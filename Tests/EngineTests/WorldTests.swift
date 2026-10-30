import Foundation
import Testing
@testable import Engine

private struct Position: Component, Equatable { var value: Vec3 }
private struct Velocity: Component, Equatable { var value: Vec3 }
private struct Health: Component, Equatable { var points: Int }
private struct Tag: Component {}

private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool { length(a - b) < eps }

// MARK: Entities and components

@MainActor @Test func staleHandlesAreDetectedAfterSlotReuse() {
    let world = World()
    let a = world.spawn(Health(points: 1))
    world.despawn(a)
    #expect(!world.isAlive(a))
    let b = world.spawn(Health(points: 2))
    #expect(b.index == a.index && b.generation == a.generation + 1)
    #expect(world.isAlive(b) && !world.isAlive(a))
    // The stale handle sees nothing and changes nothing.
    #expect(world.get(Health.self, for: a) == nil)
    world.add(Health(points: 99), to: a)
    world.remove(Health.self, from: a)
    world.despawn(a)
    #expect(world.get(Health.self, for: b) == Health(points: 2))
    #expect(world.isAlive(b) && world.entityCount == 1)
    #expect(world.components(of: a).isEmpty)
}

@MainActor @Test func addReplaceRemoveAndGet() {
    let world = World()
    let e = world.spawn()
    #expect(world.components(of: e).isEmpty)
    world.add(Position(value: Vec3(1, 2, 3)), to: e)
    world.add(Velocity(value: .one), to: e)
    #expect(world.has(Position.self, for: e) && world.count(of: Position.self) == 1)
    world.add(Position(value: .zero), to: e)  // replaces
    #expect(world.get(Position.self, for: e) == Position(value: .zero))
    #expect(world.count(of: Position.self) == 1)
    world.modify(Velocity.self, for: e) { $0.value.x = 5 }
    #expect(world.get(Velocity.self, for: e)?.value.x == 5)
    #expect(world.modify(Health.self, for: e) { _ in 1 } == nil)
    world.remove(Position.self, from: e)
    #expect(!world.has(Position.self, for: e) && world.has(Velocity.self, for: e))
}

@MainActor @Test func removalKeepsOtherEntitiesIntact() {
    // Swap-removal moves the last element; every survivor must keep its own value.
    let world = World()
    let entities = (0..<10).map { world.spawn(Health(points: $0)) }
    for i in [0, 9, 4, 5] { world.remove(Health.self, from: entities[i]) }
    for (i, e) in entities.enumerated() {
        #expect(world.get(Health.self, for: e) == ([0, 9, 4, 5].contains(i) ? nil : Health(points: i)))
    }
    var seen: [Int] = []
    world.query(Health.self) { _, h in seen.append(h.points) }
    #expect(seen.sorted() == [1, 2, 3, 6, 7, 8])
}

@MainActor @Test func queriesMatchEntitiesWithAllComponents() {
    let world = World()
    let both = world.spawn(Position(value: .zero), Velocity(value: Vec3(1, 0, 0)))
    let onlyPosition = world.spawn(Position(value: .zero))
    let three = world.spawn(Position(value: .zero), Velocity(value: Vec3(0, 1, 0)), Health(points: 3))
    _ = world.spawn(Velocity(value: .zero))

    var matched: Set<Entity> = []
    world.query(Position.self, Velocity.self) { e, _, _ in matched.insert(e) }
    #expect(matched.count == 2 && matched.contains(both) && matched.contains(three) && !matched.contains(onlyPosition))

    world.queryMutating(Position.self, Velocity.self) { _, p, v in p.value += v.value }
    #expect(world.get(Position.self, for: both)?.value == Vec3(1, 0, 0))
    #expect(world.get(Position.self, for: three)?.value == Vec3(0, 1, 0))
    #expect(world.get(Position.self, for: onlyPosition)?.value == .zero)

    var triples = 0
    world.query(Position.self, Velocity.self, Health.self) { e, _, _, h in
        triples += 1
        #expect(e == three && h.points == 3)
    }
    #expect(triples == 1)
    world.queryMutating(Position.self, Velocity.self, Health.self, Tag.self) { _, _, _, _, _ in Issue.record("no Tag") }
    world.add(Tag(), to: three)
    var quads = 0
    world.queryMutating(Position.self, Velocity.self, Health.self, Tag.self) { _, _, _, h, _ in
        h.points += 1
        quads += 1
    }
    #expect(quads == 1 && world.get(Health.self, for: three)?.points == 4)
    // A component type never added: queries are empty, not a crash.
    world.query(Health.self, Tag.self, Velocity.self, Position.self) { _, _, _, _, _ in quads += 1 }
    #expect(quads == 2)
}

@MainActor @Test func structuralChangesDuringQueriesAreDeferred() {
    let world = World()
    let entities = (0..<6).map { world.spawn(Health(points: $0), Velocity(value: .zero)) }

    var visited = 0
    world.query(Health.self, Velocity.self) { e, h, _ in
        visited += 1
        // Remove from entities not yet visited and ones already visited, despawn some,
        // and add new components: none of it may disturb this iteration.
        world.remove(Velocity.self, from: entities[(Int(h.points) + 3) % 6])
        if h.points % 2 == 0 { world.despawn(e) }
        world.add(Tag(), to: e)
        #expect(world.isAlive(e) && world.has(Velocity.self, for: e))  // still there until the query ends
        #expect(!world.has(Tag.self, for: e))
        #expect(world.isIterating)
    }
    #expect(visited == 6)
    #expect(!world.isIterating)
    #expect(world.entityCount == 3)
    for (i, e) in entities.enumerated() {
        #expect(world.isAlive(e) == (i % 2 == 1))
    }
    #expect(world.count(of: Velocity.self) == 0)
    #expect(world.count(of: Tag.self) == 3)

    // Spawning inside a query: the handle is live at once, its components arrive afterwards.
    var spawned: Entity?
    world.query(Health.self) { _, _ in
        if spawned == nil {
            spawned = world.spawn(Health(points: 100))
            #expect(world.isAlive(spawned!) && !world.has(Health.self, for: spawned!))
        }
    }
    #expect(world.get(Health.self, for: spawned!) == Health(points: 100))
}

@MainActor @Test func queryMutatingWritesBackAndAllowsReadingOthers() {
    let world = World()
    let leader = world.spawn(Position(value: Vec3(10, 0, 0)))
    let follower = world.spawn(Position(value: .zero))
    world.queryMutating(Position.self) { e, p in
        // Reading the same store (another entity) inside the body is allowed.
        if e == follower { p.value = world.get(Position.self, for: leader)!.value }
        // Nested queries are allowed too.
        world.query(Position.self) { _, _ in }
    }
    #expect(world.get(Position.self, for: follower)?.value == Vec3(10, 0, 0))
}

@MainActor @Test func componentsCanBeEnumeratedAndMovedDynamically() {
    let world = World()
    let e = world.spawn(Health(points: 7), Position(value: Vec3(1, 1, 1)))
    let other = world.spawn(Velocity(value: .zero))
    world.add(Tag(), to: e)
    #expect(world.componentTypes(of: e).map { $0.componentName } == ["Health", "Position", "Tag"])
    #expect(world.registeredComponentTypes.map { $0.componentName } == ["Health", "Position", "Velocity", "Tag"])
    // What serialization will do: copy components through existentials.
    let copy = world.spawn()
    for component in world.components(of: e) { world.add(component, to: copy) }
    #expect(world.get(Health.self, for: copy) == Health(points: 7))
    #expect(world.get(Position.self, for: copy) == Position(value: Vec3(1, 1, 1)))
    for type in world.componentTypes(of: copy) { world.remove(type, from: copy) }
    #expect(world.components(of: copy).isEmpty)
    #expect(world.componentTypes(of: other).map { $0.componentName } == ["Velocity"])
}

// MARK: Hierarchy

@MainActor @Test func hierarchyPropagatesWorldMatrices() {
    let world = World()
    let root = world.spawn(Transform(position: Vec3(10, 0, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))))
    let child = world.spawn(Transform(position: Vec3(0, 0, -2), scale: Vec3(repeating: 2)))
    let grandchild = world.spawn(Transform(position: Vec3(1, 0, 0)))
    #expect(world.setParent(child, to: root))
    #expect(world.setParent(grandchild, to: child))
    world.propagateTransforms()

    // root rotates -Z onto -X: child sits at (8, 0, 0); the grandchild's +X is scaled by 2
    // and rotated onto -Z.
    #expect(approx(world.get(GlobalTransform.self, for: child)!.position, Vec3(8, 0, 0)))
    #expect(approx(world.get(GlobalTransform.self, for: grandchild)!.position, Vec3(8, 0, -2)))
    let fresh = world.worldMatrix(of: grandchild)
    #expect(approx(world.get(GlobalTransform.self, for: grandchild)!.position, Vec3(fresh.c3.x, fresh.c3.y, fresh.c3.z)))

    // Moving the root moves the whole subtree on the next propagation.
    world.modify(Transform.self, for: root) { $0.position.y = 5 }
    world.propagateTransforms()
    #expect(approx(world.get(GlobalTransform.self, for: grandchild)!.position, Vec3(8, 5, -2)))

    #expect(world.children(of: root) == [child] && world.parent(of: grandchild) == child)
    #expect(world.isDescendant(grandchild, of: root) && !world.isDescendant(root, of: grandchild))
    #expect(!world.setParent(root, to: grandchild))  // cycle rejected
    #expect(!world.setParent(root, to: root))
    #expect(world.parent(of: root) == nil)
}

@MainActor @Test func reparentingKeepsLocalOrWorldTransform() {
    let world = World()
    let a = world.spawn(Transform(position: Vec3(5, 0, 0)))
    let b = world.spawn(Transform(position: Vec3(0, 3, 0), rotation: Quat(angle: 0.5, axis: Vec3(0, 0, 1)), scale: Vec3(repeating: 2)))
    let child = world.spawn(Transform(position: Vec3(1, 0, 0)))
    world.setParent(child, to: a)
    world.propagateTransforms()
    #expect(approx(world.get(GlobalTransform.self, for: child)!.position, Vec3(6, 0, 0)))

    // Keep world: stays at (6, 0, 0) under b, with a rewritten local transform.
    world.setParent(child, to: b, keepWorldTransform: true)
    world.propagateTransforms()
    #expect(approx(world.get(GlobalTransform.self, for: child)!.position, Vec3(6, 0, 0)))
    #expect(world.children(of: a).isEmpty && world.children(of: b) == [child])
    #expect(abs(world.get(Transform.self, for: child)!.scale.x - 0.5) < 1e-5)

    // Keep local: the same local transform now relative to a, so it moves.
    let local = world.get(Transform.self, for: child)!
    world.setParent(child, to: a)
    world.propagateTransforms()
    #expect(world.get(Transform.self, for: child) == local)
    #expect(approx(world.get(GlobalTransform.self, for: child)!.position, Vec3(5, 0, 0) + local.position))

    // Detach to a root with keepWorldTransform: world position unchanged.
    let before = world.get(GlobalTransform.self, for: child)!.position
    world.setParent(child, to: nil, keepWorldTransform: true)
    world.propagateTransforms()
    #expect(approx(world.get(GlobalTransform.self, for: child)!.position, before))
    #expect(world.parent(of: child) == nil)
}

@MainActor @Test func reparentingWithoutLocalChangeUpdatesGlobal() {
    // Dirty tracking must notice a new parent even when nothing else changed.
    let world = World()
    let a = world.spawn(Transform(position: Vec3(1, 0, 0)))
    let b = world.spawn(Transform(position: Vec3(0, 0, 7)))
    let child = world.spawn(Transform())
    world.setParent(child, to: a)
    world.propagateTransforms()
    world.setParent(child, to: b)
    world.propagateTransforms()
    #expect(world.get(GlobalTransform.self, for: child)!.position == Vec3(0, 0, 7))
    // Removing the parent's Transform makes the child a root.
    world.remove(Transform.self, from: b)
    world.propagateTransforms()
    #expect(world.get(GlobalTransform.self, for: child)!.position == .zero)
}

@MainActor @Test func deepChainsPropagateInParentFirstOrder() {
    let world = World()
    // Spawn children before parents so storage order is the reverse of hierarchy order.
    let depth = 5000
    let chain = (0..<depth).map { _ in world.spawn(Transform(position: Vec3(1, 0, 0))) }.reversed().map { $0 }
    for i in 1..<depth { world.setParent(chain[i], to: chain[i - 1]) }
    world.propagateTransforms()
    #expect(world.get(GlobalTransform.self, for: chain[depth - 1])!.position == Vec3(Float(depth), 0, 0))
    world.modify(Transform.self, for: chain[0]) { $0.position.x = 0 }
    world.propagateTransforms()
    #expect(world.get(GlobalTransform.self, for: chain[depth - 1])!.position == Vec3(Float(depth - 1), 0, 0))
    #expect(world.get(GlobalTransform.self, for: chain[1])!.position == Vec3(1, 0, 0))
}

@MainActor @Test func despawningAParentDespawnsItsSubtree() {
    let world = World()
    let keep = world.spawn(Transform())
    let parent = world.spawn(Transform())
    let child = world.spawn(Transform())
    let grandchild = world.spawn(Transform())
    let rescued = world.spawn(Transform())
    world.setParent(parent, to: keep)
    world.setParent(child, to: parent)
    world.setParent(grandchild, to: child)
    world.setParent(rescued, to: child)
    world.setParent(rescued, to: nil)  // reparent to keep it
    world.despawn(parent)
    #expect(!world.isAlive(parent) && !world.isAlive(child) && !world.isAlive(grandchild))
    #expect(world.isAlive(keep) && world.isAlive(rescued))
    #expect(world.children(of: keep).isEmpty)
    #expect(world.count(of: Transform.self) == 2 && world.entityCount == 2)
    // Reused slots start without a parent or children.
    let fresh = world.spawn()
    #expect(world.parent(of: fresh) == nil && world.children(of: fresh).isEmpty)

    // Deferred during a query: the subtree goes when the query ends.
    let p = world.spawn(Transform()), c = world.spawn(Transform())
    world.setParent(c, to: p)
    world.query(Transform.self) { e, _ in if e == p { world.despawn(p) } }
    #expect(!world.isAlive(p) && !world.isAlive(c))
}

// MARK: Systems

@MainActor @Test func fixedStepAccumulatesAndExposesAlpha() {
    let world = World()
    world.fixedTimestep = 0.1
    var steps = 0
    var deltas: Set<Float> = []
    world.addSystem("count", stage: .fixedUpdate) { w in
        steps += 1
        deltas.insert(w.time.delta)
    }
    world.update(dt: 0.05)
    #expect(steps == 0 && abs(world.time.alpha - 0.5) < 1e-5)
    world.update(dt: 0.07)
    #expect(steps == 1 && abs(world.time.alpha - 0.2) < 1e-4)
    world.update(dt: 0.25)
    #expect(steps == 3 && abs(world.time.alpha - 0.7) < 1e-4)
    #expect(world.time.fixedStepsThisFrame == 2 && world.time.fixedStepCount == 3)
    #expect(deltas == [0.1])
    #expect(abs(world.time.fixedElapsed - 0.3) < 1e-9 && abs(world.time.elapsed - 0.37) < 1e-9)
    #expect(world.time.frame == 3)
}

@MainActor @Test func fixedStepIsClampedToAvoidSpiralOfDeath() {
    let world = World()
    world.fixedTimestep = 0.01
    world.maxFixedStepsPerFrame = 4
    var steps = 0
    world.addSystem("count", stage: .fixedUpdate) { _ in steps += 1 }
    world.update(dt: 0.105)  // 10.5 steps' worth
    #expect(steps == 4)
    #expect(world.time.droppedFixedSteps == 6)
    #expect(abs(world.time.alpha - 0.5) < 1e-3)  // the sub-step remainder is kept
    world.update(dt: 0.005)
    #expect(steps == 5)
}

@MainActor @Test func fixedStepIsExactForMultipleRates() {
    // A 120 Hz step at a 60 Hz frame rate (screenshot mode's dt) runs exactly twice a frame.
    let world = World()
    world.fixedTimestep = 1.0 / 120.0
    var perFrame: [Int] = []
    for _ in 0..<600 {
        world.update(dt: 1.0 / 60.0)
        perFrame.append(world.time.fixedStepsThisFrame)
    }
    #expect(perFrame.allSatisfy { $0 == 2 })
    world.fixedTimestep = 1.0 / 60.0
    world.update(dt: 1.0 / 60.0)
    #expect(world.time.fixedStepsThisFrame == 1)
}

@MainActor @Test func stagesRunInOrderAroundPropagation() {
    let world = World()
    var log: [String] = []
    let e = world.spawn(Transform())
    world.addSystem("render", stage: .renderPrep) { w in
        log.append("render:\(w.get(GlobalTransform.self, for: e)!.position.x)")
    }
    world.addSystem("late", stage: .lateUpdate) { w in
        log.append("late")
        w.modify(Transform.self, for: e) { $0.position.x += 1 }
    }
    world.addSystem("update", stage: .update) { _ in log.append("update") }
    world.addSystem("fixed", stage: .fixedUpdate) { _ in log.append("fixed") }
    world.addSystem("first", stage: .update, before: "update") { _ in log.append("first") }
    world.addSystem("third", stage: .update, after: "update") { _ in log.append("third") }
    #expect(world.systemNames(in: .update) == ["first", "update", "third"])
    world.update(dt: 1.0 / 60.0)
    #expect(log == ["fixed", "first", "update", "third", "late", "render:1.0"])

    #expect(world.removeSystem(named: "update") && !world.removeSystem(named: "update"))
    log = []
    world.update(dt: 0)
    #expect(log == ["first", "third", "late", "render:2.0"])
}

// MARK: Benchmark

/// Prints how long a two-component query over 100k entities takes. The number is only
/// meaningful in release: `swift test -c release -Xswiftc -enable-testing --filter worldQueryBenchmark`.
@MainActor @Test func worldQueryBenchmark() {
    let world = World()
    let count = 100_000
    for i in 0..<count {
        world.add(Position(value: Vec3(Float(i), 0, 0)), to: world.spawn())
    }
    // Velocity on every entity, added in a different order than Position.
    for e in world.entities.reversed() { world.add(Velocity(value: Vec3(0, 1, 0)), to: e) }
    let clock = ContinuousClock()
    var best = Duration.seconds(1000)
    var bestRead = Duration.seconds(1000)
    var bestTransforms = Duration.seconds(1000)
    for _ in 0..<20 {
        let t0 = clock.now
        world.queryMutating(Position.self, Velocity.self) { _, p, v in p.value += v.value * 0.016 }
        best = min(best, clock.now - t0)
        var sum: Float = 0
        let t1 = clock.now
        world.query(Position.self, Velocity.self) { _, p, v in sum += p.value.y + v.value.y }
        bestRead = min(bestRead, clock.now - t1)
        #expect(sum > 0)
    }
    // Transform propagation over 100k roots, all dirty (the worst case) and all clean.
    let transforms = World()
    for i in 0..<count { _ = transforms.spawn(Transform(position: Vec3(Float(i), 0, 0))) }
    transforms.propagateTransforms()
    var bestClean = Duration.seconds(1000)
    for _ in 0..<10 {
        transforms.queryMutating(Transform.self) { _, t in t.position.y += 1 }
        let t0 = clock.now
        transforms.propagateTransforms()
        bestTransforms = min(bestTransforms, clock.now - t0)
        let t1 = clock.now
        transforms.propagateTransforms()
        bestClean = min(bestClean, clock.now - t1)
    }
    print("World benchmark, \(count) entities: queryMutating(2) \(best), query(2) \(bestRead), "
        + "propagateTransforms dirty \(bestTransforms), clean \(bestClean)")
}
