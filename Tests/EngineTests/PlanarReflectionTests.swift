import Foundation
import Testing
@testable import Engine

private func close(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool {
    abs(a.x - b.x) < eps && abs(a.y - b.y) < eps && abs(a.z - b.z) < eps
}

private func ndc(_ m: Mat4, _ p: Vec3) -> Vec3 {
    let c = m * Vec4(p, 1)
    return Vec3(c.x / c.w, c.y / c.w, c.z / c.w)
}

@Test func planeComesFromTheTransformUpAxisAndPosition() {
    let plane = ReflectionPlane(world: Mat4.translation(Vec3(0, 2, 0)) * Mat4.scale(Vec3(5, 5, 5)))
    #expect(close(plane.normal, Vec3(0, 1, 0)))
    #expect(abs(plane.offset - 2) < 1e-5)
    #expect(abs(plane.distance(to: Vec3(3, 5, -1)) - 3) < 1e-5)
    #expect(abs(plane.distance(to: Vec3(0, 1, 0)) + 1) < 1e-5)
}

@Test func mirrorIsAnInvolutionThatFixesThePlane() {
    let plane = ReflectionPlane(normal: normalize(Vec3(1, 2, 0.5)), offset: 1.5)
    let onPlane = Vec3(0, 0, 0) + plane.normal * 1.5
    let moved = plane.mirror * Vec4(onPlane, 1)
    #expect(close(Vec3(moved.x, moved.y, moved.z), onPlane))
    let p = Vec3(3, -2, 4)
    let once = plane.mirror * Vec4(p, 1)
    let twice = plane.mirror * once
    #expect(close(Vec3(twice.x, twice.y, twice.z), p))
    #expect(abs(plane.distance(to: Vec3(once.x, once.y, once.z)) + plane.distance(to: p)) < 1e-4)
}

@Test(arguments: [false, true]) func mirroredCameraSeesTheReflectedPointAtTheSameSpotAsTheReceiverLookup(reversedZ: Bool) {
    let plane = ReflectionPlane(normal: Vec3(0, 1, 0), offset: 0)
    let projection = reversedZ
        ? Mat4.perspective(fovY: 1, aspect: 1.5, near: 100, far: 0.1)
        : Mat4.perspective(fovY: 1, aspect: 1.5, near: 0.1, far: 100)
    let view = Mat4.lookAt(eye: Vec3(0, 3, 6), target: Vec3(0, 0, 0))
    let camera = plane.mirroredCamera(view: view, projection: projection, reversedZ: reversedZ, clipBias: 0.01)
    // A point above the plane: it appears in the mirrored image where its reflection does in the
    // real view (x flipped by the mirrored projection).
    let above = Vec3(1, 1, 0)
    let image = ndc(camera.projection * camera.view, above)
    let mirrored = plane.mirror * Vec4(above, 1)
    let real = ndc(projection * view, Vec3(mirrored.x, mirrored.y, mirrored.z))
    // The image of `above` seen by the mirrored camera is the real view of its mirror image, flipped in x.
    #expect(abs(image.x + real.x) < 1e-3 && abs(image.y - real.y) < 1e-3)
}

@Test(arguments: [false, true]) func obliqueNearPlaneClipsBelowThePlaneOnly(reversedZ: Bool) {
    let plane = ReflectionPlane(normal: Vec3(0, 1, 0), offset: 0)
    let projection = reversedZ
        ? Mat4.perspective(fovY: 1, aspect: 1, near: 100, far: 0.1)
        : Mat4.perspective(fovY: 1, aspect: 1, near: 0.1, far: 100)
    let view = Mat4.lookAt(eye: Vec3(0, 3, 6), target: Vec3(0, 0, 0))
    let camera = plane.mirroredCamera(view: view, projection: projection, reversedZ: reversedZ, clipBias: 0)
    let viewProj = camera.projection * camera.view
    // Depth [0, 1] inside; a point just above the plane is kept, one below falls outside the volume.
    let nearGate: (Vec3) -> Bool = { p in
        let c = viewProj * Vec4(p, 1)
        return c.z >= 0 && c.z <= c.w
    }
    #expect(nearGate(Vec3(0, 0.5, 0)))
    #expect(!nearGate(Vec3(0, -0.5, 0)))
}

@Test func planarReflectionDecodesMissingKeysToDefaults() throws {
    let decoded = try JSONDecoder().decode(PlanarReflection.self, from: Data(#"{"strength":0.25}"#.utf8))
    var expected = PlanarReflection()
    expected.strength = 0.25
    #expect(decoded == expected)
}

@MainActor @Test func planarReflectionRoundTripsThroughSceneFilesAndPicksTheFirstEnabled() throws {
    ComponentRegistry.register(PlanarReflection.self)
    let world = World()
    let off = world.spawn(Transform(position: Vec3(0, 9, 0)), PlanarReflection(isEnabled: false))
    let first = world.spawn(Transform(position: Vec3(0, 1, 0)), PlanarReflection(strength: 0.5))
    _ = world.spawn(Transform(position: Vec3(0, 2, 0)), PlanarReflection())
    world.update(dt: 0)
    let loaded = World()
    let roots = try loaded.load(world.save())
    #expect(loaded.get(PlanarReflection.self, for: roots[0]) == world.get(PlanarReflection.self, for: off))
    #expect(loaded.get(PlanarReflection.self, for: roots[1])?.strength == 0.5)

    var state = ReflectionState()
    state.find(in: world)
    #expect(state.plane?.settings.strength == 0.5)
    #expect(abs((state.plane?.plane.offset ?? 0) - 1) < 1e-5)
    _ = first
}
