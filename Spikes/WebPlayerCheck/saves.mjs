// Checks that a save survives a page reload (Web/saves.js keeps /userdata in IndexedDB), with the
// Demo's character scene: F5 quick saves, the page reloads, F9 quick loads (docs/wasm-spike.md).
//
//   node Spikes/WebPlayerCheck/saves.mjs <Demo site dir> [--headed]
//
// The site is Scripts/web-player.sh --demo --no-serve output (default .build-wasm/web-demo).
// Prints what happened and exits non-zero unless the load after the reload found the save.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const tools = process.env.ACRO_WEBTOOLS ?? path.join(os.homedir(), '.acro-webtools');
const require = createRequire(path.join(tools, 'package.json'));
const { chromium } = require('playwright');

const [siteArg, ...rest] = process.argv.slice(2);
if (!siteArg) { console.error('usage: saves.mjs <Demo site dir> [--headed]'); process.exit(2); }
const site = path.resolve(siteArg);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
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
const url = `http://127.0.0.1:${server.address().port}/?args=--scene,character`;

const browser = await chromium.launch({ channel: 'chromium', headless: !rest.includes('--headed'), args: ['--enable-unsafe-webgpu'] });
const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
const lines = [];
page.on('console', (message) => lines.push(message.text()));
page.on('pageerror', (error) => lines.push(`[pageerror] ${error}`));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const waitForLine = async (pattern, ms = 15000) => {
  for (const end = Date.now() + ms; Date.now() < end; await sleep(100)) {
    const line = lines.find((l) => pattern.test(l));
    if (line) return line;
  }
  return null;
};
const start = async () => {
  lines.length = 0;
  await page.goto(url);
  await page.waitForFunction(() => globalThis.acro?.stats || document.querySelector('#status.error'), null, { timeout: 120000 });
  await page.mouse.click(480, 270);
  await sleep(300);
};
// The stored paths (the "files" store of the "acro-userdata" database).
const storedPaths = () => page.evaluate(() => new Promise((resolve) => {
  const open = indexedDB.open('acro-userdata', 1);
  open.onupgradeneeded = () => open.result.createObjectStore('files', { keyPath: 'path' });
  open.onsuccess = () => {
    const get = open.result.transaction('files').objectStore('files').getAllKeys();
    get.onsuccess = () => { open.result.close(); resolve(get.result); };
  };
}));

const report = {};
await start();
await page.keyboard.press('F9');
report.loadBeforeSave = await waitForLine(/^Character: (No quick save yet|Quick loaded|Quick load failed)/);
await page.keyboard.press('F5');
report.save = await waitForLine(/^Character: Quick sav/);
await sleep(500);
report.storedAfterSave = await storedPaths();

await start();  // a reload: the wasm and its in-memory filesystem start over
report.preloaded = await waitForLine(/^\[acro\] user data: /, 1000);
await page.keyboard.press('F9');
report.loadAfterReload = await waitForLine(/^Character: (No quick save yet|Quick loaded|Quick load failed)/);
report.check = await waitForLine(/^Character: after load/, 5000);

console.log(JSON.stringify(report, null, 1));
await browser.close();
server.close();
const ok = /No quick save yet/.test(report.loadBeforeSave ?? '') && /Quick saved/.test(report.save ?? '')
  && report.storedAfterSave.includes('AcroDemo/saves/quick.save.json') && /Quick loaded/.test(report.loadAfterReload ?? '');
console.log(ok ? 'PASS: the save survived the reload' : 'FAIL');
process.exit(ok ? 0 : 1);
