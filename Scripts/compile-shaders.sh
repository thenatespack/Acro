#!/usr/bin/env bash
# Regenerates every shader under Sources/ and Tests/ from its GLSL (*.vert, *.frag, *.comp), the
# single source:
#   name.vert  -> name.vert.spv   (glslc; used by the Vulkan backend)
#   name.vert.spv -> name.vert.metal (SPIRV-Cross via Scripts/spirv-to-msl.c; used by the Metal backend)
# and the same for .frag and .comp (compute; entry point compute_main in MSL). A fragment
# shader with more outputs than [[color(0)]] also gets
#   name.frag.spv -> name.frag.color0.metal (outputs other than color 0 dropped; the Metal
#   backend uses it for pipelines without those attachments, as MoltenVK does)
#   name.vert.spv -> name.vert.wgsl (spirv-opt, Scripts/spirv-wgsl-prep.c, then naga; used by the
#   WebGPU backend: combined image samplers split, push constants moved to a uniform buffer at
#   @group(3) @binding(0), see ShaderSource)
#   name.vert.spv -> name.vert.gles (GLSL ES 3.00 via Scripts/spirv-to-gles.c; used by the WebGL 2
#   backend: combined image samplers, push constants as a uniform block, everything named by its
#   binding and listed in a header the device parses, see ShaderSource). Vertex and fragment only.
#   A shader marked "// compile-shaders: gles <glslc flags>" gets its .gles from a second
#   compile with those flags (the material graph templates' uniform-block variant).
# All outputs are committed, so building the package needs none of the tools.
# Requires glslc (shaderc), SPIRV-Cross with its C API, spirv-opt (SPIRV-Tools) and naga-cli:
#   macOS: brew install shaderc spirv-cross spirv-tools
#   Linux: apt install glslc libspirv-cross-c-shared-dev spirv-tools (or the Vulkan SDK)
#   Both: cargo install naga-cli (Homebrew's "naga" is an unrelated program); NAGA=<path> overrides
set -euo pipefail
cd "$(dirname "$0")/.."

shaders=()
while IFS= read -r src; do shaders+=("$src"); done < <(find Sources Tests -type f \( -name '*.vert' -o -name '*.frag' -o -name '*.comp' \) | sort)

# Vendored shader libraries include their own headers by paths relative to their root (e.g. the
# FidelityFX SDK's "fsr1/ffx_fsr1.h"), so each such root is an include directory.
includes=()
while IFS= read -r dir; do includes+=(-I "$dir"); done < <(find Sources Tests -type d -name FidelityFX | sort)

for src in "${shaders[@]}"; do
    echo "glslc $src -> $src.spv"
    # A shader marked "// compile-shaders: -O0" is compiled unoptimized (mesh_graph.frag: its
    # functions must survive, by name, for the engine to replace one).
    opt=-O
    grep -q '^// compile-shaders: -O0' "$src" && opt=-O0
    glslc --target-env=vulkan1.1 $opt ${includes[@]+"${includes[@]}"} "$src" -o "$src.spv"
done

# Build the SPIR-V -> MSL and -> GLSL ES drivers (SPIRV-Cross C API; the spirv-cross CLI can't
# remap our descriptor sets and push constants to the Metal binding table, or name resources by binding).
tool=.build/spirv-to-msl
gles_tool=.build/spirv-to-gles
if [[ ! -x "$tool" || Scripts/spirv-to-msl.c -nt "$tool" || ! -x "$gles_tool" || Scripts/spirv-to-gles.c -nt "$gles_tool" ]]; then
    mkdir -p .build
    if pkg-config --exists spirv-cross-c-shared 2>/dev/null; then
        read -r -a flags <<<"$(pkg-config --cflags --libs spirv-cross-c-shared)"
    elif pkg-config --exists spirv-cross-c 2>/dev/null; then
        # Static libraries (Homebrew): the C API needs the backends it was built with.
        libdir=$(pkg-config --variable=libdir spirv-cross-c)
        read -r -a flags <<<"$(pkg-config --cflags spirv-cross-c)"
        flags+=("-L$libdir")
        for lib in c msl glsl hlsl cpp reflect util core; do
            [[ -e "$libdir/libspirv-cross-$lib.a" ]] && flags+=("-lspirv-cross-$lib")
        done
    else
        echo "SPIRV-Cross not found (pkg-config spirv-cross-c-shared / spirv-cross-c)." >&2
        echo "Install it: brew install spirv-cross / apt install libspirv-cross-c-shared-dev" >&2
        exit 1
    fi
    echo "building $tool"
    c++ -x c -O2 -Wall Scripts/spirv-to-msl.c "${flags[@]}" -o "$tool"
    echo "building $gles_tool"
    c++ -x c -O2 -Wall Scripts/spirv-to-gles.c "${flags[@]}" -o "$gles_tool"
fi

for src in "${shaders[@]}"; do
    echo "spirv-to-msl $src.spv -> $src.metal"
    "$tool" "$src.spv" "$src.metal" "$src"
    if [[ "$src" == *.frag ]] && grep -q '\[\[color([1-9])\]\]' "$src.metal"; then
        echo "spirv-to-msl $src.spv -> $src.color0.metal"
        "$tool" "$src.spv" "$src.color0.metal" "$src" 1
    else
        rm -f "$src.color0.metal"
    fi
done

# SPIR-V -> GLSL ES 3.00 for the WebGL 2 backend (vertex and fragment stages). A stage whose active
# resources include storage buffers or images gets no .gles (listed at the end); the WebGL 2 backend
# refuses its pipelines. With glslangValidator installed each output is checked as GLSL ES.
validator=$(command -v glslangValidator || true)
work_gles_log=$(mktemp)
work_gles_spv=$(mktemp)
no_gles=()
for src in "${shaders[@]}"; do
    [[ "$src" == *.comp ]] && continue
    echo "spirv-to-gles $src.spv -> $src.gles"
    status=0
    # A shader marked "// compile-shaders: gles <glslc flags>" is compiled again with those flags
    # for its GLSL ES (the material graph templates: GRAPH_VALUES_UNIFORM reads the graph's values
    # from a uniform block instead of a storage buffer). The header still records $src.spv's hash.
    gles_flags=$(sed -n 's|^// compile-shaders: gles ||p' "$src" | head -n 1)
    gles_input="$src.spv"
    if [[ -n "$gles_flags" ]]; then
        opt=-O
        grep -q '^// compile-shaders: -O0' "$src" && opt=-O0
        read -r -a gles_flag_list <<<"$gles_flags"
        glslc --target-env=vulkan1.1 $opt ${includes[@]+"${includes[@]}"} "${gles_flag_list[@]}" "$src" -o "$work_gles_spv"
        gles_input="$work_gles_spv"
    fi
    "$gles_tool" "$gles_input" "$src.gles" "$src" "$src.spv" 2>"$work_gles_log" || status=$?
    if ((status == 3)); then
        no_gles+=("$src: $(head -n 1 "$work_gles_log")")
        rm -f "$src.gles"
        continue
    elif ((status != 0)); then
        cat "$work_gles_log" >&2
        exit 1
    fi
    if [[ -n "$validator" ]] && ! "$validator" -S "${src##*.}" "$src.gles" >"$work_gles_log" 2>&1; then
        cat "$work_gles_log" >&2
        echo "GLSL ES validation failed: $src.gles" >&2
        exit 1
    fi
done

# SPIR-V -> WGSL for the WebGPU backend. naga translates; the SPIR-V is prepared first:
# spirv-opt splits the set 1 combined image samplers (texture at binding 0, sampler at 1), and
# spirv-wgsl-prep turns push constants into a uniform buffer and drops write-only from storage
# buffers. Derivative uniformity (textureSample in non-uniform control flow, which GLSL allows)
# is turned off per module. Barrier uniformity can't be turned off: browsers reject the FSR 3
# shaders that call barriers under a condition naga can't prove uniform (FSR 3 is unsupported there). A shader naga can't translate gets no .wgsl (listed at the end); the
# WebGPU backend refuses pipelines without WGSL.
naga=${NAGA:-$(command -v naga || echo "$HOME/.cargo/bin/naga")}
if ! "$naga" --version 2>/dev/null | grep -Eq '^(naga )?[0-9]+\.'; then
    echo "naga-cli not found (cargo install naga-cli; Homebrew's naga is a different program), or set NAGA" >&2
    exit 1
fi
command -v spirv-opt >/dev/null || { echo "spirv-opt not found (brew install spirv-tools / apt install spirv-tools)" >&2; exit 1; }
prep=.build/spirv-wgsl-prep
if [[ ! -x "$prep" || Scripts/spirv-wgsl-prep.c -nt "$prep" ]]; then
    mkdir -p .build
    echo "building $prep"
    cc -O2 -Wall Scripts/spirv-wgsl-prep.c -o "$prep"
fi
work=$(mktemp -d)
trap 'rm -rf "$work" "$work_gles_log" "$work_gles_spv"' EXIT
failed=()
for src in "${shaders[@]}"; do
    echo "naga $src.spv -> $src.wgsl"
    spirv-opt --split-combined-image-sampler --resolve-binding-conflicts "$src.spv" -o "$work/split.spv"
    "$prep" "$work/split.spv" "$work/prepared.spv"
    if ! "$naga" "$work/prepared.spv" "$work/out.wgsl" >"$work/naga.log" 2>&1; then
        failed+=("$src: $(grep -v WARN "$work/naga.log" | head -n 3 | tr '\n' ' ')")
        rm -f "$src.wgsl"
        continue
    fi
    # naga prints FLT_MAX as 340282350000000000000000000000000000000f, which is above FLT_MAX: browsers
    # reject it ("value cannot be represented as 'f32'"), so write it exactly.
    { "$prep" --header "$src.spv" "$src"; echo 'diagnostic(off, derivative_uniformity);'; echo
      sed 's/340282350000000000000000000000000000000f/0x1.fffffep+127f/g' "$work/out.wgsl"; } >"$src.wgsl"
done
if ((${#no_gles[@]})); then
    echo "No GLSL ES for these shaders (the WebGL 2 backend refuses their pipelines):"
    printf '  %s\n' "${no_gles[@]}"
fi
if ((${#failed[@]})); then
    echo "No WGSL for these shaders (the WebGPU backend refuses their pipelines):"
    printf '  %s\n' "${failed[@]}"
fi
