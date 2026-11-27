import Foundation
import Testing
@testable import Engine
@testable import EngineAssets
@testable import EngineCore
@testable import EngineGraphics
@testable import EngineScene
@testable import EngineBackends
#if canImport(QuartzCore)
import QuartzCore
#endif

// Web exports ship a pack per texture family (W2.6C): both families cooked from one project with
// the shared blobs compressed once, each pack an ordinary one any player reads, player.json listing
// them, the export options (both for the web, one family elsewhere), which family a GPU gets
// (`TextureFamily.choose`, mirrored by Web/loader.js's `pickTextureFamily`) and what a GPU that
// can't sample a format uploads instead (`TextureCodec.decodeForUpload`).

private func textureFamilyPacksFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TextureFamilyPacksTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func textureFamilyPacksWrite(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

/// A 64x64 image with gradients and a checker, so block compression has something to do.
private func textureFamilyPacksImage(seed: UInt8) -> Image {
    var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
    for y in 0..<64 {
        for x in 0..<64 {
            let i = (y * 64 + x) * 4
            pixels[i] = UInt8((x * 4) & 255) &+ seed
            pixels[i + 1] = UInt8((y * 4) & 255)
            pixels[i + 2] = (x / 8 + y / 8) % 2 == 0 ? 200 : 40
            pixels[i + 3] = 255
        }
    }
    return Image(width: 64, height: 64, pixels: pixels)
}

/// A normal map: a bumpy surface's unit normals.
private func textureFamilyPacksNormalMap() -> Image {
    var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
    for y in 0..<64 {
        for x in 0..<64 {
            let n = normalize(Vec3(sin(Float(x) * 0.3) * 0.4, cos(Float(y) * 0.2) * 0.4, 1))
            let i = (y * 64 + x) * 4
            for c in 0..<3 { pixels[i + c] = UInt8(((n[c] * 0.5 + 0.5) * 255).rounded()) }
            pixels[i + 3] = 255
        }
    }
    return Image(width: 64, height: 64, pixels: pixels)
}

private func textureFamilyPacksMeanDifference(_ a: [UInt8], _ b: [UInt8]) -> Double {
    Double(zip(a, b).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }) / Double(max(a.count, 1))
}

@MainActor @Suite struct TextureFamilyPacksTests {
    /// A project whose scene draws a quad with a color texture and a normal map.
    private func project() throws -> (database: AssetDatabase, root: URL, model: AssetID, color: AssetID, normal: AssetID) {
        let root = try textureFamilyPacksFolder().appendingPathComponent("FamilyGame")
        let project = try Project.create(at: root)
        let obj = "o Quad\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nf 1/1 2/2 3/3 4/4\n"
        try textureFamilyPacksWrite(Data(obj.utf8), to: project.url(forAssetPath: "Models/quad.obj"))
        try textureFamilyPacksWrite(textureFamilyPacksImage(seed: 0).pngData(), to: project.url(forAssetPath: "Textures/color.png"))
        try textureFamilyPacksWrite(textureFamilyPacksNormalMap().pngData(), to: project.url(forAssetPath: "Textures/normal.png"))
        let database = AssetDatabase(project: project)
        database.scan()
        let model = database.id(forPath: "Models/quad.obj")!, color = database.id(forPath: "Textures/color.png")!
        let normal = database.id(forPath: "Textures/normal.png")!
        try database.setSettings(TextureImporter.Settings(sRGB: false, normalMap: true), for: normal)
        let material = try database.createMaterial(MaterialAsset(baseColor: Vec4(1, 1, 1, 1), texture: AssetReference(color),
                                                                 normalTexture: AssetReference(normal)),
                                                   at: "Materials/Quad.material")
        let world = World()
        _ = world.spawn(Transform(), Name("Quad"), MeshRenderer(mesh: MeshHandle(AssetReference(model, subAsset: "mesh/Quad")),
                                                                material: MaterialHandle(AssetReference(material))))
        try textureFamilyPacksWrite(try world.save(), to: project.url(forAssetPath: "Scenes/Main.scene"))
        database.scan()
        return (database, root, model, color, normal)
    }

    /// Both families from one project: ordinary packs (the format a native player reads) that
    /// differ only in their textures, the shared blobs compressed once.
    @Test func bothFamiliesCookFromOneProject() throws {
        let (database, root, model, color, normal) = try project()
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        let blobs = AssetPackFormat.PreparedBlobs()
        var packs: [TextureFamily: AssetPack] = [:]
        for family in CookPlatform.web.defaultTextureFamilies {
            var options = CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .web, textureFamily: family))
            options.packName = "Game.\(family.rawValue)"
            let report = try AssetCooker.plan(database: database, options: options).run(to: root.appendingPathComponent("out"), blobs: blobs)
            #expect(report.packPath.hasSuffix("Game.\(family.rawValue).pack"))
            #expect(report.storedTextureBytes > 0 && report.storedMeshBytes > 0)
            packs[family] = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        }
        let bc = try #require(packs[.bc]), astc = try #require(packs[.astc])
        #expect(bc.manifest.textureFamily == .bc && astc.manifest.textureFamily == .astc)
        #expect(bc.manifest.version == AssetPackManifest.currentVersion && astc.manifest.version == AssetPackManifest.currentVersion)
        #expect(bc.manifest.compressedTextureFormats == [.bc7Srgb: 1, .bc5Unorm: 1])
        #expect(astc.manifest.compressedTextureFormats == [.astc4x4Srgb: 1, .astc4x4RG: 1])
        // The same mesh blob, stored the same way, and the same scene.
        let meshBlobs = [bc, astc].map { pack in pack.entry(model)?.files.mapValues { [$0.hash, $0.encoding ?? "", "\($0.size)"] } }
        #expect(meshBlobs[0] != nil && meshBlobs[0] == meshBlobs[1])
        #expect(try bc.scene() == astc.scene())

        // Each family's textures, decoded as a GPU without the format gets them, look alike and like the source.
        let source = textureFamilyPacksImage(seed: 0).pixels
        var decodedColors: [[UInt8]] = []
        for pack in [bc, astc] {
            let assets = AssetDatabase(mounting: pack)
            let texture = try #require(assets.texture(AssetReference(color)))
            guard case .compressed(let format, let levels) = texture.pixels else { Issue.record("color not compressed"); continue }
            let decoded = try TextureCodec.decodeForUpload(levels, format: format)
            #expect(decoded.format == .rgba8Srgb && decoded.levels.count == levels.count)
            #expect(textureFamilyPacksMeanDifference(decoded.levels[0].pixels, source) < 3, "\(format)")
            decodedColors.append(decoded.levels[0].pixels)

            let normals = try #require(assets.texture(AssetReference(normal)))
            guard case .compressed(let normalFormat, let normalLevels) = normals.pixels else { Issue.record("normal map not compressed"); continue }
            let expanded = try TextureCodec.decodeForUpload(normalLevels, format: normalFormat)
            #expect(expanded.format == .rgba8Unorm)
            // Z rebuilt into blue, alpha opaque: the RGB normal map the mesh shader reads.
            #expect(textureFamilyPacksMeanDifference(expanded.levels[0].pixels, textureFamilyPacksNormalMap().pixels) < 3, "\(normalFormat)")
        }
        #expect(decodedColors.count == 2 && textureFamilyPacksMeanDifference(decodedColors[0], decodedColors[1]) < 3)

        #if os(macOS)
        // A player on Apple silicon samples either family as cooked (what it logs at startup).
        let device = try MetalRenderDevice(layer: CAMetalLayer(), sampleCount: 1)
        for pack in [bc, astc] where pack.manifest.compressedTextureFormats.keys.allSatisfy(device.supports) {
            let note = GamePlayer.textureSupportNote(pack.manifest, device: device)
            #expect(!note.decodes && note.message.contains("sampled as cooked"), "\(note.message)")
        }
        #endif
    }

    /// The web ships every family by default, one when asked; other platforms one.
    @Test func exportOptionsShipBothFamiliesForTheWebOnly() {
        func options(_ platform: CookPlatform, family: TextureFamily? = nil, web: [TextureFamily]? = nil) -> GameExportOptions {
            var options = GameExportOptions(name: "G", gameTarget: "G", gamePackage: URL(fileURLWithPath: "/tmp"),
                                            enginePackage: URL(fileURLWithPath: "/tmp"), output: URL(fileURLWithPath: "/tmp"),
                                            cook: CookOptions(scenes: ["a.scene"], target: CookTarget(platform: platform, textureFamily: family)))
            options.webTextureFamilies = web
            return options
        }
        #expect(options(.web).textureFamilies == [.bc, .astc])
        #expect(options(.web, web: [.astc, .bc]).textureFamilies == [.bc, .astc])
        #expect(options(.web, web: [.astc]).textureFamilies == [.astc])
        #expect(options(.linux).textureFamilies == [.bc])
        #expect(options(.macos).textureFamilies == [.astc])
        #expect(options(.macos, family: .bc, web: [.astc]).textureFamilies == [.bc])
        #expect(CookPlatform.web.defaultTextureFamilies == [.bc, .astc] && CookPlatform.windows.defaultTextureFamilies == [.bc])
    }

    /// A multi-family export's folder: game.<family>.pack each, listed in player.json's `packs`.
    @Test func playerConfigListsAPackPerFamily() throws {
        let folder = try textureFamilyPacksFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let packaged = folder.appendingPathComponent("Package", isDirectory: true)
        try textureFamilyPacksWrite(Data("wasm".utf8), to: packaged.appendingPathComponent("G.wasm"))
        let shim = folder.appendingPathComponent("shim/dist", isDirectory: true)
        try textureFamilyPacksWrite(Data("export {}".utf8), to: shim.appendingPathComponent("index.js"))
        let resources = folder.appendingPathComponent("Resources", isDirectory: true)
        try textureFamilyPacksWrite(Data("wgsl".utf8), to: resources.appendingPathComponent("Shaders/ui.vert.wgsl"))
        var packs: [(family: TextureFamily, url: URL)] = []
        for (family, hash, padding) in [(TextureFamily.bc, "00000000000000bc", 20), (.astc, "000000000000a57c", 40)] {
            let url = folder.appendingPathComponent("G.\(family.rawValue).pack")
            try textureFamilyPacksWrite(Data(("SGEPACK\0" + String(repeating: "\u{1}", count: 24) + hash + String(repeating: " ", count: padding)).utf8), to: url)
            packs.append((family, url))
        }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let site = folder.appendingPathComponent("Site", isDirectory: true)
        try GameExporter.assembleWebSite(at: site, inputs: WebSiteInputs(page: root.appendingPathComponent("Web"), packaged: packaged, wasiShim: shim,
                                                                          engineResources: resources, pack: packs[0].url, familyPacks: packs),
                                         wasmName: "G.wasm", packName: "G.pack", gameName: "G")
        let fm = FileManager.default
        #expect(fm.fileExists(atPath: site.appendingPathComponent("game.bc.pack").path))
        #expect(fm.fileExists(atPath: site.appendingPathComponent("game.astc.pack").path))
        #expect(!fm.fileExists(atPath: site.appendingPathComponent("game.pack").path))
        let config = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: site.appendingPathComponent("player.json"))) as? [String: Any])
        let listed = try #require(config["packs"] as? [String: [String: Any]])
        #expect(Set(listed.keys) == ["bc", "astc"])
        #expect(listed["bc"]?["file"] as? String == "game.bc.pack" && listed["bc"]?["size"] as? Int == 68 && listed["bc"]?["hash"] as? String == "00000000000000bc")
        #expect(listed["astc"]?["file"] as? String == "game.astc.pack" && listed["astc"]?["size"] as? Int == 88
                && listed["astc"]?["hash"] as? String == "000000000000a57c")
        // A loader that knows one pack gets the first family's.
        #expect(config["pack"] as? String == "game.bc.pack" && config["packSize"] as? Int == 68 && config["packHash"] as? String == "00000000000000bc")
        // The page picks one (Web/loader.js).
        let loader = try String(contentsOf: site.appendingPathComponent("loader.js"), encoding: .utf8)
        #expect(loader.contains("function pickTextureFamily") && loader.contains("config.packs"))
    }

    /// Which family a GPU gets, and which of its formats are decoded: the rule Web/loader.js mirrors.
    @Test func choosesTheFamilyTheGPUSamples() {
        func choose(_ sampled: Set<TextureFormat>, from available: [TextureFamily] = TextureFamily.allCases) -> (TextureFamily, [TextureFormat]) {
            let result = TextureFamily.choose(from: available) { !$0.isCompressed || sampled.contains($0) }
            return (result.family, result.decoded)
        }
        let bc: Set<TextureFormat> = [.bc7Srgb, .bc7Unorm, .bc5Unorm, .bc6hUfloat]
        let astc: Set<TextureFormat> = [.astc4x4Srgb, .astc4x4Unorm, .astc4x4RG]
        // WebGPU on Apple silicon: both (no ASTC HDR on WebGPU): BC, nothing decoded.
        #expect(choose(bc.union(astc)) == (.bc, []))
        // Native Metal: both, ASTC HDR too: BC first on a tie.
        #expect(choose(bc.union(astc).union([.astc4x4HDR])) == (.bc, []))
        // A desktop GPU, and a phone (WebGPU on Android).
        #expect(choose(bc) == (.bc, []))
        #expect(choose(astc) == (.astc, [.astc4x4HDR]))
        // WebGL 2 with BPTC but no RGTC: ASTC when it has it, else BC with its normal maps decoded.
        #expect(choose(Set<TextureFormat>([.bc7Srgb, .bc7Unorm, .bc6hUfloat]).union(astc)) == (.astc, [.astc4x4HDR]))
        #expect(choose([.bc7Srgb, .bc7Unorm, .bc6hUfloat]) == (.bc, [.bc5Unorm]))
        // Neither: BC, all decoded (BC7 decodes faster than ASTC).
        #expect(choose([]) == (.bc, [.bc7Srgb, .bc7Unorm, .bc5Unorm, .bc6hUfloat]))
        // Only what the export has.
        #expect(choose(bc, from: [.astc]) == (.astc, [.astc4x4Srgb, .astc4x4Unorm, .astc4x4RG, .astc4x4HDR]))
        #expect(choose(astc, from: [.bc]).0 == .bc)
    }

    /// What a GPU without a format gets instead, for every format a pack can hold.
    @Test func decodeFallbackForEveryFormat() throws {
        let image = textureFamilyPacksImage(seed: 30)
        for family in TextureFamily.allCases {
            for format in family.formats {
                let levels: [TextureMipLevel]
                if format.isHDR {
                    let float = FloatImage(width: 64, height: 64, pixels: image.pixels.map { Float($0) / 64 })
                    levels = try TextureCodec.encode(float, format: format, quality: .fast)
                } else {
                    levels = try TextureCodec.encode(image, format: format, quality: .fast)
                }
                let decoded = try TextureCodec.decodeForUpload(levels, format: format)
                #expect(decoded.format == (format.isHDR ? .rgba16Float : format.isSRGB ? .rgba8Srgb : .rgba8Unorm), "\(format)")
                #expect(decoded.levels.count == levels.count, "\(format)")
                for (level, original) in zip(decoded.levels, levels) {
                    #expect(level.width == original.width && level.height == original.height)
                    #expect(level.pixels.count == level.width * level.height * (format.isHDR ? 8 : 4), "\(format)")
                }
            }
        }
    }
}
