#version 450

// SDF text: positions in framebuffer pixels (top-left origin), atlas UVs, per-vertex RGBA.

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec4 inColor;

layout(push_constant) uniform PushConstants {
    vec2 screenSize;
} pc;

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec4 vColor;

void main() {
    vec2 ndc = vec2(inPosition.x / pc.screenSize.x * 2.0 - 1.0,
                    1.0 - inPosition.y / pc.screenSize.y * 2.0);
    gl_Position = vec4(ndc, 0.0, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
    vColor = inColor;
}
