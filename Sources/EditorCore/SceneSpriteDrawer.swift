import Engine
import Foundation

/// Draws the world's `Sprite` components in the editor's Scene view (and Game view and their
/// screenshots): each sprite's atlas key is the path of a `.sprite` asset (as
/// `SpriteAssetLibrary.handle(path:)` gives it), loaded on first use and reloaded when the file
/// changes. Sprites are depth-tested against the scene, so meshes in front hide them. Atlases
/// that aren't `.sprite` assets (registered by game code at run time) aren't drawn.
@MainActor
final class SceneSpriteDrawer {
    let device: RenderDevice
    private var renderers: [Bool: SpriteRenderer] = [:]
    private var library: SpriteAssetLibrary?

    init(device: RenderDevice) {
        self.device = device
    }

    private func renderer(reversedZ: Bool) -> SpriteRenderer? {
        if let renderer = renderers[reversedZ] { return renderer }
        guard let renderer = try? SpriteRenderer(device: device, depth: .tested(reversedZ: reversedZ)) else { return nil }
        renderers[reversedZ] = renderer
        return renderer
    }

    /// Loads the atlases `world`'s sprites use and queues them; call before the view's pass,
    /// then `render(into:viewProjection:reversedZ:)` inside it. Returns how many sprites were queued.
    @discardableResult
    func prepare(world: World, assets: AssetDatabase?, reversedZ: Bool) -> Int {
        guard world.count(of: Sprite.self) > 0, let renderer = renderer(reversedZ: reversedZ) else { return 0 }
        if library?.assets !== assets { library = assets.map { SpriteAssetLibrary(assets: $0, device: device, renderer: nil) } }
        if let library {
            library.update()
            var keys = Set<String>()
            world.query(Sprite.self) { _, sprite in keys.insert(sprite.atlas.key) }
            // Cached by file revision, so this is a lookup once loaded.
            for key in keys { if let atlas = library.atlas(path: key) { renderer.registerAtlas(atlas, key: key) } }
        }
        let before = renderer.batch.count
        renderer.draw(world: world)
        return renderer.batch.count - before
    }

    /// Draws what `prepare` queued into `pass`.
    func render(into pass: RenderPass, viewProjection: Mat4, reversedZ: Bool) {
        guard let renderer = renderers[reversedZ], renderer.batch.count > 0 else { return }
        renderer.render(into: pass, viewProjection: viewProjection)
    }
}
