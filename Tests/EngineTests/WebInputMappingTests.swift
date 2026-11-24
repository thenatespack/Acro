import Testing
@testable import EngineCore
@testable import EngineBackends

// The browser input tables CanvasWindow and WebGamepadSource use (WebInputMapping.swift).
@Suite struct WebInputMappingTests {
    @Test func everyKeyHasACodeThatMapsBack() {
        for key in Key.allCases {
            let code = WebInputMapping.code(for: key)
            #expect(code != nil, "\(key) has no KeyboardEvent.code")
            if let code { #expect(WebInputMapping.key(forCode: code) == key, "\(code)") }
        }
    }

    /// Every key means the same physical key on every platform: each native window maps every
    /// case (the keypad's Enter is `enter` everywhere).
    @MainActor @Test func nativeWindowsMapEveryKey() {
        #if canImport(AppKit)
        let appKit = Set(AppKitWindow.keyMap.values).union(AppKitWindow.modifierMap.values.map { $0.0 })
        #expect(appKit == Set(Key.allCases), "AppKitWindow lacks \(Set(Key.allCases).subtracting(appKit))")
        #expect(AppKitWindow.keyMap[76] == .enter && AppKitWindow.keyMap[36] == .enter)
        #endif
        #if ENGINE_VULKAN
        let glfw = GLFWWindow.keyMap.map { $0.0 }
        #expect(Set(glfw) == Set(Key.allCases), "GLFWWindow lacks \(Set(Key.allCases).subtracting(glfw))")
        #expect(glfw.count == Key.allCases.count, "a key is mapped twice")
        #endif
    }

    @Test func codesFollowTheUIEventsNames() {
        #expect(WebInputMapping.key(forCode: "KeyW") == .w)
        #expect(WebInputMapping.key(forCode: "Digit0") == .num0)
        #expect(WebInputMapping.key(forCode: "F12") == .f12)
        #expect(WebInputMapping.key(forCode: "ArrowUp") == .up)
        #expect(WebInputMapping.key(forCode: "Backquote") == .grave)
        #expect(WebInputMapping.key(forCode: "MetaLeft") == .leftSuper)
        #expect(WebInputMapping.key(forCode: "OSRight") == .rightSuper)
        #expect(WebInputMapping.key(forCode: "NumpadEnter") == .enter)
        #expect(WebInputMapping.key(forCode: "Period") == .period)
        #expect(WebInputMapping.key(forCode: "Quote") == .apostrophe)
        #expect(WebInputMapping.key(forCode: "Numpad7") == .numpad7)
        #expect(WebInputMapping.key(forCode: "NumpadSubtract") == .numpadSubtract)
        #expect(WebInputMapping.key(forCode: "IntlBackslash") == nil)
        #expect(WebInputMapping.key(forCode: "") == nil)
    }

    @Test func browserShortcutsKeepTheirDefaultAction() {
        #expect(WebInputMapping.preventsDefault(.space, modifiers: []))
        #expect(WebInputMapping.preventsDefault(.tab, modifiers: .shift))
        #expect(WebInputMapping.preventsDefault(.down, modifiers: []))
        #expect(!WebInputMapping.preventsDefault(.r, modifiers: .control))
        #expect(!WebInputMapping.preventsDefault(.c, modifiers: .command))
        #expect(!WebInputMapping.preventsDefault(.f5, modifiers: []))
        #expect(!WebInputMapping.preventsDefault(.f12, modifiers: []))
    }

    @Test func typedTextIsSingleCharactersWithoutShortcutModifiers() {
        #expect(WebInputMapping.typedText(key: "a", modifiers: []) == "a")
        #expect(WebInputMapping.typedText(key: "é", modifiers: .alt) == "é")
        #expect(WebInputMapping.typedText(key: "€", modifiers: [.control, .alt]) == "€")  // AltGr
        #expect(WebInputMapping.typedText(key: "a", modifiers: .control) == nil)
        #expect(WebInputMapping.typedText(key: "a", modifiers: .command) == nil)
        #expect(WebInputMapping.typedText(key: "Enter", modifiers: []) == nil)
        #expect(WebInputMapping.typedText(key: "Dead", modifiers: []) == nil)
        #expect(WebInputMapping.typedText(key: "👍🏽", modifiers: []) == "👍🏽")
    }

    @Test func wheelDeltasBecomePointsScrollingUpAndLeft() {
        #expect(WebInputMapping.scroll(deltaX: 0, deltaY: 100, mode: 0, pageHeight: 600) == Vec2(0, -100))
        #expect(WebInputMapping.scroll(deltaX: -2, deltaY: 3, mode: 1, pageHeight: 600) == Vec2(32, -48))
        #expect(WebInputMapping.scroll(deltaX: 0, deltaY: -1, mode: 2, pageHeight: 600) == Vec2(0, 600))
    }

    @Test func mouseButtonsAndCursors() {
        #expect(WebInputMapping.mouseButton(0) == .left)
        #expect(WebInputMapping.mouseButton(1) == .middle)
        #expect(WebInputMapping.mouseButton(2) == .right)
        #expect(WebInputMapping.mouseButton(3) == nil)
        #expect(WebInputMapping.cssCursor(.hidden) == "none")
        #expect(WebInputMapping.cssCursor(.resizeHorizontal) == "ew-resize")
    }

    @Test func standardGamepadLayout() {
        var pressed = [Bool](repeating: false, count: 17)
        pressed[0] = true; pressed[3] = true; pressed[9] = true; pressed[15] = true; pressed[16] = true
        pressed[6] = true  // the left trigger, reported through its value instead
        var values = [Double](repeating: 0, count: 17)
        values[6] = 0.4; values[7] = 1.5
        let snapshot = WebInputMapping.gamepadSnapshot(id: 2, name: "Pad", pressed: pressed, values: values, axes: [0.25, -1, -0.5, 0.5])
        #expect(snapshot.id == 2)
        #expect(snapshot.buttons == [.south, .north, .start, .dpadRight, .guide])
        #expect(snapshot.leftStick == Vec2(0.25, 1))  // the API's y is down
        #expect(snapshot.rightStick == Vec2(-0.5, -0.5))
        #expect(snapshot.leftTrigger == 0.4)
        #expect(snapshot.rightTrigger == 1)  // clamped
        // Fewer buttons and axes than the standard layout read as released / centred.
        let small = WebInputMapping.gamepadSnapshot(id: 0, name: "Small", pressed: [true], values: [1], axes: [0.5])
        #expect(small.buttons == [.south] && small.leftStick == Vec2(0.5, 0) && small.rightTrigger == 0)
    }
}
