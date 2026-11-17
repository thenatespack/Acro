import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuilders2D
@testable import EditorBuildersAnimation
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
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// The tilemap builder as an agent uses it (tilemap.* tools, JSON in and out), including undo,
// and the Tilemap Builder tab's strokes and forms.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TilemapToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct TilemapToolsTests {
    @Test func newPaintFillEraseAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "tilemap.new", ["name": "Level", "folder": "Levels", "size": [24, 12], "place": true])
        #expect(created["path"] as? String == "Levels/Level.tilemap")
        #expect(created["layers"] as? [String] == ["Background", "Ground", "Foreground"])
        #expect(created["tileCount"] as? Int == 32, "the starter tile set")
        #expect(created["terrains"] as? [String] == ["Dirt"])
        #expect((created["warnings"] as? [String])?.isEmpty == true, "\(created["warnings"] ?? "")")
        #expect(session.assets?.id(forPath: "Levels/Level tiles.png") != nil)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isTilemapFile(id))

        let ground = try call(session, "tilemap.fill", ["path": "Levels/Level.tilemap", "layer": "Ground", "rect": [0, 9, 23, 11],
                                                        "terrain": "Dirt"])
        #expect(ground["changed"] as? Int == 72)
        #expect(ground["colliders"] as? Int == 1, "one merged box")
        let platform = try call(session, "tilemap.paint", ["path": "Levels/Level.tilemap", "layer": "Ground", "tile": 18,
                                                           "cells": [[5, 5], [6, 5], [7, 5]]])
        #expect(platform["colliders"] as? Int == 2)
        try call(session, "tilemap.paint", ["path": "Levels/Level.tilemap", "layer": "Background", "tiles": [29, 30], "cells": [[1, 1], [2, 1]], "seed": 3])
        try call(session, "tilemap.fill", ["asset": "asset:\(id)", "layer": "Background", "at": [10, 2], "tile": 30])
        let map = try #require(session.assets?.tilemapContents(of: id))
        #expect(map.cell(layer: 1, x: 3, y: 9).tile == 2 | 4 | 8, "terrain top edge gets grass")
        #expect(map.cell(layer: 1, x: 3, y: 10).tile == 15)
        #expect(map.cell(layer: 0, x: 20, y: 6).tile == 30, "flood filled the background")

        // The placed copy follows: Collider2D shapes from the collision.
        #expect(session.world.count(of: Collider2D.self) == 2)

        let erased = try call(session, "tilemap.erase", ["path": "Levels/Level.tilemap", "layer": "Ground", "cells": [[3, 9]], "terrain": "Dirt"])
        #expect(erased["changed"] as? Int ?? 0 >= 3, "the cell and its re-tiled neighbors")
        #expect(session.assets?.tilemapContents(of: id)?.cell(layer: 1, x: 3, y: 10).tile == 2 | 4 | 8, "its north neighbor is gone")

        #expect(throws: (any Error).self) { try call(session, "tilemap.paint", ["path": "Levels/Level.tilemap", "layer": "Nope", "tile": 1, "cells": [[0, 0]]]) }
        #expect(throws: (any Error).self) { try call(session, "tilemap.paint", ["path": "Levels/Level.tilemap", "tile": 1, "tiles": [2], "cells": [[0, 0]]]) }
        #expect(throws: (any Error).self) { try call(session, "tilemap.fill", ["path": "Levels/Level.tilemap", "tile": 1]) }

        let get = try call(session, "tilemap.get", ["path": "Levels/Level.tilemap", "layer": "Ground", "rect": [4, 4, 8, 5]])
        let cells = try #require(get["cells"] as? [[Int]])
        #expect(cells == [[-1, -1, -1, -1, -1], [-1, 18, 18, 18, -1]])
        #expect((get["layers"] as? [[String: Any]])?.count == 3)

        for _ in 0..<5 { _ = session.performUndo() }   // erase, flood, random, platform, ground
        let undone = try #require(session.assets?.tilemapContents(of: id))
        #expect(undone.paintedCounts == [0, 0, 0])
    }

    @Test func editManagesLayersTilesTerrainsAndObjects() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "tilemap.new", ["name": "M", "size": [10, 6], "layers": ["A", "B"]])
        try call(session, "tilemap.paint", ["path": "M.tilemap", "layer": "B", "tile": 7, "cells": [[0, 5], [1, 5]]])

        let edited = try call(session, "tilemap.edit", [
            "path": "M.tilemap", "size": [12, 8], "anchorBottom": true,
            "setTiles": [["index": 7, "collision": "full", "tags": ["solid"]], ["index": 21, "name": "spikes"]],
            "removeTiles": [28],
            "addLayers": [["name": "Front", "parallax": [1.2, 1], "collision": false]],
            "updateLayers": ["A": ["name": "Back", "opacity": 0.5, "collision": false]],
            "layerOrder": ["Front", "Back", "B"],
            "addTerrains": [["name": "Rock", "first": 0]],
            "addObjects": [["name": "Spawn", "type": "spawn", "position": [1.5, 2.5]]],
        ])
        #expect(edited["layers"] as? [String] == ["Front", "Back", "B"])
        #expect(edited["size"] as? [Int] == [12, 8])
        #expect(edited["objects"] as? [String] == ["Spawn"])
        #expect(edited["terrains"] as? [String] == ["Dirt", "Rock"])
        let id = try #require(session.assets?.id(forPath: "M.tilemap"))
        let m = try #require(session.assets?.tilemapContents(of: id))
        #expect(m.cell(layer: 2, x: 0, y: 7).tile == 7, "anchored to the bottom")
        #expect(m.tileset.tile(7)?.collision == .full && m.tileset.tile(28) == nil && m.tileset.tile(21)?.name == "spikes")
        #expect(m.layers[1].opacity == 0.5 && m.layers[1].data.count == 96, "renaming keeps the cells")

        try call(session, "tilemap.edit", ["path": "M.tilemap", "updateObjects": ["Spawn": ["position": [3, 3], "trigger": true, "size": [1, 1]]]])
        let prefab = try #require(session.assets?.prefab(AssetReference(id)))
        let objects = try #require(prefab.roots[0].children.first { $0.name == "Objects" })
        #expect(objects.children[0].transform.position == Vec3(3, 3, 0) && objects.children[0].collider2D?.isTrigger == true)

        #expect(throws: (any Error).self) { try call(session, "tilemap.edit", ["path": "M.tilemap", "layerOrder": ["Back"]]) }
        #expect(throws: (any Error).self) { try call(session, "tilemap.edit", ["path": "M.tilemap", "removeLayers": ["Nope"]]) }

        let set = try call(session, "tilemap.set", ["path": "M.tilemap", "tilemap": ["size": [4, 4], "tileset": ["source": "M tiles.png"],
                                                                                    "layers": [["name": "Only", "cells": [[0, 1, 2, 3]]]]]])
        #expect(set["size"] as? [Int] == [4, 4] && set["painted"] as? [Int] == [4])
        #expect((set["warnings"] as? [String])?.isEmpty == true, "\(set["warnings"] ?? "")")
        let bad = try call(session, "tilemap.edit", ["path": "M.tilemap", "tilesetSource": "Missing.png"])
        #expect((bad["warnings"] as? [String])?.contains { $0.contains("Missing.png") } == true)
    }

    @Test func workspaceStrokesAreOneUndoStepEach() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "tilemap.new", ["name": "W", "size": [16, 10]])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let workspace = TilemapWorkspace(session: session)
        #expect(workspace.open(id))
        #expect(workspace.map?.cols == 16 && workspace.layout?.count == 32)
        #expect(workspace.selectedLayer == 1, "the colliding layer")

        // A pencil drag from (0, 0) to (4, 0) leaves no gaps; written on release.
        workspace.selectTile(16)
        workspace.tool = .pencil
        workspace.beginStroke(x: 0, y: 0)
        workspace.continueStroke(x: 4, y: 0)
        #expect(!workspace.hasPendingEdit, "nothing written mid-stroke")
        workspace.endStroke()
        #expect(workspace.hasPendingEdit)
        workspace.update()
        let painted = try #require(session.assets?.tilemapContents(of: id))
        #expect((0...4).allSatisfy { painted.cell(layer: 1, x: $0, y: 0).tile == 16 })

        workspace.tool = .rectangle
        workspace.flipX = true
        workspace.beginStroke(x: 2, y: 3)
        workspace.continueStroke(x: 5, y: 4)
        #expect(workspace.rectPreview != nil)
        workspace.endStroke()
        workspace.update()
        #expect(workspace.map?.cell(layer: 1, x: 5, y: 4) == TileCell(tile: 16, flipX: true))

        workspace.tool = .terrain
        workspace.beginStroke(x: 0, y: 8)
        workspace.continueStroke(x: 15, y: 8)
        workspace.endStroke()
        workspace.update()
        #expect(workspace.map?.cell(layer: 1, x: 7, y: 8).tile == 2 | 8, "a one-row strip: east and west")

        workspace.tool = .object
        workspace.beginStroke(x: 1, y: 7)
        workspace.endStroke()
        workspace.update()
        #expect(workspace.map?.objects.count == 1 && workspace.selectedObject == 0)
        // Dragging the object moves it (one step).
        workspace.beginStroke(x: 1, y: 7)
        workspace.continueStroke(x: 3, y: 7)
        workspace.endStroke()
        workspace.update()
        #expect(workspace.map?.objects[0].position == workspace.map?.cellCenter(x: 3, y: 7))

        workspace.pick(x: 0, y: 0)
        #expect(workspace.brushTile == 16 && workspace.tool == .pencil)

        // Sidebar edits.
        let builder = try #require(workspace.builder)
        builder.addLayer()
        workspace.update()
        #expect(workspace.map?.layers.count == 4 && workspace.selectedLayer == 3)
        builder.moveLayer(by: -1)
        workspace.update()
        #expect(workspace.map?.layers[2].name == "Layer" && workspace.selectedLayer == 2)

        // Undo walks back one step at a time and the workspace follows the file.
        #expect(session.performUndo())   // reorder
        #expect(session.performUndo())   // add layer
        #expect(session.performUndo())   // move object
        #expect(session.performUndo())   // add object
        workspace.update()
        #expect(workspace.map?.objects.isEmpty == true && workspace.map?.layers.count == 3)
        #expect(session.performUndo())   // terrain
        #expect(session.performUndo())   // rectangle
        #expect(session.performUndo())   // pencil
        workspace.update()
        #expect(workspace.map?.paintedCounts == [0, 0, 0])
    }

    @Test func canvasKeyboardShortcutsPickToolsAndTurnTheBrush() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "tilemap.new", ["name": "K", "size": [8, 6]])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let workspace = TilemapWorkspace(session: session)
        #expect(workspace.open(id))
        func press(_ key: Key, _ modifiers: KeyModifiers = []) -> Bool {
            workspace.canvas.handleEvent(.key(KeyEvent(key: key, modifiers: modifiers)))
        }

        for tool in TilemapTool.allCases {
            #expect(press(tool.shortcut) && workspace.tool == tool, "\(tool)")
        }
        #expect(Set(TilemapTool.allCases.map(\.shortcut)).count == TilemapTool.allCases.count, "one key per tool")
        #expect(!TilemapTool.allCases.contains { $0.shortcut == .f }, "F frames the selection editor-wide")
        #expect(press(.x) && workspace.flipX && press(.y) && workspace.flipY)
        #expect(press(.z) && workspace.rotation == 1 && press(.z, .shift) && workspace.rotation == 0)
        #expect(press(.g, .shift) && !workspace.canvas.showsGrid)
        workspace.selectTile(0)
        #expect(press(.rightBracket) && workspace.brushTile == 1)
        #expect(press(.leftBracket) && press(.leftBracket) && workspace.brushTile == 31, "wraps around the tile set")
        // Editor shortcuts (undo, save) pass through.
        #expect(!press(.z, .command) && !press(.s, .control) && workspace.rotation == 0)
        #expect(!press(.k))
    }
}
