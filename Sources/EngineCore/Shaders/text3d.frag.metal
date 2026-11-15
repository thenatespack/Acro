// Generated from text3d.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6403a3086bd58aa4
// glsl-fnv1a64: f3f9431411ff6165

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _54
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _154
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
};

struct fragment_main_out
{
    float4 m_164 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_30 [[user(locn0)]];
    float m_151 [[user(locn1)]];
    float m_8 [[user(locn2), flat]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _54& _56 [[buffer(2)]], constant _154& _156 [[buffer(15)]], texture2d<float> _20 [[texture(1)]], sampler _24 [[sampler(1)]])
{
    fragment_main_out out = {};
    if (in.m_8 < 0.5)
    {
        discard_fragment();
    }
    float4 _33 = _20.sample(_24, in.m_30);
    float _36 = _33.x;
    float _39 = fwidth(_36);
    float _42 = fast::max(_39 * 0.5, 0.001953125);
    float _49 = smoothstep(0.5 - _42, 0.5 + _42, _36);
    float3 _67 = _56._m3.xyz + _56._m4.xyz;
    float _177;
    float3 _178;
    if (_56._m5.w > 0.0)
    {
        float _82 = 0.5 - _56._m5.w;
        _178 = mix(_56._m5.xyz, _67, float3(_49));
        _177 = smoothstep(_82 - _42, _82 + _42, _36);
    }
    else
    {
        _178 = _67;
        _177 = _49;
    }
    float _179;
    float3 _180;
    if (_56._m6.w > 0.0)
    {
        float _114 = fast::clamp((_36 - (0.5 - _56._m6.w)) / _56._m6.w, 0.0, 1.0);
        float _121 = (_114 * _114) * (1.0 - _177);
        float _125 = _177 + _121;
        _180 = ((_178 * _177) + (_56._m6.xyz * _121)) / float3(fast::max(_125, 9.9999997473787516355514526367188e-06));
        _179 = _125;
    }
    else
    {
        _180 = _178;
        _179 = _177;
    }
    float _144 = _179 * _56._m3.w;
    if (_144 <= 0.0)
    {
        discard_fragment();
    }
    out.m_164 = float4(mix(_180, _156._m7.xyz, float3(1.0 - exp((-in.m_151) * _156._m7.w))), _144);
    return out;
}

