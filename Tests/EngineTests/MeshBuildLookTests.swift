import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild

// Mesh build looks (generated surface textures), their mapping and baked ambient occlusion.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildLookTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MeshBuildLook")
}

@MainActor private func importBuild(_ build: MeshBuild, _ body: (AssetDatabase, AssetID) throws -> Void) throws {
    let project = try makeProject()
    defer { try? FileManager.default.removeItem(at: project.root) }
    let database = AssetDatabase(project: project)
    let id = try database.createMeshBuild(build, at: "Models/model.meshbuild")
    database.refreshAsync()
    database.waitForAll()
    try body(database, id)
}

/// The prefab node named `name` (depth first).
private func node(_ name: String, in nodes: [PrefabNode]) -> PrefabNode? {
    for n in nodes {
        if n.name == name { return n }
        if let found = node(name, in: n.children) { return found }
    }
    return nil
}

@Suite(.serialized) struct MeshBuildLookTests {
    @Test func everyLookMakesItsTexturesInTheirFormats() {
        for look in MeshBuildLook.allCases {
            let t = MeshBuildLookTextures.generate(look, wearLevel: 0, resolution: 32)
            for image in [t.albedo, t.normal, t.orm] {
                #expect(image.width == 32 && image.height == 32 && image.pixels.count == 32 * 32 * 4, "\(look)")
            }
            // Normals point out of the surface (Z up, stored 0.5 + z / 2).
            #expect(stride(from: 2, to: t.normal.pixels.count, by: 4).allSatisfy { t.normal.pixels[$0] >= 128 }, "\(look)")
            // The albedo averages about 0.5 linear (sRGB ~188) before wear.
            var sum = 0.0
            for i in stride(from: 0, to: t.albedo.pixels.count, by: 4) {
                let c = Double(t.albedo.pixels[i + 1]) / 255
                sum += c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            let mean = sum / Double(32 * 32)
            #expect(abs(mean - 0.5) < 0.12, "\(look): mean \(mean)")
            #expect(t.averageColor.x > 0 && t.averageColor.x <= 1.05, "\(look)")
        }
        // Metals are metallic, the rest aren't.
        let gold = MeshBuildLookTextures.generate(.gold, wearLevel: 0, resolution: 16)
        let wood = MeshBuildLookTextures.generate(.wood, wearLevel: 0, resolution: 16)
        #expect(gold.orm.pixels[2] == 255 && wood.orm.pixels[2] == 0)
    }

    @Test func generationIsDeterministicAndWearChangesIt() {
        let a = MeshBuildLookTextures.generate(.rustyMetal, wearLevel: 2, resolution: 48)
        let b = MeshBuildLookTextures.generate(.rustyMetal, wearLevel: 2, resolution: 48)
        #expect(a.albedo.pixels == b.albedo.pixels && a.normal.pixels == b.normal.pixels && a.orm.pixels == b.orm.pixels)
        let clean = MeshBuildLookTextures.generate(.paintedMetal, wearLevel: 0, resolution: 48)
        let worn = MeshBuildLookTextures.generate(.paintedMetal, wearLevel: 4, resolution: 48)
        #expect(clean.albedo.pixels != worn.albedo.pixels)
        #expect(MeshBuildLookTextures.wearLevel(nil) == 0 && MeshBuildLookTextures.wearLevel(1) == 4 && MeshBuildLookTextures.wearLevel(0.3) == 1)
    }

    @Test func texturesAreGeneratedOncePerLookWearAndResolution() {
        let before = MeshBuildLookTextures.generations
        let first = MeshBuildLookTextures.textures(.brick, wearLevel: 1, resolution: 24)
        let second = MeshBuildLookTextures.textures(.brick, wearLevel: 1, resolution: 24)
        #expect(MeshBuildLookTextures.generations == before + 1)
        #expect(first.albedo.pixels == second.albedo.pixels)
        _ = MeshBuildLookTextures.textures(.brick, wearLevel: 1, resolution: 28)
        #expect(MeshBuildLookTextures.generations == before + 2, "another resolution is another set")
    }

    @Test func lookNamesAreLenientAndUnknownOnesWarn() {
        #expect(MeshBuildLook.named("Painted Metal") == .paintedMetal && MeshBuildLook.named("rusty-metal") == .rustyMetal)
        #expect(MeshBuildLook.named("ground") == .dirt && MeshBuildLook.named("unobtainium") == nil)
        let part = MeshBuildPart(look: "marble")
        let warning = part.lookWarnings.first ?? ""
        #expect(warning.contains("unknown look 'marble'") && warning.contains("rustyMetal") && warning.contains("cobblestone"))
        #expect(MeshBuildPart(look: "wood", lookScale: 0.5, wear: 0.3).lookWarnings.isEmpty)
        #expect(MeshBuildPart(look: "wood", wear: 2).lookWarnings == ["wear must be between 0 and 1"])
        #expect(part.shapeWarnings.contains(warning), "reported with the shape warnings")
    }

    @Test func lookFieldsRoundTripAndAreLeftOutWhenUnset() throws {
        let part = MeshBuildPart(name: "Lid", look: "planks", lookScale: 0.8, wear: 0.5, grain: .z)
        let build = MeshBuild(parts: [part, MeshBuildPart(name: "Plain")], ao: false)
        let data = try build.fileData()
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: data) == build)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let parts = try #require(json["parts"] as? [[String: Any]])
        #expect(parts[0]["look"] as? String == "planks" && parts[0]["grain"] as? String == "z")
        #expect(parts[1]["look"] == nil && parts[1]["lookScale"] == nil && parts[1]["wear"] == nil && parts[1]["grain"] == nil)
        #expect(json["ao"] as? Bool == false)
        #expect(try MeshBuild.starter.fileData().range(of: Data("\"ao\"".utf8)) == nil)
        // Lenient: wrong types read as unset instead of failing the file.
        let loose = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(
            #"{"ao": "yes", "parts": [{"look": 3, "lookScale": "big", "wear": 0.25, "grain": "w"}]}"#.utf8))
        #expect(loose.ao == nil && loose.parts[0].look == nil && loose.parts[0].lookScale == nil && loose.parts[0].wear == 0.25
                && loose.parts[0].grain == nil)
    }

    @Test func lookScaleGivesWorldSizedCoordinatesAlongTheGrain() throws {
        // A 2 m plank and a 0.5 m block: the same 0.5 m tiles, the grain along their long side.
        for (size, scale) in [(Vec3(2, 0.1, 0.3), Float(0.5)), (Vec3(0.5, 0.2, 0.4), Float(0.25))] {
            let part = MeshBuildPart(name: "Plank", size: size, look: "wood", lookScale: scale)
            let g = part.applyingLookUVs(to: try #require(part.geometry()))
            // On the top face, U follows X (the grain) at 1 tile per `scale` meters.
            let top = g.vertices.filter { $0.normal.y > 0.9 }
            let us = top.map(\.uv.x), vs = top.map(\.uv.y)
            #expect(abs((us.max()! - us.min()!) - size.x / scale) < 1e-3, "\(size)")
            #expect(abs((vs.max()! - vs.min()!) - size.z / scale) < 1e-3, "\(size)")
        }
        // Grain along Z when asked.
        let turned = MeshBuildPart(size: Vec3(2, 0.1, 0.3), look: "wood", lookScale: 1, grain: .z)
        let top = turned.applyingLookUVs(to: try #require(turned.geometry())).vertices.filter { $0.normal.y > 0.9 }
        #expect(abs((top.map(\.uv.x).max()! - top.map(\.uv.x).min()!) - 0.3) < 1e-3)
        // A cylinder wraps a whole number of tiles around.
        let post = MeshBuildPart(shape: .cylinder, size: Vec3(0.3, 2, 0.3), look: "bark", lookScale: 0.4)
        let side = post.applyingLookUVs(to: try #require(post.geometry())).vertices.filter { abs($0.normal.y) < 0.5 }
        // Tiles per radian away from the seam: a whole number of tiles in a full turn.
        let away = side.filter { abs(atan2f($0.position.x, $0.position.z)) < 2.5 }
        let a0 = try #require(away.min { atan2f($0.position.x, $0.position.z) < atan2f($1.position.x, $1.position.z) })
        let a1 = try #require(away.max { atan2f($0.position.x, $0.position.z) < atan2f($1.position.x, $1.position.z) })
        let perTurn = (a1.uv.y - a0.uv.y) / (atan2f(a1.position.x, a1.position.z) - atan2f(a0.position.x, a0.position.z)) * 2 * .pi
        #expect(abs(perTurn - (Float.pi * 0.3 / 0.4).rounded()) < 1e-3, "\(perTurn)")
        #expect(abs((side.map(\.uv.x).max()! - side.map(\.uv.x).min()!) - 2 / 0.4) < 1e-3, "U runs up the post (grain Y)")
    }

    @MainActor @Test func importAddsLookTexturesOnceAndTintsTheMaterial() throws {
        let red = Vec3(0.8, 0.1, 0.1)
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Panel", position: Vec3(0, 0.5, 0), size: Vec3(1, 1, 0.05), color: red, look: "paintedMetal"),
            MeshBuildPart(name: "Panel 2", parent: "Panel", position: Vec3(0, 0, 0.05), size: Vec3(1, 1, 0.05), look: "painted metal"),
            MeshBuildPart(name: "Pane", parent: "Panel", position: Vec3(0, 0, -0.05), size: Vec3(0.5, 0.5, 0.05), look: "glass"),
        ])
        try importBuild(build) { database, id in
            let record = try #require(database.record(id))
            let textures = record.objects.filter { $0.kind == .texture }
            #expect(textures.count == 6, "two looks x albedo, normal, orm: \(textures.map(\.id))")
            let prefab = try #require(database.prefab(AssetReference(id)))
            let panel = try #require(node("Panel", in: prefab.roots).flatMap { $0.material }.flatMap { database.material($0) })
            let plain = try #require(node("Panel 2", in: prefab.roots).flatMap { $0.material }.flatMap { database.material($0) })
            let pane = try #require(node("Pane", in: prefab.roots).flatMap { $0.material }.flatMap { database.material($0) })
            let linear = MeshBuildColor.linear(fromSRGB: red)
            #expect(abs(panel.baseColor.x - linear.x * 2) < 1e-4 && abs(panel.baseColor.y - linear.y * 2) < 1e-4, "the color tints")
            let average = MeshBuildLookTextures.average(.paintedMetal).color
            #expect(abs(plain.baseColor.z - average.z * 2) < 1e-4, "the default color keeps the look's own")
            #expect(panel.texture == plain.texture && panel.normalTexture == plain.normalTexture, "one set per look")
            let albedo = try #require(panel.texture.flatMap { database.texture($0) })
            let normal = try #require(panel.normalTexture.flatMap { database.texture($0) })
            let orm = try #require(panel.metallicRoughnessTexture.flatMap { database.texture($0) })
            #expect(albedo.isSRGB && !normal.isSRGB && !orm.isSRGB, "the normal map and ORM are linear")
            #expect(panel.occlusionTexture == panel.metallicRoughnessTexture && panel.metallic == 1 && panel.roughness == 1)
            #expect(pane.alphaMode == .blend && pane.baseColor.w < 0.5, "glass is see-through")
        }
    }

    @MainActor @Test func bakedOcclusionDarkensWhereAPartTouches() throws {
        // A small box standing on a big slab: the slab's top darkens next to it, not at its corners.
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Slab", position: Vec3(0, 0.05, 0), size: Vec3(2, 0.1, 2)),
            MeshBuildPart(name: "Block", parent: "Slab", position: Vec3(0, 0.25, 0), size: Vec3(0.4, 0.4, 0.4)),
        ], ao: true)
        try importBuild(build) { database, id in
            let prefab = try #require(database.prefab(AssetReference(id)))
            let slab = try #require(node("Slab", in: prefab.roots)?.mesh.flatMap { database.mesh($0) })
            let top = slab.vertices.filter { $0.normal.y > 0.9 }
            let ao = { (v: MeshVertex) in abs(v.tangent.w) }
            let near = top.filter { max(abs($0.position.x), abs($0.position.z)) > 0.21 && max(abs($0.position.x), abs($0.position.z)) < 0.27 }
            let far = top.filter { abs($0.position.x) > 0.8 && abs($0.position.z) > 0.8 }
            #expect(!near.isEmpty && !far.isEmpty)
            let nearAO = near.map(ao).reduce(0, +) / Float(near.count), farAO = far.map(ao).reduce(0, +) / Float(far.count)
            #expect(nearAO < farAO - 0.15, "near \(nearAO), far \(farAO)")
            #expect(farAO > 0.9)
            #expect(slab.vertices.count > 24, "tessellated so the middle of a face can darken")
        }
        var off = build
        off.ao = false
        try importBuild(off) { database, id in
            let prefab = try #require(database.prefab(AssetReference(id)))
            let slab = try #require(node("Slab", in: prefab.roots)?.mesh.flatMap { database.mesh($0) })
            #expect(slab.vertices.count == 24 && slab.vertices.allSatisfy { $0.tangent.w == 0 }, "ao false leaves meshes as they were")
        }
    }

    /// Writes every look's textures (and a 2 x 2 tiling of its albedo) as PNGs to
    /// $MESHBUILD_LOOK_DUMP, with timings. Off unless the variable is set.
    @Test func dumpLooks() throws {
        guard let path = ProcessInfo.processInfo.environment["MESHBUILD_LOOK_DUMP"] else { return }
        let folder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let resolution = Int(ProcessInfo.processInfo.environment["MESHBUILD_LOOK_RES"] ?? "") ?? 512
        let wear = Int(ProcessInfo.processInfo.environment["MESHBUILD_LOOK_WEAR"] ?? "") ?? 0
        var report = ""
        for look in MeshBuildLook.allCases {
            let start = Date()
            let t = MeshBuildLookTextures.generate(look, wearLevel: wear, resolution: resolution)
            report += String(format: "%@ %d: %.0f ms\n", look.rawValue, resolution, Date().timeIntervalSince(start) * 1000)
            try t.albedo.writePNG(to: folder.appendingPathComponent("\(look.rawValue)-albedo.png"))
            try t.normal.writePNG(to: folder.appendingPathComponent("\(look.rawValue)-normal.png"))
            try t.orm.writePNG(to: folder.appendingPathComponent("\(look.rawValue)-orm.png"))
            // The look's own colors (albedo x 2 x its average), tiled 2 x 2.
            var color = [UInt8](repeating: 255, count: resolution * resolution * 16)
            for y in 0..<(resolution * 2) {
                for x in 0..<(resolution * 2) {
                    let s = ((y % resolution) * resolution + x % resolution) * 4, d = (y * resolution * 2 + x) * 4
                    for c in 0..<3 {
                        let v = Float(t.albedo.pixels[s + c]) / 255
                        let lin = v <= 0.04045 ? v / 12.92 : powf((v + 0.055) / 1.055, 2.4)
                        color[d + c] = MeshBuildLookTextures.srgbByte(lin * 2 * t.averageColor[c])
                    }
                }
            }
            try Image(width: resolution * 2, height: resolution * 2, pixels: color)
                .writePNG(to: folder.appendingPathComponent("\(look.rawValue)-color.png"))
        }
        try report.write(to: folder.appendingPathComponent("timings.txt"), atomically: true, encoding: .utf8)
        print(report)
    }
}
