// Drives WebInputSmoke in Playwright's Chromium and checks what the engine saw (see main.swift).
//
//   node Spikes/WebInputSmoke/smoke.mjs <PackageToJS output dir> [log file]
//
// Environment: ACRO_WEBTOOLS (default ~/.acro-webtools) has playwright; WASI_SHIM_DIR is the
// dist/ folder of @bjorn3/browser_wasi_shim 0.3.0 (default: resolved from ACRO_WEBTOOLS);
// DPR (default 2) is the device scale factor. Exits non-zero when a check fails.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const { chromium } = require('playwright');
const outputDir = path.resolve(process.argv[2] ?? '.build-wasm/plugins/PackageToJS/outputs/Package');
const logFile = process.argv[3];
const shimDir = process.env.WASI_SHIM_DIR ?? path.dirname(require.resolve('@bjorn3/browser_wasi_shim'));
const dpr = Number(process.env.DPR ?? 2);

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost').pathname;
  let file;
  if (url === '/' || url === '/index.html') file = path.join(here, 'index.html');
  else if (url.startsWith('/wasi-shim/')) file = path.join(shimDir, url.slice('/wasi-shim/'.length));
  else file = path.join(outputDir, url);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream' });
    res.end(data);
  });
}).listen(0);
const port = server.address().port;

const lines = [];
const events = [];
let failures = 0;
process.on('exit', () => { if (logFile) fs.writeFileSync(logFile, lines.join('\n') + '\n'); });
function check(ok, what) {
  const line = `${ok ? 'PASS' : 'FAIL'} ${what}`;
  console.log(line);
  lines.push(line);
  if (!ok) failures++;
}
const since = (mark) => events.slice(mark);
const find = (mark, pred) => since(mark).find(pred);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function waitFor(mark, pred, ms = 3000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const hit = find(mark, pred);
    if (hit) return hit;
    await sleep(20);
  }
  return null;
}
const near = (a, b, eps = 0.01) => Math.abs(a - b) <= eps;

const browser = await chromium.launch({ channel: 'chromium' });
const context = await browser.newContext({ viewport: { width: 800, height: 600 }, deviceScaleFactor: dpr });
// A fake standard-mapping gamepad the test drives through window.__pad.
await context.addInitScript(() => {
  const buttons = Array.from({ length: 17 }, () => ({ pressed: false, touched: false, value: 0 }));
  window.__pad = { id: 'Test Pad (STANDARD GAMEPAD)', index: 0, connected: false, mapping: 'standard', timestamp: 0, buttons, axes: [0, 0, 0, 0] };
  navigator.getGamepads = () => [window.__pad.connected ? window.__pad : null, null, null, null];
  window.__prevented = [];
  window.__wheel = [];
  // Headless Chromium refuses pointer lock (WrongDocumentError: no real window), so the API is
  // stubbed: it records whether the request came with user activation, as browsers require,
  // grants it, and lets the test end it as a user would (Esc).
  let locked = null;
  window.__lockRequests = [];
  HTMLCanvasElement.prototype.requestPointerLock = function () {
    window.__lockRequests.push(navigator.userActivation.isActive);
    locked = this;
    setTimeout(() => document.dispatchEvent(new Event('pointerlockchange')));
    return Promise.resolve();
  };
  Object.defineProperty(Document.prototype, 'pointerLockElement', { get() { return locked; }, configurable: true });
  Document.prototype.exitPointerLock = function () {
    locked = null;
    setTimeout(() => document.dispatchEvent(new Event('pointerlockchange')));
  };
});
const page = await context.newPage();
page.on('console', (msg) => {
  const text = msg.text();
  lines.push(text);
  if (text.startsWith('[acro] {')) {
    try { events.push(JSON.parse(text.slice(7))); } catch { lines.push('(unparsed)'); }
  }
});
page.on('pageerror', (e) => lines.push(`pageerror: ${e.message}`));

await page.goto(`http://localhost:${port}/`);
check(!!(await waitFor(0, (e) => e.t === 'ready', 30000)), 'harness started');
// Registered after the engine's listeners, so they see its preventDefault, and the DOM's raw wheel deltas.
await page.evaluate(() => {
  addEventListener('keydown', (e) => window.__prevented.push([e.code, e.defaultPrevented]));
  addEventListener('wheel', (e) => window.__wheel.push([e.deltaX, e.deltaY, e.deltaMode]));
});
const startSize = await waitFor(0, (e) => e.t === 'size');
check(startSize && startSize.width === 800 * dpr && startSize.height === 600 * dpr && near(startSize.scale, dpr),
  `framebuffer 800x600 CSS at DPR ${dpr}: ${JSON.stringify(startSize)}`);
const attrs = await page.evaluate(() => [acro.canvas.width, acro.canvas.height]);
check(attrs[0] === 800 * dpr && attrs[1] === 600 * dpr, `canvas width/height attributes ${attrs}`);
check(!!find(0, (e) => e.t === 'audioStats' && e.state === 'suspended'), 'AudioContext suspended before any gesture');

// Keyboard: state edges, presses with modifiers, preventDefault.
let mark = events.length;
await page.keyboard.down('w');
await waitFor(mark, (e) => e.t === 'key' && e.key === 'w' && e.down);
await page.keyboard.up('w');
await page.keyboard.press('ArrowLeft');
await page.keyboard.press('Space');
await page.keyboard.press('Tab');
await page.keyboard.down('Shift');
await page.keyboard.press('KeyA');
await page.keyboard.up('Shift');
await page.keyboard.press('Digit7');
await page.keyboard.press('Control+KeyJ');  // shortcuts with Control are left to the browser
await sleep(150);
check(!!find(mark, (e) => e.t === 'key' && e.key === 'w' && e.down), 'W down');
check(!!find(mark, (e) => e.t === 'key' && e.key === 'w' && !e.down), 'W up');
for (const key of ['left', 'space', 'tab', 'num7']) {
  check(!!find(mark, (e) => e.t === 'press' && e.key === key), `${key} press`);
}
const shiftA = find(mark, (e) => e.t === 'press' && e.key === 'a');
check(shiftA && shiftA.modifiers.includes('shift'), `Shift+A press has shift: ${JSON.stringify(shiftA)}`);
check(!!find(mark, (e) => e.t === 'key' && e.key === 'leftShift' && e.down), 'left shift down');
const prevented = Object.fromEntries((await page.evaluate(() => window.__prevented)).map(([c, p]) => [c, p]));
check(prevented.ArrowLeft && prevented.Space && prevented.Tab, `arrows, space, Tab prevented: ${JSON.stringify(prevented)}`);
check(prevented.KeyJ === false, 'Control+J not prevented');

// Text input (F2 toggles it in the harness).
mark = events.length;
await page.keyboard.press('F2');
await waitFor(mark, (e) => e.t === 'textInput' && e.active);
await page.keyboard.type('hi!');
await page.keyboard.press('Backspace');
await page.keyboard.press('F2');
await waitFor(mark, (e) => e.t === 'textInput' && !e.active);
const typed = since(mark).filter((e) => e.t === 'text').map((e) => e.text).join('');
check(typed === 'hi!', `typed text "${typed}"`);
check(!!find(mark, (e) => e.t === 'textKey' && e.key === 'backspace'), 'backspace reaches text input as a key');
check(!find(mark, (e) => e.t === 'key' && e.key === 'h'), 'typed letters do not show up as key state while text input is active');

// Mouse: position in CSS pixels (window points), buttons, wheel.
mark = events.length;
await page.mouse.move(100, 50);
const move = await waitFor(mark, (e) => e.t === 'move' && e.x === 100 && e.y === 50);
check(!!move, 'mouse at (100, 50) points');
// One frame reports one cursor position, so each press waits for the engine to see it.
const released = (button) => waitFor(mark, (e) => e.t === 'button' && e.button === button && !e.down);
await page.mouse.down();
await page.mouse.up();
await released('left');
await page.mouse.click(200, 150, { button: 'right' });
await released('right');
await page.mouse.click(300, 250, { button: 'middle' });
await released('middle');
const left = find(mark, (e) => e.t === 'button' && e.button === 'left' && e.down);
check(left && left.x === 100 && left.y === 50, `left press at ${left && [left.x, left.y]}`);
check(!!find(mark, (e) => e.t === 'button' && e.button === 'left' && !e.down), 'left release');
const right = find(mark, (e) => e.t === 'button' && e.button === 'right' && e.down);
check(right && right.x === 200 && right.y === 150, `right press at ${right && [right.x, right.y]}`);
check(!!find(mark, (e) => e.t === 'button' && e.button === 'middle' && e.down), 'middle press');
mark = events.length;
await page.mouse.move(400, 300);
await page.mouse.wheel(0, 120);
await page.mouse.wheel(-30, 0);
await sleep(150);
const scrolls = since(mark).filter((e) => e.t === 'scroll');
const sy = scrolls.reduce((s, e) => s + e.y, 0), sx = scrolls.reduce((s, e) => s + e.x, 0);
// Compared with what the DOM reported (Playwright's wheel deltas are scaled by the emulated DPR).
const wheel = await page.evaluate(() => window.__wheel);
const domY = wheel.reduce((s, w) => s + w[1], 0), domX = wheel.reduce((s, w) => s + w[0], 0);
check(wheel.length === 2 && near(sy, -domY) && near(sx, -domX) && sy < 0 && sx > 0,
  `wheel: DOM deltas ${JSON.stringify(wheel)} -> engine scroll (${sx}, ${sy}) (up / left positive)`);
const pageScroll = await page.evaluate(() => [scrollX, scrollY]);
check(pageScroll[0] === 0 && pageScroll[1] === 0, 'page did not scroll');

// Audio: the clicks above were gestures.
const running = await waitFor(0, (e) => e.t === 'audioStats' && e.state === 'running', 3000);
check(!!running, 'AudioContext running after a click');
await sleep(2500);
const audio = await page.evaluate(() => {
  const a = acro.audio;
  return { state: a.state, chunks: a.chunks, sent: a.sent, received: a.received, queued: a.queued, underruns: a.underruns,
           underrunFrames: a.underrunFrames, dropped: a.dropped, peak: a.peak, reports: a.reports, rate: a.context.sampleRate,
           baseLatency: a.context.baseLatency, currentTime: a.context.currentTime };
});
lines.push(`audio counters: ${JSON.stringify(audio)}`);
console.log('audio counters', audio);
check(audio.chunks > 20 && audio.received > audio.rate, `worklet received ${audio.received} frames in ${audio.chunks} chunks`);
check(audio.peak > 0.15 && audio.peak < 0.25, `worklet is playing the 0.2 tone (peak ${audio.peak})`);
check(audio.underruns <= 3, `underruns ${audio.underruns} (${audio.underrunFrames} frames)`);
check(audio.queued > 0 && audio.queued < audio.rate * 0.12, `queue ${audio.queued} frames (~${(audio.queued / audio.rate * 1000).toFixed(0)} ms)`);

// Resize.
mark = events.length;
await page.setViewportSize({ width: 640, height: 480 });
const resized = await waitFor(mark, (e) => e.t === 'size');
check(resized && resized.width === 640 * dpr && resized.height === 480 * dpr, `resized: ${JSON.stringify(resized)}`);

// Gamepad.
mark = events.length;
await page.evaluate(() => {
  const p = window.__pad;
  p.connected = true;
  p.buttons[0].pressed = true; p.buttons[0].value = 1;
  p.buttons[12].pressed = true; p.buttons[12].value = 1;
  p.buttons[6].value = 0.75;
  p.axes = [0.5, -1, 0, 0];
});
const connected = await waitFor(mark, (e) => e.t === 'gamepad' && e.connected);
check(connected && connected.name.includes('Test Pad'), `gamepad connected: ${JSON.stringify(connected)}`);
const pad = await waitFor(mark, (e) => e.t === 'pad' && e.buttons.includes('south'));
check(pad && pad.buttons.includes('dpadUp') && near(pad.lx, 0.5) && near(pad.ly, 1) && near(pad.lt, 0.75),
  `pad state (A, d-pad up, left stick up-right, left trigger): ${JSON.stringify(pad)}`);
mark = events.length;
await page.evaluate(() => { window.__pad.connected = false; });
check(!!(await waitFor(mark, (e) => e.t === 'gamepad' && !e.connected)), 'gamepad disconnected');

// Focus loss releases held keys.
mark = events.length;
await page.keyboard.down('d');
await waitFor(mark, (e) => e.t === 'key' && e.key === 'd' && e.down);
await page.evaluate(() => dispatchEvent(new Event('blur')));
const dReleased = await waitFor(mark, (e) => e.t === 'key' && e.key === 'd' && !e.down);
check(!!dReleased && !!find(mark, (e) => e.t === 'focus' && !e.focused), 'blur reports unfocused and releases D');
await page.evaluate(() => dispatchEvent(new Event('focus')));
check(!!(await waitFor(mark, (e) => e.t === 'focus' && e.focused)), 'focus comes back');
await page.keyboard.up('d');

// Pointer lock: C asks for capture; the lock comes with the next click.
mark = events.length;
await page.keyboard.press('KeyC');
const pending = await waitFor(mark, (e) => e.t === 'capture' && e.captured);
check(!!pending, `capture requested: ${JSON.stringify(pending)}`);
const cursor = await page.evaluate(() => acro.canvas.style.cursor);
check(cursor === 'none', `cursor hidden while captured (${cursor})`);
check((await page.evaluate(() => window.__lockRequests.length)) === 0, 'no lock requested before a click');
await page.mouse.click(320, 240);
const locked = await waitFor(mark, (e) => e.t === 'capture' && e.captured && e.pointerLock);
const requests = await page.evaluate(() => window.__lockRequests);
check(!!locked && requests.length === 1 && requests[0] === true, `pointer lock requested in the click (user activation: ${requests}) and granted`);
mark = events.length;
await page.mouse.move(340, 230);
await sleep(100);
const deltas = since(mark).filter((e) => e.t === 'delta');
const dx = deltas.reduce((s, e) => s + e.dx, 0), dy = deltas.reduce((s, e) => s + e.dy, 0);
check(deltas.length > 0 && dx > 0 && dy < 0, `raw motion while captured: (${dx}, ${dy})`);
mark = events.length;
await page.evaluate(() => document.exitPointerLock());
const ended = await waitFor(mark, (e) => e.t === 'capture' && !e.captured && !e.pointerLock);
check(!!ended, 'user ending the lock ends the capture');

await page.screenshot({ path: path.join(path.dirname(logFile ?? path.join(os.tmpdir(), 'x')), `webinputsmoke-dpr${dpr}.png`) });
await browser.close();
server.close();
console.log(failures ? `${failures} check(s) failed` : 'all checks passed');
process.exit(failures ? 1 : 0);
