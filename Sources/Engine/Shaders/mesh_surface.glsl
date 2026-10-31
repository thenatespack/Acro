// SceneRenderer's lit forward fragment shader, included by mesh.frag and by mesh_mask.frag
// (which defines ALPHA_MASK: fragments below the material's alpha cutoff are discarded).
// Not compiled on its own (Scripts/compile-shaders.sh only compiles .vert / .frag); rerun the
// script after editing it. See mesh.vert for the vertex stage.
//
// Shading models (material.emissive.w):
// - Blinn-Phong (0): the engine's original model, kept bit for bit so older scenes look the same.
// - PBR (1): glTF metallic-roughness. Direct light: Lambert diffuse plus Cook-Torrance GGX
//   specular with height-correlated Smith visibility and Schlick Fresnel, both scaled by pi so
//   a white Lambert surface facing the light reflects exactly the light's color x intensity
//   (the same light units as Blinn-Phong). Diffuse is weighted by 1 - F. Ambient: the
//   hemisphere light as irradiance for diffuse, and for specular the hemisphere seen along the
//   reflection vector (blurred toward the irradiance with roughness) times Karis' analytic
//   split-sum DFG approximation, so metals aren't black away from the sun. No cubemap IBL.
//
// Point and spot lights (clustered forward, see `LightClusters`): the fragment finds its
// cluster from gl_FragCoord (screen tile) and its view depth (logarithmic slice), then loops
// over that cluster's lights. Each adds the same direct BRDF as the sun (per shading model),
// with radiance color x intensity / d² windowed smoothly to zero at the light's range
// (Karis 2013: saturate(1 - (d/range)^4)²) and, for spots, saturate(cos x scale + offset)²
// between the outer and inner cone. No shadows. Without lights the loop is skipped entirely.

// Must match `SceneRenderer.FrameUniforms`.
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
    vec4 viewDepth;      // view depth of a world position: dot(viewDepth.xyz, p) + viewDepth.w
    vec4 clusterScale;   // xy: tiles per pixel, z: slice scale, w: slice bias (slice = log2(depth) * z + w)
    vec4 clusterGrid;    // xyz: tiles x, tiles y, slices; w: 1 when there are point/spot lights
} frame;

// Must match `SceneRenderer.MaterialUniforms` (uniform buffer 2).
layout(set = 2, binding = 2, std140) uniform MaterialData {
    vec4 baseColor;  // linear rgb, a: opacity
    vec4 params;     // x: world-space checkerboard, y: unlit (0 lit .. 1 unlit), z: specular, w: shininess (Blinn-Phong)
    vec4 uvRow0;     // UV transform, rows of a 2x3 matrix: uv' = (dot(row0.xy, uv) + row0.z, dot(row1.xy, uv) + row1.z)
    vec4 uvRow1;
    vec4 surface;    // x: metallic, y: perceptual roughness, z: normal scale, w: occlusion strength
    vec4 emissive;   // rgb: emissive color x strength (linear), w: 1 PBR, 0 Blinn-Phong
    vec4 flags;      // x: alpha cutoff (mask), y: 1 when there is a normal map
} material;

// Point and spot lights, must match `LightClusters.GPUData` (uniform buffers 3-7).
layout(set = 2, binding = 3, std140) uniform LightPositions {
    vec4 data[1024];  // xyz: world position, w: 1 / range²
} lightPositions;
layout(set = 2, binding = 4, std140) uniform LightColors {
    vec4 data[1024];  // rgb: color x intensity, w: spot scale (0: point light)
} lightColors;
layout(set = 2, binding = 5, std140) uniform LightDirections {
    vec4 data[1024];  // xyz: spot direction (travel), w: spot offset (1: point light)
} lightDirections;
layout(set = 2, binding = 6, std140) uniform LightCells {
    uvec4 data[1024];  // a word per cluster, 4 per uvec4: first index | count << 16
} lightCells;
layout(set = 2, binding = 7, std140) uniform LightIndices {
    uvec4 data[1024];  // 10-bit light indices, 3 per word (bits 0, 10, 20), 4 words per uvec4
} lightIndices;

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;
// Textures 1-5 share sampler 1. Missing ones are a 1x1 white texture.
layout(set = 2, binding = 9) uniform texture2D baseColorMap;          // sRGB color, alpha
layout(set = 2, binding = 10) uniform texture2D metallicRoughnessMap; // linear: G roughness, B metallic
layout(set = 2, binding = 11) uniform texture2D normalMap;            // linear tangent-space normal
layout(set = 2, binding = 12) uniform texture2D occlusionMap;         // linear: R occlusion
layout(set = 2, binding = 13) uniform texture2D emissiveMap;          // sRGB color
layout(set = 2, binding = 17) uniform sampler materialSampler;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vColor;
layout(location = 4) in vec4 vLightClip;
layout(location = 5) in vec4 vParams;
layout(location = 6) in vec4 vCurrentClip;
layout(location = 7) in vec4 vPreviousClip;
layout(location = 8) in vec4 vTangent;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMotion;  // see `PipelineDescriptor.writesMotionVectors`

const float PI = 3.14159265;

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

// The hemisphere ambient light arriving from direction d (sky above, ground below).
vec3 hemisphere(vec3 d) {
    return mix(frame.groundColor.rgb, frame.skyColor.rgb, d.y * 0.5 + 0.5) * frame.skyColor.w;
}

// GGX / Trowbridge-Reitz normal distribution, a = roughness².
float distributionGGX(float NoH, float a) {
    float a2 = a * a;
    float d = NoH * NoH * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

// Height-correlated Smith visibility, V = G / (4 NoL NoV) (Heitz 2014).
float visibilitySmithGGXCorrelated(float NoV, float NoL, float a) {
    float a2 = a * a;
    float ggxV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float ggxL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / max(ggxV + ggxL, 1e-5);
}

vec3 fresnelSchlick(vec3 f0, float VoH) {
    float f = pow(1.0 - VoH, 5.0);
    return f0 + (vec3(1.0) - f0) * f;
}

// Karis' analytic fit of the split-sum environment BRDF ("Physically Based Shading on
// Mobile", 2014): scale and bias applied to F0.
vec2 environmentBRDF(float NoV, float roughness) {
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
}

// The radiance arriving from point / spot light `i`, and the unit direction toward it in `l`.
vec3 punctualRadiance(uint i, out vec3 l) {
    vec4 position = lightPositions.data[i];
    vec3 toLight = position.xyz - vWorldPos;
    float d2 = dot(toLight, toLight);
    float x = d2 * position.w;  // (d / range)²
    float window = clamp(1.0 - x * x, 0.0, 1.0);
    l = toLight * inversesqrt(max(d2, 1e-8));
    vec4 color = lightColors.data[i];
    vec4 direction = lightDirections.data[i];
    float cone = clamp(dot(-l, direction.xyz) * color.w + direction.w, 0.0, 1.0);
    return color.rgb * (window * window * cone * cone / max(d2, 1e-4));
}

// This fragment's cluster: first light index (x) and count (y).
uvec2 clusterLights() {
    float depth = dot(frame.viewDepth.xyz, vWorldPos) + frame.viewDepth.w;
    vec2 tile = clamp(floor(gl_FragCoord.xy * frame.clusterScale.xy), vec2(0.0), frame.clusterGrid.xy - 1.0);
    float slice = clamp(floor(log2(max(depth, 1e-6)) * frame.clusterScale.z + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
    uint cluster = uint((slice * frame.clusterGrid.y + tile.y) * frame.clusterGrid.x + tile.x);
    uint cell = lightCells.data[cluster >> 2][cluster & 3u];
    return uvec2(cell & 0xFFFFu, cell >> 16);
}

uint lightIndex(uint i) {
    uint word = i / 3u;
    return (lightIndices.data[word >> 2][word & 3u] >> ((i - word * 3u) * 10u)) & 0x3FFu;
}

void main() {
    vec2 uv = vec2(dot(material.uvRow0.xy, vUV) + material.uvRow0.z, dot(material.uvRow1.xy, vUV) + material.uvRow1.z);
    vec4 texel = texture(sampler2D(baseColorMap, materialSampler), uv);
    vec3 albedo = vColor.rgb * material.baseColor.rgb * texel.rgb;
    float opacity = vColor.a * material.baseColor.a * texel.a;
#ifdef ALPHA_MASK
    // glTF MASK: the material's alpha decides coverage; what's kept is opaque (the instance's
    // opacity still fades it in the transparent pass).
    if (material.baseColor.a * texel.a < material.flags.x) discard;
    opacity = vColor.a;
#endif
    if (material.params.x > 0.5) {
        vec2 cell = floor(vWorldPos.xz / 2.0);
        albedo *= (mod(abs(cell.x + cell.y), 2.0) < 0.5) ? 1.0 : 0.75;
    }

    vec3 n = normalize(vNormal);
    if (material.flags.y > 0.5) {
        // Tangent frame from the interpolated vertex tangent, re-orthogonalized.
        vec3 t = vTangent.xyz - n * dot(n, vTangent.xyz);
        if (dot(t, t) > 1e-12) {
            t = normalize(t);
            vec3 b = cross(n, t) * (vTangent.w < 0.0 ? -1.0 : 1.0);
            vec3 m = texture(sampler2D(normalMap, materialSampler), uv).xyz * 2.0 - 1.0;
            m.xy *= material.surface.z;
            n = normalize(t * m.x + b * m.y + n * m.z);
        }
    }
    bool pbr = material.emissive.w > 0.5;
    // Double-sided PBR materials light their back faces from behind.
    if (pbr && !gl_FrontFacing) n = -n;

    vec3 l = normalize(frame.lightDir.xyz);
    vec3 v = normalize(frame.cameraPos.xyz - vWorldPos);
    vec3 h = normalize(l + v);
    float shadow = (frame.lightColor.w > 0.5 && vParams.x > 0.5) ? shadowFactor() : 1.0;
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    float ao = 1.0 + material.surface.w * (texture(sampler2D(occlusionMap, materialSampler), uv).r - 1.0);

    vec3 color;
    if (!pbr) {
        float ndotl = dot(n, l);
        vec3 diffuse = max(ndotl, 0.0) * light;
        vec3 specular = pow(max(dot(n, h), 0.0), material.params.w) * material.params.z * step(0.0, ndotl) * light;
        vec3 ambient = hemisphere(n) * ao;
        color = albedo * (ambient + diffuse * shadow) + specular * shadow;
        if (frame.clusterGrid.w > 0.5) {
            uvec2 cell = clusterLights();
            for (uint i = cell.x; i < cell.x + cell.y; i++) {
                vec3 pl;
                vec3 radiance = punctualRadiance(lightIndex(i), pl);
                float pndotl = dot(n, pl);
                vec3 ph = normalize(pl + v);
                color += albedo * max(pndotl, 0.0) * radiance
                    + pow(max(dot(n, ph), 0.0), material.params.w) * material.params.z * step(0.0, pndotl) * radiance;
            }
        }
    } else {
        vec4 mr = texture(sampler2D(metallicRoughnessMap, materialSampler), uv);
        float metallic = clamp(material.surface.x * mr.b, 0.0, 1.0);
        float roughness = clamp(material.surface.y * mr.g, 0.045, 1.0);
        float a = roughness * roughness;
        vec3 diffuseColor = albedo * (1.0 - metallic);
        vec3 f0 = mix(vec3(0.04), albedo, metallic);

        float NoV = max(dot(n, v), 1e-4);
        float NoL = clamp(dot(n, l), 0.0, 1.0);
        float NoH = clamp(dot(n, h), 0.0, 1.0);
        float VoH = clamp(dot(v, h), 0.0, 1.0);
        vec3 F = fresnelSchlick(f0, VoH);
        vec3 specular = distributionGGX(NoH, a) * visibilitySmithGGXCorrelated(NoV, NoL, a) * F * PI;
        vec3 direct = ((vec3(1.0) - F) * diffuseColor + specular) * NoL * light * shadow;

        vec2 dfg = environmentBRDF(NoV, roughness);
        vec3 specularAmbient = f0 * dfg.x + dfg.y;
        vec3 irradiance = hemisphere(n);
        vec3 reflected = mix(hemisphere(reflect(-v, n)), irradiance, roughness);
        vec3 ambient = ((vec3(1.0) - specularAmbient) * diffuseColor * irradiance + specularAmbient * reflected) * ao;
        color = direct + ambient;
        if (frame.clusterGrid.w > 0.5) {
            uvec2 cell = clusterLights();
            for (uint i = cell.x; i < cell.x + cell.y; i++) {
                vec3 pl;
                vec3 radiance = punctualRadiance(lightIndex(i), pl);
                vec3 ph = normalize(pl + v);
                float pNoL = clamp(dot(n, pl), 0.0, 1.0);
                float pNoH = clamp(dot(n, ph), 0.0, 1.0);
                vec3 pF = fresnelSchlick(f0, clamp(dot(v, ph), 0.0, 1.0));
                vec3 pSpecular = distributionGGX(pNoH, a) * visibilitySmithGGXCorrelated(NoV, pNoL, a) * pF * PI;
                color += ((vec3(1.0) - pF) * diffuseColor + pSpecular) * pNoL * radiance;
            }
        }
    }
    color = mix(color, albedo, material.params.y);
    color += material.emissive.rgb * texture(sampler2D(emissiveMap, materialSampler), uv).rgb;

    float dist = length(frame.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * frame.fogColor.w);
    outColor = vec4(mix(color, frame.fogColor.rgb, fog), opacity);
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
