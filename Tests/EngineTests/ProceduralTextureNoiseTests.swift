import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild

// The .proctex noise generators (fbm, ridged, voronoi, cells, woodRings, streaks) and the
// companion normal map.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ProcTexNoiseTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "ProcTexNoise")
}

/// The mean absolute difference between two columns of `image` (RGB, 0...255).
private func columnDifference(_ image: Image, _ a: Int, _ b: Int) -> Double {
    var sum = 0.0
    for y in 0..<image.height {
        for c in 0..<3 {
            sum += abs(Double(image.pixels[(y * image.width + a) * 4 + c]) - Double(image.pixels[(y * image.width + b) * 4 + c]))
        }
    }
    return sum / Double(image.height * 3)
}

@Suite struct ProceduralTextureNoiseTests {
    static let noiseKinds: [ProceduralTexture.Generator] = [.fbm, .ridged, .voronoi, .cells, .woodRings, .streaks]

    @Test func noiseKindsRenderDeterministicallyAndTile() {
        for kind in Self.noiseKinds {
            var spec = ProceduralTexture.preset(kind)
            spec.width = 64
            spec.height = 64
            if kind == .streaks { spec.columns = 16 }
            let a = spec.render(), b = spec.render()
            #expect(a.pixels == b.pixels, "\(kind) is deterministic")
            #expect(Set(a.pixels).count > 8, "\(kind) has detail")
            // Seamless: the last column continues into the first about as smoothly as neighbors do.
            let seam = columnDifference(a, 63, 0), inside = (columnDifference(a, 31, 32) + columnDifference(a, 15, 16)) / 2
            #expect(seam <= inside * 3 + 6, "\(kind): seam \(seam), inside \(inside)")
            var other = spec
            other.seed += 1
            #expect(other.render().pixels != a.pixels, "\(kind) follows the seed")
        }
    }

    @Test func normalMapComesFromHeight() {
        // Bricks: mortar lines are low, so the normal map leans away from them; elsewhere it is flat.
        let spec = ProceduralTexture(generator: .bricks, width: 64, height: 64, columns: 2, rows: 4, margin: 0.1, normalStrength: 2)
        let normal = spec.renderNormalMap()
        #expect(normal.width == 64 && normal.height == 64)
        let z = stride(from: 2, to: normal.pixels.count, by: 4).map { normal.pixels[$0] }
        #expect(z.allSatisfy { $0 >= 128 }, "normals face out")
        #expect(z.contains { $0 < 240 } && z.contains { $0 > 252 }, "bevels at the mortar, flat brick faces")
        var flat = spec
        flat.generator = .checker
        flat.colorA = Vec3(0.5, 0.5, 0.5)
        flat.colorB = Vec3(0.5, 0.5, 0.5)
        #expect(flat.renderNormalMap().pixels.enumerated().allSatisfy { i, v in i % 4 == 3 || abs(Int(v) - [128, 128, 255][i % 4]) <= 1 },
                "an even texture gives a flat normal map")
    }

    @Test func existingKindsAreUnchanged() {
        // A checker's tiles are exactly its colors, and noise kinds didn't change the old presets.
        let checker = ProceduralTexture(generator: .checker, width: 4, height: 4, colorA: Vec3(1, 0, 0), colorB: Vec3(0, 0, 1),
                                        columns: 2, rows: 2)
        let image = checker.render()
        #expect(Array(image.pixels[0..<4]) == [255, 0, 0, 255] && Array(image.pixels[8..<12]) == [0, 0, 255, 255])
        #expect(ProceduralTexture.preset(.bricks).normalStrength == 0)
        // An old file (no normalStrength) reads as before.
        let old = try? AssetJSON.decoder().decode(ProceduralTexture.self, from: Data(#"{"generator": "noise", "scale": 3}"#.utf8))
        #expect(old?.normalStrength == 0 && old?.scale == 3)
    }

    @MainActor @Test func importerAddsALinearNormalTexture() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var spec = ProceduralTexture.preset(.cells)
        spec.width = 32
        spec.height = 32
        let id = try database.createProceduralTexture(spec, at: "Textures/stones.proctex")
        let plain = try database.createProceduralTexture(ProceduralTexture(generator: .fbm, width: 16, height: 16), at: "Textures/plain.proctex")
        database.refreshAsync()
        database.waitForAll()
        let color = try #require(database.texture(AssetReference(id, subAsset: "texture")))
        let normal = try #require(database.texture(AssetReference(id, subAsset: "normal")))
        #expect(color.isSRGB && !normal.isSRGB)
        #expect(database.texture(AssetReference(id))?.isSRGB == true, "the color texture stays the default object")
        #expect(database.record(plain)?.objects.count == 1, "no normal map without normalStrength")
    }
}
