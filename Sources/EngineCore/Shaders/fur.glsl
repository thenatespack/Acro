// Fur and hair (Groom.swift): SceneRenderer's vertex stage for fur materials (`Material.fur`),
// included by mesh_fur.vert and mesh_fur_skinned.vert (which defines SKINNED), and with FUR_DEPTH
// by mesh_fur_depth(_skinned).vert, the shadow atlas's fur casters (only the position and what
// fur_strands.glsl needs; `Frame` is then the shadow pass's two matrices). Not compiled on its
// own; rerun Scripts/compile-shaders.sh after editing it. Pairs with mesh_fur.frag /
// mesh_fur_depth.frag. mesh_fur_sim.vert defines SIMULATED: simulated hair cards
// (HairSimulation.swift), their vertices already in world space (identity model) and last
// frame's position in attribute 14 (the `VertexPaint` stream) for the motion vectors.
//
// Uniform buffer 2 (both stages; must match `SceneRenderer.furBlock`): the material (padded to
// 8 vec4, unused here), the groom's numbers, and for skinned meshes a spring offset per joint and
// the joint matrices (as skinning.glsl's block, after the springs):
// - fur[0]: x length (m), y strand spacing (m), z root thickness, w tip thickness (0-1 of the spacing);
// - fur[1]: x clumping, y curl, z frizz, w droop (gravity x bendability);
// - fur[2]: x bendability (1 - 0.8 stiffness), y length variation, z color noise, w specular;
// - fur[3]: rgb root color (linear), w 1 for cards;
// - fur[4]: rgb tip color (linear), w strands per card;
// - fur[5]: xy the wind's direction in XZ, z its strength x the groom's wind, w gustiness;
// - fur[6]: x time, y last frame's, z 1 with a mask texture (texture 2), w 1 when the mask is inverted;
// - fur[7]: x the pass's MSAA sample count, y a frame counter (mod 64; card dithering).
//
// Instances (MeshInstance): color rgb the GroomRenderer's tint, color w the item's shell count
// (shells; mesh_fur.frag thins out alike shells; its fraction the opacity boost of shells drawn
// for several, `RenderPrep.appendFur`) or -1 for simulated cards (nothing bends them here), params.x receives shadows, params.y the shell's height (0...1 of the
// length; 0 the undercoat just above the surface; 2 for fins, GroomFins, whose vertices carry
// their height in UV y and their strand coordinate in UV x), params.zw a rigid entity's spring lag in
// world X and Z (meters). Shell vertices carry the comb vector in tangent.xyz (mesh space) and
// 1 + the length factor in tangent.w; card vertices their strand direction and 2 + a random
// number per card.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
#ifndef FUR_DEPTH
    mat4 currentViewProj;
    mat4 previousViewProj;
#endif
} frame;

#define MAX_JOINTS 128
layout(set = 2, binding = 2, std140) uniform FurData {
    vec4 material[8];
    vec4 fur[8];
#ifdef SKINNED
    vec4 springs[MAX_JOINTS];
    vec4 joints[MAX_JOINTS * 3];
    vec4 previousJoints[MAX_JOINTS * 3];
#endif
} furData;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inUV;
layout(location = 3) in vec4 model0;
layout(location = 4) in vec4 model1;
layout(location = 5) in vec4 model2;
layout(location = 6) in vec4 model3;
layout(location = 7) in vec4 previous0;
layout(location = 8) in vec4 previous1;
layout(location = 9) in vec4 previous2;
layout(location = 10) in vec4 previous3;
layout(location = 11) in vec4 inColor;
layout(location = 12) in vec4 inParams;
layout(location = 13) in vec4 inTangent;
#ifdef SKINNED
layout(location = 14) in vec4 inJoints;
layout(location = 15) in vec4 inWeights;
#endif
#ifdef SIMULATED
layout(location = 14) in vec4 inPrevious;     // last frame's world position (xyz)
#endif

#ifndef FUR_DEPTH
layout(location = 0) out vec3 vWorldPos;
layout(location = 1) out vec3 vNormal;
#endif
layout(location = 2) out vec2 vUV;
#ifndef FUR_DEPTH
layout(location = 3) out vec4 vColor;
#endif
layout(location = 4) out vec3 vObjectPos;     // the root's position in the mesh's (bind pose) space
#ifndef FUR_DEPTH
layout(location = 5) out vec4 vParams;
layout(location = 6) out vec4 vCurrentClip;
layout(location = 7) out vec4 vPreviousClip;
#endif
layout(location = 8) out vec4 vFur;           // x height along the strand 0...1, y card random, z 1 for cards, w 1 for the undercoat
#ifndef FUR_DEPTH
layout(location = 9) out vec3 vStrand;        // world-space strand direction
#endif
layout(location = 10) out vec3 vObjectNormal; // the root's normal in the mesh's space

#ifdef SKINNED
// As skinning.glsl (this block has the springs before the joints).
mat4 skinMatrix() {
    precise vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        int j = int(inJoints[k]) * 3;
        r0 += furData.joints[j] * inWeights[k];
        r1 += furData.joints[j + 1] * inWeights[k];
        r2 += furData.joints[j + 2] * inWeights[k];
    }
    return transpose(mat4(r0, r1, r2, vec4(0.0, 0.0, 0.0, 1.0)));
}

mat4 previousSkinMatrix() {
    precise vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        int j = int(inJoints[k]) * 3;
        r0 += furData.previousJoints[j] * inWeights[k];
        r1 += furData.previousJoints[j + 1] * inWeights[k];
        r2 += furData.previousJoints[j + 2] * inWeights[k];
    }
    return transpose(mat4(r0, r1, r2, vec4(0.0, 0.0, 0.0, 1.0)));
}

// The springs of the vertex's joints, blended like the joints (world meters).
vec3 springLag() {
    vec3 s = vec3(0.0);
    for (int k = 0; k < 4; k++) s += furData.springs[int(inJoints[k])].xyz * inWeights[k];
    return s;
}
#else
vec3 springLag() { return vec3(inParams.z, 0.0, inParams.w); }
#endif

// The wind's lean on a strand rooted at world `base` at `time` (unitless: added to the strand's
// direction, so 0.3 tips a strand about 17 degrees). Gusts roll across the scene like wind.glsl's.
vec3 furWind(vec3 base, float time) {
    precise vec2 dir = furData.fur[5].xy;
    precise float phase = dot(base.xz, dir) * 0.35 + dot(base.xz, vec2(0.83, -0.57)) * 1.7;
    precise float g = 0.5 + 0.5 * sin(time * 0.61 + phase) * sin(time * 0.23 + phase * 0.7);
    precise float gust = 1.0 + furData.fur[5].w * (g * 1.6 - 0.6);
    precise float n = dot(base, vec3(3.1, 2.3, 2.7)) * 3.0;
    precise float flutter = 0.7 + 0.3 * sin(time * 4.7 + n) * sin(time * 2.9 + n * 0.37);
    precise vec3 lean = vec3(dir.x, 0.0, dir.y) * (furData.fur[5].z * gust * flutter * 0.35);
    return lean;
}

// The world position of this vertex's point of the strand for `model` (skin included) at `time`,
// and the strand's direction there.
vec3 furPosition(mat4 model, float time, out vec3 strand) {
    precise vec3 base = (model * vec4(inPosition, 1.0)).xyz;
    vec3 a = model[0].xyz, b = model[1].xyz, c = model[2].xyz;
    mat3 cofactor = mat3(cross(b, c), cross(c, a), cross(a, b));
    float handedness = dot(cross(a, b), c) < 0.0 ? -1.0 : 1.0;
    vec3 n = normalize(cofactor * inNormal * handedness);
    float bendable = furData.fur[2].x;
    bool cards = furData.fur[3].w > 0.5;
    // Simulated cards (color w -1) are already where the simulation put them.
    float animated = inColor.w < -0.5 ? 0.0 : 1.0;
    precise vec3 dynamic = (furWind(model[3].xyz, time) + springLag() / max(furData.fur[0].x, 1e-3)) * (bendable * animated);
    if (cards) {
        // Cards are grown already: only wind and motion bend them, more toward the tip.
        float v = inUV.y;
        strand = normalize(mat3(a, b, c) * inTangent.xyz + dynamic * (2.0 * v));
        precise vec3 moved = base + dynamic * (furData.fur[0].x * v * v);
        return moved;
    }
    bool fin = inParams.y > 1.5;
    float h = fin ? inUV.y : inParams.y;
    float len = furData.fur[0].x * max(inTangent.w - 1.0, 0.0);
    if (h <= 0.0 && !fin) {
        // The undercoat: just above the surface.
        strand = n;
        precise vec3 lifted = base + n * (len * 0.04 + 0.0004);
        return lifted;
    }
    vec3 comb = mat3(a, b, c) * inTangent.xyz;
    float lean = min(length(comb), 1.0);
    vec3 droop = vec3(0.0, -furData.fur[1].w, 0.0) + dynamic;
    strand = normalize(n * (1.0 - lean) + comb + droop * h);
    precise vec3 d = normalize(n * (1.0 - lean) + comb + droop * (0.5 * h)) * (len * h);
    // Never below the surface (gravity and combing would push roots inside).
    precise float up = dot(d, n);
    precise float minimum = len * h * 0.12;
    if (up < minimum) d += n * (minimum - up);
    precise vec3 moved = base + d;
    return moved;
}

void main() {
    precise mat4 model = mat4(model0, model1, model2, model3);
#ifdef SKINNED
    model = model * skinMatrix();
#endif
    vec3 strand;
    precise vec3 world = furPosition(model, furData.fur[6].x, strand);
    precise vec4 clip = frame.viewProj * vec4(world, 1.0);
    gl_Position = clip;
    gl_Position.y = -gl_Position.y;  // clip space is y-up; see beginPass in VulkanRenderDevice
    bool cards = furData.fur[3].w > 0.5;
    bool fin = !cards && inParams.y > 1.5;
    vFur = vec4(cards || fin ? inUV.y : inParams.y, cards ? fract(inTangent.w) : 0.0, cards ? 1.0 : fin ? 2.0 : 0.0,
                !cards && inParams.y <= 0.0 ? 1.0 : 0.0);
    vUV = inUV;
    vObjectPos = inPosition;
    vObjectNormal = inNormal;
#ifndef FUR_DEPTH
    precise mat4 previousModel = mat4(previous0, previous1, previous2, previous3);
#ifdef SKINNED
    previousModel = previousModel * previousSkinMatrix();
#endif
    vec3 previousStrand;
#ifdef SIMULATED
    precise vec3 previousWorld = inPrevious.xyz;
#else
    precise vec3 previousWorld = furPosition(previousModel, furData.fur[6].y, previousStrand);
#endif
    vec3 a = model[0].xyz, b = model[1].xyz, c = model[2].xyz;
    mat3 cofactor = mat3(cross(b, c), cross(c, a), cross(a, b));
    float handedness = dot(cross(a, b), c) < 0.0 ? -1.0 : 1.0;
    vWorldPos = world;
    vNormal = cofactor * inNormal * handedness;
    vColor = inColor;
    vParams = vec4(inParams.x, 0.0, 0.0, 0.0);
    precise vec4 currentClip = frame.currentViewProj * vec4(world, 1.0);
    precise vec4 previousClip = frame.previousViewProj * vec4(previousWorld, 1.0);
    vCurrentClip = currentClip;
    vPreviousClip = previousClip;
    vStrand = strand;
#endif
}
