#version 450
#extension GL_GOOGLE_include_directive : require

// Volumetric fog (SceneEnvironment.volumetricFog, SceneRenderer+Volumetric.swift): marches the
// view ray of every pixel from the eye to the opaque surface behind it (or maxDistance for the
// sky) through the scene's fog and adds the light the fog scatters toward the camera to the HDR
// scene image. The medium is the fog the meshes already use (density fogColor.w, with the height
// falloff of groundColor.w / cameraPos.w), whose extinction the meshes' fog blend already applies
// to surfaces, so this pass only adds light:
//   in-scatter = sum over samples of T(t) density ds (sun x phase x shadow + point / spot lights)
// where T is the transmittance from the eye. The sun is shadowed with its cascades (the same
// bilinear depth comparison as the lit particles, reading the atlas as a plain depth texture), so
// occluders cut shafts through the fog; point and spot lights come from the clustered light grid
// (unshadowed). Sample positions are jittered by interleaved gradient noise (a fixed per-pixel
// pattern, so screenshots are deterministic). Reads texels with exact loads like the other post
// passes. Not part of the scene pass: it needs the scene's depth (a prepass the renderer makes).

#include "post_common.glsl"

// Must match `SceneRenderer.FrameUniforms` (as in mesh_surface.glsl).
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
    vec4 lightDir;
    vec4 lightColor;
    vec4 cameraPos;      // xyz: eye, w: height fog base height
    vec4 fogColor;       // w: density
    vec4 skyColor;
    vec4 groundColor;    // w: height fog falloff
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

layout(set = 2, binding = 3, std140) uniform LightPositions { vec4 data[1024]; } lightPositions;
layout(set = 2, binding = 4, std140) uniform LightColors { vec4 data[1024]; } lightColors;
layout(set = 2, binding = 5, std140) uniform LightDirections { vec4 data[1024]; } lightDirections;
layout(set = 2, binding = 6, std140) uniform LightCells { uvec4 data[1024]; } lightCells;
layout(set = 2, binding = 7, std140) uniform LightIndices { uvec4 data[1024]; } lightIndices;
layout(set = 2, binding = 9) uniform texture2D sceneImage;
layout(set = 2, binding = 10) uniform texture2D sceneDepth;
layout(set = 2, binding = 11) uniform texture2D shadowAtlas;

layout(push_constant) uniform PushConstants {
    mat4 inverseViewProj;  // of frame.viewProj
    vec4 params;           // x: intensity, y: anisotropy g, z: max distance, w: steps
    vec4 flags;            // x: 1 with reversed-Z, y: 1 to scatter point / spot lights
} pc;

layout(location = 0) out vec4 outColor;

// Cascade c's shadow at p (as particle_lighting.glsl): 2x2 depth comparisons, bilinearly
// weighted, kept inside the cascade's tile.
float cascadeShadow(int c, vec3 p) {
    vec3 local = (frame.cascadeMatrices[c] * vec4(p, 1.0)).xyz;
    if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) return 1.0;
    vec2 size = 1.0 / frame.shadowAtlas.xy;
    vec2 origin = vec2(float(c & 1), float(c >> 1)) * frame.shadowTiles.xy;
    ivec2 low = ivec2(origin * size + 0.5), high = ivec2((origin + frame.shadowTiles.xy) * size + 0.5) - 1;
    float ref = min(local.z, 1.0) - frame.cascadeBiases[c];
    vec2 t = (origin + local.xy * frame.shadowTiles.xy) * size - 0.5;
    vec2 base = floor(t), f = t - base;
    float lit[4];
    for (int i = 0; i < 4; i++) {
        ivec2 texel = clamp(ivec2(base) + ivec2(i & 1, i >> 1), low, high);
        lit[i] = ref <= texelFetch(sampler2D(shadowAtlas, pointSampler), texel, 0).r ? 1.0 : 0.0;
    }
    return mix(mix(lit[0], lit[1], f.x), mix(lit[2], lit[3], f.x), f.y);
}

// The sun's shadow at p: its cascade, blended into the next near the end, the last fading to lit.
float sunShadow(vec3 p) {
    int count = int(frame.shadowInfo.x);
    float depth = dot(frame.shadowDepthRow.xyz, p) + frame.shadowDepthRow.w;
    int c = 0;
    while (c < count - 1 && depth > frame.cascadeSplits[c]) c++;
    if (depth > frame.cascadeSplits[c]) return 1.0;
    float s = cascadeShadow(c, p);
    float start = frame.cascadeBlendStarts[c];
    if (depth > start) {
        float f = (depth - start) / (frame.cascadeSplits[c] - start);
        s = mix(s, c + 1 < count ? cascadeShadow(c + 1, p) : 1.0, f);
    }
    return s;
}

// Fog density at height y.
float fogDensityAt(float y) {
    float k = frame.groundColor.w;
    return k == 0.0 ? frame.fogColor.w : frame.fogColor.w * exp(min(-k * (y - frame.cameraPos.w), 30.0));
}

// Henyey-Greenstein, scaled by 4 pi so that g = 0 is 1. c: cosine between the view ray and the
// direction toward the light (looking at the light is forward scattering).
float phase(float c, float g) {
    return (1.0 - g * g) / pow(max(1.0 + g * g - 2.0 * g * c, 1e-4), 1.5);
}

// The point and spot lights' radiance scattered toward the viewer at p (isotropic).
vec3 localScatter(vec3 p) {
    vec4 clip = frame.viewProj * vec4(p, 1.0);
    if (clip.w <= 0.0) return vec3(0.0);
    float depth = dot(frame.viewDepth.xyz, p) + frame.viewDepth.w;
    vec2 screen = vec2(clip.x / clip.w * 0.5 + 0.5, 0.5 - clip.y / clip.w * 0.5);
    if (screen.x < 0.0 || screen.x >= 1.0 || screen.y < 0.0 || screen.y >= 1.0) return vec3(0.0);
    vec2 tile = clamp(floor(screen * frame.clusterGrid.xy), vec2(0.0), frame.clusterGrid.xy - 1.0);
    float slice = clamp(floor(log2(max(depth, 1e-6)) * frame.clusterScale.z + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
    uint cluster = uint((slice * frame.clusterGrid.y + tile.y) * frame.clusterGrid.x + tile.x);
    uint cell = lightCells.data[cluster >> 2][cluster & 3u];
    uint first = cell & 0xFFFFu, count = cell >> 16;
    vec3 light = vec3(0.0);
    for (uint i = first; i < first + count; i++) {
        uint word = i / 3u;
        uint index = (lightIndices.data[word >> 2][word & 3u] >> ((i - word * 3u) * 10u)) & 0x3FFu;
        vec4 position = lightPositions.data[index];
        vec3 toLight = position.xyz - p;
        float d2 = dot(toLight, toLight);
        float x = d2 * position.w;
        float window = clamp(1.0 - x * x, 0.0, 1.0);
        vec3 pl = toLight * inversesqrt(max(d2, 1e-8));
        vec4 color = lightColors.data[index];
        vec4 direction = lightDirections.data[index];
        float cone = clamp(dot(-pl, direction.xyz) * color.w + direction.w, 0.0, 1.0);
        light += color.rgb * (window * window * cone * cone / max(d2, 0.25));
    }
    return light;
}

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    vec3 scene = texelFetch(sampler2D(sceneImage, pointSampler), px, 0).rgb;
    float depth = texelFetch(sampler2D(sceneDepth, pointSampler), px, 0).r;
    vec2 size = vec2(textureSize(sampler2D(sceneImage, pointSampler), 0));
    vec2 ndc = (vec2(px) + 0.5) / size * 2.0 - 1.0;
    ndc.y = -ndc.y;  // texel rows run down; clip space is y-up

    vec3 eye = frame.cameraPos.xyz;
    vec4 onRay = pc.inverseViewProj * vec4(ndc, 0.5, 1.0);
    vec3 dir = normalize(onRay.xyz / onRay.w - eye);
    float maxDistance = pc.params.z;
    bool sky = pc.flags.x > 0.5 ? depth <= 0.0 : depth >= 1.0;
    float dist = maxDistance;
    if (!sky) {
        vec4 hit = pc.inverseViewProj * vec4(ndc, depth, 1.0);
        dist = min(length(hit.xyz / hit.w - eye), maxDistance);
    }

    int steps = int(pc.params.w);
    float ds = dist / float(steps);
    float jitter = fract(52.9829189 * fract(dot(vec2(px), vec2(0.06711056, 0.00583715))));
    vec3 sun = frame.lightColor.rgb * frame.lightDir.w * phase(dot(dir, normalize(frame.lightDir.xyz)), pc.params.y);
    bool sunShadows = frame.lightColor.w > 0.5;
    bool lights = pc.flags.y > 0.5 && frame.clusterGrid.w > 0.5;

    vec3 scattered = vec3(0.0);
    float opticalDepth = 0.0;
    for (int i = 0; i < steps; i++) {
        vec3 p = eye + dir * ((float(i) + jitter) * ds);
        float density = fogDensityAt(p.y) * ds;
        float transmittance = exp(-(opticalDepth + 0.5 * density));
        opticalDepth += density;
        vec3 light = sun * (sunShadows ? sunShadow(p) : 1.0);
        if (lights) light += localScatter(p);
        scattered += light * (density * transmittance);
    }
    outColor = vec4(scene + scattered * pc.params.x, 1.0);
}
