// ECS components for physics. An entity with a `Collider` gets a body: static without a
// `RigidBody`, else as the `RigidBody` says. A `Joint` connects the entity's body to another
// entity's body (or to the world). All three serialize with scenes.

/// Makes an entity's collider move: dynamic (simulated) or kinematic (moved by its
/// `Transform`). Without one, a `Collider` is static.
public struct RigidBody: Component, Codable, Equatable, Sendable {
    public static let componentName = "RigidBody"
    public static var fieldHints: [String: FieldHints] {
        ["linearVelocity": FieldHints(tooltip: "m/s, world space; written back by the simulation"),
         "angularVelocity": FieldHints(tooltip: "rad/s, world space; written back by the simulation"),
         "linearDamping": FieldHints(range: 0...100, step: 0.01), "angularDamping": FieldHints(range: 0...100, step: 0.01),
         "gravityScale": FieldHints(range: -10...10, step: 0.1),
         "startsAsleep": FieldHints(tooltip: "Created asleep (a stack built at rest) until something touches it")]
    }

    public var motion: MotionType
    public var linearVelocity: Vec3
    public var angularVelocity: Vec3
    public var linearDamping: Float
    public var angularDamping: Float
    public var gravityScale: Float
    public var allowSleep: Bool
    public var startsAsleep: Bool

    public init(_ motion: MotionType = .dynamic, linearVelocity: Vec3 = .zero, angularVelocity: Vec3 = .zero,
                linearDamping: Float = 0.05, angularDamping: Float = 0.1, gravityScale: Float = 1, allowSleep: Bool = true,
                startsAsleep: Bool = false) {
        self.motion = motion
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
        self.linearDamping = linearDamping
        self.angularDamping = angularDamping
        self.gravityScale = gravityScale
        self.allowSleep = allowSleep
        self.startsAsleep = startsAsleep
    }
}

/// An entity's collision shape (scaled by the entity's world scale) and surface.
public struct Collider: Component, Codable, Equatable, Sendable {
    public static let componentName = "Collider"
    public static var fieldHints: [String: FieldHints] {
        ["friction": FieldHints(range: 0...2, step: 0.01), "restitution": FieldHints(range: 0...1, step: 0.01),
         "density": FieldHints(range: 0.001...100_000, step: 10, tooltip: "kg/m³ (water: 1000)"),
         "isTrigger": FieldHints(tooltip: "Reports overlaps instead of colliding"),
         "layer": FieldHints(tooltip: "Layer bits this collider is on"),
         "mask": FieldHints(tooltip: "Layer bits it collides with")]
    }

    public var shape: ColliderShape
    /// The shape's position and rotation in the entity's frame (unscaled).
    public var offset: Vec3
    public var rotation: Quat
    public var friction: Float
    public var restitution: Float
    public var density: Float
    public var isTrigger: Bool
    public var layer: UInt32
    public var mask: UInt32

    public init(_ shape: ColliderShape, offset: Vec3 = .zero, rotation: Quat = .identity, friction: Float = 0.5,
                restitution: Float = 0, density: Float = 1000, isTrigger: Bool = false, layer: UInt32 = 1,
                mask: UInt32 = .max) {
        self.shape = shape
        self.offset = offset
        self.rotation = rotation
        self.friction = friction
        self.restitution = restitution
        self.density = density
        self.isTrigger = isTrigger
        self.layer = layer
        self.mask = mask
    }

    var material: ColliderMaterial { ColliderMaterial(friction: friction, restitution: restitution, density: density) }
}

/// Connects this entity's body to `connectedBody`'s (or to the world when nil). The joint is
/// made when both bodies exist, in the pose they have then; `anchor` and `axis` are in this
/// entity's frame (position and rotation, not scale).
public struct Joint: Component, Codable, Equatable, Sendable {
    public static let componentName = "Joint"

    public var kind: JointKind
    public var connectedBody: Entity?
    public var anchor: Vec3
    /// The hinge axis.
    public var axis: Vec3
    /// For `.distance`: the anchor on the connected body, in its frame (the world when there
    /// is none). Nil uses the point that coincides with `anchor`.
    public var connectedAnchor: Vec3?
    public var collideConnected: Bool

    public init(_ kind: JointKind, connectedTo connectedBody: Entity? = nil, anchor: Vec3 = .zero, axis: Vec3 = Vec3(0, 1, 0),
                connectedAnchor: Vec3? = nil, collideConnected: Bool = false) {
        self.kind = kind
        self.connectedBody = connectedBody
        self.anchor = anchor
        self.axis = axis
        self.connectedAnchor = connectedAnchor
        self.collideConnected = collideConnected
    }
}

/// What a body was made from and last wrote back, so the sync can tell the game's edits
/// from its own.
struct BodySync {
    var transform: Transform?
    var rigidBody: RigidBody?
    var collider: Collider?
    var scale = Vec3.one
}

extension PhysicsWorld {
    /// Registers the physics components with `ComponentRegistry` (done by `addPhysics`, and
    /// needed before loading scene files that use them into a world that hasn't seen them).
    public static func registerComponents() {
        ComponentRegistry.register(RigidBody.self, Collider.self, Joint.self)
    }
}
