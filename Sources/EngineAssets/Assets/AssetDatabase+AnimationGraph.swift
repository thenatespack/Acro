import Foundation
import EngineCore
import EngineScene

extension AssetDatabase {
    /// Writes `graph` to a new `.animgraph` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createAnimationGraph(_ graph: AnimationGraph, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try graph.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.animgraph` asset `id` (nil if it isn't one or can't be read).
    public func animationGraph(of id: AssetID) -> AnimationGraph? {
        guard record(id)?.importer == AnimationGraphImporter().name, let path = path(of: id),
              let data = try? Data(contentsOf: project.url(forAssetPath: path)) else { return nil }
        return try? AssetJSON.decoder().decode(AnimationGraph.self, from: data)
    }

    /// Overwrites the `.animgraph` asset `id` with `graph` and reimports it, so animators using
    /// it update. Returns the import's warnings and errors about it.
    @discardableResult
    public func writeAnimationGraph(_ graph: AnimationGraph, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try graph.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// Every imported animation clip as an asset-reference key, sorted by file path.
    public var animationClipKeys: [String] { references(of: .animation).map(\.description) }

    /// A clip or preview key in the form files store: an asset reference stays as it is, and a
    /// project path ("Models/fox.glb#animation/Walk", or the file alone) becomes one. Other
    /// strings (keys registered in code) are returned unchanged.
    public func normalizedAssetKey(_ key: String) -> String {
        if key.hasPrefix(AssetReference.scheme) { return key }
        let parts = key.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        guard let id = id(forPath: String(parts[0])) else { return key }
        return AssetReference(id, subAsset: parts.count > 1 && !parts[1].isEmpty ? String(parts[1]) : nil).description
    }

    /// The skeleton clips address on a model: a `.character`'s bones (in bone order), or a
    /// node-tree prefab's nodes depth first (an imported glTF model). Nil for other assets.
    public func animationSkeleton(of reference: AssetReference) -> AnimationSkeleton? {
        if let build = character(of: reference.asset) { return build.rig.animationSkeleton }
        guard let prefab = prefab(AssetReference(reference.asset)), !prefab.roots.isEmpty else { return nil }
        return AnimationSkeleton(prefab: prefab)
    }

    /// The clip `clip` names, retargeted onto `skeleton` (bones matched by name, see
    /// `AnimationClip.retargeted(to:options:)`); nil when there is no such clip. A clip that
    /// doesn't know its skeleton (made in code) comes back unchanged.
    public func retargetedAnimationClip(_ clip: AssetReference, to skeleton: AnimationSkeleton,
                                        options: AnimationRetargetOptions = AnimationRetargetOptions()) -> AnimationClip? {
        animationClip(clip)?.retargeted(to: skeleton, options: options)
    }
}
