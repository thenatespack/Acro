/// The CPU side of `SceneRenderer`, free of GPU resources (and unit-tested on its own):
/// gathering entities into `RenderItem`s (`RenderPrep`), remembering last frame's
/// transforms for motion vectors (`MotionHistory`), and culling, batching and sorting them
/// into instanced draws (`RenderList`).

/// Per-instance data, vertex buffer 1 of the mesh shaders (160 bytes).
public struct MeshInstance: Equatable, Sendable, BitwiseCopyable {
    public var model: Mat4
    /// Last frame's model matrix, for motion vectors (equal to `model` for a still object).
    public var previousModel: Mat4
    /// Linear RGB tint times the material color, a: opacity.
    public var color: Vec4
    /// x: receives shadows (0 / 1).
    public var params: Vec4

    public init(model: Mat4, previousModel: Mat4, color: Vec4, params: Vec4) {
        self.model = model
        self.previousModel = previousModel
        self.color = color
        self.params = params
    }

    static let zero = MeshInstance(model: .identity, previousModel: .identity, color: .zero, params: .zero)

    static let layout = VertexLayout(
        stride: MemoryLayout<MeshInstance>.stride,
        attributes: (0..<8).map { VertexAttribute(location: 3 + $0, format: .float4, offset: $0 * MemoryLayout<Vec4>.stride) } + [
            VertexAttribute(location: 11, format: .float4, offset: MemoryLayout<MeshInstance>.offset(of: \.color)!),
            VertexAttribute(location: 12, format: .float4, offset: MemoryLayout<MeshInstance>.offset(of: \.params)!),
        ])
}

/// Each entity's previous-frame world matrix, so moving objects get motion vectors.
///
/// Keyed by entity slot index and checked against the generation, so despawned entities
/// (and reused slots) never pick up someone else's history. An entry counts only if it
/// was recorded in the immediately preceding frame; otherwise the object is treated as
/// still (it just appeared or wasn't drawn last frame).
public struct MotionHistory: Sendable {
    struct Slot: Sendable {
        var generation: UInt32
        var frame: Int
        var matrix: Mat4
    }

    private var slots: [Slot] = []
    public private(set) var frame = 0

    public init() {}

    /// Starts a new frame; call once before the frame's `previousMatrix` calls.
    public mutating func beginFrame() { frame += 1 }

    /// Forgets all history (camera cuts, teleports): next frame nothing has motion.
    public mutating func reset() { frame += 1 }

    /// Returns `entity`'s matrix from the previous frame (or `current` if there is none) and
    /// records `current` for the next frame.
    public mutating func previousMatrix(for entity: Entity, current: Mat4) -> Mat4 {
        let index = Int(entity.index)
        if index >= slots.count {
            slots.append(contentsOf: repeatElement(Slot(generation: .max, frame: .min, matrix: .identity),
                                                   count: max(index + 1 - slots.count, slots.count)))
        }
        return withUnsafeMutablePointer(to: &slots[index]) { slot in
            let previous = slot.pointee.generation == entity.generation && slot.pointee.frame == frame - 1
                ? slot.pointee.matrix : current
            slot.pointee = Slot(generation: entity.generation, frame: frame, matrix: current)
            return previous
        }
    }
}

/// One entity to draw this frame, resolved from its components.
public struct RenderItem: Sendable {
    public var entity: Entity
    public var mesh: Int
    public var material: Int
    public var instance: MeshInstance
    /// World-space bounds.
    public var bounds: Bounds
    public var castsShadows: Bool
    public var transparent: Bool
    /// The material is alpha-tested (`MaterialTraits.alphaTested`), so its shadow batch keeps it.
    public var alphaTested: Bool
    /// Index into `RenderPrep.skins` for a skinned mesh (drawn in a batch of its own), else -1.
    public var skin: Int

    public init(entity: Entity, mesh: Int, material: Int, instance: MeshInstance, bounds: Bounds,
                castsShadows: Bool, transparent: Bool, alphaTested: Bool = false, skin: Int = -1) {
        self.entity = entity
        self.mesh = mesh
        self.material = material
        self.instance = instance
        self.bounds = bounds
        self.castsShadows = castsShadows
        self.transparent = transparent
        self.alphaTested = alphaTested
        self.skin = skin
    }
}

/// Collects a world's `MeshRenderer`s into `RenderItem`s and finds its camera, light and
/// environment. Mesh and material handles resolve through `meshes` (local bounds) and
/// `materials` (whether the material blends or is alpha-tested); entities naming unknown keys are skipped.
/// Entities drawing a mesh in `skinnedMeshes` get this frame's joint matrices (`skins`, from
/// their `Skin`) and bounds around the posed mesh.
@MainActor
public struct RenderPrep {
    public var meshes = AssetRegistry<Bounds>()
    public var materials = AssetRegistry<MaterialTraits>()
    /// Skinned meshes by mesh id.
    public var skinnedMeshes: [Int: SkinnedMeshInfo] = [:]
    public var motion = MotionHistory()
    public var skinHistory = SkinHistory()
    /// Poses skinned meshes in parallel (the result doesn't depend on its thread count).
    public var jobs = JobSystem.shared
    public private(set) var items: [RenderItem] = []
    /// The joint matrices of this frame's skinned items (`RenderItem.skin`).
    public private(set) var skins: [SkinPose] = []
    /// Keys entities referenced that aren't registered (reported once by the renderer).
    public private(set) var missingKeys: Set<String> = []
    /// The same, split by what the entity wanted the key for.
    public private(set) var missingMeshKeys: Set<String> = []
    public private(set) var missingMaterialKeys: Set<String> = []

    public init() {}

    /// Rebuilds `items` from every visible entity with a `GlobalTransform` and a
    /// `MeshRenderer`, and advances the motion history by one frame.
    public mutating func gather(world: World) {
        motion.beginFrame()
        items.removeAll(keepingCapacity: true)
        skins.removeAll(keepingCapacity: true)
        world.query(GlobalTransform.self, MeshRenderer.self) { entity, transform, renderer in
            guard renderer.isVisible else { return }
            let mesh = meshes.id(of: renderer.mesh.key), material = materials.id(of: renderer.material.key)
            guard let mesh, let material else {
                if mesh == nil {
                    missingKeys.insert(renderer.mesh.key)
                    missingMeshKeys.insert(renderer.mesh.key)
                }
                if material == nil {
                    missingKeys.insert(renderer.material.key)
                    missingMaterialKeys.insert(renderer.material.key)
                }
                return
            }
            let model = transform.matrix
            let previous = motion.previousMatrix(for: entity, current: model)
            var skin = -1
            if !skinnedMeshes.isEmpty, let info = skinnedMeshes[mesh] {
                // Posed below, in parallel.
                skin = skins.count
                skins.append(SkinPose(joints: [], previousJoints: []))
                pendingSkins.append(PendingSkin(item: items.count, entity: entity, model: model, skin: world.get(Skin.self, for: entity),
                                                info: info))
            }
            items.append(RenderItem(
                entity: entity, mesh: mesh, material: material,
                instance: MeshInstance(model: model, previousModel: previous, color: Vec4(renderer.tint, renderer.opacity),
                                       params: Vec4(renderer.receivesShadows ? 1 : 0, 0, 0, 0)),
                bounds: meshes[mesh].transformed(by: model),
                castsShadows: renderer.castsShadows,
                transparent: renderer.opacity < 1 || materials[material].blends,
                alphaTested: materials[material].alphaTested,
                skin: skin))
        }
        gatherLines(world: world)
        poseSkins(world: world)
    }

    /// Adds an item for every visible `LineRenderer` whose generated mesh is registered under
    /// `LineRenderer.meshKey(for:)` (`SceneRenderer.syncLineMeshes`).
    private mutating func gatherLines(world: World) {
        world.query(GlobalTransform.self, LineRenderer.self) { entity, transform, line in
            guard line.isVisible, let mesh = meshes.id(of: LineRenderer.meshKey(for: entity)),
                  let material = materials.id(of: line.material.key) else {
                if !materials.contains(line.material.key) {
                    missingKeys.insert(line.material.key)
                    missingMaterialKeys.insert(line.material.key)
                }
                return
            }
            let model = transform.matrix
            let previous = motion.previousMatrix(for: entity, current: model)
            items.append(RenderItem(
                entity: entity, mesh: mesh, material: material,
                instance: MeshInstance(model: model, previousModel: previous, color: Vec4(line.tint, line.opacity),
                                       params: Vec4(line.receivesShadows ? 1 : 0, 0, 0, 0)),
                bounds: meshes[mesh].transformed(by: model),
                castsShadows: line.castsShadows,
                transparent: line.opacity < 1 || materials[material].blends,
                alphaTested: materials[material].alphaTested,
                skin: -1))
        }
    }

    /// A skinned item waiting for its joint matrices.
    private struct PendingSkin {
        var item: Int
        var entity: Entity
        var model: Mat4
        var skin: Skin?
        var info: SkinnedMeshInfo
    }
    private var pendingSkins: [PendingSkin] = []

    /// Computes the joint matrices and posed bounds of this frame's skinned items on `jobs`
    /// (each reads only its joints' `GlobalTransform`s), then records the history in item order.
    private mutating func poseSkins(world: World) {
        guard !pendingSkins.isEmpty else { return }
        defer { pendingSkins.removeAll(keepingCapacity: true) }
        let pending = pendingSkins
        let transforms = world.existingStore(GlobalTransform.self)?.view
        let posed = jobs.parallelMap(pending.count, batchSize: 16, name: "skin poses") { k -> (joints: [Mat4], bounds: Bounds?) in
            let p = pending[k]
            let joints = SkinPose.joints(of: p.skin, meshWorld: p.model, jointCount: p.info.jointCount) { joint in
                guard let transforms, let dense = transforms.denseIndex(of: joint) else { return nil }
                return transforms.values[dense].matrix
            }
            return (joints, SkinPose.bounds(p.info.jointBounds, joints: joints))
        }
        for (k, (p, pose)) in zip(pending, posed).enumerated() {
            let previousJoints = skinHistory.previousJoints(for: p.entity, current: pose.joints, frame: motion.frame)
            skins[k] = SkinPose(joints: pose.joints, previousJoints: previousJoints)
            if let bounds = pose.bounds { items[p.item].bounds = bounds.transformed(by: p.model) }
        }
    }

    /// The camera to render from: `preferred` if it has a `Camera`, else the active camera
    /// with the lowest entity index.
    public static func findCamera(in world: World, preferred: Entity? = nil) -> (entity: Entity, camera: Camera, world: Mat4)? {
        func worldMatrix(_ entity: Entity) -> Mat4 {
            world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
        }
        if let preferred, let camera = world.get(Camera.self, for: preferred) {
            return (preferred, camera, worldMatrix(preferred))
        }
        var best: (entity: Entity, camera: Camera)?
        world.query(Camera.self) { entity, camera in
            guard camera.isActive else { return }
            if best == nil || entity.index < best!.entity.index { best = (entity, camera) }
        }
        return best.map { ($0.entity, $0.camera, worldMatrix($0.entity)) }
    }

    /// The directional light with the lowest entity index, with its world matrix.
    public static func findLight(in world: World) -> (light: DirectionalLight, world: Mat4)? {
        var best: (entity: Entity, light: DirectionalLight)?
        world.query(DirectionalLight.self) { entity, light in
            if best == nil || entity.index < best!.entity.index { best = (entity, light) }
        }
        return best.map { ($0.light, world.get(GlobalTransform.self, for: $0.entity)?.matrix ?? world.worldMatrix(of: $0.entity)) }
    }

    /// The `SceneEnvironment` with the lowest entity index, or the defaults.
    public static func findEnvironment(in world: World) -> SceneEnvironment {
        var best: (entity: Entity, environment: SceneEnvironment)?
        world.query(SceneEnvironment.self) { entity, environment in
            if best == nil || entity.index < best!.entity.index { best = (entity, environment) }
        }
        return best?.environment ?? SceneEnvironment()
    }
}

/// Decides which shadow casters can affect the image: a caster must be inside the light's
/// frustum, and the volume its shadow can fall in (its box swept away from the light down
/// to the lowest receiver) must intersect the camera's frustum.
public struct ShadowCasterCulling: Sendable {
    public var lightFrustum: Frustum
    /// Unit direction toward the light.
    public var toLight: Vec3
    /// The lowest y of any shadow receiver: shadows can't land below it.
    public var receiverFloor: Float
    /// Longest sweep, for grazing light (the shadow frustum's depth is a good bound).
    public var maxSweep: Float

    public init(lightFrustum: Frustum, toLight: Vec3, receiverFloor: Float, maxSweep: Float) {
        self.lightFrustum = lightFrustum
        self.toLight = toLight
        self.receiverFloor = receiverFloor
        self.maxSweep = maxSweep
    }

    public func castsVisibleShadow(_ bounds: Bounds, view: Frustum) -> Bool {
        guard lightFrustum.intersects(center: bounds.center, halfExtent: bounds.halfExtent) else { return false }
        let drop = bounds.center.y + bounds.halfExtent.y - receiverFloor
        let length = toLight.y > 0 ? min(max(drop, 0) / toLight.y, maxSweep) : maxSweep
        return view.intersects(center: bounds.center, halfExtent: bounds.halfExtent, sweptBy: -toLight * length)
    }
}

/// A run of instances in `RenderList.instances` drawn with one mesh and material.
public struct RenderBatch: Equatable, Sendable {
    public var mesh: Int
    /// -1 for shadow batches drawn depth only (any material); alpha-tested shadow batches keep theirs.
    public var material: Int
    public var first: Int
    public var count: Int
    /// The skinned item's `RenderItem.skin` (its batch has one instance), else -1.
    public var skin: Int

    public init(mesh: Int, material: Int, first: Int, count: Int, skin: Int = -1) {
        self.mesh = mesh
        self.material = material
        self.first = first
        self.count = count
        self.skin = skin
    }
}

/// Counters from the last `RenderList.build`.
public struct RenderListStats: Equatable, Sendable {
    public var items = 0
    public var opaque = 0
    public var transparent = 0
    /// Outside the camera's frustum.
    public var culled = 0
    public var shadowCasters = 0
    /// Casters skipped because their shadow can't be seen.
    public var culledShadowCasters = 0
    public var drawCalls = 0
}

/// One frame's draws: culled, grouped into instanced batches and sorted.
///
/// `instances` holds every instance once per pass that draws it, laid out as opaque
/// batches, then the transparent ones, then the shadow batches, so it can be uploaded in
/// one copy. Opaque batches group by (mesh, material) in order of first appearance;
/// transparent instances are sorted back to front by the distance from the camera to their
/// bounds' center (ties by entity index), and consecutive ones sharing mesh and material
/// share a batch. Shadow batches group casters by mesh, and alpha-tested ones by mesh and
/// material (their batch keeps the material, others have -1). Skinned items get a batch each.
public struct RenderList {
    public private(set) var instances: [MeshInstance] = []
    public private(set) var opaque: [RenderBatch] = []
    public private(set) var transparent: [RenderBatch] = []
    public private(set) var shadow: [RenderBatch] = []
    public private(set) var stats = RenderListStats()

    // Scratch, kept between frames to avoid reallocating.
    private var slotOfItem: [Int32] = []
    private var shadowSlotOfItem: [Int32] = []
    private var transparentItems: [(item: Int32, distance: Float)] = []
    private var opaqueSlots: [Int: Int] = [:]
    private var shadowSlots: [Int: Int] = [:]
    private var visibility: [UInt8] = []
    /// Runs the visibility tests (in batches of 4096 items; the result doesn't depend on its
    /// thread count).
    public var jobs = JobSystem.shared

    public init() {}

    /// Culls and batches `items` for a camera seeing `view` from `cameraPosition`, plus, with
    /// `shadows`, the casters whose shadow it can see. `cameraBatches: false` builds only the
    /// shadow batches (opaque and transparent stay empty, and nothing counts as culled).
    public mutating func build(items: [RenderItem], view: Frustum, cameraPosition: Vec3, shadows: ShadowCasterCulling?,
                               cameraBatches: Bool = true) {
        stats = RenderListStats(items: items.count)
        opaque.removeAll(keepingCapacity: true)
        transparent.removeAll(keepingCapacity: true)
        shadow.removeAll(keepingCapacity: true)
        transparentItems.removeAll(keepingCapacity: true)
        opaqueSlots.removeAll(keepingCapacity: true)
        shadowSlots.removeAll(keepingCapacity: true)
        slotOfItem.removeAll(keepingCapacity: true)
        slotOfItem.append(contentsOf: repeatElement(-1, count: items.count))
        shadowSlotOfItem.removeAll(keepingCapacity: true)
        shadowSlotOfItem.append(contentsOf: repeatElement(-1, count: items.count))

        // Visibility tests first, in parallel: one flag byte per item (1: in view, 2: casts a
        // visible shadow).
        visibility.removeAll(keepingCapacity: true)
        visibility.append(contentsOf: repeatElement(0, count: items.count))
        let jobs = self.jobs
        visibility.withUnsafeMutableBufferPointer { flags in
            jobs.parallelFor(items.indices, batchSize: 4096, name: "cull") { range in
                for i in range {
                    let item = items[i]
                    var flag: UInt8 = 0
                    if cameraBatches && view.intersects(center: item.bounds.center, halfExtent: item.bounds.halfExtent) { flag |= 1 }
                    if let shadows, item.castsShadows, shadows.castsVisibleShadow(item.bounds, view: view) { flag |= 2 }
                    flags[i] = flag
                }
            }
        }

        // Classify and count, in item order. `count` of each batch is used as a counter here.
        var lastKey = Int.min, lastSlot = -1
        for (i, item) in items.enumerated() {
            if shadows != nil, item.castsShadows {
                if visibility[i] & 2 != 0 {
                    let slot: Int
                    // Alpha-tested casters need their material; the rest share a depth-only batch per mesh.
                    let material = item.alphaTested ? item.material : -1
                    let key = item.mesh << 32 | (material & 0xffff_ffff)
                    if item.skin < 0, let existing = shadowSlots[key] {
                        slot = existing
                    } else {
                        slot = shadow.count
                        if item.skin < 0 { shadowSlots[key] = slot }
                        shadow.append(RenderBatch(mesh: item.mesh, material: material, first: 0, count: 0, skin: item.skin))
                    }
                    shadow[slot].count += 1
                    shadowSlotOfItem[i] = Int32(slot)
                    stats.shadowCasters += 1
                } else {
                    stats.culledShadowCasters += 1
                }
            }
            guard cameraBatches else { continue }
            guard visibility[i] & 1 != 0 else {
                stats.culled += 1
                continue
            }
            if item.transparent {
                let d = item.bounds.center - cameraPosition
                transparentItems.append((Int32(i), dot(d, d)))
                continue
            }
            let key = item.skin < 0 ? item.mesh << 32 | item.material : Int.min
            let slot: Int
            if key == lastKey && item.skin < 0 {
                slot = lastSlot
            } else if item.skin < 0, let existing = opaqueSlots[key] {
                slot = existing
            } else {
                slot = opaque.count
                if item.skin < 0 { opaqueSlots[key] = slot }
                opaque.append(RenderBatch(mesh: item.mesh, material: item.material, first: 0, count: 0, skin: item.skin))
            }
            lastKey = key
            lastSlot = slot
            opaque[slot].count += 1
            slotOfItem[i] = Int32(slot)
        }

        // Back to front; ties by entity so the order is stable across runs and backends.
        transparentItems.sort {
            if $0.distance != $1.distance { return $0.distance > $1.distance }
            return items[Int($0.item)].entity.index < items[Int($1.item)].entity.index
        }

        // Lay out: opaque batches, transparent runs, shadow batches.
        var next = 0
        for slot in opaque.indices {
            opaque[slot].first = next
            next += opaque[slot].count
        }
        let transparentStart = next
        next += transparentItems.count
        for slot in shadow.indices {
            shadow[slot].first = next
            next += shadow[slot].count
        }
        stats.opaque = transparentStart
        stats.transparent = transparentItems.count

        instances.removeAll(keepingCapacity: true)
        instances.append(contentsOf: repeatElement(.zero, count: next))
        instances.withUnsafeMutableBufferPointer { out in
            var opaqueFill = opaque.map(\.first), shadowFill = shadow.map(\.first)
            for i in items.indices {
                let slot = Int(slotOfItem[i])
                if slot >= 0 {
                    out[opaqueFill[slot]] = items[i].instance
                    opaqueFill[slot] += 1
                }
                let shadowSlot = Int(shadowSlotOfItem[i])
                if shadowSlot >= 0 {
                    out[shadowFill[shadowSlot]] = items[i].instance
                    shadowFill[shadowSlot] += 1
                }
            }
            for (n, entry) in transparentItems.enumerated() {
                let item = items[Int(entry.item)]
                out[transparentStart + n] = item.instance
                if let last = transparent.last, last.mesh == item.mesh, last.material == item.material, last.skin < 0, item.skin < 0 {
                    transparent[transparent.count - 1].count += 1
                } else {
                    transparent.append(RenderBatch(mesh: item.mesh, material: item.material, first: transparentStart + n, count: 1,
                                                   skin: item.skin))
                }
            }
        }
        stats.drawCalls = opaque.count + transparent.count + shadow.count
    }
}
