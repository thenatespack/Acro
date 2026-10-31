import Foundation

// Effects for voices and buses: biquad filters (RBJ cookbook) with a smoothed cutoff, and a
// Freeverb reverb. The public types describe an effect; the game thread turns them into plain
// commands and the audio thread runs the DSP below. Nothing here allocates on the audio
// thread: reverb delay lines are allocated by the game thread (`ReverbMemory`), which keeps
// them alive until the device has stopped, and the mixer only holds raw pointers into them.

/// A filter's response.
public enum AudioFilterType: String, Codable, Sendable, CaseIterable {
    case lowPass, highPass, bandPass
}

/// A second-order filter: on a voice (`Voice.filter`) or in a bus's effect chain. Changes to
/// the cutoff glide over about 20 ms, so sweeping it doesn't zipper.
public struct AudioFilter: Codable, Equatable, Sendable {
    public var type: AudioFilterType
    /// Corner or center frequency in Hz (clamped to 10 Hz ... just under Nyquist).
    public var cutoff: Float
    /// Resonance: 0.7071 is a flat Butterworth response; higher peaks at the cutoff. For
    /// `bandPass` it sets the bandwidth (center / bandwidth), with 0 dB gain at the center.
    public var q: Float

    public init(_ type: AudioFilterType, cutoff: Float, q: Float = 0.7071) {
        self.type = type
        self.cutoff = cutoff
        self.q = q
    }
}

/// A Freeverb reverb. As a send bus's effect keep `dry` at 0 and `wet` at 1 and feed it with
/// voice or bus sends; as an insert effect mix with `dry` and `wet`.
public struct AudioReverb: Codable, Equatable, Sendable {
    /// 0 ... 1: longer tail as it grows (about 0.2 s ... 3 s).
    public var roomSize: Float
    /// 0 ... 1: how quickly the tail loses high frequencies.
    public var damping: Float
    /// 0 ... 1: 0 is mono, 1 is full stereo.
    public var width: Float
    /// Linear gain of the reverberated signal.
    public var wet: Float
    /// Linear gain of the unprocessed input.
    public var dry: Float

    public init(roomSize: Float = 0.7, damping: Float = 0.5, width: Float = 1, wet: Float = 1, dry: Float = 0) {
        self.roomSize = roomSize
        self.damping = damping
        self.width = width
        self.wet = wet
        self.dry = dry
    }
}

/// One slot of a bus's effect chain. Effects run in order, before the bus's volume.
public enum AudioEffect: Codable, Equatable, Sendable {
    case filter(AudioFilter)
    case reverb(AudioReverb)
}

// MARK: - Biquad

/// Normalized biquad coefficients (a0 = 1), from Robert Bristow-Johnson's Audio EQ Cookbook.
struct BiquadCoefficients: Equatable {
    var b0: Float = 1, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0

    static func make(_ type: AudioFilterType, cutoff: Float, q: Float, sampleRate: Double) -> BiquadCoefficients {
        let f = min(max(Double(cutoff), 10), sampleRate * 0.49)
        let w0 = 2 * Double.pi * f / sampleRate
        let cosW = cos(w0), sinW = sin(w0)
        let alpha = sinW / (2 * Double(max(q, 0.05)))
        let b0: Double, b1: Double, b2: Double
        switch type {
        case .lowPass: (b0, b1, b2) = ((1 - cosW) / 2, 1 - cosW, (1 - cosW) / 2)
        case .highPass: (b0, b1, b2) = ((1 + cosW) / 2, -(1 + cosW), (1 + cosW) / 2)
        case .bandPass: (b0, b1, b2) = (alpha, 0, -alpha)  // constant 0 dB peak gain
        }
        let a0 = 1 + alpha
        return BiquadCoefficients(b0: Float(b0 / a0), b1: Float(b1 / a0), b2: Float(b2 / a0),
                                  a1: Float(-2 * cosW / a0), a2: Float((1 - alpha) / a0))
    }
}

/// Flushes values too small to matter to zero, so feedback paths never go denormal.
@inline(__always) func flushDenormal(_ x: Float) -> Float { abs(x) < 1e-18 ? 0 : x }

/// A stereo biquad (transposed direct form II) whose cutoff can differ per channel (head
/// shadow) and glides toward its target once per block.
struct StereoFilter {
    /// Cutoffs at or above this frequency count as open: a low-pass there is bypassed.
    static let openCutoff: Float = 24000
    /// Time constant of the cutoff glide.
    static let glideSeconds = 0.02

    var active = false
    var type = AudioFilterType.lowPass
    var q: Float = 0.7071
    var cutoffL: Float = openCutoff, cutoffR: Float = openCutoff
    var targetL: Float = openCutoff, targetR: Float = openCutoff
    private var coefL = BiquadCoefficients(), coefR = BiquadCoefficients()
    private var builtL: Float = 0, builtR: Float = 0
    private var z1L: Float = 0, z2L: Float = 0, z1R: Float = 0, z2R: Float = 0

    /// Sets the response and the cutoffs to glide to (`immediate` jumps, for a filter that was off).
    mutating func set(type: AudioFilterType, cutoffL: Float, cutoffR: Float, q: Float, immediate: Bool) {
        if self.type != type || self.q != q { builtL = 0; builtR = 0 }
        self.type = type
        self.q = q
        targetL = cutoffL
        targetR = cutoffR
        if immediate || !active {
            self.cutoffL = cutoffL
            self.cutoffR = cutoffR
            z1L = 0; z2L = 0; z1R = 0; z2R = 0
        }
        active = true
    }

    mutating func reset() {
        self = StereoFilter()
    }

    /// True when it would pass the signal through unchanged.
    var isBypassed: Bool {
        guard active else { return true }
        return type == .lowPass && min(min(cutoffL, cutoffR), min(targetL, targetR)) >= StereoFilter.openCutoff * 0.9
    }

    /// Moves the cutoffs toward their targets for a block of `frames` and rebuilds the coefficients.
    mutating func prepare(frames: Int, sampleRate: Double) {
        guard active else { return }
        let k = Float(1 - exp(-Double(frames) / (sampleRate * Self.glideSeconds)))
        cutoffL = Self.glide(cutoffL, to: targetL, k)
        cutoffR = Self.glide(cutoffR, to: targetR, k)
        if cutoffL != builtL {
            coefL = .make(type, cutoff: cutoffL, q: q, sampleRate: sampleRate)
            builtL = cutoffL
        }
        if cutoffR != builtR {
            coefR = cutoffR == cutoffL ? coefL : .make(type, cutoff: cutoffR, q: q, sampleRate: sampleRate)
            builtR = cutoffR
        }
    }

    /// Geometric glide (equal steps in octaves), snapping when close.
    private static func glide(_ current: Float, to target: Float, _ k: Float) -> Float {
        if current == target { return current }
        let ratio = target / current
        if abs(ratio - 1) < 1e-3 { return target }
        return current * powf(ratio, k)
    }

    /// Frames between coefficient updates while the cutoff glides (small steps avoid clicks).
    static let glideChunk = 32

    /// `prepare` and `process` for one block, updating the coefficients every `glideChunk`
    /// frames while the cutoff is still moving.
    mutating func run(_ buffer: UnsafeMutablePointer<Float>, frames: Int, sampleRate: Double) {
        guard active else { return }
        var done = 0
        while done < frames {
            let n = min(Self.glideChunk, frames - done)
            prepare(frames: n, sampleRate: sampleRate)
            process(buffer + done * 2, frames: n)
            done += n
        }
    }

    /// Filters interleaved stereo in place. Call `prepare` first.
    mutating func process(_ buffer: UnsafeMutablePointer<Float>, frames: Int) {
        if isBypassed {
            z1L = 0; z2L = 0; z1R = 0; z2R = 0
            return
        }
        let l = coefL, r = coefR
        for k in 0..<frames {
            let xl = buffer[2 * k]
            let yl = l.b0 * xl + z1L
            z1L = flushDenormal(l.b1 * xl - l.a1 * yl + z2L)
            z2L = flushDenormal(l.b2 * xl - l.a2 * yl)
            buffer[2 * k] = yl
            let xr = buffer[2 * k + 1]
            let yr = r.b0 * xr + z1R
            z1R = flushDenormal(r.b1 * xr - r.a1 * yr + z2R)
            z2R = flushDenormal(r.b2 * xr - r.a2 * yr)
            buffer[2 * k + 1] = yr
        }
    }
}

// MARK: - Reverb

/// The delay lines of one reverb, allocated by the game thread. The audio thread works through
/// `ref` (raw pointers), so the owner must outlive the device.
final class ReverbMemory {
    /// Freeverb's tunings at 44.1 kHz (comb delays; the right channel adds `spread`), and the all-pass delays.
    static let combTunings = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    static let allpassTunings = [556, 441, 341, 225]
    static let spread = 23
    static let lines = 24  // 8 combs + 4 all-passes, per channel

    let ref: ReverbRef
    private let totalFrames: Int

    init(sampleRate: Double) {
        let scale = sampleRate / 44100
        func scaled(_ n: Int) -> Int { max(Int((Double(n) * scale).rounded()), 1) }
        var lengths: [Int] = []
        for channel in 0..<2 { for t in Self.combTunings { lengths.append(scaled(t + channel * Self.spread)) } }
        for channel in 0..<2 { for t in Self.allpassTunings { lengths.append(scaled(t + channel * Self.spread)) } }
        var offsets: [Int] = []
        var total = 0
        for n in lengths { offsets.append(total); total += n }
        totalFrames = total
        let lengthPointer = UnsafeMutablePointer<Int>.allocate(capacity: Self.lines)
        let offsetPointer = UnsafeMutablePointer<Int>.allocate(capacity: Self.lines)
        lengthPointer.initialize(from: lengths, count: Self.lines)
        offsetPointer.initialize(from: offsets, count: Self.lines)
        let positions = UnsafeMutablePointer<Int>.allocate(capacity: Self.lines)
        positions.initialize(repeating: 0, count: Self.lines)
        let stores = UnsafeMutablePointer<Float>.allocate(capacity: 16)
        stores.initialize(repeating: 0, count: 16)
        let delay = UnsafeMutablePointer<Float>.allocate(capacity: total)
        delay.initialize(repeating: 0, count: total)
        ref = ReverbRef(delay: delay, totalFrames: total, offsets: offsetPointer, lengths: lengthPointer,
                        positions: positions, stores: stores)
    }

    deinit {
        ref.delay.deallocate()
        ref.offsets.deallocate()
        ref.lengths.deallocate()
        ref.positions.deallocate()
        ref.stores.deallocate()
    }
}

/// Raw pointers into a `ReverbMemory`, the audio thread's view of one reverb. Lines 0-7 are the
/// left combs, 8-15 the right combs, 16-19 the left all-passes, 20-23 the right ones.
struct ReverbRef: @unchecked Sendable {
    let delay: UnsafeMutablePointer<Float>
    let totalFrames: Int
    let offsets: UnsafeMutablePointer<Int>
    let lengths: UnsafeMutablePointer<Int>
    let positions: UnsafeMutablePointer<Int>
    let stores: UnsafeMutablePointer<Float>

    func clear() {
        delay.update(repeating: 0, count: totalFrames)
        positions.update(repeating: 0, count: ReverbMemory.lines)
        stores.update(repeating: 0, count: 16)
    }

    @inline(__always) private func allpass(_ index: Int, _ x: Float, _ feedback: Float) -> Float {
        let line = delay + offsets[index]
        let p = positions[index]
        let bufferOut = line[p]
        line[p] = flushDenormal(x + bufferOut * feedback)
        positions[index] = p + 1 == lengths[index] ? 0 : p + 1
        return bufferOut - x
    }

    /// Reverberates interleaved stereo in place: `out = dry * in + wet * reverb(in)`.
    func process(_ buffer: UnsafeMutablePointer<Float>, frames: Int, feedback: Float, damping: Float, width: Float,
                 wet: inout Ramp, dry: inout Ramp) {
        let damp1 = damping, damp2 = 1 - damping
        let allpassFeedback: Float = 0.5
        for k in 0..<frames {
            let inL = buffer[2 * k], inR = buffer[2 * k + 1]
            let input = (inL + inR) * 0.015
            var outL: Float = 0, outR: Float = 0
            for c in 0..<8 {
                // Left comb c.
                var line = delay + offsets[c]
                var p = positions[c]
                var out = line[p]
                var store = flushDenormal(out * damp2 + stores[c] * damp1)
                stores[c] = store
                line[p] = input + store * feedback
                p += 1
                positions[c] = p == lengths[c] ? 0 : p
                outL += out
                // Right comb c.
                let r = 8 + c
                line = delay + offsets[r]
                p = positions[r]
                out = line[p]
                store = flushDenormal(out * damp2 + stores[r] * damp1)
                stores[r] = store
                line[p] = input + store * feedback
                p += 1
                positions[r] = p == lengths[r] ? 0 : p
                outR += out
            }
            for a in 0..<4 {
                outL = allpass(16 + a, outL, allpassFeedback)
                outR = allpass(20 + a, outR, allpassFeedback)
            }
            let w = wet.next() * 3, d = dry.next()
            let wet1 = w * (width / 2 + 0.5), wet2 = w * ((1 - width) / 2)
            buffer[2 * k] = inL * d + outL * wet1 + outR * wet2
            buffer[2 * k + 1] = inR * d + outR * wet1 + outL * wet2
        }
    }

    /// Comb feedback gain for a room size.
    static func feedback(roomSize: Float) -> Float { min(max(roomSize, 0), 1) * 0.28 + 0.7 }
}
