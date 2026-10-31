#!/usr/bin/env bash
# Compares screenshots with reference ("golden") images, within a tolerance.
#
#   Scripts/compare-golden.sh <golden-dir> <shots-dir> [glob]
#   Scripts/compare-golden.sh --update <golden-dir> <shots-dir> [glob]
#
# Every <shots-dir>/<name>.png matching glob (default *) is compared with
# <golden-dir>/<name>.png using Scripts/png-diff.py: it passes when the mean difference is at
# most GOLDEN_MEAN (default 2.0, in 0-255 units) and at most GOLDEN_FRACTION (default 0.02) of
# the pixels differ by more than 16 in some channel. Metal and Vulkan are byte-identical on the
# same GPU (render-scenes.sh checks that), but software Vulkan (lavapipe) or another GPU
# rounds differently, so goldens are kept per platform and backend and compared by tolerance.
# A shot without a golden is skipped (a failure with GOLDEN_STRICT=1). --update copies the
# shots into the golden dir instead (new baselines). Differing shots are copied next to the
# shots as <name>.golden.png so a CI artifact upload has both.
# Needs python3 (standard library only).
set -euo pipefail
cd "$(dirname "$0")/.."

update=0
if [[ "${1:-}" == --update ]]; then
    update=1
    shift
fi
golden=${1:?usage: compare-golden.sh [--update] <golden-dir> <shots-dir> [glob]}
shots=${2:?usage: compare-golden.sh [--update] <golden-dir> <shots-dir> [glob]}
glob=${3:-*}

if [[ $update == 1 ]]; then
    mkdir -p "$golden"
    for shot in "$shots"/$glob.png; do
        [[ -e "$shot" ]] || continue
        [[ "$shot" == *.golden.png ]] && continue
        cp "$shot" "$golden/"
        echo "updated $(basename "$shot")"
    done
    exit 0
fi

status=0
for shot in "$shots"/$glob.png; do
    [[ -e "$shot" ]] || continue
    [[ "$shot" == *.golden.png ]] && continue
    name=$(basename "$shot" .png)
    if [[ ! -f "$golden/$name.png" ]]; then
        if [[ "${GOLDEN_STRICT:-0}" == 1 ]]; then
            echo "FAIL  $name: no golden image"
            status=1
        else
            echo "skip  $name: no golden image"
        fi
        continue
    fi
    if result=$(python3 Scripts/png-diff.py --mean "${GOLDEN_MEAN:-2.0}" --fraction "${GOLDEN_FRACTION:-0.02}" \
        "$golden/$name.png" "$shot"); then
        echo "ok    $name: $result"
    else
        echo "FAIL  $name: $result"
        cp "$golden/$name.png" "$shots/$name.golden.png"
        status=1
    fi
done
exit $status
