import Foundation
import Testing
@testable import Engine

private struct Link: Component, Equatable {
    static let componentName = "Test.IDLink"
    var target: Entity?
}

private func text(_ data: Data) -> String { String(decoding: data, as: UTF8.self) }

/// Three roots; the first has two children, the second of which has a child.
@MainActor private func makeWorld(ids: Bool = true) -> (world: World, e: [Entity]) {
    let world = World()
    world.assignsEntityIDs = ids
    let a = world.spawn(Transform(position: Vec3(1, 2, 3)), Name("A"))
    let b = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("B"))
    let c = world.spawn(Transform(position: Vec3(0, 0, 1)), Name("C"))
    let d = world.spawn(Transform(), Name("D"))
    let e = world.spawn(Name("E"))
    let f = world.spawn(Name("F"))
    world.setParent(b, to: a)
    world.setParent(c, to: a)
    world.setParent(d, to: c)
    world.add(Link(target: d), to: b)
    return (world, [a, b, c, d, e, f])
}

@MainActor @Test func idsAreAssignedOnSpawnWhenEnabled() {
    let world = World()
    let off = world.spawn()
    #expect(world.id(of: off) == nil)
    world.assignsEntityIDs = true
    #expect(world.id(of: off) != nil)  // existing entities get ids when it is turned on
    let on = world.spawn(Name("x"))
    let id = world.id(of: on)!
    #expect(id != world.id(of: off))
    #expect(world.entity(for: id) == on)
    world.despawn(on)
    #expect(world.id(of: on) == nil && world.entity(for: id) == nil)
    // A reused slot gets a new id.
    let reused = world.spawn()
    #expect(reused.index == on.index && world.id(of: reused) != id)
}

@MainActor @Test func ensureIDWorksWithTheFlagOffAndSetIDRefusesDuplicates() {
    let world = World()
    let a = world.spawn(), b = world.spawn()
    let id = world.ensureID(of: a)!
    #expect(world.ensureID(of: a) == id)
    #expect(!world.setEntityID(id, for: b))
    #expect(world.id(of: b) == nil)
    let other = EntityID(high: 1, low: 2)
    #expect(world.setEntityID(other, for: b))
    #expect(world.setEntityID(other, for: b))
    #expect(world.entity(for: other) == b)
    #expect(world.setEntityID(EntityID(high: 9, low: 9), for: a))
    #expect(world.entity(for: id) == nil)  // the old id is released
    world.despawn(a)
    #expect(world.ensureID(of: a) == nil)
}

@MainActor @Test func entityIDGeneratorCanBeReplaced() {
    let world = World()
    var next: UInt64 = 0
    world.entityIDGenerator = { next += 1; return EntityID(high: 0, low: next) }
    world.assignsEntityIDs = true
    let a = world.spawn(), b = world.spawn()
    #expect(world.id(of: a) == EntityID(high: 0, low: 1) && world.id(of: b) == EntityID(high: 0, low: 2))
}

@Test func idTextRoundTrips() throws {
    let id = EntityID(high: 0xAB, low: 0xFFFF_FFFF_FFFF_FFFF)
    #expect(id.description == "00000000000000abffffffffffffffff")
    #expect(EntityID(id.description) == id)
    #expect(EntityID("nope") == nil && EntityID(String(repeating: "g", count: 32)) == nil)
    let json = try JSONEncoder().encode([id])
    #expect(try JSONDecoder().decode([EntityID].self, from: json) == [id])
    #expect(EntityID(high: 1, low: 5) < EntityID(high: 2, low: 0))
}

@MainActor @Test func savingKeepsIdsAndLoadingIntoAnEmptyWorldPreservesThem() throws {
    let (world, e) = makeWorld()
    let first = try world.save()
    #expect(try world.save() == first)  // byte-stable
    #expect(text(first).contains("\"uid\" : \"\(world.id(of: e[0])!)\""))

    let loaded = World()
    let roots = try loaded.load(first)
    #expect(roots.count == 3)
    #expect(try loaded.save() == first)  // ids and everything else reproduce
    for entity in e {
        let id = world.id(of: entity)!
        let copy = loaded.entity(for: id)!
        #expect(loaded.get(Name.self, for: copy) == world.get(Name.self, for: entity))
    }
}

@MainActor @Test func loadingTheSameFileTwiceKeepsIdsUnique() throws {
    let (world, e) = makeWorld()
    let data = try world.save()
    let originalIDs = Set(e.compactMap { world.id(of: $0) })

    // Additive load into the world that already has these ids: the copy gets new ones.
    let second = try world.load(data)
    #expect(world.entityCount == 12)
    var all = Set<EntityID>()
    for entity in world.entities { #expect(all.insert(world.id(of: entity)!).inserted) }
    #expect(all.count == 12)
    #expect(originalIDs.allSatisfy { world.entity(for: $0).map { e.contains($0) } ?? false })  // originals untouched
    #expect(second.allSatisfy { !originalIDs.contains(world.id(of: $0)!) })

    // Into a world with ids disabled, an entity whose id was taken still gets one.
    let plain = World()
    try plain.load(data)
    try plain.load(data)
    #expect(Set(plain.entities.compactMap { plain.id(of: $0) }).count == 12)

    // .regenerate gives new ids even into an empty world.
    let fresh = World()
    try fresh.load(data, ids: .regenerate)
    #expect(Set(fresh.entities.compactMap { fresh.id(of: $0) }).isDisjoint(with: originalIDs))
    #expect(fresh.entityCount == 6)
}

@MainActor @Test func duplicateIdsInsideAFileAreRepaired() throws {
    let (world, _) = makeWorld()
    var json = text(try world.save())
    let ids = json.components(separatedBy: "\"uid\" : \"").dropFirst().map { String($0.prefix(32)) }
    json = json.replacingOccurrences(of: ids[1], with: ids[0])
    let target = World()
    try target.load(Data(json.utf8))
    #expect(Set(target.entities.compactMap { target.id(of: $0) }).count == 6)
    #expect(target.entity(for: EntityID(ids[0])!) != nil)
    // A malformed id is a decoding error, and nothing is spawned.
    let bad = Data(json.replacingOccurrences(of: ids[2], with: "xyz").utf8)
    #expect(throws: DecodingError.self) { try target.load(bad) }
    #expect(target.entityCount == 6)
}

@MainActor @Test func version1FilesLoadAndGetIdsWhenWanted() throws {
    let (world, e) = makeWorld()
    var json = text(try world.save()).replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 1")
    json = json.split(separator: "\n").filter { !$0.contains("\"uid\"") }.joined(separator: "\n")
    // Dropping the uid lines leaves the preceding "id" line with a trailing comma, so fix it up.
    json = json.replacingOccurrences(of: "\"id\" : 0,\n", with: "\"id\" : 0\n")
    let v1 = try #require(try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]) // still valid JSON
    #expect(v1["version"] as? Int == 1)

    let plain = World()
    let roots = try plain.load(Data(json.utf8))
    #expect(roots.count == 3 && plain.entityCount == 6)
    #expect(plain.entities.allSatisfy { plain.id(of: $0) == nil })  // not wanted: none assigned

    let editor = World()
    editor.assignsEntityIDs = true
    try editor.load(Data(json.utf8))
    #expect(Set(editor.entities.compactMap { editor.id(of: $0) }).count == 6)
    // Structure is intact.
    let a = editor.roots[0]
    #expect(editor.get(Name.self, for: a) == Name("A") && editor.children(of: a).count == 2)
    // Saving it again writes version 2 with ids.
    #expect(text(try editor.save()).contains("\"version\" : 2"))
}

@MainActor @Test func filesWithoutIdsStaySmallWhenTheFlagIsOff() throws {
    let (world, _) = makeWorld(ids: false)
    #expect(!text(try world.save()).contains("uid"))
}

@MainActor @Test func snapshotRestorePreservesIdsAndRootOrder() throws {
    let (world, e) = makeWorld()
    world.setParent(e[5], to: nil, at: 0)  // F first
    let ids = e.map { world.id(of: $0)! }
    let before = try world.save()
    let snapshot = world.snapshot()

    // Play mode: change everything.
    world.despawn(e[0])
    let extra = world.spawn(Name("play"))
    world.setParent(e[4], to: extra)
    world.assignsEntityIDs = false
    #expect(world.entity(for: ids[0]) == nil)

    world.restore(snapshot)
    #expect(try world.save() == before)
    for (entity, id) in zip(e, ids) {
        #expect(world.id(of: entity) == id && world.entity(for: id) == entity)
    }
    #expect(world.entity(for: world.id(of: extra) ?? EntityID(high: 0, low: 0)) == nil)
    #expect(world.roots == [e[5], e[0], e[4]])
}

@MainActor @Test func lookupIsConstantTime() {
    let world = World()
    world.assignsEntityIDs = true
    let all = (0..<20_000).map { _ in world.spawn() }
    let ids = all.map { world.id(of: $0)! }
    // A linear scan per lookup would be 4e8 steps here, minutes in a debug build.
    var found = 0
    for id in ids where world.entity(for: id) != nil { found += 1 }
    #expect(found == 20_000)
    for e in all.prefix(10_000) { world.despawn(e) }
    #expect(ids.prefix(10_000).allSatisfy { world.entity(for: $0) == nil })
    #expect(ids.suffix(10_000).allSatisfy { world.entity(for: $0) != nil })
}

@MainActor @Test func rootsAndSiblingOrderAreExplicit() throws {
    let (world, e) = makeWorld()
    #expect(world.roots == [e[0], e[4], e[5]])
    #expect(world.siblingIndex(of: e[5]) == 2 && world.siblingIndex(of: e[2]) == 1 && world.siblingIndex(of: e[3]) == 0)
    // Reorder within a parent, and among roots.
    world.setParent(e[2], to: e[0], at: 0)
    #expect(world.children(of: e[0]) == [e[2], e[1]])
    world.setParent(e[5], to: nil, at: 1)
    #expect(world.roots == [e[0], e[5], e[4]])
    // Reparent to a given index; clamped.
    world.setParent(e[4], to: e[0], at: 99)
    #expect(world.children(of: e[0]) == [e[2], e[1], e[4]] && world.roots == [e[0], e[5]])
    // A despawned root's slot reused later doesn't take its old place in the order.
    world.despawn(e[0])
    let fresh = world.spawn()
    #expect(world.roots == [e[5], fresh])
    // Save order follows it.
    let loaded = World()
    try loaded.load(world.save())
    #expect(loaded.roots.count == 2)
}

@MainActor @Test func manyRootsCanBeDespawnedQuickly() {
    let world = World()
    let all = (0..<5_000).map { _ in world.spawn() }
    for e in all where e.index % 3 != 0 { world.despawn(e) }
    let kept = all.filter { $0.index % 3 == 0 }
    #expect(world.roots == kept)
    #expect(kept.indices.allSatisfy { world.siblingIndex(of: kept[$0]) == $0 })
}

@MainActor @Test func nameComponentIsRegisteredAndRoundTrips() throws {
    #expect(ComponentRegistry.type(named: "Name") == Name.self)
    let (world, e) = makeWorld()
    let json = text(try world.save())
    #expect(json.contains("\"Name\" : {"))
    let loaded = World()
    try loaded.load(Data(json.utf8))
    #expect(loaded.get(Name.self, for: loaded.roots[0]) == "A")
    try world.setField("value", of: "Name", for: e[0], to: .string("Renamed"))
    #expect(world.get(Name.self, for: e[0])?.value == "Renamed")
}
