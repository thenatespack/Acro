import Engine
import Foundation

/// One cell of the asset browser: a folder, a file, or (under an expanded model) one of its
/// objects.
public struct AssetBrowserEntry: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case folder, model, texture, material, mesh, prefab, file
    }

    public var item: AssetItem
    public var title: String
    public var kind: Kind
    /// A file's or folder's path relative to `Assets/` (a sub-asset's file path).
    public var path: String
    /// An object shown under its expanded file.
    public var isSubAsset: Bool
    /// A file with several objects (a model), which can be expanded.
    public var isExpandable: Bool
    public var isExpanded: Bool
    /// What its thumbnail shows: a texture, mesh, material or prefab object (nil: an icon).
    public var thumbnail: AssetReference?
    /// The kind of `thumbnail`.
    public var thumbnailKind: AssetKind?

    public init(item: AssetItem, title: String, kind: Kind, path: String, isSubAsset: Bool = false, isExpandable: Bool = false,
                isExpanded: Bool = false, thumbnail: AssetReference? = nil, thumbnailKind: AssetKind? = nil) {
        self.item = item
        self.title = title
        self.kind = kind
        self.path = path
        self.isSubAsset = isSubAsset
        self.isExpandable = isExpandable
        self.isExpanded = isExpanded
        self.thumbnail = thumbnail
        self.thumbnailKind = thumbnailKind
    }
}

/// The asset browser's state and logic, independent of widgets: the current folder, the
/// search text, which models are expanded, the selection (shown in the inspector through
/// `EditorSession.inspectedAsset`), and the entries to show.
///
/// Without a search the entries are the current folder's subfolders, then its files, each
/// expanded model followed by its objects. With a search they are every file and object in
/// the project whose name contains it (case-insensitive), in path order.
@MainActor
public final class AssetBrowserModel {
    public let session: EditorSession
    /// The folder shown, relative to `Assets/` ("" is `Assets/`).
    public var folder = "" { didSet { if folder != oldValue { invalidate() } } }
    public var search = "" { didSet { if search != oldValue { invalidate() } } }
    public private(set) var expanded = Set<AssetID>()
    /// The selected item; selecting also shows it in the inspector.
    public var selection: AssetItem? {
        didSet {
            guard selection != oldValue else { return }
            if selection != nil { session.inspectedAsset = selection }
            version += 1
        }
    }
    /// Increases whenever the entries or the selection may have changed.
    public private(set) var version = 0

    private var cachedEntries: [AssetBrowserEntry]?
    private var cachedFolders: [String]?
    private var cachedRevision = -1

    public init(session: EditorSession) {
        self.session = session
    }

    /// Forget cached listings (after file operations, or when the project changed).
    public func invalidate() {
        cachedEntries = nil
        cachedFolders = nil
        version += 1
    }

    /// Every folder of the project, sorted ("" excluded).
    public var folders: [String] {
        syncRevision()
        if let cachedFolders { return cachedFolders }
        let folders = session.assets?.folders() ?? []
        cachedFolders = folders
        return folders
    }

    /// What the grid shows (see the type's notes).
    public var entries: [AssetBrowserEntry] {
        syncRevision()
        if let cachedEntries { return cachedEntries }
        let entries = makeEntries()
        cachedEntries = entries
        return entries
    }

    private func syncRevision() {
        let revision = session.assets?.revision ?? -1
        if revision != cachedRevision {
            cachedRevision = revision
            cachedEntries = nil
            cachedFolders = nil
            version += 1
            if let assets = session.assets {
                if !folder.isEmpty && !assets.isFolder(folder) { folder = "" }
                if let id = selection?.assetID, assets.record(id) == nil { selection = nil }
            } else {
                folder = ""
                selection = nil
            }
        }
    }

    // MARK: Navigation

    /// Shows `item` expanded or collapsed (models only).
    public func setExpanded(_ id: AssetID, _ isExpanded: Bool) {
        guard expanded.contains(id) != isExpanded else { return }
        if isExpanded { expanded.insert(id) } else { expanded.remove(id) }
        invalidate()
    }

    public func toggleExpanded(_ id: AssetID) { setExpanded(id, !expanded.contains(id)) }

    /// Double click: a folder opens, a model expands or collapses.
    public func activate(_ entry: AssetBrowserEntry) {
        switch entry.item {
        case .folder(let path):
            folder = path
            search = ""
        case .asset(let id) where session.isMeshBuildFile(id):
            session.run(MeshBuildOpenCommand.self, .init(asset: AssetReference(id)))
        case .asset(let id) where session.isVFXFile(id):
            session.run(VFXOpenCommand.self, .init(asset: AssetReference(id)))
        case .asset(let id) where session.isSoundBuildFile(id):
            session.run(SoundBuildOpenCommand.self, .init(asset: AssetReference(id)))
        case .asset(let id) where session.isPostFXFile(id):
            session.run(PostFXOpenCommand.self, .init(asset: AssetReference(id)))
        case .asset(let id) where entry.isExpandable:
            toggleExpanded(id)
        default:
            break
        }
    }

    /// Shows the item at `path` (relative to `Assets/`): a folder is opened, a file selected in
    /// its folder, "file#sub-asset" selects that object with its file expanded. Returns whether
    /// it was found.
    @discardableResult
    public func reveal(_ path: String) -> Bool {
        guard let assets = session.assets else { return false }
        let parts = path.split(separator: "#", maxSplits: 1).map(String.init)
        let file = parts.first ?? ""
        if parts.count == 1, file.isEmpty || assets.isFolder(file) {
            folder = file
            select(.folder(file))
            return true
        }
        guard let id = assets.id(forPath: file) else { return false }
        folder = EditorSession.parentFolder(of: file)
        if parts.count == 2 {
            setExpanded(id, true)
            select(.object(AssetReference(id, subAsset: parts[1])))
        } else {
            select(.asset(id))
        }
        return true
    }

    /// The folder new items go into: the current one.
    public var targetFolder: String { folder }

    /// The parts of the current folder for a breadcrumb: ("Assets", ""), ("Models", "Models")…
    public var breadcrumb: [(title: String, path: String)] {
        var parts: [(String, String)] = [("Assets", "")]
        var path = ""
        for component in folder.split(separator: "/") {
            path = EditorSession.join(path, String(component))
            parts.append((String(component), path))
        }
        return parts
    }

    // MARK: Actions (on the selection or the current folder, through the session's commands)

    /// Creates a folder in the current folder (`asset.newFolder`) and selects it.
    @discardableResult
    public func newFolder() -> String? {
        guard let path = session.run(AssetNewFolderCommand.self, .init(folder: targetFolder))?.path else { return nil }
        invalidate()
        selection = .folder(path)
        return path
    }

    /// Creates a material in the current folder (`asset.newMaterial`) and selects it.
    @discardableResult
    public func newMaterial() -> AssetID? {
        guard let id = session.run(AssetNewMaterialCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Creates a procedural texture in the current folder (`asset.newProceduralTexture`) and selects it.
    @discardableResult
    public func newProceduralTexture() -> AssetID? {
        guard let id = session.run(AssetNewProceduralTextureCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Creates a mesh build in the current folder (`meshBuild.new`) and selects it, so the
    /// inspector shows the Mesh Builder.
    @discardableResult
    public func newMeshBuild() -> AssetID? {
        guard let id = session.run(MeshBuildNewCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Creates a VFX effect in the current folder (`vfx.new`) and selects it.
    @discardableResult
    public func newVFX() -> AssetID? {
        guard let id = session.run(VFXNewCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Creates a sound build in the current folder (`sfx.new`) and selects it.
    @discardableResult
    public func newSoundBuild() -> AssetID? {
        guard let id = session.run(SoundBuildNewCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Creates a post-fx profile in the current folder (`postfx.new`) and selects it.
    @discardableResult
    public func newPostFX() -> AssetID? {
        guard let id = session.run(PostFXNewCommand.self, .init(folder: targetFolder))?.asset else { return nil }
        invalidate()
        selection = .asset(id)
        return id
    }

    /// Copies files or folders from outside the project into the current folder, imports them
    /// (`asset.import`) and selects the first one. Returns the new paths.
    @discardableResult
    public func importFiles(_ urls: [URL]) -> [String] {
        guard !urls.isEmpty else { return [] }
        let paths = session.run(AssetImportCommand.self, .init(sources: urls.map(\.path), folder: targetFolder))?.paths ?? []
        guard let first = paths.first, let assets = session.assets else { return paths }
        invalidate()
        if assets.isFolder(first) {
            select(.folder(first))
        } else if let id = assets.id(forPath: first) {
            select(.asset(id))
        }
        return paths
    }

    /// The path a rename or delete acts on: the selected folder or file (not a sub-asset).
    public var selectedPath: String? {
        switch selection {
        case .folder(let path)?: path.isEmpty ? nil : path
        case .asset(let id)?: session.assets?.path(of: id)
        default: nil
        }
    }

    /// Renames the selected file or folder (`asset.rename`). Returns whether it worked.
    @discardableResult
    public func renameSelection(to name: String) -> Bool {
        guard let path = selectedPath,
              let newPath = session.run(AssetRenameCommand.self, .init(path: path, name: name))?.path else { return false }
        invalidate()
        if case .folder = selection { selection = .folder(newPath) }
        if folder == path || folder.hasPrefix(path + "/") { folder = newPath + folder.dropFirst(path.count) }
        return true
    }

    /// Moves `item` (a file or folder) into `folder` (`asset.move`). Returns whether it worked.
    @discardableResult
    public func move(_ item: AssetItem, into folder: String) -> Bool {
        guard let path = session.path(of: item), !path.isEmpty else { return false }
        if case .object = item { return false }
        guard EditorSession.parentFolder(of: path) != folder else { return false }
        guard let newPath = session.run(AssetMoveCommand.self, .init(path: path, folder: folder))?.path else { return false }
        invalidate()
        if case .folder = item, selection == item { selection = .folder(newPath) }
        return true
    }

    /// Deletes the selected file or folder (`asset.delete`; ask first). Returns whether it worked.
    @discardableResult
    public func deleteSelection() -> Bool {
        guard let path = selectedPath, session.run(AssetDeleteCommand.self, .init(path: path)) != nil else { return false }
        invalidate()
        selection = nil
        if folder == path || folder.hasPrefix(path + "/") { folder = EditorSession.parentFolder(of: path) }
        return true
    }

    // MARK: Building entries

    private func makeEntries() -> [AssetBrowserEntry] {
        guard let assets = session.assets else { return [] }
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        var result: [AssetBrowserEntry] = []
        if query.isEmpty {
            let prefix = folder.isEmpty ? "" : folder + "/"
            for path in folders where path.hasPrefix(prefix) && !path.dropFirst(prefix.count).contains("/") {
                result.append(AssetBrowserEntry(item: .folder(path), title: String(path.dropFirst(prefix.count)), kind: .folder,
                                                path: path))
            }
            for record in assets.allRecords where EditorSession.parentFolder(of: record.path) == folder {
                result.append(entry(for: record, assets: assets))
                if expanded.contains(record.id) && record.objects.count > 1 {
                    result += record.objects.map { entry(for: $0, in: record, assets: assets) }
                }
            }
        } else {
            for path in folders where (path.split(separator: "/").last ?? "").lowercased().contains(query) {
                result.append(AssetBrowserEntry(item: .folder(path), title: String(path.split(separator: "/").last ?? ""),
                                                kind: .folder, path: path))
            }
            for record in assets.allRecords {
                if record.fileName.lowercased().contains(query) { result.append(entry(for: record, assets: assets)) }
                guard record.objects.count > 1 else { continue }
                for object in record.objects where object.name.lowercased().contains(query) {
                    result.append(entry(for: object, in: record, assets: assets))
                }
            }
        }
        return result
    }

    private func entry(for record: AssetRecord, assets: AssetDatabase) -> AssetBrowserEntry {
        var kind: AssetBrowserEntry.Kind = .file
        var thumbnail: (AssetReference, AssetKind)?
        switch record.importer {
        case TextureImporter().name?: kind = .texture
        case MaterialFileImporter().name?: kind = .material
        case GLTFImporter().name?, OBJImporter().name?: kind = .model
        default: break
        }
        if record.objects.count == 1 {
            let object = record.objects[0]
            thumbnail = (AssetReference(record.id, subAsset: object.id), object.kind)
            if kind == .file { kind = Self.kind(of: object.kind) }
        } else if let prefab = record.objects.last(where: { $0.kind == .prefab }) {
            thumbnail = (AssetReference(record.id, subAsset: prefab.id), .prefab)
        }
        return AssetBrowserEntry(item: .asset(record.id), title: record.fileName, kind: kind, path: record.path,
                                 isExpandable: record.objects.count > 1, isExpanded: expanded.contains(record.id),
                                 thumbnail: thumbnail?.0, thumbnailKind: thumbnail?.1)
    }

    private func entry(for object: AssetObjectInfo, in record: AssetRecord, assets: AssetDatabase) -> AssetBrowserEntry {
        let reference = AssetReference(record.id, subAsset: object.id)
        return AssetBrowserEntry(item: .object(reference), title: object.name, kind: Self.kind(of: object.kind), path: record.path,
                                 isSubAsset: true, thumbnail: reference, thumbnailKind: object.kind)
    }

    static func kind(of kind: AssetKind) -> AssetBrowserEntry.Kind {
        switch kind {
        case .mesh: .mesh
        case .material: .material
        case .texture: .texture
        case .prefab: .prefab
        }
    }
}
