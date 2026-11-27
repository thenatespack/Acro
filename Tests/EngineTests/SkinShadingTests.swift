import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineAssets
@testable import EngineRendering

// Skin and eye shading (MaterialSkin.swift, skin.glsl, subsurface_blur.frag,
// SceneRenderer+Subsurface.swift): the material blocks and their file format, the presets, the
// separable subsurface kernel, the eyeball mesh's layout, the push constants and the variant choice.

@Suite struct SkinShadingTests {
    @Test func kernelIsNormalizedCenterFirstAndSymmetric() {
        for count in [11, 17, 25] {
            let kernel = SubsurfaceKernel(strength: MaterialSubsurface().channelStrength, falloff: Vec3(1, 0.37, 0.3), count: count)
            #expect(kernel.taps.count == count)
            #expect(kernel.taps[0].w == 0)
            var sum = Vec3.zero
            for t in kernel.taps { sum += Vec3(t.x, t.y, t.z) }
            #expect(abs(sum.x - 1) < 1e-4 && abs(sum.y - 1) < 1e-4 && abs(sum.z - 1) < 1e-4)
            // Offsets come in ± pairs, out to the range.
            let offsets = kernel.taps.dropFirst().map(\.w).sorted()
            for (a, b) in zip(offsets, offsets.reversed()) { #expect(abs(a + b) < 1e-5) }
            #expect(abs((offsets.last ?? 0) - kernel.range) < 1e-5)
            // Red scatters furthest: its share away from the center is the largest.
            #expect(1 - kernel.taps[0].x > 1 - kernel.taps[0].z)
        }
    }

    @Test func zeroStrengthKernelIsIdentity() {
        let kernel = SubsurfaceKernel(strength: .zero, falloff: Vec3(1, 1, 1))
        #expect(kernel.taps[0].x == 1 && kernel.taps[0].y == 1 && kernel.taps[0].z == 1)
        #expect(kernel.taps.dropFirst().allSatisfy { $0.x == 0 && $0.y == 0 && $0.z == 0 })
    }

    @Test func materialFileRoundTripsAndOmitsUnsetBlocks() throws {
        let plain = try JSONEncoder().encode(MaterialAsset())
        let text = String(decoding: plain, as: UTF8.self)
        for key in ["subsurface", "specularLobes", "detailNormal", "\"eye\""] { #expect(!text.contains(key)) }

        let skin = MaterialAsset.skin(.tan)
        let decoded = try JSONDecoder().decode(MaterialAsset.self, from: try JSONEncoder().encode(skin))
        #expect(decoded == skin)
        let eye = MaterialAsset.eye(iris: MaterialEye.green)
        #expect(try JSONDecoder().decode(MaterialAsset.self, from: try JSONEncoder().encode(eye)) == eye)

        // Missing keys inside a block take the defaults.
        let partial = try JSONDecoder().decode(MaterialAsset.self, from: Data(#"{"shading": "pbr", "subsurface": {"radius": 0.02}, "eye": {"pupilSize": 0.5}}"#.utf8))
        #expect(partial.subsurface == MaterialSubsurface(radius: 0.02))
        #expect(partial.eye == MaterialEye(pupilSize: 0.5))
        #expect(partial.specularLobes == nil)
    }

    @Test @MainActor func presetsReachTheMaterialAndPickTheSkinVariant() {
        let skin = Material.skin(.deep)
        #expect(skin.subsurface != nil && skin.specularLobes != nil && skin.detailNormal != nil && skin.eye == nil)
        #expect(skin.usesSkinShading && skin.scattersInScreenSpace)
        let eye = Material.eye()
        #expect(eye.usesSkinShading && !eye.scattersInScreenSpace)
        #expect(!Material().usesSkinShading)
        var blinn = Material.skin()
        blinn.shading = .blinnPhong
        #expect(!blinn.usesSkinShading)
        #expect(SceneRenderer.pipelineKey(for: skin, blending: false, reversedZ: false).skin)
        #expect(!SceneRenderer.pipelineKey(for: Material(), blending: false, reversedZ: false).skin)
        // Tones go from light to deep.
        let luminance = SkinTone.allCases.map { PostProcessMath.luminance($0.linear) }
        #expect(luminance == luminance.sorted(by: >))
    }

    @Test func pushConstantsFitAndFollowTheMode() {
        #expect(MemoryLayout<SkinPushConstants>.size <= maxPushConstantSize)
        let skin = Material.skin()
        let screen = SkinPushConstants(skin, mode: .screen, screenPass: true)
        #expect(screen.scatter.w == 1 && screen.subsurface.w == 1 && screen.lobes.w == 1)
        #expect(SkinPushConstants(skin, mode: .screen, screenPass: false).scatter.w == 0)
        #expect(SkinPushConstants(skin, mode: .preintegrated, screenPass: true).scatter.w == 0)
        let off = SkinPushConstants(skin, mode: .off, screenPass: true)
        #expect(off.subsurface.w == 0 && off.scatter.y == 0 && off.scatter.w == 0)
        #expect(SkinPushConstants(.eye(), mode: .screen, screenPass: true).scatter.z == 1)
        #expect(SubsurfaceMode.environment("off") == .off)
        #expect(SubsurfaceMode.environment("preintegrated") == .preintegrated)
        #expect(SubsurfaceMode.environment("1") == .screen)
        #expect(SubsurfaceMode.environment(nil) == nil)
    }

    @Test func eyeballHasTheEyeLayout() {
        let eye = MeshGeometry.eyeball(radius: 0.012)
        #expect(eye.hasTangents)
        for v in eye.vertices {
            #expect(v.tangent == Vec4(1, 0, 0, 1))
            let d = normalize(v.position)
            let du = v.uv.x - 0.5, dv = v.uv.y - 0.5
            let rho = (du * du + dv * dv).squareRoot() * 2
            if d.z >= 0 {
                // Front half: planar along the gaze.
                #expect(abs(v.uv.x - (0.5 + 0.5 * d.x)) < 1e-4 && abs(v.uv.y - (0.5 + 0.5 * d.y)) < 1e-4)
            } else {
                #expect(rho >= 1 - 1e-3)
            }
        }
        // The cornea bulges at the front pole.
        let front = eye.vertices.max { $0.position.z < $1.position.z }!
        #expect(front.position.z > 0.012 * 1.05)
        // Triangles face outward.
        for i in stride(from: 0, to: eye.indices.count, by: 3) {
            let a = eye.vertices[Int(eye.indices[i])].position, b = eye.vertices[Int(eye.indices[i + 1])].position
            let c = eye.vertices[Int(eye.indices[i + 2])].position
            let n = cross(b - a, c - a)
            if length(n) > 1e-12 { #expect(dot(n, a + b + c) > 0) }
        }
    }
}
