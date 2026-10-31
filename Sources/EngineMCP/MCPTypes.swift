import Foundation

// What a server offers: tools (named calls with a JSON Schema for their arguments) and
// resources (readable documents named by URI). The host supplies them through
// `MCPToolProvider` and `MCPResourceProvider`; the server turns them into protocol messages.

/// Hints about a tool's behaviour, for clients deciding whether to ask the user first. All
/// optional; MCP's defaults are not read-only, destructive, not idempotent, open world.
public struct MCPToolAnnotations: Equatable, Sendable {
    /// A human-readable title.
    public var title: String?
    /// The tool doesn't modify its environment.
    public var readOnlyHint: Bool?
    /// The tool may delete or overwrite (as opposed to only adding).
    public var destructiveHint: Bool?
    /// Calling it again with the same arguments has no further effect.
    public var idempotentHint: Bool?
    /// The tool talks to an open world (the internet) rather than a closed one.
    public var openWorldHint: Bool?

    public init(title: String? = nil, readOnlyHint: Bool? = nil, destructiveHint: Bool? = nil, idempotentHint: Bool? = nil,
                openWorldHint: Bool? = nil) {
        self.title = title
        self.readOnlyHint = readOnlyHint
        self.destructiveHint = destructiveHint
        self.idempotentHint = idempotentHint
        self.openWorldHint = openWorldHint
    }

    var json: JSON {
        var object: [String: JSON] = [:]
        if let title { object["title"] = .string(title) }
        if let readOnlyHint { object["readOnlyHint"] = .bool(readOnlyHint) }
        if let destructiveHint { object["destructiveHint"] = .bool(destructiveHint) }
        if let idempotentHint { object["idempotentHint"] = .bool(idempotentHint) }
        if let openWorldHint { object["openWorldHint"] = .bool(openWorldHint) }
        return .object(object)
    }
}

/// A tool as `tools/list` describes it.
public struct MCPTool: Equatable, Sendable {
    /// Unique; letters, digits, "_", "-" and "." (`MCPTool.isValidName`).
    public var name: String
    public var title: String?
    public var description: String
    /// A JSON Schema with `"type": "object"`.
    public var inputSchema: JSON
    /// A JSON Schema for `structuredContent`, if the tool returns structured results.
    public var outputSchema: JSON?
    public var annotations: MCPToolAnnotations?

    public init(name: String, title: String? = nil, description: String, inputSchema: JSON = ["type": "object"],
                outputSchema: JSON? = nil, annotations: MCPToolAnnotations? = nil) {
        self.name = name
        self.title = title
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.annotations = annotations
    }

    /// Whether `name` is a valid MCP tool name: 1–128 characters from `[A-Za-z0-9_.-]`.
    public static func isValidName(_ name: String) -> Bool {
        !name.isEmpty && name.utf8.count <= 128
            && name.unicodeScalars.allSatisfy { ($0.isASCII && CharacterSet.alphanumerics.contains($0)) || "_-.".unicodeScalars.contains($0) }
    }

    func json(protocolVersion: String) -> JSON {
        var object: [String: JSON] = ["name": .string(name), "description": .string(description), "inputSchema": inputSchema]
        // `title` and `outputSchema` arrived in 2025-06-18; older clients ignore unknown keys
        // but some validate output against the schema, so only send it to clients that know it.
        let modern = protocolVersion >= MCPProtocol.v2025_06_18
        if let title, modern { object["title"] = .string(title) }
        if let outputSchema, modern { object["outputSchema"] = outputSchema }
        if let annotations { object["annotations"] = annotations.json }
        return .object(object)
    }
}

/// The result of a tool call. A failure the model should see (bad arguments, a command that
/// isn't available) is a result with `isError`, not a protocol error.
public struct MCPToolResult: Equatable, Sendable {
    /// Text blocks shown to the model.
    public var text: [String]
    /// The result as JSON (an object), matching the tool's `outputSchema`.
    public var structuredContent: JSON?
    public var isError: Bool

    public init(text: [String], structuredContent: JSON? = nil, isError: Bool = false) {
        self.text = text
        self.structuredContent = structuredContent
        self.isError = isError
    }

    /// A successful result: `structured` as structured content, rendered as text too.
    public static func success(_ structured: JSON, text: String? = nil) -> MCPToolResult {
        MCPToolResult(text: [text ?? structured.prettyText], structuredContent: structured)
    }

    /// A failed result with `message` as its text.
    public static func error(_ message: String) -> MCPToolResult {
        MCPToolResult(text: [message], isError: true)
    }

    func json(protocolVersion: String) -> JSON {
        var object: [String: JSON] = [
            "content": .array(text.map { ["type": "text", "text": .string($0)] }),
            "isError": .bool(isError),
        ]
        if let structuredContent, protocolVersion >= MCPProtocol.v2025_06_18 { object["structuredContent"] = structuredContent }
        return .object(object)
    }
}

/// What a tool call returns: a result now, or later (a long call the server polls each pump,
/// reporting progress through the context meanwhile).
public enum MCPToolOutcome {
    case result(MCPToolResult)
    /// Polled on the main actor every `MCPServer.pump()` until it returns a result.
    case pending(@MainActor (MCPCallContext) -> MCPToolResult?)
}

/// A resource as `resources/list` describes it.
public struct MCPResource: Equatable, Sendable {
    public var uri: String
    public var name: String
    public var title: String?
    public var description: String?
    public var mimeType: String?

    public init(uri: String, name: String, title: String? = nil, description: String? = nil, mimeType: String? = "application/json") {
        self.uri = uri
        self.name = name
        self.title = title
        self.description = description
        self.mimeType = mimeType
    }

    var json: JSON {
        var object: [String: JSON] = ["uri": .string(uri), "name": .string(name)]
        if let title { object["title"] = .string(title) }
        if let description { object["description"] = .string(description) }
        if let mimeType { object["mimeType"] = .string(mimeType) }
        return .object(object)
    }
}

/// A family of resources (`resources/templates/list`), e.g. `editor://entity/{id}`.
public struct MCPResourceTemplate: Equatable, Sendable {
    /// An RFC 6570 URI template.
    public var uriTemplate: String
    public var name: String
    public var title: String?
    public var description: String?
    public var mimeType: String?

    public init(uriTemplate: String, name: String, title: String? = nil, description: String? = nil,
                mimeType: String? = "application/json") {
        self.uriTemplate = uriTemplate
        self.name = name
        self.title = title
        self.description = description
        self.mimeType = mimeType
    }

    var json: JSON {
        var object: [String: JSON] = ["uriTemplate": .string(uriTemplate), "name": .string(name)]
        if let title { object["title"] = .string(title) }
        if let description { object["description"] = .string(description) }
        if let mimeType { object["mimeType"] = .string(mimeType) }
        return .object(object)
    }
}

/// The text of a resource.
public struct MCPResourceContents: Equatable, Sendable {
    public var uri: String
    public var mimeType: String?
    public var text: String

    public init(uri: String, mimeType: String? = "application/json", text: String) {
        self.uri = uri
        self.mimeType = mimeType
        self.text = text
    }

    var json: JSON {
        var object: [String: JSON] = ["uri": .string(uri), "text": .string(text)]
        if let mimeType { object["mimeType"] = .string(mimeType) }
        return .object(object)
    }
}

/// Supplies the server's tools. Called on the main actor, between frames.
@MainActor
public protocol MCPToolProvider: AnyObject {
    /// Every tool, in listing order.
    var tools: [MCPTool] { get }
    /// Runs the tool `name`. Unknown names never get here (the server checks `tools`).
    func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome
}

/// Supplies the server's resources. Called on the main actor, between frames.
@MainActor
public protocol MCPResourceProvider: AnyObject {
    var resources: [MCPResource] { get }
    var resourceTemplates: [MCPResourceTemplate] { get }
    /// The contents of `uri`, or nil if there is no such resource.
    func readResource(_ uri: String) -> [MCPResourceContents]?
}

extension MCPResourceProvider {
    public var resourceTemplates: [MCPResourceTemplate] { [] }
}

/// A failure answered with a JSON-RPC error.
public struct MCPError: Error, Equatable, Sendable, CustomStringConvertible {
    public var code: Int
    public var message: String
    public var data: JSON?

    public init(code: Int, message: String, data: JSON? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    public static func parseError(_ message: String = "Parse error") -> MCPError { MCPError(code: -32700, message: message) }
    public static func invalidRequest(_ message: String = "Invalid request") -> MCPError { MCPError(code: -32600, message: message) }
    public static func methodNotFound(_ method: String) -> MCPError { MCPError(code: -32601, message: "Method not found: \(method)") }
    public static func invalidParams(_ message: String) -> MCPError { MCPError(code: -32602, message: message) }
    public static func internalError(_ message: String) -> MCPError { MCPError(code: -32603, message: message) }
    /// MCP's code for an unknown resource.
    public static func resourceNotFound(_ uri: String) -> MCPError {
        MCPError(code: -32002, message: "Resource not found", data: ["uri": .string(uri)])
    }

    public var description: String { "\(message) (\(code))" }
}

/// Protocol revisions.
public enum MCPProtocol {
    public static let v2025_06_18 = "2025-06-18"
    public static let v2025_03_26 = "2025-03-26"
    public static let v2024_11_05 = "2024-11-05"
    /// Newest first. `initialize` answers with the client's version when it is one of these,
    /// else with the newest (and the client decides whether it can continue).
    public static let supportedVersions = [v2025_06_18, v2025_03_26, v2024_11_05]
    public static var latest: String { supportedVersions[0] }

    /// The version a server speaks with a client that asked for `requested`.
    public static func negotiate(_ requested: String?) -> String {
        guard let requested else { return latest }
        return supportedVersions.contains(requested) ? requested : latest
    }
}
