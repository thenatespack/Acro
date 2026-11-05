import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The data table as an agent uses it (table.* tools, JSON in and out) and as a user does (the Data Table tab).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("DataTableToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct DataTableToolsTests {
    @MainActor private func project(_ folder: URL) throws -> EditorSession {
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return session
    }

    @Test func newEditQueryAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)

        let created = try call(session, "table.new", [
            "name": "enemies", "folder": "Data",
            "columns": [
                ["name": "hp", "type": "number", "default": 10],
                ["name": "kind", "type": "enum", "options": ["melee", "ranged"]],
                ["name": "drops", "type": "row"],
            ],
            "rows": [["id": "goblin", "hp": 30, "kind": "melee"], ["id": "archer", "hp": "20", "kind": "ranged", "drops": "gold"]],
        ])
        #expect(created["path"] as? String == "Data/enemies.table")
        #expect(created["rows"] as? [String] == ["goblin", "archer"])
        #expect((created["warnings"] as? [String])?.contains { $0.contains("no row 'gold'") } == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isTableFile(id))
        #expect(session.assets?.dataTableContents(of: id)?.rows[1].values["hp"] == .int(20), "text is parsed for number columns")

        let edited = try call(session, "table.edit", [
            "path": "Data/enemies.table",
            "addRows": [["id": "gold", "hp": 1]],
            "updateRows": ["goblin": ["hp": 35, "kind": "magic"]],
            "columns": [["name": "boss", "type": "bool"]],
        ])
        let warnings = try #require(edited["warnings"] as? [String])
        #expect(warnings.contains { $0.contains("'magic' is not one of") })
        #expect(!warnings.contains { $0.contains("no row 'gold'") }, "the dangling reference is fixed by the new row")

        let queried = try call(session, "table.query", ["asset": id.description, "filter": "hp >= 20", "sort": "hp", "descending": true])
        #expect(queried["matched"] as? Int == 2)
        let rows = try #require(queried["rows"] as? [[String: Any]])
        #expect(rows.map { $0["id"] as? String } == ["goblin", "archer"])
        #expect(rows[1]["kind"] as? String == "ranged" && rows[1]["boss"] as? Bool == false)
        let limited = try call(session, "table.query", ["asset": id.description, "limit": 1, "columns": ["hp"]])
        #expect((limited["rows"] as? [[String: Any]])?.first?.keys.sorted() == ["hp", "id"] && limited["matched"] as? Int == 3)
        #expect(throws: (any Error).self) { try call(session, "table.query", ["asset": id.description, "filter": "speed > 3"]) }
        #expect(throws: (any Error).self) { try call(session, "table.query", ["asset": id.description, "sort": "speed"]) }

        let reader = try #require(session.assets?.dataTable(id))
        #expect(reader.row("archer")?.reference("drops")?.number("hp") == 1)

        #expect(session.performUndo())
        #expect(session.assets?.dataTableContents(of: id)?.columns.map(\.name) == ["hp", "kind", "drops"])
        #expect(throws: (any Error).self) { try call(session, "table.edit", ["asset": id.description, "removeRows": ["nobody"]]) }
        #expect(throws: (any Error).self) { try call(session, "table.get", ["path": "Missing.table"]) }

        let got = try call(session, "table.get", ["asset": id.description])
        #expect(((got["table"] as? [String: Any])?["rows"] as? [Any])?.count == 2)
    }

    @Test func csvTools() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let created = try call(session, "table.new", ["name": "items", "columns": [["name": "name", "type": "text"], ["name": "cost", "type": "number"]]])
        let path = try #require(created["path"] as? String)

        let csv = "id,name,cost,rarity\nsword,\"Sword, long\",50,rare\nshield,\"Say \"\"hi\"\"\",30,\n"
        let imported = try call(session, "table.importCsv", ["path": path, "csv": csv, "createColumns": true])
        #expect(imported["added"] as? Int == 2 && imported["createdColumns"] as? [String] == ["rarity"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let table = try #require(session.assets?.dataTableContents(of: id))
        #expect(table.rows[0].values["name"] == .string("Sword, long") && table.rows[1].values["name"] == .string("Say \"hi\""))

        let outFile = folder.appendingPathComponent("out.csv").path
        let exported = try call(session, "table.exportCsv", ["path": path, "file": outFile])
        #expect(exported["csv"] as? String == csv)
        #expect(try String(contentsOfFile: outFile, encoding: .utf8) == exported["csv"] as? String)

        let merged = try call(session, "table.importCsv", ["path": path, "file": outFile, "mode": "merge"])
        #expect(merged["updated"] as? Int == 2)
        #expect(throws: (any Error).self) { try call(session, "table.importCsv", ["path": path]) }
        #expect(session.performUndo(), "the merge changed nothing, so this undoes the import")
        #expect(session.assets?.dataTableContents(of: id)?.rows.isEmpty == true)
    }

    @Test func workspaceEditsFilterAndFollowsUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let table = DataTable(columns: [DataTableColumn(name: "hp", type: .number), DataTableColumn(name: "boss", type: .bool)],
                              rows: [DataTableRow(id: "a", values: ["hp": .int(5)]), DataTableRow(id: "b", values: ["hp": .int(50)]),
                                     DataTableRow(id: "c", values: ["hp": .int(20)])])
        let id = try #require(session.createTableAsset(in: "", name: "units", table: table))

        let workspace = DataTableWorkspace(session: session)
        var opened: AssetID?
        session.onOpenTable = { opened = $0; workspace.open($0) }
        try call(session, "table.open", ["asset": id.description])
        #expect(opened == id && session.openTable == id && workspace.asset == id)
        workspace.update()

        workspace.setCell(row: "a", column: "hp", text: "7")
        #expect(workspace.hasPendingEdit)
        workspace.update()
        #expect(session.assets?.dataTableContents(of: id)?.rows[0].values["hp"] == .int(7))

        workspace.sort(by: "hp")
        workspace.sort(by: "hp")
        workspace.update()
        #expect(workspace.sortAscending == false)
        workspace.applySortToFile()
        workspace.update()
        #expect(session.assets?.dataTableContents(of: id)?.rows.map(\.id) == ["b", "c", "a"])

        workspace.addRow()
        workspace.update()
        #expect(workspace.table.rows.count == 4)
        workspace.renameRow("row", to: "d")
        workspace.update()
        #expect(workspace.table.rows.last?.id == "d")
        workspace.renameRow("d", to: "a")  // taken: refused
        workspace.update()
        #expect(workspace.table.rows.last?.id == "d")

        workspace.addColumn()
        workspace.update()
        #expect(workspace.table.columns.map(\.name) == ["hp", "boss", "column"])
        #expect(workspace.selectedColumn == "column")

        // Undo is seen by the workspace without a reopen.
        #expect(session.performUndo())
        workspace.update()
        #expect(workspace.table.columns.count == 2)

        workspace.close()
        #expect(workspace.asset == nil)
    }
}
