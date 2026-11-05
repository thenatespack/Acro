import Foundation

// Post-FX profiles: the contents of a `.postfx` file (JSON, every key optional) are exactly a
// `PostProcessSettings` (the `PostProcess` component's fields), so a profile and a scene's
// post-processing are interchangeable.
//
// ```json
// {"tonemapper": "aces", "exposure": 0.3, "bloom": true, "bloomIntensity": 0.08,
//  "lift": [0.02, 0, 0.03], "gamma": [1, 1, 1], "gain": [1.05, 1, 0.95], "saturation": 1.1,
//  "contrast": 1.05, "vignette": 0.3, "vignetteSoftness": 0.5, "chromaticAberration": 0.1, "filmGrain": 0.05}
// ```
//
// Assignment: `Camera.postFX` names a profile for that camera; `PostFXVolume`s blend more
// profiles over it while the camera is inside (or near) them. `PostFXResolver` computes the
// settings the renderer uses each frame.

public typealias PostFXProfile = PostProcessSettings

extension PostProcessSettings {
    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// Problems with a profile's values (out of range or contradicting each other). Values are
    /// still used, clamped where the renderer needs it.
    public func validationWarnings() -> [String] {
        var out: [String] = []
        if exposure < -10 || exposure > 10 { out.append("exposure \(exposure) is outside -10...10 EV") }
        if autoExposureMin > autoExposureMax { out.append("autoExposureMin is above autoExposureMax") }
        if adaptationSpeed <= 0 { out.append("adaptationSpeed should be above 0") }
        if bloomIntensity < 0 || bloomIntensity > 1 { out.append("bloomIntensity \(bloomIntensity) is outside 0...1") }
        if saturation < 0 || saturation > 2 { out.append("saturation \(saturation) is outside 0...2") }
        if contrast < 0.5 || contrast > 1.5 { out.append("contrast \(contrast) is outside 0.5...1.5") }
        if gamma.x <= 0 || gamma.y <= 0 || gamma.z <= 0 { out.append("gamma must be above 0") }
        if vignette < 0 || vignette > 1 { out.append("vignette \(vignette) is outside 0...1") }
        if vignetteSoftness <= 0 || vignetteSoftness > 1 { out.append("vignetteSoftness \(vignetteSoftness) is outside 0...1") }
        if chromaticAberration < 0 || chromaticAberration > 1 { out.append("chromaticAberration \(chromaticAberration) is outside 0...1") }
        if filmGrain < 0 || filmGrain > 1 { out.append("filmGrain \(filmGrain) is outside 0...1") }
        return out
    }

    /// This profile moved toward `other` by `weight` (0 = this, 1 = other). Numbers and colors
    /// interpolate; the tonemapper and auto-exposure switch take `other`'s once `weight` reaches
    /// a half. Bloom stays on while either side has it, fading with the intensity.
    public func blended(to other: PostProcessSettings, weight: Float) -> PostProcessSettings {
        let t = min(max(weight, 0), 1)
        if t <= 0 { return self }
        if t >= 1 { return other }
        func mix(_ a: Float, _ b: Float) -> Float { a + (b - a) * t }
        func mix(_ a: Vec3, _ b: Vec3) -> Vec3 { a + (b - a) * t }
        var r = t >= 0.5 ? other : self
        r.exposure = mix(exposure, other.exposure)
        r.autoExposureMin = mix(autoExposureMin, other.autoExposureMin)
        r.autoExposureMax = mix(autoExposureMax, other.autoExposureMax)
        r.adaptationSpeed = mix(adaptationSpeed, other.adaptationSpeed)
        let a: Float = bloom ? bloomIntensity : 0
        let b: Float = other.bloom ? other.bloomIntensity : 0
        r.bloom = bloom || other.bloom
        r.bloomIntensity = mix(a, b)
        r.lift = mix(lift, other.lift)
        r.gamma = mix(gamma, other.gamma)
        r.gain = mix(gain, other.gain)
        r.saturation = mix(saturation, other.saturation)
        r.contrast = mix(contrast, other.contrast)
        r.vignette = mix(vignette, other.vignette)
        r.vignetteSoftness = mix(vignetteSoftness, other.vignetteSoftness)
        r.chromaticAberration = mix(chromaticAberration, other.chromaticAberration)
        r.filmGrain = mix(filmGrain, other.filmGrain)
        return r
    }
}

/// Ready-made looks for a new profile.
public enum PostFXPreset: String, CaseIterable, Sendable {
    case neutral, cinematic, warm, cold, noir, retro

    public var settings: PostProcessSettings {
        var s = PostProcessSettings(tonemapper: .neutral, bloom: true, bloomIntensity: 0.03)
        switch self {
        case .neutral:
            s.bloom = false
        case .cinematic:
            s.tonemapper = .aces
            s.exposure = -0.2
            s.bloomIntensity = 0.06
            s.lift = Vec3(0.0, 0.01, 0.025)
            s.gain = Vec3(1.06, 1.0, 0.92)
            s.contrast = 1.12
            s.saturation = 0.92
            s.vignette = 0.35
            s.filmGrain = 0.06
            s.chromaticAberration = 0.08
        case .warm:
            s.tonemapper = .aces
            s.bloomIntensity = 0.05
            s.lift = Vec3(0.02, 0.005, 0)
            s.gamma = Vec3(1.04, 1.0, 0.94)
            s.gain = Vec3(1.1, 1.02, 0.88)
            s.saturation = 1.1
            s.vignette = 0.15
        case .cold:
            s.tonemapper = .neutral
            s.bloomIntensity = 0.04
            s.lift = Vec3(0, 0.005, 0.03)
            s.gamma = Vec3(0.96, 1.0, 1.06)
            s.gain = Vec3(0.9, 0.98, 1.1)
            s.saturation = 0.85
            s.contrast = 1.05
            s.vignette = 0.2
        case .noir:
            s.tonemapper = .aces
            s.bloomIntensity = 0.04
            s.saturation = 0
            s.contrast = 1.3
            s.gain = Vec3(1.1, 1.1, 1.1)
            s.vignette = 0.55
            s.vignetteSoftness = 0.6
            s.filmGrain = 0.15
        case .retro:
            s.tonemapper = .reinhard
            s.exposure = 0.3
            s.bloomIntensity = 0.07
            s.lift = Vec3(0.04, 0.02, 0.05)
            s.gamma = Vec3(1.05, 0.95, 1.0)
            s.gain = Vec3(1.1, 1.0, 0.9)
            s.saturation = 1.35
            s.contrast = 1.15
            s.vignette = 0.45
            s.chromaticAberration = 0.25
            s.filmGrain = 0.2
        }
        return s
    }
}

/// Blends profiles over the camera's look by volume. Place on an entity (its `Transform`
/// positions, rotates and scales the shape); while the active camera is inside, `profile`
/// blends over the camera's look by `weight`, fading in over `blendDistance` outside the shape.
/// Overlapping volumes apply in `priority` order (higher last, so it wins).
public struct PostFXVolume: Component, Codable, Equatable, Sendable {
    public static let componentName = "PostFXVolume"

    public enum Shape: String, Codable, CaseIterable, Sendable { case box, sphere }

    /// A `.postfx` path relative to `Assets/` or an "asset:<id>" reference.
    public var profile: String
    public var shape: Shape
    /// Box: full extents in the entity's local space.
    public var size: Vec3
    /// Sphere: radius in the entity's local space.
    public var radius: Float
    /// Distance outside the shape over which the effect fades in (0 = hard edge).
    public var blendDistance: Float
    public var priority: Int
    /// Strength inside the shape (0...1).
    public var weight: Float
    /// Affects every camera everywhere, ignoring the shape.
    public var isGlobal: Bool

    public init(profile: String = "", shape: Shape = .box, size: Vec3 = Vec3(10, 10, 10), radius: Float = 5,
                blendDistance: Float = 2, priority: Int = 0, weight: Float = 1, isGlobal: Bool = false) {
        self.profile = profile
        self.shape = shape
        self.size = size
        self.radius = radius
        self.blendDistance = blendDistance
        self.priority = priority
        self.weight = weight
        self.isGlobal = isGlobal
    }

    private enum CodingKeys: String, CodingKey { case profile, shape, size, radius, blendDistance, priority, weight, isGlobal }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PostFXVolume()
        profile = try c.decodeIfPresent(String.self, forKey: .profile) ?? d.profile
        shape = try c.decodeIfPresent(Shape.self, forKey: .shape) ?? d.shape
        size = try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size
        radius = try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius
        blendDistance = try c.decodeIfPresent(Float.self, forKey: .blendDistance) ?? d.blendDistance
        priority = try c.decodeIfPresent(Int.self, forKey: .priority) ?? d.priority
        weight = try c.decodeIfPresent(Float.self, forKey: .weight) ?? d.weight
        isGlobal = try c.decodeIfPresent(Bool.self, forKey: .isGlobal) ?? d.isGlobal
    }

    public static var fieldHints: [String: FieldHints] {
        [
            "size": FieldHints(tooltip: "Box extents"),
            "radius": FieldHints(range: 0...1000, step: 0.1),
            "blendDistance": FieldHints(range: 0...100, step: 0.1),
            "weight": FieldHints(range: 0...1, step: 0.01),
        ]
    }

    @MainActor public static func registerComponents() { ComponentRegistry.register(PostFXVolume.self) }

    /// How strongly the volume applies at `point` (world space) for a volume whose entity has
    /// world matrix `matrix`: `weight` inside, fading to 0 over `blendDistance` outside.
    public func influence(at point: Vec3, volumeWorld matrix: Mat4) -> Float {
        let w = min(max(weight, 0), 1)
        if isGlobal { return w }
        let local = matrix.inverse * Vec4(point.x, point.y, point.z, 1)
        let p = Vec3(local.x, local.y, local.z)
        let outside: Float
        switch shape {
        case .box:
            let q = Vec3(abs(p.x), abs(p.y), abs(p.z)) - size * 0.5
            let o = Vec3(max(q.x, 0), max(q.y, 0), max(q.z, 0))
            outside = (o.x * o.x + o.y * o.y + o.z * o.z).squareRoot()
        case .sphere:
            outside = max((p.x * p.x + p.y * p.y + p.z * p.z).squareRoot() - radius, 0)
        }
        if outside <= 0 { return w }
        guard blendDistance > 0 else { return 0 }
        return w * max(1 - outside / blendDistance, 0)
    }
}

/// Finds the post-processing a frame uses.
public enum PostFXResolver {
    /// The profile `key` names (path or "asset:<id>"), or nil if it names none or isn't a `.postfx`.
    @MainActor
    public static func profile(_ key: String, assets: AssetDatabase?) -> PostProcessSettings? {
        let key = key.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, let assets else { return nil }
        let id: AssetID?
        if let reference = AssetReference(key) {
            id = reference.asset
        } else {
            id = assets.id(forPath: key.hasPrefix("Assets/") ? String(key.dropFirst("Assets/".count)) : key)
        }
        guard let id, assets.record(id)?.importer == PostFXImporter().name else { return nil }
        return assets.prefab(AssetReference(id))?.roots.first?.postFX
    }

    /// The camera's profile (else the scene's `PostProcess` component) with the volumes the
    /// camera is in blended over it; nil when nothing asks for post-processing.
    @MainActor
    public static func resolve(world: World, camera: Camera, cameraWorld: Mat4, assets: AssetDatabase?) -> PostProcessSettings? {
        var settings = profile(camera.postFX, assets: assets) ?? PostProcessSettings.find(in: world)
        var volumes: [(priority: Int, index: UInt32, volume: PostFXVolume, world: Mat4)] = []
        world.query(PostFXVolume.self) { entity, volume in
            volumes.append((volume.priority, entity.index, volume,
                            world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)))
        }
        guard !volumes.isEmpty else { return settings }
        let eye = Vec3(cameraWorld.c3.x, cameraWorld.c3.y, cameraWorld.c3.z)
        for item in volumes.sorted(by: { ($0.priority, $0.index) < ($1.priority, $1.index) }) {
            let weight = item.volume.influence(at: eye, volumeWorld: item.world)
            guard weight > 0, let profile = profile(item.volume.profile, assets: assets) else { continue }
            settings = (settings ?? PostProcessSettings()).blended(to: profile, weight: weight)
        }
        return settings
    }
}

/// `.postfx` files: the profile is validated (problems become warnings) and stored as the
/// single node of an otherwise empty prefab (so it reaches built games through the asset pack).
public struct PostFXImporter: AssetImporter {
    public init() {}

    public var name: String { "postfx" }
    public var fileExtensions: [String] { ["postfx"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let profile: PostProcessSettings
        do { profile = try AssetJSON.decoder().decode(PostProcessSettings.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a post-fx profile: \(error)")
        }
        for warning in profile.validationWarnings() { context.warn(warning) }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, postFX: profile)])))
        asset.main = prefab
        return asset
    }
}

extension AssetDatabase {
    /// Writes `profile` to a new `.postfx` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createPostFX(_ profile: PostProcessSettings, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try profile.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.postfx` asset `id` (nil if it isn't one or can't be read).
    public func postFX(of id: AssetID) -> PostProcessSettings? {
        guard record(id)?.importer == PostFXImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(PostProcessSettings.self, from: data)
    }

    /// Overwrites the `.postfx` asset `id` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writePostFX(_ profile: PostProcessSettings, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try profile.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
