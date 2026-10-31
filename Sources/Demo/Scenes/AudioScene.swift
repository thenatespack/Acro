import Engine
import Foundation

/// The audio system (`engine.audio`): a streamed, looping music track (generated here and
/// streamed from an in-memory WAV), one-shots with pitch and pan, a looping ambience on a user
/// bus with its pan swept over time, and dialogue on the voice bus that ducks the music.
/// Every sound is synthesized at startup, so the scene needs no files. Bus meters, a level
/// history and the active voices are drawn with the UI draw list.
///
/// Keys: **B** blip (steps up a scale), **K** kick, **H** hi-hat (alternating sides), **T** a line of
/// "dialogue" (ducks the music), **M** music on/off, **L** ambience on/off, **X** mute music,
/// **P** pause the sfx bus, **G** toggle ducking. A short scripted intro (kick, blip, dialogue)
/// plays when the scene opens.
///
/// Under `ENGINE_SCREENSHOT` the engine uses the offline audio device, which renders exactly
/// one frame's worth of audio per frame, so the meters in the screenshot are deterministic.
final class AudioScene: DemoScene {
    static let name = "audio"
    static let summary = "Audio: streamed music, one-shots, pitch/pan, buses, ducking, meters"

    private static let sampleRate = 48000.0
    private static let panel = UIColor(hex: 0x1b2130)
    private static let border = UIColor(hex: 0x323b52)
    private static let text = UIColor(hex: 0xe6e9f0)
    private static let dim = UIColor(hex: 0x8a93a8)
    private static let accent = UIColor(hex: 0x3fb6ff)
    private static let warm = UIColor(hex: 0xf5a623)
    private static let green = UIColor(hex: 0x34c759)
    private static let red = UIColor(hex: 0xff5a4f)
    private static let historyLength = 240

    private let musicData: Data
    private let blip: SoundBuffer
    private let kick: SoundBuffer
    private let hat: SoundBuffer
    private let line: SoundBuffer
    private let drone: SoundBuffer

    private var audio: AudioSystem?
    private var ambienceBus: AudioBus?
    private var music: Voice?
    private var ambience: Voice?
    private var ownVoices: [Voice] = []
    private var blipStep = 0
    private var hatSide: Float = -1
    private var ducking = true
    private var time: Float = 0
    private var scriptIndex = 0
    /// Per bus: the last `historyLength` levels, oldest first.
    private var history: [[Float]] = []
    private var meters: [(name: String, level: Float, volume: Float, flags: String)] = []
    private var voiceRows: [String] = []
    private var deviceName = ""

    init(renderer: Renderer) throws {
        musicData = Self.makeMusic()
        blip = Self.makeBlip()
        kick = Self.makeKick()
        hat = Self.makeHat()
        line = Self.makeLine()
        drone = Self.makeDrone()
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.006, 0.007, 0.012)) }
    var status: String { "music \(music?.isPlaying == true ? "on" : "off"), ducking \(ducking ? "on" : "off")" }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func willClose() {
        for voice in ownVoices { voice.stop(fade: 0.2) }
        if let audio {
            audio.stopDucking(audio.music)
            audio.music.isMuted = false
            audio.sfx.isPaused = false
        }
    }

    // MARK: - Update

    func update(engine: Engine, dt: Float, time t: Float) {
        let audio = setUp(engine.audio)
        let input = engine.input
        time = t

        // A scripted intro, so the scene (and its screenshot) shows every kind of voice.
        let script: [(at: Float, action: () -> Void)] = [
            (0.25, { self.playKick() }), (0.5, { self.playBlip() }), (0.6, { self.playLine() }),
        ]
        while scriptIndex < script.count, t >= script[scriptIndex].at {
            script[scriptIndex].action()
            scriptIndex += 1
        }

        if input.wasPressed(.b) { playBlip() }
        if input.wasPressed(.k) { playKick() }
        if input.wasPressed(.h) {
            track(audio.play(hat, volume: 0.5, pitch: 1, pan: hatSide * 0.8))
            hatSide = -hatSide
        }
        if input.wasPressed(.t) { playLine() }
        if input.wasPressed(.m) { toggleMusic(audio) }
        if input.wasPressed(.l) {
            if let ambience, ambience.isPlaying { ambience.stop(fade: 0.5); self.ambience = nil } else { startAmbience(audio) }
        }
        if input.wasPressed(.x) { audio.music.isMuted.toggle() }
        if input.wasPressed(.p) { audio.sfx.isPaused.toggle() }
        if input.wasPressed(.g) {
            ducking.toggle()
            if ducking { audio.duck(audio.music, while: audio.voice, to: 0.25) } else { audio.stopDucking(audio.music) }
        }

        // Sweep the ambience across the stereo field.
        ambience?.pan = sinf(t * 0.8) * 0.9
        ownVoices.removeAll { !$0.isPlaying }
        gatherDisplay(audio)
    }

    private func setUp(_ system: AudioSystem) -> AudioSystem {
        if let audio { return audio }
        audio = system
        deviceName = system.device.name
        ambienceBus = system.bus(named: "ambience") ?? system.addBus("ambience")
        system.duck(system.music, while: system.voice, to: 0.25, attack: 0.08, release: 0.5)
        toggleMusic(system)
        startAmbience(system)
        return system
    }

    private func track(_ voice: Voice) {
        if voice.isValid { ownVoices.append(voice) }
    }

    private func playBlip() {
        guard let audio else { return }
        let scale: [Float] = [0, 2, 4, 7, 9, 12, 14, 16]  // major pentatonic-ish, in semitones
        let semitones = scale[blipStep % scale.count]
        blipStep += 1
        track(audio.play(blip, volume: 0.6, pitch: powf(2, semitones / 12), pan: Float(blipStep % 3 - 1) * 0.5))
    }

    private func playKick() {
        guard let audio else { return }
        track(audio.play(kick, volume: 0.9))
    }

    private func playLine() {
        guard let audio else { return }
        track(audio.play(line, on: audio.voice, volume: 0.7))
    }

    private func toggleMusic(_ audio: AudioSystem) {
        if let music, music.isPlaying {
            music.stop(fade: 0.6)
            self.music = nil
        } else if let decoder = try? WAVDecoder(data: musicData) {
            let voice = audio.playStream(decoder, volume: 0.55, fadeIn: 0.05, name: "music (stream)")
            music = voice
            track(voice)
        }
    }

    private func startAmbience(_ audio: AudioSystem) {
        let voice = audio.play(drone, on: ambienceBus, volume: 0.35, loop: true, fadeIn: 0.3)
        ambience = voice
        track(voice)
    }

    private func gatherDisplay(_ audio: AudioSystem) {
        let buses = audio.buses
        if history.count != buses.count { history = Array(repeating: Array(repeating: 0, count: Self.historyLength), count: buses.count) }
        meters = []
        for (i, bus) in buses.enumerated() {
            history[i].removeFirst()
            history[i].append(bus.level)
            var flags: [String] = []
            if bus.isMuted { flags.append("muted") }
            if bus.isPaused { flags.append("paused") }
            if let ducking = bus.ducking {
                let trigger = buses.first { $0.index == ducking.trigger }?.name ?? "?"
                flags.append("ducks under \(trigger)")
            }
            if let parent = bus.parent, parent != audio.master { flags.append("in \(parent.name)") }
            meters.append((bus.name, bus.level, bus.volume, flags.joined(separator: ", ")))
        }
        voiceRows = audio.activeVoices.map { voice in
            let bus = voice.bus?.name ?? "-"
            let state = voice.isPaused ? " paused" : ""
            return String(format: "%@  ·  %@  ·  %.2f s  ·  vol %.2f  pitch %.2f  pan %+.2f%@",
                          voice.name, bus, voice.position, voice.volume, voice.pitch, voice.pan, state)
        }
    }

    // MARK: - Drawing

    func drawUI(_ ui: UIDrawList) {
        let canvas = UIRect(x: 0, y: 0, width: 1280, height: 720)
        let origin = Vec2(max((ui.size.x - canvas.width) / 2, 0), max((ui.size.y - canvas.height) / 2, 0))
        func at(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> UIRect {
            UIRect(x: origin.x + x, y: origin.y + y, width: w, height: h)
        }
        func text(_ s: String, _ x: Float, _ y: Float, size: Float = 14, color: UIColor = AudioScene.text) {
            ui.drawText(s, at: Vec2(origin.x + x, origin.y + y), size: size, color: color)
        }
        func section(_ rect: UIRect, _ title: String) {
            ui.fillRect(rect, color: Self.panel, radii: UICornerRadii(10))
            ui.strokeRect(rect, color: Self.border, width: 1, radii: UICornerRadii(10))
            ui.drawText(title, at: Vec2(rect.x + 16, rect.y + 12), size: 15, color: Self.dim)
        }

        text("Audio", 24, 18, size: 30)
        text(deviceName.isEmpty ? "" : "Device: \(deviceName)", 24, 58, size: 13, color: Self.dim)

        // Bus meters.
        section(at(20, 86, 600, 300), "Buses (peak level · volume)")
        for (i, meter) in meters.enumerated() {
            let y: Float = 124 + Float(i) * 42
            text(meter.name, 36, y, size: 15)
            let bar = at(140, y + 2, 300, 16)
            ui.fillRect(bar, color: UIColor(hex: 0x10141d), radii: UICornerRadii(4))
            let level = min(meter.level, 1)
            if level > 0 {
                let color = level > 0.9 ? Self.red : level > 0.6 ? Self.warm : Self.green
                ui.fillRect(UIRect(x: bar.x, y: bar.y, width: bar.width * level, height: bar.height), color: color,
                            radii: UICornerRadii(4))
            }
            // Volume marker.
            let marker = bar.x + bar.width * min(meter.volume, 1)
            ui.drawLine(from: Vec2(marker, bar.y - 3), to: Vec2(marker, bar.maxY + 3), width: 2, color: Self.accent)
            text(String(format: "%.2f · %.2f", meter.level, meter.volume), 452, y, size: 13, color: Self.dim)
            if !meter.flags.isEmpty { text(meter.flags, 140, y + 21, size: 11, color: Self.warm) }
        }

        // Level history.
        section(at(640, 86, 620, 300), "Level history (last \(Self.historyLength) frames)")
        let graph = at(660, 124, 580, 240)
        ui.fillRect(graph, color: UIColor(hex: 0x10141d), radii: UICornerRadii(6))
        let colors = [Self.text, Self.accent, Self.green, Self.warm, UIColor(hex: 0xbf7cff), Self.red]
        for (i, levels) in history.enumerated() {
            let color = colors[i % colors.count]
            var previous: Vec2?
            for (k, level) in levels.enumerated() {
                let p = Vec2(graph.x + Float(k) / Float(Self.historyLength - 1) * graph.width,
                             graph.maxY - min(level, 1) * (graph.height - 8) - 4)
                if let previous { ui.drawLine(from: previous, to: p, width: 1.5, color: color) }
                previous = p
            }
            if i < meters.count {
                ui.drawText(meters[i].name, at: Vec2(graph.x + 10 + Float(i) * 90, graph.y + 8), size: 12, color: color)
            }
        }

        // Voices.
        section(at(20, 402, 1240, 210), "Voices (\(voiceRows.count))")
        for (i, row) in voiceRows.prefix(8).enumerated() {
            text(row, 36, 438 + Float(i) * 21, size: 13)
        }
        if voiceRows.isEmpty { text("No voices playing", 36, 438, size: 13, color: Self.dim) }

        let help = "B blip · K kick · H hi-hat · T dialogue (ducks music) · M music · L ambience · X mute music · "
            + "P pause sfx · G ducking \(ducking ? "on" : "off")"
        text(help, 24, 628, size: 13, color: Self.dim)
        text("Music streams from an in-memory WAV; everything is synthesized at startup.", 24, 650, size: 12,
             color: Self.dim)
    }

    // MARK: - Sounds

    /// A deterministic noise source (no global random state).
    private struct Noise {
        var state: UInt32 = 0x1234_5678
        mutating func next() -> Float {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Float(state >> 8) / Float(1 << 23) - 1
        }
    }

    private static func frequency(midi: Int) -> Float { 440 * powf(2, Float(midi - 69) / 12) }

    /// 8 s, 120 bpm: Am F C G pads, a bass note on every beat, hi-hats on the off-beats.
    /// Returned as a 16-bit stereo WAV so the scene can stream it.
    private static func makeMusic() -> Data {
        let rate = Float(sampleRate)
        let frames = Int(sampleRate * 8)
        let chords: [[Int]] = [[57, 60, 64], [53, 57, 60], [48, 55, 64], [55, 59, 62]]  // Am F C G
        let roots = [45, 41, 36, 43]
        var samples = [Float](repeating: 0, count: frames * 2)
        var noise = Noise()
        var hatLow: Float = 0
        for i in 0..<frames {
            let t = Float(i) / rate
            let chord = Int(t / 2) % 4
            let inChord = t.truncatingRemainder(dividingBy: 2)
            let padEnvelope = min(inChord / 0.3, 1) * min((2 - inChord) / 0.2, 1)
            var left: Float = 0, right: Float = 0
            for note in chords[chord] {
                let f = frequency(midi: note)
                left += sinf(2 * .pi * f * 0.998 * t) + 0.25 * sinf(4 * .pi * f * 0.998 * t)
                right += sinf(2 * .pi * f * 1.002 * t) + 0.25 * sinf(4 * .pi * f * 1.002 * t)
            }
            left *= 0.07 * padEnvelope
            right *= 0.07 * padEnvelope
            let beat = t.truncatingRemainder(dividingBy: 0.5)
            let bass = sinf(2 * .pi * frequency(midi: roots[chord]) * t) * expf(-beat * 6) * 0.3
            let offBeat = (t + 0.25).truncatingRemainder(dividingBy: 0.5)
            let white = noise.next()
            hatLow += (white - hatLow) * 0.3
            let hatSample = (white - hatLow) * expf(-offBeat * 40) * 0.12
            samples[2 * i] = left + bass + hatSample * 0.7
            samples[2 * i + 1] = right + bass + hatSample
        }
        return WAVWriter.encode(samples, channelCount: 2, sampleRate: Int(sampleRate), encoding: .pcm16)
    }

    private static func makeBlip() -> SoundBuffer {
        var phase: Float = 0
        return SoundBuffer(frameCount: Int(sampleRate * 0.18), sampleRate: sampleRate, name: "blip") { i, _ in
            let t = Float(i) / Float(sampleRate)
            phase += 2 * .pi * (880 + 440 * min(t / 0.05, 1)) / Float(sampleRate)
            return sinf(phase) * expf(-t * 18) * min(t / 0.002, 1)
        }
    }

    private static func makeKick() -> SoundBuffer {
        var phase: Float = 0
        return SoundBuffer(frameCount: Int(sampleRate * 0.35), sampleRate: sampleRate, name: "kick") { i, _ in
            let t = Float(i) / Float(sampleRate)
            phase += 2 * .pi * (45 + 90 * expf(-t * 30)) / Float(sampleRate)
            return sinf(phase) * expf(-t * 9) * min(t / 0.001, 1)
        }
    }

    private static func makeHat() -> SoundBuffer {
        var noise = Noise(state: 99)
        var low: Float = 0
        return SoundBuffer(frameCount: Int(sampleRate * 0.09), sampleRate: sampleRate, name: "hi-hat") { i, _ in
            let t = Float(i) / Float(sampleRate)
            let white = noise.next()
            low += (white - low) * 0.25
            return (white - low) * expf(-t * 45)
        }
    }

    /// 1.6 s of "speech": a buzzy glottal tone with vibrato, chopped into syllables and softened.
    private static func makeLine() -> SoundBuffer {
        var phase: Float = 0
        var smooth: Float = 0
        let duration: Float = 1.6
        return SoundBuffer(frameCount: Int(sampleRate * Double(duration)), sampleRate: sampleRate, name: "dialogue") { i, _ in
            let t = Float(i) / Float(sampleRate)
            let pitch = 150 + 25 * sinf(2 * .pi * 0.7 * t) + 4 * sinf(2 * .pi * 5.5 * t)
            phase += pitch / Float(sampleRate)
            phase -= floorf(phase)
            let saw = 2 * phase - 1
            smooth += (saw - smooth) * 0.12  // a soft low-pass
            let syllables = max(sinf(2 * .pi * 3.3 * t), 0)
            let envelope = min(t / 0.05, 1) * min((duration - t) / 0.1, 1)
            return smooth * syllables * envelope * 0.9
        }
    }

    /// A 4 s seamless loop: a fifth on A with slow beating, stereo.
    private static func makeDrone() -> SoundBuffer {
        let seconds = 4.0
        return SoundBuffer(frameCount: Int(sampleRate * seconds), channelCount: 2, sampleRate: sampleRate, name: "ambience") { i, c in
            let t = Float(i) / Float(sampleRate)
            // Whole numbers of cycles in 4 s, so the loop point is seamless.
            let a: Float = 110, e: Float = 165, beat: Float = c == 0 ? 110.25 : 109.75
            let swell = 0.6 + 0.4 * sinf(2 * .pi * 0.25 * t)
            return (sinf(2 * .pi * a * t) + 0.6 * sinf(2 * .pi * e * t) + 0.5 * sinf(2 * .pi * beat * t)) * 0.3 * swell
        }
    }
}
