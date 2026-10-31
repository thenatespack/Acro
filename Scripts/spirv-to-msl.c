// Cross-compiles one SPIR-V stage (vertex, fragment or compute) to MSL for the Metal backend.
// Built and run by Scripts/compile-shaders.sh; links the SPIRV-Cross C API.
//
//   spirv-to-msl <in.spv> <out.metal> <GLSL source path> [fragment output mask]
//
// Uses the same SPIRV-Cross that MoltenVK uses to run our SPIR-V on Metal, so native Metal
// executes the same MSL as Vulkan-on-MoltenVK, apart from three things set here:
// - Entry point `main` is renamed `vertex_main` / `fragment_main` / `compute_main`.
// - Resources get the Metal indices of the binding table in `ShaderSource` (the spirv-cross
//   CLI can't remap descriptor sets / push constants, hence this driver). A resource outside
//   the table is an error.
// - The vertex stage negates gl_Position.y at the end (`flip_vert_y`, as MoltenVK does): the
//   GLSL negates it for Vulkan's y-down clip space, Metal's clip space is y-up.
// - With an output mask (bit n = keep [[color(n)]]), other fragment outputs become locals.
//   MoltenVK does this for outputs the render pass has no attachment for. It matters: Apple's
//   compiler emits a different color(0) epilogue when unconsumed outputs exist, and blending
//   then rounds differently, so a pipeline without that attachment must use the masked MSL to
//   match Vulkan bit for bit.
#include <spirv_cross_c.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static _Noreturn void fail(const char *message, const char *detail) {
    fprintf(stderr, "spirv-to-msl: %s%s%s\n", message, detail ? ": " : "", detail ? detail : "");
    exit(1);
}

static void onError(void *userdata, const char *error) {
    (void)userdata;
    fail("SPIRV-Cross error", error);
}

static void check(spvc_result result, spvc_context context, const char *what) {
    if (result != SPVC_SUCCESS) fail(what, spvc_context_get_last_error_string(context));
}

// FNV-1a 64, recorded in the header so tests can tell stale output: of the SPIR-V (a stale
// .metal) and, in hashFile, of the GLSL source (a stale .spv; '\r' is skipped so a CRLF
// checkout of the GLSL hashes the same).
static uint64_t fnv1a64(const unsigned char *bytes, size_t count) {
    uint64_t hash = 0xcbf29ce484222325ull;
    for (size_t i = 0; i < count; i++) {
        hash ^= bytes[i];
        hash *= 0x100000001b3ull;
    }
    return hash;
}

static uint64_t hashFile(const char *path) {
    FILE *file = fopen(path, "rb");
    if (!file) fail("cannot open", path);
    uint64_t hash = 0xcbf29ce484222325ull;
    int c;
    while ((c = fgetc(file)) != EOF) {
        if (c == '\r') continue;
        hash ^= (unsigned char)c;
        hash *= 0x100000001b3ull;
    }
    fclose(file);
    return hash;
}

// Metal index for (set, binding), following the table in ShaderSource. Returns 0 if the
// binding isn't part of the table.
static int metalIndex(unsigned set, unsigned binding, unsigned *buffer, unsigned *texture, unsigned *sampler) {
    if (set == 0 && binding == 0) { *buffer = 15; return 1; }                     // per-frame uniform block
    if (set == 1 && binding == 0) { *texture = 0; *sampler = 0; return 1; }       // shadow map / image
    if (set == 2 && binding >= 2 && binding <= 7) { *buffer = binding; return 1; } // uniform buffer n
    if (set == 2 && binding >= 8 && binding <= 15) { *texture = binding - 8; return 1; }
    if (set == 2 && binding >= 16 && binding <= 23) { *sampler = binding - 16; return 1; }
    if (set == 2 && binding >= 24 && binding <= 31) { *buffer = 20 + binding - 24; return 1; } // storage buffer n
    if (set == 2 && binding >= 32 && binding <= 39) { *texture = 8 + binding - 32; return 1; } // storage texture n
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 4 && argc != 5) {
        fprintf(stderr, "usage: spirv-to-msl <in.spv> <out.metal> <GLSL source path> [fragment output mask]\n");
        return 2;
    }
    FILE *in = fopen(argv[1], "rb");
    if (!in) fail("cannot open", argv[1]);
    fseek(in, 0, SEEK_END);
    long size = ftell(in);
    fseek(in, 0, SEEK_SET);
    if (size <= 0 || size % 4 != 0) fail("not a SPIR-V module", argv[1]);
    unsigned char *bytes = malloc((size_t)size);
    if (fread(bytes, 1, (size_t)size, in) != (size_t)size) fail("cannot read", argv[1]);
    fclose(in);
    SpvId *words = malloc((size_t)size);
    memcpy(words, bytes, (size_t)size);

    spvc_context context;
    if (spvc_context_create(&context) != SPVC_SUCCESS) fail("cannot create a SPIRV-Cross context", NULL);
    spvc_context_set_error_callback(context, onError, NULL);
    spvc_parsed_ir ir;
    check(spvc_context_parse_spirv(context, words, (size_t)size / 4, &ir), context, "parse");
    spvc_compiler compiler;
    check(spvc_context_create_compiler(context, SPVC_BACKEND_MSL, ir, SPVC_CAPTURE_MODE_TAKE_OWNERSHIP, &compiler),
          context, "create compiler");

    SpvExecutionModel model = spvc_compiler_get_execution_model(compiler);
    const char *entry;
    if (model == SpvExecutionModelVertex) entry = "vertex_main";
    else if (model == SpvExecutionModelFragment) entry = "fragment_main";
    else if (model == SpvExecutionModelGLCompute) entry = "compute_main";
    else fail("only vertex, fragment and compute shaders are supported", argv[1]);
    check(spvc_compiler_rename_entry_point(compiler, "main", entry, model), context, "rename entry point");

    spvc_compiler_options options;
    check(spvc_compiler_create_compiler_options(compiler, &options), context, "options");
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_PLATFORM, SPVC_MSL_PLATFORM_MACOS);
    // MSL 3.1 is what macOS 14 (the package's minimum) supports.
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_VERSION, 30100);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_FLIP_VERTEX_Y, model == SpvExecutionModelVertex);
    if (argc == 5) {
        if (model != SpvExecutionModelFragment) fail("an output mask only applies to fragment shaders", argv[1]);
        spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_MSL_ENABLE_FRAG_OUTPUT_MASK,
                                       (unsigned)strtoul(argv[4], NULL, 0));
    }
    check(spvc_compiler_install_compiler_options(compiler, options), context, "install options");

    // Push constants → buffer(16).
    spvc_msl_resource_binding_2 push;
    spvc_msl_resource_binding_init_2(&push);
    push.stage = model;
    push.desc_set = SPVC_MSL_PUSH_CONSTANT_DESC_SET;
    push.binding = SPVC_MSL_PUSH_CONSTANT_BINDING;
    push.count = 1;
    push.msl_buffer = 16;
    check(spvc_compiler_msl_add_resource_binding_2(compiler, &push), context, "push constant binding");

    // Every descriptor the shader declares must be in the table.
    spvc_resources resources;
    check(spvc_compiler_create_shader_resources(compiler, &resources), context, "reflect");
    static const struct { spvc_resource_type type; const char *name; } kinds[] = {
        { SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, "uniform buffer" },
        { SPVC_RESOURCE_TYPE_SAMPLED_IMAGE, "combined image sampler" },
        { SPVC_RESOURCE_TYPE_SEPARATE_IMAGE, "texture" },
        { SPVC_RESOURCE_TYPE_SEPARATE_SAMPLERS, "sampler" },
        { SPVC_RESOURCE_TYPE_STORAGE_BUFFER, "storage buffer" },
        { SPVC_RESOURCE_TYPE_STORAGE_IMAGE, "storage image" },
        { SPVC_RESOURCE_TYPE_SUBPASS_INPUT, "subpass input" },
    };
    for (size_t k = 0; k < sizeof(kinds) / sizeof(kinds[0]); k++) {
        const spvc_reflected_resource *list;
        size_t count;
        check(spvc_resources_get_resource_list_for_type(resources, kinds[k].type, &list, &count), context, "reflect");
        for (size_t i = 0; i < count; i++) {
            unsigned set = spvc_compiler_get_decoration(compiler, list[i].id, SpvDecorationDescriptorSet);
            unsigned binding = spvc_compiler_get_decoration(compiler, list[i].id, SpvDecorationBinding);
            spvc_msl_resource_binding_2 remap;
            spvc_msl_resource_binding_init_2(&remap);
            remap.stage = model;
            remap.desc_set = set;
            remap.binding = binding;
            remap.count = 1;
            int buffer = kinds[k].type == SPVC_RESOURCE_TYPE_UNIFORM_BUFFER || kinds[k].type == SPVC_RESOURCE_TYPE_STORAGE_BUFFER;
            int texture = kinds[k].type == SPVC_RESOURCE_TYPE_SAMPLED_IMAGE || kinds[k].type == SPVC_RESOURCE_TYPE_SEPARATE_IMAGE
                || kinds[k].type == SPVC_RESOURCE_TYPE_STORAGE_IMAGE;
            int sampler = kinds[k].type == SPVC_RESOURCE_TYPE_SAMPLED_IMAGE || kinds[k].type == SPVC_RESOURCE_TYPE_SEPARATE_SAMPLERS;
            unsigned b = ~0u, t = ~0u, s = ~0u;
            int known = (buffer || texture || sampler) && metalIndex(set, binding, &b, &t, &s)
                && (!buffer || b != ~0u) && (!texture || t != ~0u) && (!sampler || s != ~0u);
            if (!known) {
                fprintf(stderr, "spirv-to-msl: %s: %s '%s' at set %u, binding %u is not in the binding table (see ShaderSource)\n",
                        argv[1], kinds[k].name, list[i].name, set, binding);
                return 1;
            }
            remap.msl_buffer = b;
            remap.msl_texture = t;
            remap.msl_sampler = s;
            check(spvc_compiler_msl_add_resource_binding_2(compiler, &remap), context, "resource binding");
        }
    }

    const char *msl;
    check(spvc_compiler_compile(compiler, &msl), context, "compile");

    const char *sourceName = strrchr(argv[3], '/');
    const char *backslash = strrchr(argv[3], '\\');
    if (backslash && (!sourceName || backslash > sourceName)) sourceName = backslash;
    sourceName = sourceName ? sourceName + 1 : argv[3];
    uint64_t sourceHash = hashFile(argv[3]);

    FILE *out = fopen(argv[2], "wb");
    if (!out) fail("cannot write", argv[2]);
    fprintf(out,
            "// Generated from %s by Scripts/compile-shaders.sh — do not edit.\n"
            "// Edit the GLSL and rerun the script (needs glslc and spirv-cross).\n"
            "// spirv-fnv1a64: %016llx\n"
            "// glsl-fnv1a64: %016llx\n\n",
            sourceName, (unsigned long long)fnv1a64(bytes, (size_t)size), (unsigned long long)sourceHash);
    fputs(msl, out);
    if (fclose(out) != 0) fail("cannot write", argv[2]);
    spvc_context_destroy(context);
    free(words);
    free(bytes);
    return 0;
}
