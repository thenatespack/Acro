import Foundation

/// A mesh uploaded to the GPU (vertex buffer 0 in `MeshVertex` layout, or `SkinnedMeshVertex`
/// for a skinned mesh; 32-bit indices).
public struct GPUMesh {
    public var vertexBuffer: GPUBuffer
    public var indexBuffer: GPUBuffer
    public var indexCount: Int
    /// Local-space bounds of the vertices, used for culling (the bind pose for a skinned mesh).
    public var bounds: Bounds
    /// The vertices are `SkinnedMeshVertex`es.
    public var isSkinned = false
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
    /// Point and spot lights of the last view prepared (`LightClusters`).
    public var lights = LightClusters.Stats()
    /// Cascades, shadowed point / spot lights and atlas tiles of the last frame.
    public var shadows = ShadowStats()
    /// CPU seconds spent gathering, culling and batching (`prepare`).
    public var prepareTime: Double = 0
}

/// Draws a `World`'s entities: a forward renderer with one shadow-casting directional light
/// (cascaded shadow maps), clustered point and spot lights (a few with shadows), hemisphere ambient
/// or a sky with image-based lighting (`SceneEnvironment.sky`), exponential fog, instancing,
/// frustum and shadow-caster culling, a back-to-front sorted transparent pass and motion vectors
/// for temporal upscalers.
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
/// `renderView` per view. The views share the frame's gathered entities and its shadow atlas,
/// which is rendered once, for the `shadowFocus` camera: cascades fitted to it when it has a
/// perspective projection, else a single square of `shadowExtent` in front of it (the game
/// camera by default). Give the light a fixed `shadowCenter` and a larger `shadowExtent` when
/// views look at different places. Views have no motion vectors or jitter. Use one of the two
/// paths per frame (they share the shadow atlas).
///
/// `debugDraw` (the engine's by default with `init(engine:)`) is drawn over the scene in the
/// screen pass; `renderView` takes its own, so each view can show different gizmos.
///
/// What gets drawn comes from components: the active `Camera`, the first `DirectionalLight`,
/// every `PointLight` and `SpotLight` (binned per view by `LightClusters`), the first
/// `SceneEnvironment` and every entity with a `MeshRenderer` and a
/// `GlobalTransform`. Meshes and materials are registered under string keys; the built-in
/// meshes `MeshHandle.cube`, `.plane`, `.sphere` and `MaterialHandle.default` (Blinn-Phong, the pre-PBR look) exist from the start.
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
    /// Textures registered with `registerTexture` (environment maps).
    private var textures: [String: GPUTexture] = [:]
    /// The sky and image-based lighting of `SceneEnvironment`.
    private let environmentLighting: EnvironmentLighting
    /// The view and (jittered) projection `draw` draws the sky for.
    private var skyView: (view: Mat4, projection: Mat4)?
    private let whiteTexture: GPUTexture
    private let shader: ShaderSource
    /// `shader` with mesh_mask.frag (alpha-tested), loaded with the first masked material.
    private var maskShader: ShaderSource?
    /// The skinning variants of `shader` and `maskShader` (mesh_skinned.vert), loaded with the first skinned mesh.
    private var skinnedShaders: [Bool: ShaderSource] = [:]
    private let shadowPipeline: RenderPipeline
    /// The shadow pipeline for alpha-tested casters (mesh_shadow_mask), created on first use.
    private var shadowMaskPipeline: RenderPipeline?
    /// Shadow pipelines for skinned casters, plain and alpha-tested, created on first use.
    private var skinnedShadowPipelines: [Bool: RenderPipeline] = [:]
    /// Scratch for the skinning uniform block (`SkinPose.uniformBlock`).
    private var skinBlock: [Vec4] = []
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    /// The shadow atlas: every cascade, spot-light map and point-light face of the frame in
    /// one depth texture (`ShadowAtlasLayout`). Recreated when the layout's size changes.
    public private(set) var shadowMap: GPUTexture
    private var shadowMapCleared = false
    /// Casters per atlas tile, for the frame's `ShadowSetup` (from `prepare` / `beginViews`).
    private var shadowCasters = ShadowCasterBatches()
    /// Tints each shadow cascade (red, green, blue, yellow) to show where they fall. Also on
    /// with `ENGINE_SHOW_CASCADES=1`.
    public var showsShadowCascades = ProcessInfo.processInfo.environment["ENGINE_SHOW_CASCADES"] == "1"

    private var uniforms: FrameUniforms?
    private var reversedZ = false
    private var shadowsActive = false
    /// The shadows `prepare` set up for `renderShadows`.
    private var shadowSetup: ShadowSetup?
    var uploaded: TransientBuffer?
    private var previousViewProj: Mat4?
    private var reportedMissing: Set<String> = []

    /// Resolves handles that name project assets (`MeshHandle(AssetReference)`, keys
    /// `asset:<id>[#<sub-asset>]`): the first frame an entity uses one, its mesh or material
    /// (and the material's textures) is taken from the database and uploaded, then registered
    /// under that key like any other. Assets the database imports again are re-uploaded on the
    /// next frame. Built-in and code-registered keys are unaffected. Nil (the default) leaves
    /// asset keys unresolved (reported as missing, entities skipped).
    public var assets: AssetDatabase? {
        didSet { failedAssetKeys.removeAll(); seenAssetRevision = -1 }
    }
    /// Turns an imported texture into a GPU texture (RGBA8 in `texture.format`, or `.rgba16Float`
    /// for HDR images, with a mip chain when `generatesMipmaps`; compressed ones as they are, or
    /// decoded to RGBA8 on a GPU without their format). Replace it to upload other formats.
    /// With the default, mip chains (and HDR images' half-float conversion) are built on job
    /// workers first and only the GPU texture is made on the render thread; a replacement runs
    /// entirely on the render thread.
    public var textureUploader: (TextureAsset, RenderDevice) throws -> GPUTexture = { texture, device in
        switch texture.pixels {
        case .rgba8(let image):
            try device.makeTexture(image: image, srgb: texture.isSRGB, generateMipmaps: texture.generatesMipmaps)
        case .rgbaFloat(let image):
            try device.makeTexture(image: image, generateMipmaps: texture.generatesMipmaps)
        case .compressed(let format, let levels):
            try device.makeTexture(compressedLevels: levels, format: format)
        }
    } {
        didSet { usesDefaultTextureUploader = false }
    }
    /// `textureUploader` hasn't been replaced, so texture levels can be built on job workers.
    var usesDefaultTextureUploader = true
    /// Asset textures whose levels are being built on a job worker, by reference text.
    var preparingTextures: [String: PreparedTextureLevels] = [:]
    /// How many bytes of asset meshes and textures `gather` uploads per frame before it leaves the
    /// rest for the next frames (so a big import doesn't hitch). At least one upload is made per
    /// frame. Ignored when `blocksOnAssetLoading` is set.
    public var assetUploadBudget = 32 << 20
    /// Wait for background imports and upload everything at once, instead of drawing
    /// placeholders and spreading uploads over frames. On by default when `ENGINE_SCREENSHOT` is
    /// set, so screenshots show fully loaded assets (and match across backends).
    public var blocksOnAssetLoading = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil
    /// Bytes uploaded since the last `syncAssets` (this frame).
    var assetUploadedBytes = 0
    /// Something is still loading or was deferred by the budget: `syncAssets` runs again next frame.
    var assetsNeedRetry = false
    /// Texture references already reported as missing.
    var reportedTextures: Set<String> = []
    /// Replaces the buffers of a mesh whose asset was deleted.
    var vanishedMesh: GPUMesh?
    /// The mesh built for each `LineRenderer` entity and the spec it was built from.
    var lineMeshes: [Entity: LineRenderer.Spec] = [:]
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
    /// Each view's batches (`renderView`).
    private var viewList = RenderList()
    /// This frame's point and spot lights (`gather`), binned for the `prepare` camera and for
    /// each `renderView`, and the uniform data they're uploaded from.
    private var punctualLights: [PunctualLight] = []
    public private(set) var clusters = LightClusters()
    private var viewClusters = LightClusters()
    private var lightData = LightClusters.GPUData()
    /// Bound as the light buffers when there are no point or spot lights (16 KiB of zeros).
    private let emptyLightBuffer: GPUBuffer
    /// GPU particles of the world's `ParticleEmitter`s (see `SceneRenderer+Particles.swift`),
    /// created with the first emitter; nil until then.
    public internal(set) var particles: ParticleSystem?
    /// World-space text of the world's `TextMesh`es (see `SceneRenderer+Text.swift`), created with the first one.
    var worldText: WorldTextRenderer?
    /// Decals of the world's `Decal` components (see `SceneRenderer+Decals.swift`), created with
    /// the first one; nil until then.
    var decals: DecalRenderer?
    /// The `prepare` camera, for the particles' depth prepass (`renderParticleDepth`).
    var particleView: (viewProjection: Mat4, projection: Mat4, eye: Vec3, size: (width: Int, height: Int), reversedZ: Bool)?
    /// This frame's depth prepass of the `prepare` camera, when particles need it.
    var particleDepth: ParticleSceneDepth?
    /// Depth prepass textures: the `prepare` camera's, and `renderView`'s by size.
    var particleDepthTexture: GPUTexture?
    var viewParticleDepthTextures: [[Int]: GPUTexture] = [:]
    /// The camera depth prepass's pipelines (`DepthVariant.prepass`), created on first use.
    private var prepassPipelines: [PrepassKey: RenderPipeline] = [:]

    /// The light as `prepare` / `beginViews` set it up, with the frame's shadows.
    private struct LightSetup {
        var toLight: Vec3
        var color: Vec3
        var intensity: Float
        var bias: Float
        var shadows: ShadowSetup?
        /// The directional light casts shadows.
        var sunShadows: Bool { (shadows?.stats.cascades ?? 0) > 0 }
    }

    private struct ViewsFrame {
        var light: LightSetup
        var environment: SceneEnvironment
    }

    /// Must match `Frame` in mesh_surface.glsl (std140: only mat4 and vec4); mesh.vert and the
    /// shadow shaders declare a prefix of it.
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
        /// Clustered lights: view depth row, tile / slice scale, grid size and whether any lights exist.
        var viewDepth = Vec4.zero
        var clusterScale = Vec4.zero
        var clusterGrid = Vec4.zero
        /// Shadow cascades and point / spot light shadows (see ShadowMaps.swift / shadows.glsl).
        var shadows = ShadowUniforms()
        /// Image-based lighting: x 1 when on, y intensity, z, w cos / sin of the environment's rotation.
        var environment = Vec4.zero

        /// Points the shader's cluster lookup at `clusters`, binned for `view` and a target of `size` pixels.
        mutating func setClusters(_ clusters: LightClusters, view: Mat4, size: (width: Int, height: Int)) {
            guard !clusters.isEmpty else { return }
            viewDepth = -Vec4(view.c0.z, view.c1.z, view.c2.z, view.c3.z)
            clusterScale = Vec4(Float(LightClusters.tilesX) / Float(max(size.width, 1)),
                                Float(LightClusters.tilesY) / Float(max(size.height, 1)),
                                clusters.sliceScale, -log2f(clusters.near) * clusters.sliceScale)
            clusterGrid = Vec4(Float(LightClusters.tilesX), Float(LightClusters.tilesY), Float(LightClusters.slices), 1)
        }
    }

    /// Must match `MaterialData` in mesh_surface.glsl (uniform buffer 2).
    struct MaterialUniforms: BitwiseCopyable {
        var baseColor: Vec4
        /// x: checker, y: unlit, z: specular, w: shininess
        var params: Vec4
        var uvRow0: Vec4
        var uvRow1: Vec4
        /// x: metallic, y: roughness, z: normal scale, w: occlusion strength
        var surface: Vec4
        /// rgb: emissive color x strength, w: 1 for PBR
        var emissive: Vec4
        /// x: alpha cutoff, y: has a normal map, z: its layout (0 XYZ in RGB; two channels, Z
        /// rebuilt: 1 XY in RG (BC5), 2 XY in RA (two-channel ASTC))
        var flags: Vec4

        @MainActor init(_ material: Material) {
            baseColor = material.baseColor
            params = Vec4(material.checker ? 1 : 0, material.emissive, material.specular, material.shininess)
            (uvRow0, uvRow1) = material.uvTransformRows
            surface = Vec4(material.metallic, material.roughness, material.normalScale, material.occlusionStrength)
            emissive = Vec4(material.emissiveColor * material.emissiveStrength, material.shading == .pbr ? 1 : 0)
            let normalLayout: Float = switch material.normalTexture?.format {
            case .bc5Unorm: 1
            case .astc4x4RG: 2
            default: 0
            }
            flags = Vec4(material.alphaCutoff, material.normalTexture != nil ? 1 : 0, normalLayout, 0)
        }
    }

    struct PipelineKey: Hashable {
        var blending: Bool
        var doubleSided: Bool
        var reversedZ: Bool
        /// The alpha-tested shader variant (mesh_mask.frag).
        var alphaTested: Bool = false
        /// The skinning vertex shader (mesh_skinned.vert) and `SkinnedMeshVertex` layout.
        var skinned: Bool = false
    }

    /// The pipeline variant a batch of `material` draws with, in the transparent pass when `blending`.
    static func pipelineKey(for material: Material, blending: Bool, reversedZ: Bool) -> PipelineKey {
        PipelineKey(blending: blending, doubleSided: material.doubleSided, reversedZ: reversedZ, alphaTested: material.alphaTested)
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
        let atlas = ShadowAtlasLayout(tileSize: quality.shadowMapSize, cascades: quality.shadowCascades, localShadows: false)
        shadowMap = try device.makeTexture(TextureDescriptor(width: atlas.width, height: atlas.height, format: .depth32Float))
        whiteTexture = try device.makeTexture(pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm)
        emptyLightBuffer = try device.makeBuffer([Vec4](repeating: .zero, count: LightClusters.GPUData.entries), usage: .uniform)
        environmentLighting = try EnvironmentLighting(device: device, placeholder: whiteTexture)

        try registerMesh(.cube(), key: MeshHandle.cube.key)
        try registerMesh(.plane(), key: MeshHandle.plane.key)
        try registerMesh(.sphere(), key: MeshHandle.sphere.key)
        for handle in [MeshHandle.cylinder, .capsule, .cone, .torus] {
            try registerMesh(MeshGeometry.builtin(handle)!, key: handle.key)
        }
        // Blinn-Phong, so scenes made before PBR keep their look.
        try registerMaterial(Material(shading: .blinnPhong), key: MaterialHandle.default.key)
    }

    // MARK: - Assets

    /// Uploads `geometry` and registers it under `key` (replacing an earlier mesh with that key).
    /// Tangents are generated first unless every vertex has one (`MeshGeometry.hasTangents`).
    /// A skinned geometry (`skin` set, one influence per vertex, joints below
    /// `SkinPose.maxJoints`) is drawn posed by its entity's `Skin`.
    @discardableResult
    public func registerMesh(_ geometry: MeshGeometry, key: String) throws -> MeshHandle {
        let geometry = geometry.withTangents()
        var skinInfo: SkinnedMeshInfo?
        let vertexBuffer: GPUBuffer
        if let skin = geometry.skin {
            guard skin.count == geometry.vertices.count else {
                throw GraphicsError("Mesh '\(key)' has \(skin.count) skin influences for \(geometry.vertices.count) vertices")
            }
            let info = SkinnedMeshInfo(jointBounds: geometry.jointBounds)
            guard info.jointCount <= SkinPose.maxJoints else {
                throw GraphicsError("Mesh '\(key)' uses \(info.jointCount) joints; at most \(SkinPose.maxJoints) are supported")
            }
            skinInfo = info
            vertexBuffer = try device.makeBuffer(zip(geometry.vertices, skin).map { SkinnedMeshVertex($0, skin: $1) }, usage: .vertex)
        } else {
            vertexBuffer = try device.makeBuffer(geometry.vertices, usage: .vertex)
        }
        let mesh = GPUMesh(
            vertexBuffer: vertexBuffer,
            indexBuffer: try device.makeBuffer(geometry.indices, usage: .index),
            indexCount: geometry.indices.count,
            bounds: geometry.bounds,
            isSkinned: skinInfo != nil)
        let id = prep.meshes.register(mesh.bounds, key: key)
        prep.skinnedMeshes[id] = skinInfo
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
        let id = prep.materials.register(MaterialTraits(blends: material.blends, alphaTested: material.alphaTested), key: key)
        if id == materials.count { materials.append(entry) } else { materials[id] = entry }
        return MaterialHandle(key)
    }

    /// Registers `texture` under `key` (replacing an earlier texture with that key), for
    /// `TextureHandle`s such as `SceneEnvironment.environmentMap`.
    @discardableResult
    public func registerTexture(_ texture: GPUTexture, key: String) -> TextureHandle {
        textures[key] = texture
        return TextureHandle(key)
    }

    /// The texture registered under `handle`'s key, or the project texture asset it names
    /// (uploaded on first use); nil if neither exists (reported once) or it is still loading.
    public func texture(_ handle: TextureHandle) -> GPUTexture? {
        if let texture = textures[handle.key] { return texture }
        if assets != nil, let reference = AssetReference(handle.key) {
            return try? assetTexture(reference, ignoringBudget: false)
        }
        if !reportedTextures.contains(handle.key) {
            reportedTextures.insert(handle.key)
            print("SceneRenderer: no texture registered as '\(handle.key)'")
        }
        return nil
    }

    /// Stops drawing `key`'s mesh and releases its GPU buffers (the id stays allocated).
    func unregisterMesh(key: String) {
        guard let id = prep.meshes.id(of: key) else { return }
        prep.meshes.remove(key)
        prep.skinnedMeshes[id] = nil
        if vanishedMesh == nil {
            vanishedMesh = try? GPUMesh(vertexBuffer: device.makeBuffer([MeshVertex(position: .zero, normal: .zero)], usage: .vertex),
                                        indexBuffer: device.makeBuffer([UInt32(0)], usage: .index), indexCount: 0, bounds: Bounds(center: .zero, halfExtent: .zero))
        }
        if let vanishedMesh { meshes[id] = vanishedMesh }
        geometries[id] = MeshGeometry(vertices: [], indices: [])
    }

    /// The GPU mesh registered under `handle`'s key (an asset handle is resolved and uploaded first).
    public func mesh(_ handle: MeshHandle) -> GPUMesh? {
        resolveAsset(handle.key, kind: .mesh, ignoringBudget: true)
        return prep.meshes.contains(handle.key) ? meshes[prep.meshes.id(of: handle.key)!] : nil
    }
    /// The vertices and indices registered under `handle`'s key (kept on the CPU for picking).
    public func geometry(_ handle: MeshHandle) -> MeshGeometry? {
        resolveAsset(handle.key, kind: .mesh, ignoringBudget: true)
        return prep.meshes.contains(handle.key) ? geometries[prep.meshes.id(of: handle.key)!] : nil
    }
    public func material(_ handle: MaterialHandle) -> Material? {
        resolveAsset(handle.key, kind: .material, ignoringBudget: true)
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
    /// Sets `engine.clearColor` and `engine.clearDepth` from the camera, and
    /// `engine.postProcess` from the world's `PostProcess` component (nil without one). Without
    /// a camera, nothing is drawn this frame.
    public func prepare(world: World, engine: Engine) {
        let start = ContinuousClock.now
        Profiler.begin("render prep")
        defer {
            Profiler.end()
            stats.prepareTime = Self.seconds(since: start)
        }
        gather(world)
        engine.postProcess = PostProcessSettings.find(in: world)

        guard let (_, camera, cameraWorld) = RenderPrep.findCamera(in: world, preferred: self.camera) else {
            uniforms = nil
            debugView = nil
            stats.list = RenderListStats()
            stats.lights = LightClusters.Stats()
            stats.shadows = ShadowStats()
            return
        }
        reversedZ = camera.reversedZ
        engine.clearColor = camera.clearColor
        engine.clearDepth = camera.reversedZ ? 0 : 1

        let view = Camera.viewMatrix(world: cameraWorld)
        let viewProj = camera.projection(aspect: engine.aspectRatio) * view
        let jitteredProjection = engine.jittered(camera.projection(aspect: engine.aspectRatio))
        let jittered = jitteredProjection * view
        let eye = Vec3(cameraWorld.c3.x, cameraWorld.c3.y, cameraWorld.c3.z)

        let environment = RenderPrep.findEnvironment(in: world)
        let viewFrustum = Frustum(viewProjection: jittered)
        let light = lightSetup(world: world, focus: ShadowSetup.Focus(
            view: view, projection: camera.projection(aspect: engine.aspectRatio), frustum: viewFrustum))
        shadowsActive = light.shadows != nil

        list.build(items: prep.items, view: viewFrustum, cameraPosition: eye, shadows: nil)
        stats.list = list.stats
        buildShadowCasters(light.shadows)

        let previous = previousViewProj ?? viewProj
        previousViewProj = viewProj
        uniforms = makeUniforms(viewProj: jittered, current: viewProj, previous: previous, eye: eye, light: light,
                                environment: environment)
        prepareEnvironment(environment, light: light)
        uniforms!.environment = environmentLighting.lighting
        skyView = (view, jitteredProjection)
        let size = engine.renderSize
        // Binned with the projection the pass rasterizes with, so tiles match gl_FragCoord.
        clusters.build(lights: punctualLights, view: view, projection: jitteredProjection)
        clusters.write(to: &lightData)
        stats.lights = clusters.stats
        uniforms!.setClusters(clusters, view: view, size: size)
        if let shadows = light.shadows { uniforms!.shadows = shadows.uniforms(for: clusters) }
        shadowSetup = light.shadows
        debugView = DebugView(viewProjection: jittered, cameraPosition: eye, viewportSize: size, reversedZ: camera.reversedZ,
                              projectionScale: camera.projection(aspect: engine.aspectRatio).c1.y)
        particleView = (jittered, jitteredProjection, eye, size, camera.reversedZ)
        prepareParticles(world: world, cameraPosition: eye)
        prepareWorldText(world: world)
    }

    /// Sets up the sky and image-based lighting of `environment` for this frame.
    private func prepareEnvironment(_ environment: SceneEnvironment, light: LightSetup) {
        let map = environment.sky == .map ? environment.environmentMap.flatMap { texture($0) } : nil
        environmentLighting.prepare(environment, map: map, toLight: light.toLight, lightColor: light.color * light.intensity)
    }

    func gather(_ world: World) {
        syncAssets()
        syncLineMeshes(world)
        prep.gather(world: world)
        // Upload assets entities started using, then gather again so they draw this frame
        // (only on frames where something new resolved).
        if resolveMissingAssets() { prep.gather(world: world) }
        PunctualLight.gather(in: world, into: &punctualLights)
        gatherDecals(world: world)
        for key in prep.missingKeys where !reportedMissing.contains(key) && !prep.meshes.contains(key) && !prep.materials.contains(key)
            && (assets == nil || AssetReference(key) == nil || failedAssetKeys.contains(key)) {
            reportedMissing.insert(key)
            print("SceneRenderer: no mesh or material registered as '\(key)'; entities using it are skipped")
        }
    }

    /// The first directional light's parameters and the frame's shadows (`ShadowSetup`: the
    /// light's cascades or fixed map, and the shadowed point / spot lights), set up for `focus`.
    private func lightSetup(world: World, focus: ShadowSetup.Focus) -> LightSetup {
        var setup = LightSetup(toLight: normalize(Vec3(0.5, 0.75, 0.35)), color: .zero, intensity: 0, bias: 0, shadows: nil)
        let found = RenderPrep.findLight(in: world)
        if let (light, lightWorld) = found {
            setup.toLight = -light.travelDirection(world: lightWorld)
            setup.color = light.color
            setup.intensity = light.intensity
            setup.bias = light.shadowBias
        }
        setup.shadows = ShadowSetup.build(light: found?.light, toLight: setup.toLight, focus: focus, lights: &punctualLights,
                                          items: prep.items, quality: quality, showCascades: showsShadowCascades)
        stats.shadows = setup.shadows?.stats ?? ShadowStats()
        return setup
    }

    /// Culls and batches casters for every tile of `shadows`, and counts them in `stats.list`.
    private func buildShadowCasters(_ shadows: ShadowSetup?) {
        guard let shadows else { return }
        shadowCasters.build(items: prep.items, tiles: shadows.tiles.map(\.culling))
        stats.list.shadowCasters = shadowCasters.drawn
        stats.list.culledShadowCasters = shadowCasters.culled
        stats.list.drawCalls += shadowCasters.batches.count
    }

    private func makeUniforms(viewProj: Mat4, current: Mat4, previous: Mat4, eye: Vec3, light: LightSetup,
                              environment: SceneEnvironment) -> FrameUniforms {
        FrameUniforms(
            viewProj: viewProj,
            lightViewProj: light.shadows.map { $0.tiles.first?.clip ?? .identity } ?? .identity,
            currentViewProj: current,
            previousViewProj: previous,
            lightDir: Vec4(light.toLight, light.intensity),
            lightColor: Vec4(light.color, light.sunShadows ? 1 : 0),
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

    /// Uploads this frame's instances once and renders the shadow atlas. Call after `prepare`,
    /// from `Game.renderOffscreen`.
    public func renderShadows(frame: Frame) {
        guard uniforms != nil else { return }
        uploaded = list.instances.isEmpty ? nil : frame.upload(list.instances)
        environmentLighting.render()
        renderShadowAtlas(shadowsActive ? shadowSetup : nil, frame: frame)
        renderParticleDepth(frame: frame)
        particles?.simulate(frame: frame)
    }

    /// Renders every tile of `shadows` into the atlas in one depth pass (resizing the atlas to
    /// its layout first). Without shadows, only clears the atlas once, so it's valid to bind.
    private func renderShadowAtlas(_ shadows: ShadowSetup?, frame: Frame) {
        if let layout = shadows?.layout, layout.width != shadowMap.width || layout.height != shadowMap.height {
            do {
                shadowMap = try device.makeTexture(TextureDescriptor(width: layout.width, height: layout.height, format: .depth32Float))
                shadowMapCleared = false
            } catch {
                print("SceneRenderer: shadow atlas of \(layout.width)x\(layout.height) unavailable: \(error)")
            }
        }
        guard let shadows, shadows.layout.width == shadowMap.width, shadows.layout.height == shadowMap.height else {
            guard !shadowMapCleared else { return }
            shadowMapCleared = true
            frame.depthPass(into: shadowMap) { _ in }
            return
        }
        shadowMapCleared = true
        let instances = shadowCasters.instances.isEmpty ? nil : frame.upload(shadowCasters.instances)
        frame.depthPass(into: shadowMap) { pass in
            guard let instances else { return }
            pass.setPipeline(shadowPipeline)
            for (tile, range) in zip(shadows.tiles, shadowCasters.tileBatches) where !range.isEmpty {
                pass.setScissorRect(ScissorRect(x: tile.rect.x, y: tile.rect.y, width: tile.rect.width, height: tile.rect.height))
                pass.setUniforms(ShadowPassUniforms(viewProj: tile.clip, lightViewProj: tile.clip))
                drawShadows(pass, shadowCasters.batches[range], instances: instances)
            }
        }
    }

    /// The prefix of `Frame` the shadow shaders read (mesh_shadow.vert): the tile's projection.
    private struct ShadowPassUniforms: BitwiseCopyable {
        var viewProj: Mat4
        var lightViewProj: Mat4
    }

    /// Draws the prepared frame into the screen pass: opaque batches, then transparent ones
    /// back to front, then `debugDraw`.
    public func draw(_ pass: RenderPass) {
        guard let uniforms else { return }
        draw(pass, list: list, uniforms: uniforms, instances: uploaded, reversedZ: reversedZ, lights: clusters.isEmpty ? nil : lightData,
             sky: skyView, particleDepth: particleDepth)
        if let debugDraw, let debugView { drawDebug(debugDraw, in: pass, view: debugView) }
    }

    // MARK: - Views

    /// Starts this frame's `renderView` calls: gathers the world's entities, sets up the light
    /// and renders the shared shadow map (all casters in the light's frustum, centered for
    /// `shadowFocus`, by default the camera `prepare` would use). Call once per frame in
    /// `Game.renderOffscreen`, after the world's transforms are current.
    public func beginViews(world: World, frame: Frame, shadowFocus: SceneView? = nil) {
        let start = ContinuousClock.now
        Profiler.begin("render prep")
        defer {
            Profiler.end()
            stats.prepareTime = Self.seconds(since: start)
        }
        gather(world)
        let focus: ShadowSetup.Focus
        if let shadowFocus {
            focus = ShadowSetup.Focus(view: shadowFocus.view, projection: shadowFocus.projection,
                                      frustum: Frustum(viewProjection: shadowFocus.viewProjection))
        } else {
            // The views may look anywhere: no perspective to fit cascades to, no view to cull with.
            let view = RenderPrep.findCamera(in: world, preferred: camera).map { Camera.viewMatrix(world: $0.world) } ?? .identity
            focus = ShadowSetup.Focus(view: view, projection: nil, frustum: nil)
        }
        let light = lightSetup(world: world, focus: focus)
        let environment = RenderPrep.findEnvironment(in: world)
        views = ViewsFrame(light: light, environment: environment)
        prepareEnvironment(environment, light: light)
        environmentLighting.render()
        buildShadowCasters(light.shadows)
        renderShadowAtlas(light.shadows, frame: frame)
        prepareParticles(world: world, cameraPosition: shadowFocus?.eye ?? Vec3(focus.view.inverse.c3.x, focus.view.inverse.c3.y,
                                                                                focus.view.inverse.c3.z))
        prepareWorldText(world: world)
        particles?.sceneDepth = nil  // no single camera: no depth collisions
        particles?.simulate(frame: frame)
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
        var uniforms = makeUniforms(viewProj: viewProj, current: viewProj, previous: viewProj, eye: eye, light: views.light,
                                    environment: views.environment)
        viewClusters.build(lights: punctualLights, view: view.view, projection: view.projection)
        if !viewClusters.isEmpty { viewClusters.write(to: &lightData) }
        stats.lights = viewClusters.stats
        uniforms.setClusters(viewClusters, view: view.view, size: (target.width, target.height))
        if let shadows = views.light.shadows { uniforms.shadows = shadows.uniforms(for: viewClusters) }
        uniforms.environment = environmentLighting.lighting
        let lights = viewClusters.isEmpty ? nil : lightData
        let particleDepth = renderViewParticleDepth(list: viewList, instances: instances, view: view,
                                                    size: (target.width, target.height), frame: frame)
        frame.renderPass(into: target, clearColor: view.clearColor, clearDepth: view.reversedZ ? 0 : 1) { pass in
            draw(pass, list: viewList, uniforms: uniforms, instances: instances, reversedZ: view.reversedZ, lights: lights,
                 sky: (view.view, view.projection), particleDepth: particleDepth)
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

    /// Depth-only pipeline configurations: the shadow atlas's (depth bias, standard Z) and the
    /// camera depth prepass's (`renderDepthPrepass`: no bias, the camera's depth direction).
    enum DepthVariant: Hashable {
        case shadow
        case prepass(reversedZ: Bool)
    }

    private struct PrepassKey: Hashable {
        var reversedZ: Bool
        var alphaTested: Bool
        var skinned: Bool
    }

    /// Shadow batches: depth only, except alpha-tested ones, which sample their material's alpha.
    /// Skinned casters use the skinning variants with their joint matrices. The pass starts with
    /// `variant`'s plain pipeline set.
    private func drawShadows(_ pass: RenderPass, _ batches: ArraySlice<RenderBatch>, instances: TransientBuffer,
                             variant: DepthVariant = .shadow) {
        guard let plain = depthPipeline(variant, alphaTested: false, skinned: false) else { return }
        var masked = false
        var skinned = false
        for batch in batches {
            if batch.skin >= 0 {
                guard let pipeline = depthPipeline(variant, alphaTested: batch.material >= 0, skinned: true) else { continue }
                pass.setPipeline(pipeline)
                if batch.material >= 0 { bindMaterial(batch.material, in: pass, skin: batch.skin) } else { bindSkin(batch.skin, material: nil, in: pass) }
                skinned = true
                draw(pass, batch, instances: instances)
                continue
            }
            if skinned {
                // Back to the pipeline the batches below expect.
                pass.setPipeline(masked ? depthPipeline(variant, alphaTested: true, skinned: false) ?? plain : plain)
                skinned = false
            }
            if batch.material >= 0, let pipeline = depthPipeline(variant, alphaTested: true, skinned: false) {
                if !masked { pass.setPipeline(pipeline) }
                masked = true
                bindMaterial(batch.material, in: pass)
            } else if masked {
                pass.setPipeline(plain)
                masked = false
            }
            draw(pass, batch, instances: instances)
        }
        if skinned { pass.setPipeline(masked ? depthPipeline(variant, alphaTested: true, skinned: false) ?? plain : plain) }
    }

    private func depthPipeline(_ variant: DepthVariant, alphaTested: Bool, skinned: Bool) -> RenderPipeline? {
        switch variant {
        case .shadow:
            skinned ? skinnedShadowPipeline(alphaTested: alphaTested) : alphaTested ? maskedShadowPipeline() : shadowPipeline
        case .prepass(let reversedZ):
            prepassPipeline(PrepassKey(reversedZ: reversedZ, alphaTested: alphaTested, skinned: skinned))
        }
    }

    /// The shadow shaders without depth bias, testing in the camera's depth direction.
    private func prepassPipeline(_ key: PrepassKey) -> RenderPipeline? {
        if let pipeline = prepassPipelines[key] { return pipeline }
        do {
            let shader = switch (key.skinned, key.alphaTested) {
            case (false, false): try ShaderSource.load(named: "mesh_shadow", bundle: .module)
            case (false, true): try ShaderSource.load(named: "mesh_shadow_mask", bundle: .module)
            case (true, false): try ShaderSource.load(named: "mesh_shadow_skinned", bundle: .module)
            case (true, true): try ShaderSource.load(vertex: "mesh_shadow_mask_skinned", fragment: "mesh_shadow_mask", bundle: .module)
            }
            var descriptor = PipelineDescriptor(shader: shader, vertexLayout: key.skinned ? SkinnedMeshVertex.layout : MeshVertex.layout,
                                                instanceLayout: MeshInstance.layout)
            descriptor.target = .depthOnly
            descriptor.depthOnlyFragment = key.alphaTested
            descriptor.cullMode = .none
            descriptor.depthCompare = key.reversedZ ? .greater : .less
            let pipeline = try device.makePipeline(descriptor)
            prepassPipelines[key] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: depth prepass pipeline creation failed: \(error)")
            return nil
        }
    }

    /// Renders the opaque batches of `list` (`instances` uploaded for it), seen with
    /// `viewProjection`, into `target`'s depth (cleared to the far plane): what particles fade
    /// against (`softness`) and collide with (`collidesWithDepth`). Transparent batches don't
    /// occlude and aren't drawn.
    func renderDepthPrepass(into target: GPUTexture, list: RenderList, instances: TransientBuffer?, viewProjection: Mat4,
                            reversedZ: Bool, frame: Frame) {
        let variant = DepthVariant.prepass(reversedZ: reversedZ)
        // Depth-only batches have no material, alpha-tested ones keep theirs (as for shadows).
        let batches = list.opaque.map { batch -> RenderBatch in
            var batch = batch
            if !materials[batch.material].material.alphaTested { batch.material = -1 }
            return batch
        }
        frame.depthPass(into: target, clearDepth: reversedZ ? 0 : 1) { pass in
            guard let instances, !batches.isEmpty, let plain = depthPipeline(variant, alphaTested: false, skinned: false) else { return }
            pass.setPipeline(plain)
            pass.setUniforms(ShadowPassUniforms(viewProj: viewProjection, lightViewProj: viewProjection))
            drawShadows(pass, batches[...], instances: instances, variant: variant)
        }
    }

    private func skinnedShadowPipeline(alphaTested: Bool) -> RenderPipeline? {
        if let pipeline = skinnedShadowPipelines[alphaTested] { return pipeline }
        do {
            var descriptor = PipelineDescriptor(
                shader: alphaTested
                    ? try ShaderSource.load(vertex: "mesh_shadow_mask_skinned", fragment: "mesh_shadow_mask", bundle: .module)
                    : try ShaderSource.load(named: "mesh_shadow_skinned", bundle: .module),
                vertexLayout: SkinnedMeshVertex.layout, instanceLayout: MeshInstance.layout)
            descriptor.target = .depthOnly
            descriptor.depthOnlyFragment = alphaTested
            descriptor.cullMode = .none
            descriptor.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
            let pipeline = try device.makePipeline(descriptor)
            skinnedShadowPipelines[alphaTested] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: skinned shadow pipeline creation failed: \(error)")
            return nil
        }
    }

    private func maskedShadowPipeline() -> RenderPipeline? {
        if let shadowMaskPipeline { return shadowMaskPipeline }
        do {
            var descriptor = PipelineDescriptor(
                shader: try ShaderSource.load(named: "mesh_shadow_mask", bundle: .module),
                vertexLayout: MeshVertex.layout, instanceLayout: MeshInstance.layout)
            descriptor.target = .depthOnly
            descriptor.depthOnlyFragment = true
            descriptor.cullMode = .none
            descriptor.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
            shadowMaskPipeline = try device.makePipeline(descriptor)
        } catch {
            print("SceneRenderer: alpha-tested shadow pipeline creation failed: \(error)")
        }
        return shadowMaskPipeline
    }

    /// Binds the point / spot light buffers 3-7 (copied into the frame's transient memory), or
    /// zeros when there are none (the shader skips the lights then, but Vulkan wants every
    /// declared binding valid).
    func bindLights(_ lights: LightClusters.GPUData?, in pass: RenderPass, stage: ShaderStage = .fragment) {
        guard let lights else {
            for index in 3...7 { pass.setUniformBuffer(emptyLightBuffer, index: index, stage: stage) }
            return
        }
        lights.positions.withUnsafeBytes { pass.setUniformData($0, index: 3, stage: stage) }
        lights.colors.withUnsafeBytes { pass.setUniformData($0, index: 4, stage: stage) }
        lights.directions.withUnsafeBytes { pass.setUniformData($0, index: 5, stage: stage) }
        lights.cells.withUnsafeBytes { pass.setUniformData($0, index: 6, stage: stage) }
        lights.indices.withUnsafeBytes { pass.setUniformData($0, index: 7, stage: stage) }
    }

    /// Binds the skinning uniform block of `prep.skins[skin]` (buffer 2, both stages), with
    /// `material`'s uniforms as its prefix (zeros for nil).
    func bindSkin(_ skin: Int, material: Int?, in pass: RenderPass) {
        let pose = skin < prep.skins.count ? prep.skins[skin] : nil
        SkinPose.uniformBlock(material: material.map { MaterialUniforms(materials[$0].material) }, pose: pose, into: &skinBlock)
        skinBlock.withUnsafeBytes { pass.setUniformData($0, index: 2, stage: .all) }
    }

    /// Binds a material's uniforms (buffer 2), textures 1-5 and sampler 1. For a skinned batch,
    /// buffer 2 is the skinning block with the material's uniforms as its prefix.
    private func bindMaterial(_ index: Int, in pass: RenderPass, skin: Int = -1) {
        let (material, sampler) = materials[index]
        if skin >= 0 {
            bindSkin(skin, material: index, in: pass)
        } else {
            pass.setUniformData(MaterialUniforms(material), index: 2, stage: .fragment)
        }
        pass.setTexture(material.texture ?? whiteTexture, index: 1)
        pass.setTexture(material.metallicRoughnessTexture ?? whiteTexture, index: 2)
        pass.setTexture(material.normalTexture ?? whiteTexture, index: 3)
        pass.setTexture(material.occlusionTexture ?? whiteTexture, index: 4)
        pass.setTexture(material.emissiveTexture ?? whiteTexture, index: 5)
        pass.setSampler(sampler, index: 1)
    }

    /// Opaque batches, then the sky (seen from `sky`'s view and projection, if the environment
    /// has one), then transparent batches back to front.
    private func draw(_ pass: RenderPass, list: RenderList, uniforms: FrameUniforms, instances uploaded: TransientBuffer?,
                      reversedZ: Bool, lights: LightClusters.GPUData?, sky: (view: Mat4, projection: Mat4)?,
                      particleDepth: ParticleSceneDepth?) {
        pass.setUniforms(uniforms)
        pass.setTexture(shadowMap)
        bindLights(lights, in: pass)
        environmentLighting.bindLighting(in: pass)
        var current: (pipeline: PipelineKey, material: Int, skin: Int)?
        for (batches, blending) in [(list.opaque, false), (list.transparent, true)] {
            if blending {
                // Decals paint the opaque surfaces only: after them, before the sky and glass.
                if drawDecals(in: pass, uniforms: uniforms, reversedZ: reversedZ, depth: particleDepth) { current = nil }
            }
            if blending, let sky {
                environmentLighting.drawSky(in: pass, view: sky.view, projection: sky.projection, reversedZ: reversedZ)
                current = nil  // the sky replaced the pipeline and the material's bindings
            }
            guard let uploaded else { continue }
            for batch in batches {
                var key = Self.pipelineKey(for: materials[batch.material].material, blending: blending, reversedZ: reversedZ)
                key.skinned = batch.skin >= 0
                if current?.pipeline != key {
                    guard let pipeline = pipeline(key) else { continue }
                    pass.setPipeline(pipeline)
                }
                if current?.material != batch.material || batch.skin >= 0 || (current?.skin ?? -1) >= 0 {
                    bindMaterial(batch.material, in: pass, skin: batch.skin)
                }
                current = (key, batch.material, batch.skin)
                draw(pass, batch, instances: uploaded)
            }
        }
        if particles?.hasLitEmitters == true {
            // Lit particles are lit per vertex: the vertex stage reads what the meshes' fragments did.
            bindLights(lights, in: pass, stage: .vertex)
            environmentLighting.bindLighting(in: pass, stage: .vertex)
            pass.setTexture(shadowMap, index: 3, stage: .vertex)
        }
        drawParticles(in: pass, uniforms: uniforms, reversedZ: reversedZ, depth: particleDepth)
        drawWorldText(in: pass, uniforms: uniforms, view: sky?.view, reversedZ: reversedZ)
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
        if key.alphaTested && maskShader == nil {
            do {
                maskShader = try ShaderSource.load(vertex: "mesh", fragment: "mesh_mask", bundle: .module)
            } catch {
                print("SceneRenderer: alpha-tested shader unavailable: \(error)")
                return nil
            }
        }
        if key.skinned && skinnedShaders[key.alphaTested] == nil {
            do {
                skinnedShaders[key.alphaTested] = try ShaderSource.load(
                    vertex: "mesh_skinned", fragment: key.alphaTested ? "mesh_mask" : "mesh", bundle: .module)
            } catch {
                print("SceneRenderer: skinning shader unavailable: \(error)")
                return nil
            }
        }
        let shader = key.skinned ? skinnedShaders[key.alphaTested]! : key.alphaTested ? maskShader! : shader
        var descriptor = PipelineDescriptor(shader: shader, vertexLayout: key.skinned ? SkinnedMeshVertex.layout : MeshVertex.layout,
                                            instanceLayout: MeshInstance.layout)
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
