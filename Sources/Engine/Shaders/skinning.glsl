// Skeletal skinning for SceneRenderer's skinned meshes (SkinnedMeshVertex: MeshVertex plus
// four joints and weights). Included by the *_skinned.vert shaders.
//
// Uniform buffer 2 holds the material first (the fragment shaders read it as MaterialData, see
// mesh_surface.glsl), padded to 128 bytes, then this draw's joint matrices: MAX_JOINTS for this
// frame and MAX_JOINTS for the last one (motion vectors), each an affine 3x4 matrix stored as
// three rows. Must match `SkinPose.uniformBlock`.
#define MAX_JOINTS 128

layout(set = 2, binding = 2, std140) uniform Skin {
    vec4 material[8];
    vec4 joints[MAX_JOINTS * 3];
    vec4 previousJoints[MAX_JOINTS * 3];
} skin;

layout(location = 14) in vec4 inJoints;   // joint indices (as floats)
layout(location = 15) in vec4 inWeights;  // sum to 1

// Positions computed from these matrices are `precise` (no fused multiply-adds or reordering
// left to the Metal compiler) in every skinned vertex shader: Metal compiles them with fast
// math, and the same MSL compiled natively (joints in a plain buffer) and by MoltenVK (joints
// behind an argument buffer) contracted differently, so a skinned shadow caster's depth
// differed by an ulp between backends, which flipped a shadow comparison now and then.
//
// The weighted sum of the vertex's joint matrices (mesh space, bind pose to posed).
mat4 skinMatrix() {
    precise vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        int j = int(inJoints[k]) * 3;
        r0 += skin.joints[j] * inWeights[k];
        r1 += skin.joints[j + 1] * inWeights[k];
        r2 += skin.joints[j + 2] * inWeights[k];
    }
    return transpose(mat4(r0, r1, r2, vec4(0.0, 0.0, 0.0, 1.0)));
}

// The same with last frame's joint matrices.
mat4 previousSkinMatrix() {
    precise vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        int j = int(inJoints[k]) * 3;
        r0 += skin.previousJoints[j] * inWeights[k];
        r1 += skin.previousJoints[j + 1] * inWeights[k];
        r2 += skin.previousJoints[j + 2] * inWeights[k];
    }
    return transpose(mat4(r0, r1, r2, vec4(0.0, 0.0, 0.0, 1.0)));
}
