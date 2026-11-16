import Engine
import Foundation

// Mesh build results report plants' detail levels (MeshBuildLOD.swift): triangles per level and
// the distances where they take over, read from the imported prefab's `MeshLOD`s.

extension MeshBuildResult {
    /// Triangles drawn at each detail level of `prefab` (full detail first; one entry without
    /// levels) and the levels' distances (nil without levels). A node's level without a mesh of
    /// its own (merged into another node's, or hidden behind the impostor) adds nothing.
    @MainActor static func levelTriangles(_ prefab: PrefabAsset, assets: AssetDatabase) -> (triangles: [Int], distances: [Float]?) {
        var nodes: [PrefabNode] = []
        var stack = prefab.roots
        while let node = stack.popLast() {
            nodes.append(node)
            stack += node.children
        }
        let levels = nodes.reduce(0) { max($0, $1.lod?.levelCount ?? 0) }
        var cache: [String: Int] = [:]
        func triangles(_ key: String) -> Int {
            guard !key.isEmpty, let reference = AssetReference(key) else { return 0 }
            if let hit = cache[key] { return hit }
            let count = (assets.mesh(reference)?.indices.count ?? 0) / 3
            cache[key] = count
            return count
        }
        var totals = [Int](repeating: 0, count: levels + 1)
        var distances: [Float]?
        for node in nodes {
            guard let mesh = node.mesh else { continue }
            let base = MeshHandle(mesh)
            for level in 0...levels {
                totals[level] += triangles((node.lod?.mesh(level: min(level, node.lod?.levelCount ?? 0), base: base) ?? base).key)
            }
            if distances == nil, let lod = node.lod, lod.levelCount == levels, levels > 0 { distances = Array(lod.distances.prefix(levels)) }
        }
        return (totals, distances)
    }
}
