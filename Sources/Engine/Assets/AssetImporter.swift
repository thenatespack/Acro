import Foundation

// Importers turn a source file in `Assets/` into CPU-side objects (`ImportedAsset`).
//
// ## Writing one
//
// ```swift
// struct TextureImporter: AssetImporter {
//     struct Settings: Codable, Equatable, Sendable {
//         var sRGB = true
//         var mipmaps = true
//     }
//     var name: String { "texture" }                       // stored in sidecars; never change it
//     var fileExtensions: [String] { ["png", "jpg", "jpeg", "tga", "hdr"] }
//     var version: Int { 1 }                               // bump to reimport every texture
//     var defaultSettings: Settings { Settings() }
//
//     func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
//         let image = try decode(context.data())
//         var asset = ImportedAsset()
//         asset.add("texture", .texture(TextureAsset(image: image, isSRGB: settings.sRGB, generatesMipmaps: settings.mipmaps)))
//         return asset
//     }
// }
//
// AssetImporterRegistry.standard.register(TextureImporter())   // before opening projects
// ```
//
// Rules:
// - `importAsset` must not touch a `RenderDevice` or other main-actor state: it can run on a
//   background thread (`AssetImportJob.run()`). The renderer uploads the result later.
// - Settings come from the asset's sidecar, overlaid on `defaultSettings`, so settings added
//   in a later version get their default in old sidecars without custom decoding.
// - Reimport happens only when the source bytes, the settings or `version` change (or the
//   cache in `Library/` is missing); otherwise the database loads the cached result.
// - Sub-asset ids must be stable across reimports (see `SubAssetID`, `SubAssetNamer`).
// - References between objects of the same file use `context.reference(_:)`; to other files,
//   `context.asset(atRelativePath:)` (e.g. a glTF's external texture next to it).
// - Other files the import reads (a glTF's `.bin`) go through `context.readDependency(relativePath:)`,
//   which records them: the asset is reimported when one of them changes, not only its source.
// - Extra derived files (anything worth caching beyond the returned objects) can go in
//   `context.artifactsDirectory`, which is emptied before every import. Expensive results worth
//   keeping across reimports (the texture importer's compressed mips) go in
//   `context.cacheDirectory`, keyed by what they were made from.

/// Converts files of some types into `ImportedAsset`s. See the notes above.
public protocol AssetImporter: Sendable {
    /// Import options stored in the sidecar (JSON). Use `NoImportSettings` for none.
    associatedtype Settings: Codable & Equatable & Sendable

    /// A stable identifier stored in sidecars ("texture", "gltf"). Never change it.
    var name: String { get }
    /// Lowercase file extensions without the dot ("png", "glb").
    var fileExtensions: [String] { get }
    /// Bump when the output changes for the same input: every asset it imported is reimported.
    var version: Int { get }
    var defaultSettings: Settings { get }

    /// Reads the source (`context.data()` / `context.sourceURL`) and returns its objects.
    /// Throwing marks the asset as failed (logged in the scan report); its previous import stays.
    func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset
}

/// Settings for importers that have none.
public struct NoImportSettings: Codable, Equatable, Sendable {
    public init() {}
}

extension AssetImporter where Settings == NoImportSettings {
    public var defaultSettings: NoImportSettings { NoImportSettings() }
}

/// What an importer gets besides its settings: where the source is, the asset's id, a place
/// for cached artifacts and a snapshot of the project's other assets.
public struct ImportContext: Sendable {
    public let assetID: AssetID
    /// The source file.
    public let sourceURL: URL
    /// The source's path relative to `Assets/`, with "/" separators.
    public let assetPath: String
    /// `Library/Artifacts/<id>/files/`: created and emptied before the import. Put derived files here.
    public let artifactsDirectory: URL
    /// `Library/Artifacts/<id>/cache/` (nil outside a database): kept across reimports of the
    /// asset and removed with it. Not created; name files by a hash of everything they depend on
    /// (source, settings, encoder version), since a reimport doesn't clear stale ones.
    public let cacheDirectory: URL?
    /// Problems that didn't stop the import; they show up in the scan report.
    public var warnings: [String] = []
    /// Every asset in the project at the time of the import, by path relative to `Assets/`.
    let assetsByPath: [String: AssetID]
    /// The files `readDependency` read. Shared by copies of the context.
    let dependencyLog = DependencyLog()

    public init(assetID: AssetID, sourceURL: URL, assetPath: String, artifactsDirectory: URL,
                cacheDirectory: URL? = nil, assetsByPath: [String: AssetID] = [:]) {
        self.assetID = assetID
        self.sourceURL = sourceURL
        self.assetPath = assetPath
        self.artifactsDirectory = artifactsDirectory
        self.cacheDirectory = cacheDirectory
        self.assetsByPath = assetsByPath
    }

    /// The source file's bytes.
    public func data() throws -> Data { try Data(contentsOf: sourceURL) }

    /// A reference to an object of this same file (to put in a material or prefab).
    public func reference(_ subAsset: SubAssetID?) -> AssetReference { AssetReference(assetID, subAsset: subAsset) }

    /// The id of another file in the project, by a path relative to this file's folder
    /// ("textures/rock.png", "../shared/a.png"); nil if there is no such asset.
    public func asset(atRelativePath path: String) -> AssetID? {
        var parts = assetPath.split(separator: "/").dropLast().map(String.init)
        for part in path.split(separator: "/") {
            switch part {
            case ".", "": continue
            case "..": if !parts.isEmpty { parts.removeLast() }
            default: parts.append(String(part))
            }
        }
        return assetsByPath[parts.joined(separator: "/")]
    }

    /// The bytes of another file, by a path relative to this file's folder ("model.bin",
    /// "../shared/a.bin"), recording it as a dependency: the asset is reimported when the file
    /// changes or disappears. Safe to call from closures (it doesn't mutate the context).
    public func readDependency(relativePath path: String) throws -> Data {
        let url = sourceURL.deletingLastPathComponent().appendingPathComponent(path)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            // Remember that it was missing, so adding it later reimports.
            dependencyLog.record(LibraryIndex.Dependency(path: normalizedPath(relativeTo: path), hash: "", size: -1, modified: 0))
            throw error
        }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        dependencyLog.record(LibraryIndex.Dependency(
            path: normalizedPath(relativeTo: path), hash: ContentHash.hex(data),
            size: Int64(values?.fileSize ?? data.count),
            modified: values?.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0))
        return data
    }

    /// `path` (relative to this file's folder) as a path relative to `Assets/`.
    private func normalizedPath(relativeTo path: String) -> String {
        var parts = assetPath.split(separator: "/").dropLast().map(String.init)
        for part in path.split(separator: "/") {
            switch part {
            case ".", "": continue
            case "..": if !parts.isEmpty { parts.removeLast() }
            default: parts.append(String(part))
            }
        }
        return parts.joined(separator: "/")
    }

    /// Records a problem that didn't stop the import.
    public mutating func warn(_ message: String) { warnings.append(message) }
}

/// The dependencies one import recorded (thread-safe: importers may read from closures).
final class DependencyLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String: LibraryIndex.Dependency] = [:]

    func record(_ dependency: LibraryIndex.Dependency) {
        lock.lock()
        entries[dependency.path] = dependency
        lock.unlock()
    }

    var all: [LibraryIndex.Dependency] {
        lock.lock()
        defer { lock.unlock() }
        return entries.values.sorted { $0.path < $1.path }
    }
}

/// Importers by name and file extension. `AssetDatabase` copies `standard` when it is
/// created; add importers there at startup (or to `database.importers` for one database).
public struct AssetImporterRegistry: Sendable {
    /// The importers new databases start with: the built-in ones (`OBJImporter`,
    /// `MaterialFileImporter`, `PrefabFileImporter`, `TextureImporter`, `GLTFImporter`, `AudioImporter`) plus
    /// whatever the app registers.
    @MainActor public static var standard = AssetImporterRegistry.builtIn

    /// `OBJImporter`, `MaterialFileImporter`, `PrefabFileImporter`, `TextureImporter`, `GLTFImporter` and `AudioImporter`.
    public static var builtIn: AssetImporterRegistry {
        var registry = AssetImporterRegistry()
        registry.register(OBJImporter())
        registry.register(MaterialFileImporter())
        registry.register(PrefabFileImporter())
        registry.register(TextureImporter())
        registry.register(GLTFImporter())
        registry.register(AudioImporter())
        registry.register(ProceduralTextureImporter())
        registry.register(MeshBuildImporter())
        registry.register(VFXBuildImporter())
        registry.register(SoundBuildImporter())
        registry.register(PostFXImporter())
        registry.register(DataTableImporter())
        return registry
    }

    private var byName: [String: AnyAssetImporter] = [:]
    private var byExtension: [String: String] = [:]

    public init() {}

    /// Adds `importer`, replacing one with the same name. For each of its extensions it becomes
    /// the importer new files get (the last registered wins).
    public mutating func register<I: AssetImporter>(_ importer: I) {
        let erased = AnyAssetImporter(importer)
        byName[importer.name] = erased
        for ext in importer.fileExtensions { byExtension[ext.lowercased()] = importer.name }
    }

    /// The importer named `name` (as stored in sidecars).
    public func importer(named name: String) -> AnyAssetImporter? { byName[name] }

    /// The importer for a file with this extension (case-insensitive, without the dot).
    public func importer(forExtension ext: String) -> AnyAssetImporter? {
        byExtension[ext.lowercased()].flatMap { byName[$0] }
    }

    /// Every registered importer's name, sorted.
    public var names: [String] { byName.keys.sorted() }
}

/// A type-erased `AssetImporter`, with settings as JSON.
public struct AnyAssetImporter: Sendable {
    public let name: String
    public let fileExtensions: [String]
    public let version: Int
    /// `defaultSettings` as JSON.
    public let defaultSettings: JSONValue
    private let run: @Sendable (inout ImportContext, JSONValue?) throws -> ImportedAsset
    private let normalize: @Sendable (JSONValue?) -> JSONValue

    public init<I: AssetImporter>(_ importer: I) {
        name = importer.name
        fileExtensions = importer.fileExtensions
        version = importer.version
        let defaults = (try? AssetJSON.value(importer.defaultSettings)) ?? .object([:])
        defaultSettings = defaults
        normalize = { stored in
            AssetJSON.settingsValue(I.self, stored: stored, defaults: defaults).json
        }
        run = { context, stored in
            let settings = AssetJSON.settingsValue(I.self, stored: stored, defaults: defaults).settings ?? importer.defaultSettings
            return try importer.importAsset(&context, settings: settings)
        }
    }

    /// The settings the importer would use for `stored` (a sidecar's `settings`): the stored
    /// keys over the defaults, as the importer's `Settings` type re-encodes them. Equal values
    /// mean equal imports.
    public func effectiveSettings(_ stored: JSONValue?) -> JSONValue { normalize(stored) }

    /// Runs the importer with the settings `stored` in the sidecar.
    public func importAsset(_ context: inout ImportContext, settings stored: JSONValue?) throws -> ImportedAsset {
        try run(&context, stored)
    }
}

/// JSON helpers for sidecars, settings and the Library index: sorted keys, stable output.
enum AssetJSON {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return decoder
    }

    /// Pretty, sorted, with short numeric arrays on one line and a trailing newline.
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        var bytes = SceneCoder.collapsingNumericArrays(try encoder().encode(value))
        bytes.append(UInt8(ascii: "\n"))
        return Data(bytes)
    }

    static func value<T: Encodable>(_ value: T) throws -> JSONValue {
        try decoder().decode(JSONValue.self, from: encoder().encode(value))
    }

    static func decode<T: Decodable>(_ type: T.Type, from value: JSONValue) throws -> T {
        try decoder().decode(T.self, from: encoder().encode(value))
    }

    /// One-line canonical text of a value (sorted keys), for comparing settings.
    static func canonical(_ value: JSONValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    /// `stored` over `defaults` (objects merged key by key, recursively), decoded as `I.Settings`
    /// and re-encoded. Falls back to the defaults when the result doesn't decode.
    static func settingsValue<I: AssetImporter>(_: I.Type, stored: JSONValue?, defaults: JSONValue) -> (settings: I.Settings?, json: JSONValue) {
        let merged = stored.map { merge($0, over: defaults) } ?? defaults
        guard let settings = try? decode(I.Settings.self, from: merged), let json = try? value(settings) else {
            return (try? decode(I.Settings.self, from: defaults), defaults)
        }
        return (settings, json)
    }

    static func merge(_ value: JSONValue, over base: JSONValue) -> JSONValue {
        guard case .object(let top) = value, case .object(var result) = base else { return value }
        for (key, v) in top { result[key] = result[key].map { merge(v, over: $0) } ?? v }
        return .object(result)
    }
}
