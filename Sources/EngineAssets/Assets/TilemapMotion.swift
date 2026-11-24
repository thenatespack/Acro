#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

// What makes a placed tilemap prefab move like `TilemapSpriteDrawer` draws it: layer parallax
// and animated tiles. The `.tilemap` importer puts a `TilemapMotion` on each layer node whose
// parallax isn't [1, 1] and on one node per animated tile of a layer (its mesh holds every cell
// of that tile, and the component names one mesh per animation frame). `World.runTilemapMotion()`
// plays them; `addBuiltinAnimationSystems()` runs it in `.lateUpdate` (after cameras moved), so
// the editor's play mode, `GamePlayer` and `GameRunner` play tilemaps with no game code.

/// Parallax and tile animation for a node of a placed tilemap (or any node: parallax works on
/// any entity with a `Transform`, background art say).
public struct TilemapMotion: Component, Codable, Equatable, Sendable {
    public static let componentName = "TilemapMotion"
    public static var fieldHints: [String: FieldHints] {
        ["parallax": FieldHints(step: 0.05, tooltip: "How much the node follows the world as the camera moves: 1 moves with the world, 0 stays with the camera"),
         "origin": FieldHints(step: 0.1, tooltip: "The node's position (in its parent) when the camera is at the parent's origin"),
         "meshes": FieldHints(tooltip: "One mesh per animation frame, shown in turn by the MeshRenderer")]
    }

    /// [1, 1] moves with the world (no parallax); [0.5, 0.5] moves half as fast (far away);
    /// [0, 0] stays fixed on screen. Applied as `origin + camera * (1 - parallax)`, with the
    /// active camera's position in the parent's space.
    public var parallax: Vec2
    /// The node's local position with the camera at its parent's origin.
    public var origin: Vec3
    /// A tile animation: the entity's `MeshRenderer` shows `meshes[step]` (one per frame).
    public var animation: TilemapAnimation?
    public var meshes: [MeshHandle]

    public init(parallax: Vec2 = Vec2(1, 1), origin: Vec3 = .zero, animation: TilemapAnimation? = nil, meshes: [MeshHandle] = []) {
        self.parallax = parallax
        self.origin = origin
        self.animation = animation
        self.meshes = meshes
    }

    private enum CodingKeys: String, CodingKey { case parallax, origin, animation, meshes }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(parallax: try c.decodeIfPresent(Vec2.self, forKey: .parallax) ?? Vec2(1, 1),
                  origin: try c.decodeIfPresent(Vec3.self, forKey: .origin) ?? .zero,
                  animation: try c.decodeIfPresent(TilemapAnimation.self, forKey: .animation),
                  meshes: try c.decodeIfPresent([MeshHandle].self, forKey: .meshes) ?? [])
    }

    /// Whether the node has parallax to apply.
    public var hasParallax: Bool { parallax != Vec2(1, 1) }

    /// The mesh to show at `time` seconds (nil: no animation).
    public func mesh(at time: Float) -> MeshHandle? {
        guard let step = animation?.step(at: time), meshes.indices.contains(step) else { return nil }
        return meshes[step]
    }
}

extension World {
    /// Applies every `TilemapMotion`: parallax against the active `Camera` (the lowest-index
    /// active one; none: no parallax), and animated tiles at `time.elapsed`. Cheap when no entity
    /// has one.
    @MainActor public func runTilemapMotion() {
        guard count(of: TilemapMotion.self) > 0 else { return }
        var camera: Entity?
        query(Camera.self) { entity, c in
            guard c.isActive else { return }
            if camera == nil || entity.index < camera!.index { camera = entity }
        }
        let cameraPosition = camera.map { worldMatrix(of: $0).c3 }
        let time = Float(self.time.elapsed)
        var entities: [(Entity, TilemapMotion)] = []
        query(TilemapMotion.self) { entity, motion in entities.append((entity, motion)) }
        var inverses: [Entity: Mat4] = [:]
        for (entity, motion) in entities {
            if motion.hasParallax, let cameraPosition, var transform = get(Transform.self, for: entity) {
                var local = cameraPosition
                if let parent = parent(of: entity) {
                    let inverse = inverses[parent] ?? worldMatrix(of: parent).inverse
                    inverses[parent] = inverse
                    local = inverse * cameraPosition
                }
                let follow = Vec2(1, 1) - motion.parallax
                transform.position = motion.origin + Vec3(local.x * follow.x, local.y * follow.y, 0)
                if transform != get(Transform.self, for: entity) { add(transform, to: entity) }
            }
            if let mesh = motion.mesh(at: time), var renderer = get(MeshRenderer.self, for: entity), renderer.mesh != mesh {
                renderer.mesh = mesh
                add(renderer, to: entity)
            }
        }
    }
}
