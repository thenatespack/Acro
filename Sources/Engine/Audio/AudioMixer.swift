import Foundation

// The audio-thread half of the engine's mixer. `AudioSystem` (game thread) owns it and talks to
// it only through a lock-free command queue; the mixer reports back through atomic words.
//
// ## Real-time safety
//
// `render(_:frames:)` runs on the device's real-time thread. It never allocates, frees, locks
// or waits:
// - All state lives in buffers allocated once in `init` (voices, buses, per-bus mix buffers),
//   held through unsafe pointers so no copy-on-write can ever trigger.
// - Commands arrive through `CommandQueue` (single producer, single consumer, atomics only).
//   Commands are plain values; sample data is passed as raw pointers that the game thread
//   keeps alive until the mixer reports the voice finished.
// - The mixer reports back by storing to atomic words: the generation of each voice it
//   finished, per-bus peak levels and per-voice positions. The game thread polls them.
// - The only reference counting on the audio thread is on the mixer object itself, which the
//   device and the `AudioSystem` keep alive, so nothing can be deallocated there.
//
// ## Signal flow
//
// Each voice reads its source (a `SoundBuffer` or a streamed ring) through a 2-frame window
// with linear interpolation, advancing by `step = sourceRate / deviceRate * pitch` per output
// frame; that one step does both sample-rate conversion and pitch. It is scaled by a smoothed
// left/right gain (volume and balance pan) and a fade (start, stop, pause), and summed into its
// bus. Buses are processed children first: each applies its smoothed volume (0 when muted),
// ducking and pause gains, measures its peak and sums into its parent. The master bus is
// clamped to [-1, 1] into the output. Every gain change ramps linearly, so nothing clicks.
//
// Effects (see AudioEffects.swift): a voice is rendered into a scratch buffer, then runs
// through its spatial filter (distance and head-shadow low-pass) and its own filter, and is
// added to its bus and, scaled by its send level, to a send bus. A bus mixes its voices,
// children and sends, runs its effect chain (filters, reverb), then applies its gains. A send
// to a bus that was already processed this block is heard one block (5 ms) late. Reverb delay
// lines belong to the game thread, which keeps them alive until the device stops.

/// Where a voice's frames come from.
struct VoiceSource {
    /// Interleaved `SoundBuffer` samples (nil for a stream).
    var samples: UnsafePointer<Float>?
    var frameCount: Int
    var channels: Int
    var sampleRate: Double
    /// Looping region for buffers: after `loopEnd` playback continues at `loopStart`.
    var loopStart: Int
    var loopEnd: Int
    var stream: StreamRing?
}

struct VoiceStart {
    var source: VoiceSource
    var bus: Int
    var volume: Float
    var pan: Float
    var pitch: Float
    var loop: Bool
    var fadeIn: Double
    /// Set for a spatial voice: the gains and cutoffs to start at (so it doesn't ramp in from full volume).
    var spatial: SpatialStart?
}

struct SpatialStart {
    var gainL: Float
    var gainR: Float
    var cutoffL: Float
    var cutoffR: Float
}

/// A filter or reverb for a voice or a bus effect slot.
enum EffectSpec {
    case none
    case filter(type: AudioFilterType, cutoff: Float, q: Float)
    case reverb(roomSize: Float, damping: Float, width: Float, wet: Float, dry: Float, memory: ReverbRef)
}

enum AudioCommand {
    case start(slot: Int, generation: UInt64, VoiceStart)
    case setVoice(slot: Int, generation: UInt64, volume: Float, pan: Float, pitch: Float)
    /// A spatial voice's per-frame update: final gains (volume, attenuation and pan), pitch with Doppler, cutoffs.
    case setVoiceSpatial(slot: Int, generation: UInt64, gainL: Float, gainR: Float, pitch: Float, cutoffL: Float, cutoffR: Float)
    case setVoiceFilter(slot: Int, generation: UInt64, EffectSpec)
    /// `bus` -1 removes the send.
    case setVoiceSend(slot: Int, generation: UInt64, bus: Int, level: Float)
    case setBusEffect(bus: Int, slot: Int, EffectSpec)
    case setBusSend(bus: Int, target: Int, level: Float)
    case pauseVoice(slot: Int, generation: UInt64, paused: Bool, fade: Double)
    case stopVoice(slot: Int, generation: UInt64, fade: Double)
    case setBus(index: Int, parent: Int, volume: Float, muted: Bool, paused: Bool)
    /// `trigger` -1 removes the ducking.
    case setDucking(bus: Int, trigger: Int, gain: Float, attack: Double, release: Double)
}

/// A gain that moves linearly toward `target` by `step` per sample.
struct Ramp {
    var value: Float
    var target: Float
    var step: Float = .infinity

    init(_ value: Float) {
        self.value = value
        target = value
    }

    /// Ramps from the current value to `target` over `seconds`.
    mutating func set(_ target: Float, seconds: Double, sampleRate: Double) {
        self.target = target
        let frames = Float(seconds * sampleRate)
        step = frames >= 1 ? abs(target - value) / frames : .infinity
    }

    @inline(__always) mutating func next() -> Float {
        if value != target {
            value = value < target ? min(value + step, target) : max(value - step, target)
        }
        return value
    }

    var isSettled: Bool { value == target }
}

private struct VoiceState {
    var active = false
    var generation: UInt64 = 0
    var source = VoiceSource(samples: nil, frameCount: 0, channels: 1, sampleRate: 1, loopStart: 0, loopEnd: 0, stream: nil)
    var bus = 0
    var loop = false
    var step = 1.0
    var pitch: Float = 1
    /// Spatial voices glide `step` toward this once per block (Doppler changes without zipper).
    var stepTarget = 1.0
    var smoothStep = false
    // Read window: the output interpolates between `a` and `b` at `frac`.
    var primed = false
    var aL: Float = 0, aR: Float = 0, bL: Float = 0, bR: Float = 0
    var frac = 0.0
    /// `b` is the silence after the last frame; the next shift ends the voice.
    var draining = false
    /// Next buffer frame to read.
    var readIndex = 0
    /// Stream frames read but not yet published to the ring, and frames known to be available.
    var streamRead: UInt64 = 0
    var streamAvailable: UInt64 = 0
    /// Source frames consumed (for the position the game thread sees).
    var consumed: UInt64 = 0
    var gainL = Ramp(1), gainR = Ramp(1)
    var fade = Ramp(1)
    var stopping = false
    var paused = false
    var spatialFilter = StereoFilter()
    var filter = StereoFilter()
    var sendBus = -1
    var sendLevel = Ramp(0)
}

/// One slot of a bus's effect chain.
private struct EffectState {
    enum Kind { case none, filter, reverb }
    var kind = Kind.none
    var filter = StereoFilter()
    var reverb: ReverbRef?
    var feedback: Float = 0.84
    var damping: Float = 0.2
    var width: Float = 1
    var wet = Ramp(1)
    var dry = Ramp(0)
}

private struct BusState {
    var used = false
    var parent = -1
    var volume = Ramp(1)
    var duck = Ramp(1)
    var pause = Ramp(1)
    var paused = false
    var duckTrigger = -1
    var duckGain: Float = 1
    var duckAttack = 0.0
    var duckRelease = 0.0
    var sendTarget = -1
    var sendLevel = Ramp(0)
    // Per block.
    var activeVoices = 0
    var effectivelyPaused = false
    var effectivePause: Float = 1
}

final class AudioMixer: @unchecked Sendable {
    static let blockSize = 256
    /// How long volume, pan and bus volume changes take.
    static let smoothingSeconds = 0.01
    /// Spatial gains glide a little longer: they are retargeted once per game frame.
    static let spatialSmoothingSeconds = 0.02
    /// Effect slots per bus.
    static let effectsPerBus = 4

    let sampleRate: Double
    let maxVoices: Int
    let maxBuses: Int
    let commands = CommandQueue(capacity: 4096)
    /// Per voice slot: the generation of the last voice the mixer finished there.
    let finished: AtomicWords
    /// Per voice slot: source frames consumed.
    let positions: AtomicWords
    /// Per bus: the peak output level since the game thread last read it (float bits).
    let peaks: AtomicWords
    /// [0]: stream underruns (frames a streamed voice wanted but the ring didn't have yet).
    let counters = AtomicWords(count: 1)

    private let voices: UnsafeMutablePointer<VoiceState>
    private let buses: UnsafeMutablePointer<BusState>
    /// `maxBuses` interleaved stereo buffers of `blockSize` frames.
    private let busBuffers: UnsafeMutablePointer<Float>
    /// Per bus, the sends waiting to be mixed into it (consumed and cleared when the bus is processed).
    private let sendBuffers: UnsafeMutablePointer<Float>
    /// One voice's stereo block before filtering.
    private let voiceScratch: UnsafeMutablePointer<Float>
    private let effects: UnsafeMutablePointer<EffectState>
    /// Per block: how far spatial voices glide toward their target pitch.
    private var stepGlide = 0.0

    init(sampleRate: Double, maxVoices: Int, maxBuses: Int) {
        self.sampleRate = sampleRate
        self.maxVoices = maxVoices
        self.maxBuses = maxBuses
        finished = AtomicWords(count: maxVoices)
        positions = AtomicWords(count: maxVoices)
        peaks = AtomicWords(count: maxBuses)
        voices = .allocate(capacity: maxVoices)
        voices.initialize(repeating: VoiceState(), count: maxVoices)
        buses = .allocate(capacity: maxBuses)
        buses.initialize(repeating: BusState(), count: maxBuses)
        buses[0].used = true  // master
        busBuffers = .allocate(capacity: maxBuses * Self.blockSize * 2)
        busBuffers.initialize(repeating: 0, count: maxBuses * Self.blockSize * 2)
        sendBuffers = .allocate(capacity: maxBuses * Self.blockSize * 2)
        sendBuffers.initialize(repeating: 0, count: maxBuses * Self.blockSize * 2)
        voiceScratch = .allocate(capacity: Self.blockSize * 2)
        voiceScratch.initialize(repeating: 0, count: Self.blockSize * 2)
        effects = .allocate(capacity: maxBuses * Self.effectsPerBus)
        effects.initialize(repeating: EffectState(), count: maxBuses * Self.effectsPerBus)
    }

    deinit {
        voices.deallocate()
        buses.deallocate()
        busBuffers.deallocate()
        sendBuffers.deallocate()
        voiceScratch.deallocate()
        effects.deallocate()
        finished.free()
        positions.free()
        peaks.free()
        counters.free()
    }

    /// Fills `frames` frames of interleaved stereo. Real-time safe (see above).
    func render(_ output: UnsafeMutablePointer<Float>, frames: Int) {
        while let command = commands.pop() { apply(command) }
        var done = 0
        while done < frames {
            let n = min(Self.blockSize, frames - done)
            renderBlock(output + done * 2, frames: n)
            done += n
        }
    }

    // MARK: - Commands

    private func apply(_ command: AudioCommand) {
        switch command {
        case .start(let slot, let generation, let start):
            var voice = VoiceState()
            voice.active = true
            voice.generation = generation
            voice.source = start.source
            voice.bus = buses[start.bus].used ? start.bus : 0
            voice.loop = start.loop
            voice.pitch = start.pitch
            voice.step = start.source.sampleRate / sampleRate * Double(start.pitch)
            voice.stepTarget = voice.step
            if let stream = start.source.stream { voice.streamRead = stream.read }
            let (l, r) = Self.panGains(volume: start.volume, pan: start.pan)
            voice.gainL = Ramp(l)
            voice.gainR = Ramp(r)
            if let spatial = start.spatial {
                voice.gainL = Ramp(spatial.gainL)
                voice.gainR = Ramp(spatial.gainR)
                voice.smoothStep = true
                voice.spatialFilter.set(type: .lowPass, cutoffL: spatial.cutoffL, cutoffR: spatial.cutoffR, q: 0.7071,
                                        immediate: true)
            }
            if start.fadeIn > 0 {
                voice.fade = Ramp(0)
                voice.fade.set(1, seconds: start.fadeIn, sampleRate: sampleRate)
            }
            voices[slot] = voice
        case .setVoice(let slot, let generation, let volume, let pan, let pitch):
            guard voices[slot].active, voices[slot].generation == generation else { return }
            let (l, r) = Self.panGains(volume: volume, pan: pan)
            voices[slot].gainL.set(l, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
            voices[slot].gainR.set(r, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
            voices[slot].pitch = pitch
            voices[slot].step = voices[slot].source.sampleRate / sampleRate * Double(pitch)
            voices[slot].stepTarget = voices[slot].step
            voices[slot].smoothStep = false
        case .setVoiceSpatial(let slot, let generation, let gainL, let gainR, let pitch, let cutoffL, let cutoffR):
            guard voices[slot].active, voices[slot].generation == generation else { return }
            voices[slot].gainL.set(gainL, seconds: Self.spatialSmoothingSeconds, sampleRate: sampleRate)
            voices[slot].gainR.set(gainR, seconds: Self.spatialSmoothingSeconds, sampleRate: sampleRate)
            voices[slot].pitch = pitch
            voices[slot].stepTarget = voices[slot].source.sampleRate / sampleRate * Double(pitch)
            voices[slot].smoothStep = true
            voices[slot].spatialFilter.set(type: .lowPass, cutoffL: cutoffL, cutoffR: cutoffR, q: 0.7071, immediate: false)
        case .setVoiceFilter(let slot, let generation, let spec):
            guard voices[slot].active, voices[slot].generation == generation else { return }
            if case .filter(let type, let cutoff, let q) = spec {
                voices[slot].filter.set(type: type, cutoffL: cutoff, cutoffR: cutoff, q: q, immediate: false)
            } else {
                voices[slot].filter.reset()
            }
        case .setVoiceSend(let slot, let generation, let bus, let level):
            guard voices[slot].active, voices[slot].generation == generation else { return }
            if bus != voices[slot].sendBus {
                voices[slot].sendBus = bus
                voices[slot].sendLevel = Ramp(0)
            }
            voices[slot].sendLevel.set(bus >= 0 ? max(level, 0) : 0, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
        case .setBusEffect(let bus, let slot, let spec):
            applyEffect(spec, to: bus * Self.effectsPerBus + slot)
        case .setBusSend(let bus, let target, let level):
            if target != buses[bus].sendTarget {
                buses[bus].sendTarget = target
                buses[bus].sendLevel = Ramp(0)
            }
            buses[bus].sendLevel.set(target >= 0 ? max(level, 0) : 0, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
        case .pauseVoice(let slot, let generation, let paused, let fade):
            guard voices[slot].active, voices[slot].generation == generation, !voices[slot].stopping else { return }
            voices[slot].paused = paused
            voices[slot].fade.set(paused ? 0 : 1, seconds: fade, sampleRate: sampleRate)
        case .stopVoice(let slot, let generation, let fade):
            guard voices[slot].active, voices[slot].generation == generation else { return }
            if voices[slot].paused && voices[slot].fade.value == 0 {
                finish(slot)
            } else {
                voices[slot].stopping = true
                voices[slot].paused = false
                voices[slot].fade.set(0, seconds: fade, sampleRate: sampleRate)
            }
        case .setBus(let index, let parent, let volume, let muted, let paused):
            let wasUsed = buses[index].used
            buses[index].used = true
            buses[index].parent = index == 0 ? -1 : parent
            let target = muted ? 0 : max(volume, 0)
            if wasUsed {
                buses[index].volume.set(target, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
                buses[index].pause.set(paused ? 0 : 1, seconds: Self.smoothingSeconds, sampleRate: sampleRate)
            } else {
                buses[index].volume = Ramp(target)
                buses[index].pause = Ramp(paused ? 0 : 1)
            }
            buses[index].paused = paused
        case .setDucking(let bus, let trigger, let gain, let attack, let release):
            buses[bus].duckTrigger = trigger
            buses[bus].duckGain = min(max(gain, 0), 1)
            buses[bus].duckAttack = attack
            buses[bus].duckRelease = release
        }
    }

    private func applyEffect(_ spec: EffectSpec, to index: Int) {
        switch spec {
        case .none:
            effects[index] = EffectState()
        case .filter(let type, let cutoff, let q):
            if effects[index].kind != .filter { effects[index] = EffectState() }
            effects[index].kind = .filter
            effects[index].filter.set(type: type, cutoffL: cutoff, cutoffR: cutoff, q: q, immediate: false)
        case .reverb(let roomSize, let damping, let width, let wet, let dry, let memory):
            if effects[index].kind != .reverb || effects[index].reverb?.delay != memory.delay {
                memory.clear()
                effects[index] = EffectState()
                effects[index].kind = .reverb
                effects[index].reverb = memory
                effects[index].wet = Ramp(max(wet, 0))
                effects[index].dry = Ramp(max(dry, 0))
            }
            effects[index].feedback = ReverbRef.feedback(roomSize: roomSize)
            effects[index].damping = min(max(damping, 0), 1) * 0.4
            effects[index].width = min(max(width, 0), 1)
            effects[index].wet.set(max(wet, 0), seconds: Self.smoothingSeconds, sampleRate: sampleRate)
            effects[index].dry.set(max(dry, 0), seconds: Self.smoothingSeconds, sampleRate: sampleRate)
        }
    }

    /// Balance pan: center plays both channels at `volume`; panning attenuates the far side.
    static func panGains(volume: Float, pan: Float) -> (Float, Float) {
        let pan = min(max(pan, -1), 1)
        return (volume * (1 - max(pan, 0)), volume * (1 + min(pan, 0)))
    }

    private func finish(_ slot: Int) {
        voices[slot].active = false
        if let stream = voices[slot].source.stream { stream.publishRead(voices[slot].streamRead) }
        finished.store(slot, voices[slot].generation)
    }

    // MARK: - Mixing

    private func renderBlock(_ output: UnsafeMutablePointer<Float>, frames: Int) {
        let busCount = (0..<maxBuses).last { buses[$0].used }.map { $0 + 1 } ?? 1

        // Which buses are paused (directly or through a parent) and which have something playing.
        for i in 0..<busCount where buses[i].used {
            let parent = buses[i].parent
            let parentPaused = parent >= 0 ? buses[parent].effectivelyPaused : false
            let parentPause: Float = parent >= 0 ? buses[parent].effectivePause : 1
            buses[i].effectivelyPaused = buses[i].paused || parentPaused
            buses[i].effectivePause = buses[i].pause.value * parentPause
            buses[i].activeVoices = 0
        }
        for v in 0..<maxVoices where voices[v].active && !voices[v].paused && !voices[v].stopping {
            buses[voices[v].bus].activeVoices += 1
        }
        for i in stride(from: busCount - 1, to: 0, by: -1) where buses[i].used && buses[i].parent >= 0 {
            buses[buses[i].parent].activeVoices += buses[i].activeVoices
        }
        // Ducking: ramp toward the ducked gain while the trigger bus has playing voices.
        for i in 0..<busCount where buses[i].used {
            let trigger = buses[i].duckTrigger
            let ducked = trigger >= 0 && trigger < busCount && buses[trigger].activeVoices > 0
                && !buses[trigger].effectivelyPaused
            let target: Float = trigger >= 0 && ducked ? buses[i].duckGain : 1
            if buses[i].duck.target != target {
                let range = max(1 - buses[i].duckGain, 1e-6)
                let seconds = ducked ? buses[i].duckAttack : buses[i].duckRelease
                let frames = Float(seconds * sampleRate)
                buses[i].duck.target = target
                buses[i].duck.step = frames >= 1 ? range / frames : .infinity
            }
        }

        busBuffers.update(repeating: 0, count: busCount * Self.blockSize * 2)
        stepGlide = 1 - exp(-Double(frames) / (sampleRate * 0.03))

        for v in 0..<maxVoices where voices[v].active {
            let bus = voices[v].bus
            // A paused bus holds its voices once its fade-out is done.
            if buses[bus].effectivelyPaused && buses[bus].effectivePause == 0 { continue }
            renderVoice(v, busCount: busCount, frames: frames)
        }

        // Buses, children first (a child always has a higher index than its parent).
        for i in stride(from: busCount - 1, through: 0, by: -1) where buses[i].used {
            let buffer = busBuffers + i * Self.blockSize * 2
            // Sends that arrived for this bus (from voices, and from buses processed before it).
            let incoming = sendBuffers + i * Self.blockSize * 2
            for k in 0..<frames * 2 { buffer[k] += incoming[k] }
            incoming.update(repeating: 0, count: Self.blockSize * 2)
            for e in 0..<Self.effectsPerBus {
                let index = i * Self.effectsPerBus + e
                switch effects[index].kind {
                case .none: break
                case .filter:
                    effects[index].filter.run(buffer, frames: frames, sampleRate: sampleRate)
                case .reverb:
                    var state = effects[index]
                    state.reverb?.process(buffer, frames: frames, feedback: state.feedback, damping: state.damping,
                                          width: state.width, wet: &state.wet, dry: &state.dry)
                    effects[index].wet = state.wet
                    effects[index].dry = state.dry
                }
            }
            var peak: Float = 0
            for k in 0..<frames {
                let gain = buses[i].volume.next() * buses[i].duck.next() * buses[i].pause.next()
                let l = buffer[2 * k] * gain
                let r = buffer[2 * k + 1] * gain
                buffer[2 * k] = l
                buffer[2 * k + 1] = r
                peak = max(peak, abs(l), abs(r))
            }
            peaks.maxFloat(i, peak)
            if i == 0 { break }
            let target = buses[i].sendTarget
            if target >= 0, target < busCount, target != i, buses[target].used,
               !(buses[i].sendLevel.isSettled && buses[i].sendLevel.value == 0) {
                let destination = sendBuffers + target * Self.blockSize * 2
                for k in 0..<frames {
                    let level = buses[i].sendLevel.next()
                    destination[2 * k] += buffer[2 * k] * level
                    destination[2 * k + 1] += buffer[2 * k + 1] * level
                }
            }
            let parent = buses[i].parent >= 0 && buses[buses[i].parent].used ? buses[i].parent : 0
            let destination = busBuffers + parent * Self.blockSize * 2
            for k in 0..<frames * 2 { destination[k] += buffer[k] }
        }
        for k in 0..<frames * 2 { output[k] = min(max(busBuffers[k], -1), 1) }
    }

    private enum Fetch { case frame, end, starved }

    /// Reads the next source frame into the window's `b`.
    @inline(__always) private func fetch(_ voice: inout VoiceState) -> Fetch {
        let source = voice.source
        if let samples = source.samples {
            let end = voice.loop ? source.loopEnd : source.frameCount
            if voice.readIndex >= end {
                guard voice.loop, source.loopEnd > source.loopStart else { return .end }
                voice.readIndex = source.loopStart
            }
            let i = voice.readIndex
            voice.readIndex += 1
            if source.channels == 1 {
                voice.bL = samples[i]
                voice.bR = voice.bL
            } else {
                voice.bL = samples[2 * i]
                voice.bR = samples[2 * i + 1]
            }
            return .frame
        }
        guard let ring = source.stream else { return .end }
        if voice.streamAvailable == 0 {
            let written = ring.written
            voice.streamAvailable = written - voice.streamRead
            if voice.streamAvailable == 0 {
                // Check the end flag after the count: the writer sets it after its last frames.
                return ring.isFinished && ring.written == voice.streamRead ? .end : .starved
            }
        }
        let i = Int(voice.streamRead % UInt64(ring.capacity))
        if ring.channels == 1 {
            voice.bL = ring.samples[i]
            voice.bR = voice.bL
        } else {
            voice.bL = ring.samples[2 * i]
            voice.bR = ring.samples[2 * i + 1]
        }
        voice.streamRead += 1
        voice.streamAvailable -= 1
        return .frame
    }

    /// Renders a voice into the scratch buffer, filters it, and adds it to its bus and send bus.
    private func renderVoice(_ slot: Int, busCount: Int, frames: Int) {
        let scratch = voiceScratch
        scratch.update(repeating: 0, count: frames * 2)
        renderVoiceSource(slot, into: scratch, frames: frames)
        if voices[slot].spatialFilter.active {
            voices[slot].spatialFilter.run(scratch, frames: frames, sampleRate: sampleRate)
        }
        if voices[slot].filter.active {
            voices[slot].filter.run(scratch, frames: frames, sampleRate: sampleRate)
        }
        let destination = busBuffers + voices[slot].bus * Self.blockSize * 2
        for k in 0..<frames * 2 { destination[k] += scratch[k] }
        let sendBus = voices[slot].sendBus
        var send = voices[slot].sendLevel
        if sendBus >= 0, sendBus < busCount, buses[sendBus].used, !(send.isSettled && send.value == 0) {
            let target = sendBuffers + sendBus * Self.blockSize * 2
            for k in 0..<frames {
                let level = send.next()
                target[2 * k] += scratch[2 * k] * level
                target[2 * k + 1] += scratch[2 * k + 1] * level
            }
            voices[slot].sendLevel = send
        }
    }

    private func renderVoiceSource(_ slot: Int, into buffer: UnsafeMutablePointer<Float>, frames: Int) {
        var voice = voices[slot]
        if voice.smoothStep && voice.step != voice.stepTarget {
            voice.step += (voice.stepTarget - voice.step) * stepGlide
            if abs(voice.step - voice.stepTarget) < voice.stepTarget * 1e-5 { voice.step = voice.stepTarget }
        }
        defer {
            if let stream = voice.source.stream { stream.publishRead(voice.streamRead) }
            positions.store(slot, voice.consumed)
            voices[slot] = voice
            if !voice.active { finished.store(slot, voice.generation) }
        }
        // Paused and faded out: hold position.
        if voice.paused && voice.fade.isSettled && voice.fade.value == 0 { return }

        if !voice.primed {
            switch fetch(&voice) {
            case .starved: counters.store(0, counters.load(0) &+ UInt64(frames)); return
            case .end: voice.active = false; return
            case .frame: break
            }
            voice.aL = voice.bL
            voice.aR = voice.bR
            switch fetch(&voice) {
            case .frame: break
            case .end:
                // A one-frame source.
                voice.bL = 0
                voice.bR = 0
                voice.draining = true
            case .starved:
                // A stream with only one frame decoded so far: put it back and try again next block.
                voice.streamRead -= 1
                voice.streamAvailable += 1
                return
            }
            voice.primed = true
        }

        for k in 0..<frames {
            while voice.frac >= 1 {
                if voice.draining {
                    voice.active = false
                    return
                }
                let previous = (voice.aL, voice.aR)
                voice.aL = voice.bL
                voice.aR = voice.bR
                switch fetch(&voice) {
                case .frame:
                    voice.frac -= 1
                    voice.consumed += 1
                case .end:
                    voice.bL = 0
                    voice.bR = 0
                    voice.draining = true
                    voice.frac -= 1
                    voice.consumed += 1
                case .starved:
                    // Not decoded yet: undo the shift and wait (silence for the rest of this block).
                    voice.bL = voice.aL
                    voice.bR = voice.aR
                    (voice.aL, voice.aR) = previous
                    counters.store(0, counters.load(0) &+ UInt64(frames - k))
                    return
                }
            }
            let t = Float(voice.frac)
            let l = voice.aL + (voice.bL - voice.aL) * t
            let r = voice.aR + (voice.bR - voice.aR) * t
            let fade = voice.fade.next()
            buffer[2 * k] += l * voice.gainL.next() * fade
            buffer[2 * k + 1] += r * voice.gainR.next() * fade
            if fade == 0 && voice.fade.target == 0 {
                if voice.stopping {
                    voice.active = false
                    return
                }
                if voice.paused { return }
            }
            voice.frac += voice.step
        }
    }
}
