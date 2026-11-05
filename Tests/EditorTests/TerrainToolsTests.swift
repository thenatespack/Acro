import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The terrain builder as an agent uses it (terrain.* tools, JSON in and out), including undo.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TerrainToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct TerrainToolsTests {
    @Test func newSculptPaintScatterAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "meshBuild.new", ["name": "Tree", "folder": "Models",
                                            "build": ["parts": [["name": "Trunk", "shape": "cylinder", "size": [0.3, 3, 0.3]]]]])

        let created = try call(session, "terrain.new", ["name": "Hills", "folder": "Maps", "size": [64, 64], "resolution": 33,
                                                        "seed": 9, "place": true])
        #expect(created["path"] as? String == "Maps/Hills.terrain")
        #expect(created["layers"] as? [String] == ["Grass", "Rock", "Dirt"])
        #expect(created["resolution"] as? Int == 33)
        #expect((created["entities"] as? [String])?.count == 1)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isTerrainFile(id))
        #expect(session.world.count(of: Collider.self) == 1, "one chunk, one collider")

        let before = try #require(session.assets?.terrain(of: id))
        let sculpted = try call(session, "terrain.sculpt", ["path": "Maps/Hills.terrain", "brush": "raise", "points": [[0, 0], [2, 0]],
                                                            "radius": 6, "strength": 4])
        #expect((sculpted["warnings"] as? [String])?.isEmpty == true)
        let after = try #require(session.assets?.terrain(of: id))
        #expect(after.heightAt(x: 0, z: 0) > before.heightAt(x: 0, z: 0) + 3)

        let painted = try call(session, "terrain.paint", ["path": "Maps/Hills.terrain", "layer": "Rock", "points": [[10, 10]], "radius": 5, "strength": 1,
                                                          "falloff": 0])
        #expect(painted["layers"] as? [String] == ["Grass", "Rock", "Dirt"])
        let painting = try #require(session.assets?.terrain(of: id))
        #expect(painting.weightAt(layer: 1, x: 10, z: 10) > 0.95 && painting.weightAt(layer: 1, x: -20, z: -20) == 0)
        #expect(throws: (any Error).self) { try call(session, "terrain.paint", ["path": "Maps/Hills.terrain", "layer": "Lava", "points": [[0, 0]]]) }
        #expect(throws: (any Error).self) { try call(session, "terrain.sculpt", ["path": "Maps/Hills.terrain", "brush": "raise", "points": []]) }

        let scattered = try call(session, "terrain.scatter", ["terrain": "asset:\(id)", "asset": "Models/Tree.meshbuild", "density": 10,
                                                              "rules": ["maxSlope": 90, "layer": "Grass", "maxCount": 50]])
        #expect(scattered["scatter"] as? [String] == ["Tree"])
        let counts = try #require(scattered["scatterCounts"] as? [Int])
        #expect(counts.count == 1 && counts[0] > 5 && counts[0] <= 50, "\(counts)")
        #expect((scattered["warnings"] as? [String])?.isEmpty == true)
        let prefab = try #require(session.assets?.prefab(AssetReference(id)))
        #expect(prefab.roots[0].children.last?.name == "Scatter")
        let missing = try call(session, "terrain.scatter", ["path": "Maps/Hills.terrain", "asset": "Models/Nope.meshbuild", "name": "Bad"])
        #expect((missing["warnings"] as? [String])?.contains { $0.contains("no asset") } == true)

        _ = session.performUndo()  // the bad rule
        _ = session.performUndo()  // the tree rule
        #expect(session.assets?.terrain(of: id)?.scatter.isEmpty == true)
        _ = session.performUndo()  // paint
        #expect(session.assets?.terrain(of: id)?.weightAt(layer: 1, x: 10, z: 10) == 0)
        _ = session.performUndo()  // sculpt
        #expect(session.assets?.terrain(of: id) == before)
    }

    @Test func editResamplesAndManagesLayersAndRules() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "terrain.new", ["name": "T", "size": [32, 32], "resolution": 17])
        let id = try #require(session.assets?.id(forPath: "T.terrain"))
        let original = try #require(session.assets?.terrain(of: id))

        let edited = try call(session, "terrain.edit", [
            "path": "T.terrain", "resolution": 33, "heightRange": 128, "removeLayers": ["Dirt"],
            "addLayers": [["name": "Sand", "color": [0.9, 0.8, 0.5]]], "updateLayers": ["Rock": ["name": "Stone", "tileSize": 8]],
            "addScatter": [["name": "Rocks", "asset": "asset:\(id)#mesh/chunk 0_0", "layer": "Stone"]],
        ])
        #expect(edited["layers"] as? [String] == ["Grass", "Stone", "Sand"])
        #expect(edited["resolution"] as? Int == 33)
        let t = try #require(session.assets?.terrain(of: id))
        #expect(t.heightData.count == 33 * 33 && t.splatData.count == 3 && t.splatData.allSatisfy { $0.count == 33 * 33 })
        #expect(t.layers[1].tileSize == 8)
        for p in [Vec2(0, 0), Vec2(5, -7), Vec2(-12, 9)] {
            #expect(abs(t.heightAt(x: p.x, z: p.y) - original.heightAt(x: p.x, z: p.y)) < 0.4, "resampling keeps the ground")
        }
        #expect(t.weightAt(layer: 0, x: 3, z: 3) == 1, "grass stays everywhere")

        #expect(throws: (any Error).self) { try call(session, "terrain.edit", ["path": "T.terrain", "removeLayers": ["Nope"]]) }
        let get = try call(session, "terrain.get", ["path": "T.terrain", "sampleHeights": 4])
        #expect((get["heights"] as? [[Double]])?.count == 4)
        #expect((get["layers"] as? [[String: Any]])?.count == 3)
        _ = session.performUndo()
        #expect(session.assets?.terrain(of: id) == original)
    }

    @Test func setReplacesAndSparseFileImports() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "terrain.new", ["name": "T", "resolution": 17])
        let result = try call(session, "terrain.set", ["path": "T.terrain", "terrain": ["size": [10, 10], "resolution": 9]])
        #expect(result["resolution"] as? Int == 9 && result["maxHeight"] as? Double == 0, "no heights: flat ground")
        #expect(result["chunks"] as? Int == 1)
        #expect(TerrainSculptCommand.id == "terrain.sculpt")
    }
}

@MainActor
@Suite struct TerrainBuilderViewTests {
    @Test func strokesLayersAndScatterRulesAreOneUndoStepEach() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createTerrainAsset(in: "", name: "T", terrain: .generated(size: Vec2(32, 32), resolution: 17)))
        let workspace = TerrainBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        let view = try #require(workspace.builder)
        let base = view.terrain

        workspace.brush.tool = .raise
        workspace.brush.radius = 5
        workspace.brush.strength = 1
        view.applyStroke([Vec2(0, 0), Vec2(2, 0)])
        #expect(view.hasPendingEdit)
        view.refresh()
        #expect(view.terrain.heightAt(x: 0, z: 0) > base.heightAt(x: 0, z: 0) + 1)

        workspace.brush.tool = .paint
        view.applyStroke([Vec2(8, 8)])
        view.refresh()
        #expect(view.terrain.weightAt(layer: 0, x: 8, z: 8) < 0.5 || view.terrain.splatData[0].count > 0)

        view.addLayer()
        view.refresh()
        #expect(view.terrain.layers.count == 4 && view.selectedLayer == 3)
        view.addScatter()
        view.refresh()
        #expect(view.terrain.scatter.count == 1 && view.selectedScatter == 0)
        view.removeScatter()
        view.refresh()
        #expect(view.terrain.scatter.isEmpty)

        #expect(session.performUndo())  // remove scatter
        view.reload()
        #expect(view.terrain.scatter.count == 1)
    }

    @Test func brushRaycastFindsTheGround() {
        var terrain = Terrain(size: Vec2(32, 32), resolution: 33)
        terrain.normalizeData()
        terrain.heightData = [UInt16](repeating: UInt16(0.25 * 65535), count: 33 * 33)   // 16 m high
        let down = ViewportRay(origin: Vec3(3, 50, -4), direction: Vec3(0, -1, 0))
        let hit = try? #require(TerrainBrushViewportTool.intersect(down, with: terrain))
        #expect(hit != nil && abs(hit!.y - 16) < 0.05 && abs(hit!.x - 3) < 0.01 && abs(hit!.z + 4) < 0.01)
        let slanted = ViewportRay(origin: Vec3(-10, 36, 0), direction: Vec3(1, -1, 0))
        let hit2 = TerrainBrushViewportTool.intersect(slanted, with: terrain)
        #expect(hit2 != nil && abs(hit2!.y - 16) < 0.1 && abs(hit2!.x - 10) < 0.2)
        #expect(TerrainBrushViewportTool.intersect(ViewportRay(origin: Vec3(100, 50, 0), direction: Vec3(0, -1, 0)), with: terrain) == nil)
    }
}
