import Engine
import Foundation

// Aiming without quaternions: `transform.lookAt`, and degrees for rotation values
// (`{"eulerDegrees": [x, y, z]}` wherever a quaternion field is set, see `FieldValue(json:)`).

/// What `transform.lookAt` aims at: another entity (its world position) or a world point.
public enum LookTarget: Codable, Equatable, Sendable {
    case entity(EntityID)
    case point(Vec3)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            guard let id = EntityID(text) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad entity id '\(text)'"))
            }
            self = .entity(id)
        } else {
            self = .point(try container.decode(Vec3.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .entity(let id): try container.encode(id)
        case .point(let point): try container.encode(point)
        }
    }
}

public enum TransformLookAtCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The entity to turn: a camera, a light, anything.
        public var entity: EntityID
        /// An entity id (aims at its world position) or a world point [x, y, z].
        public var target: LookTarget
        /// The direction that should end up above the entity (default [0, 1, 0]).
        public var up: Vec3?
        public init(entity: EntityID, target: LookTarget, up: Vec3? = nil) {
            self.entity = entity
            self.target = target
            self.up = up
        }
    }

    public static let id: CommandID = "transform.lookAt"
    public static let title = "Look At"
    public static let doc = "Turns the entity so its local -Z (a camera's or light's forward) points at `target` (another entity or a world point [x, y, z]), keeping +Y toward `up` (default [0, 1, 0]). Only the rotation changes. Aiming straight along `up` picks another up vector."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let world = session.world
        let entity = try world.require(arguments.entity)
        world.propagateTransforms()  // earlier edits of this call's batch, and of the parents
        let local = world.get(Transform.self, for: entity) ?? Transform()
        let parentMatrix = world.parent(of: entity).map { world.worldMatrix(of: $0) } ?? .identity
        let position = Transform(matrix: parentMatrix * local.matrix).position
        let target: Vec3
        switch arguments.target {
        case .point(let point): target = point
        case .entity(let id):
            target = Transform(matrix: world.worldMatrix(of: try world.require(id))).position
        }
        let forward = target - position
        guard length(forward) > 1e-6 else { throw CommandError.failed("The target is at the entity's position: nothing to look at") }
        var up = arguments.up ?? Vec3(0, 1, 0)
        guard length(up) > 1e-6 else { throw CommandError.failed("`up` can't be zero") }
        up = normalize(up)
        if length(cross(normalize(forward), up)) < 1e-4 { up = abs(up.z) < 0.9 ? Vec3(0, 0, 1) : Vec3(1, 0, 0) }
        let rotation = Quat.lookRotation(forward: forward, up: up)
        let parent = Transform(matrix: parentMatrix)
        var updated = local
        updated.rotation = (parent.rotation.inverse * rotation).normalized
        guard let id = world.id(of: entity) else { throw CommandError.failed("The entity has no id") }
        try session.commands.check(session.perform(SetComponentCommand(id: id, old: local, new: updated, label: "Look At")), title)
        return NoResult()
    }
}

extension Quat {
    /// A rotation from Euler angles in degrees: Z (roll), then X (pitch), then Y (yaw) about the
    /// fixed axes (the camera convention: yaw turns the view left/right, pitch tilts it).
    static func euler(degrees: Vec3) -> Quat {
        let r = Float.pi / 180
        let yaw = Quat(angle: degrees.y * r, axis: Vec3(0, 1, 0))
        let pitch = Quat(angle: degrees.x * r, axis: Vec3(1, 0, 0))
        let roll = Quat(angle: degrees.z * r, axis: Vec3(0, 0, 1))
        return (yaw * pitch * roll).normalized
    }
}
