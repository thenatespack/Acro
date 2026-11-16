import Foundation
import Testing
@testable import EditorCore
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

// The path builder as an agent uses it (path.* tools, JSON in and out), including undo, and the
// Path Builder tab's form and control-point handles.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("PathToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct PathToolsTests {
    @Test func newEditSampleAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "terrain.new", ["name": "Hills", "folder": "Maps", "size": [96, 96], "resolution": 33, "seed": 3])

        let created = try call(session, "path.new", ["name": "Main Road", "folder": "Roads", "kind": "road", "terrain": "Maps/Hills.terrain",
                                                     "place": true])
        #expect(created["path"] as? String == "Roads/Main Road.path")
        #expect(created["profiles"] as? [String] == ["Road", "Center Line"])
        #expect(created["terrain"] as? String == "Maps/Hills.terrain")
        #expect((created["warnings"] as? [String])?.isEmpty == true, "\(created["warnings"] ?? "")")
        #expect((created["entities"] as? [String])?.count == 1)
        #expect((created["length"] as? Double ?? 0) > 40)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isPathBuildFile(id))
        #expect(session.world.count(of: Collider.self) == 1, "the road bed has a collider")
        let before = try #require(session.assets?.pathBuild(of: id))

        // The road sits on the terrain.
        let terrainID = try #require(session.assets?.id(forPath: "Maps/Hills.terrain"))
        let terrain = try #require(session.assets?.terrain(of: terrainID))
        let sampled = try call(session, "path.sample", ["path": "Roads/Main Road.path", "count": 5])
        let points = try #require(sampled["points"] as? [[String: Any]])
        #expect(points.count == 5)
        for point in points {
            let p = try #require(point["position"] as? [Double])
            let ground = Double(terrain.heightAt(x: Float(p[0]), z: Float(p[2])))
            #expect(abs(p[1] - ground - 0.05) < 0.01, "on the ground at \(p)")
        }

        let edited = try call(session, "path.edit", [
            "path": "Roads/Main Road.path", "addPoints": [[30, 0, 10]], "updatePoints": [["index": 0, "bank": 5]],
            "profile": ["width": 8, "color": [0.3, 0.3, 0.3]],
            "addPieces": [["name": "Posts", "shape": "cylinder", "size": [0.1, 1, 0.1], "spacing": 10, "offset": [4.5, 0.5, 0], "mirror": true]],
        ])
        #expect(edited["points"] as? Int == 5)
        #expect(edited["pieces"] as? [String] == ["Posts"])
        #expect(((edited["pieceCounts"] as? [Int])?.first ?? 0) >= 10)
        let build = try #require(session.assets?.pathBuild(of: id))
        #expect(build.profiles[0].width == 8 && build.profiles[0].height == 0.3, "profile merges fields")
        #expect(build.points[0].bank == 5 && build.points.last?.position == Vec3(30, 0, 10))

        #expect(throws: (any Error).self) { try call(session, "path.edit", ["path": "Roads/Main Road.path", "removePoints": [99]]) }
        #expect(throws: (any Error).self) { try call(session, "path.edit", ["path": "Roads/Main Road.path", "updateProfiles": ["Nope": ["width": 1]]]) }

        let rail = try call(session, "path.edit", ["path": "Roads/Main Road.path", "kind": "rail", "terrain": ["asset": ""]])
        #expect(rail["profiles"] as? [String] == ["Ballast", "Left Rail", "Right Rail"])
        #expect(rail["pieces"] as? [String] == ["Sleepers"])
        #expect(rail["terrain"] == nil || rail["terrain"] is NSNull, "following turned off")

        let get = try call(session, "path.get", ["path": "Roads/Main Road.path"])
        #expect(((get["build"] as? [String: Any])?["points"] as? [Any])?.count == 5)

        _ = session.performUndo()  // the rail preset
        _ = session.performUndo()  // the edit
        #expect(session.assets?.pathBuild(of: id) == before)
    }

    @Test func setReplacesAndReportsProblems() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "path.new", ["name": "P", "kind": "fence"])
        let result = try call(session, "path.set", ["path": "P.path", "build": [
            "points": [[0, 0, 0]], "terrain": ["asset": "Maps/None.terrain"],
            "pieces": [["name": "Lamp", "asset": "Models/missing.meshbuild"]],
        ]])
        let warnings = try #require(result["warnings"] as? [String])
        #expect(warnings.contains { $0.contains("at least 2 points") })
        #expect(warnings.contains { $0.contains("no terrain file") })
        #expect(warnings.contains { $0.contains("Lamp") })
        #expect(PathOpenCommand.id == "path.open" && EditorPathCommands.all.count == 6)
    }
}

@MainActor
@Suite struct PathBuilderViewTests {
    @Test func formEditsAndHandleMovesAreOneUndoStepEach() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createPathBuildAsset(in: "", name: "P", build: .preset(.wall)))
        let workspace = PathBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        let view = try #require(workspace.builder)
        workspace.update(input: nil, dt: 0)
        #expect(workspace.handles.count == 4)

        // Picking a point in the form selects its handle.
        view.selectPoint(2)
        workspace.update(input: nil, dt: 0)
        #expect(workspace.selection.primaryEntity(in: workspace.world) == workspace.handles[2])

        // A gizmo drag ends as a move of the selected point: one undo step.
        view.movePoints([2: Vec3(7, 0, 12)])
        workspace.update(input: nil, dt: 0)
        #expect(view.build.points[2].position == Vec3(7, 0, 12))
        #expect(workspace.world.get(Transform.self, for: workspace.handles[2])?.position == Vec3(7, 0, 12))

        view.addPoint()
        view.refresh()
        #expect(view.build.points.count == 5 && view.selectedPoint == 4)
        view.insertPoint()
        view.refresh()
        #expect(view.build.points.count == 6 && view.selectedPoint == 4)
        view.deletePoint()
        view.refresh()
        #expect(view.build.points.count == 5)

        view.applyKind(.fence)
        view.refresh()
        #expect(view.build.kind == .fence && view.build.pieces.map(\.name) == ["Posts"])
        view.addProfile()
        view.refresh()
        #expect(view.build.profiles.count == 3 && view.selectedProfile == 2)
        view.addPiece()
        view.refresh()
        #expect(view.build.pieces.count == 2)

        #expect(session.performUndo())  // add piece
        #expect(session.performUndo())  // add profile
        #expect(session.performUndo())  // fence
        view.reload()
        #expect(view.build.kind == .wall)
        #expect(session.performUndo())  // delete
        #expect(session.performUndo())  // insert
        #expect(session.performUndo())  // add
        #expect(session.performUndo())  // move
        view.reload()
        #expect(view.build == PathBuild.preset(.wall))
    }
}
