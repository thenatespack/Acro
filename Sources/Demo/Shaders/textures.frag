#version 450

layout(set = 0, binding = 0, std140) uniform Scene {
    mat4 viewProj;
    mat4 lightViewProj;
    vec4 lightDir;
    vec4 cameraPos;
    vec4 fogColor;
    vec4 shadowParams;
} scene;

layout(set = 2, binding = 2, std140) uniform Params {
    vec4 uvScale;
    vec4 tint;
} params;

// Texture n is set 2, binding 8 + n; sampler n is binding 16 + n (see `ShaderSource`).
layout(set = 2, binding = 9) uniform texture2D albedoMap;
layout(set = 2, binding = 17) uniform sampler albedoSampler;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;

layout(location = 0) out vec4 outColor;

void main() {
    vec3 albedo = texture(sampler2D(albedoMap, albedoSampler), vUV).rgb * params.tint.rgb;
    vec3 n = normalize(vNormal);
    vec3 l = normalize(scene.lightDir.xyz);
    float diffuse = max(dot(n, l), 0.0) * scene.lightDir.w;
    vec3 sky = vec3(0.55, 0.65, 0.85), ground = vec3(0.12, 0.1, 0.09);
    vec3 ambient = mix(ground, sky, n.y * 0.5 + 0.5) * 0.3;
    vec3 color = albedo * (ambient + diffuse);
    float dist = length(scene.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * scene.fogColor.w);
    outColor = vec4(mix(color, scene.fogColor.rgb, fog), 1.0);
}
