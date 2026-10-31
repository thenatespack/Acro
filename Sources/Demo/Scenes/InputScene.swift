import Engine
import Foundation

/// Action-mapped input (`InputActions`) and gamepads. A cube moves on the floor with the `move`
/// action (WASD, arrows or the left stick: one 2D axis, normalized), spins with `spin`, speeds up
/// with `boost` and flashes with `flash`. The panels show the first gamepad (sticks, triggers,
/// buttons; "no gamepad" otherwise) and the actions with their bindings. C selects a binding, R
/// rebinds it to the next key, button or axis you move (Esc cancels), B restores the defaults.
///
/// The scene fixes its camera (so WASD / arrows move the cube instead of orbiting) and keeps the
/// global shortcuts off while it listens for a binding. Under ENGINE_SCREENSHOT the engine feeds
/// the game no input at all, so the image never depends on the pads that are plugged in;
/// DEMO_FAKE_GAMEPAD=1 shows a synthetic pad instead (to check the visualizer).
final class InputScene: DemoScene {
    static let name = "input"
    static let summary = "action maps (WASD / arrows / left stick), gamepad visualizer, runtime rebinding"

    private let renderer: Renderer
    private let actions = InputActions(bindings: InputScene.defaultBindings)
    private var position = Vec3.zero
    private var spin: Float = 0
    private var flash: Float = 0
    private var pad: Gamepad?
    private var selected = 0
    private let fakePad: Gamepad? = {
        guard ProcessInfo.processInfo.environment["DEMO_FAKE_GAMEPAD"] != nil else { return nil }
        let pad = Gamepad(id: 99, name: "Synthetic pad")
        pad.apply(GamepadSnapshot(id: 99, name: "Synthetic pad", buttons: [.south, .dpadLeft, .rightShoulder, .start],
                                  leftStick: Vec2(0.6, -0.5), rightStick: Vec2(-0.3, 0.8), leftTrigger: 0.2, rightTrigger: 0.85))
        return pad
    }()

    private static let panel = UIColor(hex: 0x1d2330).withAlpha(0.92)
    private static let line = UIColor(hex: 0x39425a)
    private static let accent = UIColor(hex: 0x3478f6)
    private static let warm = UIColor(hex: 0xf5a623)
    private static let dim = UIColor(hex: 0x8791a8)

    static var defaultBindings: InputBindings {
        var map = InputBindings()
        map.vectors.append(.init("move", [
            .composite(up: .key(.w), down: .key(.s), left: .key(.a), right: .key(.d)),
            .composite(up: .key(.up), down: .key(.down), left: .key(.left), right: .key(.right)),
            .stick(stick: .left),
        ]))
        map.axes.append(.init("spin", [
            .composite(negative: .key(.j), positive: .key(.k)),
            .source(input: .gamepadAxis(.rightStickX, .full)),
        ]))
        map.buttons.append(.init("boost", [.key(.leftShift), .gamepadButton(.leftShoulder), .gamepadAxis(.rightTrigger, .positive)]))
        map.buttons.append(.init("flash", [.key(.f), .gamepadButton(.south)]))
        return map
    }

    /// The bindings C steps through and R rebinds, with their row labels.
    private static let rows: [(label: String, target: RebindTarget)] = [
        ("boost (keyboard)", .button("boost", slot: 0)),
        ("boost (button)", .button("boost", slot: 1)),
        ("flash (keyboard)", .button("flash", slot: 0)),
        ("flash (button)", .button("flash", slot: 1)),
        ("spin left", .axis("spin", slot: 0, part: .negative)),
        ("spin right", .axis("spin", slot: 0, part: .positive)),
        ("move up (WASD)", .vector("move", slot: 0, part: .up)),
        ("move down (WASD)", .vector("move", slot: 0, part: .down)),
        ("move left (WASD)", .vector("move", slot: 0, part: .left)),
        ("move right (WASD)", .vector("move", slot: 0, part: .right)),
    ]

    init(renderer: Renderer) throws {
        self.renderer = renderer
    }

    var lighting: Lighting { Lighting(direction: Vec3(0.3, 0.9, 0.6), shadowExtent: 16) }
    var wantsKeyboard: Bool { actions.listeningTarget != nil }
    var status: String { actions.listeningTarget != nil ? "press a key or button" : "" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        ViewCamera(eye: Vec3(0, 16, 12), target: Vec3(0, 0, 1))
    }

    func update(input: Input, dt: Float, time: Float) {
        pad = fakePad ?? input.gamepad
        actions.update(input)
        if actions.listeningTarget == nil {
            if input.wasPressed(.c) { selected = (selected + 1) % Self.rows.count }
            if input.wasPressed(.r) { actions.listen(for: Self.rows[selected].target) }
            if input.wasPressed(.b) { actions.bindings = Self.defaultBindings }
        }
        let move = actions.vector("move")
        let speed: Float = actions.isPressed("boost") ? 14 : 7
        position.x = min(max(position.x + move.x * speed * dt, -10), 10)
        position.z = min(max(position.z - move.y * speed * dt, -6), 8)
        spin += actions.value("spin") * 3 * dt
        flash = actions.wasPressed("flash") ? 0.3 : max(flash - dt, 0)
    }

    private var cubes: [Instance] {
        let tint = Vec3(0.95, 0.55, 0.15) + (Vec3(1, 1, 1) - Vec3(0.95, 0.55, 0.15)) * (flash / 0.3)
        let posts = [(-11.0, -7.0), (11, -7), (-11, 9), (11, 9)].map { x, z in
            Instance(.trs(Vec3(Float(x), 0.8, Float(z)), scale: Vec3(0.4, 0.8, 0.4)), color: Vec3(0.3, 0.45, 0.8))
        }
        return posts + [Instance(.trs(position + Vec3(0, 0.9, 0), angle: spin, scale: Vec3(repeating: 0.9)), color: tint)]
    }

    func drawShadowCasters(_ pass: RenderPass) {
        renderer.draw(pass, renderer.cube, cubes)
    }

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(try renderer.litPipeline())
        renderer.draw(pass, renderer.cube, [floorInstance(halfSize: 13)])
        renderer.draw(pass, renderer.cube, cubes)
    }

    // MARK: UI

    func drawUI(_ ui: UIDrawList) {
        let origin = Vec2(max((ui.size.x - 1280) / 2, 0), max((ui.size.y - 720) / 2, 0))
        func at(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> UIRect {
            UIRect(x: origin.x + x, y: origin.y + y, width: w, height: h)
        }
        func text(_ s: String, _ x: Float, _ y: Float, _ size: Float = 15, _ color: UIColor = .white) {
            ui.drawText(s, at: Vec2(origin.x + x, origin.y + y), size: size, color: color)
        }
        func box(_ rect: UIRect) {
            ui.fillRect(rect, color: Self.panel, radii: UICornerRadii(10))
            ui.strokeRect(rect, color: Self.line, width: 1, radii: UICornerRadii(10))
        }

        text("Move: WASD / arrows / left stick    Spin: J K / right stick X    Boost: Shift / LB / RT    Flash: F / A", 24, 16, 15, Self.dim)

        // Actions and what they are bound to.
        box(at(24, 440, 640, 256))
        text("Actions", 40, 452, 18)
        let bindings = actions.bindings
        var y: Float = 480
        func line(_ name: String, _ detail: String) {
            text(name, 40, y, 14, Self.warm)
            text(detail, 130, y, 14)
            y += 20
        }
        for entry in bindings.vectors {
            line(entry.name, entry.bindings.map(Self.describe).joined(separator: "  |  "))
        }
        for entry in bindings.axes {
            line(entry.name, entry.bindings.map(Self.describe).joined(separator: "  |  "))
        }
        for entry in bindings.buttons {
            line(entry.name, entry.bindings.map(\.displayName).joined(separator: "  |  "))
        }
        y += 8
        text("C: select    R: rebind    B: defaults", 40, y, 13, Self.dim)
        y += 22
        let listening = actions.listeningTarget
        for (i, row) in Self.rows.enumerated() {
            let column = Float(i / 5) * 310
            let rowY = y + Float(i % 5) * 22
            let rect = at(36 + column, rowY - 2, 300, 20)
            let target = row.target
            if listening == target {
                ui.fillRect(rect, color: Self.warm.withAlpha(0.35), radii: UICornerRadii(5))
            } else if i == selected {
                ui.fillRect(rect, color: Self.accent.withAlpha(0.4), radii: UICornerRadii(5))
            }
            let value = listening == target ? "press..." : (actions.source(at: target)?.displayName ?? "-")
            text(row.label, 42 + column, rowY, 13, i == selected ? .white : Self.dim)
            text(value, 190 + column, rowY, 13)
        }

        drawGamepad(ui, at(684, 440, 572, 256), origin)
    }

    private static func describe(_ binding: AxisBinding) -> String {
        switch binding {
        case .source(let source): source.displayName
        case .composite(let n, let p): "\(n.displayName) / \(p.displayName)"
        }
    }

    private static func describe(_ binding: VectorBinding) -> String {
        switch binding {
        case .stick(let stick): stick == .left ? "Left Stick" : "Right Stick"
        case .composite(let u, let d, let l, let r): [u, l, d, r].map(\.displayName).joined(separator: " ")
        }
    }

    /// The first gamepad: sticks (with the deadzone as a ring), triggers and buttons as they read now.
    private func drawGamepad(_ ui: UIDrawList, _ area: UIRect, _ origin: Vec2) {
        ui.fillRect(area, color: Self.panel, radii: UICornerRadii(10))
        ui.strokeRect(area, color: Self.line, width: 1, radii: UICornerRadii(10))
        func text(_ s: String, _ x: Float, _ y: Float, _ size: Float = 13, _ color: UIColor = .white) {
            ui.drawText(s, at: Vec2(area.x + x, area.y + y), size: size, color: color)
        }
        guard let pad else {
            text("Gamepad", 16, 12, 18)
            text("no gamepad", 16, 44, 16, Self.dim)
            text("Connect one (Xbox, PlayStation, Switch Pro).", 16, 70, 13, Self.dim)
            return
        }
        text("Gamepad: " + pad.name, 16, 12, 18)

        func disc(_ center: Vec2, _ radius: Float, _ color: UIColor) {
            ui.fillRect(UIRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
                        color: color, radii: UICornerRadii(radius))
        }
        func button(_ b: GamepadButton, _ center: Vec2, _ radius: Float = 15, _ label: String = "") {
            let down = pad.isDown(b)
            disc(center, radius, down ? Self.accent : Self.line)
            if !label.isEmpty { ui.drawText(label, at: Vec2(center.x - 4, center.y - 8), size: 14, color: .white) }
        }
        func pill(_ b: GamepadButton, _ rect: UIRect) {
            ui.fillRect(rect, color: pad.isDown(b) ? Self.accent : Self.line, radii: UICornerRadii(6))
        }
        func bar(_ value: Float, _ rect: UIRect, _ name: String) {
            ui.fillRect(rect, color: Self.line, radii: UICornerRadii(4))
            ui.fillRect(UIRect(x: rect.x, y: rect.y, width: rect.width * value, height: rect.height), color: Self.warm,
                        radii: UICornerRadii(4))
            ui.drawText(name + String(format: " %.2f", value), at: Vec2(rect.x, rect.y + rect.height + 4), size: 12, color: Self.dim)
        }
        func stick(_ raw: Vec2, _ value: Vec2, _ deadzone: Float, _ clicked: Bool, _ center: Vec2) {
            let r: Float = 52
            disc(center, r, Self.line)
            disc(center, r - 2, UIColor(hex: 0x141a26))
            disc(center, r * deadzone, Self.line.withAlpha(0.6))  // the deadzone
            ui.drawLine(from: Vec2(center.x - r, center.y), to: Vec2(center.x + r, center.y), width: 1, color: Self.line)
            ui.drawLine(from: Vec2(center.x, center.y - r), to: Vec2(center.x, center.y + r), width: 1, color: Self.line)
            // The raw position (hollow) and the deadzoned value (filled); y is up.
            let rawPoint = Vec2(center.x + raw.x * r, center.y - raw.y * r)
            ui.strokeRect(UIRect(x: rawPoint.x - 5, y: rawPoint.y - 5, width: 10, height: 10), color: Self.dim, width: 1.5,
                          radii: UICornerRadii(5))
            disc(Vec2(center.x + value.x * r, center.y - value.y * r), 9, clicked ? .white : Self.accent)
            ui.drawText(String(format: "%+.2f %+.2f", value.x, value.y), at: Vec2(center.x - 40, center.y + r + 6), size: 12,
                        color: Self.dim)
        }

        let x = area.x, y = area.y
        // Triggers and shoulders.
        bar(pad.leftTrigger, UIRect(x: x + 24, y: y + 48, width: 120, height: 12), "LT")
        bar(pad.rightTrigger, UIRect(x: x + area.width - 144, y: y + 48, width: 120, height: 12), "RT")
        pill(.leftShoulder, UIRect(x: x + 24, y: y + 84, width: 120, height: 14))
        pill(.rightShoulder, UIRect(x: x + area.width - 144, y: y + 84, width: 120, height: 14))
        // D-pad, face buttons, start / back / guide.
        let dpad = Vec2(x + 90, y + 148)
        button(.dpadUp, dpad + Vec2(0, -26), 12)
        button(.dpadDown, dpad + Vec2(0, 26), 12)
        button(.dpadLeft, dpad + Vec2(-26, 0), 12)
        button(.dpadRight, dpad + Vec2(26, 0), 12)
        let face = Vec2(x + area.width - 90, y + 148)
        button(.north, face + Vec2(0, -26), 14, "N")
        button(.south, face + Vec2(0, 26), 14, "S")
        button(.west, face + Vec2(-26, 0), 14, "W")
        button(.east, face + Vec2(26, 0), 14, "E")
        pill(.back, UIRect(x: x + area.width / 2 - 52, y: y + 110, width: 32, height: 12))
        pill(.guide, UIRect(x: x + area.width / 2 - 8, y: y + 110, width: 16, height: 12))
        pill(.start, UIRect(x: x + area.width / 2 + 20, y: y + 110, width: 32, height: 12))
        // Sticks.
        stick(pad.rawLeftStick, pad.leftStick, pad.leftStickDeadzone, pad.isDown(.leftStickClick), Vec2(x + 220, y + 168))
        stick(pad.rawRightStick, pad.rightStick, pad.rightStickDeadzone, pad.isDown(.rightStickClick), Vec2(x + area.width - 220, y + 168))
    }
}
