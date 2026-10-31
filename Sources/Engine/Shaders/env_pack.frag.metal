// Generated from env_pack.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3acd7ff4d37e137f
// glsl-fnv1a64: ee12627daabade21

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _28
{
    int2 _m0;
};

struct fragment_main_out
{
    float4 m_9 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _28& _30 [[buffer(16)]], texture2d<float> _12 [[texture(1)]], sampler _16 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    out.m_9 = _12.read(uint2((int2(gl_FragCoord.xy) - _30._m0)), 0);
    return out;
}

