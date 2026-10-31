import Foundation

/// A 3D model read from a file, entirely on the CPU: meshes, materials, textures with their
/// encoded images, and a node tree. Produced by `GLTFReader`; nothing in it touches a
/// `RenderDevice`, so it can be built on a background thread. Turn it into GPU resources and
/// entities with `register(with:keyPrefix:textures:)` and `instantiate(in:under:meshes:materials:)`
/// (or supply your own mesh and material handles to `instantiate`).
///
/// Coordinates follow the engine (and glTF): right-handed, +Y up, counter-clockwise front
/// faces, texture coordinates with (0, 0) at the top-left of the image, meters.
public struct ImportedModel: Sendable {
    /// Every mesh in the file, indexed like the file's meshes.
    public var meshes: [ImportedMesh] = []
    /// Every material in the file, indexed like the file's materials.
    public var materials: [ImportedMaterial] = []
    /// Every texture (an image plus sampler state), indexed like the file's textures.
    public var textures: [ImportedTexture] = []
    /// Every image, still encoded (PNG, JPEG, …), indexed like the file's images.
    public var images: [ImportedImage] = []
    /// Every node, indexed like the file's nodes. Nodes outside `scenes[sceneIndex]` are kept
    /// too (they are just not instantiated).
    public var nodes: [ImportedNode] = []
    /// The file's scenes.
    public var scenes: [ImportedSceneInfo] = []
    /// The scene to instantiate: the file's `scene`, else the first one, else nil (then
    /// `roots` lists every node without a parent).
    public var sceneIndex: Int?
    /// Root nodes of the selected scene, in file order.
    public var roots: [Int] = []
    /// Things that were skipped or approximated (unsupported primitive modes, ignored
    /// extensions, …). Unreadable data throws instead.
    public var warnings: [String] = []
    /// `asset.generator` and `asset.copyright`, for attribution.
    public var generator: String?
    public var copyright: String?

    public init() {}
}

/// A named scene: the root nodes to instantiate.
public struct ImportedSceneInfo: Sendable, Equatable {
    public var name: String?
    public var roots: [Int]

    public init(name: String?, roots: [Int]) {
        self.name = name
        self.roots = roots
    }
}

/// A mesh: one or more primitives, each with its own geometry and material.
public struct ImportedMesh: Sendable {
    public var name: String?
    public var primitives: [ImportedPrimitive]

    public init(name: String?, primitives: [ImportedPrimitive]) {
        self.name = name
        self.primitives = primitives
    }
}

/// One drawable part of a mesh: triangles in the engine's vertex format plus the vertex
/// attributes `MeshVertex` has no slot for yet. All per-vertex arrays have
/// `geometry.vertices.count` entries.
public struct ImportedPrimitive: Sendable {
    /// Positions, normals (generated when the file has none) and `TEXCOORD_0` (zero when
    /// missing), as an indexed triangle list with counter-clockwise front faces.
    public var geometry: MeshGeometry
    /// `TANGENT`: xyz is the tangent, w (±1) the bitangent sign. nil when the file has none.
    public var tangents: [Vec4]?
    /// `TEXCOORD_1`, for occlusion or light maps.
    public var texCoords1: [Vec2]?
    /// `COLOR_0` as linear RGBA (RGB inputs get alpha 1).
    public var colors: [Vec4]?
    /// Index into `ImportedModel.materials`, or nil for the glTF default material.
    public var material: Int?
    /// The file had no normals, so they were generated (see `GLTFReader.Options.normals`).
    public var generatedNormals: Bool

    public init(geometry: MeshGeometry, tangents: [Vec4]? = nil, texCoords1: [Vec2]? = nil, colors: [Vec4]? = nil,
                material: Int? = nil, generatedNormals: Bool = false) {
        self.geometry = geometry
        self.tangents = tangents
        self.texCoords1 = texCoords1
        self.colors = colors
        self.material = material
        self.generatedNormals = generatedNormals
    }
}

/// A node of the scene tree: a local transform, an optional mesh and children.
public struct ImportedNode: Sendable {
    public var name: String?
    /// Local transform relative to the parent. A `matrix` in the file is decomposed (shear is lost).
    public var transform: Transform
    /// Index into `ImportedModel.meshes`.
    public var mesh: Int?
    /// Indices into `ImportedModel.nodes`.
    public var children: [Int]
    /// Index of the parent node, nil for roots.
    public var parent: Int?

    public init(name: String?, transform: Transform, mesh: Int? = nil, children: [Int] = [], parent: Int? = nil) {
        self.name = name
        self.transform = transform
        self.mesh = mesh
        self.children = children
        self.parent = parent
    }
}

/// How a texture's texels are to be interpreted.
public enum TextureColorSpace: String, Sendable, Codable {
    /// Color data (base color, emissive): create the texture as `.rgba8Srgb`.
    case sRGB
    /// Non-color data (normals, metallic-roughness, occlusion): create it as `.rgba8Unorm`.
    case linear
}

/// What a material uses a texture for. Decides its color space.
public enum TextureSlot: String, Sendable, Codable, CaseIterable {
    case baseColor, metallicRoughness, normal, occlusion, emissive

    /// `.sRGB` for color (`baseColor`, `emissive`), `.linear` for data.
    public var colorSpace: TextureColorSpace {
        switch self {
        case .baseColor, .emissive: return .sRGB
        case .metallicRoughness, .normal, .occlusion: return .linear
        }
    }
}

/// A texture: an image and how to sample it.
public struct ImportedTexture: Sendable {
    public var name: String?
    /// Index into `ImportedModel.images`; nil when the file names no (supported) image.
    public var image: Int?
    public var sampler: ImportedSampler
    /// Every slot a material uses this texture in.
    public var slots: Set<TextureSlot>

    public init(name: String?, image: Int?, sampler: ImportedSampler, slots: Set<TextureSlot> = []) {
        self.name = name
        self.image = image
        self.sampler = sampler
        self.slots = slots
    }

    /// `.sRGB` when any material uses the texture as color (base color, emissive), else
    /// `.linear`. A texture used both ways is rare; the reader warns about it.
    public var colorSpace: TextureColorSpace {
        slots.contains { $0.colorSpace == .sRGB } ? .sRGB : .linear
    }
}

/// Texture sampling state from a glTF sampler, with separate U and V wrap modes.
public struct ImportedSampler: Sendable, Equatable {
    public var magFilter: SamplerFilter
    public var minFilter: SamplerFilter
    /// `.none` when the file asks for a minification filter without mipmaps.
    public var mipFilter: SamplerMipFilter
    public var wrapU: SamplerAddressMode
    public var wrapV: SamplerAddressMode

    /// The glTF default when a texture has no sampler: linear filtering with mipmaps, repeat.
    public init(magFilter: SamplerFilter = .linear, minFilter: SamplerFilter = .linear,
                mipFilter: SamplerMipFilter = .linear, wrapU: SamplerAddressMode = .repeat,
                wrapV: SamplerAddressMode = .repeat) {
        self.magFilter = magFilter
        self.minFilter = minFilter
        self.mipFilter = mipFilter
        self.wrapU = wrapU
        self.wrapV = wrapV
    }

    /// The engine's sampler. `SamplerDescriptor` has one address mode for both axes, so a
    /// sampler with different U and V modes uses its U mode.
    public var descriptor: SamplerDescriptor {
        SamplerDescriptor(minFilter: minFilter, magFilter: magFilter, mipFilter: mipFilter, addressMode: wrapU)
    }

    /// Whether the texture needs a mip chain.
    public var usesMipmaps: Bool { mipFilter != .none }
}

/// An image as stored in the file: encoded bytes (PNG, JPEG, KTX2, …) and the MIME type when
/// known. The importer does not decode images; decode them with whatever decoder the caller
/// has, e.g. `model.decodeImages(using:)`.
public struct ImportedImage: Sendable {
    public var name: String?
    /// The `mimeType` from the file, or guessed from the URI's extension or the data's magic
    /// bytes (`image/png`, `image/jpeg`, …). nil when unknown.
    public var mimeType: String?
    /// The URI the image came from (relative to the file, or a `data:` URI shortened to its
    /// header), nil for images stored in a buffer view. For display and asset dependencies.
    public var uri: String?
    public var data: Data

    public init(name: String?, mimeType: String?, uri: String?, data: Data) {
        self.name = name
        self.mimeType = mimeType
        self.uri = uri
        self.data = data
    }
}

/// `KHR_texture_transform`: UVs are transformed as `offset + rotate(rotation) * (scale * uv)`.
public struct TextureTransform: Sendable, Equatable {
    public var offset: Vec2
    /// Radians, counter-clockwise in UV space.
    public var rotation: Float
    public var scale: Vec2
    /// Overrides the texture reference's texture coordinate set when set.
    public var texCoord: Int?

    public init(offset: Vec2 = .zero, rotation: Float = 0, scale: Vec2 = Vec2(1, 1), texCoord: Int? = nil) {
        self.offset = offset
        self.rotation = rotation
        self.scale = scale
        self.texCoord = texCoord
    }

    /// Only a scale, which `Material.uvScale` can express.
    public var isScaleOnly: Bool { offset == .zero && rotation == 0 }
}

/// A material's use of a texture.
public struct TextureReference: Sendable, Equatable {
    /// Index into `ImportedModel.textures`.
    public var texture: Int
    /// Which `TEXCOORD_n` set to sample with (0 or 1 here).
    public var texCoord: Int
    public var transform: TextureTransform?

    public init(texture: Int, texCoord: Int = 0, transform: TextureTransform? = nil) {
        self.texture = texture
        self.texCoord = texCoord
        self.transform = transform
    }
}

/// glTF `alphaMode`.
public enum AlphaMode: String, Sendable, Codable {
    /// Alpha is ignored; fully opaque.
    case opaque = "OPAQUE"
    /// Alpha below `alphaCutoff` is discarded, the rest is opaque.
    case mask = "MASK"
    /// Alpha blended.
    case blend = "BLEND"
}

/// A glTF metallic-roughness material, with every parameter the file gave. Colors and
/// factors are linear. `engineMaterial(textures:sampler:)` maps it onto the engine's PBR
/// `Material` (`materialAsset` onto its data form).
public struct ImportedMaterial: Sendable, Equatable {
    public var name: String?
    /// Linear RGBA, multiplied with the base color texture.
    public var baseColorFactor: Vec4 = Vec4(1, 1, 1, 1)
    /// sRGB color in RGB, linear alpha in A.
    public var baseColorTexture: TextureReference?
    public var metallicFactor: Float = 1
    public var roughnessFactor: Float = 1
    /// Linear: roughness in G, metalness in B.
    public var metallicRoughnessTexture: TextureReference?
    /// Linear tangent-space normal map.
    public var normalTexture: TextureReference?
    public var normalScale: Float = 1
    /// Linear: occlusion in R.
    public var occlusionTexture: TextureReference?
    public var occlusionStrength: Float = 1
    /// sRGB emissive color, multiplied with `emissiveFactor`.
    public var emissiveTexture: TextureReference?
    /// Linear RGB.
    public var emissiveFactor: Vec3 = .zero
    /// `KHR_materials_emissive_strength` (1 without it).
    public var emissiveStrength: Float = 1
    public var alphaMode: AlphaMode = .opaque
    /// Used only with `.mask`.
    public var alphaCutoff: Float = 0.5
    public var doubleSided: Bool = false
    /// `KHR_materials_unlit`: shade with the base color only.
    public var unlit: Bool = false

    public init(name: String? = nil) {
        self.name = name
    }

    /// The glTF default material (used by primitives without one): white, fully metallic and rough.
    public static let gltfDefault = ImportedMaterial(name: "Default")

    /// Every texture reference with its slot.
    public var textureReferences: [(slot: TextureSlot, reference: TextureReference)] {
        var refs: [(TextureSlot, TextureReference)] = []
        if let t = baseColorTexture { refs.append((.baseColor, t)) }
        if let t = metallicRoughnessTexture { refs.append((.metallicRoughness, t)) }
        if let t = normalTexture { refs.append((.normal, t)) }
        if let t = occlusionTexture { refs.append((.occlusion, t)) }
        if let t = emissiveTexture { refs.append((.emissive, t)) }
        return refs
    }
}

extension ImportedMaterial {
    /// The texture whose sampler and `KHR_texture_transform` the engine material uses for all
    /// its textures (a `Material` has one sampler and one UV transform): the base color
    /// texture, else the first texture in slot order.
    public var primaryTexture: TextureReference? { textureReferences.first?.reference }

    /// The engine's PBR `Material` for this glTF material:
    /// - base color, metallic and roughness factors, normal scale, occlusion strength,
    ///   emissive factor times `KHR_materials_emissive_strength`, alpha mode and cutoff,
    ///   double-sided carry over; `.opaque` forces alpha to 1; unlit sets `emissive` to 1;
    /// - `textures` supplies the GPU texture of each of the five texture references (created
    ///   in the slot's color space, see `TextureSlot.colorSpace`; nil leaves the slot empty);
    /// - `sampler` (the `primaryTexture`'s) and the primary texture's transform (offset,
    ///   rotation, scale) apply to every texture.
    ///
    /// Not mapped: per-texture samplers and transforms when they differ, `TEXCOORD_1` (every
    /// texture samples `TEXCOORD_0`), separate U/V wrap modes (U's is used).
    public func engineMaterial(textures: (TextureReference) -> GPUTexture? = { _ in nil },
                               sampler: ImportedSampler? = nil) -> Material {
        var material = materialAsset(sampler: sampler).material(texture: nil)
        material.sampler = (sampler ?? ImportedSampler()).descriptor
        material.texture = baseColorTexture.flatMap(textures)
        material.metallicRoughnessTexture = metallicRoughnessTexture.flatMap(textures)
        material.normalTexture = normalTexture.flatMap(textures)
        material.occlusionTexture = occlusionTexture.flatMap(textures)
        material.emissiveTexture = emissiveTexture.flatMap(textures)
        return material
    }

    /// The same mapping as `engineMaterial`, as data for the asset database: textures are
    /// `AssetReference`s from `textures`, and the sampler keeps only its mag filter
    /// (`MaterialAsset` has one filter for both).
    public func materialAsset(textures: (TextureReference) -> AssetReference? = { _ in nil },
                              sampler: ImportedSampler? = nil) -> MaterialAsset {
        var color = baseColorFactor
        if alphaMode == .opaque { color.w = 1 }
        let transform = primaryTexture?.transform ?? TextureTransform()
        let sampler = (sampler ?? ImportedSampler()).descriptor
        return MaterialAsset(
            shading: .pbr, baseColor: color, texture: baseColorTexture.flatMap(textures),
            filter: sampler.magFilter, mipFilter: sampler.mipFilter, addressMode: sampler.addressMode,
            uvScale: transform.scale, uvOffset: transform.offset, uvRotation: transform.rotation,
            emissive: unlit ? 1 : 0, metallic: min(max(metallicFactor, 0), 1), roughness: min(max(roughnessFactor, 0), 1),
            metallicRoughnessTexture: metallicRoughnessTexture.flatMap(textures), normalTexture: normalTexture.flatMap(textures),
            normalScale: normalScale, occlusionTexture: occlusionTexture.flatMap(textures),
            occlusionStrength: min(max(occlusionStrength, 0), 1), emissiveColor: emissiveFactor,
            emissiveTexture: emissiveTexture.flatMap(textures), emissiveStrength: emissiveStrength,
            alphaMode: alphaMode, alphaCutoff: alphaCutoff, doubleSided: doubleSided)
    }
}

extension ImportedModel {
    /// The material of `primitive` (the glTF default material when it has none).
    public func material(of primitive: ImportedPrimitive) -> ImportedMaterial {
        primitive.material.map { materials[$0] } ?? .gltfDefault
    }

    /// Decodes every image with `decoder`, which gets the encoded bytes and the MIME type (if
    /// known). Images that fail to decode are nil, and the error is returned with them.
    public func decodeImages(using decoder: (Data, String?) throws -> Image) -> [Result<Image, any Error>] {
        images.map { image in Result { try decoder(image.data, image.mimeType) } }
    }

    /// Total vertex and index counts over all primitives.
    public var vertexCount: Int { meshes.reduce(0) { $0 + $1.primitives.reduce(0) { $0 + $1.geometry.vertices.count } } }
    public var triangleCount: Int { meshes.reduce(0) { $0 + $1.primitives.reduce(0) { $0 + $1.geometry.indices.count / 3 } } }

    /// Bounds of the selected scene in model space (every mesh instance under its node's
    /// world transform), or nil when it draws nothing.
    public var sceneBounds: Bounds? {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        var stack = roots.map { ($0, Mat4.identity) }
        while let (index, parentMatrix) = stack.popLast() {
            let node = nodes[index]
            let matrix = parentMatrix * node.transform.matrix
            if let mesh = node.mesh {
                for primitive in meshes[mesh].primitives where !primitive.geometry.vertices.isEmpty {
                    let b = primitive.geometry.bounds.transformed(by: matrix)
                    lo = pointwiseMin(lo, b.center - b.halfExtent)
                    hi = pointwiseMax(hi, b.center + b.halfExtent)
                }
            }
            stack += node.children.map { ($0, matrix) }
        }
        guard lo.x <= hi.x else { return nil }
        return Bounds(center: (lo + hi) / 2, halfExtent: (hi - lo) / 2)
    }
}
