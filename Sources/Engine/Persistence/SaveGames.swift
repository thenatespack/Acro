import Foundation

// Save games: named slots in `<user data dir>/saves/`, each a JSON file `<slot>.save.json`
// (plus `<slot>.png` when there is a thumbnail).
//
// ```swift
// struct Progress: Codable { var level = 3; var gold = 120 }
// let saves = SaveGames(app: "MyGame")
// try saves.save(slot: "quick", state: Progress(), world: world, sceneName: "level3", playtime: 812)
// let game = try saves.load(slot: "quick")       // throws SaveError.corrupt for a damaged file
// let progress = try game.state(Progress.self)
// try game.apply(to: world)                       // despawns the Saveable entities, loads the saved ones
// ```
//
// What is saved:
// - `info`: slot name, time, playtime, scene name (what a load menu lists, see `list()`).
// - `state`: any Codable game value (progress, inventory, flags).
// - `world`: the entities marked `Saveable` and their subtrees, written by `World.save` (see
//   World+Serialization.swift), so components, hierarchy and `EntityID`s are the scene format's.
//   A `Saveable` child of an unsaved parent is saved as a root and loses its parent.
//
// References: every saved entity is given a persistent `EntityID` first, and `apply` despawns
// the current `Saveable` entities before loading, so the loaded entities get their ids back
// and an `EntityRef` (from a saved entity to another saved one, or to a never-saved scene
// entity such as the level's door) resolves again. An `Entity` handle field points at a saved
// entity only (it loads as nil / `.invalid` for one that wasn't saved); use `EntityRef` for
// anything that can point outside the saved set.
//
// File: `{"format": "SwiftGameEngine.Save", "version": N, "info": {...}, "state": {...},
// "world": "<the scene file's JSON, as a string>"}`. Older versions are rewritten by
// `migrate` (given the file as JSON) before decoding; newer ones throw `unsupportedVersion`.
// Writes are atomic, so a crash while saving leaves the previous save.

/// Marks an entity (and its descendants) as part of the save game.
public struct Saveable: Component, Equatable, Sendable {
    public static let componentName = "Saveable"
    public init() {}
}

/// What a load menu shows for a slot.
public struct SaveSlotInfo: Codable, Equatable, Sendable {
    public var slot: String
    public var savedAt: Date
    /// Seconds played, as the game counted them.
    public var playtime: Double
    public var sceneName: String
    /// Whether `<slot>.png` exists next to the save.
    public var hasThumbnail: Bool
}

/// One slot as `SaveGames.list()` found it.
public struct SaveSlotEntry {
    public var slot: String
    /// The metadata, or nil for a damaged file (then `error` says why).
    public var info: SaveSlotInfo?
    public var error: SaveError?
}

public enum SaveError: Error, Equatable, CustomStringConvertible {
    /// The slot name isn't letters, digits, `-`, `_` or `.` (it becomes a file name).
    case invalidSlotName(String)
    case notFound(String)
    /// The file couldn't be read as a save (truncated, edited by hand, wrong file).
    case corrupt(slot: String, reason: String)
    /// Written by a newer engine or game.
    case unsupportedVersion(Int)

    public var description: String {
        switch self {
        case .invalidSlotName(let name): "Invalid save slot name '\(name)'"
        case .notFound(let slot): "No save in slot '\(slot)'"
        case .corrupt(let slot, let reason): "Save slot '\(slot)' is damaged: \(reason)"
        case .unsupportedVersion(let v): "Save version \(v) is newer than this game supports"
        }
    }
}

/// A save read from disk. `apply` and `state` don't touch the disk again.
public struct SaveGame {
    public let info: SaveSlotInfo
    let state: JSONValue
    let worldData: Data?

    /// The game state saved with it, decoded as `T`.
    public func state<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        try state.decode(type)
    }

    /// Whether the save holds entities.
    public var hasWorld: Bool { worldData != nil }

    /// Replaces `world`'s `Saveable` entities with the saved ones and returns the new roots.
    /// The file is checked first (decoded into a scratch world), so a damaged one throws
    /// before anything is despawned. Not callable inside a query.
    @MainActor
    @discardableResult
    public func apply(to world: World) throws -> [Entity] {
        guard let worldData else { return [] }
        do { _ = try World().load(worldData) } catch {
            throw SaveError.corrupt(slot: info.slot, reason: "\(error)")
        }
        for entity in world.saveableRoots() { world.despawn(entity) }
        return try world.load(worldData)
    }
}

extension World {
    /// The `Saveable` entities, in slot order.
    func saveableRoots() -> [Entity] {
        var found: [Entity] = []
        query(Saveable.self) { entity, _ in found.append(entity) }
        return found.sorted { $0.index < $1.index }
    }
}

/// The save slots of one game.
@MainActor
public final class SaveGames {
    public static let format = "SwiftGameEngine.Save"
    /// The version `save` writes. Bump it when the layout of `state` changes and add the
    /// conversion to `migrate`.
    public var version = 1
    /// Rewrites a file's JSON (`info`, `state`, `world`) from `fromVersion` to `version`, for
    /// files older than `version`. Throw to refuse the file.
    public var migrate: (_ file: inout [String: JSONValue], _ fromVersion: Int) throws -> Void = { _, _ in }
    public let directory: URL

    /// `app` names the folder under the user's data directory (see `UserData`); `directory`
    /// replaces the whole user folder. Saves go to its `saves` subfolder.
    public init(app: String, directory: URL? = nil) {
        self.directory = (directory ?? UserData.directory(app: app)).appendingPathComponent("saves", isDirectory: true)
    }

    private struct Header: Codable {
        var format: String
        var version: Int
        var info: SaveSlotInfo
        var state: JSONValue
        var world: String?
    }

    // MARK: Slots

    /// Writes `slot`. `world` contributes its `Saveable` entities (none if nil); `thumbnail`
    /// is stored as a PNG next to the file. Returns the slot's info.
    @discardableResult
    public func save<State: Encodable>(slot: String, state: State, world: World? = nil, sceneName: String = "",
                                       playtime: Double = 0, thumbnail: Image? = nil, date: Date = Date()) throws -> SaveSlotInfo {
        try checkName(slot)
        var worldText: String?
        if let world {
            let roots = world.saveableRoots()
            for root in roots { world.ensureIDs(inSubtreeOf: root) }
            worldText = String(decoding: try world.save(roots), as: UTF8.self)
        }
        let info = SaveSlotInfo(slot: slot, savedAt: date, playtime: playtime, sceneName: sceneName, hasThumbnail: thumbnail != nil)
        let header = Header(format: Self.format, version: version, info: info, state: try JSONValue.encoding(state), world: worldText)
        let encoder = SceneCoder.encoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try AtomicFile.write(try encoder.encode(header), to: file(slot))
        // The thumbnail is decoration: losing it must not fail the save.
        if let thumbnail {
            do { try AtomicFile.write(thumbnail.pngData(), to: thumbnailURL(slot)) } catch {
                try? FileManager.default.removeItem(at: thumbnailURL(slot))
                var fixed = info
                fixed.hasThumbnail = false
                return fixed
            }
        } else {
            try? FileManager.default.removeItem(at: thumbnailURL(slot))
        }
        return info
    }

    /// Reads `slot`. Throws `notFound`, `corrupt` (not JSON, truncated, not a save, damaged
    /// entities) or `unsupportedVersion`; never traps.
    public func load(slot: String) throws -> SaveGame {
        try checkName(slot)
        guard let data = try? Data(contentsOf: file(slot)) else { throw SaveError.notFound(slot) }
        return try decode(data, slot: slot)
    }

    /// The thumbnail's PNG bytes, if the slot has one.
    public func thumbnail(slot: String) -> Data? {
        guard (try? checkName(slot)) != nil else { return nil }
        return try? Data(contentsOf: thumbnailURL(slot))
    }

    public func exists(slot: String) -> Bool {
        (try? checkName(slot)) != nil && FileManager.default.fileExists(atPath: file(slot).path)
    }

    /// Removes the slot's files (no error if it doesn't exist).
    public func delete(slot: String) throws {
        try checkName(slot)
        for url in [file(slot), thumbnailURL(slot)] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    /// Every slot, newest first; damaged ones are listed with their error rather than skipped.
    public func list() -> [SaveSlotEntry] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let suffix = ".save.json"
        var entries: [(Date, SaveSlotEntry)] = []
        for name in names where name.hasSuffix(suffix) && !name.hasPrefix(".") {
            let slot = String(name.dropLast(suffix.count))
            do {
                let info = try load(slot: slot).info
                entries.append((info.savedAt, SaveSlotEntry(slot: slot, info: info, error: nil)))
            } catch let error as SaveError {
                entries.append((.distantPast, SaveSlotEntry(slot: slot, info: nil, error: error)))
            } catch {
                entries.append((.distantPast, SaveSlotEntry(slot: slot, info: nil, error: .corrupt(slot: slot, reason: "\(error)"))))
            }
        }
        return entries.sorted { ($0.0, $1.1.slot) > ($1.0, $0.1.slot) }.map(\.1)
    }

    // MARK: Decoding

    func decode(_ data: Data, slot: String) throws -> SaveGame {
        func corrupt(_ reason: Any) -> SaveError { .corrupt(slot: slot, reason: "\(reason)") }
        var root: [String: JSONValue]
        do {
            guard case .object(let object) = try SceneCoder.decoder().decode(JSONValue.self, from: data) else {
                throw corrupt("not a JSON object")
            }
            root = object
        } catch let error as SaveError {
            throw error
        } catch {
            throw corrupt("not valid JSON")
        }
        guard case .string(let format)? = root["format"], format == Self.format, case .int(let fileVersion)? = root["version"] else {
            throw corrupt("not a save file")
        }
        if fileVersion > Int64(version) { throw SaveError.unsupportedVersion(Int(fileVersion)) }
        if fileVersion < Int64(version) {
            do { try migrate(&root, Int(fileVersion)) } catch { throw corrupt("migration failed: \(error)") }
        }
        do {
            let header = try JSONValue.object(root).decode(Header.self)
            var info = header.info
            info.slot = slot
            return SaveGame(info: info, state: header.state, worldData: header.world.map { Data($0.utf8) })
        } catch {
            throw corrupt(error)
        }
    }

    // MARK: Paths

    private func checkName(_ slot: String) throws {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard !slot.isEmpty, slot.count <= 64, !slot.hasPrefix("."), slot.allSatisfy({ allowed.contains($0) }) else {
            throw SaveError.invalidSlotName(slot)
        }
    }

    private func file(_ slot: String) -> URL { directory.appendingPathComponent("\(slot).save.json") }
    private func thumbnailURL(_ slot: String) -> URL { directory.appendingPathComponent("\(slot).png") }
}

/// Saves on a timer: call `update(dt:)` every frame and give it the save to run. A failed
/// autosave is kept in `lastError` rather than thrown into the game loop.
@MainActor
public final class Autosaver {
    public var interval: Double
    public var isEnabled = true
    public private(set) var lastError: Error?
    public private(set) var saveCount = 0
    private var elapsed = 0.0
    private let action: () throws -> Void

    public init(interval: Double = 120, action: @escaping () throws -> Void) {
        self.interval = interval
        self.action = action
    }

    public func update(dt: Double) {
        guard isEnabled else { return }
        elapsed += dt
        if elapsed >= interval { saveNow() }
    }

    /// Runs the save now and restarts the timer.
    public func saveNow() {
        elapsed = 0
        do {
            try action()
            saveCount += 1
            lastError = nil
        } catch {
            lastError = error
        }
    }
}
