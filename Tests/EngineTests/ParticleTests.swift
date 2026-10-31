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
    #expect(ParticleEmitter(capacity: 100_000, blend: .alpha).effectiveCapacity == ParticleEmitter.maxSortedCapacity)
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
