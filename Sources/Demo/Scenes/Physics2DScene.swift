import Engine
import Foundation

/// Drives the kinematic pinball paddle: turns its `Transform` every fixed step (the physics
/// sync turns that into velocity, so it flings what it touches).
struct Paddle2D: Component, Codable, Sendable {
    var speed: Float
}

/// 2D rigid bodies (`PhysicsWorld2D` driven by `Collider2D` / `RigidBody2D` / `Joint2D`
/// components) drawn with the sprite renderer: a pyramid of boxes (left), a bridge of
/// revolute-jointed planks with crates on it (top left), a car with motorized wheels driving
/// back and forth over a chain-shape terrain (bottom right), and a pinball-style pen (top
/// right) with bouncy bumpers, balls, two one-way shelves and a kinematic paddle that flings
/// the balls up through them. Every image is generated here, in meters (1280x720 shows 32x18).
///
/// Keys: **G** toggles the physics debug view (shapes, contacts, joints; drawn through
/// `DebugDraw`), **F** drops a few shapes, **R** resets; drag any body with the left mouse
/// button (a mouse joint). Fixed timestep and a seeded generator, so screenshots are
/// deterministic.
final class Physics2DScene: DemoScene {
    static let name = "physics2d"
    static let summary = "2D rigid bodies: box pyramid, revolute bridge, motorized car on chain terrain, pinball bumpers and one-way shelves, mouse joint"

    private let renderer: Renderer
    private let sprites: SpriteRenderer
    private let atlas: SpriteAtlas
    private let debug = DebugDraw()
    private var world = World()
    private var physics = PhysicsWorld2D()
    private var debugMode = false
    private var mouseJoint: Joint2DID?
    private var uiSize = Vec2(1280, 720)
    private var rng = SplitMix64(state: 5)
    private var chassis = Entity.invalid
    private var wheels: [Entity] = []
    private var carDirection: Float = 1
    private var dropped = 0
    private var time: Float = 0

    private static let area = Vec2(32, 18)
    private static let carSpeed: Float = 7
    private static let terrain: [Vec2] = {
        var points = [Vec2(0, 1), Vec2(12, 1)]
        var x: Float = 12.5
        while x <= 32.001 {
            let s = sinf(0.4 * (x - 12))
            points.append(Vec2(x, 1 + 0.9 * s * s))
            x += 0.5
        }
        return points
    }()

    init(renderer: Renderer) throws {
        self.renderer = renderer
        sprites = try SpriteRenderer(device: renderer.device)
        var builder = SpriteAtlasBuilder(extrude: 1, spacing: 1)
        for (name, size, shade) in Self.images { builder.add(name: name, image: Self.image(width: size.0, height: size.1, shade)) }
        atlas = try SpriteAtlas(device: renderer.device, packed: try builder.pack())
        atlas.pixelsPerUnit = 32
        sprites.registerAtlas(atlas, key: "bodies")
        build()
    }

    // MARK: Procedural images

    /// A grey-scale image (tinted at draw time); `shade` takes pixel coordinates (y down) and
    /// returns a brightness, or nil outside the shape. 4x4 supersampled coverage.
    private static func image(width: Int, height: Int, _ shade: (Vec2) -> Float?) -> Image {
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                var covered = 0
                var sum: Float = 0
                for sy in 0..<4 {
                    for sx in 0..<4 {
                        if let s = shade(Vec2(Float(x) + (Float(sx) + 0.5) / 4, Float(y) + (Float(sy) + 0.5) / 4)) {
                            covered += 1
                            sum += s
                        }
                    }
                }
                let i = (y * width + x) * 4
                let value = covered > 0 ? sum / Float(covered) : 1
                for c in 0..<3 { pixels[i + c] = UInt8(min(max(value, 0), 1) * 255) }
                pixels[i + 3] = UInt8(covered * 255 / 16)
            }
        }
        return Image(width: width, height: height, pixels: pixels)
    }

    /// Distance to a rounded box of half size `half` and corner radius `r`, centered on the origin.
    private static func roundBox(_ p: Vec2, half: Vec2, radius r: Float) -> Float {
        let q = Vec2(abs(p.x), abs(p.y)) - half + Vec2(repeating: r)
        return vecLength(Vec2(max(q.x, 0), max(q.y, 0))) + min(max(q.x, q.y), 0) - r
    }

    private static let images: [(String, (Int, Int), (Vec2) -> Float?)] = [
        ("white", (8, 8), { _ in 1 }),
        // A crate: dark border, bevelled face, cross braces.
        ("box", (32, 32), { p in
            let q = p - Vec2(16, 16)
            let d = roundBox(q, half: Vec2(16, 16), radius: 4)
            if d > 0 { return nil }
            if d > -2.5 { return 0.38 }
            if abs(abs(q.x) - abs(q.y)) < 1.3 { return 0.62 }
            return 0.78 + 0.2 * (1 - p.y / 32)
        }),
        // A disc with a spoke, so rolling reads.
        ("disc", (32, 32), { p in
            let q = p - Vec2(16, 16)
            let d = vecLength(q) - 15.5
            if d > 0 { return nil }
            if d > -2 { return 0.4 }
            if abs(q.y) < 1.1 && q.x > 0 { return 0.55 }
            return 0.7 + 0.3 * max(0, 1 - vecLength(p - Vec2(11, 10)) / 22)
        }),
        ("wheel", (32, 32), { p in
            let q = p - Vec2(16, 16), r = vecLength(q)
            if r > 15.5 { return nil }
            if r > 10.5 { return 0.22 }
            if r < 3 { return 0.5 }
            let a = atan2f(q.y, q.x)
            if abs(sinf(a * 2.5)) < 0.22 { return 0.45 }
            return 0.85
        }),
        ("bumper", (32, 32), { p in
            let r = vecLength(p - Vec2(16, 16))
            if r > 15.5 { return nil }
            if r > 13 { return 0.45 }
            if r > 9.5 { return 0.95 }
            if r > 7 { return 0.55 }
            return 1.0
        }),
        ("plank", (32, 8), { p in
            let d = roundBox(p - Vec2(16, 4), half: Vec2(16, 4), radius: 2)
            if d > 0 { return nil }
            if d > -1.2 { return 0.38 }
            if vecLength(Vec2(abs(p.x - 16) - 12.5, p.y - 4)) < 1.1 { return 0.5 }
            return 0.85
        }),
        ("platform", (32, 8), { p in
            let d = roundBox(p - Vec2(16, 4), half: Vec2(16, 4), radius: 1.5)
            if d > 0 { return nil }
            if d > -1 { return 0.4 }
            return Int(p.x / 4) % 2 == 0 ? 0.95 : 0.7
        }),
    ]

    // MARK: Building the world

    private func build() {
        world = World()
        physics = PhysicsWorld2D()
        physics.interpolatesPoses = true
        world.addPhysics2D(physics)
        mouseJoint = nil
        rng = SplitMix64(state: 5)
        dropped = 0
        carDirection = 1
        let physics = physics

        // The paddle turns before the physics step.
        world.addSystem("paddle2d", stage: .fixedUpdate, before: "physics2d") { world in
            let dt = world.time.delta
            world.queryMutating(Transform.self, Paddle2D.self) { _, transform, paddle in
                transform.rotation = (Quat(angle: paddle.speed * dt, axis: Vec3(0, 0, 1)) * transform.rotation).normalized
            }
        }
        // The car turns around at the ends of its track.
        world.addSystem("car2d", stage: .fixedUpdate, before: "physics2d") { [unowned self] world in
            guard let body = physics.body(for: chassis), let p = physics.pose(of: body)?.position else { return }
            let wanted: Float = p.x > 29.5 ? -1 : (p.x < 14.5 ? 1 : carDirection)
            guard wanted != carDirection else { return }
            carDirection = wanted
            for wheel in wheels { world.modify(Joint2D.self, for: wheel) { $0.motorSpeed = wanted * Self.carSpeed } }
        }

        buildScenery()
        buildPyramid()
        buildBridge()
        buildCar()
        buildPinball()
        world.propagateTransforms()
    }

    /// A box, circle or hull entity drawn by `frame`: `size` is the sprite's size in meters.
    @discardableResult
    private func spawn(_ frame: String, at p: Vec2, angle: Float = 0, size: Vec2, shape: ColliderShape2D, tint: Vec4,
                       motion: MotionType? = .dynamic, friction: Float = 0.6, restitution: Float = 0, density: Float = 1,
                       oneWay: Bool = false, order: Float = 0, velocity: Vec2 = .zero, joint: Joint2D? = nil) -> Entity {
        let e = world.spawn(
            Transform(position: Vec3(p.x, p.y, 0), rotation: Quat(angle: angle, axis: Vec3(0, 0, 1))),
            Sprite(atlas: SpriteAtlasHandle("bodies"), frame: atlas.index(named: frame)!, tint: tint, order: order, size: size),
            Collider2D(shape, friction: friction, restitution: restitution, density: density, isOneWay: oneWay))
        if let motion { world.add(RigidBody2D(motion, linearVelocity: velocity), to: e) }
        if let joint { world.add(joint, to: e) }
        return e
    }

    private func box(at p: Vec2, angle: Float = 0, half: Vec2, tint: Vec4, motion: MotionType? = .dynamic, friction: Float = 0.6,
                     restitution: Float = 0, order: Float = 0, joint: Joint2D? = nil) -> Entity {
        spawn("box", at: p, angle: angle, size: half * 2, shape: .box(halfExtents: half), tint: tint, motion: motion,
              friction: friction, restitution: restitution, order: order, joint: joint)
    }

    /// Walls, the ceiling, ledges, the terrain chain.
    private func buildScenery() {
        let slate = Vec4(0.16, 0.19, 0.25, 1)
        _ = box(at: Vec2(-0.5, 9), half: Vec2(0.5, 10), tint: slate, motion: nil)
        _ = box(at: Vec2(32.5, 9), half: Vec2(0.5, 10), tint: slate, motion: nil)
        _ = box(at: Vec2(16, 18.5), half: Vec2(17, 0.5), tint: slate, motion: nil)
        // Terrain: a chain collider, drawn as columns in `draw`.
        _ = world.spawn(Transform(), Collider2D(.chain(points: Self.terrain, isLoop: false), friction: 0.9), Name("Terrain"))
    }

    private func buildPyramid() {
        let size: Float = 0.8, rows = 7
        for row in 0..<rows {
            for k in 0..<(rows - row) {
                let x = 6.2 + (Float(k) - Float(rows - row - 1) / 2) * (size + 0.02)
                _ = box(at: Vec2(x, 1 + size / 2 + Float(row) * size), half: Vec2(repeating: size / 2),
                        tint: Vec4(hsv(0.04 + Float(row) * 0.025, 0.6, 0.95), 1), friction: 0.6)
            }
        }
    }

    /// Two ledges joined by ten planks, each hinged to the next; crates and balls on top.
    private func buildBridge() {
        let slate = Vec4(0.16, 0.19, 0.25, 1)
        let planks = 10
        let y: Float = 10.88
        let planksHalf = Vec2(0.5, 0.12)
        var planksList = [Entity](repeating: .invalid, count: planks)
        // Created back to front so each plank can name the next one in its joint.
        let right = box(at: Vec2(14.5, 10), half: Vec2(1.5, 1), tint: slate, motion: nil)
        var next = right
        for k in stride(from: planks - 1, through: 0, by: -1) {
            planksList[k] = spawn("plank", at: Vec2(3.5 + Float(k), y), size: planksHalf * 2, shape: .box(halfExtents: planksHalf),
                                  tint: Vec4(0.75, 0.55, 0.3, 1), friction: 0.7, density: 0.8, order: 1,
                                  joint: Joint2D(.revolute, connectedTo: next, anchor: Vec2(0.5, 0)))
            next = planksList[k]
        }
        _ = box(at: Vec2(1.5, 10), half: Vec2(1.5, 1), tint: slate, motion: nil, joint: Joint2D(.revolute, connectedTo: planksList[0], anchor: Vec2(1.5, 0.88)))
        for (k, x) in [Float(5), 8, 10.5].enumerated() {
            _ = box(at: Vec2(x, 12.1 + Float(k) * 0.2), angle: Float(k) * 0.2, half: Vec2(0.35, 0.35 + Float(k) * 0.08),
                    tint: Vec4(hsv(0.58 + Float(k) * 0.08, 0.55, 0.95), 1), order: 2)
        }
        for (k, x) in [Float(6.6), 9.2].enumerated() {
            _ = spawn("disc", at: Vec2(x, 12.4), size: Vec2(repeating: 0.7), shape: .circle(radius: 0.35),
                      tint: Vec4(hsv(0.9 + Float(k) * 0.05, 0.6, 1), 1), restitution: 0.3, order: 2)
        }
    }

    /// A chassis on two motorized wheels (revolute joints, the motor turns the wheel relative to the chassis).
    private func buildCar() {
        let start = Vec2(13.5, 2.3)
        chassis = box(at: start, half: Vec2(1.1, 0.3), tint: Vec4(0.9, 0.18, 0.15, 1), friction: 0.3, order: 4)
        wheels = []
        for dx in [Float(-0.8), 0.8] {
            let wheel = spawn("wheel", at: start + Vec2(dx, -0.4), size: Vec2(repeating: 0.8), shape: .circle(radius: 0.4),
                              tint: Vec4(0.55, 0.57, 0.62, 1), friction: 1.4, density: 1.2, order: 5,
                              joint: Joint2D(.revolute, connectedTo: chassis, anchor: .zero, enableMotor: true,
                                             motorSpeed: Self.carSpeed, maxMotorTorque: 14))
            wheels.append(wheel)
        }
    }

    /// The pen: two ramps into a gap with a spinning paddle, bumpers, shelves, balls.
    private func buildPinball() {
        let slate = Vec4(0.16, 0.19, 0.25, 1)
        _ = box(at: Vec2(17.25, 12.5), half: Vec2(0.25, 6), tint: slate, motion: nil)
        _ = box(at: Vec2(20.5, 8.3), angle: -0.35, half: Vec2(3, 0.15), tint: slate, motion: nil, friction: 0.3)
        _ = box(at: Vec2(28.5, 8.3), angle: 0.35, half: Vec2(3, 0.15), tint: slate, motion: nil, friction: 0.3)
        _ = box(at: Vec2(24.5, 6.3), half: Vec2(3.2, 0.3), tint: slate, motion: nil)
        let paddle = box(at: Vec2(24.5, 7.8), half: Vec2(1.3, 0.1), tint: Vec4(0.95, 0.75, 0.2, 1), motion: .kinematic,
                         friction: 0.4, restitution: 0.4, order: 3)
        world.add(Paddle2D(speed: 3), to: paddle)
        for p in [Vec2(20.5, 12.6), Vec2(24.5, 14), Vec2(28.5, 12.6), Vec2(22.4, 10.6), Vec2(26.6, 10.6)] {
            _ = spawn("bumper", at: p, size: Vec2(repeating: 1.1), shape: .circle(radius: 0.55), tint: Vec4(1.0, 0.45, 0.12, 1),
                      motion: nil, restitution: 1.2, order: 1)
        }
        for (p, w) in [(Vec2(19.2, 15), Float(1.2)), (Vec2(29.8, 15.3), 1.5)] {
            _ = spawn("platform", at: p, size: Vec2(w * 2, 0.3), shape: .box(halfExtents: Vec2(w, 0.15)),
                      tint: Vec4(0.25, 0.6, 1, 1), motion: nil, oneWay: true, order: 1)
        }
        for k in 0..<14 {
            let p = Vec2(18.4 + rng.next() * 12.6, 14.5 + Float(k % 4) * 0.7 + rng.next() * 0.3)
            _ = spawn("disc", at: p, size: Vec2(repeating: 0.56), shape: .circle(radius: 0.28),
                      tint: Vec4(hsv(Float(k) / 14, 0.55, 1), 1), friction: 0.2, restitution: 0.55, order: 4,
                      velocity: Vec2(rng.next() * 4 - 2, 0))
        }
    }

    /// Drops a few random shapes over the pyramid and the bridge.
    private func drop() {
        for k in 0..<4 {
            let x = 2 + rng.next() * 12, y = 14 + Float(k) * 0.9
            let tint = Vec4(hsv(rng.next(), 0.6, 1), 1)
            if rng.next() < 0.5 {
                _ = box(at: Vec2(x, y), angle: rng.next() * 3, half: Vec2(0.25 + rng.next() * 0.2, 0.25 + rng.next() * 0.2), tint: tint, order: 6)
            } else {
                let r = 0.2 + rng.next() * 0.2
                _ = spawn("disc", at: Vec2(x, y), size: Vec2(repeating: r * 2), shape: .circle(radius: r), tint: tint,
                          restitution: 0.3, order: 6)
            }
            dropped += 1
        }
    }

    // MARK: DemoScene

    var lighting: Lighting { Lighting(fogColor: Vec3(0.008, 0.01, 0.02)) }

    var status: String {
        "\(physics.bodyCount) bodies, \(physics.awakeBodyCount) awake, \(physics.touchingContactCount) contacts, \(sprites.stats.drawCalls) draw calls"
    }

    /// The camera's zoom in points per meter, and where the window's center is in the world.
    private func worldPoint(ofPoint p: Vec2) -> Vec2 {
        let zoom = min(uiSize.x / Self.area.x, uiSize.y / Self.area.y)
        return Self.area / 2 + Vec2(p.x - uiSize.x / 2, uiSize.y / 2 - p.y) / zoom
    }

    func update(input: Input, dt: Float, time: Float) {
        self.time = time
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.g) { debugMode.toggle() }
        if input.wasPressed(.f) { drop() }

        // Dragging: grab the topmost dynamic body under the cursor with a mouse joint.
        let cursor = worldPoint(ofPoint: input.mousePosition)
        if input.isDown(.left as MouseButton) {
            if let joint = mouseJoint {
                physics.setMouseTarget(joint, cursor)
            } else if input.wasPressed(.left as MouseButton),
                      let grabbed = physics.overlapPoint(cursor).last(where: { physics.motion(of: $0) == .dynamic }) {
                mouseJoint = physics.addMouseJoint(body: grabbed, target: cursor, maxForce: 800 * physics.mass(of: grabbed))
            }
        } else if let joint = mouseJoint {
            physics.removeJoint(joint)
            mouseJoint = nil
        }

        world.update(dt: Double(dt))
        world.propagateTransforms()
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        let batch = sprites.batch
        let white = atlas.index(named: "white")!
        /// A flat colored rectangle of `size` meters centered on `at`.
        func quad(at: Vec2, rotation: Float = 0, size: Vec2, tint: Vec4, order: Float, blend: SpriteBlend = .alpha) {
            let m = Mat4(translation: Vec3(at.x, at.y, 0), rotation: Quat(angle: rotation, axis: Vec3(0, 0, 1)), scale: .one)
            batch.draw(atlas, frame: white, transform: m, size: size, pivot: Vec2(0.5, 0.5), tint: tint, order: order, blend: blend)
        }

        // Sky: horizontal bands (opaque), wider than the view so any window shape is covered.
        for band in -6..<24 {
            let t = Float(band) / 18
            quad(at: Vec2(16, Float(band) + 0.5), size: Vec2(60, 1.05),
                 tint: Vec4(0.07 + 0.2 * (1 - t) * (1 - t), 0.1 + 0.28 * (1 - t) * (1 - t), 0.2 + 0.35 * (1 - t), 1),
                 order: -100, blend: .opaque)
        }
        // Terrain: a parallelogram column under every segment, with a grass strip on top.
        for i in 0..<(Self.terrain.count - 1) {
            let a = Self.terrain[i], b = Self.terrain[i + 1]
            for (depth, tint, order) in [(Float(8), Vec4(0.16, 0.1, 0.07, 1), Float(-20)), (0.28, Vec4(0.2, 0.62, 0.15, 1), -19)] {
                let d = b - a
                let m = Mat4(Vec4(d.x, d.y, 0, 0), Vec4(0, depth, 0, 0), Vec4(0, 0, 1, 0), Vec4(a.x, a.y - depth, 0, 1))
                batch.draw(atlas, frame: white, transform: m, size: Vec2(1, 1), pivot: Vec2(0, 0), tint: tint, order: order)
            }
        }

        // Bodies, from their (interpolated) transforms.
        sprites.draw(world: world)

        if debugMode {
            debug.removeAll()
            physics.drawDebug(into: debug, options: [.colliders, .contacts, .joints])
            let widthPerPoint = 1 / min(uiSize.x / Self.area.x, uiSize.y / Self.area.y)
            for depth in [DebugDepth.tested, .onTop] {
                for s in debug.segments[depth] ?? [] {
                    let a = Vec2(s.start.x, s.start.y), b = Vec2(s.end.x, s.end.y), d = b - a
                    quad(at: (a + b) / 2, rotation: atan2f(d.y, d.x),
                         size: Vec2(max(vecLength(d), 0.001), max(s.start.w, 1) * widthPerPoint * 0.5), tint: s.color, order: 100)
                }
            }
        }

        let size = renderer.targetSize
        let zoom = min(Float(size.width) / Self.area.x, Float(size.height) / Self.area.y)
        let camera = SpriteCamera(position: Self.area / 2, zoom: zoom, viewport: Vec2(Float(size.width), Float(size.height)))
        sprites.render(into: pass, viewProjection: camera.viewProjection)
    }

    /// Captions, in points over the area (the sprite camera's mapping applied to the window).
    func drawUI(_ ui: UIDrawList) {
        uiSize = ui.size
        let zoom = min(ui.size.x / Self.area.x, ui.size.y / Self.area.y)
        let origin = (ui.size - Self.area * zoom) / 2
        func label(_ text: String, _ x: Float, _ y: Float, size: Float = 0.4, alpha: Float = 0.9) {
            // Meters from the bottom-left of the area to points.
            let p = origin + Vec2(x, Self.area.y - y) * zoom
            ui.drawText(text, at: p + Vec2(1, 1), size: size * zoom * 1.0, color: UIColor(0, 0, 0, alpha * 0.8))
            ui.drawText(text, at: p, size: size * zoom * 1.0, color: UIColor(1, 1, 1, alpha))
        }
        label("2D physics: boxes, revolute bridge, motorized car, pinball (restitution 1.2), one-way shelves, mouse joint", 0.4, 17.9, size: 0.45)
        label("pyramid", 4.5, 8.2)
        label("bridge of revolute joints", 5.2, 14.1)
        label("car: chain terrain, motors", 17, 5.5)
        label("pinball: bumpers, kinematic paddle", 18.2, 17.1)
        label("G debug | F drop | R reset | drag with the mouse", 0.4, 0.5, alpha: 0.7)
    }
}

private func vecLength(_ v: Vec2) -> Float { (v.x * v.x + v.y * v.y).squareRoot() }
