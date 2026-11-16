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
    public static var all: [MeshBuildExample] { [streetLamp, cart, turret, crate, bench] }

    /// Dark green-black paint for street furniture.
    static let lampPaint = Vec3(0.09, 0.13, 0.11)
    static let iron = Vec3(0.18, 0.19, 0.2)

    /// A pole on a foot with an arm reaching forward, a shade and a glowing bulb: a parent chain
    /// where each position is in the parent's space.
    public static var streetLamp: MeshBuildExample {
        MeshBuildExample(name: "Street Lamp", about: "3.8 m tall. A parent chain (Base > Pole > Arm > Shade > Bulb): each position is the part's center in its parent's space, so the pole's 1.9 is half its 3.6 m height above the foot's center. The arm reaches forward (-Z). Painted metal looks with wear (scuffed paint, grime) tinted dark green; the bulb glows.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.1, 0), size: Vec3(0.4, 0.2, 0.4), color: lampPaint,
                          bevel: 0.03, look: "paintedMetal", wear: 0.6),
            MeshBuildPart(name: "Pole", shape: .cylinder, parent: "Base", position: Vec3(0, 1.9, 0), size: Vec3(0.12, 3.6, 0.12),
                          color: lampPaint, look: "paintedMetal", wear: 0.4),
            MeshBuildPart(name: "Arm", shape: .box, parent: "Pole", position: Vec3(0, 1.7, -0.3), size: Vec3(0.08, 0.08, 0.7),
                          color: lampPaint, look: "paintedMetal", wear: 0.4),
            MeshBuildPart(name: "Shade", shape: .cone, parent: "Arm", position: Vec3(0, -0.1, -0.3), size: Vec3(0.45, 0.3, 0.45),
                          color: Vec3(0.12, 0.3, 0.2), look: "paintedMetal", wear: 0.3),
            MeshBuildPart(name: "Bulb", shape: .sphere, parent: "Shade", position: Vec3(0, -0.15, 0), size: Vec3(0.18, 0.18, 0.18),
                          color: Vec3(1, 0.95, 0.8), glow: Vec3(1, 0.85, 0.55), glowStrength: 4),
        ]))
    }

    /// A wooden cart, 2 m long, front at -Z: wheels turned onto the X axle with rotation [0,0,90].
    public static var cart: MeshBuildExample {
        func wheel(_ name: String, _ x: Float, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(x, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.8, 0.1, 0.8), color: Vec3(0.45, 0.33, 0.22), look: "wood", wear: 0.7)
        }
        func axle(_ name: String, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(0, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.06, 1.3, 0.06), look: "rustyMetal")
        }
        return MeshBuildExample(name: "Wooden Cart", about: "2 m long, front (the shaft) at -Z. Cylinders run along Y, so wheels and axles on an axle along X use rotation [0,0,90]. The wheels' 0.8 m diameter puts their centers 0.4 m up and their bottoms on y=0; they touch the bed's sides. Planks and wood looks with wear, rusty axles. The Roll animation (autoplay off) spins the wheels about their own axis (motion axis y).", build: MeshBuild(parts: [
            MeshBuildPart(name: "Bed", shape: .box, position: Vec3(0, 0.6, 0), size: Vec3(1.2, 0.15, 2), look: "planks", wear: 0.5,
                          grain: .z),
            MeshBuildPart(name: "Side L", shape: .box, parent: "Bed", position: Vec3(-0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Side R", shape: .box, parent: "Bed", position: Vec3(0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Front", shape: .box, parent: "Bed", position: Vec3(0, 0.25, -0.96), size: Vec3(1.04, 0.35, 0.08),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Shaft", shape: .box, parent: "Bed", position: Vec3(0, -0.05, -1.45), size: Vec3(0.08, 0.08, 1),
                          look: "wood", wear: 0.5),
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
        let olive = Vec3(0.32, 0.36, 0.24), gunmetal = Vec3(0.25, 0.26, 0.28)
        return MeshBuildExample(name: "Turret", about: "1.2 m wide. A group part (Pivot) is a hinge with no mesh: the head hangs from it and the Scan animation swings the pivot 40 degrees each way about Y, so everything on it turns together. The barrel is a cylinder turned with rotation [90,0,0] to point forward (-Z); the muzzle is its child, so it inherits that rotation and sits at the barrel's local y=-0.5 end. Painted metal tinted olive with wear, a brushed steel barrel.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.15, 0), size: Vec3(1.2, 0.3, 1.2), color: Vec3(0.3, 0.31, 0.32),
                          bevel: 0.03, look: "paintedMetal", wear: 0.7),
            MeshBuildPart(name: "Pivot", shape: .group, parent: "Base", position: Vec3(0, 0.15, 0)),
            MeshBuildPart(name: "Head", shape: .box, parent: "Pivot", position: Vec3(0, 0.25, 0), size: Vec3(0.8, 0.5, 0.9),
                          color: olive, bevel: 0.04, look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Barrel", shape: .cylinder, parent: "Head", position: Vec3(0, 0.05, -0.85), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.12, 1, 0.12), color: gunmetal, look: "brushedMetal", wear: 0.3),
            MeshBuildPart(name: "Muzzle", shape: .cylinder, parent: "Barrel", position: Vec3(0, -0.5, 0), size: Vec3(0.18, 0.15, 0.18),
                          color: gunmetal, look: "brushedMetal", wear: 0.6),
            MeshBuildPart(name: "Sensor", shape: .sphere, parent: "Head", position: Vec3(0.25, 0.3, 0.1), size: Vec3(0.2, 0.2, 0.2),
                          color: Vec3(0.9, 0.1, 0.05), glow: Vec3(1, 0.1, 0.05), glowStrength: 3),
        ], animations: [
            MeshBuildAnimation(name: "Scan", motions: [MeshBuildMotion(part: "Pivot", kind: .swing, axis: .y, amount: 40, period: 4)]),
        ]))
    }

    /// A weathered wooden crate with rusty metal corner caps and bolts: looks, wear and mirror.
    public static var crate: MeshBuildExample {
        MeshBuildExample(name: "Weathered Crate", about: "0.8 m cube of worn planks with a batten across each side, rusty corner caps and bolts. One corner cap (with its two bolts as children) mirrored across x, y and z makes all eight; one batten mirrored across z covers the back. Looks: planks (grain along X), wood, rustyMetal; wear adds grime and darker creases, and the baked ambient occlusion darkens where parts meet.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Crate", shape: .box, position: Vec3(0, 0.41, 0), size: Vec3(0.8, 0.8, 0.8), look: "planks",
                          lookScale: 0.9, wear: 0.7, grain: .x),
            MeshBuildPart(name: "Batten Front", shape: .box, parent: "Crate", position: Vec3(0, 0, -0.415), size: Vec3(0.66, 0.1, 0.03),
                          color: Vec3(0.42, 0.3, 0.2), mirror: [.z], look: "wood", wear: 0.8),
            MeshBuildPart(name: "Batten Left", shape: .box, parent: "Crate", position: Vec3(-0.415, 0, 0), size: Vec3(0.03, 0.1, 0.66),
                          color: Vec3(0.42, 0.3, 0.2), mirror: [.x], look: "wood", wear: 0.8),
            MeshBuildPart(name: "Corner", shape: .box, parent: "Crate", position: Vec3(0.34, 0.34, -0.34), size: Vec3(0.14, 0.14, 0.14),
                          bevel: 0.006, mirror: [.x, .y, .z], look: "rustyMetal", wear: 0.5),
            MeshBuildPart(name: "Bolt Front", shape: .cylinder, parent: "Corner", position: Vec3(-0.02, -0.02, -0.0775),
                          rotation: Vec3(90, 0, 0), size: Vec3(0.03, 0.015, 0.03), segments: 12, look: "rustyMetal", wear: 0.8),
            MeshBuildPart(name: "Bolt Side", shape: .cylinder, parent: "Corner", position: Vec3(0.0775, -0.02, 0.02),
                          rotation: Vec3(0, 0, 90), size: Vec3(0.03, 0.015, 0.03), segments: 12, look: "rustyMetal", wear: 0.8),
        ]))
    }

    /// A park bench: wooden slats on painted iron ends, made with mirror and repeat.
    public static var bench: MeshBuildExample {
        let iron = Vec3(0.06, 0.07, 0.065)
        return MeshBuildExample(name: "Park Bench", about: "1.6 m wide, seat 0.47 m high, facing -Z. One iron end (front leg, back leg, seat rail, armrest) mirrored across x makes both; one seat slat repeated 4 times along z and one back slat 3 times up y. Looks: wood slats (grain along X by default: their longest side) with wear, paintedMetal tinted near-black for the iron, so scuffs and grime show.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Front Leg L", shape: .box, position: Vec3(-0.75, 0.34, -0.2), size: Vec3(0.06, 0.68, 0.06), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Back Leg L", shape: .box, position: Vec3(-0.75, 0.425, 0.2), size: Vec3(0.06, 0.85, 0.06), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Seat Rail L", shape: .box, position: Vec3(-0.75, 0.42, 0), size: Vec3(0.06, 0.06, 0.34), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Arm L", shape: .box, position: Vec3(-0.75, 0.7, -0.05), size: Vec3(0.07, 0.04, 0.36), color: iron,
                          bevel: 0.01, mirror: [.x], look: "paintedMetal", wear: 0.6),
            MeshBuildPart(name: "Seat Slat", shape: .box, position: Vec3(0, 0.4675, -0.18), size: Vec3(1.56, 0.035, 0.09),
                          bevel: 0.006, repetition: MeshBuildRepeat(count: 4, offset: Vec3(0, 0, 0.12)), look: "wood", wear: 0.5),
            MeshBuildPart(name: "Back Slat", shape: .box, position: Vec3(0, 0.58, 0.155), size: Vec3(1.56, 0.09, 0.03),
                          bevel: 0.006, repetition: MeshBuildRepeat(count: 3, offset: Vec3(0, 0.11, 0)), look: "wood", wear: 0.5),
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
    public static let doc = "Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation), a turret (a group pivot swinging its children), a weathered crate (looks, wear, mirrored corner caps) and a park bench (mirror and repeat, wood and painted iron). All use looks. Each stands on y=0, faces -Z and gives no warnings. `name` picks one."
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
