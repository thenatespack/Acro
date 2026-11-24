#!/usr/bin/env bash
# Builds WebGPUSmoke for WebAssembly, assembles a static site (page, wasm + JS glue, engine
# resources, every generated WGSL) and runs it in Playwright's Chromium with WebGPU.
#
#   Spikes/WebGPUSmoke/web/run.sh [mode ...]     modes: msaa (default) fsr1 taau hdr bilinear shaders
#
# SMOKE_OUT=<dir> picks where the site and screenshots go (default: a new temporary directory).
# Needs the swiftly 6.4.2 toolchain with the Wasm SDK (docs/wasm-spike.md), Node, and Playwright
# in ~/.acro-webtools. Installs @bjorn3/browser_wasi_shim (the WASI shim) under .build-wasm/webtools.
set -euo pipefail
cd "$(dirname "$0")/../../.."
out=${SMOKE_OUT:-$(mktemp -d)}
site="$out/site"

ENGINE_WASM=1 ~/.swiftly/bin/swift package --swift-sdk swift-6.4.2-RELEASE_wasm --scratch-path .build-wasm js --product WebGPUSmoke
webtools=.build-wasm/webtools
if [[ ! -d "$webtools/node_modules/@bjorn3/browser_wasi_shim" ]]; then
    mkdir -p "$webtools"
    npm install --prefix "$webtools" --no-save @bjorn3/browser_wasi_shim@0.4.1
fi

rm -rf "$site"
mkdir -p "$site/wgsl"
cp Spikes/WebGPUSmoke/web/index.html Spikes/WebGPUSmoke/web/smoke.js "$site/"
cp -R .build-wasm/plugins/PackageToJS/outputs/Package "$site/pkg"
cp -R .build-wasm/out/Products/Debug-webassembly-wasm32/Acro_EngineCore.bundle "$site/engine"
cp -R "$webtools/node_modules/@bjorn3/browser_wasi_shim/dist" "$site/wasi-shim"
find Sources Tests -name '*.wgsl' | sort | while read -r file; do
    mkdir -p "$site/wgsl/$(dirname "$file")"
    cp "$file" "$site/wgsl/$file"
done
node -e '
const fs = require("fs"), path = require("path");
const list = (root) => { const files = []; const walk = (dir) => { for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const relative = dir ? `${dir}/${entry.name}` : entry.name;
    if (entry.isDirectory()) walk(relative); else files.push(relative); } }; walk(""); return files.sort(); };
fs.writeFileSync(process.argv[1] + "/engine-files.json", JSON.stringify(list(process.argv[1] + "/engine")));
fs.writeFileSync(process.argv[1] + "/wgsl-files.json", JSON.stringify(list(process.argv[1] + "/wgsl")));
' "$site"

node Spikes/WebGPUSmoke/web/shoot.mjs "$site" "$out" "${@:-msaa}"
