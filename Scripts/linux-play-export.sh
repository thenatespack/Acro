#!/usr/bin/env bash
# Runs an exported Linux game (Build Game's output folder) in a clean Ubuntu container with no
# Swift toolchain and no GLFW (the export bundles it in lib/): only what a desktop player's
# machine has (Vulkan loader, X11 and the X extensions GLFW loads, zlib, ALSA) plus lavapipe
# and xvfb to draw on. It renders one frame with
# ENGINE_SCREENSHOT and checks that a PNG came out, so a missing library, resource bundle or
# pack shows up here rather than on a player's machine.
#
#   Scripts/linux-play-export.sh [game folder]     default: the only folder in .build/linux-ci/export/
#
# IMAGE (default ubuntu:24.04) picks the distro; PLATFORM=linux/amd64 as in linux-docker-ci.sh
# (the game must have been exported for that architecture). The screenshot, the log and `ldd`'s
# output land in .build/linux-ci/play/.
set -euo pipefail
cd "$(dirname "$0")/.."

game=${1:-}
if [[ -z $game ]]; then
    folders=(.build/linux-ci/export/*/)
    [[ ${#folders[@]} -eq 1 && -d ${folders[0]} ]] || { echo "No single game folder in .build/linux-ci/export/; run Scripts/linux-docker-ci.sh export or pass one"; exit 1; }
    game=${folders[0]%/}
fi
[[ -x $game/run.sh ]] || { echo "$game has no run.sh: not a Linux export"; exit 1; }
game=$(cd "$game" && pwd)
name=$(basename "$game")
image=${IMAGE:-ubuntu:24.04}
platform=${PLATFORM:-}
out=.build/linux-ci/play
rm -rf "$out" && mkdir -p "$out"
tag="sge-linux-play:$(echo "$image${platform:+-$platform}" | tr ':/' '--')"

# Runtime packages only: no -dev packages, no compiler, no Swift, no GLFW.
docker build ${platform:+--platform "$platform"} -t "$tag" - >"$out/docker-build.log" 2>&1 <<EOF || { tail -30 "$out/docker-build.log"; exit 1; }
FROM $image
RUN apt-get update && apt-get install -y --no-install-recommends libvulkan1 libx11-6 libxrandr2 libxinerama1 libxcursor1 libxi6 libxxf86vm1 zlib1g libasound2t64 \
        mesa-vulkan-drivers xvfb xauth && rm -rf /var/lib/apt/lists/*
EOF

docker run --rm ${platform:+--platform "$platform"} \
    -v "$game":/game:ro -v "$PWD/$out":/out \
    -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json \
    -e ENGINE_SCREENSHOT=/out/screenshot.png -e ENGINE_RESOLUTION=720p \
    -e ENGINE_USER_DATA_DIR=/tmp/userdata -e ENGINE_CRASH_DIR=/out/crashes \
    "$tag" bash -c "
ldd /game/$name > /out/ldd.txt 2>&1
if grep -q 'not found' /out/ldd.txt; then echo 'Missing libraries:'; grep 'not found' /out/ldd.txt; exit 1; fi
cp -r /game /tmp/game   # writable copy, as a player would have
xvfb-run -a -s '-screen 0 1280x720x24' timeout 120 /tmp/game/run.sh > /out/run.log 2>&1
status=\$?
tail -20 /out/run.log
exit \$status
" || { echo "FAILED: the game exited with an error (see $out/run.log)"; exit 1; }

[[ -s $out/screenshot.png ]] || { echo "FAILED: no screenshot (see $out/run.log)"; exit 1; }
echo "ok: $name ran on $image; screenshot at $out/screenshot.png"
echo "linked libraries (beyond libc):"
grep -vE 'linux-vdso|ld-linux|libc\.so|libm\.so|libpthread|libdl\.so|librt\.so' "$out/ldd.txt" | sed 's/ (0x.*//; s/^/  /'
