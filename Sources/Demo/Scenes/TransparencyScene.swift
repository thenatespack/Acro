import Engine
import Foundation

/// Alpha-blended glass panes and cubes over an opaque, shadowed scene. Transparent
/// objects are sorted back to front every frame and drawn without depth writes.
/// O toggles sorting so you can see what goes wrong without it.
final class TransparencyScene: DemoScene {
    static let name = "transparency"
    static let summary = "alpha blending, depth writes off, back-to-front sorting"

    private let renderer: Renderer
    private var opaque: [Instance] = []
    private var transparent: [Instance] = []
    private var sorted = true

    init(renderer: Renderer) throws {
        self.renderer = renderer
    }

    var initialView: OrbitView { OrbitView(yaw: 0.4, pitch: 0.4, distance: 17, target: Vec3(0, 2.5, 0)) }
    var lighting: Lighting { Lighting(direction: Vec3(-0.4, 0.8, 0.5), shadowExtent: 20) }
    var status: String { sorted ? "sorted" : "UNSORTED" }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.o) { sorted.toggle() }

        opaque = [floorInstance(halfSize: 16)]
        for i in 0..<6 {
            let angle = Float(i) / 6 * 2 * .pi
            opaque.append(Instance(
                .trs(Vec3(cosf(angle) * 4, 1.5, sinf(angle) * 4), angle: -angle, scale: Vec3(0.5, 1.5, 0.5)),
                color: hsv(Float(i) / 6, 0.5, 0.9)))
        }
        opaque.append(Instance(.trs(Vec3(0, 1, 0), angle: t * 0.5, scale: Vec3(repeating: 1)), color: Vec3(0.9, 0.9, 0.9)))

        transparent.removeAll(keepingCapacity: true)
        // A slowly turning ring of tall glass panes.
        let panes = 10
        for i in 0..<panes {
            let angle = Float(i) / Float(panes) * 2 * .pi + t * 0.15
            transparent.append(Instance(
                .trs(Vec3(cosf(angle) * 8, 2.5, sinf(angle) * 8), angle: .pi / 2 - angle, scale: Vec3(1.6, 2.5, 0.05)),
                color: hsv(Float(i) / Float(panes), 0.8, 1), opacity: 0.35))
        }
        // Floating tinted cubes weaving between the pillars.
        for i in 0..<8 {
            let f = Float(i)
            let angle = f / 8 * 2 * .pi - t * 0.4
            transparent.append(Instance(
                .trs(Vec3(cosf(angle) * 5.5, 3.5 + sinf(t * 1.3 + f) * 1.2, sinf(angle) * 5.5), angle: t + f,
                     axis: Vec3(1, 1, 0), scale: Vec3(repeating: 0.7)),
                color: hsv(f / 8 + 0.5, 0.7, 1), opacity: 0.5))
        }

        if sorted {
            let eye = renderer.eye
            func distanceSquared(_ instance: Instance) -> Float {
                let d = Vec3(instance.model.c3.x, instance.model.c3.y, instance.model.c3.z) - eye
                return dot(d, d)
            }
            transparent.sort { distanceSquared($0) > distanceSquared($1) }
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, opaque)
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        renderer.draw(pass, renderer.cube, opaque)
        pass.setPipeline(try renderer.litPipeline(.transparent))
        renderer.draw(pass, renderer.cube, transparent)
    }
}
