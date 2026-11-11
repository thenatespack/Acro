import Foundation
import Testing
@testable import Engine
#if ENGINE_VULKAN
import CVulkan
#endif

// Creating static buffers and textures doesn't wait for the GPU (Vulkan records the copies into
// an upload batch submitted ahead of the frame; Metal copies on the CPU), and asset loads run as
// background jobs on the job system. On every backend the tests have (see `TestDevices`).

private func copyShader() throws -> ShaderSource {
    try ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders")
}

/// RGBA8 texels of a `size`² texture: texel i is (i, 2i, 255 - i, seed) mod 256.
private func pattern(size: Int, seed: UInt8) -> [UInt8] {
    var texels: [UInt8] = []
    texels.reserveCapacity(size * size * 4)
    for i in 0..<size * size {
        let r = UInt8(i & 255)
        let g = UInt8((i * 2) & 255)
        let b = UInt8(255 - (i & 255))  // `&` binds tighter than `-` in Swift
        texels += [r, g, b, seed]
    }
    return texels
}

/// What `test_copy` writes for `pattern`: unorm floats.
private func expected(size: Int, seed: UInt8) -> [Float] {
    pattern(size: size, seed: seed).map { Float($0) / 255 }
}

/// Records a compute pass copying `texture` (`size`²) into `results` (`size`² vec4s).
@MainActor
private func copy(_ texture: GPUTexture, size: Int, into results: GPUBuffer, pipeline: ComputePipeline, frame: Frame) {
    frame.computePass(label: "copy") { pass in
        pass.setPipeline(pipeline)
        pass.setTexture(texture, index: 1)
        pass.setStorageBuffer(results, index: 0)
        pass.setPushConstants(SIMD2<UInt32>(UInt32(size), UInt32(size)))
        pass.dispatch(threads: ComputeSize(size, size), of: pipeline)
    }
}

private func floats(_ bytes: [UInt8]) -> [Float] {
    bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
}

private func close(_ a: [Float], _ b: [Float]) -> Bool {
    a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 1e-6 }
}

@MainActor
@Suite(.serialized) struct AsyncUploadTests {
    // MARK: GPU resources

    /// A texture and a buffer made in the middle of a frame (between passes and while a pass is
    /// open) are read correctly by the passes after it in the same frame.
    @Test func resourcesCreatedMidFrameAreUsableInTheSameFrame() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: copyShader())
            let size = 8
            let results = try (0..<2).map { _ in try device.makeBuffer(length: size * size * 16, usage: .storage) }
            let target = try device.makeRenderTarget(RenderTargetDescriptor(width: 16, height: 16, multisampled: false))
            var copied: [[Float]] = [[], []]
            var bufferBytes: [UInt8] = []
            let bufferContents = (0..<256).map { UInt8($0) }
            try frames.run { frame in
                // Between passes.
                let first = try device.makeTexture(pixels: pattern(size: size, seed: 1), width: size, height: size, format: .rgba8Unorm)
                copy(first, size: size, into: results[0], pipeline: pipeline, frame: frame)
                // While a render pass is open.
                var second: GPUTexture?
                var buffer: GPUBuffer?
                frame.renderPass(into: target, clearColor: Vec4(0, 0, 0, 1)) { _ in
                    second = try? device.makeTexture(pixels: pattern(size: size, seed: 2), width: size, height: size, format: .rgba8Unorm)
                    buffer = try? device.makeBuffer(bufferContents, usage: .storage)
                }
                copy(try #require(second), size: size, into: results[1], pipeline: pipeline, frame: frame)
                frame.readBack(try #require(buffer)) { bufferBytes = $0 }
                for i in 0..<2 { frame.readBack(results[i]) { copied[i] = floats($0) } }
            }
            #expect(close(copied[0], expected(size: size, seed: 1)), "\(device.backend)")
            #expect(close(copied[1], expected(size: size, seed: 2)), "\(device.backend)")
            #expect(bufferBytes == bufferContents, "\(device.backend)")
        }
    }

    /// A texture made mid-frame from explicit levels (one staging region, a copy per level) has
    /// its level 0 in place.
    @Test func explicitLevelsUploadMidFrame() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: copyShader())
            let size = 8
            let levels = [TextureMipLevel(width: size, height: size, pixels: pattern(size: size, seed: 3)),
                          TextureMipLevel(width: 4, height: 4, pixels: [UInt8](repeating: 9, count: 64)),
                          TextureMipLevel(width: 2, height: 2, pixels: [UInt8](repeating: 9, count: 16)),
                          TextureMipLevel(width: 1, height: 1, pixels: [9, 9, 9, 9])]
            let results = try device.makeBuffer(length: size * size * 16, usage: .storage)
            var copied: [Float] = []
            try frames.run { frame in
                let texture = try device.makeTexture(levels: levels, format: .rgba8Unorm)
                #expect(texture.mipLevelCount == 4)
                copy(texture, size: size, into: results, pipeline: pipeline, frame: frame)
                frame.readBack(results) { copied = floats($0) }
            }
            #expect(close(copied, expected(size: size, seed: 3)), "\(device.backend)")
        }
    }

    /// Thousands of textures and buffers in one frame: none waits for the GPU (no blocking submit
    /// on Vulkan), staging memory is shared in chunks, and every one holds its data.
    @Test func thousandsOfCreationsInOneFrameDontStall() throws {
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: copyShader())
            let size = 4, count = 3000
            let results = try device.makeBuffer(length: size * size * 16, usage: .storage)
            #if ENGINE_VULKAN
            let vulkan = device as? VulkanRenderDevice
            device.waitIdle()
            let blockingBefore = vulkan?.blockingSubmitCount
            let uploadsBefore = vulkan?.uploads.statistics
            #endif
            var textures: [GPUTexture] = []
            var buffers: [GPUBuffer] = []
            var copied: [Float] = []
            var lastBuffer: [UInt8] = []
            try frames.run { frame in
                for i in 0..<count {
                    textures.append(try device.makeTexture(pixels: pattern(size: size, seed: UInt8(i & 255)), width: size, height: size,
                                                           format: .rgba8Unorm))
                    buffers.append(try device.makeBuffer([UInt32(i), UInt32(i * 7)], usage: .vertex))
                }
                #if ENGINE_VULKAN
                if let vulkan, let uploadsBefore {
                    let stats = vulkan.uploads.statistics
                    #expect(stats.openUploads == 2 * count)
                    #expect(stats.uploads - uploadsBefore.uploads == 2 * count)
                    // 3000 x 64 B + 3000 x 16 B (padded) fit one 8 MiB chunk.
                    #expect(stats.chunks <= uploadsBefore.chunks + 1)
                    #expect(vulkan.blockingSubmitCount == blockingBefore)
                }
                #endif
                copy(textures[count - 1], size: size, into: results, pipeline: pipeline, frame: frame)
                frame.readBack(results) { copied = floats($0) }
            }
            #expect(close(copied, expected(size: size, seed: UInt8((count - 1) & 255))), "\(device.backend)")
            // A buffer made in an earlier frame reads back too.
            try frames.run { frame in frame.readBack(buffers[1234]) { lastBuffer = $0 } }
            #expect(lastBuffer == [UInt32(1234), UInt32(1234 * 7)].withUnsafeBytes { Array($0) }, "\(device.backend)")
            #if ENGINE_VULKAN
            if let vulkan {
                #expect(vulkan.uploads.statistics.openUploads == 0)
                #expect(vulkan.uploads.statistics.batchesInFlight == 0)  // given back by `waitIdle`
            }
            #endif
        }
    }

    /// `RenderDevice` is main-actor API, but Vulkan's upload queue is what creation on another
    /// thread would go through: uploads staged and recorded from several threads at once, while
    /// the main thread submits and recycles batches frame after frame, all land.
    @Test func uploadsRecordedFromOtherThreadsWhileFramesRun() throws {
        try TestDevices.forEachBackend { device, frames in
            #if ENGINE_VULKAN
            guard let vulkan = device as? VulkanRenderDevice else { return }
            let threads = 4, perThread = 150
            let buffers = try (0..<threads * perThread).map { _ in try device.makeBuffer(length: 16, usage: .storage) as! VulkanBuffer }
            struct Target: @unchecked Sendable { let buffer: VkBuffer }
            let targets = buffers.map { Target(buffer: $0.buffer) }
            let uploads: VulkanUploadQueue = vulkan.uploads
            final class Errors: @unchecked Sendable {
                let lock = NSLock()
                var messages: [String] = []
            }
            let errors = Errors()
            let group = DispatchGroup()
            for t in 0..<threads {
                DispatchQueue.global().async(group: group) {
                    for k in 0..<perThread {
                        let i = t * perThread + k
                        do {
                            let values = [UInt32(i), UInt32(t), UInt32(k), 0xABCD]
                            // Some big enough for a staging buffer of their own.
                            let length = k % 50 == 0 ? uploads.chunkSize : 16
                            let staging = try uploads.stage(length) { base in
                                values.withUnsafeBytes { base.copyMemory(from: $0.baseAddress!, byteCount: 16) }
                            }
                            try uploads.record(staging) { cmd in
                                var region = VkBufferCopy(srcOffset: VkDeviceSize(staging.offset), dstOffset: 0, size: 16)
                                vkCmdCopyBuffer(cmd, staging.buffer, targets[i].buffer, 1, &region)
                            }
                        } catch {
                            errors.lock.withLock { errors.messages.append("\(error)") }
                        }
                    }
                }
            }
            var frameCount = 0
            while group.wait(timeout: .now()) == .timedOut || frameCount < 2 {
                guard try device.beginFrame(framebufferSize: frames.size) else { continue }
                _ = device.beginScreenPass(clearColor: Vec4(0, 0, 0, 1), clearDepth: 1)
                device.endPass()
                _ = try device.endFrame()
                frameCount += 1
            }
            #expect(errors.messages.isEmpty, "\(errors.messages.prefix(3))")
            var read: [[UInt8]] = Array(repeating: [], count: buffers.count)
            try frames.run { frame in
                for (i, buffer) in buffers.enumerated() { frame.readBack(buffer) { read[i] = $0 } }
            }
            for t in 0..<threads {
                for k in 0..<perThread {
                    let i = t * perThread + k
                    #expect(read[i] == [UInt32(i), UInt32(t), UInt32(k), 0xABCD].withUnsafeBytes { Array($0) }, "upload \(i)")
                }
            }
            let stats = uploads.statistics
            #expect(stats.openUploads == 0 && stats.batchesInFlight == 0 && stats.dedicatedBuffers == 0)
            #endif
        }
    }

    /// Resources dropped before their upload ran (between frames, mid-frame, and while the
    /// frame using them is in flight) are freed once it can't be in use, with their staging memory.
    @Test func resourcesDroppedBeforeTheirUploadRanAreFreed() throws {
        try TestDevices.forEachBackend { device, frames in
            #if ENGINE_VULKAN
            let vulkan = device as? VulkanRenderDevice
            device.waitIdle()
            let liveBefore = vulkan?.deletionQueueCounts.live
            #endif
            let pixels = [UInt8](repeating: 77, count: 64 * 64 * 4)
            // Between frames: made and dropped before any frame submits their copies.
            for _ in 0..<200 {
                _ = try device.makeTexture(pixels: pixels, width: 64, height: 64, format: .rgba8Unorm)
                _ = try device.makeBuffer(bytes: [UInt8](repeating: 1, count: 4096).withUnsafeBytes { $0 }, usage: .vertex)
            }
            // Mid-frame, some big enough for staging buffers of their own.
            try frames.run { _ in
                for i in 0..<50 {
                    let side = i % 10 == 0 ? 1100 : 64
                    _ = try device.makeTexture(pixels: [UInt8](repeating: 5, count: side * side * 4), width: side, height: side,
                                               format: .rgba8Unorm)
                    _ = try device.makeBuffer(length: 1024, usage: .storage)
                    _ = try device.makeTexture(TextureDescriptor(width: 8, height: 8, format: .rgba16Float, storage: true))
                }
            }
            // Kept across a frame submit, dropped while it may be in flight.
            var kept: [GPUTexture] = try (0..<20).map { _ in try device.makeTexture(pixels: pixels, width: 64, height: 64, format: .rgba8Unorm) }
            guard try device.beginFrame(framebufferSize: frames.size) else { return }
            _ = device.beginScreenPass(clearColor: Vec4(0, 0, 0, 1), clearDepth: 1)
            device.endPass()
            _ = try device.endFrame()
            kept.removeAll()
            for _ in 0..<3 { try frames.run { _ in } }
            device.waitIdle()
            #if ENGINE_VULKAN
            if let vulkan, let liveBefore {
                #expect(vulkan.deletionQueueCounts.live == liveBefore)
                #expect(vulkan.deletionQueueCounts.pending == 0)
                let stats = vulkan.uploads.statistics
                #expect(stats.openUploads == 0 && stats.batchesInFlight == 0)
                #expect(stats.dedicatedBuffers == 0)
                #expect(stats.chunks <= 5)  // the one being filled plus at most four idle
            }
            #endif
            #expect(kept.isEmpty)
        }
    }

    // MARK: Job system priorities

    /// Background jobs only run on workers, after queued normal jobs, and never on a thread
    /// waiting in `parallelFor` or a group wait; waiting for one directly still helps run it.
    @Test func backgroundJobsStayOffWaitingThreads() throws {
        let jobs = JobSystem(threadCount: 3)
        defer { jobs.shutdown() }
        final class Log: @unchecked Sendable {
            let lock = NSLock()
            var backgroundOnCaller = 0
            var backgroundRan = 0
        }
        let log = Log()
        let release = DispatchSemaphore(value: 0)
        // Two background jobs that block, so both workers are busy with them.
        let blockers = (0..<2).map { _ in jobs.schedule("blocker", priority: .background) { release.wait() } }
        // More background work queued behind them.
        let queued = (0..<20).map { _ in
            jobs.schedule("queued", priority: .background) {
                log.lock.withLock {
                    log.backgroundRan += 1
                    if Thread.isMainThread { log.backgroundOnCaller += 1 }
                }
            }
        }
        // The caller's loop and group wait finish on their own without touching background work.
        var sums = [Int](repeating: 0, count: 64)
        sums.withUnsafeMutableBufferPointer { out in
            nonisolated(unsafe) let out = out
            jobs.parallelFor(0..<64, batchSize: 4) { range in for i in range { out[i] = i * 2 } }
        }
        #expect(sums == (0..<64).map { $0 * 2 })
        let group = JobGroup()
        for _ in 0..<4 { jobs.schedule("normal", in: group) {} }
        jobs.wait(group)
        #expect(log.lock.withLock { log.backgroundRan } == 0)
        release.signal()
        release.signal()
        // Polled rather than waited for: waiting for a background job helps run background jobs.
        while !(blockers + queued).allSatisfy(\.isComplete) { Thread.sleep(forTimeInterval: 0.001) }
        #expect(log.lock.withLock { log.backgroundRan } == 20)
        #expect(log.lock.withLock { log.backgroundOnCaller } == 0)
        #expect(blockers[0].priority == .background)

        // Inline (no workers), a background job runs at once.
        let inline = JobSystem(threadCount: 1)
        nonisolated(unsafe) var ran = false
        let job = inline.schedule("inline", priority: .background) { ran = true }
        #expect(ran && job.isComplete)
    }

    /// Workers take normal jobs before background ones queued earlier.
    @Test func workersPreferNormalJobs() throws {
        let jobs = JobSystem(threadCount: 2)  // one worker
        defer { jobs.shutdown() }
        final class Order: @unchecked Sendable {
            let lock = NSLock()
            var names: [String] = []
        }
        let order = Order()
        let gate = DispatchSemaphore(value: 0), started = DispatchSemaphore(value: 0)
        let blocker = jobs.schedule("blocker", priority: .background) {
            started.signal()
            gate.wait()
        }
        started.wait()  // the only worker is busy: the next two wait in their queues
        let background = jobs.schedule("background", priority: .background) { order.lock.withLock { order.names.append("background") } }
        let normal = jobs.schedule("normal") { order.lock.withLock { order.names.append("normal") } }
        gate.signal()
        // Not `wait`: a waiting thread would help and could take the background job first.
        while !(blocker.isComplete && background.isComplete && normal.isComplete) { Thread.sleep(forTimeInterval: 0.001) }
        #expect(order.names == ["normal", "background"])
    }
}

// MARK: - Asset loading on jobs

/// Imports `.slow` files: waits for `gate` (if any) and records the order and thread.
private struct GatedImporter: AssetImporter {
    typealias Settings = NoImportSettings
    final class Control: @unchecked Sendable {
        let lock = NSLock()
        var order: [String] = []
        var threads: Set<String> = []
        var onMainThread = 0
        var gates: [String: DispatchSemaphore] = [:]
    }
    let control: Control
    var name: String { "asyncUploadTests.gated" }
    var fileExtensions: [String] { ["slow"] }
    var version: Int { 1 }

    func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let gate = control.lock.withLock { () -> DispatchSemaphore? in
            control.order.append(context.assetPath)
            control.threads.insert(Thread.current.name ?? "?")
            if Thread.isMainThread { control.onMainThread += 1 }
            return control.gates[context.assetPath]
        }
        gate?.wait()
        var asset = ImportedAsset()
        asset.add("material", name: context.assetPath, .material(MaterialAsset()))
        return asset
    }
}

@MainActor
@Suite(.serialized) struct AsyncUploadAssetLoadingTests {
    private func makeProject(files: [String]) throws -> Project {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AsyncUploadTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "AsyncUpload")
        for file in files { try Data(file.utf8).write(to: project.assetsURL.appendingPathComponent(file)) }
        return project
    }

    private func database(_ project: Project, control: GatedImporter.Control, jobs: JobSystem, maxConcurrentLoads: Int) -> AssetDatabase {
        var importers = AssetImporterRegistry()
        importers.register(GatedImporter(control: control))
        let database = AssetDatabase(project: project, importers: importers, jobs: jobs, maxConcurrentLoads: maxConcurrentLoads)
        database.scan()
        return database
    }

    private func spin(_ database: AssetDatabase, until condition: () -> Bool) -> Bool {
        let deadline = Date(timeIntervalSinceNow: 10)
        while Date() < deadline {
            database.pump()
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.002)
        }
        return false
    }

    @Test func loadsRunOnJobWorkersAndReportProgress() throws {
        let files = (0..<6).map { "a\($0).slow" }
        let project = try makeProject(files: files)
        defer { try? FileManager.default.removeItem(at: project.root) }
        let jobs = JobSystem(threadCount: 4)
        defer { jobs.shutdown() }
        let control = GatedImporter.Control()
        let database = database(project, control: control, jobs: jobs, maxConcurrentLoads: 2)
        var reported: [AssetLoadProgress] = []
        database.onLoadProgress = { reported.append($0) }
        let ids = files.map { database.id(forPath: $0)! }
        for id in ids { #expect(database.request(id) == .loading) }
        #expect(database.loadProgress.total == 6 && database.loadProgress.pending == 6)
        #expect(database.loadQueue.runningCount + database.loadQueue.waitingCount <= 6)
        #expect(database.waitForAll(timeout: 10))
        #expect(ids.allSatisfy { database.loadState(of: $0) == .loaded })
        #expect(control.onMainThread == 0)
        #expect(database.loadQueue.jobs === jobs)
        #if os(macOS)  // swift-corelibs-foundation doesn't apply a thread's name set before it starts
        #expect(control.threads.allSatisfy { $0.hasPrefix("Engine job worker") }, "\(control.threads)")
        #endif
        let last = try #require(reported.last)
        #expect(last.completed == 6 && last.total == 6 && last.fraction == 1)
        #expect(reported.map(\.completed) == reported.map(\.completed).sorted())
        #expect(database.loadProgress.isIdle)
    }

    @Test func highPriorityLoadsStartFirstAndCancelledOnesDrop() throws {
        let files = ["block.slow", "b.slow", "c.slow", "d.slow", "e.slow"]
        let project = try makeProject(files: files)
        defer { try? FileManager.default.removeItem(at: project.root) }
        let jobs = JobSystem(threadCount: 3)
        defer { jobs.shutdown() }
        let control = GatedImporter.Control()
        let gate = DispatchSemaphore(value: 0)
        control.gates["block.slow"] = gate
        let database = database(project, control: control, jobs: jobs, maxConcurrentLoads: 1)
        let id = { (path: String) in database.id(forPath: path)! }

        database.request(id("block.slow"))
        #expect(spin(database) { control.lock.withLock { control.order == ["block.slow"] } })  // running, held by the gate
        database.request(id("b.slow"))
        database.request(id("c.slow"))
        database.request(id("d.slow"), priority: .high)
        database.request(id("e.slow"))
        database.request(id("c.slow"), priority: .high)  // already waiting: moves up behind d

        // Cancel one waiting and the running one.
        #expect(database.cancelLoading(id("e.slow")))
        #expect(database.cancelLoading(id("block.slow")))
        #expect(!database.cancelLoading(id("block.slow")))  // already cancelled
        #expect(database.loadState(of: id("e.slow")) == .unloaded)
        #expect(database.loadState(of: id("block.slow")) == .unloaded)
        #expect(database.loadProgress.cancelled == 2 && database.loadProgress.total == 5 && database.loadProgress.pending == 3)

        gate.signal()
        #expect(database.waitForAll(timeout: 10))
        #expect(control.order == ["block.slow", "d.slow", "c.slow", "b.slow"])
        #expect(database.loadState(of: id("block.slow")) == .unloaded)  // its result was dropped
        #expect(database.loadState(of: id("e.slow")) == .unloaded)
        for path in ["b.slow", "c.slow", "d.slow"] { #expect(database.loadState(of: id(path)) == .loaded) }

        // Requested again, a cancelled asset loads.
        #expect(database.request(id("e.slow")) == .loading)
        #expect(database.waitForAll(timeout: 10))
        #expect(database.loadState(of: id("e.slow")) == .loaded)
    }

    /// A load cancelled while it runs and requested again before it finishes keeps that job's
    /// result instead of starting a second import of the same asset.
    @Test func requestingACancelledRunningLoadKeepsItsResult() throws {
        let project = try makeProject(files: ["x.slow"])
        defer { try? FileManager.default.removeItem(at: project.root) }
        let jobs = JobSystem(threadCount: 2)
        defer { jobs.shutdown() }
        let control = GatedImporter.Control()
        let gate = DispatchSemaphore(value: 0)
        control.gates["x.slow"] = gate
        let database = database(project, control: control, jobs: jobs, maxConcurrentLoads: 1)
        let x = try #require(database.id(forPath: "x.slow"))
        database.request(x)
        #expect(spin(database) { control.lock.withLock { control.order.count == 1 } })
        #expect(database.cancelLoading(x))
        #expect(database.request(x) == .loading)
        gate.signal()
        #expect(database.waitForAll(timeout: 10))
        #expect(database.loadState(of: x) == .loaded)
        #expect(control.order == ["x.slow"])
        #expect(database.loadProgress.isIdle)
    }

    /// `cancelAllLoading` empties the queue; nothing more is applied.
    @Test func cancelAllDropsEverything() throws {
        let files = (0..<5).map { "q\($0).slow" }
        let project = try makeProject(files: files)
        defer { try? FileManager.default.removeItem(at: project.root) }
        let jobs = JobSystem(threadCount: 2)
        defer { jobs.shutdown() }
        let control = GatedImporter.Control()
        let gate = DispatchSemaphore(value: 0)
        control.gates["q0.slow"] = gate
        let database = database(project, control: control, jobs: jobs, maxConcurrentLoads: 1)
        let ids = files.map { database.id(forPath: $0)! }
        for id in ids { database.request(id) }
        #expect(spin(database) { control.lock.withLock { control.order.count == 1 } })
        #expect(database.cancelAllLoading() == 5)
        #expect(!database.isLoading)
        gate.signal()
        #expect(spin(database) { database.loadQueue.runningCount == 0 })
        database.pump()
        #expect(ids.allSatisfy { database.loadState(of: $0) == .unloaded })
        #expect(control.order == ["q0.slow"])
    }
}

#if os(macOS)
import QuartzCore

/// The scene renderer builds asset textures' mip chains on job workers and uploads them on a
/// later frame, with the same texture the render-thread path made.
@MainActor
@Suite struct AsyncUploadSceneRendererTests {
    @Test func textureLevelsAreBuiltOnJobsAndMatchTheRenderThreadPath() throws {
        let image = Image(width: 64, height: 32, pixels: (0..<64 * 32 * 4).map { UInt8($0 * 7 & 255) })
        for srgb in [true, false] {
            let texture = TextureAsset(image: image, isSRGB: srgb)
            #expect(PreparedTextureLevels.isWorthPreparing(texture))
            let prepared = PreparedTextureLevels(texture, revision: 3)
            prepared.wait()
            let (levels, format) = try #require(prepared.result)
            let direct = MipChain.generate(pixels: image.pixels, width: 64, height: 32, srgb: srgb)
            #expect(format == (srgb ? .rgba8Srgb : .rgba8Unorm))
            #expect(levels.map(\.pixels) == direct.map(\.pixels) && levels.count == 7)
        }
        let float = FloatImage(width: 4, height: 4, pixels: (0..<64).map { Float($0) / 8 })
        let prepared = PreparedTextureLevels(TextureAsset(floatImage: float), revision: 1)
        prepared.wait()
        let (levels, format) = try #require(prepared.result)
        #expect(format == .rgba16Float)
        #expect(levels.map(\.pixels) == MipChain.generateFloat(pixels: float.pixels, width: 4, height: 4).map(\.pixels))
        #expect(!PreparedTextureLevels.isWorthPreparing(TextureAsset(image: image, generatesMipmaps: false)))
    }
}
#endif
