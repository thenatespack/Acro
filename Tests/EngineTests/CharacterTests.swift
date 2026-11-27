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
@testable import EngineMeshBuild
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Character builds: templates, skeletons, skinned body meshes, procedural clips and the
// .character importer (a scene-file prefab with an Animator, clips as animation sub-assets).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CharacterTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Characters")
}

@MainActor
@Suite(.serialized) struct CharacterTests {
    @Test func everyTemplateHasAValidSkeletonAndSkinnedBody() {
        for template in CharacterTemplate.allCases {
            let rig = CharacterRig(template: template)
            #expect(!rig.bones.isEmpty && rig.bones[0].parent == nil, "\(template)")
            #expect(Set(rig.bones.map(\.name)).count == rig.bones.count, "\(template): bone names are unique")
            for (i, bone) in rig.bones.enumerated() {
                if let parent = bone.parent { #expect(parent < i, "\(template): parents come first") }
            }
            #expect(rig.bones.first { $0.name == template.handBone } != nil, "\(template)")
            let meshes = rig.bodyMeshes()
            #expect(meshes.contains { $0.region == .body } && meshes.contains { $0.region == .eyes }, "\(template)")
            for (_, mesh) in meshes {
                let skin = try! #require(mesh.skin)
                #expect(skin.count == mesh.vertices.count)
                for influence in skin {
                    #expect(abs(influence.weights.sum() - 1) < 1e-4)
                    for k in 0..<4 where influence.weights[k] > 0 { #expect(Int(influence.joints[k]) < rig.bones.count) }
                }
                #expect(mesh.indices.allSatisfy { Int($0) < mesh.vertices.count })
            }
            // Standing on the ground.
            #expect(abs(rig.bounds.center.y - rig.bounds.halfExtent.y) < 0.12, "\(template) feet near y = 0: \(rig.bounds.center.y - rig.bounds.halfExtent.y)")
        }
    }

    @Test func proportionsChangeTheSkeleton() {
        let base = CharacterRig(template: .humanoid)
        let tall = CharacterRig(template: .humanoid, proportions: CharacterProportions(height: 2))
        let leggy = CharacterRig(template: .humanoid, proportions: CharacterProportions(legs: 1.5))
        let hips = { (rig: CharacterRig) in rig.bones[rig.index(of: "hips")!].position.y }
        #expect(abs(hips(tall) - 2 * hips(base)) < 1e-4)
        #expect(hips(leggy) > hips(base) * 1.3)
        let wide = CharacterRig(template: .humanoid, proportions: CharacterProportions(width: 2))
        #expect(wide.bounds.halfExtent.x > base.bounds.halfExtent.x * 1.4)
        let clamped = CharacterRig(template: .humanoid, proportions: CharacterProportions(head: 50))
        #expect(clamped.proportions.head == CharacterProportions.range.upperBound)
        // Smoothing blends some vertices across joints.
        let rigid = base.bodyMeshes(smooth: false).flatMap { $0.geometry.skin! }
        let smooth = base.bodyMeshes(smooth: true).flatMap { $0.geometry.skin! }
        #expect(rigid.allSatisfy { $0.weights.x == 1 })
        #expect(smooth.contains { $0.weights.y > 0 })
    }

    @Test func stockClipsFitEveryTemplate() {
        for template in CharacterTemplate.allCases {
            let rig = CharacterRig(template: template, proportions: CharacterProportions(height: 1.3))
            let clips = CharacterClips.clips(rig: rig)
            #expect(clips.map(\.name) == CharacterClips.stockNames, "\(template)")
            for clip in clips {
                #expect(clip.duration == CharacterClips.duration(clip.name, template: template))
                #expect(clip.channels.allSatisfy { $0.target < rig.bones.count })
                #expect(clip.channels.contains { $0.target == 0 && $0.path == .translation }, "the root bone moves")
                #expect(clip.channels.contains { $0.path == .rotation || $0.path == .scale }, "\(template) \(clip.name) animates")
                if CharacterClips.loops(clip.name) {
                    for channel in clip.channels {
                        let n = channel.path == .rotation ? 4 : 3
                        let first = Array(channel.sampler.values.prefix(n)), last = Array(channel.sampler.values.suffix(n))
                        for (a, b) in zip(first, last) { #expect(abs(abs(a) - abs(b)) < 1e-3, "\(template) \(clip.name) loops seamlessly") }
                    }
                }
                // Sampling gives real motion away from rest.
                var pose = AnimationPose(rig.restPose)
                clip.sample(at: clip.duration * 0.37, into: &pose)
                let moved = zip(pose.transforms, rig.restPose).contains { a, b in
                    a.rotation.vector != b.rotation.vector || a.position != b.position || a.scale != b.scale
                }
                #expect(moved, "\(template) \(clip.name)")
            }
            #expect(clips.first { $0.name == "attack" }?.events.map(\.name) == ["hit"])
            #expect(clips.first { $0.name == "walk" }?.events.count == 2)
        }
        // Deterministic.
        #expect(CharacterClips.clip("run", rig: CharacterRig(template: .bird)) == CharacterClips.clip("run", rig: CharacterRig(template: .bird)))
        #expect(CharacterClips.clip("dance", rig: CharacterRig(template: .bird)) == nil)
    }

    @Test func fileRoundTripsAndSparseFilesDecode() throws {
        let empty = try AssetJSON.decoder().decode(CharacterBuild.self, from: Data("{}".utf8))
        #expect(empty == CharacterBuild())
        let sparse = try AssetJSON.decoder().decode(CharacterBuild.self, from: Data("""
            {"template": "bird", "proportions": {"legs": 2}, "colors": {"body": [1, 0, 0]},
             "attachments": [{"name": "Hat", "asset": "Models/hat.meshbuild"}]}
            """.utf8))
        #expect(sparse.template == .bird && sparse.proportions.legs == 2 && sparse.proportions.head == 1)
        #expect(sparse.color(.body) == Vec3(1, 0, 0) && sparse.color(.legs) == CharacterTemplate.bird.defaultColor(.legs))
        #expect(sparse.attachments[0].bone == "head" && sparse.attachments[0].scale == 1 && sparse.attachments[0].color == nil)
        let round = try AssetJSON.decoder().decode(CharacterBuild.self, from: sparse.fileData())
        #expect(round == sparse)
        var bad = sparse
        bad.attachments.append(CharacterAttachment(name: "Hat", bone: "tentacle", asset: "x.meshbuild"))
        bad.clips = ["idle", "dance"]
        bad.defaultClip = "walk"
        let problems = bad.problems.joined(separator: "\n")
        #expect(problems.contains("two attachments are named 'Hat'") && problems.contains("no bone 'tentacle'"))
        #expect(problems.contains("no stock clip 'dance'") && problems.contains("defaultClip 'walk'"))
    }

    @Test func importsASkinnedPrefabWithAnAnimatorThatPlays() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Grip", shape: .cylinder, size: Vec3(0.04, 0.2, 0.04)),
            MeshBuildPart(name: "Blade", parent: "Grip", position: Vec3(0, 0.5, 0), size: Vec3(0.08, 0.8, 0.02)),
        ]), at: "Models/sword.meshbuild")
        let character = CharacterBuild(template: .humanoid, colors: CharacterColors(body: Vec3(1, 0, 0)), attachments: [
            CharacterAttachment(name: "Sword", bone: "hand.R", asset: "Models/sword.meshbuild", rotation: Vec3(90, 0, 0), color: Vec3(0.7, 0.7, 0.8)),
            CharacterAttachment(name: "Ghost", bone: "head", asset: "Models/missing.meshbuild"),
        ])
        let id = try database.createCharacter(character, at: "Characters/hero.character")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importer == "character" && record.importError == nil)
        #expect(record.objects.filter { $0.kind == .animation }.map(\.id) == CharacterClips.stockNames.map { "animation/\($0)" })
        #expect(record.objects.contains { $0.id == "mesh/body body" } && record.objects.contains { $0.id == "mesh/Sword Blade" })
        #expect(database.character(of: id) == character)
        let walk = try #require(database.animationClip(AssetReference(id, subAsset: "animation/walk")))
        #expect(walk == CharacterClips.clip("walk", rig: character.rig))

        let prefab = try #require(database.prefab(AssetReference(id)))
        #expect(prefab.scene != nil && prefab.roots.isEmpty, "a scene-file prefab, for the Animator")
        let world = World()
        let root = try #require(world.instantiate(prefab).first)
        #expect(world.get(Name.self, for: root)?.value == "hero")
        let animator = try #require(world.get(Animator.self, for: root), "the Animator decodes")
        let rig = character.rig
        #expect(animator.targets.count == rig.bones.count)
        #expect(animator.targets.map { world.get(Name.self, for: $0)?.value } == rig.bones.map(\.name))
        #expect(animator.restPose == rig.restPose)
        // The prefab holds `Animator`'s own encoding of the importer's value (no hand-written copy).
        var clipKeys: [String: String] = [:]
        for name in CharacterClips.stockNames { clipKeys[name] = AssetReference(id, subAsset: "animation/\(name)").description }
        var expected = CharacterImporter.animator(build: character, rig: rig, clipKeys: clipKeys)
        expected.targets = animator.targets
        #expect(animator == expected)
        #expect(animator.stateMachine.states.map(\.name) == CharacterClips.stockNames + ["locomotion"])
        #expect(animator.stateMachine.initialState == "idle")
        #expect(animator.stateMachine.transitions.contains { $0.to == "jump" && $0.conditions == [.triggered("jump")] })
        #expect(animator.stateMachine.transitions.contains { $0.from == "attack" && $0.to == "locomotion" && $0.exitTime == 1 })
        if case .blend1D(let parameter, let entries)? = animator.stateMachine.states.last?.motion {
            #expect(parameter == "speed" && entries.count == 3 && entries[0].clip.key == AssetReference(id, subAsset: "animation/idle").description)
        } else {
            Issue.record("locomotion is a blend space")
        }
        // Body meshes are skinned to the bone entities.
        var skins = 0
        world.query(Skin.self) { entity, skin in
            skins += 1
            #expect(skin.joints == animator.targets)
            #expect(skin.inverseBindMatrices == rig.inverseBindMatrices)
            #expect(world.get(MeshRenderer.self, for: entity) != nil)
        }
        #expect(skins == rig.bodyMeshes().count)
        // The sword hangs from the right hand, recolored.
        let hand = animator.targets[rig.index(of: "hand.R")!]
        let sword = try #require(world.children(of: hand).first { world.get(Name.self, for: $0)?.value == "Sword" })
        #expect(world.children(of: sword).count == 2)
        #expect(record.objects.contains { $0.id == "material/Sword Blade" })
        if case .material(let m)? = database.object(AssetReference(id, subAsset: "material/Sword Blade"), kind: .material)?.value {
            #expect(abs(m.baseColor.x - MeshBuildColor.linear(fromSRGB: Vec3(0.7, 0.7, 0.8)).x) < 1e-5)
        }

        // Plays with clips from the database, through the play-mode system (SceneAnimation.swift).
        world.propagateTransforms()
        _ = world.addSceneAnimationSystem(assets: { database })
        let hipsRest = world.get(Transform.self, for: animator.targets[0])!.position
        world.modify(Animator.self, for: root) { $0.play("walk", fade: 0) }
        for _ in 0..<10 { world.update(dt: 1.0 / 30) }
        let hipsNow = world.get(Transform.self, for: animator.targets[0])!.position
        let legNow = world.get(Transform.self, for: animator.targets[rig.index(of: "upperLeg.L")!])!.rotation
        #expect(hipsNow != hipsRest && legNow.vector != Quat.identity.vector, "the walk moves the bones")
        #expect(world.get(Animator.self, for: root)?.currentState == "walk")

        // Hot reload: a new template reimports and the prefab follows.
        var bird = character
        bird.template = .bird
        bird.attachments = []
        let warnings = try database.writeCharacter(bird, to: id)
        #expect(warnings.isEmpty, "\(warnings)")
        let reloaded = try #require(database.prefab(AssetReference(id)))
        let birdWorld = World()
        let birdRoot = try #require(birdWorld.instantiate(reloaded).first)
        #expect(birdWorld.get(Animator.self, for: birdRoot)?.targets.count == CharacterRig(template: .bird).bones.count)
    }

    @Test func externalClipEntriesRoundTripAndAreValidated() throws {
        let file = try AssetJSON.decoder().decode(CharacterBuild.self, from: Data("""
            {"clips": ["idle", "asset:0123456789abcdef0123456789abcdef#animation/Wave",
                       {"name": "walk", "clip": "asset:0123456789abcdef0123456789abcdef#animation/Walk", "boneMap": {"Hips": "hips"}}]}
            """.utf8))
        #expect(file.clips == ["idle"])
        #expect(file.externalClips.map(\.name) == ["Wave", "walk"] && file.externalClips[1].boneMap == ["Hips": "hips"])
        #expect(file.clipNames == ["idle", "walk", "Wave"], "a same-named external clip takes the stock clip's place")
        #expect(file.stockClipNames == ["idle"] && file.loops("walk") && file.loops("Wave"))
        #expect(try AssetJSON.decoder().decode(CharacterBuild.self, from: file.fileData()) == file)
        var bad = file
        bad.externalClips += [CharacterExternalClip(name: "Wave", clip: "Models/wave.gltf"),
                              CharacterExternalClip(name: "x", clip: "asset:0123456789abcdef0123456789abcdef#animation/X", boneMap: ["A": "tentacle"])]
        let problems = bad.problems.joined(separator: "\n")
        #expect(problems.contains("two clips are named 'Wave'") && problems.contains("isn't an animation reference"))
        #expect(problems.contains("boneMap 'A' → no bone 'tentacle'"))
    }

    @Test func externalClipsFromGLTFAndCharactersPlayByBoneName() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.url(forAssetPath: "Models/rig.gltf")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try animationClipImportGLTF().write(to: url)
        let database = AssetDatabase(project: project)
        database.refresh()
        let gltf = try #require(database.id(forPath: "Models/rig.gltf"))
        let other = try database.createCharacter(CharacterBuild(), at: "other.character")
        let bend = AssetReference(gltf, subAsset: "animation/Bend").description
        // glTF nodes Root (rotation) and Tip (translation, scale) mapped onto bones; a stock jump
        // from another humanoid replaces this one's; a clip with no matching node is dropped.
        let character = CharacterBuild(clips: ["idle", "walk"], externalClips: [
            CharacterExternalClip(name: "bend", clip: bend, boneMap: ["Root": "head", "Tip": "hand.R"], loops: false),
            CharacterExternalClip(name: "jump", clip: AssetReference(other, subAsset: "animation/jump").description),
            CharacterExternalClip(name: "lost", clip: bend),
        ])
        let id = try database.createCharacter(CharacterBuild(), at: "hero.character")
        let warnings = try database.writeCharacter(character, to: id).joined(separator: "\n")
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        #expect(record.objects.filter { $0.kind == .animation }.map(\.id) == ["animation/idle", "animation/walk", "animation/bend", "animation/jump"])
        #expect(warnings.contains("clip 'lost': none of the animated nodes"), "\(warnings)")

        let rig = character.rig
        let clip = try #require(database.animationClip(AssetReference(id, subAsset: "animation/bend")))
        let head = rig.index(of: "head")!, hand = rig.index(of: "hand.R")!
        // Retargeted (AnimationRetarget.swift): the mapped bones are driven, and a glTF source keeps no translation.
        #expect(Set(clip.channels.map(\.target)).isSuperset(of: [head, hand]), "\(clip.channels.map { ($0.target, $0.path) })")
        #expect(clip.channels.contains { $0.target == head && $0.path == .rotation })
        #expect(!clip.channels.contains { $0.path == .translation })
        let jump = try #require(database.animationClip(AssetReference(id, subAsset: "animation/jump")))
        #expect(jump.channels.count == CharacterClips.clip("jump", rig: CharacterBuild().rig)!.channels.count)
        #expect(jump.channels.contains { $0.path == .translation }, "the same skeleton keeps its root moves")
        #expect(jump.events.map(\.name) == ["takeoff", "land"])

        // The Animator has them as states, and the glTF rotation plays on the head.
        let world = World()
        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(world.instantiate(prefab).first)
        let animator = try #require(world.get(Animator.self, for: root))
        #expect(animator.stateMachine.states.map(\.name) == ["idle", "walk", "jump", "bend", "locomotion"])
        #expect(animator.stateMachine.states.first { $0.name == "bend" }?.loops == false)
        #expect(animator.stateMachine.transitions.contains { $0.to == "jump" })
        world.propagateTransforms()
        _ = world.addSceneAnimationSystem(assets: { database })
        world.modify(Animator.self, for: root) { $0.play("bend", fade: 0) }
        for _ in 0..<40 { world.update(dt: 1.0 / 30) }
        let headRotation = try #require(world.get(Transform.self, for: animator.targets[head])).rotation
        let expected = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))
        #expect(abs(abs(headRotation.vector.y) - abs(expected.vector.y)) < 1e-3 && abs(abs(headRotation.vector.w) - abs(expected.vector.w)) < 1e-3)
    }

    @Test func partColorsRecolorSinglePartsOfAnAttachment() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Grip", shape: .cylinder, size: Vec3(0.04, 0.2, 0.04)),
            MeshBuildPart(name: "Blade", parent: "Grip", position: Vec3(0, 0.5, 0), size: Vec3(0.08, 0.8, 0.02)),
        ]), at: "sword.meshbuild")
        let sword = CharacterAttachment(name: "Sword", bone: "hand.R", asset: "sword.meshbuild", color: Vec3(0, 0, 1),
                                        partColors: ["Blade": Vec3(1, 0, 0), "Hilt": Vec3(0, 1, 0)])
        let round = try AssetJSON.decoder().decode(CharacterAttachment.self, from: AssetJSON.encode(sword))
        #expect(round == sword)
        #expect(!String(decoding: try AssetJSON.encode(CharacterAttachment()), as: UTF8.self).contains("partColors"))
        let id = try database.createCharacter(CharacterBuild(), at: "hero.character")
        let warnings = try database.writeCharacter(CharacterBuild(attachments: [sword]), to: id)
        #expect(warnings.contains { $0.contains("partColors names no part 'Hilt'") }, "\(warnings)")
        func baseColor(_ part: String) -> Vec4? {
            guard case .material(let m)? = database.object(AssetReference(id, subAsset: "material/Sword \(part)"), kind: .material)?.value else { return nil }
            return m.baseColor
        }
        let red = MeshBuildColor.linear(fromSRGB: Vec3(1, 0, 0)), blue = MeshBuildColor.linear(fromSRGB: Vec3(0, 0, 1))
        #expect(baseColor("Blade").map { abs($0.x - red.x) < 1e-5 && $0.z < 1e-5 } == true)
        #expect(baseColor("Grip").map { abs($0.z - blue.z) < 1e-5 && $0.x < 1e-5 } == true)
    }

    /// Built games: a placed character is cooked with its clips and plays from the mounted pack
    /// through `ScenePlayback` (the exported player's path), with the project gone.
    @Test func cookedCharacterPlaysFromAPackWithoutTheProject() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createCharacter(CharacterBuild(defaultClip: "walk"), at: "Characters/hero.character")
        let prefab = try #require(database.prefab(AssetReference(id)))
        let world = World()
        _ = try world.instantiatePrefab(try prefab.template(prefabs: { database.prefab($0) }), reference: AssetReference(id))
        let sceneURL = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: sceneURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try world.save().write(to: sceneURL)

        let output = FileManager.default.temporaryDirectory.appendingPathComponent("CharacterTests-pack-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: output) }
        let report = try AssetCooker.cook(projectAt: project.root, options: CookOptions(scenes: ["Scenes/Main.scene"]), to: output)
        try FileManager.default.removeItem(at: project.root)
        let pack = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        let assets = AssetDatabase(mounting: pack)
        #expect(assets.animationClip(AssetReference(id, subAsset: "animation/walk")) != nil)

        let playback = ScenePlayback(module: GameModule(), context: GameContext(input: Input()), assets: { assets }, log: { _ in }) { path in
            try pack.scene(path)
        }
        try playback.load("Scenes/Main.scene")
        var root: Entity?
        playback.world.query(Animator.self) { entity, _ in root = entity }
        let animator = try #require(root.flatMap { playback.world.get(Animator.self, for: $0) })
        let leg = animator.targets[CharacterRig(template: .humanoid).index(of: "upperLeg.L")!]
        let rest = try #require(playback.world.get(Transform.self, for: leg)).rotation
        for _ in 0..<10 { playback.world.update(dt: 1.0 / 30) }
        #expect(playback.world.get(Animator.self, for: root!)?.currentState == "walk")
        #expect(playback.world.get(Transform.self, for: leg)?.rotation.vector != rest.vector, "the walk plays from the pack")
    }

    /// GameRunner: a scene file inside a project plays its characters with the project's assets
    /// (`ScenePlayback.projectAssets(containing:)`), from a fresh database as a new process would.
    @Test func sceneFileInAProjectPlaysCharactersWithTheProjectsAssets() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createCharacter(CharacterBuild(defaultClip: "run"), at: "hero.character")
        let prefab = try #require(database.prefab(AssetReference(id)))
        let world = World()
        _ = try world.instantiatePrefab(try prefab.template(prefabs: { database.prefab($0) }), reference: AssetReference(id))
        let sceneURL = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: sceneURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try world.save().write(to: sceneURL)

        #expect(ScenePlayback.projectAssets(containing: FileManager.default.temporaryDirectory.appendingPathComponent("loose.scene")) == nil)
        let assets = try #require(ScenePlayback.projectAssets(containing: sceneURL))
        #expect(assets.project.root.standardizedFileURL == project.root.standardizedFileURL)
        let playback = ScenePlayback(module: GameModule(), context: GameContext(input: Input()), assets: { assets }, log: { _ in }) { path in
            try Data(contentsOf: URL(fileURLWithPath: path))
        }
        try playback.load(sceneURL.path)
        var root: Entity?
        playback.world.query(Animator.self) { entity, _ in root = entity }
        let animator = try #require(root.flatMap { playback.world.get(Animator.self, for: $0) })
        let leg = animator.targets[CharacterRig(template: .humanoid).index(of: "upperLeg.L")!]
        let rest = try #require(playback.world.get(Transform.self, for: leg)).rotation
        for _ in 0..<10 { playback.world.update(dt: 1.0 / 30) }
        #expect(playback.world.get(Animator.self, for: root!)?.currentState == "run")
        #expect(playback.world.get(Transform.self, for: leg)?.rotation.vector != rest.vector)
    }

    @Test func importWarnsAboutMissingAssetsAndClips() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var character = CharacterBuild(template: .blob, attachments: [CharacterAttachment(name: "Hat", bone: "nope", asset: "Models/hat.meshbuild")])
        character.clips = ["idle", "attack"]
        let id = try database.createCharacter(character, at: "blob.character")
        _ = database.reimport(id)
        let record = try #require(database.record(id))
        #expect(record.objects.filter { $0.kind == .animation }.count == 2)
        let prefab = try #require(database.prefab(AssetReference(id)))
        let world = World()
        let root = try #require(world.instantiate(prefab).first)
        let animator = try #require(world.get(Animator.self, for: root))
        #expect(animator.stateMachine.states.map(\.name) == ["idle", "attack"], "no locomotion without walk or run")
        #expect(animator.stateMachine.transitions.contains { $0.from == "attack" && $0.to == "idle" })
        // The attachment on a missing bone goes on the root bone.
        let rootBone = animator.targets[0]
        #expect(world.children(of: rootBone).contains { world.get(Name.self, for: $0)?.value == "Hat" })
    }

    @Test func realisticHumanoidIsOneSkinnedBodyWithFaceEyesAndClothes() throws {
        let rig = CharacterRig(template: .humanoid)
        #expect(rig.isRealisticHuman)
        let parts = rig.bodyParts()
        let names = Set(parts.map(\.name))
        for name in ["skin", "lips", "body", "legs", "accent", "shoe.sole", "eyes"] { #expect(names.contains(name), "\(name)") }
        let triangles = parts.reduce(0) { $0 + $1.geometry.indices.count / 3 }
        #expect(triangles > 50_000 && triangles < 300_000, "\(triangles) triangles")
        for part in parts {
            let skin = try #require(part.geometry.skin)
            #expect(skin.count == part.geometry.vertices.count)
            for influence in skin {
                #expect(abs(influence.weights.sum() - 1) < 1e-3)
                for k in 0..<4 where influence.weights[k] > 0 { #expect(Int(influence.joints[k]) < rig.bones.count) }
            }
        }
        // Skin shows at the head and the hands; the hands follow their bones, the face the head.
        let skin = try #require(parts.first { $0.name == "skin" })
        let ys = skin.geometry.vertices.map(\.position.y)
        #expect((ys.min() ?? 1) < 0.75 && (ys.max() ?? 0) > 1.72)
        let head = UInt16(rig.index(of: "head")!), handL = UInt16(rig.index(of: "hand.L")!)
        for (v, influence) in zip(skin.geometry.vertices, skin.geometry.skin!) {
            if v.position.y > 1.62 { #expect(influence.joints[0] == head) }
            if v.position.y < 0.78 && v.position.x > 0.1 { #expect(influence.joints[0] == handL) }
        }
        // Elbows blend two bones.
        let lower = UInt16(rig.index(of: "lowerArm.L")!), upper = UInt16(rig.index(of: "upperArm.L")!)
        #expect(skin.geometry.skin!.contains { i in
            (0..<4).contains { i.joints[$0] == lower && i.weights[$0] > 0.2 } && (0..<4).contains { i.joints[$0] == upper && i.weights[$0] > 0.2 }
        })
        // Hair has a scalp above the eyes; skin and eyes get the shading presets.
        let scalp = try #require(rig.humanScalp)
        #expect(scalp.indices.count > 3000 && scalp.vertices.allSatisfy { $0.position.y > 0.02 })
        #expect(skin.look.material(region: Vec3(0.8, 0.6, 0.5)).subsurface != nil)
        #expect(parts.first { $0.name == "eyes" }?.look.material(region: Vec3(0.3, 0.2, 0.1)).eye != nil)
        // The toy style keeps a shape per bone; the file key round-trips.
        let toy = CharacterRig(template: .humanoid, style: .toy)
        #expect(toy.bodyParts().map(\.name) == ["skin", "body", "legs", "accent", "eyes"])
        var build = CharacterBuild()
        build.style = .toy
        let decoded = try AssetJSON.decoder().decode(CharacterBuild.self, from: build.fileData())
        #expect(decoded.style == .toy && decoded.rig == toy)
        #expect(try AssetJSON.decoder().decode(CharacterBuild.self, from: Data("{}".utf8)).style == .realistic)
    }

    @Test func prefabTemplatesKeepStableIDs() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createCharacter(CharacterBuild(), at: "a.character")
        let first = try #require(database.prefab(AssetReference(id)))
        try database.writeCharacter(CharacterBuild(proportions: CharacterProportions(legs: 1.4)), to: id)
        let second = try #require(database.prefab(AssetReference(id)))
        #expect(first != second)
        let a = try first.template(prefabs: { database.prefab($0) })
        let b = try second.template(prefabs: { database.prefab($0) })
        #expect(Set(a.order.compactMap { a.localID(of: $0) }) == Set(b.order.compactMap { b.localID(of: $0) }),
                "the same bones keep their prefab-local ids")
    }
}
