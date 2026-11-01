// Generated from text3d.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5e7e76e20eaacb81
// glsl-fnv1a64: 9505a72cad9404a7

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _12
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _23
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
};

struct vertex_main_out
{
    float2 m_131 [[user(locn0)]];
    float m_134 [[user(locn1)]];
    float m_104 [[user(locn2)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float2 m_61 [[attribute(0)]];
    float2 m_132 [[attribute(1)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _12& _14 [[buffer(2)]], constant _23& _25 [[buffer(15)]])
{
    vertex_main_out out = {};
    float _141;
    float3 _142;
    if (_14._m1.w > 0.5)
    {
        _142 = (_14._m0[3].xyz + (_14._m1.xyz * (in.m_61.x * length(_14._m0[0].xyz)))) + (_14._m2.xyz * (in.m_61.y * length(_14._m0[1].xyz)));
        _141 = 1.0;
    }
    else
    {
        _142 = (_14._m0 * float4(in.m_61, 0.0, 1.0)).xyz;
        _141 = dot(cross(_14._m0[0].xyz, _14._m0[1].xyz), _25._m6.xyz - _14._m0[3].xyz);
    }
    out.m_104 = float((_14._m2.w < 0.5) || (_141 >= 0.0));
    out.gl_Position = _25._m0 * float4(_142, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_131 = in.m_132;
    out.m_134 = length(_25._m6.xyz - _142);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

