import Foundation
import Testing
@testable import Engine

private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool { length(a - b) < eps }
private func approx(_ a: Mat4, _ b: Mat4, _ eps: Float = 1e-4) -> Bool {
    let columns: [(Vec4, Vec4)] = [(a.c0, b.c0), (a.c1, b.c1), (a.c2, b.c2), (a.c3, b.c3)]
    return columns.allSatisfy { (x: Vec4, y: Vec4) -> Bool in (x - y).replacing(with: -(x - y), where: x - y .< 0).max() < eps }
}

private let unitBox = Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5))

/// A camera at `eye` looking at the origin, with a standard projection.
private func viewProjection(eye: Vec3 = Vec3(0, 5, 20)) -> Mat4 {
    Mat4.perspective(fovY: .pi / 3, aspect: 16 / 9, near: 0.1, far: 200) * Mat4.lookAt(eye: eye, target: .zero)
}

private func item(_ index: UInt32, mesh: Int = 0, material: Int = 0, at position: Vec3, transparent: Bool = false,
                  castsShadows: Bool = true) -> RenderItem {
    let model = Mat4.translation(position)
    return RenderItem(
        entity: Entity(index: index, generation: 0), mesh: mesh, material: material,
        instance: MeshInstance(model: model, previousModel: model, color: Vec4(1, 1, 1, Float(index)), params: Vec4(1, 0, 0, 0)),
        bounds: unitBox.transformed(by: model), castsShadows: castsShadows, transparent: transparent)
}

// MARK: Handles and registry

@Test func handlesEncodeAsTheirKey() throws {
    let renderer = MeshRenderer(mesh: .sphere, material: MaterialHandle("glass"), opacity: 0.5)
    let data = try JSONEncoder().encode(renderer)
    let json = String(decoding: data, as: UTF8.self)
    #expect(json.contains("\"mesh\":\"sphere\"") && json.contains("\"material\":\"glass\""))
    #expect(try JSONDecoder().decode(MeshRenderer.self, from: data) == renderer)
    let camera = Camera(fovY: 1, near: 0.2, far: 90, reversedZ: true)
    #expect(try JSONDecoder().decode(Camera.self, from: JSONEncoder().encode(camera)) == camera)
    let light = DirectionalLight(direction: Vec3(0, -1, 0), shadowCenter: nil)
    #expect(try JSONDecoder().decode(DirectionalLight.self, from: JSONEncoder().encode(light)) == light)
}

@Test func registryAssignsStableDenseIDs() {
    var registry = AssetRegistry<Int>()
    #expect(registry.register(10, key: "cube") == 0)
    #expect(registry.register(20, key: "sphere") == 1)
    #expect(registry.id(of: "sphere") == 1)
    #expect(registry.id(of: "sphere") == 1)  // cached path
    #expect(registry.id(of: "cube") == 0)
    #expect(registry.id(of: "missing") == nil)
    // Re-registering replaces the value and keeps the id.
    #expect(registry.register(30, key: "cube") == 0)
    #expect(registry[0] == 30 && registry["cube"] == 30 && registry.count == 2)
    #expect(registry.keys == ["cube", "sphere"])
}

// MARK: Motion history

@Test func motionHistoryReturnsLastFramesMatrix() {
    var history = MotionHistory()
    let e = Entity(index: 3, generation: 0)
    let a = Mat4.translation(Vec3(1, 0, 0)), b = Mat4.translation(Vec3(2, 0, 0))
    history.beginFrame()
    #expect(history.previousMatrix(for: e, current: a) == a)  // first sighting: no motion
    history.beginFrame()
    #expect(history.previousMatrix(for: e, current: b) == a)
    history.beginFrame()
    #expect(history.previousMatrix(for: e, current: b) == b)
}

@Test func motionHistoryIgnoresStaleAndReusedEntries() {
    var history = MotionHistory()
    let e = Entity(index: 0, generation: 0), reused = Entity(index: 0, generation: 1)
    let a = Mat4.translation(Vec3(1, 0, 0)), b = Mat4.translation(Vec3(5, 0, 0))
    history.beginFrame()
    _ = history.previousMatrix(for: e, current: a)
    history.beginFrame()
    // The slot was reused by a new entity: it must not inherit the old one's matrix.
    #expect(history.previousMatrix(for: reused, current: b) == b)

    // Skipped a frame: the entry is too old.
    history.beginFrame()
    history.beginFrame()
    #expect(history.previousMatrix(for: reused, current: a) == a)

    // reset() forgets everything.
    history.beginFrame()
    _ = history.previousMatrix(for: reused, current: b)
    history.reset()
    history.beginFrame()
    #expect(history.previousMatrix(for: reused, current: a) == a)
}

// MARK: Gathering from a world

@MainActor @Test func gatherResolvesHandlesAndTracksMotion() {
    let world = World()
    var prep = RenderPrep()
    prep.meshes.register(unitBox, key: "cube")
    prep.materials.register(false, key: "default")
    prep.materials.register(true, key: "glass")

    let parent = world.spawn(Transform(position: Vec3(10, 0, 0)))
    let child = world.spawn(Transform(position: Vec3(1, 0, 0)), MeshRenderer(mesh: .cube))
    world.setParent(child, to: parent)
    let glass = world.spawn(Transform(), MeshRenderer(mesh: .cube, material: MaterialHandle("glass")))
    let faded = world.spawn(Transform(), MeshRenderer(mesh: .cube, opacity: 0.5))
    _ = world.spawn(Transform(), MeshRenderer(mesh: .cube, isVisible: false))
    _ = world.spawn(Transform(), MeshRenderer(mesh: MeshHandle("teapot")))
    world.propagateTransforms()

    prep.gather(world: world)
    #expect(prep.items.count == 3)
    #expect(prep.missingKeys == ["teapot"])
    let byEntity = Dictionary(uniqueKeysWithValues: prep.items.map { ($0.entity, $0) })
    #expect(approx(byEntity[child]!.bounds.center, Vec3(11, 0, 0)))
    #expect(!byEntity[child]!.transparent && byEntity[glass]!.transparent && byEntity[faded]!.transparent)
    #expect(byEntity[child]!.instance.previousModel == byEntity[child]!.instance.model)

    // Moving the parent moves the child; its previous matrix is last frame's.
    world.modify(Transform.self, for: parent) { $0.position.x = 20 }
    world.propagateTransforms()
    prep.gather(world: world)
    let moved = prep.items.first { $0.entity == child }!
    #expect(approx(moved.bounds.center, Vec3(21, 0, 0)))
    #expect(approx(moved.instance.previousModel, Mat4.translation(Vec3(11, 0, 0))))
}

@MainActor @Test func findsActiveCameraLightAndEnvironment() {
    let world = World()
    #expect(RenderPrep.findCamera(in: world) == nil)
    let inactive = world.spawn(Transform(), Camera(isActive: false))
    let main = world.spawn(Transform.looking(from: Vec3(0, 0, 10), at: .zero), Camera(far: 50))
    _ = world.spawn(Transform(), Camera(far: 70))
    world.propagateTransforms()
    #expect(RenderPrep.findCamera(in: world)?.entity == main)
    #expect(RenderPrep.findCamera(in: world, preferred: inactive)?.entity == inactive)
    #expect(RenderPrep.findEnvironment(in: world) == SceneEnvironment())

    _ = world.spawn(Transform(rotation: .lookRotation(forward: Vec3(0, -1, 0.001))), DirectionalLight())
    world.propagateTransforms()
    let (light, matrix) = RenderPrep.findLight(in: world)!
    #expect(approx(light.travelDirection(world: matrix), normalize(Vec3(0, -1, 0.001))))
    #expect(approx(DirectionalLight(direction: Vec3(0, -2, 0)).travelDirection(world: matrix), Vec3(0, -1, 0)))
}

@Test func cameraViewMatchesLookAt() {
    let eye = Vec3(3, 4, 12), target = Vec3(-1, 1, 0)
    let transform = Transform.looking(from: eye, at: target)
    #expect(approx(Camera.viewMatrix(world: transform.matrix), Mat4.lookAt(eye: eye, target: target)))
    // Scale on the camera entity doesn't affect the view.
    var scaled = transform
    scaled.scale = Vec3(2, 3, 4)
    #expect(approx(Camera.viewMatrix(world: scaled.matrix), Mat4.lookAt(eye: eye, target: target)))
}

// MARK: Culling, batching, sorting

@Test func opaqueItemsBatchByMeshAndMaterialInFirstSeenOrder() {
    var list = RenderList()
    let items = [
        item(0, mesh: 1, material: 0, at: Vec3(0, 0, 0)),
        item(1, mesh: 0, material: 0, at: Vec3(1, 0, 0)),
        item(2, mesh: 1, material: 0, at: Vec3(2, 0, 0)),
        item(3, mesh: 1, material: 2, at: Vec3(3, 0, 0)),
        item(4, mesh: 0, material: 0, at: Vec3(-1, 0, 0)),
    ]
    list.build(items: items, view: Frustum(viewProjection: viewProjection()), cameraPosition: Vec3(0, 5, 20), shadows: nil)
    #expect(list.opaque == [
        RenderBatch(mesh: 1, material: 0, first: 0, count: 2),
        RenderBatch(mesh: 0, material: 0, first: 2, count: 2),
        RenderBatch(mesh: 1, material: 2, first: 4, count: 1),
    ])
    // Instances keep their gather order within a batch (color.w carries the entity index here).
    #expect(list.instances.map { Int($0.color.w) } == [0, 2, 1, 4, 3])
    #expect(list.transparent.isEmpty && list.shadow.isEmpty)
    #expect(list.stats.opaque == 5 && list.stats.drawCalls == 3)
}

@Test func itemsOutsideTheFrustumAreCulled() {
    var list = RenderList()
    let items = [item(0, at: .zero), item(1, at: Vec3(0, 0, 40)) /* behind the camera */, item(2, at: Vec3(500, 0, 0))]
    list.build(items: items, view: Frustum(viewProjection: viewProjection()), cameraPosition: Vec3(0, 5, 20), shadows: nil)
    #expect(list.stats.culled == 2 && list.stats.opaque == 1)
    #expect(list.instances.count == 1 && list.instances[0].color.w == 0)
}

@Test func transparentItemsSortBackToFrontAndMergeRuns() {
    var list = RenderList()
    let items = [
        item(0, mesh: 0, at: Vec3(0, 0, 10), transparent: true),   // nearest
        item(1, mesh: 0, at: Vec3(0, 0, -10), transparent: true),  // farthest
        item(2, mesh: 0, at: Vec3(0, 0, -5), transparent: true),
        item(3, mesh: 1, at: Vec3(0, 0, 0), transparent: true),
        item(4, mesh: 0, at: Vec3(0, 0, 0)),                        // opaque
    ]
    list.build(items: items, view: Frustum(viewProjection: viewProjection()), cameraPosition: Vec3(0, 5, 20), shadows: nil)
    #expect(list.instances.map { Int($0.color.w) } == [4, 1, 2, 3, 0])
    #expect(list.transparent == [
        RenderBatch(mesh: 0, material: 0, first: 1, count: 2),
        RenderBatch(mesh: 1, material: 0, first: 3, count: 1),
        RenderBatch(mesh: 0, material: 0, first: 4, count: 1),
    ])
}

@Test func shadowCastersOutsideTheViewAreKeptOnlyIfTheirShadowCanBeSeen() {
    // Light straight from above with a frustum covering everything.
    let toLight = Vec3(0, 1, 0)
    let light = SceneRenderer.lightViewProjection(toLight: toLight, center: .zero, extent: 100, distance: 100, mapSize: 2048, snap: false)
    let culling = ShadowCasterCulling(lightFrustum: Frustum(viewProjection: light), toLight: toLight, receiverFloor: -0.5, maxSweep: 300)
    // Looking straight down at the origin from 30 units: sees roughly ±17 units on the ground.
    let view = Frustum(viewProjection: Mat4.perspective(fovY: .pi / 3, aspect: 1, near: 0.1, far: 100)
        * Mat4.lookAt(eye: Vec3(0, 30, 0), target: .zero, up: Vec3(0, 0, -1)))
    // Above the camera (out of view) but its shadow falls in view.
    #expect(culling.castsVisibleShadow(Bounds(center: Vec3(0, 40, 0), halfExtent: Vec3(repeating: 1)), view: view))
    // Far to the side: neither it nor its shadow is visible.
    #expect(!culling.castsVisibleShadow(Bounds(center: Vec3(80, 5, 0), halfExtent: Vec3(repeating: 1)), view: view))
    // Outside the light's frustum entirely.
    #expect(!culling.castsVisibleShadow(Bounds(center: Vec3(500, 0, 0), halfExtent: Vec3(repeating: 1)), view: view))

    var list = RenderList()
    let items = [
        item(0, mesh: 0, at: Vec3(0, 40, 0)), item(1, mesh: 0, at: Vec3(80, 5, 0)),
        item(2, mesh: 1, at: .zero), item(3, mesh: 0, at: Vec3(1, 0, 0), castsShadows: false),
    ]
    list.build(items: items, view: view, cameraPosition: Vec3(0, 30, 0), shadows: culling)
    #expect(list.shadow.map(\.mesh) == [0, 1] && list.shadow.map(\.count) == [1, 1])
    #expect(list.stats.shadowCasters == 2 && list.stats.culledShadowCasters == 1)
    // Shadow instances come after the opaque ones.
    #expect(list.shadow[0].first == list.stats.opaque)
}

@Test func followingShadowFrustumSnapsToTexels() {
    let toLight = normalize(Vec3(0.5, 0.75, 0.35))
    func light(_ center: Vec3, snap: Bool) -> Mat4 {
        SceneRenderer.lightViewProjection(toLight: toLight, center: center, extent: 30, distance: 60, mapSize: 2048, snap: snap)
    }
    // 20 sub-texel camera moves (texel = 60 / 2048 ≈ 0.029) cross at most one texel boundary per axis.
    let moves = (0..<20).map { Vec3(1 + Float($0) * 0.001, 0, 1) }
    #expect(Set(moves.map { "\(light($0, snap: true))" }).count <= 2)
    #expect(Set(moves.map { "\(light($0, snap: false))" }).count == 20)
    let a = light(Vec3(1, 0, 1), snap: true)
    // The center lands mid-depth inside the light's clip volume.
    let c = a * Vec4(1, 0, 1, 1)
    #expect(abs(c.x) < 0.01 && abs(c.y) < 0.01 && c.z > 0 && c.z < 1)
}

// MARK: Geometry

@Test func primitivesWindCounterClockwiseOutward() {
    for (name, geometry) in [("cube", MeshGeometry.cube()), ("plane", .plane(segments: 3)), ("sphere", .sphere())] {
        var bad = 0
        for t in stride(from: 0, to: geometry.indices.count, by: 3) {
            let v = (0..<3).map { geometry.vertices[Int(geometry.indices[t + $0])] }
            let faceNormal = cross(v[1].position - v[0].position, v[2].position - v[0].position)
            if dot(faceNormal, v[0].normal + v[1].normal + v[2].normal) <= 0 { bad += 1 }
        }
        #expect(bad == 0, "\(name): \(bad) triangles wound clockwise")
    }
    #expect(MeshGeometry.cube().bounds == Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5)))
    #expect(approx(MeshGeometry.sphere().bounds.halfExtent, Vec3(repeating: 0.5)))
}

@Test func boundsTransformCoversRotatedBox() {
    let m = Mat4(translation: Vec3(1, 2, 3), rotation: Quat(angle: .pi / 4, axis: Vec3(0, 1, 0)), scale: Vec3(2, 1, 1))
    let b = unitBox.transformed(by: m)
    #expect(approx(b.center, Vec3(1, 2, 3)))
    // Every transformed corner is inside the box.
    for corner in [Vec3(-0.5, -0.5, -0.5), Vec3(0.5, 0.5, 0.5), Vec3(0.5, -0.5, 0.5), Vec3(-0.5, 0.5, 0.5)] {
        let p = m * Vec4(corner, 1)
        let offset = Vec3(p.x, p.y, p.z) - b.center
        let d = Vec3(abs(offset.x), abs(offset.y), abs(offset.z)) - b.halfExtent
        #expect(d.max() < 1e-4)
    }
}

// MARK: Performance

@MainActor @Test func renderPrepOf10kEntities() {
    let world = World()
    var prep = RenderPrep()
    prep.meshes.register(unitBox, key: "cube")
    prep.meshes.register(Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5)), key: "sphere")
    prep.materials.register(false, key: "default")
    prep.materials.register(false, key: "b")
    for i in 0..<10_000 {
        let p = Vec3(Float(i % 100) - 50, 0, Float(i / 100) - 50)
        _ = world.spawn(Transform(position: p),
                        MeshRenderer(mesh: i % 2 == 0 ? .cube : .sphere, material: i % 3 == 0 ? .default : MaterialHandle("b"),
                                     opacity: i % 10 == 0 ? 0.5 : 1))
    }
    world.propagateTransforms()
    var list = RenderList()
    let view = Frustum(viewProjection: viewProjection(eye: Vec3(0, 30, 60)))
    let light = SceneRenderer.lightViewProjection(toLight: normalize(Vec3(0.5, 0.75, 0.35)), center: .zero, extent: 60,
                                                  distance: 60, mapSize: 2048, snap: false)
    let culling = ShadowCasterCulling(lightFrustum: Frustum(viewProjection: light), toLight: normalize(Vec3(0.5, 0.75, 0.35)),
                                      receiverFloor: -0.5, maxSweep: 180)
    let clock = ContinuousClock()
    var best = Duration.seconds(1)
    for _ in 0..<10 {
        let start = clock.now
        prep.gather(world: world)
        list.build(items: prep.items, view: view, cameraPosition: Vec3(0, 30, 60), shadows: culling)
        best = min(best, clock.now - start)
    }
    #expect(prep.items.count == 10_000)
    print("render prep of 10k entities: \(best) (gather + cull + batch + sort), \(list.stats)")
}

// MARK: Serialization

/// Rendering components save under their stable names and load back unchanged.
@MainActor @Test func renderComponentsRoundTripThroughSceneFiles() throws {
    let world = World()
    let camera = world.spawn(Transform(position: Vec3(0, 2, 8)), Camera(fovY: 1, near: 0.2, far: 300, reversedZ: true))
    let light = world.spawn(Transform(), DirectionalLight(intensity: 2, direction: Vec3(0, -1, 0), castsShadows: false))
    let environment = world.spawn(SceneEnvironment())
    let mesh = world.spawn(Transform(), MeshRenderer(mesh: .sphere, material: MaterialHandle("glass"), tint: Vec3(1, 0, 0), opacity: 0.5))
    world.setParent(mesh, to: camera)
    let data = try world.save()
    let text = String(decoding: data, as: UTF8.self)
    for name in ["Camera", "DirectionalLight", "SceneEnvironment", "MeshRenderer"] {
        #expect(text.contains("\"\(name)\""))
    }

    let loaded = World()
    try loaded.load(data)
    #expect(try loaded.save() == data)
    func only<C: Component & Equatable>(_ type: C.Type, in w: World) -> C? {
        var found: [C] = []
        w.query(type) { _, c in found.append(c) }
        return found.count == 1 ? found[0] : nil
    }
    #expect(only(Camera.self, in: loaded) == world.get(Camera.self, for: camera))
    #expect(only(DirectionalLight.self, in: loaded) == world.get(DirectionalLight.self, for: light))
    #expect(only(SceneEnvironment.self, in: loaded) == world.get(SceneEnvironment.self, for: environment))
    #expect(only(MeshRenderer.self, in: loaded) == world.get(MeshRenderer.self, for: mesh))
}
