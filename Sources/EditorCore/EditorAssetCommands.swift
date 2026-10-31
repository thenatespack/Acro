import Engine
import Foundation

// Project, asset and prefab commands beyond the asset browser's file operations (those are in
// EditorCommands.swift): closing the project, listing and inspecting assets with their objects,
// import settings and load state, reimporting and waiting for imports, reading materials, and
// prefabs (create, overrides, apply, revert, unpack). Like the others, each is a thin front for
// an `EditorSession` action, so the asset browser, the inspector and MCP clients share them.

// MARK: Values

/// One object of an asset (a sub-asset) in a listing.
public struct AssetObjectEntry: Codable, Equatable, Sendable {
    public var reference: AssetReference
    public var name: String
    public var kind: AssetKind
}

/// An asset in a listing (`asset.list`, `asset.get`).
public struct AssetEntry: Codable, Equatable, Sendable {
    public var id: AssetID
    /// Relative to `Assets/`.
    public var path: String
    /// The folder it is in ("" is `Assets/`).
    public var folder: String
    /// The importer's name ("gltf", "texture", "material", "prefab", …); nil when none handles it.
    public var importer: String?
    /// What the browser shows it as: model, texture, material, mesh, prefab or file.
    public var kind: String
    public var objects: [AssetObjectEntry]
    /// loaded, loading, unloaded (imported, not read yet), failed or missing.
    public var state: String
    /// The last import's error.
    public var error: String?
}

extension EditorSession {
    /// `id` as an `AssetEntry`.
    func assetEntry(_ id: AssetID) -> AssetEntry? {
        guard let assets, let record = assets.record(id) else { return nil }
        let objects = record.objects.map { AssetObjectEntry(reference: AssetReference(id, subAsset: $0.id), name: $0.name, kind: $0.kind) }
        var kind: AssetBrowserEntry.Kind = .file
        switch record.importer {
        case TextureImporter().name?: kind = .texture
        case MaterialFileImporter().name?: kind = .material
        case GLTFImporter().name?, OBJImporter().name?: kind = .model
        default: if record.objects.count == 1 { kind = AssetBrowserModel.kind(of: record.objects[0].kind) }
        }
        let state: String = switch assets.loadState(of: id) {
        case .loaded: "loaded"
        case .loading: "loading"
        case .unloaded: "unloaded"
        case .failed: "failed"
        case .missing: "missing"
        }
        return AssetEntry(id: id, path: record.path, folder: Self.parentFolder(of: record.path), importer: record.importer,
                          kind: kind.rawValue, objects: objects, state: state, error: record.importError)
    }

    /// The asset `reference` or `path` names (one of them is required).
    func resolveAsset(_ reference: AssetReference?, path: String?, _ title: String) throws -> AssetID {
        guard let assets else { throw CommandError.failed(noProjectReason) }
        if let reference {
            guard assets.record(reference.asset) != nil else { throw CommandError.failed("No asset \(reference)") }
            return reference.asset
        }
        guard let path else { throw CommandError.failed("\(title): give `asset` or `path`") }
        guard let id = assets.id(forPath: path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else {
            throw CommandError.failed("No asset at Assets/\(path)")
        }
        return id
    }
}

// MARK: Project

public enum ProjectCloseCommand: EditorCommand {
    public static let id: CommandID = "project.close"
    public static let title = "Close Project"
    public static let doc = "Closes the open project. The scene stays open; its asset references stay as they are (they draw again when the project is reopened)."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.commands.check(session.closeProject(), title)
        return NoResult()
    }
}

// MARK: Listing and inspecting

public enum AssetListCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The folder to list, relative to `Assets/` (default: `Assets/` itself).
        public var folder: String?
        /// Include subfolders' contents (default false; true when searching).
        public var recursive: Bool?
        /// Only assets holding an object of this kind.
        public var kind: AssetKind?
        /// Only assets whose path or object names contain this (case-insensitive).
        public var search: String?
        public init(folder: String? = nil, recursive: Bool? = nil, kind: AssetKind? = nil, search: String? = nil) {
            self.folder = folder
            self.recursive = recursive
            self.kind = kind
            self.search = search
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The folders inside `folder` (all levels when recursive).
        public var folders: [String]
        public var assets: [AssetEntry]
        /// Imports still running in the background.
        public var importing: Int
    }

    public static let id: CommandID = "asset.list"
    public static let title = "List Assets"
    public static let doc = "Lists a folder of the project: its subfolders and assets, each with id, path, importer, kind, load state, import error and objects (sub-assets: meshes, materials, textures, prefabs as asset: references). `recursive` includes subfolders; `kind` and `search` filter (search looks at paths and object names, in the whole project when no folder is given)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let assets = try session.commands.require(session.assets, title)
        let folder = (arguments.folder ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard folder.isEmpty || assets.isFolder(folder) else { throw CommandError.failed("No folder Assets/\(folder)") }
        let query = arguments.search?.lowercased() ?? ""
        let recursive = arguments.recursive ?? (!query.isEmpty && arguments.folder == nil)
        func inFolder(_ path: String) -> Bool {
            let parent = EditorSession.parentFolder(of: path)
            if recursive { return folder.isEmpty || parent == folder || parent.hasPrefix(folder + "/") }
            return parent == folder
        }
        let folders = assets.folders().filter(inFolder)
        let entries = assets.allRecords.filter { record in
            guard inFolder(record.path) else { return false }
            if let kind = arguments.kind, !record.objects.contains(where: { $0.kind == kind }) { return false }
            if !query.isEmpty, !record.path.lowercased().contains(query),
               !record.objects.contains(where: { $0.name.lowercased().contains(query) }) { return false }
            return true
        }.compactMap { session.assetEntry($0.id) }
        return Result(folders: folders, assets: entries, importing: assets.pendingLoadCount)
    }
}

public enum AssetGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The asset (an object reference names its file).
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetEntry
        /// The effective import settings (sidecar values over the importer's defaults); change them with asset.applySettings.
        public var settings: JSONValue?
        /// The importer's default settings.
        public var defaultSettings: JSONValue?
        /// Bumped by every reimport.
        public var revision: Int
    }

    public static let id: CommandID = "asset.get"
    public static let title = "Get Asset"
    public static let doc = "One asset's metadata: id, path, importer, kind, load state, import error, objects, its effective import settings and the importer's defaults (as asset.applySettings takes them), and its revision."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let id = try session.resolveAsset(arguments.asset, path: arguments.path, title)
        return try session.commands.require(session.assetDetails(id), title)
    }
}

extension EditorSession {
    /// `asset.get`'s result for `id`.
    func assetDetails(_ id: AssetID) -> AssetGetCommand.Result? {
        guard let assets, let entry = assetEntry(id) else { return nil }
        let importer = assets.record(id)?.importer.flatMap { assets.importers.importer(named: $0) }
        return AssetGetCommand.Result(asset: entry, settings: assets.settings(of: id), defaultSettings: importer?.defaultSettings,
                                      revision: assets.revision(of: id))
    }
}

public enum AssetReimportCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "asset.reimport"
    public static let title = "Reimport"
    public static let doc = "Imports the asset again now, even if it is up to date (prefab instances in the scene follow). Returns its metadata (see asset.get)."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> AssetGetCommand.Result {
        let id = try session.resolveAsset(arguments.asset, path: arguments.path, title)
        let report = try session.commands.require(session.assets, title).reimport(id)
        for (path, message) in report.errors { session.log.error("\(path): \(message)") }
        session.log.info("Reimported \(session.assets?.path(of: id) ?? id.description)")
        return try session.commands.require(session.assetDetails(id), title)
    }
}

public enum AssetWaitForImportsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Seconds to wait at most (default 60).
        public var timeout: Double?
        public init(timeout: Double? = nil) { self.timeout = timeout }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Everything finished (false: timed out).
        public var finished: Bool
        /// Imports still running.
        public var pending: Int
        /// Assets whose import failed, with the error.
        public var errors: [String]
    }

    public static let id: CommandID = "asset.waitForImports"
    public static let title = "Wait for Imports"
    public static let doc = "Waits until the background imports (asset.import, hot reload, a project just opened) are done or `timeout` seconds pass, applying them; returns whether they finished and any import errors."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let assets = try session.commands.require(session.assets, title)
        let finished = assets.waitForAll(timeout: max(0, arguments.timeout ?? 60))
        let errors = assets.allRecords.compactMap { record in record.importError.map { "\(record.path): \($0)" } }
        return Result(finished: finished, pending: assets.pendingLoadCount, errors: errors)
    }
}

public enum AssetSelectCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "asset.select"
    public static let title = "Select Asset"
    public static let doc = "Selects an asset (or one of its objects) in the asset browser, opening its folder, and shows it in the inspector."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let id = try session.resolveAsset(arguments.asset, path: arguments.path, title)
        let reference = arguments.asset.map { AssetReference(id, subAsset: $0.subAsset) } ?? AssetReference(id)
        try session.commands.check(session.selectAsset(reference), title)
        return NoResult()
    }
}

public enum MaterialGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A .material file, or a material object of a model.
        public var asset: AssetReference
        public init(asset: AssetReference) { self.asset = asset }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var material: MaterialAsset
        /// A .material file, which material.set can change (a model's materials are read-only; extract them first).
        public var editable: Bool
    }

    public static let id: CommandID = "material.get"
    public static let title = "Get Material"
    public static let doc = "Reads a material: a .material file or a model's material object, with every parameter as material.set takes it."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let assets = try session.commands.require(session.assets, title)
        guard let material = assets.material(arguments.asset) else { throw CommandError.failed("\(arguments.asset) isn't a material") }
        return Result(material: material, editable: session.isMaterialFile(arguments.asset.asset))
    }
}

// MARK: Prefabs

/// A prefab override as tools see it: `entity` is the instance's entity it applies to.
public struct PrefabOverrideEntry: Codable, Equatable, Sendable {
    public var kind: PrefabOverride.Kind
    /// The instance's entity (nil for a removed one).
    public var entity: EntityID?
    /// The prefab entity's id in the prefab.
    public var prefabEntity: String
    public var component: String?
    public var path: String?
    /// The instance's value (prefab-relative: references to the prefab's entities are `{"$prefabEntity": id}`).
    public var value: JSONValue?
}

public enum PrefabCreateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The subtree's root (default: the primary selection).
        public var entity: EntityID?
        /// Where the .prefab file goes, relative to `Assets/` (default `Assets/`).
        public var folder: String?
        /// The file's name (default: the entity's name; " 2"… when taken).
        public var name: String?
        public init(entity: EntityID? = nil, folder: String? = nil, name: String? = nil) {
            self.entity = entity
            self.folder = folder
            self.name = name
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var prefab: AssetReference
        public var path: String
    }

    public static let id: CommandID = "prefab.create"
    public static let title = "Create Prefab"
    public static let doc = "Saves an entity and its subtree as a .prefab file and makes the entity an instance of it (linking it is one undo step; the file stays). Instances inside the subtree become nested prefabs. Returns the prefab."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool {
        hasProject(session) && !session.isPlaying && session.selection.primaryEntity(in: session.world) != nil
    }
    public static func isAvailable(_ arguments: Arguments, in session: EditorSession) -> Bool {
        arguments.entity == nil ? isAvailable(in: session) : hasProject(session) && !session.isPlaying
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        !hasProject(session) ? noProjectReason : session.isPlaying ? EditorError.playing.description : noSelectionReason
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let entity = try arguments.entity ?? session.commands.require(
            session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) }, title)
        let reference = try session.commands.require(session.createPrefab(from: entity, in: arguments.folder ?? "", name: arguments.name), title)
        return Result(prefab: reference, path: session.assets?.path(of: reference.asset) ?? "")
    }
}

public enum PrefabOverridesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Any entity of the instance (default: the primary selection).
        public var entity: EntityID?
        public init(entity: EntityID? = nil) { self.entity = entity }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var prefab: AssetReference
        /// The instance's root.
        public var root: EntityID
        /// The entity's id in the prefab (nil: it was added to the instance).
        public var prefabEntity: String?
        /// Every override of the instance.
        public var overrides: [PrefabOverrideEntry]
        /// Entities added under the instance (top-level ones).
        public var added: [EntityID]
        /// The prefab is a .prefab file (prefab.apply can write it); a model's prefab is read-only.
        public var canApply: Bool
    }

    public static let id: CommandID = "prefab.overrides"
    public static let title = "Prefab Overrides"
    public static let doc = "The prefab instance an entity belongs to: its prefab, root, overrides (changed fields, added and removed components, removed entities) and added children, and whether prefab.apply can write the prefab."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let id = try arguments.entity ?? session.commands.require(
            session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) }, title)
        guard let entity = session.world.entity(for: id) else { throw CommandError.failed("\(UndoError.entityNotFound(id))") }
        guard let link = session.world.prefabLink(of: entity), let instance = session.world.get(PrefabInstance.self, for: link.root),
              let rootID = session.world.id(of: link.root), let assets = session.assets else {
            throw CommandError.failed("\(session.displayName(of: entity)) isn't part of a prefab instance")
        }
        let overrides = session.prefabs.overrides(of: link.root, in: session.world, database: assets) ?? instance.overrides
        return Result(
            prefab: link.prefab, root: rootID, prefabEntity: link.local,
            overrides: overrides.map { override in
                PrefabOverrideEntry(kind: override.kind, entity: instance.entities[override.entity].flatMap { session.world.resolve($0) }
                                        .flatMap { session.world.id(of: $0) },
                                    prefabEntity: override.entity, component: override.component, path: override.path,
                                    value: override.value)
            },
            added: session.world.prefabAddedEntities(of: link.root).compactMap { session.world.id(of: $0.entity) },
            canApply: session.isPrefabFile(link.prefab.asset))
    }
}

/// Arguments naming an entity of a prefab instance and optionally one of its components.
public struct PrefabComponentArguments: Codable, Equatable, Sendable {
    /// An entity of the instance (default: the primary selection).
    public var entity: EntityID?
    /// One component of that entity; nil: the whole instance.
    public var component: String?
    public init(entity: EntityID? = nil, component: String? = nil) {
        self.entity = entity
        self.component = component
    }
}

public enum PrefabApplyCommand: EditorCommand {
    public typealias Arguments = PrefabComponentArguments
    public static let id: CommandID = "prefab.apply"
    public static let title = "Apply to Prefab"
    public static let doc = "Writes an instance's change into its .prefab file, so every instance (in open scenes and when scenes open) gets it: one component of one entity, or with no component the whole instance (its overrides, added and removed entities). One undo step (undo writes the old file back). A model's prefab can't be changed; neither can the root's Transform."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) && !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? {
        hasProject(session) ? EditorError.playing.description : noProjectReason
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let id = try arguments.entity ?? session.commands.require(
            session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) }, title)
        try session.commands.check(session.applyToPrefab(id, component: arguments.component), title)
        return NoResult()
    }
}

public enum PrefabRevertCommand: EditorCommand {
    public typealias Arguments = PrefabComponentArguments
    public static let id: CommandID = "prefab.revert"
    public static let title = "Revert to Prefab"
    public static let doc = "Puts an instance back to its prefab: one component of one entity (added, removed or changed), or with no component the whole instance (every override goes, added children are deleted). One undo step."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) && !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? {
        hasProject(session) ? EditorError.playing.description : noProjectReason
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let id = try arguments.entity ?? session.commands.require(
            session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) }, title)
        try session.commands.check(session.revertToPrefab(id, component: arguments.component), title)
        return NoResult()
    }
}

public enum PrefabUnpackCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// An entity of the instance (default: the primary selection).
        public var entity: EntityID?
        public init(entity: EntityID? = nil) { self.entity = entity }
    }

    public static let id: CommandID = "prefab.unpack"
    public static let title = "Unpack Prefab"
    public static let doc = "Unlinks a prefab instance from its prefab: its entities stay, but no longer follow the prefab. One undo step."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let id = try arguments.entity ?? session.commands.require(
            session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) }, title)
        try session.commands.check(session.unpackPrefab(id), title)
        return NoResult()
    }
}
