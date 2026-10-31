import Foundation
import Testing
@testable import EditorCore

// docs/MCPTools.md is generated from the command registry. This fails when it is out of date;
// regenerate it with `swift run Editor --mcp-tool-docs > docs/MCPTools.md` (or run this suite
// with UPDATE_TOOL_DOCS=1).

@MainActor @Suite struct ToolReferenceTests {
    @Test func toolReferenceIsUpToDate() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent(EditorToolReference.path)
        let generated = EditorToolReference.markdown()
        if ProcessInfo.processInfo.environment["UPDATE_TOOL_DOCS"] == "1" {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try generated.write(to: url, atomically: true, encoding: .utf8)
        }
        let stored = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        #expect(stored == generated,
                "\(EditorToolReference.path) is out of date: run `swift run Editor --mcp-tool-docs > \(EditorToolReference.path)`")
        // Every tool has a section.
        for info in EditorSession(document: EditorDocument()).commands.all {
            #expect(generated.contains("### `\(info.id)`"))
        }
    }
}
