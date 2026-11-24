import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// Navigation meshes and crowds: a level with two floors (the ground, and two decks 3 m up
/// joined by a bridge over the ground), a ramp from the ground up to the west deck and a one-way
/// jump link off the east deck. The navmesh is baked from the colliders (`world.bakeNavigation`)
/// and drawn over the level: polygons tinted by region, the jump link as an arc, each agent's
/// path. Behavior tree agents patrol across it: up the ramp, over the bridge, under it, and off
/// the east deck with a jump; agents walking at once avoid each other (ORCA).
///
/// N toggles the overlay, R restarts. Deterministic under ENGINE_SCREENSHOT (fixed dt): the
/// scene starts a few seconds in, with agents on the ramp, the bridge and in the air.
final class NavMeshScene: DemoScene {
    static let name = "navmesh"
    static let summary = "navmesh: two floors, a ramp, a bridge and a jump link, behavior tree agents pathing across and avoiding each other"

    private var world = World()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private var cameraEntity = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private var agents: [Entity] = []
    private var overlay = true
    private var polygons = 0
    private var bakeMilliseconds = 0.0

    private static let sky = Vec3(0.62, 0.72, 0.84)
    private static let tree = "navmesh.patrol"

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.42, 0.44, 0.4, 1), checker: true, roughness: 0.9), key: "nav.floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.6), key: "nav.matte")
        BehaviorTreeLibrary.register(BehaviorTree(nodes: [BehaviorNode("walk", .patrol, ["key": .string("route"), "loop": .bool(true),
                                                                                           "wait": .double(0.4), "arriveDistance": .double(0.3)])],
                                                  speed: 3, turnSpeed: 8), as: Self.tree)
        build()
    }

    private func box(_ name: String, center: Vec3, half: Vec3, rotation: Quat = .identity, tint: Vec3, material: String = "nav.matte") {
        world.spawn(Name(name), Transform(position: center, rotation: rotation, scale: half * 2),
                    MeshRenderer(mesh: .cube, material: MaterialHandle(material), tint: tint),
                    Collider(.box(Vec3(repeating: 0.5))))
    }

    /// (Re)creates the world.
    private func build() {
        world = World()
        sceneRenderer.resetMotion()
        cameraEntity = world.spawn(Transform.looking(from: Vec3(26, 24, 34), at: Vec3(1, 1, 3)),
                                   Camera(fovY: .pi / 3.5, near: 0.3, far: 200, clearColor: Vec4(Self.sky, 1)))
        world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.004))
        world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.3))), DirectionalLight(intensity: 1.6, shadowExtent: 34))

        // The level (the same as NavMeshTests' level).
        box("Ground", center: Vec3(2.5, -0.5, 4), half: Vec3(17.5, 0.5, 16), tint: Vec3(1, 1, 1), material: "nav.floor")
        box("West deck", center: Vec3(-9, 2.75, 0), half: Vec3(5, 0.25, 9), tint: Vec3(0.75, 0.62, 0.48))
        box("East deck", center: Vec3(9, 2.75, 0), half: Vec3(5, 0.25, 9), tint: Vec3(0.75, 0.62, 0.48))
        box("Bridge", center: Vec3(0, 2.85, 0), half: Vec3(4.05, 0.15, 1), tint: Vec3(0.55, 0.4, 0.3))
        let run: Float = 8, rise: Float = 3
        let slope = (run * run + rise * rise).squareRoot()
        let normal = Vec3(0, run, rise) / slope
        box("Ramp", center: Vec3(-10, 1.5, 13) - normal * 0.25, half: Vec3(2, 0.25, (slope + 0.2) / 2),
            rotation: Quat(angle: asin(rise / slope), axis: Vec3(1, 0, 0)), tint: Vec3(0.7, 0.58, 0.45))
        // Pillars under the decks' corners, and crates on the ground to walk round.
        for x: Float in [-13.4, -4.6, 4.6, 13.4] {
            for z: Float in [-8.4, 8.4] {
                box("Pillar", center: Vec3(x, 1.25, z), half: Vec3(0.3, 1.25, 0.3), tint: Vec3(0.6, 0.6, 0.64))
            }
        }
        for (i, p) in [Vec3(16, 0.6, 4), Vec3(17.5, 0.6, -8), Vec3(2, 0.6, 14), Vec3(8, 0.6, 15)].enumerated() {
            box("Crate \(i + 1)", center: p, half: Vec3(0.8, 0.6, 0.8), tint: Vec3(0.8, 0.55, 0.3))
        }
        world.spawn(Name("Jump"), Transform(position: Vec3(13.3, 3, -5)),
                    NavigationLink(end: Vec3(3.5, -3, 0), bidirectional: false, kind: .jump, cost: 1, radius: 1))

        world.addBehaviorTrees()
        world.bakeNavigation()
        if let report = world.lastNavMeshBake {
            polygons = report.polygonCount
            bakeMilliseconds = report.seconds * 1000
            for warning in report.warnings { print("navmesh: \(warning)") }
        }

        // Agents: a body and a head on a root at their feet. Routes are patrols (there and back).
        agents = []
        let routes: [(start: Vec3, route: [Vec3], tint: Vec3)] = [
            (Vec3(4, 0, 12), [Vec3(4, 0, 12), Vec3(-9, 3, -6)], Vec3(0.95, 0.35, 0.3)),          // up the ramp to the west deck
            (Vec3(-8, 3, 4), [Vec3(-8, 3, 4), Vec3(8, 3, 4)], Vec3(0.3, 0.6, 0.95)),             // deck to deck over the bridge
            (Vec3(9, 3, -5), [Vec3(9, 3, -5), Vec3(18, 0, -5)], Vec3(0.95, 0.8, 0.25)),          // off the east deck with a jump
            (Vec3(11, 3, -3), [Vec3(11, 3, -3), Vec3(18.5, 0, -2)], Vec3(1, 0.55, 0.2)),
            (Vec3(0, 0, -9), [Vec3(0, 0, -9), Vec3(0.5, 0, 10)], Vec3(0.4, 0.85, 0.45)),         // under the bridge
            (Vec3(-3, 0, -10.5), [Vec3(-3, 0, -10.5), Vec3(16, 0, -10.5)], Vec3(0.75, 0.4, 0.9)), // head-on pairs: they avoid
            (Vec3(16, 0, -10.3), [Vec3(16, 0, -10.3), Vec3(-3, 0, -10.3)], Vec3(0.3, 0.85, 0.85)),
            (Vec3(-2, 0, 17), [Vec3(-2, 0, 17), Vec3(17, 0, 17)], Vec3(0.95, 0.5, 0.7)),
            (Vec3(17, 0, 17.2), [Vec3(17, 0, 17.2), Vec3(-2, 0, 17.2)], Vec3(0.6, 0.75, 0.3)),
            (Vec3(-12, 0, 2), [Vec3(-12, 0, 2), Vec3(12, 0, -2)], Vec3(0.9, 0.9, 0.9)),          // under both decks
        ]
        for (k, agent) in routes.enumerated() {
            let root = world.spawn(Name("Agent \(k + 1)"), Transform(position: agent.start),
                                   BehaviorTreeRunner(tree: Self.tree, speed: 2.6 + Float(k % 3) * 0.3, radius: 0.45))
            world.setBlackboardValue(.points(agent.route), forKey: "route", of: root)
            let body = world.spawn(Transform(position: Vec3(0, 0.75, 0), scale: Vec3(0.6, 1.5, 0.6)),
                                   MeshRenderer(mesh: .cube, material: MaterialHandle("nav.matte"), tint: agent.tint))
            let head = world.spawn(Transform(position: Vec3(0, 1.72, -0.08), scale: Vec3(repeating: 0.42)),
                                   MeshRenderer(mesh: .sphere, material: MaterialHandle("nav.matte"), tint: agent.tint * 0.8 + 0.2))
            _ = world.setParent(body, to: root)
            _ = world.setParent(head, to: root)
            agents.append(root)
        }
        // Start a few seconds in.
        for _ in 0..<200 { world.update(dt: 1.0 / 60) }
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.62, pitch: 0.62, distance: 44, target: Vec3(2, 1, 3)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String {
        let crossing = agents.filter { world.get(BehaviorTreeState.self, for: $0)?.isCrossingLink == true }.count
        return "navmesh: \(polygons) polygons, baked in \(String(format: "%.0f", bakeMilliseconds)) ms; \(agents.count) agents, \(crossing) jumping [N overlay, R reset]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.3)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.n) { overlay.toggle() }
        world.update(dt: Double(dt))
        debug.removeAll()
        guard overlay else { return }
        world.navMesh?.drawDebug(into: debug)
        for agent in agents {
            if let path = world.get(BehaviorTreeState.self, for: agent)?.path, path.count >= 2 {
                NavMesh.drawPath(path, into: debug, color: Vec4(1, 0.85, 0.25, 0.9))
            }
        }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
