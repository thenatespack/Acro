import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

extension AssetDatabase {
    /// Writes `build` to a new `.path` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createPathBuild(_ build: PathBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.path` asset `id` (nil if it isn't one or can't be read). Works in a
    /// cooked pack too (the cooker keeps `.path` sources: `AssetCooker.keepsSource`).
    public func pathBuild(of id: AssetID) -> PathBuild? {
        guard record(id)?.importer == BuiltInImporterName.pathBuild, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(PathBuild.self, from: data)
    }

    /// The `.path` asset a key names: "asset:<id>" or a path under `Assets/` (a leading `Assets/` is allowed).
    public func pathBuildID(forKey key: String) -> AssetID? {
        guard let id = assetID(forTableValue: key.trimmingCharacters(in: .whitespaces)),
              record(id)?.importer == BuiltInImporterName.pathBuild else { return nil }
        return id
    }

    /// The terrain `build` follows, read from the project or a cooked pack (nil when off, missing
    /// or unreadable).
    public func pathTerrain(of build: PathBuild) -> Terrain? {
        guard build.terrain.isOn else { return nil }
        let value = build.terrain.asset.trimmingCharacters(in: .whitespaces)
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        guard let id = id(forPath: path), let data = try? fileData(of: id) else { return nil }
        return PathBuild.decodeTerrain(data)
    }

    /// The centerline samples of the `.path` asset `id`, on its terrain when it follows one.
    public func pathSamples(of id: AssetID) -> (samples: [PathSample], closed: Bool)? {
        guard let build = pathBuild(of: id) else { return nil }
        return (build.samples(on: pathTerrain(of: build)), build.wraps)
    }

    /// Overwrites the `.path` asset `id` with `build` and reimports it, so placed copies
    /// update. Returns the import's warnings and errors about it (missing terrains, assets…).
    @discardableResult
    public func writePathBuild(_ build: PathBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
