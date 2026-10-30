// Generated from shadow.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 9880248748432611

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _105
{
    float4x4 _m0;
    float4x4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
};

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_118 [[attribute(0)]];
    float4 m_66 [[attribute(2)]];
    float4 m_68 [[attribute(3)]];
    float4 m_70 [[attribute(4)]];
    float4 m_72 [[attribute(5)]];
    float4 m_95 [[attribute(7)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _105& _107 [[buffer(15)]])
{
    vertex_main_out out = {};
    float4x4 _94 = float4x4(in.m_66, in.m_68, in.m_70, in.m_72);
    float4 _200;
    if (in.m_95.w > 0.0)
    {
        float _169 = _107._m3.w + in.m_95.z;
        float _170 = cos(_169);
        float _175 = sin(_169);
        _200 = (_94 * float4(float3x3(float3(_170, 0.0, -_175), float3(0.0, 1.0, 0.0), float3(_175, 0.0, _170)) * in.m_118, 1.0)) + float4(0.0, sin((_107._m3.w * 2.0) + in.m_95.z) * in.m_95.w, 0.0, 0.0);
    }
    else
    {
        _200 = _94 * float4(in.m_118, 1.0);
    }
    out.gl_Position = _107._m1 * _200;
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

