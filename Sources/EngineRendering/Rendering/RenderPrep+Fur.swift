/// The CPU side of fur (Groom.swift): `RenderPrep.gather` adds, after an entity's own item, the
/// items of its `GroomRenderer` (the undercoat and one per shell, or the cards at this detail
/// level), all sharing the entity's transform, skin and (grown) bounds, so its shells batch into
/// one instanced draw with every other copy of that mesh and groom. A few shells (or the cards)
/// also cast shadows (`GroomRenderer.castsShadows`), as alpha-tested casters keeping their
/// material, so the shadow atlas draws them with mesh_fur_depth. It also runs the fur's
/// secondary motion: a damped spring per entity (rigid meshes) or per joint (skinned), pulled
/// toward a lag behind its velocity, so fur trails and settles when its owner moves.
import EngineAssets
import EngineCore
import EngineScene

/// One fur spring: its lag (world meters) and velocity, and where its point was last frame.
struct FurSpring: Sendable {
    var offset = Vec3.zero
    var velocity = Vec3.zero
    var lastPosition: Vec3?
    var lastVelocity = Vec3.zero

    /// Advances the spring by `dt` seconds with its point now at `position`; `limit` caps the lag.
    mutating func step(to position: Vec3, dt: Float, limit: Float) {
        guard dt > 0, let last = lastPosition else {
            lastPosition = position
            return
        }
        let pointVelocity = (position - last) / dt
        lastPosition = position
        lastVelocity = pointVelocity
        // Strands lag 0.06 s behind where their root went, springing back with some overshoot.
        let target = -pointVelocity * 0.06
        let k: Float = 70, damping: Float = 2 * k.squareRoot() * 0.3
        var remaining = min(dt, 0.25)
        while remaining > 0 {
            let h = min(remaining, 1 / 120)
            velocity += ((target - offset) * k - velocity * damping) * h
            offset += velocity * h
            remaining -= h
        }
        let l = length(offset)
        if l > limit { offset *= limit / l }
        if !offset.x.isFinite || !offset.y.isFinite || !offset.z.isFinite { self = FurSpring(lastPosition: position) }
    }
}

/// The fur springs of one entity: one (rigid) or one per joint (skinned).
struct FurSprings: Sendable {
    var springs: [FurSpring] = []
    var time: Float = -1
    var frame = 0
}

/// The items of one entity's fur in `RenderPrep.items`.
struct FurGroup: Sendable {
    var base: Int
    var first: Int
    var count: Int
    /// Meters the fur reaches past the base's bounds.
    var pad: Float
}

extension RenderPrep {
    /// Adds the fur items of `groom` for the item at `base` (just appended) drawing `meshKey`.
    mutating func appendFur(_ groom: GroomRenderer, base: Int, meshKey: String, entity: Entity) {
        guard let material = materials.id(of: groom.groom.key) else {
            if !groom.groom.key.isEmpty {
                missingKeys.insert(groom.groom.key)
                missingMaterialKeys.insert(groom.groom.key)
            }
            return
        }
        guard let fur = materials[material].fur else { return }  // still loading (placeholder)
        let item = items[base]
        let model = item.instance.model
        let scale = max(length(Vec3(model.c0.x, model.c0.y, model.c0.z)), length(Vec3(model.c1.x, model.c1.y, model.c1.z)),
                        length(Vec3(model.c2.x, model.c2.y, model.c2.z)))
        let pad = fur.length * scale * 1.5
        let distance = lodViewpoint.map { MeshLOD.distance(from: $0, to: item.bounds) } ?? 0
        let level = fur.level(distance: distance)
        let bounds = Bounds(center: item.bounds.center, halfExtent: item.bounds.halfExtent + Vec3(repeating: pad))
        let receives: Float = groom.receivesShadows && item.instance.params.x > 0.5 ? 1 : 0
        let casts = groom.castsShadows && item.castsShadows
        let color = Vec4(groom.tint, 1)
        let first = items.count
        func add(mesh: Int, height: Float, castsShadows: Bool = false) {
            items.append(RenderItem(
                entity: entity, mesh: mesh, material: material,
                instance: MeshInstance(model: model, previousModel: item.instance.previousModel, color: color,
                                       params: Vec4(receives, height, 0, 0)),
                bounds: bounds, castsShadows: castsShadows, transparent: false, alphaTested: castsShadows, skin: item.skin))
        }
        let shellKey = GroomRenderer.meshKey("shell", tag: fur.tag, base: meshKey)
        guard let shell = meshes.id(of: shellKey) else { return }  // SceneRenderer.syncGroomMeshes builds it
        if fur.style == .shell, level < fur.shellLevels.count {
            // Outer shells first, so the depth test rejects what the tips cover.
            let n = max(fur.shellLevels[level], 1)
            let casters = casts ? Self.furShadowShells(n) : []
            for i in stride(from: n, through: 1, by: -1) { add(mesh: shell, height: Float(i) / Float(n), castsShadows: casters.contains(i)) }
        }
        add(mesh: shell, height: 0)
        if fur.style != .shell, level < fur.cardLevels.count,
           let cards = meshes.id(of: GroomRenderer.meshKey("cards\(level)", tag: fur.tag, base: meshKey)) {
            add(mesh: cards, height: 1, castsShadows: casts)
        }
        furGroups.append(FurGroup(base: base, first: first, count: items.count - first, pad: pad))
    }

    /// The shells (1...n) of an n-shell groom that cast shadows: those nearest 0.35 and 0.75 of
    /// the length (their strands widened in mesh_fur_depth.frag to stand for the shells between).
    static func furShadowShells(_ n: Int) -> Set<Int> {
        guard n > 0 else { return [] }
        return [max(1, Int((Float(n) * 0.35).rounded())), max(1, Int((Float(n) * 0.75).rounded()))]
    }

    /// After the skins are posed: grows each fur group's bounds with its base's (posed) bounds and
    /// steps the springs (rigid ones go into the items' params.zw, skinned ones to `furSkinSprings`).
    mutating func finishFur(world: World) {
        guard !furGroups.isEmpty else {
            if !furSpringState.isEmpty { furSpringState.removeAll() }
            return
        }
        furFrame += 1
        let time = furTime
        for group in furGroups {
            let base = items[group.base]
            let bounds = Bounds(center: base.bounds.center, halfExtent: base.bounds.halfExtent + Vec3(repeating: group.pad))
            for k in group.first..<(group.first + group.count) { items[k].bounds = bounds }
            guard group.count > 0 else { continue }
            let limit = max(group.pad * 0.6, 1e-3)
            var state = furSpringState[base.entity] ?? FurSprings()
            let dt = state.time < 0 ? 0 : time - state.time
            if state.frame == furFrame {
                // A second fur group on the same entity (several grooms): reuse this frame's springs.
            } else if base.skin >= 0, base.skin < skins.count {
                let pose = skins[base.skin]
                let info = skinnedMeshes[base.mesh]
                let count = min(pose.joints.count, SkinPose.maxJoints)
                if state.springs.count != count { state.springs = Array(repeating: FurSpring(), count: count) }
                let model = base.instance.model
                for j in 0..<count {
                    let center = info.flatMap { j < $0.jointBounds.count ? $0.jointBounds[j]?.center : nil } ?? .zero
                    let p = model * (pose.joints[j] * Vec4(center, 1))
                    state.springs[j].step(to: Vec3(p.x, p.y, p.z), dt: dt, limit: limit)
                }
            } else {
                if state.springs.count != 1 { state.springs = [FurSpring()] }
                let c = base.instance.model.c3
                state.springs[0].step(to: Vec3(c.x, c.y, c.z), dt: dt, limit: limit)
            }
            if state.frame != furFrame { state.time = time }
            state.frame = furFrame
            furSpringState[base.entity] = state
            if base.skin >= 0 {
                furSkinSprings[base.skin] = state.springs.map { Vec4($0.offset, 0) }
            } else if let spring = state.springs.first {
                for k in group.first..<(group.first + group.count) {
                    items[k].instance.params.z = spring.offset.x
                    items[k].instance.params.w = spring.offset.z
                }
            }
        }
        if furSpringState.count > 2 * furGroups.count + 32 { furSpringState = furSpringState.filter { $0.value.frame == furFrame } }
    }
}
