import Foundation
import Testing
@testable import Engine

@Suite struct FogEmissiveTests {
    private let box = Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5))

    @MainActor @Test func emissiveOverrideDefaultsLeaveTheInstanceUnchanged() {
        let world = World()
        var prep = RenderPrep()
        prep.meshes.register(box, key: "cube")
        prep.materials.register(MaterialTraits(), key: "default")
        let plain = world.spawn(Transform(), MeshRenderer(mesh: .cube, tint: Vec3(0.5, 0.2, 0.1)))
        let neon = world.spawn(Transform(), MeshRenderer(mesh: .cube, emissiveTint: Vec3(1, 0.5, 0), emissiveStrength: 4))
        world.propagateTransforms()
        prep.gather(world: world)
        let byEntity = Dictionary(uniqueKeysWithValues: prep.items.map { ($0.entity, $0) })
        // Default: receives shadows, the emissive multiplier minus one is exactly zero; tint is not involved.
        #expect(byEntity[plain]!.instance.params == Vec4(1, 0, 0, 0))
        #expect(byEntity[plain]!.instance.color == Vec4(0.5, 0.2, 0.1, 1))
        // Multiplier = tint x strength: (4, 2, 0), stored minus one.
        #expect(byEntity[neon]!.instance.params == Vec4(1, 3, 1, -1))
        #expect(MemoryLayout<MeshInstance>.stride == 160)
    }

    @MainActor @Test func meshRendererLoadsOldFilesAndRoundTrips() throws {
        let old = #"{"mesh":"cube","material":"default","tint":[1,0,0],"opacity":1,"castsShadows":true,"receivesShadows":true,"isVisible":true}"#
        let decoded = try JSONDecoder().decode(MeshRenderer.self, from: Data(old.utf8))
        #expect(decoded.emissiveTint == Vec3(1, 1, 1) && decoded.emissiveStrength == 1 && decoded.tint == Vec3(1, 0, 0))
        let value = MeshRenderer(mesh: .cube, emissiveTint: Vec3(0, 1, 0), emissiveStrength: 3)
        #expect(try JSONDecoder().decode(MeshRenderer.self, from: JSONEncoder().encode(value)) == value)
    }

    @MainActor @Test func environmentFogFieldsDefaultOffAndRoundTrip() throws {
        let old = #"{"ambientIntensity":0.5,"fogColor":[0.1,0.2,0.3],"fogDensity":0.01,"groundColor":[0.1,0.1,0.1],"skyColor":[0.5,0.6,0.7]}"#
        let decoded = try JSONDecoder().decode(SceneEnvironment.self, from: Data(old.utf8))
        #expect(decoded.fogHeightFalloff == 0 && decoded.fogBaseHeight == 0)
        #expect(decoded.volumetricFog == VolumetricFog() && !decoded.volumetricFog.enabled)
        #expect(SceneEnvironment() == (try JSONDecoder().decode(SceneEnvironment.self, from: JSONEncoder().encode(SceneEnvironment()))))

        let environment = SceneEnvironment(fogDensity: 0.05, fogHeightFalloff: 0.2, fogBaseHeight: 3,
                                           volumetricFog: VolumetricFog(enabled: true, intensity: 2, anisotropy: 0.7, maxDistance: 40,
                                                                        steps: 24, localLights: false))
        #expect(try JSONDecoder().decode(SceneEnvironment.self, from: JSONEncoder().encode(environment)) == environment)
        // Partial volumetric settings keep the other defaults.
        let partial = try JSONDecoder().decode(VolumetricFog.self, from: Data(#"{"enabled":true}"#.utf8))
        #expect(partial == VolumetricFog(enabled: true))
    }

    @Test func heightFogClosedFormMatchesIntegration() {
        // The optical depth mesh_surface.glsl computes in closed form, against numeric integration.
        let d0: Float = 0.05, k: Float = 0.2, base: Float = 1
        let eyeY: Float = 2, hitY: Float = 12, dist: Float = 30
        let dirY = (hitY - eyeY) / dist
        let x = k * (hitY - eyeY)
        let closed = dist * d0 * expf(-k * (eyeY - base)) * (1 - expf(-x)) / x
        var numeric: Float = 0
        let n = 20000
        for i in 0..<n {
            let s = (Float(i) + 0.5) / Float(n) * dist
            numeric += d0 * expf(-k * (eyeY + dirY * s - base)) * dist / Float(n)
        }
        #expect(abs(closed - numeric) < 1e-4)
    }

    @Test func volumetricFogPushConstantsMatchTheShader() {
        // volumetric_fog.frag: mat4 + two vec4 = 96 bytes.
        #expect(MemoryLayout<VolumetricFogConstants>.stride == 96)
    }
}
