import Foundation

// What importers produce: CPU-side objects only (no GPU resources), so imports can run on any
// thread. `SceneRenderer` uploads them on the main thread when a handle first names them.

/// Everything imported from one source file: its objects (sub-assets), in the importer's order.
public struct ImportedAsset: Sendable {
    public var objects: [ImportedObject]
    /// The object a reference without a sub-asset means (when it has the kind asked for);
    /// nil means the first object of that kind.
    public var main: SubAssetID?

    public init(objects: [ImportedObject] = [], main: SubAssetID? = nil) {
        self.objects = objects
        self.main = main
    }

    /// Appends an object. Its id must be unique in this asset (`SubAssetNamer` makes such ids).
    public mutating func add(_ id: SubAssetID, name: String? = nil, _ value: AssetObject) {
        precondition(!objects.contains { $0.id == id }, "Duplicate sub-asset id '\(id)'")
        objects.append(ImportedObject(id: id, name: name ?? Self.defaultName(id), value: value))
    }

    /// The object with `id`.
    public func object(_ id: SubAssetID) -> ImportedObject? { objects.first { $0.id == id } }

    /// The object a reference means for `kind`: `subAsset` if given (and of that kind), else
    /// `main` if it is of that kind, else the first object of that kind.
    public func object(_ subAsset: SubAssetID?, kind: AssetKind) -> ImportedObject? {
        if let subAsset {
            return object(subAsset).flatMap { $0.kind == kind ? $0 : nil }
        }
        if let main, let object = object(main), object.kind == kind { return object }
        return objects.first { $0.kind == kind }
    }

    /// The last path component of an id ("Rock" for "mesh/Rock").
    static func defaultName(_ id: SubAssetID) -> String {
        id.split(separator: "/").last.map(String.init) ?? id
    }
}

/// One object of an `ImportedAsset`.
public struct ImportedObject: Sendable {
    public var id: SubAssetID
    /// Display name (the name in the source file).
    public var name: String
    public var value: AssetObject

    public init(id: SubAssetID, name: String, value: AssetObject) {
        self.id = id
        self.name = name
        self.value = value
    }

    public var kind: AssetKind { value.kind }
}

/// The kinds of objects importers can produce.
public enum AssetKind: String, Codable, Sendable, CaseIterable {
    case mesh, material, texture, prefab
}

/// An imported object. Each kind is plain CPU data:
/// - `.mesh`: vertices and indices (`MeshGeometry`), uploaded as a `GPUMesh`.
/// - `.material`: a `MaterialAsset`, whose texture is a reference to a `.texture` object.
/// - `.texture`: RGBA8 pixels (`TextureAsset`).
/// - `.prefab`: a node hierarchy (`PrefabAsset`) whose nodes reference meshes and materials;
///   `World.instantiate(_:)` spawns it as entities.
public enum AssetObject: Sendable {
    case mesh(MeshGeometry)
    case material(MaterialAsset)
    case texture(TextureAsset)
    case prefab(PrefabAsset)

    public var kind: AssetKind {
        switch self {
        case .mesh: .mesh
        case .material: .material
        case .texture: .texture
        case .prefab: .prefab
        }
    }
}

/// A `Material` as data: the same parameters, with textures named by `AssetReference`s instead
/// of held as GPU textures. `SceneRenderer` turns it into a `Material` when it is first used
/// (uploading the textures too). Codable, with every key optional, so it is also the
/// `.material` file format (see `MaterialFileImporter`).
///
/// Missing keys take the defaults of `init()`, except `shading`: a file without it was written
/// before PBR existed and loads as `.blinnPhong`, so it keeps its look. Files written now always
/// contain it. The old key `isTransparent` (true) still reads as `alphaMode` `blend`.
public struct MaterialAsset: Equatable, Sendable, Codable {
    public var shading: ShadingModel
    public var baseColor: Vec4
    /// The base color texture, a `.texture` object: another asset's (`AssetReference(textureID)`)
    /// or one from the same file (`ImportContext.reference(_:)`). sRGB.
    public var texture: AssetReference?
    public var filter: SamplerFilter
    public var mipFilter: SamplerMipFilter
    public var addressMode: SamplerAddressMode
    public var uvScale: Vec2
    public var uvOffset: Vec2
    public var uvRotation: Float
    public var checker: Bool
    /// Unlit amount (see `Material.emissive`); the emitted light is `emissiveColor`.
    public var emissive: Float
    public var specular: Float
    public var shininess: Float
    public var metallic: Float
    public var roughness: Float
    /// Linear: roughness in G, metalness in B.
    public var metallicRoughnessTexture: AssetReference?
    /// Linear tangent-space normal map.
    public var normalTexture: AssetReference?
    public var normalScale: Float
    /// Linear: occlusion in R.
    public var occlusionTexture: AssetReference?
    public var occlusionStrength: Float
    public var emissiveColor: Vec3
    /// sRGB.
    public var emissiveTexture: AssetReference?
    public var emissiveStrength: Float
    public var alphaMode: AlphaMode
    public var alphaCutoff: Float
    public var doubleSided: Bool

    public init(shading: ShadingModel = .pbr, baseColor: Vec4 = Vec4(0.8, 0.8, 0.8, 1), texture: AssetReference? = nil,
                filter: SamplerFilter = .linear, mipFilter: SamplerMipFilter = .linear, addressMode: SamplerAddressMode = .repeat,
                uvScale: Vec2 = Vec2(1, 1), uvOffset: Vec2 = .zero, uvRotation: Float = 0, checker: Bool = false,
                emissive: Float = 0, specular: Float = 0.35, shininess: Float = 48, metallic: Float = 0, roughness: Float = 0.5,
                metallicRoughnessTexture: AssetReference? = nil, normalTexture: AssetReference? = nil, normalScale: Float = 1,
                occlusionTexture: AssetReference? = nil, occlusionStrength: Float = 1, emissiveColor: Vec3 = .zero,
                emissiveTexture: AssetReference? = nil, emissiveStrength: Float = 1, alphaMode: AlphaMode = .opaque,
                alphaCutoff: Float = 0.5, doubleSided: Bool = false) {
        self.shading = shading
        self.baseColor = baseColor
        self.texture = texture
        self.filter = filter
        self.mipFilter = mipFilter
        self.addressMode = addressMode
        self.uvScale = uvScale
        self.uvOffset = uvOffset
        self.uvRotation = uvRotation
        self.checker = checker
        self.emissive = emissive
        self.specular = specular
        self.shininess = shininess
        self.metallic = metallic
        self.roughness = roughness
        self.metallicRoughnessTexture = metallicRoughnessTexture
        self.normalTexture = normalTexture
        self.normalScale = normalScale
        self.occlusionTexture = occlusionTexture
        self.occlusionStrength = occlusionStrength
        self.emissiveColor = emissiveColor
        self.emissiveTexture = emissiveTexture
        self.emissiveStrength = emissiveStrength
        self.alphaMode = alphaMode
        self.alphaCutoff = alphaCutoff
        self.doubleSided = doubleSided
    }

    /// `alphaMode == .blend`.
    public var isTransparent: Bool {
        get { alphaMode == .blend }
        set { alphaMode = newValue ? .blend : (alphaMode == .blend ? .opaque : alphaMode) }
    }

    /// Every texture reference with its slot, base color first.
    public var textureReferences: [(slot: TextureSlot, reference: AssetReference)] {
        let all: [(TextureSlot, AssetReference?)] = [
            (.baseColor, texture), (.metallicRoughness, metallicRoughnessTexture), (.normal, normalTexture),
            (.occlusion, occlusionTexture), (.emissive, emissiveTexture),
        ]
        return all.compactMap { slot, reference in reference.map { (slot, $0) } }
    }

    /// The `Material` with GPU textures from `textures`, called once per texture reference
    /// (nil draws without that texture).
    public func material(textures: (AssetReference) throws -> GPUTexture?) rethrows -> Material {
        func resolve(_ reference: AssetReference?) throws -> GPUTexture? { try reference.flatMap(textures) }
        return Material(
            shading: shading, baseColor: baseColor, texture: try resolve(texture),
            sampler: SamplerDescriptor(filter: filter, mipFilter: mipFilter, addressMode: addressMode),
            uvScale: uvScale, uvOffset: uvOffset, uvRotation: uvRotation, checker: checker, emissive: emissive,
            specular: specular, shininess: shininess, metallic: metallic, roughness: roughness,
            metallicRoughnessTexture: try resolve(metallicRoughnessTexture), normalTexture: try resolve(normalTexture),
            normalScale: normalScale, occlusionTexture: try resolve(occlusionTexture), occlusionStrength: occlusionStrength,
            emissiveColor: emissiveColor, emissiveTexture: try resolve(emissiveTexture), emissiveStrength: emissiveStrength,
            alphaMode: alphaMode, alphaCutoff: alphaCutoff, doubleSided: doubleSided)
    }

    /// The `Material` with `texture` as its base color texture and no other textures.
    public func material(texture gpuTexture: GPUTexture?) -> Material {
        var material = material(textures: { _ in nil })
        material.texture = gpuTexture
        return material
    }

    private enum CodingKeys: String, CodingKey {
        case shading, baseColor, texture, filter, mipFilter, addressMode, uvScale, uvOffset, uvRotation, checker, emissive
        case specular, shininess, metallic, roughness, metallicRoughnessTexture, normalTexture, normalScale
        case occlusionTexture, occlusionStrength, emissiveColor, emissiveTexture, emissiveStrength, alphaMode, alphaCutoff
        case doubleSided, isTransparent
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialAsset()
        // Files from before PBR have no `shading` key: keep their Blinn-Phong look.
        shading = try c.decodeIfPresent(String.self, forKey: .shading).map { $0 == ShadingModel.pbr.rawValue ? .pbr : .blinnPhong }
            ?? .blinnPhong
        baseColor = try c.decodeIfPresent(Vec4.self, forKey: .baseColor) ?? d.baseColor
        texture = try c.decodeIfPresent(AssetReference.self, forKey: .texture)
        filter = try c.decodeIfPresent(String.self, forKey: .filter).map { $0 == "nearest" ? .nearest : .linear } ?? d.filter
        mipFilter = try c.decodeIfPresent(String.self, forKey: .mipFilter).map {
            switch $0 { case "none": .none; case "nearest": .nearest; default: .linear }
        } ?? d.mipFilter
        addressMode = try c.decodeIfPresent(String.self, forKey: .addressMode).map {
            switch $0 { case "clampToEdge": .clampToEdge; case "mirrorRepeat": .mirrorRepeat; default: .repeat }
        } ?? d.addressMode
        uvScale = try c.decodeIfPresent(Vec2.self, forKey: .uvScale) ?? d.uvScale
        uvOffset = try c.decodeIfPresent(Vec2.self, forKey: .uvOffset) ?? d.uvOffset
        uvRotation = try c.decodeIfPresent(Float.self, forKey: .uvRotation) ?? d.uvRotation
        checker = try c.decodeIfPresent(Bool.self, forKey: .checker) ?? d.checker
        emissive = try c.decodeIfPresent(Float.self, forKey: .emissive) ?? d.emissive
        specular = try c.decodeIfPresent(Float.self, forKey: .specular) ?? d.specular
        shininess = try c.decodeIfPresent(Float.self, forKey: .shininess) ?? d.shininess
        metallic = try c.decodeIfPresent(Float.self, forKey: .metallic) ?? d.metallic
        roughness = try c.decodeIfPresent(Float.self, forKey: .roughness) ?? d.roughness
        metallicRoughnessTexture = try c.decodeIfPresent(AssetReference.self, forKey: .metallicRoughnessTexture)
        normalTexture = try c.decodeIfPresent(AssetReference.self, forKey: .normalTexture)
        normalScale = try c.decodeIfPresent(Float.self, forKey: .normalScale) ?? d.normalScale
        occlusionTexture = try c.decodeIfPresent(AssetReference.self, forKey: .occlusionTexture)
        occlusionStrength = try c.decodeIfPresent(Float.self, forKey: .occlusionStrength) ?? d.occlusionStrength
        emissiveColor = try c.decodeIfPresent(Vec3.self, forKey: .emissiveColor) ?? d.emissiveColor
        emissiveTexture = try c.decodeIfPresent(AssetReference.self, forKey: .emissiveTexture)
        emissiveStrength = try c.decodeIfPresent(Float.self, forKey: .emissiveStrength) ?? d.emissiveStrength
        if let mode = try c.decodeIfPresent(String.self, forKey: .alphaMode) {
            alphaMode = AlphaMode(rawValue: mode.uppercased()) ?? d.alphaMode
        } else {
            alphaMode = try c.decodeIfPresent(Bool.self, forKey: .isTransparent) == true ? .blend : d.alphaMode
        }
        alphaCutoff = try c.decodeIfPresent(Float.self, forKey: .alphaCutoff) ?? d.alphaCutoff
        doubleSided = try c.decodeIfPresent(Bool.self, forKey: .doubleSided) ?? d.doubleSided
    }

    /// Writes every key except unset textures. `alphaMode` is written as "opaque", "mask" or "blend".
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shading.rawValue, forKey: .shading)
        try c.encode(baseColor, forKey: .baseColor)
        try c.encodeIfPresent(texture, forKey: .texture)
        try c.encode(filter == .nearest ? "nearest" : "linear", forKey: .filter)
        let mip = switch mipFilter { case .none: "none"; case .nearest: "nearest"; case .linear: "linear" }
        try c.encode(mip, forKey: .mipFilter)
        let address = switch addressMode { case .repeat: "repeat"; case .clampToEdge: "clampToEdge"; case .mirrorRepeat: "mirrorRepeat" }
        try c.encode(address, forKey: .addressMode)
        try c.encode(uvScale, forKey: .uvScale)
        try c.encode(uvOffset, forKey: .uvOffset)
        try c.encode(uvRotation, forKey: .uvRotation)
        try c.encode(checker, forKey: .checker)
        try c.encode(emissive, forKey: .emissive)
        try c.encode(specular, forKey: .specular)
        try c.encode(shininess, forKey: .shininess)
        try c.encode(metallic, forKey: .metallic)
        try c.encode(roughness, forKey: .roughness)
        try c.encodeIfPresent(metallicRoughnessTexture, forKey: .metallicRoughnessTexture)
        try c.encodeIfPresent(normalTexture, forKey: .normalTexture)
        try c.encode(normalScale, forKey: .normalScale)
        try c.encodeIfPresent(occlusionTexture, forKey: .occlusionTexture)
        try c.encode(occlusionStrength, forKey: .occlusionStrength)
        try c.encode(emissiveColor, forKey: .emissiveColor)
        try c.encodeIfPresent(emissiveTexture, forKey: .emissiveTexture)
        try c.encode(emissiveStrength, forKey: .emissiveStrength)
        try c.encode(alphaMode.rawValue.lowercased(), forKey: .alphaMode)
        try c.encode(alphaCutoff, forKey: .alphaCutoff)
        try c.encode(doubleSided, forKey: .doubleSided)
    }
}

/// The pixels of a `TextureAsset`.
public enum TexturePixels: Sendable {
    /// 8-bit RGBA rows top to bottom (PNG, JPEG, TGA).
    case rgba8(Image)
    /// Linear float RGBA (Radiance HDR), uploaded as `.rgba16Float`.
    case rgbaFloat(FloatImage)
    /// A block-compressed mip chain (`TextureCodec`) in one of `TextureFormat.compressedFormats`
    /// or `hdrCompressedFormats`, level 0 first.
    case compressed(format: TextureFormat, levels: [TextureMipLevel])
}

/// A texture as pixels (RGBA8 `Image`, linear `FloatImage` or a compressed mip chain), how to
/// interpret them and whether the GPU copy gets a mip chain. `SceneRenderer` uploads it with
/// `RenderDevice.makeTexture(image:srgb:generateMipmaps:)` (`.rgba16Float` for float pixels,
/// `makeTexture(compressedLevels:format:)` for compressed ones) unless
/// `SceneRenderer.textureUploader` says otherwise.
public struct TextureAsset: Sendable {
    public var pixels: TexturePixels
    /// Color data (albedo) is sRGB-encoded (`.rgba8Srgb`); data such as normal maps and masks
    /// is linear (`.rgba8Unorm`). Ignored for float pixels, which are always linear.
    public var isSRGB: Bool
    public var generatesMipmaps: Bool

    public init(image: Image, isSRGB: Bool = true, generatesMipmaps: Bool = true) {
        pixels = .rgba8(image)
        self.isSRGB = isSRGB
        self.generatesMipmaps = generatesMipmaps
    }

    public init(floatImage: FloatImage, generatesMipmaps: Bool = true) {
        pixels = .rgbaFloat(floatImage)
        isSRGB = false
        self.generatesMipmaps = generatesMipmaps
    }

    /// A compressed texture (`TextureCodec.encode`): sRGB and mipmapped as its format and level
    /// count say.
    public init(compressedLevels levels: [TextureMipLevel], format: TextureFormat) {
        precondition(format.isCompressed && !levels.isEmpty, "A compressed texture needs a compressed format and a level")
        pixels = .compressed(format: format, levels: levels)
        isSRGB = format.isSRGB
        generatesMipmaps = levels.count > 1
    }

    public init(decoded: DecodedImage, isSRGB: Bool = true, generatesMipmaps: Bool = true) {
        switch decoded {
        case .rgba8(let image): self.init(image: image, isSRGB: isSRGB, generatesMipmaps: generatesMipmaps)
        case .rgba32F(let image): self.init(floatImage: image, generatesMipmaps: generatesMipmaps)
        }
    }

    /// The 8-bit pixels. For a float texture (an HDR compressed one too) this is a clamped 0...1
    /// conversion (not sRGB encoded); use `floatImage` to read the real values. A compressed
    /// texture's level 0 is decoded (transparent black if its data is damaged).
    public var image: Image {
        get {
            switch pixels {
            case .rgba8(let image): return image
            case .rgbaFloat(let image): return Self.clamped(image)
            case .compressed(let format, let levels) where format.isHDR:
                return floatImage.map(Self.clamped)
                    ?? Image(width: levels[0].width, height: levels[0].height,
                             pixels: [UInt8](repeating: 0, count: levels[0].width * levels[0].height * 4))
            case .compressed(let format, let levels):
                return (try? TextureCodec.decode(levels[0], format: format))
                    ?? Image(width: levels[0].width, height: levels[0].height,
                             pixels: [UInt8](repeating: 0, count: levels[0].width * levels[0].height * 4))
            }
        }
        set { pixels = .rgba8(newValue) }
    }

    private static func clamped(_ image: FloatImage) -> Image {
        Image(width: image.width, height: image.height, pixels: image.pixels.map { UInt8((min(max($0, 0), 1) * 255).rounded()) })
    }

    /// The float pixels, or nil for an 8-bit texture. An HDR compressed texture's level 0 is
    /// decoded (`TextureCodec.decodeFloat`; nil if its data is damaged), e.g. for CPU-side
    /// precomputation from an environment map.
    public var floatImage: FloatImage? {
        switch pixels {
        case .rgbaFloat(let image): image
        case .compressed(let format, let levels) where format.isHDR: try? TextureCodec.decodeFloat(levels[0], format: format)
        default: nil
        }
    }

    /// Float pixels, uncompressed (`.rgba16Float` on the GPU) or in an HDR compressed format.
    public var isHDR: Bool {
        switch pixels {
        case .rgba8: false
        case .rgbaFloat: true
        case .compressed(let format, _): format.isHDR
        }
    }

    /// The compressed mip chain, or nil for RGBA8 and float pixels.
    public var compressedLevels: [TextureMipLevel]? {
        if case .compressed(_, let levels) = pixels { return levels }
        return nil
    }

    public var width: Int {
        switch pixels {
        case .rgba8(let image): image.width
        case .rgbaFloat(let image): image.width
        case .compressed(_, let levels): levels[0].width
        }
    }

    public var height: Int {
        switch pixels {
        case .rgba8(let image): image.height
        case .rgbaFloat(let image): image.height
        case .compressed(_, let levels): levels[0].height
        }
    }

    /// The format it is uploaded in (a compressed one may still become RGBA8 on a GPU without it).
    public var format: TextureFormat {
        if case .compressed(let format, _) = pixels { return format }
        return isHDR ? .rgba16Float : isSRGB ? .rgba8Srgb : .rgba8Unorm
    }

    /// Approximate GPU bytes (with a mip chain's third), for upload budgets; exact for
    /// compressed textures.
    public var gpuByteCount: Int {
        if let levels = compressedLevels { return levels.reduce(0) { $0 + $1.pixels.count } }
        let base = width * height * (isHDR ? 8 : 4)
        return generatesMipmaps ? base + base / 3 : base
    }
}

/// A prefab: entities to spawn as a unit. Two forms, one type:
/// - a node tree (`roots`): what model importers produce (a glTF or OBJ file's scene graph),
///   nodes with a name, a transform, optionally a mesh, material and skin;
/// - a scene file (`scene`, `World.save` of one subtree): a `.prefab` file, any components.
///
/// Spawn either with `World.instantiate(_:under:)` (a plain copy) or, for a copy that stays
/// linked to its asset and keeps overrides, `World.instantiatePrefab` (see PrefabInstance.swift).
public struct PrefabAsset: Equatable, Sendable, Codable {
    public var roots: [PrefabNode]
    /// A `.prefab` file's entities as scene-file data; when set, `roots` is empty.
    public var scene: Data?
    /// A variant: another prefab plus this one's overrides (`roots` is empty and `scene` nil);
    /// see `PrefabVariant`.
    public var variant: PrefabVariant?

    public init(roots: [PrefabNode]) {
        self.roots = roots
        scene = nil
    }

    /// A prefab holding a scene file (`World.save` of its root).
    public init(scene: Data) {
        roots = []
        self.scene = scene
    }

    /// A prefab based on another prefab (a `.prefab` variant file).
    public init(variant: PrefabVariant) {
        roots = []
        scene = nil
        self.variant = variant
    }

    private enum CodingKeys: String, CodingKey { case roots, scene, variant }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        roots = try c.decodeIfPresent([PrefabNode].self, forKey: .roots) ?? []
        scene = try c.decodeIfPresent(String.self, forKey: .scene).map { Data($0.utf8) }
        variant = try c.decodeIfPresent(PrefabVariant.self, forKey: .variant)
    }

    /// The scene, when there is one, as text (it is JSON), so cached imports stay readable.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(roots, forKey: .roots)
        try c.encodeIfPresent(scene.map { String(decoding: $0, as: UTF8.self) }, forKey: .scene)
        try c.encodeIfPresent(variant, forKey: .variant)
    }
}

/// One node of a `PrefabAsset`. A node draws at most one mesh; a source node with several
/// mesh/material pairs (glTF primitives) becomes one child node per pair.
public struct PrefabNode: Equatable, Sendable, Codable {
    public var name: String
    public var transform: Transform
    public var mesh: AssetReference?
    public var material: AssetReference?
    /// For a skinned mesh: the joints that pose it (instantiating adds a `Skin`).
    public var skin: PrefabSkin?
    /// Animation that plays on the node (instantiating adds the `FieldAnimator`); mesh builds use it.
    public var animator: FieldAnimator?
    /// A `.postfx` import's profile (the prefab spawns nothing for it; cameras and volumes read it).
    public var postFX: PostProcessSettings?
    public var children: [PrefabNode]

    public init(name: String, transform: Transform = Transform(), mesh: AssetReference? = nil,
                material: AssetReference? = nil, skin: PrefabSkin? = nil, animator: FieldAnimator? = nil,
                children: [PrefabNode] = [], postFX: PostProcessSettings? = nil) {
        self.postFX = postFX
        self.name = name
        self.transform = transform
        self.mesh = mesh
        self.material = material
        self.skin = skin
        self.animator = animator
        self.children = children
    }
}

/// A `PrefabNode`'s skin: its joints as node numbers (the nodes of the whole prefab in depth-first
/// order, roots first, starting at 0; -1 for a joint outside the prefab, which stays in the
/// bind pose) and their inverse bind matrices, as in `Skin`.
public struct PrefabSkin: Equatable, Sendable, Codable {
    public var joints: [Int]
    public var inverseBindMatrices: [Mat4]

    public init(joints: [Int], inverseBindMatrices: [Mat4]) {
        self.joints = joints
        self.inverseBindMatrices = inverseBindMatrices
    }
}

extension World {
    /// Spawns a copy of `prefab` under `parent` and returns its root entities. A node tree's
    /// nodes become entities with `Name` and `Transform`, plus a `MeshRenderer` for nodes with
    /// a mesh (`.default` material when a node has none) and a `Skin` for skinned ones and a `FieldAnimator` for animated ones, keeping
    /// the hierarchy. A scene-file prefab is loaded with new entity ids (nothing is spawned if it
    /// doesn't load). The copy isn't linked to the asset; see `instantiatePrefab` for that.
    @discardableResult
    public func instantiate(_ prefab: PrefabAsset, under parent: Entity? = nil) -> [Entity] {
        if let scene = prefab.scene {
            guard let roots = try? load(scene, under: parent, ids: .regenerate) else { return [] }
            return roots
        }
        var order: [Entity] = []
        var skinned: [(Entity, PrefabSkin)] = []
        func spawn(_ node: PrefabNode, parent: Entity?) -> Entity {
            let entity = self.spawn(node.transform, Name(node.name))
            order.append(entity)
            if let mesh = node.mesh {
                add(MeshRenderer(mesh: MeshHandle(mesh), material: node.material.map { MaterialHandle($0) } ?? .default), to: entity)
            }
            if let animator = node.animator { add(animator, to: entity) }
            if let skin = node.skin { skinned.append((entity, skin)) }
            if let parent { setParent(entity, to: parent) }
            for child in node.children { _ = spawn(child, parent: entity) }
            return entity
        }
        let roots = prefab.roots.map { spawn($0, parent: parent) }
        // Joints may come after the meshes they pose, so skins are bound once every node exists.
        for (entity, skin) in skinned {
            add(Skin(joints: skin.joints.map { order.indices.contains($0) ? order[$0] : .invalid },
                     inverseBindMatrices: skin.inverseBindMatrices), to: entity)
        }
        return roots
    }
}
