import Foundation
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene

// Game feel: camera shake, hit stop and hit flashes, for combat (Combat.swift) and game code.
//
// - Shake uses trauma (0...1, decaying over time): the active camera is offset and turned by
//   smooth noise scaled by trauma squared, in `.lateUpdate` after camera rigs move it, and put
//   back before the next frame's offset so rigs and game code see the unshaken transform.
// - Hit stop is `World.hitStop`: game time freezes (or slows) for a moment of real time.
// - A flash multiplies an entity's (and its children's) `MeshRenderer` tints for a moment.

/// Camera shake and hit flashes of one world (`World.gameFeel` while playing).
@MainActor
public final class GameFeel {
    public static let systemName = "gameFeel"

    /// Shake strength 0...1; the offset grows with its square. `shake(_:)` adds to it.
    public private(set) var trauma: Float = 0
    /// Trauma lost per second.
    public var decay: Float = 1.6
    /// Offset at full trauma, meters, and turn at full trauma, degrees.
    public var maxOffset: Float = 0.12
    public var maxAngle: Float = 2.5
    /// How fast the shake moves (noise samples per second).
    public var frequency: Float = 22
    /// Shake and flashes off (hit stop still works: it is the world's).
    public var enabled = true

    private var time: Float = 0
    private var shaken: (camera: Entity, base: Transform, applied: Transform)?
    private struct Flash {
        var entity: Entity
        var remaining: Float
        var tints: [Entity: Vec3]
    }
    private var flashes: [Flash] = []

    init() {}

    /// Adds `amount` of trauma (capped at 1).
    public func shake(_ amount: Float) {
        guard amount.isFinite else { return }
        trauma = min(max(trauma + amount, 0), 1)
    }

    /// Tints `entity` and its children by `color` (multiplied with their tints) for `duration` seconds.
    public func flash(_ entity: Entity, color: Vec3, duration: Float = 0.12, in world: World) {
        guard enabled, world.isAlive(entity), duration > 0 else { return }
        if let i = flashes.firstIndex(where: { $0.entity == entity }) {
            flashes[i].remaining = max(flashes[i].remaining, duration)
            return
        }
        var tints: [Entity: Vec3] = [:]
        var stack = [entity]
        while let e = stack.popLast() {
            if let renderer = world.get(MeshRenderer.self, for: e) {
                tints[e] = renderer.tint
                world.modify(MeshRenderer.self, for: e) { $0.tint = renderer.tint * color }
            }
            stack += world.children(of: e)
        }
        flashes.append(Flash(entity: entity, remaining: duration, tints: tints))
    }

    /// The camera offset the shake applies now (for tests and tools).
    public var currentOffset: Vec3 { shaken.map { $0.applied.position - $0.base.position } ?? .zero }

    func update(_ world: World) {
        let dt = world.time.unscaledDelta
        time += dt
        trauma = max(trauma - decay * dt, 0)
        updateFlashes(world, dt)
        // Put the camera back where its owner left it.
        if let s = shaken, world.isAlive(s.camera) {
            if let now = world.get(Transform.self, for: s.camera), now == s.applied { world.add(s.base, to: s.camera) }
        }
        shaken = nil
        guard enabled, trauma > 0.001, let camera = RenderPrep.findCamera(in: world)?.entity,
              let base = world.get(Transform.self, for: camera) else { return }
        let amount = trauma * trauma
        func noise(_ k: Float) -> Float { AnimationNoise.fractal(time * frequency + k * 31.7, seed: 0x5EED) }
        let offset = Vec3(noise(1), noise(2), noise(3)) * maxOffset * amount
        let degrees = Vec3(noise(4), noise(5), noise(6)) * maxAngle * amount
        var moved = base
        moved.position += base.rotation * offset
        moved.rotation = base.rotation * Quat(angle: degrees.x * .pi / 180, axis: Vec3(1, 0, 0))
            * Quat(angle: degrees.y * .pi / 180, axis: Vec3(0, 1, 0)) * Quat(angle: degrees.z * .pi / 180, axis: Vec3(0, 0, 1))
        world.add(moved, to: camera)
        shaken = (camera, base, moved)
    }

    private func updateFlashes(_ world: World, _ dt: Float) {
        guard !flashes.isEmpty else { return }
        var kept: [Flash] = []
        for var flash in flashes {
            flash.remaining -= dt
            if flash.remaining > 0 && world.isAlive(flash.entity) {
                kept.append(flash)
                continue
            }
            for (e, tint) in flash.tints { world.modify(MeshRenderer.self, for: e) { $0.tint = tint } }
        }
        flashes = kept
    }

    /// Ends the shake and flashes, restoring the camera and tints.
    func reset(_ world: World) {
        if let s = shaken, world.isAlive(s.camera), world.get(Transform.self, for: s.camera) == s.applied { world.add(s.base, to: s.camera) }
        shaken = nil
        for flash in flashes { for (e, tint) in flash.tints { world.modify(MeshRenderer.self, for: e) { $0.tint = tint } } }
        flashes = []
        trauma = 0
    }
}
