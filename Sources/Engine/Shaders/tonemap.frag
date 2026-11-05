#version 450
#extension GL_GOOGLE_include_directive : require

// The last post-processing pass: HDR scene (linear, RGBA16F) -> displayed image (the sRGB
// scene image the upscalers and the window pass read). Per pixel:
// 1. mix in the bloom (half resolution, bilinearly upsampled: it is smooth already) by its
//    intensity: an energy-conserving lerp, so there is no threshold and brightness is preserved;
// 2. scale by the exposure: 2^EV, times the auto exposure (exposure_adapt.frag) when enabled;
// 3. tonemap to 0...1 with the selected curve;
// 4. write linear values: the sRGB target encodes them.
// The curves mirror `PostProcessMath` (unit-tested there).

#include "post_common.glsl"

layout(set = 2, binding = 9) uniform texture2D sceneImage;
layout(set = 2, binding = 10) uniform texture2D bloomImage;     // final bloom level (half size)
layout(set = 2, binding = 11) uniform texture2D exposureImage;  // 1x1, r: auto exposure in EV

layout(push_constant) uniform PushConstants {
    float exposure;        // 2^EV
    float bloomIntensity;  // 0: no bloom
    int tonemapper;        // 0 none, 1 Reinhard, 2 neutral, 3 ACES (`Tonemapper` order)
    float autoExposure;    // 1: also scale by 2^(exposureImage.r)
    ivec2 bloomMax;        // bloom size - 1
    vec4 lift;             // rgb: color grading lift (added in the shadows); a: 1 when grading is on
    vec4 gamma;            // rgb: 1 / gamma exponent per channel
    vec4 gain;             // rgb: gain (multiplier)
    vec4 look;             // x saturation, y contrast, z vignette intensity, w vignette softness
    vec4 fx;               // x chromatic aberration, y film grain, z time (seconds), w split position (0 = off)
} pc;

layout(location = 0) out vec4 outColor;

vec3 reinhard(vec3 c) {
    return c / (1.0 + c);
}

// Khronos PBR Neutral (https://github.com/KhronosGroup/ToneMapping): hue- and
// saturation-preserving, nearly linear below 0.76 apart from a small toe.
vec3 neutral(vec3 color) {
    const float startCompression = 0.8 - 0.04;
    const float desaturation = 0.15;
    float x = min(color.r, min(color.g, color.b));
    float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
    color -= offset;
    float peak = max(color.r, max(color.g, color.b));
    if (peak < startCompression) return color;
    const float d = 1.0 - startCompression;
    float newPeak = 1.0 - d * d / (peak + d - startCompression);
    color *= newPeak / peak;
    float g = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
    return mix(color, vec3(newPeak), g);
}

// ACES filmic (RRT + ODT), Stephen Hill's fit for sRGB displays.
vec3 aces(vec3 c) {
    vec3 v = vec3(dot(vec3(0.59719, 0.35458, 0.04823), c),
                  dot(vec3(0.07600, 0.90834, 0.01566), c),
                  dot(vec3(0.02840, 0.13383, 0.83777), c));
    v = (v * (v + 0.0245786) - 0.000090537) / (v * (0.983729 * v + 0.4329510) + 0.238081);
    return vec3(dot(vec3(1.60475, -0.53108, -0.07367), v),
                dot(vec3(-0.10208, 1.10813, -0.00605), v),
                dot(vec3(-0.00327, -0.07276, 1.07602), v));
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    ivec2 size = textureSize(sampler2D(sceneImage, pointSampler), 0);
    // Before/after split preview: left of the split line shows the plain scene (neutral
    // tonemapper, no exposure or effects).
    if (pc.fx.w > 0.0) {
        float line = pc.fx.w * float(size.x);
        if (float(p.x) < line - 1.0) {
            vec3 c = texelFetch(sampler2D(sceneImage, pointSampler), p, 0).rgb;
            outColor = vec4(clamp(neutral(max(c, vec3(0.0))), 0.0, 1.0), 1.0);
            return;
        }
        if (float(p.x) < line + 1.0) {
            outColor = vec4(1.0);
            return;
        }
    }
    vec3 color = texelFetch(sampler2D(sceneImage, pointSampler), p, 0).rgb;
    vec2 uv = (vec2(p) + 0.5) / vec2(size);
    vec2 centered = uv * 2.0 - 1.0;
    centered.x *= float(size.x) / float(size.y);
    if (pc.fx.x > 0.0) {
        // Chromatic aberration: red and blue sampled radially in and out (fraction of the height).
        vec2 dir = (uv - 0.5) * vec2(size) * pc.fx.x * 0.02;
        ivec2 mx = size - 1;
        color.r = loadClamped(sceneImage, p + ivec2(round(dir)), mx).r;
        color.b = loadClamped(sceneImage, p - ivec2(round(dir)), mx).b;
    }
    if (pc.bloomIntensity > 0.0) {
        color = mix(color, bilinearUpsample(bloomImage, p, pc.bloomMax), pc.bloomIntensity);
    }
    float exposure = pc.exposure;
    if (pc.autoExposure > 0.5) {
        exposure *= exp2(texelFetch(sampler2D(exposureImage, pointSampler), ivec2(0), 0).r);
    }
    color = max(color * exposure, vec3(0.0));
    if (pc.tonemapper == 1) {
        color = reinhard(color);
    } else if (pc.tonemapper == 2) {
        color = neutral(color);
    } else if (pc.tonemapper == 3) {
        color = aces(color);
    }
    color = clamp(color, 0.0, 1.0);
    if (pc.lift.w > 0.5) {
        // Color grading on the display-referred (linear) result: contrast around middle gray,
        // lift / gamma / gain, then saturation.
        color = (color - 0.18) * pc.look.y + 0.18;
        color = max(color, vec3(0.0));
        color = pow(max(color * pc.gain.rgb + pc.lift.rgb * (1.0 - color), vec3(0.0)), pc.gamma.rgb);
        color = mix(vec3(luminance(color)), color, pc.look.x);
    }
    if (pc.look.z > 0.0) {
        float d = length(centered) * 0.7071;
        float v = smoothstep(1.0, 1.0 - max(pc.look.w, 0.01), d);
        color *= mix(1.0, v, pc.look.z);
    }
    if (pc.fx.y > 0.0) {
        float n = hash12(gl_FragCoord.xy + fract(pc.fx.z) * 1000.0) - 0.5;
        color += n * pc.fx.y * 0.25 * (1.0 - 0.5 * luminance(color));
    }
    outColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
