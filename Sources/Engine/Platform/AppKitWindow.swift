#if canImport(AppKit)
import AppKit
import QuartzCore

/// Native macOS window whose content view is backed by a `CAMetalLayer`.
/// Events are pumped manually each frame (no `NSApp.run()`), like a classic game loop.
@MainActor
final class AppKitWindow: NSObject, PlatformWindow, NSWindowDelegate {
    let metalLayer = CAMetalLayer()
    private let window: NSWindow
    private let view: GameView
    private(set) var shouldClose = false
    private var lastTextInputRect = TextInputRect.zero
    /// The capture state last applied, and whether we hid the cursor (`NSCursor.hide` calls nest).
    private var captured = false
    private var cursorHidden = false
    private let gamepads = makePlatformGamepadSource()

    init(title: String, width: Int, height: Int) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        view = GameView(frame: window.contentLayoutRect)
        super.init()

        // Layer-hosting view: assign the layer before enabling wantsLayer.
        view.layer = metalLayer
        view.wantsLayer = true
        metalLayer.contentsScale = window.backingScaleFactor

        window.title = title
        window.contentView = view
        window.makeFirstResponder(view)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        window.center()
        window.makeKeyAndOrderFront(nil)

        installMenu(appName: title)
        app.finishLaunching()
        app.activate()
    }

    var title: String {
        get { window.title }
        set { window.title = newValue }
    }

    var framebufferSize: (width: Int, height: Int) {
        let size = view.convertToBacking(view.bounds).size
        return (Int(size.width), Int(size.height))
    }

    var contentScale: Float { Float(window.backingScaleFactor) }

    func pollEvents(into input: Input) {
        view.input = input
        syncTextInput(input)
        while let event = NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true) {
            switch event.type {
            case .keyDown, .keyUp:
                let key = Self.keyMap[event.keyCode]
                if let key { input.setKey(key, down: event.type == .keyDown) }
                if event.type == .keyDown {
                    if let key { input.recordKeyPress(key, modifiers: Self.modifiers(event), isRepeat: event.isARepeat) }
                    routeText(event, key: key, to: input)
                }
                // Let menu shortcuts (Cmd-Q, Cmd-W…) through; swallow the rest to avoid the system beep.
                if event.modifierFlags.contains(.command) { NSApp.sendEvent(event) }
                continue
            case .flagsChanged:
                if let (key, flag) = Self.modifierMap[event.keyCode] {
                    input.setKey(key, down: event.modifierFlags.contains(flag))
                }
            case .leftMouseDown: input.setButton(.left, down: true)
            case .leftMouseUp: input.setButton(.left, down: false)
            case .rightMouseDown: input.setButton(.right, down: true)
            case .rightMouseUp: input.setButton(.right, down: false)
            case .otherMouseDown where event.buttonNumber == 2: input.setButton(.middle, down: true)
            case .otherMouseUp where event.buttonNumber == 2: input.setButton(.middle, down: false)
            case .scrollWheel:
                // Trackpads and Magic Mouse report points; classic wheels report lines.
                let lines: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 16
                input.addScroll(Vec2(Float(event.scrollingDeltaX * lines), Float(event.scrollingDeltaY * lines)))
            default: break
            }
            switch event.type {
            case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
                // Points, y down, and still reported while the cursor is disassociated from the mouse.
                input.addMouseMotion(Vec2(Float(event.deltaX), Float(event.deltaY)))
            default: break
            }
            NSApp.sendEvent(event)
        }

        let p = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        input.mousePosition = Vec2(Float(p.x), Float(view.bounds.height - p.y))

        if !window.isKeyWindow { input.releaseAll() }
        input.setWindowFocused(window.isKeyWindow && NSApp.isActive)
        input.updateGamepads(gamepads?.snapshots() ?? [])
        metalLayer.contentsScale = window.backingScaleFactor
    }

    /// Sends a key press to an active text input: edit keys and shortcuts directly, everything
    /// else (and all keys while composing) through the system so dead keys, press-and-hold and
    /// input methods get to see it. They call back into `GameView` with text or marked text.
    private func routeText(_ event: NSEvent, key: Key?, to input: Input) {
        guard input.isTextInputActive else { return }
        let flags = event.modifierFlags
        let modifiers = Self.modifiers(event)
        if input.composition == nil, let key, KeyEvent.isRoutedAsKey(key, modifiers: modifiers) {
            input.textKeyEvent(key, modifiers: modifiers, isRepeat: event.isARepeat)
        } else if !flags.contains(.command), !flags.contains(.control) || input.composition != nil {
            view.interpretKeyEvents([event])
        }
    }

    private static func modifiers(_ event: NSEvent) -> KeyModifiers {
        let flags = event.modifierFlags
        var modifiers: KeyModifiers = []
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.alt) }
        if flags.contains(.command) { modifiers.insert(.command) }
        return modifiers
    }

    /// Keeps the system's text input state in step with `input`: drops marked text the engine
    /// no longer wants and tells the input context when the caret moved.
    private func syncTextInput(_ input: Input) {
        if !input.isTextInputActive { view.inputContext?.discardMarkedText() }
        if input.textInputRect != lastTextInputRect {
            lastTextInputRect = input.textInputRect
            view.inputContext?.invalidateCharacterCoordinates()
        }
    }

    func applyCursor(_ cursor: CursorShape, captured: Bool) {
        if captured != self.captured {
            self.captured = captured
            if captured {
                // Park the cursor in the middle of the view, so it reappears there, then lock it.
                // A warp normally suppresses mouse events for a moment; turn that off.
                CGEventSource(stateID: .combinedSessionState)?.localEventsSuppressionInterval = 0
                let center = window.convertPoint(toScreen: view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil))
                let screenHeight = NSScreen.screens.first?.frame.height ?? 0
                CGWarpMouseCursorPosition(CGPoint(x: center.x, y: screenHeight - center.y))  // top-left origin
            }
            CGAssociateMouseAndMouseCursorPosition(captured ? 0 : 1)
        }
        // NSCursor.hide is global, so `.hidden` only hides while the pointer is over the view.
        let location = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        let over = window.isKeyWindow && view.bounds.contains(location)
        let hide = captured || (cursor == .hidden && over)
        if hide != cursorHidden {
            cursorHidden = hide
            if hide { NSCursor.hide() } else { NSCursor.unhide() }
        }
        // Set every frame while the pointer is over the view: AppKit resets the cursor on its own
        // (window edges, other apps), and the view has no cursor rects to restore ours.
        if !hide && over { Self.nsCursor(cursor).set() }
    }

    private static func nsCursor(_ shape: CursorShape) -> NSCursor {
        switch shape {
        case .arrow, .hidden: .arrow
        case .iBeam: .iBeam
        case .pointingHand: .pointingHand
        case .resizeHorizontal: .resizeLeftRight
        case .resizeVertical: .resizeUpDown
        case .crosshair: .crosshair
        case .notAllowed: .operationNotAllowed
        }
    }

    func requestClose() {
        shouldClose = true
    }

    func destroy() {
        applyCursor(.arrow, captured: false)
        window.delegate = nil
        window.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        shouldClose = true
        return false  // The engine closes the window after shutting the renderer down.
    }

    @objc private func quitFromMenu(_ sender: Any?) {
        shouldClose = true
    }

    private func installMenu(appName: String) {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        let quit = NSMenuItem(title: "Quit \(appName)", action: #selector(quitFromMenu(_:)), keyEquivalent: "q")
        quit.target = self
        appMenu.addItem(quit)
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    // Virtual key codes (kVK_* from Carbon's Events.h).
    private static let keyMap: [UInt16: Key] = [
        0: .a, 11: .b, 8: .c, 2: .d, 14: .e, 3: .f, 5: .g, 4: .h, 34: .i, 38: .j, 40: .k, 37: .l, 46: .m,
        45: .n, 31: .o, 35: .p, 12: .q, 15: .r, 1: .s, 17: .t, 32: .u, 9: .v, 13: .w, 7: .x, 16: .y, 6: .z,
        29: .num0, 18: .num1, 19: .num2, 20: .num3, 21: .num4, 23: .num5, 22: .num6, 26: .num7, 28: .num8, 25: .num9,
        49: .space, 36: .enter, 53: .escape, 48: .tab, 51: .backspace, 50: .grave, 33: .leftBracket, 30: .rightBracket,
        122: .f1, 120: .f2, 99: .f3, 118: .f4, 96: .f5, 97: .f6, 98: .f7, 100: .f8, 101: .f9, 109: .f10,
        103: .f11, 111: .f12,
        117: .delete, 115: .home, 119: .end, 116: .pageUp, 121: .pageDown,
        123: .left, 124: .right, 125: .down, 126: .up,
    ]

    private static let modifierMap: [UInt16: (Key, NSEvent.ModifierFlags)] = [
        56: (.leftShift, .shift), 60: (.rightShift, .shift),
        59: (.leftControl, .control), 62: (.rightControl, .control),
        58: (.leftAlt, .option), 61: (.rightAlt, .option),
        55: (.leftSuper, .command), 54: (.rightSuper, .command),
    ]
}
#endif
