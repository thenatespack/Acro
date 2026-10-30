import Engine
import Foundation

/// Three columns, one per cull mode: back (left), front (middle), none (right). Each has
/// a spinning cube and, above it, a spinning single-sided quad. Expected:
/// - back: solid cube; quad only visible from its front
/// - front: you see the cube's inside faces; quad only visible from its back
/// - none: solid cube; quad visible from both sides
final class CullingScene: DemoScene {
    static let name = "culling"
    static let summary = "cull modes and counter-clockwise winding on both backends"

    private static let modes: [CullMode] = [.back, .front, .none]
    private let renderer: Renderer
    private var floor: [Instance] = [floorInstance(halfSize: 12)]
    private var cubes: [[Instance]] = []
    private var quads: [[Instance]] = []

    init(renderer: Renderer) throws {
        self.renderer = renderer
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.3, distance: 18, target: Vec3(0, 2.5, 0)) }
    var lighting: Lighting { Lighting(direction: Vec3(0.3, 0.9, 0.6), shadowExtent: 14) }

    func update(input: Input, dt: Float, time t: Float) {
        let tints = [Vec3(0.3, 0.85, 0.35), Vec3(0.9, 0.3, 0.25), Vec3(0.95, 0.8, 0.25)]
        cubes = (0..<3).map { i in
            [Instance(.trs(Vec3(Float(i - 1) * 5, 1.5, 0), angle: t * 0.7, axis: Vec3(0.3, 1, 0.2), scale: Vec3(repeating: 1.2)),
                      color: tints[i])]
        }
        quads = (0..<3).map { i in
            [Instance(.trs(Vec3(Float(i - 1) * 5, 4.4, 0), angle: t * 0.9, scale: Vec3(repeating: 1.1)), color: tints[i])]
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, floor)
        for i in 0..<3 {
            renderer.draw(pass, renderer.cube, cubes[i])
            renderer.draw(pass, renderer.quad, quads[i])
        }
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        renderer.draw(pass, renderer.cube, floor)
        for (i, mode) in Self.modes.enumerated() {
            pass.setPipeline(try renderer.litPipeline(LitStyle(cullMode: mode)))
            renderer.draw(pass, renderer.cube, cubes[i])
            renderer.draw(pass, renderer.quad, quads[i])
        }
    }
}
