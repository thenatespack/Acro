#version 450

// SceneRenderer's shadow pass for alpha-tested materials (AlphaMode.mask): mesh_shadow.vert
// plus the UVs mesh_shadow_mask.frag needs to sample the base color alpha.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
} frame;

layout(location = 0) in vec3 inPosition;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;

layout(location = 0) out vec2 vUV;

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    gl_Position = frame.lightViewProj * (model * vec4(inPosition, 1.0));
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vUV = inUV;
}
