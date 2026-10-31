// The engine's side of the vendored block codecs (see include/CTextureCodec.h). bc7enc.c,
// bc7decomp.cpp and the astc-encoder library sources in vendor/ are compiled as they are; this
// file only adapts their APIs to whole RGBA8 (and, for ASTC HDR, half-float) levels. BC6H is in
// bc6h.cpp.
#include "CTextureCodec.h"

#include <algorithm>
#include <cstring>
#include <mutex>

#include "vendor/bc7enc/bc7enc.h"
#include "vendor/bc7enc/bc7decomp.h"
#include "vendor/astcenc/astcenc.h"

namespace {

int blocks_across(int size) { return (size + 3) / 4; }

/// Copies the 4x4 texels of block (bx, by) into `out` (RGBA8), repeating the last column / row
/// past the image's edge.
void gather_block(const uint8_t *rgba, int width, int height, int bx, int by, uint8_t out[64]) {
    for (int y = 0; y < 4; y++) {
        int sy = std::min(by * 4 + y, height - 1);
        for (int x = 0; x < 4; x++) {
            int sx = std::min(bx * 4 + x, width - 1);
            std::memcpy(out + (y * 4 + x) * 4, rgba + ((size_t)sy * width + sx) * 4, 4);
        }
    }
}

std::once_flag bc7_init_once;

bc7enc_compress_block_params bc7_params(tc_quality quality, int perceptual) {
    bc7enc_compress_block_params params;
    bc7enc_compress_block_params_init(&params);
    if (!perceptual) bc7enc_compress_block_params_init_linear_weights(&params);
    switch (quality) {
    case 0:  // fast: fewer mode 1 partitions, no least-squares refinement
        params.m_max_partitions_mode = 16;
        params.m_try_least_squares = BC7ENC_FALSE;
        params.m_uber_level = 0;
        break;
    case 2:  // high
        params.m_mode_partition_estimation_filterbank = BC7ENC_FALSE;
        params.m_uber_level = 2;
        break;
    default:  // normal: bc7enc's defaults with one uber level
        params.m_uber_level = 1;
        break;
    }
    return params;
}

astcenc_swizzle identity_swizzle() {
    return astcenc_swizzle{ASTCENC_SWZ_R, ASTCENC_SWZ_G, ASTCENC_SWZ_B, ASTCENC_SWZ_A};
}

float astc_effort(tc_quality quality) {
    switch (quality) {
    case 0: return ASTCENC_PRE_FAST;
    case 2: return ASTCENC_PRE_THOROUGH;
    default: return ASTCENC_PRE_MEDIUM;
    }
}

/// Decompress-only contexts, one per profile (LDR, LDR sRGB, HDR), shared under a lock.
struct AstcDecoder {
    std::mutex lock;
    astcenc_context *context = nullptr;
    bool failed = false;
};
AstcDecoder astc_decoders[3];

/// Decodes a level into `pixels` (`type` texels) with decoder `index` of `astc_decoders`.
bool astc_decode(int index, astcenc_profile profile, const uint8_t *blocks, int width, int height, astcenc_type type,
                 void *pixels) {
    AstcDecoder &decoder = astc_decoders[index];
    std::lock_guard<std::mutex> guard(decoder.lock);
    if (!decoder.context && !decoder.failed) {
        astcenc_config config;
        decoder.failed = astcenc_config_init(profile, 4, 4, 1, ASTCENC_PRE_FAST, ASTCENC_FLG_DECOMPRESS_ONLY, &config)
                != ASTCENC_SUCCESS
            || astcenc_context_alloc(&config, 1, &decoder.context, nullptr) != ASTCENC_SUCCESS;
    }
    if (decoder.failed) return false;
    void *slice = pixels;
    astcenc_image image{(unsigned)width, (unsigned)height, 1, type, &slice};
    const astcenc_swizzle swizzle{ASTCENC_SWZ_R, ASTCENC_SWZ_G, ASTCENC_SWZ_B, ASTCENC_SWZ_A};
    const size_t length = (size_t)((width + 3) / 4) * ((height + 3) / 4) * 16;
    const bool ok = astcenc_decompress_image(decoder.context, blocks, length, &image, &swizzle, 0) == ASTCENC_SUCCESS;
    astcenc_decompress_reset(decoder.context);
    return ok;
}

}  // namespace

extern "C" void tc_bc7_encode(const uint8_t *rgba, int width, int height, int first_block_row, int block_row_count,
                              tc_quality quality, int perceptual, uint8_t *blocks) {
    std::call_once(bc7_init_once, [] { bc7enc_compress_block_init(); });
    const bc7enc_compress_block_params params = bc7_params(quality, perceptual);
    const int across = blocks_across(width);
    const int last = std::min(first_block_row + block_row_count, blocks_across(height));
    uint8_t texels[64];
    for (int by = first_block_row; by < last; by++) {
        for (int bx = 0; bx < across; bx++) {
            gather_block(rgba, width, height, bx, by, texels);
            bc7enc_compress_block(blocks + ((size_t)by * across + bx) * 16, texels, &params);
        }
    }
}

extern "C" int tc_bc7_decode(const uint8_t *blocks, int width, int height, uint8_t *rgba) {
    const int across = blocks_across(width), down = blocks_across(height);
    int ok = 1;
    bc7decomp::color_rgba texels[16];
    for (int by = 0; by < down; by++) {
        for (int bx = 0; bx < across; bx++) {
            if (!bc7decomp::unpack_bc7(blocks + ((size_t)by * across + bx) * 16, texels)) {
                std::memset(texels, 0, sizeof(texels));
                ok = 0;
            }
            for (int y = 0; y < 4 && by * 4 + y < height; y++) {
                for (int x = 0; x < 4 && bx * 4 + x < width; x++) {
                    std::memcpy(rgba + ((size_t)(by * 4 + y) * width + bx * 4 + x) * 4, texels[y * 4 + x].m_comps, 4);
                }
            }
        }
    }
    return ok;
}

struct tc_astc_encoder {
    astcenc_context *context;
    astcenc_swizzle swizzle;
};

namespace {

tc_astc_encoder *make_astc_encoder(astcenc_profile profile, unsigned flags, tc_quality quality, int thread_count,
                                   astcenc_swizzle swizzle) {
    astcenc_config config;
    if (astcenc_config_init(profile, 4, 4, 1, astc_effort(quality), flags, &config)
        != ASTCENC_SUCCESS) {
        return nullptr;
    }
    astcenc_context *context = nullptr;
    if (astcenc_context_alloc(&config, (unsigned)std::max(thread_count, 1), &context, nullptr) != ASTCENC_SUCCESS) {
        return nullptr;
    }
    return new tc_astc_encoder{context, swizzle};
}

}  // namespace

extern "C" tc_astc_encoder *tc_astc_encoder_create(int srgb, tc_quality quality, int thread_count) {
    return make_astc_encoder(srgb ? ASTCENC_PRF_LDR_SRGB : ASTCENC_PRF_LDR, srgb ? ASTCENC_FLG_USE_PERCEPTUAL : 0, quality,
                             thread_count, identity_swizzle());
}

extern "C" tc_astc_encoder *tc_astc_encoder_create_rg(tc_quality quality, int thread_count) {
    const astcenc_swizzle rrrg{ASTCENC_SWZ_R, ASTCENC_SWZ_R, ASTCENC_SWZ_R, ASTCENC_SWZ_G};
    return make_astc_encoder(ASTCENC_PRF_LDR, ASTCENC_FLG_MAP_NORMAL, quality, thread_count, rrrg);
}

extern "C" tc_astc_encoder *tc_astc_encoder_create_hdr(tc_quality quality, int thread_count) {
    // HDR color with LDR alpha: environment maps are opaque, and an LDR alpha leaves the
    // endpoint bits to the color.
    return make_astc_encoder(ASTCENC_PRF_HDR_RGB_LDR_A, 0, quality, thread_count, identity_swizzle());
}

extern "C" void tc_astc_encoder_destroy(tc_astc_encoder *encoder) {
    if (!encoder) return;
    astcenc_context_free(encoder->context);
    delete encoder;
}

extern "C" int tc_astc_encode(tc_astc_encoder *encoder, const uint8_t *rgba, int width, int height,
                              uint8_t *blocks, size_t length, int thread_index) {
    void *slice = const_cast<uint8_t *>(rgba);
    astcenc_image image{(unsigned)width, (unsigned)height, 1, ASTCENC_TYPE_U8, &slice};
    return astcenc_compress_image(encoder->context, &image, &encoder->swizzle, blocks, length, (unsigned)thread_index)
        == ASTCENC_SUCCESS;
}

extern "C" void tc_astc_encoder_reset(tc_astc_encoder *encoder) {
    astcenc_compress_reset(encoder->context);
}

extern "C" int tc_astc_encode_hdr(tc_astc_encoder *encoder, const uint16_t *rgba_half, int width, int height,
                                  uint8_t *blocks, size_t length, int thread_index) {
    void *slice = const_cast<uint16_t *>(rgba_half);
    astcenc_image image{(unsigned)width, (unsigned)height, 1, ASTCENC_TYPE_F16, &slice};
    return astcenc_compress_image(encoder->context, &image, &encoder->swizzle, blocks, length, (unsigned)thread_index)
        == ASTCENC_SUCCESS;
}

extern "C" int tc_astc_decode(const uint8_t *blocks, int width, int height, int srgb, uint8_t *rgba) {
    return astc_decode(srgb ? 1 : 0, srgb ? ASTCENC_PRF_LDR_SRGB : ASTCENC_PRF_LDR, blocks, width, height, ASTCENC_TYPE_U8,
                       rgba);
}

extern "C" int tc_astc_decode_hdr(const uint8_t *blocks, int width, int height, uint16_t *rgba_half) {
    return astc_decode(2, ASTCENC_PRF_HDR, blocks, width, height, ASTCENC_TYPE_F16, rgba_half);
}
