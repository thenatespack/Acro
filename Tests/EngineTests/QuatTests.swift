import Testing
@testable import Engine

private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-5) -> Bool { length(a - b) < eps }

private func approx(_ a: Mat4, _ b: Mat4, _ eps: Float = 1e-5) -> Bool {
    [a.c0 - b.c0, a.c1 - b.c1, a.c2 - b.c2, a.c3 - b.c3].allSatisfy { ($0 * $0).sum() < eps }
}

/// Same rotation (q and -q are equal rotations).
private func sameRotation(_ a: Quat, _ b: Quat, _ eps: Float = 1e-5) -> Bool {
    abs(abs((a.vector * b.vector).sum()) - 1) < eps
}

@Test func quatAxisAngleMatchesMatrixRotation() {
    for (angle, axis) in [(Float.pi / 2, Vec3(0, 0, 1)), (0.7, Vec3(1, 2, 3)), (-2.5, Vec3(0, 1, 0)), (.pi, Vec3(1, 0, 0))] {
        let q = Quat(angle: angle, axis: axis)
        #expect(abs(q.length - 1) < 1e-6)
        #expect(approx(q.matrix, Mat4.rotation(angle: angle, axis: axis)))
        let v = Vec3(0.3, -1.2, 2)
        let m = Mat4.rotation(angle: angle, axis: axis) * Vec4(v, 0)
        #expect(approx(q * v, Vec3(m.x, m.y, m.z)))
    }
    #expect(approx(Quat(angle: .pi / 2, axis: Vec3(0, 0, 1)) * Vec3(1, 0, 0), Vec3(0, 1, 0)))
    #expect(Quat.identity.matrix == Mat4.identity)
}

@Test func quatProductComposesLikeMatrices() {
    let a = Quat(angle: 0.8, axis: Vec3(1, 1, 0)), b = Quat(angle: -1.3, axis: Vec3(0, 0.5, 1))
    #expect(approx((a * b).matrix, a.matrix * b.matrix))
    let v = Vec3(1, 2, 3)
    #expect(approx((a * b) * v, a * (b * v)))
    #expect(sameRotation(a * a.conjugate, .identity))
    #expect(sameRotation(a * a.inverse, .identity))
    let scaled = Quat(vector: a.vector * 3)
    #expect(approx(Quat(vector: (scaled * scaled.inverse).vector).imaginary, .zero))
    #expect(abs(scaled.normalized.length - 1) < 1e-6)
}

@Test func quatRoundTripsThroughMatrix() {
    // Covers every branch of the matrix → quaternion conversion (positive trace, and each
    // of x, y, z dominating near 180°).
    let cases: [Quat] = [
        .identity,
        Quat(angle: 0.4, axis: Vec3(1, -2, 0.5)),
        Quat(angle: 3.1, axis: Vec3(1, 0.1, 0.05)),
        Quat(angle: 3.1, axis: Vec3(0.1, 1, 0.05)),
        Quat(angle: 3.1, axis: Vec3(0.05, 0.1, 1)),
        Quat(angle: .pi, axis: Vec3(0, 1, 0)),
    ]
    for q in cases {
        #expect(sameRotation(Quat(rotationMatrix: q.matrix), q))
    }
}

@Test func quatSlerpInterpolatesAlongShortestArc() {
    let a = Quat.identity, b = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))
    #expect(sameRotation(Quat.slerp(a, b, 0), a))
    #expect(sameRotation(Quat.slerp(a, b, 1), b))
    #expect(sameRotation(Quat.slerp(a, b, 0.5), Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))))
    // -b is the same rotation; slerp must still take the short way.
    let negated = Quat(vector: -b.vector)
    #expect(sameRotation(Quat.slerp(a, negated, 0.5), Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))))
    #expect(abs(Quat.slerp(a, b, 0.3).length - 1) < 1e-5)
}

@Test func matrixInverseUndoesTransform() {
    let m = Mat4(translation: Vec3(1, -2, 3), rotation: Quat(angle: 0.9, axis: Vec3(1, 1, 1)), scale: Vec3(2, 0.5, 3))
    #expect(approx(m * m.inverse, .identity))
    #expect(approx(m.inverse * m, .identity))
    let p = Mat4.perspective(fovY: 1, aspect: 1.5, near: 0.1, far: 50)
    #expect(approx(p * p.inverse, .identity, 1e-4))
}

@Test func trsMatrixMatchesComposition() {
    let t = Vec3(1, 2, 3), q = Quat(angle: 0.6, axis: Vec3(0, 1, 1)), s = Vec3(2, 3, 4)
    let expected = Mat4.translation(t) * q.matrix * Mat4.scale(s)
    #expect(approx(Mat4(translation: t, rotation: q, scale: s), expected))
}

@Test func transformDecomposesMatrix() {
    let original = Transform(position: Vec3(4, -1, 2), rotation: Quat(angle: 1.1, axis: Vec3(1, 0, 1)), scale: Vec3(1, 2, 0.5))
    let decomposed = Transform(matrix: original.matrix)
    #expect(approx(decomposed.position, original.position))
    #expect(approx(decomposed.scale, original.scale))
    #expect(sameRotation(decomposed.rotation, original.rotation))
    // Mirrored: negative scale comes back on x, and the matrix is reproduced.
    let mirrored = Transform(scale: Vec3(1, -1, 1)).matrix
    #expect(approx(Transform(matrix: mirrored).matrix, mirrored))
}
