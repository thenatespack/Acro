import Foundation
import EngineCore
import EngineScene

extension AssetDatabase {
    /// The `.material` asset `id` as written in its file (nil if it isn't one or can't be read).
    /// Unlike `material(_:)` (the imported object), graph textures keep the paths the author
    /// typed and the texture slots aren't filled from the graph.
    public func materialFile(of id: AssetID) -> MaterialAsset? {
        guard record(id)?.importer == MaterialFileImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(MaterialAsset.self, from: data)
    }

    /// Overwrites the `.material` asset `id` with `material` and reimports it. Returns the
    /// import's warnings and errors about it (graph problems, missing textures).
    @discardableResult
    public func writeMaterialFile(_ material: MaterialAsset, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try Self.materialFileData(material).write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The warnings compiling `material`'s graph gives in this project (texture paths resolved
    /// as the importer does), without writing anything.
    public func materialGraphWarnings(_ material: MaterialAsset) -> [String] {
        guard let graph = material.graph else { return [] }
        let resolve: (String) -> AssetReference? = { [self] text in
            let value = text.trimmingCharacters(in: .whitespaces)
            if let reference = AssetReference(value) { return reference }
            let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
            return id(forPath: path).map { AssetReference($0) }
        }
        return MaterialGraphCompiler.compile(graph, resolveTexture: resolve).warnings
    }
}
