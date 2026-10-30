// Generated from debug_line.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4c9e2afb3c0fc84e
// glsl-fnv1a64: 786f7f4e864cddb9

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_37 [[color(0)]];
};

struct fragment_main_in
{
    float4 m_39 [[user(locn0)]];
    float2 m_11 [[user(locn1), center_no_perspective]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]])
{
    fragment_main_out out = {};
    out.m_37 = float4(in.m_39.xyz, in.m_39.w * (fast::clamp((fast::max(in.m_11.y, 0.5) + 0.5) - abs(in.m_11.x), 0.0, 1.0) * fast::min(in.m_11.y * 2.0, 1.0)));
    return out;
}

