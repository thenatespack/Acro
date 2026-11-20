import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// A rigged character assembled from a body template: the contents of a `.character` file (JSON,
// every key optional). `CharacterImporter` turns it into a skinned prefab with an `Animator`
// and the template's stock clips (idle, walk, run, jump, attack, die) as animation sub-assets.
//
// ```json
// {
//   "template": "humanoid",
//   "proportions": {"height": 1.1, "head": 1.2, "legs": 0.9},
//   "colors": {"body": [0.8, 0.2, 0.2], "legs": [0.2, 0.2, 0.25]},
//   "attachments": [
//     {"name": "Sword", "bone": "hand.R", "asset": "Models/Sword.meshbuild", "rotation": [90, 0, 0]}
//   ],
//   "ragdoll": {"bones": [{"bone": "lowerLeg.L", "maxAngle": 120}]},
//   "ik": {"footPlacement": true, "lookAt": true, "lookTarget": "Player"}
// }
// ```
//
// The skeleton is built in code from the template and proportions. Bones rest with no rotation
// (only offsets from their parent), facing +Z with +Y up; ".L" bones are on the character's left
// (+X). Clips are generated per template (CharacterClips.swift), so they always fit the skeleton.

/// A body plan: the skeleton, the body shapes and the stock clips.
public enum CharacterTemplate: String, Codable, CaseIterable, Sendable {
    /// Two legs, two arms, a head.
    case humanoid
    /// Four legs, a tail, a long neck.
    case quadruped
    /// Two legs, two wings, a beak and a tail.
    case bird
    /// A round squashy body with two nubs.
    case blob
}

/// Multipliers on the template's measurements (1 is the template as designed; each is clamped to
/// `CharacterProportions.range`). Templates read the ones that apply: a blob has no legs.
public struct CharacterProportions: Codable, Equatable, Sendable {
    /// Scales the whole character.
    public var height: Float = 1
    public var head: Float = 1
    /// Body length (spine).
    public var torso: Float = 1
    /// Girth: body, limb thickness and shoulder or hip spacing.
    public var width: Float = 1
    /// Arm length (a bird's wingspan).
    public var arms: Float = 1
    public var legs: Float = 1
    public var neck: Float = 1
    public var tail: Float = 1

    public static let range: ClosedRange<Float> = 0.25...3
    /// The field names, in display order.
    public static let names = ["height", "head", "torso", "width", "arms", "legs", "neck", "tail"]

    public init(height: Float = 1, head: Float = 1, torso: Float = 1, width: Float = 1, arms: Float = 1, legs: Float = 1,
                neck: Float = 1, tail: Float = 1) {
        self.height = height
        self.head = head
        self.torso = torso
        self.width = width
        self.arms = arms
        self.legs = legs
        self.neck = neck
        self.tail = tail
    }

    private enum CodingKeys: String, CodingKey { case height, head, torso, width, arms, legs, neck, tail }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func read(_ key: CodingKeys, _ field: inout Float) throws {
            if let v = try c.decodeIfPresent(Float.self, forKey: key) { field = v }
        }
        try read(.height, &height); try read(.head, &head); try read(.torso, &torso); try read(.width, &width)
        try read(.arms, &arms); try read(.legs, &legs); try read(.neck, &neck); try read(.tail, &tail)
    }

    /// The value named `name` (one of `names`).
    public subscript(name: String) -> Float? {
        get {
            switch name {
            case "height": height
            case "head": head
            case "torso": torso
            case "width": width
            case "arms": arms
            case "legs": legs
            case "neck": neck
            case "tail": tail
            default: nil
            }
        }
        set {
            guard let v = newValue else { return }
            switch name {
            case "height": height = v
            case "head": head = v
            case "torso": torso = v
            case "width": width = v
            case "arms": arms = v
            case "legs": legs = v
            case "neck": neck = v
            case "tail": tail = v
            default: break
            }
        }
    }

    /// Every value clamped to `range` (NaN becomes 1).
    public var clamped: CharacterProportions {
        var p = self
        for name in Self.names {
            let v = self[name] ?? 1
            p[name] = v.isFinite ? min(max(v, Self.range.lowerBound), Self.range.upperBound) : 1
        }
        return p
    }
}

/// The color regions of a body. Display (sRGB) colors 0...1.
public enum CharacterRegion: String, Codable, CaseIterable, Sendable {
    /// Bare skin: face, hands (a quadruped's snout, a blob's nubs).
    case skin
    /// The torso: shirt, fur, feathers, a blob's body.
    case body
    /// Legs: trousers, a quadruped's legs.
    case legs
    /// Feet, shoes, beak, ears and other details.
    case accent
    case eyes
}

/// Colors by region; a missing one takes the template's default (`CharacterTemplate.defaultColor`).
public struct CharacterColors: Codable, Equatable, Sendable {
    public var skin: Vec3?
    public var body: Vec3?
    public var legs: Vec3?
    public var accent: Vec3?
    public var eyes: Vec3?

    public init(skin: Vec3? = nil, body: Vec3? = nil, legs: Vec3? = nil, accent: Vec3? = nil, eyes: Vec3? = nil) {
        self.skin = skin
        self.body = body
        self.legs = legs
        self.accent = accent
        self.eyes = eyes
    }

    public subscript(region: CharacterRegion) -> Vec3? {
        get {
            switch region {
            case .skin: skin
            case .body: body
            case .legs: legs
            case .accent: accent
            case .eyes: eyes
            }
        }
        set {
            switch region {
            case .skin: skin = newValue
            case .body: body = newValue
            case .legs: legs = newValue
            case .accent: accent = newValue
            case .eyes: eyes = newValue
            }
        }
    }
}

extension CharacterTemplate {
    /// The color a region has when the file doesn't set one.
    public func defaultColor(_ region: CharacterRegion) -> Vec3 {
        switch (self, region) {
        case (_, .eyes): Vec3(0.06, 0.06, 0.08)
        case (.humanoid, .skin): Vec3(0.94, 0.76, 0.62)
        case (.humanoid, .body): Vec3(0.22, 0.45, 0.85)
        case (.humanoid, .legs): Vec3(0.2, 0.22, 0.3)
        case (.humanoid, .accent): Vec3(0.35, 0.22, 0.12)
        case (.quadruped, .skin): Vec3(0.85, 0.7, 0.55)
        case (.quadruped, .body): Vec3(0.62, 0.42, 0.24)
        case (.quadruped, .legs): Vec3(0.55, 0.37, 0.21)
        case (.quadruped, .accent): Vec3(0.25, 0.17, 0.1)
        case (.bird, .skin): Vec3(0.95, 0.9, 0.8)
        case (.bird, .body): Vec3(0.2, 0.6, 0.9)
        case (.bird, .legs): Vec3(0.95, 0.6, 0.15)
        case (.bird, .accent): Vec3(1, 0.7, 0.1)
        case (.blob, .skin): Vec3(0.4, 0.85, 0.45)
        case (.blob, .body): Vec3(0.35, 0.8, 0.4)
        case (.blob, .legs): Vec3(0.3, 0.7, 0.35)
        case (.blob, .accent): Vec3(1, 0.5, 0.6)
        }
    }

    /// The bone hand-held gear goes on by default.
    public var handBone: String {
        switch self {
        case .humanoid: "hand.R"
        case .quadruped: "head"
        case .bird: "head"
        case .blob: "arm.R"
        }
    }
}

/// A `.meshbuild` model attached to a bone: hair, a hat, armor, a sword. It follows the bone
/// rigidly; `position`, `rotation` and `scale` place it in the bone's space (bones rest
/// unrotated, so these are the character's axes: +Y up, +Z forward, +X the character's left).
public struct CharacterAttachment: Codable, Equatable, Sendable {
    /// Unique within the character.
    public var name: String
    /// A bone name of the template (see `CharacterRig.bones`); a missing bone attaches to the root bone.
    public var bone: String
    /// A `.meshbuild` path under `Assets/` (or "asset:<id>" of one).
    public var asset: String
    /// Meters, in the bone's space.
    public var position: Vec3
    /// Euler degrees.
    public var rotation: Vec3
    public var scale: Float
    /// Recolors every part of the model (nil keeps its own colors).
    public var color: Vec3?
    /// Mesh-build part name → color ([r, g, b] 0-1 sRGB) for those parts, over `color` and
    /// the parts' own looks. Mirror / repeat copies ("Right Arm", "Leg 2") can be named, and
    /// otherwise take their source part's entry.
    public var partColors: [String: Vec3]

    public init(name: String = "Part", bone: String = "head", asset: String = "", position: Vec3 = .zero, rotation: Vec3 = .zero,
                scale: Float = 1, color: Vec3? = nil, partColors: [String: Vec3] = [:]) {
        self.name = name
        self.bone = bone
        self.asset = asset
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.color = color
        self.partColors = partColors
    }

    private enum CodingKeys: String, CodingKey { case name, bone, asset, position, rotation, scale, color, partColors }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CharacterAttachment()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  bone: try c.decodeIfPresent(String.self, forKey: .bone) ?? d.bone,
                  asset: try c.decodeIfPresent(String.self, forKey: .asset) ?? d.asset,
                  position: try c.decodeIfPresent(Vec3.self, forKey: .position) ?? d.position,
                  rotation: try c.decodeIfPresent(Vec3.self, forKey: .rotation) ?? d.rotation,
                  scale: try c.decodeIfPresent(Float.self, forKey: .scale) ?? d.scale,
                  color: try c.decodeIfPresent(Vec3.self, forKey: .color),
                  partColors: try c.decodeIfPresent([String: Vec3].self, forKey: .partColors) ?? [:])
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(bone, forKey: .bone)
        try c.encode(asset, forKey: .asset)
        try c.encode(position, forKey: .position)
        try c.encode(rotation, forKey: .rotation)
        try c.encode(scale, forKey: .scale)
        try c.encodeIfPresent(color, forKey: .color)
        if !partColors.isEmpty { try c.encode(partColors, forKey: .partColors) }
    }

    /// The color `part` gets: its entry in `partColors`, else (for a mirror / repeat copy) the
    /// entry of the part it was copied from, `source`, else `color` (nil: the part's own look).
    public func color(ofPart part: String, source: String? = nil) -> Vec3? {
        partColors[part] ?? source.flatMap { partColors[$0] } ?? color
    }

    public static var fieldHints: [String: FieldHints] {
        ["bone": FieldHints(tooltip: "The bone it follows"),
         "asset": FieldHints(tooltip: "A .meshbuild path under Assets/"),
         "position": FieldHints(step: 0.01, tooltip: "Meters in the bone's space (+Y up, +Z forward)"),
         "rotation": FieldHints(step: 1, tooltip: "Degrees"),
         "scale": FieldHints(range: 0.01...100, step: 0.01),
         "color": FieldHints(color: true, srgb: true, tooltip: "Recolors every part (unset keeps the model's colors)"),
         "partColors": FieldHints(tooltip: "Part name → color, over Color")]
    }

    public var transform: Transform {
        Transform(position: position, rotation: Quat(eulerDegrees: rotation), scale: Vec3(repeating: scale))
    }
}

/// A clip from another asset on the character's skeleton: a `clips` entry that is an object
/// (`{"name": "wave", "clip": "asset:<id>#animation/Wave", "boneMap": {"mixamorig:Head": "head"}}`)
/// or an asset reference string (named after its animation). The source is a glTF / GLB file's
/// animation or another `.character`'s clip. Imported by plain name match: each channel on a
/// source node whose name (after `boneMap`) is one of the character's bones drives that bone's
/// rotation and scale; translations (except from a `.character` of the same template) and
/// unmatched nodes are dropped. There is no rest-pose correction: rigs whose bones rest rotated
/// differently from the character's (unrotated) need retargeting. Named like a stock clip, it
/// replaces that clip (a glTF walk in the locomotion blend).
public struct CharacterExternalClip: Codable, Equatable, Sendable {
    /// The Animator state (and the character's `animation/<name>` sub-asset).
    public var name: String
    /// "asset:<id>#animation/<name>".
    public var clip: String
    /// Source node name → character bone name, for bones named differently; names not listed
    /// match as they are.
    public var boneMap: [String: String]
    /// Repeats; default: as the stock clip of that name (idle, walk, run loop), else true.
    public var loops: Bool?

    public init(name: String, clip: String, boneMap: [String: String] = [:], loops: Bool? = nil) {
        self.name = name
        self.clip = clip
        self.boneMap = boneMap
        self.loops = loops
    }

    private enum CodingKeys: String, CodingKey { case name, clip, boneMap, loops }

    public init(from decoder: any Decoder) throws {
        if let text = try? decoder.singleValueContainer().decode(String.self) {
            self.init(name: Self.defaultName(text), clip: text)
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let clip = try c.decode(String.self, forKey: .clip)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? Self.defaultName(clip), clip: clip,
                  boneMap: try c.decodeIfPresent([String: String].self, forKey: .boneMap) ?? [:],
                  loops: try c.decodeIfPresent(Bool.self, forKey: .loops))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(clip, forKey: .clip)
        if !boneMap.isEmpty { try c.encode(boneMap, forKey: .boneMap) }
        try c.encodeIfPresent(loops, forKey: .loops)
    }

    /// The source reference, when `clip` is "asset:<id>#animation/<name>".
    public var reference: AssetReference? {
        guard let reference = AssetReference(clip.trimmingCharacters(in: .whitespaces)),
              reference.subAsset?.hasPrefix("animation/") == true else { return nil }
        return reference
    }

    /// The animation's name in `reference` ("Wave" for "asset:<id>#animation/Wave").
    static func defaultName(_ reference: String) -> String {
        guard let range = reference.range(of: "#animation/") else { return reference }
        return String(reference[range.upperBound...])
    }

    var repeats: Bool { loops ?? (CharacterClips.stockNames.contains(name) ? CharacterClips.loops(name) : true) }
}

/// A character: the contents of a `.character` file.
public struct CharacterBuild: Codable, Equatable, Sendable {
    public var template: CharacterTemplate
    public var proportions: CharacterProportions
    public var colors: CharacterColors
    public var attachments: [CharacterAttachment]
    /// The stock clips to include (names from `CharacterClips.stockNames`); all of them by default.
    public var clips: [String]
    /// Clips from other assets (objects or asset references in the file's `clips` list, after
    /// the stock names).
    public var externalClips: [CharacterExternalClip]
    /// The state the `Animator` starts in.
    public var defaultClip: String
    /// Blends skin weights across joints, so elbows and knees bend smoothly instead of as rigid pieces.
    public var smooth: Bool
    /// Slices around the round body shapes (6...32): lower is chunkier and lighter.
    public var segments: Int
    /// A `Ragdoll` on the prefab (bodies sized from the body shapes; CharacterRagdoll.swift); nil: none.
    public var ragdoll: CharacterRagdoll?
    /// IK nodes on the `Animator` (foot placement, look at, hand reach); nil: none.
    public var ik: CharacterIK?

    public init(template: CharacterTemplate = .humanoid, proportions: CharacterProportions = CharacterProportions(),
                colors: CharacterColors = CharacterColors(), attachments: [CharacterAttachment] = [],
                clips: [String] = CharacterClips.stockNames, externalClips: [CharacterExternalClip] = [], defaultClip: String = "idle",
                smooth: Bool = true, segments: Int = 12, ragdoll: CharacterRagdoll? = nil, ik: CharacterIK? = nil) {
        self.template = template
        self.proportions = proportions
        self.colors = colors
        self.attachments = attachments
        self.clips = clips
        self.externalClips = externalClips
        self.defaultClip = defaultClip
        self.smooth = smooth
        self.segments = segments
        self.ragdoll = ragdoll
        self.ik = ik
    }

    private enum CodingKeys: String, CodingKey { case template, proportions, colors, attachments, clips, defaultClip, smooth, segments, ragdoll, ik }

    /// A `clips` entry: a stock name, or a clip from another asset.
    private enum ClipEntry: Decodable {
        case stock(String)
        case external(CharacterExternalClip)

        init(from decoder: any Decoder) throws {
            if let name = try? decoder.singleValueContainer().decode(String.self), !name.hasPrefix(AssetReference.scheme) {
                self = .stock(name)
            } else {
                self = .external(try CharacterExternalClip(from: decoder))
            }
        }
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CharacterBuild()
        let entries = try c.decodeIfPresent([ClipEntry].self, forKey: .clips)
        self.init(template: try c.decodeIfPresent(CharacterTemplate.self, forKey: .template) ?? d.template,
                  proportions: try c.decodeIfPresent(CharacterProportions.self, forKey: .proportions) ?? d.proportions,
                  colors: try c.decodeIfPresent(CharacterColors.self, forKey: .colors) ?? d.colors,
                  attachments: try c.decodeIfPresent([CharacterAttachment].self, forKey: .attachments) ?? d.attachments,
                  clips: entries.map { $0.compactMap { if case .stock(let name) = $0 { name } else { nil } } } ?? d.clips,
                  externalClips: entries.map { $0.compactMap { if case .external(let clip) = $0 { clip } else { nil } } } ?? [],
                  defaultClip: try c.decodeIfPresent(String.self, forKey: .defaultClip) ?? d.defaultClip,
                  smooth: try c.decodeIfPresent(Bool.self, forKey: .smooth) ?? d.smooth,
                  segments: try c.decodeIfPresent(Int.self, forKey: .segments) ?? d.segments,
                  ragdoll: try c.decodeIfPresent(CharacterRagdoll.self, forKey: .ragdoll),
                  ik: try c.decodeIfPresent(CharacterIK.self, forKey: .ik))
    }

    /// `clips` holds the stock names, then the external clips' objects.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(template, forKey: .template)
        try c.encode(proportions, forKey: .proportions)
        try c.encode(colors, forKey: .colors)
        try c.encode(attachments, forKey: .attachments)
        var list = c.nestedUnkeyedContainer(forKey: .clips)
        for name in clips { try list.encode(name) }
        for clip in externalClips { try list.encode(clip) }
        try c.encode(defaultClip, forKey: .defaultClip)
        try c.encode(smooth, forKey: .smooth)
        try c.encode(segments, forKey: .segments)
        try c.encodeIfPresent(ragdoll, forKey: .ragdoll)
        try c.encodeIfPresent(ik, forKey: .ik)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// The color of `region`: the file's, else the template's default.
    public func color(_ region: CharacterRegion) -> Vec3 { colors[region] ?? template.defaultColor(region) }

    /// The skeleton and body shapes for the template and proportions.
    public var rig: CharacterRig { CharacterRig(template: template, proportions: proportions) }

    /// The Animator's clip states: `clips` filtered to stock names, without repeats, in stock
    /// order (an external clip of the same name takes its place), then the other external clips.
    public var clipNames: [String] {
        let external = externalClips.map(\.name)
        var names = CharacterClips.stockNames.filter { clips.contains($0) || external.contains($0) }
        for name in external where !names.contains(name) && !name.isEmpty { names.append(name) }
        return names
    }

    /// The stock clips generated in code (those no external clip replaces).
    public var stockClipNames: [String] {
        CharacterClips.stockNames.filter { name in clips.contains(name) && !externalClips.contains { $0.name == name } }
    }

    /// Whether the clip state `name` repeats.
    public func loops(_ name: String) -> Bool {
        externalClips.first { $0.name == name }?.repeats ?? CharacterClips.loops(name)
    }

    /// `base`, or "`base` 2", "`base` 3"… whichever no attachment has.
    public func uniqueAttachmentName(_ base: String) -> String {
        let names = Set(attachments.map(\.name))
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// Problems found without importing: unknown bones, clips, duplicate names.
    public var problems: [String] {
        var problems: [String] = []
        let bones = Set(rig.bones.map(\.name))
        var seen = Set<String>()
        for a in attachments {
            if !seen.insert(a.name).inserted { problems.append("two attachments are named '\(a.name)'") }
            if !bones.contains(a.bone) { problems.append("attachment '\(a.name)': no bone '\(a.bone)' in the \(template.rawValue) template; it goes on '\(rig.bones[0].name)'") }
            if a.asset.trimmingCharacters(in: .whitespaces).isEmpty { problems.append("attachment '\(a.name)' has no asset") }
        }
        for clip in clips where !CharacterClips.stockNames.contains(clip) {
            problems.append("no stock clip '\(clip)' (stock clips: \(CharacterClips.stockNames.joined(separator: ", ")))")
        }
        var clipNamesSeen = Set<String>()
        for clip in externalClips {
            let label = clip.name.isEmpty ? "'\(clip.clip)'" : "'\(clip.name)'"
            if clip.name.trimmingCharacters(in: .whitespaces).isEmpty { problems.append("clip '\(clip.clip)' has no name") }
            if !clipNamesSeen.insert(clip.name).inserted { problems.append("two clips are named '\(clip.name)'") }
            if clip.name == "locomotion" { problems.append("clip 'locomotion': the name is the locomotion blend's") }
            if clip.reference == nil {
                problems.append("clip \(label): '\(clip.clip)' isn't an animation reference (asset:<id>#animation/<name>)")
            }
            for (source, bone) in clip.boneMap.sorted(by: { $0.key < $1.key }) where !bones.contains(bone) {
                problems.append("clip \(label): boneMap '\(source)' → no bone '\(bone)' in the \(template.rawValue) template")
            }
        }
        if !clipNames.isEmpty && !clipNames.contains(defaultClip) {
            problems.append("defaultClip '\(defaultClip)' isn't one of the clips; the Animator starts in '\(clipNames[0])'")
        }
        if let ragdoll {
            let bodies = Set(rig.ragdollBones().map(\.bone))
            var seenBones = Set<String>()
            for o in ragdoll.bones {
                if !seenBones.insert(o.bone).inserted { problems.append("ragdoll: two entries for bone '\(o.bone)'") }
                if !bodies.contains(o.bone) {
                    problems.append("ragdoll: '\(o.bone)' has no body (bodies: \(rig.ragdollBones().map(\.bone).joined(separator: ", ")))")
                }
                if let r = o.radius, !(r > 0) { problems.append("ragdoll '\(o.bone)': radius must be above 0") }
                if let lo = o.minAngle, let hi = o.maxAngle, lo > hi { problems.append("ragdoll '\(o.bone)': minAngle \(lo) is above maxAngle \(hi)") }
                if let swing = o.swing, !(0...180).contains(swing) { problems.append("ragdoll '\(o.bone)': swing \(swing) is outside 0...180") }
            }
            if let m = ragdoll.mass, !(m > 0) { problems.append("ragdoll: mass must be above 0") }
        }
        if let ik {
            if ik.footPlacement && rig.ikLegs == nil { problems.append("ik: the \(template.rawValue) template has no legs for footPlacement") }
            if ik.handIK && rig.ikArms.isEmpty { problems.append("ik: the \(template.rawValue) template has no arms for handIK") }
        }
        let p = proportions
        for name in CharacterProportions.names {
            if let v = p[name], !CharacterProportions.range.contains(v) {
                problems.append("proportion \(name) \(v) is outside \(CharacterProportions.range.lowerBound)...\(CharacterProportions.range.upperBound); clamped")
            }
        }
        return problems
    }
}

// MARK: - Skeleton and body

/// One bone of a character skeleton.
public struct CharacterBone: Equatable, Sendable {
    public var name: String
    /// Index of the parent bone (nil for the root bone, which is always bone 0).
    public var parent: Int?
    /// Rest offset from the parent bone (from the character's origin for the root bone), meters.
    public var offset: Vec3
    /// Rest position in the character's space (bones rest unrotated).
    public var position: Vec3
}

/// One body shape, posed by up to three bones: `bone`, blending toward `startBone` near
/// `from` and toward `endBone` near `to` (over `blend` of its length) when smoothing.
public struct CharacterSegment: Equatable, Sendable {
    public var bone: Int
    public var shape: MeshBuildShape
    /// The shape spans `from` to `to` (character space, rest pose) along its Y axis.
    public var from: Vec3
    public var to: Vec3
    /// Half-thickness across the axis: x is the character's sideways direction for vertical
    /// shapes, y the other one.
    public var radius: Vec2
    public var region: CharacterRegion
    public var startBone: Int?
    public var endBone: Int?
    public var blend: Float
}

/// A template's skeleton and body shapes for some proportions.
public struct CharacterRig: Equatable, Sendable {
    public private(set) var template: CharacterTemplate
    public private(set) var bones: [CharacterBone] = []
    public private(set) var segments: [CharacterSegment] = []
    /// The proportions used (clamped).
    public private(set) var proportions: CharacterProportions

    public init(template: CharacterTemplate, proportions: CharacterProportions = CharacterProportions()) {
        self.template = template
        self.proportions = proportions.clamped
        build()
    }

    public func index(of bone: String) -> Int? { bones.firstIndex { $0.name == bone } }

    /// Overall height of the rest pose (top of the highest shape), meters.
    public var height: Float {
        segments.map { max($0.from.y, $0.to.y) }.max() ?? 1
    }

    // MARK: Building

    private mutating func bone(_ name: String, _ parent: Int?, _ offset: Vec3) -> Int {
        let position = (parent.map { bones[$0].position } ?? .zero) + offset
        bones.append(CharacterBone(name: name, parent: parent, offset: offset, position: position))
        return bones.count - 1
    }

    private func at(_ bone: Int, _ offset: Vec3 = .zero) -> Vec3 { bones[bone].position + offset }

    private mutating func segment(_ bone: Int, _ shape: MeshBuildShape, _ from: Vec3, _ to: Vec3, _ radius: Vec2, _ region: CharacterRegion,
                                  start: Int? = nil, end: Int? = nil, blend: Float = 0.25) {
        segments.append(CharacterSegment(bone: bone, shape: shape, from: from, to: to, radius: radius, region: region,
                                         startBone: start, endBone: end, blend: blend))
    }

    /// A shape centered on `center` with half-sizes `half` (y along the vertical).
    private mutating func blobShape(_ bone: Int, _ shape: MeshBuildShape, _ center: Vec3, _ half: Vec3, _ region: CharacterRegion) {
        segment(bone, shape, center - Vec3(0, half.y, 0), center + Vec3(0, half.y, 0), Vec2(half.x, half.z), region)
    }

    private mutating func build() {
        let p = proportions
        switch template {
        case .humanoid: buildHumanoid(p)
        case .quadruped: buildQuadruped(p)
        case .bird: buildBird(p)
        case .blob: buildBlob(p)
        }
        // Height scales everything about the character's origin.
        let s = p.height
        guard s != 1 else { return }
        for i in bones.indices {
            bones[i].offset *= s
            bones[i].position *= s
        }
        for i in segments.indices {
            segments[i].from *= s
            segments[i].to *= s
            segments[i].radius *= s
        }
    }

    private mutating func buildHumanoid(_ p: CharacterProportions) {
        let W = p.width, A = p.arms, L = p.legs, T = p.torso, H = p.head, N = p.neck
        let thigh: Float = 0.42 * L, shin: Float = 0.4 * L, ankle: Float = 0.08
        let hips = bone("hips", nil, Vec3(0, ankle + thigh + shin + 0.04, 0))
        let spine = bone("spine", hips, Vec3(0, 0.1 * T, 0))
        let chest = bone("chest", spine, Vec3(0, 0.2 * T, 0))
        let neck = bone("neck", chest, Vec3(0, 0.2 * T, 0))
        let head = bone("head", neck, Vec3(0, 0.08 * N, 0))
        segment(hips, .capsule, at(hips, Vec3(0, -0.09, 0)), at(spine, Vec3(0, 0.04, 0)), Vec2(0.15 * W, 0.1 * W), .legs, end: spine)
        segment(spine, .capsule, at(spine, Vec3(0, -0.02, 0)), at(chest, Vec3(0, 0.06, 0)), Vec2(0.15 * W, 0.1 * W), .body, start: hips, end: chest)
        segment(chest, .capsule, at(chest, Vec3(0, -0.04, 0)), at(neck, Vec3(0, 0.02, 0)), Vec2(0.18 * W, 0.11 * W), .body, start: spine)
        segment(neck, .capsule, at(neck, Vec3(0, -0.03, 0)), at(head, Vec3(0, 0.04, 0)), Vec2(0.045, 0.045) * W, .skin, start: chest)
        let headCenter = at(head, Vec3(0, 0.12 * H, 0.01))
        blobShape(head, .sphere, headCenter, Vec3(0.11, 0.13, 0.12) * H, .skin)
        for eye: Float in [1, -1] {
            blobShape(head, .sphere, headCenter + Vec3(eye * 0.045, 0.01, 0.105) * H, Vec3(repeating: 0.022 * H), .eyes)
        }
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            let upperArm = bone("upperArm.\(side)", chest, Vec3(s * (0.17 * W + 0.04), 0.16 * T, 0))
            let lowerArm = bone("lowerArm.\(side)", upperArm, Vec3(0, -0.28 * A, 0))
            let hand = bone("hand.\(side)", lowerArm, Vec3(0, -0.26 * A, 0))
            segment(upperArm, .capsule, at(upperArm, Vec3(0, 0.04, 0)), at(lowerArm), Vec2(0.055, 0.055) * W, .body, start: chest, blend: 0.15)
            segment(lowerArm, .capsule, at(lowerArm, Vec3(0, 0.02, 0)), at(hand), Vec2(0.045, 0.045) * W, .skin, start: upperArm)
            blobShape(hand, .sphere, at(hand, Vec3(0, -0.05, 0)), Vec3(0.04, 0.06, 0.035) * W, .skin)
            let upperLeg = bone("upperLeg.\(side)", hips, Vec3(s * 0.09 * W, -0.05, 0))
            let lowerLeg = bone("lowerLeg.\(side)", upperLeg, Vec3(0, -thigh, 0))
            let foot = bone("foot.\(side)", lowerLeg, Vec3(0, -shin, 0))
            segment(upperLeg, .capsule, at(upperLeg, Vec3(0, 0.05, 0)), at(lowerLeg), Vec2(0.075, 0.075) * W, .legs, start: hips, blend: 0.2)
            segment(lowerLeg, .capsule, at(lowerLeg, Vec3(0, 0.03, 0)), at(foot, Vec3(0, -0.02, 0)), Vec2(0.058, 0.058) * W, .legs, start: upperLeg)
            segment(foot, .box, at(foot, Vec3(0, -ankle * 0.55, -0.06)), at(foot, Vec3(0, -ankle * 0.55, 0.16 * L.squareRoot())),
                    Vec2(0.055 * W, ankle * 0.45), .accent)
        }
    }

    private mutating func buildQuadruped(_ p: CharacterProportions) {
        let W = p.width, L = p.legs, T = p.torso, H = p.head, N = p.neck, Tl = p.tail
        let upper: Float = 0.24 * L, lower: Float = 0.22 * L, ankle: Float = 0.05
        let hips = bone("hips", nil, Vec3(0, ankle + upper + lower + 0.04, -0.3 * T))
        let spine = bone("spine", hips, Vec3(0, 0.02, 0.3 * T))
        let chest = bone("chest", spine, Vec3(0, 0.01, 0.3 * T))
        let neck = bone("neck", chest, Vec3(0, 0.1, 0.08))
        let head = bone("head", neck, Vec3(0, 0.2 * N, 0.1 * N))
        let tail = bone("tail", hips, Vec3(0, 0.05, -0.12))
        let tailTip = bone("tailTip", tail, Vec3(0, 0.06 * Tl, -0.2 * Tl))
        segment(hips, .capsule, at(hips, Vec3(0, 0, -0.14)), at(spine, Vec3(0, 0, -0.05)), Vec2(0.15, 0.16) * W, .body, end: spine, blend: 0.35)
        segment(spine, .capsule, at(spine, Vec3(0, 0, -0.12)), at(chest, Vec3(0, 0, 0.0)), Vec2(0.155, 0.165) * W, .body, start: hips, end: chest, blend: 0.3)
        segment(chest, .capsule, at(chest, Vec3(0, 0, -0.1)), at(chest, Vec3(0, 0.02, 0.15)), Vec2(0.16, 0.17) * W, .body, start: spine, blend: 0.3)
        segment(neck, .capsule, at(neck, Vec3(0, -0.06, -0.03)), at(head), Vec2(0.075, 0.075) * W, .body, start: chest)
        let headCenter = at(head, Vec3(0, 0.03, 0.04))
        blobShape(head, .sphere, headCenter, Vec3(0.1, 0.1, 0.11) * H, .body)
        segment(head, .capsule, headCenter + Vec3(0, -0.03, 0.02) * H, headCenter + Vec3(0, -0.04, 0.17) * H, Vec2(0.055, 0.05) * H, .skin)
        for s: Float in [1, -1] {
            blobShape(head, .sphere, headCenter + Vec3(s * 0.055, 0.035, 0.085) * H, Vec3(repeating: 0.02 * H), .eyes)
            segment(head, .cone, headCenter + Vec3(s * 0.06, 0.07, -0.03) * H, headCenter + Vec3(s * 0.08, 0.17, -0.05) * H,
                    Vec2(0.035, 0.02) * H, .accent)
        }
        segment(tail, .capsule, at(tail, Vec3(0, -0.01, 0.03)), at(tailTip), Vec2(0.035, 0.035) * W, .body, start: hips, blend: 0.2)
        segment(tailTip, .capsule, at(tailTip, Vec3(0, -0.005, 0.02)), at(tailTip, Vec3(0, 0.03 * Tl, -0.12 * Tl)), Vec2(0.03, 0.03) * W, .accent, start: tail)
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            for (prefix, parent, z) in [("front", chest, Float(0.02)), ("back", hips, Float(-0.02))] {
                let top = bone("\(prefix)Upper.\(side)", parent, Vec3(s * 0.1 * W, -0.05, z))
                let mid = bone("\(prefix)Lower.\(side)", top, Vec3(0, -upper, 0))
                let foot = bone("\(prefix)Foot.\(side)", mid, Vec3(0, -lower, 0))
                segment(top, .capsule, at(top, Vec3(0, 0.07, 0)), at(mid), Vec2(0.06, 0.07) * W, .legs, start: parent, blend: 0.2)
                segment(mid, .capsule, at(mid, Vec3(0, 0.02, 0)), at(foot), Vec2(0.045, 0.045) * W, .legs, start: top)
                blobShape(foot, .sphere, at(foot, Vec3(0, -ankle * 0.5, 0.015)), Vec3(0.05, ankle * 0.55, 0.06) * W, .accent)
            }
        }
    }

    private mutating func buildBird(_ p: CharacterProportions) {
        let W = p.width, A = p.arms, L = p.legs, T = p.torso, H = p.head, N = p.neck, Tl = p.tail
        let thigh: Float = 0.12 * L, shin: Float = 0.12 * L, ankle: Float = 0.03
        let body = bone("body", nil, Vec3(0, ankle + thigh + shin + 0.1, 0))
        let neck = bone("neck", body, Vec3(0, 0.1, 0.1 * T))
        let head = bone("head", neck, Vec3(0, 0.1 * N, 0.03))
        let tail = bone("tail", body, Vec3(0, 0.03, -0.15 * T))
        blobShape(body, .sphere, at(body, Vec3(0, 0.01, -0.01)), Vec3(0.12 * W, 0.12, 0.17 * T), .body)
        segment(neck, .capsule, at(neck, Vec3(0, -0.05, -0.02)), at(head), Vec2(0.055, 0.055) * W, .body, start: body)
        let headCenter = at(head, Vec3(0, 0.03, 0.01))
        blobShape(head, .sphere, headCenter, Vec3(repeating: 0.075 * H), .body)
        segment(head, .cone, headCenter + Vec3(0, -0.005, 0.05) * H, headCenter + Vec3(0, -0.015, 0.15) * H, Vec2(0.03, 0.022) * H, .accent)
        blobShape(head, .sphere, headCenter + Vec3(0, -0.02, 0.035) * H, Vec3(0.05, 0.035, 0.04) * H, .skin)
        for s: Float in [1, -1] {
            blobShape(head, .sphere, headCenter + Vec3(s * 0.045, 0.02, 0.045) * H, Vec3(repeating: 0.016 * H), .eyes)
        }
        segment(tail, .box, at(tail, Vec3(0, 0, 0.04)), at(tail, Vec3(0, 0.03 * Tl, -0.14 * Tl)), Vec2(0.07, 0.012) * W, .body, start: body, blend: 0.15)
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            let wing = bone("wing.\(side)", body, Vec3(s * 0.11 * W, 0.04, 0))
            let tip = bone("wingTip.\(side)", wing, Vec3(s * 0.2 * A, 0, -0.03))
            segment(wing, .capsule, at(wing, Vec3(-s * 0.03, 0, 0)), at(tip), Vec2(0.02, 0.075), .body, start: body, blend: 0.15)
            segment(tip, .capsule, at(tip, Vec3(-s * 0.02, 0, 0)), at(tip, Vec3(s * 0.16 * A, 0, -0.05)), Vec2(0.015, 0.055), .body, start: wing)
            let leg = bone("leg.\(side)", body, Vec3(s * 0.055 * W, -0.08, 0))
            let shinBone = bone("shin.\(side)", leg, Vec3(0, -thigh, 0))
            let foot = bone("foot.\(side)", shinBone, Vec3(0, -shin, 0))
            segment(leg, .capsule, at(leg, Vec3(0, 0.04, 0)), at(shinBone), Vec2(0.04, 0.04) * W, .body, start: body, blend: 0.15)
            segment(shinBone, .cylinder, at(shinBone), at(foot), Vec2(0.012, 0.012) * W, .legs)
            segment(foot, .box, at(foot, Vec3(0, -ankle * 0.6, -0.02)), at(foot, Vec3(0, -ankle * 0.6, 0.07)), Vec2(0.03 * W, ankle * 0.35), .legs)
        }
    }

    private mutating func buildBlob(_ p: CharacterProportions) {
        let W = p.width, T = p.torso, H = p.head, A = p.arms
        let root = bone("root", nil, .zero)
        let body = bone("body", root, Vec3(0, 0.02, 0))
        let top = bone("top", body, Vec3(0, 0.36 * T, 0))
        segment(body, .sphere, at(body, Vec3(0, -0.02, 0)), at(body, Vec3(0, 0.6 * T, 0)), Vec2(0.32, 0.3) * W, .body, end: top, blend: 0.6)
        let topZ = 0.27 * W
        for s: Float in [1, -1] {
            blobShape(top, .sphere, at(top, Vec3(s * 0.09 * W, 0.04 * H, topZ)), Vec3(0.04, 0.05, 0.03) * H, .eyes)
        }
        segment(top, .cone, at(top, Vec3(0, 0.2 * T, 0)), at(top, Vec3(0, 0.2 * T + 0.12 * H, 0)), Vec2(0.04, 0.04) * H, .accent)
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            let arm = bone("arm.\(side)", body, Vec3(s * 0.3 * W, 0.22 * T, 0))
            segment(arm, .capsule, at(arm, Vec3(-s * 0.02, 0, 0)), at(arm, Vec3(s * 0.1 * A, -0.04, 0)), Vec2(0.05, 0.05) * W, .skin, start: body, blend: 0.2)
        }
    }

    /// The shortest rotation taking unit vector `a` to unit vector `b`.
    package static func rotation(from a: Vec3, to b: Vec3) -> Quat {
        let d = dot(a, b)
        if d > 0.9999 { return .identity }
        if d < -0.9999 {
            let axis = abs(a.x) < 0.9 ? Vec3(1, 0, 0) : Vec3(0, 0, 1)
            return Quat(angle: .pi, axis: normalize(cross(a, axis)))
        }
        return Quat(angle: acosf(d), axis: normalize(cross(a, b)))
    }

    /// Mesh space to each bone's space in the rest pose (the `Skin` inverse bind matrices).
    public var inverseBindMatrices: [Mat4] { bones.map { Mat4.translation(-$0.position) } }

    /// The bones' rest transforms (local, relative to the parent bone).
    public var restPose: [Transform] { bones.map { Transform(position: $0.offset) } }
}
