import Engine
import Foundation

/// The editor's app icon (`EngineConfig.icon`): an isometric cube on a rounded midnight-blue
/// tile, drawn in code so the executable needs no resource bundle.
public enum EditorAppIcon {
    /// The icon at `size` x `size` pixels. The tile follows the macOS icon grid (824 of 1024,
    /// with a soft shadow), so it sits in the Dock like other apps. Rows are drawn in parallel
    /// with scalar math, so it stays quick in debug builds too.
    public static func image(size: Int = 512) -> Image {
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        pixels.withUnsafeMutableBufferPointer { buffer in
            let base = buffer.baseAddress!
            // Each row writes only its own bytes.
            nonisolated(unsafe) let output = base
            DispatchQueue.concurrentPerform(iterations: size) { y in
                for x in 0..<size {
                    let color = shade(x: (Float(x) + 0.5) / Float(size), y: (Float(y) + 0.5) / Float(size), aa: 1 / Float(size))
                    let i = (y * size + x) * 4
                    output[i] = byte(color.r)
                    output[i + 1] = byte(color.g)
                    output[i + 2] = byte(color.b)
                    output[i + 3] = byte(color.a)
                }
            }
        }
        return Image(width: size, height: size, pixels: pixels)
    }

    // Layout, in unit coordinates (y down).
    /// The tile: the macOS grid's 824/1024 body with a 185/1024 corner radius.
    private static let tileHalf: Float = 412 / 1024
    private static let tileRadius: Float = 185 / 1024
    /// The cube: an isometric hexagon of this radius, split into three faces with thin gaps.
    private static let cubeX: Float = 0.5, cubeY: Float = 0.53, cubeRadius: Float = 0.25
    private static let faceGap: Float = 0.012

    private struct RGBA { var r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 0 }
    private struct RGB { var r, g, b: Float }

    private static func shade(x: Float, y: Float, aa: Float) -> RGBA {
        var out = RGBA()

        // Shadow: the tile's shape, lowered and blurred.
        let shadowDistance = roundedBoxDistance(x - 0.5, y - 0.512)
        if shadowDistance < 0.03 {
            over(&out, RGB(r: 0, g: 0, b: 0), 0.35 * (1 - smoothstep(-0.01, 0.03, shadowDistance)))
        }

        // Tile: a vertical gradient, a soft glow behind the cube and a faint rim highlight on top.
        let tileDistance = roundedBoxDistance(x - 0.5, y - 0.5)
        let tileCoverage = coverage(tileDistance, aa)
        guard tileCoverage > 0 else { return out }
        let t = (y - (0.5 - tileHalf)) / (2 * tileHalf)
        var tile = mix(rgb(0x34457A), rgb(0x161D38), t)
        let toCubeX = x - cubeX, toCubeY = y - cubeY
        let glow = max(0, 1 - (toCubeX * toCubeX + toCubeY * toCubeY).squareRoot() / 0.42)
        tile = add(tile, rgb(0x5A6FB8), glow * glow * 0.35)
        let rim = 1 - smoothstep(0, 0.006, -tileDistance)
        tile = mix(tile, rgb(0x6C7FC4), rim * 0.6 * (1 - t))
        over(&out, tile, tileCoverage)

        // Cube faces: past the hexagon's bounds there is nothing to draw.
        let halfWidth = cubeRadius * 0.8660254
        guard abs(toCubeX) < halfWidth + aa, abs(toCubeY) < cubeRadius + aa else { return out }
        let topX = cubeX, topY = cubeY - cubeRadius, bottomX = cubeX, bottomY = cubeY + cubeRadius
        let rightX = cubeX + halfWidth, leftX = cubeX - halfWidth
        let upperY = cubeY - cubeRadius / 2, lowerY = cubeY + cubeRadius / 2
        let faces: [(xs: (Float, Float, Float, Float), ys: (Float, Float, Float, Float), color: UInt32)] = [
            ((topX, rightX, cubeX, leftX), (topY, upperY, cubeY, upperY), 0xFFC15E),
            ((leftX, cubeX, bottomX, leftX), (upperY, cubeY, bottomY, lowerY), 0xF2803A),
            ((cubeX, rightX, rightX, bottomX), (cubeY, upperY, lowerY, bottomY), 0xC9502E),
        ]
        for face in faces {
            let distance = quadDistance(x, y, face.xs, face.ys) + faceGap / 2
            let faceCoverage = coverage(distance, aa)
            if faceCoverage > 0 { over(&out, rgb(face.color), faceCoverage) }
        }
        return out
    }

    private static func byte(_ value: Float) -> UInt8 { UInt8(min(max(value * 255, 0), 255).rounded()) }

    private static func rgb(_ hex: UInt32) -> RGB {
        RGB(r: Float((hex >> 16) & 0xFF) / 255, g: Float((hex >> 8) & 0xFF) / 255, b: Float(hex & 0xFF) / 255)
    }

    private static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB {
        RGB(r: a.r + (b.r - a.r) * t, g: a.g + (b.g - a.g) * t, b: a.b + (b.b - a.b) * t)
    }

    private static func add(_ a: RGB, _ b: RGB, _ amount: Float) -> RGB {
        RGB(r: a.r + b.r * amount, g: a.g + b.g * amount, b: a.b + b.b * amount)
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// How much of a pixel a shape with signed distance `distance` (negative inside) covers.
    private static func coverage(_ distance: Float, _ aa: Float) -> Float { min(max(0.5 - distance / aa, 0), 1) }

    /// Straight-alpha "over": `color` at `coverage` on top of `dst`.
    private static func over(_ dst: inout RGBA, _ color: RGB, _ coverage: Float) {
        let alpha = coverage + dst.a * (1 - coverage)
        guard alpha > 0 else { return }
        let below = dst.a * (1 - coverage)
        dst = RGBA(r: (color.r * coverage + dst.r * below) / alpha, g: (color.g * coverage + dst.g * below) / alpha,
                   b: (color.b * coverage + dst.b * below) / alpha, a: alpha)
    }

    /// Signed distance from the tile's center offset (`px`, `py`) to its rounded square.
    private static func roundedBoxDistance(_ px: Float, _ py: Float) -> Float {
        let qx = abs(px) - tileHalf + tileRadius, qy = abs(py) - tileHalf + tileRadius
        let outsideX = max(qx, 0), outsideY = max(qy, 0)
        return (outsideX * outsideX + outsideY * outsideY).squareRoot() + min(max(qx, qy), 0) - tileRadius
    }

    /// Signed distance to a convex quad (clockwise in y-down coordinates), exact inside and along
    /// the edges, which is all antialiasing needs.
    private static func quadDistance(_ x: Float, _ y: Float, _ xs: (Float, Float, Float, Float), _ ys: (Float, Float, Float, Float)) -> Float {
        func edge(_ ax: Float, _ ay: Float, _ bx: Float, _ by: Float) -> Float {
            let ex = bx - ax, ey = by - ay
            let length = (ex * ex + ey * ey).squareRoot()
            // Outward normal of a clockwise (y-down) edge: (ey, -ex).
            return ((x - ax) * ey - (y - ay) * ex) / length
        }
        return max(max(edge(xs.0, ys.0, xs.1, ys.1), edge(xs.1, ys.1, xs.2, ys.2)),
                   max(edge(xs.2, ys.2, xs.3, ys.3), edge(xs.3, ys.3, xs.0, ys.0)))
    }
}
