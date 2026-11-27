import EngineCore

/// Fins for shell fur (Lengyel et al. 2001, "Real-Time Fur over Arbitrary Surfaces"; NVIDIA "Fur
/// using Shells and Fins", 2007): a strip standing on every edge of the furry triangles, rising
/// along the fur, so the silhouette shows strands where the shells, seen edge-on, would show
/// their layers. Built from `GroomGeometry.shells`' mesh (its vertices already carry the comb
/// vector and length factor in the tangent), drawn by fur.glsl as one more fur instance
/// (`params.y` 2): each fin vertex is its edge end's vertex with UV y its height (0 root ... 1
/// tip; the vertex stage grows it like a shell of that height) and UV x the strand coordinate
/// along the edge (`strandsPerSpacing` strands per strand spacing, from a random start per edge).
/// mesh_fur.frag draws strands across UV x and fades fins away from the silhouette, so only the
/// edges whose surface is seen edge-on show. Both windings are emitted (the shell pipeline culls
/// back faces).
public enum GroomFins {
    /// Strips along each fin's height (it bends with the comb and gravity).
    public static let segments = 3
    /// Strands per strand spacing along a fin (fur_strands.glsl's FUR_FIN_DENSITY).
    public static let strandsPerSpacing: Float = 2

    /// The fin mesh of `shells` (`GroomGeometry.shells`' result) for strands `spacing` apart, or
    /// nil when it has no furry edges.
    public static func fins(_ shells: MeshGeometry, spacing: Float) -> MeshGeometry? {
        let spacing = spacing.isFinite && spacing > 1e-6 ? spacing : 0.001
        var seen: Set<UInt64> = []
        var vertices: [MeshVertex] = []
        var skin: [SkinInfluence]? = shells.skin == nil ? nil : []
        var indices: [UInt32] = []
        var t = 0
        var edgeIndex: UInt64 = 0
        while t + 2 < shells.indices.count {
            let tri = [shells.indices[t], shells.indices[t + 1], shells.indices[t + 2]]
            t += 3
            for k in 0..<3 {
                let a = tri[k], b = tri[(k + 1) % 3]
                let key = UInt64(min(a, b)) << 32 | UInt64(max(a, b))
                guard a != b, seen.insert(key).inserted else { continue }
                let va = shells.vertices[Int(a)], vb = shells.vertices[Int(b)]
                // Length factors (tangent.w - 1): an edge without fur gets no fin.
                guard va.tangent.w - 1 > 0.01 || vb.tangent.w - 1 > 0.01 else { continue }
                let edgeLength = length(vb.position - va.position)
                guard edgeLength.isFinite, edgeLength > 0 else { continue }
                edgeIndex &+= 1
                let start = Float((edgeIndex &* 0x9E37_79B9_7F4A_7C15) >> 40) / Float(1 << 24) * 64
                let u0 = start, u1 = start + edgeLength / spacing * strandsPerSpacing
                let first = UInt32(vertices.count)
                for s in 0...segments {
                    let h = Float(s) / Float(segments)
                    for (vertex, u, index) in [(va, u0, a), (vb, u1, b)] {
                        var v = vertex
                        v.uv = Vec2(u, h)
                        vertices.append(v)
                        if let influences = shells.skin, Int(index) < influences.count { skin?.append(influences[Int(index)]) }
                    }
                }
                for s in 0..<UInt32(segments) {
                    let r0 = first + s * 2, r1 = r0 + 2
                    indices += [r0, r0 + 1, r1 + 1, r0, r1 + 1, r1]
                    indices += [r0, r1 + 1, r0 + 1, r0, r1, r1 + 1]
                }
            }
        }
        guard !indices.isEmpty else { return nil }
        if let s = skin, s.count != vertices.count { skin = nil }
        return MeshGeometry(vertices: vertices, indices: indices, skin: skin)
    }
}
