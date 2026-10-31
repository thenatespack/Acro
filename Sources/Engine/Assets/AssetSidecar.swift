import Foundation

// Sidecar files: `<file>.meta` next to every file in `Assets/` (e.g. `rock.obj.meta`).
//
// ```json
// {
//   "id" : "5f1c0e9a8b7d4c3e2f1a0b9c8d7e6f50",
//   "importer" : "obj",
//   "settings" : {
//     "flipV" : true,
//     "scale" : 1
//   },
//   "version" : 1
// }
// ```
//
// - `id` is the asset's `AssetID`. It is what other files store, so keep the sidecar with its
//   file when renaming or moving it (and commit both).
// - `importer` names the importer (`AssetImporter.name`); absent for files no importer handles
//   (they still get an id). `settings` are that importer's settings; keys left out get their
//   defaults, so a hand-written `{"id": "…"}` is valid.
// - Sorted keys, two-space indentation, short number arrays on one line and a final newline,
//   so sidecars diff cleanly. The database writes a sidecar only when it creates one, assigns
//   a new id or changes settings (`AssetDatabase.setSettings`), never just because it read it.
// - `version` is the sidecar format version (1).

/// The contents of a `.meta` sidecar.
public struct AssetSidecar: Equatable, Sendable, Codable {
    public static let fileExtension = "meta"
    public static let currentVersion = 1

    public var id: AssetID
    public var importer: String?
    public var settings: JSONValue?

    public init(id: AssetID, importer: String? = nil, settings: JSONValue? = nil) {
        self.id = id
        self.importer = importer
        self.settings = settings
    }

    private enum CodingKeys: String, CodingKey { case id, importer, settings, version }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version <= Self.currentVersion else { throw AssetError.badSidecar("version \(version) is newer than supported") }
        id = try c.decode(AssetID.self, forKey: .id)
        importer = try c.decodeIfPresent(String.self, forKey: .importer)
        settings = try c.decodeIfPresent(JSONValue.self, forKey: .settings)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(importer, forKey: .importer)
        try c.encodeIfPresent(settings, forKey: .settings)
        try c.encode(Self.currentVersion, forKey: .version)
    }

    /// The sidecar URL for an asset file (`rock.obj` → `rock.obj.meta`).
    public static func url(for file: URL) -> URL {
        file.deletingLastPathComponent().appendingPathComponent(file.lastPathComponent + "." + fileExtension)
    }

    public static func read(from url: URL) throws -> AssetSidecar {
        do {
            return try AssetJSON.decoder().decode(AssetSidecar.self, from: Data(contentsOf: url))
        } catch let error as AssetError {
            throw error
        } catch {
            throw AssetError.badSidecar("\(url.lastPathComponent): \(error)")
        }
    }

    public func write(to url: URL) throws {
        try AssetJSON.encode(self).write(to: url, options: .atomic)
    }
}
