#version 450
#extension GL_GOOGLE_include_directive : require

// SceneRenderer's fragment shader for fur (Groom.swift; vertex stage fur.glsl).
//
// Coverage:
// - shells: the strand a fragment belongs to comes from its root in the mesh's own space
//   (vObjectPos, bind pose, so strands stay on an animated mesh and don't depend on UVs): the
//   space is cut into cubes one strand spacing wide, each holding one strand at a random point
//   (its center projected onto the surface). Toward the tip the root is pulled toward a clump
//   center (clumping), circles it (curl) and wobbles (frizz). Fragments outside the strand's
//   radius (root to tip thickness), above its random length or above the mask texture's length
//   are discarded;
// - cards: strandsPerCard strands across each card (UV x), tapering to a soft edge; the
//   coverage goes out as alpha for alpha-to-coverage;
// - the undercoat (height 0) is solid wherever fur grows.
// Shading: root-to-tip color with per-strand noise, darker toward the roots, wrapped diffuse
// and two Kajiya-Kay highlights along the strand (a white one shifted toward the tip and a
// colored one toward the root, "Marschner-lite"), the sun's shadows, the hemisphere or
// image-based ambient light, point and spot lights (diffuse), fog.

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

// Three random numbers in 0...1 for integer cell `c`.
vec3 hash3(vec3 c) {
    uvec3 q = uvec3(ivec3(c) + ivec3(1 << 20));
    uint h = q.x * 1597334677u ^ q.y * 3812015801u ^ q.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
    uint h2 = h * 3266489917u; h2 ^= h2 >> 16;
    uint h3 = h2 * 668265263u; h3 ^= h3 >> 15;
    return vec3(float(h & 0xFFFFu), float(h2 & 0xFFFFu), float(h3 & 0xFFFFu)) / 65535.0;
}

// A strand highlight along tangent `t` (Kajiya-Kay): sin(t, h)^exponent.
float strandHighlight(vec3 t, vec3 h, float exponent) {
    float th = dot(t, h);
    return pow(sqrt(max(1.0 - th * th, 0.0)), exponent);
}

void main() {
    float h = vFur.x;
    bool cards = vFur.z > 0.5;
    bool undercoat = vFur.w > 0.5;
    vec4 f0 = furData.fur[0], f1 = furData.fur[1], f2 = furData.fur[2];
    float along = 0.0;        // 0 root ... 1 tip
    float strandRandom = 0.5;
    float alpha = 1.0;
    float maskLength = 1.0;
    if (furData.fur[6].z > 0.5) {
        maskLength = texture(sampler2D(maskMap, materialSampler), vUV).r;
        if (furData.fur[6].w > 0.5) maskLength = 1.0 - maskLength;
    }
    if (undercoat) {
        if (maskLength < 0.02) discard;
        strandRandom = hash3(floor(vObjectPos / max(f0.y, 1e-5))).z;
    } else if (!cards) {
        float spacing = max(f0.y, 1e-5);
        vec3 n = normalize(vObjectNormal);
        vec3 p = vObjectPos;
        // Clumps: roots pulled toward a clump center (4 spacings apart) toward the tip.
        if (f1.x > 0.0) {
            float size = spacing * 4.0;
            vec3 cc = floor(p / size);
            vec3 center = (cc + 0.5 + (hash3(cc + vec3(31.0, 17.0, 5.0)) - 0.5) * 0.6) * size;
            center -= n * dot(center - p, n);
            float pull = min(f1.x * h * 0.85, 0.9);
            p = center + (p - center) / (1.0 - pull);
        }
        vec3 cell = floor(p / spacing);
        vec3 r = hash3(cell);
        vec3 strand = (cell + 0.5 + (r - 0.5) * 0.5) * spacing;
        vec3 e1 = normalize(abs(n.y) < 0.9 ? cross(n, vec3(0.0, 1.0, 0.0)) : cross(n, vec3(1.0, 0.0, 0.0)));
        vec3 e2 = cross(n, e1);
        if (f1.y > 0.0) {
            float angle = h * 12.566 + r.x * 6.283;
            strand += (e1 * cos(angle) + e2 * sin(angle)) * (f1.y * 0.3 * spacing);
        }
        if (f1.z > 0.0) {
            float k = h * 4.0;
            vec3 a = hash3(cell + vec3(floor(k) * 7.0, 3.0, 11.0)), b = hash3(cell + vec3(floor(k) * 7.0 + 7.0, 3.0, 11.0));
            strand += (mix(a, b, smoothstep(0.0, 1.0, fract(k))) - 0.5) * (f1.z * 0.4 * spacing * h);
        }
        vec3 d = p - strand;
        d -= n * dot(d, n);
        float strandLength = (1.0 - f2.y * r.y) * min(maskLength, 1.0);
        if (h > strandLength) discard;
        float radius = mix(f0.z, f0.w, h / max(strandLength, 1e-3)) * 0.5 * spacing;
        if (dot(d, d) > radius * radius) discard;
        along = h / max(strandLength, 1e-3);
        strandRandom = r.z;
    } else {
        float strands = max(furData.fur[4].w, 1.0);
        float u = vUV.x * strands;
        float index = floor(u);
        vec3 r = hash3(vec3(index, floor(vFur.y * 65535.0), 7.0));
        float x = fract(u) - 0.5 + (r.x - 0.5) * 0.3;
        float v = h;
        float strandLength = 1.0 - f2.y * r.y;
        if (v > strandLength) discard;
        along = v / max(strandLength, 1e-3);
        float halfWidth = mix(f0.z, f0.w, along) * 0.5;
        alpha = 1.0 - smoothstep(halfWidth * 0.55, halfWidth, abs(x));
        alpha *= 1.0 - smoothstep(0.85, 1.0, along);
        if (alpha < 0.03) discard;
        strandRandom = r.z;
    }

    vec3 rootColor = furData.fur[3].rgb, tipColor = furData.fur[4].rgb;
    float noise = 1.0 + (strandRandom - 0.5) * 2.0 * f2.z;
    vec3 albedo = mix(rootColor, tipColor, pow(along, 0.8)) * max(noise, 0.0) * vColor.rgb;
    // Self-shadowing: darker toward the roots (and in the undercoat).
    float occlusion = undercoat ? 0.4 : mix(0.4, 1.0, along);

    vec3 n = normalize(vNormal);
    if (cards && !gl_FrontFacing) n = -n;
    vec3 t = normalize(vStrand);
    vec3 l = normalize(frame.lightDir.xyz);
    vec3 v = normalize(frame.cameraPos.xyz - vWorldPos);
    vec3 hv = normalize(l + v);
    bool receivesShadows = vParams.x > 0.5;
    float shadow = 1.0;
    if (frame.lightColor.w > 0.5 && receivesShadows) {
        vec3 tint;
        shadow = directionalShadow(vWorldPos, n, tint);
        albedo *= tint;
    }
    vec3 light = frame.lightColor.rgb * frame.lightDir.w;
    float wrap = clamp(dot(n, l) * 0.6 + 0.4, 0.0, 1.0);
    float diffuse = wrap * wrap * mix(0.75, 1.0, occlusion);
    float shift = (strandRandom - 0.5) * 0.3;
    vec3 t1 = normalize(t + n * (0.1 + shift));
    vec3 t2 = normalize(t + n * (-0.12 + shift));
    float facing = smoothstep(-0.2, 0.35, dot(n, l));
    vec3 specular = (vec3(0.22) * strandHighlight(t1, hv, 90.0) + tipColor * 0.55 * strandHighlight(t2, hv, 18.0))
        * (f2.w * facing * occlusion);
    vec3 color = (albedo * diffuse + specular) * light * shadow;
    vec3 irradiance = frame.environment.x > 0.5 ? environmentIrradiance(n) : hemisphere(n);
    color += albedo * irradiance * occlusion;
    if (frame.clusterGrid.w > 0.5) {
        uvec2 cell = clusterLights();
        for (uint i = cell.x; i < cell.x + cell.y; i++) {
            vec3 pl;
            uint li = lightIndex(i);
            vec3 radiance = punctualRadiance(li, pl);
            if (receivesShadows) radiance *= localShadow(li, vWorldPos, n, pl);
            float pw = clamp(dot(n, pl) * 0.6 + 0.4, 0.0, 1.0);
            color += albedo * pw * pw * radiance;
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
    outMotion = motionVector(vCurrentClip, vPreviousClip);
}
