import Foundation
import Testing
@testable import Engine

// Sound builds: deterministic synthesis, presets, mutate, file round trip and the .sfx importer.

@Suite struct SoundBuildTests {
    @Test func sameParametersAndSeedGiveIdenticalSamples() {
        for preset in SFXPreset.allCases {
            let a = SoundBuild.preset(preset, seed: 42), b = SoundBuild.preset(preset, seed: 42)
            #expect(a == b)
            #expect(a.render() == b.render(), "\(preset)")
        }
        var noise = SoundBuild(waveform: .noise)
        noise.seed = 5
        let first = noise.render()
        noise.seed = 6
        #expect(noise.render() != first, "a different seed changes noise")
        noise.seed = 5
        #expect(noise.render() == first)
    }

    @Test func rendersAudibleBoundedSamples() {
        for preset in SFXPreset.allCases {
            let samples = SoundBuild.preset(preset).render()
            #expect(!samples.isEmpty)
            #expect(samples.allSatisfy { $0.isFinite && abs($0) <= 1 })
            #expect((samples.map { abs($0) }.max() ?? 0) > 0.05, "\(preset) is audible")
        }
        let build = SoundBuild(attack: 0.1, sustain: 0.1, decay: 0.3)
        #expect(abs(Double(build.render().count) - 0.5 * 44100) < 2)
    }

    @Test func mutateAndRandomizeAreDeterministicAndDiffer() {
        let base = SoundBuild.preset(.laser)
        let m1 = base.mutated(amount: 0.3, seed: 9), m2 = base.mutated(amount: 0.3, seed: 9)
        #expect(m1 == m2)
        #expect(m1 != base)
        #expect(SoundBuild.preset(.coin, seed: 1) != SoundBuild.preset(.coin, seed: 2))
        #expect(base.mutated(amount: 0, seed: 3).render().count == base.render().count)
    }

    @Test func fileRoundTripAndOptionalKeys() throws {
        let build = SoundBuild.preset(.explosion, seed: 3)
        let decoded = try AssetJSON.decoder().decode(SoundBuild.self, from: build.fileData())
        #expect(decoded == build)
        let empty = try AssetJSON.decoder().decode(SoundBuild.self, from: Data("{}".utf8))
        #expect(empty == SoundBuild())
        #expect(SoundBuild(volume: 0).problems().contains { $0.contains("silent") })
    }

    @MainActor @Test func sfxFileLoadsAsASoundAndImports() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SoundBuildTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "Sfx")
        defer { try? FileManager.default.removeItem(at: url) }
        let db = AssetDatabase(project: project)
        db.refresh()
        let build = SoundBuild.preset(.coin, seed: 11)
        let id = try db.createSoundBuild(build, at: "Sounds/coin.sfx")
        #expect(db.record(id)?.importer == "sfx")
        #expect(db.record(id)?.importError == nil)
        #expect(db.soundBuild(of: id) == build)
        let buffer = try db.loadSound(id)
        #expect(buffer.samples == build.render())
        #expect(buffer.channelCount == 1)

        var louder = build
        louder.frequency = 700
        try db.writeSoundBuild(louder, to: id)
        #expect(try db.loadSound(id).samples == louder.render())

        // From bytes too (packs).
        let decoder = try AudioFile.decoder(data: build.fileData())
        #expect(decoder.frameCount == build.render().count)
    }
}
