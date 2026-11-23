import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersLogic
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineRendering

// The navigation tools as an agent uses them: navigation.bake (with the Library cache),
// navigation.query and navigation.overlay.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct NavigationToolsTests {
    @Test func bakeQueryAndOverlay() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("NavigationToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        #expect(try call(session, "navigation.bake")["baked"] as? Bool == false, "nothing to bake")

        let world = session.world
        world.spawn(Name("NavigationToolsTests.Floor"), Transform(position: Vec3(0, -0.5, 0)), Collider(.box(Vec3(10, 0.5, 10))))
        world.spawn(Name("NavigationToolsTests.Wall"), Transform(position: Vec3(0, 1, 0)), Collider(.box(Vec3(5, 1, 0.25))))
        world.spawn(Name("NavigationToolsTests.Deck"), Transform(position: Vec3(7, 2.75, 7)), Collider(.box(Vec3(2, 0.25, 2))))
        let baked = try call(session, "navigation.bake")
        #expect(baked["baked"] as? Bool == true && baked["cached"] as? Bool == false)
        #expect((baked["polygons"] as? Int ?? 0) > 3)
        #expect(baked["islands"] as? Int == 2, "the deck can't be reached")
        #expect((baked["warnings"] as? [String] ?? []).contains { $0.contains("can't be reached") }, "\(baked)")
        #expect((baked["cacheFile"] as? String)?.hasPrefix("Library/Navigation/") == true)
        // The same level again: from the Library cache.
        let again = try call(session, "navigation.bake")
        #expect(again["cached"] as? Bool == true && again["polygons"] as? Int == baked["polygons"] as? Int)
        #expect(try call(session, "navigation.bake", ["force": true])["cached"] as? Bool == false)

        let path = try call(session, "navigation.query", ["from": [0, 0, -4], "to": [0, 0, 4]])
        #expect(path["surface"] as? String == "navmesh" && path["found"] as? Bool == true)
        #expect((path["length"] as? Double ?? 0) > 10, "around the wall")
        #expect((path["segments"] as? [String])?.allSatisfy { $0 == "walk" } == true)
        #expect(path["connected"] as? Bool == true)
        let blocked = try call(session, "navigation.query", ["from": [0, 0, -4], "to": [7, 3, 7]])
        #expect(blocked["found"] as? Bool == false && blocked["toOnMesh"] as? Bool == true && blocked["connected"] as? Bool == false)
        let point = try call(session, "navigation.query", ["point": [0, 0, 0]])
        #expect(point["pointOnMesh"] as? Bool == false && point["nearest"] != nil, "on the wall: off the mesh, a walkable point nearby")
        #expect(throws: (any Error).self) { try call(session, "navigation.query", ["from": [0, 0, 0]]) }

        #expect(try call(session, "navigation.overlay")["shown"] as? Bool == true)
        #expect(session.sceneOverlays["navigation"] != nil)
        let draw = DebugDraw()
        session.sceneOverlays["navigation"]?(draw, world)
        #expect(draw.triangleCount > 0 && draw.segmentCount > 0)
        try call(session, "navigation.overlay", ["show": false])
        #expect(session.sceneOverlays["navigation"] == nil)
    }
}
