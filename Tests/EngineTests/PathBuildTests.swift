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

@Suite struct PathBuildInsertTests {
    @Test func insertingOnTheCurveKeepsItsShape() {
        var build = PathBuild(points: [PathPoint(Vec3(0, 0, 0), bank: 0, width: 1), PathPoint(Vec3(10, 0, 0), bank: 10, width: 3),
                                       PathPoint(Vec3(10, 0, 10))])
        let before = build.curvePosition(at: 0.5)
        #expect(build.insertPoint(atU: 0.5) == 1)
        #expect(build.points.count == 4 && build.points[1].position == before)
        #expect(build.points[1].bank == 5 && build.points[1].width == 2)
        #expect(build.insertPoint(atU: 1.005) == nil, "too near a point")
        #expect(build.insertPoint(atU: 3.5) == nil, "past the end")
        build.closed = true
        #expect(build.insertPoint(atU: 3.5) == 4, "a closed path's last span wraps to the first point")
    }
}

private func bumpyTerrain() -> Terrain {
    var t = Terrain(size: Vec2(64, 64), resolution: 65, heightRange: 20, chunkCells: 16)
    t.normalizeData()
    for z in 0..<t.res {
        for x in 0..<t.res {
            let p = t.position(x: x, z: z)
            let h = 6 + sinf(p.y * 0.9) + p.x * 0.05
            t.heightData[z * t.res + x] = UInt16(h / 20 * 65535)
        }
    }
    return t
}

@Suite struct PathBuildTerrainShapingTests {
    @Test func flatteningLevelsTheGroundUnderTheRoadAndBlendsAtTheShoulders() {
        var build = straight()
        build.terrain = PathTerrain(asset: "Maps/bumpy.terrain", height: 0.05)
        let ground = bumpyTerrain()
        #expect(build.profileWidth == 2)
        let (flat, report) = build.shapeTerrain(ground, PathTerrainShaping(width: 4, shoulder: 3, smoothing: 30))
        #expect(report.changedSamples > 0 && report.clampedSamples == 0)
        for z in stride(from: Float(-18), through: -2, by: 2) {
            // Level across the road, and smoothed along it (the bumps along z mostly gone).
            #expect(abs(flat.heightAt(x: -1.5, z: z) - flat.heightAt(x: 1.5, z: z)) < 0.01)
            #expect(abs(flat.heightAt(x: 0, z: z) - 6) < 0.35)
        }
        // Past the shoulder: untouched; inside it: between the two.
        #expect(flat.heightAt(x: 8, z: -10) == ground.heightAt(x: 8, z: -10))
        let mid = flat.heightAt(x: 3.5, z: -10), road = flat.heightAt(x: 0, z: -10), wild = ground.heightAt(x: 3.5, z: -10)
        #expect(mid > min(road, wild) - 0.01 && mid < max(road, wild) + 0.01)
        // Shaping again changes nothing much.
        let (_, again) = build.shapeTerrain(flat, PathTerrainShaping(width: 4, shoulder: 3, smoothing: 30))
        #expect(again.largestChange < 0.4)
    }

    @Test func carveOnlyLowersRaiseOnlyRaises() {
        var build = straight()
        build.terrain = PathTerrain(asset: "Maps/bumpy.terrain", height: 0)
        let ground = bumpyTerrain()
        let (carved, _) = build.shapeTerrain(ground, PathTerrainShaping(mode: .carve, width: 3, shoulder: 1, depth: 1.5, smoothing: 0))
        let (raised, _) = build.shapeTerrain(ground, PathTerrainShaping(mode: .raise, width: 3, shoulder: 1, depth: -1.5, smoothing: 0))
        for k in ground.heightData.indices {
            #expect(carved.heightData[k] <= ground.heightData[k])
            #expect(raised.heightData[k] >= ground.heightData[k])
        }
        #expect(abs(carved.heightAt(x: 0, z: -10) - (ground.heightAt(x: 0, z: -10) - 1.5)) < 0.05, "a bed 1.5 m down")
        #expect(abs(raised.heightAt(x: 0, z: -10) - (ground.heightAt(x: 0, z: -10) + 1.5)) < 0.05, "an embankment 1.5 m up")

        // A path that doesn't follow the terrain shapes it to its own heights.
        var bridge = straight()
        bridge.points = bridge.points.map { PathPoint($0.position + Vec3(0, 10, 0)) }
        let (fill, _) = bridge.shapeTerrain(ground, PathTerrainShaping(width: 2, shoulder: 0))
        #expect(abs(fill.heightAt(x: 0, z: -10) - 10) < 0.01)
    }
}

private func road(_ from: Vec3, _ to: Vec3) -> PathBuild {
    PathBuild.preset(.road, points: [PathPoint(from), PathPoint(to)])
}

@Suite struct PathBuildJunctionTests {
    let main = road(Vec3(-30, 0, 0), Vec3(30, 0, 0))

    func layout(_ side: PathBuild, radius: Float = 3) -> PathJunctionLayout {
        let target = PathJunctionTarget(PathJunction(path: "Roads/main.path", radius: radius), other: main, samples: main.samples())
        return side.junctionLayout([target], samples: side.samples())
    }

    @Test func aTJunctionCutsTheSideRoadBackAndPavesRoundedCorners() throws {
        // Ends on the main road's centerline: cut back 3 m (the main road's half width) + 3 m (the radius).
        let side = road(Vec3(0, 0, 30), Vec3(0, 0, 0))
        let t = layout(side)
        #expect(t.warnings.isEmpty && t.made == ["T with Roads/main.path"])
        #expect(t.cuts.count == 1 && abs(t.cuts[0].lowerBound - 24) < 0.05 && abs(t.cuts[0].upperBound - 30) < 0.01)
        let patch = try #require(t.patch)
        let tops = patch.vertices.filter { $0.normal == Vec3(0, 1, 0) }.map(\.position)
        // Between the side road's cut (z 6) and the main road's edge (z 3), widening to 3 + 3 m each side.
        #expect(tops.allSatisfy { $0.z >= 3 - 1e-3 && $0.z <= 6 + 1e-3 && abs($0.y - 0.05) < 1e-3 })
        #expect(abs((tops.map(\.x).max() ?? 0) - 6) < 0.01 && abs((tops.map(\.x).min() ?? 0) + 6) < 0.01)
        #expect(patch.vertices.contains { $0.normal.y == 0 }, "a box road gets skirts")
        for i in stride(from: 0, to: patch.indices.count, by: 3) {
            let a = patch.vertices[Int(patch.indices[i])], b = patch.vertices[Int(patch.indices[i + 1])], c = patch.vertices[Int(patch.indices[i + 2])]
            #expect(dot(cross(b.position - a.position, c.position - a.position), a.normal) >= -1e-5, "faces wound toward their normals")
        }
        // An end that stops short of the road (or runs a little past it) makes the same T.
        #expect(layout(road(Vec3(0, 0, 30), Vec3(0, 0, 4))).made == ["T with Roads/main.path"])
        let past = layout(road(Vec3(0, 0, 30), Vec3(0, 0, -2)))
        #expect(past.made == ["T with Roads/main.path"] && abs(past.cuts[0].upperBound - 32) < 0.01)
        // From the start end too.
        let fromStart = layout(road(Vec3(0, 0, 0), Vec3(0, 0, 30)))
        #expect(fromStart.made == ["T with Roads/main.path"] && fromStart.cuts[0].lowerBound == 0 && abs(fromStart.cuts[0].upperBound - 6) < 0.05)
    }

    @Test func anXJunctionCutsBothSidesAndSkipsPieces() {
        var side = road(Vec3(0, 0, 30), Vec3(0, 0, -30))
        side.pieces = [PathPiece(name: "Lamps", spacing: 2)]
        let x = layout(side, radius: 2)
        #expect(x.made == ["X with Roads/main.path"])
        #expect(x.cuts.count == 1 && abs(x.cuts[0].lowerBound - 25) < 0.05 && abs(x.cuts[0].upperBound - 35) < 0.05)
        let runs = PathBuild.runs(side.samples(), outside: x.cuts)
        #expect(runs.count == 2 && abs((runs[0].last?.distance ?? 0) - 25) < 0.05 && abs((runs[1].first?.distance ?? 0) - 35) < 0.05)
        let lamps = side.instances(of: side.pieces[0], samples: side.samples(), excluding: x.cuts)
        #expect(lamps.count == 31 - 5 && !lamps.contains { abs($0.position.z) < 5 })

        // At an angle the corners still meet both edges.
        let angled = layout(road(Vec3(-20, 0, 20), Vec3(20, 0, -20)))
        #expect(angled.made == ["X with Roads/main.path"] && angled.patch != nil)
        // Nearly parallel roads can't be joined; paths that never meet say so.
        #expect(layout(road(Vec3(-30, 0, 1), Vec3(30, 0, -1))).warnings.contains { $0.contains("shallow") })
        #expect(layout(road(Vec3(-30, 0, 50), Vec3(30, 0, 50))).warnings.contains { $0.contains("don't meet") })
        // Without a flat or box profile there's nothing to pave with.
        var fence = PathBuild.preset(.fence, points: side.points)
        fence.profiles = []
        #expect(layout(fence).warnings.contains { $0.contains("no flat or box") })
    }

    @MainActor @Test func importsJunctionsAndReimportsWhenTheOtherPathChanges() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let mainID = try database.createPathBuild(main, at: "Roads/main.path")
        var side = road(Vec3(0, 0, 30), Vec3(0, 0, 0))
        let plain = try database.createPathBuild(side, at: "Roads/plain.path")
        side.junctions = [PathJunction(path: "Roads/main.path", radius: 3)]
        let id = try database.createPathBuild(side, at: "Roads/side.path")
        database.refreshAsync()
        database.waitForAll()
        #expect(database.record(id)?.importError == nil)
        #expect(database.pathBuild(of: id)?.junctions.count == 1)
        func roadMesh(_ id: AssetID) throws -> MeshGeometry {
            let root = try #require(database.prefab(AssetReference(id))?.roots.first)
            return try #require(root.children.first { $0.name == "Road" }?.mesh.flatMap { database.mesh($0) })
        }
        let joined = try roadMesh(id), whole = try roadMesh(plain)
        func extent(_ g: MeshGeometry) -> (minZ: Float, maxX: Float) { (g.vertices.map(\.position.z).min() ?? 0, g.vertices.map(\.position.x).max() ?? 0) }
        #expect(extent(joined).minZ > 2.9, "stops at the main road's edge, not its centerline")
        #expect(abs(extent(whole).minZ) < 0.01)
        #expect(abs(extent(joined).maxX - 6) < 0.01, "the corners widen it")

        // Moving the main road reimports the side road.
        var moved = main
        moved.points = [PathPoint(Vec3(-30, 0, 5)), PathPoint(Vec3(30, 0, 5))]
        _ = try database.writePathBuild(moved, to: mainID)
        database.refreshAsync()
        database.waitForAll()
        #expect(extent(try roadMesh(id)).minZ > 7.9)

        // By id too; a missing one is reported in the path's own words.
        side.junctions = [PathJunction(path: AssetReference(mainID).description), PathJunction(path: "Roads/gone.path")]
        let warnings = try database.writePathBuild(side, to: id)
        #expect(warnings.contains { $0.contains("junction: no readable path 'Roads/gone.path'") })
        #expect(extent(try roadMesh(id)).minZ > 7.9)
    }
}

// MARK: PathFollower

@MainActor private func run(_ world: World, _ seconds: Double, dt: Double = 0.1) {
    var left = seconds
    while left > 1e-9 {
        let d = min(dt, left)
        world.update(dt: d)
        left -= d
    }
}

@MainActor
@Suite struct PathBuildFollowerTests {
    @Test func followsAtSpeedAndOrientsAlongThePath() throws {
        let world = World()
        let system = try #require(world.addPathFollowers(source: .fixed(["road": straight()])))
        #expect(world.addPathFollowers(source: .fixed([:])) == nil, "installed once")
        let car = world.spawn(Transform(), Name("PathBuildFollowerCar"),
                              PathFollower(path: "road", speed: 4, mode: .once, offset: Vec3(1, 0, 0)))
        world.update(dt: 0)
        var f = try #require(world.get(PathFollower.self, for: car))
        #expect(f.state == .playing && abs(f.length - 20) < 0.01)
        run(world, 2)
        f = try #require(world.get(PathFollower.self, for: car))
        #expect(abs(f.distance - 8) < 0.05)
        let t = try #require(world.get(Transform.self, for: car))
        #expect(length(t.position - Vec3(1, 0, -8)) < 0.05, "8 m along -Z, 1 m to the right")
        #expect(length(t.rotation * Vec3(0, 0, -1) - Vec3(0, 0, -1)) < 1e-3, "faces along the path")

        var events: [PathFollowerEvent.Kind] = []
        system.onEvent = { _, e in events.append(e.kind) }
        run(world, 4)
        f = try #require(world.get(PathFollower.self, for: car))
        #expect(f.state == .finished && f.distance == 20 && events == [.reachedEnd, .finished])
        system.remove()
    }

    @Test func loopsPingPongsAndTakesRequests() throws {
        let world = World()
        world.addPathFollowers(source: .fixed(["road": straight(10)]))
        let loop = world.spawn(Transform(), PathFollower(path: "road", speed: 4, mode: .loop))
        let bounce = world.spawn(Transform(), PathFollower(path: "road", speed: 4, mode: .pingPong, startOffset: 2))
        let back = world.spawn(Transform(), PathFollower(path: "road", speed: 2, mode: .once, orient: .full, reverse: true))
        let idle = world.spawn(Transform(), PathFollower(path: "road", playOnStart: false))
        world.update(dt: 0)
        #expect(world.get(PathFollower.self, for: bounce)?.distance == 2)
        #expect(world.get(PathFollower.self, for: back)?.distance == 10)
        run(world, 3)  // 12 m
        #expect(abs((world.get(PathFollower.self, for: loop)?.distance ?? 0) - 2) < 0.05, "wrapped round")
        let b = try #require(world.get(PathFollower.self, for: bounce))
        #expect(abs(b.distance - 6) < 0.05 && b.direction == -1, "2 + 12 = 14: 8 out, turned, 4 back")
        #expect(abs((world.get(PathFollower.self, for: back)?.distance ?? 0) - 4) < 0.05)
        let r = try #require(world.get(Transform.self, for: back)).rotation
        #expect(length(r * Vec3(0, 0, -1) - Vec3(0, 0, 1)) < 1e-3, "reversing faces the way it travels")
        #expect(world.get(PathFollower.self, for: idle)?.state == .stopped)
        #expect(world.get(Transform.self, for: idle)?.position == Vec3(0, 0, 0), "a stopped follower sits at its start")

        world.modify(PathFollower.self, for: idle) { $0.seek(to: 5) }
        world.update(dt: 0.1)
        #expect(world.get(PathFollower.self, for: idle)?.state == .paused)
        #expect(length((world.get(Transform.self, for: idle)?.position ?? .zero) - Vec3(0, 0, -5)) < 0.01)
        world.modify(PathFollower.self, for: idle) { $0.resume() }
        run(world, 0.5)
        #expect(abs((world.get(PathFollower.self, for: idle)?.distance ?? 0) - 7.5) < 0.05)
        world.modify(PathFollower.self, for: idle) { $0.stop() }
        world.update(dt: 0.1)
        #expect(world.get(PathFollower.self, for: idle)?.distance == 0 && world.get(PathFollower.self, for: idle)?.state == .stopped)
    }

    @Test func placedAtMovesThePathWithItsEntity() throws {
        let world = World()
        world.addPathFollowers(source: .fixed(["road": straight()]))
        _ = world.spawn(Transform(position: Vec3(100, 5, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))), Name("PathBuildFollowerRoad"))
        let rider = world.spawn(Transform(), PathFollower(path: "road", speed: 10, placedAt: "PathBuildFollowerRoad"))
        run(world, 1)
        let p = try #require(world.get(Transform.self, for: rider)).position
        // 10 m along -Z, turned 90° about Y (-Z becomes -X), then moved.
        #expect(length(p - Vec3(90, 5, 0)) < 0.05)
    }

    @Test func codesItsSettingsOnly() throws {
        let f = PathFollower(path: "Roads/a.path", speed: 3, mode: .pingPong, orient: .full, startOffset: 2, offset: Vec3(1, 2, 3),
                             placedAt: "Road", playOnStart: false, reverse: true)
        #expect(try AssetJSON.decoder().decode(PathFollower.self, from: JSONEncoder().encode(f)) == f)
        #expect(try AssetJSON.decoder().decode(PathFollower.self, from: Data("{}".utf8)) == PathFollower())
    }

    @Test func loadsFromTheDatabaseOnTheTerrainAndRunsInScenePlayback() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        _ = try database.createTerrain(flatTerrain(height: 4), at: "Maps/flat.terrain")
        var build = straight()
        build.terrain = PathTerrain(asset: "Maps/flat.terrain", height: 0)
        _ = try database.createPathBuild(build, at: "Paths/road.path")
        ComponentRegistry.register(PathFollower.self)
        let scene = World()
        _ = scene.spawn(Transform(), Name("PathBuildFollowerBus"), PathFollower(path: "Paths/road.path", speed: 5))
        let data = try scene.save()
        let playback = ScenePlayback(module: GameModule(), context: GameContext(input: Input()), assets: { database }, log: { _ in }) { _ in data }
        try playback.load("Main.scene")
        for _ in 0..<10 { playback.world.update(dt: 0.1) }
        var bus: Entity?
        playback.world.query(PathFollower.self) { e, _ in bus = e }
        let p = try #require(bus.flatMap { playback.world.get(Transform.self, for: $0) }).position
        #expect(length(p - Vec3(0, 4, -5)) < 0.1, "5 m along, on the 4 m ground")
    }

    @Test func cookedGamesFollowPathsOnTheirTerrain() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        _ = try database.createTerrain(flatTerrain(height: 4), at: "Maps/flat.terrain")
        var build = straight()
        build.terrain = PathTerrain(asset: "Maps/flat.terrain", height: 0)
        let road = try database.createPathBuild(build, at: "Paths/road.path")
        let scene = World()
        _ = scene.spawn(Transform(), Name("PathBuildFollowerCooked"), PathFollower(path: AssetReference(road).description, speed: 5))
        let sceneURL = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: sceneURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try scene.save().write(to: sceneURL)
        database.scan()
        let report = try AssetCooker.plan(database: database, options: CookOptions(scenes: ["Scenes/Main.scene"]))
            .run(to: project.root.appendingPathComponent("out"))
        let assets = AssetDatabase(mounting: try AssetPack(url: URL(fileURLWithPath: report.packPath)))
        let world = World()
        world.addPathFollowers(assets: { assets })
        let bus = world.spawn(Transform(), PathFollower(path: AssetReference(road).description, speed: 5))
        for _ in 0..<10 { world.update(dt: 0.1) }
        let p = try #require(world.get(Transform.self, for: bus)).position
        #expect(length(p - Vec3(0, 4, -5)) < 0.1, "the pack has the path's source and its terrain")
    }
}
