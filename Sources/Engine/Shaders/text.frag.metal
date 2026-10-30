// Generated from text.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6daf82505a92d45b

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_43 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_21 [[user(locn0)]];
    float4 m_45 [[user(locn1)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], texture2d<float> _11 [[texture(1)]], sampler _15 [[sampler(1)]])
{
    fragment_main_out out = {};
    float4 _24 = _11.sample(_15, in.m_21);
    float _27 = _24.x;
    float _34 = fast::max(fwidth(_27) * 0.5, 0.001953125);
    out.m_43 = float4(in.m_45.xyz, in.m_45.w * smoothstep(0.5 - _34, 0.5 + _34, _27));
    return out;
}

