import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The sound builder as an agent uses it (sfx.* tools) and as a user does (SoundBuilderView), with undo.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct SoundBuildToolsTests {
    @Test func newEditPlayAndUndo() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SoundBuildToolsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "sfx.new", ["name": "Coin", "folder": "Sounds", "preset": "coin", "seed": 7])
        #expect(created["path"] as? String == "Sounds/Coin.sfx")
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isSoundBuildFile(id))
        #expect(session.assets?.soundBuild(of: id) == SoundBuild.preset(.coin, seed: 7))
        #expect((created["peaks"] as? [Double])?.count == EditorSoundBuildCommands.peakCount)

        let edited = try call(session, "sfx.edit", ["path": "Sounds/Coin.sfx", "changes": ["frequency": 660, "waveform": "saw"]])
        let build = try #require(session.assets?.soundBuild(of: id))
        #expect(build.frequency == 660 && build.waveform == .saw)
        #expect((edited["duration"] as? Double ?? 0) > 0.1)

        try call(session, "sfx.edit", ["path": "Sounds/Coin.sfx", "preset": "laser", "randomize": true, "seed": 5])
        #expect(session.assets?.soundBuild(of: id) == SoundBuild.preset(.laser, seed: 5))
        try call(session, "sfx.edit", ["path": "Sounds/Coin.sfx", "mutate": 0.2])
        #expect(session.assets?.soundBuild(of: id) != SoundBuild.preset(.laser, seed: 5))

        let got = try call(session, "sfx.get", ["path": "Sounds/Coin.sfx"])
        #expect((got["build"] as? [String: Any])?["waveform"] != nil)
        let played = try call(session, "sfx.play", ["path": "Sounds/Coin.sfx"])
        #expect(played["played"] as? Bool == false, "no audio device in tests")

        try call(session, "sfx.set", ["path": "Sounds/Coin.sfx", "build": ["waveform": "sine", "volume": 0]])
        #expect((try call(session, "sfx.get", ["path": "Sounds/Coin.sfx"])["warnings"] as? [String])?.contains { $0.contains("silent") } == true)
        #expect(session.performUndo())
        #expect(session.assets?.soundBuild(of: id)?.waveform != .sine)

        #expect(throws: (any Error).self) { try call(session, "sfx.edit", ["path": "Sounds/Coin.sfx", "randomize": true]) }
    }

    @Test func formEditsAreUndoable() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SoundBuildToolsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createSoundBuildAsset(in: "", name: "S"))
        let form = try #require(SoundBuilderView(session: session, asset: id))
        let original = form.build
        form.applyPreset(.hit)
        #expect(form.hasPendingEdit)
        form.refresh()
        #expect(session.assets?.soundBuild(of: id)?.waveform == SoundBuild.preset(.hit).waveform)
        #expect(session.assets?.soundBuild(of: id) != original)
        #expect(session.performUndo())
        #expect(session.assets?.soundBuild(of: id) == original)
    }
}
