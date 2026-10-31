import Foundation

/// The mesh and material handles an `ImportedModel`'s primitives draw with, e.g. from
/// `ImportedModel.register(with:keyPrefix:textures:)` or an asset database.
public struct ModelHandles: Sendable {
    /// `meshes[m][p]` draws primitive `p` of mesh `m`; nil leaves that primitive out.
    public var meshes: [[MeshHandle?]]
    /// One per material of the model.
    public var materials: [MaterialHandle]
    /// For primitives without a material.
    public var defaultMaterial: MaterialHandle

    public init(meshes: [[MeshHandle?]], materials: [MaterialHandle], defaultMaterial: MaterialHandle = .default) {
        self.meshes = meshes
        self.materials = materials
        self.defaultMaterial = defaultMaterial
    }
}

/// The entities `ImportedModel.instantiate` spawned.
public struct InstantiatedModel {
    /// One entity per root node of the scene, in order.
    public var roots: [Entity]
    /// The entity of each node that was instantiated, by node index.
    public var nodes: [Int: Entity]
    /// Every entity with a `MeshRenderer`: a node's own entity for single-primitive meshes, a
    /// child per primitive for meshes with several.
    public var renderers: [Entity]
}

@MainActor
extension ImportedModel {
    /// Spawns the selected scene's node tree into `world`, under `parent` if given.
    ///
    /// Every node becomes an entity with a `Transform` (its local TRS), a `Name` (the node's
    /// name, or "Node <i>") and the same parent-child structure. A node whose mesh has one
    /// primitive gets the `MeshRenderer` itself; for a mesh with several primitives, each one
    /// becomes a child entity named "<mesh> [<i>]" with an identity `Transform` and its own
    /// `MeshRenderer`, because a `MeshRenderer` draws one mesh with one material.
    ///
    /// `mesh(meshIndex, primitiveIndex)` and `material(materialIndex)` supply the handles
    /// (`material(nil)` for primitives without a material); a nil mesh handle skips the primitive.
    @discardableResult
    public func instantiate(in world: World, under parent: Entity? = nil,
                            mesh: (_ mesh: Int, _ primitive: Int) -> MeshHandle?,
                            material: (_ material: Int?) -> MaterialHandle) -> InstantiatedModel {
        var result = InstantiatedModel(roots: [], nodes: [:], renderers: [])
        // Depth first with an explicit stack, children in file order.
        var stack: [(node: Int, parent: Entity?)] = roots.reversed().map { ($0, parent) }
        while let (index, parentEntity) = stack.popLast() {
            let node = nodes[index]
            let entity = world.spawn(node.transform, Name(node.name ?? "Node \(index)"))
            if let parentEntity { world.setParent(entity, to: parentEntity) }
            if parentEntity == parent { result.roots.append(entity) }
            result.nodes[index] = entity
            if let meshIndex = node.mesh {
                let imported = meshes[meshIndex]
                let single = imported.primitives.count == 1
                for (p, primitive) in imported.primitives.enumerated() {
                    guard let handle = mesh(meshIndex, p) else { continue }
                    let renderer = MeshRenderer(mesh: handle, material: material(primitive.material))
                    if single {
                        world.add(renderer, to: entity)
                        result.renderers.append(entity)
                    } else {
                        let child = world.spawn(Transform(), Name("\(imported.name ?? "Mesh \(meshIndex)") [\(p)]"), renderer)
                        world.setParent(child, to: entity)
                        result.renderers.append(child)
                    }
                }
            }
            stack += node.children.reversed().map { ($0, entity) }
        }
        return result
    }

    /// `instantiate(in:under:mesh:material:)` with handles from `handles`.
    @discardableResult
    public func instantiate(in world: World, under parent: Entity? = nil, handles: ModelHandles) -> InstantiatedModel {
        instantiate(in: world, under: parent,
                    mesh: { m, p in handles.meshes[safe: m]?[safe: p] ?? nil },
                    material: { $0.flatMap { handles.materials[safe: $0] } ?? handles.defaultMaterial })
    }

    /// Uploads every primitive and material to `renderer` under keys starting with
    /// `keyPrefix` ("<prefix>/mesh<m>.<p>", "<prefix>/material<i>", "<prefix>/default") and
    /// returns their handles. Materials go through `ImportedMaterial.engineMaterial`, with
    /// the base color texture from `textures[textureIndex]` (see `makeTextures`; nil or a
    /// missing entry draws untextured). Empty primitives are left out.
    public func register(with renderer: SceneRenderer, keyPrefix: String, textures: [GPUTexture?] = []) throws -> ModelHandles {
        var meshHandles: [[MeshHandle?]] = []
        for (m, mesh) in meshes.enumerated() {
            meshHandles.append(try mesh.primitives.enumerated().map { p, primitive in
                primitive.geometry.indices.isEmpty
                    ? nil : try renderer.registerMesh(primitive.geometry, key: "\(keyPrefix)/mesh\(m).\(p)")
            })
        }
        var materialHandles: [MaterialHandle] = []
        for (i, material) in materials.enumerated() {
            let reference = material.baseColorTexture
            let texture = reference.flatMap { textures[safe: $0.texture] ?? nil }
            let sampler = reference.map { self.textures[$0.texture].sampler }
            materialHandles.append(try renderer.registerMaterial(
                material.engineMaterial(baseColorTexture: texture, sampler: sampler), key: "\(keyPrefix)/material\(i)"))
        }
        let defaultMaterial = try renderer.registerMaterial(ImportedMaterial.gltfDefault.engineMaterial(), key: "\(keyPrefix)/default")
        return ModelHandles(meshes: meshHandles, materials: materialHandles, defaultMaterial: defaultMaterial)
    }

    /// Decodes each texture's image with `decoder` and uploads it: `.rgba8Srgb` for color
    /// textures, `.rgba8Unorm` for data, with mipmaps when the sampler uses them. Textures
    /// whose image is missing or fails to decode are nil, with a message in `failures`.
    public func makeTextures(device: RenderDevice, decoder: (Data, String?) throws -> Image)
        -> (textures: [GPUTexture?], failures: [String]) {
        var decoded: [Int: Image] = [:]
        var failures: [String] = []
        let result: [GPUTexture?] = textures.enumerated().map { i, texture in
            guard let imageIndex = texture.image else { return nil }
            do {
                let image: Image
                if let cached = decoded[imageIndex] {
                    image = cached
                } else {
                    let source = images[imageIndex]
                    image = try decoder(source.data, source.mimeType)
                    decoded[imageIndex] = image
                }
                return try device.makeTexture(
                    pixels: image.pixels, width: image.width, height: image.height,
                    format: texture.colorSpace == .sRGB ? .rgba8Srgb : .rgba8Unorm, generateMipmaps: texture.sampler.usesMipmaps)
            } catch {
                failures.append("Texture \(i) (image \(imageIndex)): \(error)")
                return nil
            }
        }
        return (result, failures)
    }
}

fileprivate extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
