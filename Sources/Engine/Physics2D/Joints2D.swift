import Foundation

// 2D joints: velocity constraints between two bodies (or a body and the world), solved with
// the contacts by sequential impulses with warm starting. Like Box2D v3 they are soft
// constraints (a stiff spring) while pushing positions back, and rigid in the relax pass.
// Revolute (pin with optional limits and motor), distance (rod or spring with length limits),
// weld (no relative motion) and the mouse joint (drags a body toward a point).

/// What a joint holds together.
public enum Joint2DKind: String, Codable, Sendable, CaseIterable {
    /// A shared point; rotation about it is free, or limited and motorized.
    case revolute
    /// Two anchors at a distance: a rigid rod, or a spring (`hertz` > 0).
    case distance
    /// No relative motion at all (glue).
    case weld
}

/// A handle to a joint in a `PhysicsWorld2D`.
public struct Joint2DID: Hashable, Sendable {
    public let index: UInt32
    public let generation: UInt32
}

/// Everything needed to create a joint. Anchors are given in world space at the bodies'
/// current poses; the joint then keeps that configuration (for `.revolute`, relative angles
/// are measured from the angle the bodies have now).
public struct Joint2DDescriptor: Sendable {
    public var kind: Joint2DKind
    public var bodyA: Body2DID
    /// Nil joins `bodyA` to the world.
    public var bodyB: Body2DID?
    /// The shared point (world space), on A.
    public var anchor: Vec2
    /// For `.distance`: the anchor on B (world space); defaults to `anchor`.
    public var anchorB: Vec2?
    /// Whether the two bodies still collide with each other.
    public var collideConnected: Bool
    public var entity: Entity?

    // Revolute: limits are the angle of B relative to A, in radians (0 where the joint was made).
    public var enableLimit: Bool
    public var lowerAngle: Float
    public var upperAngle: Float
    public var enableMotor: Bool
    /// rad/s of B relative to A.
    public var motorSpeed: Float
    public var maxMotorTorque: Float

    // Distance: `hertz` 0 is a rigid rod, more a spring of that frequency; `length` defaults to
    // the distance of the anchors. A spring stays within `minLength...maxLength`.
    public var length: Float?
    public var hertz: Float
    public var dampingRatio: Float
    public var minLength: Float
    public var maxLength: Float

    public init(kind: Joint2DKind, bodyA: Body2DID, bodyB: Body2DID? = nil, anchor: Vec2, anchorB: Vec2? = nil,
                collideConnected: Bool = false, entity: Entity? = nil, enableLimit: Bool = false, lowerAngle: Float = 0,
                upperAngle: Float = 0, enableMotor: Bool = false, motorSpeed: Float = 0, maxMotorTorque: Float = 0,
                length: Float? = nil, hertz: Float = 0, dampingRatio: Float = 0.5, minLength: Float = 0,
                maxLength: Float = .infinity) {
        self.kind = kind
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.anchor = anchor
        self.anchorB = anchorB
        self.collideConnected = collideConnected
        self.entity = entity
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

struct JointData2D {
    var generation: UInt32 = 0
    var isAlive = false
    var kind = Joint2DKind.revolute
    var isMouse = false
    var a = 0, b = 0
    /// Anchors relative to each body's center of mass, in the body's frame.
    var localAnchorA = Vec2.zero, localAnchorB = Vec2.zero
    var collideConnected = false
    var entity: Entity?
    /// The component it was made from (ECS joints).
    var source: Joint2D?

    var enableLimit = false
    var lowerAngle: Float = 0, upperAngle: Float = 0
    var enableMotor = false
    var motorSpeed: Float = 0, maxMotorTorque: Float = 0
    var restLength: Float = 0
    var hertz: Float = 0, dampingRatio: Float = 0
    var minLength: Float = 0, maxLength = Float.infinity
    /// Mouse joint: the target (world), the strength and the spring.
    var target = Vec2.zero
    var maxForce: Float = 0

    // Solver state.
    var rA = Vec2.zero, rB = Vec2.zero
    /// The inverse of the point constraint's 2x2 mass matrix (m11, m12, m22).
    var pointMass = Vec3.zero
    var pointError = Vec2.zero
    var axialMass: Float = 0
    var axis = Vec2(0, 1)
    var length: Float = 0
    /// The angle of B relative to A, unwrapped (it keeps counting past a half turn).
    var jointAngle: Float = 0
    var lastRawAngle: Float = 0
    var linearImpulse = Vec2.zero
    var angularImpulse: Float = 0
    var motorImpulse: Float = 0
    var lowerImpulse: Float = 0, upperImpulse: Float = 0
    var axialImpulse: Float = 0
}

private func wrapAngle(_ a: Float) -> Float {
    var a = a
    while a > .pi { a -= 2 * .pi }
    while a < -.pi { a += 2 * .pi }
    return a
}

extension PhysicsWorld2D {
    /// How quickly a held body's spin is damped, per second.
    static let mouseAngularDamping: Float = 4

    @discardableResult
    public func addJoint(_ d: Joint2DDescriptor) -> Joint2DID? {
        guard let a = index(of: d.bodyA) else { return nil }
        let b = d.bodyB.flatMap(index(of:)) ?? 0
        if d.bodyB != nil && b == 0 { return nil }
        var joint = JointData2D()
        joint.kind = d.kind
        joint.a = a
        joint.b = b
        joint.entity = d.entity
        joint.collideConnected = d.collideConnected
        let bodyA = bodies[a], bodyB = bodies[b]
        let anchorB = d.kind == .distance ? (d.anchorB ?? d.anchor) : d.anchor
        joint.localAnchorA = bodyA.pose.rotation.inverseRotate(d.anchor - bodyA.center)
        joint.localAnchorB = bodyB.pose.rotation.inverseRotate(anchorB - bodyB.center)
        joint.enableLimit = d.enableLimit
        joint.lowerAngle = min(d.lowerAngle, d.upperAngle)
        joint.upperAngle = max(d.lowerAngle, d.upperAngle)
        joint.enableMotor = d.enableMotor
        joint.motorSpeed = d.motorSpeed
        joint.maxMotorTorque = d.maxMotorTorque
        joint.restLength = d.length ?? length2(anchorB - d.anchor)
        joint.hertz = d.hertz
        joint.dampingRatio = d.dampingRatio
        joint.minLength = d.minLength
        joint.maxLength = d.maxLength
        joint.lastRawAngle = (bodyB.pose.rotation * bodyA.pose.rotation.inverse).angle
        return insert(joint)
    }

    /// Drags the body toward a point with a spring (`hertz`, `dampingRatio`), pulling with at
    /// most `maxForce` newtons: the way to grab things with the mouse. `target` is where the
    /// body is held now (world space); move it with `setMouseTarget`.
    @discardableResult
    public func addMouseJoint(body: Body2DID, target: Vec2, maxForce: Float, hertz: Float = 5, dampingRatio: Float = 0.7) -> Joint2DID? {
        guard let b = index(of: body), bodies[b].motion == .dynamic else { return nil }
        var joint = JointData2D()
        joint.isMouse = true
        joint.a = 0
        joint.b = b
        joint.collideConnected = true
        joint.localAnchorB = bodies[b].pose.rotation.inverseRotate(target - bodies[b].center)
        joint.target = target
        joint.maxForce = maxForce
        joint.hertz = hertz
        joint.dampingRatio = dampingRatio
        return insert(joint)
    }

    /// Moves a mouse joint's target (and wakes the body).
    public func setMouseTarget(_ id: Joint2DID, _ target: Vec2) {
        guard let j = jointIndex(id), joints[j].isMouse else { return }
        joints[j].target = target
        wake(joints[j].b)
    }

    private func insert(_ data: JointData2D) -> Joint2DID {
        var joint = data
        let index = freeJoints.popLast() ?? {
            joints.append(JointData2D())
            return joints.count - 1
        }()
        joint.generation = joints[index].generation &+ 1
        joint.isAlive = true
        joints[index] = joint
        if !joint.collideConnected {
            let key = pairKey(joint.a, joint.b)
            jointPairs[key, default: 0] += 1
            contacts.removeAll { c in
                guard pairKey(c.a, c.b) == key else { return false }
                contactKeys.remove(c.key)
                return true
            }
        }
        wake(joint.a)
        wake(joint.b)
        return Joint2DID(index: UInt32(index), generation: joint.generation)
    }

    public func removeJoint(_ id: Joint2DID) {
        guard let i = jointIndex(id) else { return }
        removeJoint(at: i)
    }

    func removeJoint(at i: Int) {
        let joint = joints[i]
        if !joint.collideConnected {
            let key = pairKey(joint.a, joint.b)
            if let n = jointPairs[key], n > 1 { jointPairs[key] = n - 1 } else { jointPairs[key] = nil }
            // Let the pair be found again.
            for k in [joint.a, joint.b] where k != 0 && bodies[k].isAlive {
                for f in bodies[k].fixtures where !movedProxies.contains(f) { movedProxies.append(f) }
            }
        }
        wake(joint.a)
        wake(joint.b)
        if let entity = joint.entity, jointForEntity[entity] == i { jointForEntity[entity] = nil }
        let generation = joint.generation
        joints[i] = JointData2D()
        joints[i].generation = generation
        freeJoints.append(i)
    }

    func jointIndex(_ id: Joint2DID) -> Int? {
        let i = Int(id.index)
        return i < joints.count && joints[i].isAlive && joints[i].generation == id.generation ? i : nil
    }

    public func contains(_ id: Joint2DID) -> Bool { jointIndex(id) != nil }
    public var jointCount: Int { joints.filter(\.isAlive).count }

    /// The angle of B relative to A (revolute and weld joints), radians, 0 where the joint was made.
    public func jointAngle(_ id: Joint2DID) -> Float? { jointIndex(id).map { joints[$0].jointAngle } }

    /// Sets a revolute joint's motor (`nil` speed turns it off).
    public func setMotor(_ id: Joint2DID, speed: Float?, maxTorque: Float? = nil) {
        guard let j = jointIndex(id) else { return }
        joints[j].enableMotor = speed != nil
        if speed == nil { joints[j].motorImpulse = 0 }
        if let speed { joints[j].motorSpeed = speed }
        if let maxTorque { joints[j].maxMotorTorque = maxTorque }
        wake(joints[j].a)
        wake(joints[j].b)
    }

    /// Sets (or with `nil`, removes) a revolute joint's angle limits.
    public func setLimits(_ id: Joint2DID, lower: Float?, upper: Float?) {
        guard let j = jointIndex(id) else { return }
        joints[j].enableLimit = lower != nil && upper != nil
        if !joints[j].enableLimit {
            joints[j].lowerImpulse = 0
            joints[j].upperImpulse = 0
        }
        if let lower, let upper {
            joints[j].lowerAngle = min(lower, upper)
            joints[j].upperAngle = max(lower, upper)
        }
        wake(joints[j].a)
        wake(joints[j].b)
    }

    // MARK: - Solver

    func prepareJoints(h: Float) {
        for j in joints.indices where joints[j].isAlive {
            let a = bodies[joints[j].a], b = bodies[joints[j].b]
            guard a.isSolverActive || b.isSolverActive else { continue }
            var joint = joints[j]
            joint.rA = a.pose.rotation.rotate(joint.localAnchorA)
            joint.rB = b.pose.rotation.rotate(joint.localAnchorB)
            let mA = a.invMass, mB = b.invMass, iA = a.invInertia, iB = b.invInertia
            let k11 = mA + mB + iA * joint.rA.y * joint.rA.y + iB * joint.rB.y * joint.rB.y
            let k12 = -iA * joint.rA.x * joint.rA.y - iB * joint.rB.x * joint.rB.y
            let k22 = mA + mB + iA * joint.rA.x * joint.rA.x + iB * joint.rB.x * joint.rB.x
            let det = k11 * k22 - k12 * k12
            let inv = abs(det) > 1e-12 ? 1 / det : 0
            joint.pointMass = Vec3(inv * k22, -inv * k12, inv * k11)
            let d = (b.center + joint.rB) - (a.center + joint.rA)
            joint.pointError = joint.isMouse ? b.center + joint.rB - joint.target : d
            let k = iA + iB
            joint.axialMass = k > 0 ? 1 / k : 0
            if joint.kind != .distance || joint.isMouse {
                let raw = (b.pose.rotation * a.pose.rotation.inverse).angle
                joint.jointAngle += wrapAngle(raw - joint.lastRawAngle)
                joint.lastRawAngle = raw
            }
            if joint.kind == .distance && !joint.isMouse {
                joint.length = length2(d)
                joint.axis = joint.length > 1e-6 ? d / joint.length : Vec2(0, 1)
                let crA = cross2(joint.rA, joint.axis), crB = cross2(joint.rB, joint.axis)
                let kd = mA + mB + iA * crA * crA + iB * crB * crB
                joint.axialMass = kd > 0 ? 1 / kd : 0
            }
            if joint.isMouse { bodies[joint.b].angularVelocity *= 1 / (1 + h * Self.mouseAngularDamping) }
            joints[j] = joint
        }
    }

    func warmStartJoints() {
        for j in joints.indices where joints[j].isAlive {
            let joint = joints[j]
            guard bodies[joint.a].isSolverActive || bodies[joint.b].isSolverActive else { continue }
            if joint.isMouse {
                apply(joint.linearImpulse, joint.a, joint.rA, joint.b, joint.rB)
            } else if joint.kind == .distance {
                apply(joint.axis * (joint.axialImpulse + joint.lowerImpulse - joint.upperImpulse), joint.a, joint.rA, joint.b, joint.rB)
            } else {
                var angular = joint.angularImpulse
                if joint.kind == .revolute {
                    angular = (joint.enableMotor ? joint.motorImpulse : 0)
                        + (joint.enableLimit ? joint.lowerImpulse - joint.upperImpulse : 0)
                }
                apply(joint.linearImpulse, joint.a, joint.rA, joint.b, joint.rB)
                applyAngular(angular, joint.a, joint.b)
            }
        }
    }

    func solveJoints(h: Float, softness: Softness2D, useBias: Bool) {
        for j in joints.indices where joints[j].isAlive {
            var joint = joints[j]
            guard bodies[joint.a].isSolverActive || bodies[joint.b].isSolverActive else { continue }
            if joint.isMouse {
                solveMouse(&joint, h: h)
            } else {
                switch joint.kind {
                case .revolute: solveRevolute(&joint, h: h, softness: softness, useBias: useBias)
                case .weld: solveWeld(&joint, softness: softness, useBias: useBias)
                case .distance: solveDistance(&joint, h: h, softness: softness, useBias: useBias)
                }
            }
            joints[j] = joint
        }
    }

    /// A pure angular impulse (+ on B, - on A).
    private func applyAngular(_ impulse: Float, _ a: Int, _ b: Int) {
        bodies[a].angularVelocity -= bodies[a].invInertia * impulse
        bodies[b].angularVelocity += bodies[b].invInertia * impulse
    }

    /// The two rows that keep the anchors together.
    private func solvePoint(_ joint: inout JointData2D, softness: Softness2D, useBias: Bool) {
        let dv = relativeVelocity(joint.a, joint.rA, joint.b, joint.rB)
        var bias = Vec2.zero, massScale: Float = 1, impulseScale: Float = 0
        if useBias {
            bias = joint.pointError * softness.biasRate
            massScale = softness.massScale
            impulseScale = softness.impulseScale
        }
        let c = dv + bias, m = joint.pointMass
        let b = Vec2(m.x * c.x + m.y * c.y, m.y * c.x + m.z * c.y)
        let impulse = Vec2(-massScale * b.x - impulseScale * joint.linearImpulse.x,
                           -massScale * b.y - impulseScale * joint.linearImpulse.y)
        joint.linearImpulse += impulse
        apply(impulse, joint.a, joint.rA, joint.b, joint.rB)
    }

    private func solveRevolute(_ joint: inout JointData2D, h: Float, softness: Softness2D, useBias: Bool) {
        let a = joint.a, b = joint.b
        if joint.enableMotor {
            let cdot = bodies[b].angularVelocity - bodies[a].angularVelocity - joint.motorSpeed
            let maxImpulse = h * joint.maxMotorTorque
            let total = min(max(joint.motorImpulse - joint.axialMass * cdot, -maxImpulse), maxImpulse)
            applyAngular(total - joint.motorImpulse, a, b)
            joint.motorImpulse = total
        }
        if joint.enableLimit {
            // Speculative like contacts: approaching a limit is allowed up to it.
            let lowerC = joint.jointAngle - joint.lowerAngle
            var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
            if lowerC > 0 {
                bias = lowerC / h
            } else if useBias {
                bias = softness.biasRate * lowerC
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            var cdot = bodies[b].angularVelocity - bodies[a].angularVelocity
            var total = max(joint.lowerImpulse - joint.axialMass * massScale * (cdot + bias) - impulseScale * joint.lowerImpulse, 0)
            applyAngular(total - joint.lowerImpulse, a, b)
            joint.lowerImpulse = total

            let upperC = joint.upperAngle - joint.jointAngle
            bias = 0
            massScale = 1
            impulseScale = 0
            if upperC > 0 {
                bias = upperC / h
            } else if useBias {
                bias = softness.biasRate * upperC
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            cdot = bodies[a].angularVelocity - bodies[b].angularVelocity
            total = max(joint.upperImpulse - joint.axialMass * massScale * (cdot + bias) - impulseScale * joint.upperImpulse, 0)
            applyAngular(-(total - joint.upperImpulse), a, b)
            joint.upperImpulse = total
        }
        solvePoint(&joint, softness: softness, useBias: useBias)
    }

    private func solveWeld(_ joint: inout JointData2D, softness: Softness2D, useBias: Bool) {
        var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
        if useBias {
            bias = softness.biasRate * joint.jointAngle
            massScale = softness.massScale
            impulseScale = softness.impulseScale
        }
        let cdot = bodies[joint.b].angularVelocity - bodies[joint.a].angularVelocity
        let impulse = -joint.axialMass * massScale * (cdot + bias) - impulseScale * joint.angularImpulse
        joint.angularImpulse += impulse
        applyAngular(impulse, joint.a, joint.b)
        solvePoint(&joint, softness: softness, useBias: useBias)
    }

    private func solveDistance(_ joint: inout JointData2D, h: Float, softness: Softness2D, useBias: Bool) {
        let a = joint.a, b = joint.b
        let isSpring = joint.hertz > 0
        // The rod, or the spring along the axis.
        var dv = relativeVelocity(a, joint.rA, b, joint.rB)
        let c = joint.length - joint.restLength
        var s = softness, bias: Float = 0
        if isSpring {
            s = Softness2D(hertz: joint.hertz, dampingRatio: joint.dampingRatio, h: h)
            bias = s.biasRate * c
        } else if useBias {
            bias = s.biasRate * c
        } else {
            s = .rigid
        }
        var impulse = -s.massScale * joint.axialMass * (dot2(joint.axis, dv) + bias) - s.impulseScale * joint.axialImpulse
        joint.axialImpulse += impulse
        apply(joint.axis * impulse, a, joint.rA, b, joint.rB)
        guard isSpring else { return }
        if joint.minLength > 0 {
            dv = relativeVelocity(a, joint.rA, b, joint.rB)
            let lowerC = joint.length - joint.minLength
            var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
            if lowerC > 0 {
                bias = lowerC / h
            } else if useBias {
                bias = softness.biasRate * lowerC
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            impulse = -massScale * joint.axialMass * (dot2(joint.axis, dv) + bias) - impulseScale * joint.lowerImpulse
            let total = max(joint.lowerImpulse + impulse, 0)
            impulse = total - joint.lowerImpulse
            joint.lowerImpulse = total
            apply(joint.axis * impulse, a, joint.rA, b, joint.rB)
        }
        if joint.maxLength.isFinite {
            dv = relativeVelocity(a, joint.rA, b, joint.rB)
            let upperC = joint.maxLength - joint.length
            var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
            if upperC > 0 {
                bias = upperC / h
            } else if useBias {
                bias = softness.biasRate * upperC
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            impulse = -massScale * joint.axialMass * (-dot2(joint.axis, dv) + bias) - impulseScale * joint.upperImpulse
            let total = max(joint.upperImpulse + impulse, 0)
            impulse = total - joint.upperImpulse
            joint.upperImpulse = total
            apply(-joint.axis * impulse, a, joint.rA, b, joint.rB)
        }
    }

    private func solveMouse(_ joint: inout JointData2D, h: Float) {
        let soft = Softness2D(hertz: joint.hertz, dampingRatio: joint.dampingRatio, h: h)
        let b = joint.b
        let dv = bodies[b].linearVelocity + cross2(bodies[b].angularVelocity, joint.rB)
        let c = dv + joint.pointError * soft.biasRate, m = joint.pointMass
        let solved = Vec2(m.x * c.x + m.y * c.y, m.y * c.x + m.z * c.y)
        var impulse = Vec2(-soft.massScale * solved.x - soft.impulseScale * joint.linearImpulse.x,
                           -soft.massScale * solved.y - soft.impulseScale * joint.linearImpulse.y)
        let old = joint.linearImpulse
        var total = old + impulse
        let limit = joint.maxForce * h
        let l = length2(total)
        if l > limit { total *= limit / l }
        impulse = total - old
        joint.linearImpulse = total
        apply(impulse, joint.a, joint.rA, joint.b, joint.rB)
    }
}
