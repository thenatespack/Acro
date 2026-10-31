import Engine
import Foundation

/// 2D sprites: 2800 animated sprites from one runtime-packed atlas in a single draw call over an
/// opaque tiled background (a second draw), flipbook characters from a nearest-filtered grid
/// sheet (ECS `Sprite` + `SpriteAnimator`, clip events flash the sprite with a component tween),
/// tweened dots showing every easing curve, a Hermite path, translucent discs sorted by
/// `order` instead of submission order, and flip / pivot / rotation. Every image is generated
/// here. Laid out in 1280x720 design units (y down in the comments below) and fitted to the
/// window; everything is driven by the animation clock and the fixed-step dt, so screenshots
/// are deterministic. The window title shows the sprite and draw-call counts.
final class SpritesScene: DemoScene {
    static let name = "sprites"
    static let summary = "2D sprites: batched atlas sprites, flipbook animation, easing tweens, sorting and alpha blending"

    private let renderer: Renderer
    private let sprites: SpriteRenderer
    private let shapes: SpriteAtlas
    private let creatures: SpriteAtlas
    private let world = World()
    private let tweens = TweenSystem()
    private let path = PathState()
    private var time: Float = 0
    private var lastX: [Entity: Float] = [:]

    private static let designSize = Vec2(1280, 720)
    private static let swarmColumns = 80, swarmRows = 35
    private static let easingFamilies = ["quad", "cubic", "quart", "sine", "expo", "back", "elastic", "bounce"]

    /// Position that is `y` down from the top of the design area, in the camera's y-up world.
    private static func at(_ x: Float, _ y: Float) -> Vec2 { Vec2(x, designSize.y - y) }

    init(renderer: Renderer) throws {
        self.renderer = renderer
        sprites = try SpriteRenderer(device: renderer.device)

        // Shapes: packed at runtime, with a 1 px extruded edge so rotated, scaled sprites stay clean.
        var builder = SpriteAtlasBuilder(extrude: 1, spacing: 1)
        for (name, inside) in Self.shapeFunctions { builder.add(name: name, image: Self.shapeImage(size: 32, inside)) }
        builder.add(name: "white", image: Image(width: 8, height: 8, pixels: [UInt8](repeating: 255, count: 8 * 8 * 4)))
        shapes = try SpriteAtlas(device: renderer.device, packed: try builder.pack())

        // Pixel-art creatures: a grid sheet (8 frames x 2 colors), drawn 4x with nearest filtering.
        let sheet = SpriteAtlasImage.grid(image: Self.creatureSheet(), columns: 8, rows: 2, namePrefix: "creature",
                                          pivot: Vec2(0.5, 0))
        creatures = try SpriteAtlas(device: renderer.device, packed: sheet, filter: .nearest)
        sprites.registerAtlas(shapes, key: "shapes")
        sprites.registerAtlas(creatures, key: "creatures")

        world.addTweenSystem(tweens)
        let tweens = tweens, world = world
        world.addSpriteAnimationSystem { entity, name in
            guard name == "land" else { return }
            // Flash white-hot, then settle back: a tween on the sprite component's tint.
            world.modify(Sprite.self, for: entity) { $0.tint = Vec4(4, 4, 4, 1) }
            tweens.tween(\Sprite.tint, of: entity, in: world, to: Vec4(1, 1, 1, 1), duration: 0.4, ease: .quadOut)
        }
        buildCharacters()
        buildEasingDots()
        buildPath()
        world.propagateTransforms()
    }

    // MARK: Procedural images

    private static let shapeFunctions: [(String, (Vec2) -> Bool)] = [
        ("disc", { ($0 * $0).sum() < 0.81 }),
        ("ring", { let r = sqrtf(($0 * $0).sum()); return r > 0.55 && r < 0.9 }),
        ("star", { p in
            let r = sqrtf((p * p).sum()), a = atan2f(p.y, p.x)
            return r < 0.3 + 0.62 * powf(abs(cosf(2.5 * a)), 3)
        }),
        ("diamond", { abs($0.x) + abs($0.y) < 0.9 }),
        ("round", { p in
            let q = Vec2(abs(p.x), abs(p.y)) - Vec2(repeating: 0.45)
            let outside = Vec2(max(q.x, 0), max(q.y, 0)); return sqrtf((outside * outside).sum()) + min(max(q.x, q.y), 0) < 0.3
        }),
        ("cross", { (abs($0.x) < 0.3 && abs($0.y) < 0.9) || (abs($0.y) < 0.3 && abs($0.x) < 0.9) }),
        // Lopsided on purpose: flips and rotations about the pivot are visible.
        ("glyph", { p in
            (p.x > -0.7 && p.x < -0.4 && abs(p.y) < 0.9) || (p.x > -0.7 && p.x < 0.6 && p.y < -0.6 && p.y > -0.9)
                || (p.x > -0.7 && p.x < 0.3 && abs(p.y) < 0.15)
        }),
    ]

    /// A white shape (straight alpha, 4x4 supersampled coverage) with a soft vertical shade, so a
    /// tint colors it. `inside` takes coordinates in -1...1, y down.
    private static func shapeImage(size: Int, _ inside: (Vec2) -> Bool) -> Image {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                var covered = 0
                for sy in 0..<4 {
                    for sx in 0..<4 {
                        let p = (Vec2(Float(x) + (Float(sx) + 0.5) / 4, Float(y) + (Float(sy) + 0.5) / 4) / Float(size)) * 2 - 1
                        if inside(p) { covered += 1 }
                    }
                }
                let shade = 0.72 + 0.28 * (1 - Float(y) / Float(size))
                let i = (y * size + x) * 4
                for c in 0..<3 { pixels[i + c] = UInt8(shade * 255) }
                pixels[i + 3] = UInt8(covered * 255 / 16)
            }
        }
        return Image(width: size, height: size, pixels: pixels)
    }

    /// 8 walk frames of a little creature in two colors (rows), 16x16 each, facing right.
    private static func creatureSheet() -> Image {
        let width = 8 * 16, height = 2 * 16
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        func set(_ x: Int, _ y: Int, _ rgb: (UInt8, UInt8, UInt8)) {
            let i = (y * width + x) * 4
            (pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3]) = (rgb.0, rgb.1, rgb.2, 255)
        }
        let bodies: [((UInt8, UInt8, UInt8), (UInt8, UInt8, UInt8))] = [
            ((92, 205, 112), (52, 140, 78)), ((248, 170, 60), (190, 106, 36)),
        ]
        for row in 0..<2 {
            for frame in 0..<8 {
                let ox = frame * 16, oy = row * 16, bob = frame % 2
                let (body, shade) = bodies[row]
                for y in (4 + bob)..<(12 + bob) {
                    for x in 3..<13 { set(ox + x, oy + y, y == 11 + bob ? shade : body) }
                }
                for (x, y) in [(9, 6), (10, 6), (9, 7), (10, 7)] { set(ox + x, oy + y + bob, (255, 255, 255)) }
                set(ox + 10, oy + 7 + bob, (20, 20, 30))
                // Two legs that take turns lifting.
                for (x, lifted) in [(4, frame % 4 < 2), (9, frame % 4 >= 2)] {
                    for y in (12 + bob)..<(lifted ? 15 : 16) {
                        set(ox + x, oy + y, shade)
                        set(ox + x + 1, oy + y, shade)
                    }
                }
            }
        }
        return Image(width: width, height: height, pixels: pixels)
    }

    // MARK: Entities

    /// Eight characters: four walk back and forth in lanes (loop clips at different speeds, a
    /// position tween with yoyo), two rock back and forth (ping-pong), two stomp (a `once` clip
    /// restarted when it finishes, flashing on its "land" event).
    private func buildCharacters() {
        func clip(_ name: String, _ color: Int, _ columns: [Int], fps: Float, mode: SpriteLoopMode,
                  events: [SpriteClipEvent] = []) -> SpriteClip {
            SpriteClip(name, frames: columns.map { color * 8 + $0 }, fps: fps, mode: mode, events: events)
        }
        let all = Array(0..<8)
        for i in 0..<8 {
            let color = i % 2
            let lane = Float(i % 4)
            let row = i / 4
            let ground = row == 0 ? Float(490) : Float(560)
            let x = 60 + lane * 150
            var clips: [SpriteClip]
            switch i {
            case 0...3: clips = [clip("walk", color, all, fps: [6, 8, 10, 14][i], mode: .loop)]
            case 4, 5: clips = [clip("rock", color, [0, 2, 4, 6], fps: i == 4 ? 6 : 10, mode: .pingPong)]
            default: clips = [clip("stomp", color, all, fps: 10, mode: .once, events: [SpriteClipEvent(step: 4, name: "land")])]
            }
            let entity = world.spawn(
                Transform(position: Vec3(Self.at(x, ground), 0), scale: Vec3(4, 4, 1)),
                Sprite(atlas: SpriteAtlasHandle("creatures"), order: 10 + Float(i) * 0.01),
                SpriteAnimator(clips: clips))
            if i < 4 {
                tweens.tween(\Transform.position, of: entity, in: world, to: Vec3(Self.at(x + 100, ground), 0),
                             duration: 2 + Float(i) * 0.4, ease: .sineInOut, repeatCount: -1, yoyo: true)
            }
        }
    }

    /// One dot per easing curve, sliding along a track and back (yoyo, forever). Linear first.
    private func buildEasingDots() {
        let names = ["linear"] + Self.easingFamilies.flatMap { family in ["In", "Out", "InOut"].map { family + $0 } }
        for (n, name) in names.enumerated() {
            let (x, y) = Self.easingCell(n)
            let hue = Float(n) / Float(names.count)
            let entity = world.spawn(
                Transform(position: Vec3(Self.at(x, y), 0), scale: Vec3(repeating: 0.4)),
                Sprite(atlas: SpriteAtlasHandle("shapes"), frame: shapes.index(named: "disc")!,
                       tint: Vec4(hsv(hue, 0.6, 1), 1), order: 6))
            tweens.tween(\Transform.position, of: entity, in: world, to: Vec3(Self.at(x + Self.trackLength, y), 0),
                         duration: 1.6, ease: Easing(rawValue: name)!, repeatCount: -1, yoyo: true)
        }
    }

    private static let trackLength: Float = 112

    /// Where the dot of easing `n` starts (design units, y down): 9 columns by 3 rows.
    private static func easingCell(_ n: Int) -> (x: Float, y: Float) {
        let (column, row) = n == 0 ? (0, 0) : ((n - 1) / 3 + 1, (n - 1) % 3)
        return (Float(column) * 142 + 14, 638 + Float(row) * 36)
    }

    /// A Hermite path through the swarm (a `Vec2` curve) and a scale pulse (a `Float` curve with
    /// a step key), both played back and forth through tweens.
    private func buildPath() {
        let points = [Vec2(60, 380), Vec2(380, 110), Vec2(700, 320), Vec2(1010, 90), Vec2(1220, 360)]
        let positions = AnimationCurve<Vec2>(keys: points.enumerated().map { i, p in
            Keyframe(Float(i), Self.at(p.x, p.y), interpolation: .hermite)
        })
        let pulse = AnimationCurve<Float>(keys: [
            Keyframe(0, 1.4), Keyframe(0.5, 2.6, interpolation: .hermite), Keyframe(1, 1.4, interpolation: .step),
            Keyframe(2, 2.2), Keyframe(3, 1.4, interpolation: .hermite), Keyframe(4, 1.4),
        ])
        let path = path
        tweens.play(positions, speed: 0.5, repeatCount: -1, yoyo: true) { path.position = $0 }
        tweens.play(pulse, speed: 0.5, repeatCount: -1, yoyo: true) { path.scale = $0 }
    }

    // MARK: DemoScene

    var lighting: Lighting { Lighting(fogColor: Vec3(0.008, 0.01, 0.02)) }

    var status: String {
        "\(sprites.stats.sprites) sprites, \(sprites.stats.drawCalls) draw calls"
    }

    func update(input: Input, dt: Float, time: Float) {
        self.time = time
        world.update(dt: Double(dt))
        // Walkers face where they are going; the stompers start again when they finish.
        world.queryMutating(Transform.self, Sprite.self, SpriteAnimator.self) { entity, transform, sprite, animator in
            let x = transform.position.x
            if let previous = lastX[entity], abs(x - previous) > 1e-4 { sprite.flipX = x < previous }
            lastX[entity] = x
            if animator.justFinished { animator.play("stomp", restart: true) }
        }
        world.propagateTransforms()
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        let batch = sprites.batch
        let shapeFrame = { (name: String) in self.shapes.index(named: name)! }
        let white = shapeFrame("white")

        // Opaque checkered backdrop: a second blend mode, so a second draw.
        for row in 0..<9 {
            for column in 0..<16 {
                let shade: Float = (row + column) % 2 == 0 ? 0.02 : 0.035
                batch.draw(shapes, frame: white, position: Self.at(Float(column) * 80 + 40, Float(row) * 80 + 40),
                           scale: Vec2(10, 10), tint: Vec4(shade * 0.6, shade * 0.8, shade * 1.6, 1), order: -100,
                           blend: .opaque)
            }
        }

        // The swarm: every sprite moves, spins, pulses and shifts hue with the clock.
        let t = time
        let swarmFrames = ["disc", "ring", "star", "diamond", "round", "cross"].map(shapeFrame)
        for row in 0..<Self.swarmRows {
            for column in 0..<Self.swarmColumns {
                let i = row * Self.swarmColumns + column
                let f = Float(i)
                let base = Vec2(24 + Float(column) * 15.5, 22 + Float(row) * 11)
                let offset = Vec2(cosf(t * 0.9 + f * 0.37), sinf(t * 1.3 + f * 0.21)) * 5
                let scale = 0.36 + 0.1 * sinf(t * 2 + f * 0.1)
                let hue = (Float(column) / Float(Self.swarmColumns) + t * 0.05).truncatingRemainder(dividingBy: 1)
                batch.draw(shapes, frame: swarmFrames[(i * 7) % 6], position: Self.at(base.x + offset.x, base.y + offset.y),
                           rotation: t * (0.4 + 0.6 * Float(i % 5) / 4) + f, scale: Vec2(repeating: scale),
                           tint: Vec4(hsv(hue, 0.6, 1), 0.9), order: Float(i % 4))
            }
        }

        // The Hermite path rider.
        batch.draw(shapes, frame: shapeFrame("star"), position: path.position, rotation: -t * 2,
                   scale: Vec2(repeating: path.scale), tint: Vec4(1.6, 1.2, 0.3, 1), order: 20)
        batch.draw(shapes, frame: shapeFrame("ring"), position: path.position, scale: Vec2(repeating: path.scale * 1.6),
                   tint: Vec4(1, 1, 1, 0.8), order: 19)

        // Translucent discs, submitted red, green, blue but drawn green, blue, red by `order`.
        let disc = shapeFrame("disc")
        for (center, tint, order) in [(Vec2(770, 500), Vec4(1, 0.1, 0.1, 0.6), Float(3)),
                                      (Vec2(830, 500), Vec4(0.1, 1, 0.2, 0.6), 1),
                                      (Vec2(800, 552), Vec4(0.15, 0.3, 1, 0.6), 2)] {
            batch.draw(shapes, frame: disc, position: Self.at(center.x, center.y), scale: Vec2(repeating: 3.2), tint: tint,
                       order: 30 + order)
        }

        // Flip, pivot and rotation of a lopsided glyph (64 px, pivot at the bottom-left unless noted).
        let glyph = shapeFrame("glyph")
        let glyphSize = Vec2(repeating: 2)
        batch.draw(shapes, frame: glyph, position: Self.at(940, 540), scale: glyphSize, order: 40)
        batch.draw(shapes, frame: glyph, position: Self.at(1020, 540), scale: glyphSize, flip: .horizontal, order: 40)
        batch.draw(shapes, frame: glyph, position: Self.at(1100, 540), scale: glyphSize, flip: .vertical, order: 40)
        batch.draw(shapes, frame: glyph, position: Self.at(1210, 520), rotation: sinf(t) * 1.2, scale: glyphSize,
                   pivot: Vec2(0.1, 0.1), tint: Vec4(1, 0.7, 0.3, 1), order: 40)

        // Easing tracks behind the dots.
        for n in 0..<25 {
            let (x, y) = Self.easingCell(n)
            batch.draw(shapes, frame: white, position: Self.at(x + Self.trackLength / 2, y), scale: Vec2(Self.trackLength / 8, 0.25),
                       tint: Vec4(0.25, 0.28, 0.35, 1), order: 5)
        }

        // Entities (characters and easing dots) queue into the same batch.
        sprites.draw(world: world)

        let size = renderer.targetSize
        let zoom = min(Float(size.width) / Self.designSize.x, Float(size.height) / Self.designSize.y)
        let camera = SpriteCamera(position: Self.designSize / 2, zoom: zoom, viewport: Vec2(Float(size.width), Float(size.height)))
        sprites.render(into: pass, viewProjection: camera.viewProjection)
    }

    /// Captions, in points over the design area (the sprite camera's mapping applied to the window).
    func drawUI(_ ui: UIDrawList) {
        let zoom = min(ui.size.x / Self.designSize.x, ui.size.y / Self.designSize.y)
        let origin = (ui.size - Self.designSize * zoom) / 2
        func label(_ text: String, _ x: Float, _ y: Float, size: Float = 12, alpha: Float = 0.9) {
            let p = origin + Vec2(x, y) * zoom
            ui.drawText(text, at: p + Vec2(1, 1), size: size * zoom, color: UIColor(0, 0, 0, alpha * 0.8))
            ui.drawText(text, at: p, size: size * zoom, color: UIColor(1, 1, 1, alpha))
        }
        label("2800 sprites: one atlas, one draw call (plus the opaque backdrop)", 24, 8, size: 14)
        label("flipbook: loop (6, 8, 10, 14 fps) | ping-pong | once + event flash", 24, 418)
        label("alpha + order 3, 1, 2", 712, 600)
        label("flipX | flipY | pivot + rotation", 930, 582)
        label("Hermite path (Vec2 curve) + scale curve (Float, step key)", 700, 430, alpha: 0.7)
        let names = ["linear"] + Self.easingFamilies.flatMap { family in ["In", "Out", "InOut"].map { family + $0 } }
        for (n, name) in names.enumerated() {
            let (x, y) = Self.easingCell(n)
            label(name, x - 8, y - 22, size: 10, alpha: 0.75)
        }
    }
}

/// Where the path tween last put the rider.
private final class PathState {
    var position = Vec2.zero
    var scale: Float = 1.4
}
