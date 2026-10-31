#version 450
#extension GL_GOOGLE_include_directive : require

// Auto-exposure, step 2 (a 1x1 target): averages the log2-luminance grid, turns it into the
// exposure in EV that maps the average to middle gray (`key`), clamped, and moves last frame's
// exposure toward it by `rate` (1 - e^(-dt * speed), computed on the CPU; 1 converges at once).
// The result is next frame's history and what the tonemap pass applies. Mirrors
// `PostProcessMath.autoExposureEV` and `adapt`.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D gridImage;     // exposure_reduce output
layout(set = 2, binding = 10) uniform texture2D historyImage;  // last frame's result (r: EV)

layout(push_constant) uniform PushConstants {
    ivec2 gridSize;
    float rate;
    float key;    // log2 of the luminance the average maps to (middle gray 0.18)
    float minEV;
    float maxEV;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    float sum = 0.0;
    for (int y = 0; y < pc.gridSize.y; y++) {
        float row = 0.0;
        for (int x = 0; x < pc.gridSize.x; x++) {
            row += texelFetch(sampler2D(gridImage, pointSampler), ivec2(x, y), 0).r;
        }
        sum += row;
    }
    float average = sum / float(pc.gridSize.x * pc.gridSize.y);
    float target = clamp(pc.key - average, pc.minEV, pc.maxEV);
    float previous = texelFetch(sampler2D(historyImage, pointSampler), ivec2(0), 0).r;
    // rate 1 (a reset) ignores the history, which may hold anything then.
    outColor = vec4(pc.rate >= 1.0 ? target : previous + (target - previous) * pc.rate, 0.0, 0.0, 1.0);
}
