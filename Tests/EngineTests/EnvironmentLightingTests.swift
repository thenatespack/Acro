import Foundation
import Testing
@testable import Engine

@Suite struct EnvironmentLightingTests {
    private func close(_ a: Vec3, _ b: Vec3, _ tolerance: Float) -> Bool {
        abs(a.x - b.x) <= tolerance && abs(a.y - b.y) <= tolerance && abs(a.z - b.z) <= tolerance
    }

    @Test func equirectMappingRoundTrips() {
        // u = 0.5 looks down -Z, u = 0.75 toward +X, v = 0 straight up.
        #expect(close(EnvironmentMath.equirectDirection(Vec2(0.5, 0.5)), Vec3(0, 0, -1), 1e-6))
        #expect(close(EnvironmentMath.equirectDirection(Vec2(0.75, 0.5)), Vec3(1, 0, 0), 1e-6))
        #expect(close(EnvironmentMath.equirectDirection(Vec2(0.3, 0)), Vec3(0, 1, 0), 1e-6))
        for uv in [Vec2(0.1, 0.2), Vec2(0.5, 0.5), Vec2(0.9, 0.7), Vec2(0.62, 0.95)] {
            let back = EnvironmentMath.equirectUV(EnvironmentMath.equirectDirection(uv))
            #expect(abs(back.x - uv.x) < 1e-5 && abs(back.y - uv.y) < 1e-5)
        }
    }

    @Test func shProjectionOfKnownFunctions() {
        // A uniform environment: irradiance / pi equals its radiance in every direction.
        let constant = EnvironmentMath.projectIrradianceSH(width: 64, height: 32) { _ in Vec3(0.2, 0.5, 1.5) }
        for n in [Vec3(0, 1, 0), Vec3(0, -1, 0), normalize(Vec3(1, 2, -3))] {
            #expect(close(EnvironmentMath.irradiance(constant, normal: n), Vec3(0.2, 0.5, 1.5), 1e-3))
        }
        #expect(constant[1...].allSatisfy { length($0) < 2e-3 })

        // L = a + b d.y (bands 0 and 1 only, so SH9 is exact): E / pi = a + (2/3) b n.y.
        let linear = EnvironmentMath.projectIrradianceSH(width: 64, height: 32) { d in Vec3(repeating: 1 + 0.6 * d.y) }
        for n in [Vec3(0, 1, 0), Vec3(1, 0, 0), normalize(Vec3(0.3, -0.8, 0.5))] {
            let expected = 1 + 0.6 * 2 / 3 * n.y
            #expect(abs(EnvironmentMath.irradiance(linear, normal: n).x - expected) < 2e-3)
        }

        // A sky of radiance 1 above the horizon, black below: the band-2 coefficient of a
        // hemisphere vanishes, so SH9 gives the exact 1 facing up, 1/2 sideways, 0 facing down.
        let sky = EnvironmentMath.projectIrradianceSH(width: 64, height: 32) { d in d.y > 0 ? Vec3(1, 1, 1) : .zero }
        #expect(abs(EnvironmentMath.irradiance(sky, normal: Vec3(0, 1, 0)).x - 1) < 5e-3)
        #expect(abs(EnvironmentMath.irradiance(sky, normal: Vec3(0, 0, 1)).x - 0.5) < 5e-3)
        #expect(EnvironmentMath.irradiance(sky, normal: Vec3(0, -1, 0)).x < 5e-3)
    }

    @Test func brdfTableIsSane() {
        let n = EnvironmentMath.brdfLUTSize
        let lut = EnvironmentMath.brdfLUT
        #expect(lut.count == n * n)
        for (i, e) in lut.enumerated() {
            // Scale and bias are non-negative and conserve energy (A + B <= 1).
            #expect(e.x >= 0 && e.y >= 0 && e.x + e.y <= 1.001, "entry \(i): \(e)")
        }
        // Smooth surfaces seen head-on reflect F0 almost exactly: A ~ 1, B ~ 0.
        #expect(lut[n - 1].x > 0.95 && lut[n - 1].y < 0.02)
        // At grazing angles the Fresnel bias dominates for smooth surfaces.
        let grazing = EnvironmentMath.environmentBRDF(NoV: 0.05, roughness: 0.1)
        #expect(grazing.y > 0.3)
        // Roughness loses energy (single scattering): A + B decreases toward rough at NoV = 0.5.
        let column = n / 2
        let sums = (0..<n).map { lut[$0 * n + column].x + lut[$0 * n + column].y }
        #expect(sums[n - 1] < sums[4] && sums[n - 1] > 0.35)
        // Importance sampling agrees with a brute-force integration of the same BRDF over the hemisphere.
        for (NoV, r): (Float, Float) in [(0.5, 0.5), (0.9, 0.2), (0.2, 0.8)] {
            let alpha = r * r, a2 = alpha * alpha
            let v = Vec3((1 - NoV * NoV).squareRoot(), 0, NoV)
            var reference = Vec2.zero
            let steps = 200
            for i in 0..<steps {
                let theta = (Float(i) + 0.5) / Float(steps) * .pi / 2
                for j in 0..<(4 * steps) {
                    let phi = (Float(j) + 0.5) / Float(4 * steps) * 2 * .pi
                    let l = Vec3(sinf(theta) * cosf(phi), sinf(theta) * sinf(phi), cosf(theta))
                    let h = normalize(l + v)
                    let d = h.z * h.z * (a2 - 1) + 1
                    let dw = sinf(theta) * (.pi / 2 / Float(steps)) * (2 * .pi / Float(4 * steps))
                    let f = a2 / (.pi * d * d) * EnvironmentMath.visibility(NoV: NoV, NoL: l.z, alpha: alpha) * l.z * dw
                    let fc = powf(1 - dot(v, h), 5)
                    reference += Vec2(1 - fc, fc) * f
                }
            }
            let e = EnvironmentMath.environmentBRDF(NoV: NoV, roughness: r)
            #expect(abs(e.x - reference.x) < 0.015 && abs(e.y - reference.y) < 0.005, "NoV \(NoV) r \(r): \(e) vs \(reference)")
        }
    }

    @Test func hammersleyAndAtlasLayout() {
        #expect(EnvironmentMath.hammersley(0, 4) == Vec2(0, 0))
        #expect(EnvironmentMath.hammersley(1, 4) == Vec2(0.25, 0.5))
        #expect(EnvironmentMath.hammersley(3, 4) == Vec2(0.75, 0.75))
        // Levels halve in size, fit the atlas and don't overlap each other or the SH row.
        var rects = EnvironmentAtlas.levels
        rects.append((EnvironmentAtlas.sh.x, EnvironmentAtlas.sh.y, 9, 1))
        for (i, a) in rects.enumerated() {
            #expect(a.x >= 0 && a.y >= 0 && a.x + a.width <= EnvironmentAtlas.width && a.y + a.height <= EnvironmentAtlas.height)
            for b in rects[(i + 1)...] {
                #expect(a.x + a.width <= b.x || b.x + b.width <= a.x || a.y + a.height <= b.y || b.y + b.height <= a.y)
            }
        }
        // Incremental alphas add up to each level's alpha (in quadrature).
        var total: Float = 0
        for level in 1..<EnvironmentAtlas.levels.count {
            total += powf(EnvironmentAtlas.incrementalAlpha(level: level), 2)
            #expect(abs(total.squareRoot() - powf(EnvironmentAtlas.roughness(level: level), 2)) < 1e-5)
        }
    }

    @MainActor @Test func sceneEnvironmentLoadsOldFilesAndRoundTrips() throws {
        // A scene file written before skies existed.
        let old = #"{"ambientIntensity":0.5,"fogColor":[0.1,0.2,0.3],"fogDensity":0.01,"groundColor":[0.1,0.1,0.1],"skyColor":[0.5,0.6,0.7]}"#
        let decoded = try JSONDecoder().decode(SceneEnvironment.self, from: Data(old.utf8))
        #expect(decoded.sky == .color && decoded.environmentMap == nil && decoded.environmentIntensity == 1)
        #expect(decoded.imageBasedLighting && decoded.proceduralSky == ProceduralSky() && decoded.ambientIntensity == 0.5)

        var environment = SceneEnvironment(sky: .map, environmentMap: TextureHandle("studio"), environmentIntensity: 2,
                                           environmentRotation: 0.5, imageBasedLighting: false)
        environment.proceduralSky.sunSize = 0.02
        let data = try JSONEncoder().encode(environment)
        #expect(String(decoding: data, as: UTF8.self).contains(#""environmentMap":"studio""#))
        #expect(try JSONDecoder().decode(SceneEnvironment.self, from: data) == environment)

        // Through a whole scene file.
        let world = World()
        let entity = world.spawn(environment)
        let loaded = World()
        _ = try loaded.load(try world.save())
        var found: SceneEnvironment?
        loaded.query(SceneEnvironment.self) { _, e in found = e }
        #expect(found == world.get(SceneEnvironment.self, for: entity))
    }
}
