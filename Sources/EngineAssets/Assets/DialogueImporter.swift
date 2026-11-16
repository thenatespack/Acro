import Foundation
import EngineCore
import EngineScene

/// Imports a `.dialogue` file: checks that it decodes and warns about problems (missing nodes,
/// unknown speakers or variables, bad conditions, unreachable nodes, missing portraits). A
/// dialogue has no objects; game code plays it with a `DialoguePlayer` component or a
/// `DialogueRunner`, which read the file again whenever it is reimported (hot reload). A
/// cooked game keeps the file as it is.
public struct DialogueImporter: AssetImporter {
    public init() {}

    public var name: String { "dialogue" }
    public var fileExtensions: [String] { ["dialogue"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let dialogue: DialogueAsset
        do { dialogue = try DialogueAsset.decode(context.data()) } catch {
            throw AssetError.unreadable("not a dialogue: \(DialogueAsset.describe(error))")
        }
        let paths = context.assetsByPath
        for issue in dialogue.validate(assetExists: { DataTableImporter.exists($0, in: paths) }) {
            context.warn(issue.description)
        }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `dialogue` to a new `.dialogue` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createDialogue(_ dialogue: DialogueAsset, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try dialogue.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// Whether `id` is a `.dialogue` file.
    public func isDialogue(_ id: AssetID) -> Bool { record(id)?.importer == DialogueImporter().name }

    /// The contents of the `.dialogue` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func dialogueContents(of id: AssetID) -> DialogueAsset? {
        guard isDialogue(id), let data = try? fileData(of: id) else { return nil }
        return try? DialogueAsset.decode(data)
    }

    /// The dialogue at `path` (relative to `Assets/`, a leading `Assets/` is allowed) or "asset:<id>".
    public func dialogue(path: String) -> DialogueAsset? {
        assetID(forTableValue: path).flatMap { dialogueContents(of: $0) }
    }

    /// Overwrites the `.dialogue` asset `id` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writeDialogue(_ dialogue: DialogueAsset, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try dialogue.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// Problems with `dialogue`, with portraits checked against the project.
    public func dialogueIssues(_ dialogue: DialogueAsset) -> [DialogueIssue] {
        dialogue.validate(assetExists: { [unowned self] in assetID(forTableValue: $0) != nil })
    }
}
