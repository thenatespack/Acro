import Foundation

/// Imports PNG, JPEG and TGA images (`ImageDecoder`) as one `texture` sub-asset: RGBA8, sRGB
/// or linear, with a mip chain unless turned off. Use linear (`sRGB: false`) for data such as
/// normal maps and masks.
///
/// Radiance HDR isn't imported yet: `TextureAsset` holds 8-bit pixels only.
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
    public var fileExtensions: [String] { ["png", "jpg", "jpeg", "tga"] }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let image = try ImageDecoder.decode(context.data())
        var asset = ImportedAsset()
        asset.add("texture", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .texture(TextureAsset(image: image, isSRGB: settings.sRGB, generatesMipmaps: settings.mipmaps)))
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
///
/// External `.bin` buffers are read relative to the model's folder. `Settings.materialRemap`
/// points the prefab's nodes at other material assets (extracted `.material` files).
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
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let folder = context.sourceURL.deletingLastPathComponent()
        let model = try GLTFReader.read(
            data: context.data(), baseURL: folder,
            options: GLTFReader.Options(normals: settings.smoothNormals ? .smooth : .flat),
            loadResource: { try Data(contentsOf: folder.appendingPathComponent($0)) })
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
            let base = material.baseColorTexture
            let value = material.materialAsset(baseColorTexture: base.flatMap { textures[$0.texture] },
                                               sampler: base.map { model.textures[$0.texture].sampler })
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

        func node(_ index: Int) -> PrefabNode {
            let source = model.nodes[index]
            var result = PrefabNode(name: source.name ?? "Node \(index)", transform: source.transform)
            if let meshIndex = source.mesh {
                let mesh = model.meshes[meshIndex]
                let refs = primitives(of: meshIndex)
                if mesh.primitives.count == 1 {
                    if let ref = refs[0] {
                        result.mesh = ref
                        result.material = material(mesh.primitives[0].material)
                    }
                } else {
                    for (p, primitive) in mesh.primitives.enumerated() {
                        guard let ref = refs[p] else { continue }
                        result.children.append(PrefabNode(name: "\(mesh.name ?? "Mesh \(meshIndex)") [\(p)]",
                                                          mesh: ref, material: material(primitive.material)))
                    }
                }
            }
            result.children += source.children.map(node)
            return result
        }

        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let roots = model.roots.map(node)
        guard !roots.isEmpty else { throw AssetError.unreadable("the scene has no nodes") }
        let root = roots.count == 1 ? roots[0] : PrefabNode(name: stem, children: roots)
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [root])))
        asset.main = prefab
        return asset
    }
}
