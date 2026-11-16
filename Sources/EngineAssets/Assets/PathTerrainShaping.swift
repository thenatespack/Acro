import Foundation
import EngineCore

// Shaping a terrain to a path: flattening the ground under a road, carving a river bed, building
// up an embankment. Works on a `Terrain` value; the editor writes the result into the `.terrain`
// file (an undo step), and the path, which depends on the terrain, reimports onto the new ground.

/// Which way `PathBuild.shapeTerrain` may move the ground.
public enum PathTerrainShapeMode: String, Codable, CaseIterable, Sendable {
    /// Cut and fill: the ground under the path ends up at the path's level.
    case flatten
    /// Only lower the ground (cuttings, river beds); it never rises.
    case carve
    /// Only raise the ground (embankments); it never drops.
    case raise
}

/// How `PathBuild.shapeTerrain` shapes the ground.
public struct PathTerrainShaping: Codable, Equatable, Sendable {
    public var mode: PathTerrainShapeMode
    /// Meters across the flat part, centered on the path; nil: the widest profile (2 m without profiles).
    public var width: Float?
    /// Meters beyond each edge over which the shaped ground blends back into the terrain.
    public var shoulder: Float
    /// Meters below the path's ground level to put the flat part (a river bed, a sunken lane).
    public var depth: Float
    /// Meters along the path over which the ground level is averaged, so a road following bumpy
    /// ground comes out smooth (0: no smoothing).
    public var smoothing: Float

    public init(mode: PathTerrainShapeMode = .flatten, width: Float? = nil, shoulder: Float = 3, depth: Float = 0, smoothing: Float = 8) {
        self.mode = mode
        self.width = width
        self.shoulder = shoulder
        self.depth = depth
        self.smoothing = smoothing
    }

    private enum CodingKeys: String, CodingKey { case mode, width, shoulder, depth, smoothing }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathTerrainShaping()
        self.init(mode: try c.decodeIfPresent(PathTerrainShapeMode.self, forKey: .mode) ?? d.mode,
                  width: try c.decodeIfPresent(Float.self, forKey: .width),
                  shoulder: try c.decodeIfPresent(Float.self, forKey: .shoulder) ?? d.shoulder,
                  depth: try c.decodeIfPresent(Float.self, forKey: .depth) ?? d.depth,
                  smoothing: try c.decodeIfPresent(Float.self, forKey: .smoothing) ?? d.smoothing)
    }
}

/// What `PathBuild.shapeTerrain` changed.
public struct PathTerrainShapeReport: Equatable, Sendable {
    /// Height samples moved.
    public var changedSamples: Int
    /// The largest move, in meters (up or down).
    public var largestChange: Float
    /// Samples that wanted to go below 0 or above the terrain's height range and were clamped.
    public var clampedSamples: Int
}

extension PathBuild {
    /// Meters across the widest profile (with its offset and the widest point width); 2 m without profiles.
    public var profileWidth: Float {
        let widest = points.map(\.width).max() ?? 1
        let halves = profiles.map { p -> Float in
            let half = p.shape == .custom ? (p.points.map { abs($0.x) }.max() ?? p.width / 2) : p.width / 2
            return abs(p.offset.x) + half * max(widest, 0)
        }
        return halves.isEmpty ? 2 : 2 * (halves.max() ?? 1)
    }

    /// `terrain` with its heights shaped to this path: within `width / 2` of the centerline the
    /// ground is set to the path's ground level (the centerline on the followed terrain, averaged
    /// over `smoothing` meters, less `depth`; or the path's own heights when it doesn't follow a
    /// terrain), blending back over `shoulder` meters. Cross-sections are level (banking is
    /// ignored). `terrain` is in the path's space shifted by `self.terrain.offset`.
    public func shapeTerrain(_ terrain: Terrain, _ shaping: PathTerrainShaping = PathTerrainShaping()) -> (Terrain, PathTerrainShapeReport) {
        var out = terrain
        out.resolution = out.res
        out.normalizeData()
        var report = PathTerrainShapeReport(changedSamples: 0, largestChange: 0, clampedSamples: 0)
        let following = self.terrain.isOn
        let samples = self.samples(on: following ? out : nil)
        guard samples.count > 1 else { return (out, report) }
        let offset = self.terrain.offset

        // The ground level at each sample, in the terrain's space, averaged along the path.
        let raw = samples.map { $0.position.y - (following ? self.terrain.height : 0) - offset.y }
        let level = Self.smoothed(raw, distances: samples.map(\.distance), window: max(shaping.smoothing, 0), closed: wraps)
            .map { $0 - shaping.depth }

        let half = max(shaping.width ?? profileWidth, 0) / 2
        let shoulder = max(shaping.shoulder, 0)
        let reach = half + shoulder
        let n = out.res
        let cells = Float(n - 1)
        let size = Vec2(max(out.size.x, 0.001), max(out.size.y, 0.001))
        // For each height sample near the path: the nearest horizontal distance and the level there.
        var best = [Float](repeating: .infinity, count: n * n)
        var target = [Float](repeating: 0, count: n * n)
        func grid(_ x: Float, _ z: Float) -> (Float, Float) { ((x / size.x + 0.5) * cells, (z / size.y + 0.5) * cells) }
        for i in 1..<samples.count {
            let a = samples[i - 1].position - offset, b = samples[i].position - offset
            let (ax, az) = grid(min(a.x, b.x) - reach, min(a.z, b.z) - reach)
            let (bx, bz) = grid(max(a.x, b.x) + reach, max(a.z, b.z) + reach)
            let x0 = max(Int(ax.rounded(.down)), 0), x1 = min(Int(bx.rounded(.up)), n - 1)
            let z0 = max(Int(az.rounded(.down)), 0), z1 = min(Int(bz.rounded(.up)), n - 1)
            guard x0 <= x1, z0 <= z1 else { continue }
            let abx = b.x - a.x, abz = b.z - a.z, l2 = abx * abx + abz * abz
            for gz in z0...z1 {
                for gx in x0...x1 {
                    let p = out.position(x: gx, z: gz)
                    let t: Float = l2 > 1e-8 ? min(max(((p.x - a.x) * abx + (p.y - a.z) * abz) / l2, 0), 1) : 0
                    let dx = p.x - (a.x + abx * t), dz = p.y - (a.z + abz * t)
                    let d = (dx * dx + dz * dz).squareRoot()
                    let k = gz * n + gx
                    if d <= reach, d < best[k] {
                        best[k] = d
                        target[k] = level[i - 1] + (level[i] - level[i - 1]) * t
                    }
                }
            }
        }

        let range = max(out.heightRange, 0.001)
        for k in best.indices where best[k].isFinite {
            let current = Float(out.heightData[k]) / 65535 * range
            // 1 on the flat part, easing to 0 at the shoulder's outer edge.
            let weight: Float
            if best[k] <= half || shoulder <= 0 {
                weight = 1
            } else {
                let f = 1 - (best[k] - half) / shoulder
                weight = f * f * (3 - 2 * f)
            }
            var wanted = current + (target[k] - current) * weight
            switch shaping.mode {
            case .flatten: break
            case .carve: wanted = min(wanted, current)
            case .raise: wanted = max(wanted, current)
            }
            if wanted < 0 || wanted > range { report.clampedSamples += 1 }
            let value = UInt16((min(max(wanted, 0), range) / range * 65535).rounded())
            guard value != out.heightData[k] else { continue }
            report.changedSamples += 1
            report.largestChange = max(report.largestChange, abs(Float(value) / 65535 * range - current))
            out.heightData[k] = value
        }
        return (out, report)
    }

    /// `values` averaged over `window` meters of `distances` (a box filter; wraps when `closed`).
    static func smoothed(_ values: [Float], distances: [Float], window: Float, closed: Bool) -> [Float] {
        guard window > 0, values.count > 2, let total = distances.last, total > 0 else { return values }
        let half = window / 2
        return values.indices.map { i in
            var sum: Float = 0, count: Float = 0
            for j in values.indices {
                var d = abs(distances[j] - distances[i])
                if closed { d = min(d, total - d) }
                if d <= half { sum += values[j]; count += 1 }
            }
            return count > 0 ? sum / count : values[i]
        }
    }
}
