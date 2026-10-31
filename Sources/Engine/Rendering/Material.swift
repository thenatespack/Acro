/// Surface parameters for `SceneRenderer`'s lit shader. A GPU resource (it can hold a
/// texture), so entities reference it through a `MaterialHandle`; register it with
/// `SceneRenderer.registerMaterial(_:key:)`.
public struct Material {
    /// Linear RGB and opacity, multiplied with the texture and the `MeshRenderer`'s tint and opacity.
    public var baseColor: Vec4
    /// Albedo texture (`.rgba8Srgb` for color), sampled with the mesh's UVs times `uvScale`.
    public var texture: GPUTexture?
    public var sampler: SamplerDescriptor
    public var uvScale: Vec2
    /// Darkens alternate 2x2-unit cells of a world-space XZ checkerboard (for floors).
    public var checker: Bool
    /// 0 is lit, 1 shows the albedo unlit (fog still applies).
    public var emissive: Float
    public var specular: Float
    public var shininess: Float
    /// Draws back faces too (no culling).
    public var doubleSided: Bool
    /// Always draws in the transparent pass, even at full opacity.
    public var isTransparent: Bool

    public init(baseColor: Vec4 = Vec4(0.8, 0.8, 0.8, 1), texture: GPUTexture? = nil,
                sampler: SamplerDescriptor = SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear, addressMode: .repeat),
                uvScale: Vec2 = Vec2(1, 1), checker: Bool = false, emissive: Float = 0, specular: Float = 0.35,
                shininess: Float = 48, doubleSided: Bool = false, isTransparent: Bool = false) {
        self.baseColor = baseColor
        self.texture = texture
        self.sampler = sampler
        self.uvScale = uvScale
        self.checker = checker
        self.emissive = emissive
        self.specular = specular
        self.shininess = shininess
        self.doubleSided = doubleSided
        self.isTransparent = isTransparent
    }

    /// Whether entities with this material always go to the transparent pass.
    var blends: Bool { isTransparent || baseColor.w < 1 }
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
