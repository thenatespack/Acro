#version 450

// Draws the offscreen scene image into the window. A fullscreen triangle scaled by
// `scale` (≤ 1 per axis) letterboxes it while keeping its aspect ratio.

layout(push_constant) uniform PushConstants {
    vec2 scale;
} pc;

layout(location = 0) out vec2 vUV;

void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    gl_Position = vec4((p * 2.0 - 1.0) * pc.scale, 0.0, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = vec2(p.x, 1.0 - p.y);
}
