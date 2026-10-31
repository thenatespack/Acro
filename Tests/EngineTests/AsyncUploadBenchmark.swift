import Foundation
import Testing
@testable import Engine

// Main-thread hitches while assets load mid-game, on every backend (opt-in: set
// ENGINE_UPLOAD_BENCH=1 and run in release, `swift test -c release --filter AsyncUploadBenchmark`).
//
// A project holds the BoomBox (glTF, five 2048² maps) and 32 1024² PNG textures, each on a
// material on a cube. Everything is imported and cached first; then a fresh database over the
// same project starts loading it while frames run (`blocksOnAssetLoading` off, the default
// upload budget), as a game streaming a level would. Per frame it times `gather` (where
// finished loads are applied and uploaded: everything the main thread does for assets) and
// the whole frame on the CPU (beginFrame ... endFrame), and prints the worst frames. Also
// times creating 32 1024² textures and 32 1 MiB static buffers in the middle of a frame.

@MainActor
@Suite(.serialized) struct AsyncUploadBenchmark {
    nonisolated static let enabled = ProcessInfo.processInfo.environment["ENGINE_UPLOAD_BENCH"] != nil

    private static func milliseconds(_ from: UInt64, _ to: UInt64) -> Double { Double(to - from) / 1e6 }

    private static func makeProject() throws -> (Project, textureCount: Int) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AsyncUploadBenchmark-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "UploadBench")
        let boomBox = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Demo/Models/BoomBox.glb")
        try FileManager.default.copyItem(at: boomBox, to: project.assetsURL.appendingPathComponent("BoomBox.glb"))
        let count = 32, size = 1024
        for i in 0..<count {
            var pixels = [UInt8](repeating: 255, count: size * size * 4)
            for y in 0..<size {
                for x in 0..<size {
                    let o = (y * size + x) * 4
                    pixels[o] = UInt8((x &* 3 &+ i &* 17) & 255)
                    pixels[o + 1] = UInt8((y &* 5 &+ x &* y >> 7) & 255)
                    pixels[o + 2] = UInt8((x ^ y &+ i) & 255)
                }
            }
            try Image(width: size, height: size, pixels: pixels).pngData()
                .write(to: project.assetsURL.appendingPathComponent("t\(i).png"))
        }
        return (project, count)
    }

    @Test(.enabled(if: enabled)) func loadingHitches() throws {
        let (project, textureCount) = try Self.makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let importing = AssetDatabase(project: project)
        importing.refreshAsync()
        #expect(importing.waitForAll())
        for i in 0..<textureCount {
            let texture = try #require(importing.id(forPath: "t\(i).png"))
            try Data(#"{"texture": "\#(AssetReference(texture, subAsset: "texture").description)"}"#.utf8)
                .write(to: project.assetsURL.appendingPathComponent("m\(i).material"))
        }
        importing.refreshAsync()
        #expect(importing.waitForAll())

        try TestDevices.forEachBackend { device, frames in
            for run in 0..<2 {  // the first run warms up pipelines and caches
                let database = AssetDatabase(project: project)
                database.scan()
                let renderer = try SceneRenderer(device: device, quality: .low)
                renderer.blocksOnAssetLoading = false
                renderer.assets = database
                let world = World()
                let box = try #require(database.id(forPath: "BoomBox.glb"))
                let objects = try #require(database.record(box)).objects
                let material = try #require(objects.first { $0.kind == .material })
                for mesh in objects where mesh.kind == .mesh {
                    _ = world.spawn(Transform(), MeshRenderer(mesh: MeshHandle(AssetReference(box, subAsset: mesh.id)),
                                                              material: MaterialHandle(AssetReference(box, subAsset: material.id))))
                }
                for i in 0..<textureCount {
                    let id = try #require(database.id(forPath: "m\(i).material"))
                    _ = world.spawn(Transform(), MeshRenderer(mesh: .cube, material: MaterialHandle(AssetReference(id))))
                }
                world.propagateTransforms()

                var gathers: [Double] = [], totals: [Double] = []
                var lastBusy = 0, loadedAt = 0.0
                let loadStart = DispatchTime.now().uptimeNanoseconds
                for index in 0..<600 {
                    let start = DispatchTime.now().uptimeNanoseconds
                    guard try device.beginFrame(framebufferSize: frames.size) else { continue }
                    let gatherStart = DispatchTime.now().uptimeNanoseconds
                    renderer.gather(world)
                    let gatherEnd = DispatchTime.now().uptimeNanoseconds
                    _ = device.beginScreenPass(clearColor: Vec4(0, 0, 0, 1), clearDepth: 1)
                    device.endPass()
                    _ = try device.endFrame()
                    let end = DispatchTime.now().uptimeNanoseconds
                    gathers.append(Self.milliseconds(gatherStart, gatherEnd))
                    totals.append(Self.milliseconds(start, end))
                    if gathers.last! > 0.5 {
                        lastBusy = index
                        loadedAt = Self.milliseconds(loadStart, end)
                    }
                    if index > 30, !database.isLoading, index - lastBusy > 30 { break }
                }
                device.waitIdle()
                guard run == 1 else { continue }
                let worst = gathers.sorted(by: >).prefix(5).map { String(format: "%.1f", $0) }.joined(separator: " ")
                print(String(format: "BENCH %@ load: loaded after %d frames / %.0f ms, gather max %.1f ms (worst five %@), sum %.0f ms, "
                             + "frames over 8 ms %d; frame CPU max %.1f ms",
                             "\(device.backend)", lastBusy + 1, loadedAt, gathers.max() ?? 0, worst, gathers.reduce(0, +),
                             gathers.filter { $0 > 8 }.count, totals.max() ?? 0))
            }

            // Creation in the middle of a frame.
            let size = 1024
            let pixels = [UInt8](repeating: 128, count: size * size * 4)
            let bytes = [UInt8](repeating: 7, count: 1 << 20)
            for run in 0..<2 {
                var textureTimes: [Double] = [], bufferTimes: [Double] = []
                var keep: [AnyObject] = []
                guard try device.beginFrame(framebufferSize: frames.size) else { continue }
                for _ in 0..<32 {
                    let t0 = DispatchTime.now().uptimeNanoseconds
                    keep.append(try device.makeTexture(pixels: pixels, width: size, height: size, format: .rgba8Unorm) as AnyObject)
                    let t1 = DispatchTime.now().uptimeNanoseconds
                    keep.append(try device.makeBuffer(bytes, usage: .vertex) as AnyObject)
                    let t2 = DispatchTime.now().uptimeNanoseconds
                    textureTimes.append(Self.milliseconds(t0, t1))
                    bufferTimes.append(Self.milliseconds(t1, t2))
                }
                _ = device.beginScreenPass(clearColor: Vec4(0, 0, 0, 1), clearDepth: 1)
                device.endPass()
                let endStart = DispatchTime.now().uptimeNanoseconds
                _ = try device.endFrame()
                let endTime = Self.milliseconds(endStart, DispatchTime.now().uptimeNanoseconds)
                device.waitIdle()
                keep.removeAll()
                guard run == 1 else { continue }
                print(String(format: "BENCH %@ create: 32 x 4 MiB textures max %.2f ms sum %.1f ms; 32 x 1 MiB buffers max %.2f ms "
                             + "sum %.1f ms; endFrame %.2f ms",
                             "\(device.backend)", textureTimes.max() ?? 0, textureTimes.reduce(0, +),
                             bufferTimes.max() ?? 0, bufferTimes.reduce(0, +), endTime))
            }
        }
    }
}
