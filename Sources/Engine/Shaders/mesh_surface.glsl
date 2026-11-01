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
//   split-sum DFG approximation, so metals aren't black away from the sun.
//
// Image-based lighting (frame.environment.x = 1, see EnvironmentLighting.swift): the ambient
// light comes from the environment instead of the hemisphere. Diffuse: SH9 irradiance (both
// models). PBR specular: the prefiltered radiance along the reflection vector, between the two
// atlas levels around the roughness, times the split-sum BRDF table (f0 x A + B). The
// occlusion texture darkens both.
//
// Point and spot lights (clustered forward, see `LightClusters`): the fragment finds its
// cluster from gl_FragCoord (screen tile) and its view depth (logarithmic slice), then loops
// over that cluster's lights. Each adds the same direct BRDF as the sun (per shading model),
// with radiance color x intensity / d² windowed smoothly to zero at the light's range
// (Karis 2013: saturate(1 - (d/range)^4)²) and, for spots, saturate(cos x scale + offset)²
// between the outer and inner cone, times its shadow if it has one (shadows.glsl). Without
// lights the loop is skipped entirely.
//
// Shadows (shadows.glsl): the directional light's cascades and a few point / spot lights'
// maps, all in one shadow atlas.

// Must match `SceneRenderer.FrameUniforms`.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
    vec4 lightDir;
    vec4 lightColor;
    vec4 cameraPos;      // xyz: eye, w: height fog base height
    vec4 fogColor;       // rgb: fog color, w: density (at the base height with height fog)
    vec4 skyColor;
    vec4 groundColor;    // rgb: hemisphere ground color, w: height fog falloff (0 = off)
    vec4 shadowParams;
    vec4 viewDepth;      // view depth of a world position: dot(viewDepth.xyz, p) + viewDepth.w
    vec4 clusterScale;   // xy: tiles per pixel, z: slice scale, w: slice bias (slice = log2(depth) * z + w)
    vec4 clusterGrid;    // xyz: tiles x, tiles y, slices; w: 1 when there are point/spot lights
    // Shadows, must match `ShadowUniforms` (see shadows.glsl).
    mat4 cascadeMatrices[4];      // world -> cascade tile coordinates (xy 0-1, z depth)
    mat4 spotShadowMatrices[8];   // world -> spot tile coordinates before the divide
    vec4 cascadeSplits;           // far view depth of each cascade
    vec4 cascadeBlendStarts;      // view depth where each cascade starts blending into the next
    vec4 cascadeNormalOffsets;    // world units
    vec4 cascadeBiases;           // depth units
    vec4 shadowDepthRow;          // view depth of p: dot(xyz, p) + w
    vec4 shadowInfo;              // x: cascades, z: shadowed spots, w: shadowed points
    vec4 shadowAtlas;             // xy: 1 / atlas size, z: PCF radius, w: tint cascades
    vec4 shadowTiles;             // xy: cascade tile size, zw: spot tile size (atlas coordinates)
    vec4 shadowFaces;             // xy: point face size (atlas coordinates), z: face tangent scale
    vec4 shadowLocal;             // x: normal offset, y: depth bias (texels at the receiver)
    vec4 spotShadowParams[8];     // xy: tile origin, z: texel size per unit distance
    vec4 pointShadowPositions[4]; // xyz: position, w: texel size per unit distance
    vec4 pointShadowParams[4];    // xy: face block origin, depth = z + w / axis distance
    vec4 environment;             // x: 1 image-based lighting, y: intensity, z, w: cos, sin of the rotation
} frame;

// Must match `SceneRenderer.MaterialUniforms` (uniform buffer 2).
layout(set = 2, binding = 2, std140) uniform MaterialData {
    vec4 baseColor;  // linear rgb, a: opacity
    vec4 params;     // x: world-space checkerboard, y: unlit (0 lit .. 1 unlit), z: specular, w: shininess (Blinn-Phong)
    vec4 uvRow0;     // UV transform, rows of a 2x3 matrix: uv' = (dot(row0.xy, uv) + row0.z, dot(row1.xy, uv) + row1.z)
    vec4 uvRow1;
    vec4 surface;    // x: metallic, y: perceptual roughness, z: normal scale, w: occlusion strength
    vec4 emissive;   // rgb: emissive color x strength (linear), w: 1 PBR, 0 Blinn-Phong
    vec4 flags;      // x: alpha cutoff (mask), y: 1 when there is a normal map, z: its layout (below)
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

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;  // the shadow atlas
// Textures 1-5 share sampler 1. Missing ones are a 1x1 white texture.
layout(set = 2, binding = 9) uniform texture2D baseColorMap;          // sRGB color, alpha
layout(set = 2, binding = 10) uniform texture2D metallicRoughnessMap; // linear: G roughness, B metallic
layout(set = 2, binding = 11) uniform texture2D normalMap;            // linear tangent-space normal (see main)
layout(set = 2, binding = 12) uniform texture2D occlusionMap;         // linear: R occlusion
layout(set = 2, binding = 13) uniform texture2D emissiveMap;          // sRGB color
layout(set = 2, binding = 17) uniform sampler materialSampler;
// Image-based lighting: the environment atlas (read with texel loads) and the BRDF table.
layout(set = 2, binding = 14) uniform texture2D environmentAtlas;
layout(set = 2, binding = 15) uniform texture2D brdfTable;
layout(set = 2, binding = 23) uniform sampler brdfSampler;  // linear, clamped

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vColor;
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

#include "shadows.glsl"
#include "environment.glsl"

// The hemisphere ambient light arriving from direction d (sky above, ground below).
vec3 hemisphere(vec3 d) {
    return mix(frame.groundColor.rgb, frame.skyColor.rgb, d.y * 0.5 + 0.5) * frame.skyColor.w;
}

// The environment's diffuse irradiance / pi arriving at normal n (SH9).
vec3 environmentIrradiance(vec3 n) {
    float y[9];
    shBasis(environmentDirection(n, frame.environment.zw), y);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        sum += texelFetch(sampler2D(environmentAtlas, materialSampler), ENV_SH + ivec2(i, 0), 0).rgb * y[i];
    }
    return max(sum, vec3(0.0)) * frame.environment.y;
}

// The environment's radiance from direction d prefiltered for `roughness`: between the two
// levels around it (level i holds roughness i / 5).
vec3 environmentRadiance(vec3 d, float roughness) {
    vec2 uv = equirectUV(environmentDirection(d, frame.environment.zw));
    float level = roughness * 5.0;
    int i = min(int(level), 4);
    vec3 a = sampleEquirect(environmentAtlas, materialSampler, ENV_LEVELS[i], uv);
    vec3 b = sampleEquirect(environmentAtlas, materialSampler, ENV_LEVELS[i + 1], uv);
    return mix(a, b, level - float(i)) * frame.environment.y;
}

// The split-sum environment BRDF (`EnvironmentMath.environmentBRDF`): scale and bias of F0.
vec2 environmentBRDFTable(float NoV, float roughness) {
    vec2 uv = (vec2(NoV, roughness) * (ENV_LUT_SIZE - 1.0) + 0.5) / ENV_LUT_SIZE;
    return texture(sampler2D(brdfTable, brdfSampler), uv).rg;
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
            // flags.z: 0 XYZ in RGB; two-channel maps (Z = sqrt(1 - x² - y²)): 1 XY in RG
            // (BC5), 2 XY in RA (two-channel ASTC, which samples as x, x, x, y).
            vec4 s = texture(sampler2D(normalMap, materialSampler), uv);
            vec3 m;
            if (material.flags.z > 0.5) {
                vec2 xy = (material.flags.z > 1.5 ? s.ra : s.rg) * 2.0 - 1.0;
                m = vec3(xy, sqrt(clamp(1.0 - dot(xy, xy), 0.0, 1.0)));
            } else {
                m = s.xyz * 2.0 - 1.0;
            }
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
    // The geometric normal on the side being seen, for the shadow lookups' normal offset.
    vec3 ng = normalize(vNormal) * (gl_FrontFacing ? 1.0 : -1.0);
    bool receivesShadows = vParams.x > 0.5;
    float shadow = 1.0;
    if (frame.lightColor.w > 0.5 && receivesShadows) {
        vec3 cascadeTint;
        shadow = directionalShadow(vWorldPos, ng, cascadeTint);
        albedo *= cascadeTint;
    }
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    float ao = 1.0 + material.surface.w * (texture(sampler2D(occlusionMap, materialSampler), uv).r - 1.0);

    vec3 color;
    if (!pbr) {
        float ndotl = dot(n, l);
        vec3 diffuse = max(ndotl, 0.0) * light;
        vec3 specular = pow(max(dot(n, h), 0.0), material.params.w) * material.params.z * step(0.0, ndotl) * light;
        vec3 ambient = (frame.environment.x > 0.5 ? environmentIrradiance(n) : hemisphere(n)) * ao;
        color = albedo * (ambient + diffuse * shadow) + specular * shadow;
        if (frame.clusterGrid.w > 0.5) {
            uvec2 cell = clusterLights();
            for (uint i = cell.x; i < cell.x + cell.y; i++) {
                vec3 pl;
                uint li = lightIndex(i);
                vec3 radiance = punctualRadiance(li, pl);
                if (receivesShadows) radiance *= localShadow(li, vWorldPos, ng, pl);
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

        vec2 dfg;
        vec3 irradiance, reflected;
        if (frame.environment.x > 0.5) {
            dfg = environmentBRDFTable(NoV, roughness);
            irradiance = environmentIrradiance(n);
            reflected = environmentRadiance(reflect(-v, n), roughness);
        } else {
            dfg = environmentBRDF(NoV, roughness);
            irradiance = hemisphere(n);
            reflected = mix(hemisphere(reflect(-v, n)), irradiance, roughness);
        }
        vec3 specularAmbient = f0 * dfg.x + dfg.y;
        vec3 ambient = ((vec3(1.0) - specularAmbient) * diffuseColor * irradiance + specularAmbient * reflected) * ao;
        color = direct + ambient;
        if (frame.clusterGrid.w > 0.5) {
            uvec2 cell = clusterLights();
            for (uint i = cell.x; i < cell.x + cell.y; i++) {
                vec3 pl;
                uint li = lightIndex(i);
                vec3 radiance = punctualRadiance(li, pl);
                if (receivesShadows) radiance *= localShadow(li, vWorldPos, ng, pl);
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
    // vParams.yzw: the MeshRenderer's emissive tint x strength, minus one (so zero, a default
    // instance, multiplies by exactly one). `vColor` (the tint) does not touch emission.
    color += material.emissive.rgb * texture(sampler2D(emissiveMap, materialSampler), uv).rgb * (vec3(1.0) + vParams.yzw);

    float dist = length(frame.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * frame.fogColor.w);
    // Height fog (groundColor.w: falloff per world unit of height, 0 = uniform; cameraPos.w: the
    // height where the density is fogColor.w): the optical depth of the exponential density
    // d(y) = d0 exp(-k (y - base)) along the ray from the eye to this fragment, in closed form.
    if (frame.groundColor.w != 0.0) {
        float k = frame.groundColor.w;
        vec3 toEye = vWorldPos - frame.cameraPos.xyz;
        float x = k * toEye.y;  // k x height difference
        float span = abs(x) < 1e-4 ? 1.0 - 0.5 * x : (1.0 - exp(min(-x, 60.0))) / x;
        float atEye = frame.fogColor.w * exp(min(-k * (frame.cameraPos.y - frame.cameraPos.w), 30.0));
        fog = 1.0 - exp(-dist * atEye * span);
    }
    outColor = vec4(mix(color, frame.fogColor.rgb, fog), opacity);
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
