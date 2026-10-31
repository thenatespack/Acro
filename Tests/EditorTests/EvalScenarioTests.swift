import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Runs the agent eval scenarios in Evals/scenarios (see Evals/README.md) against a headless
// editor through MCP: the fixtures, the setup, the recorded reference transcript (an agent's
// tool calls), then the grading checks. Screenshot steps and checks need a window and are
// skipped here; Evals/run-window.py runs the same specs against a running editor.
// WRITE_EVAL_RESULTS=1 writes each run's step and check outcomes to Evals/results/<id>.json.

private let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// One scenario run: an editor with its panels, no window, and an MCP client named "eval-agent".
@MainActor private final class EvalRun {
    let app: EditorApp
    let mcp: EditorMCP
    let connection: MCPMemoryConnection
    let workspace: URL
    var session: EditorSession { app.session }
    /// What happened, for the results file.
    var log: [JSON] = []

    init() {
        workspace = FileManager.default.temporaryDirectory.appendingPathComponent("Eval-\(UUID().uuidString)").resolvingSymlinksInPath()
        try? FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        mcp = EditorMCP(session: app.session)
        mcp.server.log = { _ in }
        mcp.workspaceRoot = workspace
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = request("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "eval-agent"]])
    }

    func request(_ method: String, _ params: JSON) -> JSON {
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": .string(method), "params": params])
        // Long calls (imports) answer on a later pump.
        for _ in 0..<2000 {
            mcp.pump()
            app.updateWithoutWindow(dt: 1.0 / 60)
            if let reply = connection.output.take().first(where: { $0["id"] == id }) { return reply["result"] ?? reply["error"] ?? nil }
            Thread.sleep(forTimeInterval: 0.002)
        }
        return ["isError": true, "content": [["type": "text", "text": "no answer"]]]
    }

    /// Calls a tool; returns (structured result, error text).
    func call(_ tool: String, _ arguments: JSON) -> (JSON, String?) {
        let result = request("tools/call", ["name": .string(tool), "arguments": arguments])
        let text = result["content"]?.arrayValue?.compactMap { $0["text"]?.stringValue }.joined(separator: "\n") ?? ""
        return result["isError"] == false ? (result["structuredContent"] ?? [:], nil) : (nil, text)
    }

    func prepare(_ fixture: JSON) throws {
        let target = workspace.appendingPathComponent(fixture["to"]?.stringValue ?? "")
        if let source = fixture["copy"]?.stringValue {
            try FileManager.default.copyItem(at: repository.appendingPathComponent(source), to: target)
        } else if fixture["generate"] == "crate-texture" {
            // Planks: brown stripes with dark seams, 64x64.
            var pixels: [UInt8] = []
            for y in 0..<64 {
                for x in 0..<64 {
                    let seam = y % 16 == 0 || x == 0 || x == 63
                    let grain = UInt8((x * 7 + y * 3) % 23)
                    pixels += seam ? [60, 38, 20, 255] : [150 + grain, 105 + grain / 2, 55, 255]
                }
            }
            try Image(width: 64, height: 64, pixels: pixels).pngData().write(to: target)
        }
    }

    /// Runs steps, substituting "@<n>.<path>" (whole strings) and "{@<n>.<path>}" (inside
    /// strings) with parts of earlier results ("$" is edit.batch's own). A step's "expect" lists result fields it must have.
    /// Steps that need a window are skipped headless.
    func run(_ steps: [JSON], phase: String) -> [String] {
        var results: [JSON] = []
        var errors: [String] = []
        for (index, step) in steps.enumerated() {
            let tool = step["tool"]?.stringValue ?? ""
            if step["requires"] == "window" {
                results.append(nil)
                log.append(["phase": .string(phase), "step": .int(Int64(index)), "tool": .string(tool), "outcome": "skipped (needs a window)"])
                continue
            }
            let arguments = Self.substitute(step["arguments"] ?? [:], results)
            let (result, error) = call(tool, arguments)
            results.append(result)
            log.append(["phase": .string(phase), "step": .int(Int64(index)), "tool": .string(tool), "arguments": arguments,
                        "outcome": error.map { .string("error: \($0)") } ?? "ok"])
            if let error { errors.append("\(phase) step \(index) \(tool): \(error)") }
            // A step can state what its result must hold ("expect": {"reason": "stopped"}).
            for (key, expected) in step["expect"]?.objectValue ?? [:] where error == nil && result[key] != expected {
                errors.append("\(phase) step \(index) \(tool): \(key) is \(result[key]?.text ?? "missing"), want \(expected.text)")
            }
        }
        return errors
    }

    static func lookup(_ path: Substring, in results: [JSON]) -> JSON {
        var parts = path.split(separator: ".").map(String.init)
        guard let first = parts.first, let n = Int(first), results.indices.contains(n) else { return nil }
        parts.removeFirst()
        func walk(_ value: JSON, _ rest: ArraySlice<String>) -> JSON {
            guard let key = rest.first else { return value }
            if key == "*" { return .array((value.arrayValue ?? []).map { walk($0, rest.dropFirst()) }) }
            if let i = Int(key), let items = value.arrayValue { return items.indices.contains(i) ? walk(items[i], rest.dropFirst()) : nil }
            return walk(value[key] ?? nil, rest.dropFirst())
        }
        return walk(results[n], parts[...])
    }

    static func substitute(_ json: JSON, _ results: [JSON]) -> JSON {
        switch json {
        case .string(let text):
            if text.hasPrefix("@"), text.dropFirst().first?.isNumber == true { return lookup(text.dropFirst(), in: results) }
            var out = text
            while let open = out.range(of: "{@"), let close = out[open.upperBound...].firstIndex(of: "}") {
                let value = lookup(out[open.upperBound..<close], in: results)
                out.replaceSubrange(open.lowerBound...close, with: value.stringValue ?? value.text)
            }
            return .string(out)
        case .array(let items): return .array(items.map { substitute($0, results) })
        case .object(let members): return .object(members.mapValues { substitute($0, results) })
        default: return json
        }
    }

    // MARK: Grading

    /// The check's outcome: nil when it passed, else why not; "skipped" for window-only checks.
    func grade(_ check: JSON) -> String? {
        let find = check["find"] ?? [:]
        func entities() -> [JSON] { call("entity.find", find).0["entities"]?.arrayValue ?? [] }
        switch check["kind"]?.stringValue {
        case "count":
            let count = entities().count
            if let min = check["min"]?.intValue, count < min { return "found \(count), want at least \(min)" }
            if let max = check["max"]?.intValue, count > max { return "found \(count), want at most \(max)" }
            return nil
        case "entities":
            let found = entities()
            if let min = check["min"]?.intValue, found.count < min { return "found \(found.count), want at least \(min)" }
            for entity in found {
                let details = call("entity.get", ["entity": entity["id"] ?? nil]).0
                for (path, predicate) in check["fields"]?.objectValue ?? [:] {
                    let parts = path.split(separator: ".", maxSplits: 1).map(String.init)
                    let value = details["components"]?[parts[0]].flatMap { Self.value($0, at: parts.count > 1 ? parts[1] : "") } ?? nil
                    if let problem = Self.test(value, predicate) { return "\(entity["name"]?.stringValue ?? "?") \(path): \(problem)" }
                }
            }
            return nil
        case "material":
            let found = entities()
            guard !found.isEmpty else { return "no entity matches" }
            for entity in found {
                let details = call("entity.get", ["entity": entity["id"] ?? nil]).0
                guard let reference = details["components"]?["MeshRenderer"]?["material"]?.stringValue else { continue }
                let (material, error) = call("material.get", ["asset": .string(reference)])
                if let error { return "\(entity["name"]?.stringValue ?? "?"): \(error)" }
                for (path, predicate) in check["fields"]?.objectValue ?? [:] {
                    if let problem = Self.test(Self.value(material["material"] ?? nil, at: path), predicate) {
                        return "\(entity["name"]?.stringValue ?? "?") material \(path): \(problem)"
                    }
                }
            }
            return nil
        case "tool":
            let (result, error) = call(check["tool"]?.stringValue ?? "", check["arguments"] ?? [:])
            if let error { return error }
            for (key, expected) in check["expect"]?.objectValue ?? [:] where result[key] != expected {
                return "\(key) is \(result[key]?.text ?? "missing"), want \(expected.text)"
            }
            return nil
        case "position":
            guard let entity = entities().first else { return "no entity matches" }
            let details = call("entity.get", ["entity": entity["id"] ?? nil]).0
            let axis = check["axis"]?.intValue ?? 0
            guard let value = details["world"]?["position"]?.arrayValue?[axis].doubleValue else { return "no position" }
            if let min = check["min"]?.doubleValue, value < min { return "at \(value), want at least \(min)" }
            if let max = check["max"]?.doubleValue, value > max { return "at \(value), want at most \(max)" }
            return nil
        case "file":
            let url = (session.project?.root ?? workspace).appendingPathComponent(check["path"]?.stringValue ?? "")
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "\(url.lastPathComponent) doesn't exist" }
            if let needle = check["contains"]?.stringValue, !text.contains(needle) { return "doesn't contain \(needle)" }
            return nil
        case "undo":
            let history = session.undo.undoHistory
            if let label = check["label"]?.stringValue, !history.contains(label) { return "no undo step '\(label)' in \(history.prefix(5))" }
            if let prefix = check["prefix"]?.stringValue, history.first?.hasPrefix(prefix) != true { return "last step is \(history.first ?? "none")" }
            return nil
        case "screenshot":
            return "skipped"
        default:
            return "unknown check kind"
        }
    }

    static func value(_ json: JSON, at path: String) -> JSON {
        path.split(separator: ".").reduce(json) { value, key in
            if let i = Int(key), let items = value.arrayValue { return items.indices.contains(i) ? items[i] : nil }
            return value[String(key)] ?? nil
        }
    }

    static func test(_ value: JSON, _ predicate: JSON) -> String? {
        if let expected = predicate["equals"], value != expected { return "is \(value.text), want \(expected.text)" }
        if let prefix = predicate["startsWith"]?.stringValue, value.stringValue?.hasPrefix(prefix) != true {
            return "is \(value.text), want it to start with \(prefix)"
        }
        if let bound = predicate["atLeast"]?.doubleValue, (value.doubleValue ?? -.infinity) < bound { return "is \(value.text), want ≥ \(bound)" }
        if let bound = predicate["atMost"]?.doubleValue, (value.doubleValue ?? .infinity) > bound { return "is \(value.text), want ≤ \(bound)" }
        return nil
    }
}

@MainActor @Suite struct EvalScenarioTests {
    nonisolated static let scenarios: [String] = {
        let folder = repository.appendingPathComponent("Evals/scenarios")
        return ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []).filter { $0.hasSuffix(".json") }.sorted()
    }()

    @Test func scenariosExist() {
        #expect(Self.scenarios.count == 4)
    }

    @Test(arguments: scenarios) func scenario(_ file: String) throws {
        let spec = try JSON(data: Data(contentsOf: repository.appendingPathComponent("Evals/scenarios/\(file)")))
        #expect(spec["prompt"]?.stringValue?.isEmpty == false && spec["checks"]?.arrayValue?.isEmpty == false)
        let run = EvalRun()
        for fixture in spec["fixtures"]?.arrayValue ?? [] { try run.prepare(fixture) }
        let setupErrors = run.run(spec["setup"]?.arrayValue ?? [], phase: "setup")
        #expect(setupErrors.isEmpty, "\(setupErrors)")
        let errors = run.run(spec["transcript"]?.arrayValue ?? [], phase: "transcript")
        #expect(errors.isEmpty, "\(errors)")
        var outcomes: [JSON] = []
        for check in spec["checks"]?.arrayValue ?? [] {
            let problem = run.grade(check)
            outcomes.append(["kind": check["kind"] ?? nil, "description": check["description"] ?? nil,
                             "outcome": .string(problem.map { $0 == "skipped" ? "skipped (needs a window)" : "fail: \($0)" } ?? "pass")])
            if problem != "skipped" {
                #expect(problem == nil, "\(spec["id"]?.stringValue ?? file): \(check["description"]?.stringValue ?? ""): \(problem ?? "")")
            }
        }
        // Every mutating call the agent made is in the activity log, and its steps are labeled.
        #expect(run.session.activity.entries.count >= (spec["transcript"]?.arrayValue?.count ?? 0))
        #expect(run.session.undo.undoHistory.allSatisfy { $0.hasPrefix("AI: ") })
        if ProcessInfo.processInfo.environment["WRITE_EVAL_RESULTS"] == "1" {
            let report: JSON = ["id": spec["id"] ?? nil, "prompt": spec["prompt"] ?? nil, "mode": "headless",
                                "steps": .array(run.log), "checks": .array(outcomes)]
            let folder = repository.appendingPathComponent("Evals/results")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data(report.prettyText.utf8).write(to: folder.appendingPathComponent("\(spec["id"]?.stringValue ?? file).json"))
        }
    }
}
