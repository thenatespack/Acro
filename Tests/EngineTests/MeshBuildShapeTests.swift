import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild

// Mesh build shapes beyond the unit primitives: bevelled boxes and cylinders, lathe and extrude.

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

/// Whether the mesh is closed and consistently wound once seams are welded: every directed
/// edge appears once and its reverse once (degenerate triangles skipped).
private func isClosedManifold(_ g: MeshGeometry) -> Bool {
    let ids = weldedIDs(g)
    var edges: [SIMD2<Int>: Int] = [:]
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = ids[Int(g.indices[t])], b = ids[Int(g.indices[t + 1])], c = ids[Int(g.indices[t + 2])]
        guard a != b, b != c, a != c else { continue }
        for (p, q) in [(a, b), (b, c), (c, a)] { edges[SIMD2(p, q), default: 0] += 1 }
    }
    return edges.allSatisfy { edge, count in count == 1 && edges[SIMD2(edge.y, edge.x)] == 1 }
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

/// Σ face normal · (centroid − center), area weighted: positive when the mesh faces outward.
private func outwardness(_ g: MeshGeometry) -> Float {
    let center = g.bounds.center
    var sum: Float = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
        let c = g.vertices[Int(g.indices[t + 2])].position
        sum += dot(cross(b - a, c - a), (a + b + c) / 3 - center)
    }
    return sum
}

/// Vertex normals agree with their triangles' faces (no triangle's face normal points against
/// its corners' normals), and are unit length.
private func normalsMatchWinding(_ g: MeshGeometry) -> Bool {
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let v = (0..<3).map { g.vertices[Int(g.indices[t + $0])] }
        let n = cross(v[1].position - v[0].position, v[2].position - v[0].position)
        guard length(n) > 1e-9 else { continue }
        if v.contains(where: { dot($0.normal, n) < 0 }) { return false }
    }
    return g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-3 }
}

private func expectSolid(_ g: MeshGeometry, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(!g.indices.isEmpty && g.indices.count % 3 == 0, "\(label): triangles", sourceLocation: sourceLocation)
    #expect(isClosedManifold(g), "\(label): closed", sourceLocation: sourceLocation)
    #expect(outwardness(g) > 0 && signedVolume(g) > 0, "\(label): faces point out", sourceLocation: sourceLocation)
    #expect(normalsMatchWinding(g), "\(label): normals follow the winding", sourceLocation: sourceLocation)
}

private func warnings(_ part: MeshBuildPart) -> (MeshGeometry?, [String]) {
    var warnings: [String] = []
    let g = part.geometry(warnings: &warnings)
    return (g, warnings)
}

private let lShape: [Vec2] = [Vec2(0, 0), Vec2(0.6, 0), Vec2(0.6, 0.2), Vec2(0.2, 0.2), Vec2(0.2, 1), Vec2(0, 1)]

@Suite struct MeshBuildShapeTests {
    @Test func zeroBevelIsTheOldBox() throws {
        let size = Vec3(2, 1, 0.5)
        let old = try #require(MeshBuildPart(shape: .box, size: size).geometry())
        for bevel: Float? in [nil, 0, -1, .nan] {
            let g = try #require(MeshBuildPart(shape: .box, size: size, bevel: bevel).geometry())
            #expect(g.vertices == old.vertices && g.indices == old.indices, "bevel \(String(describing: bevel))")
        }
    }

    @Test func bevelledBoxIsRoundAndClosed() throws {
        let size = Vec3(2, 1, 0.5)
        let part = MeshBuildPart(shape: .box, size: size, segments: 24, bevel: 0.1)
        let g = try #require(part.geometry())
        expectSolid(g, "rounded box")
        #expect(length(g.bounds.halfExtent - size / 2) < 1e-4 && length(g.bounds.center) < 1e-4, "fills its size box")
        // 24 segments: 3 steps per half quarter round, so 8 samples across each axis.
        #expect(g.vertices.count == 6 * 8 * 8 && g.indices.count == 6 * 7 * 7 * 6)
        // Smooth: every welded position has one normal.
        let ids = weldedIDs(g)
        var normals: [Int: Vec3] = [:]
        var split = 0
        for (i, id) in ids.enumerated() {
            if let n = normals[id], length(n - g.vertices[i].normal) > 1e-4 { split += 1 } else { normals[id] = g.vertices[i].normal }
        }
        #expect(split == 0, "no hard edges")
        // A corner vertex's normal leans out along the diagonal.
        let corner = try #require(g.vertices.max { dot($0.position, Vec3(1, 1, 1)) < dot($1.position, Vec3(1, 1, 1)) })
        #expect(corner.normal.x > 0.5 && corner.normal.y > 0.5 && corner.normal.z > 0.5)
        // The volume is less than the sharp box's.
        #expect(signedVolume(g) < size.x * size.y * size.z && signedVolume(g) > size.x * size.y * size.z * 0.9)
    }

    @Test func bevelClampsToHalfTheSmallestSize() throws {
        let g = try #require(MeshBuildPart(shape: .box, size: Vec3(1, 0.4, 1), segments: 8, bevel: 5).geometry())
        expectSolid(g, "fully rounded slab")
        #expect(abs(g.bounds.halfExtent.y - 0.2) < 1e-4 && abs(g.bounds.halfExtent.x - 0.5) < 1e-4)
        let cube = try #require(MeshBuildPart(shape: .box, size: Vec3(1, 1, 1), segments: 16, bevel: 0.5).geometry())
        expectSolid(cube, "sphere-like cube")
        #expect(cube.vertices.allSatisfy { abs(length($0.position) - 0.5) < 1e-4 }, "a radius-0.5 bevel on a unit cube is a sphere")
    }

    @Test func bevelledCylinderHasRoundRims() throws {
        let part = MeshBuildPart(shape: .cylinder, size: Vec3(1, 2, 1), segments: 24, bevel: 0.1)
        let g = try #require(part.geometry())
        expectSolid(g, "rounded cylinder")
        #expect(length(g.bounds.halfExtent - Vec3(0.5, 1, 0.5)) < 1e-3)
        // The rim is rounded: no vertex at the sharp corner (r = 0.5, y = 1).
        #expect(!g.vertices.contains { abs($0.position.y - 1) < 1e-4 && abs(length(Vec3($0.position.x, 0, $0.position.z)) - 0.5) < 1e-3 })
        // An oval one still fits its box.
        let oval = try #require(MeshBuildPart(shape: .cylinder, size: Vec3(2, 1, 1), bevel: 0.2).geometry())
        #expect(length(oval.bounds.halfExtent - Vec3(1, 0.5, 0.5)) < 1e-3)
    }

    @Test func latheMakesAClosedVase() throws {
        // Written top to bottom on purpose: the lathe orients it.
        let vase: [Vec2] = [Vec2(0.15, 1), Vec2(0.1, 0.9), Vec2(0.25, 0.5), Vec2(0.2, 0), Vec2(0, 0)]
        let part = MeshBuildPart(shape: .lathe, segments: 16, profile: vase)
        let (g0, w) = warnings(part)
        let g = try #require(g0)
        #expect(w.isEmpty)
        expectSolid(g, "vase")
        // The profile is in meters, used as written: base at y = 0, top at 1, widest 0.25.
        let b = g.bounds
        #expect(abs(b.center.y - b.halfExtent.y) < 1e-4 && abs(b.center.y + b.halfExtent.y - 1) < 1e-4)
        #expect(abs(b.halfExtent.x - 0.25) < 1e-3)
        // 5 points + a cap point on the axis at the top = 5 segments, 2 rings of 17 each.
        #expect(g.vertices.count == 5 * 2 * 17)
        // size multiplies it.
        let doubled = try #require(MeshBuildPart(shape: .lathe, size: Vec3(2, 2, 2), segments: 16, profile: vase).geometry())
        #expect(abs(doubled.bounds.halfExtent.x - 0.5) < 1e-3 && abs(signedVolume(doubled) - 8 * signedVolume(g)) < 1e-3)
    }

    @Test func latheCylinderHasTheRightVolumeAndSplitNormals() throws {
        let part = MeshBuildPart(shape: .lathe, segments: 64, profile: [Vec2(0.5, 0), Vec2(0.5, 1)])
        let g = try #require(part.geometry())
        expectSolid(g, "lathe cylinder")
        #expect(abs(signedVolume(g) - .pi * 0.25) < 0.01)
        // The 90° rim is sharp: vertices there point straight up (cap) and straight out (wall).
        let rim = g.vertices.filter { abs($0.position.y - 1) < 1e-5 && abs($0.position.z - 0.5) < 1e-5 && abs($0.position.x) < 1e-5 }
        #expect(rim.contains { abs($0.normal.y - 1) < 1e-4 } && rim.contains { abs($0.normal.z - 1) < 1e-4 })
        #expect(!rim.contains { $0.normal.y > 0.01 && $0.normal.z > 0.01 }, "no averaged normal on a sharp corner")
    }

    @Test func latheSmoothBendsShareNormals() throws {
        // A sphere-ish profile: 10° bends everywhere are smooth.
        let profile = (0...18).map { i -> Vec2 in
            let a = -Float.pi / 2 + Float(i) / 18 * .pi
            return Vec2(0.5 * cosf(a), 0.5 * sinf(a))
        }
        let g = try #require(MeshBuildPart(shape: .lathe, segments: 24, profile: profile).geometry())
        expectSolid(g, "lathe sphere")
        let ids = weldedIDs(g)
        var normals: [Int: Vec3] = [:]
        var split = 0
        for (i, id) in ids.enumerated() where length(Vec3(g.vertices[i].position.x, 0, g.vertices[i].position.z)) > 1e-3 {
            if let n = normals[id], length(n - g.vertices[i].normal) > 1e-4 { split += 1 } else { normals[id] = g.vertices[i].normal }
        }
        #expect(split == 0)
        // A smooth point's normal is the bend's average: on the equator it points straight out.
        let equator = try #require(g.vertices.first { abs($0.position.y) < 1e-5 && $0.position.z > 0.49 })
        #expect(abs(equator.normal.z - 1) < 1e-3)
    }

    @Test func concaveExtrudeTriangulatesWithTheRightArea() throws {
        for (label, outline) in [("ccw", lShape), ("cw", Array(lShape.reversed()))] {
            let part = MeshBuildPart(shape: .extrude, size: Vec3(1, 1, 0.1), profile: outline)
            let (g0, w) = warnings(part)
            let g = try #require(g0, "\(label)")
            #expect(w.isEmpty)
            expectSolid(g, "L \(label)")
            // Caps: 6 corners, 4 triangles each; sides: a quad per edge.
            #expect(g.vertices.count == 2 * 6 + 4 * 6 && g.indices.count == 3 * (2 * 4 + 2 * 6))
            var front: Float = 0, back: Float = 0
            for t in stride(from: 0, to: g.indices.count, by: 3) {
                let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
                let c = g.vertices[Int(g.indices[t + 2])].position
                let n = cross(b - a, c - a) / 2
                if n.z > 1e-6 { front += n.z } else if n.z < -1e-6 { back -= n.z }
            }
            #expect(abs(front - 0.28) < 1e-5 && abs(back - 0.28) < 1e-5, "\(label): cap area \(front), \(back)")
            #expect(abs(signedVolume(g) - 0.028) < 1e-5)
            #expect(abs(g.bounds.halfExtent.z - 0.05) < 1e-6 && abs(g.bounds.center.z) < 1e-6, "size.z deep, centered")
            // The L's corners are 90°: hard. No side normal is diagonal.
            #expect(!g.vertices.contains { abs($0.normal.x) > 0.01 && abs($0.normal.y) > 0.01 })
        }
    }

    @Test func starExtrudeAndSmoothRound() throws {
        let star = (0..<10).map { i -> Vec2 in
            let a = Float(i) / 10 * 2 * .pi, r: Float = i % 2 == 0 ? 0.5 : 0.2
            return Vec2(r * cosf(a), r * sinf(a))
        }
        let g = try #require(MeshBuildPart(shape: .extrude, size: Vec3(1, 1, 0.2), profile: star).geometry())
        expectSolid(g, "star")
        // A 32-gon's 11° corners are smooth: its side normals point straight out from the center.
        let round = (0..<32).map { i -> Vec2 in Vec2(0.5 * cosf(Float(i) / 32 * 2 * .pi), 0.5 * sinf(Float(i) / 32 * 2 * .pi)) }
        let disc = try #require(MeshBuildPart(shape: .extrude, size: Vec3(2, 2, 0.1), profile: round).geometry())
        expectSolid(disc, "disc")
        #expect(abs(disc.bounds.halfExtent.x - 1) < 1e-4, "size multiplies the outline")
        for v in disc.vertices where v.normal.z == 0 {
            #expect(abs(dot(v.normal, normalize(Vec3(v.position.x, v.position.y, 0))) - 1) < 1e-4)
        }
    }

    @Test func badProfilesWarnInsteadOfCrashing() {
        let cases: [(MeshBuildPart, String)] = [
            (MeshBuildPart(shape: .lathe), "at least 2"),
            (MeshBuildPart(shape: .lathe, profile: [Vec2(0.3, 0)]), "at least 2"),
            (MeshBuildPart(shape: .lathe, profile: [Vec2(0, 0), Vec2(0, 1)]), "no area"),
            (MeshBuildPart(shape: .lathe, profile: [Vec2(.nan, 0), Vec2(0.2, .infinity)]), "aren't numbers"),
            (MeshBuildPart(shape: .extrude, profile: [Vec2(0, 0), Vec2(1, 0)]), "at least 3"),
            (MeshBuildPart(shape: .extrude, profile: [Vec2(0, 0), Vec2(1, 0), Vec2(2, 0)]), "no area"),
            (MeshBuildPart(shape: .extrude, profile: [Vec2(0, 0), Vec2(2, 2), Vec2(2, 0), Vec2(0, 1)]), "crosses itself"),
            (MeshBuildPart(shape: .extrude, size: Vec3(1, 1, 0), profile: lShape), "depth"),
            (MeshBuildPart(shape: .extrude, profile: [Vec2(0, 0), Vec2(.nan, 1), Vec2(1, 0)]), "aren't numbers"),
        ]
        for (part, phrase) in cases {
            let (g, w) = warnings(part)
            #expect(g == nil, "\(phrase): nothing built")
            #expect(w.contains { $0.contains(phrase) }, "\(phrase): \(w)")
            #expect(part.shapeWarnings == w)
        }
        // A NaN point among good ones is dropped and the rest builds.
        let (g, w) = warnings(MeshBuildPart(shape: .extrude, profile: lShape + [Vec2(.nan, 0)]))
        #expect(g != nil && w.count == 1)
        // Fields a shape ignores are pointed out.
        #expect(MeshBuildPart(shape: .sphere, bevel: 0.1).shapeWarnings.first?.contains("bevel") == true)
        #expect(MeshBuildPart(shape: .box, profile: lShape).shapeWarnings.first?.contains("profile") == true)
        #expect(MeshBuildPart(shape: .box, bevel: 0.1).shapeWarnings.isEmpty)
    }

    @Test func newFieldsRoundTripAndStayOutOfOldFiles() throws {
        let plain = MeshBuild(parts: [MeshBuildPart(name: "Crate")])
        let plainJSON = String(decoding: try plain.fileData(), as: UTF8.self)
        #expect(!plainJSON.contains("bevel") && !plainJSON.contains("profile"), "defaults aren't written")

        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Crate", bevel: 0.05),
            MeshBuildPart(name: "Vase", shape: .lathe, profile: [Vec2(0, 0), Vec2(0.2, 0), Vec2(0.1, 0.5)]),
            MeshBuildPart(name: "Sign", shape: .extrude, size: Vec3(1, 1, 0.05), profile: lShape),
        ])
        let data = try build.fileData()
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: data) == build)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"bevel\"") && json.contains("\"profile\""))

        let sparse = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(#"""
            {"parts": [{"shape": "extrude", "profile": [[0,0],[1,0],[0,1]]}, {"shape": "box", "bevel": 0.1}]}
            """#.utf8))
        #expect(sparse.parts[0].shape == .extrude && sparse.parts[0].profile == [Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)])
        #expect(sparse.parts[1].bevel == 0.1 && sparse.parts[1].profile == nil)
    }

    @MainActor @Test func importerReportsProfileWarnings() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildShapeTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "MeshBuildShapes")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let good = MeshBuild(parts: [MeshBuildPart(name: "Vase", shape: .lathe, profile: [Vec2(0.2, 0), Vec2(0.2, 1)])])
        let id = try database.createMeshBuild(good, at: "Models/shapes.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        #expect(database.record(id)?.objects.filter { $0.kind == .mesh }.count == 1)
        var bad = good
        bad.parts.append(MeshBuildPart(name: "Bowtie", shape: .extrude, profile: [Vec2(0, 0), Vec2(2, 2), Vec2(2, 0), Vec2(0, 1)]))
        let warnings = try database.writeMeshBuild(bad, to: id)
        #expect(warnings.contains { $0.contains("part 'Bowtie'") && $0.contains("crosses itself") }, "\(warnings)")
        #expect(database.record(id)?.objects.filter { $0.kind == .mesh }.count == 1, "the bad part has no mesh")
    }
}
