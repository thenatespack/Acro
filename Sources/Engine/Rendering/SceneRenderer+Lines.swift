import Foundation

extension SceneRenderer {
    /// Builds, rebuilds and drops the generated meshes of the world's `LineRenderer`s: a mesh is
    /// rebuilt only when its entity's `LineRenderer.Spec` (path, endpoints and shape parameters)
    /// differs from the one it was built from. Entities that lost the component or despawned
    /// release their mesh.
    func syncLineMeshes(_ world: World) {
        guard !lineMeshes.isEmpty || world.existingStore(LineRenderer.self) != nil else { return }
        var seen: Set<Entity> = []
        var pending: [(Entity, LineRenderer.Spec)] = []
        world.query(GlobalTransform.self, LineRenderer.self) { entity, transform, line in
            seen.insert(entity)
            let spec = line.spec(in: world, worldToLocal: transform.matrix.inverse)
            if lineMeshes[entity] != spec { pending.append((entity, spec)) }
        }
        for (entity, spec) in pending {
            let key = LineRenderer.meshKey(for: entity)
            if let geometry = LineRenderer.geometry(spec) {
                do { try registerMesh(geometry, key: key) } catch { print("SceneRenderer: LineRenderer mesh failed: \(error)") }
            } else {
                unregisterMesh(key: key)
            }
            lineMeshes[entity] = spec
        }
        for entity in lineMeshes.keys where !seen.contains(entity) {
            unregisterMesh(key: LineRenderer.meshKey(for: entity))
            lineMeshes[entity] = nil
        }
    }
}
