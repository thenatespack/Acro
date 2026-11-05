import Foundation
import Testing
@testable import Engine

// Mesh builds: shape geometry, animation tracks, editing helpers and the .meshbuild importer.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MeshBuild")
}

/// Every triangle faces away from the mesh's center (for convex shapes), normals are unit length.
private func expectOutwardAndUnit(_ g: MeshGeometry, _ label: String) {
    let center = g.bounds.center
    var inward = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
        let c = g.vertices[Int(g.indices[t + 2])].position
        let n = cross(b - a, c - a)
        if length(n) > 1e-7, dot(n, (a + b + c) / 3 - center) < -1e-6 { inward += 1 }
    }
    #expect(inward == 0, "\(label): \(inward) inward triangles")
    #expect(g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-3 }, "\(label): normals")
}

@Suite struct MeshBuildTests {
    @Test func everyShapeFitsItsSizeBox() {
        let size = Vec3(2, 1, 0.5)
        for shape in MeshBuildShape.allCases {
            let part = MeshBuildPart(shape: shape, size: size, segments: 16)
            guard let g = part.geometry() else {
                #expect(shape == .group)
                continue
            }
            #expect(!g.indices.isEmpty && g.indices.count % 3 == 0, "\(shape)")
            let b = g.bounds
            // A plane is flat; a torus's tube is at most half its radius thick.
            let expected = shape == .plane ? Vec3(1, 0, 0.25) : shape == .torus ? Vec3(1, 0.125, 0.25) : size / 2
            #expect(abs(b.halfExtent.x - expected.x) < 1e-3 && abs(b.halfExtent.y - expected.y) < 1e-3
                    && abs(b.halfExtent.z - expected.z) < 1e-3, "\(shape): \(b.halfExtent)")
            #expect(length(b.center) < 1e-3, "\(shape) is centered")
            if shape != .plane && shape != .tube && shape != .torus { expectOutwardAndUnit(g, "\(shape)") }
        }
    }

    @Test func worldUVKeepsTextureScaleInMeters() throws {
        let g = try #require(MeshBuildPart(shape: .box, size: Vec3(4, 1, 1), worldUV: true).geometry())
        let us = g.vertices.filter { $0.normal.z > 0.5 }.map(\.uv.x)
        #expect(abs((us.max() ?? 0) - (us.min() ?? 0) - 4) < 1e-4)
    }

    @Test func motionsAndKeysBecomeAdditiveCurves() {
        var build = MeshBuild(parts: [MeshBuildPart(name: "Fan")])
        build.animations = [MeshBuildAnimation(name: "Run", motions: [MeshBuildMotion(part: "Fan", kind: .spin, axis: .z, period: 2)])]
        let tracks = build.animatorTracks(for: "Fan")
        #expect(tracks.count == 1)
        #expect(tracks[0].target == "Transform.rotation.z" && tracks[0].mode == .curve && tracks[0].additive)
        #expect(abs(tracks[0].value(at: 1) - 180) < 1e-3)
        #expect(abs(tracks[0].value(at: 3) - 180) < 1e-3, "loops")

        build.animations = [MeshBuildAnimation(name: "Grow", loop: .once, tracks: [
            MeshBuildTrack(part: "Fan", property: .scale, keys: [MeshBuildKey(1, Vec3(1, 1, 1)), MeshBuildKey(2, Vec3(1, 3, 1))]),
        ])]
        let grow = build.animatorTracks(for: "Fan")
        #expect(grow.map(\.target) == ["Transform.scale.y"], "only the axis that changes")
        #expect(abs(grow[0].value(at: 0.5)) < 1e-4, "holds the first key before it")
        #expect(abs(grow[0].value(at: 5) - 2) < 1e-4, "scale offset from 1, held after the end")

        build.animations[0].autoplay = false
        #expect(build.animatorTracks(for: "Fan").isEmpty)
    }

    @Test func renameAndRemoveKeepReferencesConsistent() {
        var build = MeshBuild(parts: [MeshBuildPart(name: "A"), MeshBuildPart(name: "B", parent: "A"),
                                      MeshBuildPart(name: "C", parent: "B")],
                              animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "B"), MeshBuildMotion(part: "C")])])
        build.renamePart("B", to: "Arm")
        #expect(build.parts.map(\.name) == ["A", "Arm", "C"] && build.parts[2].parent == "Arm")
        #expect(build.animations[0].motions[0].part == "Arm")
        build.removeParts(["Arm"])
        #expect(build.parts.map(\.name) == ["A", "C"] && build.parts[1].parent == "A")
        #expect(build.animations[0].motions.map(\.part) == ["C"])
        #expect(build.uniquePartName("A") == "A 2" && build.uniquePartName("Z") == "Z")
    }

    @Test func sparseFilesDecodeWithDefaults() throws {
        let build = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(#"{"parts": [{"shape": "cone"}]}"#.utf8))
        #expect(build.parts.count == 1 && build.parts[0].shape == .cone && build.parts[0].size == Vec3(1, 1, 1))
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: build.fileData()) == build)
    }

    @MainActor @Test func importsAPrefabTreeWithMaterialsAndAnimators() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let texture = try database.createProceduralTexture(ProceduralTexture(generator: .checker, width: 8, height: 8),
                                                           at: "Textures/check.proctex")
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Body", size: Vec3(2, 1, 1), color: Vec3(1, 0, 0), texture: "Textures/check.proctex"),
            MeshBuildPart(name: "Pivot", shape: .group, parent: "Body", position: Vec3(0, 1, 0)),
            MeshBuildPart(name: "Blade", parent: "Pivot", glow: Vec3(0, 1, 0)),
            MeshBuildPart(name: "Loose", parent: "Nobody"),
        ], animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "Pivot", kind: .spin)])])
        let id = try database.createMeshBuild(build, at: "Models/fan.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importer == "meshbuild")
        #expect(record.objects.filter { $0.kind == .mesh }.count == 3, "a group has no mesh")
        #expect(database.meshBuild(of: id) == build)

        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(prefab.roots.first)
        #expect(root.name == "fan" && root.children.map(\.name) == ["Body", "Loose"], "a missing parent hangs from the root")
        let pivot = try #require(root.children[0].children.first)
        #expect(pivot.mesh == nil && pivot.animator?.tracks.count == 1 && pivot.children.map(\.name) == ["Blade"])

        let bodyMaterial = try #require(root.children[0].material.flatMap { database.material($0) })
        #expect(bodyMaterial.texture == AssetReference(texture, subAsset: "texture"))
        #expect(abs(bodyMaterial.baseColor.x - 1) < 1e-5 && bodyMaterial.baseColor.y == 0)

        let world = World()
        let spawned = world.instantiate(prefab)
        #expect(spawned.count == 1)
        #expect(world.count(of: FieldAnimator.self) == 1)

        var edited = build
        edited.parts[0].size = Vec3(3, 1, 1)
        let revision = database.revision(of: id)
        try database.writeMeshBuild(edited, to: id)
        database.refreshAsync()
        database.waitForAll()
        #expect(database.revision(of: id) > revision)
    }
}
