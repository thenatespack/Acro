#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineScene

// The Mesh Builder's data types that `MeshBuildPart` (MeshBuild.swift) is made of. The
// algorithms that use them, and the notes on what each field does, are in the EngineMeshBuild
// module (in the file each MARK names); the types stay here because EngineRendering
// sees mesh builds through path, terrain and character data, and must not wait for that module.

// MARK: - Mirror and repeat (EngineMeshBuild/MeshBuildExpansion.swift)

/// The axes a part is mirrored across (in its parent's space): `"x"` or several `["x", "z"]`.
public struct MeshBuildMirror: Codable, Equatable, Sendable, ExpressibleByArrayLiteral {
    /// In x, y, z order, each once.
    public private(set) var axes: [MeshBuildAxis]

    public init(_ axes: [MeshBuildAxis]) { self.axes = MeshBuildAxis.allCases.filter(axes.contains) }
    public init(arrayLiteral axes: MeshBuildAxis...) { self.init(axes) }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let one = try? c.decode(MeshBuildAxis.self) { self.init([one]) } else { self.init(try c.decode([MeshBuildAxis].self)) }
    }

    /// One axis as a string, several as an array.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        if axes.count == 1 { try c.encode(axes[0]) } else { try c.encode(axes) }
    }
}

/// Copies of a part (and its subtree) in a line and/or a ring; see the notes in EngineMeshBuild/MeshBuildExpansion.swift.
public struct MeshBuildRepeat: Codable, Equatable, Sendable {
    /// A ring of copies about an axis of the parent.
    public struct Radial: Codable, Equatable, Sendable {
        public var axis: MeshBuildAxis
        /// nil: the ring turns about the parent's origin. Set: it is centered on the part's
        /// position, each copy this far out.
        public var radius: Float?
        /// Degrees the ring spans (360: evenly spaced all round; less: from 0 to `angle`, both ends).
        public var angle: Float

        public init(axis: MeshBuildAxis = .y, radius: Float? = nil, angle: Float = 360) {
            self.axis = axis
            self.radius = radius
            self.angle = angle
        }

        private enum CodingKeys: String, CodingKey { case axis, radius, angle }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.init(axis: try c.decodeIfPresent(MeshBuildAxis.self, forKey: .axis) ?? .y,
                      radius: try c.decodeIfPresent(Float.self, forKey: .radius),
                      angle: try c.decodeIfPresent(Float.self, forKey: .angle) ?? 360)
        }
    }

    /// Parts in all, the original included (1...`maxCount`).
    public var count: Int
    /// Each copy's step from the previous one, meters in the parent's space.
    public var offset: Vec3
    public var radial: Radial?

    public static let maxCount = 256

    public init(count: Int = 2, offset: Vec3 = .zero, radial: Radial? = nil) {
        self.count = count
        self.offset = offset
        self.radial = radial
    }

    private enum CodingKeys: String, CodingKey { case count, offset, radial }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(count: try c.decodeIfPresent(Int.self, forKey: .count) ?? 2,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? .zero,
                  radial: try c.decodeIfPresent(Radial.self, forKey: .radial))
    }

    /// The `index`th part's turn (degrees) about the ring's axis.
    package func angle(of index: Int, count: Int) -> Float {
        guard let radial, count > 1 else { return 0 }
        let step = abs(radial.angle) >= 359.999 ? radial.angle / Float(count) : radial.angle / Float(count - 1)
        return step * Float(index)
    }
}

// MARK: - Loft sections (EngineMeshBuild/MeshBuildCurves.swift)

extension MeshBuildAxis {
    /// The axes a loft section along this axis spans, [across, other]: y → (x, z), z → (x, y), x → (z, y).
    package var sectionAxes: (u: Int, v: Int) {
        switch self {
        case .y: (0, 2)
        case .z: (0, 1)
        case .x: (2, 1)
        }
    }
}

/// Where a loft section sits: a distance along the loft's axis (`"at": 0.4`), or its center in
/// the part's space (`"at": [0, 0.4, 0.1]`), which also shifts it sideways.
public enum MeshBuildSectionPosition: Codable, Equatable, Sendable {
    case along(Float)
    case point(Vec3)

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let x = try? c.decode(Float.self) {
            self = .along(x)
        } else if let v = try? c.decode([Float].self) {
            self = v.count >= 2 ? .point(Vec3(v[0], v[1], v.count > 2 ? v[2] : 0)) : .along(v.first ?? 0)
        } else {
            self = .along(0)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .along(let x): try c.encode(x)
        case .point(let p): try c.encode(p)
        }
    }

    /// The coordinate along `axis` and the offset across it (section [across, other]) for a point.
    public func split(_ axis: MeshBuildAxis) -> (along: Float, offset: Vec2) {
        switch self {
        case .along(let x): return (x, .zero)
        case .point(let p):
            let (u, v) = axis.sectionAxes
            return (p[axis.index], Vec2(p[u], p[v]))
        }
    }
}

/// One cross-section of a `loft` (see the notes in EngineMeshBuild/MeshBuildCurves.swift).
public struct MeshBuildSection: Codable, Equatable, Sendable {
    public var at: MeshBuildSectionPosition
    /// [across, other] meters (default [0.5, 0.5]); with a `profile`, a multiplier (default [1, 1]).
    public var size: Vec2?
    /// 0 diamond, 1 ellipse (default), 2 squircle, 3 rounded box, 4+ nearly a box.
    public var roundness: Float?
    /// An outline [[across, other], ...] meters around the section's center, instead of the superellipse.
    public var profile: [Vec2]?

    public static let defaultSize = Vec2(0.5, 0.5)

    public init(at: Float, size: Vec2? = nil, roundness: Float? = nil, profile: [Vec2]? = nil) {
        self.init(at: .along(at), size: size, roundness: roundness, profile: profile)
    }

    public init(center: Vec3, size: Vec2? = nil, roundness: Float? = nil, profile: [Vec2]? = nil) {
        self.init(at: .point(center), size: size, roundness: roundness, profile: profile)
    }

    public init(at: MeshBuildSectionPosition, size: Vec2? = nil, roundness: Float? = nil, profile: [Vec2]? = nil) {
        self.at = at
        self.size = size
        self.roundness = roundness
        self.profile = profile
    }

    private enum CodingKeys: String, CodingKey { case at, size, roundness, profile }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(at: (try? c.decodeIfPresent(MeshBuildSectionPosition.self, forKey: .at)) ?? .along(0),
                  size: try? c.decodeIfPresent(Vec2.self, forKey: .size),
                  roundness: try? c.decodeIfPresent(Float.self, forKey: .roundness),
                  profile: try? c.decodeIfPresent([Vec2].self, forKey: .profile))
    }
}

// MARK: - Deformers (EngineMeshBuild/MeshBuildDeform.swift)

/// One deformer of a part's `deform` list; set one of its fields (see the notes in EngineMeshBuild/MeshBuildDeform.swift).
public struct MeshBuildDeform: Codable, Equatable, Sendable {
    public struct Bend: Codable, Equatable, Sendable {
        /// The way the top leans: x or z.
        public var axis: MeshBuildAxis
        public var degrees: Float

        public init(axis: MeshBuildAxis = .x, degrees: Float = 30) {
            self.axis = axis
            self.degrees = degrees
        }

        private enum CodingKeys: String, CodingKey { case axis, degrees }

        /// An object, or just a number of degrees (toward x).
        public init(from decoder: any Decoder) throws {
            if let degrees = try? decoder.singleValueContainer().decode(Float.self) {
                self.init(degrees: degrees)
                return
            }
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.init(axis: (try? c.decodeIfPresent(MeshBuildAxis.self, forKey: .axis)) ?? .x,
                      degrees: (try? c.decodeIfPresent(Float.self, forKey: .degrees)) ?? 30)
        }
    }

    public struct Noise: Codable, Equatable, Sendable {
        /// How far the surface moves in and out, meters (about the most).
        public var amount: Float
        /// How large the lumps are, meters.
        public var scale: Float
        public var seed: Int

        public init(amount: Float = 0.02, scale: Float = 0.2, seed: Int = 0) {
            self.amount = amount
            self.scale = scale
            self.seed = seed
        }

        private enum CodingKeys: String, CodingKey { case amount, scale, seed }

        /// An object, or just an amount.
        public init(from decoder: any Decoder) throws {
            if let amount = try? decoder.singleValueContainer().decode(Float.self) {
                self.init(amount: amount)
                return
            }
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let seed = (try? c.decodeIfPresent(Int.self, forKey: .seed))
                ?? (try? c.decodeIfPresent(Float.self, forKey: .seed)).flatMap { $0.map { $0.isFinite ? Int($0.rounded()) : 0 } }
            self.init(amount: (try? c.decodeIfPresent(Float.self, forKey: .amount)) ?? 0.02,
                      scale: (try? c.decodeIfPresent(Float.self, forKey: .scale)) ?? 0.2, seed: seed ?? 0)
        }
    }

    /// The scale across [x, z] at the top relative to the bottom.
    public var taper: Vec2?
    public var bend: Bend?
    /// Degrees about Y at the top.
    public var twist: Float?
    public var noise: Noise?

    public init(taper: Vec2? = nil, bend: Bend? = nil, twist: Float? = nil, noise: Noise? = nil) {
        self.taper = taper
        self.bend = bend
        self.twist = twist
        self.noise = noise
    }

    public static func taper(_ x: Float, _ z: Float) -> MeshBuildDeform { MeshBuildDeform(taper: Vec2(x, z)) }
    public static func bend(_ axis: MeshBuildAxis, _ degrees: Float) -> MeshBuildDeform {
        MeshBuildDeform(bend: Bend(axis: axis, degrees: degrees))
    }
    public static func twist(_ degrees: Float) -> MeshBuildDeform { MeshBuildDeform(twist: degrees) }
    public static func noise(_ amount: Float, scale: Float, seed: Int = 0) -> MeshBuildDeform {
        MeshBuildDeform(noise: Noise(amount: amount, scale: scale, seed: seed))
    }

    private enum CodingKeys: String, CodingKey { case taper, bend, twist, noise }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var taper = try? c.decodeIfPresent(Vec2.self, forKey: .taper)
        if taper == nil, let k = try? c.decodeIfPresent(Float.self, forKey: .taper) { taper = Vec2(k, k) }
        self.init(taper: taper, bend: try? c.decodeIfPresent(Bend.self, forKey: .bend),
                  twist: try? c.decodeIfPresent(Float.self, forKey: .twist), noise: try? c.decodeIfPresent(Noise.self, forKey: .noise))
    }

    /// What it does, for lists ("taper 0.5 × 0.5", "bend x 30°"…).
    public var summary: String {
        var parts: [String] = []
        if let taper { parts.append(String(format: "taper %g × %g", taper.x, taper.y)) }
        if let twist { parts.append(String(format: "twist %g°", twist)) }
        if let bend { parts.append("bend \(bend.axis.rawValue) " + String(format: "%g°", bend.degrees)) }
        if let noise { parts.append(String(format: "noise %g m / %g m, seed %d", noise.amount, noise.scale, noise.seed)) }
        return parts.isEmpty ? "nothing" : parts.joined(separator: ", ")
    }
}

// MARK: - Sculpting (EngineMeshBuild/MeshBuildSculpt.swift)

/// How a sculpt child combines with the shape made by the children before it.
public enum MeshBuildBlend: String, Codable, CaseIterable, Sendable {
    /// Joined on (union).
    case add
    /// Cut out (difference).
    case subtract
    /// Only where both are (intersection).
    case intersect
}

/// Bumps on a sculpt's surface: up to `amount` meters in or out, features about `scale` meters across.
public struct MeshBuildNoise: Codable, Equatable, Sendable {
    public var amount: Float
    public var scale: Float
    public var seed: Int

    public init(amount: Float = 0.02, scale: Float = 0.2, seed: Int = 0) {
        self.amount = amount
        self.scale = scale
        self.seed = seed
    }

    private enum CodingKeys: String, CodingKey { case amount, scale, seed }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(amount: try c.decodeIfPresent(Float.self, forKey: .amount) ?? 0.02,
                  scale: try c.decodeIfPresent(Float.self, forKey: .scale) ?? 0.2,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? 0)
    }
}

/// A part combined into a sculpt (`MeshBuildPart.sculptChildren`): its fields and its placement in the sculpt's space.
public struct MeshBuildSculptChild: Equatable, Sendable {
    public var part: MeshBuildPart
    public var position: Vec3
    public var rotation: Quat

    public init(part: MeshBuildPart, position: Vec3, rotation: Quat) {
        self.part = part
        self.position = position
        self.rotation = rotation
    }
}

// MARK: - Foliage (EngineMeshBuild/MeshBuildFoliage.swift)

/// What a foliage part grows on, resolved in its own space (`MeshBuild.attachingFoliageTargets`).
public struct MeshBuildFoliageTarget: Equatable, Sendable {
    public var name: String
    /// A sweep's spine: points, unit tangents and the radius at each.
    public var path: [Vec3] = []
    public var tangents: [Vec3] = []
    public var radii: [Float] = []
    /// Another mesh's triangles.
    public var positions: [Vec3] = []
    public var normals: [Vec3] = []
    public var indices: [UInt32] = []

    package init(name: String) { self.name = name }
}
