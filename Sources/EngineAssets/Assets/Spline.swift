#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

// Spline math shared by `CameraPath` and `LineRenderer` (EngineRendering) and `.path` builds
// (PathBuild.swift): a uniform Catmull-Rom spline through control points, open or closed, and
// the sag of a hanging cable span.

/// A uniform Catmull-Rom spline through control points (it passes through every point).
public enum CatmullRom {
    /// The segment between `p1` and `p2` at `t` (0...1), with `p0` and `p3` as the neighbors.
    public static func point(_ p0: Vec3, _ p1: Vec3, _ p2: Vec3, _ p3: Vec3, _ t: Float) -> Vec3 {
        let t2 = t * t, t3 = t2 * t
        let a = p1 * 2
        let b = (p2 - p0) * t
        let c = (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
        let d = (p1 * 3 - p0 - p2 * 3 + p3) * t3
        return (a + b + c + d) * 0.5
    }

    /// Segments through `n` points: n - 1 open, n closed (a closed spline needs 3 points).
    public static func segmentCount(_ n: Int, closed: Bool) -> Int { n < 2 ? 0 : (closed && n > 2 ? n : n - 1) }

    /// The spline through `p` at parameter `u` in 0...segments (one unit per segment). Open ends
    /// reuse the end point as the missing neighbor; a closed spline wraps around.
    public static func position(at u: Float, points p: [Vec3], closed: Bool) -> Vec3 {
        let n = p.count
        guard n > 0 else { return .zero }
        let segments = segmentCount(n, closed: closed)
        guard segments > 0 else { return p[0] }
        let wraps = closed && n > 2
        let clamped = min(max(u, 0), Float(segments))
        let i = min(Int(clamped.rounded(.down)), segments - 1)
        let t = clamped - Float(i)
        func at(_ k: Int) -> Vec3 { wraps ? p[((k % n) + n) % n] : p[min(max(k, 0), n - 1)] }
        return point(at(i - 1), at(i), at(i + 1), at(i + 2), t)
    }
}

/// The shape of a cable hanging between two supports.
public enum CableSag {
    /// How far below its ends a span of `chord` length hangs at fraction `t`, as a fraction of its
    /// middle's drop `sag` (1 at t = 0.5, 0 at both ends): a parabola, or a catenary (the shape of
    /// a real hanging cable).
    public static func profile(catenary: Bool, t: Float, sag: Float, chord: Float) -> Float {
        guard catenary else { return 4 * t * (1 - t) }
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
