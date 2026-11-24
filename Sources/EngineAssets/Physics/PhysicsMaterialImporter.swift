// The asset side of physics materials (PhysicsMaterial.swift in EnginePhysics): the `.physmat`
// importer, the database helpers that create, read and edit them, and the loader that lets a
// `PhysicsWorld` find them by path while playing.
import Foundation
import EngineCore
import EnginePhysics
import EngineScene

extension PhysicsMaterial {
    /// The file's JSON (sorted keys, unset keys left out).
    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// The material in `data` (a `.physmat` file's contents).
    public static func decode(_ data: Data) throws -> PhysicsMaterial {
        try AssetJSON.decoder().decode(PhysicsMaterial.self, from: data)
    }

    /// Ready-made starting points for `physicsMaterial.new` (the built-ins' numbers).
    public static func preset(_ name: String) -> PhysicsMaterial? { builtIn(named: name) }
}

/// Imports `.physmat` files: checks that the JSON reads, warns about out-of-range values,
/// effects that name nothing, sounds and VFX that aren't in the project and pairs naming
/// materials that don't exist. Like `.sfx` files they produce no sub-assets; the material is
/// read when a physics world asks for it.
public struct PhysicsMaterialImporter: AssetImporter {
    public init() {}

    public var name: String { "physmat" }
    public var fileExtensions: [String] { ["physmat"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let material: PhysicsMaterial
        do { material = try PhysicsMaterial.decode(context.data()) } catch {
            throw AssetError.unreadable("not a physics material: \(error)")
        }
        for problem in material.problems() { context.warn(problem) }
        for warning in Self.referenceProblems(material, exists: { context.assetsByPath[Self.assetPath($0)] != nil }) { context.warn(warning) }
        return ImportedAsset()
    }

    /// `value` (a path, maybe with "Assets/" in front) as a path relative to `Assets/`.
    static func assetPath(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("Assets/") ? String(trimmed.dropFirst("Assets/".count)) : trimmed
    }

    /// Sounds, VFX and pair materials that `exists` (by `Assets/` path) doesn't find. "asset:"
    /// references aren't checked here.
    public static func referenceProblems(_ material: PhysicsMaterial, exists: (String) -> Bool) -> [String] {
        var found: [String] = []
        for (label, sound, vfx) in material.effectReferences {
            for (key, value) in [("sound", sound), ("vfx", vfx)] {
                guard let value, !value.isEmpty, !value.hasPrefix(AssetReference.scheme) else { continue }
                if !exists(value) { found.append("\(label).\(key): no asset '\(value)'") }
            }
        }
        for other in (material.pairs ?? [:]).keys.sorted() {
            let isFile = other.hasSuffix(".physmat")
            if isFile ? !exists(other) : PhysicsMaterial.builtIn(named: other) == nil {
                found.append("pairs.\(other): no \(isFile ? "file" : "built-in material") '\(other)' (built-ins: \(PhysicsMaterial.builtInNames.joined(separator: ", ")))")
            }
        }
        return found
    }
}

extension AssetDatabase {
    /// Writes `material` to a new `.physmat` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createPhysicsMaterial(_ material: PhysicsMaterial, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try material.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.physmat` asset `id` (nil if it isn't one or can't be read).
    public func physicsMaterial(of id: AssetID) -> PhysicsMaterial? {
        guard record(id)?.importer == PhysicsMaterialImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? PhysicsMaterial.decode(data)
    }

    /// The `.physmat` file a `PhysicsSurface` names (a path under `Assets/` or "asset:<id>").
    public func physicsMaterial(named name: String) -> PhysicsMaterial? {
        assetID(forScriptValue: name).flatMap { physicsMaterial(of: $0) }
    }

    /// Overwrites the `.physmat` asset `id` with `material` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writePhysicsMaterial(_ material: PhysicsMaterial, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try material.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// Every `.physmat` file's path, sorted.
    public var physicsMaterialPaths: [String] {
        allRecords.filter { $0.importer == PhysicsMaterialImporter().name }.map(\.path)
    }
}

extension PhysicsMaterialLibrary {
    /// Loads `.physmat` files from `assets` (as long as it exists) when a surface names one.
    public func load(from assets: @escaping () -> AssetDatabase?) {
        loader = { name in assets()?.physicsMaterial(named: name) }
    }
}
