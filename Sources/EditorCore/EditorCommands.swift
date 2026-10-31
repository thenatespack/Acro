import Engine
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
        EditUndoCommand.self, EditRedoCommand.self,
        PlayStartCommand.self, PlayStopCommand.self, PlayToggleCommand.self,
        ToolSetCommand.self,
        ProjectOpenCommand.self, ProjectNewCommand.self,
        LayoutResetCommand.self, ViewFrameSelectionCommand.self,
        SelectionSetCommand.self, SelectionClearCommand.self,
        EntityCreateCommand.self, EntityDuplicateCommand.self, EntityDeleteCommand.self, EntityRenameCommand.self,
        EntityReparentCommand.self, TransformSetCommand.self,
        ComponentAddCommand.self, ComponentRemoveCommand.self, ComponentSetFieldCommand.self,
        AssetImportCommand.self, AssetNewFolderCommand.self, AssetNewMaterialCommand.self, AssetRenameCommand.self,
        AssetMoveCommand.self, AssetDeleteCommand.self, AssetExtractMaterialsCommand.self, AssetApplySettingsCommand.self,
        AssetInstantiateCommand.self, AssetAssignCommand.self, MaterialSetCommand.self,
    ]
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
    public static let id: CommandID = "scene.new"
    public static let title = "New Scene"
    public static let doc = "Replaces the open scene with the starter scene. Clears the undo history; unsaved changes are lost. Not while playing."
    public static let isDestructive = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.newDocument(), title)
        return NoResult()
    }
}

public enum SceneOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A scene file (`~` expanded, relative to the working directory).
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "scene.open"
    public static let title = "Open Scene"
    public static let doc = "Replaces the open scene with the scene file at `path` and clears the undo history. Not while playing."
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
    public static let doc = "Saves the scene to its file, or to `path` when it has never been saved. Not while playing."
    public static let isDestructive = true
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
    public static let doc = "Saves the scene to `path`, which becomes its file. Not while playing."
    public static let isDestructive = true
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
    public static func unavailableReason(in session: EditorSession) -> String? { "nothing to undo" }
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
    public static func unavailableReason(in session: EditorSession) -> String? { "nothing to redo" }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.performRedo(), title)
        return NoResult()
    }
}

// MARK: Play mode

public enum PlayStartCommand: EditorCommand {
    public static let id: CommandID = "play.start"
    public static let title = "Play"
    public static let doc = "Snapshots the scene and runs its systems; edits while playing are discarded on stop."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "already playing" }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.play()
        return NoResult()
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

// MARK: Project

public enum ProjectOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project folder or its `Project.json`.
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "project.open"
    public static let title = "Open Project"
    public static let doc = "Opens the project at `path`, scans its assets and imports what changed (in the background). The scene stays open. Returns the project's root folder."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        try session.commands.check(session.openProject(path: arguments.path), title)
        return PathResult(path: session.project?.root.path ?? "")
    }
}

public enum ProjectNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A new folder, or an existing one without a project.
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "project.new"
    public static let title = "New Project"
    public static let doc = "Creates a project (Project.json, Assets/, Library/) at `path` and opens it. Returns its root folder."
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        try session.commands.check(session.newProject(path: arguments.path), title)
        return PathResult(path: session.project?.root.path ?? "")
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

public enum ViewFrameSelectionCommand: EditorCommand {
    public static let id: CommandID = .focusSelection
    public static let title = "Frame Selection"
    public static let doc = "Moves the viewport camera to frame the selected entities. Needs the editor window."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool {
        session.host != nil && !session.selection.entities(in: session.world).isEmpty
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.host == nil ? noWindowReason : noSelectionReason
    }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.host?.frameSelection()
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
        /// "empty", "cube", "sphere" or "plane".
        public var template: EntityTemplate
        /// World position (default: the origin).
        public var position: Vec3?
        public init(template: EntityTemplate, position: Vec3? = nil) {
            self.template = template
            self.position = position
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entity: EntityID
    }

    public static let id: CommandID = "entity.create"
    public static let title = "Create Entity"
    public static let doc = "Creates a root entity from `template` at `position` ([x, y, z]), named after it (\"Cube 2\" when taken), and selects it."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        Result(entity: try session.commands.require(session.create(arguments.template, at: arguments.position ?? .zero), title))
    }
}

public enum EntityDuplicateCommand: EditorCommand {
    public static let id: CommandID = .duplicate
    public static let title = "Duplicate"
    public static let doc = "Duplicates the selected entities with their children next to the originals and selects the copies. Returns the copies."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.selection.entities(in: session.world).isEmpty }
    public static func unavailableReason(in session: EditorSession) -> String? { noSelectionReason }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> EntitiesResult {
        let copies = session.duplicateSelection()
        try session.commands.check(!copies.isEmpty, title)
        return EntitiesResult(entities: copies)
    }
}

public enum EntityDeleteCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// How many subtrees were deleted.
        public var count: Int
    }

    public static let id: CommandID = .delete
    public static let title = "Delete"
    public static let doc = "Deletes the selected entities with their children. The editor asks for confirmation before running it; the command itself doesn't."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.selection.entities(in: session.world).isEmpty }
    public static func unavailableReason(in session: EditorSession) -> String? { noSelectionReason }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let count = session.deleteSelection()
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
        public var component: String
        /// A reflection path: "position", "stats.health", "points.2".
        public var path: String
        /// The value as JSON: a bool, number or string (also an enum case name), [x, y, z(, w)]
        /// for vectors and quaternions, an entity id string, or null for a nil optional.
        public var value: JSONValue
        /// What undo restores (default: the value before the command). A gesture that already
        /// applied its value live passes where it started.
        public var previous: JSONValue?
        /// The undo step's name (default "Edit <path>").
        public var label: String?
        /// Apply without recording an undo step (a live preview during a drag, which ends with
        /// a recorded set).
        public var transient: Bool?

        public init(entity: EntityID, component: String, path: String, value: JSONValue, previous: JSONValue? = nil,
                    label: String? = nil, transient: Bool? = nil) {
            self.entity = entity
            self.component = component
            self.path = path
            self.value = value
            self.previous = previous
            self.label = label
            self.transient = transient
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
    public static let doc = "Sets one field of a component by reflection path (what the inspector edits)."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let world = session.world
        let entity = try world.require(arguments.entity)
        guard let component = world.component(named: arguments.component, of: entity) else {
            throw SceneError.noSuchComponent(arguments.component)
        }
        guard let field = component.field(at: arguments.path) else { throw SceneError.noSuchField(arguments.path) }
        let value = try FieldValue(json: arguments.value, kind: field.kind, in: world)
        if arguments.transient == true {
            try world.setField(arguments.path, of: arguments.component, for: entity, to: value)
            return NoResult()
        }
        let old = try arguments.previous.map { try FieldValue(json: $0, kind: field.kind, in: world) } ?? field.value ?? .null
        try session.commands.check(session.perform(SetFieldCommand(id: arguments.entity, component: arguments.component,
                                                                   path: arguments.path, old: old, new: value,
                                                                   label: arguments.label)), title)
        return NoResult()
    }
}

// MARK: Assets

/// Commands on the open project's files: unavailable without a project.
@MainActor
private func hasProject(_ session: EditorSession) -> Bool { session.assets != nil }

// Why commands are unavailable (`EditorCommand.unavailableReason(in:)`).
private let noProjectReason = "no project is open (run project.open or project.new first)"
private let noSelectionReason = "nothing is selected (run selection.set first)"
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
        let urls = arguments.sources.map { EditorSession.url(forPath: $0) }
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
        public init(folder: String? = nil, name: String? = nil) {
            self.folder = folder
            self.name = name
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
    }

    public static let id: CommandID = "asset.newMaterial"
    public static let title = "New Material"
    public static let doc = "Writes a default .material file in `folder`. Returns its asset id and path."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let id = try session.commands.require(session.createMaterialAsset(in: arguments.folder ?? "",
                                                                          name: arguments.name ?? "New Material"), title)
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

public enum MaterialSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A .material file.
        public var asset: AssetID
        public var material: MaterialAsset
        /// What undo restores (default: the file's material before the command).
        public var previous: MaterialAsset?
        public var label: String?
        /// Write without recording an undo step (a live preview during a drag).
        public var transient: Bool?
        public init(asset: AssetID, material: MaterialAsset, previous: MaterialAsset? = nil, label: String? = nil,
                    transient: Bool? = nil) {
            self.asset = asset
            self.material = material
            self.previous = previous
            self.label = label
            self.transient = transient
        }
    }

    public static let id: CommandID = "material.set"
    public static let title = "Edit Material"
    public static let doc = "Writes `material` to the .material file and reimports it (the viewport updates)."
    public static let isIdempotent = true
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        guard session.isMaterialFile(arguments.asset) else {
            throw CommandError.failed("\(arguments.asset.description.prefix(8)) isn't a .material file")
        }
        if arguments.transient == true {
            try session.commands.check(session.previewMaterial(arguments.material, of: arguments.asset), title)
        } else {
            try session.commands.check(session.setMaterial(arguments.material, of: arguments.asset, from: arguments.previous,
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
        case (.object, _): throw mismatch
        }
    }
}
