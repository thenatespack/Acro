import Engine
import Foundation

/// The editor's app icon (`EngineConfig.icon`): the Acro mark, an A split down the middle into a
/// yellow lit half and a cyan shadow half (the Arcade two-tone scheme), on a rounded near-black
/// tile. Drawn in code so the executable needs no resource bundle.
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

    // Layout, in unit coordinates (y down). The mark is the Acro "Apex Split" A from
    // `logos/schemes/arcade/split-duo-icon.svg`, drawn in a 512-unit space and then placed on the
    // tile with that file's transform.
    /// The tile: the macOS grid's 824/1024 body with a 185/1024 corner radius.
    private static let tileHalf: Float = 412 / 1024
    private static let tileRadius: Float = 185 / 1024
    /// Where the glow behind the A is centered.
    private static let glowX: Float = 0.5, glowY: Float = 0.55

    /// A point of the A's 512-unit design space, placed on the tile (scaled by 0.78 about the
    /// design's center and nudged down, as in the SVG).
    private static func place(_ x: Float, _ y: Float) -> (x: Float, y: Float) {
        ((256 + 0.78 * (x - 256)) / 512, (266 + 0.78 * (y - 253)) / 512)
    }
    /// The A's outline: apex, bottom right, bottom left (clockwise, y down).
    private static let outline = [place(256, 86), place(422, 420), place(90, 420)]
    /// The triangular counter (the arrowhead) cut out of the A.
    private static let counter = [place(256, 230.9), place(291.4, 302), place(220.6, 302)]
    /// The opening between the legs.
    private static let notch = [place(195.8, 352), place(316.2, 352), place(350.5, 421), place(161.5, 421)]
    /// The split down the middle: half its width, and the x it is centered on.
    private static let splitHalf: Float = 8 * 0.78 / 512
    private static let splitX: Float = 0.5
    private static let outlineTop = outline[0].y, outlineBottom = outline[1].y
    private static let outlineLeft = outline[2].x, outlineRight = outline[1].x

    /// Arcade two-tone: yellow for the lit (left) half, cyan for the shadow (right) half.
    private static let litColor: UInt32 = 0xFFE14D, shadowColor: UInt32 = 0x22C7F0

    private struct RGBA { var r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 0 }
    private struct RGB { var r, g, b: Float }

    private static func shade(x: Float, y: Float, aa: Float) -> RGBA {
        var out = RGBA()

        // Shadow: the tile's shape, lowered and blurred.
        let shadowDistance = roundedBoxDistance(x - 0.5, y - 0.512)
        if shadowDistance < 0.03 {
            over(&out, RGB(r: 0, g: 0, b: 0), 0.35 * (1 - smoothstep(-0.01, 0.03, shadowDistance)))
        }

        // Tile: a near-black vertical gradient, a soft glow behind the A and a faint rim.
        let tileDistance = roundedBoxDistance(x - 0.5, y - 0.5)
        let tileCoverage = coverage(tileDistance, aa)
        guard tileCoverage > 0 else { return out }
        let t = (y - (0.5 - tileHalf)) / (2 * tileHalf)
        var tile = mix(rgb(0x1E1E28), rgb(0x0A0A0F), t)
        let toGlowX = x - glowX, toGlowY = y - glowY
        let glow = max(0, 1 - (toGlowX * toGlowX + toGlowY * toGlowY).squareRoot() / 0.4)
        tile = mix(tile, rgb(0x3A3A55), glow * 0.45)
        let rim = 1 - smoothstep(0, 0.006, -tileDistance)
        tile = mix(tile, rgb(0x4A4A66), rim * 0.35)
        over(&out, tile, tileCoverage)

        // The A: past its bounds there is nothing to draw.
        guard x > outlineLeft - aa, x < outlineRight + aa, y > outlineTop - aa, y < outlineBottom + aa else { return out }
        let distance = max(max(polygonDistance(x, y, outline), -polygonDistance(x, y, counter)),
                           max(-polygonDistance(x, y, notch), splitHalf - abs(x - splitX)))
        let markCoverage = coverage(distance, aa)
        if markCoverage > 0 { over(&out, rgb(x < splitX ? litColor : shadowColor), markCoverage) }
        return out
    }

    private static func byte(_ value: Float) -> UInt8 { UInt8(min(max(value * 255, 0), 255).rounded()) }

    private static func rgb(_ hex: UInt32) -> RGB {
        RGB(r: Float((hex >> 16) & 0xFF) / 255, g: Float((hex >> 8) & 0xFF) / 255, b: Float(hex & 0xFF) / 255)
    }

    private static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB {
        RGB(r: a.r + (b.r - a.r) * t, g: a.g + (b.g - a.g) * t, b: a.b + (b.b - a.b) * t)
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

    /// Signed distance to a convex polygon (clockwise in y-down coordinates), exact inside and
    /// along the edges, which is all antialiasing needs.
    private static func polygonDistance(_ x: Float, _ y: Float, _ points: [(x: Float, y: Float)]) -> Float {
        var distance = -Float.infinity
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            let ex = b.x - a.x, ey = b.y - a.y
            // Outward normal of a clockwise (y-down) edge: (ey, -ex).
            distance = max(distance, ((x - a.x) * ey - (y - a.y) * ex) / (ex * ex + ey * ey).squareRoot())
        }
        return distance
    }
}
