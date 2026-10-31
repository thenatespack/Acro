import Foundation

/// The engine's sound output: voices (one-shot, looping and streamed), a bus tree with volume,
/// mute, pause and ducking, all mixed in Swift on the audio thread (see `AudioMixer` for the
/// real-time rules). Reach it as `engine.audio`, or make one with any `AudioDevice`.
///
/// ```swift
/// let shot = try SoundBuffer(contentsOf: url)
/// engine.audio.play(shot, volume: 0.8, pitch: 1.1, pan: -0.3)          // one-shot on the sfx bus
/// let music = try engine.audio.playStream(contentsOf: songURL)         // looping, on the music bus
/// engine.audio.duck(engine.audio.music, while: engine.audio.voice)     // music dips under dialogue
/// engine.audio.music.volume = 0.5
/// music.stop(fade: 1)
///
/// engine.audio.listener.position = cameraPosition                      // 3D: where the ears are
/// let step = engine.audio.play(shot, at: Vec3(4, 0, -2))               // attenuated, panned, Doppler
/// let reverb = engine.audio.addBus("reverb")                           // effects: a reverb send bus
/// reverb.effects = [.reverb(AudioReverb(roomSize: 0.8))]
/// engine.audio.sfx.send(to: reverb, level: 0.3)
/// step.filter = AudioFilter(.lowPass, cutoff: 1200)                    // a voice effect
/// ```
///
/// Use it from one thread (the game's main thread). Calls only queue commands for the audio
/// thread, so they take effect within one device buffer (a few milliseconds), smoothed so
/// nothing clicks. `update(dt:)` (the engine calls it every frame) tops up streams, frees
/// voices that ended, and with an offline device renders the elapsed time.
///
/// Spatial voices (`play(_:at:)`, `Voice.worldPosition`) are recomputed from `listener` and their
/// emitter data on every change and once per `update`; the ECS `AudioListener` / `AudioEmitter`
/// components do that from transforms (`World.addSpatialAudio`).
public final class AudioSystem {
    public let device: AudioDevice
    /// The device's rate; everything is converted to it.
    public var sampleRate: Double { device.sampleRate }
    public let maxVoices: Int
    public static let maxBuses = 32
    /// Default fade for stop / pause / resume, in seconds: short enough to feel instant, long
    /// enough not to click.
    public static let defaultFade = 0.01
    /// Seconds of audio a stream keeps decoded ahead (`update` must run at least this often).
    public static let streamBufferSeconds = 2.0

    /// Everything ends up here; the device plays it.
    public private(set) var master: AudioBus!
    /// Default bus for `playStream`.
    public private(set) var music: AudioBus!
    /// Default bus for `play`.
    public private(set) var sfx: AudioBus!
    /// For dialogue; `duck(music, while: voice)` lowers the music while it plays.
    public private(set) var voice: AudioBus!

    let mixer: AudioMixer
    private var busInfo: [BusInfo] = []
    private var slots: [Slot]
    private var freeSlots: [Int]
    private var nextGeneration: UInt64 = 1
    private var pendingCommands: [AudioCommand] = []
    private var levels: [Float]
    private var offlineFrameDebt = 0.0
    private var isShutDown = false
    private var sounds: [String: SoundBuffer] = [:]
    /// Reverb delay lines per (bus, effect slot). Kept until the system is freed, because the audio thread holds pointers.
    private var reverbMemory: [Int: ReverbMemory] = [:]
    private var derivedListenerVelocity = Vec3.zero
    private var previousListenerPosition: Vec3?

    /// Where the ears are for spatial voices.
    public var listener = AudioListenerState() {
        didSet { if listener != oldValue { refreshSpatial() } }
    }

    private struct BusInfo {
        var name: String
        var parent: Int
        var volume: Float = 1
        var muted = false
        var paused = false
        var ducking: Ducking?
        var effects: [AudioEffect] = []
        var sendTarget = -1
        var sendLevel: Float = 0
    }

    /// A bus's ducking: lowered to `gain` while `trigger` has playing voices.
    public struct Ducking: Equatable, Sendable {
        public var trigger: AudioBus.ID
        public var gain: Float
        public var attack: Double
        public var release: Double
    }

    fileprivate struct Slot {
        var generation: UInt64 = 0
        var inUse = false
        var sound: SoundBuffer?
        var stream: AudioStream?
        var bus = 0
        var volume: Float = 1
        var pan: Float = 0
        var pitch: Float = 1
        var paused = false
        var stopping = false
        var loop = false
        var name = ""
        var filter: AudioFilter?
        var sendBus = -1
        var sendLevel: Float = 0
        // Spatial voices (nil settings: plain volume and pan).
        var spatial: SpatialSettings?
        var emitterPosition = Vec3.zero
        var emitterVelocity: Vec3?
        var emitterDirection: Vec3?
        var derivedVelocity = Vec3.zero
        var previousPosition: Vec3?
        var sent: SpatialSend?
    }

    /// What was last sent for a spatial voice, to skip commands that change nothing.
    fileprivate struct SpatialSend: Equatable {
        var gainL: Float, gainR: Float, pitch: Float, cutoffL: Float, cutoffR: Float
    }

    /// Starts `device`. Throws if it can't start.
    public init(device: AudioDevice, maxVoices: Int = 64) throws {
        self.device = device
        self.maxVoices = maxVoices
        mixer = AudioMixer(sampleRate: device.sampleRate, maxVoices: maxVoices, maxBuses: Self.maxBuses)
        slots = Array(repeating: Slot(), count: maxVoices)
        freeSlots = Array((0..<maxVoices).reversed())
        levels = Array(repeating: 0, count: Self.maxBuses)
        busInfo.append(BusInfo(name: "master", parent: -1))
        master = AudioBus(system: self, index: 0)
        music = addBus("music")
        sfx = addBus("sfx")
        voice = addBus("voice")
        flush()
        let mixer = mixer
        try device.start { output, frames in mixer.render(output, frames: frames) }
    }

    /// An `AudioSystem` on `makeDefaultDevice(headless:)`, falling back to the offline device
    /// if the chosen one fails to start.
    public static func makeDefault(headless: Bool = false) -> AudioSystem {
        let device = makeDefaultDevice(headless: headless)
        do {
            let system = try AudioSystem(device: device)
            EngineLog.info("Audio: \(device.name)", category: .audio)
            return system
        } catch {
            EngineLog.warning("Audio device \(device.name) failed to start (\(error)); using the offline device (silent)", category: .audio)
            return try! AudioSystem(device: OfflineAudioDevice())  // the offline device can't fail
        }
    }

    deinit {
        shutdown()
    }

    /// Stops the device and releases every voice. Further calls do nothing audible.
    public func shutdown() {
        guard !isShutDown else { return }
        isShutDown = true
        device.stop()
        if streamUnderruns > 0 { EngineLog.warning("\(streamUnderruns) frames of stream underrun (update ran too rarely)", category: .audio) }
        for i in slots.indices where slots[i].inUse { release(i) }
    }

    // MARK: - Buses

    /// Adds a bus under `parent` (master by default). At most `maxBuses` buses in total;
    /// past that, returns master (printed).
    @discardableResult
    public func addBus(_ name: String, parent: AudioBus? = nil) -> AudioBus {
        guard busInfo.count < Self.maxBuses else {
            EngineLog.warning("no room for bus '\(name)' (max \(Self.maxBuses)); using master", category: .audio)
            return master
        }
        busInfo.append(BusInfo(name: name, parent: parent?.index ?? 0))
        let index = busInfo.count - 1
        sendBus(index)
        return AudioBus(system: self, index: index)
    }

    /// Every bus, master first.
    public var buses: [AudioBus] { busInfo.indices.map { AudioBus(system: self, index: $0) } }

    public func bus(named name: String) -> AudioBus? {
        busInfo.firstIndex { $0.name == name }.map { AudioBus(system: self, index: $0) }
    }

    /// Lowers `bus` to `gain` while `trigger` (or a bus under it) has playing voices, ramping
    /// down over `attack` seconds and back up over `release` (each for the full range).
    public func duck(_ bus: AudioBus, while trigger: AudioBus, to gain: Float = 0.3, attack: Double = 0.08,
                     release: Double = 0.4) {
        precondition(bus.index != trigger.index, "A bus can't duck itself")
        busInfo[bus.index].ducking = Ducking(trigger: trigger.index, gain: gain, attack: attack, release: release)
        send(.setDucking(bus: bus.index, trigger: trigger.index, gain: gain, attack: attack, release: release))
    }

    /// Removes `bus`'s ducking (it ramps back up over its release time).
    public func stopDucking(_ bus: AudioBus) {
        guard let ducking = busInfo[bus.index].ducking else { return }
        busInfo[bus.index].ducking = nil
        send(.setDucking(bus: bus.index, trigger: -1, gain: ducking.gain, attack: ducking.attack, release: ducking.release))
    }

    fileprivate func busName(_ index: Int) -> String { busInfo[index].name }
    fileprivate func busParent(_ index: Int) -> Int? { busInfo[index].parent >= 0 ? busInfo[index].parent : nil }
    fileprivate func busDucking(_ index: Int) -> Ducking? { busInfo[index].ducking }
    fileprivate func busVolume(_ index: Int) -> Float { busInfo[index].volume }
    fileprivate func busMuted(_ index: Int) -> Bool { busInfo[index].muted }
    fileprivate func busPaused(_ index: Int) -> Bool { busInfo[index].paused }
    fileprivate func busLevel(_ index: Int) -> Float { levels[index] }
    fileprivate func busEffects(_ index: Int) -> [AudioEffect] { busInfo[index].effects }
    fileprivate func busSend(_ index: Int) -> (target: Int, level: Float) { (busInfo[index].sendTarget, busInfo[index].sendLevel) }

    fileprivate func setBusEffects(_ index: Int, _ effects: [AudioEffect]) {
        let list = Array(effects.prefix(AudioMixer.effectsPerBus))
        busInfo[index].effects = list
        for slot in 0..<AudioMixer.effectsPerBus {
            send(.setBusEffect(bus: index, slot: slot, slot < list.count ? effectSpec(list[slot], key: index * AudioMixer.effectsPerBus + slot) : .none))
        }
    }

    private func effectSpec(_ effect: AudioEffect, key: Int) -> EffectSpec {
        switch effect {
        case .filter(let f):
            return .filter(type: f.type, cutoff: f.cutoff, q: f.q)
        case .reverb(let r):
            let memory = reverbMemory[key] ?? ReverbMemory(sampleRate: sampleRate)
            reverbMemory[key] = memory
            return .reverb(roomSize: r.roomSize, damping: r.damping, width: r.width, wet: r.wet, dry: r.dry, memory: memory.ref)
        }
    }

    fileprivate func setBusSend(_ index: Int, to target: AudioBus?, level: Float) {
        precondition(target?.index != index, "A bus can't send to itself")
        busInfo[index].sendTarget = target?.index ?? -1
        busInfo[index].sendLevel = max(level, 0)
        send(.setBusSend(bus: index, target: busInfo[index].sendTarget, level: busInfo[index].sendLevel))
    }
    fileprivate func setBus(_ index: Int, volume: Float? = nil, muted: Bool? = nil, paused: Bool? = nil) {
        if let volume { busInfo[index].volume = max(volume, 0) }
        if let muted { busInfo[index].muted = muted }
        if let paused { busInfo[index].paused = paused }
        sendBus(index)
    }

    private func sendBus(_ index: Int) {
        let info = busInfo[index]
        send(.setBus(index: index, parent: info.parent, volume: info.volume, muted: info.muted, paused: info.paused))
    }

    // MARK: - Playing

    /// Plays `sound` on `bus` (sfx by default). `pitch` scales speed and pitch together (0.5 is
    /// an octave down); `pan` goes from -1 (left) to 1 (right). A looping sound repeats
    /// `loopRange` (frames; the whole sound by default) after playing up to its end. Returns
    /// an inert voice (printed) when all `maxVoices` voices are busy.
    @discardableResult
    public func play(_ sound: SoundBuffer, on bus: AudioBus? = nil, volume: Float = 1, pitch: Float = 1, pan: Float = 0,
                     loop: Bool = false, loopRange: Range<Int>? = nil, fadeIn: Double = 0) -> Voice {
        let range = (loopRange ?? 0..<sound.frameCount).clamped(to: 0..<sound.frameCount)
        let source = VoiceSource(samples: UnsafePointer(sound.storage), frameCount: sound.frameCount,
                                 channels: sound.channelCount, sampleRate: sound.sampleRate,
                                 loopStart: range.lowerBound, loopEnd: range.upperBound, stream: nil)
        return start(source, bus: bus ?? sfx, volume: volume, pitch: pitch, pan: pan, loop: loop, fadeIn: fadeIn,
                     name: sound.name) { $0.sound = sound }
    }

    /// Plays `sound` as a 3D voice at `position`: attenuated by distance, panned and low-passed
    /// by its direction relative to `listener`, and pitch-shifted by Doppler as it or the listener
    /// moves. Move it with `Voice.worldPosition`. Mono sounds work best (a stereo one is balanced,
    /// not spread). `settings` sets the distance model, cone and Doppler.
    @discardableResult
    public func play(_ sound: SoundBuffer, at position: Vec3, settings: SpatialSettings = SpatialSettings(),
                     on bus: AudioBus? = nil, volume: Float = 1, pitch: Float = 1, loop: Bool = false,
                     loopRange: Range<Int>? = nil, fadeIn: Double = 0) -> Voice {
        let range = (loopRange ?? 0..<sound.frameCount).clamped(to: 0..<sound.frameCount)
        let source = VoiceSource(samples: UnsafePointer(sound.storage), frameCount: sound.frameCount,
                                 channels: sound.channelCount, sampleRate: sound.sampleRate,
                                 loopStart: range.lowerBound, loopEnd: range.upperBound, stream: nil)
        return start(source, bus: bus ?? sfx, volume: volume, pitch: pitch, pan: 0, loop: loop, fadeIn: fadeIn,
                     spatial: (settings, position), name: sound.name) { $0.sound = sound }
    }

    /// Makes `sound` findable by `name` (`sound(named:)`), which is how `AudioEmitter` components refer to sounds.
    public func register(_ sound: SoundBuffer, as name: String) { sounds[name] = sound }

    public func sound(named name: String) -> SoundBuffer? { sounds[name] }

    /// Streams `decoder` on `bus` (music by default): about `streamBufferSeconds` are decoded
    /// ahead, topped up by `update`. Looping rewinds the decoder at its end, seamlessly.
    @discardableResult
    public func playStream(_ decoder: AudioDecoder, on bus: AudioBus? = nil, volume: Float = 1, pitch: Float = 1,
                           pan: Float = 0, loop: Bool = true, fadeIn: Double = 0, name: String = "stream") -> Voice {
        let stream = AudioStream(decoder: decoder, loop: loop,
                                 capacityFrames: max(Int(decoder.sampleRate * Self.streamBufferSeconds), 4096))
        stream.fill()
        let source = VoiceSource(samples: nil, frameCount: decoder.frameCount ?? 0, channels: decoder.channelCount,
                                 sampleRate: decoder.sampleRate, loopStart: 0, loopEnd: 0, stream: stream.ring)
        let voice = start(source, bus: bus ?? music, volume: volume, pitch: pitch, pan: pan, loop: loop, fadeIn: fadeIn,
                          name: name) { $0.stream = stream }
        if !voice.isValid { stream.close() }
        return voice
    }

    /// Streams a WAV, Ogg Vorbis or MP3 file (see `playStream(_:)`).
    @discardableResult
    public func playStream(contentsOf url: URL, on bus: AudioBus? = nil, volume: Float = 1, pitch: Float = 1,
                           pan: Float = 0, loop: Bool = true, fadeIn: Double = 0) throws -> Voice {
        try playStream(AudioFile.decoder(contentsOf: url), on: bus, volume: volume, pitch: pitch, pan: pan, loop: loop,
                       fadeIn: fadeIn, name: url.deletingPathExtension().lastPathComponent)
    }

    private func start(_ source: VoiceSource, bus: AudioBus, volume: Float, pitch: Float, pan: Float, loop: Bool,
                       fadeIn: Double, spatial: (settings: SpatialSettings, position: Vec3)? = nil, name: String,
                       retain: (inout Slot) -> Void) -> Voice {
        reclaimFinishedVoices()
        guard !isShutDown, let slot = freeSlots.popLast() else {
            if !isShutDown { EngineLog.warning("all \(maxVoices) voices busy; '\(name)' not played", category: .audio) }
            return Voice(system: self, slot: -1, generation: 0)
        }
        let generation = nextGeneration
        nextGeneration += 1
        let pitch = Self.clampPitch(pitch)
        var info = Slot(generation: generation, inUse: true, bus: bus.index, volume: max(volume, 0), pan: pan,
                        pitch: pitch, loop: loop, name: name)
        retain(&info)
        var startPitch = pitch
        var spatialStart: SpatialStart?
        if let spatial {
            info.spatial = spatial.settings
            info.emitterPosition = spatial.position
            info.previousPosition = spatial.position
            let result = spatialResult(info)
            startPitch = Self.clampPitch(pitch * result.pitch)
            spatialStart = SpatialStart(gainL: result.gainL, gainR: result.gainR, cutoffL: result.cutoffL, cutoffR: result.cutoffR)
            info.sent = SpatialSend(gainL: result.gainL, gainR: result.gainR, pitch: startPitch, cutoffL: result.cutoffL,
                                    cutoffR: result.cutoffR)
        }
        slots[slot] = info
        send(.start(slot: slot, generation: generation,
                    VoiceStart(source: source, bus: bus.index, volume: info.volume, pan: pan, pitch: startPitch, loop: loop,
                               fadeIn: fadeIn, spatial: spatialStart)))
        return Voice(system: self, slot: slot, generation: generation)
    }

    private static func clampPitch(_ pitch: Float) -> Float { min(max(pitch, 1.0 / 64), 64) }

    /// Stops every voice (on `bus` and the buses under it, if given).
    public func stopAll(on bus: AudioBus? = nil, fade: Double = AudioSystem.defaultFade) {
        for voice in activeVoices where bus.map({ isUnder(voice.busIndex, $0.index) }) ?? true {
            voice.stop(fade: fade)
        }
    }

    private func isUnder(_ index: Int, _ ancestor: Int) -> Bool {
        var current = index
        while current >= 0 {
            if current == ancestor { return true }
            current = busInfo[current].parent
        }
        return false
    }

    /// Voices that haven't ended (including paused and fading-out ones).
    public var activeVoices: [Voice] {
        slots.indices.filter { slots[$0].inUse && mixer.finished.load($0) != slots[$0].generation }
            .map { Voice(system: self, slot: $0, generation: slots[$0].generation) }
    }

    /// Frames streamed voices wanted but weren't decoded yet (each one played as silence).
    /// Nonzero means `update` ran too rarely for `streamBufferSeconds`.
    public var streamUnderruns: Int { Int(mixer.counters.load(0)) }

    // MARK: - Voice access (used by `Voice`)

    fileprivate func slotIfCurrent(_ voice: Voice) -> Int? {
        guard voice.slot >= 0, slots[voice.slot].inUse, slots[voice.slot].generation == voice.generation else { return nil }
        return voice.slot
    }

    fileprivate func isPlaying(_ voice: Voice) -> Bool {
        guard let slot = slotIfCurrent(voice) else { return false }
        return mixer.finished.load(slot) != voice.generation
    }

    fileprivate func info(_ voice: Voice) -> Slot? { slotIfCurrent(voice).map { slots[$0] } }

    fileprivate func setVoice(_ voice: Voice, volume: Float? = nil, pan: Float? = nil, pitch: Float? = nil) {
        guard let slot = slotIfCurrent(voice) else { return }
        if let volume { slots[slot].volume = max(volume, 0) }
        if let pan { slots[slot].pan = min(max(pan, -1), 1) }
        if let pitch { slots[slot].pitch = Self.clampPitch(pitch) }
        let s = slots[slot]
        if s.spatial != nil {
            sendSpatial(slot)
        } else {
            send(.setVoice(slot: slot, generation: s.generation, volume: s.volume, pan: s.pan, pitch: s.pitch))
        }
    }

    // MARK: - Spatial and effects (used by `Voice`)

    private func spatialResult(_ s: Slot) -> SpatialResult {
        SpatialAudio.compute(listener: listener, listenerVelocity: listener.velocity ?? derivedListenerVelocity,
                             position: s.emitterPosition, velocity: s.emitterVelocity ?? s.derivedVelocity,
                             direction: s.emitterDirection, settings: s.spatial ?? SpatialSettings(), volume: s.volume)
    }

    /// Recomputes a spatial voice and queues the result if it changed.
    private func sendSpatial(_ slot: Int) {
        guard slots[slot].inUse, slots[slot].spatial != nil else { return }
        let result = spatialResult(slots[slot])
        let pitch = Self.clampPitch(slots[slot].pitch * result.pitch)
        let sent = SpatialSend(gainL: result.gainL, gainR: result.gainR, pitch: pitch, cutoffL: result.cutoffL,
                               cutoffR: result.cutoffR)
        guard sent != slots[slot].sent else { return }
        slots[slot].sent = sent
        send(.setVoiceSpatial(slot: slot, generation: slots[slot].generation, gainL: sent.gainL, gainR: sent.gainR,
                              pitch: sent.pitch, cutoffL: sent.cutoffL, cutoffR: sent.cutoffR))
    }

    private func refreshSpatial() {
        for i in slots.indices where slots[i].inUse && slots[i].spatial != nil { sendSpatial(i) }
    }

    fileprivate func setSpatial(_ voice: Voice, _ settings: SpatialSettings?) {
        guard let slot = slotIfCurrent(voice) else { return }
        if let settings {
            guard settings != slots[slot].spatial else { return }
            slots[slot].spatial = settings
            sendSpatial(slot)
        } else if slots[slot].spatial != nil {
            // Back to plain volume and pan, with the spatial low-pass opened.
            slots[slot].spatial = nil
            slots[slot].sent = nil
            let s = slots[slot]
            let (l, r) = AudioMixer.panGains(volume: s.volume, pan: s.pan)
            send(.setVoiceSpatial(slot: slot, generation: s.generation, gainL: l, gainR: r, pitch: s.pitch,
                                  cutoffL: StereoFilter.openCutoff, cutoffR: StereoFilter.openCutoff))
            send(.setVoice(slot: slot, generation: s.generation, volume: s.volume, pan: s.pan, pitch: s.pitch))
        }
    }

    fileprivate func setEmitter(_ voice: Voice, position: Vec3? = nil, velocity: Vec3?? = nil, direction: Vec3?? = nil) {
        guard let slot = slotIfCurrent(voice) else { return }
        if slots[slot].spatial == nil { slots[slot].spatial = SpatialSettings() }
        if let position { slots[slot].emitterPosition = position }
        if let velocity { slots[slot].emitterVelocity = velocity }
        if let direction { slots[slot].emitterDirection = direction }
        sendSpatial(slot)
    }

    fileprivate func setFilter(_ voice: Voice, _ filter: AudioFilter?) {
        guard let slot = slotIfCurrent(voice), slots[slot].filter != filter else { return }
        slots[slot].filter = filter
        let spec: EffectSpec = filter.map { .filter(type: $0.type, cutoff: $0.cutoff, q: $0.q) } ?? .none
        send(.setVoiceFilter(slot: slot, generation: voice.generation, spec))
    }

    fileprivate func setSend(_ voice: Voice, to bus: AudioBus?, level: Float) {
        guard let slot = slotIfCurrent(voice) else { return }
        slots[slot].sendBus = bus?.index ?? -1
        slots[slot].sendLevel = max(level, 0)
        send(.setVoiceSend(slot: slot, generation: voice.generation, bus: slots[slot].sendBus, level: slots[slot].sendLevel))
    }

    fileprivate func pause(_ voice: Voice, _ paused: Bool, fade: Double) {
        guard let slot = slotIfCurrent(voice), !slots[slot].stopping, slots[slot].paused != paused else { return }
        slots[slot].paused = paused
        send(.pauseVoice(slot: slot, generation: voice.generation, paused: paused, fade: fade))
    }

    fileprivate func stop(_ voice: Voice, fade: Double) {
        guard let slot = slotIfCurrent(voice), !slots[slot].stopping else { return }
        slots[slot].stopping = true
        send(.stopVoice(slot: slot, generation: voice.generation, fade: fade))
    }

    fileprivate func position(_ voice: Voice) -> Double {
        guard let slot = slotIfCurrent(voice) else { return 0 }
        let s = slots[slot]
        var frames = Int(mixer.positions.load(slot))
        let rate: Double
        if let sound = s.sound {
            rate = sound.sampleRate
            if s.loop && frames >= sound.frameCount && sound.frameCount > 0 { frames %= sound.frameCount }
        } else if let stream = s.stream {
            rate = stream.sampleRate
            if let count = stream.frameCount, count > 0, s.loop { frames %= count }
        } else {
            return 0
        }
        return Double(frames) / rate
    }

    // MARK: - Per frame

    /// Call once per frame (`Engine.run` does): frees voices that ended, tops up streams and
    /// reads bus levels. With an offline device it also renders `dt` seconds (silently), so
    /// voices progress and end just as they would on a real device.
    public func update(dt: Double) {
        guard !isShutDown else { return }
        updateSpatial(dt: dt)
        flush()
        reclaimFinishedVoices()
        for i in slots.indices where slots[i].inUse { slots[i].stream?.fill() }
        if let offline = device as? OfflineAudioDevice {
            offlineFrameDebt += dt * sampleRate
            let frames = Int(offlineFrameDebt)
            offlineFrameDebt -= Double(frames)
            renderOffline(offline, frames: frames, keep: false)
            reclaimFinishedVoices()
        }
        for i in busInfo.indices { levels[i] = mixer.peaks.exchangeFloat(i, 0) }
    }

    /// Derives velocities from movement since the last call, then recomputes every spatial voice.
    private func updateSpatial(dt: Double) {
        if dt > 0, let previous = previousListenerPosition {
            derivedListenerVelocity = (listener.position - previous) / Float(dt)
        } else {
            derivedListenerVelocity = .zero
        }
        previousListenerPosition = listener.position
        for i in slots.indices where slots[i].inUse && slots[i].spatial != nil {
            if dt > 0, let previous = slots[i].previousPosition {
                slots[i].derivedVelocity = (slots[i].emitterPosition - previous) / Float(dt)
            } else {
                slots[i].derivedVelocity = .zero
            }
            slots[i].previousPosition = slots[i].emitterPosition
            sendSpatial(i)
        }
    }

    /// Renders `frames` frames with an offline device and returns them (interleaved stereo),
    /// topping up streams as it goes. For tests and offline bouncing; requires an `OfflineAudioDevice`.
    public func render(frames: Int) -> [Float] {
        guard let offline = device as? OfflineAudioDevice else {
            preconditionFailure("AudioSystem.render(frames:) needs an OfflineAudioDevice")
        }
        flush()
        reclaimFinishedVoices()
        let output = renderOffline(offline, frames: frames, keep: true)
        reclaimFinishedVoices()
        for i in busInfo.indices { levels[i] = mixer.peaks.exchangeFloat(i, 0) }
        return output
    }

    @discardableResult
    private func renderOffline(_ offline: OfflineAudioDevice, frames: Int, keep: Bool) -> [Float] {
        var output: [Float] = keep ? [] : []
        if keep { output.reserveCapacity(frames * 2) }
        // Chunks well under the stream buffer, refilling streams in between as a game loop would.
        let chunk = 1024
        var done = 0
        while done < frames {
            let n = min(chunk, frames - done)
            for i in slots.indices where slots[i].inUse { slots[i].stream?.fill() }
            if keep { output += offline.render(frames: n) } else { offline.advance(frames: n) }
            done += n
        }
        return output
    }

    // MARK: - Internals

    private func send(_ command: AudioCommand) {
        if pendingCommands.isEmpty && mixer.commands.push(command) { return }
        pendingCommands.append(command)
        flush()
    }

    /// Retries commands that didn't fit in the queue, in order.
    private func flush() {
        var sent = 0
        while sent < pendingCommands.count, mixer.commands.push(pendingCommands[sent]) { sent += 1 }
        if sent > 0 { pendingCommands.removeFirst(sent) }
    }

    /// Frees the slots of voices the mixer has finished (and the sounds/streams they held).
    private func reclaimFinishedVoices() {
        for i in slots.indices where slots[i].inUse && mixer.finished.load(i) == slots[i].generation {
            release(i)
            freeSlots.append(i)
        }
    }

    private func release(_ slot: Int) {
        slots[slot].stream?.close()
        slots[slot] = Slot(generation: slots[slot].generation)
    }
}

/// A handle to one playing sound. Stays valid after the sound ends (then it does nothing and
/// `isPlaying` is false); a slot reused by a later sound doesn't affect old handles.
public struct Voice: Hashable {
    let system: AudioSystem?
    let slot: Int
    let generation: UInt64

    init(system: AudioSystem, slot: Int, generation: UInt64) {
        self.system = slot >= 0 ? system : nil
        self.slot = slot
        self.generation = generation
    }

    public static func == (a: Voice, b: Voice) -> Bool {
        a.system === b.system && a.slot == b.slot && a.generation == b.generation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(slot)
        hasher.combine(generation)
    }

    /// False for the handle `play` returns when every voice was busy.
    public var isValid: Bool { system != nil }
    /// Until the sound ends or is stopped (and its fade-out finishes). True while paused.
    public var isPlaying: Bool { system?.isPlaying(self) ?? false }
    public var isPaused: Bool { system?.info(self)?.paused ?? false }
    public var name: String { system?.info(self)?.name ?? "" }
    fileprivate var busIndex: Int { system?.info(self)?.bus ?? -1 }
    /// The bus it plays on (nil once ended).
    public var bus: AudioBus? { system.flatMap { s in s.info(self).map { AudioBus(system: s, index: $0.bus) } } }
    /// Seconds into the source (within the loop for looping sounds), as of the last mix.
    public var position: Double { system?.position(self) ?? 0 }

    /// Linear gain (1 = unchanged). Changes ramp over 10 ms.
    public var volume: Float {
        get { system?.info(self)?.volume ?? 0 }
        nonmutating set { system?.setVoice(self, volume: newValue) }
    }

    /// Playback speed and pitch (1 = original, 2 = an octave up). Clamped to 1/64...64.
    public var pitch: Float {
        get { system?.info(self)?.pitch ?? 1 }
        nonmutating set { system?.setVoice(self, pitch: newValue) }
    }

    /// -1 (left) ... 1 (right). Balance pan: center plays both channels at full volume.
    public var pan: Float {
        get { system?.info(self)?.pan ?? 0 }
        nonmutating set { system?.setVoice(self, pan: newValue) }
    }

    /// A filter on this voice (after its spatial low-pass); nil for none. Cutoff changes glide.
    public var filter: AudioFilter? {
        get { system?.info(self)?.filter }
        nonmutating set { system?.setFilter(self, newValue) }
    }

    /// Where the voice is for 3D audio (nil for a plain voice). Setting it makes the voice spatial
    /// (default `spatial` settings); setting nil makes it plain again.
    public var worldPosition: Vec3? {
        get { system?.info(self).flatMap { $0.spatial != nil ? $0.emitterPosition : nil } }
        nonmutating set {
            if let newValue { system?.setEmitter(self, position: newValue) } else { system?.setSpatial(self, nil) }
        }
    }

    /// Meters per second, for Doppler. nil (the default) derives it from how `worldPosition` changes between updates.
    public var worldVelocity: Vec3? {
        get { system?.info(self)?.emitterVelocity }
        nonmutating set { system?.setEmitter(self, velocity: .some(newValue)) }
    }

    /// The way the sound points, for the cone. nil for omnidirectional.
    public var worldDirection: Vec3? {
        get { system?.info(self)?.emitterDirection }
        nonmutating set { system?.setEmitter(self, direction: .some(newValue)) }
    }

    /// Distance model, cone and Doppler of a spatial voice (nil for a plain voice).
    public var spatial: SpatialSettings? {
        get { system?.info(self)?.spatial }
        nonmutating set { system?.setSpatial(self, newValue) }
    }

    /// Sends the voice's signal (after its volume, pan and filters) to `bus` at `level`, in addition to its own bus.
    /// Typically a bus with a reverb. nil removes the send.
    public func setSend(to bus: AudioBus?, level: Float) { system?.setSend(self, to: bus, level: level) }
    public var sendBus: AudioBus? {
        guard let system, let info = system.info(self), info.sendBus >= 0 else { return nil }
        return AudioBus(system: system, index: info.sendBus)
    }
    public var sendLevel: Float { system?.info(self)?.sendLevel ?? 0 }

    /// Fades out over `fade` seconds, then ends.
    public func stop(fade: Double = AudioSystem.defaultFade) { system?.stop(self, fade: fade) }
    /// Fades out over `fade` seconds and holds the position.
    public func pause(fade: Double = AudioSystem.defaultFade) { system?.pause(self, true, fade: fade) }
    /// Fades back in from where it paused.
    public func resume(fade: Double = AudioSystem.defaultFade) { system?.pause(self, false, fade: fade) }
}

/// A mixer bus: voices on it (and buses under it) are summed, scaled by its volume, ducking
/// and pause, and sent to its parent. Changes ramp over 10 ms.
public struct AudioBus: Hashable {
    public typealias ID = Int
    let system: AudioSystem
    public let index: ID

    public static func == (a: AudioBus, b: AudioBus) -> Bool { a.system === b.system && a.index == b.index }
    public func hash(into hasher: inout Hasher) { hasher.combine(index) }

    public var name: String { system.busName(index) }
    public var parent: AudioBus? { system.busParent(index).map { AudioBus(system: system, index: $0) } }
    public var ducking: AudioSystem.Ducking? { system.busDucking(index) }

    /// Linear gain (1 = unchanged).
    public var volume: Float {
        get { system.busVolume(index) }
        nonmutating set { system.setBus(index, volume: newValue) }
    }

    /// Silences the bus without forgetting its volume; voices keep playing.
    public var isMuted: Bool {
        get { system.busMuted(index) }
        nonmutating set { system.setBus(index, muted: newValue) }
    }

    /// Fades the bus out and holds every voice on it (and under it) where it is.
    public var isPaused: Bool {
        get { system.busPaused(index) }
        nonmutating set { system.setBus(index, paused: newValue) }
    }

    /// Up to `AudioMixer.effectsPerBus` (4) effects run in order on the bus's mix, before its volume.
    /// A reverb here is usually a send target (`wet` 1, `dry` 0). Cutoff and mix changes glide.
    public var effects: [AudioEffect] {
        get { system.busEffects(index) }
        nonmutating set { system.setBusEffects(index, newValue) }
    }

    /// Sends this bus's output (after effects and volume) to `target` at `level`, in addition to its parent.
    /// Any bus but itself works; a target processed earlier in the block hears it one block (5 ms) late.
    public func send(to target: AudioBus?, level: Float) { system.setBusSend(index, to: target, level: level) }
    public var sendTarget: AudioBus? {
        let target = system.busSend(index).target
        return target >= 0 ? AudioBus(system: system, index: target) : nil
    }
    public var sendLevel: Float { system.busSend(index).level }

    /// Peak output level (after volume, mute and ducking; 1 = full scale) over what was mixed
    /// between the last two `update` calls.
    public var level: Float { system.busLevel(index) }
}

/// Decodes a stream on the game thread into the ring a streamed voice reads.
final class AudioStream {
    let ring: StreamRing
    let decoder: AudioDecoder
    let loop: Bool
    var sampleRate: Double { decoder.sampleRate }
    var frameCount: Int? { decoder.frameCount }
    private var written: UInt64 = 0
    private var ended = false
    private var closed = false
    private var scratch: [Float]

    init(decoder: AudioDecoder, loop: Bool, capacityFrames: Int) {
        self.decoder = decoder
        self.loop = loop
        ring = StreamRing(capacityFrames: capacityFrames, channels: decoder.channelCount)
        scratch = [Float](repeating: 0, count: 4096 * decoder.channelCount)
    }

    deinit { close() }

    /// Decodes into the free part of the ring.
    func fill() {
        guard !ended, !closed else { return }
        let channels = ring.channels
        var free = ring.capacity - Int(written - ring.read)
        var emptyReadsInARow = 0
        while free > 0 {
            let wanted = min(free, scratch.count / channels)
            let got: Int
            do {
                got = try scratch.withUnsafeMutableBufferPointer { try decoder.read(into: $0.baseAddress!, frames: wanted) }
            } catch {
                EngineLog.error("Audio stream decode failed: \(error)", category: .audio)
                got = 0
                emptyReadsInARow = 2
            }
            if got == 0 {
                emptyReadsInARow += 1
                if loop && emptyReadsInARow < 2, (try? decoder.rewind()) != nil { continue }
                ended = true
                break
            }
            emptyReadsInARow = 0
            for f in 0..<got {
                let i = Int((written + UInt64(f)) % UInt64(ring.capacity))
                for c in 0..<channels { ring.samples[i * channels + c] = scratch[f * channels + c] }
            }
            written += UInt64(got)
            free -= got
        }
        ring.publishWritten(written)
        if ended { ring.markFinished() }
    }

    func close() {
        guard !closed else { return }
        closed = true
        ring.free()
    }
}
