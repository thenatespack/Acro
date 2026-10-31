import Foundation
import Testing
@testable import Engine

// Filters and reverb on the offline device (and directly on the DSP), so every sample is deterministic.

private let rate = 48000.0

private func makeSystem() throws -> AudioSystem {
    try AudioSystem(device: OfflineAudioDevice(sampleRate: rate), maxVoices: 16)
}

private func sine(_ frequency: Double, seconds: Double = 2, amplitude: Float = 1) -> SoundBuffer {
    SoundBuffer(frameCount: Int(rate * seconds), channelCount: 1, sampleRate: rate) { i, _ in
        amplitude * Float(sin(2 * Double.pi * frequency * Double(i) / rate))
    }
}

private func constant(_ value: Float, seconds: Double = 2) -> SoundBuffer {
    SoundBuffer(frameCount: Int(rate * seconds), channelCount: 1, sampleRate: rate) { _, _ in value }
}

/// A single full-scale frame followed by silence.
private func impulse(seconds: Double = 0.1) -> SoundBuffer {
    SoundBuffer(frameCount: Int(rate * seconds), channelCount: 1, sampleRate: rate) { i, _ in i == 0 ? 1 : 0 }
}

private func rms(_ output: [Float], channel: Int = 0, frames range: Range<Int>) -> Float {
    var sum: Float = 0
    for i in range { sum += output[2 * i + channel] * output[2 * i + channel] }
    return (sum / Float(range.count)).squareRoot()
}

private func energy(_ output: [Float], frames range: Range<Int>) -> Float {
    var sum: Float = 0
    for i in range { sum += output[2 * i] * output[2 * i] + output[2 * i + 1] * output[2 * i + 1] }
    return sum
}

/// Gain of a filter on a sine, measured through the DSP in 256-frame blocks like the mixer does.
private func gain(_ type: AudioFilterType, cutoff: Float, q: Float = 0.7071, at frequency: Double) -> Float {
    var filter = StereoFilter()
    filter.set(type: type, cutoffL: cutoff, cutoffR: cutoff, q: q, immediate: true)
    let frames = 24000
    var buffer = [Float](repeating: 0, count: frames * 2)
    for i in 0..<frames {
        let x = Float(sin(2 * Double.pi * frequency * Double(i) / rate))
        buffer[2 * i] = x
        buffer[2 * i + 1] = x
    }
    buffer.withUnsafeMutableBufferPointer { p in
        var done = 0
        while done < frames {
            let n = min(256, frames - done)
            filter.run(p.baseAddress! + done * 2, frames: n, sampleRate: rate)
            done += n
        }
    }
    return rms(buffer, frames: 12000..<frames) / Float(0.5).squareRoot()
}

@Suite struct AudioEffectsTests {
    // MARK: - Filters

    @Test func lowPassResponse() {
        #expect(abs(gain(.lowPass, cutoff: 1000, at: 100) - 1) < 0.01)
        #expect(abs(gain(.lowPass, cutoff: 1000, at: 1000) - 0.7071) < 0.01)  // -3 dB at the cutoff
        // Two poles: -12 dB per octave, so three octaves up is about -36 dB.
        let high = gain(.lowPass, cutoff: 1000, at: 8000)
        #expect(high < 0.025 && high > 0.008, "\(high)")
    }

    @Test func highPassResponse() {
        #expect(gain(.highPass, cutoff: 1000, at: 125) < 0.025)
        #expect(abs(gain(.highPass, cutoff: 1000, at: 1000) - 0.7071) < 0.01)
        #expect(abs(gain(.highPass, cutoff: 1000, at: 10000) - 1) < 0.02)
    }

    @Test func bandPassResponse() {
        #expect(abs(gain(.bandPass, cutoff: 1000, q: 2, at: 1000) - 1) < 0.01)  // 0 dB at the center
        #expect(gain(.bandPass, cutoff: 1000, q: 2, at: 250) < 0.35)
        #expect(gain(.bandPass, cutoff: 1000, q: 2, at: 4000) < 0.35)
        // A higher Q is narrower.
        #expect(gain(.bandPass, cutoff: 1000, q: 8, at: 1300) < gain(.bandPass, cutoff: 1000, q: 2, at: 1300))
    }

    @Test func resonancePeaksAtTheCutoff() {
        #expect(gain(.lowPass, cutoff: 1000, q: 4, at: 1000) > 3.5)  // about Q
    }

    @Test func cutoffGlidesTowardItsTarget() {
        var filter = StereoFilter()
        filter.set(type: .lowPass, cutoffL: 500, cutoffR: 500, q: 0.7071, immediate: true)
        filter.set(type: .lowPass, cutoffL: 8000, cutoffR: 8000, q: 0.7071, immediate: false)
        filter.prepare(frames: 256, sampleRate: rate)
        #expect(filter.cutoffL > 500 && filter.cutoffL < 4000)  // moved, but not there yet
        var previous = filter.cutoffL
        for _ in 0..<200 {
            filter.prepare(frames: 256, sampleRate: rate)
            #expect(filter.cutoffL >= previous)
            previous = filter.cutoffL
        }
        #expect(filter.cutoffL == 8000)
    }

    @Test func sweepingTheCutoffMakesNoClicks() throws {
        let audio = try makeSystem()
        let voice = audio.play(sine(200, seconds: 3, amplitude: 0.8), loop: true)
        voice.filter = AudioFilter(.lowPass, cutoff: 400)
        _ = audio.render(frames: 4800)
        voice.filter = AudioFilter(.lowPass, cutoff: 5000)  // a jump in the setting, a glide in the sound
        let output = audio.render(frames: 9600)
        var largest: Float = 0
        for i in 1..<9600 { largest = max(largest, abs(output[2 * i] - output[2 * (i - 1)])) }
        // A 200 Hz sine at 0.8 moves at most 2π·200/48000·0.8 ≈ 0.021 per frame.
        #expect(largest < 0.03, "largest step \(largest)")
    }

    @Test func voiceFilterAttenuatesHighFrequenciesOnly() throws {
        let audio = try makeSystem()
        let low = audio.play(sine(200), volume: 0.5, loop: true)
        low.filter = AudioFilter(.lowPass, cutoff: 1000)
        var output = audio.render(frames: 24000)
        let lowLevel = rms(output, frames: 12000..<24000)
        #expect(abs(lowLevel - 0.5 / Float(2).squareRoot()) < 0.01)
        low.stop()
        _ = audio.render(frames: 2400)

        let high = audio.play(sine(8000), volume: 0.5, loop: true)
        high.filter = AudioFilter(.lowPass, cutoff: 1000)
        output = audio.render(frames: 24000)
        #expect(rms(output, frames: 12000..<24000) < 0.02)
        high.filter = nil
        output = audio.render(frames: 24000)
        #expect(abs(rms(output, frames: 12000..<24000) - 0.5 / Float(2).squareRoot()) < 0.01)
    }

    @Test func busFilterEffect() throws {
        let audio = try makeSystem()
        let bus = audio.addBus("muffled")
        bus.effects = [.filter(AudioFilter(.highPass, cutoff: 2000))]
        #expect(bus.effects == [.filter(AudioFilter(.highPass, cutoff: 2000))])
        audio.play(sine(200), on: bus, loop: true)
        var output = audio.render(frames: 24000)
        #expect(rms(output, frames: 12000..<24000) < 0.01)
        bus.effects = []
        output = audio.render(frames: 24000)
        #expect(abs(rms(output, frames: 12000..<24000) - Float(0.5).squareRoot()) < 0.02)
    }

    @Test func extremeFilterSettingsStayFinite() throws {
        for (cutoff, q) in [(Float(0), Float(0)), (-5, -1), (1e9, 100), (10, 0.01), (23000, 50), (Float.nan, 1)] {
            var filter = StereoFilter()
            filter.set(type: .bandPass, cutoffL: cutoff.isNaN ? 1000 : cutoff, cutoffR: cutoff.isNaN ? 1000 : cutoff, q: q,
                       immediate: true)
            var buffer = (0..<512).map { Float(sin(Double($0) * 0.3)) }
            buffer = buffer.flatMap { [$0, $0] }
            buffer.withUnsafeMutableBufferPointer { p in
                for _ in 0..<40 {
                    filter.prepare(frames: 256, sampleRate: rate)
                    filter.process(p.baseAddress!, frames: 256)
                }
            }
            #expect(buffer.allSatisfy { $0.isFinite }, "cutoff \(cutoff) q \(q)")
        }
    }

    // MARK: - Reverb

    private func reverbBus(_ audio: AudioSystem, _ reverb: AudioReverb) -> AudioBus {
        let bus = audio.addBus("reverb")
        bus.effects = [.reverb(reverb)]
        return bus
    }

    @Test func reverbTailDecays() throws {
        let audio = try makeSystem()
        let bus = reverbBus(audio, AudioReverb(roomSize: 0.7))
        let voice = audio.play(impulse(), on: audio.addBus("dry-source"), volume: 1)
        voice.setSend(to: bus, level: 1)
        let output = audio.render(frames: 48000 * 4)
        #expect(output.allSatisfy { $0.isFinite && !$0.isSubnormal })
        let early = energy(output, frames: 2000..<26000)  // 0.04 s ... 0.54 s
        let mid = energy(output, frames: 48000..<72000)  // 1 s ... 1.5 s
        let late = energy(output, frames: 144000..<168000)  // 3 s ... 3.5 s
        #expect(early > 1e-6)
        #expect(mid < early && late < mid, "\(early) \(mid) \(late)")
        #expect(late < early * 0.01)
        // Past the dry impulse the first 10 ms are empty (the shortest delay line is 23 ms).
        #expect(energy(output, frames: 1..<480) == 0)
    }

    @Test func reverbTailLengthFollowsRoomSize() throws {
        func tailEnergy(roomSize: Float) throws -> Float {
            let audio = try makeSystem()
            let bus = reverbBus(audio, AudioReverb(roomSize: roomSize))
            audio.play(impulse(), volume: 1).setSend(to: bus, level: 1)
            let output = audio.render(frames: 48000 * 3)
            return energy(output, frames: 72000..<144000)
        }
        let small = try tailEnergy(roomSize: 0.2), large = try tailEnergy(roomSize: 0.9)
        #expect(large > 20 * small, "\(small) \(large)")
    }

    @Test func dampingRemovesHighFrequenciesFromTheTail() throws {
        func tailLevel(damping: Float) throws -> Float {
            let audio = try makeSystem()
            let bus = reverbBus(audio, AudioReverb(roomSize: 0.8, damping: damping))
            audio.play(sine(6000, seconds: 0.2, amplitude: 0.5), volume: 1).setSend(to: bus, level: 1)
            let output = audio.render(frames: 48000)
            return rms(output, frames: 24000..<48000)
        }
        let damped = try tailLevel(damping: 1), bright = try tailLevel(damping: 0)
        #expect(damped < bright * 0.6, "\(damped) \(bright)")
    }

    @Test func reverbIsSilentWithoutASendAndDryUntouched() throws {
        let audio = try makeSystem()
        let bus = reverbBus(audio, AudioReverb())
        let voice = audio.play(constant(0.5), loop: true)
        var output = audio.render(frames: 9600)
        #expect(output[2 * 9599] == 0.5)  // nothing sent: only the dry signal, bit for bit
        #expect(audio.sfx.level > 0 && bus.level == 0)
        voice.setSend(to: bus, level: 0.5)
        output = audio.render(frames: 9600)
        #expect(bus.level > 0)  // the reverb bus hears it (after the update)
        audio.update(dt: 0)
        output = audio.render(frames: 9600)
        #expect(bus.level > 0.01)
        voice.setSend(to: nil, level: 0)
        #expect(voice.sendBus == nil)
    }

    @Test func busSendFeedsTheReverb() throws {
        let audio = try makeSystem()
        let bus = reverbBus(audio, AudioReverb(roomSize: 0.6))
        audio.sfx.send(to: bus, level: 0.5)
        #expect(audio.sfx.sendTarget == bus && audio.sfx.sendLevel == 0.5)
        audio.play(impulse(), volume: 1)
        let output = audio.render(frames: 24000)
        #expect(energy(output, frames: 2000..<24000) > 1e-6)
        audio.sfx.send(to: nil, level: 0)
        #expect(audio.sfx.sendTarget == nil)
    }

    @Test func insertReverbMixesDryAndWet() throws {
        let audio = try makeSystem()
        let bus = audio.addBus("room")
        bus.effects = [.reverb(AudioReverb(roomSize: 0.5, wet: 0, dry: 1))]
        audio.play(constant(0.25), on: bus, loop: true)
        var output = audio.render(frames: 9600)
        #expect(abs(output[2 * 9599] - 0.25) < 1e-6)
        bus.effects = [.reverb(AudioReverb(roomSize: 0.5, wet: 0.5, dry: 0))]
        output = audio.render(frames: 48000)
        #expect(abs(output[2 * 47999] - 0.25) > 0.01)  // the wet signal replaced the dry one
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func reverbOutputStaysBoundedAndFinite() throws {
        let audio = try makeSystem()
        let bus = reverbBus(audio, AudioReverb(roomSize: 1, damping: 0, width: 1, wet: 1))
        let voice = audio.play(sine(220, seconds: 1, amplitude: 1), loop: true)
        voice.setSend(to: bus, level: 1)
        let output = audio.render(frames: 48000 * 2)
        #expect(output.allSatisfy { $0.isFinite && abs($0) <= 1 })
        // Out-of-range parameters are clamped, not trusted.
        bus.effects = [.reverb(AudioReverb(roomSize: 50, damping: -3, width: 9, wet: 1, dry: 0))]
        let more = audio.render(frames: 48000)
        #expect(more.allSatisfy { $0.isFinite && abs($0) <= 1 })
    }

    @Test func reverbDiesToExactSilenceWithoutDenormals() throws {
        let audio = try makeSystem()
        let bus = reverbBus(audio, AudioReverb(roomSize: 0.3, damping: 0.5))
        audio.play(impulse(), volume: 1).setSend(to: bus, level: 1)
        var sawSubnormal = false
        var lastFrames: [Float] = []
        for _ in 0..<12 {
            let block = audio.render(frames: 48000)
            if block.contains(where: { $0.isSubnormal }) { sawSubnormal = true }
            lastFrames = block
        }
        #expect(!sawSubnormal)
        #expect(lastFrames.allSatisfy { $0 == 0 })
    }

    @Test func effectChainsRunInOrderAndChangeCleanly() throws {
        let audio = try makeSystem()
        let bus = audio.addBus("chain")
        bus.effects = [.filter(AudioFilter(.lowPass, cutoff: 3000)), .reverb(AudioReverb(wet: 0.3, dry: 1)),
                       .filter(AudioFilter(.highPass, cutoff: 100))]
        let voice = audio.play(sine(500, seconds: 2, amplitude: 0.5), on: bus, loop: true)
        _ = voice
        var output = audio.render(frames: 24000)
        #expect(output.allSatisfy { $0.isFinite })
        bus.effects = Array(repeating: .filter(AudioFilter(.bandPass, cutoff: 500, q: 1)), count: 9)  // clamped to 4 slots
        #expect(bus.effects.count == AudioMixer.effectsPerBus)
        output = audio.render(frames: 24000)
        #expect(output.allSatisfy { $0.isFinite })
    }
}
