// Generated from textures.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: f7b89778d88aa8a0

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _27
{
    float4 _m0;
    float4 _m1;
};

struct _44
{
    float4x4 _m0;
    float4x4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
};

struct fragment_main_out
{
    float4 m_115 [[color(0)]];
    float2 m_136 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_100 [[user(locn0)]];
    float3 m_39 [[user(locn1)]];
    float2 m_22 [[user(locn2)]];
    float4 m_130 [[user(locn3)]];
    float4 m_133 [[user(locn4)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _27& _29 [[buffer(2)]], constant _44& _46 [[buffer(15)]], texture2d<float> _12 [[texture(1)]], sampler _16 [[sampler(1)]])
{
    fragment_main_out out = {};
    float3 _41 = fast::normalize(in.m_39);
    out.m_115 = float4(mix((_12.sample(_16, in.m_22).xyz * _29._m1.xyz) * ((mix(float3(0.119999997317790985107421875, 0.100000001490116119384765625, 0.0900000035762786865234375), float3(0.550000011920928955078125, 0.64999997615814208984375, 0.85000002384185791015625), float3((_41.y * 0.5) + 0.5)) * 0.300000011920928955078125) + float3(fast::max(dot(_41, fast::normalize(_46._m2.xyz)), 0.0) * _46._m2.w)), _46._m4.xyz, float3(1.0 - exp((-length(_46._m3.xyz - in.m_100)) * _46._m4.w))), 1.0);
    float2 _168;
    if (in.m_133.w > 0.0)
    {
        _168 = ((in.m_133.xy / float2(in.m_133.w)) - (in.m_130.xy / float2(in.m_130.w))) * float2(0.5, -0.5);
    }
    else
    {
        _168 = float2(0.0);
    }
    out.m_136 = _168;
    return out;
}

