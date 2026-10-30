import Foundation

/// A mesh uploaded to the GPU (vertex buffer 0 in `MeshVertex` layout, 32-bit indices).
public struct GPUMesh {
    public var vertexBuffer: GPUBuffer
    public var indexBuffer: GPUBuffer
    public var indexCount: Int
    /// Local-space bounds of the vertices, used for culling.
    public var bounds: Bounds
}

/// Timing and counts of the last frame `SceneRenderer` prepared.
public struct SceneRenderStats: Sendable {
    public var list = RenderListStats()
    /// CPU seconds spent gathering, culling and batching (`prepare`).
    public var prepareTime: Double = 0
}

/// Draws a `World`'s entities: a forward renderer with one shadow-casting directional light,
/// hemisphere ambient, exponential fog, instancing, frustum and shadow-caster culling, a
/// back-to-front sorted transparent pass and motion vectors for temporal upscalers.
///
/// Opt-in, driven by the game:
///
/// ```swift
/// func setup(engine: Engine) throws { sceneRenderer = try SceneRenderer(engine: engine) }
/// func renderOffscreen(engine: Engine, frame: Frame) {
///     sceneRenderer.prepare(world: world, engine: engine)   // gather, cull, batch; sets clear color/depth
///     sceneRenderer.renderShadows(frame: frame)             // upload instances, shadow pass
/// }
/// func render(engine: Engine, pass: RenderPass) { sceneRenderer.draw(pass) }
/// ```
///
/// (`renderOffscreen(world:engine:frame:)` does the first two in one call.) Call `prepare`
/// after the world's transforms are up to date for the frame, i.e. after `world.update`.
///
/// What gets drawn comes from components: the active `Camera`, the first `DirectionalLight`,
/// the first `SceneEnvironment` and every entity with a `MeshRenderer` and a
/// `GlobalTransform`. Meshes and materials are registered under string keys; the built-in
/// meshes `MeshHandle.cube`, `.plane`, `.sphere` and `MaterialHandle.default` exist from the start.
@MainActor
public final class SceneRenderer {
    public let device: RenderDevice
    public let quality: RenderQuality
    /// Renders from this entity's `Camera` instead of the first active one.
    public var camera: Entity?
    public private(set) var stats = SceneRenderStats()
    /// The CPU side: registries of mesh bounds and material flags, motion history, gathered items.
    public private(set) var prep = RenderPrep()
    public private(set) var list = RenderList()

    private var meshes: [GPUMesh] = []
    private var materials: [(material: Material, sampler: GPUSampler)] = []
    private let whiteTexture: GPUTexture
    private let shader: ShaderSource
    private let shadowPipeline: RenderPipeline
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    public let shadowMap: GPUTexture
    private var shadowMapCleared = false

    private var uniforms: FrameUniforms?
    private var reversedZ = false
    private var shadowsActive = false
    private var uploaded: TransientBuffer?
    private var previousViewProj: Mat4?
    private var reportedMissing: Set<String> = []

    /// Must match `Frame` in mesh.vert / mesh.frag (std140: only mat4 and vec4).
    struct FrameUniforms: BitwiseCopyable {
        var viewProj: Mat4
        var lightViewProj: Mat4
        var currentViewProj: Mat4
        var previousViewProj: Mat4
        var lightDir: Vec4
        var lightColor: Vec4
        var cameraPos: Vec4
        var fogColor: Vec4
        var skyColor: Vec4
        var groundColor: Vec4
        var shadowParams: Vec4
    }

    /// Must match `MaterialData` in mesh.frag (uniform buffer 2).
    struct MaterialUniforms: BitwiseCopyable {
        var baseColor: Vec4
        var params: Vec4
        var uvScale: Vec4
    }

    private struct PipelineKey: Hashable {
        var blending: Bool
        var doubleSided: Bool
        var reversedZ: Bool
    }

    public convenience init(engine: Engine) throws {
        try self.init(device: engine.device, quality: engine.quality)
    }

    public init(device: RenderDevice, quality: RenderQuality) throws {
        self.device = device
        self.quality = quality
        shader = try ShaderSource.load(named: "mesh", bundle: .module)
        var shadow = PipelineDescriptor(
            shader: try ShaderSource.load(named: "mesh_shadow", bundle: .module),
            vertexLayout: MeshVertex.layout, instanceLayout: MeshInstance.layout)
        shadow.target = .depthOnly
        shadow.cullMode = .none  // single-sided planes still cast shadows
        shadow.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
        shadowPipeline = try device.makePipeline(shadow)
        shadowMap = try device.makeTexture(
            TextureDescriptor(width: quality.shadowMapSize, height: quality.shadowMapSize, format: .depth32Float))
        whiteTexture = try device.makeTexture(pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm)

        try registerMesh(.cube(), key: MeshHandle.cube.key)
        try registerMesh(.plane(), key: MeshHandle.plane.key)
        try registerMesh(.sphere(), key: MeshHandle.sphere.key)
        try registerMaterial(Material(), key: MaterialHandle.default.key)
    }

    // MARK: - Assets

    /// Uploads `geometry` and registers it under `key` (replacing an earlier mesh with that key).
    @discardableResult
    public func registerMesh(_ geometry: MeshGeometry, key: String) throws -> MeshHandle {
        let mesh = GPUMesh(
            vertexBuffer: try device.makeBuffer(geometry.vertices, usage: .vertex),
            indexBuffer: try device.makeBuffer(geometry.indices, usage: .index),
            indexCount: geometry.indices.count,
            bounds: geometry.bounds)
        let id = prep.meshes.register(mesh.bounds, key: key)
        if id == meshes.count { meshes.append(mesh) } else { meshes[id] = mesh }
        return MeshHandle(key)
    }

    /// Registers `material` under `key` (replacing an earlier material with that key).
    @discardableResult
    public func registerMaterial(_ material: Material, key: String) throws -> MaterialHandle {
        let entry = (material, try device.makeSampler(material.sampler))
        let id = prep.materials.register(material.blends, key: key)
        if id == materials.count { materials.append(entry) } else { materials[id] = entry }
        return MaterialHandle(key)
    }

    public func mesh(_ handle: MeshHandle) -> GPUMesh? { prep.meshes.contains(handle.key) ? meshes[prep.meshes.id(of: handle.key)!] : nil }
    public func material(_ handle: MaterialHandle) -> Material? {
        prep.materials.contains(handle.key) ? materials[prep.materials.id(of: handle.key)!].material : nil
    }

    // MARK: - Frame

    /// Forgets the previous frame's camera and object transforms (after a camera cut or a
    /// teleport), so the next frame has no motion. Pair it with `engine.resetTemporalHistory()`.
    public func resetMotion() {
        previousViewProj = nil
        prep.motion.reset()
    }

    /// `prepare` and `renderShadows` in one call.
    public func renderOffscreen(world: World, engine: Engine, frame: Frame) {
        prepare(world: world, engine: engine)
        renderShadows(frame: frame)
    }

    /// Gathers the world's renderable entities, culls and batches them, and computes the
    /// frame's uniforms (jittered with `engine.jittered` when a temporal upscaler is active).
    /// Sets `engine.clearColor` and `engine.clearDepth` from the camera. Without a camera,
    /// nothing is drawn this frame.
    public func prepare(world: World, engine: Engine) {
        let start = ContinuousClock.now
        defer {
            let (s, attoseconds) = (ContinuousClock.now - start).components
            stats.prepareTime = Double(s) + Double(attoseconds) * 1e-18
        }
        prep.gather(world: world)
        for key in prep.missingKeys where !reportedMissing.contains(key) {
            reportedMissing.insert(key)
            print("SceneRenderer: no mesh or material registered as '\(key)'; entities using it are skipped")
        }

        guard let (_, camera, cameraWorld) = RenderPrep.findCamera(in: world, preferred: self.camera) else {
            uniforms = nil
            stats.list = RenderListStats()
            return
        }
        reversedZ = camera.reversedZ
        engine.clearColor = camera.clearColor
        engine.clearDepth = camera.reversedZ ? 0 : 1

        let view = Camera.viewMatrix(world: cameraWorld)
        let viewProj = camera.projection(aspect: engine.aspectRatio) * view
        let jittered = engine.jittered(camera.projection(aspect: engine.aspectRatio)) * view
        let eye = Vec3(cameraWorld.c3.x, cameraWorld.c3.y, cameraWorld.c3.z)
        let forward = -Vec3(view.c0.z, view.c1.z, view.c2.z)

        let environment = RenderPrep.findEnvironment(in: world)
        var lightViewProj = Mat4.identity
        var toLight = normalize(Vec3(0.5, 0.75, 0.35)), lightColor = Vec3.zero, intensity: Float = 0
        var culling: ShadowCasterCulling?
        var bias: Float = 0
        if let (light, lightWorld) = RenderPrep.findLight(in: world) {
            toLight = -light.travelDirection(world: lightWorld)
            lightColor = light.color
            intensity = light.intensity
            bias = light.shadowBias
            if light.castsShadows {
                lightViewProj = Self.lightViewProjection(
                    toLight: toLight, center: light.shadowCenter ?? eye + forward * light.shadowExtent,
                    extent: light.shadowExtent, distance: light.shadowDistance, mapSize: shadowMap.width,
                    snap: light.shadowCenter == nil)
                var floor = Float.infinity
                for item in prep.items where item.instance.params.x > 0 {
                    floor = min(floor, item.bounds.center.y - item.bounds.halfExtent.y)
                }
                culling = ShadowCasterCulling(
                    lightFrustum: Frustum(viewProjection: lightViewProj), toLight: toLight,
                    receiverFloor: floor.isFinite ? floor : -.infinity,
                    maxSweep: light.shadowDistance + light.shadowExtent * 2)
            }
        }
        shadowsActive = culling != nil

        list.build(items: prep.items, view: Frustum(viewProjection: jittered), cameraPosition: eye, shadows: culling)
        stats.list = list.stats

        let previous = previousViewProj ?? viewProj
        previousViewProj = viewProj
        uniforms = FrameUniforms(
            viewProj: jittered,
            lightViewProj: lightViewProj,
            currentViewProj: viewProj,
            previousViewProj: previous,
            lightDir: Vec4(toLight, intensity),
            lightColor: Vec4(lightColor, shadowsActive ? 1 : 0),
            cameraPos: Vec4(eye, 0),
            fogColor: Vec4(environment.fogColor, environment.fogDensity),
            skyColor: Vec4(environment.skyColor, environment.ambientIntensity),
            groundColor: Vec4(environment.groundColor, 0),
            shadowParams: Vec4(1 / Float(shadowMap.width), bias, Float(quality.shadowFilterRadius), 0))
    }

    /// An orthographic light projection covering a `2 extent` square around `center`, from
    /// `distance` toward the light to `2 extent` beyond the center. With `snap`, the square
    /// moves in whole shadow-map texels so a following shadow map doesn't shimmer.
    nonisolated static func lightViewProjection(toLight: Vec3, center: Vec3, extent: Float, distance: Float, mapSize: Int, snap: Bool) -> Mat4 {
        let up = abs(toLight.y) > 0.99 ? Vec3(0, 0, 1) : Vec3(0, 1, 0)
        // Oriented along the light, positioned at the origin so snapping works in a fixed frame.
        let view = Mat4.lookAt(eye: toLight, target: .zero, up: up)
        var c = view * Vec4(center, 1)
        if snap {
            let texel = 2 * extent / Float(mapSize)
            c.x = (c.x / texel).rounded() * texel
            c.y = (c.y / texel).rounded() * texel
            c.z = (c.z / texel).rounded() * texel
        }
        // View space looks down -z: depth along the light is -z.
        let projection = Mat4.orthographic(
            left: c.x - extent, right: c.x + extent, bottom: c.y - extent, top: c.y + extent,
            near: -c.z - distance, far: -c.z + extent * 2)
        return projection * view
    }

    /// Uploads this frame's instances once and renders the shadow map. Call after `prepare`,
    /// from `Game.renderOffscreen`.
    public func renderShadows(frame: Frame) {
        guard let uniforms else { return }
        uploaded = list.instances.isEmpty ? nil : frame.upload(list.instances)
        guard shadowsActive || !shadowMapCleared else { return }
        shadowMapCleared = true
        frame.depthPass(into: shadowMap) { pass in
            pass.setPipeline(shadowPipeline)
            pass.setUniforms(uniforms)
            guard shadowsActive, let uploaded else { return }
            for batch in list.shadow {
                draw(pass, batch, instances: uploaded)
            }
        }
    }

    /// Draws the prepared frame into the screen pass: opaque batches, then transparent ones
    /// back to front.
    public func draw(_ pass: RenderPass) {
        guard let uniforms, let uploaded else { return }
        pass.setUniforms(uniforms)
        pass.setTexture(shadowMap)
        var current: (pipeline: PipelineKey, material: Int)?
        for (batches, blending) in [(list.opaque, false), (list.transparent, true)] {
            for batch in batches {
                let (material, sampler) = materials[batch.material]
                let key = PipelineKey(blending: blending, doubleSided: material.doubleSided, reversedZ: reversedZ)
                if current?.pipeline != key {
                    guard let pipeline = pipeline(key) else { continue }
                    pass.setPipeline(pipeline)
                }
                if current?.material != batch.material {
                    pass.setUniformData(MaterialUniforms(
                        baseColor: material.baseColor,
                        params: Vec4(material.checker ? 1 : 0, material.emissive, material.specular, material.shininess),
                        uvScale: Vec4(material.uvScale.x, material.uvScale.y, 0, 0)), index: 2, stage: .fragment)
                    pass.setTexture(material.texture ?? whiteTexture, index: 1)
                    pass.setSampler(sampler, index: 1)
                }
                current = (key, batch.material)
                draw(pass, batch, instances: uploaded)
            }
        }
    }

    private func draw(_ pass: RenderPass, _ batch: RenderBatch, instances: TransientBuffer) {
        let mesh = meshes[batch.mesh]
        pass.setVertexBuffer(mesh.vertexBuffer)
        pass.setIndexBuffer(mesh.indexBuffer, type: .uint32)
        pass.setVertexBuffer(instances.buffer, offset: instances.offset + batch.first * MemoryLayout<MeshInstance>.stride, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: batch.count)
    }

    private func pipeline(_ key: PipelineKey) -> RenderPipeline? {
        if let pipeline = pipelines[key] { return pipeline }
        var descriptor = PipelineDescriptor(shader: shader, vertexLayout: MeshVertex.layout, instanceLayout: MeshInstance.layout)
        descriptor.cullMode = key.doubleSided ? .none : .back
        descriptor.alphaBlending = key.blending
        descriptor.depthWrite = !key.blending
        descriptor.depthCompare = key.reversedZ ? .greater : .less
        // Blended surfaces keep the motion of what's behind them.
        descriptor.writesMotionVectors = !key.blending
        do {
            let pipeline = try device.makePipeline(descriptor)
            pipelines[key] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: pipeline creation failed: \(error)")
            return nil
        }
    }
}
