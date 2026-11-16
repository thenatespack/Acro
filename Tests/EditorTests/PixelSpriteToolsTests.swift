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
}
