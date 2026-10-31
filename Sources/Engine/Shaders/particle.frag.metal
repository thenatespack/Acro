// Generated from particle.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: b24c0f02be1f50ea
// glsl-fnv1a64: 0ace28207aed76f5

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_21 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_12 [[user(locn0)]];
    float4 m_23 [[user(locn1)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]])
{
    fragment_main_out out = {};
    float _18 = fast::clamp(1.0 - dot(in.m_12, in.m_12), 0.0, 1.0);
    out.m_21 = float4(in.m_23.xyz, (in.m_23.w * _18) * _18);
    return out;
}

