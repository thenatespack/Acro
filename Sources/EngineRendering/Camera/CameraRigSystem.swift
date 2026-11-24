#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// The "cameraRigs" system: each frame (in `.lateUpdate`, after gameplay moved the targets) it
// 1. picks the live rig: the enabled `CameraRig` with the highest `priority` (ties: lowest entity);
// 2. evaluates every enabled rig (standby rigs too, so a blend to one starts from where it is now):
//    the followed point damped per axis, yaw and pitch from input (live rig only) and damped,
//    auto-recenter, the mode's framing, then the collision probe;
// 3. when the live rig changed, starts a blend from the outgoing rig (still evaluated, so the blend
//    follows both) or, if a blend was already running, from the pose it had reached;
// 4. writes the result into the output camera's `Transform` (and `Camera.fovY`).
// Smoothing is exponential with time constants (`1 - exp(-dt / time)`), so it is the same at any
// frame rate. Collision sphere-casts from the followed point toward the camera; a wall pulls the
// camera in at once (smoothed by `pullInTime`, never further than a collision radius behind the
// hit) and it eases back out over `easeOutTime`. The target's own colliders, its character's and
// its ragdoll's bodies (everything under the target or under the nearest ancestor with a
// `CharacterController` or `Ragdoll`) don't block it.

/// The live state of a rig's collision probe, for gizmos and tools.
public struct CameraRigProbe: Equatable, Sendable {
    /// Where the rig's camera is (before blending with another rig).
    public var pose: CameraPose
    /// The followed point the cast starts from, and where the camera wants to be.
    public var start: Vec3
    public var end: Vec3
    /// Where the cast hit a wall (nil: clear).
    public var hit: Vec3?
    public var radius: Float
}

/// Runs `CameraRig`s for one world; `World.addCameraRigs(input:)` makes one. See the notes at
/// the top of CameraRigSystem.swift.
@MainActor
public final class CameraRigSystem {
    public static let systemName = "cameraRigs"

    public private(set) weak var world: World?
    /// The game's input: orbit, zoom and recenter for the live rig. nil: no input.
    public var input: Input?
    /// The actions rigs read (`CameraRig.orbitAction`, `.zoomAction`, `.recenterAction`); starts
    /// with `defaultBindings`. Rebind or add actions here.
    public let actions: InputActions
    /// The rig driving the camera now (nil: none enabled).
    public private(set) var liveRig: Entity?
    /// The camera entity the rigs move.
    public private(set) var outputCamera: Entity?
    /// Whether a blend between rigs is running, and how far (0...1 after the curve).
    public var isBlending: Bool { blend != nil }
    public private(set) var blendWeight: Float = 1

    private enum BlendSource {
        case pose(CameraPose)
        case rig(Entity)
    }
    private struct Blend {
        var from: BlendSource
        var elapsed: Float
        var duration: Float
        var curve: Easing
    }
    private var blend: Blend?
    /// A blend time asked for by `activate(_:blendTime:)`, used by the next switch.
    private var pendingBlendTime: Float?
    private var lastOutput: CameraPose?
    /// Each output camera's own field of view, for rigs without `fieldOfView`.
    private var baseFov: [Entity: Float] = [:]

    /// look: the right stick; zoom: d-pad up (in) / down (out); recenter: right stick click or the middle mouse button.
    public static func defaultBindings() -> InputBindings {
        var bindings = InputBindings()
        bindings.vectors.append(.init("look", [.stick(stick: .right)]))
        bindings.axes.append(.init("zoom", [.composite(negative: .gamepadButton(.dpadDown), positive: .gamepadButton(.dpadUp))]))
        bindings.buttons.append(.init("recenter", [.gamepadButton(.rightStickClick), .mouseButton(.middle)]))
        return bindings
    }

    init(world: World, input: Input?) {
        self.world = world
        self.input = input
        actions = InputActions(bindings: Self.defaultBindings())
    }

    /// The system running `world`'s rigs, if `addCameraRigs` was called.
    public static func system(for world: World) -> CameraRigSystem? {
        guard let entry = systems[ObjectIdentifier(world)], entry.world === world else { return nil }
        return entry.system
    }

    private struct Entry {
        weak var world: World?
        weak var system: CameraRigSystem?
    }
    private static var systems: [ObjectIdentifier: Entry] = [:]

    fileprivate static func set(_ system: CameraRigSystem?, for world: World) {
        systems = systems.filter { $0.value.world != nil && $0.value.system != nil }
        systems[ObjectIdentifier(world)] = system.map { Entry(world: world, system: $0) }
    }

    /// Removes the system from its world.
    public func remove() {
        guard let world else { return }
        world.removeCameraRigs()
    }

    /// Makes `rig` the live rig: enables it and raises its priority above every other rig's.
    /// The switch blends over `blendTime` (nil: the rig's own). Returns false when it has no rig.
    @discardableResult
    public func activate(_ rig: Entity, blendTime: Float? = nil) -> Bool {
        guard let world, world.activateCameraRigPriority(rig) else { return false }
        if rig != liveRig { pendingBlendTime = blendTime }
        return true
    }

    // MARK: Frame

    func update() {
        guard let world else { return }
        let dt = world.time.delta
        if let input { actions.update(input) }
        var rigs: [(entity: Entity, rig: CameraRig)] = []
        world.query(CameraRig.self) { entity, rig in rigs.append((entity, rig)) }
        rigs.sort { $0.entity.index < $1.entity.index }
        let live = Self.pickLive(rigs)
        let output = live.flatMap { entity in rigs.first { $0.entity == entity }.map { Self.outputCamera(for: $0.rig, entity: entity, in: world) } } ?? nil
        let physics = world.attachedPhysics

        var poses: [Entity: CameraPose] = [:]
        for (entity, original) in rigs {
            var rig = original
            if !rig.enabled {
                if rig.runtime.started || rig.isLive {
                    rig.runtime = CameraRigRuntime()
                    rig.isLive = false
                    rig.blendWeight = 0
                    world.add(rig, to: entity)
                }
                continue
            }
            let isLive = entity == live
            let control = isLive && rig.inputEnabled ? control(for: rig, dt: dt) : nil
            poses[entity] = Self.evaluate(&rig, entity: entity, in: world, dt: dt, control: control, physics: physics,
                                          ownsOutput: entity == output)
            rig.isLive = isLive
            rig.blendWeight = isLive ? 1 : 0
            world.add(rig, to: entity)
        }

        guard let live, let output, var livePose = poses[live], let liveRig = world.get(CameraRig.self, for: live) else {
            self.liveRig = live
            blend = nil
            return
        }
        // The output camera: the new one becomes the active camera, the old one steps aside.
        if output != outputCamera {
            if let old = outputCamera, world.isAlive(old), old != output, world.has(Camera.self, for: old) {
                world.modify(Camera.self, for: old) { $0.isActive = false }
            }
            world.modify(Camera.self, for: output) { $0.isActive = true }
            outputCamera = output
        }
        if baseFov[output] == nil { baseFov[output] = world.get(Camera.self, for: output)?.fovY ?? .pi / 3 }
        let base = baseFov[output] ?? .pi / 3
        if livePose.fovY == nil { livePose.fovY = base }

        if live != self.liveRig {
            let duration = pendingBlendTime ?? liveRig.blendTime
            if let previous = self.liveRig, let last = lastOutput, duration > 0 {
                let from: BlendSource = blend != nil || poses[previous] == nil ? .pose(last) : .rig(previous)
                blend = Blend(from: from, elapsed: 0, duration: duration, curve: liveRig.blendCurve)
            } else {
                blend = nil
            }
            pendingBlendTime = nil
            self.liveRig = live
        }
        var pose = livePose
        blendWeight = 1
        if var running = blend {
            running.elapsed += dt
            let t = min(running.elapsed / max(running.duration, 1e-4), 1)
            blendWeight = running.curve(t)
            var from: CameraPose
            switch running.from {
            case .pose(let p): from = p
            case .rig(let e): from = poses[e] ?? lastOutput ?? livePose
            }
            if from.fovY == nil { from.fovY = base }
            pose = CameraPose.blend(from, livePose, blendWeight)
            blend = t >= 1 ? nil : running
        }
        lastOutput = pose
        world.modify(CameraRig.self, for: live) { $0.blendWeight = blendWeight }
        Self.write(pose, to: output, in: world)
    }

    /// The enabled rig with the highest priority (ties: the lowest entity index).
    static func pickLive(_ rigs: [(entity: Entity, rig: CameraRig)]) -> Entity? {
        var best: (entity: Entity, priority: Int)?
        for (entity, rig) in rigs where rig.enabled {
            if best == nil || rig.priority > best!.priority || (rig.priority == best!.priority && entity.index < best!.entity.index) {
                best = (entity, rig.priority)
            }
        }
        return best?.entity
    }

    /// `rig.camera`, else the rig's own entity when it has a `Camera`, else the active camera with
    /// the lowest index (else any camera).
    public static func outputCamera(for rig: CameraRig, entity: Entity, in world: World) -> Entity? {
        if let e = world.resolve(rig.camera), world.has(Camera.self, for: e) { return e }
        if world.has(Camera.self, for: entity) { return entity }
        var active: Entity?, any: Entity?
        world.query(Camera.self) { e, camera in
            if camera.isActive, active == nil || e.index < active!.index { active = e }
            if any == nil || e.index < any!.index { any = e }
        }
        return active ?? any
    }

    /// Puts the camera at `pose` (in its parent's space) and sets its field of view.
    static func write(_ pose: CameraPose, to camera: Entity, in world: World) {
        let scale = world.get(Transform.self, for: camera)?.scale ?? .one
        var local = Transform(position: pose.position, rotation: pose.rotation, scale: scale)
        if let parent = world.parent(of: camera) {
            let m = world.worldMatrix(of: parent).inverse * Mat4(translation: pose.position, rotation: pose.rotation, scale: .one)
            let t = Transform(matrix: m)
            local = Transform(position: t.position, rotation: t.rotation, scale: scale)
        }
        if world.has(Transform.self, for: camera) {
            world.modify(Transform.self, for: camera) { $0 = local }
        } else {
            world.add(local, to: camera)
        }
        if let fov = pose.fovY, let current = world.get(Camera.self, for: camera), current.fovY != fov {
            world.modify(Camera.self, for: camera) { $0.fovY = fov }
        }
    }

    // MARK: Input

    /// What the player asks of the live rig this frame.
    struct Control {
        /// Degrees to add to (yaw, pitch).
        var orbit: Vec2 = .zero
        /// Meters closer (positive) or farther.
        var zoom: Float = 0
        var recenter = false
    }

    private func control(for rig: CameraRig, dt: Float) -> Control? {
        guard let input else { return nil }
        var c = Control()
        let sx: Float = rig.invertX ? -1 : 1, sy: Float = rig.invertY ? -1 : 1
        let stick = actions.vector(rig.orbitAction)
        c.orbit = Vec2(-stick.x * sx, -stick.y * sy) * rig.orbitSpeed * dt
        if rig.mouseOrbit, input.isMouseCaptured || input.isDown(MouseButton.right) {
            c.orbit += Vec2(-input.mouseDelta.x * sx, input.mouseDelta.y * sy) * rig.mouseSensitivity
        }
        c.zoom = actions.value(rig.zoomAction) * rig.zoomSpeed * dt + input.scrollDelta.y * rig.zoomSpeed * 0.01
        c.recenter = actions.wasPressed(rig.recenterAction)
        return c
    }

    // MARK: Evaluation

    /// The fraction of the way to move toward a goal this frame with smoothing time `time`.
    static func smoothing(_ dt: Float, _ time: Float) -> Float {
        time <= 0 ? 1 : 1 - expf(-max(dt, 0) / time)
    }

    /// `a` toward `b` (degrees, the short way round) by `k`.
    static func approachAngle(_ a: Float, _ b: Float, _ k: Float) -> Float {
        a + wrapDegrees(b - a) * k
    }

    static func wrapDegrees(_ a: Float) -> Float {
        var x = a.truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }

    /// The camera rotation for a heading and a pitch (degrees, positive looking down).
    public static func rotation(yaw: Float, pitch: Float) -> Quat {
        (Quat(angle: yaw * .pi / 180, axis: Vec3(0, 1, 0)) * Quat(angle: -pitch * .pi / 180, axis: Vec3(1, 0, 0))).normalized
    }

    /// The heading (degrees) that looks along `forward` (horizontal part), nil when it is vertical.
    public static func heading(of forward: Vec3) -> Float? {
        guard forward.x * forward.x + forward.z * forward.z > 1e-8 else { return nil }
        return atan2f(-forward.x, -forward.z) * 180 / .pi
    }

    /// Moves `rig` one frame and returns where its camera goes. `control` is the live rig's input
    /// (nil for standby rigs and previews); `ownsOutput` says the rig sits on the camera it moves
    /// (so its own entity's pose is the camera's, not an anchor). `dt` 0 on a fresh rig gives its
    /// settled pose (what previews show).
    static func evaluate(_ rig: inout CameraRig, entity: Entity, in world: World, dt: Float, control: Control?,
                         physics: PhysicsWorld?, ownsOutput: Bool) -> CameraPose {
        var r = rig.runtime
        let first = !r.started
        r.started = true
        let fov = rig.fieldOfView.map { $0 * .pi / 180 }
        let up = Vec3(0, 1, 0)

        // A fixed rig on the camera it moves remembers where the camera was placed (it is moved from now on).
        if first, ownsOutput {
            let m = world.worldMatrix(of: entity)
            let t = Transform(matrix: m)
            r.fixedPose = CameraPose(position: t.position, rotation: t.rotation, fovY: fov)
        }
        if rig.mode == .fixed {
            var pose = r.fixedPose ?? {
                let t = Transform(matrix: world.worldMatrix(of: entity))
                return CameraPose(position: t.position, rotation: t.rotation)
            }()
            if !ownsOutput {
                let t = Transform(matrix: world.worldMatrix(of: entity))
                pose = CameraPose(position: t.position, rotation: t.rotation)
            }
            pose.fovY = fov
            r.pose = pose
            r.probeHitPoint = nil
            rig.runtime = r
            rig.cameraPosition = pose.position
            rig.probeStart = pose.position
            rig.probeEnd = pose.position
            rig.probeHit = false
            return pose
        }

        // The target: its origin and facing. Without one the rig follows its own entity (its
        // placed position when it is the camera it moves).
        let targetEntity = world.resolve(rig.target).flatMap { world.isAlive($0) ? $0 : nil }
        let origin: Vec3
        var facing = Vec3(0, 0, 1)
        if let targetEntity {
            let m = world.worldMatrix(of: targetEntity)
            origin = Vec3(m.c3.x, m.c3.y, m.c3.z)
            facing = Vec3(m.c2.x, m.c2.y, m.c2.z)
        } else if ownsOutput, let placed = r.fixedPose {
            origin = placed.position - rig.targetOffset
            facing = -placed.forward
        } else {
            let m = world.worldMatrix(of: entity)
            origin = Vec3(m.c3.x, m.c3.y, m.c3.z)
            facing = -Vec3(m.c2.x, m.c2.y, m.c2.z)
        }
        let followed = origin + rig.targetOffset
        if first {
            r.lastTarget = origin
            r.velocity = .zero
        }
        if dt > 0 {
            let v = (origin - r.lastTarget) / dt
            r.velocity += (v - r.velocity) * smoothing(dt, 0.1)
        }
        r.lastTarget = origin
        let speed = (r.velocity.x * r.velocity.x + r.velocity.z * r.velocity.z).squareRoot()
        // Looking along the target's +Z (the way characters face) from behind it.
        let behindYaw = heading(of: facing) ?? r.yaw

        let minPitch = rig.resolvedMinPitch, maxPitch = rig.resolvedMaxPitch
        let sideDirection = lengthSquared(rig.sideDirection) > 1e-8 ? normalize(rig.sideDirection) : Vec3(0, 0, 1)
        let sideYaw = heading(of: -sideDirection) ?? 0
        if first {
            switch rig.mode {
            case .topDown: r.yaw = rig.yaw ?? 0
            case .sideScroller: r.yaw = sideYaw
            default: r.yaw = rig.yaw ?? behindYaw
            }
            r.pitch = rig.resolvedPitch
            r.wantedYaw = r.yaw
            r.wantedPitch = r.pitch
            r.distance = rig.resolvedDistance
            r.pivot = followed
            r.focus = followed
            r.lookAhead = 0
            r.pull = 0
            r.idleTime = 0
            r.recentering = false
        }

        // Input: orbit (not from the side), zoom, recenter.
        let lo = min(rig.minDistance, rig.maxDistance), hi = max(rig.minDistance, rig.maxDistance)
        if let control {
            if rig.mode != .sideScroller, control.orbit != .zero {
                r.wantedYaw += control.orbit.x
                r.wantedPitch += control.orbit.y
                r.idleTime = 0
                r.recentering = false
            } else {
                r.idleTime += dt
            }
            if control.zoom != 0, rig.mode != .firstPerson { r.distance = min(max(r.distance - control.zoom, lo), hi) }
            if control.recenter { r.recentering = true }
        } else {
            r.idleTime += dt
        }
        if rig.mode == .sideScroller { r.wantedYaw = sideYaw }
        r.wantedPitch = min(max(r.wantedPitch, minPitch), maxPitch)
        if rig.distance != nil, control == nil { r.distance = rig.resolvedDistance }

        // Recentering: behind the target (or the starting heading, top-down).
        let home = rig.mode == .topDown ? (rig.yaw ?? 0) : behindYaw
        let autoRecenters = rig.autoRecenter && rig.mode != .topDown && r.idleTime >= rig.recenterDelay && speed > 0.5
        if rig.mode != .sideScroller, r.recentering || autoRecenters {
            let k = smoothing(dt, r.recentering ? rig.recenterTime * 0.5 : rig.recenterTime)
            r.wantedYaw = approachAngle(r.wantedYaw, home, k)
            if r.recentering {
                r.wantedPitch += (rig.resolvedPitch - r.wantedPitch) * k
                if abs(wrapDegrees(home - r.wantedYaw)) < 0.5 && abs(rig.resolvedPitch - r.wantedPitch) < 0.5 { r.recentering = false }
            }
        }

        // Rotation damping per axis.
        let rd = rig.resolvedRotationDamping
        r.yaw = first ? r.wantedYaw : approachAngle(r.yaw, r.wantedYaw, smoothing(dt, rd.x))
        r.pitch = first ? r.wantedPitch : r.pitch + (r.wantedPitch - r.pitch) * smoothing(dt, rd.y)
        r.yaw = wrapDegrees(r.yaw)
        r.wantedYaw = r.yaw + wrapDegrees(r.wantedYaw - r.yaw)
        let rotation = rotation(yaw: r.yaw, pitch: r.pitch)
        let forward = rotation * Vec3(0, 0, -1)

        // The framed point: the target, or the side scroller's dead-zone focus plus look-ahead.
        var framed = followed
        if rig.mode == .sideScroller {
            var right = cross(-sideDirection, up)
            right = lengthSquared(right) > 1e-8 ? normalize(right) : Vec3(1, 0, 0)
            let d = followed - r.focus
            let dx = dot(d, right), dy = d.y
            if abs(dx) > rig.deadZone.x { r.focus += right * (dx - (dx > 0 ? rig.deadZone.x : -rig.deadZone.x)) }
            if abs(dy) > rig.deadZone.y { r.focus.y += dy - (dy > 0 ? rig.deadZone.y : -rig.deadZone.y) }
            r.focus += sideDirection * dot(followed - r.focus, sideDirection)
            let along = dot(r.velocity, right)
            if abs(along) > 0.3 {
                r.lookAhead += ((along > 0 ? rig.lookAhead : -rig.lookAhead) - r.lookAhead) * smoothing(dt, rig.lookAheadTime)
            }
            framed = r.focus + right * r.lookAhead
        }

        // Position damping per world axis.
        let pd = rig.resolvedPositionDamping
        if !first {
            r.pivot.x += (framed.x - r.pivot.x) * smoothing(dt, pd.x)
            r.pivot.y += (framed.y - r.pivot.y) * smoothing(dt, pd.y)
            r.pivot.z += (framed.z - r.pivot.z) * smoothing(dt, pd.z)
        } else {
            r.pivot = framed
        }

        var pose: CameraPose
        var probe: (start: Vec3, end: Vec3)?
        switch rig.mode {
        case .firstPerson:
            var eye = r.pivot
            if rig.headBob > 0, dt > 0 {
                r.bobPhase += speed * dt * rig.headBobFrequency * 2 * .pi
                r.bobPhase = r.bobPhase.truncatingRemainder(dividingBy: 4 * .pi)
                let amount = rig.headBob * min(speed / 4, 1)
                let right = rotation * Vec3(1, 0, 0)
                eye += up * (sinf(r.bobPhase) * amount) + right * (sinf(r.bobPhase * 0.5) * amount * 0.5)
            }
            pose = CameraPose(position: eye, rotation: rotation, fovY: fov)
            // The first-person camera turns the body it looks out of.
            if rig.rotateTarget, control != nil, let targetEntity {
                world.modify(Transform.self, for: targetEntity) {
                    $0.rotation = Quat(angle: (r.yaw + 180) * .pi / 180, axis: up)
                }
            }
        case .thirdPerson:
            let aim = r.pivot + rotation * rig.shoulderOffset
            probe = (r.pivot, aim - forward * r.distance)
            pose = CameraPose(position: probe!.end, rotation: rotation, fovY: fov)
        case .topDown, .sideScroller, .fixed:
            probe = (r.pivot, r.pivot - forward * r.distance)
            pose = CameraPose(position: probe!.end, rotation: rotation, fovY: fov)
        }

        // Collision: a sphere cast from the followed point to the camera.
        r.probeHitPoint = nil
        if let probe {
            var position = probe.end
            if rig.collision, let physics {
                let delta = probe.end - probe.start
                let full = length(delta)
                if full > 1e-4 {
                    let direction = delta / full
                    var allowed = full
                    let ignore = IgnoreSet(target: targetEntity ?? entity, extra: [entity], in: world)
                    if let hit = cast(from: probe.start, direction: direction, distance: full, radius: max(rig.collisionRadius, 0.01),
                                      mask: rig.collisionMask, ignoring: ignore, physics: physics, in: world) {
                        allowed = max(hit.distance, 0)
                        r.probeHitPoint = hit.point
                    }
                    let goal = full - allowed
                    if first {
                        r.pull = goal
                    } else if goal > r.pull {
                        r.pull += (goal - r.pull) * smoothing(dt, rig.pullInTime)
                        // Never more than a collision radius behind the wall.
                        r.pull = max(r.pull, goal - rig.collisionRadius)
                    } else {
                        r.pull += (goal - r.pull) * smoothing(dt, rig.easeOutTime)
                    }
                    r.pull = min(max(r.pull, 0), full)
                    position = probe.start + direction * (full - r.pull)
                }
            } else {
                r.pull = 0
            }
            pose.position = position
            rig.probeStart = probe.start
            rig.probeEnd = probe.end
        } else {
            rig.probeStart = pose.position
            rig.probeEnd = pose.position
        }
        rig.probeHit = r.probeHitPoint != nil
        rig.cameraPosition = pose.position
        r.pose = pose
        rig.runtime = r
        return pose
    }

    /// The entities a rig's collision ignores: everything under the target, under the nearest
    /// ancestor of it with a `CharacterController` or `Ragdoll` (its character, its ragdoll's bone
    /// bodies), and `extra` (the rig and its camera).
    @MainActor struct IgnoreSet {
        var roots: Set<Entity>

        init(target: Entity, extra: [Entity], in world: World) {
            roots = Set(extra)
            roots.insert(target)
            var current: Entity? = target
            while let e = current {
                if world.has(CharacterController.self, for: e) || world.has(Ragdoll.self, for: e) {
                    roots.insert(e)
                    break
                }
                current = world.parent(of: e)
            }
        }

        func contains(_ entity: Entity, in world: World) -> Bool {
            var current: Entity? = entity
            while let e = current {
                if roots.contains(e) { return true }
                current = world.parent(of: e)
            }
            return false
        }
    }

    /// The first hit of a sphere cast that isn't one of the ignored entities' bodies.
    static func cast(from start: Vec3, direction: Vec3, distance: Float, radius: Float, mask: UInt32, ignoring: IgnoreSet,
                     physics: PhysicsWorld, in world: World) -> RaycastHit? {
        var excluded: [BodyID] = []
        for _ in 0..<16 {
            guard let hit = physics.sphereCast(center: start, radius: radius, direction: direction, maxDistance: distance,
                                               filter: QueryFilter(mask: mask, excluding: excluded)) else { return nil }
            if let e = hit.entity, ignoring.contains(e, in: world) {
                excluded.append(hit.body)
                continue
            }
            return hit
        }
        return nil
    }

    /// Where `entity`'s rig would put its camera right now with nothing smoothed (a fresh rig, no
    /// input), with its collision probe against `physics`: what the editor draws for a rig that
    /// isn't running. nil when the entity has no `CameraRig`.
    public static func preview(_ entity: Entity, in world: World, physics: PhysicsWorld?) -> CameraRigProbe? {
        guard var rig = world.get(CameraRig.self, for: entity) else { return nil }
        rig.runtime = CameraRigRuntime()
        let owns = outputCamera(for: rig, entity: entity, in: world) == entity
        let pose = evaluate(&rig, entity: entity, in: world, dt: 0, control: nil, physics: physics, ownsOutput: owns)
        return CameraRigProbe(pose: pose, start: rig.probeStart, end: rig.probeEnd, hit: rig.runtime.probeHitPoint, radius: rig.collisionRadius)
    }

    /// The running rig's pose and probe this frame (nil before the system evaluated it).
    public static func probe(of entity: Entity, in world: World) -> CameraRigProbe? {
        guard let rig = world.get(CameraRig.self, for: entity), let pose = rig.runtime.pose else { return nil }
        return CameraRigProbe(pose: pose, start: rig.probeStart, end: rig.probeEnd, hit: rig.runtime.probeHitPoint, radius: rig.collisionRadius)
    }
}

extension World {
    /// Runs `CameraRig`s (the "cameraRigs" system in `.lateUpdate`) with `input` for orbit, zoom and
    /// recenter. Returns the existing system if there is one.
    @discardableResult
    public func addCameraRigs(input: Input? = nil) -> CameraRigSystem {
        if let existing = CameraRigSystem.system(for: self) {
            if input != nil { existing.input = input }
            return existing
        }
        CameraRig.register()
        let system = CameraRigSystem(world: self, input: input)
        // The closure keeps the system alive while it is installed (the system holds the world weakly).
        addSystem(CameraRigSystem.systemName, stage: .lateUpdate) { _ in system.update() }
        CameraRigSystem.set(system, for: self)
        return system
    }

    /// Removes the "cameraRigs" system (the components stay).
    public func removeCameraRigs() {
        removeSystem(named: CameraRigSystem.systemName)
        CameraRigSystem.set(nil, for: self)
    }

    /// The camera rig system `addCameraRigs` added.
    public var cameraRigs: CameraRigSystem? { CameraRigSystem.system(for: self) }

    /// The rig that drives the camera: the running system's live rig, else the enabled rig with
    /// the highest priority.
    public var liveCameraRig: Entity? {
        if let system = cameraRigs, let live = system.liveRig, isAlive(live) { return live }
        var rigs: [(entity: Entity, rig: CameraRig)] = []
        query(CameraRig.self) { entity, rig in rigs.append((entity, rig)) }
        return CameraRigSystem.pickLive(rigs)
    }

    /// Makes `rig` the live camera rig (enabled, priority above every other rig), blending over
    /// `blendTime` (nil: the rig's `blendTime`). Works without the system too (it only changes the
    /// components). Returns false when `rig` has no `CameraRig`.
    @discardableResult
    public func activateCameraRig(_ rig: Entity, blendTime: Float? = nil) -> Bool {
        if let system = cameraRigs { return system.activate(rig, blendTime: blendTime) }
        return activateCameraRigPriority(rig)
    }

    func activateCameraRigPriority(_ rig: Entity) -> Bool {
        guard has(CameraRig.self, for: rig) else { return false }
        var highest = Int.min
        query(CameraRig.self) { entity, other in
            if entity != rig { highest = max(highest, other.priority) }
        }
        modify(CameraRig.self, for: rig) { r in
            r.enabled = true
            if highest != Int.min, r.priority <= highest { r.priority = highest + 1 }
        }
        return true
    }
}

extension CameraRig {
    /// Registers `CameraRig` with `ComponentRegistry` (scene files name it "CameraRig").
    @MainActor public static func register() {
        ComponentRegistry.register(CameraRig.self)
    }
}
