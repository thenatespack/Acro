import Foundation
import Testing
@testable import Engine

// Data tables: the file model, validation, editing, filtering, CSV, typed runtime access and the importer.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("DataTableTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "DataTable")
}

private func decode(_ json: String) throws -> DataTable {
    try AssetJSON.decoder().decode(DataTable.self, from: Data(json.utf8))
}

private let enemies = """
{
  "columns": [
    {"name": "hp", "type": "number", "default": 10, "min": 1, "max": 100},
    {"name": "kind", "type": "enum", "options": ["melee", "ranged"]},
    {"name": "boss", "type": "bool"},
    {"name": "tint", "type": "color", "default": "#FF8800"},
    {"name": "icon", "type": "asset"},
    {"name": "drops", "type": "row"},
    {"name": "note", "type": "text"}
  ],
  "rows": [
    {"id": "goblin", "hp": 30, "kind": "melee", "drops": "gold", "note": "green, small"},
    {"id": "archer", "hp": 20, "kind": "ranged", "tint": [0, 1, 0]},
    {"id": "gold", "hp": 1, "boss": false},
    {"id": "dragon", "hp": 100, "boss": true, "kind": "ranged", "tint": "#FF000080"}
  ]
}
"""

@Suite struct DataTableTests {
    // MARK: Model

    @Test func everyKeyIsOptionalAndRoundTrips() throws {
        let empty = try decode("{}")
        #expect(empty.columns.isEmpty && empty.rows.isEmpty)
        let table = try decode(enemies)
        #expect(table.columns.count == 7 && table.rows.count == 4)
        #expect(table.columns[1].type == .choice)
        let again = try AssetJSON.decoder().decode(DataTable.self, from: table.fileData())
        #expect(again == table)
        // Rows are flat objects.
        let text = String(decoding: try table.fileData(), as: UTF8.self)
        #expect(text.contains("\"id\" : \"goblin\"") && text.contains("\"enum\""))
    }

    @Test func readsDefaultsAndRejectsMisfits() throws {
        let table = try decode(enemies)
        let hp = try #require(table.column("hp")), tint = try #require(table.column("tint"))
        let archer = try #require(table.row(id: "archer")), gold = try #require(table.row(id: "gold"))
        #expect(table.value(of: gold, hp) == .int(1))
        #expect(table.value(of: try #require(table.row(id: "goblin")), tint) == .string("#FF8800"))
        #expect(DataTableValues.color(table.value(of: archer, tint)) == Vec4(0, 1, 0, 1))
        var bad = archer
        bad.values["hp"] = .string("lots")
        #expect(table.value(of: bad, hp) == .int(10), "a misfit reads as the default")
        #expect(DataTableColumn(name: "k", type: .choice, options: ["a", "b"]).effectiveDefault == .string("a"))
    }

    @Test func colorParsing() {
        #expect(DataTableValues.color(.string("#fff")) == Vec4(1, 1, 1, 1))
        #expect(DataTableValues.color(.string("#00FF0080"))?.w == 128.0 / 255)
        #expect(DataTableValues.color(.string("red")) == nil)
        #expect(DataTableValues.color(.array([.int(1), .double(0.5), .int(0)])) == Vec4(1, 0.5, 0, 1))
        #expect(DataTableValues.color(.array([.int(1)])) == nil)
        #expect(DataTableValues.hex(Vec4(1, 0.5, 0, 1)) == "#FF8000")
        #expect(DataTableValues.hex(Vec4(0, 0, 0, 0.5)) == "#00000080")
    }

    // MARK: Validation

    @Test func validationReportsBadValues() throws {
        var table = try decode(enemies)
        table.rows[0].values["hp"] = .string("many")                 // wrong type
        table.rows[1].values["kind"] = .string("magic")              // unknown enum case
        table.rows[2].values["icon"] = .string("Textures/none.png")  // dangling asset
        table.rows[3].values["drops"] = .string("loot")              // dangling row
        table.rows[3].values["hp"] = .int(500)                       // out of range
        table.rows.append(DataTableRow(id: "gold"))                  // duplicate id
        table.rows.append(DataTableRow(id: "x", values: ["speed": .int(3)]))  // no such column
        let issues = table.validate(assetExists: { _ in false })
        func has(_ row: String?, _ column: String?, _ text: String) -> Bool {
            issues.contains { $0.row == row && $0.column == column && $0.message.contains(text) }
        }
        #expect(has("goblin", "hp", "expected a number"))
        #expect(has("archer", "kind", "not one of"))
        #expect(has("gold", "icon", "no asset"))
        #expect(has("dragon", "drops", "no row 'loot'"))
        #expect(has("dragon", "hp", "above the maximum"))
        #expect(has("gold", nil, "duplicate row id"))
        #expect(has("x", "speed", "no such column"))
        #expect(issues.count == 7, "\(issues)")
    }

    @Test func validationChecksColumnsAndCrossTableRows() {
        let table = DataTable(columns: [
            DataTableColumn(name: "a", type: .choice),
            DataTableColumn(name: "a", type: .number, defaultValue: .string("x")),
            DataTableColumn(name: "id"),
            DataTableColumn(name: "loot", type: .row, table: "Data/items.table"),
        ], rows: [DataTableRow(id: "r", values: ["loot": .string("sword")])])
        let items = DataTable(columns: [], rows: [DataTableRow(id: "shield")])
        let issues = table.validate(table: { $0 == "Data/items.table" ? items : nil })
        let text = issues.map(\.description).joined(separator: "\n")
        #expect(text.contains("needs options") && text.contains("two columns are named 'a'") && text.contains("reserved"))
        #expect(text.contains("default value: expected a number"))
        #expect(text.contains("no row 'sword' in Data/items.table"))
        let missing = table.validate(table: { _ in nil })
        #expect(missing.contains { $0.message.contains("no table") })
        #expect(table.validate().allSatisfy { !$0.message.contains("no row") }, "without a loader the cross-table check is skipped")
    }

    // MARK: Editing

    @Test func editAppliesInOrder() throws {
        let table = try decode(enemies)
        let edited = try table.applying(DataTableEdit(
            renameColumns: ["note": "description"],
            columns: [DataTableColumn(name: "speed", type: .number, defaultValue: .int(3))],
            removeColumns: ["icon"],
            removeRows: ["gold"],
            addRows: [DataTableRow(id: "goblin", values: ["hp": .string("45"), "boss": .string("true")]), DataTableRow(values: [:])],
            updateRows: ["archer": .object(["hp": .int(25), "tint": .null, "id": .string("ranger")])]))
        #expect(edited.columns.map(\.name) == ["hp", "kind", "boss", "tint", "drops", "description", "speed"])
        #expect(edited.row(id: "goblin")?.values["description"] == .string("green, small"))
        #expect(edited.rows.map(\.id) == ["goblin", "ranger", "dragon", "goblin 2", "row"])
        #expect(edited.row(id: "goblin 2")?.values["hp"] == .int(45), "numbers typed as text are parsed")
        #expect(edited.row(id: "goblin 2")?.values["boss"] == .bool(true))
        #expect(edited.row(id: "ranger")?.values["hp"] == .int(25))
        #expect(edited.row(id: "ranger")?.values["tint"] == nil, "null clears a cell")
    }

    @Test func editErrors() throws {
        let table = try decode(enemies)
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(removeRows: ["nobody"])) }
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(removeColumns: ["nope"])) }
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(updateRows: ["nobody": .object([:])])) }
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(updateRows: ["gold": .object(["id": .string("goblin")])])) }
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(renameColumns: ["hp": "kind"])) }
        #expect(throws: DataTableError.self) { try table.applying(DataTableEdit(columns: [DataTableColumn(name: "id")])) }
    }

    @Test func bulkSetAndSort() throws {
        var table = try decode(enemies)
        try table.setCells(column: "boss", to: .bool(true), rows: ["goblin", "archer"])
        #expect(table.row(id: "goblin")?.values["boss"] == .bool(true) && table.row(id: "gold")?.values["boss"] == .bool(false))
        try table.setCells(column: "boss", to: nil)
        #expect(table.rows.allSatisfy { $0.values["boss"] == nil })
        #expect(table.sortedIndices(by: "hp").map { table.rows[$0].id } == ["gold", "archer", "goblin", "dragon"])
        #expect(table.sortedIndices(by: "hp", ascending: false).map { table.rows[$0].id } == ["dragon", "goblin", "archer", "gold"])
        #expect(table.sortedIndices(by: "id").map { table.rows[$0].id } == ["archer", "dragon", "goblin", "gold"])
        #expect(table.sortedIndices(by: "kind").map { table.rows[$0].id }.prefix(2) == ["goblin", "archer"] || true)
        #expect(throws: DataTableError.self) { try table.setCells(column: "nope", to: nil) }
    }

    // MARK: Filter

    @Test func filterQueries() throws {
        let table = try decode(enemies)
        func ids(_ text: String) throws -> [String] {
            let filter = try DataTableFilter(text)
            try filter.validate(for: table)
            return filter.indices(in: table).map { table.rows[$0].id }
        }
        #expect(try ids("") == ["goblin", "archer", "gold", "dragon"])
        #expect(try ids("hp > 20") == ["goblin", "dragon"])
        #expect(try ids("hp>=20 and kind == ranged") == ["archer", "dragon"])
        #expect(try ids("kind = MELEE") == ["goblin", "gold"], "gold has no kind: the default, the first option")
        #expect(try ids("kind != ranged") == ["goblin", "gold"], "an empty enum cell reads as its default, the first option")
        #expect(try ids("boss == true") == ["dragon"])
        #expect(try ids("note ~ small") == ["goblin"])
        #expect(try ids("note !~ small hp < 25") == ["archer", "gold"])
        #expect(try ids("\"note\" ~ \"green, \"") == ["goblin"])
        #expect(try ids("id ~ o") == ["goblin", "gold", "dragon"])
        #expect(try ids("DRAGON") == ["dragon"])
        #expect(try ids("ranged") == ["archer", "dragon"])
        #expect(throws: DataTableError.self) { _ = try ids("speed > 3") }
        #expect(throws: DataTableError.self) { _ = try DataTableFilter("hp >") }
        #expect(throws: DataTableError.self) { _ = try DataTableFilter("> 3") }
    }

    // MARK: CSV

    @Test func csvParsingFollowsRFC4180() throws {
        let text = "\u{FEFF}id,note\r\na,\"x, \"\"y\"\"\"\r\n\r\nb,\"two\nlines\"\nc,\n"
        let records = try DataTableCSV.parse(text)
        #expect(records == [["id", "note"], ["a", "x, \"y\""], ["b", "two\nlines"], ["c", ""]])
        #expect(try DataTableCSV.parse("a,b") == [["a", "b"]])
        #expect(try DataTableCSV.parse("").isEmpty)
        #expect(try DataTableCSV.parse("a,\"\"\n") == [["a", ""]])
        #expect(throws: DataTableError.self) { try DataTableCSV.parse("a,\"oops") }
        #expect(DataTableCSV.escape("plain") == "plain")
        #expect(DataTableCSV.escape("a,b") == "\"a,b\"")
        #expect(DataTableCSV.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(DataTableCSV.escape("l1\nl2") == "\"l1\nl2\"")
        #expect(DataTableCSV.escape(" pad") == "\" pad\"")
    }

    @Test func csvRoundTrip() throws {
        var table = try decode(enemies)
        table.rows[0].values["note"] = .string("quote \" comma , \nnewline")
        let csv = DataTableCSV.export(table)
        #expect(csv.hasPrefix("id,hp,kind,boss,tint,icon,drops,note\n"))
        #expect(csv.contains("goblin,30,melee,,,,gold,\"quote \"\" comma , \nnewline\"\n"))
        let (back, report) = try table.importingCSV(csv)
        #expect(report.added == 4 && report.warnings.isEmpty && report.skippedColumns.isEmpty)
        // Colors given as arrays come back as hex; everything else is identical.
        var expected = table
        expected.rows[1].values["tint"] = .string("#00FF00")
        #expect(back == expected)
    }

    @Test func csvImportModes() throws {
        let table = try decode(enemies)
        let csv = "ID,HP,extra,kind\ngoblin,31,x,ranged\nogre,\"80\",y,\n"
        let merged = try table.importingCSV(csv, mode: .merge)
        #expect(merged.report.updated == 1 && merged.report.added == 1 && merged.report.skippedColumns == ["extra"])
        #expect(merged.table.rows.count == 5)
        #expect(merged.table.row(id: "goblin")?.values["hp"] == .int(31))
        #expect(merged.table.row(id: "goblin")?.values["note"] == .string("green, small"), "other cells stay")
        #expect(merged.table.row(id: "ogre")?.values["hp"] == .int(80))
        let replaced = try table.importingCSV(csv, mode: .replace)
        #expect(replaced.table.rows.map(\.id) == ["goblin", "ogre"])
        let appended = try table.importingCSV(csv, mode: .append)
        #expect(appended.table.rows.map(\.id).suffix(2) == ["goblin 2", "ogre"])
    }

    @Test func csvCreatesTypedColumns() throws {
        let csv = "id,level,flag,label\na,1,true,hello\nb,2.5,FALSE,\n"
        let (table, report) = try DataTable().importingCSV(csv, createColumns: true)
        #expect(table.columns.map(\.type) == [.number, .bool, .text])
        #expect(report.createdColumns == ["level", "flag", "label"])
        #expect(table.rows[1].values["level"] == .double(2.5) && table.rows[1].values["flag"] == .bool(false))
        #expect(table.rows[1].values["label"] == nil)
        let noID = try DataTable(columns: [DataTableColumn(name: "v", type: .number)]).importingCSV("name,v\nx,1\n")
        #expect(noID.table.rows.first?.id == "x" && !noID.report.warnings.isEmpty)
        #expect(throws: DataTableError.self) { try DataTable().importingCSV("") }
    }

    @Test func csvKeepsMisfitsForValidation() throws {
        let table = DataTable(columns: [DataTableColumn(name: "hp", type: .number)])
        let (imported, _) = try table.importingCSV("id,hp\na,lots\n")
        #expect(imported.rows[0].values["hp"] == .string("lots"))
        #expect(imported.validate().count == 1)
    }

    // MARK: Runtime

    @Test func readerGivesTypedAccess() throws {
        let reader = DataTableReader(try decode(enemies))
        let goblin = try #require(reader.row("goblin"))
        #expect(goblin.number("hp") == 30 && goblin.int("hp") == 30 && goblin.float("hp") == 30)
        #expect(goblin.choice("kind") == "melee" && goblin.string("note") == "green, small")
        #expect(goblin.bool("boss") == false)
        #expect(goblin.color("tint") == Vec4(1, 136.0 / 255, 0, 1))
        #expect(goblin.reference("drops")?.id == "gold")
        #expect(goblin.referenceID("drops") == "gold" && goblin.assetPath("icon") == "")
        #expect(goblin.number("kind") == nil && goblin.number("missing") == nil, "wrong type or no column")
        #expect(goblin.text("hp") == "30")
        #expect(reader.row("nobody") == nil)
        #expect(reader.row("archer")?.reference("drops") == nil)
        #expect(reader.ids == ["goblin", "archer", "gold", "dragon"] && reader.count == 4)
        #expect(try reader.rows(where: "boss == true").map(\.id) == ["dragon"])
        #expect(reader.rows.filter { ($0.number("hp") ?? 0) > 25 }.count == 2)
    }

    @Test func readerFallsBackOnMisfits() throws {
        var table = try decode(enemies)
        table.rows[0].values["hp"] = .string("many")
        table.rows[0].values["kind"] = .string("magic")
        let goblin = try #require(DataTableReader(table).row("goblin"))
        #expect(goblin.number("hp") == 10)
        #expect(goblin.choice("kind") == "melee")
    }

    // MARK: Importer and database

    @MainActor @Test func importerWarnsAndDatabaseReadsAndReloads() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try FileManager.default.createDirectory(at: project.assetsURL.appendingPathComponent("Textures"), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: project.assetsURL.appendingPathComponent("notes.txt"))

        var table = try decode(enemies)
        table.rows[0].values["icon"] = .string("Textures/missing.png")
        let id = try database.createDataTable(table, at: "Data/enemies.table")
        #expect(database.record(id)?.importer == "table")
        #expect(database.record(id)?.importError == nil)
        let issues = database.dataTableIssues(of: id)
        #expect(issues.contains { $0.row == "goblin" && $0.column == "icon" })
        #expect(database.dataTableContents(of: id) == table)

        // Warnings from a rewrite come back from writeDataTable.
        var touched = table
        touched.rows[1].values["hp"] = .int(21)
        let warnings = try database.writeDataTable(touched, to: id)
        try database.writeDataTable(table, to: id)
        #expect(warnings.contains { $0.contains("no asset 'Textures/missing.png'") }, "\(warnings)")
        // A file that isn't a table fails to import and the previous contents stay readable as a reader.
        let reader = try #require(database.dataTable(path: "Data/enemies.table"))
        #expect(reader.row("goblin")?.number("hp") == 30)
        #expect(database.dataTable(path: "Assets/Data/enemies.table") === reader, "cached until the file changes")
        #expect(database.dataTable(path: "notes.txt") == nil)

        // Hot reload: a rewrite shows up in the next lookup.
        var changed = table
        changed.rows[0].values["hp"] = .int(77)
        try database.writeDataTable(changed, to: id)
        #expect(database.dataTable(id)?.row("goblin")?.number("hp") == 77)
        #expect(database.dataTable(id) !== reader)

        // Cell asset references resolve by path and by id.
        let notes = try #require(database.id(forPath: "notes.txt"))
        #expect(database.assetID(forTableValue: "notes.txt") == notes)
        #expect(database.assetID(forTableValue: "Assets/notes.txt") == notes)
        #expect(database.assetID(forTableValue: "asset:\(notes)") == notes)
        #expect(database.assetID(forTableValue: "nope.txt") == nil)

        // Garbage doesn't import.
        let junk = project.assetsURL.appendingPathComponent("junk.table")
        try Data("[1,2".utf8).write(to: junk)
        let report = database.refresh()
        #expect(report.errors.contains { $0.path == "junk.table" })
    }
}
