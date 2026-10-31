// ECS components for 2D physics. An entity with a `Collider2D` gets a body: static without a
// `RigidBody2D`, else as the `RigidBody2D` says. A `Joint2D` connects the entity's body to
// another entity's body (or to the world). The entity's `Transform` is the body's pose: x / y
// position and the rotation about z (parents, z and scale are ignored; collider sizes are in
// meters). All of them serialize with scenes.

/// Makes an entity's collider move: dynamic (simulated) or kinematic (moved by its
/// `Transform`). Without one, a `Collider2D` is static.
public struct RigidBody2D: Component, Codable, Equatable, Sendable {
    public static let componentName = "RigidBody2D"
    public static var fieldHints: [String: FieldHints] {
        ["linearVelocity": FieldHints(tooltip: "m/s; written back by the simulation"),
         "angularVelocity": FieldHints(tooltip: "rad/s; written back by the simulation"),
         "linearDamping": FieldHints(range: 0...100, step: 0.01), "angularDamping": FieldHints(range: 0...100, step: 0.01),
         "gravityScale": FieldHints(range: -10...10, step: 0.1),
         "startsAsleep": FieldHints(tooltip: "Created asleep (a stack built at rest) until something touches it"),
         "fixedRotation": FieldHints(tooltip: "Never rotates (a platformer character)"),
         "interpolation": FieldHints(tooltip: "Smooth the displayed Transform between fixed steps (the simulation stays exact)")]
    }

    public var motion: MotionType
    public var linearVelocity: Vec2
    public var angularVelocity: Float
    public var linearDamping: Float
    public var angularDamping: Float
    public var gravityScale: Float
    public var allowSleep: Bool
    public var startsAsleep: Bool
    public var fixedRotation: Bool
    public var interpolation: PoseInterpolation

    public init(_ motion: MotionType = .dynamic, linearVelocity: Vec2 = .zero, angularVelocity: Float = 0,
                linearDamping: Float = 0, angularDamping: Float = 0.05, gravityScale: Float = 1, allowSleep: Bool = true,
                startsAsleep: Bool = false, fixedRotation: Bool = false, interpolation: PoseInterpolation = .inherit) {
        self.motion = motion
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
        self.linearDamping = linearDamping
        self.angularDamping = angularDamping
        self.gravityScale = gravityScale
        self.allowSleep = allowSleep
        self.startsAsleep = startsAsleep
        self.fixedRotation = fixedRotation
        self.interpolation = interpolation
    }
}

/// An entity's 2D collision shape and surface.
public struct Collider2D: Component, Codable, Equatable, Sendable {
    public static let componentName = "Collider2D"
    public static var fieldHints: [String: FieldHints] {
        ["friction": FieldHints(range: 0...2, step: 0.01), "restitution": FieldHints(range: 0...1, step: 0.01),
         "density": FieldHints(range: 0.001...100_000, step: 0.1, tooltip: "kg/m² (the mass of a body is its area times this)"),
         "rotation": FieldHints(tooltip: "radians"),
         "isTrigger": FieldHints(tooltip: "Reports overlaps instead of colliding"),
         "isOneWay": FieldHints(tooltip: "A platform bodies pass through from below and land on top of (its local +y)"),
         "layer": FieldHints(tooltip: "Layer bits this collider is on"),
         "mask": FieldHints(tooltip: "Layer bits it collides with")]
    }

    public var shape: ColliderShape2D
    /// The shape's position and rotation (radians) in the entity's frame.
    public var offset: Vec2
    public var rotation: Float
    public var friction: Float
    public var restitution: Float
    public var density: Float
    public var isTrigger: Bool
    public var isOneWay: Bool
    public var layer: UInt32
    public var mask: UInt32

    public init(_ shape: ColliderShape2D, offset: Vec2 = .zero, rotation: Float = 0, friction: Float = 0.5,
                restitution: Float = 0, density: Float = 1, isTrigger: Bool = false, isOneWay: Bool = false,
                layer: UInt32 = 1, mask: UInt32 = .max) {
        self.shape = shape
        self.offset = offset
        self.rotation = rotation
        self.friction = friction
        self.restitution = restitution
        self.density = density
        self.isTrigger = isTrigger
        self.isOneWay = isOneWay
        self.layer = layer
        self.mask = mask
    }

    var material: ColliderMaterial { ColliderMaterial(friction: friction, restitution: restitution, density: density) }
}

/// Connects this entity's body to `connectedBody`'s (or to the world when nil). The joint is
/// made when both bodies exist, in the pose they have then; `anchor` is in this entity's
/// frame (position and rotation).
public struct Joint2D: Component, Codable, Equatable, Sendable {
    public static let componentName = "Joint2D"
    public static var fieldHints: [String: FieldHints] {
        ["lowerAngle": FieldHints(tooltip: "radians, of the connected body relative to this one"),
         "upperAngle": FieldHints(tooltip: "radians"),
         "motorSpeed": FieldHints(tooltip: "rad/s"), "maxMotorTorque": FieldHints(tooltip: "N m"),
         "connectedAnchor": FieldHints(tooltip: "Distance: the anchor on the connected body, in its frame (the world when there is none). Empty: where the anchor is"),
         "length": FieldHints(tooltip: "Distance: rest length; empty uses the distance of the anchors"),
         "hertz": FieldHints(range: 0...100, step: 0.1, tooltip: "Distance: 0 is a rigid rod, more a spring of this frequency"),
         "dampingRatio": FieldHints(range: 0...10, step: 0.05),
         "maxLength": FieldHints(tooltip: "Spring: longest length; empty is unlimited")]
    }

    public var kind: Joint2DKind
    public var connectedBody: Entity?
    public var anchor: Vec2
    public var connectedAnchor: Vec2?
    public var collideConnected: Bool
    // Revolute.
    public var enableLimit: Bool
    public var lowerAngle: Float
    public var upperAngle: Float
    public var enableMotor: Bool
    public var motorSpeed: Float
    public var maxMotorTorque: Float
    // Distance.
    public var length: Float?
    public var hertz: Float
    public var dampingRatio: Float
    public var minLength: Float
    public var maxLength: Float?

    public init(_ kind: Joint2DKind, connectedTo connectedBody: Entity? = nil, anchor: Vec2 = .zero, connectedAnchor: Vec2? = nil,
                collideConnected: Bool = false, enableLimit: Bool = false, lowerAngle: Float = 0, upperAngle: Float = 0,
                enableMotor: Bool = false, motorSpeed: Float = 0, maxMotorTorque: Float = 0, length: Float? = nil,
                hertz: Float = 0, dampingRatio: Float = 0.5, minLength: Float = 0, maxLength: Float? = nil) {
        self.kind = kind
        self.connectedBody = connectedBody
        self.anchor = anchor
        self.connectedAnchor = connectedAnchor
        self.collideConnected = collideConnected
        self.enableLimit = enableLimit
        self.lowerAngle = lowerAngle
        self.upperAngle = upperAngle
        self.enableMotor = enableMotor
        self.motorSpeed = motorSpeed
        self.maxMotorTorque = maxMotorTorque
        self.length = length
        self.hertz = hertz
        self.dampingRatio = dampingRatio
        self.minLength = minLength
        self.maxLength = maxLength
    }
}

/// What a body was made from and last wrote back, so the sync can tell the game's edits
/// from its own.
struct BodySync2D {
    var transform: Transform?
    var rigidBody: RigidBody2D?
    var collider: Collider2D?
}

extension PhysicsWorld2D {
    /// Registers the 2D physics components with `ComponentRegistry` (done by `addPhysics2D`, and
    /// needed before loading scene files that use them into a world that hasn't seen them).
    public static func registerComponents() {
        ComponentRegistry.register(RigidBody2D.self, Collider2D.self, Joint2D.self)
    }
}
