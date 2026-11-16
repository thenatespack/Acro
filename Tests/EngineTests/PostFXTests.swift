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
