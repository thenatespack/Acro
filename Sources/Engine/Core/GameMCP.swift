import EngineMCP
import Foundation

// A game as an MCP server (`EngineConfig.mcp`, or `ENGINE_MCP=1` for stdio / `ENGINE_MCP=http`):
// an AI client can pause and step the game, play input into it, take screenshots, read stats
// and read or edit the game's `World`. The tools are a runtime subset of the editor's, under the
// same names: `play.state`, `play.pause`, `play.step`, `play.setTimeScale`, `input.inject`,
// `input.clear`, `input.state`, `view.screenshot`, `stats.get`, and with a world
// `scene.hierarchy`, `entity.find`, `entity.get` and `component.setField`.
//
// ```sh
// claude mcp add my-game -- env ENGINE_MCP=1 swift run -c release Demo --scene ecs
// ```
//
// Requests are queued by the transports and handled at the start of each frame, after the
// window's events and before `Game.update`, so input injected by a call lands in that frame.
// Screenshots (`Engine.captureFrame`) and steps answer once their frames ran. Entities are
// named by their `EntityID` when the world assigns ids, else by "<index>v<generation>".

/// Which transport `EngineConfig.mcp` serves.
public enum EngineMCPMode: Equatable, Sendable {
    case off
    /// Standard input / output: the client launched the game.
    case stdio
    /// Streamable HTTP on 127.0.0.1 (the next free port if taken); the URL and bearer token
    /// are printed to standard error.
    case http(port: UInt16)

    /// From `ENGINE_MCP`: `1` or `stdio`, `http` (port 7334) or `http:<port>`, `0`; nil when unset.
    public static func fromEnvironment() -> EngineMCPMode? {
        guard let value = ProcessInfo.processInfo.environment["ENGINE_MCP"]?.lowercased() else { return nil }
        switch value {
        case "0", "", "off": return .off
        case "http": return .http(port: 7334)
        default:
            if value.hasPrefix("http:"), let port = UInt16(value.dropFirst(5)) { return .http(port: port) }
            return .stdio
        }
    }
}

/// The game's MCP server; see the notes at the top of this file. `Engine` makes it when
/// `EngineConfig.mcp` (or `ENGINE_MCP`) asks for one: `engine.mcp`.
@MainActor
public final class GameMCP: MCPToolProvider {
    public let server: MCPServer
    public private(set) var stdio: MCPStdioTransport?
    public private(set) var http: MCPHTTPTransport?
    /// The world the entity tools read and edit: `engine.world` by default. Games that keep
    /// their world elsewhere point this at it.
    public var world: (() -> World?)?
    weak var engine: Engine?

    private struct Entry {
        var tool: MCPTool
        var call: @MainActor (JSON) throws -> MCPToolOutcome
    }

    private var entries: [Entry] = []
    private var generator = GameMCP.makeSchemaGenerator()

    init() {
        server = MCPServer(info: .init(name: "acro-game", title: "Acro Game", version: "0.1.0"),
                           instructions: Self.instructions)
        server.tools = self
        registerTools()
    }

    static let instructions = """
        Drives a running Acro game. play.pause / play.step / play.setTimeScale control time \
        (stepping runs whole frames at 1/60 s, deterministic); input.inject plays keyboard, mouse, scroll and text \
        into the game over game time (e.g. [{"key": "w", "duration": 2}, {"key": "space"}]); view.screenshot shows \
        the next frame; stats.get has frame and GPU times. With a world: scene.hierarchy, entity.find, entity.get and \
        component.setField read and edit live entities.
        """

    /// Starts the transport `mode` names. Stdio claims standard output first (from then on
    /// `print` goes to standard error), so start it before printing anything.
    func start(_ mode: EngineMCPMode) {
        switch mode {
        case .off: break
        case .stdio:
            if stdio == nil { stdio = MCPStdioTransport.start(inbox: server.inbox) }
        case .http(let port):
            guard http == nil else { return }
            do {
                let transport = try MCPHTTPTransport.start(inbox: server.inbox, port: port, token: MCPHTTPTransport.makeToken())
                http = transport
                MCPServer.logToStandardError("MCP: Streamable HTTP on \(transport.url), bearer token \(transport.token)")
            } catch {
                MCPServer.logToStandardError("MCP: HTTP server unavailable: \(error)")
            }
        }
    }

    /// The stdio client closed its end: the game should quit.
    public var stdioClientDisconnected: Bool { stdio?.isClosed ?? false }

    /// Handles queued requests (the engine calls it once per frame).
    public func pump() {
        server.pump()
    }

    func stop() {
        http?.stop()
    }

    // MARK: Tools

    public var tools: [MCPTool] { entries.map(\.tool) }

    public func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        guard let entry = entries.first(where: { $0.tool.name == name }) else { return .result(.error("No tool '\(name)'")) }
        do {
            return try entry.call(arguments)
        } catch let error as DecodingError {
            return .result(.error("Invalid arguments for '\(name)': \(error)"))
        } catch {
            return .result(.error("\(name) failed: \(error)"))
        }
    }

    /// Adds a tool that answers at once.
    private func add<A: Codable, R: Codable>(_ name: String, _ title: String, _ doc: String, readOnly: Bool = false,
                                             _ arguments: A.Type, _ result: R.Type, run: @escaping @MainActor (A) throws -> R) {
        addDeferred(name, title, doc, readOnly: readOnly, arguments, result) { arguments in
            .result(.success(try JSON(encoding: run(arguments))))
        }
    }

    /// Adds a tool whose call may answer later.
    private func addDeferred<A: Codable, R: Codable>(_ name: String, _ title: String, _ doc: String, readOnly: Bool = false,
                                                     _ arguments: A.Type, _ result: R.Type,
                                                     run: @escaping @MainActor (A) throws -> MCPToolOutcome) {
        func object(_ schema: JSON) -> JSON { schema["type"] == "object" ? schema : ["type": "object", "properties": [:]] }
        let tool = MCPTool(name: name, title: title, description: doc, inputSchema: object(generator.schema(for: A.self)),
                           outputSchema: object(generator.schema(for: R.self)),
                           annotations: MCPToolAnnotations(title: title, readOnlyHint: readOnly, destructiveHint: false,
                                                           idempotentHint: readOnly, openWorldHint: false))
        entries.append(Entry(tool: tool) { json in
            try run(JSON.object(json.objectValue ?? [:]).decode(A.self))
        })
    }

    private func requireEngine() throws -> Engine {
        guard let engine else { throw GameMCPError("The game isn't running") }
        return engine
    }

    private func requireWorld() throws -> World {
        guard let world = world?() ?? engine?.world else {
            throw GameMCPError("This game has no World (set engine.world or engine.mcp?.world)")
        }
        return world
    }

    private func registerTools() {
        add("play.state", "Play State", "Returns whether the game is paused, its time scale, game frames and seconds run, and the input still scheduled.",
            readOnly: true, Empty.self, PlayState.self) { [unowned self] _ in try state() }
        add("play.pause", "Pause", "Pauses the game (`paused` true), resumes it (false) or toggles (omitted). While paused the game gets dt 0 and scheduled input waits.",
            Pause.self, PlayState.self) { [unowned self] arguments in
            let engine = try requireEngine()
            engine.isPaused = arguments.paused ?? !engine.isPaused
            return try state()
        }
        addDeferred("play.step", "Step", "Pauses and runs `frames` frames (default 1, at most 600) of 1/60 s each, with scheduled input; answers when they ran. Deterministic.",
                    Step.self, PlayState.self) { [unowned self] arguments in
            let engine = try requireEngine()
            let frames = min(max(arguments.frames ?? 1, 1), 600)
            engine.step(frames: frames)
            let deadline = ContinuousClock.now + .seconds(30)
            return .pending { [weak self] _ in
                guard let self, let engine = self.engine else { return .error("The game went away") }
                if engine.pendingSteps > 0 {
                    return ContinuousClock.now > deadline ? .error("Stepping timed out (is the window minimized?)") : nil
                }
                return (try? JSON(encoding: self.state())).map { .success($0) } ?? .error("No state")
            }
        }
        add("play.setTimeScale", "Set Time Scale", "Multiplies the game's dt by `scale` (0 to 100; 1 is real time).",
            TimeScale.self, PlayState.self) { [unowned self] arguments in
            guard arguments.scale >= 0, arguments.scale <= 100 else { throw GameMCPError("`scale` must be between 0 and 100") }
            try requireEngine().timeScale = arguments.scale
            return try state()
        }
        add("input.inject", "Inject Input", """
            Plays input into the game over game time, after what is already scheduled (`replace`: instead of it). Each step \
            does one thing: `key` / `keys` / `button` tapped (one frame), held for `duration` seconds, or pressed (`down`: \
            true) / released (false); `mouseTo` [x, y] in window points; `mouseBy`; `scroll`; `text`. The next step starts \
            `wait` seconds later (default the step's `duration`). Returns the seconds until it is done.
            """, Inject.self, InjectResult.self) { [unowned self] arguments in
            let engine = try requireEngine()
            if arguments.replace == true {
                engine.inputPlayer.clear()
                engine.input.releaseInjected()
            }
            let seconds = try engine.inputPlayer.enqueue(arguments.steps)
            return InjectResult(seconds: seconds, pending: engine.inputPlayer.pendingCount, state: try state())
        }
        add("input.clear", "Clear Input", "Drops scheduled input and releases every injected key and button.",
            Empty.self, PlayState.self) { [unowned self] _ in
            let engine = try requireEngine()
            engine.inputPlayer.clear()
            engine.input.releaseInjected()
            return try state()
        }
        add("input.state", "Input State", "Returns the keys and mouse buttons down, the cursor position and the input still scheduled.",
            readOnly: true, Empty.self, InputState.self) { [unowned self] _ in
            let engine = try requireEngine()
            return InputState(engine.input, player: engine.inputPlayer)
        }
        addDeferred("view.screenshot", "Screenshot", "A PNG of the next frame as the window shows it (or the scene at render resolution with ENGINE_SCREENSHOT_SOURCE unset); `maxSize` scales it down.",
                    readOnly: true, Screenshot.self, ScreenshotResult.self) { [unowned self] arguments in
            let engine = try requireEngine()
            var outcome: Image??
            engine.captureFrame { outcome = .some($0) }
            let deadline = ContinuousClock.now + .seconds(20)
            return .pending { _ in
                guard let image = outcome else {
                    return ContinuousClock.now > deadline ? .error("No frame was rendered (is the window minimized?)") : nil
                }
                guard let image else { return .error("This backend can't read the frame back") }
                let shot = image.downsampled(maxSize: arguments.maxSize)
                return MCPToolResult(text: ["\(shot.width)x\(shot.height) screenshot"], images: [MCPImageContent(data: shot.pngData())],
                                     structuredContent: ["width": .int(Int64(shot.width)), "height": .int(Int64(shot.height))])
            }
        }
        add("stats.get", "Stats", "Returns FPS, frame / update / render / GPU times in milliseconds with each GPU pass, draw calls and triangles.",
            readOnly: true, Empty.self, Stats.self) { [unowned self] _ in
            let engine = try requireEngine()
            return Stats(engine.stats, backend: engine.device.backend.rawValue, device: engine.device.deviceName,
                         entities: (world?() ?? engine.world)?.entityCount)
        }
        add("scene.hierarchy", "Scene Hierarchy", "The world's entity tree: ids, names, component names and children.",
            readOnly: true, Empty.self, Hierarchy.self) { [unowned self] _ in
            let world = try requireWorld()
            return Hierarchy(entities: world.roots.map { node($0, in: world) })
        }
        add("entity.find", "Find Entities", "Entities whose name contains `name` (any case) and that have the component `component`.",
            readOnly: true, Find.self, Found.self) { [unowned self] arguments in
            let world = try requireWorld()
            let text = arguments.name?.lowercased()
            let found = world.entities.filter { entity in
                if let text, !(world.get(Name.self, for: entity)?.value.lowercased().contains(text) ?? false) { return false }
                if let component = arguments.component, world.component(named: component, of: entity) == nil { return false }
                return true
            }
            return Found(entities: found.prefix(500).map { FoundEntity(entity: Self.idString($0, in: world),
                                                                       name: world.get(Name.self, for: $0)?.value) })
        }
        add("entity.get", "Get Entity", "One entity: name, parent, children and every component's fields as JSON.",
            readOnly: true, EntityArgument.self, EntityInfo.self) { [unowned self] arguments in
            let world = try requireWorld()
            let entity = try Self.entity(arguments.entity, in: world)
            var components: [String: JSON] = [:]
            for component in world.components(of: entity) {
                components[type(of: component).componentName] = (try? JSON(encoding: component)) ?? nil
            }
            return EntityInfo(entity: arguments.entity, name: world.get(Name.self, for: entity)?.value,
                              parent: world.parent(of: entity).map { Self.idString($0, in: world) },
                              children: world.children(of: entity).map { Self.idString($0, in: world) }, components: components)
        }
        add("component.setField", "Set Field", "Sets a component field of a live entity: `path` is dotted (\"position\", \"position.1\", \"color.x\"); `value` any JSON the field decodes from (vectors as arrays).",
            SetField.self, EntityInfo.self) { [unowned self] arguments in
            let world = try requireWorld()
            let entity = try Self.entity(arguments.entity, in: world)
            guard let component = world.component(named: arguments.component, of: entity) else {
                throw GameMCPError("\(arguments.entity) has no \(arguments.component)")
            }
            var json = try JSON(encoding: component)
            let keys = arguments.path.split(separator: ".").map(String.init)
            guard !keys.isEmpty, Self.replace(&json, at: keys[...], with: arguments.value) else {
                throw GameMCPError("\(arguments.component) has no field '\(arguments.path)'")
            }
            world.add(try Self.decode(like: component, from: json), to: entity)
            return try callResult("entity.get", EntityArgument(entity: arguments.entity), EntityInfo.self)
        }
    }

    /// Runs another tool's body (for results that repeat it).
    private func callResult<A: Codable, R: Codable>(_ name: String, _ arguments: A, _ type: R.Type) throws -> R {
        guard let entry = entries.first(where: { $0.tool.name == name }),
              case .result(let result) = try entry.call(JSON(encoding: arguments)),
              let structured = result.structuredContent else { throw GameMCPError("\(name) failed") }
        return try structured.decode(R.self)
    }

    private func state() throws -> PlayState {
        let engine = try requireEngine()
        return PlayState(paused: engine.isPaused, timeScale: engine.timeScale, frames: engine.gameFrameCount, time: engine.gameTime,
                         inputPending: engine.inputPlayer.pendingCount, inputSeconds: engine.inputPlayer.remaining,
                         world: (world?() ?? engine.world) != nil)
    }

    private func node(_ entity: Entity, in world: World) -> HierarchyEntry {
        HierarchyEntry(entity: Self.idString(entity, in: world), name: world.get(Name.self, for: entity)?.value,
                       components: world.componentTypes(of: entity).map { $0.componentName },
                       children: world.children(of: entity).map { node($0, in: world) })
    }

    // MARK: Entities and JSON

    static func idString(_ entity: Entity, in world: World) -> String {
        world.id(of: entity)?.description ?? "\(entity.index)v\(entity.generation)"
    }

    static func entity(_ text: String, in world: World) throws -> Entity {
        if let id = EntityID(text), let entity = world.entity(for: id) { return entity }
        let parts = text.split(separator: "v")
        if parts.count == 2, let index = UInt32(parts[0]), let generation = UInt32(parts[1]) {
            let entity = Entity(index: index, generation: generation)
            if world.isAlive(entity) { return entity }
        }
        throw GameMCPError("No entity '\(text)' (see scene.hierarchy)")
    }

    private static func decode<C: Component>(like component: C, from json: JSON) throws -> any Component {
        try json.decode(C.self)
    }

    /// Replaces the value at `keys` (object keys, array indices) in `json`; false if it isn't there.
    static func replace(_ json: inout JSON, at keys: ArraySlice<String>, with value: JSON) -> Bool {
        guard let key = keys.first else {
            json = value
            return true
        }
        switch json {
        case .object(var members):
            guard var child = members[key], replace(&child, at: keys.dropFirst(), with: value) else { return false }
            members[key] = child
            json = .object(members)
            return true
        case .array(var items):
            guard let index = Int(key), items.indices.contains(index), replace(&items[index], at: keys.dropFirst(), with: value) else {
                return false
            }
            json = .array(items)
            return true
        default:
            return false
        }
    }

    static func makeSchemaGenerator() -> JSONSchemaGenerator {
        var generator = JSONSchemaGenerator()
        func floats(_ count: Int, _ description: String) -> JSON {
            ["type": "array", "items": ["type": "number"], "minItems": .int(Int64(count)), "maxItems": .int(Int64(count)),
             "description": .string(description)]
        }
        generator.override(Vec2.self, schema: floats(2, "[x, y]"), sample: .zero)
        generator.override(JSON.self, schema: ["description": "Any JSON value."], sample: .null)
        return generator
    }

    // MARK: Arguments and results

    struct Empty: Codable {}

    struct Pause: Codable {
        /// true pauses, false resumes; omitted toggles.
        var paused: Bool?
    }

    struct Step: Codable {
        /// Frames to run (default 1, at most 600).
        var frames: Int?
    }

    struct TimeScale: Codable {
        var scale: Double
    }

    struct Inject: Codable {
        var steps: [InputStep]
        /// Drop what is scheduled (and release injected keys) first.
        var replace: Bool?
    }

    struct InjectResult: Codable {
        /// Seconds of game time until the scheduled input is done.
        var seconds: Double
        var pending: Int
        var state: PlayState
    }

    struct PlayState: Codable {
        var paused: Bool
        var timeScale: Double
        /// Game frames and seconds of game time run (scaled; nothing while paused).
        var frames: Int
        var time: Double
        /// Injected events still scheduled, and the seconds until the last.
        var inputPending: Int
        var inputSeconds: Double
        /// Whether the entity tools have a world.
        var world: Bool
    }

    struct InputState: Codable {
        var keys: [Key]
        var buttons: [MouseButton]
        var mouse: Vec2
        /// Held by injected input.
        var injectedKeys: [Key]
        var pending: Int

        @MainActor init(_ input: Input, player: InputPlayer) {
            keys = Key.allCases.filter { input.isDown($0) }
            buttons = MouseButton.allCases.filter { input.isDown($0) }
            mouse = input.mousePosition
            injectedKeys = input.injectedHeldKeys.sorted { $0.rawValue < $1.rawValue }
            pending = player.pendingCount
        }
    }

    struct Screenshot: Codable {
        /// Scale the image down so its longer side is at most this many pixels.
        var maxSize: Int?
    }

    struct ScreenshotResult: Codable {
        var width: Int
        var height: Int
    }

    struct Stats: Codable {
        var fps: Double
        var frameMilliseconds: Double
        var updateMilliseconds: Double
        var renderMilliseconds: Double
        var gpuMilliseconds: Double?
        var gpuPasses: [String: Double]
        var drawCalls: Int
        var triangles: Int
        /// Vulkan descriptor pools allocated so far.
        var descriptorPools: Int?
        var backend: String
        var device: String
        var entities: Int?

        init(_ stats: FrameStats, backend: String, device: String, entities: Int?) {
            func ms(_ seconds: Double) -> Double { (seconds * 1e6).rounded() / 1e3 }
            fps = (stats.fps * 10).rounded() / 10
            frameMilliseconds = ms(stats.frameTime)
            updateMilliseconds = ms(stats.updateTime)
            renderMilliseconds = ms(stats.renderTime)
            gpuMilliseconds = stats.gpuTime.map(ms)
            gpuPasses = Dictionary(stats.gpuPassTimes.map { ($0.name, ms($0.seconds)) }, uniquingKeysWith: +)
            drawCalls = stats.drawCalls
            triangles = stats.triangles
            descriptorPools = stats.descriptorPools
            self.backend = backend
            self.device = device
            self.entities = entities
        }
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

    struct Find: Codable {
        var name: String?
        var component: String?
    }

    struct FoundEntity: Codable {
        var entity: String
        var name: String?
    }

    struct Found: Codable {
        var entities: [FoundEntity]
    }

    struct EntityArgument: Codable {
        /// An entity id (32 hex digits) or "<index>v<generation>" (see scene.hierarchy).
        var entity: String
    }

    struct EntityInfo: Codable {
        var entity: String
        var name: String?
        var parent: String?
        var children: [String]
        var components: [String: JSON]
    }

    struct SetField: Codable {
        var entity: String
        var component: String
        var path: String
        var value: JSON
    }
}

struct GameMCPError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
}

extension Image {
    /// Box-filtered down so the longer side is at most `maxSize` (unchanged without one).
    func downsampled(maxSize: Int?) -> Image {
        guard let maxSize, maxSize > 0, max(width, height) > maxSize else { return self }
        let factor = Double(max(width, height)) / Double(maxSize)
        let w = max(1, Int((Double(width) / factor).rounded())), h = max(1, Int((Double(height) / factor).rounded()))
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            let y0 = y * height / h, y1 = max((y + 1) * height / h, y0 + 1)
            for x in 0..<w {
                let x0 = x * width / w, x1 = max((x + 1) * width / w, x0 + 1)
                var sum = [Int](repeating: 0, count: 4)
                for sy in y0..<y1 {
                    for sx in x0..<x1 {
                        for c in 0..<4 { sum[c] += Int(self.pixels[(sy * width + sx) * 4 + c]) }
                    }
                }
                let count = (y1 - y0) * (x1 - x0)
                for c in 0..<4 { pixels[(y * w + x) * 4 + c] = UInt8(sum[c] / count) }
            }
        }
        return Image(width: w, height: h, pixels: pixels)
    }
}
