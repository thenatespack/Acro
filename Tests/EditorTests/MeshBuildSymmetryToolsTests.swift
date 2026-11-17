import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuilders2D
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Mesh build `mirror` / `repeat` through the meshBuild.* tools, the Mesh Builder form and its view.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSymmetryToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct MeshBuildSymmetryToolsTests {
    @Test func toolsTakeMirrorAndRepeatAndListCopies() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let renderersBefore = session.world.count(of: MeshRenderer.self)
        let created = try call(session, "meshBuild.new", [
            "name": "Table", "place": true,
            "build": [
                "parts": [
                    ["name": "Top", "size": [1.2, 0.08, 0.8], "position": [0, 0.75, 0]],
                    ["name": "Front Left Leg", "parent": "Top", "size": [0.06, 0.71, 0.06], "position": [-0.55, -0.395, 0.35],
                     "mirror": ["x", "z"]],
                    ["name": "Bolt", "parent": "Top", "shape": "cylinder", "size": [0.03, 0.02, 0.03], "position": [0, 0.05, 0],
                     "repeat": ["count": 6, "radial": ["radius": 0.2]]],
                ],
                "animations": [["name": "Wobble", "tracks": [
                    ["part": "Back Right Leg", "property": "rotation", "keys": [["time": 0, "value": [0, 0, 0]], ["time": 1, "value": [5, 0, 0]]]],
                ]]],
            ],
        ])
        #expect(created["parts"] as? [String] == ["Top", "Front Left Leg", "Bolt"], "the file's parts")
        #expect(created["copies"] as? [String] == ["Front Right Leg", "Back Left Leg", "Back Right Leg",
                                                    "Bolt 2", "Bolt 3", "Bolt 4", "Bolt 5", "Bolt 6"])
        #expect((created["warnings"] as? [String])?.isEmpty == true, "a track may name a copy: \(created["warnings"] ?? "")")
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.world.count(of: MeshRenderer.self) == renderersBefore + 1 + 4 + 6, "the placed model draws every copy")

        // The file keeps the short form; get returns it as written.
        let got = try call(session, "meshBuild.get", ["asset": id.description])
        let parts = try #require((got["build"] as? [String: Any])?["parts"] as? [[String: Any]])
        #expect(parts.count == 3 && parts[1]["mirror"] as? [String] == ["x", "z"])
        #expect((parts[2]["repeat"] as? [String: Any])?["count"] as? Int == 6)

        // updateParts sets mirror / repeat like any field; a clash is a warning.
        let edited = try call(session, "meshBuild.edit", [
            "asset": id.description,
            "addParts": [["name": "Right Drawer", "position": [0.3, 0.6, 0.4]]],
            "updateParts": ["Bolt": ["repeat": NSNull()], "Right Drawer": ["mirror": "x"]],
        ])
        #expect(edited["copies"] as? [String] == ["Front Right Leg", "Back Left Leg", "Back Right Leg", "Left Drawer"])
        let editedWarnings = try call(session, "meshBuild.edit", ["asset": id.description, "addParts": [["name": "Left Drawer"]]])
        #expect(editedWarnings["parts"] as? [String] == ["Top", "Front Left Leg", "Bolt", "Right Drawer", "Left Drawer 2"],
                "a new part's name skips the copies' names")
        let clash = try call(session, "meshBuild.edit", ["asset": id.description,
                                                         "updateParts": ["Left Drawer 2": ["name": "Left Drawer"]]])
        #expect((clash["warnings"] as? [String])?.contains { $0.contains("makes a copy named 'Left Drawer'") } == true)
        #expect(session.performUndo())
    }

    @Test func checksSeeTheExpandedParts() throws {
        let build = MeshBuild(parts: [MeshBuildPart(name: "Left Wing", mirror: [.x]),
                                      MeshBuildPart(name: "Flap", parent: "Right Wing")],
                              animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "Right Wing", kind: .swing)])])
        #expect(MeshBuildCheck.parts(of: build).map(\.name) == ["Left Wing", "Flap", "Right Wing"])
        let session = makeSession()
        #expect(MeshBuildCheck.problems(build, in: session).isEmpty, "a part may hang from a copy and tracks may name one")
        #expect(EditorMeshBuildCommands.formatDoc.contains(EditorMeshBuildCommands.symmetryDoc))
        #expect(MeshBuildNewCommand.doc.contains("mirror") && MeshBuildNewCommand.doc.contains("repeat"))
    }

    @Test func formSetsMirrorAndRepeat() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Bench",
                                                           build: MeshBuild(parts: [MeshBuildPart(name: "Leg", position: Vec3(-0.5, 0.25, 0))])))
        let view = try #require(MeshBuilderView(session: session, asset: id))
        let mirrorX = try #require(view.view.descendant(named: "meshBuildMirror.x") as? Checkbox)
        #expect(!mirrorX.isOn)
        mirrorX.onChange?(true)
        view.refresh()
        #expect(session.assets?.meshBuild(of: id)?.parts[0].mirror == [.x])

        let count = try #require(view.view.descendant(named: "meshBuildRepeatCount") as? NumberField)
        count.onEditEnded?(1, 3)
        view.refresh()
        let repetition = try #require(session.assets?.meshBuild(of: id)?.parts[0].repetition)
        #expect(repetition.count == 3 && repetition.offset.x > 0, "a row beside the part to start with")

        let mode = try #require(view.view.descendant(named: "meshBuildRepeatMode") as? Dropdown)
        mode.onChange?(2)
        view.refresh()
        #expect(session.assets?.meshBuild(of: id)?.parts[0].repetition?.radial?.radius == 0.5)
        #expect(view.view.descendant(named: "meshBuildRepeatRadius") != nil && view.view.descendant(named: "meshBuildRepeatAxis") != nil)

        let again = try #require(view.view.descendant(named: "meshBuildRepeatCount") as? NumberField)
        again.onEditEnded?(3, 1)
        view.refresh()
        #expect(session.assets?.meshBuild(of: id)?.parts[0].repetition == nil, "count 1 removes the repeat")
        #expect(view.view.descendant(named: "meshBuildRepeatMode") == nil)
    }

    @Test func clickingACopySelectsItsSource() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let build = MeshBuild(parts: [MeshBuildPart(name: "Body"),
                                      MeshBuildPart(name: "Left Ear", parent: "Body", position: Vec3(-0.4, 0.6, 0), mirror: [.x])])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Bunny", build: build))
        let workspace = MeshBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.copySources == ["Right Ear": "Left Ear"])

        func entity(_ name: String) -> Entity? {
            var found: Entity?
            workspace.world.query(Name.self) { entity, n in if n.value == name { found = entity } }
            return found
        }
        let rightEar = try #require(entity("Right Ear"), "copies show in the view")
        let leftEar = try #require(entity("Left Ear"))
        workspace.selection.set([workspace.world.ensureID(of: rightEar)].compactMap { $0 })
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.builder?.selectedPart == "Left Ear")
        #expect(workspace.selection.primaryEntity(in: workspace.world) == leftEar, "the gizmo edits the source")
    }
}
