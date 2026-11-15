#version 450

// Sprites: world-space corners (z included, so a perspective camera works too) transformed by
// the camera's view-projection, atlas UVs, per-vertex linear RGBA tint.

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec4 inColor;

layout(push_constant) uniform PushConstants {
    mat4 viewProj;
} pc;

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec4 vColor;

void main() {
    gl_Position = pc.viewProj * vec4(inPosition, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
    vColor = inColor;
}
