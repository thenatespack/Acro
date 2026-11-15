// The asset side of sound builds (SoundBuild.swift in EngineAudio): the importer and the
// database helpers that create and edit `.sfx` assets.
import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Imports `.sfx` files: checks that the JSON reads and warns about out-of-range values. Like
/// audio files they produce no sub-assets; the sound is rendered when loaded.
public struct SoundBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "sfx" }
    public var fileExtensions: [String] { ["sfx"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: SoundBuild
        do { build = try AssetJSON.decoder().decode(SoundBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a sound build: \(error)")
        }
        for problem in build.problems() { context.warn(problem) }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `build` to a new `.sfx` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createSoundBuild(_ build: SoundBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.sfx` asset `id` (nil if it isn't one or can't be read).
    public func soundBuild(of id: AssetID) -> SoundBuild? {
        guard record(id)?.importer == SoundBuildImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(SoundBuild.self, from: data)
    }

    /// Overwrites the `.sfx` asset `id` with `build` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writeSoundBuild(_ build: SoundBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }
}
