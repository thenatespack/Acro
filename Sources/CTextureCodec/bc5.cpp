// BC5 (two BC4 blocks: red, then green) encoder and decoder, written for the engine (not
// vendored). A BC4 block is two 8-bit endpoints and sixteen 3-bit indices into a palette:
// e0 > e1 gives e0, e1 and six values between them; e0 <= e1 gives e0, e1, four values between
// them, 0 and 255.
//
// The encoder starts from the block's range (and, when it holds 0 or 255, the six-value mode
// over the values between them), refines the eight-value endpoints by least squares from the
// chosen indices, then (normal / high quality) searches the endpoints around the best pair.
// Integer arithmetic only, so the output is the same on every machine.
#include "CTextureCodec.h"

#include <algorithm>
#include <climits>
#include <cmath>
#include <cstring>

namespace {

int blocks_across(int size) { return (size + 3) / 4; }

int clamp255(int v) { return v < 0 ? 0 : v > 255 ? 255 : v; }

/// The block's palette (rounded to 8 bits, as the decoder returns it).
void bc4_palette(int e0, int e1, int p[8]) {
    p[0] = e0;
    p[1] = e1;
    if (e0 > e1) {
        for (int i = 1; i < 7; i++) p[i + 1] = ((7 - i) * e0 + i * e1 + 3) / 7;
    } else {
        for (int i = 1; i < 5; i++) p[i + 1] = ((5 - i) * e0 + i * e1 + 2) / 5;
        p[6] = 0;
        p[7] = 255;
    }
}

/// Squared error of the best index per texel (written to `indices` when not null).
int bc4_error(const uint8_t v[16], int e0, int e1, uint8_t *indices) {
    int p[8];
    bc4_palette(e0, e1, p);
    int total = 0;
    for (int t = 0; t < 16; t++) {
        int best = INT_MAX, bestIndex = 0;
        for (int k = 0; k < 8; k++) {
            const int d = (int)v[t] - p[k];
            if (d * d < best) {
                best = d * d;
                bestIndex = k;
            }
        }
        total += best;
        if (indices) indices[t] = (uint8_t)bestIndex;
    }
    return total;
}

struct Candidate {
    int e0, e1, error;
};

void consider(const uint8_t v[16], int e0, int e1, Candidate &best) {
    e0 = clamp255(e0);
    e1 = clamp255(e1);
    const int error = bc4_error(v, e0, e1, nullptr);
    if (error < best.error) best = {e0, e1, error};
}

/// Eight-value endpoints fitted by least squares to the indices `e0`, `e1` pick, with e0 > e1.
void least_squares(const uint8_t v[16], Candidate &best) {
    if (best.e0 <= best.e1) return;
    uint8_t indices[16];
    bc4_error(v, best.e0, best.e1, indices);
    // Value = e0 (1 - w) + e1 w, w = 0 for index 0, 1 for index 1, (k - 1) / 7 for the others.
    double aa = 0, ab = 0, bb = 0, av = 0, bv = 0;
    for (int t = 0; t < 16; t++) {
        const int k = indices[t];
        const double w = k == 0 ? 0 : k == 1 ? 1 : (k - 1) / 7.0;
        const double a = 1 - w, b = w;
        aa += a * a;
        ab += a * b;
        bb += b * b;
        av += a * v[t];
        bv += b * v[t];
    }
    const double det = aa * bb - ab * ab;
    if (std::fabs(det) < 1e-9) return;
    int e0 = (int)std::lround((av * bb - bv * ab) / det);
    int e1 = (int)std::lround((bv * aa - av * ab) / det);
    e0 = clamp255(e0);
    e1 = clamp255(e1);
    if (e0 <= e1) return;
    consider(v, e0, e1, best);
}

/// One BC4 block (8 bytes) for 16 values.
void bc4_encode_block(const uint8_t v[16], tc_quality quality, uint8_t out[8]) {
    int lo = 255, hi = 0, innerLo = 255, innerHi = 0;
    bool extremes = false;
    for (int t = 0; t < 16; t++) {
        lo = std::min(lo, (int)v[t]);
        hi = std::max(hi, (int)v[t]);
        if (v[t] == 0 || v[t] == 255) {
            extremes = true;
        } else {
            innerLo = std::min(innerLo, (int)v[t]);
            innerHi = std::max(innerHi, (int)v[t]);
        }
    }
    Candidate best{lo, hi, INT_MAX};  // e0 <= e1: exact for a flat block
    if (lo == hi) {
        best.error = 0;
    } else {
        consider(v, hi, lo, best);
        consider(v, lo, hi, best);
        if (extremes && innerLo <= innerHi) consider(v, innerLo, innerHi, best);
        if (quality > 0 && best.error > 0) {
            for (int pass = 0; pass < 2; pass++) least_squares(v, best);
            // Search the eight-value endpoints around the best pair.
            const int radius = quality >= 2 ? 3 : 1;
            if (best.e0 > best.e1) {
                const Candidate center = best;
                for (int d0 = -radius; d0 <= radius; d0++) {
                    for (int d1 = -radius; d1 <= radius; d1++) {
                        const int e0 = center.e0 + d0, e1 = center.e1 + d1;
                        if (e0 > e1 && e0 <= 255 && e1 >= 0) consider(v, e0, e1, best);
                    }
                }
            }
        }
    }
    uint8_t indices[16];
    bc4_error(v, best.e0, best.e1, indices);
    out[0] = (uint8_t)best.e0;
    out[1] = (uint8_t)best.e1;
    uint64_t bits = 0;
    for (int t = 0; t < 16; t++) bits |= (uint64_t)indices[t] << (3 * t);
    for (int i = 0; i < 6; i++) out[2 + i] = (uint8_t)(bits >> (8 * i));
}

void bc4_decode_block(const uint8_t in[8], uint8_t v[16]) {
    int p[8];
    bc4_palette(in[0], in[1], p);
    uint64_t bits = 0;
    for (int i = 0; i < 6; i++) bits |= (uint64_t)in[2 + i] << (8 * i);
    for (int t = 0; t < 16; t++) v[t] = (uint8_t)p[(bits >> (3 * t)) & 7];
}

}  // namespace

extern "C" void tc_bc5_encode(const uint8_t *rgba, int width, int height, int first_block_row, int block_row_count,
                              tc_quality quality, uint8_t *blocks) {
    const int across = blocks_across(width);
    const int last = std::min(first_block_row + block_row_count, blocks_across(height));
    uint8_t red[16], green[16];
    for (int by = first_block_row; by < last; by++) {
        for (int bx = 0; bx < across; bx++) {
            // Texels past the edge repeat the last column / row.
            for (int y = 0; y < 4; y++) {
                const int sy = std::min(by * 4 + y, height - 1);
                for (int x = 0; x < 4; x++) {
                    const int sx = std::min(bx * 4 + x, width - 1);
                    const uint8_t *texel = rgba + ((size_t)sy * width + sx) * 4;
                    red[y * 4 + x] = texel[0];
                    green[y * 4 + x] = texel[1];
                }
            }
            uint8_t *out = blocks + ((size_t)by * across + bx) * 16;
            bc4_encode_block(red, quality, out);
            bc4_encode_block(green, quality, out + 8);
        }
    }
}

extern "C" void tc_bc5_decode(const uint8_t *blocks, int width, int height, uint8_t *rgba) {
    const int across = blocks_across(width), down = blocks_across(height);
    uint8_t red[16], green[16];
    for (int by = 0; by < down; by++) {
        for (int bx = 0; bx < across; bx++) {
            const uint8_t *block = blocks + ((size_t)by * across + bx) * 16;
            bc4_decode_block(block, red);
            bc4_decode_block(block + 8, green);
            for (int y = 0; y < 4 && by * 4 + y < height; y++) {
                for (int x = 0; x < 4 && bx * 4 + x < width; x++) {
                    uint8_t *texel = rgba + ((size_t)(by * 4 + y) * width + bx * 4 + x) * 4;
                    texel[0] = red[y * 4 + x];
                    texel[1] = green[y * 4 + x];
                    texel[2] = 0;
                    texel[3] = 255;
                }
            }
        }
    }
}
