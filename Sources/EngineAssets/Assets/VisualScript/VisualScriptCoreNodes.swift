import Foundation
import EngineCore
import EngineScene

// The built-in events, flow control, math, logic, text, arrays and maps, variables and functions.

typealias VSPin = VisualScriptPin
typealias VSValue = VisualScriptValue
typealias VSDef = VisualScriptNodeDefinition
typealias VSContext = VisualScriptNodeContext

@MainActor
enum VSNode {
    static func action(_ id: String, _ title: String, _ category: String, _ doc: String, config: [VisualScriptConfigKey] = [],
                       _ inputs: [VSPin] = [], _ outputs: [VSPin] = [],
                       _ run: @escaping @MainActor (VSContext) throws -> VisualScriptFlow) -> VSDef {
        VSDef(id: id, title: title, category: category, doc: doc, kind: .action, config: config, inputs: inputs, outputs: outputs, run: run)
    }

    static func pure(_ id: String, _ title: String, _ category: String, _ doc: String, config: [VisualScriptConfigKey] = [],
                     _ inputs: [VSPin] = [], _ outputs: [VSPin] = [], _ run: @escaping @MainActor (VSContext) throws -> Void) -> VSDef {
        VSDef(id: id, title: title, category: category, doc: doc, kind: .pure, config: config, inputs: inputs, outputs: outputs) { context in
            try run(context)
            return .stop
        }
    }

    static func event(_ id: String, _ title: String, _ doc: String, event: String, config: [VisualScriptConfigKey] = [],
                      _ outputs: [VSPin] = []) -> VSDef {
        VSDef(id: id, title: title, category: "Events", doc: doc, kind: .event, config: config, event: event, outputs: outputs, run: nil)
    }

    /// A config value as a list of strings (`["a", "b"]` or "a, b").
    static func strings(_ value: JSONValue?) -> [String] {
        switch value {
        case .array(let items)?: return items.compactMap { if case .string(let s) = $0 { s } else if case .int(let i) = $0 { String(i) } else { nil } }
        case .string(let s)?: return s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        default: return []
        }
    }

    static func int(_ value: JSONValue?, _ fallback: Int) -> Int {
        switch value {
        case .int(let i)?: Int(i)
        case .double(let d)?: Int(d)
        default: fallback
        }
    }
}

@MainActor
enum VisualScriptCoreNodes {
    static func all() -> [VSDef] {
        events() + flow() + math() + vectors() + logic() + text() + collections() + variables() + functions() + misc() + VisualScriptReroute.definitions()
    }

    // MARK: Events

    static func events() -> [VSDef] {
        let dt = VSPin("dt", .float, doc: "Seconds since the last frame")
        let collision = [VSPin("other", .entity, doc: "The other entity"), VSPin("point", .vec3), VSPin("normal", .vec3)]
        var list: [VSDef] = [
            VSNode.event("event.start", "On Start", "Runs once when the entity's script starts (play begins or the entity spawns).", event: "start"),
            VSNode.event("event.update", "On Update", "Runs every frame.", event: "update", [dt]),
            VSNode.event("event.fixedUpdate", "On Fixed Update", "Runs every fixed physics step.", event: "fixedUpdate", [dt]),
            VSNode.event("event.lateUpdate", "On Late Update", "Runs every frame after the update event and other systems (cameras).", event: "lateUpdate", [dt]),
            VSNode.event("event.destroy", "On Destroy", "Runs when the entity or its VisualScript goes away.", event: "destroy"),
            VSNode.event("event.timer", "On Timer", "Runs every `interval` seconds (once when `repeat` is false).", event: "timer",
                         config: [VisualScriptConfigKey("interval", .float, doc: "Seconds (default 1)"),
                                  VisualScriptConfigKey("repeat", .bool, doc: "Default true")]),
            VSNode.event("event.keyPressed", "On Key Pressed", "Runs when `key` goes down.", event: "keyPressed",
                         config: [VisualScriptConfigKey("key", options: Key.allCases.map(\.rawValue))]),
            VSNode.event("event.keyReleased", "On Key Released", "Runs when `key` comes up.", event: "keyReleased",
                         config: [VisualScriptConfigKey("key", options: Key.allCases.map(\.rawValue))]),
            VSNode.event("event.actionPressed", "On Action Pressed",
                         "Runs when the input action `action` (declared in the graph's `actions`) is pressed.", event: "actionPressed",
                         config: [VisualScriptConfigKey("action")]),
            VSNode.event("event.actionReleased", "On Action Released", "Runs when the input action `action` is released.", event: "actionReleased",
                         config: [VisualScriptConfigKey("action")]),
            VSNode.event("event.custom", "On Custom Event",
                         "Runs when the custom event `name` is sent to this entity or to everyone (event.send, or Swift: runtime.send).",
                         event: "custom", config: [VisualScriptConfigKey("name")],
                         [VSPin("sender", .entity), VSPin("value", .any)]),
        ]
        for (dimension, suffix) in [("3D", ""), ("2D", "2D")] {
            list += [
                VSNode.event("event.collisionEnter\(suffix)", "On Collision Enter \(dimension)", "Runs when this entity's \(dimension) collider starts touching another.",
                             event: "collisionEnter\(suffix)", collision),
                VSNode.event("event.collisionExit\(suffix)", "On Collision Exit \(dimension)", "Runs when it stops touching.", event: "collisionExit\(suffix)", collision),
                VSNode.event("event.triggerEnter\(suffix)", "On Trigger Enter \(dimension)", "Runs when something enters this entity's \(dimension) trigger (or this enters one).",
                             event: "triggerEnter\(suffix)", collision),
                VSNode.event("event.triggerExit\(suffix)", "On Trigger Exit \(dimension)", "Runs when it leaves.", event: "triggerExit\(suffix)", collision),
            ]
        }
        list.append(VSNode.action("event.send", "Send Event", "Events",
                                  "Sends the custom event `name` to `target`'s graph (unconnected: to every graph and Swift listeners).",
                                  config: [VisualScriptConfigKey("name")],
                                  [VSPin("target", .entity), VSPin("value", .any)]) { c in
            guard let name = c.configString("name"), !name.isEmpty else { throw VisualScriptError("no event name") }
            let value = try c.input("value")
            let target: Entity? = c.isConnected("target") ? try c.entity("target") : nil
            c.runtime.send(name, to: target, value: value, from: c.entity)
            return .next
        })
        return list
    }

    // MARK: Flow

    static func flow() -> [VSDef] {
        let sequence = VSDef(
            id: "flow.sequence", title: "Sequence", category: "Flow",
            doc: "Runs `out0`, `out1`… one after another (`count` outputs, default 2).", kind: .action,
            config: [VisualScriptConfigKey("count", .int)],
            signature: { context in
                let count = min(max(VSNode.int(context.node.config["count"], 2), 1), 16)
                return VisualScriptSignature(inputs: [.exec("in")], outputs: (0..<count).map { .exec("out\($0)") })
            }, run: { c in
                let count = min(max(VSNode.int(c.config("count"), 2), 1), 16)
                for i in 0..<count { try c.fire("out\(i)") }
                return .stop
            })
        let switchNode = VSDef(
            id: "flow.switch", title: "Switch", category: "Flow",
            doc: "Follows the output named after `value` (as text) among `cases` (config list, e.g. enum case names), else `default`.",
            kind: .action, config: [VisualScriptConfigKey("cases", .array)],
            signature: { context in
                let cases = VSNode.strings(context.node.config["cases"]).filter { !$0.contains(".") }
                return VisualScriptSignature(inputs: [.exec("in"), VSPin("value", .any)],
                                             outputs: cases.map { .exec($0) } + [.exec("default")])
            }, run: { c in
                let value = try c.input("value").asString
                return VSNode.strings(c.config("cases")).contains(value) ? .out(value) : .out("default")
            })
        let gate = VSDef(
            id: "flow.gate", title: "Gate", category: "Flow",
            doc: "Lets the flow from `enter` through to `out` while open; `open`, `close` and `toggle` change it (config startOpen).",
            kind: .action, config: [VisualScriptConfigKey("startOpen", .bool)],
            signature: { _ in
                VisualScriptSignature(inputs: [.exec("enter"), .exec("open"), .exec("close"), .exec("toggle")], outputs: [.exec("out")])
            }, run: { c in
                var open = c.state["open"]?.asBool ?? (c.config("startOpen") == .bool(true))
                switch c.trigger {
                case "open": open = true
                case "close": open = false
                case "toggle": open.toggle()
                default:
                    c.state["open"] = .bool(open)
                    return open ? .next : .stop
                }
                c.state["open"] = .bool(open)
                return .stop
            })
        let doOnce = VSDef(
            id: "flow.doOnce", title: "Do Once", category: "Flow", doc: "Passes the flow the first time only, until `reset`.", kind: .action,
            signature: { _ in VisualScriptSignature(inputs: [.exec("in"), .exec("reset")], outputs: [.exec("out")]) },
            run: { c in
                if c.trigger == "reset" { c.state["done"] = .bool(false); return .stop }
                if c.state["done"]?.asBool == true { return .stop }
                c.state["done"] = .bool(true)
                return .next
            })
        return [
            VSNode.action("flow.branch", "Branch", "Flow", "Follows `true` or `false`.",
                          [VSPin("condition", .bool)], [.exec("true"), .exec("false")]) { c in
                try c.bool("condition") ? .out("true") : .out("false")
            },
            sequence,
            VSNode.action("flow.forLoop", "For Loop", "Flow", "Runs `body` for each index from `first` to `last` (inclusive), then `done`.",
                          [VSPin("first", .int), VSPin("last", .int, default: .int(9))],
                          [.exec("body"), VSPin("index", .int), .exec("done")]) { c in
                let first = try c.int("first"), last = try c.int("last")
                if first <= last {
                    for i in first...last {
                        c.set("index", .int(i))
                        try c.fire("body")
                    }
                }
                return .out("done")
            },
            VSNode.action("flow.forEach", "For Each", "Flow", "Runs `body` for each item of `array`, then `done`.",
                          [VSPin("array", .array, required: true)],
                          [.exec("body"), VSPin("item", .any), VSPin("index", .int), .exec("done")]) { c in
                for (i, item) in try c.input("array").asArray.enumerated() {
                    c.set("item", item)
                    c.set("index", .int(i))
                    try c.fire("body")
                }
                return .out("done")
            },
            VSNode.action("flow.while", "While", "Flow", "Runs `body` while `condition` is true (read again each time), then `done`.",
                          [VSPin("condition", .bool)], [.exec("body"), .exec("done")]) { c in
                while try c.bool("condition") {
                    try c.fire("body")
                    c.runtime.bumpEpoch()
                }
                return .out("done")
            },
            gate,
            doOnce,
            VSNode.action("flow.delay", "Delay", "Flow",
                          "Continues from `out` after `seconds` of game time. Running it again while waiting does nothing.",
                          [VSPin("seconds", .float, default: .float(1))]) { c in
                if c.state["waiting"]?.asBool == true { return .stop }
                c.state["waiting"] = .bool(true)
                c.wait(try c.double("seconds"), then: "out", clearing: "waiting")
                return .stop
            },
            VSNode.action("flow.flipFlop", "Flip Flop", "Flow", "Alternates between `a` and `b` each time it runs.",
                          [], [.exec("a"), .exec("b"), VSPin("isA", .bool)]) { c in
                let isA = !(c.state["isA"]?.asBool ?? false)
                c.state["isA"] = .bool(isA)
                c.set("isA", .bool(isA))
                return isA ? .out("a") : .out("b")
            },
            switchNode,
        ]
    }

    // MARK: Math

    /// Arithmetic over numbers and vectors: vectors work per component (a number is spread over
    /// every component), two ints give an int, anything else a float.
    static func arithmetic(_ a: VSValue, _ b: VSValue, _ f: (Double, Double) -> Double, intOp: ((Int, Int) -> Int?)? = nil) -> VSValue {
        let a = numeric(a), b = numeric(b)
        func vec(_ v: VSValue) -> Vec4 {
            switch v {
            case .vec2(let x): Vec4(x.x, x.y, 0, 0)
            case .vec3(let x): Vec4(x.x, x.y, x.z, 0)
            case .vec4(let x): x
            default: Vec4(repeating: v.asFloat)
            }
        }
        func rank(_ v: VSValue) -> Int {
            switch v { case .vec2: 2; case .vec3: 3; case .vec4: 4; default: 0 }
        }
        let r = max(rank(a), rank(b))
        if r > 0 {
            let x = vec(a), y = vec(b)
            let out = Vec4(Float(f(Double(x.x), Double(y.x))), Float(f(Double(x.y), Double(y.y))),
                           Float(f(Double(x.z), Double(y.z))), Float(f(Double(x.w), Double(y.w))))
            switch r {
            case 2: return .vec2(Vec2(out.x, out.y))
            case 3: return .vec3(Vec3(out.x, out.y, out.z))
            default: return .vec4(out)
            }
        }
        if case .int(let x) = a, case .int(let y) = b, let intOp, let result = intOp(x, y) { return .int(result) }
        return .float(f(a.asDouble, b.asDouble))
    }

    /// Arrays of 2 to 4 numbers read as vectors; text as a number.
    static func numeric(_ v: VSValue) -> VSValue {
        switch v {
        case .array(let items) where (2...4).contains(items.count):
            switch items.count {
            case 2: return .vec2(v.asVec2)
            case 3: return .vec3(v.asVec3)
            default: return .vec4(v.asVec4)
            }
        case .string, .bool, .none: return .float(v.asDouble)
        default: return v
        }
    }

    static func unary(_ v: VSValue, _ f: (Double) -> Double, keepsInt: Bool = false) -> VSValue {
        switch numeric(v) {
        case .vec2(let x): return .vec2(Vec2(Float(f(Double(x.x))), Float(f(Double(x.y)))))
        case .vec3(let x): return .vec3(Vec3(Float(f(Double(x.x))), Float(f(Double(x.y))), Float(f(Double(x.z)))))
        case .vec4(let x): return .vec4(Vec4(Float(f(Double(x.x))), Float(f(Double(x.y))), Float(f(Double(x.z))), Float(f(Double(x.w)))))
        case .int(let i) where keepsInt: return .int(Int(f(Double(i))))
        case let other: return .float(f(other.asDouble))
        }
    }

    static func math() -> [VSDef] {
        let ab = [VSPin("a", .any, default: .float(0)), VSPin("b", .any, default: .float(0))]
        let result = [VSPin("result", .any)]
        func binary(_ id: String, _ title: String, _ doc: String, _ f: @escaping (Double, Double) -> Double,
                    int: ((Int, Int) -> Int?)? = nil) -> VSDef {
            VSNode.pure("math.\(id)", title, "Math", doc + " Works on numbers and vectors.", ab, result) { c in
                c.set("result", arithmetic(try c.input("a"), try c.input("b"), f, intOp: int))
            }
        }
        func single(_ id: String, _ title: String, _ f: @escaping (Double) -> Double, keepsInt: Bool = false) -> VSDef {
            VSNode.pure("math.\(id)", title, "Math", "\(title) of `value` (per component for vectors).",
                        [VSPin("value", .any, default: .float(0))], result) { c in
                c.set("result", unary(try c.input("value"), f, keepsInt: keepsInt))
            }
        }
        return [
            binary("add", "Add", "a + b.", +, int: { $0.addingReportingOverflow($1).overflow ? nil : $0 + $1 }),
            binary("subtract", "Subtract", "a - b.", -, int: { $0.subtractingReportingOverflow($1).overflow ? nil : $0 - $1 }),
            binary("multiply", "Multiply", "a × b.", *, int: { $0.multipliedReportingOverflow(by: $1).overflow ? nil : $0 * $1 }),
            binary("divide", "Divide", "a ÷ b (0 when b is 0).", { $1 == 0 ? 0 : $0 / $1 }, int: { $1 == 0 ? 0 : ($0 % $1 == 0 ? $0 / $1 : nil) }),
            binary("modulo", "Modulo", "Remainder of a ÷ b (same sign as b).", { $1 == 0 ? 0 : $0 - $1 * ($0 / $1).rounded(.down) },
                   int: { $1 == 0 ? 0 : (($0 % $1) + $1) % $1 }),
            binary("min", "Min", "The smaller of a and b.", { Swift.min($0, $1) }, int: { Swift.min($0, $1) }),
            binary("max", "Max", "The larger of a and b.", { Swift.max($0, $1) }, int: { Swift.max($0, $1) }),
            binary("power", "Power", "a to the power b.", { pow($0, $1) }),
            binary("atan2", "Atan2", "The angle in degrees of the direction (b, a): atan2(a, b).", { atan2($0, $1) * 180 / .pi }),
            single("abs", "Absolute", { Swift.abs($0) }, keepsInt: true),
            single("negate", "Negate", { -$0 }, keepsInt: true),
            single("sqrt", "Square Root", { $0 < 0 ? 0 : $0.squareRoot() }),
            single("floor", "Floor", { $0.rounded(.down) }, keepsInt: true),
            single("ceil", "Ceiling", { $0.rounded(.up) }, keepsInt: true),
            single("round", "Round", { $0.rounded() }, keepsInt: true),
            single("sin", "Sine (degrees)", { sin($0 * .pi / 180) }),
            single("cos", "Cosine (degrees)", { cos($0 * .pi / 180) }),
            single("tan", "Tangent (degrees)", { tan($0 * .pi / 180) }),
            VSNode.pure("math.clamp", "Clamp", "Math", "`value` limited to `min`...`max` (per component for vectors).",
                        [VSPin("value", .any), VSPin("min", .any, default: .float(0)), VSPin("max", .any, default: .float(1))], result) { c in
                let low = arithmetic(try c.input("value"), try c.input("min"), { Swift.max($0, $1) }, intOp: { Swift.max($0, $1) })
                c.set("result", arithmetic(low, try c.input("max"), { Swift.min($0, $1) }, intOp: { Swift.min($0, $1) }))
            },
            VSNode.pure("math.lerp", "Lerp", "Math", "a + (b - a) × t (vectors too).",
                        [VSPin("a", .any), VSPin("b", .any, default: .float(1)), VSPin("t", .float, default: .float(0.5))], result) { c in
                let a = try c.input("a"), b = try c.input("b"), t = try c.double("t")
                let delta = arithmetic(b, a, -)
                c.set("result", arithmetic(a, arithmetic(delta, .float(t), *), +))
            },
            VSNode.pure("math.randomFloat", "Random Float", "Math", "A random number in `min`...`max`, new each time it is read.",
                        [VSPin("min", .float), VSPin("max", .float, default: .float(1))], [VSPin("value", .float)]) { c in
                let low = try c.double("min"), high = try c.double("max")
                c.set("value", .float(low < high ? Double.random(in: low...high) : low))
            },
            VSNode.pure("math.randomInt", "Random Integer", "Math", "A random whole number in `min`...`max` (inclusive).",
                        [VSPin("min", .int), VSPin("max", .int, default: .int(10))], [VSPin("value", .int)]) { c in
                let low = try c.int("min"), high = try c.int("max")
                c.set("value", .int(low < high ? Int.random(in: low...high) : low))
            },
            VSNode.pure("math.randomBool", "Random Bool", "Math", "True with probability `chance` (0...1).",
                        [VSPin("chance", .float, default: .float(0.5))], [VSPin("value", .bool)]) { c in
                c.set("value", .bool(Double.random(in: 0..<1) < (try c.double("chance"))))
            },
        ]
    }

    // MARK: Vectors

    static func vectors() -> [VSDef] {
        [
            VSNode.pure("vec3.make", "Make Vector3", "Vector", "A vector from x, y, z.",
                        [VSPin("x", .float), VSPin("y", .float), VSPin("z", .float)], [VSPin("vector", .vec3)]) { c in
                c.set("vector", .vec3(Vec3(try c.float("x"), try c.float("y"), try c.float("z"))))
            },
            VSNode.pure("vec3.break", "Break Vector3", "Vector", "A vector's x, y, z.",
                        [VSPin("vector", .vec3)], [VSPin("x", .float), VSPin("y", .float), VSPin("z", .float)]) { c in
                let v = try c.vec3("vector")
                c.set("x", .float(Double(v.x)))
                c.set("y", .float(Double(v.y)))
                c.set("z", .float(Double(v.z)))
            },
            VSNode.pure("vec2.make", "Make Vector2", "Vector", "A 2D vector from x, y.",
                        [VSPin("x", .float), VSPin("y", .float)], [VSPin("vector", .vec2)]) { c in
                c.set("vector", .vec2(Vec2(try c.float("x"), try c.float("y"))))
            },
            VSNode.pure("vec2.break", "Break Vector2", "Vector", "A 2D vector's x, y.",
                        [VSPin("vector", .vec2)], [VSPin("x", .float), VSPin("y", .float)]) { c in
                let v = try c.vec2("vector")
                c.set("x", .float(Double(v.x)))
                c.set("y", .float(Double(v.y)))
            },
            VSNode.pure("color.make", "Make Color", "Vector", "A color from r, g, b, a (0...1, linear).",
                        [VSPin("r", .float, default: .float(1)), VSPin("g", .float, default: .float(1)), VSPin("b", .float, default: .float(1)),
                         VSPin("a", .float, default: .float(1))], [VSPin("color", .color)]) { c in
                c.set("color", .vec4(Vec4(try c.float("r"), try c.float("g"), try c.float("b"), try c.float("a"))))
            },
            VSNode.pure("vec3.length", "Length", "Vector", "A vector's length.", [VSPin("vector", .vec3)], [VSPin("length", .float)]) { c in
                c.set("length", .float(Double(length(try c.vec3("vector")))))
            },
            VSNode.pure("vec3.normalize", "Normalize", "Vector", "The vector scaled to length 1 (zero stays zero).",
                        [VSPin("vector", .vec3)], [VSPin("result", .vec3)]) { c in
                let v = try c.vec3("vector")
                c.set("result", .vec3(length(v) > 1e-8 ? normalize(v) : .zero))
            },
            VSNode.pure("vec3.dot", "Dot", "Vector", "a · b.", [VSPin("a", .vec3), VSPin("b", .vec3)], [VSPin("result", .float)]) { c in
                c.set("result", .float(Double(dot(try c.vec3("a"), try c.vec3("b")))))
            },
            VSNode.pure("vec3.cross", "Cross", "Vector", "a × b.", [VSPin("a", .vec3), VSPin("b", .vec3)], [VSPin("result", .vec3)]) { c in
                c.set("result", .vec3(cross(try c.vec3("a"), try c.vec3("b"))))
            },
            VSNode.pure("vec3.distance", "Distance", "Vector", "The distance between two points.",
                        [VSPin("a", .vec3), VSPin("b", .vec3)], [VSPin("distance", .float)]) { c in
                c.set("distance", .float(Double(length(try c.vec3("a") - (try c.vec3("b"))))))
            },
        ]
    }

    // MARK: Logic and comparison

    static func compare(_ a: VSValue, _ b: VSValue) -> Int? {
        let x = numeric(a), y = numeric(b)
        switch (x, y) {
        case (.string(let s), .string(let t)): return s < t ? -1 : (s == t ? 0 : 1)
        case (.int, _), (.float, _):
            let p = x.asDouble, q = y.asDouble
            return p < q ? -1 : (p == q ? 0 : 1)
        default: return nil
        }
    }

    static func equal(_ a: VSValue, _ b: VSValue) -> Bool {
        switch (numeric(a), numeric(b)) {
        case (.int(let x), .int(let y)): return x == y
        case (.int, .float), (.float, .int), (.float, .float): return abs(a.asDouble - b.asDouble) < 1e-9
        case (.vec2(let x), .vec2(let y)): return x == y
        case (.vec3(let x), .vec3(let y)): return x == y
        case (.vec4(let x), .vec4(let y)): return x == y
        case (.string(let s), let other), (let other, .string(let s)): return s == other.asString
        default: return a == b
        }
    }

    static func logic() -> [VSDef] {
        let ab = [VSPin("a", .any), VSPin("b", .any)]
        let out = [VSPin("result", .bool)]
        func comparison(_ id: String, _ title: String, _ test: @escaping (Int) -> Bool) -> VSDef {
            VSNode.pure("compare.\(id)", title, "Logic", "Compares numbers (or text alphabetically).", ab, out) { c in
                c.set("result", .bool(compare(try c.input("a"), try c.input("b")).map(test) ?? false))
            }
        }
        return [
            VSNode.pure("compare.equal", "Equal", "Logic", "Whether a equals b (numbers compare by value, text by content).", ab, out) { c in
                c.set("result", .bool(equal(try c.input("a"), try c.input("b"))))
            },
            VSNode.pure("compare.notEqual", "Not Equal", "Logic", "Whether a differs from b.", ab, out) { c in
                c.set("result", .bool(!equal(try c.input("a"), try c.input("b"))))
            },
            comparison("less", "Less", { $0 < 0 }),
            comparison("lessOrEqual", "Less or Equal", { $0 <= 0 }),
            comparison("greater", "Greater", { $0 > 0 }),
            comparison("greaterOrEqual", "Greater or Equal", { $0 >= 0 }),
            VSNode.pure("logic.and", "And", "Logic", "a and b.", [VSPin("a", .bool), VSPin("b", .bool)], out) { c in
                c.set("result", .bool(try c.bool("a") && c.bool("b")))
            },
            VSNode.pure("logic.or", "Or", "Logic", "a or b.", [VSPin("a", .bool), VSPin("b", .bool)], out) { c in
                c.set("result", .bool(try c.bool("a") || c.bool("b")))
            },
            VSNode.pure("logic.xor", "Xor", "Logic", "Exactly one of a and b.", [VSPin("a", .bool), VSPin("b", .bool)], out) { c in
                c.set("result", .bool(try c.bool("a") != c.bool("b")))
            },
            VSNode.pure("logic.not", "Not", "Logic", "The opposite of `value`.", [VSPin("value", .bool)], out) { c in
                c.set("result", .bool(!(try c.bool("value"))))
            },
            VSNode.pure("logic.select", "Select", "Logic", "`a` when `condition` is true, else `b`.",
                        [VSPin("condition", .bool), VSPin("a", .any), VSPin("b", .any)], [VSPin("result", .any)]) { c in
                c.set("result", try c.bool("condition") ? c.input("a") : c.input("b"))
            },
        ]
    }

    // MARK: Text

    static func text() -> [VSDef] {
        [
            VSNode.pure("string.format", "Format Text", "Text",
                        "Replaces {a}, {b}, {c}, {d} (or {0}…{3}) in `format` with the inputs as text.",
                        [VSPin("format", .string, default: .string("{a}")), VSPin("a", .any), VSPin("b", .any), VSPin("c", .any), VSPin("d", .any)],
                        [VSPin("text", .string)]) { c in
                var text = try c.string("format")
                for (i, name) in ["a", "b", "c", "d"].enumerated() where text.contains("{\(name)}") || text.contains("{\(i)}") {
                    let value = try c.input(name).asString
                    text = text.replacingOccurrences(of: "{\(name)}", with: value).replacingOccurrences(of: "{\(i)}", with: value)
                }
                c.set("text", .string(text))
            },
            VSNode.pure("string.join", "Join Text", "Text", "a, then `separator`, then b.",
                        [VSPin("a", .string), VSPin("b", .string), VSPin("separator", .string)], [VSPin("text", .string)]) { c in
                c.set("text", .string(try c.string("a") + c.string("separator") + c.string("b")))
            },
            VSNode.pure("string.contains", "Text Contains", "Text", "Whether `text` contains `search`.",
                        [VSPin("text", .string), VSPin("search", .string)], [VSPin("result", .bool)]) { c in
                let search = try c.string("search")
                let text = try c.string("text")
                c.set("result", .bool(search.isEmpty || text.contains(search)))
            },
            VSNode.pure("string.length", "Text Length", "Text", "Characters in `text`.", [VSPin("text", .string)], [VSPin("length", .int)]) { c in
                c.set("length", .int(try c.string("text").count))
            },
            VSNode.pure("string.toText", "To Text", "Text", "Any value as text.", [VSPin("value", .any)], [VSPin("text", .string)]) { c in
                c.set("text", .string(try c.input("value").asString))
            },
            VSNode.pure("string.toNumber", "To Number", "Text", "Text read as a number (0 when it isn't one).",
                        [VSPin("text", .string)], [VSPin("value", .float), VSPin("valid", .bool)]) { c in
                let number = Double(try c.string("text").trimmingCharacters(in: .whitespaces))
                c.set("value", .float(number ?? 0))
                c.set("valid", .bool(number != nil))
            },
        ]
    }

    // MARK: Arrays and maps

    static func collections() -> [VSDef] {
        let makeArray = VSDef(
            id: "array.make", title: "Make Array", category: "Array", doc: "An array of the `count` items (config, default 3).", kind: .pure,
            config: [VisualScriptConfigKey("count", .int)],
            signature: { context in
                let count = min(max(VSNode.int(context.node.config["count"], 3), 0), 32)
                return VisualScriptSignature(inputs: (0..<count).map { VSPin("item\($0)", .any) }, outputs: [VSPin("array", .array)])
            }, run: { c in
                let count = min(max(VSNode.int(c.config("count"), 3), 0), 32)
                c.set("array", .array(try (0..<count).map { try c.input("item\($0)") }))
                return .stop
            })
        let array = VSPin("array", .array)
        return [
            makeArray,
            VSNode.pure("array.get", "Get Item", "Array", "The item at `index` (from 0; negative counts from the end).",
                        [array, VSPin("index", .int)], [VSPin("item", .any), VSPin("valid", .bool)]) { c in
                let items = try c.input("array").asArray
                var i = try c.int("index")
                if i < 0 { i += items.count }
                let valid = items.indices.contains(i)
                c.set("item", valid ? items[i] : .none)
                c.set("valid", .bool(valid))
            },
            VSNode.pure("array.length", "Length", "Array", "Items in the array.", [array], [VSPin("length", .int)]) { c in
                c.set("length", .int(try c.input("array").asArray.count))
            },
            VSNode.pure("array.append", "Append", "Array", "The array with `item` added at the end (store it with a variable).",
                        [array, VSPin("item", .any)], [VSPin("result", .array)]) { c in
                c.set("result", .array(try c.input("array").asArray + [c.input("item")]))
            },
            VSNode.pure("array.set", "Set Item", "Array", "The array with the item at `index` replaced.",
                        [array, VSPin("index", .int), VSPin("item", .any)], [VSPin("result", .array)]) { c in
                var items = try c.input("array").asArray
                let i = try c.int("index")
                if items.indices.contains(i) { items[i] = try c.input("item") }
                c.set("result", .array(items))
            },
            VSNode.pure("array.removeAt", "Remove Item", "Array", "The array without the item at `index`.",
                        [array, VSPin("index", .int)], [VSPin("result", .array)]) { c in
                var items = try c.input("array").asArray
                let i = try c.int("index")
                if items.indices.contains(i) { items.remove(at: i) }
                c.set("result", .array(items))
            },
            VSNode.pure("array.contains", "Contains", "Array", "Whether the array holds `item`.",
                        [array, VSPin("item", .any)], [VSPin("result", .bool), VSPin("index", .int)]) { c in
                let item = try c.input("item")
                let index = try c.input("array").asArray.firstIndex { equal($0, item) }
                c.set("result", .bool(index != nil))
                c.set("index", .int(index ?? -1))
            },
            VSNode.pure("array.random", "Random Item", "Array", "A random item (none for an empty array).", [array], [VSPin("item", .any)]) { c in
                c.set("item", try c.input("array").asArray.randomElement() ?? .none)
            },
            VSNode.pure("map.get", "Get Value", "Map", "The value under `key`.",
                        [VSPin("map", .map), VSPin("key", .string)], [VSPin("value", .any), VSPin("found", .bool)]) { c in
                let value = try c.input("map").asMap[try c.string("key")]
                c.set("value", value ?? .none)
                c.set("found", .bool(value != nil))
            },
            VSNode.pure("map.set", "Set Value", "Map", "The map with `key` set to `value` (store it with a variable).",
                        [VSPin("map", .map), VSPin("key", .string), VSPin("value", .any)], [VSPin("result", .map)]) { c in
                var map = try c.input("map").asMap
                map[try c.string("key")] = try c.input("value")
                c.set("result", .map(map))
            },
            VSNode.pure("map.remove", "Remove Key", "Map", "The map without `key`.",
                        [VSPin("map", .map), VSPin("key", .string)], [VSPin("result", .map)]) { c in
                var map = try c.input("map").asMap
                map[try c.string("key")] = nil
                c.set("result", .map(map))
            },
            VSNode.pure("map.has", "Has Key", "Map", "Whether the map has `key`.",
                        [VSPin("map", .map), VSPin("key", .string)], [VSPin("result", .bool)]) { c in
                c.set("result", .bool(try c.input("map").asMap[try c.string("key")] != nil))
            },
            VSNode.pure("map.keys", "Keys", "Map", "The map's keys, sorted.", [VSPin("map", .map)], [VSPin("keys", .array)]) { c in
                c.set("keys", .array(try c.input("map").asMap.keys.sorted().map { .string($0) }))
            },
        ]
    }

    // MARK: Variables

    static func variableType(_ context: VisualScriptSignatureContext) -> VisualScriptType {
        context.node.configString("variable").flatMap { context.graph.variable($0)?.type } ?? .any
    }

    static func checkVariable(_ context: VisualScriptSignatureContext) -> [String] {
        guard let name = context.node.configString("variable"), !name.isEmpty else { return ["no variable chosen (config.variable)"] }
        return context.graph.variable(name) == nil ? ["no variable named '\(name)'"] : []
    }

    static func variables() -> [VSDef] {
        [
            VSDef(id: "var.get", title: "Get Variable", category: "Variables", doc: "The value of the graph variable `variable` (config).",
                  kind: .pure, config: [VisualScriptConfigKey("variable")],
                  signature: { VisualScriptSignature(outputs: [VSPin("value", variableType($0))]) },
                  check: checkVariable,
                  run: { c in
                      c.set("value", c.variable(c.configString("variable") ?? "") ?? .none)
                      return .stop
                  }),
            VSDef(id: "var.set", title: "Set Variable", category: "Variables", doc: "Sets the graph variable `variable` (config) to `value`.",
                  kind: .action, config: [VisualScriptConfigKey("variable")],
                  signature: { context in
                      let type = variableType(context)
                      return VisualScriptSignature(inputs: [.exec("in"), VSPin("value", type)], outputs: [.exec("out"), VSPin("value", type)])
                  },
                  check: checkVariable,
                  run: { c in
                      let name = c.configString("variable") ?? ""
                      try c.setVariable(name, try c.input("value"))
                      c.set("value", c.variable(name) ?? .none)
                      return .next
                  }),
        ]
    }

    // MARK: Functions

    static func functions() -> [VSDef] {
        [
            VSDef(id: "function.call", title: "Call Function", category: "Functions",
                  doc: "Calls the graph's function `function` (config) with its inputs; its results come out as outputs. For a macro, the macro's nodes run in its place (its exec pins are the macro's).",
                  kind: .action, config: [VisualScriptConfigKey("function")],
                  signature: { context in
                      guard let function = context.node.configString("function").flatMap(context.graph.function) else {
                          return VisualScriptSignature(inputs: [.exec("in")], outputs: [.exec("out")])
                      }
                      let ins = function.inputs.map { VSPin($0.name, $0.type) }, outs = function.outputs.map { VSPin($0.name, $0.type) }
                      if function.macro { return VisualScriptSignature(inputs: ins, outputs: outs) }
                      return function.pure ? VisualScriptSignature(inputs: ins, outputs: outs)
                                           : VisualScriptSignature(inputs: [.exec("in")] + ins, outputs: [.exec("out")] + outs)
                  },
                  check: { context in
                      guard let name = context.node.configString("function"), !name.isEmpty else { return ["no function chosen (config.function)"] }
                      return context.graph.function(name) == nil ? ["no function named '\(name)'"] : []
                  },
                  run: { c in
                      let name = c.configString("function") ?? ""
                      guard let function = c.instance.program.graph.function(name) else { throw VisualScriptError("no function '\(name)'") }
                      if function.macro { throw VisualScriptError("macro '\(name)' uses itself (macros can't be recursive)") }
                      let results = try c.call(function: name, try function.inputs.map { try c.input($0.name) })
                      for (parameter, value) in zip(function.outputs, results) { c.set(parameter.name, value) }
                      return .next
                  }),
            VSDef(id: "function.entry", title: "Function Entry", category: "Functions",
                  doc: "Where a function starts; its outputs are the call's inputs.", kind: .pure,
                  signature: { context in
                      let pins = (context.function?.inputs ?? []).map { VSPin($0.name, $0.type) }
                      return VisualScriptSignature(outputs: context.function?.macro == true ? pins : [.exec("out")] + pins)
                  }, run: nil),
            VSDef(id: "function.return", title: "Return", category: "Functions",
                  doc: "Ends the function; its inputs are the call's results.", kind: .action,
                  signature: { context in
                      let pins = (context.function?.outputs ?? []).map { VSPin($0.name, $0.type) }
                      return VisualScriptSignature(inputs: context.function?.macro == true ? pins : [.exec("in")] + pins)
                  }, run: { c in
                      c.returnFromFunction(try (c.function?.outputs ?? []).map { try c.input($0.name) })
                      return .stop
                  }),
        ]
    }

    // MARK: Debug, time, input

    static func misc() -> [VSDef] {
        let keys = Key.allCases.map(\.rawValue)
        return [
            VSNode.action("debug.log", "Log", "Debug", "Writes `message` to the console.", [VSPin("message", .any, default: .string("Hello"))]) { c in
                c.log(try c.input("message").asString)
                return .next
            },
            VSNode.pure("time.delta", "Delta Time", "Time", "Seconds since the last frame.", [], [VSPin("dt", .float)]) { c in
                c.set("dt", .float(Double(c.dt)))
            },
            VSNode.pure("time.elapsed", "Time", "Time", "Seconds since play started.", [], [VSPin("time", .float)]) { c in
                c.set("time", .float(c.world.time.elapsed))
            },
            VSNode.pure("input.keyDown", "Key Down", "Input", "Whether `key` (config) is held.",
                        config: [VisualScriptConfigKey("key", options: keys)], [], [VSPin("down", .bool)]) { c in
                let key = c.configString("key").flatMap(Key.init(rawValue:))
                c.set("down", .bool(key.map { c.host.input?.isDown($0) ?? false } ?? false))
            },
            VSNode.pure("input.axis", "Key Axis", "Input", "-1 while `negative` is held, +1 for `positive` (config keys), else 0.",
                        config: [VisualScriptConfigKey("negative", options: keys), VisualScriptConfigKey("positive", options: keys)],
                        [], [VSPin("value", .float)]) { c in
                @MainActor func down(_ key: String) -> Bool {
                    c.configString(key).flatMap(Key.init(rawValue:)).map { c.host.input?.isDown($0) ?? false } ?? false
                }
                c.set("value", .float((down("positive") ? 1 : 0) - (down("negative") ? 1 : 0)))
            },
            VSNode.pure("input.wasd", "Move Input", "Input", "WASD / arrow keys as a vector: x right, y forward (length up to 1).",
                        [], [VSPin("vector", .vec2)]) { c in
                guard let input = c.host.input else { c.set("vector", .vec2(.zero)); return }
                let x = input.axis(negative: .a, positive: .d) + input.axis(negative: .left, positive: .right)
                let y = input.axis(negative: .s, positive: .w) + input.axis(negative: .down, positive: .up)
                var v = Vec2(max(min(x, 1), -1), max(min(y, 1), -1))
                let l = (v.x * v.x + v.y * v.y).squareRoot()
                if l > 1 { v /= l }
                c.set("vector", .vec2(v))
            },
            VSNode.pure("input.actionDown", "Action Down", "Input", "Whether the input action `action` (graph `actions`) is held.",
                        config: [VisualScriptConfigKey("action")], [], [VSPin("down", .bool)]) { c in
                c.set("down", .bool(c.instance.actions?.isPressed(c.configString("action") ?? "") ?? false))
            },
            VSNode.pure("input.mousePosition", "Mouse Position", "Input", "The mouse position in window points.", [], [VSPin("position", .vec2)]) { c in
                c.set("position", .vec2(c.host.input?.mousePosition ?? .zero))
            },
        ]
    }
}

