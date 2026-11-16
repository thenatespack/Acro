// Generated from dof.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 8f6172556eb870a3
// glsl-fnv1a64: 0ed45bba6fbcfdd0

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _39
{
    float4 _m0;
    float4 _m1;
    int2 _m2;
    float _m3;
    float _m4;
};

struct fragment_main_out
{
    float4 m_227 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _39& _41 [[buffer(16)]], texture2d<float> _119 [[texture(1)]], texture2d<float> _22 [[texture(2)]], sampler _26 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _107 = int2(gl_FragCoord.xy);
    float4 _247 = _22.read(uint2(_107), 0);
    float _248 = _247.x;
    float _255 = (_41._m0.z * _248) + _41._m0.w;
    float _352;
    if (abs(_255) < 9.9999999600419720025001879548654e-13)
    {
        _352 = 1000000.0;
    }
    else
    {
        _352 = abs(((_41._m0.x * _248) + _41._m0.y) / _255);
    }
    float _274 = fast::clamp(_352, 9.9999997473787516355514526367188e-05, 1000000.0);
    float _293 = fast::min((_41._m1.z * fast::max(abs(_274 - _41._m1.x) - _41._m1.y, 0.0)) / _274, _41._m1.w);
    float3 _356;
    float _358;
    _358 = 1.0;
    _356 = _119.read(uint2(_107), 0).xyz;
    float3 _212;
    float _214;
    float _220;
    float _223;
    int _353 = 0;
    float _354 = _41._m3;
    float _360 = 0.0;
    for (;;)
    {
        bool _143 = _353 < 160;
        bool _150;
        if (_143)
        {
            _150 = _354 < _41._m1.w;
        }
        else
        {
            _150 = _143;
        }
        if (_150)
        {
            int2 _168 = clamp(_107 + int2(round(float2(cos(_360), sin(_360)) * _354)), int2(0), _41._m2);
            float4 _305 = _22.read(uint2(_168), 0);
            float _306 = _305.x;
            float _313 = (_41._m0.z * _306) + _41._m0.w;
            float _362;
            if (abs(_313) < 9.9999999600419720025001879548654e-13)
            {
                _362 = 1000000.0;
            }
            else
            {
                _362 = abs(((_41._m0.x * _306) + _41._m0.y) / _313);
            }
            float _332 = fast::clamp(_362, 9.9999997473787516355514526367188e-05, 1000000.0);
            float _351 = fast::min((_41._m1.z * fast::max(abs(_332 - _41._m1.x) - _41._m1.y, 0.0)) / _332, _41._m1.w);
            float _365;
            if (_332 > _274)
            {
                _365 = fast::clamp(_351, 0.0, _293 * 2.0);
            }
            else
            {
                _365 = _351;
            }
            _212 = _356 + mix(_356 / float3(_358), _119.read(uint2(_168), 0).xyz, float3(smoothstep(_354 - 0.5, _354 + 0.5, _365)));
            _214 = _358 + 1.0;
            _220 = _354 + (_41._m3 / _354);
            _223 = _360 + 2.3999631404876708984375;
            _360 = _223;
            _358 = _214;
            _356 = _212;
            _354 = _220;
            _353++;
            continue;
        }
        else
        {
            break;
        }
    }
    out.m_227 = float4(_356 / float3(_358), 1.0);
    return out;
}

