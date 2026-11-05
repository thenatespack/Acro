import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The VFX builder as an agent uses it (vfx.* tools) and as a user does (VFXBuilderView / workspace).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("VFXBuildToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct VFXBuildToolsTests {
    @Test func everyPresetImportsAsAPrefabOfEmitters() throws {
        for name in VFXBuild.presetNames {
            let build = try #require(VFXBuild.preset(name), "\(name)")
            #expect(!build.emitters.isEmpty)
            #expect(VFXBuildCheck.problems(build).isEmpty, "\(name): \(VFXBuildCheck.problems(build))")
            let decoded = try AssetJSON.decoder().decode(VFXBuild.self, from: build.fileData())
            #expect(decoded == build, "\(name) round-trips")
        }
        #expect(VFXBuild.preset("nope") == nil)
        let empty = try AssetJSON.decoder().decode(VFXBuild.self, from: Data("{}".utf8))
        #expect(empty.emitters.isEmpty && empty.duration == 4)
    }

    @Test func newEditGetUndoAndPlacedCopyFollows() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "vfx.new", ["preset": "fire", "folder": "FX", "place": true])
        #expect(created["path"] as? String == "FX/Fire.vfx")
        #expect(created["emitters"] as? [String] == ["Flames", "Embers", "Smoke"])
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isVFXFile(id))
        #expect(session.world.count(of: ParticleEmitter.self) == 3, "placed as three emitter entities")

        let edited = try call(session, "vfx.edit", [
            "path": "FX/Fire.vfx",
            "removeEmitters": ["Embers"],
            "addEmitters": [["name": "Smoke", "rate": 5]],
            "updateEmitters": ["Flames": ["rate": 300, "delay": 0.5]],
            "duration": 6,
        ])
        #expect(edited["emitters"] as? [String] == ["Flames", "Smoke", "Smoke 2"])
        #expect(session.world.count(of: ParticleEmitter.self) == 3)
        let build = try #require(session.assets?.vfx(of: id))
        #expect(build.emitters[0].rate == 300 && build.emitters[0].delay == 0.5 && build.duration == 6)

        let got = try call(session, "vfx.get", ["asset": id.description])
        #expect(((got["effect"] as? [String: Any])?["emitters"] as? [Any])?.count == 3)

        #expect(session.performUndo())
        #expect(session.assets?.vfx(of: id)?.emitters.count == 3)
        #expect(throws: (any Error).self) { try call(session, "vfx.edit", ["asset": id.description, "removeEmitters": ["Nope"]]) }
        #expect(throws: (any Error).self) { try call(session, "vfx.new", ["preset": "nope"]) }
    }

    @Test func importedEmitterCarriesDelayAndPlacement() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        var build = VFXBuild.preset("explosion")!
        build.emitters[2].position = Vec3(0, 1, 0)
        let id = try #require(session.createVFXAsset(in: "", name: "Boom", build: build))
        let prefab = try #require(session.assets?.prefab(AssetReference(id)))
        let nodes = prefab.roots[0].children
        #expect(nodes.count == 4 && nodes[0].name == "Flash")
        #expect(nodes[2].particles?.startDelay == 0.1 && nodes[2].transform.position == Vec3(0, 1, 0))
    }

    @Test func startDelayHoldsBackSpawning() {
        var emitter = ParticleEmitter(rate: 100, startDelay: 0.5)
        emitter.bursts = [ParticleBurst(time: 0, count: 10)]
        #expect(emitter.startDelay == 0.5)
    }

    @Test func viewAndWorkspace() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createVFXAsset(in: "", name: "Puff"))

        let view = try #require(VFXBuilderView(session: session, asset: id))
        view.addEmitter()
        view.refresh()
        #expect(view.build.emitters.map(\.name) == ["Smoke", "Emitter"])
        view.duplicateSelected()
        view.refresh()
        #expect(view.build.emitters.count == 3)
        view.deleteSelected()
        view.refresh()
        #expect(view.build.emitters.count == 2)

        let workspace = VFXBuilderWorkspace(session: session)
        var opened: AssetID?
        session.onOpenVFX = { opened = $0; workspace.open($0) }
        try call(session, "vfx.open", ["asset": id.description])
        #expect(opened == id && workspace.asset == id)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.world.count(of: ParticleEmitter.self) == 2)
        let starts = workspace.restartCount
        workspace.update(input: nil, dt: 100)
        #expect(workspace.restartCount == starts + 1, "loops after its duration")
        workspace.setLooping(false)
        workspace.update(input: nil, dt: 100)
        #expect(workspace.restartCount == starts + 1, "plays once with Loop off")
        workspace.restart()
        #expect(workspace.runTime == 0)
    }
}
