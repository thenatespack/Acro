import Foundation
import Testing
@testable import Engine

/// A counter jobs can bump from any thread.
private final class JobSystemTestsCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Int] = []
    func append(_ value: Int) { lock.withLock { values.append(value) } }
    var all: [Int] { lock.withLock { values } }
}

@Suite struct JobSystemTests {
    @Test func threadCountComesFromTheEnvironment() {
        #expect(JobSystem.threadCount(environment: ["ENGINE_JOB_THREADS": "1"]) == 1)
        #expect(JobSystem.threadCount(environment: ["ENGINE_JOB_THREADS": "0"]) == 0)
        #expect(JobSystem.threadCount(environment: ["ENGINE_JOB_THREADS": "6"]) == 6)
        let fallback = JobSystem.threadCount(environment: [:])
        #expect(fallback >= 1 && fallback <= 16)
        #expect(JobSystem.threadCount(environment: ["ENGINE_JOB_THREADS": "lots"]) == fallback)
        #expect(JobSystem(threadCount: 0).isInline)
        #expect(JobSystem(threadCount: 1).isInline)
        let pool = JobSystem(threadCount: 3)
        defer { pool.shutdown() }
        #expect(pool.workerCount == 2 && pool.threadCount == 3 && !pool.isInline)
    }

    @Test(arguments: [1, 2, 4, 8])
    func parallelForCoversEveryIndexOnce(threads: Int) {
        let jobs = JobSystem(threadCount: threads)
        defer { jobs.shutdown() }
        for (count, batch) in [(0, 4), (1, 4), (7, 3), (1000, 1), (1000, 64), (12345, 100)] {
            var hits = [Int](repeating: 0, count: count)
            hits.withUnsafeMutableBufferPointer { out in
                jobs.parallelFor(0..<count, batchSize: batch) { range in
                    #expect(range.count <= batch)
                    for i in range { out[i] += 1 }
                }
            }
            #expect(hits.allSatisfy { $0 == 1 })
        }
        // Ranges not starting at zero.
        let squares = jobs.parallelMap(100, batchSize: 7) { $0 * $0 }
        #expect(squares == (0..<100).map { $0 * $0 })
        var seen = [Bool](repeating: false, count: 20)
        seen.withUnsafeMutableBufferPointer { out in
            jobs.parallelFor(5..<15, batchSize: 3) { range in for i in range { out[i] = true } }
        }
        #expect(seen.enumerated().allSatisfy { $0.element == (5..<15).contains($0.offset) })
    }

    @Test func inlineRunsBatchesInOrderOnTheCallingThread() {
        let jobs = JobSystem(threadCount: 1)
        defer { jobs.shutdown() }
        var order: [Range<Int>] = []
        jobs.parallelFor(0..<10, batchSize: 4) { range in
            order.append(range)
        }
        #expect(order == [0..<4, 4..<8, 8..<10])
        let log = JobSystemTestsCounter()
        let a = jobs.schedule("a") { log.append(1) }
        #expect(a.isComplete)  // ran before schedule returned
        let b = jobs.schedule("b", after: [a]) { log.append(2) }
        jobs.wait(b)
        #expect(log.all == [1, 2])
    }

    @Test func threadedMatchesInline() {
        // A floating-point reduction done per batch and merged in batch order gives the same
        // bits whatever the thread count.
        func sum(_ threads: Int) -> [Float] {
            let jobs = JobSystem(threadCount: threads)
            defer { jobs.shutdown() }
            let batch = 97
            let count = 20_000
            let batches = (count + batch - 1) / batch
            let partial = jobs.parallelMap(batches) { b -> Float in
                var s: Float = 0
                for i in b * batch..<min((b + 1) * batch, count) { s += sinf(Float(i) * 0.37) * 1.0001 }
                return s
            }
            return partial
        }
        let reference = sum(1)
        for threads in [2, 3, 8] {
            #expect(sum(threads) == reference)
        }
    }

    @Test func dependenciesRunFirst() {
        let jobs = JobSystem(threadCount: 4)
        defer { jobs.shutdown() }
        for _ in 0..<50 {
            let log = JobSystemTestsCounter()
            let group = JobGroup()
            let a = jobs.schedule("a", in: group) { usleep(200); log.append(1) }
            let b = jobs.schedule("b", in: group) { log.append(2) }
            let c = jobs.schedule("c", after: [a, b], in: group) { log.append(3) }
            let d = jobs.schedule("d", after: [c], in: group) { log.append(4) }
            _ = d
            jobs.wait(group)
            let all = log.all
            #expect(all.count == 4)
            #expect(Set(all.prefix(2)) == [1, 2] && all.suffix(2) == [3, 4])
        }
    }

    @Test func dependencyOnAFinishedJobDoesNotWait() {
        let jobs = JobSystem(threadCount: 3)
        defer { jobs.shutdown() }
        let a = jobs.schedule("a") {}
        jobs.wait(a)
        #expect(a.isComplete)
        let log = JobSystemTestsCounter()
        let b = jobs.schedule("b", after: [a]) { log.append(7) }
        jobs.wait(b)
        #expect(log.all == [7])
    }

    @Test func waitingFromAJobHelpsInsteadOfDeadlocking() {
        // Every worker waits on jobs scheduled behind it; only helping lets them finish.
        let jobs = JobSystem(threadCount: 3)
        defer { jobs.shutdown() }
        let log = JobSystemTestsCounter()
        let group = JobGroup()
        for outer in 0..<8 {
            jobs.schedule("outer", in: group) {
                let inner = (0..<4).map { k in jobs.schedule("inner") { log.append(outer * 10 + k) } }
                for job in inner { jobs.wait(job) }
                // Nested loops on workers work too.
                let squares = jobs.parallelMap(64, batchSize: 4) { $0 * $0 }
                if squares[63] == 63 * 63 { log.append(1000 + outer) }
            }
        }
        jobs.wait(group)
        let all = log.all
        #expect(all.count == 8 * 4 + 8)
        #expect(Set(all).count == all.count)
    }

    @Test func manyLoopsFromTheMainThreadStayCorrect() async {
        await MainActor.run {
            let jobs = JobSystem(threadCount: 4)
            defer { jobs.shutdown() }
            var total = 0
            for round in 0..<300 {
                let values = jobs.parallelMap(37, batchSize: 2) { $0 + round }
                total += values.reduce(0, +)
            }
            let expected = (0..<300).reduce(0) { $0 + (0..<37).reduce(0, +) + 37 * $1 }
            #expect(total == expected)
        }
    }

    @Test func shutdownFinishesQueuedJobsThenRunsInline() {
        let jobs = JobSystem(threadCount: 3)
        defer { jobs.shutdown() }
        let log = JobSystemTestsCounter()
        let group = JobGroup()
        for i in 0..<20 { jobs.schedule("j", in: group) { log.append(i) } }
        jobs.wait(group)
        jobs.shutdown()
        let late = jobs.schedule("late") { log.append(99) }
        #expect(late.isComplete)
        #expect(log.all.count == 21)
        let mapped = jobs.parallelMap(10, batchSize: 1) { $0 }
        #expect(mapped == Array(0..<10))
    }
}

// MARK: - The engine's parallel paths give the same results inline and threaded

/// A test component for `parallelQueryMutating`.
private struct JobSystemTestsSpin: Component, Codable, Equatable {
    static let componentName = "JobSystemTests.Spin"
    var angle: Float
    var speed: Float
}

@MainActor @Suite struct JobSystemDeterminismTests {
    static let threadCounts = [2, 4, 7]

    /// Hundreds of boxes, spheres and capsules dropped in a pile: every pose after 90 steps.
    func simulatePile(threads: Int) -> [Pose] {
        let physics = PhysicsWorld()
        physics.jobs = JobSystem(threadCount: threads)
        defer { physics.jobs.shutdown() }
        physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(20, 0.5, 20))))
        var ids: [BodyID] = []
        for i in 0..<180 {
            let x = Float(i % 10) - 4.5, z = Float((i / 10) % 6) - 2.5, y = 1 + Float(i / 60) * 1.2
            let shape: ColliderShape = i % 3 == 0 ? .box(Vec3(0.4, 0.3, 0.45)) : i % 3 == 1 ? .sphere(radius: 0.4) : .capsule(radius: 0.25, halfHeight: 0.3)
            ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(x * 0.95, y, z * 0.9 + Float(i % 7) * 0.01)), shape: shape,
                                                      angularVelocity: Vec3(Float(i % 5) * 0.1, 0, 0))))
        }
        for _ in 0..<90 { physics.step(1.0 / 60.0) }
        #expect(physics.contactCount > 150)
        return ids.map { physics.pose(of: $0)! }
    }

    @Test func physicsIsIdenticalForAnyThreadCount() {
        let reference = simulatePile(threads: 1)
        for threads in Self.threadCounts {
            #expect(simulatePile(threads: threads) == reference, "\(threads) threads")
        }
    }

    /// 40 three-bone rigs with their own clip times and blend weights: every animated transform after 30 updates.
    func animate(threads: Int) -> [Transform] {
        let world = World()
        let library = AnimationLibrary()
        func clip(_ name: String, _ phase: Float) -> AnimationClipHandle {
            let times: [Float] = [0, 0.5, 1]
            let rotation = AnimationSampler(times: times, values: [0, 0, 0, 1, 0, sinf(phase), 0, cosf(phase), 0, 0, 0, 1])
            let translation = AnimationSampler(interpolation: .cubicSpline, times: times,
                                               values: (0..<9).flatMap { k in [Float(k) * 0.1 + phase, 0.5, -0.2] })
            return library.register(AnimationClip(name: name, channels: [
                AnimationChannel(target: 0, path: .rotation, sampler: rotation),
                AnimationChannel(target: 1, path: .translation, sampler: translation),
                AnimationChannel(target: 2, path: .rotation, sampler: rotation),
            ]), key: name)
        }
        let walk = clip("walk", 0.4), run = clip("run", 1.1)
        var bones: [Entity] = []
        for i in 0..<40 {
            let rig = (0..<3).map { _ in world.spawn(Transform()) }
            bones += rig
            let machine = AnimationStateMachine(states: [
                AnimationState("Move", .blend1D(parameter: "speed", entries: [BlendSpaceEntry(clip: walk, position: 0),
                                                                              BlendSpaceEntry(clip: run, position: 1)])),
            ])
            var animator = Animator(targets: rig, restPose: Array(repeating: Transform(), count: 3), stateMachine: machine,
                                    parameters: ["speed": .float(Float(i) / 39)], speed: 0.5 + Float(i % 5) * 0.2)
            animator.play("Move", fade: 0, normalizedTime: Float(i) * 0.137)
            world.spawn(animator)
        }
        let jobs = JobSystem(threadCount: threads)
        defer { jobs.shutdown() }
        world.addAnimationSystem(library, jobs: jobs)
        for _ in 0..<30 { world.update(dt: 1.0 / 60.0) }
        return bones.map { world.get(Transform.self, for: $0)! }
    }

    @Test func animationIsIdenticalForAnyThreadCount() {
        let reference = animate(threads: 1)
        #expect(reference.contains { $0.position != .zero })
        for threads in Self.threadCounts {
            #expect(animate(threads: threads) == reference, "\(threads) threads")
        }
    }

    /// 5000 items in a grid, some transparent, some casting shadows, culled by a camera.
    func renderList(threads: Int) -> (RenderList, ShadowCasterBatches) {
        var items: [RenderItem] = []
        for i in 0..<5000 {
            let p = Vec3(Float(i % 100) - 50, Float(i % 7), Float(i / 100) - 25)
            let model = Mat4.translation(p)
            items.append(RenderItem(entity: Entity(index: UInt32(i), generation: 0), mesh: i % 3, material: i % 4,
                                    instance: MeshInstance(model: model, previousModel: model, color: Vec4(1, 1, 1, 1), params: .zero),
                                    bounds: Bounds(center: p, halfExtent: Vec3(0.5, 0.5, 0.5)), castsShadows: i % 2 == 0,
                                    transparent: i % 9 == 0, alphaTested: i % 11 == 0))
        }
        let view = Frustum(viewProjection: Mat4.perspective(fovY: 1, aspect: 1.6, near: 0.1, far: 80)
            * Mat4.lookAt(eye: Vec3(0, 10, 30), target: .zero))
        let toLight = normalize(Vec3(0.3, 1, 0.2))
        let lightFrustum = Frustum(viewProjection: Mat4.orthographic(left: -30, right: 30, bottom: -30, top: 30, near: -50, far: 50)
            * Mat4.lookAt(eye: toLight, target: .zero))
        var list = RenderList()
        list.jobs = JobSystem(threadCount: threads)
        defer { list.jobs.shutdown() }
        list.build(items: items, view: view, cameraPosition: Vec3(0, 10, 30),
                   shadows: ShadowCasterCulling(lightFrustum: lightFrustum, toLight: toLight, receiverFloor: 0, maxSweep: 50))
        var casters = ShadowCasterBatches()
        casters.jobs = list.jobs
        casters.build(items: items, tiles: [
            ShadowTileCulling(frustum: lightFrustum),
            ShadowTileCulling(frustum: view, sphere: (Vec3(5, 0, 5), 12)),
            ShadowTileCulling(frustum: lightFrustum, sweep: ShadowCasterCulling(lightFrustum: lightFrustum, toLight: toLight,
                                                                                receiverFloor: 0, maxSweep: 50), view: view),
        ])
        return (list, casters)
    }

    @Test func renderListsAreIdenticalForAnyThreadCount() {
        let (list, casters) = renderList(threads: 1)
        #expect(list.stats.culled > 0 && list.stats.opaque > 0 && list.stats.transparent > 0 && list.stats.shadowCasters > 0)
        #expect(casters.drawn > 0 && casters.culled > 0)
        for threads in Self.threadCounts {
            let (other, otherCasters) = renderList(threads: threads)
            #expect(other.instances == list.instances && other.opaque == list.opaque && other.transparent == list.transparent
                && other.shadow == list.shadow && other.stats == list.stats, "\(threads) threads")
            #expect(otherCasters.instances == casters.instances && otherCasters.batches == casters.batches
                && otherCasters.tileBatches == casters.tileBatches && otherCasters.culled == casters.culled)
        }
    }

    @Test func lightClustersAreIdenticalForAnyThreadCount() {
        let lights = (0..<400).map { i in
            PunctualLight(point: PointLight(color: Vec3(1, 0.5, 0.2), intensity: 3, range: 2 + Float(i % 5)),
                          position: Vec3(Float(i % 20) * 2 - 20, 1, Float(i / 20) * -2))
        }
        func build(_ threads: Int) -> LightClusters {
            var clusters = LightClusters()
            clusters.jobs = JobSystem(threadCount: threads)
            defer { clusters.jobs.shutdown() }
            clusters.build(lights: lights, view: Mat4.lookAt(eye: Vec3(0, 5, 10), target: Vec3(0, 0, -10)),
                           projection: Mat4.perspective(fovY: 1, aspect: 1.6, near: 0.1, far: 100))
            return clusters
        }
        let reference = build(1)
        #expect(reference.stats.references > 1000)
        for threads in Self.threadCounts {
            let other = build(threads)
            #expect(other.indices == reference.indices && other.cellFirst == reference.cellFirst
                && other.cellCount == reference.cellCount && other.stats == reference.stats)
        }
    }

    @Test func parallelQueryMatchesQueryMutating() {
        func run(_ threads: Int?) -> [JobSystemTestsSpin] {
            let world = World()
            let jobs = JobSystem(threadCount: threads ?? 1)
            defer { jobs.shutdown() }
            let entities = (0..<3000).map { i in world.spawn(JobSystemTestsSpin(angle: Float(i), speed: Float(i % 13) * 0.1)) }
            for _ in 0..<5 {
                let step: (Entity, inout JobSystemTestsSpin) -> Void = { _, spin in spin.angle = sinf(spin.angle + spin.speed) * 3 }
                if let threads {
                    world.parallelQueryMutating(JobSystemTestsSpin.self, batchSize: 100, jobs: jobs, step)
                } else {
                    world.queryMutating(JobSystemTestsSpin.self, step)
                }
            }
            return entities.map { world.get(JobSystemTestsSpin.self, for: $0)! }
        }
        let reference = run(nil)
        for threads in [1] + Self.threadCounts { #expect(run(threads) == reference) }
    }
}
