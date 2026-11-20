import EditorCore
import Engine
import Foundation

// The Character Builder's ragdoll and IK tools: `character.ragdoll` and `character.ik`.

/// One ragdoll body as the tools list it.
public struct CharacterRagdollBodyInfo: Codable, Equatable, Sendable {
    public var bone: String
    /// The bone the capsule ends at (nil: `length` along the bone).
    public var end: String?
    public var length: Float?
    public var radius: Float
    /// The body it hangs from (nil: the root body).
    public var parent: String?
    public var joint: JointKind
    /// Degrees.
    public var swing: Float?
    public var minAngle: Float
    public var maxAngle: Float
    /// kg (its own, or its share of the total by volume).
    public var mass: Float
    /// Whether the file changes this body (the rest is automatic).
    public var edited: Bool
}

/// What `character.ragdoll` returns.
public struct CharacterRagdollResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The file's ragdoll settings (nil: the character has none).
    public var ragdoll: CharacterRagdoll?
    public var enabled: Bool
    /// Total kg.
    public var mass: Float
    public var bodies: [CharacterRagdollBodyInfo]
    public var warnings: [String]
    /// Whether the Character Builder's preview went limp (`test`).
    public var tested: Bool?
}

/// What `character.ik` returns.
public struct CharacterIKResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The file's IK switches (nil: none).
    public var ik: CharacterIK?
    /// The Animator's IK nodes the importer makes from them (names for setIKTarget / ik.setTarget).
    public var nodes: [AnimationIKNode]
    public var warnings: [String]
}

extension CharacterRig {
    /// The ragdoll bodies with masses, as the tools list them.
    @MainActor func ragdollBodyInfo(_ ragdoll: CharacterRagdoll?) -> [CharacterRagdollBodyInfo] {
        let component = self.ragdoll(ragdoll ?? CharacterRagdoll())
        let bones = component.bones
        let world = World()
        let root = world.spawn(Transform(), Name("root"))
        var entities: [Entity] = []
        for bone in self.bones {
            let e = world.spawn(Transform(position: bone.offset), Name(bone.name))
            _ = world.setParent(e, to: bone.parent.map { entities[$0] } ?? root)
            entities.append(e)
        }
        // The masses as built (volume shares), from a scratch physics world.
        let physics = PhysicsWorld()
        world.add(component, to: root)
        physics.updateRagdolls(in: world, dt: 1.0 / 60.0)
        let layout = physics.ragdollLayout(of: root)
        return bones.map { bone in
            let built = layout.first { $0.bone == bone.bone }
            return CharacterRagdollBodyInfo(bone: bone.bone, end: bone.end, length: bone.end == nil ? bone.length : nil, radius: bone.radius,
                                            parent: built?.parent, joint: bone.joint, swing: bone.joint == .ball ? bone.swing : nil,
                                            minAngle: bone.minAngle, maxAngle: bone.maxAngle,
                                            mass: built?.mass ?? 0,
                                            edited: ragdoll?.override(bone.bone).map { !$0.isEmpty } ?? false)
        }
    }
}

public enum CharacterRagdollCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Turn the ragdoll on (adds the section with automatic bodies) or off (keeps the settings).
        public var enabled: Bool?
        /// Total kg (0 or less: the template's automatic mass).
        public var mass: Float?
        /// Partial ragdoll pull toward the animation (1/s).
        public var strength: Float?
        /// Seconds to blend back to the animation after going limp.
        public var blendTime: Float?
        /// Per-bone changes merged into the file's: {bone, radius, swing, minAngle, maxAngle (degrees), mass}.
        public var bones: [CharacterRagdollBone]?
        /// Bones whose changes to drop (back to automatic).
        public var resetBones: [String]?
        /// Remove the ragdoll section entirely.
        public var remove: Bool?
        /// Open the character in the Character Builder and drop its preview as a ragdoll (true) or stand it up (false).
        public var test: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, enabled: Bool? = nil, mass: Float? = nil, strength: Float? = nil,
                    blendTime: Float? = nil, bones: [CharacterRagdollBone]? = nil, resetBones: [String]? = nil, remove: Bool? = nil,
                    test: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.enabled = enabled
            self.mass = mass
            self.strength = strength
            self.blendTime = blendTime
            self.bones = bones
            self.resetBones = resetBones
            self.remove = remove
            self.test = test
        }

        var changesFile: Bool { enabled != nil || mass != nil || strength != nil || blendTime != nil || bones != nil || resetBones != nil || remove != nil }
    }

    public static let id: CommandID = "character.ragdoll"
    public static let title = "Character Ragdoll"
    public static let doc = "Reads or changes a .character file's ragdoll: capsule bodies sized automatically from the body shapes (humanoid: hips, spine, head, upper and lower arms and legs), ball joints with swing and twist limits at shoulders, hips, spine and neck, hinges at elbows and knees. With no changes it lists the bodies (bone, end bone, radius, parent, joint, limits in degrees, mass). `enabled` adds or switches it, `bones` merges per-bone changes {bone, radius, swing, minAngle, maxAngle, mass}, `resetBones` drops them, `remove` deletes the section; one undo step. The prefab gets a Ragdoll component: Visual Script ragdoll.enable / ragdoll.applyImpulse or Ragdoll.goLimp / hit / getUp in code. `test` opens the Character Builder and drops the preview (false stands it up)."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterRagdollResult {
        let (id, original) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let character = try edited(original, with: arguments)
        var warnings: [String] = []
        if arguments.changesFile {
            warnings = try session.commands.require(session.applyCharacter(character, to: id, label: title), title)
        }
        var tested: Bool?
        if let test = arguments.test {
            session.openCharacter = id
            session.onOpenCharacter?(id)
            tested = CharacterBuilderWorkspace.active(for: session)?.testRagdoll(test)
            if tested == nil { warnings.append("test: the Character Builder isn't open (it needs the editor window)") }
        }
        let rig = character.rig
        for problem in character.problems where problem.hasPrefix("ragdoll") && !warnings.contains(problem) { warnings.append(problem) }
        return CharacterRagdollResult(asset: id, path: session.assets?.path(of: id) ?? "", ragdoll: character.ragdoll,
                                      enabled: character.ragdoll?.enabled ?? false, mass: character.ragdoll?.mass ?? rig.ragdollMass,
                                      bodies: rig.ragdollBodyInfo(character.ragdoll), warnings: warnings, tested: tested)
    }

    /// `character` with the ragdoll changes of `arguments` (pure, for tests and the UI).
    public static func edited(_ character: CharacterBuild, with arguments: Arguments) throws -> CharacterBuild {
        var c = character
        if arguments.remove == true {
            c.ragdoll = nil
            return c
        }
        guard arguments.changesFile else { return c }
        var ragdoll = c.ragdoll ?? CharacterRagdoll()
        if let enabled = arguments.enabled { ragdoll.enabled = enabled }
        if let mass = arguments.mass {
            guard mass.isFinite else { throw CommandError.failed("mass must be a number") }
            ragdoll.mass = mass > 0 ? mass : nil
        }
        if let v = arguments.strength { ragdoll.strength = max(v, 0) }
        if let v = arguments.blendTime { ragdoll.blendTime = max(v, 0) }
        let bodies = Set(c.rig.ragdollBones().map(\.bone))
        for name in arguments.resetBones ?? [] { ragdoll.bones.removeAll { $0.bone == name } }
        for change in arguments.bones ?? [] {
            guard bodies.contains(change.bone) else {
                throw CommandError.failed("No ragdoll body for bone '\(change.bone)' (bodies: \(c.rig.ragdollBones().map(\.bone).joined(separator: ", ")))")
            }
            if let r = change.radius, !(r > 0) { throw CommandError.failed("bones '\(change.bone)': radius must be above 0") }
            var merged = ragdoll.override(change.bone) ?? CharacterRagdollBone(bone: change.bone)
            if let v = change.radius { merged.radius = v }
            if let v = change.swing { merged.swing = min(max(v, 0), 180) }
            if let v = change.minAngle { merged.minAngle = min(max(v, -180), 180) }
            if let v = change.maxAngle { merged.maxAngle = min(max(v, -180), 180) }
            if let v = change.mass { merged.mass = v > 0 ? v : nil }
            ragdoll.bones.removeAll { $0.bone == change.bone }
            if !merged.isEmpty { ragdoll.bones.append(merged) }
        }
        c.ragdoll = ragdoll
        return c
    }
}

public enum CharacterIKCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Feet follow uneven ground (ray casts against physics), the pelvis drops, planted feet lock.
        public var footPlacement: Bool?
        /// The head and chest turn toward `lookTarget` (or a target set at run time).
        public var lookAt: Bool?
        /// The Name of the entity to look at ("" clears it).
        public var lookTarget: String?
        /// Arms reach run-time targets ("Hand.L", "Hand.R").
        public var handIK: Bool?
        /// Remove the IK section.
        public var remove: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, footPlacement: Bool? = nil, lookAt: Bool? = nil, lookTarget: String? = nil,
                    handIK: Bool? = nil, remove: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.footPlacement = footPlacement
            self.lookAt = lookAt
            self.lookTarget = lookTarget
            self.handIK = handIK
            self.remove = remove
        }

        var changesFile: Bool { footPlacement != nil || lookAt != nil || lookTarget != nil || handIK != nil || remove != nil }
    }

    public static let id: CommandID = "character.ik"
    public static let title = "Character IK"
    public static let doc = "Reads or changes a .character file's inverse kinematics, which the importer turns into Animator IK nodes run after the animation: `footPlacement` (node \"Feet\": rays against physics find the ground under each foot, the pelvis drops, feet turn to the slope and planted feet lock), `lookAt` (node \"Look\": the spine, chest, neck and head turn toward the entity named `lookTarget`, or a point set at run time), `handIK` (humanoids, nodes \"Hand.L\" / \"Hand.R\": two-bone arms reach points set at run time). Returns the nodes. Set targets and weights at run time with the Visual Script nodes ik.setTarget / ik.setWeight or Animator.setIKTarget / setIKWeight. One undo step."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterIKResult {
        let (id, original) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let character = edited(original, with: arguments)
        var warnings: [String] = []
        if arguments.changesFile {
            warnings = try session.commands.require(session.applyCharacter(character, to: id, label: title), title)
        }
        for problem in character.problems where problem.hasPrefix("ik") && !warnings.contains(problem) { warnings.append(problem) }
        return CharacterIKResult(asset: id, path: session.assets?.path(of: id) ?? "", ik: character.ik,
                                 nodes: character.ik.map { character.rig.ikNodes($0) } ?? [], warnings: warnings)
    }

    /// `character` with the IK changes of `arguments` (pure).
    public static func edited(_ character: CharacterBuild, with arguments: Arguments) -> CharacterBuild {
        var c = character
        if arguments.remove == true {
            c.ik = nil
            return c
        }
        guard arguments.changesFile else { return c }
        var ik = c.ik ?? CharacterIK(footPlacement: false)
        if let v = arguments.footPlacement { ik.footPlacement = v }
        if let v = arguments.lookAt { ik.lookAt = v }
        if let v = arguments.lookTarget { ik.lookTarget = v.isEmpty ? nil : v }
        if let v = arguments.handIK { ik.handIK = v }
        c.ik = ik
        return c
    }
}
