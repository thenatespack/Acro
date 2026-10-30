// Generated from debug_fill.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 28cb792195098208
// glsl-fnv1a64: 22218318aeeefe3b

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _52
{
    float4x4 _m0;
    float4 _m1;
};

struct vertex_main_out
{
    float4 m_42 [[user(locn0)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float4 m_22 [[attribute(0)]];
    float4 m_32 [[attribute(1)]];
    float4 m_36 [[attribute(2)]];
    float4 m_43 [[attribute(3)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _52& _54 [[buffer(16)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    float3 _72;
    if (int(gl_VertexIndex) == 0)
    {
        _72 = in.m_22.xyz;
    }
    else
    {
        float3 _71;
        if (int(gl_VertexIndex) == 1)
        {
            _71 = in.m_32.xyz;
        }
        else
        {
            _71 = in.m_36.xyz;
        }
        _72 = _71;
    }
    out.m_42 = in.m_43;
    out.gl_Position = _54._m0 * float4(_72, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

