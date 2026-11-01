import Foundation
import Testing
@testable import Engine

// ProceduralTexture rendering and the .proctex importer, and MeshArray expansion.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ProcTexTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "ProcTex")
}

@Suite struct ProceduralTextureTests {
    @Test func renderIsDeterministicAndSized() {
        let spec = ProceduralTexture(generator: .windowGrid, width: 64, height: 32, seed: 3, columns: 4, rows: 2)
        let a = spec.render(), b = spec.render()
        #expect(a.width == 64 && a.height == 32 && a.pixels.count == 64 * 32 * 4)
        #expect(a.pixels == b.pixels)
        var other = spec
        other.seed = 4
        #expect(other.render().pixels != a.pixels)
    }

    @Test func everyGeneratorRenders() {
        for generator in ProceduralTexture.Generator.allCases {
            let image = ProceduralTexture.preset(generator).render()
            #expect(image.pixels.count == image.width * image.height * 4, "\(generator)")
            #expect(Set(image.pixels).count > 1, "\(generator)")
        }
    }

    @Test func checkerAlternatesColors() {
        let image = ProceduralTexture.checker(width: 4, height: 4, columns: 2, rows: 2)
        func pixel(_ x: Int, _ y: Int) -> [UInt8] { Array(image.pixels[(y * 4 + x) * 4..<(y * 4 + x) * 4 + 4]) }
        #expect(pixel(0, 0) != pixel(2, 0))
        #expect(pixel(0, 0) == pixel(2, 2))
    }

    @Test func fileRoundTripWithDefaultsForMissingKeys() throws {
        var spec = ProceduralTexture(generator: .bricks, width: 16, height: 16)
        spec.columns = 3
        let decoded = try AssetJSON.decoder().decode(ProceduralTexture.self, from: spec.fileData())
        #expect(decoded == spec)
        let sparse = try AssetJSON.decoder().decode(ProceduralTexture.self, from: Data(#"{"generator": "stripes"}"#.utf8))
        #expect(sparse.generator == .stripes && sparse.width == ProceduralTexture().width)
    }

    @MainActor @Test func importsAsATextureAndReimportsOnWrite() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createProceduralTexture(ProceduralTexture(generator: .checker, width: 8, height: 8), at: "Tex/check.proctex")
        database.refreshAsync()
        database.waitForAll()
        #expect(database.record(id)?.importer == "proctex")
        #expect(database.proceduralTexture(of: id)?.generator == .checker)
        #expect(throws: (any Error).self) {
            try database.createProceduralTexture(ProceduralTexture(), at: "Tex/check.proctex")
        }
        let revision = database.revision(of: id)
        try database.writeProceduralTexture(ProceduralTexture(generator: .noise, width: 8, height: 8), to: id)
        database.refreshAsync()
        database.waitForAll()
        #expect(database.proceduralTexture(of: id)?.generator == .noise)
        #expect(database.revision(of: id) > revision)
    }
}

@Suite struct MeshArrayTests {
    @Test func placementsFillTheGrid() {
        let array = MeshArray(countX: 3, countY: 2, countZ: 2, spacing: Vec3(2, 3, 4))
        let placements = array.placements()
        #expect(placements.count == 12 && array.instanceCount == 12)
        #expect(placements.first?.offset == .zero)
        #expect(placements.last?.offset == Vec3(4, 3, 4))
    }

    @Test func centeredGridSumsToZero() {
        let placements = MeshArray(countX: 3, countY: 3, spacing: Vec3(1, 1, 1), centered: true).placements()
        let sum = placements.reduce(Vec3.zero) { $0 + $1.offset }
        #expect(abs(sum.x) < 1e-5 && abs(sum.y) < 1e-5 && abs(sum.z) < 1e-5)
    }

    @Test func offCopiesAreHiddenOrTintedDeterministically() {
        let hidden = MeshArray(countX: 20, countY: 20, seed: 5, offFraction: 0.5, offMode: .hidden)
        let count = hidden.placements().count
        #expect(count > 100 && count < 300)
        #expect(hidden.placements().count == count)
        var tinted = hidden
        tinted.offMode = .tinted
        #expect(tinted.placements().count == 400)
        #expect(tinted.placements().contains { $0.tint != Vec3(1, 1, 1) })
        var varied = MeshArray(countX: 4, countY: 4, seed: 1, tintVariation: 0.5)
        #expect(varied.placements().allSatisfy { $0.tint.x >= 0.5 && $0.tint.x <= 1 })
        varied.tintVariation = 0
        #expect(varied.placements().allSatisfy { $0.tint == Vec3(1, 1, 1) })
    }

    @Test func countsAreClampedToMaxInstances() {
        let array = MeshArray(countX: 4096, countY: 4096, countZ: 4096)
        #expect(array.instanceCount <= MeshArray.maxInstances && array.instanceCount > 0)
        #expect(MeshArray(countX: -3).instanceCount == 0)
    }

    @Test func offsetFollowsRotationIgnoringScale() {
        let model = Mat4.translation(Vec3(1, 0, 0)) * Mat4.rotation(angle: .pi / 2, axis: Vec3(0, 1, 0)) * Mat4.scale(Vec3(2, 2, 2))
        let moved = MeshArray.offset(model, by: Vec3(1, 0, 0))
        // Local +X points to world -Z after a quarter turn about Y.
        #expect(abs(moved.c3.x - 1) < 1e-5 && abs(moved.c3.z + 1) < 1e-5)
    }

    @Test func codableDefaultsMissingFields() throws {
        let decoded = try JSONDecoder().decode(MeshArray.self, from: Data(#"{"countX": 5}"#.utf8))
        #expect(decoded.countX == 5 && decoded.countY == 1 && decoded.offMode == .hidden)
    }
}
