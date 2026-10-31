import Foundation
import Testing
@testable import Engine

/// The physics demo's chain: 7 box links hinged about z, the first to the world, released
/// horizontally, with a ball-jointed sphere weight at the end, and the gantry beam just above
/// the world anchor.
@MainActor private struct Chain {
    let physics = PhysicsWorld()
    var links: [BodyID] = []
    var weight = BodyID(index: 0, generation: 0)
    var joints: [JointID] = []
    let anchor = Vec3(-9, 7.5, 2)

    init(linearDamping: Float = 0.05, angularDamping: Float = 0.1) {
        let length: Float = 0.8
        physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(-9.4, 7.85, 2)), shape: .box(Vec3(repeating: 0.5)),
                                       scale: Vec3(1.2, 0.3, 3.4)))
        var previous: BodyID?
        for k in 0..<7 {
            let center = Vec3(anchor.x + length * (Float(k) + 0.5), anchor.y, anchor.z)
            let link = physics.addBody(BodyDescriptor(pose: Pose(position: center), shape: .box(Vec3(repeating: 0.5)),
                                                      scale: Vec3(length - 0.06, 0.18, 0.3), material: ColliderMaterial(density: 2000),
                                                      linearDamping: linearDamping, angularDamping: angularDamping))
            joints.append(physics.addJoint(JointDescriptor(kind: .hinge, bodyA: link, bodyB: previous, anchor: center - Vec3(length / 2, 0, 0),
                                                           axis: Vec3(0, 0, 1)))!)
            links.append(link)
            previous = link
        }
        let center = anchor + Vec3(length * 7 + 0.35, 0, 0)
        weight = physics.addBody(BodyDescriptor(pose: Pose(position: center), shape: .sphere(radius: 0.5), scale: Vec3(repeating: 0.7),
                                                material: ColliderMaterial(density: 3000),
                                                linearDamping: linearDamping, angularDamping: angularDamping))
        joints.append(physics.addJoint(JointDescriptor(kind: .ball, bodyA: weight, bodyB: previous, anchor: center - Vec3(0.35, 0, 0)))!)
    }

    var bodies: [BodyID] { links + [weight] }

    /// Kinetic + potential energy (J), relative to y = 0.
    var energy: Float {
        bodies.reduce(0) { sum, id in
            let b = physics.bodies[Int(id.index)]
            let inertia = b.invInertiaWorld.inverse
            let w = b.angularVelocity
            return sum + 0.5 * b.mass * lengthSquared(b.linearVelocity) + 0.5 * dot(w, inertia * w) - b.mass * dot(physics.gravity, b.center)
        }
    }

    /// The largest anchor separation (m) and hinge axis misalignment (radians) of any joint.
    var jointError: (position: Float, angle: Float) {
        var position: Float = 0, angle: Float = 0
        for id in joints {
            let j = physics.joints[Int(id.index)]
            let a = physics.bodies[j.a], b = physics.bodies[j.b]
            let pA = a.center + a.pose.rotation * j.localAnchorA, pB = b.center + b.pose.rotation * j.localAnchorB
            position = max(position, length(pB - pA))
            if j.kind == .hinge {
                let axisA = a.pose.rotation * j.localAxisA, axisB = b.pose.rotation * j.localAxisB
                angle = max(angle, asin(min(length(cross(axisA, axisB)), 1)))
            }
        }
        return (position, angle)
    }

    /// The energy hanging straight down at rest.
    var restingEnergy: Float {
        bodies.enumerated().reduce(0) { sum, item in
            let below: Float = item.offset < 7 ? 0.8 * (Float(item.offset) + 0.5) : 0.8 * 7 + 0.35
            return sum + physics.bodies[Int(item.element.index)].mass * -physics.gravity.y * (anchor.y - below)
        }
    }
}

/// Released horizontally (with the engine's default damping), the chain must swing without
/// gaining energy and with its joints together. Before the joints were soft with a relax pass,
/// a rigid Baumgarte bias that the warm start reapplied made an out-of-plane wobble grow from
/// step ~360: energy rose by 1.07 MJ (13x the start), hinge axes tilted by 1.56 rad, anchors
/// parted by 0.36 m, and the chain flailed up around the gantry.
@MainActor @Test func hingeChainSwingsWithoutGainingEnergy() {
    let chain = Chain()
    let e0 = chain.energy
    var lowest = e0, rise: Float = 0, gap: Float = 0, tilt: Float = 0
    for _ in 0..<1200 {
        chain.physics.step(1.0 / 60)
        let e = chain.energy, error = chain.jointError
        lowest = min(lowest, e)
        rise = max(rise, e - lowest)
        gap = max(gap, error.position)
        tilt = max(tilt, error.angle)
    }
    // A little comes back when the soft joints, stretched by a centimeter or so under the
    // whip's tension, spring back (about 1.9 kJ); never more.
    #expect(rise < 0.03 * e0, "energy rose by \(rise) J above its lowest (start \(e0) J)")
    #expect(chain.energy - chain.restingEnergy < 0.5 * (e0 - chain.restingEnergy), "the swing should die down")
    #expect(gap < 0.03, "joint anchors parted by \(gap) m")
    #expect(tilt < 0.01, "hinge axes tilted by \(tilt) rad")
    for id in chain.links { #expect(abs(chain.physics.pose(of: id)!.position.z - 2) < 0.01) }  // stays in its plane
}

/// With the demo's damping, the chain comes to rest hanging straight down and falls asleep.
@MainActor @Test func dampedHingeChainSettlesHanging() {
    let chain = Chain(linearDamping: 0.4, angularDamping: 0.5)
    let e0 = chain.energy
    var previous = e0, rise: Float = 0
    for _ in 0..<600 {
        chain.physics.step(1.0 / 60)
        rise = max(rise, chain.energy - previous)
        previous = chain.energy
    }
    #expect(rise < 0.001 * e0, "energy rose by \(rise) J in a step")
    // After 10 s it only sways a little; by 30 s it is asleep, hanging below the anchor.
    #expect(abs(chain.physics.pose(of: chain.weight)!.position.x - chain.anchor.x) < 1.5)
    for _ in 0..<1200 { chain.physics.step(1.0 / 60) }
    #expect(chain.physics.awakeBodyCount == 0)
    for (k, id) in chain.bodies.enumerated() {
        let p = chain.physics.pose(of: id)!.position
        let below = k < 7 ? 0.8 * (Float(k) + 0.5) : 0.8 * 7 + 0.35
        #expect(length(p - (chain.anchor - Vec3(0, below, 0))) < 0.15, "body \(k) at \(p)")
    }
    let error = chain.jointError
    #expect(error.position < 0.01 && error.angle < 0.001)
}
