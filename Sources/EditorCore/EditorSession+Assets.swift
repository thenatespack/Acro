import Engine
import Foundation

/// Something in the asset browser: a folder, a file (an asset) or one object imported from a
/// file (a sub-asset, such as a model's mesh).
public enum AssetItem: Hashable, Sendable {
    /// A folder, by path relative to `Assets/` ("" is `Assets/` itself).
    case folder(String)
    /// A whole file.
    case asset(AssetID)
    /// One object of a file.
    case object(AssetReference)

    /// The file this item belongs to (nil for folders).
    public var assetID: AssetID? {
        switch self {
        case .folder: nil
        case .asset(let id): id
        case .object(let reference): reference.asset
        }
    }
}

/// Where an asset from the browser was dropped (see `EditorSession.drop(_:on:)`).
public enum AssetDropTarget: Equatable, Sendable {
    /// The viewport: the point on the ground (or the surface) under the pointer, and the
    /// entity there, if any.
    case viewport(position: Vec3, entity: EntityID?)
    /// A hierarchy row's entity (nil: below the rows, as a root at `position`).
    case hierarchy(parent: EntityID?, position: Vec3)
    /// An inspector field taking an asset of `kind` (`MeshRenderer.mesh` / `.material`) of `entity`.
    case field(entity: EntityID, kind: AssetKind)
}

/// Makes material edits undoable: performing writes `new` to the `.material` file of `asset`
/// (and reimports it, so the viewport updates), reverting writes `old` back.
public struct MaterialEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: MaterialAsset
    public let new: MaterialAsset
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: MaterialAsset, new: MaterialAsset, in database: AssetDatabase, label: String = "Edit Material") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ material: MaterialAsset) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        try database.writeMaterial(material, to: asset)
    }
}

/// Asset browser actions: file operations on `Assets/` (through `AssetDatabase`, so ids are
/// kept), material editing with undo, Extract Materials, and dropping assets into the scene.
/// Like the rest of the session, failures are logged and reported as nil / false.
extension EditorSession {
    // MARK: Paths

    /// The path (relative to `Assets/`) of a folder or file item; a sub-asset's file path.
    public func path(of item: AssetItem) -> String? {
        switch item {
        case .folder(let path): path
        case .asset(let id): assets?.path(of: id)
        case .object(let reference): assets?.path(of: reference.asset)
        }
    }

    /// `name` inside `folder` ("" is `Assets/`).
    public static func join(_ folder: String, _ name: String) -> String {
        folder.isEmpty ? name : folder + "/" + name
    }

    /// The folder containing `path` ("" for top-level items).
    public static func parentFolder(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slash])
    }

    // MARK: Files

    /// Creates "New Folder" (or "New Folder 2"…) in `folder`. Returns its path.
    @discardableResult
    public func createAssetFolder(in folder: String, name: String = "New Folder") -> String? {
        guard let assets = requireAssets("New Folder") else { return nil }
        let path = assets.uniquePath(Self.join(folder, name))
        do {
            try assets.createFolder(path)
            log.info("Created folder \(path)")
            return path
        } catch {
            log.error("New Folder failed: \(error)")
            return nil
        }
    }

    /// Writes a default material to "New Material.material" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createMaterialAsset(in folder: String, name: String = "New Material",
                                    material: MaterialAsset = MaterialAsset()) -> AssetID? {
        guard let assets = requireAssets("New Material") else { return nil }
        let path = assets.uniquePath(Self.join(folder, name + ".material"))
        do {
            let id = try assets.createMaterial(material, at: path)
            log.info("Created material \(path)")
            return id
        } catch {
            log.error("New Material failed: \(error)")
            return nil
        }
    }

    /// Renames the file or folder at `path` to `newName` in the same folder, keeping the
    /// extension when `newName` has none. Returns the new path.
    @discardableResult
    public func renameAsset(at path: String, to newName: String) -> String? {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !name.contains("/") else {
            log.error("Rename: '\(newName)' isn't a valid name")
            return nil
        }
        let ext = (path as NSString).pathExtension
        let isFolder = assets?.isFolder(path) ?? false
        let full = isFolder || ext.isEmpty || !(name as NSString).pathExtension.isEmpty ? name : name + "." + ext
        return moveAsset(at: path, to: Self.join(Self.parentFolder(of: path), full), verb: "Renamed")
    }

    /// Moves the file or folder at `path` into `folder`. Returns the new path.
    @discardableResult
    public func moveAsset(at path: String, into folder: String) -> String? {
        let name = String(path.split(separator: "/").last ?? "")
        return moveAsset(at: path, to: Self.join(folder, name), verb: "Moved")
    }

    private func moveAsset(at path: String, to newPath: String, verb: String) -> String? {
        guard let assets = requireAssets(verb) else { return nil }
        guard newPath != path else { return path }
        do {
            try assets.move(path, to: newPath)
            log.info("\(verb) \(path) to \(newPath)")
            return newPath
        } catch {
            log.error("\(verb == "Renamed" ? "Rename" : "Move") \(path) failed: \(error)")
            return nil
        }
    }

    /// Deletes the file (with its sidecar) or folder at `path`. Not undoable: ask first.
    @discardableResult
    public func deleteAsset(at path: String) -> Bool {
        guard let assets = requireAssets("Delete") else { return false }
        do {
            try assets.delete(path)
            log.info("Deleted \(path)")
            if let item = inspectedAsset, self.path(of: item) == nil || self.path(of: item) == path { inspectedAsset = nil }
            return true
        } catch {
            log.error("Delete \(path) failed: \(error)")
            return false
        }
    }

    // MARK: Materials

    /// Whether `id` is a `.material` file (editable), as opposed to a material imported from a model.
    public func isMaterialFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == MaterialFileImporter().name
    }

    /// Sets the `.material` asset `id` to `material` as one undo step, saving the file.
    @discardableResult
    public func setMaterial(_ material: MaterialAsset, of id: AssetID, from old: MaterialAsset? = nil,
                            label: String = "Edit Material") -> Bool {
        guard let assets = requireAssets(label) else { return false }
        guard let previous = old ?? assets.material(AssetReference(id)) else {
            log.error("\(label): \(id.description.prefix(8)) isn't a material")
            return false
        }
        guard previous != material else { return true }
        return perform(MaterialEditCommand(asset: id, old: previous, new: material, in: assets, label: label))
    }

    /// Writes `material` to the `.material` asset `id` without recording an undo step (live
    /// preview during a drag; `setMaterial` records the whole gesture at its end).
    public func previewMaterial(_ material: MaterialAsset, of id: AssetID) {
        do { try assets?.writeMaterial(material, to: id) } catch { log.error("Edit material failed: \(error)") }
    }

    /// Writes each material imported from the model `id` (a glTF file) to a `.material` file in
    /// "<model name> Materials/" next to it, remaps the model to them
    /// (`GLTFImporter.Settings.materialRemap`, so new instances use them) and points the open
    /// scene's renderers that used the model's materials at the new files (one undo step).
    /// Materials already remapped are skipped. Returns the new materials' ids.
    @discardableResult
    public func extractMaterials(of id: AssetID) -> [AssetID] {
        guard let assets = requireAssets("Extract Materials") else { return [] }
        guard let record = assets.record(id), record.importer == GLTFImporter().name,
              var settings = assets.settings(of: id, as: GLTFImporter.Settings.self) else {
            log.error("Extract Materials: only models (.gltf, .glb) have materials to extract")
            return []
        }
        let stem = ((record.path as NSString).lastPathComponent as NSString).deletingPathExtension
        let folder = Self.join(Self.parentFolder(of: record.path), "\(stem) Materials")
        var created: [AssetID] = []
        var remapped: [String: String] = [:]
        for object in record.objects where object.kind == .material && settings.materialRemap[object.id] == nil {
            let source = AssetReference(id, subAsset: object.id)
            guard let material = assets.material(source) else { continue }
            let name = object.name.replacingOccurrences(of: "/", with: "-").trimmingCharacters(in: .whitespaces)
            let path = assets.uniquePath(Self.join(folder, (name.isEmpty ? "Material" : name) + ".material"))
            do {
                let newID = try assets.createMaterial(material, at: path)
                let target = AssetReference(newID, subAsset: "material")
                settings.materialRemap[object.id] = target
                remapped[source.description] = target.description
                created.append(newID)
            } catch {
                log.error("Extract Materials: writing \(path) failed: \(error)")
            }
        }
        guard !created.isEmpty else {
            log.info("Extract Materials: \(record.path) has no materials left to extract")
            return []
        }
        do {
            try assets.setSettings(settings, for: id)
        } catch {
            log.error("Extract Materials: updating \(record.path)'s settings failed: \(error)")
        }
        // The scene's existing instances.
        var edits: [(EntityID, String, String)] = []
        world.query(MeshRenderer.self) { entity, renderer in
            if let target = remapped[renderer.material.key], let entityID = world.id(of: entity) {
                edits.append((entityID, renderer.material.key, target))
            }
        }
        if !edits.isEmpty {
            undo.beginGroup("Extract Materials")
            for (entityID, old, new) in edits {
                try? undo.perform(SetFieldCommand(id: entityID, component: MeshRenderer.componentName, path: "material",
                                                  old: .string(old), new: .string(new)))
            }
            undo.endGroup()
            changed()
        }
        log.info("Extracted \(created.count) material\(created.count == 1 ? "" : "s") from \(record.path) to \(folder)")
        return created
    }

    // MARK: Into the scene

    /// The prefab an item spawns: a prefab object, or a file's main prefab (a model).
    public func prefabReference(for item: AssetItem) -> AssetReference? {
        guard let assets else { return nil }
        switch item {
        case .folder: return nil
        case .object(let reference):
            return assets.prefab(reference) != nil ? reference : nil
        case .asset(let id):
            return assets.prefab(AssetReference(id)) != nil ? AssetReference(id) : nil
        }
    }

    /// The kind of object an item stands for when dropped on a field: a mesh or material
    /// object, or a file whose main (single) object is one (a `.material` file).
    public func droppableKind(of item: AssetItem) -> (AssetReference, AssetKind)? {
        guard let assets else { return nil }
        switch item {
        case .folder: return nil
        case .object(let reference):
            if assets.mesh(reference) != nil { return (reference, .mesh) }
            if assets.material(reference) != nil { return (reference, .material) }
            return nil
        case .asset(let id):
            guard let objects = assets.record(id)?.objects, objects.count == 1 else { return nil }
            let reference = AssetReference(id, subAsset: objects[0].id)
            return objects[0].kind == .mesh || objects[0].kind == .material ? (reference, objects[0].kind) : nil
        }
    }

    /// Spawns `item` into the scene as one undo step and selects the new root: a model or prefab
    /// as its node tree (`World.instantiate`), a mesh as one entity drawing it. The root is
    /// placed at `position` (in `parent`'s space when a parent is given) and appended to
    /// `parent`'s children (or the roots). Returns the new roots' ids.
    @discardableResult
    public func instantiate(_ item: AssetItem, at position: Vec3 = .zero, parent: EntityID? = nil) -> [EntityID] {
        guard let assets = requireAssets("Instantiate") else { return [] }
        let scratch = World()
        var roots: [Entity] = []
        var title = "Asset"
        if let reference = prefabReference(for: item), let prefab = assets.prefab(reference) {
            roots = scratch.instantiate(prefab)
            title = prefab.roots.count == 1 ? prefab.roots[0].name : (assets.path(of: reference.asset) ?? "Prefab")
        } else if let (reference, kind) = droppableKind(of: item), kind == .mesh {
            title = assets.record(reference.asset)?.objects.first { $0.id == reference.subAsset }?.name ?? "Mesh"
            roots = [scratch.spawn(Transform(), Name(title), MeshRenderer(mesh: MeshHandle(reference)))]
        } else {
            log.error("Instantiate: only models, prefabs and meshes can be placed in the scene")
            return []
        }
        for root in roots { scratch.modify(Transform.self, for: root) { $0.position += position } }
        do {
            let parentEntity = try parent.map { id -> Entity in
                guard let entity = world.entity(for: id) else { throw UndoError.entityNotFound(id) }
                return entity
            }
            let command = try SpawnCommand(subtree: scratch.save(roots), parent: parentEntity, index: nil, in: world,
                                           label: "Instantiate \(title)")
            guard perform(command) else { return [] }
            selection.set(command.rootIDs)
            return command.rootIDs
        } catch {
            log.error("Instantiate \(title) failed: \(error)")
            return []
        }
    }

    /// Sets the entity's `MeshRenderer.mesh` or `.material` to `reference` (one undo step). An
    /// entity without a `MeshRenderer` gets one when a mesh is dropped on it.
    @discardableResult
    public func assign(_ reference: AssetReference, kind: AssetKind, to id: EntityID) -> Bool {
        guard kind == .mesh || kind == .material, let entity = world.entity(for: id) else { return false }
        let key = reference.description
        let field = kind == .mesh ? "mesh" : "material"
        let label = kind == .mesh ? "Assign Mesh" : "Assign Material"
        guard let renderer = world.get(MeshRenderer.self, for: entity) else {
            guard kind == .mesh else {
                log.warning("\(label): \(displayName(of: entity)) has no MeshRenderer")
                return false
            }
            do {
                return perform(try AddComponentCommand(entity, MeshRenderer(mesh: MeshHandle(reference)), in: world, label: label))
            } catch {
                log.error("\(label) failed: \(error)")
                return false
            }
        }
        let old = kind == .mesh ? renderer.mesh.key : renderer.material.key
        guard old != key else { return true }
        return perform(SetFieldCommand(id: id, component: MeshRenderer.componentName, path: field, old: .string(old),
                                       new: .string(key), label: label))
    }

    /// Handles an asset dropped from the browser (one undo step, logged when refused):
    /// - `.viewport`: a material on an entity sets its material; models, prefabs and meshes
    ///   are instantiated at the point.
    /// - `.hierarchy`: a material or mesh on an entity row is assigned to it; a model or prefab
    ///   is instantiated as a child of the row's entity (or as a root at `position`).
    /// - `.field`: a mesh or material onto the matching `MeshRenderer` field.
    @discardableResult
    public func drop(_ item: AssetItem, on target: AssetDropTarget) -> Bool {
        let droppable = droppableKind(of: item)
        switch target {
        case .viewport(let position, let entity):
            if let (reference, kind) = droppable, kind == .material {
                guard let entity else {
                    log.info("Drop a material on an object to assign it")
                    return false
                }
                return assign(reference, kind: kind, to: entity)
            }
            return !instantiate(item, at: position).isEmpty
        case .hierarchy(let parent, let position):
            if let (reference, kind) = droppable, let parent, kind == .material || prefabReference(for: item) == nil {
                return assign(reference, kind: kind, to: parent)
            }
            return !instantiate(item, at: parent == nil ? position : .zero, parent: parent).isEmpty
        case .field(let entity, let kind):
            guard let (reference, droppedKind) = droppable, droppedKind == kind else {
                log.info("Only a \(kind.rawValue) can be dropped on this field")
                return false
            }
            return assign(reference, kind: kind, to: entity)
        }
    }

    private func requireAssets(_ action: String) -> AssetDatabase? {
        if assets == nil { log.warning("\(action): no project is open") }
        return assets
    }
}
