import Testing
@testable import Engine

private let red = Vec4(1, 0, 0, 1)

@Test func shapesBecomeTheExpectedSegments() {
    let debug = DebugDraw()
    debug.box(Bounds(center: Vec3(1, 2, 3), halfExtent: Vec3(1, 1, 1)), color: red)
    #expect(debug.segments[.tested]?.count == 12)
    // Every edge of an axis-aligned box is axis-aligned and 2 long.
    for segment in debug.segments[.tested]! {
        let d = Vec3(segment.end.x, segment.end.y, segment.end.z) - Vec3(segment.start.x, segment.start.y, segment.start.z)
        #expect(abs(length(d) - 2) < 1e-5)
        #expect([d.x, d.y, d.z].filter { abs($0) > 1e-5 }.count == 1)
    }

    debug.removeAll()
    debug.sphere(center: .zero, radius: 2, color: red, segments: 16)
    #expect(debug.segmentCount == 48)  // three closed circles
    for segment in debug.segments[.tested]! {
        #expect(abs(length(Vec3(segment.start.x, segment.start.y, segment.start.z)) - 2) < 1e-5)
    }

    debug.removeAll()
    debug.polyline([.zero, Vec3(1, 0, 0), Vec3(1, 1, 0)], color: red)
    #expect(debug.segmentCount == 2)
    debug.polyline([.zero, Vec3(1, 0, 0), Vec3(1, 1, 0)], closed: true, color: red)
    #expect(debug.segmentCount == 5)

    debug.removeAll()
    debug.arrow(from: .zero, to: Vec3(0, 0, 5), color: red)
    debug.axes(.identity, style: .onTop)
    #expect(debug.segments[.tested]?.count == 5)
    #expect(debug.segments[.onTop]?.count == 15)
    // The axes are red, green, blue along x, y, z.
    let shafts = stride(from: 0, to: 15, by: 5).map { debug.segments[.onTop]![$0] }
    #expect(shafts.map(\.end.x) == [1, 0, 0] && shafts.map(\.end.y) == [0, 1, 0] && shafts.map(\.end.z) == [0, 0, 1])
    #expect(shafts[0].color.x > 0.5 && shafts[1].color.y > 0.5 && shafts[2].color.z > 0.5)
}

@Test(arguments: [false, true]) func frustumCornersLieOnTheNearAndFarPlanes(reversedZ: Bool) {
    let projection = reversedZ
        ? Mat4.perspective(fovY: .pi / 2, aspect: 2, near: 10, far: 1)
        : Mat4.perspective(fovY: .pi / 2, aspect: 2, near: 1, far: 10)
    let debug = DebugDraw()
    debug.frustum(viewProjection: projection * Mat4.lookAt(eye: .zero, target: Vec3(0, 0, -1)), color: red)
    let segments = debug.segments[.tested]!
    #expect(segments.count == 12)
    let depths = Set(segments.flatMap { [$0.start.z, $0.end.z] }.map { ($0 * 1000).rounded() / 1000 })
    #expect(depths == [-1, -10])
    // The far plane is 2 * 10 * tan(45°) = 20 high and 40 wide.
    let far = segments.flatMap { [$0.start, $0.end] }.filter { abs($0.z + 10) < 1e-3 }
    #expect(abs(far.map(\.y).max()! - 10) < 1e-3 && abs(far.map(\.x).max()! - 20) < 1e-3)
}

@Test func styleEncodesWidthAndBatchesByDepthMode() {
    let debug = DebugDraw()
    debug.line(.zero, Vec3(1, 0, 0), color: red, style: DebugDraw.Style(width: 3))
    debug.line(.zero, Vec3(1, 0, 0), color: red, style: DebugDraw.Style(width: 0.1, worldWidth: true))
    debug.line(.zero, Vec3(1, 0, 0), color: red, style: DebugDraw.Style(width: 2, depth: .onTop))
    // Pixel widths are positive, world widths negative; one batch per depth mode.
    #expect(debug.segments[.tested]!.map(\.start.w) == [3, -0.1])
    #expect(debug.segments[.onTop]!.map(\.start.w) == [2])
    #expect(MemoryLayout<DebugSegment>.stride == 48)
}

@Test func lifetimesExpireAfterTheirDuration() {
    let debug = DebugDraw()
    debug.line(.zero, Vec3(1, 0, 0), color: red)                       // this frame only
    debug.line(.zero, Vec3(0, 1, 0), color: red, duration: 0.05)       // a few frames
    debug.text("label", at: .zero, duration: 0.02)
    debug.grid = DebugGrid()
    #expect(debug.segmentCount == 2 && debug.labels.count == 1)

    debug.beginFrame(dt: 1.0 / 60)
    #expect(debug.segments[.tested]!.map(\.end.y) == [1])
    #expect(debug.labels.count == 1)
    debug.beginFrame(dt: 1.0 / 60)
    #expect(debug.labels.isEmpty && debug.segmentCount == 1)
    debug.beginFrame(dt: 1.0 / 60)
    #expect(debug.segmentCount == 0)
    // The grid is a setting and stays.
    #expect(debug.grid != nil && !debug.isEmpty)
    debug.grid = nil
    #expect(debug.isEmpty)
}

@Test func renderTargetSizingClampsAndOnlyReportsChanges() {
    var sizing = RenderTargetSizing(width: 0, height: 50_000, maxSize: 16384)
    #expect(sizing.width == 1 && sizing.height == 16384)
    var changed = sizing.update(width: 640, height: 360)
    #expect(changed && sizing.width == 640 && sizing.height == 360)
    changed = sizing.update(width: 640, height: 360)
    #expect(!changed)
    changed = sizing.update(width: 640, height: 99_999)
    #expect(changed && sizing.height == 16384)
    changed = sizing.update(width: -5, height: 10)
    #expect(changed && sizing.width == 1 && sizing.height == 10)
    changed = sizing.update(width: 0, height: 10)  // clamps to the same size
    #expect(!changed)
    // Points to pixels, rounded.
    let pixels = RenderTargetSizing.pixels(points: Vec2(100.4, 50.25), scale: 2)
    #expect(pixels.width == 201 && pixels.height == 101)
}
