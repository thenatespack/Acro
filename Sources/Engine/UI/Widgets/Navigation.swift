import Foundation

// Directional (gamepad / arrow key) navigation between focusable widgets.
//
// With `UIContext.directionalNavigation` on (or a `UIContext.gamepadNavigation` set), an arrow
// key the focused widget doesn't use moves focus to the nearest focusable widget in that
// direction (`UINavigation.nearest`), unless the widget has an explicit target
// (`Widget.setNavigation(_:to:)`). The search stays inside the focused widget's navigation
// scope: the nearest ancestor with `isNavigationScope`, else the topmost overlay or the root.
// Gamepads come in through `UINavigationInput`, which turns an `InputActions` map into the
// same key events: D-pad / left stick are arrows (repeating while held), A is Enter, B is Esc
// and the shoulder buttons are Ctrl-Page Up / Down, which `TabView` takes to switch tabs.

/// A direction of focus movement (y down, like the UI).
public enum UINavDirection: Sendable, Hashable, CaseIterable {
    case up, down, left, right

    /// The arrow key's direction, or nil for other keys.
    public init?(key: Key) {
        switch key {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        default: return nil
        }
    }

    public var key: Key {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        }
    }

    /// The dominant direction of a stick-style vector (x right, y up), or nil inside `threshold`.
    public init?(vector: Vec2, threshold: Float = 0.5) {
        guard max(abs(vector.x), abs(vector.y)) >= threshold else { return nil }
        if abs(vector.x) > abs(vector.y) {
            self = vector.x > 0 ? .right : .left
        } else {
            self = vector.y > 0 ? .up : .down
        }
    }
}

/// The spatial part of directional navigation, as pure functions (for tests).
public enum UINavigation {
    /// The index of the rectangle in `candidates` that moving `direction` from `from` should
    /// reach, or nil when none lies that way. A candidate counts when its center is beyond
    /// `from`'s center along the direction. Candidates that overlap `from` across the
    /// direction (the same row for left / right, the same column for up / down) win over the
    /// others; among each group the smallest gap along the direction plus half the offset
    /// between centers across it wins, then the first in order.
    public static func nearest(from: UIRect, direction: UINavDirection, candidates: [UIRect]) -> Int? {
        var best: (index: Int, overlaps: Bool, score: Float)?
        for (index, rect) in candidates.enumerated() {
            guard let (overlaps, score) = score(from: from, to: rect, direction: direction) else { continue }
            if let current = best {
                if current.overlaps && !overlaps { continue }
                if current.overlaps == overlaps && score >= current.score { continue }
            }
            best = (index, overlaps, score)
        }
        return best?.index
    }

    /// Whether `to` overlaps `from` across `direction`, and its distance score; nil when it isn't that way.
    static func score(from: UIRect, to: UIRect, direction: UINavDirection) -> (overlaps: Bool, score: Float)? {
        let horizontal = direction == .left || direction == .right
        let sign: Float = direction == .right || direction == .down ? 1 : -1
        let (fromCenter, toCenter) = (from.center, to.center)
        let along = horizontal ? (toCenter.x - fromCenter.x) * sign : (toCenter.y - fromCenter.y) * sign
        guard along > 0.5 else { return nil }
        // Gap between the facing edges (0 when they overlap along the direction).
        let gap: Float
        switch direction {
        case .right: gap = max(0, to.x - from.maxX)
        case .left: gap = max(0, from.x - to.maxX)
        case .down: gap = max(0, to.y - from.maxY)
        case .up: gap = max(0, from.y - to.maxY)
        }
        let crossGap = horizontal ? max(0, max(to.y, from.y) - min(to.maxY, from.maxY))
            : max(0, max(to.x, from.x) - min(to.maxX, from.maxX))
        let crossOffset = horizontal ? abs(toCenter.y - fromCenter.y) : abs(toCenter.x - fromCenter.x)
        return (crossGap <= 0, gap + 2 * crossGap + 0.5 * crossOffset)
    }
}

/// Key-repeat for a held direction: fires once when a direction starts, then after `delay`
/// seconds every `interval` seconds while it stays held. Changing direction starts over.
public struct UINavigationRepeater: Sendable, Equatable {
    public var delay: Double = 0.4
    public var interval: Double = 0.09
    public private(set) var held: UINavDirection?
    private var heldTime: Double = 0
    private var nextFire: Double = 0

    public init(delay: Double = 0.4, interval: Double = 0.09) {
        self.delay = delay
        self.interval = interval
    }

    /// Advances by `dt` with `direction` held (nil: released). Returns how many times the
    /// direction fires this frame and whether they are repeats; 0 when nothing fires.
    public mutating func update(direction: UINavDirection?, dt: Double) -> (direction: UINavDirection, count: Int, isRepeat: Bool)? {
        guard let direction else {
            held = nil
            return nil
        }
        if direction != held {
            held = direction
            heldTime = 0
            nextFire = delay
            return (direction, 1, false)
        }
        heldTime += dt
        var count = 0
        while heldTime >= nextFire && count < 8 {
            count += 1
            nextFire += max(interval, 0.01)
        }
        return count > 0 ? (direction, count, true) : nil
    }
}

/// Turns gamepad (or any `InputActions`) input into the key events widgets already understand,
/// for `UIContext.gamepadNavigation`. The actions it reads:
/// - `ui.move` (vector): D-pad and left stick by default. Arrows, with `repeater` timing.
/// - `ui.accept` (A / south): Enter, which activates buttons, toggles and selectors.
/// - `ui.back` (B / east): Escape, which closes popups and dialogs and pops `MenuStack` screens.
/// - `ui.nextTab` / `ui.previousTab` (shoulders): Ctrl-Page Down / Up, which switches `TabView` tabs.
///
/// The default bindings are gamepad-only, because the keyboard already reaches the UI as key
/// events (with the OS's key repeat). Rebind through `actions.bindings`.
@MainActor
public final class UINavigationInput {
    public let actions: InputActions
    public var repeater = UINavigationRepeater()

    public init(bindings: InputBindings = UINavigationInput.defaultBindings) {
        actions = InputActions(bindings: bindings)
    }

    public static var defaultBindings: InputBindings {
        var map = InputBindings()
        map.vectors.append(.init("ui.move", [
            .composite(up: .gamepadButton(.dpadUp), down: .gamepadButton(.dpadDown),
                       left: .gamepadButton(.dpadLeft), right: .gamepadButton(.dpadRight)),
            .stick(stick: .left),
        ]))
        map.buttons.append(.init("ui.accept", [.gamepadButton(.south)]))
        map.buttons.append(.init("ui.back", [.gamepadButton(.east)]))
        map.buttons.append(.init("ui.nextTab", [.gamepadButton(.rightShoulder)]))
        map.buttons.append(.init("ui.previousTab", [.gamepadButton(.leftShoulder)]))
        return map
    }

    /// Updates the actions from `input` and returns this frame's synthetic key events.
    public func events(input: Input, dt: Float) -> [KeyEvent] {
        actions.update(input)
        return events(dt: dt)
    }

    /// This frame's key events from the actions' current state (call after `actions.update`).
    public func events(dt: Float) -> [KeyEvent] {
        var events: [KeyEvent] = []
        if let fired = repeater.update(direction: UINavDirection(vector: actions.vector("ui.move")), dt: Double(dt)) {
            for _ in 0..<fired.count { events.append(KeyEvent(key: fired.direction.key, isRepeat: fired.isRepeat)) }
        }
        if actions.wasPressed("ui.accept") { events.append(KeyEvent(key: .enter)) }
        if actions.wasPressed("ui.back") { events.append(KeyEvent(key: .escape)) }
        if actions.wasPressed("ui.nextTab") { events.append(KeyEvent(key: .pageDown, modifiers: .control)) }
        if actions.wasPressed("ui.previousTab") { events.append(KeyEvent(key: .pageUp, modifiers: .control)) }
        return events
    }
}
