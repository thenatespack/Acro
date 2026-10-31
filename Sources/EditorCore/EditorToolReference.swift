import EngineMCP
import Foundation

/// The MCP tool reference (docs/MCPTools.md), generated from the command registry: every tool
/// the editor serves, by namespace, with its title, hints, description, arguments and result
/// fields as the JSON Schemas give them. `swift run Editor --mcp-tool-docs > docs/MCPTools.md`
/// writes it; `ToolReferenceTests` fails when the file is out of date.
@MainActor
public enum EditorToolReference {
    /// Where the reference lives in the repository.
    public static let path = "docs/MCPTools.md"

    public static func markdown() -> String {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let mcp = EditorMCP(session: session)
        let tools = mcp.tools
        let infos = Dictionary(uniqueKeysWithValues: session.commands.all.map { ($0.id.rawValue, $0) })

        var out = """
            # Editor MCP tool reference

            Generated from the editor's command registry by `swift run Editor --mcp-tool-docs > \(path)`;
            `swift test --filter ToolReferenceTests` fails when it is out of date. Every editor command is a tool
            named by its id (see README › Editor › AI control). \(tools.count) tools.

            Hints: **read-only** (changes nothing), **undoable** (one undo step, labeled "AI: …" when an MCP client
            made it), **destructive** (can lose work undo can't bring back; needs `confirm: true`), **idempotent**
            (running it again changes nothing more), **deferred** (answers after a frame or more). Types: entity ids
            are 32-hex strings, assets `asset:<id>[#object]` references, vectors `[x, y, z]` number arrays, `?` marks
            optional arguments.


            """
        let groups = Dictionary(grouping: tools) { String($0.name.split(separator: ".").first ?? "") }
        out += "| Namespace | Tools |\n|---|---|\n"
        for namespace in groups.keys.sorted() {
            let names = groups[namespace]!.map { "[`\($0.name)`](#\(anchor($0.name)))" }.joined(separator: ", ")
            out += "| `\(namespace)` | \(names) |\n"
        }
        for namespace in groups.keys.sorted() {
            out += "\n## \(namespace)\n"
            for tool in groups[namespace]! {
                let info = infos[tool.name]
                out += "\n### `\(tool.name)`\n\n"
                var hints: [String] = []
                if info?.isReadOnly == true { hints.append("read-only") }
                if info?.isUndoable == true { hints.append("undoable") }
                if info?.isDestructive == true { hints.append("destructive") }
                if info?.isIdempotent == true { hints.append("idempotent") }
                if info?.isDeferred == true { hints.append("deferred") }
                out += "**\(tool.title ?? tool.name)**" + (hints.isEmpty ? "" : " · " + hints.map { "_\($0)_" }.joined(separator: ", "))
                out += "\n\n\(tool.description)\n"
                let arguments = fields(tool.inputSchema)
                out += "\nArguments:" + (arguments.isEmpty ? " none.\n" : "\n\n" + arguments.map { "- \($0)" }.joined(separator: "\n") + "\n")
                let results = tool.outputSchema.map(fields) ?? []
                if !results.isEmpty {
                    out += "\nResult:\n\n" + results.map { "- \($0)" }.joined(separator: "\n") + "\n"
                }
            }
        }
        return out
    }

    /// GitHub's heading anchor for "`entity.create`".
    private static func anchor(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    /// "`name`: type — description" for each property of an object schema.
    private static func fields(_ schema: JSON) -> [String] {
        guard let properties = schema["properties"]?.objectValue else { return [] }
        let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
        return properties.keys.sorted().map { key in
            let property = properties[key]!
            var line = "`\(key)\(required.contains(key) ? "" : "?")`: \(type(property))"
            if let description = property["description"]?.stringValue { line += " — \(description)" }
            return line
        }
    }

    /// A short type: `string`, `"a" | "b"`, `number[3]`, `object {a, b?}`, `entity id`…
    private static func type(_ schema: JSON, depth: Int = 0) -> String {
        if let cases = schema["enum"]?.arrayValue {
            // Long lists inside results read better as their type.
            if depth > 0 && cases.count > 6 { return "string (\(cases.count) cases)" }
            return cases.map { $0.text }.joined(separator: " \\| ")
        }
        if let constant = schema["const"] { return constant.text }
        if let options = (schema["anyOf"] ?? schema["oneOf"])?.arrayValue {
            return options.map { type($0, depth: depth) }.joined(separator: " \\| ")
        }
        let kind = schema["type"]?.stringValue ?? (schema["type"]?.arrayValue?.compactMap(\.stringValue).joined(separator: " \\| ") ?? "any")
        switch kind {
        case "array":
            let item = schema["items"].map { type($0, depth: depth + 1) } ?? "any"
            if let n = schema["minItems"]?.intValue, n == schema["maxItems"]?.intValue { return "\(item)[\(n)]" }
            return "[\(item)]"
        case "object":
            guard depth < 2, let properties = schema["properties"]?.objectValue, !properties.isEmpty else { return "object" }
            let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
            let inner = properties.keys.sorted().map { key in
                "\(key)\(required.contains(key) ? "" : "?"): \(type(properties[key]!, depth: depth + 1))"
            }
            return "{" + inner.joined(separator: ", ") + "}"
        case "string":
            if let pattern = schema["pattern"]?.stringValue {
                if pattern == "^[0-9a-f]{32}$" { return "entity id" }
                if pattern.hasPrefix("^asset:") { return "asset reference" }
                return "asset id"
            }
            return "string"
        default:
            return kind
        }
    }
}
