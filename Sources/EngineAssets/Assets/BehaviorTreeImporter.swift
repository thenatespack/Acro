#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

/// Imports a `.behavior` file: checks that it decodes and warns about the tree's problems
/// (`BehaviorTree.validate`). A tree makes no objects: the `BehaviorTreeRunner` system reads
/// the file through `AssetDatabase.behaviorTree(_:)`, again whenever it is reimported, so
/// edits apply to running NPCs while playing. A cooked game ships the file as written.
public struct BehaviorTreeImporter: AssetImporter {
    public init() {}

    public var name: String { "behavior" }
    public var fileExtensions: [String] { ["behavior"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let tree: BehaviorTree
        do { tree = try AssetJSON.decoder().decode(BehaviorTree.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a behavior tree: \(error)")
        }
        for issue in tree.validate() { context.warn(issue.description) }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `tree` to a new `.behavior` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createBehaviorTree(_ tree: BehaviorTree, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try tree.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// References to every `.behavior` file, sorted by path.
    public func behaviorTreeReferences() -> [AssetReference] {
        allRecords.filter { $0.importer == BehaviorTreeImporter().name }.map { AssetReference($0.id) }
    }

    /// Whether `id` is a `.behavior` file.
    public func isBehaviorTree(_ id: AssetID) -> Bool { record(id)?.importer == BehaviorTreeImporter().name }

    /// The contents of the `.behavior` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func behaviorTreeContents(of id: AssetID) -> BehaviorTree? {
        guard isBehaviorTree(id), let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(BehaviorTree.self, from: data)
    }

    /// Overwrites the `.behavior` asset `id` with `tree` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writeBehaviorTree(_ tree: BehaviorTree, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try tree.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The `.behavior` asset a runner's `tree` field names: "asset:<id>" or a path under
    /// `Assets/` (a leading `Assets/` is allowed).
    public func behaviorTreeID(for reference: String) -> AssetID? {
        guard !reference.isEmpty else { return nil }
        if reference.hasPrefix(AssetReference.scheme) {
            guard let parsed = AssetReference(reference), isBehaviorTree(parsed.asset) else { return nil }
            return parsed.asset
        }
        let path = reference.hasPrefix("Assets/") ? String(reference.dropFirst("Assets/".count)) : reference
        return id(forPath: path).flatMap { isBehaviorTree($0) ? $0 : nil }
    }

    /// The `.behavior` asset a runner names and its revision (bumped by each reimport, so a
    /// cache can tell when to read it again). In a project the file is reimported first when it
    /// changed. Cheap: no file is read when nothing changed.
    public func behaviorTreeRevision(_ reference: String) -> (id: AssetID, revision: Int)? {
        guard let id = behaviorTreeID(for: reference) else { return nil }
        if pack == nil { _ = asset(id) }  // imports it if out of date, which bumps the revision
        return (id, pack == nil ? revision(of: id) : 0)
    }

    /// The tree a runner names and the revision it was read at; nil when the reference names
    /// no readable `.behavior` file.
    public func behaviorTree(_ reference: String) -> (tree: BehaviorTree, revision: Int)? {
        guard let (id, revision) = behaviorTreeRevision(reference), let tree = behaviorTreeContents(of: id) else { return nil }
        return (tree, revision)
    }
}
