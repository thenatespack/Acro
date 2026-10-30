#if canImport(AppKit)
import AppKit
import QuartzCore

/// Native macOS window whose content view is backed by a `CAMetalLayer`.
/// Events are pumped manually each frame (no `NSApp.run()`), like a classic game loop.
@MainActor
final class AppKitWindow: NSObject, PlatformWindow, NSWindowDelegate {
    let metalLayer = CAMetalLayer()
    private let window: NSWindow
    private let view: NSView
    private(set) var shouldClose = false

    init(title: String, width: Int, height: Int) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        view = NSView(frame: window.contentLayoutRect)
        super.init()

        // Layer-hosting view: assign the layer before enabling wantsLayer.
        view.layer = metalLayer
        view.wantsLayer = true
        metalLayer.contentsScale = window.backingScaleFactor

        window.title = title
        window.contentView = view
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
        while let event = NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true) {
            switch event.type {
            case .keyDown, .keyUp:
                if let key = Self.keyMap[event.keyCode] {
                    input.setKey(key, down: event.type == .keyDown)
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
            default: break
            }
            NSApp.sendEvent(event)
        }

        let p = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        input.mousePosition = Vec2(Float(p.x), Float(view.bounds.height - p.y))

        if !window.isKeyWindow { input.releaseAll() }
        metalLayer.contentsScale = window.backingScaleFactor
    }

    func requestClose() {
        shouldClose = true
    }

    func destroy() {
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
        49: .space, 36: .enter, 53: .escape, 48: .tab, 51: .backspace, 50: .grave,
        122: .f1, 120: .f2, 99: .f3, 118: .f4, 96: .f5, 97: .f6, 98: .f7, 100: .f8, 101: .f9, 109: .f10,
        103: .f11, 111: .f12,
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
