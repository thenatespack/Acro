import Engine

/// The editor's selection: a set of entities plus a primary one (what the inspector shows and
/// `F` frames). It stores `EntityID`s, never `Entity` handles, so it survives everything that
/// changes handles: undo / redo of deletes, play mode's snapshot restore, reloading.
///
/// Ids are kept even when their entity is gone (deleted, or spawned in play mode and dropped
/// on stop); `entities(in:)` and `primaryEntity(in:)` resolve only live ones, so an undo that
/// brings an entity back also brings back its selection. `prune(in:)` drops dead ids
/// explicitly (the document does it on New / Open).
@MainActor
public final class EditorSelection {
    /// Selected ids in selection order (the primary is included).
    public private(set) var ids: [EntityID] = []
    public private(set) var primary: EntityID?
    /// Increases on every change.
    public private(set) var version = 0
    private var observers: [(EditorSelection) -> Void] = []

    public init() {}

    /// Calls `body` after every change.
    public func observe(_ body: @escaping (EditorSelection) -> Void) {
        observers.append(body)
    }

    public var isEmpty: Bool { ids.isEmpty }
    public var count: Int { ids.count }
    public func contains(_ id: EntityID) -> Bool { ids.contains(id) }

    /// Selects exactly `ids` (duplicates dropped). `primary` must be among them (it is added if
    /// not); nil picks the last one.
    public func set(_ ids: [EntityID], primary: EntityID? = nil) {
        var unique: [EntityID] = []
        var seen = Set<EntityID>()
        for id in ids where seen.insert(id).inserted { unique.append(id) }
        if let primary, !seen.contains(primary) { unique.append(primary) }
        let newPrimary = primary ?? unique.last
        guard unique != self.ids || newPrimary != self.primary else { return }
        self.ids = unique
        self.primary = newPrimary
        changed()
    }

    /// Selects only `id` (nil clears).
    public func select(_ id: EntityID?) {
        set(id.map { [$0] } ?? [])
    }

    /// Adds `id` (it becomes the primary) or, when already selected, removes it.
    public func toggle(_ id: EntityID) {
        if let index = ids.firstIndex(of: id) {
            var rest = ids
            rest.remove(at: index)
            set(rest, primary: primary == id ? rest.last : primary)
        } else {
            set(ids + [id], primary: id)
        }
    }

    public func clear() { set([]) }

    /// The live selected entities, in selection order.
    public func entities(in world: World) -> [Entity] {
        ids.compactMap { world.entity(for: $0) }
    }

    /// The primary entity if it is alive, else the last live selected one.
    public func primaryEntity(in world: World) -> Entity? {
        if let primary, let entity = world.entity(for: primary) { return entity }
        return ids.reversed().lazy.compactMap { world.entity(for: $0) }.first
    }

    /// The live selected entities that have no selected ancestor (what delete and duplicate act
    /// on: their descendants come along), in hierarchy order.
    public func topLevelEntities(in world: World) -> [Entity] {
        let selected = Set(entities(in: world))
        var result: [Entity] = []
        func visit(_ entity: Entity) {
            if selected.contains(entity) { result.append(entity); return }
            for child in world.children(of: entity) { visit(child) }
        }
        for root in world.roots { visit(root) }
        return result
    }

    /// Drops ids whose entities don't exist in `world`.
    public func prune(in world: World) {
        let live = ids.filter { world.entity(for: $0) != nil }
        guard live.count != ids.count else { return }
        set(live, primary: primary.flatMap { live.contains($0) ? $0 : nil })
    }

    private func changed() {
        version += 1
        for observer in observers { observer(self) }
    }
}
