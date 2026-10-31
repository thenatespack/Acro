#version 450
#extension GL_GOOGLE_include_directive : require

// The sky: an equirectangular HDR map (trilinear, with the UV gradients fixed across the
// horizontal wrap so the seam doesn't drop to the smallest mip) or the procedural sky with the
// sun's disk, times the environment's intensity. Not fogged. Writes the motion of directions at
// infinity, so temporal upscalers reproject it as the camera turns.

#include "environment.glsl"
#include "sky_common.glsl"

// The prefix of `SceneRenderer.FrameUniforms` this shader reads.
layout(set = 0, binding = 0, std140) uniform Frame {
    mat4 viewProj;
    mat4 lightViewProj;
    mat4 currentViewProj;
    mat4 previousViewProj;
} frame;

layout(set = 2, binding = 9) uniform texture2D skyMap;
layout(set = 2, binding = 17) uniform sampler skySampler;

layout(location = 0) in vec4 vRay;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMotion;  // see `PipelineDescriptor.writesMotionVectors`

void main() {
    vec3 d = normalize(vRay.xyz / vRay.w);
    vec3 color;
    if (skyData.params.x > 0.5) {
        vec2 uv = equirectUV(environmentDirection(d, skyData.params.zw));
        vec2 dx = dFdx(uv), dy = dFdy(uv);
        dx.x -= round(dx.x);
        dy.x -= round(dy.x);
        color = textureGrad(sampler2D(skyMap, skySampler), uv, dx, dy).rgb;
    } else {
        color = proceduralSky(skyParameters(), d, true);
    }
    outColor = vec4(color * skyData.params.y, 1.0);

    vec4 current = frame.currentViewProj * vec4(d, 0.0);
    vec4 previous = frame.previousViewProj * vec4(d, 0.0);
    outMotion = (previous.w <= 0.0 || current.w <= 0.0)
        ? vec2(0.0) : (previous.xy / previous.w - current.xy / current.w) * vec2(0.5, -0.5);
}
