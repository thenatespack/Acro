import Foundation

/// A tube (or flat ribbon) along a path, for power cables, ropes, neon tubes and pipes. The path
/// is `points` in the entity's local space, optionally bracketed by two entities (`start`, `end`),
/// smoothed with a Catmull-Rom spline and sagged under gravity (local -Y, so keep the entity
/// unrotated for a cable that hangs down). `SceneRenderer` builds the mesh from these fields,
/// rebuilds it only when its inputs change (including the endpoint entities' positions) and draws
/// it like a `MeshRenderer` (shadows, culling, lighting, transparency, emissive materials).
///
/// Path: with both `start` and `end` set, it is the start entity's position, then `points` (as
/// intermediate control points), then the end entity's position, all in this entity's local space.
/// Otherwise it is just `points`. Fewer than two points draw nothing.
public struct LineRenderer: Component, Codable, Equatable, Sendable {
    public static let componentName = "LineRenderer"
    public static var fieldHints: [String: FieldHints] {
        ["width": FieldHints(range: 0.001...2, step: 0.005, tooltip: "Tube diameter, or ribbon width, in local units"),
         "sag": FieldHints(range: 0...50, step: 0.05, tooltip: "How far the middle of each span hangs below its ends (local -Y)"),
         "segments": FieldHints(range: 1...128, step: 1, tooltip: "Samples per span between two points"),
         "sides": FieldHints(range: 3...32, step: 1, tooltip: "Tube cross-section corners"),
         "tint": FieldHints(color: true),
         "start": FieldHints(tooltip: "With end: the path begins at this entity's position"),
         "end": FieldHints(tooltip: "With start: the path ends at this entity's position")]
    }

    /// How the sagging span hangs.
    public enum Curve: String, Codable, Equatable, Sendable, CaseIterable {
        /// A parabola (cheap, a good look for short spans).
        case parabola
        /// A hyperbolic cosine: the shape of a real hanging cable.
        case catenary
    }

    /// The cross-section.
    public enum Style: String, Codable, Equatable, Sendable, CaseIterable {
        /// A round tube of `sides` corners.
        case tube
        /// A flat strip `width` wide, lying across the path and local up, drawn on both faces.
        case ribbon
    }

    /// Control points in local space.
    public var points: [Vec3]
    public var start: EntityRef
    public var end: EntityRef
    /// Drop of each span's middle below its ends, in local units (0: straight).
    public var sag: Float
    public var curve: Curve
    /// Round the path through the points with a Catmull-Rom spline.
    public var smooth: Bool
    public var style: Style
    /// Tube diameter (ribbon width) in local units.
    public var width: Float
    /// Samples per span.
    public var segments: Int
    /// Corners of the tube's round cross-section.
    public var sides: Int
    public var material: MaterialHandle
    /// Linear RGB multiplied with the material's base color (emission comes from the material).
    public var tint: Vec3
    public var opacity: Float
    public var castsShadows: Bool
    public var receivesShadows: Bool
    public var isVisible: Bool

    public init(points: [Vec3] = [Vec3(-1, 0, 0), Vec3(1, 0, 0)], start: EntityRef = .none, end: EntityRef = .none,
                sag: Float = 0, curve: Curve = .catenary, smooth: Bool = false, style: Style = .tube, width: Float = 0.05,
                segments: Int = 16, sides: Int = 8, material: MaterialHandle = .default, tint: Vec3 = Vec3(1, 1, 1),
                opacity: Float = 1, castsShadows: Bool = true, receivesShadows: Bool = true, isVisible: Bool = true) {
        self.points = points
        self.start = start
        self.end = end
        self.sag = sag
        self.curve = curve
        self.smooth = smooth
        self.style = style
        self.width = width
        self.segments = segments
        self.sides = sides
        self.material = material
        self.tint = tint
        self.opacity = opacity
        self.castsShadows = castsShadows
        self.receivesShadows = receivesShadows
        self.isVisible = isVisible
    }

    // Every field is optional when decoding, so scenes saved before a field existed still load.
    private enum CodingKeys: String, CodingKey {
        case points, start, end, sag, curve, smooth, style, width, segments, sides, material, tint, opacity
        case castsShadows, receivesShadows, isVisible
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LineRenderer()
        points = try c.decodeIfPresent([Vec3].self, forKey: .points) ?? d.points
        start = try c.decodeIfPresent(EntityRef.self, forKey: .start) ?? .none
        end = try c.decodeIfPresent(EntityRef.self, forKey: .end) ?? .none
        sag = try c.decodeIfPresent(Float.self, forKey: .sag) ?? d.sag
        curve = try c.decodeIfPresent(Curve.self, forKey: .curve) ?? d.curve
        smooth = try c.decodeIfPresent(Bool.self, forKey: .smooth) ?? d.smooth
        style = try c.decodeIfPresent(Style.self, forKey: .style) ?? d.style
        width = try c.decodeIfPresent(Float.self, forKey: .width) ?? d.width
        segments = try c.decodeIfPresent(Int.self, forKey: .segments) ?? d.segments
        sides = try c.decodeIfPresent(Int.self, forKey: .sides) ?? d.sides
        material = try c.decodeIfPresent(MaterialHandle.self, forKey: .material) ?? d.material
        tint = try c.decodeIfPresent(Vec3.self, forKey: .tint) ?? d.tint
        opacity = try c.decodeIfPresent(Float.self, forKey: .opacity) ?? d.opacity
        castsShadows = try c.decodeIfPresent(Bool.self, forKey: .castsShadows) ?? d.castsShadows
        receivesShadows = try c.decodeIfPresent(Bool.self, forKey: .receivesShadows) ?? d.receivesShadows
        isVisible = try c.decodeIfPresent(Bool.self, forKey: .isVisible) ?? d.isVisible
    }

    /// The key `SceneRenderer` registers the entity's generated mesh under.
    public static func meshKey(for entity: Entity) -> String { "line/\(entity.index).\(entity.generation)" }

    // MARK: Path

    /// The inputs the generated mesh depends on: equal specs give the same mesh, so a renderer
    /// rebuilds only when its entity's spec differs from the last one.
    public struct Spec: Equatable, Sendable {
        public var points: [Vec3]
        public var sag: Float
        public var curve: Curve
        public var smooth: Bool
        public var style: Style
        public var width: Float
        public var segments: Int
        public var sides: Int
    }

    /// The path in the entity's local space (`worldToLocal`: the inverse of its `GlobalTransform`),
    /// with the endpoint entities resolved, and the other mesh inputs.
    @MainActor public func spec(in world: World, worldToLocal: Mat4) -> Spec {
        var path = points
        if let a = world.resolve(start), let b = world.resolve(end),
           let ga = world.get(GlobalTransform.self, for: a), let gb = world.get(GlobalTransform.self, for: b) {
            func local(_ m: Mat4) -> Vec3 {
                let p = worldToLocal * m.c3
                return Vec3(p.x, p.y, p.z)
            }
            path = [local(ga.matrix)] + points + [local(gb.matrix)]
        }
        return Spec(points: path, sag: sag, curve: curve, smooth: smooth, style: style, width: width, segments: segments, sides: sides)
    }

    /// How far below its ends a span of `chord` length hangs at fraction `t`, as a fraction of its
    /// middle's drop `sag` (1 at t = 0.5, 0 at both ends).
    static func sagProfile(_ curve: Curve, t: Float, sag: Float, chord: Float) -> Float {
        switch curve {
        case .parabola:
            return 4 * t * (1 - t)
        case .catenary:
            // Sag / chord = (cosh k - 1) / (2k) for a catenary a * cosh(x / a) with k = chord / 2a;
            // solve k by bisection (the ratio grows monotonically with k).
            let ratio = sag / max(chord, 1e-6)
            guard ratio > 1e-5 else { return 4 * t * (1 - t) }
            var lo: Float = 1e-4, hi: Float = 40
            for _ in 0..<40 {
                let k = (lo + hi) / 2
                if (coshf(k) - 1) / (2 * k) < ratio { lo = k } else { hi = k }
            }
            let k = (lo + hi) / 2
            return (coshf(k) - coshf(k * (2 * t - 1))) / (coshf(k) - 1)
        }
    }

    /// The sampled centerline: `segments` samples per span (plus the last point).
    public static func centerline(_ spec: Spec) -> [Vec3] {
        let p = spec.points
        guard p.count >= 2 else { return p }
        let segments = max(1, spec.segments)
        var out: [Vec3] = []
        for i in 0..<p.count - 1 {
            let chord = length(p[i + 1] - p[i])
            let p0 = p[max(i - 1, 0)], p1 = p[i], p2 = p[i + 1], p3 = p[min(i + 2, p.count - 1)]
            for s in 0..<segments {
                let t = Float(s) / Float(segments)
                var point: Vec3
                if spec.smooth {
                    // Uniform Catmull-Rom; end spans reuse their end point as the missing neighbor.
                    let t2 = t * t, t3 = t2 * t
                    point = (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 + (p1 * 3 - p0 - p2 * 3 + p3) * t3) * 0.5
                } else {
                    point = p1 + (p2 - p1) * t
                }
                if spec.sag > 0 { point.y -= spec.sag * sagProfile(spec.curve, t: t, sag: spec.sag, chord: chord) }
                out.append(point)
            }
        }
        out.append(p[p.count - 1])
        return out
    }

    /// The mesh around `spec`'s centerline, in the entity's local space, or nil for fewer than two
    /// distinct points. UVs: U around the tube (across the ribbon), V the distance along the path.
    public static func geometry(_ spec: Spec) -> MeshGeometry? {
        var line: [Vec3] = []
        for point in centerline(spec) where line.last.map({ length($0 - point) > 1e-6 }) ?? true { line.append(point) }
        guard line.count >= 2 else { return nil }
        let n = line.count
        // Tangents (central differences), then rotation-minimizing frames by parallel transport.
        var tangents = (0..<n).map { i in normalize(line[min(i + 1, n - 1)] - line[max(i - 1, 0)]) }
        for i in 0..<n where !(length(tangents[i]) > 0) { tangents[i] = i > 0 ? tangents[i - 1] : Vec3(1, 0, 0) }
        var distance = [Float](repeating: 0, count: n)
        for i in 1..<n { distance[i] = distance[i - 1] + length(line[i] - line[i - 1]) }

        let radius = max(spec.width, 1e-5) / 2
        var g = MeshGeometry(vertices: [], indices: [])
        switch spec.style {
        case .tube:
            let sides = max(3, spec.sides)
            let t0 = tangents[0]
            var normal = abs(t0.y) < 0.99 ? normalize(cross(Vec3(0, 1, 0), t0)) : normalize(cross(Vec3(1, 0, 0), t0))
            for i in 0..<n {
                if i > 0 {
                    // Carry the previous normal along, removing its component along the new tangent.
                    var next = normal - tangents[i] * dot(normal, tangents[i])
                    if !(length(next) > 1e-6) { next = abs(tangents[i].y) < 0.99 ? cross(Vec3(0, 1, 0), tangents[i]) : cross(Vec3(1, 0, 0), tangents[i]) }
                    normal = normalize(next)
                }
                let binormal = cross(tangents[i], normal)
                for s in 0...sides {
                    let u = Float(s) / Float(sides), a = u * 2 * .pi
                    let dir = normal * cosf(a) + binormal * sinf(a)
                    g.vertices.append(MeshVertex(position: line[i] + dir * radius, normal: dir, uv: Vec2(u, distance[i])))
                }
            }
            let stride = UInt32(sides + 1)
            for i in 0..<UInt32(n - 1) {
                for s in 0..<UInt32(sides) {
                    let a = i * stride + s, b = a + 1, c = a + stride, d = c + 1
                    g.indices += [a, b, c, b, d, c]
                }
            }
        case .ribbon:
            // Across = tangent x up (a path along +Y falls back to X), so the strip stands up from
            // a horizontal path and faces sideways.
            for face in 0..<2 {
                let flip: Float = face == 0 ? 1 : -1
                let base = UInt32(g.vertices.count)
                for i in 0..<n {
                    let up = abs(tangents[i].y) < 0.99 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)
                    let across = normalize(cross(tangents[i], up))
                    // Face normal: across x tangent points to the front; the back face mirrors it.
                    let faceNormal = normalize(cross(across, tangents[i])) * flip
                    for side in 0..<2 {
                        let s = Float(side)
                        g.vertices.append(MeshVertex(position: line[i] + across * (radius * (s * 2 - 1)), normal: faceNormal,
                                                     uv: Vec2(s, distance[i])))
                    }
                }
                for i in 0..<UInt32(n - 1) {
                    let a = base + i * 2, b = a + 1, c = a + 2, d = a + 3
                    // Front (face 0) is counter-clockwise seen along its normal; the back reverses.
                    if face == 0 { g.indices += [a, b, c, b, d, c] } else { g.indices += [a, c, b, b, c, d] }
                }
            }
        }
        return g
    }
}
