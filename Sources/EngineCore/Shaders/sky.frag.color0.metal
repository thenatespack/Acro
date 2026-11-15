// Generated from sky.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 1dd939ef2c066d33
// glsl-fnv1a64: 8e97b8b7cec86dd8

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _188
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
};

struct _309
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct fragment_main_out
{
    float4 m_301 [[color(0)]];
};

struct fragment_main_in
{
    float4 m_217 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _188& _190 [[buffer(2)]], constant _309& _311 [[buffer(15)]], texture2d<float> _265 [[texture(1)]], sampler _269 [[sampler(1)]])
{
    float2 _331;
    fragment_main_out out = {};
    float3 _225 = fast::normalize(in.m_217.xyz / float3(in.m_217.w));
    float3 _587;
    if (_190._m1.x > 0.5)
    {
        float _393 = _225.x;
        float _398 = _225.z;
        float2 _430 = float2((precise::atan2((_190._m1.z * _393) - (_190._m1.w * _398), -((_190._m1.w * _393) + (_190._m1.z * _398))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_225.y, -1.0, 1.0)) * 0.3183098733425140380859375);
        float2 _244 = dfdx(_430);
        float2 _247 = dfdy(_430);
        float _249 = _244.x;
        _244.x = _249 - round(_249);
        float _256 = _247.x;
        _247.x = _256 - round(_256);
        _587 = _265.sample(_269, _430, gradient2d(_244, _247)).xyz;
    }
    else
    {
        float _464 = _225.y;
        float _469 = smoothstep(0.0, 0.02999999932944774627685546875, -_464);
        float _487 = fast::max(dot(_225, _190._m6.xyz), 0.0);
        float _490 = _487 * _487;
        float _493 = _490 * _490;
        float _496 = _493 * _493;
        float _499 = _496 * _496;
        _587 = mix(mix(_190._m4.xyz, _190._m3.xyz, float3(sqrt(fast::clamp(_464, 0.0, 1.0)))), _190._m5.xyz, float3(_469)) + (((_190._m7.xyz * (_190._m8.w * ((0.25 * _496) + (((_499 * _499) * _499) * _499)))) + (_190._m7.xyz * (_190._m8.z * smoothstep(_190._m8.x, _190._m8.y, _487)))) * (1.0 - _469));
    }
    float3 _289 = _587 * _190._m1.y;
    float3 _588;
    if (_190._m2.y > 0.5)
    {
        _588 = _289 / (float3(1.0) + _289);
    }
    else
    {
        _588 = _289;
    }
    out.m_301 = float4(_588, 1.0);
    float4 _319 = float4(_225, 0.0);
    float4 _320 = _311._m2 * _319;
    float4 _329 = _311._m3 * _319;
    float _333 = _329.w;
    bool _334 = _333 <= 0.0;
    bool _341;
    if (!_334)
    {
        _341 = _320.w <= 0.0;
    }
    else
    {
        _341 = _334;
    }
    float2 _589;
    if (_341)
    {
        _589 = float2(0.0);
    }
    else
    {
        _589 = ((_329.xy / float2(_333)) - (_320.xy / float2(_320.w))) * float2(0.5, -0.5);
    }
    _331 = _589;
    return out;
}

