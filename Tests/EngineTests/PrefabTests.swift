import Foundation
import Testing
@testable import Engine

// Prefabs: templates and their prefab-local ids, linked instances, overrides, rebuilding after
// the prefab changed, apply / revert, nested prefabs, `.prefab` files in a project with hot
// reload, and skinned models through the asset database's cache.

private struct Health: Component, Equatable {
    static let componentName = "Test.PrefabHealth"
    var value: Float = 100
    var regen: Float = 1
}

private struct Aim: Component, Equatable {
    static let componentName = "Test.PrefabAim"
    var target = EntityRef()
    var handle = Entity.invalid
}

private func temporaryFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("PrefabTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor
@Suite struct PrefabTests {
    init() { ComponentRegistry.register(Health.self, Aim.self) }

    /// A "Turret" root with a "Gun" child (aiming at a "Muzzle" grandchild) and a "Base" child.
    private func turretData() throws -> Data {
        let world = World()
        world.assignsEntityIDs = true
        let root = world.spawn(Transform(position: Vec3(5, 0, 0)), Name("Turret"), Health())
        let gun = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("Gun"))
        let muzzle = world.spawn(Transform(position: Vec3(0, 0, 1)), Name("Muzzle"))
        let base = world.spawn(Transform(), Name("Base"), MeshRenderer(mesh: .cube))
        world.setParent(gun, to: root)
        world.setParent(muzzle, to: gun)
        world.setParent(base, to: root)
        world.add(Aim(target: world.ref(to: muzzle), handle: muzzle), to: gun)
        return try world.prefabData(from: root, rootTransform: Transform()).data
    }

    private func child(_ world: World, _ entity: Entity, _ name: String) -> Entity? {
        world.children(of: entity).first { world.get(Name.self, for: $0)?.value == name }
    }

    @Test func nodeTreeTemplatesHaveStableIDs() throws {
        let prefab = PrefabAsset(roots: [PrefabNode(name: "Fox", children: [
            PrefabNode(name: "Leg"), PrefabNode(name: "Leg"), PrefabNode(name: "Tail"),
        ])])
        let a = try prefab.template(prefabs: { _ in nil })
        let b = try prefab.template(prefabs: { _ in nil })
        #expect(a.data == b.data)
        #expect(a.order.count == 4)
        #expect(Set(a.order.compactMap(a.localID)).count == 4)
        #expect(a.localID(of: a.root) == World.stableID("Fox").description)
        // Adding a node keeps the others' ids.
        var bigger = prefab
        bigger.roots[0].children.insert(PrefabNode(name: "Ear"), at: 0)
        let c = try bigger.template(prefabs: { _ in nil })
        #expect(Set(a.order.compactMap(a.localID)).isSubset(of: Set(c.order.compactMap(c.localID))))
        #expect(throws: PrefabError.notOneRoot(2)) { try PrefabAsset(roots: [PrefabNode(name: "A"), PrefabNode(name: "B")]).template(prefabs: { _ in nil }) }
    }

    @Test func instancesAreLinkedCopiesWithRemappedReferences() throws {
        let template = try PrefabAsset(scene: turretData()).template(prefabs: { _ in nil })
        let reference = AssetReference(AssetID(high: 7, low: 7), subAsset: "prefab")
        let world = World()
        world.assignsEntityIDs = true
        let one = try world.instantiatePrefab(template, reference: reference)
        let two = try world.instantiatePrefab(template, reference: reference)
        #expect(world.entityCount == 8)
        for root in [one, two] {
            let link = try #require(world.get(PrefabInstance.self, for: root))
            #expect(link.prefab == reference && link.entities.count == 4 && link.overrides.isEmpty)
            let gun = try #require(child(world, root, "Gun"))
            let muzzle = try #require(child(world, gun, "Muzzle"))
            let aim = try #require(world.get(Aim.self, for: gun))
            #expect(world.resolve(aim.target) == muzzle)
            #expect(aim.handle == muzzle)
            #expect(world.prefabLink(of: muzzle)?.root == root)
            #expect(world.prefabOverrides(of: root, template: template).isEmpty)
        }
        #expect(world.independentPrefabInstances() == [one, two])
    }

    @Test func rebuildingKeepsOverridesAndIDs() throws {
        let template = try PrefabAsset(scene: turretData()).template(prefabs: { _ in nil })
        let reference = AssetReference(AssetID(high: 7, low: 7))
        let world = World()
        world.assignsEntityIDs = true
        let other = world.spawn(Name("Other"))
        var root = try world.instantiatePrefab(template, reference: reference)
        let plain = try world.instantiatePrefab(template, reference: reference)
        world.modify(Transform.self, for: root) { $0.position = Vec3(9, 9, 9) }      // the root's own: not an override
        let gun = child(world, root, "Gun")!
        let base = child(world, root, "Base")!
        let gunID = world.id(of: gun)!
        world.modify(Transform.self, for: gun) { $0.position.y = 3 }
        world.modify(Aim.self, for: gun) { $0.target = world.ref(to: other) }        // to outside the instance
        world.remove(MeshRenderer.self, from: base)
        world.add(Health(value: 5), to: base)
        world.despawn(child(world, gun, "Muzzle")!)
        let extra = world.spawn(Transform(), Name("Extra"))
        world.setParent(extra, to: gun)

        let overrides = world.prefabOverrides(of: root, template: template)
        #expect(Set(overrides.map(\.description)) == [
            "Transform.position.1", "Test.PrefabAim.target", "Test.PrefabAim.handle", "-MeshRenderer", "+Test.PrefabHealth", "-entity " + String(template.localID(of: template.order[2])!.prefix(8)),
        ])
        #expect(world.prefabAddedEntities(of: root).map(\.entity) == [extra])

        // The prefab changes: the gun moves sideways, the base gets bigger, a light appears.
        let edited = World()
        let prefabRoot = try edited.load(template.data)[0]
        let prefabGun = child(edited, prefabRoot, "Gun")!
        edited.modify(Transform.self, for: prefabGun) { $0.position.x = 2 }
        edited.modify(Transform.self, for: child(edited, prefabRoot, "Base")!) { $0.scale = Vec3(2, 2, 2) }
        edited.modify(Health.self, for: prefabRoot) { $0.regen = 3 }
        let light = edited.spawn(Transform(), Name("Light"))
        edited.setParent(light, to: prefabRoot)
        let newTemplate = try PrefabAsset(scene: edited.save([prefabRoot])).template(prefabs: { _ in nil })

        root = try world.syncPrefabInstance(root, template: newTemplate, previous: template)
        let newGun = try #require(child(world, root, "Gun"))
        #expect(world.id(of: newGun) == gunID)
        #expect(world.get(Transform.self, for: root)?.position == Vec3(9, 9, 9))
        #expect(world.get(Transform.self, for: newGun)?.position == Vec3(2, 3, 0))  // the prefab's x, the instance's y
        #expect(world.resolve(world.get(Aim.self, for: newGun)!.target) == other)
        #expect(child(world, newGun, "Muzzle") == nil)
        #expect(child(world, newGun, "Extra") == extra)
        let newBase = try #require(child(world, root, "Base"))
        #expect(world.get(MeshRenderer.self, for: newBase) == nil)
        #expect(world.get(Health.self, for: newBase) == Health(value: 5))
        #expect(world.get(Transform.self, for: newBase)?.scale == Vec3(2, 2, 2))
        #expect(world.get(Health.self, for: root)?.regen == 3)
        #expect(child(world, root, "Light") != nil)
        #expect(world.get(PrefabInstance.self, for: root)?.overrides.count == 6)
        #expect(world.get(PrefabInstance.self, for: root)?.entities.count == 5)

        // The untouched instance takes everything.
        let plainRoot = try world.syncPrefabInstance(plain, template: newTemplate, previous: template)
        #expect(world.get(Transform.self, for: child(world, plainRoot, "Gun")!)?.position == Vec3(2, 1, 0))
        #expect(world.prefabOverrides(of: plainRoot, template: newTemplate).isEmpty)
        // Overrides against the new template are the same changes.
        #expect(world.prefabOverrides(of: root, template: newTemplate).count == 6)
    }

    @Test func storedOverridesSurviveSaveAndLoad() throws {
        let template = try PrefabAsset(scene: turretData()).template(prefabs: { _ in nil })
        let world = World()
        world.assignsEntityIDs = true
        let root = try world.instantiatePrefab(template, reference: AssetReference(AssetID(high: 1, low: 1)))
        world.modify(Health.self, for: root) { $0.value = 42 }
        var link = world.get(PrefabInstance.self, for: root)!
        link.overrides = world.prefabOverrides(of: root, template: template)
        world.add(link, to: root)
        let saved = try world.save()

        let loaded = World()
        loaded.assignsEntityIDs = true
        let loadedRoot = try loaded.load(saved)[0]
        // Opened later: no previous template, the stored overrides apply to the prefab as it is now.
        let rebuilt = try loaded.syncPrefabInstance(loadedRoot, template: template, previous: nil)
        #expect(loaded.get(Health.self, for: rebuilt)?.value == 42)
        #expect(loaded.id(of: rebuilt) == world.id(of: root))
        let gun = child(loaded, rebuilt, "Gun")!
        #expect(loaded.resolve(loaded.get(Aim.self, for: gun)!.target) == child(loaded, gun, "Muzzle"))
    }

    @Test func applyRevertAndCreate() throws {
        let data = try turretData()
        let template = try PrefabAsset(scene: data).template(prefabs: { _ in nil })
        let world = World()
        world.assignsEntityIDs = true
        let root = try world.instantiatePrefab(template, reference: AssetReference(AssetID(high: 1, low: 1)))
        let gun = child(world, root, "Gun")!
        world.modify(Transform.self, for: gun) { $0.position = Vec3(0, 7, 0) }
        world.modify(Aim.self, for: gun) { $0.handle = gun }

        // Revert gives back the prefab's component, with references into this instance.
        let reverted = try #require(try world.prefabComponent(named: Aim.componentName, of: gun, template: template) as? Aim)
        #expect(reverted.handle == child(world, gun, "Muzzle"))
        #expect(world.resolve(reverted.target) == child(world, gun, "Muzzle"))

        // Apply writes the instance's component into the prefab, with references into the prefab.
        let applied = try world.prefabData(applying: Transform.componentName, of: gun, to: data)
        let appliedAim = try world.prefabData(applying: Aim.componentName, of: gun, to: applied)
        let newTemplate = try PrefabAsset(scene: appliedAim).template(prefabs: { _ in nil })
        let prefabGun = child(newTemplate.world, newTemplate.root, "Gun")!
        #expect(newTemplate.world.get(Transform.self, for: prefabGun)?.position == Vec3(0, 7, 0))
        #expect(newTemplate.world.get(Aim.self, for: prefabGun)?.handle == prefabGun)
        #expect(world.prefabOverrides(of: root, template: newTemplate).isEmpty)

        // A prefab from a subtree that holds an instance: the instance is nested, the new root isn't linked.
        let holder = world.spawn(Transform(position: Vec3(3, 0, 0)), Name("Holder"))
        world.setParent(root, to: holder)
        let (holderData, entities) = try world.prefabData(from: holder, rootTransform: Transform())
        #expect(entities.count == 5)
        #expect(Set(entities.values.compactMap { world.resolve($0) }) == Set(world.subtreeOrder(holder)))
        let holderTemplate = try PrefabAsset(scene: holderData).template(prefabs: { _ in nil })
        #expect(holderTemplate.world.get(Transform.self, for: holderTemplate.root)?.position == .zero)
        #expect(holderTemplate.world.independentPrefabInstances().count == 1)
    }

    @Test func nestedPrefabsFollowTheInnerPrefab() throws {
        let innerID = AssetID(high: 2, low: 2)
        var innerData = try turretData()
        let innerTemplate = try PrefabAsset(scene: innerData).template(prefabs: { _ in nil })
        // The outer prefab: a "Fort" holding a turret instance.
        let authoring = World()
        authoring.assignsEntityIDs = true
        let fort = authoring.spawn(Transform(), Name("Fort"))
        let turret = try authoring.instantiatePrefab(innerTemplate, reference: AssetReference(innerID), under: fort)
        authoring.modify(Health.self, for: turret) { $0.value = 300 }   // an override inside the outer prefab
        var link = authoring.get(PrefabInstance.self, for: turret)!
        link.overrides = authoring.prefabOverrides(of: turret, template: innerTemplate)
        authoring.add(link, to: turret)
        let outer = PrefabAsset(scene: try authoring.prefabData(from: fort, rootTransform: Transform()).data)

        var lookup: (AssetReference) -> PrefabAsset? = { $0.asset == innerID ? PrefabAsset(scene: innerData) : nil }
        let outerTemplate = try outer.template(prefabs: lookup)
        #expect(outerTemplate.nestedPrefabs == [innerID])
        let world = World()
        world.assignsEntityIDs = true
        let instance = try world.instantiatePrefab(outerTemplate, reference: AssetReference(AssetID(high: 3, low: 3)))
        #expect(world.independentPrefabInstances() == [instance])

        // The inner prefab gets a new child; the outer template and its instances follow.
        let edited = World()
        let editedRoot = try edited.load(innerData)[0]
        edited.setParent(edited.spawn(Transform(), Name("Radar")), to: editedRoot)
        innerData = try edited.save([editedRoot])
        lookup = { $0.asset == innerID ? PrefabAsset(scene: innerData) : nil }
        let newOuter = try outer.template(prefabs: lookup)
        #expect(newOuter.data != outerTemplate.data)
        let rebuilt = try world.syncPrefabInstance(instance, template: newOuter, previous: outerTemplate)
        let nestedTurret = try #require(child(world, rebuilt, "Turret"))
        #expect(child(world, nestedTurret, "Radar") != nil)
        #expect(world.get(Health.self, for: nestedTurret)?.value == 300)
        #expect(world.prefabLink(of: nestedTurret)?.root == rebuilt)
    }

    @Test func prefabFilesHotReloadThroughTheDatabase() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let project = try Project.create(at: folder)
        let database = AssetDatabase(project: project)
        let id = try database.createPrefab(try turretData(), at: "Turret.prefab")
        #expect(database.record(id)?.importer == "prefab")
        #expect(database.record(id)?.objects.map(\.kind) == [.prefab])
        let reference = AssetReference(id)

        let world = World()
        world.assignsEntityIDs = true
        let sync = PrefabSync()
        let template = try #require(sync.template(for: reference, in: database))
        let root = try world.instantiatePrefab(template, reference: reference)
        sync.didBuild(reference, from: template)
        world.modify(Health.self, for: child(world, root, "Base") ?? root) { $0.value = 1 }   // no Health on Base: nothing
        world.modify(Health.self, for: root) { $0.value = 7 }
        #expect(sync.sync(world, database: database).isEmpty)  // nothing changed yet

        // Edit the file (another tool, or Apply to Prefab), reimport, sync.
        let file = World()
        let fileRoot = try file.load(database.fileData(of: id))[0]
        file.modify(Transform.self, for: child(file, fileRoot, "Gun")!) { $0.scale = Vec3(1, 2, 1) }
        try database.writePrefab(file.save([fileRoot]), to: id)
        let rebuilt = sync.sync(world, database: database)
        #expect(rebuilt.count == 1)
        let newRoot = rebuilt[0]
        #expect(world.get(Transform.self, for: child(world, newRoot, "Gun")!)?.scale == Vec3(1, 2, 1))
        #expect(world.get(Health.self, for: newRoot)?.value == 7)
        sync.refreshOverrides(in: world, database: database)
        #expect(world.get(PrefabInstance.self, for: newRoot)?.overrides.map(\.description) == ["Test.PrefabHealth.value"])

        // A plain copy for previews (thumbnails): the file's entities with new ids.
        let preview = World()
        let copy = preview.instantiate(try #require(database.prefab(reference)))
        #expect(copy.count == 1 && preview.entityCount == 4 && preview.get(PrefabInstance.self, for: copy[0]) == nil)
    }

    @Test func skinsSurviveTheMeshCache() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let project = try Project.create(at: folder)
        try skinnedGLTF().write(to: project.url(forAssetPath: "Rig.gltf"))
        let first = AssetDatabase(project: project)
        first.refresh()
        let id = try #require(first.id(forPath: "Rig.gltf"))
        #expect(first.record(id)?.importError == nil)

        // A second database reads the Library cache instead of importing.
        let cached = AssetDatabase(project: project)
        let report = cached.refresh()
        #expect(report.imported.isEmpty)
        let meshInfo = try #require(cached.record(id)?.objects.first { $0.kind == .mesh })
        let mesh = try #require(cached.mesh(AssetReference(id, subAsset: meshInfo.id)))
        #expect(mesh.skin?.count == 3)
        #expect(mesh.skin?[2] == SkinInfluence(joints: SIMD4(0, 1, 0, 0), weights: Vec4(0.5, 0.5, 0, 0)))
        #expect(mesh.skin?[0].weights == Vec4(1, 0, 0, 0))

        let prefab = try #require(cached.prefab(AssetReference(id)))
        let world = World()
        let roots = world.instantiate(prefab)
        #expect(roots.count == 1)
        var skinned: (Entity, Skin)?
        world.query(Skin.self) { skinned = ($0, $1) }
        let (meshEntity, skin) = try #require(skinned)
        #expect(world.get(Name.self, for: meshEntity)?.value == "Mesh")
        #expect(skin.joints.map { world.get(Name.self, for: $0)?.value } == ["Root", "Tip"])
        #expect(skin.inverseBindMatrices[1] == Mat4.translation(Vec3(0, -1, 0)))

        // Linked instances keep the skin bound to their own joints.
        let template = try prefab.template(prefabs: { _ in nil })
        let instance = try world.instantiatePrefab(template, reference: AssetReference(id))
        var bound: [Entity] = []
        world.query(Skin.self) { entity, skin in if world.isDescendant(entity, of: instance) { bound = skin.joints } }
        #expect(bound.count == 2 && bound.allSatisfy { world.isDescendant($0, of: instance) })
    }
}

/// A tiny skinned glTF (from SkinningTests): a triangle bound to a root joint and a child one.
private func skinnedGLTF() -> Data {
    var bin: [UInt8] = []
    var views: [[String: Any]] = [], accessors: [[String: Any]] = []
    func add<T: BitwiseCopyable>(_ values: [T], componentType: Int, count: Int, type: String) -> Int {
        while bin.count % 4 != 0 { bin.append(0) }
        let bytes = values.withUnsafeBytes { Array($0) }
        views.append(["buffer": 0, "byteOffset": bin.count, "byteLength": bytes.count])
        bin += bytes
        accessors.append(["bufferView": views.count - 1, "componentType": componentType, "count": count, "type": type])
        return accessors.count - 1
    }
    let positions = add([Float](arrayLiteral: 0, 0, 0, 1, 0, 0, 0, 2, 0), componentType: 5126, count: 3, type: "VEC3")
    let joints = add([UInt8](arrayLiteral: 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0), componentType: 5121, count: 3, type: "VEC4")
    let weights = add([Float](arrayLiteral: 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0), componentType: 5126, count: 3, type: "VEC4")
    let ibm: [Float] = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1, 0, 1]
    let inverseBind = add(ibm, componentType: 5126, count: 2, type: "MAT4")
    let json: [String: Any] = [
        "asset": ["version": "2.0"],
        "scene": 0,
        "scenes": [["nodes": [0, 1]]],
        "nodes": [
            ["name": "Mesh", "mesh": 0, "skin": 0],
            ["name": "Root", "children": [2]],
            ["name": "Tip", "translation": [0, 1, 0]],
        ],
        "meshes": [["primitives": [["attributes": ["POSITION": positions, "JOINTS_0": joints, "WEIGHTS_0": weights]]]]],
        "skins": [["joints": [1, 2], "inverseBindMatrices": inverseBind, "skeleton": 1]],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [["byteLength": bin.count, "uri": "data:application/octet-stream;base64," + Data(bin).base64EncodedString()]],
    ]
    return try! JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
}
