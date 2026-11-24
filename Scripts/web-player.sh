#!/usr/bin/env bash
# Builds the browser player (Spikes/WasmPlayer: SampleGame linked in) and serves it with a pack.
#
#   Scripts/web-player.sh <game.pack> [--release] [--port <n>] [--out <dir>] [--no-build] [--no-serve]
#   Scripts/web-player.sh --demo [same options]     the Demo app's scenes instead (no pack)
#   Scripts/web-player.sh --export <project> [--release] [--port <n>] [--out <dir>] [--no-serve]
#
# Builds with the Swift Wasm SDK (ENGINE_WASM=1, see docs/wasm-spike.md), packages the wasm with
# JavaScriptKit's PackageToJS plugin, and assembles a static site in <dir> (default
# .build-wasm/web-player):
#
#   index.html, loader.js   from Web/
#   app/                    PackageToJS output (WasmPlayer.wasm, instantiate.js, runtime.js, ...)
#   vendor/browser_wasi_shim/   the WASI shim (npm package, cached in .build-wasm/web-deps)
#   engine/                 the engine resources (Acro_EngineCore.bundle) and engine/manifest.json
#   game.pack, player.json  the pack, and what the loader fetches
#
# --export <project> instead exports the project the way the editor's Web export does
# (`Editor --build-game <project> --platform web`, GameExporterWeb.swift): the project's own game
# code and scenes in a generated player package rather than the spike's WasmPlayer (SampleGame
# linked in) with a pack you cooked, wasm-opt in release, only the WGSL shaders and fonts of the
# engine resources, and a README.txt. Same layout. The folder is <dir>/<project name>/ (default
# dir .build-wasm/web-export).
#
# Then serves it on http://localhost:<port>/ (default 8080) until Ctrl-C. Open it in a browser
# with WebGPU. Page options: ?scene=<path>, ?args=--opt,value, ?env=NAME=value, ?probe=<n>
# (see Web/index.html). With --demo the page runs the Demo product (its resources mounted at
# /demo) and ?args=--scene,<name or number> picks the scene; default out .build-wasm/web-demo.
#
# Environment: SWIFT (default ~/.swiftly/bin/swift), WASM_SDK (default swift-6.4.2-RELEASE_wasm).
set -euo pipefail
cd "$(dirname "$0")/.."

usage() { sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
pack="" configuration=debug port=8080 out="" build=1 serve=1 demo=0 project=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) configuration=release ;;
        --export) project=$2; shift ;;
        --port) port=$2; shift ;;
        --out) out=$2; shift ;;
        --no-build) build=0 ;;
        --no-serve) serve=0 ;;
        --demo) demo=1 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option $1" >&2; usage ;;
        *) [[ -z "$pack" ]] || usage; pack=$1 ;;
    esac
    shift
done
serve() {
    [[ $serve == 1 ]] || exit 0
    echo "Serving $1 on http://localhost:$port/ (Ctrl-C to stop)"
    exec python3 -c '
import http.server, sys
class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".js": "text/javascript"}
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, *args): pass
port, root = int(sys.argv[1]), sys.argv[2]
http.server.ThreadingHTTPServer(("127.0.0.1", port), lambda *a: Handler(*a, directory=root)).serve_forever()
' "$port" "$1"
}

if [[ -n "$project" ]]; then
    [[ -z "$pack" ]] || usage
    [[ -d "$project" ]] || { echo "No project at $project" >&2; exit 1; }
    out=${out:-.build-wasm/web-export}
    mkdir -p "$(dirname "$out")"
    echo "Building the editor..."
    swift build --product Editor >/dev/null
    editor=$(swift build --show-bin-path)/Editor
    "$editor" --build-game "$project" --platform web --config "$configuration" --out "$out" | tee "$out.log"
    serve "$(tail -1 "$out.log")"
fi

if [[ $demo == 1 ]]; then
    [[ -z "$pack" ]] || usage
    product=Demo out=${out:-.build-wasm/web-demo}
else
    [[ -n "$pack" ]] || usage
    [[ -f "$pack" ]] || { echo "No pack at $pack" >&2; exit 1; }
    product=WasmPlayer out=${out:-.build-wasm/web-player}
fi

swift=${SWIFT:-$HOME/.swiftly/bin/swift}
sdk=${WASM_SDK:-swift-6.4.2-RELEASE_wasm}
scratch=.build-wasm
packaged=$scratch/plugins/PackageToJS/outputs/Package
export ENGINE_WASM=1

if [[ $build == 1 ]]; then
    echo "Building and packaging $product ($configuration)..."
    mkdir -p "$scratch"
    log=$scratch/web-player-build.log
    if ! "$swift" package --swift-sdk "$sdk" --scratch-path "$scratch" js --product "$product" -c "$configuration" >"$log" 2>&1; then
        grep -E 'error:' "$log" >&2 || tail -30 "$log" >&2
        echo "Building or packaging failed (full log: $log)" >&2
        exit 1
    fi
fi
bin=$("$swift" build --swift-sdk "$sdk" --scratch-path "$scratch" -c "$configuration" --show-bin-path)
resources=$bin/Acro_EngineCore.bundle
[[ -d $resources ]] || { echo "No engine resources at $resources (build first)" >&2; exit 1; }

# The WASI shim the PackageToJS output was made for, fetched once.
shim_version=$(sed -n 's/.*"@bjorn3\/browser_wasi_shim": *"\([^"]*\)".*/\1/p' "$packaged/package.json")
deps=$scratch/web-deps/browser_wasi_shim-$shim_version
if [[ ! -f $deps/node_modules/@bjorn3/browser_wasi_shim/dist/index.js ]]; then
    echo "Fetching @bjorn3/browser_wasi_shim@$shim_version..."
    mkdir -p "$deps"
    npm install --prefix "$deps" --no-save --no-package-lock --silent "@bjorn3/browser_wasi_shim@$shim_version"
fi

rm -rf "$out"
mkdir -p "$out/app" "$out/vendor" "$out/engine"
cp Web/index.html Web/loader.js "$out/"
cp -R "$packaged/." "$out/app/"
cp -R "$deps/node_modules/@bjorn3/browser_wasi_shim/dist" "$out/vendor/browser_wasi_shim"
cp -R "$resources/." "$out/engine/"
# Everything under engine/ but Info.plist and the manifest itself, relative to engine/.
manifest() {
    (cd "$1" && find . -type f ! -name Info.plist ! -name manifest.json | sed 's|^\./||' | sort) | python3 -c '
import json, sys
print(json.dumps({"files": [line.strip() for line in sys.stdin if line.strip()]}, indent=1))' > "$1/manifest.json"
}
manifest "$out/engine"
if [[ $demo == 1 ]]; then
    mkdir -p "$out/demo"
    cp -R "$bin/Acro_Demo.bundle/." "$out/demo/"
    manifest "$out/demo"
    python3 -c 'import json; print(json.dumps({"wasm": "app/Demo.wasm", "pack": None, "engine": "engine/manifest.json",
        "mounts": {"demo": "demo/manifest.json"}, "args": []}, indent=1))' > "$out/player.json"
else
    cp "$pack" "$out/game.pack"
    # packSize / wasmSize: totals for the page's progress bar; packHash (the pack header's): its key in the browser's cache.
    python3 -c 'import json, os, sys
header = open(sys.argv[2], "rb").read(48)
print(json.dumps({"wasm": "app/WasmPlayer.wasm", "pack": "game.pack", "packName": sys.argv[1], "engine": "engine/manifest.json",
    "args": [], "packSize": os.path.getsize(sys.argv[2]), "packHash": header[32:48].decode("ascii"),
    "wasmSize": os.path.getsize(sys.argv[3])}, indent=1))' "$(basename "$pack")" "$out/game.pack" "$out/app/WasmPlayer.wasm" > "$out/player.json"
fi
echo "Assembled $out ($(du -sh "$out" | cut -f1))"

serve "$out"
