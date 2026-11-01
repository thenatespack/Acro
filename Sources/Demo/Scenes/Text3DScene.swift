import Engine
import Foundation

/// World-space text (`TextMesh`): a rainy neon street at night. Shop signs in glowing Latin
/// letters (the bundled Inter) and Japanese (a system CJK font, found among a few well-known paths and
/// checked to cover the characters; without one the signs use Latin letters), with emissive
/// colors above 1 that bloom, an outline, a halo, a billboard that always faces the camera and a
/// flickering sign. The text is depth tested against the buildings, fogged like them and sorted
/// back to front. Signs reuse the shared glyph atlas, so each character is rasterized once.
final class Text3DScene: DemoScene {
    static let name = "text3d"
    static let summary = "world-space SDF text: neon signs with emissive glow, outline, halo, billboards, CJK font"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var flicker = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let night = Vec3(0.008, 0.01, 0.025)

    /// Well-known CJK fonts of macOS, Windows and Linux (nothing is bundled: they are large).
    private static let cjkFonts = [
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf", "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/System/Library/Fonts/STHeiti Medium.ttc", "/System/Library/Fonts/PingFang.ttc",
        "C:/Windows/Fonts/YuGothM.ttc", "C:/Windows/Fonts/msgothic.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    ]

    /// The first of `cjkFonts` that exists and has a glyph for every scalar of `text`; nil if none.
    static func cjkFont(covering text: String) -> String? {
        for path in cjkFonts where FileManager.default.fileExists(atPath: path) {
            guard let font = try? Font(contentsOf: URL(fileURLWithPath: path)) else { continue }
            if text.unicodeScalars.allSatisfy({ $0.properties.isWhitespace || font.hasGlyph(for: $0) }) { return path }
        }
        return nil
    }

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let materials: [(String, Material)] = [
            ("street", Material(baseColor: Vec4(0.03, 0.03, 0.04, 1), roughness: 0.25)),
            ("wall", Material(baseColor: Vec4(0.07, 0.07, 0.09, 1), roughness: 0.7)),
            ("panel", Material(baseColor: Vec4(0.015, 0.015, 0.02, 1), metallic: 0.6, roughness: 0.4)),
            ("window", Material(baseColor: Vec4(0.02, 0.02, 0.03, 1), emissiveColor: Vec3(1, 0.7, 0.35), emissiveStrength: 0.5)),
        ]
        for (key, material) in materials { try sceneRenderer.registerMaterial(material, key: key) }

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 3.5, 15), at: Vec3(0, 5.5, 0)),
            Camera(fovY: .pi / 3, near: 0.1, far: 300, clearColor: Vec4(Self.night, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0.6, bloom: true, bloomIntensity: 0.12))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.05, 0.05, 0.12), groundColor: Vec3(0.01, 0.01, 0.015),
                                         ambientIntensity: 0.5, fogColor: Vec3(0.03, 0.02, 0.07), fogDensity: 0.02))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: normalize(Vec3(-0.3, -0.8, -0.4)))),
                        DirectionalLight(color: Vec3(0.4, 0.45, 1), intensity: 0.1))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name),
                            MeshRenderer(mesh: .cube, material: MaterialHandle(material), castsShadows: false))
        }
        box("Street", "street", center: Vec3(0, -0.5, -10), size: Vec3(40, 1, 70))
        // Two rows of buildings; the street runs along -Z. Their faces are at x = +-5.
        let heights: [Float] = [11, 15, 9, 17, 12, 20]
        for (i, h) in heights.enumerated() {
            let z = 4 - Float(i) * 7
            box("Left building \(i)", "wall", center: Vec3(-8.5, h / 2, z), size: Vec3(7, h, 6.4))
            box("Right building \(i)", "wall", center: Vec3(8.5, h / 2 - 1, z - 2), size: Vec3(7, h + 2, 6.4))
            for row in 0..<3 where (i + row) % 2 == 0 {
                box("Window", "window", center: Vec3(-4.97, 7 + Float(row) * 2.2, z + 1.2), size: Vec3(0.05, 0.9, 1.4))
                box("Window", "window", center: Vec3(4.97, 6 + Float(row) * 2.2, z - 0.8), size: Vec3(0.05, 0.9, 1.4))
            }
        }

        let japanese = ["ラーメン", "麺屋 夜市", "電脳酒場", "ネオン街"]
        let cjk = Self.cjkFont(covering: japanese.joined(separator: " ")) ?? ""
        func jp(_ japanese: String, _ latin: String) -> (text: String, font: String) { cjk.isEmpty ? (latin, "") : (japanese, cjk) }

        /// A dark panel with a neon `TextMesh` in front of it, on a wall facing `facing` (+1: toward +X).
        func sign(_ text: String, font: String = "", at position: Vec3, facing: Float, size: Float, color: Vec3,
                  strength: Float, glow: Float = 0.06, outline: Float = 0, outlineColor: Vec3 = .zero, aspect: Float = 4,
                  lines: Float = 1) -> Entity {
            let yaw = Quat(angle: facing > 0 ? .pi / 2 : -.pi / 2, axis: Vec3(0, 1, 0))
            let width = size * aspect + 0.6, height = size * 1.25 * lines + 0.5
            _ = world.spawn(Transform(position: position - Vec3(facing * 0.06, 0, 0), rotation: yaw, scale: Vec3(width, height, 0.1)),
                            Name("Sign panel"), MeshRenderer(mesh: .cube, material: MaterialHandle("panel"), castsShadows: false))
            let entity = world.spawn(
                Transform(position: position, rotation: yaw), Name("Sign: \(text)"),
                TextMesh(text, font: font, size: size, color: color * 0.25, emissiveColor: color, emissiveStrength: strength,
                         outlineWidth: outline, outlineColor: outlineColor, glowSize: glow, glowStrength: 0.6))
            _ = world.spawn(Transform(position: position + Vec3(facing * -2, 0, 0)), PointLight(color: color, intensity: 14, range: 9))
            return entity
        }

        let ramen = jp(japanese[0], "RAMEN")
        _ = sign(ramen.text, font: ramen.font, at: Vec3(-4.9, 8.2, 3.2), facing: 1, size: 1.5, color: Vec3(1, 0.1, 0.45), strength: 7,
                 aspect: 4.2)
        let yoichi = jp(japanese[1], "NOODLE BAR")
        _ = sign(yoichi.text, font: yoichi.font, at: Vec3(-4.9, 4.4, -3.4), facing: 1, size: 0.8, color: Vec3(0.1, 0.9, 1), strength: 6,
                 outline: 0.03, outlineColor: Vec3(0.02, 0.2, 0.3), aspect: 4.8)
        let bar = jp(japanese[2], "CYBER BAR")
        _ = sign(bar.text, font: bar.font, at: Vec3(4.9, 9, -2.2), facing: -1, size: 1.3, color: Vec3(0.75, 0.2, 1), strength: 6,
                 aspect: 4.2)
        flicker = sign("OPEN\n24H", at: Vec3(4.9, 3.6, 3.6), facing: -1, size: 0.65, color: Vec3(0.2, 1, 0.45), strength: 5,
                       glow: 0.1, aspect: 2.4, lines: 2)
        // The big Latin sign across the far end of the street.
        _ = world.spawn(Transform(position: Vec3(0, 7.2, -33), scale: Vec3(9, 2.4, 0.2)), Name("Far panel"),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("panel"), castsShadows: false))
        _ = world.spawn(Transform(position: Vec3(0, 7.2, -32.8)), Name("Sign: NEON NOODLE"),
                        TextMesh("NEON NOODLE", size: 1.3, color: Vec3(0.2, 0.2, 0.05), emissiveColor: Vec3(1, 0.85, 0.2),
                                 emissiveStrength: 6, glowSize: 0.08))
        _ = world.spawn(Transform(position: Vec3(0, 7.2, -32.8)), PointLight(color: Vec3(1, 0.8, 0.3), intensity: 16, range: 18))
        // A billboard hovering over the street that turns to face the camera.
        let district = jp(japanese[3], "NEON DISTRICT")
        _ = world.spawn(Transform(position: Vec3(0, 13, -8)), Name("Billboard"),
                        TextMesh(district.text + "\nNEON DISTRICT", font: district.font, size: 1.4, color: Vec3(0.1, 0.1, 0.1),
                                 emissiveColor: Vec3(0.3, 0.8, 1), emissiveStrength: 5, glowSize: 0.07, billboard: true))
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.12, distance: 17, target: Vec3(0, 4.5, 0)) }
    var lighting: Lighting { Lighting(fogColor: Vec3(0.03, 0.02, 0.07)) }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(engine: Engine, dt: Float, time: Float) {
        // The OPEN sign stutters like a failing tube (a deterministic function of the clock).
        let on: Float = sinf(time * 23) * sinf(time * 7.3) > 0.8 ? 0.15 : 1
        world.modify(TextMesh.self, for: flicker) { $0.emissiveStrength = 5 * on }
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
