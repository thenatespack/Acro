#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

// SceneRenderer's light probes (see LightProbes.swift for the components and the math, and
// probes.glsl for the shading).
//
// Every frame `findProbes` collects the gathered world's enabled `ReflectionProbe`s and
// `IrradianceVolume`s with their bake keys, looks up bakes it doesn't have in the cache
// (`probeBakeCache`: the project's Library/Lighting, or an exported game's pack) and lays out
// the probe buffer (`ProbeBufferLayout`) for the probes that have one; the mesh shaders read it
// as storage buffer 1. A probe without a bake keeps the last bake its entity had (moved in the
// editor: stale until baked again) or is left out, and the sky lights what it would have.
//
// Baking (`bakeProbes`, or automatically while `bakesProbesAutomatically`) happens in the
// offscreen part of a frame (`renderShadows` / `beginViews`), before the frame's shadow atlas:
// 1. A shadow atlas covering every probe (the directional light's shadows centered on them,
//    whatever the camera sees), and CPU rays from every irradiance probe to find those inside
//    geometry (most rays leaving through back faces): they are turned off and reported.
// 2. Per bounce, per irradiance probe: the scene drawn from the probe into six 32 px faces
//    (meshes and the sky, the real lights and shadows; the volumes lit by the previous bounce,
//    black in the first), turned into a 64 x 32 equirectangular image (probe_equirect.frag),
//    projected onto SH9 (env_sh.frag) and stored into the buffer (probe_store.comp).
// 3. Per reflection probe: six 128 px faces lit by the finished volumes, a 256 x 128
//    equirectangular image, five prefiltered levels (env_prefilter.frag) and the store.
// The frame draws with the new buffer at once; it is then read back, split into bakes, kept by
// key, written to the cache and reported (`LightProbeBakeReport`).

/// Storage buffer 1 of the mesh shaders: the probes' records, the irradiance probes' SH and the
/// reflection probes' images, in 32-bit words (probes.glsl describes it).
struct ProbeBufferLayout {
    struct Reflection {
        var key: String
        var probe: ReflectionProbe
        var frame: LightProbeFrame
    }

    struct Volume {
        var key: String
        var volume: IrradianceVolume
        var frame: LightProbeFrame
    }

    static let recordVec4s = 8

    var reflections: [Reflection]
    var volumes: [Volume]
    /// Each volume's first SH vec4.
    var shFirst: [Int] = []
    /// Each reflection probe's first image word (its first texel is half of it).
    var imageFirstWord: [Int] = []
    var wordCount = 0

    init(reflections: [Reflection], volumes: [Volume]) {
        self.reflections = reflections
        self.volumes = volumes
        var vec4 = (reflections.count + volumes.count) * Self.recordVec4s
        for volume in volumes {
            shFirst.append(vec4)
            vec4 += volume.volume.probeCount * 4
        }
        var word = vec4 * 4
        for _ in reflections {
            imageFirstWord.append(word)
            word += ReflectionProbeImage.wordCount
        }
        wordCount = max(word, 4)
    }

    /// The first word of volume `index`'s probe `probe`'s coefficients.
    func shWord(volume index: Int, probe: Int) -> Int { (shFirst[index] + probe * 4) * 4 }

    /// One irradiance probe's 16 buffer words from its `IrradianceProbeCapture.wordCount` floats:
    /// the nine RGB coefficients and the validity as 28 half floats (probes.glsl).
    static func packSH(_ c: ArraySlice<Float>) -> [UInt32] {
        let b = c.startIndex
        var halves = [Float](repeating: 0, count: 32)
        for k in 0..<9 { for ch in 0..<3 { halves[k * 3 + ch] = c[b + k * 4 + ch] } }
        halves[27] = c[b + 3]
        return (0..<16).map { UInt32(Float16(halves[$0 * 2]).bitPattern) | UInt32(Float16(halves[$0 * 2 + 1]).bitPattern) << 16 }
    }

    /// The inverse of `packSH`: 36 floats, the validity in the first coefficient's alpha.
    static func unpackSH(_ words: ArraySlice<UInt32>) -> [Float] {
        let b = words.startIndex
        let halves = (0..<16).flatMap { i -> [Float] in
            let v = ReflectionProbeBake.unpackHalves(words[b + i])
            return [v.x, v.y]
        }
        var out = [Float](repeating: 0, count: IrradianceProbeCapture.wordCount)
        for k in 0..<9 { for ch in 0..<3 { out[k * 4 + ch] = halves[k * 3 + ch] } }
        out[3] = halves[27]
        return out
    }

    /// Rows 0-2 of a record: world to the probe's space.
    private static func rows(_ frame: LightProbeFrame) -> [Vec4] {
        let m = frame.inverse
        return [Vec4(m.c0.x, m.c1.x, m.c2.x, m.c3.x), Vec4(m.c0.y, m.c1.y, m.c2.y, m.c3.y), Vec4(m.c0.z, m.c1.z, m.c2.z, m.c3.z)]
    }

    /// The buffer's words: records, then the volumes' coefficients and the probes' images from
    /// `volumeBakes` / `reflectionBakes` (zeros where a probe has none, its validity from `validity`).
    func words(reflectionBakes: [ReflectionProbeBake?], volumeBakes: [IrradianceVolumeBake?], validity: [[Bool]] = []) -> [UInt32] {
        var out = [UInt32](repeating: 0, count: wordCount)
        func put(_ vec4: Int, _ v: Vec4) {
            out[vec4 * 4] = v.x.bitPattern
            out[vec4 * 4 + 1] = v.y.bitPattern
            out[vec4 * 4 + 2] = v.z.bitPattern
            out[vec4 * 4 + 3] = v.w.bitPattern
        }
        for (i, r) in reflections.enumerated() {
            let base = i * Self.recordVec4s
            for (k, row) in Self.rows(r.frame).enumerated() { put(base + k, row) }
            put(base + 3, Vec4(r.probe.halfExtents, max(r.probe.blendDistance, 0)))
            put(base + 4, Vec4(r.probe.projectionHalfExtents, r.probe.boxProjection ? 1 : 0))
            put(base + 5, Vec4(r.probe.captureOffset, max(r.probe.intensity, 0)))
            out[(base + 6) * 4] = UInt32(imageFirstWord[i] / 2)
            if i < reflectionBakes.count, let bake = reflectionBakes[i], bake.words.count == ReflectionProbeImage.wordCount {
                out.replaceSubrange(imageFirstWord[i]..<imageFirstWord[i] + ReflectionProbeImage.wordCount, with: bake.words)
            }
        }
        for (j, v) in volumes.enumerated() {
            let base = (reflections.count + j) * Self.recordVec4s
            for (k, row) in Self.rows(v.frame).enumerated() { put(base + k, row) }
            let n = v.volume.counts
            put(base + 3, Vec4(v.volume.halfExtents, max(v.volume.blendDistance, 0)))
            put(base + 4, Vec4(Float(n.x), Float(n.y), Float(n.z), 0))
            put(base + 5, Vec4(max(v.volume.normalBias, 0), max(v.volume.viewBias, 0), max(v.volume.intensity, 0), 0))
            out[(base + 6) * 4] = UInt32(shFirst[j])
            let count = v.volume.probeCount
            if j < volumeBakes.count, let bake = volumeBakes[j], bake.coefficients.count == count * IrradianceProbeCapture.wordCount {
                for p in 0..<count {
                    let packed = Self.packSH(bake.coefficients[p * IrradianceProbeCapture.wordCount..<(p + 1) * IrradianceProbeCapture.wordCount])
                    out.replaceSubrange(shWord(volume: j, probe: p)..<shWord(volume: j, probe: p) + 16, with: packed)
                }
            } else {
                // No bake: black and valid (or off where `validity` says so), as the first bounce sees it.
                for p in 0..<count {
                    let valid = j < validity.count && p < validity[j].count ? validity[j][p] : true
                    out[shWord(volume: j, probe: p) + 13] = UInt32(Float16(valid ? 1 : 0).bitPattern) << 16
                }
            }
        }
        return out
    }

    /// `frame.probes`: the counts.
    var uniform: Vec4 { Vec4(Float(reflections.count), Float(volumes.count), 0, 0) }
}

/// A probe the world has this frame.
struct FoundProbe<Settings> {
    var entity: Entity
    var name: String
    var settings: Settings
    var frame: LightProbeFrame
    var key: String
}

/// `SceneRenderer`'s probe state: what the world has, the bakes, the buffer and the bake's GPU objects.
@MainActor
final class ProbeState {
    let device: RenderDevice
    /// Bound when there are no probes (Vulkan wants every declared binding valid).
    let emptyBuffer: GPUBuffer

    var reflections: [FoundProbe<ReflectionProbe>] = []
    var volumes: [FoundProbe<IrradianceVolume>] = []
    var world: ObjectIdentifier?

    /// Bakes by key.
    var reflectionBakes: [String: ReflectionProbeBake] = [:]
    var volumeBakes: [String: IrradianceVolumeBake] = [:]
    /// The key each probe entity last drew with (per world), so a moved probe keeps its bake until baked again.
    var lastKeys: [String: String] = [:]
    /// Keys already looked up in the cache.
    var looked: Set<String> = []
    var cache: LightProbeBakeCache?
    var cacheOwner: ObjectIdentifier?
    var explicitCache: LightProbeBakeCache?

    /// This frame's buffer and layout; buffers by contents signature (the editor draws two worlds a frame).
    var layout: ProbeBufferLayout?
    var buffer: GPUBuffer?
    var buffers: [(signature: String, buffer: GPUBuffer)] = []

    var debug = LightProbeDebug()
    var automatic = true
    /// Keys an automatic bake was already tried for.
    var autoBaked: Set<String> = []

    struct Request {
        var world: ObjectIdentifier?
        var completion: (@MainActor (LightProbeBakeReport) -> Void)?
    }
    var requests: [Request] = []
    var baking = 0
    /// The last bake's layout and buffer until its results are read back (drawn meanwhile).
    var pending: (world: ObjectIdentifier?, layout: ProbeBufferLayout, buffer: GPUBuffer)?

    /// What the frame's light and environment were (`prepare` / `beginViews`).
    var frameLight: SceneRenderer.LightSetup?
    var frameEnvironment = SceneEnvironment()
    var sun: DirectionalLight?
    /// The camera's clear color, which captures clear to (seen where there is no sky).
    var clearColor = Vec4(0, 0, 0, 1)

    // Bake objects, made on the first bake.
    var reflectionFaces: [RenderTarget] = []
    var irradianceFaces: [RenderTarget] = []
    var levels: [GPURenderTarget] = []
    var irradianceImage: GPURenderTarget?
    var shTarget: GPURenderTarget?
    var equirectPipeline: RenderPipeline?
    var prefilterPipeline: RenderPipeline?
    var shPipeline: RenderPipeline?
    var storePipeline: ComputePipeline?
    var pointSampler: GPUSampler
    var list = RenderList()
    var clusters = LightClusters()
    var lightData = LightClusters.GPUData()
    var casters = ShadowCasterBatches()
    var spherePipelines: [Bool: RenderPipeline] = [:]
    var fragmentShaders: [String: ShaderSource] = [:]
    var failed = false

    init(device: RenderDevice) throws {
        self.device = device
        emptyBuffer = try device.makeBuffer(length: 256, usage: .storage)
        pointSampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
    }

    /// `frame.probes` for this frame's buffer.
    var uniform: Vec4 {
        var u = layout?.uniform ?? .zero
        u.z = debug.irradianceOnly ? 1 : 0
        return u
    }

    func lastKey(_ entity: Entity) -> String { "\(world.map { "\($0.hashValue)" } ?? "")-\(entity.index)-\(entity.generation)" }
}

extension SceneRenderer {
    /// Bake light probes automatically when the world has some without a bake (none cached for
    /// them): in the frame they first appear. On by default (games and the demo); the editor turns it
    /// off and bakes on request (`lighting.bake`).
    public var bakesProbesAutomatically: Bool {
        get { probes.automatic }
        set { probes.automatic = newValue }
    }

    /// The light probes' debug views.
    public var probeDebug: LightProbeDebug {
        get { probes.debug }
        set { probes.debug = newValue }
    }

    /// Where probe bakes are cached and looked up: set explicitly, or by default the cache of
    /// `assets` (its project's Library/Lighting, or its pack); nil without either.
    public var probeBakeCache: LightProbeBakeCache? {
        get {
            if let explicit = probes.explicitCache { return explicit }
            guard let assets else { return nil }
            if probes.cacheOwner != ObjectIdentifier(assets) {
                probes.cache = LightProbeBakeCache.forAssets(assets)
                probes.cacheOwner = ObjectIdentifier(assets)
            }
            return probes.cache
        }
        set { probes.explicitCache = newValue }
    }

    /// The probes of the last world gathered: reflection probes, irradiance volumes and their
    /// probes, and how many of each are drawn with a bake.
    public var probeSummary: (reflectionProbes: Int, irradianceVolumes: Int, irradianceProbes: Int, bakedReflectionProbes: Int,
                              bakedIrradianceVolumes: Int) {
        (probes.reflections.count, probes.volumes.count, probes.volumes.reduce(0) { $0 + $1.settings.probeCount },
         probes.layout?.reflections.count ?? 0, probes.layout?.volumes.count ?? 0)
    }

    /// Bakes every enabled light probe of `world` (nil: the next world gathered) in the next
    /// frame's offscreen part (`renderShadows` / `beginViews`), and calls `completion` once the
    /// results were read back and cached (a few frames later).
    public func bakeProbes(in world: World? = nil, completion: (@MainActor (LightProbeBakeReport) -> Void)? = nil) {
        probes.requests.append(ProbeState.Request(world: world.map(ObjectIdentifier.init), completion: completion))
    }

    /// Whether a bake is waiting for its frame or for its results.
    public var isBakingProbes: Bool { !probes.requests.isEmpty || probes.baking > 0 }

    /// Whether a bake is waiting for its world to be gathered (`prepare` / `beginViews`).
    public var hasProbeBakeRequests: Bool { !probes.requests.isEmpty }

    /// Forgets every bake held in memory (cached ones load again when needed).
    public func discardProbeBakes() {
        probes.reflectionBakes.removeAll()
        probes.volumeBakes.removeAll()
        probes.lastKeys.removeAll()
        probes.looked.removeAll()
        probes.autoBaked.removeAll()
        probes.buffers.removeAll()
    }

    // MARK: - Finding

    /// Collects `world`'s probes, loads cached bakes and lays out this frame's buffer (from `gather`).
    func findProbes(in world: World) {
        let state = probes
        state.world = ObjectIdentifier(world)
        state.reflections.removeAll(keepingCapacity: true)
        state.volumes.removeAll(keepingCapacity: true)
        state.sun = RenderPrep.findLight(in: world)?.light
        state.clearColor = RenderPrep.findCamera(in: world, preferred: camera)?.camera.clearColor ?? Vec4(0, 0, 0, 1)
        func frame(_ entity: Entity) -> LightProbeFrame {
            LightProbeFrame(world: world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity))
        }
        func name(_ entity: Entity) -> String { world.get(Name.self, for: entity)?.value ?? "entity \(entity.index)" }
        if world.existingStore(ReflectionProbe.self) != nil {
            world.query(ReflectionProbe.self) { entity, probe in
                guard probe.isEnabled else { return }
                let f = frame(entity)
                state.reflections.append(FoundProbe(entity: entity, name: name(entity), settings: probe, frame: f, key: probe.bakeKey(frame: f)))
            }
        }
        if world.existingStore(IrradianceVolume.self) != nil {
            world.query(IrradianceVolume.self) { entity, volume in
                guard volume.isEnabled else { return }
                let f = frame(entity)
                state.volumes.append(FoundProbe(entity: entity, name: name(entity), settings: volume, frame: f, key: volume.bakeKey(frame: f)))
            }
        }
        if !device.supportsStorageBuffers, !state.reflections.isEmpty || !state.volumes.isEmpty {
            // The probe-lit shaders read the probes from a storage buffer, and baking computes.
            warnUnavailable("Light probes (ReflectionProbe, IrradianceVolume)")
            state.reflections.removeAll()
            state.volumes.removeAll()
        }
        guard !state.reflections.isEmpty || !state.volumes.isEmpty else {
            state.layout = nil
            state.buffer = nil
            return
        }
        // Blending order: higher priority first, then smaller boxes, then entity order.
        state.reflections.sort { a, b in
            if a.settings.priority != b.settings.priority { return a.settings.priority > b.settings.priority }
            let va = a.settings.size.x * a.settings.size.y * a.settings.size.z, vb = b.settings.size.x * b.settings.size.y * b.settings.size.z
            if va != vb { return va < vb }
            return a.entity.index < b.entity.index
        }
        state.volumes.sort { $0.entity.index < $1.entity.index }
        if let pending = state.pending, pending.world == state.world {
            state.layout = pending.layout
            state.buffer = pending.buffer
            return
        }
        let cache = probeBakeCache
        for probe in state.reflections where state.reflectionBakes[probe.key] == nil && !state.looked.contains(probe.key) {
            state.looked.insert(probe.key)
            if let bake = cache?.loadReflection(key: probe.key) { state.reflectionBakes[probe.key] = bake }
        }
        for volume in state.volumes where state.volumeBakes[volume.key] == nil && !state.looked.contains(volume.key) {
            state.looked.insert(volume.key)
            if let bake = cache?.loadVolume(key: volume.key) { state.volumeBakes[volume.key] = bake }
        }
        // The probes with a bake (their own, or their entity's last one).
        var reflections: [ProbeBufferLayout.Reflection] = [], reflectionBakes: [ReflectionProbeBake?] = []
        for probe in state.reflections {
            let last = state.lastKeys[state.lastKey(probe.entity)]
            guard let bake = state.reflectionBakes[probe.key] ?? last.flatMap({ state.reflectionBakes[$0] }) else { continue }
            state.lastKeys[state.lastKey(probe.entity)] = bake.key
            reflections.append(.init(key: bake.key, probe: probe.settings, frame: probe.frame))
            reflectionBakes.append(bake)
        }
        var volumes: [ProbeBufferLayout.Volume] = [], volumeBakes: [IrradianceVolumeBake?] = []
        for volume in state.volumes {
            let last = state.lastKeys[state.lastKey(volume.entity)]
            guard let bake = state.volumeBakes[volume.key] ?? last.flatMap({ state.volumeBakes[$0] }),
                  bake.counts == volume.settings.counts, bake.probeCount > 0 else { continue }
            state.lastKeys[state.lastKey(volume.entity)] = bake.key
            volumes.append(.init(key: bake.key, volume: volume.settings, frame: volume.frame))
            volumeBakes.append(bake)
        }
        guard !reflections.isEmpty || !volumes.isEmpty else {
            state.layout = nil
            state.buffer = nil
            return
        }
        let layout = ProbeBufferLayout(reflections: reflections, volumes: volumes)
        let words = layout.words(reflectionBakes: reflectionBakes, volumeBakes: volumeBakes)
        // Records change when probes move; the rest follows the keys.
        let recordWords = (reflections.count + volumes.count) * ProbeBufferLayout.recordVec4s * 4
        let signature = (reflections.map(\.key) + volumes.map(\.key)).joined(separator: ",") + "|"
            + LightProbeBakeCache.hash(words[0..<recordWords].map { Float(bitPattern: $0) })
        state.layout = layout
        if let index = state.buffers.firstIndex(where: { $0.signature == signature }) {
            state.buffer = state.buffers[index].buffer
            return
        }
        do {
            let buffer = try device.makeBuffer(words, usage: .storage)
            state.buffer = buffer
            state.buffers.append((signature, buffer))
            if state.buffers.count > 4 { state.buffers.removeFirst() }
        } catch {
            print("SceneRenderer: light probe buffer unavailable: \(error)")
            state.layout = nil
            state.buffer = nil
        }
    }

    /// Binds the probe buffer (storage buffer 1) for the mesh shaders.
    func bindProbes(in pass: RenderPass) {
        guard device.supportsStorageBuffers else { return }
        pass.setStorageBuffer(probes.buffer ?? probes.emptyBuffer, offset: 0, index: 1, stage: .fragment)
    }

    /// The light probe variant of the mesh fragment shader (mesh(_paint)(_mask)_probes.frag), loaded on first use.
    func probeFragmentShader(painted: Bool, alphaTested: Bool) -> ShaderSource? {
        let name = "mesh" + (painted ? "_paint" : "") + (alphaTested ? "_mask" : "") + "_probes"
        if let shader = probes.fragmentShaders[name] { return shader }
        do {
            let shader = try ShaderSource.load(vertex: "mesh", fragment: name, bundle: .engineResources)
            probes.fragmentShaders[name] = shader
            return shader
        } catch {
            print("SceneRenderer: light probe shader \(name) unavailable: \(error)")
            return nil
        }
    }

    // MARK: - Debug spheres

    /// Draws a sphere per probe of this frame's buffer when `probeDebug.showsProbes` (probe_debug.frag);
    /// returns whether it changed the pass's pipeline.
    func drawProbeSpheres(in pass: RenderPass, reversedZ: Bool, encoded: Bool) -> Bool {
        guard probes.debug.showsProbes, !encoded, let layout = probes.layout, let mesh = mesh(.sphere) else {
            return false
        }
        var instances: [MeshInstance] = []
        func add(_ p: Vec3, radius: Float, color: Vec4) {
            let model = Mat4(translation: p, rotation: .identity, scale: Vec3(repeating: radius * 2))
            instances.append(MeshInstance(model: model, previousModel: model, color: color, params: .zero))
        }
        for (i, r) in layout.reflections.enumerated() {
            add(r.frame.toWorld(r.probe.captureOffset), radius: 0.3, color: Vec4(0, Float(i * ProbeBufferLayout.recordVec4s), 0, 1))
        }
        for (j, v) in layout.volumes.enumerated() {
            let record = (layout.reflections.count + j) * ProbeBufferLayout.recordVec4s
            let cell = v.volume.halfExtents * 2 / Vec3(Float(max(v.volume.counts.x, 1)), Float(max(v.volume.counts.y, 1)),
                                                        Float(max(v.volume.counts.z, 1)))
            let radius = min(max(min(cell.x, min(cell.y, cell.z)) * 0.15, 0.04), 0.25)
            for p in 0..<v.volume.probeCount where instances.count < 8192 {
                add(v.frame.toWorld(v.volume.localPosition(of: p)), radius: radius,
                    color: Vec4(1, Float(layout.shFirst[j] + p * 4), Float(record), 1))
            }
        }
        guard !instances.isEmpty, let pipeline = probeSpherePipeline(reversedZ: reversedZ) else { return false }

        pass.setPipeline(pipeline)
        pass.setVertexBuffer(mesh.vertexBuffer)
        pass.setIndexBuffer(mesh.indexBuffer, type: .uint32)
        pass.setVertexData(instances, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: instances.count)
        return true
    }

    private func probeSpherePipeline(reversedZ: Bool) -> RenderPipeline? {
        if let pipeline = probes.spherePipelines[reversedZ] { return pipeline }
        do {
            var descriptor = PipelineDescriptor(shader: try ShaderSource.load(vertex: "mesh", fragment: "probe_debug", bundle: .engineResources),
                                                vertexLayout: MeshVertex.layout, instanceLayout: MeshInstance.layout)
            descriptor.depthCompare = reversedZ ? .greater : .less
            descriptor.writesMotionVectors = true
            let pipeline = try device.makePipeline(descriptor)
            probes.spherePipelines[reversedZ] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: light probe debug pipeline unavailable: \(error)")
            probes.debug.showsProbes = false
            return nil
        }
    }

    // MARK: - Baking

    /// Records a bake of the gathered world's probes when one was asked for (or is due
    /// automatically). Returns whether it baked (this frame's buffer changed).
    @discardableResult
    func renderProbeBake(frame: Frame) -> Bool {
        let state = probes
        var due: [ProbeState.Request] = []
        state.requests.removeAll { request in
            guard request.world == nil || request.world == state.world else { return false }
            due.append(request)
            return true
        }
        if due.isEmpty, state.automatic, !state.failed, state.baking == 0 {
            let missing = state.reflections.filter { state.reflectionBakes[$0.key] == nil }.map(\.key)
                + state.volumes.filter { state.volumeBakes[$0.key] == nil }.map(\.key)
            if !missing.isEmpty, !missing.allSatisfy(state.autoBaked.contains) {
                state.autoBaked.formUnion(missing)
                due.append(ProbeState.Request(world: state.world, completion: nil))
            }
        }
        guard !due.isEmpty else { return false }
        state.autoBaked.formUnion(state.reflections.map(\.key) + state.volumes.map(\.key))
        let start = ContinuousClock.now
        var report = LightProbeBakeReport()
        func finish(_ report: LightProbeBakeReport) { for request in due { request.completion?(report) } }
        if state.reflections.isEmpty && state.volumes.isEmpty {
            report.warnings.append("Nothing to bake: the world has no enabled ReflectionProbe or IrradianceVolume")
            finish(report)
            return false
        }
        do {
            try makeBakeResources()
        } catch {
            state.failed = true
            report.warnings.append("Light probe baking is unavailable: \(error)")
            finish(report)
            return false
        }

        // What to bake, and what can't be.
        var reflections: [FoundProbe<ReflectionProbe>] = []
        for probe in state.reflections {
            if probe.settings.halfExtents.x <= 0 || probe.settings.halfExtents.y <= 0 || probe.settings.halfExtents.z <= 0 {
                report.warnings.append("ReflectionProbe '\(probe.name)' has an empty box (size \(probe.settings.size)); it reflects nothing")
            }
            reflections.append(probe)
        }
        var volumes: [FoundProbe<IrradianceVolume>] = []
        for volume in state.volumes {
            if volume.settings.probeCount == 0 {
                report.warnings.append("IrradianceVolume '\(volume.name)' has no probes (counts \(volume.settings.countX) x \(volume.settings.countY) x \(volume.settings.countZ))")
            } else if volume.settings.halfExtents.x <= 0 || volume.settings.halfExtents.y <= 0 || volume.settings.halfExtents.z <= 0 {
                report.warnings.append("IrradianceVolume '\(volume.name)' has an empty box (size \(volume.settings.size))")
            } else {
                volumes.append(volume)
            }
        }
        let tracer = ProbeRayTracer(items: prep.items, geometries: geometries, skinned: prep.skinnedMeshes)
        var validity: [[Bool]] = []
        for volume in volumes {
            var valid: [Bool] = []
            for p in 0..<volume.settings.probeCount {
                valid.append(!tracer.isInsideGeometry(volume.frame.toWorld(volume.settings.localPosition(of: p))))
            }
            let inside = valid.filter { !$0 }.count
            report.probesInsideGeometry += inside
            if inside == valid.count {
                report.warnings.append("IrradianceVolume '\(volume.name)': all \(inside) probes are inside geometry, so it has no probes to light with")
            } else if inside > 0 {
                report.warnings.append("IrradianceVolume '\(volume.name)': \(inside) of \(valid.count) probes are inside geometry (turned off)")
            }
            validity.append(valid)
        }
        for probe in reflections where tracer.isInsideGeometry(probe.frame.toWorld(probe.settings.captureOffset)) {
            report.warnings.append("ReflectionProbe '\(probe.name)' captures from inside geometry; move it (or its captureOffset) into open space")
        }
        report.reflectionProbes = reflections.count
        report.irradianceVolumes = volumes.count
        report.irradianceProbes = volumes.reduce(0) { $0 + $1.settings.probeCount }
        let bounces = volumes.map { min(max($0.settings.bounces, 1), 4) }.max() ?? 0
        report.bounces = bounces

        let layout = ProbeBufferLayout(reflections: reflections.map { .init(key: $0.key, probe: $0.settings, frame: $0.frame) },
                                       volumes: volumes.map { .init(key: $0.key, volume: $0.settings, frame: $0.frame) })
        let buffer: GPUBuffer
        do {
            buffer = try device.makeBuffer(layout.words(reflectionBakes: [], volumeBakes: [], validity: validity), usage: .storage)
        } catch {
            report.warnings.append("No memory for the probe buffer: \(error)")
            finish(report)
            return false
        }

        // Shadows covering every probe, whatever the camera sees.
        let light = state.frameLight ?? LightSetup(toLight: normalize(Vec3(0.5, 0.75, 0.35)), color: .zero, intensity: 0, bias: 0, shadows: nil)
        var corners: [Vec3] = []
        for r in reflections { corners += boxCorners(r.frame, r.settings.halfExtents) }
        for v in volumes { corners += boxCorners(v.frame, v.settings.halfExtents) }
        let bounds = Bounds(enclosing: corners)
        var bakeLights = punctualLights
        var shadows: ShadowSetup?
        if var sun = state.sun, light.intensity > 0 {
            let radius = max(length(bounds.halfExtent), 1)
            sun.shadowCenter = bounds.center
            sun.shadowExtent = radius
            sun.shadowDistance = max(sun.shadowDistance, radius * 2)
            let view = Mat4.lookAt(eye: bounds.center, target: bounds.center + Vec3(0, 0, -1))
            shadows = ShadowSetup.build(light: sun, toLight: light.toLight, focus: ShadowSetup.Focus(view: view, projection: nil, frustum: nil),
                                        lights: &bakeLights, items: prep.items, quality: quality, showCascades: false)
        } else if !punctualLights.isEmpty {
            let view = Mat4.lookAt(eye: bounds.center, target: bounds.center + Vec3(0, 0, -1))
            shadows = ShadowSetup.build(light: nil, toLight: light.toLight, focus: ShadowSetup.Focus(view: view, projection: nil, frustum: nil),
                                        lights: &bakeLights, items: prep.items, quality: quality, showCascades: false)
        }
        if let shadows {
            state.casters.build(items: prep.items, tiles: shadows.tiles.map(\.culling))
            renderShadowAtlas(shadows, frame: frame, casters: state.casters)
        }
        var bakeLight = light
        bakeLight.shadows = shadows
        var base = makeUniforms(viewProj: .identity, current: .identity, previous: .identity, eye: .zero, light: bakeLight,
                                environment: state.frameEnvironment)
        base.environment = environmentLighting.lighting
        base.reflectionParams = .zero
        base.reflectionExtra = Vec4(0, 0, 0, 1)  // encode c / (1 + c), no planar reflection

        // 2. Irradiance volumes, bounce by bounce.
        let store = state.storePipeline!
        if !volumes.isEmpty {
            base.probes = Vec4(0, Float(volumes.count), 0, 0)
            for bounce in 1...max(bounces, 1) {
                for (j, volume) in volumes.enumerated() where min(max(volume.settings.bounces, 1), 4) >= bounce {
                    for p in 0..<volume.settings.probeCount where validity[j][p] {
                        let eye = volume.frame.toWorld(volume.settings.localPosition(of: p))
                        let cell = volume.settings.halfExtents * 2 / Vec3(Float(volume.settings.counts.x), Float(volume.settings.counts.y),
                                                                            Float(volume.settings.counts.z))
                        captureFaces(into: state.irradianceFaces, eye: eye, rotation: volume.frame.rotation, near: 0.02,
                                     far: max(length(volume.settings.halfExtents) * 8, length(cell) * 4, 50), base: base, shadows: shadows,
                                     lights: bakeLights, buffer: buffer, frame: frame)
                        let image = state.irradianceImage!, sh = state.shTarget!
                        equirect(from: state.irradianceFaces, into: image, frame: frame)
                        frame.renderPass(into: sh, clearColor: .zero, label: "probe filter") { pass in
                            pass.setPipeline(state.shPipeline!)
                            pass.setTexture(image.texture, index: 1)
                            pass.setSampler(state.pointSampler, index: 1)
                            pass.setPushConstants(SIMD2(Int32(image.width), Int32(image.height)))
                            pass.draw(vertexCount: 3)
                        }
                        frame.computePass(label: "probe store") { pass in
                            pass.setPipeline(store)
                            pass.setTexture(sh.texture, index: 1)
                            pass.setSampler(state.pointSampler, index: 1)
                            pass.setStorageBuffer(buffer, offset: 0, index: 0)
                            pass.setPushConstants(ProbeStoreConstants(info: SIMD4(9, 1, Int32(layout.shWord(volume: j, probe: p)), 1),
                                                                      value: Vec4(1, 0, 0, 0)))
                            pass.dispatch(groups: ComputeSize(2, 1))
                        }
                    }
                }
            }
        }

        // 3. Reflection probes, lit by the finished volumes.
        base.probes = Vec4(0, Float(volumes.count), 0, 0)
        for (i, probe) in reflections.enumerated() {
            captureFaces(into: state.reflectionFaces, eye: probe.frame.toWorld(probe.settings.captureOffset), rotation: probe.frame.rotation,
                         near: probe.settings.nearClip, far: probe.settings.farClip, base: base, shadows: shadows, lights: bakeLights,
                         buffer: volumes.isEmpty ? state.emptyBuffer : buffer, frame: frame)
            equirect(from: state.reflectionFaces, into: state.levels[0], frame: frame)
            for level in 1..<state.levels.count {
                let source = state.levels[level - 1], target = state.levels[level]
                frame.renderPass(into: target, clearColor: .zero, label: "probe filter") { pass in
                    pass.setPipeline(state.prefilterPipeline!)
                    pass.setTexture(source.texture, index: 1)
                    pass.setSampler(state.pointSampler, index: 1)
                    pass.setPushConstants(PrefilterConstants(
                        sourceSize: SIMD2(Int32(source.width), Int32(source.height)), size: SIMD2(Float(target.width), Float(target.height)),
                        alpha: EnvironmentAtlas.incrementalAlpha(level: level), samples: Int32(EnvironmentLighting.prefilterSamples)))
                    pass.draw(vertexCount: 3)
                }
            }
            frame.computePass(label: "probe store") { pass in
                pass.setPipeline(store)
                pass.setSampler(state.pointSampler, index: 1)
                pass.setStorageBuffer(buffer, offset: 0, index: 0)
                for (level, target) in state.levels.enumerated() {
                    let l = ReflectionProbeImage.levels[level]
                    pass.setTexture(target.texture, index: 1)
                    pass.setPushConstants(ProbeStoreConstants(
                        info: SIMD4(Int32(l.width), Int32(l.height), Int32(layout.imageFirstWord[i] + l.offset * 2), 0), value: .zero))
                    pass.dispatch(groups: ComputeSize((l.width + 7) / 8, (l.height + 7) / 8))
                }
            }
        }

        // Draw with it now; read it back for the bakes and the cache.
        state.layout = layout
        state.buffer = buffer
        state.pending = (state.world, layout, buffer)
        state.baking += 1
        let cache = probeBakeCache
        frame.readBack(buffer) { [weak self] bytes in
            guard let self else { return }
            let state = self.probes
            state.baking -= 1
            let words: [UInt32] = bytes.withUnsafeBytes { raw in
                (0..<(raw.count / 4)).map { UInt32(littleEndian: raw.loadUnaligned(fromByteOffset: $0 * 4, as: UInt32.self)) }
            }
            var report = report
            if words.count >= layout.wordCount {
                for (i, r) in layout.reflections.enumerated() {
                    let first = layout.imageFirstWord[i]
                    let bake = ReflectionProbeBake(key: r.key, words: Array(words[first..<first + ReflectionProbeImage.wordCount]))
                    state.reflectionBakes[r.key] = bake
                    if let file = cache?.store(bake) { report.cacheFiles.append(file) }
                }
                for (j, v) in layout.volumes.enumerated() {
                    let coefficients = (0..<v.volume.probeCount).flatMap { p in
                        ProbeBufferLayout.unpackSH(words[layout.shWord(volume: j, probe: p)..<layout.shWord(volume: j, probe: p) + 16])
                    }
                    let bake = IrradianceVolumeBake(key: v.key, counts: v.volume.counts, coefficients: coefficients)
                    state.volumeBakes[v.key] = bake
                    if let file = cache?.store(bake) { report.cacheFiles.append(file) }
                }
            } else {
                report.warnings.append("The bake couldn't be read back (\(words.count) of \(layout.wordCount) words)")
            }
            report.milliseconds = (Self.seconds(since: start) * 1000 * 10).rounded() / 10
            // The new bakes go through the usual path from the next frame.
            if state.pending?.buffer === buffer { state.pending = nil }
            for request in due { request.completion?(report) }
        }
        return true
    }

    private func boxCorners(_ frame: LightProbeFrame, _ half: Vec3) -> [Vec3] {
        (0..<8).map { c in frame.toWorld(Vec3(c & 1 == 0 ? -half.x : half.x, c & 2 == 0 ? -half.y : half.y, c & 4 == 0 ? -half.z : half.z)) }
    }

    private func makeBakeResources() throws {
        let state = probes
        guard state.storePipeline == nil else { return }
        func fullscreen(_ fragment: String) throws -> RenderPipeline {
            var descriptor = PipelineDescriptor(
                shader: try ShaderSource.load(vertex: "post", fragment: fragment, bundle: .engineResources), vertexLayout: .none)
            descriptor.target = .color(.rgba16Float)
            descriptor.cullMode = .none
            descriptor.depthTest = false
            descriptor.depthWrite = false
            return try device.makePipeline(descriptor)
        }
        func color(_ width: Int, _ height: Int) throws -> GPURenderTarget {
            try device.makeRenderTarget(.color(width: width, height: height, format: .rgba16Float))
        }
        state.equirectPipeline = try fullscreen("probe_equirect")
        state.prefilterPipeline = try fullscreen("env_prefilter")
        state.shPipeline = try fullscreen("env_sh")
        state.reflectionFaces = try (0..<6).map { _ in
            try RenderTarget(device: device, width: ReflectionProbeImage.faceSize, height: ReflectionProbeImage.faceSize, multisampled: false,
                             label: "probe capture")
        }
        state.irradianceFaces = try (0..<6).map { _ in
            try RenderTarget(device: device, width: IrradianceProbeCapture.faceSize, height: IrradianceProbeCapture.faceSize,
                             multisampled: false, label: "probe capture")
        }
        state.levels = try ReflectionProbeImage.levels.map { try color($0.width, $0.height) }
        state.irradianceImage = try color(IrradianceProbeCapture.equirect.width, IrradianceProbeCapture.equirect.height)
        state.shTarget = try color(9, 1)
        state.storePipeline = try device.makeComputePipeline(shader: ShaderSource.load(compute: "probe_store", bundle: .engineResources))
    }

    /// Draws the gathered world from `eye` into the six faces (meshes and the sky, c / (1 + c)),
    /// the probes in `buffer` lighting it as `base.probes` says.
    private func captureFaces(into faces: [RenderTarget], eye: Vec3, rotation: Quat, near: Float, far: Float, base: FrameUniforms,
                              shadows: ShadowSetup?, lights: [PunctualLight], buffer: GPUBuffer, frame: Frame) {
        let state = probes
        let projection = LightProbeMath.faceProjection(near: near, far: far)
        let clear = state.clearColor
        let encodedClear = Vec4(clear.x / (1 + clear.x), clear.y / (1 + clear.y), clear.z / (1 + clear.z), 0)
        let savedBuffer = state.buffer
        state.buffer = buffer
        defer { state.buffer = savedBuffer }
        for (face, target) in faces.enumerated() {
            let view = LightProbeMath.faceView(face: face, eye: eye, rotation: rotation)
            let viewProjection = projection * view
            state.list.build(items: prep.items, view: Frustum(viewProjection: viewProjection), cameraPosition: eye, shadows: nil)
            let instances = state.list.instances.isEmpty ? nil : frame.upload(state.list.instances)
            var uniforms = base
            uniforms.viewProj = viewProjection
            uniforms.currentViewProj = viewProjection
            uniforms.previousViewProj = viewProjection
            uniforms.cameraPos = Vec4(eye, base.cameraPos.w)
            uniforms.viewDepth = .zero
            uniforms.clusterScale = .zero
            uniforms.clusterGrid = .zero
            state.clusters.build(lights: lights, view: view, projection: projection)
            state.clusters.write(to: &state.lightData)
            uniforms.setClusters(state.clusters, view: view, size: (target.width, target.height))
            if let shadows { uniforms.shadows = shadows.uniforms(for: state.clusters) }
            let clustered = state.clusters.isEmpty ? nil : state.lightData
            frame.renderPass(into: target, clearColor: encodedClear, clearDepth: 1) { pass in
                draw(pass, list: state.list, uniforms: uniforms, instances: instances, reversedZ: false, lights: clustered,
                     sky: (view, projection), particleDepth: nil, drawsParticles: false, encodesSky: true)
            }
        }
    }

    /// The six faces as one equirectangular image in `target`.
    private func equirect(from faces: [RenderTarget], into target: GPURenderTarget, frame: Frame) {
        let state = probes
        frame.renderPass(into: target, clearColor: .zero, label: "probe filter") { pass in
            pass.setPipeline(state.equirectPipeline!)
            for (index, face) in faces.enumerated() { pass.setTexture(face.texture, index: index + 1) }
            pass.setSampler(state.pointSampler, index: 1)
            pass.setPushConstants(ProbeEquirectConstants(size: SIMD2(Int32(target.width), Int32(target.height)), faceSize: Int32(faces[0].width)))
            pass.draw(vertexCount: 3)
        }
    }
}

/// Must match the push constants of probe_equirect.frag.
struct ProbeEquirectConstants {
    var size: SIMD2<Int32>
    var faceSize: Int32
}

/// Must match the push constants of probe_store.comp.
struct ProbeStoreConstants {
    var info: SIMD4<Int32>
    var value: Vec4
}

/// CPU rays against the gathered meshes, to find probes inside geometry: a probe is inside when
/// more than a quarter of the rays that hit something hit a back face first.
struct ProbeRayTracer {
    struct Item {
        var bounds: Bounds
        var inverse: Mat4
        var mesh: Int
    }

    var items: [Item] = []
    var geometries: [MeshGeometry]
    static let rays = LightProbeMath.sphereDirections(48)

    init(items: [RenderItem], geometries: [MeshGeometry], skinned: [Int: SkinnedMeshInfo]) {
        self.geometries = geometries
        for item in items where !item.transparent && skinned[item.mesh] == nil && item.mesh < geometries.count {
            self.items.append(Item(bounds: item.bounds, inverse: item.instance.model.inverse, mesh: item.mesh))
        }
    }

    init(geometry: MeshGeometry, models: [Mat4]) {
        geometries = [geometry]
        for model in models {
            let corners = geometry.vertices.map { v -> Vec3 in
                let p = model * Vec4(v.position, 1)
                return Vec3(p.x, p.y, p.z)
            }
            items.append(Item(bounds: Bounds(enclosing: corners), inverse: model.inverse, mesh: 0))
        }
    }

    func isInsideGeometry(_ point: Vec3) -> Bool {
        var hits = 0, backfaces = 0
        for direction in Self.rays {
            guard let back = firstHit(from: point, direction: direction) else { continue }
            hits += 1
            if back { backfaces += 1 }
        }
        return hits > 0 && backfaces * 4 > Self.rays.count
    }

    /// Whether the nearest surface along the ray is seen from behind; nil if it hits nothing.
    func firstHit(from origin: Vec3, direction: Vec3) -> Bool? {
        var nearest = Float.infinity
        var back = false
        for item in items {
            guard let enter = Self.slab(origin, direction, item.bounds), enter < nearest else { continue }
            let o4 = item.inverse * Vec4(origin, 1), d4 = item.inverse * Vec4(direction, 0)
            let o = Vec3(o4.x, o4.y, o4.z), d = Vec3(d4.x, d4.y, d4.z)
            let g = geometries[item.mesh]
            var i = 0
            while i + 2 < g.indices.count {
                let a = g.vertices[Int(g.indices[i])], b = g.vertices[Int(g.indices[i + 1])], c = g.vertices[Int(g.indices[i + 2])]
                i += 3
                let e1 = b.position - a.position, e2 = c.position - a.position
                let pv = cross(d, e2)
                let det = dot(e1, pv)
                guard abs(det) > 1e-12 else { continue }
                let inv = 1 / det
                let tv = o - a.position
                let u = dot(tv, pv) * inv
                guard u >= 0, u <= 1 else { continue }
                let qv = cross(tv, e1)
                let v = dot(d, qv) * inv
                guard v >= 0, u + v <= 1 else { continue }
                let t = dot(e2, qv) * inv
                guard t > 1e-4, t < nearest else { continue }
                nearest = t
                var n = a.normal + b.normal + c.normal
                if dot(n, n) < 1e-12 { n = cross(e1, e2) }
                back = dot(n, d) > 0
            }
        }
        return nearest.isFinite ? back : nil
    }

    /// Where the ray enters `box` (0 when it starts inside), or nil if it misses.
    static func slab(_ o: Vec3, _ d: Vec3, _ box: Bounds) -> Float? {
        var lo: Float = 0, hi = Float.infinity
        for axis in 0..<3 {
            let minV = box.center[axis] - box.halfExtent[axis] - 1e-4, maxV = box.center[axis] + box.halfExtent[axis] + 1e-4
            if abs(d[axis]) < 1e-12 {
                if o[axis] < minV || o[axis] > maxV { return nil }
                continue
            }
            var t0 = (minV - o[axis]) / d[axis], t1 = (maxV - o[axis]) / d[axis]
            if t0 > t1 { swap(&t0, &t1) }
            lo = max(lo, t0)
            hi = min(hi, t1)
            if lo > hi { return nil }
        }
        return lo
    }
}
