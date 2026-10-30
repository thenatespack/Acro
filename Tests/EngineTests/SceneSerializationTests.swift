import Foundation
import Testing
@testable import Engine

// Component names here are prefixed with "Test." so they can't clash in the global
// ComponentRegistry with the components of other test files.

private enum Team: String, Codable, CaseIterable { case red, blue, green }
private enum Shape: Codable, Equatable { case sphere(radius: Float), box(size: Vec3) }
private struct Stats: Codable, Equatable {
    var level = 1
    var tags: [String] = ["a", "b"]
}

/// One field of every kind the scene format and reflection handle.
private struct Kitchen: Component, Equatable {
    static let componentName = "Test.Kitchen"
    static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(range: 0...10), "tint": FieldHints(color: true), "points.*": FieldHints(step: 0.1)]
    }

    var flag = true
    var count = -3
    var small: UInt8 = 200
    var speed: Float = 1.5
    var precise = 0.1
    var name = "hello \"world\" [1, 2] / ünïcode"
    var uv = Vec2(0.25, 0.75)
    var offset = Vec3(1, -2, 3.5)
    var tint = Vec4(1, 0.5, 0.25, 1)
    var spin = Quat(angle: 0.7, axis: Vec3(0, 1, 0))
    var team = Team.blue
    var shape = Shape.box(size: Vec3(1, 2, 3))
    var stats = Stats()
    var points = [Vec3(0, 0, 0), Vec3(1, 1, 1)]
    var maybe: Float?
    var maybeTeam: Team? = .green
    var maybeStats: Stats?
    var lookup = ["x": 1, "y": 2]
    var far = Float.infinity
}

private struct Follow: Component, Equatable {
    static let componentName = "Test.Follow"
    var target: Entity
    var backup: Entity?
    var chain: [Entity] = []
}

private struct Marker: Component, Equatable {
    static let componentName = "Test.Marker"
    var label = ""
}

@MainActor private func roundTrip(_ world: World) throws -> (World, [Entity]) {
    let loaded = World()
    let roots = try loaded.load(world.save())
    return (loaded, roots)
}

private func text(_ data: Data) -> String { String(decoding: data, as: UTF8.self) }

// MARK: Round trips

@MainActor @Test func componentsOfEveryKindRoundTrip() throws {
    let world = World()
    var custom = Kitchen()
    custom.maybe = 2
    custom.maybeStats = Stats(level: 7, tags: [])
    custom.shape = .sphere(radius: 0.5)
    let a = world.spawn(Kitchen(), Transform(position: Vec3(1, 2, 3), rotation: Quat(angle: 1, axis: Vec3(1, 0, 0)), scale: Vec3(2, 2, 2)))
    _ = world.spawn(custom, Marker(label: "b"))
    let (loaded, roots) = try roundTrip(world)
    #expect(roots.count == 2)
    #expect(loaded.get(Kitchen.self, for: roots[0]) == world.get(Kitchen.self, for: a))
    #expect(loaded.get(Transform.self, for: roots[0]) == world.get(Transform.self, for: a))
    #expect(loaded.get(Kitchen.self, for: roots[1]) == custom)
    #expect(loaded.get(Marker.self, for: roots[1]) == Marker(label: "b"))
    #expect(loaded.get(Kitchen.self, for: roots[1]) != world.get(Kitchen.self, for: a))
}

@MainActor @Test func hierarchyRoundTripsInOrderAndGlobalTransformIsRecomputed() throws {
    let world = World()
    let root = world.spawn(Transform(position: Vec3(10, 0, 0)), Marker(label: "root"))
    let children = (0..<4).map { world.spawn(Transform(position: Vec3(Float($0), 0, 0)), Marker(label: "c\($0)")) }
    for c in children { world.setParent(c, to: root) }
    let grandchild = world.spawn(Transform(position: Vec3(0, 1, 0)), Marker(label: "g"))
    world.setParent(grandchild, to: children[2])
    world.setParent(children[0], to: nil)  // a second root, saved after the first
    world.setParent(children[0], to: root)  // ...and back, now the last child
    _ = world.spawn(Marker(label: "other"))
    world.propagateTransforms()
    #expect(!text(try world.save()).contains("GlobalTransform"))

    let (loaded, roots) = try roundTrip(world)
    let label = { (e: Entity) in loaded.get(Marker.self, for: e)?.label ?? "?" }
    #expect(roots.map(label) == ["root", "other"])
    #expect(loaded.children(of: roots[0]).map(label) == ["c1", "c2", "c3", "c0"])
    let loadedGrandchild = loaded.children(of: loaded.children(of: roots[0])[1])
    #expect(loadedGrandchild.map(label) == ["g"])
    #expect(loaded.get(GlobalTransform.self, for: loadedGrandchild[0])?.position == Vec3(12, 1, 0))
    #expect(loaded.entityCount == world.entityCount)
}

@MainActor @Test func entityReferencesAreRemappedToTheNewEntities() throws {
    let world = World()
    let outsider = world.spawn(Marker(label: "outsider"))
    let leader = world.spawn(Marker(label: "leader"))
    let follower = world.spawn(Marker(label: "follower"))
    world.setParent(follower, to: leader)
    world.add(Follow(target: leader, backup: follower, chain: [follower, leader]), to: follower)
    world.add(Follow(target: outsider, backup: outsider, chain: [outsider]), to: leader)

    // Save only the leader's subtree into a world that already has entities, so every
    // handle differs from the original.
    let file = try world.save([leader])
    #expect(text(file).contains("\"$entity\" : 1"))
    let target = World()
    for _ in 0..<5 { _ = target.spawn(Marker(label: "existing")) }
    target.despawn(target.entities[1])  // a free slot to reuse
    let roots = try target.load(file)
    #expect(roots.count == 1)
    let newLeader = roots[0]
    let newFollower = target.children(of: newLeader)[0]
    #expect(newLeader != leader || newFollower != follower)
    #expect(target.get(Follow.self, for: newFollower) == Follow(target: newLeader, backup: newFollower, chain: [newFollower, newLeader]))
    // The outsider wasn't saved: an optional reference loads as nil, a plain one as invalid.
    let dangling = try #require(target.get(Follow.self, for: newLeader))
    #expect(dangling.target == .invalid && dangling.backup == nil && dangling.chain == [.invalid])
    #expect(!target.isAlive(dangling.target))
}

@MainActor @Test func loadingIsAdditiveAndCanInstanceUnderAParent() throws {
    let prefab = World()
    let body = prefab.spawn(Transform(), Marker(label: "body"))
    let arm = prefab.spawn(Transform(position: Vec3(1, 0, 0)), Marker(label: "arm"))
    prefab.setParent(arm, to: body)
    prefab.add(Follow(target: body), to: arm)
    let file = try prefab.save()

    let world = World()
    let holder = world.spawn(Transform(position: Vec3(0, 5, 0)))
    let first = try world.load(file, under: holder)
    let second = try world.load(file)
    #expect(world.entityCount == 5)
    #expect(world.parent(of: first[0]) == holder && world.parent(of: second[0]) == nil)
    let firstArm = world.children(of: first[0])[0], secondArm = world.children(of: second[0])[0]
    #expect(world.get(Follow.self, for: firstArm)?.target == first[0])
    #expect(world.get(Follow.self, for: secondArm)?.target == second[0])
    #expect(world.get(GlobalTransform.self, for: firstArm)?.position == Vec3(1, 5, 0))
    #expect(throws: SceneError.staleParent) {
        let gone = world.spawn()
        world.despawn(gone)
        try world.load(file, under: gone)
    }
}

@MainActor @Test func unknownComponentsAreKeptAndWrittenBackUnchanged() throws {
    let world = World()
    let a = world.spawn(Marker(label: "a"))
    let b = world.spawn(Marker(label: "b"))
    world.add(Follow(target: b, backup: nil, chain: [a, b]), to: a)
    // Pretend Follow's type is gone: rename it in the file to a name nobody registered.
    let file = Data(text(try world.save()).replacingOccurrences(of: "Test.Follow", with: "Test.Gone").utf8)

    let loaded = World()
    let roots = try loaded.load(file)
    #expect(!loaded.has(Follow.self, for: roots[0]))
    let unresolved = try #require(loaded.get(UnresolvedComponents.self, for: roots[0]))
    #expect(Array(unresolved.components.keys) == ["Test.Gone"])
    // Saving writes the raw data back under its name, entity references included.
    #expect(try loaded.save() == file)

    // Additive load into a non-empty world: references inside the raw data are remapped too.
    let shifted = World()
    _ = shifted.spawn(Marker(label: "first"))
    let shiftedRoots = try shifted.load(file)
    #expect(try shifted.save(shiftedRoots) == file)

    // Once a type takes the name, the raw data turns into a real component.
    struct Missing: Component, Equatable {
        static let componentName = "Test.Gone"
        var target: Entity
        var backup: Entity?
        var chain: [Entity]
    }
    ComponentRegistry.register(Missing.self)
    #expect(shifted.resolveUnresolvedComponents() == 1)
    #expect(!shifted.has(UnresolvedComponents.self, for: shiftedRoots[0]))
    #expect(shifted.get(Missing.self, for: shiftedRoots[0]) == Missing(target: shiftedRoots[1], backup: nil, chain: shiftedRoots))
}

@MainActor @Test func savingIsStableAndLoadingThenSavingReproducesTheFile() throws {
    let world = World()
    for i in 0..<20 {
        let e = world.spawn(Transform(position: Vec3(Float(i), 0.1, -0.3)), Kitchen())
        if i % 3 != 0, let parent = world.entities.first { world.setParent(e, to: parent) }
        if i % 4 == 0 { world.add(Marker(label: "m\(i)"), to: e) }
    }
    world.despawn(world.entities[5])
    let first = try world.save()
    #expect(try world.save() == first)
    let (loaded, _) = try roundTrip(world)
    #expect(try loaded.save() == first)
    // Readable: sorted keys, vectors on one line.
    let json = text(first)
    #expect(json.contains("\"position\" : [0, 0.1, -0.3]"))
    #expect(json.contains("\"far\" : \"inf\""))
    #expect(json.firstRange(of: "\"entities\"")!.lowerBound < json.firstRange(of: "\"format\"")!.lowerBound)
}

@MainActor @Test func fileHasAVersionAndBadFilesAreRejected() throws {
    let world = World()
    let x = world.spawn(Marker(label: "x"))
    world.add(Follow(target: x), to: x)
    let json = text(try world.save())
    #expect(json.contains("\"format\" : \"SwiftGameEngine.Scene\""))
    #expect(json.contains("\"version\" : 2"))
    let newer = Data(json.replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 99").utf8)
    #expect(throws: SceneError.unsupportedVersion(99)) { try World().load(newer) }
    #expect(throws: SceneError.notASceneFile) { try World().load(Data("{\"entities\": []}".utf8)) }
    let badID = Data(json.replacingOccurrences(of: "\"id\" : 0", with: "\"id\" : 3").utf8)
    let target = World()
    #expect(throws: DecodingError.self) { try target.load(badID) }
    let badReference = Data(json.replacingOccurrences(of: "{ \"$entity\" : 0 }", with: "{ \"$entity\" : 7 }").utf8)
    #expect(throws: DecodingError.self) { try target.load(badReference) }
    #expect(target.entityCount == 0)  // nothing spawned on failure
    #expect(try target.load(Data(json.utf8)).count == 1)
}

@MainActor @Test func conflictingComponentNamesFailToSave() throws {
    struct One: Component { static let componentName = "Test.Clash" }
    struct Two: Component { static let componentName = "Test.Clash" }
    let world = World()
    _ = world.spawn(One())
    let e = world.spawn(Two())
    #expect(throws: SceneError.componentNameConflict("Test.Clash")) { try world.save([e]) }
}

// MARK: Snapshots

@MainActor @Test func restoreMakesTheWorldEqualToTheSnapshot() throws {
    let world = World()
    let player = world.spawn(Transform(), Marker(label: "player"))
    let gun = world.spawn(Transform(position: Vec3(1, 0, 0)), Marker(label: "gun"))
    world.setParent(gun, to: player)
    let doomed = world.spawn(Marker(label: "doomed"))
    world.despawn(world.spawn())  // a free slot in the snapshot
    world.update(dt: 0.1)
    let snapshot = world.snapshot()
    let saved = try world.save()
    let entities = world.entities
    let time = world.time.elapsed

    // Play: change values, the hierarchy, entity set and component types.
    world.modify(Transform.self, for: player) { $0.position.x = 50 }
    world.setParent(gun, to: nil)
    world.despawn(doomed)
    let spawnedInPlay = (0..<3).map { world.spawn(Marker(label: "spawned \($0)"), Follow(target: player)) }
    world.update(dt: 0.5)

    world.restore(snapshot)
    #expect(try world.save() == saved)
    #expect(world.entities == entities && world.entityCount == entities.count)
    #expect(world.isAlive(doomed) && world.parent(of: gun) == player)
    #expect(world.count(of: Follow.self) == 0 && world.time.elapsed == time)
    #expect(world.get(GlobalTransform.self, for: gun)?.position == Vec3(1, 0, 0))
    // Play-mode handles are stale and stay stale as slots get reused.
    #expect(spawnedInPlay.allSatisfy { !world.isAlive($0) })
    let respawned = (0..<4).map { _ in world.spawn() }
    #expect(spawnedInPlay.allSatisfy { !world.isAlive($0) })
    #expect(Set(respawned).isDisjoint(with: spawnedInPlay))
    // The snapshot is unaffected by restoring and can be restored again.
    world.restore(snapshot)
    #expect(try world.save() == saved && world.entities == entities)
    world.update(dt: 1.0 / 60.0)  // and the world still runs
}

// MARK: Reflection

@MainActor @Test func reflectionListsFieldsWithKindsValuesAndHints() throws {
    let fields = Kitchen().fields()
    #expect(fields.map(\.name) == ["flag", "count", "small", "speed", "precise", "name", "uv", "offset", "tint", "spin",
                                   "team", "shape", "stats", "points", "maybe", "maybeTeam", "maybeStats", "lookup", "far"])
    let byName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0) })
    #expect(byName["flag"]?.kind == .bool && byName["flag"]?.value == .bool(true))
    #expect(byName["count"]?.kind == .int && byName["count"]?.value == .int(-3))
    #expect(byName["small"]?.value == .int(200))
    #expect(byName["speed"]?.kind == .float && byName["speed"]?.value == .float(1.5))
    #expect(byName["speed"]?.hints.range == 0...10)
    #expect(byName["uv"]?.kind == .vec2 && byName["offset"]?.value == .vec3(Vec3(1, -2, 3.5)))
    #expect(byName["tint"]?.kind == .vec4 && byName["tint"]?.hints.color == true)
    #expect(byName["spin"]?.kind == .quat)
    #expect(byName["team"]?.kind == .enumeration(cases: ["red", "blue", "green"]) && byName["team"]?.value == .enumCase("blue"))
    #expect(byName["stats"]?.kind == .structure(typeName: "Stats"))
    #expect(byName["stats"]?.children.map(\.path) == ["stats.level", "stats.tags"])
    #expect(byName["stats"]?.children[1].children.map(\.value) == [.string("a"), .string("b")])
    #expect(byName["points"]?.kind == .array && byName["points"]?.children.map(\.path) == ["points.0", "points.1"])
    #expect(byName["points"]?.children[1].hints.step == 0.1)
    #expect(byName["maybe"]?.isOptional == true && byName["maybe"]?.kind == .float && byName["maybe"]?.value == .null)
    #expect(byName["maybeTeam"]?.isOptional == true && byName["maybeTeam"]?.value == .enumCase("green"))
    #expect(byName["maybeStats"]?.value == .null && byName["maybeStats"]?.kind == .unknown)
    #expect(byName["shape"]?.children.first?.name == "box")  // enums with payloads are structures
    #expect(Kitchen().field(at: "stats.level")?.value == .int(1))
    #expect(Follow(target: Entity(index: 3, generation: 1)).field(at: "target")?.value == .entity(Entity(index: 3, generation: 1)))
    #expect(GlobalTransform.fieldHints["matrix"]?.readOnly == true)
}

@MainActor @Test func setFieldByPathEditsTheComponent() throws {
    var k = Kitchen()
    try k.setField("speed", to: .float(4.25))
    try k.setField("count", to: .float(12))  // whole numbers convert
    try k.setField("team", to: .enumCase("red"))
    try k.setField("maybeTeam", to: .null)
    try k.setField("maybe", to: .int(3))
    try k.setField("offset", to: .vec3(Vec3(7, 8, 9)))
    try k.setField("spin", to: .quat(.identity))
    try k.setField("points.1", to: .vec3(Vec3(5, 5, 5)))
    try k.setField("stats.level", to: .int(42))
    try k.setField("stats.tags.0", to: .string("z"))
    try k.setField("name", to: .string("renamed"))
    try k.setField("lookup.y", to: .int(-1))
    #expect(k.speed == 4.25 && k.count == 12 && k.team == .red && k.maybeTeam == nil && k.maybe == 3)
    #expect(k.offset == Vec3(7, 8, 9) && k.spin == .identity && k.points == [.zero, Vec3(5, 5, 5)])
    #expect(k.stats == Stats(level: 42, tags: ["z", "b"]) && k.name == "renamed" && k.lookup == ["x": 1, "y": -1])
    #expect(k.precise == 0.1 && k.far == .infinity)  // untouched fields survive the round trip exactly
    try k.setField("maybeTeam", to: .string("blue"))
    #expect(k.maybeTeam == .blue)

    #expect(throws: SceneError.noSuchField("nope")) { try k.setField("nope", to: .int(1)) }
    #expect(throws: SceneError.noSuchField("points.9")) { try k.setField("points.9", to: .vec3(.zero)) }
    #expect(throws: SceneError.typeMismatch(path: "speed", expected: "float")) { try k.setField("speed", to: .string("x")) }
    #expect(throws: SceneError.typeMismatch(path: "count", expected: "int")) { try k.setField("count", to: .float(1.5)) }
    #expect(throws: SceneError.typeMismatch(path: "count", expected: "int")) { try k.setField("count", to: .null) }
    #expect(throws: (any Error).self) { try k.setField("small", to: .int(300)) }  // out of UInt8's range
    #expect(k.small == 200)

    // Through the world, by component name (what the inspector and undo records use).
    let world = World()
    let e = world.spawn(Kitchen(), Transform())
    let other = world.spawn()
    world.add(Follow(target: e), to: e)
    try world.setField("position", of: "Transform", for: e, to: .vec3(Vec3(1, 2, 3)))
    try world.setField("target", of: "Test.Follow", for: e, to: .entity(other))
    #expect(world.get(Transform.self, for: e)?.position == Vec3(1, 2, 3))
    #expect(world.get(Follow.self, for: e)?.target == other)
    #expect(world.fields(of: "Transform", for: e)?.map(\.name) == ["position", "rotation", "scale"])
    #expect(world.fields(of: "Transform", for: other) == nil)
    #expect(throws: SceneError.noSuchComponent("Test.Marker")) {
        try world.setField("label", of: "Test.Marker", for: e, to: .string("x"))
    }
}

@Test func eulerAnglesRoundTrip() {
    for degrees in [Vec3(0, 0, 0), Vec3(30, 0, 0), Vec3(0, 45, 0), Vec3(0, 0, -60), Vec3(10, 20, 30), Vec3(-170, 80, 95)] {
        let q = Quat(eulerDegrees: degrees)
        #expect(length(q.eulerDegrees - degrees) < 1e-2, "\(degrees) -> \(q.eulerDegrees)")
    }
    // X first, then Y, then Z (fixed axes).
    let q = Quat(eulerDegrees: Vec3(90, 90, 0))
    #expect(length(q * Vec3(0, 1, 0) - Vec3(1, 0, 0)) < 1e-5)
    // Gimbal lock still describes the same rotation.
    let locked = Quat(eulerDegrees: Vec3(20, 90, 30))
    let back = Quat(eulerDegrees: locked.eulerDegrees)
    #expect(length(locked * Vec3(1, 2, 3) - back * Vec3(1, 2, 3)) < 1e-3)
}

// MARK: Benchmark

/// Prints save/load/snapshot times for 10k entities. Only meaningful in release:
/// `swift test -c release -Xswiftc -enable-testing --filter sceneSerializationBenchmark`.
@MainActor @Test func sceneSerializationBenchmark() throws {
    let world = World()
    let count = 10_000
    var parent: Entity?
    for i in 0..<count {
        let e = world.spawn(Transform(position: Vec3(Float(i), 0.5, -1), rotation: Quat(angle: Float(i), axis: Vec3(0, 1, 0))),
                            Marker(label: "entity \(i)"))
        if i % 10 == 0 { parent = e } else if let parent { world.setParent(e, to: parent) }
        if i % 2 == 0, let parent { world.add(Follow(target: parent), to: e) }
    }
    let clock = ContinuousClock()
    var data = Data()
    var bestSave = Duration.seconds(1000), bestLoad = Duration.seconds(1000)
    var bestSnapshot = Duration.seconds(1000), bestRestore = Duration.seconds(1000)
    for _ in 0..<5 {
        let t0 = clock.now
        data = try world.save()
        bestSave = min(bestSave, clock.now - t0)
        let target = World()
        let t1 = clock.now
        _ = try target.load(data)
        bestLoad = min(bestLoad, clock.now - t1)
        #expect(target.entityCount == count)
        let t2 = clock.now
        let snapshot = world.snapshot()
        bestSnapshot = min(bestSnapshot, clock.now - t2)
        let t3 = clock.now
        world.restore(snapshot)
        bestRestore = min(bestRestore, clock.now - t3)
    }
    // Reflection on a component with ~40 fields (counting nested ones).
    var kitchen = Kitchen()
    let t0 = clock.now
    for _ in 0..<1000 { #expect(kitchen.fields().count == 19) }
    let reflect = (clock.now - t0) / 1000
    let t1 = clock.now
    for i in 0..<1000 { try kitchen.setField("speed", to: .float(Double(i))) }
    let set = (clock.now - t1) / 1000
    print("Scene benchmark, \(count) entities (\(data.count / 1024) KiB): save \(bestSave), load \(bestLoad), "
        + "snapshot \(bestSnapshot), restore \(bestRestore); Kitchen.fields() \(reflect), setField \(set)")
}
