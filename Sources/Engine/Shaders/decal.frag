#version 450
#extension GL_GOOGLE_include_directive : require

// Decals (`Decal`, see SceneRenderer+Decals.swift): the fragment of a projector box's back face
// finds the opaque surface at its pixel and paints the texture onto it.
//
// - Position: the depth prepass's depth at this pixel through the inverse view-projection; the
//   normal from the neighboring texels (the smaller difference on each axis, so depth edges
//   don't bend it, as particle_simulate.comp), facing the camera. Outside the unit box in
//   decal space the fragment is discarded.
// - Texture: decal space xy (u right, v down, projected along local -Z), sampled with gradients
//   from the same neighbors, so mips are right at depth edges.
// - Alpha: texture alpha x opacity x angle fade (cos between the normal and the way back to
//   the projector, over `angleFade`).
// - Shading: PBR as mesh_surface.glsl with the decal's color as a dielectric albedo (F0 0.04)
//   and its roughness: sun with its cascaded shadow, ambient or environment diffuse and
//   specular, clustered point / spot lights with their shadows; then `emissive` x color added
//   unlit and the mesh shader's fog. The output is straight alpha, blended over the scene.
//
// Frame, the light buffers and the lookups below mirror mesh_surface.glsl (keep them in sync);
// rerun Scripts/compile-shaders.sh after editing.

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
    vec4 viewDepth;
    vec4 clusterScale;
    vec4 clusterGrid;
    mat4 cascadeMatrices[4];
    mat4 spotShadowMatrices[8];
    vec4 cascadeSplits;
    vec4 cascadeBlendStarts;
    vec4 cascadeNormalOffsets;
    vec4 cascadeBiases;
    vec4 shadowDepthRow;
    vec4 shadowInfo;
    vec4 shadowAtlas;
    vec4 shadowTiles;
    vec4 shadowFaces;
    vec4 shadowLocal;
    vec4 spotShadowParams[8];
    vec4 pointShadowPositions[4];
    vec4 pointShadowParams[4];
    vec4 environment;
} frame;

layout(set = 2, binding = 2, std140) uniform DecalData {
    mat4 model;
    mat4 inverseModel;
    mat4 inverseViewProj;
    vec4 color;   // rgb: tint, a: opacity
    vec4 params;  // x: emissive, y: roughness, z: angle fade, w: 1 with a texture
    vec4 axis;    // xyz: unit world direction the decal projects along
} decal;

layout(set = 2, binding = 3, std140) uniform LightPositions { vec4 data[1024]; } lightPositions;
layout(set = 2, binding = 4, std140) uniform LightColors { vec4 data[1024]; } lightColors;
layout(set = 2, binding = 5, std140) uniform LightDirections { vec4 data[1024]; } lightDirections;
layout(set = 2, binding = 6, std140) uniform LightCells { uvec4 data[1024]; } lightCells;
layout(set = 2, binding = 7, std140) uniform LightIndices { uvec4 data[1024]; } lightIndices;

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;  // the shadow atlas
layout(set = 2, binding = 9) uniform texture2D decalTexture;     // sRGB color, alpha
layout(set = 2, binding = 10) uniform texture2D sceneDepth;      // the depth prepass
layout(set = 2, binding = 17) uniform sampler decalSampler;
layout(set = 2, binding = 14) uniform texture2D environmentAtlas;
layout(set = 2, binding = 15) uniform texture2D brdfTable;
layout(set = 2, binding = 23) uniform sampler brdfSampler;

layout(location = 0) out vec4 outColor;

const float PI = 3.14159265;

#include "shadows.glsl"
#include "environment.glsl"

vec3 hemisphere(vec3 d) {
    return mix(frame.groundColor.rgb, frame.skyColor.rgb, d.y * 0.5 + 0.5) * frame.skyColor.w;
}

vec3 environmentIrradiance(vec3 n) {
    float y[9];
    shBasis(environmentDirection(n, frame.environment.zw), y);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        sum += texelFetch(sampler2D(environmentAtlas, decalSampler), ENV_SH + ivec2(i, 0), 0).rgb * y[i];
    }
    return max(sum, vec3(0.0)) * frame.environment.y;
}

vec3 environmentRadiance(vec3 d, float roughness) {
    vec2 uv = equirectUV(environmentDirection(d, frame.environment.zw));
    float level = roughness * 5.0;
    int i = min(int(level), 4);
    vec3 a = sampleEquirect(environmentAtlas, decalSampler, ENV_LEVELS[i], uv);
    vec3 b = sampleEquirect(environmentAtlas, decalSampler, ENV_LEVELS[i + 1], uv);
    return mix(a, b, level - float(i)) * frame.environment.y;
}

vec2 environmentBRDFTable(float NoV, float roughness) {
    vec2 uv = (vec2(NoV, roughness) * (ENV_LUT_SIZE - 1.0) + 0.5) / ENV_LUT_SIZE;
    return texture(sampler2D(brdfTable, brdfSampler), uv).rg;
}

float distributionGGX(float NoH, float a) {
    float a2 = a * a;
    float d = NoH * NoH * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

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

vec2 environmentBRDF(float NoV, float roughness) {
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    return vec2(-1.04, 1.04) * a004 + r.zw;
}

// The world position the depth prepass holds at texel t (clamped to the texture).
vec3 depthPoint(ivec2 t, ivec2 size) {
    t = clamp(t, ivec2(0), size - 1);
    float z = texelFetch(sampler2D(sceneDepth, decalSampler), t, 0).r;
    vec2 ndc = vec2((float(t.x) + 0.5) / float(size.x) * 2.0 - 1.0, 1.0 - (float(t.y) + 0.5) / float(size.y) * 2.0);
    vec4 world = decal.inverseViewProj * vec4(ndc, z, 1.0);
    return world.xyz / world.w;
}

vec3 decalSpace(vec3 p) {
    return (decal.inverseModel * vec4(p, 1.0)).xyz;
}

void main() {
    ivec2 size = textureSize(sampler2D(sceneDepth, decalSampler), 0);
    ivec2 texel = ivec2(gl_FragCoord.xy);
    vec3 p = depthPoint(texel, size);
    vec3 q = decalSpace(p);
    if (any(greaterThan(abs(q), vec3(0.5)))) discard;

    // Neighbors on the nearer side of each axis give the surface's tangents and the texture gradients.
    vec3 px = depthPoint(texel + ivec2(1, 0), size), mx = depthPoint(texel - ivec2(1, 0), size);
    vec3 py = depthPoint(texel + ivec2(0, 1), size), my = depthPoint(texel - ivec2(0, 1), size);
    vec3 ax = px - p, bx = p - mx, ay = py - p, by = p - my;
    vec3 tx = dot(ax, ax) < dot(bx, bx) ? ax : bx;
    vec3 ty = dot(ay, ay) < dot(by, by) ? ay : by;
    vec3 v = frame.cameraPos.xyz - p;
    vec3 n = cross(tx, ty);
    n = dot(n, n) > 1e-20 ? normalize(n) : normalize(v);
    if (dot(n, v) < 0.0) n = -n;
    v = normalize(v);

    // u runs along +x, v down along -y.
    vec2 uv = vec2(q.x + 0.5, 0.5 - q.y);
    vec2 duvdx = (decalSpace(p + tx).xy - q.xy) * vec2(1.0, -1.0);
    vec2 duvdy = (decalSpace(p + ty).xy - q.xy) * vec2(1.0, -1.0);
    vec4 texel4 = decal.params.w > 0.5 ? textureGrad(sampler2D(decalTexture, decalSampler), uv, duvdx, duvdy) : vec4(1.0);
    vec3 albedo = decal.color.rgb * texel4.rgb;
    float alpha = decal.color.a * texel4.a;
    if (decal.params.z > 0.0) alpha *= clamp(dot(n, -decal.axis.xyz) / decal.params.z, 0.0, 1.0);
    if (alpha <= 0.0) discard;

    // PBR, metallic 0.
    float roughness = decal.params.y;
    float a = roughness * roughness;
    vec3 f0 = vec3(0.04);
    vec3 l = normalize(frame.lightDir.xyz);
    vec3 h = normalize(l + v);
    float shadow = 1.0;
    if (frame.lightColor.w > 0.5) {
        vec3 cascadeTint;
        shadow = directionalShadow(p, n, cascadeTint);
    }
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    float NoV = max(dot(n, v), 1e-4);
    float NoL = clamp(dot(n, l), 0.0, 1.0);
    float NoH = clamp(dot(n, h), 0.0, 1.0);
    float VoH = clamp(dot(v, h), 0.0, 1.0);
    vec3 F = fresnelSchlick(f0, VoH);
    vec3 specular = distributionGGX(NoH, a) * visibilitySmithGGXCorrelated(NoV, NoL, a) * F * PI;
    vec3 color = ((vec3(1.0) - F) * albedo + specular) * NoL * light * shadow;

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
    color += (vec3(1.0) - specularAmbient) * albedo * irradiance + specularAmbient * reflected;

    if (frame.clusterGrid.w > 0.5) {
        float depth = dot(frame.viewDepth.xyz, p) + frame.viewDepth.w;
        vec2 tile = clamp(floor(gl_FragCoord.xy * frame.clusterScale.xy), vec2(0.0), frame.clusterGrid.xy - 1.0);
        float slice = clamp(floor(log2(max(depth, 1e-6)) * frame.clusterScale.z + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
        uint cluster = uint((slice * frame.clusterGrid.y + tile.y) * frame.clusterGrid.x + tile.x);
        uint cell = lightCells.data[cluster >> 2][cluster & 3u];
        uint first = cell & 0xFFFFu, count = cell >> 16;
        for (uint i = first; i < first + count; i++) {
            uint word = i / 3u;
            uint li = (lightIndices.data[word >> 2][word & 3u] >> ((i - word * 3u) * 10u)) & 0x3FFu;
            vec4 position = lightPositions.data[li];
            vec3 toLight = position.xyz - p;
            float d2 = dot(toLight, toLight);
            float x = d2 * position.w;
            float window = clamp(1.0 - x * x, 0.0, 1.0);
            vec3 pl = toLight * inversesqrt(max(d2, 1e-8));
            vec4 lc = lightColors.data[li];
            vec4 direction = lightDirections.data[li];
            float cone = clamp(dot(-pl, direction.xyz) * lc.w + direction.w, 0.0, 1.0);
            vec3 radiance = lc.rgb * (window * window * cone * cone / max(d2, 1e-4));
            radiance *= localShadow(li, p, n, pl);
            vec3 ph = normalize(pl + v);
            float pNoL = clamp(dot(n, pl), 0.0, 1.0);
            float pNoH = clamp(dot(n, ph), 0.0, 1.0);
            vec3 pF = fresnelSchlick(f0, clamp(dot(v, ph), 0.0, 1.0));
            vec3 pSpecular = distributionGGX(pNoH, a) * visibilitySmithGGXCorrelated(NoV, pNoL, a) * pF * PI;
            color += ((vec3(1.0) - pF) * albedo + pSpecular) * pNoL * radiance;
        }
    }
    color += albedo * decal.params.x;

    float dist = length(frame.cameraPos.xyz - p);
    float fog = 1.0 - exp(-dist * frame.fogColor.w);
    outColor = vec4(mix(color, frame.fogColor.rgb, fog), alpha);
}
