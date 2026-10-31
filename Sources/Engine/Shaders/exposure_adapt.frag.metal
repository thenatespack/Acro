// Generated from exposure_adapt.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 449e45e48ec9c048
// glsl-fnv1a64: d15be63d50739b57

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _21
{
    int2 _m0;
    float _m1;
    float _m2;
    float _m3;
    float _m4;
};

struct fragment_main_out
{
    float4 m_103 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _21& _23 [[buffer(16)]], texture2d<float> _45 [[texture(1)]], texture2d<float> _94 [[texture(2)]], sampler _49 [[sampler(1)]])
{
    fragment_main_out out = {};
    int _123;
    float _124;
    _124 = 0.0;
    _123 = 0;
    float _67;
    for (; _123 < _23._m0.y; _124 = _67, _123++)
    {
        float _127;
        _127 = 0.0;
        for (int _126 = 0; _126 < _23._m0.x; )
        {
            _127 += _45.read(uint2(int2(_126, _123)), 0).x;
            _126++;
            continue;
        }
        _67 = _124 + _127;
    }
    float _92 = fast::clamp(_23._m2 - (_124 / float(_23._m0.x * _23._m0.y)), _23._m3, _23._m4);
    float4 _100 = _94.read(uint2(int2(0)), 0);
    float _101 = _100.x;
    float _125;
    if (_23._m1 >= 1.0)
    {
        _125 = _92;
    }
    else
    {
        _125 = _101 + ((_92 - _101) * _23._m1);
    }
    out.m_103 = float4(_125, 0.0, 0.0, 1.0);
    return out;
}

