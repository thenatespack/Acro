// The browser loader for an exported Acro game (docs/wasm-spike.md, wave W1B).
//
// 1. Fetches `player.json` (written by the Web export or Scripts/web-player.sh) and picks the
//    renderer: `?renderer=webgpu|webgl2|auto`, else the player's saved choice (localStorage
//    `acro.renderer`, set by `acro.setRenderer`), else player.json's `renderer` (default `auto`).
//    `auto` is WebGPU when an adapter and a device come up, else WebGL 2; a renderer that fails
//    falls back to the other (the console says why), and the page shows an error only when
//    neither works. It publishes the result as `globalThis.acro`: `renderer` ("webgpu" or
//    "webgl2") and `canvas`, with `adapter`, `device`, `context`, `format` for WebGPU or `gl` and
//    `webgl` (Web/webgl2.js) for WebGL 2, plus `renderers` (what this browser seems to have) and
//    `setRenderer(name)` (saves the choice and reloads). The render device reads them
//    synchronously (WebGPU's requests are Promises and the engine starts synchronously).
// 2. Fetches the asset pack
//    and the engine resources (Shaders/, Fonts/ listed in engine/manifest.json). The pack and the
//    wasm download together under a progress bar; the pack is kept in the browser's cache (Cache
//    API, keyed by `packHash`) so the next visit doesn't download it again (wave W2.5B).
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
import { setUpWebGL2 } from "./webgl2.js";

class PlayerError extends Error {}

const RENDERERS = ["webgpu", "webgl2"];
const RENDERER_KEY = "acro.renderer";

/**
 * Starts the player.
 * @param {{ canvas: HTMLCanvasElement, status: HTMLElement, args?: string[], env?: string[],
 *           probeFrames?: number, base?: string, renderer?: string }} options
 * `env` adds `NAME=value` environment variables (ENGINE_OVERLAY=1, ENGINE_QUALITY=high, ...).
 * `renderer` ("webgpu", "webgl2" or "auto", from `?renderer=`) overrides the saved and configured choice.
 */
export async function startPlayer({ canvas, status, args = [], env = [], probeFrames = 0, base = ".", renderer = undefined }) {
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
    show("Loading…");
    const url = (path) => new URL(path, new URL(`${base}/`, location.href));
    const config = await fetchJSON(url("player.json"));

    let wasi;
    const graphics = await setUpRenderer(canvas, pickRenderer(renderer, config.renderer), show);
    canvas = graphics.canvas;
    // The render devices read these (WebGPURenderDevice, WebGL2RenderDevice).
    globalThis.acro = {
      ...graphics,
      // WebGL 2: Web/webgl2.js reads its commands and data straight from the WebAssembly memory.
      wasmMemory: () => wasi.inst.exports.memory.buffer,
      // Saves `name` ("webgpu", "webgl2" or "auto") as the player's choice and reloads the page with it.
      setRenderer: (name) => {
        if (![...RENDERERS, "auto"].includes(name)) throw new Error(`[acro] unknown renderer '${name}'`);
        try {
          if (name === "auto") localStorage.removeItem(RENDERER_KEY); else localStorage.setItem(RENDERER_KEY, name);
        } catch (error) {
          console.warn(`[acro] couldn't save the renderer choice: ${error}`);
        }
        const next = new URL(location.href);
        if (next.searchParams.has("renderer")) {
          next.searchParams.set("renderer", name);
          location.assign(next);
        } else {
          location.reload();
        }
      },
    };
    if (graphics.renderer === "webgpu") {
      graphics.device.lost.then((info) => {
        if (info.reason !== "destroyed") fail(`The GPU device was lost: ${info.message}`);
      });
    } else {
      canvas.addEventListener("webglcontextlost", () => fail("The WebGL context was lost (the GPU was reset or reclaimed)."));
    }

    // The pack and the wasm download together, with a progress bar (`packSize` and `wasmSize`
    // in player.json give the totals when the server doesn't); the pack comes from the
    // browser's cache when this exact pack (`packHash`) was downloaded before.
    const progress = new DownloadProgress(status);
    // Compiled as it downloads (a stream only downloads as fast as it is read).
    const wasmResponse = progress.track(fetchOK(url(config.wasm)), config.wasmSize);
    const wasmModule = WebAssembly.compileStreaming
      ? WebAssembly.compileStreaming(wasmResponse)
      : wasmResponse.then((response) => response.arrayBuffer()).then((bytes) => WebAssembly.compile(bytes));
    wasmModule.catch(() => {});  // (awaited below, which reports a failure)
    // `mounts` (optional): more folders for the WASI filesystem, { "<name>": "<manifest.json>" }
    // mounted at /<name> (the Demo's resources, say). A player without a pack has `pack: null`.
    const mounts = Object.entries(config.mounts ?? {});
    const [userData, pack, engineFiles, ...mounted] = await Promise.all([
      openUserData(),  // saves and settings, from IndexedDB (saves.js)
      config.pack ? loadPack(url(config.pack), config, progress) : undefined,
      fetchFolder(url(config.engine)),
      ...mounts.map(([, manifest]) => fetchFolder(url(manifest))),
    ]);
    progress.finish();

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
    wasi = new WASI(
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
    await instantiate({ module: await wasmModule, wasi });
    if (!status.classList.contains("error")) status.hidden = true;
  } catch (error) {
    fail(error instanceof PlayerError ? error.message : `The game failed to start: ${error?.stack ?? error}`);
  }
}

/** The renderer to start with: the page option, else the player's saved choice, else player.json's (default auto). */
function pickRenderer(requested, configured) {
  let saved;
  try { saved = localStorage.getItem(RENDERER_KEY) ?? undefined; } catch { saved = undefined; }
  for (const [source, value] of [["?renderer=", requested], ["the saved choice", saved], ["player.json", configured]]) {
    if (value === undefined || value === null || value === "") continue;
    if ([...RENDERERS, "auto"].includes(value)) return { choice: value, source };
    console.warn(`[acro] ignoring renderer '${value}' from ${source} (webgpu, webgl2 or auto)`);
  }
  return { choice: "auto", source: "the default" };
}

/**
 * Sets up the chosen renderer, or the other one when it fails: `{ renderer, canvas, renderers, ... }`
 * with the WebGPU device or the WebGL 2 context. Throws only when neither works.
 */
async function setUpRenderer(canvas, { choice, source }, show) {
  const order = choice === "webgl2" ? ["webgl2", "webgpu"] : ["webgpu", "webgl2"];
  const failures = {};
  for (const name of order) {
    try {
      if (name === "webgpu") {
        show("Starting WebGPU…");
        const gpu = await setUpWebGPU(canvas);
        report(name, choice, source, failures);
        return { renderer: name, renderers: availableRenderers(name, failures), canvas,
                 adapter: gpu.adapter, device: gpu.device, context: gpu.context, format: gpu.format };
      }
      show("Starting WebGL 2…");
      // A canvas that has a WebGPU context can't get a WebGL one: start over with a fresh one.
      if (canvas.acroContext) canvas = freshCanvas(canvas);
      const result = setUpWebGL2(canvas);
      if (!result.gl) throw new PlayerError(result.failure);
      canvas.acroContext = "webgl2";
      report(name, choice, source, failures);
      return { renderer: name, renderers: availableRenderers(name, failures), canvas, gl: result.gl, webgl: result.helper };
    } catch (error) {
      failures[name] = error instanceof PlayerError ? error.message : String(error?.message ?? error);
    }
  }
  throw new PlayerError("This browser can't run the game: it needs WebGPU or WebGL 2, and neither works here.\n\n" +
    `WebGPU: ${failures.webgpu}\n\nWebGL 2: ${failures.webgl2}\n\n` +
    "Use a recent Chrome, Edge, Firefox or Safari, and make sure hardware acceleration is on.");
}

function report(name, choice, source, failures) {
  const label = name === "webgpu" ? "WebGPU" : "WebGL 2";
  const other = name === "webgpu" ? "webgl2" : "webgpu";
  if (failures[other] && choice !== "auto") {
    console.warn(`[acro] renderer: ${label} (${other === "webgpu" ? "WebGPU" : "WebGL 2"}, chosen by ${source}, failed: ${failures[other]})`);
  } else if (failures[other]) {
    console.info(`[acro] renderer: ${label} (auto; WebGPU is unavailable: ${failures[other]})`);
  } else {
    console.info(`[acro] renderer: ${label} (${choice === "auto" ? "auto" : `chosen by ${source}`})`);
  }
}

/** The renderers this browser seems to have: the one that started, and the other unless it failed or is missing. */
function availableRenderers(started, failures) {
  return RENDERERS.filter((name) => {
    if (name === started) return true;
    if (failures[name]) return false;
    return name === "webgpu" ? !!navigator.gpu : typeof WebGL2RenderingContext !== "undefined";
  });
}

/** A copy of `canvas` in its place (a canvas keeps the first kind of context it gave out). */
function freshCanvas(canvas) {
  const fresh = canvas.cloneNode(false);
  canvas.parentNode.insertBefore(fresh, canvas);
  canvas.remove();
  return fresh;
}

async function setUpWebGPU(canvas) {
  if (!navigator.gpu) {
    throw new PlayerError("This browser doesn't support WebGPU (no navigator.gpu).");
  }
  // Some browsers return null for a power preference they can't honor; ask again without one.
  const adapter = await navigator.gpu.requestAdapter({ powerPreference: "high-performance" })
    ?? await navigator.gpu.requestAdapter();
  if (!adapter) {
    // Chromium browsers return no adapter when their GPU process can't start WebGPU (the console
    // says "Failed to create WebGPU Context Provider"): usually graphics acceleration is off or the
    // GPU is blocklisted.
    const internals = /Edg\//.test(navigator.userAgent) ? "edge://gpu" : "chrome://gpu";
    throw new PlayerError("WebGPU is available, but this browser couldn't get a GPU adapter.\n\n" +
      "Turn on graphics/hardware acceleration in the browser's settings (System) and restart it. " +
      `In Chrome or Edge, ${internals} shows whether WebGPU is hardware accelerated.`);
  }
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
  canvas.acroContext = "webgpu";
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

/**
 * The asset pack's bytes: from the browser's cache (Cache API) when this exact pack was
 * downloaded before, else downloaded with progress and then cached for the next visit.
 * `packHash` (player.json; the hash in the pack's header) is the cache key, so a new export is
 * downloaded again; without it, or without the Cache API (pages not on https or localhost), the
 * pack is just downloaded.
 */
async function loadPack(packURL, { packSize, packHash }, progress) {
  const cache = packHash ? await openPackCache() : undefined;
  // The cache's key for this pack (never fetched).
  const key = new URL(`${packURL.pathname}?acro-pack=${encodeURIComponent(packHash)}`, packURL);
  if (cache) {
    try {
      const hit = await cache.match(key);
      if (hit) {
        const bytes = new Uint8Array(await hit.arrayBuffer());
        if (!packSize || bytes.length === packSize) {
          progress.add(bytes.length);
          console.log(`[acro] the pack (${megabytes(bytes.length)}) came from the browser's cache`);
          return bytes;
        }
      }
    } catch (error) {
      console.warn(`[acro] couldn't read the browser's cache: ${error}`);
    }
  }
  const bytes = await progress.read(fetchOK(packURL), packSize);
  if (cache) storePack(cache, packURL, key, bytes);  // while the game starts
  return bytes;
}

async function openPackCache() {
  try { return globalThis.caches ? await caches.open("acro-packs") : undefined; } catch { return undefined; }
}

/** Keeps `bytes` in `cache` under `key`, in place of older versions of the same pack. */
async function storePack(cache, packURL, key, bytes) {
  // The Response copies the bytes now (the game may change the array later).
  const response = new Response(bytes, { headers: { "content-type": "application/octet-stream", "content-length": String(bytes.length) } });
  try {
    for (const request of await cache.keys()) {
      const old = new URL(request.url);
      if (old.pathname === packURL.pathname && old.href !== key.href) await cache.delete(request);
    }
    await cache.put(key, response);
    console.log(`[acro] cached the pack (${megabytes(bytes.length)}) for the next visit`);
  } catch (error) {
    console.warn(`[acro] couldn't cache the pack: ${error}`);  // storage full or not allowed: it downloads again next time
  }
}

function megabytes(bytes) { return `${(bytes / 1e6).toFixed(1)} MB`; }

/**
 * Download progress shown in the status box: a bar and "Downloading… 12.3 of 31.9 MB" over every
 * download it tracks. Totals come from the caller (player.json) or the response's Content-Length
 * when it isn't compressed in transit. `acro.download` has the numbers ({ loaded, total }).
 */
class DownloadProgress {
  constructor(status) {
    this.status = status;
    this.downloads = [];
    this.view = undefined;
    this.shown = 0;
    this.done = false;
  }

  /** Bytes that need no download (a cached pack). */
  add(size) {
    this.downloads.push({ loaded: size, total: size });
    this.update();
  }

  /** `responsePromise`'s body as one Uint8Array, preallocated when `expected` (bytes) is known. */
  async read(responsePromise, expected) {
    const entry = this.entry(expected);
    const response = await responsePromise;
    this.sized(entry, response);
    if (!response.body) {
      const bytes = new Uint8Array(await response.arrayBuffer());
      entry.loaded = bytes.length;
      this.update(true);
      return bytes;
    }
    const reader = response.body.getReader();
    let bytes = new Uint8Array(entry.total || 1 << 20);
    let loaded = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      if (loaded + value.length > bytes.length) {
        const grown = new Uint8Array(Math.max(bytes.length * 2, loaded + value.length));
        grown.set(bytes.subarray(0, loaded));
        bytes = grown;
      }
      bytes.set(value, loaded);
      loaded += value.length;
      entry.loaded = loaded;
      this.update();
    }
    this.update(true);
    return loaded === bytes.length ? bytes : bytes.slice(0, loaded);
  }

  /** `responsePromise` with its body counted as it is read (for WebAssembly.compileStreaming). */
  async track(responsePromise, expected) {
    const entry = this.entry(expected);
    const response = await responsePromise;
    this.sized(entry, response);
    if (!response.body) {
      entry.loaded = entry.total;
      return response;
    }
    const counter = new TransformStream({
      transform: (chunk, controller) => {
        entry.loaded += chunk.byteLength;
        this.update();
        controller.enqueue(chunk);
      },
    });
    return new Response(response.body.pipeThrough(counter), { status: response.status, statusText: response.statusText, headers: response.headers });
  }

  /** A download of `expected` bytes (0: unknown until the response says). */
  entry(expected) {
    const entry = { loaded: 0, total: expected || 0 };
    this.downloads.push(entry);
    return entry;
  }

  /** The total from the response when the caller didn't know it. */
  sized(entry, response) {
    if (entry.total) return;
    // Content-Length is the size in transit: the body's size only when it isn't compressed.
    const encoding = response.headers.get("content-encoding");
    if (!encoding || encoding === "identity") entry.total = Number(response.headers.get("content-length")) || 0;
  }

  /** Stops updating the view (the next status replaces it). */
  finish() { this.done = true; }

  update(force = false) {
    const loaded = this.downloads.reduce((sum, d) => sum + d.loaded, 0);
    const known = this.downloads.every((d) => d.total > 0);
    const total = known ? this.downloads.reduce((sum, d) => sum + Math.max(d.total, d.loaded), 0) : 0;
    if (globalThis.acro) globalThis.acro.download = { loaded, total };
    const now = performance.now();
    if (this.done || (!force && now - this.shown < 100)) return;
    this.shown = now;
    if (!this.view || !this.status.contains(this.view.box)) this.view = this.makeView();
    const fraction = total ? Math.min(loaded / total, 1) : 0;
    this.view.label.textContent = total ? `Downloading… ${megabytes(loaded)} of ${megabytes(total)}` : `Downloading… ${megabytes(loaded)}`;
    this.view.bar.style.width = `${(fraction * 100).toFixed(1)}%`;
    this.view.track.setAttribute("aria-valuenow", String(Math.round(fraction * 100)));
  }

  makeView() {
    const status = this.status;
    status.hidden = false;
    status.className = "";
    status.textContent = "";
    const box = document.createElement("div");
    box.style.cssText = "width: min(420px, 80vw)";
    const label = document.createElement("div");
    const track = document.createElement("div");
    track.setAttribute("role", "progressbar");
    track.setAttribute("aria-valuemin", "0");
    track.setAttribute("aria-valuemax", "100");
    track.style.cssText = "margin-top: 10px; height: 6px; border-radius: 3px; background: rgba(255, 255, 255, 0.15); overflow: hidden";
    const bar = document.createElement("div");
    bar.style.cssText = "height: 100%; width: 0; background: currentColor";
    track.append(bar);
    box.append(label, track);
    status.append(box);
    return { box, label, track, bar };
  }
}

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
