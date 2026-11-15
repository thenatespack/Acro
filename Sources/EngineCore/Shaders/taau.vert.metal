// Generated from taau.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5e5203b53f286cc8
// glsl-fnv1a64: 76eadab7dc82f085

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct vertex_main_out
{
    float4 gl_Position [[position]];
};

vertex vertex_main_out vertex_main(uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    out.gl_Position = float4((float2(float((int(gl_VertexIndex) << 1) & 2), float(int(gl_VertexIndex) & 2)) * 2.0) - float2(1.0), 0.0, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

