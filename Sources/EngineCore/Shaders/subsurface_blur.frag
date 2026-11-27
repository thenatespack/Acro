#version 450
#extension GL_GOOGLE_include_directive : require

// Separable subsurface scattering (Jimenez et al., "Separable Subsurface Scattering", 2015;
// SceneRenderer+Subsurface.swift): one 1D pass of the skin kernel over the HDR scene, run twice
// (horizontal, then vertical). Only pixels that skin materials marked take part: mesh_skin.frag
// writes -(1 + s) to their alpha, s being the luminance of their specular light, so
// diffuse = rgb - s (the specular of skin is close to white). Other pixels pass through.
//
// Per marked pixel: the kernel (`SubsurfaceKernel`: tap 0 the center, rgb weights per channel,
// offsets in profile millimeters) is stretched to the material's world radius at the pixel's
// view distance (from the depth prepass), so it shrinks with distance. A tap on an unmarked
// pixel, or on a surface at a different depth (follow-surface, as in the reference code), counts
// as the center's own diffuse light instead, so nothing bleeds in from the background, hair or
// another object. The first pass writes the blurred diffuse light and keeps the marker; the
// second adds the specular back and writes alpha 1. Texels are read with exact loads at
// rounded offsets, like the other post passes.

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sceneImage;
layout(set = 2, binding = 10) uniform texture2D depthImage;

// Must match `SubsurfaceKernel` (MaterialSkin.swift); unused taps are zero.
layout(set = 2, binding = 2, std140) uniform Kernel {
    vec4 taps[25];  // rgb: weight, a: offset in profile millimeters
} kernel;

layout(push_constant) uniform PushConstants {
    vec4 linearize;  // view distance from depth d: (x d + y) / (z d + w)
    vec4 params;     // x: pixels per meter at 1 m (the focal length in pixels), y: meters per profile mm, z: taps, w: 1 the second pass
    vec4 direction;  // xy: the pass's pixel step, z: follow-surface depth scale (1 / m)
    ivec4 maxTexel;  // xy: size - 1
} pc;

layout(location = 0) out vec4 outColor;

float viewDistance(ivec2 p) {
    float d = texelFetch(sampler2D(depthImage, pointSampler), p, 0).r;
    float w = pc.linearize.z * d + pc.linearize.w;
    float z = abs(w) < 1e-12 ? 1e6 : abs((pc.linearize.x * d + pc.linearize.y) / w);
    return clamp(z, 1e-4, 1e6);
}

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec4 center = texelFetch(sampler2D(sceneImage, pointSampler), p, 0);
    bool second = pc.params.w > 0.5;
    if (center.a > -0.5) {
        outColor = vec4(center.rgb, second ? 1.0 : center.a);
        return;
    }
    // The first pass separates the specular from the diffuse; the second reads diffuse already.
    float specular = max(-center.a - 1.0, 0.0);
    vec3 diffuse = second ? center.rgb : max(center.rgb - specular, vec3(0.0));
    float depth = viewDistance(p);
    // Pixels per profile millimeter here.
    float scale = pc.params.x * pc.params.y / depth;
    vec3 blurred = diffuse;
    if (scale * kernel.taps[1].a > 0.25 || scale * kernel.taps[1].a < -0.25) {
        blurred = diffuse * kernel.taps[0].rgb;
        int count = int(pc.params.z);
        for (int i = 1; i < count; i++) {
            vec4 tap = kernel.taps[i];
            ivec2 q = clamp(p + ivec2(round(pc.direction.xy * (tap.a * scale))), ivec2(0), pc.maxTexel.xy);
            vec4 c = texelFetch(sampler2D(sceneImage, pointSampler), q, 0);
            vec3 d = diffuse;
            if (c.a < -0.5) {
                vec3 tapDiffuse = second ? c.rgb : max(c.rgb - max(-c.a - 1.0, 0.0), vec3(0.0));
                // Follow the surface: a tap at another depth falls back to the center.
                float s = clamp(abs(viewDistance(q) - depth) * pc.direction.z, 0.0, 1.0);
                d = mix(tapDiffuse, diffuse, s);
            }
            blurred += tap.rgb * d;
        }
    }
    outColor = second ? vec4(blurred + specular, 1.0) : vec4(blurred, center.a);
}
