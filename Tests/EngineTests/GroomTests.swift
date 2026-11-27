import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// Fur and hair (GroomBuild.swift, Groom.swift, GroomGeometry.swift, GroomImporter.swift, RenderPrep+Fur.swift):
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
        #expect(GroomBuild.presetNames.count == 9)
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
        #expect(list.opaque.count == 2, "the bodies, then every shell of every copy in one instanced draw")
        #expect(list.opaque.contains { $0.material == 1 && $0.count == 27 })

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
