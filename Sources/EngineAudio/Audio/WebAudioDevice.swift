#if canImport(JavaScriptKit)
import JavaScriptKit
import EngineCore

/// Output through Web Audio (WebAssembly builds): the default device there.
///
/// The browser's audio thread (an AudioWorklet) can't call into the wasm instance, which lives
/// on the main thread, and sharing memory with it (SharedArrayBuffer) needs a cross-origin
/// isolated page. So the mix is rendered on the main thread instead: a timer (every
/// `pumpInterval`, and whenever `pump()` is called) renders enough frames to keep about
/// `bufferDuration` queued and posts them as Float32Array chunks (transferred, not copied) to a
/// small AudioWorklet that plays them from a queue. The worklet's code is an inline Blob URL,
/// so nothing extra is fetched.
///
/// Browsers only start audio after a user gesture: the context resumes on the first click,
/// touch or key press. Until then nothing is rendered, so voices started at load play from
/// their start once audio runs. Timers are throttled in background tabs, so a hidden tab's
/// audio underruns (it is silent then anyway).
///
/// `globalThis.acro.audio` (when the page set `globalThis.acro`) is the JS side, with its
/// counters: `state`, `chunks`, `sent`, `underruns`, `underrunFrames`, `dropped`, `queued`, and
/// `peak` (the loudest sample the worklet played over its last report, about 10 ms).
public final class WebAudioDevice: AudioDevice {
    public let sampleRate: Double
    public var name: String { "Web Audio (\(Int(sampleRate)) Hz)" }
    public var isRealtime: Bool { true }
    /// Seconds of audio kept queued ahead of the speakers: the output latency added on top of
    /// the browser's own. Larger survives longer main-thread stalls without underruns.
    public var bufferDuration: Double = 0.06
    /// Milliseconds between the timer's top-ups.
    public let pumpInterval: Double

    private let host: JSObject
    private var render: AudioRenderCallback?
    private var scratch: [Float] = []
    private var timer: JSClosure?
    private var timerID: JSValue = .undefined

    /// Counters of the JS side, for tests and diagnostics.
    public struct Stats: Sendable {
        /// The AudioContext's state: "suspended" until a user gesture, then "running".
        public var state: String
        /// Chunks posted to the worklet, and the frames in them.
        public var chunks: Int
        public var framesSent: Int
        /// Render quanta (128 frames) the worklet had too little for after playback began, and
        /// the frames of silence it played instead.
        public var underruns: Int
        public var underrunFrames: Int
        /// Frames the worklet dropped because its queue grew too long (catching up after a stall).
        public var droppedFrames: Int
        /// Frames queued in the worklet at its last report.
        public var queuedFrames: Int
    }

    /// Creates the AudioContext (suspended until a user gesture). `sampleRate` nil uses the
    /// output's native rate.
    public init(sampleRate: Double? = nil, pumpInterval: Double = 10) throws {
        let make = JSObject.global.Function.function!.new("sampleRate", Self.hostSource)
        let result = make(sampleRate.map { JSValue.number($0) } ?? .undefined)
        guard let host = result.object else { throw AudioError("Web Audio is unavailable") }
        if let error = host.error.string { throw AudioError("Web Audio: \(error)") }
        self.host = host
        self.sampleRate = host.context.sampleRate.number ?? sampleRate ?? 48000
        self.pumpInterval = pumpInterval
        if let acro = JSObject.global.acro.object { acro.audio = .object(host) }
    }

    deinit {
        stop()
        _ = host.close!()
    }

    public func start(render: @escaping AudioRenderCallback) throws {
        self.render = render
        _ = host.start!()
        let timer = JSClosure { [weak self] _ in
            self?.pump()
            return .undefined
        }
        self.timer = timer
        timerID = JSObject.global.setInterval!(timer, pumpInterval)
    }

    public func stop() {
        if let timer {
            _ = JSObject.global.clearInterval!(timerID)
            timer.release()
        }
        timer = nil
        render = nil
        _ = host.stop!()
    }

    /// Tops the worklet's queue up to `bufferDuration`. The timer calls it; calling it once per
    /// frame as well keeps the queue fuller when timers run late.
    public func pump() {
        guard let render else { return }
        let target = Int(bufferDuration * sampleRate)
        var wanted = Int(host.wanted!(target).number ?? 0)
        // Whole render quanta, so chunks line up with the worklet's 128-frame blocks.
        wanted = wanted / 128 * 128
        guard wanted > 0 else { return }
        if scratch.count < wanted * 2 { scratch = [Float](repeating: 0, count: wanted * 2) }
        let chunk = scratch.withUnsafeMutableBufferPointer { buffer -> JSTypedArray<Float32> in
            render(buffer.baseAddress!, wanted)
            return JSTypedArray<Float32>(buffer: UnsafeBufferPointer(rebasing: buffer[0..<wanted * 2]))
        }
        _ = host.push!(chunk)
    }

    public var stats: Stats {
        Stats(state: host.context.state.string ?? "", chunks: Int(host.chunks.number ?? 0), framesSent: Int(host.sent.number ?? 0),
              underruns: Int(host.underruns.number ?? 0), underrunFrames: Int(host.underrunFrames.number ?? 0),
              droppedFrames: Int(host.dropped.number ?? 0), queuedFrames: Int(host.queued.number ?? 0))
    }

    /// The JS side: the AudioContext, the worklet (from a Blob URL), the queue estimate the
    /// pump asks for, and resuming on the first gesture. Called as `new Function("sampleRate", …)`.
    private static let hostSource = #"""
    const AC = globalThis.AudioContext || globalThis.webkitAudioContext;
    if (!AC) return { error: "this browser has no AudioContext" };
    const context = sampleRate ? new AC({ latencyHint: "interactive", sampleRate }) : new AC({ latencyHint: "interactive" });
    const processor = `
    class AcroOutput extends AudioWorkletProcessor {
      constructor(options) {
        super();
        this.chunks = []; this.offset = 0; this.queued = 0; this.received = 0;
        this.started = false; this.underruns = 0; this.underrunFrames = 0; this.dropped = 0; this.blocks = 0; this.peak = 0;
        this.maxQueued = options.processorOptions.maxQueued;
        this.port.onmessage = (e) => {
          const chunk = e.data;
          this.chunks.push(chunk);
          this.queued += chunk.length / 2;
          this.received += chunk.length / 2;
          this.started = true;
          // Far behind (the main thread stalled, then caught up): drop the oldest audio.
          while (this.queued > this.maxQueued && this.chunks.length > 1) {
            const old = this.chunks.shift();
            const frames = old.length / 2 - this.offset;
            this.offset = 0; this.queued -= frames; this.dropped += frames;
          }
        };
      }
      process(inputs, outputs) {
        const out = outputs[0];
        const left = out[0], right = out[1] || out[0];
        const n = left.length;
        let i = 0;
        while (i < n && this.chunks.length > 0) {
          const chunk = this.chunks[0];
          const take = Math.min(chunk.length / 2 - this.offset, n - i);
          for (let k = 0; k < take; k++) {
            const s = (this.offset + k) * 2;
            left[i + k] = chunk[s]; right[i + k] = chunk[s + 1];
            this.peak = Math.max(this.peak, Math.abs(chunk[s]), Math.abs(chunk[s + 1]));
          }
          i += take; this.offset += take;
          if (this.offset * 2 >= chunk.length) { this.chunks.shift(); this.offset = 0; }
        }
        this.queued -= i;
        if (i < n) {
          left.fill(0, i); if (right !== left) right.fill(0, i);
          if (this.started) { this.underruns++; this.underrunFrames += n - i; }
        }
        if (++this.blocks % 4 === 0) {
          this.port.postMessage({ queued: this.queued, received: this.received, time: currentTime,
                                  underruns: this.underruns, underrunFrames: this.underrunFrames, dropped: this.dropped, peak: this.peak });
          this.peak = 0;
        }
        return true;
      }
    }
    registerProcessor("acro-output", AcroOutput);
    `;
    const url = URL.createObjectURL(new Blob([processor], { type: "application/javascript" }));
    const gestures = ["pointerdown", "mousedown", "keydown", "touchend"];
    const host = {
      context, node: null, ready: false, error: null, running: false,
      chunks: 0, sent: 0, received: 0, queued: 0, reportTime: 0, underruns: 0, underrunFrames: 0, dropped: 0, resumes: 0, peak: 0, reports: 0,
      get state() { return context.state; },
    };
    const resume = () => {
      if (context.state === "suspended") { host.resumes++; context.resume().catch(() => {}); }
    };
    host.start = () => {
      host.running = true;
      for (const type of gestures) globalThis.addEventListener(type, resume, { capture: true });
      resume();  // allowed when the page already had a gesture (or autoplay is permitted)
      if (host.node || host.loading) return;
      host.loading = true;
      context.audioWorklet.addModule(url).then(() => {
        const node = new AudioWorkletNode(context, "acro-output", {
          numberOfInputs: 0, numberOfOutputs: 1, outputChannelCount: [2],
          processorOptions: { maxQueued: Math.round(context.sampleRate * 0.25) },
        });
        node.port.onmessage = (e) => {
          const r = e.data;
          host.queued = r.queued; host.received = r.received; host.reportTime = r.time;
          host.underruns = r.underruns; host.underrunFrames = r.underrunFrames; host.dropped = r.dropped;
          host.peak = r.peak; host.reports++;
        };
        node.connect(context.destination);
        host.node = node;
        host.ready = true;
      }).catch((e) => { host.error = String(e); console.error("Web Audio worklet failed:", e); });
    };
    host.stop = () => {
      host.running = false;
      for (const type of gestures) globalThis.removeEventListener(type, resume, { capture: true });
    };
    // Frames to render now to have `target` queued: the worklet's last report, less what it has
    // played since (by the context's clock), plus what was posted after that report.
    host.wanted = (target) => {
      if (!host.ready || !host.running || context.state !== "running") return 0;
      const played = Math.max(0, context.currentTime - host.reportTime) * context.sampleRate;
      const estimate = Math.max(0, host.queued - played) + (host.sent - host.received);
      return Math.max(0, Math.floor(target - estimate));
    };
    host.push = (chunk) => {
      host.sent += chunk.length / 2;  // before the transfer empties it
      host.chunks++;
      host.node.port.postMessage(chunk, [chunk.buffer]);
    };
    host.close = () => {
      host.stop();
      if (host.node) host.node.disconnect();
      context.close().catch(() => {});
      URL.revokeObjectURL(url);
    };
    return host;
    """#
}
#endif
