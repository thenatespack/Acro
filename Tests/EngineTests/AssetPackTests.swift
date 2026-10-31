import Foundation
import Testing
@testable import Engine

// Cooking projects into asset packs and mounting them (Sources/Engine/Packaging/): what goes in
// (references followed from the scenes, nothing else), shipping texture settings, determinism,
// reuse of Library and cook-cache imports, a mounted database with the project gone, damaged
// packs and unknown ids, and the player's startup pieces. Each test cooks its own project in a
// temporary folder.

private let quadOBJ = """
    o Quad
    v 0 0 0
    v 1 0 0
    v 1 1 0
    v 0 1 0
    vt 0 0
    vt 1 0
    vt 1 1
    vt 0 1
    f 1/1 2/2 3/3 4/4
    """

private func temporaryFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AssetPackTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func write(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

/// A 64x64 RGBA image with some structure, so block compression has something to do.
private func testImage(seed: UInt8) -> Image {
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

/// A mono 16-bit WAV of `frames` samples of a square wave.
private func testWAV(frames: Int = 800) -> Data {
    var data = Data("RIFF".utf8)
    func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    u32(UInt32(36 + frames * 2))
    data.append(contentsOf: Array("WAVEfmt ".utf8))
    u32(16); u16(1); u16(1); u32(8000); u32(16000); u16(2); u16(16)
    data.append(contentsOf: Array("data".utf8))
    u32(UInt32(frames * 2))
    for i in 0..<frames { u16(UInt16(bitPattern: (i / 20) % 2 == 0 ? 8000 : -8000)) }
    return data
}

/// A project: a model, a texture used by a material, a texture nothing uses, a sound, and a
/// scene with an entity drawing the model's mesh with the material.
@MainActor
private struct TestProject {
    let root: URL
    let database: AssetDatabase
    let model: AssetID
    let material: AssetID
    let texture: AssetID
    let unused: AssetID
    let sound: AssetID

    init(textureSettings: TextureImporter.Settings? = nil) throws {
        root = try temporaryFolder().appendingPathComponent("PackGame")
        let project = try Project.create(at: root)
        try write(Data(quadOBJ.utf8), to: project.url(forAssetPath: "Models/quad.obj"))
        try write(testImage(seed: 0).pngData(), to: project.url(forAssetPath: "Textures/bricks.png"))
        try write(testImage(seed: 90).pngData(), to: project.url(forAssetPath: "Textures/unused.png"))
        try write(testWAV(), to: project.url(forAssetPath: "Audio/beep.wav"))
        database = AssetDatabase(project: project)
        database.scan()
        model = database.id(forPath: "Models/quad.obj")!
        texture = database.id(forPath: "Textures/bricks.png")!
        unused = database.id(forPath: "Textures/unused.png")!
        sound = database.id(forPath: "Audio/beep.wav")!
        if let textureSettings { try database.setSettings(textureSettings, for: texture) }
        material = try database.createMaterial(MaterialAsset(baseColor: Vec4(1, 0.5, 0.25, 1), texture: AssetReference(texture)),
                                               at: "Materials/Bricks.material")
        let world = World()
        _ = world.spawn(Transform(position: Vec3(1, 2, 3)), Name("Quad"),
                        MeshRenderer(mesh: MeshHandle(AssetReference(model, subAsset: "mesh/Quad")), material: MaterialHandle(AssetReference(material))))
        try write(try world.save(), to: project.url(forAssetPath: "Scenes/Main.scene"))
        database.scan()
    }

    func cook(_ options: CookOptions = CookOptions(scenes: ["Scenes/Main.scene"]), to folder: String = "out") throws -> CookReport {
        try AssetCooker.plan(database: database, options: options).run(to: root.appendingPathComponent(folder))
    }
}

@MainActor @Suite struct AssetPackTests {
    @Test func cooksWhatTheScenesReferenceAndMountsIt() throws {
        let project = try TestProject()
        let report = try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], include: ["Audio/beep.wav"],
                                                  target: CookTarget(platform: .linux)))
        #expect(report.assetCount == 4)  // model, material, its texture, the included sound; not unused.png
        #expect(report.scenes == ["Scenes/Main.scene"])
        #expect(report.warnings.isEmpty)
        let pack = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        #expect(pack.manifest.platform == .linux && pack.manifest.textureFamily == .bc)
        #expect(Set(pack.manifest.assets.map(\.id)) == [project.model, project.material, project.texture, project.sound])
        #expect(!pack.contains(project.unused))
        // The table of contents lists every blob with offset, size and hash, aligned.
        for asset in pack.manifest.assets {
            for blob in Array(asset.files.values) + (asset.data.map { [$0] } ?? []) {
                #expect(blob.offset % UInt64(AssetPackFormat.alignment) == 0)
                #expect(blob.hash.count == 16)
            }
        }
        #expect(FileManager.default.fileExists(atPath: report.manifestPath!))

        let assets = AssetDatabase(mounting: pack)
        #expect(assets.isMounted)
        let mesh = try #require(assets.mesh(AssetReference(project.model, subAsset: "mesh/Quad")))
        #expect(mesh.indices.count == 6)
        let material = try #require(assets.material(AssetReference(project.material)))
        #expect(material.texture == AssetReference(project.texture))
        let texture = try #require(assets.texture(AssetReference(project.texture)))
        // Shipping settings: compressed for the target (BC7 for color on Linux), with mips.
        guard case .compressed(let format, let levels) = texture.pixels else { Issue.record("texture not compressed"); return }
        #expect(format == .bc7Srgb)
        #expect(levels.count == MipChain.levelCount(width: 64, height: 64))
        #expect(assets.loadState(of: project.texture) == .loaded)
        #expect(assets.path(of: project.material) == "Materials/Bricks.material")
        #expect(assets.revision(of: project.model) > 0)
        // The scene comes from the pack too.
        let world = World()
        try world.load(try pack.scene())
        #expect(world.count(of: MeshRenderer.self) == 1)
        // The sound is stored as is and plays from memory.
        #expect(try assets.fileData(of: project.sound) == testWAV())
        #expect(try assets.loadSound(project.sound).frameCount == 800)
    }

    @Test func astcTargetAndNormalMapsInTwoChannels() throws {
        let project = try TestProject(textureSettings: TextureImporter.Settings(sRGB: false, normalMap: true))
        let report = try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .macos)))
        let assets = AssetDatabase(mounting: try AssetPack(url: URL(fileURLWithPath: report.packPath)))
        #expect(assets.pack?.manifest.textureFamily == .astc)
        let texture = try #require(assets.texture(AssetReference(project.texture)))
        guard case .compressed(let format, _) = texture.pixels else { Issue.record("texture not compressed"); return }
        #expect(format == .astc4x4RG)
        // asImported leaves an uncompressed texture alone.
        let plain = try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .macos), textures: .asImported),
                                     to: "plain")
        let rgba = try AssetPack(url: URL(fileURLWithPath: plain.packPath)).asset(project.texture)
        guard case .texture(let t)? = rgba.objects.first?.value, case .rgba8 = t.pixels else { Issue.record("expected RGBA8"); return }
    }

    @Test func sameInputsGiveTheSameBytesAndReuseImports() throws {
        let project = try TestProject()
        let options = CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .linux))
        let first = try project.cook(options, to: "a")
        #expect(first.imported.contains("Textures/bricks.png"))  // compressed: not what the Library has
        let second = try project.cook(options, to: "b")
        #expect(second.imported.isEmpty)
        #expect(second.fromCookCache + second.fromLibrary == second.assetCount)
        // Without the cook cache the imports run again, with the same result.
        try FileManager.default.removeItem(at: project.root.appendingPathComponent("Library/Cooked"))
        let third = try project.cook(options, to: "c")
        #expect(!third.imported.isEmpty)
        let bytes = try [first, second, third].map { try Data(contentsOf: URL(fileURLWithPath: $0.packPath)) }
        #expect(bytes[0] == bytes[1] && bytes[1] == bytes[2])
        // Changing a source invalidates only that asset's cooked import.
        try testImage(seed: 7).pngData().write(to: project.root.appendingPathComponent("Assets/Textures/bricks.png"))
        project.database.scan()
        let fourth = try project.cook(options, to: "d")
        #expect(fourth.imported == ["Textures/bricks.png"])
        #expect(try Data(contentsOf: URL(fileURLWithPath: fourth.packPath)) != bytes[0])
    }

    @Test func libraryImportsWithShippingSettingsAreCopied() throws {
        // A texture the project already compresses for this machine's family: the Library's import is the shipping one.
        let project = try TestProject(textureSettings: TextureImporter.Settings(compression: .auto))
        project.database.refresh()
        let report = try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .current, textureFamily: .machine)))
        #expect(report.imported.isEmpty)
        #expect(report.fromLibrary == report.assetCount)
    }

    @Test func mountedPackNeedsNoProject() throws {
        let project = try TestProject()
        let report = try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], include: [project.sound.description]))
        // Move the pack out and delete the whole project: Assets/, Library/, sidecars.
        let elsewhere = try temporaryFolder().appendingPathComponent("Game.pack")
        try FileManager.default.moveItem(at: URL(fileURLWithPath: report.packPath), to: elsewhere)
        try FileManager.default.removeItem(at: project.root)
        let assets = AssetDatabase(mounting: try AssetPack(url: elsewhere))
        #expect(assets.mesh(AssetReference(project.model, subAsset: "mesh/Quad")) != nil)
        #expect(assets.texture(AssetReference(project.texture)) != nil)
        #expect(try assets.loadSound(project.sound).frameCount == 800)
        // Nothing to scan or import, nothing written.
        #expect(!assets.refresh().hasChanges)
        #expect(!assets.refreshAsync().hasChanges)
        #expect(assets.importJob(for: project.model) == nil)
        #expect(throws: AssetError.self) { try assets.setSettings(TextureImporter.Settings(), for: project.texture) }
        #expect(!FileManager.default.fileExists(atPath: elsewhere.deletingLastPathComponent().appendingPathComponent("Library").path))
        // Ids it doesn't have fail clearly.
        #expect(assets.loadState(of: project.unused) == .missing)
        #expect(assets.asset(project.unused) == nil)
        #expect(assets.request(project.unused) == .missing)
        #expect(throws: AssetPackError.unknownAsset(project.unused, pack: "Game.pack")) { try assets.loadFromPack(project.unused) }
        let message = AssetPackError.unknownAsset(project.unused, pack: "Game.pack").description
        #expect(message.contains(project.unused.description) && message.contains("Game.pack") && message.contains("--include"))
        #expect(throws: AssetPackError.self) { try assets.pack!.scene("Scenes/Other.scene") }
    }

    @Test func damagedPacksFailClearly() throws {
        let project = try TestProject()
        let report = try project.cook()
        let url = URL(fileURLWithPath: report.packPath)
        var bytes = try Data(contentsOf: url)
        let pack = try AssetPack(url: url)
        let blob = try #require(pack.entry(project.texture)?.files.values.first)
        // A flipped byte in a blob: that asset fails, others still load.
        bytes[Int(blob.offset) + 10] ^= 0xFF
        let damaged = url.deletingLastPathComponent().appendingPathComponent("damaged.pack")
        try bytes.write(to: damaged)
        let reopened = try AssetPack(url: damaged)
        #expect(throws: AssetPackError.self) { try reopened.asset(project.texture) }
        #expect(try reopened.asset(project.material).objects.count == 1)
        let mounted = AssetDatabase(mounting: reopened)
        #expect(mounted.texture(AssetReference(project.texture)) == nil)
        #expect(mounted.loadState(of: project.texture) == .failed)
        // A damaged table of contents, a file that isn't a pack, a missing file.
        var toc = try Data(contentsOf: url)
        toc[toc.count - 5] ^= 0x01
        try toc.write(to: damaged)
        #expect(throws: AssetPackError.self) { try AssetPack(url: damaged) }
        try Data("hello".utf8).write(to: damaged)
        #expect(throws: AssetPackError.notAPack(damaged.path)) { try AssetPack(url: damaged) }
        #expect(throws: AssetPackError.self) { try AssetPack(url: url.appendingPathExtension("missing")) }
    }

    @Test func missingReferencesAreReportedAndBadOptionsRefused() throws {
        let project = try TestProject()
        let ghost = AssetID.random()
        let world = World()
        _ = world.spawn(Transform(), MeshRenderer(mesh: .cube, material: MaterialHandle(AssetReference(ghost))))
        try write(try world.save(), to: project.root.appendingPathComponent("Assets/Scenes/Ghost.scene"))
        let report = try project.cook(CookOptions(scenes: ["Assets/Scenes/Ghost.scene", "Scenes/Main.scene"]))
        #expect(report.scenes == ["Scenes/Ghost.scene", "Scenes/Main.scene"])
        #expect(report.warnings.count == 1 && report.warnings[0].contains(ghost.description))
        #expect(try AssetPack(url: URL(fileURLWithPath: report.packPath)).manifest.startScene == "Scenes/Ghost.scene")
        #expect(throws: CookError.noScenes) { try project.cook(CookOptions(scenes: [])) }
        #expect(throws: CookError.sceneNotFound("Nope.scene")) { try project.cook(CookOptions(scenes: ["Nope.scene"])) }
        #expect(throws: CookError.unknownInclude("Audio/none.wav")) {
            try project.cook(CookOptions(scenes: ["Scenes/Main.scene"], include: ["Audio/none.wav"]))
        }
    }

    @Test func referencesAreFoundInEscapedJSON() {
        let a = AssetID.random(), b = AssetID.random()
        // A .prefab's scene data is JSON inside a JSON string: its references are escaped.
        let text = #"{"scene":"{\"mesh\":\"asset:\#(a)#mesh\/X\"}","material":"asset:\#(b)","bad":"asset:12"}"#
        #expect(CookPlan.references(in: Data(text.utf8)) == [a, b])
    }

    @Test func shippingTextureSettings() {
        let importer = AnyAssetImporter(TextureImporter())
        func shipped(_ compression: TextureCompression, _ family: TextureFamily, _ mode: TextureCookMode = .compress) -> String? {
            let effective = importer.effectiveSettings(try? AssetJSON.value(TextureImporter.Settings(compression: compression)))
            let options = CookOptions(scenes: [], target: CookTarget(platform: .linux, textureFamily: family), textures: mode,
                                      textureQuality: .fast)
            guard case .object(let o) = AssetCooker.shippingSettings(importer: importer, effective: effective, options: options),
                  case .string(let value)? = o["compression"] else { return nil }
            return value
        }
        #expect(shipped(.none, .bc) == "bc5")
        #expect(shipped(.none, .astc) == "astcRG")
        #expect(shipped(.none, .bc, .asImported) == "none")
        #expect(shipped(.bc7, .astc) == "astc")
        #expect(shipped(.astc, .bc) == "bc7")
        #expect(shipped(.astcRG, .bc) == "bc5")
        #expect(shipped(.auto, TextureFamily.machine) == "auto")
        #expect(shipped(.auto, TextureFamily.machine == .bc ? .astc : .bc) == (TextureFamily.machine == .bc ? "astcRG" : "bc5"))
        // Other importers keep their settings.
        let obj = AnyAssetImporter(OBJImporter())
        #expect(AssetCooker.shippingSettings(importer: obj, effective: obj.defaultSettings, options: CookOptions(scenes: [])) == obj.defaultSettings)
    }

    @Test func playerOptionsAndModuleRegistration() throws {
        let options = try GamePlayer.Options.parse(["--pack", "a.pack", "--scene", "Scenes/B.scene", "--backend", "vulkan", "--size", "640x360"])
        #expect(options.pack == "a.pack" && options.scene == "Scenes/B.scene" && options.backend == .vulkan)
        #expect(options.width == 640 && options.height == 360)
        #expect(throws: GamePlayerError.self) { try GamePlayer.Options.parse(["--size", "big"]) }
        #expect(throws: GamePlayerError.self) { try GamePlayer.Options.parse(["--nope"]) }
        #expect(try GamePlayer.findPack(explicit: "/x/y.pack").path == "/x/y.pack")
        // A module's entry point, called the way a statically linked one is.
        let module = try GamePlayer.register { raw in
            GameModule.register(raw) { game in
                game.name = "AssetPackTestsGame"
                game.system("assetPackTests.noop") { _, _ in }
            }
        }
        #expect(module.name == "AssetPackTestsGame" && module.systems.count == 1)
        #expect(throws: GameModuleError.versionMismatch(99)) { try GamePlayer.register { _ in 99 } }
        // With a pack holding scenes, the player plays the start scene.
        let project = try TestProject()
        let report = try project.cook()
        let assets = AssetDatabase(mounting: try AssetPack(url: URL(fileURLWithPath: report.packPath)))
        #expect(try GamePlayer.makeGame(module: module, assets: assets, scene: nil) is PackSceneGame)
        #expect(throws: AssetPackError.self) { try GamePlayer.makeGame(module: module, assets: assets, scene: "Missing.scene") }
    }

    @Test func projectBuildSettingsRoundTrip() throws {
        let root = try temporaryFolder().appendingPathComponent("Settings")
        var project = try Project.create(at: root)
        project.settings.build = GameBuildSettings(scenes: ["Scenes/A.scene"], include: ["x.wav"], name: "Game", textureFamily: .bc,
                                                   textures: .asImported)
        try project.saveSettings()
        #expect(try Project.open(at: root).settings.build == project.settings.build)
    }
}
