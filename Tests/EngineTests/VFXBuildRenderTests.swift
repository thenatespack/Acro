import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineAssets
@testable import EngineRendering

// VFX Builder on the GPU (Metal and Vulkan): a `.vfx` emitter textured by a `.sprite` tag
// flipbook draws the tag's frames over each particle's life, and birth sub-emitter links spawn
// children where their parents' particles are born.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("VFXBuildRenderTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "VFXBuildRender")
}

/// 2×2 pixels, three solid frames (blue, red, green); the tag "pop" plays frames 1-2.
private let sprite = """
{"width": 2, "height": 2, "palette": ["#0000ff", "#ff0000", "#00ff00"],
 "layers": [{"name": "Body", "cels": [["00", "00"], ["11", "11"], ["22", "22"]]}],
 "frames": [{"duration": 100}, {"duration": 100}, {"duration": 100}],
 "tags": [{"name": "pop", "from": 1, "to": 2}]}
"""

@MainActor private func step(_ system: ParticleSystem, _ world: World, frames count: Int, on frames: TestFrames) throws {
    for _ in 0..<count {
        world.update(dt: 1.0 / 60)
        system.prepare(world: world, cameraPosition: Vec3(0, 0, 3))
        try frames.run { frame in system.simulate(frame: frame) }
    }
}

@MainActor private func liveCount(_ system: ParticleSystem, _ entity: Entity, on frames: TestFrames) throws -> (live: Int, particles: [[Float]]) {
    let buffers = try #require(system.buffers(of: entity))
    var floats: [Float] = [], live = 0
    try frames.run { frame in
        frame.readBack(buffers.particles) { bytes in floats = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
        frame.readBack(buffers.state, offset: 0, length: 8) { bytes in
            live = Int(bytes.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
        }
    }
    let particles = stride(from: 0, to: floats.count, by: 12).map { Array(floats[$0..<$0 + 12]) }.filter { $0[7] > 0 }
    return (live, particles)
}

@MainActor
@Suite(.serialized) struct VFXBuildRenderTests {
    @Test func spriteTagFlipbookDrawsItsFramesOverLife() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createPixelSprite(AssetJSON.decoder().decode(PixelSprite.self, from: Data(sprite.utf8)), at: "Sprites/hit.sprite")

        var emitter = VFXEmitter()
        emitter.name = "Hit"
        emitter.rate = 0
        emitter.bursts = [ParticleBurst(count: 1)]
        emitter.capacity = 256
        emitter.lifetime = Vec2(0.2, 0.2)
        emitter.speed = Vec2(0, 0)
        emitter.size = Vec2(1, 1)
        emitter.color = [ParticleColorKey(0, Vec4(1, 1, 1, 1))]
        emitter.texture = "Sprites/hit.sprite"
        emitter.spriteTag = "pop"
        let id = try database.createVFX(VFXBuild(emitters: [emitter]), at: "FX/Hit.vfx")
        #expect(database.record(id)?.importError == nil)
        let prefab = try #require(database.prefab(AssetReference(id)))
        let particles = try #require(prefab.roots.first?.children.first?.particles)
        #expect(particles.frameCount == 2 && particles.atlasColumns * particles.atlasRows >= 2)
        let handle = try #require(particles.texture)
        let image = try #require(AssetReference(handle.key).flatMap { database.texture($0) }?.image)
        #expect(image.width == particles.atlasColumns * 2 && image.height == particles.atlasRows * 2)
        #expect(Array(image.pixels[0..<4]) == [255, 0, 0, 255], "the tag's first frame (red) is cell 0")
        #expect(Array(image.pixels[8..<12]) == [0, 255, 0, 255], "its second (green) is cell 1")

        var images: [String: [Image]] = [:]
        try TestDevices.forEachBackend { device, frames in
            let system = try ParticleSystem(device: device)
            let gpuTexture = try device.makeTexture(image: image, srgb: true, generateMipmaps: false)
            system.textureResolver = { $0 == handle ? gpuTexture : nil }
            let world = World()
            world.instantiate(prefab)
            let target = try device.makeRenderTarget(RenderTargetDescriptor(width: 32, height: 32, multisampled: false))
            let viewProjection = Mat4.perspective(fovY: 1, aspect: 1, near: 0.1, far: 100) * Mat4.lookAt(eye: Vec3(0, 0, 3), target: .zero)
            var shots: [Image] = []
            // 3 steps: 0.05 s of a 0.2 s life (the first frame); 6 more: 0.15 s (the second).
            for count in [3, 6] {
                try step(system, world, frames: count - 1, on: frames)
                world.update(dt: 1.0 / 60)
                system.prepare(world: world, cameraPosition: Vec3(0, 0, 3))
                try frames.run { frame in
                    system.simulate(frame: frame)
                    frame.renderPass(into: target, clearColor: Vec4(0, 0, 0, 1)) { pass in
                        system.draw(in: pass, viewProjection: viewProjection, cameraPosition: Vec3(0, 0, 3), reversedZ: false)
                    }
                    device.readBack(target) { shots.append($0) }
                }
            }
            #expect(shots.count == 2, "\(device.backend)")
            guard shots.count == 2 else { return }
            let early = shots[0].pixels[(16 * 32 + 16) * 4..<(16 * 32 + 16) * 4 + 3].map(Int.init)
            let late = shots[1].pixels[(16 * 32 + 16) * 4..<(16 * 32 + 16) * 4 + 3].map(Int.init)
            #expect(early[0] > 100 && early[1] < 40 && early[2] < 40, "\(device.backend) early frame is red: \(early)")
            #expect(late[1] > 100 && late[0] < 40 && late[2] < 40, "\(device.backend) late frame is green: \(late)")
            images["\(device.backend)"] = shots
        }
        // Both backends draw the same picture (within rounding).
        if let metal = images.values.first, images.count == 2, let vulkan = images.values.dropFirst().first {
            for (a, b) in zip(metal, vulkan) {
                let worst = zip(a.pixels, b.pixels).map { abs(Int($0) - Int($1)) }.max() ?? 0
                #expect(worst <= 8, "the backends drew differently (max channel difference \(worst))")
            }
        }
    }

    /// A birth link: each parent particle spawns `count` children where it's born, on both backends alike.
    @Test func birthSubEmittersSpawnWhereParentsAreBorn() throws {
        var results: [[Float]] = []
        try TestDevices.forEachBackend { device, frames in
            let system = try ParticleSystem(device: device)
            let world = World()
            let child = world.spawn(Transform(), ParticleEmitter(capacity: 256, rate: 0, lifetime: Vec2(10, 10), shape: .sphere,
                                                                 speed: Vec2(0.2, 0.4), seed: 31))
            let parent = world.spawn(Transform(position: Vec3(1, 2, 0)), ParticleEmitter(
                capacity: 256, rate: 0, bursts: [ParticleBurst(count: 20)], lifetime: Vec2(10, 10), speed: Vec2(0, 0),
                subEmitters: [ParticleSubEmitter(.birth, emitter: world.ref(to: child), count: 3)], seed: 30))
            try step(system, world, frames: 10, on: frames)
            #expect(system.stats.subEmitterLinks == 1)
            let parents = try liveCount(system, parent, on: frames)
            let children = try liveCount(system, child, on: frames)
            #expect(parents.live == 20, "\(device.backend)")
            #expect(children.live == 60, "one birth event per parent, three children each (\(device.backend))")
            // Within the child's 0.5 m sphere around the parent's point (1, 2, 0), plus 10 steps at under 0.4 m/s.
            #expect(children.particles.allSatisfy { length(Vec3($0[0], $0[1], $0[2]) - Vec3(1, 2, 0)) < 0.6 }, "\(device.backend)")
            results.append(children.particles.flatMap { $0 })
        }
        #expect(Set(results).count <= 1, "the backends simulated differently")
    }
}
