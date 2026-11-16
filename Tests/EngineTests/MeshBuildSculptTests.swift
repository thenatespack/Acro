import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Sculpt parts: children combined as signed distance fields and meshed by dual contouring
// (MeshBuildSculpt.swift).

/// Positions welded to a 1e-4 grid.
private func weldedIDs(_ g: MeshGeometry) -> [Int] {
    var ids: [SIMD3<Int>: Int] = [:]
    return g.vertices.map { v in
        let key = SIMD3<Int>(Int((v.position.x * 1e4).rounded()), Int((v.position.y * 1e4).rounded()), Int((v.position.z * 1e4).rounded()))
        if let id = ids[key] { return id }
        ids[key] = ids.count
        return ids.count - 1
    }
}

/// Closed and consistently wound: every directed edge (welded) appears as often as its reverse.
private func isClosedAndOriented(_ g: MeshGeometry) -> Bool {
    let ids = weldedIDs(g)
    var edges: [SIMD2<Int>: Int] = [:]
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = ids[Int(g.indices[t])], b = ids[Int(g.indices[t + 1])], c = ids[Int(g.indices[t + 2])]
        guard a != b, b != c, a != c else { continue }
        for (p, q) in [(a, b), (b, c), (c, a)] { edges[SIMD2(p, q), default: 0] += 1 }
    }
    return !edges.isEmpty && edges.allSatisfy { edge, count in edges[SIMD2(edge.y, edge.x)] == count }
}

/// The enclosed volume (positive when faces point out).
private func signedVolume(_ g: MeshGeometry) -> Float {
    var v: Float = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
        let c = g.vertices[Int(g.indices[t + 2])].position
        v += dot(a, cross(b, c)) / 6
    }
    return v
}

/// The share of triangles whose corners' normals agree with the face (0...1).
private func normalAgreement(_ g: MeshGeometry) -> Float {
    var good = 0, total = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let v = (0..<3).map { g.vertices[Int(g.indices[t + $0])] }
        let n = cross(v[1].position - v[0].position, v[2].position - v[0].position)
        guard length(n) > 1e-9 else { continue }
        total += 1
        if v.allSatisfy({ dot($0.normal, n) > 0 }) { good += 1 }
    }
    return total > 0 ? Float(good) / Float(total) : 0
}

private func sculpt(_ children: [MeshBuildPart], resolution: Int? = nil, name: String = "Sculpt") -> MeshBuildPart {
    var parts = [MeshBuildPart(name: name, shape: .sculpt)]
    parts[0].resolution = resolution
    for var child in children {
        child.parent = name
        parts.append(child)
    }
    let gathered = MeshBuild(parts: parts).gatheringSculpts()
    return gathered.build.parts[0]
}

private func child(_ name: String, _ shape: MeshBuildShape, at position: Vec3 = .zero, rotation: Vec3 = .zero, size: Vec3,
                   blend: MeshBuildBlend? = nil, smooth: Float? = nil, bevel: Float? = nil) -> MeshBuildPart {
    var part = MeshBuildPart(name: name, shape: shape, position: position, rotation: rotation, size: size, bevel: bevel)
    part.blend = blend
    part.smooth = smooth
    return part
}

private func expectSolid(_ g: MeshGeometry, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(!g.indices.isEmpty && g.indices.count % 3 == 0, "\(label): triangles", sourceLocation: sourceLocation)
    #expect(isClosedAndOriented(g), "\(label): closed", sourceLocation: sourceLocation)
    #expect(signedVolume(g) > 0, "\(label): faces point out", sourceLocation: sourceLocation)
    #expect(normalAgreement(g) > 0.98, "\(label): normals follow the winding (\(normalAgreement(g)))", sourceLocation: sourceLocation)
    #expect(g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-3 }, "\(label): unit normals", sourceLocation: sourceLocation)
}

@Suite(.serialized) struct MeshBuildSculptTests {
    // MARK: Field

    @Test func blendOperationsMatchMinAndMax() {
        typealias S = MeshBuildSculptor
        #expect(S.union(0.3, -0.2, 0) == -0.2)
        #expect(S.subtract(0.3, -0.2, 0) == 0.3 && S.subtract(-0.5, -0.2, 0) == 0.2)
        #expect(S.intersect(0.3, -0.2, 0) == 0.3)
        // Smooth: never above the sharp union, lower near the seam by up to k/4, unchanged far from it.
        #expect(abs(S.union(0, 0, 0.2) - -0.05) < 1e-6)
        #expect(S.union(1, -1, 0.2) == -1)
        #expect(abs(S.subtract(0, 0, 0.2) - 0.05) < 1e-6)
        #expect(abs(S.intersect(0, 0, 0.2) - 0.05) < 1e-6)
        for (a, b) in [(Float(0.1), Float(0.05)), (-0.1, 0.02), (0.3, 0.29)] {
            #expect(S.union(a, b, 0.1) <= min(a, b) + 1e-6)
            #expect(S.subtract(a, b, 0.1) >= max(a, -b) - 1e-6)
            #expect(S.intersect(a, b, 0.1) >= max(a, b) - 1e-6)
        }
    }

    @Test func fieldOfEachShapeIsNegativeInsideAndPositiveOutside() throws {
        let shapes: [MeshBuildShape] = [.box, .sphere, .hemisphere, .cylinder, .cone, .capsule, .tube, .wedge, .pyramid]
        for shape in shapes {
            let part = sculpt([child("A", shape, size: Vec3(1, 1, 1))])
            var warnings: [String] = []
            let sculptor = try #require(MeshBuildSculptor(sculpt: part, warnings: &warnings), "\(shape)")
            let inside: Vec3 = shape == .tube ? Vec3(0.45, 0, 0) : shape == .hemisphere ? Vec3(0, -0.3, 0) : Vec3(0, -0.2, 0)
            #expect(sculptor.field(inside) < 0, "\(shape) inside: \(sculptor.field(inside))")
            #expect(sculptor.field(Vec3(0, 2, 0)) > 0 && sculptor.field(Vec3(2, 0, 0)) > 0, "\(shape) outside")
        }
        // A sphere's field is its true distance.
        let ball = try #require(MeshBuildSculptor(sculpt: sculpt([child("A", .sphere, size: Vec3(1, 1, 1))]), warnings: &ignoredWarnings))
        #expect(abs(ball.field(Vec3(1.5, 0, 0)) - 1) < 1e-5)
    }

    // MARK: Mesh

    @Test func meshesAreClosedAndFaceOut() throws {
        let cases: [(String, MeshBuildPart)] = [
            ("sphere", sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))])),
            ("rounded box", sculpt([child("Box", .box, size: Vec3(1, 0.6, 0.8), bevel: 0.1)])),
            ("snowman", sculpt([child("Low", .sphere, size: Vec3(1, 1, 1)),
                                child("High", .sphere, at: Vec3(0, 0.7, 0), size: Vec3(0.7, 0.7, 0.7), smooth: 0.15)])),
            ("box with a hole", sculpt([child("Box", .box, size: Vec3(1, 1, 0.4)),
                                       child("Hole", .cylinder, rotation: Vec3(90, 0, 0), size: Vec3(0.4, 1, 0.4), blend: .subtract)])),
            ("lens", sculpt([child("A", .sphere, at: Vec3(-0.2, 0, 0), size: Vec3(1, 1, 1)),
                             child("B", .sphere, at: Vec3(0.2, 0, 0), size: Vec3(1, 1, 1), blend: .intersect, smooth: 0.05)])),
            ("torus and cone", sculpt([child("Ring", .torus, size: Vec3(1, 0.2, 1)),
                                       child("Cone", .cone, at: Vec3(0, 0.3, 0), size: Vec3(0.5, 0.8, 0.5), smooth: 0.1)])),
        ]
        for (label, part) in cases {
            var warnings: [String] = []
            let g = try #require(part.geometry(warnings: &warnings), "\(label)")
            #expect(warnings.isEmpty, "\(label): \(warnings)")
            expectSolid(g, label)
        }
    }

    @Test func sphereVolumeAndBoundsAreAccurate() throws {
        let g = try #require(sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))]).geometry())
        let expected = Float.pi * 4 / 3 * 0.125
        #expect(abs(signedVolume(g) - expected) / expected < 0.02)
        #expect(abs(g.bounds.halfExtent.x - 0.5) < 0.01 && length(g.bounds.center) < 0.01)
    }

    @Test func subtractCutsAHoleOfTheRightVolume() throws {
        let box = child("Box", .box, size: Vec3(1, 1, 1))
        let solid = try #require(sculpt([box]).geometry())
        // A 0.4 m square bar straight through: 0.16 m³ less.
        let cut = try #require(sculpt([box, child("Bar", .box, size: Vec3(0.4, 0.4, 2), blend: .subtract)]).geometry())
        #expect(abs(signedVolume(solid) - 1) < 0.01)
        #expect(abs(signedVolume(cut) - 0.84) < 0.01, "\(signedVolume(cut))")
        expectSolid(cut, "square hole")
        // Nothing is left at the hole's center line.
        let throughHole = cut.vertices.contains { abs($0.position.x) < 0.15 && abs($0.position.y) < 0.15 }
        #expect(!throughHole)
        // Carved boxes keep their crisp edges: vertices sit on the box's corners.
        #expect(cut.vertices.contains { length($0.position - Vec3(0.5, 0.5, 0.5)) < 0.005 })
        #expect(cut.vertices.contains { length($0.position - Vec3(0.2, 0.2, 0.5)) < 0.005 })
    }

    @Test func subtractWithNothingBeforeItWarns() {
        var warnings: [String] = []
        #expect(sculpt([child("Hole", .sphere, size: Vec3(1, 1, 1), blend: .subtract)]).geometry(warnings: &warnings) == nil)
        #expect(warnings.contains { $0.contains("added") })
        warnings = []
        #expect(MeshBuildPart(shape: .sculpt).geometry(warnings: &warnings) == nil)
        #expect(warnings.contains { $0.contains("give it child parts") })
    }

    @Test func resolutionIsClampedAndSetsDetail() throws {
        var part = MeshBuildPart(shape: .sculpt)
        #expect(part.sculptResolution == MeshBuildPart.defaultSculptResolution)
        part.resolution = 4
        #expect(part.sculptResolution == 8 && part.fieldWarnings.contains { $0.contains("outside 8...128") })
        part.resolution = 100_000
        #expect(part.sculptResolution == 128)
        let coarse = try #require(sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))], resolution: 16).geometry())
        let fine = try #require(sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))], resolution: 48).geometry())
        #expect(fine.indices.count > coarse.indices.count * 4)
        expectSolid(coarse, "coarse sphere")
    }

    @Test func noiseRoughensTheSurface() throws {
        var rock = sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))])
        rock.noise = MeshBuildNoise(amount: 0.05, scale: 0.2, seed: 3)
        let g = try #require(rock.geometry())
        let radii = g.vertices.map { length($0.position) }
        #expect((radii.max() ?? 0) - (radii.min() ?? 0) > 0.04)
        expectSolid(g, "rock")
        var other = rock
        other.noise?.seed = 4
        #expect(try #require(other.geometry()).vertices.map(\.position) != g.vertices.map(\.position))
    }

    @Test func noiseLeavesIntersectTrimsClean() throws {
        // A rough rock with its base cut flat at y = 0 (the sculpt's origin).
        var parts = [MeshBuildPart(name: "Rock", shape: .sculpt),
                     MeshBuildPart(name: "Lump", shape: .sphere, parent: "Rock", position: Vec3(0, 0.3, 0), size: Vec3(1, 0.8, 0.9)),
                     MeshBuildPart(name: "Trim", parent: "Rock", position: Vec3(0, 1, 0), size: Vec3(2, 2, 2))]
        parts[0].noise = MeshBuildNoise(amount: 0.04, scale: 0.15, seed: 1)
        parts[2].blend = .intersect
        let g = try #require(MeshBuild(parts: parts).gatheringSculpts().build.parts[0].geometry())
        expectSolid(g, "flat-based rock")
        #expect(abs(g.bounds.center.y - g.bounds.halfExtent.y) < 1e-3, "the base is exactly at y = 0: \(g.bounds.center.y - g.bounds.halfExtent.y)")
        let base = g.vertices.filter { abs($0.position.y) < 1e-3 }
        #expect(base.count > 20 && base.contains { $0.normal.y < -0.99 })
    }

    @Test func childrenKeepTheirPlacementAndShapesTheirSize() throws {
        let g = try #require(sculpt([child("Bar", .capsule, at: Vec3(1, 0.5, 0), rotation: Vec3(0, 0, 90), size: Vec3(0.2, 1, 0.2))]).geometry())
        let b = g.bounds
        #expect(abs(b.center.x - 1) < 0.01 && abs(b.center.y - 0.5) < 0.01)
        #expect(abs(b.halfExtent.x - 0.5) < 0.01 && abs(b.halfExtent.y - 0.1) < 0.01)
        // The sculpt's size multiplies the mesh.
        var stretched = sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1))])
        stretched.size = Vec3(2, 1, 1)
        #expect(abs(try #require(stretched.geometry()).bounds.halfExtent.x - 1) < 0.02)
    }

    @Test func profileShapesWork() throws {
        var vase = child("Vase", .lathe, size: Vec3(1, 1, 1))
        vase.profile = [Vec2(0, 0), Vec2(0.2, 0), Vec2(0.26, 0.3), Vec2(0.12, 0.6), Vec2(0.16, 0.7)]
        var plate = child("L", .extrude, size: Vec3(1, 1, 0.2))
        plate.profile = [Vec2(0, 0), Vec2(0.6, 0), Vec2(0.6, 0.2), Vec2(0.2, 0.2), Vec2(0.2, 1), Vec2(0, 1)]
        for (label, part) in [("lathe", vase), ("extrude", plate)] {
            let g = try #require(sculpt([part]).geometry(), "\(label)")
            let direct = try #require(part.geometry())
            #expect(length(g.bounds.halfExtent - direct.bounds.halfExtent) < 0.02, "\(label) bounds")
            expectSolid(g, label)
        }
    }

    @Test func badNumbersBuildNothing() {
        var warnings: [String] = []
        #expect(sculpt([child("Ball", .sphere, at: Vec3(.nan, 0, 0), size: Vec3(1, 1, 1))]).geometry(warnings: &warnings) == nil)
        #expect(warnings.contains { $0.contains("isn't a number") })
    }

    @Test func planesAreLeftOutWithAWarning() {
        var warnings: [String] = []
        let g = sculpt([child("Ball", .sphere, size: Vec3(1, 1, 1)), child("Sheet", .plane, size: Vec3(2, 1, 2))]).geometry(warnings: &warnings)
        #expect(g != nil)
        #expect(warnings.contains { $0.contains("'Sheet'") && $0.contains("plane") })
    }

    // MARK: The build

    @Test func mirroredChildrenJoinTheSculptInOrder() throws {
        var leg = MeshBuildPart(name: "Leg L", shape: .capsule, parent: "Body", position: Vec3(-0.3, -0.4, 0), size: Vec3(0.2, 0.6, 0.2))
        leg.smooth = 0.1
        leg.mirror = [.x]
        var notch = MeshBuildPart(name: "Notch", shape: .box, parent: "Body", position: Vec3(0, -0.65, 0), size: Vec3(2, 0.2, 0.5))
        notch.blend = .subtract
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Body", shape: .sculpt, position: Vec3(0, 1, 0)),
            MeshBuildPart(name: "Torso", shape: .sphere, parent: "Body", size: Vec3(1, 0.8, 0.6)),
            leg, notch,
        ])
        let expansion = build.expansion()
        let sculpting = expansion.build.gatheringSculpts(sources: expansion.sources)
        let body = try #require(sculpting.build.parts.first { $0.name == "Body" })
        // The mirror copy comes right after its source, before the notch, so the notch cuts both legs.
        #expect(body.sculptChildren.map(\.part.name) == ["Torso", "Leg L", "Leg R", "Notch"])
        #expect(sculpting.drawnParts.map(\.name) == ["Body"])
        #expect(sculpting.sculptOf["Leg R"] == "Body")
        let g = try #require(body.geometry())
        expectSolid(g, "body with legs")
        // Symmetric, and both legs cut at the same height: from the torso's top (0.4) to the notch (-0.55), not the legs' ends (-0.7).
        #expect(abs(g.bounds.center.x) < 0.01)
        #expect(abs(g.bounds.halfExtent.y - 0.475) < 0.02, "\(g.bounds)")
        let bottom = g.vertices.filter { $0.position.y < -0.54 }
        #expect(bottom.contains { $0.position.x < -0.2 } && bottom.contains { $0.position.x > 0.2 })
    }

    @MainActor @Test func importerDrawsOneMeshAndKeepsChildrenAsPivots() throws {
        var hole = MeshBuildPart(name: "Hole", shape: .cylinder, parent: "Stone", rotation: Vec3(90, 0, 0), size: Vec3(0.3, 1, 0.3))
        hole.blend = .subtract
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Stone", shape: .sculpt, position: Vec3(0, 0.5, 0)),
            MeshBuildPart(name: "Block", shape: .box, parent: "Stone", size: Vec3(1, 1, 0.5)),
            hole,
        ], animations: [MeshBuildAnimation(name: "Wobble", motions: [MeshBuildMotion(part: "Hole", kind: .bob)])])
        let warnings = build.sculptWarnings()
        #expect(warnings.count == 1 && warnings[0].contains("'Hole', a child of sculpt 'Stone'"), "\(warnings)")

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "Sculpt")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createMeshBuild(build, at: "Models/stone.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.objects.filter { $0.kind == .mesh }.count == 1, "one mesh: the sculpt's")
        #expect(database.reimport(id).warnings.contains { $0.contains("a child of sculpt 'Stone'") })
        let root = try #require(database.prefab(AssetReference(id))?.roots.first)
        let stone = try #require(root.children.first)
        #expect(stone.mesh != nil && stone.children.map(\.name) == ["Block", "Hole"] && stone.children.allSatisfy { $0.mesh == nil })
    }

    @MainActor @Test func terrainScatterAndCharacterAttachmentsDrawTheSculpt() throws {
        SkeletalAnimation.registerComponents()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "Sculpt")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Rock", shape: .sculpt, position: Vec3(0, 0.3, 0)),
            MeshBuildPart(name: "Lump", shape: .sphere, parent: "Rock", size: Vec3(0.6, 0.6, 0.6)),
            MeshBuildPart(name: "Knob", shape: .sphere, parent: "Rock", position: Vec3(0.3, 0, 0), size: Vec3(0.3, 0.3, 0.3)),
        ]), at: "Props/rock.meshbuild")
        var terrain = Terrain.generated(size: Vec2(16, 16), resolution: 9, seed: 1)
        terrain.scatter = [TerrainScatter(name: "Rocks", asset: "Props/rock.meshbuild", density: 1, maxSlope: 90, maxCount: 2)]
        let terrainID = try database.createTerrain(terrain, at: "Maps/field.terrain")
        let characterID = try database.createCharacter(CharacterBuild(), at: "hero.character")
        _ = try database.writeCharacter(CharacterBuild(attachments: [CharacterAttachment(name: "Pet", bone: "head", asset: "Props/rock.meshbuild")]),
                                        to: characterID)
        database.refreshAsync()
        database.waitForAll()
        let rock = try #require(database.prefab(AssetReference(terrainID))?.roots.first?.children.last?.children.first?.children.first)
        #expect(rock.children.map(\.name) == ["Rock"] && rock.children[0].mesh?.subAsset == "mesh/Rock")
        #expect(database.object(AssetReference(characterID, subAsset: "mesh/Pet Rock"), kind: .mesh) != nil)
        #expect(database.object(AssetReference(characterID, subAsset: "mesh/Pet Lump"), kind: .mesh) == nil)
    }

    @Test func blendOutsideASculptWarns() {
        var stray = MeshBuildPart(name: "Stray", shape: .sphere)
        stray.smooth = 0.1
        #expect(MeshBuild(parts: [stray]).sculptWarnings().contains { $0.contains("'Stray'") && $0.contains("isn't in a sculpt") })
    }

    @Test func jsonRoundTripsAndLeavesUnsetFieldsOut() throws {
        var stone = MeshBuildPart(name: "Stone", shape: .sculpt)
        stone.resolution = 80
        stone.noise = MeshBuildNoise(amount: 0.01, scale: 0.3, seed: 2)
        var hole = MeshBuildPart(name: "Hole", parent: "Stone")
        hole.blend = .subtract
        hole.smooth = 0.02
        let build = MeshBuild(parts: [stone, MeshBuildPart(name: "Block", parent: "Stone"), hole])
        let data = try build.fileData()
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: data) == build)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.components(separatedBy: "\"blend\"").count == 2 && text.components(separatedBy: "\"smooth\"").count == 2)
        #expect(text.components(separatedBy: "\"resolution\"").count == 2 && !text.contains("sculptChildren"))
        let sparse = try AssetJSON.decoder().decode(MeshBuildPart.self, from: Data(#"{"shape": "sculpt", "noise": {"amount": 0.03}}"#.utf8))
        #expect(sparse.shape == .sculpt && sparse.blend == nil && sparse.smooth == nil && sparse.noise == MeshBuildNoise(amount: 0.03))
    }

    // MARK: Speed

    @Test func twentyChildSculptImportsQuickly() throws {
        MeshBuildSculptCache.shared.removeAll()
        var parts = [MeshBuildPart(name: "Creature", shape: .sculpt, position: Vec3(0, 1, 0))]
        for i in 0..<20 {
            let a = Float(i) / 20 * 2 * .pi
            var part = MeshBuildPart(name: "Blob \(i)", shape: [.sphere, .capsule, .box, .cylinder][i % 4], parent: "Creature",
                                     position: Vec3(cosf(a) * 0.5, sinf(a * 2) * 0.2, sinf(a) * 0.5), rotation: Vec3(Float(i) * 17, Float(i) * 31, 0),
                                     size: Vec3(0.35, 0.5, 0.3))
            part.smooth = 0.08
            if i % 7 == 6 { part.blend = .subtract }
            parts.append(part)
        }
        let sculpting = MeshBuild(parts: parts).gatheringSculpts()
        let start = Date()
        let g = try #require(sculpting.build.parts[0].geometry())
        let elapsed = Date().timeIntervalSince(start)
        print("MeshBuildSculptTests: 20-child sculpt at resolution \(MeshBuildPart.defaultSculptResolution): "
              + "\(Int(elapsed * 1000)) ms, \(g.vertices.count) vertices, \(g.indices.count / 3) triangles")
        #expect(elapsed < 3, "took \(elapsed) s")
        // Cached: the second ask is free.
        let again = Date()
        _ = sculpting.build.parts[0].geometry()
        #expect(Date().timeIntervalSince(again) < 0.05)
    }
}

nonisolated(unsafe) private var ignoredWarnings: [String] = []
