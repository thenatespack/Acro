// Ragdolls: capsule bodies and limited joints built from a skeleton's bones, which the
// animation drives (kinematic hit boxes), physics pushes around while the animation pulls the
// bodies back (hit reactions), or physics takes over (death). Returning to the animation blends
// from the last physics pose (get-up).
//
// The `Ragdoll` component sits on a character's root and names bones (entities with a `Name`
// in its subtree). `world.addPhysics` runs it:
// - "ragdoll" (`.fixedUpdate`, before "physics"): makes the bodies and joints (again after
//   the bone list changes), moves kinematic bodies to the animated pose, switches bodies to
//   dynamic for `partial` / `full`, pulls partial bodies toward the animation, applies queued
//   impulses and counts down hit reactions.
// - "ragdoll.pose" (`.lateUpdate`, after the animation and IK of `.update`, before transform
//   propagation): records the animated pose, then writes the bones' `Transform`s blended
//   toward the bodies' (or the frozen pose while getting up) by `Ragdoll.blend`. The root
//   bone takes the body's position and rotation; the others only rotation, so bone lengths stay.
//
// The bodies are the physics world's own (not ECS colliders): `PhysicsWorld.ragdollBody(of:bone:)`
// finds them; ray casts report the bone entity they belong to. Bodies of one ragdoll never
// collide with each other, and a `CharacterController` on the same entity ignores them.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineScene

/// How a `Ragdoll` moves.
public enum RagdollMode: String, Codable, Sendable, CaseIterable {
    /// The animation drives the bones; the bodies follow it as kinematic hit boxes.
    case animated
    /// Dynamic bodies that the animation pulls back (`Ragdoll.strength`); `Ragdoll.weight` of
    /// their pose shows. Hit reactions (`Ragdoll.hit`).
    case partial
    /// Physics alone: the character goes limp.
    case full
}

/// One body of a `Ragdoll`: a capsule from a bone to `end` (or `length` along the bone's +Y),
/// jointed to its parent body.
public struct RagdollBone: Codable, Equatable, Sendable {
    /// The bone entity's `Name`.
    public var bone: String
    /// The bone where the capsule ends (a child bone); nil uses `length` along the bone's +Y.
    public var end: String?
    /// Capsule length when there is no `end`, meters (0: a sphere).
    public var length: Float
    public var radius: Float
    /// The ragdoll bone it hangs from; nil: the nearest ragdoll bone above it (none: the root body).
    public var parent: String?
    /// `ball` (shoulders, hips, spine, neck) or `hinge` (elbows, knees); `fixed` glues it.
    public var joint: JointKind
    /// The twist (ball) or hinge axis in the bone's frame; nil: toward `end` for a ball, +X for a hinge.
    public var axis: Vec3?
    /// Ball: how far the bone may tilt from its rest direction, degrees.
    public var swing: Float
    /// Twist (ball) or bend (hinge) range about `axis`, degrees.
    public var minAngle: Float
    public var maxAngle: Float
    /// Mass, kg; nil: a share of `Ragdoll.mass` by volume.
    public var mass: Float?

    public init(bone: String, end: String? = nil, length: Float = 0, radius: Float = 0.08, parent: String? = nil, joint: JointKind = .ball,
                axis: Vec3? = nil, swing: Float = 40, minAngle: Float = -30, maxAngle: Float = 30, mass: Float? = nil) {
        self.bone = bone
        self.end = end
        self.length = length
        self.radius = radius
        self.parent = parent
        self.joint = joint
        self.axis = axis
        self.swing = swing
        self.minAngle = minAngle
        self.maxAngle = maxAngle
        self.mass = mass
    }

    private enum CodingKeys: String, CodingKey { case bone, end, length, radius, parent, joint, axis, swing, minAngle, maxAngle, mass }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = RagdollBone(bone: "")
        bone = try c.decodeIfPresent(String.self, forKey: .bone) ?? ""
        end = try c.decodeIfPresent(String.self, forKey: .end)
        length = try c.decodeIfPresent(Float.self, forKey: .length) ?? d.length
        radius = try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius
        parent = try c.decodeIfPresent(String.self, forKey: .parent)
        joint = try c.decodeIfPresent(JointKind.self, forKey: .joint) ?? d.joint
        axis = try c.decodeIfPresent(Vec3.self, forKey: .axis)
        swing = try c.decodeIfPresent(Float.self, forKey: .swing) ?? d.swing
        minAngle = try c.decodeIfPresent(Float.self, forKey: .minAngle) ?? d.minAngle
        maxAngle = try c.decodeIfPresent(Float.self, forKey: .maxAngle) ?? d.maxAngle
        mass = try c.decodeIfPresent(Float.self, forKey: .mass)
    }

    /// The joint's limits in radians.
    public var limits: JointLimits {
        switch joint {
        case .ball: .degrees(swing: swing, min: minAngle, max: maxAngle)
        case .hinge: .degrees(min: minAngle, max: maxAngle)
        case .fixed, .distance: JointLimits()
        }
    }
}

/// An impulse waiting for the next fixed step (`Ragdoll.applyImpulse`).
public struct RagdollImpulse: Codable, Equatable, Sendable {
    public var bone: String
    /// N·s, world space.
    public var impulse: Vec3
    /// Where it hits (world space); nil: the body's center of mass.
    public var point: Vec3?

    public init(bone: String, impulse: Vec3, point: Vec3? = nil) {
        self.bone = bone
        self.impulse = impulse
        self.point = point
    }
}

/// Physics bodies for a skeleton: put it on a character's root (the entity whose subtree holds
/// the bones) with `world.addPhysics` running. See the notes at the top of Ragdoll.swift.
///
/// ```swift
/// world.modify(Ragdoll.self, for: hero) { $0.hit(bone: "chest", impulse: Vec3(0, 0, -40)) }  // flinch
/// world.modify(Ragdoll.self, for: hero) { $0.goLimp() }                                        // die
/// world.modify(Ragdoll.self, for: hero) { $0.getUp() }                                         // back to the animation
/// ```
public struct Ragdoll: Component, Equatable, Sendable {
    public static let componentName = "Ragdoll"
    public static var fieldHints: [String: FieldHints] {
        ["weight": FieldHints(range: 0...1, step: 0.01, tooltip: "Partial: how much of the physics pose shows (0: the animation)"),
         "strength": FieldHints(range: 0...60, step: 0.5, tooltip: "Partial: how fast the bodies are pulled back to the animation (1/s)"),
         "blendTime": FieldHints(range: 0...5, step: 0.05, tooltip: "Seconds to blend from the physics pose back to the animation"),
         "mass": FieldHints(range: 1...1000, step: 1, tooltip: "Total kg, shared by volume (a bone's own mass overrides its share)"),
         "friction": FieldHints(range: 0...2, step: 0.01),
         "layer": FieldHints(tooltip: "Layer bits the bodies are on"), "mask": FieldHints(tooltip: "Layer bits they collide with"),
         "moveRootOnGetUp": FieldHints(tooltip: "On getting up from full, move this entity under the pelvis first"),
         "blend": FieldHints(readOnly: true, tooltip: "How much of the physics pose shows now"),
         "hitTime": FieldHints(hidden: true), "impulses": FieldHints(hidden: true)]
    }

    /// The bodies, root (pelvis) first.
    public var bones: [RagdollBone]
    public var mode: RagdollMode
    /// `partial`: the share of the physics pose shown (0...1).
    public var weight: Float
    /// `partial`: how fast the bodies are pulled back toward the animation (1/s).
    public var strength: Float
    /// Seconds to blend back to the animation when the mode returns to `animated`.
    public var blendTime: Float
    /// Total mass, kg.
    public var mass: Float
    public var friction: Float
    public var layer: UInt32
    public var mask: UInt32
    /// Getting up from `full` first moves this entity under the root body (on the ground below it).
    public var moveRootOnGetUp: Bool
    /// The share of the physics pose shown now (the system moves it toward the mode's).
    public var blend: Float
    /// Seconds left of a hit reaction before the mode returns to `animated` (0: none).
    public var hitTime: Float
    /// Impulses waiting for the next fixed step.
    public var impulses: [RagdollImpulse]

    public init(bones: [RagdollBone] = [], mode: RagdollMode = .animated, weight: Float = 0.6, strength: Float = 14, blendTime: Float = 0.5,
                mass: Float = 70, friction: Float = 0.7, layer: UInt32 = 1, mask: UInt32 = .max, moveRootOnGetUp: Bool = true) {
        self.bones = bones
        self.mode = mode
        self.weight = weight
        self.strength = strength
        self.blendTime = blendTime
        self.mass = mass
        self.friction = friction
        self.layer = layer
        self.mask = mask
        self.moveRootOnGetUp = moveRootOnGetUp
        blend = mode == .full ? 1 : 0
        hitTime = 0
        impulses = []
    }

    private enum CodingKeys: String, CodingKey {
        case bones, mode, weight, strength, blendTime, mass, friction, layer, mask, moveRootOnGetUp, blend, hitTime, impulses
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Ragdoll()
        bones = try c.decodeIfPresent([RagdollBone].self, forKey: .bones) ?? []
        mode = try c.decodeIfPresent(RagdollMode.self, forKey: .mode) ?? d.mode
        weight = try c.decodeIfPresent(Float.self, forKey: .weight) ?? d.weight
        strength = try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength
        blendTime = try c.decodeIfPresent(Float.self, forKey: .blendTime) ?? d.blendTime
        mass = try c.decodeIfPresent(Float.self, forKey: .mass) ?? d.mass
        friction = try c.decodeIfPresent(Float.self, forKey: .friction) ?? d.friction
        layer = try c.decodeIfPresent(UInt32.self, forKey: .layer) ?? d.layer
        mask = try c.decodeIfPresent(UInt32.self, forKey: .mask) ?? d.mask
        moveRootOnGetUp = try c.decodeIfPresent(Bool.self, forKey: .moveRootOnGetUp) ?? d.moveRootOnGetUp
        blend = try c.decodeIfPresent(Float.self, forKey: .blend) ?? (mode == .full ? 1 : 0)
        hitTime = try c.decodeIfPresent(Float.self, forKey: .hitTime) ?? 0
        impulses = try c.decodeIfPresent([RagdollImpulse].self, forKey: .impulses) ?? []
    }

    /// Physics takes over (death).
    public mutating func goLimp() {
        mode = .full
        hitTime = 0
    }

    /// Back to the animation, blending from the current physics pose over `blendTime`.
    public mutating func getUp() {
        mode = .animated
        hitTime = 0
    }

    /// A hit reaction: physics shows `weight` of the pose for `duration` seconds while the
    /// animation pulls the bodies back, then the animation returns (a limp ragdoll just takes
    /// the impulse). `impulse` (N·s, world space) hits `bone` at `point` (default its center).
    public mutating func hit(bone: String, impulse: Vec3, at point: Vec3? = nil, weight: Float = 0.6, duration: Float = 0.6) {
        if mode != .full {
            mode = .partial
            self.weight = min(max(weight, 0), 1)
            hitTime = max(duration, 0.01)
        }
        applyImpulse(bone: bone, impulse: impulse, at: point)
    }

    /// Queues an impulse on `bone`'s body for the next fixed step (only `partial` and `full`
    /// bodies move; see `hit` to switch too).
    public mutating func applyImpulse(bone: String, impulse: Vec3, at point: Vec3? = nil) {
        impulses.append(RagdollImpulse(bone: bone, impulse: impulse, point: point))
    }

    /// The physics share `mode` aims for.
    public var targetBlend: Float {
        switch mode {
        case .animated: 0
        case .partial: min(max(weight, 0), 1)
        case .full: 1
        }
    }

    /// What changes the bodies (a new list, mass or surface rebuilds them).
    var bodyLayout: [String] {
        [String(describing: bones), "\(mass)", "\(friction)", "\(layer)", "\(mask)"]
    }
}

// MARK: - Runtime

/// The bodies and joints of each ragdoll in one physics world (`PhysicsWorld.ragdolls`).
@MainActor
final class RagdollRuntime {
    struct Rig {
        var layout: [String]
        /// Bone entities, parents before children.
        var bones: [Entity]
        var names: [String]
        /// Index of the parent body (nil: the root body).
        var parents: [Int?]
        var bodies: [BodyID]
        /// Each body's mass, kg (kinematic bodies report none).
        var masses: [Float]
        var joints: [JointID]
        var group: UInt32
        /// The animated world poses of the bones (last `.lateUpdate`), and the ones before.
        var animated: [Pose]
        var previousAnimated: [Pose]
        var animatedLocal: [Transform]
        /// What `.lateUpdate` wrote, to tell it from a new animated pose.
        var written: [Transform?]
        /// The pose blended from while returning to the animation.
        var frozen: [Pose]?
        var isDynamic = false
        var mode: RagdollMode = .animated
    }

    var rigs: [Entity: Rig] = [:]
    private var nextGroup: UInt32 = 0x5244_0000
    /// Problems already logged, by ragdoll entity.
    private var reported: Set<String> = []

    func bodies(of entity: Entity) -> [BodyID] { rigs[entity]?.bodies ?? [] }

    func removeAll(in physics: PhysicsWorld) {
        for rig in rigs.values { destroy(rig, in: physics) }
        rigs.removeAll()
    }

    private func destroy(_ rig: Rig, in physics: PhysicsWorld) {
        for joint in rig.joints { physics.removeJoint(joint) }
        for body in rig.bodies { physics.removeBody(body) }
    }

    /// The first entity named `name` in `root`'s subtree (depth first).
    static func find(_ name: String, under root: Entity, in world: World) -> Entity? {
        if world.get(Name.self, for: root)?.value == name { return root }
        for child in world.children(of: root) {
            if let found = find(name, under: child, in: world) { return found }
        }
        return nil
    }

    static func pose(of entity: Entity, in world: World) -> Pose {
        let t = Transform(matrix: world.worldMatrix(of: entity))
        return Pose(position: t.position, rotation: t.rotation.normalized)
    }

    private func depth(_ entity: Entity, in world: World) -> Int {
        var d = 0, current = world.parent(of: entity)
        while let p = current, d < 4096 { d += 1; current = world.parent(of: p) }
        return d
    }

    /// Builds `ragdoll`'s bodies and joints at the bones' current poses.
    private func build(_ entity: Entity, _ ragdoll: Ragdoll, in world: World, physics: PhysicsWorld) -> Rig? {
        var found: [(config: RagdollBone, entity: Entity)] = []
        for config in ragdoll.bones {
            guard let bone = Self.find(config.bone, under: entity, in: world) else {
                if reported.insert("\(entity) \(config.bone)").inserted {
                    EngineLog.warning("Ragdoll on \(world.get(Name.self, for: entity)?.value ?? "\(entity)"): no bone '\(config.bone)'", category: "physics")
                }
                continue
            }
            if !found.contains(where: { $0.entity == bone }) { found.append((config, bone)) }
        }
        guard !found.isEmpty else { return nil }
        found.sort { depth($0.entity, in: world) < depth($1.entity, in: world) }
        let entities = found.map(\.entity)
        let poses = entities.map { Self.pose(of: $0, in: world) }
        // Shapes in each bone's frame.
        var shapes: [(shape: ColliderShape, offset: Pose, volume: Float, axis: Vec3)] = []
        for (k, item) in found.enumerated() {
            let c = item.config
            var tip: Vec3?
            if let end = c.end, let endEntity = Self.find(end, under: item.entity, in: world) ?? Self.find(end, under: entity, in: world) {
                tip = poses[k].inverseTransform(Self.pose(of: endEntity, in: world).position)
            } else if c.length > 0 {
                tip = Vec3(0, c.length, 0)
            }
            let r = max(c.radius, 0.005)
            if let tip, length(tip) > 1e-4 {
                let len = length(tip), dir = tip / len
                let half = max(len / 2 - r * 0.5, 0.005)
                let rotation = Self.rotation(from: Vec3(0, 1, 0), to: dir)
                shapes.append((.capsule(radius: r, halfHeight: half), Pose(position: tip / 2, rotation: rotation),
                               .pi * r * r * (2 * half) + 4 / 3 * .pi * r * r * r, dir))
            } else {
                shapes.append((.sphere(radius: r), Pose(), 4 / 3 * .pi * r * r * r, Vec3(0, 1, 0)))
            }
        }
        let totalVolume = max(shapes.reduce(0) { $0 + $1.volume }, 1e-6)
        let density = max(ragdoll.mass, 0.01) / totalVolume
        nextGroup &+= 1
        let group = nextGroup
        var bodies: [BodyID] = []
        var masses: [Float] = []
        for (k, item) in found.enumerated() {
            let d = item.config.mass.map { max($0, 0.01) / max(shapes[k].volume, 1e-6) } ?? density
            masses.append(d * shapes[k].volume)
            bodies.append(physics.addBody(BodyDescriptor(
                motion: .kinematic, pose: poses[k], shape: shapes[k].shape, shapeOffset: shapes[k].offset,
                material: ColliderMaterial(friction: ragdoll.friction, restitution: 0, density: d), layer: ragdoll.layer, mask: ragdoll.mask,
                linearDamping: 0.1, angularDamping: 0.6, entity: item.entity, group: group)))
            physics.bodies[Int(bodies[k].index)].isExternal = true
        }
        // Parents: named, else the nearest ragdoll bone above.
        var parents: [Int?] = []
        for (k, item) in found.enumerated() {
            var parent: Int?
            if let name = item.config.parent { parent = found.firstIndex { $0.config.bone == name } }
            if parent == nil {
                var up = world.parent(of: item.entity)
                while let e = up, parent == nil {
                    parent = entities.firstIndex(of: e)
                    if e == entity { break }
                    up = world.parent(of: e)
                }
            }
            parents.append(parent == k ? nil : parent)
        }
        var joints: [JointID] = []
        for (k, item) in found.enumerated() {
            guard let p = parents[k] else { continue }
            let c = item.config
            let localAxis = c.axis.map { length($0) > 1e-6 ? normalize($0) : Vec3(1, 0, 0) } ?? (c.joint == .hinge ? Vec3(1, 0, 0) : shapes[k].axis)
            let kind: JointKind = c.joint == .distance ? .ball : c.joint
            if let joint = physics.addJoint(JointDescriptor(kind: kind, bodyA: bodies[p], bodyB: bodies[k], anchor: poses[k].position,
                                                            axis: poses[k].rotation * localAxis, limits: c.limits)) {
                joints.append(joint)
            }
        }
        let locals = entities.map { world.get(Transform.self, for: $0) ?? Transform() }
        return Rig(layout: ragdoll.bodyLayout, bones: entities, names: found.map(\.config.bone), parents: parents, bodies: bodies, masses: masses, joints: joints,
                   group: group, animated: poses, previousAnimated: poses, animatedLocal: locals,
                   written: Array(repeating: nil, count: entities.count))
    }

    /// The fixed-step part (system "ragdoll").
    func fixedStep(in world: World, physics: PhysicsWorld, dt: Float) {
        var entities: [(Entity, Ragdoll)] = []
        world.query(Ragdoll.self) { e, r in entities.append((e, r)) }
        let alive = Set(entities.map(\.0))
        for (e, rig) in rigs where !alive.contains(e) {
            destroy(rig, in: physics)
            rigs[e] = nil
        }
        for (entity, original) in entities {
            var ragdoll = original
            if let rig = rigs[entity], rig.layout != ragdoll.bodyLayout || rig.bodies.contains(where: { !physics.contains($0) }) {
                destroy(rig, in: physics)
                rigs[entity] = nil
            }
            if rigs[entity] == nil {
                guard let rig = build(entity, ragdoll, in: world, physics: physics) else { continue }
                rigs[entity] = rig
            }
            guard var rig = rigs[entity] else { continue }
            if ragdoll.mode == .partial, ragdoll.hitTime > 0 {
                ragdoll.hitTime -= dt
                if ragdoll.hitTime <= 0 {
                    ragdoll.hitTime = 0
                    ragdoll.mode = .animated
                }
            }
            switch ragdoll.mode {
            case .animated:
                if rig.isDynamic {
                    // Back to the animation: freeze the physics pose to blend from, stand the root up under the pelvis.
                    rig.frozen = rig.bodies.map { physics.pose(of: $0) ?? Pose() }
                    if rig.mode == .full, ragdoll.moveRootOnGetUp, let pelvis = rig.frozen?.first {
                        moveRoot(entity, under: pelvis.position, rig: rig, in: world, physics: physics)
                    }
                    for body in rig.bodies { physics.setMotion(body, .kinematic) }
                    rig.isDynamic = false
                }
                for (k, body) in rig.bodies.enumerated() { physics.moveKinematic(body, to: rig.animated[k], dt: dt) }
            case .partial, .full:
                if !rig.isDynamic {
                    // Start from the animation's motion.
                    let frame = max(world.time.delta, 1e-4)
                    for body in rig.bodies { physics.setMotion(body, .dynamic) }
                    for (k, body) in rig.bodies.enumerated() {
                        let (v, w) = Self.velocity(from: rig.previousAnimated[k], to: rig.animated[k], dt: frame)
                        physics.setPose(body, rig.animated[k])
                        physics.setLinearVelocity(body, v)
                        physics.setAngularVelocity(body, w)
                    }
                    rig.isDynamic = true
                    rig.frozen = nil
                }
                if ragdoll.mode == .partial {
                    let s = 1 - expf(-max(ragdoll.strength, 0) * dt)
                    for (k, body) in rig.bodies.enumerated() {
                        guard let pose = physics.pose(of: body) else { continue }
                        let (v, w) = Self.velocity(from: pose, to: rig.animated[k], dt: dt)
                        let v0 = physics.linearVelocity(of: body), w0 = physics.angularVelocity(of: body)
                        physics.setLinearVelocity(body, v0 + (v - v0) * s)
                        physics.setAngularVelocity(body, w0 + (w - w0) * s)
                    }
                }
            }
            rig.mode = ragdoll.mode
            if !ragdoll.impulses.isEmpty {
                for impulse in ragdoll.impulses {
                    guard let k = index(of: impulse.bone, in: rig, root: entity, world: world) else {
                        if reported.insert("\(entity) impulse \(impulse.bone)").inserted {
                            EngineLog.warning("Ragdoll: no body for bone '\(impulse.bone)'", category: "physics")
                        }
                        continue
                    }
                    physics.applyImpulse(rig.bodies[k], impulse.impulse, at: impulse.point)
                }
                ragdoll.impulses.removeAll()
            }
            rigs[entity] = rig
            if ragdoll != original { world.add(ragdoll, to: entity) }
        }
    }

    /// The body of `name`: its own, or the nearest ragdoll bone above the bone so named.
    func index(of name: String, in rig: Rig, root: Entity, world: World) -> Int? {
        if let k = rig.names.firstIndex(of: name) { return k }
        guard let bone = Self.find(name, under: root, in: world) else { return nil }
        var current: Entity? = bone
        while let e = current {
            if let k = rig.bones.firstIndex(of: e) { return k }
            if e == root { break }
            current = world.parent(of: e)
        }
        return nil
    }

    /// Moves the ragdoll's entity so it stands on the ground under `point`.
    private func moveRoot(_ entity: Entity, under point: Vec3, rig: Rig, in world: World, physics: PhysicsWorld) {
        guard var transform = world.get(Transform.self, for: entity) else { return }
        let current = Self.pose(of: entity, in: world).position
        var target = Vec3(point.x, current.y, point.z)
        let filter = QueryFilter(excluding: rig.bodies + (physics.body(for: entity).map { [$0] } ?? []))
        if let hit = physics.raycast(Ray(origin: point + Vec3(0, 0.5, 0), direction: Vec3(0, -1, 0)), maxDistance: 4, filter: filter) {
            target.y = hit.point.y
        }
        let delta = target - current
        if let parent = world.parent(of: entity) {
            let p = Transform(matrix: world.worldMatrix(of: parent))
            transform.position += p.rotation.conjugate * delta / p.scale
        } else {
            transform.position += delta
        }
        world.add(transform, to: entity)
    }

    /// The velocities that move `a` to `b` in `dt`.
    static func velocity(from a: Pose, to b: Pose, dt: Float) -> (Vec3, Vec3) {
        let v = (b.position - a.position) / dt
        var dq = b.rotation * a.rotation.conjugate
        if dq.w < 0 { dq = Quat(vector: -dq.vector) }
        let s = length(dq.imaginary)
        let angle = 2 * atan2f(s, dq.w)
        return (v, s > 1e-9 ? dq.imaginary / s * (angle / dt) : .zero)
    }

    /// The pose part (system "ragdoll.pose").
    func writePose(in world: World, physics: PhysicsWorld, dt: Float) {
        for (entity, var rig) in rigs.sorted(by: { $0.key.index < $1.key.index }) {
            guard var ragdoll = world.get(Ragdoll.self, for: entity) else { continue }
            // The animated pose: what the animation wrote this frame, or (bones it left alone) last frame's.
            for (k, bone) in rig.bones.enumerated() {
                guard let t = world.get(Transform.self, for: bone) else { continue }
                if let written = rig.written[k], t == written {
                    world.add(rig.animatedLocal[k], to: bone)
                } else {
                    rig.animatedLocal[k] = t
                }
            }
            rig.previousAnimated = rig.animated
            rig.animated = rig.bones.map { Self.pose(of: $0, in: world) }
            let old = ragdoll.blend
            switch ragdoll.mode {
            case .animated:
                ragdoll.blend = ragdoll.blendTime > 0 ? max(ragdoll.blend - dt / ragdoll.blendTime, 0) : 0
            case .partial:
                let target = ragdoll.targetBlend
                let rate = dt / max(ragdoll.blendTime * 0.5, 0.05)
                ragdoll.blend = ragdoll.blend < target ? target : max(ragdoll.blend - rate, target)
            case .full:
                ragdoll.blend = 1
            }
            if ragdoll.blend != old { world.add(ragdoll, to: entity) }
            let source: [Pose]? = rig.isDynamic ? rig.bodies.map { physics.pose(of: $0) ?? Pose() } : rig.frozen
            guard ragdoll.blend > 0, let source else {
                rig.written = Array(repeating: nil, count: rig.bones.count)
                if ragdoll.blend <= 0 { rig.frozen = nil }
                rigs[entity] = rig
                continue
            }
            let b = ragdoll.blend
            for (k, bone) in rig.bones.enumerated() {
                let animated = rig.animated[k], physical = source[k]
                let rotation = Quat.slerp(animated.rotation, physical.rotation, b).normalized
                var local = rig.animatedLocal[k]
                let parentWorld = world.parent(of: bone).map { Transform(matrix: world.worldMatrix(of: $0)) } ?? Transform()
                local.rotation = (parentWorld.rotation.conjugate * rotation).normalized
                if rig.parents[k] == nil {
                    let position = animated.position + (physical.position - animated.position) * b
                    local.position = parentWorld.rotation.conjugate * (position - parentWorld.position) / parentWorld.scale
                }
                world.add(local, to: bone)
                rig.written[k] = local
            }
            rigs[entity] = rig
        }
    }

    /// The rotation taking unit `a` to unit `b`.
    static func rotation(from a: Vec3, to b: Vec3) -> Quat {
        let d = dot(a, b)
        if d > 0.99999 { return .identity }
        if d < -0.99999 {
            let axis = abs(a.x) < 0.9 ? cross(a, Vec3(1, 0, 0)) : cross(a, Vec3(0, 0, 1))
            return Quat(angle: .pi, axis: normalize(axis))
        }
        return Quat(angle: acosf(d), axis: normalize(cross(a, b)))
    }
}

extension PhysicsWorld {
    /// The body `Ragdoll` on `entity` made for `bone` (or the nearest ragdoll bone above it).
    public func ragdollBody(of entity: Entity, bone: String, in world: World) -> BodyID? {
        guard let rig = ragdolls.rigs[entity], let k = ragdolls.index(of: bone, in: rig, root: entity, world: world) else { return nil }
        return rig.bodies[k]
    }

    /// Every body of the `Ragdoll` on `entity`, root first (empty until the first fixed step).
    public func ragdollBodies(of entity: Entity) -> [BodyID] { ragdolls.bodies(of: entity) }

    /// The joints of the `Ragdoll` on `entity`.
    public func ragdollJoints(of entity: Entity) -> [JointID] { ragdolls.rigs[entity]?.joints ?? [] }

    /// The bodies of the `Ragdoll` on `entity`: each one's bone, the bone of the body it hangs
    /// from (nil: the root body), its id and mass (kg, also while kinematic), parents first.
    public func ragdollLayout(of entity: Entity) -> [(bone: String, parent: String?, body: BodyID, mass: Float)] {
        guard let rig = ragdolls.rigs[entity] else { return [] }
        return rig.names.indices.map { k in (rig.names[k], rig.parents[k].map { rig.names[$0] }, rig.bodies[k], rig.masses[k]) }
    }

    /// Runs the fixed-step part of the ragdolls now (what the "ragdoll" system of `addPhysics`
    /// does before each step): builds new ones, drives modes, applies queued impulses.
    public func updateRagdolls(in world: World, dt: Float) {
        ragdolls.fixedStep(in: world, physics: self, dt: dt)
    }
}

extension World {
    /// Adds the ragdoll systems (`addPhysics` does).
    func addRagdollSystems(_ physics: PhysicsWorld) {
        addSystem("ragdoll", stage: .fixedUpdate, before: "physics") { world in
            physics.ragdolls.fixedStep(in: world, physics: physics, dt: world.time.delta)
        }
        addSystem("ragdoll.pose", stage: .lateUpdate, before: systemNames(in: .lateUpdate).first) { world in
            guard !physics.ragdolls.rigs.isEmpty else { return }
            physics.ragdolls.writePose(in: world, physics: physics, dt: world.time.delta)
        }
    }
}
