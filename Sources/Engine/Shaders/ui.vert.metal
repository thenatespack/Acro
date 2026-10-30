// Generated from ui.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 365ff86fa6efada9

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
    float2 m_64 [[user(locn2)]];
    float2 m_67 [[user(locn3)]];
    float4 m_70 [[user(locn4)]];
    float4 m_73 [[user(locn5)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float2 m_11 [[attribute(0)]];
    float2 m_58 [[attribute(1)]];
    float4 m_62 [[attribute(2)]];
    float2 m_65 [[attribute(3)]];
    float2 m_68 [[attribute(4)]];
    float4 m_71 [[attribute(5)]];
    float4 m_74 [[attribute(6)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _17& _19 [[buffer(16)]])
{
    vertex_main_out out = {};
    out.gl_Position = float4(((in.m_11.x / _19._m0.x) * 2.0) - 1.0, 1.0 - ((in.m_11.y / _19._m0.y) * 2.0), 0.0, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_57 = in.m_58;
    out.m_60 = in.m_62;
    out.m_64 = in.m_65;
    out.m_67 = in.m_68;
    out.m_70 = in.m_71;
    out.m_73 = in.m_74;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

