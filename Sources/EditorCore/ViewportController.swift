import Engine

/// One frame of input as the viewport sees it (built from `Input` by the host, or by tests).
public struct ViewportInput: Sendable {
    /// Window points.
    public var mousePosition: Vec2
    /// Window points; raw motion while the mouse is captured.
    public var mouseDelta: Vec2 = .zero
    public var pressed: Set<MouseButton> = []
    public var released: Set<MouseButton> = []
    public var down: Set<MouseButton> = []
    public var scroll: Vec2 = .zero
    public var modifiers: KeyModifiers = []
    /// Fly movement axes from the keyboard (x: D−A, y: E−Q, z: W−S), zero when the keyboard
    /// belongs to the UI.
    public var move: Vec3 = .zero
    public var dt: Float = 1.0 / 60
    /// The UI wants the pointer this frame (`UIContext.wantsPointer`): over a widget or dragging one.
    public var pointerOverUI = false

    public init(mousePosition: Vec2) {
        self.mousePosition = mousePosition
    }
}

/// Keeps a render target's pixel size in step with a panel: the size it should have for a
/// rectangle in points at a pixel scale (whole pixels, at least 1x1), and whether that is a
/// change, i.e. whether the target must be recreated.
public struct ViewportTargetSizer: Sendable, Equatable {
    public private(set) var width = 0
    public private(set) var height = 0
    /// How many times the size changed (the first sizing counts).
    public private(set) var resizeCount = 0

    public init() {}

    /// Returns the new pixel size when `rect` at `scale` needs a different one, else nil.
    /// An empty rect (a hidden panel) keeps the current size.
    public mutating func update(rect: UIRect, scale: Float) -> (width: Int, height: Int)? {
        guard rect.width > 0, rect.height > 0 else { return nil }
        let pixels = RenderTargetSizing.pixels(points: Vec2(rect.width, rect.height), scale: scale)
        let w = max(pixels.width, 1), h = max(pixels.height, 1)
        guard w != width || h != height else { return nil }
        width = w
        height = h
        resizeCount += 1
        return (w, h)
    }

    public var aspectRatio: Float { height > 0 ? Float(width) / Float(height) : 1 }
}

/// The scene viewport's interaction logic: offers the pointer to `tools` first, then drives
/// the `EditorCamera`:
///
/// - orbit: middle-drag, or Alt/Option + left-drag
/// - pan: Shift + middle-drag, or Alt/Option + Shift + left-drag
/// - zoom: wheel
/// - fly: hold the right button (the mouse is captured): look around, WASD move, Q/E down / up,
///   Shift faster
///
/// The viewport has the pointer while it is over it and the UI doesn't want it, or while a
/// gesture that started in it continues (anywhere). A tool that consumes a press keeps getting
/// the gesture's events until the release.
@MainActor
public final class ViewportController {
    public var camera: EditorCamera
    public var tools: [any ViewportTool] = []
    /// The viewport in window points (set by the host from the panel's frame every frame).
    public var rect = UIRect.zero
    /// Base fly speed in units per second (Shift: 4x).
    public var flySpeed: Float = 6

    public enum Gesture: Equatable, Sendable {
        case orbit, pan, fly
        /// A tool consumed the press of this button.
        case tool(MouseButton)
    }

    public private(set) var gesture: Gesture?
    private var gestureButton: MouseButton?
    private var capturingTool: (any ViewportTool)?

    public init(camera: EditorCamera = EditorCamera()) {
        self.camera = camera
    }

    /// Whether the mouse should be captured (fly mode).
    public var wantsMouseCapture: Bool { gesture == .fly }

    /// Whether the viewport has the pointer for `input` (see the type's docs).
    public func hasPointer(_ input: ViewportInput) -> Bool {
        gesture != nil || (!input.pointerOverUI && rect.contains(input.mousePosition))
    }

    /// Processes one frame. `context` builds the tool context for the current camera view.
    public func update(_ input: ViewportInput, context: (SceneView) -> ViewportToolContext) {
        let local = input.mousePosition - Vec2(rect.x, rect.y)
        let size = Vec2(rect.width, rect.height)
        let aspect = rect.height > 0 ? rect.width / rect.height : 1

        // A gesture in progress keeps going until its button is released.
        if let current = gesture, let button = gestureButton {
            let released = input.released.contains(button) || !input.down.contains(button)
            switch current {
            case .tool:
                let event = ViewportPointerEvent(position: local, viewportSize: size, phase: released ? .released : .dragged,
                                                 button: button, modifiers: input.modifiers)
                _ = capturingTool?.handlePointer(event, context: context(view(aspect: aspect)))
            case .orbit:
                camera.orbit(by: input.mouseDelta)
            case .pan:
                camera.pan(by: input.mouseDelta, viewportHeight: rect.height)
            case .fly:
                camera.look(by: input.mouseDelta)
                camera.fly(input.move, speed: flySpeed * (input.modifiers.contains(.shift) ? 4 : 1), dt: input.dt)
            }
            if released { endGesture() }
            return
        }

        guard hasPointer(input) else { return }
        let pressedButton = MouseButton.allCases.first { input.pressed.contains($0) }
        let event = ViewportPointerEvent(position: local, viewportSize: size, phase: pressedButton == nil ? .moved : .pressed,
                                         button: pressedButton, modifiers: input.modifiers)
        let toolContext = context(view(aspect: aspect))
        for tool in tools where tool.handlePointer(event, context: toolContext) {
            if let pressedButton {
                gesture = .tool(pressedButton)
                gestureButton = pressedButton
                capturingTool = tool
            }
            return
        }

        if input.scroll.y != 0 { camera.zoom(scroll: input.scroll.y) }
        guard let button = pressedButton else { return }
        let alt = input.modifiers.contains(.alt), shift = input.modifiers.contains(.shift)
        switch button {
        case .middle: gesture = shift ? .pan : .orbit
        case .left where alt: gesture = shift ? .pan : .orbit
        case .right: gesture = .fly
        default: return
        }
        gestureButton = button
    }

    /// Frames `bounds` (F).
    public func frame(_ bounds: Bounds) {
        camera.frame(bounds)
    }

    /// The camera's view for the current viewport size.
    public func view(aspect: Float, clearColor: Vec4 = Vec4(0.08, 0.09, 0.11, 1)) -> SceneView {
        camera.sceneView(aspect: aspect, clearColor: clearColor)
    }

    /// Drops a gesture in progress (e.g. the window lost focus).
    public func cancelGesture() { endGesture() }

    private func endGesture() {
        gesture = nil
        gestureButton = nil
        capturingTool = nil
    }
}
