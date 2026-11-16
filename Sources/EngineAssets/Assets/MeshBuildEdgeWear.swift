import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// Edge wear for mesh build parts with a look and `wear`: their convex edges and corners blend
// toward the look's worn variant (`MeshBuildLook.edgeWear`): paint chipped to bare metal or wood,
// lighter rubbed edges on wood, stone and leather, polished edges on rusty and plain metal.
//
// Per part, in its own space, after the occlusion bake's tessellation:
//
// 1. Convex edges: mesh edges (vertices welded by position) between two triangles that bend
//    away from each other. An edge's strength is how much the surface turns within one band
//    width across it (the angle between the most tilted normals of the triangles on each side), so
//    a 90° box edge, a hexagon's 60° edges and the rows of a rounded bevel count, but the many
//    shallow edges of a smooth cylinder or sphere don't (smoothstep from about 26° to 57°).
// 2. Every vertex's edge coordinate e = max over edges (strength - distance / band width), plus
//    a third of the second best edge running another way (corners wear more), in -24...1.5.
//    Linear in the distance, so it interpolates exactly across a flat triangle: an unbevelled box
//    face cut into a few large triangles still gets a sharp band along its edges.
// 3. e rides in the tangent's component along the normal (`EdgeWear.encode`), which the shader
//    projects away before using the tangent; its material's `EdgeWear` turns it on.
//
// The band width grows with the part (5% of its middle dimension, 4 mm to 3 cm, at most a third
// of its thinnest) and with wear (half at wear 0, full at 1).

/// Mesh build edge wear (see the notes at the top of this file).
enum MeshBuildEdgeWear {
    /// The band width for a part whose mesh is `size` meters across, at `wear` 0...1.
    /// `look`'s `edgeWidthScale` widens or narrows it.
    static func bandWidth(size: Vec3, wear: Float, look: MeshBuildLook) -> Float {
        let dims = [abs(size.x), abs(size.y), abs(size.z)].sorted()
        let base = min(min(max(dims[1] * 0.05, 0.004), 0.03) * look.edgeWidthScale, max(dims[0] / 3, 0.001))
        return base * (0.5 + 0.5 * min(max(wear, 0), 1))
    }

    /// A convex edge: a segment and how strongly it reads as an edge (0...1).
    struct Edge {
        var a: Vec3
        var b: Vec3
        var strength: Float
    }

    /// The convex edges of `geometry` for a band `width` meters wide.
    static func convexEdges(_ geometry: MeshGeometry, width: Float) -> [Edge] {
        let vertices = geometry.vertices, indices = geometry.indices
        guard !vertices.isEmpty, indices.count >= 6 else { return [] }
        // Weld by position.
        let b = geometry.bounds
        let quantum = max(max(b.halfExtent.x, b.halfExtent.y, b.halfExtent.z) * 2e-5, 1e-7)
        var welded = [Int](repeating: 0, count: vertices.count)
        var points: [Vec3] = []
        var ids: [SIMD3<Int32>: Int] = [:]
        for (i, v) in vertices.enumerated() {
            let p = v.position
            let key = SIMD3<Int32>(Int32(clamping: Int((p.x / quantum).rounded())), Int32(clamping: Int((p.y / quantum).rounded())),
                                   Int32(clamping: Int((p.z / quantum).rounded())))
            if let id = ids[key] {
                welded[i] = id
            } else {
                ids[key] = points.count
                welded[i] = points.count
                points.append(p)
            }
        }
        // Triangles' normals, and each undirected edge's triangles (with the corner opposite it).
        struct Key: Hashable { var lo: Int; var hi: Int }
        var faces: [Vec3] = []
        var centroids: [Vec3] = []
        var areas: [Float] = []
        var edges: [Key: [(face: Int, opposite: Int)]] = [:]
        for t in stride(from: 0, to: indices.count - 2, by: 3) {
            let c = [welded[Int(indices[t])], welded[Int(indices[t + 1])], welded[Int(indices[t + 2])]]
            guard c[0] != c[1], c[1] != c[2], c[0] != c[2] else { continue }
            let n = cross(points[c[1]] - points[c[0]], points[c[2]] - points[c[0]])
            let area = length(n)
            guard area > quantum * quantum, area.isFinite else { continue }
            let face = faces.count
            faces.append(n / area)
            centroids.append((points[c[0]] + points[c[1]] + points[c[2]]) / 3)
            areas.append(area / 2)
            for k in 0..<3 {
                let i = c[k], j = c[(k + 1) % 3]
                edges[Key(lo: min(i, j), hi: max(i, j)), default: []].append((face, c[(k + 2) % 3]))
            }
        }
        // Convex bends.
        struct Bend { var a: Vec3; var b: Vec3; var faces: (Int, Int) }
        var bends: [Bend] = []
        for (key, sides) in edges where sides.count == 2 {
            let n1 = faces[sides[0].face], n2 = faces[sides[1].face]
            guard dot(n1, n2) < 0.9975 else { continue }  // about 4°
            let a = points[key.lo]
            // Convex: each triangle's far corner is behind the other's plane.
            guard dot(n1, points[sides[1].opposite] - a) < 0, dot(n2, points[sides[0].opposite] - a) < 0 else { continue }
            bends.append(Bend(a: a, b: points[key.hi], faces: (sides[0].face, sides[1].face)))
        }
        guard !bends.isEmpty else { return [] }
        // Strength: how far the surface turns across a window a band width to each side: the
        // angle between the most tilted normals of the triangles there (its own two always
        // included; surfaces facing away, like the far side of a thin part, are left out). A
        // grid of triangle centers finds them.
        let cell = max(width, quantum * 10)
        func cellOf(_ p: Vec3) -> SIMD3<Int32> {
            SIMD3(Int32(clamping: Int((p.x / cell).rounded(.down))), Int32(clamping: Int((p.y / cell).rounded(.down))),
                  Int32(clamping: Int((p.z / cell).rounded(.down))))
        }
        var grid: [SIMD3<Int32>: [Int]] = [:]
        for (i, c) in centroids.enumerated() { grid[cellOf(c), default: []].append(i) }
        // Each bend's strength on its own (all cores): nil where it doesn't count.
        var found = [Edge?](repeating: nil, count: bends.count)
        found.withUnsafeMutableBufferPointer { out in
            let slots = out
            DispatchQueue.concurrentPerform(iterations: bends.count) { k in
            let bend = bends[k]
            let axis = bend.b - bend.a
            let len = length(axis)
            guard len > 0 else { return }
            let dir = axis / len
            let n1 = faces[bend.faces.0], n2 = faces[bend.faces.1]
            let mean = normalize(n1 + n2)
            // Across the edge, pointing to the first triangle's side.
            var across = cross(dir, mean)
            if dot(across, centroids[bend.faces.0] - bend.a) < 0 { across = -across }
            var first = n1, second = n2
            let lo = cellOf(pointwiseMin(bend.a, bend.b) - Vec3(repeating: width))
            let hi = cellOf(pointwiseMax(bend.a, bend.b) + Vec3(repeating: width))
            if (Int(hi.x) - Int(lo.x) + 1) * (Int(hi.y) - Int(lo.y) + 1) * (Int(hi.z) - Int(lo.z) + 1) <= 4096 {
                for z in lo.z...hi.z {
                    for y in lo.y...hi.y {
                        for x in lo.x...hi.x {
                            for f in grid[SIMD3(x, y, z)] ?? [] where f != bend.faces.0 && f != bend.faces.1 {
                                let n = faces[f], tilt = dot(n, mean)
                                guard tilt > -0.2, distance(centroids[f], bend.a, bend.b) <= width else { continue }
                                if dot(centroids[f] - bend.a, across) >= 0 {
                                    if tilt < dot(first, mean) { first = n }
                                } else if tilt < dot(second, mean) {
                                    second = n
                                }
                            }
                        }
                    }
                }
            }
            let turn = acosf(min(max(dot(first, second), -1), 1))
            let strength = smoothstep(0.45, 1.0, turn)
            if strength > 0.01 { slots[k] = Edge(a: bend.a, b: bend.b, strength: strength) }
            }
        }
        return found.compactMap { $0 }
    }

    @inline(__always) static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Distance from `p` to the segment `a`-`b`.
    @inline(__always) static func distance(_ p: Vec3, _ a: Vec3, _ b: Vec3) -> Float {
        let ab = b - a
        let l2 = dot(ab, ab)
        let t = l2 > 0 ? min(max(dot(p - a, ab) / l2, 0), 1) : 0
        return length(p - (a + ab * t))
    }

    /// Every vertex's edge coordinate (see the notes at the top of this file) for edges of band `width`.
    static func coordinates(_ geometry: MeshGeometry, edges: [Edge], width: Float) -> [Float] {
        let far = EdgeWear.minimum
        guard !edges.isEmpty, width > 0 else { return [Float](repeating: far, count: geometry.vertices.count) }
        // A vertex needs its exact (linear) value only while one of its triangles can reach into the
        // band, so look no further than the band plus the longest triangle edge (and never past the
        // floor). Big flat triangles keep the full reach; dense meshes (sculpts) look only nearby
        // instead of comparing every vertex with every edge.
        var longest: Float = 0
        let v = geometry.vertices, ix = geometry.indices
        for t in stride(from: 0, to: ix.count - 2, by: 3) {
            let a = v[Int(ix[t])].position, b = v[Int(ix[t + 1])].position, c = v[Int(ix[t + 2])].position
            longest = max(longest, dot(b - a, b - a), dot(c - b, c - b), dot(a - c, a - c))
        }
        let reach = min(width * (1 - far), width * EdgeWear.maximum + longest.squareRoot())
        let cell = reach
        func cellOf(_ p: Vec3) -> SIMD3<Int32> {
            SIMD3(Int32(clamping: Int((p.x / cell).rounded(.down))), Int32(clamping: Int((p.y / cell).rounded(.down))),
                  Int32(clamping: Int((p.z / cell).rounded(.down))))
        }
        // Each edge in every cell its padded box touches.
        var grid: [SIMD3<Int32>: [Int]] = [:]
        for (i, edge) in edges.enumerated() {
            let lo = cellOf(pointwiseMin(edge.a, edge.b) - Vec3(repeating: reach)), hi = cellOf(pointwiseMax(edge.a, edge.b) + Vec3(repeating: reach))
            guard (Int(hi.x) - Int(lo.x) + 1) * (Int(hi.y) - Int(lo.y) + 1) * (Int(hi.z) - Int(lo.z) + 1) <= 4096 else {
                grid[SIMD3(Int32.min, 0, 0), default: []].append(i)  // too long: checked by every vertex
                continue
            }
            for z in lo.z...hi.z { for y in lo.y...hi.y { for x in lo.x...hi.x { grid[SIMD3(x, y, z), default: []].append(i) } } }
        }
        let always = grid[SIMD3(Int32.min, 0, 0)] ?? []
        let directions = edges.map { normalize($0.b - $0.a) }
        let vertices = geometry.vertices
        var result = [Float](repeating: far, count: vertices.count)
        result.withUnsafeMutableBufferPointer { out in
            let slots = out
            DispatchQueue.concurrentPerform(iterations: (vertices.count + 255) / 256) { chunk in
                var candidates: [(Float, Int)] = []
                for vi in chunk * 256..<min(vertices.count, chunk * 256 + 256) {
                    let p = vertices[vi].position
                    var best = far, bestEdge = -1
                    candidates.removeAll(keepingCapacity: true)
                    func consider(_ i: Int) {
                        let edge = edges[i]
                        let e = edge.strength - distance(p, edge.a, edge.b) / width
                        guard e > far else { return }
                        candidates.append((e, i))
                        if e > best { best = e; bestEdge = i }
                    }
                    for i in grid[cellOf(p)] ?? [] { consider(i) }
                    for i in always { consider(i) }
                    // Corners: the best edge running another way adds a third.
                    var second = far
                    if bestEdge >= 0 {
                        let bestDir = directions[bestEdge]
                        for (e, i) in candidates where abs(dot(directions[i], bestDir)) < 0.7 { second = max(second, e) }
                    }
                    slots[vi] = min(max(best + max(second, 0) / 3, far), EdgeWear.maximum)
                }
            }
        }
        return result
    }

    /// Writes edge coordinates `e` into the tangents (generating tangents first): xyz becomes the
    /// unit tangent made perpendicular to the normal plus the normal x `EdgeWear.encode(e)`.
    static func store(_ e: [Float], in geometry: inout MeshGeometry) {
        guard e.count == geometry.vertices.count else { return }
        if !geometry.hasTangents { geometry.generateTangents() }
        for i in geometry.vertices.indices {
            let v = geometry.vertices[i]
            let n = length(v.normal) > 1e-8 ? normalize(v.normal) : Vec3(0, 1, 0)
            var t = Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
            t -= n * dot(n, t)
            if length(t) < 1e-6 { t = cross(n, abs(n.x) < 0.9 ? Vec3(1, 0, 0) : Vec3(0, 1, 0)) }
            t = normalize(t) + n * EdgeWear.encode(e[i])
            geometry.vertices[i].tangent = Vec4(t, v.tangent.w)
        }
    }

    /// Computes and stores the edge coordinates of a part's mesh for `wear` of `look`.
    static func apply(to geometry: inout MeshGeometry, wear: Float, look: MeshBuildLook) {
        let b = geometry.bounds
        let width = bandWidth(size: b.halfExtent * 2, wear: wear, look: look)
        let edges = convexEdges(geometry, width: width)
        store(coordinates(geometry, edges: edges, width: width), in: &geometry)
    }
}

extension MeshBuildLook {
    /// Scales the edge wear band: rubbed wood and stone wear wider than chipped paint, metal narrower.
    var edgeWidthScale: Float {
        switch wearKind {
        case .paint: 1
        case .metal: 0.8
        case .smooth: 1.1
        case .rough: 1.25
        }
    }

    /// How this look's convex edges wear (nil: they don't), with `average` its average color
    /// (linear; the part's color when it has one), for band `width` meters at `scale` meters per
    /// texture tile.
    func edgeWear(average: Vec3, width: Float, scale: Float) -> EdgeWear? {
        func lin(_ r: Float, _ g: Float, _ b: Float) -> Vec3 {
            Vec3(MeshBuildLookSampler.lin(r), MeshBuildLookSampler.lin(g), MeshBuildLookSampler.lin(b))
        }
        func lighter(_ k: Float, desaturate: Float) -> Vec3 {
            let gray = dot(average, Vec3(0.2126, 0.7152, 0.0722))
            return (average + (Vec3(repeating: gray) - average) * desaturate) * k
        }
        // Chips about one and a half band widths across.
        let frequency = scale / max(width * 1.5, 1e-4)
        switch self {
        case .paintedMetal:
            return EdgeWear(color: lin(0.62, 0.62, 0.64), roughness: 0.3, metallic: 1, noiseFrequency: frequency, crisp: 1)
        case .paintedWood:
            return EdgeWear(color: lin(0.62, 0.46, 0.3), roughness: 0.6, metallic: 0, noiseFrequency: frequency, crisp: 1)
        case .rustyMetal:
            return EdgeWear(color: lin(0.6, 0.58, 0.56), roughness: 0.22, metallic: 1, noiseFrequency: frequency, crisp: 0.33)
        case .brushedMetal, .polishedMetal, .gold, .copper, .brass:
            return EdgeWear(color: lighter(1.12, desaturate: 0), roughness: 0.08, metallic: 1, noiseFrequency: frequency, crisp: 0)
        case .wood, .planks, .bark:
            return EdgeWear(color: lighter(1.45, desaturate: 0.2), roughness: 0.55, metallic: 0, noiseFrequency: frequency, crisp: 0.33)
        case .stone, .cobblestone, .concrete, .brick:
            return EdgeWear(color: lighter(1.6, desaturate: 0.3), roughness: 0.7, metallic: 0, noiseFrequency: frequency, crisp: 0.33)
        case .leather, .plastic, .rubber, .ceramic, .fabric:
            return EdgeWear(color: lighter(1.3, desaturate: 0.3), roughness: self == .ceramic ? 0.2 : 0.5, metallic: 0,
                            noiseFrequency: frequency, crisp: 0)
        case .glass, .dirt, .grass:
            return nil
        }
    }
}
