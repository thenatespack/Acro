#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
#if canImport(Dispatch)
import Dispatch
#endif
import EngineCore
import EngineScene
import EngineAssets

// Several looks in one sculpt: children can set their own color, look, wear, roughness, metallic,
// glow… The renderer has no vertex colors, so a sculpt with several looks becomes one mesh (and
// material) per look, all from the same surface.
//
// - Look groups (`MeshBuildPart.sculptLookGroups`): a child that sets any look field (color,
//   opacity, texture, textureScale, worldUV, metallic, roughness, glow, glowStrength, material,
//   look, lookScale, wear, grain) uses its own look fields; one that sets none has the sculpt's.
//   Children with the same look fields share a group. Added children own surface; a subtracted
//   or intersected child owns the surface it makes only when it sets a look of its own (a
//   painted hole), else that surface goes to the nearest added child.
// - Ownership: after dual contouring, each surface vertex belongs to the group of the owning
//   child whose surface it is closest to (|distance|, noise included). An edge whose ends belong
//   to different groups is cut where the two groups are equally close (bisection along the edge,
//   then a step onto the surface), and its triangles are split along the cuts (a triangle with
//   three groups gets a center point), so the boundary between colors follows the surface
//   smoothly instead of the triangles' staircase. Cut points are shared by the triangles on both
//   sides, so the pieces meet without cracks; vertices are split where the group changes, so
//   UVs, looks and baked occlusion don't bleed across.
// - The importers (`MeshBuildSculpting.splittingLooks`): a sculpt whose surface has one look
//   keeps its one mesh (with that look's fields); with several, the sculpt part becomes a pivot
//   (still the transform and animation target) and each look is a node under it named
//   "<sculpt>/<first child of that look>" with mesh and material sub-assets of that name.
//   Spatial checks, bounds and `parts(of:)` still see the sculpt as one part with one mesh.

/// A sculpt's mesh with each triangle's look group.
public struct MeshBuildSculptMesh: Sendable {
    public var geometry: MeshGeometry
    /// One per triangle (empty: every triangle is group 0).
    public var triangleGroups: [UInt16]
    public var groupCount: Int

    /// The groups that own triangles, in order.
    public var presentGroups: [Int] {
        guard !triangleGroups.isEmpty else { return geometry.indices.isEmpty ? [] : [0] }
        var seen = [Bool](repeating: false, count: groupCount)
        for g in triangleGroups { seen[Int(g)] = true }
        return seen.indices.filter { seen[$0] }
    }

    /// The triangles of `group` with their own vertices.
    public func submesh(_ group: Int) -> MeshGeometry {
        guard !triangleGroups.isEmpty else { return group == 0 ? geometry : MeshGeometry(vertices: [], indices: []) }
        return triangles { t in Int(triangleGroups[t]) == group }
    }

    /// The triangles `keep` (by triangle number) chooses, with their own vertices (and paint).
    func triangles(where keep: (Int) -> Bool) -> MeshGeometry {
        var result = MeshGeometry(vertices: [], indices: [])
        var remap = [Int32](repeating: -1, count: geometry.vertices.count)
        for t in 0..<geometry.indices.count / 3 where keep(t) {
            for k in 0..<3 {
                let v = Int(geometry.indices[t * 3 + k])
                if remap[v] < 0 {
                    remap[v] = Int32(result.vertices.count)
                    result.append(vertex: geometry.vertices[v], from: geometry, v)
                }
                result.indices.append(UInt32(remap[v]))
            }
        }
        return result
    }
}

/// Which look group each child of a sculpt is in (see the notes at the top of this file).
public struct MeshBuildSculptLookGroups: Sendable, Equatable {
    /// Per `sculptChildren` entry: its group, or -1 when it owns no surface.
    public var childGroups: [Int]
    /// Per group: the child whose look fields it has, or nil for the sculpt's own.
    public var lookSources: [Int?]
    /// Per group: its children (indices into `sculptChildren`).
    public var members: [[Int]]
}

extension MeshBuildPart {
    /// Whether any look field differs from its default (see the notes at the top of this file).
    public var setsLookFields: Bool {
        let d = MeshBuildPart()
        return color != d.color || opacity != d.opacity || texture != d.texture || textureScale != d.textureScale
            || worldUV != d.worldUV || metallic != d.metallic || roughness != d.roughness || glow != d.glow
            || glowStrength != d.glowStrength || material != d.material || look != nil || lookScale != nil || wear != nil
            || grain != nil
    }

    /// The look fields, as text (equal for equal looks).
    var lookFieldsKey: String {
        "\(color)|\(opacity)|\(texture)|\(textureScale)|\(worldUV)|\(metallic)|\(roughness)|\(glow)|\(glowStrength)|\(material)|"
            + "\(String(describing: look))|\(String(describing: lookScale))|\(String(describing: wear))|\(String(describing: grain))"
    }

    /// This part with `other`'s look fields.
    func withLookFields(of other: MeshBuildPart) -> MeshBuildPart {
        var p = self
        (p.color, p.opacity, p.texture, p.textureScale, p.worldUV) = (other.color, other.opacity, other.texture, other.textureScale, other.worldUV)
        (p.metallic, p.roughness, p.glow, p.glowStrength, p.material) = (other.metallic, other.roughness, other.glow, other.glowStrength,
                                                                       other.material)
        (p.look, p.lookScale, p.wear, p.grain) = (other.look, other.lookScale, other.wear, other.grain)
        return p
    }

    /// The look groups of a sculpt's `sculptChildren`.
    public func sculptLookGroups() -> MeshBuildSculptLookGroups {
        var result = MeshBuildSculptLookGroups(childGroups: [], lookSources: [], members: [])
        var byKey: [String: Int] = [:]
        let ownKey = lookFieldsKey
        for (i, child) in sculptChildren.enumerated() {
            let part = child.part
            let sets = part.setsLookFields
            guard part.shape != .group, part.shape != .sculpt, part.shape != .plane, (part.blend ?? .add) == .add || sets else {
                result.childGroups.append(-1)
                continue
            }
            let key = sets ? part.lookFieldsKey : ownKey
            if let g = byKey[key] {
                result.childGroups.append(g)
                result.members[g].append(i)
            } else {
                let g = result.lookSources.count
                byKey[key] = g
                result.lookSources.append(sets && key != ownKey ? i : nil)
                result.members.append([i])
                result.childGroups.append(g)
            }
        }
        return result
    }

    /// The part a sculpt's look group is drawn with: the sculpt's fields with the group's look,
    /// its grain turned into the sculpt's space (from the child whose look it is, or else its first child).
    func sculptLookPart(_ groups: MeshBuildSculptLookGroups, group g: Int) -> MeshBuildPart {
        let source = groups.lookSources[g]
        var part = withLookFields(of: source.map { sculptChildren[$0].part } ?? self)
        guard source != nil || grain == nil, let k = source ?? groups.members[g].first else { return part }
        let child = sculptChildren[k]
        let axis = child.rotation * child.part.lookGrainAxisVector
        let a = Vec3(abs(axis.x), abs(axis.y), abs(axis.z))
        part.grain = a.x >= a.y && a.x >= a.z ? .x : a.y >= a.z ? .y : .z
        return part
    }

    /// The part's grain axis as a unit vector in its space.
    var lookGrainAxisVector: Vec3 {
        var v = Vec3.zero
        v[lookGrainAxis] = 1
        return v
    }
}

// MARK: - Ownership

extension MeshBuildSculptor {
    /// How close `p` is to primitive `i`'s own surface (as the field sees it: noise included).
    @inline(__always) func ownerScore(_ i: Int, _ p: Vec3, bump: Float) -> Float {
        let primitive = primitives[i]
        let d = primitive.distance(p.x, p.y, p.z)
        switch primitive.blend {
        case .add: return abs(d + bump)
        case .subtract: return abs(d - bump)
        case .intersect: return abs(d)
        }
    }

    func bump(_ p: Vec3) -> Float {
        noise.map { $0.amount * Self.fbm(p / $0.scale, seed: $0.seed) } ?? 0
    }

    /// The active list of the grid cell holding `p`.
    private func list(at p: Vec3, active: ActiveLists, origin: Vec3, cell: Float) -> [Int32]? {
        let q = (p - origin) / cell
        return active.list(max(Int(q.x), 0), max(Int(q.y), 0), max(Int(q.z), 0))
    }

    /// The group owning `p`: that of the owning primitive (of `list`, or of all when the list has
    /// none) whose surface is closest.
    private func owner(at p: Vec3, list: [Int32]?) -> Int32 {
        let b = bump(p)
        var best = Float.greatestFiniteMagnitude, group: Int32 = 0
        var found = false
        if let list {
            for i in list where groups[Int(i)] >= 0 {
                let s = ownerScore(Int(i), p, bump: b)
                if s < best { (best, group, found) = (s, groups[Int(i)], true) }
            }
        }
        if !found {
            for i in primitives.indices where groups[i] >= 0 {
                let s = ownerScore(i, p, bump: b)
                if s < best { (best, group) = (s, groups[i]) }
            }
        }
        return group
    }

    /// How much closer `p` is to group `a`'s surface than to group `b`'s (negative: `a` owns it).
    private func preference(_ p: Vec3, _ a: Int32, _ b: Int32) -> Float {
        let bp = bump(p)
        var sa = Float.greatestFiniteMagnitude, sb = Float.greatestFiniteMagnitude
        for i in primitives.indices where groups[i] == a || groups[i] == b {
            let s = ownerScore(i, p, bump: bp)
            if groups[i] == a { sa = min(sa, s) } else { sb = min(sb, s) }
        }
        return sa - sb
    }

    /// `p` moved onto the surface (one Newton step) and the field's normal there.
    private func ontoSurface(_ p: Vec3, active: ActiveLists, origin: Vec3, cell: Float) -> (Vec3, Vec3) {
        let list = list(at: p, active: active, origin: origin, cell: cell)
        var q = p
        let n = normal(at: q, step: cell * 0.25, active: list)
        let f = field(q, active: list)
        if abs(f) < cell * 0.5 { q -= n * f }
        return (q, normal(at: q, step: cell * 0.25, active: list))
    }

    /// Where `splitByOwner` cut a surface: the boundaries between its look groups.
    struct OwnerSplit {
        /// One group per triangle.
        var owners: [Int32]
        /// The group of each surface vertex from before the cuts (vertices 0..<count).
        var vertexGroup: [Int32]
        /// The edges cut, as their two end vertices: cut point `e` is vertex `vertexGroup.count + e`.
        var cutEdges: [SIMD2<Int32>]
        /// The center points of triangles with three groups: (vertex, its three corners' groups).
        var centers: [(Int32, SIMD3<Int32>)]
    }

    /// Gives every triangle of `surface` its look group, cutting triangles along the boundaries
    /// between groups (see the notes at the top of this file).
    func splitByOwner(_ surface: inout Surface, active: ActiveLists, origin: Vec3, cell: Float) -> OwnerSplit {
        let vertexCount = surface.positions.count
        // Each vertex's owner, in parallel.
        var vertexGroup = [Int32](repeating: 0, count: vertexCount)
        let chunk = 256
        surface.positions.withUnsafeBufferPointer { positions in
            vertexGroup.withUnsafeMutableBufferPointer { groupBuffer in
                let out = groupBuffer
                concurrentPerform(iterations: (vertexCount + chunk - 1) / chunk) { c in
                    for v in (c * chunk)..<min((c + 1) * chunk, vertexCount) {
                        let p = positions[v]
                        out[v] = owner(at: p, list: list(at: p, active: active, origin: origin, cell: cell))
                    }
                }
            }
        }
        // The edges whose ends differ, each once (lower vertex first).
        var cutOf: [Int64: Int32] = [:]
        var cutEdges: [SIMD2<Int32>] = []
        @inline(__always) func edgeKey(_ a: Int32, _ b: Int32) -> Int64 { Int64(min(a, b)) * Int64(vertexCount) + Int64(max(a, b)) }
        for t in surface.triangles {
            for (a, b) in [(t.x, t.y), (t.y, t.z), (t.z, t.x)] where vertexGroup[Int(a)] != vertexGroup[Int(b)] {
                let key = edgeKey(a, b)
                if cutOf[key] == nil {
                    cutOf[key] = Int32(vertexCount + cutEdges.count)
                    cutEdges.append(SIMD2(min(a, b), max(a, b)))
                }
            }
        }
        guard !cutEdges.isEmpty else {
            return OwnerSplit(owners: [Int32](repeating: vertexGroup.first ?? 0, count: surface.triangles.count), vertexGroup: vertexGroup,
                              cutEdges: [], centers: [])
        }
        // Where along each cut edge the two groups are equally close, moved onto the surface.
        var cutPoints = [Vec3](repeating: .zero, count: cutEdges.count)
        var cutNormals = [Vec3](repeating: .zero, count: cutEdges.count)
        surface.positions.withUnsafeBufferPointer { positions in
            cutPoints.withUnsafeMutableBufferPointer { pointBuffer in
                cutNormals.withUnsafeMutableBufferPointer { normalBuffer in
                    let points = pointBuffer, normals = normalBuffer
                    concurrentPerform(iterations: (cutEdges.count + chunk - 1) / chunk) { c in
                        for e in (c * chunk)..<min((c + 1) * chunk, cutEdges.count) {
                            let a = Int(cutEdges[e].x), b = Int(cutEdges[e].y)
                            let pa = positions[a], pb = positions[b]
                            let ga = vertexGroup[a], gb = vertexGroup[b]
                            var lo: Float = 0, hi: Float = 1
                            for _ in 0..<10 {
                                let mid = (lo + hi) / 2
                                if preference(pa + (pb - pa) * mid, ga, gb) <= 0 { lo = mid } else { hi = mid }
                            }
                            let t = (lo + hi) / 2
                            (points[e], normals[e]) = ontoSurface(pa + (pb - pa) * t, active: active, origin: origin, cell: cell)
                        }
                    }
                }
            }
        }
        surface.positions += cutPoints
        surface.normals += cutNormals
        // Split the triangles along the cuts, keeping their winding.
        var triangles: [SIMD3<Int32>] = []
        var owners: [Int32] = []
        var centers: [(Int32, SIMD3<Int32>)] = []
        triangles.reserveCapacity(surface.triangles.count + cutEdges.count * 3)
        owners.reserveCapacity(triangles.capacity)
        func emit(_ a: Int32, _ b: Int32, _ c: Int32, _ g: Int32) {
            triangles.append(SIMD3(a, b, c))
            owners.append(g)
        }
        for t in surface.triangles {
            let v = [t.x, t.y, t.z]
            let g = v.map { vertexGroup[Int($0)] }
            if g[0] == g[1] && g[1] == g[2] {
                emit(t.x, t.y, t.z, g[0])
            } else if g[0] != g[1] && g[1] != g[2] && g[0] != g[2] {
                // Three groups: each corner's region runs to the edge cuts and a center point.
                let ab = cutOf[edgeKey(v[0], v[1])]!, bc = cutOf[edgeKey(v[1], v[2])]!, ca = cutOf[edgeKey(v[2], v[0])]!
                let center = (surface.positions[Int(ab)] + surface.positions[Int(bc)] + surface.positions[Int(ca)]) / 3
                let (p, n) = ontoSurface(center, active: active, origin: origin, cell: cell)
                let m = Int32(surface.positions.count)
                surface.positions.append(p)
                surface.normals.append(n)
                centers.append((m, SIMD3(g[0], g[1], g[2])))
                emit(v[0], ab, m, g[0]); emit(v[0], m, ca, g[0])
                emit(ab, v[1], bc, g[1]); emit(ab, bc, m, g[1])
                emit(bc, v[2], ca, g[2]); emit(bc, ca, m, g[2])
            } else {
                // Two groups: corner c is the odd one; a, b, c keeps the triangle's winding.
                let k = g[0] == g[1] ? 2 : g[1] == g[2] ? 0 : 1
                let c = v[k], a = v[(k + 1) % 3], b = v[(k + 2) % 3]
                let bc = cutOf[edgeKey(b, c)]!, ca = cutOf[edgeKey(c, a)]!
                let ga = vertexGroup[Int(a)]
                // The quad a, b, bc, ca along its shorter diagonal.
                let p = surface.positions
                if length(p[Int(a)] - p[Int(bc)]) <= length(p[Int(b)] - p[Int(ca)]) {
                    emit(a, b, bc, ga); emit(a, bc, ca, ga)
                } else {
                    emit(a, b, ca, ga); emit(b, bc, ca, ga)
                }
                emit(bc, c, ca, vertexGroup[Int(c)])
            }
        }
        surface.triangles = triangles
        return OwnerSplit(owners: owners, vertexGroup: vertexGroup, cutEdges: cutEdges, centers: centers)
    }
}

// MARK: - Importers

/// A build with each several-look sculpt split into one part per look (see the notes at the top
/// of this file): what the importers draw.
public struct MeshBuildSculptPieces: Sendable {
    /// The gathered build's parts in the same order, then one part per look of each split sculpt
    /// (a pivot-free node under its sculpt, carrying that look's fields). A one-look sculpt has
    /// its look's fields.
    public var build: MeshBuild
    /// Indices of the parts combined into a sculpt (they draw nothing).
    public var sculpted: Set<Int>
    /// For each look part's index, its sculpt's index.
    public var pieceOf: [Int: Int]
    /// For each look part's name, the sculpt children (and copies) it draws.
    public var owners: [String: [String]]
    /// With blending (`splittingLooks(blending: true)`): per split sculpt's index, how its looks
    /// blend (MeshBuildSculptBlend.swift). Its pieces' and layers' meshes carry group weights in
    /// their paint until `MeshBuildImporter.finishBlends`.
    public var blends: [Int: MeshBuildSculptBlendGroups] = [:]
    /// The blend layers' part indices (each also in `pieceOf`).
    public var layers: Set<Int> = []
    /// The meshes of sculpts and look parts, and the sculpts' warnings.
    var meshes: [Int: MeshGeometry]
    var sculptWarnings: [Int: [String]]

    /// Part `i`'s mesh in its own space (nil for sculpted parts, groups and split sculpts).
    public func geometry(_ i: Int, warnings: inout [String]) -> MeshGeometry? {
        if sculpted.contains(i) { return nil }
        if let produced = sculptWarnings[i] {
            warnings += produced
            return meshes[i]
        }
        if pieceOf[i] != nil { return meshes[i] }
        return build.parts[i].geometry(warnings: &warnings)
    }

    public func geometry(_ i: Int) -> MeshGeometry? {
        var ignored: [String] = []
        return geometry(i, warnings: &ignored)
    }
}

extension MeshBuildSculpting {
    /// The build the importers draw: sculpts with several looks split into a part per look.
    /// `blending`: their looks blend across the boundaries (MeshBuildSculptBlend.swift): blend
    /// layer parts are appended after the looks, and meshes carry group weights in their paint for
    /// `MeshBuildImporter.finishBlends` (without it, meshes have no paint).
    public func splittingLooks(blending: Bool = false) -> MeshBuildSculptPieces {
        var out = MeshBuildSculptPieces(build: build, sculpted: sculpted, pieceOf: [:], owners: [:], meshes: [:], sculptWarnings: [:])
        var names = Set(build.parts.map(\.name))
        for (i, sculpt) in build.parts.enumerated() where sculpt.shape == .sculpt && !sculpted.contains(i) {
            var warnings = sculpt.fieldWarnings
            var mesh = sculpt.sculptMesh(warnings: &warnings)
            out.sculptWarnings[i] = warnings
            if !blending { mesh?.geometry.paint = nil }
            guard let mesh else { continue }
            // Deformers and a mirror copy's reflection apply to each piece as to the whole mesh.
            func finished(_ g: MeshGeometry) -> MeshGeometry {
                var g = g
                if !(sculpt.deform ?? []).isEmpty { g = sculpt.deformed(g) }
                if sculpt.reflection != Vec3(1, 1, 1) { g.scale(by: sculpt.reflection) }
                return g
            }
            let groups = sculpt.sculptLookGroups()
            let present = mesh.presentGroups.filter { $0 < groups.lookSources.count }
            guard present.count > 1 else {
                var whole = mesh.geometry
                whole.paint = nil
                out.meshes[i] = finished(whole)
                if let g = present.first, groups.lookSources[g] != nil { out.build.parts[i] = sculpt.sculptLookPart(groups, group: g) }
                continue
            }
            out.build.parts[i].sculptChildren = []
            var blend = MeshBuildSculptBlendGroups(pieces: Array(repeating: nil, count: groups.lookSources.count),
                                                   layers: Array(repeating: nil, count: groups.lookSources.count), classes: [], blends: [])
            var classOf: [String: Int] = [:]
            for g in groups.lookSources.indices {
                let look = sculpt.sculptLookPart(groups, group: g)
                let key = look.lookTextureKey
                if classOf[key] == nil { classOf[key] = classOf.count }
                blend.classes.append(classOf[key]!)
                blend.blends.append(look.blendsLook)
            }
            func addPart(_ piece: MeshBuildPart, _ geometry: MeshGeometry) -> Int {
                let index = out.build.parts.count
                out.build.parts.append(piece)
                out.meshes[index] = finished(geometry)
                out.pieceOf[index] = i
                return index
            }
            for g in present {
                let first = groups.members[g].first.map { sculpt.sculptChildren[$0].part.name } ?? "\(g + 1)"
                var name = "\(sculpt.name)/\(first)", n = 2
                while names.contains(name) {
                    name = "\(sculpt.name)/\(first) \(n)"
                    n += 1
                }
                names.insert(name)
                var piece = sculpt.sculptLookPart(groups, group: g)
                piece.name = name
                piece.shape = .group
                piece.parent = sculpt.name
                (piece.position, piece.rotation, piece.size, piece.mirror, piece.repetition) = (.zero, .zero, Vec3(1, 1, 1), nil, nil)
                (piece.deform, piece.subdivide, piece.resolution, piece.noise, piece.sculptChildren) = (nil, nil, nil, nil, [])
                piece.reflection = Vec3(1, 1, 1)
                blend.pieces[g] = addPart(piece, mesh.submesh(g))
                out.owners[name] = groups.members[g].map { sculpt.sculptChildren[$0].part.name }
            }
            guard blending, mesh.geometry.paint != nil else { continue }
            // Blend layers: each look over the other looks' textures where it has weight.
            for g in present where blend.blends[g] {
                guard let layer = mesh.blendLayer(group: g, crossFades: { h in
                    present.contains(h) && blend.blends[h] && blend.classes[h] != blend.classes[g]
                }), let base = blend.pieces[g] else { continue }
                var piece = out.build.parts[base]
                var name = piece.name + " blend", n = 2
                while names.contains(name) {
                    name = "\(piece.name) blend \(n)"
                    n += 1
                }
                names.insert(name)
                piece.name = name
                let index = addPart(piece, layer)
                blend.layers[g] = index
                out.layers.insert(index)
            }
            out.blends[i] = blend
        }
        return out
    }
}
