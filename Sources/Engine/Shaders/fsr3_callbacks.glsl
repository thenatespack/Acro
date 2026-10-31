// This file is part of the FidelityFX SDK.
//
// Copyright (C) 2024 Advanced Micro Devices, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and /or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// The engine's version of the SDK's ffx_fsr3upscaler_callbacks_glsl.h (FidelityFX SDK 1.1.4,
// FSR 3.1.4): the resource accessors the FSR 3 upscaler headers in FidelityFX/ call. Each
// fsr3_*.comp defines FSR3UPSCALER_BIND_* for the resources it uses, as the SDK's pass shaders
// do, but with bindings from the engine's table (set 2; see `ShaderSource`): texture n at
// 8 + n, storage texture n at 32 + n, storage buffer n at 24 + n. Constants are push constants.
// Changes from the SDK version:
// - Loads outside the texture return 0 and stores outside it are dropped (D3D's rules; on
//   Metal both are undefined, and FSR relies on them at the edges).
// - The constant buffers are one push-constant block (see below); Exposure() is a constant in it
//   (`fExposure`) instead of a texture.
// - The reconstructed previous depth is a storage buffer (atomicMin / atomicMax on the depth's
//   bits), not an R32_UINT image: buffer atomics translate to Metal without texture atomics.
// - SPD mips are separate single-level textures (r_spd_mip0..2, rw_spd_mip0..2), and only the
//   levels the passes read exist. No frame info (FSR's own auto exposure) and no SPD global
//   atomic: the pyramids stop before SPD's last-workgroup step (see fsr3_luma_pyramid.comp).
// - No Lanczos LUT (the approximate and reference kernels are used) and no debug view.

#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_samplerless_texture_functions : require

#define FFX_GPU 1
#define FFX_GLSL 1
#define FFX_HALF 0
#define FFX_SPD_NO_WAVE_OPERATIONS 1
#define FFX_PREFER_WAVE64

// The engine's inputs: low-resolution motion vectors from unjittered positions, display-referred
// (already tonemapped) color.
#define FFX_FSR3UPSCALER_OPTION_HDR_COLOR_INPUT 0
#define FFX_FSR3UPSCALER_OPTION_LOW_RESOLUTION_MOTION_VECTORS 1
#define FFX_FSR3UPSCALER_OPTION_JITTERED_MOTION_VECTORS 0
#define FFX_FSR3UPSCALER_OPTION_REPROJECT_USE_LANCZOS_TYPE 0
#define FFX_FSR3UPSCALER_OPTION_UPSAMPLE_USE_LANCZOS_TYPE 2
#ifndef FFX_FSR3UPSCALER_OPTION_INVERTED_DEPTH
#define FFX_FSR3UPSCALER_OPTION_INVERTED_DEPTH 0
#endif
#ifndef FFX_FSR3UPSCALER_OPTION_APPLY_SHARPENING
#define FFX_FSR3UPSCALER_OPTION_APPLY_SHARPENING 1
#endif

#include "FidelityFX/fsr3upscaler/ffx_fsr3upscaler_resources.h"
#include "FidelityFX/ffx_core.h"

// texelFetch that returns 0 outside the texture.
#define FSR3_LOAD(image, pos) (all(lessThan(uvec2(pos), uvec2(textureSize(image, 0)))) ? texelFetch(image, pos, 0) : vec4(0.0))
// imageStore that drops texels outside the image.
#define FSR3_STORE(image, pos, value) if (all(lessThan(uvec2(pos), uvec2(imageSize(image))))) imageStore(image, pos, value)
// Bilinear sample with sampler 1 (linear, clamp to edge), as the SDK does. Both backends run
// it on the same filtering hardware, so it matches bit for bit.
#define FSR3_SAMPLE(image, uv) textureLod(sampler2D(image, s_LinearClamp), uv, 0.0)

// The SDK's cbFSR3Upscaler, cbSPD and cbRCAS as one push-constant block (128 bytes; Swift:
// `FSR3PushConstants`). Fields that are constant for the engine's inputs are folded into the
// accessors: max sizes = current sizes (resources are made per size), motion vector scale 1 (UV
// units already), no jitter cancellation, no delta time (FSR's auto exposure isn't used). Push
// constants rather than uniform buffers: MoltenVK binds uniform buffers through argument buffers,
// and Apple's compiler then rounds some FSR arithmetic differently from directly bound buffers,
// while push constants are a plain buffer on both backends (as with the particle kernels).
layout(push_constant) uniform cbFSR3UPSCALER_t
{
    FfxInt32x2 iRenderSize;
    FfxInt32x2 iPreviousFrameRenderSize;
    FfxInt32x2 iUpscaleSize;
    FfxInt32x2 iPreviousFrameUpscaleSize;

    FfxFloat32x4  fDeviceToViewDepth;

    FfxFloat32x2  fJitter;
    FfxFloat32x2  fPreviousFrameJitter;
    FfxFloat32x2  fDownscaleFactor;

    FfxFloat32    fTanHalfFOV;
    FfxFloat32    fJitterSequenceLength;
    FfxFloat32    fDeltaPreExposure;
    FfxFloat32    fViewSpaceToMetersFactor;
    FfxFloat32    fFrameIndex;
    FfxFloat32    fVelocityFactor;
    FfxFloat32    fReactivenessScale;
    FfxFloat32    fShadingChangeScale;
    FfxFloat32    fAccumulationAddedPerFrame;
    FfxFloat32    fMinDisocclusionAccumulation;
    // Engine addition: the input's exposure (see Exposure()).
    FfxFloat32    fExposure;
    // Per pass: SPD (mips, numWorkGroups) or RCAS (rcasConfig.xy).
    FfxUInt32x2   uPassConfig;
} cbFSR3Upscaler;

FfxInt32x2 RenderSize() { return cbFSR3Upscaler.iRenderSize; }
FfxInt32x2 PreviousFrameRenderSize() { return cbFSR3Upscaler.iPreviousFrameRenderSize; }
FfxInt32x2 MaxRenderSize() { return cbFSR3Upscaler.iRenderSize; }
FfxInt32x2 UpscaleSize() { return cbFSR3Upscaler.iUpscaleSize; }
FfxInt32x2 PreviousFrameUpscaleSize() { return cbFSR3Upscaler.iPreviousFrameUpscaleSize; }
FfxInt32x2 MaxUpscaleSize() { return cbFSR3Upscaler.iUpscaleSize; }
FfxFloat32x2 Jitter() { return cbFSR3Upscaler.fJitter; }
FfxFloat32x2 PreviousFrameJitter() { return cbFSR3Upscaler.fPreviousFrameJitter; }
FfxFloat32x4 DeviceToViewSpaceTransformFactors() { return cbFSR3Upscaler.fDeviceToViewDepth; }
FfxFloat32x2 MotionVectorScale() { return FfxFloat32x2(1.0, 1.0); }
FfxFloat32x2 DownscaleFactor() { return cbFSR3Upscaler.fDownscaleFactor; }
FfxFloat32x2 MotionVectorJitterCancellation() { return FfxFloat32x2(0.0, 0.0); }
FfxFloat32 TanHalfFoV() { return cbFSR3Upscaler.fTanHalfFOV; }
FfxFloat32 JitterSequenceLength() { return cbFSR3Upscaler.fJitterSequenceLength; }
FfxFloat32 DeltaTime() { return 0.0; }
FfxFloat32 DeltaPreExposure() { return cbFSR3Upscaler.fDeltaPreExposure; }
FfxFloat32 ViewSpaceToMetersFactor() { return cbFSR3Upscaler.fViewSpaceToMetersFactor; }
FfxFloat32 FrameIndex() { return cbFSR3Upscaler.fFrameIndex; }
FfxFloat32 VelocityFactor() { return cbFSR3Upscaler.fVelocityFactor; }
FfxFloat32 AccumulationAddedPerFrame() { return cbFSR3Upscaler.fAccumulationAddedPerFrame; }
FfxFloat32 MinDisocclusionAccumulation() { return cbFSR3Upscaler.fMinDisocclusionAccumulation; }

// The SDK reads this from a 1x1 texture (the game's, or FSR's own auto exposure); 0 means 1.
FfxFloat32 Exposure()
{
    FfxFloat32 exposure = cbFSR3Upscaler.fExposure;
    return exposure == 0.0 ? 1.0 : exposure;
}

// cbRCAS (FsrRcasCon; only .x and .y are ever set).
FfxUInt32x4 RCASConfig() { return FfxUInt32x4(cbFSR3Upscaler.uPassConfig, 0u, 0u); }

// cbSPD over the whole render target (no work group offset).
FfxUInt32 MipCount() { return cbFSR3Upscaler.uPassConfig.x; }
FfxUInt32 NumWorkGroups() { return cbFSR3Upscaler.uPassConfig.y; }
FfxUInt32x2 WorkGroupOffset() { return FfxUInt32x2(0u, 0u); }
FfxUInt32x2 SPD_RenderSize() { return FfxUInt32x2(cbFSR3Upscaler.iRenderSize); }

// Sampler 1 (binding 17): linear filtering, clamp to edge.
#if defined(FSR3UPSCALER_BIND_SAMPLER_LINEAR_CLAMP)
layout(set = 2, binding = FSR3UPSCALER_BIND_SAMPLER_LINEAR_CLAMP) uniform sampler s_LinearClamp;
#endif

#if defined(FSR3UPSCALER_BIND_SRV_SPD_MIP0)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_SPD_MIP0) uniform texture2D r_spd_mip0;
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_SPD_MIP1) uniform texture2D r_spd_mip1;
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_SPD_MIP2) uniform texture2D r_spd_mip2;

FfxInt32x2 GetSPDMipDimensions(FfxUInt32 uMipLevel)
{
    return uMipLevel == 0 ? textureSize(r_spd_mip0, 0).xy : uMipLevel == 1 ? textureSize(r_spd_mip1, 0).xy : textureSize(r_spd_mip2, 0).xy;
}

// The SDK samples level `mipLevel` of one texture at `fUV`; the levels are halves, so the same
// UV addresses the same place in each.
FfxFloat32x2 SampleSPDMipLevel(FfxFloat32x2 fUV, FfxUInt32 mipLevel)
{
    if (mipLevel == 0) return FSR3_SAMPLE(r_spd_mip0, fUV).rg;
    if (mipLevel == 1) return FSR3_SAMPLE(r_spd_mip1, fUV).rg;
    return FSR3_SAMPLE(r_spd_mip2, fUV).rg;
}
#endif

#if defined(FSR3UPSCALER_BIND_SRV_INPUT_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_INPUT_DEPTH) uniform texture2D r_input_depth;

FfxFloat32 LoadInputDepth(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_input_depth, iPxPos).r; }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_REACTIVE_MASK)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_REACTIVE_MASK) uniform texture2D r_reactive_mask;

FfxFloat32 LoadReactiveMask(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_reactive_mask, iPxPos).r * cbFSR3Upscaler.fReactivenessScale; }
#endif

// The engine has no transparency-and-composition mask: it reads as 0.
FfxInt32x2 GetTransparencyAndCompositionMaskResourceDimensions() { return FfxInt32x2(1, 1); }
FfxFloat32 SampleTransparencyAndCompositionMask(FfxFloat32x2 fUV) { return 0.0; }

#if defined(FSR3UPSCALER_BIND_SRV_INPUT_COLOR)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_INPUT_COLOR) uniform texture2D r_input_color_jittered;

FfxFloat32x3 LoadInputColor(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_input_color_jittered, iPxPos).rgb; }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_INPUT_MOTION_VECTORS)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_INPUT_MOTION_VECTORS) uniform texture2D r_input_motion_vectors;

FfxFloat32x2 LoadInputMotionVector(FfxInt32x2 iPxDilatedMotionVectorPos)
{
    FfxFloat32x2 fSrcMotionVector = FSR3_LOAD(r_input_motion_vectors, iPxDilatedMotionVectorPos).xy;
    FfxFloat32x2 fUvMotionVector = fSrcMotionVector * MotionVectorScale();
#if FFX_FSR3UPSCALER_OPTION_JITTERED_MOTION_VECTORS
    fUvMotionVector -= MotionVectorJitterCancellation();
#endif
    return fUvMotionVector;
}
#endif

#if defined(FSR3UPSCALER_BIND_SRV_INTERNAL_UPSCALED)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_INTERNAL_UPSCALED) uniform texture2D r_internal_upscaled_color;

FfxFloat32x4 LoadHistory(FfxInt32x2 iPxHistory) { return FSR3_LOAD(r_internal_upscaled_color, iPxHistory); }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_LUMA_HISTORY)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_LUMA_HISTORY, rgba16f) writeonly uniform image2D rw_luma_history;

void StoreLumaHistory(FfxInt32x2 iPxPos, FfxFloat32x4 fLumaHistory) { FSR3_STORE(rw_luma_history, iPxPos, fLumaHistory); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_LUMA_HISTORY)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_LUMA_HISTORY) uniform texture2D r_luma_history;

FfxFloat32x4 SampleLumaHistory(FfxFloat32x2 fUV) { return FSR3_SAMPLE(r_luma_history, fUV); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_RCAS_INPUT)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_RCAS_INPUT) uniform texture2D r_rcas_input;

FfxFloat32x4 LoadRCAS_Input(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_rcas_input, iPxPos); }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_INTERNAL_UPSCALED)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_INTERNAL_UPSCALED, rgba16f) writeonly uniform image2D rw_internal_upscaled_color;

void StoreInternalColorAndWeight(FfxInt32x2 iPxPos, FfxFloat32x4 fColorAndWeight)
{
    FSR3_STORE(rw_internal_upscaled_color, iPxPos, fColorAndWeight);
}
#endif

#if defined(FSR3UPSCALER_BIND_UAV_UPSCALED_OUTPUT)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_UPSCALED_OUTPUT, rgba16f) writeonly uniform image2D rw_upscaled_output;

void StoreUpscaledOutput(FfxInt32x2 iPxPos, FfxFloat32x3 fColor) { FSR3_STORE(rw_upscaled_output, iPxPos, FfxFloat32x4(fColor, 1.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_ACCUMULATION)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_ACCUMULATION) uniform texture2D r_accumulation;

FfxFloat32 SampleAccumulation(FfxFloat32x2 fUV) { return FSR3_SAMPLE(r_accumulation, fUV).x; }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_ACCUMULATION)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_ACCUMULATION, r8) writeonly uniform image2D rw_accumulation;

void StoreAccumulation(FfxInt32x2 iPxPos, FfxFloat32 fAccumulation) { FSR3_STORE(rw_accumulation, iPxPos, vec4(fAccumulation, 0.0, 0.0, 0.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_SHADING_CHANGE)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_SHADING_CHANGE) uniform texture2D r_shading_change;

FfxFloat32 SampleShadingChange(FfxFloat32x2 fUV) { return FSR3_SAMPLE(r_shading_change, fUV).x * cbFSR3Upscaler.fShadingChangeScale; }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_SHADING_CHANGE)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_SHADING_CHANGE, r8) writeonly uniform image2D rw_shading_change;

void StoreShadingChange(FfxInt32x2 iPxPos, FfxFloat32 fShadingChange) { FSR3_STORE(rw_shading_change, iPxPos, vec4(fShadingChange, 0.0, 0.0, 0.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_FARTHEST_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_FARTHEST_DEPTH) uniform texture2D r_farthest_depth;

FfxFloat32 LoadFarthestDepth(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_farthest_depth, iPxPos).x; }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_FARTHEST_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_FARTHEST_DEPTH, r16f) writeonly uniform image2D rw_farthest_depth;

void StoreFarthestDepth(FfxInt32x2 iPxPos, FfxFloat32 fDepth) { FSR3_STORE(rw_farthest_depth, iPxPos, vec4(fDepth, 0.0, 0.0, 0.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_FARTHEST_DEPTH_MIP1)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_FARTHEST_DEPTH_MIP1) uniform texture2D r_farthest_depth_mip1;

FfxInt32x2 GetFarthestDepthMip1ResourceDimensions() { return textureSize(r_farthest_depth_mip1, 0).xy; }
FfxFloat32 SampleFarthestDepthMip1(FfxFloat32x2 fUV) { return FSR3_SAMPLE(r_farthest_depth_mip1, fUV).x; }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_FARTHEST_DEPTH_MIP1)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_FARTHEST_DEPTH_MIP1, r16f) writeonly uniform image2D rw_farthest_depth_mip1;

void StoreFarthestDepthMip1(FfxInt32x2 iPxPos, FfxFloat32 fDepth) { FSR3_STORE(rw_farthest_depth_mip1, iPxPos, vec4(fDepth, 0.0, 0.0, 0.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_CURRENT_LUMA)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_CURRENT_LUMA) uniform texture2D r_current_luma;

FfxFloat32 LoadCurrentLuma(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_current_luma, iPxPos).r; }
#if defined(FSR3UPSCALER_BIND_SAMPLER_LINEAR_CLAMP)
FfxFloat32 SampleCurrentLuma(FfxFloat32x2 uv) { return FSR3_SAMPLE(r_current_luma, uv).r; }
#endif
#endif

#if defined(FSR3UPSCALER_BIND_UAV_CURRENT_LUMA)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_CURRENT_LUMA, r16f) writeonly uniform image2D rw_current_luma;

void StoreCurrentLuma(FfxInt32x2 iPxPos, FfxFloat32 fLuma) { FSR3_STORE(rw_current_luma, iPxPos, vec4(fLuma, 0.0, 0.0, 0.0)); }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_LUMA_INSTABILITY)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_LUMA_INSTABILITY) uniform texture2D r_luma_instability;

FfxFloat32 SampleLumaInstability(FfxFloat32x2 uv) { return FSR3_SAMPLE(r_luma_instability, uv).x; }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_LUMA_INSTABILITY)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_LUMA_INSTABILITY, r16f) writeonly uniform image2D rw_luma_instability;

void StoreLumaInstability(FfxInt32x2 iPxPos, FfxFloat32 fLumaInstability)
{
    FSR3_STORE(rw_luma_instability, iPxPos, vec4(fLumaInstability, 0.0, 0.0, 0.0));
}
#endif

#if defined(FSR3UPSCALER_BIND_SRV_PREVIOUS_LUMA)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_PREVIOUS_LUMA) uniform texture2D r_previous_luma;

FfxFloat32 LoadPreviousLuma(FfxInt32x2 iPxPos) { return FSR3_LOAD(r_previous_luma, iPxPos).r; }
#endif

// New locks: written by the reactivity pass, read and cleared by the accumulation pass.
#if defined(FSR3UPSCALER_BIND_UAV_NEW_LOCKS)
#if defined(FSR3UPSCALER_NEW_LOCKS_WRITEONLY)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_NEW_LOCKS, r8) writeonly uniform image2D rw_new_locks;
#else
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_NEW_LOCKS, r8) uniform image2D rw_new_locks;

FfxFloat32 LoadRwNewLocks(FfxInt32x2 iPxPos)
{
    return all(lessThan(uvec2(iPxPos), uvec2(imageSize(rw_new_locks)))) ? imageLoad(rw_new_locks, iPxPos).r : 0.0;
}
#endif

void StoreNewLocks(FfxInt32x2 iPxPos, FfxFloat32 newLock) { FSR3_STORE(rw_new_locks, iPxPos, vec4(newLock, 0.0, 0.0, 0.0)); }
#endif

// The reconstructed previous nearest depth: one uint per render pixel, the depth's bits (depths
// are >= 0, so their bits order like the floats), row-major at the render size.
#if defined(FSR3UPSCALER_BIND_BUFFER_RECONSTRUCTED_PREV_NEAREST_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_BUFFER_RECONSTRUCTED_PREV_NEAREST_DEPTH, std430) buffer ReconstructedDepth_t
{
    FfxUInt32 data[];
} rw_reconstructed_previous_nearest_depth;

FfxBoolean ReconstructedDepthInside(FfxInt32x2 iPxPos) { return all(lessThan(uvec2(iPxPos), uvec2(RenderSize()))); }
FfxUInt32 ReconstructedDepthIndex(FfxInt32x2 iPxPos) { return FfxUInt32(iPxPos.y * RenderSize().x + iPxPos.x); }

FfxFloat32 LoadReconstructedPrevDepth(FfxInt32x2 iPxPos)
{
    return ReconstructedDepthInside(iPxPos)
        ? uintBitsToFloat(rw_reconstructed_previous_nearest_depth.data[ReconstructedDepthIndex(iPxPos)]) : 0.0;
}

// The nearest depth wins whatever order threads arrive in (min or max is order-independent).
void StoreReconstructedDepth(FfxInt32x2 iPxSample, FfxFloat32 fDepth)
{
    if (!ReconstructedDepthInside(iPxSample)) return;
    FfxUInt32 uDepth = floatBitsToUint(fDepth);
#if FFX_FSR3UPSCALER_OPTION_INVERTED_DEPTH
    atomicMax(rw_reconstructed_previous_nearest_depth.data[ReconstructedDepthIndex(iPxSample)], uDepth);
#else
    atomicMin(rw_reconstructed_previous_nearest_depth.data[ReconstructedDepthIndex(iPxSample)], uDepth);  // min for standard, max for inverted depth
#endif
}
#endif

#if defined(FSR3UPSCALER_BIND_UAV_DILATED_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_DILATED_DEPTH, r32f) writeonly uniform image2D rw_dilated_depth;

void StoreDilatedDepth(FFX_PARAMETER_IN FfxInt32x2 iPxPos, FFX_PARAMETER_IN FfxFloat32 fDepth)
{
    FSR3_STORE(rw_dilated_depth, iPxPos, vec4(fDepth, 0.0, 0.0, 0.0));
}
#endif

#if defined(FSR3UPSCALER_BIND_UAV_DILATED_MOTION_VECTORS)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_DILATED_MOTION_VECTORS, rg16f) writeonly uniform image2D rw_dilated_motion_vectors;

void StoreDilatedMotionVector(FFX_PARAMETER_IN FfxInt32x2 iPxPos, FFX_PARAMETER_IN FfxFloat32x2 fMotionVector)
{
    FSR3_STORE(rw_dilated_motion_vectors, iPxPos, vec4(fMotionVector, 0.0, 0.0));
}
#endif

#if defined(FSR3UPSCALER_BIND_SRV_DILATED_MOTION_VECTORS)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_DILATED_MOTION_VECTORS) uniform texture2D r_dilated_motion_vectors;

FfxFloat32x2 LoadDilatedMotionVector(FfxInt32x2 iPxInput) { return FSR3_LOAD(r_dilated_motion_vectors, iPxInput).xy; }
#endif

#if defined(FSR3UPSCALER_BIND_SRV_DILATED_DEPTH)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_DILATED_DEPTH) uniform texture2D r_dilated_depth;

FfxFloat32 LoadDilatedDepth(FfxInt32x2 iPxInput) { return FSR3_LOAD(r_dilated_depth, iPxInput).r; }
#endif

// No Lanczos LUT: the reference and approximate kernels don't read it.
FfxFloat32 SampleLanczos2Weight(FfxFloat32 x) { return 0.0; }

#if defined(FSR3UPSCALER_BIND_SRV_DILATED_REACTIVE_MASKS)
layout(set = 2, binding = FSR3UPSCALER_BIND_SRV_DILATED_REACTIVE_MASKS) uniform texture2D r_dilated_reactive_masks;

FfxFloat32x4 SampleDilatedReactiveMasks(FfxFloat32x2 fUV) { return FSR3_SAMPLE(r_dilated_reactive_masks, fUV); }
#endif

#if defined(FSR3UPSCALER_BIND_UAV_DILATED_REACTIVE_MASKS)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_DILATED_REACTIVE_MASKS, rgba8) writeonly uniform image2D rw_dilated_reactive_masks;

void StoreDilatedReactiveMasks(FFX_PARAMETER_IN FfxInt32x2 iPxPos, FFX_PARAMETER_IN FfxFloat32x4 fDilatedReactiveMasks)
{
    FSR3_STORE(rw_dilated_reactive_masks, iPxPos, fDilatedReactiveMasks);
}
#endif

// SPD levels written by the pyramids, as separate single-level images (rg16f). Only the levels
// a pass binds are written; stores to the others are dropped.
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_0)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_0, rg16f) writeonly uniform image2D rw_spd_mip0;
#endif
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_1)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_1, rg16f) writeonly uniform image2D rw_spd_mip1;
#endif
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_2)
layout(set = 2, binding = FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_2, rg16f) writeonly uniform image2D rw_spd_mip2;
#endif

// SPD's level 5, read back by its last-workgroup step, which the engine's passes never reach.
FfxFloat32x2 RWLoadPyramid(FFX_PARAMETER_IN FfxInt32x2 iPxPos, FFX_PARAMETER_IN FfxUInt32 index) { return FfxFloat32x2(0.0, 0.0); }

void StorePyramid(FFX_PARAMETER_IN FfxInt32x2 iPxPos, FFX_PARAMETER_IN FfxFloat32x2 outValue, FFX_PARAMETER_IN FfxUInt32 index)
{
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_0)
    if (index == 0) { FSR3_STORE(rw_spd_mip0, iPxPos, vec4(outValue, 0.0, 0.0)); }
#endif
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_1)
    if (index == 1) { FSR3_STORE(rw_spd_mip1, iPxPos, vec4(outValue, 0.0, 0.0)); }
#endif
#if defined(FSR3UPSCALER_BIND_UAV_SPD_MIPS_LEVEL_2)
    if (index == 2) { FSR3_STORE(rw_spd_mip2, iPxPos, vec4(outValue, 0.0, 0.0)); }
#endif
}

// SPD's global atomic counter picks the last workgroup for levels 6+, which the engine's passes
// don't compute (SPD returns before it with at most 6 levels).
void SPD_IncreaseAtomicCounter(inout FfxUInt32 spdCounter) { spdCounter = 0; }
void SPD_ResetAtomicCounter() {}

// FSR's frame info (its own auto exposure, written by the luma pyramid's last level) isn't kept.
FfxFloat32x4 LoadFrameInfo() { return FfxFloat32x4(0.0, 0.0, 0.0, 0.0); }
void StoreFrameInfo(FfxFloat32x4 fInfo) {}
