import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Path builds: the spline, frames and banking, terrain following, profile sweeps, repeated
// pieces and the .path importer.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("PathBuildTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Paths")
}

private func flatTerrain(height: Float) -> Terrain {
    var t = Terrain(size: Vec2(64, 64), resolution: 17, heightRange: 20, chunkCells: 16)
    t.normalizeData()
    t.heightData = [UInt16](repeating: UInt16(height / 20 * 65535), count: t.res * t.res)
    return t
}

private func straight(_ length: Float = 20) -> PathBuild {
    PathBuild(points: [PathPoint(Vec3(0, 0, 0)), PathPoint(Vec3(0, 0, -length))], profiles: [PathProfile(shape: .flat, width: 2)])
}

@Suite struct PathBuildTests {
    @Test func fileRoundTripsAndSparseFilesDecode() throws {
        var build = PathBuild.preset(.rail)
        build.terrain = PathTerrain(asset: "Maps/Hills.terrain", offset: Vec3(1, 2, 3), height: 0.2)
        #expect(try AssetJSON.decoder().decode(PathBuild.self, from: build.fileData()) == build)
        let sparse = try AssetJSON.decoder().decode(PathBuild.self, from: Data("{}".utf8))
        #expect(sparse == PathBuild())
        let short = try AssetJSON.decoder().decode(PathBuild.self, from: Data(#"{"points": [[1, 2, 3], {"position": [4, 5, 6], "bank": 10}]}"#.utf8))
        #expect(short.points == [PathPoint(Vec3(1, 2, 3)), PathPoint(Vec3(4, 5, 6), bank: 10)])
        for kind in PathKind.allCases { #expect(PathBuild.preset(kind).kind == kind && !PathBuild.preset(kind).profiles.isEmpty) }
    }

    @Test func samplesFollowTheCurveAtEvenSpacing() {
        let build = straight()
        let samples = build.samples()
        #expect(abs(build.length - 20) < 0.01)
        #expect(samples.count == 41, "every 0.5 m")
        #expect(samples.first?.position == Vec3(0, 0, 0) && abs((samples.last?.position.z ?? 0) + 20) < 1e-3)
        let s = samples[10]
        #expect(abs(s.forward.z + 1) < 1e-4 && abs(s.right.x - 1) < 1e-4 && abs(s.up.y - 1) < 1e-4, "forward -Z, right +X")

        let curve = PathBuild.preset(.road)
        let points = curve.controlPositions
        let curveSamples = curve.samples()
        for p in points {
            #expect(curveSamples.contains { length($0.position - p) < 0.3 }, "the spline passes through \(p)")
        }
        // Even spacing.
        let steps = zip(curveSamples, curveSamples.dropFirst()).map { length($1.position - $0.position) }
        #expect((steps.max() ?? 0) - (steps.min() ?? 0) < 0.05)
        // Same math as CameraPath.
        let camera = CameraPath(points: points)
        #expect(length(camera.position(at: 1.5, controlPoints: points) - curve.curvePosition(at: 1.5)) < 1e-5)
    }

    @Test func closedPathsWrapAndStraightPathsKeepCorners() {
        let square = [Vec3(0, 0, 0), Vec3(10, 0, 0), Vec3(10, 0, 10), Vec3(0, 0, 10)].map { PathPoint($0) }
        var build = PathBuild(points: square, closed: true, smooth: false)
        let samples = build.samples()
        #expect(abs(build.length - 40) < 0.01)
        #expect(length(samples.first!.position - samples.last!.position) < 1e-4)
        #expect(samples.contains { length($0.position - Vec3(10, 0, 10)) < 1e-4 }, "corners are samples")
        build.pieces = [PathPiece(spacing: 5)]
        #expect(build.instances(of: build.pieces[0], samples: samples).count == 8, "no doubled piece where the loop closes")
        build.closed = false
        #expect(build.instances(of: build.pieces[0], samples: build.samples()).count == 7)
    }

    @Test func bankingRollsTheFrame() {
        var build = straight()
        build.points[0].bank = 30
        build.points[1].bank = 30
        let s = build.samples()[5]
        #expect(s.right.y < -0.49 && s.right.y > -0.51, "positive bank lowers the right side")
        #expect(abs(dot(s.right, s.up)) < 1e-4 && abs(dot(s.forward, s.up)) < 1e-4)

        // Auto bank leans into a right turn.
        var turn = PathBuild(points: [PathPoint(Vec3(0, 0, 0)), PathPoint(Vec3(0, 0, -10)), PathPoint(Vec3(10, 0, -20))], autoBank: 20)
        let middle = turn.samples()[turn.samples().count / 2]
        #expect(middle.bank > 5 && middle.right.y < 0)
        turn.autoBank = 0
        #expect(turn.samples()[turn.samples().count / 2].bank == 0)
    }

    @Test func followsTerrainHeight() {
        var build = straight()
        build.terrain = PathTerrain(asset: "x.terrain", offset: Vec3(0, 1, 0), height: 0.1)
        let ground = flatTerrain(height: 5)
        let samples = build.samples(on: ground)
        #expect(samples.allSatisfy { abs($0.position.y - 6.1) < 0.01 })

        var sloped = Terrain(size: Vec2(64, 64), resolution: 3, heightRange: 10)
        sloped.normalizeData()
        // z = -32 row at full height, z = +32 row at 0: the path climbs as it runs to -z.
        sloped.heightData = [65535, 65535, 65535, 32768, 32768, 32768, 0, 0, 0]
        let climbing = build.samples(on: sloped)
        #expect(climbing.last!.position.y > climbing.first!.position.y + 2)
        #expect(climbing[10].forward.y > 0.05, "forward tilts up the slope")

        build.pieces = [PathPiece(spacing: 5, offset: Vec3(3, 0.5, 0), mirror: true)]
        let posts = build.instances(of: build.pieces[0], samples: samples, on: ground)
        #expect(posts.count == 10)
        #expect(posts.allSatisfy { abs($0.position.y - 6.6) < 0.01 }, "pieces stand on the ground plus their offset")
        #expect(Set(posts.map { $0.position.x }) == [3, -3])
    }

    @Test func profilesSweepIntoMeshesWithOutwardNormals() throws {
        let build = straight(10)
        let samples = build.samples()
        let flat = try #require(build.mesh(PathProfile(shape: .flat, width: 2), samples: samples))
        #expect(flat.vertices.allSatisfy { abs($0.normal.y - 1) < 1e-4 })
        #expect(abs(flat.bounds.halfExtent.x - 1) < 1e-4)
        func faceNormalsAgree(_ g: MeshGeometry) -> Bool {
            stride(from: 0, to: g.indices.count, by: 3).allSatisfy { i in
                let a = g.vertices[Int(g.indices[i])], b = g.vertices[Int(g.indices[i + 1])], c = g.vertices[Int(g.indices[i + 2])]
                let n = cross(b.position - a.position, c.position - a.position)
                return length(n) < 1e-8 || dot(n, a.normal) > 0
            }
        }
        #expect(faceNormalsAgree(flat))

        let box = try #require(build.mesh(PathProfile(shape: .box, width: 2, height: 1, offset: Vec2(0, 0.5)), samples: samples))
        #expect(faceNormalsAgree(box))
        #expect(abs(box.bounds.center.y - 1) < 1e-4 && abs(box.bounds.halfExtent.y - 0.5) < 1e-4, "stands on the offset")
        #expect(box.vertices.contains { abs($0.normal.z - 1) < 1e-4 } && box.vertices.contains { abs($0.normal.z + 1) < 1e-4 }, "end caps")

        let tube = try #require(build.mesh(PathProfile(shape: .tube, width: 1, sides: 8), samples: samples))
        #expect(faceNormalsAgree(tube))
        #expect(abs(tube.bounds.halfExtent.x - 0.5) < 1e-3)

        var widening = build
        widening.points[1].width = 3
        let wide = try #require(widening.mesh(PathProfile(shape: .flat, width: 2), samples: widening.samples()))
        #expect(abs(wide.bounds.halfExtent.x - 3) < 1e-3, "per-point width scales the profile")

        // A sagging cable hangs lowest midway between its supports.
        let cable = PathProfile(shape: .tube, width: 0.05, sag: 2)
        let hanging = try #require(build.mesh(cable, samples: samples))
        #expect(abs(hanging.bounds.center.y - hanging.bounds.halfExtent.y + 2.025) < 0.05)
        #expect(build.mesh(PathProfile(shape: .custom, points: [Vec2(0, 0)]), samples: samples) == nil)
    }

    @MainActor @Test func importsProfilesPiecesAndFollowsTerrainEdits() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let post = try database.createMeshBuild(MeshBuild(parts: [MeshBuildPart(name: "Post", size: Vec3(0.1, 1, 0.1)),
                                                                 MeshBuildPart(name: "Cap", parent: "Post", position: Vec3(0, 0.55, 0))]),
                                                at: "Models/post.meshbuild")
        _ = post
        let terrain = try database.createTerrain(flatTerrain(height: 4), at: "Maps/flat.terrain")
        var build = PathBuild.preset(.fence, points: [PathPoint(Vec3(0, 0, 0)), PathPoint(Vec3(0, 0, -10))])
        build.pieces.append(PathPiece(name: "Lamps", asset: "Models/post.meshbuild", spacing: 5))
        build.pieces.append(PathPiece(name: "Lost", asset: "Models/missing.meshbuild"))
        build.terrain = PathTerrain(asset: "Maps/flat.terrain", height: 0)
        let id = try database.createPathBuild(build, at: "Paths/fence.path")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importer == "path" && record.importError == nil)
        #expect(database.pathBuild(of: id) == build)
        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(prefab.roots.first)
        #expect(root.name == "fence" && root.children.map(\.name) == ["Top Rail", "Low Rail", "Posts", "Lamps"])
        #expect(root.children[2].children.count == 5 && root.children[2].children[0].collider != nil, "posts every 2.5 m, with colliders")
        #expect(root.children[3].children.count == 3 && root.children[3].children[0].children.map(\.name) == ["Post", "Cap"])
        #expect(abs(root.children[2].children[0].transform.position.y - 4.6) < 0.01, "on the terrain")
        let rail = try #require(root.children[0].mesh.flatMap { database.mesh($0) })
        #expect(abs(rail.bounds.center.y - 4.95 - 0.05) < 0.02)

        let world = World()
        #expect(world.instantiate(prefab).count == 1)
        #expect(world.count(of: Collider.self) == 5)

        // Raising the terrain reimports the path onto the new ground.
        try database.writeTerrain(flatTerrain(height: 8), to: terrain)
        database.refreshAsync()
        database.waitForAll()
        let moved = try #require(database.prefab(AssetReference(id))?.roots.first)
        #expect(abs(moved.children[2].children[0].transform.position.y - 8.6) < 0.01)
    }
}
