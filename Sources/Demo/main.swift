import Engine
import Foundation

struct Vertex {
    var x, y, z: Float
    var r, g, b: Float
}

struct PushConstants {
    var mvp: Mat4
}

final class CubeDemo: Game {
    private var pipeline: RenderPipeline!
    private var vertexBuffer: GPUBuffer!
    private var indexBuffer: GPUBuffer!
    private var indexCount = 0

    private var yaw: Float = 0.6
    private var pitch: Float = 0.4
    private var distance: Float = 9
    private var autoSpin = true
    private var palette = 0

    func setup(engine: Engine) throws {
        engine.title = "Demo — \(engine.device.backend.rawValue) on \(engine.device.deviceName)"
        try buildMesh(device: engine.device)

        let layout = VertexLayout(
            stride: MemoryLayout<Vertex>.stride,
            attributes: [
                VertexAttribute(location: 0, format: .float3, offset: MemoryLayout<Vertex>.offset(of: \.x)!),
                VertexAttribute(location: 1, format: .float3, offset: MemoryLayout<Vertex>.offset(of: \.r)!),
            ])
        let shader = try ShaderSource.load(named: "cube", bundle: .module)
        pipeline = try engine.device.makePipeline(PipelineDescriptor(shader: shader, vertexLayout: layout))
    }

    /// Creates fresh vertex/index buffers. Replacing the old ones releases them; the
    /// backend frees the GPU memory once in-flight frames are done with it.
    private func buildMesh(device: RenderDevice) throws {
        let corners: [(Float, Float, Float)] = [
            (-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1),
            (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1),
        ]
        let vertices = corners.map { x, y, z in
            // Color from position; each palette rotates the channels.
            let c = [(x + 1) / 2, (y + 1) / 2, (z + 1) / 2]
            let p = palette % 3
            return Vertex(x: x, y: y, z: z, r: c[p], g: c[(p + 1) % 3], b: c[(p + 2) % 3])
        }
        // Counter-clockwise when viewed from outside the cube.
        let indices: [UInt16] = [
            4, 5, 6, 4, 6, 7,  // +Z
            1, 0, 3, 1, 3, 2,  // -Z
            5, 1, 2, 5, 2, 6,  // +X
            0, 4, 7, 0, 7, 3,  // -X
            7, 6, 2, 7, 2, 3,  // +Y
            0, 1, 5, 0, 5, 4,  // -Y
        ]
        vertexBuffer = try device.makeBuffer(vertices, usage: .vertex)
        indexBuffer = try device.makeBuffer(indices, usage: .index)
        indexCount = indices.count
    }

    func update(engine: Engine, dt: Float) {
        let input = engine.input
        if input.wasPressed(.escape) { engine.quit() }
        if input.wasPressed(.space) { autoSpin.toggle() }
        if input.wasPressed(.r) {
            palette += 1
            do { try buildMesh(device: engine.device) } catch { print("Rebuild failed: \(error)") }
        }

        yaw += input.axis(negative: .left, positive: .right) * 2 * dt
        yaw += input.axis(negative: .a, positive: .d) * 2 * dt
        pitch += input.axis(negative: .down, positive: .up) * 2 * dt
        pitch += input.axis(negative: .s, positive: .w) * 2 * dt
        distance -= input.axis(negative: .e, positive: .q) * 4 * dt
        if input.isDown(.left as MouseButton) {
            yaw -= input.mouseDelta.x * 0.01
            pitch += input.mouseDelta.y * 0.01
        }
        if autoSpin { yaw += 0.5 * dt }

        pitch = min(max(pitch, -1.5), 1.5)
        distance = min(max(distance, 2.5), 20)
    }

    func render(engine: Engine, pass: RenderPass) {
        let eye = Vec3(cosf(pitch) * sinf(yaw), sinf(pitch), cosf(pitch) * cosf(yaw)) * distance
        let view = Mat4.lookAt(eye: eye, target: .zero)
        let projection = Mat4.perspective(fovY: .pi / 3, aspect: engine.aspectRatio, near: 0.1, far: 100)

        pass.setPipeline(pipeline)
        pass.setVertexBuffer(vertexBuffer)
        pass.setIndexBuffer(indexBuffer, type: .uint16)

        // A row of cubes so depth testing and culling are easy to eyeball.
        for i in -1...1 {
            let model = Mat4.translation(Vec3(Float(i) * 3, 0, 0))
                * Mat4.rotation(angle: Float(engine.time) * Float(i + 2) * 0.7, axis: Vec3(1, 1, 0))
                * Mat4.scale(Vec3(repeating: 0.8))
            pass.setPushConstants(PushConstants(mvp: projection * view * model))
            pass.drawIndexed(indexCount: indexCount)
        }
    }
}

let arguments = CommandLine.arguments
var config = EngineConfig(title: "Demo")
if let i = arguments.firstIndex(of: "--backend"), i + 1 < arguments.count {
    guard let backend = GraphicsBackend(rawValue: arguments[i + 1]) else {
        print("Unknown backend '\(arguments[i + 1])'. Available: \(GraphicsBackend.available.map(\.rawValue))")
        exit(1)
    }
    config.backend = backend
}

do {
    let engine = try Engine(config: config)
    print("Running on \(engine.device.backend.rawValue): \(engine.device.deviceName)")
    try engine.run(CubeDemo())
} catch {
    print("Fatal: \(error)")
    exit(1)
}
