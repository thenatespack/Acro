#!/usr/bin/env bash
# Renders every demo scene on every available backend and checks that the backends
# produce identical images.
#
#   Scripts/render-scenes.sh [quality] [output-dir]
#
# quality: low|medium|high|ultra (default high). Screenshots land in
# output-dir (default .build/scene-shots/<quality>[-<resolution>]) as <scene>-<backend>.png.
# Set ENGINE_RESOLUTION (e.g. 144p, 4k, 16k) to render at a fixed resolution; screenshots
# are taken at that size.
# Set VALIDATE=1 to run Vulkan with validation layers (Homebrew paths on macOS).
set -euo pipefail
cd "$(dirname "$0")/.."

quality=${1:-high}
out=${2:-.build/scene-shots/$quality${ENGINE_RESOLUTION:+-$ENGINE_RESOLUTION}}
mkdir -p "$out"

swift build -c release --product Demo >/dev/null
demo="$(swift build -c release --show-bin-path)/Demo"

backends=(vulkan)
[[ "$(uname)" == Darwin ]] && backends=(metal)
if [[ "$(uname)" == Darwin && -n "$(find .build -name 'CVulkan*' -print -quit 2>/dev/null)" ]]; then
    backends+=(vulkan)
fi

vulkan_env=()
if [[ "${VALIDATE:-0}" == 1 ]]; then
    vulkan_env=(ENGINE_VULKAN_VALIDATION=1)
    if command -v brew >/dev/null && prefix=$(brew --prefix vulkan-validationlayers 2>/dev/null); then
        vulkan_env+=(VK_LAYER_PATH="$prefix/share/vulkan/explicit_layer.d" DYLD_LIBRARY_PATH="$prefix/lib")
    fi
fi

status=0
for scene in $("$demo" --list); do
    for backend in "${backends[@]}"; do
        log="$out/$scene-$backend.log"
        extra=()
        [[ "$backend" == vulkan ]] && extra=(${vulkan_env[@]+"${vulkan_env[@]}"})
        if ! env ${extra[@]+"${extra[@]}"} ENGINE_OVERLAY=0 ENGINE_SCREENSHOT="$out/$scene-$backend.png" \
            "$demo" --scene "$scene" --quality "$quality" --backend "$backend" >"$log" 2>&1; then
            echo "FAIL  $scene ($backend): exited with an error, see $log"
            status=1
            continue
        fi
        if grep -q "Validation Error" "$log"; then
            echo "FAIL  $scene ($backend): validation errors, see $log"
            status=1
        fi
    done
    if [[ ${#backends[@]} -gt 1 ]]; then
        if cmp -s "$out/$scene-${backends[0]}.png" "$out/$scene-${backends[1]}.png"; then
            echo "ok    $scene: ${backends[*]} identical"
        else
            echo "DIFF  $scene: ${backends[0]} and ${backends[1]} differ"
            status=1
        fi
    else
        echo "ok    $scene: rendered on ${backends[0]}"
    fi
done
echo "Screenshots in $out"
exit $status
