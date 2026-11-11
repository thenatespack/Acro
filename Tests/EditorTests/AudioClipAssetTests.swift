import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Audio assets on AudioEmitter.clip (dropdown, drop, play mode loading) and scene.open path forms.

@MainActor private func makeAudioProject() throws -> (EditorSession, URL, AssetID) {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("AudioClipAssetTests-\(UUID().uuidString)")
    let assets = folder.appendingPathComponent("Assets")
    try FileManager.default.createDirectory(at: assets.appendingPathComponent("Audio"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: assets.appendingPathComponent("Scenes"), withIntermediateDirectories: true)
    try WAVWriter.encode([Float](repeating: 0.5, count: 4800), channelCount: 1, sampleRate: 48000)
        .write(to: assets.appendingPathComponent("Audio/rain.wav"))
    #expect(session.newProject(path: folder.path))
    session.assets?.waitForAll()
    let id = try #require(session.assets?.id(forPath: "Audio/rain.wav"))
    return (session, folder, id)
}

@MainActor @Suite struct AudioClipAssetTests {
    @Test func inspectorListsAudioAssetsAndDropSetsClip() throws {
        let (session, folder, id) = try makeAudioProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let entity = session.world.spawn(Transform(), AudioEmitter())
        let entityID = try #require(session.world.ensureID(of: entity))
        let choices = AssetChoices(meshes: { [] }, materials: { [] }, assets: { session.assets })
        #expect(choices.options(component: "AudioEmitter", path: "clip") == ["", AssetReference(id).description])
        #expect(choices.options(component: "AudioEmitter", path: "sound") == nil)
        #expect(choices.title(AssetReference(id).description) == "Audio/rain.wav")

        #expect(session.drop(.asset(id), on: .audioField(entity: entityID)))
        #expect(session.world.get(AudioEmitter.self, for: entity)?.clip == AssetReference(id).description)
    }

    @Test func playModeLoadsTheClipAndStopSilencesIt() throws {
        let (session, folder, id) = try makeAudioProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let audio = try AudioSystem(device: OfflineAudioDevice(sampleRate: 48000), maxVoices: 8)
        session.audioProvider = { audio }
        session.world.spawn(Transform(), AudioEmitter(clip: AssetReference(id).description, loop: true))
        session.play()
        var started = false
        for _ in 0..<400 where !started {
            session.tick(dt: 1.0 / 60)
            started = audio.activeVoices.count == 1
            if !started { Thread.sleep(forTimeInterval: 0.005) }
        }
        #expect(started)
        session.stop()
        _ = audio.render(frames: 2400)
        #expect(audio.activeVoices.isEmpty)
    }

    @Test func aMissingClipIsReportedOnceOnTheEngineLog() throws {
        let (session, folder, _) = try makeAudioProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let audio = try AudioSystem(device: OfflineAudioDevice(sampleRate: 48000), maxVoices: 8)
        session.audioProvider = { audio }
        let missing = AssetID(high: 1, low: 2)
        _ = session.world.spawn(Transform(), AudioEmitter(clip: AssetReference(missing).description, loop: true))
        let start = (EngineLog.recent().last?.sequence ?? -1) + 1
        session.play()
        session.tick(dt: 1.0 / 60)
        session.tick(dt: 1.0 / 60)
        let hits = EngineLog.recent().filter {
            $0.sequence >= start && $0.category == .audio && $0.message.contains("no audio asset \(missing)")
        }
        #expect(hits.count == 1)
        #expect(hits.first?.level == .warning)
        #expect(audio.activeVoices.isEmpty)
        session.stop()
    }

    @Test func aClipThatFailsToDecodeIsReportedOnTheEngineLog() throws {
        let (session, folder, _) = try makeAudioProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data("not a wav".utf8).write(to: folder.appendingPathComponent("Assets/Audio/bad.wav"))
        _ = session.assets?.refresh()
        let id = try #require(session.assets?.id(forPath: "Audio/bad.wav"))
        let audio = try AudioSystem(device: OfflineAudioDevice(sampleRate: 48000), maxVoices: 8)
        session.audioProvider = { audio }
        _ = session.world.spawn(Transform(), AudioEmitter(clip: AssetReference(id).description, loop: true))
        let start = (EngineLog.recent().last?.sequence ?? -1) + 1
        session.play()
        var reported = false
        for _ in 0..<400 where !reported {
            session.tick(dt: 1.0 / 60)
            reported = EngineLog.recent().contains {
                $0.sequence >= start && $0.category == .audio && $0.message.contains("could not load \(id)")
            }
            if !reported { Thread.sleep(forTimeInterval: 0.005) }
        }
        #expect(reported)
        #expect(audio.activeVoices.isEmpty)
        session.stop()
    }

    @Test func sceneOpenAcceptsProjectAndAssetsRelativePaths() throws {
        let (session, folder, _) = try makeAudioProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let scene = folder.appendingPathComponent("Assets/Scenes/Main.scene")
        #expect(session.save(as: scene.path))
        session.fileAccessRoots = [folder]
        session.newDocument()
        #expect(session.open(path: "Assets/Scenes/Main.scene"))
        session.newDocument()
        #expect(session.open(path: "Scenes/Main.scene"))
        #expect(session.document.url?.standardizedFileURL.path.hasSuffix("Assets/Scenes/Main.scene") == true)
        #expect(!session.open(path: "Scenes/Missing.scene"))
        #expect(!session.open(path: "../../etc/hosts"))
    }

    @Test func oldEmitterJSONLoadsWithoutClip() throws {
        let json = try JSONEncoder().encode(AudioEmitter(sound: "hum"))
        var object = try #require(JSONSerialization.jsonObject(with: json) as? [String: Any])
        object["clip"] = nil
        let decoded = try JSONDecoder().decode(AudioEmitter.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded == AudioEmitter(sound: "hum") && decoded.clip.isEmpty)
        let with = try JSONDecoder().decode(AudioEmitter.self, from: JSONEncoder().encode(AudioEmitter(clip: "asset:x")))
        #expect(with.clip == "asset:x")
    }
}
