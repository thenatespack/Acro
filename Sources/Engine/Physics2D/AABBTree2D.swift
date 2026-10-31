/// The 2D broadphase: a dynamic AABB tree (after Box2D's `b2DynamicTree`). Leaves hold "fat"
/// boxes, a margin larger than their shape, so a body that moves a little doesn't touch the
/// tree. Leaves are inserted next to the sibling that grows the tree's surface the least,
/// and AVL-style rotations keep it balanced. Everything is index based and the results of
/// queries only depend on the sequence of insertions and removals, so it is deterministic.
struct AABBTree2D {
    struct Node {
        var box: AABB2
        var parent = -1
        var left = -1, right = -1
        /// -1 for a free node, 0 for a leaf.
        var height = 0
        /// The leaf's payload (a body index).
        var item = -1
        var isLeaf: Bool { left < 0 }
    }

    private(set) var nodes: [Node] = []
    private var root = -1
    private var freeList: [Int] = []

    var isEmpty: Bool { root < 0 }

    /// Inserts a leaf for `item` with box `box`; returns the leaf's id.
    mutating func insert(_ box: AABB2, item: Int) -> Int {
        let leaf = allocate(Node(box: box, item: item))
        insertLeaf(leaf)
        return leaf
    }

    mutating func remove(_ leaf: Int) {
        removeLeaf(leaf)
        nodes[leaf].height = -1
        nodes[leaf].item = -1
        freeList.append(leaf)
    }

    /// Replaces the leaf's box (removing and reinserting it).
    mutating func update(_ leaf: Int, box: AABB2) {
        removeLeaf(leaf)
        nodes[leaf].box = box
        insertLeaf(leaf)
    }

    func box(_ leaf: Int) -> AABB2 { nodes[leaf].box }

    /// Calls `body` with every leaf item whose box overlaps `box`. Return false to stop.
    func query(_ box: AABB2, _ body: (Int) -> Bool) {
        guard root >= 0 else { return }
        var stack = [root]
        while let n = stack.popLast() {
            let node = nodes[n]
            guard node.box.overlaps(box) else { continue }
            if node.isLeaf {
                if !body(node.item) { return }
            } else {
                stack.append(node.right)
                stack.append(node.left)
            }
        }
    }

    /// Calls `body` with every leaf item whose box the ray `origin + t * direction`, t in
    /// [0, maxT], passes through. `body` returns the new maxT (to clip the ray), or a negative
    /// value to stop.
    func raycast(origin: Vec2, direction: Vec2, maxT: Float, _ body: (Int) -> Float) {
        guard root >= 0 else { return }
        let inv = Vec2(1, 1) / direction
        var limit = maxT
        var stack = [root]
        while let n = stack.popLast() {
            let node = nodes[n]
            guard node.box.raycast(origin: origin, inverseDirection: inv, maxT: limit) != nil else { continue }
            if node.isLeaf {
                let t = body(node.item)
                if t < 0 { return }
                limit = min(limit, t)
            } else {
                stack.append(node.right)
                stack.append(node.left)
            }
        }
    }

    // MARK: - Internals

    private mutating func allocate(_ node: Node) -> Int {
        if let index = freeList.popLast() {
            nodes[index] = node
            return index
        }
        nodes.append(node)
        return nodes.count - 1
    }

    private mutating func insertLeaf(_ leaf: Int) {
        nodes[leaf].parent = -1
        guard root >= 0 else {
            root = leaf
            return
        }
        // Find the best sibling: descend toward the child whose cost grows the least.
        let box = nodes[leaf].box
        var index = root
        while !nodes[index].isLeaf {
            let node = nodes[index]
            let area = node.box.perimeter
            let combined = node.box.union(box).perimeter
            let cost = 2 * combined
            let inheritance = 2 * (combined - area)
            func childCost(_ c: Int) -> Float {
                let merged = nodes[c].box.union(box).perimeter
                return nodes[c].isLeaf ? merged + inheritance : merged - nodes[c].box.perimeter + inheritance
            }
            let costLeft = childCost(node.left), costRight = childCost(node.right)
            if cost < costLeft && cost < costRight { break }
            index = costLeft <= costRight ? node.left : node.right
        }

        let sibling = index
        let oldParent = nodes[sibling].parent
        var parentNode = Node(box: box.union(nodes[sibling].box))
        parentNode.parent = oldParent
        parentNode.left = sibling
        parentNode.right = leaf
        parentNode.height = nodes[sibling].height + 1
        let newParent = allocate(parentNode)
        if oldParent >= 0 {
            if nodes[oldParent].left == sibling { nodes[oldParent].left = newParent } else { nodes[oldParent].right = newParent }
        } else {
            root = newParent
        }
        nodes[sibling].parent = newParent
        nodes[leaf].parent = newParent
        refit(from: newParent)
    }

    private mutating func removeLeaf(_ leaf: Int) {
        if leaf == root {
            root = -1
            return
        }
        let parent = nodes[leaf].parent
        let grandParent = nodes[parent].parent
        let sibling = nodes[parent].left == leaf ? nodes[parent].right : nodes[parent].left
        if grandParent >= 0 {
            if nodes[grandParent].left == parent { nodes[grandParent].left = sibling } else { nodes[grandParent].right = sibling }
            nodes[sibling].parent = grandParent
            free(parent)
            refit(from: grandParent)
        } else {
            root = sibling
            nodes[sibling].parent = -1
            free(parent)
        }
    }

    private mutating func free(_ node: Int) {
        nodes[node].height = -1
        nodes[node].left = -1
        nodes[node].right = -1
        freeList.append(node)
    }

    /// Walks up from `start`, rebalancing and recomputing boxes and heights.
    private mutating func refit(from start: Int) {
        var index = start
        while index >= 0 {
            index = balance(index)
            let l = nodes[index].left, r = nodes[index].right
            nodes[index].height = 1 + max(nodes[l].height, nodes[r].height)
            nodes[index].box = nodes[l].box.union(nodes[r].box)
            index = nodes[index].parent
        }
    }

    /// Rotates the higher grandchild up if `a`'s children differ in height by more than one.
    /// Returns the node now at `a`'s position.
    private mutating func balance(_ a: Int) -> Int {
        if nodes[a].isLeaf || nodes[a].height < 2 { return a }
        let b = nodes[a].left, c = nodes[a].right
        let diff = nodes[c].height - nodes[b].height
        if diff > 1 { return rotate(a, up: c, other: b) }
        if diff < -1 { return rotate(a, up: b, other: c) }
        return a
    }

    /// Makes child `up` of `a` take `a`'s place; `a` keeps `other` and the shorter child of `up`.
    private mutating func rotate(_ a: Int, up c: Int, other b: Int) -> Int {
        let f = nodes[c].left, g = nodes[c].right
        nodes[c].left = a
        nodes[c].parent = nodes[a].parent
        nodes[a].parent = c
        let p = nodes[c].parent
        if p >= 0 {
            if nodes[p].left == a { nodes[p].left = c } else { nodes[p].right = c }
        } else {
            root = c
        }
        let (keep, give) = nodes[f].height > nodes[g].height ? (f, g) : (g, f)
        nodes[c].right = keep
        if nodes[a].left == c { nodes[a].left = give } else { nodes[a].right = give }
        nodes[give].parent = a
        nodes[a].box = nodes[b].box.union(nodes[give].box)
        nodes[c].box = nodes[a].box.union(nodes[keep].box)
        nodes[a].height = 1 + max(nodes[b].height, nodes[give].height)
        nodes[c].height = 1 + max(nodes[a].height, nodes[keep].height)
        return c
    }
}
