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
// carries the result as `structuredContent` and as text, plus what the command logged. A call
// that starts background imports finishes when they do, with progress notifications meanwhile.
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
        undo step, which edit.undo reverts. Read the scene from the editor://scene resource (entity ids, names, \
        components, hierarchy, selection), one entity's component fields from editor://entity/{id}, the project's \
        assets from editor://assets and the console from editor://log. Entities are named by 32-hex-digit ids, \
        assets by "asset:<id>[#<object>]" references or paths under Assets/; vectors are [x, y, z] arrays and \
        rotations quaternions [x, y, z, w]. Commands acting on "the selection" (entity.duplicate, entity.delete) \
        need selection.set first.
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
        guard commands.isAvailable(id) else {
            let failure = CommandError.unavailable(id, reason: commands.unavailableReason(id))
            return .result(.error(failure.description))
        }
        let mark = session.log.nextSequence
        let pendingBefore = session.assets?.pendingLoadCount ?? 0
        let result: JSON
        do {
            result = try JSON(data: commands.run(id, json: arguments.data()))
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

    // MARK: Resources

    public var resources: [MCPResource] {
        [
            MCPResource(uri: "editor://scene", name: "scene", title: "Scene",
                        description: "The open scene: file, dirty and play state, selection, and the entity tree (ids, names, component names)."),
            MCPResource(uri: "editor://assets", name: "assets", title: "Project assets",
                        description: "The open project's assets: paths under Assets/, ids, importers and the objects each holds (as asset: references)."),
            MCPResource(uri: "editor://log", name: "log", title: "Console",
                        description: "The editor console's latest entries (level, message, time)."),
        ]
    }

    public var resourceTemplates: [MCPResourceTemplate] {
        [MCPResourceTemplate(uriTemplate: "editor://entity/{id}", name: "entity", title: "Entity",
                             description: "One entity: name, parent, children and every component's fields.")]
    }

    public func readResource(_ uri: String) -> [MCPResourceContents]? {
        let json: JSON
        switch uri {
        case "editor://scene": json = sceneJSON()
        case "editor://assets": json = assetsJSON()
        case "editor://log": json = logJSON()
        default:
            let prefix = "editor://entity/"
            guard uri.hasPrefix(prefix), let id = EntityID(String(uri.dropFirst(prefix.count))),
                  let entity = entityJSON(id) else { return nil }
            json = entity
        }
        return [MCPResourceContents(uri: uri, text: json.prettyText)]
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

    private func entityJSON(_ id: EntityID) -> JSON? {
        let world = session.world
        guard let entity = world.entity(for: id) else { return nil }
        var components: [String: JSON] = [:]
        for component in world.components(of: entity) where type(of: component).isSerialized {
            components[type(of: component).componentName] = .object(Dictionary(
                component.fields().map { ($0.name, fieldJSON($0)) }, uniquingKeysWith: { first, _ in first }))
        }
        return [
            "id": .string(id.description),
            "name": .string(session.displayName(of: entity)),
            "parent": world.parent(of: entity).flatMap { world.id(of: $0) }.map { .string($0.description) } ?? nil,
            "children": .array(world.children(of: entity).compactMap { world.id(of: $0) }.map { .string($0.description) }),
            "components": .object(components),
        ]
    }

    private func fieldJSON(_ field: FieldDescriptor) -> JSON {
        if let value = field.value { return JSON(value.json(in: session.world), in: session.world) }
        switch field.kind {
        case .array: return .array(field.children.map(fieldJSON))
        case .structure:
            return .object(Dictionary(field.children.map { ($0.name, fieldJSON($0)) }, uniquingKeysWith: { first, _ in first }))
        default: return nil
        }
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

    private func logJSON() -> JSON {
        .array(session.log.entries.suffix(200).map { entry in
            ["level": .string(entry.level.tag), "message": .string(entry.message), "time": .double(entry.time)]
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
