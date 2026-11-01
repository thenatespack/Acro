import Foundation

extension AssetDatabase {
    /// Writes `texture` to a new `.proctex` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createProceduralTexture(_ texture: ProceduralTexture, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try texture.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The parameters stored in the `.proctex` asset `id` (nil if it isn't one or can't be read).
    public func proceduralTexture(of id: AssetID) -> ProceduralTexture? {
        guard record(id)?.importer == ProceduralTextureImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(ProceduralTexture.self, from: data)
    }

    /// Overwrites the `.proctex` asset `id` with `texture` and reimports it, so materials using it
    /// pick up the change on their next frame.
    public func writeProceduralTexture(_ texture: ProceduralTexture, to id: AssetID) throws {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try texture.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        refresh()
    }
}
