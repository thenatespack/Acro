// Creates the WebGPU device and canvas context, hands them to the engine through
// `globalThis.acro = { adapter, device, context, format }` (WebGPURenderDevice reads it), mounts
// the engine's resources at /engine in a WASI file system, starts the wasm and drives frames
// from requestAnimationFrame. Results land in `window.smokeResult` for shoot.mjs.
//
// Query: ?mode=msaa|fsr1|taau|hdr|bilinear&frames=N, or ?check=shaders (compile every WGSL).
import { WASI, File, OpenFile, ConsoleStdout, PreopenDirectory, Directory } from '@bjorn3/browser_wasi_shim';
import { instantiate } from './pkg/instantiate.js';

const params = new URLSearchParams(location.search);
const result = window.smokeResult = { done: false, errors: [], logs: [], shaders: null };
const fail = (message) => { result.errors.push(String(message)); result.done = true; };

async function createDevice() {
    if (!navigator.gpu) throw new Error('navigator.gpu is missing (WebGPU disabled?)');
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) throw new Error('No WebGPU adapter');
    // Every feature the adapter has (compression, timestamps, storage texture tiers) and its
    // largest limits, so the engine sees what the GPU can do.
    const requiredLimits = {};
    for (const name in adapter.limits) requiredLimits[name] = adapter.limits[name];
    const device = await adapter.requestDevice({ requiredFeatures: [...adapter.features], requiredLimits });
    device.addEventListener('uncapturederror', (event) => result.errors.push('uncaptured: ' + event.error.message));
    device.lost.then((info) => result.errors.push('device lost: ' + info.message));
    return { adapter, device };
}

/** Compiles every generated WGSL module and collects the compiler's errors and warnings. */
async function checkShaders(device) {
    const files = await (await fetch('wgsl-files.json')).json();
    const report = { count: files.length, errors: {}, warnings: 0 };
    for (const path of files) {
        const code = await (await fetch('wgsl/' + path)).text();
        const module = device.createShaderModule({ code, label: path });
        const info = await module.getCompilationInfo();
        for (const message of info.messages) {
            if (message.type === 'error') (report.errors[path] ??= []).push(`${message.lineNum}:${message.linePos} ${message.message}`);
            else report.warnings += 1;
        }
    }
    result.shaders = report;
}

/** The engine resource folder as a WASI directory tree. */
async function engineResources() {
    const files = await (await fetch('engine-files.json')).json();
    const root = new Map();
    await Promise.all(files.map(async (path) => {
        const data = new Uint8Array(await (await fetch('engine/' + path)).arrayBuffer());
        const parts = path.split('/');
        let directory = root;
        for (const part of parts.slice(0, -1)) {
            if (!directory.has(part)) directory.set(part, new Directory(new Map()));
            directory = directory.get(part).contents;
        }
        directory.set(parts[parts.length - 1], new File(data));
    }));
    return root;
}

async function main() {
    const { adapter, device } = await createDevice();
    result.adapter = `${adapter.info?.vendor} ${adapter.info?.architecture}; features: ${[...device.features].join(', ')}`;
    if (params.get('check') === 'shaders') {
        await checkShaders(device);
        result.done = true;
        return;
    }
    const canvas = document.querySelector('canvas');
    const context = canvas.getContext('webgpu');
    globalThis.acro = { adapter, device, context, format: navigator.gpu.getPreferredCanvasFormat() };
    globalThis.acroSmokeMode = params.get('mode') ?? 'msaa';
    globalThis.acroCanvasWidth = canvas.width;
    globalThis.acroCanvasHeight = canvas.height;

    const line = (text) => { result.logs.push(text); console.log(text); };
    const wasi = new WASI(['WebGPUSmoke'], ['ENGINE_RESOURCES=/engine'], [
        new OpenFile(new File([])),
        ConsoleStdout.lineBuffered(line),
        ConsoleStdout.lineBuffered((text) => { result.logs.push(text); console.error(text); }),
        new PreopenDirectory('/engine', await engineResources()),
    ]);
    wasi.setInstance = (instance) => { wasi.inst = instance; };
    await instantiate({ module: fetch('pkg/WebGPUSmoke.wasm'), wasi });
    if (globalThis.acroSmokeFailed) return fail('setup: ' + globalThis.acroSmokeFailed);
    if (typeof globalThis.acroSmokeFrame !== 'function') return fail('acroSmokeFrame was not exported');

    const frames = Number(params.get('frames') ?? 30);
    for (let n = 0; n < frames; n++) {
        await new Promise((resolve) => requestAnimationFrame(resolve));
        device.pushErrorScope('validation');
        device.pushErrorScope('out-of-memory');
        globalThis.acroSmokeFrame();
        for (const kind of ['out of memory', 'validation']) {
            const error = await device.popErrorScope();
            if (error) result.errors.push(`frame ${n} ${kind}: ${error.message}`);
        }
    }
    await device.queue.onSubmittedWorkDone();
    // One more frame so results mapped meanwhile are delivered, then let the page present.
    await new Promise((resolve) => requestAnimationFrame(resolve));
    result.passTimes = globalThis.acroSmokePassTimes;
    result.done = true;
}

main().catch((error) => fail(error?.stack ?? error));
