import Foundation
import EngineCore
import EnginePhysics
import EngineScene

// Inverse kinematics on an `Animator`'s pose: after the state machine and layers make the pose
// and before it is written to the bones (so before skinning), each node of `Animator.ik` bends
// bones toward a target:
//
// - `twoBoneIK`: an arm or a leg (root, middle, end) reaches a point; the middle joint bends
//   toward `pole` (a direction in the character's space) or keeps the animated bend.
// - `aim`: a chain (spine, chest, head; or up to a weapon hand) turns so the last bone's
//   `aimAxis` points at the target, the turn shared along the chain (at most `maxAngle` each).
// - `chainIK`: FABRIK for longer chains (tails, tentacles): the chain's tip reaches the target.
// - `footPlacement`: legs on uneven ground. A ray down from above each animated foot finds the
//   ground (physics, `World.attachedPhysics`); the pelvis drops so the lower foot reaches it,
//   each leg is solved like `twoBoneIK`, feet turn to the ground's normal and planted feet
//   (animated near the character's base) stay locked where they landed.
//
// Each node has a weight (0...1) times its float `weightParameter`, so a graph parameter can
// blend it in and out. Targets are world-space points (`target`, set at run time with
// `Animator.setIKTarget`) or an entity followed by name (`targetEntity`).
//
// `.animgraph` files list nodes under `ik` (every key optional):
//
// ```json
// "ik": [
//   {"name": "Look", "type": "aim", "bones": ["spine", "chest", "neck", "head"], "targetEntity": "Target",
//    "weightParameter": "look"},
//   {"name": "Hand", "type": "twoBoneIK", "bones": ["upperArm.R", "lowerArm.R", "hand.R"], "target": [0.3, 1.2, 0.5], "pole": [0, 0, -1]},
//   {"name": "Tail", "type": "chainIK", "bones": ["tail", "tailTip"], "targetEntity": "Bone"},
//   {"name": "Feet", "type": "footPlacement", "pelvis": "hips",
//    "legs": [["upperLeg.L", "lowerLeg.L", "foot.L"], ["upperLeg.R", "lowerLeg.R", "foot.R"]]}
// ]
// ```

/// What an `AnimationIKNode` solves.
public enum AnimationIKType: String, Codable, Sendable, CaseIterable {
    case twoBoneIK, aim, chainIK, footPlacement

    /// How many `bones` it needs (nil: any number from 2; footPlacement uses `legs`).
    public var boneCount: Int? {
        switch self {
        case .twoBoneIK: 3
        case .aim: nil
        case .chainIK: nil
        case .footPlacement: 0
        }
    }
}

/// One IK step on an animator's pose. See the notes at the top of AnimationIK.swift.
public struct AnimationIKNode: Codable, Equatable, Sendable {
    /// Code and scripts address the node by name (`Animator.setIKTarget`).
    public var name: String
    public var type: AnimationIKType
    /// Bone `Name`s: twoBoneIK [root, middle, end]; aim and chainIK the chain from root to tip.
    public var bones: [String]
    /// 0...1, times `weightParameter`'s value.
    public var weight: Float
    /// A float parameter of the animator that multiplies `weight` (missing: 1).
    public var weightParameter: String?
    /// The world-space point to reach or look at.
    public var target: Vec3?
    /// Follows the first entity with this `Name` (wins over `target` while it exists).
    public var targetEntity: String?
    /// twoBoneIK: the direction the middle joint bends toward, in the character's space (knees
    /// [0, 0, 1], elbows [0, 0, -1]); nil keeps the animated bend.
    public var pole: Vec3?
    /// aim: the last bone's axis (its own space) that points at the target.
    public var aimAxis: Vec3
    /// aim: the most each bone turns, degrees.
    public var maxAngle: Float
    /// chainIK: FABRIK passes and the distance at which it stops, meters.
    public var iterations: Int
    public var tolerance: Float
    /// footPlacement: each leg [hip bone, knee bone, ankle bone].
    public var legs: [[String]]
    /// footPlacement: the bone that moves down so the lower foot reaches (usually the hips).
    public var pelvis: String?
    /// footPlacement: rays start this far above the character's base and reach `maxStep` below it.
    public var rayHeight: Float
    public var maxStep: Float
    /// footPlacement: turn feet to the ground's slope (at most 40 degrees).
    public var alignFeet: Bool
    /// footPlacement: a planted foot (animated within `plantHeight` of the lowest it has been) stays where it landed.
    public var lockFeet: Bool
    public var plantHeight: Float
    /// footPlacement: layer bits the rays hit.
    public var mask: UInt32

    public init(name: String, type: AnimationIKType, bones: [String] = [], weight: Float = 1, weightParameter: String? = nil,
                target: Vec3? = nil, targetEntity: String? = nil, pole: Vec3? = nil, aimAxis: Vec3 = Vec3(0, 0, 1), maxAngle: Float = 60,
                iterations: Int = 10, tolerance: Float = 0.001, legs: [[String]] = [], pelvis: String? = nil, rayHeight: Float = 0.6,
                maxStep: Float = 0.5, alignFeet: Bool = true, lockFeet: Bool = true, plantHeight: Float = 0.04, mask: UInt32 = .max) {
        self.name = name
        self.type = type
        self.bones = bones
        self.weight = weight
        self.weightParameter = weightParameter
        self.target = target
        self.targetEntity = targetEntity
        self.pole = pole
        self.aimAxis = aimAxis
        self.maxAngle = maxAngle
        self.iterations = iterations
        self.tolerance = tolerance
        self.legs = legs
        self.pelvis = pelvis
        self.rayHeight = rayHeight
        self.maxStep = maxStep
        self.alignFeet = alignFeet
        self.lockFeet = lockFeet
        self.plantHeight = plantHeight
        self.mask = mask
    }

    private enum CodingKeys: String, CodingKey {
        case name, type, bones, weight, weightParameter, target, targetEntity, pole, aimAxis, maxAngle, iterations, tolerance, legs, pelvis,
             rayHeight, maxStep, alignFeet, lockFeet, plantHeight, mask
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decodeIfPresent(AnimationIKType.self, forKey: .type) ?? .twoBoneIK
        let d = AnimationIKNode(name: "", type: type)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? type.rawValue, type: type,
                  bones: try c.decodeIfPresent([String].self, forKey: .bones) ?? [],
                  weight: try c.decodeIfPresent(Float.self, forKey: .weight) ?? d.weight,
                  weightParameter: try c.decodeIfPresent(String.self, forKey: .weightParameter),
                  target: try c.decodeIfPresent(Vec3.self, forKey: .target),
                  targetEntity: try c.decodeIfPresent(String.self, forKey: .targetEntity),
                  pole: try c.decodeIfPresent(Vec3.self, forKey: .pole),
                  aimAxis: try c.decodeIfPresent(Vec3.self, forKey: .aimAxis) ?? d.aimAxis,
                  maxAngle: try c.decodeIfPresent(Float.self, forKey: .maxAngle) ?? d.maxAngle,
                  iterations: try c.decodeIfPresent(Int.self, forKey: .iterations) ?? d.iterations,
                  tolerance: try c.decodeIfPresent(Float.self, forKey: .tolerance) ?? d.tolerance,
                  legs: try c.decodeIfPresent([[String]].self, forKey: .legs) ?? [],
                  pelvis: try c.decodeIfPresent(String.self, forKey: .pelvis),
                  rayHeight: try c.decodeIfPresent(Float.self, forKey: .rayHeight) ?? d.rayHeight,
                  maxStep: try c.decodeIfPresent(Float.self, forKey: .maxStep) ?? d.maxStep,
                  alignFeet: try c.decodeIfPresent(Bool.self, forKey: .alignFeet) ?? d.alignFeet,
                  lockFeet: try c.decodeIfPresent(Bool.self, forKey: .lockFeet) ?? d.lockFeet,
                  plantHeight: try c.decodeIfPresent(Float.self, forKey: .plantHeight) ?? d.plantHeight,
                  mask: try c.decodeIfPresent(UInt32.self, forKey: .mask) ?? d.mask)
    }

    /// Writes the keys that apply to `type` (and non-default values).
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let d = AnimationIKNode(name: "", type: type)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        if type != .footPlacement || !bones.isEmpty { try c.encode(bones, forKey: .bones) }
        try c.encode(weight, forKey: .weight)
        try c.encodeIfPresent(weightParameter, forKey: .weightParameter)
        try c.encodeIfPresent(target, forKey: .target)
        try c.encodeIfPresent(targetEntity, forKey: .targetEntity)
        switch type {
        case .twoBoneIK:
            try c.encodeIfPresent(pole, forKey: .pole)
        case .aim:
            try c.encode(aimAxis, forKey: .aimAxis)
            try c.encode(maxAngle, forKey: .maxAngle)
        case .chainIK:
            try c.encode(iterations, forKey: .iterations)
            try c.encode(tolerance, forKey: .tolerance)
        case .footPlacement:
            try c.encode(legs, forKey: .legs)
            try c.encodeIfPresent(pelvis, forKey: .pelvis)
            try c.encodeIfPresent(pole, forKey: .pole)
            try c.encode(rayHeight, forKey: .rayHeight)
            try c.encode(maxStep, forKey: .maxStep)
            try c.encode(alignFeet, forKey: .alignFeet)
            try c.encode(lockFeet, forKey: .lockFeet)
            try c.encode(plantHeight, forKey: .plantHeight)
            if mask != d.mask { try c.encode(mask, forKey: .mask) }
        }
    }

    /// Every bone name the node uses.
    public var allBones: [String] {
        bones + legs.flatMap { $0 } + (pelvis.map { [$0] } ?? [])
    }

    /// Problems found without a skeleton (`bones` names a skeleton's bones to check them too).
    public func problems(bones skeleton: Set<String>? = nil, parameters: [String: AnimationGraphParameterType]? = nil) -> [String] {
        var problems: [String] = []
        let what = "IK node '\(name)'"
        switch type {
        case .twoBoneIK:
            if bones.count != 3 { problems.append("\(what) (twoBoneIK) needs 3 bones (root, middle, end), not \(bones.count)") }
        case .aim:
            if bones.isEmpty { problems.append("\(what) (aim) needs at least one bone") }
            if length(aimAxis) < 1e-6 { problems.append("\(what): aimAxis is zero") }
        case .chainIK:
            if bones.count < 2 { problems.append("\(what) (chainIK) needs at least 2 bones (root to tip)") }
        case .footPlacement:
            if legs.isEmpty { problems.append("\(what) (footPlacement) has no legs") }
            for (i, leg) in legs.enumerated() where leg.count != 3 {
                problems.append("\(what): leg \(i + 1) needs 3 bones (hip, knee, ankle), not \(leg.count)")
            }
        }
        if !(0...1).contains(weight) { problems.append("\(what): weight \(weight) is outside 0...1") }
        if let skeleton {
            for bone in allBones where !skeleton.contains(bone) { problems.append("\(what): no bone '\(bone)'") }
        }
        if let parameters, let p = weightParameter {
            if let kind = parameters[p] {
                if kind != .float { problems.append("\(what): weightParameter '\(p)' isn't a float parameter") }
            } else {
                problems.append("\(what): weightParameter '\(p)' doesn't exist")
            }
        }
        return problems
    }

    /// A humanoid's foot placement (CharacterRig bone names).
    public static func humanoidFeet(name: String = "Feet") -> AnimationIKNode {
        AnimationIKNode(name: name, type: .footPlacement, pole: Vec3(0, 0, 1),
                        legs: [["upperLeg.L", "lowerLeg.L", "foot.L"], ["upperLeg.R", "lowerLeg.R", "foot.R"]], pelvis: "hips")
    }
}

extension Animator {
    /// The IK node named `name`.
    public func ikNode(_ name: String) -> AnimationIKNode? { ik?.first { $0.name == name } }

    /// Sets the world-space point the IK node `name` reaches or looks at (nil clears it).
    /// Returns false when there is no such node.
    @discardableResult
    public mutating func setIKTarget(_ name: String, _ target: Vec3?) -> Bool {
        guard let i = ik?.firstIndex(where: { $0.name == name }) else { return false }
        ik![i].target = target
        return true
    }

    /// Sets the IK node `name`'s weight (0...1). Returns false when there is no such node.
    @discardableResult
    public mutating func setIKWeight(_ name: String, _ weight: Float) -> Bool {
        guard let i = ik?.firstIndex(where: { $0.name == name }) else { return false }
        ik![i].weight = min(max(weight, 0), 1)
        return true
    }

    /// `node`'s weight now: its own times its weight parameter, clamped to 0...1.
    public func effectiveWeight(_ node: AnimationIKNode) -> Float {
        let scale = node.weightParameter.flatMap { float($0) } ?? 1
        return min(max(node.weight * scale, 0), 1)
    }

    /// Takes a graph's IK nodes: they replace the animator's (keeping run-time targets of nodes
    /// with the same name and type); a graph without any leaves the animator's own.
    public mutating func replaceIK(_ nodes: [AnimationIKNode]) {
        guard !nodes.isEmpty else { return }
        let old = ik ?? []
        ik = nodes.map { node in
            var node = node
            if node.target == nil, let previous = old.first(where: { $0.name == node.name && $0.type == node.type }) {
                node.target = previous.target
            }
            return node
        }
    }
}

// MARK: - Solvers

/// The IK solvers on world-space positions and rotations (pure functions, for tests and tools).
public enum IKSolver {
    /// The rotation taking direction `a` to direction `b` (shortest arc; any lengths).
    public static func rotation(from a: Vec3, to b: Vec3) -> Quat {
        let la = length(a), lb = length(b)
        guard la > 1e-8, lb > 1e-8 else { return .identity }
        let u = a / la, v = b / lb
        let d = min(max(dot(u, v), -1), 1)
        if d > 0.999999 { return .identity }
        if d < -0.999999 {
            let axis = abs(u.x) < 0.9 ? cross(u, Vec3(1, 0, 0)) : cross(u, Vec3(0, 0, 1))
            return Quat(angle: .pi, axis: normalize(axis))
        }
        return Quat(angle: acosf(d), axis: normalize(cross(u, v)))
    }

    /// Where the middle and end joints of a two-bone chain go so the end reaches `target`
    /// (clamped to the reach): the middle joint bends toward `pole` (a direction; nil or
    /// parallel to the reach: the current bend at `middle`).
    public static func twoBone(root a: Vec3, middle b: Vec3, end c: Vec3, target: Vec3, pole: Vec3? = nil) -> (middle: Vec3, end: Vec3) {
        let l1 = length(b - a), l2 = length(c - b)
        let toTarget = target - a
        let reach = length(toTarget)
        guard l1 > 1e-6, l2 > 1e-6, reach > 1e-6 else { return (b, c) }
        let dir = toTarget / reach
        let d = min(max(reach, abs(l1 - l2) + 1e-4), l1 + l2 - 1e-4)
        func perpendicular(_ v: Vec3) -> Vec3? {
            let p = v - dir * dot(v, dir)
            let len = length(p)
            return len > 1e-5 ? p / len : nil
        }
        let bend = pole.flatMap(perpendicular) ?? perpendicular(b - a) ?? perpendicular(c - a)
            ?? normalize(abs(dir.y) < 0.9 ? cross(dir, Vec3(0, 1, 0)) : cross(dir, Vec3(1, 0, 0)))
        let x = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
        let h = max(l1 * l1 - x * x, 0).squareRoot()
        return (a + dir * x + bend * h, a + dir * d)
    }

    /// FABRIK: new joint positions for a chain (root first) whose tip should reach `target`.
    /// The root stays; bone lengths are kept. Out of reach, the chain points straight at it.
    public static func fabrik(_ joints: [Vec3], target: Vec3, iterations: Int = 10, tolerance: Float = 0.001) -> [Vec3] {
        guard joints.count >= 2 else { return joints }
        var p = joints
        let n = p.count - 1
        let lengths = (0..<n).map { length(p[$0 + 1] - p[$0]) }
        let root = p[0]
        if length(target - root) >= lengths.reduce(0, +) {
            for i in 0..<n {
                p[i + 1] = p[i] + direction(target - p[i]) * lengths[i]
            }
            return p
        }
        for _ in 0..<max(iterations, 1) {
            p[n] = target
            for i in stride(from: n - 1, through: 0, by: -1) {
                p[i] = p[i + 1] + direction(p[i] - p[i + 1]) * lengths[i]
            }
            p[0] = root
            for i in 0..<n {
                p[i + 1] = p[i] + direction(p[i + 1] - p[i]) * lengths[i]
            }
            if length(p[n] - target) <= tolerance { break }
        }
        return p
    }

    private static func direction(_ v: Vec3) -> Vec3 {
        let len = length(v)
        return len > 1e-8 ? v / len : Vec3(0, 1, 0)
    }

    /// `q` scaled to `fraction` of its angle, at most `maxAngle` radians.
    static func partial(_ q: Quat, _ fraction: Float, maxAngle: Float = .pi) -> Quat {
        var q = q
        if q.w < 0 { q = Quat(vector: -q.vector) }
        let s = length(q.imaginary)
        guard s > 1e-8 else { return .identity }
        let angle = 2 * atan2f(s, q.w)
        return Quat(angle: min(angle * fraction, maxAngle), axis: q.imaginary / s)
    }
}

// MARK: - Applying to a pose

/// The world transforms of an animator's targets while IK edits its pose.
@MainActor
struct IKPose {
    let world: World
    let targets: [Entity]
    /// Each target's parent among the targets (nil: another entity, see `base`).
    let parents: [Int?]
    /// The world transform above targets whose parent isn't a target.
    let base: [Transform]
    var pose: AnimationPose
    var globals: [Transform] = []

    init(world: World, targets: [Entity], parents: [Int?], pose: AnimationPose, moved: Set<Int> = []) {
        self.world = world
        self.targets = targets
        self.parents = parents
        var pose = pose
        // Bones no clip drives start from their rest pose (in `pose`), so IK never builds on its
        // own last result; rig roots (the animator's entity) are where they really are.
        for i in 0..<min(pose.count, targets.count) where !pose.animated[i] && parents[i] == nil && !moved.contains(i) {
            if let t = world.get(Transform.self, for: targets[i]) { pose.transforms[i] = t }
        }
        self.pose = pose
        base = targets.indices.map { i in
            guard parents[i] == nil, let parent = world.parent(of: targets[i]) else { return Transform() }
            return Transform(matrix: world.worldMatrix(of: parent))
        }
        update()
    }

    static func compose(_ p: Transform, _ l: Transform) -> Transform {
        Transform(position: p.position + p.rotation * (p.scale * l.position), rotation: (p.rotation * l.rotation).normalized, scale: p.scale * l.scale)
    }

    mutating func update() {
        let n = min(pose.count, targets.count)
        globals = Array(repeating: Transform(), count: n)
        var done = [Bool](repeating: false, count: n)
        func visit(_ i: Int, _ depth: Int) {
            if done[i] { return }
            if let p = parents[i], p < n, p != i, depth < 512 {
                visit(p, depth + 1)
                globals[i] = Self.compose(globals[p], pose.transforms[i])
            } else {
                globals[i] = Self.compose(base[i], pose.transforms[i])
            }
            done[i] = true
        }
        for i in 0..<n { visit(i, 0) }
    }

    func parentGlobal(_ i: Int) -> Transform { parents[i].map { globals[$0] } ?? base[i] }

    /// Sets target `i`'s world rotation (its local rotation relative to its parent).
    mutating func setWorldRotation(_ i: Int, _ rotation: Quat) {
        pose.transforms[i].rotation = (parentGlobal(i).rotation.conjugate * rotation).normalized
        pose.animated[i] = true
        update()
    }

    /// Moves target `i` by `delta` in world space.
    mutating func move(_ i: Int, by delta: Vec3) {
        let p = parentGlobal(i)
        pose.transforms[i].position += p.rotation.conjugate * delta / p.scale
        pose.animated[i] = true
        update()
    }

    /// Turns bone `i` so its child `child` moves from where it is to `position`.
    mutating func pointBone(_ i: Int, child: Int, at position: Vec3) {
        let from = globals[child].position - globals[i].position
        let to = position - globals[i].position
        setWorldRotation(i, (IKSolver.rotation(from: from, to: to) * globals[i].rotation).normalized)
    }

    /// Two-bone IK on targets a, b, c toward `target`, `weight` of the way; c keeps its world rotation.
    mutating func twoBone(_ a: Int, _ b: Int, _ c: Int, target: Vec3, pole: Vec3?, weight: Float) {
        guard weight > 0 else { return }
        let endRotation = globals[c].rotation
        let goal = globals[c].position + (target - globals[c].position) * weight
        let solved = IKSolver.twoBone(root: globals[a].position, middle: globals[b].position, end: globals[c].position, target: goal, pole: pole)
        pointBone(a, child: b, at: solved.middle)
        pointBone(b, child: c, at: solved.end)
        setWorldRotation(c, endRotation)
    }

    /// Aims the chain's last bone's `axis` at `target`.
    mutating func aim(_ chain: [Int], axis: Vec3, target: Vec3, weight: Float, maxAngle: Float) {
        guard weight > 0, let tip = chain.last, length(axis) > 1e-6 else { return }
        let localAxis = normalize(axis)
        for (k, bone) in chain.enumerated() {
            let current = globals[tip].rotation * localAxis
            let wanted = target - globals[tip].position
            guard length(wanted) > 1e-4 else { return }
            let full = IKSolver.rotation(from: current, to: wanted)
            let turn = IKSolver.partial(full, weight / Float(chain.count - k), maxAngle: maxAngle)
            setWorldRotation(bone, (turn * globals[bone].rotation).normalized)
        }
    }

    /// FABRIK on a chain (root to tip) toward `target`.
    mutating func chain(_ chain: [Int], target: Vec3, weight: Float, iterations: Int, tolerance: Float) {
        guard weight > 0, chain.count >= 2, let tip = chain.last else { return }
        let goal = globals[tip].position + (target - globals[tip].position) * weight
        let solved = IKSolver.fabrik(chain.map { globals[$0].position }, target: goal, iterations: iterations, tolerance: tolerance)
        for k in 0..<(chain.count - 1) { pointBone(chain[k], child: chain[k + 1], at: solved[k + 1]) }
    }
}

/// What IK remembers between frames: planted feet and bone lookups. One per animation system.
@MainActor
public final class AnimationIKState {
    struct Rig {
        var targets: [Entity]
        var parents: [Int?]
        var names: [String: Int]
    }

    private var rigs: [Entity: Rig] = [:]
    /// Planted feet: world position, by animator entity and "node/leg".
    var locks: [Entity: [String: Vec3]] = [:]
    /// The lowest each foot has been above the character's base (its planted height).
    var lows: [Entity: [String: Float]] = [:]
    private var found: [String: Entity] = [:]
    private var reported: Set<String> = []

    public init() {}

    func rig(for entity: Entity, targets: [Entity], in world: World) -> Rig {
        if let rig = rigs[entity], rig.targets == targets { return rig }
        let skeleton = world.animationSkeleton(targets: targets)
        var names: [String: Int] = [:]
        for (i, bone) in skeleton.bones.enumerated() where !bone.name.isEmpty && names[bone.name] == nil { names[bone.name] = i }
        let rig = Rig(targets: targets, parents: skeleton.bones.map(\.parent), names: names)
        rigs[entity] = rig
        return rig
    }

    /// The first entity named `name` (cached while it keeps the name).
    func entity(named name: String, in world: World) -> Entity? {
        if let e = found[name], world.isAlive(e), world.get(Name.self, for: e)?.value == name { return e }
        var result: Entity?
        world.query(Name.self) { e, n in if result == nil, n.value == name { result = e } }
        found[name] = result
        return result
    }

    func warnOnce(_ key: String, _ message: @autoclosure () -> String) {
        if reported.insert(key).inserted { EngineLog.warning(message(), category: .animation) }
    }

    /// Forgets animators not in `alive`.
    public func keepOnly(_ alive: Set<Entity>) {
        if rigs.keys.contains(where: { !alive.contains($0) }) { rigs = rigs.filter { alive.contains($0.key) } }
        if locks.keys.contains(where: { !alive.contains($0) }) { locks = locks.filter { alive.contains($0.key) } }
        if lows.keys.contains(where: { !alive.contains($0) }) { lows = lows.filter { alive.contains($0.key) } }
    }
}

extension World {
    /// Runs `animator.ik` (on the animator on `entity`) on `pose`, in order: the targets'
    /// world transforms come from the world above them and `pose` below. Changed bones are
    /// marked animated so they are written. Foot placement casts rays in `attachedPhysics`
    /// (skipped without one). `state` keeps planted feet between frames.
    public func applyIK(_ animator: Animator, on entity: Entity, pose: inout AnimationPose, state: AnimationIKState) {
        guard let nodes = animator.ik, !nodes.isEmpty, !animator.targets.isEmpty else { return }
        let rig = state.rig(for: entity, targets: animator.targets, in: self)
        let moved = Set(nodes.flatMap(\.allBones).compactMap { rig.names[$0] })
        var ik = IKPose(world: self, targets: animator.targets, parents: rig.parents, pose: pose, moved: moved)
        let rootWorld = Transform(matrix: worldMatrix(of: entity))
        let count = ik.globals.count
        func index(_ bone: String, _ node: AnimationIKNode) -> Int? {
            if let i = rig.names[bone], i < count { return i }
            state.warnOnce("\(entity) \(node.name) \(bone)", "IK node '\(node.name)': no bone '\(bone)'")
            return nil
        }
        for node in nodes {
            let weight = animator.effectiveWeight(node)
            guard weight > 0 else { continue }
            var target = node.target
            if let name = node.targetEntity, !name.isEmpty, let e = state.entity(named: name, in: self) {
                target = Transform(matrix: worldMatrix(of: e)).position
            }
            switch node.type {
            case .twoBoneIK:
                guard node.bones.count == 3, let target else { continue }
                let bones = node.bones.compactMap { index($0, node) }
                guard bones.count == 3 else { continue }
                ik.twoBone(bones[0], bones[1], bones[2], target: target, pole: node.pole.map { rootWorld.rotation * $0 }, weight: weight)
            case .aim:
                guard let target else { continue }
                let chain = node.bones.compactMap { index($0, node) }
                guard chain.count == node.bones.count, !chain.isEmpty else { continue }
                ik.aim(chain, axis: node.aimAxis, target: target, weight: weight, maxAngle: max(node.maxAngle, 0) * .pi / 180)
            case .chainIK:
                guard let target else { continue }
                let chain = node.bones.compactMap { index($0, node) }
                guard chain.count == node.bones.count, chain.count >= 2 else { continue }
                ik.chain(chain, target: target, weight: weight, iterations: node.iterations, tolerance: node.tolerance)
            case .footPlacement:
                placeFeet(node, weight: weight, ik: &ik, root: entity, rootWorld: rootWorld, state: state, index: { index($0, node) })
            }
        }
        // Every bone a node may move is written, so one a node let go of (weight 0) returns to
        // the animation instead of keeping the last IK pose.
        for node in nodes {
            for bone in node.allBones {
                if let i = rig.names[bone], i < count { ik.pose.animated[i] = true }
            }
        }
        pose = ik.pose
    }

    private func placeFeet(_ node: AnimationIKNode, weight: Float, ik: inout IKPose, root: Entity, rootWorld: Transform, state: AnimationIKState,
                           index: (String) -> Int?) {
        guard let physics = attachedPhysics else { return }
        let up = Vec3(0, 1, 0)
        let baseY = rootWorld.position.y
        struct Leg { var bones: [Int]; var key: String; var lift: Float; var ground: Vec3?; var normal: Vec3 }
        var legs: [Leg] = []
        for (k, names) in node.legs.enumerated() where names.count == 3 {
            let bones = names.compactMap(index)
            guard bones.count == 3 else { continue }
            let foot = ik.globals[bones[2]].position
            let lift = foot.y - baseY
            var ground: Vec3?, normal = up
            let ray = Ray(origin: Vec3(foot.x, baseY + node.rayHeight, foot.z), direction: Vec3(0, -1, 0))
            for hit in physics.raycastAll(ray, maxDistance: node.rayHeight + node.maxStep, filter: QueryFilter(mask: node.mask)) {
                if let e = hit.entity, e == root || isDescendant(e, of: root) { continue }
                ground = hit.point
                normal = hit.normal.y > 0.2 ? normalize(hit.normal) : up
                break
            }
            legs.append(Leg(bones: bones, key: "\(node.name)/\(k)", lift: lift, ground: ground, normal: normal))
        }
        guard !legs.isEmpty else { return }
        // The pelvis drops so the lowest foot reaches its ground.
        let offsets = legs.compactMap { leg in leg.ground.map { $0.y - baseY } }
        if let pelvis = node.pelvis.flatMap(index), let lowest = offsets.min(), lowest < 0 {
            ik.move(pelvis, by: up * (max(lowest, -node.maxStep) * weight))
        }
        var locks = state.locks[root] ?? [:]
        var lows = state.lows[root] ?? [:]
        for leg in legs {
            guard let ground = leg.ground else {
                locks[leg.key] = nil
                continue
            }
            let foot = ik.globals[leg.bones[2]]
            var target = Vec3(foot.position.x, ground.y + max(leg.lift, 0), foot.position.z)
            let low = min(lows[leg.key] ?? leg.lift, leg.lift)
            lows[leg.key] = low
            if node.lockFeet {
                if leg.lift <= low + node.plantHeight {
                    if let lock = locks[leg.key], length(Vec3(lock.x - target.x, 0, lock.z - target.z)) < 0.25 {
                        target = Vec3(lock.x, target.y, lock.z)
                    } else {
                        locks[leg.key] = target
                    }
                } else {
                    locks[leg.key] = nil
                }
            }
            ik.twoBone(leg.bones[0], leg.bones[1], leg.bones[2], target: target, pole: node.pole.map { rootWorld.rotation * $0 }, weight: weight)
            if node.alignFeet, leg.normal != up {
                let tilt = IKSolver.partial(IKSolver.rotation(from: up, to: leg.normal), weight, maxAngle: 40 * .pi / 180)
                ik.setWorldRotation(leg.bones[2], (tilt * ik.globals[leg.bones[2]].rotation).normalized)
            }
        }
        state.locks[root] = locks
        state.lows[root] = lows
    }
}
