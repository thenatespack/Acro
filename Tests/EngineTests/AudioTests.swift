import Foundation
import Testing
@testable import Engine

// Audio tests run on the offline device, so every sample is deterministic.

private let rate = 48000.0

private func makeSystem(maxVoices: Int = 64) throws -> AudioSystem {
    try AudioSystem(device: OfflineAudioDevice(sampleRate: rate), maxVoices: maxVoices)
}

/// A constant (DC) sound, handy because gains show up directly in the output.
private func constant(_ value: Float, frames: Int, channels: Int = 1, sampleRate: Double = rate) -> SoundBuffer {
    SoundBuffer(frameCount: frames, channelCount: channels, sampleRate: sampleRate) { _, _ in value }
}

private func left(_ output: [Float], _ frame: Int) -> Float { output[2 * frame] }
private func right(_ output: [Float], _ frame: Int) -> Float { output[2 * frame + 1] }

private func resource(_ name: String) throws -> URL {
    try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Resources/audio"))
}

@Suite struct AudioTests {
    // MARK: - WAV

    // Tolerance: one quantization step (half a step from rounding, a full one at +1.0, which
    // clamps to the largest positive code).
    @Test(arguments: [(WAVWriter.Encoding.pcm8, Float(1.0 / 128)), (.pcm16, 1.0 / 32768), (.pcm24, 1.0 / 8_388_608),
                      (.pcm32, 1e-7), (.float32, 0), (.float64, 0)])
    func wavRoundTrip(encoding: WAVWriter.Encoding, tolerance: Float) throws {
        // Stereo ramp with distinct channels, including the extremes.
        let frames = 301
        var samples: [Float] = []
        for i in 0..<frames {
            let t = Float(i) / Float(frames - 1) * 2 - 1
            samples += [t, -t * 0.5]
        }
        let data = WAVWriter.encode(samples, channelCount: 2, sampleRate: 22050, encoding: encoding)
        let decoder = try WAVDecoder(data: data)
        #expect(decoder.channelCount == 2)
        #expect(decoder.sampleRate == 22050)
        #expect(decoder.frameCount == frames)
        let sound = try SoundBuffer(data: data)
        #expect(sound.frameCount == frames)
        let decoded = sound.samples
        for i in samples.indices {
            #expect(abs(decoded[i] - samples[i]) <= tolerance, "sample \(i): \(decoded[i]) vs \(samples[i])")
        }
    }

    @Test func wavParsesExtensibleFormatOddChunksAndKeepsTwoChannels() throws {
        // WAVE_FORMAT_EXTENSIBLE, 4 channels of 16-bit PCM, after an odd-sized LIST chunk (padded).
        var bytes: [UInt8] = []
        func u16(_ v: Int) { bytes += [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF)] }
        func u32(_ v: Int) { bytes += [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 24 & 0xFF)] }
        let frames: [[Int16]] = [[1000, -2000, 5, 6], [16384, -16384, 7, 8], [32767, -32768, 9, 10]]
        bytes += Array("RIFF".utf8); u32(0)  // size unused by the reader
        bytes += Array("WAVE".utf8)
        bytes += Array("LIST".utf8); u32(3); bytes += [1, 2, 3, 0]  // odd chunk + pad byte
        bytes += Array("fmt ".utf8); u32(40)
        u16(0xFFFE); u16(4); u32(44100); u32(44100 * 8); u16(8); u16(16)
        u16(22); u16(16); u32(0x33)  // cbSize, valid bits, channel mask
        u16(1); bytes += [0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71]  // PCM GUID
        bytes += Array("data".utf8); u32(frames.count * 8)
        for frame in frames { for s in frame { u16(Int(UInt16(bitPattern: s))) } }
        let decoder = try WAVDecoder(data: Data(bytes))
        #expect(decoder.fileChannelCount == 4)
        #expect(decoder.channelCount == 2)
        #expect(decoder.sampleFormat == .pcm(bits: 16))
        let sound = try SoundBuffer(decoder: decoder)
        let expected: [Float] = [1000.0 / 32768, -2000.0 / 32768, 0.5, -0.5, 32767.0 / 32768, -1]
        #expect(sound.samples == expected)
    }

    @Test func wavRejectsGarbage() {
        #expect(throws: (any Error).self) { try WAVDecoder(data: Data("RIFF....WAVEjunk".utf8)) }
        #expect(throws: (any Error).self) { try SoundBuffer(data: Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])) }
    }

    @Test func wavStreamsFromFileLikeFromMemory() throws {
        let samples = (0..<10000).map { Float(sin(Double($0) * 0.01)) * 0.8 }
        let data = WAVWriter.encode(samples, channelCount: 1, sampleRate: 32000, encoding: .pcm24)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio-test-\(UUID().uuidString).wav")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let fromFile = try SoundBuffer(contentsOf: url)
        let fromMemory = try SoundBuffer(data: data)
        #expect(fromFile.samples == fromMemory.samples)
        #expect(fromFile.sampleRate == 32000)
        #expect(fromFile.name.hasPrefix("audio-test-"))
    }

    // MARK: - Compressed formats

    @Test(arguments: ["tone.ogg", "tone.mp3"])
    func compressedStreamDecodeEqualsFullDecode(file: String) throws {
        let url = try resource(file)
        let full = try SoundBuffer(contentsOf: url)
        #expect(full.channelCount == 2)
        #expect(full.sampleRate == 22050)
        // 0.4 s; MP3 adds encoder delay / padding.
        #expect(abs(full.frameCount - 8820) < 2400, "\(full.frameCount) frames")
        // The left channel is a 440 Hz sine at 0.5, the right 660 Hz at 0.4.
        let samples = full.samples
        let peakL = stride(from: 0, to: samples.count, by: 2).map { abs(samples[$0]) }.max() ?? 0
        let peakR = stride(from: 1, to: samples.count, by: 2).map { abs(samples[$0]) }.max() ?? 0
        #expect(abs(peakL - 0.5) < 0.08 && abs(peakR - 0.4) < 0.08, "peaks \(peakL) \(peakR)")

        // Decoding in small odd-sized chunks (as a stream does) gives the same samples.
        let decoder = try AudioFile.decoder(contentsOf: url)
        var streamed: [Float] = []
        var chunk = [Float](repeating: 0, count: 777 * 2)
        while true {
            let n = try chunk.withUnsafeMutableBufferPointer { try decoder.read(into: $0.baseAddress!, frames: 777) }
            if n == 0 { break }
            streamed += chunk[0..<(n * 2)]
        }
        #expect(streamed == samples)
        // And again after rewinding.
        try decoder.rewind()
        let again = try SoundBuffer(decoder: decoder)
        #expect(again.samples == samples)
    }

    @Test func formatDetection() {
        #expect(AudioFile.format(of: Data("RIFF\0\0\0\0WAVE".utf8)) == .wav)
        #expect(AudioFile.format(of: Data("OggS".utf8)) == .vorbis)
        #expect(AudioFile.format(of: Data("ID3\u{3}".utf8)) == .mp3)
        #expect(AudioFile.format(of: Data([0xFF, 0xFB, 0x90])) == .mp3)
        #expect(AudioFile.format(of: Data("hello".utf8)) == nil)
    }

    // MARK: - Mixing

    @Test func voicesSumAndPan() throws {
        let audio = try makeSystem()
        audio.play(constant(0.25, frames: 1000))
        audio.play(constant(0.125, frames: 1000))
        audio.play(constant(0.5, frames: 1000), pan: 1)  // right only
        audio.play(SoundBuffer(frameCount: 1000, channelCount: 2, sampleRate: rate) { _, c in c == 0 ? 0.0625 : -0.0625 })
        let out = audio.render(frames: 1200)
        #expect(left(out, 10) == 0.25 + 0.125 + 0.0625)
        #expect(right(out, 10) == 0.25 + 0.125 + 0.5 - 0.0625)
        // Every voice ended after its 1000 frames.
        #expect(left(out, 1100) == 0 && right(out, 1100) == 0)
        #expect(audio.activeVoices.isEmpty)
    }

    @Test func outputIsClamped() throws {
        let audio = try makeSystem()
        audio.play(constant(0.8, frames: 100))
        audio.play(constant(0.8, frames: 100))
        let out = audio.render(frames: 50)
        #expect(left(out, 0) == 1)
    }

    @Test func busVolumeMuteAndNesting() throws {
        let audio = try makeSystem()
        let ui = audio.addBus("ui", parent: audio.sfx)
        audio.play(constant(0.5, frames: 48000))
        audio.play(constant(0.25, frames: 48000), on: ui)
        var out = audio.render(frames: 100)
        #expect(left(out, 50) == 0.75)

        // Changes ramp over 10 ms (480 frames), then hold.
        audio.sfx.volume = 0.5
        out = audio.render(frames: 1000)
        #expect(left(out, 0) > 0.375 && left(out, 0) < 0.75)
        #expect(abs(left(out, 600) - 0.375) < 1e-6)
        for k in 1..<1000 { #expect(left(out, k) <= left(out, k - 1)) }  // no jumps up: a smooth ramp down

        ui.volume = 0.5  // ui is under sfx: 0.5 * 0.5 * 0.25
        out = audio.render(frames: 1000)
        #expect(abs(left(out, 900) - (0.25 + 0.0625)) < 1e-6)

        audio.sfx.isMuted = true
        out = audio.render(frames: 1000)
        #expect(left(out, 900) == 0)
        _ = audio.render(frames: 100)  // the level is the peak over the last render, which included the fade
        #expect(audio.sfx.level == 0 && audio.sfx.volume == 0.5)

        audio.sfx.isMuted = false
        audio.master.volume = 2
        out = audio.render(frames: 1000)
        #expect(abs(left(out, 900) - 0.625) < 1e-6)
        #expect(abs(audio.master.level - 0.625) < 1e-6)
        #expect(audio.music.level == 0)
        #expect(audio.bus(named: "ui") == ui && ui.parent == audio.sfx)
    }

    @Test func pausedBusHoldsVoices() throws {
        let audio = try makeSystem()
        let ramp = SoundBuffer(frameCount: 10000, sampleRate: rate) { i, _ in Float(i) / 10000 }
        let voice = audio.play(ramp)
        _ = audio.render(frames: 1000)
        audio.sfx.isPaused = true
        var out = audio.render(frames: 2000)
        #expect(left(out, 1999) == 0)
        let held = voice.position
        _ = audio.render(frames: 2000)
        #expect(voice.position == held && voice.isPlaying)
        audio.sfx.isPaused = false
        out = audio.render(frames: 1000)
        #expect(left(out, 999) > 0)
        #expect(voice.position > held)
    }

    @Test func loopingWrapsExactlyAtTheBoundary() throws {
        let audio = try makeSystem()
        let n = 100
        let sound = SoundBuffer(frameCount: n, sampleRate: rate) { i, _ in Float(i + 1) / 1000 }
        let voice = audio.play(sound, loop: true)
        let out = audio.render(frames: 350)
        for k in 0..<350 { #expect(left(out, k) == Float(k % n + 1) / 1000, "frame \(k)") }
        #expect(voice.isPlaying)
        #expect(abs(voice.position - Double(349 % n) / rate) < 2 / rate)

        // An intro, then a loop of frames 50..<100.
        let audio2 = try makeSystem()
        audio2.play(sound, loop: true, loopRange: 50..<100)
        let out2 = audio2.render(frames: 250)
        for k in 0..<250 {
            let expected = k < 100 ? k : 50 + (k - 100) % 50
            #expect(left(out2, k) == Float(expected + 1) / 1000, "frame \(k)")
        }
    }

    @Test func resamplingAndPitchSetTheLength() throws {
        // 1000 frames at 24 kHz on a 48 kHz device: 2000 output frames. Pitch 2 halves that.
        for (pitch, expected) in [(Float(1), 2000), (2, 1000), (0.5, 4000)] {
            let audio = try makeSystem()
            let voice = audio.play(constant(0.5, frames: 1000, sampleRate: 24000), pitch: pitch)
            let out = audio.render(frames: 5000)
            let audible = (0..<5000).filter { left(out, $0) != 0 }.count
            #expect(audible == expected, "pitch \(pitch): \(audible)")
            #expect(!voice.isPlaying)
        }
        // Linear interpolation between source frames when upsampling.
        let audio = try makeSystem()
        audio.play(SoundBuffer(samples: [0, 1, 0], channelCount: 1, sampleRate: 24000))
        let out = audio.render(frames: 8)
        #expect((0..<6).map { left(out, $0) } == [0, 0.5, 1, 0.5, 0, 0])
    }

    @Test func voiceControlsFadeInsteadOfClicking() throws {
        let audio = try makeSystem()
        let voice = audio.play(constant(0.5, frames: 48000), volume: 1)
        _ = audio.render(frames: 100)
        voice.volume = 0.5
        voice.pan = -1
        var out = audio.render(frames: 1000)
        #expect(abs(left(out, 900) - 0.25) < 1e-6 && right(out, 900) == 0)
        #expect(voice.volume == 0.5 && voice.pan == -1)

        voice.pause(fade: 0.01)
        out = audio.render(frames: 1000)
        #expect(left(out, 100) > 0 && left(out, 900) == 0)
        #expect(voice.isPaused && voice.isPlaying)
        let held = voice.position
        _ = audio.render(frames: 1000)
        #expect(voice.position == held)
        voice.resume()
        out = audio.render(frames: 1000)
        #expect(abs(left(out, 900) - 0.25) < 1e-6)

        voice.stop(fade: 0.005)  // 240 frames
        out = audio.render(frames: 1000)
        for k in 1..<240 { #expect(left(out, k) <= left(out, k - 1)) }
        #expect(left(out, 300) == 0)
        #expect(!voice.isPlaying)
        // Controls on an ended voice do nothing.
        voice.volume = 1
        #expect(voice.volume == 0)
    }

    @Test func handlesSurviveSlotReuse() throws {
        let audio = try makeSystem(maxVoices: 1)
        let first = audio.play(constant(0.5, frames: 10))
        _ = audio.render(frames: 100)
        #expect(!first.isPlaying)
        let second = audio.play(constant(0.25, frames: 1000))
        #expect(second.isPlaying && first != second)
        first.stop()  // must not stop the voice now in the same slot
        let out = audio.render(frames: 100)
        #expect(left(out, 99) == 0.25)
        // No free voice: an inert handle.
        let third = audio.play(constant(1, frames: 10))
        #expect(!third.isValid && !third.isPlaying)
    }

    @Test func fadeInRampsUp() throws {
        let audio = try makeSystem()
        audio.play(constant(1, frames: 4800, channels: 2), volume: 0.5, fadeIn: 0.01)
        let out = audio.render(frames: 1000)
        #expect(left(out, 0) < 0.01)
        for k in 1..<480 { #expect(left(out, k) >= left(out, k - 1)) }
        #expect(left(out, 600) == 0.5)
    }

    @Test func duckingRampsSmoothlyDownAndBackUp() throws {
        let audio = try makeSystem()
        let attack = 0.1, release = 0.2
        audio.duck(audio.music, while: audio.voice, to: 0.25, attack: attack, release: release)
        audio.play(constant(0.5, frames: 1000), on: audio.music, loop: true)
        var out = audio.render(frames: 4800)
        #expect(left(out, 4799) == 0.5)

        // A (silent) line of dialogue for 0.5 s.
        let line = audio.play(constant(0, frames: 24000), on: audio.voice)
        out = audio.render(frames: 24000)
        let maxStep = Float(0.5 * 0.75 / (attack * rate)) * 1.001
        for k in 1..<24000 {
            let step = left(out, k - 1) - left(out, k)
            #expect(step >= 0 && step <= maxStep, "frame \(k): step \(step)")
            if step < 0 || step > maxStep { break }
        }
        // Fully ducked after the attack time (plus at most one mixer block of detection latency).
        let settled = Int(attack * rate) + AudioMixer.blockSize
        #expect(abs(left(out, settled) - 0.125) < 1e-5)
        #expect(left(out, 23999) == 0.125)

        // The line ends; the music comes back up over the release time.
        out = audio.render(frames: 24000)
        #expect(!line.isPlaying)
        for k in 1..<24000 { #expect(left(out, k) >= left(out, k - 1)) }
        let back = Int(release * rate) + AudioMixer.blockSize
        #expect(left(out, back) == 0.5)
        #expect(left(out, back / 2 - AudioMixer.blockSize) < 0.5)

        audio.stopDucking(audio.music)
        #expect(audio.music.ducking == nil)
    }

    // MARK: - Streaming

    @Test func streamedVoiceMatchesBufferedVoice() throws {
        // 5 s of stereo at 44.1 kHz (longer than the 2 s stream buffer), played at a pitch so
        // resampling and the ring's wrap-around are both exercised.
        let frames = 44100 * 5
        var samples = [Float](repeating: 0, count: frames * 2)
        for i in 0..<frames {
            samples[2 * i] = Float(sin(Double(i) * 0.031)) * 0.5
            samples[2 * i + 1] = Float(sin(Double(i) * 0.017)) * 0.5
        }
        let data = WAVWriter.encode(samples, channelCount: 2, sampleRate: 44100, encoding: .float32)
        let buffered = try makeSystem()
        buffered.play(try SoundBuffer(data: data), on: buffered.music, pitch: 1.25)
        let streamed = try makeSystem()
        let voice = streamed.playStream(try WAVDecoder(data: data), loop: false)
        voice.pitch = 1.25
        #expect(voice.bus == streamed.music)
        let a = buffered.render(frames: 48000 * 5)
        let b = streamed.render(frames: 48000 * 5)
        #expect(a == b)
        #expect(a.contains { $0 != 0 })
        #expect(!voice.isPlaying)
        #expect(streamed.streamUnderruns == 0)
    }

    @Test func loopingStreamWrapsSeamlessly() throws {
        let n = 3000
        let samples = (0..<n).map { Float($0 + 1) / Float(n * 2) }
        let data = WAVWriter.encode(samples, channelCount: 1, sampleRate: Int(rate), encoding: .float32)
        let audio = try makeSystem()
        let voice = audio.playStream(try WAVDecoder(data: data), on: audio.sfx)
        let out = audio.render(frames: 10000)
        for k in 0..<10000 { #expect(left(out, k) == samples[k % n], "frame \(k)") }
        #expect(voice.isPlaying)
        voice.stop(fade: 0)
        _ = audio.render(frames: 10)
        #expect(!voice.isPlaying && audio.activeVoices.isEmpty)
    }

    @Test func stopAllOnABus() throws {
        let audio = try makeSystem()
        let a = audio.play(constant(0.5, frames: 48000))
        let b = audio.play(constant(0.5, frames: 48000), on: audio.music)
        audio.stopAll(on: audio.sfx)
        _ = audio.render(frames: 2000)
        #expect(!a.isPlaying && b.isPlaying)
        #expect(audio.activeVoices == [b])
    }

    @Test func updateAdvancesTheOfflineDevice() throws {
        let audio = try makeSystem()
        let voice = audio.play(constant(0.5, frames: 4800))  // 0.1 s
        for _ in 0..<5 { audio.update(dt: 1.0 / 60) }
        #expect(voice.isPlaying)
        #expect(audio.sfx.level == 0.5)
        for _ in 0..<2 { audio.update(dt: 1.0 / 60) }
        #expect(!voice.isPlaying)
    }

    // MARK: - Assets

    @Test func audioImporterReadsTheHeader() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("audio-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("beep.wav")
        try WAVWriter.encode([Float](repeating: 0.1, count: 2205), channelCount: 1, sampleRate: 22050).write(to: url)
        var context = ImportContext(assetID: AssetID.random(), sourceURL: url, assetPath: "beep.wav", artifactsDirectory: dir)
        let importer = AudioImporter()
        #expect(importer.fileExtensions.contains("ogg"))
        _ = try importer.importAsset(&context, settings: importer.defaultSettings)
        let info = try AudioImporter.info(contentsOf: url)
        #expect(info.format == .wav && info.channelCount == 1 && info.sampleRate == 22050 && info.duration == 0.1)
        try Data("not audio".utf8).write(to: url)
        #expect(throws: (any Error).self) { _ = try importer.importAsset(&context, settings: importer.defaultSettings) }
    }
}
