import Engine
import Foundation

/// The Post-FX builder tools: `postfx.new`, `postfx.get`, `postfx.set`, `postfx.edit`,
/// `postfx.assign` (and `postfx.open` in PostFXWorkspace.swift).
@MainActor
public enum EditorPostFXCommands {
    public static let all: [any EditorCommand.Type] = [
        PostFXNewCommand.self,
        PostFXGetCommand.self,
        PostFXSetCommand.self,
        PostFXEditCommand.self,
        PostFXAssignCommand.self,
        PostFXOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A post-fx profile is a camera look; every key is optional (missing = neutral): tonemapper none|reinhard|neutral|aces, \
        exposure (EV stops, -10..10), autoExposure (bool), autoExposureMin/autoExposureMax (EV), adaptationSpeed, bloom (bool), \
        bloomIntensity (0..1), color grading applied after tonemapping: contrast (0.5..1.5, 1 = unchanged), lift [r,g,b] (adds to \
        shadows, 0 = unchanged), gamma [r,g,b] (midtone, 1 = unchanged), gain [r,g,b] (multiplier, 1 = unchanged), saturation \
        (0..2, 1 = unchanged), vignette (0..1), vignetteSoftness (0..1), chromaticAberration (0..1), filmGrain (0..1). Presets: \
        \(PostFXPreset.allCases.map(\.rawValue).joined(separator: ", ")). Assign a profile to a camera (Camera.postFX) or a \
        PostFXVolume component (profile, shape box|sphere, size, radius, blendDistance, priority, weight, isGlobal) with postfx.assign.
        """
}

extension EditorSession {
    /// Writes a post-fx profile to "`name`.postfx" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createPostFXAsset(in folder: String, name: String = "New Look", profile: PostProcessSettings = PostFXPreset.neutral.settings) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Post-FX") else {
            log.error("New Post-FX: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".postfx"))
        do {
            let id = try assets.createPostFX(profile, at: path)
            log.info("Created post-fx profile \(path)")
            return id
        } catch {
            log.error("New Post-FX failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.postfx` file.
    public func isPostFXFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == PostFXImporter().name
    }

    /// Replaces the contents of the profile `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyPostFX(_ profile: PostProcessSettings, to id: AssetID, label: String = "Edit Post-FX") -> [String]? {
        guard let assets, let old = assets.postFX(of: id) else {
            log.error("\(label): \(id) isn't a readable .postfx file")
            return nil
        }
        guard old != profile else { return [] }
        let command = PostFXFileEditCommand(asset: id, old: old, new: profile, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes profile edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct PostFXFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: PostProcessSettings
    public let new: PostProcessSettings
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: PostProcessSettings, new: PostProcessSettings, in database: AssetDatabase, label: String = "Edit Post-FX") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ profile: PostProcessSettings) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writePostFX(profile, to: asset)
    }
}

/// Arguments naming a `.postfx` file.
public protocol PostFXTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    func resolvePostFX(_ target: some PostFXTarget, _ title: String) throws -> (AssetID, PostProcessSettings) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isPostFXFile(id), let profile = assets?.postFX(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .postfx file")
        }
        return (id, profile)
    }
}

/// What the editing tools return.
public struct PostFXResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The profile's contents, every field.
    public var settings: PostProcessSettings
    /// Out-of-range values and import problems.
    public var warnings: [String]
}

extension PostFXResult {
    @MainActor init(_ id: AssetID, _ profile: PostProcessSettings, warnings: [String] = [], in session: EditorSession) {
        let record = session.assets?.record(id)
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", settings: profile,
                  warnings: Array(Set(profile.validationWarnings() + warnings)).sorted()
                      + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum PostFXNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Look" (the file gets ".postfx").
        public var name: String?
        /// neutral, cinematic, warm, cold, noir or retro (default neutral).
        public var preset: String?
        /// Keys to override on top of the preset.
        public var settings: JSONValue?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, settings: JSONValue? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.settings = settings
        }
    }

    public static let id: CommandID = "postfx.new"
    public static let title = "New Post-FX"
    public static let doc = "Writes a .postfx profile in `folder` (default: the Assets root) from a `preset` (default neutral) with optional `settings` overrides, and imports it. Returns the asset, its contents and warnings. Assign it with postfx.assign, tweak it with postfx.edit. " + EditorPostFXCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PostFXResult {
        var profile = try PostFXEditCommand.preset(named: arguments.preset) ?? PostFXPreset.neutral.settings
        if let settings = arguments.settings { profile = try PostFXEditCommand.merged(profile, with: settings) }
        let id = try session.commands.require(session.createPostFXAsset(in: arguments.folder ?? "", name: arguments.name ?? "New Look", profile: profile), title)
        return PostFXResult(id, profile, in: session)
    }
}

public enum PostFXGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PostFXTarget {
        public var asset: AssetReference?
        /// Or the path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "postfx.get"
    public static let title = "Get Post-FX"
    public static let doc = "Reads a .postfx profile: every setting (defaults included) and warnings about out-of-range values."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PostFXResult {
        let (id, profile) = try session.resolvePostFX(arguments, title)
        return PostFXResult(id, profile, in: session)
    }
}

public enum PostFXSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PostFXTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var settings: PostProcessSettings?
        /// Or start from a preset (neutral, cinematic, warm, cold, noir, retro) instead.
        public var preset: String?
        public init(asset: AssetReference? = nil, path: String? = nil, settings: PostProcessSettings? = nil, preset: String? = nil) {
            self.asset = asset
            self.path = path
            self.settings = settings
            self.preset = preset
        }
    }

    public static let id: CommandID = "postfx.set"
    public static let title = "Set Post-FX"
    public static let doc = "Replaces a .postfx profile's whole contents (`settings`, or a `preset`) and reimports it; cameras and volumes using it update. Undoable. For a few changes, postfx.edit is shorter. " + EditorPostFXCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PostFXResult {
        let (id, _) = try session.resolvePostFX(arguments, title)
        guard let profile = try arguments.settings ?? PostFXEditCommand.preset(named: arguments.preset) else {
            throw CommandError.failed("\(title): give `settings` or `preset`")
        }
        let warnings = try session.commands.require(session.applyPostFX(profile, to: id, label: title), title)
        return PostFXResult(id, profile, warnings: warnings, in: session)
    }
}

public enum PostFXEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PostFXTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Start over from this preset before applying `changes`.
        public var preset: String?
        /// Keys to change, e.g. {"vignette": 0.4, "gain": [1.1, 1, 0.9]}; other keys keep their values.
        public var changes: JSONValue?
        public init(asset: AssetReference? = nil, path: String? = nil, preset: String? = nil, changes: JSONValue? = nil) {
            self.asset = asset
            self.path = path
            self.preset = preset
            self.changes = changes
        }
    }

    public static let id: CommandID = "postfx.edit"
    public static let title = "Edit Post-FX"
    public static let doc = "Changes some settings of a .postfx profile in one undoable step: optionally restart from a `preset`, then set the keys in `changes` (others keep their values). Returns the full contents and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PostFXResult {
        let (id, original) = try session.resolvePostFX(arguments, title)
        let profile = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyPostFX(profile, to: id, label: title), title)
        return PostFXResult(id, profile, warnings: warnings, in: session)
    }

    /// `profile` with the edits applied (pure, for tests).
    public static func edited(_ profile: PostProcessSettings, with arguments: Arguments) throws -> PostProcessSettings {
        var result = try preset(named: arguments.preset) ?? profile
        if let changes = arguments.changes { result = try merged(result, with: changes) }
        return result
    }

    /// The preset called `name` (nil for nil); throws for an unknown name.
    static func preset(named name: String?) throws -> PostProcessSettings? {
        guard let name else { return nil }
        guard let preset = PostFXPreset(rawValue: name.lowercased()) else {
            throw CommandError.failed("Unknown preset '\(name)'; use \(PostFXPreset.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        return preset.settings
    }

    /// `profile` with the object `changes`' keys replaced.
    static func merged(_ profile: PostProcessSettings, with changes: JSONValue) throws -> PostProcessSettings {
        guard case .object(let fields) = changes else { throw CommandError.failed("settings/changes must be an object of keys") }
        guard case .object(var current)? = try? JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(profile)) else { return profile }
        for key in fields.keys where current[key] == nil { throw CommandError.failed("Unknown post-fx key '\(key)'") }
        for (key, value) in fields { current[key] = value }
        do {
            return try JSONDecoder().decode(PostProcessSettings.self, from: JSONEncoder().encode(JSONValue.object(current)))
        } catch {
            throw CommandError.failed("Invalid post-fx value: \(error)")
        }
    }
}

public enum PostFXAssignCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PostFXTarget {
        /// The .postfx file ("" to clear: give neither `asset` nor `path` and `clear` true).
        public var asset: AssetReference?
        public var path: String?
        /// A Camera or PostFXVolume entity (default: the scene's active camera).
        public var entity: EntityID?
        /// Clear the assignment instead.
        public var clear: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, entity: EntityID? = nil, clear: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.entity = entity
            self.clear = clear
        }
    }

    public static let id: CommandID = "postfx.assign"
    public static let title = "Assign Post-FX"
    public static let doc = "Assigns a .postfx profile to a camera (sets Camera.postFX; default: the active camera) or to a PostFXVolume entity (sets its profile). Undoable. A camera's profile replaces the scene's PostProcess component; volumes blend over it by priority."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let world = session.world
        var value = ""
        var path = ""
        if arguments.clear != true {
            let (id, _) = try session.resolvePostFX(arguments, title)
            value = AssetReference(id).description
            path = session.assets?.path(of: id) ?? ""
        }
        let entity: Entity
        if let id = arguments.entity {
            entity = try world.require(id)
        } else if let camera = RenderPrep.findCamera(in: world)?.entity {
            entity = camera
        } else {
            throw CommandError.failed("\(title): the scene has no camera; pass `entity`")
        }
        guard let entityID = world.ensureID(of: entity) else { throw CommandError.failed("\(title): entity has no id") }
        let component: String, field: String
        if world.has(PostFXVolume.self, for: entity) {
            (component, field) = (PostFXVolume.componentName, "profile")
        } else if world.has(Camera.self, for: entity) {
            (component, field) = (Camera.componentName, "postFX")
        } else {
            throw CommandError.failed("\(title): the entity has neither a Camera nor a PostFXVolume")
        }
        _ = try session.commands.require(
            session.run(ComponentSetFieldCommand.self, .init(entity: entityID, component: component, path: field, value: .string(value))), title)
        return PathResult(path: path)
    }
}
