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

// The grid map builder as an agent uses it (gridMap.* tools, JSON in and out), including undo,
// and the builder form's brush strokes.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("GridMapToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct GridMapToolsTests {
    @Test func newPaintFillEraseEditAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "gridMap.new", ["name": "Dungeon", "folder": "Levels", "place": true])
        #expect(created["path"] as? String == "Levels/Dungeon.gridmap")
        let pieces = try #require(created["pieces"] as? [String])
        #expect(pieces.contains("Wall") && pieces.contains("Floor") && pieces.contains("Wall Corner"))
        #expect((created["warnings"] as? [String])?.isEmpty == true, "\(created["warnings"] ?? "")")
        #expect(session.assets?.id(forPath: "Levels/Dungeon Pieces/Floor.meshbuild") != nil, "starter pieces are written")
        #expect((created["entities"] as? [String])?.count == 1)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isGridMapFile(id))

        let room = try call(session, "gridMap.fill", ["path": "Levels/Dungeon.gridmap", "piece": "Wall", "box": [[0, 0, 0], [4, 0, 4]], "hollow": true])
        #expect(room["changed"] as? Int == 16 && room["cells"] as? Int == 16)
        let floor = try call(session, "gridMap.paint", ["asset": "asset:\(id)", "piece": "Floor", "cells": [[2, 0, 2]], "brush": "fill"])
        #expect(floor["changed"] as? Int == 9)
        let line = try call(session, "gridMap.paint", ["path": "Levels/Dungeon.gridmap", "piece": "Crate", "cells": [[1, 0, 1], [3, 0, 1]],
                                                       "brush": "line", "rotation": 90])
        #expect(line["changed"] as? Int == 3 && line["floors"] as? [Int] == [0])
        let random = try call(session, "gridMap.paint", ["path": "Levels/Dungeon.gridmap", "pieces": ["Crate", "Pillar"],
                                                         "cells": [[0, 1, 0], [1, 1, 0], [2, 1, 0]], "seed": 4])
        #expect(random["changed"] as? Int == 3 && random["floors"] as? [Int] == [0, 1])
        #expect(throws: (any Error).self) { try call(session, "gridMap.paint", ["path": "Levels/Dungeon.gridmap", "piece": "Nope", "cells": [[0, 0, 0]]]) }
        #expect(throws: (any Error).self) { try call(session, "gridMap.paint", ["path": "Levels/Dungeon.gridmap", "piece": "Floor", "cells": [[20, 0, 20]], "brush": "fill"]) }

        // The import resolved the walls into corners and straights, one collider per chunk and floor.
        let prefab = try #require(session.assets?.prefab(AssetReference(id)))
        let names = prefab.roots[0].children[0].children.flatMap(\.children).map(\.name)
        #expect(names.filter { $0.hasPrefix("Wall ") }.count == 16)
        #expect(session.world.count(of: Collider.self) == 2, "the placed copy updated: floors 0 and 1")

        let got = try call(session, "gridMap.get", ["path": "Levels/Dungeon.gridmap", "floor": 0, "cellLimit": 5, "mapFloor": 0])
        #expect((got["cells"] as? [Any])?.count == 5 && got["truncated"] as? Bool == true)
        let rows = try #require(got["map"] as? [String])
        #expect(rows.count == 5 && rows[0] == "WWWWW" && rows[1] == "WCCCW" && rows[2] == "WFFFW", "\(rows)")

        let erased = try call(session, "gridMap.erase", ["path": "Levels/Dungeon.gridmap", "box": [[0, 1, 0], [9, 1, 9]]])
        #expect(erased["changed"] as? Int == 3 && erased["floors"] as? [Int] == [0])

        let edited = try call(session, "gridMap.edit", ["path": "Levels/Dungeon.gridmap", "updatePieces": ["Crate": ["name": "Box", "collider": "none"]],
                                                        "addPieces": [["asset": "Levels/Dungeon Pieces/Pillar.meshbuild"]]])
        let editedPieces = try #require(edited["pieces"] as? [String])
        #expect(editedPieces.contains("Box") && !editedPieces.contains("Crate") && editedPieces.last == "Pillar 2")
        let map = try #require(session.assets?.gridMap(of: id))
        #expect(map.cells.filter { $0.piece == "Box" }.count == 3 && map.piece(named: "Box")?.collider == GridPieceCollider.none)

        _ = session.performUndo()  // edit
        _ = session.performUndo()  // erase
        #expect(session.assets?.gridMap(of: id)?.floors == [0, 1])
        _ = session.performUndo()  // random
        _ = session.performUndo()  // line
        _ = session.performUndo()  // fill brush
        #expect(session.assets?.gridMap(of: id)?.cells.count == 16)
        _ = session.performUndo()  // the room
        #expect(session.assets?.gridMap(of: id)?.cells.isEmpty == true)

        let opened = try call(session, "gridMap.open", ["path": "Levels/Dungeon.gridmap", "floor": 2])
        #expect(opened["path"] as? String == "Levels/Dungeon.gridmap" && session.openGridMap == id && session.openGridMapFloor == 2)
    }

    @Test func libraryFromAssetsAndSet() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "meshBuild.new", ["name": "Block", "folder": "Models", "build": ["parts": [["name": "Cube", "shape": "box"]]]])

        let created = try call(session, "gridMap.new", ["name": "City", "cellSize": [4, 4, 4], "assets": ["Models/Block.meshbuild"],
                                                        "library": [["name": "Tower", "asset": "Models/Block.meshbuild", "footprint": [2, 2],
                                                                     "scale": [4, 8, 4]]]])
        #expect(created["pieces"] as? [String] == ["Tower", "Block"], "no starter pieces with a library")
        #expect(created["cellSize"] as? [Double] == [4, 4, 4])
        let set = try call(session, "gridMap.set", ["path": "City.gridmap", "map": [
            "pieces": [["name": "Block", "asset": "Models/Block.meshbuild"], ["name": "Gone", "asset": "Models/missing.meshbuild"]],
            "cells": [["at": [0, 0, 0], "piece": "Block"], ["at": [1, 0, 0], "piece": "Gone"], ["at": [2, 0, 0], "piece": "Ghost"]],
        ]])
        let warnings = try #require(set["warnings"] as? [String])
        #expect(warnings.contains { $0.contains("missing.meshbuild") }, "\(warnings)")
        #expect(warnings.contains { $0.contains("Ghost") })
        #expect(set["cellSize"] as? [Double] == [2, 3, 2], "omitted keys take their defaults")
    }

    @Test func builderStrokesAreUndoSteps() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "gridMap.new", ["name": "Keep"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        let workspace = GridMapWorkspace(session: session)
        #expect(workspace.open(id, floor: 0))
        let view = try #require(workspace.builder)
        workspace.brush.piece = "Wall"
        workspace.brush.tool = .rect
        view.applyStroke([GridCoord(0, 0, 0), GridCoord(3, 0, 2)], outline: true)
        #expect(view.hasPendingEdit)
        workspace.update(input: nil, dt: 0)
        #expect(session.assets?.gridMap(of: id)?.cells.count == 10)
        #expect(workspace.root != nil)

        workspace.brush.tool = .erase
        view.applyStroke([GridCoord(0, 0, 0), GridCoord(1, 0, 0)])
        workspace.update(input: nil, dt: 0)
        #expect(session.assets?.gridMap(of: id)?.cells.count == 8)

        // Floors above the edited one are hidden, those below faded.
        workspace.brush.tool = .paint
        workspace.brush.piece = "Floor"
        view.setFloor(1)
        view.applyStroke([GridCoord(5, 1, 5)])
        workspace.update(input: nil, dt: 0)
        workspace.builder?.setFloor(0)
        func renderers(_ floor: String) -> [MeshRenderer] {
            guard let root = workspace.root, let node = workspace.world.children(of: root).first(where: {
                workspace.world.get(Name.self, for: $0)?.value == floor }) else { return [] }
            var out: [MeshRenderer] = [], stack = [node]
            while let e = stack.popLast() {
                if let r = workspace.world.get(MeshRenderer.self, for: e) { out.append(r) }
                stack += workspace.world.children(of: e)
            }
            return out
        }
        #expect(!renderers("Floor 1").isEmpty && renderers("Floor 1").allSatisfy { !$0.isVisible })
        workspace.builder?.setFloor(2)
        #expect(renderers("Floor 0").allSatisfy { $0.isVisible && $0.opacity < 1 })
        #expect(renderers("Floor 0").allSatisfy { $0.emissiveStrength == $0.opacity }, "glow fades with the floor")
        workspace.builder?.setFloor(0)
        #expect(renderers("Floor 0").allSatisfy { $0.opacity == 1 && $0.emissiveStrength == 1 })
        workspace.builder?.setFloor(2)

        _ = session.performUndo()
        _ = session.performUndo()
        #expect(session.assets?.gridMap(of: id)?.cells.count == 10)
        workspace.update(input: nil, dt: 0)
        #expect(workspace.builder?.map.cells.count == 10, "the form follows undo")
    }

    @Test func builderKeyboardShortcuts() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "gridMap.new", ["name": "Keys"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let workspace = GridMapWorkspace(session: session)
        #expect(workspace.open(id, floor: 0))
        let view = try #require(workspace.builder)
        let brush = workspace.brush

        #expect(view.handleKey(KeyEvent(key: .num3)) && brush.tool == .rect)
        #expect(view.handleKey(KeyEvent(key: .num5)) && brush.tool == .erase)
        #expect(view.handleKey(KeyEvent(key: .r)) && brush.rotation == 90)
        #expect(view.handleKey(KeyEvent(key: .r, isRepeat: true)) && brush.rotation == 180)
        #expect(view.handleKey(KeyEvent(key: .r, modifiers: .shift)) && brush.rotation == 90)
        #expect(view.handleKey(KeyEvent(key: .x)) && brush.flipX)
        #expect(!view.handleKey(KeyEvent(key: .x, isRepeat: true)) && brush.flipX, "a held key doesn't flicker the flip")
        #expect(view.handleKey(KeyEvent(key: .z)) && brush.flipZ)
        #expect(view.handleKey(KeyEvent(key: .pageUp)) && brush.floor == 1)
        #expect(view.handleKey(KeyEvent(key: .leftBracket)) && brush.floor == 0)
        // Shortcut combinations (Cmd+Z undo) and other keys are left alone.
        #expect(!view.handleKey(KeyEvent(key: .z, modifiers: .shortcut)) && brush.flipZ)
        #expect(!view.handleKey(KeyEvent(key: .q)))
        // The workspace only takes keys while the pointer is over the tab.
        #expect(!workspace.handleKeys([KeyEvent(key: .num1)], pointer: Vec2(-100, -100)) && brush.tool == .erase)
        // The buttons show their keys.
        let rotate = try #require(view.view.descendant(named: "gridMapRotate"))
        #expect(rotate.tooltip?.contains("(R") == true)
    }

}
