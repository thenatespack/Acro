import Foundation
import EngineCore
import EngineScene

// Ribbons: a `sweep` with `ribbon` (a width in meters) or `open: true` (its `profile` is an open
// curve, not an outline) is a surface, not a tube: the cross-section is moved along the path like
// any sweep (smooth spline or straight, rotation-minimizing frames, `radii` scaling it) but its
// ends stay open and nothing is capped. The material is double-sided, so either side shows.
//
// ```json
// {"name": "Blade", "shape": "sweep", "path": [[0,0,0],[0.02,0.3,0],[0.12,0.55,0.05]], "ribbon": 0.02, "radii": [1, 0.8, 0]},
// {"name": "Sail strip", "shape": "sweep", "path": [[0,0,0],[0,2,0]], "open": true, "profile": [[-0.5,0],[0,0.15],[0.5,0]]}
// ```
//
// A flat ribbon lies along the frame's right vector (the profile's x) and faces its up vector (y),
// which starts as the world's up (or -Z, the front, when the path starts straight up) and is
// carried along without twisting. An open profile is listed left to right (x increasing) so its
// front faces +y. U runs across (0 at the
// first profile point, 1 at the last); V runs along the path (0...1 from the start with a leaf
// look, whose sprig's base sits at the path's start; else in multiples of the section's width).

extension MeshBuildPart {
    /// The ribbon's mesh in meters (before `size`), nil (with a warning) if it can't be built.
    func ribbonGeometry(segments: Int, warnings: inout [String]) -> MeshGeometry? {
        // The open cross-section.
        var section: [Vec2]
        if let ribbon, ribbon.isFinite, ribbon > 0 {
            section = [Vec2(-ribbon / 2, 0), Vec2(ribbon / 2, 0)]
            if let profile, !profile.isEmpty { warnings.append("a ribbon is a flat strip, so its profile is ignored (use open:true for a curved one)") }
        } else if let profile, !profile.isEmpty {
            section = MeshGeometry.cleanProfile(profile, shape: "sweep", warnings: &warnings)
            guard section.count >= 2 else {
                warnings.append("an open sweep profile needs at least 2 different [x, y] points; nothing was built")
                return nil
            }
        } else {
            section = [Vec2(-0.025, 0), Vec2(0.025, 0)]
        }
        // The path and its radii, cleaned together.
        let raw = path ?? []
        if let radii, radii.count != raw.count {
            warnings.append("sweep radii has \(radii.count) values for \(raw.count) path points; missing ones are 1, extras are ignored")
        }
        var points: [Vec3] = [], scales: [Float] = []
        for (i, p) in raw.enumerated() where p.x.isFinite && p.y.isFinite && p.z.isFinite {
            var k: Float = 1
            if let radii, i < radii.count { k = radii[i].isFinite ? max(radii[i], 0) : 1 }
            if let last = points.last, length(p - last) <= 1e-6 { scales[scales.count - 1] = k; continue }
            points.append(p)
            scales.append(k)
        }
        var closed = closed ?? false
        if closed, points.count > 2, length(points[0] - points[points.count - 1]) <= 1e-6 {
            points.removeLast()
            scales.removeLast()
        }
        guard points.count >= 2 else {
            warnings.append("a sweep needs a path of at least 2 different [x, y, z] points (it has \(points.count)); nothing was built")
            return nil
        }
        if closed && points.count < 3 { closed = false }
        var samples = (straight ?? false)
            ? MeshGeometry.cornerSamples(points, scales: scales, closed: closed)
            : MeshGeometry.smoothSamples(points, scales: scales, closed: closed, ringStep: curveRingStep)
        guard samples.count >= 2 else { return nil }
        MeshGeometry.frame(&samples, closed: closed)

        // Columns across: one per point, two at a corner sharper than the sharp angle. The normal
        // is the left perpendicular, so a profile listed left to right faces +y (up).
        let n = section.count
        let edgeNormals: [Vec2] = (0..<n - 1).map { i in
            let d = section[i + 1] - section[i]
            let l = (d.x * d.x + d.y * d.y).squareRoot()
            return l > 0 ? Vec2(-d.y, d.x) / l : Vec2(0, 1)
        }
        var along: [Float] = [0]
        for i in 0..<n - 1 { let d = section[i + 1] - section[i]; along.append(along[i] + (d.x * d.x + d.y * d.y).squareRoot()) }
        let width = max(along[n - 1], 1e-6)
        let cosSharp = cosf(MeshGeometry.profileSharpAngle * .pi / 180)
        var columns: [(p: Vec2, n: Vec2, u: Float)] = []
        for i in 0..<n {
            let u = along[i] / width
            let incoming = i > 0 ? edgeNormals[i - 1] : nil, outgoing = i < n - 1 ? edgeNormals[i] : nil
            if let a = incoming, let b = outgoing, a.x * b.x + a.y * b.y < cosSharp {
                columns.append((section[i], a, u))
                columns.append((section[i], b, u))
            } else {
                let sum = (incoming ?? .zero) + (outgoing ?? .zero)
                let l = (sum.x * sum.x + sum.y * sum.y).squareRoot()
                columns.append((section[i], l > 0 ? sum / l : Vec2(0, 1), u))
            }
        }

        var total: Float = 0
        for i in 1..<samples.count { total += length(samples[i].position - samples[i - 1].position) }
        let leafy = resolvedLeafLook != nil
        var g = MeshGeometry(vertices: [], indices: [])
        let cols = columns.count
        var distance: Float = 0
        var firstRing: [Vec3] = []
        for (i, s) in samples.enumerated() {
            if i > 0 { distance += length(s.position - samples[i - 1].position) }
            let right = s.right
            let v = leafy ? 1 - distance / max(total, 1e-6) : distance / width
            var ring: [Vec3]
            if s.join || (closed && i == samples.count - 1) {
                ring = closed && i == samples.count - 1 ? firstRing : (0..<cols).map { g.vertices[(i - 1) * cols + $0].position }
            } else {
                ring = columns.map { MeshGeometry.ringPoint(s, right: right, $0.p) }
            }
            if i == 0 { firstRing = ring }
            for (j, c) in columns.enumerated() {
                g.vertices.append(MeshVertex(position: ring[j], normal: right * c.n.x + s.up * c.n.y, uv: Vec2(c.u, v)))
            }
        }
        // (i, j) → (i, j+1) → (i+1, j+1): faces the left perpendicular of the profile.
        for i in 0..<samples.count - 1 where !samples[i + 1].join {
            for j in 0..<cols - 1 where columns[j].p != columns[j + 1].p {
                let a = UInt32(i * cols + j), b = a + 1, d = UInt32((i + 1) * cols + j), c = d + 1
                g.indices += [a, b, c, a, c, d]
            }
        }
        g.refreshNormals(sharpAngle: MeshGeometry.profileSharpAngle)
        return g
    }
}
