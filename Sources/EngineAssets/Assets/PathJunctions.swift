import Foundation
import EngineCore
import EngineGraphics
import EngineScene

// Junctions between paths. A path lists the other paths it meets (`junctions`): where its
// centerline crosses another's it makes an X junction, and where one of its ends stops at (or just
// short of, or just past) another it makes a T. The other road stays whole; this one is cut back
// from the other's edges (its profiles and pieces leave a gap there) and a paved patch with rounded
// corners fills the gap, at the height of both surfaces. The patch is added to this path's paving
// profile (its widest flat or box profile), with that profile's look and collider.

/// Another path this one meets: a T where one of this path's ends stops at it, an X where this
/// path crosses it.
public struct PathJunction: Codable, Equatable, Sendable {
    /// The other `.path` (a path under `Assets/` or "asset:<id>").
    public var path: String
    /// Meters: how round the corners where the two roads meet are.
    public var radius: Float
    /// Where the other path's origin is in this path's space (both placed at the same spot: zero).
    public var offset: Vec3

    public static var fieldHints: [String: FieldHints] {
        ["path": FieldHints(tooltip: "The other .path this one meets or crosses"),
         "radius": FieldHints(range: 0...100, step: 0.1, tooltip: "Meters: how round the corners are where the roads meet"),
         "offset": FieldHints(step: 0.1, tooltip: "The other path's origin in this path's space (zero when both are placed at the same spot)")]
    }

    public init(path: String = "", radius: Float = 3, offset: Vec3 = .zero) {
        self.path = path
        self.radius = radius
        self.offset = offset
    }

    private enum CodingKeys: String, CodingKey { case path, radius, offset }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathJunction()
        self.init(path: try c.decodeIfPresent(String.self, forKey: .path) ?? d.path,
                  radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? d.offset)
    }
}

/// The other side of a junction, ready to join: its centerline samples in this path's space.
public struct PathJunctionTarget: Sendable {
    public var junction: PathJunction
    public var samples: [PathSample]
    /// Half the other road's paved width (before per-point width) and its surface height above the centerline.
    public var halfWidth: Float
    public var surface: Float

    public init(_ junction: PathJunction, other: PathBuild, samples: [PathSample]) {
        self.junction = junction
        self.samples = samples.map { var s = $0; s.position += junction.offset; return s }
        let paving = other.pavingProfile
        halfWidth = paving.map { abs($0.offset.x) + max($0.width, 0.001) / 2 } ?? other.profileWidth / 2
        surface = paving?.surfaceHeight ?? 0
    }
}

/// Where junctions cut a path and the patches that pave them.
public struct PathJunctionLayout: Sendable {
    /// Distance ranges along the path with no profiles or pieces.
    public var cuts: [ClosedRange<Float>] = []
    /// The paving, in the path's space (up-facing tops, plus skirts for a box profile).
    public var patch: MeshGeometry?
    /// One line per junction made ("T with Roads/main.path at 40.2 m").
    public var made: [String] = []
    public var warnings: [String] = []
}

extension PathProfile {
    /// The height of the top of a flat or box profile above the centerline.
    var surfaceHeight: Float { offset.y + (shape == .box ? max(height, 0.001) : 0) }
}

extension PathBuild {
    /// The profile junctions pave with: the widest flat or box profile (nil without one).
    public var pavingProfile: PathProfile? {
        profiles.filter { $0.shape == .flat || $0.shape == .box }.max { abs($0.offset.x) + $0.width / 2 < abs($1.offset.x) + $1.width / 2 }
    }

    /// The cuts and paving for joining `targets`, along this path's `samples`.
    public func junctionLayout(_ targets: [PathJunctionTarget], samples: [PathSample]) -> PathJunctionLayout {
        var layout = PathJunctionLayout()
        guard !targets.isEmpty, samples.count > 1, let total = samples.last?.distance, total > 0 else { return layout }
        guard let paving = pavingProfile else {
            layout.warnings.append("junctions: no flat or box profile to pave them with")
            return layout
        }
        let half = abs(paving.offset.x) + max(paving.width, 0.001) / 2
        var patch = MeshGeometry(vertices: [], indices: [])
        for target in targets {
            let name = target.junction.path
            guard target.samples.count > 1 else {
                layout.warnings.append("junction '\(name)': the other path has no curve")
                continue
            }
            let radius = max(target.junction.radius, 0)
            let approaches = Self.approaches(samples, total: total, closed: wraps, to: target, half: half, radius: radius)
            if approaches.isEmpty { layout.warnings.append("junction '\(name)': the paths don't meet") }
            var kinds: [String] = []
            for approach in approaches {
                guard let made = Self.pave(approach, target: target, half: half, radius: radius, paving: paving, samples: samples,
                                           closed: wraps, into: &patch) else {
                    layout.warnings.append("junction '\(name)': the roads meet at too shallow an angle to join")
                    continue
                }
                layout.cuts.append(made)
                if !kinds.contains(approach.kind) { kinds.append(approach.kind) }
            }
            for kind in kinds { layout.made.append("\(kind) with \(name)") }
        }
        layout.cuts = Self.merged(layout.cuts)
        layout.patch = patch.indices.isEmpty ? nil : patch
        return layout
    }

    // MARK: Approaches

    /// One way this road comes up to the other: from `anchor` (meters along this path), heading
    /// `sign` (+1: increasing distance) toward the other road's centerline point `center`.
    struct Approach {
        var anchor: Float
        var sign: Float
        /// The cut runs from the paving's start to here (the path's end for a T), in this path's distance.
        var reach: Float
        var center: Vec3
        var mainForward: Vec3
        var kind: String
    }

    /// Where this path meets `target`: both approaches of each crossing (X), or one where an end
    /// is at or near the other road (T).
    static func approaches(_ samples: [PathSample], total: Float, closed: Bool, to target: PathJunctionTarget,
                           half: Float, radius: Float) -> [Approach] {
        let other = target.samples
        let near = target.halfWidth + half + radius
        var crossings: [(distance: Float, center: Vec3, mainForward: Vec3)] = []
        for i in 1..<samples.count {
            let a = samples[i - 1].position, b = samples[i].position
            for j in 1..<other.count {
                let c = other[j - 1].position, d = other[j].position
                guard let (t, u) = Self.intersect(a, b, c, d) else { continue }
                let distance = samples[i - 1].distance + (samples[i].distance - samples[i - 1].distance) * t
                let center = c + (d - c) * u
                let forward = Self.flat(d - c)
                // Skip a crossing found twice at a shared sample.
                if crossings.contains(where: { abs($0.distance - distance) < 0.01 }) { continue }
                crossings.append((distance, center, forward))
            }
        }
        var result: [Approach] = []
        for crossing in crossings.sorted(by: { $0.distance < $1.distance }) {
            let d = crossing.distance
            // Close enough to an end: a T (the stub past the other road is dropped).
            let toStart = closed ? Float.infinity : d, toEnd = closed ? Float.infinity : total - d
            if toEnd < near {
                result.append(Approach(anchor: d, sign: 1, reach: total, center: crossing.center, mainForward: crossing.mainForward, kind: "T"))
            } else if toStart < near {
                result.append(Approach(anchor: d, sign: -1, reach: 0, center: crossing.center, mainForward: crossing.mainForward, kind: "T"))
            } else {
                result.append(Approach(anchor: d, sign: 1, reach: d, center: crossing.center, mainForward: crossing.mainForward, kind: "X"))
                result.append(Approach(anchor: d, sign: -1, reach: d, center: crossing.center, mainForward: crossing.mainForward, kind: "X"))
            }
        }
        // An end that stops short of the other road (no crossing near it): a T reaching over to it.
        guard !closed else { return result }
        for (end, sign) in [(total, Float(1)), (Float(0), Float(-1))] {
            if result.contains(where: { $0.kind == "T" && $0.reach == end }) { continue }
            if crossings.contains(where: { abs($0.distance - end) < near }) { continue }
            guard let s = PathBuild.sample(samples, atDistance: end) else { continue }
            guard let (center, forward) = Self.nearest(s.position, on: other), Self.flatLength(center - s.position) < near else { continue }
            let heading = Self.flat(s.forward) * sign
            // Only when the end points at the other road.
            guard dot(heading, Self.flat(center - s.position)) > 0 || Self.flatLength(center - s.position) < 1e-3 else { continue }
            result.append(Approach(anchor: end, sign: sign, reach: end, center: center, mainForward: forward, kind: "T"))
        }
        return result
    }

    /// Paves one approach into `patch`; returns the distance range cut, nil when the roads are too
    /// close to parallel.
    static func pave(_ approach: Approach, target: PathJunctionTarget, half: Float, radius: Float, paving: PathProfile,
                     samples: [PathSample], closed: Bool, into patch: inout MeshGeometry) -> ClosedRange<Float>? {
        guard let anchor = PathBuild.sample(samples, atDistance: approach.anchor, closed: closed) else { return nil }
        let f = flat(anchor.forward) * approach.sign  // toward the other road
        let right = Vec3(-f.z, 0, f.x)                // this road's right, looking toward the other road
        let m = approach.mainForward
        var n = Vec3(-m.z, 0, m.x)
        if dot(n, f) > 0 { n = -n }                   // the other road's normal, pointing back at this road
        let facing = -dot(f, n)
        guard facing > 0.2 else { return nil }
        let otherAtCenter = nearestSample(approach.center, on: target.samples)
        let otherHalf = target.halfWidth * (otherAtCenter?.width ?? 1)
        let thisHalf = half * anchor.width
        let edgePoint = approach.center + n * otherHalf
        // Meters along f from `p` to the other road's near edge.
        func toEdge(_ p: Vec3) -> Float { dot(p - edgePoint, n) / facing }
        let base = Vec3(anchor.position.x, 0, anchor.position.z)
        let leftStart = base - right * thisHalf, rightStart = base + right * thisHalf
        let sLeft = toEdge(leftStart), sRight = toEdge(rightStart)
        // The paving starts `radius` before the nearer edge meets the other road (never past the anchor).
        let back = max(radius - min(sLeft, sRight), 0)
        let cutStart = approach.anchor - approach.sign * back
        let cut = min(cutStart, approach.reach)...max(cutStart, approach.reach)
        guard let start = PathBuild.sample(samples, atDistance: cutStart, closed: closed) else { return nil }

        // Heights: this road's surface at the cut, the other's along its edge.
        let thisTop = start.position.y + paving.surfaceHeight
        func otherTop(_ p: Vec3) -> Float {
            (nearestSample(p, on: target.samples)?.position.y ?? approach.center.y) + target.surface
        }
        let eLeft = Vec3(start.position.x, 0, start.position.z) - right * thisHalf
        let eRight = Vec3(start.position.x, 0, start.position.z) + right * thisHalf
        let mLeft = eLeft + f * toEdge(eLeft), mRight = eRight + f * toEdge(eRight)
        let alongEdgeLeft = dot(m, -right) >= 0 ? m : -m
        let bLeft = mLeft + alongEdgeLeft * radius, bRight = mRight - alongEdgeLeft * radius
        func lifted(_ p: Vec3, _ y: Float) -> Vec3 { Vec3(p.x, y, p.z) }
        let segments = radius > 0.01 ? 8 : 1
        func curve(_ a: Vec3, _ control: Vec3, _ b: Vec3) -> [Vec3] {
            (0...segments).map { i in
                let t = Float(i) / Float(segments)
                return a * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + b * (t * t)
            }
        }
        let leftCurve = curve(lifted(eLeft, thisTop), lifted(mLeft, otherTop(mLeft)), lifted(bLeft, otherTop(bLeft)))
        let rightCurve = curve(lifted(bRight, otherTop(bRight)), lifted(mRight, otherTop(mRight)), lifted(eRight, thisTop))
        let outline = leftCurve + rightCurve  // E_l … B_l, B_r … E_r; closes along the cut line
        addFan(outline, to: &patch, uvScale: paving.textureScale)
        if paving.shape == .box {
            let depth = max(paving.height, 0.001)
            let center = outline.reduce(Vec3.zero, +) / Float(outline.count)
            addSkirt(leftCurve, depth: depth, awayFrom: center, to: &patch)
            addSkirt(rightCurve, depth: depth, awayFrom: center, to: &patch)
        }
        return cut
    }

    /// An up-facing fan over `outline` from its centroid.
    static func addFan(_ outline: [Vec3], to g: inout MeshGeometry, uvScale: Vec2) {
        guard outline.count >= 3 else { return }
        let center = outline.reduce(Vec3.zero, +) / Float(outline.count)
        let start = UInt32(g.vertices.count)
        for p in [center] + outline {
            g.vertices.append(MeshVertex(position: p, normal: Vec3(0, 1, 0), uv: Vec2(p.x * uvScale.x, p.z * uvScale.y)))
        }
        let k = UInt32(outline.count)
        for i in 0..<k {
            let a = start + 1 + i, b = start + 1 + (i + 1) % k
            let pa = g.vertices[Int(a)].position, pb = g.vertices[Int(b)].position
            if cross(pa - center, pb - center).y >= 0 { g.indices += [start, a, b] } else { g.indices += [start, b, a] }
        }
    }

    /// The side of a raised patch: a strip down `depth` meters under `edge`, facing away from `center`.
    static func addSkirt(_ edge: [Vec3], depth: Float, awayFrom center: Vec3, to g: inout MeshGeometry) {
        guard edge.count >= 2 else { return }
        for i in 1..<edge.count {
            let a = edge[i - 1], b = edge[i]
            let along = b - a
            var normal = Vec3(along.z, 0, -along.x)
            guard EngineCore.length(normal) > 1e-6 else { continue }
            normal = normalize(normal)
            if dot(normal, (a + b) / 2 - center) < 0 { normal = -normal }
            let start = UInt32(g.vertices.count)
            let down = Vec3(0, -depth, 0)
            for p in [a, b, a + down, b + down] { g.vertices.append(MeshVertex(position: p, normal: normal, uv: Vec2(p.x + p.z, p.y))) }
            let pa = a, pb = b, pc = a + down
            if dot(cross(pb - pa, pc - pa), normal) >= 0 { g.indices += [start, start + 1, start + 2, start + 1, start + 3, start + 2] }
            else { g.indices += [start, start + 2, start + 1, start + 1, start + 2, start + 3] }
        }
    }

    // MARK: Cutting

    /// `samples` split into the runs outside `cuts` (with samples added at the cut edges).
    public static func runs(_ samples: [PathSample], outside cuts: [ClosedRange<Float>]) -> [[PathSample]] {
        guard !cuts.isEmpty, let total = samples.last?.distance else { return [samples] }
        var keep: [ClosedRange<Float>] = []
        var from: Float = samples.first?.distance ?? 0
        for cut in merged(cuts) {
            if cut.lowerBound > from { keep.append(from...cut.lowerBound) }
            from = max(from, cut.upperBound)
        }
        if from < total { keep.append(from...total) }
        return keep.compactMap { range -> [PathSample]? in
            guard range.upperBound - range.lowerBound > 1e-3,
                  let first = sample(samples, atDistance: range.lowerBound), let last = sample(samples, atDistance: range.upperBound) else { return nil }
            let inside = samples.filter { $0.distance > range.lowerBound + 1e-4 && $0.distance < range.upperBound - 1e-4 }
            return [first] + inside + [last]
        }
    }

    static func merged(_ ranges: [ClosedRange<Float>]) -> [ClosedRange<Float>] {
        var out: [ClosedRange<Float>] = []
        for r in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = out.last, r.lowerBound <= last.upperBound {
                out[out.count - 1] = last.lowerBound...max(last.upperBound, r.upperBound)
            } else {
                out.append(r)
            }
        }
        return out
    }

    // MARK: Geometry helpers

    static func flat(_ v: Vec3) -> Vec3 {
        let f = Vec3(v.x, 0, v.z)
        return EngineCore.length(f) > 1e-6 ? normalize(f) : Vec3(0, 0, -1)
    }

    static func flatLength(_ v: Vec3) -> Float { (v.x * v.x + v.z * v.z).squareRoot() }

    /// Where segments ab and cd cross on the XZ plane: the parameters along each, nil if they don't.
    static func intersect(_ a: Vec3, _ b: Vec3, _ c: Vec3, _ d: Vec3) -> (Float, Float)? {
        let r = Vec2(b.x - a.x, b.z - a.z), s = Vec2(d.x - c.x, d.z - c.z)
        let denom = r.x * s.y - r.y * s.x
        guard abs(denom) > 1e-9 else { return nil }
        let q = Vec2(c.x - a.x, c.z - a.z)
        let t = (q.x * s.y - q.y * s.x) / denom, u = (q.x * r.y - q.y * r.x) / denom
        guard t >= 0, t < 1, u >= 0, u <= 1 else { return nil }
        return (t, u)
    }

    /// The nearest point on the polyline `samples` to `p` (XZ), with the direction there.
    static func nearest(_ p: Vec3, on samples: [PathSample]) -> (Vec3, Vec3)? {
        var best: (Float, Vec3, Vec3)?
        for i in 1..<max(samples.count, 1) {
            let a = samples[i - 1].position, b = samples[i].position
            let ab = Vec3(b.x - a.x, 0, b.z - a.z), l2 = dot(ab, ab)
            let t = l2 > 1e-9 ? min(max(dot(Vec3(p.x - a.x, 0, p.z - a.z), ab) / l2, 0), 1) : 0
            let q = a + (b - a) * t
            let d = flatLength(q - p)
            if d < (best?.0 ?? .infinity) { best = (d, q, flat(b - a)) }
        }
        return best.map { ($0.1, $0.2) }
    }

    /// The sample of `samples` nearest to `p` (XZ).
    static func nearestSample(_ p: Vec3, on samples: [PathSample]) -> PathSample? {
        samples.min { flatLength($0.position - p) < flatLength($1.position - p) }
    }
}

extension MeshGeometry {
    /// `parts` as one mesh (nil when they draw nothing).
    static func joined(_ parts: [MeshGeometry]) -> MeshGeometry? {
        var out = MeshGeometry(vertices: [], indices: [])
        for part in parts where !part.indices.isEmpty {
            let base = UInt32(out.vertices.count)
            out.vertices += part.vertices
            out.indices += part.indices.map { $0 + base }
        }
        return out.indices.isEmpty ? nil : out
    }
}
