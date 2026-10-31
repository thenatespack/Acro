// Joints: velocity constraints between two bodies (or a body and the world), solved with
// the contacts by sequential impulses with warm starting. Position drift is corrected with
// a Baumgarte bias.

/// What a joint holds together.
public enum JointKind: String, Codable, Sendable, CaseIterable {
    /// No relative motion at all (glue).
    case fixed
    /// A shared point; free rotation (ball and socket).
    case ball
    /// A shared point and a shared axis; rotation about the axis only (doors, wheels, chains).
    case hinge
    /// A rigid rod between two anchors; free rotation at both ends.
    case distance
}

/// A handle to a joint in a `PhysicsWorld`.
public struct JointID: Hashable, Sendable {
    public let index: UInt32
    public let generation: UInt32
}

/// Everything needed to create a joint. Anchors and the axis are given in world space at the
/// bodies' current poses; the joint then keeps that configuration.
public struct JointDescriptor: Sendable {
    public var kind: JointKind
    public var bodyA: BodyID
    /// Nil joins `bodyA` to the world.
    public var bodyB: BodyID?
    /// The shared point (world space), on A.
    public var anchor: Vec3
    /// For `.distance`: the anchor on B (world space); defaults to `anchor`.
    public var anchorB: Vec3?
    /// For `.hinge`: the rotation axis (world space).
    public var axis: Vec3
    /// Whether the two bodies still collide with each other.
    public var collideConnected: Bool
    public var entity: Entity?

    public init(kind: JointKind, bodyA: BodyID, bodyB: BodyID? = nil, anchor: Vec3, anchorB: Vec3? = nil,
                axis: Vec3 = Vec3(0, 1, 0), collideConnected: Bool = false, entity: Entity? = nil) {
        self.kind = kind
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.anchor = anchor
        self.anchorB = anchorB
        self.axis = axis
        self.collideConnected = collideConnected
        self.entity = entity
    }
}

struct JointData {
    var generation: UInt32 = 0
    var isAlive = false
    var kind: JointKind = .ball
    var a = 0, b = 0
    /// Anchors relative to each body's center of mass, in the body's frame.
    var localAnchorA = Vec3.zero, localAnchorB = Vec3.zero
    var localAxisA = Vec3(0, 1, 0), localAxisB = Vec3(0, 1, 0)
    /// B's rotation relative to A's when the joint was made (`fixed`).
    var relativeRotation = Quat.identity
    var length: Float = 0
    var collideConnected = false
    var entity: Entity?
    /// The component it was made from (ECS joints).
    var source: Joint?

    // Solver state.
    var rA = Vec3.zero, rB = Vec3.zero
    var linearMass = Mat3.zero
    var angularMass = Mat3.zero
    var linearBias = Vec3.zero, angularBias = Vec3.zero
    var perpendicular1 = Vec3.zero, perpendicular2 = Vec3.zero
    var hingeMass = Vec4.zero
    var hingeBias = Vec2.zero
    var axis = Vec3.zero
    var axialMass: Float = 0
    var axialBias: Float = 0
    var linearImpulse = Vec3.zero, angularImpulse = Vec3.zero
    var hingeImpulse = Vec2.zero
    var axialImpulse: Float = 0
}

extension PhysicsWorld {
    static let jointBaumgarte: Float = 0.2

    func prepareJoints(dt: Float) {
        let beta = Self.jointBaumgarte / dt
        for j in joints.indices where joints[j].isAlive {
            let a = bodies[joints[j].a], b = bodies[joints[j].b]
            guard a.isSolverActive || b.isSolverActive else { continue }
            var joint = joints[j]
            let qA = a.pose.rotation, qB = b.pose.rotation
            let iA = a.invInertiaWorld, iB = b.invInertiaWorld
            joint.rA = qA * joint.localAnchorA
            joint.rB = qB * joint.localAnchorB
            let pA = a.center + joint.rA, pB = b.center + joint.rB
            switch joint.kind {
            case .ball, .hinge, .fixed:
                let skewA = Mat3.skew(joint.rA), skewB = Mat3.skew(joint.rB)
                let k = Mat3.identity * (a.invMass + b.invMass) - skewA * iA * skewA - skewB * iB * skewB
                joint.linearMass = k.inverse
                joint.linearBias = (pB - pA) * beta
            case .distance:
                let d = pB - pA
                let len = length(d)
                joint.axis = len > 1e-6 ? d / len : Vec3(0, 1, 0)
                let ca = cross(joint.rA, joint.axis), cb = cross(joint.rB, joint.axis)
                let k = a.invMass + b.invMass + dot(ca, iA * ca) + dot(cb, iB * cb)
                joint.axialMass = k > 0 ? 1 / k : 0
                joint.axialBias = (len - joint.length) * beta
            }
            let angular = iA + iB
            if joint.kind == .hinge {
                let axisA = qA * joint.localAxisA, axisB = qB * joint.localAxisB
                let (p1, p2) = tangentBasis(axisA)
                joint.perpendicular1 = p1
                joint.perpendicular2 = p2
                let k11 = dot(p1, angular * p1), k12 = dot(p1, angular * p2), k22 = dot(p2, angular * p2)
                let det = k11 * k22 - k12 * k12
                joint.hingeMass = abs(det) > 1e-12 ? Vec4(k22, -k12, -k12, k11) / det : .zero
                let error = cross(axisA, axisB)
                joint.hingeBias = Vec2(dot(error, p1), dot(error, p2)) * beta
            } else if joint.kind == .fixed {
                joint.angularMass = angular.inverse
                var q = qB * (qA * joint.relativeRotation).conjugate
                if q.w < 0 { q = Quat(vector: -q.vector) }
                joint.angularBias = q.imaginary * (2 * beta)
            }
            joints[j] = joint
        }
    }

    func warmStartJoints() {
        for j in joints.indices where joints[j].isAlive {
            let joint = joints[j]
            guard bodies[joint.a].isSolverActive || bodies[joint.b].isSolverActive else { continue }
            var angular = joint.angularImpulse
            if joint.kind == .hinge { angular = joint.perpendicular1 * joint.hingeImpulse.x + joint.perpendicular2 * joint.hingeImpulse.y }
            let linear = joint.kind == .distance ? joint.axis * joint.axialImpulse : joint.linearImpulse
            applyJointImpulse(joint, linear: linear, angular: angular)
        }
    }

    func solveJoints() {
        for j in joints.indices where joints[j].isAlive {
            var joint = joints[j]
            let a = bodies[joint.a], b = bodies[joint.b]
            guard a.isSolverActive || b.isSolverActive else { continue }
            // Angular rows first, then the point, which matters most visually.
            if joint.kind == .hinge {
                let dw = b.angularVelocity - a.angularVelocity
                let cdot = Vec2(dot(dw, joint.perpendicular1), dot(dw, joint.perpendicular2)) + joint.hingeBias
                let m = joint.hingeMass
                let lambda = -Vec2(m.x * cdot.x + m.z * cdot.y, m.y * cdot.x + m.w * cdot.y)
                joint.hingeImpulse += lambda
                applyJointImpulse(joint, linear: .zero, angular: joint.perpendicular1 * lambda.x + joint.perpendicular2 * lambda.y)
            } else if joint.kind == .fixed {
                let cdot = b.angularVelocity - a.angularVelocity + joint.angularBias
                let lambda = -(joint.angularMass * cdot)
                joint.angularImpulse += lambda
                applyJointImpulse(joint, linear: .zero, angular: lambda)
            }
            let va = bodies[joint.a], vb = bodies[joint.b]
            let dv = vb.linearVelocity + cross(vb.angularVelocity, joint.rB) - va.linearVelocity - cross(va.angularVelocity, joint.rA)
            if joint.kind == .distance {
                let lambda = -joint.axialMass * (dot(dv, joint.axis) + joint.axialBias)
                joint.axialImpulse += lambda
                applyJointImpulse(joint, linear: joint.axis * lambda, angular: .zero)
            } else {
                let lambda = -(joint.linearMass * (dv + joint.linearBias))
                joint.linearImpulse += lambda
                applyJointImpulse(joint, linear: lambda, angular: .zero)
            }
            joints[j] = joint
        }
    }

    /// Applies `linear` at the anchors (+ to B, − to A) and a pure `angular` impulse.
    private func applyJointImpulse(_ joint: JointData, linear: Vec3, angular: Vec3) {
        let a = joint.a, b = joint.b
        bodies[a].linearVelocity -= linear * bodies[a].invMass
        bodies[a].angularVelocity -= bodies[a].invInertiaWorld * (cross(joint.rA, linear) + angular)
        bodies[b].linearVelocity += linear * bodies[b].invMass
        bodies[b].angularVelocity += bodies[b].invInertiaWorld * (cross(joint.rB, linear) + angular)
    }
}
