import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Visual scripts: the .vscript format, validation, the VM (events, flow, data, latent nodes,
// functions, hot reload, runaway protection), world and component nodes, Swift interop and the importer.

struct VisualScriptTestsHealth: Component, Equatable {
    static let componentName = "VisualScriptTests.Health"
    var points: Float = 100
    var label: String = "hero"

    init(points: Float = 100, label: String = "hero") {
        self.points = points
        self.label = label
    }

    // Decodes from {} so visual scripts can list its fields without an Add Component factory.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        points = try c.decodeIfPresent(Float.self, forKey: .points) ?? 100
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? "hero"
    }
}

private func decode(_ json: String) throws -> VisualScriptGraph {
    try VisualScriptGraph.decode(Data(json.utf8))
}

private func node(_ id: String, _ type: String, config: [String: JSONValue] = [:], inputs: [String: JSONValue] = [:]) -> VisualScriptNode {
    VisualScriptNode(id: id, type: type, config: config, inputs: inputs)
}

private func link(_ from: String, _ to: String) -> VisualScriptLink { VisualScriptLink(from: from, to: to) }

/// A world with one entity running `graph`, its runtime and the log.
@MainActor
private final class Rig {
    let world = World()
    let host = VisualScriptHost()
    let runtime: VisualScriptRuntime
    let entity: Entity
    var lines: [String] = []

    init(_ graph: VisualScriptGraph, components: [any Component] = []) {
        host.log = { _ in }
        runtime = world.addVisualScripts(host: host)
        runtime.graphs["g"] = graph
        entity = world.spawn(Transform(), Name("Hero"), VisualScript(graph: "g"))
        for component in components { world.add(component, to: entity) }
        host.log = { [unowned self] in lines.append($0) }
    }

    func step(_ frames: Int = 1, dt: Double = 1.0 / 60) {
        for _ in 0..<frames { world.update(dt: dt) }
    }

    func variable(_ name: String) -> VisualScriptValue? { runtime.variable(name, of: entity) }
}

@MainActor
@Suite struct VisualScriptTests {
    // MARK: Format

    @Test func everyKeyIsOptionalAndRoundTrips() throws {
        let empty = try decode("{}")
        #expect(empty == VisualScriptGraph())
        let graph = try decode("""
            {"variables": [{"name": "speed", "default": 2}],
             "nodes": [{"id": "a", "type": "event.update"}, {"type": "debug.log", "id": "b", "inputs": {"message": "hi"}}],
             "links": [["a.out", "b.in"]]}
            """)
        #expect(graph.variables[0].type == .float)
        #expect(graph.links == [link("a.out", "b.in")])
        #expect(graph.nodes[1].inputs["message"] == .string("hi"))
        let again = try VisualScriptGraph.decode(graph.fileData())
        #expect(again == graph)
        #expect(VisualScriptPinRef("node.pin.with.dots")?.pin == "pin.with.dots")
        #expect(VisualScriptPinRef("nodot") == nil)
    }

    @Test func valuesConvert() {
        #expect(VisualScriptValue.int(3).converted(to: .float) == .float(3))
        #expect(VisualScriptValue.float(2.5).converted(to: .string) == .string("2.5"))
        #expect(VisualScriptValue(json: .array([.int(1), .int(2), .int(3)]), as: .vec3) == .vec3(Vec3(1, 2, 3)))
        #expect(VisualScriptValue(json: .string("#FF0000"), as: .color) == .vec4(Vec4(1, 0, 0, 1)))
        #expect(VisualScriptValue(json: .string("nope"), as: .vec3) == nil)
        #expect(VisualScriptType.int.converts(to: .float))
        #expect(!VisualScriptType.vec3.converts(to: .entity))
        #expect(!VisualScriptType.exec.converts(to: .any))
    }

    // MARK: Validation

    @Test func validationFindsProblems() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "hp", type: .float)],
            nodes: [
                node("start", "event.start"),
                node("bogus", "no.such.node"),
                node("pos", "transform.getPosition"),
                node("branch", "flow.branch"),
                node("lonely", "debug.log"),
                node("snd", "audio.play"),
                node("get", "var.get", config: ["variable": .string("missing")]),
                node("log", "debug.log", inputs: ["message": .int(1)]),
            ],
            links: [
                link("start.out", "branch.in"),
                link("pos.position", "branch.condition"),  // vec3 → bool: mismatch
                link("branch.true", "snd.in"),
                link("branch.in", "log.in"),  // from an input
            ])
        let issues = VisualScriptValidator.validate(graph)
        func has(_ node: String, _ text: String) -> Bool { issues.contains { $0.node == node && $0.message.contains(text) } }
        #expect(has("bogus", "unknown node type"))
        #expect(has("branch", "type mismatch"))
        #expect(has("snd", "required input 'sound'"))
        #expect(has("lonely", "never runs"))
        #expect(has("get", "no variable named 'missing'"))
        #expect(has("branch", "is an input"))
        #expect(issues.contains { $0.severity == .info && $0.node == "get" })
    }

    // MARK: Running

    @Test func updateEventMovesTheEntity() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "speed", type: .float, defaultValue: .int(2))],
            nodes: [node("tick", "event.update"), node("speed", "var.get", config: ["variable": .string("speed")]),
                    node("mul", "math.multiply"), node("vec", "vec3.make"),
                    node("move", "transform.translate")],
            links: [link("tick.out", "move.in"), link("tick.dt", "mul.a"), link("speed.value", "mul.b"),
                    link("mul.result", "vec.x"), link("vec.vector", "move.offset")])
        #expect(VisualScriptValidator.validate(graph).filter { $0.severity != .info }.isEmpty)
        let rig = Rig(graph)
        rig.step(30, dt: 0.1)
        let x = rig.world.get(Transform.self, for: rig.entity)!.position.x
        #expect(abs(x - 6) < 1e-3)
    }

    @Test func flowNodesAndVariables() {
        // start: for 1...4 { sum += i }; branch sum > 5 → log; sequence; flip-flop twice; do once twice.
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "sum", type: .int), VisualScriptVariable(name: "flips", type: .string),
                        VisualScriptVariable(name: "once", type: .int)],
            nodes: [
                node("start", "event.start"),
                node("loop", "flow.forLoop", inputs: ["first": .int(1), "last": .int(4)]),
                node("sum", "var.get", config: ["variable": .string("sum")]),
                node("add", "math.add"),
                node("set", "var.set", config: ["variable": .string("sum")]),
                node("gt", "compare.greater", inputs: ["b": .int(5)]),
                node("branch", "flow.branch"),
                node("log", "debug.log"),
                node("fmt", "string.format", inputs: ["format": .string("sum is {a}")]),
                node("seq", "flow.sequence", config: ["count": .int(3)]),
                node("ff", "flow.flipFlop"),
                node("flips", "var.get", config: ["variable": .string("flips")]),
                node("join", "string.join"),
                node("setFlips", "var.set", config: ["variable": .string("flips")]),
                node("once", "flow.doOnce"),
                node("onceVal", "var.get", config: ["variable": .string("once")]),
                node("inc", "math.add", inputs: ["b": .int(1)]),
                node("setOnce", "var.set", config: ["variable": .string("once")]),
            ],
            links: [
                link("start.out", "loop.in"),
                link("loop.body", "set.in"), link("sum.value", "add.a"), link("loop.index", "add.b"), link("add.result", "set.value"),
                link("loop.done", "branch.in"), link("sum.value", "gt.a"), link("gt.result", "branch.condition"),
                link("branch.true", "log.in"), link("sum.value", "fmt.a"), link("fmt.text", "log.message"),
                link("log.out", "seq.in"),
                link("seq.out0", "ff.in"), link("seq.out1", "ff.in"), link("seq.out2", "once.in"),
                link("ff.a", "setFlips.in"), link("ff.b", "setFlips.in"),
                link("flips.value", "join.a"), link("ff.isA", "join.b"), link("join.text", "setFlips.value"),
                link("once.out", "setOnce.in"), link("onceVal.value", "inc.a"), link("inc.result", "setOnce.value"),
            ])
        let rig = Rig(graph)
        rig.step()
        #expect(rig.variable("sum") == .int(10))
        #expect(rig.lines.contains { $0.hasSuffix("sum is 10") })
        #expect(rig.variable("flips") == .string("truefalse"))
        #expect(rig.variable("once") == .int(1))
    }

    @Test func delayContinuesLaterAndIgnoresRetriggers() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "fired", type: .int)],
            nodes: [node("tick", "event.update"), node("wait", "flow.delay", inputs: ["seconds": .double(0.5)]),
                    node("get", "var.get", config: ["variable": .string("fired")]), node("inc", "math.add", inputs: ["b": .int(1)]),
                    node("set", "var.set", config: ["variable": .string("fired")])],
            links: [link("tick.out", "wait.in"), link("wait.out", "set.in"), link("get.value", "inc.a"), link("inc.result", "set.value")])
        let rig = Rig(graph)
        rig.step(4, dt: 0.1)
        #expect(rig.variable("fired") == .int(0))
        rig.step(2, dt: 0.1)
        #expect(rig.variable("fired") == .int(1))
        rig.step(5, dt: 0.1)
        #expect(rig.variable("fired") == .int(2))
    }

    @Test func functionsAndHotReload() {
        var graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "out", type: .float), VisualScriptVariable(name: "starts", type: .int)],
            nodes: [node("start", "event.start"), node("starts", "var.get", config: ["variable": .string("starts")]),
                    node("inc", "math.add", inputs: ["b": .int(1)]), node("setStarts", "var.set", config: ["variable": .string("starts")]),
                    node("tick", "event.update"),
                    node("call", "function.call", config: ["function": .string("double")], inputs: ["x": .double(21)]),
                    node("set", "var.set", config: ["variable": .string("out")])],
            links: [link("start.out", "setStarts.in"), link("starts.value", "inc.a"), link("inc.result", "setStarts.value"),
                    link("tick.out", "call.in"), link("call.out", "set.in"), link("call.y", "set.value")],
            functions: [VisualScriptFunction(
                name: "double", inputs: [VisualScriptParameter(name: "x")], outputs: [VisualScriptParameter(name: "y")],
                nodes: [node("entry", "function.entry"), node("mul", "math.multiply", inputs: ["b": .int(2)]), node("ret", "function.return")],
                links: [link("entry.out", "ret.in"), link("entry.x", "mul.a"), link("mul.result", "ret.y")])])
        #expect(VisualScriptValidator.validate(graph).filter { $0.severity == .error }.isEmpty)
        let rig = Rig(graph)
        rig.step()
        #expect(rig.variable("out") == .float(42))
        #expect(rig.variable("starts") == .int(1))

        // Edit the function while running: variables stay, start doesn't run again.
        graph.functions[0].nodes[1].inputs["b"] = .int(3)
        rig.runtime.graphs["g"] = graph
        rig.step()
        #expect(rig.variable("out") == .float(63))
        #expect(rig.variable("starts") == .int(1))
    }

    @Test func runawayLoopsStopWithAnError() {
        let graph = VisualScriptGraph(
            nodes: [node("start", "event.start"), node("loop", "flow.while", inputs: ["condition": .bool(true)]), node("log", "debug.log")],
            links: [link("start.out", "loop.in"), link("loop.body", "log.in")])
        let rig = Rig(graph)
        rig.runtime.stepLimit = 1000
        rig.step()
        #expect(rig.runtime.instances[rig.entity]?.halted == true)
        #expect(rig.runtime.errors.contains { $0.contains("endless loop") })
    }

    @Test func customEventsBetweenGraphsAndSwift() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "got", type: .float)],
            nodes: [node("on", "event.custom", config: ["name": .string("hit")]),
                    node("set", "var.set", config: ["variable": .string("got")]),
                    node("start", "event.start"),
                    node("send", "event.send", config: ["name": .string("ready")], inputs: ["value": .int(7)])],
            links: [link("on.out", "set.in"), link("on.value", "set.value"), link("start.out", "send.in")])
        let rig = Rig(graph)
        var heard: [VisualScriptValue] = []
        rig.runtime.onEvent("ready") { _, value in heard.append(value) }
        rig.step()
        #expect(heard == [.int(7)])
        #expect(rig.world.sendScriptEvent("hit", to: rig.entity, value: .float(12)))
        #expect(rig.variable("got") == .float(12))
    }

    @Test func componentFieldsThroughReflection() {
        ComponentRegistry.register(VisualScriptTestsHealth.self)
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "seen", type: .float)],
            nodes: [node("start", "event.start"),
                    node("get", "component.get", config: ["component": .string("VisualScriptTests.Health"), "field": .string("points")]),
                    node("half", "math.divide", inputs: ["b": .int(2)]),
                    node("set", "component.set", config: ["component": .string("VisualScriptTests.Health"), "field": .string("points")]),
                    node("remember", "var.set", config: ["variable": .string("seen")])],
            links: [link("start.out", "set.in"), link("get.value", "half.a"), link("half.result", "set.value"),
                    link("set.out", "remember.in"), link("get.value", "remember.value")])
        let issues = VisualScriptValidator.validate(graph).filter { $0.severity != .info }
        #expect(issues.isEmpty, "\(issues)")
        let rig = Rig(graph, components: [VisualScriptTestsHealth(points: 80)])
        rig.step()
        #expect(rig.world.get(VisualScriptTestsHealth.self, for: rig.entity)?.points == 40)
        #expect(rig.variable("seen") == .float(40))

        let catalog = VisualScriptNodes.catalog(search: "VisualScriptTests.Health")
        #expect(catalog.contains { $0.type == "component.get" && $0.config?["field"] == .string("label") && $0.outputs.first?.type == .string })
        #expect(catalog.contains { $0.type == "component.set" && $0.config?["field"] == .string("points") })
    }

    @Test func worldNodesSpawnFindAndDestroy() {
        let graph = VisualScriptGraph(
            nodes: [node("start", "event.start"),
                    node("spawn", "world.spawn", inputs: ["name": .string("Coin"), "position": .array([.int(1), .int(2), .int(3)])]),
                    node("find", "world.findByName", inputs: ["name": .string("Hero")]),
                    node("kill", "world.destroy")],
            links: [link("start.out", "spawn.in"), link("spawn.out", "kill.in"), link("find.entity", "kill.entity")])
        let rig = Rig(graph)
        rig.step()
        #expect(!rig.world.isAlive(rig.entity))
        var coin: Entity?
        rig.world.query(Name.self) { e, n in if n.value == "Coin" { coin = e } }
        #expect(coin.flatMap { rig.world.get(Transform.self, for: $0)?.position } == Vec3(1, 2, 3))
        rig.step()
        #expect(rig.runtime.instances.isEmpty)
    }

    @Test func tweenAndTimerEvents() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "ticks", type: .int), VisualScriptVariable(name: "done", type: .bool)],
            nodes: [node("start", "event.start"),
                    node("tween", "tween.transform", config: ["property": .string("position"), "ease": .string("linear")],
                         inputs: ["to": .array([.int(10), .int(0), .int(0)]), "duration": .double(1)]),
                    node("finished", "var.set", config: ["variable": .string("done")], inputs: ["value": .bool(true)]),
                    node("timer", "event.timer", config: ["interval": .double(0.25)]),
                    node("ticks", "var.get", config: ["variable": .string("ticks")]),
                    node("inc", "math.add", inputs: ["b": .int(1)]),
                    node("set", "var.set", config: ["variable": .string("ticks")])],
            links: [link("start.out", "tween.in"), link("tween.done", "finished.in"),
                    link("timer.out", "set.in"), link("ticks.value", "inc.a"), link("inc.result", "set.value")])
        let rig = Rig(graph)
        rig.step(5, dt: 0.1)
        let x = rig.world.get(Transform.self, for: rig.entity)!.position.x
        #expect(abs(x - 5) < 0.05)
        #expect(rig.variable("done") == .bool(false))
        rig.step(6, dt: 0.1)
        #expect(rig.world.get(Transform.self, for: rig.entity)!.position.x == 10)
        #expect(rig.variable("done") == .bool(true))
        #expect(rig.variable("ticks") == .int(4))
    }

    @Test func keyEventsAndMoveInput() {
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "jumps", type: .int), VisualScriptVariable(name: "move", type: .vec2)],
            nodes: [node("key", "event.keyPressed", config: ["key": .string("space")]),
                    node("jumps", "var.get", config: ["variable": .string("jumps")]), node("inc", "math.add", inputs: ["b": .int(1)]),
                    node("set", "var.set", config: ["variable": .string("jumps")]),
                    node("tick", "event.update"), node("wasd", "input.wasd"), node("setMove", "var.set", config: ["variable": .string("move")])],
            links: [link("key.out", "set.in"), link("jumps.value", "inc.a"), link("inc.result", "set.value"),
                    link("tick.out", "setMove.in"), link("wasd.vector", "setMove.value")])
        let rig = Rig(graph)
        let input = Input()
        rig.host.input = input
        input.beginFrame()
        input.inject(.key(.space, down: true))
        input.inject(.key(.d, down: true))
        input.endEvents()
        rig.step()
        #expect(rig.variable("jumps") == .int(1))
        #expect(rig.variable("move") == .vec2(Vec2(1, 0)))
        input.beginFrame()
        input.endEvents()
        rig.step()
        #expect(rig.variable("jumps") == .int(1))
    }

    @Test func collisionEventsReachBothEntities() {
        let world = World()
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        let host = VisualScriptHost()
        host.physics = { physics }
        host.log = { _ in }
        let runtime = world.addVisualScripts(host: host)
        runtime.graphs["g"] = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "hits", type: .int)],
            nodes: [node("hit", "event.collisionEnter"), node("hits", "var.get", config: ["variable": .string("hits")]),
                    node("inc", "math.add", inputs: ["b": .int(1)]), node("set", "var.set", config: ["variable": .string("hits")])],
            links: [link("hit.out", "set.in"), link("hits.value", "inc.a"), link("inc.result", "set.value")])
        let ground = world.spawn(Transform(), Collider(.box(halfExtents: Vec3(5, 0.5, 5))), RigidBody(.static), VisualScript(graph: "g"))
        let ball = world.spawn(Transform(position: Vec3(0, 1.2, 0)), Collider(.sphere(radius: 0.5)), RigidBody(.dynamic), VisualScript(graph: "g"))
        for _ in 0..<60 { world.update(dt: 1.0 / 60) }
        #expect(runtime.variable("hits", of: ball) == .int(1))
        #expect(runtime.variable("hits", of: ground) == .int(1))
    }

    @Test func gameModuleNodesAndEvents() {
        let module = GameModule()
        module.name = "VisualScriptTestsGame"
        module.scriptNode("vstests.triple", title: "Triple", inputs: [VisualScriptPin("x", .float)], outputs: [VisualScriptPin("y", .float)],
                          pure: true) { node in
            node.set("y", .float(try node.double("x") * 3))
        }
        module.scriptEvent("vstests.ping")
        defer { VisualScriptNodes.unregister(owner: module.scriptNodeOwner) }
        #expect(VisualScriptNodes.definition("vstests.triple")?.kind == .pure)
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "y", type: .float), VisualScriptVariable(name: "pinged", type: .bool)],
            nodes: [node("start", "event.start"), node("triple", "vstests.triple", inputs: ["x": .int(5)]),
                    node("set", "var.set", config: ["variable": .string("y")]),
                    node("ping", "event.vstests.ping"), node("setPing", "var.set", config: ["variable": .string("pinged")], inputs: ["value": .bool(true)])],
            links: [link("start.out", "set.in"), link("triple.y", "set.value"), link("ping.out", "setPing.in")])
        let rig = Rig(graph)
        rig.step()
        #expect(rig.variable("y") == .float(15))
        rig.world.sendScriptEvent("vstests.ping")
        #expect(rig.variable("pinged") == .bool(true))
        VisualScriptNodes.unregister(owner: module.scriptNodeOwner)
        #expect(VisualScriptNodes.definition("vstests.triple") == nil)
    }

    // MARK: Assets

    @Test func importerRunsGraphsFromTheProjectAndHotReloads() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let project = try Project.create(at: url, name: "VisualScript")
        let database = AssetDatabase(project: project)
        var graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "value", type: .float)],
            nodes: [node("tick", "event.update"), node("set", "var.set", config: ["variable": .string("value")], inputs: ["value": .int(1)])],
            links: [link("tick.out", "set.in")])
        let id = try database.createVisualScript(graph, at: "Scripts/counter.vscript")
        #expect(database.record(id)?.importer == "vscript")
        #expect(database.visualScript(of: id) == graph)

        let world = World()
        let host = VisualScriptHost()
        host.assets = { database }
        host.log = { _ in }
        let runtime = world.addVisualScripts(host: host)
        let byID = world.spawn(Transform(), VisualScript(graph: AssetReference(id).description))
        let byPath = world.spawn(Transform(), VisualScript(graph: "Scripts/counter.vscript", variables: ["value": .int(5)]))
        world.update(dt: 1.0 / 60)
        #expect(runtime.variable("value", of: byID) == .float(1))
        #expect(runtime.variable("value", of: byPath) == .float(1))

        graph.nodes[1].inputs["value"] = .int(2)
        let warnings = try database.writeVisualScript(graph, to: id)
        #expect(warnings.isEmpty)
        world.update(dt: 1.0 / 60)
        #expect(runtime.variable("value", of: byID) == .float(2))

        // A broken graph imports with warnings.
        graph.nodes.append(node("x", "nope"))
        let broken = try database.writeVisualScript(graph, to: id)
        #expect(broken.contains { $0.contains("unknown node type 'nope'") })
        world.removeVisualScripts(runtime)
        #expect(!world.systemNames(in: .update).contains("vscript.update"))
    }

    @Test func backgroundImportsGetTheFullChecks() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let project = try Project.create(at: url, name: "VisualScriptBackground")
        let database = AssetDatabase(project: project)
        var warnings: [String] = []
        database.onChange = { warnings += $0.warnings }
        let graph = VisualScriptGraph(nodes: [node("start", "event.start"), node("x", "nope"), node("log", "debug.log")],
                                      links: [link("start.out", "log.in")])
        let file = project.url(forAssetPath: "Scripts/bad.vscript")
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try graph.fileData().write(to: file)
        _ = database.refreshAsync()
        #expect(database.waitForAll(timeout: 30))
        #expect(warnings.contains { $0.contains("unknown node type 'nope'") }, "\(warnings)")
        // The importer alone (any thread) only checks the structure.
        let issues = VisualScriptValidator.structuralIssues(graph)
        #expect(!issues.contains { $0.message.contains("unknown node type") })
    }

    @Test func engineNodesUseProjectAssets() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let project = try Project.create(at: url, name: "VisualScriptEngine")
        let database = AssetDatabase(project: project)
        let sound = try database.createSoundBuild(SoundBuild(), at: "Sounds/coin.sfx")
        let effect = try database.createVFX(.starter, at: "Effects/puff.vfx")
        let table = try database.createDataTable(DataTable(columns: [DataTableColumn(name: "hp", type: .number, defaultValue: .int(5))],
                                                           rows: [DataTableRow(id: "goblin", values: ["hp": .int(30)])]), at: "Data/enemies.table")
        let graph = VisualScriptGraph(
            variables: [VisualScriptVariable(name: "hp", type: .float)],
            nodes: [node("start", "event.start"),
                    node("play", "audio.play", inputs: ["sound": .string(AssetReference(sound).description)]),
                    node("puff", "vfx.spawn", inputs: ["effect": .string("Effects/puff.vfx"), "lifetime": .double(0.5)]),
                    node("cell", "table.value", inputs: ["table": .string(AssetReference(table).description), "row": .string("goblin"),
                                                         "column": .string("hp")]),
                    node("set", "var.set", config: ["variable": .string("hp")])],
            links: [link("start.out", "play.in"), link("play.out", "puff.in"), link("puff.out", "set.in"), link("cell.value", "set.value")])
        let world = World()
        let host = VisualScriptHost()
        host.assets = { database }
        var lines: [String] = []
        host.log = { lines.append($0) }
        let runtime = world.addVisualScripts(host: host)
        runtime.graphs["g"] = graph
        let entity = world.spawn(Transform(), VisualScript(graph: "g"))
        world.update(dt: 0.1)
        #expect(lines.isEmpty, "\(lines)")
        #expect(runtime.variable("hp", of: entity) == .float(30))
        var emitters = 0
        world.query(AudioEmitter.self) { _, emitter in if emitter.clip == AssetReference(sound).description { emitters += 1 } }
        #expect(emitters == 1)
        var puff: Entity?
        world.query(Name.self) { e, n in if n.value == "puff" { puff = e } }
        #expect(puff != nil)
        _ = effect
        for _ in 0..<6 { world.update(dt: 0.1) }
        #expect(puff.map(world.isAlive) == false)
    }

    @Test func breakpointsRecordTheFlowForStepping() throws {
        let graph = try decode("""
            {"variables": [{"name": "n", "type": "int"}, {"name": "ticks", "type": "int"}],
             "nodes": [
              {"id": "start", "type": "event.start"},
              {"id": "a", "type": "var.set", "config": {"variable": "n"}, "inputs": {"value": 1}, "breakpoint": true},
              {"id": "call", "type": "function.call", "config": {"function": "twice"}, "inputs": {"x": 4}},
              {"id": "b", "type": "var.set", "config": {"variable": "n"}},
              {"id": "tick", "type": "event.update"},
              {"id": "count", "type": "var.set", "config": {"variable": "ticks"}, "inputs": {"value": 7}}
             ],
             "links": [{"from": "start.out", "to": "a.in"}, {"from": "a.out", "to": "call.in"}, {"from": "call.out", "to": "b.in"},
                       {"from": "call.y", "to": "b.value"}, {"from": "tick.out", "to": "count.in"}],
             "functions": [{"name": "twice", "inputs": [{"name": "x", "type": "int"}], "outputs": [{"name": "y", "type": "int"}],
               "nodes": [{"id": "entry", "type": "function.entry"}, {"id": "mul", "type": "math.multiply", "inputs": {"b": 2}},
                         {"id": "ret", "type": "function.return"}],
               "links": [{"from": "entry.out", "to": "ret.in"}, {"from": "entry.x", "to": "mul.a"}, {"from": "mul.result", "to": "ret.y"}]}]}
            """)
        let rig = Rig(graph)
        var hits: [String] = []
        rig.host.onBreakpoint = { hits.append($0.node) }
        rig.step()
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(hits == ["a"])
        let trace = try #require(rig.runtime.trace)
        #expect(trace.steps.map(\.node) == ["a", "call", "ret", "b"])
        #expect(trace.steps.map(\.depth) == [0, 0, 1, 0])
        #expect(trace.steps[2].function == "twice")
        #expect(trace.steps[0].variables["n"] == .int(0), "variables as the node started")
        #expect(trace.steps[1].inputs["x"] == .int(4) && trace.steps[1].outputs["y"] == .int(8))
        #expect(trace.steps[3].inputs["value"] == .int(8))
        #expect(trace.next(after: 1, .into) == 2)
        #expect(trace.next(after: 1, .over) == 3)
        #expect(trace.next(after: 2, .out) == 3)
        #expect(trace.next(after: 3, .into) == nil)

        // Past the end: break at the next node this entity's graph runs (the update flow, next frame).
        rig.runtime.breakAtNextNode(of: rig.entity)
        rig.step()
        #expect(hits == ["a", "count"])
        #expect(rig.runtime.trace?.steps.map(\.node) == ["count"])
        rig.step()
        #expect(hits.count == 2, "only once")
        rig.runtime.clearTrace()
        #expect(rig.runtime.trace == nil)
    }

    @Test func functionSignaturesKeepWiresThroughRenames() throws {
        let graph = try decode("""
            {"variables": [{"name": "r", "type": "float"}],
             "nodes": [
              {"id": "start", "type": "event.start"},
              {"id": "call", "type": "function.call", "config": {"function": "scale"}, "inputs": {"x": 3, "k": 5}},
              {"id": "set", "type": "var.set", "config": {"variable": "r"}}
             ],
             "links": [{"from": "start.out", "to": "call.in"}, {"from": "call.out", "to": "set.in"}, {"from": "call.y", "to": "set.value"}],
             "functions": [{"name": "scale", "inputs": [{"name": "x"}, {"name": "k"}], "outputs": [{"name": "y"}],
               "nodes": [{"id": "entry", "type": "function.entry"}, {"id": "mul", "type": "math.multiply", "inputs": {"b": 2}},
                         {"id": "ret", "type": "function.return"}],
               "links": [{"from": "entry.out", "to": "ret.in"}, {"from": "entry.x", "to": "mul.a"}, {"from": "entry.k", "to": "mul.b"},
                         {"from": "mul.result", "to": "ret.y"}]}]}
            """)
        // Rename x → value and y → result, drop k, add an int output.
        let edited = try graph.applying(VisualScriptEdit(signatures: [VisualScriptFunctionSignature(
            function: "scale", inputs: [VisualScriptParameter(name: "value")],
            outputs: [VisualScriptParameter(name: "result"), VisualScriptParameter(name: "count", type: .int)],
            renamedInputs: ["x": "value"], renamedOutputs: ["y": "result"])])).graph
        let function = try #require(edited.function("scale"))
        #expect(function.inputs.map(\.name) == ["value"] && function.outputs.map(\.name) == ["result", "count"])
        #expect(Set(function.links) == [link("entry.out", "ret.in"), link("entry.value", "mul.a"), link("mul.result", "ret.result")])
        #expect(edited.links.contains(link("call.result", "set.value")))
        #expect(edited.node("call")?.inputs == ["value": .int(3)], "literals follow the rename; the removed pin's goes")
        #expect(VisualScriptValidator.validate(edited).filter { $0.severity == .error }.isEmpty, "\(VisualScriptValidator.validate(edited))")
        let rig = Rig(edited)
        rig.step()
        #expect(rig.variable("r") == .float(6))

        #expect(throws: VisualScriptEditError.self) {
            try graph.applying(VisualScriptEdit(signatures: [VisualScriptFunctionSignature(function: "scale", inputs: [
                VisualScriptParameter(name: "a"), VisualScriptParameter(name: "a")])]))
        }
        #expect(throws: VisualScriptEditError.self) {
            try graph.applying(VisualScriptEdit(signatures: [VisualScriptFunctionSignature(function: "scale", outputs: [VisualScriptParameter(name: "out")])]))
        }
    }

    @Test func collapsingAFlowThatEndsInsideKeepsItsOutputs() throws {
        // start → s1 (n = 4) ends the flow; dbl reads s1 and update stores dbl into m.
        let graph = try decode("""
            {"variables": [{"name": "n", "type": "int"}, {"name": "m", "type": "int"}],
             "nodes": [
              {"id": "start", "type": "event.start"},
              {"id": "s1", "type": "var.set", "config": {"variable": "n"}, "inputs": {"value": 4}},
              {"id": "dbl", "type": "math.multiply", "inputs": {"b": 2}},
              {"id": "tick", "type": "event.update"},
              {"id": "s2", "type": "var.set", "config": {"variable": "m"}}
             ],
             "links": [{"from": "start.out", "to": "s1.in"}, {"from": "s1.value", "to": "dbl.a"},
                       {"from": "tick.out", "to": "s2.in"}, {"from": "dbl.result", "to": "s2.value"}]}
            """)
        let original = Rig(graph)
        original.step()
        #expect(original.variable("m") == .int(8))

        let collapsed = try graph.collapsingToFunction(["s1", "dbl"], name: "setup")
        let function = try #require(collapsed.function("setup"))
        #expect(!function.pure && function.outputs.map(\.name) == ["result"])
        #expect(!function.links.contains { $0.to == "return.in" }, "no exec wire leaves: the flow ends inside")
        let issues = VisualScriptValidator.validate(collapsed).filter { $0.severity != .info }
        #expect(issues.isEmpty, "\(issues)")
        let rig = Rig(collapsed)
        rig.step()
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(rig.variable("n") == .int(4))
        #expect(rig.variable("m") == .int(8), "the call's output is what reaches Return when the flow ends, not zero")
    }

    @Test func componentDefaultsListExposedVariables() {
        let graph = VisualScriptGraph(variables: [VisualScriptVariable(name: "speed", type: .float, defaultValue: .int(3)),
                                                  VisualScriptVariable(name: "secret", type: .int, exposed: false)])
        let component = VisualScript(graph: "asset:x", defaults: graph)
        #expect(component.variables == ["speed": .int(3)])
        #expect(component.fields().contains { $0.name == "variables" })
    }
}
