import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineRendering

// Game-ready plants (MeshBuildLOD.swift, MeshBuildImpostor.swift, Wind.swift): wind on plant
// materials, detail levels with an impostor, and many placed copies drawing instanced.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildPlantTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MeshBuildPlant")
}

/// A small tree on a pot: a bark trunk, two branches with leaves on them, a crown and a pot.
private func tree(lod: Bool? = nil, lodDistances: [Float]? = nil, wind: Float? = nil) -> MeshBuild {
    func sweep(_ name: String, _ path: [Vec3], radius: Float, parent: String = "") -> MeshBuildPart {
        var part = MeshBuildPart(name: name, shape: .sweep, parent: parent, look: "bark")
        part.path = path
        part.radius = radius
        part.radii = Array(repeating: 1, count: path.count - 1) + [0.3]
        part.segments = 12
        return part
    }
    var leaves = MeshBuildPart(name: "Leaves", shape: .foliage, parent: "Trunk", look: "oakLeaves")
    leaves.on = ["Branch A", "Branch B"]
    leaves.cardSize = 0.4
    var crown = MeshBuildPart(name: "Crown", shape: .foliage, parent: "Trunk", position: Vec3(0, 3, 0), size: Vec3(2.4, 1.6, 2.4),
                              look: "oakLeaves")
    crown.cardSize = 0.45
    crown.seed = 3
    return MeshBuild(parts: [
        MeshBuildPart(name: "Pot", shape: .cylinder, position: Vec3(0, 0.15, 0), size: Vec3(0.8, 0.3, 0.8), color: Vec3(0.6, 0.3, 0.2)),
        sweep("Trunk", [Vec3(0, 0.2, 0), Vec3(0.05, 1.5, 0), Vec3(0, 3, 0)], radius: 0.12),
        sweep("Branch A", [Vec3(0, 2, 0), Vec3(0.6, 2.5, 0), Vec3(1.1, 2.9, 0.1)], radius: 0.05, parent: "Trunk"),
        sweep("Branch B", [Vec3(0, 2.2, 0), Vec3(-0.5, 2.7, 0.2), Vec3(-0.9, 3.1, 0.3)], radius: 0.05, parent: "Trunk"),
        leaves, crown,
    ], lod: lod, lodDistances: lodDistances, wind: wind)
}

@MainActor private func importBuild(_ build: MeshBuild, _ body: @MainActor (AssetDatabase, AssetID, PrefabAsset) throws -> Void) throws {
    let project = try makeProject()
    defer { try? FileManager.default.removeItem(at: project.root) }
    let database = AssetDatabase(project: project)
    let id = try database.createMeshBuild(build, at: "Models/tree.meshbuild")
    database.refreshAsync()
    database.waitForAll()
    try body(database, id, try #require(database.prefab(AssetReference(id))))
}

/// Every node with its model-space matrix, depth first.
private func flatten(_ prefab: PrefabAsset) -> [(node: PrefabNode, model: Mat4)] {
    var out: [(PrefabNode, Mat4)] = []
    func walk(_ node: PrefabNode, _ parent: Mat4) {
        let m = parent * node.transform.matrix
        out.append((node, m))
        for child in node.children { walk(child, m) }
    }
    for root in prefab.roots { walk(root, .identity) }
    return out
}

@MainActor private func triangles(_ database: AssetDatabase, _ key: String) -> Int {
    guard !key.isEmpty, let reference = AssetReference(key) else { return 0 }
    return (database.mesh(reference)?.indices.count ?? 0) / 3
}

@Suite(.serialized) struct MeshBuildPlantTests {
    // MARK: Wind

    @Test func windIsStillAtTheBaseAndGrowsWithHeight() {
        let material = MaterialWind(flutter: 1, height: 5)
        let wind = Wind(strength: 1, gustiness: 0.5)
        var low: Float = 0, middle: Float = 0, top: Float = 0
        for k in 0..<40 {
            let t = Float(k) * 0.37
            #expect(WindSway.offset(.zero, material: material, wind: wind, time: t) == .zero, "the base doesn't move")
            #expect(WindSway.offset(Vec3(0.3, -1, 0.2), material: material, wind: wind, time: t) == .zero, "nor what's below it")
            low += length(WindSway.offset(Vec3(0, 1, 0), material: material, wind: wind, time: t))
            middle += length(WindSway.offset(Vec3(0, 2.5, 0), material: material, wind: wind, time: t))
            top += length(WindSway.offset(Vec3(0, 5, 0), material: material, wind: wind, time: t))
        }
        #expect(low < middle && middle < top, "\(low) < \(middle) < \(top)")
        // The bend grows with the square of the height: the top moves about 4x the middle.
        #expect(top > 2.5 * middle, "\(top) vs \(middle)")
        // At strength 1 the top moves a few percent of the height, never more than the most a gust bends it (plus flutter).
        let most = WindSway.maxBend(height: 5, plantHeight: 5, wind: wind) + 0.05
        for k in 0..<40 {
            let d = length(WindSway.offset(Vec3(0, 5, 0), material: material, wind: wind, time: Float(k) * 0.37))
            #expect(d > 0.02 && d <= most, "\(d) m (most \(most))")
        }
        // The bend follows the wind, in the mesh's own space.
        let along = WindSway.offset(Vec3(0, 5, 0), material: MaterialWind(flutter: 0, height: 5), wind: Wind(direction: Vec3(0, 0, 1)),
                                    time: 1)
        #expect(along.z > 0.05 && abs(along.x) < 1e-4, "\(along)")
        let turned = Mat4.translation(Vec3(3, 0, 0)) * Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)).matrix
        let local = WindSway.offset(Vec3(0, 5, 0), material: MaterialWind(flutter: 0, height: 5), wind: Wind(direction: Vec3(0, 0, 1)),
                                    model: turned, time: 1)
        let world = turned * Vec4(local, 0)
        #expect(world.z > 0.05 && abs(world.x) < 1e-4, "the turned model still bends toward +Z: \(world)")
    }

    @Test func windIsDeterministicCalmIsStillAndCopiesSwayOutOfStep() {
        let material = MaterialWind(flutter: 1, height: 4)
        let p = Vec3(0.4, 3, -0.2)
        let a = WindSway.offset(p, material: material, wind: Wind(), time: 12.5)
        #expect(a == WindSway.offset(p, material: material, wind: Wind(), time: 12.5), "same inputs, same sway")
        #expect(a != .zero)
        #expect(WindSway.offset(p, material: material, wind: .calm, time: 12.5) == .zero, "no wind, no sway")
        #expect(WindSway.offset(p, material: MaterialWind(flutter: 0, bend: 0, height: 4), wind: Wind(), time: 12.5) == .zero)
        // Two copies of a plant at different places sway differently at the same moment.
        let other = WindSway.offset(p, material: material, wind: Wind(), model: .translation(Vec3(7, 0, 3)), time: 12.5)
        #expect(length(other - a) > 1e-3, "\(a) vs \(other)")
        // Flutter alone moves leaves a little (a few cm), more than branches.
        let leaf = MaterialWind(flutter: 1, bend: 0, height: 4), branch = MaterialWind(flutter: 0.08, bend: 0, height: 4)
        var leafMotion: Float = 0, branchMotion: Float = 0
        for k in 0..<30 {
            leafMotion = max(leafMotion, length(WindSway.offset(p, material: leaf, wind: Wind(strength: 1), time: Float(k) * 0.21)))
            branchMotion = max(branchMotion, length(WindSway.offset(p, material: branch, wind: Wind(strength: 1), time: Float(k) * 0.21)))
        }
        #expect(leafMotion > 0.01 && leafMotion < 0.06 && branchMotion < leafMotion / 5, "\(leafMotion) \(branchMotion)")
    }

    @Test func windSettingsDecodeWithDefaults() throws {
        let environment = try JSONDecoder().decode(SceneEnvironment.self, from: Data(#"{"ambientIntensity": 0.3}"#.utf8))
        #expect(environment.wind == Wind())
        let wind = try JSONDecoder().decode(Wind.self, from: Data(#"{"strength": 2}"#.utf8))
        #expect(wind.strength == 2 && wind.gustiness == Wind().gustiness)
        #expect(Wind(direction: .zero).horizontalDirection == Vec2(1, 0))
        var material = MaterialAsset()
        #expect(!String(decoding: try JSONEncoder().encode(material), as: UTF8.self).contains("wind"), "nil isn't written")
        material.wind = MaterialWind(flutter: 0.5, height: 3)
        let decoded = try JSONDecoder().decode(MaterialAsset.self, from: JSONEncoder().encode(material))
        #expect(decoded.wind == material.wind)
        #expect(material.material(textures: { _ in nil }).sways)
    }

    // MARK: Import

    @MainActor @Test func plantsGetWindOnLeavesAndBranchesOnly() throws {
        try importBuild(tree()) { database, id, prefab in
            for (node, _) in flatten(prefab) {
                guard let reference = node.material, let material = database.material(reference) else { continue }
                switch node.name {
                case "Pot": #expect(material.wind == nil, "the pot stays still")
                case "Leaves", "Crown": #expect(material.wind?.flutter == 1 && material.wind?.bend == 1, "\(node.name)")
                default: #expect(material.wind.map { $0.flutter > 0 && $0.flutter < 0.2 && $0.bend == 1 } == true, "\(node.name)")
                }
            }
            // Every part's wind names the same base and up axis in model space, so they bend together.
            for (node, model) in flatten(prefab) {
                guard let reference = node.material, let wind = database.material(reference)?.wind else { continue }
                let base = model * Vec4(wind.origin, 1), up = model * Vec4(wind.up, 0)
                #expect(length(Vec3(base.x, base.y, base.z)) < 1e-4 && abs(up.y - 1) < 1e-4, "\(node.name)")
                #expect(abs(wind.height - 3.9) < 0.4, "the plant's height: \(wind.height)")
            }
        }
        var still = tree(wind: 0)
        still.lod = false
        try importBuild(still) { database, _, prefab in
            for (node, _) in flatten(prefab) {
                guard let reference = node.material else { continue }
                #expect(database.material(reference)?.wind == nil, "wind 0 keeps \(node.name) still")
                #expect(node.lod == nil, "lod false makes no levels")
            }
        }
    }

    @MainActor @Test func detailLevelsShrinkAndSwitchTogether() throws {
        try importBuild(tree()) { database, _, prefab in
            let nodes = flatten(prefab).filter { $0.node.mesh != nil }
            #expect(nodes.count == 6)
            var totals = [0, 0, 0, 0]
            var spheres: [Vec4] = []
            for (node, model) in nodes {
                let lod = try #require(node.lod, "\(node.name) has detail levels")
                #expect(lod.levelCount == 3 && lod.distances.count == 3)
                #expect(lod.distances == nodes[0].node.lod?.distances, "every part switches at the same distances")
                #expect(zip(lod.distances, lod.distances.dropFirst()).allSatisfy { $0 < $1 })
                let s = try #require(lod.sphere)
                let c = model * Vec4(s.x, s.y, s.z, 1)
                spheres.append(Vec4(c.x, c.y, c.z, s.w))
                let base = MeshHandle(node.mesh!)
                for level in 0...3 { totals[level] += triangles(database, lod.mesh(level: level, base: base).key) }
            }
            for s in spheres { #expect(length(Vec3(s.x - spheres[0].x, s.y - spheres[0].y, s.z - spheres[0].z)) < 1e-3 && s.w == spheres[0].w) }
            // Distances follow the plant's size: about 8, 16 and 32 times its radius.
            let radius = spheres[0].w
            #expect(abs(nodes[0].node.lod!.distances[0] - 8 * radius) < 1e-3, "\(nodes[0].node.lod!.distances) r \(radius)")
            #expect(totals[0] > totals[1] && totals[1] > totals[2] && totals[2] > totals[3], "\(totals)")
            #expect(Float(totals[1]) < 0.75 * Float(totals[0]), "level 1 is much lighter: \(totals)")
            #expect(totals[3] == 6, "the impostor is three crossed quads: \(totals)")
            // Levels 1+ merge parts with equal materials: one bark mesh, one leaf mesh, the pot.
            for level in 1...2 {
                let drawn = nodes.filter { !$0.node.lod!.mesh(level: level, base: MeshHandle($0.node.mesh!)).key.isEmpty }
                #expect(drawn.count == 3, "level \(level): \(drawn.map(\.node.name))")
            }
            // The impostor draws on one part with a material of its own; the rest draw nothing.
            let far = nodes.filter { !$0.node.lod!.mesh(level: 3, base: MeshHandle($0.node.mesh!)).key.isEmpty }
            #expect(far.count == 1)
            let impostorMaterial = try #require(far.first?.node.lod?.material(level: 3))
            let material = try #require(AssetReference(impostorMaterial.key).flatMap { database.material($0) })
            #expect(material.alphaMode == .mask && material.doubleSided && material.texture != nil && material.normalTexture != nil)
            #expect(material.wind?.flutter == 0 && material.wind?.bend == 1, "the impostor bends with the plant")
        }
    }

    @Test func thinnedCardsAreNestedGrownSubsets() throws {
        var part = MeshBuildPart(name: "Leaves", shape: .foliage, size: Vec3(2, 2, 2), look: "oakLeaves")
        part.count = 200
        let full = try #require(part.geometry())
        let half = try #require(MeshBuildLOD.thinnedCards(full, share: 0.5, growth: 1.3, quadsPerCard: 1, seed: 9))
        let quarter = try #require(MeshBuildLOD.thinnedCards(full, share: 0.25, growth: 1.3, quadsPerCard: 1, seed: 9))
        #expect(half.indices.count == 100 * 6 && quarter.indices.count == 50 * 6)
        // Each quarter card's stem is one of the half's stems.
        let stems = Set(stride(from: 0, to: half.vertices.count, by: 4).map { half.vertices[$0].position + half.vertices[$0 + 1].position })
        for k in stride(from: 0, to: quarter.vertices.count, by: 4) {
            #expect(stems.contains(quarter.vertices[k].position + quarter.vertices[k + 1].position))
        }
        // Grown about the stem: each kept card is 1.3 times as long as some original card.
        let sides = Set(stride(from: 0, to: full.vertices.count, by: 4).map {
            Int((length(full.vertices[$0 + 2].position - full.vertices[$0 + 1].position) * 1.3 * 1000).rounded())
        })
        for k in stride(from: 0, to: half.vertices.count, by: 4) {
            let side = Int((length(half.vertices[k + 2].position - half.vertices[k + 1].position) * 1000).rounded())
            #expect(sides.contains(side) || sides.contains(side - 1) || sides.contains(side + 1))
        }
        // A mesh whose quads don't follow one another isn't touched.
        var shuffled = full
        shuffled.indices.swapAt(0, 7)
        #expect(MeshBuildLOD.thinnedCards(shuffled, share: 0.5, growth: 1, quadsPerCard: 1, seed: 1) == nil)
    }

    @MainActor @Test func lodSettingsAndWarnings() throws {
        try importBuild(tree(lodDistances: [10, 25])) { _, _, prefab in
            let lod = try #require(flatten(prefab).first { $0.node.mesh != nil }?.node.lod)
            #expect(lod.distances == [10, 25, 50], "missing distances double the last")
        }
        #expect(tree(lodDistances: [5, 3]).plantFieldWarnings.contains { $0.contains("increasing") })
        #expect(tree(wind: -1).plantFieldWarnings.contains { $0.contains("wind") })
        #expect(tree().plantFieldWarnings.isEmpty)
        // A build without foliage is no plant: no wind, no levels, unless asked.
        let box = MeshBuild(parts: [MeshBuildPart(name: "Box")])
        #expect(!box.makesDetailLevels && box.effectiveWind == 0)
        try importBuild(box) { _, _, prefab in #expect(flatten(prefab).allSatisfy { $0.node.lod == nil }) }
    }

    // MARK: MeshLOD and instancing

    @Test func meshLODMeasuresFromItsSphereAndHasPerLevelMaterials() throws {
        let lod = MeshLOD(meshes: [MeshHandle("a"), MeshHandle(""), MeshHandle("c")], distances: [10, 20, 40],
                          materials: [MaterialHandle(""), MaterialHandle(""), MaterialHandle("far")], sphere: Vec4(0, 2, 0, 3))
        #expect(lod.material(level: 1) == nil && lod.material(level: 3)?.key == "far" && lod.material(level: 0) == nil)
        let model = Mat4.translation(Vec3(5, 0, 0)) * Mat4.scale(Vec3(2, 2, 2))
        #expect(abs(MeshLOD.distance(from: Vec3(5, 4, 20), toSphere: lod.sphere!, model: model) - 14) < 1e-4)
        let data = try JSONEncoder().encode(MeshLOD(meshes: [MeshHandle("a")], distances: [3]))
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("materials") && !text.contains("sphere"), "unset fields aren't written: \(text)")
        #expect(try JSONDecoder().decode(MeshLOD.self, from: JSONEncoder().encode(lod)) == lod)
    }

    @MainActor @Test func placedCopiesDrawInstancedPerPartAndLevel() throws {
        try importBuild(tree()) { database, id, prefab in
            let world = World()
            let copies = 200
            for k in 0..<copies {
                let root = world.instantiate(prefab).first!
                world.add(Transform(position: Vec3(Float(k % 20) * 6, 0, Float(k / 20) * 6)), to: root)
            }
            world.propagateTransforms()
            var prep = RenderPrep()
            var keys: Set<String> = []
            world.query(MeshRenderer.self) { _, renderer in keys.insert(renderer.mesh.key); keys.insert(renderer.material.key) }
            world.query(MeshLOD.self) { _, lod in
                for mesh in lod.meshes where !mesh.key.isEmpty { keys.insert(mesh.key) }
                for material in lod.materials where !material.key.isEmpty { keys.insert(material.key) }
            }
            for key in keys {
                guard let reference = AssetReference(key) else { continue }
                if let mesh = database.mesh(reference) { prep.meshes.register(mesh.bounds, key: key) }
                if let material = database.material(reference) {
                    let m = material.material(textures: { _ in nil })
                    prep.materials.register(MaterialTraits(blends: m.blends, alphaTested: m.masksDepth || m.sways), key: key)
                }
            }
            let view = Frustum(viewProjection: Mat4.orthographic(left: -1000, right: 1000, bottom: -1000, top: 1000, near: -1000, far: 1000))
            @MainActor func batches(from eye: Vec3) -> (opaque: Int, items: Int) {
                prep.lodViewpoint = eye
                prep.gather(world: world)
                var list = RenderList()
                list.build(items: prep.items, view: view, cameraPosition: eye, shadows: nil)
                #expect(list.opaque.reduce(0) { $0 + $1.count } == prep.items.count)
                return (list.opaque.count, prep.items.count)
            }
            // Up close: every copy draws every part, one instanced batch per part (mesh + material).
            let near = batches(from: Vec3(57, 3, 57))
            #expect(near.items > 6 * copies / 2, "\(near)")
            // Far away: only the impostors, all in one batch.
            let far = batches(from: Vec3(57, 3, 5_000))
            #expect(far == (1, copies), "\(far)")
            // Anywhere, copies at different levels: at most a batch per part and level (6 + 3 + 3 + 1).
            let middle = batches(from: Vec3(57, 3, 150))
            #expect(middle.opaque <= 13 && middle.items < near.items, "\(middle)")
            _ = id
        }
    }
}
