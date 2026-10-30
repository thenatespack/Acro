#version 450

// 2D UI: positions in framebuffer pixels (top-left origin). Everything the fragment shader
// needs to shade a rounded box analytically (see UIDrawList.swift for the vertex format).

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec4 inColor;     // sRGB, straight alpha
layout(location = 3) in vec2 inLocal;     // position relative to the box center, pixels
layout(location = 4) in vec2 inHalfSize;  // box half extents, pixels
layout(location = 5) in vec4 inRadii;     // corner radii: top-left, top-right, bottom-right, bottom-left
layout(location = 6) in vec4 inParams;    // x: stroke width (0 = filled), y: mode, z: SDF smoothing

layout(push_constant) uniform PushConstants {
    vec2 screenSize;
} pc;

layout(location = 0) out vec2 vUV;
layout(location = 1) out vec4 vColor;
layout(location = 2) out vec2 vLocal;
layout(location = 3) flat out vec2 vHalfSize;
layout(location = 4) flat out vec4 vRadii;
layout(location = 5) flat out vec4 vParams;

void main() {
    vec2 ndc = vec2(inPosition.x / pc.screenSize.x * 2.0 - 1.0,
                    1.0 - inPosition.y / pc.screenSize.y * 2.0);
    gl_Position = vec4(ndc, 0.0, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
    vColor = inColor;
    vLocal = inLocal;
    vHalfSize = inHalfSize;
    vRadii = inRadii;
    vParams = inParams;
}
