// Generated from env_downsample.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3c5a07c7c55f9623
// glsl-fnv1a64: 8bc218e852f50e2c

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _18
{
    int _m0;
    int _m1;
};

struct fragment_main_out
{
    float4 m_116 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _18& _20 [[buffer(16)]], texture2d<float> _79 [[texture(1)]], sampler _83 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _26 = int2(gl_FragCoord.xy) * int2(_20._m0);
    float3 _152;
    float _153;
    _153 = 0.0;
    _152 = float3(0.0);
    float3 _105;
    float _112;
    for (int _151 = 0; _151 < _20._m0; _153 = _112, _152 = _105, _151++)
    {
        int _52 = _26.y + _151;
        float _65 = sin(((float(_52) + 0.5) / float(_20._m1)) * 3.1415927410125732421875);
        float3 _155;
        _155 = float3(0.0);
        for (int _154 = 0; _154 < _20._m0; )
        {
            _155 += _79.read(uint2(int2(_26.x + _154, _52)), 0).xyz;
            _154++;
            continue;
        }
        _105 = _152 + (_155 * _65);
        _112 = _153 + (_65 * float(_20._m0));
    }
    out.m_116 = float4(_152 / float3(_153), 1.0);
    return out;
}

