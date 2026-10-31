import Foundation

// Asset handles: keys of the form `asset:<id>[#<sub-asset>]` resolve through
// `SceneRenderer.assets` and are uploaded on first use (see `SceneRenderer.assets`).

extension SceneRenderer {
    /// Resolves `key` now if it names an asset that isn't registered yet (for a mesh or a
    /// material). Returns whether it is registered afterwards.
    @discardableResult
    public func resolveAsset(_ key: String, kind: AssetKind) -> Bool {
        let registered = kind == .mesh ? prep.meshes.contains(key) : prep.materials.contains(key)
        if registered { return true }
        guard let assets, !failedAssetKeys.contains(key), let reference = AssetReference(key) else { return false }
        do {
            switch kind {
            case .mesh:
                guard let geometry = assets.mesh(reference) else { break }
                try registerMesh(geometry, key: key)
                assetKeys[key] = assets.revision(of: reference.asset)
                return true
            case .material:
                guard let material = assets.material(reference) else { break }
                try registerMaterial(material.material(texture: try assetTexture(material.texture)), key: key)
                assetKeys[key] = assets.revision(of: reference.asset)
                return true
            case .texture, .prefab:
                break
            }
        } catch {
            print("SceneRenderer: uploading \(assets.displayName(of: reference)) failed: \(error)")
        }
        failedAssetKeys.insert(key)
        return false
    }

    /// Uploads the asset keys the last gather couldn't find. Returns whether any resolved.
    func resolveMissingAssets() -> Bool {
        guard assets != nil else { return false }
        var resolved = false
        for key in prep.missingKeys where !failedAssetKeys.contains(key) && AssetReference(key) != nil {
            let hasMesh = prep.meshes.contains(key), hasMaterial = prep.materials.contains(key)
            if hasMesh && hasMaterial { continue }
            // The key may be a mesh or a material handle (or both); try whichever is missing.
            var any = false
            if !hasMesh, assets?.object(AssetReference(key)!, kind: .mesh) != nil { any = resolveAsset(key, kind: .mesh) || any }
            if !hasMaterial, assets?.object(AssetReference(key)!, kind: .material) != nil {
                any = resolveAsset(key, kind: .material) || any
            }
            if any { resolved = true } else if !hasMesh && !hasMaterial { failedAssetKeys.insert(key) }
        }
        return resolved
    }

    /// Re-uploads assets the database imported again since the last frame and retries keys
    /// that failed before.
    func syncAssets() {
        guard let assets, assets.revision != seenAssetRevision else { return }
        seenAssetRevision = assets.revision
        failedAssetKeys.removeAll()
        assetTextures = assetTextures.filter { key, entry in
            AssetReference(key).map { assets.revision(of: $0.asset) == entry.revision } ?? false
        }
        for (key, revision) in assetKeys {
            guard let reference = AssetReference(key), assets.revision(of: reference.asset) != revision else { continue }
            // Registering under the same key replaces the GPU data and keeps its id.
            if prep.meshes.contains(key), let geometry = assets.mesh(reference) { _ = try? registerMesh(geometry, key: key) }
            if prep.materials.contains(key), let material = assets.material(reference) {
                let texture = (try? assetTexture(material.texture)) ?? nil
                _ = try? registerMaterial(material.material(texture: texture), key: key)
            }
            assetKeys[key] = assets.revision(of: reference.asset)
        }
    }

    /// The GPU texture for a material's texture reference (uploaded once per revision).
    private func assetTexture(_ reference: AssetReference?) throws -> GPUTexture? {
        guard let reference, let assets else { return nil }
        let key = reference.description
        if let cached = assetTextures[key], cached.revision == assets.revision(of: reference.asset) { return cached.texture }
        guard let texture = assets.texture(reference) else {
            print("SceneRenderer: material texture \(assets.displayName(of: reference)) not found; drawing untextured")
            return nil
        }
        let gpu = try textureUploader(texture, device)
        assetTextures[key] = (gpu, assets.revision(of: reference.asset))
        return gpu
    }
}
