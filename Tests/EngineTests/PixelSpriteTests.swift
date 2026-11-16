import Foundation
import Testing
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

private func rgba(_ image: Image, _ x: Int, _ y: Int) -> [UInt8] {
    let i = (y * image.width + x) * 4
    return Array(image.pixels[i..<i + 4])
}

@Suite struct PixelSpriteTests {
    @Test func fileRoundTripsWithRowStringsAndDefaults() throws {
        var sprite = PixelSprite(width: 4, height: 2, palette: [PixelColor(hex: 0x000000), PixelColor(hex: 0xff004d)], frameCount: 2)
        sprite.stamp(rows: [".11.", "1001"], frame: 0, layer: 0)
        sprite.tags = [PixelSprite.Tag("idle", from: 0, to: 1, mode: .pingPong)]
        let data = try sprite.fileData()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\".11.\""))
        #expect(text.contains("\"#ff004d\""))
        let decoded = try AssetJSON.decoder().decode(PixelSprite.self, from: data)
        #expect(decoded == sprite)
        #expect(decoded.layers[0].cels[1].allSatisfy { $0 == 0 }, "an empty cel")

        let empty = try AssetJSON.decoder().decode(PixelSprite.self, from: Data("{}".utf8))
        #expect(empty == PixelSprite())
        #expect(empty.width == 16 && empty.palette == PixelPalette.pico8.colors)

        // Cels without a frame list get a frame each; short rows pad with transparent.
        let loose = try AssetJSON.decoder().decode(PixelSprite.self, from: Data(#"{"width": 3, "height": 2, "layers": [{"cels": [["1"], ["", "22"]]}]}"#.utf8))
        #expect(loose.frames.count == 2)
        #expect(loose.compositeRows(frame: 0) == ["1..", "..."])
        #expect(loose.compositeRows(frame: 1) == ["...", "22."])
    }

    @Test func drawingToolsLinesRectsFillAndMirror() {
        var s = PixelSprite(width: 5, height: 5)
        s.draw(.line, points: [PixelPoint(0, 0), PixelPoint(4, 4)], value: 1, frame: 0, layer: 0)
        #expect((0..<5).allSatisfy { s.pixel(frame: 0, layer: 0, x: $0, y: $0) == 1 })
        s.clearCel(frame: 0, layer: 0)
        s.draw(.rect, points: [PixelPoint(0, 0), PixelPoint(4, 4)], value: 2, frame: 0, layer: 0)
        #expect(s.compositeRows(frame: 0) == ["11111", "1...1", "1...1", "1...1", "11111"])
        s.draw(.fill, points: [PixelPoint(2, 2)], value: 3, frame: 0, layer: 0)
        #expect(s.compositeRows(frame: 0)[2] == "12221")
        s.draw(.eraser, points: [PixelPoint(0, 0), PixelPoint(0, 4)], value: 3, frame: 0, layer: 0)
        #expect(s.compositeRows(frame: 0).map { $0.first! } == [".", ".", ".", ".", "."])

        var m = PixelSprite(width: 4, height: 4)
        m.draw(.pencil, points: [PixelPoint(0, 0)], value: 1, frame: 0, layer: 0, mirror: [.horizontal, .vertical])
        #expect(m.compositeRows(frame: 0) == ["0..0", "....", "....", "0..0"])
        m.draw(.rect, points: [PixelPoint(1, 1), PixelPoint(2, 2)], value: 2, frame: 0, layer: 0, filled: true)
        #expect(m.compositeRows(frame: 0)[1] == ".11.")
    }

    @Test func layersCompositeWithOpacityAndVisibility() {
        var s = PixelSprite(width: 2, height: 1, palette: [PixelColor(255, 0, 0), PixelColor(0, 0, 255)])
        s.stamp(rows: ["00"], frame: 0, layer: 0)
        let top = s.insertLayer(name: "Top", opacity: 0.5)
        s.stamp(rows: ["1."], frame: 0, layer: top)
        let image = s.image(frame: 0)
        #expect(rgba(image, 1, 0) == [255, 0, 0, 255])
        let mixed = rgba(image, 0, 0)
        #expect(mixed[0] > 120 && mixed[0] < 135 && mixed[2] > 120 && mixed[2] < 135 && mixed[3] == 255)
        #expect(s.pick(frame: 0, x: 0, y: 0) == 2)
        s.layers[top].visible = false
        #expect(rgba(s.image(frame: 0), 0, 0) == [255, 0, 0, 255])
        #expect(s.pick(frame: 0, x: 0, y: 0) == 1)
        #expect(s.layerIndex(named: "Top") == 1)
    }

    @Test func framesTagsAndPaletteEditsKeepThingsConsistent() {
        var s = PixelSprite(width: 2, height: 2, frameCount: 4)
        s.tags = [PixelSprite.Tag("walk", from: 1, to: 3)]
        s.stamp(rows: ["1"], frame: 1, layer: 0)
        s.insertFrames(2, at: 0)
        #expect(s.frames.count == 6 && s.tags[0].from == 3 && s.tags[0].to == 5)
        s.insertFrames(1, at: 4, copyOf: 3)
        #expect(s.tags[0].to == 6, "a frame inserted inside a tag joins it")
        #expect(s.layers[0].cels[4] == s.layers[0].cels[3])
        s.removeFrames([3, 4])
        #expect(s.frames.count == 5 && s.tags[0].from == 3 && s.tags[0].to == 4)
        s.removeFrames([0, 1, 2, 3, 4])
        #expect(s.frames.count == 1, "one frame always stays")

        var p = PixelSprite(width: 3, height: 1, palette: [PixelColor(hex: 0x111111), PixelColor(hex: 0x222222), PixelColor(hex: 0x333333)])
        p.stamp(rows: ["012"], frame: 0, layer: 0)
        p.removeColor(1)
        #expect(p.compositeRows(frame: 0) == ["0.1"])
        #expect(p.value(for: PixelColor(hex: 0xabcdef)) == 3)
        #expect(p.palette.count == 3)
        #expect(p.resized(width: 2, height: 2).compositeRows(frame: 0) == ["0.", ".."])
        p.layers[0].cels[0][0] = 40
        #expect(p.problems().contains { $0.contains("palette entry 39") })
    }

    @Test func sheetHasStableGridIndexingAndClipsKeepFrameTiming() {
        var s = PixelSprite(width: 3, height: 2, palette: [PixelColor(255, 0, 0), PixelColor(0, 255, 0)], frameCount: 5)
        for f in 0..<5 { s.stamp(rows: [String(repeating: f % 2 == 0 ? "0" : "1", count: 3)], frame: f, layer: 0) }
        s.frames[1].duration = 200
        s.tags = [PixelSprite.Tag("run", from: 0, to: 2), PixelSprite.Tag("jump", from: 3, to: 4, mode: .once)]
        let sheet = s.sheet()
        #expect(sheet.columns == 3 && sheet.rows == 2)
        #expect(sheet.cellWidth == 5 && sheet.cellHeight == 4 && sheet.image.width == 15 && sheet.image.height == 8)
        #expect(sheet.frames.count == 5)
        #expect(sheet.frames[4].x == 1 * 5 + 1 && sheet.frames[4].y == 4 + 1)
        #expect(sheet.frameIndex(column: 1, row: 1) == 4)
        #expect(sheet.frameIndex(column: 2, row: 1) == nil)
        // Frame 1 is green; its extruded border repeats its edge.
        #expect(rgba(sheet.image, sheet.frames[1].x, sheet.frames[1].y) == [0, 255, 0, 255])
        #expect(rgba(sheet.image, sheet.frames[1].x - 1, sheet.frames[1].y - 1) == [0, 255, 0, 255])

        let run = sheet.clip(named: "run")!
        #expect(run.frames == [0, 1, 1, 2] && run.fps == 10)
        let jump = sheet.clip(named: "jump")!
        #expect(jump.frames == [3, 4] && jump.mode == .once)
        #expect(PixelSprite(width: 1, height: 1, frameCount: 3).clips().map(\.name) == ["default"])

        // EngineRendering's view of it.
        let atlas = SpriteAtlasImage(sheet: sheet)
        #expect(atlas.frames.map(\.name) == (0..<5).map { "frame\($0)" })
        #expect(atlas.frames[4].x == sheet.frames[4].x && atlas.frames[4].pivot == Vec2(0.5, 0))
        let clips = SpriteClip.clips(from: sheet)
        #expect(clips[0].name == "run" && clips[0].frames == [0, 1, 1, 2] && clips[1].mode == .once)
        #expect(clips[0].frame(at: 0.15) == 1 && clips[0].frame(at: 0.35) == 2)
    }

    @Test func selectionsCopyPasteMoveAndClearBetweenCels() throws {
        var sprite = PixelSprite(width: 4, height: 3, frameCount: 2)
        sprite.insertLayer(name: "Top", at: 1)
        sprite.stamp(rows: ["12..", "34.."], frame: 0, layer: 0)
        sprite.stamp(rows: ["...5"], frame: 0, layer: 1)

        let clip = try #require(sprite.copy(PixelRect(x: 0, y: 0, width: 2, height: 2), frame: 0, layer: 0))
        #expect(clip.rows == ["12", "34"])
        #expect(sprite.copy(PixelRect(x: 9, y: 9, width: 2, height: 2), frame: 0, layer: 0) == nil)
        #expect(sprite.copy(PixelRect(x: 3, y: 2, width: 5, height: 5), frame: 0, layer: 0)?.width == 1, "cut to the canvas")

        // Paste into another frame, partly off the canvas: the overflow is cut.
        sprite.paste(clip, x: 3, y: 1, frame: 1, layer: 0)
        #expect(sprite.compositeRows(frame: 1) == ["....", "...1", "...3"])
        // Transparent clip pixels don't cover, unless opaque.
        let holes = PixelClip(width: 2, height: 1, pixels: [0, 7])
        sprite.paste(holes, x: 2, y: 1, frame: 1, layer: 0)
        #expect(sprite.compositeRows(frame: 1)[1] == "...6")
        sprite.paste(holes, x: 2, y: 1, frame: 1, layer: 0, opaque: true)
        #expect(sprite.compositeRows(frame: 1)[1] == "...6")
        sprite.paste(holes, x: 3, y: 1, frame: 1, layer: 0, opaque: true)
        #expect(sprite.compositeRows(frame: 1)[1] == "....")

        // Merged copies take the visible pixels of every layer.
        #expect(sprite.copyMerged(PixelRect(x: 2, y: 0, width: 2, height: 1), frame: 0)?.rows == [".5"])

        sprite.move(PixelRect(x: 0, y: 0, width: 2, height: 2), dx: 1, dy: 1, frame: 0, layer: 0)
        #expect(sprite.compositeRows(frame: 0) == ["...5", ".12.", ".34."])
        sprite.move(PixelRect(x: 1, y: 1, width: 1, height: 1), dx: -1, dy: -1, frame: 0, layer: 0, copy: true)
        #expect(sprite.compositeRows(frame: 0) == ["1..5", ".12.", ".34."])
        sprite.clear(PixelRect(x: 1, y: 1, width: 9, height: 9), frame: 0, layer: 0)
        #expect(sprite.compositeRows(frame: 0) == ["1..5", "....", "...."])

        #expect(PixelRect(corners: PixelPoint(3, 1), PixelPoint(1, 2)) == PixelRect(x: 1, y: 1, width: 3, height: 2))
        let encoded = try JSONEncoder().encode(PixelRect(x: 1, y: 2, width: 3, height: 4))
        #expect(String(decoding: encoded, as: UTF8.self) == "[1,2,3,4]")
    }

    @Test func layerBlendModesApplyAtImport() throws {
        // Base gray (128) under a top layer of (64, 255, 0); the top's right pixel has nothing below.
        var s = PixelSprite(width: 2, height: 1, palette: [PixelColor(128, 128, 128), PixelColor(64, 255, 0)])
        s.stamp(rows: ["0."], frame: 0, layer: 0)
        s.insertLayer(name: "Top", at: 1)
        s.stamp(rows: ["11"], frame: 0, layer: 1)
        func top(_ mode: PixelSprite.BlendMode) -> [UInt8] {
            s.layers[1].blend = mode
            let image = s.image(frame: 0)
            #expect(rgba(image, 1, 0) == [64, 255, 0, 255], "over nothing every mode is normal")
            return rgba(image, 0, 0)
        }
        #expect(top(.normal) == [64, 255, 0, 255])
        #expect(top(.multiply) == [32, 128, 0, 255])
        #expect(top(.add) == [192, 255, 128, 255])
        #expect(top(.screen) == [160, 255, 128, 255])
        let overlay = top(.overlay)
        #expect((63...66).contains(overlay[0]) && overlay[1] == 255 && overlay[2] <= 2, "below is mid gray: about the layer itself")

        // Half opacity mixes the blended color with what is below.
        s.layers[1].blend = .multiply
        s.layers[1].opacity = 0.5
        #expect(rgba(s.image(frame: 0), 0, 0) == [80, 128, 64, 255])

        // In the file: "blend" only when not normal; the importer's atlas uses it.
        let decoded = try JSONDecoder().decode(PixelSprite.self, from: s.fileData())
        #expect(decoded.layers.map(\.blend) == [.normal, .multiply])
        #expect(!String(decoding: try PixelSprite().fileData(), as: UTF8.self).contains("blend"))
        let sheet = s.sheet()
        #expect(rgba(sheet.image, sheet.frames[0].x, sheet.frames[0].y) == [80, 128, 64, 255])
    }

    @Test func tagFrameEventsFireThroughTheAnimator() throws {
        var s = PixelSprite(width: 1, height: 1, frameCount: 4)
        s.frames[1].duration = 200
        s.tags = [PixelSprite.Tag("walk", from: 0, to: 2, events: [PixelSprite.FrameEvent(frame: 1, name: "step"),
                                                                    PixelSprite.FrameEvent(frame: 2, name: "land"),
                                                                    PixelSprite.FrameEvent(frame: 3, name: "outside")])]
        #expect(s.problems().contains { $0.contains("'outside'") })
        let clip = try #require(s.clips().first)
        #expect(clip.frames == [0, 1, 1, 2])
        #expect(clip.events == [.init(step: 1, name: "step"), .init(step: 3, name: "land")], "first step of a repeated frame; outside dropped")

        // In the file: events only on tags that have them.
        let json = String(decoding: try JSONEncoder().encode(PixelSprite.Tag("idle", from: 0, to: 0)), as: UTF8.self)
        #expect(!json.contains("events"))
        let decoded = try JSONDecoder().decode(PixelSprite.self, from: s.fileData())
        #expect(decoded.tags[0].events.count == 3)

        // The animator fires them once per pass, in order.
        var animator = SpriteAnimator(clips: SpriteClip.clips(from: s.sheet()))
        var fired: [String] = []
        for _ in 0..<40 { animator.advance(dt: 0.01); fired += animator.events }
        #expect(fired == ["step", "land"])
        animator.advance(dt: 0.12)
        #expect(animator.events == ["step"], "loops back to frame 1")

        // Frame edits keep the events on their frames.
        s.insertFrames(1, at: 0)
        #expect(s.tags[0].events.map(\.frame) == [2, 3, 4])
        s.removeFrames([2])
        #expect(s.tags[0].events.map(\.frame) == [2, 3])
        #expect(s.tags[0].events.map(\.name) == ["land", "outside"])
    }

    @Test func importsASheetBySlicingAndQuantizing() throws {
        // A 2 x 2 grid of 3 x 2 cells with a 1-pixel margin and spacing: red, green, blue, empty.
        let colors: [[UInt8]] = [[255, 0, 0, 255], [0, 255, 0, 255], [0, 0, 255, 255]]
        var px = [UInt8](repeating: 0, count: 9 * 7 * 4)
        func set(_ x: Int, _ y: Int, _ c: [UInt8]) { for k in 0..<4 { px[(y * 9 + x) * 4 + k] = c[k] } }
        for (i, c) in colors.enumerated() {
            let ox = 1 + (i % 2) * 4, oy = 1 + (i / 2) * 3
            set(ox, oy, c)
            set(ox + 2, oy + 1, c)
        }
        set(1 + 1, 1, [255, 0, 0, 40]) // nearly transparent: dropped
        let sheet = Image(width: 9, height: 7, pixels: px)
        let slicing = PixelSheetSlicing(frameWidth: 3, frameHeight: 2, margin: 1, spacing: 1)
        #expect(slicing.grid(width: 9, height: 7) == (2, 2))

        let (sprite, report) = try PixelSprite.importingSheet(sheet, slicing: slicing)
        #expect(sprite.width == 3 && sprite.height == 2)
        #expect(sprite.frames.count == 3, "the empty last cell is dropped")
        #expect(report.columns == 2 && report.rows == 2 && report.colorsFound == 3 && !report.quantized)
        #expect(sprite.palette.count == 3)
        for f in 0..<3 {
            let i = try #require(sprite.palette.firstIndex(of: PixelColor(colors[f][0], colors[f][1], colors[f][2])))
            let ch = PixelSprite.character(for: UInt8(i + 1))
            #expect(sprite.compositeRows(frame: f) == ["\(ch)..", "..\(ch)"])
        }

        // A given palette maps to the nearest color; frameCount limits the frames.
        let mapped = try PixelSprite(sheet: sheet, slicing: PixelSheetSlicing(frameWidth: 3, frameHeight: 2, margin: 1, spacing: 1, frameCount: 2),
                                     palette: [PixelColor(200, 30, 30), PixelColor(20, 20, 20)])
        #expect(mapped.frames.count == 2)
        #expect(mapped.compositeRows(frame: 0) == ["0..", "..0"])
        #expect(mapped.compositeRows(frame: 1) == ["1..", "..1"], "green is nearer the dark gray")

        // More colors than allowed: median cut.
        let (reduced, reducedReport) = try PixelSprite.importingSheet(sheet, slicing: slicing, maxColors: 2)
        #expect(reduced.palette.count == 2 && reducedReport.quantized)
        #expect(reducedReport.warnings.contains { $0.contains("reduced to 2") })

        #expect(throws: PixelSheetImportError.self) { try PixelSprite(sheet: sheet, slicing: PixelSheetSlicing(frameWidth: 20, frameHeight: 2)) }
        #expect(throws: PixelSheetImportError.self) { try PixelSprite(sheet: sheet, slicing: PixelSheetSlicing(frameWidth: 0, frameHeight: 2)) }

        // Median cut keeps clusters apart.
        let cut = PixelSprite.medianCut([PixelColor(250, 0, 0): 5, PixelColor(240, 10, 0): 5, PixelColor(0, 0, 250): 3, PixelColor(0, 10, 240): 3], to: 2)
        #expect(cut.count == 2)
        #expect(cut.contains { $0.r > 200 && $0.b < 20 } && cut.contains { $0.b > 200 && $0.r < 20 })
    }

    @MainActor @Test func importsAsATextureAndHotReloads() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PixelSpriteTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "Sprites")
        defer { try? FileManager.default.removeItem(at: url) }
        let db = AssetDatabase(project: project)
        db.refresh()
        var sprite = PixelSprite(width: 8, height: 8, frameCount: 2)
        sprite.stamp(rows: ["88888888"], frame: 0, layer: 0)
        let id = try db.createPixelSprite(sprite, at: "Sprites/hero.sprite")
        #expect(db.record(id)?.importer == "sprite")
        #expect(db.record(id)?.importError == nil)
        #expect(db.pixelSprite(of: id) == sprite)
        let texture = try #require(db.texture(AssetReference(id, subAsset: "texture")))
        #expect(texture.generatesMipmaps == false)
        guard case .rgba8(let image) = texture.pixels else { Issue.record("expected rgba8 pixels"); return }
        #expect(image.width == 20 && image.height == 10)
        #expect(db.spriteSheet(path: "Assets/Sprites/hero.sprite")?.frames.count == 2)

        var bad = sprite
        bad.tags = [PixelSprite.Tag("oops", from: 0, to: 9)]
        let warnings = try db.writePixelSprite(bad, to: id)
        #expect(warnings.contains { $0.contains("oops") })

        #if os(macOS)
        let device = try MetalRenderDevice(layer: CAMetalLayer(), sampleCount: 1)
        let renderer = try SpriteRenderer(device: device)
        let library = SpriteAssetLibrary(assets: db, device: device, renderer: renderer)
        let handle = try #require(library.handle(path: "Sprites/hero.sprite"))
        #expect(handle.key == "Sprites/hero.sprite")
        #expect(renderer.atlas(for: handle)?.frameCount == 2)
        #expect(library.animator(path: "Sprites/hero.sprite", playing: "oops")?.current == "oops")
        #expect(library.update().isEmpty)
        var more = sprite
        more.insertFrames(2)
        try db.writePixelSprite(more, to: id)
        #expect(library.update() == [id])
        #expect(renderer.atlas(for: handle)?.frameCount == 4)
        #expect(library.atlas(id)?.pixelsPerUnit == 16)
        #endif
    }
}

#if os(macOS)
import QuartzCore
#endif
