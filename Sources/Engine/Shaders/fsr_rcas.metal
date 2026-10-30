#include <metal_stdlib>
using namespace metal;

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
// With sharpness 0 it's a plain copy (used after MetalFX). Keep in sync with fsr_rcas.frag.

struct PushConstants {
    int2 origin;      // top-left of the output rectangle in the window
    int2 inputMax;    // image size - 1
    float sharpness;  // exp2(-stops); 0 disables sharpening
    float padding;
};

struct VertexOut {
    float4 position [[position]];
};

// Fullscreen triangle (FSR passes read texels by pixel position, so no UVs needed).
vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VertexOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    return out;
}

// Limits the negative lobe so the result stays away from black/white clipping.
constant float rcasLimit = 0.25 - 1.0 / 16.0;

static float3 srgbToLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

static float3 load(texture2d<float> image, int2 p, int2 inputMax) {
    return image.read(uint2(clamp(p, int2(0), inputMax))).rgb;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant PushConstants& pc [[buffer(16)]],
                              texture2d<float> image [[texture(0)]]) {
    int2 p = int2(in.position.xy) - pc.origin;
    //    b
    //  d e f
    //    h
    float3 b = load(image, p + int2(0, -1), pc.inputMax);
    float3 d = load(image, p + int2(-1, 0), pc.inputMax);
    float3 e = load(image, p, pc.inputMax);
    float3 f = load(image, p + int2(1, 0), pc.inputMax);
    float3 h = load(image, p + int2(0, 1), pc.inputMax);

    float3 mn4 = min(min(b, d), min(f, h));
    float3 mx4 = max(max(b, d), max(f, h));
    // How far the lobe can go before the ring would clip at 0 or 1. The tiny bounds on the
    // divisors avoid 0/0 on pure black/white, where the reference relies on NaN handling.
    float3 hitMin = min(mn4, e) / max(4.0 * mx4, float3(1.0 / 65536.0));
    float3 hitMax = (1.0 - max(mx4, e)) / min(4.0 * mn4 - 4.0, float3(-1.0 / 65536.0));
    float3 lobeRGB = max(-hitMin, hitMax);
    float lobe = max(-rcasLimit, min(max(lobeRGB.r, max(lobeRGB.g, lobeRGB.b)), 0.0)) * pc.sharpness;

    // Exact division (the reference approximates it, ~0.3% low even with no sharpening).
    float3 c = (lobe * b + lobe * d + lobe * h + lobe * f + e) / (4.0 * lobe + 1.0);
    return float4(srgbToLinear(clamp(c, 0.0, 1.0)), 1.0);
}
