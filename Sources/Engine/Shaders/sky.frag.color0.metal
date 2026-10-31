// Generated from sky.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 81f2a6dee1e38e5f
// glsl-fnv1a64: ed056a38b66d5322

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

struct _298
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
};

struct fragment_main_out
{
    float4 m_287 [[color(0)]];
};

struct fragment_main_in
{
    float4 m_217 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _188& _190 [[buffer(2)]], constant _298& _300 [[buffer(15)]], texture2d<float> _265 [[texture(1)]], sampler _269 [[sampler(1)]])
{
    float2 _320;
    fragment_main_out out = {};
    float3 _225 = fast::normalize(in.m_217.xyz / float3(in.m_217.w));
    float3 _576;
    if (_190._m1.x > 0.5)
    {
        float _382 = _225.x;
        float _387 = _225.z;
        float2 _419 = float2((precise::atan2((_190._m1.z * _382) - (_190._m1.w * _387), -((_190._m1.w * _382) + (_190._m1.z * _387))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_225.y, -1.0, 1.0)) * 0.3183098733425140380859375);
        float2 _244 = dfdx(_419);
        float2 _247 = dfdy(_419);
        float _249 = _244.x;
        _244.x = _249 - round(_249);
        float _256 = _247.x;
        _247.x = _256 - round(_256);
        _576 = _265.sample(_269, _419, gradient2d(_244, _247)).xyz;
    }
    else
    {
        float _453 = _225.y;
        float _458 = smoothstep(0.0, 0.02999999932944774627685546875, -_453);
        float _476 = fast::max(dot(_225, _190._m6.xyz), 0.0);
        float _479 = _476 * _476;
        float _482 = _479 * _479;
        float _485 = _482 * _482;
        float _488 = _485 * _485;
        _576 = mix(mix(_190._m4.xyz, _190._m3.xyz, float3(sqrt(fast::clamp(_453, 0.0, 1.0)))), _190._m5.xyz, float3(_458)) + (((_190._m7.xyz * (_190._m8.w * ((0.25 * _485) + (((_488 * _488) * _488) * _488)))) + (_190._m7.xyz * (_190._m8.z * smoothstep(_190._m8.x, _190._m8.y, _476)))) * (1.0 - _458));
    }
    out.m_287 = float4(_576 * _190._m1.y, 1.0);
    float4 _308 = float4(_225, 0.0);
    float4 _309 = _300._m2 * _308;
    float4 _318 = _300._m3 * _308;
    float _322 = _318.w;
    bool _323 = _322 <= 0.0;
    bool _330;
    if (!_323)
    {
        _330 = _309.w <= 0.0;
    }
    else
    {
        _330 = _323;
    }
    float2 _577;
    if (_330)
    {
        _577 = float2(0.0);
    }
    else
    {
        _577 = ((_318.xy / float2(_322)) - (_309.xy / float2(_309.w))) * float2(0.5, -0.5);
    }
    _320 = _577;
    return out;
}

