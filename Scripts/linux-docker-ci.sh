#!/usr/bin/env bash
# Runs the steps of .github/workflows/linux.yml locally in Docker (arm64 on Apple silicon,
# amd64 elsewhere): debug build, release build, swift test, and the lavapipe render step.
#
#   Scripts/linux-docker-ci.sh [step...]        steps: build release test render shell (default: all but shell)
#
# SWIFT_IMAGE (default: the workflow's image) picks the toolchain; PLATFORM=linux/amd64 runs
# x86_64 under emulation (slow). The checkout is copied (without .build / .git) into a Docker
# volume, so builds are incremental between runs and never touch the macOS .build folder.
# TEST_FILTER=NetworkingTests limits swift test; SCENES / ENGINE_RESOLUTION as in the workflow.
# Logs land in .build/linux-ci/ and screenshots in .build/linux-ci/shots.
set -euo pipefail
cd "$(dirname "$0")/.."

workflow_image=$(sed -n 's/^ *image: *//p' .github/workflows/linux.yml | head -1)
image=${SWIFT_IMAGE:-${workflow_image:-swift:6.0-noble}}
platform=${PLATFORM:-}
steps=("$@")
[[ ${#steps[@]} -eq 0 ]] && steps=(build release test render)
tag="sge-linux-ci:$(echo "$image${platform:+-$platform}" | tr ':/' '--')"
volume="sge-linux-ci-$(echo "$image${platform:+-$platform}" | tr ':/.' '---')"
out=.build/linux-ci
mkdir -p "$out"

# The workflow's "Install dependencies" step, plus rsync for copying the checkout in.
packages=$(awk '/apt-get install/{f=1} f{print} f&&!/\\$/{exit}' .github/workflows/linux.yml \
    | sed -e 's/.*--no-install-recommends//' -e 's/\\//g' | tr -s ' \n' ' ')
docker build ${platform:+--platform "$platform"} -t "$tag" - >"$out/docker-build.log" 2>&1 <<EOF || { tail -30 "$out/docker-build.log"; exit 1; }
FROM $image
RUN apt-get update && apt-get install -y --no-install-recommends $packages rsync && rm -rf /var/lib/apt/lists/*
EOF

docker run --rm ${platform:+--platform "$platform"} \
    -v "$PWD":/src:ro -v "$volume":/work -v "$PWD/$out":/out \
    -e ENGINE_RESOLUTION="${ENGINE_RESOLUTION:-720p}" \
    -e SCENES="${SCENES-ecs shadows transparency pbr}" \
    -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json \
    -e LIBGL_ALWAYS_SOFTWARE=1 -e ENGINE_CRASH_DIR=/out/crashes \
    -e TEST_FILTER="${TEST_FILTER:-}" -e STEPS="${steps[*]}" \
    ${DOCKER_TTY:+-it} "$tag" bash -c '
set -uo pipefail
rsync -a --delete --exclude /.build --exclude /.git --exclude /.claude /src/ /work/src/
cd /work/src
status=0
run() { # name, command...
    local name=$1; shift
    echo "== $name"
    local start=$SECONDS
    if "$@" >"/out/$name.log" 2>&1; then echo "   ok ($((SECONDS - start)) s)"; else echo "   FAILED ($((SECONDS - start)) s), see .build/linux-ci/$name.log"; tail -25 "/out/$name.log"; status=1; fi
}
swift --version 2>&1 | head -1
for step in $STEPS; do
    case $step in
        build)   run build swift build ;;
        release) run release swift build -c release ;;
        test)    run test xvfb-run -a -s "-screen 0 1280x720x24" swift test ${TEST_FILTER:+--filter "$TEST_FILTER"}
                 grep -E "Test run with|Executed [0-9]+ tests" /out/test.log | tail -3 ;;
        render)  vulkaninfo --summary 2>&1 | grep -E "deviceName|apiVersion|driverName" | head -3
                 rm -rf /out/shots
                 run render xvfb-run -a -s "-screen 0 1280x720x24" Scripts/render-scenes.sh low /out/shots
                 grep -E "^(ok|FAIL|DIFF)" /out/render.log ;;
        shell)   bash ;;
        *)       echo "unknown step $step"; status=1 ;;
    esac
done
exit $status
'
