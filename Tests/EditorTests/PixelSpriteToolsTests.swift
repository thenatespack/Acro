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

// The pixel sprite builder as an agent uses it (sprite.* tools) and as a user does
// (PixelSpriteBuilderView, PixelSpriteWorkspace), with undo.

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
@Suite struct PixelSpriteToolsTests {
    private func makeProject() throws -> (EditorSession, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PixelSpriteToolsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return (session, folder)
    }

    @Test func newDrawEditAndUndo() throws {
        let (session, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }

        let created = try call(session, "sprite.new", ["name": "Hero", "folder": "Sprites", "width": 8, "height": 8, "palette": "db32"])
        #expect(created["path"] as? String == "Sprites/Hero.sprite")
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isPixelSpriteFile(id))
        #expect((created["palette"] as? [String])?.count == 32)
        #expect((created["texture"] as? String)?.hasSuffix("#texture") == true)

        let drawn = try call(session, "sprite.draw", ["path": "Sprites/Hero.sprite", "pixels": ["..11..", ".1221."], "x": 1, "y": 2])
        let preview = try #require(drawn["preview"] as? [String])
        #expect(preview[2] == "...11...")
        #expect(preview[3] == "..1221..")

        try call(session, "sprite.draw", ["path": "Sprites/Hero.sprite",
                                          "ops": [["tool": "line", "points": [[0, 7], [7, 7]], "color": 5],
                                                  ["tool": "rect", "points": [[0, 0], [1, 1]], "color": "#123456", "filled": true]],
                                          "mirrorX": true])
        var sprite = try #require(session.assets?.pixelSprite(of: id))
        #expect(sprite.compositeRows(frame: 0)[7] == "55555555")
        #expect(sprite.palette.count == 33, "the hex color was added")
        #expect(sprite.compositeRows(frame: 0)[0] == "ww....ww")

        let edited = try call(session, "sprite.edit", ["path": "Sprites/Hero.sprite", "addFrames": 3, "copyFrame": 0, "addLayers": ["Outline"],
                                                       "durations": [100, 200], "tags": [["name": "idle", "from": 0, "to": 1],
                                                                                         ["name": "run", "from": 2, "to": 3, "mode": "pingPong"]]])
        #expect((edited["frames"] as? [Int]) == [100, 200, 100, 100])
        let clips = try #require(edited["clips"] as? [[String: Any]])
        #expect(clips.map { $0["name"] as? String } == ["idle", "run"])
        #expect(clips[0]["frames"] as? [Int] == [0, 1, 1])
        sprite = try #require(session.assets?.pixelSprite(of: id))
        #expect(sprite.layers.map(\.name) == ["Layer 1", "Outline"])
        #expect(sprite.layers[0].cels[3] == sprite.layers[0].cels[0])

        try call(session, "sprite.draw", ["path": "Sprites/Hero.sprite", "frame": 2, "layer": "Outline", "ops": [["tool": "fill", "points": [[4, 4]]]], "color": "a"])
        #expect(session.assets?.pixelSprite(of: id)?.layers[1].cels[2].allSatisfy { $0 == 11 } == true)
        #expect(session.performUndo())
        #expect(session.assets?.pixelSprite(of: id)?.layers[1].cels[2].allSatisfy { $0 == 0 } == true)

        let got = try call(session, "sprite.get", ["path": "Sprites/Hero.sprite", "frame": 1])
        #expect(got["previewFrame"] as? Int == 1)
        #expect((got["sprite"] as? [String: Any])?["layers"] != nil)
        #expect(got["atlasColumns"] as? Int == 2)

        // Problems come back as warnings, bad arguments as errors.
        let bad = try call(session, "sprite.edit", ["path": "Sprites/Hero.sprite", "addTags": [["name": "far", "from": 2, "to": 40]]])
        #expect((bad["warnings"] as? [String])?.contains { $0.contains("far") } == true)
        #expect(throws: (any Error).self) { try call(session, "sprite.draw", ["path": "Sprites/Hero.sprite", "layer": "Nope", "pixels": ["0"]]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.draw", ["path": "Sprites/Hero.sprite", "frame": 99, "pixels": ["0"]]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.new", ["palette": "nope"]) }

        try call(session, "sprite.set", ["path": "Sprites/Hero.sprite", "sprite": ["width": 2, "height": 2]])
        #expect(session.assets?.pixelSprite(of: id)?.width == 2)
        #expect(session.performUndo())
        #expect(session.assets?.pixelSprite(of: id)?.width == 8)

        let opened = try call(session, "sprite.open", ["path": "Sprites/Hero.sprite"])
        #expect(opened["path"] as? String == "Sprites/Hero.sprite")
        #expect(session.openPixelSprite == id)
    }

    @Test func builderStrokesAndFormEditsAreOneUndoStepEach() throws {
        let (session, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let id = try #require(session.createPixelSpriteAsset(in: "", name: "S", sprite: PixelSprite(width: 6, height: 6)))
        let workspace = PixelSpriteWorkspace(session: session)
        #expect(workspace.open(id))
        let builder = try #require(workspace.builder)

        builder.selectTool(.line)
        builder.selectColor(3)
        builder.applyStroke(.line, points: [PixelPoint(0, 0), PixelPoint(5, 0)])
        #expect(builder.hasPendingEdit)
        workspace.update(dt: 0.016)
        #expect(session.assets?.pixelSprite(of: id)?.compositeRows(frame: 0)[0] == "222222")

        // A canvas drag: the canvas maps pointer positions to pixels and hands the stroke over on release.
        let canvas = workspace.canvas
        canvas.layout(in: UIRect(x: 0, y: 0, width: 300, height: 300))
        builder.selectTool(.pencil)
        let s = canvas.pixelScale, o = canvas.origin
        func at(_ x: Int, _ y: Int) -> Vec2 { Vec2(o.x + (Float(x) + 0.5) * s, o.y + (Float(y) + 0.5) * s) }
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: at(0, 5))))
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: at(5, 5))))
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: at(5, 5))))
        workspace.update(dt: 0.016)
        #expect(session.assets?.pixelSprite(of: id)?.compositeRows(frame: 0)[5] == "222222")

        // Picker (Alt+click) selects the color under the pointer without an edit.
        builder.selectColor(1)
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: at(2, 0), modifiers: .alt)))
        #expect(builder.color == 3)
        #expect(!builder.hasPendingEdit)

        var edited = builder.sprite
        edited.insertFrames(1)
        edited.tags = [PixelSprite.Tag("walk", from: 0, to: 1)]
        builder.apply(edited, label: "Add Frame")
        workspace.update(dt: 0.016)
        #expect(session.assets?.pixelSprite(of: id)?.frames.count == 2)
        #expect(workspace.preview.currentFrame != nil)

        #expect(session.performUndo())
        workspace.update(dt: 0.016)
        #expect(session.assets?.pixelSprite(of: id)?.frames.count == 1)
        #expect(builder.sprite.frames.count == 1, "the builder follows the undo")
        #expect(session.performUndo())
        #expect(session.assets?.pixelSprite(of: id)?.compositeRows(frame: 0)[5] == "......")
        #expect(session.performUndo())
        #expect(session.assets?.pixelSprite(of: id)?.compositeRows(frame: 0)[0] == "......")
    }

    @Test func selectionToolsMoveCopyAndClearBetweenCels() throws {
        let (session, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let created = try call(session, "sprite.new", ["name": "Sel", "width": 4, "height": 3, "frames": 2])
        try call(session, "sprite.draw", ["path": "Sel.sprite", "pixels": ["12..", "34.."]])

        // move cuts and pastes; copy pastes from another cel; clear erases.
        var drawn = try call(session, "sprite.draw", ["path": "Sel.sprite", "ops": [["tool": "move", "rect": [0, 0, 2, 2], "to": [2, 1]]]])
        #expect(drawn["preview"] as? [String] == ["....", "..12", "..34"])
        drawn = try call(session, "sprite.draw", ["path": "Sel.sprite", "frame": 1,
                                                  "ops": [["tool": "copy", "rect": [2, 1, 2, 2], "fromFrame": 0, "to": [0, 0]],
                                                          ["tool": "clear", "rect": [1, 0, 1, 9]]]])
        #expect(drawn["preview"] as? [String] == ["1...", "3...", "...."])
        #expect((drawn["warnings"] as? [String])?.contains { $0.contains("cut to the canvas") } == true)
        #expect(throws: (any Error).self) { try call(session, "sprite.draw", ["path": "Sel.sprite", "ops": [["tool": "move", "rect": [0, 0, 1, 1]]]]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.draw", ["path": "Sel.sprite", "ops": [["tool": "clear"]]]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.draw", ["path": "Sel.sprite", "ops": [["tool": "clear", "rect": [9, 9, 1, 1]]]]) }

        // sprite.edit copyCels: a new frame and layer as targets, merged and replacing.
        try call(session, "sprite.edit", ["path": "Sel.sprite", "addFrames": 1, "addLayers": ["Top"],
                                          "copyCels": [["fromFrame": 0, "toFrame": 2, "toLayer": "Top"],
                                                       ["fromFrame": 1, "toFrame": 2, "rect": [0, 0, 1, 1], "x": 3, "y": 0]]])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        var sprite = try #require(session.assets?.pixelSprite(of: id))
        #expect(sprite.compositeRows(frame: 2) == ["...1", "..12", "..34"])
        try call(session, "sprite.edit", ["path": "Sel.sprite", "copyCels": [["fromFrame": 1, "toFrame": 2, "toLayer": "Top", "replace": true]]])
        sprite = try #require(session.assets?.pixelSprite(of: id))
        #expect(sprite.compositeRows(frame: 2) == ["1..1", "3...", "...."], "replace: the Top cel is now frame 1's")
        #expect(throws: (any Error).self) { try call(session, "sprite.edit", ["path": "Sel.sprite", "copyCels": [["fromFrame": 0, "toFrame": 9]]]) }
        #expect(session.performUndo())
        #expect(session.assets?.pixelSprite(of: id)?.compositeRows(frame: 2) == ["...1", "..12", "..34"])
    }

    @Test func builderSelectsCopiesPastesAndTakesToolKeys() throws {
        let (session, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        var start = PixelSprite(width: 6, height: 6, frameCount: 2)
        start.stamp(rows: ["11", "22"], frame: 0, layer: 0)
        let id = try #require(session.createPixelSpriteAsset(in: "", name: "S", sprite: start))
        let workspace = PixelSpriteWorkspace(session: session)
        #expect(workspace.open(id))
        let builder = try #require(workspace.builder)
        func rows(_ frame: Int) -> [String]? { session.assets?.pixelSprite(of: id)?.compositeRows(frame: frame) }

        // Drag out a selection with the select tool, then drag it to move the pixels.
        let canvas = workspace.canvas
        canvas.layout(in: UIRect(x: 0, y: 0, width: 300, height: 300))
        #expect(builder.handleKey(KeyEvent(key: .m)))
        #expect(builder.tool == .select)
        let s = canvas.pixelScale, o = canvas.origin
        func at(_ x: Int, _ y: Int) -> Vec2 { Vec2(o.x + (Float(x) + 0.5) * s, o.y + (Float(y) + 0.5) * s) }
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: at(0, 0))))
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: at(1, 1))))
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: at(1, 1))))
        #expect(builder.selection == PixelRect(x: 0, y: 0, width: 2, height: 2))
        #expect(!builder.hasPendingEdit)
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: at(1, 1))))
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: at(3, 2))))
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: at(3, 2))))
        workspace.update(dt: 0.016)
        #expect(rows(0)?[1] == "..11..")
        #expect(rows(0)?[2] == "..22..")
        #expect(builder.selection == PixelRect(x: 2, y: 1, width: 2, height: 2))

        // Copy, go to the next frame, paste in the same place; arrows nudge the pasted pixels.
        let mod: KeyModifiers = EditorShortcuts().shortcutModifier == .command ? .command : .control
        #expect(builder.claimsKey(KeyEvent(key: .c, modifiers: mod)))
        #expect(!builder.claimsKey(KeyEvent(key: .s, modifiers: mod)), "save stays the editor's")
        builder.handleKey(KeyEvent(key: .c, modifiers: mod))
        builder.selectFrame(1)
        builder.handleKey(KeyEvent(key: .v, modifiers: mod))
        workspace.update(dt: 0.016)
        #expect(rows(1)?[1] == "..11..")
        builder.handleKey(KeyEvent(key: .right, modifiers: .shift))
        workspace.update(dt: 0.016)
        #expect(rows(1)?[1] == "......", "moved 8 pixels: off the canvas")
        #expect(session.performUndo())
        workspace.update(dt: 0.016)
        #expect(rows(1)?[1] == "..11..")

        // Delete erases the selection, Esc drops it; without a selection, arrows step frames.
        builder.select(PixelRect(x: 2, y: 1, width: 1, height: 2))
        builder.handleKey(KeyEvent(key: .delete))
        workspace.update(dt: 0.016)
        #expect(rows(1)?[1] == "...1..")
        builder.handleKey(KeyEvent(key: .escape))
        #expect(builder.selection == nil)
        builder.handleKey(KeyEvent(key: .left))
        #expect(builder.frame == 0)

        // Tool keys and mirror toggles.
        for (key, tool) in [(Key.b, PixelTool.pencil), (.l, .line), (.u, .rect), (.g, .fill), (.e, .eraser), (.i, .picker)] {
            builder.handleKey(KeyEvent(key: key))
            #expect(builder.tool == tool)
        }
        builder.handleKey(KeyEvent(key: .h))
        #expect(builder.mirror.contains(.horizontal))
        #expect(!builder.claimsKey(KeyEvent(key: .z, modifiers: mod)), "undo stays the editor's")
    }

    @Test func importSheetWritesASpriteOrReplacesOne() throws {
        let (session, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        // A 4 x 1 strip of 2 x 1 frames: [red, clear], [clear, blue].
        let png = folder.appendingPathComponent("walk.png")
        try Image(width: 4, height: 1, pixels: [255, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255]).writePNG(to: png)

        let result = try call(session, "sprite.importSheet", ["file": png.path, "frameWidth": 2, "frameHeight": 1, "duration": 80,
                                                              "tags": [["name": "walk", "from": 0, "to": 1]]])
        #expect(result["path"] as? String == "walk.sprite")
        #expect(result["frames"] as? [Int] == [80, 80])
        #expect((result["sheet"] as? [String: Any])?["columns"] as? Int == 2)
        #expect((result["clips"] as? [[String: Any]])?.first?["name"] as? String == "walk")
        let id = try #require((result["asset"] as? String).flatMap { AssetID($0) })
        let sprite = try #require(session.assets?.pixelSprite(of: id))
        #expect(sprite.palette.count == 2)
        #expect(sprite.compositeRows(frame: 0)[0].first != ".")
        #expect(sprite.compositeRows(frame: 1)[0].first == ".")

        // columns / rows give the frame size; `into` replaces an existing sprite as one undo step.
        try call(session, "sprite.new", ["name": "Target"])
        let replaced = try call(session, "sprite.importSheet", ["file": png.path, "columns": 4, "rows": 1, "palette": "pico8", "into": "Target.sprite"])
        #expect(replaced["width"] as? Int == 1)
        #expect((replaced["frames"] as? [Int])?.count == 4)
        #expect((replaced["sheet"] as? [String: Any])?["quantized"] as? Bool == true, "pure red and blue map to the nearest pico8 colors")
        #expect((replaced["palette"] as? [String])?.count == 16)
        #expect(session.performUndo())
        let targetID = try #require(session.assets?.id(forPath: "Target.sprite"))
        let target = try #require(session.assets?.pixelSprite(of: targetID))
        #expect(target.width == 16)

        #expect(throws: (any Error).self) { try call(session, "sprite.importSheet", ["file": png.path]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.importSheet", ["file": png.path, "frameWidth": 8, "frameHeight": 8]) }
        #expect(throws: (any Error).self) { try call(session, "sprite.importSheet", ["frameWidth": 2]) }
    }
}
