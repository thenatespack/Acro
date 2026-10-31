import Engine
import Foundation

// A small game as a game module (see Sources/Engine/GameModule/GameModule.swift): two
// components, their systems and a standalone `Game`. The editor loads it with
// `swift run Editor --game SampleGame`, offers Bobber and Orbiter in Add Component and runs
// the systems in play mode; "Reload Game Code" rebuilds and reloads it with the scene kept.
// `swift run GameRunner SampleGame` runs it without the editor.

/// Bobs its entity up and down around where it was when play started.
public struct Bobber: Component, Equatable, Sendable {
    public static let componentName = "Bobber"
    public static var fieldHints: [String: FieldHints] {
        ["amplitude": FieldHints(range: 0...10, step: 0.05, tooltip: "Units up and down"),
         "speed": FieldHints(range: 0...20, step: 0.1, tooltip: "Radians per second"),
         "origin": FieldHints(tooltip: "Set when play starts")]
    }

    public var amplitude: Float = 0.5
    public var speed: Float = 2
    public var phase: Float = 0
    /// The local position it bobs around; taken from the transform on the first frame.
    public var origin: Vec3?

    public init(amplitude: Float = 0.5, speed: Float = 2, phase: Float = 0) {
        self.amplitude = amplitude
        self.speed = speed
        self.phase = phase
    }
}

/// Circles its entity around a center (where it was when play started) in the XZ plane.
public struct Orbiter: Component, Equatable, Sendable {
    public static let componentName = "Orbiter"
    public static var fieldHints: [String: FieldHints] {
        ["radius": FieldHints(range: 0...50, step: 0.05), "speed": FieldHints(step: 0.05, tooltip: "Radians per second")]
    }

    public var radius: Float = 1.5
    public var speed: Float = 1
    /// The local position it circles; taken from the transform on the first frame.
    public var center: Vec3?

    public init(radius: Float = 1.5, speed: Float = 1) {
        self.radius = radius
        self.speed = speed
    }
}

/// State outside the ECS, which a reload would otherwise reset (each load is a fresh copy of
/// the library, statics included): handed from the old code to the new by the reload hooks.
struct SampleGameStats: Codable {
    /// Frames the bob system has run, over every reload.
    var frames = 0
    /// Reloads it has survived.
    var reloads = 0

    init() {}

    /// Tolerant: the previous version may have saved fewer (or other) fields.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frames = try container.decodeIfPresent(Int.self, forKey: .frames) ?? 0
        reloads = try container.decodeIfPresent(Int.self, forKey: .reloads) ?? 0
    }
}

@MainActor
enum SampleGameState {
    static var stats = SampleGameStats()
}

/// The module's entry point (`GameModuleABI.entryPoint`).
@_cdecl("swift_game_engine_module_v1")
public func registerSampleGame(_ module: UnsafeMutableRawPointer) -> Int32 {
    GameModule.register(module) { game in
        game.name = "SampleGame"
        game.summary = "Bobbing and orbiting props"
        // Editor icons: SVG markup on a 24x24 box, or a built-in (Lucide) icon's name.
        game.component(Bobber.self, icon: #"<path d="M12 3v18"/><path d="m8 7 4-4 4 4"/><path d="m8 17 4 4 4-4"/>"#) { Bobber() }
        game.component(Orbiter.self, icon: "orbit") { Orbiter() }
        game.system("sample.bob") { world, _ in
            SampleGameState.stats.frames += 1
            SampleGameSystems.bob(world)
        }
        game.system("sample.orbit") { world, _ in SampleGameSystems.orbit(world) }
        game.makeGame = { SampleGameApp() }
        // Carry the stats across reloads.
        game.willUnload { SampleGameState.stats }
        game.didLoad(SampleGameStats.self) { [unowned game] saved in
            guard var stats = saved else { return }
            stats.reloads += 1
            SampleGameState.stats = stats
            game.summary = "Bobbing and orbiting props (\(stats.frames) frames, \(stats.reloads) reloads)"
        }
    }
}

@MainActor
enum SampleGameSystems {
    static func bob(_ world: World) {
        let t = Float(world.time.elapsed)
        world.queryMutating(Transform.self, Bobber.self) { _, transform, bobber in
            let origin = bobber.origin ?? transform.position
            bobber.origin = origin
            transform.position.y = origin.y + sinf(t * bobber.speed + bobber.phase) * bobber.amplitude
        }
    }

    static func orbit(_ world: World) {
        let dt = world.time.delta
        world.queryMutating(Transform.self, Orbiter.self) { _, transform, orbiter in
            let center = orbiter.center ?? transform.position - Vec3(orbiter.radius, 0, 0)
            orbiter.center = center
            var offset = transform.position - center
            offset.y = 0
            let angle = atan2f(offset.z, offset.x) + orbiter.speed * dt
            transform.position = Vec3(center.x + cosf(angle) * orbiter.radius, transform.position.y,
                                      center.z + sinf(angle) * orbiter.radius)
        }
    }
}

/// SampleGame on its own (GameRunner): a few props on a floor, bobbing and orbiting.
@MainActor
final class SampleGameApp: Game {
    private let world = World()
    private var renderer: SceneRenderer!

    func setup(engine: Engine) throws {
        renderer = try SceneRenderer(engine: engine)
        try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                      key: "checker")
        _ = world.spawn(Transform.looking(from: Vec3(0, 5, 10), at: Vec3(0, 1, 0)),
                        Camera(fovY: .pi / 3.4, near: 0.1, far: 200, clearColor: Vec4(0.55, 0.62, 0.74, 1)))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.35))), DirectionalLight(intensity: 1.3, shadowExtent: 14))
        _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(20, 1, 20)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("checker"), castsShadows: false))
        for i in 0..<5 {
            let x = Float(i) * 1.6 - 3.2
            _ = world.spawn(Transform(position: Vec3(x, 0.8, 0), scale: Vec3(repeating: 0.7)),
                            MeshRenderer(mesh: i % 2 == 0 ? .cube : .sphere, tint: Vec3(0.3 + Float(i) * 0.15, 0.5, 0.9 - Float(i) * 0.15)),
                            Bobber(amplitude: 0.4, speed: 2, phase: Float(i)))
        }
        _ = world.spawn(Transform(position: Vec3(2, 2.2, -2), scale: Vec3(repeating: 0.5)),
                        MeshRenderer(mesh: .sphere, tint: Vec3(0.95, 0.75, 0.25)), Orbiter(radius: 2, speed: 1.2))
        world.addSystem("sample.bob") { SampleGameSystems.bob($0) }
        world.addSystem("sample.orbit") { SampleGameSystems.orbit($0) }
        engine.world = world
    }

    func update(engine: Engine, dt: Float) {}

    func renderOffscreen(engine: Engine, frame: Frame) {
        renderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func render(engine: Engine, pass: RenderPass) {
        renderer.draw(pass)
    }
}
