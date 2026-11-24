#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// How `SceneRenderer` lights a material.
public enum ShadingModel: String, Sendable, Codable, CaseIterable {
    /// Metallic-roughness PBR: Cook-Torrance GGX specular with Smith height-correlated
    /// visibility and Schlick Fresnel, Lambert diffuse, and an ambient term from the
    /// hemisphere light or the sky's image-based lighting (diffuse irradiance plus split-sum specular).
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
    /// Draws back faces too (no culling). PBR materials light back faces with the flipped normal
    /// (unless translucent).
    public var doubleSided: Bool
    /// 0...1 (PBR): light through a thin surface such as a leaf: the side away from the light glows
    /// with the base color, and back faces keep their normals (foliage cards' bent normals). 0: none.
    public var translucency: Float = 0
    /// A compiled material graph (`MaterialAsset.graph`): draws with its shader variant, which
    /// computes the PBR inputs itself. Its textures are in the five texture fields, in slot order;
    /// the color, factor and UV fields are unused.
    public var graph: MaterialGraphProgram?
    /// Worn convex edges (see `EdgeWear`): nil draws none. Needs a mesh with edge coordinates in
    /// its tangents (`EdgeWear.encode`); not used by material graphs.
    public var edgeWear: EdgeWear?
    /// Sways in the scene's wind (`SceneEnvironment.wind`, see Wind.swift): drawn with the wind
    /// vertex shaders in every pass. nil (the default) draws as before; not used by material graphs.
    public var wind: MaterialWind?
    /// Draws fur on the mesh of an entity's `GroomRenderer` (see Groom.swift); nil for every other
    /// material. Fur materials draw only through `GroomRenderer`s (mesh_fur shaders).
    public var fur: MaterialFur?

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
        graph = nil
    }

    /// Always draws in the transparent pass, even at full opacity (`alphaMode == .blend`).
    public var isTransparent: Bool {
        get { alphaMode == .blend }
        set { alphaMode = newValue ? .blend : (alphaMode == .blend ? .opaque : alphaMode) }
    }

    /// Whether entities with this material always go to the transparent pass: blended, or not
    /// alpha-tested with a base alpha below 1.
    package var blends: Bool { alphaMode == .blend || (alphaMode == .opaque && baseColor.w < 1) }

    /// Whether it draws with the alpha-tested shader variants (`alphaMode == .mask`).
    package var alphaTested: Bool { alphaMode == .mask && graph == nil }

    /// Whether it draws with the wind vertex shaders (`wind`, not a graph).
    package var sways: Bool { wind != nil && graph == nil }

    /// Whether its shadow and depth prepass cut out what the alpha test discards (`alphaMode ==
    /// .mask`): with the alpha-tested shadow shader, or a masked graph's own depth variant
    /// (`MaterialGraphProgram.metalDepthFragment` / `spirvDepthFragment`; a graph without them
    /// casts its whole shape).
    package var masksDepth: Bool {
        guard alphaMode == .mask else { return false }
        guard let graph else { return true }
        return graph.metalDepthFragment != nil && graph.spirvDepthFragment != nil
    }

    /// The UV transform as the rows of a 2x3 matrix: `uv' = (dot(row0.xy, uv) + row0.z, dot(row1.xy, uv) + row1.z)`.
    package var uvTransformRows: (Vec4, Vec4) {
        let c = cosf(uvRotation), s = sinf(uvRotation)
        // offset + [c s; -s c] * (scale * uv), the KHR_texture_transform matrix.
        if uvRotation == 0 { return (Vec4(uvScale.x, 0, uvOffset.x, 0), Vec4(0, uvScale.y, uvOffset.y, 0)) }
        return (Vec4(c * uvScale.x, s * uvScale.y, uvOffset.x, 0), Vec4(-s * uvScale.x, c * uvScale.y, uvOffset.y, 0))
    }
}

/// Worn convex edges: where a mesh's edges and corners stick out, the surface blends toward a
/// worn variant (chipped paint showing bare metal, lighter rubbed wood or stone, polished edges on
/// rust). Mesh builds set it on parts with a look and `wear` (MeshBuildEdgeWear.swift).
///
/// How far each point is from a convex edge comes from the mesh: every vertex carries an edge
/// coordinate e = strength - distance / band width (1 on a sharp edge, 0 one band width away,
/// negative further in, up to 1.5 at corners), stored as the component of `MeshVertex.tangent`'s
/// xyz along the vertex normal (`encode`). The lit shader already removes that component before
/// using the tangent (it projects the tangent onto the surface), so it changes nothing else, and
/// since e is linear in the distance to the edge it interpolates exactly across a flat triangle:
/// a box face split into a few triangles still gets a sharp band along its edges. The shader
/// (mesh_surface.glsl) adds noise for an irregular, chipped boundary, in the mesh's own space
/// (the vertex position before the model transform, `noise`), so a chip wraps around an edge as
/// one and stays on the model as it moves, turns or scales.
///
/// The parameters reach the shader in the two unused w components of the material's UV rows
/// (`MaterialUniforms.uvRow0.w` / `uvRow1.w`) as 24-bit integers (`packed`); 0 means none.
public struct EdgeWear: Equatable, Sendable, Codable {
    /// Linear albedo of the worn surface (0...2), times half the base color texture's detail
    /// (mix(1, texture x 2, 0.5): looks normalize their albedo to an average of 0.5) and the instance tint.
    public var color: Vec3
    public var roughness: Float
    public var metallic: Float
    /// Cycles per meter (of the mesh's own space) of the noise that breaks up the band (4...~5000).
    public var noiseFrequency: Float
    /// 0: a soft rubbed edge, 1: crisp chips.
    public var crisp: Float

    public init(color: Vec3, roughness: Float, metallic: Float, noiseFrequency: Float, crisp: Float) {
        self.color = color
        self.roughness = roughness
        self.metallic = metallic
        self.noiseFrequency = noiseFrequency
        self.crisp = crisp
    }

    /// The edge coordinate's range (mesh_surface.glsl's EDGE_MIN / EDGE_MAX): values beyond it
    /// are clamped, so a triangle reaching further than `-minimum` band widths from an edge
    /// widens the band a little.
    public static let minimum: Float = -24
    public static let maximum: Float = 1.5

    /// The tangent's component along the normal that carries edge coordinate `e` (0...1; 0 is
    /// `minimum`, far from any edge, which is what a mesh without edge coordinates reads as).
    public static func encode(_ e: Float) -> Float {
        (min(max(e, minimum), maximum) - minimum) / (maximum - minimum)
    }

    /// The edge coordinate a tangent's component along the normal (`encode`) stands for.
    public static func decode(_ s: Float) -> Float { minimum + s * (maximum - minimum) }

    /// The edge coordinate a vertex's tangent carries (the ratio of its component along `normal`
    /// to the rest, as the shader computes it).
    public static func coordinate(tangent: Vec3, normal: Vec3) -> Float {
        let n = normalize(normal)
        let along = dot(n, tangent)
        return decode(along / max(length(tangent - n * along), 1e-6))
    }

    /// The noise frequency's 5-bit code: 4 x 2^(code / 3) cycles per meter.
    static func frequencyCode(_ f: Float) -> Int {
        guard f.isFinite, f > 4 else { return 0 }
        return min(Int((3 * log2f(f / 4)).rounded()), 31)
    }

    /// mesh_surface.glsl's `edgeHash`: a value in 0...1 for an integer lattice cell.
    static func hash(_ x: Int32, _ y: Int32, _ z: Int32) -> Float {
        var h = (UInt32(bitPattern: x) &* 1597334677) ^ (UInt32(bitPattern: y) &* 3812015801) ^ (UInt32(bitPattern: z) &* 2798796415)
        h = h &* 1597334677
        h ^= h >> 16
        return Float(h & 0xFFFF) / 65535
    }

    /// mesh_surface.glsl's `edgeNoise`: smooth value noise in 0...1 at `p` (object-space position x frequency).
    static func noise(_ p: Vec3) -> Float {
        let i = Vec3(p.x.rounded(.down), p.y.rounded(.down), p.z.rounded(.down))
        let f = p - i
        let u = f * f * (Vec3(repeating: 3) - 2 * f)
        let x = Int32(i.x), y = Int32(i.y), z = Int32(i.z)
        func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
        func layer(_ z: Int32) -> Float {
            mix(mix(hash(x, y, z), hash(x + 1, y, z), u.x), mix(hash(x, y + 1, z), hash(x + 1, y + 1, z), u.x), u.y)
        }
        return mix(layer(z), layer(z + 1), u.z)
    }

    /// mesh_surface.glsl's two-octave chip noise at object-space position `position` (meters).
    public func chipNoise(at position: Vec3) -> Float {
        let p = position * noiseFrequency
        return Self.noise(p) * 0.65 + Self.noise(p * 2.7 + Vec3(17.3, 5.1, 9.7)) * 0.35
    }

    /// The parameters as the shader reads them: (rgb bytes of color / 2; roughness, metallic and
    /// a byte with the frequency code, crispness in two bits and a set top bit). Every value is
    /// an integer below 2^24, exact in a float.
    public var packed: (Float, Float) {
        func byte(_ x: Float) -> Int { Int((min(max(x.isFinite ? x : 0, 0), 1) * 255).rounded()) }
        let rgb = byte(color.x / 2) + byte(color.y / 2) << 8 + byte(color.z / 2) << 16
        let flags = Self.frequencyCode(noiseFrequency) | Int((min(max(crisp, 0), 1) * 3).rounded()) << 5 | 128
        return (Float(rgb), Float(byte(roughness) + byte(metallic) << 8 + flags << 16))
    }
}

/// What the CPU side of `SceneRenderer` needs to know about a material to sort and batch it.
public struct MaterialTraits: Equatable, Sendable {
    /// Always drawn in the transparent pass (`Material.isTransparent` or base alpha < 1).
    public var blends: Bool
    /// Alpha-tested (`AlphaMode.mask`): its shadow casters are batched per material, since the
    /// shadow pass samples its base color alpha. `SceneRenderer` also sets it for materials that
    /// sway in the wind (`Material.sways`), whose depth passes need their material too.
    public var alphaTested: Bool
    /// A fur material's detail levels (`Material.fur`), nil for others.
    public var fur: FurTraits?

    public init(blends: Bool = false, alphaTested: Bool = false, fur: FurTraits? = nil) {
        self.blends = blends
        self.alphaTested = alphaTested
        self.fur = fur
    }
}

/// Assets by key, with dense integer ids for fast per-frame lookups. Keys are registered
/// once; registering a key again replaces its value and keeps its id.
public struct AssetRegistry<Value> {
    /// The registered keys, in id order.
    public var keys: [String] { ids.sorted { $0.value < $1.value }.map(\.key) }
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
        values.append(value)
        return id
    }

    /// Forgets `key`: lookups fail from now on. Its id (and value) stay allocated, so ids already
    /// handed out stay valid; registering the key again gets a new id.
    public mutating func remove(_ key: String) {
        ids[key] = nil
        last = nil
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
