// Rewrites one SPIR-V module (already through `spirv-opt --split-combined-image-sampler
// --resolve-binding-conflicts`) into a form naga can translate to WGSL for the WebGPU backend.
// Built and run by Scripts/compile-shaders.sh; no dependencies.
//
//   spirv-wgsl-prep <in.spv> <out.spv>
//   spirv-wgsl-prep --header <original.spv> <GLSL source path>   (prints the .wgsl header)
//
// - Push constants become a uniform buffer at set 3, binding 0 (WebGPU has no push constants;
//   see the table in ShaderSource). The block keeps its offsets, so WGSL's uniform layout rules
//   apply to it: naga rejects a push-constant block that breaks them.
// - `writeonly` storage buffers become read-write (WGSL storage buffers are `read` or
//   `read_write`; naga rejects write-only ones). Write-only storage images keep it.
// - A global OpVariable placed before its pointer type (spirv-opt's split pass reuses an existing
//   sampler pointer type declared later in the module) is moved after it.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
    OpTypeVoid = 19, OpTypeForwardPointer = 39, OpTypePointer = 32, OpVariable = 59, OpDecorate = 71,
    OpMemberDecorate = 72, DecorationNonReadable = 25, DecorationBinding = 33, DecorationDescriptorSet = 34,
    StorageUniform = 2, StoragePushConstant = 9, StorageStorageBuffer = 12, OpFunction = 54,
};

static _Noreturn void fail(const char *message, const char *detail) {
    fprintf(stderr, "spirv-wgsl-prep: %s%s%s\n", message, detail ? ": " : "", detail ? detail : "");
    exit(1);
}

typedef struct { uint32_t *words; size_t count, capacity; } Words;

static void append(Words *out, const uint32_t *words, size_t count) {
    if (out->count + count > out->capacity) {
        out->capacity = (out->count + count) * 2;
        out->words = realloc(out->words, out->capacity * sizeof(uint32_t));
        if (!out->words) fail("out of memory", NULL);
    }
    memcpy(out->words + out->count, words, count * sizeof(uint32_t));
    out->count += count;
}

// FNV-1a 64 of a file, as in spirv-to-msl.c: recorded in the header so tests can tell stale
// output. `text` skips '\r' (a CRLF checkout of the GLSL hashes the same).
static uint64_t hashFile(const char *path, int text) {
    FILE *file = fopen(path, "rb");
    if (!file) fail("cannot open", path);
    uint64_t hash = 0xcbf29ce484222325ull;
    int c;
    while ((c = fgetc(file)) != EOF) {
        if (text && c == '\r') continue;
        hash ^= (unsigned char)c;
        hash *= 0x100000001b3ull;
    }
    fclose(file);
    return hash;
}

int main(int argc, char **argv) {
    if (argc == 4 && strcmp(argv[1], "--header") == 0) {
        const char *sourceName = strrchr(argv[3], '/') ? strrchr(argv[3], '/') + 1 : argv[3];
        printf("// Generated from %s by Scripts/compile-shaders.sh — do not edit.\n"
               "// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).\n"
               "// spirv-fnv1a64: %016llx\n"
               "// glsl-fnv1a64: %016llx\n\n",
               sourceName, (unsigned long long)hashFile(argv[2], 0), (unsigned long long)hashFile(argv[3], 1));
        return 0;
    }
    if (argc != 3) {
        fprintf(stderr, "usage: spirv-wgsl-prep <in.spv> <out.spv> | --header <original.spv> <GLSL source path>\n");
        return 2;
    }
    FILE *in = fopen(argv[1], "rb");
    if (!in) fail("cannot open", argv[1]);
    fseek(in, 0, SEEK_END);
    long size = ftell(in);
    fseek(in, 0, SEEK_SET);
    if (size < 20 || size % 4 != 0) fail("not a SPIR-V module", argv[1]);
    uint32_t *words = malloc((size_t)size);
    if (fread(words, 1, (size_t)size, in) != (size_t)size) fail("cannot read", argv[1]);
    fclose(in);
    size_t count = (size_t)size / 4;
    if (words[0] != 0x07230203) fail("not a little-endian SPIR-V module", argv[1]);
    uint32_t bound = words[3];

    // Storage class of each pointer type and variable; where each id is defined.
    uint32_t *storage = calloc(bound, sizeof(uint32_t));
    size_t *definedAt = calloc(bound, sizeof(size_t));
    uint32_t pushConstant = 0;
    for (size_t i = 5; i < count;) {
        uint32_t length = words[i] >> 16, opcode = words[i] & 0xffff;
        if (length == 0 || i + length > count) fail("malformed instruction", argv[1]);
        if (opcode == OpTypePointer && length >= 4) storage[words[i + 1]] = words[i + 2];
        if (opcode == OpVariable && length >= 4) {
            storage[words[i + 2]] = words[i + 3];
            if (words[i + 3] == StoragePushConstant) {
                if (pushConstant) fail("more than one push-constant block", argv[1]);
                pushConstant = words[i + 2];
            }
        }
        if (opcode == OpTypePointer || (opcode >= OpTypeVoid && opcode <= OpTypeForwardPointer)) definedAt[words[i + 1]] = i;
        i += length;
    }

    Words out = {0};
    append(&out, words, 5);
    int decorationsAdded = 0;
    // Variables waiting for their pointer type: (type id, instruction index).
    size_t pendingCount = 0, pending[64];
    for (size_t i = 5; i < count;) {
        uint32_t length = words[i] >> 16, opcode = words[i] & 0xffff;
        uint32_t *inst = words + i;
        i += length;
        if (opcode == OpMemberDecorate && length >= 4 && inst[3] == DecorationNonReadable) continue;
        if (opcode == OpDecorate && length >= 3 && inst[2] == DecorationNonReadable
            && (storage[inst[1]] == StorageStorageBuffer || storage[inst[1]] == StorageUniform)) continue;
        // The first type declaration ends the annotations: add the push constants' binding there.
        if (!decorationsAdded && opcode >= OpTypeVoid && opcode <= OpTypeForwardPointer) {
            decorationsAdded = 1;
            if (pushConstant) {
                uint32_t set[] = { (4u << 16) | OpDecorate, pushConstant, DecorationDescriptorSet, 3 };
                uint32_t binding[] = { (4u << 16) | OpDecorate, pushConstant, DecorationBinding, 0 };
                append(&out, set, 4);
                append(&out, binding, 4);
            }
        }
        if ((opcode == OpTypePointer && length >= 4 && inst[2] == StoragePushConstant)
            || (opcode == OpVariable && length >= 4 && inst[3] == StoragePushConstant)) {
            uint32_t copy[16];
            if (length > 16) fail("unexpected instruction length", argv[1]);
            memcpy(copy, inst, length * sizeof(uint32_t));
            copy[opcode == OpTypePointer ? 2 : 3] = StorageUniform;
            append(&out, copy, length);
        } else if (opcode == OpVariable && length >= 4 && definedAt[inst[1]] > (size_t)(inst - words)) {
            if (pendingCount == 64) fail("too many misplaced variables", argv[1]);
            pending[pendingCount++] = (size_t)(inst - words);
            continue;
        } else {
            append(&out, inst, length);
        }
        if (opcode == OpTypePointer) {
            // Emit variables that were waiting for this pointer type.
            for (size_t p = 0; p < pendingCount;) {
                uint32_t *variable = words + pending[p];
                if (variable[1] == inst[1]) {
                    append(&out, variable, variable[0] >> 16);
                    pending[p] = pending[--pendingCount];
                } else {
                    p++;
                }
            }
        }
        if (opcode == OpFunction && pendingCount) fail("a variable's pointer type is never declared", argv[1]);
    }

    FILE *file = fopen(argv[2], "wb");
    if (!file || fwrite(out.words, sizeof(uint32_t), out.count, file) != out.count) fail("cannot write", argv[2]);
    fclose(file);
    return 0;
}
