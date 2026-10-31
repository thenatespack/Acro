import Foundation

/// How `SceneRenderer` lights a material.
public enum ShadingModel: String, Sendable, Codable, CaseIterable {
    /// Metallic-roughness PBR: Cook-Torrance GGX specular with Smith height-correlated
    /// visibility and Schlick Fresnel, Lambert diffuse, and an ambient term from the
    /// hemisphere light (diffuse irradiance plus a split-sum specular approximation).
    case pbr
    /// The engine's original Blinn-Phong model (`specular`, `shininess`; metallic and
    /// roughness are ignored). The built-in default material uses it, and `.material` files
    /// written before PBR existed load with it, so older scenes keep their look.
    case blinnPhong
}

/// Surface parameters for `SceneRenderer`'s lit shader. A GPU resource (it holds textures), so
/// entities reference it through a `MaterialHandle`; register it with
/// `SceneRenderer.registerMaterial(_:key:)`.
///
/// Textures follow glTF's metallic-roughness conventions: base color and emissive are color
/// (create them `.rgba8Srgb`), metallic-roughness, normal and occlusion are data (`.rgba8Unorm`).
/// Every texture is sampled with `sampler`, at the mesh's UVs transformed by `uvScale`,
/// `uvRotation` and `uvOffset`. A missing texture counts as white (no normal map: the mesh
/// normal). Everything but metallic and roughness also applies to `.blinnPhong`.
public struct Material {
    public var shading: ShadingModel
    /// Linear RGB and opacity, multiplied with `texture` and the `MeshRenderer`'s tint and opacity.
    public var baseColor: Vec4
    /// Base color (albedo) texture: sRGB color, alpha in A.
    public var texture: GPUTexture?
    public var sampler: SamplerDescriptor
    /// UV transform, glTF `KHR_texture_transform` order: `offset + rotate(rotation) * (scale * uv)`.
    public var uvScale: Vec2
    public var uvOffset: Vec2
    /// Radians, counter-clockwise in UV space.
    public var uvRotation: Float
    /// Darkens alternate 2x2-unit cells of a world-space XZ checkerboard (for floors).
    public var checker: Bool
    /// 0 is lit, 1 shows the albedo unlit (fog still applies). glTF `KHR_materials_unlit`.
    /// For light-emitting surfaces use `emissiveColor`.
    public var emissive: Float
    /// Blinn-Phong highlight strength and exponent (`.blinnPhong` only).
    public var specular: Float
    public var shininess: Float
    /// 0 dielectric .. 1 metal, multiplied with `metallicRoughnessTexture`'s blue channel (`.pbr`).
    public var metallic: Float
    /// Perceptual roughness, 0 mirror .. 1 rough, multiplied with `metallicRoughnessTexture`'s
    /// green channel (`.pbr`; clamped to at least 0.045 in the shader).
    public var roughness: Float
    /// Linear: roughness in G, metalness in B (glTF; R is often occlusion, see `occlusionTexture`).
    public var metallicRoughnessTexture: GPUTexture?
    /// Linear tangent-space normal map (+X right, +Y up, glTF / OpenGL convention), using the
    /// mesh's tangents (`MeshVertex.tangent`; generated at registration when missing).
    public var normalTexture: GPUTexture?
    /// Scales the normal map's X and Y.
    public var normalScale: Float
    /// Linear: ambient occlusion in R. Darkens the ambient light only.
    public var occlusionTexture: GPUTexture?
    /// 0 ignores `occlusionTexture`, 1 applies it fully.
    public var occlusionStrength: Float
    /// Linear RGB light the surface emits, multiplied with `emissiveTexture` and `emissiveStrength`
    /// and added after lighting.
    public var emissiveColor: Vec3
    /// sRGB emissive color.
    public var emissiveTexture: GPUTexture?
    public var emissiveStrength: Float
    /// `.blend` draws in the transparent pass; `.mask` discards fragments (also in the shadow
    /// map) whose base color alpha is below `alphaCutoff` and draws the rest opaque.
    public var alphaMode: AlphaMode
    public var alphaCutoff: Float
    /// Draws back faces too (no culling). PBR materials light back faces with the flipped normal.
    public var doubleSided: Bool

    public init(shading: ShadingModel = .pbr, baseColor: Vec4 = Vec4(0.8, 0.8, 0.8, 1), texture: GPUTexture? = nil,
                sampler: SamplerDescriptor = SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear, addressMode: .repeat),
                uvScale: Vec2 = Vec2(1, 1), uvOffset: Vec2 = .zero, uvRotation: Float = 0, checker: Bool = false,
                emissive: Float = 0, specular: Float = 0.35, shininess: Float = 48, metallic: Float = 0, roughness: Float = 0.5,
                metallicRoughnessTexture: GPUTexture? = nil, normalTexture: GPUTexture? = nil, normalScale: Float = 1,
                occlusionTexture: GPUTexture? = nil, occlusionStrength: Float = 1, emissiveColor: Vec3 = .zero,
                emissiveTexture: GPUTexture? = nil, emissiveStrength: Float = 1, alphaMode: AlphaMode = .opaque,
                alphaCutoff: Float = 0.5, doubleSided: Bool = false) {
        self.shading = shading
        self.baseColor = baseColor
        self.texture = texture
        self.sampler = sampler
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

    /// Always draws in the transparent pass, even at full opacity (`alphaMode == .blend`).
    public var isTransparent: Bool {
        get { alphaMode == .blend }
        set { alphaMode = newValue ? .blend : (alphaMode == .blend ? .opaque : alphaMode) }
    }

    /// Whether entities with this material always go to the transparent pass: blended, or not
    /// alpha-tested with a base alpha below 1.
    var blends: Bool { alphaMode == .blend || (alphaMode == .opaque && baseColor.w < 1) }

    /// Whether it draws with the alpha-tested shader variants (`alphaMode == .mask`).
    var alphaTested: Bool { alphaMode == .mask }

    /// The UV transform as the rows of a 2x3 matrix: `uv' = (dot(row0.xy, uv) + row0.z, dot(row1.xy, uv) + row1.z)`.
    var uvTransformRows: (Vec4, Vec4) {
        let c = cosf(uvRotation), s = sinf(uvRotation)
        // offset + [c s; -s c] * (scale * uv), the KHR_texture_transform matrix.
        if uvRotation == 0 { return (Vec4(uvScale.x, 0, uvOffset.x, 0), Vec4(0, uvScale.y, uvOffset.y, 0)) }
        return (Vec4(c * uvScale.x, s * uvScale.y, uvOffset.x, 0), Vec4(-s * uvScale.x, c * uvScale.y, uvOffset.y, 0))
    }
}

/// What the CPU side of `SceneRenderer` needs to know about a material to sort and batch it.
public struct MaterialTraits: Equatable, Sendable {
    /// Always drawn in the transparent pass (`Material.isTransparent` or base alpha < 1).
    public var blends: Bool
    /// Alpha-tested (`AlphaMode.mask`): its shadow casters are batched per material, since the
    /// shadow pass samples its base color alpha.
    public var alphaTested: Bool

    public init(blends: Bool = false, alphaTested: Bool = false) {
        self.blends = blends
        self.alphaTested = alphaTested
    }
}

/// Assets by key, with dense integer ids for fast per-frame lookups. Keys are registered
/// once; registering a key again replaces its value and keeps its id.
public struct AssetRegistry<Value> {
    public private(set) var keys: [String] = []
    public private(set) var values: [Value] = []
    private var ids: [String: Int] = [:]
    /// One-entry cache: consecutive lookups usually ask for the same key.
    private var last: (key: String, id: Int)?

    public init() {}

    public var count: Int { values.count }

    /// Adds or replaces `key`'s value and returns its id.
    @discardableResult
    public mutating func register(_ value: Value, key: String) -> Int {
        if let id = ids[key] {
            values[id] = value
            return id
        }
        let id = values.count
        ids[key] = id
        keys.append(key)
        values.append(value)
        return id
    }

    /// The id of `key`, or nil if it isn't registered.
    public mutating func id(of key: String) -> Int? {
        if let last, last.key == key { return last.id }
        guard let id = ids[key] else { return nil }
        last = (key, id)
        return id
    }

    public func contains(_ key: String) -> Bool { ids[key] != nil }

    public subscript(id: Int) -> Value { values[id] }

    public subscript(key: String) -> Value? { ids[key].map { values[$0] } }
}
