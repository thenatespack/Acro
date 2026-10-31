// Generated from env_base.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 9d447ea6db25bef4
// glsl-fnv1a64: 6a0b877ebf393ae9

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _165
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

struct fragment_main_out
{
    float4 m_237 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _165& _167 [[buffer(2)]], texture2d<float> _210 [[texture(1)]], sampler _214 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    float2 _200 = gl_FragCoord.xy / _167._m2.zw;
    float3 _429;
    if (_167._m1.x > 0.5)
    {
        _429 = fast::min(_210.sample(_214, _200, level(_167._m2.y)).xyz, float3(60000.0));
    }
    else
    {
        float _296 = (_200.x - 0.5) * 6.283185482025146484375;
        float _299 = _200.y * 3.1415927410125732421875;
        float _301 = sin(_299);
        float _307 = cos(_299);
        float _332 = smoothstep(0.0, 0.02999999932944774627685546875, -_307);
        float _350 = fast::max(dot(float3(_301 * sin(_296), _307, (-_301) * cos(_296)), _167._m6.xyz), 0.0);
        float _353 = _350 * _350;
        float _356 = _353 * _353;
        float _359 = _356 * _356;
        float _362 = _359 * _359;
        _429 = mix(mix(_167._m4.xyz, _167._m3.xyz, float3(sqrt(fast::clamp(_307, 0.0, 1.0)))), _167._m5.xyz, float3(_332)) + ((_167._m7.xyz * (_167._m8.w * ((0.25 * _359) + (((_362 * _362) * _362) * _362)))) * (1.0 - _332));
    }
    out.m_237 = float4(fast::max(_429, float3(0.0)), 1.0);
    return out;
}

