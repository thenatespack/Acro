// Generated from particle.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 8d2398c2d0f7c792
// glsl-fnv1a64: 270ecc2a7da9a11b

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2[4];
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    float4 _m9;
    float4 _m10;
};

struct fragment_main_out
{
    float4 m_135 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_72 [[user(locn0)]];
    float4 m_11 [[user(locn1)]];
    float4 m_42 [[user(locn2)]];
    float m_48 [[user(locn3)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _17& _19 [[buffer(2)]], texture2d<float> _34 [[texture(1)]], texture2d<float> _94 [[texture(2)]], sampler _38 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    float4 _12 = in.m_11;
    float4 _145;
    if (_19._m9.z > 0.5)
    {
        float4 _46 = _34.sample(_38, in.m_42.xy);
        float4 _143;
        if (in.m_48 > 0.0)
        {
            _143 = mix(_46, _34.sample(_38, in.m_42.zw), float4(in.m_48));
        }
        else
        {
            _143 = _46;
        }
        _145 = _12 * _143;
    }
    else
    {
        float _77 = fast::clamp(1.0 - dot(in.m_72, in.m_72), 0.0, 1.0);
        _12.w = _12.w * (_77 * _77);
        _145 = _12;
    }
    float4 _146;
    if (_19._m10.x > 0.0)
    {
        float4 _142 = _145;
        _142.w = _145.w * fast::clamp(((_19._m10.y / (_94.read(uint2(int2(gl_FragCoord.xy)), 0).x + _19._m10.z)) - (_19._m10.y / (gl_FragCoord.z + _19._m10.z))) * _19._m10.x, 0.0, 1.0);
        _146 = _142;
    }
    else
    {
        _146 = _145;
    }
    out.m_135 = _146;
    return out;
}

