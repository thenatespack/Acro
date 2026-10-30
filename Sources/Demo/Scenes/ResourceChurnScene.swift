import Engine
import Foundation

/// Creates and drops GPU resources continuously while they're in use:
/// - a new instance buffer every frame
/// - new cube mesh buffers every 10 frames
/// - a new depth texture (rendered into, then sampled by nothing) every 30 frames
/// - a new pipeline every 60 frames
/// Run it with Vulkan validation to check the deletion queue; memory should stay flat.
final class ResourceChurnScene: DemoScene {
    static let name = "churn"
    static let summary = "continuous buffer/texture/pipeline creation and release while in flight"

    private let renderer: Renderer
    private var frame = 0
    private var mesh: Mesh
    private var instanceBuffer: GPUBuffer?
    private var instanceCount = 0
    private var scratchTexture: GPUTexture?
    private var pipeline: RenderPipeline
    private var created = (buffers: 0, textures: 0, pipelines: 0)

    init(renderer: Renderer) throws {
        self.renderer = renderer
        mesh = try renderer.makeCubeMesh()
        pipeline = try renderer.makeLitPipeline(.opaque)
    }

    var initialView: OrbitView { OrbitView(yaw: 0.9, pitch: 0.5, distance: 24, target: Vec3(0, 2, 0)) }
    var lighting: Lighting { Lighting(direction: Vec3(0.5, 0.8, -0.2), shadowExtent: 18) }
    var status: String {
        "created \(created.buffers) buffers, \(created.textures) textures, \(created.pipelines) pipelines"
    }

    func update(input: Input, dt: Float, time t: Float) {
        do {
            try churn(time: t)
        } catch {
            print("Churn failed: \(error)")
        }
        frame += 1
    }

    private func churn(time t: Float) throws {
        if frame % 10 == 0 {
            mesh = try renderer.makeCubeMesh()
            created.buffers += 2
        }
        if frame % 30 == 0 {
            let size = 128 << (frame / 30 % 3)
            scratchTexture = try renderer.device.makeTexture(TextureDescriptor(width: size, height: size, format: .depth32Float))
            created.textures += 1
        }
        if frame % 60 == 0 {
            pipeline = try renderer.makeLitPipeline(.opaque)
            created.pipelines += 1
        }

        var instances = [floorInstance(halfSize: 14)]
        let count = 150 + Int(sinf(t) * 50)  // buffer size changes every frame too
        for i in 0..<count {
            let f = Float(i)
            let angle = f * 0.618 * 2 * .pi + t * (0.2 + f.truncatingRemainder(dividingBy: 7) * 0.05)
            let radius = 2 + f.truncatingRemainder(dividingBy: 23) * 0.4
            instances.append(Instance(
                .trs(Vec3(cosf(angle) * radius, 0.5 + f.truncatingRemainder(dividingBy: 11) * 0.45, sinf(angle) * radius),
                     angle: t + f, axis: Vec3(1, 1, 0), scale: Vec3(repeating: 0.25)),
                color: hsv(f / Float(count), 0.6, 0.95)))
        }
        instanceBuffer = try renderer.device.makeBuffer(instances, usage: .vertex)
        instanceCount = instances.count
        created.buffers += 1
    }

    func renderOffscreen(frame: Frame) {
        guard let scratchTexture, let instanceBuffer else { return }
        frame.depthPass(into: scratchTexture) { pass in
            pass.setPipeline(renderer.shadowPipeline)
            renderer.bind(pass)
            renderer.draw(pass, mesh, instanceBuffer: instanceBuffer, count: instanceCount)
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {
        guard let instanceBuffer else { return }
        renderer.draw(pass, mesh, instanceBuffer: instanceBuffer, count: instanceCount)
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(pipeline)
        drawShadowCasters(pass)
    }
}
