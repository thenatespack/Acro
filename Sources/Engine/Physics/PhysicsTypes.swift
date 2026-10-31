// Public value types of the physics API: body handles and descriptions, events, query
// filters and results.

/// A handle to a body in a `PhysicsWorld` (slot index + generation, like `Entity`).
public struct BodyID: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let index: UInt32
    public let generation: UInt32

    init(index: Int, generation: UInt32) {
        self.index = UInt32(index)
        self.generation = generation
    }

    public static func < (a: BodyID, b: BodyID) -> Bool { (a.index, a.generation) < (b.index, b.generation) }
    public var description: String { "Body(\(index)v\(generation))" }
}

/// How a body moves.
public enum MotionType: String, Codable, Sendable, CaseIterable {
    /// Never moves (floors, walls). Infinite mass.
    case `static`
    /// Moved by game code (its transform or `moveKinematic`); pushes dynamic bodies but
    /// isn't pushed back. Infinite mass.
    case kinematic
    /// Moved by the simulation: gravity, contacts, joints, forces.
    case dynamic
}

/// Surface and filtering properties of a body's collider.
public struct ColliderMaterial: Equatable, Sendable {
    /// Coulomb friction; a pair uses the geometric mean of both.
    public var friction: Float
    /// Bounciness in [0, 1]; a pair uses the larger of both.
    public var restitution: Float
    /// kg/m³ (1000 is water), for the mass and inertia of dynamic bodies.
    public var density: Float

    public init(friction: Float = 0.5, restitution: Float = 0, density: Float = 1000) {
        self.friction = friction
        self.restitution = restitution
        self.density = density
    }
}

/// Everything needed to create a body.
public struct BodyDescriptor: Sendable {
    public var motion: MotionType
    /// The body's frame (for ECS bodies, the entity's world position and rotation).
    public var pose: Pose
    public var shape: ColliderShape?
    /// The collider's pose in the body's frame.
    public var shapeOffset: Pose
    /// Applied to the shape (the entity's scale for ECS bodies).
    public var scale: Vec3
    public var material: ColliderMaterial
    /// Triggers report overlaps (`PhysicsEvent.triggerEntered` ...) and never push anything.
    public var isTrigger: Bool
    /// The layer bits this body is on, and the layers it collides with. Two bodies collide
    /// when each one's `mask` has a bit of the other's `layer`.
    public var layer: UInt32
    public var mask: UInt32
    public var linearVelocity: Vec3
    public var angularVelocity: Vec3
    /// Velocity lost per second, as a fraction (`v *= 1 / (1 + dt * damping)`).
    public var linearDamping: Float
    public var angularDamping: Float
    public var gravityScale: Float
    /// Whether the body may fall asleep when it (and everything touching it) comes to rest.
    public var allowSleep: Bool
    /// Starts asleep (e.g. a stack built at rest); woken by contact with a moving body.
    public var startsAsleep: Bool
    /// The entity the body belongs to (set by the ECS integration; reported in hits and events).
    public var entity: Entity?

    public init(motion: MotionType = .dynamic, pose: Pose = .identity, shape: ColliderShape? = nil,
                shapeOffset: Pose = .identity, scale: Vec3 = .one, material: ColliderMaterial = ColliderMaterial(),
                isTrigger: Bool = false, layer: UInt32 = 1, mask: UInt32 = .max, linearVelocity: Vec3 = .zero,
                angularVelocity: Vec3 = .zero, linearDamping: Float = 0.05, angularDamping: Float = 0.1,
                gravityScale: Float = 1, allowSleep: Bool = true, startsAsleep: Bool = false, entity: Entity? = nil) {
        self.motion = motion
        self.pose = pose
        self.shape = shape
        self.shapeOffset = shapeOffset
        self.scale = scale
        self.material = material
        self.isTrigger = isTrigger
        self.layer = layer
        self.mask = mask
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
        self.linearDamping = linearDamping
        self.angularDamping = angularDamping
        self.gravityScale = gravityScale
        self.allowSleep = allowSleep
        self.startsAsleep = startsAsleep
        self.entity = entity
    }
}

/// Something that happened during a step. Events are listed in a deterministic order.
public struct PhysicsEvent: Equatable, Sendable {
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
    public var bodyA: BodyID
    public var bodyB: BodyID
    public var entityA: Entity?
    public var entityB: Entity?
    /// World contact point and normal (from A to B), for `collisionBegan`; zero otherwise.
    public var point: Vec3
    public var normal: Vec3

    /// The other party of an event involving `entity`, if it is one of the two.
    public func other(than entity: Entity) -> Entity? {
        entityA == entity ? entityB : (entityB == entity ? entityA : nil)
    }
}

/// Which bodies a query sees.
public struct QueryFilter: Sendable {
    /// Bodies whose `layer` shares a bit with this.
    public var mask: UInt32
    public var includeTriggers: Bool
    /// Bodies to skip (e.g. the caster itself).
    public var excluding: [BodyID]

    public init(mask: UInt32 = .max, includeTriggers: Bool = false, excluding: [BodyID] = []) {
        self.mask = mask
        self.includeTriggers = includeTriggers
        self.excluding = excluding
    }

    public static let `default` = QueryFilter()
}

/// A ray or shape cast hit.
public struct RaycastHit: Equatable, Sendable {
    public var body: BodyID
    public var entity: Entity?
    /// World-space hit point (for shape casts, the touching point).
    public var point: Vec3
    /// The surface normal of the hit body there.
    public var normal: Vec3
    /// Distance along the ray / cast direction.
    public var distance: Float
    /// The mesh triangle hit, for triangle-mesh colliders.
    public var triangle: Int?
}

/// What `PhysicsWorld.drawDebug` draws.
public struct PhysicsDebugOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let colliders = PhysicsDebugOptions(rawValue: 1)
    public static let contacts = PhysicsDebugOptions(rawValue: 2)
    public static let bounds = PhysicsDebugOptions(rawValue: 4)
    public static let joints = PhysicsDebugOptions(rawValue: 8)
    public static let centersOfMass = PhysicsDebugOptions(rawValue: 16)
    public static let all: PhysicsDebugOptions = [.colliders, .contacts, .bounds, .joints, .centersOfMass]
}
