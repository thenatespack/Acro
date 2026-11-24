#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// The mesh build shapes beyond the unit primitives: rounded boxes and cylinders (`bevel`) and the
// profile shapes `lathe` and `extrude`.
//
// Size convention: every other shape fills its `size` box, centered on the part. A profile is
// different: its points are meters in the part's own space, used as written (a lathe's axis is
// the part's Y axis, an extrude's [0, 0] is the part's origin, centered in Z), and `size`
// multiplies them. So an author can write real measurements and leave `size` at [1, 1, 1], and
// the Move / Scale gizmos and `size` edits still stretch the shape as for any other part. An
// extrude has no Z in its profile: it is `size.z` meters deep.

extension MeshBuildPart {
    /// What the tool docs say about bevels and the profile shapes (appended to the format doc).
    public static let shapesDoc = """
        Rounding: `bevel` (m) rounds a box's edges or a cylinder's rims (0 = sharp, clamped to half the smallest \
        size; segments sets how smooth). Profile shapes: their `profile` points are meters used as written in the part's \
        space (not fitted to size; size multiplies them, so leave size [1,1,1]). `lathe` spins `profile` \
        [[radius, height], ...] (bottom to top) around Y; ends with radius > 0 get flat caps, bends sharper than 40° get a \
        hard edge; segments = steps around. A vase: [[0,0],[0.2,0],[0.26,0.3],[0.12,0.6],[0.16,0.7]]. `extrude` pushes \
        the outline `profile` [[x, y], ...] (either winding, concave is fine, must not cross itself) along Z, size.z m \
        deep and centered in Z; corners sharper than 40° stay hard. An L: [[0,0],[0.6,0],[0.6,0.2],[0.2,0.2],[0.2,1],[0,1]] \
        with size [1,1,0.1]. A bad profile (too few points, no area, crossing itself) builds nothing and gives a warning.
        """

    /// Problems with the fields that shape the mesh (the importer reports them as warnings),
    /// without building a mesh unless the part is a profile shape.
    public var shapeWarnings: [String] {
        guard shape == .lathe || shape == .extrude || shape == .sweep || shape == .loft || shape == .foliage else { return fieldWarnings }
        var warnings: [String] = []
        _ = geometry(warnings: &warnings)
        return warnings
    }

    /// Cheap checks of fields a shape ignores.
    var fieldWarnings: [String] {
        var warnings: [String] = []
        if let bevel, bevel != 0, shape != .box && shape != .cylinder {
            warnings.append("bevel only rounds box and cylinder parts; this \(shape.rawValue) ignores it")
        }
        if let bevel, !bevel.isFinite || bevel < 0 { warnings.append("bevel must be a number of meters ≥ 0") }
        if let profile, !profile.isEmpty, shape != .lathe && shape != .extrude && shape != .sweep {
            warnings.append("profile is only used by lathe, extrude and sweep parts; this \(shape.rawValue) ignores it")
        }
        warnings += lookWarnings  // MeshBuildLookMapping.swift
        return warnings + sculptFieldWarnings + curveFieldWarnings + foliageFieldWarnings
    }

    /// The box the part's mesh occupies in its own space: `size` centered on the origin for most
    /// shapes, the built mesh's extent for `lathe`, `extrude`, `sweep`, `loft`, deformed parts and a `sculpt` with
    /// its `sculptChildren` gathered (empty at the origin if nothing can be built).
    public var localBounds: Bounds {
        if [.lathe, .extrude, .sculpt, .sweep, .loft, .foliage].contains(shape) || !(deform ?? []).isEmpty {
            return geometry().map(\.bounds) ?? Bounds(center: .zero, halfExtent: .zero)
        }
        return Bounds(center: .zero, halfExtent: Vec3(abs(size.x), abs(size.y), abs(size.z)) / 2)
    }
}

extension MeshGeometry {
    /// Profile bends sharper than this (degrees between neighboring segments) get split normals.
    static let profileSharpAngle: Float = 40

    /// A box of `halfExtent` whose edges are quarter rounds of `radius` (clamped to the smallest
    /// half extent) and whose corners are sphere octants, with smooth normals across the
    /// rounding. Each face is a grid: its flat middle plus half of each neighboring rounded edge,
    /// sampled at even angles, so faces meet with identical positions and normals. UVs are the
    /// cube's 0–1 per face.
    static func roundedBox(halfExtent h: Vec3, radius: Float, segments: Int) -> MeshGeometry {
        let r = min(radius, min(h.x, min(h.y, h.z)))
        guard r > 0 else {
            var g = cube(size: 1)
            g.scale(by: h * 2)
            return g
        }
        let k = max(segments / 8, 1)  // steps per half of a quarter round
        // Samples across one axis, ascending: the inner box's coordinate and the offset to the surface.
        func samples(_ half: Float) -> [(inner: Float, offset: Float)] {
            let e = half - r
            let positive: [(inner: Float, offset: Float)] = (0...k).map { i in
                (e, r * (i == k ? 1 : tanf(Float(i) / Float(k) * .pi / 4)))
            }
            var negative = positive.reversed().map { (inner: -$0.inner, offset: -$0.offset) }
            if e <= 0 { negative.removeLast() }  // the middle samples coincide
            return negative + positive
        }
        let axisSamples = [samples(h.x), samples(h.y), samples(h.z)]
        func axis(_ v: Vec3) -> (index: Int, sign: Float) {
            v.x != 0 ? (0, v.x) : v.y != 0 ? (1, v.y) : (2, v.z)
        }
        let x = Vec3(1, 0, 0), y = Vec3(0, 1, 0), z = Vec3(0, 0, 1)
        // (normal, u, v) as in `cube`: u × v = normal, so the grid winds counter-clockwise from outside.
        let faces = [(x, -z, y), (-x, z, y), (y, x, -z), (-y, x, z), (z, x, y), (-z, -x, y)]
        var g = MeshGeometry(vertices: [], indices: [])
        for (n, u, v) in faces {
            let (an, sn) = axis(n), (au, su) = axis(u), (av, sv) = axis(v)
            let us = axisSamples[au], vs = axisSamples[av]
            let base = UInt32(g.vertices.count)
            for sampleV in vs {
                for sampleU in us {
                    var inner = Vec3.zero, offset = Vec3.zero
                    inner[an] = sn * (h[an] - r)
                    offset[an] = sn * r
                    inner[au] = su * sampleU.inner
                    offset[au] = su * sampleU.offset
                    inner[av] = sv * sampleV.inner
                    offset[av] = sv * sampleV.offset
                    let normal = normalize(offset)
                    let pu = (sampleU.inner + sampleU.offset) / h[au], pv = (sampleV.inner + sampleV.offset) / h[av]
                    g.vertices.append(MeshVertex(position: inner + normal * r, normal: normal, uv: Vec2((pu + 1) / 2, (1 - pv) / 2)))
                }
            }
            let nu = UInt32(us.count)
            for j in 0..<UInt32(vs.count - 1) {
                for i in 0..<nu - 1 {
                    let a = base + j * nu + i, b = a + 1, c = a + nu + 1, d = a + nu
                    g.indices += [a, b, c, a, c, d]
                }
            }
        }
        return g
    }

    /// A cylinder along Y with rounded rims of `bevel` (clamped to the radius and half the
    /// height): a lathe of its profile, smooth across the rounding.
    static func roundedCylinder(radius: Float, height: Float, bevel: Float, segments: Int) -> MeshGeometry {
        let hh = height / 2, b = min(bevel, min(radius, hh))
        let steps = max(segments / 4, 2)
        var profile = [Vec2(0, -hh)]
        for i in 0...steps {
            let a = -Float.pi / 2 + Float(i) / Float(steps) * .pi / 2
            profile.append(Vec2(radius - b + b * cosf(a), -hh + b + b * sinf(a)))
        }
        for i in 0...steps {
            let a = Float(i) / Float(steps) * .pi / 2
            profile.append(Vec2(radius - b + b * cosf(a), hh - b + b * sinf(a)))
        }
        profile.append(Vec2(0, hh))
        var ignored: [String] = []
        return lathe(profile: profile, segments: segments, sharpAngle: 89, warnings: &ignored)
            ?? cylinder(radius: radius, height: height, segments: segments)
    }

    /// `profile` without non-finite points (warned about) and consecutive repeats.
    static func cleanProfile(_ profile: [Vec2], shape: String, warnings: inout [String]) -> [Vec2] {
        let finite = profile.filter { $0.x.isFinite && $0.y.isFinite }
        if finite.count != profile.count {
            warnings.append("\(shape) profile: \(profile.count - finite.count) point(s) that aren't numbers were left out")
        }
        var points: [Vec2] = []
        for p in finite where points.last.map({ length(p - $0) > 1e-6 }) ?? true { points.append(p) }
        return points
    }

    /// Twice the signed area of a closed polygon (positive: counter-clockwise).
    static func doubleSignedArea(_ points: [Vec2]) -> Float {
        var area: Float = 0
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            area += a.x * b.y - b.x * a.y
        }
        return area
    }

    /// A solid of revolution around Y from `profile` (`[radius, height]` points in meters, bottom
    /// to top). The profile is closed along the axis (ends with a radius get flat caps) and
    /// oriented so faces point out whichever way it was written. Normals are smooth around and
    /// along the profile except at bends sharper than `sharpAngle` degrees; U runs around, V
    /// along the profile's arc length (0 at the top). Nil (with a warning) for a profile that
    /// can't make a solid.
    static func lathe(profile raw: [Vec2], segments: Int, sharpAngle: Float = profileSharpAngle,
                      warnings: inout [String]) -> MeshGeometry? {
        var points = cleanProfile(raw, shape: "lathe", warnings: &warnings)
        if points.contains(where: { $0.x < 0 }) {
            if points.contains(where: { $0.x < -1e-5 }) { warnings.append("lathe profile: radii below 0 were treated as 0") }
            points = cleanProfile(points.map { Vec2(max($0.x, 0), $0.y) }, shape: "lathe", warnings: &warnings)
        }
        guard points.count >= 2 else {
            warnings.append("a lathe needs a profile of at least 2 [radius, height] points (it has \(points.count)); nothing was built")
            return nil
        }
        if points[0].x > 0 { points.insert(Vec2(0, points[0].y), at: 0) }
        if points[points.count - 1].x > 0 { points.append(Vec2(0, points[points.count - 1].y)) }
        let extent = points.reduce(Float(0)) { max($0, abs($1.x), abs($1.y)) }
        let area = doubleSignedArea(points)
        guard abs(area) > 1e-9 * max(extent * extent, 1e-6) else {
            warnings.append("the lathe profile encloses no area (all on the axis or on one line); nothing was built")
            return nil
        }
        // Counter-clockwise in (radius, height): the outside is to the right of the direction of travel.
        if area < 0 { points.reverse() }

        let segmentNormals: [Vec2] = (0..<points.count - 1).map { i in
            let d = points[i + 1] - points[i]
            return normalize(Vec2(d.y, -d.x))
        }
        let cosSharp = cosf(sharpAngle * .pi / 180)
        // Each segment's normal at its start and end: the bend's average, or its own at a sharp bend.
        var startNormals = segmentNormals, endNormals = segmentNormals
        for i in 1..<max(points.count - 1, 1) {
            let a = segmentNormals[i - 1], b = segmentNormals[i]
            if dot(a, b) >= cosSharp {
                let smooth = normalize(a + b)
                endNormals[i - 1] = smooth
                startNormals[i] = smooth
            }
        }
        var arc: [Float] = [0]
        for i in 1..<points.count { arc.append(arc[i - 1] + length(points[i] - points[i - 1])) }
        let total = max(arc[arc.count - 1], 1e-6)

        var g = MeshGeometry(vertices: [], indices: [])
        for i in 0..<points.count - 1 {
            let p0 = points[i], p1 = points[i + 1], n0 = startNormals[i], n1 = endNormals[i]
            // `appendLathe` runs its profile the other way (outside to the left), so the segment goes in reversed.
            g.appendLathe([(p1.x, p1.y, n1.x, n1.y, 1 - arc[i + 1] / total), (p0.x, p0.y, n0.x, n0.y, 1 - arc[i] / total)],
                          segments: segments)
        }
        return g
    }

    /// A prism: the polygon `profile` (`[x, y]`, meters, either winding, concave allowed) in XY
    /// pushed `depth` meters along Z, centered in Z. The caps are flat and ear-clipped; the
    /// sides are smooth across corners up to `sharpAngle` degrees and hard beyond. Cap UVs span
    /// the outline's bounds 0–1; side U runs along the perimeter, V front to back. Nil (with a
    /// warning) for an outline with too few points, no area, or edges that cross.
    static func extrude(profile raw: [Vec2], depth: Float, sharpAngle: Float = profileSharpAngle,
                        warnings: inout [String]) -> MeshGeometry? {
        var points = cleanProfile(raw, shape: "extrude", warnings: &warnings)
        if points.count > 1, length(points[0] - points[points.count - 1]) <= 1e-6 { points.removeLast() }
        guard points.count >= 3 else {
            warnings.append("an extrude needs a profile of at least 3 [x, y] points (it has \(points.count)); nothing was built")
            return nil
        }
        let lo = points.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
        let hi = points.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
        let extent = max(hi.x - lo.x, hi.y - lo.y)
        let area = doubleSignedArea(points)
        guard abs(area) > 1e-9 * max(extent * extent, 1e-6) else {
            warnings.append("the extrude profile encloses no area (its points are on one line); nothing was built")
            return nil
        }
        guard depth > 0 else {
            warnings.append("an extrude needs a depth: size.z is 0; nothing was built")
            return nil
        }
        if area < 0 { points.reverse() }
        guard !polygonSelfIntersects(points) else {
            warnings.append("the extrude profile crosses itself; nothing was built (list the outline's corners in order around it)")
            return nil
        }
        guard let triangles = earClip(points) else {
            warnings.append("the extrude profile couldn't be triangulated; nothing was built")
            return nil
        }

        var g = MeshGeometry(vertices: [], indices: [])
        let size = pointwiseMax(hi - lo, Vec2(1e-6, 1e-6)), hz = depth / 2
        // Caps: the front faces +Z (counter-clockwise as listed), the back -Z (reversed, U mirrored
        // so a texture reads the right way round from behind).
        for front in [true, false] {
            let base = UInt32(g.vertices.count)
            for p in points {
                let t = (p - lo) / size
                g.vertices.append(MeshVertex(position: Vec3(p.x, p.y, front ? hz : -hz), normal: Vec3(0, 0, front ? 1 : -1),
                                             uv: Vec2(front ? t.x : 1 - t.x, 1 - t.y)))
            }
            for (a, b, c) in triangles {
                g.indices += front ? [base + UInt32(a), base + UInt32(b), base + UInt32(c)]
                                   : [base + UInt32(a), base + UInt32(c), base + UInt32(b)]
            }
        }
        // Sides: one quad per edge, its outward normal to the right of the edge.
        let n = points.count
        let edgeNormals: [Vec2] = (0..<n).map { i in
            let d = points[(i + 1) % n] - points[i]
            return normalize(Vec2(d.y, -d.x))
        }
        let cosSharp = cosf(sharpAngle * .pi / 180)
        // Corner i is between edge i - 1 and edge i: smooth (shared normal) or hard (each edge's own).
        let cornerNormals: [Vec2?] = (0..<n).map { i in
            let a = edgeNormals[(i + n - 1) % n], b = edgeNormals[i]
            return dot(a, b) >= cosSharp ? normalize(a + b) : nil
        }
        var along: [Float] = [0]
        for i in 0..<n { along.append(along[i] + length(points[(i + 1) % n] - points[i])) }
        let perimeter = max(along[n], 1e-6)
        for i in 0..<n {
            let j = (i + 1) % n
            let a = points[i], b = points[j]
            let na = cornerNormals[i] ?? edgeNormals[i], nb = cornerNormals[j] ?? edgeNormals[i]
            let ua = along[i] / perimeter, ub = along[i + 1] / perimeter
            let base = UInt32(g.vertices.count)
            g.vertices += [
                MeshVertex(position: Vec3(a.x, a.y, hz), normal: Vec3(na.x, na.y, 0), uv: Vec2(ua, 0)),
                MeshVertex(position: Vec3(a.x, a.y, -hz), normal: Vec3(na.x, na.y, 0), uv: Vec2(ua, 1)),
                MeshVertex(position: Vec3(b.x, b.y, -hz), normal: Vec3(nb.x, nb.y, 0), uv: Vec2(ub, 1)),
                MeshVertex(position: Vec3(b.x, b.y, hz), normal: Vec3(nb.x, nb.y, 0), uv: Vec2(ub, 0)),
            ]
            g.indices += [base, base + 1, base + 2, base, base + 2, base + 3]
        }
        return g
    }

    private static func cross2(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.y - a.y * b.x }

    /// Whether two edges of the closed polygon that don't share a corner touch or cross.
    static func polygonSelfIntersects(_ p: [Vec2]) -> Bool {
        let n = p.count
        func orient(_ a: Vec2, _ b: Vec2, _ c: Vec2) -> Float { cross2(b - a, c - a) }
        func onSegment(_ a: Vec2, _ b: Vec2, _ c: Vec2) -> Bool {
            c.x >= min(a.x, b.x) - 1e-7 && c.x <= max(a.x, b.x) + 1e-7 && c.y >= min(a.y, b.y) - 1e-7 && c.y <= max(a.y, b.y) + 1e-7
        }
        let lo = p.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
        let hi = p.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
        let eps = 1e-7 * max(hi.x - lo.x, hi.y - lo.y, 1e-6) * max(hi.x - lo.x, hi.y - lo.y, 1e-6)
        for i in 0..<n {
            let a = p[i], b = p[(i + 1) % n]
            for j in (i + 1)..<n {
                // Neighboring edges share a corner.
                if j == i + 1 || (i == 0 && j == n - 1) { continue }
                let c = p[j], d = p[(j + 1) % n]
                let o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b)
                if ((o1 > eps && o2 < -eps) || (o1 < -eps && o2 > eps)) && ((o3 > eps && o4 < -eps) || (o3 < -eps && o4 > eps)) {
                    return true
                }
                if abs(o1) <= eps && onSegment(a, b, c) { return true }
                if abs(o2) <= eps && onSegment(a, b, d) { return true }
                if abs(o3) <= eps && onSegment(c, d, a) { return true }
                if abs(o4) <= eps && onSegment(c, d, b) { return true }
            }
        }
        return false
    }

    /// Ear-clipping triangulation of a simple counter-clockwise polygon: index triples, each
    /// counter-clockwise. Corners in line with their neighbors are dropped without a triangle.
    /// Nil if no ear can be found (the polygon isn't simple).
    static func earClip(_ p: [Vec2]) -> [(Int, Int, Int)]? {
        let lo = p.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
        let hi = p.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
        let scale = max(hi.x - lo.x, hi.y - lo.y, 1e-6)
        let eps = 1e-9 * scale * scale
        var remaining = Array(p.indices)
        var triangles: [(Int, Int, Int)] = []
        var i = 0, misses = 0
        func inside(_ q: Vec2, _ a: Vec2, _ b: Vec2, _ c: Vec2) -> Bool {
            cross2(b - a, q - a) >= -eps && cross2(c - b, q - b) >= -eps && cross2(a - c, q - c) >= -eps
        }
        while remaining.count > 3 {
            let n = remaining.count
            guard misses < n else { return nil }
            i %= n
            let ia = remaining[(i + n - 1) % n], ib = remaining[i], ic = remaining[(i + 1) % n]
            let a = p[ia], b = p[ib], c = p[ic]
            let turn = cross2(b - a, c - b)
            if abs(turn) <= eps {
                remaining.remove(at: i)
                misses = 0
                continue
            }
            let isEar = turn > 0 && !remaining.contains { j in
                j != ia && j != ib && j != ic && p[j] != a && p[j] != b && p[j] != c && inside(p[j], a, b, c)
            }
            if isEar {
                triangles.append((ia, ib, ic))
                remaining.remove(at: i)
                misses = 0
            } else {
                i += 1
                misses += 1
            }
        }
        if remaining.count == 3 {
            let a = p[remaining[0]], b = p[remaining[1]], c = p[remaining[2]]
            if abs(cross2(b - a, c - a)) > eps { triangles.append((remaining[0], remaining[1], remaining[2])) }
        }
        return triangles
    }
}

private func dot(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
private func length(_ v: Vec2) -> Float { dot(v, v).squareRoot() }
private func normalize(_ v: Vec2) -> Vec2 {
    let l = length(v)
    return l > 0 ? v / l : v
}
