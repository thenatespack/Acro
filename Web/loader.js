// The browser loader for an exported Acro game (docs/wasm-spike.md, wave W1B).
//
// 1. Gets a WebGPU adapter and device, configures the canvas, and publishes them as
//    `globalThis.acro = { adapter, device, context, format, canvas }` (the WebGPU render device
//    reads them synchronously; WebGPU's requests are Promises and the engine starts synchronously).
// 2. Fetches `player.json` (written by Scripts/web-player.sh), the asset pack and the engine
//    resources (Shaders/, Fonts/ listed in engine/manifest.json).
// 3. Instantiates the wasm (packaged by JavaScriptKit's PackageToJS) with a WASI shim whose
//    in-memory filesystem holds the engine resources at /engine (ENGINE_RESOURCES), so Swift
//    reads them by URL as usual. The pack goes to Swift as a Uint8Array (`acro.pack`), opened
//    with `AssetPack(data:)`.
// 4. Runs the player's main, which starts the game and returns; frames then come from
//    requestAnimationFrame (`WebFrameDriver` in Swift). Errors show on the page and console.
import { WASI, File, Directory, PreopenDirectory, OpenFile, ConsoleStdout } from "@bjorn3/browser_wasi_shim";
import { instantiate } from "./app/instantiate.js";

/** Features the engine uses when the adapter has them (the device asks for no others). */
const optionalFeatures = [
  "texture-compression-bc", "texture-compression-astc", "texture-compression-etc2", "float32-filterable",
  "rg11b10ufloat-renderable", "timestamp-query", "depth32float-stencil8", "indirect-first-instance",
  "shader-f16", "bgra8unorm-storage", "depth-clip-control", "float32-blendable", "clip-distances",
  "dual-source-blending",
];

class PlayerError extends Error {}

/**
 * Starts the player.
 * @param {{ canvas: HTMLCanvasElement, status: HTMLElement, args?: string[], probeFrames?: number,
 *           base?: string }} options
 */
export async function startPlayer({ canvas, status, args = [], probeFrames = 0, base = "." }) {
  const show = (text) => { status.hidden = false; status.className = ""; status.textContent = text; };
  const fail = (text) => {
    status.hidden = false;
    status.className = "error";
    status.textContent = text;
    console.error(`[acro] ${text}`);
  };
  // Traps (Swift runtime errors) from frame callbacks surface as uncaught errors.
  addEventListener("error", (event) => fail(`The game stopped: ${event.message}`));
  addEventListener("unhandledrejection", (event) => fail(`The game stopped: ${event.reason}`));

  try {
    show("Starting WebGPU…");
    const gpu = await setUpWebGPU(canvas);
    // Exactly this shape: the WebGPU render device reads these.
    globalThis.acro = { adapter: gpu.adapter, device: gpu.device, context: gpu.context, format: gpu.format, canvas };
    gpu.device.lost.then((info) => {
      if (info.reason !== "destroyed") fail(`The GPU device was lost: ${info.message}`);
    });

    show("Loading…");
    const url = (path) => new URL(path, new URL(`${base}/`, location.href));
    const config = await fetchJSON(url("player.json"));
    const [pack, engineFiles] = await Promise.all([
      fetchBytes(url(config.pack)),
      fetchFolder(url(config.engine)),
    ]);

    Object.assign(globalThis.acro, {
      args: [...(config.args ?? []), ...args],
      pack,
      packName: config.packName ?? "Game.pack",
      probeFrames,
      onError: (message) => fail(message),
      // (An error stays on screen.)
      onExit: (code) => { if (!status.classList.contains("error")) show(code === 0 ? "The game has ended." : `The game exited (${code}).`); },
    });

    show("Starting the game…");
    const wasi = new WASI(
      [config.wasm], [`ENGINE_RESOURCES=/engine`],
      [
        new OpenFile(new File([])),  // stdin
        ConsoleStdout.lineBuffered((line) => console.log(line)),
        ConsoleStdout.lineBuffered((line) => console.error(line)),
        new PreopenDirectory("/", new Map([["engine", engineFiles]])),
      ],
      { debug: false },
    );
    // instantiate() runs `main`: it returns once the game has started (or failed: onError).
    await instantiate({ module: fetch(url(config.wasm)), wasi });
    if (!status.classList.contains("error")) status.hidden = true;
  } catch (error) {
    fail(error instanceof PlayerError ? error.message : `The game failed to start: ${error?.stack ?? error}`);
  }
}

async function setUpWebGPU(canvas) {
  if (!navigator.gpu) {
    throw new PlayerError("This browser doesn't support WebGPU, which the game needs.\n\n" +
      "Use a recent Chrome or Edge, or Safari 26 or later, and make sure hardware acceleration is on.");
  }
  const adapter = await navigator.gpu.requestAdapter({ powerPreference: "high-performance" });
  if (!adapter) throw new PlayerError("WebGPU is available, but no suitable GPU adapter was found.");
  const requiredFeatures = optionalFeatures.filter((name) => adapter.features.has(name));
  // The adapter's own limits, so the engine isn't held to WebGPU's conservative defaults.
  const requiredLimits = {};
  for (const name in adapter.limits) {
    if (typeof adapter.limits[name] === "number") requiredLimits[name] = adapter.limits[name];
  }
  let device;
  try {
    device = await adapter.requestDevice({ requiredFeatures, requiredLimits });
  } catch (error) {
    console.warn(`[acro] requestDevice with the adapter's limits failed (${error}); using the defaults`);
    device = await adapter.requestDevice({ requiredFeatures });
  }
  device.addEventListener("uncapturederror", (event) => console.error(`[acro] WebGPU: ${event.error.message}`));

  const context = canvas.getContext("webgpu");
  if (!context) throw new PlayerError("The canvas has no WebGPU context.");
  const format = navigator.gpu.getPreferredCanvasFormat();
  const scale = devicePixelRatio || 1;
  canvas.width = Math.max(1, Math.round(canvas.clientWidth * scale));
  canvas.height = Math.max(1, Math.round(canvas.clientHeight * scale));
  context.configure({
    device, format, alphaMode: "opaque",
    usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
  });
  return { adapter, device, context, format };
}

async function fetchOK(url) {
  const response = await fetch(url);
  if (!response.ok) throw new PlayerError(`Couldn't load ${url.pathname}: ${response.status} ${response.statusText}`);
  return response;
}

async function fetchJSON(url) { return (await fetchOK(url)).json(); }

async function fetchBytes(url) { return new Uint8Array(await (await fetchOK(url)).arrayBuffer()); }

/** The files a manifest lists (`{ "files": ["Shaders/a.spv", ...] }`, relative to it), as a read-only WASI directory. */
async function fetchFolder(manifestURL) {
  const { files } = await fetchJSON(manifestURL);
  const root = new Directory(new Map());
  await Promise.all(files.map(async (path) => {
    const data = await fetchBytes(new URL(path, manifestURL));
    const parts = path.split("/");
    let folder = root;
    for (const name of parts.slice(0, -1)) {
      let next = folder.contents.get(name);
      if (!next) { next = new Directory(new Map()); folder.contents.set(name, next); }
      folder = next;
    }
    folder.contents.set(parts.at(-1), new File(data, { readonly: true }));
  }));
  return root;
}
