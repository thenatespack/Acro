import Foundation
import Testing
@testable import Engine

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
