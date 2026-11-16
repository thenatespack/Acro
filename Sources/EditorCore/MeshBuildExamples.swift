import Engine
import Foundation

// `meshBuild.examples`: a few small, correct mesh builds to copy from. Each one stands on y = 0,
// faces -Z, has every part touching another and gives no warnings (MeshBuildToolsTests checks).

/// A ready-made mesh build and what it shows.
public struct MeshBuildExample: Codable, Equatable, Sendable {
    public var name: String
    /// What it demonstrates.
    public var about: String
    public var build: MeshBuild
}

public enum MeshBuildExamples {
    public static var all: [MeshBuildExample] { [streetLamp, cart, turret, armchair, stoneArch] }

    static let iron = Vec3(0.18, 0.19, 0.2)
    static let wood = Vec3(0.55, 0.36, 0.2)

    /// A pole on a foot with an arm reaching forward, a shade and a glowing bulb: a parent chain
    /// where each position is in the parent's space.
    public static var streetLamp: MeshBuildExample {
        MeshBuildExample(name: "Street Lamp", about: "3.8 m tall. A parent chain (Base > Pole > Arm > Shade > Bulb): each position is the part's center in its parent's space, so the pole's 1.9 is half its 3.6 m height above the foot's center. The arm reaches forward (-Z). The bulb glows.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.1, 0), size: Vec3(0.4, 0.2, 0.4), color: iron,
                          metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Pole", shape: .cylinder, parent: "Base", position: Vec3(0, 1.9, 0), size: Vec3(0.12, 3.6, 0.12),
                          color: iron, metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Arm", shape: .box, parent: "Pole", position: Vec3(0, 1.7, -0.3), size: Vec3(0.08, 0.08, 0.7),
                          color: iron, metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Shade", shape: .cone, parent: "Arm", position: Vec3(0, -0.1, -0.3), size: Vec3(0.45, 0.3, 0.45),
                          color: Vec3(0.12, 0.3, 0.2), metallic: 0.3, roughness: 0.5),
            MeshBuildPart(name: "Bulb", shape: .sphere, parent: "Shade", position: Vec3(0, -0.15, 0), size: Vec3(0.18, 0.18, 0.18),
                          color: Vec3(1, 0.95, 0.8), glow: Vec3(1, 0.85, 0.55), glowStrength: 4),
        ]))
    }

    /// A wooden cart, 2 m long, front at -Z: wheels turned onto the X axle with rotation [0,0,90].
    public static var cart: MeshBuildExample {
        func wheel(_ name: String, _ x: Float, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(x, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.8, 0.1, 0.8), color: Vec3(0.3, 0.2, 0.12), roughness: 0.8)
        }
        func axle(_ name: String, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(0, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.06, 1.3, 0.06), color: iron, metallic: 0.6, roughness: 0.4)
        }
        return MeshBuildExample(name: "Wooden Cart", about: "2 m long, front (the shaft) at -Z. Cylinders run along Y, so wheels and axles on an axle along X use rotation [0,0,90]. The wheels' 0.8 m diameter puts their centers 0.4 m up and their bottoms on y=0; they touch the bed's sides. The Roll animation (autoplay off) spins the wheels about their own axis (motion axis y).", build: MeshBuild(parts: [
            MeshBuildPart(name: "Bed", shape: .box, position: Vec3(0, 0.6, 0), size: Vec3(1.2, 0.15, 2), color: wood, roughness: 0.8),
            MeshBuildPart(name: "Side L", shape: .box, parent: "Bed", position: Vec3(-0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Side R", shape: .box, parent: "Bed", position: Vec3(0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Front", shape: .box, parent: "Bed", position: Vec3(0, 0.25, -0.96), size: Vec3(1.04, 0.35, 0.08),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Shaft", shape: .box, parent: "Bed", position: Vec3(0, -0.05, -1.45), size: Vec3(0.08, 0.08, 1),
                          color: wood, roughness: 0.8),
            axle("Front Axle", -0.6), axle("Back Axle", 0.6),
            wheel("Wheel FL", -0.65, -0.6), wheel("Wheel FR", 0.65, -0.6), wheel("Wheel BL", -0.65, 0.6), wheel("Wheel BR", 0.65, 0.6),
        ], animations: [
            MeshBuildAnimation(name: "Roll", autoplay: false, motions: ["Wheel FL", "Wheel FR", "Wheel BL", "Wheel BR"].map {
                MeshBuildMotion(part: $0, kind: .spin, axis: .y, period: 1.5)
            }),
        ]))
    }

    /// A small gun turret whose head sweeps from side to side on a group pivot.
    public static var turret: MeshBuildExample {
        MeshBuildExample(name: "Turret", about: "1.2 m wide. A group part (Pivot) is a hinge with no mesh: the head hangs from it and the Scan animation swings the pivot 40 degrees each way about Y, so everything on it turns together. The barrel is a cylinder turned with rotation [90,0,0] to point forward (-Z); the muzzle is its child, so it inherits that rotation and sits at the barrel's local y=-0.5 end.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.15, 0), size: Vec3(1.2, 0.3, 1.2), color: Vec3(0.35, 0.37, 0.4),
                          metallic: 0.7, roughness: 0.35),
            MeshBuildPart(name: "Pivot", shape: .group, parent: "Base", position: Vec3(0, 0.15, 0)),
            MeshBuildPart(name: "Head", shape: .box, parent: "Pivot", position: Vec3(0, 0.25, 0), size: Vec3(0.8, 0.5, 0.9),
                          color: Vec3(0.45, 0.5, 0.35), metallic: 0.4, roughness: 0.5),
            MeshBuildPart(name: "Barrel", shape: .cylinder, parent: "Head", position: Vec3(0, 0.05, -0.85), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.12, 1, 0.12), color: iron, metallic: 0.8, roughness: 0.3),
            MeshBuildPart(name: "Muzzle", shape: .cylinder, parent: "Barrel", position: Vec3(0, -0.5, 0), size: Vec3(0.18, 0.15, 0.18),
                          color: iron, metallic: 0.8, roughness: 0.3),
            MeshBuildPart(name: "Sensor", shape: .sphere, parent: "Head", position: Vec3(0.25, 0.3, 0.1), size: Vec3(0.2, 0.2, 0.2),
                          color: Vec3(0.9, 0.1, 0.05), glow: Vec3(1, 0.1, 0.05), glowStrength: 3),
        ], animations: [
            MeshBuildAnimation(name: "Scan", motions: [MeshBuildMotion(part: "Pivot", kind: .swing, axis: .y, amount: 40, period: 4)]),
        ]))
    }
}

// MARK: Sculpts

extension MeshBuildPart {
    /// This part with its sculpt fields set (for building examples in code).
    func sculpting(blend: MeshBuildBlend? = nil, smooth: Float? = nil, resolution: Int? = nil, noise: MeshBuildNoise? = nil) -> MeshBuildPart {
        var part = self
        part.blend = blend
        part.smooth = smooth
        part.resolution = resolution
        part.noise = noise
        return part
    }
}

extension MeshBuildExamples {
    /// An upholstered armchair: a sculpt frame whose back and rolled arms melt into the base, a
    /// second sculpt for the puffy cushions (another color) and turned wooden legs.
    public static var armchair: MeshBuildExample {
        let fabric = Vec3(0.27, 0.33, 0.27), linen = Vec3(0.62, 0.58, 0.48)
        return MeshBuildExample(name: "Armchair", about: "0.9 m wide, seat 0.47 m high, front at -Z. Two sculpts: Frame (base, back tilted 8° back, arms and rolled arm tops mirrored on x) melts its parts together with small smooth radii (0.02-0.04 m; larger radii on faces that line up bulge at the seam), and Cushions (a bevelled box plus a flattened sphere smoothed in for a puffy top, front and back) is a separate sculpt because a sculpt has one color. The tapered legs are lathes mirrored on x and z, touching the frame's underside at y=0.1.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Frame", shape: .sculpt, position: Vec3(0, 0.1, 0), color: fabric, roughness: 0.9),
            MeshBuildPart(name: "Base", parent: "Frame", position: Vec3(0, 0.125, 0), size: Vec3(0.8, 0.25, 0.78), bevel: 0.05),
            MeshBuildPart(name: "Back", parent: "Frame", position: Vec3(0, 0.42, 0.32), rotation: Vec3(-8, 0, 0), size: Vec3(0.84, 0.82, 0.16),
                          bevel: 0.07).sculpting(smooth: 0.04),
            MeshBuildPart(name: "Left Arm", parent: "Frame", position: Vec3(-0.35, 0.27, -0.01), size: Vec3(0.15, 0.52, 0.8), bevel: 0.06,
                          mirror: [.x]).sculpting(smooth: 0.02),
            MeshBuildPart(name: "Left Roll", shape: .capsule, parent: "Frame", position: Vec3(-0.355, 0.54, -0.02), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.18, 0.8, 0.15), mirror: [.x]).sculpting(smooth: 0.03),
            MeshBuildPart(name: "Cushions", shape: .sculpt, position: Vec3(0, 0.35, 0), color: linen, roughness: 0.95),
            MeshBuildPart(name: "Seat", parent: "Cushions", position: Vec3(0, 0.06, -0.06), size: Vec3(0.53, 0.12, 0.64), bevel: 0.05),
            MeshBuildPart(name: "Puff", shape: .sphere, parent: "Cushions", position: Vec3(0, 0.08, -0.06), size: Vec3(0.48, 0.1, 0.58))
                .sculpting(smooth: 0.04),
            MeshBuildPart(name: "Back Cushion", parent: "Cushions", position: Vec3(0, 0.34, 0.2), rotation: Vec3(-10, 0, 0),
                          size: Vec3(0.53, 0.46, 0.14), bevel: 0.06),
            MeshBuildPart(name: "Back Puff", shape: .sphere, parent: "Cushions", position: Vec3(0, 0.34, 0.19), rotation: Vec3(-10, 0, 0),
                          size: Vec3(0.46, 0.4, 0.15)).sculpting(smooth: 0.04),
            MeshBuildPart(name: "Front Left Leg", shape: .lathe, position: Vec3(-0.35, 0, -0.32), color: Vec3(0.28, 0.17, 0.09), roughness: 0.5,
                          profile: [Vec2(0, 0), Vec2(0.018, 0), Vec2(0.028, 0.1), Vec2(0, 0.1)], mirror: [.x, .z]),
        ]))
    }

    /// A weathered stone arch: one sculpt carved with subtracts (the opening, mortar joints) and roughened with noise.
    public static var stoneArch: MeshBuildExample {
        func joint(_ name: String, at position: Vec3, size: Vec3, rotation: Vec3 = .zero, mirror: MeshBuildMirror, repeat r: MeshBuildRepeat) -> MeshBuildPart {
            MeshBuildPart(name: name, parent: "Arch", position: position, rotation: rotation, size: size, mirror: mirror, repetition: r)
                .sculpting(blend: .subtract, smooth: 0.006)
        }
        return MeshBuildExample(name: "Stone Arch", about: "2.6 m wide, 2.65 m high, the opening 1.3 m wide. One sculpt: a wall box with the opening cut out by a subtracted cylinder (the round top, turned [90,0,0] to run along Z) and box (below it), and mortar joints cut 1.5 cm into both faces by thin subtracted boxes: courses repeated up the wall, staggered vertical joints mirrored on x and z, and voussoir joints in a half ring around the opening (repeat radial about z with a radius, angle 180). Keystone, cornice and plinths are added with a 1 cm smooth so they join like mortared stone. noise (1 cm bumps 12 cm across) weathers the stone, and the last child, Trim (a big box intersected, standing on y=0), trims the bumps off the base so it stands flat on y=0: intersects aren't roughened. resolution 120 keeps the joints sharp.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Arch", shape: .sculpt, color: Vec3(0.66, 0.6, 0.5), roughness: 0.95)
                .sculpting(resolution: 120, noise: MeshBuildNoise(amount: 0.01, scale: 0.12, seed: 7)),
            MeshBuildPart(name: "Wall", parent: "Arch", position: Vec3(0, 1.25, 0), size: Vec3(2.4, 2.5, 0.6), bevel: 0.03),
            MeshBuildPart(name: "Opening Top", shape: .cylinder, parent: "Arch", position: Vec3(0, 1.55, 0), rotation: Vec3(90, 0, 0),
                          size: Vec3(1.3, 1, 1.3)).sculpting(blend: .subtract, smooth: 0.02),
            MeshBuildPart(name: "Opening", parent: "Arch", position: Vec3(0, 0.75, 0), size: Vec3(1.3, 1.6, 1)).sculpting(blend: .subtract, smooth: 0.02),
            joint("Front Course", at: Vec3(0, 0.42, -0.3), size: Vec3(2.6, 0.04, 0.035), mirror: [.z],
                  repeat: MeshBuildRepeat(count: 4, offset: Vec3(0, 0.42, 0))),
            joint("Front Left Joint", at: Vec3(-1, 0.21, -0.3), size: Vec3(0.04, 0.42, 0.035), mirror: [.x, .z],
                  repeat: MeshBuildRepeat(count: 3, offset: Vec3(0, 0.84, 0))),
            joint("Front Left Joint B", at: Vec3(-0.82, 0.63, -0.3), size: Vec3(0.04, 0.42, 0.035), mirror: [.x, .z],
                  repeat: MeshBuildRepeat(count: 2, offset: Vec3(0, 0.84, 0))),
            joint("Front Voussoir", at: Vec3(0, 1.55, -0.3), size: Vec3(0.04, 0.44, 0.035), rotation: Vec3(0, 0, 90), mirror: [.z],
                  repeat: MeshBuildRepeat(count: 8, radial: MeshBuildRepeat.Radial(axis: .z, radius: 0.87, angle: 180))),
            MeshBuildPart(name: "Keystone", parent: "Arch", position: Vec3(0, 2.27, 0), size: Vec3(0.3, 0.44, 0.66), bevel: 0.02).sculpting(smooth: 0.01),
            MeshBuildPart(name: "Cornice", parent: "Arch", position: Vec3(0, 2.56, 0), size: Vec3(2.6, 0.14, 0.72), bevel: 0.025).sculpting(smooth: 0.01),
            MeshBuildPart(name: "Left Plinth", parent: "Arch", position: Vec3(-0.88, 0.14, 0), size: Vec3(0.64, 0.28, 0.7), bevel: 0.025, mirror: [.x])
                .sculpting(smooth: 0.01),
            MeshBuildPart(name: "Trim", parent: "Arch", position: Vec3(0, 1.5, 0), size: Vec3(3, 3, 1)).sculpting(blend: .intersect),
        ]))
    }
}

public enum MeshBuildExamplesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// One example by name (default: all).
        public var name: String?
        public init(name: String? = nil) { self.name = name }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var examples: [Example]
    }

    /// An example with its build as JSON keeping only the keys that differ from the defaults.
    public struct Example: Codable, Equatable, Sendable {
        public var name: String
        public var about: String
        public var build: JSONValue
    }

    /// `build` as JSON without the keys that hold their default values (names are kept).
    static func compact(_ build: MeshBuild) throws -> JSONValue {
        func json<T: Encodable>(_ value: T) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) }
        func strip(_ value: JSONValue, _ defaults: JSONValue) -> JSONValue {
            guard case .object(let fields) = value, case .object(let base) = defaults else { return value }
            return .object(fields.filter { key, value in key == "name" || key == "part" || base[key] != value })
        }
        guard case .object(var root) = try json(build) else { return try json(build) }
        let part = try json(MeshBuildPart()), animation = try json(MeshBuildAnimation()), motion = try json(MeshBuildMotion())
        let track = try json(MeshBuildTrack())
        if case .array(let parts)? = root["parts"] { root["parts"] = .array(parts.map { strip($0, part) }) }
        if case .array(let animations)? = root["animations"] {
            root["animations"] = .array(animations.map { value in
                guard case .object(var fields) = strip(value, animation) else { return value }
                if case .array(let motions)? = fields["motions"] { fields["motions"] = .array(motions.map { strip($0, motion) }) }
                if case .array(let tracks)? = fields["tracks"] { fields["tracks"] = .array(tracks.map { strip($0, track) }) }
                return .object(fields)
            })
            if animations.isEmpty { root["animations"] = nil }
        }
        return .object(root)
    }

    public static let id: CommandID = "meshBuild.examples"
    public static let title = "Mesh Build Examples"
    public static let doc = "Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation) and a turret (a group pivot swinging its children), an armchair (two sculpts: parts melted together with smooth, puffy cushions) and a stone arch (a sculpt carved with subtracts and roughened with noise). Each stands on y=0, faces -Z and gives no warnings. `name` picks one."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let matches = MeshBuildExamples.all.filter { arguments.name == nil || $0.name.caseInsensitiveCompare(arguments.name!) == .orderedSame }
        guard !matches.isEmpty else {
            throw CommandError.failed("No example named \(arguments.name ?? "") (examples: \(MeshBuildExamples.all.map(\.name).joined(separator: ", ")))")
        }
        return Result(examples: try matches.map { Example(name: $0.name, about: $0.about, build: try compact($0.build)) })
    }
}
