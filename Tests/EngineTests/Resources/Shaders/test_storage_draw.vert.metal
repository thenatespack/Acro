// Generated from test_storage_draw.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: effb75d5503ba7d4
// glsl-fnv1a64: f15c6698ad57ead3

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    float4 _m0[1];
};

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(const device _17& _19 [[buffer(20)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    out.gl_Position = _19._m0[int(gl_VertexIndex)];
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

