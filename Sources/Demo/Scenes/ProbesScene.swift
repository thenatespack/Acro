import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// A room lit through one window: the sun lays a patch on a red rug and the floor, and
/// everything else inside is lit by light bouncing off it, from an `IrradianceVolume` of 6 x 3 x 5
/// L2 SH probes (two bounces), with box-projected reflections from a room-sized
/// `ReflectionProbe` on the glossy floor, a chrome ball and a dark metal panel. The probes are
/// baked on the GPU in the first frame (`SceneRenderer.bakesProbesAutomatically`). Without
/// probes (`PROBES_OFF=1`) the sky lights the room as if it had no walls.
///
/// `PROBES_VIEW=irradiance` shows the indirect diffuse light only, `PROBES_DEBUG=1` the probe
/// spheres and boxes, `PROBES_VIEW=window` looks at the window, `PROBES_BAKE_EACH_FRAME=1` bakes
/// again every frame (for the bake's GPU pass times). Keys: **P** toggles the probes, **I** the
/// irradiance-only view, **G** the debug spheres and boxes, **B** bakes again.
final class ProbesScene: DemoScene {
    static let name = "probes"
    static let summary = "light probes: an interior lit through a window, SH irradiance volume bounce, box-projected reflection probe"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let debugDraw = DebugDraw()
    private var cameraEntity = Entity.invalid
    private var probeEntities: [Entity] = []
    private var orbit: (eye: Vec3, target: Vec3)?
    private var probesOn: Bool
    private var showsBoxes: Bool
    private let bakesEachFrame: Bool
    private var lastBake: LightProbeBakeReport?

    init(renderer: Renderer) throws {
        let env = ProcessInfo.processInfo.environment
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debugDraw
        probesOn = env["PROBES_OFF"] != "1"
        showsBoxes = env["PROBES_DEBUG"] == "1"
        bakesEachFrame = env["PROBES_BAKE_EACH_FRAME"] == "1"
        sceneRenderer.probeDebug = LightProbeDebug(showsProbes: showsBoxes, irradianceOnly: env["PROBES_VIEW"] == "irradiance")

        func material(_ key: String, _ color: Vec3, metallic: Float = 0, roughness: Float) throws {
            try sceneRenderer.registerMaterial(Material(baseColor: Vec4(color, 1), metallic: metallic, roughness: roughness), key: key)
        }
        try material("probes.wall", Vec3(0.72, 0.7, 0.66), roughness: 0.9)
        try material("probes.ceiling", Vec3(0.8, 0.8, 0.78), roughness: 0.95)
        try material("probes.floor", Vec3(0.5, 0.33, 0.2), roughness: 0.22)
        try material("probes.rug", Vec3(0.7, 0.09, 0.06), roughness: 0.95)
        try material("probes.white", Vec3(0.8, 0.8, 0.8), roughness: 0.7)
        try material("probes.blue", Vec3(0.12, 0.25, 0.6), roughness: 0.6)
        try material("probes.chrome", Vec3(0.95, 0.94, 0.92), metallic: 1, roughness: 0.04)
        try material("probes.gold", Vec3(1, 0.78, 0.34), metallic: 1, roughness: 0.3)
        try material("probes.panel", Vec3(0.2, 0.2, 0.22), metallic: 1, roughness: 0.12)
        try material("probes.ground", Vec3(0.3, 0.36, 0.22), roughness: 0.95)
        try material("probes.tree", Vec3(0.16, 0.3, 0.12), roughness: 0.9)

        let view = env["PROBES_VIEW"] == "window"
            ? Transform.looking(from: Vec3(-3.5, 1.6, -3.6), at: Vec3(6, 1.5, 1.2))
            : Transform.looking(from: Vec3(-5.2, 1.75, 4.3), at: Vec3(2.2, 1.0, -1.8))
        cameraEntity = world.spawn(view, Camera(fovY: .pi / 2.6, near: 0.05, far: 200))
        var environment = SceneEnvironment(sky: .procedural, environmentIntensity: 1)
        environment.proceduralSky.sunIntensity = 20
        _ = world.spawn(Name("Environment"), environment)
        _ = world.spawn(Name("Sun"), Transform(rotation: .lookRotation(forward: -normalize(Vec3(1, 0.55, 0.25)))),
                        DirectionalLight(color: Vec3(1, 0.92, 0.8), intensity: 4, shadowExtent: 9, shadowCenter: Vec3(1, 1.5, 0)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, exposure: 0.4))

        buildRoom()
        if probesOn {
            spawnProbes()
            bake()
        }
        world.propagateTransforms()
    }

    private func box(_ name: String, center: Vec3, size: Vec3, material: String, rotation: Quat = .identity) {
        _ = world.spawn(Name(name), Transform(position: center, rotation: rotation, scale: size),
                        MeshRenderer(mesh: .cube, material: MaterialHandle(material)))
    }

    /// The room: 12 x 3.6 x 10 m inside, 0.3 m walls, a 3 x 2 m window in the +X wall.
    private func buildRoom() {
        box("Ground", center: Vec3(0, -0.55, 0), size: Vec3(80, 1, 80), material: "probes.ground")
        box("Floor", center: Vec3(0, -0.15, 0), size: Vec3(12.6, 0.3, 10.6), material: "probes.floor")
        box("Ceiling", center: Vec3(0, 3.75, 0), size: Vec3(12.6, 0.3, 10.6), material: "probes.ceiling")
        box("West wall", center: Vec3(-6.15, 1.8, 0), size: Vec3(0.3, 3.6, 10.6), material: "probes.wall")
        box("North wall", center: Vec3(0, 1.8, -5.15), size: Vec3(12.6, 3.6, 0.3), material: "probes.wall")
        box("South wall", center: Vec3(0, 1.8, 5.15), size: Vec3(12.6, 3.6, 0.3), material: "probes.wall")
        // The east wall around the window (z -1.5...1.5, y 0.9...2.9).
        box("East wall, below", center: Vec3(6.15, 0.45, 0), size: Vec3(0.3, 0.9, 10.6), material: "probes.wall")
        box("East wall, above", center: Vec3(6.15, 3.25, 0), size: Vec3(0.3, 0.7, 10.6), material: "probes.wall")
        box("East wall, north", center: Vec3(6.15, 1.9, -3.4), size: Vec3(0.3, 2, 3.8), material: "probes.wall")
        box("East wall, south", center: Vec3(6.15, 1.9, 3.4), size: Vec3(0.3, 2, 3.8), material: "probes.wall")

        box("Rug", center: Vec3(2.4, 0.01, 0.2), size: Vec3(3.6, 0.02, 3.2), material: "probes.rug")
        box("Panel", center: Vec3(-0.5, 1.7, -4.97), size: Vec3(3.6, 1.8, 0.04), material: "probes.panel")
        box("Column", center: Vec3(-3.6, 1.1, -2.6), size: Vec3(0.8, 2.2, 0.8), material: "probes.white")
        box("Cabinet", center: Vec3(-5.4, 0.6, 1.5), size: Vec3(1, 1.2, 2.4), material: "probes.blue")
        _ = world.spawn(Name("Chrome ball"), Transform(position: Vec3(0.8, 0.6, -2.4), scale: Vec3(repeating: 1.2)),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("probes.chrome")))
        _ = world.spawn(Name("Gold ball"), Transform(position: Vec3(-1.6, 0.45, -1.2), scale: Vec3(repeating: 0.9)),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("probes.gold")))
        _ = world.spawn(Name("White ball"), Transform(position: Vec3(-2.2, 0.55, 1.6), scale: Vec3(repeating: 1.1)),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("probes.white")))
        // Trees outside, seen through the window.
        for (k, p) in [Vec3(11, 0, -3), Vec3(14, 0, 2.5), Vec3(10, 0, 5)].enumerated() {
            box("Tree \(k + 1)", center: p + Vec3(0, 2, 0), size: Vec3(1.6, 4, 1.6), material: "probes.tree")
        }
    }

    private func spawnProbes() {
        probeEntities = [
            world.spawn(Name("Room irradiance"), Transform(position: Vec3(0, 1.8, 0)),
                        IrradianceVolume(size: Vec3(12.4, 4, 10.4), countX: 6, countY: 3, countZ: 5, blendDistance: 0.1)),
            world.spawn(Name("Room reflection"), Transform(position: Vec3(0, 1.8, 0)),
                        ReflectionProbe(size: Vec3(12.6, 4.2, 10.6), blendDistance: 0.3, projectionSize: Vec3(12, 3.6, 10),
                                        captureOffset: Vec3(0, -0.3, 0))),
        ]
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.1, distance: 8, target: Vec3(0, 1.4, 0)) }

    var status: String {
        let s = sceneRenderer.probeSummary
        var text = "probes \(probesOn ? "on" : "off") [P]: \(s.reflectionProbes) reflection, \(s.irradianceProbes) irradiance"
        if let lastBake { text += ", baked in \(Int(lastBake.milliseconds)) ms" }
        if sceneRenderer.probeDebug.irradianceOnly { text += ", irradiance only [I]" }
        return text
    }

    /// The camera stays where the scene puts it (inside the room); the orbit controls are ignored.
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        let t = world.get(Transform.self, for: cameraEntity) ?? Transform()
        return ViewCamera(eye: t.position, target: t.position + t.rotation * Vec3(0, 0, -1))
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.p) {
            probesOn.toggle()
            if probesOn { spawnProbes() } else { probeEntities.forEach { world.despawn($0) } }
        }
        if input.wasPressed(.i) { sceneRenderer.probeDebug.irradianceOnly.toggle() }
        if input.wasPressed(.g) {
            showsBoxes.toggle()
            sceneRenderer.probeDebug.showsProbes = showsBoxes
        }
        if input.wasPressed(.b) { bake() }
        world.update(dt: Double(dt))
    }

    private func bake() {
        sceneRenderer.bakeProbes(in: world) { [weak self] report in
            self?.lastBake = report
            print("Probes baked: \(report.reflectionProbes) reflection probes, \(report.irradianceProbes) irradiance probes "
                  + "(\(report.probesInsideGeometry) inside geometry), \(report.bounces) bounces, \(report.milliseconds) ms"
                  + (report.warnings.isEmpty ? "" : "; " + report.warnings.joined(separator: "; ")))
        }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if bakesEachFrame && !sceneRenderer.isBakingProbes { bake() }
        world.propagateTransforms()
        debugDraw.removeAll()
        if showsBoxes { LightProbeDebug.drawVolumes(of: world, into: debugDraw) }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
