// Block compression for the texture importer: BC7 (bc7enc / bc7decomp) and ASTC 4x4 LDR (Arm
// astc-encoder), both vendored in vendor/ (see LICENSES.md). Images are RGBA8, rows top to
// bottom, tightly packed. A compressed level is ceil(width / 4) x ceil(height / 4) blocks of 16
// bytes, row-major; edge blocks of sizes that aren't a multiple of 4 repeat the last column / row.
#ifndef CTEXTURECODEC_H
#define CTEXTURECODEC_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Encoder effort: 0 fast, 1 normal, 2 high.
typedef int tc_quality;

/// Encodes the block rows `first_block_row ..< first_block_row + block_row_count` of an RGBA8
/// image as BC7 into `blocks` (the whole level's output; only those rows are written), so
/// callers can split a level across threads. `perceptual` weights errors for color (sRGB) data;
/// 0 treats the four channels alike (normal maps, masks).
void tc_bc7_encode(const uint8_t *rgba, int width, int height, int first_block_row, int block_row_count,
                   tc_quality quality, int perceptual, uint8_t *blocks);

/// Decodes a BC7 level to RGBA8 (`width * height * 4` bytes). Returns 0 if a block is invalid
/// (it decodes as transparent black, as GPUs do).
int tc_bc7_decode(const uint8_t *blocks, int width, int height, uint8_t *rgba);

/// An ASTC 4x4 encoder for one profile and effort, usable by `thread_count` threads at once.
typedef struct tc_astc_encoder tc_astc_encoder;

/// nil if the codec can't be set up. `srgb` selects the LDR sRGB profile (color) or LDR
/// linear (data); linear data weights the channels alike.
tc_astc_encoder *tc_astc_encoder_create(int srgb, tc_quality quality, int thread_count);
void tc_astc_encoder_destroy(tc_astc_encoder *encoder);

/// Encodes one level. Call it from `thread_count` threads at once with thread indices
/// 0 ..< thread_count (or from one thread with index 0 if the encoder was made for one); they
/// share the work. Before the next level, all of them must have returned and
/// `tc_astc_encoder_reset` must be called. Returns 0 on failure.
int tc_astc_encode(tc_astc_encoder *encoder, const uint8_t *rgba, int width, int height,
                   uint8_t *blocks, size_t length, int thread_index);
void tc_astc_encoder_reset(tc_astc_encoder *encoder);

/// Decodes an ASTC 4x4 level to RGBA8 (8-bit decode mode; sRGB data stays sRGB-encoded).
/// Thread-safe. Returns 0 on failure.
int tc_astc_decode(const uint8_t *blocks, int width, int height, int srgb, uint8_t *rgba);

#ifdef __cplusplus
}
#endif

#endif
