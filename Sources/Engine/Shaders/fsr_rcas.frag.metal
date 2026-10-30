// Generated from fsr_rcas.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 1a5ab98c9d5c3255
// glsl-fnv1a64: b70bd71f99229e17

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _28
{
    int2 _m0;
    int2 _m1;
    float _m2;
    float _m3;
};

struct fragment_main_out
{
    float4 m_196 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _28& _30 [[buffer(16)]], texture2d<float> _23 [[texture(0)]], sampler _23Smplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _72 = int2(gl_FragCoord.xy) - _30._m0;
    float3 _217 = _23.read(uint2(clamp(_72 + int2(0, -1), int2(0), _30._m1)), 0).xyz;
    float3 _227 = _23.read(uint2(clamp(_72 + int2(-1, 0), int2(0), _30._m1)), 0).xyz;
    float3 _237 = _23.read(uint2(clamp(_72, int2(0), _30._m1)), 0).xyz;
    float3 _247 = _23.read(uint2(clamp(_72 + int2(1, 0), int2(0), _30._m1)), 0).xyz;
    float3 _257 = _23.read(uint2(clamp(_72 + int2(0, 1), int2(0), _30._m1)), 0).xyz;
    float3 _109 = fast::min(fast::min(_217, _227), fast::min(_247, _257));
    float3 _117 = fast::max(fast::max(_217, _227), fast::max(_247, _257));
    float3 _148 = fast::max(-(fast::min(_109, _237) / fast::max(_117 * 4.0, float3(1.52587890625e-05))), (float3(1.0) - fast::max(_117, _237)) / fast::min((_109 * 4.0) - float3(4.0), float3(-1.52587890625e-05)));
    float _171 = fast::max(-0.1875, fast::min(fast::max(_148.x, fast::max(_148.y, _148.z)), 0.0)) * _30._m2;
    float3 _200 = fast::clamp((((((_217 * _171) + (_227 * _171)) + (_257 * _171)) + (_247 * _171)) + _237) / float3((4.0 * _171) + 1.0), float3(0.0), float3(1.0));
    out.m_196 = float4(mix(_200 * float3(0.077399380505084991455078125), powr((_200 + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), step(float3(0.040449999272823333740234375), _200)), 1.0);
    return out;
}

