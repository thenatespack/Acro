import Foundation
import Testing
@testable import Engine

private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool { length(a - b) < eps }

/// A camera at the origin looking down -Z (view = identity) with a 16:9 projection.
private let projection = Mat4.perspective(fovY: .pi / 3, aspect: 16 / 9, near: 0.1, far: 200)

private func pointLight(at position: Vec3, range: Float) -> PunctualLight {
    PunctualLight(point: PointLight(range: range), position: position)
}

/// Deterministic pseudo-random floats in [0, 1).
private struct Random {
    var state: UInt64
    mutating func next() -> Float {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Float(state >> 40) / Float(1 << 24)
    }
}

// MARK: Gathering

@MainActor @Test func gatherPositionsLightsByTheirWorldTransform() {
    let world = World()
    let parent = world.spawn(Transform(position: Vec3(10, 0, 0)))
    let point = world.spawn(Transform(position: Vec3(0, 2, 0)), PointLight(color: Vec3(1, 0.5, 0), intensity: 4, range: 6))
    world.setParent(point, to: parent)
    _ = world.spawn(Transform.looking(from: Vec3(0, 5, 0), at: Vec3(0, 0, 0)),
                    SpotLight(intensity: 2, range: 8, innerConeAngle: 0.9, outerConeAngle: 0.4))  // inner > outer: clamped
    _ = world.spawn(Transform(), PointLight(range: 0))       // no range: skipped
    _ = world.spawn(Transform(), PointLight(intensity: 0))   // no light: skipped
    _ = world.spawn(PointLight())                            // no transform: skipped
    world.propagateTransforms()

    let lights = PunctualLight.gather(in: world)
    #expect(lights.count == 2)
    let p = lights[0], s = lights[1]
    #expect(!p.isSpot && approx(p.position, Vec3(10, 2, 0)) && approx(p.color, Vec3(4, 2, 0)) && p.range == 6)
    #expect(s.isSpot && approx(s.position, Vec3(0, 5, 0)) && approx(s.direction, Vec3(0, -1, 0)))
    #expect(abs(s.cosOuter - cosf(0.4)) < 1e-6 && s.cosInner == s.cosOuter)
}

@Test func spotBoundingSphereEnclosesTheCone() {
    for angle: Float in [0.1, 0.5, 0.78, 0.8, 1.2, 1.5, 2] {
        let light = PunctualLight(spot: SpotLight(range: 10, innerConeAngle: 0, outerConeAngle: angle), position: Vec3(1, 2, 3),
                                  direction: Vec3(0, 0, -1))
        let (center, radius) = light.boundingSphere
        #expect(radius <= 10.0001)
        let outer = min(angle, PunctualLight.maxConeAngle)
        // Apex, cap tip and rim points at several angles inside the cone.
        var points = [light.position, light.position + light.direction * 10]
        for k in 0...8 {
            let a = outer * Float(k) / 8
            for phi: Float in [0, 1.6, 3.1, 4.7] {
                let d = Vec3(sinf(a) * cosf(phi), sinf(a) * sinf(phi), -cosf(a))
                points.append(light.position + d * 10)
            }
        }
        for point in points { #expect(length(point - center) <= radius * 1.0001 + 1e-4, "angle \(angle)") }
    }
}

// MARK: Binning

@Test func lightLandsInTheClustersItReaches() {
    var clusters = LightClusters()
    let light = pointLight(at: Vec3(1, 0.5, -12), range: 3)
    // A small far light (off to the side) stretches the slices past the first one's reach.
    let far = pointLight(at: Vec3(-25, 0, -70), range: 1)
    clusters.build(lights: [far, light], view: .identity, projection: projection)
    #expect(clusters.stats.lights == 2 && clusters.lights == [light, far])  // nearest first
    #expect(clusters.stats.references > 1 && clusters.stats.droppedReferences == 0)

    // Every point the light reaches (and the camera sees) finds it in its cluster.
    var random = Random(state: 1)
    for _ in 0..<2000 {
        let d = Vec3(random.next(), random.next(), random.next()) * 2 - 1
        guard length(d) <= 1 else { continue }
        let p = light.position + d * light.range
        guard let cluster = clusters.cluster(viewPosition: p, projection: projection) else { continue }
        #expect(clusters.lights(inCluster: cluster).contains(0), "point \(p)")
    }
    // Clusters away from the light don't list it. (Slice 0 reaches from the camera to the
    // nearest light bound, so anything nearer in the light's tiles does.)
    for p in [Vec3(-12, 0, -12), Vec3(1, 0.5, -30), Vec3(-6, 0.5, -12), Vec3(8, 6, -12)] {
        let cluster = clusters.cluster(viewPosition: p, projection: projection)!
        #expect(!clusters.lights(inCluster: cluster).contains(0), "point \(p)")
    }
}

@Test func binningIsConservativeForManyLightsAndAJitteredProjection() {
    var random = Random(state: 7)
    var lights: [PunctualLight] = []
    for _ in 0..<200 {
        let p = Vec3((random.next() - 0.5) * 40, (random.next() - 0.5) * 10, -2 - random.next() * 45)
        lights.append(pointLight(at: p, range: 1 + random.next() * 4))
    }
    for k in 0..<10 {
        let p = Vec3((random.next() - 0.5) * 20, 6, -10 - random.next() * 20)
        lights.append(PunctualLight(spot: SpotLight(range: 15, outerConeAngle: 0.2 + Float(k) * 0.15), position: p,
                                    direction: Vec3(random.next() - 0.5, -1, random.next() - 0.5)))
    }
    let jittered = projection.jittered(clipOffset: Vec2(0.0007, -0.0011))
    let view = Mat4.lookAt(eye: Vec3(3, 4, 5), target: Vec3(0, 0, -20))
    var clusters = LightClusters()
    clusters.build(lights: lights, view: view, projection: jittered)
    #expect(clusters.stats.droppedReferences == 0)
    #expect(clusters.lights.count < lights.count)  // some are outside the view

    // Sample points inside each light's reach; each must find that light in its cluster.
    for (index, light) in clusters.lights.enumerated() {
        for _ in 0..<60 {
            let d = Vec3(random.next(), random.next(), random.next()) * 2 - 1
            guard length(d) <= 1 else { continue }
            let world = light.position + d * light.range
            if light.isSpot, dot(normalize(world - light.position), light.direction) < light.cosOuter { continue }
            let v = view * Vec4(world, 1)
            guard let cluster = clusters.cluster(viewPosition: Vec3(v.x, v.y, v.z), projection: jittered) else { continue }
            let clip = jittered * v
            guard abs(clip.x) <= clip.w, abs(clip.y) <= clip.w else { continue }
            #expect(clusters.lights(inCluster: cluster).contains(index))
        }
    }
}

@Test func lightsOutsideTheViewAreCulled() {
    var clusters = LightClusters()
    clusters.build(lights: [pointLight(at: Vec3(0, 0, 10), range: 3),     // behind the camera
                            pointLight(at: Vec3(60, 0, -10), range: 3),    // far to the right
                            pointLight(at: Vec3(0, -40, -10), range: 5)],  // below
                   view: .identity, projection: projection)
    #expect(clusters.isEmpty && clusters.stats.references == 0)

    // A light around the camera reaches every tile of the nearest slices.
    clusters.build(lights: [pointLight(at: Vec3(0, 0, 0.5), range: 2)], view: .identity, projection: projection)
    #expect(clusters.stats.lights == 1)
    for ty in 0..<LightClusters.tilesY {
        for tx in 0..<LightClusters.tilesX {
            #expect(clusters.lights(inCluster: LightClusters.clusterIndex(tileX: tx, tileY: ty, slice: 0)) == [0])
        }
    }
}

@Test func limitsKeepTheNearestLights() {
    var lights: [PunctualLight] = []
    for k in 0..<(LightClusters.maxLights + 100) {
        lights.append(pointLight(at: Vec3(0, 0, -5 - Float(k) * 0.05), range: 0.5))
    }
    lights.reverse()  // input order doesn't matter
    var clusters = LightClusters()
    clusters.build(lights: lights, view: .identity, projection: projection)
    #expect(clusters.stats.lights == LightClusters.maxLights)
    #expect(clusters.lights.first?.position.z == -5)
    #expect(clusters.lights.allSatisfy { $0.position.z > -5 - Float(LightClusters.maxLights) * 0.05 })
    #expect(clusters.stats.maxClusterLights <= LightClusters.maxLightsPerCluster)
    #expect(clusters.stats.references <= LightClusters.maxReferences)
    // Light 0 (nearest) survives the per-cluster cap where it was binned.
    let cluster = clusters.cluster(viewPosition: Vec3(0, 0, -5), projection: projection)!
    #expect(clusters.lights(inCluster: cluster).first == 0)
}

@Test func shaderSliceFormulaMatchesTheCPU() {
    var clusters = LightClusters()
    clusters.build(lights: [pointLight(at: Vec3(0, 0, -4), range: 2), pointLight(at: Vec3(0, 0, -60), range: 5)],
                   view: .identity, projection: projection)
    #expect(abs(clusters.near - 2) < 1e-4)
    // slice = floor(log2(depth) * scale + bias), as mesh_surface.glsl computes it from FrameUniforms.
    let bias = -log2f(clusters.near) * clusters.sliceScale
    var mismatches = 0
    for k in 0..<1000 {
        let depth = 0.05 + Float(k) * 0.08
        let gpu = Int(min(max((log2f(depth) * clusters.sliceScale + bias).rounded(.down), 0), Float(LightClusters.slices - 1)))
        if gpu != clusters.slice(depth: depth) { mismatches += 1 }
    }
    #expect(mismatches <= 2)  // only exactly on a boundary
    #expect(clusters.slice(depth: 1) == 0 && clusters.slice(depth: 65) == LightClusters.slices - 1)
}

@Test func gpuDataDecodesLikeTheShader() {
    var random = Random(state: 3)
    var lights: [PunctualLight] = []
    for _ in 0..<150 {
        lights.append(pointLight(at: Vec3((random.next() - 0.5) * 30, (random.next() - 0.5) * 10, -3 - random.next() * 30), range: 3))
    }
    lights.append(PunctualLight(spot: SpotLight(color: Vec3(1, 0, 0), intensity: 2, range: 5, innerConeAngle: 0.2, outerConeAngle: 0.4),
                                position: Vec3(0, 0, -6), direction: Vec3(0, 0, -1)))
    var clusters = LightClusters()
    clusters.build(lights: lights, view: .identity, projection: projection)
    var data = LightClusters.GPUData()
    clusters.write(to: &data)
    #expect(data.positions.count * 16 == maxUniformBufferSize && data.indices.count * 16 == maxUniformBufferSize)

    for cluster in 0..<LightClusters.clusterCount {
        let cell = data.cells[cluster >> 2][cluster & 3]
        let first = Int(cell & 0xFFFF), count = Int(cell >> 16)
        let decoded = (first..<first + count).map { i -> Int in
            let word = i / 3
            return Int((data.indices[word >> 2][word & 3] >> UInt32((i - word * 3) * 10)) & 0x3FF)
        }
        #expect(decoded == clusters.lights(inCluster: cluster))
    }
    // The spot light's cone terms: 0 at the outer angle, 1 at the inner one; a point light has none.
    let spot = clusters.lights.firstIndex { $0.isSpot }!
    let scale = data.colors[spot].w, offset = data.directions[spot].w
    #expect(abs(cosf(0.4) * scale + offset) < 1e-3 && abs(cosf(0.2) * scale + offset - 1) < 1e-3)
    #expect(abs(data.positions[spot].w - 1 / 25) < 1e-6 && approx(Vec3(data.colors[spot].x, data.colors[spot].y, data.colors[spot].z), Vec3(2, 0, 0)))
    let point = clusters.lights.firstIndex { !$0.isSpot }!
    #expect(data.colors[point].w == 0 && data.directions[point].w == 1)
}

// MARK: Serialization

@MainActor @Test func pointAndSpotLightsRoundTripThroughSceneFiles() throws {
    let world = World()
    let point = world.spawn(Transform(position: Vec3(1, 2, 3)), PointLight(color: Vec3(1, 0.2, 0.1), intensity: 7, range: 4.5))
    let spot = world.spawn(Transform.looking(from: Vec3(0, 5, 0), at: .zero),
                           SpotLight(color: Vec3(0.9, 0.9, 1), intensity: 30, range: 12, innerConeAngle: 0.25, outerConeAngle: 0.4))
    let data = try world.save()
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"PointLight\"") && text.contains("\"SpotLight\"") && text.contains("\"outerConeAngle\""))

    let loaded = World()
    try loaded.load(data)
    #expect(try loaded.save() == data)
    var points: [PointLight] = [], spots: [SpotLight] = []
    loaded.query(PointLight.self) { _, light in points.append(light) }
    loaded.query(SpotLight.self) { _, light in spots.append(light) }
    #expect(points == [world.get(PointLight.self, for: point)!])
    #expect(spots == [world.get(SpotLight.self, for: spot)!])

    // Reflection sees the fields (for the inspector), with a color picker for the color.
    let fields = try #require(world.fields(of: "SpotLight", for: spot))
    #expect(Set(fields.map(\.name)) == ["color", "intensity", "range", "innerConeAngle", "outerConeAngle", "castsShadows"])
    #expect(fields.first { $0.name == "color" }?.hints.color == true)
    try world.setField("range", of: "PointLight", for: point, to: .float(9))
    #expect(world.get(PointLight.self, for: point)?.range == 9)
}
