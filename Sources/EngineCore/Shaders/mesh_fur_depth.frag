#version 450
#extension GL_GOOGLE_include_directive : require

// Fur and hair in the shadow atlas (depth only, SceneRenderer+Fur.swift): keeps the fragments on
// a strand (fur_strands.glsl), so fur casts the strands it draws. The renderer draws only a few
// shells per groom here (`RenderPrep.appendFur`), so their strands are widened to stand in for
// the shells between; card strands are cut at half coverage, like alpha-to-coverage at one sample.

// The prefix of fur.glsl's block.
layout(set = 2, binding = 2, std140) uniform FurData {
    vec4 material[8];
    vec4 fur[8];
} furData;

layout(set = 2, binding = 10) uniform texture2D maskMap;
layout(set = 2, binding = 17) uniform sampler materialSampler;

layout(location = 2) in vec2 vUV;
layout(location = 4) in vec3 vObjectPos;
layout(location = 8) in vec4 vFur;
layout(location = 10) in vec3 vObjectNormal;

#include "fur_strands.glsl"

void main() {
    float along, strandRandom, alpha, exposed;
    bool cards = vFur.z > 0.5;
    if (!furCoverage(cards ? 1.0 : 1.7, along, strandRandom, alpha, exposed) || alpha < 0.5) discard;
}
