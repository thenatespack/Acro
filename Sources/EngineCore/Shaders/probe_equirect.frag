#version 450
#extension GL_GOOGLE_include_directive : require

// Light probe baking (SceneRenderer+Probes.swift): the six capture faces of a probe (textures
// 1-6, in `LightProbeMath.faces` order: +X, -X, +Y, -Y, +Z, -Z in the probe's space, each a 90°
// view with v = 0 at the top) as one equirectangular image (environment.glsl's layout) in the
// probe's space. The faces hold c / (1 + c) (an LDR target, as the planar reflection pass
// writes), decoded here before filtering. Bilinear from texel loads, so Metal and Vulkan agree.

#include "environment.glsl"

layout(set = 2, binding = 9) uniform texture2D face0;
layout(set = 2, binding = 10) uniform texture2D face1;
layout(set = 2, binding = 11) uniform texture2D face2;
layout(set = 2, binding = 12) uniform texture2D face3;
layout(set = 2, binding = 13) uniform texture2D face4;
layout(set = 2, binding = 14) uniform texture2D face5;
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    ivec2 size;    // the output image
    int faceSize;  // the faces' width and height
} pc;

layout(location = 0) out vec4 outColor;

vec3 faceTexel(int face, ivec2 p) {
    vec3 e;
    if (face == 0) e = texelFetch(sampler2D(face0, pointSampler), p, 0).rgb;
    else if (face == 1) e = texelFetch(sampler2D(face1, pointSampler), p, 0).rgb;
    else if (face == 2) e = texelFetch(sampler2D(face2, pointSampler), p, 0).rgb;
    else if (face == 3) e = texelFetch(sampler2D(face3, pointSampler), p, 0).rgb;
    else if (face == 4) e = texelFetch(sampler2D(face4, pointSampler), p, 0).rgb;
    else e = texelFetch(sampler2D(face5, pointSampler), p, 0).rgb;
    return e / (1.0 - min(e, vec3(0.995)));
}

void main() {
    vec3 d = equirectDirection(gl_FragCoord.xy / vec2(pc.size));
    // `LightProbeMath.face(of:)`: the face d falls on and its forward and up.
    vec3 a = abs(d);
    int face;
    vec3 f, u;
    if (a.x >= a.y && a.x >= a.z) {
        face = d.x >= 0.0 ? 0 : 1;
        f = vec3(d.x >= 0.0 ? 1.0 : -1.0, 0.0, 0.0);
        u = vec3(0.0, 1.0, 0.0);
    } else if (a.y >= a.z) {
        face = d.y >= 0.0 ? 2 : 3;
        f = vec3(0.0, d.y >= 0.0 ? 1.0 : -1.0, 0.0);
        u = vec3(0.0, 0.0, d.y >= 0.0 ? 1.0 : -1.0);
    } else {
        face = d.z >= 0.0 ? 4 : 5;
        f = vec3(0.0, 0.0, d.z >= 0.0 ? 1.0 : -1.0);
        u = vec3(0.0, 1.0, 0.0);
    }
    vec3 r = cross(f, u);
    float z = dot(d, f);
    vec2 uv = vec2(0.5 + 0.5 * dot(d, r) / z, 0.5 - 0.5 * dot(d, u) / z);
    vec2 p = uv * float(pc.faceSize) - 0.5;
    vec2 fl = floor(p);
    vec2 t = p - fl;
    int last = pc.faceSize - 1;
    ivec2 p0 = clamp(ivec2(fl), ivec2(0), ivec2(last));
    ivec2 p1 = clamp(ivec2(fl) + 1, ivec2(0), ivec2(last));
    vec3 c00 = faceTexel(face, p0);
    vec3 c10 = faceTexel(face, ivec2(p1.x, p0.y));
    vec3 c01 = faceTexel(face, ivec2(p0.x, p1.y));
    vec3 c11 = faceTexel(face, p1);
    outColor = vec4(mix(mix(c00, c10, t.x), mix(c01, c11, t.x), t.y), 1.0);
}
