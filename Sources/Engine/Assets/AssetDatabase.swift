import Foundation

// The asset database: which files a project's `Assets/` folder holds, their ids, and their
// imported objects.
//
// ```swift
// let project = try Project.open(at: url)
// let assets = AssetDatabase(project: project)       // importers from AssetImporterRegistry.standard
// let report = assets.refresh()                      // scan, fix sidecars, import what changed
// sceneRenderer.assets = assets                      // MeshHandle(AssetReference(...)) now draws
// ```
//
// ## Scanning (`scan()`)
//
// Walks `Assets/` (skipping hidden files and `*.meta`) and reconciles files with sidecars:
// - a file without a sidecar gets one, with a new id, its importer and default settings;
// - a sidecar whose file is gone is an orphan. If a new sidecar-less file has exactly the
//   content the orphan's asset had (the file was moved without its sidecar), the sidecar is
//   moved to it and the id kept. Otherwise the orphan is deleted (`orphanPolicy = .delete`, the
//   default) or left alone and reported (`.report`);
// - a file and sidecar moved together keep their id; the move is reported;
// - several sidecars with the same id (a file copied with its sidecar): the one at the path
//   the Library index knows keeps the id (the original), else the first path in sorted order;
//   the copies get new ids, written to their sidecars;
// - a sidecar that can't be read is reported and left untouched (the file is skipped), so a
//   merge conflict never silently loses an id.
//
// ## Importing
//
// An asset is imported again only when its source content (hash; size and mtime short-cut
// rehashing), its effective settings, its importer or that importer's `version` changed, or
// its cache is missing. Otherwise its objects load from `Library/Artifacts/<id>/` on first use.
// `refresh()` scans and imports everything out of date; `object(_:kind:)` imports or loads one
// asset on demand. Imports run through `AssetImportJob`, whose `run()` is nonisolated and
// touches no GPU, so it can move to a background thread: `importJob(for:)` on the main actor,
// `run()` anywhere, `apply(_:)` back on the main actor.
//
// ## Background loading and hot reload
//
// `request(_:priority:)` queues a background import (or a read of the Library cache) for one
// asset and `refreshAsync()` does it for everything out of date; both return at once. The jobs
// run as background jobs on the engine's `JobSystem` (`AssetLoadQueue`: a few at a time, `.high`
// requests first, never on a thread waiting for frame work); their results wait in a mailbox
// until the main actor calls `pump()` (`SceneRenderer` does every frame), which applies them,
// bumps revisions and calls `onChange`. `loadState(of:)`, `pendingLoadCount`, `loadProgress`
// and `onLoadProgress` report what is in flight; `cancelLoading(_:)` / `cancelAllLoading()` drop
// loads that are no longer wanted; `waitForAll()` blocks (pumping) until everything has been
// applied. Importers never see the main thread and the database is only touched on it. GPU
// uploads happen on the render thread (`SceneRenderer`), which builds texture mip chains on job
// workers first.
//
// `startWatching()` (or `ENGINE_HOT_RELOAD=1`) polls `Assets/` and reimports changed files in
// the background, so edits show up in a running game. An import also depends on the other files
// it read (`ImportContext.readDependency`): changing one of those reimports it too.

/// What a scan or refresh found and did.
public struct AssetScanReport: Sendable {
    /// Assets seen for the first time (new files, or files whose sidecar the index didn't know).
    public var added: [AssetID] = []
    /// Assets whose path changed (renamed or moved with their sidecar, or a sidecar re-attached).
    public var moved: [(id: AssetID, from: String, to: String)] = []
    /// Assets that are gone (their files deleted).
    public var removed: [(id: AssetID, path: String)] = []
    /// Sidecars created for files that had none (paths relative to `Assets/`).
    public var createdSidecars: [String] = []
    /// Copies whose duplicated id was replaced with a new one.
    public var reassigned: [(path: String, old: AssetID, new: AssetID)] = []
    /// Sidecars without a file: deleted (`.delete`) or just listed (`.report`).
    public var orphanedSidecars: [String] = []
    /// Assets imported (or reimported) by a `refresh`.
    public var imported: [AssetID] = []
    /// Assets whose cached import was still valid.
    public var upToDate: Int = 0
    /// Files or imports that failed, with the reason.
    public var errors: [(path: String, message: String)] = []
    public var warnings: [String] = []

    public init() {}

    /// Whether the set of assets, their paths or their imports changed.
    public var hasChanges: Bool {
        !added.isEmpty || !moved.isEmpty || !removed.isEmpty || !reassigned.isEmpty || !imported.isEmpty
    }

    /// One line for logs: "3 assets: 1 added, 2 imported".
    public var summary: String {
        var parts: [String] = []
        if !added.isEmpty { parts.append("\(added.count) added") }
        if !moved.isEmpty { parts.append("\(moved.count) moved") }
        if !removed.isEmpty { parts.append("\(removed.count) removed") }
        if !reassigned.isEmpty { parts.append("\(reassigned.count) duplicate ids replaced") }
        if !orphanedSidecars.isEmpty { parts.append("\(orphanedSidecars.count) orphaned sidecars") }
        if !imported.isEmpty { parts.append("\(imported.count) imported") }
        if upToDate > 0 { parts.append("\(upToDate) up to date") }
        if !errors.isEmpty { parts.append("\(errors.count) failed") }
        return parts.isEmpty ? "no changes" : parts.joined(separator: ", ")
    }

    mutating func merge(_ other: AssetScanReport) {
        added += other.added
        moved += other.moved
        removed += other.removed
        createdSidecars += other.createdSidecars
        reassigned += other.reassigned
        orphanedSidecars += other.orphanedSidecars
        imported += other.imported
        upToDate += other.upToDate
        errors += other.errors
        warnings += other.warnings
    }
}

/// One asset as the database knows it.
public struct AssetRecord: Sendable, Equatable {
    public var id: AssetID
    /// Path relative to `Assets/`, "/" separators.
    public var path: String
    /// The importer's name, or nil for files no importer handles.
    public var importer: String?
    /// The objects of the last successful import (empty before the first).
    public var objects: [AssetObjectInfo]
    /// Why the last import failed, if it did.
    public var importError: String?

    /// The file name without folders.
    public var fileName: String { String(path.split(separator: "/").last ?? Substring(path)) }

    // Scan state.
    var sidecar: AssetSidecar
    var sourceHash: String
    var size: Int64
    var modified: Double
}

/// What `scan` does with sidecars whose file is gone.
public enum OrphanSidecarPolicy: Sendable {
    /// Delete them (after trying to re-attach them to a moved file).
    case delete
    /// Leave them and only report them.
    case report
}

/// The asset database of one `Project`. See the notes above.
@MainActor
public final class AssetDatabase {
    public let project: Project
    /// The importers in use. Changing them doesn't reimport; call `refresh()` afterwards.
    public var importers: AssetImporterRegistry
    public var orphanPolicy: OrphanSidecarPolicy = .delete
    /// Every asset found by the last scan, by id.
    public private(set) var records: [AssetID: AssetRecord] = [:]
    /// Bumped whenever an asset is imported again, added or removed. `SceneRenderer` compares
    /// it to re-upload what changed.
    public private(set) var revision = 0
    /// Called after a scan or import changed something (the report says what).
    public var onChange: ((AssetScanReport) -> Void)?

    /// The pack this database was mounted from (`init(mounting:)`); nil for a project's.
    public let pack: AssetPack?
    /// Pack entries that failed to load (damaged), so they are reported once.
    var packLoadFailures: Set<AssetID> = []

    private var idsByPath: [String: AssetID] = [:]
    private var index: LibraryIndex
    var loaded: [AssetID: ImportedAsset] = [:]
    var revisions: [AssetID: Int] = [:]
    /// Background jobs not applied yet, with the source hash they were started for.
    private var pendingJobs: [AssetID: String] = [:]
    /// Assets that changed again while their job ran: reimported when it finishes.
    private var rerun: Set<AssetID> = []
    /// Finished jobs taken from the queue but not applied yet (`pump` stopped on its time budget).
    private var ready: [AssetImportResult] = []
    let loadQueue: AssetLoadQueue
    /// Loads cancelled while their job runs: the result is dropped when it arrives (one job per
    /// asset at a time, so a new request waits for it and keeps its result instead).
    private var cancelledJobs: Set<AssetID> = []
    /// Called by `pump()` and the cancel calls when `loadProgress` changed.
    public var onLoadProgress: ((AssetLoadProgress) -> Void)?
    /// Jobs submitted and applied since the database was last idle.
    public private(set) var loadProgress = AssetLoadProgress()
    private var watcher: FileWatcher?
    /// Whether the watcher started by `startWatching` prints what it reloaded.
    public var logsHotReloads = true

    /// Background loads run on `jobs` (the engine's shared job system by default), at most
    /// `maxConcurrentLoads` at once (default: up to 4, one fewer than its workers).
    public init(project: Project, importers: AssetImporterRegistry? = nil, jobs: JobSystem? = nil, maxConcurrentLoads: Int? = nil) {
        loadQueue = AssetLoadQueue(jobs: jobs ?? .shared, maxRunning: maxConcurrentLoads)
        self.project = project
        self.importers = importers ?? AssetImporterRegistry.standard
        pack = nil
        index = LibraryIndex.load(from: Self.indexURL(project))
        if ProcessInfo.processInfo.environment["ENGINE_HOT_RELOAD"].map({ $0 != "0" && !$0.isEmpty }) == true { startWatching() }
    }

    /// A read-only database over a cooked pack (AssetPack.swift): its assets resolve from the
    /// pack, with no importers, sources or `Library/`. Scanning, importing, settings and
    /// watching do nothing; an id the pack lacks is `.missing` (see AssetDatabase+Pack.swift).
    public init(mounting pack: AssetPack) {
        loadQueue = AssetLoadQueue()
        self.pack = pack
        project = Project(root: pack.url.deletingLastPathComponent(), settings: ProjectSettings(name: pack.manifest.name))
        importers = AssetImporterRegistry()
        index = LibraryIndex()
        for entry in pack.manifest.assets {
            records[entry.id] = AssetRecord(
                id: entry.id, path: entry.path, importer: entry.importer, objects: entry.objectInfos, importError: nil,
                sidecar: AssetSidecar(id: entry.id, importer: entry.importer, settings: nil),
                sourceHash: entry.data?.hash ?? "", size: Int64(entry.byteCount), modified: 0)
        }
        idsByPath = Dictionary(records.values.map { ($0.path, $0.id) }, uniquingKeysWith: { first, _ in first })
    }

    /// The Library index entry of `id` (what was last imported, with which settings).
    func libraryEntry(_ id: AssetID) -> LibraryIndex.Entry? { index.assets[id.description] }

    /// Every asset by path relative to `Assets/` (what `ImportContext` resolves paths with).
    var assetsByPath: [String: AssetID] { idsByPath }

    /// Opens the project at `url` and returns its database after a `refresh()`.
    public static func open(projectAt url: URL, importers: AssetImporterRegistry? = nil) throws -> (AssetDatabase, AssetScanReport) {
        let database = AssetDatabase(project: try Project.open(at: url), importers: importers)
        let report = database.refresh()
        return (database, report)
    }

    // MARK: Queries

    /// Every asset, sorted by path.
    public var allRecords: [AssetRecord] { records.values.sorted { $0.path < $1.path } }

    public func record(_ id: AssetID) -> AssetRecord? { records[id] }

    /// The id of the asset at `path` (relative to `Assets/`, "/" separators).
    public func id(forPath path: String) -> AssetID? { idsByPath[path] }

    public func path(of id: AssetID) -> String? { records[id]?.path }

    /// The revision `id` was last imported (or loaded) at; 0 if never.
    public func revision(of id: AssetID) -> Int { revisions[id] ?? 0 }

    /// References to every object of `kind`, sorted by asset path, then in import order.
    /// Assets that were never imported are imported first.
    public func references(of kind: AssetKind) -> [AssetReference] {
        allRecords.flatMap { record in
            record.objects.filter { $0.kind == kind }.map { AssetReference(record.id, subAsset: $0.id) }
        }
    }

    /// A readable name for a reference: "Models/rock.obj › Rock", or the path alone when it
    /// names the whole file or the file has a single object.
    public func displayName(of reference: AssetReference) -> String {
        guard let record = records[reference.asset] else { return "Missing asset \(reference.asset.description.prefix(8))" }
        guard let sub = reference.subAsset else { return record.path }
        guard let object = record.objects.first(where: { $0.id == sub }) else { return "\(record.path) › \(sub) (missing)" }
        return record.objects.count == 1 ? record.path : "\(record.path) › \(object.name)"
    }

    /// The imported asset `id`: from memory, else from the Library cache, else imported now.
    /// Nil if it has no importer or its import fails.
    public func asset(_ id: AssetID) -> ImportedAsset? {
        if let asset = loaded[id] { return asset }
        if pack != nil { return packAsset(id) }
        guard let record = records[id], record.importer != nil else { return nil }
        if !needsImport(record), let cached = AssetArtifacts.read(from: artifactsURL(id)) {
            loaded[id] = cached
            if revisions[id] == nil { revisions[id] = bumpRevision() }
            return cached
        }
        var report = AssetScanReport()
        importAsset(id, report: &report)
        saveIndex(&report)
        return loaded[id]
    }

    /// The object `reference` names, if it is of `kind` (see `AssetReference`).
    public func object(_ reference: AssetReference, kind: AssetKind) -> ImportedObject? {
        asset(reference.asset)?.object(reference.subAsset, kind: kind)
    }

    public func mesh(_ reference: AssetReference) -> MeshGeometry? {
        if case .mesh(let mesh)? = object(reference, kind: .mesh)?.value { return mesh }
        return nil
    }

    public func material(_ reference: AssetReference) -> MaterialAsset? {
        if case .material(let material)? = object(reference, kind: .material)?.value { return material }
        return nil
    }

    public func texture(_ reference: AssetReference) -> TextureAsset? {
        if case .texture(let texture)? = object(reference, kind: .texture)?.value { return texture }
        return nil
    }

    public func prefab(_ reference: AssetReference) -> PrefabAsset? {
        if case .prefab(let prefab)? = object(reference, kind: .prefab)?.value { return prefab }
        return nil
    }

    // MARK: Settings

    /// The asset's effective import settings (sidecar values over the importer's defaults).
    public func settings(of id: AssetID) -> JSONValue? {
        if let pack { return pack.entry(id)?.settings }
        guard let record = records[id], let importer = record.importer.flatMap(importers.importer(named:)) else { return nil }
        return importer.effectiveSettings(record.sidecar.settings)
    }

    /// The asset's settings decoded as its importer's `Settings` type.
    public func settings<S: Decodable>(of id: AssetID, as type: S.Type) -> S? {
        settings(of: id).flatMap { try? AssetJSON.decode(S.self, from: $0) }
    }

    /// Writes new import settings to the asset's sidecar and reimports it.
    public func setSettings<S: Encodable>(_ settings: S, for id: AssetID) throws {
        guard var record = records[id] else { throw AssetError.noSuchAsset(id.description) }
        if let pack { throw AssetError.unreadable("\(pack.name) is a cooked pack: its import settings can't change") }
        record.sidecar.settings = try AssetJSON.value(settings)
        try record.sidecar.write(to: AssetSidecar.url(for: project.url(forAssetPath: record.path)))
        records[id] = record
        var report = AssetScanReport()
        importAsset(id, report: &report)
        if report.hasChanges { onChange?(report) }
    }

    // MARK: Scan and import

    /// Scans, then imports every asset that is out of date (see the notes above).
    @discardableResult
    public func refresh() -> AssetScanReport {
        if pack != nil { return AssetScanReport() }
        var report = scanFiles()
        for record in allRecords where record.importer != nil {
            let cached = FileManager.default.fileExists(atPath: artifactsURL(record.id).appendingPathComponent(AssetArtifacts.manifestName).path)
            if needsImport(record) || !cached && index.assets[record.id.description]?.error == nil {
                importAsset(record.id, report: &report)
            } else {
                report.upToDate += 1
            }
        }
        saveIndex(&report)
        if report.hasChanges { onChange?(report) }
        return report
    }

    /// Scans `Assets/` and reconciles files with sidecars, without importing.
    @discardableResult
    public func scan() -> AssetScanReport {
        var report = scanFiles()
        saveIndex(&report)
        if report.hasChanges { onChange?(report) }
        return report
    }

    /// The entry point for file-change events (`FileWatcher`): rescans and reimports what
    /// changed. Scanning re-hashes only files whose size or mtime changed, so it is cheap.
    @discardableResult
    public func reimport(changed: [FileChange]) -> AssetScanReport {
        refresh()
    }

    /// Imports `id` again even if it is up to date.
    @discardableResult
    public func reimport(_ id: AssetID) -> AssetScanReport {
        var report = AssetScanReport()
        importAsset(id, report: &report)
        saveIndex(&report)
        if report.hasChanges { onChange?(report) }
        return report
    }

    /// Whether `record`'s cached import is out of date (source, settings, importer or version changed).
    func needsImport(_ record: AssetRecord) -> Bool {
        guard let importer = record.importer.flatMap(importers.importer(named:)) else { return false }
        guard let entry = index.assets[record.id.description] else { return true }
        return entry.sourceHash != record.sourceHash || entry.importer != importer.name
            || entry.importerVersion != importer.version
            || entry.settings != AssetJSON.canonical(importer.effectiveSettings(record.sidecar.settings))
            || dependenciesChanged(entry.dependencies ?? [])
    }

    /// Whether any file an import read (`ImportContext.readDependency`) differs from what it read.
    private func dependenciesChanged(_ dependencies: [LibraryIndex.Dependency]) -> Bool {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        for dependency in dependencies {
            let url = project.url(forAssetPath: dependency.path)
            guard let values = try? url.resourceValues(forKeys: keys), let size = values.fileSize else {
                if dependency.hash.isEmpty { continue }  // it was missing then and still is
                return true
            }
            if Int64(size) == dependency.size, values.contentModificationDate?.timeIntervalSinceReferenceDate == dependency.modified { continue }
            if (try? ContentHash.hex(contentsOf: url)) != dependency.hash { return true }
        }
        return false
    }

    /// Prepares the import of `id` (main actor); run it with `job.run()` on any thread and
    /// hand the result to `apply(_:)`.
    public func importJob(for id: AssetID) -> AssetImportJob? {
        guard pack == nil, let record = records[id], let importer = record.importer.flatMap(importers.importer(named:)) else { return nil }
        let directory = artifactsURL(id)
        let context = ImportContext(assetID: id, sourceURL: project.url(forAssetPath: record.path), assetPath: record.path,
                                    artifactsDirectory: directory.appendingPathComponent("files", isDirectory: true),
                                    cacheDirectory: directory.appendingPathComponent("cache", isDirectory: true),
                                    assetsByPath: idsByPath)
        return AssetImportJob(importer: importer, context: context, settings: record.sidecar.settings,
                              cacheDirectory: directory, sourceHash: record.sourceHash, cacheOnly: false)
    }

    /// Takes in a finished import: keeps its objects, updates the index and bumps the revision.
    @discardableResult
    public func apply(_ result: AssetImportResult) -> AssetScanReport {
        var report = AssetScanReport()
        record(result, into: &report)
        saveIndex(&report)
        if report.hasChanges { onChange?(report) }
        return report
    }

    private func importAsset(_ id: AssetID, report: inout AssetScanReport) {
        guard let job = importJob(for: id) else { return }
        record(job.run(), into: &report)
    }

    private func record(_ result: AssetImportResult, into report: inout AssetScanReport) {
        let id = result.id
        guard var record = records[id] else { return }
        report.warnings += result.warnings.map { "\(record.path): \($0)" }
        let importer = importers.importer(named: result.importer)
        var entry = LibraryIndex.Entry(
            path: record.path, importer: result.importer, importerVersion: importer?.version ?? 0,
            sourceHash: result.sourceHash, size: record.size, modified: record.modified,
            settings: AssetJSON.canonical(importer?.effectiveSettings(result.settings) ?? .null),
            objects: record.objects, error: nil, dependencies: result.dependencies)
        if result.fromCache, case .success(let asset) = result.outcome {
            // A cache read: the index entry is already right; just keep the objects.
            loaded[id] = asset
            record.importError = nil
            revisions[id] = bumpRevision()
            records[id] = record
            return
        }
        switch result.outcome {
        case .success(let asset):
            loaded[id] = asset
            record.objects = asset.objects.map { AssetObjectInfo(id: $0.id, name: $0.name, kind: $0.kind) }
            record.importError = nil
            entry.objects = record.objects
            revisions[id] = bumpRevision()
            report.imported.append(id)
        case .failure(let message):
            record.importError = message
            entry.error = message
            report.errors.append((record.path, message))
        }
        records[id] = record
        index.assets[id.description] = entry
    }

    func bumpRevision() -> Int {
        revision += 1
        return revision
    }

    private func saveIndex(_ report: inout AssetScanReport) {
        guard pack == nil else { return }
        do {
            try index.save(to: Self.indexURL(project))
        } catch {
            report.warnings.append("Couldn't write the Library index: \(error)")
        }
    }

    static func indexURL(_ project: Project) -> URL { project.libraryURL.appendingPathComponent("AssetDatabase.json") }

    func artifactsURL(_ id: AssetID) -> URL {
        project.libraryURL.appendingPathComponent("Artifacts", isDirectory: true).appendingPathComponent(id.description, isDirectory: true)
    }

    // MARK: Scanning

    private struct FoundFile {
        var path: String
        var url: URL
        var size: Int64
        var modified: Double
    }

    /// Lists `Assets/`: asset files and sidecars, by relative path.
    private func listAssets() -> (files: [String: FoundFile], sidecars: Set<String>) {
        var files: [String: FoundFile] = [:]
        var sidecars: Set<String> = []
        let root = project.assetsURL.standardizedFileURL.resolvingSymlinksInPath()
        let base = root.pathComponents
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys,
                                                              options: [.skipsHiddenFiles]) else { return ([:], []) }
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  !name.hasSuffix("~") else { continue }
            let components = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            guard components.count > base.count, Array(components.prefix(base.count)) == base else { continue }
            let path = components.dropFirst(base.count).joined(separator: "/")
            if name.hasSuffix("." + AssetSidecar.fileExtension) {
                sidecars.insert(path)
            } else {
                files[path] = FoundFile(path: path, url: url, size: Int64(values.fileSize ?? 0),
                                        modified: values.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0)
            }
        }
        return (files, sidecars)
    }

    private func scanFiles() -> AssetScanReport {
        var report = AssetScanReport()
        guard pack == nil else { return report }  // a pack's records are fixed
        let (files, sidecarPaths) = listAssets()
        let suffix = "." + AssetSidecar.fileExtension

        // Read the sidecars of existing files; collect orphans.
        var sidecars: [String: AssetSidecar] = [:]
        var orphans: [(path: String, sidecar: AssetSidecar?)] = []
        var unreadable: Set<String> = []
        for sidecarPath in sidecarPaths.sorted() {
            let filePath = String(sidecarPath.dropLast(suffix.count))
            let url = project.url(forAssetPath: sidecarPath)
            if files[filePath] == nil {
                orphans.append((sidecarPath, try? AssetSidecar.read(from: url)))
                continue
            }
            do {
                sidecars[filePath] = try AssetSidecar.read(from: url)
            } catch {
                unreadable.insert(filePath)
                report.errors.append((sidecarPath, "\(error)"))
            }
        }

        // Hash every file (reusing the stored hash when size and mtime match).
        var hashes: [String: String] = [:]
        func hash(_ file: FoundFile, knownAs id: AssetID?) -> String {
            if let h = hashes[file.path] { return h }
            var h: String
            if let id, let entry = index.assets[id.description], entry.size == file.size, entry.modified == file.modified {
                h = entry.sourceHash
            } else if let id, let record = records[id], record.path == file.path, record.size == file.size, record.modified == file.modified {
                h = record.sourceHash
            } else {
                h = (try? ContentHash.hex(contentsOf: file.url)) ?? ""
            }
            hashes[file.path] = h
            return h
        }

        // Orphans: re-attach to a sidecar-less file with the same content, else delete or report.
        let sidecarless = files.keys.filter { sidecars[$0] == nil && !unreadable.contains($0) }.sorted()
        var byHash: [String: [String]] = [:]
        if !orphans.isEmpty {
            for path in sidecarless { byHash[hash(files[path]!, knownAs: nil), default: []].append(path) }
        }
        for orphan in orphans {
            let url = project.url(forAssetPath: orphan.path)
            if let sidecar = orphan.sidecar, let entry = index.assets[sidecar.id.description],
               let candidates = byHash[entry.sourceHash], candidates.count == 1, sidecars[candidates[0]] == nil {
                let target = candidates[0]
                do {
                    try FileManager.default.moveItem(at: url, to: AssetSidecar.url(for: project.url(forAssetPath: target)))
                    sidecars[target] = sidecar
                    byHash[entry.sourceHash] = nil
                    continue
                } catch {
                    report.errors.append((orphan.path, "Couldn't move the sidecar to \(target): \(error)"))
                }
            }
            report.orphanedSidecars.append(orphan.path)
            if orphanPolicy == .delete { try? FileManager.default.removeItem(at: url) }
        }

        // Duplicate ids: the path the index knows keeps the id, else the first path.
        var pathsByID: [AssetID: [String]] = [:]
        for (path, sidecar) in sidecars { pathsByID[sidecar.id, default: []].append(path) }
        for (id, paths) in pathsByID where paths.count > 1 {
            let known = index.assets[id.description]?.path ?? records[id]?.path
            let keeper = paths.contains(where: { $0 == known }) ? known! : paths.sorted()[0]
            for path in paths.sorted() where path != keeper {
                var sidecar = sidecars[path]!
                let old = sidecar.id
                sidecar.id = freshID(avoiding: pathsByID)
                do {
                    try sidecar.write(to: AssetSidecar.url(for: project.url(forAssetPath: path)))
                    sidecars[path] = sidecar
                    report.reassigned.append((path, old, sidecar.id))
                } catch {
                    sidecars[path] = nil
                    report.errors.append((path, "Couldn't write a new id to its sidecar: \(error)"))
                }
            }
        }

        // New files: create sidecars.
        let taken = Set(sidecars.values.map(\.id))
        for path in files.keys.sorted() where sidecars[path] == nil && !unreadable.contains(path) {
            let ext = (path as NSString).pathExtension
            let importer = importers.importer(forExtension: ext)
            var id = AssetID.random()
            while taken.contains(id) || records[id] != nil { id = .random() }
            let sidecar = AssetSidecar(id: id, importer: importer?.name, settings: importer?.defaultSettings)
            do {
                try sidecar.write(to: AssetSidecar.url(for: files[path]!.url))
                sidecars[path] = sidecar
                report.createdSidecars.append(path)
            } catch {
                report.errors.append((path, "Couldn't write its sidecar: \(error)"))
            }
        }

        // Rebuild the records; diff against the previous scan and the index.
        var newRecords: [AssetID: AssetRecord] = [:]
        for (path, sidecar) in sidecars {
            let file = files[path]!
            let id = sidecar.id
            let previous = records[id]
            let entry = index.assets[id.description]
            let ext = (path as NSString).pathExtension
            let importer = sidecar.importer.flatMap(importers.importer(named:)) ?? importers.importer(forExtension: ext)
            let objects = previous?.objects ?? (entry?.importer == importer?.name ? entry?.objects : nil) ?? []
            newRecords[id] = AssetRecord(
                id: id, path: path, importer: importer?.name, objects: objects,
                importError: previous?.importError ?? entry?.error, sidecar: sidecar,
                sourceHash: hash(file, knownAs: id), size: file.size, modified: file.modified)
            if let oldPath = previous?.path ?? entry?.path {
                if oldPath != path { report.moved.append((id, oldPath, path)) }
            } else {
                report.added.append(id)
            }
        }
        var gone = Set(records.keys).union(index.assets.keys.compactMap(AssetID.init))
        gone.subtract(newRecords.keys)
        for id in gone.sorted() {
            let path = records[id]?.path ?? index.assets[id.description]?.path ?? ""
            report.removed.append((id, path))
            index.assets[id.description] = nil
            loaded[id] = nil
            revisions[id] = bumpRevision()
            try? FileManager.default.removeItem(at: artifactsURL(id))
        }
        for (id, record) in newRecords {
            let key = id.description
            guard var entry = index.assets[key], entry.importer != nil else {
                // Files without an importer are tracked too (by path and content), so their
                // ids are known next session; no import state to protect.
                index.assets[key] = LibraryIndex.Entry(
                    path: record.path, importer: nil, importerVersion: 0, sourceHash: record.sourceHash, size: record.size,
                    modified: record.modified, settings: "", objects: [], error: nil)
                continue
            }
            // Keep the path current (so a later duplicate is told from the original), and the
            // size and mtime when the content is what was imported (so it isn't rehashed again).
            entry.path = record.path
            if entry.sourceHash == record.sourceHash {
                entry.size = record.size
                entry.modified = record.modified
            }
            index.assets[key] = entry
        }
        records = newRecords
        idsByPath = Dictionary(uniqueKeysWithValues: newRecords.values.map { ($0.path, $0.id) })
        report.added.sort()
        report.moved.sort { $0.to < $1.to }
        return report
    }

    private func freshID(avoiding used: [AssetID: [String]]) -> AssetID {
        var id = AssetID.random()
        while used[id] != nil || records[id] != nil || index.assets[id.description] != nil { id = .random() }
        return id
    }
}

// MARK: Background loading and hot reload

extension AssetDatabase {
    /// Where `id` is in loading. Doesn't start anything (`request(_:)` does).
    public func loadState(of id: AssetID) -> AssetLoadState {
        guard let record = records[id] else { return .missing }
        if loaded[id] != nil { return .loaded }
        if pack != nil { return packLoadFailures.contains(id) ? .failed : .unloaded }
        if pendingJobs[id] != nil && !cancelledJobs.contains(id) { return .loading }
        if record.importer == nil { return .failed }
        if record.importError != nil && !needsImport(record) { return .failed }
        return .unloaded
    }

    /// Starts importing (or reading the cache of) `id` in the background unless it is loaded or
    /// already loading; `.high` puts it ahead of the `.normal` loads that haven't started (also
    /// when it is already waiting). Returns its state afterwards.
    @discardableResult
    public func request(_ id: AssetID, priority: AssetLoadPriority = .normal) -> AssetLoadState {
        let state = loadState(of: id)
        if pack != nil, state == .unloaded {
            // Reading a pack entry is a copy out of the mapped file: done at once.
            _ = packAsset(id)
            return loadState(of: id)
        }
        if state == .loading, priority == .high { loadQueue.prioritize(id) }
        guard state == .unloaded, let record = records[id] else { return state }
        submit(id, cacheOnly: !needsImport(record), priority: priority)
        return .loading
    }

    /// Stops loading `id`: a load that hasn't started is dropped, one that is running finishes
    /// on its worker and its result is discarded. Its state goes back to `.unloaded` (a later
    /// `request` starts it again) and it counts as completed (and cancelled) in `loadProgress`.
    /// Returns whether it was loading.
    @discardableResult
    public func cancelLoading(_ id: AssetID) -> Bool {
        guard pendingJobs[id] != nil, !cancelledJobs.contains(id) else { return false }
        if loadQueue.cancel(id) {
            pendingJobs[id] = nil
        } else {
            cancelledJobs.insert(id)
        }
        rerun.remove(id)
        loadProgress.completed += 1
        loadProgress.cancelled += 1
        onLoadProgress?(loadProgress)
        return true
    }

    /// `cancelLoading` for every load in flight (e.g. when leaving a level). Returns how many.
    @discardableResult
    public func cancelAllLoading() -> Int {
        pendingJobs.keys.sorted { $0.description < $1.description }.reduce(0) { $0 + (cancelLoading($1) ? 1 : 0) }
    }

    /// Jobs queued, running or waiting for `pump()`.
    public var pendingLoadCount: Int { loadProgress.pending }

    /// Whether any background job hasn't been applied yet.
    public var isLoading: Bool { loadProgress.pending > 0 }

    /// Applies finished background jobs on the main actor: keeps their objects, updates the
    /// index, bumps revisions and calls `onChange` once with everything that changed. Stops
    /// taking more once `timeBudget` seconds have passed (at least one is applied per call).
    @discardableResult
    public func pump(timeBudget: Double = 0.004) -> AssetScanReport {
        var report = AssetScanReport()
        if let changes = watcher?.takeChanges(), !changes.isEmpty {
            let scan = reimportAsync(changed: changes)
            if logsHotReloads { print("AssetDatabase: \(changes.count) file change(s) in \(project.name): \(scan.summary)") }
        }
        ready += loadQueue.takeFinished()
        guard !ready.isEmpty else { return report }
        let start = DispatchTime.now().uptimeNanoseconds
        var applied = 0
        while applied < ready.count {
            if applied > 0, Double(DispatchTime.now().uptimeNanoseconds - start) / 1e9 > timeBudget { break }
            let result = ready[applied]
            applied += 1
            let id = result.id
            pendingJobs[id] = nil
            if cancelledJobs.remove(id) != nil { continue }  // counted when it was cancelled
            loadProgress.completed += 1
            guard let record = records[id] else { rerun.remove(id); continue }  // deleted meanwhile
            if rerun.remove(id) != nil || record.sourceHash != result.sourceHash {
                submit(id, cacheOnly: false)  // changed again while it ran: this result is stale
                continue
            }
            self.record(result, into: &report)
        }
        ready.removeFirst(applied)
        onLoadProgress?(loadProgress)
        if loadProgress.pending == 0 { loadProgress = AssetLoadProgress() }
        saveIndex(&report)
        if report.hasChanges {
            if logsHotReloads && watcher != nil {
                for path in report.imported.compactMap({ records[$0]?.path }) { print("AssetDatabase: reloaded \(path)") }
                for (path, message) in report.errors { print("AssetDatabase: \(path): \(message)") }
            }
            onChange?(report)
        }
        return report
    }

    /// Blocks the calling (main) thread, applying results as they arrive, until no background
    /// job is left or `timeout` seconds pass. Returns whether everything finished. For tests,
    /// screenshots and tools that need fully loaded assets.
    @discardableResult
    public func waitForAll(timeout: TimeInterval = 300) -> Bool {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while true {
            pump(timeBudget: .infinity)
            if loadProgress.pending == 0 { return true }
            if Date() >= deadline { return false }
            loadQueue.waitForFinished(timeout: 0.05)
        }
    }

    /// `refresh()` without waiting for the imports: scans now (hashing only files whose size or
    /// mtime changed) and queues background jobs for everything out of date. The returned
    /// report has the scan's results; imports show up in `onChange` reports as `pump()` applies
    /// them. Use `waitForAll()` to block until they are done.
    @discardableResult
    public func refreshAsync() -> AssetScanReport {
        if pack != nil { return AssetScanReport() }
        var report = scanFiles()
        for record in allRecords where record.importer != nil {
            if pendingJobs[record.id] == record.sourceHash && !cancelledJobs.contains(record.id) { continue }
            let cached = FileManager.default.fileExists(atPath: artifactsURL(record.id).appendingPathComponent(AssetArtifacts.manifestName).path)
            if needsImport(record) || !cached && index.assets[record.id.description]?.error == nil {
                submit(record.id, cacheOnly: false)
            } else {
                report.upToDate += 1
            }
        }
        saveIndex(&report)
        if report.hasChanges { onChange?(report) }
        return report
    }

    /// The file-change entry point for background reloading (`FileWatcher`): like `refreshAsync()`.
    @discardableResult
    public func reimportAsync(changed: [FileChange]) -> AssetScanReport { refreshAsync() }

    /// Whether `startWatching` is active.
    public var isWatching: Bool { watcher != nil }

    /// Hot reload: polls `Assets/` in the background (every `interval` seconds, stretched when
    /// a poll is slow) and reimports changed files, their dependents and new files in the
    /// background. The changes and the results are picked up by `pump()`, which `SceneRenderer`
    /// calls every frame (call it yourself when no renderer uses the database). Also started
    /// by `ENGINE_HOT_RELOAD=1`.
    public func startWatching(interval: Double = 0.5) {
        guard watcher == nil, pack == nil else { return }
        let watcher = FileWatcher(directory: project.assetsURL)
        watcher.startCollecting(interval: interval)  // `pump()` collects the changes
        self.watcher = watcher
    }

    public func stopWatching() {
        watcher?.stop()
        watcher = nil
    }

    private func submit(_ id: AssetID, cacheOnly: Bool, priority: AssetLoadPriority = .normal) {
        if let running = pendingJobs[id] {
            // One job per asset at a time: they share its cache folder.
            if cancelledJobs.remove(id) != nil {
                // Wanted again while its cancelled job still runs: keep that job's result.
                if loadProgress.pending == 0 { loadProgress = AssetLoadProgress() }
                loadProgress.total += 1
                if running != records[id]?.sourceHash { rerun.insert(id) }
            } else {
                rerun.insert(id)
            }
            return
        }
        guard var job = importJob(for: id) else { return }
        job.cacheOnly = cacheOnly
        if loadProgress.pending == 0 { loadProgress = AssetLoadProgress() }
        loadProgress.total += 1
        pendingJobs[id] = job.sourceHash
        loadQueue.submit(job, priority: priority)
    }
}

/// One import, ready to run on any thread (`AssetDatabase.importJob(for:)`).
public struct AssetImportJob: Sendable {
    public let importer: AnyAssetImporter
    public var context: ImportContext
    /// The sidecar's settings.
    public let settings: JSONValue?
    let cacheDirectory: URL
    let sourceHash: String
    /// Read the Library cache instead of importing, when it is valid.
    var cacheOnly: Bool

    /// Runs the importer and writes the result to the Library cache. Nonisolated and GPU-free.
    public func run() -> AssetImportResult {
        if cacheOnly, let cached = AssetArtifacts.read(from: cacheDirectory) {
            return AssetImportResult(id: context.assetID, importer: importer.name, settings: settings, sourceHash: sourceHash,
                                     outcome: .success(cached), warnings: [], dependencies: nil, fromCache: true)
        }
        var context = self.context
        let fm = FileManager.default
        let outcome: AssetImportResult.Outcome
        do {
            try? fm.removeItem(at: context.artifactsDirectory)
            try fm.createDirectory(at: context.artifactsDirectory, withIntermediateDirectories: true)
            let asset = try importer.importAsset(&context, settings: settings)
            // Replace the previous cache only now: a failed import keeps it.
            let keep = [context.artifactsDirectory.lastPathComponent, context.cacheDirectory?.lastPathComponent]
            for name in (try? fm.contentsOfDirectory(atPath: cacheDirectory.path)) ?? [] where !keep.contains(name) {
                try? fm.removeItem(at: cacheDirectory.appendingPathComponent(name))
            }
            try AssetArtifacts.write(asset, to: cacheDirectory)
            outcome = .success(asset)
        } catch {
            outcome = .failure("\(error)")
        }
        return AssetImportResult(id: context.assetID, importer: importer.name, settings: settings, sourceHash: sourceHash,
                                 outcome: outcome, warnings: context.warnings, dependencies: context.dependencyLog.all,
                                 fromCache: false)
    }
}

/// The outcome of an `AssetImportJob`, to hand to `AssetDatabase.apply(_:)`.
public struct AssetImportResult: Sendable {
    public enum Outcome: Sendable {
        case success(ImportedAsset)
        case failure(String)
    }

    public let id: AssetID
    let importer: String
    let settings: JSONValue?
    let sourceHash: String
    public let outcome: Outcome
    public let warnings: [String]
    let dependencies: [LibraryIndex.Dependency]?
    /// The objects came from the Library cache (nothing was imported).
    let fromCache: Bool
}
