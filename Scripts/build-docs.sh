#!/usr/bin/env bash
# Builds the Engine API documentation with DocC as a static website.
#
#   Scripts/build-docs.sh [output-dir]         (default .build/docs)
#   Scripts/build-docs.sh --preview            serve it locally at http://localhost:8080/documentation/engine
#
# No package plugin is needed: the Engine target's symbol graph comes from `swift build`, and
# the toolchain's `docc` (xcrun docc on macOS) turns it plus Sources/Engine/Engine.docc into a
# site. Set DOCS_HOSTING_BASE_PATH for a site served below the domain root (GitHub Pages
# project sites use the repository name, e.g. Acro).
set -euo pipefail

cd "$(dirname "$0")/.."
CATALOG=Sources/Engine/Engine.docc
SCRATCH=.build/docs-build
# Written by the compiler, so they stay next to the build they came from: an up-to-date build
# compiles nothing and writes no new graphs.
GRAPHS=$SCRATCH/symbol-graphs
ENGINE_GRAPHS=$SCRATCH/symbol-graphs-engine

if [ "$(uname)" = Darwin ]; then DOCC=(xcrun docc); else DOCC=(docc); fi

preview=0
if [ "${1:-}" = --preview ]; then preview=1; shift; fi
OUT=${1:-.build/docs}

build_engine() {
    mkdir -p "$GRAPHS"
    # The native build system: Swift Build ignores -emit-symbol-graph-dir, and `swift package
    # dump-symbol-graph` also extracts the C++ targets, which fails. A separate scratch path
    # keeps this build from mixing with the regular one.
    swift build --build-system native --scratch-path "$SCRATCH" -c release --target Engine \
        -Xswiftc -emit-symbol-graph \
        -Xswiftc -emit-symbol-graph-dir -Xswiftc "$PWD/$GRAPHS" \
        -Xswiftc -symbol-graph-minimum-access-level -Xswiftc public
}

echo "Building Engine and its symbol graph..."
build_engine
if [ ! -f "$GRAPHS/Engine.symbols.json" ]; then
    echo "No symbol graph from the cached build; rebuilding from scratch..."
    rm -rf "$SCRATCH"
    build_engine
fi
# Only Engine's graphs (Engine.symbols.json, plus Engine@<Module> for its extensions of other
# modules' types); the vendored C modules' graphs would add their headers as pages.
rm -rf "$ENGINE_GRAPHS"
mkdir -p "$ENGINE_GRAPHS"
cp "$GRAPHS"/Engine.symbols.json "$ENGINE_GRAPHS"/
for f in "$GRAPHS"/Engine@*.symbols.json; do [ -e "$f" ] && cp "$f" "$ENGINE_GRAPHS"/; done

common=(--additional-symbol-graph-dir "$ENGINE_GRAPHS"
        --fallback-display-name Engine
        --fallback-bundle-identifier dev.acro.Engine)

if [ "$preview" = 1 ]; then
    exec "${DOCC[@]}" preview "$CATALOG" "${common[@]}"
fi

echo "Converting with DocC..."
rm -rf "$OUT"
hosting=()
if [ -n "${DOCS_HOSTING_BASE_PATH:-}" ]; then hosting=(--hosting-base-path "$DOCS_HOSTING_BASE_PATH"); fi
"${DOCC[@]}" convert "$CATALOG" "${common[@]}" \
    --transform-for-static-hosting ${hosting[@]+"${hosting[@]}"} \
    --output-path "$OUT"

# The site's root sends visitors to the Engine module's page.
base=${DOCS_HOSTING_BASE_PATH:+/$DOCS_HOSTING_BASE_PATH}
cat > "$OUT/index.html" <<EOF
<!doctype html>
<meta charset="utf-8">
<title>Acro Engine documentation</title>
<meta http-equiv="refresh" content="0; url=$base/documentation/engine/">
<a href="$base/documentation/engine/">Acro Engine documentation</a>
EOF
echo "Documentation written to $OUT (entry: $OUT/documentation/engine/index.html)"
