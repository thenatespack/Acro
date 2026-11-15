// Generated from outline_composite.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 93b75bea5b58fb78
// glsl-fnv1a64: 1c1fcfd816ee96c5

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _44
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    int4 _m3;
};

struct fragment_main_out
{
    float4 m_212 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _44& _46 [[buffer(16)]], texture2d<float> _20 [[texture(1)]], sampler _24 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _17 = int2(gl_FragCoord.xy);
    if (_20.read(uint2(_17), 0).x > 0.5)
    {
        discard_fragment();
    }
    int _52 = int(_46._m2.z);
    int _60 = -_52;
    float _234;
    float _235;
    float _236;
    _236 = 1000000000.0;
    _235 = 1000000000.0;
    _234 = 1000000000.0;
    float _249;
    float _253;
    float _258;
    for (int _233 = _60; _233 <= _52; _236 = _258, _235 = _249, _234 = _253, _233++)
    {
        _258 = _236;
        _253 = _234;
        _249 = _235;
        float _265;
        float _268;
        float _271;
        for (int _238 = _60; _238 <= _52; _258 = _271, _253 = _268, _249 = _265, _238++)
        {
            int2 _85 = _17 + int2(_238, _233);
            int _87 = _85.x;
            bool _88 = _87 < 0;
            bool _96;
            if (!_88)
            {
                _96 = _85.y < 0;
            }
            else
            {
                _96 = _88;
            }
            bool _107;
            if (!_96)
            {
                _107 = _87 > _46._m3.x;
            }
            else
            {
                _107 = _96;
            }
            bool _116;
            if (!_107)
            {
                _116 = _85.y > _46._m3.y;
            }
            else
            {
                _116 = _107;
            }
            if (_116)
            {
                _271 = _258;
                _268 = _253;
                _265 = _249;
                continue;
            }
            float4 _127 = _20.read(uint2(_85), 0);
            if (_127.x < 0.5)
            {
                _271 = _258;
                _268 = _253;
                _265 = _249;
                continue;
            }
            float _143 = sqrt(float((_238 * _238) + (_233 * _233)));
            float _270;
            if (_127.y > 0.5)
            {
                _270 = fast::min(_253, _143);
            }
            else
            {
                _270 = _253;
            }
            float _272;
            if (_127.z > 0.5)
            {
                _272 = fast::min(_258, _143);
            }
            else
            {
                _272 = _258;
            }
            _271 = _272;
            _268 = _270;
            _265 = fast::min(_249, _143);
        }
    }
    float _174 = _46._m2.x + 1.0;
    float _191 = fast::max(fast::clamp(_174 - _234, 0.0, 1.0), fast::clamp(_174 - _235, 0.0, 1.0) * _46._m2.y);
    if (_191 <= 0.0)
    {
        discard_fragment();
    }
    float4 _237;
    if (_236 <= _235)
    {
        _237 = _46._m0;
    }
    else
    {
        _237 = _46._m1;
    }
    out.m_212 = float4(_237.xyz, _237.w * _191);
    return out;
}

