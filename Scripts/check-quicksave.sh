#!/usr/bin/env bash
# Drives the `character` scene's quick save / load with injected input (DEMO_INPUT_SCRIPT) in
# a screenshot run, with ENGINE_USER_DATA_DIR in a temporary folder: F5 after half a second,
# then A for 1.5 s (the character walks into the crates and pushes them), then F9. The scene
# prints where the character and crates are a few steps after the load; this fails unless
# they are back where they were saved.
#
#   Scripts/check-quicksave.sh [backend]     (default: metal on macOS, vulkan elsewhere)
set -euo pipefail
cd "$(dirname "$0")/.."

backend=${1:-$([[ "$(uname)" == Darwin ]] && echo metal || echo vulkan)}
swift build -c release --product Demo >/dev/null
demo="$(swift build -c release --show-bin-path)/Demo"
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

script='[{"mouseBy": [0, 0], "wait": 0.5}, {"key": "f5", "wait": 0.2}, {"key": "a", "duration": 1.5},
         {"mouseBy": [0, 0], "wait": 0.5}, {"key": "f9"}]'
ENGINE_USER_DATA_DIR="$dir" DEMO_INPUT_SCRIPT="$script" ENGINE_OVERLAY=0 ENGINE_SCREENSHOT="$dir/quicksave.png" \
    ENGINE_SCREENSHOT_FRAME=240 "$demo" --scene character --quality low --backend "$backend" >"$dir/log" 2>&1
grep "^Character:" "$dir/log" || true
[[ -f "$dir/saves/quick.save.json" ]] || { echo "FAIL  no quick save was written"; exit 1; }
error=$(sed -n 's/.*largest distance from the save \([0-9.]*\) m$/\1/p' "$dir/log")
[[ -n "$error" ]] || { echo "FAIL  the scene never reported the load"; exit 1; }
if awk -v e="$error" 'BEGIN { exit !(e < 0.01) }'; then
    echo "ok    quick load put everything back (largest distance $error m)"
else
    echo "FAIL  after the quick load something is $error m from where it was saved"
    exit 1
fi
