/// Fur (Groom.swift): `syncGroomMeshes` builds each `GroomRenderer`'s fur meshes from its entity's
/// mesh the first time the pair is drawn (and again when the groom's geometry changes), and fur
/// materials draw with mesh_fur(_skinned).vert and mesh_fur.frag, their uniform buffer 2 the fur
/// block (fur.glsl). Fur items never cast shadows and are left out of the depth prepass.
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

extension SceneRenderer {
    /// What `syncGroomMeshes` built for one base mesh and fur material.
    struct FurMeshes {
        var tag: String
        var keys: [String]
    }

    /// Builds the fur meshes the world's `GroomRenderer`s need (see the notes at the top of
    /// Groom.swift), resolving their fur materials and base meshes first.
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
            guard let geometry = geometry(MeshHandle(base)), !geometry.indices.isEmpty else { continue }
            for key in furMeshes[pair]?.keys ?? [] { unregisterMesh(key: key) }
            var keys: [String] = []
            func register(_ made: MeshGeometry?, _ key: String) {
                guard let made else { return }
                do {
                    try registerMesh(made, key: key)
                    keys.append(key)
                } catch {
                    print("SceneRenderer: fur mesh '\(key)' failed: \(error)")
                }
            }
            register(GroomGeometry.shells(geometry, fur: fur), GroomRenderer.meshKey("shell", tag: fur.tag, base: base))
            if fur.groom.drawnStyle == .cards {
                let guides = GroomGeometry.guides(geometry, fur: fur).guides
                for (level, fraction) in fur.groom.cardLevels.enumerated() {
                    register(GroomGeometry.cards(guides: guides, fur: fur, fraction: fraction, skinned: geometry.skin != nil),
                             GroomRenderer.meshKey("cards\(level)", tag: fur.tag, base: base))
                }
            }
            furMeshes[pair] = FurMeshes(tag: fur.tag, keys: keys)
        }
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
            out[15] = .zero
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

    /// The fur shader: mesh_fur(_skinned).vert with mesh_fur.frag.
    func furShader(skinned: Bool) -> ShaderSource? {
        if let shader = furShaders[skinned] { return shader }
        do {
            let shader = try ShaderSource.load(vertex: skinned ? "mesh_fur_skinned" : "mesh_fur", fragment: "mesh_fur", bundle: .engineResources)
            furShaders[skinned] = shader
            return shader
        } catch {
            print("SceneRenderer: fur shader unavailable: \(error)")
            return nil
        }
    }
}
