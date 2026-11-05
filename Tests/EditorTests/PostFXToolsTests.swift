import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The post-fx tools as an agent uses them (postfx.* tools, JSON in and out), including undo,
// camera assignment and the workspace form's undo steps.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct PostFXToolsTests {
    @Test func newEditAssignAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "postfx.new", ["name": "Noir", "folder": "Looks", "preset": "noir", "settings": ["vignette": 0.9]])
        #expect(created["path"] as? String == "Looks/Noir.postfx")
        let settings = try #require(created["settings"] as? [String: Any])
        #expect(settings["saturation"] as? Double == 0)
        #expect(settings["vignette"] as? Double == 0.9)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isPostFXFile(id))

        let edited = try call(session, "postfx.edit", ["path": "Looks/Noir.postfx", "changes": ["exposure": 0.5, "gain": [1, 1, 0.5]]])
        #expect((edited["settings"] as? [String: Any])?["exposure"] as? Double == 0.5)
        #expect(session.assets?.postFX(of: id)?.exposure == 0.5)
        #expect(session.assets?.postFX(of: id)?.saturation == 0, "other keys kept")

        #expect(throws: (any Error).self) { try call(session, "postfx.edit", ["path": "Looks/Noir.postfx", "changes": ["bogus": 1]]) }
        #expect(throws: (any Error).self) { try call(session, "postfx.new", ["preset": "nope"]) }

        let bad = try call(session, "postfx.edit", ["path": "Looks/Noir.postfx", "changes": ["bloomIntensity": 5]])
        #expect((bad["warnings"] as? [String])?.contains { $0.contains("bloomIntensity") } == true)

        try call(session, "postfx.set", ["path": "Looks/Noir.postfx", "preset": "warm"])
        #expect(session.assets?.postFX(of: id) == PostFXPreset.warm.settings)
        #expect(session.performUndo())
        #expect(session.assets?.postFX(of: id)?.bloomIntensity == 5, "undo restores the previous contents")

        let got = try call(session, "postfx.get", ["asset": AssetReference(id).description])
        #expect(got["path"] as? String == "Looks/Noir.postfx")

        // Assign to the active camera (the new scene has one).
        try call(session, "postfx.assign", ["path": "Looks/Noir.postfx"])
        let camera = try #require(RenderPrep.findCamera(in: session.world))
        #expect(camera.camera.postFX == AssetReference(id).description)
        #expect(PostFXResolver.profile(camera.camera.postFX, assets: session.assets) == session.assets?.postFX(of: id))
        try call(session, "postfx.assign", ["clear": true])
        #expect(RenderPrep.findCamera(in: session.world)?.camera.postFX == "")
    }

    @Test func workspaceFormEditsAreUndoSteps() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "postfx.new", [:])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let workspace = PostFXWorkspace(session: session)
        #expect(workspace.open(id))
        try call(session, "postfx.open", ["asset": AssetReference(id).description])
        workspace.setSplit(enabled: true, position: 0.3)
        #expect(workspace.splitEnabled && workspace.splitPosition == 0.3)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.profile == PostFXPreset.neutral.settings)
    }
}
