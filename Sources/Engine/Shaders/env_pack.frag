#version 450

// Environment precomputation, last step (see EnvironmentLighting.swift): copies one level (or
// the SH row) into its region of the environment atlas. One draw per region, scissored to it.

layout(set = 2, binding = 9) uniform texture2D source;
layout(set = 2, binding = 17) uniform sampler pointSampler;

layout(push_constant) uniform PushConstants {
    ivec2 origin;  // the region's top-left texel in the atlas
} pc;

layout(location = 0) out vec4 outColor;

void main() {
    outColor = texelFetch(sampler2D(source, pointSampler), ivec2(gl_FragCoord.xy) - pc.origin, 0);
}
