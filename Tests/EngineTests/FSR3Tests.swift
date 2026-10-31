import Foundation
import Testing
@testable import Engine

/// FSR 3.1 upscaler: option parsing, the constants the host side computes (checked against the
/// SDK's formulas), and the whole pass chain on every backend (same bytes on each).
@MainActor
@Suite(.serialized) struct FSR3Tests {
    @Test func parsesAndDescribesTheUpscaler() {
        #expect(Upscaler("fsr3") == .fsr3())
        #expect(Upscaler("FSR3:0.8") == .fsr3(sharpness: 0.8))
        #expect(Upscaler("fsr3:-1") == nil)
        #expect(Upscaler.fsr3().isTemporal)
        #expect(Upscaler.fsr3().firstStage == .fsr3)
        // It sharpens in its own RCAS pass; the window pass only copies.
        #expect(Upscaler.fsr3(sharpness: 0).rcasSharpness == 0)
        #expect(Upscaler.fsr3().description == "FSR 3 (sharpness 0.4)")
    }

    /// The SDK derives these from near, far and the vertical field of view
    /// (`setupDeviceDepthToViewSpaceDepthParams`); the engine reads them off the projection.
    @Test func depthConversionMatchesTheSDK() {
        let (near, far, fovY, aspect): (Float, Float, Float, Float) = (0.5, 200, .pi / 3.5, 16.0 / 9)
        let cot = 1 / tanf(fovY / 2)
        for reversed in [false, true] {
            var constants = FSR3Constants()
            constants.setProjection(reversed
                ? Mat4.perspective(fovY: fovY, aspect: aspect, near: far, far: near)
                : Mat4.perspective(fovY: fovY, aspect: aspect, near: near, far: far))
            // SDK: min/max swapped for inverted depth, q = max / (min - max); [0] = -q, [1] = q * min.
            let (lo, hi) = reversed ? (far, near) : (near, far)
            let q = hi / (lo - hi)
            let expected = SIMD4<Float>(-q, q * lo, aspect / cot, 1 / cot)
            for i in 0..<4 { #expect(abs(constants.deviceToViewDepth[i] - expected[i]) <= 1e-5 * max(1, abs(expected[i])), "reversed \(reversed) [\(i)]") }
            #expect(abs(constants.tanHalfFOV - aspect / cot) < 1e-5)
            // View distance from device depth: the near plane is `near` away, the far plane `far`.
            func distance(_ d: Float) -> Float { constants.deviceToViewDepth[1] / (d - constants.deviceToViewDepth[0]) }
            #expect(abs(distance(reversed ? 1 : 0) - near) < 1e-4)
            #expect(abs(distance(reversed ? 0 : 1) - far) / far < 1e-4)
        }
    }

    @Test func constantsAdvanceLikeTheSDK() {
        let inputs = TemporalInputs(jitter: Vec2(0.25, -0.125), resetHistory: true)
        let first = FSR3Constants.next(after: nil, render: (1280, 720), output: (2560, 1440), inputs: inputs, exposure: 1, reset: true)
        #expect(first.frameIndex == 0)
        #expect(first.renderSize == SIMD2(1280, 720) && first.upscaleSize == SIMD2(2560, 1440))
        // No previous frame: "previous" values are this frame's (the SDK's zeros would divide by zero).
        #expect(first.previousFrameRenderSize == first.renderSize && first.previousFrameJitter == inputs.jitter)
        #expect(first.downscaleFactor == Vec2(0.5, 0.5))
        #expect(first.jitterSequenceLength == 32)  // 8 * 2^2, ffxFsr3UpscalerGetJitterPhaseCount
        #expect(first.motionVectorScale == Vec2(1, 1) && first.deltaPreExposure == 1 && first.exposure == 1)
        #expect(first.accumulationAddedPerFrame == 1.0 / 3.0 && first.minDisocclusionAccumulation == -1.0 / 3.0)

        let moved = TemporalInputs(jitter: Vec2(-0.375, 0.0625), resetHistory: false)
        let second = FSR3Constants.next(after: first, render: (1280, 720), output: (2560, 1440), inputs: moved, exposure: 1, reset: false)
        #expect(second.frameIndex == 1)
        #expect(second.previousFrameJitter == first.jitter && second.jitter == moved.jitter)
        // A new phase count is approached one step per frame.
        let resized = FSR3Constants.next(after: second, render: (1280, 720), output: (3840, 2160), inputs: moved, exposure: 1, reset: false)
        #expect(resized.jitterSequenceLength == 33 && resized.previousFrameUpscaleSize == SIMD2(2560, 1440))
        #expect(FSR3Constants.next(after: resized, render: (1280, 720), output: (3840, 2160), inputs: moved, exposure: 1, reset: true)
                    .jitterSequenceLength == 72)
        #expect(FSR3Constants.jitterPhaseCount(renderWidth: 1706, outputWidth: 2560) == 18)
    }

    /// The push-constant block must match `cbFSR3Upscaler` in fsr3_callbacks.glsl byte for byte.
    @Test func pushConstantLayoutMatchesTheShaders() {
        #expect(MemoryLayout<FSR3PushConstants>.size == 128)
        #expect(MemoryLayout<FSR3PushConstants>.size <= maxPushConstantSize)
        #expect(MemoryLayout<FSR3PushConstants>.offset(of: \.deviceToViewDepth) == 32)
        #expect(MemoryLayout<FSR3PushConstants>.offset(of: \.jitter) == 48)
        #expect(MemoryLayout<FSR3PushConstants>.offset(of: \.tanHalfFOV) == 72)
        #expect(MemoryLayout<FSR3PushConstants>.offset(of: \.exposure) == 112)
        #expect(MemoryLayout<FSR3PushConstants>.offset(of: \.passConfig) == 120)
    }

    @Test func spdAndRcasSetup() {
        // ffxSpdSetup: one workgroup per 64x64 tile, floor(log2(max side)) levels (capped by the pass).
        let spd = FSR3SpdConstants(render: (1280, 720), maxMips: 3)
        #expect(FSR3SpdConstants.workgroups(render: (1280, 720)) == ComputeSize(20, 12))
        #expect(spd.numWorkGroups == 240 && spd.mips == 3 && spd.workGroupOffset == .zero)
        #expect(FSR3SpdConstants(render: (1280, 720), maxMips: 12).mips == 10)
        #expect(FSR3SpdConstants(render: (5, 3), maxMips: 3).mips == 2)
        // FsrRcasCon: exp2(-stops) as float bits, and as two halves.
        let rcas = FSR3RcasConstants(sharpness: 1)
        #expect(rcas.config == SIMD4(Float(0.5).bitPattern, 0x3800_3800, 0, 0))
    }

    /// The whole chain on a small static image: the output converges to the upsampled input and is
    /// the same, bit for bit, on every backend.
    @Test func upscalesAndMatchesAcrossBackends() throws {
        let render = (width: 48, height: 32), output = (width: 96, height: 64)
        var color: [UInt8] = []
        for y in 0..<render.height {
            for x in 0..<render.width {
                // A smooth gradient with a hard vertical edge in the middle.
                color += [UInt8(x * 5), UInt8(y * 7), x < render.width / 2 ? 40 : 220, 255]
            }
        }
        let depth = Half.encode([Float](repeating: 0.5, count: render.width * render.height * 4))
        let motion = Half.encode([Float](repeating: 0, count: render.width * render.height * 4))
        var results: [(GraphicsBackend, [SIMD4<Float>])] = []
        try TestDevices.forEachBackend { device, frames in
            let fsr3 = try FSR3Upscaler(device: device)
            let copy = try device.makeComputePipeline(
                shader: ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders"))
            let colorTexture = try device.makeTexture(pixels: color, width: render.width, height: render.height, format: .rgba8Unorm)
            let depthTexture = try device.makeTexture(pixels: depth, width: render.width, height: render.height, format: .rgba16Float)
            let motionTexture = try device.makeTexture(pixels: motion, width: render.width, height: render.height, format: .rgba16Float)
            let buffer = try device.makeBuffer(length: output.width * output.height * 16, usage: .storage)
            var pixels: [SIMD4<Float>] = []
            for frame in 0..<12 {
                try frames.run { recorder in
                    let inputs = FSR3Inputs(
                        color: colorTexture, depth: depthTexture, motion: motionTexture,
                        temporal: TemporalInputs(jitter: TemporalJitter.offset(frame: frame, phaseCount: 32), resetHistory: frame == 0,
                                                 projection: Mat4.perspective(fovY: 1, aspect: 1.5, near: 0.1, far: 100)),
                        sharpness: 0.4)
                    let upscaled = try fsr3.encode(inputs, output: output, device: device)
                    #expect(upscaled.width == output.width && upscaled.format == .rgba16Float)
                    guard frame == 11 else { return }
                    recorder.computePass(label: "copy") { pass in
                        pass.setPipeline(copy)
                        pass.setTexture(upscaled, index: 1)
                        pass.setStorageBuffer(buffer, index: 0)
                        pass.setPushConstants(SIMD2<UInt32>(UInt32(output.width), UInt32(output.height)))
                        pass.dispatch(threads: ComputeSize(output.width, output.height), of: copy)
                    }
                    recorder.readBack(buffer) { bytes in pixels = bytes.withUnsafeBytes { Array($0.bindMemory(to: SIMD4<Float>.self)) } }
                }
            }
            #expect(pixels.count == output.width * output.height, "\(device.backend)")
            // Away from the edge and the borders the gradient comes through (within RCAS's overshoot).
            for (x, y) in [(10, 10), (30, 40), (70, 20), (85, 50)] {
                let got = pixels[y * output.width + x]
                let source = (x: (x / 2), y: (y / 2))
                let expected = Vec3(Float(source.x * 5), Float(source.y * 7), source.x < render.width / 2 ? 40 : 220) / 255
                #expect(abs(got.x - expected.x) < 0.04 && abs(got.y - expected.y) < 0.04 && abs(got.z - expected.z) < 0.04,
                        "\(device.backend) (\(x), \(y)): \(got) vs \(expected)")
            }
            #expect(pixels.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite }, "\(device.backend)")
            results.append((device.backend, pixels))
        }
        if results.count == 2 {
            #expect(results[0].1 == results[1].1, "\(results[0].0) and \(results[1].0) differ")
        }
    }
}
