#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's depth-only passes (shadow atlas, depth prepass) for materials with wind:
// mesh_shadow_mask.vert with the same sway as mesh_wind.vert (wind.glsl), so shadows and depth
// follow the swaying surface. Paired with mesh_shadow_mask.frag for alpha-tested materials and
// with no fragment stage otherwise.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
} frame;

#include "wind.glsl"

layout(location = 0) in vec3 inPosition;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;

layout(location = 0) out vec2 vUV;

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    vec3 base = (model * vec4(wind.plant.xyz, 1.0)).xyz;
    vec3 swayed = inPosition + windOffset(inPosition, mat3(model0.xyz, model1.xyz, model2.xyz), base, wind.clock.x);
    gl_Position = frame.lightViewProj * (model * vec4(swayed, 1.0));
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
}
