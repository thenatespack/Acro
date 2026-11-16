import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Mesh build plants: foliage cards, leaf looks, ribbons and the deformers' triangle budget.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildFoliageTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MeshBuildFoliage")
}

@MainActor private func importBuild(_ build: MeshBuild, _ body: (AssetDatabase, AssetID) throws -> Void) throws {
    let project = try makeProject()
    defer { try? FileManager.default.removeItem(at: project.root) }
    let database = AssetDatabase(project: project)
    let id = try database.createMeshBuild(build, at: "Models/model.meshbuild")
    database.refreshAsync()
    database.waitForAll()
    try body(database, id)
}

private func foliage(_ name: String = "Leaves", look: String = "oakLeaves", size: Vec3 = Vec3(2, 1.5, 2), count: Int? = nil,
                     density: Float? = nil, cardSize: Float? = nil, seed: Int? = nil) -> MeshBuildPart {
    var part = MeshBuildPart(name: name, shape: .foliage, position: Vec3(0, 0.75, 0), size: size, look: look)
    part.count = count
    part.density = density
    part.cardSize = cardSize
    part.seed = seed
    return part
}

private func triangles(_ g: MeshGeometry?) -> Int { (g?.indices.count ?? 0) / 3 }

@Suite(.serialized) struct MeshBuildFoliageTests {
    // MARK: Cards

    @Test func cardsAreDeterministicBySeed() throws {
        let a = try #require(foliage(count: 120, seed: 4).geometry())
        let b = try #require(foliage(count: 120, seed: 4).geometry())
        #expect(a.vertices == b.vertices && a.indices == b.indices, "the same fields make the same cards")
        #expect(triangles(a) == 240 && a.vertices.count == 480, "an outward card is one quad: 2 triangles")
        let other = try #require(foliage(count: 120, seed: 5).geometry())
        #expect(triangles(other) == 240 && other.vertices.map(\.position) != a.vertices.map(\.position), "another seed moves them")
        let renamed = try #require(foliage("Hedge", count: 120, seed: 4).geometry())
        #expect(renamed.vertices.map(\.position) != a.vertices.map(\.position), "the name is part of the seed")
        // Without a count, density and card size set it, still deterministically.
        let dense = triangles(foliage(density: 2).geometry()), sparse = triangles(foliage(density: 0.5).geometry())
        #expect(dense > 3 * sparse && sparse > 0 && dense == triangles(foliage(density: 2).geometry()))
        #expect(triangles(foliage(cardSize: 0.25).geometry()) > 3 * triangles(foliage(cardSize: 0.5).geometry()))
        // Upright looks are crossed tufts: 4 triangles each, standing on the box's floor.
        let grass = try #require(MeshBuildPart(name: "Grass", shape: .foliage, size: Vec3(2, 0.4, 2), look: "grassBlades")
            .withFoliage(count: 50).geometry())
        #expect(triangles(grass) == 200)
        let lowest = grass.vertices.map(\.position.y).min() ?? 0
        #expect(abs(lowest + 0.2) < 1e-4, "tufts stand on the floor of the size box")
    }

    @Test func canopyCardsStayInTheirBoxWithOutwardBentNormals() throws {
        let size = Vec3(3, 2, 2.4)
        let g = try #require(foliage(size: size, seed: 1).geometry())
        let b = g.bounds
        for k in 0..<3 { #expect(b.halfExtent[k] <= size[k] / 2 + 1e-3, "cards stay inside the size box (\(k))") }
        // Normals lean out of the canopy: on average they point away from its center.
        var outward = 0
        for v in g.vertices where dot(v.normal, v.position) > 0 { outward += 1 }
        #expect(Float(outward) / Float(g.vertices.count) > 0.85, "bent normals point outward (\(outward) of \(g.vertices.count))")
        // UVs pick one of the look's four sprigs.
        for v in g.vertices { #expect(v.uv.x >= 0 && v.uv.x <= 1 && v.uv.y >= 0 && v.uv.y <= 1) }
    }

    @Test func triangleBudgetCaps() throws {
        var warnings: [String] = []
        let g = foliage(count: 1_000_000).geometry(warnings: &warnings)
        #expect(triangles(g) == MeshBuildPart.maxFoliageTriangles)
        #expect(warnings.contains { $0.contains("capped") }, "\(warnings)")
        var upright: [String] = []
        let tufts = MeshBuildPart(name: "Grass", shape: .foliage, size: Vec3(50, 0.3, 50), look: "grassBlades").geometry(warnings: &upright)
        #expect(triangles(tufts) <= MeshBuildPart.maxFoliageTriangles && upright.contains { $0.contains("capped") })
    }

    @Test func foliageGrowsOnNamedSweepsAndTheirCopies() throws {
        var branch = MeshBuildPart(name: "Branch", shape: .sweep, position: Vec3(0, 1, 0),
                                   path: [Vec3(0, 0, 0), Vec3(0.8, 0.4, 0), Vec3(1.5, 0.6, 0)], radius: 0.05, radii: [1, 0.6, 0.2])
        branch.repetition = MeshBuildRepeat(count: 3, radial: MeshBuildRepeat.Radial(axis: .y))
        var leaves = MeshBuildPart(name: "Leaves", shape: .foliage, position: Vec3(0.3, 0.2, 0), look: "broadleaf")
        leaves.on = ["Branch"]
        leaves.count = 90
        let trunk = MeshBuildPart(name: "Trunk", shape: .cylinder, position: Vec3(0, 0.6, 0), size: Vec3(0.2, 1.2, 0.2))
        let build = MeshBuild(parts: [trunk, branch, leaves])
        let expansion = build.expansion()
        let gathered = expansion.build.gatheringSculpts(sources: expansion.sources).build
        let placed = try #require(gathered.parts.first { $0.name == "Leaves" })
        #expect(placed.foliageTargets.count == 3, "the repeat copies are targets too")
        let g = try #require(placed.geometry())
        #expect(triangles(g) == 180)
        // Every card is near one of the branches (in the model: leaves' position + vertex).
        let spines = gathered.parts.filter { $0.shape == .sweep }.map { part -> [Vec3] in
            let q = Quat(eulerDegrees: part.rotation)
            return (part.sweepSpine()?.points ?? []).map { q * $0 + part.position }
        }
        for v in g.vertices {
            let p = v.position + placed.position
            let nearest = spines.flatMap { $0 }.map { length($0 - p) }.min() ?? .infinity
            #expect(nearest < 0.75, "a card corner \(nearest) m from the branches")
        }
        // A missing name warns and grows nothing there.
        var lost = leaves
        lost.on = ["Nope"]
        var warnings: [String] = []
        let alone = MeshBuild(parts: [trunk, lost]).gatheringSculpts().build.parts[1]
        #expect(alone.geometry(warnings: &warnings) == nil && warnings.contains { $0.contains("'Nope'") }, "\(warnings)")
    }

    @Test func foliageFieldWarnings() {
        func warns(_ part: MeshBuildPart, _ text: String) {
            #expect(part.fieldWarnings.contains { $0.contains(text) }, "\(part.fieldWarnings) should mention \(text)")
        }
        var box = MeshBuildPart(name: "Box")
        box.density = 2
        warns(box, "density only shape foliage")
        var wrongLook = foliage(look: "grass")
        warns(wrongLook, "grassBlades")
        wrongLook.look = "oak"
        #expect(wrongLook.fieldWarnings.isEmpty, "aliases work: \(wrongLook.fieldWarnings)")
        var ribbonBox = MeshBuildPart(name: "Box")
        ribbonBox.ribbon = 0.1
        warns(ribbonBox, "ribbon only shape sweep")
        #expect(foliage().fieldWarnings.isEmpty && MeshBuildPart(name: "Leaf", shape: .plane, look: "fern").fieldWarnings.isEmpty)
        #expect(MeshBuildPart(name: "Box", look: "fern").fieldWarnings.contains { $0.contains("one sprig") })
    }

    // MARK: Leaf looks and materials

    @MainActor @Test func leafTexturesHaveAlphaAndCutoutMaterials() throws {
        for look in MeshBuildLeafLook.allCases {
            let t = MeshBuildLeafTextures.textures(look, resolution: 64)
            #expect(t.albedo.width == 64 && t.normal.width == 64 && t.orm.width == 64)
            let alphas = stride(from: 3, to: t.albedo.pixels.count, by: 4).map { t.albedo.pixels[$0] }
            #expect(alphas.contains(0) && (alphas.max() ?? 0) > 220, "\(look): leaves on a transparent background")
            #expect(t.coverage > 0.03 && t.coverage < 0.8, "\(look) covers \(t.coverage)")
            #expect(MeshBuildLeafLook.named(look.rawValue) == look && MeshBuildLook.named(look.rawValue) == nil)
        }
        #expect(MeshBuildLeafLook.named("Pine needles") == .pineNeedles && MeshBuildLeafLook.named("ivy leaves") == .ivy)
        #expect(MeshBuildLeafTextures.textures(.fern, resolution: 64).albedo.pixels == MeshBuildLeafPainter.paint(.fern, resolution: 64).albedo.pixels, "deterministic")

        var ribbon = MeshBuildPart(name: "Frond", shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 0.5, 0.2)], look: "fern")
        ribbon.ribbon = 0.2
        let tinted = foliage("Tinted", count: 10).with(color: Vec3(0.6, 0.4, 0.1))
        try importBuild(MeshBuild(parts: [foliage(count: 30), ribbon, tinted])) { database, id in
            let objects = database.record(id)?.objects ?? []
            @MainActor func material(_ name: String) -> MaterialAsset? { database.material(AssetReference(id, subAsset: "material/\(name)")) }
            for name in ["Leaves", "Frond", "Tinted"] {
                let m = try #require(material(name), "\(name)")
                #expect(m.alphaMode == .mask && m.doubleSided && m.translucency > 0, "\(name): alpha-cutout, double-sided, translucent")
                #expect(m.alphaCutoff > 0.2 && m.alphaCutoff < 0.6 && m.texture != nil && m.normalTexture != nil)
                #expect(m.metallicRoughnessTexture != nil && m.occlusionTexture != nil)
            }
            #expect(material("Leaves")?.baseColor == Vec4(1, 1, 1, 1), "the default color keeps the look's own")
            #expect(material("Tinted")?.baseColor != Vec4(1, 1, 1, 1), "color tints it")
            // One texture set per leaf look, shared by its parts.
            let leafTextures = objects.filter { $0.kind == .texture && $0.id.contains("leaves") }
            #expect(leafTextures.count == 6, "oak and fern: albedo, normal and ORM each (\(leafTextures.map(\.id)))")
            // Foliage cards aren't split for the baked occlusion, but they get it.
            let mesh = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Leaves")))
            #expect(mesh.indices.count / 3 == 60)
            #expect(mesh.vertices.contains { abs($0.tangent.w) < 0.999 }, "baked occlusion darkens the inner cards")
        }
    }

    // MARK: Ribbons

    @Test func openRibbonsAreDoubleSidedAndUncapped() throws {
        var ribbon = MeshBuildPart(name: "Blade", shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0.02, 0.3, 0), Vec3(0.1, 0.5, 0.05)])
        ribbon.ribbon = 0.04
        let g = try #require(ribbon.geometry())
        // Two columns (one strip): every triangle is part of the strip, none caps an end.
        #expect(g.vertices.count % 2 == 0 && g.indices.count / 3 == g.vertices.count - 2, "a strip of quads, no caps")
        #expect(!MeshBuildSpatialProbe.isClosed(g), "an open surface")
        let width = g.vertices[1].position - g.vertices[0].position
        #expect(abs(length(width) - 0.04) < 1e-4, "as wide as `ribbon` at a radii of 1")
        #expect(MeshBuildImporter.material(for: ribbon, texture: nil).doubleSided)
        // An open profile: a V-fold, also uncapped; the same path as a tube has caps.
        var fold = ribbon
        fold.ribbon = nil
        fold.open = true
        fold.profile = [Vec2(-0.02, 0.01), Vec2(0, 0), Vec2(0.02, 0.01)]
        let v = try #require(fold.geometry())
        #expect(v.indices.count / 3 == (v.vertices.count / 4 - 1) * 4 || v.indices.count / 3 < v.vertices.count, "no caps")
        #expect(fold.isRibbon && MeshBuildImporter.material(for: fold, texture: nil).doubleSided)
        var tube = fold
        tube.open = nil
        let closedTube = try #require(tube.geometry())
        #expect(MeshBuildSpatialProbe.isClosed(closedTube) && !MeshBuildImporter.material(for: tube, texture: nil).doubleSided)
        // A leaf look runs once along the ribbon, inside one sprig of the texture.
        var frond = ribbon
        frond.look = "fern"
        let f = try #require(frond.geometry())
        let us = f.vertices.map(\.uv.x), vs = f.vertices.map(\.uv.y)
        #expect((us.max()! - us.min()!) <= 0.5 + 1e-5 && (vs.max()! - vs.min()!) > 0.49 && (vs.max()! - vs.min()!) <= 0.5 + 1e-5)
        // Bad fields warn.
        var bad = ribbon
        bad.ribbon = nil
        bad.open = true
        #expect(bad.fieldWarnings.contains { $0.contains("open needs a profile") })
    }

    // MARK: Deformer budget

    @Test func noiseSubdivisionRespectsItsBudget() throws {
        // Fine noise on a big part: the budget stops the splitting, the fine lumps fade and it warns.
        let trunk = MeshBuildPart(name: "Trunk", shape: .cylinder, size: Vec3(0.6, 4, 0.6), deform: [.noise(0.03, scale: 0.05)])
        var warnings: [String] = []
        let g = try #require(trunk.geometry(warnings: &warnings))
        #expect(g.indices.count / 3 <= MeshBuildPart.maxDeformTriangles)
        #expect(warnings.contains { $0.contains("budget") }, "\(warnings)")
        // The surface stays close to the cylinder (the unrepresentable octaves fade instead of spiking).
        let r = g.vertices.map { ($0.position.x * $0.position.x + $0.position.z * $0.position.z).squareRoot() }
        #expect((r.max() ?? 0) < 0.3 + 0.06, "no spikes: \(r.max() ?? 0)")
        // Noise the budget can show: no warning, and the subdivision follows the noise scale.
        let rock = MeshBuildPart(name: "Rock", shape: .sphere, size: Vec3(1.2, 1, 1.2), deform: [.noise(0.03, scale: 0.15)])
        var quiet: [String] = []
        let small = try #require(rock.geometry(warnings: &quiet))
        #expect(quiet.isEmpty && small.indices.count / 3 <= MeshBuildPart.maxDeformTriangles, "\(quiet)")
        let coarse = MeshBuildPart(name: "Rock", shape: .sphere, size: Vec3(1.2, 1, 1.2), deform: [.noise(0.03, scale: 0.6)])
        #expect(triangles(coarse.geometry()) < triangles(small), "larger lumps need fewer triangles")
    }
}

/// The spatial checks' closed-surface test, reimplemented for the engine tests (it lives in EditorCore).
enum MeshBuildSpatialProbe {
    static func isClosed(_ g: MeshGeometry) -> Bool {
        var ids: [SIMD3<Int32>: Int] = [:]
        func id(_ p: Vec3) -> Int {
            let key = SIMD3<Int32>(Int32((p.x * 1e4).rounded()), Int32((p.y * 1e4).rounded()), Int32((p.z * 1e4).rounded()))
            if let id = ids[key] { return id }
            ids[key] = ids.count
            return ids.count - 1
        }
        var edges: [SIMD2<Int>: Int] = [:]
        for t in stride(from: 0, to: g.indices.count - 2, by: 3) {
            let v = (0..<3).map { id(g.vertices[Int(g.indices[t + $0])].position) }
            guard v[0] != v[1], v[1] != v[2], v[0] != v[2] else { continue }
            for k in 0..<3 { edges[SIMD2(min(v[k], v[(k + 1) % 3]), max(v[k], v[(k + 1) % 3])), default: 0] += 1 }
        }
        return !edges.isEmpty && edges.values.allSatisfy { $0 % 2 == 0 }
    }
}

private extension MeshBuildPart {
    func withFoliage(count: Int) -> MeshBuildPart {
        var p = self
        p.count = count
        return p
    }

    func with(color: Vec3) -> MeshBuildPart {
        var p = self
        p.color = color
        return p
    }
}
