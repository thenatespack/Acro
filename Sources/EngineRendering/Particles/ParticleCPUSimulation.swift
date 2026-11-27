#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics

/// One particle as particles.glsl lays it out (48 bytes): the CPU simulation's record and the
/// per-instance vertex data its draws read (particle_vertex.glsl's PARTICLES_INSTANCED variant).
struct ParticleRecord: BitwiseCopyable, Equatable {
    /// xyz world position, w age in seconds.
    var position: Vec4
    /// xyz world velocity, w lifetime in seconds (0: dead).
    var velocity: Vec4
    /// x size, y rotation, z spin (radians / s), w random 0...1.
    var attributes: Vec4

    static let dead = ParticleRecord(position: .zero, velocity: .zero, attributes: .zero)

    /// Three float4 instance attributes at locations 0-2.
    static let layout = VertexLayout(stride: 48, attributes: [
        VertexAttribute(location: 0, format: .float4, offset: 0),
        VertexAttribute(location: 1, format: .float4, offset: 16),
        VertexAttribute(location: 2, format: .float4, offset: 32),
    ])
}

/// `ParticleSystem`'s simulation on the CPU, for devices without compute (WebGL 2): the
/// particle_*.comp shaders as Swift, slot for slot, with the same parameters
/// (`ParticleSystem.SimulationUniforms`), random numbers and spawn schedule, so an emitter
/// behaves as it does on the GPU up to float rounding (plain multiply-adds rather than the
/// shaders' fused ones, the platform's sin / cos / pow). Depth-buffer collisions are left out:
/// the scene's depth stays on the GPU.
///
/// One `ParticleCPUEmitter` per emitter holds its ring of particles; `step` is
/// particle_simulate.comp (spawn the step's slots, integrate, collide, age, flag events),
/// `spawnFromEvents` particle_events.comp + particle_spawn.comp (a sub-emitter's spawns), and
/// `buildDrawList` particle_compact.comp plus, for sorted emitters, the bitonic sort's order (far
/// to near, ties by slot).
final class ParticleCPUEmitter {
    let capacity: Int
    /// Every `stride`-th spawn index of the emitter's own schedule is simulated (1: all); see
    /// `ParticleSystem.cpuMaxCapacity`.
    let stride: Int
    var particles: [ParticleRecord]
    /// Per slot: bit 0 died, bit 1 collided, bit 2 born this step (when recording events).
    var eventFlags: [UInt8] = []
    /// Live slots in draw order (`buildDrawList`).
    var drawList: [Int32] = []
    var alive = 0
    /// Sub-emitter targets: the ring cursor and the spawn index counter (particle_events.comp's spawner).
    var spawnCursor = 0
    var spawned: UInt32 = 0

    init(capacity: Int, stride: Int = 1) {
        self.capacity = capacity
        self.stride = max(stride, 1)
        particles = [ParticleRecord](repeating: .dead, count: capacity)
    }

    // MARK: - Random numbers (particles.glsl)

    @inline(__always) static func pcgHash(_ v: UInt32) -> UInt32 {
        let state = v &* 747_796_405 &+ 2_891_336_453
        let word = ((state >> ((state >> 28) &+ 4)) ^ state) &* 277_803_737
        return (word >> 22) ^ word
    }

    @inline(__always) static func random(_ key: UInt32, _ k: UInt32) -> Float {
        Float(pcgHash(key &+ k &* 0x9E37_79B9) >> 8) * (1.0 / 16_777_216.0)
    }

    @inline(__always) private static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

    // MARK: - Spawning (particle_spawn.glsl)

    static func spawn(_ u: ParticleSystem.SimulationUniforms, spawnIndex: UInt32) -> ParticleRecord {
        let tau: Float = 6.28318530718
        let key = pcgHash(spawnIndex ^ pcgHash(u.spawn.w))
        var local = Vec3.zero
        let axis = Vec3(u.shape.y, u.shape.z, u.shape.w)
        switch Int(u.shape.x) {
        case 1:  // sphere: uniform in the volume
            let z = random(key, 0) * 2 - 1, phi = random(key, 1) * tau
            let s = max(1 - z * z, 0).squareRoot()
            let dir = Vec3(s * cosf(phi), s * sinf(phi), z)
            local = dir * axis.x * powf(random(key, 2), 1.0 / 3.0)
        case 2:  // box
            local = (Vec3(random(key, 0), random(key, 1), random(key, 2)) * 2 - 1) * axis
        case 3:  // disc in the local XZ plane, optionally gathered into spiral arms
            var r = axis.x * random(key, 0).squareRoot()
            var angle = random(key, 1) * tau
            if u.disc.x > 0 {
                r = axis.x * random(key, 0)
                let arm = (random(key, 1) * u.disc.x).rounded(.down)
                angle = arm * tau / u.disc.x + u.arms.x + r * u.disc.y + (random(key, 3) - 0.5) * u.disc.z
            }
            local = Vec3(cosf(angle) * r, (random(key, 2) - 0.5) * axis.y, sinf(angle) * r)
        default:
            break
        }

        let forward = normalize(Vec3(u.direction.x, u.direction.y, u.direction.z))
        let helper = abs(forward.y) < 0.99 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)
        let side = normalize(cross(helper, forward)), up = cross(forward, side)
        let cosTheta = mix(u.direction.w, 1, random(key, 4))
        let sinTheta = max(1 - cosTheta * cosTheta, 0).squareRoot(), phi = random(key, 5) * tau
        let localDirection = forward * cosTheta + (side * cosf(phi) + up * sinf(phi)) * sinTheta
        let speed = mix(u.speedLife.x, u.speedLife.y, random(key, 6))
        var localVelocity = localDirection * speed
        if u.sizeSpin.w != 0 {
            let r = (local.x * local.x + local.z * local.z).squareRoot()
            let tangent = r > 1e-4 ? Vec3(-local.z, 0, local.x) / r : .zero
            let orbital = u.turbulence.w > 0 ? u.turbulence.w.squareRoot() * r : 1
            localVelocity += tangent * u.sizeSpin.w * orbital
        }

        let m = u.transform
        let world = m.c0 * local.x + m.c1 * local.y + m.c2 * local.z + m.c3
        let velocity = m.c0 * localVelocity.x + m.c1 * localVelocity.y + m.c2 * localVelocity.z
        return ParticleRecord(
            position: Vec4(world.x, world.y, world.z, 0),
            velocity: Vec4(velocity.x, velocity.y, velocity.z, max(mix(u.speedLife.z, u.speedLife.w, random(key, 7)), 1e-3)),
            attributes: Vec4(mix(u.sizeSpin.x, u.sizeSpin.y, random(key, 8)), random(key, 9) * tau,
                             (random(key, 10) * 2 - 1) * u.sizeSpin.z, random(key, 11)))
    }

    // MARK: - Simulation (particle_simulate.comp)

    /// What one step did, for the sub-emitters.
    struct StepEvents {
        var died = 0
        var collided = 0
        var born = 0
    }

    /// Bounces off a surface with unit normal n (only when moving into it).
    @inline(__always) private static func reflect(_ velocity: inout Vec3, _ n: Vec3, bounce: Float, friction: Float) {
        let vn = dot(velocity, n)
        guard vn < 0 else { return }
        let normal = n * vn
        velocity = (velocity - normal) * (1 - friction) - normal * bounce
    }

    @inline(__always) private static func collide(_ position: inout Vec3, _ velocity: inout Vec3, _ n: Vec3, _ depth: Float,
                                                  bounce: Float, friction: Float) -> Bool {
        guard depth > 0, dot(velocity, n) < 0 else { return false }
        position += n * (depth * (1 + bounce))
        reflect(&velocity, n, bounce: bounce, friction: friction)
        return true
    }

    private static func collideAnalytic(_ position: inout Vec3, _ velocity: inout Vec3, a: Vec4, b: Vec4, bounce: Float,
                                        friction: Float) -> Bool {
        let code = UInt32(a.w)
        let kind = code & 3, inside = code >= 4
        let delta = position - Vec3(a.x, a.y, a.z)
        let bv = Vec3(b.x, b.y, b.z)
        if kind == 0 { return collide(&position, &velocity, bv, -dot(delta, bv), bounce: bounce, friction: friction) }
        if kind == 1 {
            let distance = length(delta)
            let n = distance > 1e-6 ? delta / distance : Vec3(0, 1, 0)
            return inside ? collide(&position, &velocity, -n, distance - b.x, bounce: bounce, friction: friction)
                : collide(&position, &velocity, n, b.x - distance, bounce: bounce, friction: friction)
        }
        let penetration = bv - Vec3(abs(delta.x), abs(delta.y), abs(delta.z))
        let s = Vec3(delta.x < 0 ? -1 : 1, delta.y < 0 ? -1 : 1, delta.z < 0 ? -1 : 1)
        if !inside {
            if penetration.x <= 0 || penetration.y <= 0 || penetration.z <= 0 { return false }
            if penetration.x <= penetration.y && penetration.x <= penetration.z {
                return collide(&position, &velocity, Vec3(s.x, 0, 0), penetration.x, bounce: bounce, friction: friction)
            }
            if penetration.y <= penetration.z {
                return collide(&position, &velocity, Vec3(0, s.y, 0), penetration.y, bounce: bounce, friction: friction)
            }
            return collide(&position, &velocity, Vec3(0, 0, s.z), penetration.z, bounce: bounce, friction: friction)
        }
        var hit = collide(&position, &velocity, Vec3(-s.x, 0, 0), -penetration.x, bounce: bounce, friction: friction)
        hit = collide(&position, &velocity, Vec3(0, -s.y, 0), -penetration.y, bounce: bounce, friction: friction) || hit
        return collide(&position, &velocity, Vec3(0, 0, -s.z), -penetration.z, bounce: bounce, friction: friction) || hit
    }

    /// One fixed step: the slots of `u.spawn` (first slot, count, first spawn index) get new
    /// particles, then every live particle is integrated, collides, ages and may die. With
    /// `recordEvents`, `eventFlags` gets each slot's flags. Born particles are spread over the step
    /// as on the GPU: the one at offset o of the step's `scheduled` spawns integrates
    /// (scheduled - o - 0.5) / scheduled of it. With a `stride` (every `stride`-th spawn index is
    /// simulated), born slot i is spawn index `u.spawn.z + i × stride`, at offset
    /// `firstOffset + i × stride` of the step's spawns; without one, `scheduled` is the count.
    @discardableResult
    func step(_ u: ParticleSystem.SimulationUniforms, scheduled: Int? = nil, firstOffset: Int = 0,
              recordEvents: Bool) -> StepEvents {
        let capacity = capacity
        let stride = stride
        if recordEvents && eventFlags.count != capacity { eventFlags = [UInt8](repeating: 0, count: capacity) }
        var events = StepEvents()
        let dtStep = u.disc.w
        let firstSlot = Int(u.spawn.x), spawnCount = Int(u.spawn.y)
        let scheduled = max(scheduled ?? spawnCount, 1)
        let forces = Vec3(u.forces.x, u.forces.y, u.forces.z), drag = u.forces.w
        let turbulence = u.turbulence
        let center = Vec3(u.transform.c3.x, u.transform.c3.y, u.transform.c3.z)
        let groundOn = u.ground.x > 0, groundY = u.ground.y, bounce = u.ground.z, friction = u.ground.w
        let colliderCount = Int(min(u.collision.y, 4))
        let colliders = [u.colliders.0, u.colliders.1, u.colliders.2, u.colliders.3,
                         u.colliders.4, u.colliders.5, u.colliders.6, u.colliders.7]
        let kills = (u.collision.x & 2) != 0
        var alive = 0
        particles.withUnsafeMutableBufferPointer { ps in
            for slot in 0..<capacity {
                var offset = slot - firstSlot
                if offset < 0 { offset += capacity }
                let born = offset < spawnCount
                var dt = dtStep
                if born {
                    let spawnOffset = firstOffset + offset * stride
                    ps[slot] = Self.spawn(u, spawnIndex: u.spawn.z &+ UInt32(truncatingIfNeeded: offset * stride))
                    dt *= (Float(scheduled - spawnOffset) - 0.5) / Float(scheduled)
                }
                var died = false, collided = false
                var p = ps[slot]
                if p.velocity.w > 0 {
                    var position = Vec3(p.position.x, p.position.y, p.position.z)
                    var velocity = Vec3(p.velocity.x, p.velocity.y, p.velocity.z)
                    var acceleration = forces
                    if turbulence.x != 0 {
                        let q = position * turbulence.y, t = turbulence.z
                        let field = Vec3(sinf(q.y * 1.7 + q.z * 0.9 + t), sinf(q.z * 1.3 + q.x * 1.1 + t * 1.21),
                                         sinf(q.x * 1.5 + q.y * 0.7 + t * 0.83))
                        acceleration += field * turbulence.x
                    }
                    if turbulence.w != 0 { acceleration += (center - position) * turbulence.w }
                    velocity += acceleration * dt
                    velocity /= drag * dt + 1
                    position += velocity * dt
                    if groundOn && position.y < groundY && velocity.y < 0 {
                        position.y = (groundY - position.y) * bounce + groundY
                        velocity.y = -velocity.y * bounce
                        velocity.x *= 1 - friction
                        velocity.z *= 1 - friction
                        collided = true
                    }
                    var i = 0
                    while i < colliderCount {
                        if Self.collideAnalytic(&position, &velocity, a: colliders[2 * i], b: colliders[2 * i + 1], bounce: bounce,
                                                friction: friction) {
                            collided = true
                        }
                        i += 1
                    }
                    let age = p.position.w + dt
                    let isAlive = age < p.velocity.w && !(collided && kills)
                    died = !isAlive
                    p.position = Vec4(position.x, position.y, position.z, age)
                    p.velocity = Vec4(velocity.x, velocity.y, velocity.z, isAlive ? p.velocity.w : 0)
                    ps[slot] = p
                }
                if recordEvents { eventFlags[slot] = (died ? 1 : 0) | (collided ? 2 : 0) | (born ? 4 : 0) }
                if p.velocity.w > 0 { alive += 1 }
                if died { events.died += 1 }
                if collided { events.collided += 1 }
                if born { events.born += 1 }
            }
        }
        self.alive = alive
        return events
    }

    // MARK: - Sub-emitters (particle_events.comp, particle_spawn.comp)

    /// The parent's events of `mask` (1 death, 2 collision, 4 birth) this step, in slot order, at
    /// most `maxEvents`: position and velocity.
    func events(mask: UInt8, maxEvents: Int) -> [(position: Vec3, velocity: Vec3)] {
        var out: [(Vec3, Vec3)] = []
        guard !eventFlags.isEmpty else { return out }
        for slot in 0..<capacity where eventFlags[slot] & mask != 0 {
            guard out.count < maxEvents else { break }
            let p = particles[slot]
            out.append((Vec3(p.position.x, p.position.y, p.position.z), Vec3(p.velocity.x, p.velocity.y, p.velocity.z)))
        }
        return out
    }

    /// `perEvent` particles per event into the ring from its cursor (at most the capacity), each
    /// from the emitter's shape and cone (`u`, its transform centered on the event) moved to the
    /// event and inheriting `inheritVelocity` of its velocity.
    func spawnFromEvents(_ events: [(position: Vec3, velocity: Vec3)], perEvent: Int, inheritVelocity: Float,
                         uniforms u: ParticleSystem.SimulationUniforms) {
        let count = min(events.count * perEvent, capacity)
        guard count > 0 else { return }
        for i in 0..<count {
            let event = events[i / perEvent]
            var p = Self.spawn(u, spawnIndex: spawned &+ UInt32(truncatingIfNeeded: i))
            p.position += Vec4(event.position.x, event.position.y, event.position.z, 0)
            p.velocity += Vec4(event.velocity.x, event.velocity.y, event.velocity.z, 0) * inheritVelocity
            particles[(spawnCursor + i) % capacity] = p
        }
        spawnCursor = (spawnCursor + count) % capacity
        spawned &+= UInt32(truncatingIfNeeded: count)
    }

    // MARK: - Draw list (particle_compact.comp, the sort)

    /// Live slots in slot order, or (`sortedFrom`) far to near from that camera position, ties in
    /// slot order (the GPU sort's keys: the distance's inverted float bits, then the slot).
    func buildDrawList(sortedFrom camera: Vec3?) {
        drawList.removeAll(keepingCapacity: true)
        particles.withUnsafeBufferPointer { ps in
            if let camera {
                var keys: [UInt64] = []
                keys.reserveCapacity(alive)
                for slot in 0..<capacity where ps[slot].velocity.w > 0 {
                    let p = ps[slot].position
                    let distance = max(length(Vec3(p.x, p.y, p.z) - camera), 1e-6)
                    keys.append(UInt64(~distance.bitPattern) << 32 | UInt64(slot))
                }
                keys.sort()
                for key in keys { drawList.append(Int32(truncatingIfNeeded: key & 0xFFFF_FFFF)) }
            } else {
                for slot in 0..<capacity where ps[slot].velocity.w > 0 { drawList.append(Int32(slot)) }
            }
        }
        alive = drawList.count
    }

    /// The live particles in draw order (the instance data of the draw).
    func drawRecords() -> [ParticleRecord] {
        particles.withUnsafeBufferPointer { ps in drawList.map { ps[Int($0)] } }
    }
}
