import Foundation
import EngineCore
import EngineGraphics

/// What `NavMesh.drawDebug` draws.
public struct NavMeshDebugOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Polygons filled, tinted by region.
    public static let polygons = NavMeshDebugOptions(rawValue: 1 << 0)
    /// Polygon outlines.
    public static let edges = NavMeshDebugOptions(rawValue: 1 << 1)
    /// Off-mesh links as arcs.
    public static let links = NavMeshDebugOptions(rawValue: 1 << 2)
    /// Areas the largest one can't reach, in red.
    public static let islands = NavMeshDebugOptions(rawValue: 1 << 3)

    public static let all: NavMeshDebugOptions = [.polygons, .edges, .links, .islands]
}

extension NavMesh {
    /// The largest island (by area), whose polygons `drawDebug` doesn't flag.
    public var mainIsland: Int32 {
        guard islandCount > 1 else { return 0 }
        var area = [Float](repeating: 0, count: islandCount)
        for polygon in polygons { area[Int(polygon.island)] += polygon.area }
        return Int32(area.indices.max { area[$0] != area[$1] ? area[$0] < area[$1] : $0 > $1 } ?? 0)
    }

    /// Draws the mesh into `draw`, `lift` meters over the surface (so it shows over the floor).
    public func drawDebug(into draw: DebugDraw, options: NavMeshDebugOptions = .all, lift: Float = 0.04, alpha: Float = 0.5,
                          depth: DebugDepth = .tested) {
        let up = Vec3(0, lift, 0)
        let main = mainIsland
        for polygon in polygons where polygon.vertices.count >= 3 {
            let v = polygon.vertices.map { $0 + up }
            if options.contains(.polygons) {
                var color = Self.regionColor(polygon.region)
                if options.contains(.islands), islandCount > 1, polygon.island != main { color = Vec3(0.95, 0.2, 0.15) }
                for i in 1..<(v.count - 1) { draw.triangle(v[0], v[i], v[i + 1], color: Vec4(color, alpha), depth: depth) }
            }
            if options.contains(.edges) {
                draw.polyline(v, closed: true, color: Vec4(0.05, 0.25, 0.3, 0.8), style: DebugDraw.Style(width: 1, depth: depth))
            }
        }
        if options.contains(.links) {
            for link in offMeshLinks {
                let color = link.kind == .ladder ? Vec4(1, 0.85, 0.2, 1) : Vec4(0.2, 0.9, 1, 1)
                let points = Self.arc(from: link.start + up, to: link.end + up, kind: link.kind, samples: 16)
                draw.polyline(points, color: color, style: DebugDraw.Style(width: 2.5, depth: .onTop))
                draw.circle(center: link.start + up, normal: Vec3(0, 1, 0), radius: 0.25, color: color, style: DebugDraw.Style(width: 2, depth: .onTop))
                draw.circle(center: link.end + up, normal: Vec3(0, 1, 0), radius: 0.25, color: color, style: DebugDraw.Style(width: 2, depth: .onTop))
                if !link.bidirectional, points.count >= 2 {
                    draw.arrow(from: points[points.count - 2], to: points[points.count - 1], color: color, headSize: 0.3,
                               style: DebugDraw.Style(width: 2.5, depth: .onTop))
                }
            }
        }
    }

    /// A path as a line with dots at its corners.
    public static func drawPath(_ path: [Vec3], into draw: DebugDraw, color: Vec4 = Vec4(1, 0.8, 0.2, 1), lift: Float = 0.08) {
        let points = path.map { $0 + Vec3(0, lift, 0) }
        draw.polyline(points, color: color, style: DebugDraw.Style(width: 2.5, depth: .onTop))
        for p in points { draw.circle(center: p, normal: Vec3(0, 1, 0), radius: 0.12, color: color, style: DebugDraw.Style(width: 2, depth: .onTop)) }
    }

    /// Points along an agent's way across a link (`t` from 0 to 1): an arc for jumps and drops,
    /// straight up or down then across for ladders, a line for walking.
    public static func linkPoint(from a: Vec3, to b: Vec3, kind: NavigationLinkKind, t: Float) -> Vec3 {
        let t = min(max(t, 0), 1)
        switch kind {
        case .walk:
            return a + (b - a) * t
        case .jump, .drop:
            let flat = Vec3(b.x - a.x, 0, b.z - a.z)
            // Higher over a longer or upward jump; a drop just hops off the edge.
            let height = kind == .jump ? max(0.6, length(flat) * 0.25) + abs(b.y - a.y) * 0.35 : 0.3
            let y = a.y + (b.y - a.y) * t + 4 * height * t * (1 - t)
            return Vec3(a.x + flat.x * t, y, a.z + flat.z * t)
        case .ladder:
            // Climb (or descend) in the first 80%, step off in the rest.
            let climb: Float = 0.8
            if t < climb {
                let k = t / climb
                return Vec3(a.x, a.y + (b.y - a.y) * k, a.z)
            }
            let k = (t - climb) / (1 - climb)
            return Vec3(a.x + (b.x - a.x) * k, b.y, a.z + (b.z - a.z) * k)
        }
    }

    static func arc(from a: Vec3, to b: Vec3, kind: NavigationLinkKind, samples: Int) -> [Vec3] {
        (0...samples).map { linkPoint(from: a, to: b, kind: kind, t: Float($0) / Float(samples)) }
    }

    /// A pale color per region.
    static func regionColor(_ region: Int32) -> Vec3 {
        let h = Float((Int(region) &* 37) % 360) / 360
        let s: Float = 0.6, v: Float = 0.95
        let i = Int(h * 6) % 6, f = h * 6 - Float(Int(h * 6))
        let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch i {
        case 0: return Vec3(v, t, p)
        case 1: return Vec3(q, v, p)
        case 2: return Vec3(p, v, t)
        case 3: return Vec3(p, q, v)
        case 4: return Vec3(t, p, v)
        default: return Vec3(v, p, q)
        }
    }
}
