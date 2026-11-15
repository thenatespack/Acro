// Generated from mesh.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 093eb360912cbc6a
// glsl-fnv1a64: 7c73fbb0f3ab98ad

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _147
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    float4 _m9;
    float4 _m10;
};

struct vertex_main_out
{
    float3 m_163 [[user(locn0)]];
    float3 m_166 [[user(locn1)]];
    float2 m_175 [[user(locn2)]];
    float4 m_179 [[user(locn3)]];
    float4 m_182 [[user(locn5)]];
    float4 m_185 [[user(locn6)]];
    float4 m_191 [[user(locn7)]];
    float4 m_197 [[user(locn8)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_78 [[attribute(0)]];
    float3 m_168 [[attribute(1)]];
    float2 m_177 [[attribute(2)]];
    float4 m_12 [[attribute(3)]];
    float4 m_14 [[attribute(4)]];
    float4 m_16 [[attribute(5)]];
    float4 m_18 [[attribute(6)]];
    float4 m_44 [[attribute(7)]];
    float4 m_46 [[attribute(8)]];
    float4 m_48 [[attribute(9)]];
    float4 m_50 [[attribute(10)]];
    float4 m_180 [[attribute(11)]];
    float4 m_183 [[attribute(12)]];
    float4 m_214 [[attribute(13)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _147& _149 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4 _83 = float4(in.m_78, 1.0);
    float4 _84 = float4x4(in.m_12, in.m_14, in.m_16, in.m_18) * _83;
    float3 _114 = cross(in.m_12.xyz, in.m_14.xyz);
    float _138 = (dot(_114, in.m_16.xyz) < 0.0) ? (-1.0) : 1.0;
    out.gl_Position = _149._m0 * _84;
    out.gl_Position.y = -out.gl_Position.y;
    out.m_163 = _84.xyz;
    out.m_166 = (float3x3(cross(in.m_14.xyz, in.m_16.xyz), cross(in.m_16.xyz, in.m_12.xyz), _114) * in.m_168) * _138;
    out.m_175 = in.m_177;
    out.m_179 = in.m_180;
    out.m_182 = in.m_183;
    out.m_185 = _149._m2 * _84;
    out.m_191 = _149._m3 * (float4x4(in.m_44, in.m_46, in.m_48, in.m_50) * _83);
    out.m_197 = float4(float3x3(float3(in.m_12.xyz), float3(in.m_14.xyz), float3(in.m_16.xyz)) * in.m_214.xyz, in.m_214.w * _138);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

