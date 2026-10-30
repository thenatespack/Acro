// Generated from outline_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5b2e3713436dd0c8
// glsl-fnv1a64: 4e8e08f628d5118e

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _11
{
    float4x4 _m0;
    float4 _m1;
};

struct fragment_main_out
{
    float4 m_9 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _11& _13 [[buffer(16)]])
{
    fragment_main_out out = {};
    out.m_9 = _13._m1;
    return out;
}

