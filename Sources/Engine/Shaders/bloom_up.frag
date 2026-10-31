#version 450
#extension GL_GOOGLE_include_directive : require

// Bloom upsample: level i = (downsampled level i + the coarser level upsampled with a 3x3 tent)
// / 2. Every level is an energy-preserving blur of the scene, and the halving makes the final
// weights 1/2, 1/4, … (the coarsest two share the last), which sum to 1: the result is a wide,
// energy-conserving blur that the tonemap pass mixes in by the bloom intensity.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D coarseImage;   // level i + 1 (already upsampled)
layout(set = 2, binding = 10) uniform texture2D detailImage;  // level i of the downsample chain

layout(push_constant) uniform PushConstants {
    ivec2 coarseMax;  // coarse size - 1
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec3 coarse = tentUpsample(coarseImage, p, pc.coarseMax);
    vec3 detail = texelFetch(sampler2D(detailImage, pointSampler), p, 0).rgb;
    outColor = vec4((detail + coarse) * 0.5, 1.0);
}
