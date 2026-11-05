import Foundation

extension AssetDatabase {
    /// Writes `build` to a new `.meshbuild` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createMeshBuild(_ build: MeshBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.meshbuild` asset `id` (nil if it isn't one or can't be read).
    public func meshBuild(of id: AssetID) -> MeshBuild? {
        guard record(id)?.importer == MeshBuildImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(MeshBuild.self, from: data)
    }

    /// Overwrites the `.meshbuild` asset `id` with `build` and reimports it, so placed copies
    /// update. Returns the import's warnings and errors about it (missing parents, textures…).
    @discardableResult
    public func writeMeshBuild(_ build: MeshBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
