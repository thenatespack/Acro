import Foundation

/// Simulates and draws the `ParticleEmitter`s of a world on the GPU. `SceneRenderer` owns one
/// (`sceneRenderer.particles`, created with the first emitter it sees) and drives it:
///
/// 1. `prepare` (in `SceneRenderer.prepare`) gathers the emitters and decides on the CPU how
///    many fixed steps of `fixedTimestep` run this frame and what each one spawns
///    (`ParticleSpawnSchedule`): counts, ring slots and spawn indices.
/// 2. `simulate` (in `renderShadows`) records one compute pass, `particles`: per emitter, a
///    `particle_simulate` dispatch per step, then a draw list, `particle_compact` (live slots in
///    slot order) or, for `.alpha` emitters, `particle_sort` (back to front).
/// 3. `draw` (in the scene pass, after the transparent meshes) draws each emitter with
///    `drawIndirect`: camera-facing quads, one instance per live particle, with depth testing
///    and no depth writes; alpha emitters first (farthest first), then additive ones.
///
/// It is deterministic: steps are fixed (time comes from `world.time.elapsed`, which
/// `ENGINE_SCREENSHOT` advances by exactly 1/60 s per frame), random numbers hash spawn indices,
/// and draw lists never depend on the order threads run in, so Metal and Vulkan render the
/// same pixels.
@MainActor
public final class ParticleSystem {
    public struct Stats: Sendable, Equatable {
        public var emitters = 0
        /// Slots allocated over all emitters.
        public var capacity = 0
        /// Live particles, read back from the GPU's draw arguments a few frames late (every
        /// `countReadbackInterval` frames).
        public var aliveParticles = 0
        /// Simulation steps and particles spawned this frame.
        public var steps = 0
        public var spawned = 0

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

    private let simulatePipeline: ComputePipeline
    private let compactPipeline: ComputePipeline
    private let sortPipeline: ComputePipeline
    private let shader: ShaderSource
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    private var emitters: [Entity: EmitterState] = [:]
    /// This frame's emitters in draw order.
    private var order: [Entity] = []
    private var cameraPosition = Vec3.zero
    private var frameCount = 0

    private struct PipelineKey: Hashable {
        var blend: ParticleBlend
        var reversedZ: Bool
    }

    /// One step's spawns: `count` particles into the ring from `firstSlot`, spawn indices from `firstIndex`.
    struct Step: Equatable {
        var firstSlot: Int
        var count: Int
        var firstIndex: UInt32
        /// Emitter time at the start of the step (drives the turbulence field).
        var time: Double
    }

    /// GPU buffers and timing of one emitter entity.
    @MainActor private final class EmitterState {
        /// Settings whose change restarts the emitter.
        let key: RestartKey
        let capacity: Int
        /// `capacity` × 48-byte particles.
        let particles: GPUBuffer
        /// Draw arguments (16 bytes), then one live count per workgroup of 256 slots.
        let state: GPUBuffer
        /// Live slots in draw order.
        let drawList: GPUBuffer
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
            state = try device.makeBuffer(length: 16 + capacity / 256 * 4, usage: .storage)
            drawList = try device.makeBuffer(length: capacity * 4, usage: .storage)
        }
    }

    private struct RestartKey: Equatable {
        var capacity: Int
        var blend: ParticleBlend
        var seed: UInt32
    }

    public init(device: RenderDevice) throws {
        self.device = device
        simulatePipeline = try device.makeComputePipeline(shader: ShaderSource.load(compute: "particle_simulate", bundle: .module))
        compactPipeline = try device.makeComputePipeline(shader: ShaderSource.load(compute: "particle_compact", bundle: .module))
        sortPipeline = try device.makeComputePipeline(shader: ShaderSource.load(compute: "particle_sort", bundle: .module))
        shader = try ShaderSource.load(named: "particle", bundle: .module)
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
        var seen = Set<Entity>()
        var additive: [Entity] = [], sorted: [(Entity, Float)] = []
        stats.steps = 0
        stats.spawned = 0
        world.query(ParticleEmitter.self, GlobalTransform.self) { entity, emitter, global in
            let key = RestartKey(capacity: emitter.effectiveCapacity, blend: emitter.blend, seed: emitter.seed)
            if emitters[entity]?.key != key {
                do {
                    emitters[entity] = try EmitterState(key: key, emitter: emitter, device: device)
                } catch {
                    print("ParticleSystem: emitter of \(key.capacity) particles unavailable: \(error)")
                    return
                }
            }
            guard let state = emitters[entity] else { return }
            seen.insert(entity)
            state.emitter = emitter
            state.transform = global.matrix
            schedule(state, elapsed: elapsed)
            if emitter.blend == .alpha {
                let origin = Vec3(global.matrix.c3.x, global.matrix.c3.y, global.matrix.c3.z)
                sorted.append((entity, length(origin - cameraPosition)))
            } else {
                additive.append(entity)
            }
        }
        for entity in emitters.keys where !seen.contains(entity) { emitters[entity] = nil }
        // Alpha emitters back to front (ties in entity order: the sort is stable), then additive ones.
        order = sorted.enumerated().sorted { ($0.element.1, $1.offset) > ($1.element.1, $0.offset) }.map(\.element.0) + additive
        stats.emitters = order.count
        stats.capacity = order.reduce(0) { $0 + emitters[$1]!.capacity }
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
            let requested = state.schedule.step(dt: fixedTimestep, rate: emitter.rate, bursts: emitter.bursts, emitting: emitter.isEmitting)
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

    /// Records the `particles` compute pass: this frame's steps, then each emitter's draw list.
    public func simulate(frame: Frame) {
        guard !order.isEmpty else { return }
        frameCount += 1
        frame.computePass(label: "particles") { pass in
            for entity in order {
                let state = emitters[entity]!
                let groups = ComputeSize(state.capacity / 256)
                pass.setStorageBuffer(state.particles, index: 0)
                pass.setStorageBuffer(state.state, index: 1)
                pass.setStorageBuffer(state.drawList, index: 2)
                pass.setPipeline(simulatePipeline)
                for step in state.steps {
                    pass.setUniformData(simulationUniforms(state, step: step), index: 2)
                    pass.dispatch(groups: groups)
                }
                if state.emitter.blend == .alpha {
                    pass.setPipeline(sortPipeline)
                    let size = 1 << Int(ceil(log2(Double(state.capacity))))
                    pass.setUniformData(SortUniforms(camera: Vec4(cameraPosition, 0), sizes: SIMD4(UInt32(state.capacity), UInt32(size), 0, 0)),
                                        index: 2)
                    pass.dispatch(groups: ComputeSize(1))
                } else {
                    pass.setPipeline(compactPipeline)
                    pass.setUniformData(simulationUniforms(state, step: nil), index: 2)
                    pass.dispatch(groups: groups)
                }
            }
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

    /// Draws every emitter into `pass` (a `.screen` pass with depth: the scene pass or a render
    /// target), seen with `viewProjection` from `cameraPosition`. Call after `simulate`.
    public func draw(in pass: RenderPass, viewProjection: Mat4, cameraPosition: Vec3, reversedZ: Bool) {
        for entity in order {
            guard let state = emitters[entity], let pipeline = pipeline(PipelineKey(blend: state.emitter.blend, reversedZ: reversedZ)) else {
                continue
            }
            pass.setPipeline(pipeline)
            pass.setUniformData(drawUniforms(state.emitter, viewProjection: viewProjection, cameraPosition: cameraPosition), index: 2,
                                stage: .vertex)
            pass.setStorageBuffer(state.particles, index: 0)
            pass.setStorageBuffer(state.drawList, index: 1)
            pass.drawIndirect(state.state, offset: 0)
        }
    }

    private func pipeline(_ key: PipelineKey) -> RenderPipeline? {
        if let pipeline = pipelines[key] { return pipeline }
        var descriptor = PipelineDescriptor(shader: shader, vertexLayout: .none)
        descriptor.cullMode = .none
        descriptor.depthWrite = false
        descriptor.depthCompare = key.reversedZ ? .greater : .less
        descriptor.blendMode = key.blend.blendMode
        do {
            let pipeline = try device.makePipeline(descriptor)
            pipelines[key] = pipeline
            return pipeline
        } catch {
            print("ParticleSystem: pipeline creation failed: \(error)")
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
    }

    /// Must match the `Params` block of particle_sort.comp.
    struct SortUniforms: BitwiseCopyable {
        var camera: Vec4
        var sizes: SIMD4<UInt32>
    }

    /// Must match the `Draw` block of particle.vert.
    struct DrawUniforms: BitwiseCopyable {
        var viewProj: Mat4
        var camera: Vec4
        var colors: (Vec4, Vec4, Vec4, Vec4)
        var colorTimes: Vec4
        var sizes: Vec4
        var sizeTimes: Vec4
        var params: Vec4
        var counts: Vec4
    }

    /// `step` nil: the parameters `particle_compact` reads (no spawns).
    private func simulationUniforms(_ state: EmitterState, step: Step?) -> SimulationUniforms {
        let e = state.emitter
        let shapeKind: Float = switch e.shape {
        case .point: 0
        case .sphere: 1
        case .box: 2
        case .disc: 3
        }
        let direction = length(e.direction) > 1e-6 ? normalize(e.direction) : Vec3(0, 1, 0)
        let spawn = step.map { SIMD4<UInt32>(UInt32($0.firstSlot), UInt32($0.count), $0.firstIndex, e.seed) } ?? SIMD4(0, 0, 0, e.seed)
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
            info: SIMD4(UInt32(state.capacity), UInt32(state.capacity / 256), 0, 0),
            arms: Vec4(Self.armRotation(e, time: step?.time ?? 0), 0, 0, 0))
    }

    /// How far the spiral arms have turned after `time` seconds: with an attraction everything
    /// orbits at the same angular speed, so spawning along arms that turn with it keeps them sharp.
    nonisolated static func armRotation(_ e: ParticleEmitter, time: Double) -> Float {
        guard e.attraction > 0 else { return 0 }
        let angularSpeed = Double(e.orbit) * Double(e.attraction).squareRoot()
        return Float((angularSpeed * time).truncatingRemainder(dividingBy: 2 * .pi))
    }

    private func drawUniforms(_ e: ParticleEmitter, viewProjection: Mat4, cameraPosition: Vec3) -> DrawUniforms {
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
            params: Vec4(max(e.stretch, 0), e.intensity, min(max(e.brightnessVariation, 0), 1), 0),
            counts: Vec4(Float(max(min(e.color.count, 4), 1)), Float(max(min(e.sizeOverLife.count, 4), 1)), 0, 0))
    }
}
