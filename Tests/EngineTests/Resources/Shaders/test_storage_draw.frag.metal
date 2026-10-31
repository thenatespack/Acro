// Generated from test_storage_draw.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4cfabfada863d48f
// glsl-fnv1a64: a80ff571cdad8bd3

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _10
{
    float4 _m0;
};

struct fragment_main_out
{
    float4 m_9 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _10& _12 [[buffer(16)]])
{
    fragment_main_out out = {};
    out.m_9 = _12._m0;
    return out;
}

