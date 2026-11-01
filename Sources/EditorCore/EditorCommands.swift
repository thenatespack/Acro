import Engine
import EngineMCP
import Foundation

// The built-in editor commands (see EditorCommand.swift). Each one is a thin, typed front for an
// `EditorSession` action: arguments name entities by `EntityID`, assets by `AssetReference` /
// `AssetID` or by path relative to `Assets/`, all of which encode as strings in JSON. Commands
// that act on "the selection" (duplicate, delete, frame) do exactly what the UI does; select
// first with `selection.set` to aim them.

/// Every built-in command, in the order of the README's table.
@MainActor
public enum BuiltinCommands {
    public static let all: [any EditorCommand.Type] = [
        SceneNewCommand.self, SceneOpenCommand.self, SceneSaveCommand.self, SceneSaveAsCommand.self,
        EditUndoCommand.self, EditRedoCommand.self, EditBatchCommand.self, EditBeginBatchCommand.self, EditEndBatchCommand.self,
        PlayStartCommand.self, PlayStopCommand.self, PlayToggleCommand.self, PlayPauseCommand.self, PlayStepCommand.self,
        PlaySetTimeScaleCommand.self, PlayStateCommand.self, ViewGameCameraCommand.self,
        InputInjectCommand.self, InputClearCommand.self, InputStateCommand.self,
        ToolSetCommand.self, ToolSnappingCommand.self,
        ProjectOpenCommand.self, ProjectNewCommand.self, ProjectCloseCommand.self,
        LayoutResetCommand.self, ViewAppearanceCommand.self, ViewFrameSelectionCommand.self,
        ViewScreenshotCommand.self, ViewPickCommand.self, SceneRaycastCommand.self,
        SelectionSetCommand.self, SelectionClearCommand.self, SelectionGetCommand.self,
        SceneHierarchyCommand.self, EntityFindCommand.self, EntityGetCommand.self,
        EntityCreateCommand.self, EntityDuplicateCommand.self, EntityDeleteCommand.self, EntityRenameCommand.self,
        EntityReparentCommand.self, TransformSetCommand.self, TransformLookAtCommand.self,
        ComponentTypesCommand.self, ComponentAddCommand.self, ComponentRemoveCommand.self, ComponentSetFieldCommand.self,
        AssetImportCommand.self, AssetNewFolderCommand.self, AssetNewMaterialCommand.self, AssetRenameCommand.self,
        AssetMoveCommand.self, AssetDeleteCommand.self, AssetExtractMaterialsCommand.self, AssetApplySettingsCommand.self,
        AssetInstantiateCommand.self, AssetAssignCommand.self, MaterialSetCommand.self,
        AssetListCommand.self, AssetGetCommand.self, AssetReimportCommand.self, AssetWaitForImportsCommand.self,
        AssetSelectCommand.self, MaterialGetCommand.self,
        PrefabCreateCommand.self, PrefabOverridesCommand.self, PrefabApplyCommand.self, PrefabRevertCommand.self,
        PrefabUnpackCommand.self, PrefabCreateVariantCommand.self,
        LogReadCommand.self, StatsGetCommand.self, DiagnosticsGetCommand.self,
    ] + EditorUICommands.all + EditorSafetyCommands.all + EditorGameModuleCommands.all + EditorBuildCommands.all
      + EditorRecoveryCommands.all + EditorNetCommands.all + EditorLauncherCommands.all + EditorScriptCommands.all
      + EditorProceduralTextureCommands.all
}

extension CommandID {
    // The ids the editor's shortcuts are bound to.
    public static let undo: CommandID = "edit.undo"
    public static let redo: CommandID = "edit.redo"
    public static let save: CommandID = "scene.save"
    public static let duplicate: CommandID = "entity.duplicate"
    public static let delete: CommandID = "entity.delete"
    public static let focusSelection: CommandID = "view.frameSelection"
    public static let clearSelection: CommandID = "selection.clear"
    public static let togglePlay: CommandID = "play.toggle"
    public static let togglePause: CommandID = "play.pause"
    public static let step: CommandID = "play.step"
    public static let toggleGameCamera: CommandID = "view.gameCamera"
    public static let importAsset: CommandID = "asset.import"
}

/// A result holding one path.
public struct PathResult: Codable, Equatable, Sendable {
    public var path: String
}

/// A result holding entity ids (new or affected roots).
public struct EntitiesResult: Codable, Equatable, Sendable {
    public var entities: [EntityID]
}

// MARK: Scene

public enum SceneNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// "starter" (default): a camera, a sun, a floor and a few primitives. "empty": no entities at all.
        public var template: String?
        public init(template: String? = nil) { self.template = template }
    }

    public static let id: CommandID = "scene.new"
    public static let title = "New Scene"
    public static let doc = "Replaces the open scene with a new one: the starter scene (default) or, with `template: \"empty\"`, a scene with no entities. Clears the undo history; unsaved changes are lost. Not while playing."
    public static let isDestructive = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        switch arguments.template ?? "starter" {
        case "starter": try session.commands.check(session.newDocument(), title)
        case "empty": try session.commands.check(session.newDocument(empty: true), title)
        default: throw CommandError.failed("Unknown scene template '\(arguments.template ?? "")': use \"starter\" or \"empty\"")
        }
        return NoResult()
    }
}

extension EditorSession {
    /// New Scene (the starter scene) for the UI.
    @discardableResult
    public func run(_ command: SceneNewCommand.Type) -> NoResult? { run(command, .init()) }
}

extension CommandRegistry {
    @discardableResult
    public func run(_ command: SceneNewCommand.Type) throws -> NoResult { try run(command, .init()) }
}

public enum SceneOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A scene file (`~` expanded; relative to the project folder, or the working directory without a project). With a project open, a path relative to `Assets/` ("Scenes/Main.scene", as in build.scenes) works too. Scenes must be inside the project folder over MCP.
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "scene.open"
    public static let title = "Open Scene"
    public static let doc = "Replaces the open scene with the scene file at `path` and clears the undo history. Not while playing. With a project open, `path` is relative to the project folder (Assets/Scenes/Main.scene) or to Assets/ (Scenes/Main.scene, the form Project.json's build.scenes uses); only scenes inside the project folder can be opened."
    public static let isDestructive = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        try session.commands.check(session.open(path: arguments.path), title)
        return PathResult(path: session.document.url?.path ?? arguments.path)
    }
}

public enum SceneSaveCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Where to save a scene that has no file yet (ignored when it has one).
        public var path: String?
        public init(path: String? = nil) { self.path = path }
    }

    public static let id: CommandID = "scene.save"
    public static let title = "Save Scene"
    public static let doc = "Saves the scene to its file, or to `path` when it has never been saved. Not while playing. Scenes are only saved inside the project folder (or the editor's start folder without a project); relative paths are relative to it, and a scene opened from elsewhere must be saved with scene.saveAs."
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when `path` names an existing file that isn't the scene's own (saving to the scene's own file or to a new file needs no confirm)"
    public static func needsConfirmation(_ arguments: Arguments, in session: EditorSession) -> Bool {
        session.document.url == nil && session.savingOverOtherFile(at: arguments.path ?? "")
    }
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        try session.commands.check(session.save(fallbackPath: arguments.path), title)
        return PathResult(path: session.document.url?.path ?? "")
    }
}

public enum SceneSaveAsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "scene.saveAs"
    public static let title = "Save Scene As"
    public static let doc = "Saves the scene to `path`, which becomes its file. Not while playing. `path` must be inside the project folder (or the editor's start folder without a project); relative paths are relative to it."
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when `path` is an existing file that isn't the scene's own (a new file or the scene's own file needs no confirm)"
    public static func needsConfirmation(_ arguments: Arguments, in session: EditorSession) -> Bool {
        session.savingOverOtherFile(at: arguments.path)
    }
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        try session.commands.check(session.save(as: arguments.path), title)
        return PathResult(path: session.document.url?.path ?? arguments.path)
    }
}

// MARK: Undo

public enum EditUndoCommand: EditorCommand {
    public static let id: CommandID = .undo
    public static let title = "Undo"
    public static let doc = "Undoes the last recorded step (a whole command, gizmo drag or inspector gesture)."
    public static func isAvailable(in session: EditorSession) -> Bool { session.undo.canUndo }
    public static func unavailableReason(in session: EditorSession) -> String? { undoBlockedReason(session) ?? "nothing to undo" }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.performUndo(), title)
        return NoResult()
    }
}

public enum EditRedoCommand: EditorCommand {
    public static let id: CommandID = .redo
    public static let title = "Redo"
    public static let doc = "Redoes the last undone step."
    public static func isAvailable(in session: EditorSession) -> Bool { session.undo.canRedo }
    public static func unavailableReason(in session: EditorSession) -> String? { undoBlockedReason(session) ?? "nothing to redo" }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.performRedo(), title)
        return NoResult()
    }
}

/// Why undo and redo are off apart from an empty history: a batch or a drag is open, or play mode.
@MainActor
private func undoBlockedReason(_ session: EditorSession) -> String? {
    if session.batch != nil { return "a batch is open (edit.endBatch ends it)" }
    if session.undo.isGrouping { return "an edit is in progress in the editor (a drag)" }
    return session.isPlaying ? EditorError.playing.description : nil
}

// MARK: Play mode

public enum PlayStartCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Start paused, before the first frame (then play.step runs frames deterministically).
        public var paused: Bool?
        public init(paused: Bool? = nil) { self.paused = paused }
    }

    public static let id: CommandID = "play.start"
    public static let title = "Play"
    public static let doc = "Snapshots the scene and runs its systems (with physics when it has colliders); edits while playing apply to the live world and are discarded on stop. `paused` starts paused, for play.step."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "already playing" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PlayStateResult {
        session.play(paused: arguments.paused ?? false)
        return session.playStateResult
    }
}

public enum PlayStopCommand: EditorCommand {
    public static let id: CommandID = "play.stop"
    public static let title = "Stop"
    public static let doc = "Leaves play mode, restoring the scene as it was when Play was pressed."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing" }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.stop()
        return NoResult()
    }
}

public enum PlayToggleCommand: EditorCommand {
    public static let id: CommandID = .togglePlay
    public static let title = "Play / Stop"
    public static let doc = "Play when editing, Stop when playing."
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.togglePlay()
        return NoResult()
    }
}

// MARK: Tool

public enum ToolSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// "move", "rotate" or "scale".
        public var tool: EditorTool
        public init(tool: EditorTool) { self.tool = tool }
    }

    public static let id: CommandID = "tool.set"
    public static let title = "Select Tool"
    public static let doc = "Picks the viewport gizmo: `tool` is \"move\", \"rotate\" or \"scale\"."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        session.tool = arguments.tool
        return NoResult()
    }
}

public enum ToolSnappingCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// On or off; omitted toggles it.
        public var enabled: Bool?
        public init(enabled: Bool? = nil) { self.enabled = enabled }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var enabled: Bool
    }

    public static let id: CommandID = "tool.snapping"
    public static let title = "Snapping"
    public static let doc = "Turns gizmo snapping on or off (`enabled`; omitted toggles it): drags move in 0.5-unit steps, rotate by 15° and scale by 0.1. Holding Cmd (Ctrl elsewhere) during a drag inverts it."
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        session.snapping = arguments.enabled ?? !session.snapping
        return Result(enabled: session.snapping)
    }
}

// MARK: Project

public enum ProjectOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project folder or its `Project.json` (or the name of a project in project.recent.list).
        public var path: String
        /// Also open the scene last used in the project (else its first build scene), as the
        /// launcher does; replaces the open scene. Default false: the scene stays.
        public var openLastScene: Bool?
        public init(path: String, openLastScene: Bool? = nil) {
            self.path = path
            self.openLastScene = openLastScene
        }
    }

    public static let id: CommandID = "project.open"
    public static let title = "Open Project"
    public static let doc = "Opens the project at `path` (or a recent project by name), scans its assets and imports what changed (in the background); the project goes to the top of project.recent.list and the launcher closes. The scene stays open unless `openLastScene` is true. Returns the project's root folder."
    public static let isIdempotent = true
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when `openLastScene` is true and the open scene has unsaved changes"
    public static func needsConfirmation(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.openLastScene == true && session.document.isDirty
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        var path = arguments.path
        // A recent project's name, when there is no such folder.
        if !FileManager.default.fileExists(atPath: session.resolvedFileURL(forPath: path).path),
           let entry = session.recentProjects.entry(path) {
            path = entry.path
        }
        if arguments.openLastScene == true, session.isPlaying { throw CommandError.failed(EditorError.playing.description) }
        try session.commands.check(session.openProject(path: path), title)
        if arguments.openLastScene == true, let project = session.project {
            let entry = session.recentProjects.entry(project.root.path)
            let candidates = [entry?.lastScene].compactMap { $0 }
                + (project.settings.build?.scenes ?? []).map { project.url(forAssetPath: $0).path }
            if let scene = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }),
               session.document.url?.standardizedFileURL.path != scene {
                session.open(path: scene)
            }
        }
        return PathResult(path: session.project?.root.path ?? "")
    }
}

public enum ProjectNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A new folder, or an existing one without a project. Default: `location`/`name`.
        public var path: String?
        /// The project's name (Project.json); default: the folder's. With `location` it names the folder too.
        public var name: String?
        /// The folder to create the project in (with `name`); default: the last one used, else ~/Games.
        public var location: String?
        /// What it starts with: `empty`, `starter` (the starter scene in Scenes/Main.scene) or
        /// `game` (a copy of Projects/SampleGame with its game code). With a template its scene
        /// is opened in place of the open one; without (the default), only the folders are made
        /// and the scene stays.
        public var template: ProjectTemplate?
        public init(path: String? = nil, name: String? = nil, location: String? = nil, template: ProjectTemplate? = nil) {
            self.path = path
            self.name = name
            self.location = location
            self.template = template
        }
    }

    public static let id: CommandID = "project.new"
    public static let title = "New Project"
    public static let doc = "Creates a project (Project.json, Assets/, Library/) at `path`, or in `location` as a folder called `name`, and opens it (it goes to the top of project.recent.list and the launcher closes). With `template` (empty, starter, game) it is filled from the template and its scene opened. Paths outside the project folder (the editor's start folder without one) are refused for AI clients. Returns its root folder."
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when a `template` is given and the open scene has unsaved changes (the template's scene replaces it)"
    public static func needsConfirmation(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.template != nil && session.document.isDirty
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let path = try folder(for: arguments, in: session)
        try session.commands.check(session.newProject(path: path, name: arguments.name, template: arguments.template), title)
        if arguments.path == nil, let location = arguments.location ?? session.recentProjects.newProjectLocation {
            session.recentProjects.newProjectLocation = location
        }
        return PathResult(path: session.project?.root.path ?? "")
    }

    /// The folder to create: `path`, else `location` (or the last one) / `name`.
    static func folder(for arguments: Arguments, in session: EditorSession) throws -> String {
        if let path = arguments.path, !path.trimmingCharacters(in: .whitespaces).isEmpty { return path }
        guard let name = arguments.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            throw CommandError.failed("New Project needs a `path`, or a `name` (and a `location`)")
        }
        guard !name.contains("/"), !name.contains("\\"), name != ".", name != ".." else {
            throw CommandError.failed("The project name '\(name)' can't be a folder name (no slashes)")
        }
        let location = arguments.location ?? session.recentProjects.newProjectLocation ?? RecentProjectList.defaultNewProjectLocation()
        let trimmed = location.trimmingCharacters(in: .whitespaces)
        return (trimmed.isEmpty ? "." : trimmed) + "/" + name
    }
}

// MARK: Host

public enum LayoutResetCommand: EditorCommand {
    public static let id: CommandID = "layout.reset"
    public static let title = "Reset Layout"
    public static let doc = "Restores the default panel layout. Needs the editor window."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.host != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noWindowReason }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.host?.resetLayout()
        return NoResult()
    }
}

public enum ViewAppearanceCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A theme: Dark, Light or High Contrast (case-insensitive).
        public var theme: String?
        /// The UI zoom, 0.85...2 (1 = 100%).
        public var uiScale: Float?
        public init(theme: String? = nil, uiScale: Float? = nil) {
            self.theme = theme
            self.uiScale = uiScale
        }
    }

    public static let id: CommandID = "view.appearance"
    public static let title = "Appearance"
    public static let doc = """
        The editor's theme and UI zoom (the toolbar's View menu): sets `theme` (Dark, Light or High Contrast; the \
        engine's Game preset is for game UI and is refused) and / or `uiScale` (0.85-2) when given and saves them in \
        the prefs, then returns them. A zoom the window is too small for is lowered while it lasts (`effectiveUIScale`). Needs the editor window.
        """
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.host != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noWindowReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EditorAppearance {
        guard let appearance = try session.host?.appearance(theme: arguments.theme, uiScale: arguments.uiScale) else {
            throw CommandError.failed("Appearance: \(noWindowReason)")
        }
        return appearance
    }
}

public enum ViewFrameSelectionCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Frame these instead of the selection (which stays as it is).
        public var entities: [EntityID]?
        public init(entities: [EntityID]? = nil) { self.entities = entities }
    }

    public static let id: CommandID = .focusSelection
    public static let title = "Frame Selection"
    public static let doc = "Moves the viewport camera to frame the selected entities, or `entities` (without selecting them). Needs the editor window."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool {
        session.host != nil && !session.selection.entities(in: session.world).isEmpty
    }
    public static func isAvailable(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.entities != nil ? session.host != nil : isAvailable(in: session)
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.host == nil ? noWindowReason : noSelectionReason
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        if let ids = arguments.entities {
            session.host?.frame(try ids.map { try session.world.require($0) })
        } else {
            session.host?.frameSelection()
        }
        return NoResult()
    }
}

// MARK: Selection

public enum SelectionSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entities: [EntityID]
        /// The one the inspector shows (default: the last).
        public var primary: EntityID?
        public init(entities: [EntityID], primary: EntityID? = nil) {
            self.entities = entities
            self.primary = primary
        }
    }

    public static let id: CommandID = "selection.set"
    public static let title = "Select"
    public static let doc = "Selects exactly `entities` (empty clears), with `primary` shown in the inspector."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        for id in arguments.entities + (arguments.primary.map { [$0] } ?? []) where session.world.entity(for: id) == nil {
            throw UndoError.entityNotFound(id)
        }
        session.selection.set(arguments.entities, primary: arguments.primary)
        // Selecting the entity that already was selected (clicking its row again while an asset
        // is in the inspector) changes nothing in the selection, but shows the entity again.
        if !arguments.entities.isEmpty { session.inspectedAsset = nil }
        return NoResult()
    }
}

public enum SelectionClearCommand: EditorCommand {
    public static let id: CommandID = .clearSelection
    public static let title = "Clear Selection"
    public static let doc = "Deselects everything."
    public static let isIdempotent = true
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.selection.clear()
        return NoResult()
    }
}

// MARK: Entities

public enum EntityCreateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// "empty", "cube", "sphere", "plane", "cylinder", "capsule", "cone" or "torus".
        public var template: EntityTemplate
        /// Position (in `parent`'s space with a parent; default: the origin).
        public var position: Vec3?
        /// Default: the template's title, numbered when taken ("Cube 2").
        public var name: String?
        /// Create it as this entity's last child (default: a root).
        public var parent: EntityID?
        public init(template: EntityTemplate, position: Vec3? = nil, name: String? = nil, parent: EntityID? = nil) {
            self.template = template
            self.position = position
            self.name = name
            self.parent = parent
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entity: EntityID
    }

    public static let id: CommandID = "entity.create"
    public static let title = "Create Entity"
    public static let doc = "Creates an entity from `template` at `position` ([x, y, z]), named `name` (default: after the template, \"Cube 2\" when taken), as a root or under `parent`, and selects it."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if let parent = arguments.parent { _ = try session.world.require(parent) }
        return Result(entity: try session.commands.require(session.create(arguments.template, at: arguments.position ?? .zero,
                                                                          name: arguments.name, parent: arguments.parent), title))
    }
}

/// Arguments of commands that act on the selection unless given entities.
public struct EntitiesArguments: Codable, Equatable, Sendable {
    /// Act on these instead of the selection.
    public var entities: [EntityID]?
    public init(entities: [EntityID]? = nil) { self.entities = entities }

    /// The entities named, or the selection's top-level ones; throws for a missing one.
    @MainActor func resolve(in session: EditorSession) throws -> [Entity] {
        guard let entities else { return session.selection.topLevelEntities(in: session.world) }
        return try entities.map { try session.world.require($0) }
    }
}

public enum EntityDuplicateCommand: EditorCommand {
    public typealias Arguments = EntitiesArguments
    public static let id: CommandID = .duplicate
    public static let title = "Duplicate"
    public static let doc = "Duplicates the selected entities (or `entities`) with their children next to the originals and selects the copies. Returns the copies."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.selection.entities(in: session.world).isEmpty }
    public static func isAvailable(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.entities != nil || isAvailable(in: session)
    }
    public static func unavailableReason(in session: EditorSession) -> String? { noSelectionReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EntitiesResult {
        let originals = try arguments.resolve(in: session)
        let copies = session.duplicate(originals)
        try session.commands.check(!copies.isEmpty, title)
        return EntitiesResult(entities: copies)
    }
}

public enum EntityDeleteCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// How many subtrees were deleted.
        public var count: Int
    }

    public typealias Arguments = EntitiesArguments
    public static let id: CommandID = .delete
    public static let title = "Delete"
    public static let doc = "Deletes the selected entities (or `entities`) with their children. The editor asks for confirmation before running it; the command itself doesn't."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.selection.entities(in: session.world).isEmpty }
    public static func isAvailable(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.entities != nil || isAvailable(in: session)
    }
    public static func unavailableReason(in session: EditorSession) -> String? { noSelectionReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let doomed = try arguments.resolve(in: session)
        let count = session.delete(doomed)
        try session.commands.check(count > 0, title)
        return Result(count: count)
    }
}

public enum EntityRenameCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        public var name: String
        public init(entity: EntityID, name: String) {
            self.entity = entity
            self.name = name
        }
    }

    public static let id: CommandID = "entity.rename"
    public static let title = "Rename"
    public static let doc = "Sets the entity's `Name` (adding one if it has none)."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.rename(arguments.entity, to: arguments.name), title)
        return NoResult()
    }
}

public enum EntityReparentCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Moved in this order.
        public var entities: [EntityID]
        /// The new parent; nil makes them roots.
        public var parent: EntityID?
        /// Where among the parent's children (or the roots) once the moved ones are taken out;
        /// nil appends.
        public var index: Int?
        public init(entities: [EntityID], parent: EntityID?, index: Int? = nil) {
            self.entities = entities
            self.parent = parent
            self.index = index
        }
    }

    public static let id: CommandID = "entity.reparent"
    public static let title = "Reparent"
    public static let doc = "Makes `entities` children of `parent` (nil: roots) at `index` (nil: last), keeping their world transforms."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let world = session.world
        for id in arguments.entities + (arguments.parent.map { [$0] } ?? []) where world.entity(for: id) == nil {
            throw UndoError.entityNotFound(id)
        }
        let moved = Set(arguments.entities)
        let siblings = arguments.parent.flatMap { world.entity(for: $0) }.map { world.children(of: $0) } ?? world.roots
        let remaining = siblings.filter { world.id(of: $0).map { !moved.contains($0) } ?? true }.count
        let index = min(max(arguments.index ?? remaining, 0), remaining)
        try session.commands.check(session.move(arguments.entities, to: arguments.parent, at: index), title)
        return NoResult()
    }
}

public enum TransformSetCommand: EditorCommand {
    public struct Change: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// The new local transform.
        public var transform: Transform
        /// What undo restores (default: the transform before the command). A gesture that
        /// already moved the entity live passes where it started.
        public var previous: Transform?
        public init(entity: EntityID, transform: Transform, previous: Transform? = nil) {
            self.entity = entity
            self.transform = transform
            self.previous = previous
        }
    }

    public struct Arguments: Codable, Equatable, Sendable {
        public var changes: [Change]
        /// The undo step's name (default "Transform").
        public var label: String?
        public init(changes: [Change], label: String? = nil) {
            self.changes = changes
            self.label = label
        }
    }

    public static let id: CommandID = "transform.set"
    public static let title = "Set Transform"
    public static let doc = "Sets the local Transform (position, rotation as a quaternion [x, y, z, w], scale) of each entity in `changes`, as one undo step. The gizmo records its drags with it."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let world = session.world
        let label = arguments.label ?? "Transform"
        let commands: [any UndoCommand] = try arguments.changes.map { change in
            let entity = try world.require(change.entity)
            let old = change.previous ?? world.get(Transform.self, for: entity) ?? Transform()
            return SetComponentCommand(id: change.entity, old: old, new: change.transform, label: label)
        }
        guard !commands.isEmpty else { return NoResult() }
        try session.commands.check(session.perform(GroupCommand(label, commands)), title)
        return NoResult()
    }
}

// MARK: Components

public enum ComponentAddCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// A component name from `EditorComponentCatalog` ("MeshRenderer", "Spin"…).
        public var component: String
        public init(entity: EntityID, component: String) {
            self.entity = entity
            self.component = component
        }
    }

    public static let id: CommandID = "component.add"
    public static let title = "Add Component"
    public static let doc = "Adds the default value of an addable component (`EditorComponentCatalog`) to the entity."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.addComponent(named: arguments.component, to: arguments.entity), title)
        return NoResult()
    }
}

public enum ComponentRemoveCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        public var component: String
        public init(entity: EntityID, component: String) {
            self.entity = entity
            self.component = component
        }
    }

    public static let id: CommandID = "component.remove"
    public static let title = "Remove Component"
    public static let doc = "Removes the named component from the entity."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.removeComponent(named: arguments.component, from: arguments.entity), title)
        return NoResult()
    }
}

public enum ComponentSetFieldCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// The component; nil when `path` starts with it ("Transform.position.x").
        public var component: String?
        /// A reflection path: "position", "stats.health", "points.2"; ".x", ".y", ".z", ".w"
        /// (or ".r", ".g", ".b", ".a") after a vector or quaternion set one element.
        public var path: String
        /// The value as JSON: a bool, number or string (also an enum case name), [x, y, z(, w)]
        /// for vectors and quaternions (a rotation can also be {"eulerDegrees": [x, y, z]}, see transform.lookAt to aim), an entity id string, or null for a nil optional.
        public var value: JSONValue
        /// What undo restores (default: the value before the command). A gesture that already
        /// applied its value live passes where it started.
        public var previous: JSONValue?
        /// The undo step's name (default "Edit <path>").
        public var label: String?
        /// Apply without recording an undo step (a live preview during a drag, which ends with
        /// a recorded set).
        public var transient: Bool?
        /// "local" (default) or "world": for Transform's position, rotation and scale (or their
        /// elements), `value` is in world space and the local transform is set to match.
        public var space: TransformSpace?

        public init(entity: EntityID, component: String?, path: String, value: JSONValue, previous: JSONValue? = nil,
                    label: String? = nil, transient: Bool? = nil, space: TransformSpace? = nil) {
            self.entity = entity
            self.component = component
            self.path = path
            self.value = value
            self.previous = previous
            self.label = label
            self.transient = transient
            self.space = space
        }

        /// From reflected values (the inspector's `PropertyEdit`).
        @MainActor public init(entity: EntityID, component: String, path: String, value: FieldValue, previous: FieldValue? = nil,
                    label: String? = nil, transient: Bool? = nil, in world: World) {
            self.init(entity: entity, component: component, path: path, value: value.json(in: world),
                      previous: previous.map { $0.json(in: world) }, label: label, transient: transient)
        }
    }

    public static let id: CommandID = "component.setField"
    public static let title = "Set Field"
    public static let doc = "Sets one field of a component by reflection path (what the inspector edits): `component` \"Transform\" with `path` \"position\", or just `path` \"Transform.position.x\" (a trailing .x/.y/.z/.w sets one element of a vector). A rotation (a quaternion field) is [x, y, z, w] or {\"eulerDegrees\": [x, y, z]} (Z roll, then X pitch, then Y yaw). With `space` \"world\", Transform's position, rotation and scale are given in world space."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let world = session.world
        let entity = try world.require(arguments.entity)
        var componentName = arguments.component ?? ""
        var path = arguments.path
        if arguments.component == nil {
            let parts = path.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                throw CommandError.failed("Give `component`, or start `path` with the component (\"Transform.position\")")
            }
            (componentName, path) = (parts[0], parts[1])
        }
        guard let component = world.component(named: componentName, of: entity) else {
            throw SceneError.noSuchComponent(componentName)
        }
        if arguments.space == .world {
            return try setWorld(path, value: arguments.value, of: entity, arguments, in: session)
        }
        // A whole field, or one element of a vector field.
        var value: FieldValue, old: FieldValue
        if let field = component.field(at: path) {
            value = try FieldValue(json: arguments.value, kind: field.kind, in: world)
            old = try arguments.previous.map { try FieldValue(json: $0, kind: field.kind, in: world) } ?? field.value ?? .null
        } else if let (vectorPath, element) = Self.elementPath(path), let field = component.field(at: vectorPath),
                  let vector = field.value, vector.element(element) != nil {
            path = vectorPath
            value = try vector.replacing(element, with: Self.number(arguments.value))
            old = try arguments.previous.map { try vector.replacing(element, with: Self.number($0)) } ?? vector
        } else {
            throw SceneError.noSuchField(path)
        }
        if arguments.transient == true {
            try world.setField(path, of: componentName, for: entity, to: value)
            return NoResult()
        }
        try session.commands.check(session.perform(SetFieldCommand(id: arguments.entity, component: componentName,
                                                                   path: path, old: old, new: value,
                                                                   label: arguments.label)), title)
        return NoResult()
    }

    /// "position.x" → ("position", 0).
    static func elementPath(_ path: String) -> (String, Int)? {
        guard let dot = path.lastIndex(of: ".") else { return nil }
        let names: [String: Int] = ["x": 0, "y": 1, "z": 2, "w": 3, "r": 0, "g": 1, "b": 2, "a": 3]
        guard let index = names[String(path[path.index(after: dot)...])] else { return nil }
        return (String(path[..<dot]), index)
    }

    static func number(_ json: JSONValue) throws -> Float {
        switch json {
        case .int(let i): return Float(i)
        case .double(let d): return Float(d)
        default: throw SceneError.typeMismatch(path: "value", expected: "a number")
        }
    }

    /// Sets Transform's `path` (position, rotation or scale, or an element) in world space:
    /// the new local transform is the one that puts the entity there under its parent.
    private static func setWorld(_ path: String, value json: JSONValue, of entity: Entity, _ arguments: Arguments,
                                 in session: EditorSession) throws -> NoResult {
        let world = session.world
        let local = world.get(Transform.self, for: entity) ?? Transform()
        let parentMatrix = world.parent(of: entity).map { world.worldMatrix(of: $0) } ?? .identity
        let parent = Transform(matrix: parentMatrix)
        let current = Transform(matrix: parentMatrix * local.matrix)
        let (field, element) = elementPath(path) ?? (path, -1)
        let currentValue: FieldValue
        switch field {
        case "position": currentValue = .vec3(current.position)
        case "rotation": currentValue = .quat(current.rotation)
        case "scale": currentValue = .vec3(current.scale)
        default: throw CommandError.failed("World space applies to Transform position, rotation and scale, not '\(path)'")
        }
        let kind: FieldKind = field == "rotation" ? .quat : .vec3
        let value = element >= 0 ? try currentValue.replacing(element, with: number(json))
                                 : try FieldValue(json: json, kind: kind, in: world)
        var updated = local
        switch value {
        case .vec3(let v) where field == "position":
            let p = parentMatrix.inverse * Vec4(v, 1)
            updated.position = Vec3(p.x, p.y, p.z)
        case .vec3(let v) where field == "scale":
            updated.scale = v / Vec3(parent.scale.x == 0 ? 1 : parent.scale.x, parent.scale.y == 0 ? 1 : parent.scale.y,
                                     parent.scale.z == 0 ? 1 : parent.scale.z)
        case .quat(let q):
            updated.rotation = (parent.rotation.inverse * q).normalized
        default:
            throw SceneError.typeMismatch(path: "value", expected: kind.description)
        }
        guard let id = world.id(of: entity) else { throw CommandError.failed("The entity has no id") }
        if arguments.transient == true {
            world.add(updated, to: entity)
            return NoResult()
        }
        let label = arguments.label ?? "Edit \(field)"
        try session.commands.check(session.perform(SetComponentCommand(id: id, old: local, new: updated, label: label)), title)
        return NoResult()
    }
}

/// Which space `component.setField` reads a Transform value in.
public enum TransformSpace: String, Codable, CaseIterable, Sendable {
    case local, world
}

// MARK: Assets

/// Commands on the open project's files: unavailable without a project.
@MainActor
func hasProject(_ session: EditorSession) -> Bool { session.assets != nil }

// Why commands are unavailable (`EditorCommand.unavailableReason(in:)`).
let noProjectReason = "no project is open (run project.open or project.new first)"
let noSelectionReason = "nothing is selected (run selection.set first)"
private let noWindowReason = "it needs the editor window (the editor is running headless)"

public enum AssetImportCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Files or folders anywhere on disk.
        public var sources: [String]
        /// The destination folder relative to `Assets/` (default: `Assets/` itself).
        public var folder: String?
        public init(sources: [String], folder: String? = nil) {
            self.sources = sources
            self.folder = folder
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The new paths relative to `Assets/`.
        public var paths: [String]
    }

    public static let id: CommandID = .importAsset
    public static let title = "Import"
    public static let doc = "Copies files or folders into `folder` of the project and imports them in the background (a .gltf brings its .bin and images). Taken names get \" 2\". Not undoable."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let urls = try arguments.sources.map { try session.commands.require(session.fileURL(forPath: $0, title), title) }
        let paths = session.importAssets(urls, into: arguments.folder ?? "")
        try session.commands.check(!paths.isEmpty, title)
        return Result(paths: paths)
    }
}

public enum AssetNewFolderCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Where, relative to `Assets/` (default: `Assets/`).
        public var folder: String?
        /// Default "New Folder" (" 2"… when taken).
        public var name: String?
        public init(folder: String? = nil, name: String? = nil) {
            self.folder = folder
            self.name = name
        }
    }

    public static let id: CommandID = "asset.newFolder"
    public static let title = "New Folder"
    public static let doc = "Creates a folder in `folder`. Returns its path."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let path = session.createAssetFolder(in: arguments.folder ?? "", name: arguments.name ?? "New Folder")
        return PathResult(path: try session.commands.require(path, title))
    }
}

public enum AssetNewMaterialCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Material" (the file gets ".material").
        public var name: String?
        /// Its parameters (default: a default PBR material).
        public var material: MaterialAsset?
        public init(folder: String? = nil, name: String? = nil, material: MaterialAsset? = nil) {
            self.folder = folder
            self.name = name
            self.material = material
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
    }

    public static let id: CommandID = "asset.newMaterial"
    public static let title = "New Material"
    public static let doc = "Writes a .material file in `folder` (default parameters, or `material`). Returns its asset id and path."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let id = try session.commands.require(session.createMaterialAsset(in: arguments.folder ?? "",
                                                                          name: arguments.name ?? "New Material",
                                                                          material: arguments.material ?? MaterialAsset()), title)
        return Result(asset: id, path: session.assets?.path(of: id) ?? "")
    }
}

public enum AssetRenameCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The file or folder, relative to `Assets/`.
        public var path: String
        /// The new name in the same folder; the extension is kept when it has none.
        public var name: String
        public init(path: String, name: String) {
            self.path = path
            self.name = name
        }
    }

    public static let id: CommandID = "asset.rename"
    public static let title = "Rename Asset"
    public static let doc = "Renames a file or folder in place. Asset ids, and so every reference, survive. Returns the new path. Not undoable."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        PathResult(path: try session.commands.require(session.renameAsset(at: arguments.path, to: arguments.name), title))
    }
}

public enum AssetMoveCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String
        /// The destination folder ("" is `Assets/`).
        public var folder: String
        public init(path: String, folder: String) {
            self.path = path
            self.folder = folder
        }
    }

    public static let id: CommandID = "asset.move"
    public static let title = "Move Asset"
    public static let doc = "Moves a file or folder into `folder`, keeping asset ids. Returns the new path. Not undoable."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        PathResult(path: try session.commands.require(session.moveAsset(at: arguments.path, into: arguments.folder), title))
    }
}

public enum AssetDeleteCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "asset.delete"
    public static let title = "Delete Asset"
    public static let doc = "Deletes a file (with its sidecar) or a folder. Not undoable; the editor asks first, the command doesn't."
    public static let isDestructive = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.deleteAsset(at: arguments.path), title)
        return NoResult()
    }
}

public enum AssetExtractMaterialsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A glTF model.
        public var asset: AssetID
        public init(asset: AssetID) { self.asset = asset }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The new .material files.
        public var materials: [AssetID]
    }

    public static let id: CommandID = "asset.extractMaterials"
    public static let title = "Extract Materials"
    public static let doc = "Writes the model's materials to .material files in \"<model> Materials/\", remaps the model to them and points the scene's renderers at them. The scene edit is one undo step; the files stay."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let created = session.extractMaterials(of: arguments.asset)
        try session.commands.check(!created.isEmpty, title)
        return Result(materials: created)
    }
}

public enum AssetApplySettingsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetID
        /// The importer's settings as JSON (what the sidecar holds).
        public var settings: JSONValue
        public init(asset: AssetID, settings: JSONValue) {
            self.asset = asset
            self.settings = settings
        }
    }

    public static let id: CommandID = "asset.applySettings"
    public static let title = "Apply Import Settings"
    public static let doc = "Writes the asset's import settings to its sidecar and reimports it. Not undoable."
    public static let isDestructive = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.applyImportSettings(arguments.settings, to: arguments.asset), title)
        return NoResult()
    }
}

public enum AssetInstantiateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A model or prefab (file or object) or a mesh object.
        public var asset: AssetReference
        /// Where the root goes (in `parent`'s space with a parent).
        public var position: Vec3?
        public var parent: EntityID?
        public init(asset: AssetReference, position: Vec3? = nil, parent: EntityID? = nil) {
            self.asset = asset
            self.position = position
            self.parent = parent
        }
    }

    public static let id: CommandID = "asset.instantiate"
    public static let title = "Instantiate"
    public static let doc = "Places a model, prefab or mesh in the scene at `position`, under `parent` (default: a root), and selects it. Returns the new roots."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EntitiesResult {
        let roots = session.instantiate(AssetItem(arguments.asset), at: arguments.position ?? .zero, parent: arguments.parent)
        try session.commands.check(!roots.isEmpty, title)
        return EntitiesResult(entities: roots)
    }
}

public enum AssetAssignCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// A mesh or material object, or a file whose only object is one (a .material file).
        public var asset: AssetReference
        /// "mesh" or "material" (default: what `asset` is).
        public var kind: AssetKind?
        public init(entity: EntityID, asset: AssetReference, kind: AssetKind? = nil) {
            self.entity = entity
            self.asset = asset
            self.kind = kind
        }
    }

    public static let id: CommandID = "asset.assign"
    public static let title = "Assign Asset"
    public static let doc = "Sets the entity's MeshRenderer mesh or material to the asset (an entity without a MeshRenderer gets one for a mesh)."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        guard let (reference, kind) = session.droppableKind(of: AssetItem(arguments.asset)) else {
            throw CommandError.failed("\(arguments.asset) isn't a mesh or a material")
        }
        if let wanted = arguments.kind, wanted != kind {
            throw CommandError.failed("\(arguments.asset) is a \(kind.rawValue), not a \(wanted.rawValue)")
        }
        try session.commands.check(session.assign(reference, kind: kind, to: arguments.entity), title)
        return NoResult()
    }
}

/// The material fields `material.set` changes: a JSON object holding any of `MaterialAsset`'s
/// keys. (A typed `MaterialAsset` converts to every key: a complete material.)
public struct MaterialPatch: Codable, Equatable, Sendable {
    public var fields: [String: JSON]

    public init(fields: [String: JSON]) { self.fields = fields }

    /// Every field of `material`.
    public init(_ material: MaterialAsset) {
        let object = (try? JSONEncoder().encode(material)).flatMap { try? JSON(data: $0) }
        fields = object?.objectValue ?? [:]
    }

    public init(from decoder: any Decoder) throws {
        let json = try decoder.singleValueContainer().decode(JSON.self)
        guard let object = json.objectValue else {
            throw DecodingError.typeMismatch([String: JSON].self, .init(codingPath: decoder.codingPath,
                                                                       debugDescription: "the material is an object of fields"))
        }
        fields = object
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(JSON.object(fields))
    }

    /// The names of the fields a patch may hold (every key a material is written with, and the legacy `isTransparent`).
    static let knownKeys: Set<String> = {
        var full = MaterialAsset()
        let texture = AssetReference(AssetID(high: 0, low: 1))
        full.texture = texture
        full.metallicRoughnessTexture = texture
        full.normalTexture = texture
        full.occlusionTexture = texture
        full.emissiveTexture = texture
        return Set(MaterialPatch(full).fields.keys).union(["isTransparent"])
    }()

    /// `base` with this patch's fields replaced (`null` clears a texture).
    func applied(to base: MaterialAsset) throws -> MaterialAsset {
        let unknown = fields.keys.filter { !Self.knownKeys.contains($0) }.sorted()
        if let first = unknown.first {
            throw CommandError.failed("Unknown material field '\(first)'; the fields are \(Self.knownKeys.sorted().joined(separator: ", "))")
        }
        var merged = MaterialPatch(base).fields
        for (key, value) in fields { merged[key] = value }
        do {
            return try JSONDecoder().decode(MaterialAsset.self, from: JSON.object(merged).data())
        } catch {
            throw CommandError.failed("Bad material value: \(error)")
        }
    }
}

public enum MaterialSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A .material file.
        public var asset: AssetID
        /// The fields to change; fields left out keep their current values (see `reset`).
        public var material: MaterialPatch
        /// Start from the default material instead of the current one, so fields left out go
        /// back to their defaults.
        public var reset: Bool?
        /// What undo restores (default: the file's material before the command).
        public var previous: MaterialAsset?
        public var label: String?
        /// Write without recording an undo step (a live preview during a drag).
        public var transient: Bool?
        public init(asset: AssetID, material: MaterialPatch, reset: Bool? = nil, previous: MaterialAsset? = nil,
                    label: String? = nil, transient: Bool? = nil) {
            self.asset = asset
            self.material = material
            self.reset = reset
            self.previous = previous
            self.label = label
            self.transient = transient
        }

        /// A complete material (replaces the file's).
        public init(asset: AssetID, material: MaterialAsset, previous: MaterialAsset? = nil, label: String? = nil,
                    transient: Bool? = nil) {
            self.init(asset: asset, material: MaterialPatch(material), reset: true, previous: previous, label: label,
                      transient: transient)
        }
    }

    public static let id: CommandID = "material.set"
    public static let title = "Edit Material"
    public static let doc = "Changes the .material file's fields and reimports it (the viewport updates). Fields left out in `material` keep their current values (`null` clears a texture); `reset: true` starts from the default material instead. A model's own materials are read-only: asset.extractMaterials makes editable .material files."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        guard session.isMaterialFile(arguments.asset) else {
            let id = arguments.asset.description
            let path = session.assets?.path(of: arguments.asset).map { " (\($0))" } ?? ""
            throw CommandError.failed("\(id.prefix(8))\(path) isn't a .material file, so its materials are read-only. "
                                      + "To edit a model's materials, run asset.extractMaterials {asset: \"\(id)\"}, which writes "
                                      + "editable .material files and points the scene at them, then material.set one of those.")
        }
        let base = arguments.reset == true ? MaterialAsset() : session.assets?.material(AssetReference(arguments.asset)) ?? MaterialAsset()
        let material = try arguments.material.applied(to: base)
        if arguments.transient == true {
            try session.commands.check(session.previewMaterial(material, of: arguments.asset), title)
        } else {
            try session.commands.check(session.setMaterial(material, of: arguments.asset, from: arguments.previous,
                                                           label: arguments.label ?? "Edit Material"), title)
        }
        return NoResult()
    }
}

// MARK: Values

extension World {
    /// The live entity for `id`, or throws `UndoError.entityNotFound`.
    @MainActor func require(_ id: EntityID) throws -> Entity {
        guard let entity = entity(for: id) else { throw UndoError.entityNotFound(id) }
        return entity
    }
}

extension AssetItem {
    /// The file for a reference without a sub-asset, else the object.
    public init(_ reference: AssetReference) {
        self = reference.subAsset == nil ? .asset(reference.asset) : .object(reference)
    }
}

extension FieldValue {
    /// Element `index` of a vector or quaternion (x, y, z, w), or nil.
    func element(_ index: Int) -> Float? {
        switch self {
        case .vec2(let v) where index < 2: v[index]
        case .vec3(let v) where index < 3: v[index]
        case .vec4(let v) where index < 4: v[index]
        case .quat(let q) where index < 4: q.vector[index]
        default: nil
        }
    }

    /// This vector or quaternion with element `index` set to `value`.
    func replacing(_ index: Int, with value: Float) throws -> FieldValue {
        guard element(index) != nil else { throw SceneError.typeMismatch(path: "value", expected: "a vector element") }
        switch self {
        case .vec2(var v): v[index] = value; return .vec2(v)
        case .vec3(var v): v[index] = value; return .vec3(v)
        case .vec4(var v): v[index] = value; return .vec4(v)
        case .quat(let q):
            var v = q.vector
            v[index] = value
            return .quat(Quat(vector: v))
        default: return self
        }
    }

    /// As JSON for command arguments: vectors and quaternions as arrays, entities by id, enum
    /// cases by name.
    @MainActor public func json(in world: World) -> JSONValue {
        func floats(_ values: [Float]) -> JSONValue { .array(values.map { .double(Double($0)) }) }
        switch self {
        case .null: return .null
        case .bool(let b): return .bool(b)
        case .int(let i): return .int(Int64(i))
        case .float(let d): return .double(d)
        case .string(let s), .enumCase(let s): return .string(s)
        case .vec2(let v): return floats([v.x, v.y])
        case .vec3(let v): return floats([v.x, v.y, v.z])
        case .vec4(let v): return floats([v.x, v.y, v.z, v.w])
        case .quat(let q): return floats([q.vector.x, q.vector.y, q.vector.z, q.vector.w])
        case .entity(let e): return world.id(of: e).map { .string($0.description) } ?? .null
        }
    }

    /// Reads `json` as a value for a field of `kind` (nil or `.unknown`: guessed from its shape).
    @MainActor public init(json: JSONValue, kind: FieldKind?, in world: World) throws {
        let mismatch = SceneError.typeMismatch(path: "value", expected: kind?.description ?? "a field value")
        func numbers(_ items: [JSONValue]) throws -> [Float] {
            try items.map { item in
                switch item {
                case .int(let i): return Float(i)
                case .double(let d): return Float(d)
                default: throw mismatch
                }
            }
        }
        switch (json, kind) {
        case (.null, _): self = .null
        case (.bool(let b), _): self = .bool(b)
        case (.int(let i), .float?): self = .float(Double(i))
        case (.int(let i), _): self = .int(Int(i))
        case (.double(let d), _): self = .float(d)
        case (.string(let s), .entity?):
            guard let id = EntityID(s) else { throw mismatch }
            self = .entity(try world.require(id))
        case (.string(let s), .enumeration?): self = .enumCase(s)
        case (.string(let s), _): self = .string(s)
        case (.entity(let e), _): self = .entity(e)
        case (.array(let items), _):
            let v = try numbers(items)
            switch (v.count, kind) {
            case (2, _): self = .vec2(Vec2(v[0], v[1]))
            case (3, _): self = .vec3(Vec3(v[0], v[1], v[2]))
            case (4, .quat?): self = .quat(Quat(v[0], v[1], v[2], v[3]))
            case (4, _): self = .vec4(Vec4(v[0], v[1], v[2], v[3]))
            default: throw mismatch
            }
        case (.object(let members), .quat?):
            // {"eulerDegrees": [x, y, z]}: see Quat.euler(degrees:).
            guard members.count == 1, case .array(let items)? = members["eulerDegrees"] else {
                throw SceneError.typeMismatch(path: "value", expected: "a quaternion [x, y, z, w] or {\"eulerDegrees\": [x, y, z]}")
            }
            let v = try numbers(items)
            guard v.count == 3 else { throw mismatch }
            self = .quat(Quat.euler(degrees: Vec3(v[0], v[1], v[2])))
        case (.object, _): throw mismatch
        }
    }
}
