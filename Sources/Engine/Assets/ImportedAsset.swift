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

/// A `Material` as data: the same parameters, with the texture named by an `AssetReference`
/// instead of held as a GPU texture. `SceneRenderer` turns it into a `Material` when it is
/// first used (uploading the texture too). Codable, with every key optional, so it is also the
/// `.material` file format (see `MaterialFileImporter`).
public struct MaterialAsset: Equatable, Sendable, Codable {
    public var baseColor: Vec4
    /// A `.texture` object: another asset's (`AssetReference(textureID)`) or one from the same
    /// file (`ImportContext.reference(_:)`).
    public var texture: AssetReference?
    public var filter: SamplerFilter
    public var mipFilter: SamplerMipFilter
    public var addressMode: SamplerAddressMode
    public var uvScale: Vec2
    public var checker: Bool
    public var emissive: Float
    public var specular: Float
    public var shininess: Float
    public var doubleSided: Bool
    public var isTransparent: Bool

    public init(baseColor: Vec4 = Vec4(0.8, 0.8, 0.8, 1), texture: AssetReference? = nil, filter: SamplerFilter = .linear,
                mipFilter: SamplerMipFilter = .linear, addressMode: SamplerAddressMode = .repeat, uvScale: Vec2 = Vec2(1, 1),
                checker: Bool = false, emissive: Float = 0, specular: Float = 0.35, shininess: Float = 48,
                doubleSided: Bool = false, isTransparent: Bool = false) {
        self.baseColor = baseColor
        self.texture = texture
        self.filter = filter
        self.mipFilter = mipFilter
        self.addressMode = addressMode
        self.uvScale = uvScale
        self.checker = checker
        self.emissive = emissive
        self.specular = specular
        self.shininess = shininess
        self.doubleSided = doubleSided
        self.isTransparent = isTransparent
    }

    /// The `Material` with `texture` as its GPU texture.
    public func material(texture gpuTexture: GPUTexture?) -> Material {
        Material(baseColor: baseColor, texture: gpuTexture,
                 sampler: SamplerDescriptor(filter: filter, mipFilter: mipFilter, addressMode: addressMode),
                 uvScale: uvScale, checker: checker, emissive: emissive, specular: specular, shininess: shininess,
                 doubleSided: doubleSided, isTransparent: isTransparent)
    }

    private enum CodingKeys: String, CodingKey {
        case baseColor, texture, filter, mipFilter, addressMode, uvScale, checker, emissive, specular, shininess
        case doubleSided, isTransparent
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialAsset()
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
        checker = try c.decodeIfPresent(Bool.self, forKey: .checker) ?? d.checker
        emissive = try c.decodeIfPresent(Float.self, forKey: .emissive) ?? d.emissive
        specular = try c.decodeIfPresent(Float.self, forKey: .specular) ?? d.specular
        shininess = try c.decodeIfPresent(Float.self, forKey: .shininess) ?? d.shininess
        doubleSided = try c.decodeIfPresent(Bool.self, forKey: .doubleSided) ?? d.doubleSided
        isTransparent = try c.decodeIfPresent(Bool.self, forKey: .isTransparent) ?? d.isTransparent
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(baseColor, forKey: .baseColor)
        try c.encodeIfPresent(texture, forKey: .texture)
        try c.encode(filter == .nearest ? "nearest" : "linear", forKey: .filter)
        let mip = switch mipFilter { case .none: "none"; case .nearest: "nearest"; case .linear: "linear" }
        try c.encode(mip, forKey: .mipFilter)
        let address = switch addressMode { case .repeat: "repeat"; case .clampToEdge: "clampToEdge"; case .mirrorRepeat: "mirrorRepeat" }
        try c.encode(address, forKey: .addressMode)
        try c.encode(uvScale, forKey: .uvScale)
        try c.encode(checker, forKey: .checker)
        try c.encode(emissive, forKey: .emissive)
        try c.encode(specular, forKey: .specular)
        try c.encode(shininess, forKey: .shininess)
        try c.encode(doubleSided, forKey: .doubleSided)
        try c.encode(isTransparent, forKey: .isTransparent)
    }
}

/// A texture as pixels: RGBA8 rows top to bottom (`Image`), how to interpret them and whether
/// the GPU copy gets a mip chain. `SceneRenderer` uploads it with
/// `RenderDevice.makeTexture(pixels:width:height:format:generateMipmaps:)` unless
/// `SceneRenderer.textureUploader` says otherwise.
public struct TextureAsset: Sendable {
    public var image: Image
    /// Color data (albedo) is sRGB-encoded (`.rgba8Srgb`); data such as normal maps and masks
    /// is linear (`.rgba8Unorm`).
    public var isSRGB: Bool
    public var generatesMipmaps: Bool

    public init(image: Image, isSRGB: Bool = true, generatesMipmaps: Bool = true) {
        self.image = image
        self.isSRGB = isSRGB
        self.generatesMipmaps = generatesMipmaps
    }

    public var format: TextureFormat { isSRGB ? .rgba8Srgb : .rgba8Unorm }
}

/// A node hierarchy (a model's scene graph, a prefab): nodes with a name, a local transform,
/// optionally a mesh and material to draw, and children. Spawn it with `World.instantiate(_:)`.
public struct PrefabAsset: Equatable, Sendable, Codable {
    public var roots: [PrefabNode]

    public init(roots: [PrefabNode]) { self.roots = roots }
}

/// One node of a `PrefabAsset`. A node draws at most one mesh; a source node with several
/// mesh/material pairs (glTF primitives) becomes one child node per pair.
public struct PrefabNode: Equatable, Sendable, Codable {
    public var name: String
    public var transform: Transform
    public var mesh: AssetReference?
    public var material: AssetReference?
    public var children: [PrefabNode]

    public init(name: String, transform: Transform = Transform(), mesh: AssetReference? = nil,
                material: AssetReference? = nil, children: [PrefabNode] = []) {
        self.name = name
        self.transform = transform
        self.mesh = mesh
        self.material = material
        self.children = children
    }
}

extension World {
    /// Spawns `prefab`'s nodes as entities (each with `Name` and `Transform`, plus a
    /// `MeshRenderer` for nodes with a mesh; `.default` material when a node has none) under
    /// `parent`, keeping the hierarchy. Returns the root entities.
    @discardableResult
    public func instantiate(_ prefab: PrefabAsset, under parent: Entity? = nil) -> [Entity] {
        func spawn(_ node: PrefabNode, parent: Entity?) -> Entity {
            let entity = self.spawn(node.transform, Name(node.name))
            if let mesh = node.mesh {
                add(MeshRenderer(mesh: MeshHandle(mesh), material: node.material.map { MaterialHandle($0) } ?? .default), to: entity)
            }
            if let parent { setParent(entity, to: parent) }
            for child in node.children { _ = spawn(child, parent: entity) }
            return entity
        }
        return prefab.roots.map { spawn($0, parent: parent) }
    }
}
