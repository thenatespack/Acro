import Foundation
import Testing
@testable import EditorCore
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

    @Test func textureAndSubEmitterKeysRoundTripAndAreChecked() throws {
        let json = """
        {"emitters": [
          {"name": "Sparks", "rate": 0, "killOnCollision": true, "texture": "FX/puff.proctex", "atlasColumns": 4, "atlasRows": 2,
           "frameRate": 12, "randomStartFrame": true, "frameBlending": true,
           "subEmitters": [{"trigger": "collision", "emitter": "Pops", "count": 6, "inheritVelocity": 0.5}, {"emitter": "Nope"}]},
          {"name": "Pops", "rate": 0, "subEmitters": [{"trigger": "birth", "emitter": "Sparks"}]}
        ]}
        """
        let build = try AssetJSON.decoder().decode(VFXBuild.self, from: Data(json.utf8))
        let sparks = build.emitters[0]
        #expect(sparks.texture == "FX/puff.proctex" && sparks.atlasColumns == 4 && sparks.atlasRows == 2 && sparks.killOnCollision)
        #expect(sparks.subEmitters == [VFXSubEmitter(.collision, emitter: "Pops", count: 6, inheritVelocity: 0.5), VFXSubEmitter(.death, emitter: "Nope")])
        #expect(try AssetJSON.decoder().decode(VFXBuild.self, from: build.fileData()) == build)
        let particles = sparks.particleEmitter()
        #expect(particles.atlasColumns == 4 && particles.frameRate == 12 && particles.frameBlending && particles.killOnCollision)

        let problems = VFXBuildCheck.problems(build)
        #expect(problems.contains("emitter 'Sparks': no emitter 'Nope' for its sub-emitter"))
        #expect(problems.contains("emitter 'Sparks': sub-emitter 'Pops' has sub-emitters of its own, which don't run"))
        #expect(!problems.contains { $0.contains("'Pops' has no rate") }, "a target emits through its links")

        var edited = build
        edited.renameEmitter("Pops", to: "Splash")
        #expect(edited.emitters[1].name == "Splash" && edited.emitters[0].subEmitters[0].emitter == "Splash")
        #expect(edited.subEmitterTargets == ["Splash", "Nope", "Sparks"])
        edited.removeEmitters(named: ["Splash"])
        #expect(edited.emitters.map(\.name) == ["Sparks"] && edited.emitters[0].subEmitters.map(\.emitter) == ["Nope"])
    }

    @Test func texturedEmittersAndLinksImportPlaceAndEdit() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        let puff = try assets.createProceduralTexture(ProceduralTexture(width: 64, height: 32), at: "Textures/puff.proctex")
        let sprite = """
        {"width": 2, "height": 2, "palette": ["#ff0000", "#00ff00", "#0000ff"],
         "layers": [{"name": "L", "cels": [["00", "00"], ["11", "11"], ["22", "22"]]}],
         "frames": [{}, {}, {}], "tags": [{"name": "spin", "from": 1, "to": 2}]}
        """
        try assets.createPixelSprite(AssetJSON.decoder().decode(PixelSprite.self, from: Data(sprite.utf8)), at: "Sprites/spark.sprite")

        let created = try call(session, "vfx.new", ["preset": "sparks", "folder": "FX", "place": true])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let first = try #require((created["emitters"] as? [String])?.first)
        let edited = try call(session, "vfx.edit", [
            "asset": id.description,
            "addEmitters": [["name": "Pops", "rate": 0, "texture": "Sprites/spark.sprite", "spriteTag": "spin"],
                            ["name": "Smoke", "texture": "Textures/puff.proctex", "atlasColumns": 2, "atlasRows": 1],
                            ["name": "Odd", "texture": "Textures/none.png"]],
            "updateEmitters": [first: ["subEmitters": [["trigger": "death", "emitter": "Pops", "count": 5, "inheritVelocity": 0.3]]]],
        ])
        let warnings = edited["warnings"] as? [String] ?? []
        #expect(warnings == ["emitter 'Odd': no texture 'Textures/none.png'"], "\(warnings)")

        let prefab = try #require(assets.prefab(AssetReference(id)))
        let nodes = prefab.roots[0].children
        let pops = try #require(nodes.first { $0.name == "Pops" }?.particles)
        #expect(pops.frameCount == 2 && pops.atlasColumns == 2 && pops.atlasRows == 1)
        let popsTexture = try #require(pops.texture.flatMap { AssetReference($0.key) })
        #expect(popsTexture.asset == id, "a sprite's frames are baked into a texture of the effect")
        let baked = try #require(assets.texture(popsTexture)?.image)
        #expect(Array(baked.pixels[0..<4]) == [0, 255, 0, 255] && Array(baked.pixels[8..<12]) == [0, 0, 255, 255])
        let smoke = try #require(nodes.first { $0.name == "Smoke" }?.particles)
        #expect(smoke.texture.flatMap { AssetReference($0.key) } == AssetReference(puff, subAsset: "texture") && smoke.atlasColumns == 2)
        #expect(nodes.first { $0.name == "Odd" }?.particles?.texture == nil)
        let parentNode = try #require(nodes.first { $0.name == first })
        #expect(parentNode.particles?.subEmitters.map(\.count) == [5])

        // The placed copy's link points at its own Pops entity.
        func linkedName() -> String? {
            var result: String?
            session.world.query(ParticleEmitter.self, Name.self) { _, emitter, name in
                guard name.value == first, let link = emitter.subEmitters.first,
                      let target = session.world.resolve(link.emitter) else { return }
                result = session.world.get(Name.self, for: target)?.value
            }
            return result
        }
        #expect(linkedName() == "Pops")

        // Renaming the target keeps the link; removing it drops the link.
        _ = try call(session, "vfx.edit", ["asset": id.description, "updateEmitters": ["Pops": ["name": "Burst"]]])
        #expect(assets.vfx(of: id)?.emitters.first { $0.name == first }?.subEmitters.first?.emitter == "Burst")
        #expect(linkedName() == "Burst")
        _ = try call(session, "vfx.edit", ["asset": id.description, "removeEmitters": ["Burst"]])
        #expect(assets.vfx(of: id)?.emitters.first { $0.name == first }?.subEmitters.isEmpty == true)
        #expect(linkedName() == nil)
    }

    @Test func viewOffersTexturesSpriteTagsAndLinkTargets() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        try assets.createProceduralTexture(ProceduralTexture(width: 16, height: 16), at: "puff.proctex")
        let sprite = """
        {"width": 1, "height": 1, "palette": ["#ff0000"], "layers": [{"name": "L", "cels": [["0"], ["0"]]}],
         "frames": [{}, {}], "tags": [{"name": "a", "from": 0, "to": 1}]}
        """
        try assets.createPixelSprite(AssetJSON.decoder().decode(PixelSprite.self, from: Data(sprite.utf8)), at: "spark.sprite")
        var build = VFXBuild.preset("fire")!
        build.emitters[0].texture = "spark.sprite"
        #expect(VFXBuilderView.choices(for: "texture", emitter: build.emitters[0], build: build, assets: assets) == ["", "puff.proctex", "spark.sprite"])
        #expect(VFXBuilderView.choices(for: "spriteTag", emitter: build.emitters[0], build: build, assets: assets) == ["", "a"])
        #expect(VFXBuilderView.choices(for: "subEmitters[0].emitter", emitter: build.emitters[0], build: build, assets: assets)
                == ["", "Embers", "Smoke"])
        #expect(VFXBuilderView.choices(for: "rate", emitter: build.emitters[0], build: build, assets: assets) == nil)

        let id = try #require(session.createVFXAsset(in: "", name: "Linked", build: build))
        let view = try #require(VFXBuilderView(session: session, asset: id))
        view.refresh()
        #expect(view.emitterList.items.first?.contains("spark") == true)
    }
}
