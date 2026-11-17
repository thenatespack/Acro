import Foundation
import Dispatch
import EngineCore
import EngineScene

// Blending between a sculpt's looks (MeshBuildSculptLooks.swift splits a sculpt with several looks
// into a mesh per look): where the children's surfaces meet with a `smooth` join, their looks melt
// into each other over a band instead of changing at a line.
//
// - The band: each boundary point (a cut point of `splitByOwner`) gets a half-width from the
//   `smooth` of the join there (that of the later of the two children whose surfaces are closest,
//   as the field melts the later child into what came before): `bandScale` x smooth, at least
//   `minimumBand`; a sharp join (smooth 0) keeps its sharp line. A multi-source Dijkstra over the
//   mesh's edges, from every boundary point and only into the two groups it divides, gives each
//   vertex within the band its distance d to the nearest boundary (in half-widths, t = d / h).
// - Weights: a vertex of group o that far from a boundary with group n weighs n by
//   1 - smoothstep(-1, 1, t) (0.5 on the boundary, 0 at the band's edge) and o by the rest; a
//   boundary point weighs both 0.5, a triangle center between three groups each a third. They
//   ride through the importer in the mesh's `VertexPaint` (`weight(of:)`: color xyzw and surface
//   xyzw are the weights of groups 0-7; groups from 8 on don't blend), which interpolates them
//   like any vertex attribute, until `MeshBuildImporter.finishBlends` turns them into real paint.
// - Looks with the same textures (`lookTextureKey`: the same look, look scale, wear, grain,
//   texture...) blend in the vertex paint: each vertex gets the weighted mix of the groups'
//   material values (base color, roughness, metallic, emission). The piece's material holds the
//   largest of each (per channel) and the paint the factor down to the vertex's value, so the
//   pieces meet with equal values on the boundary.
// - Different textures cross-fade: for each group, a blend layer (a part "<sculpt>/<child> blend")
//   draws the triangles of the other looks' pieces where it has weight, with its own look and the
//   weight as opacity (alpha blended, depth tested less-or-equal on the very surface it covers, so
//   there is no dithering to shimmer and no sorting between the layers). The layer copies its
//   surface's baked occlusion and has no edge wear of its own.
// - Not blended: groups with a `material` asset (its values can't be changed) or with opacity below
//   1 (a transparent look can't be layered): their boundaries stay sharp.
// Everything is linear in the mesh (the Dijkstra only visits the band) and the per-point work is parallel.

enum MeshBuildSculptBlend {
    /// The band's half-width per meter of `smooth`.
    static let bandScale: Float = 0.75
    /// The narrowest band's half-width (meters): even a small `smooth` softens the line a little.
    static let minimumBand: Float = 0.004
    /// Groups whose weights fit in a `VertexPaint`.
    static let maxGroups = 8

    /// The half-width of the band around a join of `smooth` meters (0: a sharp line).
    static func halfWidth(smooth: Float) -> Float {
        smooth > 0 && smooth.isFinite ? max(smooth * bandScale, minimumBand) : 0
    }

    /// The weight a vertex `t` half-widths from a boundary gives the group across it.
    static func across(_ t: Float) -> Float {
        let x = min(max((t + 1) / 2, 0), 1)
        return 1 - x * x * (3 - 2 * x)
    }

    /// Group `g`'s weight in `paint` (the importer's weight encoding, see the notes above).
    static func weight(_ paint: VertexPaint, group g: Int) -> Float {
        guard g >= 0, g < maxGroups else { return 0 }
        return g < 4 ? paint.color[g] : paint.surface[g - 4]
    }

    static func setWeight(_ paint: inout VertexPaint, group g: Int, _ w: Float) {
        guard g >= 0, g < maxGroups else { return }
        if g < 4 { paint.color[g] = w } else { paint.surface[g - 4] = w }
    }

    /// No weights: the vertex is its own group's.
    static let unweighted = VertexPaint(color: .zero, surface: .zero)
}

// MARK: - Weights

extension MeshBuildSculptor {
    /// Each surface vertex's group weights after `splitByOwner` (see the notes at the top of this
    /// file), or nil when no boundary blends.
    func blendWeights(_ surface: Surface, _ split: OwnerSplit) -> [VertexPaint]? {
        let base = split.vertexGroup.count, cuts = split.cutEdges.count
        let positions = surface.positions, total = positions.count
        guard cuts > 0 else { return nil }
        // Each boundary point's half-width, from the smooth of the join there (in parallel).
        var halfWidth = [Float](repeating: 0, count: cuts)
        let chunk = 256
        halfWidth.withUnsafeMutableBufferPointer { buffer in
            let out = buffer
            concurrentPerform(iterations: (cuts + chunk - 1) / chunk) { c in
                for e in (c * chunk)..<min((c + 1) * chunk, cuts) {
                    let edge = split.cutEdges[e]
                    let ga = split.vertexGroup[Int(edge.x)], gb = split.vertexGroup[Int(edge.y)]
                    let p = positions[base + e], b = bump(p)
                    var best = (Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude), index = (-1, -1)
                    for i in primitives.indices where groups[i] == ga || groups[i] == gb {
                        let s = ownerScore(i, p, bump: b)
                        if groups[i] == ga, s < best.0 { (best.0, index.0) = (s, i) }
                        if groups[i] == gb, s < best.1 { (best.1, index.1) = (s, i) }
                    }
                    let later = max(index.0, index.1)
                    out[e] = later >= 0 ? MeshBuildSculptBlend.halfWidth(smooth: primitives[later].smooth) : 0
                }
            }
        }
        guard halfWidth.contains(where: { $0 > 0 }) else { return nil }

        // Vertex neighbors (compressed rows).
        var start = [Int32](repeating: 0, count: total + 1)
        for t in surface.triangles { for k in 0..<3 { start[Int(t[k]) + 1] += 2 } }
        for v in 0..<total { start[v + 1] += start[v] }
        var fill = Array(start.dropLast())
        var neighbors = [Int32](repeating: 0, count: Int(start[total]))
        for t in surface.triangles {
            for k in 0..<3 {
                let v = Int(t[k])
                neighbors[Int(fill[v])] = t[(k + 1) % 3]
                neighbors[Int(fill[v]) + 1] = t[(k + 2) % 3]
                fill[v] += 2
            }
        }

        // Distance to the nearest blending boundary, in its half-widths, within the band.
        var best = [Float](repeating: 1, count: total)
        var source = [Int32](repeating: -1, count: total)
        var heap = MinHeap()
        for e in 0..<cuts where halfWidth[e] > 0 {
            best[base + e] = 0
            source[base + e] = Int32(e)
            heap.push(0, Int32(base + e))
        }
        while let (t, v) = heap.pop() {
            guard t <= best[Int(v)] else { continue }
            let s = Int(source[Int(v)])
            let edge = split.cutEdges[s]
            let ga = split.vertexGroup[Int(edge.x)], gb = split.vertexGroup[Int(edge.y)]
            let pv = positions[Int(v)]
            for k in Int(start[Int(v)])..<Int(start[Int(v) + 1]) {
                let u = Int(neighbors[k])
                // Only into the two groups this boundary divides, and within one group's region.
                guard u < base else { continue }
                let gu = split.vertexGroup[u]
                guard gu == ga || gu == gb, Int(v) >= base || split.vertexGroup[Int(v)] == gu else { continue }
                let d = positions[u] - pv
                let next = t + (d.x * d.x + d.y * d.y + d.z * d.z).squareRoot() / halfWidth[s]
                if next < best[u] {
                    best[u] = next
                    source[u] = Int32(s)
                    heap.push(next, Int32(u))
                }
            }
        }

        var weights = [VertexPaint](repeating: MeshBuildSculptBlend.unweighted, count: total)
        for v in 0..<total {
            let s = Int(source[v])
            guard s >= 0 else { continue }
            let edge = split.cutEdges[s]
            let ga = Int(split.vertexGroup[Int(edge.x)]), gb = Int(split.vertexGroup[Int(edge.y)])
            if v >= base {
                MeshBuildSculptBlend.setWeight(&weights[v], group: ga, 0.5)
                MeshBuildSculptBlend.setWeight(&weights[v], group: gb, 0.5)
            } else {
                let own = Int(split.vertexGroup[v])
                let other = own == ga ? gb : ga
                let w = MeshBuildSculptBlend.across(best[v])
                MeshBuildSculptBlend.setWeight(&weights[v], group: own, 1 - w)
                MeshBuildSculptBlend.setWeight(&weights[v], group: other, w)
            }
        }
        // A center between three groups: a third each, when a boundary next to it blends.
        for (m, g) in split.centers {
            let v = Int(m)
            let blends = (Int(start[v])..<Int(start[v + 1])).contains { source[Int(neighbors[$0])] >= 0 && Int(neighbors[$0]) >= base }
            guard blends else { continue }
            for k in 0..<3 { MeshBuildSculptBlend.setWeight(&weights[v], group: Int(g[k]), 1.0 / 3) }
        }
        return weights
    }
}

/// A binary min-heap of (key, vertex) for the band's Dijkstra.
private struct MinHeap {
    private var keys: [Float] = []
    private var values: [Int32] = []

    mutating func push(_ key: Float, _ value: Int32) {
        keys.append(key)
        values.append(value)
        var i = keys.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard keys[i] < keys[parent] else { break }
            keys.swapAt(i, parent)
            values.swapAt(i, parent)
            i = parent
        }
    }

    mutating func pop() -> (Float, Int32)? {
        guard let first = keys.first else { return nil }
        let value = values[0]
        let lastKey = keys.removeLast(), lastValue = values.removeLast()
        if !keys.isEmpty {
            keys[0] = lastKey
            values[0] = lastValue
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < keys.count, keys[l] < keys[m] { m = l }
                if r < keys.count, keys[r] < keys[m] { m = r }
                guard m != i else { break }
                keys.swapAt(i, m)
                values.swapAt(i, m)
                i = m
            }
        }
        return (first, value)
    }
}

// MARK: - Groups and layers

extension MeshBuildPart {
    /// The look fields that choose a look's textures and their mapping (equal: the looks blend in
    /// the vertex paint; different: they cross-fade with a blend layer).
    var lookTextureKey: String {
        let base = "\(texture)|\(textureScale)|\(worldUV)|\(material)"
        guard resolvedLook != nil || resolvedLeafLook != nil else { return base }
        return base + "|\(String(describing: resolvedLook))|\(String(describing: resolvedLeafLook))|\(effectiveLookScale)|"
            + "\(MeshBuildLookTextures.wearLevel(wear))|\(lookGrainAxis)"
    }

    /// Whether a sculpt look of these fields can blend: no `material` asset, and opaque.
    var blendsLook: Bool {
        let defaults = MeshBuildPart()
        let opacity = opacity == defaults.opacity ? resolvedLook?.defaultOpacity ?? 1 : opacity
        return material.trimmingCharacters(in: .whitespaces).isEmpty && opacity >= 1
    }
}

/// How one sculpt's look groups blend (for `MeshBuildImporter.finishBlends`).
public struct MeshBuildSculptBlendGroups: Sendable {
    /// Per group: the index of its piece (the part drawing its mesh), nil when it has none.
    public var pieces: [Int?]
    /// Per group: the index of its blend layer part, nil when it has none.
    public var layers: [Int?]
    /// Per group: its texture class (groups of one class blend in the vertex paint).
    public var classes: [Int]
    /// Per group: whether it blends at all.
    public var blends: [Bool]

    /// Whether group `h`'s values blend into group `o`'s piece through its paint.
    func paints(_ h: Int, into o: Int) -> Bool {
        h != o && blends[h] && blends[o] && classes[h] == classes[o]
    }
}

extension MeshBuildSculptMesh {
    /// Group `g`'s blend layer: the triangles of the other looks' pieces (those `crossFades`
    /// accepts) where `g` has weight, or nil when there are none.
    func blendLayer(group g: Int, crossFades: (Int) -> Bool) -> MeshGeometry? {
        guard let paint = geometry.paint, g < MeshBuildSculptBlend.maxGroups, !triangleGroups.isEmpty else { return nil }
        let indices = geometry.indices
        let layer = triangles { t in
            guard crossFades(Int(triangleGroups[t])) else { return false }
            return (0..<3).contains { MeshBuildSculptBlend.weight(paint[Int(indices[t * 3 + $0])], group: g) > 0 }
        }
        return layer.indices.isEmpty ? nil : layer
    }
}
