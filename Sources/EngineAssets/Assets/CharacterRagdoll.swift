import Foundation
import EngineCore
import EnginePhysics
import EngineScene

// The `.character` file's `ragdoll` and `ik` sections (Character Builder):
//
// ```json
// "ragdoll": {"mass": 80, "bones": [{"bone": "lowerLeg.L", "maxAngle": 120}, {"bone": "head", "radius": 0.12}]},
// "ik": {"footPlacement": true, "lookAt": true, "lookTarget": "Player", "handIK": true}
// ```
//
// The ragdoll's bodies are sized from the template's body shapes (`CharacterRig.ragdollBones`);
// `bones` overrides single values by bone name. The importer puts a `Ragdoll` on the prefab's
// root and the IK nodes (`CharacterRig.ikNodes`) on its `Animator`.

/// Changes to one automatic ragdoll body (every key optional).
public struct CharacterRagdollBone: Codable, Equatable, Sendable {
    public var bone: String
    public var radius: Float?
    public var swing: Float?
    public var minAngle: Float?
    public var maxAngle: Float?
    public var mass: Float?

    public init(bone: String, radius: Float? = nil, swing: Float? = nil, minAngle: Float? = nil, maxAngle: Float? = nil, mass: Float? = nil) {
        self.bone = bone
        self.radius = radius
        self.swing = swing
        self.minAngle = minAngle
        self.maxAngle = maxAngle
        self.mass = mass
    }

    private enum CodingKeys: String, CodingKey { case bone, radius, swing, minAngle, maxAngle, mass }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bone = try c.decodeIfPresent(String.self, forKey: .bone) ?? ""
        radius = try c.decodeIfPresent(Float.self, forKey: .radius)
        swing = try c.decodeIfPresent(Float.self, forKey: .swing)
        minAngle = try c.decodeIfPresent(Float.self, forKey: .minAngle)
        maxAngle = try c.decodeIfPresent(Float.self, forKey: .maxAngle)
        mass = try c.decodeIfPresent(Float.self, forKey: .mass)
    }

    /// Whether it changes nothing.
    public var isEmpty: Bool { radius == nil && swing == nil && minAngle == nil && maxAngle == nil && mass == nil }
}

/// A character's ragdoll: automatic bodies with per-bone changes.
public struct CharacterRagdoll: Codable, Equatable, Sendable {
    /// Off keeps the settings but leaves the `Ragdoll` out of the prefab.
    public var enabled: Bool
    /// Total kg; nil: the template's (`CharacterRig.ragdollMass`).
    public var mass: Float?
    /// Partial ragdoll pull toward the animation (1/s) and seconds to blend back (nil: defaults).
    public var strength: Float?
    public var blendTime: Float?
    public var bones: [CharacterRagdollBone]

    public init(enabled: Bool = true, mass: Float? = nil, strength: Float? = nil, blendTime: Float? = nil, bones: [CharacterRagdollBone] = []) {
        self.enabled = enabled
        self.mass = mass
        self.strength = strength
        self.blendTime = blendTime
        self.bones = bones
    }

    private enum CodingKeys: String, CodingKey { case enabled, mass, strength, blendTime, bones }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        mass = try c.decodeIfPresent(Float.self, forKey: .mass)
        strength = try c.decodeIfPresent(Float.self, forKey: .strength)
        blendTime = try c.decodeIfPresent(Float.self, forKey: .blendTime)
        bones = try c.decodeIfPresent([CharacterRagdollBone].self, forKey: .bones) ?? []
    }

    /// The change for `bone`, if any.
    public func override(_ bone: String) -> CharacterRagdollBone? { bones.first { $0.bone == bone } }
}

/// A character's IK nodes, made for its template's bones.
public struct CharacterIK: Codable, Equatable, Sendable {
    /// Feet follow the ground (rays against physics), the pelvis drops, planted feet lock.
    public var footPlacement: Bool
    /// The head (and chest) turn toward `lookTarget` or a target set at run time ("Look").
    public var lookAt: Bool
    /// The `Name` of the entity to look at.
    public var lookTarget: String?
    /// Arms reach targets set at run time ("Hand.L", "Hand.R"; two-bone IK).
    public var handIK: Bool

    public init(footPlacement: Bool = true, lookAt: Bool = false, lookTarget: String? = nil, handIK: Bool = false) {
        self.footPlacement = footPlacement
        self.lookAt = lookAt
        self.lookTarget = lookTarget
        self.handIK = handIK
    }

    private enum CodingKeys: String, CodingKey { case footPlacement, lookAt, lookTarget, handIK }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        footPlacement = try c.decodeIfPresent(Bool.self, forKey: .footPlacement) ?? true
        lookAt = try c.decodeIfPresent(Bool.self, forKey: .lookAt) ?? false
        lookTarget = try c.decodeIfPresent(String.self, forKey: .lookTarget)
        handIK = try c.decodeIfPresent(Bool.self, forKey: .handIK) ?? false
    }
}

extension CharacterRig {
    /// A template's default total mass, kg (scaled by height cubed).
    public var ragdollMass: Float {
        let base: Float
        switch template {
        case .humanoid: base = 70
        case .quadruped: base = 35
        case .bird: base = 4
        case .blob: base = 25
        }
        let s = proportions.height
        return base * s * s * s * proportions.width * proportions.width
    }

    /// The radius of `bone`'s main body shape (its first capsule, cylinder or sphere), meters.
    private func shapeRadius(_ bone: String) -> Float? {
        guard let i = index(of: bone) else { return nil }
        let shapes: [MeshBuildShape] = [.capsule, .cylinder, .sphere]
        guard let segment = segments.first(where: { $0.bone == i && shapes.contains($0.shape) }) else { return nil }
        return min(segment.radius.x, segment.radius.y)
    }

    /// How far `bone`'s main shape reaches above the bone along +Y, meters.
    private func shapeTop(_ bone: String) -> Float {
        guard let i = index(of: bone), let segment = segments.first(where: { $0.bone == i }) else { return 0.1 }
        return max(max(segment.from.y, segment.to.y) - bones[i].position.y, 0.02)
    }

    /// The automatic ragdoll: capsules sized from the body shapes, ball joints at shoulders,
    /// hips, spine and neck, hinges at elbows and knees, then `ragdoll`'s per-bone changes.
    public func ragdollBones(_ ragdoll: CharacterRagdoll? = nil) -> [RagdollBone] {
        let s = proportions.height
        func radius(_ bone: String, _ fallback: Float) -> Float { shapeRadius(bone) ?? fallback * s }
        func ball(_ bone: String, end: String? = nil, length: Float = 0, r: Float, swing: Float, twist: Float) -> RagdollBone {
            RagdollBone(bone: bone, end: end, length: length, radius: r, joint: .ball, swing: swing, minAngle: -twist, maxAngle: twist)
        }
        func hinge(_ bone: String, end: String, r: Float, min: Float, max: Float) -> RagdollBone {
            RagdollBone(bone: bone, end: end, radius: r, joint: .hinge, axis: Vec3(1, 0, 0), minAngle: min, maxAngle: max)
        }
        var list: [RagdollBone] = []
        switch template {
        case .humanoid:
            list.append(ball("hips", end: "spine", r: radius("hips", 0.1), swing: 0, twist: 0))
            list.append(ball("spine", end: "neck", r: radius("spine", 0.1), swing: 30, twist: 25))
            list.append(ball("head", length: shapeTop("head") * 0.85, r: radius("head", 0.1) * 0.9, swing: 40, twist: 50))
            for side in ["L", "R"] {
                list.append(ball("upperArm.\(side)", end: "lowerArm.\(side)", r: radius("upperArm.\(side)", 0.05), swing: 80, twist: 45))
                list.append(hinge("lowerArm.\(side)", end: "hand.\(side)", r: radius("lowerArm.\(side)", 0.045), min: -140, max: 5))
                list.append(ball("upperLeg.\(side)", end: "lowerLeg.\(side)", r: radius("upperLeg.\(side)", 0.07), swing: 60, twist: 25))
                list.append(hinge("lowerLeg.\(side)", end: "foot.\(side)", r: radius("lowerLeg.\(side)", 0.055), min: -5, max: 140))
            }
        case .quadruped:
            list.append(ball("hips", end: "spine", r: radius("hips", 0.1), swing: 0, twist: 0))
            list.append(ball("spine", end: "neck", r: radius("spine", 0.1), swing: 25, twist: 20))
            list.append(ball("head", length: shapeTop("head"), r: radius("head", 0.07), swing: 45, twist: 40))
            list.append(ball("tail", end: "tailTip", r: radius("tail", 0.03), swing: 60, twist: 20))
            for side in ["L", "R"] {
                for prefix in ["front", "back"] {
                    list.append(ball("\(prefix)Upper.\(side)", end: "\(prefix)Lower.\(side)", r: radius("\(prefix)Upper.\(side)", 0.05), swing: 50, twist: 15))
                    list.append(hinge("\(prefix)Lower.\(side)", end: "\(prefix)Foot.\(side)", r: radius("\(prefix)Lower.\(side)", 0.04),
                                      min: prefix == "front" ? -120 : -5, max: prefix == "front" ? 5 : 120))
                }
            }
        case .bird:
            list.append(ball("body", r: radius("body", 0.12), swing: 0, twist: 0))
            list.append(ball("neck", end: "head", r: radius("neck", 0.05), swing: 50, twist: 40))
            list.append(ball("head", r: radius("head", 0.07), swing: 40, twist: 40))
            for side in ["L", "R"] {
                list.append(ball("wing.\(side)", end: "wingTip.\(side)", r: radius("wing.\(side)", 0.02), swing: 70, twist: 30))
                list.append(ball("leg.\(side)", end: "shin.\(side)", r: radius("leg.\(side)", 0.035), swing: 50, twist: 15))
                list.append(hinge("shin.\(side)", end: "foot.\(side)", r: max(radius("shin.\(side)", 0.015), 0.015 * s), min: -5, max: 120))
            }
        case .blob:
            list.append(ball("body", end: "top", r: radius("body", 0.3) * 0.9, swing: 0, twist: 0))
            for side in ["L", "R"] {
                list.append(ball("arm.\(side)", r: radius("arm.\(side)", 0.05), swing: 50, twist: 30))
            }
        }
        list.removeAll { index(of: $0.bone) == nil }
        guard let ragdoll else { return list }
        for i in list.indices {
            guard let o = ragdoll.override(list[i].bone) else { continue }
            if let v = o.radius { list[i].radius = max(v, 0.005) }
            if let v = o.swing { list[i].swing = v }
            if let v = o.minAngle { list[i].minAngle = v }
            if let v = o.maxAngle { list[i].maxAngle = v }
            if let v = o.mass { list[i].mass = max(v, 0.01) }
        }
        return list
    }

    /// The `Ragdoll` component for `ragdoll`'s settings.
    public func ragdoll(_ ragdoll: CharacterRagdoll) -> Ragdoll {
        var component = Ragdoll(bones: ragdollBones(ragdoll), mass: ragdoll.mass ?? ragdollMass)
        if let v = ragdoll.strength { component.strength = max(v, 0) }
        if let v = ragdoll.blendTime { component.blendTime = max(v, 0) }
        return component
    }

    /// The bones that turn to look ("Look"), root to tip.
    public var lookBones: [String] {
        switch template {
        case .humanoid: ["spine", "chest", "neck", "head"]
        case .quadruped, .bird: ["neck", "head"]
        case .blob: ["body"]
        }
    }

    /// The legs foot placement moves ([hip, knee, ankle] each) and the bone that drops.
    public var ikLegs: (legs: [[String]], pelvis: String)? {
        switch template {
        case .humanoid: (["L", "R"].map { ["upperLeg.\($0)", "lowerLeg.\($0)", "foot.\($0)"] }, "hips")
        case .quadruped: (["front", "back"].flatMap { p in ["L", "R"].map { ["\(p)Upper.\($0)", "\(p)Lower.\($0)", "\(p)Foot.\($0)"] } }, "hips")
        case .bird: (["L", "R"].map { ["leg.\($0)", "shin.\($0)", "foot.\($0)"] }, "body")
        case .blob: nil
        }
    }

    /// The arms hand IK moves ([shoulder, elbow, hand] each, named "Hand.L" / "Hand.R").
    public var ikArms: [(name: String, bones: [String])] {
        switch template {
        case .humanoid: ["L", "R"].map { ("Hand.\($0)", ["upperArm.\($0)", "lowerArm.\($0)", "hand.\($0)"]) }
        default: []
        }
    }

    /// The `Animator.ik` nodes for `ik`'s switches.
    public func ikNodes(_ ik: CharacterIK) -> [AnimationIKNode] {
        var nodes: [AnimationIKNode] = []
        if ik.footPlacement, let legs = ikLegs {
            let knee: Vec3 = template == .bird ? Vec3(0, 0, -1) : Vec3(0, 0, 1)
            nodes.append(AnimationIKNode(name: "Feet", type: .footPlacement, pole: knee, legs: legs.legs, pelvis: legs.pelvis,
                                         rayHeight: 0.6 * proportions.height * proportions.legs, maxStep: 0.45 * proportions.height * proportions.legs))
        }
        if ik.lookAt {
            nodes.append(AnimationIKNode(name: "Look", type: .aim, bones: lookBones, targetEntity: ik.lookTarget, maxAngle: 35))
        }
        if ik.handIK {
            for arm in ikArms {
                nodes.append(AnimationIKNode(name: arm.name, type: .twoBoneIK, bones: arm.bones, pole: Vec3(0, 0, -1)))
            }
        }
        return nodes
    }
}
