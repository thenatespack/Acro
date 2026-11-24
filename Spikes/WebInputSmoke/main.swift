// Browser check of the web platform layer (docs/wasm-spike.md, lane W1C): a CanvasWindow feeding
// an Input, the Gamepad API source, and a WebAudioDevice playing a test tone through the
// engine's AudioSystem. Every animation frame it polls events and logs what the engine saw, as
// one JSON object per console line prefixed "[acro]". smoke.mjs drives it with Playwright.
//
//   ENGINE_WASM=1 ~/.swiftly/bin/swift package --swift-sdk swift-6.4.2-RELEASE_wasm \
//       --scratch-path .build-wasm js --product WebInputSmoke -c release
//   cp Spikes/WebInputSmoke/index.html .build-wasm/plugins/PackageToJS/outputs/Package/
//   (cd ~/.acro-webtools && node <repo>/Spikes/WebInputSmoke/smoke.mjs <repo>/.build-wasm/plugins/PackageToJS/outputs/Package)
//
// Keys: C asks for mouse capture (pointer lock on the next click), F2 toggles text input.
import JavaScriptKit
import EngineCore
import EngineBackends
import EngineAudio

func log(_ fields: [(String, Any)]) {
    func json(_ value: Any) -> String {
        switch value {
        case let s as String:
            var out = "\""
            for scalar in s.unicodeScalars {
                switch scalar {
                case "\"": out += "\\\""
                case "\\": out += "\\\\"
                case "\n": out += "\\n"
                default:
                    if scalar.value < 0x20 { out += " " } else { out.unicodeScalars.append(scalar) }
                }
            }
            return out + "\""
        case let b as Bool: return b ? "true" : "false"
        case let f as Float: return f.isFinite ? "\(f)" : "null"
        case let d as Double: return d.isFinite ? "\(d)" : "null"
        case let i as Int: return "\(i)"
        case let a as [String]: return "[" + a.map { json($0) }.joined(separator: ",") + "]"
        default: return json("\(value)")
        }
    }
    let body = fields.map { "\(json($0.0)):\(json($0.1))" }.joined(separator: ",")
    _ = JSObject.global.console.log("[acro] {\(body)}")
}

func names(_ modifiers: KeyModifiers) -> [String] {
    var names: [String] = []
    if modifiers.contains(.shift) { names.append("shift") }
    if modifiers.contains(.control) { names.append("control") }
    if modifiers.contains(.alt) { names.append("alt") }
    if modifiers.contains(.command) { names.append("command") }
    return names
}

@MainActor
final class Smoke {
    let window: CanvasWindow
    let input = Input()
    let audio: AudioSystem?
    let device: WebAudioDevice?
    var frame = 0
    var lastTime: Double?
    var lastSize = (width: 0, height: 0)
    var lastScale: Float = 0
    var lastPosition = Vec2(-1, -1)
    var lastFocused: Bool?
    var lastCaptured = false
    var lastLock = false
    var lastAudioState = ""
    var lastPadButtons: [Int: Set<GamepadButton>] = [:]
    var lastPadSticks: [Int: Vec2] = [:]

    init() throws {
        window = try CanvasWindow()
        window.title = "WebInputSmoke"
        do {
            let device = try WebAudioDevice()
            let audio = try AudioSystem(device: device)
            // A quiet 440 Hz sine, looping (one second is a whole number of cycles).
            let rate = device.sampleRate
            let frames = Int(rate)
            let samples = (0..<frames).map { Float(sin(2 * Double.pi * 440 * Double($0) / rate)) * 0.2 }
            audio.play(SoundBuffer(samples: samples, channelCount: 1, sampleRate: rate, name: "tone"), loop: true)
            self.device = device
            self.audio = audio
            log([("t", "audio"), ("device", device.name), ("rate", rate)])
        } catch {
            device = nil
            audio = nil
            log([("t", "audio-error"), ("error", "\(error)")])
        }
        log([("t", "ready")])
    }

    func tick(time: Double) {
        let dt = lastTime.map { (time - $0) / 1000 } ?? 0
        lastTime = time
        frame += 1
        input.beginFrame()
        window.pollEvents(into: input)
        input.endEvents()

        if input.wasPressed(.c) { input.isMouseCaptured = true }
        window.applyCursor(input.cursor, captured: input.isMouseCaptured)
        audio?.update(dt: dt)
        report()
        // After the report, so the frame's text is logged before stopping text input discards it.
        if input.wasPressed(.f2) || input.keyEvents.contains(where: { $0.key == .f2 && !$0.isRepeat }) {
            if input.isTextInputActive { input.stopTextInput() } else { input.startTextInput() }
            log([("t", "textInput"), ("active", input.isTextInputActive)])
        }
    }

    func report() {
        let size = window.framebufferSize
        if size != lastSize || window.contentScale != lastScale {
            lastSize = size
            lastScale = window.contentScale
            log([("t", "size"), ("width", size.width), ("height", size.height), ("scale", window.contentScale)])
        }
        if lastFocused != window.isFocused {
            lastFocused = window.isFocused
            log([("t", "focus"), ("focused", window.isFocused)])
        }
        for key in Key.allCases {
            if input.wasPressed(key) { log([("t", "key"), ("key", key.rawValue), ("down", true), ("modifiers", names(input.modifiers))]) }
            if input.wasReleased(key) { log([("t", "key"), ("key", key.rawValue), ("down", false)]) }
        }
        for press in input.keyPresses {
            log([("t", "press"), ("key", press.key.rawValue), ("modifiers", names(press.modifiers)), ("repeat", press.isRepeat)])
        }
        if !input.committedText.isEmpty { log([("t", "text"), ("text", input.committedText)]) }
        for event in input.keyEvents {
            log([("t", "textKey"), ("key", event.key.rawValue), ("modifiers", names(event.modifiers))])
        }
        for button in MouseButton.allCases {
            if input.wasPressed(button) {
                log([("t", "button"), ("button", button.rawValue), ("down", true), ("x", input.mousePosition.x), ("y", input.mousePosition.y)])
            }
            if input.wasReleased(button) {
                log([("t", "button"), ("button", button.rawValue), ("down", false), ("x", input.mousePosition.x), ("y", input.mousePosition.y)])
            }
        }
        if input.mousePosition != lastPosition && !input.isMouseCaptured {
            lastPosition = input.mousePosition
            log([("t", "move"), ("x", input.mousePosition.x), ("y", input.mousePosition.y)])
        }
        if input.isMouseCaptured && input.mouseDelta != .zero {
            log([("t", "delta"), ("dx", input.mouseDelta.x), ("dy", input.mouseDelta.y)])
        }
        if input.scrollDelta != .zero { log([("t", "scroll"), ("x", input.scrollDelta.x), ("y", input.scrollDelta.y)]) }
        if input.isMouseCaptured != lastCaptured || window.hasPointerLock != lastLock {
            lastCaptured = input.isMouseCaptured
            lastLock = window.hasPointerLock
            log([("t", "capture"), ("captured", lastCaptured), ("pointerLock", lastLock)])
        }
        for event in input.gamepadEvents {
            switch event {
            case .connected(let pad): log([("t", "gamepad"), ("id", pad.id), ("name", pad.name), ("connected", true)])
            case .disconnected(let pad): log([("t", "gamepad"), ("id", pad.id), ("connected", false)])
            }
        }
        for pad in input.gamepads {
            let down = Set(GamepadButton.allCases.filter { pad.isDown($0) })
            let sticks = pad.rawLeftStick
            if down != lastPadButtons[pad.id] || sticks != lastPadSticks[pad.id] {
                lastPadButtons[pad.id] = down
                lastPadSticks[pad.id] = sticks
                log([("t", "pad"), ("id", pad.id), ("buttons", down.map(\.rawValue).sorted()),
                     ("lx", sticks.x), ("ly", sticks.y), ("lt", pad.rawLeftTrigger), ("rt", pad.rawRightTrigger)])
            }
        }
        if let device {
            let stats = device.stats
            if stats.state != lastAudioState || frame % 60 == 0 {
                lastAudioState = stats.state
                log([("t", "audioStats"), ("state", stats.state), ("chunks", stats.chunks), ("sent", stats.framesSent),
                     ("queued", stats.queuedFrames), ("underruns", stats.underruns), ("underrunFrames", stats.underrunFrames),
                     ("dropped", stats.droppedFrames)])
            }
        }
    }
}

var smoke: Smoke?
do {
    smoke = try Smoke()
} catch {
    log([("t", "error"), ("error", "\(error)")])
}

// requestAnimationFrame drives the frames; the closure lives for the page's lifetime.
nonisolated(unsafe) var frameCallback: JSClosure?
frameCallback = JSClosure { arguments in
    let time = arguments.first?.number ?? 0
    MainActor.assumeIsolated { smoke?.tick(time: time) }
    _ = JSObject.global.requestAnimationFrame!(frameCallback!)
    return .undefined
}
_ = JSObject.global.requestAnimationFrame!(frameCallback!)
