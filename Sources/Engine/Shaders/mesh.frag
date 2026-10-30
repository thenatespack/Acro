#version 450

// See mesh.vert.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
    vec4 lightDir;
    vec4 lightColor;
    vec4 cameraPos;
    vec4 fogColor;
    vec4 skyColor;
    vec4 groundColor;
    vec4 shadowParams;
} frame;

// Must match `SceneRenderer.MaterialUniforms` (uniform buffer 2).
layout(set = 2, binding = 2, std140) uniform MaterialData {
    vec4 baseColor;  // linear rgb, a: opacity
    vec4 params;     // x: world-space checkerboard, y: emissive (0 lit .. 1 unlit), z: specular, w: shininess
    vec4 uvScale;    // xy: UV scale
} material;

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;
// Texture 1 / sampler 1: the material's albedo map (a 1x1 white texture when it has none).
layout(set = 2, binding = 9) uniform texture2D albedoMap;
layout(set = 2, binding = 17) uniform sampler albedoSampler;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vColor;
layout(location = 4) in vec4 vLightClip;
layout(location = 5) in vec4 vParams;
layout(location = 6) in vec4 vCurrentClip;
layout(location = 7) in vec4 vPreviousClip;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMotion;  // see `PipelineDescriptor.writesMotionVectors`

// Texture-space offset from this pixel to where its surface was last frame (0 if it was behind the camera).
vec2 motionVector(vec4 current, vec4 previous) {
    if (previous.w <= 0.0) return vec2(0.0);
    return (previous.xy / previous.w - current.xy / current.w) * vec2(0.5, -0.5);
}

// Tent-filtered PCF over (2r+1)² texels from 4 (r = 1) or 9 (r = 2) hardware comparison
// taps, each placed and weighted by where the sample falls inside its texel (Castaño,
// "Shadow Mapping Summary", 2013). Points outside the shadow frustum are lit.
float shadowFactor() {
    vec3 ndc = vLightClip.xyz / vLightClip.w;
    vec2 uv = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 1.0;
    float ref = min(ndc.z, 1.0) - frame.shadowParams.y;
    float texel = frame.shadowParams.x;
    int radius = int(frame.shadowParams.z);
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
    vec3 l = normalize(frame.lightDir.xyz);
    vec3 v = normalize(frame.cameraPos.xyz - vWorldPos);
    vec3 h = normalize(l + v);

    vec4 texel = texture(sampler2D(albedoMap, albedoSampler), vUV * material.uvScale.xy);
    vec3 albedo = vColor.rgb * material.baseColor.rgb * texel.rgb;
    float opacity = vColor.a * material.baseColor.a * texel.a;
    if (material.params.x > 0.5) {
        vec2 cell = floor(vWorldPos.xz / 2.0);
        albedo *= (mod(abs(cell.x + cell.y), 2.0) < 0.5) ? 1.0 : 0.75;
    }

    float shadow = (frame.lightColor.w > 0.5 && vParams.x > 0.5) ? shadowFactor() : 1.0;
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    float ndotl = dot(n, l);
    vec3 diffuse = max(ndotl, 0.0) * light;
    vec3 specular = pow(max(dot(n, h), 0.0), material.params.w) * material.params.z * step(0.0, ndotl) * light;
    vec3 ambient = mix(frame.groundColor.rgb, frame.skyColor.rgb, n.y * 0.5 + 0.5) * frame.skyColor.w;

    vec3 color = albedo * (ambient + diffuse * shadow) + specular * shadow;
    color = mix(color, albedo, material.params.y);
    float dist = length(frame.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * frame.fogColor.w);
    outColor = vec4(mix(color, frame.fogColor.rgb, fog), opacity);
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
