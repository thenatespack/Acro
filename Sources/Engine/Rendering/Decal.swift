/// A projector box that paints a texture onto the opaque geometry inside it (graffiti, grime,
/// wet patches). The box is the unit cube (-0.5...0.5 on each axis) in the entity's world
/// transform, scale included. The texture is projected along the entity's forward axis (local
/// -Z, the camera / light convention) onto the XY plane: u runs along +X, v down along -Y.
/// Aim it by looking at the surface (`Transform.looking`); for a floor, point -Z down.
///
/// `SceneRenderer` draws decals after the opaque meshes and before the sky and the transparent
/// ones (see `SceneRenderer+Decals.swift`): glass and particles are never painted, and cost is
/// zero while the world has none. Decals are lit like a PBR surface (ambient or environment,
/// the sun with its shadow, point and spot lights) with the normal rebuilt from the depth
/// prepass, and fogged like meshes.
public struct Decal: Component, Codable, Equatable, Sendable {
    public static let componentName = "Decal"
    public static var fieldHints: [String: FieldHints] {
        ["tint": FieldHints(color: true, tooltip: "Linear RGB multiplied with the texture"),
         "opacity": FieldHints(range: 0...1, step: 0.01),
         "emissive": FieldHints(range: 0...100, step: 0.1, tooltip: "Unlit glow added on top, in multiples of the color (neon paint)"),
         "roughness": FieldHints(range: 0.045...1, step: 0.01,
                                 tooltip: "Low values give wet, reflective patches (specular from the sun, lights and environment)"),
         "angleFade": FieldHints(range: 0...1, step: 0.01,
                                 tooltip: "Fades out on surfaces turned away from the projection axis: alpha = cos(angle) / angleFade; 0 disables"),
         "sortOrder": FieldHints(tooltip: "Decals with a higher order are drawn on top of lower ones")]
    }

    /// The projected image (RGBA; its alpha is the decal's coverage). nil: a flat `tint`.
    public var texture: TextureHandle?
    /// Linear RGB multiplied with the texture.
    public var tint: Vec3
    /// Overall alpha, 0...1.
    public var opacity: Float
    /// Unlit glow: the decal's color times this is added to its lit color (0: none).
    public var emissive: Float
    /// Perceptual roughness of the painted surface (a dielectric: F0 0.04).
    public var roughness: Float
    /// Alpha falls off as cos(angle between the surface normal and the way back to the
    /// projector) / `angleFade`, so surfaces at a grazing angle or facing away fade out; 0: off.
    public var angleFade: Float
    /// Overlapping decals draw in ascending order (ties by entity index).
    public var sortOrder: Int
    public var isVisible: Bool

    public init(texture: TextureHandle? = nil, tint: Vec3 = Vec3(1, 1, 1), opacity: Float = 1, emissive: Float = 0,
                roughness: Float = 0.9, angleFade: Float = 0.5, sortOrder: Int = 0, isVisible: Bool = true) {
        self.texture = texture
        self.tint = tint
        self.opacity = opacity
        self.emissive = emissive
        self.roughness = roughness
        self.angleFade = angleFade
        self.sortOrder = sortOrder
        self.isVisible = isVisible
    }

    /// Missing fields take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Decal()
        texture = try c.decodeIfPresent(TextureHandle.self, forKey: .texture)
        tint = try c.decodeIfPresent(Vec3.self, forKey: .tint) ?? d.tint
        opacity = try c.decodeIfPresent(Float.self, forKey: .opacity) ?? d.opacity
        emissive = try c.decodeIfPresent(Float.self, forKey: .emissive) ?? d.emissive
        roughness = try c.decodeIfPresent(Float.self, forKey: .roughness) ?? d.roughness
        angleFade = try c.decodeIfPresent(Float.self, forKey: .angleFade) ?? d.angleFade
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? d.sortOrder
        isVisible = try c.decodeIfPresent(Bool.self, forKey: .isVisible) ?? d.isVisible
    }

    /// The world-space bounds (center, half extent) of the projector box under `matrix`.
    public static func bounds(of matrix: Mat4) -> (center: Vec3, halfExtent: Vec3) {
        func axis(_ c: Vec4) -> Vec3 { Vec3(abs(c.x), abs(c.y), abs(c.z)) }
        return (Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z), (axis(matrix.c0) + axis(matrix.c1) + axis(matrix.c2)) * 0.5)
    }
}
