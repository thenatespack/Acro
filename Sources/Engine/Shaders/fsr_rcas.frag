#version 450

// Port of AMD FidelityFX Super Resolution 1.0 (ffx_fsr1.h), MIT license:
// Copyright (c) 2021 Advanced Micro Devices, Inc. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions: The above copyright notice
// and this permission notice shall be included in all copies or substantial portions of the
// Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
//
// RCAS (robust contrast-adaptive sharpening), FP32 path without the optional denoise.
// Reads the gamma-encoded EASU output and writes linear color for the sRGB window.
// With sharpness 0 it's a plain copy (used after MetalFX).

layout(set = 1, binding = 0) uniform sampler2D image;

layout(push_constant) uniform PushConstants {
    ivec2 origin;     // top-left of the output rectangle in the window
    ivec2 inputMax;   // image size - 1
    float sharpness;  // exp2(-stops); 0 disables sharpening
    float padding;
} pc;

layout(location = 0) out vec4 outColor;

// Limits the negative lobe so the result stays away from black/white clipping.
const float rcasLimit = 0.25 - 1.0 / 16.0;

vec3 load(ivec2 p) { return texelFetch(image, clamp(p, ivec2(0), pc.inputMax), 0).rgb; }

vec3 srgbToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy) - pc.origin;
    //    b
    //  d e f
    //    h
    vec3 b = load(p + ivec2(0, -1));
    vec3 d = load(p + ivec2(-1, 0));
    vec3 e = load(p);
    vec3 f = load(p + ivec2(1, 0));
    vec3 h = load(p + ivec2(0, 1));

    vec3 mn4 = min(min(b, d), min(f, h));
    vec3 mx4 = max(max(b, d), max(f, h));
    // How far the lobe can go before the ring would clip at 0 or 1. The tiny bounds on the
    // divisors avoid 0/0 on pure black/white, where the reference relies on NaN handling.
    vec3 hitMin = min(mn4, e) / max(4.0 * mx4, vec3(1.0 / 65536.0));
    vec3 hitMax = (1.0 - max(mx4, e)) / min(4.0 * mn4 - 4.0, vec3(-1.0 / 65536.0));
    vec3 lobeRGB = max(-hitMin, hitMax);
    float lobe = max(-rcasLimit, min(max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b)), 0.0)) * pc.sharpness;

    // Exact division (the reference approximates it, ~0.3% low even with no sharpening).
    vec3 c = (lobe * b + lobe * d + lobe * h + lobe * f + e) / (4.0 * lobe + 1.0);
    outColor = vec4(srgbToLinear(clamp(c, 0.0, 1.0)), 1.0);
}
