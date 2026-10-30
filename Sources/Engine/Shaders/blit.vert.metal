// Generated from blit.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: fa787a348664c466

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _38
{
    float2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
};

struct vertex_main_out
{
    float2 m_57 [[user(locn0)]];
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(constant _38& _40 [[buffer(16)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float _18 = float((int(gl_VertexIndex) << 1) & 2);
    float _21 = float(int(gl_VertexIndex) & 2);
    out.gl_Position = float4(((float2(_18, _21) * 2.0) - float2(1.0)) * _40._m0, 0.0, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_57 = float2(_18, 1.0 - _21);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

