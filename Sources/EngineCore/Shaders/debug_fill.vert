#version 450

// Filled debug triangles (DebugDraw.triangle and the shapes built from it): one instance per
// triangle, its corner picked by the vertex index. Flat color, no lighting.

layout(location = 0) in vec4 inA;      // xyz: first corner
layout(location = 1) in vec4 inB;
layout(location = 2) in vec4 inC;
layout(location = 3) in vec4 inColor;  // linear RGBA

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
    vec4 viewport;  // unused here; the layout is shared with debug_line
} pc;

layout(location = 0) out vec4 vColor;

void main() {
    vec3 p = gl_VertexIndex == 0 ? inA.xyz : (gl_VertexIndex == 1 ? inB.xyz : inC.xyz);
    vColor = inColor;
    gl_Position = pc.viewProj * vec4(p, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
