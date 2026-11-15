#version 450
#extension GL_GOOGLE_include_directive : require

// Environment precomputation, step 4 (see EnvironmentLighting.swift): diffuse irradiance as
// nine SH coefficients (bands 0-2), one per output texel (x = coefficient index). Projects the
// downsampled radiance with the exact solid angle of each equirectangular texel, then applies
// the clamped-cosine convolution (Ramamoorthi & Hanrahan 2001: pi, 2pi/3, pi/4 per band) divided
// by pi, so evaluating the result gives irradiance / pi: a uniform environment of radiance L
// gives L, as the hemisphere ambient does. Same math as `EnvironmentMath.projectIrradianceSH`.

#include "environment.glsl"

layout(set = 2, binding = 9) uniform texture2D source;
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    ivec2 sourceSize;
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    int k = int(gl_FragCoord.x);
    vec2 size = vec2(pc.sourceSize);
    float dphi = 2.0 * ENV_PI / size.x;
    vec3 sum = vec3(0.0);
    for (int y = 0; y < pc.sourceSize.y; y++) {
        // Solid angle of one texel of this row: dphi (cos theta0 - cos theta1).
        float dw = dphi * (cos(float(y) / size.y * ENV_PI) - cos(float(y + 1) / size.y * ENV_PI));
        vec3 row = vec3(0.0);
        for (int x = 0; x < pc.sourceSize.x; x++) {
            float basis[9];
            shBasis(equirectDirection((vec2(x, y) + 0.5) / size), basis);
            row += texelFetch(sampler2D(source, pointSampler), ivec2(x, y), 0).rgb * basis[k];
        }
        sum += row * dw;
    }
    float band = k == 0 ? 1.0 : (k < 4 ? 2.0 / 3.0 : 0.25);
    outColor = vec4(sum * band, 1.0);
}
