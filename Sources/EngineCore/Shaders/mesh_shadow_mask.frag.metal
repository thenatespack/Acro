// Generated from mesh_shadow_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: c9170889009cf0f1
// glsl-fnv1a64: 5a3f20b268ccdd21

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _11
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct fragment_main_in
{
    float2 m_21 [[user(locn0)]];
};

fragment void fragment_main(fragment_main_in in [[stage_in]], constant _11& _13 [[buffer(2)]], texture2d<float> _46 [[texture(1)]], sampler _50 [[sampler(1)]])
{
    if ((_13._m0.w * _46.sample(_50, float2(dot(_13._m2.xy, in.m_21) + _13._m2.z, dot(_13._m3.xy, in.m_21) + _13._m3.z)).w) < _13._m6.x)
    {
        discard_fragment();
    }
}

