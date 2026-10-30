import Testing
@testable import Engine

@MainActor private final class FakeTexture: GPUTexture {
    var width = 4, height = 4
    var format = TextureFormat.rgba8Unorm
    var mipLevelCount = 1
}

@MainActor private func makeList(scale: Float = 1, width: Int = 400, height: Int = 300) -> UIDrawList {
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (width, height), scale: scale)
    return list
}

private let box = UIRect(x: 10, y: 20, width: 100, height: 50)

@MainActor @Test func fillRectEmitsAQuadInPixelsWithAnAntialiasMargin() {
    let list = makeList(scale: 2)
    list.fillRect(box, color: UIColor(1, 0, 0, 0.5))
    #expect(list.vertices.count == 4)
    #expect(list.indices == [0, 1, 2, 0, 2, 3])
    // Points are scaled to framebuffer pixels (x2) and the quad grows by one pixel per side.
    let m = UIDrawList.antialiasMargin
    #expect(list.vertices[0].position == Vec2(20 - m, 40 - m))
    #expect(list.vertices[2].position == Vec2(220 + m, 140 + m))
    #expect(list.vertices[0].halfSize == Vec2(100, 50))
    #expect(list.vertices[0].local == Vec2(-100 - m, -50 - m))
    #expect(list.vertices[0].color == Vec4(1, 0, 0, 0.5))
    #expect(list.vertices[0].params.x == 0)
    #expect(list.stats.items == 1)
}

@MainActor @Test func emptyRectsAreSkipped() {
    let list = makeList()
    list.fillRect(UIRect(x: 0, y: 0, width: 0, height: 10), color: .white)
    list.fillRect(UIRect(x: 0, y: 0, width: 10, height: -1), color: .white)
    #expect(list.vertices.isEmpty && list.batches.isEmpty)
}

@Test func radiiScaleAndShrinkToFit() {
    let r = UICornerRadii(topLeft: 30, topRight: 30, bottomRight: 0, bottomLeft: 0).fitted(toWidth: 40, height: 100, scale: 1)
    // 30 + 30 > 40 along the top: both shrink by 40/60.
    #expect(abs(r.topLeft - 20) < 1e-5 && abs(r.topRight - 20) < 1e-5)
    let scaled = UICornerRadii(4).fitted(toWidth: 100, height: 100, scale: 2)
    #expect(scaled == UICornerRadii(8))
    #expect(UICornerRadii(-3).fitted(toWidth: 10, height: 10) == .zero)
}

@MainActor @Test func perCornerRadiiReachTheVertices() {
    let list = makeList()
    list.fillRect(box, color: .white, radii: UICornerRadii(topLeft: 1, topRight: 2, bottomRight: 3, bottomLeft: 4))
    #expect(list.vertices[0].radii == Vec4(1, 2, 3, 4))
}

@MainActor @Test func strokeWidthIsClampedToHalfTheShortSide() {
    let list = makeList()
    list.strokeRect(box, color: .white, width: 3)
    #expect(list.vertices[0].params.x == 3)
    list.strokeRect(box, color: .white, width: 500)
    #expect(list.vertices[4].params.x == 25)
}

@MainActor @Test func gradientCornersGetAffineColors() {
    let list = makeList()
    list.fillRect(box, fill: .linearGradient(start: .black, end: .white, angle: 0))
    // Left to right: the left edge is the start color, the right edge the end color, and the
    // margin extrapolates (the shader clamps).
    let m = UIDrawList.antialiasMargin
    let left = list.vertices[0].color, right = list.vertices[1].color
    #expect(left.x < 0 && right.x > 1)
    #expect(abs(left.x - (-m / box.width)) < 1e-5)
    #expect(list.vertices[0].color == list.vertices[3].color)
    // A vertical gradient runs top to bottom by default.
    list.fillRect(box, fill: .linearGradient(start: .black, end: .white))
    #expect(list.vertices[4].color.x < list.vertices[7].color.x)
    #expect(abs(list.vertices[4].color.x - list.vertices[5].color.x) < 1e-5)
}

@MainActor @Test func imageUVsFollowTheRectAndTheUVRect() {
    let list = makeList()
    let texture = FakeTexture()
    list.drawImage(texture, in: box, uv: UIRect(x: 0.5, y: 0, width: 0.5, height: 1))
    let m = UIDrawList.antialiasMargin
    // The visible rect's corners map exactly to the UV rect; the margin extrapolates.
    #expect(abs(list.vertices[0].uv.x - (0.5 - 0.5 * m / box.width)) < 1e-5)
    #expect(abs(list.vertices[2].uv.x - (1 + 0.5 * m / box.width)) < 1e-5)
    #expect(list.vertices[0].params.y == UIQuadMode.image.shaderMode)
}

@MainActor @Test func linesAreRotatedCapsules() {
    let list = makeList()
    list.drawLine(from: Vec2(10, 10), to: Vec2(10, 110), width: 4, color: .white, cap: .round)
    #expect(list.vertices[0].halfSize == Vec2(52, 2))
    #expect(list.vertices[0].radii == Vec4(repeating: 2))
    // A vertical line: the local x axis (along the line) maps to world y.
    let a = list.vertices[0], b = list.vertices[1]
    #expect(abs(b.position.y - a.position.y) > 100 && abs(b.position.x - a.position.x) < 1e-3)
    list.drawLine(from: .zero, to: Vec2(10, 0), width: 2, color: .white)
    #expect(list.vertices[4].radii == Vec4(repeating: 0))
    list.drawLine(from: .zero, to: Vec2(10, 0), width: 0, color: .white)
    #expect(list.vertices.count == 8)
}

@MainActor @Test func texturedQuadsCarryModeAndSmoothing() {
    let list = makeList()
    let atlas = FakeTexture()
    list.drawTexturedRect(atlas, rect: box, uv: UIRect(x: 0.25, y: 0.25, width: 0.1, height: 0.1), color: .white,
                          mode: .sdf(smoothing: 0.1))
    #expect(list.vertices[0].position == Vec2(10, 20))  // no margin on free quads
    #expect(list.vertices[0].params == Vec4(0, 3, 0.1, 0))
    #expect(abs(list.vertices[2].uv.x - 0.35) < 1e-6)
}

@MainActor @Test func consecutiveItemsWithTheSameTextureAndClipShareADraw() {
    let list = makeList()
    let a = FakeTexture(), b = FakeTexture()
    for _ in 0..<3 { list.drawImage(a, in: box) }
    #expect(list.batches.count == 1 && list.batches[0].indexCount == 18)
    list.drawImage(b, in: box)
    #expect(list.batches.count == 2)
    list.drawImage(a, in: box)
    #expect(list.batches.count == 3)
    #expect(list.batches.map(\.firstIndex) == [0, 18, 24])
    #expect(list.stats.batches == 3 && list.stats.items == 5)
}

@MainActor @Test func textureLessItemsJoinAnyBatchAndBatchesAdoptTheFirstTexture() {
    let list = makeList()
    let a = FakeTexture(), b = FakeTexture()
    list.fillRect(box, color: .white)
    list.drawImage(a, in: box)  // the solid-only batch adopts the texture
    list.fillRect(box, color: .white)
    list.strokeRect(box, color: .white)
    list.drawLine(from: .zero, to: Vec2(5, 5), color: .white)
    #expect(list.batches.count == 1 && list.batches[0].texture === a)
    list.drawImage(b, in: box)
    #expect(list.batches.count == 2 && list.batches[1].texture === b)
}

@MainActor @Test func differentClipsBreakBatchesButEqualRectanglesMerge() {
    let list = makeList()
    let a = FakeTexture()
    list.drawImage(a, in: box)
    list.pushClip(UIRect(x: 0, y: 0, width: 200, height: 200))
    list.drawImage(a, in: box)
    list.popClip()
    #expect(list.batches.count == 2)
    // Pushing an equal clip again after the pop doesn't split: the rectangle is what counts.
    list.pushClip(UIRect(x: 0, y: 0, width: 200, height: 200))
    list.drawImage(a, in: box)
    list.popClip()
    list.pushClip(UIRect(x: 0, y: 0, width: 200, height: 200))
    list.drawImage(a, in: box)
    list.popClip()
    #expect(list.batches.count == 2)
    #expect(list.batches[1].indexCount == 18)
}

@MainActor @Test func nestedClipsIntersect() {
    let list = makeList()
    list.pushClip(UIRect(x: 10, y: 10, width: 100, height: 100))
    list.pushClip(UIRect(x: 60, y: 0, width: 100, height: 50))
    #expect(list.clipBounds == UIRect(x: 60, y: 10, width: 50, height: 40))
    list.popClip()
    #expect(list.clipBounds == UIRect(x: 10, y: 10, width: 100, height: 100))
    list.popClip()
    #expect(list.clipBounds == UIRect(x: 0, y: 0, width: 400, height: 300))
}

@MainActor @Test func clipsAreClampedToTheTargetRoundedToPixelsAndScaled() {
    let list = makeList(scale: 2, width: 400, height: 300)
    list.pushClip(UIRect(x: -50, y: 10.3, width: 1000, height: 20.2))
    list.fillRect(UIRect(x: 0, y: 0, width: 100, height: 100), color: .white)
    // 10.3 * 2 = 20.6 -> 21, 30.5 * 2 = 61; x is clamped to the 400 px target.
    #expect(list.batches[0].clip == UIPixelRect(x0: 0, y0: 21, x1: 400, y1: 61))
    #expect(list.batches[0].clip.scissor == ScissorRect(x: 0, y: 21, width: 400, height: 40))
    list.popClip()
}

@MainActor @Test func itemsOutsideTheClipAreCulledAndDisjointClipsShowNothing() {
    let list = makeList()
    list.pushClip(UIRect(x: 0, y: 0, width: 50, height: 50))
    list.fillRect(UIRect(x: 100, y: 100, width: 20, height: 20), color: .white)
    #expect(list.vertices.isEmpty && list.stats.culled == 1)
    list.fillRect(UIRect(x: 40, y: 40, width: 20, height: 20), color: .white)
    #expect(list.stats.items == 1)
    list.pushClip(UIRect(x: 200, y: 200, width: 10, height: 10))  // disjoint from the outer clip
    #expect(list.clipBounds == nil)
    list.fillRect(UIRect(x: 0, y: 0, width: 400, height: 300), color: .white)
    #expect(list.stats.items == 1 && list.stats.culled == 2)
    list.popClip()
    list.popClip()
}

@MainActor @Test func beginFrameClearsEverything() {
    let list = makeList()
    list.fillRect(box, color: .white)
    list.beginFrame(framebufferSize: (800, 600), scale: 2)
    #expect(list.vertices.isEmpty && list.indices.isEmpty && list.batches.isEmpty)
    #expect(list.stats == UIDrawStats())
    #expect(list.size == Vec2(400, 300))
}

@Test func vertexLayoutMatchesTheShader() {
    #expect(MemoryLayout<UIVertex>.stride == 80)
    #expect(UIVertex.layout.attributes.map(\.offset) == [0, 8, 16, 32, 40, 48, 64])
}

@Test func scissorRectsAreClampedInsideTheTarget() {
    #expect(ScissorRect(x: -5, y: -5, width: 30, height: 30).clamped(toWidth: 100, height: 100)
        == ScissorRect(x: 0, y: 0, width: 25, height: 25))
    #expect(ScissorRect(x: 90, y: 90, width: 50, height: 50).clamped(toWidth: 100, height: 100)
        == ScissorRect(x: 90, y: 90, width: 10, height: 10))
    #expect(ScissorRect(x: 200, y: 0, width: 5, height: 5).clamped(toWidth: 100, height: 100).width >= 1)
}
