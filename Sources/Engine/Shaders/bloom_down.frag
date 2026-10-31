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

// The 2x2 box whose top-left texel is source texel p.
vec3 box(ivec2 p) {
    vec3 a = min(loadClamped(sourceImage, p, pc.sourceMax), vec3(pc.maxValue));
    vec3 b = min(loadClamped(sourceImage, p + ivec2(1, 0), pc.sourceMax), vec3(pc.maxValue));
    vec3 c = min(loadClamped(sourceImage, p + ivec2(0, 1), pc.sourceMax), vec3(pc.maxValue));
    vec3 d = min(loadClamped(sourceImage, p + ivec2(1, 1), pc.sourceMax), vec3(pc.maxValue));
    return (a + b + c + d) * 0.25;
}

void main() {
    // Box at corner offset (i, j) from the pixel's center corner starts at texel 2x + i, 2y + j.
    ivec2 o = ivec2(gl_FragCoord.xy) * 2;
    vec3 A = box(o + ivec2(-2, -2)), B = box(o + ivec2(0, -2)), C = box(o + ivec2(2, -2));
    vec3 D = box(o + ivec2(-1, -1)), E = box(o + ivec2(1, -1));
    vec3 F = box(o + ivec2(-2, 0)), G = box(o), H = box(o + ivec2(2, 0));
    vec3 I = box(o + ivec2(-1, 1)), J = box(o + ivec2(1, 1));
    vec3 K = box(o + ivec2(-2, 2)), L = box(o + ivec2(0, 2)), M = box(o + ivec2(2, 2));

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
