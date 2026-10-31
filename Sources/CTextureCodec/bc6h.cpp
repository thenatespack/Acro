// BC6H unsigned float (see include/CTextureCodec.h) with Convection Texture Tools' kernels
// (vendor/cvtt, unmodified): this file only feeds them whole half-float levels.
#include "CTextureCodec.h"

#include <algorithm>
#include <cstring>

#include "vendor/cvtt/ConvectionKernels.h"
#include "vendor/cvtt/ConvectionKernels_BC67.h"
#include "vendor/cvtt/ConvectionKernels_Util.h"

namespace {

int blocks_across(int size) { return (size + 3) / 4; }

constexpr int parallel = (int)cvtt::ParallelMath::ParallelSize;

/// The 4x4 texels of block (bx, by), repeating the last column / row past the image's edge.
/// Negative values (and NaN) become 0, which BC6H's unsigned mode can't hold anyway.
void gather_block(const uint16_t *rgba, int width, int height, int bx, int by, cvtt::PixelBlockF16 &out) {
    for (int y = 0; y < 4; y++) {
        const int sy = std::min(by * 4 + y, height - 1);
        for (int x = 0; x < 4; x++) {
            const int sx = std::min(bx * 4 + x, width - 1);
            const uint16_t *texel = rgba + ((size_t)sy * width + sx) * 4;
            for (int c = 0; c < 4; c++) {
                uint16_t h = texel[c];
                if ((h & 0x8000) || ((h & 0x7C00) == 0x7C00 && (h & 0x03FF))) h = 0;  // negative, NaN
                if (h > 0x7BFF) h = 0x7BFF;  // +infinity: the largest finite half
                out.m_pixels[y * 4 + x][c] = (int16_t)h;
            }
        }
    }
}

cvtt::Options bc6h_options(tc_quality quality) {
    cvtt::Options options;
    switch (quality) {
    case 0:  // fast
        options.flags = cvtt::Flags::Fastest;
        options.seedPoints = 1;
        options.refineRoundsBC6H = 1;
        break;
    case 2:  // high: the kernels' maximum search
        options.flags = cvtt::Flags::Better;
        options.seedPoints = 4;
        options.refineRoundsBC6H = 3;
        break;
    default:  // normal
        options.flags = cvtt::Flags::Default;
        options.seedPoints = 2;
        options.refineRoundsBC6H = 2;
        break;
    }
    return options;
}

}  // namespace

extern "C" void tc_bc6h_encode(const uint16_t *rgba_half, int width, int height, int first_block_row, int block_row_count,
                               tc_quality quality, uint8_t *blocks) {
    const cvtt::Options options = bc6h_options(quality);
    float weights[4];
    cvtt::Util::FillWeights(options, weights);
    const int across = blocks_across(width);
    const int last = std::min(first_block_row + block_row_count, blocks_across(height));
    cvtt::PixelBlockF16 inputs[parallel];
    uint8_t packed[parallel * 16];
    for (int by = first_block_row; by < last; by++) {
        for (int bx = 0; bx < across; bx += parallel) {
            const int count = std::min(parallel, across - bx);
            for (int i = 0; i < parallel; i++) {
                // A short group at the row's end repeats its last block.
                gather_block(rgba_half, width, height, bx + std::min(i, count - 1), by, inputs[i]);
            }
            cvtt::Internal::BC6HComputer::Pack(options.flags, inputs, packed, weights, false, options.seedPoints,
                                               options.refineRoundsBC6H);
            std::memcpy(blocks + ((size_t)by * across + bx) * 16, packed, (size_t)count * 16);
        }
    }
}

extern "C" void tc_bc6h_decode(const uint8_t *blocks, int width, int height, uint16_t *rgba_half) {
    const int across = blocks_across(width), down = blocks_across(height);
    cvtt::PixelBlockF16 texels;
    for (int by = 0; by < down; by++) {
        for (int bx = 0; bx < across; bx++) {
            cvtt::Internal::BC6HComputer::UnpackOne(texels, blocks + ((size_t)by * across + bx) * 16, false);
            for (int y = 0; y < 4 && by * 4 + y < height; y++) {
                for (int x = 0; x < 4 && bx * 4 + x < width; x++) {
                    uint16_t *out = rgba_half + ((size_t)(by * 4 + y) * width + bx * 4 + x) * 4;
                    for (int c = 0; c < 3; c++) out[c] = (uint16_t)texels.m_pixels[y * 4 + x][c];
                    out[3] = 0x3C00;  // 1.0
                }
            }
        }
    }
}
