import Engine
import Foundation

/// PBR materials drawn by `SceneRenderer`: a wall of spheres from dielectric to metal
/// (bottom to top) and smooth to rough (left to right), a normal-mapped brick slab, an
/// emissive panel, an alpha-tested plant (cutout leaves, also in its shadow) and the Khronos
/// BoomBox glTF model with base color, metallic-roughness, normal, occlusion and emissive maps.
/// Every texture except the model's is generated in code.
final class PBRScene: DemoScene {
    static let name = "pbr"
    static let summary = "PBR materials: metallic x roughness spheres, normal map, emissive, alpha-mask cutouts, textured glTF (BoomBox)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let fogColor = Vec3(0.62, 0.7, 0.82)

    init(renderer: Renderer) throws {
        let device = renderer.device
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)
        try sceneRenderer.registerMesh(.sphere(radius: 0.5, segments: 64, rings: 32), key: "sphere-hi")

        // Floor: a rough dielectric checkerboard.
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, roughness: 0.8), key: "floor")

        // Spheres: one material per cell, metallic rows x roughness columns.
        let steps = 5
        for m in 0..<steps {
            for r in 0..<steps {
                try sceneRenderer.registerMaterial(
                    Material(baseColor: Vec4(0.95, 0.64, 0.37, 1), metallic: Float(m) / Float(steps - 1),
                             roughness: Float(r) / Float(steps - 1)), key: "sphere \(m).\(r)")
            }
        }

        // Brick slab: color and normal map from one height field.
        let bricks = Self.brickTextures(size: 256)
        try sceneRenderer.registerMaterial(Material(
            baseColor: Vec4(1, 1, 1, 1),
            texture: try device.makeTexture(pixels: bricks.color, width: 256, height: 256, format: .rgba8Srgb, generateMipmaps: true),
            uvScale: Vec2(2, 2), roughness: 0.75,
            normalTexture: try device.makeTexture(pixels: bricks.normal, width: 256, height: 256, format: .rgba8Unorm,
                                                  generateMipmaps: true),
            normalScale: 1.5), key: "bricks")

        // Emissive panel: glowing grid lines on dark metal.
        let glow = Self.gridPixels(size: 128)
        try sceneRenderer.registerMaterial(Material(
            baseColor: Vec4(0.08, 0.08, 0.09, 1), metallic: 1, roughness: 0.35, emissiveColor: Vec3(0.3, 0.75, 1),
            emissiveTexture: try device.makeTexture(pixels: glow, width: 128, height: 128, format: .rgba8Srgb, generateMipmaps: true),
            emissiveStrength: 6), key: "glow")

        // Plant: cutout leaves (alpha mask), lit from both sides.
        let leaves = Self.leafPixels(size: 128)
        try sceneRenderer.registerMaterial(Material(
            baseColor: Vec4(1, 1, 1, 1),
            texture: try device.makeTexture(pixels: leaves, width: 128, height: 128, format: .rgba8Srgb, generateMipmaps: true),
            sampler: SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear, addressMode: .clampToEdge),
            roughness: 0.6, alphaMode: .mask, alphaCutoff: 0.5, doubleSided: true), key: "leaves")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.35, 0.2, 0.12, 1), roughness: 0.9), key: "pot")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(4, 6, 17), at: Vec3(0, 2.5, 0)),
            Camera(fovY: .pi / 3.5, near: 0.1, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.5, fogColor: Self.fogColor, fogDensity: 0.004))
        // HDR post-processing: the emissive panel and the sun's highlights on the metal spheres bloom.
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, bloom: true, bloomIntensity: 0.06))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.45, 0.7, 0.55)))),
            DirectionalLight(intensity: 1.4, shadowExtent: 14, shadowCenter: Vec3(0, 2, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))

        for m in 0..<steps {
            for r in 0..<steps {
                _ = world.spawn(
                    Transform(position: Vec3(Float(r - 2) * 1.15, 0.8 + Float(m) * 1.15, -1), scale: Vec3(repeating: 0.95)),
                    Name("metallic \(m) roughness \(r)"),
                    MeshRenderer(mesh: MeshHandle("sphere-hi"), material: MaterialHandle("sphere \(m).\(r)")))
            }
        }
        _ = world.spawn(
            Transform(position: Vec3(-6.2, 2, 0.5), rotation: Quat(angle: 0.5, axis: Vec3(0, 1, 0)), scale: Vec3(4, 4, 0.4)),
            Name("Bricks"), MeshRenderer(mesh: .cube, material: MaterialHandle("bricks")))
        _ = world.spawn(
            Transform(position: Vec3(-3.6, 0.6, 4), rotation: Quat(angle: 0.35, axis: Vec3(0, 1, 0)), scale: Vec3(1.8, 1.2, 1.8)),
            Name("Glow"), MeshRenderer(mesh: .cube, material: MaterialHandle("glow")))
        try buildPlant(at: Vec3(6, 0, 0.5))
        try loadBoomBox(device: device, at: Vec3(3.4, 0, 4))
        world.propagateTransforms()
    }

    /// Crossed double-sided leaf cards in a pot.
    private func buildPlant(at position: Vec3) throws {
        let root = world.spawn(Transform(position: position), Name("Plant"))
        let pot = world.spawn(Transform(position: Vec3(0, 0.4, 0), scale: Vec3(1.1, 0.8, 1.1)), Name("Pot"),
                              MeshRenderer(mesh: .cube, material: MaterialHandle("pot")))
        world.setParent(pot, to: root)
        for k in 0..<4 {
            // A vertical 3x3 card: the plane faces +Y, so stand it up, then turn it around Y.
            let yaw = Float(k) * .pi / 4
            let card = world.spawn(
                Transform(position: Vec3(0, 2.3, 0), rotation: Quat(angle: yaw, axis: Vec3(0, 1, 0)) * Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)),
                          scale: Vec3(3, 1, 3)),
                Name("Leaves \(k)"), MeshRenderer(mesh: .plane, material: MaterialHandle("leaves")))
            world.setParent(card, to: root)
        }
    }

    /// The BoomBox model (2 cm in the file), scaled up and stood on the floor.
    private func loadBoomBox(device: RenderDevice, at position: Vec3) throws {
        guard let url = Bundle.module.url(forResource: "BoomBox", withExtension: "glb", subdirectory: "Models") else {
            throw GraphicsError("Models/BoomBox.glb is missing from the Demo bundle")
        }
        let model = try GLTFReader.read(contentsOf: url)
        for warning in model.warnings { print("glTF: \(warning)") }
        let (textures, failures) = model.makeTextures(device: device) { data, _ in try ImageDecoder.decode(data) }
        for failure in failures { print("glTF: \(failure)") }
        let handles = try model.register(with: sceneRenderer, keyPrefix: "BoomBox", textures: textures)
        let bounds = model.sceneBounds ?? Bounds(center: .zero, halfExtent: Vec3(repeating: 0.01))
        let scale = 1.1 / max(bounds.halfExtent.max(), 1e-4)
        let root = world.spawn(
            Transform(position: position + Vec3(0, bounds.halfExtent.y * scale, 0),
                      rotation: Quat(angle: -0.5, axis: Vec3(0, 1, 0)), scale: Vec3(repeating: scale)),
            Name("BoomBox"))
        model.instantiate(in: world, under: root, handles: handles)
    }

    var initialView: OrbitView { OrbitView(yaw: 0.15, pitch: 0.28, distance: 16, target: Vec3(0, 2.2, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
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

    // MARK: - Procedural textures

    /// Bricks with beveled edges: sRGB color and a tangent-space normal map (+Y up in the
    /// image, i.e. toward row 0) derived from the same height field.
    private static func brickTextures(size: Int) -> (color: [UInt8], normal: [UInt8]) {
        let rows = 8, columns = 4
        func height(_ x: Int, _ y: Int) -> Float {
            let x = (x + size) % size, y = (y + size) % size
            let rowHeight = Float(size) / Float(rows), brickWidth = Float(size) / Float(columns)
            let row = Int(Float(y) / rowHeight)
            let fx = Float(x) + (row % 2 == 0 ? 0 : brickWidth / 2)
            let u = fx.truncatingRemainder(dividingBy: brickWidth), v = Float(y) - Float(row) * rowHeight
            // Distance to the nearest mortar line, in texels, bevelled over 3 texels.
            let edge = min(min(u, brickWidth - u), min(v, rowHeight - v)) - 1.5
            return edge <= 0 ? 0 : min(edge / 3, 1)
        }
        var color = [UInt8](repeating: 255, count: size * size * 4)
        var normal = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let h = height(x, y)
                let i = (y * size + x) * 4
                // Per-brick tint from the brick's position.
                let row = y * rows / size
                let brick = (x + (row % 2 == 0 ? 0 : size / columns / 2)) * columns / size
                let tint = Float((row * 7 + brick * 13) % 5) / 5 * 0.25
                let mortar: (Float, Float, Float) = (0.55, 0.53, 0.5)
                let clay: (Float, Float, Float) = (0.62 + tint * 0.4, 0.27 + tint * 0.2, 0.18 + tint * 0.1)
                let t = h > 0 ? Float(1) : 0
                color[i] = UInt8(255 * (mortar.0 + (clay.0 - mortar.0) * t))
                color[i + 1] = UInt8(255 * (mortar.1 + (clay.1 - mortar.1) * t))
                color[i + 2] = UInt8(255 * (mortar.2 + (clay.2 - mortar.2) * t))
                // Central differences; image rows grow downward, so up is -y.
                let dx = (height(x + 1, y) - height(x - 1, y)) / 2
                let dUp = (height(x, y - 1) - height(x, y + 1)) / 2
                let n = normalize(Vec3(-dx * 3, -dUp * 3, 1))
                normal[i] = UInt8((n.x * 0.5 + 0.5) * 255)
                normal[i + 1] = UInt8((n.y * 0.5 + 0.5) * 255)
                normal[i + 2] = UInt8((n.z * 0.5 + 0.5) * 255)
            }
        }
        return (color, normal)
    }

    /// Bright grid lines on black (sRGB), for the emissive map.
    private static func gridPixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let line = x % 32 < 3 || y % 32 < 3
                let dot = (x % 32 - 16) * (x % 32 - 16) + (y % 32 - 16) * (y % 32 - 16) < 25
                let i = (y * size + x) * 4
                let v: UInt8 = line ? 255 : dot ? 180 : 0
                pixels[i] = v
                pixels[i + 1] = v
                pixels[i + 2] = v
            }
        }
        return pixels
    }

    /// Leaves on a stem: green with alpha 1 inside the leaf shapes, 0 elsewhere.
    private static func leafPixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        // Leaves as ellipses: center (u, v), half length, half width, angle.
        let leaves: [(Float, Float, Float, Float, Float)] = [
            (0.5, 0.12, 0.12, 0.05, 0), (0.33, 0.3, 0.16, 0.06, 0.9), (0.67, 0.36, 0.16, 0.06, -0.9),
            (0.3, 0.55, 0.17, 0.065, 0.7), (0.7, 0.6, 0.17, 0.065, -0.7), (0.34, 0.8, 0.15, 0.06, 0.5),
            (0.66, 0.84, 0.14, 0.055, -0.5),
        ]
        for y in 0..<size {
            for x in 0..<size {
                let u = (Float(x) + 0.5) / Float(size), v = (Float(y) + 0.5) / Float(size)
                var inside = abs(u - 0.5) < 0.012 && v > 0.1  // stem
                var vein = inside
                for (cu, cv, a, b, angle) in leaves {
                    let du = u - cu, dv = v - cv
                    let p = du * cosf(angle) + dv * sinf(angle), q = -du * sinf(angle) + dv * cosf(angle)
                    let r = (p * p) / (a * a) + (q * q) / (b * b)
                    if r < 1 {
                        inside = true
                        vein = vein || abs(q) < 0.004
                    }
                }
                let i = (y * size + x) * 4
                guard inside else { continue }
                let shade = 0.75 + 0.25 * sinf(u * 37 + v * 23)
                pixels[i] = UInt8(vein ? 120 : 60 * shade)
                pixels[i + 1] = UInt8(vein ? 170 : 140 * shade)
                pixels[i + 2] = UInt8(vein ? 70 : 40 * shade)
                pixels[i + 3] = 255
            }
        }
        return pixels
    }
}
