/// An entity's position, rotation and scale relative to its parent (or the world, for an
/// entity without a parent). See `World.setParent(_:to:keepWorldTransform:)`.
public struct Transform: Component, Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat
    public var scale: Vec3

    public static let componentName = "Transform"

    public init(position: Vec3 = .zero, rotation: Quat = .identity, scale: Vec3 = .one) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    /// Decomposes an affine matrix into translation, rotation and scale. Shear (from
    /// non-uniform scale under a rotated parent) can't be represented and is lost; a
    /// mirroring matrix gets a negative x scale.
    public init(matrix m: Mat4) {
        let c0 = Vec3(m.c0.x, m.c0.y, m.c0.z), c1 = Vec3(m.c1.x, m.c1.y, m.c1.z), c2 = Vec3(m.c2.x, m.c2.y, m.c2.z)
        var s = Vec3(length(c0), length(c1), length(c2))
        if dot(cross(c0, c1), c2) < 0 { s.x = -s.x }
        position = Vec3(m.c3.x, m.c3.y, m.c3.z)
        scale = s
        if s.x == 0 || s.y == 0 || s.z == 0 {
            rotation = .identity
        } else {
            let r = Mat4(Vec4(c0 / s.x, 0), Vec4(c1 / s.y, 0), Vec4(c2 / s.z, 0), Vec4(0, 0, 0, 1))
            rotation = Quat(rotationMatrix: r).normalized
        }
    }

    /// Local-to-parent matrix: scale, then rotate, then translate.
    public var matrix: Mat4 { Mat4(translation: position, rotation: rotation, scale: scale) }
}

/// An entity's local-to-world matrix, computed from its `Transform` and its ancestors' by
/// `World.propagateTransforms()` (run every frame after `.lateUpdate`). Added automatically
/// to entities with a `Transform`; read-only for game code. Derived data: scene files don't
/// store it (it is recomputed after loading), and decoding one yields a matrix that the next
/// propagation recomputes.
public struct GlobalTransform: Component, Sendable {
    public static let componentName = "GlobalTransform"
    public static var isSerialized: Bool { false }
    public static var fieldHints: [String: FieldHints] { ["matrix": FieldHints(readOnly: true)] }

    public internal(set) var matrix: Mat4 = .identity

    // What `matrix` was computed from, for dirty tracking: it is recomputed only when the
    // local transform, the transform parent, or (transitively) an ancestor changed.
    var local = Transform()
    var parent: Entity?
    var isValid = false

    public init() {}

    /// World-space position.
    public var position: Vec3 { Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z) }

    private enum CodingKeys: String, CodingKey { case matrix }

    public init(from decoder: any Decoder) throws {
        matrix = try decoder.container(keyedBy: CodingKeys.self).decode(Mat4.self, forKey: .matrix)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matrix, forKey: .matrix)
    }
}

extension World {
    /// Updates every `GlobalTransform` from the hierarchy, parents before children, adding
    /// missing ones. Runs automatically in `update(dt:)` between `.lateUpdate` and
    /// `.renderPrep`; call it directly to get world matrices outside a frame (e.g. after
    /// building a scene). Can't be called from inside a query.
    ///
    /// An entity's transform parent is its hierarchy parent if that has a `Transform`.
    /// Otherwise (no parent, or a parent without one) the entity is a root and its world
    /// matrix is its local one. Only dirty subtrees do matrix work; clean entities cost a
    /// comparison of their `Transform` against the cached copy.
    ///
    /// Root subtrees are independent (each entity is written by its own root's walk only), so
    /// they are walked in parallel on `jobs`, in batches of roots; every matrix is the same
    /// product whichever thread computes it, so results don't depend on the thread count.
    public func propagateTransforms(jobs: JobSystem = .shared) {
        precondition(!isIterating, "propagateTransforms() can't run inside a query")
        guard let transforms = existingStore(Transform.self) else { return }
        let globals = store(GlobalTransform.self)
        for entity in transforms.entities where !globals.contains(entity) {
            globals.insert(GlobalTransform(), for: entity)
        }

        // Nothing below changes the stores' layout or the hierarchy, so loop over snapshots.
        let locals = transforms.view, globalsView = globals.view
        let parents = parents, childLists = childLists
        var roots: [Int] = []
        for (dense, entity) in locals.entities.enumerated() {
            if let parent = parents[Int(entity.index)], locals.denseIndex(of: parent) != nil { continue }
            roots.append(dense)
        }

        // Depth-first from each root with an explicit stack, so deep chains can't overflow.
        jobs.parallelFor(roots.indices, batchSize: 256, name: "transform roots") { range in
            var stack: [(entity: Entity, dense: Int, parent: Entity?, parentMatrix: Mat4, parentDirty: Bool)] = []
            for rootDense in roots[range] {
                stack.append((locals.entities[rootDense], rootDense, nil, .identity, false))
                while let (entity, dense, parent, parentMatrix, parentDirty) = stack.popLast() {
                    let local = locals.values[dense]
                    let g = globalsView.values + globalsView.denseIndex(of: entity)!
                    let dirty = parentDirty || !g.pointee.isValid || g.pointee.parent != parent || g.pointee.local != local
                    if dirty {
                        g.pointee.matrix = parentMatrix * local.matrix
                        g.pointee.local = local
                        g.pointee.parent = parent
                        g.pointee.isValid = true
                    }
                    let children = childLists[Int(entity.index)]
                    if children.isEmpty { continue }
                    let matrix = g.pointee.matrix
                    for child in children {
                        if let childDense = locals.denseIndex(of: child) {
                            stack.append((child, childDense, entity, matrix, dirty))
                        }
                    }
                }
            }
        }
    }

    /// `entity`'s local-to-world matrix computed now from the `Transform`s up its hierarchy
    /// (`GlobalTransform` is only as fresh as the last propagation). Identity without a `Transform`.
    public func worldMatrix(of entity: Entity) -> Mat4 {
        guard let transforms = existingStore(Transform.self), let dense = transforms.denseIndex(of: entity) else {
            return .identity
        }
        var matrix = transforms.values[dense].matrix
        var current = entity
        while let parent = parents[Int(current.index)], let p = transforms.denseIndex(of: parent) {
            matrix = transforms.values[p].matrix * matrix
            current = parent
        }
        return matrix
    }
}
