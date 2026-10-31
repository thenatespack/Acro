#version 450
#extension GL_GOOGLE_include_directive : require

// Bloom downsample (Jimenez, "Next Generation Post Processing in Call of Duty: Advanced
// Warfare", 2014): writes one level at half the source's resolution. Output pixel x covers
// source texels 2x and 2x + 1; 13 taps on the source texel corners around it, each the average
// of a 2x2 texel box, are combined as five overlapping 4x4 groups: the center (weight 0.5) and
// the four corner groups (0.125 each). The boxes are computed from exact texel loads (the same
// result as bilinear taps at the corners, without depending on the filtering hardware).
// On the first level each group is weighted by 1 / (1 + luma) (Karis average), so a single
// very bright pixel (a specular firefly) can't make a flickering blob.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sourceImage;

layout(push_constant) uniform PushConstants {
    ivec2 sourceMax;  // source size - 1
    float karis;      // 1 on the first level
    float maxValue;   // the source is clamped to this (first level: guards against huge or inf values)
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    // Output pixel x covers texels 2x and 2x + 1; the 13 boxes span texels 2x - 2 ... 2x + 3.
    // Each of those 6x6 texels is loaded once (52 loads if each box loaded its own four).
    ivec2 o = ivec2(gl_FragCoord.xy) * 2 - 2;
    vec3 t[36];
    for (int y = 0; y < 6; y++) {
        for (int x = 0; x < 6; x++) {
            t[y * 6 + x] = min(loadClamped(sourceImage, o + ivec2(x, y), pc.sourceMax), vec3(pc.maxValue));
        }
    }
    // The 2x2 box whose top-left texel is (i, j) in that block.
#define BOX(i, j) ((t[(j) * 6 + (i)] + t[(j) * 6 + (i) + 1] + t[((j) + 1) * 6 + (i)] + t[((j) + 1) * 6 + (i) + 1]) * 0.25)
    vec3 A = BOX(0, 0), B = BOX(2, 0), C = BOX(4, 0);
    vec3 D = BOX(1, 1), E = BOX(3, 1);
    vec3 F = BOX(0, 2), G = BOX(2, 2), H = BOX(4, 2);
    vec3 I = BOX(1, 3), J = BOX(3, 3);
    vec3 K = BOX(0, 4), L = BOX(2, 4), M = BOX(4, 4);

    vec3 groups[5] = vec3[5]((D + E + I + J) * 0.25, (A + B + F + G) * 0.25, (B + C + G + H) * 0.25,
                             (F + G + K + L) * 0.25, (G + H + L + M) * 0.25);
    float weights[5] = float[5](0.5, 0.125, 0.125, 0.125, 0.125);
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int k = 0; k < 5; k++) {
        float w = pc.karis > 0.5 ? weights[k] / (1.0 + luminance(groups[k])) : weights[k];
        sum += groups[k] * w;
        total += w;
    }
    outColor = vec4(sum / total, 1.0);
}
