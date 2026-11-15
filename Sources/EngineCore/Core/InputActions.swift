import Foundation

/// Which part of a gamepad axis a source reads: the whole signed value, or just one direction
/// as a 0...1 strength (so a stick pushed left can be a button, or a trigger an "axis" half).
public enum AxisSide: String, Hashable, Sendable, Codable {
    case full, positive, negative
}

/// One physical input an action can be bound to: a key, a mouse button, a gamepad button or a
/// gamepad axis. Gamepad sources read every connected pad and take the strongest.
///
/// Encodes as a short string ("key.w", "mouse.left", "pad.south", "axis.leftStickX",
/// "axis.leftTrigger+", "axis.leftStickX-") so saved bindings are easy to read and edit.
public enum InputSource: Hashable, Sendable, Codable {
    case key(Key)
    case mouseButton(MouseButton)
    case gamepadButton(GamepadButton)
    case gamepadAxis(GamepadAxis, AxisSide = .full)

    /// The source's strength this frame: 0 or 1 for buttons and keys, the deadzoned value for
    /// axes (signed for `.full`, 0...1 for one `side`).
    @MainActor public func value(in input: Input) -> Float {
        switch self {
        case .key(let key): return input.isDown(key) ? 1 : 0
        case .mouseButton(let button): return input.isDown(button) ? 1 : 0
        case .gamepadButton(let button): return input.gamepads.contains { $0.isDown(button) } ? 1 : 0
        case .gamepadAxis(let axis, let side):
            var strongest: Float = 0
            for pad in input.gamepads where abs(pad.value(axis)) > abs(strongest) { strongest = pad.value(axis) }
            switch side {
            case .full: return strongest
            case .positive: return max(strongest, 0)
            case .negative: return max(-strongest, 0)
            }
        }
    }

    /// A short label for UI: "W", "Left Shift", "Left Mouse", "Pad South", "Left Trigger".
    public var displayName: String {
        switch self {
        case .key(let key): return Self.words(key.rawValue, dropping: "num", upperShort: true)
        case .mouseButton(let button): return Self.words(button.rawValue) + " Mouse"
        case .gamepadButton(let button): return "Pad " + Self.words(button.rawValue)
        case .gamepadAxis(let axis, let side):
            let suffix = side == .positive ? " +" : side == .negative ? " -" : ""
            return Self.words(axis.rawValue) + suffix
        }
    }

    private static func words(_ camel: String, dropping prefix: String = "", upperShort: Bool = false) -> String {
        var name = camel
        if !prefix.isEmpty, name.hasPrefix(prefix), name.count > prefix.count { name.removeFirst(prefix.count) }
        if upperShort, name.count == 1 || (name.hasPrefix("f") && Int(name.dropFirst()) != nil) { return name.uppercased() }
        var result = ""
        for (i, c) in name.enumerated() {
            if c.isUppercase { result += " " }
            result += i == 0 ? c.uppercased() : String(c)
        }
        return result
    }

    public init(from decoder: Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let source = Self.parse(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown input source \"\(text)\""))
        }
        self = source
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encoded)
    }

    var encoded: String {
        switch self {
        case .key(let key): "key.\(key.rawValue)"
        case .mouseButton(let button): "mouse.\(button.rawValue)"
        case .gamepadButton(let button): "pad.\(button.rawValue)"
        case .gamepadAxis(let axis, let side):
            "axis.\(axis.rawValue)" + (side == .positive ? "+" : side == .negative ? "-" : "")
        }
    }

    static func parse(_ text: String) -> InputSource? {
        guard let dot = text.firstIndex(of: ".") else { return nil }
        let kind = text[..<dot]
        var name = String(text[text.index(after: dot)...])
        switch kind {
        case "key": return Key(rawValue: name).map { .key($0) }
        case "mouse": return MouseButton(rawValue: name).map { .mouseButton($0) }
        case "pad": return GamepadButton(rawValue: name).map { .gamepadButton($0) }
        case "axis":
            var side = AxisSide.full
            if name.hasSuffix("+") { side = .positive; name.removeLast() } else if name.hasSuffix("-") { side = .negative; name.removeLast() }
            return GamepadAxis(rawValue: name).map { .gamepadAxis($0, side) }
        default: return nil
        }
    }
}

private func lengthSquared(_ v: Vec2) -> Float { v.x * v.x + v.y * v.y }

/// A binding of a 1D axis (-1...1): one source's value, or a negative / positive pair
/// (A / D, or two triggers).
public enum AxisBinding: Hashable, Sendable, Codable {
    case source(input: InputSource)
    case composite(negative: InputSource, positive: InputSource)

    @MainActor func value(in input: Input) -> Float {
        switch self {
        case .source(let source): source.value(in: input)
        case .composite(let negative, let positive): max(positive.value(in: input), 0) - max(negative.value(in: input), 0)
        }
    }
}

/// A binding of a 2D axis (x right, y up, length at most 1): a gamepad stick, or four sources
/// as a pad (WASD). A composite is normalized, so diagonals aren't faster.
public enum VectorBinding: Hashable, Sendable, Codable {
    case stick(stick: GamepadStick)
    case composite(up: InputSource, down: InputSource, left: InputSource, right: InputSource)

    @MainActor func value(in input: Input) -> Vec2 {
        switch self {
        case .stick(let stick):
            var strongest = Vec2.zero
            for pad in input.gamepads where lengthSquared(pad.stick(stick)) > lengthSquared(strongest) {
                strongest = pad.stick(stick)
            }
            return strongest
        case .composite(let up, let down, let left, let right):
            func strength(_ s: InputSource) -> Float { max(s.value(in: input), 0) }
            return Self.clamped(Vec2(strength(right) - strength(left), strength(up) - strength(down)))
        }
    }

    /// `v` scaled down to length 1 when it is longer.
    static func clamped(_ v: Vec2) -> Vec2 {
        let length = lengthSquared(v).squareRoot()
        return length > 1 ? v / length : v
    }
}

/// An action's name and what it is bound to. Any binding triggers it.
public struct NamedBindings<Binding: Hashable & Sendable & Codable>: Hashable, Sendable, Codable {
    public var name: String
    public var bindings: [Binding]

    public init(_ name: String, _ bindings: [Binding]) {
        self.name = name
        self.bindings = bindings
    }
}

/// Every binding of an `InputActions`, as plain data: Codable, so a game can save the player's
/// bindings and load them back (`json()` / `init(json:)`).
public struct InputBindings: Hashable, Sendable, Codable {
    /// Button actions (down / up with edges).
    public var buttons: [NamedBindings<InputSource>] = []
    /// 1D axes, -1...1.
    public var axes: [NamedBindings<AxisBinding>] = []
    /// 2D axes (vectors), x right and y up.
    public var vectors: [NamedBindings<VectorBinding>] = []

    public init() {}

    public init(json: Data) throws {
        self = try JSONDecoder().decode(InputBindings.self, from: json)
    }

    /// Pretty-printed JSON with stable key order.
    public func json() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

/// What a rebind changes: one binding of one action. `slot` is the index in the action's
/// binding list; for a button, `slot == count` appends a new binding.
public enum RebindTarget: Hashable, Sendable {
    /// A part of a composite binding (or the whole binding for `.whole`).
    public enum Part: Hashable, Sendable {
        case whole
        case negative, positive
        case up, down, left, right
    }

    case button(String, slot: Int)
    case axis(String, slot: Int, part: Part)
    case vector(String, slot: Int, part: Part)
}

/// Named actions and axes over keys, mouse buttons and gamepads, so game code asks for "jump" or
/// "move" instead of a key, and players can rebind them.
///
/// ```swift
/// var map = InputBindings()
/// map.buttons.append(.init("jump", [.key(.space), .gamepadButton(.south)]))
/// map.vectors.append(.init("move", [.composite(up: .key(.w), down: .key(.s), left: .key(.a), right: .key(.d)),
///                                    .stick(stick: .left)]))
/// let actions = InputActions(bindings: map)
/// // each frame:
/// actions.update(engine.input)
/// if actions.wasPressed("jump") { ... }
/// position += actions.vector("move") * speed * dt
/// ```
///
/// Call `update(_:)` once per frame, after the engine has polled input (in `Game.update`).
/// Edges (`wasPressed` / `wasReleased`) are relative to the previous `update`.
///
/// Runtime rebinding: `listen(for:)` waits for the next key, button or axis past `listenThreshold`
/// and assigns it (Esc cancels); `onRebind` reports it. Independent of the editor: it only reads `Input`.
@MainActor
public final class InputActions {
    public var bindings: InputBindings {
        didSet { reset() }
    }

    /// A button action counts as down when its strongest source reaches this (analog sources:
    /// triggers, sticks).
    public var pressThreshold: Float = 0.5
    /// How far an axis must move for `listen(for:)` to take it.
    public var listenThreshold: Float = 0.6
    /// Pressing this while listening cancels instead of binding it. nil to allow binding everything.
    public var cancelKey: Key? = .escape
    /// The rebind being waited for, if any.
    public private(set) var listeningTarget: RebindTarget?
    /// Called after a listened-for input has been assigned.
    public var onRebind: ((RebindTarget, InputSource) -> Void)?

    private var strengths: [String: Float] = [:]
    private var downNow = Set<String>()
    private var pressedNow = Set<String>()
    private var releasedNow = Set<String>()
    private var axisValues: [String: Float] = [:]
    private var vectorValues: [String: Vec2] = [:]
    /// The first `update` after `listen` only notes what is already held (the key that started
    /// listening mustn't bind itself).
    private var listenArmed = false
    private var activeAxisSources = Set<InputSource>()

    public init(bindings: InputBindings = InputBindings()) {
        self.bindings = bindings
    }

    // MARK: Queries

    /// A button action is down (any of its bindings is held).
    public func isPressed(_ name: String) -> Bool { downNow.contains(name) }
    /// It went down since the previous `update`.
    public func wasPressed(_ name: String) -> Bool { pressedNow.contains(name) }
    public func wasReleased(_ name: String) -> Bool { releasedNow.contains(name) }

    /// A 1D axis (-1...1), or a button's strength (0...1; analog for triggers). 0 if unknown.
    public func value(_ name: String) -> Float { axisValues[name] ?? strengths[name] ?? 0 }
    /// A 2D axis: x right, y up, length at most 1.
    public func vector(_ name: String) -> Vec2 { vectorValues[name] ?? .zero }

    /// Evaluates every action against this frame's input and advances rebinding.
    public func update(_ input: Input) {
        pressedNow.removeAll(keepingCapacity: true)
        releasedNow.removeAll(keepingCapacity: true)
        for entry in bindings.buttons {
            let strength = entry.bindings.map { abs($0.value(in: input)) }.max() ?? 0
            strengths[entry.name] = strength
            let down = strength >= pressThreshold
            if down != downNow.contains(entry.name) {
                if down {
                    downNow.insert(entry.name)
                    pressedNow.insert(entry.name)
                } else {
                    downNow.remove(entry.name)
                    releasedNow.insert(entry.name)
                }
            }
        }
        for entry in bindings.axes {
            var best: Float = 0
            for binding in entry.bindings {
                let v = binding.value(in: input)
                if abs(v) > abs(best) { best = v }
            }
            axisValues[entry.name] = min(max(best, -1), 1)
        }
        for entry in bindings.vectors {
            var best = Vec2.zero
            for binding in entry.bindings {
                let v = binding.value(in: input)
                if lengthSquared(v) > lengthSquared(best) { best = v }
            }
            vectorValues[entry.name] = VectorBinding.clamped(best)
        }
        if let target = listeningTarget { pollListening(target, input) }
    }

    private func reset() {
        strengths.removeAll()
        downNow.removeAll()
        pressedNow.removeAll()
        releasedNow.removeAll()
        axisValues.removeAll()
        vectorValues.removeAll()
    }

    // MARK: Rebinding

    /// Waits for the next key, mouse button, gamepad button or axis movement past `listenThreshold`
    /// that suits `target` (stick targets only take sticks, an axis target only axes), then assigns it.
    /// Returns false when the target doesn't exist. Whatever is held when this is called is
    /// ignored, and so is the next `update` (the one that was probably running when the
    /// key that triggered listening was pressed).
    @discardableResult
    public func listen(for target: RebindTarget) -> Bool {
        guard isValid(target) else { return false }
        listeningTarget = target
        listenArmed = false
        activeAxisSources.removeAll()
        return true
    }

    public func cancelListening() {
        listeningTarget = nil
    }

    /// Assigns `source` to `target` directly (what `listen(for:)` does once it has an input).
    /// Gamepad axes are converted to what the target takes: a whole axis for an axis target, a stick
    /// for a stick binding. Returns false when the target doesn't exist or the source doesn't suit it.
    @discardableResult
    public func rebind(_ target: RebindTarget, to source: InputSource) -> Bool {
        guard accepts(source, for: target) else { return false }
        switch target {
        case .button(let name, let slot):
            guard let i = bindings.buttons.firstIndex(where: { $0.name == name }), slot >= 0, slot <= bindings.buttons[i].bindings.count
            else { return false }
            if slot == bindings.buttons[i].bindings.count {
                bindings.buttons[i].bindings.append(source)
            } else {
                bindings.buttons[i].bindings[slot] = source
            }
        case .axis(let name, let slot, let part):
            guard let i = bindings.axes.firstIndex(where: { $0.name == name }), bindings.axes[i].bindings.indices.contains(slot)
            else { return false }
            switch (bindings.axes[i].bindings[slot], part) {
            case (_, .whole):
                guard case .gamepadAxis(let axis, _) = source else { return false }
                bindings.axes[i].bindings[slot] = .source(input: .gamepadAxis(axis, .full))
            case (.composite(_, let positive), .negative):
                bindings.axes[i].bindings[slot] = .composite(negative: source, positive: positive)
            case (.composite(let negative, _), .positive):
                bindings.axes[i].bindings[slot] = .composite(negative: negative, positive: source)
            default: return false
            }
        case .vector(let name, let slot, let part):
            guard let i = bindings.vectors.firstIndex(where: { $0.name == name }), bindings.vectors[i].bindings.indices.contains(slot)
            else { return false }
            switch (bindings.vectors[i].bindings[slot], part) {
            case (_, .whole):
                guard case .gamepadAxis(let axis, _) = source, let stick = Self.stick(of: axis) else { return false }
                bindings.vectors[i].bindings[slot] = .stick(stick: stick)
            case (.composite(_, let down, let left, let right), .up):
                bindings.vectors[i].bindings[slot] = .composite(up: source, down: down, left: left, right: right)
            case (.composite(let up, _, let left, let right), .down):
                bindings.vectors[i].bindings[slot] = .composite(up: up, down: source, left: left, right: right)
            case (.composite(let up, let down, _, let right), .left):
                bindings.vectors[i].bindings[slot] = .composite(up: up, down: down, left: source, right: right)
            case (.composite(let up, let down, let left, _), .right):
                bindings.vectors[i].bindings[slot] = .composite(up: up, down: down, left: left, right: source)
            default: return false
            }
        }
        return true
    }

    /// The source currently bound at `target`, if it exists (a whole stick reports its X axis).
    public func source(at target: RebindTarget) -> InputSource? {
        switch target {
        case .button(let name, let slot):
            return bindings.buttons.first { $0.name == name }.flatMap { $0.bindings.indices.contains(slot) ? $0.bindings[slot] : nil }
        case .axis(let name, let slot, let part):
            guard let list = bindings.axes.first(where: { $0.name == name })?.bindings, list.indices.contains(slot) else { return nil }
            switch (list[slot], part) {
            case (.source(let s), .whole): return s
            case (.composite(let n, _), .negative): return n
            case (.composite(_, let p), .positive): return p
            default: return nil
            }
        case .vector(let name, let slot, let part):
            guard let list = bindings.vectors.first(where: { $0.name == name })?.bindings, list.indices.contains(slot) else { return nil }
            switch (list[slot], part) {
            case (.stick(let stick), .whole): return .gamepadAxis(stick == .left ? .leftStickX : .rightStickX, .full)
            case (.composite(let s, _, _, _), .up): return s
            case (.composite(_, let s, _, _), .down): return s
            case (.composite(_, _, let s, _), .left): return s
            case (.composite(_, _, _, let s), .right): return s
            default: return nil
            }
        }
    }

    private func isValid(_ target: RebindTarget) -> Bool {
        if case .button(let name, let slot) = target {
            guard let entry = bindings.buttons.first(where: { $0.name == name }) else { return false }
            return slot >= 0 && slot <= entry.bindings.count
        }
        return source(at: target) != nil
    }

    private func accepts(_ source: InputSource, for target: RebindTarget) -> Bool {
        switch target {
        case .button: return true
        case .axis(_, _, let part), .vector(_, _, let part):
            guard part == .whole else { return true }
            guard case .gamepadAxis(let axis, _) = source else { return false }
            if case .vector = target { return Self.stick(of: axis) != nil }
            return true
        }
    }

    private static func stick(of axis: GamepadAxis) -> GamepadStick? {
        switch axis {
        case .leftStickX, .leftStickY: .left
        case .rightStickX, .rightStickY: .right
        case .leftTrigger, .rightTrigger: nil
        }
    }

    private func pollListening(_ target: RebindTarget, _ input: Input) {
        let axesNow = Self.axesPastThreshold(input, listenThreshold)
        defer { activeAxisSources = axesNow }
        guard listenArmed else {
            listenArmed = true
            return
        }
        if let cancelKey, input.wasPressed(cancelKey) {
            listeningTarget = nil
            return
        }
        var captured: InputSource?
        for key in Key.allCases where input.wasPressed(key) && key != cancelKey {
            captured = .key(key)
            break
        }
        if captured == nil {
            for button in MouseButton.allCases where input.wasPressed(button) {
                captured = .mouseButton(button)
                break
            }
        }
        if captured == nil {
            outer: for pad in input.gamepads {
                for button in GamepadButton.allCases where pad.wasPressed(button) {
                    captured = .gamepadButton(button)
                    break outer
                }
            }
        }
        if captured == nil {
            // A direction that just went past the threshold, in a stable order.
            search: for axis in GamepadAxis.allCases {
                for side in [AxisSide.positive, .negative] {
                    let candidate = InputSource.gamepadAxis(axis, side)
                    if axesNow.contains(candidate), !activeAxisSources.contains(candidate), accepts(candidate, for: target) {
                        captured = candidate
                        break search
                    }
                }
            }
        }
        guard let source = captured, rebind(target, to: source) else { return }
        listeningTarget = nil
        onRebind?(target, source)
    }

    private static func axesPastThreshold(_ input: Input, _ threshold: Float) -> Set<InputSource> {
        var result = Set<InputSource>()
        for axis in GamepadAxis.allCases {
            for side in [AxisSide.positive, .negative] {
                let source = InputSource.gamepadAxis(axis, side)
                if source.value(in: input) >= threshold { result.insert(source) }
            }
        }
        return result
    }
}
