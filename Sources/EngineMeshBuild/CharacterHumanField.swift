#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineAssets

// The distance field and mesher behind the realistic humanoid (CharacterHumanBody.swift builds the
// anatomy with it). Shapes are smooth-blended (polynomial smooth min) inside groups (the head, an
// arm, a finger, a leg...); groups join the body with a blend radius that is large only near
// their joint (a shoulder, a knuckle) and nearly zero elsewhere, so a finger merges into the palm
// at its knuckle but never webs to the next finger, and a hanging arm never fuses to the ribs.
// Pieces (the skin of the head, each forearm and hand, the shirt, the trousers, the shoes) are
// meshed separately with surface nets on a rectilinear grid that is finer where detail lives
// (the face, the hands), only in blocks near the surface, then relaxed and projected back onto
// the field; normals come from the field's gradient and ambient occlusion is baked from it.

/// One shape of the field, in a local frame (`q = axes * (p - center)`). Flat scalars: it is
/// evaluated millions of times.
struct HumanPrim {
    enum Kind: UInt8 { case ellipsoid, sphere, cone, torus, almond }
    enum Op: UInt8 { case add, subtract, intersect }

    var kind: Kind
    var op: Op = .add
    var group: Int32 = 0
    /// The skin-weight chain (`HumanChain`), -1: weighs nothing (carving shapes).
    var chain: Int32 = -1
    /// A part tag overriding the piece's (lips, nails), 255: the piece's.
    var tag: UInt8 = 255
    var k: Float = 0
    var cx: Float, cy: Float, cz: Float
    // Rows of the world-to-local rotation.
    var r00: Float = 1, r01: Float = 0, r02: Float = 0
    var r10: Float = 0, r11: Float = 1, r12: Float = 0
    var r20: Float = 0, r21: Float = 0, r22: Float = 1
    /// Shape parameters (see `distance`).
    var a: Float = 0, b: Float = 0, c: Float = 0, d: Float = 0, e: Float = 1, f: Float = 1
    var lo = Vec3.zero, hi = Vec3.zero

    init(kind: Kind, center: Vec3) {
        self.kind = kind
        cx = center.x; cy = center.y; cz = center.z
    }

    mutating func setAxes(x: Vec3, y: Vec3, z: Vec3) {
        r00 = x.x; r01 = x.y; r02 = x.z
        r10 = y.x; r11 = y.y; r12 = y.z
        r20 = z.x; r21 = z.y; r22 = z.z
    }

    @inline(__always) func distance(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        let dx = px - cx, dy = py - cy, dz = pz - cz
        switch kind {
        case .sphere:
            return (dx * dx + dy * dy + dz * dz).squareRoot() - a
        case .ellipsoid:
            let x = r00 * dx + r01 * dy + r02 * dz, y = r10 * dx + r11 * dy + r12 * dz, z = r20 * dx + r21 * dy + r22 * dz
            let ax = x / a, ay = y / b, az = z / c
            let k0 = (ax * ax + ay * ay + az * az).squareRoot()
            let bx = ax / a, by = ay / b, bz = az / c
            let k1 = (bx * bx + by * by + bz * bz).squareRoot()
            return k1 > 1e-12 ? k0 * (k0 - 1) / k1 : -min(a, min(b, c))
        case .cone:
            // A round cone along local +y from 0 (radius a) to d (radius b), its cross-section
            // scaled by e (local x) and f (local z).
            let x = (r00 * dx + r01 * dy + r02 * dz) / e, y = r10 * dx + r11 * dy + r12 * dz, z = (r20 * dx + r21 * dy + r22 * dz) / f
            let qx = (x * x + z * z).squareRoot()
            let h = d, r1 = a, r2 = b
            let sb = (r1 - r2) / h
            let ca = max(1 - sb * sb, 0).squareRoot()
            let k = -sb * qx + ca * y
            let s = min(e, f)
            if k < 0 { return ((qx * qx + y * y).squareRoot() - r1) * s }
            if k > ca * h { return ((qx * qx + (y - h) * (y - h)).squareRoot() - r2) * s }
            return (qx * ca + y * sb - r1) * s
        case .torus:
            // In the local xz plane: an ellipse of radii a (x) and c (z), a tube of radius b.
            let x = r00 * dx + r01 * dy + r02 * dz, y = r10 * dx + r11 * dy + r12 * dz, z = r20 * dx + r21 * dy + r22 * dz
            let ex = x / a, ez = z / c
            let ring = ((ex * ex + ez * ez).squareRoot() - 1) * min(a, c)
            return (ring * ring + y * y).squareRoot() - b
        case .almond:
            // The eye opening: an almond in the directions from the eye's center (local x toward
            // the temple, y up, z forward), between radii a and b. c, d: the corners' azimuths
            // (radians, medial negative); e, f: the upper and lower lids' heights (radians).
            let x = r00 * dx + r01 * dy + r02 * dz, y = r10 * dx + r11 * dy + r12 * dz, z = r20 * dx + r21 * dy + r22 * dz
            let r = (x * x + y * y + z * z).squareRoot()
            guard r > 1e-6 else { return a }
            let az = atan2f(x, z)
            let el = asinf(max(-1, min(1, y / r)))
            let mid = (c + d) / 2, half = (d - c) / 2
            let u = (az - mid) / half
            let dAz = abs(az - mid) - half
            let uc = max(-1, min(1, u))
            // Upper lid peaks a little toward the nose, the lower lid's low point toward the temple;
            // the outer corner sits a little higher (canthal tilt).
            let upU = uc + 0.18, loU = uc - 0.15
            let center = 0.06 * uc
            let upper = center + e * powf(max(1 - upU * upU / 1.38, 0), 0.65)
            let lower = center - f * powf(max(1 - loU * loU / 1.32, 0), 0.75)
            let dEl = max(el - upper, lower - el)
            let angular = max(dAz, dEl) * r
            return max(angular, max(a - r, r - b))
        }
    }

    /// The bounding box of where the shape is within its blend radius.
    mutating func computeBounds() {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        let center = Vec3(cx, cy, cz)
        let axes = [Vec3(r00, r01, r02), Vec3(r10, r11, r12), Vec3(r20, r21, r22)]
        switch kind {
        case .sphere:
            lo = center - Vec3(repeating: a); hi = center + Vec3(repeating: a)
        case .ellipsoid:
            var half = Vec3.zero
            let radii = [a, b, c]
            for i in 0..<3 { half += Vec3(Swift.abs(axes[i].x), Swift.abs(axes[i].y), Swift.abs(axes[i].z)) * radii[i] }
            lo = center - half; hi = center + half
        case .cone:
            let r = max(a, b) * max(e, f)
            let end = center + axes[1] * d
            lo = pointwiseMin(center, end) - Vec3(repeating: r); hi = pointwiseMax(center, end) + Vec3(repeating: r)
        case .torus:
            let r = max(a, c) + b
            lo = center - Vec3(repeating: r); hi = center + Vec3(repeating: r)
        case .almond:
            lo = center - Vec3(repeating: b); hi = center + Vec3(repeating: b)
        }
        self.lo = lo - Vec3(repeating: k)
        self.hi = hi + Vec3(repeating: k)
    }
}

/// How a group joins the body: blend radius `kNear` within `radius` of `center` (fading over
/// `fade`), `kFar` elsewhere.
struct HumanGroup {
    var center = Vec3.zero
    var radius: Float = 1e9
    var fade: Float = 1
    var kNear: Float = 0
    var kFar: Float = 0

    @inline(__always) func k(_ x: Float, _ y: Float, _ z: Float) -> Float {
        if radius >= 1e8 { return kNear }
        let dx = x - center.x, dy = y - center.y, dz = z - center.z
        let t = max(0, min(1, 1 - ((dx * dx + dy * dy + dz * dz).squareRoot() - radius) / fade))
        return kFar + (kNear - kFar) * t
    }
}

/// A chain of bones a shape's skin weights run along: `bones[0]` before `joints[0]`, blending
/// into `bones[1]` across it (over ± `width` along `axis`), and so on.
struct HumanChain {
    var bones: [Int]
    var joints: [(position: Vec3, axis: Vec3, width: Float)]

    func weights(_ p: Vec3, into w: inout [Float], scale: Float) {
        var carry: Float = scale
        for (i, joint) in joints.enumerated() {
            let s = HumanField.smoothstep(-joint.width, joint.width, dot(p - joint.position, joint.axis))
            w[bones[i]] += carry * (1 - s)
            carry *= s
        }
        w[bones[joints.count]] += carry
    }
}

@inline(__always) func humanSmin(_ a: Float, _ b: Float, _ k: Float) -> Float {
    if k <= 0 { return min(a, b) }
    let h = max(k - abs(a - b), 0) / k
    return min(a, b) - h * h * k * 0.25
}

@inline(__always) func humanSmax(_ a: Float, _ b: Float, _ k: Float) -> Float { -humanSmin(-a, -b, k) }

/// The shapes, groups and chains of one body.
final class HumanField: @unchecked Sendable {
    var prims: [HumanPrim] = []
    var groups: [HumanGroup] = []
    var chains: [HumanChain] = []
    var boneCount = 0

    static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = max(0, min(1, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    /// Prims sorted by group (groups join in their index order); call once after adding.
    func finish() {
        for i in prims.indices { prims[i].computeBounds() }
        prims = prims.enumerated().sorted { ($0.element.group, $0.offset) < ($1.element.group, $1.offset) }.map(\.element)
    }

    /// The field of the listed prims (indices ascending, so grouped), joined group by group.
    @inline(__always) func evaluate(_ x: Float, _ y: Float, _ z: Float, _ list: UnsafeBufferPointer<Int32>,
                                    _ primPointer: UnsafePointer<HumanPrim>, _ groupPointer: UnsafePointer<HumanGroup>) -> Float {
        var total: Float = 1e9
        var group: Int32 = -1
        var dg: Float = 1e9
        var i = 0
        let n = list.count
        while i < n {
            let p = primPointer[Int(list[i])]
            if p.group != group {
                if group >= 0 && dg < 1e8 {
                    total = total >= 1e8 ? dg : humanSmin(total, dg, groupPointer[Int(group)].k(x, y, z))
                }
                group = p.group
                dg = 1e9
            }
            let pd = p.distance(x, y, z)
            switch p.op {
            case .add: dg = humanSmin(dg, pd, p.k)
            case .subtract: dg = humanSmax(dg, -pd, p.k)
            case .intersect: dg = humanSmax(dg, pd, p.k)
            }
            i += 1
        }
        if group >= 0 && dg < 1e8 {
            total = total >= 1e8 ? dg : humanSmin(total, dg, groupPointer[Int(group)].k(x, y, z))
        }
        return total
    }
}

/// A piece of the body meshed on its own grid.
struct HumanPiece {
    enum Kind { case skin, shirt, trousers, shoes }
    var kind: Kind
    var groups: Set<Int32>
    var lo: Vec3
    var hi: Vec3
    var fineLo: Vec3
    var fineHi: Vec3
    var fine: Float
    var coarse: Float
    /// The part tag of its surface where no prim tags it.
    var tag: UInt8
    /// Keeps the side of each plane (point, normal) the normal points to.
    var keep: [(point: Vec3, normal: Vec3)] = []
}

/// A meshed piece: positions, normals, occlusion, tags, skin weights (dense per bone) and triangles.
struct HumanSurface {
    var positions: [Vec3] = []
    var normals: [Vec3] = []
    var occlusion: [Float] = []
    var tags: [UInt8] = []
    var weights: [[Float]] = []
    var triangles: [SIMD3<UInt32>] = []
}

/// Meshes one piece. `post` turns the body field into the piece's (clothing offsets, hems, cuts).
struct HumanMesher {
    let field: HumanField
    let piece: HumanPiece
    let post: (Float, Float, Float, Float) -> Float
    static let block = 8

    /// Coordinates from `lo` to `hi`: `fine` apart within fineLo...fineHi, growing toward `coarse` outside.
    static func axis(_ lo: Float, _ hi: Float, _ fineLo: Float, _ fineHi: Float, _ fine: Float, _ coarse: Float) -> [Float] {
        let fl = max(lo, min(fineLo, hi)), fh = min(hi, max(fineHi, lo))
        guard fh - fl > fine else {
            let n = max(Int(((hi - lo) / coarse).rounded(.up)), 2)
            return (0...n).map { lo + (hi - lo) * Float($0) / Float(n) }
        }
        let n = max(Int(((fh - fl) / fine).rounded(.up)), 1)
        var core = (0...n).map { fl + (fh - fl) * Float($0) / Float(n) }
        var step = (fh - fl) / Float(n)
        var x = fl
        var below: [Float] = []
        while x > lo + 1e-6 {
            step = min(step * 1.25, coarse)
            x = max(x - step, lo)
            below.append(x)
        }
        step = (fh - fl) / Float(n)
        x = fh
        var above: [Float] = []
        while x < hi - 1e-6 {
            step = min(step * 1.25, coarse)
            x = min(x + step, hi)
            above.append(x)
        }
        core = below.reversed() + core + above
        return core
    }

    func mesh() -> HumanSurface {
        let xs = Self.axis(piece.lo.x, piece.hi.x, piece.fineLo.x, piece.fineHi.x, piece.fine, piece.coarse)
        let ys = Self.axis(piece.lo.y, piece.hi.y, piece.fineLo.y, piece.fineHi.y, piece.fine, piece.coarse)
        let zs = Self.axis(piece.lo.z, piece.hi.z, piece.fineLo.z, piece.fineHi.z, piece.fine, piece.coarse)
        let nx = xs.count, ny = ys.count, nz = zs.count
        let B = Self.block
        let bx = (nx - 1 + B - 1) / B, by = (ny - 1 + B - 1) / B, bz = (nz - 1 + B - 1) / B
        let blockCount = bx * by * bz
        let all = field.prims.indices.filter { piece.groups.contains(field.prims[$0].group) }.map { Int32($0) }
        let maxK = field.prims.map(\.k).max() ?? 0
        let maxJoin = field.groups.map { max($0.kNear, $0.kFar) }.max() ?? 0
        var lists = [[Int32]](repeating: [], count: blockCount)
        var near = [Bool](repeating: false, count: blockCount)
        // Which blocks hold surface, and the prims near each.
        field.prims.withUnsafeBufferPointer { prims in
            field.groups.withUnsafeBufferPointer { groups in
                all.withUnsafeBufferPointer { allList in
                    lists.withUnsafeMutableBufferPointer { listOut in
                        near.withUnsafeMutableBufferPointer { nearOut in
                            concurrentPerform(iterations: bz) { kz in
                                for ky in 0..<by {
                                    for kx in 0..<bx {
                                        let i0 = kx * B, j0 = ky * B, k0 = kz * B
                                        let i1 = min(i0 + B, nx - 1), j1 = min(j0 + B, ny - 1), k1 = min(k0 + B, nz - 1)
                                        let lo = Vec3(xs[i0], ys[j0], zs[k0]), hi = Vec3(xs[i1], ys[j1], zs[k1])
                                        let c = (lo + hi) / 2
                                        let d = post(c.x, c.y, c.z, field.evaluate(c.x, c.y, c.z, allList, prims.baseAddress!, groups.baseAddress!))
                                        let reach = length(hi - lo) * 0.5 * 1.35 + 0.004
                                        let index = (kz * by + ky) * bx + kx
                                        guard abs(d) <= reach else { continue }
                                        nearOut[index] = true
                                        let band = 0.03 + maxK + maxJoin + length(hi - lo) * 0.25
                                        var list: [Int32] = []
                                        for p in allList {
                                            let prim = prims[Int(p)]
                                            let gap = pointwiseMax(prim.lo - hi, lo - prim.hi)
                                            let g = length(pointwiseMax(gap, .zero))
                                            if g <= band || prim.op == .intersect { list.append(p) }
                                        }
                                        listOut[index] = list
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Corner values of the near blocks ((B+1)^3 each).
        let nearBlocks = (0..<blockCount).filter { near[$0] }
        let side = B + 1
        var slot = [Int32](repeating: -1, count: blockCount)
        for (s, b) in nearBlocks.enumerated() { slot[b] = Int32(s) }
        var values = [Float](repeating: 1, count: nearBlocks.count * side * side * side)
        field.prims.withUnsafeBufferPointer { prims in
            field.groups.withUnsafeBufferPointer { groups in
                values.withUnsafeMutableBufferPointer { out in
                    concurrentPerform(iterations: nearBlocks.count) { s in
                        let b = nearBlocks[s]
                        let kx = b % bx, ky = (b / bx) % by, kz = b / (bx * by)
                        lists[b].withUnsafeBufferPointer { list in
                            for c in 0..<side {
                                let k = min(kz * B + c, nz - 1)
                                for bb in 0..<side {
                                    let j = min(ky * B + bb, ny - 1)
                                    for a in 0..<side {
                                        let i = min(kx * B + a, nx - 1)
                                        let x = xs[i], y = ys[j], z = zs[k]
                                        out[((s * side + c) * side + bb) * side + a] = post(x, y, z, field.evaluate(x, y, z, list, prims.baseAddress!, groups.baseAddress!))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // A vertex per cell the surface crosses, at the mean of its edge crossings.
        var vertexOfCell: [Int: Int32] = [:]
        var positions: [Vec3] = []
        var vertexBlock: [Int32] = []
        let cnx = nx - 1, cny = ny - 1
        func cellKey(_ i: Int, _ j: Int, _ k: Int) -> Int { (k * cny + j) * cnx + i }
        let corners: [(Int, Int, Int)] = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0), (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 1, 1)]
        let edges: [(Int, Int)] = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
        for (s, b) in nearBlocks.enumerated() {
            let kx = b % bx, ky = (b / bx) % by, kz = b / (bx * by)
            let base = s * side * side * side
            for c in 0..<B where kz * B + c < nz - 1 {
                for bb in 0..<B where ky * B + bb < ny - 1 {
                    for a in 0..<B where kx * B + a < nx - 1 {
                        var v = [Float](repeating: 0, count: 8)
                        var inside = 0
                        for (n, o) in corners.enumerated() {
                            v[n] = values[base + ((c + o.2) * side + bb + o.1) * side + a + o.0]
                            if v[n] < 0 { inside += 1 }
                        }
                        guard inside > 0 && inside < 8 else { continue }
                        let i = kx * B + a, j = ky * B + bb, k = kz * B + c
                        var sum = Vec3.zero
                        var count: Float = 0
                        for (e0, e1) in edges where (v[e0] < 0) != (v[e1] < 0) {
                            let t = v[e0] / (v[e0] - v[e1])
                            let p0 = Vec3(xs[i + corners[e0].0], ys[j + corners[e0].1], zs[k + corners[e0].2])
                            let p1 = Vec3(xs[i + corners[e1].0], ys[j + corners[e1].1], zs[k + corners[e1].2])
                            sum += p0 + (p1 - p0) * t
                            count += 1
                        }
                        vertexOfCell[cellKey(i, j, k)] = Int32(positions.count)
                        positions.append(sum / count)
                        vertexBlock.append(Int32(b))
                    }
                }
            }
        }
        // A quad per crossed grid edge, between the four cells around it.
        var quads: [SIMD4<Int32>] = []
        for (s, b) in nearBlocks.enumerated() {
            let kx = b % bx, ky = (b / bx) % by, kz = b / (bx * by)
            let base = s * side * side * side
            func value(_ a: Int, _ bb: Int, _ c: Int) -> Float { values[base + (c * side + bb) * side + a] }
            for c in 0..<B {
                for bb in 0..<B {
                    for a in 0..<B {
                        let i = kx * B + a, j = ky * B + bb, k = kz * B + c
                        guard i < nx, j < ny, k < nz else { continue }
                        let v0 = value(a, bb, c)
                        // Edges along x, y and z from this grid point.
                        for axis in 0..<3 {
                            let (da, db, dc) = axis == 0 ? (1, 0, 0) : axis == 1 ? (0, 1, 0) : (0, 0, 1)
                            guard i + da < nx, j + db < ny, k + dc < nz else { continue }
                            let v1 = value(a + da, bb + db, c + dc)
                            guard (v0 < 0) != (v1 < 0) else { continue }
                            // The four cells sharing the edge, counter-clockwise about +axis.
                            var cells: [(Int, Int, Int)]
                            switch axis {
                            case 0: cells = [(i, j - 1, k - 1), (i, j, k - 1), (i, j, k), (i, j - 1, k)]
                            case 1: cells = [(i - 1, j, k - 1), (i - 1, j, k), (i, j, k), (i, j, k - 1)]
                            default: cells = [(i - 1, j - 1, k), (i, j - 1, k), (i, j, k), (i - 1, j, k)]
                            }
                            var ids = SIMD4<Int32>(repeating: -1)
                            var ok = true
                            for (n, cell) in cells.enumerated() {
                                guard cell.0 >= 0, cell.1 >= 0, cell.2 >= 0, cell.0 < cnx, cell.1 < cny, cell.2 < nz - 1,
                                      let id = vertexOfCell[cellKey(cell.0, cell.1, cell.2)] else { ok = false; break }
                                ids[n] = id
                            }
                            guard ok else { continue }
                            // Inside at the start: the surface faces +axis, as wound.
                            quads.append(v0 < 0 ? ids : SIMD4(ids[3], ids[2], ids[1], ids[0]))
                        }
                    }
                }
            }
        }
        var surface = HumanSurface()
        guard !positions.isEmpty else { return surface }
        // Relax toward the neighbors' mean and project back onto the surface.
        var neighborSum = [Vec3](repeating: .zero, count: positions.count)
        var neighborCount = [Float](repeating: 0, count: positions.count)
        let fieldRef = field
        let postRef = post
        func eval(_ p: Vec3, _ list: UnsafeBufferPointer<Int32>, _ prims: UnsafePointer<HumanPrim>, _ groups: UnsafePointer<HumanGroup>) -> Float {
            postRef(p.x, p.y, p.z, fieldRef.evaluate(p.x, p.y, p.z, list, prims, groups))
        }
        func gradient(_ p: Vec3, _ list: UnsafeBufferPointer<Int32>, _ prims: UnsafePointer<HumanPrim>, _ groups: UnsafePointer<HumanGroup>) -> Vec3 {
            let h: Float = 0.0004
            return Vec3(eval(p + Vec3(h, 0, 0), list, prims, groups) - eval(p - Vec3(h, 0, 0), list, prims, groups),
                        eval(p + Vec3(0, h, 0), list, prims, groups) - eval(p - Vec3(0, h, 0), list, prims, groups),
                        eval(p + Vec3(0, 0, h), list, prims, groups) - eval(p - Vec3(0, 0, h), list, prims, groups)) / (2 * h)
        }
        for round in 0..<2 {
            if round > 0 {
                for i in neighborSum.indices { neighborSum[i] = .zero; neighborCount[i] = 0 }
                for q in quads {
                    for n in 0..<4 {
                        let a = Int(q[n]), b = Int(q[(n + 1) % 4])
                        neighborSum[a] += positions[b]; neighborCount[a] += 1
                        neighborSum[b] += positions[a]; neighborCount[b] += 1
                    }
                }
            }
            let relax = round > 0
            let sums = neighborSum, counts = neighborCount
            field.prims.withUnsafeBufferPointer { prims in
                field.groups.withUnsafeBufferPointer { groups in
                    positions.withUnsafeMutableBufferPointer { out in
                        let chunk = 512
                        concurrentPerform(iterations: (out.count + chunk - 1) / chunk) { c in
                            for v in c * chunk..<min(out.count, (c + 1) * chunk) {
                                var p = out[v]
                                if relax, counts[v] > 0 { p += (sums[v] / counts[v] - p) * 0.5 }
                                lists[Int(vertexBlock[v])].withUnsafeBufferPointer { list in
                                    for _ in 0..<2 {
                                        let d = eval(p, list, prims.baseAddress!, groups.baseAddress!)
                                        let g = gradient(p, list, prims.baseAddress!, groups.baseAddress!)
                                        let gg = dot(g, g)
                                        guard gg > 1e-6, abs(d) < 0.01 else { break }
                                        p -= g * (d / gg)
                                    }
                                }
                                out[v] = p
                            }
                        }
                    }
                }
            }
        }
        // Normals from the gradient, occlusion from the field along the normal.
        var normals = [Vec3](repeating: Vec3(0, 1, 0), count: positions.count)
        var occlusion = [Float](repeating: 1, count: positions.count)
        field.prims.withUnsafeBufferPointer { prims in
            field.groups.withUnsafeBufferPointer { groups in
                normals.withUnsafeMutableBufferPointer { normalOut in
                    occlusion.withUnsafeMutableBufferPointer { aoOut in
                        let chunk = 512
                        concurrentPerform(iterations: (positions.count + chunk - 1) / chunk) { c in
                            for v in c * chunk..<min(positions.count, (c + 1) * chunk) {
                                let p = positions[v]
                                lists[Int(vertexBlock[v])].withUnsafeBufferPointer { list in
                                    let g = gradient(p, list, prims.baseAddress!, groups.baseAddress!)
                                    let n = length(g) > 1e-6 ? normalize(g) : Vec3(0, 1, 0)
                                    normalOut[v] = n
                                    var occluded: Float = 0, weight: Float = 1, total: Float = 0
                                    for step in 1...5 {
                                        let h = 0.0045 * Float(step)
                                        let d = eval(p + n * h, list, prims.baseAddress!, groups.baseAddress!)
                                        occluded += max(0, h - d) / h * weight
                                        total += weight
                                        weight *= 0.7
                                    }
                                    aoOut[v] = max(0.3, min(1, 1 - 1.25 * occluded / total))
                                }
                            }
                        }
                    }
                }
            }
        }
        // Triangles: each quad split along its shorter diagonal.
        var triangles: [SIMD3<UInt32>] = []
        triangles.reserveCapacity(quads.count * 2)
        for q in quads {
            let a = UInt32(q[0]), b = UInt32(q[1]), c = UInt32(q[2]), d = UInt32(q[3])
            if length(positions[Int(a)] - positions[Int(c)]) <= length(positions[Int(b)] - positions[Int(d)]) {
                triangles.append(SIMD3(a, b, c)); triangles.append(SIMD3(a, c, d))
            } else {
                triangles.append(SIMD3(a, b, d)); triangles.append(SIMD3(b, c, d))
            }
        }
        // Tags and skin weights from the prims nearest each vertex.
        var tags = [UInt8](repeating: piece.tag, count: positions.count)
        let boneCount = field.boneCount
        var weights = [[Float]](repeating: [], count: positions.count)
        field.prims.withUnsafeBufferPointer { prims in
            tags.withUnsafeMutableBufferPointer { tagOut in
                weights.withUnsafeMutableBufferPointer { weightOut in
                    let chunk = 512
                    concurrentPerform(iterations: (positions.count + chunk - 1) / chunk) { c in
                        var nearest = [(Float, Int32)]()
                        for v in c * chunk..<min(positions.count, (c + 1) * chunk) {
                            let p = positions[v]
                            nearest.removeAll(keepingCapacity: true)
                            var best: Float = .infinity
                            var bestTag: UInt8 = 255
                            for index in lists[Int(vertexBlock[v])] {
                                let prim = prims[Int(index)]
                                guard prim.op == .add else { continue }
                                let d = prim.distance(p.x, p.y, p.z)
                                if d < best { best = d; bestTag = prim.tag }
                                if prim.chain >= 0 { nearest.append((d, prim.chain)) }
                            }
                            if bestTag != 255 { tagOut[v] = bestTag }
                            var w = [Float](repeating: 0, count: boneCount)
                            let dmin = nearest.map(\.0).min() ?? 0
                            let sigma: Float = 0.006
                            var total: Float = 0
                            for (d, chain) in nearest where d - dmin < 5 * sigma {
                                let s = expf(-(d - dmin) / sigma)
                                fieldRef.chains[Int(chain)].weights(p, into: &w, scale: s)
                                total += s
                            }
                            if total > 0 { for b in w.indices { w[b] /= total } } else if boneCount > 0 { w[0] = 1 }
                            weightOut[v] = w
                        }
                    }
                }
            }
        }
        surface.positions = positions
        surface.normals = normals
        surface.occlusion = occlusion
        surface.tags = tags
        surface.weights = weights
        surface.triangles = triangles
        return surface
    }
}
