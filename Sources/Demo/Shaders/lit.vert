#version 450

// Must match `SceneUniforms` in Renderer.swift.
layout(set = 0, binding = 0, std140) uniform Scene {
    mat4 viewProj;      // jittered with a temporal upscaler
    mat4 lightViewProj;
    vec4 lightDir;      // xyz: direction toward the light, w: intensity
    vec4 cameraPos;     // xyz: eye, w: time
    vec4 fogColor;      // rgb: fog/sky color, w: density
    vec4 shadowParams;  // x: shadow-map texel size, y: depth bias, z: PCF radius in texels
    mat4 currentViewProj;   // unjittered, for motion vectors
    mat4 previousViewProj;  // last frame's, unjittered
    vec4 motionParams;      // x: last frame's time
} scene;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec4 model0;
layout(location = 3) in vec4 model1;
layout(location = 4) in vec4 model2;
layout(location = 5) in vec4 model3;
layout(location = 6) in vec4 inColor;   // a: opacity
layout(location = 7) in vec4 inParams;  // x: checkerboard, y: emissive (0 lit .. 1 unlit)

layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
layout(location = 2) out vec4 vColor;
layout(location = 3) out vec4 vLightClip;
layout(location = 4) out vec4 vParams;
layout(location = 5) out vec4 vCurrentClip;   // unjittered, for motion vectors
layout(location = 6) out vec4 vPreviousClip;

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
    vec3 position = inPosition, normal = inNormal;
    vec4 world, previousWorld;
    if (inParams.w > 0.0) {
        mat3 r = spin(inParams, scene.cameraPos.w);
        position = r * position;
        normal = r * normal;
        world = model * vec4(position, 1.0) + vec4(0.0, bob(inParams, scene.cameraPos.w), 0.0, 0.0);
        // Where the animation had this vertex last frame, for motion vectors.
        float previousTime = scene.motionParams.x;
        previousWorld = model * vec4(spin(inParams, previousTime) * inPosition, 1.0)
            + vec4(0.0, bob(inParams, previousTime), 0.0, 0.0);
    } else {
        world = model * vec4(position, 1.0);
        previousWorld = world;
    }
    // model = T * R * S, so R * (n / s) is the correctly transformed normal.
    vec3 scaleSq = vec3(dot(model0.xyz, model0.xyz), dot(model1.xyz, model1.xyz), dot(model2.xyz, model2.xyz));
    mat3 m3 = mat3(model0.xyz, model1.xyz, model2.xyz);

    gl_Position = scene.viewProj * world;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    vWorldPos = world.xyz;
    vNormal = m3 * (normal / scaleSq);
    vColor = inColor;
    vParams = inParams;
    vLightClip = scene.lightViewProj * world;
    vCurrentClip = scene.currentViewProj * world;
    vPreviousClip = scene.previousViewProj * previousWorld;
}
