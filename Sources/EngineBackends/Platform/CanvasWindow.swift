#if canImport(JavaScriptKit)
import JavaScriptKit
import EngineCore
import EngineGraphics

/// The browser's "window": an HTML canvas the page created (WebAssembly builds).
///
/// DOM events are queued by JS listeners as they arrive and replayed into `Input` in
/// `pollEvents(into:)`, as GLFW queues OS events until `glfwPollEvents`. Keyboard events are
/// listened for on the page's `window` (so the canvas needn't have keyboard focus), mouse
/// presses on the canvas, and moves and releases on `window` (drags that leave the canvas keep
/// reporting). Events aimed at a form field (`<input>`, `<textarea>`, editable content) are
/// left to it.
///
/// Sizes: window points are CSS pixels. `framebufferSize` is the canvas's CSS size times
/// `devicePixelRatio`, checked every poll; the canvas's `width` / `height` attributes are set
/// to match. The page sizes the canvas with CSS (`width: 100vw; height: 100vh`, say): its
/// attributes are the drawing buffer, so an unstyled canvas would grow every frame.
///
/// Capturing the mouse uses the Pointer Lock API, which browsers only grant in a user gesture,
/// so a capture is requested on the next click or key press in the page. While it is pending
/// the cursor is hidden and motion is reported raw as usual. When the user ends the lock
/// (Esc, switching tabs) the engine's capture ends too.
@MainActor
package final class CanvasWindow: PlatformWindow {
    /// The `<canvas>` element.
    package let canvas: JSObject

    /// A DOM event, with the values `pollEvents` needs copied out of it.
    private enum Event {
        case key(code: String, key: String, down: Bool, isRepeat: Bool, modifiers: KeyModifiers)
        case move(clientX: Float, clientY: Float, movementX: Float, movementY: Float)
        case button(Int, down: Bool, clientX: Float, clientY: Float)
        case wheel(deltaX: Double, deltaY: Double, mode: Int)
        case focus(Bool)
    }

    private var events: [Event] = []
    private var listeners: [(target: JSObject, type: String, closure: JSClosure, capture: Bool)] = []
    private let document: JSObject
    private let global = JSObject.global

    private var currentTitle: String
    private var requestedCloseReason: String?
    package private(set) var shouldClose = false
    package var closeReason: String? { shouldClose ? requestedCloseReason ?? "the page asked to close" : nil }

    private var size: (width: Int, height: Int) = (1, 1)
    private var scale: Float = 1
    /// The canvas's position in the viewport (CSS pixels), read once per poll.
    private var origin = Vec2.zero
    private var lastPosition = Vec2.zero

    private var focused = true
    /// Whether the page had focus at the last poll (and was visible).
    package var isFocused: Bool { focused }
    /// Keys and buttons the page saw go down, so losing focus can release them.
    private var keysDown = Set<Key>()

    private var captured = false
    private var appliedCursor: CursorShape?
    /// The engine wants pointer lock and it hasn't been granted yet: asked for in the next gesture.
    private var wantsPointerLock = false
    /// The lock was granted during the current capture (so losing it means the user ended it).
    private var hadPointerLock = false

    private let gamepads = makePlatformGamepadSource()

    /// The canvas the page put on `globalThis.acro.canvas`.
    package convenience init() throws {
        guard let acro = JSObject.global.acro.object else {
            throw GraphicsError("globalThis.acro is not set: the page must set globalThis.acro = { canvas } before starting the engine")
        }
        guard let canvas = acro.canvas.object else {
            throw GraphicsError("globalThis.acro.canvas is not set: the page must put its <canvas> element there")
        }
        self.init(canvas: canvas)
    }

    /// Wraps `canvas`, an HTML `<canvas>` element sized by CSS.
    package init(canvas: JSObject) {
        self.canvas = canvas
        document = JSObject.global.document.object!
        currentTitle = document.title.string ?? ""
        // Focusable, so clicking it takes focus away from other elements on the page; no outline.
        if canvas.getAttribute!("tabindex").isNull { canvas.tabIndex = .number(0) }
        canvas.style.object?.outline = .string("none")
        // The browser's touch gestures (panning, zooming) would steal pointer events.
        canvas.style.object?.touchAction = .string("none")
        focused = document.hasFocus!().boolean ?? true
        updateSize()
        installListeners()
    }

    package var title: String {
        get { currentTitle }
        set {
            currentTitle = newValue
            document.title = .string(newValue)
        }
    }

    package var framebufferSize: (width: Int, height: Int) { size }
    package var contentScale: Float { scale }

    /// Whether the page holds a pointer lock on the canvas.
    package var hasPointerLock: Bool {
        guard let element = document.pointerLockElement.object else { return false }
        return element == canvas
    }

    /// Reads the canvas's CSS size and the device pixel ratio, and resizes the drawing buffer
    /// (the canvas's `width` / `height`) when they changed.
    private func updateSize() {
        let ratio = Float(global.devicePixelRatio.number ?? 1)
        scale = ratio > 0 ? ratio : 1
        let rect = canvas.getBoundingClientRect!().object!
        origin = Vec2(Float(rect.left.number ?? 0), Float(rect.top.number ?? 0))
        let cssWidth = Float(rect.width.number ?? 0), cssHeight = Float(rect.height.number ?? 0)
        let width = max(1, Int((cssWidth * scale).rounded()))
        let height = max(1, Int((cssHeight * scale).rounded()))
        if canvas.width.number.map(Int.init) != width { canvas.width = .number(Double(width)) }
        if canvas.height.number.map(Int.init) != height { canvas.height = .number(Double(height)) }
        size = (width, height)
    }

    package func pollEvents(into input: Input) {
        updateSize()
        let queued = events
        events.removeAll(keepingCapacity: true)
        for event in queued { replay(event, into: input) }
        if captured, hadPointerLock, !hasPointerLock {
            // The user ended the lock (Esc, or the browser took it away): end the capture too,
            // as losing focus does. The game asks again to get it back.
            input.isMouseCaptured = false
            hadPointerLock = false
            wantsPointerLock = false
        }
        if !captured { input.mousePosition = lastPosition }
        input.setWindowFocused(focused)
        input.updateGamepads(gamepads?.snapshots() ?? [])
    }

    private func replay(_ event: Event, into input: Input) {
        switch event {
        case .key(let code, let key, let down, let isRepeat, let modifiers):
            guard let engineKey = WebInputMapping.key(forCode: code) else {
                // A key the engine has no case for can still type text ("." or "é").
                if down, let text = WebInputMapping.typedText(key: key, modifiers: modifiers) { input.commitText(text) }
                return
            }
            if down {
                keysDown.insert(engineKey)
                input.setKey(engineKey, down: true)
                input.recordKeyPress(engineKey, modifiers: modifiers, isRepeat: isRepeat)
                input.textKeyEvent(engineKey, modifiers: modifiers, isRepeat: isRepeat)
                if let text = WebInputMapping.typedText(key: key, modifiers: modifiers) { input.commitText(text) }
            } else {
                keysDown.remove(engineKey)
                input.setKey(engineKey, down: false)
            }
        case .move(let clientX, let clientY, let movementX, let movementY):
            lastPosition = Vec2(clientX, clientY) - origin
            input.addMouseMotion(Vec2(movementX, movementY))
        case .button(let index, let down, let clientX, let clientY):
            lastPosition = Vec2(clientX, clientY) - origin
            if !captured { input.mousePosition = lastPosition }
            if let button = WebInputMapping.mouseButton(index) { input.setButton(button, down: down) }
        case .wheel(let deltaX, let deltaY, let mode):
            input.addScroll(WebInputMapping.scroll(deltaX: deltaX, deltaY: deltaY, mode: mode, pageHeight: Float(size.height) / scale))
        case .focus(let focused):
            self.focused = focused
            if !focused {
                // Key-ups that happen elsewhere never arrive: release everything now.
                keysDown.removeAll()
                input.releaseAll()
            }
        }
    }

    package func applyCursor(_ cursor: CursorShape, captured: Bool) {
        if captured != self.captured {
            self.captured = captured
            hadPointerLock = false
            if captured {
                wantsPointerLock = true
            } else {
                wantsPointerLock = false
                if hasPointerLock { _ = document.exitPointerLock!() }
            }
            appliedCursor = nil
        }
        let shape: CursorShape = captured ? .hidden : cursor
        guard shape != appliedCursor else { return }
        appliedCursor = shape
        canvas.style.object?.cursor = .string(WebInputMapping.cssCursor(shape))
    }

    /// In a user gesture (click, key press): asks for the pointer lock a capture is waiting for.
    private func userGesture() {
        guard wantsPointerLock, !hasPointerLock else { return }
        let result = canvas.requestPointerLock!()
        // Newer browsers return a Promise that rejects when the lock is refused: keep waiting
        // for the next gesture instead of reporting an unhandled rejection.
        if let promise = result.object, promise.then.function != nil {
            let ignore = JSClosure { _ in .undefined }
            _ = promise.catch!(ignore)
        }
    }

    package func requestClose(reason: String) {
        if !shouldClose { requestedCloseReason = reason }
        shouldClose = true
    }

    /// Sets the page's favicon to `image` (as a PNG data URL).
    package func setIcon(_ image: Image) {
        guard image.width > 0, image.height > 0 else { return }
        let canvas = document.createElement!("canvas").object!
        canvas.width = .number(Double(image.width))
        canvas.height = .number(Double(image.height))
        guard let context = canvas.getContext!("2d").object,
              let imageData = context.createImageData!(image.width, image.height).object else { return }
        _ = imageData.data.object!.set!(JSTypedArray<UInt8>(image.pixels))
        _ = context.putImageData!(imageData, 0, 0)
        let url = canvas.toDataURL!("image/png")
        var link = document.querySelector!("link[rel~='icon']").object
        if link == nil {
            link = document.createElement!("link").object
            link?.rel = .string("icon")
            _ = document.head.object?.appendChild!(link!)
        }
        link?.href = url
    }

    package func destroy() {
        for listener in listeners {
            _ = listener.target.removeEventListener!(listener.type, listener.closure, listener.capture)
            listener.closure.release()
        }
        listeners.removeAll()
        events.removeAll()
        if hasPointerLock { _ = document.exitPointerLock!() }
        canvas.style.object?.cursor = .string("")
    }

    // MARK: Listeners

    private func listen(_ target: JSObject, _ type: String, passive: Bool = true, capture: Bool = false,
                        _ handler: @escaping @MainActor (CanvasWindow, JSObject) -> Void) {
        let closure = JSClosure { [weak self] arguments in
            guard let event = arguments.first?.object else { return .undefined }
            // JS calls listeners on the one (main) thread the engine runs on.
            MainActor.assumeIsolated {
                if let self { handler(self, event) }
            }
            return .undefined
        }
        let options: JSObject = ["passive": .boolean(passive), "capture": .boolean(capture)]
        _ = target.addEventListener!(type, closure, options)
        listeners.append((target, type, closure, capture))
    }

    /// Whether `event` is aimed at a form field or editable element, which keeps its keys.
    private static func targetsEditable(_ event: JSObject) -> Bool {
        guard let target = event.target.object else { return false }
        if target.isContentEditable.boolean == true { return true }
        let tag = target.tagName.string?.uppercased() ?? ""
        return tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
    }

    private static func modifiers(_ event: JSObject) -> KeyModifiers {
        WebInputMapping.modifiers(shift: event.shiftKey.boolean ?? false, control: event.ctrlKey.boolean ?? false,
                                  alt: event.altKey.boolean ?? false, meta: event.metaKey.boolean ?? false)
    }

    private func installListeners() {
        let window = global
        for (type, down) in [("keydown", true), ("keyup", false)] {
            listen(window, type, passive: false) { this, event in
                guard !Self.targetsEditable(event) else { return }
                let code = event.code.string ?? ""
                let modifiers = Self.modifiers(event)
                if down {
                    if let key = WebInputMapping.key(forCode: code), WebInputMapping.preventsDefault(key, modifiers: modifiers) {
                        _ = event.preventDefault!()
                    }
                    // Esc isn't a user activation, and it ends a capture rather than starting one.
                    if code != "Escape" { this.userGesture() }
                }
                // Composing with an IME: the keys belong to the composition (see Known gaps).
                if event.isComposing.boolean == true { return }
                this.events.append(.key(code: code, key: event.key.string ?? "", down: down,
                                        isRepeat: event.repeat.boolean ?? false, modifiers: modifiers))
            }
        }
        listen(canvas, "mousedown", passive: false) { this, event in
            _ = event.preventDefault!()  // no text selection or drag start
            _ = this.canvas.focus!()
            this.userGesture()
            this.events.append(.button(Int(event.button.number ?? 0), down: true,
                                       clientX: Float(event.clientX.number ?? 0), clientY: Float(event.clientY.number ?? 0)))
        }
        listen(window, "mouseup") { this, event in
            this.events.append(.button(Int(event.button.number ?? 0), down: false,
                                       clientX: Float(event.clientX.number ?? 0), clientY: Float(event.clientY.number ?? 0)))
        }
        listen(window, "mousemove") { this, event in
            this.events.append(.move(clientX: Float(event.clientX.number ?? 0), clientY: Float(event.clientY.number ?? 0),
                                     movementX: Float(event.movementX.number ?? 0), movementY: Float(event.movementY.number ?? 0)))
        }
        listen(canvas, "wheel", passive: false) { this, event in
            _ = event.preventDefault!()  // the page doesn't scroll under the game
            this.events.append(.wheel(deltaX: event.deltaX.number ?? 0, deltaY: event.deltaY.number ?? 0,
                                      mode: Int(event.deltaMode.number ?? 0)))
        }
        listen(canvas, "contextmenu", passive: false) { _, event in _ = event.preventDefault!() }
        listen(window, "focus") { this, _ in this.events.append(.focus(true)) }
        listen(window, "blur") { this, _ in this.events.append(.focus(false)) }
        listen(document, "visibilitychange") { this, _ in
            let visible = this.document.visibilityState.string != "hidden"
            this.events.append(.focus(visible && (this.document.hasFocus!().boolean ?? true)))
        }
        listen(document, "pointerlockchange") { this, _ in
            if this.hasPointerLock {
                this.hadPointerLock = true
                this.wantsPointerLock = false
            }
        }
    }
}
#endif
