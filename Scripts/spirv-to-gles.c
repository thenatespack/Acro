// Cross-compiles one SPIR-V vertex or fragment stage to GLSL ES 3.00 for the WebGL 2 backend.
// Built and run by Scripts/compile-shaders.sh; links the SPIRV-Cross C API.
//
//   spirv-to-gles <in.spv> <out.gles> <GLSL source path>
//
// Exit status 3 (and no output file) when the stage needs what WebGL 2 lacks: storage buffers or
// storage images among its *active* resources (inactive ones are left out of the output).
//
// GLSL ES 3.00 has no binding qualifiers and links varyings and uniform blocks by name, so this
// names everything the device binds, deterministically, and lists it in a header the device parses
// (`WebGL2Program`, see the table in ShaderSource):
// - Stage outputs of the vertex shader and inputs of the fragment shader are `acro_v<location>`.
// - Uniform blocks are `acro_<vs|fs>_u<set>_<binding>`, push constants `acro_<vs|fs>_push` (a
//   uniform block: WebGL has no push constants). Per stage, so a vertex and a fragment block that
//   differ in layout never collide; the device binds both to the same binding point.
// - Samplers (GLSL ES has only combined image samplers) are `acro_t<set>_<binding>_s<set>_<binding>`
//   for a texture and the sampler it is used with, `acro_t<set>_<binding>` for one already
//   combined in the GLSL (the shadow map) or loaded without a sampler (texelFetch).
// - The header (after `#version 300 es`, which WebGL wants on the first line) has one line per resource:
//     // acro-ubo <block name> <set> <binding>        (push constants: set -1, binding -1)
//     // acro-sampler <uniform name> <texture set> <texture binding> <sampler set> <sampler binding> <shadow 0|1>
//   (sampler set and binding -1 when the texture has no sampler of its own.)
//
// Settings: push constants as a uniform block; z mapped from Vulkan's 0..1 to GL's -1..1
// (`fixup_clipspace`; WebGL has no glClipControl everywhere). y is not flipped: the device renders
// every pass into framebuffers whose memory row 0 is the image's top, as in Vulkan and WebGPU, and
// flips the winding and the final present instead. gl_InstanceIndex is gl_InstanceID (the engine
// draws from instance 0). `noperspective` varyings become perspective-correct (ES 3.00 has none).
#include <spirv_cross_c.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static _Noreturn void fail(const char *message, const char *detail) {
    fprintf(stderr, "spirv-to-gles: %s%s%s\n", message, detail ? ": " : "", detail ? detail : "");
    exit(1);
}

static void onError(void *userdata, const char *error) {
    (void)userdata;
    fail("SPIRV-Cross error", error);
}

static void check(spvc_result result, spvc_context context, const char *what) {
    if (result != SPVC_SUCCESS) fail(what, spvc_context_get_last_error_string(context));
}

// FNV-1a 64, as in spirv-to-msl.c: recorded in the header so tests can tell stale output.
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

static unsigned decoration(spvc_compiler compiler, SpvId id, SpvDecoration which) {
    return spvc_compiler_has_decoration(compiler, id, which) ? spvc_compiler_get_decoration(compiler, id, which) : ~0u;
}

// The binding-table check of spirv-to-msl.c: uniform buffers, textures and samplers the WebGL 2
// device can bind.
static int known(unsigned set, unsigned binding) {
    return (set == 0 && binding == 0) || (set == 1 && binding <= 1) || (set == 2 && binding >= 2 && binding <= 23);
}

static int isShadowSampler(const char *glsl, const char *name) {
    // "uniform highp sampler2DShadow <name>;"
    char pattern[256];
    snprintf(pattern, sizeof pattern, "sampler2DShadow %s;", name);
    return strstr(glsl, pattern) != NULL;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: spirv-to-gles <in.spv> <out.gles> <GLSL source path>\n");
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
    check(spvc_context_create_compiler(context, SPVC_BACKEND_GLSL, ir, SPVC_CAPTURE_MODE_TAKE_OWNERSHIP, &compiler),
          context, "create compiler");

    SpvExecutionModel model = spvc_compiler_get_execution_model(compiler);
    if (model != SpvExecutionModelVertex && model != SpvExecutionModelFragment) {
        fail("only vertex and fragment shaders have GLSL ES (WebGL 2 has no compute)", argv[1]);
    }
    const char *stage = model == SpvExecutionModelVertex ? "vs" : "fs";

    // Only the resources the entry point uses (probes.glsl's storage buffer is declared by every
    // mesh fragment shader, used only by the *_probes variants).
    spvc_set active;
    check(spvc_compiler_get_active_interface_variables(compiler, &active), context, "active variables");
    check(spvc_compiler_set_enabled_interface_variables(compiler, active), context, "enable active variables");
    spvc_resources resources;
    check(spvc_compiler_create_shader_resources_for_active_variables(compiler, &resources, active), context, "reflect");

    const spvc_reflected_resource *list;
    size_t count;
    static const spvc_resource_type unsupported[] = {
        SPVC_RESOURCE_TYPE_STORAGE_BUFFER, SPVC_RESOURCE_TYPE_STORAGE_IMAGE, SPVC_RESOURCE_TYPE_SUBPASS_INPUT,
        SPVC_RESOURCE_TYPE_ATOMIC_COUNTER,
    };
    for (size_t k = 0; k < sizeof(unsupported) / sizeof(unsupported[0]); k++) {
        check(spvc_resources_get_resource_list_for_type(resources, unsupported[k], &list, &count), context, "reflect");
        if (count > 0) {
            fprintf(stderr, "spirv-to-gles: %s: uses '%s' (storage buffers and images need WebGPU)\n", argv[1], list[0].name);
            return 3;
        }
    }

    spvc_compiler_options options;
    check(spvc_compiler_create_compiler_options(compiler, &options), context, "options");
    spvc_compiler_options_set_uint(options, SPVC_COMPILER_OPTION_GLSL_VERSION, 300);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_ES, SPVC_TRUE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_VULKAN_SEMANTICS, SPVC_FALSE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_ENABLE_420PACK_EXTENSION, SPVC_FALSE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_SEPARATE_SHADER_OBJECTS, SPVC_FALSE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_ES_DEFAULT_FLOAT_PRECISION_HIGHP, SPVC_TRUE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_ES_DEFAULT_INT_PRECISION_HIGHP, SPVC_TRUE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_EMIT_PUSH_CONSTANT_AS_UNIFORM_BUFFER, SPVC_TRUE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_GLSL_SUPPORT_NONZERO_BASE_INSTANCE, SPVC_FALSE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_FLIP_VERTEX_Y, SPVC_FALSE);
    spvc_compiler_options_set_bool(options, SPVC_COMPILER_OPTION_FIXUP_DEPTH_CONVENTION, model == SpvExecutionModelVertex);
    check(spvc_compiler_install_compiler_options(compiler, options), context, "install options");

    // Every descriptor must be in the binding table.
    static const struct { spvc_resource_type type; const char *name; } kinds[] = {
        { SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, "uniform buffer" },
        { SPVC_RESOURCE_TYPE_SAMPLED_IMAGE, "combined image sampler" },
        { SPVC_RESOURCE_TYPE_SEPARATE_IMAGE, "texture" },
        { SPVC_RESOURCE_TYPE_SEPARATE_SAMPLERS, "sampler" },
    };
    for (size_t k = 0; k < sizeof(kinds) / sizeof(kinds[0]); k++) {
        check(spvc_resources_get_resource_list_for_type(resources, kinds[k].type, &list, &count), context, "reflect");
        for (size_t i = 0; i < count; i++) {
            unsigned set = decoration(compiler, list[i].id, SpvDecorationDescriptorSet);
            unsigned binding = decoration(compiler, list[i].id, SpvDecorationBinding);
            if (!known(set, binding)) {
                fprintf(stderr, "spirv-to-gles: %s: %s '%s' at set %u, binding %u is not in the binding table (see ShaderSource)\n",
                        argv[1], kinds[k].name, list[i].name, set, binding);
                return 1;
            }
        }
    }

    // Header lines, collected while naming.
    size_t headerCapacity = 1 << 16, headerLength = 0;
    char *header = malloc(headerCapacity);
    header[0] = 0;
#define HEADER(...) do { \
        int n = snprintf(header + headerLength, headerCapacity - headerLength, __VA_ARGS__); \
        if (n < 0 || (size_t)n >= headerCapacity - headerLength) fail("header too long", argv[1]); \
        headerLength += (size_t)n; \
    } while (0)

    char name[256];
    // Uniform blocks: the block (type) name is what links; the instance keeps its name.
    check(spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &list, &count), context, "reflect");
    for (size_t i = 0; i < count; i++) {
        unsigned set = decoration(compiler, list[i].id, SpvDecorationDescriptorSet);
        unsigned binding = decoration(compiler, list[i].id, SpvDecorationBinding);
        snprintf(name, sizeof name, "acro_%s_u%u_%u", stage, set, binding);
        spvc_compiler_set_name(compiler, list[i].base_type_id, name);
        HEADER("// acro-ubo %s %u %u\n", name, set, binding);
    }
    check(spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_PUSH_CONSTANT, &list, &count), context, "reflect");
    for (size_t i = 0; i < count; i++) {
        snprintf(name, sizeof name, "acro_%s_push", stage);
        spvc_compiler_set_name(compiler, list[i].base_type_id, name);
        HEADER("// acro-ubo %s -1 -1\n", name);
    }

    // Varyings link by name in GLSL ES 3.00: name them by location.
    spvc_resource_type varyings = model == SpvExecutionModelVertex ? SPVC_RESOURCE_TYPE_STAGE_OUTPUT : SPVC_RESOURCE_TYPE_STAGE_INPUT;
    check(spvc_resources_get_resource_list_for_type(resources, varyings, &list, &count), context, "reflect");
    for (size_t i = 0; i < count; i++) {
        unsigned location = decoration(compiler, list[i].id, SpvDecorationLocation);
        if (location == ~0u) fail("a varying has no location", list[i].name);
        snprintf(name, sizeof name, "acro_v%u", location);
        spvc_compiler_set_name(compiler, list[i].id, name);
        // GLSL ES 3.00 has no `noperspective` (only an NV extension WebGL doesn't expose): such
        // varyings are interpolated with perspective here (debug_line's width falloff).
        spvc_compiler_unset_decoration(compiler, list[i].id, SpvDecorationNoPerspective);
    }

    // Combined image samplers: a dummy sampler for textures loaded without one (texelFetch), then
    // one sampler2D per texture and sampler used together.
    spvc_variable_id dummy = 0;
    check(spvc_compiler_build_dummy_sampler_for_combined_images(compiler, &dummy), context, "dummy sampler");
    check(spvc_compiler_build_combined_image_samplers(compiler), context, "combined image samplers");
    const spvc_combined_image_sampler *combined;
    size_t combinedCount;
    check(spvc_compiler_get_combined_image_samplers(compiler, &combined, &combinedCount), context, "combined image samplers");
    typedef struct { char name[96]; int textureSet, textureBinding, samplerSet, samplerBinding; } Sampler;
    Sampler *samplers = calloc(combinedCount + 64, sizeof(Sampler));
    size_t samplerCount = 0;
    for (size_t i = 0; i < combinedCount; i++) {
        unsigned tset = decoration(compiler, combined[i].image_id, SpvDecorationDescriptorSet);
        unsigned tbinding = decoration(compiler, combined[i].image_id, SpvDecorationBinding);
        Sampler *s = &samplers[samplerCount++];
        s->textureSet = (int)tset;
        s->textureBinding = (int)tbinding;
        if (combined[i].sampler_id == dummy) {
            s->samplerSet = -1;
            s->samplerBinding = -1;
            snprintf(s->name, sizeof s->name, "acro_t%u_%u", tset, tbinding);
        } else {
            unsigned sset = decoration(compiler, combined[i].sampler_id, SpvDecorationDescriptorSet);
            unsigned sbinding = decoration(compiler, combined[i].sampler_id, SpvDecorationBinding);
            s->samplerSet = (int)sset;
            s->samplerBinding = (int)sbinding;
            snprintf(s->name, sizeof s->name, "acro_t%u_%u_s%u_%u", tset, tbinding, sset, sbinding);
        }
        spvc_compiler_set_name(compiler, combined[i].combined_id, s->name);
    }
    // Samplers the GLSL declares combined (sampler2DShadow shadowMap, sampler2D image).
    check(spvc_resources_get_resource_list_for_type(resources, SPVC_RESOURCE_TYPE_SAMPLED_IMAGE, &list, &count), context, "reflect");
    for (size_t i = 0; i < count; i++) {
        if (samplerCount >= combinedCount + 64) fail("too many samplers", argv[1]);
        unsigned set = decoration(compiler, list[i].id, SpvDecorationDescriptorSet);
        unsigned binding = decoration(compiler, list[i].id, SpvDecorationBinding);
        Sampler *s = &samplers[samplerCount++];
        s->textureSet = (int)set;
        s->textureBinding = (int)binding;
        s->samplerSet = (int)set;
        s->samplerBinding = (int)binding;
        snprintf(s->name, sizeof s->name, "acro_t%u_%u", set, binding);
        spvc_compiler_set_name(compiler, list[i].id, s->name);
    }

    const char *glsl;
    check(spvc_compiler_compile(compiler, &glsl), context, "compile");
    for (size_t i = 0; i < samplerCount; i++) {
        // A combined sampler the compiler dropped (an inactive one) isn't declared.
        char declared[128];
        snprintf(declared, sizeof declared, " %s;", samplers[i].name);
        if (!strstr(glsl, declared)) continue;
        HEADER("// acro-sampler %s %d %d %d %d %d\n", samplers[i].name, samplers[i].textureSet, samplers[i].textureBinding,
               samplers[i].samplerSet, samplers[i].samplerBinding, isShadowSampler(glsl, samplers[i].name));
    }

    // Built-ins GLSL ES 3.00 lacks (3.10 has them): a polyfill under another name.
    char *patched = NULL;
    if (strstr(glsl, "bitfieldReverse(")) {
        static const char *polyfill =
            "highp uint acro_bitfieldReverse(highp uint v)\n{\n"
            "    v = ((v >> 1u) & 0x55555555u) | ((v & 0x55555555u) << 1u);\n"
            "    v = ((v >> 2u) & 0x33333333u) | ((v & 0x33333333u) << 2u);\n"
            "    v = ((v >> 4u) & 0x0F0F0F0Fu) | ((v & 0x0F0F0F0Fu) << 4u);\n"
            "    v = ((v >> 8u) & 0x00FF00FFu) | ((v & 0x00FF00FFu) << 8u);\n"
            "    return (v >> 16u) | (v << 16u);\n}\n\n";
        // After the precision statements, which start the body.
        const char *anchor = strstr(glsl, "precision highp int;\n");
        if (!anchor) fail("no precision statement to put a polyfill after", argv[1]);
        anchor += strlen("precision highp int;\n");
        size_t length = strlen(glsl);
        patched = malloc(length * 2 + strlen(polyfill) + 1);
        size_t n = (size_t)(anchor - glsl);
        memcpy(patched, glsl, n);
        strcpy(patched + n, polyfill);
        n += strlen(polyfill);
        for (const char *p = anchor; *p;) {
            if (strncmp(p, "bitfieldReverse(", 16) == 0) {
                memcpy(patched + n, "acro_bitfieldReverse(", 21);
                n += 21;
                p += 16;
            } else {
                patched[n++] = *p++;
            }
        }
        patched[n] = 0;
        glsl = patched;
    }

    const char *sourceName = strrchr(argv[3], '/');
    sourceName = sourceName ? sourceName + 1 : argv[3];
    FILE *out = fopen(argv[2], "wb");
    if (!out) fail("cannot write", argv[2]);
    // WebGL wants `#version 300 es` on the first line, before any comment.
    const char *body = strchr(glsl, '\n');
    if (strncmp(glsl, "#version 300 es\n", 16) != 0 || !body) fail("unexpected output", argv[1]);
    fprintf(out,
            "#version 300 es\n"
            "// Generated from %s by Scripts/compile-shaders.sh — do not edit.\n"
            "// Edit the GLSL and rerun the script (needs glslc and spirv-cross).\n"
            "// spirv-fnv1a64: %016llx\n"
            "// glsl-fnv1a64: %016llx\n",
            sourceName, (unsigned long long)fnv1a64(bytes, (size_t)size), (unsigned long long)hashFile(argv[3]));
    fputs(header, out);
    fputs(body + 1, out);
    if (fclose(out) != 0) fail("cannot write", argv[2]);
    spvc_context_destroy(context);
    free(patched);
    free(samplers);
    free(header);
    free(words);
    free(bytes);
    return 0;
}
