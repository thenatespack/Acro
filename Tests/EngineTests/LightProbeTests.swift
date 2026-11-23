import Foundation
import Testing
@testable import Engine
@testable import EngineRendering
@testable import EngineGraphics

/// Light probes: the components, the math the shaders share, the buffer layout, the cache and a
/// GPU bake on every backend.
@MainActor @Suite struct LightProbeTests {
    // MARK: - Components

    @Test func componentsDecodeMissingKeysAsDefaults() throws {
        let probe = try JSONDecoder().decode(ReflectionProbe.self, from: Data("{}".utf8))
        #expect(probe == ReflectionProbe())
        let volume = try JSONDecoder().decode(IrradianceVolume.self, from: Data(#"{"countX": 3, "bounces": 1}"#.utf8))
        #expect(volume.countX == 3 && volume.bounces == 1 && volume.countY == IrradianceVolume().countY && volume.isEnabled)
        let round = try JSONDecoder().decode(ReflectionProbe.self, from: JSONEncoder().encode(
            ReflectionProbe(size: Vec3(4, 3, 2), blendDistance: 0.25, boxProjection: false, intensity: 2, priority: 3)))
        #expect(round.size == Vec3(4, 3, 2) && round.priority == 3 && !round.boxProjection)
    }

    @Test func componentsAreRegisteredForScenes() {
        GamePlayer.registerEngineComponents()
        #expect(ComponentRegistry.type(named: ReflectionProbe.componentName) != nil)
        #expect(ComponentRegistry.type(named: IrradianceVolume.componentName) != nil)
    }

    @Test func bakeKeysFollowWhatShapesTheBake() {
        let frame = LightProbeFrame(position: Vec3(1, 2, 3), rotation: Quat(angle: 0.3, axis: Vec3(0, 1, 0)))
        let probe = ReflectionProbe()
        let key = probe.bakeKey(frame: frame)
        // Float noise doesn't change it; shading-only settings don't either.
        let nudged = LightProbeFrame(position: Vec3(1, 2, 3.000001), rotation: frame.rotation)
        #expect(probe.bakeKey(frame: nudged) == key)
        var brighter = probe
        brighter.intensity = 3
        brighter.blendDistance = 2
        #expect(brighter.bakeKey(frame: frame) == key)
        #expect(probe.bakeKey(frame: LightProbeFrame(position: Vec3(1, 2, 4), rotation: frame.rotation)) != key)
        var moved = probe
        moved.captureOffset = Vec3(0, 1, 0)
        #expect(moved.bakeKey(frame: frame) != key)
        let volume = IrradianceVolume()
        var denser = volume
        denser.countX = 8
        #expect(volume.bakeKey(frame: frame) != denser.bakeKey(frame: frame))
        #expect(volume.bakeKey(frame: frame).hasPrefix("irradiance-") && key.hasPrefix("reflection-"))
    }

    @Test func framesDropScaleAndRoundTripPoints() {
        let rotation = Quat(angle: 0.7, axis: normalize(Vec3(1, 2, 0.5)))
        let world = Mat4(translation: Vec3(3, -1, 2), rotation: rotation, scale: Vec3(2, 5, 0.5))
        let frame = LightProbeFrame(world: world)
        #expect(length(frame.position - Vec3(3, -1, 2)) < 1e-5)
        let p = Vec3(0.3, -2, 4)
        #expect(length(frame.toLocal(frame.toWorld(p)) - p) < 1e-4)
        let viaMatrix = frame.inverse * Vec4(frame.toWorld(p), 1)
        #expect(length(Vec3(viaMatrix.x, viaMatrix.y, viaMatrix.z) - p) < 1e-4)
    }

    // MARK: - Math

    @Test func facesCoverEveryDirectionBothWays() {
        for d in LightProbeMath.sphereDirections(200) {
            let (face, uv) = LightProbeMath.face(of: d)
            #expect(uv.x >= -1e-5 && uv.x <= 1 + 1e-5 && uv.y >= -1e-5 && uv.y <= 1 + 1e-5)
            #expect(length(LightProbeMath.direction(face: face, uv: uv) - d) < 1e-4)
        }
        // A face's camera sees a direction where `face(of:)` says: NDC (x, y) = (2u - 1, 1 - 2v).
        let rotation = Quat(angle: 0.4, axis: Vec3(0, 1, 0))
        let projection = LightProbeMath.faceProjection(near: 0.1, far: 10)
        for d in [normalize(Vec3(0.9, 0.3, -0.2)), normalize(Vec3(-0.1, 0.95, 0.2)), normalize(Vec3(0.2, -0.3, -0.9))] {
            let (face, uv) = LightProbeMath.face(of: d)
            let clip = projection * LightProbeMath.faceView(face: face, eye: .zero, rotation: rotation) * Vec4(rotation * d, 1)
            #expect(abs(clip.x / clip.w - (uv.x * 2 - 1)) < 1e-4 && abs(clip.y / clip.w - (1 - uv.y * 2)) < 1e-4)
        }
    }

    @Test func influenceFadesOverTheBlendDistance() {
        let half = Vec3(2, 1, 2)
        #expect(LightProbeMath.influence(local: .zero, half: half, blend: 0.5) == 1)
        #expect(LightProbeMath.influence(local: Vec3(2, 0, 0), half: half, blend: 0.5) == 0)
        #expect(LightProbeMath.influence(local: Vec3(3, 0, 0), half: half, blend: 0.5) == 0)
        let mid = LightProbeMath.influence(local: Vec3(1.75, 0, 0), half: half, blend: 0.5)
        #expect(abs(mid - 0.5) < 1e-5)
        #expect(LightProbeMath.influence(local: Vec3(1.99, 0, 0), half: half, blend: 0) == 1)
    }

    @Test func boxProjectionAimsAtWhereTheRayLeavesTheBox() {
        let half = Vec3(5, 2, 5)
        // From the capture point it changes nothing.
        let r = normalize(Vec3(1, 0.2, -0.3))
        #expect(length(LightProbeMath.boxProjected(local: .zero, ray: r, half: half, capture: .zero) - r) < 1e-5)
        // From near the +X wall, looking at it: straight ahead of the capture point, toward that spot on the wall.
        let d = LightProbeMath.boxProjected(local: Vec3(4, 0, 3), ray: Vec3(1, 0, 0), half: half, capture: .zero)
        #expect(length(d - normalize(Vec3(5, 0, 3))) < 1e-5)
        // The capture point offset: from it to the hit point.
        let e = LightProbeMath.boxProjected(local: Vec3(0, 0, 0), ray: Vec3(0, 1, 0), half: half, capture: Vec3(0, -1, 0))
        #expect(length(e - Vec3(0, 1, 0)) < 1e-5)
    }

    @Test func volumeProbesSitAtCellCenters() {
        let volume = IrradianceVolume(size: Vec3(4, 2, 6), countX: 2, countY: 1, countZ: 3)
        #expect(volume.probeCount == 6)
        #expect(length(volume.localPosition(of: 0) - Vec3(-1, 0, -2)) < 1e-5)
        #expect(length(volume.localPosition(of: 5) - Vec3(1, 0, 2)) < 1e-5)
        #expect(IrradianceVolume(countX: 0).probeCount == 0)
        #expect(IrradianceVolume(countX: 1000).counts.x == IrradianceVolume.maxCount)
    }

    /// The CPU mirror of the shader's interpolation: a uniform volume gives its light everywhere,
    /// a probe inside geometry is skipped, and a gradient is interpolated in between.
    @Test func irradianceInterpolatesBetweenValidProbes() {
        let volume = IrradianceVolume(size: Vec3(2, 2, 2), countX: 2, countY: 1, countZ: 1, normalBias: 0, viewBias: 0)
        let frame = LightProbeFrame(position: .zero, rotation: .identity)
        func sh(_ dc: Vec3, valid: Bool) -> [Float] {
            // Only the constant band: irradiance / pi = dc * 0.282095 for every normal.
            var c = [Float](repeating: 0, count: 36)
            c[0] = dc.x; c[1] = dc.y; c[2] = dc.z; c[3] = valid ? 1 : 0
            return c
        }
        let k: Float = 0.282095
        let uniform = IrradianceVolumeBake(key: "u", counts: SIMD3(2, 1, 1), coefficients: sh(Vec3(1, 1, 1), valid: true) + sh(Vec3(1, 1, 1), valid: true))
        let at = uniform.irradiance(at: Vec3(0.2, 0, 0), normal: Vec3(0, 1, 0), volume: volume, frame: frame)!
        #expect(abs(at.x - k) < 1e-4)
        #expect(uniform.irradiance(at: Vec3(5, 0, 0), normal: Vec3(0, 1, 0), volume: volume, frame: frame) == nil)

        let ramp = IrradianceVolumeBake(key: "r", counts: SIMD3(2, 1, 1), coefficients: sh(Vec3(0, 0, 0), valid: true) + sh(Vec3(2, 2, 2), valid: true))
        let middle = ramp.irradiance(at: Vec3(0, 0, 0), normal: Vec3(0, 1, 0), volume: volume, frame: frame)!
        #expect(abs(middle.x - k) < 1e-4)
        let skipped = IrradianceVolumeBake(key: "s", counts: SIMD3(2, 1, 1), coefficients: sh(Vec3(0, 0, 0), valid: false) + sh(Vec3(2, 2, 2), valid: true))
        let lit = skipped.irradiance(at: Vec3(-0.25, 0, 0), normal: Vec3(0, 1, 0), volume: volume, frame: frame)!
        #expect(abs(lit.x - 2 * k) < 1e-4)
    }

    @Test func raysFindProbesInsideGeometry() {
        let tracer = ProbeRayTracer(geometry: .cube(), models: [Mat4(translation: Vec3(0, 0, 0), rotation: .identity, scale: Vec3(2, 2, 2))])
        #expect(tracer.isInsideGeometry(.zero))
        #expect(!tracer.isInsideGeometry(Vec3(3, 0, 0)))
        // A room of six walls: inside it, every ray sees a wall's front face.
        let walls = [Vec3(1, 0, 0), Vec3(-1, 0, 0), Vec3(0, 1, 0), Vec3(0, -1, 0), Vec3(0, 0, 1), Vec3(0, 0, -1)].map { n in
            Mat4(translation: n * 2.1, rotation: .identity, scale: Vec3(repeating: 4.4) - simdAbs(n) * 4.2)
        }
        let room = ProbeRayTracer(geometry: .cube(), models: walls)
        #expect(!room.isInsideGeometry(.zero))
        #expect(room.isInsideGeometry(Vec3(2.1, 0, 0)))
    }

    // MARK: - Buffer and cache

    @Test func bufferLayoutPlacesRecordsCoefficientsAndImages() {
        let frame = LightProbeFrame(position: Vec3(1, 0, 0), rotation: .identity)
        let volume = IrradianceVolume(countX: 2, countY: 1, countZ: 1)
        let layout = ProbeBufferLayout(reflections: [.init(key: "a", probe: ReflectionProbe(), frame: frame)],
                                       volumes: [.init(key: "b", volume: volume, frame: frame)])
        #expect(layout.shFirst == [16])
        #expect(layout.imageFirstWord == [(16 + 8) * 4])
        #expect(layout.wordCount == (16 + 8) * 4 + ReflectionProbeImage.wordCount)
        #expect(layout.uniform == Vec4(1, 1, 0, 0))
        let image = ReflectionProbeBake(key: "a", words: (0..<ReflectionProbeImage.wordCount).map { UInt32($0) })
        let words = layout.words(reflectionBakes: [image], volumeBakes: [nil], validity: [[true, false]])
        // Row 0 of the reflection record maps world to local: x - 1.
        #expect(Float(bitPattern: words[0]) == 1 && Float(bitPattern: words[3]) == -1)
        #expect(words[6 * 4] == UInt32(layout.imageFirstWord[0] / 2))
        #expect(words[(8 + 6) * 4] == 16)
        #expect(words[layout.imageFirstWord[0] + 7] == 7)
        // No bake: black, the first probe valid, the second off.
        #expect(ProbeBufferLayout.unpackSH(words[layout.shWord(volume: 0, probe: 0)..<layout.shWord(volume: 0, probe: 0) + 16])[3] == 1)
        #expect(ProbeBufferLayout.unpackSH(words[layout.shWord(volume: 0, probe: 1)..<layout.shWord(volume: 0, probe: 1) + 16])[3] == 0)
        // Bakes pack into halves and back exactly when they hold half values.
        let sh: [Float] = (0..<36).map { $0 % 4 == 3 ? ($0 == 3 ? 1 : 0) : Float($0) * 0.25 }
        #expect(ProbeBufferLayout.unpackSH(ProbeBufferLayout.packSH(sh[...])[...]) == sh)
    }

    @Test func cacheRoundTripsBakes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LightProbeTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = LightProbeBakeCache(directory: directory)
        let reflection = ReflectionProbeBake(key: "reflection-1", words: (0..<ReflectionProbeImage.wordCount).map { UInt32($0 &* 2654435761 & 0xFFFF_FFFF) })
        let volume = IrradianceVolumeBake(key: "irradiance-1", counts: SIMD3(1, 2, 1), coefficients: (0..<72).map { Float($0) * 0.5 })
        #expect(cache.store(reflection) == "reflection-1.lightprobe")
        #expect(cache.store(volume) != nil)
        #expect(cache.loadReflection(key: "reflection-1") == reflection)
        #expect(cache.loadVolume(key: "irradiance-1") == volume)
        #expect(cache.loadVolume(key: "reflection-1") == nil)
        #expect(cache.loadReflection(key: "missing") == nil)
        #expect(Set(LightProbeBakeCache.files(in: directory).keys) == ["reflection-1", "irradiance-1"])
        let reflectionTexel = reflection.texel(level: 0, x: 0, y: 0)
        #expect(reflectionTexel.x == 0)
    }

    // MARK: - GPU

    /// Bakes a reflection probe and a 2 x 1 x 1 volume (one probe buried in a box) under a
    /// procedural sky on every backend: the report, the probe inside geometry, sky light from
    /// above brighter than from below, a blue zenith in the reflection, and the same bits on
    /// Metal and Vulkan. The bakes are cached and found again by a new renderer.
    @Test func bakesProbesOnTheGPU() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LightProbeTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        var results: [(reflection: [UInt32], volume: [Float])] = []
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .medium)
            renderer.bakesProbesAutomatically = false
            renderer.probeBakeCache = LightProbeBakeCache(directory: directory.appendingPathComponent("\(device.backend)"))
            let world = World()
            _ = world.spawn(SceneEnvironment(sky: .procedural))
            _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.3, 1, 0.2)))), DirectionalLight(intensity: 2))
            _ = world.spawn(Name("LightProbeTests box"), Transform(position: Vec3(2, 1, 0), scale: Vec3(repeating: 1.5)),
                            MeshRenderer(mesh: .cube))
            _ = world.spawn(Name("LightProbeTests volume"), Transform(position: Vec3(1, 1, 0)),
                            IrradianceVolume(size: Vec3(4, 1, 1), countX: 2, countY: 1, countZ: 1, bounces: 1))
            let probe = world.spawn(Name("LightProbeTests reflection"), Transform(position: Vec3(-2, 1, 0)), ReflectionProbe())
            world.propagateTransforms()
            var report: LightProbeBakeReport?
            renderer.bakeProbes(in: world) { report = $0 }
            for _ in 0..<3 where report == nil {
                try frames.run { renderer.beginViews(world: world, frame: $0) }
            }
            guard let report else {
                Issue.record("\(device.backend): the bake never finished")
                return
            }
            #expect(report.reflectionProbes == 1 && report.irradianceVolumes == 1 && report.irradianceProbes == 2, "\(device.backend)")
            #expect(report.probesInsideGeometry == 1, "\(device.backend)")
            #expect(report.warnings.contains { $0.contains("1 of 2 probes are inside geometry") }, "\(report.warnings)")
            #expect(report.cacheFiles.count == 2, "\(device.backend)")

            let volume = renderer.probes.volumeBakes.values.first!
            #expect(volume.isValid(0) && !volume.isValid(1))
            let up = EnvironmentMath.irradiance(volume.sh(of: 0), normal: Vec3(0, 1, 0))
            let down = EnvironmentMath.irradiance(volume.sh(of: 0), normal: Vec3(0, -1, 0))
            #expect(up.z > down.z && up.z > 0.05, "up \(up), down \(down)")
            let reflection = renderer.probes.reflectionBakes.values.first!
            let zenith = reflection.texel(level: 0, x: 128, y: 0)
            #expect(zenith.z > zenith.x && zenith.z > 0.05, "zenith \(zenith)")
            #expect(renderer.probeSummary.bakedReflectionProbes == 1 || renderer.probes.pending != nil)
            results.append((reflection.words, volume.coefficients))

            // A new renderer finds the bakes in the cache instead of baking.
            let again = try SceneRenderer(device: device, quality: .medium)
            again.bakesProbesAutomatically = false
            again.probeBakeCache = renderer.probeBakeCache
            try frames.run { again.beginViews(world: world, frame: $0) }
            #expect(again.probeSummary.bakedReflectionProbes == 1 && again.probeSummary.bakedIrradianceVolumes == 1)
            // A moved probe keeps its bake until baked again.
            world.add(Transform(position: Vec3(-2.5, 1, 0)), to: probe)
            world.propagateTransforms()
            try frames.run { again.beginViews(world: world, frame: $0) }
            #expect(again.probeSummary.bakedReflectionProbes == 1)
        }
        if results.count == 2 {
            #expect(results[0].reflection == results[1].reflection, "Metal and Vulkan reflection probes differ")
            #expect(results[0].volume == results[1].volume, "Metal and Vulkan irradiance probes differ")
        }
    }
}
