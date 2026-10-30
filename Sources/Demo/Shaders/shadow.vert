#version 450

// Depth-only pass: same uniforms and vertex layout as lit.vert, no fragment stage.
layout(set = 0, binding = 0, std140) uniform Scene {
    mat4 viewProj;
    mat4 lightViewProj;
    vec4 lightDir;
    vec4 cameraPos;
    vec4 fogColor;
    vec4 shadowParams;
} scene;

layout(location = 0) in vec3 inPosition;
layout(location = 2) in vec4 model0;
layout(location = 3) in vec4 model1;
layout(location = 4) in vec4 model2;
layout(location = 5) in vec4 model3;
layout(location = 7) in vec4 inParams;

// Instances with params.w > 0 spin about their local Y axis (1 rad/s) and bob vertically
// (amplitude params.w, 2 rad/s), offset by phase params.z. See `Instance.animated`.
mat3 spin(vec4 params, float time) {
    float c = cos(time + params.z), s = sin(time + params.z);
    return mat3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c);
}

float bob(vec4 params, float time) {
    return sin(time * 2.0 + params.z) * params.w;
}

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    vec4 world;
    if (inParams.w > 0.0) {
        world = model * vec4(spin(inParams, scene.cameraPos.w) * inPosition, 1.0)
            + vec4(0.0, bob(inParams, scene.cameraPos.w), 0.0, 0.0);
    } else {
        world = model * vec4(inPosition, 1.0);
    }
    gl_Position = scene.lightViewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
}
