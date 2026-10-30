import Testing
@testable import Engine

@Test func captureNeedsFocusAndEndsOnFocusLossOrEscape() {
    var capture = MouseCapture()
    capture.request(true)
    #expect(capture.isActive)
    // Losing focus ends it for good; refocusing doesn't grab the mouse again.
    capture.setFocused(false)
    #expect(!capture.isActive)
    capture.setFocused(true)
    #expect(!capture.isActive)
    // Requests while unfocused are ignored.
    capture.setFocused(false)
    capture.request(true)
    capture.setFocused(true)
    #expect(!capture.isActive)
    capture.request(true)
    var released = capture.escapePressed()
    #expect(released && !capture.isActive)
    released = capture.escapePressed()
    #expect(!released)
}

@Test func mouseMotionUsesPositionsUncapturedAndRawMotionCaptured() {
    var motion = MouseMotion()
    func frame(_ x: Float, _ y: Float, captured: Bool, raw: [Vec2] = []) -> Vec2 {
        for delta in raw { motion.addRaw(delta) }
        return motion.endFrame(position: Vec2(x, y), captured: captured)
    }
    #expect(frame(10, 10, captured: false) == .zero)  // no previous position
    #expect(frame(13, 6, captured: false) == Vec2(3, -4))
    // The frame capture starts in reports nothing (the cursor may have been warped).
    #expect(frame(400, 300, captured: true, raw: [Vec2(50, 0)]) == .zero)
    // Captured: raw motion accumulates across events, unbounded by the position.
    #expect(frame(400, 300, captured: true, raw: [Vec2(5, 1), Vec2(3000, 2)]) == Vec2(3005, 3))
    #expect(frame(400, 300, captured: true) == .zero)
    // Releasing reports nothing, then positions again.
    #expect(frame(400, 300, captured: false) == .zero)
    #expect(frame(401, 300, captured: false) == Vec2(1, 0))
}

@MainActor @Test func escapeReleasesCaptureAndIsSwallowedUntilReleased() {
    let input = Input()
    input.isMouseCaptured = true
    #expect(input.isMouseCaptured)
    input.beginFrame()
    input.setKey(.escape, down: true)
    input.recordKeyPress(.escape, modifiers: [], isRepeat: false)
    input.endEvents()
    #expect(!input.isMouseCaptured && !input.wasPressed(.escape) && !input.isDown(.escape) && input.keyPresses.isEmpty)
    // Held: repeats are swallowed too (GLFW polls the key every frame).
    input.beginFrame()
    input.setKey(.escape, down: true)
    input.recordKeyPress(.escape, modifiers: [], isRepeat: true)
    #expect(!input.isDown(.escape) && input.keyPresses.isEmpty)
    input.setKey(.escape, down: false)
    #expect(!input.wasReleased(.escape))
    // Uncaptured, Esc is an ordinary key again.
    input.beginFrame()
    input.setKey(.escape, down: true)
    #expect(input.wasPressed(.escape))
}

@MainActor @Test func inputDeltaFollowsCaptureAndCursorResetsEachFrame() {
    let input = Input()
    input.mousePosition = Vec2(100, 100)
    input.endEvents()
    input.beginFrame()
    input.mousePosition = Vec2(110, 95)
    input.addMouseMotion(Vec2(10, -5))
    input.endEvents()
    #expect(input.mouseDelta == Vec2(10, -5))

    input.isMouseCaptured = true
    input.cursor = .resizeHorizontal
    input.beginFrame()
    #expect(input.cursor == .arrow)
    input.addMouseMotion(Vec2(7, 7))
    input.endEvents()
    #expect(input.mouseDelta == .zero)  // capture started this frame
    input.beginFrame()
    input.addMouseMotion(Vec2(-2000, 3))
    input.endEvents()
    #expect(input.mouseDelta == Vec2(-2000, 3) && input.mousePosition == Vec2(110, 95))

    input.setWindowFocused(false)
    #expect(!input.isMouseCaptured)
    input.isMouseCaptured = true
    #expect(!input.isMouseCaptured)  // ignored without focus
}
