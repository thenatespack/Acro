// The single implementation of miniaudio v0.11.25 (vendored in vendor/, public domain or
// MIT-0), with everything but low-level device I/O compiled out: the engine mixes in Swift
// and only needs a callback that fills the output buffer. Used on Linux and Windows, and on
// macOS with ENGINE_AUDIO=miniaudio (the default there is AVAudioEngine). Backends (ALSA,
// PulseAudio, WASAPI, Core Audio, ...) are loaded at run time, so nothing extra is linked
// besides -ldl -lpthread -lm on Linux.
#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MA_NO_GENERATION
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE
#define MINIAUDIO_IMPLEMENTATION
#include "vendor/miniaudio.h"

#include <stdio.h>
#include <stdlib.h>
#include "include/CAudio.h"

struct caudio_device {
    ma_device device;
    caudio_render_fn render;
    void *user;
};

static void caudio_data_callback(ma_device *device, void *output, const void *input, ma_uint32 frames) {
    (void)input;
    struct caudio_device *self = (struct caudio_device *)device->pUserData;
    self->render(self->user, (float *)output, frames);
}

static void caudio_copy(char *dst, size_t capacity, const char *src) {
    if (dst == NULL || capacity == 0) return;
    snprintf(dst, capacity, "%s", src ? src : "");
}

caudio_device *caudio_device_open(uint32_t sample_rate, caudio_render_fn render, void *user,
                                  uint32_t *out_rate, char *name, size_t name_capacity,
                                  char *error, size_t error_capacity) {
    struct caudio_device *self = (struct caudio_device *)calloc(1, sizeof(struct caudio_device));
    if (self == NULL) {
        caudio_copy(error, error_capacity, "out of memory");
        return NULL;
    }
    self->render = render;
    self->user = user;
    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format = ma_format_f32;
    config.playback.channels = 2;
    config.sampleRate = sample_rate;
    config.dataCallback = caudio_data_callback;
    config.pUserData = self;
    config.noPreSilencedOutputBuffer = MA_TRUE;  // the mixer writes every sample
    config.noClip = MA_TRUE;                     // and clamps the output itself
    ma_result result = ma_device_init(NULL, &config, &self->device);
    if (result != MA_SUCCESS) {
        caudio_copy(error, error_capacity, ma_result_description(result));
        free(self);
        return NULL;
    }
    if (out_rate) *out_rate = self->device.sampleRate;
    caudio_copy(name, name_capacity, self->device.playback.name);
    return self;
}

int caudio_device_start(caudio_device *device) {
    return ma_device_start(&device->device) == MA_SUCCESS ? 0 : -1;
}

void caudio_device_stop(caudio_device *device) {
    ma_device_stop(&device->device);
}

void caudio_device_close(caudio_device *device) {
    if (device == NULL) return;
    ma_device_uninit(&device->device);
    free(device);
}
