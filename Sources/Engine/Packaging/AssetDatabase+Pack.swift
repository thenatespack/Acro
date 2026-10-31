import Foundation

// A database mounted from a pack (`AssetDatabase(mounting:)`): what a shipping build uses.
//
// ```swift
// let assets = AssetDatabase(mounting: try AssetPack(url: packURL))
// sceneRenderer.assets = assets                 // asset: references resolve from the pack
// try world.load(try assets.pack!.scene())      // the start scene
// ```
//
// Records come from the pack's table of contents; `asset(_:)` copies an entry out of the
// mapped file on first use (no importer runs). An id the pack lacks has no record: it is
// `.missing`, `asset(_:)` returns nil and the first miss is printed with the reason;
// `loadFromPack(_:)` throws `AssetPackError.unknownAsset` instead.

extension AssetDatabase {
    /// Whether this database reads a cooked pack rather than a project.
    public var isMounted: Bool { pack != nil }

    /// The imported asset `id` from the mounted pack. Throws `AssetPackError.unknownAsset`
    /// for an id the pack lacks, `.damaged` for a bad entry.
    public func loadFromPack(_ id: AssetID) throws -> ImportedAsset {
        guard let pack else { throw AssetError.noSuchAsset("\(id): no pack is mounted") }
        if let asset = loaded[id] { return asset }
        let asset = try pack.asset(id)
        loaded[id] = asset
        revisions[id] = bumpRevision()
        return asset
    }

    /// `loadFromPack`, reporting a failure once and returning nil.
    func packAsset(_ id: AssetID) -> ImportedAsset? {
        do {
            return try loadFromPack(id)
        } catch AssetPackError.noObjects {
            return nil
        } catch {
            if packLoadFailures.insert(id).inserted { print("AssetDatabase: \(error)") }
            return nil
        }
    }
}
