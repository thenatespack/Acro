#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineAssets

// A plant's far detail level (MeshBuildLOD.swift): three crossed vertical quads through the
// middle of the plant, 60° apart, each showing the plant as seen straight through it.
//
// Importers can't use the GPU (they run on background threads and in the headless asset cooker),
// so the pictures are rasterized here on the CPU: each view is an orthographic projection of the
// full-detail meshes (in the model's space) with a depth buffer, the leaf looks' and bark looks'
// albedo sampled per pixel and their alpha cutoff applied, 2x2 samples per texel. Each texel
// stores the visible surface's color (times its baked occlusion) and, in a second texture, its
// normal in the quad's tangent space (the crown's bent normals), so the impostor is lit like the
// plant by the same PBR shader. Alpha is the covered share of the texel's samples; transparent
// texels take their neighbors' colors so mipmaps don't fringe. The three cells share a 512 px
// atlas (2x2 cells of 256 px; the fourth is unused).

enum MeshBuildImpostor {
    /// One part's mesh in the model's space and how its surface looks.
    struct Source {
        var geometry: MeshGeometry
        /// sRGB albedo sampled with the mesh's UVs (wrapping), times `tint`; nil: `tint` alone.
        var image: Image?
        /// Linear color multiplier.
        var tint: Vec3
        /// Samples whose albedo alpha is below this are cut out (leaf looks).
        var cutoff: Float?
        /// A leaf look: the impostor is translucent like leaves when any source is.
        var leafy: Bool
    }

    struct Baked {
        /// sRGB color, alpha the coverage.
        var albedo: Image
        /// Linear tangent-space normals.
        var normal: Image
        /// The crossed quads, in the model's space.
        var mesh: MeshGeometry
        var leafy: Bool
    }

    static let cell = 256
    static let views = 3
    static let samples = 2

    static func bake(_ sources: [Source]) -> Baked? {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for s in sources where !s.geometry.indices.isEmpty {
            for v in s.geometry.vertices {
                lo = pointwiseMin(lo, v.position)
                hi = pointwiseMax(hi, v.position)
            }
        }
        guard lo.x <= hi.x else { return nil }
        let axis = Vec3((lo.x + hi.x) / 2, 0, (lo.z + hi.z) / 2)
        var reach: Float = 0
        for s in sources {
            for v in s.geometry.vertices {
                let dx = v.position.x - axis.x, dz = v.position.z - axis.z
                reach = max(reach, (dx * dx + dz * dz).squareRoot())
            }
        }
        let height = max(hi.y - lo.y, 1e-3)
        let side = max(2 * reach, height) * 1.02
        // The square each view covers: centered on the axis, its bottom at the plant's foot (or
        // lower, centering a plant wider than it is tall).
        let bottom = lo.y - (side - height) / 2
        let res = cell * samples
        let atlas = 2 * cell
        var albedo = [UInt8](repeating: 0, count: atlas * atlas * 4)
        var normals = [UInt8](repeating: 0, count: atlas * atlas * 4)
        var mesh = MeshGeometry(vertices: [], indices: [])
        let up = Vec3(0, 1, 0)
        for view in 0..<views {
            let angle = Float(view) * .pi / Float(views)
            let facing = Vec3(sinf(angle), 0, cosf(angle))  // toward the viewer
            let right = cross(up, facing)
            let image = render(sources, axis: axis, right: right, facing: facing, bottom: bottom, side: side, res: res)
            let ox = (view % 2) * cell, oy = (view / 2) * cell
            write(image, into: &albedo, normals: &normals, atlas: atlas, at: (ox, oy))
            // The quad, its texture the cell (UV v down the image).
            let u0 = Float(ox) / Float(atlas), v0 = Float(oy) / Float(atlas), du = Float(cell) / Float(atlas)
            let corners: [(Float, Float)] = [(0, 0), (1, 0), (1, 1), (0, 1)]  // (across, up)
            let first = UInt32(mesh.vertices.count)
            for (a, b) in corners {
                let p = axis + right * ((a - 0.5) * side) + up * (bottom + b * side)
                mesh.vertices.append(MeshVertex(position: p, normal: facing, uv: Vec2(u0 + a * du, v0 + (1 - b) * du),
                                                tangent: Vec4(right, 1)))
            }
            mesh.indices += [first, first + 1, first + 2, first, first + 2, first + 3]
        }
        return Baked(albedo: Image(width: atlas, height: atlas, pixels: albedo), normal: Image(width: atlas, height: atlas, pixels: normals),
                     mesh: mesh, leafy: sources.contains { $0.leafy })
    }

    /// One view's samples: linear color, coverage and tangent-space normal per sample.
    private struct View {
        var color: [Vec3]
        var normal: [Vec3]
        var covered: [Bool]
    }

    private static func render(_ sources: [Source], axis: Vec3, right: Vec3, facing: Vec3, bottom: Float, side: Float, res: Int) -> View {
        let count = res * res
        var view = View(color: Array(repeating: .zero, count: count), normal: Array(repeating: Vec3(0, 0, 1), count: count),
                        covered: Array(repeating: false, count: count))
        var depth = [Float](repeating: -.infinity, count: count)
        let scale = Float(res) / side
        for source in sources {
            let g = source.geometry
            // Screen x, y (pixels, y down) and depth (toward the viewer) of every vertex.
            let screen = g.vertices.map { v -> Vec3 in
                let d = v.position - axis
                return Vec3((dot(d, right) / side + 0.5) * Float(res), (1 - (v.position.y - bottom) / side) * Float(res), dot(d, facing))
            }
            for t in stride(from: 0, to: g.indices.count - 2, by: 3) {
                let ia = Int(g.indices[t]), ib = Int(g.indices[t + 1]), ic = Int(g.indices[t + 2])
                let a = screen[ia], b = screen[ib], c = screen[ic]
                let area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
                guard abs(area) > 1e-9 else { continue }
                let x0 = max(Int(min(a.x, b.x, c.x).rounded(.down)), 0), x1 = min(Int(max(a.x, b.x, c.x).rounded(.up)), res - 1)
                let y0 = max(Int(min(a.y, b.y, c.y).rounded(.down)), 0), y1 = min(Int(max(a.y, b.y, c.y).rounded(.up)), res - 1)
                guard x0 <= x1, y0 <= y1 else { continue }
                let va = g.vertices[ia], vb = g.vertices[ib], vc = g.vertices[ic]
                for y in y0...y1 {
                    let py = Float(y) + 0.5
                    for x in x0...x1 {
                        let px = Float(x) + 0.5
                        // Barycentric weights (either winding: the plant's surfaces are seen from both sides).
                        let wa = ((b.x - px) * (c.y - py) - (b.y - py) * (c.x - px)) / area
                        let wb = ((c.x - px) * (a.y - py) - (c.y - py) * (a.x - px)) / area
                        let wc = 1 - wa - wb
                        guard wa >= 0, wb >= 0, wc >= 0 else { continue }
                        let z = a.z * wa + b.z * wb + c.z * wc
                        let i = y * res + x
                        guard z > depth[i] else { continue }
                        var color = source.tint
                        if let image = source.image {
                            let uv = va.uv * wa + vb.uv * wb + vc.uv * wc
                            let texel = sample(image, uv)
                            if let cutoff = source.cutoff, texel.w < cutoff { continue }
                            color *= Vec3(texel.x, texel.y, texel.z)
                        }
                        let occlusion = occlusionOf(va) * wa + occlusionOf(vb) * wb + occlusionOf(vc) * wc
                        color *= 1 - 0.7 * (1 - occlusion)
                        var n = va.normal * wa + vb.normal * wb + vc.normal * wc
                        let l = length(n)
                        n = l > 1e-6 ? n / l : facing
                        depth[i] = z
                        view.color[i] = color
                        view.normal[i] = Vec3(dot(n, right), dot(n, Vec3(0, 1, 0)), dot(n, facing))
                        view.covered[i] = true
                    }
                }
            }
        }
        return view
    }

    private static func occlusionOf(_ v: MeshVertex) -> Float {
        let w = abs(v.tangent.w)
        return w > 0 && w < 1 ? w : 1
    }

    /// The linear color and alpha of `image` (sRGB) at `uv`, wrapping, nearest texel.
    private static func sample(_ image: Image, _ uv: Vec2) -> Vec4 {
        let u = uv.x - uv.x.rounded(.down), v = uv.y - uv.y.rounded(.down)
        let x = min(Int(u * Float(image.width)), image.width - 1), y = min(Int(v * Float(image.height)), image.height - 1)
        let i = (y * image.width + x) * 4
        return Vec4(srgbTable[Int(image.pixels[i])], srgbTable[Int(image.pixels[i + 1])], srgbTable[Int(image.pixels[i + 2])],
                    Float(image.pixels[i + 3]) / 255)
    }

    private static let srgbTable: [Float] = (0..<256).map { k in
        let x = Float(k) / 255
        return x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4)
    }

    private static func srgbByte(_ x: Float) -> UInt8 {
        let x = min(max(x, 0), 1)
        let s = x <= 0.003_130_8 ? x * 12.92 : 1.055 * powf(x, 1 / 2.4) - 0.055
        return UInt8((s * 255).rounded())
    }

    /// Averages `view`'s samples into `cell` texels at `origin` of the atlas, then fills the
    /// uncovered texels with their covered neighbors' color and normal (repeatedly, so mipmaps
    /// average plant colors, not black).
    private static func write(_ view: View, into albedo: inout [UInt8], normals: inout [UInt8], atlas: Int, at origin: (Int, Int)) {
        let res = cell * samples
        var color = [Vec3](repeating: .zero, count: cell * cell)
        var normal = [Vec3](repeating: Vec3(0, 0, 1), count: cell * cell)
        var coverage = [Float](repeating: 0, count: cell * cell)
        for y in 0..<cell {
            for x in 0..<cell {
                var c = Vec3.zero, n = Vec3.zero, k = 0
                for sy in 0..<samples {
                    for sx in 0..<samples {
                        let i = (y * samples + sy) * res + x * samples + sx
                        guard view.covered[i] else { continue }
                        c += view.color[i]
                        n += view.normal[i]
                        k += 1
                    }
                }
                let t = y * cell + x
                coverage[t] = Float(k) / Float(samples * samples)
                if k > 0 {
                    color[t] = c / Float(k)
                    normal[t] = length(n) > 1e-6 ? normalize(n) : Vec3(0, 0, 1)
                }
            }
        }
        // Fill outward from the covered texels.
        var filled = coverage.map { $0 > 0 }
        for _ in 0..<12 {
            var next = filled
            var changed = false
            for y in 0..<cell {
                for x in 0..<cell where !filled[y * cell + x] {
                    var c = Vec3.zero, n = Vec3.zero, k = 0
                    for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                        let nx = x + dx, ny = y + dy
                        guard nx >= 0, ny >= 0, nx < cell, ny < cell, filled[ny * cell + nx] else { continue }
                        c += color[ny * cell + nx]
                        n += normal[ny * cell + nx]
                        k += 1
                    }
                    guard k > 0 else { continue }
                    color[y * cell + x] = c / Float(k)
                    normal[y * cell + x] = length(n) > 1e-6 ? normalize(n) : Vec3(0, 0, 1)
                    next[y * cell + x] = true
                    changed = true
                }
            }
            filled = next
            if !changed { break }
        }
        // What's still empty takes the average color.
        var sum = Vec3.zero, k: Float = 0
        for t in 0..<(cell * cell) where coverage[t] > 0 {
            sum += color[t]
            k += 1
        }
        let average = k > 0 ? sum / k : Vec3(repeating: 0.2)
        for y in 0..<cell {
            for x in 0..<cell {
                let t = y * cell + x
                let c = filled[t] ? color[t] : average
                let n = filled[t] ? normal[t] : Vec3(0, 0, 1)
                let o = ((origin.1 + y) * atlas + origin.0 + x) * 4
                albedo[o] = srgbByte(c.x)
                albedo[o + 1] = srgbByte(c.y)
                albedo[o + 2] = srgbByte(c.z)
                albedo[o + 3] = UInt8((coverage[t] * 255).rounded())
                normals[o] = UInt8(((n.x * 0.5 + 0.5) * 255).rounded())
                normals[o + 1] = UInt8(((n.y * 0.5 + 0.5) * 255).rounded())
                normals[o + 2] = UInt8(((n.z * 0.5 + 0.5) * 255).rounded())
                normals[o + 3] = 255
            }
        }
    }
}
