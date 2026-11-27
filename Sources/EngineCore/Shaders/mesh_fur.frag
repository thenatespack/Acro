#version 450
// compile-shaders: gles -DFUR_NO_SAMPLE_MASK
// compile-shaders: wgsl -DFUR_NO_SAMPLE_MASK
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's fragment shader for fur (Groom.swift; vertex stage fur.glsl).
//
// Coverage: fur_strands.glsl (shared with the shadow casters, mesh_fur_depth.frag), filtered, as
// alpha: shells and fins are alpha blended (drawn inner to outer after the opaque surfaces,
// `RenderPrep.appendFur`), cards are opaque with hashed alpha per MSAA sample (gl_SampleMask;
// the GLSL ES and WGSL variants, built with FUR_NO_SAMPLE_MASK, alpha-test instead).
// Shading:
// - color: root-to-tip with per-strand noise;
// - hair model (Marschner as approximated by Karis, "Physically Based Hair Shading in Unreal",
//   2016) along the strand: R (a white highlight shifted toward the tip), TRT (a highlight
//   tinted by the fiber, shifted toward the root, broader) and TT (light through the fibers: a
//   bright rim when the light is behind the hair), plus a multiple-scattering diffuse that
//   saturates toward the fiber color where less light gets through. Shells take their diffuse
//   from the surface normal (the body's shape), cards from the strand and the view;
// - the sun's shadow at the strand (`furSunShadow`): deep-opacity-style, the shadow atlas is
//   compared at three depths toward the light, so fur (which casts into the atlas) lets light
//   in to a depth set by the groom's length and density, and other casters shadow fully;
// - ambient occlusion from root to tip by how many strands the light crosses (length, density,
//   thickness), lighter where clumps open gaps and for bright fibers (light bounces between them);
// - the hemisphere or image-based ambient light, clustered point and spot lights (same model,
//   their shadows), fog.

// Must match `SceneRenderer.FrameUniforms` (as mesh_surface.glsl).
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
    mat4 reflectionViewProj;
    vec4 reflectionPlane;
    vec4 reflectionParams;
    vec4 reflectionExtra;
} frame;

// The prefix of fur.glsl's block.
layout(set = 2, binding = 2, std140) uniform FurData {
    vec4 material[8];
    vec4 fur[8];
} furData;

layout(set = 2, binding = 3, std140) uniform LightPositions { vec4 data[1024]; } lightPositions;
layout(set = 2, binding = 4, std140) uniform LightColors { vec4 data[1024]; } lightColors;
layout(set = 2, binding = 5, std140) uniform LightDirections { vec4 data[1024]; } lightDirections;
layout(set = 2, binding = 6, std140) uniform LightCells { uvec4 data[1024]; } lightCells;
layout(set = 2, binding = 7, std140) uniform LightIndices { uvec4 data[1024]; } lightIndices;

layout(set = 1, binding = 0) uniform sampler2DShadow shadowMap;
layout(set = 2, binding = 10) uniform texture2D maskMap;  // the groom's mask texture (metallic-roughness slot): R scales the length
layout(set = 2, binding = 17) uniform sampler materialSampler;
layout(set = 2, binding = 14) uniform texture2D environmentAtlas;

layout(location = 0) in vec3 vWorldPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vColor;
layout(location = 4) in vec3 vObjectPos;
layout(location = 5) in vec4 vParams;
layout(location = 6) in vec4 vCurrentClip;
layout(location = 7) in vec4 vPreviousClip;
layout(location = 8) in vec4 vFur;
layout(location = 9) in vec3 vStrand;
layout(location = 10) in vec3 vObjectNormal;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMotion;

vec2 motionVector(vec4 current, vec4 previous) {
    if (previous.w <= 0.0) return vec2(0.0);
    return (previous.xy / previous.w - current.xy / current.w) * vec2(0.5, -0.5);
}

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
        sum += texelFetch(sampler2D(environmentAtlas, materialSampler), ENV_SH + ivec2(i, 0), 0).rgb * y[i];
    }
    return max(sum, vec3(0.0)) * frame.environment.y;
}

vec3 punctualRadiance(uint i, out vec3 l) {
    vec4 position = lightPositions.data[i];
    vec3 toLight = position.xyz - vWorldPos;
    float d2 = dot(toLight, toLight);
    float x = d2 * position.w;
    float window = clamp(1.0 - x * x, 0.0, 1.0);
    l = toLight * inversesqrt(max(d2, 1e-8));
    vec4 color = lightColors.data[i];
    vec4 direction = lightDirections.data[i];
    float cone = clamp(dot(-l, direction.xyz) * color.w + direction.w, 0.0, 1.0);
    return color.rgb * (window * window * cone * cone / max(d2, 1e-4));
}

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

#include "fur_strands.glsl"

// MARK: Hair shading

float hairGaussian(float b, float x) { return exp(-0.5 * x * x / (b * b)) / (2.5066283 * b); }

// Fresnel of a fiber (index 1.55) at cosine `c`.
float hairFresnel(float c) {
    const float f0 = 0.04652;
    float m = 1.0 - clamp(c, 0.0, 1.0);
    float m2 = m * m;
    return f0 + (1.0 - f0) * m2 * m2 * m;
}

// The light a fiber along unit tangent `t` (root to tip) sends toward `v` from unit direction
// `l`, per unit irradiance, in the engine's units (a Lambert surface would give albedo x N.L).
// `color` the fiber's (absorption), `shell` picks the surface normal `n` for the diffuse,
// `through` 0...1 how much of the light reaches this depth (tints the multiple scattering),
// `shift` the cuticle tilt in radians, `roughness` the lobes' width, `specular` their strength.
vec3 hairLight(vec3 t, vec3 n, vec3 l, vec3 v, vec3 color, bool shell, float through, float shift, float roughness,
               float specular) {
    float sinL = clamp(dot(t, l), -1.0, 1.0);
    float sinV = clamp(dot(t, v), -1.0, 1.0);
    float cosThetaD = max(cos(0.5 * abs(asin(sinV) - asin(sinL))), 0.05);
    vec3 lp = l - sinL * t, vp = v - sinV * t;
    float cosPhi = dot(lp, vp) * inversesqrt(max(dot(lp, lp) * dot(vp, vp), 1e-6));
    float cosHalfPhi = sqrt(clamp(0.5 + 0.5 * cosPhi, 0.0, 1.0));
    float r2 = roughness * roughness;
    float s = sinL + sinV;

    // R: reflection off the cuticle; white, shifted toward the tip.
    float mR = hairGaussian(r2 * 1.4142, s + 2.0 * shift);
    vec3 spec = vec3(mR * 0.25 * cosHalfPhi * hairFresnel(sqrt(clamp(0.5 + 0.5 * dot(l, v), 0.0, 1.0))) * 3.0);
    // TT: through the fiber, colored by absorption; strongest with the light behind.
    float mTT = hairGaussian(r2 * 0.5 + 0.08, s - shift);
    const float a = 1.0 / 1.55;
    float hTT = cosHalfPhi * (1.0 + a * (0.6 - 0.8 * cosPhi));
    float fTT = hairFresnel(cosThetaD * sqrt(clamp(1.0 - hTT * hTT, 0.0, 1.0)));
    // (Twice Karis' absorption: the light crosses more than one fiber on its way through.)
    vec3 tTT = pow(max(color, vec3(1e-4)), vec3(sqrt(clamp(1.0 - hTT * hTT * a * a, 0.0, 1.0)) / cosThetaD));
    spec += mTT * exp(-3.65 * cosPhi - 3.98) * (1.0 - fTT) * (1.0 - fTT) * tTT;
    // TRT: in, bounced off the back, out; the fiber's color, shifted toward the root, broader.
    float mTRT = hairGaussian(r2 * 2.0 * 1.4142, s - 4.0 * shift);
    float fTRT = hairFresnel(cosThetaD * 0.5);
    vec3 tTRT = pow(max(color, vec3(1e-4)), vec3(0.8 / cosThetaD));
    spec += mTRT * exp(17.0 * cosPhi - 16.78) * (1.0 - fTRT) * (1.0 - fTRT) * fTRT * tTRT * 4.0;

    // Multiple scattering: light diffused through many fibers, more saturated the deeper it went.
    float diffuse;
    if (shell) {
        float wrap = clamp(dot(n, l) * 0.6 + 0.4, 0.0, 1.0);
        diffuse = wrap * wrap;
    } else {
        vec3 facing = v - t * sinV;
        facing *= inversesqrt(max(dot(facing, facing), 1e-6));
        float wrapped = clamp((dot(facing, l) + 1.0) * 0.5, 0.0, 1.0);
        diffuse = mix(wrapped, 1.0 - abs(sinL), 0.33);
    }
    float luma = max(dot(color, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
    vec3 scatter = pow(max(color, vec3(1e-4)) / luma, vec3((1.0 - through) * 0.35));
    // Fibers pass light on to the fibers behind: dark hair is still visibly lit.
    vec3 fiber = pow(max(color, vec3(1e-4)), vec3(0.92));
    return fiber * scatter * diffuse + spec * (specular * 3.14159265);
}

// The sun's light reaching world position p (geometric normal ng) through fur: the cascade's
// shadow compared at three depths up to ~1.8 x `depth` meters toward the light, so casters that
// close (the fur's own strands) only dim it (exp(-distance / depth), roughly) and casters
// farther in front shadow it fully.
float furCascadeShadow(int c, vec3 p, float depth) {
    mat4 m = frame.cascadeMatrices[c];
    vec3 local = (m * vec4(p, 1.0)).xyz;
    if (local.x < 0.0 || local.x > 1.0 || local.y < 0.0 || local.y > 1.0) return 1.0;
    vec2 origin = vec2(float(c & 1), float(c >> 1)) * frame.shadowTiles.xy;
    float ref = min(local.z, 1.0) - frame.cascadeBiases[c];
    float perMeter = length(vec3(m[0][2], m[1][2], m[2][2]));
    float d = depth * perMeter;
    // One hardware-filtered compare per depth, the three spread over a triangle a texel and a
    // half wide (a small PCF kernel spread across the depths): fur fragments are many and
    // layered, and three full PCF kernels cost several ms in a close-up.
    vec2 texel = frame.shadowAtlas.xy;
    vec2 lo = origin + texel * 0.5, hi = origin + frame.shadowTiles.xy - texel * 0.5;
    vec2 uv = origin + local.xy * frame.shadowTiles.xy;
    float s = texture(shadowMap, vec3(clamp(uv + texel * vec2(0.0, 0.85), lo, hi), ref - d * 0.18));
    s += texture(shadowMap, vec3(clamp(uv + texel * vec2(-0.74, -0.43), lo, hi), ref - d * 0.69));
    s += texture(shadowMap, vec3(clamp(uv + texel * vec2(0.74, -0.43), lo, hi), ref - d * 1.79));
    return s * (1.0 / 3.0);
}

// directionalShadow (shadows.glsl) with furCascadeShadow.
float furSunShadow(vec3 p, vec3 ng, float depth, out vec3 tint) {
    tint = vec3(1.0);
    int count = int(frame.shadowInfo.x);
    float viewDepth = dot(frame.shadowDepthRow.xyz, p) + frame.shadowDepthRow.w;
    int c = 0;
    while (c < count - 1 && viewDepth > frame.cascadeSplits[c]) c++;
    if (viewDepth > frame.cascadeSplits[c]) return 1.0;
    float s = furCascadeShadow(c, p + ng * frame.cascadeNormalOffsets[c], depth);
    vec3 t = cascadeTints[c];
    float start = frame.cascadeBlendStarts[c];
    if (viewDepth > start) {
        float f = (viewDepth - start) / (frame.cascadeSplits[c] - start);
        if (c + 1 < count) {
            s = mix(s, furCascadeShadow(c + 1, p + ng * frame.cascadeNormalOffsets[c + 1], depth), f);
            t = mix(t, cascadeTints[c + 1], f);
        } else {
            s = mix(s, 1.0, f);
        }
    }
    if (frame.shadowAtlas.w > 0.5) tint = t;
    return s;
}

void main() {
    float h = vFur.x;
    bool cards = vFur.z > 0.5 && vFur.z < 1.5;
    bool fin = vFur.z > 1.5;
    bool undercoat = vFur.w > 0.5;
    vec4 f0 = furData.fur[0], f1 = furData.fur[1], f2 = furData.fur[2];
    vec3 v = normalize(frame.cameraPos.xyz - vWorldPos);
    vec3 faceNormal = cross(dFdx(vWorldPos), dFdy(vWorldPos));
    float along, strandRandom, exposed, blur;
    uint sampleMask = 0xFFFFFFFFu;
    float alpha = furCoverage(1.0, along, strandRandom, exposed, blur);
    // The shells drawn; in the fraction, how many of the groom's each stands for
    // (`RenderPrep.furShellCode`): fewer shells drawn by screen size, each that much more opaque.
    float shells = floor(vColor.w);
    float code = vColor.w - shells;
    if (!cards && !fin && !undercoat && code > 0.005) {
        float boost = 1.0 + (code - 0.01) / 0.98 * 8.0;
        alpha = 1.0 - pow(1.0 - min(alpha, 0.999), boost);
    }
    // (Not toward the silhouette, where each shell shows as its own outline.)
    if (!cards && !fin && !undercoat && blur > 0.5 && shells >= 8.0 && abs(dot(normalize(vNormal), v)) > 0.45) {
        // Where the shells have blended into their (alike) average, only every 2nd (4th, for
        // the plain average and 16+ shells) draws, with the coverage of the ones it stands for:
        // as many layers as the fur shows structure, at half (a quarter of) the shading.
        float skip = blur > 1.5 && shells >= 16.0 ? 4.0 : 2.0;
        float index = floor(h * shells + 0.5);
        if (mod(index, skip) > 0.5) discard;
        alpha = 1.0 - pow(1.0 - min(alpha, 0.999), skip);
    }
    if (cards) {
        // Edge-on cards fade instead of collapsing into aliased lines.
        float facing = abs(dot(normalize(vNormal), v));
        alpha *= mix(0.35, 1.0, smoothstep(0.03, 0.3, facing));
        // Hashed alpha per sample (Wyman & McGuire 2017, "Hashed Alpha Testing"): the coverage
        // picks how many of the pixel's samples the card covers (dithered rounding, so the levels
        // average out between pixels) and a hash of the pixel and the strand picks which, so
        // cards over cards cover different samples and add up (alpha-to-coverage covers the
        // same samples for every layer: overlapping thin strands would never fill a pixel). With
        // one sample (temporal upscalers) it is the stochastic alpha test, its threshold changing
        // every frame for the upscaler to average. WebGL 2 has no sample mask (and naga can't translate
        // it for WebGPU): an alpha test there.
        float samples = clamp(furData.fur[7].x, 1.0, 8.0);
        vec2 pixel = gl_FragCoord.xy + (samples < 1.5 ? vec2(5.588238, 3.1416) * furData.fur[7].y : vec2(0.0));
        // Each strand its own threshold: one threshold for every layer would make them cover
        // the same pixels (their union no more than the densest).
        vec2 layer = vec2(strandRandom * 61.0 + vFur.y * 113.0, h * 7.0);
        float k = floor(alpha * samples + fract(furPixelNoise(pixel) + strandRandom * 0.618034 + vFur.y * 0.414214));
        if (k < 0.5) discard;
#ifdef FUR_NO_SAMPLE_MASK
        alpha = 1.0;
#else
        uint count = uint(samples);
        uint bits = (1u << uint(min(k, samples))) - 1u;
        uint rotation = uint(furPixelNoise(pixel.yx * 1.37 + layer) * samples) % count;
        uint full = (1u << count) - 1u;
        sampleMask = ((bits << rotation) | (bits >> (count - rotation))) & full;
        alpha = 1.0;
#endif
    } else if (fin) {
        // Fins show at the silhouette only (the surface edge-on), and not when seen edge-on themselves.
        float silhouette = 1.0 - abs(dot(normalize(vNormal), v));
        float finFacing = abs(dot(faceNormal * inversesqrt(max(dot(faceNormal, faceNormal), 1e-20)), v));
        alpha *= smoothstep(0.72, 0.95, silhouette) * smoothstep(0.08, 0.35, finFacing);
    }
    if (alpha < 0.004) discard;

    vec3 rootColor = furData.fur[3].rgb, tipColor = furData.fur[4].rgb;
    float noise = 1.0 + (strandRandom - 0.5) * 2.0 * f2.z;
    vec3 albedo = mix(rootColor, tipColor, pow(along, 0.8)) * max(noise, 0.0) * vColor.rgb;

    // How many strands a ray from the tips down to the roots crosses (strands of radius r every
    // `spacing`: length x 2r / spacing²), for shells; hair cards lie in looser layers.
    float spacing = max(f0.y, 1e-5);
    float crossings = cards ? 3.0 : f0.x * (f0.z + f0.w) * 0.5 / spacing;
    crossings *= 1.0 - 0.6 * exposed;
    crossings = 5.0 * (1.0 - exp(-crossings / 5.0));  // past a few strands, more hardly matters
    float depthBelowTips = undercoat ? 1.0 : 1.0 - (cards ? along : h);
    float occlusion = exp(-0.5 * crossings * depthBelowTips);
    // Bright fibers pass light on to each other.
    float luma = dot(albedo, vec3(0.2126, 0.7152, 0.0722));
    occlusion = mix(occlusion, 1.0, 0.3 * sqrt(clamp(luma, 0.0, 1.0)));
    occlusion = max(occlusion, 0.12);
    if (cards) occlusion *= mix(0.85, 1.0, strandRandom);

    vec3 n = normalize(vNormal);
    if (cards && !gl_FrontFacing) n = -n;
    vec3 t = normalize(vStrand);
    vec3 l = normalize(frame.lightDir.xyz);
    bool receivesShadows = vParams.x > 0.5;
    // Light gets through about this many meters of fur: less for dense, thick fur.
    float through = clamp(f0.x * 2.0 / max(crossings, 1.0), 0.004, 0.06);
    float shadow = 1.0;
    if (frame.lightColor.w > 0.5 && receivesShadows) {
        vec3 tint;
        shadow = furSunShadow(vWorldPos, n, through, tint);
        albedo *= tint;
    }
    float shift = 0.06 + (strandRandom - 0.5) * 0.08;
    float roughness = cards ? 0.38 : 0.45;
    float specular = f2.w;
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    vec3 color = hairLight(t, n, l, v, albedo, !cards, shadow, shift, roughness, specular)
        * light * shadow * mix(0.5, 1.0, occlusion);
    vec3 irradiance = frame.environment.x > 0.5 ? environmentIrradiance(n) : hemisphere(n);
    color += albedo * irradiance * occlusion;
    if (frame.clusterGrid.w > 0.5) {
        uvec2 cell = clusterLights();
        for (uint i = cell.x; i < cell.x + cell.y; i++) {
            vec3 pl;
            uint li = lightIndex(i);
            vec3 radiance = punctualRadiance(li, pl);
            float local = receivesShadows ? localShadow(li, vWorldPos, n, pl) : 1.0;
            color += hairLight(t, n, pl, v, albedo, !cards, local, shift, roughness, specular) * radiance * local
                * mix(0.5, 1.0, occlusion);
        }
    }

    float dist = length(frame.cameraPos.xyz - vWorldPos);
    float fog = 1.0 - exp(-dist * frame.fogColor.w);
    if (frame.groundColor.w != 0.0) {
        float k = frame.groundColor.w;
        vec3 toEye = vWorldPos - frame.cameraPos.xyz;
        float x = k * toEye.y;
        float span = abs(x) < 1e-4 ? 1.0 - 0.5 * x : (1.0 - exp(min(-x, 60.0))) / x;
        float atEye = frame.fogColor.w * exp(min(-k * (frame.cameraPos.y - frame.cameraPos.w), 30.0));
        fog = 1.0 - exp(-dist * atEye * span);
    }
    vec3 rgb = mix(color, frame.fogColor.rgb, fog);
    if (frame.reflectionExtra.w > 0.5) rgb /= 1.0 + rgb;
    outColor = vec4(rgb, alpha);
#ifndef FUR_NO_SAMPLE_MASK
    gl_SampleMask[0] = int(sampleMask);
#endif
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
