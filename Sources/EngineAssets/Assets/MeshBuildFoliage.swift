import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// Foliage: a `foliage` part is a cloud of leaf cards (quads cut out by a leaf look's alpha,
// MeshBuildLeafLooks.swift), the cheap, realistic way games draw leaves:
//
// ```json
// {"name": "Crown", "shape": "foliage", "look": "oakLeaves", "position": [0, 4, 0], "size": [3, 2.5, 3]},
// {"name": "Leaves", "shape": "foliage", "look": "broadleaf", "on": ["Branch East", "Twig West"]},
// {"name": "Grass", "shape": "foliage", "look": "grassBlades", "size": [2, 0.4, 2], "density": 0.8}
// ```
//
// - A volume (no `on`): tree and shrub looks cover the ellipsoid filling `size` with cards, most of
//   them on its outer shell (facing outward, tilted and rolled at random) and some inside; upright
//   looks (grassBlades, flowers, fern) stand crossed pairs of cards (tufts) on the floor of the box,
//   as tall as `size.y`, scattered over the ellipse of its footprint.
// - `on` (a part name or a list): cards sprout along the outer part of each named sweep (`along`
//   [from, to] of its length, default [0.35, 1]: twigs and branch tips), pointing outward and up
//   from its surface, or over the surface of any other mesh part (ivy on a wall, moss on a rock).
//   The part's `size` is unused; its position and rotation don't move the leaves (they stay on
//   their targets).
//
// Cards are `cardSize` meters (default per look, ±25% at random), 2 triangles each (an upright
// tuft is 4). Their number is `count`, or `density` (default 1: a full canopy) times what covers
// the volume, branches or surfaces about twice over, capped at `maxFoliageTriangles`. Everything
// is seeded (`seed`, plus the part's name), so a build always makes the same cards.
//
// Normals are bent: each card's normal leans toward the outward normal of the whole cloud (its
// ellipsoid, or the box around the cards on branches), so the canopy shades as one rounded volume
// in light and shadow instead of as many flat, differently lit planes; the baked occlusion then
// darkens the cards inside it.

/// What a foliage part grows on, resolved in its own space (`MeshBuild.attachingFoliageTargets`).
public struct MeshBuildFoliageTarget: Equatable, Sendable {
    public var name: String
    /// A sweep's spine: points, unit tangents and the radius at each.
    public var path: [Vec3] = []
    public var tangents: [Vec3] = []
    public var radii: [Float] = []
    /// Another mesh's triangles.
    public var positions: [Vec3] = []
    public var normals: [Vec3] = []
    public var indices: [UInt32] = []
}

extension MeshBuildPart {
    /// What the tool docs say about foliage, ribbons and leaf looks (appended to the format doc).
    public static let foliageDoc = """
        Foliage and plants: shape "foliage" scatters leaf cards (quads cut out by a leaf look, double-sided, alpha \
        cutout incl. shadows, normals bent outward from the whole cloud so it shades like one rounded volume). Leaf \
        looks: \(MeshBuildLeafLook.nameList) (color tints them; leave color out for their own). Without `on`, tree \
        looks fill the ellipsoid of `size` (cards mostly on its shell facing out, some inside); grassBlades, flowers \
        and fern stand crossed tufts on the floor of the box, size.y tall. With `on` ("Branch" or ["Branch A","Twig B"]) \
        cards sprout from the outer part of those sweeps (`along` [from,to] of their length, default [0.35,1]) or \
        cover any other part's surface (ivy on a wall); then size is unused. cardSize m (default 0.35-0.6 per look), \
        density (default 1 = full; 0.5 sparse) or count (exact cards), seed. Each card is 2 triangles (a tuft 4): \
        results give `triangles`; keep a whole tree under about 15k. Crown: {"name":"Crown","shape":"foliage",\
        "look":"oakLeaves","parent":"Trunk","position":[0,4,0],"size":[3,2.4,3]}. Tips: put a crown where the \
        branches end (cards touch them) and/or "on" the twigs; use bark look on tapered sweeps for wood (no noise \
        deform needed: the bark normal map gives the relief). Ribbons: a sweep with `ribbon` w (a flat strip w m wide, \
        times radii) or `profile` + `open`:true (an open curve, e.g. a V-fold) is a double-sided surface with no \
        caps: grass blades, leaves on stems, fronds, straps, cloth strips, sail sections. A leaf look on a ribbon or a \
        plane maps one sprig along it (base at the path's start): a fern ribbon is a frond. Frond: {"shape":"sweep",\
        "path":[[0,0,0],[0.1,0.35,0],[0.35,0.55,0]],"ribbon":0.22,"radii":[0.6,1,0.5],"look":"fern"}.
        """

    /// The most triangles one foliage part makes.
    public static let maxFoliageTriangles = 12_000
    /// Cards along `on` sweeps at density 1: this many per card length of leafy branch.
    static let cardsPerCardLength: Float = 10
    /// Where along a sweep leaves grow by default (fractions of its length).
    public static let defaultFoliageAlong = Vec2(0.35, 1)

    /// The leaf look this part's `look` names, if it names one.
    public var leafLook: MeshBuildLeafLook? {
        guard let look, !look.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return MeshBuildLeafLook.named(look)
    }

    /// The leaf look the part draws with: its own, or broadleaf for a foliage part without one;
    /// nil for other parts without a leaf look.
    public var resolvedLeafLook: MeshBuildLeafLook? {
        if let leafLook { return leafLook }
        return shape == .foliage ? .broadleaf : nil
    }

    /// A sweep drawn as an open, double-sided surface (`ribbon` or `open`).
    public var isRibbon: Bool { shape == .sweep && ((ribbon ?? 0) > 0 || open == true) }

    /// The card side in meters.
    public var effectiveCardSize: Float {
        if let cardSize, cardSize.isFinite, cardSize > 0.005 { return cardSize }
        return (resolvedLeafLook ?? .broadleaf).defaultCardSize
    }

    /// Problems with the foliage and ribbon fields (cheap: nothing is built).
    var foliageFieldWarnings: [String] {
        var warnings: [String] = []
        let name = shape.rawValue
        if shape != .foliage {
            let unused = [("cardSize", cardSize != nil), ("count", count != nil), ("density", density != nil), ("seed", seed != nil),
                          ("on", on != nil), ("along", along != nil)].filter(\.1).map(\.0)
            if !unused.isEmpty { warnings.append("\(unused.joined(separator: ", ")) only shape foliage parts; this \(name) ignores it") }
        } else {
            if let look, !look.trimmingCharacters(in: .whitespaces).isEmpty, leafLook == nil {
                let hint = MeshBuildLook.named(look) == .grass ? " (grassBlades is the leaf look for grass)" : ""
                warnings.append("foliage needs a leaf look (\(MeshBuildLeafLook.nameList)); '\(look)' isn't one\(hint), so broadleaf was used")
            }
            if let cardSize, !(cardSize.isFinite && cardSize > 0.005) { warnings.append("cardSize must be a number of meters > 0.005") }
            if let density, !(density.isFinite && density > 0) { warnings.append("density must be a number > 0 (1 = a full canopy)") }
            if let count, count < 0 { warnings.append("count must be ≥ 0 cards") }
            if let along, !(along.x.isFinite && along.y.isFinite && along.x >= 0 && along.y <= 1 && along.x < along.y) {
                warnings.append("along must be [from, to] fractions of the length with 0 ≤ from < to ≤ 1; [0.35, 1] was used")
            }
            if along != nil && (on ?? []).isEmpty { warnings.append("along only matters with on (where on the branches leaves grow)") }
            if !(on ?? []).isEmpty && size != Vec3(1, 1, 1) {
                warnings.append("size is unused when foliage grows on other parts (the leaves follow them); leave it out")
            }
        }
        if shape != .sweep {
            let unused = [("ribbon", ribbon != nil), ("open", open != nil)].filter(\.1).map(\.0)
            if !unused.isEmpty { warnings.append("\(unused.joined(separator: ", ")) only shape sweep parts; this \(name) ignores it") }
        } else if let ribbon, !(ribbon.isFinite && ribbon >= 0) {
            warnings.append("ribbon must be a width in meters > 0")
        } else if open == true && (profile ?? []).isEmpty && (ribbon ?? 0) <= 0 {
            warnings.append("open needs a profile (the open curve across the strip) or a ribbon width; a 0.05 m flat strip was used")
        }
        if shape != .foliage && shape != .sweep && shape != .plane, leafLook != nil, shape != .group {
            warnings.append("a leaf look is a cut-out picture for foliage, ribbons and planes; on this \(name) it maps one sprig over the "
                            + "whole shape")
        }
        return warnings
    }

    // MARK: Geometry

    /// The part's seed for its cards (its `seed` and its name).
    var foliageSeed: UInt64 {
        UInt64(truncatingIfNeeded: seed ?? 0) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(Self.nameHash(name)) &* 0xD6E8_FEB8_6659_FD93
    }

    /// The cards the fields ask for, before the cap.
    func requestedFoliageCards(look: MeshBuildLeafLook) -> Int {
        if let count { return max(count, 0) }
        let s = effectiveCardSize, d = density.map { $0.isFinite && $0 > 0 ? $0 : 1 } ?? 1
        if !foliageTargets.isEmpty {
            var measure: Float = 0
            let range = foliageAlong
            for t in foliageTargets {
                if t.path.count >= 2 {
                    var total: Float = 0
                    for i in 1..<t.path.count { total += length(t.path[i] - t.path[i - 1]) }
                    measure += Self.cardsPerCardLength * total * (range.y - range.x) / s
                } else {
                    measure += 2.5 * Self.area(t.positions, t.indices) / (s * s)
                }
            }
            return Int((measure * d).rounded())
        }
        let r = Vec3(abs(size.x), abs(size.y), abs(size.z)) / 2
        if look.isUpright {
            return Int((d * 2.5 * Float.pi * r.x * r.z / (s * s)).rounded())
        }
        // Knud Thomsen's ellipsoid surface area.
        let p: Float = 1.6075
        let ap = powf(r.x, p), bp = powf(r.y, p), cp = powf(r.z, p)
        let area = 4 * Float.pi * powf((ap * bp + ap * cp + bp * cp) / 3, 1 / p)
        return Int((d * 4.5 * area / (s * s)).rounded())
    }

    public var foliageAlong: Vec2 {
        if let along, along.x.isFinite, along.y.isFinite, along.x >= 0, along.y <= 1, along.x < along.y { return along }
        return Self.defaultFoliageAlong
    }

    /// Triangles one card (or tuft) makes for this part.
    func trianglesPerCard(look: MeshBuildLeafLook) -> Int { look.isUpright && foliageTargets.isEmpty ? 4 : 2 }

    /// The foliage part's cards (nil when there are none), adding a sentence to `warnings` for each problem.
    func foliageGeometry(warnings: inout [String]) -> MeshGeometry? {
        warnings += foliageContextWarnings
        let look = resolvedLeafLook ?? .broadleaf
        let perCard = trianglesPerCard(look: look)
        let requested = requestedFoliageCards(look: look)
        let cap = Self.maxFoliageTriangles / perCard
        if requested > cap {
            warnings.append("\(requested) cards would be \(requested * perCard) triangles; capped at \(cap) cards "
                            + "(\(Self.maxFoliageTriangles) triangles): use bigger cards (cardSize), a lower density or split it")
        }
        let cards = min(requested, cap)
        guard cards > 0, (on ?? []).isEmpty || !foliageTargets.isEmpty else { return nil }
        var rng = MeshBuildLeafPainter.Random(Int(truncatingIfNeeded: foliageSeed))
        var g = MeshGeometry(vertices: [], indices: [])
        g.vertices.reserveCapacity(cards * perCard * 2)
        if !(on ?? []).isEmpty {
            guard !foliageTargets.isEmpty else { return nil }  // nothing to grow on (warned when resolved)
            cardsOnTargets(&g, cards: cards, look: look, rng: &rng)
        } else if look.isUpright {
            tufts(&g, count: cards, look: look, rng: &rng)
        } else {
            canopy(&g, cards: cards, rng: &rng)
        }
        g.paint = Self.cardVariation(cardCount: g.vertices.count / 4, seed: foliageSeed)
        return g.indices.isEmpty ? nil : g
    }

    /// Each card's (4 vertices') vertex paint: a subtle, seeded color jitter so a canopy isn't one
    /// flat tint: brightness ±12%, a warmer (yellower) or cooler (bluer) cast up to about 7%, and
    /// roughness ±8%.
    static func cardVariation(cardCount: Int, seed: UInt64) -> [VertexPaint] {
        var rng = MeshBuildLeafPainter.Random(Int(truncatingIfNeeded: seed ^ 0x5EED_CA4D))
        var paint: [VertexPaint] = []
        paint.reserveCapacity(cardCount * 4)
        for _ in 0..<cardCount {
            let brightness = rng.range(0.88, 1.12), warmth = rng.range(-1, 1), rough = rng.range(0.92, 1.08)
            let color = Vec4(brightness * (1 + 0.06 * warmth), brightness * (1 + 0.015 * warmth), brightness * (1 - 0.07 * warmth), 1)
            paint += Array(repeating: VertexPaint(color: color, surface: Vec4(rough, 1, 1, 0)), count: 4)
        }
        return paint
    }

    /// A random unit vector.
    private static func randomDirection(_ rng: inout MeshBuildLeafPainter.Random) -> Vec3 {
        let z = rng.range(-1, 1), a = rng.range(0, 2 * .pi)
        let r = max(1 - z * z, 0).squareRoot()
        return Vec3(r * cosf(a), z, r * sinf(a))
    }

    /// Adds one card: a quad whose stem end is at `base`, growing along `tip` (unit), facing
    /// `normal` (unit, perpendicular to `tip`), `side` meters, with a random sprig of the look
    /// (mirrored at random). `bent` gives each corner's shading normal.
    private func addCard(_ g: inout MeshGeometry, base: Vec3, tip: Vec3, normal: Vec3, side: Float, width: Float? = nil,
                         rng: inout MeshBuildLeafPainter.Random, bent: (Vec3) -> Vec3) {
        let right = cross(tip, normal)
        let halfWidth = (width ?? side) / 2
        let corners = [base - right * halfWidth, base + right * halfWidth, base + right * halfWidth + tip * side,
                       base - right * halfWidth + tip * side]
        let (origin, extent) = MeshBuildLeafTextures.variantRect(Int(rng.next() * 4))
        let flip = rng.next() < 0.5
        let us: [Float] = flip ? [1, 0, 0, 1] : [0, 1, 1, 0]
        let vs: [Float] = [1, 1, 0, 0]
        let first = UInt32(g.vertices.count)
        for k in 0..<4 {
            g.vertices.append(MeshVertex(position: corners[k], normal: bent(corners[k]),
                                         uv: origin + Vec2(us[k] * extent.x, vs[k] * extent.y)))
        }
        // right × tip = normal: counter-clockwise seen from the side the card faces.
        g.indices += [first, first + 1, first + 2, first, first + 2, first + 3]
    }

    /// `v` made perpendicular to unit `n` and normalized (nil if it is along `n`).
    private static func perpendicular(_ v: Vec3, to n: Vec3) -> Vec3? {
        let p = v - n * dot(v, n)
        let l = length(p)
        return l > 1e-4 ? p / l : nil
    }

    /// Cards over the ellipsoid of `size`: 78% on its outer shell, the rest inside.
    private func canopy(_ g: inout MeshGeometry, cards: Int, rng: inout MeshBuildLeafPainter.Random) {
        let r = pointwiseMax(Vec3(abs(size.x), abs(size.y), abs(size.z)) / 2, Vec3(repeating: 0.01))
        let s = effectiveCardSize
        let up = Vec3(0, 1, 0)
        func outward(_ q: Vec3) -> Vec3 {
            let n = q / (r * r)
            return length(n) > 1e-6 ? normalize(n) : up
        }
        for _ in 0..<cards {
            let dir = Self.randomDirection(&rng)
            let shell = rng.next() < 0.78
            let depth = shell ? rng.range(0.8, 0.97) : powf(rng.next(), 0.5) * 0.75 + 0.05
            let center = dir * r * depth
            let out = outward(center)
            // Facing outward, tilted at random and a little toward the sky.
            let normal = normalize(out + Self.randomDirection(&rng) * 0.6 + up * 0.25)
            let tip = Self.perpendicular(up * 0.7 + out * 0.5 + Self.randomDirection(&rng) * 0.9, to: normal)
                ?? Self.perpendicular(Vec3(1, 0, 0), to: normal) ?? Vec3(0, 0, 1)
            let side = s * rng.range(0.75, 1.25)
            var base = center - tip * side * 0.5
            // Keep the card inside the size box: `size` is the canopy's outer bound.
            let right = cross(tip, normal) * (side / 2)
            let corners = [base - right, base + right, base + right + tip * side, base - right + tip * side]
            let lo = corners.reduce(Vec3(repeating: .infinity), pointwiseMin)
            let hi = corners.reduce(Vec3(repeating: -.infinity), pointwiseMax)
            base += pointwiseMax(-r - lo, .zero) - pointwiseMax(hi - r, .zero)
            addCard(&g, base: base, tip: tip, normal: normal, side: side, rng: &rng) { corner in
                normalize(normal * 0.22 + outward(corner))
            }
        }
    }

    /// Crossed upright cards standing on the floor of the box, scattered over its footprint ellipse.
    private func tufts(_ g: inout MeshGeometry, count: Int, look: MeshBuildLeafLook, rng: inout MeshBuildLeafPainter.Random) {
        let r = pointwiseMax(Vec3(abs(size.x), abs(size.y), abs(size.z)) / 2, Vec3(repeating: 0.005))
        let s = effectiveCardSize
        let up = Vec3(0, 1, 0)
        for _ in 0..<count {
            let a = rng.range(0, 2 * .pi), d = rng.next().squareRoot()
            let foot = Vec3(cosf(a) * d * r.x, -r.y, sinf(a) * d * r.z)
            let height = 2 * r.y * rng.range(0.7, 1.0) * (1 - 0.25 * d * d)
            let width = s * rng.range(0.8, 1.2)
            let yaw = rng.range(0, .pi)
            let lean = Vec3(rng.range(-0.15, 0.15), 0, rng.range(-0.15, 0.15))
            let radial = Vec3(foot.x / r.x, 0, foot.z / r.z)
            for k in 0..<2 {
                let angle = yaw + Float(k) * .pi / 2
                let facing = Vec3(cosf(angle), 0, sinf(angle))
                let tip = normalize(up + facing * dot(lean, facing))  // leaning out of its plane only
                // The base edge stays level (on the floor): right is horizontal, the normal follows the lean.
                let right = Vec3(-facing.z, 0, facing.x)
                let normal = normalize(cross(right, tip))
                // Stretched to the tuft's height, standing on the floor.
                let base = foot
                addCard(&g, base: base, tip: tip, normal: normal, side: height, width: width,
                        rng: &rng) { corner in
                    let rise = min(max((corner.y + r.y) / max(2 * r.y, 1e-3), 0), 1)
                    return normalize(up * (0.7 + 0.3 * rise) + radial * 0.45 + normal * 0.15)
                }
            }
        }
    }

    /// Cards on the resolved targets: along the outer part of sweeps, over other surfaces.
    private func cardsOnTargets(_ g: inout MeshGeometry, cards: Int, look: MeshBuildLeafLook, rng: inout MeshBuildLeafPainter.Random) {
        let s = effectiveCardSize
        let up = Vec3(0, 1, 0)
        let range = foliageAlong
        // Each target's share of the cards by its measure (leafy length, or area).
        var measures: [Float] = foliageTargets.map { t in
            if t.path.count >= 2 {
                var total: Float = 0
                for i in 1..<t.path.count { total += length(t.path[i] - t.path[i - 1]) }
                return Self.cardsPerCardLength * total * (range.y - range.x) / s
            }
            return 2.5 * Self.area(t.positions, t.indices) / (s * s)
        }
        let sum = max(measures.reduce(0, +), 1e-6)
        measures = measures.map { $0 / sum }
        // The cloud the bent normals lean out of: the box around the targets' leafy parts.
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for t in foliageTargets {
            if t.path.count >= 2 {
                var lengths: [Float] = [0]
                for i in 1..<t.path.count { lengths.append(lengths[i - 1] + length(t.path[i] - t.path[i - 1])) }
                let total = max(lengths.last!, 1e-6)
                for (i, p) in t.path.enumerated() where lengths[i] / total >= range.x - 0.05 {
                    lo = pointwiseMin(lo, p - Vec3(repeating: s * 0.6))
                    hi = pointwiseMax(hi, p + Vec3(repeating: s * 0.6))
                }
            } else {
                for p in t.positions {
                    lo = pointwiseMin(lo, p)
                    hi = pointwiseMax(hi, p)
                }
            }
        }
        let center = (lo + hi) / 2, half = pointwiseMax((hi - lo) / 2, Vec3(repeating: s))
        func outward(_ q: Vec3) -> Vec3 {
            let n = (q - center) / (half * half)
            return length(n) > 1e-6 ? normalize(n) : up
        }
        var made = 0
        for (k, t) in foliageTargets.enumerated() {
            let share = k == foliageTargets.count - 1 ? cards - made : Int((Float(cards) * measures[k]).rounded())
            let n = max(min(share, cards - made), 0)
            made += n
            guard n > 0 else { continue }
            if t.path.count >= 2 {
                var lengths: [Float] = [0]
                for i in 1..<t.path.count { lengths.append(lengths[i - 1] + length(t.path[i] - t.path[i - 1])) }
                let total = max(lengths.last!, 1e-6)
                func at(_ u: Float) -> (Vec3, Vec3, Float) {
                    let target = u * total
                    var i = 1
                    while i < lengths.count - 1 && lengths[i] < target { i += 1 }
                    let span = max(lengths[i] - lengths[i - 1], 1e-6)
                    let f = min(max((target - lengths[i - 1]) / span, 0), 1)
                    let tangent = t.tangents[i - 1] * (1 - f) + t.tangents[i] * f
                    return (t.path[i - 1] * (1 - f) + t.path[i] * f, length(tangent) > 1e-6 ? normalize(tangent) : up,
                            t.radii[i - 1] * (1 - f) + t.radii[i] * f)
                }
                for j in 0..<n {
                    // Evenly along the leafy part, jittered; the last card of a sweep ends it.
                    let isTip = j == n - 1 && range.y >= 0.999
                    let u = isTip ? 1 : range.x + (range.y - range.x) * min((Float(j) + rng.next()) / Float(n), 1)
                    let (p, tangent, radius) = at(u)
                    var radial = Self.perpendicular(Self.randomDirection(&rng) + up * 0.3, to: tangent) ?? Vec3(1, 0, 0)
                    if isTip { radial = Self.perpendicular(up, to: tangent) ?? radial }
                    let side = s * rng.range(0.75, 1.2)
                    let tip = normalize(isTip ? tangent + radial * 0.2 : radial * 0.85 + tangent * 0.55 + up * 0.3
                                        + Self.randomDirection(&rng) * 0.3)
                    let facing = up * 0.8 + radial * 0.4 + Self.randomDirection(&rng) * 0.45
                    let normal = Self.perpendicular(facing, to: tip) ?? Self.perpendicular(tangent, to: tip) ?? up
                    let base = p + radial * radius * 0.6 - tip * side * 0.08
                    addCard(&g, base: base, tip: tip, normal: normal, side: side, rng: &rng) { corner in
                        normalize(normal * 0.35 + outward(corner))
                    }
                }
            } else {
                // Area-weighted triangles of the surface.
                var cumulative: [Float] = []
                var total: Float = 0
                for i in stride(from: 0, to: t.indices.count - 2, by: 3) {
                    let a = t.positions[Int(t.indices[i])], b = t.positions[Int(t.indices[i + 1])], c = t.positions[Int(t.indices[i + 2])]
                    total += length(cross(b - a, c - a)) / 2
                    cumulative.append(total)
                }
                guard total > 0 else { continue }
                for _ in 0..<n {
                    let pick = rng.next() * total
                    var lo = 0, hi = cumulative.count - 1
                    while lo < hi {
                        let mid = (lo + hi) / 2
                        if cumulative[mid] < pick { lo = mid + 1 } else { hi = mid }
                    }
                    let i = lo * 3
                    var u = rng.next(), v = rng.next()
                    if u + v > 1 { u = 1 - u; v = 1 - v }
                    let ia = Int(t.indices[i]), ib = Int(t.indices[i + 1]), ic = Int(t.indices[i + 2])
                    let p = t.positions[ia] * (1 - u - v) + t.positions[ib] * u + t.positions[ic] * v
                    var surface = t.normals[ia] * (1 - u - v) + t.normals[ib] * u + t.normals[ic] * v
                    surface = length(surface) > 1e-6 ? normalize(surface) : up
                    let normal = normalize(surface + Self.randomDirection(&rng) * 0.45 + up * 0.1)
                    let tip = Self.perpendicular(up * 0.8 + Self.randomDirection(&rng) * 0.9, to: normal)
                        ?? Self.perpendicular(Vec3(1, 0, 0), to: normal) ?? Vec3(0, 0, 1)
                    let side = s * rng.range(0.75, 1.2)
                    let base = p + surface * min(s * 0.08, 0.03) - tip * side * 0.35
                    addCard(&g, base: base, tip: tip, normal: normal, side: side, rng: &rng) { _ in
                        normalize(normal * 0.4 + surface)
                    }
                }
            }
        }
    }

    static func area(_ positions: [Vec3], _ indices: [UInt32]) -> Float {
        var total: Float = 0
        for i in stride(from: 0, to: indices.count - 2, by: 3) {
            let a = positions[Int(indices[i])], b = positions[Int(indices[i + 1])], c = positions[Int(indices[i + 2])]
            total += length(cross(b - a, c - a)) / 2
        }
        return total
    }

    /// A non-foliage part's mesh with its texture coordinates (0...1) squeezed into one sprig of
    /// its leaf look (chosen by its name), for leaf looks on ribbons and planes.
    func leafSprigUVs(_ geometry: MeshGeometry) -> MeshGeometry {
        var g = geometry
        let (origin, extent) = MeshBuildLeafTextures.variantRect(Int(Self.nameHash(name) % 4))
        for i in g.vertices.indices {
            let uv = g.vertices[i].uv
            g.vertices[i].uv = origin + Vec2(min(max(uv.x, 0), 1) * extent.x, min(max(uv.y, 0), 1) * extent.y)
        }
        return g
    }
}

// MARK: - Targets

extension MeshBuild {
    /// The build with every foliage part's `on` targets resolved into its own space
    /// (`MeshBuildPart.foliageTargets`), and problems naming them in `foliageContextWarnings`.
    /// A name also covers that part's mirror / repeat copies (`sources`: each part's source name,
    /// from `MeshBuild.expansion()`). Called by `gatheringSculpts`, so every consumer of a build's
    /// meshes sees them.
    public func attachingFoliageTargets(sources: [String]? = nil) -> MeshBuild {
        guard parts.contains(where: { $0.shape == .foliage && !($0.on ?? []).isEmpty }) else { return self }
        var out = self
        var firstIndex: [String: Int] = [:]
        for (i, part) in parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        let sources = sources.flatMap { $0.count == parts.count ? $0 : nil }
        var matrices: [Int: Mat4] = [:]
        func world(_ i: Int, depth: Int = 0) -> Mat4 {
            if let m = matrices[i] { return m }
            var m = parts[i].transform.matrix
            if let p = firstIndex[parts[i].parent], p != i, depth < parts.count { m = world(p, depth: depth + 1) * m }
            matrices[i] = m
            return m
        }
        func apply(_ m: Mat4, _ p: Vec3) -> Vec3 {
            let r = m * Vec4(p.x, p.y, p.z, 1)
            return Vec3(r.x, r.y, r.z)
        }
        func applyDirection(_ m: Mat4, _ d: Vec3) -> Vec3 {
            let r = m * Vec4(d.x, d.y, d.z, 0)
            let v = Vec3(r.x, r.y, r.z)
            return length(v) > 1e-9 ? normalize(v) : v
        }
        for (i, part) in parts.enumerated() where part.shape == .foliage {
            let names = (part.on ?? []).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard !names.isEmpty else { continue }
            let toPart = world(i).inverse
            var targets: [MeshBuildFoliageTarget] = []
            var warnings: [String] = []
            var used: Set<Int> = []
            for name in names {
                guard let first = firstIndex[name] else {
                    warnings.append("on names '\(name)', which isn't a part")
                    continue
                }
                // The part and its copies.
                var indices = [first]
                if let sources { indices += parts.indices.filter { $0 != first && sources[$0] == name && parts[$0].name != name } }
                for j in indices where used.insert(j).inserted {
                    let target = parts[j]
                    guard j != i, target.shape != .foliage, target.shape != .group else {
                        if j == first {
                            warnings.append("foliage can't grow on '\(name)' (\(j == i ? "itself" : "a \(target.shape.rawValue)")); "
                                            + "name sweeps or mesh parts")
                        }
                        continue
                    }
                    let m = toPart * world(j)
                    // Mirror copies draw their meshes reflected: the target's reflection first, then
                    // this part's undone ahead of time, so the leaves land on the target.
                    let r = part.reflection, own = target.reflection
                    var t = MeshBuildFoliageTarget(name: target.name)
                    if target.shape == .sweep, let spine = target.sweepSpine() {
                        t.path = spine.points.map { apply(m, $0 * own) * r }
                        t.tangents = spine.tangents.map { applyDirection(m, $0 * own) * r }
                        func stretch(_ d: Vec3) -> Float {
                            let v = m * Vec4(d.x, d.y, d.z, 0)
                            return length(Vec3(v.x, v.y, v.z))
                        }
                        let scale = (stretch(Vec3(1, 0, 0)) + stretch(Vec3(0, 1, 0)) + stretch(Vec3(0, 0, 1))) / 3
                        t.radii = spine.radii.map { $0 * scale }
                    } else if let g = target.geometry(), !g.indices.isEmpty {
                        t.positions = g.vertices.map { apply(m, $0.position) * r }
                        t.normals = g.vertices.map { applyDirection(m, $0.normal) * r }
                        t.indices = g.indices
                    } else {
                        if j == first { warnings.append("'\(name)' has no mesh to grow on") }
                        continue
                    }
                    targets.append(t)
                }
            }
            out.parts[i].foliageTargets = targets
            out.parts[i].foliageContextWarnings = warnings
        }
        return out
    }
}

extension MeshBuildPart {
    /// A sweep's spine in its own space (after `size`): smoothed points, tangents and radii.
    func sweepSpine() -> (points: [Vec3], tangents: [Vec3], radii: [Float])? {
        guard shape == .sweep, let raw = path, raw.count >= 2 else { return nil }
        let s = Vec3(abs(size.x), abs(size.y), abs(size.z))
        var points: [Vec3] = [], scales: [Float] = []
        for (i, p) in raw.enumerated() where p.x.isFinite && p.y.isFinite && p.z.isFinite {
            if let last = points.last, length(p - last) <= 1e-6 { continue }
            points.append(p)
            let k = radii.flatMap { i < $0.count ? $0[i] : nil } ?? 1
            scales.append(k.isFinite ? max(k, 0) : 1)
        }
        guard points.count >= 2 else { return nil }
        let closed = (closed ?? false) && points.count >= 3
        let samples = (straight ?? false)
            ? MeshGeometry.cornerSamples(points, scales: scales, closed: closed)
            : MeshGeometry.smoothSamples(points, scales: scales, closed: closed)
        // The section's reach: the circle's radius, a profile's farthest point, half a ribbon.
        var reach = radius ?? MeshGeometry.defaultSweepRadius
        if let profile, !profile.isEmpty { reach = profile.reduce(Float(0)) { max($0, ($1.x * $1.x + $1.y * $1.y).squareRoot()) } }
        if let ribbon, ribbon > 0 { reach = ribbon / 2 }
        let sizeScale = (s.x + s.y + s.z) / 3
        return (samples.map { $0.position * s }, samples.map { normalize($0.tangent * s) }, samples.map { $0.scale * reach * sizeScale })
    }
}
