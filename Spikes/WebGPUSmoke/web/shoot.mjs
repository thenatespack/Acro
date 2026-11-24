// Serves the assembled smoke-test site from http://localhost and runs it in Playwright's Chromium
// with WebGPU (Apple Metal adapter on macOS): one page per mode, a screenshot of each, and the
// console output, WebGPU validation errors and shader compile errors.
//
//   node shoot.mjs <site dir> <screenshot dir> [mode ...]    (mode "shaders": compile every WGSL)
// Exits non-zero if any page reports an error. Playwright comes from ~/.acro-webtools.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const require = createRequire(path.join(os.homedir(), '.acro-webtools', 'package.json'));
const { chromium } = require('playwright');

const [site, shots, ...requested] = process.argv.slice(2);
const modes = requested.length ? requested : ['msaa'];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
                '.wasm': 'application/wasm', '.wgsl': 'text/plain' };
const server = http.createServer((request, response) => {
    const file = path.join(site, decodeURIComponent(new URL(request.url, 'http://localhost').pathname));
    if (!file.startsWith(path.resolve(site)) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        response.writeHead(404);
        return response.end();
    }
    response.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream' });
    fs.createReadStream(file).pipe(response);
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const port = server.address().port;
fs.mkdirSync(shots, { recursive: true });

const browser = await chromium.launch({ channel: 'chromium', args: ['--enable-unsafe-webgpu'] });
let failed = false;
for (const mode of modes) {
    const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
    const consoleLines = [];
    page.on('console', (message) => consoleLines.push(`[${message.type()}] ${message.text()}`));
    page.on('pageerror', (error) => consoleLines.push(`[pageerror] ${error.message}`));
    const query = mode === 'shaders' ? 'check=shaders' : `mode=${mode}&frames=${process.env.SMOKE_FRAMES ?? 30}`;
    await page.goto(`http://localhost:${port}/index.html?${query}`);
    await page.waitForFunction(() => window.smokeResult?.done, null, { timeout: 300_000, polling: 250 });
    const result = await page.evaluate(() => window.smokeResult);
    console.log(`\n=== ${mode} ===`);
    if (result.adapter) console.log(`adapter: ${result.adapter}`);
    if (mode === 'shaders') {
        const failures = Object.entries(result.shaders.errors);
        console.log(`${result.shaders.count} WGSL modules, ${failures.length} with errors, ${result.shaders.warnings} warnings`);
        for (const [file, errors] of failures) console.log(`  ${file}: ${errors.slice(0, 3).join(' | ')}`);
        if (failures.length) failed = true;
    } else {
        const shot = path.join(shots, `smoke-${mode}.png`);
        await page.locator('canvas').screenshot({ path: shot });
        console.log(`screenshot: ${shot}`);
        for (const line of result.logs) console.log(`  ${line}`);
        if (result.passTimes) console.log(`  pass times: ${result.passTimes}`);
    }
    const errors = [...new Set(result.errors)];
    console.log(`${errors.length} WebGPU/page errors`);
    for (const error of errors.slice(0, 40)) console.log(`  ! ${error}`);
    for (const line of consoleLines.filter((line) => /error|warn/i.test(line)).slice(0, 40)) console.log(`  console ${line}`);
    if (errors.length) failed = true;
    await page.close();
}
await browser.close();
server.close();
process.exit(failed ? 1 : 0);
