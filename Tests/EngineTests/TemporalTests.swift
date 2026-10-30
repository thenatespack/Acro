import Testing
@testable import Engine

@Test func haltonMatchesKnownValues() {
    #expect((1...4).map { TemporalJitter.halton($0, base: 2) } == [0.5, 0.25, 0.75, 0.125])
    let base3 = (1...4).map { TemporalJitter.halton($0, base: 3) }
    let expected: [Float] = [1.0 / 3, 2.0 / 3, 1.0 / 9, 4.0 / 9]
    #expect(zip(base3, expected).allSatisfy { abs($0 - $1) < 1e-6 })
}

@Test func jitterStaysInsideThePixelAndRepeats() {
    let phases = 8
    let offsets = (0..<phases).map { TemporalJitter.offset(frame: $0, phaseCount: phases) }
    #expect(offsets.allSatisfy { $0.x >= -0.5 && $0.x < 0.5 && $0.y >= -0.5 && $0.y < 0.5 })
    #expect(Set(offsets.map { [$0.x, $0.y] }).count == phases)
    #expect(TemporalJitter.offset(frame: phases + 3, phaseCount: phases) == offsets[3])
    // Over a cycle the samples average out near the pixel center.
    let mean = offsets.reduce(Vec2.zero, +) / Float(phases)
    #expect(abs(mean.x) < 0.1 && abs(mean.y) < 0.1)
}

@Test func jitterPhaseCountGrowsWithTheUpscaleFactor() {
    #expect(TemporalJitter.phaseCount(renderWidth: 1920, outputWidth: 1920) == 8)
    #expect(TemporalJitter.phaseCount(renderWidth: 1280, outputWidth: 2560) == 32)
    #expect(TemporalJitter.phaseCount(renderWidth: 1280, outputWidth: 1920) == 18)
    #expect(TemporalJitter.phaseCount(renderWidth: 3840, outputWidth: 1920) == 8)
}

@Test func jitteredProjectionShiftsTheImageByWholePixelsAtEveryDepth() {
    let size = (width: 200, height: 100)
    let projection = Mat4.perspective(fovY: 1, aspect: 2, near: 0.1, far: 100)
    let offset = TemporalJitter.clipOffset(Vec2(1, 1), renderSize: size)
    #expect(offset == Vec2(0.01, -0.02))
    let jittered = projection.jittered(clipOffset: offset)
    for z: Float in [-0.5, -10, -90] {
        let point = Vec4(1, 2, z, 1)
        let a = projection * point, b = jittered * point
        // NDC moves by the offset (1 pixel right, 1 pixel down), and depth is unchanged.
        #expect(abs(b.x / b.w - a.x / a.w - offset.x) < 1e-5)
        #expect(abs(b.y / b.w - a.y / a.w - offset.y) < 1e-5)
        #expect(b.z == a.z && b.w == a.w)
    }
}

@Test func temporalUpscalersParseAndAreFlagged() {
    #expect(Upscaler("taau") == .taau())
    #expect(Upscaler("TAAU:1") == .taau(sharpness: 1))
    #expect(Upscaler("metalfx-temporal") == .metalFXTemporal)
    #expect(Upscaler("metalfx-spatial") == .metalFXSpatial)
    #expect(Upscaler("taau:-1") == nil)
    #expect(Upscaler("metalfx:1") == nil)
    #expect(Upscaler.taau().isTemporal && Upscaler.metalFXTemporal.isTemporal)
    #expect(!Upscaler.fsr1().isTemporal && !Upscaler.metalFXSpatial.isTemporal && !Upscaler.bilinear.isTemporal)
    #expect(Upscaler.taau(sharpness: 1).rcasSharpness == 0.5)
    #expect(Upscaler.metalFXTemporal.rcasSharpness == 0)
    #expect(Upscaler.taau(sharpness: 2).firstStage == .taau)
}

@Test func taauConstantsMatchTheShaderLayout() {
    // 6 x vec2/ivec2 + 2 floats, as declared in taau.metal / taau.frag.
    #expect(MemoryLayout<TaauConstants>.size == 56)
    #expect(MemoryLayout<TaauConstants>.size <= maxPushConstantSize)
    let constants = TaauConstants(
        input: (1280, 720), output: (2560, 1440), inputs: TemporalInputs(jitter: Vec2(0.25, -0.125), reversedDepth: true),
        reset: false)
    #expect(constants.inputPerOutput == Vec2(0.5, 0.5))
    #expect(constants.outputPerInput == Vec2(2, 2))
    #expect(constants.inputMax == SIMD2(1279, 719))
    #expect(constants.outputMax == SIMD2(2559, 1439))
    #expect(constants.reset == 0 && constants.reversedDepth == 1)
}
