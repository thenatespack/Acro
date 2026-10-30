import Testing
@testable import Engine

@Test(arguments: [false, true]) func frustumKeepsBoxesInViewAndRejectsOthers(reversedZ: Bool) {
    let projection = reversedZ
        ? Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 100, far: 1)
        : Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 1, far: 100)
    // Camera at the origin looking down -Z.
    let frustum = Frustum(viewProjection: projection * Mat4.lookAt(eye: .zero, target: Vec3(0, 0, -1)))
    let unit = Vec3(repeating: 1)
    #expect(frustum.intersects(center: Vec3(0, 0, -10), halfExtent: unit))
    #expect(!frustum.intersects(center: Vec3(0, 0, 10), halfExtent: unit))     // behind
    #expect(!frustum.intersects(center: Vec3(0, 0, -150), halfExtent: unit))   // past far
    #expect(!frustum.intersects(center: Vec3(20, 0, -10), halfExtent: unit))   // off to the side
    #expect(frustum.intersects(center: Vec3(10.5, 0, -10), halfExtent: unit))  // straddles the side plane
}

@Test func sweptBoxCoversItsWholePath() {
    let frustum = Frustum(viewProjection: Mat4.perspective(fovY: .pi / 2, aspect: 1, near: 1, far: 100)
        * Mat4.lookAt(eye: .zero, target: Vec3(0, 0, -1)))
    let unit = Vec3(repeating: 1)
    // Starts behind the camera, ends behind it on the other side, crosses the view in between.
    #expect(frustum.intersects(center: Vec3(-30, 0, -10), halfExtent: unit, sweptBy: Vec3(60, 0, 0)))
    #expect(!frustum.intersects(center: Vec3(-30, 0, -10), halfExtent: unit))
    // Swept away from the view: still outside.
    #expect(!frustum.intersects(center: Vec3(0, 0, 10), halfExtent: unit, sweptBy: Vec3(0, 0, 20)))
}
