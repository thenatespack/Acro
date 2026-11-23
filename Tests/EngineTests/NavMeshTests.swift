import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineRendering

// Navigation meshes: baking (floors stacked above one another, ramps, bridges, off-mesh links),
// paths (A* and the funnel), surface moves, the bake cache, crowd avoidance (ORCA) and behavior
// trees walking on the navmesh around each other.

private func flat(_ a: Vec3, _ b: Vec3) -> Float {
    ((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)).squareRoot()
}

/// A level with two floors: ground (top y = 0, x -15…20, z -12…20), two decks at y = 3 (x -14…-4
/// and 4…14, z -9…9) joined by a bridge over the ground (x -4…4, z -1…1), a ramp from the ground
/// up to the left deck (x -12…-8, z 9…17) and a one-way jump link off the right deck's east edge.
@MainActor func navMeshTestsLevel(link: Bool = true) -> World {
    let world = World()
    world.assignsEntityIDs = true
    world.spawn(Name("NavMeshTests.Ground"), Transform(position: Vec3(2.5, -0.5, 4)), Collider(.box(Vec3(17.5, 0.5, 16))))
    world.spawn(Name("NavMeshTests.DeckWest"), Transform(position: Vec3(-9, 2.75, 0)), Collider(.box(Vec3(5, 0.25, 9))))
    world.spawn(Name("NavMeshTests.DeckEast"), Transform(position: Vec3(9, 2.75, 0)), Collider(.box(Vec3(5, 0.25, 9))))
    world.spawn(Name("NavMeshTests.Bridge"), Transform(position: Vec3(0, 2.85, 0)), Collider(.box(Vec3(4.05, 0.15, 1))))
    // The ramp: top surface from (z 9, y 3) down to (z 17, y 0).
    let run: Float = 8, rise: Float = 3
    let slopeLength = (run * run + rise * rise).squareRoot() + 0.2
    let angle = asin(rise / (run * run + rise * rise).squareRoot())
    let normal = Vec3(0, run, rise) / (run * run + rise * rise).squareRoot()
    let top = Vec3(-10, 1.5, 13)
    world.spawn(Name("NavMeshTests.Ramp"), Transform(position: top - normal * 0.25, rotation: Quat(angle: angle, axis: Vec3(1, 0, 0))),
                Collider(.box(Vec3(2, 0.25, slopeLength / 2))))
    if link {
        world.spawn(Name("NavMeshTests.Jump"), Transform(position: Vec3(13.3, 3, -5)),
                    NavigationLink(end: Vec3(3.5, -3, 0), bidirectional: false, kind: .jump, cost: 1, radius: 1))
    }
    return world
}

@MainActor @Suite struct NavMeshTests {
    @Test func funnelPullsTheStringRoundACorner() {
        // An L corridor: along +x (z -1…1), then along -z (x 9…11). Portals across it, left and
        // right seen walking through (walking +x, left is +z).
        var portals: [(left: Vec3, right: Vec3)] = []
        for x in stride(from: Float(1), through: 9, by: 1) { portals.append((Vec3(x, 0, 1), Vec3(x, 0, -1))) }
        portals.append((Vec3(11, 0, 1), Vec3(9, 0, -1)))
        for z in stride(from: Float(-2), through: -9, by: -1) { portals.append((Vec3(11, 0, z), Vec3(9, 0, z))) }
        let path = NavMesh.funnel(start: Vec3(0, 0, 0), end: Vec3(10, 0, -10), portals: portals)
        #expect(path.count == 3, "\(path)")
        #expect(flat(path[1], Vec3(9, 0, -1)) < 0.01, "hugs the inside corner: \(path)")
        // A straight corridor stays straight.
        let straight = NavMesh.funnel(start: .zero, end: Vec3(10, 0, 0), portals: Array(portals.prefix(9)))
        #expect(straight.count == 2, "\(straight)")
    }

    @Test func bakesAroundWallsAndFindsPaths() throws {
        let world = World()
        world.spawn(Transform(position: Vec3(0, -0.5, 0)), Collider(.box(Vec3(12, 0.5, 12))))
        world.spawn(Transform(position: Vec3(0, 1, 0)), Collider(.box(Vec3(6, 1, 0.25))))
        let report = try #require(world.bakeNavMesh())
        let mesh = report.navMesh
        #expect(world.navMesh == mesh)
        #expect(mesh.polygonCount > 3 && mesh.polygonCount < 400, "\(mesh.polygonCount) polygons")
        #expect(mesh.islandCount == 1 && report.warnings.isEmpty, "\(report.warnings)")
        #expect(mesh.locate(Vec3(0, 0, -5)) != nil && mesh.locate(Vec3(0, 0, 5)) != nil)
        #expect(mesh.locate(Vec3(0, 0, 0)) == nil && mesh.locate(Vec3(3, 0, 0.4)) == nil, "the wall and the agent radius around it")
        #expect(mesh.locate(Vec3(0, 2, 0)) == nil, "the wall's top is too narrow to stand on")
        #expect(!mesh.isClear(from: Vec3(0, 0, -5), to: Vec3(0, 0, 5)))
        #expect(mesh.isClear(from: Vec3(-3, 0, -5), to: Vec3(3, 0, -8)))
        #expect(mesh.areConnected(Vec3(0, 0, -5), Vec3(0, 0, 5)))

        let path = try #require(world.findPath(from: Vec3(0, 0, -5), to: Vec3(0, 0, 5)))
        #expect(path.count >= 3 && path.count <= 8, "string-pulled round one (rounded) end of the wall: \(path)")
        #expect(flat(path.first!, Vec3(0, 0, -5)) < 0.01 && flat(path.last!, Vec3(0, 0, 5)) < 0.01)
        #expect(NavigationGrid.length(of: path) > 15.6 && NavigationGrid.length(of: path) < 17.5, "\(NavigationGrid.length(of: path))")
        for (a, b) in zip(path, path.dropFirst()) { #expect(mesh.isClear(from: a, to: b), "\(a) → \(b)") }
        for p in path { #expect(abs(p.y) < 0.01) }
        #expect(world.findPath(from: Vec3(-3, 0, -5), to: Vec3(3, 0, -8))?.count == 2)
        #expect(world.findPath(from: Vec3(0, 0, -5), to: Vec3(0, 0, 40)) == nil)
        let partial = try #require(world.findPath(from: Vec3(0, 0, -5), to: Vec3(0, 0, 40), partial: true))
        #expect((partial.last?.z ?? 0) > 10)
    }

    @Test func walksBetweenFloorsOverRampsAndBridges() throws {
        let world = navMeshTestsLevel()
        let report = try #require(world.bakeNavMesh())
        let mesh = report.navMesh
        #expect(mesh.offMeshLinks.count == 1, "\(report.warnings)")
        #expect(mesh.islandCount == 1, "\(report.warnings)")
        // The ground goes on under the bridge and the decks.
        #expect(abs((mesh.locate(Vec3(0, 0, 0))?.point.y ?? -9) - 0) < 0.05)
        #expect(abs((mesh.locate(Vec3(0, 3, 0))?.point.y ?? -9) - 3) < 0.05)
        #expect(abs((mesh.locate(Vec3(-9, 0, 3))?.point.y ?? -9) - 0) < 0.05, "under the deck")
        #expect(abs((mesh.locate(Vec3(-10, 1.5, 13))?.point.y ?? -9) - 1.5) < 0.1, "halfway up the ramp")

        // Ground to the west deck: up the ramp.
        let up = try #require(world.findNavigationPath(from: Vec3(0, 0, -6), to: Vec3(-9, 3, -5)))
        #expect(abs(up.points.last!.y - 3) < 0.05)
        #expect(up.points.contains { $0.z > 9.5 }, "via the ramp: \(up.points)")
        #expect(up.segments.allSatisfy { $0 == .walk })
        #expect(up.points.count <= 12, "a few corners and the ramp's foot and top, not every voxel: \(up.points)")
        // Consecutive points never cut through the air: the line between them stays near the surface (within a step).
        for (a, b) in zip(up.points, up.points.dropFirst()) {
            for k in 1..<8 {
                let p = a + (b - a) * (Float(k) / 8)
                if let h = mesh.locate(p, vertical: 0.3)?.point.y { #expect(abs(h - p.y) < 0.45, "\(a) → \(b) at \(p): surface \(h)") }
            }
        }
        // Deck to deck: over the bridge, never down to the ground.
        let across = try #require(world.findPath(from: Vec3(-9, 3, 5), to: Vec3(9, 3, 5)))
        #expect(across.allSatisfy { $0.y > 2.9 }, "\(across)")
        #expect(across.contains { abs($0.x) < 4.5 && abs($0.z) <= 1.05 } || across.count == 4, "\(across)")
        // East deck to the ground east of it: the jump (one way), far shorter than walking round.
        let down = try #require(world.findNavigationPath(from: Vec3(9, 3, -5), to: Vec3(18, 0, -5)))
        #expect(down.segments.contains(.jump), "\(down.points) \(down.segments)")
        #expect(down.length < 15, "\(down.length)")
        // And back up: no jumping up, so the long way (ramp, west deck, bridge).
        let back = try #require(world.findNavigationPath(from: Vec3(18, 0, -5), to: Vec3(9, 3, -5)))
        #expect(!back.segments.contains(.jump))
        #expect(back.points.contains { $0.z > 9.5 } && back.length > 30, "\(back.length)")
    }

    @Test func linksOffTheMeshAreReported() throws {
        let world = navMeshTestsLevel(link: false)
        world.spawn(Name("NavMeshTests.Nowhere"), Transform(position: Vec3(40, 5, 40)), NavigationLink(end: Vec3(2, 0, 0)))
        // A closed pen nobody can get into.
        for (p, h) in [(Vec3(16, 1, 14), Vec3(3, 1, 0.2)), (Vec3(16, 1, 19.5), Vec3(3, 1, 0.2)),
                       (Vec3(13.2, 1, 16.75), Vec3(0.2, 1, 2.6)), (Vec3(18.8, 1, 16.75), Vec3(0.2, 1, 2.6))] {
            world.spawn(Transform(position: p), Collider(.box(h)))
        }
        let report = try #require(world.bakeNavMesh())
        #expect(report.navMesh.offMeshLinks.isEmpty)
        #expect(report.warnings.contains { $0.contains("NavMeshTests.Nowhere") }, "\(report.warnings)")
        #expect(report.warnings.contains { $0.contains("can't be reached") }, "\(report.warnings)")
        #expect(report.navMesh.findPath(from: Vec3(0, 0, -6), to: Vec3(16, 0, 16.75)) == nil)
    }

    @Test func movesSlideAlongWallsAndFollowTheSurface() throws {
        let world = navMeshTestsLevel()
        let mesh = try #require(world.bakeNavMesh()?.navMesh)
        // Walking at the wall of the west deck's edge (a drop) from the deck: stops at the edge.
        let start = try #require(mesh.locate(Vec3(-9, 3, 0)))
        let moved = mesh.move(from: start, to: Vec3(-9, 3, -20))
        #expect(moved.point.z > -9 && moved.point.z < -8, "stops at the edge, less the radius: \(moved.point)")
        #expect(abs(moved.point.y - 3) < 0.01)
        // Diagonally into the edge: slides along it.
        let slid = mesh.move(from: start, to: Vec3(-6, 3, -20))
        #expect(slid.point.x > -7.5, "slid east along the edge: \(slid.point)")
        // Up the ramp, the height follows.
        let foot = try #require(mesh.locate(Vec3(-10, 0, 17.5)))
        let climbed = mesh.move(from: foot, to: Vec3(-10, 0, 15))
        #expect(abs(climbed.point.y - 0.75) < 0.1, "\(climbed.point)")
    }

    @Test func cachesBakesAndRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NavMeshTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let world = navMeshTestsLevel()
        world.navigationCache = NavigationBakeCache(directory: directory)
        let first = try #require(world.bakeNavMesh())
        #expect(!first.cached)
        #expect(NavigationBakeCache.files(in: directory).count == 1)
        let second = try #require(world.bakeNavMesh())
        #expect(second.cached && second.navMesh == first.navMesh)
        // Moving a collider changes the key.
        var moved: Entity?
        world.query(Name.self) { e, n in if n.value == "NavMeshTests.Bridge" { moved = e } }
        world.modify(Transform.self, for: moved!) { $0.position.z += 2 }
        let third = try #require(world.bakeNavMesh())
        #expect(!third.cached && third.navMesh != first.navMesh)
        #expect(!(try #require(world.bakeNavMesh(useCache: false))).cached)
        // Codable round trip keeps queries working.
        let data = try JSONEncoder().encode(first.navMesh)
        let decoded = try JSONDecoder().decode(NavMesh.self, from: data)
        #expect(decoded == first.navMesh && decoded.islandCount == first.navMesh.islandCount)
        #expect(decoded.findPath(from: Vec3(0, 0, -6), to: Vec3(-9, 3, -5)) == first.navMesh.findPath(from: Vec3(0, 0, -6), to: Vec3(-9, 3, -5)))
        // Old settings and areas decode with the new keys' defaults.
        let area = try JSONDecoder().decode(NavigationArea.self, from: Data(#"{"size": [10, 4, 10], "agentRadius": 0.3}"#.utf8))
        #expect(area.navMesh && area.voxelSize == 0 && area.maxPolygonSize == 8 && area.agentRadius == 0.3)
    }

    @Test func gridIsTheFallbackWithoutANavMesh() throws {
        let world = navMeshTestsLevel(link: false)
        let grid = try #require(world.bakeNavigation(settings: NavigationSettings(navMesh: false)))
        #expect(world.navMesh == nil && world.navigation == grid)
        #expect(world.navigationSurface is NavigationGrid)
        #expect(world.findPath(from: Vec3(16, 0, -6), to: Vec3(16, 0, 6)) != nil)
        world.bakeNavigation()
        #expect(world.navMesh != nil && world.navigationSurface is NavMesh)
        world.clearNavigation()
        #expect(world.navigationSurface == nil)
    }

    @Test func orcaAgentsPassEachOther() {
        // Two agents walking straight at each other, and a crossing pair.
        var agents = [CrowdAgent(position: Vec3(-5, 0, 0.01), radius: 0.4, maxSpeed: 2),
                      CrowdAgent(position: Vec3(5, 0, 0), radius: 0.4, maxSpeed: 2),
                      CrowdAgent(position: Vec3(0, 0, -5), radius: 0.4, maxSpeed: 2),
                      CrowdAgent(position: Vec3(0.02, 0, 5), radius: 0.4, maxSpeed: 2)]
        let goals = [Vec3(5, 0, 0), Vec3(-5, 0, 0), Vec3(0, 0, 5), Vec3(0, 0, -5)]
        let crowd = NavigationCrowd()
        var closest: Float = .infinity
        let dt: Float = 1 / 60
        for _ in 0..<600 {
            for i in agents.indices {
                let to = goals[i] - agents[i].position
                let d = length(to)
                agents[i].preferredVelocity = d > 1e-3 ? to / d * min(2, d / dt) : .zero
            }
            let v = crowd.solve(agents, dt: dt)
            for i in agents.indices {
                agents[i].velocity = v[i]
                agents[i].position += v[i] * dt
            }
            for i in agents.indices { for j in agents.indices where j > i { closest = min(closest, flat(agents[i].position, agents[j].position)) } }
        }
        #expect(closest > 0.75, "never overlapped (radii 0.4 each): \(closest)")
        for i in agents.indices { #expect(flat(agents[i].position, goals[i]) < 0.3, "agent \(i) arrived: \(agents[i].position)") }
        // Deterministic.
        #expect(crowd.solve(agents, dt: dt) == crowd.solve(agents, dt: dt))
    }

    @Test func behaviorTreesWalkTheNavMeshAndAvoidEachOther() throws {
        let world = navMeshTestsLevel()
        func tree(_ goal: Vec3) -> BehaviorTree {
            BehaviorTree(nodes: [BehaviorNode("go", .moveTo, ["position": .array([.double(Double(goal.x)), .double(Double(goal.y)), .double(Double(goal.z))]),
                                                                "arriveDistance": .double(0.2)])], speed: 3, turnSpeed: 0)
        }
        BehaviorTreeLibrary.register(tree(Vec3(18, 0, -5)), as: "NavMeshTests.jumper")
        BehaviorTreeLibrary.register(tree(Vec3(5, 0, -6)), as: "NavMeshTests.east")
        BehaviorTreeLibrary.register(tree(Vec3(-5, 0, -6)), as: "NavMeshTests.west")
        world.addBehaviorTrees()
        // One jumps off the east deck; two walk head-on along the ground under the bridge.
        let jumper = world.spawn(Transform(position: Vec3(9, 3, -5)), BehaviorTreeRunner(tree: "NavMeshTests.jumper"))
        let a = world.spawn(Transform(position: Vec3(-5, 0, -6)), BehaviorTreeRunner(tree: "NavMeshTests.east"))
        let b = world.spawn(Transform(position: Vec3(5, 0, -6.02)), BehaviorTreeRunner(tree: "NavMeshTests.west"))
        var closest: Float = .infinity
        var highest: Float = 0
        var crossed = false
        for _ in 0..<600 {
            world.update(dt: 1.0 / 60)
            let pa = world.get(Transform.self, for: a)!.position, pb = world.get(Transform.self, for: b)!.position
            closest = min(closest, flat(pa, pb))
            highest = max(highest, world.get(Transform.self, for: jumper)!.position.y)
            if world.get(BehaviorTreeState.self, for: jumper)?.isCrossingLink == true { crossed = true }
        }
        #expect(world.navMesh != nil, "the system baked a navmesh")
        #expect(closest > 0.7, "the two walkers kept apart (radius 0.4 each): \(closest)")
        let pa = world.get(Transform.self, for: a)!.position, pb = world.get(Transform.self, for: b)!.position
        #expect(flat(pa, Vec3(5, 0, -6)) < 0.3 && flat(pb, Vec3(-5, 0, -6)) < 0.3, "both arrived: \(pa) \(pb)")
        let pj = world.get(Transform.self, for: jumper)!.position
        #expect(crossed && highest > 3.3, "jumped in an arc: \(highest)")
        #expect(flat(pj, Vec3(18, 0, -5)) < 0.3 && abs(pj.y) < 0.05, "landed and arrived: \(pj)")
    }
}
