#!/usr/bin/env bash
# Builds the release browser player (Spikes/WasmPlayer: SampleGame linked in), strips it and
# prints its sizes; fails when one is over budget (see docs/wasm-spike.md, "Size").
#
#   Scripts/wasm-size.sh [--no-build] [--wasm-opt]
#
# --no-build measures the last build. --wasm-opt also measures `wasm-opt -Oz` (binaryen, `brew
# install binaryen`), for information: the budgets apply to the plain stripped module.
#
# The budgets are the measured sizes plus about 10%. Raise them on purpose, not to get a red run
# green. A jump of tens of MB in the data section usually means something under Sources/Engine*
# imports Foundation instead of WASIFoundation on WASI, which links ICU's data back in; the check
# for ICU below names that case.
#
# Environment: SWIFT (default ~/.swiftly/bin/swift), WASM_SDK (default swift-6.4.2-RELEASE_wasm),
# LLVM_BIN (default: the 6.4.2 toolchain's usr/bin, for llvm-objcopy and llvm-objdump).
set -euo pipefail
cd "$(dirname "$0")/.."

# Budgets in bytes (decimal MB).
budget_stripped=$((33 * 1000 * 1000))
budget_gzip=$((10600 * 1000))
budget_brotli=$((6700 * 1000))
budget_data=$((3900 * 1000))

build=1 opt=0
for arg in "$@"; do
    case "$arg" in
        --no-build) build=0 ;;
        --wasm-opt) opt=1 ;;
        *) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
    esac
done

swift=${SWIFT:-$HOME/.swiftly/bin/swift}
sdk=${WASM_SDK:-swift-6.4.2-RELEASE_wasm}
llvm=${LLVM_BIN:-$HOME/Library/Developer/Toolchains/swift-6.4.2-RELEASE.xctoolchain/usr/bin}
for tool in llvm-objcopy llvm-objdump; do
    [[ -x $llvm/$tool ]] || { echo "No $tool in $llvm (set LLVM_BIN)" >&2; exit 1; }
done
command -v brotli >/dev/null || { echo "brotli is needed (brew install brotli)" >&2; exit 1; }

if (( build )); then
    ENGINE_WASM=1 "$swift" build -c release --swift-sdk "$sdk" --scratch-path .build-wasm --product WasmPlayer
fi
wasm=.build-wasm/out/Products/Release-webassembly-wasm32/WasmPlayer.wasm
[[ -f $wasm ]] || wasm=.build-wasm/release/WasmPlayer.wasm
[[ -f $wasm ]] || { echo "No release WasmPlayer.wasm (build first)" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
stripped=$tmp/WasmPlayer.wasm
"$llvm/llvm-objcopy" --strip-all "$wasm" "$stripped"

size() { wc -c < "$1" | tr -d ' '; }
section() { "$llvm/llvm-objdump" -h "$1" | awk -v name="$2" '$2 == name { print $3 }'; }
mb() { awk -v b="$1" 'BEGIN { printf "%.1f MB", b / 1000000 }'; }

status=0
report() {  # label file
    local file=$2 bytes gz br code data
    bytes=$(size "$file")
    gz=$(gzip -9 -c "$file" | wc -c | tr -d ' ')
    br=$(brotli -q 11 -c "$file" | wc -c | tr -d ' ')
    code=$((16#$(section "$file" CODE)))
    data=$((16#$(section "$file" DATA)))
    printf '%-22s stripped %9s   gzip %9s   brotli %9s   code %9s   data %9s\n' \
        "$1" "$(mb "$bytes")" "$(mb "$gz")" "$(mb "$br")" "$(mb "$code")" "$(mb "$data")"
    if [[ $1 == WasmPlayer.wasm ]]; then
        over() { if (( $2 > $3 )); then echo "Over budget: $1 is $(mb "$2"), the budget is $(mb "$3")" >&2; status=1; fi; }
        over stripped "$bytes" "$budget_stripped"
        over gzip "$gz" "$budget_gzip"
        over brotli "$br" "$budget_brotli"
        over data "$data" "$budget_data"
    fi
}

report WasmPlayer.wasm "$stripped"
if grep -q icudt "$stripped"; then
    echo "ICU's data is linked in: something imports Foundation on WASI (use WASIFoundation, see Package.swift)" >&2
    status=1
fi
if (( opt )); then
    if command -v wasm-opt >/dev/null; then
        # The features the Swift SDK's output uses.
        wasm-opt -Oz --enable-bulk-memory --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
            --enable-simd --enable-reference-types --enable-multivalue "$stripped" -o "$tmp/opt.wasm"
        report "wasm-opt -Oz" "$tmp/opt.wasm"
    else
        echo "wasm-opt not found (brew install binaryen)" >&2
    fi
fi
exit $status
