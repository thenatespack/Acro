import Foundation

/// Where copy / cut / paste go. `SystemClipboard` (the default) is the OS clipboard via
/// `Clipboard`; tests and sandboxes can use `MemoryClipboard`.
@MainActor
public protocol UIClipboard: AnyObject {
    var string: String? { get set }
}

@MainActor
public final class SystemClipboard: UIClipboard {
    public init() {}
    public var string: String? {
        get { Clipboard.string }
        set { Clipboard.string = newValue }
    }
}

@MainActor
public final class MemoryClipboard: UIClipboard {
    public var string: String?
    public init(_ string: String? = nil) { self.string = string }
}

/// Timings and counts of the last frame, for overlays and benchmarks.
public struct UIContextStats: Sendable, Equatable {
    /// Layout passes run since the context was created.
    public var layoutPasses = 0
    /// Seconds spent in the last layout pass.
    public var layoutTime: Double = 0
    /// Seconds spent in the last `draw(into:)`.
    public var paintTime: Double = 0
    /// Draw-list items the last `draw(into:)` added.
    public var paintedItems = 0
}

/// Owns a retained widget tree and runs it: once per frame `update` turns `Input` into
/// events (hover, click, capture, scroll, keys, text), and `draw(into:)` lays the tree out if
/// something changed and paints it into a draw list. It is opt-in: a game creates one, adds
/// widgets to `root`, and calls
///
///     ui.update(engine: engine, dt: dt)   // early in Game.update, before reading input itself
///     ui.draw(into: engine.ui)            // in Game.update or Game.render
///
/// Afterwards `wantsPointer` / `wantsKeyboard` say whether this frame's mouse / keyboard input
/// belonged to the UI, so camera controls and shortcuts can skip it.
///
/// Routing rules:
/// - Pointer down goes to the widget under the pointer and bubbles to its ancestors; the widget
///   that handles it captures the pointer until the button is released (drags keep going to
///   it outside its frame). A press that starts outside every widget belongs to the game until
///   all buttons are released (the UI ignores that drag even when it crosses widgets). A left
///   press there also clears focus.
/// - Clicking focuses the nearest focusable ancestor of the widget clicked (or clears focus).
/// - With an overlay (popup) open, a press outside the topmost overlay only closes it.
/// - Keys and text go to the focused widget and bubble. Unhandled Tab / Shift-Tab move focus;
///   unhandled Esc closes the topmost overlay, or else clears focus. With nothing focused and no
///   overlay open, the keyboard is left to the game entirely.
@MainActor
public final class UIContext {
    /// The tree's root. It fills the viewport and isn't hit-testable itself, so the game still
    /// gets clicks wherever no widget is.
    public let root: Widget
    public var theme: UITheme {
        didSet { invalidateAll() }
    }
    public var clipboard: UIClipboard = SystemClipboard()

    public private(set) var focusedWidget: Widget?
    /// The focus came from the keyboard (Tab), so the focus ring is drawn.
    public private(set) var focusVisible = false
    /// The deepest widget under the pointer (nil over empty space or while the game owns the pointer).
    public private(set) var hoveredWidget: Widget?
    /// The widget receiving drags until the button is released.
    public private(set) var capturedWidget: Widget?
    /// Popups and other widgets drawn above the tree, bottom to top.
    public private(set) var overlays: [Widget] = []
    /// Pointer position in window points.
    public private(set) var pointerPosition = Vec2(-1e6, -1e6)
    /// The pointer is over a widget, captured by one, or this frame's click/scroll went to the UI.
    public private(set) var wantsPointer = false
    /// A widget has focus, an overlay is open, or the UI handled a key this frame.
    public private(set) var wantsKeyboard = false
    /// The current IME composition while a text widget has focus.
    public private(set) var composition: Composition?
    /// Seconds of accumulated `dt` (drives caret blinking and double-click timing).
    public private(set) var time: Double = 0
    public private(set) var viewport = UIRect.zero
    /// Framebuffer pixels per point; layout snaps to this grid.
    public private(set) var scale: Float = 1
    public private(set) var stats = UIContextStats()

    /// A layout pass is pending.
    public internal(set) var layoutDirty = true
    /// Something visible changed since the last paint (informational: the draw list is rebuilt every frame).
    public internal(set) var paintDirty = true

    /// Max seconds and points between clicks that count as a double click.
    public var doubleClickInterval: Double = 0.4
    public var doubleClickDistance: Float = 4

    private var gameOwnsPointer = false
    private var captureButton: MouseButton?
    private var buttonsDown = Set<MouseButton>()
    private var lastClick: (time: Double, position: Vec2, button: MouseButton, count: Int)?
    private var pointerConsumed = false
    private var keyboardConsumed = false
    private var ownsTextInput = false
    private var modifiers: KeyModifiers = []

    public init(theme: UITheme = .dark()) {
        self.theme = theme
        root = Widget(name: "root")
        root.isHitTestable = false
        root.attach(to: self)
    }

    // MARK: Frame

    /// Processes this frame's engine input and lays out; call early in `Game.update`.
    public func update(engine: Engine, dt: Float) {
        update(input: engine.input, dt: dt, viewportSize: engine.ui.size, scale: engine.ui.scale)
    }

    /// Processes `input` for a viewport of `viewportSize` points at `scale` pixels per point.
    public func update(input: Input, dt: Float, viewportSize: Vec2, scale: Float) {
        time += Double(dt)
        setViewport(size: viewportSize, scale: scale)
        pointerConsumed = false
        keyboardConsumed = false
        modifiers = input.modifiers
        layoutIfNeeded()

        pointerMoved(to: input.mousePosition)
        for button in MouseButton.allCases {
            let pressed = input.wasPressed(button), released = input.wasReleased(button)
            if pressed && released && input.isDown(button) {
                pointerButton(button, down: false)  // released, then pressed again
                pointerButton(button, down: true)
            } else {
                if pressed { pointerButton(button, down: true) }
                if released { pointerButton(button, down: false) }
            }
        }
        if input.scrollDelta != .zero { scrolled(by: input.scrollDelta) }

        if ownsTextInput && input.isTextInputActive {
            for event in input.textEvents {
                switch event {
                case .text(let text): textEntered(text)
                case .key(let key): keyPressed(key)
                }
            }
        } else if !input.isTextInputActive {
            for key in input.keyPresses { keyPressed(key) }
        }
        syncTextInput(input)
        layoutIfNeeded()
    }

    /// Lets go of `input` before the context is dropped or hidden: clears focus and capture,
    /// closes overlays and stops text input if the UI started it.
    public func resign(input: Input) {
        for overlay in overlays.reversed() { dismissOverlay(overlay) }
        focus(nil)
        capturedWidget = nil
        captureButton = nil
        if ownsTextInput {
            input.stopTextInput()
            ownsTextInput = false
        }
        composition = nil
        wantsPointer = false
        wantsKeyboard = false
    }

    /// Lays out if needed, then paints the tree, the focus ring and the overlays into `list`.
    public func draw(into list: UIDrawList) {
        layoutIfNeeded()
        let start = ContinuousClock.now
        let itemsBefore = list.stats.items
        root.paint(list, theme: theme)
        if focusVisible, let focused = focusedWidget, focused.showsFocusRing, focused.isEffectivelyVisible {
            let w = theme.focusRingWidth
            let ring = UIRect(x: focused.frame.x - w - 1, y: focused.frame.y - w - 1,
                              width: focused.frame.width + 2 * (w + 1), height: focused.frame.height + 2 * (w + 1))
            list.strokeRect(ring, color: theme.focusRing, width: w, radii: UICornerRadii(theme.cornerRadius + w + 1))
        }
        for overlay in overlays { overlay.paint(list, theme: theme) }
        paintDirty = false
        stats.paintedItems = list.stats.items - itemsBefore
        stats.paintTime = Self.seconds(ContinuousClock.now - start)
    }

    /// Sets the area the root fills (points) and the pixel grid layout snaps to.
    public func setViewport(size: Vec2, scale: Float) {
        let rect = UIRect(x: 0, y: 0, width: size.x, height: size.y)
        if scale != self.scale {
            self.scale = scale
            invalidateAll()
        }
        if rect != viewport {
            viewport = rect
            layoutDirty = true
        }
    }

    /// Runs a layout pass if anything changed since the last one.
    public func layoutIfNeeded() {
        guard layoutDirty else { return }
        let start = ContinuousClock.now
        layoutDirty = false
        root.layout(in: viewport)
        for overlay in overlays { overlay.layout(in: overlay.overlayFrame(in: viewport)) }
        stats.layoutPasses += 1
        stats.layoutTime = Self.seconds(ContinuousClock.now - start)
        paintDirty = true
        // Frames moved: what is under the pointer may have changed.
        if capturedWidget == nil && !gameOwnsPointer { hoveredWidget = hitTest(pointerPosition) }
    }

    // MARK: Events (also usable directly, e.g. for synthetic input)

    /// The pointer moved to `position` (window points).
    public func pointerMoved(to position: Vec2) {
        let moved = position != pointerPosition
        pointerPosition = position
        if let captured = capturedWidget {
            if moved {
                _ = captured.isEffectivelyEnabled && captured.handleEvent(.pointerDrag(pointerEvent(button: captureButton ?? .left)))
            }
            wantsPointer = true
            return
        }
        if gameOwnsPointer {
            hoveredWidget = nil
            wantsPointer = false
            return
        }
        let hit = hitTest(position)
        if hit !== hoveredWidget { paintDirty = true }
        hoveredWidget = hit
        if moved, let hit { dispatch(.pointerMove(pointerEvent(button: .left)), from: hit) }
        wantsPointer = hit != nil || pointerConsumed
    }

    /// A mouse button went down or up at the current pointer position.
    public func pointerButton(_ button: MouseButton, down: Bool) {
        if down {
            buttonsDown.insert(button)
            if gameOwnsPointer || capturedWidget != nil { return }
            let hit = hitTest(pointerPosition)
            if hit == nil && overlays.isEmpty {
                // Clicking into the game ends editing, like clicking any non-focusable spot.
                if button == .left { focus(nil) }
                gameOwnsPointer = true
                hoveredWidget = nil
                wantsPointer = false
                return
            }
            pointerConsumed = true
            wantsPointer = true
            // A press outside the topmost overlay closes it (and does nothing else).
            var dismissed = false
            while let top = overlays.last, !(hit?.isDescendant(of: top) ?? false) {
                dismissOverlay(top)
                dismissed = true
            }
            if dismissed { return }
            guard let hit else { return }

            var count = 1
            if let last = lastClick, last.button == button, time - last.time <= doubleClickInterval,
               ((last.position - pointerPosition) * (last.position - pointerPosition)).sum() <= doubleClickDistance * doubleClickDistance {
                count = last.count + 1
            }
            lastClick = (time, pointerPosition, button, count)

            if button == .left {
                var node: Widget? = hit
                while let current = node, !isFocusable(current) { node = current.parent }
                focus(node)
            }
            let event = PointerEvent(position: pointerPosition, button: button, modifiers: modifiers, clickCount: count)
            if let handler = dispatch(.pointerDown(event), from: hit) {
                capturedWidget = handler
                captureButton = button
            }
            paintDirty = true
        } else {
            buttonsDown.remove(button)
            if gameOwnsPointer {
                if buttonsDown.isEmpty { gameOwnsPointer = false }
                return
            }
            guard let captured = capturedWidget, captureButton == button else { return }
            let count = lastClick?.count ?? 1
            capturedWidget = nil
            captureButton = nil
            pointerConsumed = true
            wantsPointer = true
            let event = PointerEvent(position: pointerPosition, button: button, modifiers: modifiers, clickCount: count)
            _ = captured.isEffectivelyEnabled && captured.handleEvent(.pointerUp(event))
            hoveredWidget = hitTest(pointerPosition)
            paintDirty = true
        }
    }

    /// Wheel / trackpad scrolling at the pointer (see `Input.scrollDelta`).
    public func scrolled(by delta: Vec2) {
        guard !gameOwnsPointer, let hit = capturedWidget ?? hitTest(pointerPosition) else { return }
        pointerConsumed = true
        wantsPointer = true
        dispatch(.scroll(delta: delta, position: pointerPosition), from: hit)
    }

    /// A key press or repeat. Ignored (left to the game) when nothing is focused and no overlay is open.
    public func keyPressed(_ key: KeyEvent) {
        guard focusedWidget != nil || !overlays.isEmpty else { return }
        keyboardConsumed = true
        if let focused = focusedWidget, dispatch(.key(key), from: focused) != nil { return }
        switch key.key {
        case .tab where focusedWidget != nil:
            if key.modifiers.contains(.shift) { focusPrevious() } else { focusNext() }
        case .escape:
            if let top = overlays.last { dismissOverlay(top) } else { focus(nil) }
        default:
            break
        }
    }

    /// Committed text for the focused widget.
    public func textEntered(_ text: String) {
        guard let focused = focusedWidget else { return }
        keyboardConsumed = true
        dispatch(.text(text), from: focused)
    }

    /// Delivers `event` to `target` and its ancestors until one handles it; returns that one.
    /// Disabled widgets are skipped.
    @discardableResult
    public func dispatch(_ event: UIEvent, from target: Widget) -> Widget? {
        var node: Widget? = target
        while let current = node {
            if current.isEffectivelyEnabled && current.handleEvent(event) {
                paintDirty = true
                return current
            }
            node = current.parent
        }
        return nil
    }

    // MARK: Focus

    /// Gives `widget` keyboard focus (nil clears it). `visible` draws the focus ring and
    /// scrolls the widget into view (keyboard navigation does both).
    public func focus(_ widget: Widget?, visible: Bool = false) {
        if let widget, !isFocusable(widget) { return }
        focusVisible = widget != nil && visible
        if visible, let widget { reveal(widget) }
        guard widget !== focusedWidget else { return }
        let old = focusedWidget
        focusedWidget = widget
        old?.focusChanged(false)
        widget?.focusChanged(true)
        paintDirty = true
    }

    /// Focusable widgets in tree order (depth first): what Tab cycles through.
    public var focusOrder: [Widget] {
        var result: [Widget] = []
        func visit(_ widget: Widget) {
            guard !widget.isHidden, widget.isEnabled else { return }
            if widget.acceptsFocus { result.append(widget) }
            for child in widget.children { visit(child) }
        }
        visit(root)
        return result
    }

    public func focusNext() { moveFocus(by: 1) }
    public func focusPrevious() { moveFocus(by: -1) }

    private func moveFocus(by step: Int) {
        let order = focusOrder
        guard !order.isEmpty else { return }
        let next: Int
        if let current = focusedWidget, let index = order.firstIndex(where: { $0 === current }) {
            next = (index + step + order.count) % order.count
        } else {
            next = step > 0 ? 0 : order.count - 1
        }
        focus(order[next], visible: true)
    }

    func isFocusable(_ widget: Widget) -> Bool {
        widget.acceptsFocus && widget.context === self && widget.isEffectivelyEnabled && widget.isEffectivelyVisible
    }

    /// Scrolls every scrolling ancestor so `widget` is visible.
    public func reveal(_ widget: Widget) {
        layoutIfNeeded()
        var node = widget.parent
        while let current = node {
            if current.scrollToReveal(widget.frame) { layoutIfNeeded() }
            node = current.parent
        }
    }

    // MARK: Overlays

    /// Shows `widget` above the tree (popups, menus, tooltips). It is placed by
    /// `overlayFrame(in:)` on every layout pass, and closed by a press outside it or Esc.
    public func presentOverlay(_ widget: Widget) {
        guard !overlays.contains(where: { $0 === widget }) else { return }
        widget.removeFromParent()
        widget.attach(to: self)
        overlays.append(widget)
        layoutDirty = true
        paintDirty = true
    }

    /// Removes an overlay (and the ones above it) and calls their `overlayDismissed`.
    public func dismissOverlay(_ widget: Widget) {
        guard let index = overlays.firstIndex(where: { $0 === widget }) else { return }
        let removed = overlays[index...]
        overlays.removeSubrange(index...)
        for overlay in removed.reversed() {
            widgetBecameUnavailable(overlay)
            overlay.attach(to: nil)
            overlay.overlayDismissed()
        }
        hoveredWidget = capturedWidget == nil ? hitTest(pointerPosition) : hoveredWidget
        paintDirty = true
    }

    // MARK: Queries

    /// The deepest widget at `point`, overlays first.
    public func hitTest(_ point: Vec2) -> Widget? {
        for overlay in overlays.reversed() {
            if let hit = overlay.hitTest(point) { return hit }
        }
        return root.hitTest(point)
    }

    func isHovered(_ widget: Widget) -> Bool {
        if let captured = capturedWidget { return captured === widget && captured.frame.contains(pointerPosition) }
        return hoveredWidget?.isDescendant(of: widget) ?? false
    }

    /// Called when a widget is hidden, disabled or removed: drops focus, capture and hover inside it.
    func widgetBecameUnavailable(_ widget: Widget) {
        if let focused = focusedWidget, focused.isDescendant(of: widget) { focus(nil) }
        if let captured = capturedWidget, captured.isDescendant(of: widget) {
            capturedWidget = nil
            captureButton = nil
        }
        if let hovered = hoveredWidget, hovered.isDescendant(of: widget) { hoveredWidget = nil }
    }

    // MARK: Text

    private struct TextKey: Hashable {
        var text: String
        var size: Float
        var font: ObjectIdentifier
    }
    private var textLayouts: [TextKey: TextLayout] = [:]

    /// A single-line layout of `text`, cached across frames (lists, trees and menus re-draw the
    /// same strings every frame; laying out applies kerning per glyph pair). The cache is
    /// cleared when it grows past a few thousand entries.
    public func textLayout(_ text: String, size: Float, font: Font? = nil) -> TextLayout {
        let font = font ?? theme.font
        let key = TextKey(text: text, size: size, font: ObjectIdentifier(font))
        if let layout = textLayouts[key] { return layout }
        if textLayouts.count >= 4096 { textLayouts.removeAll(keepingCapacity: true) }
        let layout = TextLayout(text, font: font, size: size)
        textLayouts[key] = layout
        return layout
    }

    // MARK: Helpers

    private func pointerEvent(button: MouseButton) -> PointerEvent {
        PointerEvent(position: pointerPosition, button: button, modifiers: modifiers, clickCount: lastClick?.count ?? 1)
    }

    /// Starts text input (with the caret rect) while a text widget has focus and stops it after.
    private func syncTextInput(_ input: Input) {
        if let focused = focusedWidget, focused.wantsTextInput, focused.isEffectivelyEnabled,
           ownsTextInput || !input.isTextInputActive {
            let r = focused.textInputCaretRect
            let rect = TextInputRect(x: r.x, y: r.y, width: r.width, height: r.height)
            if !ownsTextInput || input.textInputRect != rect { input.startTextInput(rect: rect) }
            ownsTextInput = true
            composition = input.composition
        } else if ownsTextInput {
            input.stopTextInput()
            ownsTextInput = false
            composition = nil
        }
        wantsKeyboard = focusedWidget != nil || !overlays.isEmpty || keyboardConsumed
    }

    /// Drops every cached measurement (theme or scale changed).
    private func invalidateAll() {
        func visit(_ widget: Widget) {
            widget.setNeedsLayout()
            for child in widget.children { visit(child) }
        }
        visit(root)
        for overlay in overlays { visit(overlay) }
        layoutDirty = true
    }

    private static func seconds(_ d: Duration) -> Double {
        let (s, attoseconds) = d.components
        return Double(s) + Double(attoseconds) * 1e-18
    }
}
