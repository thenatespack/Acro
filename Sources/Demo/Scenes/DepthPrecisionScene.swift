import Engine
import Foundation

/// Pairs of nearly coplanar boxes at 10 m … 20 km with a 0.05 m near plane. Each blue box
/// sits 0.01% of its distance in front of a red one. With standard depth the far pairs
/// z-fight; reversed-Z (Z toggles) keeps them all clean.
final class DepthPrecisionScene: DemoScene {
    static let name = "depth"
    static let summary = "depth precision over a huge range, standard vs reversed-Z (Z toggles)"

    private static let distances: [Float] = [10, 100, 1000, 5000, 20000]
    private let renderer: Renderer
    private var reversedZ = false
    private var instances: [Instance] = []

    init(renderer: Renderer) throws {
        self.renderer = renderer
    }

    var lighting: Lighting { Lighting(fogDensity: 0) }
    var status: String { reversedZ ? "reversed-Z" : "standard Z" }

    /// Fixed camera at the origin looking down -Z (ignores the orbit controls).
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        ViewCamera(eye: .zero, target: Vec3(0, 0, -1), fovY: .pi / 3, near: 0.05, far: 50_000, reversedZ: reversedZ)
    }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.z) { reversedZ.toggle() }
        instances.removeAll(keepingCapacity: true)
        for (k, d) in Self.distances.enumerated() {
            // Evenly spaced across the screen, constant apparent size.
            let center = Vec3((Float(k) - 2) * 0.36 * d, 0, -d)
            let spin = t * 0.3 + Float(k)
            let size = Vec3(0.13 * d, 0.13 * d, 0.02 * d)
            let offset = d * 1e-4
            instances.append(Instance(
                .trs(center, angle: spin, axis: Vec3(0, 0, 1), scale: size), color: Vec3(0.9, 0.1, 0.1), emissive: 1))
            instances.append(Instance(
                .trs(center + Vec3(0, 0, offset), angle: spin + 0.4, axis: Vec3(0, 0, 1), scale: size * Vec3(0.8, 0.8, 1)),
                color: Vec3(0.1, 0.3, 0.95), emissive: 1))
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline(LitStyle(reversedZ: reversedZ)))
        renderer.draw(pass, renderer.cube, instances)
    }
}
