/// Simulated card hair (HairSimulation.swift) in the renderer: after each gather, every entity
/// drawing card hair at detail level 0 or 1 (`hairSimulatedLevels`; level 1 steps every other
/// frame) steps its simulation and rewrites its cards in world space into a mesh of its own
/// ("groom:sim:<entity>"), whose second vertex stream (the `VertexPaint` slot) holds last
/// frame's positions for the motion vectors. The card item then draws that mesh unskinned with
/// an identity transform and color w -1 (fur.glsl: nothing more bends it), with
/// mesh_fur_sim.vert in the scene pass and the plain fur casters in the shadow atlas. The new
/// vertices are copied to the GPU in `renderShadows` / `beginViews`, before the frame's passes.
/// Farther levels keep the springs.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

extension SceneRenderer {
    /// One entity's simulated hair and its mesh.
    final class HairState {
        var simulation: HairSimulation
        let meshKey: String
        var mesh: Int
        /// This frame's card vertices (world space) and last frame's positions.
        var vertices: [MeshVertex]
        var previous: [VertexPaint]
        /// Vertices and indices drawn at the current level.
        var vertexCount = 0
        var indexCount = 0
        var time: Float = -1
        var frame = 0
        var level = -1
        var needsUpload = false

        init(simulation: HairSimulation, meshKey: String, mesh: Int, vertexCount: Int) {
            self.simulation = simulation
            self.meshKey = meshKey
            self.mesh = mesh
            // (Tangents set, so registering the mesh doesn't generate them.)
            vertices = Array(repeating: MeshVertex(position: .zero, normal: Vec3(0, 0, 1), tangent: Vec4(0, -1, 0, 2)), count: vertexCount)
            previous = Array(repeating: VertexPaint(color: .zero, surface: .zero), count: vertexCount)
        }
    }

    /// Card detail levels simulated (farther ones bend with the springs).
    static let hairSimulatedLevels = 2

    /// Steps the hair of every card groom drawn this frame and points its card item at the
    /// simulated mesh. Call after the frame's last gather.
    func stepHair() {
        let start = ContinuousClock.now
        defer {
            let d = ContinuousClock.now - start
            hairSimulationSeconds = Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18
        }
        hairFrame += 1
        guard simulatesHair else {
            if !hairStates.isEmpty { dropHair(all: true) }
            return
        }
        let wind = windState.wind
        let direction = wind.horizontalDirection
        let simWind = HairSimulation.Wind(direction: Vec3(direction.x, 0, direction.y), strength: wind.effectiveStrength,
                                          gustiness: wind.effectiveGustiness)
        let time = prep.furTime
        for group in prep.furGroups where group.cards >= 0 && group.level < Self.hairSimulatedLevels {
            let item = prep.items[group.cards]
            let base = prep.items[group.base]
            guard let rig = furMeshes[group.pair]?.rig, let fur = materials[item.material].material.fur,
                  group.level < fur.groom.cardLevels.count else { continue }
            var state = hairStates[item.entity]
            if state == nil || state!.simulation.rig !== rig {
                if let old = state { unregisterMesh(key: old.meshKey) }
                state = makeHairState(rig: rig, entity: item.entity)
                hairStates[item.entity] = state
            }
            guard let state else { continue }
            if state.frame != hairFrame {
                state.frame = hairFrame
                let dt = state.time < 0 ? 0 : time - state.time
                // Level 1 steps every other frame.
                if group.level == 0 || hairFrame % 2 == 0 || state.time < 0 || state.level != group.level {
                    state.time = time
                    let joints = base.skin >= 0 && base.skin < prep.skins.count ? prep.skins[base.skin].joints : nil
                    state.simulation.step(model: base.instance.model, joints: joints, dt: dt, time: time, wind: simWind, jobs: prep.jobs)
                    writeHairCards(state, fur: fur, level: group.level)
                }
            }
            guard state.indexCount > 0 else { continue }
            meshes[state.mesh].indexCount = state.indexCount
            var moved = item
            moved.mesh = state.mesh
            moved.skin = -1
            moved.instance.model = .identity
            moved.instance.previousModel = .identity
            moved.instance.color.w = -1
            moved.instance.params.z = 0
            moved.instance.params.w = 0
            prep.items[group.cards] = moved
        }
        dropHair(all: false)
    }

    /// Registers the simulated mesh of `entity` for `rig` (every guide's card, world space).
    private func makeHairState(rig: HairRig, entity: Entity) -> HairState? {
        let key = "groom:sim:\(entity.index).\(entity.generation)"
        var indices: [UInt32] = []
        var vertex: UInt32 = 0
        for g in 0..<rig.guideCount {
            let n = rig.first[g + 1] - rig.first[g]
            guard n >= 2 else { continue }
            for k in 1..<n {
                let a = vertex + UInt32((k - 1) * 2), b = a + 1, c = a + 2, d = a + 3
                indices += [a, c, b, b, c, d]
            }
            vertex += UInt32(n * 2)
        }
        guard vertex > 0 else { return nil }
        var simulation = HairSimulation(rig: rig)
        simulation.follow = 0.7
        let state = HairState(simulation: simulation, meshKey: key, mesh: 0, vertexCount: Int(vertex))
        let geometry = MeshGeometry(vertices: state.vertices, indices: indices, paint: state.previous)
        do {
            try registerMesh(geometry, key: key)
        } catch {
            print("SceneRenderer: simulated hair mesh failed: \(error)")
            return nil
        }
        guard let id = prep.meshes.id(of: key) else { return nil }
        state.mesh = id
        return state
    }

    /// Rewrites `state`'s card vertices for detail level `level` from its simulated guides.
    private func writeHairCards(_ state: HairState, fur: MaterialFur, level: Int) {
        let rig = state.simulation.rig
        let fraction = fur.groom.cardLevels[level]
        let count = GroomGeometry.cardCount(guides: rig.guideCount, fraction: fraction)
        var vertices = 0, indices = 0
        for g in 0..<min(count, rig.guideCount) {
            let n = rig.first[g + 1] - rig.first[g]
            guard n >= 2 else { continue }
            vertices += n * 2
            indices += (n - 1) * 6
        }
        // Last frame's positions (the same vertices only when the level didn't change).
        let continuous = state.level == level && state.vertexCount == vertices
        if continuous {
            for v in 0..<vertices { state.previous[v].color = Vec4(state.vertices[v].position, 1) }
        }
        state.vertices.withUnsafeMutableBufferPointer { out in
            state.simulation.writeCards(count: count, width: GroomGeometry.cardWidth(fur: fur, fraction: fraction),
                                        taper: GroomGeometry.clamp01(fur.groom.cardTaper), into: out.baseAddress!, jobs: prep.jobs)
        }
        if !continuous {
            for v in 0..<vertices { state.previous[v].color = Vec4(state.vertices[v].position, 1) }
        }
        state.vertexCount = vertices
        state.indexCount = indices
        state.level = level
        state.needsUpload = true
    }

    /// Forgets the hair of entities not drawn for a while (all of it with `all`).
    private func dropHair(all: Bool) {
        let stale = hairStates.filter { all || hairFrame - $0.value.frame > 120 }
        for (entity, state) in stale {
            unregisterMesh(key: state.meshKey)
            hairStates[entity] = nil
        }
    }

    /// Copies this frame's simulated card vertices to the GPU. Between passes, before the first.
    func uploadHair(frame: Frame) {
        for state in hairStates.values where state.needsUpload {
            state.needsUpload = false
            guard state.mesh < meshes.count, let paint = meshes[state.mesh].paintBuffer, state.vertexCount > 0 else { continue }
            do {
                try state.vertices.withUnsafeBytes {
                    try device.updateBuffer(meshes[state.mesh].vertexBuffer, offset: 0,
                                            bytes: UnsafeRawBufferPointer(rebasing: $0.prefix(state.vertexCount * MemoryLayout<MeshVertex>.stride)))
                }
                try state.previous.withUnsafeBytes {
                    try device.updateBuffer(paint, offset: 0,
                                            bytes: UnsafeRawBufferPointer(rebasing: $0.prefix(state.vertexCount * MemoryLayout<VertexPaint>.stride)))
                }
            } catch {
                print("SceneRenderer: simulated hair upload failed: \(error)")
            }
        }
    }
}
