import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// Skeletal animation from assets: `Animator`s whose clip handles are asset references
// ("asset:<id>#animation/walk", the clips a `.character` or glTF file imports) get their clips
// from the asset database through `addSceneAnimationSystem` (SceneAnimation.swift), which the
// editor's play mode, the Character Builder tab, GameRunner and built games all use.
//
// ```swift
// SkeletalAnimation.registerComponents()                       // before loading scenes
// world.addSceneAnimationSystem(assets: { database })          // while the world plays
// ```

/// Registration of the skeletal animation components.
public enum SkeletalAnimation {
    /// Registers `MeshRenderer`, `Skin`, `Animator` and `GroomRenderer` with `ComponentRegistry`, so scene files and scene-file
    /// prefabs (a `.character`'s) that hold them load. Idempotent.
    @MainActor public static func registerComponents() { ComponentRegistry.register(MeshRenderer.self, Skin.self, Animator.self, GroomRenderer.self) }
}
