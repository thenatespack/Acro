// Generated from text.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: bc688fff75e73d03
// glsl-fnv1a64: b8746969b989bf75

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    float2 _m0;
};

struct vertex_main_out
{
    float2 m_57 [[user(locn0)]];
    float4 m_60 [[user(locn1)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float2 m_11 [[attribute(0)]];
    float2 m_58 [[attribute(1)]];
    float4 m_62 [[attribute(2)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _17& _19 [[buffer(16)]])
{
    vertex_main_out out = {};
    out.gl_Position = float4(((in.m_11.x / _19._m0.x) * 2.0) - 1.0, 1.0 - ((in.m_11.y / _19._m0.y) * 2.0), 0.0, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_57 = in.m_58;
    out.m_60 = in.m_62;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

