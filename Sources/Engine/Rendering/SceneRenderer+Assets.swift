import Foundation

// Asset handles: keys of the form `asset:<id>[#<sub-asset>]` resolve through
// `SceneRenderer.assets` and are uploaded on first use (see `SceneRenderer.assets`).
//
// Loading is asynchronous. The first frame an entity uses an asset, the database is asked to
// import it in the background (`AssetDatabase.request`); until it is ready:
// - an entity whose mesh is still loading is skipped;
// - an entity whose material is still loading (or whose texture is) draws with a neutral gray
//   placeholder material, replaced when the real one is ready.
// Finished imports are applied in `syncAssets` (`AssetDatabase.pump`) and uploaded under the
// per-frame `assetUploadBudget`. A texture's mip chain (or an HDR image's half floats) is built
// by a background job first (`PreparedTextureLevels`), so the frame only makes the GPU texture,
// which doesn't wait for the GPU on either backend. With `blocksOnAssetLoading` (the default under
// `ENGINE_SCREENSHOT`) the frame waits for the imports and uploads everything, so nothing
// placeholder-ish is ever drawn.
//
// Every registered asset key remembers a "signature" of what it was uploaded from: the asset's
// revision, and for a material the revisions of all its textures (base color, metallic-roughness,
// normal, occlusion, emissive; -1 for one that isn't uploaded yet). `syncAssets` re-uploads keys whose desired signature differs, which is how reimports,
// finished loads and texture changes reach the viewport. An asset that was deleted releases
// its mesh (nothing is drawn) or turns its material into the placeholder, and is reported.

extension SceneRenderer {
    private static let loadingSignature = -2
    private static let vanishedSignature = -3

    /// A neutral gray stand-in for materials that aren't ready.
    private static var placeholderMaterial: Material { Material(baseColor: Vec4(0.5, 0.5, 0.5, 1)) }

    /// Resolves `key` now if it names an asset that isn't registered yet (for a mesh or a
    /// material). Returns whether it is registered afterwards. A mesh that is still loading
    /// returns false and is picked up by a later frame; a loading material registers the placeholder.
    @discardableResult
    public func resolveAsset(_ key: String, kind: AssetKind) -> Bool {
        resolveAsset(key, kind: kind, ignoringBudget: false)
    }

    @discardableResult
    func resolveAsset(_ key: String, kind: AssetKind, ignoringBudget: Bool) -> Bool {
        let registered = kind == .mesh ? prep.meshes.contains(key) : prep.materials.contains(key)
        if registered { return true }
        guard let assets, !failedAssetKeys.contains(key), let reference = AssetReference(key) else { return false }
        do {
            switch kind {
            case .mesh:
                switch awaitAsset(reference.asset) {
                case .loaded: break
                case .loading, .unloaded:
                    assetsNeedRetry = true
                    return false
                case .failed, .missing:
                    failedAssetKeys.insert(key)
                    return false
                }
                guard let geometry = assets.mesh(reference) else { break }
                guard reserveUpload(Self.byteCount(geometry), ignoringBudget) else { return false }
                try registerMesh(geometry, key: key)
                assetKeys[key] = assets.revision(of: reference.asset)
                return true
            case .material:
                switch awaitAsset(reference.asset) {
                case .loaded: break
                case .loading, .unloaded:
                    try registerMaterial(Self.placeholderMaterial, key: key)
                    assetKeys[key] = Self.loadingSignature
                    assetsNeedRetry = true
                    return true
                case .failed, .missing:
                    failedAssetKeys.insert(key)
                    return false
                }
                guard let material = assets.material(reference) else { break }
                let (resolved, signature) = try materialTextures(material, reference: reference, ignoringBudget: ignoringBudget)
                try registerMaterial(resolved, key: key)
                assetKeys[key] = signature
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

    /// Uploads the asset keys the last gather couldn't find (meshes first-use, materials as the
    /// placeholder while loading). Returns whether any resolved.
    func resolveMissingAssets() -> Bool {
        guard assets != nil else { return false }
        var resolved = false
        for key in prep.missingMeshKeys where !prep.meshes.contains(key) && !failedAssetKeys.contains(key) && AssetReference(key) != nil {
            if resolveAsset(key, kind: .mesh) { resolved = true }
        }
        for key in prep.missingMaterialKeys where !prep.materials.contains(key) && !failedAssetKeys.contains(key) && AssetReference(key) != nil {
            if resolveAsset(key, kind: .material) { resolved = true }
        }
        return resolved
    }

    /// Applies finished background imports, re-uploads assets whose data changed (reimported,
    /// finished loading, or a texture of a material changed), releases deleted ones and retries
    /// keys that failed before or were deferred by the upload budget. Called once per `gather`.
    func syncAssets() {
        guard let assets else { return }
        assets.pump()
        assetUploadedBytes = 0
        let revisionChanged = assets.revision != seenAssetRevision
        guard revisionChanged || assetsNeedRetry else { return }
        seenAssetRevision = assets.revision
        assetsNeedRetry = false
        if revisionChanged {
            failedAssetKeys.removeAll()
            assetTextures = assetTextures.filter { key, entry in
                AssetReference(key).map { assets.revision(of: $0.asset) == entry.revision } ?? false
            }
            preparingTextures = preparingTextures.filter { key, entry in
                AssetReference(key).map { assets.revision(of: $0.asset) == entry.revision } ?? false
            }
        }
        for (key, signature) in assetKeys {
            guard let reference = AssetReference(key) else { continue }
            let isMesh = prep.meshes.contains(key), isMaterial = prep.materials.contains(key)
            guard isMesh || isMaterial else {
                assetKeys[key] = nil
                continue
            }
            let vanished = assets.record(reference.asset) == nil
            if vanished {
                if signature != Self.vanishedSignature { reportVanished(key, isMesh: isMesh) }
                continue
            }
            guard assets.loadState(of: reference.asset) == .loaded else { continue }
            if isMesh {
                guard signature != assets.revision(of: reference.asset), let geometry = assets.mesh(reference) else { continue }
                guard reserveUpload(Self.byteCount(geometry), false) else { continue }
                // Registering under the same key replaces the GPU data and keeps its id.
                _ = try? registerMesh(geometry, key: key)
                assetKeys[key] = assets.revision(of: reference.asset)
            } else if let material = assets.material(reference), signature != desiredSignature(of: material, reference: reference) {
                guard let (resolved, actual) = try? materialTextures(material, reference: reference, ignoringBudget: false) else { continue }
                _ = try? registerMaterial(resolved, key: key)
                assetKeys[key] = actual
            }
        }
    }

    /// The asset behind `key` was deleted: the mesh is released, the material becomes the placeholder.
    private func reportVanished(_ key: String, isMesh: Bool) {
        if isMesh {
            unregisterMesh(key: key)
            assetKeys[key] = nil
        } else {
            _ = try? registerMaterial(Self.placeholderMaterial, key: key)
            assetKeys[key] = Self.vanishedSignature
        }
        print("SceneRenderer: asset \(key) was deleted; its \(isMesh ? "mesh is no longer drawn" : "material is replaced by a placeholder")")
    }

    // MARK: Textures and budget

    /// Requests `id` and, when `blocksOnAssetLoading`, waits for it.
    private func awaitAsset(_ id: AssetID) -> AssetLoadState {
        guard let assets else { return .missing }
        var state = assets.request(id)
        if state == .loading && blocksOnAssetLoading {
            assets.waitForAll()
            state = assets.loadState(of: id)
        }
        return state
    }

    /// Whether `bytes` more can be uploaded this frame (and counts them if so).
    private func reserveUpload(_ bytes: Int, _ ignoringBudget: Bool) -> Bool {
        if ignoringBudget || blocksOnAssetLoading || assetUploadedBytes == 0 || assetUploadedBytes + bytes <= assetUploadBudget {
            assetUploadedBytes += bytes
            return true
        }
        assetsNeedRetry = true
        return false
    }

    private static func byteCount(_ geometry: MeshGeometry) -> Int {
        geometry.vertices.count * MemoryLayout<MeshVertex>.stride + geometry.indices.count * MemoryLayout<UInt32>.stride
    }

    private static func combine(_ revision: Int, _ texture: Int) -> Int { revision &* 1_000_003 &+ texture }

    /// Each texture slot of a material, in a fixed order (nil for an empty slot), for signatures.
    private static func textureSlots(_ material: MaterialAsset) -> [AssetReference?] {
        [material.texture, material.metallicRoughnessTexture, material.normalTexture, material.occlusionTexture,
         material.emissiveTexture]
    }

    /// What `material`'s signature will be once everything it needs is uploaded: the revision of
    /// its asset and of each of its textures (0 for an empty slot, -1 while a texture isn't
    /// loaded or has failed).
    private func desiredSignature(of material: MaterialAsset, reference: AssetReference) -> Int {
        guard let assets else { return Self.loadingSignature }
        return Self.textureSlots(material).reduce(assets.revision(of: reference.asset)) { signature, slot in
            Self.combine(signature, slot.map { assets.loadState(of: $0.asset) == .loaded ? assets.revision(of: $0.asset) : -1 } ?? 0)
        }
    }

    /// `material` with the GPU textures of all its texture references (a slot stays empty while
    /// its texture loads, is deferred or missing) and the signature of what was uploaded.
    private func materialTextures(_ material: MaterialAsset, reference: AssetReference, ignoringBudget: Bool) throws -> (Material, Int) {
        guard let assets else { return (material.material(texture: nil), Self.loadingSignature) }
        var signature = assets.revision(of: reference.asset)
        for slot in Self.textureSlots(material) {
            guard let slot else { signature = Self.combine(signature, 0); continue }
            let uploaded = try assetTexture(slot, ignoringBudget: ignoringBudget) != nil
            signature = Self.combine(signature, uploaded ? assets.revision(of: slot.asset) : -1)
        }
        // The uploads above are cached in `assetTextures`, so resolving again only looks them up.
        let resolved = try material.material(textures: { reference in
            guard let cached = assetTextures[reference.description], cached.revision == assets.revision(of: reference.asset) else { return nil }
            return cached.texture
        })
        return (resolved, signature)
    }

    /// The GPU texture for a material's texture reference (uploaded once per revision).
    func assetTexture(_ reference: AssetReference, ignoringBudget: Bool) throws -> GPUTexture? {
        guard let assets else { return nil }
        let key = reference.description
        if let cached = assetTextures[key], cached.revision == assets.revision(of: reference.asset) { return cached.texture }
        switch awaitAsset(reference.asset) {
        case .loaded: break
        case .loading, .unloaded:
            assetsNeedRetry = true
            return nil
        case .failed, .missing:
            if reportedTextures.insert(key).inserted {
                print("SceneRenderer: material texture \(assets.displayName(of: reference)) not found; drawing untextured")
            }
            return nil
        }
        guard let texture = assets.texture(reference) else {
            if reportedTextures.insert(key).inserted {
                print("SceneRenderer: material texture \(assets.displayName(of: reference)) not found; drawing untextured")
            }
            return nil
        }
        let revision = assets.revision(of: reference.asset)
        let gpu: GPUTexture
        if usesDefaultTextureUploader && PreparedTextureLevels.isWorthPreparing(texture) {
            guard let (levels, format) = preparedLevels(of: texture, key: key, revision: revision) else {
                assetsNeedRetry = true  // its job is still running
                return nil
            }
            guard reserveUpload(texture.gpuByteCount, ignoringBudget) else { return nil }
            preparingTextures[key] = nil
            gpu = try Profiler.scope("asset texture upload") { try device.makeTexture(levels: levels, format: format) }
        } else {
            guard reserveUpload(texture.gpuByteCount, ignoringBudget) else { return nil }
            gpu = try Profiler.scope("asset texture upload") { try textureUploader(texture, device) }
        }
        assetTextures[key] = (gpu, revision)
        return gpu
    }

    /// The levels of `texture` once its job has built them (started on the first call; waited
    /// for when `blocksOnAssetLoading`).
    private func preparedLevels(of texture: TextureAsset, key: String, revision: Int) -> ([TextureMipLevel], TextureFormat)? {
        let entry: PreparedTextureLevels
        if let preparing = preparingTextures[key], preparing.revision == revision {
            entry = preparing
        } else {
            entry = PreparedTextureLevels(texture, revision: revision)
            preparingTextures[key] = entry
        }
        if blocksOnAssetLoading { entry.wait() }
        return entry.result
    }
}

/// The GPU-ready levels of an imported texture, built by a background job (`JobSystem.shared`):
/// what the default `SceneRenderer.textureUploader` would build on the render thread (the same
/// levels, so the texture is identical).
final class PreparedTextureLevels: @unchecked Sendable {
    let revision: Int
    let format: TextureFormat
    private let jobs: JobSystem
    private let lock = NSLock()
    private var levels: [TextureMipLevel]?
    private var job: JobHandle?

    /// Whether building `texture`'s levels is CPU work worth moving off the render thread (a mip
    /// chain or a float conversion; not a plain copy or compressed levels). Malformed images
    /// aren't: the uploader reports them.
    static func isWorthPreparing(_ texture: TextureAsset) -> Bool {
        switch texture.pixels {
        case .rgba8(let image):
            texture.generatesMipmaps && image.width > 0 && image.height > 0 && image.pixels.count == image.width * image.height * 4
        case .rgbaFloat(let image):
            image.width > 0 && image.height > 0 && image.pixels.count == image.width * image.height * 4
        case .compressed:
            false
        }
    }

    init(_ texture: TextureAsset, revision: Int, jobs: JobSystem = .shared) {
        self.revision = revision
        self.jobs = jobs
        switch texture.pixels {
        case .rgba8: format = texture.isSRGB ? .rgba8Srgb : .rgba8Unorm
        case .rgbaFloat: format = .rgba16Float
        case .compressed(let format, _): self.format = format
        }
        job = jobs.schedule("texture levels", priority: .background) { [self] in
            let built: [TextureMipLevel]
            switch texture.pixels {
            case .rgba8(let image):
                built = MipChain.generate(pixels: image.pixels, width: image.width, height: image.height, srgb: texture.isSRGB)
            case .rgbaFloat(let image):
                built = MipChain.generateFloat(pixels: image.pixels, width: image.width, height: image.height,
                                               generateMipmaps: texture.generatesMipmaps)
            case .compressed(_, let levels):
                built = levels
            }
            lock.withLock { levels = built }
        }
    }

    /// The levels, once built.
    var result: ([TextureMipLevel], TextureFormat)? {
        lock.withLock { levels.map { ($0, format) } }
    }

    /// Returns once the levels are built (helping with background jobs meanwhile).
    func wait() {
        if let job { jobs.wait(job) }
    }
}
