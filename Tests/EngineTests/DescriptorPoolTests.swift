import Foundation
import Testing
@testable import Engine

// Vulkan descriptor pools that grow on demand: the long-lived pool list (sets 0 and 1: a dynamic
// uniform buffer per transient-ring chunk, a combined image sampler per depth texture / target)
// and the per-frame arenas (set 2), far past the single pool's old limits (1280 sets, 1024
// dynamic uniform buffers, 256 combined image samplers). Run with ENGINE_VULKAN_VALIDATION=1
// (and the layer on VK_LAYER_PATH) to check the allocations under the validation layer too.

@Suite struct DescriptorPoolTests {
    #if ENGINE_VULKAN
    /// Tiny pools (4 sets each) on the test device: thousands of sets of both long-lived
    /// layouts, freed into holes and reused, a pool added only when every pool is full.
    @MainActor @Test func poolListGrowsFreesIntoItsPoolsAndReuses() throws {
        try TestDevices.forEachBackend { device, _ in
            guard let vulkan = device as? VulkanRenderDevice else { return }
            let pools = VulkanDescriptorPools(device: vulkan.device, setsPerPool: 4)
            defer { pools.destroy() }
            var sets: [OpaquePointer] = []  // VkDescriptorSet
            for i in 0..<3000 {
                sets.append(try pools.allocate(layout: i % 3 == 0 ? vulkan.textureSetLayout : vulkan.uniformSetLayout))
            }
            #expect(pools.liveSetCount == 3000)
            #expect(pools.poolCount == 750)
            #expect(Set(sets).count == 3000)
            // Free every other set: the holes take the next 1500 without a new pool.
            for (i, set) in sets.enumerated() where i % 2 == 0 { pools.free(set) }
            #expect(pools.liveSetCount == 1500)
            for i in 0..<1500 {
                _ = try pools.allocate(layout: i % 2 == 0 ? vulkan.textureSetLayout : vulkan.uniformSetLayout)
            }
            #expect(pools.poolCount == 750 && pools.liveSetCount == 3000)
            // Full again: the next one adds a pool.
            _ = try pools.allocate(layout: vulkan.uniformSetLayout)
            #expect(pools.poolCount == 751)
        }
    }

    /// Through the device: 1500 depth textures (a set-1 descriptor each) and a frame whose
    /// compute pass rebinds a texture for each of 1200 dispatches (a set-2 descriptor each,
    /// several arena pools), then releasing and recreating the textures reuses the pools.
    @MainActor @Test func deviceAllocatesFarPastTheOldSinglePool() throws {
        let shader = try ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders")
        try TestDevices.forEachBackend { device, frames in
            guard device.backend == .vulkan else {
                #expect(device.descriptorPoolCount == nil)
                return
            }
            let before = try #require(device.descriptorPoolCount)
            var textures = try (0..<1500).map { _ in try device.makeTexture(TextureDescriptor(width: 4, height: 4, format: .depth32Float)) }
            let grown = try #require(device.descriptorPoolCount)
            #expect(grown >= before + 1500 / 256, "\(before) -> \(grown) pools")

            let pipeline = try device.makeComputePipeline(shader: shader)
            let colors = try (0..<2).map { i in
                try device.makeTexture(pixels: [UInt8](repeating: UInt8(i * 200), count: 16 * 4), width: 4, height: 4, format: .rgba8Unorm)
            }
            let results = try device.makeBuffer(length: 4 * 4 * 16, usage: .storage)
            var values: [Float] = []
            // One frame per frame slot (each has its own arena).
            @MainActor func rebindFrames() throws {
                for _ in 0..<4 {
                    try frames.run { frame in
                        frame.computePass(label: "rebind") { pass in
                            pass.setPipeline(pipeline)
                            pass.setStorageBuffer(results, index: 0)
                            pass.setPushConstants(SIMD2<UInt32>(4, 4))
                            for i in 0..<1200 {
                                pass.setTexture(colors[i % 2], index: 1)
                                pass.dispatch(threads: ComputeSize(4, 4), of: pipeline)
                            }
                        }
                        frame.readBack(results) { bytes in values = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
                    }
                }
            }
            try rebindFrames()
            // The last dispatch (1199, odd) read the second texture.
            #expect(values.count == 64 && values.allSatisfy { abs($0 - 200.0 / 255) < 1e-6 })
            let afterFrame = try #require(device.descriptorPoolCount)
            #expect(afterFrame >= grown + 1200 / 256, "\(grown) -> \(afterFrame) pools")

            // Released textures return their sets (after the frames that could use them); new
            // ones fill the holes instead of adding pools, and the arenas are reused.
            textures.removeAll()
            for _ in 0..<4 { try frames.run { _ in } }
            textures = try (0..<1500).map { _ in try device.makeTexture(TextureDescriptor(width: 4, height: 4, format: .depth32Float)) }
            try rebindFrames()
            #expect(device.descriptorPoolCount == afterFrame)
            textures.removeAll()
            for _ in 0..<4 { try frames.run { _ in } }
        }
    }
    #endif
}
