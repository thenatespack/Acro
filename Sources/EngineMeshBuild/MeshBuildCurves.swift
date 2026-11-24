#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene
import EngineAssets

// Curved mesh build shapes: `sweep` (a cross-section moved along a smooth 3D path: pipes, cables,
// handles, railings, branches, horns) and `loft` (a skin through a stack of cross-sections: hulls,
// bottles, fuselages, blades, car bodies). Like the profile shapes, their numbers are meters used
// as written in the part's space and `size` multiplies the result, so leave it at [1, 1, 1].
//
// ```json
// {"name": "Pipe", "shape": "sweep", "path": [[0,0,0],[0,0.5,0],[0.4,0.8,0]], "radius": 0.04},
// {"name": "Horn", "shape": "sweep", "path": [[0,0,0],[0.1,0.3,0],[0.3,0.45,0]], "radius": 0.06, "radii": [1, 0.6, 0]},
// {"name": "Ring", "shape": "sweep", "path": [[0.5,0,0],[0,0,0.5],[-0.5,0,0],[0,0,-0.5]], "closed": true, "radius": 0.03},
// {"name": "Hull", "shape": "loft", "axis": "z", "sections": [
//   {"at": [0, 0.5, -2], "size": [0, 0]}, {"at": -1, "size": [1.4, 1], "roundness": 1.5}, {"at": 2, "size": [1.2, 0.9], "roundness": 3}]}
// ```
//
// Sweep: `path` points are smoothed by a centripetal Catmull-Rom spline (no overshoot or loops on
// uneven spacing); `straight: true` joins straight segments with mitred corners. The section is a
// circle of `radius` (default 0.05 m), or `profile` ([x, y] points: x to the right of the direction
// of travel, y "up", which starts as the world's up and is carried along by rotation-minimizing
// frames, so it never twists or flips). `radii` multiplies the section at each path point (taper).
// `closed` joins the end to the start; open ends get flat caps (none where the section shrinks to 0).
//
// Loft: `sections` are ordered along `axis` (default y, like cylinders and lathes; "z" for things
// that lie front to back such as hulls, fuselages and cars). Each has `at` (its position along the
// axis, or its center [x, y, z]), `size` [across, other] (y: [x, z]; z: [x, y]; x: [z, y]) and
// `roundness` (the superellipse exponent is 2^roundness: 0 diamond, 1 ellipse (default), 2 squircle,
// 3 rounded box, 4+ box), or a `profile` of [across, other] points (size multiplies it). The skin
// follows a monotone cubic through the sections (no bulging past them); `straight: true` makes
// straight panels with creases. The ends get flat caps.

extension MeshBuildPart {
    /// What the tool docs say about sweeps, lofts and deformers (appended to the format doc).
    public static let curvesDoc = """
        Curves: `sweep` moves a section along `path` [[x,y,z],...] (m, part space, at least 2 points; a smooth spline \
        through them, straight:true = straight segments with mitred corners): a circle of `radius` (default 0.05) or a \
        `profile` [[x,y],...] (x = right of the direction of travel, y = up; never twists), `radii` [k,...] multiplies \
        it per path point (taper: [1,0.7,0] makes a horn), `closed`:true joins the end to the start (rings), open ends are \
        capped. Pipe: {"shape":"sweep","path":[[0,0,0],[0,0.5,0],[0.3,0.7,0]],"radius":0.04}. `loft` skins `sections` \
        [{at, size, roundness, profile}] along `axis` (default y; "z" for hulls, fuselages, car bodies lying front to \
        back): at = position along the axis or the center [x,y,z]; size [across, other] m (axis y: [x,z]; z: [x,y]; x: \
        [z,y]); roundness 0 diamond, 1 ellipse (default), 2 squircle, 3 rounded box, 4 box; or profile [[a,b],...] \
        (the same point count in every section keeps its corners exact); smooth spline between sections \
        (straight:true = straight panels); ends capped (size [0,0] = a point). Bottle: {"shape":"loft","sections":[{"at":0,\
        "size":[0.3,0.2],"roundness":2},{"at":0.3,"size":[0.32,0.22],"roundness":2},{"at":0.4,"size":[0.08,0.08]},\
        {"at":0.5,"size":[0.08,0.08]}]}. Sweep and loft numbers are meters as written (size multiplies; leave [1,1,1]). \
        Deform any mesh part: `deform` [{"taper":[x,z]} (scale at the top vs the bottom, along Y), {"bend":{"axis":"x"|"z",\
        "degrees":d}} (the top leans toward +axis, d<0 the other way, length kept), {"twist":deg} (about Y, bottom to \
        top), {"noise":{"amount":m,"scale":m,"seed":n}} (bumps for rocks, bark, dents)], applied in order, before \
        mirror (copies deform symmetrically). The mesh is split finely first (`subdivide` 0-6, default 3; 0 = off); \
        hard edges stay hard. Leaning trunk: {"shape":"cylinder","size":[0.3,2,0.3],"deform":[{"taper":[0.6,0.6]},\
        {"bend":{"axis":"x","degrees":25}}]}.
        """

    /// Problems with the curve and deform fields a shape ignores (cheap: no mesh is built).
    var curveFieldWarnings: [String] {
        var warnings: [String] = []
        let name = shape.rawValue
        if shape != .sweep {
            let unused = [("path", path != nil), ("radius", radius != nil), ("radii", radii != nil), ("closed", closed != nil)]
                .filter(\.1).map(\.0)
            if !unused.isEmpty { warnings.append("\(unused.joined(separator: ", ")) only shape sweep parts; this \(name) ignores it") }
        }
        if shape != .loft {
            let unused = [("sections", sections != nil), ("axis", axis != nil)].filter(\.1).map(\.0)
            if !unused.isEmpty { warnings.append("\(unused.joined(separator: ", ")) only shape loft parts; this \(name) ignores it") }
        }
        if straight != nil && shape != .sweep && shape != .loft {
            warnings.append("straight is only used by sweep and loft parts; this \(name) ignores it")
        }
        warnings += deformWarnings
        return warnings
    }

    /// The sweep's or loft's mesh in meters (before `size`), nil (with a warning) if it can't be built.
    func curveGeometry(segments: Int, warnings: inout [String]) -> MeshGeometry? {
        switch shape {
        case .sweep:
            if isRibbon { return ribbonGeometry(segments: segments, warnings: &warnings) }  // MeshBuildRibbon.swift
            return MeshGeometry.sweep(path: path ?? [], radius: radius ?? MeshGeometry.defaultSweepRadius, radii: radii,
                                      profile: profile, closed: closed ?? false, smooth: !(straight ?? false), segments: segments,
                                      ringStep: curveRingStep, warnings: &warnings)
        case .loft:
            return MeshGeometry.loft(sections: sections ?? [], axis: axis ?? .y, smooth: !(straight ?? false), segments: segments,
                                     warnings: &warnings)
        default: return nil
        }
    }
}

// MARK: - Sweep

extension MeshGeometry {
    public static let defaultSweepRadius: Float = 0.05
    /// Rings a sweep or loft may have along its length.
    static let maxCurveRings = 600

    /// One column of a cross-section: a point, its outward normal and its U. A corner sharper than
    /// the sharp angle has two columns at the same point (one per side), so the edge stays hard.
    struct SectionColumn {
        var p: Vec2
        var n: Vec2
        var u: Float
    }

    /// The columns around the closed counter-clockwise polygon `points`, the first repeated at the
    /// end (U 0 and 1). Corners whose sides turn more than `sharpAngle` degrees are split.
    static func sectionColumns(_ points: [Vec2], sharpAngle: Float) -> [SectionColumn] {
        let n = points.count
        let edgeNormals: [Vec2] = (0..<n).map { i in
            let d = points[(i + 1) % n] - points[i]
            return norm2(Vec2(d.y, -d.x))
        }
        var along: [Float] = [0]
        for i in 0..<n { along.append(along[i] + len2(points[(i + 1) % n] - points[i])) }
        let perimeter = max(along[n], 1e-9)
        let cosSharp = cosf(sharpAngle * .pi / 180)
        var columns: [SectionColumn] = []
        for i in 0...n {
            let k = i % n
            let incoming = edgeNormals[(k + n - 1) % n], outgoing = edgeNormals[k]
            let u = i == n ? 1 : along[i] / perimeter
            if dot2(incoming, outgoing) >= cosSharp {
                columns.append(SectionColumn(p: points[k], n: norm2(incoming + outgoing), u: u))
            } else {
                if i > 0 { columns.append(SectionColumn(p: points[k], n: incoming, u: u)) }
                if i < n { columns.append(SectionColumn(p: points[k], n: outgoing, u: u)) }
            }
        }
        return columns
    }

    /// A closed outline from `raw` for a `shape`'s section: cleaned, counter-clockwise, simple.
    /// Nil (with a warning) if it has too few points, no area or crosses itself.
    static func closedOutline(_ raw: [Vec2], shape: String, warnings: inout [String]) -> [Vec2]? {
        var points = cleanProfile(raw, shape: shape, warnings: &warnings)
        if points.count > 1, len2(points[0] - points[points.count - 1]) <= 1e-6 { points.removeLast() }
        guard points.count >= 3 else {
            warnings.append("a \(shape) profile needs at least 3 [x, y] points (it has \(points.count))")
            return nil
        }
        let extent = points.reduce(Float(0)) { max($0, abs($1.x), abs($1.y)) }
        let area = doubleSignedArea(points)
        guard abs(area) > 1e-9 * max(extent * extent, 1e-6) else {
            warnings.append("the \(shape) profile encloses no area (its points are on one line)")
            return nil
        }
        if area < 0 { points.reverse() }
        guard !polygonSelfIntersects(points) else {
            warnings.append("the \(shape) profile crosses itself (list the outline's corners in order around it)")
            return nil
        }
        return points
    }

    /// A point on the path with its frame: the ring there is `position + scale * (right * x + up * y)`.
    struct PathSample {
        var position: Vec3
        var tangent: Vec3
        var scale: Float
        /// The mitre plane's normal at a straight path's corner (rings there are cut along it).
        var miter: Vec3?
        /// The second ring of a mitred corner: same positions as the one before, its own normals.
        var join = false
        var up = Vec3(0, 1, 0)
        var right: Vec3 { normalize(cross(tangent, up)) }
    }

    /// A cross-section moved along `path` (see the notes at the top of this file). Nil (with a
    /// warning) for a path or section that can't make a tube.
    static func sweep(path raw: [Vec3], radius: Float, radii rawRadii: [Float]?, profile: [Vec2]?, closed wantsClosed: Bool,
                      smooth: Bool, segments: Int, sharpAngle: Float = profileSharpAngle, ringStep: Float = 1,
                      warnings: inout [String]) -> MeshGeometry? {
        // The path and its radii, cleaned together.
        if let rawRadii, rawRadii.count != raw.count {
            warnings.append("sweep radii has \(rawRadii.count) values for \(raw.count) path points; missing ones are 1, extras are ignored")
        }
        var points: [Vec3] = [], scales: [Float] = []
        var badPoints = 0, badRadii = 0
        for (i, p) in raw.enumerated() {
            guard p.x.isFinite && p.y.isFinite && p.z.isFinite else { badPoints += 1; continue }
            var k: Float = 1
            if let rawRadii, i < rawRadii.count {
                k = rawRadii[i]
                if !k.isFinite || k < 0 { badRadii += 1; k = k.isFinite ? 0 : 1 }
            }
            if let last = points.last, length(p - last) <= 1e-6 { scales[scales.count - 1] = k; continue }
            points.append(p)
            scales.append(k)
        }
        if badPoints > 0 { warnings.append("sweep path: \(badPoints) point(s) that aren't numbers were left out") }
        if badRadii > 0 { warnings.append("sweep radii must be numbers ≥ 0: \(badRadii) value(s) were replaced (negative: 0, not a number: 1)") }
        var closed = wantsClosed
        if closed, points.count > 2, length(points[0] - points[points.count - 1]) <= 1e-6 {
            points.removeLast()
            scales.removeLast()
        }
        guard points.count >= 2 else {
            warnings.append("a sweep needs a path of at least 2 different [x, y, z] points (it has \(points.count)); nothing was built")
            return nil
        }
        if closed && points.count < 3 {
            warnings.append("a closed sweep needs at least 3 path points; this one was left open")
            closed = false
        }

        // The cross-section.
        let outline: [Vec2]
        let columns: [SectionColumn]
        if let profile, !profile.isEmpty {
            guard let points = closedOutline(profile, shape: "sweep", warnings: &warnings) else {
                warnings.append("the sweep was not built")
                return nil
            }
            outline = points
            columns = sectionColumns(points, sharpAngle: sharpAngle)
        } else {
            guard radius.isFinite, radius > 0 else {
                warnings.append("a sweep needs a radius > 0 m (it has \(radius)); nothing was built")
                return nil
            }
            let n = max(segments, 3)
            outline = (0..<n).map { k in
                let a = Float(k) / Float(n) * 2 * .pi
                return Vec2(cosf(a), sinf(a)) * radius
            }
            columns = sectionColumns(outline, sharpAngle: 180)
        }
        var perimeter: Float = 0
        for i in outline.indices { perimeter += len2(outline[(i + 1) % outline.count] - outline[i]) }

        var samples = smooth ? smoothSamples(points, scales: scales, closed: closed, ringStep: ringStep)
            : cornerSamples(points, scales: scales, closed: closed)
        guard samples.count >= 2 else { return nil }
        frame(&samples, closed: closed)

        var g = MeshGeometry(vertices: [], indices: [])
        let cols = columns.count
        var along: Float = 0
        var firstRing: [Vec3] = []
        for (i, s) in samples.enumerated() {
            if i > 0 { along += length(s.position - samples[i - 1].position) }
            let right = s.right
            let v = along / max(perimeter, 1e-6)
            var ring: [Vec3]
            if s.join || (closed && i == samples.count - 1) {
                // A mitred corner's second ring, or a loop's last ring: the same positions exactly.
                let previous = s.join ? i - 1 : 0
                ring = (0..<cols).map { g.vertices[previous * cols + $0].position }
                if closed && i == samples.count - 1 { ring = firstRing }
            } else {
                ring = columns.map { ringPoint(s, right: right, $0.p) }
            }
            if i == 0 { firstRing = ring }
            for (j, c) in columns.enumerated() {
                let n = right * c.n.x + s.up * c.n.y
                g.vertices.append(MeshVertex(position: ring[j], normal: n, uv: Vec2(c.u, v)))
            }
        }
        // Sides: (i, j) → (i+1, j) → (i+1, j+1) faces out for a counter-clockwise section.
        for i in 0..<samples.count - 1 where !samples[i + 1].join {
            for j in 0..<cols - 1 where len2(columns[j].p - columns[j + 1].p) > 1e-9 {
                let a = UInt32(i * cols + j), b = a + 1, d = UInt32((i + 1) * cols + j), c = d + 1
                g.indices += [a, d, c, a, c, b]
            }
        }
        // Flat caps on open ends (not where the section shrank to a point).
        if !closed, let (center, triangles) = capTriangles(outline) {
            for end in [0, samples.count - 1] where samples[end].scale > 1e-6 {
                let s = samples[end]
                let right = s.right
                let n = end == 0 ? -s.tangent : s.tangent
                let lo = outline.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
                let hi = outline.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
                let extent = pointwiseMax(hi - lo, Vec2(1e-6, 1e-6))
                let base = UInt32(g.vertices.count)
                for p in outline + (center.map { [$0] } ?? []) {
                    let t = (p - lo) / extent
                    g.vertices.append(MeshVertex(position: ringPoint(s, right: right, p), normal: n, uv: Vec2(t.x, 1 - t.y)))
                }
                // A counter-clockwise section faces back along the path (right × up = -tangent).
                for (a, b, c) in triangles {
                    g.indices += end == 0 ? [base + UInt32(a), base + UInt32(b), base + UInt32(c)]
                                          : [base + UInt32(a), base + UInt32(c), base + UInt32(b)]
                }
            }
        }
        g.refreshNormals(sharpAngle: sharpAngle)
        return g
    }

    /// A ring point of the section at `s` (cut along its mitre plane at a straight path's corner).
    static func ringPoint(_ s: PathSample, right: Vec3, _ p: Vec2) -> Vec3 {
        var q = s.position + (right * p.x + s.up * p.y) * s.scale
        if let m = s.miter {
            let along = max(dot(s.tangent, m), 0.25)  // a near U-turn's mitre would reach far out
            q -= s.tangent * (dot(q - s.position, m) / along)
        }
        return q
    }

    /// Samples along a centripetal Catmull-Rom spline through `points`: more where it turns or
    /// the radius changes, one step for a straight span.
    /// `ringStep` multiplies the angle between rings (detail levels use fewer, MeshBuildLOD.swift).
    static func smoothSamples(_ points: [Vec3], scales: [Float], closed: Bool, ringStep: Float = 1) -> [PathSample] {
        let n = points.count
        let spans = closed ? n : n - 1
        func point(_ i: Int) -> Vec3 {
            if closed { return points[((i % n) + n) % n] }
            if i < 0 { return points[0] * 2 - points[1] }
            if i >= n { return points[n - 1] * 2 - points[n - 2] }
            return points[i]
        }
        func scale(_ i: Int) -> Float { closed ? scales[((i % n) + n) % n] : scales[min(max(i, 0), n - 1)] }
        func at(_ span: Int, _ t: Float) -> Vec3 { centripetal(point(span - 1), point(span), point(span + 1), point(span + 2), t) }
        func scaleAt(_ span: Int, _ t: Float) -> Float {
            let p0 = scale(span - 1), p1 = scale(span), p2 = scale(span + 1), p3 = scale(span + 2)
            let t2 = t * t, t3 = t2 * t
            let m1 = (p2 - p0) / 2, m2 = (p3 - p1) / 2
            let h = (2 * t3 - 3 * t2 + 1) * p1 + (t3 - 2 * t2 + t) * m1 + (-2 * t3 + 3 * t2) * p2 + (t3 - t2) * m2
            return max(h, 0)
        }
        // Steps per span from how far it turns (about 6° a step) and whether the radius changes.
        var steps: [Int] = (0..<spans).map { span in
            var turn: Float = 0
            var previous: Vec3?
            var last = at(span, 0)
            for k in 1...16 {
                let p = at(span, Float(k) / 16)
                let d = p - last
                if length(d) > 1e-9 {
                    let dir = normalize(d)
                    if let previous { turn += acosf(min(max(dot(previous, dir), -1), 1)) }
                    previous = dir
                }
                last = p
            }
            var count = min(max(Int((turn * 180 / .pi / (6 * ringStep)).rounded(.up)), 1), 32)
            if abs(scale(span + 1) - scale(span)) > 1e-4 || abs(scale(span + 2) - scale(span - 1)) > 1e-4 {
                count = max(count, max(Int((6 / ringStep).rounded()), 2))
            }
            return count
        }
        let total = steps.reduce(0, +)
        if total > maxCurveRings { steps = steps.map { max($0 * maxCurveRings / total, 1) } }

        var positions: [Vec3] = [], ks: [Float] = []
        for span in 0..<spans {
            for k in 0..<steps[span] {
                let t = Float(k) / Float(steps[span])
                positions.append(at(span, t))
                ks.append(scaleAt(span, t))
            }
        }
        positions.append(closed ? points[0] : points[n - 1])
        ks.append(closed ? scales[0] : scales[n - 1])
        // Tangents by central differences (one-sided at open ends; a loop wraps).
        let m = positions.count
        var samples: [PathSample] = []
        for i in 0..<m {
            var a = i > 0 ? positions[i - 1] : (closed ? positions[m - 2] : positions[i])
            var b = i < m - 1 ? positions[i + 1] : (closed ? positions[1] : positions[i])
            if length(b - a) < 1e-9 { a = positions[max(i - 1, 0)]; b = positions[min(i + 1, m - 1)] }
            let d = b - a
            samples.append(PathSample(position: positions[i], tangent: length(d) > 1e-9 ? normalize(d) : Vec3(0, 1, 0), scale: ks[i]))
        }
        return samples
    }

    /// Straight segments between the points, each corner a mitred pair of rings.
    static func cornerSamples(_ points: [Vec3], scales: [Float], closed: Bool) -> [PathSample] {
        let n = points.count
        let segmentCount = closed ? n : n - 1
        let directions = (0..<segmentCount).map { normalize(points[($0 + 1) % n] - points[$0]) }
        func miter(_ incoming: Vec3, _ outgoing: Vec3) -> Vec3? {
            let m = incoming + outgoing
            return length(m) > 1e-4 && dot(incoming, outgoing) < 0.99999 ? normalize(m) : nil
        }
        var samples: [PathSample] = []
        if closed {
            let first = miter(directions[n - 1], directions[0])
            samples.append(PathSample(position: points[0], tangent: directions[0], scale: scales[0], miter: first))
        } else {
            samples.append(PathSample(position: points[0], tangent: directions[0], scale: scales[0]))
        }
        for i in 1..<n {
            let incoming = directions[i - 1]
            if !closed && i == n - 1 {
                samples.append(PathSample(position: points[i], tangent: incoming, scale: scales[i]))
                break
            }
            let outgoing = directions[i % segmentCount]
            let m = miter(incoming, outgoing)
            samples.append(PathSample(position: points[i], tangent: incoming, scale: scales[i], miter: m))
            samples.append(PathSample(position: points[i], tangent: outgoing, scale: scales[i], miter: m, join: true))
        }
        if closed {
            samples.append(PathSample(position: points[0], tangent: directions[n - 1], scale: scales[0],
                                      miter: miter(directions[n - 1], directions[0])))
        }
        return samples
    }

    /// Rotation-minimizing frames (the double reflection method): each sample's `up` is carried
    /// from the one before with as little turning as possible, so a tube never twists or flips.
    /// The first `up` is the world's up (or -Z when the path starts vertically); a loop spreads
    /// the mismatch where it closes evenly along its length.
    static func frame(_ samples: inout [PathSample], closed: Bool) {
        guard let first = samples.first else { return }
        let t0 = first.tangent
        let reference = abs(t0.y) > 0.999 ? Vec3(0, 0, -1) : Vec3(0, 1, 0)
        samples[0].up = normalize(reference - t0 * dot(reference, t0))
        for i in 0..<samples.count - 1 {
            let r = samples[i].up, t = samples[i].tangent, t1 = samples[i + 1].tangent
            let v1 = samples[i + 1].position - samples[i].position
            let c1 = dot(v1, v1)
            var next: Vec3
            if c1 < 1e-14 {
                next = rotate(r, from: t, to: t1)  // a corner: turn with the path
            } else {
                let rL = r - v1 * (2 / c1 * dot(v1, r))
                let tL = t - v1 * (2 / c1 * dot(v1, t))
                let v2 = t1 - tL
                let c2 = dot(v2, v2)
                next = c2 < 1e-14 ? rL : rL - v2 * (2 / c2 * dot(v2, rL))
            }
            next -= t1 * dot(next, t1)
            samples[i + 1].up = length(next) > 1e-6 ? normalize(next) : samples[i].up
        }
        guard closed, samples.count > 2 else { return }
        // Spread the loop's leftover turn along it so the last ring meets the first.
        let last = samples[samples.count - 1]
        let target = rotate(samples[0].up, from: samples[0].tangent, to: last.tangent)
        let angle = atan2f(dot(cross(last.up, target), last.tangent), dot(last.up, target))
        var lengths: [Float] = [0]
        for i in 1..<samples.count { lengths.append(lengths[i - 1] + length(samples[i].position - samples[i - 1].position)) }
        let total = max(lengths[lengths.count - 1], 1e-9)
        for i in samples.indices {
            let a = angle * lengths[i] / total
            let t = samples[i].tangent, r = samples[i].up
            samples[i].up = normalize(r * cosf(a) + cross(t, r) * sinf(a))
        }
    }

    /// `v` turned by the smallest rotation that takes direction `a` to `b`.
    static func rotate(_ v: Vec3, from a: Vec3, to b: Vec3) -> Vec3 {
        let axis = cross(a, b)
        let s = length(axis), c = dot(a, b)
        guard s > 1e-7 else { return v }
        let k = axis / s
        return v * c + cross(k, v) * s + k * (dot(k, v) * (1 - c))
    }

    /// The centripetal Catmull-Rom spline between `p1` and `p2` at `t` (0...1): it never overshoots
    /// into loops or cusps when the points are unevenly spaced.
    static func centripetal(_ p0: Vec3, _ p1: Vec3, _ p2: Vec3, _ p3: Vec3, _ t: Float) -> Vec3 {
        func knot(_ ti: Float, _ a: Vec3, _ b: Vec3) -> Float { ti + max(length(b - a).squareRoot(), 1e-4) }
        let t0: Float = 0, t1 = knot(t0, p0, p1), t2 = knot(t1, p1, p2), t3 = knot(t2, p2, p3)
        let u = t1 + (t2 - t1) * t
        func lerp(_ a: Vec3, _ b: Vec3, _ ta: Float, _ tb: Float) -> Vec3 { a * ((tb - u) / (tb - ta)) + b * ((u - ta) / (tb - ta)) }
        let a1 = lerp(p0, p1, t0, t1), a2 = lerp(p1, p2, t1, t2), a3 = lerp(p2, p3, t2, t3)
        let b1 = lerp(a1, a2, t0, t2), b2 = lerp(a2, a3, t1, t3)
        return lerp(b1, b2, t1, t2)
    }
}

// MARK: - Loft

extension MeshGeometry {
    /// A skin through `sections` along `axis` (see the notes at the top of this file). Nil (with a
    /// warning) when fewer than 2 usable sections remain.
    static func loft(sections raw: [MeshBuildSection], axis: MeshBuildAxis, smooth: Bool, segments: Int,
                     sharpAngle: Float = profileSharpAngle, warnings: inout [String]) -> MeshGeometry? {
        struct Station { var along: Float; var center: Vec2; var section: MeshBuildSection; var number: Int }
        var stations: [Station] = []
        for (i, section) in raw.enumerated() {
            let (along, center) = section.at.split(axis)
            guard along.isFinite, center.x.isFinite, center.y.isFinite else {
                warnings.append("loft section \(i + 1): its `at` isn't a number; it was left out")
                continue
            }
            stations.append(Station(along: along, center: center, section: section, number: i + 1))
        }
        stations.sort { $0.along < $1.along }
        var kept: [Station] = []
        for s in stations {
            if let last = kept.last, s.along - last.along < 1e-5 {
                warnings.append("loft sections \(last.number) and \(s.number) are at the same place along \(axis.rawValue); "
                                + "section \(s.number) was left out (put them at least 1 mm apart for a step)")
                continue
            }
            kept.append(s)
        }
        guard kept.count >= 2 else {
            warnings.append("a loft needs at least 2 sections at different places along its axis (it has \(kept.count)); nothing was built")
            return nil
        }

        // Every ring has the same number of points: the profiles' own when all sections share a
        // count (exact corners), else `segments`.
        let outlines: [[Vec2]?] = kept.map { s in
            guard let profile = s.section.profile, !profile.isEmpty else { return nil }
            var ignored: [String] = []
            return closedOutline(profile, shape: "loft", warnings: &ignored)
        }
        for (i, s) in kept.enumerated() where s.section.profile.map({ !$0.isEmpty }) == true && outlines[i] == nil {
            var reasons: [String] = []
            _ = closedOutline(s.section.profile ?? [], shape: "loft", warnings: &reasons)
            warnings.append("loft section \(s.number): " + reasons.joined(separator: "; ") + "; an ellipse was used instead")
        }
        let counts = Set(outlines.compactMap { $0?.count })
        let n = outlines.allSatisfy({ $0 != nil }) && counts.count == 1 ? counts.first! : max(segments, 3)
        var rings: [[Vec2]] = []
        for (i, s) in kept.enumerated() {
            var size = s.section.size ?? (outlines[i] != nil ? Vec2(1, 1) : MeshBuildSection.defaultSize)
            if !size.x.isFinite || !size.y.isFinite {
                warnings.append("loft section \(s.number): size must be numbers; [0.5, 0.5] was used")
                size = MeshBuildSection.defaultSize
            }
            size = Vec2(abs(size.x), abs(size.y))
            if let outline = outlines[i] {
                let points = outline.count == n ? outline : resample(outline, count: n)
                rings.append(points.map { $0 * size })
            } else {
                var roundness = s.section.roundness ?? 1
                if !roundness.isFinite {
                    warnings.append("loft section \(s.number): roundness must be a number; 1 (an ellipse) was used")
                    roundness = 1
                }
                rings.append(superellipse(half: size / 2, roundness: roundness, count: n))
            }
        }

        // Line each ring up with the one before (turned to start where it matches best), so
        // sections whose outlines start at different places don't twist the skin.
        for i in 1..<rings.count { rings[i] = aligned(rings[i], to: rings[i - 1]) }

        // Rings along the axis: a monotone cubic through the sections (smooth), or straight spans
        // with a doubled ring at each inner section so its crease can stay hard.
        let xs = kept.map(\.along)
        struct Ring { var along: Float; var points: [Vec2]; var strip: Int }
        var all: [Ring] = []
        let spans = kept.count - 1
        if smooth && kept.count > 2 {
            // One channel per coordinate: the center and every ring point.
            var channels: [[Float]] = [kept.map(\.center.x), kept.map(\.center.y)]
            for k in 0..<n { channels.append(rings.map { $0[k].x }); channels.append(rings.map { $0[k].y }) }
            let slopes = channels.map { pchipSlopes(xs, $0) }
            let steps = max(2, min(12, maxCurveRings / 4 / spans))
            for span in 0..<spans {
                for k in 0...(span == spans - 1 ? steps : steps - 1) {
                    let t = Float(k) / Float(steps)
                    let values = channels.indices.map { hermite(xs, channels[$0], slopes[$0], span: span, t: t) }
                    let center = Vec2(values[0], values[1])
                    let points = (0..<n).map { Vec2(values[2 + 2 * $0], values[3 + 2 * $0]) + center }
                    all.append(Ring(along: xs[span] + (xs[span + 1] - xs[span]) * t, points: points, strip: 0))
                }
            }
        } else {
            for span in 0..<spans {
                for end in [span, span + 1] {
                    all.append(Ring(along: xs[end], points: rings[end].map { $0 + kept[end].center }, strip: span))
                }
            }
        }

        let (au, av) = axis.sectionAxes
        func place(_ along: Float, _ p: Vec2) -> Vec3 {
            var v = Vec3.zero
            v[axis.index] = along
            v[au] = p.x
            v[av] = p.y
            return v
        }
        let eu = place(0, Vec2(1, 0)), ev = place(0, Vec2(0, 1)), ea = place(1, .zero)
        let rightHanded = dot(cross(eu, ev), ea) > 0
        let lo = xs[0], hi = xs[xs.count - 1]
        var g = MeshGeometry(vertices: [], indices: [])
        // Columns around: a point whose outline turns sharper than `sharpAngle` in any section gets
        // two (one per side), so a hull's deck edge or a box section's corner stays hard.
        let cosSharp = cosf(sharpAngle * .pi / 180)
        let sharp: [Bool] = (0..<n).map { k in
            rings.contains { r in
                let a = r[k] - r[(k + n - 1) % n], b = r[(k + 1) % n] - r[k]
                return len2(a) > 1e-7 && len2(b) > 1e-7 && dot2(norm2(a), norm2(b)) < cosSharp
            }
        }
        // (point, side: -1 the edge before it, +1 the edge after, 0 both).
        var columns: [(k: Int, side: Int, u: Float)] = []
        for j in 0...n {
            let k = j % n, u = Float(j) / Float(n)
            if sharp[k] {
                if j > 0 { columns.append((k, -1, u)) }
                if j < n { columns.append((k, 1, u)) }
            } else {
                columns.append((k, 0, u))
            }
        }
        let cols = columns.count
        for (i, ring) in all.enumerated() {
            // Along the axis within this ring's strip, for the starting normals.
            let before = i > 0 && all[i - 1].strip == ring.strip ? all[i - 1] : ring
            let after = i + 1 < all.count && all[i + 1].strip == ring.strip ? all[i + 1] : ring
            for (k, side, u) in columns {
                let p = place(ring.along, ring.points[k])
                let next = side < 0 ? ring.points[k] : ring.points[(k + 1) % n]
                let previous = side > 0 ? ring.points[k] : ring.points[(k + n - 1) % n]
                let t2 = next - previous
                let around = place(0, t2)
                let alongAxis = place(after.along, after.points[k]) - place(before.along, before.points[k])
                let outward = place(0, Vec2(t2.y, -t2.x))
                var normal = cross(around, alongAxis)
                if length(normal) < 1e-12 { normal = outward }
                if dot(normal, outward) < 0 { normal = -normal }
                g.vertices.append(MeshVertex(position: p, normal: length(normal) > 0 ? normalize(normal) : ea,
                                             uv: Vec2(u, 1 - (ring.along - lo) / max(hi - lo, 1e-6))))
            }
        }
        for i in 0..<all.count - 1 where all[i].strip == all[i + 1].strip {
            for j in 0..<cols - 1 where columns[j].k != columns[j + 1].k {
                let a = UInt32(i * cols + j), b = a + 1, d = UInt32((i + 1) * cols + j), c = d + 1
                g.indices += rightHanded ? [a, b, c, a, c, d] : [a, c, b, a, d, c]
            }
        }
        // Flat caps on the end sections that have an area.
        for (ringIndex, faceUp) in [(0, false), (all.count - 1, true)] {
            let points = all[ringIndex].points
            guard abs(doubleSignedArea(points)) > 1e-10, let (center, triangles) = capTriangles(points) else { continue }
            let lo2 = points.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
            let hi2 = points.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
            let extent = pointwiseMax(hi2 - lo2, Vec2(1e-6, 1e-6))
            let base = UInt32(g.vertices.count)
            for p in points + (center.map { [$0] } ?? []) {
                let t = (p - lo2) / extent
                g.vertices.append(MeshVertex(position: place(all[ringIndex].along, p), normal: faceUp ? ea : -ea, uv: Vec2(t.x, 1 - t.y)))
            }
            // A counter-clockwise ring faces +axis when the section axes are right-handed with it.
            let asListed = faceUp == rightHanded
            for (a, b, c) in triangles {
                g.indices += asListed ? [base + UInt32(a), base + UInt32(b), base + UInt32(c)]
                                      : [base + UInt32(a), base + UInt32(c), base + UInt32(b)]
            }
        }
        g.refreshNormals(sharpAngle: sharpAngle)
        return g
    }

    /// Triangles filling the counter-clockwise outline, counter-clockwise: a fan from its center
    /// (index `points.count`) when it is convex, so every outline point is used and the cap meets
    /// the sides exactly; else ear clipping (no center).
    static func capTriangles(_ points: [Vec2]) -> (center: Vec2?, triangles: [(Int, Int, Int)])? {
        let n = points.count
        guard n >= 3 else { return nil }
        let scale = points.reduce(Float(0)) { max($0, abs($1.x), abs($1.y)) }
        let convex = (0..<n).allSatisfy { i in
            let a = points[i], b = points[(i + 1) % n], c = points[(i + 2) % n]
            let d1 = b - a, d2 = c - b
            return d1.x * d2.y - d1.y * d2.x >= -1e-7 * max(scale * scale, 1e-9)
        }
        if convex {
            let center = points.reduce(Vec2.zero, +) / Float(n)
            return (center, (0..<n).map { (n, $0, ($0 + 1) % n) })
        }
        return earClip(points).map { (nil, $0) }
    }

    /// `ring` turned (its start moved) to best match `reference` point for point, both scaled to a unit box.
    static func aligned(_ ring: [Vec2], to reference: [Vec2]) -> [Vec2] {
        let n = ring.count
        guard n == reference.count, n > 2 else { return ring }
        func normalized(_ r: [Vec2]) -> [Vec2] {
            let lo = r.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
            let hi = r.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
            let c = (lo + hi) / 2, e = pointwiseMax(hi - lo, Vec2(1e-6, 1e-6))
            return r.map { ($0 - c) / e }
        }
        let a = normalized(ring), b = normalized(reference)
        // A ring shrunk to a point matches any way round.
        guard (ring.contains { len2($0 - ring[0]) > 1e-7 }), (reference.contains { len2($0 - reference[0]) > 1e-7 }) else { return ring }
        var best = 0, bestCost = Float.infinity
        for shift in 0..<n {
            var cost: Float = 0
            for j in 0..<n {
                let d = a[(j + shift) % n] - b[j]
                cost += dot2(d, d)
            }
            if cost < bestCost - 1e-6 { best = shift; bestCost = cost }
        }
        return best == 0 ? ring : (0..<n).map { ring[($0 + best) % n] }
    }

    /// `count` points around a superellipse of half-size `half`, counter-clockwise from +across,
    /// at even parameter steps; the exponent is 2^roundness (clamped to 0...6).
    static func superellipse(half: Vec2, roundness: Float, count: Int) -> [Vec2] {
        let exponent = powf(2, min(max(roundness, 0), 6))
        let power = 2 / exponent
        return (0..<count).map { k in
            let a = Float(k) / Float(count) * 2 * .pi
            let c = cosf(a), s = sinf(a)
            func f(_ x: Float) -> Float { x == 0 ? 0 : (x < 0 ? -1 : 1) * powf(abs(x), power) }
            return Vec2(half.x * f(c), half.y * f(s))
        }
    }

    /// `count` points evenly spaced by length around the closed outline, starting at its first point.
    static func resample(_ outline: [Vec2], count: Int) -> [Vec2] {
        let m = outline.count
        var along: [Float] = [0]
        for i in 0..<m { along.append(along[i] + len2(outline[(i + 1) % m] - outline[i])) }
        let total = along[m]
        guard total > 0 else { return Array(repeating: outline[0], count: count) }
        var result: [Vec2] = []
        var edge = 0
        for k in 0..<count {
            let target = Float(k) / Float(count) * total
            while edge < m - 1 && along[edge + 1] < target { edge += 1 }
            let span = along[edge + 1] - along[edge]
            let t = span > 0 ? (target - along[edge]) / span : 0
            result.append(outline[edge] + (outline[(edge + 1) % m] - outline[edge]) * t)
        }
        return result
    }

    /// Fritsch–Carlson slopes for a monotone cubic through (`xs`, `ys`): no overshoot between points.
    static func pchipSlopes(_ xs: [Float], _ ys: [Float]) -> [Float] {
        let n = xs.count
        guard n > 1 else { return [0] }
        let h = (0..<n - 1).map { xs[$0 + 1] - xs[$0] }
        let delta = (0..<n - 1).map { (ys[$0 + 1] - ys[$0]) / h[$0] }
        guard n > 2 else { return [delta[0], delta[0]] }
        var m = [Float](repeating: 0, count: n)
        for i in 1..<n - 1 where delta[i - 1] * delta[i] > 0 {
            let w1 = 2 * h[i] + h[i - 1], w2 = h[i] + 2 * h[i - 1]
            m[i] = (w1 + w2) / (w1 / delta[i - 1] + w2 / delta[i])
        }
        func end(_ h0: Float, _ h1: Float, _ d0: Float, _ d1: Float) -> Float {
            var d = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1)
            if d * d0 <= 0 { d = 0 } else if d0 * d1 <= 0 && abs(d) > abs(3 * d0) { d = 3 * d0 }
            return d
        }
        m[0] = end(h[0], h[1], delta[0], delta[1])
        m[n - 1] = end(h[n - 2], h[n - 3], delta[n - 2], delta[n - 3])
        return m
    }

    /// The cubic Hermite between point `span` and the next at `t` (0...1).
    static func hermite(_ xs: [Float], _ ys: [Float], _ m: [Float], span i: Int, t: Float) -> Float {
        let h = xs[i + 1] - xs[i]
        let t2 = t * t, t3 = t2 * t
        return (2 * t3 - 3 * t2 + 1) * ys[i] + (t3 - 2 * t2 + t) * h * m[i] + (-2 * t3 + 3 * t2) * ys[i + 1] + (t3 - t2) * h * m[i + 1]
    }
}

private func dot2(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
private func len2(_ v: Vec2) -> Float { dot2(v, v).squareRoot() }
private func norm2(_ v: Vec2) -> Vec2 {
    let l = len2(v)
    return l > 0 ? v / l : v
}
