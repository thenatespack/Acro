// Generated from sky.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4235d2bddf84cd91
// glsl-fnv1a64: ad1a15be52517b55

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _32
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
};

struct vertex_main_out
{
    float4 m_30 [[user(locn0)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _32& _34 [[buffer(2)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float2 _27 = (float2(float((int(gl_VertexIndex) << 1) & 2), float(int(gl_VertexIndex) & 2)) * 2.0) - float2(1.0);
    float _45 = _27.x;
    float4 _47 = float4(_45, _27.y, _34._m2.x, 1.0);
    out.m_30 = _34._m0 * _47;
    if (_34._m2.z > 0.5)
    {
        float4 _68 = _34._m0 * float4(_45, _27.y, 1.0 - _34._m2.x, 1.0);
        out.m_30 = float4((out.m_30.xyz / float3(out.m_30.w)) - (_68.xyz / float3(_68.w)), 1.0);
    }
    out.gl_Position = _47;
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

