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

        // Plays with clips from the database.
        world.propagateTransforms()
        world.addAssetAnimationSystem(assets: { database })
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
