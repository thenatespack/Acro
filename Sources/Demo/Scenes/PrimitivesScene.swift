import Engine
import Foundation

/// The built-in cylinder, capsule, cone and torus next to the older cube and sphere, and
/// `LineRenderer` cables: power lines sagging between poles (endpoints following the poles'
/// entities, a catenary), a smoothed neon tube through points (emissive, blooming) and a flat ribbon.
final class PrimitivesScene: DemoScene {
    static let name = "primitives"
    static let summary = "Cylinder, capsule, cone, torus primitives; LineRenderer cables (sag, Catmull-Rom, emissive neon tubes, ribbons)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let skyColor = Vec3(0.05, 0.06, 0.11)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.16, 0.17, 0.2, 1), checker: true, roughness: 0.85), key: "ground")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.9, 0.55, 0.3, 1), metallic: 0.1, roughness: 0.45), key: "clay")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.45, 0.5, 0.58, 1), metallic: 0.9, roughness: 0.35), key: "steel")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.03, 0.03, 0.035, 1), roughness: 0.6), key: "rubber")
        try sceneRenderer.registerMaterial(Material(
            baseColor: Vec4(0.02, 0.02, 0.03, 1), roughness: 0.4, emissiveColor: Vec3(1, 0.1, 0.65), emissiveStrength: 5), key: "neon pink")
        try sceneRenderer.registerMaterial(Material(
            baseColor: Vec4(0.02, 0.02, 0.03, 1), roughness: 0.4, emissiveColor: Vec3(0.1, 0.8, 1), emissiveStrength: 5), key: "neon cyan")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.8, 0.15, 0.1, 1), roughness: 0.5, doubleSided: true), key: "ribbon")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 5, 14), at: Vec3(0, 2, 0)),
            Camera(fovY: .pi / 3.5, near: 0.1, far: 200, clearColor: Vec4(Self.skyColor, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.35, fogColor: Self.skyColor, fogDensity: 0.01))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, bloom: true, bloomIntensity: 0.12))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.4, 0.8, 0.5)))),
            DirectionalLight(intensity: 1.1, shadowExtent: 16, shadowCenter: Vec3(0, 2, 0)))
        _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(60, 1, 60)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("ground"), castsShadows: false))

        // The primitives, left to right, each about a unit tall and standing on the ground.
        let shapes: [(String, MeshHandle, String)] = [
            ("Cube", .cube, "clay"), ("Sphere", .sphere, "clay"), ("Cylinder", .cylinder, "steel"),
            ("Capsule", .capsule, "clay"), ("Cone", .cone, "steel"), ("Torus", .torus, "clay"),
        ]
        for (i, shape) in shapes.enumerated() {
            let x = (Float(i) - 2.5) * 1.8
            _ = world.spawn(Transform(position: Vec3(x, shape.1 == .torus ? 0.15 : 0.5, 3.5)), Name(shape.0),
                            MeshRenderer(mesh: shape.1, material: MaterialHandle(shape.2)))
        }

        // Three poles with cables sagging between their tops.
        for i in 0..<3 {
            let x = (Float(i) - 1) * 8
            _ = world.spawn(Transform(position: Vec3(x, 3, -2), scale: Vec3(0.3, 6, 0.3)), Name("Pole \(i)"),
                            MeshRenderer(mesh: .cylinder, material: MaterialHandle("steel")))
            // A crossarm along Z (a cylinder is along Y, so turn it).
            _ = world.spawn(Transform(position: Vec3(x, 5.6, -2), rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)),
                                      scale: Vec3(0.12, 2.6, 0.12)), Name("Crossarm \(i)"),
                            MeshRenderer(mesh: .cylinder, material: MaterialHandle("steel")))
        }
        for i in 0..<2 {
            for (k, dz) in [(0, Float(0)), (1, Float(1.8))] as [(Int, Float)] {
                let a = world.spawn(Transform(position: Vec3(Float(i - 1) * 8, 5.6, -2.9 + dz)), Name("Anchor"))
                let b = world.spawn(Transform(position: Vec3(Float(i) * 8, 5.6, -2.9 + dz)), Name("Anchor"))
                _ = world.spawn(Transform(), Name("Cable \(i).\(k)"),
                                LineRenderer(points: [], start: world.ref(to: a), end: world.ref(to: b), sag: 1.1 + Float(k) * 0.4,
                                             curve: .catenary, width: 0.07, segments: 24, sides: 8, material: MaterialHandle("rubber")))
            }
        }

        // A neon tube through points, smoothed, and a flat ribbon.
        _ = world.spawn(
            Transform(position: Vec3(-6, 1, 5)), Name("Neon"),
            LineRenderer(points: [Vec3(0, 0, 0), Vec3(2, 1.6, 0), Vec3(4, 0.4, 0), Vec3(6, 2.2, 0), Vec3(8, 1, 0), Vec3(10, 2.6, 0)],
                         smooth: true, width: 0.14, segments: 14, sides: 12, material: MaterialHandle("neon pink"), castsShadows: false))
        _ = world.spawn(
            Transform(position: Vec3(-6, 0.3, 7)), Name("Neon sag"),
            LineRenderer(points: [Vec3(0, 3, 0), Vec3(12, 3, 0)], sag: 1.5, curve: .parabola, width: 0.1, segments: 24, sides: 10,
                         material: MaterialHandle("neon cyan"), castsShadows: false))
        _ = world.spawn(
            Transform(position: Vec3(4, 0.4, 7.5)), Name("Ribbon"),
            LineRenderer(points: [Vec3(0, 0, 0), Vec3(2, 0.5, 0), Vec3(4, 0, 0)], sag: 0.3, smooth: true, style: .ribbon, width: 0.5,
                         segments: 12, material: MaterialHandle("ribbon")))
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.1, pitch: 0.3, distance: 17, target: Vec3(0, 2.2, 1)) }
    var lighting: Lighting { Lighting(fogColor: Self.skyColor) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(s.opaque) opaque drawn, \(s.shadowCasters) casters, \(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
        world.update(dt: Double(dt))
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
