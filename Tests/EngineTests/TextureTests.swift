import Testing
@testable import Engine

@Test func mipLevelCountIsLog2OfTheLargestSidePlusOne() {
    #expect(MipChain.levelCount(width: 1, height: 1) == 1)
    #expect(MipChain.levelCount(width: 2, height: 2) == 2)
    #expect(MipChain.levelCount(width: 256, height: 256) == 9)
    #expect(MipChain.levelCount(width: 256, height: 4) == 9)
    #expect(MipChain.levelCount(width: 5, height: 3) == 3)
    #expect(MipChain.levelCount(width: 1000, height: 1) == 10)
}

@Test func mipSizesHalveRoundingDownAndStopAtOne() {
    #expect(MipChain.size(width: 5, height: 3, level: 1) == (2, 1))
    #expect(MipChain.size(width: 5, height: 3, level: 2) == (1, 1))
    #expect(MipChain.size(width: 256, height: 4, level: 8) == (1, 1))
}

@Test func generatedChainMatchesLevelCountAndSizes() {
    let pixels = [UInt8](repeating: 100, count: 5 * 3 * 4)
    let chain = MipChain.generate(pixels: pixels, width: 5, height: 3, srgb: false)
    #expect(chain.count == 3)
    #expect(chain.map { [$0.width, $0.height] } == [[5, 3], [2, 1], [1, 1]])
    #expect(chain.allSatisfy { $0.pixels.count == $0.width * $0.height * 4 })
    #expect(chain.allSatisfy { $0.pixels.allSatisfy { $0 == 100 } })
}

@Test func linearBoxFilterAveragesAndSRGBAveragesInLinearLight() {
    // A 2x2 image: black, white, black, white.
    var pixels = [UInt8](repeating: 255, count: 16)
    for i in [0, 2] { pixels.replaceSubrange(i * 4..<i * 4 + 4, with: [0, 0, 0, 255]) }
    let linear = MipChain.generate(pixels: pixels, width: 2, height: 2, srgb: false)
    #expect(linear[1].pixels == [128, 128, 128, 255])
    // Half-intensity in linear light is ~188 once sRGB-encoded; alpha stays linear.
    let srgb = MipChain.generate(pixels: pixels, width: 2, height: 2, srgb: true)
    #expect(abs(Int(srgb[1].pixels[0]) - 188) <= 1)
    #expect(srgb[1].pixels[3] == 255)
}

@Test func uploadValidationRejectsBadArguments() throws {
    try TextureFormat.rgba8Srgb.validateUpload(byteCount: 16, width: 2, height: 2, maxSize: 16)
    #expect(throws: GraphicsError.self) { try TextureFormat.depth32Float.validateUpload(byteCount: 16, width: 2, height: 2, maxSize: 16) }
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba8Unorm.validateUpload(byteCount: 15, width: 2, height: 2, maxSize: 16) }
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba8Unorm.validateUpload(byteCount: 0, width: 0, height: 2, maxSize: 16) }
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba8Unorm.validateUpload(byteCount: 16, width: 32, height: 2, maxSize: 16) }
}

@Test func samplerDescriptorsHashByValue() {
    let a = SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat)
    #expect(a == SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear, addressMode: .repeat))
    #expect(a != SamplerDescriptor(filter: .linear, mipFilter: .nearest, addressMode: .repeat))
    #expect(a != SamplerDescriptor(minFilter: .nearest, magFilter: .linear, mipFilter: .linear, addressMode: .repeat))
    #expect(Set([a, a, SamplerDescriptor(filter: .nearest)]).count == 2)
}

@MainActor private final class FakeSampler: GPUSampler {
    let descriptor: SamplerDescriptor
    init(_ descriptor: SamplerDescriptor) { self.descriptor = descriptor }
}

@MainActor @Test func samplerCacheReusesIdenticalDescriptors() {
    let cache = SamplerCache<FakeSampler>()
    var created = 0
    let make = { (descriptor: SamplerDescriptor) -> FakeSampler in
        created += 1
        return FakeSampler(descriptor)
    }
    let repeating = SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat)
    let first = cache.sampler(for: repeating, make: make)
    let second = cache.sampler(for: SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat), make: make)
    let other = cache.sampler(for: SamplerDescriptor(filter: .nearest), make: make)
    #expect(first === second)
    #expect(first !== other)
    #expect(created == 2)
    #expect(cache.count == 2)
}
