import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Tileable noise for procedural textures (`.proctex` generators and mesh build looks).
///
/// Coordinates are texture units: `u`, `v` in 0...1 cover one tile. Every function takes integer
/// frequencies (lattice cells across the tile, per axis), so its output wraps exactly at the tile
/// edges and textures repeat without seams. Values are deterministic (integer hashing from
/// `seed`), identical on every machine. Plain `Float` math throughout: these run per pixel.
enum TileNoise {
    @inline(__always) static func wrap(_ i: Int, _ period: Int) -> Int {
        let r = i % period
        return r < 0 ? r + period : r
    }

    @inline(__always) static func fract(_ x: Float) -> Float { x - x.rounded(.down) }

    @inline(__always) static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    @inline(__always) static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

    /// A lattice point's hash (cheap: noise calls it four times per octave per pixel).
    @inline(__always) static func latticeHash(_ seed: UInt32, _ i: Int, _ j: Int) -> UInt32 {
        var x = (UInt32(truncatingIfNeeded: i) &* 0x9E37_79B1) ^ (UInt32(truncatingIfNeeded: j) &* 0x85EB_CA6B) ^ seed
        x ^= x >> 16
        x = x &* 0x7FEB_352D
        x ^= x >> 15
        return x
    }

    /// The dot product of one of 8 gradient directions (picked by `h`) with (dx, dy).
    @inline(__always) private static func gradient(_ h: UInt32, _ dx: Float, _ dy: Float) -> Float {
        switch h & 7 {
        case 0: return dx + dy
        case 1: return dx - dy
        case 2: return -dx + dy
        case 3: return -dx - dy
        case 4: return 1.4142 * dx
        case 5: return -1.4142 * dx
        case 6: return 1.4142 * dy
        default: return -1.4142 * dy
        }
    }

    /// Gradient (Perlin) noise in about -1...1 at `u`, `v`, with `fx` x `fy` lattice cells per tile.
    static func perlin(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, seed: Int) -> Float {
        let fx = max(fx, 1), fy = max(fy, 1)
        let x = u * Float(fx), y = v * Float(fy)
        let xf = x.rounded(.down), yf = y.rounded(.down)
        let i = Int(xf), j = Int(yf)
        let dx = x - xf, dy = y - yf
        let i0 = wrap(i, fx), i1 = i0 + 1 == fx ? 0 : i0 + 1, j0 = wrap(j, fy), j1 = j0 + 1 == fy ? 0 : j0 + 1
        let sx = dx * dx * dx * (dx * (dx * 6 - 15) + 10), sy = dy * dy * dy * (dy * (dy * 6 - 15) + 10)
        let s = UInt32(truncatingIfNeeded: seed) &* 0x27D4_EB2F
        let a = gradient(latticeHash(s, i0, j0), dx, dy), b = gradient(latticeHash(s, i1, j0), dx - 1, dy)
        let c = gradient(latticeHash(s, i0, j1), dx, dy - 1), d = gradient(latticeHash(s, i1, j1), dx - 1, dy - 1)
        let top = a + (b - a) * sx, bottom = c + (d - c) * sx
        return top + (bottom - top) * sy
    }

    /// Fractal sum of `octaves` octaves of `perlin`, each twice the frequency and `gain` times the
    /// amplitude of the last, normalized to about -1...1.
    static func fbm(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, octaves: Int, seed: Int, gain: Float = 0.5) -> Float {
        var sum: Float = 0, amplitude: Float = 1, total: Float = 0
        var px = max(fx, 1), py = max(fy, 1)
        for o in 0..<max(octaves, 1) {
            sum += amplitude * perlin(u, v, px, py, seed: seed &+ o &* 101)
            total += amplitude
            amplitude *= gain
            px *= 2
            py *= 2
        }
        return sum / total
    }

    /// Ridged multifractal in 0...1: sharp crests where the noise crosses zero, each octave
    /// weighted by the one before (ridges get detail, valleys stay smooth).
    static func ridged(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, octaves: Int, seed: Int, gain: Float = 0.5) -> Float {
        var sum: Float = 0, amplitude: Float = 1, total: Float = 0, weight: Float = 1
        var px = max(fx, 1), py = max(fy, 1)
        for o in 0..<max(octaves, 1) {
            var r = 1 - abs(perlin(u, v, px, py, seed: seed &+ o &* 131))
            r *= r
            sum += amplitude * r * weight
            total += amplitude
            weight = min(max(r * 1.5, 0), 1)
            amplitude *= gain
            px *= 2
            py *= 2
        }
        return min(max(sum / total, 0), 1)
    }

    /// Worley (cellular) noise with `fx` x `fy` jittered feature points per tile: distances to the
    /// nearest and second-nearest point (in cell units) and the nearest point's cell hash.
    static func cells(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, seed: Int, jitter: Float = 0.9)
        -> (f1: Float, f2: Float, id: UInt32) {
        let fx = max(fx, 1), fy = max(fy, 1)
        let x = u * Float(fx), y = v * Float(fy)
        let xf = x.rounded(.down), yf = y.rounded(.down)
        let i = Int(xf), j = Int(yf)
        let s = UInt32(truncatingIfNeeded: seed) &* 0x165667B1 ^ 0x2C1B3C6D
        var f1: Float = 9, f2: Float = 9
        var id: UInt32 = 0
        for dj in -1...1 {
            for di in -1...1 {
                let ci = wrap(i + di, fx), cj = wrap(j + dj, fy)
                let h = latticeHash(s, ci, cj)
                let ox = 0.5 + jitter * (Float(h & 0xFFFF) / 65_535 - 0.5)
                let oy = 0.5 + jitter * (Float(h >> 16) / 65_535 - 0.5)
                let px = Float(i + di) + ox - x, py = Float(j + dj) + oy - y
                let d = (px * px + py * py).squareRoot()
                if d < f1 {
                    f2 = f1
                    f1 = d
                    id = h
                } else if d < f2 {
                    f2 = d
                }
            }
        }
        return (f1, f2, id)
    }

    /// A random value in 0...1 for an integer cell.
    @inline(__always) static func hash01(_ seed: Int, _ a: Int, _ b: Int = 0, _ c: Int = 0) -> Float {
        Hash32.unit(seed, a, b, c)
    }

    // MARK: Height to normal map

    /// A tangent-space normal map (linear RGBA8: XYZ in RGB, +Y toward decreasing V, as the
    /// renderer reads it) from a tileable height field of `size` x `size` samples. `strength` is
    /// the slope of a height change of 1 across the whole tile (height range in meters divided by
    /// the tile's size in meters for a physical bump).
    static func normalMap(height: [Float], width: Int, height rows: Int, strength: Float) -> [UInt8] {
        let sx = strength * Float(width) / 2, sy = strength * Float(rows) / 2
        return height.withUnsafeBufferPointer { h in
            let h = SharedPointer(h.baseAddress!)
            return parallelRows(rows, width * 4, initial: 255 as UInt8) { y, out in
                let up = wrap(y - 1, rows) * width, down = wrap(y + 1, rows) * width, row = y * width
                for x in 0..<width {
                    let left = wrap(x - 1, width), right = wrap(x + 1, width)
                    let dhdu = (h[row + right] - h[row + left]) * sx
                    let dhdv = (h[down + x] - h[up + x]) * sy
                    // n ∝ (-∂h/∂u, +∂h/∂v, 1): the bitangent points toward decreasing V.
                    let nx = -dhdu, ny = dhdv
                    let inv = 1 / (nx * nx + ny * ny + 1).squareRoot()
                    out[x * 4] = unitByte(nx * inv * 0.5 + 0.5)
                    out[x * 4 + 1] = unitByte(ny * inv * 0.5 + 0.5)
                    out[x * 4 + 2] = unitByte(inv * 0.5 + 0.5)
                }
            }
        }
    }

    /// An array of `rows` x `stride` values, each row filled by `body(row, pointer to its first
    /// value)` on all cores. `body` must write only its own row.
    static func parallelRows<T>(_ rows: Int, _ stride: Int, initial: T, _ body: @Sendable (Int, SharedPointer<T>) -> Void) -> [T] {
        var values = [T](repeating: initial, count: rows * stride)
        values.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            let shared = SharedPointer(UnsafePointer(base))
            DispatchQueue.concurrentPerform(iterations: rows) { y in body(y, shared.advanced(by: y * stride)) }
        }
        return values
    }

    @inline(__always) static func unitByte(_ v: Float) -> UInt8 { UInt8(min(max(v, 0), 1) * 255 + 0.5) }

    /// `values` (a `width` x `height` tileable field) blurred by a box of `radius` samples, twice
    /// (about a Gaussian), wrapping at the edges.
    static func blur(_ values: [Float], width: Int, height: Int, radius: Int) -> [Float] {
        guard radius > 0 else { return values }
        var a = values
        var b = [Float](repeating: 0, count: values.count)
        let scale = 1 / Float(2 * radius + 1)
        for _ in 0..<2 {
            // Rows.
            for y in 0..<height {
                let row = y * width
                var sum: Float = 0
                for k in -radius...radius { sum += a[row + wrap(k, width)] }
                for x in 0..<width {
                    b[row + x] = sum * scale
                    sum += a[row + wrap(x + radius + 1, width)] - a[row + wrap(x - radius, width)]
                }
            }
            // Columns.
            for x in 0..<width {
                var sum: Float = 0
                for k in -radius...radius { sum += b[wrap(k, height) * width + x] }
                for y in 0..<height {
                    a[y * width + x] = sum * scale
                    sum += b[wrap(y + radius + 1, height) * width + x] - b[wrap(y - radius, height) * width + x]
                }
            }
        }
        return a
    }
}

/// A pointer handed to parallel row workers (each writes only its own row; Linux's Dispatch
/// requires `@Sendable` closures).
struct SharedPointer<T>: @unchecked Sendable {
    let base: UnsafeMutablePointer<T>

    init(_ base: UnsafePointer<T>) { self.base = UnsafeMutablePointer(mutating: base) }

    @inline(__always) subscript(_ i: Int) -> T {
        get { base[i] }
        nonmutating set { base[i] = newValue }
    }

    func advanced(by n: Int) -> SharedPointer<T> { SharedPointer(UnsafePointer(base + n)) }
}
