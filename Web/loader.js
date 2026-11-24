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
//    Saves and settings live in /userdata, kept in IndexedDB (saves.js).
// 4. Runs the player's main, which starts the game and returns; frames then come from
//    requestAnimationFrame (`WebFrameDriver` in Swift). Errors show on the page and console.
import { WASI, File, Directory, PreopenDirectory, OpenFile, ConsoleStdout } from "@bjorn3/browser_wasi_shim";
import { instantiate } from "./app/instantiate.js";
import { openUserData } from "./saves.js";

class PlayerError extends Error {}

/**
 * Starts the player.
 * @param {{ canvas: HTMLCanvasElement, status: HTMLElement, args?: string[], env?: string[],
 *           probeFrames?: number, base?: string }} options
 * `env` adds `NAME=value` environment variables (ENGINE_OVERLAY=1, ENGINE_QUALITY=high, ...).
 */
export async function startPlayer({ canvas, status, args = [], env = [], probeFrames = 0, base = "." }) {
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
    // `mounts` (optional): more folders for the WASI filesystem, { "<name>": "<manifest.json>" }
    // mounted at /<name> (the Demo's resources, say). A player without a pack has `pack: null`.
    const mounts = Object.entries(config.mounts ?? {});
    const [userData, pack, engineFiles, ...mounted] = await Promise.all([
      openUserData(),  // saves and settings, from IndexedDB (saves.js)
      config.pack ? fetchBytes(url(config.pack)) : undefined,
      fetchFolder(url(config.engine)),
      ...mounts.map(([, manifest]) => fetchFolder(url(manifest))),
    ]);

    Object.assign(globalThis.acro, {
      args: [...(config.args ?? []), ...args],
      pack,
      packName: config.packName ?? "Game.pack",
      probeFrames,
      onError: (message) => fail(message),
      // The engine wrote or removed a file under /userdata: keep it in IndexedDB.
      onUserDataChange: () => userData.persist(),
      // (An error stays on screen.)
      onExit: (code) => { if (!status.classList.contains("error")) show(code === 0 ? "The game has ended." : `The game exited (${code}).`); },
      // Screenshots (ENGINE_SCREENSHOT, Engine.saveScreenshot) as PNG data URLs, by path.
      screenshots: {},
      onScreenshot: (path, width, height, rgba) => {
        const canvas2D = document.createElement("canvas");
        canvas2D.width = width;
        canvas2D.height = height;
        canvas2D.getContext("2d").putImageData(new ImageData(new Uint8ClampedArray(rgba), width, height), 0, 0);
        globalThis.acro.screenshots[path] = canvas2D.toDataURL("image/png");
        console.log(`[acro] screenshot ${path} (${width}x${height})`);
      },
    });

    show("Starting the game…");
    const wasi = new WASI(
      [config.wasm], [`ENGINE_RESOURCES=/engine`, `TMPDIR=/tmp`, ...(config.env ?? []), ...env],
      [
        new OpenFile(new File([])),  // stdin
        ConsoleStdout.lineBuffered((line) => console.log(line)),
        ConsoleStdout.lineBuffered((line) => console.error(line)),
        // /tmp: an empty, writable folder in memory (temporary files; gone with the page).
        new PreopenDirectory("/", new Map([["engine", engineFiles], ["tmp", new Directory(new Map())], ["userdata", userData.directory],
                                           ...mounts.map(([name], i) => [name, mounted[i]])])),
      ],
      { debug: false },
    );
    // The shim answers poll_oneoff (sleeps, timed waits) by spinning: nothing in the engine
    // should call it in a browser, so say so when something does.
    const poll = wasi.wasiImport.poll_oneoff;
    let polls = 0;
    wasi.wasiImport.poll_oneoff = (...args) => {
      if (polls++ === 0) console.warn("[acro] poll_oneoff called: something waited on the browser's main thread");
      return poll(...args);
    };
    // The shim's directory entries all have inode 0, which wasi-libc's readdir callers (Swift's
    // FileManager) skip as deleted: every folder would list empty. Give each a nonzero one.
    const readdir = wasi.wasiImport.fd_readdir;
    wasi.wasiImport.fd_readdir = (fd, buf, length, cookie, usedPtr) => {
      const result = readdir(fd, buf, length, cookie, usedPtr);
      const view = new DataView(wasi.inst.exports.memory.buffer);
      const end = buf + view.getUint32(usedPtr, true);
      // Entries: d_next u64, d_ino u64, d_namlen u32, d_type u8 (24 bytes), then the name.
      for (let p = buf; p + 24 <= end; p += 24 + view.getUint32(p + 16, true)) {
        if (view.getBigUint64(p + 8, true) === 0n) view.setBigUint64(p + 8, view.getBigUint64(p, true), true);
      }
      return result;
    };
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
  // Every feature the adapter has (texture compression, timestamp queries, the storage texture
  // tiers...): the engine checks `device.features` for what it can use.
  const requiredFeatures = [...adapter.features];
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
