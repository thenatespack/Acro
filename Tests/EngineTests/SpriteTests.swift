import Foundation
import Testing
@testable import Engine

@MainActor private final class StubTexture: GPUTexture {
    let width = 64, height = 64
    let format = TextureFormat.rgba8Srgb
    let mipLevelCount = 1
}

private func solid(_ w: Int, _ h: Int, _ rgba: [UInt8]) -> Image {
    Image(width: w, height: h, pixels: (0..<w * h).flatMap { _ in rgba })
}

private func pixel(_ image: Image, _ x: Int, _ y: Int) -> [UInt8] {
    let i = (y * image.width + x) * 4
    return Array(image.pixels[i..<i + 4])
}

// MARK: Atlas packing

@Test func packedFramesDoNotOverlapAndKeepTheirPixels() throws {
    var builder = SpriteAtlasBuilder(extrude: 1, spacing: 1)
    let sizes = [(10, 12), (7, 7), (20, 5), (3, 30), (16, 16)]
    for (i, size) in sizes.enumerated() {
        builder.add(name: "s\(i)", image: solid(size.0, size.1, [UInt8(10 * (i + 1)), 0, 0, 255]))
    }
    let packed = try builder.pack()
    #expect(packed.frames.map(\.name) == ["s0", "s1", "s2", "s3", "s4"])
    #expect(packed.image.width == packed.image.height)
    // Frame rectangles, grown by their extrusion and spacing, are disjoint and inside the page.
    for (i, a) in packed.frames.enumerated() {
        #expect(a.x >= 1 && a.y >= 1 && a.x + a.width + 1 <= packed.image.width && a.y + a.height + 1 <= packed.image.height)
        for b in packed.frames[(i + 1)...] {
            let apart = a.x + a.width + 2 <= b.x - 1 || b.x + b.width + 2 <= a.x - 1
                || a.y + a.height + 2 <= b.y - 1 || b.y + b.height + 2 <= a.y - 1
            #expect(apart, "\(a.name) and \(b.name) overlap")
        }
        // The interior is the source color.
        #expect(pixel(packed.image, a.x, a.y)[0] == UInt8(10 * (i + 1)))
        #expect(pixel(packed.image, a.x + a.width - 1, a.y + a.height - 1)[0] == UInt8(10 * (i + 1)))
    }
}

@Test func uvRectsMatchPixelRects() throws {
    var builder = SpriteAtlasBuilder()
    builder.add(name: "a", image: solid(8, 8, [255, 255, 255, 255]))
    builder.add(name: "b", image: solid(5, 9, [255, 255, 255, 255]))
    let packed = try builder.pack()
    let size = Float(packed.image.width)
    for f in packed.frames {
        #expect(f.uvMin == Vec2(Float(f.x), Float(f.y)) / size)
        #expect(f.uvMax == Vec2(Float(f.x + f.width), Float(f.y + f.height)) / size)
    }
}

@Test func extrusionRepeatsEdgePixelsAndLeavesTheGapEmpty() throws {
    // A 2x2 image with four distinct corners.
    let image = Image(width: 2, height: 2, pixels: [
        1, 0, 0, 255, 2, 0, 0, 255,
        3, 0, 0, 255, 4, 0, 0, 255,
    ])
    var builder = SpriteAtlasBuilder(extrude: 2, spacing: 1)
    builder.add(name: "x", image: image)
    let packed = try builder.pack()
    let f = packed.frames[0]
    #expect(pixel(packed.image, f.x - 2, f.y - 2)[0] == 1)  // top-left corner extruded diagonally
    #expect(pixel(packed.image, f.x - 1, f.y)[0] == 1)
    #expect(pixel(packed.image, f.x + 3, f.y + 3)[0] == 4)
    #expect(pixel(packed.image, f.x + 2, f.y + 1)[0] == 4)
    // The spacing column right of the extrusion stays transparent.
    #expect(pixel(packed.image, f.x + 4, f.y) == [0, 0, 0, 0])
}

@Test func packingGrowsThePageAndFailsPastTheMaximum() throws {
    var small = SpriteAtlasBuilder(maxSize: 64)
    for i in 0..<4 { small.add(name: "i\(i)", image: solid(20, 20, [1, 2, 3, 255])) }
    #expect(try small.pack().image.width == 64)

    var tooMany = SpriteAtlasBuilder(maxSize: 32)
    for i in 0..<4 { tooMany.add(name: "i\(i)", image: solid(20, 20, [1, 2, 3, 255])) }
    #expect(throws: SpriteAtlasError.self) { try tooMany.pack() }

    var duplicate = SpriteAtlasBuilder()
    duplicate.add(name: "same", image: solid(2, 2, [0, 0, 0, 0]))
    duplicate.add(name: "same", image: solid(2, 2, [0, 0, 0, 0]))
    #expect(throws: SpriteAtlasError.self) { try duplicate.pack() }
}

@Test func packingIsDeterministic() throws {
    func build() throws -> SpriteAtlasImage {
        var b = SpriteAtlasBuilder()
        for i in 0..<20 { b.add(name: "f\(i)", image: solid(4 + i % 5, 6 + i % 7, [UInt8(i), 9, 9, 255])) }
        return try b.pack()
    }
    let a = try build(), b = try build()
    #expect(a.image.pixels == b.image.pixels && a.frames == b.frames)
}

@Test func gridSheetSlicesFramesInReadingOrder() {
    let image = solid(40, 20, [255, 255, 255, 255])
    let sheet = SpriteAtlasImage.grid(image: image, columns: 4, rows: 2, namePrefix: "t")
    #expect(sheet.frames.count == 8)
    #expect(sheet.frames[0].name == "t0" && sheet.frames[5].name == "t5")
    #expect((sheet.frames[5].x, sheet.frames[5].y, sheet.frames[5].width, sheet.frames[5].height) == (10, 10, 10, 10))
    #expect(sheet.frames[5].uvMin == Vec2(0.25, 0.5) && sheet.frames[5].uvMax == Vec2(0.5, 1))

    let inset = SpriteAtlasImage.grid(image: image, columns: 4, rows: 2, inset: 0.5)
    #expect(inset.frames[0].uvMin == Vec2(0.5 / 40, 0.5 / 20))
}

// MARK: Batching

@MainActor private func frames(_ count: Int, texture: GPUTexture) -> SpriteAtlas {
    let sheet = SpriteAtlasImage.grid(image: solid(count * 4, 4, [255, 255, 255, 255]), columns: count, rows: 1)
    return SpriteAtlas(texture: texture, frames: sheet.frames)
}

@MainActor @Test func spritesOfOneAtlasShareOneDraw() {
    let atlas = frames(4, texture: StubTexture())
    let batch = SpriteBatch()
    for i in 0..<100 { batch.draw(atlas, frame: i % 4, position: Vec2(Float(i), 0)) }
    let data = batch.prepare()
    #expect(data.draws.count == 1 && data.draws[0].spriteCount == 100)
    #expect(data.vertices.count == 400 && data.indices.count == 600)
}

@MainActor @Test func textureAndBlendChangesSplitDrawsAndOrderWins() {
    let a = frames(1, texture: StubTexture()), b = frames(1, texture: StubTexture())
    let batch = SpriteBatch()
    // Same order: grouped by texture even though submitted alternately.
    for i in 0..<6 { batch.draw(i % 2 == 0 ? a : b, frame: 0, position: .zero) }
    #expect(batch.prepare().draws.count == 2)
    batch.clear()
    // A different blend mode is a different draw.
    batch.draw(a, frame: 0, position: .zero)
    batch.draw(a, frame: 0, position: .zero, blend: .opaque)
    #expect(batch.prepare().draws.count == 2)
    batch.clear()
    // Order interleaves the textures: the sprites between them can't be merged.
    batch.draw(a, frame: 0, position: .zero, order: 0)
    batch.draw(b, frame: 0, position: .zero, order: 1)
    batch.draw(a, frame: 0, position: .zero, order: 2)
    batch.draw(a, frame: 0, position: .zero, order: 3)
    let data = batch.prepare()
    #expect(data.draws.map(\.spriteCount) == [1, 1, 2])
    #expect(data.draws[1].texture === b.texture)
}

@MainActor @Test func submissionOrderBreaksTiesWhenNotSortingByTexture() {
    let a = frames(1, texture: StubTexture()), b = frames(1, texture: StubTexture())
    let batch = SpriteBatch()
    batch.sortsByTexture = false
    for i in 0..<4 { batch.draw(i % 2 == 0 ? a : b, frame: 0, position: .zero) }
    #expect(batch.prepare().draws.count == 4)
}

@MainActor @Test func quadGeometryAppliesPivotRotationScaleAndFlip() {
    let atlas = frames(1, texture: StubTexture())  // one 4x4 frame
    let batch = SpriteBatch()
    batch.draw(atlas, frame: 0, position: Vec2(10, 20), scale: Vec2(2, 1), pivot: Vec2(0, 0))
    var v = batch.prepare().vertices
    #expect(v[0].position == Vec2(10, 20) && v[2].position == Vec2(18, 24))
    batch.clear()
    // A quarter turn about the center swaps the extents.
    batch.draw(atlas, frame: 0, position: .zero, rotation: .pi / 2)
    v = batch.prepare().vertices
    #expect(abs(v[0].position.x - 2) < 1e-5 && abs(v[0].position.y + 2) < 1e-5)
    batch.clear()
    batch.draw(atlas, frame: 0, position: .zero, flip: .horizontal)
    v = batch.prepare().vertices
    #expect(v[0].uv.x == 1 && v[1].uv.x == 0)
    #expect(v[0].uv.y == 1 && v[3].uv.y == 0)
}

@MainActor @Test func cameraMapsWorldToClipSpace() {
    let camera = SpriteCamera(position: Vec2(100, 50), zoom: 2, viewport: Vec2(800, 600))
    let m = camera.viewProjection
    let center = m * Vec4(100, 50, 0, 1)
    #expect(abs(center.x) < 1e-6 && abs(center.y) < 1e-6)
    let corner = m * Vec4(100 + 200, 50 + 150, 0, 1)  // half the viewport / zoom away
    #expect(abs(corner.x - 1) < 1e-5 && abs(corner.y - 1) < 1e-5)
    #expect(camera.worldPosition(ofPixel: Vec2(400, 300)) == Vec2(100, 50))
    #expect(camera.worldPosition(ofPixel: Vec2(800, 0)) == Vec2(300, 200))
}

// MARK: Components and flipbooks

@MainActor @Test func spriteComponentRoundTripsThroughJSON() throws {
    let sprite = Sprite(atlas: SpriteAtlasHandle("hero"), frame: 3, tint: Vec4(1, 0.5, 0.25, 1), flipX: true,
                        order: 2, blend: .opaque, size: Vec2(8, 8))
    let data = try JSONEncoder().encode(sprite)
    #expect(try JSONDecoder().decode(Sprite.self, from: data) == sprite)
    let minimal = try JSONDecoder().decode(Sprite.self, from: Data(#"{"atlas":"hero"}"#.utf8))
    #expect(minimal == Sprite(atlas: SpriteAtlasHandle("hero")))
}

@Test func loopOnceAndPingPongStepThroughFrames() {
    let frames = [10, 11, 12]
    let loop = SpriteClip("l", frames: frames, fps: 10, mode: .loop)
    #expect((0..<7).map { loop.frame(at: Float($0) / 10 + 0.01) } == [10, 11, 12, 10, 11, 12, 10])
    let once = SpriteClip("o", frames: frames, fps: 10, mode: .once)
    #expect((0..<5).map { once.frame(at: Float($0) / 10 + 0.01) } == [10, 11, 12, 12, 12])
    #expect(!once.isFinished(at: 0.29) && once.isFinished(at: 0.31))
    #expect(!loop.isFinished(at: 100))
    let ping = SpriteClip("p", frames: frames, fps: 10, mode: .pingPong)
    #expect((0..<9).map { ping.frame(at: Float($0) / 10 + 0.01) } == [10, 11, 12, 11, 10, 11, 12, 11, 10])
    #expect(abs(ping.duration - 0.4) < 1e-6)
}

@MainActor @Test func animatorAdvancesFramesFiresEventsAndFinishes() {
    let clip = SpriteClip("hit", frames: [5, 6, 7], fps: 10, mode: .once, events: [SpriteClipEvent(step: 1, name: "impact")])
    var animator = SpriteAnimator(clips: [clip, SpriteClip("idle", frames: [0, 1], fps: 2)], current: "hit")
    #expect(animator.advance(dt: 0) == 5 && animator.events.isEmpty)
    #expect(animator.advance(dt: 0.1) == 6 && animator.events == ["impact"])
    #expect(animator.advance(dt: 0.1) == 7 && animator.events.isEmpty && !animator.isFinished)
    #expect(animator.advance(dt: 0.1) == 7 && animator.isFinished && animator.justFinished)
    #expect(animator.advance(dt: 5) == 7 && !animator.justFinished && animator.events.isEmpty)
    animator.play("idle")
    #expect(animator.advance(dt: 0) == 0 && !animator.isFinished)
    #expect(animator.advance(dt: 0.5) == 1)
}

@MainActor @Test func animatorSplitsOfDtGiveTheSameFramesAndEvents() {
    let clip = SpriteClip("c", frames: [0, 1, 2, 3], fps: 8, mode: .loop, events: [SpriteClipEvent(step: 2, name: "step")])
    var whole = SpriteAnimator(clips: [clip]), split = whole
    var wholeEvents = 0, splitEvents = 0
    for _ in 0..<10 {
        whole.advance(dt: 0.25)
        wholeEvents += whole.events.count
        for _ in 0..<4 {
            split.advance(dt: 0.0625)
            splitEvents += split.events.count
        }
    }
    #expect(wholeEvents == splitEvents && wholeEvents == 5)
    #expect(whole.currentClip?.frame(at: whole.time) == split.currentClip?.frame(at: split.time))
}

@MainActor @Test func animationSystemWritesTheSpriteFrame() {
    let world = World()
    let e = world.spawn(Sprite(atlas: SpriteAtlasHandle("a")),
                        SpriteAnimator(clips: [SpriteClip("walk", frames: [4, 5, 6], fps: 10)]))
    var events: [String] = []
    world.addSpriteAnimationSystem { _, name in events.append(name) }
    world.update(dt: 0.25)
    #expect(world.get(Sprite.self, for: e)?.frame == 6)
    world.update(dt: 0.1)
    #expect(world.get(Sprite.self, for: e)?.frame == 4)
    #expect(events.isEmpty)
}
