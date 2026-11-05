import Foundation

extension AssetDatabase {
    /// Writes `terrain` to a new `.terrain` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createTerrain(_ terrain: Terrain, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try terrain.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.terrain` asset `id` (nil if it isn't one or can't be read).
    public func terrain(of id: AssetID) -> Terrain? {
        guard record(id)?.importer == TerrainImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(Terrain.self, from: data)
    }

    /// Overwrites the `.terrain` asset `id` with `terrain` and reimports it, so placed copies
    /// update. Returns the import's warnings and errors about it (missing parents, textures…).
    @discardableResult
    public func writeTerrain(_ terrain: Terrain, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try terrain.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
