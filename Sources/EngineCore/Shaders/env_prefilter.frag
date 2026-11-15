#version 450
#extension GL_GOOGLE_include_directive : require

// Environment precomputation, step 2 (see EnvironmentLighting.swift): one prefiltered radiance
// level, convolved from the previous (sharper, twice as large) level with the GGX lobe under
// the usual N = V = R assumption, weighted by N.L. Progressive: the previous level is already
// blurred by its own roughness, so this level only adds the difference,
// alpha = sqrt(alpha_level² - alpha_previous²) (GGX lobes widen roughly like Gaussians), which
// keeps the lobe at a few source texels and a fixed Hammersley set of samples noise-free.
// Bilinear texel loads (`sampleEquirect`), so Metal and Vulkan agree exactly.

#include "environment.glsl"

layout(set = 2, binding = 9) uniform texture2D source;
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    ivec2 sourceSize;
    vec2 size;
    float alpha;   // GGX alpha of the added blur
    int samples;
} pc;

layout(location = 0) out vec4 outColor;

// The i-th of n points of the Hammersley set (`EnvironmentMath.hammersley`).
vec2 hammersley(int i, int n) {
    return vec2(float(i) / float(n), float(bitfieldReverse(uint(i))) * 2.3283064365386963e-10);
}

void main() {
    vec3 n = equirectDirection(gl_FragCoord.xy / pc.size);
    vec3 up = abs(n.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 tx = normalize(cross(up, n));
    vec3 ty = cross(n, tx);
    ivec4 region = ivec4(0, 0, pc.sourceSize);
    float a2 = pc.alpha * pc.alpha;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int i = 0; i < pc.samples; i++) {
        vec2 xi = hammersley(i, pc.samples);
        // GGX-distributed half vector around n.
        float phi = 2.0 * ENV_PI * xi.x;
        float cosTheta = sqrt((1.0 - xi.y) / (1.0 + (a2 - 1.0) * xi.y));
        float sinTheta = sqrt(max(1.0 - cosTheta * cosTheta, 0.0));
        vec3 h = tx * (sinTheta * cos(phi)) + ty * (sinTheta * sin(phi)) + n * cosTheta;
        vec3 l = 2.0 * dot(n, h) * h - n;
        float NoL = dot(n, l);
        if (NoL > 0.0) {
            sum += sampleEquirect(source, pointSampler, region, equirectUV(l)) * NoL;
            weight += NoL;
        }
    }
    outColor = vec4(sum / max(weight, 1e-6), 1.0);
}
