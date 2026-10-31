// Public value types of the 2D physics API: body handles and descriptions, events, query
// filters and results. `MotionType` and `ColliderMaterial` are the 3D physics' (density is
// kg/m² here).

/// A handle to a body in a `PhysicsWorld2D` (slot index + generation).
public struct Body2DID: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let index: UInt32
    public let generation: UInt32

    init(index: Int, generation: UInt32) {
        self.index = UInt32(index)
        self.generation = generation
    }

    public static func < (a: Body2DID, b: Body2DID) -> Bool { (a.index, a.generation) < (b.index, b.generation) }
    public var description: String { "Body2D(\(index)v\(generation))" }
}

/// Everything needed to create a 2D body.
public struct BodyDescriptor2D: Sendable {
    public var motion: MotionType
    public var pose: Pose2D
    public var shape: ColliderShape2D?
    /// The collider's pose in the body's frame.
    public var shapeOffset: Pose2D
    public var material: ColliderMaterial
    /// Triggers report overlaps (`PhysicsEvent2D.Kind.triggerEntered` ...) and never push anything.
    public var isTrigger: Bool
    /// A one-way platform: bodies pass through it from below (or the sides) and land on its
    /// top, the side the body's local +y points to. Decided when the pair first touches.
    public var isOneWay: Bool
    /// The layer bits this body is on, and the layers it collides with. Two bodies collide
    /// when each one's `mask` has a bit of the other's `layer`.
    public var layer: UInt32
    public var mask: UInt32
    public var linearVelocity: Vec2
    public var angularVelocity: Float
    /// Velocity lost per second, as a fraction (`v *= 1 / (1 + dt * damping)`).
    public var linearDamping: Float
    public var angularDamping: Float
    public var gravityScale: Float
    public var allowSleep: Bool
    /// Starts asleep (e.g. a stack built at rest); woken by contact with a moving body.
    public var startsAsleep: Bool
    /// The body never rotates (a platformer character).
    public var fixedRotation: Bool
    /// The entity the body belongs to (set by the ECS integration; reported in hits and events).
    public var entity: Entity?

    public init(motion: MotionType = .dynamic, pose: Pose2D = .identity, shape: ColliderShape2D? = nil,
                shapeOffset: Pose2D = .identity, material: ColliderMaterial = ColliderMaterial(density: 1),
                isTrigger: Bool = false, isOneWay: Bool = false, layer: UInt32 = 1, mask: UInt32 = .max,
                linearVelocity: Vec2 = .zero, angularVelocity: Float = 0, linearDamping: Float = 0,
                angularDamping: Float = 0.05, gravityScale: Float = 1, allowSleep: Bool = true, startsAsleep: Bool = false,
                fixedRotation: Bool = false, entity: Entity? = nil) {
        self.motion = motion
        self.pose = pose
        self.shape = shape
        self.shapeOffset = shapeOffset
        self.material = material
        self.isTrigger = isTrigger
        self.isOneWay = isOneWay
        self.layer = layer
        self.mask = mask
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
        self.linearDamping = linearDamping
        self.angularDamping = angularDamping
        self.gravityScale = gravityScale
        self.allowSleep = allowSleep
        self.startsAsleep = startsAsleep
        self.fixedRotation = fixedRotation
        self.entity = entity
    }
}

/// Something that happened during a step. Events are listed in a deterministic order. A body
/// with several colliders (a chain makes one per segment) reports each touching pair.
public struct PhysicsEvent2D: Equatable, Sendable {
    public enum Kind: String, Sendable {
        /// Two solid colliders started touching (`point` / `normal` describe the deepest point).
        case collisionBegan
        /// They stopped touching (or one was removed).
        case collisionEnded
        /// A collider started overlapping a trigger; `bodyA` is the trigger.
        case triggerEntered
        /// Still overlapping, reported every step.
        case triggerStayed
        /// No longer overlapping (or one was removed).
        case triggerExited
    }

    public var kind: Kind
    public var bodyA: Body2DID
    public var bodyB: Body2DID
    public var entityA: Entity?
    public var entityB: Entity?
    /// World contact point and normal (from A to B), for `collisionBegan`; zero otherwise.
    public var point: Vec2
    public var normal: Vec2

    /// The other party of an event involving `entity`, if it is one of the two.
    public func other(than entity: Entity) -> Entity? {
        entityA == entity ? entityB : (entityB == entity ? entityA : nil)
    }
}

/// Which bodies a 2D query sees.
public struct QueryFilter2D: Sendable {
    /// Bodies whose `layer` shares a bit with this.
    public var mask: UInt32
    public var includeTriggers: Bool
    /// Bodies to skip (e.g. the caster itself).
    public var excluding: [Body2DID]

    public init(mask: UInt32 = .max, includeTriggers: Bool = false, excluding: [Body2DID] = []) {
        self.mask = mask
        self.includeTriggers = includeTriggers
        self.excluding = excluding
    }

    public static let `default` = QueryFilter2D()
}

/// A ray or shape cast hit.
public struct RaycastHit2D: Equatable, Sendable {
    public var body: Body2DID
    public var entity: Entity?
    /// World-space hit point (for shape casts, the touching point).
    public var point: Vec2
    /// The surface normal of the hit body there.
    public var normal: Vec2
    /// Distance along the ray / cast direction.
    public var distance: Float
}
