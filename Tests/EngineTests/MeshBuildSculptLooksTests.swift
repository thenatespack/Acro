import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Sculpt children's looks (MeshBuildSculptLooks.swift) and sweeps, lofts and deformed shapes in
// sculpts through the mesh distance field (MeshBuildMeshSDF.swift).

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

private func signedVolume(_ g: MeshGeometry) -> Float {
    var v: Float = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
        let c = g.vertices[Int(g.indices[t + 2])].position
        v += dot(a, cross(b, c)) / 6
    }
    return v
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

private func gathered(_ parts: [MeshBuildPart]) -> MeshBuildSculpting { MeshBuild(parts: parts).gatheringSculpts() }

private func sculptPart(_ name: String = "Sculpt", color: Vec3 = Vec3(0.8, 0.8, 0.8)) -> MeshBuildPart {
    MeshBuildPart(name: name, shape: .sculpt, color: color)
}

/// A red box with a blue ball melted onto its top.
private var twoColors: [MeshBuildPart] {
    var ball = MeshBuildPart(name: "Ball", shape: .sphere, parent: "Sculpt", position: Vec3(0, 0.45, 0), size: Vec3(0.6, 0.6, 0.6),
                             color: Vec3(0.1, 0.2, 0.9))
    ball.smooth = 0.08
    return [sculptPart(), MeshBuildPart(name: "Body", shape: .box, parent: "Sculpt", size: Vec3(1, 0.6, 0.8), color: Vec3(0.9, 0.1, 0.1)), ball]
}

@Suite(.serialized) struct MeshBuildSculptLooksTests {
    // MARK: Looks

    @Test func lookGroupsFollowTheRules() {
        var hole = MeshBuildPart(name: "Hole", shape: .cylinder, parent: "Sculpt", size: Vec3(0.2, 2, 0.2))
        hole.blend = .subtract
        var paintedHole = hole
        paintedHole.name = "Painted"
        paintedHole.color = Vec3(0, 0, 0)
        let plain = MeshBuildPart(name: "Plain", shape: .sphere, parent: "Sculpt", position: Vec3(0, 0.5, 0))
        let parts = twoColors + [plain, hole, paintedHole,
                                 MeshBuildPart(name: "Same Red", shape: .box, parent: "Sculpt", position: Vec3(0.5, 0, 0),
                                               color: Vec3(0.9, 0.1, 0.1))]
        let groups = gathered(parts).build.parts[0].sculptLookGroups()
        // Body red, Ball blue, Plain inherits the sculpt's, Hole owns nothing, Painted black, Same Red joins Body.
        #expect(groups.childGroups == [0, 1, 2, -1, 3, 0], "\(groups)")
        #expect(groups.lookSources == [0, 1, nil, 4])
        #expect(!MeshBuildPart(name: "X").setsLookFields && MeshBuildPart(look: "wood").setsLookFields)
    }

    @Test func twoColoredChildrenMakeTwoPiecesEachNearItsChild() throws {
        MeshBuildSculptCache.shared.removeAll()
        let pieces = gathered(twoColors).splittingLooks()
        #expect(pieces.build.parts.count == 5 && pieces.pieceOf == [3: 0, 4: 0])
        #expect(pieces.build.parts[3].name == "Sculpt/Body" && pieces.build.parts[4].name == "Sculpt/Ball")
        #expect(pieces.build.parts[3].color == Vec3(0.9, 0.1, 0.1) && pieces.build.parts[4].color == Vec3(0.1, 0.2, 0.9))
        #expect(pieces.owners == ["Sculpt/Body": ["Body"], "Sculpt/Ball": ["Ball"]])
        #expect(pieces.geometry(0) == nil, "the sculpt itself is a pivot")
        let body = try #require(pieces.geometry(3)), ball = try #require(pieces.geometry(4))
        // Every triangle is on (or next to) its own child's surface: the ball's are above the box's top.
        func centroids(_ g: MeshGeometry) -> [Vec3] {
            stride(from: 0, to: g.indices.count, by: 3).map { t -> Vec3 in
                let a: Vec3 = g.vertices[Int(g.indices[t])].position, b: Vec3 = g.vertices[Int(g.indices[t + 1])].position
                let c: Vec3 = g.vertices[Int(g.indices[t + 2])].position
                return (a + b + c) / 3
            }
        }
        let ballCenter = Vec3(0, 0.45, 0)
        for c in centroids(ball) {
            #expect(c.y > 0.2 && abs(length(c - ballCenter) - 0.3) < 0.06, "ball triangle at \(c)")
        }
        for c in centroids(body) {
            let outside = abs(length(c - ballCenter) - 0.3)
            let boxDistance = max(abs(c.x) - 0.5, abs(c.y) - 0.3, abs(c.z) - 0.4)
            #expect(abs(boxDistance) <= outside + 0.02, "body triangle at \(c) is nearer the ball")
        }
        // Clean boundary: the ball's piece is one ring-bounded cap, so its boundary edges form loops
        // whose points all lie where the two surfaces are equally close.
        let whole = try #require(gathered(twoColors).build.parts[0].geometry())
        #expect(body.indices.count + ball.indices.count == whole.indices.count)
    }

    @Test func piecesMeetWithoutCracks() throws {
        let pieces = gathered(twoColors).splittingLooks()
        let body = try #require(pieces.geometry(3)), ball = try #require(pieces.geometry(4))
        #expect(!isClosedAndOriented(body) && !isClosedAndOriented(ball), "each piece alone is open")
        // Welded by position, the two pieces close up exactly: every cut edge is shared.
        #expect(isClosedAndOriented(merged([body, ball])))
        // No vertex is shared across the split (looks, UVs and occlusion don't bleed).
        let whole = try #require(gathered(twoColors).build.parts[0].geometry())
        #expect(whole.vertices.count == body.vertices.count + ball.vertices.count)
        #expect(isClosedAndOriented(whole) && signedVolume(whole) > 0)
    }

    @Test func threeLooksMeetAtAPointWithoutCracks() throws {
        var parts = twoColors
        parts.append(MeshBuildPart(name: "Knob", shape: .sphere, parent: "Sculpt", position: Vec3(0.3, 0.3, 0), size: Vec3(0.4, 0.4, 0.4),
                                   color: Vec3(0.1, 0.8, 0.1)))
        let pieces = gathered(parts).splittingLooks()
        #expect(pieces.pieceOf.count == 3)
        let meshes = pieces.pieceOf.keys.sorted().compactMap { pieces.geometry($0) }
        #expect(meshes.count == 3 && isClosedAndOriented(merged(meshes)))
    }

    @Test func oneLookKeepsOneMeshWithThatLook() throws {
        // Every child sets the same color: the sculpt keeps its mesh, drawn in that color.
        let parts = [sculptPart(), MeshBuildPart(name: "A", parent: "Sculpt", color: Vec3(0.2, 0.6, 0.3), look: "stone"),
                     MeshBuildPart(name: "B", shape: .sphere, parent: "Sculpt", position: Vec3(0.4, 0.4, 0), color: Vec3(0.2, 0.6, 0.3),
                                   look: "stone")]
        let pieces = gathered(parts).splittingLooks()
        #expect(pieces.build.parts.count == 3 && pieces.pieceOf.isEmpty && pieces.geometry(0) != nil)
        #expect(pieces.build.parts[0].look == "stone" && pieces.build.parts[0].color == Vec3(0.2, 0.6, 0.3))
        // Nothing set: the sculpt's own look, unchanged.
        let plain = gathered([sculptPart(color: Vec3(1, 0, 0)), MeshBuildPart(name: "A", parent: "Sculpt")]).splittingLooks()
        #expect(plain.build.parts[0].color == Vec3(1, 0, 0) && plain.build.parts[0].look == nil)
    }

    @Test func paintedSubtractOwnsItsCut() throws {
        var hole = MeshBuildPart(name: "Hole", shape: .cylinder, parent: "Sculpt", rotation: Vec3(90, 0, 0), size: Vec3(0.3, 2, 0.3),
                                 color: Vec3(0.05, 0.05, 0.05))
        hole.blend = .subtract
        let parts = [sculptPart(), MeshBuildPart(name: "Block", parent: "Sculpt", size: Vec3(1, 1, 0.4)), hole]
        let pieces = gathered(parts).splittingLooks()
        let wall = try #require(pieces.pieceOf.first { pieces.build.parts[$0.key].name == "Sculpt/Hole" }.map { pieces.geometry($0.key) } ?? nil)
        // The hole's piece is its wall: a ring of radius 0.15 around Z.
        for v in wall.vertices { #expect(abs((v.position.x * v.position.x + v.position.y * v.position.y).squareRoot() - 0.15) < 0.03) }
        // Unpainted, the cut belongs to the block: one look, one mesh.
        hole.color = MeshBuildPart().color
        #expect(gathered([parts[0], parts[1], hole]).splittingLooks().pieceOf.isEmpty)
    }

    @MainActor @Test func importerDrawsAMeshPerLookUnderTheSculptWithStableIDs() throws {
        let build = MeshBuild(parts: twoColors, animations: [MeshBuildAnimation(name: "Spin", motions: [MeshBuildMotion(part: "Sculpt")])])
        func importIDs() throws -> ([String], PrefabNode) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptLooksTests-\(UUID().uuidString)", isDirectory: true)
            let project = try Project.create(at: url, name: "Looks")
            defer { try? FileManager.default.removeItem(at: project.root) }
            let database = AssetDatabase(project: project)
            let id = try database.createMeshBuild(build, at: "Models/toy.meshbuild")
            database.refreshAsync()
            database.waitForAll()
            let record = try #require(database.record(id))
            #expect(database.reimport(id).warnings.isEmpty)
            let root = try #require(database.prefab(AssetReference(id))?.roots.first)
            return (record.objects.map(\.id).sorted(), try #require(root.children.first))
        }
        let (ids, sculpt) = try importIDs()
        #expect(ids.contains("mesh/Sculpt/Body") && ids.contains("mesh/Sculpt/Ball") && !ids.contains("mesh/Sculpt"))
        #expect(ids.contains("material/Sculpt/Body") && ids.contains("material/Sculpt/Ball"))
        // The sculpt node stays the animated pivot; children (pivots) and then the looks hang from it.
        #expect(sculpt.name == "Sculpt" && sculpt.mesh == nil && sculpt.animator != nil)
        #expect(sculpt.children.map(\.name) == ["Body", "Ball", "Sculpt/Body", "Sculpt/Ball"])
        #expect(sculpt.children[2].mesh?.subAsset == "mesh/Sculpt/Body" && sculpt.children[3].mesh?.subAsset == "mesh/Sculpt/Ball")
        #expect(sculpt.children[2].transform.position == .zero)
        // Deterministic: a second import names everything the same.
        MeshBuildSculptCache.shared.removeAll()
        #expect(try importIDs().0 == ids)
    }

    // MARK: Mesh distance field

    @Test func meshFieldMatchesABoxExactly() throws {
        var cube = MeshGeometry.cube(size: 1)
        cube.scale(by: Vec3(1, 0.6, 0.8))
        let field = try #require(MeshDistanceField(cube))
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<2000 {
            let p = Vec3(Float.random(in: -1.2...1.2, using: &rng), Float.random(in: -1...1, using: &rng), Float.random(in: -1...1, using: &rng))
            let q = Vec3(abs(p.x) - 0.5, abs(p.y) - 0.3, abs(p.z) - 0.4)
            let exact = length(pointwiseMax(q, .zero)) + min(max(q.x, max(q.y, q.z)), 0)
            #expect(abs(field.distance(p.x, p.y, p.z) - exact) < 1e-4, "at \(p): \(field.distance(p.x, p.y, p.z)) vs \(exact)")
        }
    }

    @Test func meshFieldMatchesASphereWithinItsFacets() throws {
        let sphere = MeshGeometry.sphere(radius: 0.5, segments: 64, rings: 32)
        let field = try #require(MeshDistanceField(sphere))
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<2000 {
            let p = Vec3(Float.random(in: -1...1, using: &rng), Float.random(in: -1...1, using: &rng), Float.random(in: -1...1, using: &rng))
            let exact = length(p) - 0.5
            let d = field.distance(p.x, p.y, p.z)
            #expect(abs(d - exact) < 0.004, "at \(p): \(d) vs \(exact)")
            if abs(exact) > 0.004 { #expect((d < 0) == (exact < 0), "sign at \(p)") }
        }
        // The hierarchy's bound never overestimates.
        for _ in 0..<200 {
            let c = Vec3(Float.random(in: -1.5...1.5, using: &rng), Float.random(in: -1.5...1.5, using: &rng), Float.random(in: -1.5...1.5, using: &rng))
            let h = Vec3(repeating: 0.1)
            let bound = field.lowerBound(boxLo: c - h, boxHi: c + h)
            #expect(bound <= abs(field.distance(c.x, c.y, c.z)) + 1e-5)
        }
    }

    // MARK: Curves and deformers in a sculpt

    static var curvedChildren: [MeshBuildPart] {
        var handle = MeshBuildPart(name: "Handle", shape: .sweep, parent: "Sculpt", path: [Vec3(0.3, 0.1, 0), Vec3(0.6, 0.25, 0), Vec3(0.3, 0.45, 0)],
                                   radius: 0.05)
        handle.smooth = 0.03
        var spout = MeshBuildPart(name: "Spout", shape: .sweep, parent: "Sculpt", path: [Vec3(-0.25, 0.15, 0), Vec3(-0.5, 0.35, 0), Vec3(-0.6, 0.55, 0)],
                                  radius: 0.06, radii: [1.4, 1, 0.7])
        spout.smooth = 0.04
        let ring = MeshBuildPart(name: "Ring", shape: .sweep, parent: "Sculpt", path: [Vec3(0.3, 0, 0), Vec3(0, 0, 0.3), Vec3(-0.3, 0, 0), Vec3(0, 0, -0.3)],
                                 radius: 0.04, closed: true)
        let hull = MeshBuildPart(name: "Hull", shape: .loft, parent: "Sculpt", position: Vec3(0, 0.6, 0),
                                 sections: [MeshBuildSection(at: 0, size: Vec2(0.5, 0.3)), MeshBuildSection(at: 0.3, size: Vec2(0.2, 0.2))])
        let bent = MeshBuildPart(name: "Bent", shape: .box, parent: "Sculpt", position: Vec3(0, 0.25, 0), size: Vec3(0.3, 0.5, 0.3),
                                 deform: [.bend(.x, 40)])
        return [sculptPart(), bent, handle, spout, ring, hull]
    }

    @Test func sweepLoftAndDeformedBoxSculptClosedAndOutward() throws {
        MeshBuildSculptCache.shared.removeAll()
        let parts = Self.curvedChildren
        var warnings: [String] = []
        let start = Date()
        let g = try #require(gathered(parts).build.parts[0].geometry(warnings: &warnings))
        let elapsed = Date().timeIntervalSince(start)
        print("MeshBuildSculptLooksTests: 3 sweeps, a loft and a bent box at resolution \(MeshBuildPart.defaultSculptResolution): "
              + "\(Int(elapsed * 1000)) ms, \(g.indices.count / 3) triangles")
        #expect(warnings.isEmpty, "\(warnings)")
        #expect(isClosedAndOriented(g) && signedVolume(g) > 0)
        // Each child alone: the sculpt's volume is close to its mesh's.
        for child in parts.dropFirst() {
            let alone = try #require(gathered([sculptPart(), child]).build.parts[0].geometry(), "\(child.name)")
            var placed = child
            placed.parent = ""
            let mesh = try #require(placed.geometry())
            let expected = signedVolume(mesh), got = signedVolume(alone)
            #expect(isClosedAndOriented(alone), "\(child.name) closed")
            #expect(abs(got - expected) < expected * 0.15, "\(child.name): volume \(got) vs its mesh's \(expected)")
        }
        // The bend is used (the top leans toward +x), not ignored.
        let bent = try #require(gathered([sculptPart(), parts[1]]).build.parts[0].geometry())
        let top = bent.vertices.filter { $0.position.y > 0.4 }.map(\.position.x)
        #expect(!top.isEmpty && top.reduce(0, +) / Float(top.count) > 0.05)
    }

    @Test func meshFieldSculptTiming() throws {
        // Three sweeps, a loft and a bent box at the default resolution (printed for the docs).
        MeshBuildSculptCache.shared.removeAll()
        var parts = Self.curvedChildren
        parts[0].resolution = MeshBuildPart.defaultSculptResolution
        let sculpt = gathered(parts).build.parts[0]
        let start = Date()
        var warnings: [String] = []
        let mesh = try #require(MeshBuildSculptor(sculpt: sculpt, warnings: &warnings)?.mesh(warnings: &warnings))
        let elapsed = Date().timeIntervalSince(start)
        print("MeshBuildSculptLooksTests: mesh-field sculpt (uncached) \(Int(elapsed * 1000)) ms, \(mesh.geometry.indices.count / 3) triangles")
        #expect(elapsed < 20, "took \(elapsed) s")
    }
}
