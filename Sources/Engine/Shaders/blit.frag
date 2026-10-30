#version 450

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

layout(set = 1, binding = 0) uniform sampler2D image;

layout(push_constant) uniform PushConstants {
    vec2 scale;
    ivec2 origin;
    ivec2 outputSize;
    ivec2 imageSize;
} pc;

layout(location = 0) in vec2 vUV;
layout(location = 0) out vec4 outColor;

const int FOOTPRINT_CAP = 8;
const int SPARSE_TAPS = 4;

// Source texels covered by output pixel `x` along one axis (`img` texels over `out_`
// pixels, so the footprint is [x*img, (x+1)*img) in units of 1/output texel).
struct Footprint {
    int first;
    int count;
    int begin;
    int end;
    int img;
    int out_;
    bool sparse;
};

Footprint footprint(int x, int img, int out_) {
    Footprint f;
    f.img = img;
    f.out_ = out_;
    f.begin = x * img;
    f.end = f.begin + img;
    f.first = f.begin / out_;
    int last = (f.end - 1) / out_;
    f.sparse = last - f.first + 1 > FOOTPRINT_CAP;
    f.count = f.sparse ? SPARSE_TAPS : last - f.first + 1;
    return f;
}

int tex(Footprint f, int k) {
    return f.sparse ? (f.begin + ((2 * k + 1) * f.img) / (2 * SPARSE_TAPS)) / f.out_ : f.first + k;
}

// Area coverage (box) or 1 (sparse).
float weight(Footprint f, int k) {
    if (f.sparse) return 1.0;
    int i = f.first + k;
    return float(min(f.end, (i + 1) * f.out_) - max(f.begin, i * f.out_));
}

float norm(Footprint f) { return f.sparse ? float(SPARSE_TAPS) : float(f.img); }

void main() {
    if (pc.imageSize.x <= pc.outputSize.x && pc.imageSize.y <= pc.outputSize.y) {
        outColor = vec4(texture(image, vUV).rgb, 1.0);
        return;
    }
    ivec2 p = ivec2(gl_FragCoord.xy) - pc.origin;
    Footprint fx = footprint(p.x, pc.imageSize.x, pc.outputSize.x);
    Footprint fy = footprint(p.y, pc.imageSize.y, pc.outputSize.y);
    vec3 sum = vec3(0.0);
    for (int j = 0; j < fy.count; j++) {
        int y = tex(fy, j);
        vec3 row = vec3(0.0);
        for (int i = 0; i < fx.count; i++) {
            row = fma(texelFetch(image, ivec2(tex(fx, i), y), 0).rgb, vec3(weight(fx, i)), row);
        }
        sum = fma(row, vec3(weight(fy, j)), sum);
    }
    outColor = vec4(sum / (norm(fx) * norm(fy)), 1.0);
}
