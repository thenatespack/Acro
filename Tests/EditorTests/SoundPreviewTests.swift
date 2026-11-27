import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersAnimation
@testable import Engine
@testable import EngineCore
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineUI

// The editor's sound preview: clicking an audio file in the asset browser (or its inspector's
// Play / Stop), and an audio track or key in the Timeline builder.

@MainActor private func makeProject() throws -> (EditorSession, URL, AudioSystem) {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SoundPreviewTests-\(UUID().uuidString)")
    let assets = folder.appendingPathComponent("Assets")
    try FileManager.default.createDirectory(at: assets.appendingPathComponent("Audio"), withIntermediateDirectories: true)
    try WAVWriter.encode([Float](repeating: 0.5, count: 48000), channelCount: 1, sampleRate: 48000)
        .write(to: assets.appendingPathComponent("Audio/door.wav"))
    #expect(session.newProject(path: folder.path))
    session.assets?.waitForAll()
    let audio = try AudioSystem(device: OfflineAudioDevice(sampleRate: 48000), maxVoices: 8)
    session.audioProvider = { audio }
    return (session, folder, audio)
}

@MainActor @Suite(.serialized) struct SoundPreviewTests {
    @Test func clipsResolveToFilesAndSoundBuilds() throws {
        let (session, folder, _) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = try #require(session.assets)
        let door = try #require(assets.id(forPath: "Audio/door.wav"))
        let blip = try assets.createSoundBuild(.preset(.blip), at: "Audio/blip.sfx")

        guard case .file(let url)? = SoundPreview.source(of: "Audio/door.wav", in: assets) else {
            Issue.record("a path should name the wav")
            return
        }
        #expect(url.lastPathComponent == "door.wav")
        #expect(SoundPreview.source(of: AssetReference(door).description, in: assets) == .file(url))
        #expect(SoundPreview.source(of: AssetReference(blip).description, in: assets) == .build(.preset(.blip)))
        #expect(SoundPreview.source(of: "Audio/missing.wav", in: assets) == nil)
        #expect(SoundPreview.source(of: "", in: assets) == nil)
    }

    @Test func selectingAnAudioTrackPlaysItsSoundOnce() throws {
        let (session, folder, audio) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let timeline = Timeline(duration: 4, tracks: [
            TimelineTrack(id: "fade", kind: .fade, keys: [TimelineKey(time: 0, amount: 0)]),
            TimelineTrack(id: "sfx", kind: .audio, keys: [TimelineKey(time: 0), TimelineKey(time: 1, clip: "Audio/door.wav", volume: 0.5)]),
        ])
        let id = try #require(session.createTimelineAsset(in: "", name: "Intro", timeline: timeline))
        let view = try #require(TimelineBuilderView(session: session, asset: id))

        view.select(track: "fade", key: 0)
        #expect(!view.previewSelectedSound())
        #expect(audio.activeVoices.isEmpty)

        // The track's first key has no sound: the track plays its first key that has one.
        view.select(track: "sfx", key: 0)
        #expect(view.previewSelectedSound())
        #expect(audio.activeVoices.count == 1)

        // Clicking again replaces the preview instead of stacking voices.
        view.select(track: "sfx", key: 1)
        #expect(view.previewSelectedSound())
        // (The replaced voice fades out over a few milliseconds first, so there are no clicks.)
        _ = audio.render(frames: 2400)
        #expect(audio.activeVoices.count == 1)

        session.stopSoundPreview()
        _ = audio.render(frames: 2400)
        #expect(audio.activeVoices.isEmpty)
    }

    @Test func noAudioDeviceMeansNoPreview() throws {
        let (session, folder, _) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        session.audioProvider = nil
        #expect(!session.previewSound(clip: "Audio/door.wav"))
    }

    @Test func clickingASoundInTheBrowserOnlySelectsIt() throws {
        let (session, folder, audio) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = try #require(session.assets)
        let door = try #require(assets.id(forPath: "Audio/door.wav"))
        let blip = try assets.createSoundBuild(.preset(.blip), at: "Audio/blip.sfx")
        let timeline = try #require(session.createTimelineAsset(in: "", name: "Intro"))
        #expect(session.isSoundAsset(door) && session.isSoundAsset(blip) && !session.isSoundAsset(timeline))
        let model = AssetBrowserModel(session: session)

        model.clicked(.asset(door))
        #expect(session.soundPreviewAsset == nil && audio.activeVoices.isEmpty)

        // A preview playing (from the inspector) keeps playing while its file is clicked, and
        // stops when something else is.
        session.previewSound(asset: door)
        model.clicked(.asset(door))
        #expect(session.soundPreviewAsset == door)
        model.clicked(.asset(blip))
        #expect(session.soundPreviewAsset == nil)
        session.previewSound(asset: blip)
        model.clicked(.asset(timeline))
        #expect(session.soundPreviewAsset == nil)

        // A finished sound no longer counts as playing.
        session.previewSound(asset: door)
        _ = audio.render(frames: 48000 + 4800)
        #expect(session.soundPreviewAsset == nil)
    }

    /// Shows `item` until the inspector's sound section has read its sound.
    private func showUntilRead(_ inspector: AssetInspectorView, _ item: AssetItem) async throws -> AudioInspectorSection {
        for _ in 0..<500 {
            inspector.show(item)
            if let section = inspector.audioSection, section.analysis != nil { return section }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw CommandError.failed("the sound wasn't read")
    }

    @Test func theInspectorShowsTheWaveformAndDetailsAndPlays() async throws {
        let (session, folder, audio) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = try #require(session.assets)
        let door = try #require(assets.id(forPath: "Audio/door.wav"))
        let timeline = try #require(session.createTimelineAsset(in: "", name: "Intro"))
        let inspector = AssetInspectorView(session: session)

        inspector.show(.asset(timeline))
        #expect(inspector.audioSection == nil && inspector.view.descendant(named: "assetPlaySound") == nil)

        // Selecting the sound reads it (in the background) without playing it.
        let section = try await showUntilRead(inspector, .asset(door))
        #expect(audio.activeVoices.isEmpty)
        let analysis = try #require(section.analysis)
        #expect(analysis.format == "WAV" && analysis.channelCount == 1 && analysis.sampleRate == 48000)
        #expect(analysis.frameCount == 48000 && abs(analysis.duration - 1) < 1e-9)
        #expect(abs(analysis.peak - 0.5) < 1e-3 && abs(analysis.rms - 0.5) < 1e-3)
        #expect(section.waveform.analysis == analysis && analysis.maximums[0].allSatisfy { abs($0 - 0.5) < 1e-3 })
        func info(_ name: String) -> String? { (section.view.descendant(named: "audioInfo.\(name)") as? Label)?.text }
        #expect(info("Format") == "WAV" && info("Duration") == "0:01.000" && info("Sample rate") == "48,000 Hz")
        #expect(info("Channels") == "Mono" && info("Peak") == "-6.0 dBFS" && info("Loudness") == "-6.0 dBFS RMS")
        #expect(info("File size") != nil)

        // Play / Stop.
        let button = try #require(inspector.view.descendant(named: "assetPlaySound") as? Button)
        #expect(button.title == "Play")
        button.action?()
        #expect(session.soundPreviewAsset == door)
        inspector.show(.asset(door))
        #expect(button.title == "Stop" && section.waveform.playhead != nil)
        button.action?()
        #expect(session.soundPreviewAsset == nil)
        inspector.show(.asset(door))
        #expect(button.title == "Play" && section.waveform.playhead == nil)

        // A click on the waveform plays from there: the file skips to it in the background.
        section.waveform.onSeek?(0.5)
        #expect(session.soundPreviewAsset == door)
        #expect(SoundPreview.isStarting)
        for _ in 0..<500 where SoundPreview.isStarting { try await Task.sleep(for: .milliseconds(10)) }
        #expect(!SoundPreview.isStarting && session.soundPreviewAsset == door)
        #expect((session.soundPreviewPlayhead ?? 0) >= 0.5)
        // The rest of the file is half a second (the editor pumps streams every frame).
        func run(seconds: Double) {
            for _ in 0..<Int(seconds * 20) {
                audio.update(dt: 0.05)
                _ = audio.render(frames: 2400)
            }
        }
        run(seconds: 0.7)
        #expect(session.soundPreviewAsset == nil)

        // Loop keeps going past the end.
        section.loopToggle.isOn = true
        button.action?()
        run(seconds: 2.5)
        #expect(session.soundPreviewAsset == door)
        session.stopSoundPreview()
    }

    @Test func aSoundBuildShowsItsWaveformAndPlaysFromAPoint() async throws {
        let (session, folder, audio) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = try #require(session.assets)
        let build = SoundBuild.preset(.blip)
        let blip = try assets.createSoundBuild(build, at: "Audio/blip.sfx")
        let inspector = AssetInspectorView(session: session)
        let section = try await showUntilRead(inspector, .asset(blip))
        let analysis = try #require(section.analysis)
        #expect(analysis.format == "Synthesized (.sfx)" && analysis.frameCount == build.render().count)
        #expect(analysis.bitrate == nil)
        section.waveform.onSeek?(Double(build.duration) / 2)
        #expect(session.soundPreviewAsset == blip && audio.activeVoices.count == 1)
    }

    @Test func agentsGetTheSameInfoAndPreview() throws {
        let (session, folder, audio) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let door = try #require(session.assets?.id(forPath: "Audio/door.wav"))
        let info = try #require(session.run(AudioInfoCommand.self, .init(asset: AssetReference(door), buckets: 8)))
        #expect(info.format == "WAV" && info.channels == 1 && info.frames == 48000 && info.peakDB == -6.0)
        #expect(info.waveform.count == 8 && info.waveform.allSatisfy { $0 == 0.5 })
        let played = try #require(session.run(AudioPreviewCommand.self, .init(asset: AssetReference(door))))
        #expect(played.playing && audio.activeVoices.count == 1)
        #expect(session.run(AudioPreviewCommand.self, .init(stop: true))?.playing == false)
        #expect(session.soundPreviewAsset == nil)
        let timeline = try #require(session.createTimelineAsset(in: "", name: "Intro"))
        #expect(throws: (any Error).self) { try session.commands.run(AudioInfoCommand.self, .init(asset: AssetReference(timeline))) }
    }
}
