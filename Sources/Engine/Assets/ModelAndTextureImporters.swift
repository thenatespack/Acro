import Foundation

/// Imports PNG, JPEG, TGA and Radiance HDR images (`ImageDecoder.decodeAny`) as one `texture`
/// sub-asset: RGBA8, sRGB or linear, with a mip chain unless turned off. Use linear
/// (`sRGB: false`) for data such as normal maps and masks. `.hdr` files stay float
/// (`TextureAsset.floatImage`, uploaded as `.rgba16Float`) and ignore `sRGB`.
public struct TextureImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        /// Color data (true) or linear data such as normals and masks (false).
        public var sRGB: Bool = true
        public var mipmaps: Bool = true

        public init(sRGB: Bool = true, mipmaps: Bool = true) {
            self.sRGB = sRGB
            self.mipmaps = mipmaps
        }
    }

    public init() {}

    public var name: String { "texture" }
    public var fileExtensions: [String] { ["png", "jpg", "jpeg", "tga", "hdr"] }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let image = try ImageDecoder.decodeAny(context.data())
        var asset = ImportedAsset()
        asset.add("texture", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .texture(TextureAsset(decoded: image, isSRGB: settings.sRGB, generatesMipmaps: settings.mipmaps)))
        return asset
    }
}

/// Imports glTF 2.0 files (`.gltf`, `.glb`) with `GLTFReader`.
///
/// Sub-asset ids:
/// - `mesh/<mesh name>` for a mesh with one primitive, `mesh/<mesh name> [<p>]` per primitive
///   otherwise (`<index>` for unnamed meshes);
/// - `material/<name>` per material via `ImportedMaterial.materialAsset`, plus
///   `material/default` (glTF's default material) when a primitive has none;
/// - `texture/<name>` per texture whose image is embedded (GLB buffer or `data:` URI), or
///   external but outside the project. An external image that is a project asset is referenced
///   instead, so editing it doesn't reimport the model;
/// - `prefab/<file name>`, the main object: the scene's node tree, laid out like
///   `ImportedModel.instantiate` (multi-primitive meshes get one child node per primitive).
///   Skinned meshes keep their joint influences (`MeshGeometry.skin`) and their nodes a
///   `PrefabSkin`, so instances get a `Skin` and animate.
///
/// External `.bin` buffers are read relative to the model's folder and recorded as
/// dependencies (`ImportContext.readDependency`): editing one reimports the model.
/// `Settings.materialRemap` points the prefab's nodes at other material assets (extracted
/// `.material` files).
public struct GLTFImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        /// Generate smooth (area-weighted) normals where the file has none, instead of flat.
        public var smoothNormals: Bool = false
        /// Materials to use instead of the file's own, by material sub-asset id
        /// (`"material/Rock"` → a `.material` asset, e.g. one written by the editor's Extract
        /// Materials). The prefab's nodes reference the replacement; the file's material
        /// sub-assets are still imported, so existing references keep working.
        public var materialRemap: [SubAssetID: AssetReference] = [:]

        public init(smoothNormals: Bool = false, materialRemap: [SubAssetID: AssetReference] = [:]) {
            self.smoothNormals = smoothNormals
            self.materialRemap = materialRemap
        }

        private enum CodingKeys: String, CodingKey { case smoothNormals, materialRemap }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            smoothNormals = try c.decodeIfPresent(Bool.self, forKey: .smoothNormals) ?? false
            materialRemap = try c.decodeIfPresent([SubAssetID: AssetReference].self, forKey: .materialRemap) ?? [:]
        }

        /// An empty remap is left out, so sidecars (and cached imports) from before it existed
        /// stay the same.
        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(smoothNormals, forKey: .smoothNormals)
            if !materialRemap.isEmpty { try c.encode(materialRemap, forKey: .materialRemap) }
        }
    }

    public init() {}

    public var name: String { "gltf" }
    public var fileExtensions: [String] { ["gltf", "glb"] }
    /// 2: PBR materials (every texture slot, metallic-roughness, emissive, alpha mask) and tangents.
    /// 3: skins (joint influences in the mesh cache, `PrefabSkin` on the prefab's nodes).
    public var version: Int { 3 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let folder = context.sourceURL.deletingLastPathComponent()
        let reader = context  // the loader below can't capture the inout context; the dependency log is shared
        let model = try GLTFReader.read(
            data: context.data(), baseURL: folder,
            options: GLTFReader.Options(normals: settings.smoothNormals ? .smooth : .flat),
            loadResource: { try reader.readDependency(relativePath: $0) })
        for warning in model.warnings { context.warn(warning) }

        var asset = ImportedAsset()
        var namer = SubAssetNamer()

        // Textures: a reference to the project asset for external image files, else decoded here.
        var textures: [AssetReference?] = []
        for (i, texture) in model.textures.enumerated() {
            guard let imageIndex = texture.image else { textures.append(nil); continue }
            let image = model.images[imageIndex]
            if let uri = image.uri, !uri.hasPrefix("data:"),
               let id = context.asset(atRelativePath: uri.removingPercentEncoding ?? uri) {
                textures.append(AssetReference(id, subAsset: "texture"))
                continue
            }
            do {
                let pixels = try ImageDecoder.decode(image.data)
                let name = texture.name ?? image.name
                let id = namer.id(kind: "texture", name: name, index: i)
                asset.add(id, name: name ?? "Texture \(i)", .texture(TextureAsset(
                    image: pixels, isSRGB: texture.colorSpace == .sRGB, generatesMipmaps: texture.sampler.usesMipmaps)))
                textures.append(context.reference(id))
            } catch {
                context.warn("texture \(i) (image \(imageIndex)): \(error)")
                textures.append(nil)
            }
        }

        var materials: [AssetReference] = []
        for (i, material) in model.materials.enumerated() {
            let value = material.materialAsset(textures: { textures[$0.texture] },
                                               sampler: material.primaryTexture.map { model.textures[$0.texture].sampler })
            let id = namer.id(kind: "material", name: material.name, index: i)
            asset.add(id, name: material.name ?? "Material \(i)", .material(value))
            materials.append(context.reference(id))
        }
        var defaultMaterial: AssetReference?
        func material(_ index: Int?) -> AssetReference {
            let reference: AssetReference
            if let index {
                reference = materials[index]
            } else if let defaultMaterial {
                reference = defaultMaterial
            } else {
                let id = namer.id(kind: "material", name: "default", index: model.materials.count)
                asset.add(id, name: "Default", .material(ImportedMaterial.gltfDefault.materialAsset()))
                defaultMaterial = context.reference(id)
                reference = defaultMaterial!
            }
            return reference.subAsset.flatMap { settings.materialRemap[$0] } ?? reference
        }

        // Meshes are added as nodes use them, so meshes outside the scene aren't imported.
        var meshes: [Int: [AssetReference?]] = [:]
        func primitives(of index: Int) -> [AssetReference?] {
            if let done = meshes[index] { return done }
            let mesh = model.meshes[index]
            let meshName = mesh.name ?? "\(index)"
            let refs: [AssetReference?] = mesh.primitives.enumerated().map { p, primitive in
                guard !primitive.geometry.indices.isEmpty else { return nil }
                let name = mesh.primitives.count == 1 ? meshName : "\(meshName) [\(p)]"
                let id = namer.id(kind: "mesh", name: name, index: index)
                asset.add(id, name: name, .mesh(primitive.geometry))
                return context.reference(id)
            }
            meshes[index] = refs
            return refs
        }

        // Prefab node numbers (depth first, see `PrefabSkin`) of the glTF nodes, for skins.
        // A wrapper root (several scene roots) is node 0.
        var nodeNumbers: [Int: Int] = [:]
        var nodeCount = model.roots.count == 1 ? 0 : 1
        func skin(_ index: Int?, _ primitive: ImportedPrimitive) -> PrefabSkin? {
            guard let index, primitive.geometry.skin != nil else { return nil }
            // Joints hold glTF node indices until every node is numbered (see `numberJoints`).
            return PrefabSkin(joints: model.skins[index].joints, inverseBindMatrices: model.skins[index].inverseBindMatrices)
        }

        func node(_ index: Int) -> PrefabNode {
            let source = model.nodes[index]
            nodeNumbers[index] = nodeCount
            nodeCount += 1
            var result = PrefabNode(name: source.name ?? "Node \(index)", transform: source.transform)
            if let meshIndex = source.mesh {
                let mesh = model.meshes[meshIndex]
                let refs = primitives(of: meshIndex)
                if mesh.primitives.count == 1 {
                    if let ref = refs[0] {
                        result.mesh = ref
                        result.material = material(mesh.primitives[0].material)
                        result.skin = skin(source.skin, mesh.primitives[0])
                    }
                } else {
                    for (p, primitive) in mesh.primitives.enumerated() {
                        guard let ref = refs[p] else { continue }
                        result.children.append(PrefabNode(name: "\(mesh.name ?? "Mesh \(meshIndex)") [\(p)]",
                                                          mesh: ref, material: material(primitive.material),
                                                          skin: skin(source.skin, primitive)))
                        nodeCount += 1
                    }
                }
            }
            result.children += source.children.map(node)
            return result
        }
        func numberJoints(_ node: inout PrefabNode) {
            if var skin = node.skin {
                skin.joints = skin.joints.map { nodeNumbers[$0] ?? -1 }
                node.skin = skin
            }
            for i in node.children.indices { numberJoints(&node.children[i]) }
        }

        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var roots = model.roots.map(node)
        guard !roots.isEmpty else { throw AssetError.unreadable("the scene has no nodes") }
        for i in roots.indices { numberJoints(&roots[i]) }
        let root = roots.count == 1 ? roots[0] : PrefabNode(name: stem, children: roots)
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [root])))
        asset.main = prefab
        return asset
    }
}
