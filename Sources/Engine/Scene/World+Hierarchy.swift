// Parent/child relationships. They live in side tables indexed by entity slot rather than
// in components, so they can't be edited into an inconsistent state (a parent that doesn't
// list its child, a cycle). Serialization saves them through `parent(of:)` and restores
// them with `setParent`.

extension World {
    /// `entity`'s parent, or nil for a root or a stale handle.
    public func parent(of entity: Entity) -> Entity? {
        isAlive(entity) ? parents[Int(entity.index)] : nil
    }

    /// `entity`'s children, in the order they were attached.
    public func children(of entity: Entity) -> [Entity] {
        isAlive(entity) ? childLists[Int(entity.index)] : []
    }

    /// Makes `child` a child of `parent`, or a root when `parent` is nil. Applies immediately,
    /// also during queries.
    ///
    /// With `keepWorldTransform` false (the default), the child's `Transform` is kept, so it
    /// is now interpreted relative to the new parent and the child moves with it. With true,
    /// the `Transform` is rewritten so the child stays where it is in the world (shear can't be
    /// represented, see `Transform.init(matrix:)`).
    ///
    /// Returns false, changing nothing, if either entity is stale or the change would make a
    /// cycle (parenting an entity to itself or one of its descendants).
    @discardableResult
    public func setParent(_ child: Entity, to parent: Entity?, keepWorldTransform: Bool = false) -> Bool {
        guard isAlive(child) else { return false }
        if let parent {
            guard isAlive(parent) else { return false }
            var ancestor: Entity? = parent
            while let current = ancestor {
                if current == child { return false }
                ancestor = parents[Int(current.index)]
            }
        }
        let slot = Int(child.index)
        let oldParent = parents[slot]
        if oldParent == parent { return true }
        let world = keepWorldTransform ? worldMatrix(of: child) : nil

        if let oldParent { childLists[Int(oldParent.index)].removeAll { $0 == child } }
        parents[slot] = parent
        if let parent { childLists[Int(parent.index)].append(child) }

        if let world, has(Transform.self, for: child) {
            let parentWorld = parent.map(worldMatrix(of:)) ?? .identity
            modify(Transform.self, for: child) { $0 = Transform(matrix: parentWorld.inverse * world) }
        }
        return true
    }

    /// Whether `ancestor` is `entity`'s parent, grandparent, and so on.
    public func isDescendant(_ entity: Entity, of ancestor: Entity) -> Bool {
        var current = parent(of: entity)
        while let next = current {
            if next == ancestor { return true }
            current = parents[Int(next.index)]
        }
        return false
    }
}
