import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The mesh builder as an agent uses it (meshBuild.* tools, JSON in and out) and as a user does
// (the inspector's MeshBuilderView), including undo and placed copies following edits.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct MeshBuildToolsTests {
    @Test func newEditGetAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "meshBuild.new", [
            "name": "Lamp", "folder": "Models", "place": true, "position": [2, 0, 0],
            "build": ["parts": [
                ["name": "Pole", "shape": "cylinder", "size": [0.1, 2, 0.1], "position": [0, 1, 0]],
                ["name": "Shade", "shape": "cone", "parent": "Pole", "position": [0, 1, 0], "glow": [1, 0.8, 0.4]],
            ]],
        ])
        #expect(created["path"] as? String == "Models/Lamp.meshbuild")
        #expect(created["parts"] as? [String] == ["Pole", "Shade"])
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        #expect((created["entities"] as? [String])?.count == 1)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isMeshBuildFile(id))

        let renderersBefore = session.world.count(of: MeshRenderer.self)
        let edited = try call(session, "meshBuild.edit", [
            "path": "Models/Lamp.meshbuild",
            "addParts": [["name": "Pole", "shape": "box", "size": [0.6, 0.1, 0.6]]],
            "updateParts": ["Shade": ["name": "Hood", "color": [0, 0, 1]]],
            "addMotions": [["part": "Hood", "kind": "swing", "axis": "z"]],
        ])
        #expect(edited["parts"] as? [String] == ["Pole", "Hood", "Pole 2"], "a taken name gets a number")
        #expect(edited["animations"] as? [String] == ["Idle"])
        #expect(session.world.count(of: MeshRenderer.self) == renderersBefore + 1, "the placed copy gained the new part")
        let build = try #require(session.assets?.meshBuild(of: id))
        #expect(build.parts[1].color == Vec3(0, 0, 1) && build.parts[1].parent == "Pole")
        #expect(build.animations[0].motions.first?.part == "Hood")

        let got = try call(session, "meshBuild.get", ["asset": id.description])
        #expect(((got["build"] as? [String: Any])?["parts"] as? [Any])?.count == 3)

        let warned = try call(session, "meshBuild.edit", ["asset": id.description,
                                                          "updateParts": ["Hood": ["texture": "Textures/missing.png"]]])
        #expect((warned["warnings"] as? [String])?.contains { $0.contains("missing.png") } == true)

        #expect(session.performUndo())
        #expect(session.assets?.meshBuild(of: id)?.parts[1].texture == "")
        #expect(throws: (any Error).self) { try call(session, "meshBuild.edit", ["asset": id.description, "removeParts": ["Nope"]]) }
        #expect(throws: (any Error).self) { try call(session, "meshBuild.get", ["path": "Missing.meshbuild"]) }
    }

    @Test func builderViewAddsEditsAndAnimatesParts() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Robot"))

        let view = try #require(MeshBuilderView(session: session, asset: id))
        #expect(view.selectedPart == "Base")
        view.addPart(.sphere)
        #expect(view.hasPendingEdit)
        view.refresh()
        #expect(view.build.parts.map(\.name) == ["Base", "Sphere"])
        #expect(view.selectedPart == "Sphere")
        let sphere = view.build.parts[1]
        #expect(sphere.position.y == 1.5, "stacked on the selected part")

        view.addMotion(MeshBuildMotion(part: "Sphere", kind: .spin))
        view.refresh()
        #expect(session.assets?.meshBuild(of: id)?.animations.first?.motions.count == 1)

        view.duplicateSelected()
        view.refresh()
        #expect(view.build.parts.map(\.name) == ["Base", "Sphere", "Sphere 2"])
        view.deleteSelected()
        view.refresh()
        #expect(view.build.parts.map(\.name) == ["Base", "Sphere"])

        // Undo goes back through the view's edits, one step each.
        #expect(session.performUndo())
        view.reload()
        #expect(view.build.parts.count == 3)
    }
}

@MainActor
@Suite struct MeshBuilderWorkspaceTests {
    @Test func openSyncsSelectionAndPreviewsAnimation() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let build = MeshBuild(parts: [MeshBuildPart(name: "Base"), MeshBuildPart(name: "Fan", parent: "Base", position: Vec3(0, 1, 0))],
                              animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "Fan", kind: .spin)])])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Fan", build: build))

        let workspace = MeshBuilderWorkspace(session: session)
        var opened: AssetID?
        session.onOpenMeshBuild = { opened = $0; workspace.open($0) }
        try call(session, "meshBuild.open", ["asset": id.description])
        #expect(opened == id && session.openMeshBuild == id && workspace.asset == id)

        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.selection.ids.count == 1, "the form's first part is selected in the view")
        workspace.builder?.selectPart("Fan")
        workspace.update(input: nil, dt: 1.0 / 60)
        let fan = try #require(workspace.selection.primaryEntity(in: workspace.world))
        #expect(workspace.world.get(Name.self, for: fan)?.value == "Fan")

        let rest = try #require(workspace.world.get(Transform.self, for: fan)?.rotation)
        workspace.setPreviewingAnimation(true)
        for _ in 0..<30 { workspace.update(input: nil, dt: 1.0 / 60) }
        let spun = try #require(workspace.world.get(Transform.self, for: fan)?.rotation)
        #expect(abs(spun.vector.y - rest.vector.y) > 0.1, "the spin plays in the view")
        workspace.setPreviewingAnimation(false)

        // An edit made elsewhere (MCP) shows up in the view.
        try call(session, "meshBuild.edit", ["asset": id.description, "addParts": [["name": "Light", "shape": "sphere"]]])
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.builder?.build.parts.count == 3)
        workspace.close()
        #expect(workspace.asset == nil)
    }
}
