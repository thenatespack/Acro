#version 450
#extension GL_GOOGLE_include_directive : require

// Environment precomputation, step 1 (see EnvironmentLighting.swift): the environment's
// radiance as the sharpest equirectangular level (roughness 0). An HDR map is read at the mip
// level matching this target's size (trilinear); the procedural sky is evaluated without the
// sun's disk, whose light the directional light already provides. Intensity and rotation are
// applied at lookup time, so changing them needs no new precomputation.

#include "environment.glsl"
#include "sky_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sourceMap;
layout(set = 2, binding = 17) uniform sampler sourceSampler;

layout(location = 0) out vec4 outColor;

void main() {
    vec2 uv = gl_FragCoord.xy / skyData.extra.zw;
    vec3 color;
    if (skyData.params.x > 0.5) {
        // Clamped below the half-float maximum (a sun in an HDR file can exceed it).
        color = min(textureLod(sampler2D(sourceMap, sourceSampler), uv, skyData.extra.y).rgb, vec3(60000.0));
    } else {
        color = proceduralSky(skyParameters(), equirectDirection(uv), false);
    }
    outColor = vec4(max(color, vec3(0.0)), 1.0);
}
