import Foundation

/// A mesh uploaded to the GPU (vertex buffer 0 in `MeshVertex` layout, 32-bit indices).
public struct GPUMesh {
    public var vertexBuffer: GPUBuffer
    public var indexBuffer: GPUBuffer
    public var indexCount: Int
    /// Local-space bounds of the vertices, used for culling.
    public var bounds: Bounds
}

/// A camera to render a world from with `SceneRenderer.renderView`: an explicit view and
/// projection (an editor camera), or a `Camera` entity's (`init(camera:in:aspect:)`).
public struct SceneView: Sendable {
    /// World to camera space.
    public var view: Mat4
    public var projection: Mat4
    /// The projection maps near to depth 1 (pipelines then compare with `.greater`).
    public var reversedZ: Bool
    /// Linear RGBA the target is cleared to.
    public var clearColor: Vec4

    public init(view: Mat4, projection: Mat4, reversedZ: Bool = false, clearColor: Vec4 = Vec4(0, 0, 0, 1)) {
        self.view = view
        self.projection = projection
        self.reversedZ = reversedZ
        self.clearColor = clearColor
    }

    /// The view of `camera`'s `Camera` component from its world transform, at `aspect`
    /// (e.g. `target.aspectRatio`); nil if it has no `Camera`.
    @MainActor public init?(camera entity: Entity, in world: World, aspect: Float) {
        guard let camera = world.get(Camera.self, for: entity) else { return nil }
        let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
        self.init(view: Camera.viewMatrix(world: matrix), projection: camera.projection(aspect: aspect),
                  reversedZ: camera.reversedZ, clearColor: camera.clearColor)
    }

    public var viewProjection: Mat4 { projection * view }
    /// The camera's position in the world.
    public var eye: Vec3 {
        let p = view.inverse.c3
        return Vec3(p.x, p.y, p.z)
    }
    /// The direction the camera looks in (its -z axis).
    public var forward: Vec3 { -Vec3(view.c0.z, view.c1.z, view.c2.z) }
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
/// To render into `RenderTarget`s instead, from any number of cameras per frame (an editor
/// view next to the game camera's), call `beginViews` once in `Game.renderOffscreen`, then
/// `renderView` per view. The views share the frame's gathered entities and its shadow map,
/// which is rendered once, for every caster in the light's frustum, centered for the
/// `shadowFocus` camera (the game camera by default): give the light a fixed `shadowCenter`
/// and a larger `shadowExtent` when views look at different places. Views have no motion
/// vectors or jitter. Use one of the two paths per frame (they share the shadow map).
///
/// `debugDraw` (the engine's by default with `init(engine:)`) is drawn over the scene in the
/// screen pass; `renderView` takes its own, so each view can show different gizmos.
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
    /// Debug shapes drawn after the scene by `draw` (nil draws none).
    public var debugDraw: DebugDraw?
    /// The CPU side: registries of mesh bounds and material flags, motion history, gathered items.
    public private(set) var prep = RenderPrep()
    public private(set) var list = RenderList()

    private var meshes: [GPUMesh] = []
    /// The CPU copy of each registered mesh, for picking (`geometry(_:)`).
    private var geometries: [MeshGeometry] = []
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

    /// Resolves handles that name project assets (`MeshHandle(AssetReference)`, keys
    /// `asset:<id>[#<sub-asset>]`): the first frame an entity uses one, its mesh or material
    /// (and the material's texture) is taken from the database and uploaded, then registered
    /// under that key like any other. Assets the database imports again are re-uploaded on the
    /// next frame. Built-in and code-registered keys are unaffected. Nil (the default) leaves
    /// asset keys unresolved (reported as missing, entities skipped).
    public var assets: AssetDatabase? {
        didSet { failedAssetKeys.removeAll(); seenAssetRevision = -1 }
    }
    /// Turns an imported texture into a GPU texture (RGBA8 in `texture.format`, with a mip chain
    /// when `generatesMipmaps`). Replace it to upload other formats.
    public var textureUploader: (TextureAsset, RenderDevice) throws -> GPUTexture = { texture, device in
        try device.makeTexture(pixels: texture.image.pixels, width: texture.image.width, height: texture.image.height,
                               format: texture.format, generateMipmaps: texture.generatesMipmaps)
    }
    /// Asset keys registered from `assets`, with the asset revision they were uploaded at.
    var assetKeys: [String: Int] = [:]
    /// Uploaded asset textures by reference text, with their revision.
    var assetTextures: [String: (texture: GPUTexture, revision: Int)] = [:]
    /// Asset keys that didn't resolve at `seenAssetRevision` (retried when the database changes).
    var failedAssetKeys: Set<String> = []
    var seenAssetRevision = -1
    /// What `draw` draws `debugDraw` for (from the last `prepare`).
    private var debugView: DebugView?
    private var debugRenderer: DebugDrawRenderer?
    /// Shared by this frame's `renderView` calls (from `beginViews`).
    private var views: ViewsFrame?
    /// Shadow casters in the light's frustum (`beginViews`), and each view's batches.
    private var shadowList = RenderList()
    private var viewList = RenderList()

    /// The light as `prepare` / `beginViews` set it up.
    private struct LightSetup {
        var toLight: Vec3
        var color: Vec3
        var intensity: Float
        var bias: Float
        var viewProj: Mat4
        var culling: ShadowCasterCulling?
    }

    private struct ViewsFrame {
        var light: LightSetup
        var environment: SceneEnvironment
    }

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

    /// Also draws `engine.debugDraw` in the screen pass.
    public convenience init(engine: Engine) throws {
        try self.init(device: engine.device, quality: engine.quality)
        debugDraw = engine.debugDraw
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
        if id == meshes.count {
            meshes.append(mesh)
            geometries.append(geometry)
        } else {
            meshes[id] = mesh
            geometries[id] = geometry
        }
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

    /// The GPU mesh registered under `handle`'s key (an asset handle is resolved and uploaded first).
    public func mesh(_ handle: MeshHandle) -> GPUMesh? {
        resolveAsset(handle.key, kind: .mesh)
        return prep.meshes.contains(handle.key) ? meshes[prep.meshes.id(of: handle.key)!] : nil
    }
    /// The vertices and indices registered under `handle`'s key (kept on the CPU for picking).
    public func geometry(_ handle: MeshHandle) -> MeshGeometry? {
        resolveAsset(handle.key, kind: .mesh)
        return prep.meshes.contains(handle.key) ? geometries[prep.meshes.id(of: handle.key)!] : nil
    }
    public func material(_ handle: MaterialHandle) -> Material? {
        resolveAsset(handle.key, kind: .material)
        return prep.materials.contains(handle.key) ? materials[prep.materials.id(of: handle.key)!].material : nil
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
        defer { stats.prepareTime = Self.seconds(since: start) }
        gather(world)

        guard let (_, camera, cameraWorld) = RenderPrep.findCamera(in: world, preferred: self.camera) else {
            uniforms = nil
            debugView = nil
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
        let light = lightSetup(world: world, eye: eye, forward: forward)
        shadowsActive = light.culling != nil

        list.build(items: prep.items, view: Frustum(viewProjection: jittered), cameraPosition: eye, shadows: light.culling)
        stats.list = list.stats

        let previous = previousViewProj ?? viewProj
        previousViewProj = viewProj
        uniforms = makeUniforms(viewProj: jittered, current: viewProj, previous: previous, eye: eye, light: light,
                                environment: environment)
        let size = engine.renderSize
        debugView = DebugView(viewProjection: jittered, cameraPosition: eye, viewportSize: size, reversedZ: camera.reversedZ,
                              projectionScale: camera.projection(aspect: engine.aspectRatio).c1.y)
    }

    func gather(_ world: World) {
        syncAssets()
        prep.gather(world: world)
        // Upload assets entities started using, then gather again so they draw this frame
        // (only on frames where something new resolved).
        if resolveMissingAssets() { prep.gather(world: world) }
        for key in prep.missingKeys where !reportedMissing.contains(key) && !prep.meshes.contains(key) && !prep.materials.contains(key)
            && (assets == nil || AssetReference(key) == nil || failedAssetKeys.contains(key)) {
            reportedMissing.insert(key)
            print("SceneRenderer: no mesh or material registered as '\(key)'; entities using it are skipped")
        }
    }

    /// The first directional light's parameters and, when it casts shadows, its shadow
    /// projection (around `eye + forward * extent`, unless it has a fixed center) and culling.
    private func lightSetup(world: World, eye: Vec3, forward: Vec3) -> LightSetup {
        var setup = LightSetup(toLight: normalize(Vec3(0.5, 0.75, 0.35)), color: .zero, intensity: 0, bias: 0,
                               viewProj: .identity, culling: nil)
        guard let (light, lightWorld) = RenderPrep.findLight(in: world) else { return setup }
        setup.toLight = -light.travelDirection(world: lightWorld)
        setup.color = light.color
        setup.intensity = light.intensity
        setup.bias = light.shadowBias
        guard light.castsShadows else { return setup }
        setup.viewProj = Self.lightViewProjection(
            toLight: setup.toLight, center: light.shadowCenter ?? eye + forward * light.shadowExtent,
            extent: light.shadowExtent, distance: light.shadowDistance, mapSize: shadowMap.width,
            snap: light.shadowCenter == nil)
        var floor = Float.infinity
        for item in prep.items where item.instance.params.x > 0 {
            floor = min(floor, item.bounds.center.y - item.bounds.halfExtent.y)
        }
        setup.culling = ShadowCasterCulling(
            lightFrustum: Frustum(viewProjection: setup.viewProj), toLight: setup.toLight,
            receiverFloor: floor.isFinite ? floor : -.infinity,
            maxSweep: light.shadowDistance + light.shadowExtent * 2)
        return setup
    }

    private func makeUniforms(viewProj: Mat4, current: Mat4, previous: Mat4, eye: Vec3, light: LightSetup,
                              environment: SceneEnvironment) -> FrameUniforms {
        FrameUniforms(
            viewProj: viewProj,
            lightViewProj: light.viewProj,
            currentViewProj: current,
            previousViewProj: previous,
            lightDir: Vec4(light.toLight, light.intensity),
            lightColor: Vec4(light.color, light.culling != nil ? 1 : 0),
            cameraPos: Vec4(eye, 0),
            fogColor: Vec4(environment.fogColor, environment.fogDensity),
            skyColor: Vec4(environment.skyColor, environment.ambientIntensity),
            groundColor: Vec4(environment.groundColor, 0),
            shadowParams: Vec4(1 / Float(shadowMap.width), light.bias, Float(quality.shadowFilterRadius), 0))
    }

    private static func seconds(since start: ContinuousClock.Instant) -> Double {
        let (s, attoseconds) = (ContinuousClock.now - start).components
        return Double(s) + Double(attoseconds) * 1e-18
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
    /// back to front, then `debugDraw`.
    public func draw(_ pass: RenderPass) {
        guard let uniforms else { return }
        if let uploaded { draw(pass, list: list, uniforms: uniforms, instances: uploaded, reversedZ: reversedZ) }
        if let debugDraw, let debugView { drawDebug(debugDraw, in: pass, view: debugView) }
    }

    // MARK: - Views

    /// Starts this frame's `renderView` calls: gathers the world's entities, sets up the light
    /// and renders the shared shadow map (all casters in the light's frustum, centered for
    /// `shadowFocus`, by default the camera `prepare` would use). Call once per frame in
    /// `Game.renderOffscreen`, after the world's transforms are current.
    public func beginViews(world: World, frame: Frame, shadowFocus: SceneView? = nil) {
        let start = ContinuousClock.now
        defer { stats.prepareTime = Self.seconds(since: start) }
        gather(world)
        let focus = shadowFocus ?? RenderPrep.findCamera(in: world, preferred: camera).map {
            SceneView(view: Camera.viewMatrix(world: $0.world), projection: .identity)
        }
        let eye = focus?.eye ?? .zero, forward = focus?.forward ?? Vec3(0, 0, -1)
        let light = lightSetup(world: world, eye: eye, forward: forward)
        views = ViewsFrame(light: light, environment: RenderPrep.findEnvironment(in: world))

        guard let culling = light.culling else {
            guard !shadowMapCleared else { return }
            shadowMapCleared = true
            frame.depthPass(into: shadowMap) { _ in }
            return
        }
        // Every caster the light sees: the views may look anywhere.
        shadowList.build(items: prep.items, view: culling.lightFrustum, cameraPosition: eye, shadows: culling, cameraBatches: false)
        shadowMapCleared = true
        let instances = shadowList.instances.isEmpty ? nil : frame.upload(shadowList.instances)
        let uniforms = makeUniforms(viewProj: light.viewProj, current: light.viewProj, previous: light.viewProj, eye: eye,
                                    light: light, environment: views!.environment)
        frame.depthPass(into: shadowMap) { pass in
            pass.setPipeline(shadowPipeline)
            pass.setUniforms(uniforms)
            guard let instances else { return }
            for batch in shadowList.shadow {
                draw(pass, batch, instances: instances)
            }
        }
    }

    /// Renders the world as gathered by `beginViews` from `view` into `target` (cleared to
    /// `view.clearColor`): culled and batched for this view, opaque then transparent, then
    /// `debugDraw` (if any), then `overlay` for extra drawing into the same pass. `stats.list`
    /// describes the last view rendered.
    public func renderView(_ view: SceneView, into target: RenderTarget, frame: Frame, debugDraw: DebugDraw? = nil,
                           overlay: ((RenderPass) -> Void)? = nil) {
        guard let views else { preconditionFailure("SceneRenderer.renderView called before beginViews") }
        let viewProj = view.viewProjection
        let eye = view.eye
        viewList.build(items: prep.items, view: Frustum(viewProjection: viewProj), cameraPosition: eye, shadows: nil)
        stats.list = viewList.stats
        let instances = viewList.instances.isEmpty ? nil : frame.upload(viewList.instances)
        let uniforms = makeUniforms(viewProj: viewProj, current: viewProj, previous: viewProj, eye: eye, light: views.light,
                                    environment: views.environment)
        frame.renderPass(into: target, clearColor: view.clearColor, clearDepth: view.reversedZ ? 0 : 1) { pass in
            if let instances {
                draw(pass, list: viewList, uniforms: uniforms, instances: instances, reversedZ: view.reversedZ)
            }
            if let debugDraw {
                drawDebug(debugDraw, in: pass, view: DebugView(
                    view: view.view, projection: view.projection, viewportSize: (target.width, target.height),
                    reversedZ: view.reversedZ))
            }
            overlay?(pass)
        }
    }

    private func drawDebug(_ debug: DebugDraw, in pass: RenderPass, view: DebugView) {
        guard !debug.isEmpty else { return }
        if debugRenderer == nil {
            do {
                debugRenderer = try DebugDrawRenderer(device: device)
            } catch {
                print("SceneRenderer: debug drawing unavailable: \(error)")
                debugDraw = nil
                return
            }
        }
        debugRenderer?.draw(debug, in: pass, view: view)
    }

    /// Opaque batches, then transparent ones back to front.
    private func draw(_ pass: RenderPass, list: RenderList, uniforms: FrameUniforms, instances uploaded: TransientBuffer,
                      reversedZ: Bool) {
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
