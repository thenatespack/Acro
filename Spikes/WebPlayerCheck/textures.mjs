// Checks a Web export's texture-family choice (W2.6C, docs/wasm-spike.md): runs the exported site
// in Playwright's Chromium on WebGPU and WebGL 2, each with the GPU's texture formats as they are
// and with BC, ASTC or both hidden (the WebGPU adapter's features and WebGL's extensions patched in
// an init script), and reports for each run which pack the page downloaded, its `[acro] textures:`
// line, the engine's decode warnings, validation errors, and how far its ENGINE_SCREENSHOT frame is
// from the run with nothing hidden on the same renderer (mean difference / 255, and the share of
// channels off by more than 8).
//
//   node Spikes/WebPlayerCheck/textures.mjs <site dir> <out dir> [--renderers webgpu,webgl2] [--cases normal,bc,astc,none]
//        [--query <more page options>] [--name <prefix>]
//
// A site without per-family packs (the Demo: `--query args=--scene,compression`) only checks the
// engine's decode fallback: no pack is expected.
//
// Writes <out>/<renderer>-<case>.png (the engine's frames), <renderer>-<case>.log and summary.json.
// Exits non-zero when a run fails to start, has validation errors or downloads the wrong pack.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const { chromium } = require('playwright');

const [siteArg, outArg, ...rest] = process.argv.slice(2);
if (!siteArg || !outArg) { console.error('usage: textures.mjs <site dir> <out dir> [options]'); process.exit(2); }
const option = (name, fallback) => { const i = rest.indexOf(`--${name}`); return i >= 0 ? rest[i + 1] : fallback; };
const site = path.resolve(siteArg), out = path.resolve(outArg);
const renderers = option('renderers', 'webgpu,webgl2').split(',');
const cases = option('cases', 'normal,bc,astc,none').split(',');
const extraQuery = option('query', ''), prefix = option('name', '');
const config = JSON.parse(fs.readFileSync(path.join(site, 'player.json'), 'utf8'));
const hasPacks = !!config.packs;
fs.mkdirSync(out, { recursive: true });

// What each case hides, and the pack the page should then download.
const HIDDEN = {
  normal: { webgpu: [], webgl: [], pack: 'bc' },
  bc: { webgpu: ['texture-compression-astc'], webgl: ['WEBGL_compressed_texture_astc'], pack: 'bc' },
  astc: { webgpu: ['texture-compression-bc'], webgl: ['EXT_texture_compression_bptc', 'EXT_texture_compression_rgtc'], pack: 'astc' },
  none: { webgpu: ['texture-compression-bc', 'texture-compression-astc'],
          webgl: ['EXT_texture_compression_bptc', 'EXT_texture_compression_rgtc', 'WEBGL_compressed_texture_astc'], pack: 'bc' },
};

const requests = [];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  let url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  if (url.endsWith('/')) url += 'index.html';
  const file = path.join(site, url);
  if (!file.startsWith(site)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    if (url.endsWith('.pack')) requests.push({ url, bytes: data.length });
    res.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-store' });
    res.end(data);
  });
}).listen(0, '127.0.0.1');
await new Promise((r) => server.once('listening', r));
const port = server.address().port;

const browser = await chromium.launch({ channel: 'chromium', args: ['--enable-unsafe-webgpu'] });
const results = [];
let failed = false;
for (const renderer of renderers) {
  for (const name of cases) {
    const hidden = HIDDEN[name];
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    const log = [];
    page.on('console', (message) => log.push(`[${message.type()}] ${message.text()}`));
    page.on('pageerror', (error) => log.push(`[pageerror] ${error}`));
    await page.addInitScript(({ webgpu, webgl }) => {
      if (globalThis.GPUAdapter && webgpu.length) {
        const features = Object.getOwnPropertyDescriptor(GPUAdapter.prototype, 'features');
        Object.defineProperty(GPUAdapter.prototype, 'features', {
          get() { return new Set([...features.get.call(this)].filter((f) => !webgpu.includes(f))); },
        });
      }
      if (globalThis.WebGL2RenderingContext && webgl.length) {
        const proto = WebGL2RenderingContext.prototype;
        const getExtension = proto.getExtension, supported = proto.getSupportedExtensions;
        proto.getExtension = function (name) { return webgl.includes(name) ? null : getExtension.call(this, name); };
        proto.getSupportedExtensions = function () { return (supported.call(this) ?? []).filter((n) => !webgl.includes(n)); };
      }
    }, hidden);
    requests.length = 0;
    const env = ['ENGINE_SCREENSHOT=/shot.png', ...(renderer === 'webgl2' ? ['ENGINE_GL_DEBUG=1'] : [])].join(',');
    const started = Date.now();
    await page.goto(`http://127.0.0.1:${port}/?renderer=${renderer}&env=${env}${extraQuery ? `&${extraQuery}` : ''}`);
    const ok = await page.waitForFunction(() => Object.keys(globalThis.acro?.screenshots ?? {}).length > 0 || document.querySelector('#status.error'),
      null, { timeout: 120000 }).then(() => true, () => false);
    const seconds = (Date.now() - started) / 1000;
    const shot = ok ? await page.evaluate(() => Object.values(globalThis.acro.screenshots ?? {})[0] ?? null) : null;
    const file = path.join(out, `${prefix}${renderer}-${name}.png`);
    if (shot) fs.writeFileSync(file, Buffer.from(shot.split(',')[1], 'base64'));
    fs.writeFileSync(path.join(out, `${prefix}${renderer}-${name}.log`), log.join('\n') + '\n');
    const errors = log.filter((line) => /WebGPU:|WebGL error|\[pageerror\]/.test(line));
    const packs = requests.map((r) => path.basename(r.url));
    const textures = log.find((line) => line.includes('[acro] textures:')) ?? null;
    const decodes = log.filter((line) => /can't sample .* textures; decoding/.test(line)).map((line) => line.replace(/^.*can't sample /, '').replace(/ textures;.*$/, ''));
    const engineNote = log.find((line) => /textures: (bc|astc)[;,]/.test(line) && !line.includes('[acro]')) ?? null;
    const actual = await page.evaluate(() => globalThis.acro?.renderer ?? null);
    const expectedPack = hasPacks ? `game.${hidden.pack}.pack` : null;
    const result = { renderer, case: name, actualRenderer: actual, ok: !!shot, seconds, packs, expectedPack, textures, decodes, engineNote,
                     errors: errors.length, errorLines: errors.slice(0, 5), image: shot ? file : null };
    if (!shot || errors.length || actual !== renderer || (hasPacks && (packs.length !== 1 || packs[0] !== expectedPack))) { result.failed = true; failed = true; }
    results.push(result);
    console.log(`${renderer} ${name}: ${result.failed ? 'FAILED' : 'ok'} ${packs.join(' ')} ${textures ?? ''} decodes [${decodes.join(', ')}] ${errors.length} errors, ${seconds.toFixed(1)} s`);
    await context.close();
  }
}

// Each frame against the same renderer's unpatched run (and WebGL 2's against WebGPU's), in a page's canvas.
const page = await browser.newPage();
await page.goto(`http://127.0.0.1:${port}/player.json`);
const compare = async (a, b) => page.evaluate(async ([a, b]) => {
  const load = async (url) => {
    const image = new Image();
    image.src = url;
    await image.decode();
    const canvas = new OffscreenCanvas(image.width, image.height);
    const context = canvas.getContext('2d');
    context.drawImage(image, 0, 0);
    return context.getImageData(0, 0, image.width, image.height).data;
  };
  const [x, y] = [await load(a), await load(b)];
  if (x.length !== y.length) return null;
  let sum = 0, over8 = 0, max = 0, channels = 0;
  for (let i = 0; i < x.length; i++) {
    if (i % 4 === 3) continue;
    const d = Math.abs(x[i] - y[i]);
    sum += d; channels++; max = Math.max(max, d);
    if (d > 8) over8++;
  }
  return { mean: Math.round(sum / channels * 1000) / 1000, over8: Math.round(over8 / channels * 1e5) / 1e3, max };
}, [a, b]);
const dataURL = (file) => `data:image/png;base64,${fs.readFileSync(file).toString('base64')}`;
for (const result of results) {
  const reference = results.find((r) => r.renderer === result.renderer && r.case === 'normal');
  if (result.image && reference?.image && reference !== result) result.vsNormal = await compare(dataURL(result.image), dataURL(reference.image));
  const webgpu = results.find((r) => r.renderer === 'webgpu' && r.case === result.case);
  if (result.renderer === 'webgl2' && result.image && webgpu?.image) result.vsWebGPU = await compare(dataURL(result.image), dataURL(webgpu.image));
}
const sizes = Object.fromEntries(fs.readdirSync(site).filter((f) => f.endsWith('.pack')).map((f) => [f, fs.statSync(path.join(site, f)).size]));
fs.writeFileSync(path.join(out, `${prefix}summary.json`), JSON.stringify({ sizes, results }, null, 1) + '\n');
for (const r of results) {
  console.log(`${r.renderer.padEnd(6)} ${r.case.padEnd(6)} pack ${r.packs.join(',').padEnd(15)} vs normal ${JSON.stringify(r.vsNormal ?? null)}`
    + (r.vsWebGPU ? ` vs webgpu ${JSON.stringify(r.vsWebGPU)}` : ''));
}
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
