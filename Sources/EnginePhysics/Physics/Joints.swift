// Joints: velocity constraints between two bodies (or a body and the world), solved with
// the contacts by sequential impulses with warm starting. Drift is corrected softly (after
// Box2D v3): while iterating, each constraint is a stiff damped spring (twice the contact
// frequency, at most a quarter of the substep rate; `jointDampingRatio`) that pushes the
// anchors back together and lets go of part of its accumulated impulse; the relax pass after
// the positions are integrated solves it rigidly without the push, so the correction moves
// positions but leaves no velocity behind.
// (A rigid Baumgarte bias, which the warm start then reapplied, fed energy into the chain
// demo: an out-of-plane wobble grew until hinges and the chain flailed.)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineScene

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

/// Angle limits of a `ball` or `hinge` joint, in radians, measured from the pose the joint was
/// made in (so a joint made at rest limits motion away from rest). Every limit is optional.
///
/// - `swing` (ball): the most the connected body's copy of the joint axis may tilt away from
///   the first body's (a cone around the axis).
/// - `minAngle` / `maxAngle`: rotation about the axis (a ball's twist, a hinge's angle), right
///   hand rule, from -π to π.
///
/// Ragdolls (`Ragdoll`) use them for shoulders, hips and necks (ball with swing and twist) and
/// elbows and knees (hinges that bend one way).
public struct JointLimits: Codable, Equatable, Sendable {
    public var swing: Float?
    public var minAngle: Float?
    public var maxAngle: Float?

    public init(swing: Float? = nil, minAngle: Float? = nil, maxAngle: Float? = nil) {
        self.swing = swing
        self.minAngle = minAngle
        self.maxAngle = maxAngle
    }

    /// Limits given in degrees.
    public static func degrees(swing: Float? = nil, min: Float? = nil, max: Float? = nil) -> JointLimits {
        let r = Float.pi / 180
        return JointLimits(swing: swing.map { $0 * r }, minAngle: min.map { $0 * r }, maxAngle: max.map { $0 * r })
    }
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
    /// Angle limits (`ball` and `hinge` only; `axis` is the twist or hinge axis).
    public var limits: JointLimits?
    public var entity: Entity?

    public init(kind: JointKind, bodyA: BodyID, bodyB: BodyID? = nil, anchor: Vec3, anchorB: Vec3? = nil,
                axis: Vec3 = Vec3(0, 1, 0), collideConnected: Bool = false, limits: JointLimits? = nil, entity: Entity? = nil) {
        self.kind = kind
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.anchor = anchor
        self.anchorB = anchorB
        self.axis = axis
        self.collideConnected = collideConnected
        self.limits = limits
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
    var limits: JointLimits?
    var entity: Entity?
    /// The component it was made from (ECS joints).
    var source: Joint?

    // Solver state.
    var rA = Vec3.zero, rB = Vec3.zero
    var linearMass = Mat3.zero
    var angularMass = Mat3.zero
    /// Position errors at the start of the substep (anchor gap, angular errors, length).
    var linearError = Vec3.zero, angularError = Vec3.zero
    var perpendicular1 = Vec3.zero, perpendicular2 = Vec3.zero
    var hingeMass = Vec4.zero
    var hingeError = Vec2.zero
    var axis = Vec3.zero
    var axialMass: Float = 0
    var axialError: Float = 0
    var linearImpulse = Vec3.zero, angularImpulse = Vec3.zero
    var hingeImpulse = Vec2.zero
    var axialImpulse: Float = 0
    // Limits: the swing row (axis, error past the cone, mass, impulse) and the twist rows.
    var swingAxis = Vec3.zero
    var swingError: Float = -.infinity
    var swingMass: Float = 0
    var swingImpulse: Float = 0
    var twistAxis = Vec3.zero
    var twistAngle: Float = 0
    var twistMass: Float = 0
    var lowerImpulse: Float = 0, upperImpulse: Float = 0
}

extension SolverIsland {
    mutating func prepareJoints() {
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
                joint.linearError = pB - pA
            case .distance:
                let d = pB - pA
                let len = length(d)
                joint.axis = len > 1e-6 ? d / len : Vec3(0, 1, 0)
                let ca = cross(joint.rA, joint.axis), cb = cross(joint.rB, joint.axis)
                let k = a.invMass + b.invMass + dot(ca, iA * ca) + dot(cb, iB * cb)
                joint.axialMass = k > 0 ? 1 / k : 0
                joint.axialError = len - joint.length
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
                joint.hingeError = Vec2(dot(error, p1), dot(error, p2))
            } else if joint.kind == .fixed {
                joint.angularMass = angular.inverse
                var q = qB * (qA * joint.relativeRotation).conjugate
                if q.w < 0 { q = Quat(vector: -q.vector) }
                joint.angularError = q.imaginary * 2
            }
            if let limits = joint.limits, joint.kind == .ball || joint.kind == .hinge {
                let axisA = qA * joint.localAxisA, axisB = qB * joint.localAxisB
                if joint.kind == .ball, let swing = limits.swing {
                    let angle = acosf(min(max(dot(axisA, axisB), -1), 1))
                    let n = cross(axisA, axisB)
                    let len = length(n)
                    joint.swingAxis = len > 1e-6 ? n / len : tangentBasis(axisA).0
                    joint.swingError = angle - max(swing, 0)
                    let k = dot(joint.swingAxis, angular * joint.swingAxis)
                    joint.swingMass = k > 0 ? 1 / k : 0
                } else {
                    joint.swingError = -.infinity
                    joint.swingImpulse = 0
                }
                if limits.minAngle != nil || limits.maxAngle != nil {
                    // The rotation since the joint was made, in A's frame, and its twist about the axis.
                    var deviation = qA.conjugate * qB * joint.relativeRotation.conjugate
                    if deviation.w < 0 { deviation = Quat(vector: -deviation.vector) }
                    joint.twistAngle = 2 * atan2f(dot(deviation.imaginary, joint.localAxisA), deviation.w)
                    joint.twistAxis = axisA
                    let k = dot(axisA, angular * axisA)
                    joint.twistMass = k > 0 ? 1 / k : 0
                }
            }
            joints[j] = joint
        }
    }

    mutating func warmStartJoints() {
        for j in joints.indices where joints[j].isAlive {
            let joint = joints[j]
            guard bodies[joint.a].isSolverActive || bodies[joint.b].isSolverActive else { continue }
            var angular = joint.angularImpulse
            if joint.kind == .hinge { angular = joint.perpendicular1 * joint.hingeImpulse.x + joint.perpendicular2 * joint.hingeImpulse.y }
            if joint.limits != nil {
                angular += joint.swingAxis * joint.swingImpulse + joint.twistAxis * (joint.upperImpulse - joint.lowerImpulse)
            }
            let linear = joint.kind == .distance ? joint.axis * joint.axialImpulse : joint.linearImpulse
            applyJointImpulse(joint, linear: linear, angular: angular)
        }
    }

    /// One pass over the joints. With `useBias`, soft: the errors are pushed out by the spring
    /// of `softness`; without (the relax pass), rigid velocity constraints only.
    mutating func solveJoints(softness: Softness, useBias: Bool) {
        let biasRate = useBias ? softness.biasRate : 0
        let massScale = useBias ? softness.massScale : 1
        let impulseScale = useBias ? softness.impulseScale : 0
        for j in joints.indices where joints[j].isAlive {
            var joint = joints[j]
            let a = bodies[joint.a], b = bodies[joint.b]
            guard a.isSolverActive || b.isSolverActive else { continue }
            // Angular rows first, then the point, which matters most visually.
            if joint.kind == .hinge {
                let dw = b.angularVelocity - a.angularVelocity
                let cdot = Vec2(dot(dw, joint.perpendicular1), dot(dw, joint.perpendicular2)) + joint.hingeError * biasRate
                let m = joint.hingeMass
                let lambda = -Vec2(m.x * cdot.x + m.z * cdot.y, m.y * cdot.x + m.w * cdot.y) * massScale - joint.hingeImpulse * impulseScale
                joint.hingeImpulse += lambda
                applyJointImpulse(joint, linear: .zero, angular: joint.perpendicular1 * lambda.x + joint.perpendicular2 * lambda.y)
            } else if joint.kind == .fixed {
                let cdot = b.angularVelocity - a.angularVelocity + joint.angularError * biasRate
                let lambda = -(joint.angularMass * cdot) * massScale - joint.angularImpulse * impulseScale
                joint.angularImpulse += lambda
                applyJointImpulse(joint, linear: .zero, angular: lambda)
            }
            if let limits = joint.limits, joint.kind == .ball || joint.kind == .hinge {
                if joint.swingError > -.infinity {
                    solveLimit(&joint, axis: joint.swingAxis, error: joint.swingError, mass: joint.swingMass, impulse: \.swingImpulse,
                               softness: softness, useBias: useBias)
                }
                if let upper = limits.maxAngle {
                    solveLimit(&joint, axis: joint.twistAxis, error: joint.twistAngle - upper, mass: joint.twistMass, impulse: \.upperImpulse,
                               softness: softness, useBias: useBias)
                }
                if let lower = limits.minAngle {
                    solveLimit(&joint, axis: -joint.twistAxis, error: lower - joint.twistAngle, mass: joint.twistMass, impulse: \.lowerImpulse,
                               softness: softness, useBias: useBias)
                }
            }
            let va = bodies[joint.a], vb = bodies[joint.b]
            let dv = vb.linearVelocity + cross(vb.angularVelocity, joint.rB) - va.linearVelocity - cross(va.angularVelocity, joint.rA)
            if joint.kind == .distance {
                let lambda = -joint.axialMass * massScale * (dot(dv, joint.axis) + joint.axialError * biasRate) - joint.axialImpulse * impulseScale
                joint.axialImpulse += lambda
                applyJointImpulse(joint, linear: joint.axis * lambda, angular: .zero)
            } else {
                let lambda = -(joint.linearMass * (dv + joint.linearError * biasRate)) * massScale - joint.linearImpulse * impulseScale
                joint.linearImpulse += lambda
                applyJointImpulse(joint, linear: lambda, angular: .zero)
            }
            joints[j] = joint
        }
    }

    /// One side of an angle limit: B's rotation relative to A's along `axis` may not grow past
    /// the limit (`error` is how far past it is; negative: short of it). Short of the limit the
    /// row is speculative (it lets the bodies close the gap in this substep but no further);
    /// past it, a soft spring pushes back (rigid in the relax pass). The impulse only pushes.
    private mutating func solveLimit(_ joint: inout JointData, axis: Vec3, error: Float, mass: Float, impulse: WritableKeyPath<JointData, Float>,
                                     softness: Softness, useBias: Bool) {
        let a = bodies[joint.a], b = bodies[joint.b]
        let cdot = dot(b.angularVelocity - a.angularVelocity, axis)
        var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
        if error < 0 {
            bias = error / settings.h
        } else if useBias {
            bias = error * softness.biasRate
            massScale = softness.massScale
            impulseScale = softness.impulseScale
        }
        let old = joint[keyPath: impulse]
        let lambda = -mass * massScale * (cdot + bias) - impulseScale * old
        let total = min(old + lambda, 0)
        joint[keyPath: impulse] = total
        applyJointImpulse(joint, linear: .zero, angular: axis * (total - old))
    }

    /// Applies `linear` at the anchors (+ to B, − to A) and a pure `angular` impulse.
    private mutating func applyJointImpulse(_ joint: JointData, linear: Vec3, angular: Vec3) {
        let a = joint.a, b = joint.b
        bodies[a].linearVelocity -= linear * bodies[a].invMass
        bodies[a].angularVelocity -= bodies[a].invInertiaWorld * (cross(joint.rA, linear) + angular)
        bodies[b].linearVelocity += linear * bodies[b].invMass
        bodies[b].angularVelocity += bodies[b].invInertiaWorld * (cross(joint.rB, linear) + angular)
    }
}
