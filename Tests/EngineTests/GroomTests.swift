import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// Fur and hair (GroomBuild.swift, Groom.swift, GroomGeometry.swift, GroomFins.swift, GroomImporter.swift, RenderPrep+Fur.swift):
// the file format, the fur meshes, the importer and its hooks in mesh builds, characters and
// terrain scatter, and the render items (instanced shells, detail levels, skinned batches).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("GroomTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Groom")
}

@MainActor private func withDatabase(_ body: @MainActor (AssetDatabase) throws -> Void) throws {
    let project = try makeProject()
    defer { try? FileManager.default.removeItem(at: project.root) }
    try body(AssetDatabase(project: project))
}

private func sphere() -> MeshGeometry { MeshGeometry.sphere(radius: 0.5, segments: 32, rings: 16).withTangents() }

@Suite struct GroomTests {
    // MARK: File format

    @Test func everyKeyIsOptionalAndPresetsAreClean() throws {
        let empty = try AssetJSON.decoder().decode(GroomBuild.self, from: Data("{}".utf8))
        #expect(empty == GroomBuild())
        let text = #"{"style": "cards", "thickness": 0.5, "combDirection": "followSurface", "mask": {"parts": "Body"}, "comb": [{"radius": 0.2}]}"#
        let decoded = try AssetJSON.decoder().decode(GroomBuild.self, from: Data(text.utf8))
        #expect(decoded.style == .cards && decoded.thickness == Vec2(0.5, 0.5) && decoded.combDirection == .followSurface)
        #expect(decoded.mask.parts == ["Body"] && decoded.comb.first?.direction == Vec3(0, -1, 0))
        let vector = try AssetJSON.decoder().decode(GroomBuild.self, from: Data(#"{"combDirection": [0, 0, -1]}"#.utf8))
        #expect(vector.combDirection == .vector(Vec3(0, 0, -1)))
        #expect(try AssetJSON.decoder().decode(GroomBuild.self, from: vector.fileData()) == vector, "round-trips")
        #expect(GroomBuild.presetNames.count == 15)
        for name in GroomBuild.presetNames {
            let preset = try #require(GroomBuild.preset(name), "\(name)")
            #expect(GroomCheck.problems(preset).isEmpty, "\(name): \(GroomCheck.problems(preset))")
            #expect(!GroomBuild.presetSummary(name).isEmpty)
        }
        #expect(GroomBuild.preset("Short Fur") != nil && GroomBuild.preset("nope") == nil)
    }

    @Test func checksReportBadValues() {
        var build = GroomBuild(style: .strands, length: -1, density: 0, shells: 1)
        build.lod.distances = [10, 5]
        build.mask.vertexPaint = "q"
        build.comb = [GroomComb(radius: 0)]
        let problems = GroomCheck.problems(build).joined(separator: "\n")
        for word in ["strands", "length", "density", "shells", "lod.distances", "vertexPaint", "comb[0]"] {
            #expect(problems.contains(word), "\(word) in \(problems)")
        }
    }

    @Test func materialFurTagFollowsGeometryNotColor() throws {
        var groom = GroomBuild()
        let base = MaterialFur(groom: groom)
        groom.tipColor = Vec3(1, 0, 0)
        #expect(MaterialFur(groom: groom).tag == base.tag, "colors don't rebuild meshes")
        groom.cut = [GroomCut(center: .zero, radius: 0.1)]
        #expect(MaterialFur(groom: groom).tag != base.tag)
        var asset = MaterialAsset()
        asset.fur = MaterialFur(groom: groom, maskImage: GroomImage(width: 1, height: 1, pixels: [255, 0, 0, 255]))
        let decoded = try AssetJSON.decoder().decode(MaterialAsset.self, from: AssetJSON.encode(asset))
        #expect(decoded.fur == asset.fur && decoded.fur?.tag == asset.fur?.tag)
        #expect(asset.material(texture: nil).fur != nil)
        #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: AssetJSON.encode(MaterialAsset())).fur == nil)
    }

    @Test func detailLevelsByDistance() {
        let traits = MaterialFur(groom: GroomBuild(shells: 24, lod: GroomLOD(distances: [5, 10, 20]))).traits
        #expect(traits.shellLevels == [24, 12, 6])
        #expect(traits.level(distance: 1) == 0 && traits.level(distance: 6) == 1 && traits.level(distance: 12) == 2)
        #expect(traits.level(distance: 50) == 3, "past the last distance: undercoat only")
    }

    // MARK: Geometry

    @Test func finsStandOnEveryFurryEdgeBothWays() throws {
        let base = sphere()
        let fur = MaterialFur(groom: GroomBuild())
        let shells = try #require(GroomGeometry.shells(base, fur: fur))
        let spacing = fur.groom.strandSpacing
        let fins = try #require(GroomFins.fins(shells, spacing: spacing))
        // Each edge once: (segments + 1) x 2 vertices, segments quads drawn both ways.
        var edges: Set<UInt64> = []
        for t in stride(from: 0, to: shells.indices.count, by: 3) {
            for k in 0..<3 {
                let a = shells.indices[t + k], b = shells.indices[t + (k + 1) % 3]
                edges.insert(UInt64(min(a, b)) << 32 | UInt64(max(a, b)))
            }
        }
        let perEdge = (GroomFins.segments + 1) * 2
        #expect(fins.vertices.count == edges.count * perEdge)
        #expect(fins.indices.count == edges.count * GroomFins.segments * 12)
        // UV y climbs root to tip; UV x counts strands along the edge (2 per spacing).
        for e in stride(from: 0, to: fins.vertices.count, by: perEdge) {
            let root = fins.vertices[e], other = fins.vertices[e + 1], tip = fins.vertices[e + perEdge - 2]
            #expect(root.uv.y == 0 && tip.uv.y == 1 && tip.position == root.position && tip.tangent == root.tangent)
            let strands = length(other.position - root.position) / spacing * GroomFins.strandsPerSpacing
            #expect(abs((other.uv.x - root.uv.x) - strands) < 1e-2 * max(strands, 1))
        }
        // Bald meshes get none.
        var bald = shells
        for i in bald.vertices.indices { bald.vertices[i].tangent.w = 1 }
        #expect(GroomFins.fins(bald, spacing: spacing) == nil)
    }

    @Test func shellsKeepTheMeshAndCarryLengthAndComb() throws {
        let base = sphere()
        var groom = GroomBuild(combDirection: .followSurface, combStrength: 1)
        let shells = try #require(GroomGeometry.shells(base, fur: MaterialFur(groom: groom)))
        #expect(shells.indices.count == base.indices.count)
        #expect(shells.vertices.allSatisfy { abs($0.tangent.w - 2) < 1e-5 }, "1 + full length")
        // On the equator, following the surface combs straight down.
        let equator = try #require(shells.vertices.first { abs($0.position.y) < 0.02 && $0.position.x > 0.45 })
        #expect(equator.tangent.y < -0.95)
        // A cut stroke at the top removes the fur there; the triangles all bald go.
        groom.cut = [GroomCut(center: Vec3(0, 0.5, 0), radius: 0.3, length: 0)]
        let cut = try #require(GroomGeometry.shells(base, fur: MaterialFur(groom: groom)))
        #expect(cut.indices.count < base.indices.count)
        #expect(cut.vertices.contains { $0.tangent.w < 1.01 } && !cut.vertices.contains { $0.position.y > 0.49 && $0.tangent.w > 1.01 })
        // Skins are kept.
        var skinned = base
        skinned.skin = Array(repeating: SkinInfluence(joint: 2), count: base.vertices.count)
        let skinnedShells = try #require(GroomGeometry.shells(skinned, fur: MaterialFur(groom: GroomBuild())))
        #expect(skinnedShells.skin?.count == skinnedShells.vertices.count && skinnedShells.skin?.first?.joints.x == 2)
        // Covering everything with a length 0 cut leaves nothing.
        groom.cut = [GroomCut(center: .zero, radius: 10, length: 0)]
        #expect(GroomGeometry.shells(base, fur: MaterialFur(groom: groom)) == nil)
    }

    @Test func maskImageAndVertexPaintScaleLength() throws {
        var base = sphere()
        let image = GroomImage(width: 2, height: 1, pixels: [0, 0, 0, 255, 255, 255, 255, 255])
        let fields = GroomGeometry.vertexFields(base, fur: MaterialFur(groom: GroomBuild(), maskImage: image))
        #expect(fields.lengths.contains { $0 < 0.1 } && fields.lengths.contains { $0 > 0.9 })
        base.paint = base.vertices.map { VertexPaint(color: Vec4($0.position.y > 0 ? 1 : 0, 1, 1, 1)) }
        var groom = GroomBuild()
        groom.mask.vertexPaint = "r"
        let painted = GroomGeometry.vertexFields(base, fur: MaterialFur(groom: groom))
        for (v, l) in zip(base.vertices, painted.lengths) { #expect(l == (v.position.y > 0 ? 1 : 0)) }
    }

    @Test func cardsGrowFromTheSurfaceDeterministically() throws {
        let base = sphere()
        let groom = GroomBuild(style: .cards, length: 0.2, density: 0.05, cardSegments: 4)
        let fur = MaterialFur(groom: groom)
        let (guides, requested) = GroomGeometry.guides(base, fur: fur)
        // About 3.1 m² x 10000 cm²/m² x 0.05 per cm².
        #expect(requested > 1400 && requested < 1700, "\(requested)")
        #expect(guides.count > requested / 2)
        #expect(guides.allSatisfy { $0.points.count == 5 })
        let root = guides[0].points[0]
        #expect(abs(length(root) - 0.5) < 0.02, "roots on the surface")
        #expect(dot(guides[0].points[4] - root, guides[0].normal) > 0, "grows outward")
        let cards = try #require(GroomGeometry.cards(base, fur: fur))
        #expect(cards.vertices.count == guides.count * 10 && cards.indices.count == guides.count * 4 * 6)
        #expect(cards.vertices.allSatisfy { $0.tangent.w >= 2 && $0.tangent.w < 3 && $0.uv.y >= 0 && $0.uv.y <= 1 })
        #expect(try #require(GroomGeometry.cards(base, fur: fur)).vertices == cards.vertices, "same seed, same cards")
        let half = try #require(GroomGeometry.cards(base, fur: fur, fraction: 0.5))
        #expect(abs(half.vertices.count - cards.vertices.count / 2) <= 10)
        var skinned = base
        skinned.skin = Array(repeating: SkinInfluence(joint: 1), count: base.vertices.count)
        #expect(GroomGeometry.cards(skinned, fur: fur)?.skin?.allSatisfy { $0.joints.x == 1 } == true)
    }

    @Test func reportWarnsAboutUVsDensityAndEmptyMasks() {
        var flat = sphere()
        for i in flat.vertices.indices { flat.vertices[i].uv = .zero }
        #expect(GroomGeometry.report(flat, fur: MaterialFur(groom: GroomBuild())).warnings.contains { $0.contains("no texture coordinates") })
        #expect(GroomGeometry.report(sphere(), fur: MaterialFur(groom: GroomBuild())).warnings.isEmpty)
        var bald = GroomBuild()
        bald.cut = [GroomCut(center: .zero, radius: 10, length: 0)]
        #expect(GroomGeometry.report(sphere(), fur: MaterialFur(groom: bald)).warnings.contains { $0.contains("covers nothing") })
        let dense = GroomGeometry.report(sphere(), fur: MaterialFur(groom: GroomBuild(style: .cards, density: 50)))
        #expect(dense.warnings.contains { $0.contains("too dense") } && dense.cards == GroomGeometry.maxCards)
        let heavy = GroomGeometry.report(MeshGeometry.sphere(radius: 0.5, segments: 400, rings: 200),
                                         fur: MaterialFur(groom: GroomBuild(shells: 64)))
        #expect(heavy.warnings.contains { $0.contains("triangle count") })
        #expect(GroomGeometry.report(.cube(), fur: MaterialFur(groom: GroomBuild())).warnings.contains { $0.contains("only 12 triangles") })
    }

    // MARK: Importer and hooks

    @MainActor @Test func importerMakesAFurMaterialAndPreview() throws {
        try withDatabase { database in
            var build = GroomBuild.preset("moss")!
            build.mask.texture = "Textures/missing.png"
            let id = try database.createGroom(build, at: "Grooms/Moss.groom")
            database.refreshAsync()
            database.waitForAll()
            #expect(database.groom(of: id) == build)
            #expect(database.groomID("Assets/Grooms/Moss.groom") == id && database.groomID("asset:\(id)") == id)
            let material = try #require(database.material(AssetReference(id, subAsset: GroomRenderer.furSubAsset)))
            #expect(material.fur?.groom == build)
            let prefab = try #require(database.prefab(AssetReference(id)))
            let preview = try #require(prefab.roots.first?.children.first)
            #expect(preview.groom == GroomRenderer(groom: GroomRenderer.material(ofGroom: id)))
            #expect(preview.mesh != nil)
            build.length = 0.02
            let warnings = try database.writeGroom(build, to: id)
            #expect(warnings.contains { $0.contains("mask.texture") }, "\(warnings)")
            // Placed, the node wears the fur.
            let world = World()
            let roots = world.instantiate(prefab)
            #expect(world.count(of: GroomRenderer.self) == 1 && !roots.isEmpty)
        }
    }

    @MainActor @Test func meshBuildsCharactersAndScatterWearGrooms() throws {
        try withDatabase { database in
            let groom = try database.createGroom(GroomBuild.preset("shortFur")!, at: "Grooms/Fur.groom")
            var rock = MeshBuildPart(name: "Rock", shape: .sphere, size: Vec3(1, 0.7, 1))
            rock.groom = "Grooms/Fur.groom"
            let stand = MeshBuildPart(name: "Stand", shape: .box, position: Vec3(0, -0.5, 0), size: Vec3(1, 0.2, 1))
            let model = try database.createMeshBuild(MeshBuild(parts: [rock, stand]), at: "Models/Rock.meshbuild")
            var character = CharacterBuild(template: .quadruped,
                                           attachments: [CharacterAttachment(name: "Hat", bone: "head", asset: "Models/Rock.meshbuild")])
            character.grooms = ["body": "Grooms/Fur.groom", "wings": "Grooms/Fur.groom"]
            character.attachments[0].groom = "Grooms/Fur.groom"
            let creature = try database.createCharacter(character, at: "Characters/Fox.character")
            database.refreshAsync()
            database.waitForAll()
            let handle = GroomRenderer.material(ofGroom: groom)

            let nodes = try #require(database.prefab(AssetReference(model))).roots[0].children
            #expect(nodes.first { $0.name == "Rock" }?.groom?.groom == handle)
            #expect(nodes.first { $0.name == "Stand" }?.groom == nil)

            #expect(character.problems.contains { $0.contains("'wings' isn't a body region") })
            SkeletalAnimation.registerComponents()
            let world = World()
            world.instantiate(try #require(database.prefab(AssetReference(creature))))
            var furred: [String] = []
            world.query(GroomRenderer.self) { entity, renderer in
                #expect(renderer.groom == handle)
                furred.append(world.get(Name.self, for: entity)?.value ?? "")
            }
            // The body region (skinned) and both hat parts (the attachment's groom; Rock also has its own).
            #expect(furred.sorted() == ["Body Body", "Rock", "Stand"], "\(furred)")
            var body: Entity?
            world.query(Name.self) { entity, name in if name.value == "Body Body" { body = entity } }
            #expect(world.get(Skin.self, for: try #require(body)) != nil)

            // Terrain scatter: every prop wears it.
            var terrain = Terrain(size: Vec2(10, 10), resolution: 9)
            var rule = TerrainScatter(name: "Rocks", asset: "Models/Rock.meshbuild", density: 20, maxCount: 4)
            rule.groom = "Grooms/Fur.groom"
            terrain.scatter = [rule]
            let land = try database.createTerrain(terrain, at: "Land.terrain")
            database.refreshAsync()
            database.waitForAll()
            let scatterWorld = World()
            scatterWorld.instantiate(try #require(database.prefab(AssetReference(land))))
            #expect(scatterWorld.count(of: GroomRenderer.self) > 0)
            scatterWorld.query(GroomRenderer.self) { entity, _ in
                #expect(["Rock", "Stand"].contains(scatterWorld.get(Name.self, for: entity)?.value ?? ""))
            }
        }
    }

    // MARK: Rendering (CPU side)

    @MainActor @Test func shellsAreInstancesOfOneBatchPerMeshAndGroom() throws {
        var prep = RenderPrep()
        let groom = GroomBuild(shells: 8, lod: GroomLOD(distances: [10, 20, 40]))
        let fur = MaterialFur(groom: groom)
        prep.meshes.register(Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5)), key: "ball")
        prep.meshes.register(Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5)), key: GroomRenderer.meshKey("shell", tag: fur.tag, base: "ball"))
        prep.materials.register(MaterialTraits(), key: "skin")
        prep.materials.register(MaterialTraits(fur: fur.traits), key: "fur")
        let world = World()
        for x in 0..<3 {
            world.spawn(Transform(position: Vec3(Float(x) * 2, 0, 0)), MeshRenderer(mesh: MeshHandle("ball"), material: MaterialHandle("skin")),
                        GroomRenderer(groom: MaterialHandle("fur")))
        }
        world.propagateTransforms()
        prep.lodViewpoint = Vec3(0, 0, 5)
        prep.gather(world: world)
        // Each entity: itself, 8 shells and the undercoat.
        #expect(prep.items.count == 3 * 10)
        let heights = prep.items.filter { $0.material == 1 }.map(\.instance.params.y)
        #expect(Set(heights).count == 9 && heights.contains(0) && heights.contains(1))
        #expect(prep.items.filter { $0.material == 1 }.allSatisfy { $0.bounds.halfExtent.x > 0.5 })
        // Two shells per entity cast shadows (near 0.35 and 0.75 of the length), keeping their material.
        let casters = prep.items.filter { $0.material == 1 && $0.castsShadows }
        #expect(casters.count == 3 * 2 && casters.allSatisfy(\.alphaTested))
        let casterHeights = Set(casters.map(\.instance.params.y))
        #expect(casterHeights.count == 2 && casterHeights.allSatisfy { $0 > 0.2 && $0 < 0.9 }, "\(casterHeights)")
        var shadowBatches = ShadowCasterBatches()
        shadowBatches.build(items: prep.items, tiles: [ShadowTileCulling(frustum: Frustum(viewProjection: Mat4.orthographic(
            left: -10, right: 10, bottom: -10, top: 10, near: -20, far: 20)))])
        #expect(shadowBatches.batches.contains { $0.material == 1 && $0.count == 6 }, "every copy's fur casters in one draw")
        var list = RenderList()
        let view = Frustum(viewProjection: Mat4.perspective(fovY: 1.2, aspect: 1, near: 0.1, far: 100) * Mat4.lookAt(eye: Vec3(2, 0, 8), target: Vec3(2, 0, 0)))
        list.build(items: prep.items, view: view, cameraPosition: Vec3(2, 0, 8), shadows: nil)
        #expect(list.opaque.count == 2, "the bodies, then every copy's undercoat in one instanced draw")
        #expect(list.opaque.contains { $0.material == 1 && $0.count == 3 })
        // The shells are blended, copy by copy back to front, each inner to outer; consecutive
        // copies still share one instanced draw.
        #expect(list.transparent.count == 1 && list.transparent[0].material == 1 && list.transparent[0].count == 24,
                "\(list.transparent)")
        let order = list.instances[list.transparent[0].first..<(list.transparent[0].first + 24)].map(\.params.y)
        #expect(order == Array(repeating: (1...8).map { Float($0) / 8 }, count: 3).flatMap { $0 }, "\(order)")
        #expect(list.instances[list.transparent[0].first].color.w == 8, "the shell count rides in the color's alpha")

        // `castsShadows: false` on the groom (or the mesh) keeps the fur out of the shadows.
        var grooms: [(Entity, GroomRenderer)] = []
        world.query(GroomRenderer.self) { entity, groom in grooms.append((entity, groom)) }
        for (entity, var groom) in grooms {
            groom.castsShadows = false
            world.add(groom, to: entity)
        }
        prep.gather(world: world)
        #expect(!prep.items.contains { $0.material == 1 && $0.castsShadows })

        // Far away: only the undercoat.
        prep.lodViewpoint = Vec3(0, 0, 100)
        prep.gather(world: world)
        #expect(prep.items.count == 3 * 2)
        // A fur material still loading (no fur yet) draws nothing extra.
        prep.materials.register(MaterialTraits(), key: "fur")
        prep.gather(world: world)
        #expect(prep.items.count == 3)
    }

    @MainActor @Test func skinnedFurSharesItsPoseInOneBatch() {
        let items = (0..<5).map { k in
            RenderItem(entity: Entity(index: 1, generation: 0), mesh: k == 0 ? 0 : 1, material: k == 0 ? 0 : 1,
                       instance: MeshInstance(model: .identity, previousModel: .identity, color: Vec4(1, 1, 1, 1), params: Vec4(1, Float(k) / 4, 0, 0)),
                       bounds: Bounds(center: .zero, halfExtent: Vec3(repeating: 1)), castsShadows: false, transparent: false, skin: 0)
        }
        var list = RenderList()
        let view = Frustum(viewProjection: Mat4.perspective(fovY: 1.2, aspect: 1, near: 0.1, far: 100) * Mat4.lookAt(eye: Vec3(0, 0, 5), target: .zero))
        list.build(items: items, view: view, cameraPosition: Vec3(0, 0, 5), shadows: nil)
        #expect(list.opaque.map(\.count) == [1, 4])
        #expect(list.opaque.allSatisfy { $0.skin == 0 })
    }

    @Test func springsTrailMotionAndSettle() {
        var spring = FurSpring()
        spring.step(to: .zero, dt: 0, limit: 1)
        for k in 1...10 { spring.step(to: Vec3(Float(k) * 0.05, 0, 0), dt: 1.0 / 60, limit: 1) }
        #expect(spring.offset.x < -0.01, "lags behind motion toward +X")
        for _ in 0..<240 { spring.step(to: Vec3(0.5, 0, 0), dt: 1.0 / 60, limit: 1) }
        #expect(length(spring.offset) < 1e-3, "settles when still")
        spring.step(to: Vec3(100, 0, 0), dt: 1.0 / 60, limit: 0.05)
        for _ in 0..<5 { spring.step(to: Vec3(200, 0, 0), dt: 1.0 / 60, limit: 0.05) }
        #expect(length(spring.offset) <= 0.0501)
    }

    /// Built games: a scene entity wearing a groom (and a mask texture) cooks the `.groom` and its texture.
    @MainActor @Test func cookShipsGroomsAndTheirTextures() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let mask = Image(width: 2, height: 2, pixels: [UInt8](repeating: 255, count: 16))
        let maskURL = project.url(forAssetPath: "Textures/mask.png")
        try FileManager.default.createDirectory(at: maskURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try mask.pngData().write(to: maskURL)
        let database = AssetDatabase(project: project)
        database.refresh()
        var build = GroomBuild()
        build.mask.texture = "Textures/mask.png"
        let id = try database.createGroom(build, at: "Grooms/Fur.groom")
        let world = World()
        world.spawn(Transform(), MeshRenderer(mesh: .sphere), GroomRenderer(groom: GroomRenderer.material(ofGroom: id)))
        let sceneURL = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: sceneURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try world.save().write(to: sceneURL)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("GroomTests-pack-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: output) }
        let report = try AssetCooker.cook(projectAt: project.root, options: CookOptions(scenes: ["Scenes/Main.scene"]), to: output)
        let pack = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        let assets = AssetDatabase(mounting: pack)
        let material = try #require(assets.material(AssetReference(id, subAsset: GroomRenderer.furSubAsset)))
        #expect(material.fur?.groom.mask.texture == "Textures/mask.png" && material.fur?.maskImage != nil)
        let texture = try #require(material.metallicRoughnessTexture)
        #expect(assets.texture(texture) != nil, "the mask texture ships")
    }
}

// MARK: Hair styling (GroomStyling.swift, the guides in GroomGeometry.swift)

/// A head: a sphere of radius 0.12 (face toward +Z).
private func groomTestsHead() -> MeshGeometry { MeshGeometry.sphere(radius: 0.12, segments: 32, rings: 16).withTangents() }

/// Bald on the face and under the chin.
private let groomTestsFaceCuts = [GroomCut(center: Vec3(0, -0.01, 0.12), radius: 0.11, length: 0), GroomCut(center: Vec3(0, -0.13, 0), radius: 0.15, length: 0)]

/// The top half of the head, open at the bottom (a scalp cap).
private func groomTestsCap() -> MeshGeometry {
    let head = groomTestsHead()
    var indices: [UInt32] = []
    for t in stride(from: 0, to: head.indices.count, by: 3) {
        let tri = [head.indices[t], head.indices[t + 1], head.indices[t + 2]]
        if tri.allSatisfy({ head.vertices[Int($0)].position.y > -0.01 }) { indices += tri }
    }
    return MeshGeometry(vertices: head.vertices, indices: indices)
}

private func groomTestsGuides(_ groom: GroomBuild, on base: MeshGeometry = groomTestsHead()) -> [GroomGeometry.Guide] {
    GroomGeometry.guides(base, fur: MaterialFur(groom: groom)).guides
}

extension GroomTests {
    @Test func hairstyleKeysDecodeWithDefaultsAndPresetsRoundTrip() throws {
        let empty = try AssetJSON.decoder().decode(GroomBuild.self, from: Data("{}".utf8))
        #expect(empty.part.style == .none && !empty.hemline.enabled && !empty.tie.enabled && empty.fringe.amount == 0)
        #expect(empty.collide && empty.rootPlacement == .even && empty.scalpHug == 0 && empty.colliders.isEmpty && empty.clumpSize == 8)
        let text = #"{"style": "cards", "part": {"style": "side"}, "hemline": {"back": -1.2}, "tie": {}, "fringe": {"amount": 0.5},"#
            + #" "lengthProfile": {"back": 1.4}, "colliders": [{"center": [0, 0, 0], "radii": [0.1, 0.12, 0.1]}, {"end": [0, -0.2, 0], "radius": 0.05}],"#
            + #" "scalpHug": 0.4, "rootPlacement": "random", "sweepBack": 0.5}"#
        let decoded = try AssetJSON.decoder().decode(GroomBuild.self, from: Data(text.utf8))
        #expect(decoded.part.style == .side && decoded.part.strength == 1)
        #expect(decoded.hemline.enabled && decoded.hemline.back == -1.2 && decoded.hemline.front == GroomHemline().front, "present means on")
        #expect(decoded.tie.enabled && decoded.tie.point == GroomTie().point)
        #expect(decoded.fringe.amount == 0.5 && decoded.lengthProfile.back == 1.4 && decoded.lengthProfile.front == 1)
        #expect(decoded.colliders.count == 2 && decoded.colliders[0].radii == Vec3(0.1, 0.12, 0.1) && decoded.colliders[1].end == Vec3(0, -0.2, 0))
        #expect(decoded.scalpHug == 0.4 && decoded.rootPlacement == .random && decoded.sweepBack == 0.5)
        #expect(try AssetJSON.decoder().decode(GroomBuild.self, from: decoded.fileData()) == decoded)
        for name in GroomBuild.hairstyleNames { #expect(GroomBuild.presetNames.contains(name)) }
        for name in GroomBuild.presetNames {
            let preset = try #require(GroomBuild.preset(name), "\(name)")
            #expect(try AssetJSON.decoder().decode(GroomBuild.self, from: preset.fileData()) == preset, "\(name)")
            #expect(GroomCheck.problems(preset).isEmpty, "\(name): \(GroomCheck.problems(preset))")
            #expect(GroomBuild.presetSummary(name).contains("budget"), "\(name)")
        }
        var shell = GroomBuild.preset("shortFur")!
        shell.scalpHug = 0.5
        #expect(GroomCheck.problems(shell).contains { $0.contains("shell fur ignores") })
    }

    @Test func styledHairStaysOutOfTheHeadAlongItsWholeLength() throws {
        for name in GroomBuild.hairstyleNames {
            var groom = try #require(GroomBuild.preset(name))
            groom.cut = groomTestsFaceCuts
            groom.density = 1
            let guides = groomTestsGuides(groom)
            #expect(guides.count > 50, "\(name)")
            // The facets of the sphere are a little inside its radius.
            let inside = guides.flatMap(\.points).filter { length($0) < 0.117 }
            #expect(inside.isEmpty, "\(name): \(inside.count) points inside the head")
        }
        // An open cap: a collider stands in for the rest of the head.
        var groom = GroomBuild.preset("longStraight")!
        groom.density = 1
        groom.colliders = [GroomCollider(center: .zero, radius: 0.118)]
        let guides = groomTestsGuides(groom, on: groomTestsCap())
        #expect(guides.contains { $0.points.contains { $0.y < -0.15 } }, "long hair falls below the cap")
        #expect(guides.flatMap(\.points).allSatisfy { length($0) > 0.1175 })
        // Without colliders, hair hanging below the open cap falls through where the head would be.
        groom.colliders = []
        #expect(groomTestsGuides(groom, on: groomTestsCap()).flatMap(\.points).contains { length($0) < 0.11 })
    }

    @Test func aPartCombsHairAwayFromTheLine() throws {
        var groom = GroomBuild.preset("straightHair")!
        groom.cut = groomTestsFaceCuts
        groom.part = GroomPart(style: .center, width: 0.006)
        groom.flyaways = 0
        let guides = groomTestsGuides(groom).filter { $0.layer == .outer }
        // Roots on top, in front of the crown, off the line: the strand leaves toward its own side.
        let top = guides.filter { $0.root.y > 0.085 && $0.root.z > 0 && abs($0.root.x) > 0.012 }
        #expect(top.count > 20)
        let away = top.filter { ($0.points[2].x - $0.root.x) * $0.root.x > 0 }
        #expect(Float(away.count) > Float(top.count) * 0.9, "\(away.count) of \(top.count)")
        // The line itself is bare.
        #expect(!guides.contains { $0.root.y > 0.09 && $0.root.z > 0 && abs($0.root.x) < 0.002 })
        // Hair lies on the scalp near the roots instead of standing out along the normal.
        let lift = top.map { length($0.points[1]) - 0.12 }
        #expect(lift.reduce(0, +) / Float(lift.count) < 0.02)
    }

    @Test func evenRootsAreSpacedMoreEvenlyThanRandomOnes() {
        func nearest(_ placement: GroomRootPlacement) -> (mean: Float, min: Float) {
            var groom = GroomBuild(style: .cards, length: 0.05, density: 0.3)
            groom.rootPlacement = placement
            let roots = groomTestsGuides(groom).map(\.root)
            var distances: [Float] = []
            for (i, p) in roots.enumerated() {
                var best = Float.greatestFiniteMagnitude
                for (j, q) in roots.enumerated() where i != j { best = min(best, length(p - q)) }
                distances.append(best)
            }
            return (distances.reduce(0, +) / Float(max(distances.count, 1)), distances.min() ?? 0)
        }
        let even = nearest(.even), random = nearest(.random)
        #expect(even.mean > random.mean * 1.15, "\(even) vs \(random)")
        #expect(even.min > random.min * 3, "\(even) vs \(random)")
    }

    @Test func hemlinesFringesAndTiesShapeTheTips() throws {
        let head = groomTestsHead()
        var bob = GroomBuild.preset("bob")!
        bob.cut = groomTestsFaceCuts
        let fields = GroomGeometry.fields(head, fur: MaterialFur(groom: bob))
        let f = fields.shaper.frame
        let limit = f.center.y + f.extent.y * (min(bob.hemline.back, bob.hemline.front) - bob.hemline.softness) - 0.002
        #expect(groomTestsGuides(bob).flatMap(\.points).allSatisfy { $0.y >= limit })
        var uncut = bob
        uncut.hemline.enabled = false
        uncut.length = 0.4
        #expect(groomTestsGuides(uncut).flatMap(\.points).contains { $0.y < limit })

        // Bangs: front roots comb forward and down over the forehead, and are short.
        let bangs = GroomBuild.preset("bangs")!
        let front = groomTestsGuides(bangs).filter { $0.layer == .outer && $0.root.z > 0.08 && $0.root.y > 0.03 && abs($0.root.x) < 0.03 }
        #expect(front.count > 5)
        #expect(front.allSatisfy { $0.length < bangs.length * 0.75 })
        #expect(front.filter { $0.points.last!.z > $0.root.z - 0.02 && $0.points.last!.y < $0.root.y }.count * 10 > front.count * 8)

        // A ponytail: strands gather at the tie and hang below it.
        var ponytail = GroomBuild.preset("ponytail")!
        ponytail.cut = groomTestsFaceCuts
        let tied = groomTestsGuides(ponytail).filter { $0.layer != .flyaway }
        let tieShaper = GroomGeometry.fields(head, fur: MaterialFur(groom: ponytail)).shaper
        let tie = tieShaper.frame.world(ponytail.tie.point)
        let gathered = tied.filter { $0.points.contains { length($0 - tie) < ponytail.tie.radius + 0.03 } }
        #expect(Float(gathered.count) > Float(tied.count) * 0.8, "\(gathered.count) of \(tied.count)")
        #expect(gathered.filter { $0.points.last!.y < tie.y - 0.15 }.count * 2 > gathered.count, "the tail hangs")
    }

    @Test func guidesKeepLayersClumpsAndTheirCardVertices() throws {
        var groom = GroomBuild.preset("straightHair")!
        groom.cut = groomTestsFaceCuts
        groom.flyaways = 0.05
        let fur = MaterialFur(groom: groom)
        let guides = GroomGeometry.guides(groomTestsHead(), fur: fur).guides
        #expect(guides.contains { $0.layer == .inner } && guides.contains { $0.layer == .flyaway } && guides.contains { $0.layer == .outer })
        #expect(guides.allSatisfy { $0.normals.count == $0.points.count && $0.length > 0 })
        #expect(guides.filter { $0.layer != .flyaway }.allSatisfy { $0.clump >= 0 && guides[$0.clump].clump == $0.clump }, "leaders lead themselves")
        #expect(guides.filter { $0.layer == .inner }.allSatisfy { $0.width > 1 })
        for fraction: Float in [1, 0.5] {
            let mesh = try #require(GroomGeometry.cards(guides: guides, fur: fur, fraction: fraction, skinned: false))
            let spans = GroomGeometry.cardSpans(guides: guides, fraction: fraction)
            #expect(spans.count == GroomGeometry.cardCount(guides: guides.count, fraction: fraction))
            #expect(spans.reduce(0) { $0 + $1.vertexCount } == mesh.vertices.count)
            #expect(spans.last.map { $0.firstIndex + ($0.vertexCount / 2 - 1) * 6 } == mesh.indices.count)
            for span in spans.prefix(50) {
                let points = guides[span.guide].points
                for k in points.indices {
                    let mid = (mesh.vertices[span.firstVertex + 2 * k].position + mesh.vertices[span.firstVertex + 2 * k + 1].position) * 0.5
                    #expect(length(mid - points[k]) < 1e-4)
                }
            }
        }
        // Cards taper toward the tips.
        let mesh = try #require(GroomGeometry.cards(guides: guides, fur: fur, skinned: false))
        let span = GroomGeometry.cardSpans(guides: guides)[0]
        let rootWidth = length(mesh.vertices[span.firstVertex].position - mesh.vertices[span.firstVertex + 1].position)
        let tipWidth = length(mesh.vertices[span.firstVertex + span.vertexCount - 2].position - mesh.vertices[span.firstVertex + span.vertexCount - 1].position)
        #expect(tipWidth < rootWidth * 0.6)
    }

    @Test func hairlineThinsCardsTowardTheEdge() {
        let cap = groomTestsCap()
        let distances = GroomGeometry.edgeDistances(cap, lengths: [Float](repeating: 1, count: cap.vertices.count))
        // The top is a quarter circle from the open edge; the rim is the edge.
        let top = cap.vertices.indices.max { cap.vertices[$0].position.y < cap.vertices[$1].position.y }!
        #expect(abs(distances[top] - 0.12 * .pi / 2) < 0.02, "\(distances[top])")
        let usedRim = Set(cap.indices.map(Int.init)).filter { abs(cap.vertices[$0].position.y) < 0.005 }
        #expect(!usedRim.isEmpty && usedRim.allSatisfy { distances[$0] == 0 })
        func rimShare(_ width: Float) -> Float {
            var groom = GroomBuild(style: .cards, length: 0.1, density: 2)
            groom.hairlineWidth = width
            let roots = groomTestsGuides(groom, on: cap).map(\.root)
            return Float(roots.filter { $0.y < 0.03 }.count) / Float(roots.count)
        }
        #expect(rimShare(0.04) < rimShare(0) * 0.85)
    }
}
