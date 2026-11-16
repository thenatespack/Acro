import Engine
import Foundation

// Spatial checks on a mesh build, so an agent building one blind learns where its parts ended up
// and what looks wrong: the overall bounds and warnings about floating, buried, hidden, flat and
// out-of-scale parts and a model that doesn't stand on y = 0.
//
// Everything is measured from each part's generated geometry (`MeshBuildPart.geometry()`) placed
// through the parent chain in the rest pose, so new shapes are covered without a table here.
// Boxes are world-space AABBs of the transformed vertices: a rotated part's box is a bit larger
// than the part, which can hide a gap (no false "floating") but never invent one.

/// A mesh build's extent in its own space (rest pose), meters, rounded to millimeters.
public struct MeshBuildBounds: Codable, Equatable, Sendable {
    /// Overall size [x, y, z].
    public var size: Vec3
    public var min: Vec3
    public var max: Vec3
    /// The lowest point's height: 0 when the model stands on the ground (y = 0).
    public var base: Float
    /// Every part's box (meshBuild.get; parts without a mesh are left out).
    public var parts: [MeshBuildPartBounds]?
}

/// One part's world-space box.
public struct MeshBuildPartBounds: Codable, Equatable, Sendable {
    public var part: String
    public var min: Vec3
    public var max: Vec3
}

/// The spatial analysis of one mesh build (see the notes at the top of this file).
struct MeshBuildSpatial {
    /// How close parts (and the ground) must be to count as touching, meters.
    static let contactTolerance: Float = 0.01
    /// How far the lowest point may be from y = 0 before the model counts as not standing on it.
    static let groundTolerance: Float = 0.01
    /// A part this many times larger than the median of the others is out of scale.
    static let scaleOutlierRatio: Float = 30
    /// Parts smaller than this (largest side, meters) can't be seen.
    static let tinyPartSize: Float = 0.002
    /// A whole model larger or smaller than this (largest side, meters) is probably in the wrong unit.
    static let largestModelSize: Float = 200
    static let smallestModelSize: Float = 0.01
    /// Vertices of a part tested for being inside another (its extremes plus an even spread).
    static let hiddenSampleCount = 48
    /// Margin a part's box must keep inside another's before it is tested for being hidden.
    static let hiddenMargin: Float = 0.001

    struct Placed {
        var part: MeshBuildPart
        var world: Mat4
        /// The geometry in the part's own space (nil: a group or an empty mesh).
        var geometry: MeshGeometry?
        var lo: Vec3
        var hi: Vec3
    }

    /// Every part with a mesh, in file order.
    let placed: [Placed]
    /// Every part's world matrix by name (the first part of a name).
    let worldMatrices: [String: Mat4]
    let parts: [MeshBuildPart]
    /// The `mirror` / `repeat` copies: the scale check counts each source part once, so many small
    /// copies (bolts, spokes) don't make the other parts look oversized.
    let copyNames: Set<String>

    init(_ build: MeshBuild) {
        let parts = MeshBuildCheck.parts(of: build)
        self.parts = parts
        copyNames = build.hasCopies ? Set(build.expansion().copies) : []
        var firstIndex: [String: Int] = [:]
        for (i, part) in parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        // World matrices through the parent chain; a missing parent or a loop hangs from the root (as in the importer).
        var matrices: [Int: Mat4] = [:]
        func world(_ i: Int, _ visiting: Set<Int>) -> Mat4 {
            if let m = matrices[i] { return m }
            let local = parts[i].transform.matrix
            var m = local
            if let p = firstIndex[parts[i].parent], p != i, !visiting.contains(p) {
                m = world(p, visiting.union([i])) * local
            }
            matrices[i] = m
            return m
        }
        var placed: [Placed] = []
        var byName: [String: Mat4] = [:]
        for (i, part) in parts.enumerated() {
            let m = world(i, [i])
            if byName[part.name] == nil { byName[part.name] = m }
            guard let g = part.geometry(), !g.indices.isEmpty, !g.vertices.isEmpty else { continue }
            var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
            for v in g.vertices {
                let p = Self.point(m, v.position)
                lo = pointwiseMin(lo, p)
                hi = pointwiseMax(hi, p)
            }
            placed.append(Placed(part: part, world: m, geometry: g, lo: lo, hi: hi))
        }
        self.placed = placed
        worldMatrices = byName
    }

    static func point(_ m: Mat4, _ p: Vec3) -> Vec3 {
        let r = m * Vec4(p.x, p.y, p.z, 1)
        return Vec3(r.x, r.y, r.z)
    }

    // MARK: Bounds

    /// The overall box, with each part's when `includeParts` (nil: no part has a mesh).
    func bounds(includeParts: Bool) -> MeshBuildBounds? {
        guard !placed.isEmpty else { return nil }
        let lo = placed.map(\.lo).reduce(Vec3(repeating: .infinity), pointwiseMin)
        let hi = placed.map(\.hi).reduce(Vec3(repeating: -.infinity), pointwiseMax)
        let r = Self.rounded
        return MeshBuildBounds(size: r(hi - lo), min: r(lo), max: r(hi), base: Self.mm(lo.y),
                               parts: includeParts ? placed.map { MeshBuildPartBounds(part: $0.part.name, min: r($0.lo), max: r($0.hi)) } : nil)
    }

    static func mm(_ x: Float) -> Float {
        let r = (x * 1000).rounded() / 1000
        return r == 0 ? 0 : r  // no -0
    }

    static func rounded(_ v: Vec3) -> Vec3 { Vec3(mm(v.x), mm(v.y), mm(v.z)) }

    /// A length for a message: meters to the millimeter, without trailing zeros.
    static func meters(_ x: Float) -> String {
        let r = mm(x)
        if r == r.rounded() { return String(Int(r)) }
        var s = String(format: "%.3f", r)
        while s.hasSuffix("0") { s.removeLast() }
        return s
    }

    // MARK: Warnings

    /// What looks wrong, phrased as what to do about it.
    func warnings() -> [String] {
        var warnings: [String] = []
        warnings += sizeWarnings()
        guard !placed.isEmpty else { return warnings }
        warnings += groundWarnings()
        warnings += floatingWarnings()
        warnings += hiddenWarnings()
        warnings += scaleWarnings()
        return warnings
    }

    /// Negative sizes (the sign is ignored) and zero sizes on an axis the shape uses.
    private func sizeWarnings() -> [String] {
        var warnings: [String] = []
        for part in parts where part.geometry() != nil {
            let axes = ["x", "y", "z"]
            let negative = (0..<3).filter { part.size[$0] < 0 }
            if !negative.isEmpty {
                warnings.append("part '\(part.name)' has a negative size on \(negative.map { axes[$0] }.joined(separator: ", ")): "
                                + "sizes are always used as positive; to flip a part, rotate it instead")
            }
            var unit = part
            unit.size = Vec3(1, 1, 1)
            guard let g = unit.geometry(), !g.vertices.isEmpty else { continue }
            let extent = g.bounds.halfExtent * 2
            let zero = (0..<3).filter { abs(part.size[$0]) < 1e-5 && extent[$0] > 1e-4 }
            if !zero.isEmpty {
                warnings.append("part '\(part.name)' has size 0 on \(zero.map { axes[$0] }.joined(separator: ", ")), "
                                + "so it is flat or invisible: give it a real thickness in meters")
            }
        }
        return warnings
    }

    /// The model should stand on y = 0, and no part should be wholly underground.
    private func groundWarnings() -> [String] {
        var warnings: [String] = []
        let lowest = placed.min { $0.lo.y < $1.lo.y }!
        let base = lowest.lo.y
        if base > Self.groundTolerance {
            warnings.append("the lowest point is \(Self.meters(base)) m above the ground; models stand on y=0: "
                            + "move the root parts down \(Self.meters(base)) m (positions are part centers)")
        } else if base < -Self.groundTolerance {
            warnings.append("the lowest point is \(Self.meters(-base)) m below the ground (part '\(lowest.part.name)'); models stand on y=0: "
                            + "raise it (or the whole model) by \(Self.meters(-base)) m")
        }
        for p in placed where p.hi.y < -Self.groundTolerance {
            warnings.append("part '\(p.part.name)' is entirely below the ground (its top is at y=\(Self.meters(p.hi.y))): "
                            + "it can't be seen when the model stands on y=0")
        }
        return warnings
    }

    /// The gap between two boxes (0 when they touch or overlap).
    static func gap(_ a: Placed, _ b: Placed) -> Float {
        length(pointwiseMax(pointwiseMax(a.lo - b.hi, b.lo - a.hi), .zero))
    }

    /// Groups of parts that touch neither the rest of the model nor the ground (the model's base).
    private func floatingWarnings() -> [String] {
        guard placed.count > 1 else { return [] }
        let base = placed.map(\.lo.y).min()!
        // Connected groups of touching parts (union-find).
        var root = Array(placed.indices)
        func find(_ i: Int) -> Int {
            var i = i
            while root[i] != i { root[i] = root[root[i]]; i = root[i] }
            return i
        }
        for i in placed.indices {
            for j in placed.indices where j > i && Self.gap(placed[i], placed[j]) <= Self.contactTolerance {
                root[find(i)] = find(j)
            }
        }
        var groups: [Int: [Int]] = [:]
        for i in placed.indices { groups[find(i), default: []].append(i) }
        guard groups.count > 1 else { return [] }
        var warnings: [String] = []
        for members in groups.values.sorted(by: { $0[0] < $1[0] }) {
            guard !members.contains(where: { placed[$0].lo.y <= base + Self.contactTolerance }) else { continue }
            let inGroup = Set(members)
            var nearest: (name: String, gap: Float)?
            for i in members {
                for j in placed.indices where !inGroup.contains(j) {
                    let d = Self.gap(placed[i], placed[j])
                    if nearest == nil || d < nearest!.gap { nearest = (placed[j].part.name, d) }
                }
            }
            let names = members.map { "'\(placed[$0].part.name)'" }
            let subject = names.count == 1 ? "part \(names[0]) floats: it touches" : "parts \(names.joined(separator: ", ")) float: they touch"
            let hint = nearest.map { " (nearest: '\($0.name)', \(Self.meters($0.gap)) m away)" } ?? ""
            warnings.append("\(subject) no other part and not the ground\(hint); move \(names.count == 1 ? "it" : "them") "
                            + "until the boxes meet, or check the parent and position (positions are part centers in the parent's space)")
        }
        return warnings
    }

    /// Parts wholly inside another opaque, closed part: they can't be seen.
    private func hiddenWarnings() -> [String] {
        var warnings: [String] = []
        var closed: [Int: Bool] = [:]
        for (i, inner) in placed.enumerated() {
            for (j, outer) in placed.enumerated() where i != j {
                guard outer.part.opacity >= 1, outer.part.material.isEmpty,
                      all(inner.lo, greaterThan: outer.lo + Vec3(repeating: Self.hiddenMargin)),
                      all(outer.hi - Vec3(repeating: Self.hiddenMargin), greaterThan: inner.hi),
                      let outerGeometry = outer.geometry, let innerGeometry = inner.geometry else { continue }
                if closed[j] == nil { closed[j] = Self.isClosed(outerGeometry) }
                guard closed[j] == true else { continue }
                let toOuter = outer.world.inverse * inner.world
                let samples = Self.samples(of: innerGeometry).map { Self.point(toOuter, $0) }
                if samples.allSatisfy({ Self.contains(outerGeometry, $0) }) {
                    warnings.append("part '\(inner.part.name)' is hidden inside '\(outer.part.name)', which is opaque: it can't be seen; "
                                    + "move it out, make it bigger, lower '\(outer.part.name)' opacity, or remove it")
                    break
                }
            }
        }
        return warnings
    }

    private func all(_ a: Vec3, greaterThan b: Vec3) -> Bool { a.x > b.x && a.y > b.y && a.z > b.z }

    /// A part's extreme vertices on each axis plus an even spread of the rest.
    static func samples(of g: MeshGeometry) -> [Vec3] {
        let positions = g.vertices.map(\.position)
        var result: [Vec3] = []
        for axis in 0..<3 {
            if let lo = positions.min(by: { $0[axis] < $1[axis] }) { result.append(lo) }
            if let hi = positions.max(by: { $0[axis] < $1[axis] }) { result.append(hi) }
        }
        let stride = Swift.max(positions.count / hiddenSampleCount, 1)
        for i in Swift.stride(from: 0, to: positions.count, by: stride) { result.append(positions[i]) }
        return result
    }

    /// Whether every edge of the mesh (vertices welded by position) is shared by an even number
    /// of triangles: a closed surface, whose inside is well defined.
    static func isClosed(_ g: MeshGeometry) -> Bool {
        var ids: [SIMD3<Int32>: Int] = [:]
        func id(_ p: Vec3) -> Int {
            let key = SIMD3<Int32>(Int32((p.x * 1e4).rounded()), Int32((p.y * 1e4).rounded()), Int32((p.z * 1e4).rounded()))
            if let id = ids[key] { return id }
            ids[key] = ids.count
            return ids.count - 1
        }
        var edges: [SIMD2<Int>: Int] = [:]
        for t in Swift.stride(from: 0, to: g.indices.count - 2, by: 3) {
            let v = (0..<3).map { id(g.vertices[Int(g.indices[t + $0])].position) }
            guard v[0] != v[1], v[1] != v[2], v[0] != v[2] else { continue }
            for k in 0..<3 {
                let a = v[k], b = v[(k + 1) % 3]
                edges[SIMD2(Swift.min(a, b), Swift.max(a, b)), default: 0] += 1
            }
        }
        return !edges.isEmpty && edges.values.allSatisfy { $0 % 2 == 0 }
    }

    /// Whether `p` is inside the closed mesh `g` (ray-crossing parity along a skewed direction).
    static func contains(_ g: MeshGeometry, _ p: Vec3) -> Bool {
        let d = normalize(Vec3(0.5377, 0.8291, 0.1532))
        var crossings = 0
        for t in Swift.stride(from: 0, to: g.indices.count - 2, by: 3) {
            let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
            let c = g.vertices[Int(g.indices[t + 2])].position
            // Möller–Trumbore.
            let e1 = b - a, e2 = c - a
            let h = cross(d, e2)
            let det = dot(e1, h)
            guard abs(det) > 1e-12 else { continue }
            let f = 1 / det
            let s = p - a
            let u = f * dot(s, h)
            guard u >= 0, u <= 1 else { continue }
            let q = cross(s, e1)
            let v = f * dot(d, q)
            guard v >= 0, u + v <= 1 else { continue }
            if f * dot(e2, q) > 1e-7 { crossings += 1 }
        }
        return crossings % 2 == 1
    }

    /// Parts far larger than the rest, parts too small to see, and whole models in the wrong unit.
    private func scaleWarnings() -> [String] {
        var warnings: [String] = []
        let extents = placed.map { p in Swift.max(p.hi.x - p.lo.x, p.hi.y - p.lo.y, p.hi.z - p.lo.z) }
        let lo = placed.map(\.lo).reduce(Vec3(repeating: .infinity), pointwiseMin)
        let hi = placed.map(\.hi).reduce(Vec3(repeating: -.infinity), pointwiseMax)
        let overall = Swift.max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
        if overall > Self.largestModelSize {
            warnings.append("the model is \(Self.meters(overall)) m across: sizes are meters (a person is 1.8 m tall, a car 4.5 m long)")
        } else if overall < Self.smallestModelSize {
            warnings.append("the model is only \(Self.meters(overall)) m across: sizes are meters (a person is 1.8 m tall, a mug 0.1 m)")
        }
        for (i, p) in placed.enumerated() {
            if extents[i] < Self.tinyPartSize, overall >= Self.smallestModelSize {
                warnings.append("part '\(p.part.name)' is only \(Self.meters(extents[i])) m across, too small to see: sizes are meters")
                continue
            }
            guard !copyNames.contains(p.part.name) else { continue }
            let others = extents.enumerated().filter { $0.offset != i && !copyNames.contains(placed[$0.offset].part.name) }
                .map(\.element).sorted()
            guard others.count >= 2 else { continue }
            let median = others[others.count / 2]
            if median > 0, extents[i] > Self.scaleOutlierRatio * median {
                warnings.append("part '\(p.part.name)' is \(Self.meters(extents[i])) m across, \(Int(extents[i] / median)) times the "
                                + "other parts' typical \(Self.meters(median)) m: check its size (meters) and that it belongs to this model")
            }
        }
        return warnings
    }
}

extension MeshBuildCheck {
    /// The parts the checks look at, as the importer makes them: the file's parts in order, then
    /// the `mirror` / `repeat` copies. A sculpt's children are part of its mesh, not parts of their own.
    nonisolated static func parts(of build: MeshBuild) -> [MeshBuildPart] {
        let expansion = build.expansion()
        return expansion.build.gatheringSculpts(sources: expansion.sources).drawnParts
    }

    /// The overall bounds and the spatial warnings of `build` (`includeParts`: every part's box too).
    nonisolated static func spatial(_ build: MeshBuild, includeParts: Bool = false) -> (bounds: MeshBuildBounds?, warnings: [String]) {
        let spatial = MeshBuildSpatial(build)
        return (spatial.bounds(includeParts: includeParts), spatial.warnings())
    }
}
