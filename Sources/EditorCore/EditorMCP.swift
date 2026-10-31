import Engine
import EngineMCP
import Foundation

// The editor as an MCP server: every command in `session.commands` is a tool, and the scene,
// entities, assets and log are readable resources. AI clients drive the editor exactly as the
// toolbar does, through the command registry; there is no MCP-specific editor logic.
//
// ```sh
// claude mcp add swift-engine -- swift run Editor --mcp          # stdio: the client launches the editor
// # or attach to a running editor over HTTP (URL and token in <project>/Library/mcp.json):
// claude mcp add --transport http swift-engine http://127.0.0.1:7333/mcp --header "Authorization: Bearer <token>"
// ```
//
// ## Tools from commands
//
// One tool per `EditorCommand`, named by its id unchanged ("entity.create"; MCP tool names allow
// letters, digits, "_", "-" and ".", and every command id fits). The description is the
// command's `doc`, the title its `title`, the input schema is derived from `Arguments` and the
// output schema from `Result` by `JSONSchemaGenerator` (entity ids, asset ids and references as
// strings with their patterns, vectors and quaternions as fixed-length number arrays, enums as
// their string cases, optionals not required). Annotations come from `isReadOnly`,
// `isDestructive` and `isIdempotent`. A call runs the command by id with the arguments' JSON
// (`CommandRegistry.run(_:json:)`), so registering a command is all it takes to get a tool. An
// unavailable command or a failure is a tool result with `isError` and the reason; a success
// carries the result as `structuredContent` and as text, plus what the command logged. Images
// in a result (`CommandImage`, from `view.screenshot`) go out as image content, without their
// data in the structured result. A command that finishes later (`EditorDeferredCommand`: a
// screenshot waits for the next frame) is answered when its future is fulfilled, and a call
// that starts background imports when they finish, with progress notifications meanwhile.
//
// ## Resources
//
// `editor://scene` (the entity tree, selection, file and play state), `editor://scene/file`
// (the whole scene file, as `scene.save` would write it), `editor://entity/{id}`,
// `editor://assets`, `editor://log` (and `editor://log/{level}`: warnings and errors, or only
// errors), `editor://stats` and `editor://diagnostics`; all subscribable (checked for changes
// five times a second while someone is subscribed).
// The tool list is announced as changed when commands are registered or a project opens or
// closes.
//
// ## Threading
//
// Transports post to the server's inbox from their threads; `pump()`, which the app calls once
// per frame (and the headless loop whenever something arrives), runs everything on the main
// actor between frames.

/// Starts and feeds the editor's MCP server; see the notes at the top of this file.
@MainActor
public final class EditorMCP: MCPToolProvider, MCPResourceProvider {
    public let session: EditorSession
    public let server: MCPServer
    public private(set) var stdio: MCPStdioTransport?
    public private(set) var http: MCPHTTPTransport?
    /// Where `mcp.json` goes without a project (next to the prefs file).
    public var fallbackConfigURL: URL?

    private let generator = EditorMCP.makeSchemaGenerator()
    private var cachedTools: [MCPTool]?
    private var toolsKey: ToolsKey?
    private var resourceSnapshots: [String: String] = [:]
    private var lastResourceCheck = ContinuousClock.now
    private var writtenConfigURLs: Set<URL> = []

    private struct ToolsKey: Equatable {
        var revision: Int
        var project: String?
    }

    /// The name `initialize` reports.
    public static let serverName = "swift-engine"

    public init(session: EditorSession) {
        self.session = session
        server = MCPServer(info: .init(name: Self.serverName, title: "SwiftGameEngine Editor", version: "0.1.0"),
                           instructions: Self.instructions)
        server.tools = self
        server.resources = self
    }

    static let instructions = """
        Drives the SwiftGameEngine editor. Every editor action is a tool named by its command id \
        (entity.create, transform.set, component.setField, asset.instantiate…); tools marked undoable record one \
        undo step, which edit.undo reverts. Wrap a multi-step change in edit.batch (or edit.beginBatch / \
        edit.endBatch) so it is one undo step named after its intent, rolled back if a step fails. Read the scene \
        with scene.hierarchy, entity.find, entity.get and component.types (or the editor://scene, \
        editor://entity/{id} and editor://scene/file resources), the project's assets from editor://assets and the \
        console with log.read. See it with view.screenshot (viewport, game camera, any camera, window, panel, \
        asset thumbnail) and point at it with view.pick (a pixel of a screenshot) or scene.raycast. Entities are \
        named by 32-hex-digit ids, assets by "asset:<id>[#<object>]" references or paths under Assets/; vectors \
        are [x, y, z] arrays and rotations quaternions [x, y, z, w].
        """

    // MARK: Transports

    /// Serves the client on standard input / output (`Editor --mcp`). Claims standard output
    /// first, so everything printed from now on goes to standard error.
    public func startStdio() {
        guard stdio == nil else { return }
        stdio = MCPStdioTransport.start(inbox: server.inbox)
    }

    /// The stdio client closed its end: the editor should quit.
    public var stdioClientDisconnected: Bool { stdio?.isClosed ?? false }

    /// Serves Streamable HTTP on 127.0.0.1:`port` (the next free port if taken) and writes
    /// `mcp.json` with the URL and token; prints both to standard error.
    @discardableResult
    public func startHTTP(port: UInt16) throws -> MCPHTTPTransport {
        if let http { return http }
        let token = configURLs.lazy.compactMap { MCPConfigFile.existingToken(at: $0) }.first ?? MCPHTTPTransport.makeToken()
        let transport = try MCPHTTPTransport.start(inbox: server.inbox, port: port, token: token)
        http = transport
        writeConfig()
        let file = configURLs.first.map { " (also in \($0.path))" } ?? ""
        MCPServer.logToStandardError("MCP: Streamable HTTP on \(transport.url), bearer token \(token)\(file)")
        session.log.info("MCP server listening on \(transport.url); the token is in mcp.json")
        return transport
    }

    public func stop() {
        http?.stop()
    }

    /// Where `mcp.json` is written: the open project's `Library/`, and the prefs folder.
    var configURLs: [URL] {
        var urls: [URL] = []
        if let project = session.project { urls.append(project.libraryURL.appendingPathComponent("mcp.json")) }
        if let fallbackConfigURL { urls.append(fallbackConfigURL) }
        return urls
    }

    private func writeConfig() {
        guard let http else { return }
        let config = MCPConfigFile(url: http.url, token: http.token, serverName: Self.serverName)
        for url in configURLs where !writtenConfigURLs.contains(url) {
            do {
                try config.write(to: url)
                writtenConfigURLs.insert(url)
            } catch {
                session.log.warning("Couldn't write \(url.path): \(error)")
            }
        }
    }

    // MARK: Frame

    /// Notices what changed (commands, the project, subscribed resources) and handles queued
    /// requests. Call it once per frame on the main actor.
    public func pump() {
        let key = ToolsKey(revision: session.commands.revision, project: session.project?.root.path)
        if key != toolsKey {
            let first = toolsKey == nil
            toolsKey = key
            cachedTools = nil
            writeConfig()
            if !first { server.toolsChanged() }
        }
        server.pump()
        notifyResourceChanges()
    }

    private func notifyResourceChanges() {
        let subscribed = server.subscribedResources
        resourceSnapshots = resourceSnapshots.filter { subscribed.contains($0.key) }
        guard !subscribed.isEmpty, ContinuousClock.now - lastResourceCheck > .milliseconds(200) else { return }
        lastResourceCheck = .now
        for uri in subscribed.sorted() {
            let text = readResource(uri)?.map(\.text).joined() ?? ""
            if let previous = resourceSnapshots[uri], previous != text { server.resourceUpdated(uri) }
            resourceSnapshots[uri] = text
        }
    }

    // MARK: Tools

    /// The tool name for a command: its id, unchanged.
    public static func toolName(for id: CommandID) -> String { id.rawValue }

    public var tools: [MCPTool] {
        if let cachedTools { return cachedTools }
        let tools = session.commands.all.compactMap(tool(for:))
        cachedTools = tools
        return tools
    }

    /// The tool describing the command `info`.
    public func tool(for info: CommandInfo) -> MCPTool? {
        let name = Self.toolName(for: info.id)
        guard MCPTool.isValidName(name), let types = session.commands.types(of: info.id) else { return nil }
        var description = info.doc
        if info.isUndoable { description += " Undoable (one step; edit.undo reverts it)." }
        return MCPTool(name: name, title: info.title, description: description,
                       inputSchema: Self.objectSchema(schema(for: types.arguments)),
                       outputSchema: Self.objectSchema(schema(for: types.result)),
                       annotations: MCPToolAnnotations(title: info.title, readOnlyHint: info.isReadOnly,
                                                       destructiveHint: info.isDestructive,
                                                       idempotentHint: info.isIdempotent, openWorldHint: false))
    }

    /// The JSON Schema of `type` with the editor's overrides.
    public func schema<T: Decodable>(for type: T.Type) -> JSON {
        generator.schema(for: type)
    }

    /// Tool schemas must describe objects: an empty `Arguments` (`NoArguments`) is `{}`.
    private static func objectSchema(_ schema: JSON) -> JSON {
        schema["type"] == "object" ? schema : ["type": "object", "properties": [:]]
    }

    public func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        let id = CommandID(name)
        let commands = session.commands
        let title = commands.info(id)?.title ?? name
        let mark = session.log.nextSequence
        let pendingBefore = session.assets?.pendingLoadCount ?? 0
        let future: CommandFuture<Data>
        do {
            future = try commands.start(id, json: arguments.data())
        } catch let failure as CommandError {
            if case .unavailable = failure { return .result(.error(failure.description)) }
            return .result(.error("\(title) failed: \(failure)"))
        } catch {
            return .result(.error("\(title) failed: \(error)"))
        }
        // Finishes after a frame or more (a screenshot): answer when the future is fulfilled.
        guard let outcome = future.outcome else {
            let deadline = ContinuousClock.now + .seconds(20)
            return .pending { [weak self] context in
                guard let self else { return .error("\(title): the editor went away") }
                if let outcome = future.outcome { return toolResult(outcome, title: title, logSince: mark) }
                if context.isCancelled || ContinuousClock.now > deadline {
                    return .error("\(title) timed out (no frame was rendered; is the window minimized?)")
                }
                return nil
            }
        }
        let result: JSON
        do {
            result = try JSON(data: outcome.get())
        } catch {
            return .result(.error("\(title) failed: \(error)"))
        }
        let logged = session.log.entries.filter { $0.sequence >= mark }.map { "[\($0.level.tag)] \($0.message)" }
        func finished(_ note: String? = nil) -> MCPToolResult {
            var text = [result == .object([:]) ? "\(title): done." : result.prettyText]
            let log = logged + (note.map { [$0] } ?? [])
            if !log.isEmpty { text.append(log.joined(separator: "\n")) }
            return MCPToolResult(text: text, structuredContent: result)
        }
        // The command started background imports: answer once they are done, so the next call
        // sees the imported assets.
        let pendingAfter = session.assets?.pendingLoadCount ?? 0
        guard pendingAfter > pendingBefore else { return .result(finished()) }
        var total = pendingAfter
        let deadline = ContinuousClock.now + .seconds(300)
        return .pending { [weak self] context in
            let left = self?.session.assets?.pendingLoadCount ?? 0
            if left == 0 || context.isCancelled { return finished() }
            if ContinuousClock.now > deadline { return finished("Still importing \(left) asset(s) in the background.") }
            total = max(total, left)
            context.progress(Double(total - left), total: Double(total), message: "Importing \(left) asset(s)…")
            return nil
        }
    }

    /// The tool result for a deferred command's outcome: images as image content.
    private func toolResult(_ outcome: Swift.Result<Data, any Error>, title: String, logSince mark: Int) -> MCPToolResult {
        let logged = session.log.entries.filter { $0.sequence >= mark }.map { "[\($0.level.tag)] \($0.message)" }
        do {
            var images: [MCPImageContent] = []
            let result = Self.extractImages(try JSON(data: outcome.get()), into: &images)
            var text = [result.prettyText]
            if !logged.isEmpty { text.append(logged.joined(separator: "\n")) }
            return MCPToolResult(text: text, images: images, structuredContent: result)
        } catch {
            return .error("\(title) failed: \(error)")
        }
    }

    /// `json` with the data of every `CommandImage` in it (an object with an "image/…"
    /// `mimeType` and base64 `data`) moved to `images`.
    static func extractImages(_ json: JSON, into images: inout [MCPImageContent]) -> JSON {
        switch json {
        case .object(var members):
            if let type = members["mimeType"]?.stringValue, type.hasPrefix("image/"),
               let base64 = members["data"]?.stringValue, let data = Data(base64Encoded: base64) {
                images.append(MCPImageContent(data: data, mimeType: type))
                members["data"] = nil
                return .object(members)
            }
            return .object(members.mapValues { extractImages($0, into: &images) })
        case .array(let items):
            return .array(items.map { extractImages($0, into: &images) })
        default:
            return json
        }
    }

    // MARK: Resources

    public var resources: [MCPResource] {
        [
            MCPResource(uri: "editor://scene", name: "scene", title: "Scene",
                        description: "The open scene: file, dirty and play state, selection, and the entity tree (ids, names, component names)."),
            MCPResource(uri: "editor://scene/file", name: "scene-file", title: "Scene file",
                        description: "The whole open scene as a scene file (every entity and component, as scene.save writes it)."),
            MCPResource(uri: "editor://assets", name: "assets", title: "Project assets",
                        description: "The open project's assets: paths under Assets/, ids, importers and the objects each holds (as asset: references)."),
            MCPResource(uri: "editor://log", name: "log", title: "Console",
                        description: "The editor console's latest entries (sequence, level, message, time)."),
            MCPResource(uri: "editor://stats", name: "stats", title: "Stats",
                        description: "Frame, CPU and per-pass GPU times, draw calls, entity count and editor state (as stats.get returns them)."),
            MCPResource(uri: "editor://diagnostics", name: "diagnostics", title: "Diagnostics",
                        description: "Import errors, assets still importing, graphics validation messages and recent console problems."),
        ]
    }

    public var resourceTemplates: [MCPResourceTemplate] {
        [
            MCPResourceTemplate(uriTemplate: "editor://entity/{id}", name: "entity", title: "Entity",
                                description: "One entity: name, parent, children, world transform and every component's fields."),
            MCPResourceTemplate(uriTemplate: "editor://log/{level}", name: "log-level", title: "Console (filtered)",
                                description: "The console's latest entries at a level or above: info, warning or error."),
        ]
    }

    public func readResource(_ uri: String) -> [MCPResourceContents]? {
        let json: JSON
        switch uri {
        case "editor://scene": json = sceneJSON()
        case "editor://scene/file":
            guard let data = try? session.world.save() else { return nil }
            return [MCPResourceContents(uri: uri, text: String(decoding: data, as: UTF8.self))]
        case "editor://assets": json = assetsJSON()
        case "editor://log": json = logJSON(.info)
        case "editor://stats": json = commandJSON(StatsGetCommand.self)
        case "editor://diagnostics": json = commandJSON(DiagnosticsGetCommand.self)
        default:
            if uri.hasPrefix("editor://log/") {
                guard let level = LogLevelName(rawValue: String(uri.dropFirst("editor://log/".count))) else { return nil }
                json = logJSON(level.level)
                break
            }
            let prefix = "editor://entity/"
            guard uri.hasPrefix(prefix), let id = EntityID(String(uri.dropFirst(prefix.count))),
                  let entity = session.entityDetails(id).flatMap({ try? JSON(encoding: $0) }) else { return nil }
            json = entity
        }
        return [MCPResourceContents(uri: uri, text: json.prettyText)]
    }

    /// A read-only command's result as JSON (null if it fails).
    private func commandJSON<C: EditorCommand>(_ command: C.Type) -> JSON where C.Arguments == NoArguments {
        (try? C.run(NoArguments(), in: session)).flatMap { try? JSON(encoding: $0) } ?? nil
    }

    private func sceneJSON() -> JSON {
        let world = session.world
        func node(_ entity: Entity) -> JSON {
            [
                "id": world.id(of: entity).map { .string($0.description) } ?? nil,
                "name": .string(session.displayName(of: entity)),
                "components": .array(world.componentTypes(of: entity).filter { $0.isSerialized }.map { .string($0.componentName) }),
                "children": .array(world.children(of: entity).map(node)),
            ]
        }
        return [
            "scene": [
                "title": .string(session.document.displayName),
                "path": session.document.url.map { .string($0.path) } ?? nil,
                "dirty": .bool(session.document.isDirty),
                "playing": .bool(session.isPlaying),
            ],
            "project": session.project.map { .string($0.root.path) } ?? nil,
            "selection": .array(session.selection.ids.map { .string($0.description) }),
            "primary": session.selection.primary.map { .string($0.description) } ?? nil,
            "entities": .array(world.roots.map(node)),
        ]
    }

    private func assetsJSON() -> JSON {
        guard let assets = session.assets else { return ["project": nil, "assets": []] }
        return [
            "project": .string(assets.project.root.path),
            "assets": .array(assets.allRecords.map { record in
                var object: [String: JSON] = [
                    "path": .string(record.path),
                    "id": .string(record.id.description),
                    "importer": record.importer.map { .string($0) } ?? nil,
                    "objects": .array(record.objects.map { info in
                        [
                            "reference": .string(AssetReference(record.id, subAsset: info.id).description),
                            "name": .string(info.name),
                            "kind": .string(info.kind.rawValue),
                        ]
                    }),
                ]
                if let error = record.importError { object["error"] = .string(error) }
                return .object(object)
            }),
            "importing": .int(Int64(assets.pendingLoadCount)),
        ]
    }

    private func logJSON(_ level: LogLevel) -> JSON {
        .array(session.log.entries(atLeast: level).suffix(200).map { entry in
            ["sequence": .int(Int64(entry.sequence)), "level": .string(entry.level.tag), "message": .string(entry.message),
             "time": .double(entry.time)]
        })
    }

    // MARK: Schemas

    /// JSON Schemas for the editor's value types, as `CommandRegistry` encodes them.
    static func makeSchemaGenerator() -> JSONSchemaGenerator {
        var generator = JSONSchemaGenerator()
        generator.override(EntityID.self, schema: [
            "type": "string", "pattern": "^[0-9a-f]{32}$",
            "description": "An entity id: 32 lowercase hex digits (see the editor://scene resource).",
        ], sample: EntityID(high: 0, low: 1))
        generator.override(AssetID.self, schema: [
            "type": "string", "pattern": "^[0-9a-fA-F-]{32,36}$",
            "description": "An asset id: 32 hex digits (see the editor://assets resource).",
        ], sample: AssetID(high: 0, low: 1))
        generator.override(AssetReference.self, schema: [
            "type": "string", "pattern": "^asset:[0-9a-fA-F-]{32,36}(#.+)?$",
            "description": "An asset: \"asset:<id>\" for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).",
        ], sample: AssetReference(AssetID(high: 0, low: 1)))
        generator.override(JSONValue.self, schema: ["description": "Any JSON value."], sample: .null)
        generator.override(JSON.self, schema: ["description": "Any JSON value."], sample: .null)
        generator.override(Vec2.self, schema: Self.floats(2, "[x, y]"), sample: .zero)
        generator.override(Vec3.self, schema: Self.floats(3, "[x, y, z]"), sample: .zero)
        generator.override(Vec4.self, schema: Self.floats(4, "[x, y, z, w] (colors: linear [r, g, b, a])"), sample: .zero)
        generator.override(Quat.self, schema: Self.floats(4, "A rotation quaternion [x, y, z, w]; [0, 0, 0, 1] is none."),
                           sample: .identity)

        // MaterialAsset reads its enums as strings and accepts a legacy key: state the cases.
        var material = generator.schema(for: MaterialAsset.self)
        if case .object(var properties)? = material["properties"] {
            func cases(_ values: [String]) -> JSON { ["type": "string", "enum": .array(values.map(JSON.string))] }
            properties["shading"] = cases(ShadingModel.allCases.map(\.rawValue))
            properties["filter"] = cases(["linear", "nearest"])
            properties["mipFilter"] = cases(["linear", "nearest", "none"])
            properties["addressMode"] = cases(["repeat", "clampToEdge", "mirrorRepeat"])
            properties["alphaMode"] = cases(["opaque", "mask", "blend"])
            properties["isTransparent"] = nil
            properties["baseColor"]?["description"] = "Linear [r, g, b, a]."
            properties["emissiveColor"] = Self.floats(3, "Linear [r, g, b].")
            material["properties"] = .object(properties)
        }
        generator.override(MaterialAsset.self, schema: material, sample: MaterialAsset())
        return generator
    }

    private static func floats(_ count: Int, _ description: String) -> JSON {
        ["type": "array", "items": ["type": "number"], "minItems": .int(Int64(count)), "maxItems": .int(Int64(count)),
         "description": .string(description)]
    }
}

extension JSON {
    /// An engine `JSONValue` (entities by id).
    @MainActor init(_ value: JSONValue, in world: World) {
        switch value {
        case .null: self = .null
        case .bool(let b): self = .bool(b)
        case .int(let i): self = .int(i)
        case .double(let d): self = .double(d)
        case .string(let s): self = .string(s)
        case .array(let items): self = .array(items.map { JSON($0, in: world) })
        case .object(let members): self = .object(members.mapValues { JSON($0, in: world) })
        case .entity(let entity): self = world.id(of: entity).map { .string($0.description) } ?? .null
        }
    }
}
