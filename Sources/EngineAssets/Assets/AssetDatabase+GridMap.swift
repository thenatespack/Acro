import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

extension AssetDatabase {
    /// Writes `gridMap` to a new `.gridmap` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createGridMap(_ gridMap: GridMap, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try gridMap.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.gridmap` asset `id` (nil if it isn't one or can't be read).
    public func gridMap(of id: AssetID) -> GridMap? {
        guard record(id)?.importer == BuiltInImporterName.gridMap, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(GridMap.self, from: data)
    }

    /// Overwrites the `.gridmap` asset `id` with `gridMap` and reimports it, so placed copies
    /// update. Returns the import's warnings and errors about it (missing parents, pieces…).
    @discardableResult
    public func writeGridMap(_ gridMap: GridMap, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try gridMap.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
