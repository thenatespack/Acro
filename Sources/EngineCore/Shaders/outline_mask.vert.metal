// Generated from outline_mask.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: ed441242b7c519be
// glsl-fnv1a64: 4e6b65dc72c0e978

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _51
{
    float4x4 _m0;
    float4 _m1;
};

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_60 [[attribute(0)]];
    float4 m_12 [[attribute(3)]];
    float4 m_14 [[attribute(4)]];
    float4 m_16 [[attribute(5)]];
    float4 m_18 [[attribute(6)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _51& _53 [[buffer(16)]])
{
    vertex_main_out out = {};
    out.gl_Position = _53._m0 * (float4x4(in.m_12, in.m_14, in.m_16, in.m_18) * float4(in.m_60, 1.0));
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

