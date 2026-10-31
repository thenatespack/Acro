import Engine
import Foundation

/// Makes prefab file edits undoable: performing writes `new` to the `.prefab` file of `asset`,
/// reverting writes `old` back. Each write reimports the file, and the session then rebuilds
/// the open scene's instances (keeping their overrides).
public struct PrefabFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: Data
    public let new: Data
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: Data, new: Data, in database: AssetDatabase, label: String = "Apply to Prefab") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ data: Data) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        try database.writePrefab(data, to: asset)
    }
}

/// What the inspector shows about an entity of a prefab instance (`EditorSession.prefabInfo(of:)`).
public struct PrefabEntityInfo: Equatable {
    public var link: PrefabLink
    /// The instance root's id.
    public var root: EntityID
    /// The entity is the instance's root.
    public var isRoot: Bool
    /// The overrides on this entity (on the root: every override of the instance).
    public var overrides: [PrefabOverride]
    /// Children added to the instance (root only).
    public var addedEntities: Int
    /// The prefab is a `.prefab` file, so Apply can write it (a model's prefab is read-only).
    public var canApply: Bool

    /// The overridden components of this entity, in order, with the overridden fields (vector
    /// elements as their vector: "scale", not "scale.0"; "added" / "removed" for a component
    /// only the instance has / lacks).
    public var overriddenComponents: [(component: String, fields: [String])] {
        var result: [(component: String, fields: [String])] = []
        for override in overrides where override.entity == link.local {
            guard let component = override.component else { continue }
            var field = override.kind == .field ? (override.path ?? "") : (override.kind == .addedComponent ? "added" : "removed")
            if override.kind == .field, let dot = field.lastIndex(of: "."), field[field.index(after: dot)...].allSatisfy(\.isNumber) {
                field = String(field[..<dot])
            }
            if field.isEmpty { field = "all" }
            if let i = result.firstIndex(where: { $0.component == component }) {
                if !result[i].fields.contains(field) { result[i].fields.append(field) }
            } else {
                result.append((component, [field]))
            }
        }
        return result
    }
}

/// Prefabs in the editor: Create Prefab, linked instances kept in step with their prefabs
/// (`prefabs`, a `PrefabSync`), overrides, Apply / Revert and Unpack. See PrefabInstance.swift
/// for the model. Failures are logged and reported as nil / false, like the rest of the session.
extension EditorSession {
    // MARK: Keeping instances in step

    /// Rebuilds the open scene's instances whose prefab changed since they were built (with
    /// `force`, all of them, from their stored overrides: after a scene or project opened).
    /// Waits until Stop while playing. Returns how many were rebuilt.
    @discardableResult
    public func syncPrefabs(force: Bool = false) -> Int {
        guard let assets, !suspendsPrefabSync else { return 0 }
        if isPlaying {
            prefabSyncPending = true
            return 0
        }
        let rebuilt = prefabs.sync(world, database: assets, force: force)
        if !rebuilt.isEmpty {
            if !force { log.info("Updated \(rebuilt.count) prefab instance\(rebuilt.count == 1 ? "" : "s")") }
            selection.prune(in: world)
            changed()
        }
        return rebuilt.count
    }

    /// Writes every instance's current overrides into its `PrefabInstance` (before saving), and
    /// with `under`, those of the instances nested in that subtree too.
    func refreshPrefabOverrides(under root: Entity? = nil) {
        guard let assets else { return }
        prefabs.refreshOverrides(in: world, database: assets)
        guard let root else { return }
        // Nested instances: against their prefab as it is now.
        for entity in world.subtreeOrder(root) {
            guard var link = world.get(PrefabInstance.self, for: entity),
                  let template = prefabs.template(for: link.prefab, in: assets) else { continue }
            let overrides = world.prefabOverrides(of: entity, template: template)
            if overrides != link.overrides {
                link.overrides = overrides
                world.add(link, to: entity)
            }
        }
    }

    // MARK: Reading

    /// The prefab instance `id` belongs to, its overrides and what can be done with it, or nil.
    public func prefabInfo(of id: EntityID) -> PrefabEntityInfo? {
        guard let assets, let entity = world.entity(for: id), let link = world.prefabLink(of: entity),
              let rootID = world.id(of: link.root) else { return nil }
        let isRoot = link.root == entity
        let overrides = prefabs.overrides(of: link.root, in: world, database: assets, only: isRoot ? nil : link.local) ?? []
        return PrefabEntityInfo(link: link, root: rootID, isRoot: isRoot, overrides: overrides,
                                addedEntities: isRoot ? world.prefabAddedEntities(of: link.root).count : 0,
                                canApply: isPrefabFile(link.prefab.asset))
    }

    /// Whether `id` is a `.prefab` file (editable), as opposed to a model's prefab.
    public func isPrefabFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == PrefabFileImporter().name
    }

    // MARK: Create

    /// Saves `id`'s subtree as a new `.prefab` file in `folder` (named `name`, default the
    /// entity's name) and makes the entity an instance of it (one undo step; the file stays).
    /// An entity that was an instance is unlinked from its old prefab; instances inside the
    /// subtree become nested prefabs. Returns the new prefab.
    @discardableResult
    public func createPrefab(from id: EntityID, in folder: String = "", name: String? = nil) -> AssetReference? {
        guard let assets = requireAssetDatabase("Create Prefab") else { return nil }
        guard !isPlaying else {
            log.warning("Create Prefab: \(EditorError.playing)")
            return nil
        }
        guard let entity = world.entity(for: id) else {
            log.error("Create Prefab failed: \(UndoError.entityNotFound(id))")
            return nil
        }
        let title = (name ?? displayName(of: entity)).replacingOccurrences(of: "/", with: "-").trimmingCharacters(in: .whitespaces)
        let path = assets.uniquePath(Self.join(folder, (title.isEmpty ? "Prefab" : title) + ".prefab"))
        do {
            refreshPrefabOverrides(under: entity)
            var transform = world.get(Transform.self, for: entity)
            transform?.position = .zero
            let (data, entities) = try world.prefabData(from: entity, rootTransform: transform)
            let asset = try assets.createPrefab(data, at: path)
            let reference = AssetReference(asset)
            guard perform(try AddComponentCommand(entity, PrefabInstance(prefab: reference, entities: entities), in: world,
                                                  label: "Create Prefab")) else { return nil }
            if let template = prefabs.template(for: reference, in: assets) { prefabs.didBuild(reference, from: template) }
            log.info("Created prefab \(path)")
            return reference
        } catch {
            log.error("Create Prefab failed: \(error)")
            return nil
        }
    }

    // MARK: Apply and revert

    /// Writes `id`'s component `component` (nil: the whole instance, with added and removed
    /// entities) into its `.prefab` file, so every instance gets it (one undo step). A model's
    /// prefab can't be changed; neither can the root's `Transform` (each instance's placement).
    @discardableResult
    public func applyToPrefab(_ id: EntityID, component: String? = nil) -> Bool {
        let label = component.map { "Apply \($0) to Prefab" } ?? "Apply Prefab"
        guard let assets = requireAssetDatabase(label), let (entity, link) = prefabTarget(id, label) else { return false }
        guard isPrefabFile(link.prefab.asset) else {
            log.error("\(label): \(PrefabError.readOnly(assets.displayName(of: link.prefab)))")
            return false
        }
        do {
            let old = try assets.fileData(of: link.prefab.asset)
            if let component {
                guard link.local != nil else {
                    log.error("\(label): \(displayName(of: entity)) was added to the instance; apply the whole instance instead")
                    return false
                }
                guard !(entity == link.root && component == Transform.componentName) else {
                    log.error("\(label): the root's Transform is the instance's own placement")
                    return false
                }
                if let inner = nestedInstance(containing: entity, below: link.root) {
                    log.error("\(label): \(displayName(of: entity)) belongs to the nested prefab \(displayName(of: inner)); "
                              + "apply the whole instance, or edit that prefab")
                    return false
                }
                let new = try world.prefabData(applying: component, of: entity, to: old)
                // Undo brings the instance back as it is now (its change becomes an override again).
                undo.beginGroup(label)
                defer { undo.endGroup(); changed() }
                try undo.perform(ReplaceSubtreeCommand(link.root, with: world.save([link.root]), in: world, label: label))
                try undo.perform(PrefabFileEditCommand(asset: link.prefab.asset, old: old, new: new, in: assets, label: label))
                return true
            }
            guard let instance = world.get(PrefabInstance.self, for: link.root) else { throw PrefabError.notAnInstance }
            refreshPrefabOverrides(under: link.root)
            let template = prefabs.template(for: link.prefab, in: assets)
            let rootTransform = template.flatMap { $0.world.get(Transform.self, for: $0.root) }
            let (new, entities) = try world.prefabData(from: link.root, keeping: instance.entities, rootTransform: rootTransform)
            // The added entities become the prefab's: link them before the file is reimported. Undo
            // brings the instance back as it is now, with its old link.
            let relinked = World()
            let copy = try relinked.load(world.save([link.root]), ids: .keepUnique)[0]
            relinked.add(PrefabInstance(prefab: instance.prefab, entities: entities), to: copy)
            undo.beginGroup(label)
            defer { undo.endGroup(); changed() }
            try undo.perform(ReplaceSubtreeCommand(link.root, with: relinked.save([copy]), in: world, label: label))
            try undo.perform(PrefabFileEditCommand(asset: link.prefab.asset, old: old, new: new, in: assets, label: label))
            return true
        } catch {
            log.error("\(label) failed: \(error)")
            return false
        }
    }

    /// Puts `id`'s component `component` back to the prefab's (adding or removing it as
    /// needed); with nil, reverts the whole instance: every override goes and added children are
    /// deleted. One undo step.
    @discardableResult
    public func revertToPrefab(_ id: EntityID, component: String? = nil) -> Bool {
        let label = component.map { "Revert \($0)" } ?? "Revert Prefab Instance"
        guard let assets = requireAssetDatabase(label), let (entity, link) = prefabTarget(id, label) else { return false }
        guard let template = prefabs.builtTemplate(for: link.prefab) ?? prefabs.template(for: link.prefab, in: assets) else {
            log.error("\(label): the prefab \(assets.displayName(of: link.prefab)) isn't available")
            return false
        }
        do {
            if let component {
                guard !(entity == link.root && component == Transform.componentName) else {
                    log.error("\(label): the root's Transform is the instance's own placement")
                    return false
                }
                let prefabValue = try world.prefabComponent(named: component, of: entity, template: template)
                let current = world.component(named: component, of: entity)
                let entityID = try world.requireIDForCommand(entity)
                switch (prefabValue, current) {
                case (let value?, let current?):
                    return perform(SetComponentCommand(id: entityID, old: current, new: value, label: label))
                case (let value?, nil):
                    return perform(AddComponentCommand(id: entityID, component: value, label: label))
                case (nil, let current?):
                    return perform(RemoveComponentCommand(id: entityID, componentType: type(of: current), label: label))
                case (nil, nil):
                    return true
                }
            }
            // The whole instance: rebuild a copy without overrides, then swap it in.
            let scratch = World()
            let copy = try scratch.load(world.save([link.root]), ids: .keepUnique)[0]
            let rebuilt = try scratch.syncPrefabInstance(copy, template: template, previous: nil, overrides: [], keepsAddedEntities: false)
            return perform(try ReplaceSubtreeCommand(link.root, with: scratch.save([rebuilt]), in: world, label: label))
        } catch {
            log.error("\(label) failed: \(error)")
            return false
        }
    }

    /// Unlinks the instance `id` belongs to from its prefab (its entities stay as they are).
    @discardableResult
    public func unpackPrefab(_ id: EntityID) -> Bool {
        guard let (_, link) = prefabTarget(id, "Unpack Prefab") else { return false }
        do { return perform(try RemoveComponentCommand(link.root, PrefabInstance.self, in: world, label: "Unpack Prefab")) } catch {
            log.error("Unpack Prefab failed: \(error)")
            return false
        }
    }

    // MARK: Showing assets

    /// Selects `reference`'s file (or object) in the asset browser and shows it in the inspector.
    @discardableResult
    public func selectAsset(_ reference: AssetReference) -> Bool {
        guard let assets = requireAssetDatabase("Select Asset") else { return false }
        guard let record = assets.record(reference.asset) else {
            log.error("Select Asset: \(AssetError.noSuchAsset(reference.description))")
            return false
        }
        let item: AssetItem = reference.subAsset == nil || record.objects.count == 1 ? .asset(reference.asset) : .object(reference)
        inspectedAsset = item
        if case .object(let object) = item, let sub = object.subAsset {
            onRevealAsset?(record.path + "#" + sub)
        } else {
            onRevealAsset?(record.path)
        }
        return true
    }

    // MARK: Helpers

    private func prefabTarget(_ id: EntityID, _ label: String) -> (Entity, PrefabLink)? {
        guard !isPlaying else {
            log.warning("\(label): \(EditorError.playing)")
            return nil
        }
        guard let entity = world.entity(for: id) else {
            log.error("\(label) failed: \(UndoError.entityNotFound(id))")
            return nil
        }
        guard let link = world.prefabLink(of: entity) else {
            log.error("\(label): \(displayName(of: entity)) isn't part of a prefab instance")
            return nil
        }
        return (entity, link)
    }

    /// The root of an instance nested in the instance at `root` that `entity` belongs to.
    private func nestedInstance(containing entity: Entity, below root: Entity) -> Entity? {
        guard let id = world.id(of: entity) else { return nil }
        var current: Entity? = entity
        while let candidate = current, candidate != root {
            if let link = world.get(PrefabInstance.self, for: candidate), link.localID(of: id) != nil { return candidate }
            current = world.parent(of: candidate)
        }
        return nil
    }

    func requireAssetDatabase(_ action: String) -> AssetDatabase? {
        if assets == nil { log.warning("\(action): no project is open") }
        return assets
    }
}

extension World {
    @MainActor func requireIDForCommand(_ entity: Entity) throws -> EntityID {
        guard let id = ensureID(of: entity) else { throw UndoError.entityNotFound(EntityID(high: 0, low: 0)) }
        return id
    }
}
