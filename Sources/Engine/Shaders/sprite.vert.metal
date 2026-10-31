// Generated from sprite.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5a32036da3536a91
// glsl-fnv1a64: b8879fade431e363

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _17
{
    float4x4 _m0;
};

struct vertex_main_out
{
    float2 m_42 [[user(locn0)]];
    float4 m_46 [[user(locn1)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float3 m_25 [[attribute(0)]];
    float2 m_44 [[attribute(1)]];
    float4 m_48 [[attribute(2)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _17& _19 [[buffer(16)]])
{
    vertex_main_out out = {};
    out.gl_Position = _19._m0 * float4(in.m_25, 1.0);
    out.gl_Position.y = -out.gl_Position.y;
    out.m_42 = in.m_44;
    out.m_46 = in.m_48;
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

