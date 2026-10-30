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
layout(location = 5) in vec4 vCurrentClip;
layout(location = 6) in vec4 vPreviousClip;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMotion;  // see `PipelineDescriptor.writesMotionVectors`

// Texture-space offset from this pixel to where its surface was last frame (0 if it was behind the camera).
vec2 motionVector(vec4 current, vec4 previous) {
    if (previous.w <= 0.0) return vec2(0.0);
    return (previous.xy / previous.w - current.xy / current.w) * vec2(0.5, -0.5);
}

// Tent-filtered PCF over (2r+1)² texels from 4 (r = 1) or 9 (r = 2) hardware comparison
// taps, each placed and weighted by where the sample falls inside its texel (Castaño,
// "Shadow Mapping Summary", 2013). Taps are 2x2 bilinear compares, so each covers four texels.
float shadowFactor() {
    vec3 ndc = vLightClip.xyz / vLightClip.w;
    vec2 uv = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
    float ref = min(ndc.z, 1.0) - scene.shadowParams.y;
    float texel = scene.shadowParams.x;
    int radius = int(scene.shadowParams.z);
    if (radius <= 0) return texture(shadowMap, vec3(uv, ref));

    vec2 p = uv / texel;  // in texels
    vec2 base = floor(p + 0.5);
    vec2 st = p + 0.5 - base;
    base = (base - 0.5) * texel;
    vec2 w[3], o[3];
    int n;
    float norm;
    if (radius == 1) {
        w[0] = 3.0 - 2.0 * st; w[1] = 1.0 + 2.0 * st;
        o[0] = (2.0 - st) / w[0] - 1.0; o[1] = st / w[1] + 1.0;
        n = 2;
        norm = 1.0 / 16.0;
    } else {
        w[0] = 4.0 - 3.0 * st; w[1] = vec2(7.0); w[2] = 1.0 + 3.0 * st;
        o[0] = (3.0 - 2.0 * st) / w[0] - 2.0; o[1] = (3.0 + st) / w[1]; o[2] = st / w[2] + 2.0;
        n = 3;
        norm = 1.0 / 144.0;
    }
    float sum = 0.0;
    for (int j = 0; j < n; j++) {
        for (int i = 0; i < n; i++) {
            sum += w[i].x * w[j].y * texture(shadowMap, vec3(base + vec2(o[i].x, o[j].y) * texel, ref));
        }
    }
    return sum * norm;
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
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
