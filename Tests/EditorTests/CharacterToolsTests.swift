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

// The character builder as an agent uses it (character.* tools, JSON in and out), including undo,
// and the Character Builder tab's form.

@MainActor private func makeSession() -> EditorSession {
    EditorComponentCatalog.registerBuiltins()
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CharacterToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite(.serialized) struct CharacterToolsTests {
    @Test func newEditAttachAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "meshBuild.new", ["name": "Sword", "folder": "Models",
                                            "build": ["parts": [["name": "Blade", "shape": "box", "size": [0.06, 0.8, 0.02]]]]])

        let bones = try call(session, "character.bones", ["template": "quadruped"])
        #expect((bones["bones"] as? [[String: Any]])?.contains { $0["name"] as? String == "tailTip" } == true)
        #expect(bones["handBone"] as? String == "head")

        let created = try call(session, "character.new", ["name": "Hero", "folder": "Characters", "proportions": ["head": 1.3],
                                                          "colors": ["body": [0.8, 0.1, 0.1]], "place": true])
        #expect(created["path"] as? String == "Characters/Hero.character")
        #expect(created["template"] as? String == "humanoid")
        #expect((created["clips"] as? [String]) == CharacterClips.stockNames)
        #expect((created["parameters"] as? [String]) == ["speed", "jump", "attack", "die"])
        #expect((created["entities"] as? [String])?.count == 1)
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isCharacterFile(id))
        #expect(session.world.count(of: Animator.self) == 1 && session.world.count(of: Skin.self) >= 4)
        let original = try #require(session.assets?.character(of: id))
        #expect(original.proportions.head == 1.3 && original.colors.body == Vec3(0.8, 0.1, 0.1))

        let edited = try call(session, "character.edit", [
            "path": "Characters/Hero.character", "proportions": ["legs": 1.2], "colors": ["legs": [0, 0, 1]], "resetColors": ["body"],
            "attach": [["name": "Sword", "bone": "hand.R", "asset": "Models/Sword.meshbuild", "rotation": [90, 0, 0]]],
        ])
        #expect((edited["attachments"] as? [String]) == ["Sword"])
        #expect((edited["warnings"] as? [String])?.isEmpty == true, "\(edited["warnings"] ?? "")")
        let after = try #require(session.assets?.character(of: id))
        #expect(after.proportions.legs == 1.2 && after.proportions.head == 1.3 && after.colors.body == nil && after.colors.legs == Vec3(0, 0, 1))
        #expect(session.assets?.record(id)?.objects.contains { $0.id == "mesh/Sword Blade" } == true)

        try call(session, "character.edit", ["path": "Characters/Hero.character",
                                             "updateAttachments": ["Sword": ["bone": "hand.L", "name": "Blade"]]])
        #expect(session.assets?.character(of: id)?.attachments.map(\.name) == ["Blade"])
        #expect(session.assets?.character(of: id)?.attachments.first?.bone == "hand.L")

        let got = try call(session, "character.get", ["path": "Characters/Hero.character"])
        #expect((got["bones"] as? [[String: Any]])?.count == CharacterRig(template: .humanoid).bones.count)
        let clips = try #require(got["clips"] as? [[String: Any]])
        #expect(clips.first { $0["name"] as? String == "attack" }?["events"] as? [String] == ["hit"])
        #expect((clips.first?["clip"] as? String) == AssetReference(id, subAsset: "animation/idle").description)
        #expect(((got["colors"] as? [String: Any])?["eyes"] as? [Double])?.count == 3)

        // Errors.
        #expect(throws: (any Error).self) { try call(session, "character.edit", ["path": "Characters/Hero.character", "proportions": ["wings": 2]]) }
        #expect(throws: (any Error).self) { try call(session, "character.edit", ["path": "Characters/Hero.character", "proportions": ["head": 9]]) }
        #expect(throws: (any Error).self) { try call(session, "character.edit", ["path": "Characters/Hero.character", "colors": ["hair": [1, 0, 0]]]) }
        #expect(throws: (any Error).self) { try call(session, "character.edit", ["path": "Characters/Hero.character", "detach": ["Nope"]]) }
        #expect(throws: (any Error).self) { try call(session, "character.edit", ["path": "Characters/Hero.character", "clips": ["dance"]]) }
        #expect(throws: (any Error).self) { try call(session, "character.open", ["path": "Characters/Hero.character", "clip": "dance"]) }

        // Each edit is one undo step.
        #expect(session.performUndo())
        #expect(session.assets?.character(of: id)?.attachments.map(\.name) == ["Sword"])
        #expect(session.performUndo())
        #expect(session.assets?.character(of: id) == original)

        // A template swap moves gear on missing bones to the root bone, with a warning.
        try call(session, "character.edit", ["path": "Characters/Hero.character",
                                             "attach": [["name": "Hat", "bone": "head", "asset": "Models/Sword.meshbuild"],
                                                        ["name": "Glove", "bone": "hand.L", "asset": "Models/Sword.meshbuild"]]])
        let blob = try call(session, "character.edit", ["path": "Characters/Hero.character", "template": "blob"])
        #expect((blob["warnings"] as? [String])?.contains { $0.contains("no bone 'head'") } == true)
        #expect((blob["bones"] as? [String])?.first == "root")

        let opened = try call(session, "character.open", ["path": "Characters/Hero.character", "clip": "walk"])
        #expect(opened["path"] as? String == "Characters/Hero.character")
        #expect(session.openCharacter == id && session.characterPreviewClip == "walk")
    }

    @Test func setReplacesAndPlayModeAnimates() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "character.new", ["template": "bird", "place": true])
        #expect(created["path"] as? String == "Bird.character")
        let set = try call(session, "character.set", ["path": "Bird.character", "character": ["template": "quadruped", "clips": ["idle", "walk"]]])
        #expect(set["template"] as? String == "quadruped" && (set["clips"] as? [String]) == ["idle", "walk"])
        #expect((set["parameters"] as? [String]) == ["speed"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.assets?.character(of: id)?.proportions == CharacterProportions())

        // The placed copy followed the edit, and plays in play mode.
        _ = session.prefabs.sync(session.world, database: try #require(session.assets))
        var root: Entity?
        session.world.query(Animator.self) { entity, animator in
            #expect(animator.targets.count == CharacterRig(template: .quadruped).bones.count)
            root = entity
        }
        let character = try #require(root)
        session.world.modify(Animator.self, for: character) { $0.setFloat("speed", 1.2); $0.play("locomotion", fade: 0) }
        let leg = try #require(session.world.get(Animator.self, for: character)?.targets[CharacterRig(template: .quadruped).index(of: "frontUpper.L")!])
        let rest = try #require(session.world.get(Transform.self, for: leg)).rotation
        session.world.addSceneAnimationSystem(assets: { [weak session] in session?.assets }, name: "CharacterToolsTests.animation")
        for _ in 0..<8 { session.world.update(dt: 1.0 / 30) }
        #expect(session.world.get(Transform.self, for: leg)?.rotation.vector != rest.vector)
        session.world.removeSystem(named: "CharacterToolsTests.animation")
    }

    @Test func partColorsThroughUpdateAttachments() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "meshBuild.new", ["name": "Sword", "folder": "Models",
                                            "build": ["parts": [["name": "Blade", "shape": "box", "size": [0.06, 0.8, 0.02]],
                                                                ["name": "Grip", "shape": "box", "size": [0.04, 0.2, 0.04]]]]])
        let hero = try call(session, "character.new", ["name": "Hero", "attachments": [["name": "Sword", "bone": "hand.R", "asset": "Models/Sword.meshbuild"]]])
        let id = try #require((hero["asset"] as? String).flatMap { AssetID($0) })
        let edited = try call(session, "character.edit", ["path": "Hero.character",
                                                          "updateAttachments": ["Sword": ["partColors": ["Blade": [1, 0, 0], "Pommel": [0, 1, 0]]]]])
        #expect(session.assets?.character(of: id)?.attachments.first?.partColors["Blade"] == Vec3(1, 0, 0))
        #expect((edited["warnings"] as? [String])?.contains { $0.contains("partColors names no part 'Pommel'") } == true)
        try call(session, "edit.undo")
        #expect(session.assets?.character(of: id)?.attachments.first?.partColors.isEmpty == true)
    }

    @Test func addClipsFromOtherAssets() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let source = try call(session, "character.new", ["name": "Source"])
        let hero = try call(session, "character.new", ["name": "Hero"])
        let sourceID = try #require(source["asset"] as? String)
        let wave = "asset:\(sourceID)#animation/attack"
        #expect(throws: CommandError.self) {
            try call(session, "character.edit", ["path": "Hero.character", "addClips": [["name": "wave", "clip": wave, "boneMap": ["A": "tentacle"]]]])
        }
        #expect(throws: CommandError.self) { try call(session, "character.edit", ["path": "Hero.character", "addClips": [["name": "wave", "clip": "wave.gltf"]]]) }
        let edited = try call(session, "character.edit", ["path": "Hero.character", "addClips": [["name": "wave", "clip": wave, "loops": true]],
                                                          "defaultClip": "wave"])
        #expect((edited["clips"] as? [String])?.last == "wave")
        #expect((edited["warnings"] as? [String]) == [], "\(edited["warnings"] ?? "")")
        let got = try call(session, "character.get", ["path": "Hero.character"])
        let info = try #require((got["clips"] as? [[String: Any]])?.first { $0["name"] as? String == "wave" })
        #expect(info["source"] as? String == wave && info["loops"] as? Bool == true && (info["duration"] as? Double ?? 0) > 0)
        #expect(info["events"] as? [String] == ["hit"])
        let id = try #require((hero["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.assets?.character(of: id)?.defaultClip == "wave")
        // Missing sources are reported without importing.
        let missing = try call(session, "character.edit", ["path": "Hero.character", "addClips": [["name": "gone", "clip": "asset:0123456789abcdef0123456789abcdef#animation/x"]]])
        #expect((missing["warnings"] as? [String])?.contains { $0.contains("clip 'gone': no asset") } == true)
        let removed = try call(session, "character.edit", ["path": "Hero.character", "removeClips": ["gone"]])
        #expect((removed["clips"] as? [String])?.contains("gone") == false)
    }

    @Test func editModeAnimationShowsAPoseWithoutChangingTheScene() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "character.new", ["template": "humanoid", "place": true])
        try call(session, "character.edit", ["path": "Humanoid.character", "defaultClip": "walk"])
        _ = session.prefabs.sync(session.world, database: try #require(session.assets))
        var root: Entity?
        session.world.query(Animator.self) { entity, _ in root = entity }
        let character = try #require(root)
        let animatorBefore = try #require(session.world.get(Animator.self, for: character))
        let leg = animatorBefore.targets[CharacterRig(template: .humanoid).index(of: "upperLeg.L")!]
        let authored = try #require(session.world.get(Transform.self, for: leg))
        let dirty = session.document.isDirty, undoDepth = session.undo.undoDepth

        let on = try call(session, "view.animateInEditMode", ["on": true])
        #expect(on["on"] as? Bool == true && on["animators"] as? Int == 1)
        for _ in 0..<8 { session.tick(dt: 1.0 / 30) }
        var posed: Transform?, posedGlobal: Mat4?
        session.editAnimation.posing(session.world) {
            posed = session.world.get(Transform.self, for: leg)
            posedGlobal = session.world.get(GlobalTransform.self, for: leg)?.matrix
        }
        #expect(posed?.rotation.vector != authored.rotation.vector, "the walk shows while rendering")
        #expect(posedGlobal != nil)
        // Outside rendering the scene is as authored: transforms, the Animator, undo and dirty state.
        #expect(session.world.get(Transform.self, for: leg) == authored)
        #expect(session.world.get(Animator.self, for: character) == animatorBefore)
        #expect(session.document.isDirty == dirty && session.undo.undoDepth == undoDepth)
        #expect(session.world.get(GlobalTransform.self, for: leg)?.matrix != posedGlobal)

        // Play mode doesn't use it; turning it off stops it.
        let off = try call(session, "view.animateInEditMode", [:])
        #expect(off["on"] as? Bool == false && session.editAnimation.count == 0)
        session.editAnimation.posing(session.world) { #expect(session.world.get(Transform.self, for: leg) == authored) }
    }

    @Test func builderFormEditsAreOneUndoStepEach() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        try call(session, "meshBuild.new", ["name": "Hat", "build": ["parts": [["name": "Brim", "shape": "cylinder"]]]])
        let id = try #require(session.createCharacterAsset(in: "", name: "C", character: CharacterBuild()))
        let workspace = CharacterBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.root != nil && workspace.clip == "idle")
        workspace.play("run")
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.root.flatMap { workspace.world.get(Animator.self, for: $0)?.currentState } == "run")
        let view = try #require(workspace.builder)
        #expect(view.meshBuildPaths() == ["Hat.meshbuild"])

        view.attach("Hat.meshbuild", bone: "head")
        #expect(view.hasPendingEdit)
        view.refresh()
        #expect(view.character.attachments.map(\.name) == ["Hat"] && view.selectedAttachment == "Hat")
        var edited = view.character
        edited.proportions.height = 1.5
        view.apply(edited, label: "Edit Proportions")
        view.refresh()
        #expect(session.assets?.character(of: id)?.proportions.height == 1.5)
        view.detach("Hat")
        view.refresh()
        #expect(view.character.attachments.isEmpty)

        // The workspace rebuilds after each write and keeps playing the chosen clip.
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.root.flatMap { workspace.world.get(Animator.self, for: $0)?.currentState } == "run")

        #expect(session.performUndo())  // detach
        view.reload()
        #expect(view.character.attachments.map(\.name) == ["Hat"])
        #expect(session.performUndo())  // height
        #expect(session.performUndo())  // attach
        view.reload()
        #expect(view.character == CharacterBuild())
    }

    /// The file's colors are sRGB; the grid's swatches show linear fields as sRGB, so the proxies convert.
    @Test func formColorProxiesShowTheFilesSRGBColors() {
        let srgb = Vec3(0.5, 0.35, 0.2)
        var character = CharacterBuild()
        character.colors[.body] = srgb
        let proxy = CharacterColorsComponent(character)
        let shown = UIColor(linearRGB: proxy[.body])
        #expect(abs(shown.r - 0.5) < 1e-3 && abs(shown.g - 0.35) < 1e-3 && abs(shown.b - 0.2) < 1e-3)
        let attachment = CharacterAttachment(name: "Sword", color: srgb, partColors: ["Blade": Vec3(1, 0, 0)])
        var form = CharacterAttachmentComponent(attachment)
        form.scale = 2
        #expect(form.attachment(keeping: attachment).color == srgb, "an untouched color keeps its exact value")
        #expect(form.attachment(keeping: attachment).partColors == attachment.partColors)
        form.color = UIColor(0.25, 0.5, 0.75).linearRGB
        let picked = form.attachment(keeping: attachment).color ?? .zero
        #expect(abs(picked.x - 0.25) < 1e-3 && abs(picked.y - 0.5) < 1e-3 && abs(picked.z - 0.75) < 1e-3)
    }
}
