#version 450
#extension GL_GOOGLE_include_directive : require

// Environment precomputation, step 3 (see EnvironmentLighting.swift): the sharpest level
// box-filtered down by `factor` per axis for the SH projection, each source row weighted by its
// solid angle (sin theta), so the result is the average radiance over each output texel.

#include "environment.glsl"

layout(set = 2, binding = 9) uniform texture2D source;
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    int factor;
    int sourceHeight;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    ivec2 base = ivec2(gl_FragCoord.xy) * pc.factor;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int j = 0; j < pc.factor; j++) {
        int y = base.y + j;
        float w = sin((float(y) + 0.5) / float(pc.sourceHeight) * ENV_PI);
        vec3 row = vec3(0.0);
        for (int i = 0; i < pc.factor; i++) {
            row += texelFetch(sampler2D(source, pointSampler), ivec2(base.x + i, y), 0).rgb;
        }
        sum += row * w;
        weight += w * float(pc.factor);
    }
    outColor = vec4(sum / weight, 1.0);
}
