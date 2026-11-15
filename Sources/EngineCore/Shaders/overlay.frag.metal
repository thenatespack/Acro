// Generated from overlay.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4879c39683ce66e0
// glsl-fnv1a64: 8a2785e21cb5ab84

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_9 [[color(0)]];
};

struct fragment_main_in
{
    float4 m_11 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]])
{
    fragment_main_out out = {};
    out.m_9 = in.m_11;
    return out;
}

