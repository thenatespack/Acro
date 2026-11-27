import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineAssets
@testable import EngineRendering

/// `ParticleSystem`'s CPU simulation (devices without compute: WebGL 2), forced on a native test
/// device: deterministic counts and lifetimes, and the same particles as the GPU's compute path.
@Suite @MainActor struct ParticleCPUSimulationTests {
    /// Runs `count` frames (one step each).
    private func run(_ system: ParticleSystem, _ world: World, frames count: Int, on frames: TestFrames,
                     camera: Vec3 = Vec3(0, 0, 10)) throws {
        for _ in 0..<count {
            world.update(dt: 1.0 / 60)
            system.prepare(world: world, cameraPosition: camera)
            try frames.run { system.simulate(frame: $0) }
        }
    }

    /// The GPU's live particles (slot order) for `entity`, read back.
    private func gpuParticles(_ system: ParticleSystem, _ entity: Entity, on frames: TestFrames) throws -> [ParticleRecord] {
        let buffers = try #require(system.buffers(of: entity))
        var records: [ParticleRecord] = []
        try frames.run { frame in
            frame.readBack(buffers.particles) { bytes in
                records = bytes.withUnsafeBytes { Array($0.bindMemory(to: ParticleRecord.self)) }
            }
        }
        return records.filter { $0.velocity.w > 0 }
    }

    private func cpuParticles(_ system: ParticleSystem, _ entity: Entity) throws -> [ParticleRecord] {
        try #require(system.cpuEmitter(of: entity)).particles.filter { $0.velocity.w > 0 }
    }

    @Test func cpuSimulationCountsAndLifetimesAreDeterministic() throws {
        try TestDevices.forEachBackend { device, frames in
            var results: [[ParticleRecord]] = []
            for _ in 0..<2 {
                let system = try ParticleSystem(device: device, simulatesOnCPU: true)
                #expect(system.simulatesOnCPU)
                let world = World()
                let entity = world.spawn(Transform(position: Vec3(0, 1, 0)), ParticleEmitter(
                    capacity: 1024, rate: 120, bursts: [ParticleBurst(count: 300)], lifetime: Vec2(0.5, 1), shape: .sphere,
                    speed: Vec2(1, 2), gravity: Vec3(0, -2, 0), seed: 31))
                // The first frame only starts the clock (no prewarm); step 1: the burst plus two from the rate.
                try run(system, world, frames: 2, on: frames)
                #expect(system.stats.aliveParticles == 302)
                #expect(system.stats.spawned == 302)
                let first = try cpuParticles(system, entity)
                #expect(first.count == 302)
                #expect(first.allSatisfy { $0.velocity.w >= 0.5 && $0.velocity.w <= 1 && $0.position.w > 0 && $0.position.w <= 1.0 / 60 })
                // 0.5 s later the burst is still alive (minimum lifetime 0.5 s, minus at most one step).
                try run(system, world, frames: 28, on: frames)
                #expect(system.stats.aliveParticles == 300 + 2 * 29)
                // After 1.2 s the burst has died; the rate keeps about 120/s × 0.75 s alive.
                try run(system, world, frames: 43, on: frames)
                let alive = system.stats.aliveParticles
                #expect(alive > 70 && alive < 125, "\(alive) alive")
                let records = try cpuParticles(system, entity)
                #expect(records.allSatisfy { $0.position.w < $0.velocity.w && $0.velocity.w <= 1 })
                results.append(records)
            }
            #expect(results[0] == results[1], "\(device.backend): two runs differ")
        }
    }

    /// The CPU path simulates what the compute shaders do: spawns, forces, ground and sphere
    /// collisions, death sub-emitters and the live counts, up to float rounding.
    @Test func cpuSimulationMatchesTheGPU() throws {
        try TestDevices.forEachBackend { device, frames in
            @MainActor func scene() -> (World, [Entity]) {
                let world = World()
                let child = world.spawn(Transform(), ParticleEmitter(capacity: 512, rate: 0, lifetime: Vec2(10, 10), shape: .sphere,
                                                                     speed: Vec2(1, 2), seed: 21))
                let parent = world.spawn(Transform(position: Vec3(-2, 1, 0)), ParticleEmitter(
                    capacity: 256, rate: 0, bursts: [ParticleBurst(count: 50)], lifetime: Vec2(0.1, 0.2), shape: .sphere,
                    speed: Vec2(0, 1), subEmitters: [ParticleSubEmitter(.death, emitter: world.ref(to: child), count: 4, inheritVelocity: 1)],
                    seed: 23))
                let faller = world.spawn(Transform(position: Vec3(1, 2, 0)), ParticleEmitter(
                    capacity: 1024, rate: 600, lifetime: Vec2(1, 2), shape: .box, shapeSize: Vec3(1, 0.1, 1), spread: 0.4,
                    speed: Vec2(1, 3), gravity: Vec3(0, -9.81, 0), drag: 0.2, turbulence: 2, turbulenceFrequency: 1.3,
                    blend: .alpha, collidesWithGround: true, bounce: 0.5, friction: 0.2,
                    colliders: [.sphere(center: Vec3(1, 0.5, 0), radius: 0.6)], seed: 25))
                return (world, [child, parent, faller])
            }
            let (gpuWorld, gpuEntities) = scene()
            let gpu = try ParticleSystem(device: device)
            try run(gpu, gpuWorld, frames: 40, on: frames)
            let (cpuWorld, cpuEntities) = scene()
            let cpu = try ParticleSystem(device: device, simulatesOnCPU: true)
            try run(cpu, cpuWorld, frames: 40, on: frames)
            for (g, c) in zip(gpuEntities, cpuEntities) {
                let a = try gpuParticles(gpu, g, on: frames), b = try cpuParticles(cpu, c)
                #expect(a.count == b.count, "\(device.backend): \(a.count) live on the GPU, \(b.count) on the CPU")
                guard a.count == b.count else { continue }
                var worst: Float = 0
                for (p, q) in zip(a, b) {
                    worst = max(worst, length(Vec3(p.position.x, p.position.y, p.position.z) - Vec3(q.position.x, q.position.y, q.position.z)))
                    #expect(abs(p.velocity.w - q.velocity.w) < 1e-5 && abs(p.attributes.x - q.attributes.x) < 1e-5)
                }
                // Turbulence and bounces amplify rounding over 40 steps, but not by much.
                #expect(worst < 0.02, "\(device.backend): positions differ by up to \(worst)")
            }
            #expect(try cpuParticles(cpu, cpuEntities[0]).count == 200)
            // The sorted emitter's draw list is far to near.
            let emitter = try #require(cpu.cpuEmitter(of: cpuEntities[2]))
            let camera = Vec3(0, 0, 10)
            let distances = emitter.drawList.map { slot -> Float in
                let p = emitter.particles[Int(slot)].position
                return length(Vec3(p.x, p.y, p.z) - camera)
            }
            #expect(distances.count == emitter.alive && zip(distances, distances.dropFirst()).allSatisfy { $0 >= $1 })
        }
    }

    /// An emitter beyond `cpuMaxCapacity` simulates every n-th particle: the same ones the GPU
    /// would (the same spawn indices), n a power of two.
    @Test func cpuSimulationThinsEmittersBeyondItsCapacity() throws {
        try TestDevices.forEachBackend { device, frames in
            let system = try ParticleSystem(device: device, simulatesOnCPU: true)
            system.cpuMaxCapacity = 1000
            let world = World()
            let entity = world.spawn(Transform(), ParticleEmitter(capacity: 4096, rate: 6000, lifetime: Vec2(10, 10), seed: 7))
            try run(system, world, frames: 30, on: frames)
            let emitter = try #require(system.cpuEmitter(of: entity))
            #expect(emitter.stride == 8 && emitter.capacity == 512)
            // 29 steps (the first frame starts the clock) of 100 spawns: indices 0...2899, every 8th of them.
            #expect(system.stats.aliveParticles == 363)
            // The kept particles are spawn indices 0, 8, 16, ...: their random numbers match.
            var u = ParticleSystem.SimulationUniforms.forTesting(seed: 7)
            u.speedLife = Vec4(1, 1, 10, 10)
            let expected = ParticleCPUEmitter.spawn(u, spawnIndex: 8)
            #expect(emitter.particles[1].attributes == expected.attributes)
        }
    }
}

extension ParticleSystem.SimulationUniforms {
    /// Default emitter parameters with `seed` (spawn tests).
    static func forTesting(seed: UInt32) -> Self {
        let e = ParticleEmitter(seed: seed)
        return Self(
            transform: .identity, shape: .zero, direction: Vec4(0, 1, 0, cosf(e.spread)),
            speedLife: Vec4(e.speed.x, e.speed.y, e.lifetime.x, e.lifetime.y), sizeSpin: Vec4(e.size.x, e.size.y, e.spin, e.orbit),
            forces: .zero, turbulence: .zero, ground: .zero, disc: Vec4(0, 0, 0, 1.0 / 60), spawn: SIMD4(0, 0, 0, seed), info: .zero,
            arms: .zero, collision: .zero, depthParams: .zero, depthLinear: .zero, camera: .zero, viewProj: .identity,
            inverseViewProj: .identity, colliders: (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero))
    }
}
