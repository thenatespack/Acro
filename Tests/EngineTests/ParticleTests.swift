import Foundation
import Testing
@testable import Engine

// MARK: - Component

@Test func particleEmitterRoundTripsThroughJSON() throws {
    var emitter = ParticleEmitter(capacity: 3000, rate: 42, bursts: [ParticleBurst(time: 0.5, count: 10, interval: 1, cycles: 3)],
                                  shape: .disc, spiralArms: 3, blend: .alpha, collidesWithGround: true, seed: 7)
    emitter.color = [ParticleColorKey(0, Vec4(1, 0, 0, 1)), ParticleColorKey(1, Vec4(0, 0, 1, 0))]
    emitter.sizeOverLife = [ParticleCurveKey(0, 0.5), ParticleCurveKey(1, 2)]
    let data = try JSONEncoder().encode(emitter)
    #expect(try JSONDecoder().decode(ParticleEmitter.self, from: data) == emitter)
}

@Test func particleEmitterDecodesMissingFieldsAsDefaults() throws {
    let emitter = try JSONDecoder().decode(ParticleEmitter.self, from: Data(#"{"rate": 5, "blend": "alpha"}"#.utf8))
    var expected = ParticleEmitter()
    expected.rate = 5
    expected.blend = .alpha
    #expect(emitter == expected)
}

@MainActor @Test func particleEmitterIsARegisteredComponent() throws {
    ParticleSystem.registerComponents()
    #expect(ComponentRegistry.type(named: "ParticleEmitter") == ParticleEmitter.self)
    // It saves and loads with a world like any component.
    let world = World()
    _ = world.spawn(Transform(), ParticleEmitter(rate: 9, seed: 3))
    let loaded = World()
    _ = try loaded.load(try world.save())
    var found: [ParticleEmitter] = []
    loaded.query(ParticleEmitter.self) { _, emitter in found.append(emitter) }
    #expect(found == [ParticleEmitter(rate: 9, seed: 3)])
}

@Test func emitterCapacityRoundsToWorkgroupsWithinTheBlendLimit() {
    #expect(ParticleEmitter(capacity: 1).effectiveCapacity == 256)
    #expect(ParticleEmitter(capacity: 1000).effectiveCapacity == 1024)
    #expect(ParticleEmitter(capacity: 100_000, blend: .alpha).effectiveCapacity == 100_096)
    #expect(ParticleEmitter(capacity: 1 << 20, blend: .alpha).effectiveCapacity == ParticleEmitter.maxSortedCapacity)
    #expect(ParticleEmitter(capacity: 1 << 30).effectiveCapacity == ParticleEmitter.maxCapacity)
}

// MARK: - Spawn scheduling (CPU)

private func run(_ schedule: inout ParticleSpawnSchedule, steps: Int, rate: Float, bursts: [ParticleBurst] = [],
                 emitting: Bool = true) -> [Int] {
    (0..<steps).map { _ in schedule.step(dt: 1.0 / 60, rate: rate, bursts: bursts, emitting: emitting) }
}

@Test func spawnRateCarriesFractionsBetweenSteps() {
    var schedule = ParticleSpawnSchedule()
    #expect(run(&schedule, steps: 6, rate: 120) == [2, 2, 2, 2, 2, 2])
    var half = ParticleSpawnSchedule()
    let counts = run(&half, steps: 60, rate: 30)
    #expect(counts.reduce(0, +) == 30 && counts.allSatisfy { $0 <= 1 })
    #expect(half.spawned == 30)
}

@Test func burstsFireAtTheirTimesAndRepeat() {
    var once = ParticleSpawnSchedule()
    let onceCounts = run(&once, steps: 120, rate: 0, bursts: [ParticleBurst(time: 0.5, count: 50)])
    #expect(onceCounts.reduce(0, +) == 50)
    #expect(onceCounts.firstIndex(of: 50) == 30)  // the step [0.5, 0.5167)

    var atStart = ParticleSpawnSchedule()
    #expect(run(&atStart, steps: 1, rate: 0, bursts: [ParticleBurst(count: 7)]) == [7])

    var repeating = ParticleSpawnSchedule()
    let limited = run(&repeating, steps: 120, rate: 0, bursts: [ParticleBurst(time: 0, count: 10, interval: 0.25, cycles: 3)])
    #expect(limited.reduce(0, +) == 30)
    var forever = ParticleSpawnSchedule()
    #expect(run(&forever, steps: 50, rate: 0, bursts: [ParticleBurst(count: 1, interval: 0.25, cycles: 0)]).reduce(0, +) == 4)
}

@Test func stoppedEmittersOnlySpawnRequestedBursts() {
    var schedule = ParticleSpawnSchedule()
    #expect(run(&schedule, steps: 10, rate: 600, bursts: [ParticleBurst(count: 5)], emitting: false).reduce(0, +) == 0)
    schedule.pendingBurst = 25
    #expect(run(&schedule, steps: 2, rate: 600, emitting: false) == [25, 0])
    #expect(schedule.spawned == 25)
}

@Test func spiralArmsTurnWithTheOrbit() {
    let emitter = ParticleEmitter(attraction: 4, orbit: 1)  // angular speed sqrt(4) = 2 rad/s
    #expect(abs(ParticleSystem.armRotation(emitter, time: 1) - 2) < 1e-6)
    #expect(ParticleSystem.armRotation(ParticleEmitter(orbit: 1), time: 1) == 0)
}

// MARK: - GPU

/// A burst into an additive and a sorted emitter is simulated, compacted / sorted and counted
/// on every backend; the live counts read back from the draw arguments match.
@MainActor @Test func particleBurstsAreSimulatedAndCountedOnTheGPU() throws {
    try TestDevices.forEachBackend { device, frames in
        let system = try ParticleSystem(device: device)
        system.countReadbackInterval = 1
        let world = World()
        _ = world.spawn(Transform(), ParticleEmitter(capacity: 1024, rate: 0, bursts: [ParticleBurst(count: 300)],
                                                     lifetime: Vec2(10, 10), seed: 1))
        _ = world.spawn(Transform(position: Vec3(2, 0, 0)), ParticleEmitter(
            capacity: 256, rate: 0, bursts: [ParticleBurst(count: 100)], lifetime: Vec2(10, 10), blend: .alpha, seed: 2))
        for _ in 0..<3 {
            world.update(dt: 1.0 / 60)
            system.prepare(world: world, cameraPosition: Vec3(0, 0, 10))
            try frames.run { system.simulate(frame: $0) }
        }
        #expect(system.stats.emitters == 2 && system.stats.capacity == 1024 + 256)
        #expect(system.stats.aliveParticles == 400, "\(device.backend)")
    }
}

// MARK: - Settings (CPU)

@Test func newEmitterSettingsRoundTripThroughJSON() throws {
    let emitter = ParticleEmitter(
        blend: .alpha, collidesWithDepth: true, depthThickness: 0.3,
        colliders: [.plane(point: Vec3(0, 1, 0), normal: Vec3(0, 1, 0)), .sphere(center: Vec3(1, 2, 3), radius: 2, inside: true),
                    .box(center: .zero, halfExtents: Vec3(1, 2, 3))],
        killOnCollision: true, subEmitters: [ParticleSubEmitter(.collision, emitter: EntityRef(EntityID.random()), count: 3, inheritVelocity: 0.5)],
        texture: TextureHandle("smoke"), atlasColumns: 4, atlasRows: 2, frameCount: 7, frameRate: 12, randomStartFrame: true,
        frameBlending: true, softness: 0.5, lit: true, receivesShadows: true)
    #expect(try JSONDecoder().decode(ParticleEmitter.self, from: JSONEncoder().encode(emitter)) == emitter)
    #expect(emitter.effectiveFrameCount == 7 && emitter.needsSceneDepth)
    #expect(ParticleEmitter(atlasColumns: 4, atlasRows: 2).effectiveFrameCount == 8)
    #expect(ParticleEmitter(atlasColumns: 2, atlasRows: 2, frameCount: 9).effectiveFrameCount == 4)
    #expect(!ParticleEmitter().needsSceneDepth && ParticleEmitter(softness: 0.1).needsSceneDepth)
}

@Test func sortCapacityIsAPowerOfTwoBlockMultiple() {
    #expect(ParticleSystem.sortCapacity(for: 256) == 2048)
    #expect(ParticleSystem.sortCapacity(for: 2048) == 2048)
    #expect(ParticleSystem.sortCapacity(for: 2304) == 4096)
    #expect(ParticleSystem.sortCapacity(for: ParticleEmitter.maxSortedCapacity) == ParticleEmitter.maxSortedCapacity)
    #expect(ParticleSystem.mergeStages(2048) == 0 && ParticleSystem.mergeStages(1 << 18) == 7)
}

/// Each target is driven by the first emitter naming it that isn't a target itself; nothing
/// drives itself, and missing targets are ignored.
@Test func subEmitterTargetsGetOneDriverWithoutNesting() {
    let ids = (0..<6).map { _ in EntityID.random() }
    func emitter(_ targets: Int...) -> ParticleEmitter {
        ParticleEmitter(subEmitters: targets.map { ParticleSubEmitter(.death, emitter: $0 < ids.count ? EntityRef(ids[$0]) : EntityRef(EntityID.random())) })
    }
    let emitters: [(Int, ParticleEmitter)] = [
        (0, emitter(1, 0)),   // drives 1; itself ignored
        (1, emitter(2)),      // a target: doesn't drive 2
        (3, emitter(1, 4)),   // 1 is taken; drives 4
        (4, emitter()),
        (5, emitter(9)),      // missing target
        (2, emitter()),
    ]
    let drivers = ParticleSystem.subEmitterDrivers(emitters) { ref in ids.firstIndex { $0 == ref.id } }
    #expect(drivers == [1: 0, 4: 3])
}

// MARK: - GPU features

/// Runs `count` frames of `world` through `system` (one step each) on a test device.
@MainActor private func step(_ system: ParticleSystem, _ world: World, frames count: Int, on frames: TestFrames,
                             camera: Vec3 = Vec3(0, 0, 10), before: ((Frame) -> Void)? = nil) throws {
    for _ in 0..<count {
        world.update(dt: 1.0 / 60)
        system.prepare(world: world, cameraPosition: camera)
        try frames.run { frame in
            before?(frame)
            system.simulate(frame: frame)
        }
    }
}

/// An emitter's live particles (12 floats each, in slot order), its draw list and live count, read back.
@MainActor private func readBack(_ system: ParticleSystem, _ entity: Entity, on frames: TestFrames)
    throws -> (particles: [[Float]], all: [Float], drawList: [UInt32], live: Int) {
    let buffers = try #require(system.buffers(of: entity))
    var floats: [Float] = [], list: [UInt32] = [], live = 0
    try frames.run { frame in
        frame.readBack(buffers.particles) { bytes in floats = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
        frame.readBack(buffers.drawList) { bytes in list = bytes.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) } }
        frame.readBack(buffers.state, offset: 0, length: 8) { bytes in
            live = Int(bytes.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
        }
    }
    let particles = stride(from: 0, to: floats.count, by: 12).map { Array(floats[$0..<$0 + 12]) }
    return (particles.filter { $0[7] > 0 }, floats, Array(list.prefix(live)), live)
}

/// 20k alpha-blended particles (beyond one 2048-element block: global merge passes, dispatched
/// indirectly) are drawn back to front, every live slot once, identically on every backend.
@MainActor @Test func sortedEmittersBeyondOneBlockDrawBackToFront() throws {
    var lists: [[UInt32]] = []
    try TestDevices.forEachBackend { device, frames in
        let system = try ParticleSystem(device: device)
        let world = World()
        let entity = world.spawn(Transform(), ParticleEmitter(
            capacity: 40_000, rate: 0, bursts: [ParticleBurst(count: 20_000)], lifetime: Vec2(10, 10), shape: .sphere,
            shapeSize: Vec3(5, 5, 5), speed: Vec2(0, 0), blend: .alpha, seed: 5))
        let camera = Vec3(1, 2, 20)
        try step(system, world, frames: 3, on: frames, camera: camera)
        let result = try readBack(system, entity, on: frames)
        #expect(result.live == 20_000, "\(device.backend)")
        #expect(Set(result.drawList).count == result.live, "\(device.backend)")
        let floats = result.all
        let distances = result.drawList.map { slot -> Float in
            let i = Int(slot) * 12
            return length(Vec3(floats[i], floats[i + 1], floats[i + 2]) - camera)
        }
        // The GPU computed its keys with its own length(): the CPU's may round an ulp or two apart.
        let worst = zip(distances, distances.dropFirst()).map { $1 - $0 }.max() ?? 0
        #expect(worst <= 1e-5, "\(device.backend): not back to front (worst inversion \(worst))")
        #expect(result.drawList.allSatisfy { floats[Int($0) * 12 + 7] > 0 }, "\(device.backend): a dead slot is drawn")
        lists.append(result.drawList)
    }
    #expect(Set(lists).count <= 1, "the backends sorted differently")
}

/// Death and collision sub-emitters spawn `count` particles per event on the GPU; the
/// collision parent dies on impact (`killOnCollision`); both backends agree on every particle.
@MainActor @Test func subEmittersSpawnOnDeathAndCollision() throws {
    var results: [[Float]] = []
    try TestDevices.forEachBackend { device, frames in
        let system = try ParticleSystem(device: device)
        let world = World()
        let deathChild = world.spawn(Transform(), ParticleEmitter(capacity: 256, rate: 0, lifetime: Vec2(10, 10), shape: .sphere,
                                                                  speed: Vec2(1, 2), seed: 21))
        let collisionChild = world.spawn(Transform(), ParticleEmitter(capacity: 256, rate: 0, lifetime: Vec2(10, 10), spread: .pi,
                                                                      speed: Vec2(0.5, 1), seed: 22))
        _ = world.spawn(Transform(position: Vec3(-2, 1, 0)), ParticleEmitter(
            capacity: 256, rate: 0, bursts: [ParticleBurst(count: 50)], lifetime: Vec2(0.05, 0.05), shape: .sphere, speed: Vec2(0, 0),
            subEmitters: [ParticleSubEmitter(.death, emitter: world.ref(to: deathChild), count: 4, inheritVelocity: 1)], seed: 23))
        let faller = world.spawn(Transform(position: Vec3(2, 1, 0)), ParticleEmitter(
            capacity: 256, rate: 0, bursts: [ParticleBurst(count: 30)], lifetime: Vec2(10, 10), shape: .sphere,
            shapeSize: Vec3(0.3, 0.3, 0.3), speed: Vec2(0, 0), gravity: Vec3(0, -20, 0), collidesWithGround: true,
            killOnCollision: true,
            subEmitters: [ParticleSubEmitter(.collision, emitter: world.ref(to: collisionChild), count: 3)], seed: 24))
        try step(system, world, frames: 30, on: frames)
        #expect(system.stats.subEmitterLinks == 2)
        let death = try readBack(system, deathChild, on: frames)
        let collision = try readBack(system, collisionChild, on: frames)
        #expect(death.live == 200, "\(device.backend)")
        #expect(collision.live == 90, "\(device.backend)")
        #expect(try readBack(system, faller, on: frames).live == 0, "\(device.backend)")
        // Collision children start where their parents hit the ground (y = 0, x around 2).
        #expect(collision.particles.allSatisfy { $0[3] > 0 && abs($0[0] - 2) < 1.5 }, "\(device.backend)")
        results.append(death.all + collision.all)
    }
    #expect(Set(results).count <= 1, "the backends simulated differently")
}

/// Analytic colliders: particles stay inside a sphere and on top of a box.
@MainActor @Test func collidersKeepParticlesOnTheirSide() throws {
    try TestDevices.forEachBackend { device, frames in
        let system = try ParticleSystem(device: device)
        let world = World()
        let caged = world.spawn(Transform(), ParticleEmitter(
            capacity: 512, rate: 0, bursts: [ParticleBurst(count: 400)], lifetime: Vec2(10, 10), shape: .sphere,
            shapeSize: Vec3(0.5, 0.5, 0.5), spread: .pi, speed: Vec2(3, 6), bounce: 0.8,
            colliders: [.sphere(center: .zero, radius: 2, inside: true)], seed: 31))
        let dropped = world.spawn(Transform(position: Vec3(10, 2, 0)), ParticleEmitter(
            capacity: 512, rate: 0, bursts: [ParticleBurst(count: 400)], lifetime: Vec2(10, 10), shape: .box,
            shapeSize: Vec3(1, 0.2, 1), speed: Vec2(0, 0), gravity: Vec3(0, -10, 0), bounce: 0.3,
            colliders: [.box(center: Vec3(10, -1, 0), halfExtents: Vec3(3, 0.5, 3))], seed: 32))
        try step(system, world, frames: 90, on: frames)
        let inside = try readBack(system, caged, on: frames).particles
        let resting = try readBack(system, dropped, on: frames).particles
        #expect(inside.count == 400 && resting.count == 400, "\(device.backend)")
        #expect(inside.allSatisfy { length(Vec3($0[0], $0[1], $0[2])) <= 2.01 }, "\(device.backend)")
        #expect(resting.allSatisfy { $0[1] >= -0.51 && $0[1] < 0.5 }, "\(device.backend)")
    }
}

/// Screen-space collision: particles flying away from the camera bounce off the surface a
/// depth texture holds (a wall at view depth 5) and come back.
@MainActor @Test func depthCollisionBouncesOffTheDepthBuffer() throws {
    try TestDevices.forEachBackend { device, frames in
        let system = try ParticleSystem(device: device)
        let world = World()
        let emitter = world.spawn(Transform(position: Vec3(0, 0, -3)), ParticleEmitter(
            capacity: 256, rate: 0, bursts: [ParticleBurst(count: 200)], lifetime: Vec2(10, 10), shape: .sphere,
            shapeSize: Vec3(0.2, 0.2, 0.2), direction: Vec3(0, 0, -1), spread: 0.15, speed: Vec2(3, 4), bounce: 0.5,
            collidesWithDepth: true, depthThickness: 1, seed: 41))
        let projection = Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 0.1, far: 100)
        let clip = projection * Vec4(0, 0, -5, 1)
        let wall = clip.z / clip.w
        let depth = try device.makeTexture(TextureDescriptor(width: 64, height: 64, format: .depth32Float))
        system.sceneDepth = ParticleSceneDepth(texture: depth, viewProjection: projection, projection: projection, cameraPosition: .zero)
        try step(system, world, frames: 60, on: frames, camera: .zero) { frame in
            frame.depthPass(into: depth, clearDepth: wall) { _ in }
        }
        let particles = try readBack(system, emitter, on: frames).particles
        #expect(particles.count == 200, "\(device.backend)")
        #expect(particles.allSatisfy { $0[2] > -5.05 }, "\(device.backend): a particle went through the wall")
        #expect(particles.filter { $0[6] > 0 }.count > 150, "\(device.backend): particles didn't bounce back")
    }
}
