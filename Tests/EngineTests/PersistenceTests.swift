import Foundation
import Testing
@testable import Engine

// Settings store and save games: round trips, tolerant decoding, migration, atomic writes,
// corrupted files, and EntityRefs surviving a load. Everything runs in a scratch directory.

private struct Options: Settings, Equatable {
    var volume: Float = 0.7
    var theme = "dark"
    var subtitles = true
    var scale: Float = 1
}

private struct OptionsV2: Settings, Equatable {
    static var version: Int { 2 }
    // v1 stored "quality" as an Int 0...3; v2 names it.
    var quality = "high"
    static func migrate(_ values: inout [String: JSONValue], from version: Int) {
        if version < 2, case .int(let level)? = values["quality"] {
            values["quality"] = .string(["low", "medium", "high", "ultra"][Int(level)])
        }
    }
}

private struct OptionsV1: Settings, Equatable {
    var quality: Int = 2
}

private struct PersistenceTestsFollow: Component, Equatable {
    static let componentName = "PersistenceTests.Follow"
    var target = EntityRef()
    var buddy: Entity?
}

private struct PersistenceTestsHealth: Component, Equatable {
    static let componentName = "PersistenceTests.Health"
    var hp = 10
}

private struct Progress: Codable, Equatable {
    var level = 3
    var gold = 120
    var flags = ["door": true]
}

@MainActor
@Suite struct PersistenceTests {
    let dir: URL

    init() {
        ComponentRegistry.register(PersistenceTestsFollow.self, PersistenceTestsHealth.self)
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("PersistenceTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func cleanUp() { try? FileManager.default.removeItem(at: dir) }

    // MARK: Directory

    @Test func envOverrideReplacesTheDirectory() {
        // Only the lookup's shape is checked: the variable itself can't be set from here.
        let url = UserData.directory(app: "PersistenceTestsApp")
        if UserData.isOverridden {
            #expect(url.lastPathComponent != "PersistenceTestsApp")
        } else {
            #expect(url.lastPathComponent == "PersistenceTestsApp")
        }
    }

    // MARK: Settings

    @Test func settingsRoundTrip() throws {
        defer { cleanUp() }
        let store = SettingsStore<Options>(app: "x", directory: dir)
        store.load()
        #expect(store.values == Options())
        store.values.volume = 0.25
        store.values.theme = "light"
        try store.save()

        let again = SettingsStore<Options>(app: "x", directory: dir)
        #expect(again.load().volume == 0.25)
        #expect(again.values.theme == "light")
        #expect(again.lastLoadError == nil)
    }

    @Test func missingAndExtraKeysKeepDefaults() throws {
        defer { cleanUp() }
        let store = SettingsStore<Options>(app: "x", directory: dir)
        let json = #"{"format":"SwiftGameEngine.Settings","version":1,"values":{"volume":0.1,"removedOption":[1,2],"theme":"light"}}"#
        try AtomicFile.write(Data(json.utf8), to: store.url)
        let loaded = store.load()
        #expect(loaded.volume == 0.1)
        #expect(loaded.theme == "light")
        #expect(loaded.subtitles == true)
        #expect(loaded.scale == 1)
    }

    @Test func wrongTypedKeyKeepsItsDefaultAndTheRestLoad() throws {
        defer { cleanUp() }
        let store = SettingsStore<Options>(app: "x", directory: dir)
        let json = #"{"format":"SwiftGameEngine.Settings","version":1,"values":{"volume":"loud","theme":"light"}}"#
        try AtomicFile.write(Data(json.utf8), to: store.url)
        let loaded = store.load()
        #expect(loaded.volume == 0.7)
        #expect(loaded.theme == "light")
        #expect(store.lastLoadError?.contains("volume") == true)
    }

    @Test func damagedSettingsGiveDefaults() throws {
        defer { cleanUp() }
        let store = SettingsStore<Options>(app: "x", directory: dir)
        try AtomicFile.write(Data("{ not json".utf8), to: store.url)
        #expect(store.load() == Options())
        #expect(store.lastLoadError != nil)
        try store.save()
        #expect(SettingsStore<Options>(app: "x", directory: dir).load() == Options())
    }

    @Test func settingsMigrate() throws {
        defer { cleanUp() }
        let old = SettingsStore<OptionsV1>(app: "x", directory: dir)
        old.values.quality = 3
        try old.save()
        let migrated = SettingsStore<OptionsV2>(app: "x", directory: dir)
        #expect(migrated.load().quality == "ultra")
    }

    // MARK: Atomic writes

    @Test func failedAtomicWriteLeavesTheOldFile() throws {
        defer { cleanUp() }
        let url = dir.appendingPathComponent("file.json")
        try AtomicFile.write(Data("old".utf8), to: url)
        struct Boom: Error {}
        #expect(throws: Boom.self) { try AtomicFile.write(Data("new".utf8), to: url, beforeCommit: { throw Boom() }) }
        #expect(try Data(contentsOf: url) == Data("old".utf8))
        // No temporary file is left behind.
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path) == ["file.json"])
        try AtomicFile.write(Data("new".utf8), to: url)
        #expect(try Data(contentsOf: url) == Data("new".utf8))
    }

    // MARK: Save games

    /// "Hero" (saveable, with a child) follows "Door" (not saveable); "Pet" follows "Hero".
    private func makeWorld() -> (World, hero: Entity, door: Entity) {
        let world = World()
        let door = world.spawn(Transform(position: Vec3(9, 0, 0)), Name("Door"))
        let hero = world.spawn(Transform(position: Vec3(1, 2, 3)), Name("Hero"), Saveable(), PersistenceTestsHealth(hp: 7))
        let hat = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("Hat"))
        world.setParent(hat, to: hero)
        let pet = world.spawn(Transform(), Name("Pet"), Saveable())
        world.add(PersistenceTestsFollow(target: world.ref(to: hero), buddy: hero), to: pet)
        world.add(PersistenceTestsFollow(target: world.ref(to: door), buddy: pet), to: hat)
        return (world, hero, door)
    }

    @Test func saveRoundTripKeepsHierarchyAndReferences() throws {
        defer { cleanUp() }
        let (world, hero, door) = makeWorld()
        let saves = SaveGames(app: "x", directory: dir)
        let info = try saves.save(slot: "one", state: Progress(), world: world, sceneName: "level3", playtime: 61.5)
        #expect(info.sceneName == "level3")

        // Play on: the hero moves and is despawned, a new saveable appears.
        world.modify(Transform.self, for: hero) { $0.position = Vec3(100, 0, 0) }
        world.spawn(Name("Stray"), Saveable())
        let door2 = door

        let game = try saves.load(slot: "one")
        #expect(game.info.playtime == 61.5)
        #expect(try game.state(Progress.self) == Progress())
        let roots = try game.apply(to: world)
        #expect(roots.count == 2)

        // Door was not saveable: untouched, same handle. Stray is gone.
        #expect(world.isAlive(door2))
        #expect(world.query(named: "Stray").isEmpty)
        let newHero = try #require(world.query(named: "Hero").first)
        #expect(world.get(Transform.self, for: newHero)?.position == Vec3(1, 2, 3))
        #expect(world.get(PersistenceTestsHealth.self, for: newHero)?.hp == 7)
        let hat = try #require(world.children(of: newHero).first)
        #expect(world.get(Name.self, for: hat)?.value == "Hat")
        // The hat's ref to the unsaved door, and the pet's ref to the hero, still resolve.
        let hatFollow = try #require(world.get(PersistenceTestsFollow.self, for: hat))
        #expect(world.resolve(hatFollow.target) == door)
        let pet = try #require(world.query(named: "Pet").first)
        let petFollow = try #require(world.get(PersistenceTestsFollow.self, for: pet))
        #expect(world.resolve(petFollow.target) == newHero)
        #expect(petFollow.buddy == newHero)
        #expect(world.get(Transform.self, for: hat) != nil)
    }

    @Test func listDeleteThumbnailAndNames() throws {
        defer { cleanUp() }
        let saves = SaveGames(app: "x", directory: dir)
        let thumb = Image(width: 2, height: 2, pixels: [UInt8](repeating: 200, count: 16))
        try saves.save(slot: "old", state: Progress(), date: Date(timeIntervalSince1970: 1000))
        try saves.save(slot: "new", state: Progress(), thumbnail: thumb, date: Date(timeIntervalSince1970: 2000))
        let entries = saves.list()
        #expect(entries.map(\.slot) == ["new", "old"])
        #expect(entries[0].info?.hasThumbnail == true)
        #expect(saves.thumbnail(slot: "new")?.starts(with: [0x89, 0x50, 0x4E, 0x47]) == true)
        try saves.delete(slot: "new")
        #expect(!saves.exists(slot: "new"))
        #expect(saves.thumbnail(slot: "new") == nil)
        #expect(throws: SaveError.notFound("new")) { try saves.load(slot: "new") }
        #expect(throws: SaveError.invalidSlotName("../evil")) { try saves.load(slot: "../evil") }
    }

    @Test func corruptedSaveIsAnErrorNotACrash() throws {
        defer { cleanUp() }
        let saves = SaveGames(app: "x", directory: dir)
        try saves.save(slot: "good", state: Progress())
        let (world, _, _) = makeWorld()
        try saves.save(slot: "bad", state: Progress(), world: world)

        let badURL = saves.directory.appendingPathComponent("bad.save.json")
        let full = try Data(contentsOf: badURL)
        try full.prefix(full.count / 2).write(to: badURL)
        #expect(throws: SaveError.self) { try saves.load(slot: "bad") }

        try Data(#"{"hello": 1}"#.utf8).write(to: badURL)
        #expect(throws: SaveError.self) { try saves.load(slot: "bad") }

        let entries = saves.list()
        #expect(entries.count == 2)
        #expect(entries.first { $0.slot == "bad" }?.error != nil)
        #expect(entries.first { $0.slot == "good" }?.info != nil)
    }

    @Test func damagedWorldDoesNotDespawnAnything() throws {
        defer { cleanUp() }
        let saves = SaveGames(app: "x", directory: dir)
        let (world, hero, _) = makeWorld()
        try saves.save(slot: "s", state: Progress(), world: world)
        let url = saves.directory.appendingPathComponent("s.save.json")
        var text = try String(contentsOf: url, encoding: .utf8)
        text = text.replacingOccurrences(of: "PersistenceTests.Health", with: "PersistenceTests.Health\\\"")
        try Data(text.utf8).write(to: url)
        let game = try? saves.load(slot: "s")
        if let game {
            #expect(throws: SaveError.self) { try game.apply(to: world) }
        }
        #expect(world.isAlive(hero))
    }

    @Test func newerVersionIsRejectedAndOlderMigrates() throws {
        defer { cleanUp() }
        let saves = SaveGames(app: "x", directory: dir)
        try saves.save(slot: "s", state: Progress(level: 1))
        saves.version = 2
        saves.migrate = { file, from in
            #expect(from == 1)
            if case .object(var state)? = file["state"] {
                state["gold"] = .int(999)
                file["state"] = .object(state)
            }
        }
        let game = try saves.load(slot: "s")
        #expect(try game.state(Progress.self).gold == 999)
        #expect(try game.state(Progress.self).level == 1)

        try saves.save(slot: "s2", state: Progress())
        saves.version = 1
        #expect(throws: SaveError.unsupportedVersion(2)) { try saves.load(slot: "s2") }
    }

    @Test func autosaverFiresOnItsInterval() {
        var count = 0
        let saver = Autosaver(interval: 1) { count += 1 }
        for _ in 0..<5 { saver.update(dt: 0.25) }
        #expect(count == 1)
        saver.saveNow()
        #expect(saver.saveCount == 2)
        let failing = Autosaver(interval: 0) { throw SaveError.notFound("x") }
        failing.update(dt: 0.1)
        #expect(failing.lastError != nil)
    }
}

extension World {
    fileprivate func query(named name: String) -> [Entity] {
        entities.filter { get(Name.self, for: $0)?.value == name }
    }
}
