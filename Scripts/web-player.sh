#!/usr/bin/env bash
# Builds the browser player (Spikes/WasmPlayer: SampleGame linked in) and serves it with a pack.
#
#   Scripts/web-player.sh <game.pack> [--release] [--port <n>] [--out <dir>] [--no-build] [--no-serve]
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
# Then serves it on http://localhost:<port>/ (default 8080) until Ctrl-C. Open it in a browser
# with WebGPU. Page options: ?scene=<path>, ?args=--opt,value, ?probe=<n> (see Web/index.html).
#
# Environment: SWIFT (default ~/.swiftly/bin/swift), WASM_SDK (default swift-6.4.2-RELEASE_wasm).
set -euo pipefail
cd "$(dirname "$0")/.."

usage() { sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
pack="" configuration=debug port=8080 out=.build-wasm/web-player build=1 serve=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) configuration=release ;;
        --port) port=$2; shift ;;
        --out) out=$2; shift ;;
        --no-build) build=0 ;;
        --no-serve) serve=0 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option $1" >&2; usage ;;
        *) [[ -z "$pack" ]] || usage; pack=$1 ;;
    esac
    shift
done
[[ -n "$pack" ]] || usage
[[ -f "$pack" ]] || { echo "No pack at $pack" >&2; exit 1; }

swift=${SWIFT:-$HOME/.swiftly/bin/swift}
sdk=${WASM_SDK:-swift-6.4.2-RELEASE_wasm}
scratch=.build-wasm
packaged=$scratch/plugins/PackageToJS/outputs/Package
export ENGINE_WASM=1

if [[ $build == 1 ]]; then
    echo "Building and packaging WasmPlayer ($configuration)..."
    mkdir -p "$scratch"
    log=$scratch/web-player-build.log
    if ! "$swift" package --swift-sdk "$sdk" --scratch-path "$scratch" js --product WasmPlayer -c "$configuration" >"$log" 2>&1; then
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
(cd "$out/engine" && find . -type f ! -name Info.plist | sed 's|^\./||' | sort) | python3 -c '
import json, sys
print(json.dumps({"files": [line.strip() for line in sys.stdin if line.strip()]}, indent=1))' > "$out/engine/manifest.json"
cp "$pack" "$out/game.pack"
python3 -c 'import json, sys; print(json.dumps({"wasm": "app/WasmPlayer.wasm", "pack": "game.pack",
    "packName": sys.argv[1], "engine": "engine/manifest.json", "args": []}, indent=1))' "$(basename "$pack")" > "$out/player.json"
echo "Assembled $out ($(du -sh "$out" | cut -f1))"

[[ $serve == 1 ]] || exit 0
echo "Serving $out on http://localhost:$port/ (Ctrl-C to stop)"
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
' "$port" "$out"
