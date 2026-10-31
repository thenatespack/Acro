import Foundation

// Settings: one Codable struct of the game's options, kept as JSON in the user data folder.
//
// ```swift
// struct GameSettings: Settings {
//     var volume: Float = 0.7
//     var subtitles = true
// }
// let store = SettingsStore<GameSettings>(app: "MyGame")
// store.load()                    // never throws: a missing or damaged file gives the defaults
// store.values.volume = 0.5
// try store.save()
// ```
//
// - The file is `{"format": "SwiftGameEngine.Settings", "version": N, "values": {...}}`.
// - Decoding is tolerant: a key the file lacks keeps its default, a key the struct no longer
//   has is dropped, and a key whose value has the wrong type keeps its default while the rest
//   load. A file that isn't JSON at all gives the defaults and `lastLoadError`; the next
//   `save()` replaces it.
// - Changing what a field means: bump `version` and rewrite the old keys in `migrate`.
//   Adding or removing fields needs neither.

/// A game's settings: defaults come from `init()`.
public protocol Settings: Codable, Equatable {
    /// All defaults.
    init()
    /// The version `save` writes (default 1). Bump it when a field changes meaning.
    static var version: Int { get }
    /// Rewrites `values` (the file's keys, before decoding) from `version` to the current
    /// one. Called only for files older than `Self.version`. Default: nothing.
    static func migrate(_ values: inout [String: JSONValue], from version: Int)
}

extension Settings {
    public static var version: Int { 1 }
    public static func migrate(_ values: inout [String: JSONValue], from version: Int) {}
}

/// Loads and saves a `Settings` value to `<user data dir>/<file>`.
public final class SettingsStore<S: Settings> {
    public static var format: String { "SwiftGameEngine.Settings" }

    public var values = S()
    public let url: URL
    /// Why the last `load()` fell back to defaults, wholly or in part (nil: it didn't).
    public private(set) var lastLoadError: String?

    /// `app` names the folder under the user's data directory (see `UserData`); `directory`
    /// replaces the whole folder.
    public init(app: String, file: String = "settings.json", directory: URL? = nil) {
        url = (directory ?? UserData.directory(app: app)).appendingPathComponent(file)
    }

    /// Reads the file into `values` and returns them. A missing file, damage and wrong-typed
    /// keys fall back to defaults (key by key where possible); the reason is kept in
    /// `lastLoadError`.
    @discardableResult
    public func load() -> S {
        lastLoadError = nil
        values = S()
        guard let data = try? Data(contentsOf: url) else { return values }
        do {
            values = try Self.decode(data, note: &lastLoadError)
        } catch {
            lastLoadError = "\(error)"
        }
        return values
    }

    /// Writes `values` atomically.
    public func save() throws {
        try AtomicFile.write(try Self.encode(values), to: url)
    }

    /// Deletes the file and goes back to the defaults.
    public func reset() throws {
        values = S()
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    // MARK: Coding

    static func encode(_ values: S) throws -> Data {
        let file = JSONValue.object([
            "format": .string(format), "version": .int(Int64(S.version)), "values": try JSONValue.encoding(values),
        ])
        let encoder = SceneCoder.encoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(file)
    }

    static func decode(_ data: Data, note: inout String?) throws -> S {
        guard case .object(let root) = try SceneCoder.decoder().decode(JSONValue.self, from: data),
              case .string(let format)? = root["format"], format == Self.format,
              case .object(var stored)? = root["values"] else {
            throw SettingsError.notASettingsFile
        }
        if case .int(let version)? = root["version"], version < Int64(S.version) {
            S.migrate(&stored, from: Int(version))
        }
        // Start from the defaults and lay the file's keys over them one at a time, keeping
        // each only if the struct still decodes.
        guard case .object(var merged) = try JSONValue.encoding(S()) else { throw SettingsError.notASettingsFile }
        var skipped: [String] = []
        for (key, value) in stored.sorted(by: { $0.key < $1.key }) {
            let previous = merged[key]
            merged[key] = value
            if (try? JSONValue.object(merged).decode(S.self)) == nil {
                merged[key] = previous
                skipped.append(key)
            }
        }
        if !skipped.isEmpty { note = "Ignored settings with unusable values: \(skipped.joined(separator: ", "))" }
        return try JSONValue.object(merged).decode(S.self)
    }
}

public enum SettingsError: Error, CustomStringConvertible {
    case notASettingsFile

    public var description: String { "Not a settings file" }
}
