/// The fur meshes a groom grows on a mesh (see Groom.swift), built on the CPU from the mesh and
/// the groom alone, so the same code serves the renderer, the importers' checks and the tools.
///
/// Every vertex first gets a length factor and a comb vector (`vertexFields`):
/// - length: 1, times the mask image's red channel at its UV, the vertex paint channel, then each
///   `cut` stroke in order (the factor moves toward the stroke's `length` by its strength, fading
///   out toward the rim); 0...2;
/// - comb: `combDirection` (or the flow image, a direction in UV space mapped through the vertex
///   tangent frame) projected onto the surface, times `combStrength`, then each `comb` stroke.
///
/// Shell mesh (`shells`): the mesh's furry triangles (any vertex longer than 1%), each vertex's
/// tangent holding the comb vector (xyz) and 1 + the length factor (w; 1 + so the tangent never
/// reads as missing). The skin is kept. Card mesh (`cards`): guide curves grown from random points
/// on the surface (area-weighted, `seed`), bent by the comb, gravity, curl and frizz and pulled
/// into clumps, each drawn as a strip `cardWidth` wide: UV x across, y from root (0) to tip (1),
/// tangent along the strand (w: 2 + a random number per card), the skin of the nearest corner of
/// the root's triangle.
import Foundation
import EngineCore

public enum GroomGeometry {
    /// Cards a groom grows on one mesh at most.
    public static let maxCards = 12_000
    /// Triangles (shells x furry triangles, or card triangles) above which `report` calls the fur too dense.
    public static let triangleBudget = 1_500_000

    /// Per-vertex length factors and comb vectors of `base` (see the notes at the top).
    public static func vertexFields(_ base: MeshGeometry, fur: MaterialFur) -> (lengths: [Float], combs: [Vec3]) {
        let g = fur.groom
        let count = base.vertices.count
        var lengths = [Float](repeating: 1, count: count)
        var combs = [Vec3](repeating: .zero, count: count)
        let channel = ["r": 0, "g": 1, "b": 2, "a": 3][g.mask.vertexPaint.lowercased()]
        let strength = clamp01(g.combStrength)
        for i in 0..<count {
            let v = base.vertices[i]
            let n = safeNormalize(v.normal, fallback: Vec3(0, 1, 0))
            var l: Float = 1
            if let mask = fur.maskImage {
                let r = mask.sample(v.uv).x
                l *= g.mask.invert ? 1 - r : r
            }
            if let channel, let paint = base.paint, i < paint.count {
                let p = paint[i].color[channel]
                l *= g.mask.invert ? 1 - p : p
            }
            for stroke in g.cut where stroke.radius > 0 {
                let w = clamp01(stroke.strength) * falloff(length(v.position - stroke.center) / stroke.radius)
                if w > 0 { l += (min(max(stroke.length, 0), 2) - l) * w }
            }
            lengths[i] = min(max(l, 0), 2)

            var c: Vec3 = .zero
            switch g.combDirection {
            case .normal: break
            case .followSurface:
                // Down the surface; near the top (where down has no direction along it), backward (-Z).
                let down = Vec3(0, -1, 0) - n * dot(Vec3(0, -1, 0), n)
                c = tangential(down + tangential(Vec3(0, 0, -1), n) * 0.25, n) * strength
            case .vector(let d): c = tangential(d, n) * strength
            }
            if let flow = fur.flowImage {
                let f = flow.sample(v.uv)
                let fx = f.x * 2 - 1, fy = f.y * 2 - 1
                if fx * fx + fy * fy > 0.0025 {
                    let t = Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
                    let b = cross(n, t) * (v.tangent.w < 0 ? -1 : 1)
                    c = tangential(t * fx + b * fy, n) * strength
                }
            }
            for stroke in g.comb where stroke.radius > 0 {
                let w = clamp01(stroke.strength) * falloff(length(v.position - stroke.center) / stroke.radius)
                if w > 0 { c += (tangential(stroke.direction, n) - c) * w }
            }
            combs[i] = c
        }
        return (lengths, combs)
    }

    /// The shell mesh of `base` (nil when no fur grows on it).
    public static func shells(_ base: MeshGeometry, fur: MaterialFur) -> MeshGeometry? {
        let (lengths, combs) = vertexFields(base, fur: fur)
        var remap = [Int32](repeating: -1, count: base.vertices.count)
        var vertices: [MeshVertex] = []
        var skin: [SkinInfluence]? = base.skin == nil ? nil : []
        var indices: [UInt32] = []
        indices.reserveCapacity(base.indices.count)
        var t = 0
        while t + 2 < base.indices.count {
            let tri = (Int(base.indices[t]), Int(base.indices[t + 1]), Int(base.indices[t + 2]))
            t += 3
            guard lengths[tri.0] > 0.01 || lengths[tri.1] > 0.01 || lengths[tri.2] > 0.01 else { continue }
            for k in [tri.0, tri.1, tri.2] {
                if remap[k] < 0 {
                    remap[k] = Int32(vertices.count)
                    var v = base.vertices[k]
                    v.normal = safeNormalize(v.normal, fallback: Vec3(0, 1, 0))
                    v.tangent = Vec4(combs[k], 1 + lengths[k])
                    vertices.append(v)
                    if let s = base.skin, k < s.count { skin?.append(s[k]) }
                }
                indices.append(UInt32(remap[k]))
            }
        }
        guard !indices.isEmpty else { return nil }
        if let s = skin, s.count != vertices.count { skin = nil }
        return MeshGeometry(vertices: vertices, indices: indices, skin: skin)
    }

    /// One guide curve: points from the root (in the mesh's space), the root normal and its skin.
    public struct Guide: Sendable {
        public var points: [Vec3]
        public var normal: Vec3
        public var skin: SkinInfluence?
    }

    /// Guide curves grown from `base` (see the notes at the top), in a random order (so any prefix
    /// is an even subset), and how many the density asked for before the cap.
    public static func guides(_ base: MeshGeometry, fur: MaterialFur) -> (guides: [Guide], requested: Int) {
        let g = fur.groom
        let (lengths, combs) = vertexFields(base, fur: fur)
        // Furry triangles by area (m²), weighted by their average length factor.
        var areas: [Float] = []
        var tris: [(Int, Int, Int)] = []
        var t = 0
        while t + 2 < base.indices.count {
            let a = Int(base.indices[t]), b = Int(base.indices[t + 1]), c = Int(base.indices[t + 2])
            t += 3
            let l = (min(lengths[a], 1) + min(lengths[b], 1) + min(lengths[c], 1)) / 3
            guard l > 0.01 else { continue }
            let pa = base.vertices[a].position, pb = base.vertices[b].position, pc = base.vertices[c].position
            let area = length(cross(pb - pa, pc - pa)) * 0.5
            guard area.isFinite, area > 0 else { continue }
            tris.append((a, b, c))
            areas.append(area * l)
        }
        guard !tris.isEmpty else { return ([], 0) }
        var cumulative = [Float](repeating: 0, count: areas.count)
        var total: Float = 0
        for (i, a) in areas.enumerated() { total += a; cumulative[i] = total }
        let density = g.density.isFinite ? min(max(g.density, 0.001), 400) : 1
        let requested = Int((Double(total) * 10_000 * Double(density)).rounded())
        let count = min(max(requested, 1), maxCards)

        var rng = SplitMix(seed: UInt64(bitPattern: Int64(g.seed)) &+ 0x9E37_79B9_7F4A_7C15)
        let segments = min(max(g.cardSegments, 2), 16)
        let baseLength = g.clampedLength
        let bendable = 1 - clamp01(g.stiffness) * 0.8
        let gravity = clamp01(g.gravity) * bendable * 1.6
        let curl = clamp01(g.curl), frizz = clamp01(g.frizz)
        var guides: [Guide] = []
        guides.reserveCapacity(count)
        for _ in 0..<count {
            let pick = rng.float() * total
            var lo = 0, hi = cumulative.count - 1
            while lo < hi {
                let mid = (lo + hi) / 2
                if cumulative[mid] < pick { lo = mid + 1 } else { hi = mid }
            }
            let (a, b, c) = tris[lo]
            var u = rng.float(), v = rng.float()
            if u + v > 1 { u = 1 - u; v = 1 - v }
            let w = 1 - u - v
            let va = base.vertices[a], vb = base.vertices[b], vc = base.vertices[c]
            let root = va.position * w + vb.position * u + vc.position * v
            let n = safeNormalize(va.normal * w + vb.normal * u + vc.normal * v, fallback: Vec3(0, 1, 0))
            let lengthFactor = lengths[a] * w + lengths[b] * u + lengths[c] * v
            let comb = combs[a] * w + combs[b] * u + combs[c] * v
            let strandLength = baseLength * lengthFactor * (1 - clamp01(g.lengthVariation) * rng.float())
            let corner = w >= u && w >= v ? a : (u >= v ? b : c)
            let skin = base.skin.flatMap { corner < $0.count ? $0[corner] : nil }
            guard strandLength > baseLength * 0.03 else {
                _ = (rng.float(), rng.float())  // keep the stream aligned
                continue
            }
            // A frame around the normal for curl.
            let e1 = safeNormalize(abs(n.y) < 0.9 ? cross(n, Vec3(0, 1, 0)) : cross(n, Vec3(1, 0, 0)), fallback: Vec3(1, 0, 0))
            let e2 = cross(n, e1)
            let phase = rng.float() * 2 * .pi
            let lean = min(length(comb), 1)
            let combDir = lean > 1e-4 ? comb / lean : .zero
            var points = [root]
            var p = root
            let step = strandLength / Float(segments)
            for k in 1...segments {
                let s = Float(k) / Float(segments)
                let bend = min(s * 3, 1)
                var dir = n * (1 - lean * bend) + combDir * (lean * bend * 1.2) + Vec3(0, -1, 0) * (gravity * s)
                dir = safeNormalize(dir, fallback: n)
                p += dir * step
                // Stay above the surface's tangent plane (gravity would pull roots inside).
                let lift = dot(p - root, n), minimum = step * 0.15 * Float(min(k, 2))
                if lift < minimum { p += n * (minimum - lift) }
                var q = p
                if curl > 0 {
                    let angle = s * 4 * .pi + phase
                    q += (e1 * cosf(angle) + e2 * sinf(angle)) * (curl * strandLength * 0.08 * s)
                }
                if frizz > 0 {
                    q += Vec3(rng.float() - 0.5, rng.float() - 0.5, rng.float() - 0.5) * (frizz * step * 0.6 * s)
                }
                points.append(q)
            }
            guides.append(Guide(points: points, normal: n, skin: skin))
        }
        // Clumps: each guide leans toward the nearest of the first eighth (its leader).
        let clumping = clamp01(g.clumping)
        if clumping > 0, guides.count > 8 {
            let leaders = max(1, guides.count / 8)
            let original = guides
            for i in leaders..<guides.count {
                let root = original[i].points[0]
                var best = 0
                var bestDistance = Float.greatestFiniteMagnitude
                for j in 0..<leaders {
                    let d = original[j].points[0] - root
                    let d2 = dot(d, d)
                    if d2 < bestDistance { bestDistance = d2; best = j }
                }
                let leader = original[best].points
                for k in 1..<guides[i].points.count where k < leader.count {
                    let s = Float(k) / Float(guides[i].points.count - 1)
                    guides[i].points[k] += (leader[k] - guides[i].points[k]) * (clumping * 0.85 * s * s)
                }
            }
        }
        return (guides, requested)
    }

    /// The card mesh of `base`: the first `fraction` of the guides as strips (nil when no fur grows).
    public static func cards(_ base: MeshGeometry, fur: MaterialFur, fraction: Float = 1) -> MeshGeometry? {
        cards(guides: guides(base, fur: fur).guides, fur: fur, fraction: fraction, skinned: base.skin != nil)
    }

    /// Strips along `guides` (see `cards(_:fur:fraction:)`).
    public static func cards(guides all: [Guide], fur: MaterialFur, fraction: Float = 1, skinned: Bool) -> MeshGeometry? {
        let f = fraction.isFinite ? min(max(fraction, 0.01), 1) : 1
        let guides = all.prefix(max(1, Int((Float(all.count) * f).rounded())))
        guard !all.isEmpty, !guides.isEmpty else { return nil }
        let width = (fur.groom.cardWidth.isFinite ? min(max(fur.groom.cardWidth, 0.0005), 0.5) : 0.012) * min(2, 1 / f.squareRoot())
        var vertices: [MeshVertex] = []
        var indices: [UInt32] = []
        var skin: [SkinInfluence]? = skinned ? [] : nil
        for (index, guide) in guides.enumerated() {
            let points = guide.points
            // A random number per card (tangent.w's fraction) varies its strands in the shader.
            let random = (Float(index) * 0.618_034).truncatingRemainder(dividingBy: 1) * 0.999
            let count = points.count
            guard count >= 2 else { continue }
            let first = UInt32(vertices.count)
            for k in 0..<count {
                let s = Float(k) / Float(count - 1)
                let t = safeNormalize(points[min(k + 1, count - 1)] - points[max(k - 1, 0)], fallback: guide.normal)
                var side = cross(t, guide.normal)
                if dot(side, side) < 1e-10 { side = cross(t, abs(t.y) < 0.9 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)) }
                side = safeNormalize(side, fallback: Vec3(1, 0, 0))
                var normal = safeNormalize(cross(side, t), fallback: guide.normal)
                if dot(normal, guide.normal) < 0 { normal = -normal }
                let half = width * (1 - 0.45 * s) * 0.5
                for (x, sign) in [(Float(0), Float(-1)), (Float(1), Float(1))] {
                    vertices.append(MeshVertex(position: points[k] + side * (half * sign), normal: normal, uv: Vec2(x, s), tangent: Vec4(t, 2 + random)))
                    if let influence = guide.skin { skin?.append(influence) } else { skin?.append(SkinInfluence(joint: 0)) }
                }
                if k > 0 {
                    let a = first + UInt32((k - 1) * 2), b = a + 1, c = a + 2, d = a + 3
                    indices += [a, c, b, b, c, d]
                }
            }
        }
        guard !indices.isEmpty else { return nil }
        return MeshGeometry(vertices: vertices, indices: indices, skin: skin)
    }

    /// What growing `fur` on `base` costs and what's wrong with it (`groom.apply`'s warnings).
    public struct Report: Equatable, Sendable {
        public var triangles: Int
        /// The fraction of the surface where fur grows (0...1, by area).
        public var coverage: Float
        /// Fur triangles at full detail (shells x furry triangles, or card triangles).
        public var furTriangles: Int
        /// Cards at full detail (cards style).
        public var cards: Int
        public var hasUVs: Bool
        public var warnings: [String]
    }

    public static func report(_ base: MeshGeometry, fur: MaterialFur, usesTextures: Bool? = nil) -> Report {
        let g = fur.groom
        let triangles = base.indices.count / 3
        var warnings: [String] = []
        let uvs = base.vertices.map(\.uv)
        let hasUVs = uvs.contains { abs($0.x - (uvs.first?.x ?? 0)) > 1e-5 || abs($0.y - (uvs.first?.y ?? 0)) > 1e-5 }
        let textured = usesTextures ?? (fur.maskImage != nil || fur.flowImage != nil || !g.mask.texture.isEmpty || !g.flowTexture.isEmpty)
        if !hasUVs {
            warnings.append(textured
                ? "the mesh has no texture coordinates (UVs), so the groom's mask or flow texture can't map onto it; add UVs or use mask.parts, vertex paint or cut strokes"
                : "the mesh has no texture coordinates (UVs); fur still grows (strands are placed in 3D), but mask and flow textures won't map")
        }
        let (lengths, _) = vertexFields(base, fur: fur)
        var furryArea: Float = 0, totalArea: Float = 0, furryTriangles = 0
        var t = 0
        while t + 2 < base.indices.count {
            let a = Int(base.indices[t]), b = Int(base.indices[t + 1]), c = Int(base.indices[t + 2])
            t += 3
            let pa = base.vertices[a].position, pb = base.vertices[b].position, pc = base.vertices[c].position
            let area = length(cross(pb - pa, pc - pa)) * 0.5
            guard area.isFinite else { continue }
            totalArea += area
            let l = (min(lengths[a], 1) + min(lengths[b], 1) + min(lengths[c], 1)) / 3
            furryArea += area * min(l, 1)
            if lengths[a] > 0.01 || lengths[b] > 0.01 || lengths[c] > 0.01 { furryTriangles += 1 }
        }
        let coverage = totalArea > 0 ? min(furryArea / totalArea, 1) : 0
        if triangles == 0 {
            warnings.append("the mesh has no triangles")
        } else if furryTriangles == 0 || coverage < 1e-4 {
            warnings.append("the mask covers nothing: no fur grows on this mesh (check mask.texture, mask.vertexPaint, mask.invert and the cut strokes)")
        }
        var cards = 0, furTriangles = 0
        if g.drawnStyle == .shell {
            furTriangles = furryTriangles * (g.shellLevels.first ?? 1)
            if triangles > 0, triangles < 48 {
                warnings.append("only \(triangles) triangles: shells follow its flat faces and split at hard edges; use a smoother mesh (more segments)")
            }
        } else {
            let density = g.density.isFinite ? min(max(g.density, 0.001), 400) : 1
            let requested = Int(Double(furryArea) * 10_000 * Double(density))
            cards = min(requested, maxCards)
            furTriangles = cards * min(max(g.cardSegments, 2), 16) * 2
            if requested > maxCards {
                warnings.append("fur too dense for this mesh: \(requested) cards asked for (density \(g.density) per cm² over \(String(format: "%.0f", furryArea * 10_000)) cm²); capped at \(maxCards). Lower density or widen cardWidth")
            }
        }
        if furTriangles > triangleBudget {
            warnings.append("fur too dense for the triangle count: about \(furTriangles) fur triangles from \(triangles) mesh triangles (budget \(triangleBudget)); use fewer shells, a lower density or a lighter mesh")
        }
        return Report(triangles: triangles, coverage: coverage, furTriangles: furTriangles, cards: cards, hasUVs: hasUVs, warnings: warnings)
    }

    // MARK: Helpers

    static func clamp01(_ x: Float) -> Float { x.isFinite ? min(max(x, 0), 1) : 0 }

    /// 1 inside half the radius, easing to 0 at the rim.
    static func falloff(_ r: Float) -> Float {
        guard r.isFinite, r < 1 else { return 0 }
        if r <= 0.5 { return 1 }
        let x = (r - 0.5) / 0.5
        return 1 - x * x * (3 - 2 * x)
    }

    static func safeNormalize(_ v: Vec3, fallback: Vec3) -> Vec3 {
        let l = length(v)
        return l > 1e-8 && l.isFinite ? v / l : fallback
    }

    /// `d` projected onto the plane of unit normal `n`, normalized (zero if it is along `n`).
    static func tangential(_ d: Vec3, _ n: Vec3) -> Vec3 {
        let p = d - n * dot(d, n)
        let l = length(p)
        return l > 1e-5 && l.isFinite ? p / l : .zero
    }

    /// A small deterministic random stream.
    struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        /// 0..<1.
        mutating func float() -> Float { Float(next() >> 40) / Float(1 << 24) }
    }
}
