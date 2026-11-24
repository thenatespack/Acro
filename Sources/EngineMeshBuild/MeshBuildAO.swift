#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// Baked ambient occlusion for mesh builds: how much of the sky each vertex sees past the model's
// other parts (and its own folds), so parts darken where they meet: contact shadows under a lid,
// between planks, around a bolt. On unless the file says `"ao": false`.
//
// The whole model (all parts at rest, in model space) is drawn into a voxel grid of its surfaces;
// from every vertex, 24 fixed rays (cosine-distributed over its normal's hemisphere) march through
// the grid up to a reach of about 15% of the model's size; a ray that hits a surface occludes by
// how close the hit is, and the result is smoothed along the mesh's edges (hiding the grid's
// steps). Meshes are first tessellated to about two grid cells per edge, so a box face can darken
// in the middle where something touches it. Parts with `wear` darken their creases more.
//
// The result rides in `MeshVertex.tangent.w`: its sign stays the tangent frame's handedness and
// its magnitude (below 1) is the occlusion, which the lit shader multiplies into the ambient
// light like an occlusion texture (mesh_surface.glsl). Meshes without baked occlusion have
// |w| = 1 and are unchanged.

/// Mesh build ambient occlusion (see the notes at the top of this file).
enum MeshBuildAO {
    /// A part's mesh placed in the model.
    struct Placed {
        var geometry: MeshGeometry
        var rotation: Quat
        var translation: Vec3
        /// Darkens creases more (the part's `wear`).
        var wear: Float
    }

    /// Settings derived from the model's size: ray reach, grid cell and tessellation edge, meters.
    struct Scale {
        var reach: Float
        var cell: Float
        var edge: Float

        init(extent: Float) {
            reach = min(max(extent * 0.15, 0.04), 0.4)
            cell = max(reach / 12, extent / 192, 0.002)
            // Occlusion is smooth over `reach`, so vertices half a reach apart carry it; finer
            // splitting only multiplies triangles (and bake time).
            edge = max(cell * 2.5, reach * 0.5)
        }
    }

    static let rayCount = 24
    /// Fixed cosine-weighted directions in a z-up frame (a Fibonacci spiral).
    static let directions: [Vec3] = (0..<rayCount).map { i in
        let r = ((Float(i) + 0.5) / Float(rayCount)).squareRoot()
        let phi = Float(i) * 2.399_963
        let z = (1 - r * r).squareRoot()
        // Keep every ray at least ~12° above the surface so flat faces don't occlude themselves.
        let lifted = normalize(Vec3(r * cosf(phi), r * sinf(phi), max(z, 0.2)))
        return lifted
    }

    /// A vertex in model space. A struct, not a tuple: debug builds look up a tuple's type metadata
    /// on every access through generic code (arrays, pointers), and the bake reads these per ray.
    struct Point {
        var p: Vec3
        var n: Vec3
    }

    /// Per vertex of each placed mesh, its occlusion factor (1: open sky, toward 0: enclosed).
    static func bake(_ parts: [Placed], scale: Scale) -> [[Float]] {
        // Model-space positions and normals.
        var world: [[Point]] = []
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for part in parts {
            let placed = part.geometry.vertices.map { v in
                Point(p: part.rotation * v.position + part.translation, n: part.rotation * v.normal)
            }
            for v in placed {
                lo = pointwiseMin(lo, v.p)
                hi = pointwiseMax(hi, v.p)
            }
            world.append(placed)
        }
        guard lo.x <= hi.x else { return parts.map { _ in [] } }
        let cell = scale.cell
        lo -= Vec3(repeating: cell * 2)
        hi += Vec3(repeating: cell * 2)
        let dims = SIMD3<Int>(Int(((hi.x - lo.x) / cell).rounded(.up)) + 1, Int(((hi.y - lo.y) / cell).rounded(.up)) + 1,
                              Int(((hi.z - lo.z) / cell).rounded(.up)) + 1)
        var grid = [UInt8](repeating: 0, count: dims.x * dims.y * dims.z)
        @inline(__always) func index(_ p: Vec3) -> Int? {
            let x = Int((p.x - lo.x) / cell), y = Int((p.y - lo.y) / cell), z = Int((p.z - lo.z) / cell)
            guard x >= 0, y >= 0, z >= 0, x < dims.x, y < dims.y, z < dims.z else { return nil }
            return (z * dims.y + y) * dims.x + x
        }
        // Surfaces into the grid: sample each triangle at half-cell spacing.
        for (part, placed) in zip(parts, world) {
            let indices = part.geometry.indices
            for t in stride(from: 0, to: indices.count - 2, by: 3) {
                let a = placed[Int(indices[t])].p, b = placed[Int(indices[t + 1])].p, c = placed[Int(indices[t + 2])].p
                let longest = max(length(b - a), length(c - a), length(c - b))
                let k = min(max(Int((longest / (cell * 0.5)).rounded(.up)), 1), 2048)
                // Counted loops here and in the rays: they run per sample (ForEachIndex.swift).
                forEachIndex(0...k) { i in
                    forEachIndex(0...(k - i)) { j in
                        let p = a + (b - a) * (Float(i) / Float(k)) + (c - a) * (Float(j) / Float(k))
                        if let g = index(p) { grid[g] = 1 }
                    }
                }
            }
        }
        // Rays.
        let reach = scale.reach, step = cell * 0.8, start = cell * 2.5
        let steps = max(Int(((reach - start) / step).rounded(.up)), 1)
        let dims3 = dims, lo3 = lo
        return grid.withUnsafeBufferPointer { (gridBuffer: UnsafeBufferPointer<UInt8>) -> [[Float]] in
            let occupied = SharedPointer(gridBuffer.baseAddress!)
            var result: [[Float]] = []
            for (part, placed) in zip(parts, world) {
                let count = placed.count
                guard count > 0 else {
                    result.append([])
                    continue
                }
                let creases = 1 + min(max(part.wear, 0), 1) * 1.2
                let chunk = 256
                let chunks = (count + chunk - 1) / chunk
                let values: [Float] = placed.withUnsafeBufferPointer { buffer in
                    let vertices = SharedPointer(buffer.baseAddress!)
                    return TileNoise.parallelRows(chunks, chunk, initial: Float(1)) { c, out in
                        forEachIndex(0..<min(chunk, count - c * chunk)) { k in
                            out[k] = occlusionAt(vertices[c * chunk + k], occupied, dims3, lo3, cell: cell, reach: reach,
                                                 step: step, start: start, steps: steps, creases: creases)
                        }
                    }
                }
                result.append(smoothed(Array(values.prefix(count)), indices: part.geometry.indices))
            }
            return result
        }
    }

    /// `values` (one per vertex) averaged twice with their neighbors along the mesh's edges, which
    /// hides the voxel grid's stair steps.
    static func smoothed(_ values: [Float], indices: [UInt32]) -> [Float] {
        var a = values
        for _ in 0..<2 {
            var sum = a, count = [Float](repeating: 1, count: a.count)
            for t in stride(from: 0, to: indices.count - 2, by: 3) {
                let i = Int(indices[t]), j = Int(indices[t + 1]), k = Int(indices[t + 2])
                sum[i] += a[j] + a[k]; count[i] += 2
                sum[j] += a[i] + a[k]; count[j] += 2
                sum[k] += a[i] + a[j]; count[k] += 2
            }
            for v in a.indices { a[v] = sum[v] / count[v] }
        }
        return a
    }

    /// The occlusion factor at one vertex (model space) from the surface grid.
    private static func occlusionAt(_ v: Point, _ occupied: SharedPointer<UInt8>, _ dims: SIMD3<Int>, _ lo: Vec3,
                                    cell: Float, reach: Float, step: Float, start: Float, steps: Int, creases: Float) -> Float {
        let n = length(v.n) > 1e-6 ? normalize(v.n) : Vec3(0, 1, 0)
        let t = normalize(cross(n, abs(n.x) < 0.9 ? Vec3(1, 0, 0) : Vec3(0, 1, 0)))
        let b = cross(n, t)
        let origin = v.p + n * start
        var occlusion: Float = 0
        let directions = Self.directions
        forEachIndex(0..<directions.count) { di in
            let d = directions[di]
            let dir = t * d.x + b * d.y + n * d.z
            // March until the ray leaves the grid or hits a surface (a counted loop: see ForEachIndex.swift).
            var s = 0
            while s < steps {
                let distance = Float(s) * step
                let p = origin + dir * distance
                let fx = (p.x - lo.x) / cell, fy = (p.y - lo.y) / cell, fz = (p.z - lo.z) / cell
                guard fx >= 0, fy >= 0, fz >= 0 else { break }
                let x = Int(fx), y = Int(fy), z = Int(fz)
                guard x < dims.x, y < dims.y, z < dims.z else { break }
                if occupied[(z * dims.y + y) * dims.x + x] != 0 {
                    let f = 1 - (distance + start) / reach
                    occlusion += 0.35 + 0.65 * max(f, 0)
                    break
                }
                s += 1
            }
        }
        let open = 1 - occlusion / Float(directions.count)
        return powf(max(open, 0), creases)
    }

    /// Writes `occlusion` into the tangents' w (generating tangents first).
    static func store(_ occlusion: [Float], in geometry: inout MeshGeometry) {
        guard occlusion.count == geometry.vertices.count else { return }
        if !geometry.hasTangents { geometry.generateTangents() }
        for i in geometry.vertices.indices {
            let w = geometry.vertices[i].tangent.w
            geometry.vertices[i].tangent.w = (w < 0 ? -1 : 1) * min(max(occlusion[i], 0.05), 1)
        }
    }
}
