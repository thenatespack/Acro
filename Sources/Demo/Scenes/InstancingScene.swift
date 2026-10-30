import Engine
import Foundation

/// A large rippling heightfield of cubes, uploaded once per frame into transient memory
/// and drawn from there by both the shadow and the screen pass. I cycles the grid size.
final class InstancingScene: DemoScene {
    static let name = "instancing"
    static let summary = "3.6k–40k instances per draw, large per-frame transient uploads"

    private static let gridSizes = [60, 120, 200]
    private let renderer: Renderer
    private var sizeIndex = 1
    private var instances: [Instance] = []
    private var uploaded: FrameInstances?

    init(renderer: Renderer) throws {
        self.renderer = renderer
    }

    var initialView: OrbitView { OrbitView(yaw: 0.5, pitch: 0.7, distance: 75, target: .zero) }
    var lighting: Lighting { Lighting(direction: Vec3(0.4, 0.8, 0.3), fogDensity: 0.004, shadowExtent: 60) }
    var status: String { "\(instances.count) instances" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        ViewCamera(eye: orbitEye, target: target, far: 400)
    }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.i) { sizeIndex = (sizeIndex + 1) % Self.gridSizes.count }
        let n = Self.gridSizes[sizeIndex]
        let spacing: Float = 80 / Float(n)
        let half = Float(n - 1) / 2
        let size = spacing * 0.42
        instances.removeAll(keepingCapacity: true)
        instances.reserveCapacity(n * n)
        for z in 0..<n {
            for x in 0..<n {
                let p = Vec2(Float(x) - half, Float(z) - half) * spacing
                // Two interfering ripples.
                let d1 = ((p - Vec2(-12, -8)) * (p - Vec2(-12, -8))).sum().squareRoot()
                let d2 = ((p - Vec2(15, 10)) * (p - Vec2(15, 10))).sum().squareRoot()
                let h = sinf(d1 * 0.35 - t * 2) + sinf(d2 * 0.3 - t * 1.6)
                let height = 2 + h * 1.5
                instances.append(Instance(
                    .trs(Vec3(p.x, height / 2, p.y), scale: Vec3(size, max(height, 0.1) / 2, size)),
                    color: hsv(0.55 + h * 0.12, 0.6, 0.65 + h * 0.15)))
            }
        }
    }

    func renderOffscreen(frame: Frame) {
        uploaded = renderer.upload(instances, in: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, [floorInstance(halfSize: 45)])
        if let uploaded { renderer.draw(pass, renderer.cube, uploaded) }
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        drawShadowCasters(pass)
    }
}
