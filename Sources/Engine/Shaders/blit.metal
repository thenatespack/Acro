#include <metal_stdlib>
using namespace metal;

// Draws the offscreen scene image into the window, letterboxed to keep its aspect ratio.
//
// Upscaling (image no larger than the window rectangle): one hardware bilinear tap.
//
// Downscaling: a single bilinear tap per output pixel skips most of the source and shimmers
// as the image or camera moves, so the window pass box-filters instead: each output pixel
// averages the source texels under its footprint, weighted by exact area coverage. This is a
// single pass that reads the 8K/16K scene image once, like the old blit (a mip chain would
// need an extra pass that rewrites and rereads ~a third more memory, and mip selection and
// generation filters differ between APIs). The footprint is ceil(scale)+1 texels per axis;
// beyond FOOTPRINT_CAP texels per axis (scale > ~7, e.g. 16K into 1440p) it takes
// SPARSE_TAPS equally weighted taps spread over the footprint (stratified, so still far
// less aliasing than one tap). Cost is bound by texel loads (point loads don't get the
// bilinear unit's 4 texels per tap), so this caps it at 64 loads per pixel in the exact
// case and 16 in the sparse one. Hardware bilinear taps at texel corners could cut the
// count 4x, but their weight precision is implementation-defined, so we don't use them.
//
// Byte-identical on Metal and Vulkan: texels are loaded directly (the scene image is sRGB,
// so loads decode to linear light, and the average is taken in linear light, then written
// to the sRGB window), footprints and weights are exact integers, and the sum uses explicit
// fma in a fixed order. Keep in sync with blit.frag / blit.metal.

constant int FOOTPRINT_CAP = 8;
constant int SPARSE_TAPS = 4;

struct PushConstants {
    float2 scale;      // clip-space letterbox scale (≤ 1 per axis)
    int2 origin;       // top-left of the output rectangle in the window
    int2 outputSize;   // output rectangle size in pixels
    int2 imageSize;    // scene image size in texels
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]], constant PushConstants& pc [[buffer(16)]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VertexOut out;
    out.position = float4((p * 2.0 - 1.0) * pc.scale, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

// Source texels covered by output pixel `x` along one axis (`image` texels over `output`
// pixels, so the footprint is [x*image, (x+1)*image) in units of 1/output texel).
struct Footprint {
    int first;   // first texel
    int count;   // taps
    int begin;   // footprint start, in 1/output units
    int end;
    int image;
    int output;
    bool sparse;
    int tex(int k) const {
        return sparse ? (begin + ((2 * k + 1) * image) / (2 * SPARSE_TAPS)) / output : first + k;
    }
    // Area coverage (box) or 1 (sparse).
    float weight(int k) const {
        if (sparse) return 1.0;
        int i = first + k;
        return float(min(end, (i + 1) * output) - max(begin, i * output));
    }
    float norm() const { return sparse ? float(SPARSE_TAPS) : float(image); }
};

static Footprint footprint(int x, int image, int output) {
    Footprint f;
    f.image = image;
    f.output = output;
    f.begin = x * image;
    f.end = f.begin + image;
    f.first = f.begin / output;
    int last = (f.end - 1) / output;
    f.sparse = last - f.first + 1 > FOOTPRINT_CAP;
    f.count = f.sparse ? SPARSE_TAPS : last - f.first + 1;
    return f;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant PushConstants& pc [[buffer(16)]],
                              texture2d<float> image [[texture(0)]], sampler imageSampler [[sampler(0)]]) {
    if (pc.imageSize.x <= pc.outputSize.x && pc.imageSize.y <= pc.outputSize.y) {
        return float4(image.sample(imageSampler, in.uv).rgb, 1.0);
    }
    int2 p = int2(in.position.xy) - pc.origin;
    Footprint fx = footprint(p.x, pc.imageSize.x, pc.outputSize.x);
    Footprint fy = footprint(p.y, pc.imageSize.y, pc.outputSize.y);
    float3 sum = float3(0.0);
    #pragma clang loop unroll(full)
    for (int j = 0; j < FOOTPRINT_CAP; j++) {
        if (j >= fy.count) break;
        int y = fy.tex(j);
        float3 row = float3(0.0);
        #pragma clang loop unroll(full)
        for (int i = 0; i < FOOTPRINT_CAP; i++) {
            if (i >= fx.count) break;
            row = fma(image.read(uint2(fx.tex(i), y)).rgb, float3(fx.weight(i)), row);
        }
        sum = fma(row, float3(fy.weight(j)), sum);
    }
    return float4(sum / (fx.norm() * fy.norm()), 1.0);
}
