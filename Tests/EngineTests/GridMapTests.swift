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

// Grid maps: painting, brushes, flood fill, auto-joining, placement transforms and the .gridmap importer.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("GridMapTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "GridMap")
}

private func library() -> GridMap {
    GridMap(cellSize: Vec3(2, 3, 2), pieces: GridMap.starterPieces(folder: "Pieces") + [
        GridPiece(name: "Table", asset: "Pieces/Crate.meshbuild", footprint: SIMD2(2, 1), layer: "props"),
    ])
}

private func approx(_ a: Vec3, _ b: Vec3, _ tolerance: Float = 1e-4) -> Bool {
    abs(a.x - b.x) < tolerance && abs(a.y - b.y) < tolerance && abs(a.z - b.z) < tolerance
}

@Suite struct GridMapTests {
    @Test func fileRoundTripsAndSparseFilesDecode() throws {
        var map = library()
        map.paint("Floor", at: [GridCoord(0, 0, 0), GridCoord(1, 0, 0)])
        map.paint("Wall Straight", at: [GridCoord(0, 0, 0)], rotation: 90, flipX: true)
        #expect(try AssetJSON.decoder().decode(GridMap.self, from: map.fileData()) == map)
        let sparse = try AssetJSON.decoder().decode(GridMap.self, from: Data("{}".utf8))
        #expect(sparse.cellSize == Vec3(2, 3, 2) && sparse.layers == GridMap.defaultLayers && sparse.cells.isEmpty)
        let cell = try AssetJSON.decoder().decode(GridCell.self, from: Data(#"{"at": [1, 2, 3], "piece": "Floor", "rotation": 450}"#.utf8))
        #expect(cell.at == GridCoord(1, 2, 3) && cell.rotation == 90 && !cell.flipX)
        let text = String(decoding: try AssetJSON.encode(GridCell(at: GridCoord(0, 0, 0), piece: "Floor")), as: UTF8.self)
        #expect(!text.contains("rotation") && !text.contains("flip"), "defaults are left out: \(text)")
    }

    @Test func paintReplacesOnItsLayerOnly() {
        var map = library()
        map.paint("Floor", at: [GridCoord(0, 0, 0)])
        map.paint("Crate", at: [GridCoord(0, 0, 0)])
        #expect(map.cells.count == 2, "floor and props layers")
        map.paint("Pillar", at: [GridCoord(0, 0, 0)])
        #expect(map.cells.count == 2 && map.cells.last?.piece == "Pillar", "the pillar replaces the crate on props")
        #expect(map.cellIndex(at: GridCoord(0, 0, 0), layer: "floor").map { map.cells[$0].piece } == "Floor")

        // A 2x1 table covers two cells and replaces what it overlaps; turned, it covers along z.
        map.paint("Crate", at: [GridCoord(1, 0, 0)])
        map.paint("Table", at: [GridCoord(0, 0, 0)])
        #expect(map.cells.filter { map.layer(of: $0) == "props" }.map(\.piece) == ["Table"])
        #expect(map.covered(by: map.cells.last!) == [GridCoord(0, 0, 0), GridCoord(1, 0, 0)])
        map.paint("Table", at: [GridCoord(5, 0, 5)], rotation: 90)
        #expect(map.covered(by: map.cells.last!) == [GridCoord(5, 0, 5), GridCoord(5, 0, 6)])

        // Erasing any covered cell removes the piece; a layer limits it.
        #expect(map.erase(at: [GridCoord(5, 0, 6)]) == 1)
        #expect(map.erase(at: [GridCoord(1, 0, 0)], layer: "floor") == 0)
        #expect(map.erase(at: [GridCoord(1, 0, 0)]) == 1)
        #expect(map.cells.map(\.piece) == ["Floor"])
        map.paint("Crate", at: [GridCoord(3, 1, 3)], layer: "walls")
        #expect(map.cells.last?.layer == "walls")
        #expect(map.floors == [0, 1])
    }

    @Test func brushShapes() {
        let line = GridMap.line(from: GridCoord(0, 2, 0), to: GridCoord(4, 9, 2))
        #expect(line.first == GridCoord(0, 2, 0) && line.last == GridCoord(4, 2, 2) && line.count == 5)
        #expect(Set(line.map(\.y)) == [2], "on the first cell's floor")
        #expect(GridMap.rectangle(from: GridCoord(2, 0, 2), to: GridCoord(0, 0, 0)).count == 9)
        #expect(GridMap.rectangle(from: GridCoord(0, 0, 0), to: GridCoord(3, 0, 3), outline: true).count == 12)
        #expect(GridMap.box(from: GridCoord(0, 0, 0), to: GridCoord(1, 2, 1)).count == 12)

        var map = library()
        map.paintRandom(["Crate", "Pillar"], at: GridMap.rectangle(from: GridCoord(0, 0, 0), to: GridCoord(9, 0, 9)), seed: 3, randomRotation: true)
        let pieces = Set(map.cells.map(\.piece)), turns = Set(map.cells.map(\.rotation))
        #expect(map.cells.count == 100 && pieces == ["Crate", "Pillar"] && turns.count > 1)
        var again = library()
        again.paintRandom(["Crate", "Pillar"], at: GridMap.rectangle(from: GridCoord(0, 0, 0), to: GridCoord(9, 0, 9)), seed: 3, randomRotation: true)
        #expect(again == map, "repeatable per seed")
    }

    @Test func floodFillStaysInsideWalls() throws {
        var map = library()
        map.paint("Wall", at: GridMap.rectangle(from: GridCoord(0, 0, 0), to: GridCoord(4, 0, 4), outline: true))
        let inside = try map.floodRegion(from: GridCoord(2, 0, 2), layer: "floor")
        #expect(inside.count == 9 && inside.allSatisfy { $0.x >= 1 && $0.x <= 3 && $0.z >= 1 && $0.z <= 3 })
        #expect(throws: GridMap.FillError.notEnclosed) { try map.floodRegion(from: GridCoord(9, 0, 9), layer: "floor") }
        #expect(throws: GridMap.FillError.notEnclosed) { try library().floodRegion(from: GridCoord(0, 0, 0), layer: "floor") }

        // From a painted cell it replaces the connected cells holding the same piece.
        map.paint("Floor", at: inside)
        map.paint("Crate", at: [GridCoord(2, 0, 2)], layer: "floor")
        let floors = try map.floodRegion(from: GridCoord(1, 0, 1), layer: "floor")
        #expect(floors.count == 8 && !floors.contains(GridCoord(2, 0, 2)))
    }

    @Test func joinShapesAndTurns() {
        func shape(_ mask: Int) -> (String, Int) {
            let (variant, turns) = GridMap.joinShape(mask)
            return (GridJoin(single: "single", end: "end", straight: "straight", corner: "corner", tee: "tee", cross: "cross")[keyPath: variant], turns)
        }
        // Bits: 0 +x, 1 -z, 2 -x, 3 +z.
        #expect(shape(0) == ("single", 0))
        #expect(shape(0b0001) == ("end", 0))
        #expect(shape(0b0100) == ("end", 2))
        #expect(shape(0b0101) == ("straight", 0))
        #expect(shape(0b1010) == ("straight", 1))
        #expect(shape(0b1001) == ("corner", 0))
        #expect(shape(0b0011) == ("corner", 1))
        #expect(shape(0b1101) == ("tee", 0))
        #expect(shape(0b1111) == ("cross", 0))

        // A quarter turn takes +x to -z, as the masks assume.
        let turned = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)) * Vec3(1, 0, 0)
        #expect(approx(turned, Vec3(0, 0, -1)))
    }

    @Test func autoJoiningWallsPickVariants() {
        var map = library()
        // An L: (0,0)-(2,0) along x, then (2,1)-(2,2) along +z.
        map.paint("Wall", at: [GridCoord(0, 0, 0), GridCoord(1, 0, 0), GridCoord(2, 0, 0), GridCoord(2, 0, 1), GridCoord(2, 0, 2)])
        map.paint("Wall", at: [GridCoord(8, 0, 8)])
        var warnings: [String] = []
        let placements = map.placements(warnings: &warnings)
        #expect(warnings.isEmpty)
        func at(_ x: Int, _ z: Int) -> (String, Int)? {
            placements.first { $0.cell.at == GridCoord(x, 0, z) }.map { (map.pieces[$0.piece].name, $0.turns) }
        }
        #expect(at(0, 0)! == ("Wall End", 0), "neighbor at +x")
        #expect(at(1, 0)! == ("Wall Straight", 0))
        #expect(at(2, 0)! == ("Wall Corner", 3), "neighbors at -x and +z")
        #expect(at(2, 1)! == ("Wall Straight", 1))
        #expect(at(2, 2)! == ("Wall End", 1), "neighbor at -z")
        #expect(at(8, 8)! == ("Wall Single", 0))

        // Other layers and floors don't join; unknown pieces are reported.
        map.paint("Wall", at: [GridCoord(1, 1, 0)])
        map.cells.append(GridCell(at: GridCoord(9, 0, 9), piece: "Ghost"))
        let more = map.placements(warnings: &warnings)
        #expect(more.first { $0.cell.at == GridCoord(1, 1, 0) }.map { map.pieces[$0.piece].name } == "Wall Single")
        #expect(warnings == ["no piece named 'Ghost' in the library"])
    }

    @Test func placementTransforms() {
        var map = library()
        map.pieces.append(GridPiece(name: "Offset", asset: "Pieces/Crate.meshbuild", offset: Vec3(0.5, 0, 0), rotation: 90))
        map.paint("Floor", at: [GridCoord(1, 2, -1)])
        map.paint("Table", at: [GridCoord(0, 0, 0)], rotation: 90)
        map.paint("Offset", at: [GridCoord(0, 0, 3)], rotation: 90)
        map.paint("Offset", at: [GridCoord(0, 1, 3)], flipX: true)
        map.paint("Offset", at: [GridCoord(0, 2, 3)], flipX: true, flipZ: true)
        var warnings: [String] = []
        let p = map.placements(warnings: &warnings)
        #expect(approx(map.transform(of: p[0]).position, Vec3(3, 6, -1)), "centered on the cell, on floor 2")
        #expect(approx(map.transform(of: p[1]).position, Vec3(1, 0, 2)), "a turned 2x1 table covers two cells along z")
        // The cell's quarter turn turns the pivot too: +x becomes -z.
        let turned = map.transform(of: p[2])
        #expect(approx(turned.position, Vec3(1, 0, 7 - 0.5)))
        #expect(approx(turned.rotation * Vec3(1, 0, 0), Vec3(-1, 0, 0)), "90 + 90 degrees")
        // Mirrored: the pivot's x and the model's own turn flip.
        #expect(p[3].mirrored && p[3].turns == 0)
        let mirrored = map.transform(of: p[3])
        #expect(approx(mirrored.position, Vec3(0.5, 3, 7)))
        #expect(approx(mirrored.rotation * Vec3(1, 0, 0), Vec3(0, 0, 1)), "-90 degrees")
        #expect(!p[4].mirrored && p[4].turns == 2, "both flips are a half turn")
        let box = map.box(of: p[1])
        #expect(approx(box.center, Vec3(1, 1.5, 2)) && approx(box.halfExtent, Vec3(2, 1.5, 1)))
        #expect(map.chunk(of: GridCoord(-1, 0, 16)) == SIMD2(-1, 1))
    }

    @Test func mirroredGeometryKeepsFrontFaces() {
        let cube = MeshGeometry.cube(size: 1)
        let flipped = GridMapImporter.mirrored(cube)
        for t in stride(from: 0, to: cube.indices.count, by: 3) {
            let v = flipped.vertices, i = flipped.indices
            let a = v[Int(i[t])].position, b = v[Int(i[t + 1])].position, c = v[Int(i[t + 2])].position
            #expect(dot(cross(b - a, c - a), v[Int(i[t])].normal) > 0, "counter-clockwise toward its normal")
        }
    }

    @Test func prefabSceneFilesBecomeNodes() throws {
        let mesh = "asset:00000000000000000000000000000001#mesh/Box"
        let json = """
            {"format": "Scene", "version": 2, "entities": [
              {"id": 0, "components": {"Name": {"value": "Root"}, "Transform": {"position": [1, 0, 0], "rotation": [0, 0, 0, 1], "scale": [1, 1, 1]}}},
              {"id": 1, "parent": 0, "components": {"Name": {"value": "Box"}, "MeshRenderer": {"mesh": "\(mesh)", "material": "asset:00000000000000000000000000000001#material"}}},
              {"id": 2, "parent": 0, "components": {"MeshRenderer": {"mesh": "cube"}}}
            ]}
            """
        let nodes = PieceLoader.sceneNodes(Data(json.utf8))
        #expect(nodes.count == 1 && nodes[0].name == "Root" && nodes[0].transform.position == Vec3(1, 0, 0))
        #expect(nodes[0].children.count == 2 && nodes[0].children[0].mesh?.description == mesh)
        #expect(nodes[0].children[1].mesh == nil, "built-in meshes aren't asset references")
    }

    @MainActor @Test func importsChunksCollidersMirrorsAndReloads() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        for (name, build) in GridMap.starterBuilds() { try database.createMeshBuild(build, at: "Pieces/\(name).meshbuild") }
        let objURL = project.url(forAssetPath: "Models/ramp.obj")
        try FileManager.default.createDirectory(at: objURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "v -1 0 -1\nv 1 0 -1\nv 1 1 1\nv -1 1 1\nf 1 2 3\nf 1 3 4\n".write(to: objURL, atomically: true, encoding: .utf8)
        database.refresh()

        var map = library()
        map.chunkSize = 4
        map.pieces += [GridPiece(name: "Ramp", asset: "Models/ramp.obj", layer: "props"),
                       GridPiece(name: "Lost", asset: "Pieces/nope.meshbuild")]
        map.paint("Floor", at: GridMap.rectangle(from: GridCoord(0, 0, 0), to: GridCoord(5, 0, 1)))
        map.paint("Wall", at: GridMap.line(from: GridCoord(0, 0, 2), to: GridCoord(5, 0, 2)))
        map.paint("Wall Corner", at: [GridCoord(0, 1, 0)], flipX: true)
        map.paint("Crate", at: [GridCoord(1, 0, 0), GridCoord(2, 0, 0)])
        map.paint("Ramp", at: [GridCoord(3, 0, 0)])
        map.paint("Lost", at: [GridCoord(4, 0, 0)])
        let id = try database.createGridMap(GridMap(), at: "Levels/dungeon.gridmap")
        let warnings = try database.writeGridMap(map, to: id)
        #expect(warnings.contains { $0.contains("'Lost'") }, "\(warnings)")
        let record = try #require(database.record(id))
        #expect(record.importer == "gridmap" && record.importError == nil)
        #expect(database.gridMap(of: id) == map)

        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(prefab.roots.first)
        #expect(root.name == "dungeon" && root.children.map(\.name) == ["Floor 0", "Floor 1"])
        let floor0 = root.children[0]
        #expect(floor0.children.map(\.name) == ["Chunk 0_0", "Chunk 1_0"], "chunks of 4 cells")
        #expect(floor0.children.allSatisfy { $0.collider != nil })
        let pieces = floor0.children.flatMap(\.children)
        #expect(!pieces.contains { $0.name.hasPrefix("Lost") }, "a missing asset is skipped")
        let floors = pieces.filter { $0.name.hasPrefix("Floor ") }
        #expect(floors.count == 11, "Lost replaced one tile on the floor layer")
        #expect(Set(floors.compactMap(\.mesh)).count == 1 && floors[0].children.isEmpty, "one shared mesh: drawn instanced")
        #expect(approx(floors[0].transform.position, Vec3(1, -0.1, 1)), "the tile's own offset is folded in")
        let walls = pieces.filter { $0.name.hasPrefix("Wall ") }
        #expect(walls.count == 6 && walls.allSatisfy { !$0.children.isEmpty || $0.mesh != nil })
        let crates = pieces.filter { $0.name.hasPrefix("Crate ") }
        #expect(crates.count == 2 && crates[0].mesh == crates[1].mesh)
        let ramp = try #require(pieces.first { $0.name.hasPrefix("Ramp ") })
        #expect(ramp.mesh?.asset == database.id(forPath: "Models/ramp.obj") || ramp.children.first?.mesh != nil, "an OBJ model as a piece")

        // The mirrored corner gets mirrored meshes of its own.
        #expect(record.objects.contains { $0.kind == .mesh && $0.id.contains("mirrored") })
        let corner = try #require(root.children[1].children.first?.children.first)
        func meshes(_ node: PrefabNode) -> [AssetReference] { (node.mesh.map { [$0] } ?? []) + node.children.flatMap(meshes) }
        #expect(meshes(corner).allSatisfy { $0.asset == id }, "mirrored meshes live in the grid map")

        // Colliders are merged triangles; the crate (box collider) adds 12.
        guard case .triangleMesh(let vertices, let indices)? = floor0.children[0].collider else {
            Issue.record("expected a triangle mesh collider")
            return
        }
        #expect(indices.count % 3 == 0 && indices.count >= 36 && vertices.count > 8)
        #expect(vertices.allSatisfy { $0.x >= -0.01 && $0.x <= 8.01 }, "chunk 0 spans cells 0...3")

        let world = World()
        #expect(world.instantiate(prefab).count == 1)
        #expect(world.count(of: Collider.self) == 3)

        // Hot reload: changing a piece's mesh build reimports the map.
        let before = database.revision(of: id)
        let floorID = try #require(database.id(forPath: "Pieces/Floor.meshbuild"))
        var floorBuild = try #require(database.meshBuild(of: floorID))
        floorBuild.parts[0].size = Vec3(2, 1, 2)
        try floorBuild.fileData().write(to: project.url(forAssetPath: "Pieces/Floor.meshbuild"), options: .atomic)
        database.refresh()
        #expect(database.revision(of: id) != before, "the map follows its pieces")
    }
}
