import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineText

/// `SceneRenderer`'s decal hook. `gather` collects the world's `Decal`s (sorted by
/// `sortOrder`); each view draws the ones in its frustum in the scene pass between the opaque
/// meshes and the sky / transparent meshes, so only opaque geometry is painted.
///
/// A decal is its projector box drawn from the inside (front faces culled, no depth test), and
/// decal.frag does the projecting: it reads the opaque scene's depth at its pixel from the
/// depth prepass (the same texture soft particles use, rendered whenever a decal is visible),
/// rebuilds the world position and a normal from neighboring depth texels, maps the position
/// into the box (outside it the pixel is discarded), samples the texture with gradients from
/// the neighbors, lights it (PBR, metallic 0) and alpha-blends it into the color target. Motion
/// vectors are left alone. Without decals nothing here runs or is created.
///
/// A decal whose `material` is a material graph draws with that graph's decal variant instead
/// (decal_graph.frag with the graph's code, `MaterialGraphProgram.metalDecalFragment`): the
/// graph's values in storage buffer 0, its textures in slots 1-5 with its sampler, the depth
/// prepass in slot 7 (the BRDF table's, so the scene pass's environment bindings are restored
/// after the decals).
@MainActor
final class DecalRenderer {
    struct Item {
        var decal: Decal
        var model: Mat4
        var sortKey: Int64
    }

    /// Must match `DecalData` in decal.frag / decal.vert (uniform buffer 2, std140).
    struct Uniforms: BitwiseCopyable {
        var model: Mat4
        var inverseModel: Mat4
        var inverseViewProj: Mat4
        /// rgb: tint, a: opacity
        var color: Vec4
        /// x: emissive, y: roughness, z: angle fade, w: 1 with a texture
        var params: Vec4
        /// xyz: unit world direction the decal projects along
        var axis: Vec4
    }

    /// A decal's material graph (`SceneRenderer.decalGraph`).
    struct Graph {
        var program: MaterialGraphProgram
        var values: GPUBuffer
        var sampler: GPUSampler
        /// Slots 1-5 (nil: white).
        var textures: [GPUTexture?]
    }

    private struct GraphPipelineKey: Hashable {
        var reversedZ: Bool
        var graph: String
    }

    private let device: RenderDevice
    private var shader: ShaderSource?
    private var pipelines: [Bool: RenderPipeline] = [:]
    private var graphPipelines: [GraphPipelineKey: RenderPipeline] = [:]
    private let sampler: GPUSampler
    private let whiteTexture: GPUTexture
    /// This frame's visible decals, in drawing order.
    private(set) var items: [Item] = []

    init(device: RenderDevice) throws {
        self.device = device
        sampler = try device.makeSampler(SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear,
                                                           addressMode: .clampToEdge))
        whiteTexture = try device.makeTexture(pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm)
    }

    func gather(world: World) {
        items.removeAll(keepingCapacity: true)
        world.query(Decal.self, GlobalTransform.self) { entity, decal, transform in
            let m = transform.matrix
            guard decal.isVisible, decal.opacity > 0,
                  (m.c0 * m.c0).sum() > 1e-12, (m.c1 * m.c1).sum() > 1e-12, (m.c2 * m.c2).sum() > 1e-12 else { return }
            items.append(Item(decal: decal, model: m, sortKey: Int64(decal.sortOrder) << 32 | Int64(entity.index)))
        }
        items.sort { $0.sortKey < $1.sortKey }
    }

    /// What `draw` replaced in the pass.
    struct Drawn: OptionSet {
        let rawValue: Int
        /// The pipeline, uniform buffer 2, textures 1-5 and sampler 1.
        static let bindings = Drawn(rawValue: 1)
        /// Texture 7 (a graph decal's depth slot), storage buffer 0 and the push constants.
        static let graph = Drawn(rawValue: 2)
    }

    /// Draws the decals that touch `viewProjection`'s frustum, painting what `depth` (the view's
    /// depth prepass) holds. Returns what it replaced in the pass's bindings.
    func draw(in pass: RenderPass, viewProjection: Mat4, reversedZ: Bool, depth: ParticleSceneDepth, time: Float,
              texture: (TextureHandle) -> GPUTexture?, graph: (MaterialHandle) -> Graph?) -> Drawn {
        guard !items.isEmpty else { return [] }
        let frustum = Frustum(viewProjection: viewProjection)
        let inverseViewProj = depth.viewProjection.inverse
        var drawn: Drawn = []
        var current: String?  // the bound pipeline: "" the plain one, else the graph's key
        for item in items {
            let (center, halfExtent) = Decal.bounds(of: item.model)
            guard frustum.intersects(center: center, halfExtent: halfExtent) else { continue }
            let decal = item.decal
            let material = decal.material.flatMap(graph)
            let key = material?.program.key ?? ""
            if key != current {
                guard let pipeline = material.map({ graphPipeline(GraphPipelineKey(reversedZ: reversedZ, graph: $0.program.key), $0.program) })
                        ?? pipeline(reversedZ: reversedZ) else { continue }
                pass.setPipeline(pipeline)
                if material == nil {
                    pass.setSampler(sampler, index: 1)
                    pass.setTexture(depth.texture, index: 2)
                } else {
                    pass.setTexture(depth.texture, index: 7)
                }
                current = key
                drawn.insert(.bindings)
            }
            let axis = -Vec3(item.model.c2.x, item.model.c2.y, item.model.c2.z)
            if let material {
                drawn.insert(.graph)
                let uniforms = Uniforms(
                    model: item.model, inverseModel: item.model.inverse, inverseViewProj: inverseViewProj,
                    color: Vec4(decal.tint, min(max(decal.opacity, 0), 1)),
                    params: Vec4(max(decal.emissive, 0), min(max(decal.roughness, 0.045), 1), max(decal.angleFade, 0), 0),
                    axis: Vec4(normalize(axis), 0))
                pass.setUniformData(uniforms, index: 2, stage: .all)
                pass.setStorageBuffer(material.values, index: 0, stage: .fragment)
                pass.setPushConstants(GraphPush(params: Vec4(time, 0, 0, 0), eye: .zero))
                for slot in 0..<5 {
                    pass.setTexture((slot < material.textures.count ? material.textures[slot] : nil) ?? whiteTexture, index: slot + 1)
                }
                pass.setSampler(material.sampler, index: 1)
                pass.draw(vertexCount: 36)
                continue
            }
            let resolved = decal.texture.flatMap { texture($0) }
            let uniforms = Uniforms(
                model: item.model, inverseModel: item.model.inverse, inverseViewProj: inverseViewProj,
                color: Vec4(decal.tint, min(max(decal.opacity, 0), 1)),
                params: Vec4(max(decal.emissive, 0), min(max(decal.roughness, 0.045), 1), max(decal.angleFade, 0),
                             resolved != nil ? 1 : 0),
                axis: Vec4(normalize(axis), 0))
            pass.setUniformData(uniforms, index: 2, stage: .all)
            pass.setTexture(resolved ?? whiteTexture, index: 1)
            pass.draw(vertexCount: 36)
        }
        return drawn
    }

    /// decal_graph.frag's push constants (material_graph.glsl's `MaterialGraphPush`).
    private struct GraphPush: BitwiseCopyable {
        var params: Vec4
        var eye: Vec4
    }

    private func pipeline(reversedZ: Bool) -> RenderPipeline? {
        if let pipeline = pipelines[reversedZ] { return pipeline }
        do {
            if shader == nil { shader = try ShaderSource.load(vertex: "decal", fragment: "decal", bundle: .engineResources) }
            let pipeline = try device.makePipeline(Self.descriptor(shader!))
            pipelines[reversedZ] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: decal pipeline creation failed: \(error)")
            return nil
        }
    }

    private func graphPipeline(_ key: GraphPipelineKey, _ program: MaterialGraphProgram) -> RenderPipeline? {
        if let pipeline = graphPipelines[key] { return pipeline }
        guard let metal = program.metalDecalFragment, let spirv = program.spirvDecalFragment else { return nil }
        do {
            var shader = try ShaderSource.load(vertex: "decal", fragment: "decal_graph", bundle: .engineResources)
            shader.metalFragmentSource = metal
            shader.metalFragmentColor0Source = nil
            shader.spirvFragment = spirv
            let pipeline = try device.makePipeline(Self.descriptor(shader))
            if graphPipelines.count >= 64 { graphPipelines.removeAll() }
            graphPipelines[key] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: material graph decal pipeline creation failed: \(error)")
            return nil
        }
    }

    private static func descriptor(_ shader: ShaderSource) -> PipelineDescriptor {
        var descriptor = PipelineDescriptor(shader: shader, vertexLayout: .none)
        // Back faces only, so the camera can be inside the box; the shader clips to it.
        descriptor.cullMode = .front
        descriptor.depthTest = false
        descriptor.depthWrite = false
        descriptor.blendMode = .alpha
        return descriptor
    }
}

extension SceneRenderer {
    /// Creates `decals` on the first `Decal` and gathers this frame's.
    func gatherDecals(world: World) {
        if decals == nil {
            guard world.count(of: Decal.self) > 0 else { return }
            do {
                decals = try DecalRenderer(device: device)
            } catch {
                print("SceneRenderer: decals unavailable: \(error)")
                return
            }
        }
        decals?.gather(world: world)
        // Upload the material graphs decals paint with (asset materials load in the background).
        for item in decals?.items ?? [] {
            if let key = item.decal.material?.key, !key.isEmpty { resolveAsset(key, kind: .material) }
        }
    }

    /// Some decal is visible this frame: the depth prepass must run.
    var needsDecalDepth: Bool { decals?.items.isEmpty == false }

    /// Draws the decals into `pass` (after the opaque meshes). True if it bound its own pipeline.
    func drawDecals(in pass: RenderPass, uniforms: FrameUniforms, reversedZ: Bool, depth: ParticleSceneDepth?) -> Bool {
        guard let decals, let depth else { return false }
        let drawn = decals.draw(in: pass, viewProjection: uniforms.viewProj, reversedZ: reversedZ, depth: depth, time: graphTime,
                                texture: { [unowned self] in texture($0) }, graph: { [unowned self] in decalGraph($0.key) })
        // A graph decal put the depth prepass in the BRDF table's slot.
        if drawn.contains(.graph) { rebindEnvironmentLighting(in: pass) }
        return drawn.contains(.bindings)
    }
}
