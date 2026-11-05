import Foundation
import Testing
@testable import Engine

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
}
