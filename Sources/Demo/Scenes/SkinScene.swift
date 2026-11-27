import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// Skin and eye shading (MaterialSkin.swift, roadmap 13A): a sculpted bust in the `skin` preset
/// with `eye` eyeballs, lit by a warm key light from the front left and a low sun from behind on
/// the right, so the ears and the edges glow red through (transmission) while the screen-space
/// subsurface pass softens the lit side. Behind it, a row of spheres in every `SkinTone`; to the
/// right, a big eyeball on a stand for a close look at the cornea, iris and sclera.
///
/// `ENGINE_SSS=off` shows the same scene without scattering (before), `ENGINE_SSS=preintegrated`
/// the fallback WebGL 2 uses. `SKIN_VIEW=eye` frames the big eyeball, `ear` the right ear
/// against the sun, `tones` the row of spheres, `face` a close-up of the face.
final class SkinScene: DemoScene {
    static let name = "skin"
    static let summary = "Skin and eyes: subsurface scattering, ear transmission, dual-lobe specular, pores, refracted iris (ENGINE_SSS=off|preintegrated)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private let view = ProcessInfo.processInfo.environment["SKIN_VIEW"] ?? "bust"

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMesh(Self.headMesh(), key: "skin head")
        try sceneRenderer.registerMesh(.sphere(radius: 0.5, segments: 64, rings: 40), key: "skin sphere")
        try sceneRenderer.registerMesh(.eyeball(), key: "eyeball")
        var skin = Material.skin(.light)
        // SKIN_TRANSMISSION=0...1 overrides the preset's light through thin parts.
        if let value = ProcessInfo.processInfo.environment["SKIN_TRANSMISSION"].flatMap(Float.init) { skin.subsurface?.transmission = value }
        try sceneRenderer.registerMaterial(skin, key: "skin")
        for tone in SkinTone.allCases {
            try sceneRenderer.registerMaterial(.skin(tone), key: "skin \(tone.rawValue)")
        }
        try sceneRenderer.registerMaterial(.eye(iris: MaterialEye.blue), key: "eye")
        try sceneRenderer.registerMaterial(.eye(iris: MaterialEye.hazel), key: "eye hazel")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.05, 0.05, 0.055, 1), roughness: 0.35), key: "stand")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.05, 0.05, 0.055, 1), roughness: 0.9), key: "floor")

        cameraEntity = world.spawn(Transform.looking(from: Vec3(-0.25, 0.05, 0.55), at: Vec3(0, 0, 0)),
                                   Camera(fovY: .pi / 6, near: 0.02, far: 40, clearColor: Vec4(0.07, 0.075, 0.09, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.5, 0.55, 0.65), groundColor: Vec3(0.12, 0.1, 0.09), ambientIntensity: 0.35))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, exposure: 0.2))
        // The sun: low, behind and a little right, so it shines through the ears toward the camera.
        _ = world.spawn(Name("Back light"),
                        Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.2, 0.3, -1)))),
                        DirectionalLight(color: Vec3(1, 0.93, 0.85), intensity: 2.6, shadowExtent: 0.9, shadowCenter: Vec3(0, 0, 0),
                                         shadowDistance: 4, shadowBias: 0.0002, cascadeCount: 1, shadowMaxDistance: 6))
        // The key: warm, front left.
        _ = world.spawn(Name("Key light"), Transform(position: Vec3(-0.55, 0.3, 0.6)),
                        PointLight(color: Vec3(1, 0.86, 0.72), intensity: 1.1, range: 4))
        // A cool fill from the right.
        _ = world.spawn(Name("Fill light"), Transform(position: Vec3(0.7, -0.05, 0.5)),
                        PointLight(color: Vec3(0.6, 0.7, 1), intensity: 0.25, range: 4))
        _ = world.spawn(Name("Floor"), Transform(position: Vec3(0, -0.33, 0), scale: Vec3(6, 0.02, 6)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        buildBust()
        buildTones()
        buildEyeCloseUp()
        world.propagateTransforms()
    }

    // MARK: - Content

    /// The head, neck and shoulders, ears and eyes.
    private func buildBust() {
        let bust = world.spawn(Name("Bust"), Transform())
        func part(_ name: String, _ transform: Transform, mesh: MeshHandle, material: String) {
            let e = world.spawn(Name(name), transform, MeshRenderer(mesh: mesh, material: MaterialHandle(material)))
            world.setParent(e, to: bust)
        }
        part("Head", Transform(), mesh: MeshHandle("skin head"), material: "skin")
        part("Neck", Transform(position: Vec3(0, -0.13, -0.02), scale: Vec3(0.1, 0.17, 0.105)), mesh: MeshHandle("skin sphere"),
             material: "skin")
        part("Shoulders", Transform(position: Vec3(0, -0.235, -0.025), scale: Vec3(0.4, 0.14, 0.19)), mesh: MeshHandle("skin sphere"),
             material: "skin")
        // Ears: thin, turned a little forward, so the back light gets through toward the camera.
        for side: Float in [-1, 1] {
            part(side < 0 ? "Ear L" : "Ear R",
                 Transform(position: Vec3(side * 0.08, 0.005, -0.014),
                           rotation: Quat(angle: -side * 0.55, axis: Vec3(0, 1, 0)) * Quat(angle: -0.12, axis: Vec3(1, 0, 0)),
                           scale: Vec3(0.012, 0.06, 0.034)),
                 mesh: MeshHandle("skin sphere"), material: "skin")
        }
        // Eyes: in the sockets, looking slightly toward the camera.
        for side: Float in [-1, 1] {
            let direction = normalize(Vec3(side * 0.33, 0.1, 1))
            let center = direction * (Self.headRadius(direction) - 0.0075)
            let gaze = normalize(Vec3(side * -0.03, 0.02, 0.6) - center)
            part(side < 0 ? "Eye L" : "Eye R", Transform(position: center, rotation: .lookRotation(forward: -gaze)),
                 mesh: MeshHandle("eyeball"), material: "eye")
        }
    }

    /// One sphere per skin tone, behind the bust.
    private func buildTones() {
        for (i, tone) in SkinTone.allCases.enumerated() {
            let x = (Float(i) - Float(SkinTone.allCases.count - 1) / 2) * 0.17
            _ = world.spawn(Name("Tone \(tone.rawValue)"), Transform(position: Vec3(x, -0.05, -0.55), scale: Vec3(repeating: 0.13)),
                            MeshRenderer(mesh: MeshHandle("skin sphere"), material: MaterialHandle("skin \(tone.rawValue)")))
        }
    }

    /// A big eyeball (5x) on a stand, right of the bust.
    private func buildEyeCloseUp() {
        _ = world.spawn(Name("Eye stand"), Transform(position: Vec3(0.32, -0.2, 0.0), scale: Vec3(0.04, 0.2, 0.04)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("stand")))
        let center = Vec3(0.32, -0.06, 0.0)
        let gaze = normalize(Vec3(0.22, -0.02, 0.45) - center)
        _ = world.spawn(Name("Big eye"), Transform(position: center, rotation: .lookRotation(forward: -gaze), scale: Vec3(repeating: 5)),
                        MeshRenderer(mesh: MeshHandle("eyeball"), material: MaterialHandle("eye hazel")))
    }

    // MARK: - The head mesh

    /// A Gaussian bump on the head's radius around direction `c`, `size` wide (x, y) on the unit sphere.
    private static func bump(_ d: Vec3, _ c: Vec3, _ size: Vec2, _ amount: Float) -> Float {
        let c = normalize(c)
        guard dot(d, c) > 0 else { return 0 }
        // Offsets across the bump, in the plane facing it (x right, y up).
        let right = normalize(cross(Vec3(0, 1, 0), c))
        let up = cross(c, right)
        let o = d - c
        let x = dot(o, right) / size.x, y = dot(o, up) / size.y
        return amount * expf(-(x * x + y * y))
    }

    /// The head's surface distance from its center along unit direction `d` (+Z the face, +Y up).
    static func headRadius(_ d: Vec3) -> Float {
        // An egg: narrower jaw, longer back of the skull.
        let jaw: Float = 1 - 0.16 * max(-d.y, 0) * max(d.z + 0.2, 0)
        let a = Vec3(0.076 * jaw, 0.108, d.z > 0 ? 0.092 : 0.104)
        var r = 1 / sqrtf((d.x / a.x) * (d.x / a.x) + (d.y / a.y) * (d.y / a.y) + (d.z / a.z) * (d.z / a.z))
        // Nose: a ridge growing toward the tip, nostrils at its base.
        r += bump(d, Vec3(0, 0.02, 1), Vec2(0.05, 0.16), 0.006)
        r += bump(d, Vec3(0, -0.12, 1), Vec2(0.07, 0.09), 0.016)
        r += bump(d, Vec3(0, -0.2, 1), Vec2(0.09, 0.05), 0.009)
        for side: Float in [-1, 1] {
            r += bump(d, Vec3(side * 0.1, -0.22, 1), Vec2(0.05, 0.04), 0.005)
            // Eye sockets (wide, shallow) under a brow.
            r += bump(d, Vec3(side * 0.33, 0.1, 1), Vec2(0.17, 0.09), -0.011)
            r += bump(d, Vec3(side * 0.33, 0.27, 1), Vec2(0.22, 0.06), 0.004)
            // Cheekbones and cheeks.
            r += bump(d, Vec3(side * 0.55, -0.08, 0.85), Vec2(0.2, 0.14), 0.006)
            // Temples, slightly hollow.
            r += bump(d, Vec3(side * 0.95, 0.25, 0.35), Vec2(0.25, 0.2), -0.004)
        }
        // Lips and the groove between them, the chin.
        r += bump(d, Vec3(0, -0.42, 1), Vec2(0.17, 0.05), 0.0045)
        r += bump(d, Vec3(0, -0.52, 1), Vec2(0.15, 0.05), 0.004)
        r += bump(d, Vec3(0, -0.47, 1), Vec2(0.16, 0.018), -0.0025)
        r += bump(d, Vec3(0, -0.78, 0.75), Vec2(0.16, 0.12), 0.008)
        return r
    }

    /// The head: a sphere with `headRadius`, its normals from the surface's own derivatives.
    static func headMesh(segments: Int = 160, rings: Int = 120) -> MeshGeometry {
        func point(_ theta: Float, _ phi: Float) -> Vec3 {
            let d = Vec3(sinf(theta) * sinf(phi), cosf(theta), sinf(theta) * cosf(phi))
            return d * headRadius(d)
        }
        var geometry = MeshGeometry(vertices: [], indices: [])
        let e: Float = 1e-3
        for ring in 0...rings {
            let theta = min(max(Float(ring) / Float(rings) * .pi, 1e-3), .pi - 1e-3)
            for segment in 0...segments {
                let phi = Float(segment) / Float(segments) * 2 * .pi
                let p = point(theta, phi)
                let dTheta = point(theta + e, phi) - point(theta - e, phi)
                let dPhi = point(theta, phi + e) - point(theta, phi - e)
                var n = normalize(cross(dPhi, dTheta))
                if dot(n, p) < 0 { n = -n }
                geometry.vertices.append(MeshVertex(position: p, normal: n,
                                                    uv: Vec2(Float(segment) / Float(segments), Float(ring) / Float(rings))))
            }
        }
        let stride = UInt32(segments + 1)
        for ring in 0..<UInt32(rings) {
            for segment in 0..<UInt32(segments) {
                let a = ring * stride + segment, b = a + 1, c = a + stride, d = c + 1
                geometry.indices += [a, c, b, b, c, d]
            }
        }
        return geometry
    }

    // MARK: - View

    var initialView: OrbitView {
        switch view {
        case "eye": OrbitView(yaw: -0.35, pitch: 0.02, distance: 2.2, target: Vec3(0.32, -0.06, 0))
        case "ear": OrbitView(yaw: 0.75, pitch: 0.05, distance: 2.8, target: Vec3(0.075, 0.0, -0.01))
        case "tones": OrbitView(yaw: 0.0, pitch: 0.12, distance: 12.5, target: Vec3(0, -0.05, -0.55))
        case "face": OrbitView(yaw: -0.3, pitch: 0.05, distance: 3, target: Vec3(0, 0.0, 0.05))
        default: OrbitView(yaw: 0.55, pitch: 0.1, distance: 6.2, target: Vec3(0, -0.02, 0))
        }
    }

    var lighting: Lighting { Lighting(fogDensity: 0, shadowExtent: 1) }

    var status: String {
        let mode = ProcessInfo.processInfo.environment["ENGINE_SSS"] ?? "default"
        return "ENGINE_SSS=\(mode), \(sceneRenderer.stats.list.opaque) opaque drawn"
    }

    /// The host's orbit distances (2 at the least) are tenths of a meter here: a bust is small.
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        let eye = target + (orbitEye - target) * 0.1
        orbit = (eye, target)
        return ViewCamera(eye: eye, target: target)
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
