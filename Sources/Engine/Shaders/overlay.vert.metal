// Generated from overlay.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: e4d11cc417eff009

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    float2 _m0;
};

struct vertex_main_out
{
    float4 m_56 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float2 m_11 [[attribute(0)]];
    float4 m_58 [[attribute(1)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _17& _19 [[buffer(16)]])
{
    vertex_main_out out = {};
    out.gl_Position = float4(((in.m_11.x / _19._m0.x) * 2.0) - 1.0, 1.0 - ((in.m_11.y / _19._m0.y) * 2.0), 0.0, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_56 = in.m_58;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

