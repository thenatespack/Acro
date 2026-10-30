import Engine
import Foundation

struct Vertex {
    var position: Vec3
    var normal: Vec3
}

/// Per-instance data (vertex buffer slot 1).
struct Instance {
    var model: Mat4
    /// rgb in linear space, a = opacity (only used by blended pipelines).
    var color: Vec4
    /// x: checkerboard pattern, y: emissive (0 = lit, 1 = unlit),
    /// z/w: animation phase / bob amplitude (see `animated`).
    var params: Vec4

    init(_ model: Mat4, color: Vec3, opacity: Float = 1, checker: Bool = false, emissive: Float = 0) {
        self.model = model
        self.color = Vec4(color, opacity)
        self.params = Vec4(checker ? 1 : 0, emissive, 0, 0)
    }

    /// Animated by the vertex shader, so the instance can live in a static buffer: it spins
    /// about its local Y axis at 1 rad/s and bobs ±`bob` at 2 rad/s, offset by `phase`
    /// (angle = time + phase, height offset = sin(2 time + phase) * bob). `model` is the
    /// rest pose and must scale uniformly.
    func animated(phase: Float, bob: Float) -> Instance {
        var instance = self
        instance.params.z = phase
        instance.params.w = bob
        return instance
    }
}

/// Matches `Scene` in the lit/shadow shaders (std140-compatible: only mat4 and vec4).
struct SceneUniforms {
    var viewProj: Mat4
    var lightViewProj: Mat4
    var lightDir: Vec4
    var cameraPos: Vec4
    var fogColor: Vec4
    var shadowParams: Vec4
}

struct Mesh {
    var vertexBuffer: GPUBuffer
    var indexBuffer: GPUBuffer
    var indexCount: Int
}

struct Lighting {
    /// Direction toward the sun.
    var direction = normalize(Vec3(0.5, 0.75, 0.35))
    var intensity: Float = 1.3
    var fogColor = Vec3(0.62, 0.7, 0.82)
    var fogDensity: Float = 0.006
    /// Half-size of the sun's orthographic shadow frustum, centered on the origin.
    var shadowExtent: Float = 34
}

struct Camera {
    var eye: Vec3
    var target: Vec3
    var fovY: Float = .pi / 3.5
    var near: Float = 0.5
    var far: Float = 200
    /// Maps near → 1 and far → 0 for far better float-depth precision. Needs pipelines
    /// with `.greater` depth compare and a depth clear of 0.
    var reversedZ = false

    func viewProjection(aspect: Float) -> Mat4 {
        let projection = reversedZ
            ? Mat4.perspective(fovY: fovY, aspect: aspect, near: far, far: near)
            : Mat4.perspective(fovY: fovY, aspect: aspect, near: near, far: far)
        return projection * Mat4.lookAt(eye: eye, target: target)
    }
}

/// Fixed-function variations of the lit pipeline.
struct LitStyle: Hashable {
    var cullMode: CullMode = .back
    var blending = false
    var reversedZ = false
    var depthTest = true
    /// false draws depth-tested but invisible geometry (no color or depth writes).
    var colorWrites = true

    static let opaque = LitStyle()
    static let transparent = LitStyle(blending: true)
    /// Bounding boxes for occlusion queries. Double-sided so a box still produces samples
    /// when its front faces are clipped by the near plane.
    static let occlusionProxy = LitStyle(cullMode: .none, colorWrites: false)
    /// Translucent and drawn over everything (debug views).
    static let xray = LitStyle(blending: true, depthTest: false)
}

/// Shared GPU resources and helpers used by every scene: cube and quad meshes, the
/// lit and shadow pipelines, the shadow map, and per-frame uniforms.
@MainActor
final class Renderer {
    let device: RenderDevice
    let quality: RenderQuality
    private(set) var cube: Mesh!
    private(set) var quad: Mesh!
    private(set) var shadowPipeline: RenderPipeline!
    private(set) var shadowMap: GPUTexture!
    private(set) var uniforms: SceneUniforms!
    private(set) var eye = Vec3.zero

    private let litShader: ShaderSource
    private let shadowShader: ShaderSource
    private var litPipelines: [LitStyle: RenderPipeline] = [:]

    static let vertexLayout = VertexLayout(
        stride: MemoryLayout<Vertex>.stride,
        attributes: [
            VertexAttribute(location: 0, format: .float3, offset: MemoryLayout<Vertex>.offset(of: \.position)!),
            VertexAttribute(location: 1, format: .float3, offset: MemoryLayout<Vertex>.offset(of: \.normal)!),
        ])

    static let instanceLayout = VertexLayout(
        stride: MemoryLayout<Instance>.stride,
        attributes: (0..<4).map { VertexAttribute(location: 2 + $0, format: .float4, offset: $0 * MemoryLayout<Vec4>.stride) } + [
            VertexAttribute(location: 6, format: .float4, offset: MemoryLayout<Instance>.offset(of: \.color)!),
            VertexAttribute(location: 7, format: .float4, offset: MemoryLayout<Instance>.offset(of: \.params)!),
        ])

    init(device: RenderDevice, quality: RenderQuality) throws {
        self.device = device
        self.quality = quality
        litShader = try ShaderSource.load(named: "lit", bundle: .module)
        shadowShader = try ShaderSource.load(named: "shadow", bundle: .module)
        cube = try makeCubeMesh()
        quad = try makeQuadMesh()

        var shadow = PipelineDescriptor(shader: shadowShader, vertexLayout: Self.vertexLayout, instanceLayout: Self.instanceLayout)
        shadow.target = .depthOnly
        shadow.cullMode = .none  // single-sided quads still cast shadows
        shadow.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
        shadowPipeline = try device.makePipeline(shadow)
        shadowMap = try device.makeTexture(
            TextureDescriptor(width: quality.shadowMapSize, height: quality.shadowMapSize, format: .depth32Float))
    }

    /// The cached lit pipeline for `style`.
    func litPipeline(_ style: LitStyle = .opaque) throws -> RenderPipeline {
        if let pipeline = litPipelines[style] { return pipeline }
        let pipeline = try makeLitPipeline(style)
        litPipelines[style] = pipeline
        return pipeline
    }

    /// A new, uncached lit pipeline.
    func makeLitPipeline(_ style: LitStyle) throws -> RenderPipeline {
        var descriptor = PipelineDescriptor(shader: litShader, vertexLayout: Self.vertexLayout, instanceLayout: Self.instanceLayout)
        descriptor.cullMode = style.cullMode
        descriptor.alphaBlending = style.blending
        descriptor.depthWrite = !style.blending && style.colorWrites
        descriptor.depthTest = style.depthTest
        descriptor.colorWrites = style.colorWrites
        descriptor.depthCompare = style.reversedZ ? .greater : .less
        return try device.makePipeline(descriptor)
    }

    /// A unit cube (half-extent 1) with per-face normals.
    func makeCubeMesh() throws -> Mesh {
        // (normal, u, v) with u × v = normal so each face winds counter-clockwise from outside.
        let x = Vec3(1, 0, 0), y = Vec3(0, 1, 0), z = Vec3(0, 0, 1)
        return try makeMesh(faces: [(x, y, z), (-x, z, y), (y, z, x), (-y, x, z), (z, x, y), (-z, y, x)])
    }

    /// A single-sided unit quad in the XY plane facing +Z.
    func makeQuadMesh() throws -> Mesh {
        try makeMesh(faces: [(Vec3(0, 0, 1), Vec3(1, 0, 0), Vec3(0, 1, 0))], offset: 0)
    }

    private func makeMesh(faces: [(Vec3, Vec3, Vec3)], offset: Float = 1) throws -> Mesh {
        var vertices: [Vertex] = []
        var indices: [UInt16] = []
        for (n, u, v) in faces {
            let base = UInt16(vertices.count)
            for (a, b) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
                vertices.append(Vertex(position: n * offset + u * a + v * b, normal: n))
            }
            indices += [base, base + 1, base + 2, base, base + 2, base + 3]
        }
        return Mesh(
            vertexBuffer: try device.makeBuffer(vertices, usage: .vertex),
            indexBuffer: try device.makeBuffer(indices, usage: .index),
            indexCount: indices.count)
    }

    /// Computes this frame's uniforms. Call once per frame before any pass.
    func prepare(camera: Camera, lighting: Lighting, aspect: Float, time: Float) {
        let light = normalize(lighting.direction)
        let lightView = Mat4.lookAt(eye: light * 60, target: .zero, up: abs(light.y) > 0.99 ? Vec3(0, 0, 1) : Vec3(0, 1, 0))
        let e = lighting.shadowExtent
        let lightProjection = Mat4.orthographic(left: -e, right: e, bottom: -e, top: e, near: 1, far: 60 + e * 2)
        eye = camera.eye
        uniforms = SceneUniforms(
            viewProj: camera.viewProjection(aspect: aspect),
            lightViewProj: lightProjection * lightView,
            lightDir: Vec4(light, lighting.intensity),
            cameraPos: Vec4(camera.eye, time),
            fogColor: Vec4(lighting.fogColor, lighting.fogDensity),
            shadowParams: Vec4(1 / Float(quality.shadowMapSize), 0.0005, Float(quality.shadowFilterRadius), 0))
    }

    func bind(_ pass: RenderPass) {
        pass.setUniforms(uniforms)
    }

    /// Draws per-frame instances (copied into transient memory on every call).
    func draw(_ pass: RenderPass, _ mesh: Mesh, _ instances: [Instance]) {
        guard !instances.isEmpty else { return }
        setMesh(pass, mesh)
        pass.setVertexData(instances, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: instances.count)
    }

    /// Draws `count` instances stored in a GPU buffer, starting at instance `first`.
    func draw(_ pass: RenderPass, _ mesh: Mesh, instanceBuffer: GPUBuffer, first: Int = 0, count: Int) {
        guard count > 0 else { return }
        setMesh(pass, mesh)
        pass.setVertexBuffer(instanceBuffer, offset: first * MemoryLayout<Instance>.stride, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: count)
    }

    /// Copies instances into this frame's transient memory once, so the shadow and screen
    /// passes can both draw them without uploading them again.
    func upload(_ instances: [Instance], in frame: Frame) -> FrameInstances {
        FrameInstances(buffer: frame.upload(instances), count: instances.count)
    }

    /// Draws `count` (default: all) of this frame's uploaded instances, starting at `first`.
    func draw(_ pass: RenderPass, _ mesh: Mesh, _ instances: FrameInstances, first: Int = 0, count: Int? = nil) {
        let count = count ?? instances.count - first
        guard count > 0 else { return }
        setMesh(pass, mesh)
        let offset = instances.buffer.offset + first * MemoryLayout<Instance>.stride
        pass.setVertexBuffer(instances.buffer.buffer, offset: offset, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: count)
    }

    /// Binds a mesh's vertex and index buffers.
    func setMesh(_ pass: RenderPass, _ mesh: Mesh) {
        pass.setVertexBuffer(mesh.vertexBuffer)
        pass.setIndexBuffer(mesh.indexBuffer, type: .uint16)
    }
}

/// Instances in the current frame's transient memory (see `Renderer.upload`). Only valid
/// during the frame they were uploaded in.
struct FrameInstances {
    var buffer: TransientBuffer
    var count: Int
}

/// HSV to linear RGB (the swapchain is sRGB, so colors are squared as a cheap gamma decode).
func hsv(_ h: Float, _ s: Float, _ v: Float) -> Vec3 {
    let k = Vec3(5, 3, 1)
    var rgb = Vec3.zero
    for i in 0..<3 {
        let t = (k[i] + h * 6).truncatingRemainder(dividingBy: 6)
        rgb[i] = v - v * s * max(0, min(t, 4 - t, 1))
    }
    return rgb * rgb
}

/// Small deterministic RNG so scenes (and screenshots) are reproducible.
struct SplitMix64 {
    var state: UInt64
    mutating func next() -> Float {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float((z ^ (z >> 31)) >> 40) / Float(1 << 24)
    }
}

extension Mat4 {
    static func trs(_ t: Vec3, angle: Float = 0, axis: Vec3 = Vec3(0, 1, 0), scale: Vec3 = Vec3(repeating: 1)) -> Mat4 {
        translation(t) * rotation(angle: angle, axis: axis) * Mat4.scale(scale)
    }
}

/// The checkered floor used by most scenes.
func floorInstance(halfSize: Float = 26) -> Instance {
    Instance(.trs(Vec3(0, -0.5, 0), scale: Vec3(halfSize, 0.5, halfSize)), color: Vec3(0.55, 0.53, 0.5), checker: true)
}
