import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// Game-ready plants: wind and detail levels for mesh builds with foliage (a `foliage` part, or a
// leaf look on a ribbon or plane). Both are on by default for such builds and can be turned off
// or tuned in the file:
//
// ```json
// {"parts": [...], "wind": 0.5, "lod": true, "lodDistances": [20, 45, 90]}
// ```
//
// Wind (`Wind.swift`): every swaying part's material gets a `MaterialWind` with the plant's base
// (the model's origin, where it stands on y = 0) and up axis in the part's own space and the
// plant's height, so trunk, branches and leaves bend as one and leaves stay on their branches.
// Leaves (foliage, leaf-look ribbons and planes) flutter fully, sweeps and lofts (trunks,
// branches, stems) bend with only a trace of flutter; other parts (pots, rocks, mounds) stay
// still. Foliage that grows only on surfaces (ivy on a wall) flutters without bending. `wind`
// scales it all (0: still; default 1).
//
// Detail levels (`MeshLOD`), generated at import:
// - level 1: half the foliage cards (a fixed random half, so level 2's are among them), 1.3x
//   larger about their stems; every other part (but sculpts) rebuilt with half the segments and,
//   along sweeps, rings twice as far apart, without the occlusion tessellation (and sweeps and
//   lofts without fine noise deformers); their occlusion is copied from the nearest full-detail
//   vertex;
// - level 2: a quarter of the cards, 1.75x larger, a third of the segments, rings 3x as far apart;
// - level 3: an impostor, three crossed vertical quads textured with the plant rendered from
//   three directions (MeshBuildImpostor.swift), 6 triangles.
// At levels 1 and up, parts with equal materials are merged into one mesh on the first of them
// (the others draw nothing there), so a far plant is a few draws; the impostor hangs on the first
// meshed part with a material of its own (`MeshLOD.materials`). Every part's `MeshLOD` measures
// the camera distance to the same sphere around the whole plant (`MeshLOD.sphere`), so all parts
// switch together. Distances are 8, 16 and 32 times that sphere's radius unless `lodDistances`
// says otherwise. Builds with animations keep their parts separate and get no impostor (moving
// parts would leave a merged mesh or a picture behind).

extension MeshBuild {
    /// The build has foliage or leaf looks: a plant (wind and detail levels on by default).
    public var hasFoliage: Bool { parts.contains { $0.shape == .foliage || $0.resolvedLeafLook != nil } }
    /// Whether the import makes detail levels: `lod`, else on for plants.
    public var makesDetailLevels: Bool { lod ?? hasFoliage }
    /// How much the plant sways: `wind` (finite, 0...4), else 1 for plants and 0 for other builds.
    public var effectiveWind: Float {
        guard let wind else { return hasFoliage ? 1 : 0 }
        return wind.isFinite ? min(max(wind, 0), 4) : 0
    }

    /// Problems with `wind`, `lod` and `lodDistances` (cheap: nothing is built).
    var plantFieldWarnings: [String] {
        var warnings: [String] = []
        if let wind, !(wind.isFinite && wind >= 0) { warnings.append("wind must be a number ≥ 0 (1 = the default sway, 0 = still)") }
        if let lodDistances {
            if lodDistances.isEmpty || lodDistances.count > 3 || !lodDistances.allSatisfy({ $0.isFinite && $0 > 0 })
                || zip(lodDistances, lodDistances.dropFirst()).contains(where: { $0 >= $1 }) {
                warnings.append("lodDistances must be 1 to 3 increasing distances in meters (levels 1, 2 and the impostor)")
            }
            if lod == false { warnings.append("lodDistances is unused with lod false") }
            if lod == nil && !hasFoliage { warnings.append("lodDistances only matters with detail levels: set lod true (plants have them by default)") }
        }
        return warnings
    }
}

/// What the importer knows about a build as a plant: each part's rest placement in the model and
/// the size of the whole (see the notes at the top of this file).
struct MeshBuildPlant {
    /// Each part's rest rotation and translation in the model (parents applied).
    var placements: [(rotation: Quat, translation: Vec3)]
    /// The model's meshes' box in model space.
    var lo: Vec3
    var hi: Vec3
    /// `MeshBuild.effectiveWind`, 0 for builds that aren't plants.
    var windScale: Float

    init(build: MeshBuild, file: MeshBuild, geometries: [MeshGeometry?], firstIndex: [String: Int]) {
        let parts = build.parts
        var placed = [(rotation: Quat, translation: Vec3)?](repeating: nil, count: parts.count)
        func place(_ i: Int, depth: Int) -> (rotation: Quat, translation: Vec3) {
            if let p = placed[i] { return p }
            let part = parts[i]
            var parent = (rotation: Quat.identity, translation: Vec3.zero)
            if !part.parent.isEmpty, let p = firstIndex[part.parent], p != i, depth < parts.count { parent = place(p, depth: depth + 1) }
            let result = (rotation: parent.rotation * Quat(eulerDegrees: part.rotation),
                          translation: parent.rotation * part.position + parent.translation)
            placed[i] = result
            return result
        }
        placements = parts.indices.map { place($0, depth: 0) }
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for (i, g) in geometries.enumerated() {
            guard let g, !g.indices.isEmpty else { continue }
            let (q, t) = placements[i]
            for v in g.vertices {
                let p = q * v.position + t
                lo = pointwiseMin(lo, p)
                hi = pointwiseMax(hi, p)
            }
        }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        self.lo = lo
        self.hi = hi
        windScale = file.hasFoliage ? file.effectiveWind : 0
    }

    /// The center of the model's box.
    var center: Vec3 { (lo + hi) / 2 }
    /// The radius of the sphere around the model's box (at least 0.05 m).
    var radius: Float { max(length(hi - lo) / 2, 0.05) }
    /// How tall the plant stands above its base (y = 0), at least 0.05 m.
    var height: Float { max(hi.y, 0.05) }

    /// Model-space `p` in part `i`'s space.
    func toPart(_ i: Int, _ p: Vec3) -> Vec3 { placements[i].rotation.conjugate * (p - placements[i].translation) }
    /// A model-space direction in part `i`'s space.
    func directionToPart(_ i: Int, _ d: Vec3) -> Vec3 { placements[i].rotation.conjugate * d }

    /// The plant's sphere in part `i`'s space (`MeshLOD.sphere`).
    func sphere(inPart i: Int) -> Vec4 { Vec4(toPart(i, center), radius) }

    /// The detail levels' distances: `requested` (1-3 increasing meters; missing ones double the
    /// last) or 8, 16 and 32 times the plant's radius.
    func lodDistances(_ requested: [Float]?) -> [Float] {
        if let requested, (1...3).contains(requested.count), requested.allSatisfy({ $0.isFinite && $0 > 0 }),
           !zip(requested, requested.dropFirst()).contains(where: { $0 >= $1 }) {
            var out = requested
            while out.count < 3 { out.append(out.last! * 2) }
            return out
        }
        let r = max(radius, 0.4)
        return [8 * r, 16 * r, 32 * r]
    }

    /// The wind of part `i` (see the notes at the top of this file), nil for parts that stay still.
    func wind(forPart i: Int, _ part: MeshBuildPart) -> MaterialWind? {
        guard windScale > 0 else { return nil }
        let leafy = part.shape == .foliage || part.resolvedLeafLook != nil
        guard leafy || part.shape == .sweep || part.shape == .loft else { return nil }
        // Foliage on surfaces only (ivy on a wall) flutters in place.
        let onSurfaces = part.shape == .foliage && !part.foliageTargets.isEmpty && part.foliageTargets.allSatisfy { $0.path.count < 2 }
        return MaterialWind(flutter: (leafy ? 1 : 0.08) * windScale, bend: onSurfaces ? 0 : windScale, height: height,
                            origin: toPart(i, .zero), up: directionToPart(i, Vec3(0, 1, 0)))
    }
}

// MARK: - Levels

enum MeshBuildLOD {
    /// The share of foliage cards levels 1 and 2 keep, and how much larger their cards get.
    static let cardShares: [Float] = [0.5, 0.25]
    static let cardGrowth: [Float] = [1.3, 1.75]
    /// What levels 1 and 2 divide a sweep's or loft's segments by.
    static let segmentDivisors: [Float] = [2, 3]
    /// What levels 1 and 2 multiply the angle between a sweep's rings by (fewer rings along it).
    static let ringSteps: [Float] = [2, 3]

    /// `g`'s cards (quads of 4 vertices and 6 indices, in order, as foliage parts make them;
    /// `quadsPerCard` 2 for crossed tufts) thinned to `share` of them, each grown by `growth`
    /// about its stem (its first two corners), nil if `g` isn't made of such quads. The cards
    /// kept are the ones with the lowest hash of their index and `seed`, so a smaller share keeps a
    /// subset of a larger one's cards (no card pops in when the level drops).
    static func thinnedCards(_ g: MeshGeometry, share: Float, growth: Float, quadsPerCard: Int, seed: UInt64) -> MeshGeometry? {
        let unitVertices = 4 * quadsPerCard, unitIndices = 6 * quadsPerCard
        guard !g.vertices.isEmpty, g.vertices.count % unitVertices == 0, g.indices.count == g.vertices.count / 4 * 6 else { return nil }
        let cards = g.vertices.count / unitVertices
        for c in 0..<cards {
            let first = UInt32(c * unitVertices), last = first + UInt32(unitVertices)
            for k in 0..<unitIndices where !(first..<last).contains(g.indices[c * unitIndices + k]) { return nil }
        }
        let keep = max(Int((Float(cards) * share).rounded()), min(cards, 1))
        let ranked = (0..<cards).sorted { hash(UInt64($0), seed) < hash(UInt64($1), seed) }
        let kept = Set(ranked.prefix(keep))
        var out = MeshGeometry(vertices: [], indices: [])
        out.vertices.reserveCapacity(keep * unitVertices)
        out.indices.reserveCapacity(keep * unitIndices)
        for c in 0..<cards where kept.contains(c) {
            let firstOld = c * unitVertices, firstNew = out.vertices.count
            for q in 0..<quadsPerCard {
                let v = firstOld + q * 4
                let stem = (g.vertices[v].position + g.vertices[v + 1].position) / 2
                for k in 0..<4 {
                    var vertex = g.vertices[v + k]
                    vertex.position = stem + (vertex.position - stem) * growth
                    out.vertices.append(vertex)
                }
            }
            for k in 0..<unitIndices {
                out.indices.append(UInt32(firstNew) + g.indices[c * unitIndices + k] - UInt32(firstOld))
            }
        }
        return out
    }

    /// A fixed pseudo-random 64-bit value of `index` and `seed` (splitmix64).
    static func hash(_ index: UInt64, _ seed: UInt64) -> UInt64 {
        var z = index &+ seed &* 0x9E37_79B9_7F4A_7C15 &+ 0x632B_E59B_D9B4_E019
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Copies each vertex's baked occlusion (`MeshVertex.tangent.w`'s magnitude) from the nearest
    /// vertex of `source` (the full-detail mesh of the same part, same space) into `g`.
    static func transferOcclusion(from source: MeshGeometry, to g: inout MeshGeometry) {
        guard !source.vertices.isEmpty, !g.vertices.isEmpty,
              source.vertices.contains(where: { abs($0.tangent.w) < 0.999 && $0.tangent.w != 0 }) else { return }
        let b = source.bounds
        let cell = max(max(b.halfExtent.x, b.halfExtent.y, b.halfExtent.z) / 16, 1e-3)
        func key(_ p: Vec3) -> SIMD3<Int32> {
            SIMD3(Int32(((p.x - b.center.x) / cell).rounded(.down)), Int32(((p.y - b.center.y) / cell).rounded(.down)),
                  Int32(((p.z - b.center.z) / cell).rounded(.down)))
        }
        var grid: [SIMD3<Int32>: [Int]] = [:]
        for (i, v) in source.vertices.enumerated() { grid[key(v.position), default: []].append(i) }
        var occlusion: [Float] = []
        occlusion.reserveCapacity(g.vertices.count)
        for v in g.vertices {
            let k = key(v.position)
            var best = -1, bestDistance = Float.infinity
            var reach: Int32 = 1
            while best < 0 && reach <= 4 {
                for dz in -reach...reach { for dy in -reach...reach { for dx in -reach...reach {
                    guard let list = grid[k &+ SIMD3(dx, dy, dz)] else { continue }
                    for i in list {
                        let d = source.vertices[i].position - v.position
                        let d2 = dot(d, d)
                        if d2 < bestDistance { bestDistance = d2; best = i }
                    }
                } } }
                reach *= 2
            }
            let w = best >= 0 ? abs(source.vertices[best].tangent.w) : 1
            occlusion.append(w == 0 ? 1 : w)
        }
        MeshBuildAO.store(occlusion, in: &g)
    }

    /// `g` (in the space of a part placed at `from`) in the space of a part placed at `to`.
    static func moved(_ g: MeshGeometry, from: (rotation: Quat, translation: Vec3), to: (rotation: Quat, translation: Vec3)) -> MeshGeometry {
        var out = g
        let turn = to.rotation.conjugate * from.rotation
        for i in out.vertices.indices {
            let v = out.vertices[i]
            out.vertices[i].position = to.rotation.conjugate * (from.rotation * v.position + from.translation - to.translation)
            out.vertices[i].normal = turn * v.normal
            let t = turn * Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
            out.vertices[i].tangent = Vec4(t, v.tangent.w)
        }
        return out
    }

    /// `parts` meshes appended into one.
    static func merged(_ parts: [MeshGeometry]) -> MeshGeometry {
        var out = MeshGeometry(vertices: [], indices: [])
        out.vertices.reserveCapacity(parts.reduce(0) { $0 + $1.vertices.count })
        out.indices.reserveCapacity(parts.reduce(0) { $0 + $1.indices.count })
        for g in parts {
            // Merged meshes need tangents throughout (the renderer only generates them for a mesh without any).
            var g = g
            if !g.hasTangents { g.generateTangents() }
            let base = UInt32(out.vertices.count)
            out.vertices += g.vertices
            out.indices += g.indices.map { $0 + base }
        }
        return out
    }
}

extension MeshBuildPart {
    /// This part's mesh at detail level `level` (1 or 2) in its own space, from its full-detail
    /// `full` (finished: look coordinates, occlusion), or nil when the level keeps `full`. Foliage
    /// thins its cards; sweeps and lofts are rebuilt with fewer segments.
    func detailLevel(_ level: Int, full: MeshGeometry) -> MeshGeometry? {
        let k = min(max(level, 1), 2) - 1
        switch shape {
        case .foliage:
            let look = resolvedLeafLook ?? .broadleaf
            let quads = look.isUpright && foliageTargets.isEmpty ? 2 : 1
            return MeshBuildLOD.thinnedCards(full, share: MeshBuildLOD.cardShares[k], growth: MeshBuildLOD.cardGrowth[k],
                                             quadsPerCard: quads, seed: foliageSeed)
        case .sculpt, .group:
            return nil
        default:
            // Rebuilt with fewer segments (around round shapes and sweeps, and rings along sweeps) and
            // without the occlusion tessellation; kept when that isn't lighter.
            var simpler = self
            simpler.segments = max(Int((Float(min(max(segments, 3), 128)) / MeshBuildLOD.segmentDivisors[k]).rounded()), 3)
            simpler.curveRingStep = MeshBuildLOD.ringSteps[k]
            // A trunk's fine noise is too small to see this far away; bends, twists and tapers keep the shape.
            if let deform, shape == .sweep || shape == .loft {
                simpler.deform = deform.compactMap { d in
                    var d = d
                    d.noise = nil
                    return d.taper == nil && d.bend == nil && d.twist == nil ? nil : d
                }
                if simpler.deform?.isEmpty == true { simpler.deform = nil }
            }
            var ignored: [String] = []
            guard var g = simpler.geometry(warnings: &ignored), !g.indices.isEmpty, g.indices.count < full.indices.count else { return nil }
            if resolvedLook != nil && material.trimmingCharacters(in: .whitespaces).isEmpty { g = applyingLookUVs(to: g) }
            MeshBuildLOD.transferOcclusion(from: full, to: &g)
            if MeshBuildImporter.wearsEdges(self), let look = resolvedLook { MeshBuildEdgeWear.apply(to: &g, wear: wear ?? 0, look: look) }
            return g
        }
    }
}

// MARK: - Import

extension MeshBuildImporter {
    /// Adds detail levels to the meshed nodes of a plant (`MeshBuild.makesDetailLevels`); see the
    /// notes at the top of this file. `geometries` are the parts' finished full-detail meshes,
    /// `materials` the materials made for them (nil for parts using a material asset).
    static func addDetailLevels(file: MeshBuild, build: MeshBuild, plant: MeshBuildPlant, geometries: [MeshGeometry?],
                                materials: [MaterialAsset?], nodes: inout [PrefabNode], asset: inout ImportedAsset,
                                namer: inout SubAssetNamer, context: inout ImportContext) {
        guard file.makesDetailLevels else { return }
        let meshed = nodes.indices.filter { nodes[$0].mesh != nil && geometries[$0] != nil }
        guard !meshed.isEmpty else { return }
        let still = build.animations.isEmpty
        let distances = plant.lodDistances(file.lodDistances)
        // Parts with equal materials (wind anchors aside: each part has its own) merge at levels 1 and up.
        var groups: [[Int]] = []
        if still {
            var keys: [(MaterialAsset?, AssetReference?)] = []
            for i in meshed {
                var key = materials[i]
                if var wind = key?.wind {
                    wind.origin = .zero
                    wind.up = Vec3(0, 1, 0)
                    key?.wind = wind
                }
                let reference = materials[i] == nil ? nodes[i].material : nil
                if let g = keys.firstIndex(where: { $0.0 == key && $0.1 == reference }) {
                    groups[g].append(i)
                } else {
                    keys.append((key, reference))
                    groups.append([i])
                }
            }
        } else {
            groups = meshed.map { [$0] }
        }

        var levelMeshes: [Int: [MeshHandle]] = [:]
        var levelMaterials: [Int: [MaterialHandle]] = [:]
        for level in 1...2 {
            var meshes: [Int: MeshGeometry] = [:]
            for i in meshed {
                if let g = build.parts[i].detailLevel(level, full: geometries[i]!) { meshes[i] = g }
            }
            var empty: Set<Int> = []
            for group in groups where group.count > 1 {
                let host = group[0]
                meshes[host] = MeshBuildLOD.merged(group.map { j in
                    MeshBuildLOD.moved(meshes[j] ?? geometries[j]!, from: plant.placements[j], to: plant.placements[host])
                })
                empty.formUnion(group.dropFirst())
            }
            for i in meshed {
                let handle: MeshHandle
                if empty.contains(i) {
                    handle = MeshHandle("")
                } else if let g = meshes[i] {
                    let name = "\(build.parts[i].name) lod\(level)"
                    let id = namer.id(kind: "mesh", name: name, index: i)
                    asset.add(id, name: name, .mesh(g))
                    handle = MeshHandle(context.reference(id))
                } else {
                    handle = MeshHandle(nodes[i].mesh!)
                }
                levelMeshes[i, default: []].append(handle)
                levelMaterials[i, default: []].append(MaterialHandle(""))
            }
        }

        // The impostor, on the first meshed part.
        if still, let impostor = bakeImpostor(build: build, plant: plant, geometries: geometries, materials: materials, meshed: meshed) {
            let host = meshed[0]
            let stem = "impostor"
            let albedoID = namer.id(kind: "texture", name: "\(stem) albedo", index: 0)
            asset.add(albedoID, name: "\(stem) albedo", .texture(TextureAsset(image: impostor.albedo, isSRGB: true)))
            let normalID = namer.id(kind: "texture", name: "\(stem) normal", index: 0)
            asset.add(normalID, name: "\(stem) normal", .texture(TextureAsset(image: impostor.normal, isSRGB: false)))
            var material = MaterialAsset(shading: .pbr, baseColor: Vec4(1, 1, 1, 1), texture: context.reference(albedoID),
                                         addressMode: .clampToEdge, metallic: 0, roughness: 0.85,
                                         normalTexture: context.reference(normalID), alphaMode: .mask, alphaCutoff: 0.5, doubleSided: true)
            material.translucency = impostor.leafy ? leafTranslucency : 0
            if var wind = plant.wind(forPart: host, build.parts[host]) ?? (plant.windScale > 0 ? MaterialWind(
                flutter: 0, bend: plant.windScale, height: plant.height, origin: plant.toPart(host, .zero),
                up: plant.directionToPart(host, Vec3(0, 1, 0))) : nil) {
                wind.flutter = 0
                material.wind = wind
            }
            let materialID = namer.id(kind: "material", name: stem, index: 0)
            asset.add(materialID, name: stem, .material(material))
            let meshID = namer.id(kind: "mesh", name: stem, index: 0)
            asset.add(meshID, name: stem, .mesh(MeshBuildLOD.moved(impostor.mesh, from: (.identity, .zero), to: plant.placements[host])))
            for i in meshed {
                levelMeshes[i, default: []].append(MeshHandle(i == host ? context.reference(meshID).description : ""))
                levelMaterials[i, default: []].append(MaterialHandle(i == host ? context.reference(materialID).description : ""))
            }
        }

        for i in meshed {
            let meshes = levelMeshes[i] ?? []
            nodes[i].lod = MeshLOD(meshes: meshes, distances: Array(distances.prefix(meshes.count)), hysteresis: 0.1,
                                   materials: levelMaterials[i] ?? [], sphere: plant.sphere(inPart: i))
        }
    }

    /// The impostor of the plant's full-detail meshes (MeshBuildImpostor.swift), nil if it has none.
    private static func bakeImpostor(build: MeshBuild, plant: MeshBuildPlant, geometries: [MeshGeometry?], materials: [MaterialAsset?],
                                     meshed: [Int]) -> MeshBuildImpostor.Baked? {
        var sources: [MeshBuildImpostor.Source] = []
        for i in meshed {
            guard let g = geometries[i] else { continue }
            let part = build.parts[i]
            let material = materials[i]
            let tint = material.map { Vec3($0.baseColor.x, $0.baseColor.y, $0.baseColor.z) } ?? Vec3(repeating: 0.5)
            var source = MeshBuildImpostor.Source(geometry: MeshBuildLOD.moved(g, from: plant.placements[i], to: (.identity, .zero)),
                                                  image: nil, tint: tint, cutoff: nil, leafy: false)
            let plain = part.material.trimmingCharacters(in: .whitespaces).isEmpty && part.texture.trimmingCharacters(in: .whitespaces).isEmpty
            if plain, let leaf = part.resolvedLeafLook {
                source.image = MeshBuildLeafTextures.textures(leaf).albedo
                source.cutoff = leaf.alphaCutoff
                source.leafy = true
            } else if plain, let look = part.resolvedLook {
                source.image = MeshBuildLookTextures.textures(look, wearLevel: MeshBuildLookTextures.wearLevel(part.wear)).albedo
            }
            sources.append(source)
        }
        return MeshBuildImpostor.bake(sources)
    }
}
