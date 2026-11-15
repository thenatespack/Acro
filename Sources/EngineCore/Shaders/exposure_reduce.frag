#version 450
#extension GL_GOOGLE_include_directive : require

// Auto-exposure, step 1: the scene's log2 luminance averaged over a coarse grid. Each output
// pixel (of a small fixed-size target) covers a block of the HDR scene image and averages 8x8
// stratified texels in it. exposure_adapt.frag reduces the grid to one value.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sceneImage;

layout(push_constant) uniform PushConstants {
    ivec2 sceneSize;
    ivec2 gridSize;
} pc;

layout(location = 0) out vec4 outColor;

const int SAMPLES = 8;

void main() {
    ivec2 cell = ivec2(gl_FragCoord.xy);
    float sum = 0.0;
    for (int j = 0; j < SAMPLES; j++) {
        for (int i = 0; i < SAMPLES; i++) {
            // Texel at the center of sub-cell (i, j), in exact integer arithmetic.
            ivec2 sub = cell * SAMPLES + ivec2(i, j);
            ivec2 p = ((sub * 2 + 1) * pc.sceneSize) / (pc.gridSize * SAMPLES * 2);
            vec3 c = texelFetch(sampler2D(sceneImage, pointSampler), p, 0).rgb;
            sum += log2(max(luminance(c), 1.0 / 65536.0));
        }
    }
    outColor = vec4(sum / float(SAMPLES * SAMPLES), 0.0, 0.0, 1.0);
}
