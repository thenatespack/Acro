#version 450
#extension GL_GOOGLE_include_directive : require

// The sky behind the scene (SceneRenderer, after the opaque batches): a fullscreen triangle on
// the far plane, drawn where the depth test finds nothing nearer. Passes each corner's view
// ray to sky.frag.

#include "environment.glsl"
#include "sky_common.glsl"

layout(location = 0) out vec4 vRay;

void main() {
    vec2 p = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2) * 2.0 - 1.0;
    // Linear in the clip position, so interpolating it and dividing per pixel is exact.
    vRay = skyData.inverseViewProj * vec4(p, skyData.extra.x, 1.0);
    gl_Position = vec4(p, skyData.extra.x, 1.0);
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
