import Foundation

// A synthesized sound effect: the contents of a `.sfx` file (JSON, every key optional), the
// audio analogue of `.proctex`. The synth DSP below is pure Swift (no platform audio), so the
// same file renders to identical samples everywhere: `render()` is a pure function of the
// parameters, with `seed` driving the noise oscillator. `SoundBuildImporter` registers the file
// and `AudioFile.decoder` renders it on load, so an `.sfx` plays anywhere an audio file does
// (`AudioEmitter.clip`, `AssetDatabase.loadSound`, `AssetDatabase.play`).
//
// ```json
// {"waveform": "square", "frequency": 880, "arpeggio": 12, "arpeggioTime": 0.07,
//  "sustain": 0.05, "decay": 0.25, "seed": 7}
// ```

/// The oscillator shape of a `SoundBuild`.
public enum SFXWaveform: String, Codable, CaseIterable, Sendable {
    case square, saw, sine, noise
}

/// Ready-made starting points for a `SoundBuild`.
public enum SFXPreset: String, Codable, CaseIterable, Sendable {
    case jump, coin, laser, explosion, hit, powerUp, blip
}

public struct SoundBuild: Codable, Equatable, Sendable {
    public var waveform: SFXWaveform
    /// Starting pitch, Hz.
    public var frequency: Float
    /// Pitch slide, octaves per second (negative falls).
    public var slide: Float
    /// How the slide itself changes, octaves per second per second.
    public var slideAcceleration: Float
    /// The sound ends when the pitch falls below this, Hz (0: never).
    public var minFrequency: Float
    /// Vibrato size in semitones (0: none) and speed in Hz.
    public var vibratoDepth: Float
    public var vibratoRate: Float
    /// Arpeggio: the pitch jumps by this many semitones after `arpeggioTime` seconds (0: none).
    public var arpeggio: Float
    public var arpeggioTime: Float
    /// Square pulse width 0...1 (0.5 is a plain square) and how fast it sweeps, per second.
    public var duty: Float
    public var dutySweep: Float
    /// Volume envelope, seconds: fade in, hold, fade out.
    public var attack: Float
    public var sustain: Float
    public var decay: Float
    /// Extra loudness at the start of the sustain, fading out over it (0...1).
    public var punch: Float
    /// Low-pass and high-pass filter cutoffs, Hz (0: off).
    public var lowPass: Float
    public var highPass: Float
    /// Bit crush: quantize to this many bits (1...15; 0: off).
    public var bitCrush: Int
    /// Overall volume 0...1.
    public var volume: Float
    public var sampleRate: Int
    /// Drives the noise oscillator (and `randomized` / `mutated`): same parameters and seed give identical samples.
    public var seed: Int

    public init(waveform: SFXWaveform = .square, frequency: Float = 440, slide: Float = 0, slideAcceleration: Float = 0,
                minFrequency: Float = 0, vibratoDepth: Float = 0, vibratoRate: Float = 8, arpeggio: Float = 0,
                arpeggioTime: Float = 0.1, duty: Float = 0.5, dutySweep: Float = 0, attack: Float = 0.005,
                sustain: Float = 0.15, decay: Float = 0.2, punch: Float = 0, lowPass: Float = 0, highPass: Float = 0,
                bitCrush: Int = 0, volume: Float = 0.5, sampleRate: Int = 44100, seed: Int = 1) {
        self.waveform = waveform
        self.frequency = frequency
        self.slide = slide
        self.slideAcceleration = slideAcceleration
        self.minFrequency = minFrequency
        self.vibratoDepth = vibratoDepth
        self.vibratoRate = vibratoRate
        self.arpeggio = arpeggio
        self.arpeggioTime = arpeggioTime
        self.duty = duty
        self.dutySweep = dutySweep
        self.attack = attack
        self.sustain = sustain
        self.decay = decay
        self.punch = punch
        self.lowPass = lowPass
        self.highPass = highPass
        self.bitCrush = bitCrush
        self.volume = volume
        self.sampleRate = sampleRate
        self.seed = seed
    }

    private enum CodingKeys: String, CodingKey {
        case waveform, frequency, slide, slideAcceleration, minFrequency, vibratoDepth, vibratoRate, arpeggio, arpeggioTime,
             duty, dutySweep, attack, sustain, decay, punch, lowPass, highPass, bitCrush, volume, sampleRate, seed
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SoundBuild()
        func f(_ key: CodingKeys, _ fallback: Float) throws -> Float { try c.decodeIfPresent(Float.self, forKey: key) ?? fallback }
        func i(_ key: CodingKeys, _ fallback: Int) throws -> Int { try c.decodeIfPresent(Int.self, forKey: key) ?? fallback }
        self.init(waveform: try c.decodeIfPresent(SFXWaveform.self, forKey: .waveform) ?? d.waveform,
                  frequency: try f(.frequency, d.frequency), slide: try f(.slide, d.slide),
                  slideAcceleration: try f(.slideAcceleration, d.slideAcceleration),
                  minFrequency: try f(.minFrequency, d.minFrequency), vibratoDepth: try f(.vibratoDepth, d.vibratoDepth),
                  vibratoRate: try f(.vibratoRate, d.vibratoRate), arpeggio: try f(.arpeggio, d.arpeggio),
                  arpeggioTime: try f(.arpeggioTime, d.arpeggioTime), duty: try f(.duty, d.duty),
                  dutySweep: try f(.dutySweep, d.dutySweep), attack: try f(.attack, d.attack),
                  sustain: try f(.sustain, d.sustain), decay: try f(.decay, d.decay), punch: try f(.punch, d.punch),
                  lowPass: try f(.lowPass, d.lowPass), highPass: try f(.highPass, d.highPass),
                  bitCrush: try i(.bitCrush, d.bitCrush), volume: try f(.volume, d.volume),
                  sampleRate: try i(.sampleRate, d.sampleRate), seed: try i(.seed, d.seed))
    }

    public static var fieldHints: [String: FieldHints] {
        ["frequency": FieldHints(range: 20...8000, step: 1, tooltip: "Starting pitch in Hz"),
         "slide": FieldHints(range: -8...8, step: 0.05, tooltip: "Pitch slide in octaves per second (negative falls)"),
         "slideAcceleration": FieldHints(range: -20...20, step: 0.05, tooltip: "How the slide changes, octaves per second squared"),
         "minFrequency": FieldHints(range: 0...8000, step: 1, tooltip: "The sound ends when the pitch falls below this (0: never)"),
         "vibratoDepth": FieldHints(range: 0...24, step: 0.05, tooltip: "Vibrato size in semitones"),
         "vibratoRate": FieldHints(range: 0...60, step: 0.1, tooltip: "Vibrato speed in Hz"),
         "arpeggio": FieldHints(range: -36...36, step: 1, tooltip: "Semitones the pitch jumps by after the arpeggio time (0: none)"),
         "arpeggioTime": FieldHints(range: 0.005...2, step: 0.005, tooltip: "Seconds before the pitch jumps"),
         "duty": FieldHints(range: 0.02...0.98, step: 0.01, tooltip: "Square pulse width"),
         "dutySweep": FieldHints(range: -2...2, step: 0.01, tooltip: "Pulse width change per second"),
         "attack": FieldHints(range: 0...2, step: 0.005, tooltip: "Fade-in seconds"),
         "sustain": FieldHints(range: 0...4, step: 0.005, tooltip: "Hold seconds"),
         "decay": FieldHints(range: 0...4, step: 0.005, tooltip: "Fade-out seconds"),
         "punch": FieldHints(range: 0...1, step: 0.01, tooltip: "Extra loudness at the start of the hold"),
         "lowPass": FieldHints(range: 0...20000, step: 10, tooltip: "Low-pass cutoff in Hz (0: off)"),
         "highPass": FieldHints(range: 0...20000, step: 10, tooltip: "High-pass cutoff in Hz (0: off)"),
         "bitCrush": FieldHints(range: 0...15, step: 1, tooltip: "Quantize to this many bits (0: off)"),
         "volume": FieldHints(range: 0...1, step: 0.01),
         "sampleRate": FieldHints(range: 8000...48000, step: 1000),
         "seed": FieldHints(step: 1, tooltip: "Drives the noise; the same seed gives the same sound")]
    }

    /// The file's text.
    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    // MARK: Rendering

    /// Longest sound rendered, seconds.
    public static let maxDuration: Float = 8

    /// Length in seconds (envelope total, at most `maxDuration`).
    public var duration: Float {
        min(max(max(attack, 0) + max(sustain, 0) + max(decay, 0), 0.01), Self.maxDuration)
    }

    /// Mono samples in -1...1. A pure function of the parameters: identical every time.
    public func render() -> [Float] {
        let sr = Float(min(max(sampleRate, 8000), 192_000))
        let count = max(Int(duration * sr), 1)
        let attack = max(self.attack, 0), sustain = max(self.sustain, 0), decay = max(self.decay, 0)
        var rng = SFXRandom(seed: UInt64(bitPattern: Int64(seed)))
        var held = rng.float(in: -1...1)
        var phase: Float = 0
        var lp1: Float = 0, lp2: Float = 0, hp: Float = 0
        func coefficient(_ hz: Float) -> Float { 1 - exp(-2 * Float.pi * min(max(hz, 1), sr * 0.45) / sr) }
        let lpA = lowPass > 0 ? coefficient(lowPass) : 1
        let hpA = highPass > 0 ? coefficient(highPass) : 0
        let levels: Float = bitCrush > 0 ? Float(1 << (min(bitCrush, 15) - 1)) : 0
        var out = [Float](repeating: 0, count: count)
        for n in 0..<count {
            let t = Float(n) / sr
            // Pitch: slide (and its acceleration), then arpeggio jump and vibrato on top.
            let octaves = slide * t + 0.5 * slideAcceleration * t * t
            var base = frequency * exp2(min(max(octaves, -20), 20))
            if minFrequency > 0 && base < minFrequency { break }
            if arpeggio != 0 && t >= arpeggioTime { base *= exp2(arpeggio / 12) }
            let vibrato = vibratoDepth != 0 ? exp2(vibratoDepth / 12 * sin(2 * Float.pi * vibratoRate * t)) : 1
            let hz = min(max(base * vibrato, 10), sr * 0.45)
            phase += hz / sr
            var wrapped = false
            if phase >= 1 { phase -= phase.rounded(.down); wrapped = true }
            var x: Float
            switch waveform {
            case .square:
                let width = min(max(duty + dutySweep * t, 0.02), 0.98)
                x = phase < width ? 1 : -1
            case .saw: x = 2 * phase - 1
            case .sine: x = sin(2 * Float.pi * phase)
            case .noise:
                if wrapped { held = rng.float(in: -1...1) }
                x = held
            }
            // Filters: two cascaded one-pole low-passes (12 dB/octave), one-pole high-pass.
            if lowPass > 0 {
                lp1 += lpA * (x - lp1)
                lp2 += lpA * (lp1 - lp2)
                x = lp2
            }
            if highPass > 0 {
                hp += hpA * (x - hp)
                x -= hp
            }
            if levels > 0 { x = (x * levels).rounded() / levels }
            // Envelope.
            var env: Float
            if t < attack {
                env = t / attack
            } else if t < attack + sustain {
                env = 1 + (1 - (t - attack) / max(sustain, 1e-6)) * 2 * min(max(punch, 0), 1)
            } else if decay > 0 {
                let r = max(1 - (t - attack - sustain) / decay, 0)
                env = r * r
            } else {
                env = 0
            }
            out[n] = min(max(x * env * min(max(volume, 0), 1), -1), 1)
        }
        return out
    }

    /// The rendered sound as a mono `SoundBuffer`.
    public func soundBuffer(name: String = "") -> SoundBuffer {
        SoundBuffer(samples: render(), channelCount: 1, sampleRate: Double(min(max(sampleRate, 8000), 192_000)), name: name)
    }

    /// `count` peak magnitudes (0...1) across the sound, for drawing its waveform.
    public func peaks(count: Int, of samples: [Float]? = nil) -> [Float] {
        let samples = samples ?? render()
        guard count > 0, !samples.isEmpty else { return [] }
        return (0..<count).map { i in
            let lo = min(i * samples.count / count, samples.count - 1)
            let hi = min(max((i + 1) * samples.count / count, lo + 1), samples.count)
            return samples[lo..<hi].reduce(0) { max($0, abs($1)) }
        }
    }

    /// Values outside the usable range, as warnings (rendering clamps them).
    public func problems() -> [String] {
        var problems: [String] = []
        if frequency < 20 || frequency > 8000 { problems.append("frequency \(frequency) Hz is outside 20...8000") }
        if attack + sustain + decay > Self.maxDuration { problems.append("the sound is longer than \(Int(Self.maxDuration)) s and is cut off") }
        if attack + sustain + decay <= 0 { problems.append("attack, sustain and decay are all 0: the sound is 0.01 s of silence") }
        if volume <= 0 { problems.append("volume is 0: the sound is silent") }
        if bitCrush < 0 || bitCrush > 15 { problems.append("bitCrush \(bitCrush) is outside 0...15") }
        if lowPass > 0 && highPass > 0 && lowPass < highPass { problems.append("lowPass is below highPass: almost nothing passes") }
        if sampleRate < 8000 || sampleRate > 192_000 { problems.append("sampleRate \(sampleRate) is outside 8000...192000") }
        return problems
    }

    // MARK: Presets, randomize, mutate

    /// The preset with typical values, or (with `seed`) a random variation of it: the same
    /// preset and seed always give the same sound. The result's `seed` is the one used.
    public static func preset(_ preset: SFXPreset, seed: Int? = nil) -> SoundBuild {
        var gen = SFXGenerator(seed: seed)
        var b = SoundBuild()
        b.seed = seed ?? 1
        switch preset {
        case .jump:
            b.waveform = .square
            b.frequency = gen.value(260, 380)
            b.slide = gen.value(1.0, 2.0)
            b.duty = gen.value(0.3, 0.5)
            b.sustain = gen.value(0.05, 0.12)
            b.decay = gen.value(0.12, 0.2)
            b.highPass = 90
        case .coin:
            b.waveform = .square
            b.frequency = gen.value(900, 1300)
            b.arpeggio = gen.pick([5, 7, 12])
            b.arpeggioTime = gen.value(0.05, 0.09)
            b.duty = gen.value(0.4, 0.5)
            b.sustain = gen.value(0.05, 0.1)
            b.decay = gen.value(0.15, 0.3)
        case .laser:
            b.waveform = gen.pick([.saw, .square])
            b.frequency = gen.value(900, 1700)
            b.slide = gen.value(-4, -2)
            b.dutySweep = gen.value(-0.8, 0)
            b.duty = gen.value(0.3, 0.5)
            b.minFrequency = 120
            b.sustain = gen.value(0.08, 0.2)
            b.decay = gen.value(0.08, 0.18)
            b.highPass = 150
        case .explosion:
            b.waveform = .noise
            b.frequency = gen.value(60, 160)
            b.slide = gen.value(-1, -0.2)
            b.vibratoDepth = gen.value(0, 2)
            b.vibratoRate = gen.value(8, 20)
            b.punch = gen.value(0.5, 0.9)
            b.sustain = gen.value(0.1, 0.35)
            b.decay = gen.value(0.45, 0.9)
            b.lowPass = gen.value(1200, 3500)
            b.volume = 0.7
        case .hit:
            b.waveform = gen.pick([.noise, .square])
            b.frequency = gen.value(150, 320)
            b.slide = gen.value(-5, -2)
            b.punch = gen.value(0.4, 0.8)
            b.sustain = gen.value(0.01, 0.04)
            b.decay = gen.value(0.07, 0.14)
            b.lowPass = gen.value(3000, 7000)
        case .powerUp:
            b.waveform = gen.pick([.square, .saw])
            b.frequency = gen.value(220, 380)
            b.slide = gen.value(1, 2.5)
            b.vibratoDepth = gen.value(0.2, 1)
            b.vibratoRate = gen.value(20, 40)
            b.duty = gen.value(0.3, 0.5)
            b.sustain = gen.value(0.2, 0.4)
            b.decay = gen.value(0.2, 0.3)
        case .blip:
            b.waveform = gen.pick([.square, .sine])
            b.frequency = gen.value(500, 1200)
            b.duty = gen.value(0.3, 0.5)
            b.sustain = gen.value(0.03, 0.07)
            b.decay = gen.value(0.03, 0.08)
        }
        return b
    }

    /// A random sound of the same character as `preset` (shorthand for `preset(_:seed:)`).
    public static func randomized(_ preset: SFXPreset, seed: Int) -> SoundBuild { Self.preset(preset, seed: seed) }

    /// A variation of this sound: every continuous parameter moves by up to `amount` (0...1,
    /// default 0.2) of its size, deterministically per `seed`. The result's `seed` is the one used.
    public func mutated(amount: Float = 0.2, seed: Int) -> SoundBuild {
        var rng = SFXRandom(seed: UInt64(bitPattern: Int64(seed)) &+ 0x9E37)
        let a = min(max(amount, 0), 1)
        func jitter(_ v: Float, floor: Float) -> Float { v + rng.float(in: -1...1) * a * max(abs(v), floor) }
        var b = self
        b.frequency = max(jitter(frequency, floor: 50), 20)
        b.slide = jitter(slide, floor: 0.3)
        b.slideAcceleration = jitter(slideAcceleration, floor: 0)
        if vibratoDepth > 0 {
            b.vibratoDepth = max(jitter(vibratoDepth, floor: 0.2), 0)
            b.vibratoRate = max(jitter(vibratoRate, floor: 2), 0.1)
        }
        if arpeggio != 0 {
            b.arpeggio = jitter(arpeggio, floor: 2).rounded()
            b.arpeggioTime = max(jitter(arpeggioTime, floor: 0.02), 0.005)
        }
        b.duty = min(max(jitter(duty, floor: 0.1), 0.02), 0.98)
        b.dutySweep = jitter(dutySweep, floor: 0)
        b.attack = max(jitter(attack, floor: 0.005), 0)
        b.sustain = max(jitter(sustain, floor: 0.02), 0)
        b.decay = max(jitter(decay, floor: 0.02), 0)
        b.punch = min(max(jitter(punch, floor: 0.1), 0), 1)
        if lowPass > 0 { b.lowPass = max(jitter(lowPass, floor: 200), 50) }
        if highPass > 0 { b.highPass = max(jitter(highPass, floor: 50), 20) }
        b.seed = seed
        return b
    }
}

/// A small deterministic generator (SplitMix64), so sounds don't depend on the platform's RNG.
struct SFXRandom {
    var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform in `range`.
    mutating func float(in range: ClosedRange<Float>) -> Float {
        let unit = Float(next() >> 40) / Float(1 << 24)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}

/// Picks preset values: the middle of each range without a seed, random with one.
private struct SFXGenerator {
    var rng: SFXRandom?

    init(seed: Int?) { rng = seed.map { SFXRandom(seed: UInt64(bitPattern: Int64($0))) } }

    mutating func value(_ lo: Float, _ hi: Float) -> Float {
        guard rng != nil else { return (lo + hi) / 2 }
        return rng!.float(in: lo...hi)
    }

    mutating func pick<T>(_ options: [T]) -> T {
        guard rng != nil else { return options[0] }
        return options[Int(rng!.next() % UInt64(options.count))]
    }
}

/// Plays a `SoundBuild`'s rendered samples as an `AudioDecoder`, so `.sfx` files load like any sound file.
final class SFXDecoder: AudioDecoder {
    let channelCount = 1
    let sampleRate: Double
    var frameCount: Int? { samples.count }
    private let samples: [Float]
    private var position = 0

    init(build: SoundBuild) {
        samples = build.render()
        sampleRate = Double(min(max(build.sampleRate, 8000), 192_000))
    }

    convenience init(data: Data) throws {
        let build: SoundBuild
        do { build = try AssetJSON.decoder().decode(SoundBuild.self, from: data) } catch {
            throw AudioError("Not a sound build (.sfx) file: \(error)")
        }
        self.init(build: build)
    }

    func read(into buffer: UnsafeMutablePointer<Float>, frames: Int) throws -> Int {
        let n = max(min(frames, samples.count - position), 0)
        for i in 0..<n { buffer[i] = samples[position + i] }
        position += n
        return n
    }

    func rewind() throws { position = 0 }
}

/// Imports `.sfx` files: checks that the JSON reads and warns about out-of-range values. Like
/// audio files they produce no sub-assets; the sound is rendered when loaded.
public struct SoundBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "sfx" }
    public var fileExtensions: [String] { ["sfx"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: SoundBuild
        do { build = try AssetJSON.decoder().decode(SoundBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a sound build: \(error)")
        }
        for problem in build.problems() { context.warn(problem) }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `build` to a new `.sfx` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createSoundBuild(_ build: SoundBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.sfx` asset `id` (nil if it isn't one or can't be read).
    public func soundBuild(of id: AssetID) -> SoundBuild? {
        guard record(id)?.importer == SoundBuildImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(SoundBuild.self, from: data)
    }

    /// Overwrites the `.sfx` asset `id` with `build` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writeSoundBuild(_ build: SoundBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
