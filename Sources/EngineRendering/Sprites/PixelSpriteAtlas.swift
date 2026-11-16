import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineText

// `.sprite` files (Pixel Sprite Builder) as sprite atlases and clips.
//
// ```swift
// let library = SpriteAssetLibrary(assets: assets, device: device, renderer: spriteRenderer)
// let hero = library.handle(path: "Sprites/hero.sprite")!          // registered with the renderer
// world.spawn(Transform(), Sprite(atlas: hero), library.animator(path: "Sprites/hero.sprite", playing: "run")!)
// // each frame: library.update()  (re-uploads sprites whose file changed: hot reload)
// ```

extension SpriteAtlasImage {
    /// The atlas page of a sprite sheet: frame `i` of the sprite is atlas frame `i`, named "frame`i`".
    public init(sheet: SpriteSheet) {
        let frames = sheet.frames.map { f in
            SpriteAtlasBuilder.makeFrame(name: f.name, x: f.x, y: f.y, width: f.width, height: f.height, inset: 0,
                                         pivot: sheet.pivot, atlasWidth: sheet.image.width, atlasHeight: sheet.image.height)
        }
        self.init(image: sheet.image, frames: frames)
    }
}

extension SpriteLoopMode {
    public init(_ mode: PixelSprite.TagMode) {
        switch mode {
        case .loop: self = .loop
        case .once: self = .once
        case .pingPong: self = .pingPong
        }
    }
}

extension SpriteClip {
    /// One clip per tag of the sheet (frame indices into the sheet's atlas), ready for `SpriteAnimator`.
    public static func clips(from sheet: SpriteSheet) -> [SpriteClip] {
        sheet.clips.map {
            SpriteClip($0.name, frames: $0.frames, fps: $0.fps, mode: SpriteLoopMode($0.mode),
                       events: $0.events.map { SpriteClipEvent(step: $0.step, name: $0.name) })
        }
    }
}

extension SpriteAtlas {
    /// Uploads a sprite sheet with nearest filtering (crisp pixels) and the sprite's pixels per unit.
    public convenience init(device: RenderDevice, sheet: SpriteSheet) throws {
        try self.init(device: device, packed: SpriteAtlasImage(sheet: sheet), srgb: true, filter: .nearest,
                      pixelsPerUnit: sheet.pixelsPerUnit)
    }
}

/// Loads `.sprite` assets as `SpriteAtlas`es and `SpriteClip`s, registers them with a
/// `SpriteRenderer` under their path, and reloads them when the file changes (call `update()`
/// once a frame). Works with a project's database and a cooked pack.
@MainActor
public final class SpriteAssetLibrary {
    public let assets: AssetDatabase
    public let device: RenderDevice
    /// Where loaded atlases are registered (key: the sprite's path under `Assets/`).
    public let renderer: SpriteRenderer?

    private struct Entry {
        var revision: Int
        var atlas: SpriteAtlas
        var clips: [SpriteClip]
        var key: String
    }

    private var entries: [AssetID: Entry] = [:]

    public init(assets: AssetDatabase, device: RenderDevice, renderer: SpriteRenderer? = nil) {
        self.assets = assets
        self.device = device
        self.renderer = renderer
    }

    private func id(forPath path: String) -> AssetID? {
        assets.id(forPath: path.hasPrefix("Assets/") ? String(path.dropFirst("Assets/".count)) : path)
    }

    @discardableResult
    private func load(_ id: AssetID) -> Entry? {
        let revision = assets.revision(of: id)
        if let entry = entries[id], entry.revision == revision { return entry }
        guard let sheet = assets.spriteSheet(id), let atlas = try? SpriteAtlas(device: device, sheet: sheet) else { return entries[id] }
        let entry = Entry(revision: assets.revision(of: id), atlas: atlas, clips: SpriteClip.clips(from: sheet),
                          key: assets.path(of: id) ?? id.description)
        entries[id] = entry
        renderer?.registerAtlas(atlas, key: entry.key)
        return entry
    }

    /// The atlas of the `.sprite` asset `id` (frame `i` is the sprite's frame `i`).
    public func atlas(_ id: AssetID) -> SpriteAtlas? { load(id)?.atlas }
    public func atlas(path: String) -> SpriteAtlas? { id(forPath: path).flatMap { atlas($0) } }

    /// One clip per tag (a single "default" clip of every frame without tags).
    public func clips(_ id: AssetID) -> [SpriteClip] { load(id)?.clips ?? [] }
    public func clips(path: String) -> [SpriteClip] { id(forPath: path).map { clips($0) } ?? [] }

    /// Loads the sprite, registers it with the renderer and returns the handle `Sprite` components use.
    public func handle(path: String) -> SpriteAtlasHandle? {
        guard let id = id(forPath: path), let entry = load(id) else { return nil }
        return SpriteAtlasHandle(entry.key)
    }

    /// A `SpriteAnimator` with the sprite's clips, playing `playing` (default: the first).
    public func animator(path: String, playing: String? = nil) -> SpriteAnimator? {
        let clips = clips(path: path)
        return clips.isEmpty ? nil : SpriteAnimator(clips: clips, current: playing)
    }

    /// Reloads every loaded sprite whose file was reimported (re-registering it with the renderer).
    /// Returns the reloaded ids.
    @discardableResult
    public func update() -> [AssetID] {
        var reloaded: [AssetID] = []
        for (id, entry) in entries {
            if assets.pack == nil { _ = assets.asset(id) }  // reimports a changed file
            guard assets.revision(of: id) != entry.revision else { continue }
            load(id)
            reloaded.append(id)
        }
        return reloaded
    }
}
