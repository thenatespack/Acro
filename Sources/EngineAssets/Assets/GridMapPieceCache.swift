import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Keeps a grid map's reimports from running every piece's importer again (big textured glTF
/// models take seconds). A piece file's import is taken, in order, from:
///
/// 1. the map's own cache, `Library/Artifacts/<map>/cache/pieces/<piece>/`: `key.json` (the
///    importer, its version and settings, and every file the piece's import read with its hash,
///    size and mtime) next to the import's meshes, materials and prefabs (no textures: the map's
///    prefab references the piece's own textures, so it never needs their pixels);
/// 2. the asset database's import of the piece (`Library/Artifacts/<piece>/`), when the Library
///    index says it is up to date with the file, its settings and the files it read; only its
///    meshes, materials and prefabs are read;
/// 3. the piece's importer, after which (1) is written.
///
/// A cached entry counts only while every file it read is unchanged (same size and mtime, or
/// the same contents), so a changed `.bin` or texture of a model is imported again.
package final class GridMapPieceCache {
    /// `Library/Artifacts/<map>/cache/pieces/`.
    let directory: URL
    /// `Library/`.
    let library: URL
    let assetsRoot: URL
    private var index: LibraryIndex?
    private var used = Set<String>()

    /// Imports read from (1) or (2), and run (3), since the cache was made (tests read them).
    private(set) var hits = 0, databaseHits = 0, misses = 0

    struct Key: Codable {
        var importer: String
        var version: Int
        /// Canonical JSON of the effective settings.
        var settings: String
        /// The piece file itself.
        var source: LibraryIndex.Dependency
        /// Other files its import read.
        var dependencies: [LibraryIndex.Dependency]
    }

    static let keyName = "key.json"
    static let importFolder = "import"

    /// nil outside an asset database (no cache folder).
    package init?(context: ImportContext, assetsRoot: URL) {
        guard let cache = context.cacheDirectory else { return nil }
        directory = cache.appendingPathComponent("pieces", isDirectory: true)
        // cache → Artifacts/<id> → Artifacts → Library.
        library = cache.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        self.assetsRoot = assetsRoot
    }

    /// The kinds a map needs from a piece's import.
    static let keptKinds: Set<AssetKind> = [.mesh, .material, .prefab]

    /// `asset` without what a map doesn't read (textures, clips, graphs).
    static func slim(_ asset: ImportedAsset) -> ImportedAsset {
        ImportedAsset(objects: asset.objects.filter { keptKinds.contains($0.kind) }, main: asset.main)
    }

    /// The cached import of piece `id` (at `path`) when one is still valid; records the files it
    /// read in `log` (the map's dependencies).
    package func read(id: AssetID, path: String, importer: AnyAssetImporter, settings: String, log: DependencyLog) -> ImportedAsset? {
        used.insert(id.description)
        if let asset = readOwn(id: id, importer: importer, settings: settings, log: log) {
            hits += 1
            return asset
        }
        if let asset = readDatabase(id: id, path: path, importer: importer, settings: settings, log: log) {
            databaseHits += 1
            return asset
        }
        misses += 1
        return nil
    }

    private func readOwn(id: AssetID, importer: AnyAssetImporter, settings: String, log: DependencyLog) -> ImportedAsset? {
        let folder = directory.appendingPathComponent(id.description, isDirectory: true)
        guard let data = FileManager.default.contents(atPath: folder.appendingPathComponent(Self.keyName).path),
              let key = try? AssetJSON.decoder().decode(Key.self, from: data),
              key.importer == importer.name, key.version == importer.version, key.settings == settings,
              let source = current(key.source) else { return nil }
        var dependencies: [LibraryIndex.Dependency] = []
        for dependency in key.dependencies {
            guard let now = current(dependency) else { return nil }
            dependencies.append(now)
        }
        guard let asset = AssetArtifacts.read(from: folder.appendingPathComponent(Self.importFolder, isDirectory: true)) else { return nil }
        log.record(source)
        dependencies.forEach(log.record)
        return asset
    }

    private func readDatabase(id: AssetID, path: String, importer: AnyAssetImporter, settings: String, log: DependencyLog) -> ImportedAsset? {
        if index == nil { index = LibraryIndex.load(from: library.appendingPathComponent("AssetDatabase.json")) }
        guard let entry = index?.assets[id.description], entry.path == path, entry.error == nil, entry.importer == importer.name,
              entry.importerVersion == importer.version, entry.settings == settings,
              let source = current(LibraryIndex.Dependency(path: path, hash: entry.sourceHash, size: entry.size, modified: entry.modified))
        else { return nil }
        var dependencies: [LibraryIndex.Dependency] = []
        for dependency in entry.dependencies ?? [] {
            guard let now = current(dependency) else { return nil }
            dependencies.append(now)
        }
        let folder = library.appendingPathComponent("Artifacts", isDirectory: true).appendingPathComponent(id.description, isDirectory: true)
        guard var manifest = AssetArtifacts.readManifest(from: folder) else { return nil }
        manifest.objects = manifest.objects.filter { Self.keptKinds.contains($0.kind) }
        guard let asset = AssetArtifacts.decode(manifest, file: { FileManager.default.contents(atPath: folder.appendingPathComponent($0).path) })
        else { return nil }
        log.record(source)
        dependencies.forEach(log.record)
        // Keep a copy, so the map doesn't depend on the piece's artifacts staying as they are.
        write(asset, id: id, importer: importer, settings: settings, source: source, dependencies: dependencies)
        return asset
    }

    /// Stores a fresh import of piece `id`: `source` is the piece file as read, `dependencies`
    /// the other files its importer read.
    package func write(_ asset: ImportedAsset, id: AssetID, importer: AnyAssetImporter, settings: String, source: LibraryIndex.Dependency,
               dependencies: [LibraryIndex.Dependency]) {
        used.insert(id.description)
        let folder = directory.appendingPathComponent(id.description, isDirectory: true)
        let fm = FileManager.default
        try? fm.removeItem(at: folder)
        do {
            try AssetArtifacts.write(Self.slim(asset), to: folder.appendingPathComponent(Self.importFolder, isDirectory: true))
            let key = Key(importer: importer.name, version: importer.version, settings: settings, source: source, dependencies: dependencies)
            try AssetJSON.encode(key).write(to: folder.appendingPathComponent(Self.keyName), options: .engineAtomic)
        } catch {
            try? fm.removeItem(at: folder)
        }
    }

    /// Removes the entries of pieces this import didn't use.
    package func removeUnused() {
        let fm = FileManager.default
        for name in (try? fm.contentsOfDirectory(atPath: directory.path)) ?? [] where !used.contains(name) {
            try? fm.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    /// `dependency` as the file is now if its contents are unchanged (nil if it changed, appeared
    /// or disappeared). Size and mtime decide when they match; otherwise the contents are hashed.
    func current(_ dependency: LibraryIndex.Dependency) -> LibraryIndex.Dependency? {
        let url = assetsRoot.appendingPathComponent(dependency.path)
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]), let size = values.fileSize else {
            return dependency.hash.isEmpty ? dependency : nil  // missing then and now
        }
        guard !dependency.hash.isEmpty else { return nil }
        let modified = values.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
        if Int64(size) == dependency.size && modified == dependency.modified { return dependency }
        guard (try? ContentHash.hex(contentsOf: url)) == dependency.hash else { return nil }
        return LibraryIndex.Dependency(path: dependency.path, hash: dependency.hash, size: Int64(size), modified: modified)
    }
}
