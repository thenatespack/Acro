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

// Post-FX profiles: file format, blending, volumes, camera assignment and the importer.

@MainActor private func makeDatabase() throws -> (Project, AssetDatabase) {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXTests-\(UUID().uuidString)", isDirectory: true)
    let project = try Project.create(at: url, name: "PostFX")
    return (project, AssetDatabase(project: project))
}

@Suite struct PostFXTests {
    @Test func everyKeyIsOptionalAndRoundTrips() throws {
        let empty = try JSONDecoder().decode(PostProcessSettings.self, from: Data("{}".utf8))
        #expect(empty == PostProcessSettings())
        let profile = PostFXPreset.cinematic.settings
        let data = try profile.fileData()
        #expect(try AssetJSON.decoder().decode(PostProcessSettings.self, from: data) == profile)
        let partial = try JSONDecoder().decode(PostProcessSettings.self, from: Data(#"{"vignette":0.5,"gain":[1,0.5,1]}"#.utf8))
        #expect(partial.vignette == 0.5 && partial.gain == Vec3(1, 0.5, 1) && partial.saturation == 1)
    }

    @Test func presetsAreDistinctAndValid() {
        var seen: [PostProcessSettings] = []
        for preset in PostFXPreset.allCases {
            #expect(preset.settings.validationWarnings().isEmpty, "\(preset)")
            #expect(!seen.contains(preset.settings))
            seen.append(preset.settings)
        }
        #expect(PostFXPreset.noir.settings.saturation == 0)
    }

    @Test func warnsAboutBadValues() {
        var s = PostProcessSettings()
        s.exposure = 30
        s.vignette = 2
        s.autoExposureMin = 3
        s.autoExposureMax = -3
        #expect(s.validationWarnings().count == 3)
    }

    @Test func blendingInterpolates() {
        var a = PostProcessSettings(), b = PostProcessSettings()
        a.exposure = 0
        b.exposure = 2
        b.saturation = 0
        b.tonemapper = .aces
        b.bloom = true
        b.bloomIntensity = 0.2
        let half = a.blended(to: b, weight: 0.5)
        #expect(half.exposure == 1 && half.saturation == 0.5)
        #expect(half.bloom && abs(half.bloomIntensity - 0.1) < 1e-6)
        #expect(half.tonemapper == .aces)
        #expect(a.blended(to: b, weight: 0.25).tonemapper == a.tonemapper)
        #expect(a.blended(to: b, weight: 0) == a && a.blended(to: b, weight: 1) == b)
    }

    @Test func volumeInfluenceFollowsShapeAndBlendDistance() {
        let box = PostFXVolume(shape: .box, size: Vec3(4, 4, 4), blendDistance: 2)
        let at = Mat4.translation(Vec3(10, 0, 0))
        #expect(box.influence(at: Vec3(10, 0, 0), volumeWorld: at) == 1)
        #expect(box.influence(at: Vec3(12, 0, 0), volumeWorld: at) == 1, "on the surface")
        #expect(abs(box.influence(at: Vec3(13, 0, 0), volumeWorld: at) - 0.5) < 1e-5)
        #expect(box.influence(at: Vec3(14.5, 0, 0), volumeWorld: at) == 0)
        let sphere = PostFXVolume(shape: .sphere, radius: 1, blendDistance: 0)
        #expect(sphere.influence(at: Vec3(10.5, 0, 0), volumeWorld: at) == 1)
        #expect(sphere.influence(at: Vec3(11.5, 0, 0), volumeWorld: at) == 0, "hard edge")
        #expect(PostFXVolume(weight: 0.4, isGlobal: true).influence(at: Vec3(99, 0, 0), volumeWorld: at) == 0.4)
    }

    @Test func cameraDecodesWithoutPostFXKey() throws {
        let camera = Camera(postFX: "Looks/noir.postfx")
        let data = try JSONEncoder().encode(camera)
        #expect(try JSONDecoder().decode(Camera.self, from: data) == camera)
        var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["postFX"] = nil
        let old = try JSONDecoder().decode(Camera.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.postFX == "")
    }

    @MainActor @Test func importerStoresTheProfileAndResolverUsesIt() throws {
        let (project, database) = try makeDatabase()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let noir = PostFXPreset.noir.settings
        let warm = PostFXPreset.warm.settings
        let noirID = try database.createPostFX(noir, at: "Looks/noir.postfx")
        try database.createPostFX(warm, at: "Looks/warm.postfx")
        database.refreshAsync()
        database.waitForAll()
        #expect(database.record(noirID)?.importer == "postfx")
        #expect(database.postFX(of: noirID) == noir)
        #expect(PostFXResolver.profile("Looks/noir.postfx", assets: database) == noir)
        #expect(PostFXResolver.profile(AssetReference(noirID).description, assets: database) == noir)
        #expect(PostFXResolver.profile("Looks/missing.postfx", assets: database) == nil)

        let world = World()
        let cameraEntity = world.spawn(Transform(position: Vec3(0, 0, 0)), Camera())
        world.propagateTransforms()
        let cameraWorld = world.worldMatrix(of: cameraEntity)
        var camera = Camera()
        #expect(PostFXResolver.resolve(world: world, camera: camera, cameraWorld: cameraWorld, assets: database) == nil)

        camera.postFX = "Looks/noir.postfx"
        #expect(PostFXResolver.resolve(world: world, camera: camera, cameraWorld: cameraWorld, assets: database) == noir)

        // A volume around the camera blends the warm look over it; one far away doesn't.
        world.spawn(Transform(position: Vec3(0, 0, 0)), PostFXVolume(profile: "Looks/warm.postfx", size: Vec3(2, 2, 2), blendDistance: 0))
        world.spawn(Transform(position: Vec3(100, 0, 0)), PostFXVolume(profile: "Looks/noir.postfx", size: Vec3(2, 2, 2), blendDistance: 0, priority: 9))
        world.propagateTransforms()
        camera.postFX = ""
        #expect(PostFXResolver.resolve(world: world, camera: camera, cameraWorld: cameraWorld, assets: database) == warm)
    }

    @MainActor @Test func importWarnsAboutBadValues() throws {
        let (project, database) = try makeDatabase()
        defer { try? FileManager.default.removeItem(at: project.root) }
        var bad = PostProcessSettings()
        bad.exposure = 50
        let id = try database.createPostFX(PostProcessSettings(), at: "bad.postfx")
        let warnings = try database.writePostFX(bad, to: id)
        #expect(warnings.contains { $0.contains("exposure") })
    }
}

// Depth of field: settings, the lens math dof.frag mirrors, blending and auto-focus.
@Suite struct PostFXDepthOfFieldTests {
    @Test func depthOfFieldKeysAreOptionalAndRoundTrip() throws {
        let old = try JSONDecoder().decode(PostProcessSettings.self, from: Data(#"{"vignette":0.5}"#.utf8))
        #expect(!old.depthOfField && old.focusDistance == 10 && old.aperture == 2.8 && old.focusTarget.isEmpty)
        var s = PostProcessSettings()
        s.depthOfField = true
        s.focusDistance = 4
        s.focusRange = 1
        s.aperture = 1.8
        s.maxBlur = 2
        s.focusTarget = "Hero"
        #expect(try AssetJSON.decoder().decode(PostProcessSettings.self, from: s.fileData()) == s)
        #expect(s.validationWarnings().isEmpty)
        s.aperture = 0.1
        s.maxBlur = 20
        #expect(s.validationWarnings().count == 2)
    }

    @Test func circleOfConfusionFollowsTheThinLens() {
        var s = PostProcessSettings()
        s.depthOfField = true
        s.focusDistance = 3
        s.focusRange = 0
        s.aperture = 2.8
        s.maxBlur = 100
        let lens = PostProcessMath.depthOfFieldLens(s)  // 50 mm
        let f: Float = 0.05, a = f / 2.8
        let expected = a * f * 7 / (10 * (3 - f)) / 0.024
        #expect(abs(PostProcessMath.circleOfConfusion(distance: 10, lens: lens) - expected) < 1e-5)
        #expect(PostProcessMath.circleOfConfusion(distance: 3, lens: lens) == 0)
        #expect(PostProcessMath.circleOfConfusion(distance: 1, lens: lens) < 0, "in front of the focus is negative")
        // Wider aperture (lower f-number) blurs more; the sharp range keeps a band at 0; maxBlur caps it.
        s.aperture = 1.4
        #expect(PostProcessMath.circleOfConfusion(distance: 10, lens: PostProcessMath.depthOfFieldLens(s)) > expected * 1.9)
        s.focusRange = 2
        #expect(PostProcessMath.circleOfConfusion(distance: 3.9, lens: PostProcessMath.depthOfFieldLens(s)) == 0)
        s.focalLength = 100
        #expect(PostProcessMath.circleOfConfusion(distance: 20, lens: PostProcessMath.depthOfFieldLens(s))
            > PostProcessMath.circleOfConfusion(distance: 20, lens: PostProcessMath.depthOfFieldLens({ var t = s; t.focalLength = 50; return t }())) * 3.5)
        s.maxBlur = 0.5
        #expect(PostProcessMath.circleOfConfusion(distance: 1000, lens: PostProcessMath.depthOfFieldLens(s)) == 0.005)
        // About depthOfFieldTaps taps reach the largest radius.
        let step = PostProcessMath.depthOfFieldStep(maxRadius: 40)
        var radius = step, taps = 0
        while radius < 40 { radius += step / radius; taps += 1 }
        #expect(abs(taps - PostProcessMath.depthOfFieldTaps) < 10)
        #expect(PostProcessMath.depthOfFieldStep(maxRadius: 2) == 0.5)
    }

    @Test func depthOfFieldBlendsInByMaxBlur() {
        let off = PostProcessSettings()
        var on = PostProcessSettings()
        on.depthOfField = true
        on.focusDistance = 4
        on.maxBlur = 2
        on.focusTarget = "Hero"
        let quarter = off.blended(to: on, weight: 0.25)
        #expect(quarter.depthOfField && quarter.maxBlur == 0.5 && quarter.focusDistance == 4)
        #expect(quarter.focusTarget.isEmpty && off.blended(to: on, weight: 0.75).focusTarget == "Hero")
        var other = on
        other.focusDistance = 8
        #expect(on.blended(to: other, weight: 0.5).focusDistance == 6)
    }

    @MainActor @Test func autoFocusMeasuresAlongTheViewAxis() {
        let world = World()
        world.spawn(Transform(position: Vec3(2, 0, -5)), Name("PostFXDepthOfFieldTestsTarget"))
        world.propagateTransforms()
        var s = PostProcessSettings()
        s.depthOfField = true
        s.focusTarget = "PostFXDepthOfFieldTestsTarget"
        let camera = Mat4.translation(Vec3(0, 0, 1))  // looking down -Z from z = 1
        #expect(PostFXResolver.autoFocused(s, world: world, cameraWorld: camera)?.focusDistance == 6)
        s.focusTarget = "nobody"
        #expect(PostFXResolver.autoFocused(s, world: world, cameraWorld: camera)?.focusDistance == 10)
        s.focusTarget = "PostFXDepthOfFieldTestsTarget"
        s.depthOfField = false
        #expect(PostFXResolver.autoFocused(s, world: world, cameraWorld: camera)?.focusDistance == 10)
    }
}

/// A `.cube` file of size `n` whose output is `transform(input)`.
func postFXLUTTestsCube(size n: Int, _ transform: (Vec3) -> Vec3) -> String {
    var text = "# test\nTITLE \"test\"\nLUT_3D_SIZE \(n)\n\n"
    for b in 0..<n {
        for g in 0..<n {
            for r in 0..<n {
                let out = transform(Vec3(Float(r), Float(g), Float(b)) / Float(n - 1))
                text += "\(out.x) \(out.y) \(out.z)\n"
            }
        }
    }
    return text
}

// LUT grading: `.cube` parsing, the strip layout, the importers, blending and cooking.
@MainActor @Suite struct PostFXLUTTests {
    @Test func cubeFilesBecomeStrips() throws {
        let (strip, warnings) = try PostFXLUT.parseCube(postFXLUTTestsCube(size: 3) { Vec3($0.x, $0.y * 0.5, 1 - $0.z) })
        #expect(warnings.isEmpty && strip.width == 9 && strip.height == 3)
        // Texel (r, g, b) sits at x = r + b·N, y = g.
        let i = (2 * 9 + 1 * 3 + 2) * 4  // r 2, g 2, b 1
        #expect(strip.pixels[i] == 1 && strip.pixels[i + 1] == 0.5 && strip.pixels[i + 2] == 0.5)
        #expect(try PostFXLUT.parseCube(postFXLUTTestsCube(size: 2) { $0 }) .strip.pixels == PostFXLUT.identity(size: 2).pixels)
        #expect(throws: AssetError.self) { try PostFXLUT.parseCube("LUT_1D_SIZE 4\n0 0 0") }
        #expect(throws: AssetError.self) { try PostFXLUT.parseCube("LUT_3D_SIZE 2\n0 0 0\n1 1 1") }
        #expect(throws: AssetError.self) { try PostFXLUT.parseCube("LUT_3D_SIZE 99") }
        #expect(PostFXLUT.size(width: 256, height: 16) == 16 && PostFXLUT.size(width: 256, height: 15) == nil)
    }

    @Test func applyingInterpolatesInSRGB() {
        let identity = PostFXLUT.identity(size: 17)
        for c in [Vec3(0, 0, 0), Vec3(0.2, 0.5, 0.9), Vec3(1, 1, 1), Vec3(0.01, 0.7, 0.33)] {
            let out = PostFXLUT.apply(c, lut: identity, intensity: 1)
            #expect(abs(out.x - c.x) < 1e-4 && abs(out.y - c.y) < 1e-4 && abs(out.z - c.z) < 1e-4)
        }
        let invert = try! PostFXLUT.parseCube(postFXLUTTestsCube(size: 2) { Vec3(1, 1, 1) - $0 }).strip
        let out = PostFXLUT.apply(Vec3(1, 0, 0.214), lut: invert, intensity: 1)  // 0.214 linear ≈ 0.5 encoded
        #expect(abs(out.x) < 1e-5 && abs(out.y - 1) < 1e-5 && abs(out.z - 0.214) < 0.01)
        #expect(PostFXLUT.apply(Vec3(1, 0, 0), lut: invert, intensity: 0.5) == Vec3(0.5, 0.5, 0.5))
    }

    @Test func lutsBlendByIntensity() {
        let none = PostProcessSettings()
        let a = PostProcessSettings(lut: "a.cube", lutIntensity: 0.8)
        let b = PostProcessSettings(lut: "b.cube", lutIntensity: 1)
        let fadeIn = none.blended(to: a, weight: 0.5)
        #expect(fadeIn.lut == "a.cube" && abs(fadeIn.lutIntensity - 0.4) < 1e-6)
        let early = a.blended(to: b, weight: 0.25), late = a.blended(to: b, weight: 0.75)
        #expect(early.lut == "a.cube" && abs(early.lutIntensity - 0.4) < 1e-6)
        #expect(late.lut == "b.cube" && abs(late.lutIntensity - 0.5) < 1e-6)
        #expect(PostProcessSettings(lut: "a.cube", lutIntensity: 1.5).validationWarnings().count == 1)
    }

    @Test func importsCubesAndStripImagesAndProfilesReferenceThem() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXLUTTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "PostFXLUT")
        defer { try? FileManager.default.removeItem(at: url) }
        let assets = AssetDatabase(project: project)
        let cubeURL = project.url(forAssetPath: "Grading/film.cube")
        try FileManager.default.createDirectory(at: cubeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(postFXLUTTestsCube(size: 4) { $0 * 0.9 }.utf8).write(to: cubeURL)
        // A strip PNG whose sidecar names the lut importer.
        let identity = PostFXLUT.identity(size: 4)
        let pngURL = project.url(forAssetPath: "Grading/strip.png")
        try Image(width: 16, height: 4, pixels: identity.pixels.map { UInt8(($0 * 255).rounded()) }).writePNG(to: pngURL)
        try AssetSidecar(id: AssetID.random(), importer: "lut").write(to: AssetSidecar.url(for: pngURL))
        assets.scan()
        let cube = try #require(assets.id(forPath: "Grading/film.cube"))
        let strip = try #require(assets.id(forPath: "Grading/strip.png"))
        #expect(assets.record(cube)?.importer == "lut" && assets.record(strip)?.importer == "lut")
        let cubeTexture = try #require(assets.texture(AssetReference(cube)))
        #expect(!cubeTexture.generatesMipmaps && PostFXLUT.strip(from: cubeTexture)?.width == 16)
        let stripTexture = try #require(assets.texture(AssetReference(strip)))
        #expect(!stripTexture.isSRGB && PostFXLUT.strip(from: stripTexture)?.pixels[4] == 85.0 / 255)
        // A profile naming the LUT by path stores it as asset:<id> (so cooking follows it).
        let look = try assets.createPostFX(PostProcessSettings(lut: "Grading/film.cube", lutIntensity: 0.7), at: "Looks/film.postfx")
        #expect(assets.prefab(AssetReference(look))?.roots.first?.postFX?.lut == AssetReference(cube).description)
        #expect(assets.postFX(of: look)?.lut == "Grading/film.cube", "the file keeps the path")
        let missing = try assets.createPostFX(PostProcessSettings(lut: "Grading/none.cube"), at: "Looks/missing.postfx")
        #expect(assets.record(missing)?.importError == nil)
        #expect(assets.prefab(AssetReference(missing))?.roots.first?.postFX?.lut == "Grading/none.cube")
        // Adding the missing LUT later reimports the profile.
        try Data(postFXLUTTestsCube(size: 2) { $0 }.utf8).write(to: project.url(forAssetPath: "Grading/none.cube"))
        assets.refresh()
        let added = try #require(assets.id(forPath: "Grading/none.cube"))
        #expect(assets.prefab(AssetReference(missing))?.roots.first?.postFX?.lut == AssetReference(added).description)
    }

    @Test func cookingShipsTheLUTWithTheProfile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXLUTTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "PostFXLUTCook")
        defer { try? FileManager.default.removeItem(at: url) }
        let assets = AssetDatabase(project: project)
        let cubeURL = project.url(forAssetPath: "Grading/film.cube")
        try FileManager.default.createDirectory(at: cubeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(postFXLUTTestsCube(size: 4) { $0 * 0.9 }.utf8).write(to: cubeURL)
        assets.scan()
        let look = try assets.createPostFX(PostProcessSettings(lut: "Grading/film.cube"), at: "Looks/film.postfx")
        let world = World()
        world.spawn(Transform(), Name("PostFXLUTTestsCamera"), Camera(postFX: AssetReference(look).description))
        let sceneURL = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: sceneURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try world.save().write(to: sceneURL)
        assets.scan()
        let report = try AssetCooker.plan(database: assets, options: CookOptions(scenes: ["Scenes/Main.scene"], target: CookTarget(platform: .linux)))
            .run(to: url.appendingPathComponent("out"))
        let pack = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        let cube = try #require(assets.id(forPath: "Grading/film.cube"))
        #expect(pack.contains(look) && pack.contains(cube))
        let mounted = AssetDatabase(mounting: pack)
        #expect(PostFXLUT.strip(from: try #require(mounted.texture(AssetReference(cube))))?.height == 4)
    }
}
