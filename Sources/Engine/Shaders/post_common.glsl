// Shared by the post-processing shaders (see PostProcessing.swift).
//
// Every read is a texelFetch with explicit weights (the sampler only exists to form a
// sampler2D), so no filtering hardware is involved and Metal and Vulkan produce identical
// results, like TAAU.

layout(set = 2, binding = 17) uniform sampler pointSampler;

// Rec. 709 luminance of linear RGB.
float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Texel p of `image` (size - 1 = maxTexel), clamped to the edge.
vec3 loadClamped(texture2D image, ivec2 p, ivec2 maxTexel) {
    return texelFetch(sampler2D(image, pointSampler), clamp(p, ivec2(0), maxTexel), 0).rgb;
}

// Weights of a 3x3 tent of radius one source texel, sampled bilinearly at output pixel
// `x`'s center, where the source has half the resolution (texel k covers output pixels 2k and
// 2k + 1). Along one axis that touches 4 source texels starting at `first`:
// [1, 5, 7, 3] / 16 for even x, [3, 7, 5, 1] / 16 for odd x.
void tentWeights(int x, out int first, out vec4 w) {
    int m = x >> 1;
    if ((x & 1) == 0) {
        first = m - 2;
        w = vec4(1.0, 5.0, 7.0, 3.0) / 16.0;
    } else {
        first = m - 1;
        w = vec4(3.0, 7.0, 5.0, 1.0) / 16.0;
    }
}

// The half-resolution `image` upsampled to output pixel `p` with the tent above (16 loads).
vec3 tentUpsample(texture2D image, ivec2 p, ivec2 maxTexel) {
    int fx, fy;
    vec4 wx, wy;
    tentWeights(p.x, fx, wx);
    tentWeights(p.y, fy, wy);
    vec3 sum = vec3(0.0);
    for (int j = 0; j < 4; j++) {
        vec3 row = vec3(0.0);
        for (int i = 0; i < 4; i++) {
            row += loadClamped(image, ivec2(fx + i, fy + j), maxTexel) * wx[i];
        }
        sum += row * wy[j];
    }
    return sum;
}

// The half-resolution `image` bilinearly upsampled to output pixel `p` (4 loads): weights
// 1/4 and 3/4 per axis, toward the source texel output pixel p lies in.
vec3 bilinearUpsample(texture2D image, ivec2 p, ivec2 maxTexel) {
    ivec2 m = p >> 1;
    ivec2 first = m - 1 + (p & 1);  // the left / upper texel: m - 1 for even p, m for odd p
    vec2 w = vec2(p & 1) * 0.5 + 0.25;  // weight of `first`: 1/4 (even) or 3/4 (odd)
    vec3 a = loadClamped(image, first, maxTexel);
    vec3 b = loadClamped(image, first + ivec2(1, 0), maxTexel);
    vec3 c = loadClamped(image, first + ivec2(0, 1), maxTexel);
    vec3 d = loadClamped(image, first + ivec2(1, 1), maxTexel);
    return mix(mix(b, a, w.x), mix(d, c, w.x), 1.0 - w.y);
}
