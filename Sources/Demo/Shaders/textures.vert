#version 450

layout(set = 0, binding = 0, std140) uniform Scene {
    mat4 viewProj;
    mat4 lightViewProj;
    vec4 lightDir;
    vec4 cameraPos;
    vec4 fogColor;
    vec4 shadowParams;
    mat4 currentViewProj;   // unjittered, for motion vectors
    mat4 previousViewProj;  // last frame's, unjittered
} scene;

// Uniform buffer n is set 2, binding n (see `ShaderSource`).
layout(set = 2, binding = 2, std140) uniform Params {
    vec4 uvScale;
    vec4 tint;
} params;

layout(set = 2, binding = 3, std140) uniform FrameData {
    vec4 scroll;
} frame;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec4 model0;
layout(location = 3) in vec4 model1;
layout(location = 4) in vec4 model2;
layout(location = 5) in vec4 model3;

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec2 vUV;
layout(location = 3) out vec4 vCurrentClip;   // unjittered, for motion vectors
layout(location = 4) out vec4 vPreviousClip;

// Planar projection along the dominant axis of the (axis-aligned) face normal.
vec2 projectUV(vec3 world, vec3 normal) {
    vec3 a = abs(normal);
    if (a.y >= a.x && a.y >= a.z) return world.xz;
    return a.x >= a.z ? world.zy : world.xy;
}

void main() {
    mat4 model = mat4(model0, model1, model2, model3);
    vec4 world = model * vec4(inPosition, 1.0);
    gl_Position = scene.viewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vWorldPos = world.xyz;
    vNormal = inNormal;
    vUV = projectUV(world.xyz, inNormal) * params.uvScale.xy + frame.scroll.xy;
    // Static geometry: only the camera moves.
    vCurrentClip = scene.currentViewProj * world;
    vPreviousClip = scene.previousViewProj * world;
}
