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
/// reads as missing). The skin is kept. Card mesh (`cards`): guide curves (`guides`) grown from
/// evenly spaced (or random) roots on the surface (`seed`): along the scalp for `scalpHug` of their
/// length following the comb field (the part, sweep back, fringe and strokes of GroomStyling.swift,
/// or toward a ponytail `tie`), then falling under gravity, kept out of the mesh and `colliders`,
/// trimmed at the `hemline`, curled, waved and pulled into tapered clumps (grooms without the
/// styling keys grow out along the normal, leaning to the comb, as before). Each guide is drawn
/// as a strip `cardWidth` wide (times its layer's width, tapering): UV x across, y from root (0) to tip (1),
/// tangent along the strand (w: 2 + a random number per card), the skin of the nearest corner of
/// the root's triangle.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

public enum GroomGeometry {
    /// Cards a groom grows on one mesh at most.
    public static let maxCards = 12_000
    /// Triangles (shells x furry triangles, or card triangles) above which `report` calls the fur too dense.
    public static let triangleBudget = 1_500_000

    /// Per-vertex length factors and comb vectors of `base` (see the notes at the top).
    public static func vertexFields(_ base: MeshGeometry, fur: MaterialFur) -> (lengths: [Float], combs: [Vec3]) {
        let f = fields(base, fur: fur)
        return (f.lengths, f.combs)
    }

    /// The vertex fields and what styling needs: the base combs (before the part, the fringe and
    /// the strokes) and the shaper that evaluates those anywhere.
    struct Fields {
        var lengths: [Float]
        var combs: [Vec3]
        var baseCombs: [Vec3]
        var shaper: GroomShaper
    }

    static func fields(_ base: MeshGeometry, fur: MaterialFur) -> Fields {
        let g = fur.groom
        let count = base.vertices.count
        var maskLengths = [Float](repeating: 1, count: count)
        var baseCombs = [Vec3](repeating: .zero, count: count)
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
            maskLengths[i] = min(max(l, 0), 2)

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
            baseCombs[i] = c
        }
        let shaper = GroomShaper(groom: g, frame: GroomFrame(base, lengths: maskLengths))
        var lengths = maskLengths
        var combs = baseCombs
        for i in 0..<count {
            let v = base.vertices[i]
            lengths[i] = shaper.lengthFactor(at: v.position, base: maskLengths[i])
            combs[i] = shaper.comb(at: v.position, normal: safeNormalize(v.normal, fallback: Vec3(0, 1, 0)), base: baseCombs[i])
        }
        return Fields(lengths: lengths, combs: combs, baseCombs: baseCombs, shaper: shaper)
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

    /// Which layer a guide belongs to.
    public enum Layer: UInt8, Sendable, Equatable {
        /// The styled hair.
        case outer
        /// Short cards lying flat on the scalp under the styled hair (`innerLayer`).
        case inner
        /// Strays (`flyaways`).
        case flyaway
    }

    /// One guide curve: what a card follows, and what per-strand dynamics would move. `points[0]`
    /// is the root on the surface (the mesh's space), the rest evenly spaced along the strand at
    /// rest (`cardSegments` + 1 points). Card `i` of `cards(guides:…)` is guide `i`; `cardSpans`
    /// says which vertices it owns.
    public struct Guide: Sendable {
        public var points: [Vec3]
        /// The surface normal at the root.
        public var normal: Vec3
        public var skin: SkinInfluence?
        /// Per point, the way the card faces (away from the scalp); empty: `normal` everywhere.
        public var normals: [Vec3]
        public var layer: Layer
        /// The index of the guide this one clumps toward (its own index for a clump's leader; -1 none).
        public var clump: Int
        /// The card's width as a multiple of `cardWidth`.
        public var width: Float
        /// The rest length along the curve, in meters.
        public var length: Float

        public init(points: [Vec3], normal: Vec3, skin: SkinInfluence? = nil, normals: [Vec3] = [], layer: Layer = .outer,
                    clump: Int = -1, width: Float = 1, length: Float = 0) {
            self.points = points
            self.normal = normal
            self.skin = skin
            self.normals = normals
            self.layer = layer
            self.clump = clump
            self.width = width
            self.length = length
        }

        public var root: Vec3 { points[0] }
    }

    /// Where a guide's card is in a card mesh: `vertexCount` vertices from `firstVertex`, two per
    /// guide point (left then right edge), root first; its triangles are `(vertexCount / 2 - 1) * 2`
    /// from index `firstIndex`.
    public struct CardSpan: Equatable, Sendable {
        public var guide: Int
        public var firstVertex: Int
        public var vertexCount: Int
        public var firstIndex: Int
    }

    /// The guides a detail level draws (the first `fraction` of them).
    public static func cardCount(guides: Int, fraction: Float) -> Int {
        let f = fraction.isFinite ? min(max(fraction, 0.01), 1) : 1
        return guides == 0 ? 0 : max(1, Int((Float(guides) * f).rounded()))
    }

    /// Which vertices of `cards(guides:fur:fraction:skinned:)` each guide drives.
    public static func cardSpans(guides: [Guide], fraction: Float = 1) -> [CardSpan] {
        var spans: [CardSpan] = []
        var vertex = 0, index = 0
        for (i, guide) in guides.prefix(cardCount(guides: guides.count, fraction: fraction)).enumerated() where guide.points.count >= 2 {
            spans.append(CardSpan(guide: i, firstVertex: vertex, vertexCount: guide.points.count * 2, firstIndex: index))
            vertex += guide.points.count * 2
            index += (guide.points.count - 1) * 6
        }
        return spans
    }

    /// A root picked on the surface.
    private struct Root {
        var position: Vec3
        var normal: Vec3
        var corners: (Int, Int, Int)
        var weights: Vec3
        /// 0 at the hair's edge, 1 a hairline width inside it.
        var edge: Float
    }

    /// Guide curves grown from `base` (see the notes at the top), in a random order (so any prefix
    /// is an even subset), and how many the density asked for before the cap.
    public static func guides(_ base: MeshGeometry, fur: MaterialFur) -> (guides: [Guide], requested: Int) {
        let g = fur.groom
        let fields = fields(base, fur: fur)
        let lengths = fields.lengths, combs = fields.combs, shaper = fields.shaper
        // Furry triangles by area (m²), weighted by their average length factor.
        var areas: [Float] = []
        var tris: [(Int, Int, Int)] = []
        var plainArea: Float = 0
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
            plainArea += area
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
        let hairline = g.hairlineWidth.isFinite ? max(g.hairlineWidth, 0) : 0
        let edges = hairline > 0 ? edgeDistances(base, lengths: lengths) : nil

        // Roots: evenly spaced (dart throwing on a grid) or random.
        func sampleRoot() -> Root? {
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
            let position = va.position * w + vb.position * u + vc.position * v
            let normal = safeNormalize(va.normal * w + vb.normal * u + vc.normal * v, fallback: Vec3(0, 1, 0))
            var edge: Float = 1
            if let edges {
                let d = edges[a] * w + edges[b] * u + edges[c] * v
                edge = GroomShaper.smoothstep(0, hairline, d)
                // Fewer cards toward the edge.
                if rng.float() > 0.2 + 0.8 * edge { return nil }
            }
            if shaper.onPartLine(position) { return nil }
            return Root(position: position, normal: normal, corners: (a, b, c), weights: Vec3(w, u, v), edge: edge)
        }
        var roots: [Root] = []
        roots.reserveCapacity(count)
        if g.rootPlacement == .even {
            var radius = 0.7 * (plainArea / Float(count)).squareRoot()
            let cell = max(radius, 1e-5)
            var grid: [SIMD3<Int32>: [Int32]] = [:]
            func key(_ p: Vec3) -> SIMD3<Int32> {
                SIMD3(Int32((p.x / cell).rounded(.down)), Int32((p.y / cell).rounded(.down)), Int32((p.z / cell).rounded(.down)))
            }
            var attempts = 0
            let budget = count * 6
            while roots.count < count, attempts < budget * 3 {
                attempts += 1
                if attempts % budget == 0 { radius *= 0.75 }
                guard let root = sampleRoot() else { continue }
                let k = key(root.position)
                // Sparser toward the hairline (the spacing grows as the density falls).
                let spacing = radius / (0.2 + 0.8 * root.edge).squareRoot()
                let reach = Int32(min((spacing / cell).rounded(.up), 4))
                var free = true
                search: for x in -reach...reach {
                    for y in -reach...reach {
                        for z in -reach...reach {
                            for j in grid[k &+ SIMD3(x, y, z)] ?? [] where dot2(roots[Int(j)].position - root.position) < spacing * spacing {
                                free = false
                                break search
                            }
                        }
                    }
                }
                guard free else { continue }
                grid[k, default: []].append(Int32(roots.count))
                roots.append(root)
            }
        }
        var tries = 0
        while roots.count < count, tries < count * 4 {
            tries += 1
            if let root = sampleRoot() { roots.append(root) }
        }

        // Growing.
        let bendable = 1 - clamp01(g.stiffness) * 0.8
        let gravity = clamp01(g.gravity) * bendable * 1.6
        let bendRadius: Float = 0.02 + clamp01(g.stiffness) * 0.08
        let curl = clamp01(g.curl), frizz = clamp01(g.frizz), wave = clamp01(g.wave)
        let turns = g.curlFrequency.isFinite ? min(max(g.curlFrequency, 0.1), 16) : 2
        let lengthVariation = clamp01(g.lengthVariation)
        let cardWidth = g.cardWidth.isFinite ? min(max(g.cardWidth, 0.0005), 0.5) : 0.012
        let minLift: Float = 0.001 + cardWidth * 0.1
        let volumeLift = clamp01(g.volume) * min(baseLength * 0.1, 0.025)
        let hugFraction = clamp01(g.scalpHug)
        let innerLayer = clamp01(g.innerLayer), flyaways = clamp01(g.flyaways)
        let tie = g.tie.enabled ? shaper.frame.world(g.tie.point) : nil
        let tieTail = g.tie.tail.isFinite ? min(max(g.tie.tail, 0), 3) : 0.25
        let tieRadius = g.tie.radius.isFinite ? min(max(g.tie.radius, 0), 0.5) : 0.015
        // About 30 growth steps per strand.
        let substeps = max(2, (30 + segments - 1) / segments)
        let styled = hugFraction > 0 || tie != nil || innerLayer > 0 || flyaways > 0
        let surface: GroomSurface? = g.collide || styled
            ? GroomSurface(base, cell: max(baseLength / Float(segments * substeps) * 2.5, (minLift + volumeLift) * 3)) : nil
        let colliders = g.collide ? g.colliders : []
        let down = Vec3(0, -1, 0)
        let tailDirection = normalize(Vec3(0, -1, -0.3))

        func interpolate<T: SIMD>(_ values: [T], _ corners: (Int, Int, Int), _ w: Vec3) -> T where T.Scalar == Float {
            values[corners.0] * w.x + values[corners.1] * w.y + values[corners.2] * w.z
        }
        func interpolate(_ values: [Float], _ corners: (Int, Int, Int), _ w: Vec3) -> Float {
            values[corners.0] * w.x + values[corners.1] * w.y + values[corners.2] * w.z
        }
        func corners(_ hit: GroomSurface.Hit) -> (Int, Int, Int) {
            let tri = surface!.triangles[hit.triangle]
            return (Int(tri.x), Int(tri.y), Int(tri.z))
        }
        /// Pushes `p` out of the colliders and the mesh; the outward direction when it moved.
        func collide(_ p: inout Vec3, offset: Float, step: Float) -> Vec3? {
            var pushed: Vec3?
            for collider in colliders { if let n = collider.pushOut(&p, offset: offset) { pushed = n } }
            if g.collide, let surface, let n = surface.pushOut(&p, offset: offset, within: max(step * 2, offset * 3)) { pushed = n }
            return pushed
        }

        var guides: [Guide] = []
        guides.reserveCapacity(roots.count)
        // Each guide's points as grown (before curls and clumps), for the last collision pass.
        var centerlines: [[Vec3]] = []
        for root in roots {
            let n = root.normal
            let corner = root.weights.x >= root.weights.y && root.weights.x >= root.weights.z ? root.corners.0
                : (root.weights.y >= root.weights.z ? root.corners.1 : root.corners.2)
            let skin = base.skin.flatMap { corner < $0.count ? $0[corner] : nil }
            var layer = Layer.outer
            if rng.float() < innerLayer { layer = .inner } else if rng.float() < flyaways { layer = .flyaway }
            let lengthFactor = interpolate(lengths, root.corners, root.weights)
            var strandLength = baseLength * lengthFactor * (1 - lengthVariation * rng.float()) * (0.45 + 0.55 * root.edge)
            switch layer {
            case .inner: strandLength *= 0.5
            case .flyaway: strandLength *= 0.7 + 0.5 * rng.float()
            case .outer: break
            }
            let phase = rng.float() * 2 * .pi
            let jitter = rng.float()
            guard tie != nil || strandLength > baseLength * 0.03 else { continue }
            let hug: Float = switch layer {
            case .outer: hugFraction
            case .inner: max(hugFraction, 0.9)
            case .flyaway: hugFraction * 0.5
            }
            let lift: Float = switch layer {
            case .outer: volumeLift
            case .inner: 0
            case .flyaway: volumeLift * 1.5 + baseLength * 0.01
            }
            let legacy = hug == 0 && tie == nil

            // The centerline, grown in small steps.
            let rootComb = interpolate(combs, root.corners, root.weights)
            let lean = min(length(rootComb), 1)
            let combDir = lean > 1e-4 ? rootComb / lean : .zero
            var heading = tangential(rootComb, n)
            if dot2(heading) < 1e-8 { heading = tangential(down, n) }
            if dot2(heading) < 1e-8 { heading = tangential(Vec3(0, 0, -1), n) }
            if layer == .flyaway { heading = safeNormalize(heading + n * 0.3, fallback: n) }
            var totalLength = strandLength
            if let tie { totalLength = length(tie - root.position) * 2.5 + tieTail }
            let step = (tie.map { length($0 - root.position) * 1.4 + tieTail } ?? strandLength) / Float(segments * substeps)
            let hugLength = tie != nil ? Float.greatestFiniteMagnitude : strandLength * hug
            var dense = [root.position]
            var normals = [n]
            var p = root.position
            var surfaceNormal = n
            var lastHit: GroomSurface.Hit?
            var travelled: Float = 0
            var hugging = !legacy && surface != nil
            var tail = false
            var iterations = 0
            func liftAt(_ s: Float) -> Float { minLift + lift * GroomShaper.smoothstep(0, max(min(hugLength, strandLength) * 0.5, 1e-4), s) }
            while travelled < totalLength - 1e-6, iterations < 600 {
                iterations += 1
                let ds = min(step, totalLength - travelled)
                var next: Vec3
                var facing = normals[normals.count - 1]
                if hugging, let surface {
                    var want: Vec3
                    if let tie, !tail {
                        want = tangential(tie - p, surfaceNormal)
                    } else if let hit = lastHit {
                        let c = corners(hit)
                        want = tangential(shaper.comb(at: hit.point, normal: hit.normal, base: interpolate(fields.baseCombs, c, hit.weights)), hit.normal)
                    } else {
                        want = tangential(rootComb, n)
                    }
                    let current = tangential(heading, surfaceNormal)
                    heading = safeNormalize(current * 0.55 + want * 0.45, fallback: dot2(current) > 0 ? current : heading)
                    let candidate = p + heading * ds
                    if let hit = surface.closest(candidate, within: max(ds * 2, liftAt(travelled) * 2 + ds)),
                       tie != nil || interpolate(lengths, corners(hit), hit.weights) > 0.05 {
                        next = hit.point + hit.normal * liftAt(travelled + ds)
                        surfaceNormal = hit.normal
                        lastHit = hit
                        facing = hit.normal
                        heading = safeNormalize(next - p, fallback: heading)
                    } else {
                        hugging = false
                        next = candidate
                    }
                    if let tie, !tail, length(next - tie) < tieRadius + 0.02 {
                        // Gathered: hang from the tie.
                        tail = true
                        hugging = false
                        let e1 = safeNormalize(cross(tailDirection, Vec3(1, 0, 0)), fallback: Vec3(0, 0, 1))
                        let e2 = cross(tailDirection, e1)
                        let angle = phase, r = tieRadius * jitter.squareRoot()
                        next = tie + (e1 * cosf(angle) + e2 * sinf(angle)) * r
                        heading = tailDirection
                        totalLength = travelled + length(next - p) + tieTail * (1 - lengthVariation * 0.5 * jitter)
                    }
                    if tie == nil, travelled + ds >= hugLength { hugging = false }
                } else if legacy {
                    // Out along the normal, leaning toward the comb, drooping by gravity.
                    let s = (travelled + ds) / strandLength
                    let bend = min(s * 3, 1)
                    var dir = n * (1 - lean * bend) + combDir * (lean * bend * 1.2) + down * (gravity * s)
                    dir = safeNormalize(dir, fallback: n)
                    next = p + dir * ds
                    heading = dir
                    // Stay above the root's tangent plane.
                    let rise = dot(next - root.position, n), minimum = step * Float(substeps) * 0.15 * min(Float(dense.count) / Float(substeps), 2)
                    if rise < minimum { next += n * (minimum - rise) }
                } else {
                    // Falling: gravity turns the strand down.
                    let pull: Float = tail ? 3 : 1
                    heading = safeNormalize(heading + down * (gravity * pull * ds / bendRadius), fallback: heading)
                    next = p + heading * ds
                }
                if !hugging, let pushed = collide(&next, offset: minLift + lift * 0.5, step: ds) {
                    facing = pushed
                    if !legacy { heading = safeNormalize(next - p, fallback: heading) }
                }
                facing = safeNormalize(facing - heading * dot(facing, heading), fallback: facing)
                travelled += ds
                p = next
                dense.append(p)
                normals.append(facing)
            }

            // A blunt cut at the hemline.
            if g.hemline.enabled {
                let q = shaper.frame.local(root.position)
                let along = min(max((q.z + 1) / 2, 0), 1)
                let height = g.hemline.back + (g.hemline.front - g.hemline.back) * along + g.hemline.softness * (jitter * 2 - 1)
                let limit = shaper.frame.center.y + shaper.frame.extent.y * height
                if let k = dense.indices.dropFirst().first(where: { dense[$0].y < limit }) {
                    let a = dense[k - 1], b = dense[k]
                    let f = a.y > b.y ? min(max((a.y - limit) / (a.y - b.y), 0), 1) : 0
                    dense.removeSubrange((k + 1)...)
                    normals.removeSubrange((k + 1)...)
                    dense[k] = a + (b - a) * f
                }
            }
            // Evenly spaced points along it.
            var arc = [Float](repeating: 0, count: dense.count)
            for k in 1..<max(dense.count, 1) { arc[k] = arc[k - 1] + length(dense[k] - dense[k - 1]) }
            let rest = arc.last ?? 0
            guard dense.count >= 2, rest > baseLength * 0.03 || (tie != nil && rest > 0.005) else { continue }
            var points = [root.position], pointNormals = [n]
            var j = 1
            for k in 1...segments {
                let target = rest * Float(k) / Float(segments)
                while j < dense.count - 1, arc[j] < target { j += 1 }
                let span = arc[j] - arc[j - 1]
                let f = span > 1e-9 ? min(max((target - arc[j - 1]) / span, 0), 1) : 1
                points.append(dense[j - 1] + (dense[j] - dense[j - 1]) * f)
                pointNormals.append(safeNormalize(normals[j - 1] * (1 - f) + normals[j] * f, fallback: normals[j]))
            }
            // Curls, waves and frizz across the strand.
            let segmentLength = rest / Float(segments)
            let strandFrizz = layer == .flyaway ? max(frizz, 0.25) : (layer == .inner ? frizz * 0.3 : frizz)
            let centerline = points
            if curl > 0 || wave > 0 || strandFrizz > 0 {
                for k in 1...segments {
                    let s = Float(k) / Float(segments)
                    let tangent = safeNormalize(centerline[min(k + 1, segments)] - centerline[k - 1], fallback: n)
                    let out = safeNormalize(pointNormals[k] - tangent * dot(pointNormals[k], tangent), fallback: n)
                    let side = safeNormalize(cross(tangent, out), fallback: Vec3(1, 0, 0))
                    let angle = s * turns * 2 * .pi + phase
                    if curl > 0 {
                        let amplitude = curl * rest * 0.08 * (legacy ? s : min(s * 2.5, 1)) * (layer == .outer ? 1 : 0.4)
                        points[k] += (side * cosf(angle) + out * sinf(angle)) * amplitude
                    }
                    if wave > 0 {
                        let amplitude = wave * min(rest * 0.06, 0.03) * min(s * 3, 1) * (layer == .outer ? 1 : 0.4)
                        points[k] += (side * 0.85 + out * 0.35) * (sinf(angle) * amplitude)
                    }
                    if strandFrizz > 0 {
                        points[k] += Vec3(rng.float() - 0.5, rng.float() - 0.5, rng.float() - 0.5) * (strandFrizz * segmentLength * 0.6 * s)
                    }
                }
            }
            let width: Float = switch layer {
            case .outer: 1
            case .inner: 1.4
            case .flyaway: 0.7
            }
            guides.append(Guide(points: points, normal: n, skin: skin, normals: pointNormals, layer: layer, width: width, length: rest))
            centerlines.append(centerline)
        }

        // Clumps: each guide leans toward the nearest leader (the first of every `clumpSize`
        // outer guides) on its side of the part, more toward the tip.
        let clumping = clamp01(g.clumping)
        let outer = guides.indices.filter { guides[$0].layer == .outer }
        if clumping > 0, outer.count > 8 {
            let leaders = Array(outer.prefix(max(1, outer.count / min(max(g.clumpSize, 2), 64))))
            let leaderSet = Set(leaders)
            func side(_ p: Vec3) -> Bool { shaper.partClosest(p).map { p.x >= $0.x } ?? true }
            let leaderSides = leaders.map { side(guides[$0].root) }
            let original = guides
            for i in guides.indices where guides[i].layer != .flyaway {
                if leaderSet.contains(i) { guides[i].clump = i; continue }
                let root = original[i].root
                let mySide = side(root)
                var best = -1
                var bestDistance = Float.greatestFiniteMagnitude
                for (j, leader) in leaders.enumerated() {
                    let d2 = dot2(original[leader].root - root) * (leaderSides[j] == mySide ? 1 : 16)
                    if d2 < bestDistance { bestDistance = d2; best = leader }
                }
                guard best >= 0 else { continue }
                guides[i].clump = best
                let leader = original[best].points
                let pull = clumping * 0.85 * (guides[i].layer == .inner ? 0.3 : 1)
                for k in 1..<guides[i].points.count where k < leader.count {
                    let s = Float(k) / Float(guides[i].points.count - 1)
                    guides[i].points[k] += (leader[k] - guides[i].points[k]) * (pull * s * s)
                }
            }
        }
        // Out of the head along the whole strand, after the clumps and curls moved the points.
        if g.collide {
            for i in guides.indices {
                let step = guides[i].length / Float(segments * substeps)
                for k in 1..<guides[i].points.count {
                    // Look as far as curls and clumps moved the point off the grown (collided) curve.
                    let moved = k < centerlines[i].count ? length(guides[i].points[k] - centerlines[i][k]) : step
                    if let pushed = collide(&guides[i].points[k], offset: minLift, step: step + moved * 0.6), k < guides[i].normals.count {
                        guides[i].normals[k] = pushed
                    }
                }
            }
        }
        return (guides, requested)
    }

    /// The card mesh of `base`: the first `fraction` of the guides as strips (nil when no fur grows).
    public static func cards(_ base: MeshGeometry, fur: MaterialFur, fraction: Float = 1) -> MeshGeometry? {
        cards(guides: guides(base, fur: fur).guides, fur: fur, fraction: fraction, skinned: base.skin != nil)
    }

    /// Strips along `guides` (see `cards(_:fur:fraction:)`; `cardSpans` maps guides to vertices).
    public static func cards(guides all: [Guide], fur: MaterialFur, fraction: Float = 1, skinned: Bool) -> MeshGeometry? {
        let f = fraction.isFinite ? min(max(fraction, 0.01), 1) : 1
        let guides = all.prefix(cardCount(guides: all.count, fraction: f))
        guard !all.isEmpty, !guides.isEmpty else { return nil }
        let width = cardWidth(fur: fur, fraction: f)
        let taper = clamp01(fur.groom.cardTaper)
        var vertices: [MeshVertex] = []
        var indices: [UInt32] = []
        var skin: [SkinInfluence]? = skinned ? [] : nil
        var facing: [Vec3] = []
        for (index, guide) in guides.enumerated() {
            let count = guide.points.count
            guard count >= 2 else { continue }
            let first = UInt32(vertices.count)
            facing.removeAll(keepingCapacity: true)
            for k in 0..<count { facing.append(k < guide.normals.count ? guide.normals[k] : guide.normal) }
            vertices.append(contentsOf: repeatElement(MeshVertex(position: .zero, normal: .zero), count: count * 2))
            vertices.withUnsafeMutableBufferPointer { out in
                guide.points.withUnsafeBufferPointer { points in
                    facing.withUnsafeBufferPointer { facing in
                        writeCard(points: points, facing: facing, width: width * (guide.width.isFinite ? max(guide.width, 0.05) : 1),
                                  taper: taper, random: cardRandom(index), into: out.baseAddress! + Int(first))
                    }
                }
            }
            for _ in 0..<(count * 2) { skin?.append(guide.skin ?? SkinInfluence(joint: 0)) }
            for k in 1..<count {
                let a = first + UInt32((k - 1) * 2), b = a + 1, c = a + 2, d = a + 3
                indices += [a, c, b, b, c, d]
            }
        }
        guard !indices.isEmpty else { return nil }
        return MeshGeometry(vertices: vertices, indices: indices, skin: skin)
    }

    /// The full width of a card at detail level `fraction` (fewer, wider cards farther away).
    public static func cardWidth(fur: MaterialFur, fraction: Float) -> Float {
        let f = fraction.isFinite ? min(max(fraction, 0.01), 1) : 1
        return (fur.groom.cardWidth.isFinite ? min(max(fur.groom.cardWidth, 0.0005), 0.5) : 0.012) * min(2, 1 / f.squareRoot())
    }

    /// A random number per card (tangent.w's fraction) that varies its strands in the shader.
    public static func cardRandom(_ index: Int) -> Float { (Float(index) * 0.618_034).truncatingRemainder(dividingBy: 1) * 0.999 }

    /// Writes one card's vertices (two per point, left then right, root first) along `points`
    /// facing `facing` (per point), `width` wide at the root narrowing by `taper` to the tip:
    /// what `cards` draws, and what the hair simulation rewrites every frame from moved points.
    public static func writeCard(points: UnsafeBufferPointer<Vec3>, facing: UnsafeBufferPointer<Vec3>, width: Float, taper: Float,
                                 random: Float, into out: UnsafeMutablePointer<MeshVertex>) {
        let count = points.count
        guard count >= 2 else { return }
        let inverse = 1 / Float(count - 1)
        for k in 0..<count {
            let s = Float(k) * inverse
            let face = facing[k]
            let t = safeNormalize(points[min(k + 1, count - 1)] - points[max(k - 1, 0)], fallback: face)
            var side = cross(t, face)
            if dot(side, side) < 1e-10 { side = cross(t, abs(t.y) < 0.9 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)) }
            side = safeNormalize(side, fallback: Vec3(1, 0, 0))
            var normal = safeNormalize(cross(side, t), fallback: face)
            if dot(normal, face) < 0 { normal = -normal }
            let half = width * (1 - taper * s) * 0.5
            let tangent = Vec4(t, 2 + random)
            out[k * 2] = MeshVertex(position: points[k] - side * half, normal: normal, uv: Vec2(0, s), tangent: tangent)
            out[k * 2 + 1] = MeshVertex(position: points[k] + side * half, normal: normal, uv: Vec2(1, s), tangent: tangent)
        }
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

    package static func clamp01(_ x: Float) -> Float { x.isFinite ? min(max(x, 0), 1) : 0 }

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
