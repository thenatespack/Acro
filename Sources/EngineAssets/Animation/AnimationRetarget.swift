import Foundation
import EngineCore
import EngineScene

// Retargeting: playing a clip made for one skeleton on another whose nodes are laid out
// differently, by matching bones by name.
//
// A clip's channels address targets by index (`AnimationChannel.target`), so a clip only plays
// on a rig whose targets come in the same order. Imported glTF clips remember the skeleton they
// were made for (`AnimationClip.skeleton`: node names, parents and rest transforms, in target
// order). `retargeted(to:options:)` rewrites a clip for another skeleton:
//
// ```swift
// let walk = database.animationClip(AssetReference("asset:<id>#animation/Walk")!)!   // a glTF clip
// let onHero = walk.retargeted(to: CharacterRig(template: .humanoid).animationSkeleton,
//                              options: AnimationRetargetOptions(boneMap: AnimationRetargetOptions.mixamoHumanoid))
// ```
//
// Bones are paired by `boneMap` first (source name → target name), then by equal names, then by
// names equal once normalized (case, separators and prefixes such as `mixamorig:` ignored).
// `AnimationRetargetMap` reports which bones matched. Rotations are carried over relative to each
// skeleton's rest pose (`Rotation`), so rigs whose bones have different rest orientations still
// get the same motion; both rest poses should be alike (both T-poses, or both arms-down).
// An `Animator` with `retarget` set does this on the fly for every clip whose skeleton differs
// from its targets (EngineRendering's scene animation system).

/// The nodes an animation clip's targets index: names, parents and rest transforms.
public struct AnimationSkeleton: Codable, Equatable, Sendable {
    public struct Bone: Codable, Equatable, Sendable {
        public var name: String
        /// Index of the parent bone; nil for a root (or a bone whose parent isn't in the skeleton).
        public var parent: Int?
        /// Local transform in the rest pose.
        public var rest: Transform

        public init(name: String, parent: Int? = nil, rest: Transform = Transform()) {
            self.name = name
            self.parent = parent
            self.rest = rest
        }
    }

    public var bones: [Bone]

    public init(bones: [Bone]) { self.bones = bones }

    /// The node tree of a node-tree prefab (an imported glTF model), depth first with roots
    /// first: the numbering imported clips and `World.animationRig(of:)` use.
    public init(prefab: PrefabAsset) {
        var bones: [Bone] = []
        func visit(_ node: PrefabNode, parent: Int?) {
            let index = bones.count
            bones.append(Bone(name: node.name, parent: parent, rest: node.transform))
            for child in node.children { visit(child, parent: index) }
        }
        for root in prefab.roots { visit(root, parent: nil) }
        self.bones = bones
    }

    /// A read glTF model's nodes in file order (unnamed ones get "node<index>"): the targets of
    /// `ImportedModel.animations` before the importer renumbers them, so a clip read straight
    /// from a file can be retargeted (`AnimationClip.retargeted(from:to:options:)`).
    public init(model: ImportedModel) {
        self.bones = model.nodes.enumerated().map { i, node in
            Bone(name: node.name ?? "node\(i)", parent: node.parent, rest: node.transform)
        }
    }

    public var count: Int { bones.count }
    public var names: [String] { bones.map(\.name) }
    public var isEmpty: Bool { bones.isEmpty }

    /// The first bone named `name` exactly.
    public func index(of name: String) -> Int? { bones.firstIndex { $0.name == name } }

    /// Each bone's depth (0 for roots).
    public var depths: [Int] {
        var depths = [Int](repeating: -1, count: bones.count)
        func depth(_ i: Int, _ guardCount: Int = 0) -> Int {
            if depths[i] >= 0 { return depths[i] }
            guard let p = bones[i].parent, bones.indices.contains(p), p != i, guardCount < bones.count else { depths[i] = 0; return 0 }
            depths[i] = depth(p, guardCount + 1) + 1
            return depths[i]
        }
        for i in bones.indices { _ = depth(i) }
        return depths
    }

    /// `bone` and every bone below it.
    public func subtree(of bone: Int) -> [Int] {
        guard bones.indices.contains(bone) else { return [] }
        var children: [Int: [Int]] = [:]
        for (i, b) in bones.enumerated() { if let p = b.parent, p != i { children[p, default: []].append(i) } }
        var result: [Int] = [], stack = [bone], seen = Set<Int>()
        while let i = stack.popLast() {
            guard seen.insert(i).inserted else { continue }
            result.append(i)
            stack += (children[i] ?? []).reversed()
        }
        return result
    }

    /// Bone indices in an order where parents come before their children.
    var parentFirstOrder: [Int] {
        let depths = self.depths
        return bones.indices.sorted { depths[$0] < depths[$1] || depths[$0] == depths[$1] && $0 < $1 }
    }

    /// Each bone's model-space transform for local transforms `locals` (the rest pose when nil).
    public func modelTransforms(_ locals: [Transform]? = nil) -> [Transform] {
        var result = locals ?? bones.map(\.rest)
        let locals = result
        for i in parentFirstOrder {
            guard let p = bones[i].parent, bones.indices.contains(p), p != i else { continue }
            result[i] = Self.compose(result[p], locals[i])
        }
        return result
    }

    /// `parent` then `child` (uniform scale assumed for the rotation part).
    static func compose(_ parent: Transform, _ child: Transform) -> Transform {
        Transform(position: parent.position + parent.rotation * (parent.scale * child.position),
                  rotation: (parent.rotation * child.rotation).normalized, scale: parent.scale * child.scale)
    }

    /// `point` (model space) in the local space of a bone whose model transform is `parent`.
    static func localPoint(_ point: Vec3, in parent: Transform) -> Vec3 {
        let p = parent.rotation.conjugate * (point - parent.position)
        let s = parent.scale
        return Vec3(s.x != 0 ? p.x / s.x : p.x, s.y != 0 ? p.y / s.y : p.y, s.z != 0 ? p.z / s.z : p.z)
    }
}

/// How `AnimationClip.retargeted(to:options:)` pairs bones and carries motion over.
public struct AnimationRetargetOptions: Codable, Equatable, Hashable, Sendable {
    /// How rotations move from source bones to target bones.
    public enum Rotation: String, Codable, Sendable, CaseIterable {
        /// The source values as they are (for skeletons whose bones have the same rest orientations).
        case copy
        /// Each bone's rotation relative to its rest rotation, in its parent's frame
        /// (`target = source · sourceRest⁻¹ · targetRest`): exact per key, no resampling; right when
        /// matching parents have the same rest orientations.
        case local
        /// Each bone's rotation relative to its rest pose in model space, so bones with different
        /// rest orientations (and extra or missing bones in between) still move alike. The clip is
        /// resampled at `sampleRate`.
        case world
    }

    /// Which translation channels are kept.
    public enum Translation: String, Codable, Sendable, CaseIterable {
        /// None: every target bone keeps its rest position (bone lengths of the target rig).
        case none
        /// Only the root bone's (the matched bone nearest the root that has translation keys, e.g.
        /// the hips), as an offset from its rest position scaled by `rootScale`.
        case root
        /// Every matched bone's, as offsets from rest scaled by `rootScale`.
        case all
    }

    /// Source bone name → target bone name, checked before names are compared.
    public var boneMap: [String: String]
    /// Pair bones not in `boneMap` by name (exact, then normalized: case, separators, `prefix:`
    /// and `prefix|` ignored).
    public var matchNames: Bool
    public var rotation: Rotation
    public var translation: Translation
    /// Multiplies translation offsets; nil works it out from the root bones' rest heights.
    public var rootScale: Float?
    /// Samples per second when `rotation` is `world`.
    public var sampleRate: Float

    public init(boneMap: [String: String] = [:], matchNames: Bool = true, rotation: Rotation = .world, translation: Translation = .root,
                rootScale: Float? = nil, sampleRate: Float = 30) {
        self.boneMap = boneMap
        self.matchNames = matchNames
        self.rotation = rotation
        self.translation = translation
        self.rootScale = rootScale
        self.sampleRate = sampleRate
    }

    private enum CodingKeys: String, CodingKey { case boneMap, matchNames, rotation, translation, rootScale, sampleRate }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        boneMap = try c.decodeIfPresent([String: String].self, forKey: .boneMap) ?? [:]
        matchNames = try c.decodeIfPresent(Bool.self, forKey: .matchNames) ?? true
        rotation = try c.decodeIfPresent(Rotation.self, forKey: .rotation) ?? .world
        translation = try c.decodeIfPresent(Translation.self, forKey: .translation) ?? .root
        rootScale = try c.decodeIfPresent(Float.self, forKey: .rootScale)
        sampleRate = try c.decodeIfPresent(Float.self, forKey: .sampleRate) ?? 30
    }

    /// A bone name with case, separators and a `prefix:` / `prefix|` removed ("mixamorig:LeftArm" → "leftarm").
    public static func normalizedBoneName(_ name: String) -> String {
        var name = Substring(name)
        if let cut = name.lastIndex(where: { $0 == ":" || $0 == "|" }) { name = name[name.index(after: cut)...] }
        return String(name.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    /// Mixamo (and similar glTF humanoid) bone names → the Character Builder's humanoid bones.
    /// Names are compared normalized, so the `mixamorig:` prefix doesn't matter.
    public static let mixamoHumanoid: [String: String] = [
        "Hips": "hips", "Spine": "spine", "Spine1": "chest", "Spine2": "chest", "Neck": "neck", "Head": "head",
        "LeftArm": "upperArm.L", "LeftForeArm": "lowerArm.L", "LeftHand": "hand.L",
        "RightArm": "upperArm.R", "RightForeArm": "lowerArm.R", "RightHand": "hand.R",
        "LeftUpLeg": "upperLeg.L", "LeftLeg": "lowerLeg.L", "LeftFoot": "foot.L",
        "RightUpLeg": "upperLeg.R", "RightLeg": "lowerLeg.R", "RightFoot": "foot.R",
    ]
}

/// Which source bone drives each target bone, for `AnimationRetargetOptions`.
public struct AnimationRetargetMap: Equatable, Sendable {
    /// Per target bone, the source bone driving it.
    public var sourceOfTarget: [Int?]
    /// Target bone names nothing drives.
    public var unmatchedTargets: [String] { zip(target.bones, sourceOfTarget).filter { $0.1 == nil }.map(\.0.name) }
    /// Source bone names that drive nothing.
    public var unmatchedSources: [String] {
        let used = Set(sourceOfTarget.compactMap { $0 })
        return source.bones.indices.filter { !used.contains($0) }.map { source.bones[$0].name }
    }
    public var matchedCount: Int { sourceOfTarget.lazy.filter { $0 != nil }.count }
    public let source: AnimationSkeleton
    public let target: AnimationSkeleton

    public init(source: AnimationSkeleton, target: AnimationSkeleton, options: AnimationRetargetOptions = AnimationRetargetOptions()) {
        self.source = source
        self.target = target
        var exact: [String: Int] = [:], normalized: [String: Int] = [:]
        for (i, bone) in target.bones.enumerated() {
            if exact[bone.name] == nil { exact[bone.name] = i }
            let n = AnimationRetargetOptions.normalizedBoneName(bone.name)
            if normalized[n] == nil { normalized[n] = i }
        }
        var mapNormalized: [String: String] = [:]
        for (from, to) in options.boneMap { mapNormalized[AnimationRetargetOptions.normalizedBoneName(from)] = to }
        func find(_ name: String) -> Int? { exact[name] ?? normalized[AnimationRetargetOptions.normalizedBoneName(name)] }
        var result = [Int?](repeating: nil, count: target.count)
        // Mapped bones first, so a mapping wins over a name that happens to match.
        for pass in 0..<2 {
            for (s, bone) in source.bones.enumerated() {
                let mapped = options.boneMap[bone.name] ?? mapNormalized[AnimationRetargetOptions.normalizedBoneName(bone.name)]
                let t: Int?
                if pass == 0 { t = mapped.flatMap(find) } else { t = mapped == nil && options.matchNames ? find(bone.name) : nil }
                if let t, result[t] == nil { result[t] = s }
            }
        }
        sourceOfTarget = result
    }
}

extension AnimationClip {
    /// This clip rewritten for `target`'s bones (see the notes at the top of this file), with
    /// `skeleton` (the clip's own) as the source. A clip without a skeleton is returned as it is.
    public func retargeted(to target: AnimationSkeleton, options: AnimationRetargetOptions = AnimationRetargetOptions()) -> AnimationClip {
        guard let skeleton else { return self }
        return retargeted(from: skeleton, to: target, options: options)
    }

    /// This clip, made for `source`'s bones (channel targets index it), rewritten for `target`'s.
    /// Channels of bones with no match are dropped; events and duration are kept.
    public func retargeted(from source: AnimationSkeleton, to target: AnimationSkeleton,
                           options: AnimationRetargetOptions = AnimationRetargetOptions()) -> AnimationClip {
        AnimationRetargeter(clip: self, map: AnimationRetargetMap(source: source, target: target, options: options), options: options).run()
    }
}

/// The retargeting work of `AnimationClip.retargeted`.
private struct AnimationRetargeter {
    let clip: AnimationClip
    let map: AnimationRetargetMap
    let options: AnimationRetargetOptions
    var source: AnimationSkeleton { map.source }
    var target: AnimationSkeleton { map.target }

    /// Channels by source bone and path.
    var channels: [Int: [AnimationPath: AnimationChannel]] = [:]

    init(clip: AnimationClip, map: AnimationRetargetMap, options: AnimationRetargetOptions) {
        self.clip = clip
        self.map = map
        self.options = options
        for channel in clip.channels where source.bones.indices.contains(channel.target) {
            channels[channel.target, default: [:]][channel.path] = channel
        }
    }

    /// The target bone whose translation `Translation.root` keeps.
    var rootTarget: Int? {
        let depths = target.depths
        return target.bones.indices
            .filter { t in map.sourceOfTarget[t].map { channels[$0]?[.translation] != nil } ?? false }
            .min { depths[$0] < depths[$1] || depths[$0] == depths[$1] && $0 < $1 }
    }

    /// The translation scale: given, or the ratio of the root bones' rest heights.
    func translationScale(root: Int?) -> Float {
        if let given = options.rootScale { return given }
        guard let root, let s = map.sourceOfTarget[root] else { return 1 }
        if options.rotation == .world {
            let ts = target.modelTransforms()[root].position.y, ss = source.modelTransforms()[s].position.y
            return abs(ss) > 1e-5 && abs(ts) > 1e-5 ? abs(ts / ss) : 1
        }
        let ts = length(target.bones[root].rest.position), ss = length(source.bones[s].rest.position)
        return ss > 1e-5 && ts > 1e-5 ? ts / ss : 1
    }

    func keepsTranslation(_ t: Int, root: Int?) -> Bool {
        switch options.translation {
        case .none: false
        case .root: t == root
        case .all: true
        }
    }

    func run() -> AnimationClip {
        let root = rootTarget
        let scale = translationScale(root: root)
        var out: [AnimationChannel] = []
        if options.rotation == .world {
            out = baked(root: root, scale: scale)
        } else {
            for t in target.bones.indices {
                guard let s = map.sourceOfTarget[t], let bySource = channels[s] else { continue }
                let sourceRest = source.bones[s].rest, targetRest = target.bones[t].rest
                if var channel = bySource[.rotation] {
                    channel.target = t
                    if options.rotation == .local {
                        // Right-multiplying by a constant keeps slerp and spline tangents valid.
                        let c = (sourceRest.rotation.conjugate * targetRest.rotation).normalized
                        channel.sampler.values = Self.mapQuats(channel.sampler.values) { $0 * c }
                    }
                    out.append(channel)
                }
                if keepsTranslation(t, root: root), var channel = bySource[.translation] {
                    channel.target = t
                    if options.rotation == .local || scale != 1 {
                        let cubic = channel.sampler.interpolation == .cubicSpline
                        channel.sampler.values = Self.mapVec3s(channel.sampler.values) { i, v in
                            // Spline tangents only scale; values become offsets from the rest positions.
                            if cubic && i % 3 != 1 { return v * scale }
                            return options.rotation == .copy ? v * scale : targetRest.position + (v - sourceRest.position) * scale
                        }
                    }
                    out.append(channel)
                }
                if options.rotation == .copy, var channel = bySource[.scale] {
                    channel.target = t
                    out.append(channel)
                }
            }
        }
        var result = AnimationClip(name: clip.name, channels: out, duration: clip.duration, events: clip.events)
        result.skeleton = target
        return result
    }

    /// `.world`: samples the source pose over time and solves each matched target bone's local
    /// rotation (and the kept translations) from model-space offsets to the rest poses.
    func baked(root: Int?, scale: Float) -> [AnimationChannel] {
        let duration = max(clip.duration, 0)
        let rate = max(options.sampleRate, 1)
        let steps = max(Int((duration * rate).rounded(.up)), 1)
        var times = (0...steps).map { min(Float($0) / rate, duration) }
        if duration == 0 { times = [0] }
        let sourceRestModel = source.modelTransforms(), targetRestModel = target.modelTransforms()
        let order = target.parentFirstOrder
        let matched = target.bones.indices.filter { map.sourceOfTarget[$0] != nil }
        var rotations: [Int: [Float]] = [:], translations: [Int: [Float]] = [:]
        var lastQuat: [Int: Vec4] = [:]
        for time in times {
            var pose = AnimationPose(source.bones.map(\.rest))
            clip.sample(at: time, into: &pose)
            let sourceModel = source.modelTransforms(pose.transforms)
            var locals = target.bones.map(\.rest)
            var model = locals
            for t in order {
                let parent = target.bones[t].parent.flatMap { target.bones.indices.contains($0) && $0 != t ? model[$0] : nil }
                if let s = map.sourceOfTarget[t] {
                    let delta = sourceModel[s].rotation * sourceRestModel[s].rotation.conjugate
                    let world = (delta * targetRestModel[t].rotation).normalized
                    locals[t].rotation = ((parent?.rotation.conjugate ?? .identity) * world).normalized
                    if keepsTranslation(t, root: root), channels[s]?[.translation] != nil {
                        if t == root {
                            let offset = (sourceModel[s].position - sourceRestModel[s].position) * scale
                            let goal = targetRestModel[t].position + offset
                            locals[t].position = parent.map { AnimationSkeleton.localPoint(goal, in: $0) } ?? goal
                        } else {
                            locals[t].position = target.bones[t].rest.position + (pose.transforms[s].position - source.bones[s].rest.position) * scale
                        }
                    }
                }
                model[t] = parent.map { AnimationSkeleton.compose($0, locals[t]) } ?? locals[t]
            }
            for t in matched {
                var q = locals[t].rotation.vector
                if let last = lastQuat[t], (last * q).sum() < 0 { q = -q }
                lastQuat[t] = q
                rotations[t, default: []] += [q.x, q.y, q.z, q.w]
                if let s = map.sourceOfTarget[t], keepsTranslation(t, root: root), channels[s]?[.translation] != nil {
                    let p = locals[t].position
                    translations[t, default: []] += [p.x, p.y, p.z]
                }
            }
        }
        var out: [AnimationChannel] = []
        for t in matched {
            // Bones the source never animates (directly or through a parent) keep their rest pose.
            if let values = rotations[t], !Self.isConstant(values, stride: 4, equalTo: target.bones[t].rest.rotation.vector) {
                out.append(AnimationChannel(target: t, path: .rotation, sampler: AnimationSampler(times: times, values: values)))
            }
            if let values = translations[t] {
                out.append(AnimationChannel(target: t, path: .translation, sampler: AnimationSampler(times: times, values: values)))
            }
        }
        return out
    }

    static func isConstant(_ values: [Float], stride: Int, equalTo rest: Vec4) -> Bool {
        var i = 0
        while i + stride <= values.count {
            let q = Vec4(values[i], values[i + 1], values[i + 2], values[i + 3])
            if abs((q * rest).sum()) < 0.99999 { return false }
            i += stride
        }
        return true
    }

    static func mapQuats(_ values: [Float], _ f: (Quat) -> Quat) -> [Float] {
        var out = values
        var i = 0
        while i + 4 <= values.count {
            let q = f(Quat(values[i], values[i + 1], values[i + 2], values[i + 3]))
            out[i] = q.x; out[i + 1] = q.y; out[i + 2] = q.z; out[i + 3] = q.w
            i += 4
        }
        return out
    }

    /// `f(index, value)` over the 3-vectors of `values`.
    static func mapVec3s(_ values: [Float], _ f: (Int, Vec3) -> Vec3) -> [Float] {
        var out = values
        var i = 0
        while i + 3 <= values.count {
            let v = f(i / 3, Vec3(values[i], values[i + 1], values[i + 2]))
            out[i] = v.x; out[i + 1] = v.y; out[i + 2] = v.z
            i += 3
        }
        return out
    }
}

extension CharacterRig {
    /// The rig's bones as a skeleton (in bone order, the targets of the character's clips), for
    /// retargeting clips onto a character (`AnimationClip.retargeted(to:options:)`).
    public var animationSkeleton: AnimationSkeleton {
        AnimationSkeleton(bones: bones.map { AnimationSkeleton.Bone(name: $0.name, parent: $0.parent, rest: Transform(position: $0.offset)) })
    }
}
