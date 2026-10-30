#version 450

layout(set = 0, binding = 0, std140) uniform Scene {
    mat4 viewProj;
    mat4 lightViewProj;
    vec4 lightDir;
    vec4 cameraPos;
    vec4 fogColor;
    vec4 shadowParams;
} scene;

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec4 vColor;
layout(location = 3) in vec4 vLightClip;
layout(location = 4) in vec4 vParams;

layout(location = 0) out vec4 outColor;

float shadowFactor() {
    vec3 ndc = vLightClip.xyz / vLightClip.w;
    vec2 uv = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
    float ref = min(ndc.z, 1.0) - scene.shadowParams.y;
    float texel = scene.shadowParams.x;
    int radius = int(scene.shadowParams.z);
    float sum = 0.0;
    for (int y = -radius; y <= radius; y++) {
        for (int x = -radius; x <= radius; x++) {
            sum += texture(shadowMap, vec3(uv + vec2(x, y) * texel, ref));
        }
    }
    float taps = float(2 * radius + 1);
    return sum / (taps * taps);
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 l = normalize(scene.lightDir.xyz);
    vec3 v = normalize(scene.cameraPos.xyz - vWorldPos);
    vec3 h = normalize(l + v);

    vec3 albedo = vColor.rgb;
    if (vParams.x > 0.5) {
        vec2 cell = floor(vWorldPos.xz / 2.0);
        albedo *= (mod(abs(cell.x + cell.y), 2.0) < 0.5) ? 1.0 : 0.75;
    }

    float shadow = shadowFactor();
    float diffuse = max(dot(n, l), 0.0) * scene.lightDir.w;
    float specular = pow(max(dot(n, h), 0.0), 48.0) * 0.35 * step(0.0, dot(n, l));
    vec3 sky = vec3(0.55, 0.65, 0.85), ground = vec3(0.12, 0.1, 0.09);
    vec3 ambient = mix(ground, sky, n.y * 0.5 + 0.5) * 0.3;

    vec3 color = albedo * (ambient + diffuse * shadow) + specular * shadow;
    color = mix(color, albedo, vParams.y);
    float dist = length(scene.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * scene.fogColor.w);
    outColor = vec4(mix(color, scene.fogColor.rgb, fog), vColor.a);
}
