// Generated from bloom_up.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4fe6ec8fa5f05808
// glsl-fnv1a64: fb37b91f71b9693a

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _158
{
    int2 _m0;
};

struct fragment_main_out
{
    float4 m_178 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _158& _160 [[buffer(16)]], texture2d<float> _157 [[texture(1)]], texture2d<float> _169 [[texture(2)]], sampler _36 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _155 = int2(gl_FragCoord.xy);
    int _208 = _155.x;
    int _261 = _208 >> 1;
    bool _264 = (_208 & 1) == 0;
    int _299;
    if (_264)
    {
        _299 = _261 - 2;
    }
    else
    {
        _299 = _261 - 1;
    }
    float4 _190 = select(float4(0.1875, 0.4375, 0.3125, 0.0625), float4(0.0625, 0.3125, 0.4375, 0.1875), bool4(_264));
    int _213 = _155.y;
    int _275 = _213 >> 1;
    bool _278 = (_213 & 1) == 0;
    int _301;
    if (_278)
    {
        _301 = _275 - 2;
    }
    else
    {
        _301 = _275 - 1;
    }
    float4 _195 = select(float4(0.1875, 0.4375, 0.3125, 0.0625), float4(0.0625, 0.3125, 0.4375, 0.1875), bool4(_278));
    int _303;
    float3 _304;
    _304 = float3(0.0);
    _303 = 0;
    float3 _252;
    for (; _303 < 4; _304 = _252, _303++)
    {
        float3 _306;
        _306 = float3(0.0);
        for (int _305 = 0; _305 < 4; )
        {
            _306 += (_157.read(uint2(clamp(int2(_299 + _305, _301 + _303), int2(0), _160._m0)), 0).xyz * _190[_305]);
            _305++;
            continue;
        }
        _252 = _304 + (_306 * _195[_303]);
    }
    out.m_178 = float4((_169.read(uint2(_155), 0).xyz + _304) * 0.5, 1.0);
    return out;
}

