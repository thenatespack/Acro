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
