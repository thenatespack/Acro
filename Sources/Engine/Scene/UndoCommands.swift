import Foundation

// The built-in `UndoCommand`s. All of them name entities by `EntityID`, so they keep working
// when the entity is despawned and recreated by another command's undo, or the world is
// restored from a snapshot. Each is created with the `Entity` handles the editor has at
// hand (`in: world` turns them into ids, giving the entity an id if it has none) or
// directly with ids.
//
// Components are captured as values, not encoded: an exact copy, so undo can't drift. The
// exception is whole entities (`DespawnCommand`, `SpawnCommand`), which are captured as
// scene-file data, the same machinery as save and load, so they bring back hierarchy,
// sibling order and ids. What a scene file can't hold doesn't survive a despawn: references
// from outside the subtree to its entities, and references from inside to outside, because
// they are handles that die with the entity (see `DespawnCommand`).

extension World {
    /// The live entity for `id`, or throws `UndoError.entityNotFound`.
    func resolve(_ id: EntityID) throws -> Entity {
        guard let entity = entity(for: id) else { throw UndoError.entityNotFound(id) }
        return entity
    }

    /// `entity`'s id, assigning one if needed, or throws for a stale handle.
    func requireID(of entity: Entity) throws -> EntityID {
        guard let id = ensureID(of: entity) else { throw UndoError.entityNotFound(EntityID(high: 0, low: 0)) }
        return id
    }
}

/// Sets one field of a component, by reflection path (see `World.setField`).
public struct SetFieldCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    public let component: String
    public let path: String
    public private(set) var oldValue: FieldValue
    public private(set) var newValue: FieldValue

    public init(id: EntityID, component: String, path: String, old: FieldValue, new: FieldValue, label: String? = nil) {
        self.id = id
        self.component = component
        self.path = path
        oldValue = old
        newValue = new
        self.label = label ?? "Edit \(path)"
    }

    /// Reads the field's current value as the old one. Throws if the component or field
    /// doesn't exist.
    public init(_ entity: Entity, _ component: String, _ path: String, to new: FieldValue, in world: World, label: String? = nil) throws {
        let id = try world.requireID(of: entity)
        guard let value = world.component(named: component, of: entity) else { throw SceneError.noSuchComponent(component) }
        guard let field = value.field(at: path) else { throw SceneError.noSuchField(path) }
        self.init(id: id, component: component, path: path, old: field.value ?? .null, new: new, label: label)
    }

    public mutating func perform(in world: World) throws {
        try world.setField(path, of: component, for: world.resolve(id), to: newValue)
    }

    public mutating func revert(in world: World) throws {
        try world.setField(path, of: component, for: world.resolve(id), to: oldValue)
    }

    /// Edits of the same field merge: the first old value and the last new value remain.
    public mutating func merge(_ next: any UndoCommand) -> Bool {
        guard let next = next as? SetFieldCommand, next.id == id, next.component == component, next.path == path else { return false }
        newValue = next.newValue
        return true
    }
}

/// A component value an undo command holds: the value itself, or, after its type was taken
/// out for a reload (`detach`), its JSON under the component's name until a type with that
/// name is registered again (`resolve`). See "Reloading component types" in UndoStack.swift.
@MainActor public struct HeldComponent {
    /// The component's name (`componentName`).
    public let name: String
    private var storage: Storage

    private enum Storage {
        case value(any Component)
        case json(JSONValue)
    }

    public init(_ component: any Component) {
        name = type(of: component).componentName
        storage = .value(component)
    }

    init(name: String, json: JSONValue) {
        self.name = name
        storage = .json(json)
    }

    /// The value; nil while it is held as JSON.
    public var value: (any Component)? {
        if case .value(let component) = storage { component } else { nil }
    }

    /// Whether it is held as JSON.
    public var isDetached: Bool { value == nil }

    /// Encodes the value as JSON if its name is in `names`.
    public mutating func detach(ifNamedIn names: Set<String>) throws {
        guard names.contains(name), case .value(let component) = storage else { return }
        storage = .json(try JSONValue.encoding(component))
    }

    /// Decodes the JSON with the type registered under the name, over `defaults(name)` (see
    /// `World.resolveUnresolvedComponents(defaults:)`). Returns whether it is a value now.
    public mutating func resolve(defaults: (String) -> (any Component)?) -> Bool {
        guard case .json(let json) = storage, let type = ComponentRegistry.type(named: name) else { return false }
        let base = defaults(name).flatMap { try? JSONValue.encoding($0) }
        guard case .success(let (component, _)) = World.decodeTolerantly(type, raw: json, base: base) else { return false }
        storage = .value(component)
        return true
    }

    /// Puts it on `entity`: the value, or the JSON as an unresolved component (replacing any
    /// component with the name either way).
    public func add(to entity: Entity, in world: World) {
        switch storage {
        case .value(let component):
            world.add(component, to: entity)
        case .json(let json):
            world.removeComponent(named: name, from: entity)
            var unresolved = world.get(UnresolvedComponents.self, for: entity)?.components ?? [:]
            unresolved[name] = json
            world.add(UnresolvedComponents(components: unresolved), to: entity)
        }
    }
}

extension World {
    /// `entity`'s component named `name` as an undo command keeps it: typed, or the raw JSON of
    /// an unresolved one.
    func heldComponent(named name: String, of entity: Entity) -> HeldComponent? {
        if let component = component(named: name, of: entity) { return HeldComponent(component) }
        if let json = get(UnresolvedComponents.self, for: entity)?.components[name] { return HeldComponent(name: name, json: json) }
        return nil
    }

    /// Removes `entity`'s component named `name`, typed or unresolved.
    func removeComponent(named name: String, from entity: Entity) {
        if let store = storeOrder.first(where: { $0.componentType.componentName == name && ObjectIdentifier($0.componentType) != ObjectIdentifier(UnresolvedComponents.self) }) {
            remove(store.componentType, from: entity)
        }
        if var unresolved = get(UnresolvedComponents.self, for: entity), unresolved.components[name] != nil {
            unresolved.components[name] = nil
            if unresolved.components.isEmpty {
                remove(UnresolvedComponents.self, from: entity)
            } else {
                add(unresolved, to: entity)
            }
        }
    }
}

/// Replaces a whole component the entity has.
public struct SetComponentCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    public let componentName: String
    private var old: HeldComponent
    private var new: HeldComponent

    /// The values (nil while held as JSON across a reload).
    public var oldComponent: (any Component)? { old.value }
    public var newComponent: (any Component)? { new.value }

    public init(id: EntityID, old: any Component, new: any Component, label: String? = nil) {
        self.id = id
        componentName = type(of: new).componentName
        self.old = HeldComponent(old)
        self.new = HeldComponent(new)
        self.label = label ?? "Edit \(componentName)"
    }

    /// Captures the entity's current component as the old one. Throws if it has none.
    public init<C: Component>(_ entity: Entity, to new: C, in world: World, label: String? = nil) throws {
        let id = try world.requireID(of: entity)
        guard let old = world.get(C.self, for: entity) else { throw UndoError.componentNotFound(C.componentName) }
        self.init(id: id, old: old, new: new, label: label)
    }

    public mutating func perform(in world: World) throws {
        new.add(to: try world.resolve(id), in: world)
    }

    public mutating func revert(in world: World) throws {
        old.add(to: try world.resolve(id), in: world)
    }

    public mutating func merge(_ next: any UndoCommand) -> Bool {
        guard let next = next as? SetComponentCommand, next.id == id, next.componentName == componentName else { return false }
        new = next.new
        return true
    }

    public mutating func detachComponents(named names: Set<String>) throws {
        try old.detach(ifNamedIn: names)
        try new.detach(ifNamedIn: names)
    }

    public mutating func resolveDetachedComponents(defaults: (String) -> (any Component)?) -> Int {
        (old.resolve(defaults: defaults) ? 1 : 0) + (new.resolve(defaults: defaults) ? 1 : 0)
    }
}

/// Adds a component the entity doesn't have (or replaces one it has; undo then puts that
/// one back).
public struct AddComponentCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    private var added: HeldComponent
    /// What the entity had before, captured the first time the command runs.
    private var replaced: HeldComponent?

    /// The component it adds (nil while held as JSON across a reload).
    public var component: (any Component)? { added.value }
    public var componentName: String { added.name }

    public init(id: EntityID, component: any Component, label: String? = nil) {
        self.id = id
        added = HeldComponent(component)
        self.label = label ?? "Add \(type(of: component).componentName)"
    }

    public init(_ entity: Entity, _ component: any Component, in world: World, label: String? = nil) throws {
        self.init(id: try world.requireID(of: entity), component: component, label: label)
    }

    public mutating func perform(in world: World) throws {
        let entity = try world.resolve(id)
        replaced = world.heldComponent(named: added.name, of: entity)
        added.add(to: entity, in: world)
    }

    public mutating func revert(in world: World) throws {
        let entity = try world.resolve(id)
        if let replaced { replaced.add(to: entity, in: world) } else { world.removeComponent(named: added.name, from: entity) }
    }

    public mutating func detachComponents(named names: Set<String>) throws {
        try added.detach(ifNamedIn: names)
        try replaced?.detach(ifNamedIn: names)
    }

    public mutating func resolveDetachedComponents(defaults: (String) -> (any Component)?) -> Int {
        (added.resolve(defaults: defaults) ? 1 : 0) + (replaced?.resolve(defaults: defaults) == true ? 1 : 0)
    }
}

/// Removes a component; undo restores its exact data.
public struct RemoveComponentCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    /// The name of the component type it removes (by name, so it survives the type being
    /// replaced by a reload).
    public let componentName: String
    private var removed: HeldComponent?

    public init(id: EntityID, componentType: any Component.Type, label: String? = nil) {
        self.id = id
        componentName = componentType.componentName
        self.label = label ?? "Remove \(componentType.componentName)"
    }

    public init(_ entity: Entity, _ componentType: any Component.Type, in world: World, label: String? = nil) throws {
        self.init(id: try world.requireID(of: entity), componentType: componentType, label: label)
    }

    public mutating func perform(in world: World) throws {
        let entity = try world.resolve(id)
        guard let current = world.heldComponent(named: componentName, of: entity) else {
            throw UndoError.componentNotFound(componentName)
        }
        removed = current
        world.removeComponent(named: componentName, from: entity)
    }

    public mutating func revert(in world: World) throws {
        guard let removed else { return }
        removed.add(to: try world.resolve(id), in: world)
    }

    public mutating func detachComponents(named names: Set<String>) throws {
        try removed?.detach(ifNamedIn: names)
    }

    public mutating func resolveDetachedComponents(defaults: (String) -> (any Component)?) -> Int {
        removed?.resolve(defaults: defaults) == true ? 1 : 0
    }
}

/// Sets or changes an entity's `Name`; undo restores the old name, or removes the component
/// if there was none.
public struct RenameCommand: UndoCommand {
    public var label = "Rename"
    public let id: EntityID
    public private(set) var oldName: String?
    public private(set) var newName: String

    public init(id: EntityID, old: String?, new: String) {
        self.id = id
        oldName = old
        newName = new
    }

    public init(_ entity: Entity, to name: String, in world: World) throws {
        self.init(id: try world.requireID(of: entity), old: world.get(Name.self, for: entity)?.value, new: name)
    }

    public mutating func perform(in world: World) throws {
        world.add(Name(newName), to: try world.resolve(id))
    }

    public mutating func revert(in world: World) throws {
        let entity = try world.resolve(id)
        if let oldName { world.add(Name(oldName), to: entity) } else { world.remove(Name.self, from: entity) }
    }

    public mutating func merge(_ next: any UndoCommand) -> Bool {
        guard let next = next as? RenameCommand, next.id == id else { return false }
        newName = next.newName
        return true
    }
}

/// Creates entities from scene-file data (components, hierarchy, ids) under a parent.
/// Undo despawns them; redo creates them again with the same ids. Use it to create,
/// duplicate and paste.
public struct SpawnCommand: UndoCommand {
    public var label: String
    /// The ids of the created roots, in order: known before the command runs, so the
    /// editor can select them afterwards with `world.entity(for:)`.
    public let rootIDs: [EntityID]
    private let data: Data
    private let parent: EntityID?
    private let index: Int?

    /// Spawns the subtrees in `data` (a scene file). The ids in it are normalized now:
    /// entities without ids get new ones, and with `regenerateIDs` all do (a duplicate).
    /// `index` is the position among the new parent's children (or the roots).
    public init(subtree data: Data, parent: Entity? = nil, index: Int? = nil, regenerateIDs: Bool = false,
                in world: World, label: String = "Create Entity") throws {
        let scratch = World()
        scratch.assignsEntityIDs = true
        let roots = try scratch.load(data, ids: regenerateIDs ? .regenerate : .keepUnique)
        self.data = try scratch.save()
        rootIDs = roots.compactMap { scratch.id(of: $0) }
        self.parent = try parent.map { try world.requireID(of: $0) }
        self.index = index
        self.label = label
    }

    /// One new entity with `components` (and a `Name` if given).
    public init(components: [any Component], name: String? = nil, parent: Entity? = nil, index: Int? = nil,
                in world: World, label: String = "Create Entity") throws {
        let scratch = World()
        let entity = scratch.spawn()
        for component in components { scratch.add(component, to: entity) }
        if let name { scratch.add(Name(name), to: entity) }
        try self.init(subtree: scratch.save(), parent: parent, index: index, in: world, label: label)
    }

    /// Copies of `entities` and their subtrees, with new ids, placed under `parent`.
    public init(duplicating entities: [Entity], parent: Entity? = nil, index: Int? = nil,
                in world: World, label: String = "Duplicate") throws {
        try self.init(subtree: world.save(entities), parent: parent, index: index, regenerateIDs: true, in: world, label: label)
    }

    public mutating func perform(in world: World) throws {
        let parentEntity = try parent.map { try world.resolve($0) }
        let roots = try world.load(data, under: parentEntity, ids: .keepUnique)
        if let index {
            for (k, root) in roots.enumerated() { world.setParent(root, to: parentEntity, at: index + k) }
        }
    }

    public mutating func revert(in world: World) throws {
        // Resolve everything first so a missing entity leaves the world untouched.
        let entities = try rootIDs.map { try world.resolve($0) }
        for entity in entities { world.despawn(entity) }
    }
}

/// Despawns an entity and its subtree. Undo restores all of it: components (including
/// unresolved ones), hierarchy, sibling order and the same `EntityID`s, so commands deeper
/// in the stack still resolve.
///
/// What the entities were is captured as scene-file data the first time the command runs,
/// so references between entities inside the subtree come back mapped to the new handles.
/// References that cross the subtree's boundary don't: a component elsewhere that held a
/// handle to a despawned entity is stale (as always), and a reference from inside to an
/// entity outside loads as nil/`Entity.invalid`.
public struct DespawnCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    private var captured: Captured?

    private struct Captured {
        var data: Data
        var parent: EntityID?
        var index: Int
    }

    public init(id: EntityID, label: String = "Delete Entity") {
        self.id = id
        self.label = label
    }

    public init(_ entity: Entity, in world: World, label: String = "Delete Entity") throws {
        self.init(id: try world.requireID(of: entity), label: label)
    }

    public mutating func perform(in world: World) throws {
        let entity = try world.resolve(id)
        if captured == nil {
            world.ensureIDs(inSubtreeOf: entity)
            captured = Captured(
                data: try world.save([entity]),
                parent: world.parent(of: entity).flatMap { world.id(of: $0) },
                index: world.siblingIndex(of: entity) ?? 0)
        }
        world.despawn(entity)
    }

    public mutating func revert(in world: World) throws {
        guard let captured else { return }
        let parent = try captured.parent.map { try world.resolve($0) }
        let roots = try world.load(captured.data, under: parent, ids: .keepUnique)
        for root in roots { world.setParent(root, to: parent, at: captured.index) }
    }
}

/// Replaces an entity's subtree with other scene-file data (one root) in the same place: same
/// parent and sibling position. Both versions keep the ids in their data, so the entities of a
/// subtree that is rebuilt with the same ids (a prefab instance reverted to its prefab) stay
/// the same to every other command. Undo puts the old subtree back.
public struct ReplaceSubtreeCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    private let before: Data
    private let after: Data
    private let parent: EntityID?
    private let index: Int

    /// Replaces `entity`'s subtree with `data`, whose root has `entity`'s id.
    public init(_ entity: Entity, with data: Data, in world: World, label: String) throws {
        id = try world.requireID(of: entity)
        world.ensureIDs(inSubtreeOf: entity)
        before = try world.save([entity])
        after = data
        parent = world.parent(of: entity).flatMap { world.id(of: $0) }
        index = world.siblingIndex(of: entity) ?? 0
        self.label = label
    }

    public mutating func perform(in world: World) throws { try replace(with: after, in: world) }
    public mutating func revert(in world: World) throws { try replace(with: before, in: world) }

    private func replace(with data: Data, in world: World) throws {
        let entity = try world.resolve(id)
        let parentEntity = try parent.map { try world.resolve($0) }
        world.despawn(entity)
        let roots = try world.load(data, under: parentEntity, ids: .keepUnique)
        for root in roots { world.setParent(root, to: parentEntity, at: index) }
    }
}

/// Changes an entity's parent and its position among the siblings. Undo restores the old
/// parent, the old sibling index and, with `keepWorldTransform`, the old local `Transform`
/// exactly (redo restores the one it computed, so no round-off accumulates).
public struct ReparentCommand: UndoCommand {
    public var label: String
    public let id: EntityID
    public let newParent: EntityID?
    public let newIndex: Int?
    public let keepWorldTransform: Bool
    private var before: State?
    private var after: Transform?

    private struct State {
        var parent: EntityID?
        var index: Int
        var transform: Transform?
    }

    public init(id: EntityID, newParent: EntityID?, index: Int? = nil, keepWorldTransform: Bool = false, label: String = "Reparent") {
        self.id = id
        self.newParent = newParent
        newIndex = index
        self.keepWorldTransform = keepWorldTransform
        self.label = label
    }

    public init(_ entity: Entity, to parent: Entity?, index: Int? = nil, keepWorldTransform: Bool = false,
                in world: World, label: String = "Reparent") throws {
        self.init(id: try world.requireID(of: entity), newParent: try parent.map { try world.requireID(of: $0) },
                  index: index, keepWorldTransform: keepWorldTransform, label: label)
    }

    public mutating func perform(in world: World) throws {
        let entity = try world.resolve(id)
        let parent = try newParent.map { try world.resolve($0) }
        let state = State(
            parent: world.parent(of: entity).flatMap { world.id(of: $0) },
            index: world.siblingIndex(of: entity) ?? 0,
            transform: world.get(Transform.self, for: entity))
        // The first run computes the new local transform; a redo puts the same one back.
        let keep = keepWorldTransform && after == nil
        guard world.setParent(entity, to: parent, at: newIndex, keepWorldTransform: keep) else { throw UndoError.invalidReparent }
        if keepWorldTransform {
            if let after { world.add(after, to: entity) } else { after = world.get(Transform.self, for: entity) }
        }
        before = state
    }

    public mutating func revert(in world: World) throws {
        guard let before else { return }
        let entity = try world.resolve(id)
        let parent = try before.parent.map { try world.resolve($0) }
        guard world.setParent(entity, to: parent, at: before.index) else { throw UndoError.invalidReparent }
        if keepWorldTransform, let transform = before.transform { world.add(transform, to: entity) }
    }
}

/// Anything else: two closures. They must be inverses, and shouldn't capture `Entity`
/// handles (use `EntityID`s and `world.entity(for:)`).
public struct ClosureCommand: UndoCommand {
    public var label: String
    private let doIt: @MainActor (World) throws -> Void
    private let undoIt: @MainActor (World) throws -> Void

    public init(_ label: String, perform: @escaping @MainActor (World) throws -> Void, revert: @escaping @MainActor (World) throws -> Void) {
        self.label = label
        doIt = perform
        undoIt = revert
    }

    public mutating func perform(in world: World) throws { try doIt(world) }
    public mutating func revert(in world: World) throws { try undoIt(world) }
}
