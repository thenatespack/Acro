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

/// Names a texture registered with a `SceneRenderer` (`registerTexture(_:key:)`), or a project
/// texture asset (`TextureHandle(AssetReference)`, resolved through `SceneRenderer.assets`).
/// Encodes as its key string. Used by `SceneEnvironment.environmentMap`.
public struct TextureHandle: Hashable, Codable, Sendable, CustomStringConvertible {
    public var key: String

    public init(_ key: String) { self.key = key }

    public init(from decoder: Decoder) throws { key = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    public var description: String { "texture '\(key)'" }
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

/// Ambient light, fog, the sky and image-based lighting for the whole scene. The first entity
/// (by index) that has one is used; without one, `SceneRenderer` uses these defaults.
///
/// `sky` picks what is behind the scene and what lights it (see `SkyMode`): by default the
/// camera's clear color and the hemisphere ambient (`skyColor` / `groundColor`), as before; or
/// a procedural sky or an equirectangular HDR `environmentMap`, drawn behind the scene (in the
/// HDR scene pass, so post-processing applies) and, with `imageBasedLighting`, lighting it with
/// SH9 diffuse irradiance and GGX-prefiltered specular reflections (`EnvironmentLighting`).
/// Keys missing from older scene files take their defaults.
public struct SceneEnvironment: Component, Codable, Equatable, Sendable {
    public static let componentName = "SceneEnvironment"
    public static var fieldHints: [String: FieldHints] {
        ["environmentIntensity": FieldHints(range: 0...16, step: 0.05, tooltip: "Scales the sky and its lighting"),
         "environmentRotation": FieldHints(range: -6.2832...6.2832, step: 0.01,
                                           tooltip: "Turns the environment map about +Y, radians (not the procedural sky)"),
         "imageBasedLighting": FieldHints(tooltip: "Light the scene with the sky (else the hemisphere ambient)")]
    }
    /// Hemisphere ambient: surfaces facing up get `skyColor`, facing down `groundColor`,
    /// both scaled by `ambientIntensity`. Linear RGB. Used unless the sky lights the scene.
    public var skyColor: Vec3
    public var groundColor: Vec3
    public var ambientIntensity: Float
    /// Exponential distance fog (0 density disables it). Usually matches the camera's clear color.
    /// The sky itself isn't fogged.
    public var fogColor: Vec3
    public var fogDensity: Float
    /// What's drawn behind the scene and lights it.
    public var sky: SkyMode
    /// The equirectangular HDR image `.map` draws (e.g. a decoded Radiance `.hdr` uploaded with
    /// `makeTexture(image: FloatImage)`, mips included), registered with
    /// `SceneRenderer.registerTexture(_:key:)`, or a project texture asset.
    public var environmentMap: TextureHandle?
    /// Scales the sky's radiance, as drawn and as light.
    public var environmentIntensity: Float
    /// Turns the environment map about +Y (radians, counter-clockwise seen from above). The
    /// procedural sky follows the directional light instead.
    public var environmentRotation: Float
    /// Light the scene with the sky (`.procedural` / `.map`): diffuse irradiance and specular
    /// reflections replace the hemisphere ambient. Off draws the sky only.
    public var imageBasedLighting: Bool
    /// The look of `.procedural`.
    public var proceduralSky: ProceduralSky

    public init(skyColor: Vec3 = Vec3(0.55, 0.65, 0.85), groundColor: Vec3 = Vec3(0.12, 0.1, 0.09),
                ambientIntensity: Float = 0.3, fogColor: Vec3 = Vec3(0.62, 0.7, 0.82), fogDensity: Float = 0,
                sky: SkyMode = .color, environmentMap: TextureHandle? = nil, environmentIntensity: Float = 1,
                environmentRotation: Float = 0, imageBasedLighting: Bool = true, proceduralSky: ProceduralSky = ProceduralSky()) {
        self.skyColor = skyColor
        self.groundColor = groundColor
        self.ambientIntensity = ambientIntensity
        self.fogColor = fogColor
        self.fogDensity = fogDensity
        self.sky = sky
        self.environmentMap = environmentMap
        self.environmentIntensity = environmentIntensity
        self.environmentRotation = environmentRotation
        self.imageBasedLighting = imageBasedLighting
        self.proceduralSky = proceduralSky
    }

    /// Missing fields (scene files written before skies existed) take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SceneEnvironment()
        self.init(
            skyColor: try c.decodeIfPresent(Vec3.self, forKey: .skyColor) ?? d.skyColor,
            groundColor: try c.decodeIfPresent(Vec3.self, forKey: .groundColor) ?? d.groundColor,
            ambientIntensity: try c.decodeIfPresent(Float.self, forKey: .ambientIntensity) ?? d.ambientIntensity,
            fogColor: try c.decodeIfPresent(Vec3.self, forKey: .fogColor) ?? d.fogColor,
            fogDensity: try c.decodeIfPresent(Float.self, forKey: .fogDensity) ?? d.fogDensity,
            sky: try c.decodeIfPresent(SkyMode.self, forKey: .sky) ?? d.sky,
            environmentMap: try c.decodeIfPresent(TextureHandle.self, forKey: .environmentMap),
            environmentIntensity: try c.decodeIfPresent(Float.self, forKey: .environmentIntensity) ?? d.environmentIntensity,
            environmentRotation: try c.decodeIfPresent(Float.self, forKey: .environmentRotation) ?? d.environmentRotation,
            imageBasedLighting: try c.decodeIfPresent(Bool.self, forKey: .imageBasedLighting) ?? d.imageBasedLighting,
            proceduralSky: try c.decodeIfPresent(ProceduralSky.self, forKey: .proceduralSky) ?? d.proceduralSky)
    }
}

/// What `SceneEnvironment` draws behind the scene.
public enum SkyMode: String, Codable, CaseIterable, Sendable {
    /// The camera's clear color, and the hemisphere ambient (the default; scenes look as before).
    case color
    /// `ProceduralSky`: a gradient sky with the sun's disk where the directional light comes
    /// from. Needs no asset; recomputed when the light or the parameters change.
    case procedural
    /// `SceneEnvironment.environmentMap`, an equirectangular HDR image (`.color` applies until
    /// it is available).
    case map
}

/// An analytic sky (`SkyMode.procedural`): a gradient from `horizonColor` to `zenithColor`,
/// `groundColor` below a soft horizon, a glow around the sun and the sun's disk, both in the
/// first `DirectionalLight`'s direction and color x intensity. Linear radiance, before
/// `SceneEnvironment.environmentIntensity`. The disk is drawn but left out of the image-based
/// lighting (the directional light already provides that light).
public struct ProceduralSky: Codable, Equatable, Sendable {
    public var zenithColor: Vec3
    public var horizonColor: Vec3
    public var groundColor: Vec3
    /// Angular radius of the sun's disk in radians (the real sun's is about 0.0047).
    public var sunSize: Float
    /// The disk's radiance relative to the light's color x intensity.
    public var sunIntensity: Float
    /// Strength of the glow around the sun, relative to the light's color x intensity.
    public var sunGlow: Float

    public init(zenithColor: Vec3 = Vec3(0.12, 0.26, 0.62), horizonColor: Vec3 = Vec3(0.55, 0.62, 0.74),
                groundColor: Vec3 = Vec3(0.13, 0.12, 0.11), sunSize: Float = 0.012, sunIntensity: Float = 40, sunGlow: Float = 0.5) {
        self.zenithColor = zenithColor
        self.horizonColor = horizonColor
        self.groundColor = groundColor
        self.sunSize = sunSize
        self.sunIntensity = sunIntensity
        self.sunGlow = sunGlow
    }

    /// Missing fields take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ProceduralSky()
        self.init(zenithColor: try c.decodeIfPresent(Vec3.self, forKey: .zenithColor) ?? d.zenithColor,
                  horizonColor: try c.decodeIfPresent(Vec3.self, forKey: .horizonColor) ?? d.horizonColor,
                  groundColor: try c.decodeIfPresent(Vec3.self, forKey: .groundColor) ?? d.groundColor,
                  sunSize: try c.decodeIfPresent(Float.self, forKey: .sunSize) ?? d.sunSize,
                  sunIntensity: try c.decodeIfPresent(Float.self, forKey: .sunIntensity) ?? d.sunIntensity,
                  sunGlow: try c.decodeIfPresent(Float.self, forKey: .sunGlow) ?? d.sunGlow)
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
