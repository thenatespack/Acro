import Foundation

/// Imports PNG, JPEG, TGA and Radiance HDR images (`ImageDecoder.decodeAny`) as one `texture`
/// sub-asset: RGBA8, sRGB or linear, with a mip chain unless turned off. Use linear
/// (`sRGB: false`) for data such as normal maps and masks. `.hdr` files stay float
/// (`TextureAsset.floatImage`, uploaded as `.rgba16Float`) and ignore `sRGB`; with
/// `compression` they become BC6H or ASTC 4x4 HDR (`TextureCompression.hdrFormat`: `auto`
/// picks per machine, as for 8-bit images), an eighth of the memory.
///
/// With `compression` (BC7 / ASTC 4x4, or `auto` for this machine's GPUs), the mip chain is
/// built and block-compressed here (`TextureCodec`), so the Library caches the compressed
/// levels. The encodings are also kept in `ImportContext.cacheDirectory`, keyed by the source's
/// hash, the format, quality and mipmaps, so a reimport with the same inputs (a forced one, or
/// switching compression back) doesn't encode again. Normal maps (`normalMap`) can be stored in
/// two channels (`.bc5Unorm`, `.astc4x4RG`; the mesh shader rebuilds Z).
public struct TextureImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        /// Color data (true) or linear data such as normals and masks (false).
        public var sRGB: Bool = true
        public var mipmaps: Bool = true
        /// Block compression of 8-bit images. Linear textures (normal maps, masks) are encoded
        /// with all channels weighted alike, color with perceptual weights.
        public var compression: TextureCompression = .none
        /// Encoder effort when compressing.
        public var compressionQuality: TextureCompressionQuality = .normal
        /// A tangent-space normal map (use with `sRGB: false`): `compression` `auto`, `bc5` and
        /// `astcRG` store only its X and Y (two-channel formats; the mesh shader rebuilds Z).
        public var normalMap: Bool = false

        public init(sRGB: Bool = true, mipmaps: Bool = true, compression: TextureCompression = .none,
                    compressionQuality: TextureCompressionQuality = .normal, normalMap: Bool = false) {
            self.sRGB = sRGB
            self.mipmaps = mipmaps
            self.compression = compression
            self.compressionQuality = compressionQuality
            self.normalMap = normalMap
        }

        private enum CodingKeys: String, CodingKey { case sRGB, mipmaps, compression, compressionQuality, normalMap }

        /// Every key is optional, so sidecars from before `compression` existed decode. All of
        /// them are encoded, so the editor's inspector lists them.
        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            sRGB = try c.decodeIfPresent(Bool.self, forKey: .sRGB) ?? true
            mipmaps = try c.decodeIfPresent(Bool.self, forKey: .mipmaps) ?? true
            compression = try c.decodeIfPresent(TextureCompression.self, forKey: .compression) ?? .none
            compressionQuality = try c.decodeIfPresent(TextureCompressionQuality.self, forKey: .compressionQuality) ?? .normal
            normalMap = try c.decodeIfPresent(Bool.self, forKey: .normalMap) ?? false
        }
    }

    public init() {}

    public var name: String { "texture" }
    public var fileExtensions: [String] { ["png", "jpg", "jpeg", "tga", "hdr"] }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let data = try context.data()
        let image = try ImageDecoder.decodeAny(data)
        var texture = TextureAsset(decoded: image, isSRGB: settings.sRGB, generatesMipmaps: settings.mipmaps)
        switch texture.pixels {
        case .rgba8(let pixels):
            if let format = settings.compression.format(srgb: settings.sRGB, normalMap: settings.normalMap) {
                texture = TextureAsset(compressedLevels: try CompressedTextureCache.levels(
                    pixels, format: format, quality: settings.compressionQuality, mipmaps: settings.mipmaps,
                    sourceHash: ContentHash.hex(data), file: context.cacheDirectory?.appendingPathComponent("\(format.rawValue).bin"),
                    label: context.assetPath), format: format)
            }
        case .rgbaFloat(let image):
            if let format = settings.compression.hdrFormat {
                texture = TextureAsset(compressedLevels: try CompressedTextureCache.levels(
                    hdr: image, format: format, quality: settings.compressionQuality, mipmaps: settings.mipmaps,
                    sourceHash: ContentHash.hex(data), file: context.cacheDirectory?.appendingPathComponent("\(format.rawValue).bin"),
                    label: context.assetPath), format: format)
            }
        case .compressed:
            break
        }
        var asset = ImportedAsset()
        asset.add("texture", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .texture(texture))
        return asset
    }
}

/// One cached encoding: "TXC1", the key's length (UInt32) and UTF-8 bytes, the level count
/// (UInt32), then every level's blocks (their sizes follow from the image size and format).
enum CompressedTextureCache {
    private static let magic = Array("TXC1".utf8)

    /// The compressed mip chain of `image` from `file` (in an `ImportContext.cacheDirectory`)
    /// when one was made from the same inputs (source hash, format, quality, mipmaps, codec
    /// version), else freshly encoded and written there. Two-channel formats encode the image
    /// as a normal map, normalized first (`TextureCodec.normalized(normalMap:)`).
    static func levels(_ image: Image, format: TextureFormat, quality: TextureCompressionQuality, mipmaps: Bool,
                       sourceHash: String, file: URL?, label: String) throws -> [TextureMipLevel] {
        let key = "\(sourceHash) \(format) \(quality) mipmaps:\(mipmaps) codec:\(TextureCodec.version)"
        if let file, let levels = read(file, key: key, format: format, width: image.width, height: image.height) {
            return levels
        }
        let source = format.isTwoChannel ? TextureCodec.normalized(normalMap: image) : image
        return try encode(width: image.width, height: image.height, format: format, key: key, file: file, label: label) {
            try TextureCodec.encode(source, format: format, mipmaps: mipmaps, quality: quality)
        }
    }

    /// `levels(_:...)` for an HDR image and one of `TextureFormat.hdrCompressedFormats`.
    static func levels(hdr image: FloatImage, format: TextureFormat, quality: TextureCompressionQuality, mipmaps: Bool,
                       sourceHash: String, file: URL?, label: String) throws -> [TextureMipLevel] {
        let key = "\(sourceHash) \(format) \(quality) mipmaps:\(mipmaps) codec:\(TextureCodec.version)"
        if let file, let levels = read(file, key: key, format: format, width: image.width, height: image.height) {
            return levels
        }
        return try encode(width: image.width, height: image.height, format: format, key: key, file: file, label: label) {
            try TextureCodec.encode(image, format: format, mipmaps: mipmaps, quality: quality)
        }
    }

    private static func encode(width: Int, height: Int, format: TextureFormat, key: String, file: URL?, label: String,
                               _ body: () throws -> [TextureMipLevel]) throws -> [TextureMipLevel] {
        let start = DispatchTime.now().uptimeNanoseconds
        let levels = try body()
        let milliseconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6
        EngineLog.debug("Encoded \(label) (\(width)x\(height), \(levels.count) levels) as \(format) in "
                        + String(format: "%.0f ms", milliseconds), category: .assets)
        if let file { write(levels, key: key, to: file) }
        return levels
    }

    static func read(_ url: URL, key: String, format: TextureFormat, width: Int, height: Int) -> [TextureMipLevel]? {
        guard let data = FileManager.default.contents(atPath: url.path), data.count >= 12,
              Array(data.prefix(4)) == magic else { return nil }
        let bytes = [UInt8](data)
        func u32(_ offset: Int) -> Int { bytes[offset..<offset + 4].reversed().reduce(0) { $0 << 8 | Int($1) } }
        let keyLength = u32(4)
        guard 8 + keyLength + 4 <= bytes.count, String(decoding: bytes[8..<8 + keyLength], as: UTF8.self) == key else { return nil }
        let count = u32(8 + keyLength)
        guard count >= 1, count <= MipChain.levelCount(width: width, height: height) else { return nil }
        var offset = 12 + keyLength
        var levels: [TextureMipLevel] = []
        for level in 0..<count {
            let size = MipChain.size(width: width, height: height, level: level)
            let length = format.byteCount(width: size.width, height: size.height)
            guard offset + length <= bytes.count else { return nil }
            levels.append(TextureMipLevel(width: size.width, height: size.height, pixels: Array(bytes[offset..<offset + length])))
            offset += length
        }
        return offset == bytes.count ? levels : nil
    }

    /// Best effort: a cache that can't be written only costs an encode next time.
    static func write(_ levels: [TextureMipLevel], key: String, to url: URL) {
        func u32(_ value: Int) -> [UInt8] { (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) } }
        let keyBytes = Array(key.utf8)
        var data = Data(magic + u32(keyBytes.count) + keyBytes + u32(levels.count))
        for level in levels { data.append(contentsOf: level.pixels) }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
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
/// `Settings.compression` block-compresses the imported textures by role (normal maps in two
/// channels under `auto`), cached in `ImportContext.cacheDirectory` like `TextureImporter`'s.
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
        /// Block compression of the textures the file embeds (or references outside the
        /// project), by role: base color and emissive as sRGB color, metallic-roughness and
        /// occlusion as linear data, normal maps as normal maps (two channels under `auto`,
        /// `bc5` and `astcRG`), as `TextureImporter.Settings.compression` does. Images that are
        /// project assets keep their own importer settings.
        public var compression: TextureCompression = .none
        /// Encoder effort when compressing.
        public var compressionQuality: TextureCompressionQuality = .normal

        public init(smoothNormals: Bool = false, materialRemap: [SubAssetID: AssetReference] = [:],
                    compression: TextureCompression = .none, compressionQuality: TextureCompressionQuality = .normal) {
            self.smoothNormals = smoothNormals
            self.materialRemap = materialRemap
            self.compression = compression
            self.compressionQuality = compressionQuality
        }

        private enum CodingKeys: String, CodingKey { case smoothNormals, materialRemap, compression, compressionQuality }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            smoothNormals = try c.decodeIfPresent(Bool.self, forKey: .smoothNormals) ?? false
            materialRemap = try c.decodeIfPresent([SubAssetID: AssetReference].self, forKey: .materialRemap) ?? [:]
            compression = try c.decodeIfPresent(TextureCompression.self, forKey: .compression) ?? .none
            compressionQuality = try c.decodeIfPresent(TextureCompressionQuality.self, forKey: .compressionQuality) ?? .normal
        }

        /// An empty remap is left out, so sidecars (and cached imports) from before it existed
        /// stay the same. The compression keys are always written, so the editor lists them.
        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(smoothNormals, forKey: .smoothNormals)
            if !materialRemap.isEmpty { try c.encode(materialRemap, forKey: .materialRemap) }
            try c.encode(compression, forKey: .compression)
            try c.encode(compressionQuality, forKey: .compressionQuality)
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
                let srgb = texture.colorSpace == .sRGB, mipmaps = texture.sampler.usesMipmaps
                var value = TextureAsset(image: pixels, isSRGB: srgb, generatesMipmaps: mipmaps)
                if let format = settings.compression.format(srgb: srgb, normalMap: texture.slots == [.normal]) {
                    // Cached per texture (its image's hash, format, quality, mipmaps), so a
                    // reimport doesn't encode again.
                    value = TextureAsset(compressedLevels: try CompressedTextureCache.levels(
                        pixels, format: format, quality: settings.compressionQuality, mipmaps: mipmaps,
                        sourceHash: ContentHash.hex(image.data),
                        file: context.cacheDirectory?.appendingPathComponent("texture\(i)-\(format.rawValue).bin"),
                        label: "\(context.assetPath) texture \(i)"), format: format)
                }
                asset.add(id, name: name ?? "Texture \(i)", .texture(value))
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
