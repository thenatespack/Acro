// Generated from debug_grid.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 590329dd26619eaa
// glsl-fnv1a64: fabc356a27b91b45

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _98
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct fragment_main_out
{
    float4 m_229 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_93 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _98& _100 [[buffer(2)]])
{
    fragment_main_out out = {};
    float2 _111 = in.m_93.xz / float2(_100._m2.x);
    float2 _238 = fast::max(fwidth(_111), float2(9.9999999747524270787835121154785e-07));
    float2 _252 = float2((_100._m2.w * 0.5) + 0.5);
    float2 _256 = fast::clamp(_252 - (abs(fract(_111 - float2(0.5)) - float2(0.5)) / _238), float2(0.0), float2(1.0));
    float2 _131 = _111 / float2(_100._m2.y);
    float2 _275 = fast::max(fwidth(_131), float2(9.9999999747524270787835121154785e-07));
    float2 _293 = fast::clamp(_252 - (abs(fract(_131 - float2(0.5)) - float2(0.5)) / _275), float2(0.0), float2(1.0));
    float _141 = fast::max(_293.x, _293.y) * smoothstep(4.0, 12.0, 1.0 / fast::max(_275.x, _275.y));
    float2 _155 = fast::clamp(float2(_100._m2.w + 0.5) - (abs(in.m_93.xz) / fast::max(fwidth(in.m_93.xz), float2(9.9999999747524270787835121154785e-07))), float2(0.0), float2(1.0));
    float _165 = _100._m3.w * (fast::max(_256.x, _256.y) * smoothstep(4.0, 12.0, 1.0 / fast::max(_238.x, _238.y)));
    float3 _313 = mix(float4(_100._m3.xyz, _165).xyz, _100._m4.xyz, float3(_141));
    float _320 = fast::max(_165, _100._m4.w * _141);
    float _187 = _155.y;
    float3 _333 = mix(float4(_313, _320).xyz, _100._m5.xyz, float3(_187));
    float _340 = fast::max(_320, _100._m5.w * _187);
    float _197 = _155.x;
    float _360 = fast::max(_340, _100._m6.w * _197);
    float4 _364 = float4(mix(float4(_333, _340).xyz, _100._m6.xyz, float3(_197)), _360);
    float _219 = _360 * (1.0 - smoothstep(_100._m2.z * 0.4000000059604644775390625, _100._m2.z, length(in.m_93.xz - _100._m1.xz)));
    _364.w = _219;
    if (_219 <= 0.0)
    {
        discard_fragment();
    }
    out.m_229 = _364;
    return out;
}

