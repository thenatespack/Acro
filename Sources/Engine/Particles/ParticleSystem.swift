import Foundation

/// The scene's depth as a depth prepass rendered it (`SceneRenderer`), for soft particles and
/// depth-buffer collisions: a `.depth32Float` texture at the pass's size.
public struct ParticleSceneDepth {
    public var texture: GPUTexture
    /// The (jittered) view-projection it was rendered with.
    public var viewProjection: Mat4
    public var cameraPosition: Vec3
    /// View depth of a depth value z: `linear.x / (z + linear.y)` (perspective projections,
    /// standard or reversed Z).
    public var linear: Vec2

    public init(texture: GPUTexture, viewProjection: Mat4, projection: Mat4, cameraPosition: Vec3) {
        self.texture = texture
        self.viewProjection = viewProjection
        self.cameraPosition = cameraPosition
        // clip z = c2.z · z + c3.z and clip w = -z for view-space z: depth = c3.z / (ndc z + c2.z).
        linear = Vec2(projection.c3.z, projection.c2.z)
    }
}

/// Simulates and draws the `ParticleEmitter`s of a world on the GPU. `SceneRenderer` owns one
/// (`sceneRenderer.particles`, created with the first emitter it sees) and drives it:
///
/// 1. `prepare` (in `SceneRenderer.prepare`) gathers the emitters and decides on the CPU how
///    many fixed steps of `fixedTimestep` run this frame and what each one spawns
///    (`ParticleSpawnSchedule`): counts, ring slots and spawn indices. Sub-emitter targets
///    don't schedule: they step with the emitter that drives them.
/// 2. `simulate` (in `renderShadows`) records one compute pass, `particles`: per emitter, a
///    `particle_simulate` dispatch per step (each followed, for every sub-emitter, by
///    `particle_events`, an indirect `particle_spawn` and the child's step), then a draw list:
///    `particle_compact` (live slots in slot order) and, for `.alpha` emitters, a multi-pass
///    bitonic sort back to front whose passes are dispatched indirectly, sized by the live count.
/// 3. `draw` (in the scene pass, after the transparent meshes) draws each emitter with
///    `drawIndirect`: camera-facing quads, one instance per live particle, with depth testing
///    and no depth writes; alpha emitters first (farthest first), then additive ones.
///
/// It is deterministic: steps are fixed (time comes from `world.time.elapsed`, which
/// `ENGINE_SCREENSHOT` advances by exactly 1/60 s per frame), random numbers hash spawn indices,
/// and draw lists and sub-emitter events never depend on the order threads run in, so Metal
/// and Vulkan render the same pixels.
@MainActor
public final class ParticleSystem {
    public struct Stats: Sendable, Equatable {
        public var emitters = 0
        /// Slots allocated over all emitters.
        public var capacity = 0
        /// Live particles, read back from the GPU's draw arguments a few frames late (every
        /// `countReadbackInterval` frames).
        public var aliveParticles = 0
        /// Simulation steps and particles spawned (on the CPU's schedule, not by sub-emitters) this frame.
        public var steps = 0
        public var spawned = 0
        /// Parent → child sub-emitter links in use.
        public var subEmitterLinks = 0

        public init() {}
    }

    public let device: RenderDevice
    /// Length of one simulation step in seconds.
    public var fixedTimestep: Double = 1.0 / 60
    /// Steps per frame at most; time beyond is dropped (the prewarm isn't limited).
    public var maxStepsPerFrame = 8
    /// Frames between reads of the live counts (`stats.aliveParticles`); 0 turns them off.
    public var countReadbackInterval = 10
    public private(set) var stats = Stats()
    /// The scene's depth this frame (`SceneRenderer`'s depth prepass), for `collidesWithDepth`;
    /// set it before `simulate`. nil: depth collisions are off.
    public var sceneDepth: ParticleSceneDepth?
    /// Resolves `ParticleEmitter.texture` (`SceneRenderer` sets its `texture(_:)`).
    public var textureResolver: ((TextureHandle) -> GPUTexture?)?
    /// Some emitter this frame needs the scene's depth (`ParticleEmitter.needsSceneDepth`).
    public private(set) var needsSceneDepth = false
    /// Some emitter this frame is `lit` (its vertex shader reads the scene's lights).
    public private(set) var hasLitEmitters = false

    private let simulatePipeline: ComputePipeline
    private let compactPipeline: ComputePipeline
    private let eventsPipeline: ComputePipeline
    private let spawnPipeline: ComputePipeline
    private let sortArgsPipeline: ComputePipeline
    private let sortKeysPipeline: ComputePipeline
    private let sortLocalPipeline: ComputePipeline
    private let sortGlobalPipeline: ComputePipeline
    private let sortWritePipeline: ComputePipeline
    private let shader: ShaderSource
    private var litShader: ShaderSource?
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    /// Bound where a texture is declared but unused (no flipbook, no scene depth).
    private let whiteTexture: GPUTexture
    private let sampler: GPUSampler
    /// Bound as the event flags of emitters without sub-emitters (never written).
    private let placeholderBuffer: GPUBuffer
    private var emitters: [Entity: EmitterState] = [:]
    /// This frame's emitters in draw order.
    private var order: [Entity] = []
    private var cameraPosition = Vec3.zero
    private var frameCount = 0

    private struct PipelineKey: Hashable {
        var blend: ParticleBlend
        var reversedZ: Bool
        var lit: Bool
    }

    /// One step's spawns: `count` particles into the ring from `firstSlot`, spawn indices from `firstIndex`.
    struct Step: Equatable {
        var firstSlot: Int
        var count: Int
        var firstIndex: UInt32
        /// Emitter time at the start of the step (drives the turbulence field).
        var time: Double
    }

    /// A parent's sub-emitter in use this frame.
    private struct Link {
        var child: Entity
        var sub: ParticleSubEmitter
        /// Events kept per step: more couldn't spawn anyway.
        var maxEvents: Int
    }

    /// GPU buffers and timing of one emitter entity.
    @MainActor private final class EmitterState {
        /// Settings whose change restarts the emitter.
        let key: RestartKey
        let capacity: Int
        var groups: Int { capacity / 256 }
        /// `capacity` × 48-byte particles.
        let particles: GPUBuffer
        /// Draw arguments (16 bytes), then per workgroup of 256 slots: live, died and collided counts.
        let state: GPUBuffer
        /// Live slots in draw order.
        let drawList: GPUBuffer
        /// `.alpha`: the sorted length's capacity (a power of two, at least 2048), the sort keys
        /// (key, slot pairs) and the sort passes' indirect arguments (`particle_sort_args.comp`).
        let sortCapacity: Int
        let sortKeys: GPUBuffer?
        let sortArgs: GPUBuffer?
        /// Parents: each slot's event flags this step (created with the first sub-emitter).
        var eventFlags: GPUBuffer?
        /// Parents: each link's event list (by link index), with the events it holds.
        var eventLists: [Int: (buffer: GPUBuffer, events: Int)] = [:]
        /// Sub-emitter targets: their GPU-side spawn state (`particle_events.comp`).
        var spawner: GPUBuffer?
        var links: [Link] = []
        /// Stepped by a parent (a sub-emitter target) instead of its own schedule.
        var driven = false
        var schedule = ParticleSpawnSchedule()
        /// The ring slot the next particle spawns into.
        var cursor = 0
        /// `world.time.elapsed` last frame (nil before the first one: prewarm then).
        var lastElapsed: Double?
        var pendingTime = 0.0
        var alive = 0
        var emitter: ParticleEmitter
        var transform = Mat4.identity
        var steps: [Step] = []

        init(key: RestartKey, emitter: ParticleEmitter, device: RenderDevice) throws {
            self.key = key
            self.emitter = emitter
            capacity = key.capacity
            particles = try device.makeBuffer(length: capacity * 48, usage: .storage)
            state = try device.makeBuffer(length: 16 + capacity / 256 * 3 * 4, usage: .storage)
            drawList = try device.makeBuffer(length: capacity * 4, usage: .storage)
            if key.blend == .alpha {
                sortCapacity = ParticleSystem.sortCapacity(for: capacity)
                sortKeys = try device.makeBuffer(length: sortCapacity * 8, usage: .storage)
                sortArgs = try device.makeBuffer(length: 16 + 12 * (3 + 2 * ParticleSystem.mergeStages(sortCapacity)), usage: .storage)
            } else {
                sortCapacity = 0
                sortKeys = nil
                sortArgs = nil
            }
        }
    }

    private struct RestartKey: Equatable {
        var capacity: Int
        var blend: ParticleBlend
        var seed: UInt32
    }

    /// The sorted length's capacity for `capacity` particles: a power of two, at least one 2048-element block.
    nonisolated static func sortCapacity(for capacity: Int) -> Int {
        var n = 2048
        while n < capacity { n <<= 1 }
        return n
    }

    /// Merge stages wider than a block (widths 4096 ... `sortCapacity`).
    nonisolated static func mergeStages(_ sortCapacity: Int) -> Int {
        sortCapacity.trailingZeroBitCount - 11
    }

    public init(device: RenderDevice) throws {
        self.device = device
        func compute(_ name: String) throws -> ComputePipeline {
            try device.makeComputePipeline(shader: ShaderSource.load(compute: name, bundle: .module))
        }
        simulatePipeline = try compute("particle_simulate")
        compactPipeline = try compute("particle_compact")
        eventsPipeline = try compute("particle_events")
        spawnPipeline = try compute("particle_spawn")
        sortArgsPipeline = try compute("particle_sort_args")
        sortKeysPipeline = try compute("particle_sort_keys")
        sortLocalPipeline = try compute("particle_sort_local")
        sortGlobalPipeline = try compute("particle_sort_global")
        sortWritePipeline = try compute("particle_sort_write")
        shader = try ShaderSource.load(named: "particle", bundle: .module)
        whiteTexture = try device.makeTexture(pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm)
        sampler = try device.makeSampler(SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear,
                                                           addressMode: .clampToEdge))
        placeholderBuffer = try device.makeBuffer(length: 16, usage: .storage)
    }

    /// `entity`'s particle, draw list and state buffers (tests read them back).
    func buffers(of entity: Entity) -> (particles: GPUBuffer, drawList: GPUBuffer, state: GPUBuffer)? {
        emitters[entity].map { ($0.particles, $0.drawList, $0.state) }
    }

    /// Adds `count` particles to `entity`'s emitter at its next step (even while it isn't emitting).
    public func burst(_ count: Int, from entity: Entity) {
        emitters[entity]?.schedule.pendingBurst += max(count, 0)
    }

    /// Gathers every `ParticleEmitter` with a `GlobalTransform` and schedules this frame's steps
    /// from `world.time.elapsed`. `cameraPosition` orders alpha emitters and their particles.
    public func prepare(world: World, cameraPosition: Vec3) {
        self.cameraPosition = cameraPosition
        let elapsed = world.time.elapsed
        var found: [(entity: Entity, emitter: ParticleEmitter, transform: Mat4)] = []
        world.query(ParticleEmitter.self, GlobalTransform.self) { entity, emitter, global in
            found.append((entity, emitter, global.matrix))
        }
        let drivers = Self.subEmitterDrivers(found.map { ($0.entity, $0.emitter) }) { world.resolve($0) }
        var seen = Set<Entity>()
        var additive: [Entity] = [], sorted: [(Entity, Float)] = []
        stats.steps = 0
        stats.spawned = 0
        stats.subEmitterLinks = 0
        for (entity, emitter, transform) in found {
            let key = RestartKey(capacity: emitter.effectiveCapacity, blend: emitter.blend, seed: emitter.seed)
            if emitters[entity]?.key != key {
                do {
                    emitters[entity] = try EmitterState(key: key, emitter: emitter, device: device)
                } catch {
                    EngineLog.warning("emitter of \(key.capacity) particles unavailable: \(error)", category: .particles)
                    continue
                }
            }
            guard let state = emitters[entity] else { continue }
            seen.insert(entity)
            state.emitter = emitter
            state.transform = transform
            state.driven = drivers[entity] != nil
            if !state.driven { schedule(state, elapsed: elapsed) }
            if emitter.blend == .alpha {
                let origin = Vec3(transform.c3.x, transform.c3.y, transform.c3.z)
                sorted.append((entity, length(origin - cameraPosition)))
            } else {
                additive.append(entity)
            }
        }
        for entity in emitters.keys where !seen.contains(entity) { emitters[entity] = nil }
        // Sub-emitter links, and their targets' steps: the parent's, without spawns of their own.
        for (entity, emitter, _) in found {
            guard let parent = emitters[entity] else { continue }
            parent.links = []
            guard !parent.driven else { continue }
            for sub in emitter.subEmitters.prefix(ParticleEmitter.maxSubEmitters) {
                guard let target = world.resolve(sub.emitter), drivers[target] == entity, let child = emitters[target] else { continue }
                let count = min(max(sub.count, 1), ParticleEmitter.maxSubEmitterCount)
                parent.links.append(Link(child: target, sub: sub, maxEvents: min(parent.capacity, max(child.capacity / count, 1))))
                child.steps = parent.steps.map { Step(firstSlot: 0, count: 0, firstIndex: 0, time: $0.time) }
                child.lastElapsed = elapsed
            }
            stats.subEmitterLinks += parent.links.count
        }
        // Alpha emitters back to front (ties in entity order: the sort is stable), then additive ones.
        order = sorted.enumerated().sorted { ($0.element.1, $1.offset) > ($1.element.1, $0.offset) }.map(\.element.0) + additive
        // A target whose driver went away runs nothing until it is scheduled again.
        for entity in order where emitters[entity]!.driven && !emitters.values.contains(where: { $0.links.contains { $0.child == entity } }) {
            emitters[entity]!.steps = []
        }
        stats.emitters = order.count
        stats.capacity = order.reduce(0) { $0 + emitters[$1]!.capacity }
        needsSceneDepth = order.contains { emitters[$0]!.emitter.needsSceneDepth }
        hasLitEmitters = order.contains { emitters[$0]!.emitter.lit }
    }

    /// Which emitter drives each sub-emitter target: the first (in `emitters` order) that names
    /// it and isn't a target itself (sub-emitters don't nest). An emitter can't drive itself.
    nonisolated static func subEmitterDrivers<E: Hashable>(_ emitters: [(E, ParticleEmitter)], resolve: (EntityRef) -> E?) -> [E: E] {
        let present = Set(emitters.map(\.0))
        var targets: [(parent: E, child: E)] = []
        for (entity, emitter) in emitters {
            for sub in emitter.subEmitters.prefix(ParticleEmitter.maxSubEmitters) {
                if let child = resolve(sub.emitter), child != entity, present.contains(child) { targets.append((entity, child)) }
            }
        }
        let anyTarget = Set(targets.map(\.child))
        var drivers: [E: E] = [:]
        for (parent, child) in targets where !anyTarget.contains(parent) && drivers[child] == nil { drivers[child] = parent }
        return drivers
    }

    /// Decides the fixed steps `state` runs this frame and what each spawns.
    private func schedule(_ state: EmitterState, elapsed: Double) {
        var limit = maxStepsPerFrame
        if let last = state.lastElapsed {
            // Time going backwards (a restored snapshot) just continues from there.
            state.pendingTime += max(elapsed - last, 0)
        } else {
            state.pendingTime = Double(max(state.emitter.prewarm, 0))
            limit = Int.max
        }
        state.lastElapsed = elapsed
        let emitter = state.emitter
        state.steps.removeAll(keepingCapacity: true)
        while state.pendingTime + 1e-9 >= fixedTimestep && state.steps.count < limit {
            state.pendingTime -= fixedTimestep
            let time = state.schedule.time
            let before = state.schedule.spawned
            let requested: Int
            if emitter.startDelay > 0 {
                // Timing offset: nothing spawns until the delay has passed; bursts are relative to it.
                let delay = Double(emitter.startDelay)
                var bursts = emitter.bursts
                for i in bursts.indices { bursts[i].time += emitter.startDelay }
                requested = state.schedule.step(dt: fixedTimestep, rate: emitter.rate, bursts: bursts,
                                                emitting: emitter.isEmitting && state.schedule.time + fixedTimestep > delay)
            } else {
                requested = state.schedule.step(dt: fixedTimestep, rate: emitter.rate, bursts: emitter.bursts, emitting: emitter.isEmitting)
            }
            // More than the ring holds: the first ones would be overwritten at once; skip them.
            let count = min(requested, state.capacity)
            let firstIndex = before + UInt64(requested - count)
            state.steps.append(Step(firstSlot: state.cursor, count: count, firstIndex: UInt32(truncatingIfNeeded: firstIndex), time: time))
            state.cursor = (state.cursor + count) % state.capacity
            stats.spawned += count
        }
        if state.steps.count == limit { state.pendingTime = min(state.pendingTime, fixedTimestep) }
        stats.steps += state.steps.count
    }

    /// Records the `particles` compute pass: this frame's steps (with their sub-emitters), then
    /// each emitter's draw list.
    public func simulate(frame: Frame) {
        guard !order.isEmpty else { return }
        frameCount += 1
        frame.computePass(label: "particles") { pass in
            for entity in order {
                let state = emitters[entity]!
                guard !state.driven else { continue }
                for (i, step) in state.steps.enumerated() {
                    simulateStep(state, step: step, in: pass)
                    for (index, link) in state.links.enumerated() {
                        guard let child = emitters[link.child], i < child.steps.count else { continue }
                        spawnSubEmitter(link, index: index, parent: state, child: child, in: pass)
                        simulateStep(child, step: child.steps[i], in: pass)
                    }
                }
            }
            for entity in order { buildDrawList(emitters[entity]!, in: pass) }
        }
        guard countReadbackInterval > 0, frameCount % countReadbackInterval == 1 || countReadbackInterval == 1 else { return }
        for entity in order {
            let state = emitters[entity]!
            frame.readBack(state.state, offset: 0, length: 8) { [weak self, weak state] bytes in
                guard let self, let state else { return }
                state.alive = Int(bytes.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
                stats.aliveParticles = emitters.values.reduce(0) { $0 + $1.alive }
            }
        }
    }

    private func simulateStep(_ state: EmitterState, step: Step, in pass: ComputePass) {
        pass.setPipeline(simulatePipeline)
        pass.setStorageBuffer(state.particles, index: 0)
        pass.setStorageBuffer(state.state, index: 1)
        if !state.links.isEmpty, state.eventFlags == nil {
            do {
                state.eventFlags = try device.makeBuffer(length: state.capacity * 4, usage: .storage)
            } catch {
                EngineLog.warning("sub-emitter events unavailable: \(error)", category: .particles)
            }
        }
        pass.setStorageBuffer(state.eventFlags ?? placeholderBuffer, index: 3)
        let depth = state.emitter.collidesWithDepth ? sceneDepth : nil
        pass.setTexture(depth?.texture ?? whiteTexture, index: 1)
        pass.setSampler(sampler, index: 1)
        pass.setUniformData(simulationUniforms(state, step: step, depth: depth), index: 2)
        pass.dispatch(groups: ComputeSize(state.groups))
    }

    /// `particle_events` (the parent's events this step → the link's event list and the child's
    /// spawn range), then `particle_spawn`, dispatched indirectly with the workgroups it computed.
    private func spawnSubEmitter(_ link: Link, index: Int, parent: EmitterState, child: EmitterState, in pass: ComputePass) {
        guard let flags = parent.eventFlags else { return }
        do {
            if child.spawner == nil { child.spawner = try device.makeBuffer(length: 48, usage: .storage) }
            if parent.eventLists[index]?.events != link.maxEvents {
                parent.eventLists[index] = (try device.makeBuffer(length: link.maxEvents * 32, usage: .storage), link.maxEvents)
            }
        } catch {
            EngineLog.warning("sub-emitter buffers unavailable: \(error)", category: .particles)
            return
        }
        guard let spawner = child.spawner, let events = parent.eventLists[index]?.buffer else { return }
        let perEvent = min(max(link.sub.count, 1), ParticleEmitter.maxSubEmitterCount)
        let mask: UInt32 = link.sub.trigger == .death ? 1 : 2
        let countsOffset = 4 + parent.groups * (link.sub.trigger == .death ? 1 : 2)
        pass.setPipeline(eventsPipeline)
        pass.setStorageBuffer(parent.particles, index: 0)
        pass.setStorageBuffer(parent.state, index: 1)
        pass.setStorageBuffer(flags, index: 3)
        pass.setStorageBuffer(events, index: 4)
        pass.setStorageBuffer(spawner, index: 5)
        pass.setPushConstants(EventPush(
            parent: SIMD4(UInt32(parent.capacity), UInt32(parent.groups), mask, UInt32(countsOffset)),
            child: SIMD4(UInt32(link.maxEvents), UInt32(perEvent), UInt32(child.capacity), 0)))
        pass.dispatch(groups: ComputeSize(parent.groups))

        pass.setPipeline(spawnPipeline)
        pass.setStorageBuffer(child.particles, index: 0)
        var uniforms = simulationUniforms(child, step: nil, depth: nil)
        uniforms.transform.c3 = Vec4(0, 0, 0, 1)  // centered on each event
        pass.setUniformData(uniforms, index: 2)
        pass.setPushConstants(SpawnPush(perEvent: UInt32(perEvent), inheritVelocity: link.sub.inheritVelocity))
        pass.dispatchIndirect(buffer: spawner, offset: 0)
    }

    /// `particle_compact`, then for `.alpha` emitters the back-to-front sort: arguments, keys,
    /// 2048-element block sorts, then per wider merge stage its global steps and a block merge,
    /// and the sorted draw list, every pass after the first dispatched indirectly.
    private func buildDrawList(_ state: EmitterState, in pass: ComputePass) {
        pass.setPipeline(compactPipeline)
        pass.setStorageBuffer(state.particles, index: 0)
        pass.setStorageBuffer(state.state, index: 1)
        pass.setStorageBuffer(state.drawList, index: 2)
        pass.setUniformData(simulationUniforms(state, step: nil, depth: nil), index: 2)
        pass.dispatch(groups: ComputeSize(state.groups))
        guard let args = state.sortArgs, let keys = state.sortKeys else { return }
        let stages = Self.mergeStages(state.sortCapacity)
        func entry(_ e: Int) -> Int { 16 + 12 * e }
        pass.setStorageBuffer(args, index: 6)
        pass.setStorageBuffer(keys, index: 7)
        pass.setPipeline(sortArgsPipeline)
        pass.setPushConstants(SIMD4<UInt32>(UInt32(state.sortCapacity), UInt32(stages), 0, 0))
        pass.dispatch(groups: ComputeSize(1))
        pass.setPipeline(sortKeysPipeline)
        pass.setUniformData(Vec4(cameraPosition, 0), index: 2)
        pass.dispatchIndirect(buffer: args, offset: entry(0))
        pass.setPipeline(sortLocalPipeline)
        pass.setPushConstants(SIMD4<UInt32>(0, 0, 0, 0))
        pass.dispatchIndirect(buffer: args, offset: entry(1))
        for stage in 0..<stages {
            let k = 4096 << stage
            pass.setPipeline(sortGlobalPipeline)
            var j = k / 2
            while j >= 2048 {
                pass.setPushConstants(SIMD4<UInt32>(UInt32(k), UInt32(j), 0, 0))
                pass.dispatchIndirect(buffer: args, offset: entry(2 + 2 * stage))
                j /= 2
            }
            pass.setPipeline(sortLocalPipeline)
            pass.setPushConstants(SIMD4<UInt32>(UInt32(k), 0, 0, 0))
            pass.dispatchIndirect(buffer: args, offset: entry(3 + 2 * stage))
        }
        pass.setPipeline(sortWritePipeline)
        pass.dispatchIndirect(buffer: args, offset: entry(2 + 2 * stages))
    }

    /// Draws every emitter into `pass` (a `.screen` pass with depth: the scene pass or a render
    /// target), seen with `viewProjection` from `cameraPosition`. Call after `simulate`.
    /// `sceneDepth` (the pass's opaque depth, at its size) enables soft particles. `lit`
    /// emitters need `SceneRenderer`'s frame uniforms, and for the vertex stage its light
    /// buffers, environment atlas and shadow atlas (see particle_lighting.glsl).
    public func draw(in pass: RenderPass, viewProjection: Mat4, cameraPosition: Vec3, reversedZ: Bool,
                     sceneDepth: ParticleSceneDepth? = nil) {
        for entity in order {
            guard let state = emitters[entity],
                  let pipeline = pipeline(PipelineKey(blend: state.emitter.blend, reversedZ: reversedZ, lit: state.emitter.lit)) else {
                continue
            }
            let texture = state.emitter.texture.flatMap { textureResolver?($0) }
            let depth = state.emitter.softness > 0 ? sceneDepth : nil
            pass.setPipeline(pipeline)
            pass.setUniformData(drawUniforms(state.emitter, viewProjection: viewProjection, cameraPosition: cameraPosition,
                                             textured: texture != nil, depth: depth), index: 2, stage: .all)
            pass.setStorageBuffer(state.particles, index: 0)
            pass.setStorageBuffer(state.drawList, index: 1)
            pass.setTexture(texture ?? whiteTexture, index: 1)
            pass.setTexture(depth?.texture ?? whiteTexture, index: 2)
            pass.setSampler(sampler, index: 1, stage: .all)
            pass.drawIndirect(state.state, offset: 0)
        }
    }

    private func pipeline(_ key: PipelineKey) -> RenderPipeline? {
        if let pipeline = pipelines[key] { return pipeline }
        do {
            if key.lit && litShader == nil { litShader = try ShaderSource.load(vertex: "particle_lit", fragment: "particle", bundle: .module) }
            var descriptor = PipelineDescriptor(shader: key.lit ? litShader! : shader, vertexLayout: .none)
            descriptor.cullMode = .none
            descriptor.depthWrite = false
            descriptor.depthCompare = key.reversedZ ? .greater : .less
            descriptor.blendMode = key.blend.blendMode
            let pipeline = try device.makePipeline(descriptor)
            pipelines[key] = pipeline
            return pipeline
        } catch {
            EngineLog.error("pipeline creation failed: \(error)", category: .particles)
            return nil
        }
    }

    // MARK: - Uniforms

    /// Must match `EmitterParams` in particles.glsl.
    struct SimulationUniforms: BitwiseCopyable {
        var transform: Mat4
        var shape: Vec4
        var direction: Vec4
        var speedLife: Vec4
        var sizeSpin: Vec4
        var forces: Vec4
        var turbulence: Vec4
        var ground: Vec4
        var disc: Vec4
        var spawn: SIMD4<UInt32>
        var info: SIMD4<UInt32>
        var arms: Vec4
        var collision: SIMD4<UInt32>
        var depthParams: Vec4
        var depthLinear: Vec4
        var camera: Vec4
        var viewProj: Mat4
        var inverseViewProj: Mat4
        var colliders: (Vec4, Vec4, Vec4, Vec4, Vec4, Vec4, Vec4, Vec4)
    }

    /// The push constants of particle_events.comp.
    struct EventPush: BitwiseCopyable {
        var parent: SIMD4<UInt32>
        var child: SIMD4<UInt32>
    }

    /// The push constants of particle_spawn.comp.
    struct SpawnPush: BitwiseCopyable {
        var perEvent: UInt32
        var inheritVelocity: Float
    }

    /// Must match the `Draw` block of particle_draw.glsl.
    struct DrawUniforms: BitwiseCopyable {
        var viewProj: Mat4
        var camera: Vec4
        var colors: (Vec4, Vec4, Vec4, Vec4)
        var colorTimes: Vec4
        var sizes: Vec4
        var sizeTimes: Vec4
        var params: Vec4
        var counts: Vec4
        var atlas: Vec4
        var atlasFlags: Vec4
        var soft: Vec4
    }

    /// The collision flags of particles.glsl.
    private static let collideDepth: UInt32 = 1, collideKills: UInt32 = 2, recordEvents: UInt32 = 4

    /// `step` nil: the parameters `particle_compact` and `particle_spawn` read (no spawns).
    private func simulationUniforms(_ state: EmitterState, step: Step?, depth: ParticleSceneDepth?) -> SimulationUniforms {
        let e = state.emitter
        let shapeKind: Float = switch e.shape {
        case .point: 0
        case .sphere: 1
        case .box: 2
        case .disc: 3
        }
        let direction = length(e.direction) > 1e-6 ? normalize(e.direction) : Vec3(0, 1, 0)
        let spawn = step.map { SIMD4<UInt32>(UInt32($0.firstSlot), UInt32($0.count), $0.firstIndex, e.seed) } ?? SIMD4(0, 0, 0, e.seed)
        var flags: UInt32 = 0
        if depth != nil { flags |= Self.collideDepth }
        if e.killOnCollision { flags |= Self.collideKills }
        if !state.links.isEmpty && state.eventFlags != nil { flags |= Self.recordEvents }
        let colliders = Array(e.colliders.prefix(ParticleEmitter.maxColliders))
        var packed = [Vec4](repeating: .zero, count: 8)
        for (i, collider) in colliders.enumerated() {
            let kind: Float = switch collider.kind {
            case .plane: 0
            case .sphere: 1
            case .box: 2
            }
            var size = collider.size
            if collider.kind == .plane { size = length(size) > 1e-6 ? normalize(size) : Vec3(0, 1, 0) }
            packed[2 * i] = Vec4(collider.center, kind + (collider.inside && collider.kind != .plane ? 4 : 0))
            packed[2 * i + 1] = Vec4(size, 0)
        }
        let size = depth.map { Vec2(Float($0.texture.width), Float($0.texture.height)) } ?? Vec2(1, 1)
        return SimulationUniforms(
            transform: state.transform,
            shape: Vec4(shapeKind, e.shapeSize.x, e.shapeSize.y, e.shapeSize.z),
            direction: Vec4(direction, cosf(min(max(e.spread, 0), .pi))),
            speedLife: Vec4(e.speed.x, e.speed.y, e.lifetime.x, e.lifetime.y),
            sizeSpin: Vec4(e.size.x, e.size.y, e.spin, e.orbit),
            forces: Vec4(e.gravity, max(e.drag, 0)),
            turbulence: Vec4(e.turbulence, e.turbulenceFrequency, Float((step?.time ?? 0).truncatingRemainder(dividingBy: 1000)),
                             e.attraction),
            ground: Vec4(e.collidesWithGround ? 1 : 0, e.groundHeight, e.bounce, e.friction),
            disc: Vec4(Float(max(e.spiralArms, 0)), e.spiralTwist, e.armWidth, Float(fixedTimestep)),
            spawn: spawn,
            info: SIMD4(UInt32(state.capacity), UInt32(state.groups), 0, 0),
            arms: Vec4(Self.armRotation(e, time: step?.time ?? 0), 0, 0, 0),
            collision: SIMD4(flags, UInt32(colliders.count), 0, 0),
            depthParams: Vec4(max(e.depthThickness, 0), size.x, size.y, 0),
            depthLinear: Vec4(depth?.linear.x ?? 1, depth?.linear.y ?? 0, 0, 0),
            camera: Vec4(depth?.cameraPosition ?? .zero, 0),
            viewProj: depth?.viewProjection ?? .identity,
            inverseViewProj: depth?.viewProjection.inverse ?? .identity,
            colliders: (packed[0], packed[1], packed[2], packed[3], packed[4], packed[5], packed[6], packed[7]))
    }

    /// How far the spiral arms have turned after `time` seconds: with an attraction everything
    /// orbits at the same angular speed, so spawning along arms that turn with it keeps them sharp.
    nonisolated static func armRotation(_ e: ParticleEmitter, time: Double) -> Float {
        guard e.attraction > 0 else { return 0 }
        let angularSpeed = Double(e.orbit) * Double(e.attraction).squareRoot()
        return Float((angularSpeed * time).truncatingRemainder(dividingBy: 2 * .pi))
    }

    private func drawUniforms(_ e: ParticleEmitter, viewProjection: Mat4, cameraPosition: Vec3, textured: Bool,
                              depth: ParticleSceneDepth?) -> DrawUniforms {
        func key<T>(_ keys: [T], _ i: Int) -> T? { keys.isEmpty ? nil : keys[min(i, keys.count - 1)] }
        let colors = (0..<4).map { key(e.color, $0)?.color ?? Vec4(1, 1, 1, 1) }
        let colorTimes = (0..<4).map { key(e.color, $0)?.time ?? 0 }
        let sizes = (0..<4).map { key(e.sizeOverLife, $0)?.value ?? 1 }
        let sizeTimes = (0..<4).map { key(e.sizeOverLife, $0)?.time ?? 0 }
        return DrawUniforms(
            viewProj: viewProjection, camera: Vec4(cameraPosition, 0),
            colors: (colors[0], colors[1], colors[2], colors[3]),
            colorTimes: Vec4(colorTimes[0], colorTimes[1], colorTimes[2], colorTimes[3]),
            sizes: Vec4(sizes[0], sizes[1], sizes[2], sizes[3]),
            sizeTimes: Vec4(sizeTimes[0], sizeTimes[1], sizeTimes[2], sizeTimes[3]),
            params: Vec4(max(e.stretch, 0), e.intensity, min(max(e.brightnessVariation, 0), 1), e.stretchMode == .streak ? 1 : 0),
            counts: Vec4(Float(max(min(e.color.count, 4), 1)), Float(max(min(e.sizeOverLife.count, 4), 1)), 0, 0),
            atlas: Vec4(Float(max(e.atlasColumns, 1)), Float(max(e.atlasRows, 1)), Float(e.effectiveFrameCount), max(e.frameRate, 0)),
            atlasFlags: Vec4(e.randomStartFrame ? 1 : 0, e.frameBlending ? 1 : 0, textured ? 1 : 0, 0),
            soft: Vec4(depth != nil ? 1 / e.softness : 0, depth?.linear.x ?? 1, depth?.linear.y ?? 0, e.receivesShadows ? 1 : 0))
    }
}
