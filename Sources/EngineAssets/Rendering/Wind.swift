/// Wind: a scene-wide breeze (`SceneEnvironment.wind`) that sways the meshes whose material opts
/// in (`Material.wind` / `MaterialAsset.wind`, a `MaterialWind`). Mesh build plants opt in by
/// default: leaves flutter, trunks and branches bend with them (MeshBuildLOD.swift).
///
/// The sway runs in the vertex shader (wind.glsl, in mesh_wind.vert and mesh_shadow_wind.vert),
/// from the object-space position and the material's numbers alone (no vertex attribute), in the
/// lit, shadow and depth passes alike, on Metal and Vulkan. Materials without wind draw with the
/// usual shaders, unchanged. `WindSway.offset` is the shader's function on the CPU (tests).
import Foundation
import EngineCore
import EngineScene

/// The scene's wind (`SceneEnvironment.wind`). Keys missing from scene files take the defaults.
public struct Wind: Codable, Equatable, Sendable {
    public static var fieldHints: [String: FieldHints] {
        ["direction": FieldHints(tooltip: "Where the wind blows toward (world space; only X and Z count)"),
         "strength": FieldHints(range: 0...3, step: 0.05, tooltip: "0 calm, 0.5 a breeze, 1 windy, 2+ a storm"),
         "gustiness": FieldHints(range: 0...1, step: 0.05, tooltip: "How much gusts come and go (0: steady)")]
    }

    /// Where the wind blows toward, in world space (Y is ignored; zero blows toward +X).
    public var direction: Vec3
    /// 0 calm, 0.5 a light breeze (the default), 1 windy, 2 and more a storm.
    public var strength: Float
    /// 0...1: how much the strength rises and falls in slow gusts (rolling across the scene along
    /// the wind) around its average.
    public var gustiness: Float

    public init(direction: Vec3 = Vec3(1, 0, 0.35), strength: Float = 0.5, gustiness: Float = 0.5) {
        self.direction = direction
        self.strength = strength
        self.gustiness = gustiness
    }

    /// No wind: swaying materials stand still.
    public static let calm = Wind(strength: 0)

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Wind()
        self.init(direction: try c.decodeIfPresent(Vec3.self, forKey: .direction) ?? d.direction,
                  strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength,
                  gustiness: try c.decodeIfPresent(Float.self, forKey: .gustiness) ?? d.gustiness)
    }

    /// The unit direction in the XZ plane (x, z); +X when `direction` has no horizontal part.
    public var horizontalDirection: Vec2 {
        let d = Vec2(direction.x, direction.z)
        let l = (d.x * d.x + d.y * d.y).squareRoot()
        return l > 1e-6 && l.isFinite ? d / l : Vec2(1, 0)
    }

    /// The strength the shader uses (finite, 0...10).
    public var effectiveStrength: Float { strength.isFinite ? min(max(strength, 0), 10) : 0 }
    /// The gustiness the shader uses (finite, 0...1).
    public var effectiveGustiness: Float { gustiness.isFinite ? min(max(gustiness, 0), 1) : 0 }
}

/// How a material sways in the scene's `Wind` (see `WindSway`). A plant's parts each have their
/// own material, all with the same `origin` and `up` (in each mesh's own space), so they bend as one.
public struct MaterialWind: Codable, Equatable, Sendable {
    /// The small fast wobble of leaves: 1 for leaves, about 0.1 for branches, 0 for none.
    public var flutter: Float
    /// Scales the trunk bend (1 for plants, 0 for flutter only, as for ivy on a wall).
    public var bend: Float
    /// The plant's height in meters above `origin`: the bend grows with the square of the height
    /// and reaches its full amount here (0: no bend, flutter only).
    public var height: Float
    /// Where the plant stands, in the mesh's own space: the point that doesn't move.
    public var origin: Vec3
    /// The plant's up axis in the mesh's own space (normalized when used).
    public var up: Vec3

    public init(flutter: Float = 1, bend: Float = 1, height: Float = 1, origin: Vec3 = .zero, up: Vec3 = Vec3(0, 1, 0)) {
        self.flutter = flutter
        self.bend = bend
        self.height = height
        self.origin = origin
        self.up = up
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialWind()
        self.init(flutter: try c.decodeIfPresent(Float.self, forKey: .flutter) ?? d.flutter,
                  bend: try c.decodeIfPresent(Float.self, forKey: .bend) ?? d.bend,
                  height: try c.decodeIfPresent(Float.self, forKey: .height) ?? d.height,
                  origin: try c.decodeIfPresent(Vec3.self, forKey: .origin) ?? d.origin,
                  up: try c.decodeIfPresent(Vec3.self, forKey: .up) ?? d.up)
    }

    /// The shader's `plant` vector: xyz the origin, w the flutter (finite, 0...4).
    public var plantVector: Vec4 {
        let f = flutter.isFinite ? min(max(flutter, 0), 4) : 0
        let o = origin.x.isFinite && origin.y.isFinite && origin.z.isFinite ? origin : .zero
        return Vec4(o, f)
    }

    /// The shader's `axis` vector: xyz the unit up axis, w bend / height (0 without a bend).
    public var axisVector: Vec4 {
        let l = length(up)
        let u = l > 1e-6 && l.isFinite ? up / l : Vec3(0, 1, 0)
        let b = bend.isFinite ? min(max(bend, 0), 4) : 0
        let h = height.isFinite && height > 0.01 ? b / height : 0
        return Vec4(u, h)
    }
}

/// The wind sway of wind.glsl on the CPU (the same formula, for tests and tools).
public enum WindSway {
    /// The object-space offset of object-space `position` at `time` seconds, for a mesh with
    /// `material` drawn with the model matrix `model` in `wind`. Zero at the plant's base (and
    /// anywhere below it), growing with the height above it.
    public static func offset(_ position: Vec3, material: MaterialWind, wind: Wind, model: Mat4 = .identity, time: Float) -> Vec3 {
        let plant = material.plantVector, axis = material.axisVector
        let origin = Vec3(plant.x, plant.y, plant.z), up = Vec3(axis.x, axis.y, axis.z)
        let b = model * Vec4(origin, 1)
        let base = Vec3(b.x, b.y, b.z)
        let h = max(dot(up, position - origin), 0)
        let strength = wind.effectiveStrength
        let dir = wind.horizontalDirection
        let phase = (base.x * dir.x + base.z * dir.y) * 0.35 + (base.x * 0.83 + base.z * -0.57) * 1.7
        let g = 0.5 + 0.5 * sinf(time * 0.61 + phase) * sinf(time * 0.23 + phase * 0.7)
        let gust = 1 + wind.effectiveGustiness * (g * 1.6 - 0.6)
        let sway = 0.75 + 0.25 * sinf(time * 1.7 + phase * 1.3)
        let bend = strength * gust * sway * 0.06 * h * h * axis.w
        // transpose(basis) * (dir.x, 0, dir.y): the basis's columns dotted with the direction.
        let world = Vec3(dir.x, 0, dir.y)
        var along = Vec3(dot(Vec3(model.c0.x, model.c0.y, model.c0.z), world), dot(Vec3(model.c1.x, model.c1.y, model.c1.z), world),
                         dot(Vec3(model.c2.x, model.c2.y, model.c2.z), world))
        let n2 = dot(along, along)
        along = n2 > 1e-12 ? along / n2.squareRoot() : .zero
        var offset = along * bend - up * (0.5 * bend * bend / max(h, 1e-3))
        let n = dot(position, Vec3(3.1, 2.3, 2.7))
        let wave = sinf(time * 7.3 + n + phase) + 0.5 * sinf(time * 11.1 + n * 1.7 + phase * 2.1)
        let flutter = plant.w * strength * (0.6 + 0.4 * gust) * min(max(h * 3, 0), 1) * 0.02 * wave
        offset += Vec3(sinf(n * 1.3 + 1), cosf(n * 0.9), sinf(n * 1.7 + 2)) * flutter
        return offset
    }

    /// The most a point `height` meters above the base of a plant `plantHeight` tall can bend
    /// (strength x the strongest gust x the full sway), in meters along the wind.
    public static func maxBend(height: Float, plantHeight: Float, wind: Wind) -> Float {
        guard plantHeight > 0.01 else { return 0 }
        return wind.effectiveStrength * (1 + wind.effectiveGustiness) * 0.06 * height * height / plantHeight
    }
}
