// Lit particles (`ParticleEmitter.lit`), included by particle_lit.vert: the light reaching a
// quad corner, evaluated per vertex (a particle's six vertices rather than every pixel it
// covers: overdraw of big, overlapping puffs made per-pixel lighting cost several ms) and
// interpolated across the quad. Not compiled on its own; rerun Scripts/compile-shaders.sh
// after editing it.
//
// The puff is thin and isotropic, facing the camera: the ambient light toward the camera
// (hemisphere, or the environment's SH9 irradiance), the sun with half-Lambert wrap and
// optionally its cascaded shadow, and the clustered point / spot lights (same falloff and
// cones as mesh_surface.glsl). SceneRenderer binds its frame uniforms (set 0), its light buffers
// (3-7), the environment atlas (texture 6) and the shadow atlas as a plain depth texture
// (texture 3) for the vertex stage; the shadow is a bilinear 2x2 depth comparison with texel
// loads (vertex functions don't do comparison sampling everywhere).

// Must match `SceneRenderer.FrameUniforms` (as in mesh_surface.glsl).
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

layout(set = 2, binding = 3, std140) uniform LightPositions { vec4 data[1024]; } lightPositions;
layout(set = 2, binding = 4, std140) uniform LightColors { vec4 data[1024]; } lightColors;
layout(set = 2, binding = 5, std140) uniform LightDirections { vec4 data[1024]; } lightDirections;
layout(set = 2, binding = 6, std140) uniform LightCells { uvec4 data[1024]; } lightCells;
layout(set = 2, binding = 7, std140) uniform LightIndices { uvec4 data[1024]; } lightIndices;
layout(set = 2, binding = 11) uniform texture2D shadowAtlas;
layout(set = 2, binding = 14) uniform texture2D environmentAtlas;
layout(set = 2, binding = 17) uniform sampler particleSampler;

#include "environment.glsl"

vec3 ambientLight(vec3 n) {
    if (frame.environment.x > 0.5) {
        float y[9];
        shBasis(environmentDirection(n, frame.environment.zw), y);
        vec3 sum = vec3(0.0);
        for (int i = 0; i < 9; i++) {
            sum += texelFetch(sampler2D(environmentAtlas, particleSampler), ENV_SH + ivec2(i, 0), 0).rgb * y[i];
        }
        return max(sum, vec3(0.0)) * frame.environment.y;
    }
    return mix(frame.groundColor.rgb, frame.skyColor.rgb, n.y * 0.5 + 0.5) * frame.skyColor.w;
}

// Cascade c's shadow at p: 2x2 depth comparisons (lit where ref <= stored depth, as the
// comparison sampler), bilinearly weighted, kept inside the cascade's tile.
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
        lit[i] = ref <= texelFetch(sampler2D(shadowAtlas, particleSampler), texel, 0).r ? 1.0 : 0.0;
    }
    return mix(mix(lit[0], lit[1], f.x), mix(lit[2], lit[3], f.x), f.y);
}

// The sun's shadow at p: the cascade its view depth falls in, blended into the next one near
// the cascade's end (the last fades to lit), as directionalShadow in shadows.glsl.
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

// The light reaching a puff at p seen along v (unit, toward the camera); `clip` is p's clip
// position (before the y flip), which picks its light cluster.
vec3 particleLight(vec3 p, vec3 v, vec4 clip, bool shadowed) {
    vec3 light = ambientLight(v);
    vec3 l = normalize(frame.lightDir.xyz);
    float shadow = frame.lightColor.w > 0.5 && shadowed ? sunShadow(p) : 1.0;
    light += frame.lightColor.rgb * frame.lightDir.w * (dot(v, l) * 0.5 + 0.5) * shadow;
    if (frame.clusterGrid.w > 0.5 && clip.w > 0.0) {
        // The cluster of the screen tile and depth slice p falls in (as mesh_surface.glsl, from
        // its clip position rather than gl_FragCoord).
        float depth = dot(frame.viewDepth.xyz, p) + frame.viewDepth.w;
        vec2 screen = vec2(clip.x / clip.w * 0.5 + 0.5, 0.5 - clip.y / clip.w * 0.5);
        vec2 tile = clamp(floor(screen * frame.clusterGrid.xy), vec2(0.0), frame.clusterGrid.xy - 1.0);
        float slice = clamp(floor(log2(max(depth, 1e-6)) * frame.clusterScale.z + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
        uint cluster = uint((slice * frame.clusterGrid.y + tile.y) * frame.clusterGrid.x + tile.x);
        uint cell = lightCells.data[cluster >> 2][cluster & 3u];
        uint first = cell & 0xFFFFu, count = cell >> 16;
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
            light += color.rgb * (window * window * cone * cone / max(d2, 1e-4)) * (dot(v, pl) * 0.5 + 0.5);
        }
    }
    return light;
}
