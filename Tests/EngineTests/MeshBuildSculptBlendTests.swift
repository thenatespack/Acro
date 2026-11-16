import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Blending between a sculpt's looks (MeshBuildSculptBlend.swift, MeshBuildImporter+Blends.swift),
// vertex paint (VertexPaint.swift) and leaf card variation.

private func gathered(_ parts: [MeshBuildPart]) -> MeshBuildSculpting { MeshBuild(parts: parts).gatheringSculpts() }

private func key(_ p: Vec3) -> SIMD3<Int> {
    SIMD3(Int((p.x * 1e4).rounded()), Int((p.y * 1e4).rounded()), Int((p.z * 1e4).rounded()))
}

/// A position's exact bits (pieces and layers copy positions exactly).
private func exact(_ p: Vec3) -> SIMD3<UInt32> { SIMD3(p.x.bitPattern, p.y.bitPattern, p.z.bitPattern) }

/// A red box with a blue ball melted onto its top (`smooth` m), optionally with looks of their own.
private func twoColors(smooth: Float = 0.08, bodyLook: String? = nil, ballLook: String? = nil) -> [MeshBuildPart] {
    var ball = MeshBuildPart(name: "Ball", shape: .sphere, parent: "Sculpt", position: Vec3(0, 0.45, 0), size: Vec3(0.6, 0.6, 0.6),
                             color: Vec3(0.1, 0.2, 0.9), look: ballLook)
    ball.smooth = smooth
    return [MeshBuildPart(name: "Sculpt", shape: .sculpt, color: Vec3(0.8, 0.8, 0.8)),
            MeshBuildPart(name: "Body", shape: .box, parent: "Sculpt", size: Vec3(1, 0.6, 0.8), color: Vec3(0.9, 0.1, 0.1), look: bodyLook),
            ball]
}

private func merged(_ meshes: [MeshGeometry]) -> MeshGeometry {
    var g = MeshGeometry(vertices: [], indices: [])
    for m in meshes {
        let base = UInt32(g.vertices.count)
        g.vertices += m.vertices
        g.indices += m.indices.map { $0 + base }
    }
    return g
}

/// Closed and consistently wound when welded by position.
private func isClosedAndOriented(_ g: MeshGeometry) -> Bool {
    var ids: [SIMD3<Int>: Int] = [:]
    let welded = g.vertices.map { v -> Int in
        if let id = ids[key(v.position)] { return id }
        ids[key(v.position)] = ids.count
        return ids.count - 1
    }
    var edges: [SIMD2<Int>: Int] = [:]
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = welded[Int(g.indices[t])], b = welded[Int(g.indices[t + 1])], c = welded[Int(g.indices[t + 2])]
        guard a != b, b != c, a != c else { continue }
        for (p, q) in [(a, b), (b, c), (c, a)] { edges[SIMD2(p, q), default: 0] += 1 }
    }
    return !edges.isEmpty && edges.allSatisfy { edge, count in edges[SIMD2(edge.y, edge.x)] == count }
}

/// Imports `build` into a fresh project and returns the database and the asset id.
@MainActor private func imported(_ build: MeshBuild, _ body: (AssetDatabase, AssetID) throws -> Void) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptBlendTests-\(UUID().uuidString)", isDirectory: true)
    let project = try Project.create(at: url, name: "Blend")
    defer { try? FileManager.default.removeItem(at: project.root) }
    let database = AssetDatabase(project: project)
    let id = try database.createMeshBuild(build, at: "Models/toy.meshbuild")
    database.refreshAsync()
    database.waitForAll()
    #expect(database.reimport(id).warnings.isEmpty)
    try body(database, id)
}

@Suite(.serialized) struct MeshBuildSculptBlendTests {
    @Test func weightIsHalfOnTheBoundaryAndFadesAcrossTheBand() throws {
        #expect(MeshBuildSculptBlend.across(0) == 0.5 && MeshBuildSculptBlend.across(1) == 0 && MeshBuildSculptBlend.across(-1) == 1)
        #expect(MeshBuildSculptBlend.across(2) == 0 && abs(MeshBuildSculptBlend.across(0.5) - 0.15625) < 1e-6)
        #expect(MeshBuildSculptBlend.halfWidth(smooth: 0) == 0, "a sharp join keeps its line")
        #expect(MeshBuildSculptBlend.halfWidth(smooth: 0.001) == MeshBuildSculptBlend.minimumBand)
        #expect(MeshBuildSculptBlend.halfWidth(smooth: 0.08) == 0.08 * MeshBuildSculptBlend.bandScale)

        MeshBuildSculptCache.shared.removeAll()
        let pieces = gathered(twoColors()).splittingLooks(blending: true)
        let body = try #require(pieces.geometry(3)), ball = try #require(pieces.geometry(4))
        let bodyPaint = try #require(body.paint), ballPaint = try #require(ball.paint)
        // The boundary: points the two pieces share, weighing both groups 0.5.
        let ballKeys = Set(ball.vertices.map { key($0.position) })
        let boundary = body.vertices.indices.filter { ballKeys.contains(key(body.vertices[$0].position)) }
        #expect(boundary.count > 20)
        for v in boundary {
            #expect(MeshBuildSculptBlend.weight(bodyPaint[v], group: 0) == 0.5 && MeshBuildSculptBlend.weight(bodyPaint[v], group: 1) == 0.5)
        }
        let boundaryPoints = boundary.map { body.vertices[$0].position }
        let h = MeshBuildSculptBlend.halfWidth(smooth: 0.08)
        // Elsewhere the other group's weight follows the distance to the boundary along the surface:
        // never more than at the straight-line distance (the surface path is longer), 0 beyond the band.
        var inside = 0, nearHalf = 0
        for (g, paint, other) in [(body, bodyPaint, 1), (ball, ballPaint, 0)] {
            for v in g.vertices.indices where !boundary.isEmpty {
                let p = g.vertices[v].position
                let d = boundaryPoints.map { length($0 - p) }.min()!
                let w = MeshBuildSculptBlend.weight(paint[v], group: other)
                let own = MeshBuildSculptBlend.weight(paint[v], group: 1 - other)
                #expect(w <= MeshBuildSculptBlend.across(d / h) + 0.02, "weight \(w) at \(d) m from the boundary")
                if d > h * 1.001 { #expect(w == 0) }
                if w > 0 {
                    #expect(abs(w + own - 1) < 1e-5, "the two weights add up to 1")
                    inside += 1
                    if d < h * 0.25 && w > 0.3 { nearHalf += 1 }
                }
            }
        }
        #expect(inside > boundary.count, "the band reaches past the boundary on both sides")
        #expect(nearHalf > 10, "close to the boundary the weight stays near 0.5")
    }

    @Test func sharpJoinsAndOneLookHaveNoPaint() throws {
        MeshBuildSculptCache.shared.removeAll()
        let sharp = gathered(twoColors(smooth: 0)).splittingLooks(blending: true)
        #expect(sharp.geometry(3)?.paint == nil && sharp.geometry(4)?.paint == nil && sharp.layers.isEmpty)
        // Without blending (other importers) no mesh carries paint either.
        let plain = gathered(twoColors()).splittingLooks()
        #expect(plain.geometry(3)?.paint == nil && plain.geometry(4)?.paint == nil && plain.blends.isEmpty)
        #expect(gathered(twoColors()).build.parts[0].geometry()?.paint == nil, "the whole sculpt's mesh has none")
        // Plain parts and primitives never do.
        #expect(MeshBuildPart(name: "Box").geometry()?.paint == nil && MeshGeometry.cube().paint == nil)
    }

    @Test func differentTexturesCrossFadeWithComplementaryLayers() throws {
        MeshBuildSculptCache.shared.removeAll()
        let parts = twoColors(bodyLook: "stone", ballLook: "fabric")
        let pieces = gathered(parts).splittingLooks(blending: true)
        #expect(pieces.build.parts.map(\.name) == ["Sculpt", "Body", "Ball", "Sculpt/Body", "Sculpt/Ball", "Sculpt/Body blend",
                                                    "Sculpt/Ball blend"])
        #expect(pieces.layers == [5, 6] && pieces.pieceOf[5] == 0 && pieces.pieceOf[6] == 0)
        #expect(pieces.build.parts[5].look == "stone" && pieces.build.parts[6].look == "fabric")
        let blend = try #require(pieces.blends[0])
        #expect(blend.pieces == [3, 4] && blend.layers == [5, 6] && blend.classes == [0, 1] && blend.blends == [true, true])
        // Each layer lies on the other look's piece: every layer triangle is one of its triangles, and
        // at every layer vertex the layer's opacity and the piece's own weight add up to 1.
        for (layer, piece, group) in [(5, 4, 0), (6, 3, 1)] {
            let l = try #require(pieces.geometry(layer)), p = try #require(pieces.geometry(piece))
            let lp = try #require(l.paint), pp = try #require(p.paint)
            func triangles(_ g: MeshGeometry) -> Set<[SIMD3<Int>]> {
                Set(stride(from: 0, to: g.indices.count, by: 3).map { t in (0..<3).map { key(g.vertices[Int(g.indices[t + $0])].position) } })
            }
            #expect(!l.indices.isEmpty && triangles(l).isSubset(of: triangles(p)))
            var weightAt: [SIMD3<UInt32>: Float] = [:]
            for (v, vertex) in p.vertices.enumerated() { weightAt[exact(vertex.position)] = MeshBuildSculptBlend.weight(pp[v], group: 1 - group) }
            var someFull = false
            for (v, vertex) in l.vertices.enumerated() {
                let alpha = MeshBuildSculptBlend.weight(lp[v], group: group), base = try #require(weightAt[exact(vertex.position)])
                #expect(abs(alpha + base - 1) < 1e-5 || (alpha == 0 && base == 0))
                if alpha >= 0.5 { someFull = true }
            }
            #expect(someFull, "the layer reaches half opacity on the boundary")
        }
    }

    @Test func blendedPiecesMeetWithoutCracks() throws {
        MeshBuildSculptCache.shared.removeAll()
        for parts in [twoColors(), twoColors(bodyLook: "stone", ballLook: "fabric")] {
            let pieces = gathered(parts).splittingLooks(blending: true)
            let looks = [3, 4].compactMap { pieces.geometry($0) }
            #expect(looks.count == 2 && isClosedAndOriented(merged(looks)))
            // Pieces and layers carry one paint per vertex.
            for i in pieces.pieceOf.keys { #expect(pieces.geometry(i)?.paint?.count == pieces.geometry(i)?.vertices.count) }
        }
    }

    @MainActor @Test func importerPaintsTheBlendAndRoundTripsIt() throws {
        MeshBuildSculptCache.shared.removeAll()
        try imported(MeshBuild(parts: twoColors())) { database, id in
            let body = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Sculpt/Body")))
            let ball = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Sculpt/Ball")))
            let bodyMaterial = try #require(database.material(AssetReference(id, subAsset: "material/Sculpt/Body")))
            let ballMaterial = try #require(database.material(AssetReference(id, subAsset: "material/Sculpt/Ball")))
            let red = MeshBuildColor.linear(fromSRGB: Vec3(0.9, 0.1, 0.1)), blue = MeshBuildColor.linear(fromSRGB: Vec3(0.1, 0.2, 0.9))
            // The material holds the largest value of each channel (its own color or the boundary's
            // halfway mix); the paint scales down to each vertex's.
            #expect(length(Vec3(bodyMaterial.baseColor.x, bodyMaterial.baseColor.y, bodyMaterial.baseColor.z)
                           - pointwiseMax(red, (red + blue) / 2)) < 1e-4)
            try #require(body.paint != nil && ball.paint != nil)
            func color(_ g: MeshGeometry, _ m: MaterialAsset, _ v: Int) -> Vec3 {
                Vec3(m.baseColor.x, m.baseColor.y, m.baseColor.z) * Vec3(g.paint![v].color.x, g.paint![v].color.y, g.paint![v].color.z)
            }
            // On the boundary both pieces have the same color, halfway; far from it, their own.
            let ballKeys = Dictionary(ball.vertices.enumerated().map { (exact($0.element.position), $0.offset) }, uniquingKeysWith: { a, _ in a })
            var shared = 0
            for v in body.vertices.indices {
                guard let u = ballKeys[exact(body.vertices[v].position)] else { continue }
                shared += 1
                #expect(length(color(body, bodyMaterial, v) - color(ball, ballMaterial, u)) < 1e-4)
                #expect(length(color(body, bodyMaterial, v) - (red + blue) / 2) < 1e-4)
            }
            #expect(shared > 20)
            let bottom = try #require(body.vertices.indices.min { body.vertices[$0].position.y < body.vertices[$1].position.y })
            #expect(length(color(body, bodyMaterial, bottom) - red) < 1e-4)
            // Round trip through the import cache: the paint comes back exactly.
            let asset = try #require(database.asset(id))
            let (manifest, files) = AssetArtifacts.encode(asset)
            let decoded = try #require(AssetArtifacts.decode(manifest) { files[$0] })
            let again = try #require(decoded.object("mesh/Sculpt/Body", kind: .mesh))
            guard case .mesh(let g) = again.value else { Issue.record("not a mesh"); return }
            #expect(g.paint != nil && g.paint == body.paint && g.vertices == body.vertices && g.indices == body.indices)
            // A mesh without paint stores none.
            let plain = ImportedAsset(objects: [ImportedObject(id: "mesh/a", name: "a", value: .mesh(.cube()))])
            let (plainManifest, plainFiles) = AssetArtifacts.encode(plain)
            #expect(plainManifest.objects.first?.painted == nil)
            guard case .mesh(let cube)? = AssetArtifacts.decode(plainManifest, file: { plainFiles[$0] })?.objects.first?.value else {
                Issue.record("not a mesh")
                return
            }
            #expect(cube.paint == nil)
        }
    }

    @MainActor @Test func importerAddsBlendLayersForDifferentTextures() throws {
        MeshBuildSculptCache.shared.removeAll()
        try imported(MeshBuild(parts: twoColors(bodyLook: "stone", ballLook: "fabric"))) { database, id in
            let layer = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Sculpt/Ball blend")))
            let material = try #require(database.material(AssetReference(id, subAsset: "material/Sculpt/Ball blend")))
            #expect(material.alphaMode == .blend && material.edgeWear == nil && material.normalTexture != nil)
            let alphas = try #require(layer.paint).map(\.color.w)
            #expect(alphas.allSatisfy { $0 >= 0 && $0 <= 0.5 + 1e-5 } && alphas.contains { $0 == 0.5 } && alphas.contains { $0 < 0.1 })
            // Different textures: the pieces don't mix colors in their paint (the layers cross-fade them).
            let body = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Sculpt/Body")))
            #expect(body.paint == nil)
            // The layer copies the occlusion of the surface it lies on.
            let piece = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Sculpt/Body")))
            var occlusion: [SIMD3<UInt32>: Float] = [:]
            for v in piece.vertices { occlusion[exact(v.position)] = abs(v.tangent.w) }
            var copied = 0
            for v in layer.vertices {
                guard let o = occlusion[exact(v.position)] else { continue }
                #expect(abs(abs(v.tangent.w) - o) < 1e-5)
                copied += 1
            }
            #expect(copied == layer.vertices.count, "every layer vertex lies on the body's surface")
        }
    }

    @Test func leafCardVariationIsDeterministicAndSubtle() throws {
        func cards(seed: Int) throws -> MeshGeometry {
            var part = MeshBuildPart(name: "Crown", shape: .foliage, size: Vec3(2, 2, 2), look: "oakLeaves")
            part.count = 60
            part.seed = seed
            return try #require(part.geometry())
        }
        let a = try cards(seed: 3), b = try cards(seed: 3), c = try cards(seed: 4)
        let paint = try #require(a.paint)
        #expect(paint.count == a.vertices.count && a.paint == b.paint && a.paint != c.paint)
        // One color per card (its 4 corners), differing between cards, within ±15%.
        for card in 0..<paint.count / 4 {
            let p = paint[card * 4]
            #expect((1..<4).allSatisfy { paint[card * 4 + $0] == p })
            for k in 0..<3 { #expect(p.color[k] > 0.8 && p.color[k] < 1.2) }
            #expect(p.color.w == 1 && p.surface.y == 1 && p.surface.z == 1)
        }
        #expect(Set(stride(from: 0, to: paint.count, by: 4).map { paint[$0].color.x }).count > 50)
    }

    @Test func sculptBlendingStaysFastOnADenseSculpt() throws {
        MeshBuildSculptCache.shared.removeAll()
        var parts = twoColors()
        parts[0].resolution = 128
        let start = Date()
        let pieces = gathered(parts).splittingLooks(blending: true)
        let elapsed = Date().timeIntervalSince(start)
        let triangles = [3, 4].compactMap { pieces.geometry($0) }.map { $0.indices.count / 3 }.reduce(0, +)
        #expect(triangles > 50_000)
        #expect(elapsed < 20, "a \(triangles)-triangle two-look sculpt took \(elapsed) s")
        // The blend pass alone (band widths, Dijkstra, weights) on the split surface: a small part of it.
        let sculpt = try #require(gathered(parts).build.parts.first)
        var warnings: [String] = []
        let sculptor = try #require(MeshBuildSculptor(sculpt: sculpt, groups: sculpt.sculptLookGroups().childGroups, warnings: &warnings))
        let extent = sculptor.hi - sculptor.lo
        let cell = max(extent.x, extent.y, extent.z) / Float(sculptor.resolution)
        let origin = sculptor.lo - Vec3(repeating: cell * 2)
        let n = SIMD3<Int>(Int((extent.x / cell).rounded(.up)) + 5, Int((extent.y / cell).rounded(.up)) + 5, Int((extent.z / cell).rounded(.up)) + 5)
        let (values, active) = sculptor.sample(origin: origin, cell: cell, n: n)
        var surface = try #require(sculptor.contour(values, active: active, origin: origin, cell: cell, n: n, warnings: &warnings))
        let split = sculptor.splitByOwner(&surface, active: active, origin: origin, cell: cell)
        let blendStart = Date()
        let weights = sculptor.blendWeights(surface, split)
        let blendTime = Date().timeIntervalSince(blendStart)
        #expect(weights?.count == surface.positions.count)
        #expect(blendTime < elapsed / 4, "blending \(surface.triangles.count) triangles took \(blendTime) s")
        print("sculpt blend timing: \(triangles) triangles meshed, split and blended in \(String(format: "%.2f", elapsed)) s; "
              + "the blend pass alone \(String(format: "%.3f", blendTime)) s for \(surface.triangles.count) triangles")
    }
}
