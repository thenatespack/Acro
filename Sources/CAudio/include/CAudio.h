// The engine's audio C helpers: decoders (stb_vorbis, dr_mp3), a thin wrapper around a
// miniaudio playback device, and the few atomics the Swift mixer needs. See ../LICENSES.md.
#ifndef CAUDIO_H
#define CAUDIO_H

#include <stddef.h>
#include <stdint.h>

// Ogg Vorbis (stb_vorbis v1.22, public domain), decoding from memory only.
#define STB_VORBIS_NO_STDIO
#define STB_VORBIS_NO_PUSHDATA_API
#define STB_VORBIS_HEADER_ONLY
#include "../vendor/stb_vorbis.h"
#undef STB_VORBIS_HEADER_ONLY

// MP3 (dr_mp3 v0.7.4, public domain or MIT-0), decoding from memory only.
#define DR_MP3_NO_STDIO
#include "../vendor/dr_mp3.h"

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - Atomics
// Lock-free 64-bit loads and stores between the game thread and the audio thread (acquire /
// release ordering). Plain uint64_t storage, allocated by the Swift side.

static inline uint64_t caudio_atomic_load(const uint64_t *p) { return __atomic_load_n(p, __ATOMIC_ACQUIRE); }
static inline void caudio_atomic_store(uint64_t *p, uint64_t value) { __atomic_store_n(p, value, __ATOMIC_RELEASE); }
static inline uint64_t caudio_atomic_exchange(uint64_t *p, uint64_t value) {
    return __atomic_exchange_n(p, value, __ATOMIC_ACQ_REL);
}
/// Stores max(*p, value).
static inline void caudio_atomic_max(uint64_t *p, uint64_t value) {
    uint64_t current = __atomic_load_n(p, __ATOMIC_RELAXED);
    while (current < value && !__atomic_compare_exchange_n(p, &current, value, 1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {}
}

// MARK: - Playback device (miniaudio)

/// Fills `frames` frames of interleaved stereo float samples. Called on the device's real-time thread.
typedef void (*caudio_render_fn)(void *user, float *output, uint32_t frames);

typedef struct caudio_device caudio_device;

/// Opens the default playback device as 2-channel float32. `sample_rate` 0 uses the device's
/// native rate. Returns NULL on failure (with a message in `error`, if given). The device's
/// actual rate and name are written to `out_rate` and `name` (NUL-terminated, truncated).
caudio_device *caudio_device_open(uint32_t sample_rate, caudio_render_fn render, void *user,
                                  uint32_t *out_rate, char *name, size_t name_capacity,
                                  char *error, size_t error_capacity);
/// 0 on success.
int caudio_device_start(caudio_device *device);
void caudio_device_stop(caudio_device *device);
/// Stops (if needed) and frees the device. The render callback is not called afterwards.
void caudio_device_close(caudio_device *device);

#ifdef __cplusplus
}
#endif

#endif
