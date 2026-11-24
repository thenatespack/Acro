#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

extension AssetDatabase {
    /// Writes `build` to a new `.groom` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createGroom(_ build: GroomBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.groom` asset `id` (nil if it isn't one or can't be read).
    public func groom(of id: AssetID) -> GroomBuild? {
        guard record(id)?.importer == BuiltInImporterName.groom, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(GroomBuild.self, from: data)
    }

    /// Overwrites the `.groom` asset `id` and reimports it, so fur using it updates. Returns the import's warnings.
    @discardableResult
    public func writeGroom(_ build: GroomBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The `.groom` asset `value` names: a path under `Assets/` (with or without the prefix) or "asset:<id>[#…]".
    public func groomID(_ value: String) -> AssetID? {
        let value = value.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return record(reference.asset)?.importer == BuiltInImporterName.groom ? reference.asset : nil
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        guard let id = id(forPath: path), record(id)?.importer == BuiltInImporterName.groom else { return nil }
        return id
    }
}
