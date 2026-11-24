import Foundation
import EngineAudio
import EngineCore
import EnginePhysics
import EngineScene

// The visual script VM: runs the graphs of a world's `VisualScript` components.
//
// - Each entity with a `VisualScript` gets an instance: its graph's program, its variables
//   (graph defaults, overridden by the component's `variables`), the last values of its nodes'
//   outputs, per-node state (gates, do-once, flip-flops) and pending latent actions (delays,
//   tweens).
// - Events (start, update, keys, collisions, custom events, timers…) run the matching event
//   nodes: the flow walks exec wires node by node; a node reads its inputs by pulling values
//   along data wires (pure nodes are computed on demand, once per node that reads them).
// - A graph whose file changes (hot reload) is swapped in on the next frame: variables are kept
//   by name, pending delays continue at the same node ids, start doesn't run again.
// - Runaway graphs (an endless while loop, unbounded recursion) are stopped with an error after
//   `stepLimit` node runs in one event, and that instance is halted until its graph changes.

/// What scripts can reach besides the world: set by the host (the editor's play mode, a
/// standalone game). Every property is optional; nodes needing a missing one report it.
@MainActor
public final class VisualScriptHost {
    /// Where graphs, sounds, prefabs and tables load from.
    public var assets: () -> AssetDatabase? = { nil }
    /// The game's input (keys, mouse, gamepads).
    public var input: Input?
    public var physics: () -> PhysicsWorld? = { nil }
    public var physics2D: () -> PhysicsWorld2D? = { nil }
    /// Writes a line to the host's log (the console).
    public var log: @MainActor (String) -> Void = { print($0) }
    /// Switches scenes after this frame (`GameContext.loadScene`).
    public var loadScene: (@MainActor (String) -> Void)?
    /// Starts the current scene over.
    public var reloadScene: (@MainActor () -> Void)?
    /// Called when a node with `breakpoint` runs (the editor pauses after the frame).
    public var onBreakpoint: (@MainActor (VisualScriptBreak) -> Void)?
    /// Objects higher modules hand their nodes (a tween system, a dialogue runner…), by name.
    public var services: [String: AnyObject] = [:]

    public init() {}
}

/// Where a breakpoint was hit.
public struct VisualScriptBreak: Equatable, Sendable {
    /// The graph's key (its `VisualScript.graph`).
    public var graph: String
    public var node: String
    public var entity: Entity
}

/// One node run recorded after a breakpoint, for stepping through the flow while paused
/// (`VisualScriptRuntime.trace`).
public struct VisualScriptTraceStep: Equatable, Sendable {
    /// The graph's key and the entity running it.
    public var graph: String
    public var entity: Entity
    /// The function the node is in (nil: the event graph).
    public var function: String?
    public var node: String
    /// Function calls deep (0: the event graph): step over skips deeper steps, step out goes shallower.
    public var depth: Int
    /// The graph's variables as the node started.
    public var variables: [String: VisualScriptValue]
    /// The values the node read and produced (data pins).
    public var inputs: [String: VisualScriptValue] = [:]
    public var outputs: [String: VisualScriptValue] = [:]
    /// The error the node stopped with, if any.
    public var error: String?
}

/// The flow after a breakpoint, node by node, to the end of the event that hit it.
///
/// Why a trace and not a suspended VM: flows run on the Swift call stack inside the world's
/// synchronous update (node code calls `fire` for sequences, loops and branches; `function.call`
/// and custom events nest whole flows; game modules' `scriptNode` closures are synchronous and
/// public), and the systems after the scripts in the same frame (physics, animation, rendering)
/// can't wait half way through `World.update`. Suspending mid-event would mean rewriting every
/// node as a resumable state machine and splitting the world's frame. Instead the VM records
/// every node of the breakpoint's flow (with its inputs, outputs and the variables), the editor
/// pauses after the frame and steps through the record, and past its end the VM breaks on the
/// next node it runs (`breakAtNextNode`), so stepping carries on across frames.
public struct VisualScriptTrace: Equatable, Sendable {
    public var hit: VisualScriptBreak
    public var steps: [VisualScriptTraceStep]
    /// More nodes ran than `VisualScriptRuntime.traceLimit`; the rest weren't recorded.
    public var truncated = false

    /// The step after `index` for a debugger command, or nil when the trace ends first.
    /// `into`: the next node; `over`: the next not inside a function this one called; `out`:
    /// the next in a caller.
    public func next(after index: Int, _ mode: VisualScriptStepMode) -> Int? {
        guard steps.indices.contains(index) else { return nil }
        let depth = steps[index].depth
        return steps.indices.dropFirst(index + 1).first { i in
            switch mode {
            case .into: true
            case .over: steps[i].depth <= depth
            case .out: steps[i].depth < depth
            }
        }
    }
}

/// How to step from a paused node.
public enum VisualScriptStepMode: String, Codable, Sendable, CaseIterable {
    case into, over, out
}

/// A frame of node outputs and state: the event graph's (one per instance) or one function call's.
@MainActor
final class VSFrame {
    let body: VSCompiledBody
    var outputs: [[VisualScriptValue]]
    var epochs: [Int]
    var states: [[String: VisualScriptValue]]
    var results: [VisualScriptValue]?

    init(body: VSCompiledBody) {
        self.body = body
        outputs = body.nodes.map { node in node.outputs.map { VisualScriptValue.zero($0.type) } }
        epochs = Array(repeating: -1, count: body.nodes.count)
        states = Array(repeating: [:], count: body.nodes.count)
    }
}

/// A latent action waiting to continue the flow (a delay, a tween).
@MainActor
final class VSLatent {
    let frame: VSFrame
    let nodeID: String
    var node: Int
    let pin: String
    /// Seconds left (a delay), or nil when `update` decides.
    var remaining: Double?
    /// Called each frame with dt; returns true when done.
    var update: (@MainActor (Float) -> Bool)?
    var cancelled = false
    /// A state key of the node set to false when the latent fires (a delay's "waiting").
    var clears: String?

    init(frame: VSFrame, nodeID: String, node: Int, pin: String, remaining: Double?, update: (@MainActor (Float) -> Bool)?) {
        self.frame = frame
        self.nodeID = nodeID
        self.node = node
        self.pin = pin
        self.remaining = remaining
        self.update = update
    }
}

/// One entity's running graph.
@MainActor
public final class VisualScriptInstance {
    public let entity: Entity
    /// The graph's key (the component's `graph`).
    public let key: String
    public internal(set) var program: VisualScriptProgram
    public internal(set) var revision: Int
    /// Current variable values.
    public internal(set) var variables: [String: VisualScriptValue] = [:]
    /// The run stopped on an error (cleared when the graph changes).
    public internal(set) var halted = false
    var main: VSFrame
    var latents: [VSLatent] = []
    var started = false
    /// `event.timer` node id → seconds until it fires next.
    var timers: [String: Double] = [:]
    var actions: InputActions?

    init(entity: Entity, key: String, program: VisualScriptProgram, revision: Int, overrides: [String: JSONValue]) {
        self.entity = entity
        self.key = key
        self.program = program
        self.revision = revision
        main = VSFrame(body: program.main)
        resetVariables(keeping: [:], overrides: overrides)
        actions = program.actionBindings.map { InputActions(bindings: $0) }
    }

    func resetVariables(keeping old: [String: VisualScriptValue], overrides: [String: JSONValue]) {
        var values: [String: VisualScriptValue] = [:]
        for variable in program.graph.variables {
            if let kept = old[variable.name] {
                values[variable.name] = kept.converted(to: variable.type)
            } else if let override = overrides[variable.name], let value = VisualScriptValue(json: override, as: variable.type) {
                values[variable.name] = value
            } else {
                values[variable.name] = variable.defaultValue.flatMap { VisualScriptValue(json: $0, as: variable.type) } ?? .zero(variable.type)
            }
        }
        variables = values
    }

    /// Swaps in a new version of the graph (hot reload).
    func reload(_ program: VisualScriptProgram, revision: Int) {
        let oldStates = Dictionary(main.body.nodes.indices.map { (main.body.nodes[$0].id, main.states[$0]) }, uniquingKeysWith: { a, _ in a })
        self.program = program
        self.revision = revision
        let frame = VSFrame(body: program.main)
        for (i, node) in program.main.nodes.enumerated() { if let state = oldStates[node.id] { frame.states[i] = state } }
        let oldFrame = main
        main = frame
        resetVariables(keeping: variables, overrides: [:])
        latents = latents.compactMap { latent in
            guard latent.frame === oldFrame, let index = program.main.index[latent.nodeID] else { return nil }
            let moved = VSLatent(frame: frame, nodeID: latent.nodeID, node: index, pin: latent.pin, remaining: latent.remaining,
                                 update: latent.update)
            moved.clears = latent.clears
            return moved
        }
        timers = timers.filter { program.main.index[$0.key] != nil }
        actions = program.actionBindings.map { InputActions(bindings: $0) }
        halted = false
    }

    /// The last values of a node's outputs in the event graph (for the editor's pin hover).
    public func outputs(of nodeID: String) -> [String: VisualScriptValue] {
        guard let i = main.body.index[nodeID] else { return [:] }
        let node = main.body.nodes[i]
        var result: [String: VisualScriptValue] = [:]
        for (p, pin) in node.outputs.enumerated() where pin.type != .exec { result[pin.name] = main.outputs[i][p] }
        return result
    }

    /// Latent actions waiting (delays, tweens).
    public var pendingCount: Int { latents.count }
}

/// What a node's code gets: its inputs and outputs, the entity, the world and the host.
@MainActor
public final class VisualScriptNodeContext {
    public let runtime: VisualScriptRuntime
    public let instance: VisualScriptInstance
    let frame: VSFrame
    let node: Int
    /// The exec input the flow came in on ("in" for most nodes; gates have several).
    public let trigger: String

    init(runtime: VisualScriptRuntime, instance: VisualScriptInstance, frame: VSFrame, node: Int, trigger: String) {
        self.runtime = runtime
        self.instance = instance
        self.frame = frame
        self.node = node
        self.trigger = trigger
    }

    public var world: World { runtime.world }
    /// The entity whose `VisualScript` runs the graph.
    public var entity: Entity { instance.entity }
    public var host: VisualScriptHost { runtime.host }
    /// Seconds since the last frame (the fixed step in fixed update).
    public var dt: Float { runtime.world.time.delta }
    public var nodeID: String { frame.body.nodes[node].id }
    var compiled: VSCompiledNode { frame.body.nodes[node] }

    // MARK: Inputs

    /// The value of input `name`: from its wire, else its literal, else its default
    /// (converted to the pin's type). An unknown name reads as `.none`.
    public func input(_ name: String) throws -> VisualScriptValue {
        guard let i = compiled.inputIndex[name] else { return .none }
        return try runtime.pull(instance, frame, node, i)
    }

    public func float(_ name: String) throws -> Float { try input(name).asFloat }
    public func double(_ name: String) throws -> Double { try input(name).asDouble }
    public func int(_ name: String) throws -> Int { try input(name).asInt }
    public func bool(_ name: String) throws -> Bool { try input(name).asBool }
    public func string(_ name: String) throws -> String { try input(name).asString }
    public func vec2(_ name: String) throws -> Vec2 { try input(name).asVec2 }
    public func vec3(_ name: String) throws -> Vec3 { try input(name).asVec3 }
    public func vec4(_ name: String) throws -> Vec4 { try input(name).asVec4 }
    public func quat(_ name: String) throws -> Quat { try input(name).asQuat }
    public func entity(_ name: String) throws -> Entity { try input(name).asEntity }

    /// Whether input `name` has a wire into it.
    public func isConnected(_ name: String) -> Bool {
        compiled.inputIndex[name].map { compiled.dataSource[$0] != nil } ?? false
    }

    /// An entity input that must be alive.
    public func liveEntity(_ name: String) throws -> Entity {
        let e = try entity(name)
        guard world.isAlive(e) else { throw VisualScriptError("\(name): no entity") }
        return e
    }

    // MARK: Outputs

    /// Sets output `name` (read by nodes downstream, now and later).
    public func set(_ name: String, _ value: VisualScriptValue) {
        guard let p = compiled.outputIndex[name] else { return }
        frame.outputs[node][p] = value
    }

    /// Runs the flow from exec output `pin` now (sequence and loop nodes); returns when that flow
    /// ends or waits.
    public func fire(_ pin: String) throws {
        guard let p = compiled.outputIndex[pin], let next = compiled.next[p] else { return }
        try runtime.execute(instance, frame, next.node, next.pin)
    }

    /// Whether exec output `pin` is wired.
    public func isWired(_ pin: String) -> Bool {
        compiled.outputIndex[pin].map { compiled.next[$0] != nil } ?? false
    }

    // MARK: Config and state

    public func config(_ key: String) -> JSONValue? { compiled.source.config[key] }
    public func configString(_ key: String) -> String? { compiled.source.configString(key) }

    /// Values this node keeps between runs (per entity).
    public var state: [String: VisualScriptValue] {
        get { frame.states[node] }
        set { frame.states[node] = newValue }
    }

    // MARK: Latent actions

    /// Continues the flow from exec output `pin` after `seconds` of game time.
    /// `clearing` names a key of `state` set to false just before the flow continues.
    public func wait(_ seconds: Double, then pin: String = "out", clearing: String? = nil) {
        let latent = VSLatent(frame: frame, nodeID: nodeID, node: node, pin: pin, remaining: max(seconds, 0), update: nil)
        latent.clears = clearing
        instance.latents.append(latent)
    }

    /// Calls `update` every frame with dt until it returns true, then continues from `pin`.
    public func every(frame update: @escaping @MainActor (Float) -> Bool, then pin: String = "done") {
        instance.latents.append(VSLatent(frame: frame, nodeID: nodeID, node: node, pin: pin, remaining: nil, update: update))
    }

    // MARK: Variables and functions

    public func variable(_ name: String) -> VisualScriptValue? { instance.variables[name] }

    public func setVariable(_ name: String, _ value: VisualScriptValue) throws {
        guard let variable = instance.program.graph.variable(name) else { throw VisualScriptError("no variable '\(name)'") }
        instance.variables[name] = value.converted(to: variable.type)
    }

    /// Calls the graph's function `name` with `arguments` (by position); returns its results.
    public func call(function name: String, _ arguments: [VisualScriptValue]) throws -> [VisualScriptValue] {
        try runtime.call(instance, function: name, arguments)
    }

    /// Ends the current function call with `results` (`function.return`).
    public func returnFromFunction(_ results: [VisualScriptValue]) {
        frame.results = results
    }

    /// The function this node is in, if any.
    public var function: VisualScriptFunction? { frame.body.function }

    public func log(_ message: String) { runtime.host.log("[\(instance.program.name)] \(message)") }
}

/// Runs the visual scripts of one world. Install it with `World.addVisualScripts(host:)`.
@MainActor
public final class VisualScriptRuntime {
    public let world: World
    public let host: VisualScriptHost
    /// Instances by entity.
    public private(set) var instances: [Entity: VisualScriptInstance] = [:]
    /// Most node runs in one event before the run is stopped as runaway.
    public var stepLimit = 100_000
    /// Record when each node last ran (the editor's flow highlight). Off by default.
    public var recordsActivity = false
    /// Graph key → node id → `world.time.elapsed` when it last ran.
    public private(set) var activity: [String: [String: Double]] = [:]
    /// Errors reported so far (also logged), newest last; capped.
    public private(set) var errors: [String] = []
    /// The last breakpoint hit.
    public private(set) var lastBreak: VisualScriptBreak?
    /// The flow after the first breakpoint of the last frame that hit one (see `VisualScriptTrace`).
    public private(set) var trace: VisualScriptTrace?
    /// Most steps a trace records.
    public var traceLimit = 2000
    /// `breakAtNextNode`: break at the next node run by this entity's graph (`.invalid`: any graph).
    private var breakTarget: Entity?
    private var recording = false
    private var callDepth = 0
    private var frameCount = 0
    private var traceFrame = -1

    /// Breaks at the next node any graph runs (or only `entity`'s), as if it had a breakpoint:
    /// how stepping goes on past the end of a trace.
    public func breakAtNextNode(of entity: Entity? = nil) {
        breakTarget = entity ?? .invalid
    }

    /// Forgets the trace and a pending `breakAtNextNode` (the debugger resumed).
    public func clearTrace() {
        trace = nil
        breakTarget = nil
    }
    /// Seconds spent in each graph (by key) in the last frame.
    public private(set) var timings: [String: Double] = [:]

    /// Graphs given directly (tests, tools), by key; used before the asset database.
    public var graphs: [String: VisualScriptGraph] = [:] {
        didSet { graphRevision += 1 }
    }
    private var graphRevision = 0
    private var programs: [String: (revision: Int, program: VisualScriptProgram?)] = [:]
    private var listeners: [String: [@MainActor (Entity, VisualScriptValue) -> Void]] = [:]
    private var eventSources: [(name: String, poll: @MainActor (VisualScriptRuntime) -> Void)] = []
    private var epoch = 0
    private var steps = 0
    private var depth = 0
    private var pureDepth = 0
    private var startTimes: [String: UInt64] = [:]

    public init(world: World, host: VisualScriptHost = VisualScriptHost()) {
        self.world = world
        self.host = host
        VisualScriptRuntime.register(self)
    }

    // MARK: Lookup from a world

    private static var byWorld: [ObjectIdentifier: WeakRuntime] = [:]
    private final class WeakRuntime { weak var runtime: VisualScriptRuntime? ; init(_ r: VisualScriptRuntime) { runtime = r } }

    private static func register(_ runtime: VisualScriptRuntime) {
        byWorld = byWorld.filter { $0.value.runtime != nil }
        byWorld[ObjectIdentifier(runtime.world)] = WeakRuntime(runtime)
    }

    /// The runtime running `world`'s scripts, if one is installed.
    public static func runtime(for world: World) -> VisualScriptRuntime? {
        byWorld[ObjectIdentifier(world)]?.runtime
    }

    func detach() {
        if Self.byWorld[ObjectIdentifier(world)]?.runtime === self { Self.byWorld[ObjectIdentifier(world)] = nil }
        let handlers = detachHandlers
        detachHandlers.removeAll()
        for handler in handlers { handler() }
    }

    private var detachHandlers: [@MainActor () -> Void] = []

    /// Calls `handler` once when the runtime is removed (`World.removeVisualScripts`, `shutdown`):
    /// higher modules undo what their nodes set up (layouts a graph showed…).
    public func onDetach(_ handler: @escaping @MainActor () -> Void) {
        detachHandlers.append(handler)
    }

    // MARK: Swift interop

    /// Calls `handler` whenever a graph sends the custom event `name` (`event.send`), with the
    /// sending entity and the value.
    public func onEvent(_ name: String, _ handler: @escaping @MainActor (Entity, VisualScriptValue) -> Void) {
        listeners[name, default: []].append(handler)
    }

    /// Raises the custom event `name` (`event.custom` nodes with that name) on `target`'s graph,
    /// or on every graph when `target` is nil. `sender` is what the event's `sender` pin gives.
    public func send(_ name: String, to target: Entity? = nil, value: VisualScriptValue = .none, from sender: Entity = .invalid) {
        for handler in listeners[name] ?? [] { handler(sender, value) }
        let outputs: [String: VisualScriptValue] = ["sender": .entity(sender), "value": value]
        let matches: (VSCompiledNode) -> Bool = { node in
            (node.source.configString("name") ?? VisualScriptNodes.customEventNames[node.source.type]) == name
        }
        if let target {
            if let instance = instances[target] { raise("custom", on: instance, outputs: outputs, where: matches) }
        } else {
            for instance in orderedInstances() { raise("custom", on: instance, outputs: outputs, where: matches) }
        }
    }

    /// Adds code run every frame before the update event to raise events from other systems
    /// (sprite clip events, animation events…), once per `name`.
    public func addEventSource(_ name: String, _ poll: @escaping @MainActor (VisualScriptRuntime) -> Void) {
        guard !eventSources.contains(where: { $0.name == name }) else { return }
        eventSources.append((name, poll))
    }

    /// The value of a variable of `entity`'s graph.
    public func variable(_ name: String, of entity: Entity) -> VisualScriptValue? { instances[entity]?.variables[name] }

    /// Sets a variable of `entity`'s graph; false when there is no such instance or variable.
    @discardableResult
    public func setVariable(_ name: String, of entity: Entity, to value: VisualScriptValue) -> Bool {
        guard let instance = instances[entity], let variable = instance.program.graph.variable(name) else { return false }
        instance.variables[name] = value.converted(to: variable.type)
        return true
    }

    // MARK: Graphs

    /// The program for a component's `graph` value, rebuilt when its file changed. Returns its revision too.
    func program(for key: String) -> (VisualScriptProgram, Int)? {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let graph = graphs[trimmed] {
            if let cached = programs[trimmed], cached.revision == -graphRevision - 1, let program = cached.program { return (program, cached.revision) }
            let program = VisualScriptProgram(graph: graph, name: trimmed)
            programs[trimmed] = (-graphRevision - 1, program)
            return (program, -graphRevision - 1)
        }
        guard let assets = host.assets(), let id = assets.visualScriptID(for: trimmed) else { return nil }
        if assets.pack == nil { _ = assets.asset(id) }
        let revision = assets.pack == nil ? assets.revision(of: id) : 0
        if let cached = programs[trimmed], cached.revision == revision { return cached.program.map { ($0, revision) } }
        let program = assets.visualScript(of: id).map { VisualScriptProgram(graph: $0, name: assets.path(of: id) ?? trimmed) }
        programs[trimmed] = (revision, program)
        return program.map { ($0, revision) }
    }

    // MARK: Frame

    private func orderedInstances() -> [VisualScriptInstance] {
        instances.values.sorted { $0.entity.index < $1.entity.index }
    }

    /// Creates instances for new `VisualScript`s (running start), swaps in changed graphs and
    /// ends instances whose component or entity is gone (running destroy).
    public func syncInstances() {
        var present: [(Entity, VisualScript)] = []
        world.query(VisualScript.self) { entity, script in present.append((entity, script)) }
        var seen = Set<Entity>()
        var started: [VisualScriptInstance] = []
        for (entity, script) in present where script.enabled {
            guard let (program, revision) = program(for: script.graph) else { continue }
            seen.insert(entity)
            if let instance = instances[entity], instance.key == script.graph.trimmingCharacters(in: .whitespaces) {
                if instance.program !== program { instance.reload(program, revision: revision) }
            } else {
                if let old = instances[entity] { end(old) }
                let instance = VisualScriptInstance(entity: entity, key: script.graph.trimmingCharacters(in: .whitespaces),
                                                    program: program, revision: revision, overrides: script.variables)
                instances[entity] = instance
                started.append(instance)
            }
        }
        for (entity, instance) in instances where !seen.contains(entity) { end(instance) }
        for instance in started.sorted(by: { $0.entity.index < $1.entity.index }) {
            instance.started = true
            for (id, node) in instance.program.main.nodes.map({ ($0.id, $0) }) where node.definition?.event == "timer" {
                instance.timers[id] = Self.timerInterval(node)
            }
            raise("start", on: instance, outputs: [:])
        }
    }

    private func end(_ instance: VisualScriptInstance) {
        instances[instance.entity] = nil
        raise("destroy", on: instance, outputs: [:])
        for latent in instance.latents { latent.cancelled = true }
        instance.latents.removeAll()
    }

    /// Ends every instance (running destroy): the host is stopping.
    public func shutdown() {
        for instance in orderedInstances() { end(instance) }
        detach()
    }

    static func timerInterval(_ node: VSCompiledNode) -> Double {
        let value: Double
        switch node.source.config["interval"] {
        case .int(let i)?: value = Double(i)
        case .double(let d)?: value = d
        default: value = 1
        }
        return max(value, 0.001)
    }

    /// The `.update` part of a frame: instances synced, input and physics events, custom event
    /// sources, timers, the update event, then latent actions.
    public func update() {
        frameCount += 1
        timings.removeAll(keepingCapacity: true)
        syncInstances()
        let dt = world.time.delta
        let list = orderedInstances()
        if let input = host.input {
            for instance in list where !instance.halted {
                let program = instance.program
                for event in ["keyPressed", "keyReleased"] {
                    for index in program.events[event] ?? [] {
                        let node = program.main.nodes[index]
                        guard let name = node.source.configString("key"), let key = Key(rawValue: name) else { continue }
                        let hit = event == "keyPressed" ? input.wasPressed(key) : input.wasReleased(key)
                        if hit { raise(event, on: instance, outputs: [:]) { $0.id == node.id } }
                    }
                }
                if let actions = instance.actions {
                    actions.update(input)
                    for name in program.graph.actions.keys.sorted() {
                        if actions.wasPressed(name) { raise("actionPressed", on: instance, outputs: [:]) { $0.source.configString("action") == name } }
                        if actions.wasReleased(name) { raise("actionReleased", on: instance, outputs: [:]) { $0.source.configString("action") == name } }
                    }
                }
            }
        }
        if let physics = host.physics() { dispatchPhysics(physics.events.map { ($0.kind.rawValue, $0.entityA, $0.entityB, $0.point, $0.normal) }, suffix: "") }
        if let physics = host.physics2D() {
            dispatchPhysics(physics.events.map { ($0.kind.rawValue, $0.entityA, $0.entityB, Vec3($0.point.x, $0.point.y, 0), Vec3($0.normal.x, $0.normal.y, 0)) },
                            suffix: "2D")
        }
        for source in eventSources { source.poll(self) }
        updateTimedDestroys()
        for instance in list where !instance.halted && !instance.timers.isEmpty {
            for id in instance.timers.keys.sorted() {
                guard var left = instance.timers[id], let index = instance.program.main.index[id] else { continue }
                left -= Double(dt)
                let node = instance.program.main.nodes[index]
                while left <= 0 {
                    raise("timer", on: instance, outputs: [:]) { $0.id == id }
                    if node.source.config["repeat"] == .bool(false) { left = .infinity; break }
                    left += Self.timerInterval(node)
                }
                instance.timers[id] = left
            }
        }
        for instance in list where !instance.halted { raise("update", on: instance, outputs: ["dt": .float(Double(dt))]) }
        for instance in list where !instance.halted && !instance.latents.isEmpty { advanceLatents(instance, dt: dt) }
    }

    /// The `.fixedUpdate` part: the fixed update event.
    public func fixedUpdate() {
        let dt = world.time.delta
        for instance in orderedInstances() where !instance.halted && instance.program.handles("fixedUpdate") {
            raise("fixedUpdate", on: instance, outputs: ["dt": .float(Double(dt))])
        }
    }

    /// The `.lateUpdate` part: the late update event.
    public func lateUpdate() {
        let dt = world.time.delta
        for instance in orderedInstances() where !instance.halted && instance.program.handles("lateUpdate") {
            raise("lateUpdate", on: instance, outputs: ["dt": .float(Double(dt))])
        }
    }

    private func dispatchPhysics(_ events: [(kind: String, a: Entity?, b: Entity?, point: Vec3, normal: Vec3)], suffix: String) {
        for event in events {
            let name: String
            switch event.kind {
            case "collisionBegan": name = "collisionEnter"
            case "collisionEnded": name = "collisionExit"
            case "triggerEntered": name = "triggerEnter"
            case "triggerExited": name = "triggerExit"
            default: continue
            }
            for (me, other, sign) in [(event.a, event.b, Float(1)), (event.b, event.a, Float(-1))] {
                guard let me, let instance = instances[me], !instance.halted else { continue }
                raise(name + suffix, on: instance, outputs: ["other": .entity(other ?? .invalid), "point": .vec3(event.point),
                                                             "normal": .vec3(event.normal * sign)])
            }
        }
    }

    private func advanceLatents(_ instance: VisualScriptInstance, dt: Float) {
        let pending = instance.latents
        var finished: [VSLatent] = []
        for latent in pending where !latent.cancelled {
            var done = false
            if let update = latent.update { done = update(dt) }
            if var remaining = latent.remaining {
                remaining -= Double(dt)
                latent.remaining = remaining
                if remaining <= 1e-9 { done = true }
            }
            if done { finished.append(latent) }
        }
        guard !finished.isEmpty else { return }
        let ids = Set(finished.map(ObjectIdentifier.init))
        instance.latents.removeAll { ids.contains(ObjectIdentifier($0)) }
        for latent in finished where !instance.halted {
            if let key = latent.clears { latent.frame.states[latent.node][key] = .bool(false) }
            run(instance) {
                let node = latent.frame.body.nodes[latent.node]
                guard let p = node.outputIndex[latent.pin], let next = node.next[p] else { return }
                try execute(instance, latent.frame, next.node, next.pin)
            }
        }
    }

    // MARK: Running

    /// Runs the event nodes for `event` that pass `filter`, with their outputs set from `outputs`.
    public func raise(_ event: String, on instance: VisualScriptInstance, outputs: [String: VisualScriptValue],
                      filter: ((VSCompiledNodeView) -> Bool)? = nil) {
        guard let nodes = instance.program.events[event], !instance.halted || event == "destroy" else { return }
        for index in nodes {
            let frame = instance.main
            let node = frame.body.nodes[index]
            if let filter, !filter(VSCompiledNodeView(node: node)) { continue }
            for (name, value) in outputs { if let p = node.outputIndex[name] { frame.outputs[index][p] = value } }
            run(instance) {
                note(instance, frame, index)
                guard let p = node.outputIndex["out"], let next = node.next[p] else { return }
                try execute(instance, frame, next.node, next.pin)
            }
        }
    }

    private func raise(_ event: String, on instance: VisualScriptInstance, outputs: [String: VisualScriptValue],
                       where filter: @escaping (VSCompiledNode) -> Bool) {
        raise(event, on: instance, outputs: outputs, filter: { filter($0.node) })
    }

    /// Runs `body` as the start of a flow: resets the step budget, times it, reports errors.
    private func run(_ instance: VisualScriptInstance, _ body: () throws -> Void) {
        let outermost = depth == 0
        if outermost { steps = 0 }
        let profiling = outermost && Profiler.isEnabled
        if profiling { Profiler.begin("vscript \(instance.program.name)") }
        let start = outermost ? monotonicNanoseconds() : 0
        do {
            try body()
        } catch let error as VSRunaway {
            instance.halted = true
            report(instance, error.node, error.message + "; the script is stopped until its graph changes")
        } catch let error as VSNodeFailure {
            report(instance, error.node, error.message)
        } catch {
            report(instance, nil, "\(error)")
        }
        if outermost {
            timings[instance.program.name, default: 0] += Double(monotonicNanoseconds() - start) / 1e9
            recording = false
        }
        if profiling { Profiler.end() }
    }

    private func report(_ instance: VisualScriptInstance, _ node: String?, _ message: String) {
        let line = "[\(instance.program.name)]" + (node.map { " node \($0):" } ?? "") + " \(message)"
        errors.append(line)
        if errors.count > 200 { errors.removeFirst(errors.count - 200) }
        host.log(line)
    }

    private func note(_ instance: VisualScriptInstance, _ frame: VSFrame, _ index: Int) {
        guard recordsActivity, frame === instance.main else { return }
        activity[instance.key, default: [:]][frame.body.nodes[index].id] = world.time.elapsed
    }

    /// Runs action nodes from (`start`, exec input `trigger`) along the exec wires.
    func execute(_ instance: VisualScriptInstance, _ frame: VSFrame, _ start: Int, _ trigger: Int) throws {
        depth += 1
        defer { depth -= 1 }
        guard depth < 128 else { throw VSRunaway(node: frame.body.nodes[start].id, message: "flow nested too deep (recursion?)") }
        var current: (node: Int, pin: Int)? = (start, trigger)
        while let (index, pin) = current {
            steps += 1
            let node = frame.body.nodes[index]
            if steps > stepLimit { throw VSRunaway(node: node.id, message: "more than \(stepLimit) node runs in one event (endless loop?)") }
            guard let definition = node.definition, let run = definition.run, definition.kind == .action else { return }
            note(instance, frame, index)
            let stepped = breakTarget.map { $0 == .invalid || $0 == instance.entity } ?? false
            if node.source.breakpoint || stepped {
                if stepped { breakTarget = nil }
                let hit = VisualScriptBreak(graph: instance.key, node: node.id, entity: instance.entity)
                lastBreak = hit
                if traceFrame != frameCount || trace == nil {
                    trace = VisualScriptTrace(hit: hit, steps: [])
                    traceFrame = frameCount
                    recording = true
                }
                host.onBreakpoint?(hit)
            }
            let step = recording ? beginStep(instance, frame, index) : nil
            epoch += 1
            let context = VisualScriptNodeContext(runtime: self, instance: instance, frame: frame, node: index,
                                                  trigger: node.inputs.indices.contains(pin) ? node.inputs[pin].name : "in")
            let flow: VisualScriptFlow
            do {
                flow = try run(context)
            } catch let error as VisualScriptError {
                if let step { endStep(step, frame, index, error: error.message) }
                throw VSNodeFailure(node: node.id, message: error.message)
            }
            if let step { endStep(step, frame, index, error: nil) }
            switch flow {
            case .out(let name):
                guard let p = node.outputIndex[name] else { return }
                current = node.next[p]
            case .stop:
                current = nil
            }
        }
    }

    /// Records the start of a node run in the trace; returns its index.
    private func beginStep(_ instance: VisualScriptInstance, _ frame: VSFrame, _ index: Int) -> Int? {
        guard var trace, recording else { return nil }
        guard trace.steps.count < traceLimit else {
            trace.truncated = true
            self.trace = trace
            return nil
        }
        trace.steps.append(VisualScriptTraceStep(graph: instance.key, entity: instance.entity, function: frame.body.function?.name,
                                                 node: frame.body.nodes[index].id, depth: callDepth, variables: instance.variables))
        self.trace = trace
        return trace.steps.count - 1
    }

    /// Fills in what a recorded node read and produced.
    private func endStep(_ step: Int, _ frame: VSFrame, _ index: Int, error: String?) {
        guard trace?.steps.indices.contains(step) == true else { return }
        let node = frame.body.nodes[index]
        var inputs: [String: VisualScriptValue] = [:]
        for (p, pin) in node.inputs.enumerated() where pin.type != .exec {
            if let (source, out) = node.dataSource[p] {
                inputs[pin.name] = frame.outputs[source][out]
            } else if let literal = node.literal[p] {
                inputs[pin.name] = literal
            }
        }
        var outputs: [String: VisualScriptValue] = [:]
        for (p, pin) in node.outputs.enumerated() where pin.type != .exec { outputs[pin.name] = frame.outputs[index][p] }
        trace?.steps[step].inputs = inputs
        trace?.steps[step].outputs = outputs
        trace?.steps[step].error = error
    }

    /// Makes pure nodes compute again on their next read (loops re-reading a condition).
    func bumpEpoch() { epoch += 1 }

    /// The value of input `pin` of `node`, pulled along its wire (computing pure nodes).
    func pull(_ instance: VisualScriptInstance, _ frame: VSFrame, _ index: Int, _ pin: Int) throws -> VisualScriptValue {
        let node = frame.body.nodes[index]
        let type = node.inputs[pin].type
        let value: VisualScriptValue
        if let (source, out) = node.dataSource[pin] {
            let sourceNode = frame.body.nodes[source]
            if sourceNode.isPure, frame.epochs[source] != epoch {
                frame.epochs[source] = epoch
                pureDepth += 1
                defer { pureDepth -= 1 }
                guard pureDepth < 256 else { throw VSRunaway(node: sourceNode.id, message: "data wires form a loop") }
                steps += 1
                if steps > stepLimit { throw VSRunaway(node: sourceNode.id, message: "more than \(stepLimit) node runs in one event") }
                note(instance, frame, source)
                if let run = sourceNode.definition?.run {
                    let context = VisualScriptNodeContext(runtime: self, instance: instance, frame: frame, node: source, trigger: "")
                    do { _ = try run(context) } catch let error as VisualScriptError {
                        throw VSNodeFailure(node: sourceNode.id, message: error.message)
                    }
                }
            }
            value = frame.outputs[source][out]
        } else if let literal = node.literal[pin] {
            value = literal
        } else if type == .entity {
            value = .entity(instance.entity)
        } else {
            value = node.inputs[pin].defaultValue ?? .zero(type)
        }
        return type == .any ? value : value.converted(to: type)
    }

    /// Calls a function of the instance's graph.
    func call(_ instance: VisualScriptInstance, function name: String, _ arguments: [VisualScriptValue]) throws -> [VisualScriptValue] {
        guard let body = instance.program.functions[name], let function = body.function else { throw VisualScriptError("no function '\(name)'") }
        let frame = VSFrame(body: body)
        if let entry = body.entry {
            let node = body.nodes[entry]
            for (i, parameter) in function.inputs.enumerated() {
                guard let p = node.outputIndex[parameter.name] else { continue }
                frame.outputs[entry][p] = (i < arguments.count ? arguments[i] : .zero(parameter.type)).converted(to: parameter.type)
            }
            if let p = node.outputIndex["out"], let next = node.next[p] {
                callDepth += 1
                defer { callDepth -= 1 }
                try execute(instance, frame, next.node, next.pin)
            }
        }
        // A flow that ended without reaching Return (or a Return no exec wire reaches) still
        // returns what is wired into the Return node, read now.
        if frame.results == nil, let ret = body.nodes.firstIndex(where: { $0.source.type == "function.return" }) {
            epoch += 1
            let node = body.nodes[ret]
            frame.results = try function.outputs.map { parameter in
                guard let pin = node.inputIndex[parameter.name] else { return .zero(parameter.type) }
                return try pull(instance, frame, ret, pin)
            }
        }
        let results = frame.results ?? []
        return function.outputs.enumerated().map { i, parameter in
            (i < results.count ? results[i] : .zero(parameter.type)).converted(to: parameter.type)
        }
    }
}

/// A read-only look at a prepared node, for event filters.
@MainActor
public struct VSCompiledNodeView {
    let node: VSCompiledNode
    public var id: String { node.id }
    public var source: VisualScriptNode { node.source }
}

struct VSRunaway: Error {
    var node: String
    var message: String
}

struct VSNodeFailure: Error {
    var node: String
    var message: String
}
