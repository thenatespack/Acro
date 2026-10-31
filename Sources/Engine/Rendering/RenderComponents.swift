/// Rendering components: put these on entities and a `SceneRenderer` draws the world.
///
/// Every component here is plain data and `Codable`. GPU resources (meshes, materials) are
/// referenced by `MeshHandle` / `MaterialHandle`, which hold a stable asset key that the
/// renderer resolves through its registries.

/// Names a mesh registered with a `SceneRenderer` (`registerMesh(_:key:)`). Encodes as its
/// key string. The built-in primitives are registered by default.
public struct MeshHandle: Hashable, Codable, Sendable, CustomStringConvertible {
    public var key: String

    public init(_ key: String) { self.key = key }

    /// A cube of size 1 centered on the origin (half-extent 0.5), UVs 0–1 on each face.
    public static let cube = MeshHandle("cube")
    /// A 1x1 single-sided plane in XZ facing +Y, centered on the origin.
    public static let plane = MeshHandle("plane")
    /// A UV sphere of radius 0.5 centered on the origin.
    public static let sphere = MeshHandle("sphere")

    public init(from decoder: Decoder) throws { key = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    public var description: String { "mesh '\(key)'" }
}

/// Names a `Material` registered with a `SceneRenderer` (`registerMaterial(_:key:)`).
/// Encodes as its key string. `.default` (light gray, matte) is registered by default.
public struct MaterialHandle: Hashable, Codable, Sendable, CustomStringConvertible {
    public var key: String

    public init(_ key: String) { self.key = key }

    public static let `default` = MaterialHandle("default")

    public init(from decoder: Decoder) throws { key = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    public var description: String { "material '\(key)'" }
}

/// A perspective camera. It views from its entity's `GlobalTransform`, looking down the
/// entity's local -Z axis with +Y up (scale is ignored).
///
/// `SceneRenderer` renders from the active camera (`isActive`) with the lowest entity index,
/// unless `SceneRenderer.camera` names one explicitly.
public struct Camera: Component, Codable, Equatable, Sendable {
    public static let componentName = "Camera"
    /// Vertical field of view in radians.
    public var fovY: Float
    public var near: Float
    public var far: Float
    /// Maps near → 1 and far → 0, for much better depth precision. The renderer switches
    /// its pipelines to a `.greater` depth test and sets `engine.clearDepth` to 0.
    public var reversedZ: Bool
    /// Linear RGBA the screen is cleared to (set as `engine.clearColor`).
    public var clearColor: Vec4
    public var isActive: Bool

    public init(fovY: Float = .pi / 3, near: Float = 0.1, far: Float = 500, reversedZ: Bool = false,
                clearColor: Vec4 = Vec4(0, 0, 0, 1), isActive: Bool = true) {
        self.fovY = fovY
        self.near = near
        self.far = far
        self.reversedZ = reversedZ
        self.clearColor = clearColor
        self.isActive = isActive
    }

    /// The projection matrix (unjittered) for a viewport of `aspect` = width / height.
    public func projection(aspect: Float) -> Mat4 {
        reversedZ
            ? Mat4.perspective(fovY: fovY, aspect: aspect, near: far, far: near)
            : Mat4.perspective(fovY: fovY, aspect: aspect, near: near, far: far)
    }

    /// The view matrix for a camera whose entity has world matrix `world`: its translation
    /// and orthonormalized rotation, inverted. Scale and shear are ignored.
    public static func viewMatrix(world: Mat4) -> Mat4 {
        let eye = Vec3(world.c3.x, world.c3.y, world.c3.z)
        let back = normalize(Vec3(world.c2.x, world.c2.y, world.c2.z))
        let right = normalize(cross(Vec3(world.c1.x, world.c1.y, world.c1.z), back))
        let up = cross(back, right)
        return Mat4(
            Vec4(right.x, up.x, back.x, 0),
            Vec4(right.y, up.y, back.y, 0),
            Vec4(right.z, up.z, back.z, 0),
            Vec4(-dot(right, eye), -dot(up, eye), -dot(back, eye), 1))
    }
}

/// A sun-like light shining in one direction everywhere, optionally casting shadows.
///
/// The light travels along `direction` if set, else along its entity's forward axis (local
/// -Z of the `GlobalTransform`), so rotating the entity aims it. `SceneRenderer` uses the
/// first directional light by entity index; others are ignored.
///
/// Shadows: without a `shadowCenter`, the shadow follows the camera as cascaded shadow maps
/// (`cascadeCount` cascades, each `engine.quality.shadowMapSize` square, filtered with
/// `shadowFilterRadius`) covering the view out to `shadowMaxDistance`. With a fixed
/// `shadowCenter`, one shadow map covers the square `shadowCenter ± shadowExtent`, as before
/// cascades existed. See `ShadowCascades` for the split scheme.
public struct DirectionalLight: Component, Codable, Equatable, Sendable {
    public static let componentName = "DirectionalLight"
    public static var fieldHints: [String: FieldHints] {
        ["cascadeCount": FieldHints(range: 1...4, step: 1, tooltip: "Shadow cascades (nil: the render quality's)"),
         "cascadeSplitLambda": FieldHints(range: 0...1, step: 0.01, tooltip: "0: uniform cascade splits, 1: logarithmic"),
         "cascadeBlend": FieldHints(range: 0...0.5, step: 0.01, tooltip: "Fraction of each cascade blended into the next"),
         "shadowNormalOffset": FieldHints(range: 0...8, step: 0.1, tooltip: "Receiver offset along the normal, in shadow-map texels")]
    }
    /// Linear RGB.
    public var color: Vec3
    public var intensity: Float
    /// World-space direction the light travels in (from the light toward the scene); nil
    /// uses the entity's forward axis.
    public var direction: Vec3?
    public var castsShadows: Bool
    /// Half-size, in world units, of the square area a fixed (`shadowCenter`) shadow map
    /// covers. Without a center it sets the default `shadowMaxDistance` (2 × extent).
    public var shadowExtent: Float
    /// Center of a fixed shadowed square. nil makes the shadow follow the camera in cascades
    /// (snapped to shadow-map texels, so shadows don't shimmer as the camera moves).
    public var shadowCenter: Vec3?
    /// How far toward the light (beyond the shadowed area) casters are still included.
    public var shadowDistance: Float
    /// Depth bias, in shadow-map depth units (per cascade), against acne on lit surfaces.
    public var shadowBias: Float
    /// Shadow cascades (1–4); nil uses `engine.quality.shadowCascades`.
    public var cascadeCount: Int?
    /// View distance the cascades cover (clamped to the camera's far plane); nil is 2 × `shadowExtent`.
    public var shadowMaxDistance: Float?
    /// Blend between uniform (0) and logarithmic (1) cascade split distances.
    public var cascadeSplitLambda: Float
    /// Fraction of each cascade's depth range over which it blends into the next one (the
    /// last cascade fades out over it).
    public var cascadeBlend: Float
    /// How far receivers are pushed along their normal before the shadow lookup, in
    /// shadow-map texels of their cascade (against acne at grazing angles).
    public var shadowNormalOffset: Float

    public init(color: Vec3 = Vec3(1, 1, 1), intensity: Float = 1.3, direction: Vec3? = nil, castsShadows: Bool = true,
                shadowExtent: Float = 30, shadowCenter: Vec3? = nil, shadowDistance: Float = 60, shadowBias: Float = 0.0005,
                cascadeCount: Int? = nil, shadowMaxDistance: Float? = nil, cascadeSplitLambda: Float = 0.75,
                cascadeBlend: Float = 0.1, shadowNormalOffset: Float = 1) {
        self.color = color
        self.intensity = intensity
        self.direction = direction
        self.castsShadows = castsShadows
        self.shadowExtent = shadowExtent
        self.shadowCenter = shadowCenter
        self.shadowDistance = shadowDistance
        self.shadowBias = shadowBias
        self.cascadeCount = cascadeCount
        self.shadowMaxDistance = shadowMaxDistance
        self.cascadeSplitLambda = cascadeSplitLambda
        self.cascadeBlend = cascadeBlend
        self.shadowNormalOffset = shadowNormalOffset
    }

    /// Missing fields (scene files written before cascades) take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = DirectionalLight()
        self.init(
            color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
            intensity: try c.decodeIfPresent(Float.self, forKey: .intensity) ?? d.intensity,
            direction: try c.decodeIfPresent(Vec3.self, forKey: .direction),
            castsShadows: try c.decodeIfPresent(Bool.self, forKey: .castsShadows) ?? d.castsShadows,
            shadowExtent: try c.decodeIfPresent(Float.self, forKey: .shadowExtent) ?? d.shadowExtent,
            shadowCenter: try c.decodeIfPresent(Vec3.self, forKey: .shadowCenter),
            shadowDistance: try c.decodeIfPresent(Float.self, forKey: .shadowDistance) ?? d.shadowDistance,
            shadowBias: try c.decodeIfPresent(Float.self, forKey: .shadowBias) ?? d.shadowBias,
            cascadeCount: try c.decodeIfPresent(Int.self, forKey: .cascadeCount),
            shadowMaxDistance: try c.decodeIfPresent(Float.self, forKey: .shadowMaxDistance),
            cascadeSplitLambda: try c.decodeIfPresent(Float.self, forKey: .cascadeSplitLambda) ?? d.cascadeSplitLambda,
            cascadeBlend: try c.decodeIfPresent(Float.self, forKey: .cascadeBlend) ?? d.cascadeBlend,
            shadowNormalOffset: try c.decodeIfPresent(Float.self, forKey: .shadowNormalOffset) ?? d.shadowNormalOffset)
    }

    /// The normalized direction the light travels in, for an entity with world matrix `world`.
    public func travelDirection(world: Mat4) -> Vec3 {
        if let direction { return normalize(direction) }
        return normalize(-Vec3(world.c2.x, world.c2.y, world.c2.z))
    }
}

/// A light bulb: shines equally in every direction from its entity's world position (rotation
/// and scale are ignored).
///
/// Physically based falloff: the light reaching a surface is `color × intensity / d²` (so at
/// 1 unit it matches a `DirectionalLight` of the same intensity), smoothly windowed to zero at
/// `range`, beyond which the light has no effect and costs nothing. `SceneRenderer` bins point
/// and spot lights into a clustered view-space grid (see `LightClusters` for the limits).
public struct PointLight: Component, Codable, Equatable, Sendable {
    public static let componentName = "PointLight"
    public static var fieldHints: [String: FieldHints] {
        ["color": FieldHints(color: true), "intensity": FieldHints(range: 0...1000, step: 0.1),
         "range": FieldHints(range: 0.01...1000, step: 0.1, tooltip: "Distance at which the light fades out completely"),
         "castsShadows": FieldHints(tooltip: "Six shadow-map faces in the shadow atlas (a few lights per view)")]
    }
    /// Linear RGB.
    public var color: Vec3
    public var intensity: Float
    /// World-space distance beyond which the light contributes nothing.
    public var range: Float
    /// Casts shadows (opt-in): six faces in `SceneRenderer`'s shadow atlas, for at most
    /// `ShadowAtlasLayout.maxPointShadows` lights per frame, the most prominent ones.
    public var castsShadows: Bool

    public init(color: Vec3 = Vec3(1, 1, 1), intensity: Float = 5, range: Float = 10, castsShadows: Bool = false) {
        self.color = color
        self.intensity = intensity
        self.range = range
        self.castsShadows = castsShadows
    }

    /// Missing fields (scene files written before light shadows) take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PointLight()
        self.init(color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  intensity: try c.decodeIfPresent(Float.self, forKey: .intensity) ?? d.intensity,
                  range: try c.decodeIfPresent(Float.self, forKey: .range) ?? d.range,
                  castsShadows: try c.decodeIfPresent(Bool.self, forKey: .castsShadows) ?? d.castsShadows)
    }
}

/// A cone of light from its entity's world position along the entity's forward axis (local -Z
/// of the `GlobalTransform`, the camera / directional-light convention), with the falloff of a
/// `PointLight`. Full intensity inside `innerConeAngle`, fading smoothly to zero at
/// `outerConeAngle` (half-angles from the axis in radians, as in glTF `KHR_lights_punctual`;
/// the outer angle is clamped below 90°).
public struct SpotLight: Component, Codable, Equatable, Sendable {
    public static let componentName = "SpotLight"
    public static var fieldHints: [String: FieldHints] {
        ["color": FieldHints(color: true), "intensity": FieldHints(range: 0...1000, step: 0.1),
         "range": FieldHints(range: 0.01...1000, step: 0.1, tooltip: "Distance at which the light fades out completely"),
         "innerConeAngle": FieldHints(range: 0...1.57, step: 0.01, tooltip: "Half-angle of full intensity, radians"),
         "outerConeAngle": FieldHints(range: 0...1.57, step: 0.01, tooltip: "Half-angle where the light reaches zero, radians"),
         "castsShadows": FieldHints(tooltip: "A perspective shadow map in the shadow atlas (a few lights per view)")]
    }
    /// Linear RGB.
    public var color: Vec3
    public var intensity: Float
    public var range: Float
    public var innerConeAngle: Float
    public var outerConeAngle: Float
    /// Casts shadows (opt-in): a perspective shadow map in `SceneRenderer`'s shadow atlas, for
    /// at most `ShadowAtlasLayout.maxSpotShadows` lights per frame, the most prominent ones.
    public var castsShadows: Bool

    public init(color: Vec3 = Vec3(1, 1, 1), intensity: Float = 10, range: Float = 15,
                innerConeAngle: Float = 0.35, outerConeAngle: Float = 0.5, castsShadows: Bool = false) {
        self.color = color
        self.intensity = intensity
        self.range = range
        self.innerConeAngle = innerConeAngle
        self.outerConeAngle = outerConeAngle
        self.castsShadows = castsShadows
    }

    /// Missing fields (scene files written before light shadows) take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SpotLight()
        self.init(color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  intensity: try c.decodeIfPresent(Float.self, forKey: .intensity) ?? d.intensity,
                  range: try c.decodeIfPresent(Float.self, forKey: .range) ?? d.range,
                  innerConeAngle: try c.decodeIfPresent(Float.self, forKey: .innerConeAngle) ?? d.innerConeAngle,
                  outerConeAngle: try c.decodeIfPresent(Float.self, forKey: .outerConeAngle) ?? d.outerConeAngle,
                  castsShadows: try c.decodeIfPresent(Bool.self, forKey: .castsShadows) ?? d.castsShadows)
    }
}

/// Ambient light and fog for the whole scene. The first entity (by index) that has one
/// is used; without one, `SceneRenderer` uses these defaults.
public struct SceneEnvironment: Component, Codable, Equatable, Sendable {
    public static let componentName = "SceneEnvironment"
    /// Hemisphere ambient: surfaces facing up get `skyColor`, facing down `groundColor`,
    /// both scaled by `ambientIntensity`. Linear RGB.
    public var skyColor: Vec3
    public var groundColor: Vec3
    public var ambientIntensity: Float
    /// Exponential distance fog (0 density disables it). Usually matches the camera's clear color.
    public var fogColor: Vec3
    public var fogDensity: Float

    public init(skyColor: Vec3 = Vec3(0.55, 0.65, 0.85), groundColor: Vec3 = Vec3(0.12, 0.1, 0.09),
                ambientIntensity: Float = 0.3, fogColor: Vec3 = Vec3(0.62, 0.7, 0.82), fogDensity: Float = 0) {
        self.skyColor = skyColor
        self.groundColor = groundColor
        self.ambientIntensity = ambientIntensity
        self.fogColor = fogColor
        self.fogDensity = fogDensity
    }
}

/// Draws a mesh with a material at its entity's `GlobalTransform`. Entities with the same
/// mesh and material are drawn together, in one instanced draw per pass.
public struct MeshRenderer: Component, Codable, Equatable, Sendable {
    public static let componentName = "MeshRenderer"
    public var mesh: MeshHandle
    public var material: MaterialHandle
    /// Linear RGB multiplied with the material's base color, so entities can vary in color
    /// while sharing a material (and a draw call).
    public var tint: Vec3
    /// Multiplied with the material's opacity. Below 1, the entity is drawn in the
    /// transparent pass (blended, sorted back to front, no depth writes).
    public var opacity: Float
    public var castsShadows: Bool
    public var receivesShadows: Bool
    public var isVisible: Bool

    public init(mesh: MeshHandle, material: MaterialHandle = .default, tint: Vec3 = Vec3(1, 1, 1), opacity: Float = 1,
                castsShadows: Bool = true, receivesShadows: Bool = true, isVisible: Bool = true) {
        self.mesh = mesh
        self.material = material
        self.tint = tint
        self.opacity = opacity
        self.castsShadows = castsShadows
        self.receivesShadows = receivesShadows
        self.isVisible = isVisible
    }
}

extension Quat {
    /// The rotation that turns local -Z toward `forward` with local +Y as close to `up` as
    /// possible (the camera / light convention). `forward` must not be parallel to `up`.
    public static func lookRotation(forward: Vec3, up: Vec3 = Vec3(0, 1, 0)) -> Quat {
        let back = normalize(-forward)
        let right = normalize(cross(up, back))
        let trueUp = cross(back, right)
        let m = Mat4(Vec4(right, 0), Vec4(trueUp, 0), Vec4(back, 0), Vec4(0, 0, 0, 1))
        return Quat(rotationMatrix: m).normalized
    }
}

extension Transform {
    /// A transform at `position` looking at `target` (local -Z toward it, +Y toward `up`).
    public static func looking(from position: Vec3, at target: Vec3, up: Vec3 = Vec3(0, 1, 0)) -> Transform {
        Transform(position: position, rotation: .lookRotation(forward: target - position, up: up))
    }
}
