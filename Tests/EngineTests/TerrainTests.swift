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

// Terrain: height data, brushes, splat painting, chunk meshes, scatter and the .terrain importer.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TerrainTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Terrain")
}

private func flat(_ resolution: Int = 33, size: Float = 32, height: Float = 0.25) -> Terrain {
    var t = Terrain(size: Vec2(size, size), resolution: resolution, chunkCells: 8,
                    layers: [TerrainLayer(name: "Grass", color: Vec3(0, 1, 0)), TerrainLayer(name: "Rock", color: Vec3(1, 0, 0))])
    t.normalizeData()
    t.heightData = [UInt16](repeating: UInt16(height * 65535), count: t.res * t.res)
    return t
}

@Suite struct TerrainTests {
    @Test func generationIsDeterministicAndSeeded() {
        let a = Terrain.generated(resolution: 33, seed: 5), b = Terrain.generated(resolution: 33, seed: 5)
        let c = Terrain.generated(resolution: 33, seed: 6)
        #expect(a == b)
        #expect(a.heightData != c.heightData)
        #expect(a.heightData.count == 33 * 33 && Set(a.heightData).count > 50)
    }

    @Test func fileRoundTripsAndSparseFilesDecode() throws {
        var t = Terrain.generated(resolution: 17, seed: 3)
        t.scatter = [TerrainScatter(name: "Rocks", asset: "Models/rock.meshbuild", density: 3)]
        #expect(try AssetJSON.decoder().decode(Terrain.self, from: t.fileData()) == t)
        let sparse = try AssetJSON.decoder().decode(Terrain.self, from: Data("{}".utf8))
        #expect(sparse.resolution == 129 && sparse.heightData.isEmpty && sparse.layers.isEmpty)
        #expect(sparse.heightAt(x: 0, z: 0) == 0)
    }

    @Test func heightIsInterpolatedAndCentered() {
        var t = flat(height: 0)
        t.heightData[t.res * 16 + 16] = 65535   // center sample
        #expect(abs(t.heightAt(x: 0, z: 0) - t.heightRange) < 0.01)
        #expect(abs(t.heightAt(x: 0.5, z: 0) - t.heightRange / 2) < 0.01, "halfway to the neighbor, one cell = 1 m")
        #expect(t.heightAt(x: 100, z: 100) == 0, "clamped outside")
    }

    @Test func brushesChangeHeightsWithFalloff() {
        var t = flat()
        let base = t.heightAt(x: 0, z: 0)
        t.sculpt(.raise, at: [Vec2(0, 0)], radius: 6, strength: 2, falloff: 1)
        #expect(abs(t.heightAt(x: 0, z: 0) - base - 2) < 0.01)
        let edge = t.heightAt(x: 3, z: 0) - base
        #expect(edge > 0.1 && edge < 2, "falls off: \(edge)")
        #expect(abs(t.heightAt(x: 10, z: 0) - base) < 1e-3, "outside the radius")
        t.sculpt(.lower, at: [Vec2(0, 0)], radius: 6, strength: 2, falloff: 1)
        #expect(abs(t.heightAt(x: 0, z: 0) - base) < 0.01)

        t.sculpt(.raise, at: [Vec2(0, 0)], radius: 4, strength: 5, falloff: 0.5)
        let peak = t.heightAt(x: 0, z: 0)
        t.sculpt(.smooth, at: [Vec2(0, 0)], radius: 4, strength: 1, falloff: 0.5)
        #expect(t.heightAt(x: 0, z: 0) < peak)
        t.sculpt(.flatten, at: [Vec2(0, 0)], radius: 8, strength: 1, falloff: 0, height: 3)
        #expect(abs(t.heightAt(x: 1, z: 1) - 3) < 0.01)
        let before = t.heightData
        t.sculpt(.noise, at: [Vec2(-8, -8)], radius: 4, strength: 1)
        #expect(t.heightData != before)
        let changed = t.sculpt(.raise, at: [Vec2(500, 500)], radius: 4)
        #expect(!changed)
    }

    @Test func paintingKeepsWeightsSummingToOne() {
        var t = flat()
        #expect(t.weightAt(layer: 0, x: 0, z: 0) == 1)
        let ok = t.paint(layer: 1, at: [Vec2(0, 0)], radius: 5, strength: 1, falloff: 0)
        #expect(ok)
        #expect(t.weightAt(layer: 1, x: 0, z: 0) > 0.99)
        #expect(t.weightAt(layer: 1, x: 12, z: 0) == 0 && t.weightAt(layer: 0, x: 12, z: 0) == 1)
        t.paint(layer: 0, at: [Vec2(0, 0)], radius: 5, strength: 0.5, falloff: 0)
        let g = t.weightAt(layer: 0, x: 0, z: 0), r = t.weightAt(layer: 1, x: 0, z: 0)
        #expect(abs(g + r - 1) < 0.02 && g > 0.3 && r > 0.3, "\(g) \(r)")
        t.paint(layer: 1, at: [Vec2(0, 0)], radius: 5, strength: 1, falloff: 0, erase: true)
        #expect(t.weightAt(layer: 1, x: 0, z: 0) < 0.02 && t.weightAt(layer: 0, x: 0, z: 0) > 0.98)
        let bad = t.paint(layer: 9, at: [Vec2(0, 0)])
        #expect(!bad)
    }

    @Test func chunksTileTheTerrainWithSharedEdgesAndUpNormals() throws {
        let t = Terrain.generated(size: Vec2(32, 32), resolution: 33, seed: 2, hilliness: 1)
        var small = t
        small.chunkCells = 8
        #expect(small.chunkCounts.x == 4 && small.chunkCounts.z == 4)
        let a = small.chunkMesh(0, 0), b = small.chunkMesh(1, 0)
        #expect(a.vertices.count == 81 && a.indices.count == 8 * 8 * 6)
        let edgeA = a.vertices.filter { abs($0.position.x - (-16 + 8)) < 1e-4 }.map(\.position)
        let edgeB = b.vertices.filter { abs($0.position.x - (-16 + 8)) < 1e-4 }.map(\.position)
        #expect(edgeA.count == 9 && edgeA.sorted { $0.z < $1.z } == edgeB.sorted { $0.z < $1.z }, "neighbors meet exactly")
        let normalsB = b.vertices.filter { abs($0.position.x - (-16 + 8)) < 1e-4 }.map(\.normal).sorted { $0.z < $1.z }
        let normalsA = a.vertices.filter { abs($0.position.x - (-16 + 8)) < 1e-4 }.map(\.normal).sorted { $0.z < $1.z }
        #expect(normalsA == normalsB, "seam normals agree")
        let full = small.fullMesh()
        for i in stride(from: 0, to: full.indices.count, by: 3) {
            let p = (0..<3).map { full.vertices[Int(full.indices[i + $0])].position }
            let n = cross(p[1] - p[0], p[2] - p[0])
            #expect(n.y > 0, "faces up")
        }
        #expect(full.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-3 && $0.normal.y > 0 })
        let coarse = small.chunkMesh(0, 0, lod: 2)
        #expect(coarse.vertices.count == 9 && coarse.indices.count == 4 * 6)
        if case .triangleMesh(let vertices, let indices) = small.chunkCollider(2, 2) {
            #expect(vertices.count == 81 && indices.count == 384)
        } else { Issue.record("not a triangle mesh") }
    }

    @Test func slopeAndNormalFollowARamp() {
        var t = flat(height: 0)
        for z in 0..<t.res { for x in 0..<t.res { t.heightData[z * t.res + x] = UInt16(Float(x) / Float(t.res - 1) * 65535 * 16 / t.heightRange) } }
        // 16 m rise over 32 m: atan(0.5) = 26.57 degrees.
        #expect(abs(t.slopeAt(x: 0, z: 0) - 26.565) < 0.5)
        #expect(t.normalAt(x: 0, z: 0).x < 0)
    }

    @Test func scatterFollowsRulesAndSeed() {
        var t = flat(65, size: 64)
        // Left half high ground, right half low.
        for z in 0..<t.res { for x in 0..<t.res { t.heightData[z * t.res + x] = x < 32 ? 40000 : 10000 } }
        t.paint(layer: 1, at: [Vec2(20, 0)], radius: 12, strength: 1, falloff: 0)
        let all = t.instances(of: TerrainScatter(density: 10, maxSlope: 90))
        #expect(all.count > 300 && all.count <= 420, "\(all.count)")
        #expect(all == t.instances(of: TerrainScatter(density: 10, maxSlope: 90)), "stable")
        #expect(all != t.instances(of: TerrainScatter(density: 10, maxSlope: 90, seed: 2)))
        let high = t.instances(of: TerrainScatter(density: 10, maxSlope: 90, minHeight: 20))
        #expect(!high.isEmpty && high.allSatisfy { $0.position.y >= 20 })
        let rock = t.instances(of: TerrainScatter(density: 10, maxSlope: 90, layer: "Rock"))
        #expect(!rock.isEmpty && rock.allSatisfy { $0.position.x > 6 && $0.position.x < 34 })
        #expect(t.instances(of: TerrainScatter(density: 10, layer: "Nope")).isEmpty)
        #expect(t.instances(of: TerrainScatter(density: 100, maxSlope: 90, maxCount: 7)).count == 7)
        // The cliff between the halves is steeper than 45 degrees.
        let flatOnly = t.instances(of: TerrainScatter(density: 10, maxSlope: 10))
        #expect(flatOnly.allSatisfy { t.slopeAt(x: $0.position.x, z: $0.position.z) <= 10.01 })
        for i in all.prefix(20) { #expect(abs(i.position.y - t.heightAt(x: i.position.x, z: i.position.z)) < 1e-4) }
    }

    @Test func albedoBlendsLayerColors() {
        var t = flat(17, size: 16)
        t.paint(layer: 1, at: [Vec2(-8, 0)], radius: 6, strength: 1, falloff: 0)
        t.albedoSize = 32
        let image = t.bakeAlbedo()
        #expect(image.width == 32)
        func pixel(_ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8) { let o = (y * 32 + x) * 4; return (image.pixels[o], image.pixels[o + 1], image.pixels[o + 2]) }
        #expect(pixel(1, 16) == (255, 0, 0), "painted rock")
        #expect(pixel(30, 16) == (0, 255, 0), "grass")
        let tiled = t.bakeAlbedo(images: [Image(width: 1, height: 1, pixels: [0, 0, 255, 255]), nil])
        let o = (16 * 32 + 30) * 4
        #expect(tiled.pixels[o + 2] == 255 && tiled.pixels[o + 1] == 0, "a layer image replaces its color")
    }

    @MainActor @Test func importsChunksCollidersMaterialAndScatter() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createProceduralTexture(ProceduralTexture(generator: .noise, width: 16, height: 16), at: "Textures/dirt.proctex")
        let rock = try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Base", size: Vec3(1, 1, 1)), MeshBuildPart(name: "Top", parent: "Base", position: Vec3(0, 1, 0)),
            MeshBuildPart(name: "Pivot", shape: .group),
        ]), at: "Models/rock.meshbuild")

        var terrain = Terrain.generated(size: Vec2(32, 32), resolution: 33, seed: 4)
        terrain.chunkCells = 16
        terrain.lods = 2
        terrain.layers[2].texture = "Textures/dirt.proctex"
        terrain.paint(layer: 2, at: [Vec2(0, 0)], radius: 6, strength: 1)
        terrain.scatter = [TerrainScatter(name: "Rocks", asset: "Models/rock.meshbuild", density: 5, maxSlope: 90, maxCount: 40),
                           TerrainScatter(name: "Lost", asset: "Models/missing.meshbuild"),
                           TerrainScatter(name: "Cubes", asset: "asset:\(rock)#mesh/Base", density: 1, maxSlope: 90, maxCount: 3)]
        let id = try database.createTerrain(terrain, at: "Maps/hills.terrain")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importer == "terrain" && record.importError == nil)
        #expect(record.objects.filter { $0.kind == .mesh }.count == 8, "4 chunks, two levels each")
        #expect(record.objects.contains { $0.kind == .texture } && record.objects.contains { $0.kind == .material })
        #expect(database.terrain(of: id) == terrain)

        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(prefab.roots.first)
        #expect(root.name == "hills" && root.children.map(\.name) == ["chunk 0_0", "chunk 1_0", "chunk 0_1", "chunk 1_1", "Scatter"])
        #expect(root.children[0].collider != nil && root.children[0].mesh != nil && root.children[0].material != nil)
        let lod = try #require(root.children[0].lod, "two levels: the chunk swaps in its lod1 mesh")
        #expect(lod.meshes.map(\.key) == [AssetReference(id, subAsset: "mesh/chunk 0_0 lod1").description])
        #expect(lod.distances == terrain.lodDistances && lod.distances == [24], "1.5 chunk widths of 16 m")
        let scatter = try #require(root.children.last)
        #expect(scatter.children.map(\.name) == ["Rocks", "Cubes"], "the missing asset is skipped")
        let rocks = scatter.children[0].children
        #expect(!rocks.isEmpty && rocks.count <= 40)
        #expect(rocks[0].children.map(\.name) == ["Base", "Top"], "every shape of the mesh build, not the group")
        #expect(rocks[0].children[1].transform.position == Vec3(0, 1, 0))
        #expect(scatter.children[1].children.count == 3 && scatter.children[1].children[0].mesh?.subAsset == "mesh/Base")

        let world = World()
        let spawned = world.instantiate(prefab)
        #expect(spawned.count == 1)
        #expect(world.count(of: Collider.self) == 4)

        var edited = terrain
        edited.sculpt(.raise, at: [Vec2(0, 0)], radius: 5, strength: 3)
        let revision = database.revision(of: id)
        try database.writeTerrain(edited, to: id)
        database.refreshAsync()
        database.waitForAll()
        #expect(database.revision(of: id) > revision)
    }

    // MARK: LOD

    @Test func lodLevelsFollowDistanceWithHysteresis() {
        let lod = MeshLOD(meshes: [MeshHandle("TerrainTests.l1"), MeshHandle("TerrainTests.l2")], distances: [10, 20], hysteresis: 0.1)
        #expect(lod.level(distance: 5) == 0 && lod.level(distance: 10) == 1 && lod.level(distance: 25) == 2)
        #expect(lod.level(distance: 10.5, current: 0) == 0, "not yet past 10 x 1.1")
        #expect(lod.level(distance: 11.5, current: 0) == 1)
        #expect(lod.level(distance: 9.5, current: 1) == 1, "not yet inside 10 x 0.9")
        #expect(lod.level(distance: 8.5, current: 1) == 0)
        #expect(lod.level(distance: 50, current: 0) == 2 && lod.level(distance: 1, current: 2) == 0, "jumps several levels")
        #expect(lod.level(distance: .infinity) == 0)
        #expect(MeshLOD(meshes: [MeshHandle("TerrainTests.l1")], distances: []).level(distance: 100) == 0, "no distance, no level")
        let base = MeshHandle("TerrainTests.l0")
        #expect(lod.mesh(level: 0, base: base) == base && lod.mesh(level: 2, base: base) == lod.meshes[1] && lod.mesh(level: 3, base: base) == base)
        let box = Bounds(center: Vec3(0, 0, 0), halfExtent: Vec3(1, 1, 1))
        #expect(MeshLOD.distance(from: Vec3(0.5, 0, 0), to: box) == 0 && abs(MeshLOD.distance(from: Vec3(4, 5, 1), to: box) - 5) < 1e-5)
        let decoded = try? JSONDecoder().decode(MeshLOD.self, from: Data("{}".utf8))
        #expect(decoded == MeshLOD())
    }

    @Test func lodDistancesDefaultToChunkWidthsAndDouble() {
        var t = Terrain(size: Vec2(64, 64), resolution: 65, chunkCells: 16, lods: 3)
        #expect(t.lodDistances == [24, 48])
        t.lodDistance = 30
        #expect(t.lodDistances == [30, 60])
        t.lods = 1
        #expect(t.lodDistances.isEmpty && t.skirtDepth(0, 0) == 0)
        let data = try? JSONEncoder().encode(Terrain())
        #expect(data.map { !String(decoding: $0, as: UTF8.self).contains("lodDistance") } == true, "0 isn't written")
    }

    /// Skirts hang from the borders shared with other chunks, deep enough to cover the gap between
    /// a full-detail border and a coarse neighbor's straight edge along it.
    @Test func skirtsCoverCracksBetweenLevels() {
        var t = Terrain.generated(size: Vec2(32, 32), resolution: 33, seed: 9)
        t.chunkCells = 8
        t.lods = 3
        let plain = t.chunkMesh(1, 1, lod: 1)
        let depth = t.skirtDepth(1, 1)
        #expect(depth > 0)
        let skirted = t.chunkMesh(1, 1, lod: 1, skirt: depth)
        // An inner chunk has four neighbors: four strips of 5 vertices (8 cells at every 2nd sample).
        #expect(skirted.vertices.count == plain.vertices.count + 4 * 5)
        #expect(skirted.indices.count == plain.indices.count + 4 * 4 * 12, "both faces of every strip quad")
        #expect(skirted.vertices[plain.vertices.count].position.y == plain.vertices[0].position.y - depth)
        // A corner chunk only hangs skirts toward its two neighbors.
        #expect(t.chunkMesh(0, 0, lod: 1, skirt: depth).vertices.count == t.chunkMesh(0, 0, lod: 1).vertices.count + 2 * 5)
        // Along the border with chunk (1, 0), the coarse edge's skirt bottom stays under the full-detail heights.
        let range = t.chunkRange(1, 1)
        for lod in 1..<3 {
            let step = 1 << lod
            for x in stride(from: range.x.lowerBound, to: range.x.upperBound, by: step) {
                let z = range.z.lowerBound
                let a = t.height(x: x, z: z), b = t.height(x: x + step, z: z)
                for i in 0...step {
                    let edge = a + (b - a) * Float(i) / Float(step)
                    #expect(edge - depth < t.height(x: x + i, z: z) && t.height(x: x + i, z: z) - depth < edge)
                }
            }
        }
        // Tangents follow +x along the surface.
        let v = t.chunkMesh(0, 0).vertices[10]
        #expect(v.tangent.w == 1 && abs(dot(Vec3(v.tangent.x, v.tangent.y, v.tangent.z), v.normal)) < 1e-4 && v.tangent.x > 0)
    }

    /// The renderer draws a `MeshLOD`'s level by distance from the viewpoint, and its low-quality
    /// material on low quality, the same on Metal and on Vulkan.
    @MainActor @Test func lodSwapsMeshesWhenRenderedOnEveryBackend() throws {
        // A small quad in the plane's corner: drawing it leaves the center empty.
        var corner = MeshGeometry(vertices: [], indices: [0, 2, 1, 1, 2, 3])
        for (x, z) in [(0.4, 0.4), (0.5, 0.4), (0.4, 0.5), (0.5, 0.5)] as [(Float, Float)] {
            corner.vertices.append(MeshVertex(position: Vec3(x, 0, z), normal: Vec3(0, 1, 0)))
        }
        var results: [String: [String: [UInt8]]] = [:]
        for quality in [RenderQuality.high, .low] {
            try TestDevices.forEachBackend { device, frames in
                let renderer = try SceneRenderer(device: device, quality: quality)
                let target = try RenderTarget(device: device, width: 32, height: 32, multisampled: false)
                _ = try renderer.registerMesh(corner, key: "TerrainTests.corner")
                _ = try renderer.registerMaterial(Material(baseColor: Vec4(0, 0, 0, 1), roughness: 1, emissiveColor: Vec3(1, 0, 0)), key: "TerrainTests.red")
                _ = try renderer.registerMaterial(Material(baseColor: Vec4(0, 0, 0, 1), roughness: 1, emissiveColor: Vec3(0, 1, 0)), key: "TerrainTests.green")
                let view = SceneView(view: Mat4.lookAt(eye: Vec3(0, 0, 3), target: .zero),
                                     projection: Mat4.perspective(fovY: 0.6, aspect: 1, near: 0.1, far: 10))
                @MainActor func center(_ lod: MeshLOD) throws -> (pixel: [UInt8], level: Int?) {
                    let world = World()
                    let entity = world.spawn(Transform(rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(4, 1, 4)),
                                             MeshRenderer(mesh: .plane, material: MaterialHandle("TerrainTests.red")), lod)
                    world.propagateTransforms()
                    var pixels: Image?
                    try frames.run { frame in
                        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
                        renderer.renderView(view, into: target, frame: frame)
                        device.readBack(target.gpu) { pixels = $0 }
                    }
                    let image = try #require(pixels)
                    let i = (16 * image.width + 16) * 4
                    return (Array(image.pixels[i..<i + 4]), renderer.prep.lodLevel(of: entity))
                }
                let meshes = [MeshHandle("TerrainTests.corner")]
                let near = try center(MeshLOD(meshes: meshes, distances: [100]))
                let far = try center(MeshLOD(meshes: meshes, distances: [1]))
                let unloaded = try center(MeshLOD(meshes: [MeshHandle("TerrainTests.missing")], distances: [1]))
                let low = try center(MeshLOD(meshes: meshes, distances: [100], lowQualityMaterial: MaterialHandle("TerrainTests.green")))
                #expect(near.level == 0 && far.level == 1 && unloaded.level == 0, "\(device.backend)")
                results["\(device.backend) \(quality)"] = ["near": near.pixel, "far": far.pixel, "unloaded": unloaded.pixel, "low": low.pixel]
            }
        }
        for (label, colors) in results {
            let near = colors["near"]!, far = colors["far"]!, unloaded = colors["unloaded"]!, low = colors["low"]!
            #expect(near[0] > 200 && near[1] < 30, "level 0 is the plane, \(label): \(colors)")
            #expect(far[0] < 30, "level 1 is the corner quad, \(label): \(colors)")
            #expect(unloaded == near, "a level that isn't loaded keeps level 0, \(label)")
            if label.hasSuffix("low") {
                #expect(low[1] > 200 && low[0] < 30, "the low-quality material, \(label): \(colors)")
            } else {
                #expect(low == near, "\(label)")
            }
        }
        #if ENGINE_VULKAN && canImport(Metal)
        #expect(results.keys.contains("vulkan high") && results.keys.contains("metal high"), "both backends ran")
        #endif
        for quality in ["high", "low"] {
            if let metal = results["metal \(quality)"], let vulkan = results["vulkan \(quality)"] {
                for (name, color) in metal {
                    #expect(zip(color, vulkan[name]!).allSatisfy { abs(Int($0) - Int($1)) <= 3 }, "\(name) \(quality): metal \(color) vulkan \(vulkan[name]!)")
                }
            }
        }
    }

    // MARK: Per-pixel layers

    @Test func splatValuesAndAtlasesPackTheLayers() {
        var t = flat(9, size: 8)
        t.layers = [TerrainLayer(name: "A", color: Vec3(1, 0, 0), tileSize: 2), TerrainLayer(name: "B", color: Vec3(0, 0, 1), tileSize: 4)]
        t.normalizeData()
        t.paint(layer: 1, at: [Vec2(4, 0)], radius: 1.5, strength: 1)
        let splat = t.splatImage(firstLayer: 0)
        #expect(splat.width == 9 && splat.height == 9)
        let edge = (4 * 9 + 8) * 4, center = (4 * 9 + 4) * 4
        #expect(splat.pixels[edge + 1] > 200 && splat.pixels[center] == 255 && splat.pixels[center + 2] == 0 && splat.pixels[center + 3] == 0)
        let s = TerrainSplat(tileSizes: [2, 4], normalLayers: [false, true], size: Vec2(8, 8), resolution: 9, cellSize: 16)
        let v = s.values(metallic: 0, roughness: 0.9, normalScale: 1)
        #expect(v[0] == Vec4(2, 2, 8.0 / 9, 0.5 / 9) && v[2] == Vec4(0, 4, 1, 16) && v[3] == Vec4(0.5, 0.25, 1, 1))
        let gray = Image(width: 2, height: 1, pixels: [0, 0, 0, 255, 255, 255, 255, 255])
        let atlas = TerrainSplat.atlas(images: [nil, gray], colors: [Vec3(1, 0, 0), .zero], cellSize: 16)
        #expect(atlas.width == 64 && atlas.height == 16)
        #expect(Array(atlas.pixels[0..<3]) == [255, 0, 0], "a flat color cell")
        let left = (8 * 64 + 16 + 4) * 4, right = (8 * 64 + 16 + 12) * 4
        #expect(atlas.pixels[left] < 60 && atlas.pixels[right] > 195, "the image resampled into its cell")
        #expect(TerrainSplat.cellSize(for: [gray, nil]) == 16 && TerrainSplat.cellSize(for: []) == 64)
        #expect(TerrainSplat.cellSize(for: [Image(width: 300, height: 2, pixels: [UInt8](repeating: 0, count: 2400))]) == 512)
        let layer = TerrainLayer(name: "N", normalMap: "Textures/n.png")
        #expect(try! JSONDecoder().decode(TerrainLayer.self, from: JSONEncoder().encode(layer)) == layer)
        #expect(!String(decoding: try! JSONEncoder().encode(TerrainLayer()), as: UTF8.self).contains("normalMap"))
    }

    /// An imported terrain blends its layers per pixel (flat color, image, image with a normal map)
    /// on Metal and on Vulkan, alike, and draws the baked albedo on low quality.
    @MainActor @Test func layersBlendPerPixelOnEveryBackend() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let blue = Image(width: 4, height: 4, pixels: [UInt8](repeating: 0, count: 64).enumerated().map { $0.offset % 4 >= 2 ? 255 : 0 })
        // Tilted toward +U (+x on the terrain): (0.7, 0, 0.7).
        let tilted = Image(width: 4, height: 4, pixels: (0..<64).map { [217, 128, 217, 255][$0 % 4] })
        try FileManager.default.createDirectory(at: project.assetsURL.appendingPathComponent("Textures"), withIntermediateDirectories: true)
        try blue.pngData().write(to: project.assetsURL.appendingPathComponent("Textures/blue.png"))
        try tilted.pngData().write(to: project.assetsURL.appendingPathComponent("Textures/tilted.png"))
        database.refresh()
        var terrain = flat(9, size: 8, height: 0)
        terrain.collider = false
        terrain.layers = [TerrainLayer(name: "Red", color: Vec3(1, 0, 0)),
                          TerrainLayer(name: "Blue", color: Vec3(0, 1, 0), texture: "Textures/blue.png", tileSize: 2),
                          TerrainLayer(name: "Bumpy", color: Vec3(0, 1, 0), texture: "Textures/blue.png", tileSize: 2,
                                       normalMap: "Textures/tilted.png")]
        terrain.normalizeData()
        // Columns 0-2 red, 3-5 blue, 6-8 bumpy.
        terrain.splatData = (0..<3).map { layer in (0..<81).map { i in (i % 9) / 3 == layer ? 255 : 0 } }
        let id = try database.createTerrain(terrain, at: "Maps/splat.terrain")
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        let names = Set(record.objects.map(\.id))
        #expect(names.isSuperset(of: ["texture/layers", "texture/layer normals", "texture/splat 0", "material/terrain baked"]))
        #expect(!names.contains("texture/splat 1"), "three layers fit in one splat texture")
        let prefab = try #require(database.prefab(AssetReference(id)))
        #expect(prefab.roots[0].children[0].lod?.lowQualityMaterial?.key == AssetReference(id, subAsset: "material/terrain baked").description)

        let view = SceneView(view: Mat4.lookAt(eye: Vec3(0, 7, 4), target: .zero),
                             projection: Mat4.perspective(fovY: 0.9, aspect: 1, near: 0.1, far: 30))
        func pixel(_ p: Vec3) -> (Int, Int) {
            let c = view.viewProjection * Vec4(p.x, p.y, p.z, 1)
            return (Int((c.x / c.w * 0.5 + 0.5) * 32), Int((0.5 - c.y / c.w * 0.5) * 32))
        }
        let spots = ["red": pixel(Vec3(-3, 0, 0)), "blue": pixel(Vec3(0, 0, 0)), "bumpy": pixel(Vec3(3, 0, 0))]
        var results: [String: [String: [UInt8]]] = [:]
        for quality in [RenderQuality.high, .low] {
            try TestDevices.forEachBackend { device, frames in
                let renderer = try SceneRenderer(device: device, quality: quality)
                renderer.assets = database
                renderer.blocksOnAssetLoading = true
                let target = try RenderTarget(device: device, width: 32, height: 32, multisampled: false)
                let world = World()
                // Light from +x and above: the tilted normals face it more.
                _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(1, 0.5, 0)))), DirectionalLight(intensity: 0.5))
                _ = world.instantiate(prefab)
                world.propagateTransforms()
                var pixels: Image?
                for _ in 0..<2 {  // the first frame loads the assets
                    try frames.run { frame in
                        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
                        renderer.renderView(view, into: target, frame: frame)
                        device.readBack(target.gpu) { pixels = $0 }
                    }
                }
                let image = try #require(pixels)
                var colors: [String: [UInt8]] = [:]
                for (name, (x, y)) in spots {
                    let i = (y * image.width + x) * 4
                    colors[name] = Array(image.pixels[i..<i + 3])
                }
                results["\(device.backend) \(quality)"] = colors
            }
        }
        for (label, colors) in results {
            let red = colors["red"]!, blue = colors["blue"]!, bumpy = colors["bumpy"]!
            #expect(red[0] > 2 * Int(red[2]) + 10 && red[0] > 40, "\(label): \(colors)")
            #expect(blue[2] > 2 * Int(blue[0]) + 10 && blue[2] > 40, "the image, not the layer's color, \(label): \(colors)")
            #expect(blue[1] < blue[2] / 2, "\(label): \(colors)")
            if label.hasSuffix("high") {
                #expect(Int(bumpy[2]) > Int(blue[2]) + 15, "the normal map faces the light, \(label): \(colors)")
            } else {
                #expect(abs(Int(bumpy[2]) - Int(blue[2])) <= 4, "the baked albedo has no normal maps, \(label): \(colors)")
            }
        }
        #if ENGINE_VULKAN && canImport(Metal)
        #expect(results.keys.contains("vulkan high") && results.keys.contains("metal high"), "both backends ran")
        #endif
        for quality in ["high", "low"] {
            if let metal = results["metal \(quality)"], let vulkan = results["vulkan \(quality)"] {
                for (name, color) in metal {
                    #expect(zip(color, vulkan[name]!).allSatisfy { abs(Int($0) - Int($1)) <= 3 }, "\(name) \(quality): metal \(color) vulkan \(vulkan[name]!)")
                }
            }
        }
    }

    // MARK: Graph material layers

    @Test func layerGraphsRepeatPerTileAndFollowTheMask() throws {
        let graph = try JSONDecoder().decode(MaterialGraph.self, from: Data(#"""
        {"nodes": [{"id": "n", "type": "noise", "scale": 4},
                   {"id": "u", "type": "uv", "scale": [2, 2]},
                   {"id": "s", "type": "scrollUV", "uv": "u"}],
         "output": {"baseColor": "n", "emissive": "s.x", "opacity": 0.5}}
        """#.utf8))
        let terrain = flat(9, size: 8)
        let mask = AssetReference(AssetID(high: 1, low: 2), subAsset: "texture/A mask")
        let g = TerrainImporter.layerGraph(graph, terrain: terrain, tileSize: 2, mask: mask)
        #expect(g.node("n")?["uv"] == .string("terrainUV"), "unlinked UVs read the terrain's repeats")
        #expect(g.node("terrainUV")?["scale"] == .array([.double(4), .double(4)]) && g.node("terrainUV")?["offset"] == .array([.double(-2), .double(-2)]))
        #expect(g.node("u")?.type == "math" && g.node("u")?["a"] == .string("uScaled") && g.node("uScaled")?["a"] == .string("terrainUV"))
        #expect(g.node("s")?["uv"] == .string("u"), "linked UVs stay linked")
        #expect(g.output["opacity"] == .string("terrainOpacity") && g.node("terrainOpacity")?["a"] == .double(0.5) || g.node("terrainOpacity")?["a"] == .int(0))
        #expect(g.node("terrainMask")?["texture"] == .string(mask.description))
        let compiled = MaterialGraphCompiler.compile(g)
        #expect(compiled.warnings.isEmpty, "\(compiled.warnings)")
        #expect(compiled.program?.textures == [mask])
        // Overlays are lifted along the normal; only chunks with paint get one.
        let lifted = TerrainImporter.overlayMesh(terrain, 0, 0, lod: 1)
        #expect(abs(lifted.vertices[0].position.y - terrain.chunkMesh(0, 0, lod: 1).vertices[0].position.y - 0.04) < 1e-5)
        var painted = terrain
        painted.splatData[1][0] = 255
        #expect(TerrainImporter.chunkHasWeight(painted, layer: 1, 0, 0) && !TerrainImporter.chunkHasWeight(painted, layer: 1, 0, 1))
        #expect(painted.splatImage(firstLayer: 0, skipping: [0]).pixels[4 * 40] == 0, "a skipped layer is left out")
    }

    /// A graph material layer draws where it's painted, on Metal and on Vulkan, alike.
    @MainActor @Test func graphLayerRendersOnEveryBackend() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try FileManager.default.createDirectory(at: project.assetsURL.appendingPathComponent("Materials"), withIntermediateDirectories: true)
        try Data(#"""
        {"shading": "pbr", "graph": {"nodes": [{"id": "c", "type": "color", "value": [0, 1, 0, 1]}],
                                     "output": {"baseColor": [0, 0, 0], "emissive": "c.rgb", "roughness": 1}}}
        """#.utf8).write(to: project.assetsURL.appendingPathComponent("Materials/glow.material"))
        database.refresh()
        var terrain = flat(9, size: 8, height: 0)
        terrain.collider = false
        terrain.lods = 2
        terrain.chunkCells = 4
        terrain.layers = [TerrainLayer(name: "Red", color: Vec3(1, 0, 0)),
                          TerrainLayer(name: "Glow", color: Vec3(0, 0, 1), material: "Materials/glow.material"),
                          TerrainLayer(name: "Lost", material: "Materials/none.material")]
        terrain.normalizeData()
        // Rows 0-3: columns 5-8 glow, column 4 half and half; red elsewhere.
        let glow: [UInt8] = (0..<81).map { i in i / 9 >= 4 ? 0 : i % 9 > 4 ? 255 : i % 9 == 4 ? 127 : 0 }
        terrain.splatData = [glow.map { 255 - $0 }, glow, [UInt8](repeating: 0, count: 81)]
        let id = try database.createTerrain(terrain, at: "Maps/glow.terrain")
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        let names = Set(record.objects.map(\.id))
        #expect(names.isSuperset(of: ["material/Glow layer", "texture/Glow mask", "mesh/chunk 1_0 Glow", "mesh/chunk 1_0 Glow lod1"]))
        #expect(names.contains("mesh/chunk 0_0 Glow"), "column 4 is shared with chunk 0_0")
        #expect(!names.contains("material/Lost layer") && !names.contains("mesh/chunk 0_1 Glow") && !names.contains("mesh/chunk 1_1 Glow"),
                "only painted chunks get an overlay")
        let prefab = try #require(database.prefab(AssetReference(id)))
        let chunk = try #require(prefab.roots[0].children.first { $0.name == "chunk 1_0" })
        #expect(chunk.children.map(\.name) == ["Glow"] && chunk.children[0].lod?.meshes.count == 1)

        let view = SceneView(view: Mat4.lookAt(eye: Vec3(0, 7, 4), target: .zero),
                             projection: Mat4.perspective(fovY: 0.9, aspect: 1, near: 0.1, far: 30))
        func pixel(_ p: Vec3) -> (Int, Int) {
            let c = view.viewProjection * Vec4(p.x, p.y, p.z, 1)
            return (Int((c.x / c.w * 0.5 + 0.5) * 32), Int((0.5 - c.y / c.w * 0.5) * 32))
        }
        let spots = ["red": pixel(Vec3(-2.5, 0, -2.5)), "glow": pixel(Vec3(2.5, 0, -2.5)), "edge": pixel(Vec3(0, 0, -2.5)),
                     "south": pixel(Vec3(2.5, 0, 2.5))]
        var results: [String: [String: [UInt8]]] = [:]
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .high)
            renderer.assets = database
            renderer.blocksOnAssetLoading = true
            let target = try RenderTarget(device: device, width: 32, height: 32, multisampled: false)
            let world = World()
            _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.3, 1, 0.2)))), DirectionalLight(intensity: 0.5))
            _ = world.instantiate(prefab)
            world.propagateTransforms()
            var pixels: Image?
            for _ in 0..<2 {
                try frames.run { frame in
                    renderer.beginViews(world: world, frame: frame, shadowFocus: view)
                    renderer.renderView(view, into: target, frame: frame)
                    device.readBack(target.gpu) { pixels = $0 }
                }
            }
            let image = try #require(pixels)
            var colors: [String: [UInt8]] = [:]
            for (name, (x, y)) in spots {
                let i = (y * image.width + x) * 4
                colors[name] = Array(image.pixels[i..<i + 3])
            }
            results["\(device.backend)"] = colors
        }
        #if ENGINE_VULKAN && canImport(Metal)
        #expect(results.keys.contains("vulkan") && results.keys.contains("metal"), "both backends ran")
        #endif
        for (label, colors) in results {
            let red = colors["red"]!, glow = colors["glow"]!, edge = colors["edge"]!
            #expect(red[0] > 2 * Int(red[1]) + 10 && red[0] > 40, "\(label): \(colors)")
            #expect(glow[1] > 200 && glow[0] < 60 && glow[2] < 60, "the graph's green, \(label): \(colors)")
            #expect(edge[0] > 40 && edge[1] > 100, "half and half, \(label): \(colors)")
            #expect(colors["south"]![0] > 40 && colors["south"]![1] < 60, "unpainted: red, \(label): \(colors)")
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] {
            for (name, color) in metal {
                #expect(zip(color, vulkan[name]!).allSatisfy { abs(Int($0) - Int($1)) <= 3 }, "\(name): metal \(color) vulkan \(vulkan[name]!)")
            }
        }
    }
}
