// Generated from sprite.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 8a16bd8393f06c77
// glsl-fnv1a64: e47c018cf9396629

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_9 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_22 [[user(locn0)]];
    float4 m_26 [[user(locn1)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], texture2d<float> _12 [[texture(1)]], sampler _16 [[sampler(1)]])
{
    fragment_main_out out = {};
    out.m_9 = _12.sample(_16, in.m_22) * in.m_26;
    return out;
}

