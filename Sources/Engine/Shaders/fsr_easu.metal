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
// EASU (edge-adaptive spatial upsampling), FP32 path. Loads the 12 taps with clamped
// reads instead of gathers, so both backends read exactly the same texels.
// Input and output are gamma-encoded (sRGB values read through a UNORM view).
// Keep in sync with fsr_easu.frag.

struct PushConstants {
    float2 scale;     // input size / output size
    int2 inputMax;    // input size - 1
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

static float rcpLo(float a) { return as_type<float>(0x7ef07ebbu - as_type<uint>(a)); }
static float rsqLo(float a) { return as_type<float>(0x5f347d74u - (as_type<uint>(a) >> 1)); }

// Luma times 2.
static float luma(float3 c) { return c.b * 0.5 + (c.r * 0.5 + c.g); }

// Accumulates edge direction and length from a '+' of lumas around c (weighted bilinearly).
static void easuSet(thread float2& dir, thread float& len, float w, float lA, float lB, float lC, float lD, float lE) {
    float dc = lD - lC;
    float cb = lC - lB;
    float lenX = rcpLo(max(abs(dc), abs(cb)));
    float dirX = lD - lB;
    dir.x += dirX * w;
    lenX = clamp(abs(dirX) * lenX, 0.0, 1.0);
    lenX *= lenX;
    len += lenX * w;

    float ec = lE - lC;
    float ca = lC - lA;
    float lenY = rcpLo(max(abs(ec), abs(ca)));
    float dirY = lE - lA;
    dir.y += dirY * w;
    lenY = clamp(abs(dirY) * lenY, 0.0, 1.0);
    lenY *= lenY;
    len += lenY * w;
}

// One tap of the rotated, anisotropic Lanczos-2 approximation.
static void easuTap(thread float3& aC, thread float& aW, float2 off, float2 dir, float2 len, float lob, float clp, float3 c) {
    float2 v;
    v.x = off.x * dir.x + off.y * dir.y;
    v.y = off.x * -dir.y + off.y * dir.x;
    v *= len;
    float d2 = min(v.x * v.x + v.y * v.y, clp);
    float wB = 2.0 / 5.0 * d2 - 1.0;
    float wA = lob * d2 - 1.0;
    wB *= wB;
    wA *= wA;
    wB = 25.0 / 16.0 * wB - (25.0 / 16.0 - 1.0);
    float w = wB * wA;
    aC += c * w;
    aW += w;
}

static float3 load(texture2d<float> image, int2 p, int2 inputMax) {
    return image.read(uint2(clamp(p, int2(0), inputMax))).rgb;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant PushConstants& pc [[buffer(16)]],
                              texture2d<float> image [[texture(0)]]) {
    // Input position of this output pixel's center, split into texel f and fraction pp.
    float2 pp = in.position.xy * pc.scale - 0.5;
    float2 fp = floor(pp);
    pp -= fp;
    int2 p = int2(fp);

    //    b c
    //  e f g h
    //  i j k l
    //    n o
    float3 b = load(image, p + int2(0, -1), pc.inputMax), c = load(image, p + int2(1, -1), pc.inputMax);
    float3 e = load(image, p + int2(-1, 0), pc.inputMax), f = load(image, p, pc.inputMax), g = load(image, p + int2(1, 0), pc.inputMax), h = load(image, p + int2(2, 0), pc.inputMax);
    float3 i = load(image, p + int2(-1, 1), pc.inputMax), j = load(image, p + int2(0, 1), pc.inputMax), k = load(image, p + int2(1, 1), pc.inputMax), l = load(image, p + int2(2, 1), pc.inputMax);
    float3 n = load(image, p + int2(0, 2), pc.inputMax), o = load(image, p + int2(1, 2), pc.inputMax);
    float bL = luma(b), cL = luma(c), eL = luma(e), fL = luma(f), gL = luma(g), hL = luma(h);
    float iL = luma(i), jL = luma(j), kL = luma(k), lL = luma(l), nL = luma(n), oL = luma(o);

    float2 dir = float2(0.0);
    float len = 0.0;
    easuSet(dir, len, (1.0 - pp.x) * (1.0 - pp.y), bL, eL, fL, gL, jL);
    easuSet(dir, len, pp.x * (1.0 - pp.y), cL, fL, gL, hL, kL);
    easuSet(dir, len, (1.0 - pp.x) * pp.y, fL, iL, jL, kL, nL);
    easuSet(dir, len, pp.x * pp.y, gL, jL, kL, lL, oL);

    // Normalize the direction (approximately), falling back to horizontal when flat.
    float2 dir2 = dir * dir;
    float dirR = dir2.x + dir2.y;
    bool zro = dirR < 1.0 / 32768.0;
    dirR = zro ? 1.0 : rsqLo(dirR);
    dir.x = zro ? 1.0 : dir.x;
    dir *= dirR;
    // {0..2} → {0..1}, shaped.
    len = len * 0.5;
    len *= len;
    // Stretch the kernel along edges, more on diagonals.
    float stretch = (dir.x * dir.x + dir.y * dir.y) * rcpLo(max(abs(dir.x), abs(dir.y)));
    float2 len2 = float2(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
    // The negative lobe and window grow with the amount of edge.
    float lob = 0.5 + ((1.0 / 4.0 - 0.04) - 0.5) * len;
    float clp = rcpLo(lob);

    float3 aC = float3(0.0);
    float aW = 0.0;
    easuTap(aC, aW, float2(0.0, -1.0) - pp, dir, len2, lob, clp, b);
    easuTap(aC, aW, float2(1.0, -1.0) - pp, dir, len2, lob, clp, c);
    easuTap(aC, aW, float2(-1.0, 1.0) - pp, dir, len2, lob, clp, i);
    easuTap(aC, aW, float2(0.0, 1.0) - pp, dir, len2, lob, clp, j);
    easuTap(aC, aW, float2(0.0, 0.0) - pp, dir, len2, lob, clp, f);
    easuTap(aC, aW, float2(-1.0, 0.0) - pp, dir, len2, lob, clp, e);
    easuTap(aC, aW, float2(1.0, 1.0) - pp, dir, len2, lob, clp, k);
    easuTap(aC, aW, float2(2.0, 1.0) - pp, dir, len2, lob, clp, l);
    easuTap(aC, aW, float2(2.0, 0.0) - pp, dir, len2, lob, clp, h);
    easuTap(aC, aW, float2(1.0, 0.0) - pp, dir, len2, lob, clp, g);
    easuTap(aC, aW, float2(1.0, 2.0) - pp, dir, len2, lob, clp, o);
    easuTap(aC, aW, float2(0.0, 2.0) - pp, dir, len2, lob, clp, n);

    // Normalize and dering against the 4 nearest texels.
    float3 min4 = min(min(f, g), min(j, k));
    float3 max4 = max(max(f, g), max(j, k));
    return float4(min(max4, max(min4, aC * (1.0 / aW))), 1.0);
}
