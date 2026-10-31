import Foundation

// Cooking: a project plus a target platform in, an asset pack (AssetPack.swift) out.
//
// ```swift
// let report = try AssetCooker.cook(projectAt: url, options: CookOptions(scenes: ["Scenes/Main.scene"],
//                                   target: CookTarget(platform: .linux)), to: outputFolder)
// ```
//
// 1. **What goes in:** the scenes, then every asset they reference, transitively: an
//    `asset:<id>` anywhere in a scene file or in an imported object's data (a model's prefab
//    and materials, a `.material`'s textures, a `.prefab`'s scene data, a glTF's external
//    images) pulls in that whole asset. Plus `include` (paths or ids game code loads itself,
//    e.g. sounds). A reference to an id the project doesn't have is a warning; the pack then
//    lacks it, and the game's lookup fails with `AssetPackError.unknownAsset`.
// 2. **Shipping settings:** each asset is imported with its own settings, except that texture
//    compression (texture and glTF importers) targets the pack's `TextureFamily`: by default
//    every 8-bit texture is block-compressed (BC7 / ASTC 4x4, normal maps BC5 / two-channel
//    ASTC); with `textures: .asImported` uncompressed ones stay so and only the format family
//    of compressed ones is switched. HDR images stay float. Audio and files without an importer
//    are stored as they are.
// 3. **Incremental:** an asset whose Library import is up to date with exactly the shipping
//    settings is copied from `Library/Artifacts/<id>/` without decoding. Otherwise it is imported
//    into `Library/Cooked/<family>/<id>/`, keyed by source hash, importer and version, settings and
//    the files the import read, and reused from there next time. Imports share the database's
//    encoder cache (`Library/Artifacts/<id>/cache/`), so a texture compressed once (in the
//    editor or a previous cook) is never encoded again.
// 4. **Deterministic:** assets sorted by id, files by name, JSON with sorted keys, no times or
//    paths of the machine; the encoders are deterministic. Same inputs, same bytes.
//
// `plan(database:options:)` takes what it needs from the database on the main actor;
// `CookPlan.run(to:)` does the work on any thread (the editor runs it in the background).

/// What to cook for.
public struct CookTarget: Equatable, Sendable, Codable {
    public var platform: CookPlatform
    public var textureFamily: TextureFamily

    public init(platform: CookPlatform = .current, textureFamily: TextureFamily? = nil) {
        self.platform = platform
        self.textureFamily = textureFamily ?? platform.defaultTextureFamily
    }
}

/// How textures are compressed for a pack.
public enum TextureCookMode: String, Codable, Sendable, CaseIterable {
    /// Every 8-bit texture block-compressed for the target (normal maps in two channels).
    case compress
    /// As the project imports them, with compressed ones moved to the target's family.
    case asImported
}

/// Options for `AssetCooker`.
public struct CookOptions: Equatable, Sendable, Codable {
    /// Scene files: paths relative to the project folder or to `Assets/`, or absolute. The
    /// first is the start scene.
    public var scenes: [String]
    /// More assets to cook (paths relative to `Assets/`, or ids): ones only code refers to.
    public var include: [String]
    public var target: CookTarget
    public var textures: TextureCookMode
    /// Encoder effort for every compressed texture; nil keeps each asset's own.
    public var textureQuality: TextureCompressionQuality?
    /// The pack's file name without extension; nil: the project's name.
    public var packName: String?
    /// Also write `<name>.manifest.json` (the table of contents, for people and tools).
    public var writesManifest: Bool

    public init(scenes: [String], include: [String] = [], target: CookTarget = CookTarget(), textures: TextureCookMode = .compress,
                textureQuality: TextureCompressionQuality? = nil, packName: String? = nil, writesManifest: Bool = true) {
        self.scenes = scenes
        self.include = include
        self.target = target
        self.textures = textures
        self.textureQuality = textureQuality
        self.packName = packName
        self.writesManifest = writesManifest
    }
}

/// What a cook did.
public struct CookReport: Codable, Equatable, Sendable {
    public var packPath: String
    public var manifestPath: String?
    public var scenes: [String]
    public var assetCount: Int
    /// Assets imported now (out of date everywhere).
    public var imported: [String]
    /// Assets copied from the Library's own imports.
    public var fromLibrary: Int
    /// Assets reused from earlier cooks (`Library/Cooked/`).
    public var fromCookCache: Int
    /// Assets stored as files (audio, files without an importer).
    public var files: Int
    public var packBytes: Int
    /// Bytes of textures, meshes and stored files.
    public var textureBytes: Int
    public var meshBytes: Int
    public var fileBytes: Int
    public var seconds: Double
    public var warnings: [String]

    /// One line for logs.
    public var summary: String {
        let mb = { (bytes: Int) in String(format: "%.2f MB", Double(bytes) / 1_048_576) }
        return "\(assetCount) assets, \(scenes.count) scene\(scenes.count == 1 ? "" : "s") → \((packPath as NSString).lastPathComponent) "
            + "(\(mb(packBytes)): textures \(mb(textureBytes)), meshes \(mb(meshBytes)), files \(mb(fileBytes))); "
            + "\(imported.count) imported, \(fromLibrary) from Library, \(fromCookCache) from the cook cache, "
            + String(format: "%.2f s", seconds)
    }
}

/// Errors from cooking.
public enum CookError: Error, Equatable, CustomStringConvertible {
    case noScenes
    case sceneNotFound(String)
    case unknownInclude(String)
    case importFailed(path: String, message: String)

    public var description: String {
        switch self {
        case .noScenes: "Nothing to cook: name at least one scene"
        case .sceneNotFound(let path): "No scene file at \(path)"
        case .unknownInclude(let what): "No asset '\(what)' in the project (--include takes a path relative to Assets/ or an id)"
        case .importFailed(let path, let message): "Couldn't import \(path) for the pack: \(message)"
        }
    }
}

public enum AssetCooker {
    /// Opens the project at `url`, scans it and cooks it to `output` (a folder). Blocks.
    @MainActor
    public static func cook(projectAt url: URL, options: CookOptions, to output: URL,
                            progress: (@Sendable (String) -> Void)? = nil) throws -> CookReport {
        let database = AssetDatabase(project: try Project.open(at: url))
        database.scan()
        return try plan(database: database, options: options).run(to: output, progress: progress)
    }

    /// Everything a cook needs from `database` (scan it first), to run on any thread.
    @MainActor
    public static func plan(database: AssetDatabase, options: CookOptions) throws -> CookPlan {
        let project = database.project
        guard !options.scenes.isEmpty else { throw CookError.noScenes }
        var scenes: [CookPlan.SceneFile] = []
        for scene in options.scenes {
            let candidates = scene.hasPrefix("/") ? [URL(fileURLWithPath: scene)]
                : [project.root.appendingPathComponent(scene), project.url(forAssetPath: scene)]
            guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
                throw CookError.sceneNotFound(scene)
            }
            scenes.append(CookPlan.SceneFile(url: url, path: project.assetPath(for: url) ?? url.lastPathComponent))
        }
        var include: [AssetID] = []
        for item in options.include {
            guard let id = database.id(forPath: item) ?? AssetID(item).flatMap({ database.record($0) != nil ? $0 : nil }) else {
                throw CookError.unknownInclude(item)
            }
            include.append(id)
        }
        var sources: [AssetID: CookPlan.Source] = [:]
        for record in database.allRecords {
            let importer = record.importer.flatMap(database.importers.importer(named:))
            var library: String?
            if importer != nil, let entry = database.libraryEntry(record.id), entry.error == nil, !database.needsImport(record),
               AssetArtifacts.readManifest(from: database.artifactsURL(record.id)) != nil {
                library = entry.settings
            }
            sources[record.id] = CookPlan.Source(
                id: record.id, path: record.path, sourceURL: project.url(forAssetPath: record.path), importer: importer,
                settings: record.sidecar.settings, sourceHash: record.sourceHash, librarySettings: library,
                libraryDirectory: database.artifactsURL(record.id))
        }
        return CookPlan(projectName: project.name, assetsURL: project.assetsURL, libraryURL: project.libraryURL, options: options,
                        scenes: scenes, include: include, sources: sources, assetsByPath: database.assetsByPath)
    }

    /// The settings `importer` imports with for the pack: `effective` (the asset's settings over
    /// the importer's defaults) with texture compression aimed at the target. See the notes above.
    public static func shippingSettings(importer: AnyAssetImporter, effective: JSONValue, options: CookOptions) -> JSONValue {
        guard ["texture", "gltf"].contains(importer.name), case .object(var settings) = effective,
              case .string(let raw)? = settings["compression"], let compression = TextureCompression(rawValue: raw) else { return effective }
        let family = options.target.textureFamily
        let shipped: TextureCompression
        switch compression {
        case .none: shipped = options.textures == .compress ? (family == .bc ? .bc5 : .astcRG) : .none
        // `auto` already means the target's formats on a machine of its family (and then the
        // Library's import can be reused as is).
        case .auto: shipped = TextureFamily.machine == family ? .auto : (family == .bc ? .bc5 : .astcRG)
        case .bc7, .astc: shipped = family == .bc ? .bc7 : .astc
        case .bc5, .astcRG: shipped = family == .bc ? .bc5 : .astcRG
        }
        settings["compression"] = .string(shipped.rawValue)
        if let quality = options.textureQuality, shipped != .none {
            settings["compressionQuality"] = .string(quality.rawValue)
        }
        return importer.effectiveSettings(.object(settings))
    }
}

/// A cook ready to run on any thread (`AssetCooker.plan`).
public struct CookPlan: Sendable {
    struct SceneFile: Sendable {
        var url: URL
        var path: String
    }

    struct Source: Sendable {
        var id: AssetID
        var path: String
        var sourceURL: URL
        var importer: AnyAssetImporter?
        /// The sidecar's settings.
        var settings: JSONValue?
        var sourceHash: String
        /// The settings of an up-to-date Library import (canonical JSON), if there is one.
        var librarySettings: String?
        var libraryDirectory: URL
    }

    /// The key of a cooked import in `Library/Cooked/` (`cook.json`).
    struct CacheKey: Codable, Equatable {
        var sourceHash: String
        var importer: String
        var version: Int
        var settings: String
        var dependencies: [LibraryIndex.Dependency]
    }

    let projectName: String
    let assetsURL: URL
    let libraryURL: URL
    public let options: CookOptions
    let scenes: [SceneFile]
    let include: [AssetID]
    let sources: [AssetID: Source]
    let assetsByPath: [String: AssetID]

    /// One cooked asset.
    private struct Cooked: Sendable {
        enum Origin: Sendable { case library, cookCache, imported, file }
        var entry: AssetPackManifest.Asset
        var files: [String: Data]
        var data: Data?
        var origin: Origin
        var references: [AssetID]
        var warnings: [String]
    }

    /// Cooks into `output` (created if needed): `<name>.pack` and, unless turned off,
    /// `<name>.manifest.json`. Blocks; runs on any thread.
    public func run(to output: URL, progress: (@Sendable (String) -> Void)? = nil) throws -> CookReport {
        let start = Date()
        var warnings: [String] = []
        // The scenes and what they reference.
        var sceneData: [(SceneFile, Data)] = []
        var queue: [AssetID] = include
        for scene in scenes {
            let data = try Data(contentsOf: scene.url)
            sceneData.append((scene, data))
            queue += Self.references(in: data)
        }
        // Breadth first; each level's assets cook in parallel.
        var cooked: [AssetID: Cooked] = [:]
        var seen = Set<AssetID>()
        var missing: [AssetID: [String]] = [:]
        var level = Self.unique(queue).filter { seen.insert($0).inserted }
        let referrers = scenes.map(\.path).joined(separator: ", ")
        for id in level where sources[id] == nil { missing[id, default: []].append(referrers) }
        level = level.filter { sources[$0] != nil }
        while !level.isEmpty {
            let sorted = level.sorted()
            let results = LockedArray<Result<Cooked, any Error>>(count: sorted.count)
            DispatchQueue.concurrentPerform(iterations: sorted.count) { i in
                let source = sources[sorted[i]]!
                progress?("Cooking \(source.path)")
                results.set(i, Result { try cook(source) })
            }
            var next: [AssetID] = []
            for (i, id) in sorted.enumerated() {
                let item = try results.get(i)!.get()
                cooked[id] = item
                warnings += item.warnings
                for reference in item.references where seen.insert(reference).inserted {
                    if sources[reference] == nil {
                        missing[reference, default: []].append(item.entry.path)
                    } else {
                        next.append(reference)
                    }
                }
            }
            level = next
        }
        for (id, from) in missing.sorted(by: { $0.key < $1.key }) {
            warnings.append("\(from.sorted().joined(separator: ", ")) reference\(from.count == 1 ? "s" : "") asset \(id), which isn't in the project; the pack won't have it")
        }

        // Write the pack.
        progress?("Writing the pack")
        let writer = AssetPackFormat.Writer()
        var manifest = AssetPackManifest(name: projectName, platform: options.target.platform, textureFamily: options.target.textureFamily,
                                         vertexStride: MemoryLayout<MeshVertex>.stride, scenes: [], assets: [])
        for (scene, data) in sceneData {
            manifest.scenes.append(AssetPackManifest.Scene(path: scene.path, blob: writer.add(data)))
        }
        var report = CookReport(packPath: "", manifestPath: nil, scenes: scenes.map(\.path), assetCount: cooked.count, imported: [],
                                fromLibrary: 0, fromCookCache: 0, files: 0, packBytes: 0, textureBytes: 0, meshBytes: 0, fileBytes: 0,
                                seconds: 0, warnings: [])
        for id in cooked.keys.sorted() {
            var item = cooked[id]!
            for name in item.files.keys.sorted() {
                let data = item.files[name]!
                item.entry.files[name] = writer.add(data)
                if name.hasPrefix("texture") { report.textureBytes += data.count } else { report.meshBytes += data.count }
            }
            if let data = item.data {
                item.entry.data = writer.add(data)
                report.fileBytes += data.count
            }
            manifest.assets.append(item.entry)
            switch item.origin {
            case .library: report.fromLibrary += 1
            case .cookCache: report.fromCookCache += 1
            case .imported: report.imported.append(item.entry.path)
            case .file: report.files += 1
            }
        }
        let bytes = try writer.finish(manifest)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let name = options.packName ?? projectName
        let packURL = output.appendingPathComponent("\(name).pack")
        try bytes.write(to: packURL, options: .atomic)
        report.packPath = packURL.path
        report.packBytes = bytes.count
        if options.writesManifest {
            let manifestURL = output.appendingPathComponent("\(name).manifest.json")
            try AssetJSON.encode(manifest).write(to: manifestURL, options: .atomic)
            report.manifestPath = manifestURL.path
        }
        report.imported.sort()
        report.warnings = warnings
        report.seconds = Date().timeIntervalSince(start)
        return report
    }

    /// Cooks one asset: from the Library, the cook cache, or a fresh import.
    private func cook(_ source: Source) throws -> Cooked {
        var entry = AssetPackManifest.Asset(id: source.id, path: source.path, importer: source.importer?.name, settings: nil,
                                            main: nil, objects: [], files: [:], data: nil)
        // Audio and files without an importer ship as they are.
        guard let importer = source.importer, importer.name != "audio" else {
            let data = try Data(contentsOf: source.sourceURL)
            if let importer = source.importer { entry.settings = importer.effectiveSettings(source.settings) }
            return Cooked(entry: entry, files: [:], data: data, origin: .file, references: [], warnings: [])
        }
        let settings = AssetCooker.shippingSettings(importer: importer, effective: importer.effectiveSettings(source.settings), options: options)
        let canonical = AssetJSON.canonical(settings)
        entry.settings = settings

        func finish(_ manifest: AssetArtifacts.Manifest, _ files: [String: Data], _ origin: Cooked.Origin, _ warnings: [String] = []) -> Cooked {
            entry.main = manifest.main
            entry.objects = manifest.objects
            let text = (try? AssetJSON.encode(manifest.objects.filter { $0.material != nil || $0.prefab != nil })) ?? Data()
            let references = Self.unique(Self.references(in: text)).filter { $0 != source.id }
            return Cooked(entry: entry, files: files, data: nil, origin: origin, references: references,
                          warnings: warnings.map { "\(source.path): \($0)" })
        }

        // 1. The Library's import, when it is up to date with exactly these settings.
        if source.librarySettings == canonical, let (manifest, files) = Self.readRaw(source.libraryDirectory) {
            return finish(manifest, files, .library)
        }
        // 2. An earlier cook's.
        let cacheURL = libraryURL.appendingPathComponent("Cooked", isDirectory: true)
            .appendingPathComponent(options.target.textureFamily.rawValue, isDirectory: true)
            .appendingPathComponent(source.id.description, isDirectory: true)
        let keyURL = cacheURL.appendingPathComponent("cook.json")
        if let data = FileManager.default.contents(atPath: keyURL.path), let key = try? AssetJSON.decoder().decode(CacheKey.self, from: data),
           key.sourceHash == source.sourceHash, key.importer == importer.name, key.version == importer.version, key.settings == canonical,
           !dependenciesChanged(key.dependencies), let (manifest, files) = Self.readRaw(cacheURL) {
            return finish(manifest, files, .cookCache)
        }
        // 3. Import now.
        var context = ImportContext(assetID: source.id, sourceURL: source.sourceURL, assetPath: source.path,
                                    artifactsDirectory: cacheURL.appendingPathComponent("files", isDirectory: true),
                                    cacheDirectory: source.libraryDirectory.appendingPathComponent("cache", isDirectory: true),
                                    assetsByPath: assetsByPath)
        let fm = FileManager.default
        try? fm.removeItem(at: cacheURL)
        try fm.createDirectory(at: context.artifactsDirectory, withIntermediateDirectories: true)
        let asset: ImportedAsset
        do {
            asset = try importer.importAsset(&context, settings: settings)
        } catch {
            throw CookError.importFailed(path: source.path, message: "\(error)")
        }
        let (manifest, files) = AssetArtifacts.encode(asset)
        try AssetArtifacts.write(manifest: manifest, files: files, to: cacheURL)
        let key = CacheKey(sourceHash: source.sourceHash, importer: importer.name, version: importer.version, settings: canonical,
                           dependencies: context.dependencyLog.all)
        try AssetJSON.encode(key).write(to: keyURL, options: .atomic)
        return finish(manifest, files, .imported, context.warnings)
    }

    /// Whether a file an import read changed (or appeared, or went away) since.
    private func dependenciesChanged(_ dependencies: [LibraryIndex.Dependency]) -> Bool {
        dependencies.contains { dependency in
            let url = dependency.path.split(separator: "/").reduce(assetsURL) { $0.appendingPathComponent(String($1)) }
            let hash = (try? ContentHash.hex(contentsOf: url)) ?? ""
            return hash != dependency.hash
        }
    }

    /// A folder's import manifest and its files, undecoded.
    private static func readRaw(_ directory: URL) -> (AssetArtifacts.Manifest, [String: Data])? {
        guard let manifest = AssetArtifacts.readManifest(from: directory) else { return nil }
        var files: [String: Data] = [:]
        for name in manifest.objects.compactMap(\.file) {
            guard let data = FileManager.default.contents(atPath: directory.appendingPathComponent(name).path) else { return nil }
            files[name] = data
        }
        return (manifest, files)
    }

    /// Every `asset:<32 hex digits>` in `data` (JSON text, escaped or not).
    static func references(in data: Data) -> [AssetID] {
        let scheme = Array(AssetReference.scheme.utf8)
        var ids: [AssetID] = []
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let bytes = raw.bindMemory(to: UInt8.self)
            let count = bytes.count
            var i = 0
            while i + scheme.count + 32 <= count {
                if bytes[i] == scheme[0], (0..<scheme.count).allSatisfy({ bytes[i + $0] == scheme[$0] }) {
                    let start = i + scheme.count
                    let hex = String(decoding: UnsafeBufferPointer(rebasing: bytes[start..<start + 32]), as: UTF8.self)
                    if let id = AssetID(hex) { ids.append(id) }
                    i = start
                } else {
                    i += 1
                }
            }
        }
        return ids
    }

    private static func unique(_ ids: [AssetID]) -> [AssetID] {
        var seen = Set<AssetID>()
        return ids.filter { seen.insert($0).inserted }
    }
}

/// Results written by concurrent workers, one slot each.
private final class LockedArray<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [Element?]

    init(count: Int) { items = Array(repeating: nil, count: count) }

    func set(_ index: Int, _ value: Element) { lock.withLock { items[index] = value } }
    func get(_ index: Int) -> Element? { lock.withLock { items[index] } }
}
