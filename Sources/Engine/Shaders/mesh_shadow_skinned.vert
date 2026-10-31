#version 450
#extension GL_GOOGLE_include_directive : require

// mesh_shadow.vert for skinned casters (joint matrices from skinning.glsl).
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
} frame;

#include "skinning.glsl"

layout(location = 0) in vec3 inPosition;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;

void main() {
    mat4 model = mat4(model0, model1, model2, model3) * skinMatrix();
    gl_Position = frame.lightViewProj * (model * vec4(inPosition, 1.0));
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
