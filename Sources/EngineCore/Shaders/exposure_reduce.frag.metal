// Generated from exposure_reduce.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6bf3fc4809e2b5e4
// glsl-fnv1a64: c5887e23c92485e4

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _71
{
    int2 _m0;
    int2 _m1;
};

struct fragment_main_out
{
    float4 m_113 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _71& _73 [[buffer(16)]], texture2d<float> _88 [[texture(1)]], sampler _92 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _31 = int2(gl_FragCoord.xy);
    int _123;
    float _124;
    _124 = 0.0;
    _123 = 0;
    float _127;
    for (; _123 < 8; _124 = _127, _123++)
    {
        _127 = _124;
        for (int _125 = 0; _125 < 8; )
        {
            _127 += log2(fast::max(dot(_88.read(uint2(((((((_31 * int2(8)) + int2(_125, _123)) * int2(2)) + int2(1)) * _73._m0) / (_73._m1 * int2(16)))), 0).xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 1.52587890625e-05));
            _125++;
            continue;
        }
    }
    out.m_113 = float4(_124 * 0.015625, 0.0, 0.0, 1.0);
    return out;
}

