import Testing
@testable import Engine

private func approx(_ a: Vec4, _ b: Vec4, _ eps: Float = 1e-5) -> Bool {
    ((a - b) * (a - b)).sum() < eps
}

@Test func perspectiveMapsNearAndFarToZeroAndOne() {
    let p = Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 0.1, far: 100)
    let near = p * Vec4(0, 0, -0.1, 1)
    let far = p * Vec4(0, 0, -100, 1)
    #expect(abs(near.z / near.w) < 1e-5)
    #expect(abs(far.z / far.w - 1) < 1e-5)
}

@Test func orthographicMapsBoxToClipVolume() {
    let o = Mat4.orthographic(left: -2, right: 4, bottom: -1, top: 3, near: 1, far: 11)
    #expect(approx(o * Vec4(-2, -1, -1, 1), Vec4(-1, -1, 0, 1)))
    #expect(approx(o * Vec4(4, 3, -11, 1), Vec4(1, 1, 1, 1)))
}

@Test func lookAtPutsTargetOnNegativeZ() {
    let v = Mat4.lookAt(eye: Vec3(3, 4, 5), target: Vec3(1, 1, 1))
    let target = v * Vec4(1, 1, 1, 1)
    #expect(abs(target.x) < 1e-5 && abs(target.y) < 1e-5 && target.z < 0)
}

@Test func rotationMatchesRightHandRule() {
    // +90° around Z turns +X into +Y.
    let r = Mat4.rotation(angle: .pi / 2, axis: Vec3(0, 0, 1))
    #expect(approx(r * Vec4(1, 0, 0, 0), Vec4(0, 1, 0, 0)))
}

@Test func matrixProductComposesRightToLeft() {
    let m = Mat4.translation(Vec3(1, 2, 3)) * Mat4.scale(Vec3(repeating: 2))
    #expect(approx(m * Vec4(1, 1, 1, 1), Vec4(3, 4, 5, 1)))
    #expect(MemoryLayout<Mat4>.size == 64)
}

@Test func pngHasValidSignatureAndSize() {
    let image = Image(width: 2, height: 2, pixels: [UInt8](repeating: 255, count: 16))
    let png = [UInt8](image.pngData())
    #expect(png.prefix(8) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
}

@MainActor @Test func inputTracksEdges() {
    let input = Input()
    input.setKey(.a, down: true)
    #expect(input.wasPressed(.a) && input.isDown(.a))
    input.beginFrame()
    input.setKey(.a, down: true)
    #expect(!input.wasPressed(.a) && input.isDown(.a))
    input.setKey(.a, down: false)
    #expect(input.wasReleased(.a) && !input.isDown(.a))
}

@MainActor @Test func transientRingReusesChunksAfterReset() throws {
    var chunksMade = 0
    var storage: [UnsafeMutableRawPointer] = []
    defer { storage.forEach { $0.deallocate() } }
    let ring = TransientRing<Int>(minimumChunkSize: 64) { size in
        chunksMade += 1
        let memory = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 16)
        storage.append(memory)
        return (chunksMade, memory)
    }
    let bytes = [UInt8](repeating: 7, count: 40)
    let a = try bytes.withUnsafeBytes { try ring.upload($0) }
    let b = try bytes.withUnsafeBytes { try ring.upload($0) }  // doesn't fit: new chunk
    #expect(a.chunk == 1 && b.chunk == 2 && b.offset == 0)
    #expect(storage[0].load(fromByteOffset: 39, as: UInt8.self) == 7)

    ring.reset()
    let c = try bytes.withUnsafeBytes { try ring.upload($0) }
    #expect(c.chunk == 1 && c.offset == 0 && chunksMade == 2)

    let big = [UInt8](repeating: 1, count: 500)  // larger than a chunk: dedicated chunk
    let d = try big.withUnsafeBytes { try ring.upload($0) }
    #expect(d.chunk == 3 && chunksMade == 3)
}

@Test func renderResolutionParsesPresetsAndCustomSizes() {
    #expect(RenderResolution("native") == .native)
    #expect(RenderResolution("144p") == .fixed(width: 256, height: 144))
    #expect(RenderResolution("4K") == .fixed(width: 3840, height: 2160))
    #expect(RenderResolution("16k") == .fixed(width: 15360, height: 8640))
    #expect(RenderResolution("2880p") == .fixed(width: 5120, height: 2880))
    #expect(RenderResolution("32k") == .fixed(width: 30720, height: 17280))
    #expect(RenderResolution("1024x768") == .fixed(width: 1024, height: 768))
    #expect(RenderResolution("0x5") == nil)
    #expect(RenderResolution("huge") == nil)
}

@Test func scaledResolutionsFollowTheWindow() {
    #expect(RenderResolution("performance") == .scaled(2))
    #expect(RenderResolution("ultra-performance") == .scaled(3))
    #expect(RenderResolution("1.5x") == .scaled(1.5))
    #expect(RenderResolution("0.5x") == nil)
    let window = (width: 2560, height: 1440)
    #expect(RenderResolution.scaled(1.5).size(window: window)! == (1707, 960))
    #expect(RenderResolution.fixed(width: 640, height: 360).size(window: window)! == (640, 360))
    #expect(RenderResolution.native.size(window: window) == nil)
    #expect(RenderResolution.scaled(2).size == nil)  // depends on the window
}

@Test func upscalerParsesNamesAndSharpness() {
    #expect(Upscaler("FSR1") == .fsr1())
    #expect(Upscaler("fsr1:0.5") == .fsr1(sharpness: 0.5))
    #expect(Upscaler("metalfx") == .metalFXSpatial)
    #expect(Upscaler("fsr1:-1") == nil)
    #expect(Upscaler.fsr1(sharpness: 1).rcasSharpness == 0.5)
    #expect(Upscaler.metalFXSpatial.rcasSharpness == 0)
}

@Test func letterboxRectIsPixelAlignedAndCentered() {
    // Wider window: pillarbox.
    #expect(letterboxRect(image: (1280, 720), window: (3000, 1440)) == (220, 0, 2560, 1440))
    // Taller window: letterbox.
    #expect(letterboxRect(image: (1920, 1080), window: (1280, 1024)) == (0, 152, 1280, 720))
    // Same aspect: fills the window.
    #expect(letterboxRect(image: (1707, 960), window: (2560, 1440)) == (0, 0, 2560, 1440))
}

@Test func msaaIsReducedToFitTheBudget() {
    #expect(RenderResolution.native.affordableSampleCount(8) == 8)
    #expect(RenderResolution("4k")!.affordableSampleCount(8) == 8)
    #expect(RenderResolution("16k")!.affordableSampleCount(8) == 4)
}

@Test func letterboxKeepsAspectRatio() {
    #expect(letterboxScale(image: (1920, 1080), window: (1920, 1080)) == Vec2(1, 1))
    #expect(letterboxScale(image: (1000, 1000), window: (2000, 1000)) == Vec2(0.5, 1))
    #expect(letterboxScale(image: (2000, 1000), window: (1000, 1000)) == Vec2(1, 0.5))
}

@MainActor @Test func overlayShowsRenderAndOutputResolution() {
    #expect(DebugOverlay.resolutionLines(window: (2560, 1440), render: nil, upscaler: .fsr1()) == ["NATIVE 2560X1440"])
    #expect(DebugOverlay.resolutionLines(window: (2560, 1440), render: (1280, 720), upscaler: .metalFXSpatial) == [
        "RENDER 1280X720 TO 2560X1440 (2.00X)", "UPSCALER MetalFX spatial",
    ])
    #expect(DebugOverlay.resolutionLines(window: (2560, 1600), render: (15360, 8640), upscaler: .bilinear) == [
        "RENDER 15360X8640 TO 2560X1440 (0.17X)", "UPSCALER bilinear (DOWNSCALING)", "WINDOW 2560X1600 (LETTERBOXED)",
    ])
}
