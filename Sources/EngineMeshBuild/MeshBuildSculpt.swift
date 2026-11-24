#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
#if canImport(Dispatch)
import Dispatch
#endif
import EngineCore
import EngineScene
import EngineAssets

// Sculpted parts: a `sculpt` part's children (its whole subtree) aren't drawn on their own. Each
// is a signed-distance version of its shape, and they are combined in file order into one
// surface (`blend` add / subtract / intersect, `smooth` meters of melting between them), which is
// meshed into the sculpt part's mesh. A creature's body melts into its legs, a window is cut out of
// a wall, a rock gets a bumpy surface (`noise`).
//
// ```json
// {"name": "Stone", "shape": "sculpt", "position": [0, 0.4, 0], "resolution": 64},
// {"name": "Block", "shape": "box", "parent": "Stone", "size": [1, 0.8, 0.6], "bevel": 0.05},
// {"name": "Dome", "shape": "sphere", "parent": "Stone", "position": [0, 0.4, 0], "size": [0.7, 0.5, 0.5], "smooth": 0.15},
// {"name": "Hole", "shape": "cylinder", "parent": "Stone", "rotation": [90, 0, 0], "size": [0.3, 1, 0.3], "blend": "subtract", "smooth": 0.03}
// ```
//
// - Children keep their position / rotation / size in the sculpt's space (grandchildren hang from
//   their parent as usual). Groups are pivots; a nested sculpt is a pivot too (with a warning);
//   a plane has no inside and is left out (with a warning). Every other shape works: box (with
//   `bevel`), sphere (an ellipsoid when its size isn't even), hemisphere, cylinder (with `bevel`),
//   cone, capsule, torus, tube, wedge, pyramid, lathe and extrude have exact formulas; sweeps,
//   lofts and any shape with `deform` use the distance to their (deformed) mesh
//   (MeshBuildMeshSDF.swift).
// - Mirror / repeat copies of children join the sculpt (`MeshBuild.gatheringSculpts`), right after
//   the part they copy, so a hole cut after mirrored legs cuts both.
// - The sculpt's own `size` multiplies the mesh (leave it [1, 1, 1]); `resolution` is cells along
//   the longest side of the shape (8...128, default 64); `noise` {amount, scale, seed} roughens the
//   surface (added and subtracted shapes alike; intersects trim it cleanly, so intersecting a big
//   box that stands on y = 0 gives a rough rock a flat base). Its look (color, texture, material…)
//   is the default; children that set look fields of their own get meshes of their own
//   (MeshBuildSculptLooks.swift). UVs are box-projected in meters (as `worldUV`).
// - Meshing: the distance field is sampled on a grid (coarse blocks far from the surface are
//   skipped), then dual contouring places one vertex per surface cell where the crossing planes
//   meet, so carved boxes keep crisp edges; normals come from the field's gradient and are split
//   where faces meet at more than 40°. Results are cached by their inputs.
// - A sculpt is one surface (one mesh per look): animation tracks on its children warn and do
//   nothing visible; animate the sculpt part itself.

/// A build with every sculpt's subtree gathered into it (`MeshBuild.gatheringSculpts`).
public struct MeshBuildSculpting: Sendable {
    /// The same parts in the same order; each sculpt part has `sculptChildren` set.
    public var build: MeshBuild
    /// Indices (into `build.parts`) of the parts combined into a sculpt: they draw nothing themselves.
    public var sculpted: Set<Int>
    /// For each sculpted part's name, its sculpt's name.
    public var sculptOf: [String: String]

    /// The parts that draw (or are pivots) on their own: everything but the sculpted parts.
    public var drawnParts: [MeshBuildPart] {
        build.parts.enumerated().filter { !sculpted.contains($0.offset) }.map(\.element)
    }
}

extension MeshBuildPart {
    /// What the tool docs say about sculpts (appended to the format doc).
    public static let sculptDoc = """
        Sculpt: a part with shape "sculpt" draws its children (its whole subtree) as one smooth surface instead of \
        separate shapes, combined in file order. Each child's blend: "add" (default) joins it, "subtract" cuts it out, \
        "intersect" keeps only the overlap; smooth (m, default 0) melts it into what came before over that distance \
        (0.05-0.2 for organic joins, small values just round a cut's edge). Children keep their position/rotation/size \
        in the sculpt's space; every solid shape works (box with bevel, sphere/ellipsoid, hemisphere, cylinder, cone, \
        capsule, torus, tube, wedge, pyramid, lathe, extrude, sweep, loft, and any shape with deform, e.g. a swept \
        spout and handle melted onto a lathe pot; groups are pivots; planes are skipped); mirror/repeat children join \
        too. Sculpt fields: resolution (cells along the longest side, 8-128, default 64: more = finer detail, slower; \
        a sweep or rim needs about 3+ cells across), noise {amount m, scale m, seed} roughens the surface for \
        rock/bark/weathered stone (intersects trim cleanly: intersect a big box standing on y=0, as the last child, \
        for a flat base), size multiplies the mesh (keep [1,1,1]). Looks: the sculpt's color/look/material/roughness… \
        are the default; a child that sets any look field (color, look, wear, roughness, metallic, glow, texture, \
        material…) is drawn with its own look fields (e.g. linen cushions on a green fabric chair, a cream knob on a \
        blue teapot): each point of the surface takes the look of the added child it lies on (in a smooth join, the \
        nearer one). Where they meet with smooth > 0 the looks blend over a band about 1.5 x smooth wide (color, \
        roughness, metallic and glow mix; different textures cross-fade), e.g. moss melting into stone; smooth 0 keeps \
        a sharp line. A subtracted child with its own \
        look paints the cut it makes; without one, the cut takes the look of the child it cuts into. UVs are \
        world-projected in meters. A sculpt is one mesh per look: animate the sculpt part, not its children. Example: \
        {"name":"Stone","shape":"sculpt","position":[0,0.4,0]}, {"name":"Block","shape":"box","parent":"Stone",\
        "size":[1,0.8,0.6],"bevel":0.05}, {"name":"Hole","shape":"cylinder","parent":"Stone","rotation":[90,0,0],\
        "size":[0.3,1,0.3],"blend":"subtract","smooth":0.03,"color":[0.1,0.1,0.1]}.
        """

    /// Cells along a sculpt's longest side when `resolution` is unset, and the allowed range.
    public static let defaultSculptResolution = 64
    public static let sculptResolutionRange = 8...128

    /// The resolution a sculpt meshes at (`resolution` clamped, or the default).
    public var sculptResolution: Int {
        min(max(resolution ?? Self.defaultSculptResolution, Self.sculptResolutionRange.lowerBound), Self.sculptResolutionRange.upperBound)
    }

    /// Cheap checks of the sculpt fields on this part alone.
    var sculptFieldWarnings: [String] {
        var warnings: [String] = []
        if let resolution, shape == .sculpt, !Self.sculptResolutionRange.contains(resolution) {
            warnings.append("resolution \(resolution) is outside \(Self.sculptResolutionRange.lowerBound)..."
                            + "\(Self.sculptResolutionRange.upperBound) cells; \(sculptResolution) is used")
        }
        if resolution != nil, shape != .sculpt { warnings.append("resolution is only used by sculpt parts; this \(shape.rawValue) ignores it") }
        if noise != nil, shape != .sculpt { warnings.append("noise is only used by sculpt parts; this \(shape.rawValue) ignores it") }
        if let noise, shape == .sculpt, !(noise.amount.isFinite && noise.scale.isFinite && noise.scale > 0) {
            warnings.append("noise needs a finite amount and a scale above 0 meters; it is ignored")
        }
        if let smooth, !smooth.isFinite || smooth < 0 { warnings.append("smooth must be a number of meters ≥ 0") }
        return warnings
    }

    /// The sculpt's mesh from its `sculptChildren` (nil, with a warning, when they make no shape),
    /// scaled by `size`. Cached by its inputs.
    func sculptGeometry(warnings: inout [String]) -> MeshGeometry? {
        guard var geometry = sculptMesh(warnings: &warnings)?.geometry else { return nil }
        geometry.paint = nil  // blend weights are for the importer (MeshBuildSculptBlend.swift)
        return geometry
    }

    /// The sculpt's mesh with each triangle's look group (MeshBuildSculptLooks.swift). Cached by its inputs.
    func sculptMesh(warnings: inout [String]) -> MeshBuildSculptMesh? {
        let groups = sculptLookGroups()
        let key = sculptCacheKey(groups: groups.childGroups)
        if let cached = MeshBuildSculptCache.shared.value(for: key) {
            warnings += cached.warnings
            return cached.mesh
        }
        var produced: [String] = []
        let mesh = MeshBuildSculptor(sculpt: self, groups: groups.childGroups, warnings: &produced)?.mesh(warnings: &produced)
        MeshBuildSculptCache.shared.store(key, (mesh, produced))
        warnings += produced
        return mesh
    }

    private func sculptCacheKey(groups: [Int]) -> String {
        "\(sculptResolution)|\(String(describing: noise))|\(size)|\(groups)|"
            + "\(sculptChildren.map { "\($0.position)\($0.rotation.vector)\($0.part.sculptPrimitiveKey)" })"
    }

    /// The fields that shape a part used as a sculpt primitive.
    var sculptPrimitiveKey: String {
        "\(name)|\(shape.rawValue)|\(size)|\(segments)|\(thickness)|\(String(describing: bevel))|\(String(describing: profile))|"
            + "\(reflection)|\(String(describing: blend))|\(String(describing: smooth))|"
            + (needsMeshField ? "\(String(describing: path))|\(String(describing: radius))|\(String(describing: radii))|"
                + "\(String(describing: closed))|\(String(describing: straight))|\(String(describing: sections))|"
                + "\(String(describing: axis))|\(String(describing: deform))|\(String(describing: subdivide))" : "")
    }

    /// Whether the part, as a sculpt child, is a field of its mesh (MeshBuildMeshSDF.swift): sweeps,
    /// lofts and deformed shapes have no exact formula.
    var needsMeshField: Bool {
        switch shape {
        case .group, .sculpt, .plane, .foliage: false
        case .sweep, .loft: true
        default: !(deform ?? []).isEmpty
        }
    }
}

extension MeshBuild {
    /// Gathers each sculpt part's subtree into its `sculptChildren` (see the notes at the top of
    /// MeshBuildSculpt.swift). Run it on an expanded build (`expanded()`); `sources` (the
    /// expansion's) puts mirror / repeat copies right after the part they copy.
    public func gatheringSculpts(sources: [String]? = nil) -> MeshBuildSculpting {
        guard parts.contains(where: { $0.shape == .sculpt }) else { return MeshBuildSculpting(build: attachingFoliageTargets(sources: sources), sculpted: [], sculptOf: [:]) }
        var firstIndex: [String: Int] = [:]
        for (i, part) in parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        // The parent of each part as the importer sees it: missing parents and loops hang from the root.
        func parent(of i: Int) -> Int? {
            guard !parts[i].parent.isEmpty, let p = firstIndex[parts[i].parent], p != i else { return nil }
            var seen: Set<Int> = [i], up: Int? = p
            while let u = up {
                if !seen.insert(u).inserted { return nil }
                let name = parts[u].parent
                up = name.isEmpty ? nil : firstIndex[name]
            }
            return p
        }
        let parents = parts.indices.map(parent(of:))
        // The outermost sculpt above each part.
        func sculpt(of i: Int) -> Int? {
            var found: Int?, up = parents[i]
            while let u = up {
                if parts[u].shape == .sculpt { found = u }
                up = parents[u]
            }
            return found
        }
        // Placement in the sculpt's space: the parent chain below the sculpt.
        var placements: [Int: (Vec3, Quat)] = [:]
        func placement(_ i: Int, sculpt s: Int) -> (Vec3, Quat) {
            if let known = placements[i] { return known }
            let part = parts[i]
            let local = (part.position, Quat(eulerDegrees: part.rotation))
            var result = local
            if let p = parents[i], p != s {
                let (pp, pq) = placement(p, sculpt: s)
                result = (pp + pq * local.0, pq * local.1)
            }
            placements[i] = result
            return result
        }
        // Copies come after the file's parts: order them right after their source.
        var order: [Int] = Array(parts.indices)
        if let sources, sources.count == parts.count {
            let fileIndex = Dictionary(parts.enumerated().map { ($0.element.name, $0.offset) }, uniquingKeysWith: { a, _ in a })
            order.sort { a, b in
                let sa = fileIndex[sources[a]] ?? a, sb = fileIndex[sources[b]] ?? b
                return sa != sb ? sa < sb : a < b
            }
        }
        var out = self
        var sculpted: Set<Int> = []
        var sculptOf: [String: String] = [:]
        for i in order {
            guard let s = sculpt(of: i) else { continue }
            sculpted.insert(i)
            sculptOf[parts[i].name] = parts[s].name
            let (position, rotation) = placement(i, sculpt: s)
            out.parts[s].sculptChildren.append(MeshBuildSculptChild(part: parts[i], position: position, rotation: rotation))
        }
        return MeshBuildSculpting(build: out.attachingFoliageTargets(sources: sources), sculpted: sculpted, sculptOf: sculptOf)
    }

    /// Problems only the whole build shows: animated sculpt children, blend / smooth on parts
    /// outside a sculpt. `sculpting` is `expanded().gatheringSculpts(…)`.
    public func sculptContextWarnings(_ sculpting: MeshBuildSculpting) -> [String] {
        var warnings: [String] = []
        var warned: Set<String> = []
        for (i, part) in sculpting.build.parts.enumerated() where !sculpting.sculpted.contains(i) && warned.insert(part.name).inserted {
            if part.blend != nil || part.smooth != nil {
                warnings.append("part '\(part.name)': blend and smooth only apply to the children of a sculpt part; this one isn't in a sculpt")
            }
        }
        for (i, part) in sculpting.build.parts.enumerated() where sculpting.sculpted.contains(i) && part.shape == .sculpt {
            warnings.append("part '\(part.name)' is a sculpt inside sculpt '\(sculpting.sculptOf[part.name] ?? "")': it is used as a pivot "
                            + "and its children join the outer sculpt")
        }
        for animation in sculpting.build.animations {
            var named: Set<String> = []
            for track in animation.allTracks where named.insert(track.part).inserted {
                guard let sculpt = sculpting.sculptOf[track.part] else { continue }
                warnings.append("animation '\(animation.name)' moves '\(track.part)', a child of sculpt '\(sculpt)': a sculpt is one mesh, "
                                + "so its children can't move on their own; animate '\(sculpt)' instead")
            }
        }
        return warnings
    }

    /// Every sculpt problem of the file (its expansion's sculpts' shape warnings and the context
    /// warnings), each once: what the importer reports about sculpts.
    public func sculptWarnings() -> [String] {
        guard parts.contains(where: { $0.shape == .sculpt || $0.blend != nil || $0.smooth != nil }) else { return [] }
        let expansion = expansion()
        let sculpting = expansion.build.gatheringSculpts(sources: expansion.sources)
        var warnings: [String] = []
        for (i, part) in sculpting.build.parts.enumerated() where part.shape == .sculpt && !sculpting.sculpted.contains(i) {
            var produced: [String] = []
            _ = part.geometry(warnings: &produced)
            warnings += produced.filter { !part.fieldWarnings.contains($0) }.map { "part '\(part.name)': \($0)" }
        }
        warnings += sculptContextWarnings(sculpting)
        var seen: Set<String> = []
        return warnings.filter { seen.insert($0).inserted }
    }
}

// MARK: - Cache

/// Recent sculpt meshes by their inputs (the importer, checks and editor ask for the same ones often).
final class MeshBuildSculptCache: @unchecked Sendable {
    static let shared = MeshBuildSculptCache()
    static let capacity = 24

    private let lock = NSLock()
    private var entries: [String: (mesh: MeshBuildSculptMesh?, warnings: [String])] = [:]
    private var order: [String] = []

    func value(for key: String) -> (mesh: MeshBuildSculptMesh?, warnings: [String])? {
        lock.lock()
        defer { lock.unlock() }
        guard let value = entries[key] else { return nil }
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    func store(_ key: String, _ value: (mesh: MeshBuildSculptMesh?, warnings: [String])) {
        lock.lock()
        defer { lock.unlock() }
        if entries[key] == nil { order.append(key) }
        entries[key] = value
        while order.count > Self.capacity { entries[order.removeFirst()] = nil }
    }

    func removeAll() {
        lock.lock()
        entries = [:]
        order = []
        lock.unlock()
    }
}

// MARK: - Distance field

/// One sculpt child as a signed distance function in the sculpt's space. Evaluated millions of
/// times per mesh, so it is flat scalars (unoptimized builds run scalar math far faster than
/// generic SIMD), built from a descriptive `Kind`.
struct SculptPrimitive: Sendable {
    enum Kind: Sendable {
        /// A box of half extent `half` with edges rounded by `radius`.
        case box(half: Vec3, radius: Float)
        case ellipsoid(radii: Vec3)
        /// The top half of an ellipsoid of `radii` whose center is at y = `base`.
        case dome(radii: Vec3, base: Float)
        /// Round shapes along Y, made oval by scaling x and z by `squash` (≤ 1).
        case cylinder(radius: Float, halfHeight: Float, bevel: Float, squash: Vec2)
        case capsule(radius: Float, halfLine: Float, squash: Vec2)
        case torus(major: Float, minor: Float, squash: Vec2)
        case tube(outer: Float, inner: Float, halfHeight: Float, squash: Vec2)
        /// A solid of revolution: `polygon` in (radius, height), sampled at x and z times `squash`.
        case revolve(polygon: [Vec2], squash: Vec2)
        /// `polygon` in XY, `halfDepth` along Z.
        case prism(polygon: [Vec2], halfDepth: Float)
        /// A convex solid: the most positive of `dot(n, p) - w` over its planes.
        case convex(planes: [Vec4])
        /// A closed triangle mesh (sweeps, lofts, deformed shapes; MeshBuildMeshSDF.swift).
        case mesh(MeshDistanceField)
    }

    private enum Tag: UInt8, Sendable { case box, ellipsoid, sphere, dome, cylinder, capsule, torus, tube, revolve, prism, convex, mesh }

    private let tag: Tag
    // Sculpt space to the primitive's: p = M (q - t), M = diag(reflection) · rotation⁻¹, row major.
    private let tx, ty, tz: Float
    private let m00, m01, m02, m10, m11, m12, m20, m21, m22: Float
    /// Shape numbers, per tag (see `init`).
    private let a, b, c, d: Float
    /// Oval round shapes: x and z multipliers.
    private let sx, sz: Float
    /// Polygon corners (x, y pairs) or planes (nx, ny, nz, w).
    private let numbers: [Float]
    /// A mesh's distance field.
    private let meshField: MeshDistanceField?

    let blend: MeshBuildBlend
    let smooth: Float
    /// The primitive's box in the sculpt's space.
    let lo: Vec3
    let hi: Vec3
    /// The field is at least this times the distance to the shape (approximate fields of ovals
    /// and convex solids underestimate it), so `lo`...`hi` bounds it from below.
    let tightness: Float

    init(kind: Kind, position: Vec3, rotation: Quat, reflection: Vec3, blend: MeshBuildBlend, smooth: Float, lo: Vec3, hi: Vec3,
         tightness: Float) {
        let r = rotation.inverse
        // Columns of the inverse rotation, each row then reflected.
        let ex = r * Vec3(1, 0, 0), ey = r * Vec3(0, 1, 0), ez = r * Vec3(0, 0, 1)
        (m00, m01, m02) = (ex.x * reflection.x, ey.x * reflection.x, ez.x * reflection.x)
        (m10, m11, m12) = (ex.y * reflection.y, ey.y * reflection.y, ez.y * reflection.y)
        (m20, m21, m22) = (ex.z * reflection.z, ey.z * reflection.z, ez.z * reflection.z)
        (tx, ty, tz) = (position.x, position.y, position.z)
        var a: Float = 0, b: Float = 0, c: Float = 0, d: Float = 0, sx: Float = 1, sz: Float = 1
        var numbers: [Float] = []
        var meshField: MeshDistanceField?
        switch kind {
        case .box(let half, let radius):
            tag = .box
            (a, b, c, d) = (half.x - radius, half.y - radius, half.z - radius, radius)
        case .ellipsoid(let radii):
            tag = radii.x == radii.y && radii.y == radii.z ? .sphere : .ellipsoid
            (a, b, c) = (radii.x, radii.y, radii.z)
        case .dome(let radii, let base):
            tag = .dome
            (a, b, c, d) = (radii.x, radii.y, radii.z, base)
        case .cylinder(let radius, let halfHeight, let bevel, let squash):
            tag = .cylinder
            (a, b, c, sx, sz) = (radius, halfHeight, bevel, squash.x, squash.y)
        case .capsule(let radius, let halfLine, let squash):
            tag = .capsule
            (a, b, sx, sz) = (radius, halfLine, squash.x, squash.y)
        case .torus(let major, let minor, let squash):
            tag = .torus
            (a, b, sx, sz) = (major, minor, squash.x, squash.y)
        case .tube(let outer, let inner, let halfHeight, let squash):
            tag = .tube
            (a, b, c, sx, sz) = ((outer + inner) / 2, (outer - inner) / 2, halfHeight, squash.x, squash.y)
        case .revolve(let polygon, let squash):
            tag = .revolve
            (sx, sz) = (squash.x, squash.y)
            numbers = polygon.flatMap { [$0.x, $0.y] }
        case .prism(let polygon, let halfDepth):
            tag = .prism
            a = halfDepth
            numbers = polygon.flatMap { [$0.x, $0.y] }
        case .convex(let planes):
            tag = .convex
            numbers = planes.flatMap { [$0.x, $0.y, $0.z, $0.w] }
        case .mesh(let field):
            tag = .mesh
            meshField = field
        }
        (self.a, self.b, self.c, self.d, self.sx, self.sz, self.numbers) = (a, b, c, d, sx, sz, numbers)
        self.meshField = meshField
        self.blend = blend
        self.smooth = smooth
        self.lo = lo
        self.hi = hi
        self.tightness = tightness
    }

    /// A lower bound of `distance` anywhere in the box `boxLo`...`boxHi`.
    func lowerBound(boxLo: Vec3, boxHi: Vec3) -> Float {
        let gx = max(max(lo.x - boxHi.x, boxLo.x - hi.x), 0)
        let gy = max(max(lo.y - boxHi.y, boxLo.y - hi.y), 0)
        let gz = max(max(lo.z - boxHi.z, boxLo.z - hi.z), 0)
        let outside = (gx * gx + gy * gy + gz * gz).squareRoot() * tightness
        guard let meshField else { return outside }
        // A mesh (a curving tube) fills little of its box: ask its hierarchy, with the box in the mesh's space.
        var localLo = Vec3(repeating: .infinity), localHi = Vec3(repeating: -.infinity)
        for corner in 0..<8 {
            let qx = corner & 1 == 0 ? boxLo.x : boxHi.x, qy = corner & 2 == 0 ? boxLo.y : boxHi.y
            let qz = corner & 4 == 0 ? boxLo.z : boxHi.z
            let dx = qx - tx, dy = qy - ty, dz = qz - tz
            let p = Vec3(m00 * dx + m01 * dy + m02 * dz, m10 * dx + m11 * dy + m12 * dz, m20 * dx + m21 * dy + m22 * dz)
            localLo = pointwiseMin(localLo, p)
            localHi = pointwiseMax(localHi, p)
        }
        return max(outside, meshField.lowerBound(boxLo: localLo, boxHi: localHi))
    }

    func distance(_ q: Vec3) -> Float { distance(q.x, q.y, q.z) }

    /// The signed distance from the sculpt-space point (`qx`, `qy`, `qz`) (negative inside).
    func distance(_ qx: Float, _ qy: Float, _ qz: Float) -> Float {
        let dx = qx - tx, dy = qy - ty, dz = qz - tz
        let x = m00 * dx + m01 * dy + m02 * dz
        let y = m10 * dx + m11 * dy + m12 * dz
        let z = m20 * dx + m21 * dy + m22 * dz
        switch tag {
        case .box:
            let ux = abs(x) - a, uy = abs(y) - b, uz = abs(z) - c
            let ox = max(ux, 0), oy = max(uy, 0), oz = max(uz, 0)
            return (ox * ox + oy * oy + oz * oz).squareRoot() + min(max(ux, max(uy, uz)), 0) - d
        case .sphere:
            return (x * x + y * y + z * z).squareRoot() - a
        case .ellipsoid:
            return Self.ellipsoid(x, y, z, a, b, c)
        case .dome:
            let cy = y - d
            return max(Self.ellipsoid(x, cy, z, a, b, c), -cy)
        case .cylinder:
            let px = x * sx, pz = z * sz
            let wx = (px * px + pz * pz).squareRoot() - a + c, wy = abs(y) - b + c
            let ox = max(wx, 0), oy = max(wy, 0)
            return min(max(wx, wy), 0) + (ox * ox + oy * oy).squareRoot() - c
        case .capsule:
            let px = x * sx, pz = z * sz, py = y - min(max(y, -b), b)
            return (px * px + py * py + pz * pz).squareRoot() - a
        case .torus:
            let px = x * sx, pz = z * sz
            let wx = (px * px + pz * pz).squareRoot() - a
            return (wx * wx + y * y).squareRoot() - b
        case .tube:
            let px = x * sx, pz = z * sz
            let wx = abs((px * px + pz * pz).squareRoot() - a) - b, wy = abs(y) - c
            let ox = max(wx, 0), oy = max(wy, 0)
            return min(max(wx, wy), 0) + (ox * ox + oy * oy).squareRoot()
        case .revolve:
            let px = x * sx, pz = z * sz
            return Self.polygonDistance(numbers, (px * px + pz * pz).squareRoot(), y, skippingAxis: true)
        case .prism:
            let wx = Self.polygonDistance(numbers, x, y), wy = abs(z) - a
            let ox = max(wx, 0), oy = max(wy, 0)
            return min(max(wx, wy), 0) + (ox * ox + oy * oy).squareRoot()
        case .convex:
            var result = -Float.infinity
            var i = 0
            while i + 3 < numbers.count {
                result = max(result, numbers[i] * x + numbers[i + 1] * y + numbers[i + 2] * z - numbers[i + 3])
                i += 4
            }
            return result
        case .mesh:
            return meshField!.distance(x, y, z)
        }
    }

    /// An ellipsoid's approximate distance (exact on its surface, a bound elsewhere).
    @inline(__always) private static func ellipsoid(_ x: Float, _ y: Float, _ z: Float, _ a: Float, _ b: Float, _ c: Float) -> Float {
        let k0 = (x * x / (a * a) + y * y / (b * b) + z * z / (c * c)).squareRoot()
        let k1 = (x * x / (a * a * a * a) + y * y / (b * b * b * b) + z * z / (c * c * c * c)).squareRoot()
        return k1 > 0 ? k0 * (k0 - 1) / k1 : -min(a, min(b, c))
    }

    /// The signed distance to the closed polygon `v` (x, y pairs; negative inside, either winding).
    /// `skippingAxis`: edges on x = 0 (a lathe profile's closing edge along its axis) aren't surface.
    static func polygonDistance(_ v: [Float], _ px: Float, _ py: Float, skippingAxis: Bool = false) -> Float {
        let n = v.count / 2
        guard n >= 2 else { return .greatestFiniteMagnitude }
        var d = Float.greatestFiniteMagnitude
        var sign: Float = 1
        var j = n - 1
        forEachIndex(0..<n) { i in
            let vix = v[2 * i], viy = v[2 * i + 1], vjx = v[2 * j], vjy = v[2 * j + 1]
            let ex = vjx - vix, ey = vjy - viy, wx = px - vix, wy = py - viy
            if !(skippingAxis && vix == 0 && vjx == 0) {
                let t = min(max((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-20), 0), 1)
                let bx = wx - ex * t, by = wy - ey * t
                d = min(d, bx * bx + by * by)
            }
            let c1 = py >= viy, c2 = py < vjy, c3 = ex * wy > ey * wx
            if (c1 && c2 && c3) || (!c1 && !c2 && !c3) { sign = -sign }
            j = i
        }
        return sign * d.squareRoot()
    }
}

/// Builds a sculpt part's mesh (see the notes at the top of this file).
struct MeshBuildSculptor {
    /// Face normals further apart than this (degrees) at a vertex get their own vertex normals.
    static let sharpAngle: Float = 40
    /// Grid cells per coarse block when skipping space far from the surface.
    static let block = 4

    let primitives: [SculptPrimitive]
    /// Each primitive's look group, or -1 when it never owns surface (a subtract or intersect
    /// without a look of its own). See MeshBuildSculptLooks.swift.
    let groups: [Int32]
    /// How many look groups there are (1: one look, no ownership to work out).
    let groupCount: Int
    let resolution: Int
    let noise: MeshBuildNoise?
    let scale: Vec3
    /// The box the surface can be in.
    let lo: Vec3
    let hi: Vec3

    /// Nil (with a warning) when the children make no shape. `groups` is each child's look group
    /// (`MeshBuildPart.sculptLookGroups`; empty: one look).
    init?(sculpt: MeshBuildPart, groups childGroups: [Int] = [], warnings: inout [String]) {
        var primitives: [SculptPrimitive] = []
        var groups: [Int32] = []
        for (i, child) in sculpt.sculptChildren.enumerated() {
            var childWarnings: [String] = []
            if let primitive = Self.primitive(child, warnings: &childWarnings) {
                primitives.append(primitive)
                groups.append(i < childGroups.count ? Int32(childGroups[i]) : primitive.blend == .add ? 0 : -1)
            }
            warnings += childWarnings.map { "sculpt child '\(child.part.name)': \($0)" }
        }
        self.groups = groups
        groupCount = Int(groups.max() ?? 0) + 1
        resolution = sculpt.sculptResolution
        if let noise = sculpt.noise, noise.amount.isFinite, noise.scale.isFinite, noise.scale > 0, noise.amount != 0 {
            self.noise = noise
        } else {
            noise = nil
        }
        scale = Vec3(abs(sculpt.size.x), abs(sculpt.size.y), abs(sculpt.size.z))
        // Only added shapes make surface; smoothing can bulge a union out by up to a quarter of its radius.
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for p in primitives where p.blend == .add {
            lo = pointwiseMin(lo, p.lo - Vec3(repeating: p.smooth / 4))
            hi = pointwiseMax(hi, p.hi + Vec3(repeating: p.smooth / 4))
        }
        guard lo.x <= hi.x, primitives.first?.blend == .add else {
            warnings.append(sculpt.sculptChildren.isEmpty
                ? "a sculpt draws its children: give it child parts (parent: '\(sculpt.name)'); nothing was built"
                : "a sculpt needs an added (blend \"add\") child before any subtract or intersect; nothing was built")
            return nil
        }
        let margin = abs(noise?.amount ?? 0)
        self.lo = lo - Vec3(repeating: margin)
        self.hi = hi + Vec3(repeating: margin)
        self.primitives = primitives
    }

    /// The child as a distance function, nil for groups and shapes without an inside.
    static func primitive(_ child: MeshBuildSculptChild, warnings: inout [String]) -> SculptPrimitive? {
        let part = child.part
        let numbers = [child.position.x, child.position.y, child.position.z, part.size.x, part.size.y, part.size.z] + Array(child.rotation.vector.indices.map { child.rotation.vector[$0] })
        guard numbers.allSatisfy(\.isFinite) else {
            warnings.append("its position, rotation or size has a value that isn't a number; it is left out")
            return nil
        }
        let s = Vec3(abs(part.size.x), abs(part.size.y), abs(part.size.z))
        let h = s / 2
        let m = min(s.x, s.z)
        let squash = Vec2(s.x > 0 ? m / s.x : 1, s.z > 0 ? m / s.z : 1)
        let bevel = part.bevel.map { $0.isFinite ? max($0, 0) : 0 } ?? 0
        var bounds = Bounds(center: .zero, halfExtent: h)
        let kind: SculptPrimitive.Kind
        switch part.shape {
        case .group, .sculpt:
            return nil
        case .plane:
            warnings.append("a plane has no inside, so it can't be part of a sculpt; it is left out (use a thin box)")
            return nil
        case .foliage:
            warnings.append("foliage is leaf cards, not a solid, so it can't be part of a sculpt; it is left out (keep it outside the sculpt)")
            return nil
        case .sweep where part.isRibbon:
            warnings.append("a ribbon is an open strip, not a solid, so it can't be part of a sculpt; it is left out (use a thin loft or box)")
            return nil
        case _ where part.needsMeshField:
            // Sweeps, lofts and deformed shapes: the field of their mesh (deformed, reflected), a
            // little finer around than drawn so the melted surface stays round.
            var dense = part
            dense.segments = max(part.segments, 32)
            var meshWarnings: [String] = []
            let g = dense.geometry(warnings: &meshWarnings)
            warnings += meshWarnings.filter { !part.fieldWarnings.contains($0) }
            guard let g else { return nil }
            guard let field = MeshDistanceField(g) else {
                warnings.append("its mesh has no area; it is left out")
                return nil
            }
            kind = .mesh(field)
            bounds = g.bounds
        case .sweep, .loft:
            return nil
        case .box:
            kind = .box(half: h, radius: min(bevel, min(h.x, min(h.y, h.z))))
        case .sphere:
            kind = .ellipsoid(radii: pointwiseMax(h, Vec3(repeating: 1e-5)))
        case .hemisphere:
            kind = .dome(radii: pointwiseMax(Vec3(h.x, s.y, h.z), Vec3(repeating: 1e-5)), base: -h.y)
        case .cylinder:
            let r = m / 2
            kind = .cylinder(radius: r, halfHeight: h.y, bevel: min(bevel, min(r, h.y)), squash: squash)
        case .cone:
            kind = .revolve(polygon: [Vec2(0, -h.y), Vec2(m / 2, -h.y), Vec2(0, h.y)], squash: squash)
        case .capsule:
            let r = min(m / 2, h.y)
            kind = .capsule(radius: r, halfLine: h.y - r, squash: squash)
        case .torus:
            let minor = min(s.y, m / 2) / 2
            kind = .torus(major: max(m / 2 - minor, 0), minor: minor, squash: squash)
            bounds = Bounds(center: .zero, halfExtent: Vec3(h.x, minor, h.z))
        case .tube:
            kind = .tube(outer: m / 2, inner: max(m / 2 - part.thickness, 0), halfHeight: h.y, squash: squash)
        case .wedge, .pyramid:
            guard let g = part.geometry() else { return nil }
            var planes: [Vec4] = []
            for t in stride(from: 0, to: g.indices.count - 2, by: 3) {
                let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
                let c = g.vertices[Int(g.indices[t + 2])].position
                let n = cross(b - a, c - a)
                guard vlength(n) > 1e-9 else { continue }
                let u = normalize(n)
                let plane = Vec4(u.x, u.y, u.z, vdot(u, a))
                if !planes.contains(where: { (($0 - plane) * ($0 - plane)).sum() < 1e-8 }) { planes.append(plane) }
            }
            kind = .convex(planes: planes)
        case .lathe:
            var unscaled = part
            unscaled.size = Vec3(1, 1, 1)
            unscaled.reflection = Vec3(1, 1, 1)
            guard let g = unscaled.geometry(warnings: &warnings) else { return nil }
            // The geometry's checks passed: the cleaned profile, closed along the axis, at its real size.
            var ignored: [String] = []
            var points = MeshGeometry.cleanProfile((part.profile ?? []).map { Vec2(max($0.x, 0), $0.y) }, shape: "lathe", warnings: &ignored)
            if let first = points.first, first.x > 0 { points.insert(Vec2(0, first.y), at: 0) }
            if let last = points.last, last.x > 0 { points.append(Vec2(0, last.y)) }
            kind = .revolve(polygon: points.map { Vec2($0.x * m, $0.y * s.y) }, squash: squash)
            let b = g.bounds
            bounds = Bounds(center: b.center * s, halfExtent: b.halfExtent * s)
        case .extrude:
            var check = part
            check.reflection = Vec3(1, 1, 1)
            guard let g = check.geometry(warnings: &warnings) else { return nil }
            var ignored: [String] = []
            var points = MeshGeometry.cleanProfile((part.profile ?? []).map { $0 * Vec2(s.x, s.y) }, shape: "extrude", warnings: &ignored)
            if points.count > 1, vlength(points[0] - points[points.count - 1]) <= 1e-6 { points.removeLast() }
            kind = .prism(polygon: points, halfDepth: h.z)
            bounds = g.bounds
        }
        // The primitive's box in the sculpt's space. A mesh is already reflected.
        let reflection = part.needsMeshField ? Vec3(1, 1, 1) : part.reflection
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for corner in 0..<8 {
            let sign = Vec3(corner & 1 == 0 ? -1 : 1, corner & 2 == 0 ? -1 : 1, corner & 4 == 0 ? -1 : 1)
            let local = (bounds.center + bounds.halfExtent * sign) * reflection
            let p = child.position + child.rotation * local
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        let smooth = part.smooth.map { $0.isFinite ? max($0, 0) : 0 } ?? 0
        let tightness: Float = switch kind {
        case .box, .prism, .mesh: 1
        case .ellipsoid(let r), .dome(let r, _): min(r.x, min(r.y, r.z)) / max(r.x, max(r.y, r.z))
        case .convex: 0.25
        default: min(squash.x, squash.y)
        }
        return SculptPrimitive(kind: kind, position: child.position, rotation: child.rotation, reflection: reflection,
                               blend: part.blend ?? .add, smooth: smooth, lo: lo, hi: hi, tightness: max(tightness, 0.05))
    }

    // MARK: Field

    /// The combined signed distance at `p` (sculpt space, before `scale`).
    func field(_ p: Vec3) -> Float { field(p.x, p.y, p.z, active: nil) }
    func field(_ p: Vec3, active: [Int32]?) -> Float { field(p.x, p.y, p.z, active: active) }

    /// The field from only the `active` primitives (indices; nil: all), the rest being too far to matter.
    func field(_ x: Float, _ y: Float, _ z: Float, active: [Int32]?) -> Float {
        var d = Float.greatestFiniteMagnitude
        var empty = true
        // Noise roughens added and subtracted shapes alike; intersected ones trim cleanly.
        let bump = noise.map { $0.amount * Self.fbm(Vec3(x, y, z) / $0.scale, seed: $0.seed) } ?? 0
        func combine(_ primitive: SculptPrimitive) {
            let b = primitive.distance(x, y, z)
            switch primitive.blend {
            case .add:
                d = empty ? b + bump : Self.union(d, b + bump, primitive.smooth)
                empty = false
            case .subtract:
                if !empty { d = Self.subtract(d, b - bump, primitive.smooth) }
            case .intersect:
                if !empty { d = Self.intersect(d, b, primitive.smooth) }
            }
        }
        // Counted loops, and no closure: a closure here would copy this whole struct (its arrays
        // retained) on every one of the millions of calls a sculpt makes (ForEachIndex.swift).
        var k = 0
        if let active {
            while k < active.count {
                combine(primitives[Int(active[k])])
                k += 1
            }
        } else {
            while k < primitives.count {
                combine(primitives[k])
                k += 1
            }
        }
        return d
    }

    /// Smooth minimum (polynomial, radius `k`): `min(a, b)` when `k` is 0.
    @inline(__always) static func union(_ a: Float, _ b: Float, _ k: Float) -> Float {
        guard k > 0 else { return min(a, b) }
        let h = min(max(0.5 + 0.5 * (b - a) / k, 0), 1)
        return b + (a - b) * h - k * h * (1 - h)
    }

    /// `a` with `b` cut out, smoothly.
    @inline(__always) static func subtract(_ a: Float, _ b: Float, _ k: Float) -> Float {
        guard k > 0 else { return max(a, -b) }
        let h = min(max(0.5 - 0.5 * (b + a) / k, 0), 1)
        return a + (-b - a) * h + k * h * (1 - h)
    }

    /// Where both `a` and `b` are, smoothly.
    @inline(__always) static func intersect(_ a: Float, _ b: Float, _ k: Float) -> Float {
        guard k > 0 else { return max(a, b) }
        let h = min(max(0.5 - 0.5 * (b - a) / k, 0), 1)
        return b + (a - b) * h + k * h * (1 - h)
    }

    /// Fractal gradient noise in about -1...1 (three octaves).
    static func fbm(_ p: Vec3, seed: Int) -> Float {
        var sum: Float = 0, amplitude: Float = 0.6, q = p
        forEachIndex(0..<3) { octave in
            sum += amplitude * gradientNoise(q, seed: seed &+ octave &* 1013)
            q = q * 2.03 + Vec3(17.1, 31.7, 7.3)
            amplitude *= 0.5
        }
        return sum
    }

    /// Perlin-style gradient noise in about -1...1.
    static func gradientNoise(_ p: Vec3, seed: Int) -> Float {
        let i = Vec3(floorf(p.x), floorf(p.y), floorf(p.z))
        let f = p - i
        let u = f * f * f * (f * (f * 6 - 15) + 10)
        let ix = Int32(truncatingIfNeeded: Int(i.x)), iy = Int32(truncatingIfNeeded: Int(i.y)), iz = Int32(truncatingIfNeeded: Int(i.z))
        func corner(_ dx: Int32, _ dy: Int32, _ dz: Int32) -> Float {
            var h = UInt32(bitPattern: (ix &+ dx) &* 73_856_093 ^ (iy &+ dy) &* 19_349_663 ^ (iz &+ dz) &* 83_492_791)
            h ^= UInt32(truncatingIfNeeded: seed) &* 2_654_435_761  // same low 32 bits as before; Int is 32-bit on wasm32
            h = (h ^ (h >> 16)) &* 0x45d9f3b
            h ^= h >> 16
            let g = Vec3(Float(h & 0xFF) / 127.5 - 1, Float((h >> 8) & 0xFF) / 127.5 - 1, Float((h >> 16) & 0xFF) / 127.5 - 1)
            return vdot(g, f - Vec3(Float(dx), Float(dy), Float(dz)))
        }
        func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
        let x00 = mix(corner(0, 0, 0), corner(1, 0, 0), u.x), x10 = mix(corner(0, 1, 0), corner(1, 1, 0), u.x)
        let x01 = mix(corner(0, 0, 1), corner(1, 0, 1), u.x), x11 = mix(corner(0, 1, 1), corner(1, 1, 1), u.x)
        return mix(mix(x00, x10, u.y), mix(x01, x11, u.y), u.z) * 1.4
    }

    /// The field's gradient direction at `p` (tetrahedral differences).
    func normal(at p: Vec3, step: Float, active: [Int32]? = nil) -> Vec3 {
        let k0 = Vec3(1, -1, -1), k1 = Vec3(-1, -1, 1), k2 = Vec3(-1, 1, -1), k3 = Vec3(1, 1, 1)
        let g = k0 * field(p + k0 * step, active: active) + k1 * field(p + k1 * step, active: active)
            + k2 * field(p + k2 * step, active: active) + k3 * field(p + k3 * step, active: active)
        let len = vlength(g)
        return len > 0 ? g / len : Vec3(0, 1, 0)
    }

    // MARK: Meshing

    /// Samples the field and dual-contours it.
    func mesh(warnings: inout [String]) -> MeshBuildSculptMesh? {
        let extent = hi - lo
        let cell = max(max(extent.x, max(extent.y, extent.z)) / Float(resolution), 1e-5)
        let origin = lo - Vec3(repeating: cell * 2)
        // Points per axis: the box plus two cells of outside on each side.
        let n = SIMD3<Int>(Int((extent.x / cell).rounded(.up)) + 5, Int((extent.y / cell).rounded(.up)) + 5,
                           Int((extent.z / cell).rounded(.up)) + 5)
        let (values, active) = sample(origin: origin, cell: cell, n: n)
        guard var surface = contour(values, active: active, origin: origin, cell: cell, n: n, warnings: &warnings) else { return nil }
        // Several looks: each triangle's owner, triangles cut along the boundaries (MeshBuildSculptLooks.swift).
        var owners: [Int32] = []
        var weights: [VertexPaint]?
        if groupCount > 1 {
            let split = splitByOwner(&surface, active: active, origin: origin, cell: cell)
            owners = split.owners
            // Blending across the boundaries (MeshBuildSculptBlend.swift).
            weights = blendWeights(surface, split)
        }
        guard let geometry = assemble(positions: surface.positions, normals: surface.normals, triangles: surface.triangles,
                                      groups: owners, weights: weights) else { return nil }
        return MeshBuildSculptMesh(geometry: geometry, triangleGroups: owners.isEmpty ? [] : owners.map { UInt16($0) },
                                   groupCount: groupCount)
    }

    /// A contoured surface before its final vertices: positions and field normals in the
    /// sculpt's space, triangles indexing them.
    struct Surface {
        var positions: [Vec3]
        var normals: [Vec3]
        var triangles: [SIMD3<Int32>]
    }

    /// The primitives that can change the field near the surface in each coarse block.
    struct ActiveLists {
        var lists: [[Int32]?]
        var blocks: SIMD3<Int>

        /// The list for the block holding grid cell or point (`x`, `y`, `z`); nil: use every primitive.
        func list(_ x: Int, _ y: Int, _ z: Int) -> [Int32]? {
            let b = MeshBuildSculptor.block
            return lists[(min(z / b, blocks.z - 1) * blocks.y + min(y / b, blocks.y - 1)) * blocks.x + min(x / b, blocks.x - 1)]
        }
    }

    /// The field at every grid point. Coarse blocks whose center is far enough from the surface
    /// that none of their points can cross it are filled with that distance instead; near the
    /// surface, primitives too far from a block to change it there are skipped.
    func sample(origin: Vec3, cell: Float, n: SIMD3<Int>) -> ([Float], ActiveLists) {
        let b = Self.block
        let blocks = SIMD3<Int>((n.x - 1 + b - 1) / b, (n.y - 1 + b - 1) / b, (n.z - 1 + b - 1) / b)
        let blockCount = blocks.x * blocks.y * blocks.z
        // The field changes at most about 1 m per m (a little more for ellipsoids and noise): leave room.
        let reach = Float(b) * cell * 0.5 * Float(3).squareRoot() * 1.2 + 2 * abs(noise?.amount ?? 0) + cell
        // Within this of the surface the field must be exact; a primitive whose lower bound over a
        // block clears it by its smoothing radius can't change the field there (or only where it is
        // far outside, keeping its sign).
        let band = 3 * cell
        var coarse = [Float](repeating: 0, count: blockCount)
        var near = [Bool](repeating: false, count: blockCount)
        var lists = [[Int32]?](repeating: nil, count: blockCount)
        coarse.withUnsafeMutableBufferPointer { coarseBuffer in
            near.withUnsafeMutableBufferPointer { nearBuffer in
                lists.withUnsafeMutableBufferPointer { listBuffer in
                    let coarsePointer = coarseBuffer, nearPointer = nearBuffer, listPointer = listBuffer
                    concurrentPerform(iterations: blocks.z) { bz in
                        for by in 0..<blocks.y {
                            for bx in 0..<blocks.x {
                                let corner = origin + Vec3(Float(bx * b), Float(by * b), Float(bz * b)) * cell
                                let center = corner + Vec3(repeating: Float(b) / 2 * cell)
                                let d = field(center)
                                let index = (bz * blocks.y + by) * blocks.x + bx
                                coarsePointer[index] = d
                                nearPointer[index] = abs(d) <= reach
                                guard abs(d) <= reach else { continue }
                                let boxLo = corner - Vec3(repeating: cell), boxHi = corner + Vec3(repeating: Float(b + 1) * cell)
                                var list: [Int32] = []
                                for (i, primitive) in primitives.enumerated() {
                                    let k = primitive.smooth
                                    if primitive.blend == .intersect
                                        || primitive.lowerBound(boxLo: boxLo, boxHi: boxHi) <= max(band, k / 4 + cell) + k {
                                        list.append(Int32(i))
                                    }
                                }
                                listPointer[index] = list
                            }
                        }
                    }
                }
            }
        }
        let active = ActiveLists(lists: lists, blocks: blocks)
        var values = [Float](repeating: 0, count: n.x * n.y * n.z)
        let ox = origin.x, oy = origin.y, oz = origin.z
        values.withUnsafeMutableBufferPointer { buffer in
            let pointer = buffer
            concurrentPerform(iterations: n.z) { z in
                let bz0 = min(z / b, blocks.z - 1), bz1 = z % b == 0 && z > 0 ? z / b - 1 : bz0
                // Counted loops (forEachIndex): this runs per grid point, and debug builds' range iterators are slow.
                forEachIndex(0..<n.y) { y in
                    let by0 = min(y / b, blocks.y - 1), by1 = y % b == 0 && y > 0 ? y / b - 1 : by0
                    forEachIndex(0..<n.x) { x in
                        let bx0 = min(x / b, blocks.x - 1), bx1 = x % b == 0 && x > 0 ? x / b - 1 : bx0
                        // The point is near the surface if any block it belongs to is.
                        var isNear = false
                        forEachIndex(bz1...bz0) { bz in
                            forEachIndex(by1...by0) { by in
                                forEachIndex(bx1...bx0) { bx in
                                    if near[(bz * blocks.y + by) * blocks.x + bx] { isNear = true }
                                }
                            }
                        }
                        let index = (z * n.y + y) * n.x + x
                        pointer[index] = isNear ? field(ox + Float(x) * cell, oy + Float(y) * cell, oz + Float(z) * cell, active: active.list(x, y, z))
                                                : coarse[(bz0 * blocks.y + by0) * blocks.x + bx0]
                    }
                }
            }
        }
        return (values, active)
    }

    /// Dual contouring on the sampled grid: a vertex per cell the surface crosses (where the
    /// crossing points' tangent planes best meet, kept inside the cell), a quad per crossed edge.
    func contour(_ values: [Float], active: ActiveLists, origin: Vec3, cell: Float, n: SIMD3<Int>, warnings: inout [String]) -> Surface? {
        let nx = n.x, ny = n.y, nz = n.z
        let cx = nx - 1, cy = ny - 1
        let steps = [1, nx, nx * ny]
        // Every crossed grid edge (start point, axis), found slice by slice in parallel. The grid's
        // outer layer is outside, so no crossing touches its border.
        var slices = [[SIMD2<Int32>]](repeating: [], count: nz)
        values.withUnsafeBufferPointer { v in
            slices.withUnsafeMutableBufferPointer { sliceBuffer in
                let slicePointer = sliceBuffer
                concurrentPerform(iterations: nz - 2) { k in
                    let z = k + 1
                    var found: [SIMD2<Int32>] = []
                    forEachIndex(1..<ny - 1) { y in
                        var i = (z * ny + y) * nx + 1
                        forEachIndex(1..<nx - 1) { _ in
                            let inside = v[i] < 0
                            if inside != (v[i + 1] < 0) { found.append(SIMD2(Int32(i), 0)) }
                            if inside != (v[i + nx] < 0) { found.append(SIMD2(Int32(i), 1)) }
                            if inside != (v[i + nx * ny] < 0) { found.append(SIMD2(Int32(i), 2)) }
                            i += 1
                        }
                    }
                    slicePointer[z] = found
                }
            }
        }
        let crossings = slices.flatMap { $0 }
        guard !crossings.isEmpty else {
            warnings.append("the sculpt's children leave nothing (everything was subtracted or nothing overlaps an intersect); nothing was built")
            return nil
        }
        // The cells around each crossed edge (as cell origins: the edge's start minus 0 or 1 on the
        // two other axes), in the order a quad lists them so that it faces along +axis.
        let around: [[(Int, Int, Int)]] = [
            [(0, -1, -1), (0, 0, -1), (0, 0, 0), (0, -1, 0)],   // x: y, then z
            [(-1, 0, -1), (-1, 0, 0), (0, 0, 0), (0, 0, -1)],   // y: z, then x
            [(-1, -1, 0), (0, -1, 0), (0, 0, 0), (-1, 0, 0)],   // z: x, then y
        ]
        @inline(__always) func cellID(_ i: Int, _ offset: (Int, Int, Int)) -> Int {
            let x = i % nx + offset.0, y = i / nx % ny + offset.1, z = i / (nx * ny) + offset.2
            return (z * cy + y) * cx + x
        }
        // The cells holding a vertex: those next to a crossed edge.
        var cellVertex = [Int32: Int32]()
        cellVertex.reserveCapacity(crossings.count)
        var surfaceCells: [Int] = []
        surfaceCells.reserveCapacity(crossings.count)
        var crossingOf = [Int: Int32]()  // point * 3 + axis → crossing
        crossingOf.reserveCapacity(crossings.count)
        for (e, crossing) in crossings.enumerated() {
            let i = Int(crossing.x), axis = Int(crossing.y)
            crossingOf[i * 3 + axis] = Int32(e)
            for offset in around[axis] {
                let id = cellID(i, offset)
                if cellVertex[Int32(id)] == nil {
                    cellVertex[Int32(id)] = Int32(surfaceCells.count)
                    surfaceCells.append(id)
                }
            }
        }

        // Where the surface crosses each edge, and the field's normal there.
        var crossingPoints = [Vec3](repeating: .zero, count: crossings.count)
        var crossingNormals = [Vec3](repeating: .zero, count: crossings.count)
        let chunk = 64
        crossingPoints.withUnsafeMutableBufferPointer { pointBuffer in
            crossingNormals.withUnsafeMutableBufferPointer { normalBuffer in
                let pointPointer = pointBuffer, normalPointer = normalBuffer
                concurrentPerform(iterations: (crossings.count + chunk - 1) / chunk) { c in
                    for e in (c * chunk)..<min((c + 1) * chunk, crossings.count) {
                        let i = Int(crossings[e].x), axis = Int(crossings[e].y)
                        let x = i % nx, y = i / nx % ny, z = i / (nx * ny)
                        let f0 = values[i], f1 = values[i + steps[axis]]
                        let t = f0 / (f0 - f1)
                        let p = Vec3(origin.x + (Float(x) + (axis == 0 ? t : 0)) * cell, origin.y + (Float(y) + (axis == 1 ? t : 0)) * cell,
                                     origin.z + (Float(z) + (axis == 2 ? t : 0)) * cell)
                        pointPointer[e] = p
                        normalPointer[e] = normal(at: p, step: cell * 0.1, active: active.list(x, y, z))
                    }
                }
            }
        }
        // Vertex positions (where the crossings' tangent planes meet) and normals, in parallel.
        var positions = [Vec3](repeating: .zero, count: surfaceCells.count)
        var normals = [Vec3](repeating: .zero, count: surfaceCells.count)
        // The cell's 12 edges as (start corner, axis).
        let edges: [(Int, Int)] = [(0, 0), (2, 0), (4, 0), (6, 0), (0, 1), (1, 1), (4, 1), (5, 1), (0, 2), (1, 2), (2, 2), (3, 2)]
        positions.withUnsafeMutableBufferPointer { positionBuffer in
            normals.withUnsafeMutableBufferPointer { normalBuffer in
                let positionPointer = positionBuffer, normalPointer = normalBuffer
                concurrentPerform(iterations: (surfaceCells.count + chunk - 1) / chunk) { c in
                    var points: [Vec3] = [], planeNormals: [Vec3] = []
                    points.reserveCapacity(12)
                    planeNormals.reserveCapacity(12)
                    for v in (c * chunk)..<min((c + 1) * chunk, surfaceCells.count) {
                        let id = surfaceCells[v]
                        let x = id % cx, y = id / cx % cy, z = id / (cx * cy)
                        let base = Vec3(origin.x + Float(x) * cell, origin.y + Float(y) * cell, origin.z + Float(z) * cell)
                        points.removeAll(keepingCapacity: true)
                        planeNormals.removeAll(keepingCapacity: true)
                        for (corner, axis) in edges {
                            let start = ((z + (corner >> 2 & 1)) * ny + y + (corner >> 1 & 1)) * nx + x + (corner & 1)
                            guard let e = crossingOf[start * 3 + axis] else { continue }
                            points.append(crossingPoints[Int(e)])
                            planeNormals.append(crossingNormals[Int(e)])
                        }
                        var p = Self.solveQEF(points: points, normals: planeNormals, cellMin: base, cellSize: cell)
                        let list = active.list(x, y, z)
                        let n = normal(at: p, step: cell * 0.25, active: list)
                        // One Newton step onto the surface (where the planes' best meeting point missed it a little).
                        let f = field(p, active: list)
                        if abs(f) < cell * 0.5 { p -= n * f }
                        positionPointer[v] = p
                        normalPointer[v] = n
                    }
                }
            }
        }

        // A quad around every crossed edge, wound to face from inside to outside, split along the
        // diagonal that leaves its two triangles flattest (so creases stay put).
        var triangles: [SIMD3<Int32>] = []
        triangles.reserveCapacity(crossings.count * 2)
        for crossing in crossings {
            let i = Int(crossing.x), axis = Int(crossing.y)
            var q = around[axis].map { cellVertex[Int32(cellID(i, $0))]! }
            if !(values[i] < 0) { q = [q[0], q[3], q[2], q[1]] }  // inside at the far end: it faces -axis
            let a = positions[Int(q[0])], b = positions[Int(q[1])], c = positions[Int(q[2])], d = positions[Int(q[3])]
            let n1 = cross(b - a, c - a), n2 = cross(c - a, d - a), m1 = cross(b - a, d - a), m2 = cross(c - b, d - b)
            func agreement(_ u: Vec3, _ v: Vec3) -> Float {
                let lu = vlength(u), lv = vlength(v)
                return lu > 0 && lv > 0 ? vdot(u, v) / (lu * lv) : -1
            }
            if agreement(n1, n2) >= agreement(m1, m2) {
                triangles.append(SIMD3(q[0], q[1], q[2]))
                triangles.append(SIMD3(q[0], q[2], q[3]))
            } else {
                triangles.append(SIMD3(q[0], q[1], q[3]))
                triangles.append(SIMD3(q[1], q[2], q[3]))
            }
        }
        return Surface(positions: positions, normals: normals, triangles: triangles)
    }

    /// The point minimizing the squared distances to the planes (`points`, `normals`), measured
    /// from their mass point with small directions dropped, clamped into the cell.
    static func solveQEF(points: [Vec3], normals: [Vec3], cellMin: Vec3, cellSize: Float) -> Vec3 {
        guard !points.isEmpty else { return cellMin + Vec3(repeating: cellSize / 2) }
        let mass = points.reduce(Vec3.zero, +) / Float(points.count)
        // AᵀA (symmetric, row-major) and Aᵀb about the mass point.
        var ata = [Float](repeating: 0, count: 9), atb = Vec3.zero
        for (p, n) in zip(points, normals) {
            for r in 0..<3 { for c in 0..<3 { ata[r * 3 + c] += n[r] * n[c] } }
            atb += n * vdot(n, p - mass)
        }
        let (values, vectors) = symmetricEigen(ata)
        let largest = max(values[0], max(values[1], values[2]))
        var x = Vec3.zero
        for k in 0..<3 where values[k] > largest * 0.08 && values[k] > 1e-8 {
            let v = vectors[k]
            x += v * (vdot(v, atb) / values[k])
        }
        let lo = cellMin - Vec3(repeating: cellSize * 0.02), hi = cellMin + Vec3(repeating: cellSize * 1.02)
        return pointwiseMin(pointwiseMax(mass + x, lo), hi)
    }

    /// Eigenvalues and unit eigenvectors of a symmetric 3x3 matrix (row-major), by Jacobi rotations.
    static func symmetricEigen(_ m: [Float]) -> ([Float], [Vec3]) {
        var a = m
        var v: [Float] = [1, 0, 0, 0, 1, 0, 0, 0, 1]  // columns are the eigenvectors
        for _ in 0..<10 {
            var off: Float = 0
            for (p, q) in [(0, 1), (0, 2), (1, 2)] { off += abs(a[p * 3 + q]) }
            if off < 1e-10 { break }
            for (p, q) in [(0, 1), (0, 2), (1, 2)] {
                let apq = a[p * 3 + q]
                guard abs(apq) > 1e-12 else { continue }
                let theta = (a[q * 3 + q] - a[p * 3 + p]) / (2 * apq)
                let t: Float = (theta >= 0 ? 1 : -1) / (abs(theta) + (theta * theta + 1).squareRoot())
                let c = 1 / (t * t + 1).squareRoot(), s = t * c
                // A ← JᵀAJ with J the rotation in the (p, q) plane: columns, then rows.
                for k in 0..<3 {
                    let akp = a[k * 3 + p], akq = a[k * 3 + q]
                    a[k * 3 + p] = c * akp - s * akq
                    a[k * 3 + q] = s * akp + c * akq
                }
                for k in 0..<3 {
                    let apk = a[p * 3 + k], aqk = a[q * 3 + k]
                    a[p * 3 + k] = c * apk - s * aqk
                    a[q * 3 + k] = s * apk + c * aqk
                }
                for k in 0..<3 {
                    let vkp = v[k * 3 + p], vkq = v[k * 3 + q]
                    v[k * 3 + p] = c * vkp - s * vkq
                    v[k * 3 + q] = s * vkp + c * vkq
                }
            }
        }
        return ([a[0], a[4], a[8]], (0..<3).map { k in Vec3(v[k], v[3 + k], v[6 + k]) })
    }


    /// The final mesh: scaled by the sculpt's size, normals split at sharp creases, box-projected
    /// UVs, and vertices split where the triangles' look `groups` (one per triangle, or empty) change.
    /// `weights` (one per position, or nil) become the vertices' paint.
    func assemble(positions rawPositions: [Vec3], normals rawNormals: [Vec3], triangles: [SIMD3<Int32>], groups: [Int32] = [],
                  weights: [VertexPaint]? = nil) -> MeshGeometry? {
        guard !triangles.isEmpty else { return nil }
        let inverseScale = Vec3(scale.x > 0 ? 1 / scale.x : 0, scale.y > 0 ? 1 / scale.y : 0, scale.z > 0 ? 1 / scale.z : 0)
        let positions = rawPositions.map { $0 * scale }
        let normals = rawNormals.map { n -> Vec3 in
            let m = n * inverseScale
            let l = vlength(m)
            return l > 0 ? m / l : n
        }
        // Face normals (area weighted) and each vertex's triangles.
        var faceNormals: [Vec3] = []
        faceNormals.reserveCapacity(triangles.count)
        var incidentCount = [Int](repeating: 0, count: positions.count + 1)
        for t in triangles {
            faceNormals.append(cross(positions[Int(t.y)] - positions[Int(t.x)], positions[Int(t.z)] - positions[Int(t.x)]))
            for k in 0..<3 { incidentCount[Int(t[k]) + 1] += 1 }
        }
        for i in 1..<incidentCount.count { incidentCount[i] += incidentCount[i - 1] }
        var fill = incidentCount
        var incident = [Int](repeating: 0, count: triangles.count * 3)
        for (ti, t) in triangles.enumerated() {
            for k in 0..<3 {
                incident[fill[Int(t[k])]] = ti * 3 + k
                fill[Int(t[k])] += 1
            }
        }
        // Each triangle corner's normal: the field's at smooth vertices, else its crease side's average.
        let cosSharp = cosf(Self.sharpAngle * .pi / 180)
        var cornerNormal = [Vec3](repeating: .zero, count: triangles.count * 3)
        var cornerGroup = [Int32](repeating: 0, count: triangles.count * 3)
        for v in positions.indices {
            let corners = incident[incidentCount[v]..<incidentCount[v + 1]]
            let unit = corners.map { c -> Vec3 in
                let n = faceNormals[c / 3]
                let l = vlength(n)
                return l > 0 ? n / l : normals[v]
            }
            if unit.allSatisfy({ vdot($0, normals[v]) >= cosSharp }) {
                for c in corners { cornerNormal[c] = normals[v] }
                continue
            }
            // Group the corners by the direction their faces point.
            var seeds: [Vec3] = [], sums: [Vec3] = []
            var groupOf: [Int] = []
            for (k, c) in corners.enumerated() {
                if let g = seeds.firstIndex(where: { vdot($0, unit[k]) >= cosSharp }) {
                    groupOf.append(g)
                    sums[g] += faceNormals[c / 3]
                } else {
                    groupOf.append(seeds.count)
                    seeds.append(unit[k])
                    sums.append(faceNormals[c / 3])
                }
            }
            for (k, c) in corners.enumerated() {
                let s = sums[groupOf[k]]
                let l = vlength(s)
                cornerNormal[c] = l > 0 ? s / l : normals[v]
                cornerGroup[c] = Int32(groupOf[k])
            }
        }
        // Vertices: one per (grid vertex, crease side, projection face), with box-projected UVs in meters.
        var geometry = MeshGeometry(vertices: [], indices: [])
        if weights != nil { geometry.paint = [] }
        geometry.vertices.reserveCapacity(positions.count * 3 / 2)
        geometry.indices.reserveCapacity(triangles.count * 3)
        var made: [Int: UInt32] = [:]
        for (ti, t) in triangles.enumerated() {
            let f = faceNormals[ti]
            let a = vabs(f)
            let face = a.x >= a.y && a.x >= a.z ? (f.x > 0 ? 0 : 1) : a.y >= a.z ? (f.y > 0 ? 2 : 3) : (f.z > 0 ? 4 : 5)
            for k in 0..<3 {
                let v = Int(t[k]), c = ti * 3 + k
                let owner = groups.isEmpty ? 0 : Int(groups[ti])
                let key = ((v * 64 + min(Int(cornerGroup[c]), 63)) * 6 + face) * groupCount + owner
                if let existing = made[key] {
                    geometry.indices.append(existing)
                    continue
                }
                let p = positions[v]
                let uv: Vec2 = switch face {
                case 0: Vec2(-p.z, -p.y)
                case 1: Vec2(p.z, -p.y)
                case 2: Vec2(p.x, p.z)
                case 3: Vec2(p.x, -p.z)
                case 4: Vec2(p.x, -p.y)
                default: Vec2(-p.x, -p.y)
                }
                let index = UInt32(geometry.vertices.count)
                geometry.vertices.append(MeshVertex(position: p, normal: cornerNormal[c], uv: uv))
                if let weights { geometry.paint!.append(weights[v]) }
                made[key] = index
                geometry.indices.append(index)
            }
        }
        return geometry
    }
}

@inline(__always) private func vdot(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
@inline(__always) private func vdot(_ a: Vec3, _ b: Vec3) -> Float { a.x * b.x + a.y * b.y + a.z * b.z }
@inline(__always) private func vlengthSquared(_ v: Vec2) -> Float { vdot(v, v) }
@inline(__always) private func vlength(_ v: Vec2) -> Float { vdot(v, v).squareRoot() }
@inline(__always) private func vlength(_ v: Vec3) -> Float { vdot(v, v).squareRoot() }
@inline(__always) private func vabs(_ v: Vec3) -> Vec3 { Vec3(abs(v.x), abs(v.y), abs(v.z)) }
