#version 450
#extension GL_GOOGLE_include_directive : require

// Depth of field (PostProcessSettings.depthOfField, PostProcessor.renderDepthOfField): the HDR
// scene blurred by each pixel's circle of confusion, before bloom and exposure.
//
// The circle of confusion (radius in pixels) of a point z meters away along the view axis is
// scale * max(|z - focus| - halfRange, 0) / z, at most the largest radius (the thin-lens
// formula; `PostProcessMath.circleOfConfusion` mirrors it). Every pixel gathers taps on a
// golden-angle spiral out to the largest radius ("scatter as gather", after Dennis Gustafsson's
// single-pass bokeh depth of field): a tap counts where its own circle reaches this pixel, so
// blurry foreground spreads over sharp background but sharp foreground doesn't pick up the blur
// behind it (taps farther than this pixel are limited to twice its own circle). Bright taps
// spread into discs, the bokeh. Taps are exact texel loads at rounded offsets, like the other
// post passes, so every backend gives the same bytes.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sceneImage;
layout(set = 2, binding = 10) uniform texture2D depthImage;

layout(push_constant) uniform PushConstants {
    vec4 linearize;   // view distance from depth d: (x d + y) / (z d + w)
    vec4 lens;        // x focus (m), y half the sharp range (m), z circle scale (px), w largest radius (px)
    ivec2 maxTexel;   // size - 1
    float radiusStep; // the spiral's radius grows by radiusStep / radius per tap
    float pad;
} pc;

layout(location = 0) out vec4 outColor;

const float goldenAngle = 2.39996323;

float viewDistance(ivec2 p) {
    float d = texelFetch(sampler2D(depthImage, pointSampler), p, 0).r;
    float w = pc.linearize.z * d + pc.linearize.w;
    float z = abs(w) < 1e-12 ? 1e6 : abs((pc.linearize.x * d + pc.linearize.y) / w);
    return clamp(z, 1e-4, 1e6);
}

float circle(float z) {
    return min(pc.lens.z * max(abs(z - pc.lens.x) - pc.lens.y, 0.0) / z, pc.lens.w);
}

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    float centerDistance = viewDistance(p);
    float centerSize = circle(centerDistance);
    vec3 color = texelFetch(sampler2D(sceneImage, pointSampler), p, 0).rgb;
    float total = 1.0;
    float radius = pc.radiusStep;
    float angle = 0.0;
    for (int i = 0; i < 160 && radius < pc.lens.w; i++) {
        ivec2 q = clamp(p + ivec2(round(vec2(cos(angle), sin(angle)) * radius)), ivec2(0), pc.maxTexel);
        vec3 tap = texelFetch(sampler2D(sceneImage, pointSampler), q, 0).rgb;
        float tapDistance = viewDistance(q);
        float tapSize = circle(tapDistance);
        if (tapDistance > centerDistance) tapSize = clamp(tapSize, 0.0, centerSize * 2.0);
        float m = smoothstep(radius - 0.5, radius + 0.5, tapSize);
        color += mix(color / total, tap, m);
        total += 1.0;
        radius += pc.radiusStep / radius;
        angle += goldenAngle;
    }
    outColor = vec4(color / total, 1.0);
}
