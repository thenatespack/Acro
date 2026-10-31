import Foundation
import Testing
@testable import Engine

// `EntityRef`: persistent entity references through save/load, undo, duplication, loading a
// file twice, snapshots and reflection.

private struct Follow: Component, Equatable {
    static let componentName = "Test.Follow"
    var target = EntityRef()
    var others: [EntityRef] = []
    var optional: EntityRef?
}

@MainActor
@Suite struct EntityRefTests {
    init() { ComponentRegistry.register(Follow.self) }

    /// A root "A" with a child "B" that follows "A"'s sibling-to-be "C" (outside) and "A" (inside).
    private func makeWorld() -> (World, a: Entity, b: Entity, c: Entity) {
        let world = World()
        world.assignsEntityIDs = true
        let a = world.spawn(Transform(), Name("A"))
        let b = world.spawn(Transform(), Name("B"))
        let c = world.spawn(Transform(), Name("C"))
        world.setParent(b, to: a)
        world.add(Follow(target: world.ref(to: c), others: [world.ref(to: a)]), to: b)
        return (world, a, b, c)
    }

    @Test func resolvesAndGoesNilWhenTheTargetIsGone() {
        let (world, _, b, c) = makeWorld()
        let follow = world.get(Follow.self, for: b)!
        #expect(world.resolve(follow.target) == c)
        #expect(world.resolve(EntityRef.none) == nil)
        world.despawn(c)
        #expect(world.resolve(follow.target) == nil)
        #expect(!follow.target.isNone)
    }

    @Test func survivesSaveAndLoad() throws {
        let (world, a, _, c) = makeWorld()
        let data = try world.save()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains(#""$ref" : "\#(world.id(of: c)!)""#))

        let loaded = World()
        try loaded.load(data)
        let b2 = loaded.entity(for: world.id(of: world.children(of: a)[0])!)!
        let follow = try #require(loaded.get(Follow.self, for: b2))
        #expect(loaded.resolve(follow.target).flatMap { loaded.get(Name.self, for: $0) } == Name("C"))
        #expect(loaded.resolve(follow.others[0]).flatMap { loaded.get(Name.self, for: $0) } == Name("A"))
        #expect(try loaded.save() == data)
    }

    @Test func subtreeSavesKeepReferencesToOutside() throws {
        // `Entity` handles to entities outside a saved subtree load as nil; refs don't.
        let (world, a, b, c) = makeWorld()
        let data = try world.save([a])
        world.despawn(a)
        let roots = try world.load(data)
        let copy = world.children(of: roots[0])[0]
        #expect(world.id(of: copy) != nil)
        #expect(world.resolve(world.get(Follow.self, for: copy)!.target) == c)
        _ = b
    }

    @Test func undoOfDeleteBringsTheTargetBack() throws {
        let (world, _, b, c) = makeWorld()
        let undo = UndoStack(world: world)
        let bID = world.id(of: b)!
        let cID = world.id(of: c)!
        try undo.perform(DespawnCommand(c, in: world))
        #expect(world.resolve(world.get(Follow.self, for: b)!.target) == nil)
        try undo.undo()
        let target = world.resolve(world.get(Follow.self, for: world.entity(for: bID)!)!.target)
        #expect(target != nil && world.id(of: target!) == cID)
        // And the other way round: delete the follower's subtree and bring it back.
        let a = world.parent(of: world.entity(for: bID)!)!
        try undo.perform(DespawnCommand(a, in: world))
        try undo.undo()
        let follow = try #require(world.get(Follow.self, for: world.entity(for: bID)!))
        #expect(world.resolve(follow.target) == world.entity(for: cID))
        #expect(world.resolve(follow.others[0]) == world.parent(of: world.entity(for: bID)!))
    }

    @Test func duplicatesPointAtTheCopies() throws {
        let (world, a, b, c) = makeWorld()
        let undo = UndoStack(world: world)
        let command = try SpawnCommand(duplicating: [a], in: world)
        try undo.perform(command)
        let copy = try #require(world.entity(for: command.rootIDs[0]))
        #expect(copy != a)
        let copyB = world.children(of: copy)[0]
        let follow = try #require(world.get(Follow.self, for: copyB))
        #expect(world.resolve(follow.others[0]) == copy)          // inside: the copy
        #expect(world.resolve(follow.target) == c)                // outside: unchanged
        #expect(world.resolve(world.get(Follow.self, for: b)!.others[0]) == a)  // the original is untouched
        try undo.undo()
        #expect(world.entity(for: command.rootIDs[0]) == nil)
    }

    @Test func loadingAFileTwiceRemapsTheSecondCopy() throws {
        let (world, a, _, _) = makeWorld()
        let data = try world.save([a])
        let first = try world.load(data, ids: .regenerate)[0]
        let second = try world.load(data, ids: .keepUnique)[0]  // its ids are taken: new ones
        for root in [first, second] {
            let follow = world.get(Follow.self, for: world.children(of: root)[0])!
            #expect(world.resolve(follow.others[0]) == root)
        }
    }

    @Test func snapshotAndRestore() {
        let (world, a, b, c) = makeWorld()
        let snapshot = world.snapshot()
        world.despawn(c)
        world.modify(Follow.self, for: b) { $0.target = world.ref(to: a) }
        world.restore(snapshot)
        #expect(world.resolve(world.get(Follow.self, for: b)!.target) == c)
    }

    @Test func reflectionShowsAnOptionalIDString() throws {
        let (world, a, b, c) = makeWorld()
        let fields = try #require(world.fields(of: Follow.componentName, for: b))
        let target = try #require(fields.first { $0.name == "target" })
        #expect(target.kind == .string && target.isOptional && target.isEntityReference)
        #expect(target.value == .string(world.id(of: c)!.description))
        let optional = try #require(fields.first { $0.name == "optional" })
        #expect(optional.kind == .string && optional.value == .null && optional.isEntityReference)
        #expect(fields.first { $0.name == "others" }?.children.first?.isEntityReference == true)

        try world.setField("target", of: Follow.componentName, for: b, to: .string(world.id(of: a)!.description))
        #expect(world.resolve(world.get(Follow.self, for: b)!.target) == a)
        try world.setField("optional", of: Follow.componentName, for: b, to: .string(world.id(of: c)!.description))
        #expect(world.get(Follow.self, for: b)!.optional.flatMap(world.resolve) == c)
        try world.setField("target", of: Follow.componentName, for: b, to: .null)
        #expect(world.get(Follow.self, for: b)!.target.isNone)
        try world.setField("target", of: Follow.componentName, for: b, to: .string(""))
        #expect(world.get(Follow.self, for: b)!.target.isNone)
        #expect(throws: (any Error).self) { try world.setField("target", of: Follow.componentName, for: b, to: .string("nope")) }
    }

    @Test func codable() throws {
        let id = EntityID(high: 1, low: 2)
        let json = String(decoding: try JSONEncoder().encode([EntityRef(id), .none]), as: UTF8.self)
        #expect(json == #"[{"$ref":"00000000000000010000000000000002"},null]"#)
        #expect(try JSONDecoder().decode([EntityRef].self, from: Data(json.utf8)) == [EntityRef(id), .none])
        #expect(try JSONDecoder().decode(EntityRef.self, from: Data(#""00000000000000010000000000000002""#.utf8)) == EntityRef(id))
    }
}
