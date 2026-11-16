import Engine
import Foundation

/// The character builder tools: `character.new`, `.get`, `.set`, `.edit`, `.open`, `.bones`, and
/// `view.animateInEditMode`.
@MainActor
public enum EditorCharacterCommands {
    public static let all: [any EditorCommand.Type] = [
        CharacterNewCommand.self,
        CharacterGetCommand.self,
        CharacterSetCommand.self,
        CharacterEditCommand.self,
        CharacterOpenCommand.self,
        CharacterBonesCommand.self,
        ViewAnimateInEditModeCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A character is a body `template` (humanoid, quadruped, bird, blob) with a generated skeleton, `proportions` \
        (multipliers, 1 = as designed, 0.25-3: height (scales everything), head, torso, width, arms (a bird's wings), legs, \
        neck, tail), `colors` by region (skin, body, legs, accent, eyes; [r,g,b] 0-1 sRGB; a missing one is the template's \
        default), `attachments` (each: name, bone (see character.bones), asset (a .meshbuild path under Assets/), position \
        [x,y,z] meters and rotation [x,y,z] degrees in the bone's space (+Y up, +Z forward, +X the character's left), scale, \
        optional color recoloring every part), `clips` (stock clips to include: idle, walk, run, jump, attack, die; all by \
        default), `defaultClip` (the Animator's first state), `smooth` (blended skin weights at joints) and `segments` (6-32, \
        roundness). It imports as a skinned prefab with an Animator whose states are the clips plus `locomotion` (idle/walk/run \
        blended by the float parameter `speed` in m/s), with triggers `jump`, `attack`, `die`. Every key is optional.
        """
}

extension EditorSession {
    /// Writes a character to "`name`.character" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createCharacterAsset(in folder: String, name: String = "New Character", character: CharacterBuild) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Character") else {
            log.error("New Character: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".character"))
        do {
            let id = try assets.createCharacter(character, at: path)
            log.info("Created character \(path)")
            return id
        } catch {
            log.error("New Character failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.character` file.
    public func isCharacterFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == CharacterImporter().name
    }

    /// Replaces the contents of the character `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applyCharacter(_ character: CharacterBuild, to id: AssetID, label: String = "Edit Character") -> [String]? {
        guard let assets, let old = assets.character(of: id) else {
            log.error("\(label): \(id) isn't a readable .character file")
            return nil
        }
        guard old != character else { return [] }
        let command = CharacterFileEditCommand(asset: id, old: old, new: character, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// The character named by `asset` or `path` and its contents.
    func resolveCharacter(_ asset: AssetReference?, path: String?, _ title: String) throws -> (AssetID, CharacterBuild) {
        let id = try resolveAsset(asset, path: path, title)
        guard isCharacterFile(id), let character = assets?.character(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .character file")
        }
        return (id, character)
    }
}

/// Makes character edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct CharacterFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: CharacterBuild
    public let new: CharacterBuild
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: CharacterBuild, new: CharacterBuild, in database: AssetDatabase, label: String = "Edit Character") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ character: CharacterBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(character.template.rawValue) }
        warnings.value = try database.writeCharacter(character, to: asset)
    }
}

/// One bone, as the tools list them.
public struct CharacterBoneInfo: Codable, Equatable, Sendable {
    public var name: String
    public var parent: String?
    /// Rest position in the character's space, meters.
    public var position: Vec3
}

/// One generated clip, as the tools list them.
public struct CharacterClipInfo: Codable, Equatable, Sendable {
    /// The state name in the Animator (and the clip's name).
    public var name: String
    /// The clip to put in an AnimationClipHandle ("asset:<id>#animation/<name>").
    public var clip: String
    public var duration: Float
    public var loops: Bool
    public var events: [String]
}

/// What the tools return.
public struct CharacterResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    public var template: CharacterTemplate
    /// Rest height, meters.
    public var height: Float
    public var bones: [String]
    public var clips: [String]
    public var attachments: [String]
    /// The Animator's parameters: `speed` (float, m/s, drives `locomotion`) and the triggers.
    public var parameters: [String]
    /// Import problems and unresolved references.
    public var warnings: [String]
    /// Entities placed in the scene (character.new with `place`).
    public var entities: [EntityID]?
}

extension CharacterResult {
    @MainActor init(_ id: AssetID, _ character: CharacterBuild, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        let rig = character.rig
        let clips = character.clipNames
        var parameters: [String] = []
        if clips.filter({ ["idle", "walk", "run"].contains($0) }).count >= 2 { parameters.append("speed") }
        parameters += ["jump", "attack", "die"].filter(clips.contains)
        var all = warnings
        for problem in character.problems where !all.contains(problem) { all.append(problem) }
        if let error = record?.importError { all.append("import failed: \(error)") }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, template: character.template,
                  height: rig.bounds.center.y + rig.bounds.halfExtent.y, bones: rig.bones.map(\.name), clips: clips,
                  attachments: character.attachments.map(\.name), parameters: parameters, warnings: all, entities: entities)
    }
}

/// Problems with a character's references, found without importing.
@MainActor
enum CharacterCheck {
    static func problems(_ character: CharacterBuild, in session: EditorSession) -> [String] {
        var problems: [String] = []
        for a in character.attachments where !a.asset.trimmingCharacters(in: .whitespaces).isEmpty {
            let value = a.asset.trimmingCharacters(in: .whitespaces)
            guard let id = MeshBuildCheck.resolve(value, session: session) else {
                problems.append("attachment '\(a.name)': no asset '\(a.asset)'")
                continue
            }
            if session.assets?.record(id)?.importer != MeshBuildImporter().name {
                problems.append("attachment '\(a.name)': '\(a.asset)' isn't a .meshbuild")
            }
        }
        return problems
    }
}

/// Arguments that name a character file.
public struct CharacterTargetArguments: Codable, Equatable, Sendable {
    public var asset: AssetReference?
    public var path: String?
    public init(asset: AssetReference? = nil, path: String? = nil) {
        self.asset = asset
        self.path = path
    }
}

public enum CharacterNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Character" (the file gets ".character").
        public var name: String?
        /// humanoid (default), quadruped, bird or blob.
        public var template: CharacterTemplate?
        /// Proportion name → multiplier (see the format).
        public var proportions: [String: Float]?
        /// Region name → [r, g, b].
        public var colors: [String: Vec3]?
        public var attachments: [CharacterAttachment]?
        /// Also place it in the scene (default false).
        public var place: Bool?
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, template: CharacterTemplate? = nil, proportions: [String: Float]? = nil,
                    colors: [String: Vec3]? = nil, attachments: [CharacterAttachment]? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.template = template
            self.proportions = proportions
            self.colors = colors
            self.attachments = attachments
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "character.new"
    public static let title = "New Character"
    public static let doc = "Writes a .character file in `folder` (default: the Assets root) from a body template, imported as a skinned prefab with an Animator and the stock clips (idle, walk, run, jump, attack, die), optionally placed in the scene. Then change it with character.edit {proportions, colors, attach}. " + EditorCharacterCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterResult {
        var character = CharacterBuild(template: arguments.template ?? .humanoid)
        character = try CharacterEditCommand.edited(character, with: .init(proportions: arguments.proportions, colors: arguments.colors,
                                                                            attach: arguments.attachments))
        let name = arguments.name ?? (arguments.template.map { $0.rawValue.prefix(1).uppercased() + $0.rawValue.dropFirst() } ?? "New Character")
        let id = try session.commands.require(session.createCharacterAsset(in: arguments.folder ?? "", name: name, character: character), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return CharacterResult(id, character, warnings: CharacterCheck.problems(character, in: session), entities: entities, in: session)
    }
}

public enum CharacterGetCommand: EditorCommand {
    public typealias Arguments = CharacterTargetArguments

    public struct Result: Codable, Equatable, Sendable {
        public var summary: CharacterResult
        /// The file's contents with every default filled in.
        public var character: CharacterBuild
        /// The colors in use (the file's, else the template's defaults).
        public var colors: [String: Vec3]
        public var bones: [CharacterBoneInfo]
        public var clips: [CharacterClipInfo]
    }

    public static let id: CommandID = "character.get"
    public static let title = "Get Character"
    public static let doc = "Reads a .character file: template, proportions, colors (the ones in use, defaults included), attachments, the generated bones (name, parent, rest position) and clips (state name, clip reference, duration, looping, events), and a summary with problems."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, c) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let rig = c.rig
        var colors: [String: Vec3] = [:]
        for region in CharacterRegion.allCases { colors[region.rawValue] = c.color(region) }
        let clips = c.clipNames.map { name -> CharacterClipInfo in
            let duration = CharacterClips.duration(name, template: c.template)
            return CharacterClipInfo(name: name, clip: AssetReference(id, subAsset: "animation/\(name)").description, duration: duration,
                                     loops: CharacterClips.loops(name), events: CharacterClips.events(name, duration: duration).map(\.name))
        }
        return Result(summary: CharacterResult(id, c, warnings: CharacterCheck.problems(c, in: session), in: session), character: c,
                      colors: colors, bones: Self.bones(rig), clips: clips)
    }

    static func bones(_ rig: CharacterRig) -> [CharacterBoneInfo] {
        rig.bones.map { CharacterBoneInfo(name: $0.name, parent: $0.parent.map { rig.bones[$0].name }, position: $0.position) }
    }
}

public enum CharacterSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var character: CharacterBuild
        public init(asset: AssetReference? = nil, path: String? = nil, character: CharacterBuild) {
            self.asset = asset
            self.path = path
            self.character = character
        }
    }

    public static let id: CommandID = "character.set"
    public static let title = "Set Character"
    public static let doc = "Replaces a .character file's whole contents and reimports it; placed copies update. Undoable. For a few changes character.edit is shorter. " + EditorCharacterCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterResult {
        let (id, _) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let warnings = try session.commands.require(session.applyCharacter(arguments.character, to: id, label: title), title)
        return CharacterResult(id, arguments.character, warnings: warnings + CharacterCheck.problems(arguments.character, in: session), in: session)
    }
}

public enum CharacterEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// A new body template (bones change: attachments on bones the new template lacks go on its root bone).
        public var template: CharacterTemplate?
        /// Proportion name → multiplier (the others keep their values).
        public var proportions: [String: Float]?
        /// Region name → [r, g, b] (the others keep theirs).
        public var colors: [String: Vec3]?
        /// Regions to set back to the template's default color.
        public var resetColors: [String]?
        /// Attachments to remove by name.
        public var detach: [String]?
        /// Attachments to add (a taken name gets " 2"…).
        public var attach: [CharacterAttachment]?
        /// Attachment name → fields to change; a "name" key renames it.
        public var updateAttachments: [String: JSONValue]?
        /// The stock clips to include.
        public var clips: [String]?
        public var defaultClip: String?
        public var smooth: Bool?
        public var segments: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, template: CharacterTemplate? = nil, proportions: [String: Float]? = nil,
                    colors: [String: Vec3]? = nil, resetColors: [String]? = nil, detach: [String]? = nil, attach: [CharacterAttachment]? = nil,
                    updateAttachments: [String: JSONValue]? = nil, clips: [String]? = nil, defaultClip: String? = nil, smooth: Bool? = nil,
                    segments: Int? = nil) {
            self.asset = asset
            self.path = path
            self.template = template
            self.proportions = proportions
            self.colors = colors
            self.resetColors = resetColors
            self.detach = detach
            self.attach = attach
            self.updateAttachments = updateAttachments
            self.clips = clips
            self.defaultClip = defaultClip
            self.smooth = smooth
            self.segments = segments
        }
    }

    public static let id: CommandID = "character.edit"
    public static let title = "Edit Character"
    public static let doc = "Changes a .character file in one undoable step, in this order: template, proportions (name → multiplier), colors (region → [r,g,b]), resetColors, detach, attach, updateAttachments (name → fields; \"name\" renames), clips, defaultClip, smooth, segments. Placed copies update. Bone names for attach come from character.bones or character.get."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterResult {
        let (id, original) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let character = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyCharacter(character, to: id, label: title), title)
        return CharacterResult(id, character, warnings: warnings + CharacterCheck.problems(character, in: session), in: session)
    }

    /// `character` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ character: CharacterBuild, with arguments: Arguments) throws -> CharacterBuild {
        var c = character
        if let template = arguments.template { c.template = template }
        for (name, value) in (arguments.proportions ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard CharacterProportions.names.contains(name) else {
                throw CommandError.failed("No proportion '\(name)' (proportions: \(CharacterProportions.names.joined(separator: ", ")))")
            }
            guard value.isFinite, CharacterProportions.range.contains(value) else {
                throw CommandError.failed("proportion \(name) must be \(CharacterProportions.range.lowerBound)...\(CharacterProportions.range.upperBound)")
            }
            c.proportions[name] = value
        }
        for (name, color) in (arguments.colors ?? [:]).sorted(by: { $0.key < $1.key }) {
            c.colors[try region(name)] = Vec3(min(max(color.x, 0), 1), min(max(color.y, 0), 1), min(max(color.z, 0), 1))
        }
        for name in arguments.resetColors ?? [] { c.colors[try region(name)] = nil }
        if let names = arguments.detach {
            let missing = names.filter { name in !c.attachments.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No attachment named \(missing.joined(separator: ", "))") }
            c.attachments.removeAll { names.contains($0.name) }
        }
        for var attachment in arguments.attach ?? [] {
            attachment.name = c.uniqueAttachmentName(attachment.name)
            c.attachments.append(attachment)
        }
        for (name, changes) in (arguments.updateAttachments ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = c.attachments.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No attachment named \(name)") }
            let updated = try TerrainEditCommand.merged(c.attachments[index], changes, "updateAttachments[\(name)]")
            if updated.name != name, c.attachments.contains(where: { $0.name == updated.name }) {
                throw CommandError.failed("An attachment is already named \(updated.name)")
            }
            c.attachments[index] = updated
        }
        if let clips = arguments.clips {
            let unknown = clips.filter { !CharacterClips.stockNames.contains($0) }
            guard unknown.isEmpty else {
                throw CommandError.failed("No stock clip \(unknown.joined(separator: ", ")) (stock clips: \(CharacterClips.stockNames.joined(separator: ", ")))")
            }
            c.clips = CharacterClips.stockNames.filter(clips.contains)
        }
        if let clip = arguments.defaultClip {
            guard CharacterClips.stockNames.contains(clip) else { throw CommandError.failed("No stock clip \(clip)") }
            c.defaultClip = clip
        }
        if let smooth = arguments.smooth { c.smooth = smooth }
        if let segments = arguments.segments { c.segments = min(max(segments, 6), 32) }
        return c
    }

    static func region(_ name: String) throws -> CharacterRegion {
        guard let region = CharacterRegion(rawValue: name) else {
            throw CommandError.failed("No color region '\(name)' (regions: \(CharacterRegion.allCases.map(\.rawValue).joined(separator: ", ")))")
        }
        return region
    }
}

public enum CharacterOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// A clip to preview (idle, walk, run, jump, attack, die); default: the one already playing, else the default clip.
        public var clip: String?
        public init(asset: AssetReference? = nil, path: String? = nil, clip: String? = nil) {
            self.asset = asset
            self.path = path
            self.clip = clip
        }
    }

    public static let id: CommandID = "character.open"
    public static let title = "Open in Character Builder"
    public static let doc = "Opens a .character file in the editor's Character Builder tab (the character alone in a viewport playing a clip, with the template, proportion sliders, colors, attachments and clip buttons) and brings the tab to the front; `clip` picks the clip it plays. view.screenshot {source: \"panel\", panel: \"characterBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, character) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        if let clip = arguments.clip, !character.clipNames.contains(clip) {
            throw CommandError.failed("\(title): the character has no clip '\(clip)' (clips: \(character.clipNames.joined(separator: ", ")))")
        }
        session.openCharacter = id
        session.characterPreviewClip = arguments.clip
        session.onOpenCharacter?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum CharacterBonesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// humanoid (default), quadruped, bird or blob.
        public var template: CharacterTemplate?
        /// Proportion name → multiplier, for the rest positions.
        public var proportions: [String: Float]?
        public init(template: CharacterTemplate? = nil, proportions: [String: Float]? = nil) {
            self.template = template
            self.proportions = proportions
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var template: CharacterTemplate
        public var bones: [CharacterBoneInfo]
        /// The bone hand-held gear goes on.
        public var handBone: String
        public var clips: [String]
    }

    public static let id: CommandID = "character.bones"
    public static let title = "Character Bones"
    public static let doc = "Lists a body template's bones (name, parent, rest position in meters; +Y up, +Z forward, \".L\" on the character's left at +X) and stock clips, without a file: pick bones for character.edit {attach}."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let template = arguments.template ?? .humanoid
        let character = try CharacterEditCommand.edited(CharacterBuild(template: template), with: .init(proportions: arguments.proportions))
        return Result(template: template, bones: CharacterGetCommand.bones(character.rig), handBone: template.handBone,
                      clips: CharacterClips.stockNames)
    }
}

public enum ViewAnimateInEditModeCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// On or off; omitted: toggles.
        public var on: Bool?
        public init(on: Bool? = nil) { self.on = on }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var on: Bool
        /// Animators the preview plays (counted at the next frame after turning it on).
        public var animators: Int
    }

    public static let id: CommandID = "view.animateInEditMode"
    public static let title = "Animate in Scene View"
    public static let doc = """
        Turns on (or off, or toggles without `on`) animation in the edit-mode Scene view: characters, glTF models with \
        asset clips and animation graphs play their Animator (from its initial state, e.g. a character's idle) while you \
        edit, without entering play mode. Editor-only and never saved: the pose is shown, not written into the scene, so \
        saving, undo and the inspector see the authored transforms. Returns whether it is on and how many animators play.
        """
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let preview = session.editAnimation
        preview.isEnabled = arguments.on ?? !preview.isEnabled
        if preview.isEnabled && !session.isPlaying { preview.advance(session.world, assets: session.assets, dt: 0) }
        return Result(on: preview.isEnabled, animators: preview.count)
    }
}
