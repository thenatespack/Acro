import Foundation
import Testing
@testable import Engine

private struct Gadget: Component, Equatable {
    static let componentName = "Test.UndoGadget"
    var power: Float = 1
    var label = "g"
    var partner: Entity?
}

private struct Tagged: Component, Equatable {
    static let componentName = "Test.UndoTagged"
    var value = 0
}

/// `a`...`f` resolve through the ids, so they stay valid after commands recreate entities.
@MainActor private struct Fixture {
    let world: World
    let undo: UndoStack
    let ids: [EntityID]
    var a: Entity { world.entity(for: ids[0])! }
    var b: Entity { world.entity(for: ids[1])! }
    var c: Entity { world.entity(for: ids[2])! }
    var d: Entity { world.entity(for: ids[3])! }
    var e: Entity { world.entity(for: ids[4])! }
    var f: Entity { world.entity(for: ids[5])! }
}

/// a: root with children b and c; c has child d; e and f are roots. c and d refer to each
/// other, and d to b, b to d, so subtrees have references among their own entities.
@MainActor private func makeFixture() -> Fixture {
    let world = World()
    world.assignsEntityIDs = true
    let a = world.spawn(Transform(position: Vec3(1, 2, 3), rotation: Quat(angle: 0.5, axis: Vec3(0, 1, 0))), Name("A"))
    let b = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("B"), Gadget(power: 2))
    let c = world.spawn(Transform(position: Vec3(0, 0, 1), scale: Vec3(2, 2, 2)), Name("C"))
    let d = world.spawn(Transform(position: Vec3(5, 0, 0)), Gadget(label: "deep"))
    let e = world.spawn(Transform(position: Vec3(9, 9, 9)))
    let f = world.spawn(Name("F"))
    world.setParent(b, to: a)
    world.setParent(c, to: a)
    world.setParent(d, to: c)
    world.add(Gadget(power: 3, label: "d", partner: c), to: d)
    world.add(Gadget(power: 1, label: "c", partner: d), to: c)
    let ids = [a, b, c, d, e, f].map { world.ensureID(of: $0)! }
    return Fixture(world: world, undo: UndoStack(world: world), ids: ids)
}

@MainActor private func bytes(_ world: World) -> Data { try! world.save() }

/// Runs `edit`, then checks that undoing everything gives the world back exactly, and that
/// redoing gives the edited world exactly, twice over.
@MainActor private func expectRoundTrip(_ fx: Fixture, steps: Int = 1, _ edit: () throws -> Void, sourceLocation: SourceLocation = #_sourceLocation) throws {
    let original = bytes(fx.world)
    try edit()
    let edited = bytes(fx.world)
    #expect(edited != original, "the edit changed nothing", sourceLocation: sourceLocation)
    for _ in 0..<2 {
        for _ in 0..<steps { #expect(try fx.undo.undo(), sourceLocation: sourceLocation) }
        #expect(bytes(fx.world) == original, "undo didn't restore the world", sourceLocation: sourceLocation)
        for _ in 0..<steps { #expect(try fx.undo.redo(), sourceLocation: sourceLocation) }
        #expect(bytes(fx.world) == edited, "redo didn't reproduce the edit", sourceLocation: sourceLocation)
    }
    for _ in 0..<steps { try fx.undo.undo() }
    #expect(bytes(fx.world) == original, sourceLocation: sourceLocation)
}

// MARK: Built-in commands

@MainActor @Test func setFieldRoundTripsForEveryKindOfValue() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.a, "Transform", "position", to: .vec3(Vec3(7, 8, 9)), in: w, label: "Move")) }
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.a, "Transform", "rotation", to: .quat(Quat(angle: 1.1, axis: Vec3(1, 0, 0))), in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.b, "Test.UndoGadget", "power", to: .float(0.1), in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.b, "Test.UndoGadget", "label", to: .string("x"), in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.b, "Test.UndoGadget", "partner", to: .entity(fx.e), in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(SetFieldCommand(fx.d, "Test.UndoGadget", "partner", to: .null, in: w)) }
    #expect(fx.undo.undoLabel == nil)  // all undone
    try fx.undo.perform(SetFieldCommand(fx.a, "Transform", "position", to: .vec3(.zero), in: w, label: "Move"))
    #expect(fx.undo.undoLabel == "Move" && fx.undo.undoTitle == "Undo Move" && fx.undo.redoTitle == "Redo")
    #expect(throws: SceneError.self) { try SetFieldCommand(fx.a, "Transform", "nope", to: .float(1), in: w) }
    #expect(throws: SceneError.self) { try SetFieldCommand(fx.a, "Test.UndoGadget", "power", to: .float(1), in: w) }
}

@MainActor @Test func setWholeComponentAddAndRemove() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) {
        try fx.undo.perform(SetComponentCommand(fx.a, to: Transform(position: Vec3(4, 4, 4)), in: w))
    }
    // Add a new component, and add over an existing one.
    try expectRoundTrip(fx) { try fx.undo.perform(AddComponentCommand(fx.f, Tagged(value: 4), in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(AddComponentCommand(fx.b, Gadget(power: 77), in: w)) }
    // Remove restores the exact data, even a reference.
    try expectRoundTrip(fx) { try fx.undo.perform(RemoveComponentCommand(fx.d, Gadget.self, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(RemoveComponentCommand(fx.a, Transform.self, in: w)) }
    #expect(throws: UndoError.self) { try fx.undo.perform(RemoveComponentCommand(fx.f, Tagged.self, in: w)) }
    #expect(throws: UndoError.self) { try SetComponentCommand(fx.f, to: Tagged(), in: w) }
    #expect(fx.undo.undoDepth == 0)  // failures record nothing
}

@MainActor @Test func renameCoversNamedAndUnnamedEntities() throws {
    let fx = makeFixture()
    try expectRoundTrip(fx) { try fx.undo.perform(RenameCommand(fx.a, to: "Renamed", in: fx.world)) }
    try expectRoundTrip(fx) { try fx.undo.perform(RenameCommand(fx.e, to: "Now named", in: fx.world)) }
    #expect(fx.world.get(Name.self, for: fx.e) == nil)  // undo removed the component again
    try fx.undo.perform(RenameCommand(fx.e, to: "x", in: fx.world))
    #expect(fx.undo.undoTitle == "Undo Rename")
}

@MainActor @Test func spawnCreatesWithComponentsAndRedoKeepsTheSameID() throws {
    let fx = makeFixture()
    let w = fx.world
    var created: EntityID!
    try expectRoundTrip(fx) {
        let command = try SpawnCommand(components: [Transform(position: Vec3(1, 1, 1)), Gadget(power: 5)], name: "Fresh", parent: fx.c, index: 0, in: w)
        created = command.rootIDs[0]
        try fx.undo.perform(command)
    }
    try fx.undo.redo()
    let entity = try #require(w.entity(for: created))
    #expect(w.get(Name.self, for: entity) == "Fresh" && w.get(Gadget.self, for: entity)?.power == 5)
    #expect(w.parent(of: entity) == fx.c && w.siblingIndex(of: entity) == 0)
    try fx.undo.undo()
    #expect(w.entity(for: created) == nil)
}

@MainActor @Test func spawnSubtreeAndDuplicateGetFreshIDs() throws {
    let fx = makeFixture()
    let w = fx.world
    let originals = Set(w.entities.compactMap { w.id(of: $0) })
    try expectRoundTrip(fx) {
        let command = try SpawnCommand(duplicating: [fx.a], in: w)
        #expect(command.rootIDs.count == 1 && !originals.contains(command.rootIDs[0]))
        try fx.undo.perform(command)
    }
    try fx.undo.redo()
    #expect(w.entityCount == 10)
    // The copy's internal references point into the copy, not the original.
    let copy = try #require(w.roots.last)
    let copyC = w.children(of: copy)[1]
    let copyD = w.children(of: copyC)[0]
    #expect(w.get(Gadget.self, for: copyC)?.partner == copyD && w.get(Gadget.self, for: copyD)?.partner == copyC)
    #expect(w.get(Gadget.self, for: fx.c)?.partner == fx.d)
    #expect(Set(w.entities.compactMap { w.id(of: $0) }).count == 10)
    // Pasting a saved subtree at an index works for several roots.
    try fx.undo.perform(SpawnCommand(subtree: w.save([fx.e, fx.f]), parent: fx.b, index: 0, regenerateIDs: true, in: w))
    #expect(w.children(of: fx.b).count == 2 && w.get(Name.self, for: w.children(of: fx.b)[1]) == "F")
}

@MainActor @Test func despawnRestoresAWholeSubtreeWithCrossReferencesAndIDs() throws {
    let fx = makeFixture()
    let w = fx.world
    // a's subtree has references among its entities (c and d); a is the first root.
    try expectRoundTrip(fx) { try fx.undo.perform(DespawnCommand(fx.a, in: w)) }
    try fx.undo.perform(DespawnCommand(fx.a, in: w))
    #expect(w.entityCount == 2 && w.entity(for: fx.ids[3]) == nil)
    try fx.undo.undo()
    #expect(w.entityCount == 6)
    for (i, id) in fx.ids.enumerated() { #expect(w.entity(for: id) != nil, "entity \(i) lost its id") }
    // The restored entities are new handles with working internal references.
    let b = w.entity(for: fx.ids[1])!, c = w.entity(for: fx.ids[2])!, d = w.entity(for: fx.ids[3])!
    #expect(w.get(Gadget.self, for: c)?.partner == d && w.get(Gadget.self, for: d)?.partner == c)
    #expect(w.roots.first == w.entity(for: fx.ids[0]))  // same place among the roots
    #expect(w.children(of: w.entity(for: fx.ids[0])!) == [b, c])
}

@MainActor @Test func despawnOfAMiddleChildRestoresSiblingOrderAndParent() throws {
    let fx = makeFixture()
    let w = fx.world
    let g = w.spawn(Name("G"))
    w.setParent(g, to: fx.a)  // children of a: b, c, g
    try expectRoundTrip(fx) { try fx.undo.perform(DespawnCommand(fx.c, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(DespawnCommand(fx.b, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(DespawnCommand(fx.f, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(DespawnCommand(fx.e, in: w)) }
}

@MainActor @Test func despawnWorksForEntitiesWithoutIDsAndKeepsUnresolvedComponents() throws {
    let world = World()  // ids not enabled
    let root = world.spawn(Name("r"))
    let child = world.spawn(Tagged(value: 3))
    world.setParent(child, to: root)
    let json = String(decoding: try world.save(), as: UTF8.self)
        .replacingOccurrences(of: "\"Test.UndoTagged\"", with: "\"Test.NotRegisteredAnywhere\"")
    let loaded = World()
    try loaded.load(Data(json.utf8))
    let undo = UndoStack(world: loaded)
    let before = try loaded.save()
    try undo.perform(DespawnCommand(loaded.roots[0], in: loaded))
    #expect(loaded.entityCount == 0)
    try undo.undo()
    // (Despawning gave the entities ids, so the bytes differ by those.)
    let after = String(decoding: try loaded.save(), as: UTF8.self)
    #expect(after.contains("Test.NotRegisteredAnywhere") && after.contains("uid") && !String(decoding: before, as: UTF8.self).contains("uid"))
    #expect(loaded.roots.count == 1 && loaded.children(of: loaded.roots[0]).count == 1)
}

@MainActor @Test func reparentRestoresParentIndexAndTransform() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.b, to: fx.e, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.b, to: fx.f, keepWorldTransform: true, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.d, to: nil, index: 0, keepWorldTransform: true, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.f, to: fx.a, index: 0, in: w)) }
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.c, to: fx.a, index: 0, in: w, label: "Reorder")) }  // within the parent
    try expectRoundTrip(fx) { try fx.undo.perform(ReparentCommand(fx.f, to: nil, index: 0, in: w)) }  // reorder roots

    // keepWorldTransform: the world position doesn't change, and redo gives back the same transform.
    let worldBefore = w.worldMatrix(of: fx.d)
    try fx.undo.perform(ReparentCommand(fx.d, to: fx.e, keepWorldTransform: true, in: w))
    let local = w.get(Transform.self, for: fx.d)
    #expect(length(Transform(matrix: w.worldMatrix(of: fx.d)).position - Transform(matrix: worldBefore).position) < 1e-4)
    try fx.undo.undo()
    try fx.undo.redo()
    #expect(w.get(Transform.self, for: fx.d) == local)

    // A cycle is refused and records nothing.
    let depth = fx.undo.undoDepth
    #expect(throws: UndoError.invalidReparent) { try fx.undo.perform(ReparentCommand(fx.a, to: fx.b, in: w)) }
    #expect(fx.undo.undoDepth == depth)
}

@MainActor @Test func closureCommandRunsBothWays() throws {
    let fx = makeFixture()
    let id = fx.ids[5]
    try expectRoundTrip(fx) {
        try fx.undo.perform(ClosureCommand("Tag F", perform: { w in w.add(Tagged(value: 1), to: try w.resolve(id)) },
                                           revert: { w in w.remove(Tagged.self, from: try w.resolve(id)) }))
    }
    #expect(fx.undo.undoTitle == "Undo")  // nothing left to undo after the round trip
}


// MARK: Grouping and coalescing

@MainActor @Test func aGroupIsOneStepAndUndoesInReverse() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) {
        try fx.undo.group("Tidy") {
            try fx.undo.perform(RenameCommand(fx.a, to: "A1", in: w))
            try fx.undo.perform(RenameCommand(fx.b, to: "B1", in: w))
            try fx.undo.perform(DespawnCommand(fx.c, in: w))
            try fx.undo.perform(SetFieldCommand(fx.e, "Transform", "position", to: .vec3(.zero), in: w))
        }
    }
    #expect(fx.undo.undoDepth == 0)
    try fx.undo.group("Tidy") { try fx.undo.perform(RenameCommand(fx.a, to: "A1", in: w)) }
    #expect(fx.undo.undoDepth == 1 && fx.undo.undoLabel == "Tidy")
}

@MainActor @Test func nestedGroupsMakeOneStepAndEmptyGroupsNothing() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) {
        fx.undo.beginGroup("Outer")
        try fx.undo.perform(RenameCommand(fx.a, to: "A1", in: w))
        fx.undo.beginGroup("Inner")
        try fx.undo.perform(RenameCommand(fx.b, to: "B1", in: w))
        try fx.undo.perform(DespawnCommand(fx.f, in: w))
        fx.undo.endGroup()
        try fx.undo.perform(RenameCommand(fx.c, to: "C1", in: w))
        #expect(fx.undo.isGrouping && fx.undo.undoDepth == 0)  // nothing recorded until the outer group ends
        fx.undo.endGroup()
        #expect(!fx.undo.isGrouping)
    }
    // An empty group records nothing and keeps the redo history.
    try fx.undo.perform(RenameCommand(fx.a, to: "x", in: w))
    try fx.undo.undo()
    fx.undo.group("Nothing") {}
    #expect(fx.undo.undoDepth == 0 && fx.undo.canRedo)
    fx.undo.endGroup()  // unmatched: ignored
}

@MainActor @Test func undoAndRedoAreRefusedWhileAGroupIsOpen() throws {
    let fx = makeFixture()
    try fx.undo.perform(RenameCommand(fx.a, to: "x", in: fx.world))
    fx.undo.beginGroup("Drag")
    #expect(!fx.undo.canUndo)
    #expect(try !fx.undo.undo())
    fx.undo.endGroup()
    #expect(try fx.undo.undo())
}

@MainActor @Test func aThrowingBodyStillEndsTheGroupAndKeepsWhatRan() throws {
    struct Boom: Error {}
    let fx = makeFixture()
    let w = fx.world
    #expect(throws: Boom.self) {
        try fx.undo.group("Partial") {
            try fx.undo.perform(RenameCommand(fx.a, to: "partial", in: w))
            throw Boom()
        }
    }
    #expect(!fx.undo.isGrouping && fx.undo.undoDepth == 1)
    try fx.undo.undo()
    #expect(w.get(Name.self, for: fx.a) == "A")
}

@MainActor @Test func consecutiveEditsToOneFieldCoalesceInsideAGroup() throws {
    let fx = makeFixture()
    let w = fx.world
    try expectRoundTrip(fx) {
        try fx.undo.group("Move") {
            for i in 1...50 {
                try fx.undo.perform(SetFieldCommand(fx.a, "Transform", "position", to: .vec3(Vec3(Float(i), 0, 0)), in: w))
            }
        }
    }
    // One step, and one command inside it.
    try fx.undo.group("Move") {
        for i in 1...5 { try fx.undo.perform(SetFieldCommand(fx.a, "Transform", "position", to: .vec3(Vec3(Float(i), 0, 0)), in: w)) }
    }
    #expect(fx.undo.undoDepth == 1)
    #expect(w.get(Transform.self, for: fx.a)?.position.x == 5)
    try fx.undo.undo()
    #expect(w.get(Transform.self, for: fx.a)?.position == Vec3(1, 2, 3))  // the value before the whole drag
    try fx.undo.redo()
    #expect(w.get(Transform.self, for: fx.a)?.position.x == 5)
}

@MainActor @Test func onlyConsecutiveEditsOfTheSameFieldCoalesce() throws {
    let fx = makeFixture()
    let w = fx.world
    func set(_ entity: Entity, _ path: String, _ x: Float) throws {
        try fx.undo.perform(SetFieldCommand(entity, "Transform", path, to: .vec3(Vec3(x, 0, 0)), in: w))
    }
    try expectRoundTrip(fx) {
        fx.undo.beginGroup("Mixed")
        try set(fx.a, "position", 1)
        try set(fx.a, "scale", 2)  // another field
        try set(fx.a, "position", 3)  // not consecutive with the first
        try set(fx.b, "position", 4)  // another entity
        try set(fx.b, "position", 5)
        fx.undo.endGroup()
    }
    // Outside a group nothing merges.
    for i in 1...3 { try set(fx.a, "position", Float(i)) }
    #expect(fx.undo.undoDepth == 3)
    // Renames and whole components coalesce too.
    fx.undo.clear()
    try expectRoundTrip(fx) {
        try fx.undo.group("Typing") {
            for name in ["N", "Ne", "New"] { try fx.undo.perform(RenameCommand(fx.a, to: name, in: w)) }
            for x in [Float(1), 2, 3] { try fx.undo.perform(SetComponentCommand(fx.b, to: Transform(position: Vec3(x, x, x)), in: w)) }
        }
    }
}

// MARK: Depth, dirty state, redo, notifications

@MainActor @Test func maxDepthDropsTheOldestSteps() throws {
    let fx = makeFixture()
    let w = fx.world
    fx.undo.maxDepth = 3
    for i in 1...5 { try fx.undo.perform(RenameCommand(fx.a, to: "n\(i)", in: w)) }
    #expect(fx.undo.undoDepth == 3)
    while try fx.undo.undo() {}
    #expect(w.get(Name.self, for: fx.a) == "n2")  // steps 1 and 2 are gone, so n2 is the oldest state reachable
    fx.undo.maxDepth = 1  // shrinking trims immediately
    #expect(fx.undo.undoDepth == 0 && fx.undo.redoDepth == 3)  // redo steps are not part of the depth
    for i in 1...4 { try fx.undo.perform(RenameCommand(fx.b, to: "m\(i)", in: w)) }
    #expect(fx.undo.undoDepth == 1 && fx.undo.redoDepth == 0)
}

@MainActor @Test func dirtyStateTracksTheSavePoint() throws {
    let fx = makeFixture()
    let w = fx.world
    let u = fx.undo
    #expect(!u.isDirty)
    try u.perform(RenameCommand(fx.a, to: "1", in: w))
    #expect(u.isDirty)
    try u.undo()
    #expect(!u.isDirty)  // back at the save point
    try u.redo()
    u.markSaved()
    #expect(!u.isDirty)
    try u.perform(RenameCommand(fx.a, to: "2", in: w))
    try u.perform(RenameCommand(fx.a, to: "3", in: w))
    #expect(u.isDirty)
    try u.undo()
    try u.undo()
    #expect(!u.isDirty)
    try u.undo()  // past the save point
    #expect(u.isDirty)
    try u.redo()
    #expect(!u.isDirty)

    // A new command after undoing past the save point makes it unreachable.
    try u.undo()
    try u.perform(RenameCommand(fx.a, to: "other", in: w))
    #expect(u.isDirty)
    try u.undo()
    #expect(u.isDirty)  // not the saved state any more
    u.markSaved()
    #expect(!u.isDirty)

    // A group is dirty once it ends.
    u.beginGroup("g")
    try u.perform(RenameCommand(fx.a, to: "g", in: w))
    #expect(!u.isDirty)
    u.endGroup()
    #expect(u.isDirty)
    u.markSaved()
    u.markUnsaved()
    #expect(u.isDirty)
    u.clear()
    #expect(!u.isDirty)
}

@MainActor @Test func savePointFallingOffTheBottomMakesItDirtyForGood() throws {
    let fx = makeFixture()
    let u = fx.undo
    u.maxDepth = 2
    for i in 1...3 { try u.perform(RenameCommand(fx.a, to: "\(i)", in: fx.world)) }  // drops step 1
    try u.undo()
    try u.undo()
    #expect(u.isDirty)  // the saved (initial) state is out of reach
    // A save point that is still within reach stays clean.
    u.markSaved()
    try u.perform(RenameCommand(fx.a, to: "4", in: fx.world))
    try u.perform(RenameCommand(fx.a, to: "5", in: fx.world))
    try u.undo()
    try u.undo()
    #expect(!u.isDirty)
}

@MainActor @Test func aNewCommandInvalidatesRedo() throws {
    let fx = makeFixture()
    let w = fx.world
    try fx.undo.perform(RenameCommand(fx.a, to: "1", in: w))
    try fx.undo.perform(RenameCommand(fx.a, to: "2", in: w))
    try fx.undo.undo()
    #expect(fx.undo.canRedo && fx.undo.redoLabel == "Rename" && fx.undo.redoTitle == "Redo Rename")
    try fx.undo.perform(RenameCommand(fx.b, to: "x", in: w))
    #expect(!fx.undo.canRedo && fx.undo.redoDepth == 0)
    #expect(try !fx.undo.redo())
    #expect(w.get(Name.self, for: fx.a) == "1")
    // The same inside a group.
    try fx.undo.undo()
    fx.undo.group("g") { try? fx.undo.perform(RenameCommand(fx.a, to: "z", in: w)) }
    #expect(!fx.undo.canRedo)
    #expect(fx.undo.undoHistory == ["g", "Rename"] && fx.undo.redoHistory == [])
}

@MainActor @Test func notificationsAndChangeCounter() throws {
    let fx = makeFixture()
    let w = fx.world
    var calls = 0
    fx.undo.onChange = { calls += 1 }
    let start = fx.undo.changeCount
    try fx.undo.perform(RenameCommand(fx.a, to: "1", in: w))
    #expect(calls == 1)
    try fx.undo.undo()
    try fx.undo.redo()
    fx.undo.markSaved()
    #expect(calls == 4 && fx.undo.changeCount == start + 4)
    fx.undo.group("g") {
        for i in 0..<10 { try? fx.undo.perform(RenameCommand(fx.b, to: "\(i)", in: w)) }
    }
    #expect(calls == 5)  // a group notifies once, when it ends
    fx.undo.clear()
    #expect(calls == 6 && fx.undo.undoDepth == 0)
    // Nothing to undo: no notification.
    #expect(try !fx.undo.undo())
    #expect(calls == 6)
}

@MainActor @Test func notRecordingPerformsWithoutRecording() throws {
    let fx = makeFixture()
    let w = fx.world
    try fx.undo.perform(RenameCommand(fx.a, to: "1", in: w))
    fx.undo.isRecording = false
    #expect(!fx.undo.canUndo)
    try fx.undo.perform(RenameCommand(fx.a, to: "play", in: w))
    #expect(w.get(Name.self, for: fx.a) == "play" && fx.undo.undoDepth == 1)
    #expect(try !fx.undo.undo())
    fx.undo.isRecording = true
    #expect(fx.undo.canUndo)
}

// MARK: Resolution across snapshot/restore and despawn cycles

@MainActor @Test func commandsKeepWorkingAfterPlayModeRestore() throws {
    let fx = makeFixture()
    let w = fx.world
    try fx.undo.perform(RenameCommand(fx.a, to: "edited", in: w))
    try fx.undo.perform(SetFieldCommand(fx.d, "Transform", "position", to: .vec3(Vec3(1, 1, 1)), in: w))
    try fx.undo.perform(DespawnCommand(fx.f, in: w))
    let edited = bytes(w)

    // Play mode, as the editor does it.
    let snapshot = w.snapshot()
    fx.undo.isRecording = false
    w.despawn(fx.a)
    for _ in 0..<20 { _ = w.spawn(Name("bullet")) }
    w.assignsEntityIDs = true
    w.restore(snapshot)
    fx.undo.isRecording = true
    #expect(bytes(w) == edited)

    try fx.undo.undo()  // despawn of f
    #expect(w.entity(for: fx.ids[5]) != nil)
    try fx.undo.undo()  // the deep field edit, found by id
    try fx.undo.undo()  // rename
    #expect(w.get(Name.self, for: fx.a) == "A")
    for _ in 0..<3 { try fx.undo.redo() }
    #expect(bytes(w) == edited)
}

@MainActor @Test func commandsDeeperInTheStackResolveAfterDespawnAndUndoCycles() throws {
    let fx = makeFixture()
    let w = fx.world
    // d moves out of a's subtree below, so drop the references that would then cross it.
    w.modify(Gadget.self, for: fx.d) { $0.partner = nil }
    w.modify(Gadget.self, for: fx.c) { $0.partner = nil }
    let original = bytes(w)
    try fx.undo.perform(SetFieldCommand(fx.d, "Test.UndoGadget", "power", to: .float(42), in: w))
    try fx.undo.perform(RenameCommand(fx.b, to: "renamed", in: w))
    try fx.undo.perform(ReparentCommand(fx.d, to: fx.e, in: w))
    let afterEdits = bytes(w)
    // Delete the whole subtree that those commands touched, then bring it back and forth.
    try fx.undo.perform(DespawnCommand(fx.a, in: w))
    try fx.undo.perform(DespawnCommand(fx.e, in: w))  // e now owns d
    for _ in 0..<3 {
        try fx.undo.undo()
        try fx.undo.undo()
        #expect(bytes(w) == afterEdits)
        try fx.undo.redo()
        try fx.undo.redo()
    }
    try fx.undo.undo()
    try fx.undo.undo()
    for _ in 0..<3 { try fx.undo.undo() }
    #expect(bytes(w) == original)
    for _ in 0..<5 { try fx.undo.redo() }
    #expect(w.entityCount == 1)
}

@MainActor @Test func aStepThatCantResolveIsDroppedAndTheStackStaysUsable() throws {
    let fx = makeFixture()
    let w = fx.world
    try fx.undo.perform(RenameCommand(fx.a, to: "x", in: w))
    try fx.undo.perform(RenameCommand(fx.b, to: "y", in: w))
    w.despawn(fx.b)  // an edit made behind the stack's back
    #expect(throws: UndoError.entityNotFound(fx.ids[1])) { try fx.undo.undo() }
    #expect(fx.undo.undoDepth == 1 && fx.undo.isDirty)
    #expect(try fx.undo.undo())
    #expect(w.get(Name.self, for: fx.a) == "A")
}

@MainActor @Test func clearForgetsEverythingAndInitialStateIsClean() throws {
    let fx = makeFixture()
    try fx.undo.perform(RenameCommand(fx.a, to: "x", in: fx.world))
    try fx.undo.undo()
    fx.undo.clear()
    #expect(!fx.undo.canUndo && !fx.undo.canRedo && fx.undo.undoLabel == nil && fx.undo.undoTitle == "Undo")
    #expect(!fx.undo.isDirty && fx.undo.undoHistory.isEmpty)
}

@MainActor @Test func referencesAcrossASubtreeBoundaryDontSurviveDespawn() throws {
    // Documented limit: components hold Entity handles, which die with the entity.
    let fx = makeFixture()
    let w = fx.world
    w.add(Gadget(partner: fx.c), to: fx.f)  // outside -> inside
    w.add(Gadget(partner: fx.f), to: fx.d)  // inside -> outside
    try fx.undo.perform(DespawnCommand(fx.c, in: w))
    try fx.undo.undo()
    #expect(w.get(Gadget.self, for: fx.f)?.partner.map { w.isAlive($0) } != true)
    #expect(w.get(Gadget.self, for: fx.d)?.partner == .invalid || w.get(Gadget.self, for: fx.d)?.partner == nil)
    #expect(w.entity(for: fx.ids[2]) != nil)  // the entities themselves are back, with their ids
}

@MainActor @Test func despawnUndoOfALargeSubtreeIsPractical() throws {
    let world = World()
    world.assignsEntityIDs = true
    let root = world.spawn(Transform(), Name("root"))
    var nodes = [root]
    for i in 1..<1000 {
        let e = world.spawn(Transform(position: Vec3(Float(i), 0, 0)), Name("n\(i)"), Gadget(power: Float(i)))
        world.setParent(e, to: nodes[(i - 1) / 3])
        nodes.append(e)
    }
    let undo = UndoStack(world: world)
    let before = try world.save()
    let clock = ContinuousClock()
    let command = try DespawnCommand(root, in: world)
    let despawn = try clock.measure { try undo.perform(command) }
    let restore = try clock.measure { try undo.undo() }
    let redo = try clock.measure { try undo.redo() }
    let restoreAgain = try clock.measure { try undo.undo() }
    #expect(try world.save() == before)
    print("1000-entity subtree: despawn (capture) \(despawn), undo \(restore), redo \(redo), undo again \(restoreAgain)")
    #expect(restore < .seconds(2))  // generous: debug builds are slow
}
