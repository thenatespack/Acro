import EngineCore
import EngineMCP
import EngineScene
import Foundation

// A headless game as an MCP server for agent playtesting (`GameRunner <module> <scene> --mcp`):
// no window, frames run only when a tool asks, so every session is deterministic. The tools
// use the editor's names and arguments, so an agent drives both the same way:
// `play.state`, `play.step`, `input.inject`, `input.clear`, `input.action`, `input.gamepad`,
// `input.actions`, `scene.hierarchy`, `entity.find`, `entity.get`, `playtest.start`,
// `playtest.assert`, `playtest.result`, `playtest.save` and `playtest.run`. There are no
// screenshots (nothing renders); run the scene in the editor for those.

/// `input.action`'s arguments (the editor's and the headless server's).
public struct PlaytestActionArguments: Codable, Equatable, Sendable {
    /// The input action's name (`input.actions` lists them).
    public var action: String
    /// true presses and keeps it down, false releases it; omitted taps it or holds it `duration` seconds.
    public var down: Bool?
    public var duration: Double?
    /// -1…1 for an analog source (a gamepad axis); a key or button counts as pressed at |value| ≥ 0.5.
    public var value: Double?

    public init(action: String, down: Bool? = nil, duration: Double? = nil, value: Double? = nil) {
        self.action = action
        self.down = down
        self.duration = duration
        self.value = value
    }

    public var step: PlaytestStep { .action(action, down: down, duration: duration, value: value) }
}

/// `input.gamepad`'s arguments.
public struct PlaytestGamepadArguments: Codable, Equatable, Sendable {
    /// A button ("south", "east", "west", "north", "dpadUp", "start"…).
    public var button: GamepadButton?
    /// An axis ("leftStickX", "leftStickY", "rightStickX", "rightStickY", "leftTrigger", "rightTrigger") and its `value`.
    public var axis: GamepadAxis?
    public var value: Double?
    /// true presses / sets and keeps it, false releases / zeroes it; omitted taps the button or holds for `duration` seconds.
    public var down: Bool?
    public var duration: Double?

    public init(button: GamepadButton? = nil, axis: GamepadAxis? = nil, value: Double? = nil, down: Bool? = nil, duration: Double? = nil) {
        self.button = button
        self.axis = axis
        self.value = value
        self.down = down
        self.duration = duration
    }

    public var step: PlaytestStep {
        PlaytestStep(down: down, duration: duration, gamepad: PlaytestGamepadInput(button: button, axis: axis, value: value))
    }
}

/// `playtest.start`'s arguments.
public struct PlaytestStartArguments: Codable, Equatable, Sendable {
    /// What results and the recording are called.
    public var name: String?
    /// Record the session for `playtest.save` (default true).
    public var record: Bool?
    /// Input actions beyond the scene's visual scripts': name → sources ("key.space", "pad.south", "axis.leftStickX").
    public var actions: [String: [String]]?

    public init(name: String? = nil, record: Bool? = nil, actions: [String: [String]]? = nil) {
        self.name = name
        self.record = record
        self.actions = actions
    }
}

/// `playtest.save`'s arguments and result.
public struct PlaytestSaveArguments: Codable, Equatable, Sendable {
    /// Where to write the recording (".playtest.json" is added when missing).
    public var path: String

    public init(path: String) { self.path = path }
}

public struct PlaytestSaveResult: Codable, Equatable, Sendable {
    public var path: String
    public var steps: Int
    public var frames: Int
    public var assertions: Int

    public init(path: String, playtest: Playtest) {
        self.path = path
        steps = playtest.steps.count
        frames = playtest.frameCount
        assertions = playtest.assertionCount
    }
}

/// `playtest.run`'s arguments.
public struct PlaytestRunArguments: Codable, Equatable, Sendable {
    /// A playtest file to replay.
    public var path: String?
    /// Or the playtest itself.
    public var playtest: Playtest?

    public init(path: String? = nil, playtest: Playtest? = nil) {
        self.path = path
        self.playtest = playtest
    }
}

/// `input.actions`' result.
public struct PlaytestActionList: Codable, Equatable, Sendable {
    public var actions: [PlaytestActionInfo]
    public init(actions: [PlaytestActionInfo]) { self.actions = actions }
}

/// The headless playtest MCP server; see the notes at the top of this file.
@MainActor
public final class PlaytestMCP: MCPToolProvider {
    public let server: MCPServer
    public let host: PlaytestHeadlessHost
    /// Where relative paths of `playtest.save` / `playtest.run` resolve (default the working directory).
    public var folder: URL

    private struct Entry {
        var tool: MCPTool
        var call: @MainActor (JSON) throws -> JSON
    }

    private var entries: [Entry] = []
    private var generator = GameMCP.makeSchemaGenerator()

    public init(host: PlaytestHeadlessHost, folder: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) {
        self.host = host
        self.folder = folder
        server = MCPServer(info: .init(name: "acro-playtest", title: "Acro Headless Playtest", version: "0.1.0"),
                           instructions: Self.instructions)
        generator.override(Vec3.self, schema: ["type": "array", "items": ["type": "number"], "minItems": 3, "maxItems": 3], sample: .zero)
        server.tools = self
        registerTools()
    }

    static let instructions = """
        Plays one scene of an Acro game headless: nothing runs until play.step. Start with playtest.start (reloads the \
        scene and records), send input with input.action (by input action name: input.actions lists them; tap, hold \
        `duration`, `down` true / false, analog `value`), input.gamepad or input.inject (keys and mouse), run frames with \
        play.step {frames} (1/60 s each, deterministic), read the world with scene.hierarchy / entity.find / entity.get, \
        check it with playtest.assert ({entity, field: "position.x", min: 2}, {entity, variable, equals}, \
        {count: {component}, equals}), read the verdict with playtest.result and save the session with playtest.save \
        {path}; playtest.run replays a saved one with its assertions.
        """

    // MARK: MCPToolProvider

    public var tools: [MCPTool] { entries.map(\.tool) }

    public func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        guard let entry = entries.first(where: { $0.tool.name == name }) else { return .result(.error("No tool '\(name)'")) }
        do {
            return .result(.success(try entry.call(arguments)))
        } catch let error as DecodingError {
            return .result(.error("Invalid arguments for '\(name)': \(error)"))
        } catch {
            return .result(.error("\(name) failed: \(error)"))
        }
    }

    /// Calls a tool directly (tests, scripts); throws its error.
    public func call(_ name: String, _ arguments: JSON = [:]) throws -> JSON {
        guard let entry = entries.first(where: { $0.tool.name == name }) else { throw PlaytestError("No tool '\(name)'") }
        return try entry.call(arguments)
    }

    private func add<A: Codable, R: Codable>(_ name: String, _ title: String, _ doc: String, readOnly: Bool = false,
                                             _ arguments: A.Type, _ result: R.Type, run: @escaping @MainActor (A) throws -> R) {
        func object(_ schema: JSON) -> JSON { schema["type"] == "object" ? schema : ["type": "object", "properties": [:]] }
        let tool = MCPTool(name: name, title: title, description: doc, inputSchema: object(generator.schema(for: A.self)),
                           outputSchema: object(generator.schema(for: R.self)),
                           annotations: MCPToolAnnotations(title: title, readOnlyHint: readOnly, destructiveHint: false,
                                                           idempotentHint: readOnly, openWorldHint: false))
        entries.append(Entry(tool: tool) { json in
            try JSON(encoding: run(JSON.object(json.objectValue ?? [:]).decode(A.self)))
        })
    }

    // MARK: Tools

    struct Empty: Codable {}

    struct State: Codable {
        var scene: String
        /// Game frames and seconds run since the scene (re)loaded.
        var frame: Int
        var time: Double
        /// Raw input still scheduled (input.inject) and action / gamepad input still scheduled.
        var inputPending: Int
        var actionInputPending: Int
        var keys: [Key]
        var entities: Int
        var recording: Bool
    }

    struct Step: Codable {
        /// Frames to run (default 1, at most 100000).
        var frames: Int?
        /// Seconds per frame (default the world's fixed step, 1/60).
        var dt: Double?
    }

    struct Inject: Codable {
        var steps: [InputStep]
        /// Drop what is scheduled (and release injected keys) first.
        var replace: Bool?
    }

    struct EntityArgument: Codable {
        /// An entity id, a name or a path of names ("Level/Door").
        var entity: String
    }

    struct Find: Codable {
        /// Part of the name (any case).
        var name: String?
        var component: String?
    }

    struct FoundEntity: Codable {
        var entity: String
        var name: String?
        var components: [String]
    }

    struct Found: Codable {
        var entities: [FoundEntity]
    }

    struct EntityInfo: Codable {
        var entity: String
        var name: String?
        var parent: String?
        var children: [String]
        /// The world transform.
        var position: Vec3
        var components: [String: JSON]
        /// Visual script variables, when the entity runs a script.
        var variables: [String: JSON]?
    }

    struct HierarchyEntry: Codable {
        var entity: String
        var name: String?
        var components: [String]
        var children: [HierarchyEntry]
    }

    struct Hierarchy: Codable {
        var entities: [HierarchyEntry]
    }

    private var driver: PlaytestDriver { host.driver }

    private func state() -> State {
        State(scene: host.scenePath, frame: host.frame, time: host.time, inputPending: host.inputPlayer.pendingCount,
              actionInputPending: driver.pendingInput, keys: Key.allCases.filter { host.input.isDown($0) },
              entities: host.world.entityCount, recording: driver.isRecording)
    }

    private func url(_ path: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        return expanded.hasPrefix("/") ? URL(fileURLWithPath: expanded) : folder.appendingPathComponent(expanded).standardizedFileURL
    }

    private func registerTools() {
        add("play.state", "Play State", "The scene, frames and seconds run, scheduled input, keys down and whether the session records.",
            readOnly: true, Empty.self, State.self) { [unowned self] _ in state() }
        add("play.step", "Step", "Runs `frames` game frames now (default 1), each `dt` seconds (default 1/60), with the input scheduled for them. Deterministic.",
            Step.self, State.self) { [unowned self] arguments in
            try driver.perform(.frames(arguments.frames ?? 1, dt: arguments.dt))
            return state()
        }
        add("input.inject", "Inject Input", "Schedules keyboard / mouse input steps over game time like the editor's input.inject (after input already scheduled; `replace`: instead).",
            Inject.self, State.self) { [unowned self] arguments in
            try driver.perform(PlaytestStep(input: arguments.steps, replace: arguments.replace))
            return state()
        }
        add("input.clear", "Clear Input", "Drops scheduled input and releases every injected key, button and virtual gamepad input.",
            Empty.self, State.self) { [unowned self] _ in
            try driver.perform(PlaytestStep(clearInput: true))
            return state()
        }
        add("input.action", "Input Action", "Presses an input action by name from the next frame: tapped (one frame), held `duration` seconds, pressed (`down` true) or released (false); `value` sets an analog source (a gamepad axis).",
            PlaytestActionArguments.self, State.self) { [unowned self] arguments in
            try driver.perform(arguments.step)
            return state()
        }
        add("input.gamepad", "Gamepad Input", "Drives a virtual gamepad from the next frame: a `button` tapped / held `duration` / pressed (`down`), or an `axis` set to `value`.",
            PlaytestGamepadArguments.self, State.self) { [unowned self] arguments in
            try driver.perform(arguments.step)
            return state()
        }
        add("input.actions", "Input Actions", "The input actions input.action can press: the playtest's and the scene's visual scripts' (known after the first frame), with their sources.",
            readOnly: true, Empty.self, PlaytestActionList.self) { [unowned self] _ in PlaytestActionList(actions: driver.knownActions) }
        add("scene.hierarchy", "Scene Hierarchy", "The world's entity tree: ids, names, component names and children.",
            readOnly: true, Empty.self, Hierarchy.self) { [unowned self] _ in
            let world = host.world
            @MainActor func node(_ entity: Entity) -> HierarchyEntry {
                HierarchyEntry(entity: GameMCP.idString(entity, in: world), name: world.get(Name.self, for: entity)?.value,
                               components: world.componentTypes(of: entity).map { $0.componentName },
                               children: world.children(of: entity).map(node))
            }
            return Hierarchy(entities: world.roots.map(node))
        }
        add("entity.find", "Find Entities", "Entities whose name contains `name` (any case) and that have the component `component`.",
            readOnly: true, Find.self, Found.self) { [unowned self] arguments in
            let world = host.world
            let text = arguments.name?.lowercased()
            let found = world.entities.filter { entity in
                if let text, !(world.get(Name.self, for: entity)?.value.lowercased().contains(text) ?? false) { return false }
                if let component = arguments.component, world.component(named: component, of: entity) == nil { return false }
                return true
            }
            return Found(entities: found.prefix(500).map {
                FoundEntity(entity: GameMCP.idString($0, in: world), name: world.get(Name.self, for: $0)?.value,
                            components: world.componentTypes(of: $0).map { $0.componentName })
            })
        }
        add("entity.get", "Get Entity", "One entity: name, parent, children, world position, every component's fields and its visual script variables.",
            readOnly: true, EntityArgument.self, EntityInfo.self) { [unowned self] arguments in
            let world = host.world
            guard let entity = PlaytestDriver.findEntity(arguments.entity, in: world) else {
                throw PlaytestError("No entity '\(arguments.entity)' (see scene.hierarchy)")
            }
            var components: [String: JSON] = [:]
            for component in world.components(of: entity) {
                components[type(of: component).componentName] = (try? JSON(encoding: component)) ?? nil
            }
            let variables = VisualScriptRuntime.runtime(for: world)?.instances[entity]?.variables
                .compactMapValues { try? JSON(encoding: $0.json) }
            let matrix = world.worldMatrix(of: entity)
            return EntityInfo(entity: GameMCP.idString(entity, in: world), name: world.get(Name.self, for: entity)?.value,
                              parent: world.parent(of: entity).map { GameMCP.idString($0, in: world) },
                              children: world.children(of: entity).map { GameMCP.idString($0, in: world) },
                              position: Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z), components: components, variables: variables)
        }
        add("playtest.start", "Start Playtest", "Reloads the scene from its file, resets input and time, and starts a new session (recording unless `record` is false).",
            PlaytestStartArguments.self, State.self) { [unowned self] arguments in
            try host.restart(name: arguments.name, record: arguments.record ?? true, actions: arguments.actions ?? [:])
            return state()
        }
        add("playtest.assert", "Assert", "Checks the world now and records pass / fail in the session: an entity (`exists`), a `component` `field`, a visual script `variable`, the world transform (`field` \"position.x\") or a `count` of entities, compared with `exists`, `equals`, `min` / `max` or `near` ± `tolerance`.",
            PlaytestAssertion.self, PlaytestCheck.self) { [unowned self] assertion in
            try driver.perform(.assert(assertion)) ?? driver.check(assertion)
        }
        add("playtest.result", "Playtest Result", "The session's assertions so far, whether they all passed, step errors, and frames run.",
            readOnly: true, Empty.self, PlaytestResult.self) { [unowned self] _ in driver.result }
        add("playtest.save", "Save Playtest", "Writes the session recorded since playtest.start (input, frames and assertions) as a playtest JSON file for playtest.run or GameRunner --playtest.",
            PlaytestSaveArguments.self, PlaytestSaveResult.self) { [unowned self] arguments in
            let recording = driver.finishedRecording()
            guard !recording.steps.isEmpty else { throw PlaytestError("Nothing recorded (playtest.start first)") }
            var path = arguments.path
            if !path.hasSuffix(".json") { path += Playtest.fileSuffix }
            let file = url(path)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try recording.json().write(to: file, options: .atomic)
            return PlaytestSaveResult(path: file.path, playtest: recording)
        }
        add("playtest.run", "Run Playtest", "Replays a playtest (`path` to a file or the `playtest` itself) from the start of the scene and returns its result.",
            PlaytestRunArguments.self, PlaytestResult.self) { [unowned self] arguments in
            let playtest: Playtest
            if let given = arguments.playtest {
                playtest = given
            } else if let path = arguments.path {
                playtest = try Playtest(contentsOf: url(path))
            } else {
                throw PlaytestError("Give `path` or `playtest`")
            }
            try host.restart(name: playtest.name)
            return host.run(playtest)
        }
    }

    // MARK: Serving

    /// Points standard output at standard error and returns the protocol's handle to it (see
    /// `MCPStdioTransport.claimStandardOutput`): call before anything prints.
    public static func claimStandardOutput() -> FileHandle {
        MCPStdioTransport.claimStandardOutput()
    }

    /// Serves on standard input and `output` (default: standard output, claimed now) until the
    /// client closes its end.
    public func serveStandardIO(output: FileHandle? = nil) {
        let stdio = MCPStdioTransport(inbox: server.inbox, input: .standardInput, output: output ?? Self.claimStandardOutput())
        stdio.start()
        while !stdio.isClosed {
            server.pump()
            Thread.sleep(forTimeInterval: 0.002)
        }
        server.pump()
    }
}
