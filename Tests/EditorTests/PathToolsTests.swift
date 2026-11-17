import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersWorld
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineMeshBuild
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
        #expect(PathOpenCommand.id == "path.open" && EditorPathCommands.all.count == 7)
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

    @Test func clickingTheGroundAddsAPointAndTheCurveInsertsOne() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createPathBuildAsset(in: "", name: "P", build: .preset(.wall)))
        let workspace = PathBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        let view = try #require(workspace.builder)
        workspace.update(input: nil, dt: 0)

        let camera = EditorCamera(pivot: Vec3(0, 0, 0), yaw: 0, pitch: 1.2, distance: 70)
        let size = Vec2(400, 300)
        let context = ViewportToolContext(world: workspace.world, selection: workspace.selection, undo: UndoStack(world: workspace.world),
                                          view: camera.sceneView(aspect: size.x / size.y, clearColor: .zero),
                                          viewportRect: UIRect(x: 0, y: 0, width: size.x, height: size.y),
                                          pixelScale: 1, toolMode: .move, isPlaying: false, meshBounds: { _ in nil })
        let tool = workspace.pointTool
        func click(_ world: Vec3, _ modifiers: KeyModifiers = []) throws -> Bool {
            let at = try #require(context.project(world))
            return tool.handlePointer(ViewportPointerEvent(position: at, viewportSize: size, phase: .pressed, button: .left, modifiers: modifiers),
                                      context: context)
        }

        // Off unless toggled on or Ctrl is held.
        #expect(try !click(Vec3(0, 0, 20)))
        #expect(view.build.points.count == 4)

        // On the curve (the wall is straight between points): a point inserted there.
        #expect(try click(Vec3(-13.5, 0, -3), .control))
        view.refresh()
        #expect(view.build.points.count == 5 && view.selectedPoint == 1)
        #expect(length(view.build.points[1].position - Vec3(-13.5, 0, -3)) < 0.5)

        // On the ground: a point at the end, where the click hit the ground plane.
        workspace.update(input: nil, dt: 0)
        tool.isOn = true
        #expect(try click(Vec3(0, 0, 20)))
        view.refresh()
        #expect(view.build.points.count == 6 && view.selectedPoint == 5)
        #expect(length(view.build.points[5].position - Vec3(0, 0, 20)) < 0.05)

        // With the first point selected, a new point goes before it.
        view.selectPoint(0)
        workspace.update(input: nil, dt: 0)
        #expect(try click(Vec3(-30, 0, 10)))
        view.refresh()
        #expect(view.build.points.count == 7 && view.selectedPoint == 0)
        #expect(length(view.build.points[0].position - Vec3(-30, 0, 10)) < 0.05)

        // A click on a handle is left to the gizmo.
        workspace.update(input: nil, dt: 0)
        #expect(try !click(view.build.points[3].position))

        #expect(session.performUndo() && session.performUndo() && session.performUndo())
        view.reload()
        #expect(view.build == PathBuild.preset(.wall))
    }

    @Test func flatteningTheTerrainIsOneUndoStepAndThePathFollowsIt() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        var ground = Terrain(size: Vec2(64, 64), resolution: 65, heightRange: 20, chunkCells: 16)
        ground.normalizeData()
        for z in 0..<ground.res { for x in 0..<ground.res { ground.heightData[z * 65 + x] = UInt16((5 + Float(x % 3)) / 20 * 65535) } }
        let terrain = try assets.createTerrain(ground, at: "Maps/rough.terrain")
        var build = PathBuild.preset(.road)
        build.terrain = PathTerrain(asset: "Maps/rough.terrain", height: 0.05)
        let id = try #require(session.createPathBuildAsset(in: "", name: "Road", build: build))
        let before = try #require(assets.terrain(of: terrain))

        let result = try call(session, "path.flattenTerrain", ["path": "Road.path", "shoulder": 2])
        #expect(result["terrain"] as? String == "Maps/rough.terrain")
        #expect((result["changedSamples"] as? Int ?? 0) > 50)
        let after = try #require(assets.terrain(of: terrain))
        #expect(after.heightData != before.heightData)
        // The road now sits on level ground: its samples barely rise and fall.
        let samples = try #require(assets.pathSamples(of: id)).samples
        let heights = samples.map(\.position.y)
        #expect((heights.max() ?? 0) - (heights.min() ?? 0) < 1.2)

        #expect(session.performUndo())
        #expect(assets.terrain(of: terrain)?.heightData == before.heightData)
        #expect(session.performRedo())
        #expect(assets.terrain(of: terrain)?.heightData == after.heightData)

        // The tab's Shape Terrain button does the same with its form's settings.
        #expect(session.performUndo())
        let workspace = PathBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        let view = try #require(workspace.builder)
        view.shaping = PathTerrainShaping(mode: .carve, width: 6, shoulder: 1, depth: 1, smoothing: 0)
        view.shapeTerrain()
        #expect(view.lastShape?.hasPrefix("Moved") == true)
        let carved = try #require(assets.terrain(of: terrain))
        #expect(zip(carved.heightData, before.heightData).allSatisfy { $0 <= $1 })

        // A path that follows no terrain needs one named.
        build.terrain = PathTerrain()
        _ = try #require(session.createPathBuildAsset(in: "", name: "Loose", build: build))
        #expect(throws: (any Error).self) { try call(session, "path.flattenTerrain", ["path": "Loose.path"]) }
        let named = try call(session, "path.flattenTerrain", ["path": "Loose.path", "terrain": "Maps/rough.terrain", "smoothing": 0])
        #expect((named["changedSamples"] as? Int ?? 0) > 0)
    }

    @Test func junctionsAreEditedByToolAndTab() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        _ = try #require(session.createPathBuildAsset(in: "", name: "Main", build: .preset(.road, points: [PathPoint(Vec3(-30, 0, 0)), PathPoint(Vec3(30, 0, 0))])))
        let side = try #require(session.createPathBuildAsset(in: "", name: "Side", build: .preset(.road, points: [PathPoint(Vec3(0, 0, 30)), PathPoint(Vec3(0, 0, 0))])))

        let result = try call(session, "path.edit", ["path": "Side.path", "addJunctions": [["path": "Main.path", "radius": 2]]])
        #expect((result["warnings"] as? [String])?.isEmpty == true)
        #expect(assets.pathBuild(of: side)?.junctions == [PathJunction(path: "Main.path", radius: 2)])
        let got = try call(session, "path.get", ["path": "Side.path"])
        #expect(((got["build"] as? [String: Any])?["junctions"] as? [[String: Any]])?.first?["path"] as? String == "Main.path")
        let missing = try call(session, "path.edit", ["path": "Side.path", "addJunctions": [["path": "Nope.path"]]])
        #expect((missing["warnings"] as? [String])?.contains { $0.contains("junction: no path 'Nope.path'") } == true)
        try call(session, "path.edit", ["path": "Side.path", "removeJunctions": ["Main.path", "Nope.path"]])
        #expect(assets.pathBuild(of: side)?.junctions.isEmpty == true)
        #expect(throws: (any Error).self) { try call(session, "path.edit", ["path": "Side.path", "removeJunctions": ["Main.path"]]) }

        // The tab joins the other path and removes the junction, one undo step each.
        let workspace = PathBuilderWorkspace(session: session)
        #expect(workspace.open(side))
        let view = try #require(workspace.builder)
        view.addJunction()
        view.refresh()
        #expect(view.build.junctions.map(\.path) == ["Main.path"])
        workspace.update(input: nil, dt: 0)
        #expect(workspace.joinedRoots.count == 1, "the joined road is shown too")
        view.removeJunction(0)
        view.refresh()
        #expect(view.build.junctions.isEmpty)
        #expect(session.performUndo())
        view.reload()
        #expect(view.build.junctions.count == 1)
    }
}
