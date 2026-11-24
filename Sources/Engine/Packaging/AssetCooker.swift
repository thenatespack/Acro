#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineAudio
import EngineBackends
import EngineCore
import EngineGraphics
import EngineNet
import EnginePhysics
import EngineRendering
import EngineScene
import EngineText
import EngineUI

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
    /// Stored in the pack's manifest for the player (`AssetPackManifest.runtime`).
    public var runtime: ProjectRuntimeSettings?
    /// Store meshes quantized and compressed, and other blobs deflated where that saves enough
    /// (pack version 2, AssetPack.swift); false writes every blob as it is (version 1).
    public var compressesBlobs: Bool

    public init(scenes: [String], include: [String] = [], target: CookTarget = CookTarget(), textures: TextureCookMode = .compress,
                textureQuality: TextureCompressionQuality? = nil, packName: String? = nil, writesManifest: Bool = true,
                runtime: ProjectRuntimeSettings? = nil, compressesBlobs: Bool = true) {
        self.runtime = runtime
        self.compressesBlobs = compressesBlobs
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
    /// The same as stored in the pack (compressed: `CookOptions.compressesBlobs`).
    public var storedTextureBytes = 0
    public var storedMeshBytes = 0
    public var storedFileBytes = 0

    /// One line for logs.
    public var summary: String {
        let mb = { (bytes: Int) in String(format: "%.2f MB", Double(bytes) / 1_048_576) }
        let sizes = { (raw: Int, stored: Int) in stored > 0 && stored != raw ? "\(mb(raw)) → \(mb(stored))" : mb(raw) }
        return "\(assetCount) assets, \(scenes.count) scene\(scenes.count == 1 ? "" : "s") → \(packPath.pathLastComponent) "
            + "(\(mb(packBytes)): textures \(sizes(textureBytes, storedTextureBytes)), meshes \(sizes(meshBytes, storedMeshBytes)), "
            + "files \(sizes(fileBytes, storedFileBytes))); "
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
    /// Importers whose source files ship unchanged: audio is streamed, and builder files that
    /// game code reads as written at run time (data tables, behavior trees, UI layouts, dialogues…).
    public static let shippedAsWritten: Set<String> = ["audio", "table", "behavior", "ui", "timeline", "vscript", "dialogue"]
    /// Of those, the ones whose references are cooked along with them: `asset:<id>`s, and string
    /// values naming a file by its path under `Assets/` (see `pathReferences`): a dialogue's
    /// portraits and `uiLayout`, a timeline's sounds and effects, a layout's images…
    public static let followsReferences: Set<String> = ["timeline", "vscript", "ui", "dialogue"]
    /// Imported assets that also ship their source, which games read at run time: sprite frames
    /// and tags, tilemaps (`assets.tilemap(path:)`), path curves (`PathFollower`) and the terrain
    /// heights paths follow.
    public static let keepsSource: Set<String> = ["sprite", "tilemap", "path", "terrain"]

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
            // Components name assets by id, or by path under Assets/ (a PathFollower's `.path`, a
            // UILayoutPlayer's layout, a DialoguePlayer's dialogue and layout, a TimelinePlayer's timeline).
            queue += Self.references(in: data) + Self.pathReferences(in: data, assetsByPath: assetsByPath)
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
            concurrentPerform(iterations: sorted.count) { i in
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
        if let runtime = options.runtime, !runtime.isEmpty { manifest.runtime = runtime }
        manifest.engineVersion = EngineVersion.current
        let deflate: AssetPackFormat.Compression = options.compressesBlobs ? .deflate : .none
        for (scene, data) in sceneData {
            manifest.scenes.append(AssetPackManifest.Scene(path: scene.path, blob: writer.add(data, compression: deflate)))
        }
        // Navmeshes baked in the editor (Library/Navigation): games load them instead of baking.
        let baked = NavigationBakeCache.files(in: libraryURL.appendingPathComponent(NavigationBakeCache.libraryFolder, isDirectory: true))
        for key in baked.keys.sorted() {
            guard let data = try? Data(contentsOf: baked[key]!) else { continue }
            manifest.navigation = (manifest.navigation ?? [:]).merging([key: writer.add(data, compression: deflate)]) { $1 }
        }
        // Light probes baked in the editor (Library/Lighting): games load them instead of baking.
        let probes = LightProbeBakeCache.files(in: libraryURL.appendingPathComponent(LightProbeBakeCache.libraryFolder, isDirectory: true))
        for key in probes.keys.sorted() {
            guard let data = try? Data(contentsOf: probes[key]!) else { continue }
            manifest.lighting = (manifest.lighting ?? [:]).merging([key: writer.add(data, compression: deflate)]) { $1 }
        }
        var report = CookReport(packPath: "", manifestPath: nil, scenes: scenes.map(\.path), assetCount: cooked.count, imported: [],
                                fromLibrary: 0, fromCookCache: 0, files: 0, packBytes: 0, textureBytes: 0, meshBytes: 0, fileBytes: 0,
                                seconds: 0, warnings: [])
        // Compressing is most of the writing time: all the binary files at once, then appended in order.
        let ids = cooked.keys.sorted()
        let jobs = ids.flatMap { id in cooked[id]!.files.keys.sorted().map { (id, $0) } }
        let prepared = LockedArray<AssetPackFormat.Writer.Prepared>(count: jobs.count)
        let items = cooked
        concurrentPerform(iterations: jobs.count) { i in
            let (id, name) = jobs[i]
            let item = items[id]!
            let compression = options.compressesBlobs ? AssetPackFormat.compression(of: name, objects: item.entry.objects) : .none
            prepared.set(i, AssetPackFormat.Writer.prepare(item.files[name]!, compression: compression))
        }
        var job = 0
        for id in ids {
            var item = cooked[id]!
            for name in item.files.keys.sorted() {
                let data = item.files[name]!
                let blob = writer.add(prepared.get(job)!)
                job += 1
                item.entry.files[name] = blob
                if name.hasPrefix("texture") {
                    report.textureBytes += data.count
                    report.storedTextureBytes += Int(blob.size)
                } else {
                    report.meshBytes += data.count
                    report.storedMeshBytes += Int(blob.size)
                }
            }
            if let data = item.data {
                let blob = writer.add(data, compression: deflate)
                item.entry.data = blob
                report.fileBytes += data.count
                report.storedFileBytes += Int(blob.size)
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
        try bytes.write(to: packURL, options: .engineAtomic)
        report.packPath = packURL.path
        report.packBytes = bytes.count
        if options.writesManifest {
            let manifestURL = output.appendingPathComponent("\(name).manifest.json")
            try AssetJSON.encode(manifest).write(to: manifestURL, options: .engineAtomic)
            report.manifestPath = manifestURL.path
        }
        report.imported.sort()
        report.warnings = warnings
        report.seconds = Date().timeIntervalSince(start)
        return report
    }

    /// The `.terrain` the `.path` `source` follows, if it is in the project.
    private func pathTerrain(_ source: Source) -> AssetID? {
        guard let data = try? Data(contentsOf: source.sourceURL),
              let build = try? AssetJSON.decoder().decode(PathBuild.self, from: data), build.terrain.isOn else { return nil }
        let value = build.terrain.asset.trimmingCharacters(in: .whitespaces)
        return assetsByPath[value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value]
    }

    /// Cooks one asset: from the Library, the cook cache, or a fresh import.
    private func cook(_ source: Source) throws -> Cooked {
        var entry = AssetPackManifest.Asset(id: source.id, path: source.path, importer: source.importer?.name, settings: nil,
                                            main: nil, objects: [], files: [:], data: nil)
        // Audio, files read as written at run time, and files without an importer ship as they are.
        guard let importer = source.importer, !AssetCooker.shippedAsWritten.contains(importer.name) else {
            let data = try Data(contentsOf: source.sourceURL)
            if let importer = source.importer { entry.settings = importer.effectiveSettings(source.settings) }
            // Timelines, visual scripts and UI layouts ship the sounds, effects, prefabs, tables and images they name by "asset:<id>" or path.
            let follows = source.importer.map { AssetCooker.followsReferences.contains($0.name) } ?? false
            let references = follows ? Self.unique(Self.references(in: data) + Self.pathReferences(in: data, assetsByPath: assetsByPath))
                .filter { $0 != source.id } : []
            return Cooked(entry: entry, files: [:], data: data, origin: .file, references: references, warnings: [])
        }
        let settings = AssetCooker.shippingSettings(importer: importer, effective: importer.effectiveSettings(source.settings), options: options)
        let canonical = AssetJSON.canonical(settings)
        entry.settings = settings

        func finish(_ manifest: AssetArtifacts.Manifest, _ files: [String: Data], _ origin: Cooked.Origin, _ warnings: [String] = []) -> Cooked {
            entry.main = manifest.main
            entry.objects = manifest.objects
            let text = (try? AssetJSON.encode(manifest.objects.filter { $0.material != nil || $0.prefab != nil || $0.animationGraph != nil })) ?? Data()
            // Prefabs' components name assets by id or by path, as scenes' do.
            var references = Self.unique(Self.references(in: text) + Self.pathReferences(in: text, assetsByPath: assetsByPath))
                .filter { $0 != source.id }
            // A `.path` that follows a terrain ships it: `PathFollower` rides the same ground.
            if importer.name == "path", let terrain = pathTerrain(source), !references.contains(terrain) { references.append(terrain) }
            // Sources in `keepsSource` ship too: games read sprite frames and tags (AssetDatabase.spriteSheet),
            // tilemaps (assets.tilemap(path:)) with a `.sprite` tile set for its tag animations, and paths.
            let data = AssetCooker.keepsSource.contains(importer.name) ? try? Data(contentsOf: source.sourceURL) : nil
            if importer.name == "tilemap", let data, let map = try? AssetJSON.decoder().decode(Tilemap.self, from: data),
               case .sprite(let path) = map.tileset.source, let id = assetsByPath[TilemapImporter.normalized(path)], !references.contains(id) {
                references.append(id)
            }
            return Cooked(entry: entry, files: files, data: data, origin: origin, references: references,
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
        try AssetJSON.encode(key).write(to: keyURL, options: .engineAtomic)
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

    /// The assets that string values of the JSON `data` name by path under `Assets/` ("Audio/hit.wav",
    /// also with an "Assets/" prefix), in order. Strings that aren't a project file's path are ignored;
    /// strings holding JSON themselves (a prefab's scene data) are searched too.
    static func pathReferences(in data: Data, assetsByPath: [String: AssetID]) -> [AssetID] {
        guard !assetsByPath.isEmpty, let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else { return [] }
        var ids: [AssetID] = []
        func walk(_ value: Any) {
            switch value {
            case let text as String:
                if text.hasPrefix("{") || text.hasPrefix("["),
                   let nested = try? JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed]) {
                    return walk(nested)
                }
                guard text.contains("."), !text.hasPrefix(AssetReference.scheme) else { return }
                let path = text.hasPrefix("Assets/") ? String(text.dropFirst("Assets/".count)) : text
                if let id = assetsByPath[path] { ids.append(id) }
            case let array as [Any]: array.forEach(walk)
            case let object as [String: Any]: object.keys.sorted().forEach { walk(object[$0]!) }
            default: break
            }
        }
        walk(json)
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
