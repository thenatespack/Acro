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
    public static var all: [MeshBuildExample] { [streetLamp, cart, turret] }

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
    public static let doc = "Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation) and a turret (a group pivot swinging its children). Each stands on y=0, faces -Z and gives no warnings. `name` picks one."
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
