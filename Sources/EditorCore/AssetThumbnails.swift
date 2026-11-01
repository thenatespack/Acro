import Engine
import Foundation

/// Thumbnails for the asset browser, made lazily and cached in memory.
///
/// - Textures: the image, downsampled on the CPU to at most `size` pixels and uploaded.
/// - Meshes, materials and prefabs: a small rendered preview (a mesh or prefab framed by its
///   bounds, a material on a sphere), rendered by a `SceneRenderer` of its own from a private
///   `World` into one `RenderTarget` per thumbnail. At most `perFrame` are made per frame:
///   `prepare()` (in `update`) lays the next few out side by side in the private world and
///   `render(frame:)` (in `renderOffscreen`) draws one view per thumbnail.
///
/// A thumbnail is made again when its asset's database revision changes (it is reimported);
/// the old image stays on screen until then. Assets that aren't loaded yet are requested in
/// the background (`AssetDatabase.request`) and queued once they are.
@MainActor
public final class AssetThumbnails {
    /// Edge length in pixels.
    public let size: Int
    /// Thumbnails made per frame.
    public var perFrame = 4
    public var assets: AssetDatabase? {
        didSet {
            guard assets !== oldValue else { return }
            renderer.assets = assets
            cache.removeAll()
            queue.removeAll()
            queued.removeAll()
        }
    }

    private let device: RenderDevice
    private let renderer: SceneRenderer
    private let world = World()
    private struct Entry {
        var texture: GPUTexture
        var revision: Int
        var target: RenderTarget?
    }
    private var cache: [String: Entry] = [:]
    private var queue: [(reference: AssetReference, kind: AssetKind)] = []
    private var queued: Set<String> = []
    private var batch: [(key: String, revision: Int, view: SceneView, target: RenderTarget, roots: [Entity])] = []
    private var spawned: [Entity] = []

    public init(device: RenderDevice, quality: RenderQuality, size: Int = 128) throws {
        self.device = device
        self.size = size
        renderer = try SceneRenderer(device: device, quality: quality)
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 35, 0))),
                    DirectionalLight(intensity: 1.6, castsShadows: false))
        world.spawn(SceneEnvironment(ambientIntensity: 0.7, fogDensity: 0))
    }

    /// The thumbnail of `reference` (a `kind` object), or nil while it isn't made yet (it is
    /// queued). A thumbnail of an older revision is returned while the new one is pending.
    public func thumbnail(_ reference: AssetReference, kind: AssetKind) -> GPUTexture? {
        guard let assets else { return nil }
        let key = reference.description
        let revision = Self.revision(of: reference, in: assets)
        let entry = cache[key]
        // Not imported yet: start a background load (its completion bumps the revision, and
        // the next call queues the thumbnail) instead of importing on the main thread.
        guard assets.request(reference.asset) == .loaded else { return entry?.texture }
        if entry?.revision != revision, !queued.contains(key) {
            queued.insert(key)
            queue.append((reference, kind))
        }
        return entry?.texture
    }

    /// Thumbnails waiting to be made.
    public var pendingCount: Int { queue.count }

    /// The rendered preview of `reference` (a mesh, material or prefab) if it is made for the
    /// asset's current revision, else nil (call `thumbnail` to queue it).
    public func currentTarget(for reference: AssetReference) -> RenderTarget? {
        guard let assets, let entry = cache[reference.description], entry.revision == Self.revision(of: reference, in: assets) else {
            return nil
        }
        return entry.target
    }

    /// Makes texture thumbnails and lays out the next previews; call once per frame in `update`.
    public func prepare() {
        for entity in spawned { world.despawn(entity) }
        spawned.removeAll()
        batch.removeAll()
        guard let assets else { return }
        var made = 0
        while made < perFrame, !queue.isEmpty {
            let (reference, kind) = queue.removeFirst()
            let key = reference.description
            queued.remove(key)
            let revision = Self.revision(of: reference, in: assets)
            made += 1
            switch kind {
            case .texture:
                guard let texture = assets.texture(reference) else { continue }
                do {
                    let small = Self.downsample(texture.image, to: size)
                    let gpu = try device.makeTexture(pixels: small.pixels, width: small.width, height: small.height,
                                                     format: texture.isSRGB ? .rgba8Srgb : .rgba8Unorm, generateMipmaps: false)
                    cache[key] = Entry(texture: gpu, revision: revision, target: nil)
                } catch {
                    print("AssetThumbnails: \(error)")
                }
            case .mesh, .material, .prefab:
                layOut(reference, kind: kind, key: key, revision: revision, slot: batch.count, assets: assets)
            }
        }
        if !batch.isEmpty { world.propagateTransforms() }
    }

    /// Renders the previews laid out by `prepare()`; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard !batch.isEmpty else { return }
        renderer.beginViews(world: world, frame: frame)
        for job in batch {
            renderer.renderView(job.view, into: job.target, frame: frame)
            cache[job.key] = Entry(texture: job.target.texture, revision: job.revision, target: job.target)
        }
        batch.removeAll()
    }

    /// The revision a thumbnail is made for: the asset's, and for a prefab variant also those of
    /// its chain of bases, so editing a base remakes its variants' thumbnails.
    static func revision(of reference: AssetReference, in assets: AssetDatabase) -> Int {
        var revision = assets.revision(of: reference.asset)
        // Only bases already loaded (a thumbnail never imports on the main thread).
        func loadedBase(of reference: AssetReference) -> AssetReference? {
            assets.loadState(of: reference.asset) == .loaded ? assets.prefab(reference)?.variant?.base : nil
        }
        var next = loadedBase(of: reference)
        var depth = 0
        while let base = next, depth < 16 {
            revision = revision &* 31 &+ assets.revision(of: base.asset)
            next = loadedBase(of: base)
            depth += 1
        }
        return revision
    }

    /// Spawns a copy of the prefab `reference` under `root` for its preview; a variant (whose
    /// file holds only its base and overrides, so it used to preview empty) through its
    /// resolved template, as its instances are built. False when it isn't available.
    @discardableResult
    static func spawnPrefab(_ reference: AssetReference, under root: Entity, in world: World, assets: AssetDatabase) -> Bool {
        guard let prefab = assets.prefab(reference) else { return false }
        guard prefab.variant != nil else {
            world.instantiate(prefab, under: root)
            return true
        }
        guard let template = try? prefab.template(prefabs: { assets.prefab($0) }),
              let roots = try? world.load(template.data, under: root, ids: .regenerate) else { return false }
        return !roots.isEmpty
    }

    /// Spawns the object at slot `slot` (100 units apart), scaled to a unit sphere, with a view
    /// looking at it.
    private func layOut(_ reference: AssetReference, kind: AssetKind, key: String, revision: Int, slot: Int, assets: AssetDatabase) {
        let origin = Vec3(Float(slot) * 100, 0, 0)
        let root = world.spawn(Transform())
        spawned.append(root)
        switch kind {
        case .mesh:
            let child = world.spawn(Transform(), MeshRenderer(mesh: MeshHandle(reference), castsShadows: false))
            world.setParent(child, to: root)
        case .material:
            let child = world.spawn(Transform(), MeshRenderer(mesh: .sphere, material: MaterialHandle(reference), castsShadows: false))
            world.setParent(child, to: root)
        default:
            guard Self.spawnPrefab(reference, under: root, in: world, assets: assets) else { return }
        }
        // Bounds of everything under the root, in the root's space.
        world.propagateTransforms()
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        func visit(_ entity: Entity) {
            if let renderer = world.get(MeshRenderer.self, for: entity) {
                let geometry = renderer.mesh.assetReference.flatMap { assets.mesh($0) } ?? builtinGeometry(renderer.mesh)
                if let bounds = geometry?.bounds, let matrix = world.get(GlobalTransform.self, for: entity)?.matrix {
                    let box = bounds.transformed(by: matrix)
                    lo = pointwiseMin(lo, box.center - box.halfExtent)
                    hi = pointwiseMax(hi, box.center + box.halfExtent)
                }
            }
            for child in world.children(of: entity) { visit(child) }
        }
        visit(root)
        let center = lo.x <= hi.x ? (lo + hi) / 2 : .zero
        let radius = lo.x <= hi.x ? max(length(hi - lo) / 2, 1e-4) : 1
        let scale = 1 / radius
        world.modify(Transform.self, for: root) {
            $0.position = origin - center * scale
            $0.scale = Vec3(repeating: scale)
        }
        let fov: Float = 30 * .pi / 180
        let distance = 1 / sin(fov / 2) * 1.02
        let direction = normalize(Vec3(0.55, 0.42, 1))
        let view = Mat4.lookAt(eye: origin + direction * distance, target: origin)
        let projection = Mat4.perspective(fovY: fov, aspect: 1, near: distance - 1.5, far: distance + 1.5)
        do {
            let target = try cache[key]?.target ?? RenderTarget(device: device, width: size, height: size, label: "thumbnail")
            batch.append((key, revision, SceneView(view: view, projection: projection, clearColor: Vec4(0.035, 0.04, 0.055, 1)),
                          target, [root]))
        } catch {
            print("AssetThumbnails: \(error)")
        }
    }

    private func builtinGeometry(_ handle: MeshHandle) -> MeshGeometry? {
        switch handle {
        case .sphere: MeshGeometry.sphere()
        case .cube: MeshGeometry.cube()
        case .plane: MeshGeometry.plane()
        default: nil
        }
    }

    /// `image` box-filtered down so its longer side is at most `size` (unchanged if smaller).
    static func downsample(_ image: Image, to size: Int) -> Image {
        let longest = max(image.width, image.height)
        guard longest > size else { return image }
        let factor = Float(longest) / Float(size)
        let width = max(1, Int((Float(image.width) / factor).rounded())), height = max(1, Int((Float(image.height) / factor).rounded()))
        // Average up to 4x4 samples per output pixel (plenty for a thumbnail).
        let taps = min(4, max(1, Int(factor.rounded(.up))))
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        image.pixels.withUnsafeBufferPointer { source in
            for y in 0..<height {
                for x in 0..<width {
                    var sum = SIMD4<Float>(repeating: 0)
                    for ty in 0..<taps {
                        let sy = min(image.height - 1, Int((Float(y) + (Float(ty) + 0.5) / Float(taps)) * factor))
                        for tx in 0..<taps {
                            let sx = min(image.width - 1, Int((Float(x) + (Float(tx) + 0.5) / Float(taps)) * factor))
                            let i = (sy * image.width + sx) * 4
                            sum += SIMD4(Float(source[i]), Float(source[i + 1]), Float(source[i + 2]), Float(source[i + 3]))
                        }
                    }
                    sum /= Float(taps * taps)
                    let o = (y * width + x) * 4
                    for c in 0..<4 { pixels[o + c] = UInt8(min(255, sum[c].rounded())) }
                }
            }
        }
        return Image(width: width, height: height, pixels: pixels)
    }
}
