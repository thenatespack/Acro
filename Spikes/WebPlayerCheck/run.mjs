// Runs an assembled web player (Scripts/web-player.sh --no-serve) in Playwright's Chromium with
// WebGPU, sends some keyboard and mouse input, and records what happened (docs/wasm-spike.md).
//
//   node Spikes/WebPlayerCheck/run.mjs <site dir> <out dir> [--name <n>] [--query <a=b&c=d>]
//        [--seconds <s>] [--width <css px>] [--height <css px>] [--dpr <n>] [--headed] [--no-webgpu]
//        [--count-calls]
//
// Writes <out>/<name>-<t>s.png screenshots (start, after input, end), <name>.log (the console)
// and <name>.json: WebGPU errors (lines with "WebGPU:"), requestAnimationFrame intervals and
// callback durations (ms: mean, p50, p95, max), the engine's last `acro.stats` (frame and GPU
// pass times), and whether the page showed an error. WebGL 2 errors (`?renderer=webgl2` with
// `env=ENGINE_GL_DEBUG=1`: "WebGL error" lines) count with them. --no-webgpu launches Chromium
// without WebGPU (the page falls back to WebGL 2). --count-calls counts calls into Web/webgl2.js
// per frame (WebGL 2 only) for two seconds. Exits non-zero on a page error or a trap.
// With ENGINE_SCREENSHOT in the query's env (`--query 'env=ENGINE_SCREENSHOT=/shot.png'`) it sends
// no input and saves the engine's own capture (fixed 1/60 s steps, as natively) as <name>-engine.png.
// ACRO_WEBTOOLS (default ~/.acro-webtools) has playwright.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const { chromium } = require('playwright');

const [siteArg, outArg, ...rest] = process.argv.slice(2);
if (!siteArg || !outArg) { console.error('usage: run.mjs <site dir> <out dir> [options]'); process.exit(2); }
const option = (name, fallback) => { const i = rest.indexOf(`--${name}`); return i >= 0 ? rest[i + 1] : fallback; };
const site = path.resolve(siteArg), out = path.resolve(outArg);
const name = option('name', 'run'), query = option('query', ''), seconds = Number(option('seconds', 8));
const width = Number(option('width', 1280)), height = Number(option('height', 720)), dpr = Number(option('dpr', 1));
fs.mkdirSync(out, { recursive: true });

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  let url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  if (url.endsWith('/')) url += 'index.html';
  const file = path.join(site, url);
  if (!file.startsWith(site)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-store' });
    res.end(data);
  });
}).listen(0, '127.0.0.1');
await new Promise((r) => server.once('listening', r));
const port = server.address().port;

const log = [];
const webgpuErrors = [];
let pageError = null;
const browser = await chromium.launch({ channel: 'chromium', headless: !rest.includes('--headed'), args: rest.includes('--no-webgpu') ? [] : ['--enable-unsafe-webgpu'] });
const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: dpr });
page.on('console', (message) => {
  const text = message.text();
  log.push(`[${message.type()}] ${text}`);
  if (/WebGPU:|WebGL error/.test(text)) webgpuErrors.push(text);
});
page.on('pageerror', (error) => { pageError ??= String(error); log.push(`[pageerror] ${error}`); });
// Without WebGPU: no flag, and no navigator.gpu either (headless Chromium on macOS may have it anyway).
if (rest.includes('--no-webgpu')) await page.addInitScript(() => { Object.defineProperty(Navigator.prototype, 'gpu', { get: () => undefined }); });
// Times every requestAnimationFrame callback (the engine runs a whole frame in one) and the intervals between frames.
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

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const started = Date.now();
await page.goto(`http://127.0.0.1:${port}/${query ? `?${query}` : ''}`);
// Running: the engine has published stats, or the page shows an error.
const running = await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'),
  null, { timeout: 120000 }).then(() => true, () => false);
const startup = (Date.now() - started) / 1000;
const shot = async (label) => {
  const file = path.join(out, `${name}-${label}.png`);
  await page.screenshot({ path: file });
  return file;
};
const shots = [];
const statusError = async () => page.evaluate(() => {
  const status = document.querySelector('#status');
  return status?.classList.contains('error') ? status.textContent : null;
});
const engineShot = /ENGINE_SCREENSHOT=/.test(decodeURIComponent(query));
if (running && engineShot) {
  const ok = await page.waitForFunction(() => Object.keys(globalThis.acro?.screenshots ?? {}).length > 0, null, { timeout: 60000 })
    .then(() => true, () => false);
  if (ok) {
    const dataURL = await page.evaluate(() => Object.values(globalThis.acro.screenshots)[0]);
    const file = path.join(out, `${name}-engine.png`);
    fs.writeFileSync(file, Buffer.from(dataURL.split(',')[1], 'base64'));
    shots.push(file);
  }
} else if (running && !(await statusError())) {
  await page.evaluate(() => { window.__acroTiming.stamps = []; window.__acroTiming.durations = []; });
  await sleep(1500);
  shots.push(await shot('start'));
  // Input: click to focus, WASD and arrows, a mouse drag and the wheel.
  await page.mouse.click(width / 2, height / 2);
  for (const key of ['KeyW', 'KeyA', 'ArrowRight', 'Space']) {
    await page.keyboard.down(key);
    await sleep(400);
    await page.keyboard.up(key);
  }
  await page.mouse.move(width / 2, height / 2);
  await page.mouse.down({ button: 'right' });
  for (let i = 1; i <= 10; i++) { await page.mouse.move(width / 2 + i * 15, height / 2 + i * 4); await sleep(30); }
  await page.mouse.up({ button: 'right' });
  await page.mouse.wheel(0, -240);
  shots.push(await shot('input'));
  await sleep(Math.max(0, seconds * 1000 - 3000));
  shots.push(await shot('end'));
}
let calls = null;
if (running && rest.includes('--count-calls')) {
  calls = await page.evaluate(async () => {
    const helper = globalThis.acro?.webgl;
    if (!helper) return null;
    const before = { ...helper.calls };
    const first = globalThis.acro.stats?.frames ?? 0;
    await new Promise((r) => setTimeout(r, 2000));
    const frames = (globalThis.acro.stats?.frames ?? 0) - first;
    const counts = Object.fromEntries(Object.entries(helper.calls).map(([k, v]) => [k, v - (before[k] ?? 0)]).filter(([, v]) => v > 0));
    const total = Object.values(counts).reduce((a, b) => a + b, 0);
    return { frames, perFrame: frames ? Math.round(total / frames * 100) / 100 : null, drawCalls: globalThis.acro.stats?.drawCalls, counts };
  });
}
const result = await page.evaluate(() => {
  const summary = (values) => {
    if (!values.length) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const at = (q) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))];
    const round = (x) => Math.round(x * 100) / 100;
    return { count: values.length, mean: round(values.reduce((a, b) => a + b, 0) / values.length), p50: round(at(0.5)), p95: round(at(0.95)), max: round(sorted.at(-1)) };
  };
  const t = window.__acroTiming;
  const intervals = t.stamps.slice(1).map((s, i) => s - t.stamps[i]);
  const status = document.querySelector('#status');
  return {
    rafInterval: summary(intervals), rafCallback: summary(t.durations),
    stats: globalThis.acro?.stats ? JSON.parse(JSON.stringify(globalThis.acro.stats)) : null,
    statusError: status?.classList.contains('error') ? status.textContent : null,
    renderer: globalThis.acro?.renderer ?? null,
    adapter: globalThis.acro?.adapter?.info ? `${globalThis.acro.adapter.info.vendor} ${globalThis.acro.adapter.info.architecture}` : null,
    canvas: `${document.querySelector('canvas')?.width}x${document.querySelector('canvas')?.height}`,
  };
});
const report = { name, query, startupSeconds: startup, running, webgpuErrors: webgpuErrors.length, firstErrors: webgpuErrors.slice(0, 10), pageError, calls, ...result, screenshots: shots };
fs.writeFileSync(path.join(out, `${name}.json`), JSON.stringify(report, null, 1));
fs.writeFileSync(path.join(out, `${name}.log`), log.join('\n') + '\n');
console.log(JSON.stringify(report, null, 1));
await browser.close();
server.close();
process.exit(report.statusError || pageError || !running ? 1 : 0);
