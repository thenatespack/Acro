// Measures and profiles an assembled web player (Scripts/web-player.sh --no-serve, or a Web export)
// in Playwright's Chromium with WebGPU (docs/wasm-spike.md, "Performance").
//
//   node Spikes/WebPlayerCheck/profile.mjs <site dir> <out dir> [--name <n>] [--query <a=b&c=d>]
//        [--warmup <s>] [--seconds <s>] [--frames <first>:<end>] [--profile] [--interval <µs>] [--top <n>]
//        [--width <px>] [--height <px>]
//
// Waits for the engine to run (`acro.stats`), then `--warmup` seconds (default 5), then times every
// requestAnimationFrame callback (one engine frame each) for `--seconds` (default 10). Writes
// <out>/<name>.json: the callbacks' mean / p50 / p95, the frame interval, the engine's last
// `acro.stats` and the page title (Demo scenes put their own timings there).
// `--frames 300:600` measures animation frames 300 to 599 instead (counted from the page's first
// requestAnimationFrame callback): with `ENGINE_SCREENSHOT` in the query's env the engine takes
// fixed 1/60 s steps, so the same frames do the same work in every run, whatever the frame rate.
// With --profile it also runs Chrome's sampling CPU profiler (CDP `Profiler.start/stop`, every
// `--interval` µs, default 200) over the same window, saves <name>.cpuprofile (opens in Chrome
// DevTools) and lists the top functions by self and by total time, Swift names demangled
// (build with a name section: `swift package ... js --debug-info-format name`). The profiler
// slows the frame down, so compare timings from runs without it.
// ACRO_WEBTOOLS (default ~/.acro-webtools) has playwright; SWIFT_DEMANGLE (default
// `xcrun swift-demangle`) demangles.
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const { chromium } = require('playwright');

const [siteArg, outArg, ...rest] = process.argv.slice(2);
if (!siteArg || !outArg) { console.error('usage: profile.mjs <site dir> <out dir> [options]'); process.exit(2); }
const option = (name, fallback) => { const i = rest.indexOf(`--${name}`); return i >= 0 ? rest[i + 1] : fallback; };
const site = path.resolve(siteArg), out = path.resolve(outArg);
const name = option('name', 'profile'), query = option('query', '');
const warmup = Number(option('warmup', 5)), seconds = Number(option('seconds', 10));
const frameRange = option('frames', null)?.split(':').map(Number);
const profile = rest.includes('--profile'), interval = Number(option('interval', 200)), top = Number(option('top', 40));
const width = Number(option('width', 1280)), height = Number(option('height', 720));
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

const browser = await chromium.launch({ channel: 'chromium', args: ['--enable-unsafe-webgpu'] });
const page = await browser.newPage({ viewport: { width, height } });
let pageError = null;
page.on('pageerror', (error) => { pageError ??= String(error); });
await page.addInitScript(() => {
  const raf = window.requestAnimationFrame.bind(window);
  const timing = (window.__acroTiming = { stamps: [], durations: [], stats: [] });
  window.requestAnimationFrame = (callback) => raf((stamp) => {
    const begin = performance.now();
    try { callback(stamp); } finally {
      timing.durations.push(performance.now() - begin);
      if (timing.stamps.at(-1) !== stamp) timing.stamps.push(stamp);
      // The engine publishes `acro.stats` every 30 frames: keep each, at this callback's index.
      const stats = globalThis.acro?.stats;
      if (stats && stats !== timing.lastStats) {
        timing.lastStats = stats;
        timing.stats.push({ at: timing.durations.length - 1, updateTime: stats.updateTime, renderTime: stats.renderTime });
      }
    }
  });
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
await page.goto(`http://127.0.0.1:${port}/${query ? `?${query}` : ''}`);
const running = await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'),
  null, { timeout: 300000 }).then(() => true, () => false);
const frameCount = () => page.evaluate(() => window.__acroTiming.durations.length);
const untilFrame = async (n) => { while (running && (await frameCount()) < n) await sleep(20); };
if (frameRange) await untilFrame(frameRange[0]); else await sleep(warmup * 1000);

let cdp = null;
if (profile) {
  cdp = await page.context().newCDPSession(page);
  await cdp.send('Profiler.enable');
  await cdp.send('Profiler.setSamplingInterval', { interval });
}
const startFrame = frameRange ? await frameCount() : 0;
if (!frameRange) await page.evaluate(() => { window.__acroTiming.stamps = []; window.__acroTiming.durations = []; });
if (cdp) await cdp.send('Profiler.start');
if (frameRange) await untilFrame(frameRange[1]); else await sleep(seconds * 1000);
const cpuProfile = cdp ? (await cdp.send('Profiler.stop')).profile : null;

const result = await page.evaluate(([first, end]) => {
  const summary = (values) => {
    if (!values.length) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const at = (q) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))];
    const round = (x) => Math.round(x * 100) / 100;
    return { count: values.length, mean: round(values.reduce((a, b) => a + b, 0) / values.length), p50: round(at(0.5)), p95: round(at(0.95)), max: round(sorted.at(-1)) };
  };
  const t = window.__acroTiming;
  const durations = end ? t.durations.slice(first, end) : t.durations, stamps = end ? t.stamps.slice(first, end) : t.stamps;
  const intervals = stamps.slice(1).map((s, i) => s - stamps[i]);
  // The engine's frames are the long callbacks; other requestAnimationFrame users are tiny.
  // The engine's update and render CPU times (`acro.stats`, one frame in 30) over the window.
  const sampled = t.stats.filter((s) => !end || (s.at >= first && s.at < end));
  return {
    rafCallback: summary(durations.filter((d) => d > 0.05)), rafInterval: summary(intervals),
    updateTime: summary(sampled.map((s) => s.updateTime)), renderTime: summary(sampled.map((s) => s.renderTime)),
    title: document.title,
    stats: globalThis.acro?.stats ? JSON.parse(JSON.stringify(globalThis.acro.stats)) : null,
    statusError: document.querySelector('#status')?.classList.contains('error') ? document.querySelector('#status').textContent : null,
  };
}, frameRange ? [frameRange[0], frameRange[1]] : [0, 0]);

const report = { name, query, running, pageError, profiled: profile, frames: frameRange ? `${frameRange[0]}:${frameRange[1]}` : null, ...result };
if (frameRange) report.profiledFrames = `${startFrame}:${frameRange[1]}`;
if (cpuProfile) {
  fs.writeFileSync(path.join(out, `${name}.cpuprofile`), JSON.stringify(cpuProfile));
  // Self and total time per function: each sample's time (its timeDelta) goes to its leaf as
  // self, and once to every distinct function on its stack as total.
  const nodes = new Map(cpuProfile.nodes.map((n) => [n.id, n]));
  const parent = new Map();
  for (const n of cpuProfile.nodes) for (const c of n.children ?? []) parent.set(c, n.id);
  const self = new Map(), total = new Map();
  let all = 0;
  const label = (n) => n.callFrame.functionName || `(${n.callFrame.url || 'anonymous'})`;
  cpuProfile.samples.forEach((id, i) => {
    const dt = (cpuProfile.timeDeltas[i + 1] ?? cpuProfile.timeDeltas[i]) / 1000;
    all += dt;
    const leaf = nodes.get(id);
    self.set(label(leaf), (self.get(label(leaf)) ?? 0) + dt);
    const seen = new Set();
    for (let n = id; n !== undefined; n = parent.get(n)) {
      const l = label(nodes.get(n));
      if (seen.has(l)) continue;
      seen.add(l);
      total.set(l, (total.get(l) ?? 0) + dt);
    }
  });
  const names = [...new Set([...self.keys(), ...total.keys()])];
  let demangled = new Map(names.map((n) => [n, n]));
  try {
    const tool = (process.env.SWIFT_DEMANGLE ?? 'xcrun swift-demangle').split(' ');
    const input = names.map((n) => n.replace(/^\$/, '')).join('\n');
    const lines = execFileSync(tool[0], [...tool.slice(1), '--simplified'], { input, maxBuffer: 1 << 28 }).toString().split('\n');
    demangled = new Map(names.map((n, i) => [n, lines[i] || n]));
  } catch { /* leave the names mangled */ }
  const frames = report.rafCallback?.count || 1;
  const rows = (map) => [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, top)
    .map(([n, ms]) => ({ msPerFrame: Math.round(ms / frames * 100) / 100, percent: Math.round(ms / all * 1000) / 10, name: demangled.get(n).slice(0, 300) }));
  report.profile = { sampledMs: Math.round(all), frames, self: rows(self), total: rows(total) };
}
fs.writeFileSync(path.join(out, `${name}.json`), JSON.stringify(report, null, 1));
const brief = { ...report };
delete brief.profile;
console.log(JSON.stringify(brief, null, 1));
if (report.profile) {
  console.log(`\nSelf time (ms per frame, % of samples), ${report.profile.frames} frames:`);
  for (const r of report.profile.self) console.log(`${String(r.msPerFrame).padStart(7)} ${String(r.percent).padStart(5)}%  ${r.name}`);
  console.log('\nTotal time:');
  for (const r of report.profile.total) console.log(`${String(r.msPerFrame).padStart(7)} ${String(r.percent).padStart(5)}%  ${r.name}`);
}
await browser.close();
server.close();
process.exit(report.statusError || pageError || !running ? 1 : 0);
