import Engine
import Foundation

/// Plays the scene's asset-driven animators (characters, glTF models with clips, animation
/// graphs) in the edit-mode Scene view without changing the scene (View > Animate in Scene View,
/// `view.animateInEditMode`). Each animator gets a preview copy that advances every frame; its
/// pose is written into the bones' `Transform`s only while the viewport renders
/// (`posing(_:_:)`) and put back right after, so saving, undo, the inspector, prefab overrides
/// and commands always see the scene as authored.
///
/// A preview copy starts over whenever the scene's animator changes (an edit, undo, a reimport
/// of its graph). Editor-only: play mode and games use `World.addSceneAnimationSystem`.
@MainActor
public final class EditModeAnimationPreview {
    public var isEnabled = false {
        didSet { if !isEnabled { previews.removeAll() } }
    }

    private struct Preview {
        /// The scene's animator the copy started from (a change restarts it).
        var source: Animator
        var animator: Animator
        var pose: AnimationPose
        var graphRevision: Int?
    }

    private let library = AnimationLibrary()
    private var previews: [Entity: Preview] = [:]
    /// Transforms `posing` replaced, put back after the body.
    private var saved: [(Entity, Transform)] = []

    public init() {}

    /// How many animators the preview plays.
    public var count: Int { previews.count }

    /// Advances the preview copies by `dt`. Animators that left the scene are dropped.
    public func advance(_ world: World, assets: AssetDatabase?, dt: Float) {
        guard isEnabled else { return }
        library.assets = assets
        var seen = Set<Entity>()
        world.query(Animator.self) { entity, animator in
            guard animator.isSceneDriven else { return }
            seen.insert(entity)
        }
        for entity in previews.keys where !seen.contains(entity) { previews[entity] = nil }
        for entity in seen {
            guard let source = world.get(Animator.self, for: entity) else { continue }
            let revision = source.graph.flatMap { assets?.revision(of: $0.asset) }
            var preview: Preview
            if let existing = previews[entity], existing.source == source, existing.graphRevision == revision {
                preview = existing
            } else {
                var animator = source
                if let reference = source.graph, let graph = assets?.animationGraph(reference) { animator.apply(graph) }
                if animator.targets.isEmpty {
                    let rig = world.animationRig(of: entity)
                    animator.targets = rig.targets
                    animator.restPose = rig.restPose
                }
                preview = Preview(source: source, animator: animator, pose: AnimationPose([]), graphRevision: revision)
            }
            library.resolveAssetClips(preview.animator.clipHandles)
            preview.pose = preview.animator.update(dt: dt) { library.clip($0) }
            previews[entity] = preview
        }
    }

    /// Runs `body` with the preview poses in the scene's bone transforms (and global
    /// transforms propagated), then puts the authored transforms back. Without previews
    /// (disabled, nothing to animate) it just runs `body`.
    public func posing<R>(_ world: World, _ body: () throws -> R) rethrows -> R {
        guard isEnabled, !previews.isEmpty else { return try body() }
        saved.removeAll(keepingCapacity: true)
        for preview in previews.values {
            let pose = preview.pose, targets = preview.animator.targets
            for i in 0..<min(pose.count, targets.count) where pose.animated[i] {
                guard let authored = world.get(Transform.self, for: targets[i]) else { continue }
                saved.append((targets[i], authored))
                world.modify(Transform.self, for: targets[i]) { $0 = pose.transforms[i] }
            }
        }
        world.propagateTransforms()
        defer {
            // Reversed, so a target two animators share ends at its authored value.
            for (entity, transform) in saved.reversed() { world.modify(Transform.self, for: entity) { $0 = transform } }
            saved.removeAll(keepingCapacity: true)
            world.propagateTransforms()
        }
        return try body()
    }
}

/// `view.animateInEditMode`: the edit-mode Scene view's animation preview (`EditorSession.editAnimation`).
@MainActor
public enum ViewAnimateInEditModeCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// On or off; omitted: toggles.
        public var on: Bool?
        public init(on: Bool? = nil) { self.on = on }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var on: Bool
        /// Animators the preview plays (counted at the next frame after turning it on).
        public var animators: Int
    }

    public static let id: CommandID = "view.animateInEditMode"
    public static let title = "Animate in Scene View"
    public static let doc = """
        Turns on (or off, or toggles without `on`) animation in the edit-mode Scene view: characters, glTF models with \
        asset clips and animation graphs play their Animator (from its initial state, e.g. a character's idle) while you \
        edit, without entering play mode. Editor-only and never saved: the pose is shown, not written into the scene, so \
        saving, undo and the inspector see the authored transforms. Returns whether it is on and how many animators play.
        """
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let preview = session.editAnimation
        preview.isEnabled = arguments.on ?? !preview.isEnabled
        if preview.isEnabled && !session.isPlaying { preview.advance(session.world, assets: session.assets, dt: 0) }
        return Result(on: preview.isEnabled, animators: preview.count)
    }
}
