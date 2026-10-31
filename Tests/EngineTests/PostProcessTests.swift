import Foundation
import Testing
@testable import Engine

@Suite struct PostProcessTests {
    typealias Tonemapper = PostProcessSettings.Tonemapper

    private func gray(_ x: Float, _ t: Tonemapper) -> Float { PostProcessMath.tonemap(Vec3(repeating: x), t).x }

    @Test func tonemappersAreMonotonicAndBounded() {
        for t in Tonemapper.allCases {
            var previous: Float = -1
            for i in 0...4000 {
                let x = Float(i) * 0.01  // 0...40
                let y = gray(x, t)
                #expect(y >= previous, "\(t) decreases at \(x)")
                #expect((0...1).contains(y))
                previous = y
            }
            #expect(gray(0, t) == 0)
        }
    }

    @Test func tonemapperKnownValues() {
        // none: clamp.
        #expect(gray(0.5, .none) == 0.5 && gray(3, .none) == 1)
        // Reinhard: x / (1 + x).
        #expect(gray(1, .reinhard) == 0.5 && abs(gray(3, .reinhard) - 0.75) < 1e-6)
        // PBR Neutral: subtracts the 0.04 toe offset, linear below 0.76, compresses above.
        #expect(abs(gray(0.5, .neutral) - 0.46) < 1e-6)
        #expect(abs(gray(0.04, .neutral) - 0.01) < 1e-6)  // offset = x - 6.25 x²
        #expect(gray(1, .neutral) < 0.96 && gray(1, .neutral) > 0.85)
        #expect(gray(100, .neutral) > 0.99)
        // Saturated colors keep their hue below the knee.
        let c = PostProcessMath.tonemap(Vec3(0.6, 0.3, 0.1), .neutral)
        #expect(c.x > c.y && c.y > c.z)
        // ACES (Hill fit): filmic toe, so mid gray 0.18 maps to about 0.106; bright values saturate.
        #expect(abs(gray(0.18, .aces) - 0.106) < 0.003)
        #expect(gray(16, .aces) > 0.97)
    }

    @Test func exposureConversions() {
        #expect(PostProcessMath.exposureScale(ev: 0) == 1)
        #expect(PostProcessMath.exposureScale(ev: 1) == 2)
        #expect(PostProcessMath.exposureScale(ev: -2) == 0.25)
        for ev: Float in [-6, -1.5, 0, 0.5, 3.25] {
            #expect(abs(PostProcessMath.ev(scale: PostProcessMath.exposureScale(ev: ev)) - ev) < 1e-5)
        }
        // A scene averaging middle gray needs no exposure; one twice as bright needs -1 EV.
        let key = log2f(PostProcessMath.autoExposureKey)
        #expect(abs(PostProcessMath.autoExposureEV(averageLog2Luminance: key, minEV: -6, maxEV: 6)) < 1e-6)
        #expect(abs(PostProcessMath.autoExposureEV(averageLog2Luminance: key + 1, minEV: -6, maxEV: 6) + 1) < 1e-5)
        #expect(PostProcessMath.autoExposureEV(averageLog2Luminance: -30, minEV: -6, maxEV: 6) == 6)
        #expect(PostProcessMath.autoExposureEV(averageLog2Luminance: 30, minEV: -6, maxEV: 6) == -6)
    }

    @Test func autoExposureAdaptationStep() {
        // A reset (rate 1) converges at once.
        #expect(PostProcessMath.adapt(current: .nan, target: 2, rate: 1) == 2)
        let rate = PostProcessMath.adaptationRate(dt: 1.0 / 60, speed: 1.5)
        #expect(abs(rate - (1 - expf(-1.5 / 60))) < 1e-7)
        let step = PostProcessMath.adapt(current: 0, target: 4, rate: rate)
        #expect(step > 0 && step < 4 && abs(step - 4 * rate) < 1e-6)
        // Frame-rate independent: two half steps equal one full step.
        let half = PostProcessMath.adaptationRate(dt: 1.0 / 120, speed: 1.5)
        let twice = PostProcessMath.adapt(current: PostProcessMath.adapt(current: 0, target: 4, rate: half), target: 4, rate: half)
        #expect(abs(twice - step) < 1e-5)
        // Converges toward the target without overshooting.
        var ev: Float = -3
        for _ in 0..<600 { ev = PostProcessMath.adapt(current: ev, target: 1, rate: rate) }
        #expect(ev <= 1 && abs(ev - 1) < 1e-3)
        #expect(PostProcessMath.adaptationRate(dt: 0, speed: 1.5) == 0)
    }

    @Test func bloomMipChainSizes() {
        let sizes = PostProcessMath.bloomMipSizes(width: 1280, height: 720)
        #expect(sizes.map(\.width) == [640, 320, 160, 80, 40, 20])
        #expect(sizes.map(\.height) == [360, 180, 90, 45, 23, 12])
        #expect(PostProcessMath.bloomMipSizes(width: 2560, height: 1440).count == 7)
        #expect(PostProcessMath.bloomMipSizes(width: 1281, height: 721).first! == (641, 361))
        #expect(PostProcessMath.bloomMipSizes(width: 3840, height: 2160).count == 8)
        // Tiny images still get one level; the level cap holds.
        #expect(PostProcessMath.bloomMipSizes(width: 4, height: 4).map(\.width) == [2])
        #expect(PostProcessMath.bloomMipSizes(width: 1 << 14, height: 1 << 14, maxLevels: 5).count == 5)
    }

    @Test func settingsCodableRoundTrip() throws {
        let settings = PostProcessSettings(tonemapper: .aces, exposure: -1.5, autoExposure: true, autoExposureMin: -3,
                                           autoExposureMax: 2.5, adaptationSpeed: 4, bloom: true, bloomIntensity: 0.1)
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(PostProcessSettings.self, from: data) == settings)
        // Missing keys take defaults; tonemappers are stored by name.
        let partial = try JSONDecoder().decode(PostProcessSettings.self, from: Data(#"{"tonemapper":"reinhard","bloom":true}"#.utf8))
        #expect(partial == PostProcessSettings(tonemapper: .reinhard, bloom: true))
        #expect(PostProcessSettings.componentName == "PostProcess")
    }

    @Test @MainActor func settingsAreAComponentTheInspectorCanEdit() throws {
        let world = World()
        #expect(PostProcessSettings.find(in: world) == nil)
        let e = world.spawn(PostProcess(bloom: true))
        let fields = PostProcessSettings().fields()
        #expect(fields.first { $0.name == "tonemapper" }?.kind == .enumeration(cases: ["none", "reinhard", "neutral", "aces"]))
        #expect(fields.first { $0.name == "exposure" }?.hints.range == -10...10)
        try world.setField("exposure", of: "PostProcess", for: e, to: .float(2))
        try world.setField("tonemapper", of: "PostProcess", for: e, to: .enumCase("aces"))
        #expect(PostProcessSettings.find(in: world) == PostProcessSettings(tonemapper: .aces, exposure: 2, bloom: true))
        // Scene files keep it.
        let roots = try World().load(try world.save())
        #expect(!roots.isEmpty)
    }

    @Test func clearColorsSnapToExactSRGBCodes() {
        func code(_ x: Float) -> Double {
            let v = Double(x)
            return (v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055) * 255
        }
        // The ui scene's clear: 0.005 encodes to 15.55, near the midpoint; snapped it is exactly 16.
        let snapped = PostProcessMath.snappedToSRGB8(Vec4(0.004, 0.005, 0.009, 1))
        for x in [snapped.x, snapped.y, snapped.z] {
            #expect(abs(code(x) - code(x).rounded()) < 1e-3)
        }
        #expect(abs(code(snapped.y) - 16) < 1e-3)
        #expect(snapped.w == 1)
        // Already exact values and the extremes don't move.
        #expect(PostProcessMath.snappedToSRGB8(Vec4(0, 1, 0, 0.5)) == Vec4(0, 1, 0, 128.0 / 255))
    }
}
