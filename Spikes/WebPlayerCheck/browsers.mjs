// Runs an assembled web player in Playwright's Chromium, Firefox and WebKit, on every renderer each
// browser offers, and compares the engine's frames with Chromium's (docs/wasm-spike.md, W2.7B).
//
//   node Spikes/WebPlayerCheck/browsers.mjs <site dir> <out dir> [--scenes 1-54|1,5,graphs|none]
//        [--browsers chromium,firefox,firefox-webgpu,webkit] [--name <prefix>] [--timeout <s>]
//        [--detect] [--extras] [--compare-only] [--headed | --headless] [--no-gl-debug]
//
// <site dir> is a folder from `Scripts/web-player.sh --demo --no-serve` (scenes are passed as
// `?args=--scene,<n>`) or a Web export (`--scenes none`: the game's own scene). For each browser it
// first detects what it offers: WebGPU (navigator.gpu, an adapter and a device) and WebGL 2
// (getContext('webgl2')), with the adapter, renderer string and texture-compression support; then
// runs each scene on each renderer it offers (`?renderer=webgpu|webgl2`), plus one run of the first
// scene with `?renderer=auto` (what the page picks by itself). Every run uses a fresh browser
// context (empty storage), `ENGINE_SCREENSHOT` with `ENGINE_OVERLAY=0` (fixed 1/60 s steps, frame
// 60) and on WebGL 2 `ENGINE_GL_DEBUG=1`, and records: the renderer and texture family the page
// picked, whether it started, startup time, console errors and warnings, WebGPU validation errors
// ("WebGPU:" lines) and WebGL errors ("WebGL error" lines), requestAnimationFrame callback times
// and intervals (ms), the engine's frame (<out>/<browser>/<renderer>/<scene>.png) and the canvas
// as the page shows it after the engine quits (<scene>-canvas.png, the presented frame).
//
// Browsers: chromium (with --enable-unsafe-webgpu, the reference), firefox (the installed Firefox
// over WebDriver BiDi, headed; needs Playwright 1.59 or later, so point ACRO_WEBTOOLS at one),
// firefox-webgpu (the same with dom.webgpu.enabled), firefox-playwright (Playwright's own Firefox),
// webkit. They run one after the other; run several processes (one per browser, same <out>) to
// run them at once, then --compare-only. --extras instead checks audio, saves, renderer switching,
// the WebGL 2 fallback and the pack cache (see runExtras). At the end (or with --compare-only, from earlier results in <out>)
// every frame is compared with Chromium's on the same renderer: mean absolute difference / 255
// and the share of pixels with a channel off by more than 16. Writes <out>/results.json and
// prints a summary. ACRO_WEBTOOLS (default ~/.acro-webtools) has playwright.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import zlib from 'node:zlib';

const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const playwright = require('playwright');

const [siteArg, outArg, ...rest] = process.argv.slice(2);
if (!siteArg || !outArg) { console.error('usage: browsers.mjs <site dir> <out dir> [options]'); process.exit(2); }
const option = (name, fallback) => { const i = rest.indexOf(`--${name}`); return i >= 0 ? rest[i + 1] : fallback; };
const site = path.resolve(siteArg), out = path.resolve(outArg);
const prefix = option('name', '');
const timeout = Number(option('timeout', 150)) * 1000;
fs.mkdirSync(out, { recursive: true });

const BROWSERS = {
  chromium: { type: 'chromium', launch: { channel: 'chromium', args: ['--enable-unsafe-webgpu'] } },
  // The installed Firefox (/Applications/Firefox.app) over WebDriver BiDi (`moz-firefox`, Playwright
  // 1.59 or later): Playwright's own patched Firefox (firefox-1495, -1511) hangs at startup on macOS 27.
  // Headed: headless Firefox returns no WebGPU adapter (navigator.gpu is there, requestAdapter gives null).
  firefox: { type: 'firefox', launch: { channel: 'moz-firefox', headless: false } },
  'firefox-webgpu': { type: 'firefox', launch: { channel: 'moz-firefox', headless: false, firefoxUserPrefs: { 'dom.webgpu.enabled': true, 'gfx.webgpu.ignore-blocklist': true } } },
  // Playwright's own Firefox build (Juggler), for systems where it starts.
  'firefox-playwright': { type: 'firefox', launch: {} },
  webkit: { type: 'webkit', launch: {} },
};
const browserNames = option('browsers', 'chromium,firefox,firefox-webgpu,webkit').split(',').filter(Boolean);
for (const name of browserNames) if (!BROWSERS[name]) { console.error(`unknown browser ${name}`); process.exit(2); }

function parseScenes(text) {
  if (text === 'none') return [null];
  const scenes = [];
  for (const part of text.split(',')) {
    const range = /^(\d+)-(\d+)$/.exec(part);
    if (range) for (let n = Number(range[1]); n <= Number(range[2]); n++) scenes.push(String(n));
    else if (part) scenes.push(part);
  }
  return scenes;
}
const scenes = parseScenes(option('scenes', '1-54'));
const sceneKey = (scene) => `${prefix}${scene ?? 'game'}`;

// A static server for the site, plus /__blank.html for detection.
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  let url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  if (url === '/__blank.html') { res.writeHead(200, { 'content-type': 'text/html' }); res.end('<!doctype html><title>blank</title>'); return; }
  if (url.endsWith('/')) url += 'index.html';
  const file = path.join(site, url);
  if (!file.startsWith(site)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-store' });
    res.end(data);
  });
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** What the browser offers: WebGPU (adapter, device, features) and WebGL 2 (renderer, extensions). */
async function detect(browser, origin) {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(`${origin}/__blank.html`);
  const result = await page.evaluate(async () => {
    const info = { userAgent: navigator.userAgent, webgpu: { api: !!navigator.gpu }, webgl2: {} };
    if (navigator.gpu) {
      try {
        const adapter = await navigator.gpu.requestAdapter();
        info.webgpu.adapter = !!adapter;
        if (adapter) {
          const i = adapter.info ?? {};
          info.webgpu.adapterInfo = `${i.vendor ?? ''} ${i.architecture ?? ''} ${i.description ?? ''}`.trim();
          info.webgpu.features = [...adapter.features].sort();
          try {
            const device = await adapter.requestDevice({ requiredFeatures: [...adapter.features] });
            info.webgpu.device = !!device;
            device.destroy();
          } catch (error) { info.webgpu.device = false; info.webgpu.error = String(error); }
        }
      } catch (error) { info.webgpu.error = String(error); }
    }
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl2');
    info.webgl2.context = !!gl;
    if (gl) {
      const debug = gl.getExtension('WEBGL_debug_renderer_info');
      info.webgl2.renderer = String(debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER));
      info.webgl2.version = String(gl.getParameter(gl.VERSION));
      info.webgl2.extensions = gl.getSupportedExtensions();
      info.webgl2.maxUniformBlockSize = gl.getParameter(gl.MAX_UNIFORM_BLOCK_SIZE);
      info.webgl2.maxTextureImageUnits = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
      info.webgl2.maxCombinedTextureImageUnits = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
      info.webgl2.maxSamples = gl.getParameter(gl.MAX_SAMPLES);
    }
    info.audioWorklet = typeof AudioWorkletNode !== 'undefined';
    info.indexedDB = typeof indexedDB !== 'undefined';
    info.caches = typeof caches !== 'undefined';
    info.compileStreaming = typeof WebAssembly.compileStreaming === 'function';
    return info;
  });
  await context.close();
  const renderers = [];
  if (result.webgpu.device) renderers.push('webgpu');
  if (result.webgl2.context) renderers.push('webgl2');
  return { ...result, renderers };
}

const summary = (values) => {
  if (!values?.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const at = (q) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))];
  const round = (x) => Math.round(x * 100) / 100;
  return { count: values.length, mean: round(values.reduce((a, b) => a + b, 0) / values.length), p50: round(at(0.5)), p95: round(at(0.95)), max: round(sorted.at(-1)) };
};

/** One run of `scene` on `renderer` ("webgpu", "webgl2" or "auto") in a fresh context. */
async function runOne(browser, origin, browserName, scene, renderer) {
  const env = ['ENGINE_SCREENSHOT=/shot.png', 'ENGINE_OVERLAY=0'];
  // (gl.getError() after every command: slow, so --no-gl-debug for frame times.)
  if (renderer === 'webgl2' && !rest.includes('--no-gl-debug')) env.push('ENGINE_GL_DEBUG=1');
  const query = new URLSearchParams();
  if (renderer !== 'auto') query.set('renderer', renderer);
  if (scene !== null) query.set('args', `--scene,${scene}`);
  query.set('env', env.join(','));
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  const log = [], errors = [], warnings = [], gpuErrors = [];
  let pageError = null;
  page.on('console', (message) => {
    const text = message.text(), type = message.type();
    log.push(`[${type}] ${text}`);
    // The engine's log goes to stderr (console.error) with its own level: count by that level.
    const level = /^\[\s*[\d.]+\] \[(\w+)\]/.exec(text)?.[1] ?? (/^Engine: quitting after/.test(text) ? 'info' : type);
    if (/WebGPU:|WebGL error/.test(text)) gpuErrors.push(text);
    else if (level === 'error' || level === 'fatal') errors.push(text);
    else if (level === 'warning' || level === 'warn') warnings.push(text);
  });
  page.on('pageerror', (error) => { pageError ??= String(error); log.push(`[pageerror] ${error}`); });
  page.on('crash', () => { pageError ??= 'page crashed'; log.push('[crash]'); });
  await page.addInitScript(() => {
    const raf = window.requestAnimationFrame.bind(window);
    const timing = (window.__acroTiming = { stamps: [], durations: [] });
    window.requestAnimationFrame = (callback) => raf((stamp) => {
      const begin = performance.now();
      try { callback(stamp); } finally {
        timing.durations.push(performance.now() - begin);
        if (timing.stamps.at(-1) !== stamp) timing.stamps.push(stamp);
      }
    });
  });
  const started = Date.now();
  let running = false, shot = null, startup = null;
  try {
    await page.goto(`${origin}/?${query}`, { timeout });
    running = await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'),
      null, { timeout, polling: 250 }).then(() => true, () => false);
    startup = (Date.now() - started) / 1000;
    const failed = await page.evaluate(() => document.querySelector('#status')?.classList.contains('error'));
    if (running && !failed) {
      const ok = await page.waitForFunction(() => Object.keys(globalThis.acro?.screenshots ?? {}).length > 0 || document.querySelector('#status.error'),
        null, { timeout, polling: 250 }).then(() => true, () => false);
      if (ok) {
        const dataURL = await page.evaluate(() => Object.values(globalThis.acro.screenshots ?? {})[0] ?? null);
        if (dataURL) {
          const dir = path.join(out, browserName, renderer);
          fs.mkdirSync(dir, { recursive: true });
          shot = path.join(dir, `${sceneKey(scene)}.png`);
          fs.writeFileSync(shot, Buffer.from(dataURL.split(',')[1], 'base64'));
          // The presented frame too (the engine quits after the capture, so the canvas keeps its
          // last frame): the canvas path (WebGPU's context, WebGL 2's present draw) differs by browser.
          await page.waitForFunction(() => /ended/.test(document.querySelector('#status')?.textContent ?? ''), null, { timeout: 5000 }).catch(() => {});
          await sleep(300);
          await page.evaluate(() => { const s = document.querySelector('#status'); if (s) s.hidden = true; });
          await page.locator('canvas').first().screenshot({ path: shot.replace(/\.png$/, '-canvas.png') }).catch(() => {});
        }
      }
    }
  } catch (error) {
    pageError ??= `run: ${error.message.split('\n')[0]}`;
  }
  let state = {};
  try {
    state = await page.evaluate(() => {
      const t = window.__acroTiming ?? { stamps: [], durations: [] };
      const status = document.querySelector('#status');
      return {
        renderer: globalThis.acro?.renderer ?? null,
        renderers: globalThis.acro?.renderers ?? null,
        textureFamily: globalThis.acro?.textureFamily ?? null,
        statusError: status?.classList.contains('error') ? status.textContent.replace(/\s+/g, ' ').trim().slice(0, 600) : null,
        intervals: t.stamps.slice(1).map((s, i) => s - t.stamps[i]),
        durations: t.durations,
        frames: globalThis.acro?.stats?.frames ?? null,
      };
    });
  } catch (error) {
    pageError ??= `evaluate: ${error.message.split('\n')[0]}`;
  }
  await context.close().catch(() => {});
  // The textures line names the family when the page had several packs; a Demo run has none.
  const texturesLine = log.find((line) => line.includes('[acro] textures:'));
  const rendererLine = log.find((line) => line.includes('[acro] renderer:'));
  // Skip the frames before the game ran (loading) for the callback times: the engine's frames only.
  const durations = (state.durations ?? []).slice(1);
  return {
    browser: browserName, scene: sceneKey(scene), requested: renderer, renderer: state.renderer ?? null,
    renderers: state.renderers ?? null, textureFamily: state.textureFamily ?? null,
    texturesLine: texturesLine?.replace(/^\[\w+\] /, '') ?? null, rendererLine: rendererLine?.replace(/^\[\w+\] /, '') ?? null,
    running, startupSeconds: startup, screenshot: shot ? path.relative(out, shot) : null,
    ok: !!(running && shot && !state.statusError && !pageError && gpuErrors.length === 0),
    statusError: state.statusError ?? null, pageError,
    gpuErrors: gpuErrors.length, firstGPUErrors: gpuErrors.slice(0, 5),
    errors: errors.length, firstErrors: errors.slice(0, 8), warnings: warnings.length, firstWarnings: [...new Set(warnings)].slice(0, 8),
    rafCallback: summary(durations), rafInterval: summary(state.intervals), log,
  };
}


/**
 * --extras: what the frame comparison doesn't cover, per browser. With a Demo site: audio (the
 * `audio` scene; AudioWorklet output starts after a click), keyboard input and saves (the
 * `character` scene: F9 finds no save, F5 saves into IndexedDB, the page reloads, F9 loads it),
 * switching renderers (`acro.setRenderer`, localStorage) and the fallback to WebGL 2 with
 * `navigator.gpu` hidden. With an export (packs in player.json): the pack comes from the Cache
 * API on the second visit. Each in a fresh context.
 */
async function runExtras(browser, origin, name, capabilities) {
  const config = JSON.parse(fs.readFileSync(path.join(site, 'player.json')));
  const results = {};
  const open = async () => {
    const context = await browser.newContext({ viewport: { width: 960, height: 540 } });
    const page = await context.newPage();
    const lines = [];
    page.on('console', (message) => lines.push(message.text()));
    page.on('pageerror', (error) => lines.push(`[pageerror] ${error}`));
    const waitForLine = async (pattern, ms = 15000) => {
      for (const end = Date.now() + ms; Date.now() < end; await sleep(100)) {
        const line = lines.find((l) => pattern.test(l));
        if (line) return line;
      }
      return null;
    };
    const start = async (query) => {
      lines.length = 0;
      await page.goto(`${origin}/?${query}`);
      await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'), null, { timeout, polling: 250 });
      return page.evaluate(() => ({ renderer: globalThis.acro?.renderer, error: document.querySelector('#status.error')?.textContent?.trim() ?? null }));
    };
    return { context, page, lines, waitForLine, start };
  };
  const attempt = async (label, body) => {
    const session = await open();
    try { results[label] = await body(session); } catch (error) { results[label] = { ok: false, error: String(error.message ?? error).split('\n')[0] }; }
    await session.context.close().catch(() => {});
    console.log(`  ${name} extras ${label}: ${JSON.stringify(results[label])}`);
  };
  const demo = !!config.mounts?.demo;
  if (demo) {
    await attempt('audio', async ({ page, start }) => {
      const started = await start('args=--scene,audio');
      const before = await page.evaluate(() => globalThis.acro?.audio?.state ?? null);
      await page.mouse.click(480, 270);  // a user gesture: the context may resume now
      await sleep(2500);
      const audio = await page.evaluate(() => {
        const a = globalThis.acro?.audio;
        return a ? { state: a.state, ready: a.ready, error: a.error, reports: a.reports, sent: a.sent, received: a.received,
                     underruns: a.underruns, peak: Math.round(a.peak * 1000) / 1000, sampleRate: a.context?.sampleRate } : null;
      });
      return { ok: !!(audio && audio.state === 'running' && audio.ready && !audio.error && audio.reports > 0 && audio.received > 0),
               renderer: started.renderer, stateBeforeClick: before, ...audio };
    });
    await attempt('saves', async ({ page, start, waitForLine, lines }) => {
      const pattern = /^Character: (No quick save yet|Quick loaded|Quick load failed)/;
      await start('args=--scene,character');
      await page.mouse.click(480, 270);
      await sleep(300);
      await page.keyboard.press('F9');
      const loadBefore = await waitForLine(pattern);
      await page.keyboard.press('F5');
      const save = await waitForLine(/^Character: Quick sav/);
      await sleep(800);
      const reloaded = await start('args=--scene,character');
      const preloaded = await waitForLine(/^\[acro\] user data: /, 2000);
      await page.mouse.click(480, 270);
      await sleep(300);
      await page.keyboard.press('F9');
      const loadAfter = await waitForLine(pattern);
      const check = await waitForLine(/^Character: after load/, 5000);
      return { ok: /No quick save yet/.test(loadBefore ?? '') && /Quick saved/.test(save ?? '') && /Quick loaded/.test(loadAfter ?? ''),
               renderer: reloaded.renderer, loadBefore, save, preloaded, loadAfter, check,
               errors: lines.filter((l) => /pageerror|IndexedDB|indexedDB/.test(l)).slice(0, 4) };
    });
    await attempt('setRenderer', async ({ page, start }) => {
      const first = await start('args=--scene,1');
      const other = first.renderer === 'webgpu' ? 'webgl2' : 'webgpu';
      if (!capabilities.renderers.includes(other)) return { ok: true, first: first.renderer, note: `no ${other} here: nothing to switch to` };
      await Promise.all([page.waitForNavigation(), page.evaluate((r) => globalThis.acro.setRenderer(r), other)]);
      await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'), null, { timeout, polling: 250 });
      const switched = await page.evaluate(() => globalThis.acro?.renderer);
      await Promise.all([page.waitForNavigation(), page.evaluate(() => globalThis.acro.setRenderer('auto'))]);
      await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'), null, { timeout, polling: 250 });
      const back = await page.evaluate(() => globalThis.acro?.renderer);
      return { ok: switched === other && back === first.renderer, first: first.renderer, switched, back };
    });
    if (capabilities.renderers.includes('webgpu')) {
      await attempt('fallback', async ({ page, start, lines }) => {
        await page.addInitScript(() => { Object.defineProperty(Navigator.prototype, 'gpu', { get: () => undefined, configurable: true }); });
        const started = await start('args=--scene,1');
        return { ok: started.renderer === 'webgl2' && !started.error, renderer: started.renderer, line: lines.find((l) => l.includes('[acro] renderer:')) ?? null };
      });
    }
  }
  if (config.packs || config.packHash) {
    await attempt('packCache', async ({ start, waitForLine }) => {
      const first = await start('');
      const cached = await waitForLine(/cached the pack|couldn't cache/, 10000);
      await start('');
      const hit = await waitForLine(/came from the browser's cache/, 3000);
      return { ok: !!hit && /cached the pack/.test(cached ?? ''), renderer: first.renderer, first: cached, second: hit };
    });
  }
  return results;
}

async function runBrowser(name) {
  const spec = BROWSERS[name];
  const browser = await playwright[spec.type].launch({ headless: !rest.includes('--headed'), ...spec.launch,
    ...(rest.includes('--headless') ? { headless: true } : {}) });
  const port = server.address().port;
  const origin = `http://127.0.0.1:${port}`;
  const capabilities = await detect(browser, origin);
  capabilities.version = browser.version();
  console.log(`${name} ${capabilities.version}: renderers ${capabilities.renderers.join(', ') || 'none'}` +
    ` (WebGPU api ${capabilities.webgpu.api}, adapter ${capabilities.webgpu.adapter ?? '-'}, device ${capabilities.webgpu.device ?? '-'};` +
    ` WebGL 2 ${capabilities.webgl2.renderer ?? 'none'})`);
  const runs = [];
  if (rest.includes('--extras')) {
    capabilities.extras = await runExtras(browser, origin, name, capabilities);
  } else if (!rest.includes('--detect')) {
    const logDir = path.join(out, name, 'logs');
    fs.mkdirSync(logDir, { recursive: true });
    const plan = [[scenes[0], 'auto'], ...capabilities.renderers.flatMap((r) => scenes.map((s) => [s, r]))];
    for (const [scene, renderer] of plan) {
      const run = await runOne(browser, origin, name, scene, renderer);
      fs.writeFileSync(path.join(logDir, `${renderer}-${run.scene}.log`), run.log.join('\n') + '\n');
      delete run.log;
      runs.push(run);
      const rc = run.rafCallback ? `${run.rafCallback.mean} ms` : '-';
      console.log(`  ${name} ${renderer.padEnd(6)} ${run.scene.padEnd(10)} ${run.ok ? 'ok  ' : 'FAIL'} picked ${run.renderer ?? '-'}` +
        ` start ${run.startupSeconds ?? '-'} s, gpu errors ${run.gpuErrors}, errors ${run.errors}, warnings ${run.warnings}, rAF ${rc}` +
        (run.ok ? '' : `  ${run.statusError ?? run.pageError ?? run.firstErrors[0] ?? (run.screenshot ? '' : 'no screenshot')}`));
    }
  }
  await browser.close();
  const file = path.join(out, `${name}${prefix ? `-${prefix}` : ''}${rest.includes('--extras') ? '-extras' : ''}.json`);
  fs.writeFileSync(file, JSON.stringify({ browser: name, capabilities, runs }, null, 1));
  return { capabilities, runs };
}

// --- PNG decoding (8-bit RGB/RGBA, non-interlaced: what the loader's canvas encodes) ---
function decodePNG(file) {
  const data = fs.readFileSync(file);
  let pos = 8, width, height, color, idat = [];
  while (pos < data.length) {
    const length = data.readUInt32BE(pos), kind = data.toString('latin1', pos + 4, pos + 8);
    const body = data.subarray(pos + 8, pos + 8 + length);
    pos += 12 + length;
    if (kind === 'IHDR') { width = body.readUInt32BE(0); height = body.readUInt32BE(4); color = body[9]; if (body[8] !== 8 || body[12]) throw new Error(`${file}: unsupported PNG`); }
    else if (kind === 'IDAT') idat.push(body);
  }
  const channels = { 2: 3, 6: 4, 0: 1, 4: 2 }[color];
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = width * channels, pixels = Buffer.alloc(height * stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)], line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    const prev = y ? pixels.subarray((y - 1) * stride, y * stride) : null, row = pixels.subarray(y * stride, (y + 1) * stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? row[x - channels] : 0, b = prev ? prev[x] : 0, c = prev && x >= channels ? prev[x - channels] : 0;
      let v = line[x];
      if (filter === 1) v += a; else if (filter === 2) v += b; else if (filter === 3) v += (a + b) >> 1;
      else if (filter === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c; }
      row[x] = v & 255;
    }
  }
  return { width, height, channels, pixels };
}

/** Mean absolute difference / 255 over RGB, and the % of pixels with a channel off by more than 16. */
function compareFrames(fileA, fileB) {
  const a = decodePNG(fileA), b = decodePNG(fileB);
  if (a.width !== b.width || a.height !== b.height) return { sizeMismatch: `${a.width}x${a.height} vs ${b.width}x${b.height}` };
  let sum = 0, over = 0;
  const n = a.width * a.height;
  for (let i = 0; i < n; i++) {
    let worst = 0;
    for (let c = 0; c < 3; c++) {
      const d = Math.abs(a.pixels[i * a.channels + c] - b.pixels[i * b.channels + c]);
      sum += d;
      if (d > worst) worst = d;
    }
    if (worst > 16) over++;
  }
  return { mean: Math.round(sum / (n * 3) * 1000) / 1000, over16: Math.round(over / n * 10000) / 100 };
}

function compareAll() {
  const results = {};
  for (const file of fs.readdirSync(out).filter((f) => f.endsWith('.json') && f !== 'results.json')) {
    const data = JSON.parse(fs.readFileSync(path.join(out, file)));
    if (!data.browser || !Array.isArray(data.runs)) continue;
    results[data.browser] ??= { capabilities: data.capabilities, runs: [] };
    results[data.browser].runs.push(...data.runs);
  }
  const reference = (results.chromium?.runs ?? []).filter((r) => r.screenshot && r.requested !== 'auto');
  for (const [name, { runs }] of Object.entries(results)) {
    for (const run of runs) {
      if (name === 'chromium' || !run.screenshot || run.requested === 'auto') continue;
      const ref = reference.find((r) => r.scene === run.scene && r.renderer === run.renderer);
      if (!ref) continue;
      run.vsChromium = compareFrames(path.join(out, ref.screenshot), path.join(out, run.screenshot));
      const canvas = (file) => path.join(out, file.replace(/\.png$/, '-canvas.png'));
      if (fs.existsSync(canvas(ref.screenshot)) && fs.existsSync(canvas(run.screenshot))) {
        run.canvasVsChromium = compareFrames(canvas(ref.screenshot), canvas(run.screenshot));
      }
    }
  }
  fs.writeFileSync(path.join(out, 'results.json'), JSON.stringify(results, null, 1));
  // Summary: per browser and renderer, runs that passed, and the frames' differences.
  for (const [name, { capabilities, runs }] of Object.entries(results)) {
    for (const renderer of ['webgpu', 'webgl2']) {
      const these = runs.filter((r) => r.requested === renderer);
      if (!these.length) continue;
      const passed = these.filter((r) => r.ok);
      const diffs = these.map((r) => r.vsChromium).filter((d) => d && d.mean !== undefined);
      const close = diffs.filter((d) => d.mean <= 1 && d.over16 <= 1).length;
      const canvases = these.map((r) => r.canvasVsChromium).filter((d) => d && d.mean !== undefined);
      const median = (values) => { const v = values.filter((x) => x != null).sort((a, b) => a - b); return v.length ? v[Math.floor(v.length / 2)] : null; };
      const cb = these.map((r) => r.rafCallback?.p50).filter((v) => v != null);
      console.log(`${name.padEnd(15)} ${renderer.padEnd(7)} ${passed.length}/${these.length} ran clean` +
        (diffs.length ? `; vs Chromium: ${close}/${diffs.length} within 1/255 mean and 1% over 16, worst mean ${Math.max(...diffs.map((d) => d.mean))}` : '') +
        (canvases.length ? `; canvas vs Chromium: worst mean ${Math.max(...canvases.map((d) => d.mean))}, worst over 16 ${Math.max(...canvases.map((d) => d.over16))}%` : '') +
        (cb.length ? `; rAF callback p50 (median over scenes) ${median(cb).toFixed(2)} ms, interval p50 ${median(these.map((r) => r.rafInterval?.p50))?.toFixed(2)} ms` : ''));
      for (const r of these.filter((r) => !r.ok || (r.vsChromium && (r.vsChromium.mean > 1 || r.vsChromium.over16 > 1) || r.vsChromium?.sizeMismatch))) {
        console.log(`    ${r.scene}: ${r.ok ? '' : 'FAIL '}${r.vsChromium ? JSON.stringify(r.vsChromium) : ''} ${r.statusError ?? r.pageError ?? r.firstGPUErrors[0] ?? r.firstErrors[0] ?? ''}`.slice(0, 400));
      }
    }
    const auto = runs.find((r) => r.requested === 'auto');
    if (auto) console.log(`${name.padEnd(15)} auto    picked ${auto.renderer ?? 'nothing'} (${auto.rendererLine ?? auto.statusError ?? ''})`);
  }
}

if (!rest.includes('--compare-only')) {
  server.listen(0, '127.0.0.1');
  await new Promise((r) => server.once('listening', r));
  for (const name of browserNames) await runBrowser(name);
  server.close();
}
if (!rest.includes('--detect') && !rest.includes('--extras')) compareAll();
