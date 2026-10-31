import Foundation
import Testing
@testable import Engine
#if canImport(QuartzCore)
import QuartzCore
#endif

/// Compute passes, storage resources, indirect draws and the ordering between compute and
/// render work, on every backend this build has (see `TestDevices`).
@MainActor
@Suite(.serialized) struct ComputeTests {
    private func shader(compute name: String) throws -> ShaderSource {
        try ShaderSource.load(compute: name, bundle: .module, subdirectory: "Resources/Shaders")
    }

    @Test func dispatchesWriteABufferInOrderAndItIsReadBack() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader(compute: "test_fill"))
            #expect(pipeline.workgroupSize == ComputeSize(64))
            let count = 1000
            let buffer = try device.makeBuffer(length: count * 4, usage: .storage)
            var values: [UInt32] = []
            try frames.run { frame in
                frame.computePass(label: "fill") { pass in
                    pass.setPipeline(pipeline)
                    pass.setStorageBuffer(buffer, index: 0)
                    // The second dispatch reads what the first one wrote.
                    pass.setPushConstants(SIMD4<UInt32>(UInt32(count), 3, 7, 0))
                    pass.dispatch(threads: ComputeSize(count), of: pipeline)
                    pass.setPushConstants(SIMD4<UInt32>(UInt32(count), 2, 1, 1))
                    pass.dispatch(threads: ComputeSize(count), of: pipeline)
                }
                frame.readBack(buffer) { bytes in values = bytes.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) } }
            }
            #expect(values.count == count, "\(device.backend)")
            #expect(values == (0..<UInt32(count)).map { ($0 * 3 + 7) * 2 + 1 }, "\(device.backend)")
        }
    }

    @Test func storageTextureWrittenByOnePassIsSampledByTheNext() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader(compute: "test_image"))
            #expect(pipeline.workgroupSize == ComputeSize(8, 8))
            let size = 20  // not a multiple of the workgroup: the shader skips the extra invocations
            let texture = try device.makeTexture(TextureDescriptor(width: size, height: size, format: .rgba16Float, storage: true))
            let pixels = try device.makeBuffer(length: size * size * 4, usage: .storage)
            let sampler = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .clampToEdge))
            var result: [UInt32] = []
            try frames.run { frame in
                for mode: UInt32 in [0, 1] {
                    frame.computePass(label: "image") { pass in
                        pass.setPipeline(pipeline)
                        pass.setStorageTexture(texture, index: 0)
                        pass.setTexture(texture, index: 1)
                        pass.setSampler(sampler, index: 1)
                        pass.setStorageBuffer(pixels, index: 0)
                        pass.setPushConstants(SIMD4<UInt32>(UInt32(size), UInt32(size), mode, 0))
                        pass.dispatch(threads: ComputeSize(size, size), of: pipeline)
                    }
                }
                frame.readBack(pixels) { bytes in result = bytes.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) } }
            }
            let expected = (0..<size * size).map { i -> UInt32 in
                func unorm(_ v: Float) -> UInt32 { UInt32((v * 255).rounded()) }
                let x = Float(i % size) / 64, y = Float(i / size) / 64
                return unorm(x) | unorm(y) << 8 | unorm(0.25) << 16 | 255 << 24
            }
            #expect(result == expected, "\(device.backend)")
        }
    }

    /// Compute writes vertices and draw arguments that a render pass draws indirectly (read after
    /// write), then overwrites them for a second render pass (write after read), in one frame.
    @Test func computeOutputFeedsIndirectDrawsInOrder() throws {
        try TestDevices.forEachBackend { device, frames in
            let fill = try device.makeComputePipeline(shader: shader(compute: "test_indirect"))
            var descriptor = PipelineDescriptor(
                shader: try ShaderSource.load(named: "test_storage_draw", bundle: .module, subdirectory: "Resources/Shaders"),
                vertexLayout: .none)
            descriptor.cullMode = .none
            descriptor.depthTest = false
            descriptor.depthWrite = false
            let draw = try device.makePipeline(descriptor)
            let positions = try device.makeBuffer(length: 6 * 16, usage: .storage)
            let arguments = try device.makeBuffer(length: MemoryLayout<DrawIndirectArguments>.size, usage: .storage)
            let targets = try (0..<2).map { _ in
                try device.makeRenderTarget(RenderTargetDescriptor(width: 32, height: 32, multisampled: false))
            }
            var images: [Image?] = [nil, nil]
            var drawnArguments: DrawIndirectArguments?
            try frames.run { frame in
                for (i, half) in [(Float(-1), Float(0)), (0, 1)].enumerated() {
                    frame.computePass(label: "vertices") { pass in
                        pass.setPipeline(fill)
                        pass.setStorageBuffer(positions, index: 0)
                        pass.setStorageBuffer(arguments, index: 1)
                        pass.setPushConstants(SIMD2<Float>(half.0, half.1))
                        pass.dispatch(groups: ComputeSize(1))
                    }
                    frame.renderPass(into: targets[i], clearColor: Vec4(0, 0, 0, 1)) { pass in
                        pass.setPipeline(draw)
                        pass.setStorageBuffer(positions, index: 0)
                        pass.setPushConstants(Vec4(1, 1, 1, 1))
                        pass.drawIndirect(arguments, offset: 0)
                    }
                    device.readBack(targets[i]) { images[i] = $0 }
                }
                frame.readBack(arguments) { bytes in drawnArguments = bytes.withUnsafeBytes { $0.loadUnaligned(as: DrawIndirectArguments.self) } }
            }
            #expect(drawnArguments == DrawIndirectArguments(vertexCount: 6, instanceCount: 1))
            for (i, image) in images.enumerated() {
                let image = try #require(image)
                // Target 0 has the left half white, target 1 the right half.
                let left = image.pixel(x: 8, y: 16), right = image.pixel(x: 24, y: 16)
                #expect(left == (i == 0 ? [255, 255, 255, 255] : [0, 0, 0, 255]), "\(device.backend) target \(i)")
                #expect(right == (i == 1 ? [255, 255, 255, 255] : [0, 0, 0, 255]), "\(device.backend) target \(i)")
            }
        }
    }

    @Test func workgroupSizeIsReadFromSPIRV() throws {
        #expect(try shader(compute: "test_fill").spirvCompute.flatMap(ShaderSource.workgroupSize(spirv:)) == ComputeSize(64))
        #expect(ShaderSource.workgroupSize(spirv: [1, 2, 3, 4]) == nil)
        #expect(ComputeSize(1000).groups(of: ComputeSize(64)) == ComputeSize(16))
        #expect(ComputeSize(20, 20).groups(of: ComputeSize(8, 8)) == ComputeSize(3, 3))
    }

    @Test func blendModesMapToTheirFactors() {
        #expect(BlendMode.opaque.factors == nil)
        #expect(BlendMode.alpha.factors == BlendFactors(sourceColor: .sourceAlpha, destinationColor: .oneMinusSourceAlpha,
                                                        sourceAlpha: .one, destinationAlpha: .oneMinusSourceAlpha))
        #expect(BlendMode.premultipliedAlpha.factors == BlendFactors(sourceColor: .one, destinationColor: .oneMinusSourceAlpha,
                                                                     sourceAlpha: .one, destinationAlpha: .oneMinusSourceAlpha))
        #expect(BlendMode.additive.factors == BlendFactors(sourceColor: .sourceAlpha, destinationColor: .one,
                                                           sourceAlpha: .zero, destinationAlpha: .one))
        #expect(BlendMode.multiply.factors == BlendFactors(sourceColor: .destinationColor, destinationColor: .zero,
                                                           sourceAlpha: .zero, destinationAlpha: .one))

        // `alphaBlending` stays source-compatible: it reads and writes `blendMode`.
        var descriptor = PipelineDescriptor(shader: ShaderSource(), vertexLayout: .none)
        #expect(descriptor.blendMode == .opaque && !descriptor.alphaBlending)
        descriptor.alphaBlending = true
        #expect(descriptor.blendMode == .alpha)
        descriptor.blendMode = .additive
        #expect(!descriptor.alphaBlending)
        descriptor.alphaBlending = false
        #expect(descriptor.blendMode == .opaque)

        #expect(SpriteBlend.additive.blendMode == .additive && SpriteBlend.alpha.blendMode == .alpha)
        #if canImport(Metal) && canImport(AppKit)
        #expect([BlendFactor.zero, .one, .sourceAlpha, .oneMinusSourceAlpha, .destinationColor].map(\.metal)
                == [.zero, .one, .sourceAlpha, .oneMinusSourceAlpha, .destinationColor])
        #endif
        #if ENGINE_VULKAN
        // VK_BLEND_FACTOR_ZERO, ONE, SRC_ALPHA, ONE_MINUS_SRC_ALPHA, DST_COLOR
        #expect([BlendFactor.zero, .one, .sourceAlpha, .oneMinusSourceAlpha, .destinationColor].map(\.vulkan.rawValue)
                == [0, 1, 6, 7, 4])
        #endif
    }

    /// r8, r16f, rg16f and r32f storage textures: written by one compute pass, read by the next
    /// (sampled with texelFetch, and r8 also with imageLoad).
    @Test func singleAndTwoChannelStorageFormatsRoundTrip() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader(compute: "test_formats"))
            let size = 12  // texel i holds i / 255 in r8: up to 143 fits
            let textures = try [TextureFormat.r8Unorm, .r16Float, .rg16Float, .r32Float].map {
                try device.makeTexture(TextureDescriptor(width: size, height: size, format: $0, storage: true))
            }
            #expect(textures.map(\.format) == [.r8Unorm, .r16Float, .rg16Float, .r32Float])
            let results = try device.makeBuffer(length: size * size * 6 * 4, usage: .storage)
            var values: [Float] = []
            try frames.run { frame in
                for mode: UInt32 in [0, 1] {
                    frame.computePass(label: "formats") { pass in
                        pass.setPipeline(pipeline)
                        for (i, texture) in textures.enumerated() {
                            pass.setStorageTexture(texture, index: i)
                            pass.setTexture(texture, index: 1 + i)
                        }
                        pass.setStorageBuffer(results, index: 0)
                        pass.setPushConstants(SIMD4<UInt32>(UInt32(size), UInt32(size), mode, 0))
                        pass.dispatch(threads: ComputeSize(size, size), of: pipeline)
                    }
                }
                frame.readBack(results) { bytes in values = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
            }
            #expect(values.count == size * size * 6, "\(device.backend)")
            for i in 0..<min(size * size, values.count / 6) {
                let f = Float(i), got = Array(values[i * 6..<i * 6 + 6])
                var want = [f / 255, f * 0.5, -f, f * 0.25, f * 1000 + 0.125, f / 255]
                #if os(Linux)
                // lavapipe converts r8 UNORM to float within an ulp of i / 255 (the spec allows it).
                for k in [0, 5] where abs(got[k] - want[k]) <= want[k].ulp { want[k] = got[k] }
                #endif
                #expect(got == want, "\(device.backend) texel \(i)")
            }
        }
    }

    @Test func storageTextureFormatsAreChecked() {
        #expect(throws: GraphicsError.self) {
            try TextureDescriptor(width: 4, height: 4, format: .rgba8Srgb, storage: true).validateStorage(maxSize: 16384)
        }
        #expect(throws: GraphicsError.self) {
            try TextureDescriptor(width: 0, height: 4, format: .rgba16Float, storage: true).validateStorage(maxSize: 16384)
        }
        for format in TextureFormat.storageFormats {
            #expect(throws: Never.self) {
                try TextureDescriptor(width: 4, height: 4, format: format, storage: true).validateStorage(maxSize: 16384)
            }
        }
        // The storage-only formats can't be uploaded from the CPU.
        #expect(throws: GraphicsError.self) {
            try TextureFormat.r16Float.validateUpload(byteCount: 32, width: 4, height: 4, maxSize: 16384)
        }
        #expect([TextureFormat.r8Unorm, .r16Float, .rg16Float, .r32Float].map(\.bytesPerPixel) == [1, 2, 4, 4])
    }
}

/// GPU devices for tests: Metal, and Vulkan (on macOS through MoltenVK, presenting to a bare
/// `CAMetalLayer`: a GLFW window would start `NSApplication`, which stops the run loop the test
/// runner drains; elsewhere a hidden window).
@MainActor
enum TestDevices {
    /// Runs `body` with each available device; it is idle (readbacks delivered) afterwards.
    static func forEachBackend(_ body: (RenderDevice, TestFrames) throws -> Void) throws {
        #if canImport(Metal) && canImport(AppKit)
        let metal = try MetalRenderDevice(layer: CAMetalLayer(), sampleCount: 1)
        try body(metal, TestFrames(device: metal, size: (64, 64)))
        metal.waitIdle()
        #endif
        #if ENGINE_VULKAN
        let (vulkan, size) = try vulkanDevice()
        try body(vulkan, TestFrames(device: vulkan, size: size))
        vulkan.waitIdle()
        #endif
    }

    #if ENGINE_VULKAN
    /// One Vulkan device for the whole run.
    private static var vulkan: (device: VulkanRenderDevice, surface: VulkanSurfaceProvider)?

    private static func vulkanDevice() throws -> (VulkanRenderDevice, (width: Int, height: Int)) {
        if vulkan == nil {
            #if os(macOS)
            let surface: VulkanSurfaceProvider = MetalLayerSurface(width: 64, height: 64)
            #else
            let surface: VulkanSurfaceProvider = try GLFWWindow(title: "EngineTests", width: 64, height: 64, visible: false)
            #endif
            vulkan = (try VulkanRenderDevice(window: surface, applicationName: "EngineTests", sampleCount: 1), surface)
        }
        return (vulkan!.device, vulkan!.surface.framebufferSize)
    }
    #endif
}

/// Records whole frames on a test device: `body` gets a `Frame`; the screen pass is begun and
/// ended (as the engine does) so the swapchain image is presentable, then the device is idled
/// so buffer readbacks have been delivered when `run` returns.
@MainActor
struct TestFrames {
    let device: RenderDevice
    let size: (width: Int, height: Int)

    func run(_ body: (Frame) throws -> Void) throws {
        guard try device.beginFrame(framebufferSize: size) else {
            Issue.record("\(device.backend) couldn't begin a frame")
            return
        }
        try body(Frame(device: device, counter: CountingRenderPass()))
        _ = device.beginScreenPass(clearColor: Vec4(0, 0, 0, 1), clearDepth: 1)
        device.endPass()
        _ = try device.endFrame()
        device.waitIdle()
    }
}

private extension Image {
    func pixel(x: Int, y: Int) -> [UInt8] {
        let i = (y * width + x) * 4
        return Array(pixels[i..<i + 4])
    }
}
