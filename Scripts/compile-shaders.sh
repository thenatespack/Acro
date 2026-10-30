#!/usr/bin/env bash
# Compiles every GLSL shader (*.vert, *.frag) under Sources/ to SPIR-V next to it.
# Requires glslc (shaderc): `brew install shaderc` / `apt install glslc` / Vulkan SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
find Sources -type f \( -name '*.vert' -o -name '*.frag' \) | while read -r src; do
    echo "glslc $src -> $src.spv"
    glslc --target-env=vulkan1.1 -O "$src" -o "$src.spv"
done
