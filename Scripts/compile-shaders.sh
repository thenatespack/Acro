#!/usr/bin/env bash
# Regenerates every shader under Sources/ from its GLSL (*.vert, *.frag), the single source:
#   name.vert  -> name.vert.spv   (glslc; used by the Vulkan backend)
#   name.vert.spv -> name.vert.metal (SPIRV-Cross via Scripts/spirv-to-msl.c; used by the Metal backend)
# and the same for .frag. A fragment shader with more outputs than [[color(0)]] also gets
#   name.frag.spv -> name.frag.color0.metal (outputs other than color 0 dropped; the Metal
#   backend uses it for pipelines without those attachments, as MoltenVK does)
# All outputs are committed, so building the package needs neither tool.
# Requires glslc (shaderc) and SPIRV-Cross with its C API:
#   macOS: brew install shaderc spirv-cross
#   Linux: apt install glslc libspirv-cross-c-shared-dev (or the Vulkan SDK)
set -euo pipefail
cd "$(dirname "$0")/.."

shaders=()
while IFS= read -r src; do shaders+=("$src"); done < <(find Sources -type f \( -name '*.vert' -o -name '*.frag' \) | sort)

for src in "${shaders[@]}"; do
    echo "glslc $src -> $src.spv"
    glslc --target-env=vulkan1.1 -O "$src" -o "$src.spv"
done

# Build the SPIR-V -> MSL driver (SPIRV-Cross C API; the spirv-cross CLI can't remap our
# descriptor sets and push constants to the Metal binding table).
tool=.build/spirv-to-msl
if [[ ! -x "$tool" || Scripts/spirv-to-msl.c -nt "$tool" ]]; then
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
