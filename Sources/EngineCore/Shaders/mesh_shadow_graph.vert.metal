// Generated from mesh_shadow_graph.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6133b9a3efa5b550
// glsl-fnv1a64: 6230ab88e9fefa9d

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _109
{
    float4x4 _m0;
    float4x4 _m1;
};

struct vertex_main_out
{
    float3 m_126 [[user(locn0)]];
    float3 m_129 [[user(locn1)]];
    float2 m_138 [[user(locn2)]];
    float4 m_142 [[user(locn3)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_48 [[attribute(0)]];
    float3 m_131 [[attribute(1)]];
    float2 m_140 [[attribute(2)]];
    float4 m_12 [[attribute(3)]];
    float4 m_14 [[attribute(4)]];
    float4 m_16 [[attribute(5)]];
    float4 m_18 [[attribute(6)]];
    float4 m_143 [[attribute(11)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _109& _111 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _54 = float4x4(in.m_12, in.m_14, in.m_16, in.m_18) * float4(in.m_48, 1.0);
    float3 _76 = cross(in.m_12.xyz, in.m_14.xyz);
    out.gl_Position = _111._m1 * _54;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_126 = _54.xyz;
    out.m_129 = (float3x3(cross(in.m_14.xyz, in.m_16.xyz), cross(in.m_16.xyz, in.m_12.xyz), _76) * in.m_131) * ((dot(_76, in.m_16.xyz) < 0.0) ? (-1.0) : 1.0);
    out.m_138 = in.m_140;
    out.m_142 = in.m_143;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

