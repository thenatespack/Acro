import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// Skeletal animation from assets: `Animator`s whose clip handles are asset references
// ("asset:<id>#animation/walk", the clips a `.character` imports) get their clips from the asset
// database. Play mode and built games use `addSceneAnimationSystem` (SceneAnimation.swift),
// which drives the same animators; this loader is what the Character Builder tab previews with.
//
// ```swift
// SkeletalAnimation.registerComponents()                       // before loading scenes
// world.addAssetAnimationSystem(assets: { database })          // while the world plays
// ```

/// Registration of the skeletal animation components.
public enum SkeletalAnimation {
    /// Registers `MeshRenderer`, `Skin` and `Animator` with `ComponentRegistry`, so scene files and scene-file
    /// prefabs (a `.character`'s) that hold them load. Idempotent.
    @MainActor public static func registerComponents() { ComponentRegistry.register(MeshRenderer.self, Skin.self, Animator.self) }

    /// Every clip handle `animator` can play: its states' clips and blend entries, and its layers'.
    public static func clipHandles(of animator: Animator) -> [AnimationClipHandle] {
        var handles: [AnimationClipHandle] = []
        for state in animator.stateMachine.states {
            handles += state.motion.clips
        }
        return handles + animator.layers.map(\.clip)
    }
}

/// Keeps an `AnimationLibrary` filled with the asset clips the world's animators name, and
/// reloads a clip when its asset is reimported (hot reload while playing).
@MainActor
public final class AssetClipLoader {
    public let library: AnimationLibrary
    /// The asset revision each loaded key came from (-1: tried and missing).
    private var loaded: [String: Int] = [:]

    public init(library: AnimationLibrary = AnimationLibrary()) { self.library = library }

    /// Loads (or reloads) the asset clips the animators of `world` name. Returns how many were registered.
    @discardableResult
    public func update(_ world: World, assets: AssetDatabase) -> Int {
        var keys = Set<String>()
        world.query(Animator.self) { _, animator in
            for handle in SkeletalAnimation.clipHandles(of: animator) { keys.insert(handle.key) }
        }
        var count = 0
        for key in keys {
            guard let reference = AssetReference(key) else { continue }
            let revision = assets.revision(of: reference.asset)
            if let seen = loaded[key], seen == revision { continue }
            loaded[key] = revision
            guard let clip = assets.animationClip(reference) else { continue }
            library.register(clip, key: key)
            count += 1
        }
        return count
    }
}

extension World {
    /// Adds an `AssetClipLoader` system (`"<name>.clips"`) and `addAnimationSystem` (`name`), both in
    /// `.update`: every `Animator` plays, with clips named by asset reference loaded from `assets`
    /// (clips registered in the returned loader's library by other means play too). Remove them
    /// with `removeAssetAnimationSystem(name:)`.
    @discardableResult
    public func addAssetAnimationSystem(assets: @escaping () -> AssetDatabase?, name: String = "assetAnimation",
                                        onEvent: ((Entity, FiredAnimationEvent) -> Void)? = nil) -> AssetClipLoader {
        let loader = AssetClipLoader()
        addSystem(name + ".clips", stage: .update) { world in
            if let database = assets() { loader.update(world, assets: database) }
        }
        addAnimationSystem(loader.library, name: name, onEvent: onEvent)
        return loader
    }

    /// Removes the systems `addAssetAnimationSystem(name:)` added.
    public func removeAssetAnimationSystem(name: String = "assetAnimation") {
        removeSystem(named: name + ".clips")
        removeSystem(named: name)
    }
}
