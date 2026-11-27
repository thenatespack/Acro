/// Fur (Groom.swift): `syncGroomMeshes` builds each `GroomRenderer`'s fur meshes from its entity's
/// mesh on a background job the first time the pair is drawn (and again when the groom's geometry
/// changes), swapping them in once built, and fur materials draw with mesh_fur(_skinned / _sim).vert and mesh_fur.frag, their uniform buffer 2 the fur
/// block (fur.glsl). Fur casters (a few shells, or the cards; `RenderPrep.appendFur`) draw into the
/// shadow atlas with mesh_fur_depth(_skinned).vert and mesh_fur_depth.frag, cut to their strands;
/// fur is left out of the depth prepass. Shells and fins are alpha blended in the transparent pass
/// (their coverage is filtered, fur_strands.glsl); cards use hashed alpha. Simulated hair: SceneRenderer+HairSim.swift.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

extension SceneRenderer {
    /// What `syncGroomMeshes` built for one base mesh and fur material.
    struct FurMeshes {
        var tag: String
        var keys: [String]
        /// The hair's simulation rig (cards).
        var rig: HairRig?
    }

    /// The fur meshes of one (material, mesh) pair, built by a background job.
    final class FurBuild: @unchecked Sendable {
        struct Result {
            var meshes: [(key: String, geometry: MeshGeometry)]
            var rig: HairRig?
            var seconds: Double
        }

        let tag: String
        private let lock = NSLock()
        private var result: Result?
        private(set) var job: JobHandle?

        init(tag: String, base: String, geometry: MeshGeometry, fur: MaterialFur, jobs: JobSystem) {
            self.tag = tag
            job = jobs.schedule("fur meshes", priority: .background) { [self] in
                let built = Self.build(base: base, geometry: geometry, fur: fur)
                lock.withLock { result = built }
            }
        }

        /// The shell mesh, the fins (shells) or the card levels (cards) and the hair's rig.
        static func build(base: String, geometry: MeshGeometry, fur: MaterialFur) -> Result {
            let start = ContinuousClock.now
            var meshes: [(String, MeshGeometry)] = []
            var rig: HairRig?
            let shells = GroomGeometry.shells(geometry, fur: fur)
            if let shells { meshes.append((GroomRenderer.meshKey("shell", tag: fur.tag, base: base), shells)) }
            if fur.groom.drawnStyle == .shell, let shells, let fins = GroomFins.fins(shells, spacing: fur.groom.strandSpacing) {
                meshes.append((GroomRenderer.meshKey("fins", tag: fur.tag, base: base), fins))
            }
            if fur.groom.drawnStyle == .cards {
                let guides = GroomGeometry.guides(geometry, fur: fur).guides
                for (level, fraction) in fur.groom.cardLevels.enumerated() {
                    if let cards = GroomGeometry.cards(guides: guides, fur: fur, fraction: fraction, skinned: geometry.skin != nil) {
                        meshes.append((GroomRenderer.meshKey("cards\(level)", tag: fur.tag, base: base), cards))
                    }
                }
                if !guides.isEmpty { rig = HairRig(guides: guides, fur: fur, base: geometry) }
            }
            let d = ContinuousClock.now - start
            return Result(meshes: meshes, rig: rig, seconds: Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18)
        }

        /// The meshes, once built.
        var built: Result? { lock.withLock { result } }
    }

    /// Builds the fur meshes the world's `GroomRenderer`s need (see the notes at the top of
    /// Groom.swift) on background jobs, resolving their fur materials and base meshes first, and
    /// registers them once built (the frame after, at the earliest; at once with
    /// `blocksOnAssetLoading` or without `buildsFurInBackground`). Until then a new groom draws
    /// nothing and an edited one keeps its old meshes (`RenderPrep.furTags`).
    func syncGroomMeshes(_ world: World) {
        guard world.existingStore(GroomRenderer.self) != nil else { return }
        var wanted: [(base: String, material: String)] = []
        var seen: Set<String> = []
        world.query(GroomRenderer.self, MeshRenderer.self) { _, groom, renderer in
            guard groom.isVisible, renderer.isVisible, !groom.groom.key.isEmpty else { return }
            let pair = groom.groom.key + "|" + renderer.mesh.key
            if seen.insert(pair).inserted { wanted.append((renderer.mesh.key, groom.groom.key)) }
        }
        for (base, materialKey) in wanted {
            guard let material = material(MaterialHandle(materialKey)), let fur = material.fur else { continue }
            let pair = materialKey + "|" + base
            if furMeshes[pair]?.tag == fur.tag { continue }
            if furBuilds[pair]?.tag != fur.tag {
                guard let geometry = geometry(MeshHandle(base)), !geometry.indices.isEmpty else { continue }
                if buildsFurInBackground && !blocksOnAssetLoading {
                    furBuilds[pair] = FurBuild(tag: fur.tag, base: base, geometry: geometry, fur: fur, jobs: prep.jobs)
                } else {
                    registerFur(FurBuild.build(base: base, geometry: geometry, fur: fur), pair: pair, tag: fur.tag)
                    continue
                }
            }
            guard let build = furBuilds[pair] else { continue }
            if blocksOnAssetLoading, let job = build.job { prep.jobs.wait(job) }
            guard let result = build.built else { continue }
            furBuilds[pair] = nil
            registerFur(result, pair: pair, tag: fur.tag)
        }
    }

    /// Swaps in the fur meshes built for `pair`.
    private func registerFur(_ result: FurBuild.Result, pair: String, tag: String) {
        for key in furMeshes[pair]?.keys ?? [] { unregisterMesh(key: key) }
        var keys: [String] = []
        for (key, made) in result.meshes {
            do {
                try registerMesh(made, key: key)
                keys.append(key)
            } catch {
                print("SceneRenderer: fur mesh '\(key)' failed: \(error)")
            }
        }
        furMeshes[pair] = FurMeshes(tag: tag, keys: keys, rig: result.rig)
        prep.furTags[pair] = tag
        furBuildSeconds = result.seconds
    }

    /// Vec4s of the fur block before the skin (fur.glsl): the material (8) and the groom (8).
    static let furBlockVec4s = 16

    /// The fur block of `material` (fur.glsl): its uniforms, the groom's numbers and this frame's
    /// wind and clock, then for a skinned batch (`skin` >= 0) the springs and joint matrices.
    func furBlock(_ material: Material, skin: Int, into block: inout [Vec4]) {
        guard let fur = material.fur else { return }
        let g = fur.groom
        let skinned = skin >= 0
        let count = Self.furBlockVec4s + (skinned ? SkinPose.maxJoints * 7 : 0)
        if block.count != count { block = Array(repeating: .zero, count: count) }
        let uniforms = MaterialUniforms(material)
        func clamp01(_ x: Float) -> Float { x.isFinite ? min(max(x, 0), 1) : 0 }
        let bendable = 1 - clamp01(g.stiffness) * 0.8
        let wind = windState.wind
        let dir = wind.horizontalDirection
        let root = g.linearRootColor, tip = g.linearTipColor
        let windScale = g.wind.isFinite ? min(max(g.wind, 0), 10) : 0
        block.withUnsafeMutableBufferPointer { out in
            for i in 0..<8 { out[i] = .zero }
            withUnsafeBytes(of: uniforms) { UnsafeMutableRawBufferPointer(out).copyMemory(from: $0) }
            out[8] = Vec4(g.clampedLength, g.strandSpacing, clamp01(g.thickness.x), clamp01(g.thickness.y))
            out[9] = Vec4(clamp01(g.clumping), clamp01(g.curl), clamp01(g.frizz), clamp01(g.gravity) * bendable * 1.2)
            out[10] = Vec4(bendable, clamp01(g.lengthVariation), clamp01(g.colorNoise), clamp01(g.specular))
            out[11] = Vec4(root, g.drawnStyle == .cards ? 1 : 0)
            out[12] = Vec4(tip, Float(min(max(g.strandsPerCard, 1), 32)))
            out[13] = Vec4(dir.x, dir.y, wind.effectiveStrength * windScale, wind.effectiveGustiness)
            out[14] = Vec4(windState.time, windState.previousTime, material.metallicRoughnessTexture != nil ? 1 : 0, g.mask.invert ? 1 : 0)
            out[15] = Vec4(Float(device.sampleCount), Float(prep.furFrame % 64), 0, 0)
            guard skinned else { return }
            let springs = prep.furSkinSprings[skin] ?? []
            let pose = skin < prep.skins.count ? prep.skins[skin] : nil
            let maxJoints = SkinPose.maxJoints
            for j in 0..<maxJoints { out[16 + j] = j < springs.count ? springs[j] : .zero }
            func write(_ joints: [Mat4]?, at base: Int) {
                for j in 0..<maxJoints {
                    let m = joints.flatMap { j < $0.count ? $0[j] : nil } ?? .identity
                    out[base + j * 3] = Vec4(m.c0.x, m.c1.x, m.c2.x, m.c3.x)
                    out[base + j * 3 + 1] = Vec4(m.c0.y, m.c1.y, m.c2.y, m.c3.y)
                    out[base + j * 3 + 2] = Vec4(m.c0.z, m.c1.z, m.c2.z, m.c3.z)
                }
            }
            write(pose?.joints, at: 16 + maxJoints)
            write(pose?.previousJoints, at: 16 + maxJoints * 4)
        }
    }

    /// Binds `material`'s fur block (buffer 2, both stages).
    func bindFur(_ material: Material, skin: Int, in pass: RenderPass) {
        furBlock(material, skin: skin, into: &furBlockScratch)
        furBlockScratch.withUnsafeBytes { pass.setUniformData($0, index: 2, stage: .all) }
    }

    /// The fur shader: mesh_fur(_skinned / _sim).vert with mesh_fur.frag.
    func furShader(skinned: Bool, simulated: Bool = false) -> ShaderSource? {
        let vertex = skinned ? "mesh_fur_skinned" : simulated ? "mesh_fur_sim" : "mesh_fur"
        if let shader = furShaders[vertex] { return shader }
        do {
            let shader = try ShaderSource.load(vertex: vertex, fragment: "mesh_fur", bundle: .engineResources)
            furShaders[vertex] = shader
            return shader
        } catch {
            print("SceneRenderer: fur shader unavailable: \(error)")
            return nil
        }
    }

    /// What a fur depth pipeline is made for.
    struct FurDepthKey: Hashable {
        var variant: DepthVariant
        var skinned: Bool
    }

    /// The depth pipeline of fur casters: their strands (mesh_fur_depth), cut out of the shells or
    /// cards, with the shadow atlas's depth bias.
    func furDepthPipeline(_ variant: DepthVariant, skinned: Bool) -> RenderPipeline? {
        let key = FurDepthKey(variant: variant, skinned: skinned)
        if let pipeline = furDepthPipelines[key] { return pipeline }
        do {
            let shader = try ShaderSource.load(vertex: skinned ? "mesh_fur_depth_skinned" : "mesh_fur_depth", fragment: "mesh_fur_depth",
                                               bundle: .engineResources)
            var descriptor = PipelineDescriptor(shader: shader, vertexLayout: skinned ? SkinnedMeshVertex.layout : MeshVertex.layout,
                                                instanceLayout: MeshInstance.layout)
            descriptor.target = .depthOnly
            descriptor.depthOnlyFragment = true
            descriptor.cullMode = .none
            switch variant {
            case .shadow: descriptor.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
            case .prepass(let reversedZ): descriptor.depthCompare = reversedZ ? .greater : .less
            }
            let pipeline = try device.makePipeline(descriptor)
            furDepthPipelines[key] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: fur depth pipeline creation failed: \(error)")
            return nil
        }
    }
}
