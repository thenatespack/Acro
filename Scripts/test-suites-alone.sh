#!/bin/bash
# Runs every test suite on its own (`swift test --filter '<Suite>'`) and reports the ones that
# fail. A suite that passes in the full run but fails alone depends on state another suite set
# up (a component registration, a global). Usage: Scripts/test-suites-alone.sh [suite-regex]
cd "$(dirname "$0")/.." || exit 1
swift build --build-tests >/dev/null 2>&1 || { echo "build failed"; exit 1; }
log=$(mktemp)
suites=$(swift test list 2>/dev/null | sed -n 's|^\([A-Za-z0-9_]*\.[A-Za-z0-9_]*\)/.*|\1|p' | sort -u)
[ -n "$1" ] && suites=$(echo "$suites" | grep -E "$1")
failed=()
for s in $suites; do
  if swift test --skip-build --filter "^$s/" >"$log" 2>&1; then
    echo "ok    $s"
  else
    echo "FAIL  $s"; failed+=("$s")
    grep -E "✘|error:" "$log" | head -5
  fi
done
rm -f "$log"
echo; echo "${#failed[@]} failing suite(s)"
for s in "${failed[@]}"; do echo "  $s"; done
[ ${#failed[@]} -eq 0 ]
