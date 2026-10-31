import Foundation

/// The vertex format of `SceneRenderer` meshes (vertex buffer 0).
public struct MeshVertex: Equatable, Sendable, BitwiseCopyable {
    public var position: Vec3
    public var normal: Vec3
    public var uv: Vec2
    /// xyz: the direction of increasing U, w: ±1, the handedness of the tangent frame: the
    /// bitangent (toward decreasing V, "up" in the texture) is `cross(normal, tangent.xyz) * w`
    /// (glTF `TANGENT`). All zero when unknown; `SceneRenderer.registerMesh` then generates
    /// them (`MeshGeometry.generateTangents()`).
    public var tangent: Vec4

    public init(position: Vec3, normal: Vec3, uv: Vec2 = .zero, tangent: Vec4 = .zero) {
        self.position = position
        self.normal = normal
        self.uv = uv
        self.tangent = tangent
    }

    static let layout = VertexLayout(
        stride: MemoryLayout<MeshVertex>.stride,
        attributes: [
            VertexAttribute(location: 0, format: .float3, offset: MemoryLayout<MeshVertex>.offset(of: \.position)!),
            VertexAttribute(location: 1, format: .float3, offset: MemoryLayout<MeshVertex>.offset(of: \.normal)!),
            VertexAttribute(location: 2, format: .float2, offset: MemoryLayout<MeshVertex>.offset(of: \.uv)!),
            VertexAttribute(location: 13, format: .float4, offset: MemoryLayout<MeshVertex>.offset(of: \.tangent)!),
        ])
}

/// An axis-aligned box as center and half-extent.
public struct Bounds: Equatable, Sendable {
    public var center: Vec3
    public var halfExtent: Vec3

    public init(center: Vec3, halfExtent: Vec3) {
        self.center = center
        self.halfExtent = halfExtent
    }

    /// The smallest box around `points` (a zero box at the origin when empty).
    public init<S: Sequence>(enclosing points: S) where S.Element == Vec3 {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for p in points {
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        center = (lo + hi) / 2
        halfExtent = (hi - lo) / 2
    }

    /// The axis-aligned box around this box transformed by the affine matrix `m`.
    @inlinable public func transformed(by m: Mat4) -> Bounds {
        let c = m.c0 * center.x + m.c1 * center.y + m.c2 * center.z + m.c3
        let ax = Vec3(abs(m.c0.x), abs(m.c0.y), abs(m.c0.z))
        let ay = Vec3(abs(m.c1.x), abs(m.c1.y), abs(m.c1.z))
        let az = Vec3(abs(m.c2.x), abs(m.c2.y), abs(m.c2.z))
        return Bounds(center: Vec3(c.x, c.y, c.z), halfExtent: ax * halfExtent.x + ay * halfExtent.y + az * halfExtent.z)
    }
}

/// Mesh data on the CPU: triangles with counter-clockwise front faces. Register it with
/// `SceneRenderer.registerMesh(_:key:)` to upload it.
public struct MeshGeometry: Sendable {
    public var vertices: [MeshVertex]
    public var indices: [UInt32]

    public init(vertices: [MeshVertex], indices: [UInt32]) {
        self.vertices = vertices
        self.indices = indices
    }

    /// Bounds of the vertex positions.
    public var bounds: Bounds { Bounds(enclosing: vertices.lazy.map(\.position)) }

    /// A cube of size `size` centered on the origin, with per-face normals and 0–1 UVs on each face.
    public static func cube(size: Float = 1) -> MeshGeometry {
        let h = size / 2
        // (normal, u, v) with u × v = normal, so each face winds counter-clockwise from outside.
        let x = Vec3(1, 0, 0), y = Vec3(0, 1, 0), z = Vec3(0, 0, 1)
        let faces = [(x, -z, y), (-x, z, y), (y, x, -z), (-y, x, z), (z, x, y), (-z, -x, y)]
        var geometry = MeshGeometry(vertices: [], indices: [])
        for (n, u, v) in faces {
            let base = UInt32(geometry.vertices.count)
            for (a, b) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
                geometry.vertices.append(MeshVertex(
                    position: (n + u * a + v * b) * h, normal: n, uv: Vec2((a + 1) / 2, (1 - b) / 2)))
            }
            geometry.indices += [base, base + 1, base + 2, base, base + 2, base + 3]
        }
        return geometry
    }

    /// A single-sided `size` x `size` plane in XZ facing +Y, centered on the origin, split into
    /// `segments` x `segments` quads.
    public static func plane(size: Float = 1, segments: Int = 1) -> MeshGeometry {
        precondition(segments >= 1)
        var geometry = MeshGeometry(vertices: [], indices: [])
        let n = segments + 1
        for j in 0..<n {
            for i in 0..<n {
                let u = Float(i) / Float(segments), v = Float(j) / Float(segments)
                geometry.vertices.append(MeshVertex(
                    position: Vec3((u - 0.5) * size, 0, (v - 0.5) * size), normal: Vec3(0, 1, 0), uv: Vec2(u, v)))
            }
        }
        for j in 0..<segments {
            for i in 0..<segments {
                let a = UInt32(j * n + i), b = a + 1, c = a + UInt32(n), d = c + 1
                // Counter-clockwise seen from +Y: a (−x,−z), c (−x,+z), d (+x,+z), b (+x,−z).
                geometry.indices += [a, c, d, a, d, b]
            }
        }
        return geometry
    }

    /// A UV sphere of `radius` centered on the origin, with `segments` slices around Y and
    /// `rings` stacks from pole to pole.
    public static func sphere(radius: Float = 0.5, segments: Int = 32, rings: Int = 16) -> MeshGeometry {
        precondition(segments >= 3 && rings >= 2)
        var geometry = MeshGeometry(vertices: [], indices: [])
        for ring in 0...rings {
            let v = Float(ring) / Float(rings)
            let theta = v * .pi  // from +Y down
            for segment in 0...segments {
                let u = Float(segment) / Float(segments)
                let phi = u * 2 * .pi
                let n = Vec3(sinf(theta) * sinf(phi), cosf(theta), sinf(theta) * cosf(phi))
                geometry.vertices.append(MeshVertex(position: n * radius, normal: n, uv: Vec2(u, v)))
            }
        }
        let stride = UInt32(segments + 1)
        for ring in 0..<UInt32(rings) {
            for segment in 0..<UInt32(segments) {
                let a = ring * stride + segment, b = a + 1, c = a + stride, d = c + 1
                // Counter-clockwise seen from outside: a (top, φ), c (below), d (below, φ+), b (top, φ+).
                if ring != 0 { geometry.indices += [a, c, b] }
                if ring != UInt32(rings) - 1 { geometry.indices += [b, c, d] }
            }
        }
        return geometry
    }
}

// MARK: - Tangents

extension MeshGeometry {
    /// Whether every vertex has a tangent frame (a nonzero handedness in `tangent.w`).
    public var hasTangents: Bool { !vertices.isEmpty && vertices.allSatisfy { $0.tangent.w != 0 } }

    /// Computes `MeshVertex.tangent` for every vertex from positions, normals and UVs, in the
    /// spirit of MikkTSpace: each triangle corner contributes its UV gradient direction
    /// (∂p/∂u for the tangent, ∂p/∂v for the handedness), projected onto the vertex's normal
    /// plane, normalized and weighted by the corner's angle; the sum is orthonormalized
    /// against the normal. Unlike MikkTSpace, vertices are never split, so a vertex shared by
    /// triangles with mirrored UVs gets one averaged frame. Vertices without usable UVs get an
    /// arbitrary tangent perpendicular to their normal.
    public mutating func generateTangents() {
        let count = vertices.count
        var tangents = [Vec3](repeating: .zero, count: count)
        var bitangents = [Vec3](repeating: .zero, count: count)
        for t in stride(from: 0, to: indices.count - 2, by: 3) {
            let corners = (Int(indices[t]), Int(indices[t + 1]), Int(indices[t + 2]))
            let ids = [corners.0, corners.1, corners.2]
            let p = ids.map { vertices[$0].position }, uv = ids.map { vertices[$0].uv }
            let e1 = p[1] - p[0], e2 = p[2] - p[0]
            let d1 = uv[1] - uv[0], d2 = uv[2] - uv[0]
            let det = d1.x * d2.y - d2.x * d1.y
            guard abs(det) > 1e-12, det.isFinite else { continue }
            // ∂p/∂u and ∂p/∂v of the triangle's planar UV mapping.
            let dpdu = (e1 * d2.y - e2 * d1.y) / det
            let dpdv = (e2 * d1.x - e1 * d2.x) / det
            for k in 0..<3 {
                let a = p[(k + 1) % 3] - p[k], b = p[(k + 2) % 3] - p[k]
                let la = length(a), lb = length(b)
                guard la > 0, lb > 0 else { continue }
                let angle = acosf(min(max(dot(a, b) / (la * lb), -1), 1))
                let n = vertices[ids[k]].normal
                let tu = dpdu - n * dot(n, dpdu), tv = dpdv - n * dot(n, dpdv)
                let lu = length(tu), lv = length(tv)
                if lu > 0, lu.isFinite { tangents[ids[k]] += tu / lu * angle }
                if lv > 0, lv.isFinite { bitangents[ids[k]] += tv / lv * angle }
            }
        }
        for i in 0..<count {
            let n = vertices[i].normal
            var t = tangents[i] - n * dot(n, tangents[i])
            var len = length(t)
            if !(len > 1e-8) || !len.isFinite {
                // No UV gradient: any direction in the normal's plane.
                t = abs(n.x) < 0.9 ? cross(n, Vec3(1, 0, 0)) : cross(n, Vec3(0, 1, 0))
                t = cross(t, n)
                len = length(t)
                if !(len > 0) { t = Vec3(1, 0, 0); len = 1 }
            }
            t /= len
            // The shader's bitangent cross(n, t) * w must point toward decreasing V.
            let w: Float = dot(cross(n, t), bitangents[i]) > 0 ? -1 : 1
            vertices[i].tangent = Vec4(t, w)
        }
    }

    /// A copy with tangents generated where they are missing (`hasTangents` false).
    public func withTangents() -> MeshGeometry {
        if hasTangents { return self }
        var copy = self
        copy.generateTangents()
        return copy
    }
}
