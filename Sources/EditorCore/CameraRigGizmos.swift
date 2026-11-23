import Engine

/// Scene view gizmos for `CameraRig`s: where each rig puts its camera (a small frustum), the
/// followed point and the collision probe from it to where the camera wants to be (a sphere of
/// the cast radius at the camera, red where a wall stops it). While playing they show the running
/// rigs; in edit mode the settled pose (`CameraRigSystem.preview`), with the probe cast against
/// the scene's colliders for selected rigs.
@MainActor
enum CameraRigGizmos {
    /// Colliders for edit-mode probes, kept in step with the world (`syncFromWorld` is incremental).
    private static var editPhysics: (world: ObjectIdentifier, physics: PhysicsWorld)?

    private static func physics(for world: World) -> PhysicsWorld {
        if let cached = editPhysics, cached.world == ObjectIdentifier(world) {
            cached.physics.syncFromWorld(world, dt: 1.0 / 60)
            return cached.physics
        }
        let physics = PhysicsWorld()
        physics.syncFromWorld(world, dt: 1.0 / 60)
        editPhysics = (ObjectIdentifier(world), physics)
        return physics
    }

    static func draw(into draw: DebugDraw, session: EditorSession, labelPosition: (Vec3) -> Vec3, labelSize: Float, labelShadow: Vec4) {
        let world = session.world
        var rigs: [Entity] = []
        world.query(CameraRig.self) { entity, _ in rigs.append(entity) }
        guard !rigs.isEmpty else { return }
        let selected = Set(session.selection.entities(in: world))
        let live = session.isPlaying ? world.liveCameraRig : nil
        let teal = Vec4(0.35, 0.85, 0.95, 1), red = Vec4(1, 0.35, 0.3, 1), dim = Vec4(0.6, 0.65, 0.75, 0.8)
        for entity in rigs {
            guard let rig = world.get(CameraRig.self, for: entity) else { continue }
            let isSelected = selected.contains(entity)
            let probe: CameraRigProbe?
            if session.isPlaying {
                probe = CameraRigSystem.probe(of: entity, in: world)
            } else {
                let physics = isSelected && rig.collision ? physics(for: world) : nil
                probe = CameraRigSystem.preview(entity, in: world, physics: physics)
            }
            guard let probe else { continue }
            let color = entity == live || isSelected ? teal : dim
            let style = DebugDraw.Style(width: isSelected ? 2 : 1.25, depth: .onTop)
            // The camera: a short frustum at its pose.
            let fov = probe.pose.fovY ?? rig.fieldOfView.map { $0 * .pi / 180 } ?? .pi / 3
            let lens = Camera(fovY: fov, near: 0.05, far: 0.6)
            let matrix = Mat4(translation: probe.pose.position, rotation: probe.pose.rotation, scale: .one)
            draw.frustum(viewProjection: lens.projection(aspect: 16 / 9) * Camera.viewMatrix(world: matrix), color: color, style: style)
            guard rig.mode != .fixed, rig.mode != .firstPerson else { continue }
            // The followed point and the probe to where the camera wants to be.
            draw.sphere(center: probe.start, radius: 0.06, color: color, style: style)
            if let hit = probe.hit {
                draw.line(probe.start, probe.pose.position, color: color, style: style)
                draw.line(probe.pose.position, probe.end, color: red, style: DebugDraw.Style(width: 1, depth: .onTop))
                draw.sphere(center: hit, radius: 0.05, color: red, style: style)
            } else {
                draw.line(probe.start, probe.end, color: color, style: style)
            }
            if rig.collision, isSelected || entity == live {
                draw.sphere(center: probe.pose.position, radius: max(probe.radius, 0.02), color: probe.hit == nil ? color : red, style: style)
            }
            if isSelected {
                let label = "\(session.displayName(of: entity)) · \(rig.mode.rawValue)" + (entity == live ? " · live" : "")
                draw.text(label, at: labelPosition(probe.pose.position), color: color, size: labelSize, shadow: labelShadow)
            }
        }
    }
}
