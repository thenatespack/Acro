import Foundation

// Prefab instances: copies of a prefab asset that stay linked to it.
//
// ```swift
// let template = try prefab.template(prefabs: { database.prefab($0) })   // the prefab's entities, once
// let crate = try world.instantiatePrefab(template, reference: reference, under: nil)
// world.modify(Transform.self, for: crate) { $0.position = Vec3(2, 0, 0) }  // the root's transform is the instance's own
// // … the prefab file changes (hot reload) …
// let sync = PrefabSync()                                    // remembers the template each instance was built from
// sync.sync(world, database: database)                        // rebuilds changed instances, keeping their overrides
// ```
//
// ## Prefab-local ids
//
// Every entity of a prefab has an id of its own, the `EntityID` it has in the prefab: the
// `uid`s of a `.prefab` file (a scene file), or for a model's node tree a hash of the node's
// name path ("Fox/Root/Hip", with "#2"… for repeated names), so a reimport that adds nodes
// keeps the others' ids. `PrefabAsset.template(prefabs:)` builds a `PrefabTemplate`: a small
// world holding one copy of the prefab with exactly those ids.
//
// ## The link
//
// An instance's root carries a `PrefabInstance`: the prefab's `AssetReference`, the mapping
// from each prefab-local id to the instance's entity (an `EntityRef`, so it survives undo,
// duplication and play mode, and duplicates remap it to the copies) and the overrides. The
// instance's entities are ordinary entities with all their components, so a scene file holds
// the whole instance and opens without the project; the link is what lets it follow the
// prefab.
//
// ## Overrides
//
// The overrides are what the instance changed relative to the prefab, found by comparing the
// two (`World.prefabOverrides(of:template:)`):
// - `field`: a component field differs (by reflection path, with the instance's value; a whole
//   array when its length differs);
// - `addedComponent` / `removedComponent`: a component only the instance has / lacks;
// - `removedEntity`: a prefab entity was deleted from the instance.
// Children added under an instance's entities aren't overrides: they are kept as they are
// (reattached to the same prefab entity) whenever the instance is rebuilt.
// Entity references inside values are stored relative to the prefab
// (`{"$prefabEntity": id}`, `{"$prefabRef": id}`) so they map to the right entity of any copy.
// The root's `Transform` is the instance's own placement and is never an override, and the
// `PrefabInstance` of nested instances belongs to the prefab that contains them.
//
// The comparison needs the prefab as it was when the instance was built, so `PrefabSync` keeps
// the template it last built instances from; `refreshOverrides` writes the current overrides
// into each `PrefabInstance` (the editor does before saving), so a scene opened later rebuilds
// its instances from the prefab as it is then, with the stored overrides on top.
//
// ## Rebuilding
//
// `World.syncPrefabInstance(_:template:previous:)` replaces an instance with a fresh copy of the
// template: entities that existed keep their `EntityID`s (references, selection and undo steps
// that name them still work), the root keeps its parent, sibling position and `Transform`,
// overrides are applied on top (ones that no longer fit, such as a field the component lost, are
// dropped) and added children are reattached. Entity handles into the instance go stale.
//
// ## Nested prefabs
//
// A prefab may contain instances of other prefabs (a `.prefab` made from a subtree holding
// instances). Building a template syncs those nested instances with their own prefabs first,
// so editing the inner prefab updates the outer prefab's instances too. Cycles are cut after
// eight levels. Making a prefab from an instance root unlinks that root (the new prefab is a
// copy); prefab variants aren't supported.

/// The link from a prefab instance's root to its prefab; see the notes at the top of
/// PrefabInstance.swift.
public struct PrefabInstance: Component, Equatable, Sendable {
    public static let componentName = "PrefabInstance"
    public static var fieldHints: [String: FieldHints] {
        ["prefab": FieldHints(readOnly: true), "entities": FieldHints(readOnly: true), "overrides": FieldHints(readOnly: true)]
    }

    /// The prefab: a `.prefab` file or a model's prefab object.
    public var prefab: AssetReference
    /// Each prefab entity (by its prefab-local id, 32 hex digits) → this instance's entity.
    public var entities: [String: EntityRef]
    /// What this instance changed, as of the last `PrefabSync.refreshOverrides` (or rebuild).
    public var overrides: [PrefabOverride]

    public init(prefab: AssetReference, entities: [String: EntityRef] = [:], overrides: [PrefabOverride] = []) {
        self.prefab = prefab
        self.entities = entities
        self.overrides = overrides
    }

    /// The prefab-local id of the instance entity `id`, if it is one of the prefab's.
    public func localID(of id: EntityID) -> String? {
        entities.first { $0.value.id == id }?.key
    }
}

/// One difference between a prefab instance and its prefab (see `PrefabInstance`).
public struct PrefabOverride: Codable, Equatable, Sendable, CustomStringConvertible {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case field, addedComponent, removedComponent, removedEntity
    }

    public var kind: Kind
    /// The prefab entity, by prefab-local id.
    public var entity: String
    /// The component's name (all kinds but `removedEntity`).
    public var component: String?
    /// The field's reflection path (`field`; "" is the whole component).
    public var path: String?
    /// The instance's value (`field`) or component (`addedComponent`), prefab-relative.
    public var value: JSONValue?

    public init(kind: Kind, entity: String, component: String? = nil, path: String? = nil, value: JSONValue? = nil) {
        self.kind = kind
        self.entity = entity
        self.component = component
        self.path = path
        self.value = value
    }

    public var description: String {
        switch kind {
        case .field: "\(component ?? "?").\(path ?? "")"
        case .addedComponent: "+\(component ?? "?")"
        case .removedComponent: "-\(component ?? "?")"
        case .removedEntity: "-entity \(entity.prefix(8))"
        }
    }
}

public enum PrefabError: Error, Equatable, CustomStringConvertible {
    /// Linked instances need a prefab with exactly one root.
    case notOneRoot(Int)
    /// The entity isn't part of a prefab instance.
    case notAnInstance
    /// The prefab entity isn't in the prefab (any more).
    case noSuchPrefabEntity(String)
    /// Only `.prefab` files can be edited; a model's prefab comes from its file.
    case readOnly(String)
    /// The prefab's scene data doesn't load.
    case unreadable(String)

    public var description: String {
        switch self {
        case .notOneRoot(let n): "A linked prefab needs exactly one root entity (it has \(n))"
        case .notAnInstance: "The entity isn't part of a prefab instance"
        case .noSuchPrefabEntity(let id): "The prefab has no entity \(id.prefix(8))"
        case .readOnly(let what): "\(what) can't be edited: only .prefab files can (create a prefab from the instance)"
        case .unreadable(let message): "The prefab doesn't load: \(message)"
        }
    }
}

/// One copy of a prefab whose entities have the prefab-local ids (see the notes at the top of
/// PrefabInstance.swift). Instances are made from it and compared with it.
@MainActor
public final class PrefabTemplate {
    /// Holds the copy and nothing else.
    public let world: World
    public let root: Entity
    /// Every entity of the copy, depth first from the root (the order scene files use).
    public let order: [Entity]
    /// `world.save([root])`: what instances load, and equal when two templates are.
    public let data: Data
    /// The prefab assets nested instances inside it come from (directly or deeper).
    public let nestedPrefabs: Set<AssetID>

    init(world: World, root: Entity, nestedPrefabs: Set<AssetID>) throws {
        self.world = world
        self.root = root
        order = world.subtreeOrder(root)
        data = try world.save([root])
        self.nestedPrefabs = nestedPrefabs
    }

    /// The prefab-local id of a template entity.
    public func localID(of entity: Entity) -> String? { world.id(of: entity)?.description }

    /// The template entity with prefab-local id `local`.
    public func entity(local: String) -> Entity? { EntityID(local).flatMap { world.entity(for: $0) } }
}

extension PrefabAsset {
    /// Builds the prefab's template: its entities with their prefab-local ids, nested instances
    /// synced with their prefabs (`prefabs` finds them, e.g. `{ database.prefab($0) }`).
    /// Throws `PrefabError.notOneRoot` unless the prefab has exactly one root.
    @MainActor
    public func template(prefabs: (AssetReference) -> PrefabAsset?) throws -> PrefabTemplate {
        try template(prefabs: prefabs, depth: 0)
    }

    @MainActor
    func template(prefabs: (AssetReference) -> PrefabAsset?, depth: Int) throws -> PrefabTemplate {
        let world = World()
        let roots: [Entity]
        if let scene {
            do { roots = try world.load(scene, ids: .keepUnique) } catch { throw PrefabError.unreadable("\(error)") }
        } else {
            roots = world.instantiate(self)
        }
        guard roots.count == 1 else { throw PrefabError.notOneRoot(roots.count) }
        let root = roots[0]
        world.assignStableIDs(under: root)
        // The root is the prefab itself, not an instance of another one.
        world.remove(PrefabInstance.self, from: root)

        // Nested instances, outermost first; each sync replaces that instance's subtree.
        var nested = Set<AssetID>()
        if depth < 8 {
            for entity in world.independentPrefabInstances(under: root) where entity != root {
                guard let link = world.get(PrefabInstance.self, for: entity), let inner = prefabs(link.prefab),
                      let innerTemplate = try? inner.template(prefabs: prefabs, depth: depth + 1) else { continue }
                _ = try? world.syncPrefabInstance(entity, template: innerTemplate, previous: nil)
                nested.insert(link.prefab.asset)
                nested.formUnion(innerTemplate.nestedPrefabs)
            }
        }
        return try PrefabTemplate(world: world, root: root, nestedPrefabs: nested)
    }
}

// MARK: Instances in a world

/// Where an entity sits in a prefab instance (`World.prefabLink(of:)`).
public struct PrefabLink: Equatable {
    /// The instance's root (the outermost instance that contains the entity).
    public var root: Entity
    public var prefab: AssetReference
    /// The entity's prefab-local id; nil for an entity added to the instance.
    public var local: String?
}

extension World {
    /// The entities of `root`'s subtree, depth first (the order `save` writes them).
    public func subtreeOrder(_ root: Entity) -> [Entity] {
        var order: [Entity] = []
        var stack = [root]
        while let entity = stack.popLast() {
            order.append(entity)
            stack.append(contentsOf: children(of: entity).reversed())
        }
        return order
    }

    /// Gives every entity under `root` without an id one derived from its name path, so the
    /// same node tree gets the same ids every time.
    func assignStableIDs(under root: Entity) {
        func visit(_ entity: Entity, path: String) {
            if id(of: entity) == nil {
                if !setEntityID(Self.stableID(path), for: entity) { ensureID(of: entity) }
            }
            var seen: [String: Int] = [:]
            for child in children(of: entity) {
                let name = get(Name.self, for: child)?.value ?? ""
                let n = seen[name, default: 0]
                seen[name] = n + 1
                visit(child, path: path + "/" + name + (n == 0 ? "" : "#\(n + 1)"))
            }
        }
        visit(root, path: get(Name.self, for: root)?.value ?? "")
    }

    /// A 128-bit hash of `path` (two 64-bit FNV-1a variants, finalized).
    static func stableID(_ path: String) -> EntityID {
        var a: UInt64 = 0xcbf2_9ce4_8422_2325, b: UInt64 = 0x6c62_272e_07bb_0142
        for byte in path.utf8 {
            a = (a ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
            b = (b ^ UInt64(byte)) &* 0x9e37_79b9_7f4a_7c15
        }
        func mix(_ x: UInt64) -> UInt64 {
            var z = x &* 0xbf58_476d_1ce4_e5b9
            z = (z ^ (z >> 31)) &* 0x94d0_49bb_1331_11eb
            return z ^ (z >> 29)
        }
        return EntityID(high: mix(a), low: mix(b ^ a))
    }

    /// Prefab instance roots that aren't part of another instance (an instance inside a prefab
    /// belongs to the instance of that prefab), in hierarchy order: under `root`, or in the world.
    public func independentPrefabInstances(under root: Entity? = nil) -> [Entity] {
        var result: [Entity] = []
        func visit(_ entity: Entity, inherited: Set<EntityID>) {
            var inherited = inherited
            if let link = get(PrefabInstance.self, for: entity) {
                if !(id(of: entity).map(inherited.contains) ?? false) { result.append(entity) }
                for ref in link.entities.values { if let id = ref.id { inherited.insert(id) } }
            }
            for child in children(of: entity) { visit(child, inherited: inherited) }
        }
        for top in root.map({ [$0] }) ?? roots { visit(top, inherited: []) }
        return result
    }

    /// The prefab instance `entity` belongs to, or nil: the outermost instance whose prefab has
    /// it (nested instances belong to the prefab containing them), else the nearest instance it
    /// was added under (`local` nil).
    public func prefabLink(of entity: Entity) -> PrefabLink? {
        guard isAlive(entity) else { return nil }
        let entityID = id(of: entity)
        var mapped: PrefabLink?
        var nearest: PrefabLink?
        var current: Entity? = entity
        while let candidate = current {
            if let link = get(PrefabInstance.self, for: candidate) {
                if let local = entityID.flatMap({ link.localID(of: $0) }) {
                    mapped = PrefabLink(root: candidate, prefab: link.prefab, local: local)
                } else if nearest == nil {
                    nearest = PrefabLink(root: candidate, prefab: link.prefab, local: nil)
                }
            }
            current = parent(of: candidate)
        }
        return mapped ?? nearest
    }

    /// Spawns a linked instance of `template` (the prefab `reference`'s) under `parent`: a copy
    /// with new entity ids and a `PrefabInstance` on its root. Returns the root.
    @discardableResult
    public func instantiatePrefab(_ template: PrefabTemplate, reference: AssetReference, under parent: Entity? = nil) throws -> Entity {
        let roots = try load(template.data, under: parent, ids: .regenerate)
        let root = roots[0]
        var entities: [String: EntityRef] = [:]
        for (source, copy) in zip(template.order, subtreeOrder(root)) {
            if let local = template.localID(of: source) { entities[local] = ref(to: copy) }
        }
        add(PrefabInstance(prefab: reference, entities: entities), to: root)
        return root
    }

    /// The overrides of the instance at `root` relative to `template` (the prefab as the
    /// instance was built from it), optionally only those of the prefab entity `local`.
    public func prefabOverrides(of root: Entity, template: PrefabTemplate, only local: String? = nil) -> [PrefabOverride] {
        guard let link = get(PrefabInstance.self, for: root) else { return [] }
        let space = PrefabSpace(instance: self, link: link)
        let templateSpace = PrefabSpace(template: template)
        var result: [PrefabOverride] = []
        for source in template.order {
            guard let sourceLocal = template.localID(of: source), local == nil || local == sourceLocal,
                  let ref = link.entities[sourceLocal] else { continue }
            guard let entity = resolve(ref) else {
                result.append(PrefabOverride(kind: .removedEntity, entity: sourceLocal))
                continue
            }
            let isRoot = source == template.root
            let mine = Self.overridableComponents(of: entity, in: self, isRoot: isRoot)
            let theirs = Self.overridableComponents(of: source, in: template.world, isRoot: isRoot)
            for name in Set(mine.keys).union(theirs.keys).sorted() {
                switch (theirs[name], mine[name]) {
                case (let prefab?, let instance?):
                    guard let a = try? templateSpace.normalized(JSONValue.encoding(prefab)),
                          let b = try? space.normalized(JSONValue.encoding(instance)) else { continue }
                    var changes: [(String, JSONValue)] = []
                    Self.diff(a, b, path: [], into: &changes)
                    for (path, value) in changes {
                        result.append(PrefabOverride(kind: .field, entity: sourceLocal, component: name, path: path, value: value))
                    }
                case (nil, let instance?):
                    let value = (try? space.normalized(JSONValue.encoding(instance))) ?? .null
                    result.append(PrefabOverride(kind: .addedComponent, entity: sourceLocal, component: name, value: value))
                case (_?, nil):
                    result.append(PrefabOverride(kind: .removedComponent, entity: sourceLocal, component: name))
                case (nil, nil):
                    break
                }
            }
        }
        return result
    }

    /// The entities added to the instance at `root`: top-level subtrees under its prefab
    /// entities that aren't the prefab's, with the prefab entity they hang under.
    public func prefabAddedEntities(of root: Entity) -> [(entity: Entity, parent: String)] {
        guard let link = get(PrefabInstance.self, for: root) else { return [] }
        var mapped: [Entity: String] = [:]
        for (local, ref) in link.entities { if let entity = resolve(ref) { mapped[entity] = local } }
        var result: [(Entity, String)] = []
        var stack = [root]
        while let entity = stack.popLast() {
            guard let local = mapped[entity] else { continue }
            for child in children(of: entity).reversed() {
                if mapped[child] == nil { result.append((child, local)) } else { stack.append(child) }
            }
        }
        return result
    }

    /// Rebuilds the instance at `root` from `template` (see "Rebuilding" at the top of the file)
    /// and returns its new root. The overrides are `overrides`, else those found against
    /// `previous` (the template the instance was built from), else the stored ones. With
    /// `keepsAddedEntities` false, children added to the instance are deleted.
    @discardableResult
    public func syncPrefabInstance(_ root: Entity, template: PrefabTemplate, previous: PrefabTemplate?,
                                   overrides given: [PrefabOverride]? = nil, keepsAddedEntities: Bool = true) throws -> Entity {
        precondition(!isIterating, "syncPrefabInstance can't run inside a query")
        guard let link = get(PrefabInstance.self, for: root) else { throw PrefabError.notAnInstance }
        let overrides = given ?? previous.map { prefabOverrides(of: root, template: $0) } ?? link.overrides
        let parent = parent(of: root)
        let index = siblingIndex(of: root)
        let rootTransform = get(Transform.self, for: root)
        let backup = try save([root])

        // Children added to the instance wait outside it.
        var added: [(entity: Entity, parent: String, index: Int)] = []
        for (entity, local) in prefabAddedEntities(of: root) {
            added.append((entity, local, siblingIndex(of: entity) ?? 0))
            setParent(entity, to: nil)
        }
        if !keepsAddedEntities {
            for item in added { despawn(item.entity) }
            added = []
        }
        var ids: [EntityID: EntityID] = [:]
        for (local, ref) in link.entities { if let localID = EntityID(local), let id = ref.id { ids[localID] = id } }
        despawn(root)
        let newRoot: Entity
        do {
            newRoot = try load(template.data, under: parent, ids: .mapping(ids))[0]
        } catch {
            // Put the old instance back as it was.
            let restored = try load(backup, under: parent, ids: .keepUnique)
            for item in added {
                if let host = EntityID(item.parent).flatMap({ ids[$0] }).flatMap(entity(for:)) { setParent(item.entity, to: host, at: item.index) }
            }
            if let index { setParent(restored[0], to: parent, at: index) }
            throw error
        }
        if let index { setParent(newRoot, to: parent, at: index) }
        if let rootTransform { add(rootTransform, to: newRoot) }

        var entities: [String: EntityRef] = [:]
        var byLocal: [String: Entity] = [:]
        for (source, copy) in zip(template.order, subtreeOrder(newRoot)) {
            guard let local = template.localID(of: source) else { continue }
            entities[local] = ref(to: copy)
            byLocal[local] = copy
        }
        let space = PrefabSpace(instance: self, entities: byLocal)
        let applied = overrides.filter { apply($0, space: space, entities: byLocal) }
        for item in added {
            let host = byLocal[item.parent].flatMap { isAlive($0) ? $0 : nil } ?? newRoot
            setParent(item.entity, to: host, at: item.index)
        }
        add(PrefabInstance(prefab: link.prefab, entities: entities, overrides: applied), to: newRoot)
        propagateTransforms()
        return newRoot
    }

    /// Applies one override to the rebuilt instance; false when it no longer fits (dropped).
    private func apply(_ override: PrefabOverride, space: PrefabSpace, entities: [String: Entity]) -> Bool {
        guard let entity = entities[override.entity], isAlive(entity) else { return false }
        switch override.kind {
        case .removedEntity:
            despawn(entity)
            return true
        case .removedComponent:
            guard let name = override.component, let type = ComponentRegistry.type(named: name),
                  component(named: name, of: entity) != nil else { return false }
            remove(type, from: entity)
            return true
        case .addedComponent:
            guard let name = override.component, let type = ComponentRegistry.type(named: name), let value = override.value,
                  let component = try? Self.decodeComponent(type, from: space.denormalized(value)) else { return false }
            add(component, to: entity)
            return true
        case .field:
            guard let name = override.component, let value = override.value, var json = component(named: name, of: entity)
                .flatMap({ try? JSONValue.encoding($0) }) else { return false }
            let keys = override.path.map { $0.isEmpty ? [] : $0.split(separator: ".", omittingEmptySubsequences: false).map(String.init) } ?? []
            guard json.replace(at: keys[...], with: space.denormalized(value)), let type = ComponentRegistry.type(named: name),
                  let component = try? Self.decodeComponent(type, from: json) else { return false }
            add(component, to: entity)
            return true
        }
    }

    /// The prefab's version of `entity`'s component `name` (nil if the prefab entity has none),
    /// with entity references mapped into this instance: what "Revert" puts back.
    public func prefabComponent(named name: String, of entity: Entity, template: PrefabTemplate) throws -> (any Component)? {
        guard let link = prefabLink(of: entity), let local = link.local, let instance = get(PrefabInstance.self, for: link.root) else {
            throw PrefabError.notAnInstance
        }
        guard let source = template.entity(local: local) else { throw PrefabError.noSuchPrefabEntity(local) }
        guard let component = template.world.component(named: name, of: source), let type = ComponentRegistry.type(named: name) else {
            return nil
        }
        let normalized = try PrefabSpace(template: template).normalized(JSONValue.encoding(component))
        return try Self.decodeComponent(type, from: PrefabSpace(instance: self, link: instance).denormalized(normalized))
    }

    /// The prefab's scene data with `entity`'s component `name` set to the instance's (removed
    /// when the instance lacks it): what "Apply to Prefab" writes. `scene` is the prefab's file.
    public func prefabData(applying name: String, of entity: Entity, to scene: Data) throws -> Data {
        guard let link = prefabLink(of: entity), let local = link.local, let instance = get(PrefabInstance.self, for: link.root) else {
            throw PrefabError.notAnInstance
        }
        let prefab = World()
        let roots: [Entity]
        do { roots = try prefab.load(scene, ids: .keepUnique) } catch { throw PrefabError.unreadable("\(error)") }
        guard roots.count == 1 else { throw PrefabError.notOneRoot(roots.count) }
        prefab.assignStableIDs(under: roots[0])
        guard let target = EntityID(local).flatMap({ prefab.entity(for: $0) }) else { throw PrefabError.noSuchPrefabEntity(local) }
        if let component = self.component(named: name, of: entity) {
            guard let type = ComponentRegistry.type(named: name) else { throw SceneError.noSuchComponent(name) }
            let normalized = try PrefabSpace(instance: self, link: instance).normalized(JSONValue.encoding(component))
            prefab.add(try Self.decodeComponent(type, from: PrefabSpace(world: prefab).denormalized(normalized)), to: target)
        } else if let type = ComponentRegistry.type(named: name) {
            prefab.remove(type, from: target)
        }
        return try prefab.save(roots)
    }

    /// Scene data for a prefab made from the subtree at `root`, and which of its entities each
    /// prefab entity is (prefab-local id → `EntityRef`): Create Prefab, and Apply All for an
    /// instance (pass its mapping as `keeping`, so its entities keep their prefab ids; added
    /// ones get new ones). The root loses its `PrefabInstance` and gets `rootTransform`.
    public func prefabData(from root: Entity, keeping links: [String: EntityRef] = [:],
                           rootTransform: Transform?) throws -> (data: Data, entities: [String: EntityRef]) {
        var ids: [EntityID: EntityID] = [:]
        for (local, ref) in links { if let id = ref.id, let localID = EntityID(local) { ids[id] = localID } }
        ensureIDs(inSubtreeOf: root)
        let scratch = World()
        let copy = try scratch.load(save([root]), ids: .mapping(ids))[0]
        scratch.remove(PrefabInstance.self, from: copy)
        if let rootTransform { scratch.add(rootTransform, to: copy) }
        var entities: [String: EntityRef] = [:]
        for (original, prefabEntity) in zip(subtreeOrder(root), scratch.subtreeOrder(copy)) {
            if let local = scratch.id(of: prefabEntity) { entities[local.description] = ref(to: original) }
        }
        return (try scratch.save([copy]), entities)
    }

    /// The components compared for overrides: serialized ones by name, without the
    /// `PrefabInstance` link and, on the root, the `Transform` (the instance's placement).
    static func overridableComponents(of entity: Entity, in world: World, isRoot: Bool) -> [String: any Component] {
        var result: [String: any Component] = [:]
        for component in world.components(of: entity) {
            let componentType = type(of: component)
            guard componentType.isSerialized, componentType != PrefabInstance.self,
                  !(isRoot && componentType == Transform.self) else { continue }
            result[componentType.componentName] = component
        }
        return result
    }

    /// The paths (and `b`'s values) where `a` and `b` differ: objects key by key, arrays of the
    /// same length element by element, anything else as a whole.
    static func diff(_ a: JSONValue, _ b: JSONValue, path: [String], into changes: inout [(String, JSONValue)]) {
        guard a != b else { return }
        switch (a, b) {
        case (.object(let x), .object(let y)) where !PrefabSpace.isReference(a) && !PrefabSpace.isReference(b):
            for key in Set(x.keys).union(y.keys).sorted() {
                diff(x[key] ?? .null, y[key] ?? .null, path: path + [key], into: &changes)
            }
        case (.array(let x), .array(let y)) where x.count == y.count:
            for i in x.indices { diff(x[i], y[i], path: path + [String(i)], into: &changes) }
        default:
            changes.append((path.joined(separator: "."), b))
        }
    }

    static func decodeComponent(_ type: any Component.Type, from json: JSONValue) throws -> any Component {
        func decode<C: Component>(_: C.Type) throws -> any Component { try json.decode(C.self) }
        return try decode(type)
    }
}

/// Converts entity references in component JSON between a world and prefab-relative form:
/// `.entity(e)` ↔ `{"$prefabEntity": local}` and `{"$ref": id}` ↔ `{"$prefabRef": local}` for
/// entities of the prefab; other references stay as they are (dead handles become null).
@MainActor
struct PrefabSpace {
    let world: World
    let localOfID: (EntityID) -> String?
    let idOfLocal: (String) -> EntityID?

    /// An instance, through its link's mapping.
    init(instance world: World, link: PrefabInstance) {
        var locals: [EntityID: String] = [:]
        for (local, ref) in link.entities { if let id = ref.id { locals[id] = local } }
        self.world = world
        localOfID = { locals[$0] }
        idOfLocal = { link.entities[$0]?.id }
    }

    /// An instance being rebuilt, through its new entities.
    init(instance world: World, entities: [String: Entity]) {
        var locals: [EntityID: String] = [:]
        var ids: [String: EntityID] = [:]
        for (local, entity) in entities { if let id = world.id(of: entity) { locals[id] = local; ids[local] = id } }
        self.world = world
        localOfID = { locals[$0] }
        idOfLocal = { ids[$0] }
    }

    /// A template, or the prefab's own world: ids are the prefab-local ones.
    init(template: PrefabTemplate) { self.init(world: template.world) }

    init(world: World) {
        self.world = world
        localOfID = { world.entity(for: $0) != nil ? $0.description : nil }
        idOfLocal = { EntityID($0).flatMap { world.entity(for: $0) != nil ? $0 : nil } }
    }

    static func isReference(_ json: JSONValue) -> Bool {
        guard case .object(let members) = json, members.count == 1, let key = members.keys.first else { return false }
        return key == EntityRef.codingKey || key == "$prefabEntity" || key == "$prefabRef"
    }

    func normalized(_ json: JSONValue) -> JSONValue {
        switch json {
        case .entity(let entity):
            guard world.isAlive(entity) else { return .null }
            if let id = world.id(of: entity), let local = localOfID(id) { return .object(["$prefabEntity": .string(local)]) }
            return json
        case .object(let members):
            if members.count == 1, case .string(let text)? = members[EntityRef.codingKey], let id = EntityID(text),
               let local = localOfID(id) {
                return .object(["$prefabRef": .string(local)])
            }
            return .object(members.mapValues(normalized))
        case .array(let items):
            return .array(items.map(normalized))
        default:
            return json
        }
    }

    func denormalized(_ json: JSONValue) -> JSONValue {
        switch json {
        case .object(let members):
            if members.count == 1, case .string(let local)? = members["$prefabEntity"] {
                return idOfLocal(local).flatMap { world.entity(for: $0) }.map { JSONValue.entity($0) } ?? .null
            }
            if members.count == 1, case .string(let local)? = members["$prefabRef"] {
                return idOfLocal(local).map { .object([EntityRef.codingKey: .string($0.description)]) } ?? .null
            }
            return .object(members.mapValues(denormalized))
        case .array(let items):
            return .array(items.map(denormalized))
        default:
            return json
        }
    }
}

/// Keeps a world's prefab instances in step with their prefabs in an `AssetDatabase`: remembers
/// the template each prefab's instances were last built from, rebuilds them when the prefab
/// changes (keeping their overrides), and writes their current overrides into their
/// `PrefabInstance`s. The editor runs `sync` after imports and when a scene opens, and
/// `refreshOverrides` before saving; a game with hot reload can do the same from the
/// database's `onChange`.
@MainActor
public final class PrefabSync {
    /// The template each prefab's instances were last built from.
    private var built: [AssetReference: PrefabTemplate] = [:]
    /// The current template of each prefab, with the revisions it was built at.
    private var current: [AssetReference: (revisions: [AssetID: Int], template: PrefabTemplate)] = [:]

    public init() {}

    /// Forgets what instances were built from (a scene was opened or closed): the next `sync`
    /// rebuilds every instance with its stored overrides.
    public func reset() {
        built = [:]
        current = [:]
    }

    /// The prefab's template as it is now (cached until the prefab or a nested one is reimported).
    public func template(for reference: AssetReference, in database: AssetDatabase) -> PrefabTemplate? {
        if let cached = current[reference],
           cached.revisions.allSatisfy({ database.revision(of: $0.key) == $0.value }) {
            return cached.template
        }
        guard let prefab = database.prefab(reference),
              let template = try? prefab.template(prefabs: { database.prefab($0) }) else { return nil }
        var revisions = [reference.asset: database.revision(of: reference.asset)]
        for id in template.nestedPrefabs { revisions[id] = database.revision(of: id) }
        current[reference] = (revisions, template)
        return template
    }

    /// The template the instances of `reference` were last built from (nil: not built yet in
    /// this session).
    public func builtTemplate(for reference: AssetReference) -> PrefabTemplate? { built[reference] }

    /// Records that new instances of `reference` are built from `template`.
    public func didBuild(_ reference: AssetReference, from template: PrefabTemplate) {
        if built[reference] == nil { built[reference] = template }
    }

    /// Rebuilds every instance whose prefab changed since it was built (with `force`, every
    /// instance whose prefab is available, using the stored overrides when there is nothing to
    /// compare with). Returns the new roots. Instances whose prefab is missing are left alone.
    @discardableResult
    public func sync(_ world: World, database: AssetDatabase, force: Bool = false) -> [Entity] {
        var rebuilt: [Entity] = []
        var updated: [AssetReference: PrefabTemplate] = [:]
        for root in world.independentPrefabInstances() {
            guard world.isAlive(root), let link = world.get(PrefabInstance.self, for: root),
                  let template = updated[link.prefab] ?? template(for: link.prefab, in: database) else { continue }
            updated[link.prefab] = template
            let previous = built[link.prefab]
            if !force, let previous, previous.data == template.data { continue }
            if previous == nil && !force { continue }
            do {
                rebuilt.append(try world.syncPrefabInstance(root, template: template, previous: previous))
            } catch {
                print("Prefab: rebuilding an instance of \(link.prefab) failed: \(error)")
            }
        }
        for (reference, template) in updated { built[reference] = template }
        return rebuilt
    }

    /// Takes the current templates as what the instances were built from, without rebuilding
    /// them (after updating the instances some other way).
    public func markBuilt(_ world: World, database: AssetDatabase) {
        for root in world.independentPrefabInstances() {
            guard let link = world.get(PrefabInstance.self, for: root), let template = template(for: link.prefab, in: database) else { continue }
            built[link.prefab] = template
        }
    }

    /// The overrides of the instance at `root` now (against the template it was built from).
    public func overrides(of root: Entity, in world: World, database: AssetDatabase, only local: String? = nil) -> [PrefabOverride]? {
        guard let link = world.get(PrefabInstance.self, for: root),
              let template = built[link.prefab] ?? template(for: link.prefab, in: database) else { return nil }
        return world.prefabOverrides(of: root, template: template, only: local)
    }

    /// Writes every instance's current overrides into its `PrefabInstance` (not an undo step).
    public func refreshOverrides(in world: World, database: AssetDatabase) {
        for root in world.independentPrefabInstances() {
            guard var link = world.get(PrefabInstance.self, for: root),
                  let overrides = overrides(of: root, in: world, database: database), overrides != link.overrides else { continue }
            link.overrides = overrides
            world.add(link, to: root)
        }
    }
}
