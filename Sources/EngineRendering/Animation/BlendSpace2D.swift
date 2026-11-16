import Foundation
import EngineAssets
import EngineCore

// 2D blend spaces: clips placed at points on a plane of two float parameters (e.g. strafe
// direction: moveX, moveY), mixed by gradient band interpolation.

/// A clip placed at a point of a 2D blend space.
public struct BlendSpace2DEntry: Codable, Equatable, Sendable {
    public var clip: AnimationClipHandle
    public var x: Float
    public var y: Float

    public init(clip: AnimationClipHandle, x: Float, y: Float) {
        self.clip = clip
        self.x = x
        self.y = y
    }
}

extension AnimationMotion {
    /// Every clip the motion plays.
    public var clips: [AnimationClipHandle] {
        switch self {
        case .clip(let clip): [clip]
        case .blend1D(_, let entries): entries.map(\.clip)
        case .blend2D(_, _, let entries): entries.map(\.clip)
        }
    }

    /// Each point's weight at `value` (weights add up to 1), by gradient band interpolation
    /// (freeform cartesian): a point's weight falls from 1 at the point to 0 at each other
    /// point along the line between them, taking the smallest over all others. Exactly on a
    /// point gives that point alone; outside the points' hull the nearest edge's points share.
    /// Points in any layout work (a cross, a ring, a grid); equal points share their weight.
    public static func blendWeights2D(points: [Vec2], value: Vec2) -> [Float] {
        var weights = [Float](repeating: 0, count: points.count)
        guard points.count > 1 else {
            if !points.isEmpty { weights[0] = 1 }
            return weights
        }
        for i in points.indices {
            var w: Float = 1
            let toValue = value - points[i]
            for j in points.indices where j != i {
                let edge = points[j] - points[i]
                let lengthSquared = edge.x * edge.x + edge.y * edge.y
                guard lengthSquared > 1e-12 else { continue }  // the same point: shares below
                let h = 1 - (toValue.x * edge.x + toValue.y * edge.y) / lengthSquared
                w = min(w, max(h, 0))
                if w == 0 { break }
            }
            weights[i] = w
        }
        let total = weights.reduce(0, +)
        if total > 1e-6 { return weights.map { $0 / total } }
        // Numerically nowhere (shouldn't happen): the nearest point.
        let nearest = points.indices.min { lengthSquared(points[$0] - value) < lengthSquared(points[$1] - value) }!
        weights[nearest] = 1
        return weights
    }

    private static func lengthSquared(_ v: Vec2) -> Float { v.x * v.x + v.y * v.y }
}
