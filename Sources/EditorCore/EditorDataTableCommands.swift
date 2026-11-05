import Engine
import Foundation

/// The data table tools: `table.new`, `table.get`, `table.set`, `table.edit`, `table.query`,
/// `table.importCsv`, `table.exportCsv`, `table.open`.
@MainActor
public enum EditorDataTableCommands {
    public static let all: [any EditorCommand.Type] = [
        TableNewCommand.self,
        TableGetCommand.self,
        TableSetCommand.self,
        TableEditCommand.self,
        TableQueryCommand.self,
        TableImportCSVCommand.self,
        TableExportCSVCommand.self,
        TableOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A data table is a typed spreadsheet for game data: `columns` (each: name, type \
        number|text|bool|color|enum|asset|row, default (value of a row without that cell), options [..] for enum, \
        table (for a row column: another .table path under Assets/; empty means this table), min/max for number) and \
        `rows` (flat objects: {"id": "goblin", "hp": 30, ...}; ids are unique and are how game code finds a row). Values: \
        number, text, bool, color ("#RRGGBB[AA]" or [r,g,b,a] sRGB 0-1), enum (one of options), asset (path under \
        Assets/ or "asset:<id>"), row (a row id). Wrong values are kept and reported in `warnings` (wrong type, unknown \
        enum case, dangling asset or row reference, duplicate ids). Game code reads it with \
        assets.dataTable(path: "Data/enemies.table")?.row("goblin")?.number("hp").
        """
}

extension EditorSession {
    /// Writes a data table to "`name`.table" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createTableAsset(in folder: String, name: String = "New Table", table: DataTable = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Data Table") else {
            log.error("New Data Table: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".table"))
        do {
            let id = try assets.createDataTable(table, at: path)
            log.info("Created data table \(path)")
            return id
        } catch {
            log.error("New Data Table failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.table` file.
    public func isTableFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == DataTableImporter().name
    }

    /// Replaces the contents of the table `id` as one undo step (undo writes the old contents
    /// back). Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyTable(_ table: DataTable, to id: AssetID, label: String = "Edit Data Table") -> [String]? {
        guard let assets, let old = assets.dataTableContents(of: id) else {
            log.error("\(label): \(id) isn't a readable .table file")
            return nil
        }
        guard old != table else { return [] }
        let command = TableFileEditCommand(asset: id, old: old, new: table, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes table edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct TableFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: DataTable
    public let new: DataTable
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: DataTable, new: DataTable, in database: AssetDatabase, label: String = "Edit Data Table") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ table: DataTable) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeDataTable(table, to: asset)
    }
}

/// Arguments naming a `.table` file.
public protocol TableTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The table named by `target` and its contents.
    func resolveTable(_ target: some TableTarget, _ title: String) throws -> (AssetID, DataTable) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isTableFile(id), let table = assets?.dataTableContents(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .table file")
        }
        return (id, table)
    }

    /// Problems with `table` as the project sees it (asset and cross-table references resolved).
    func tableWarnings(_ table: DataTable) -> [String] {
        assets?.dataTableIssues(table).map(\.description) ?? table.validate().map(\.description)
    }

    /// A file for CSV: absolute as given, else relative to `Assets/`.
    func csvURL(_ file: String) -> URL {
        file.hasPrefix("/") ? URL(fileURLWithPath: file) : (assets?.project.url(forAssetPath: file) ?? URL(fileURLWithPath: file))
    }
}

/// What the editing tools return.
public struct TableResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    public var columns: [String]
    public var rowCount: Int
    /// Row ids in file order.
    public var rows: [String]
    /// Problems: wrong values, unknown enum cases, dangling references, duplicate ids, import failures.
    public var warnings: [String]
}

extension TableResult {
    @MainActor init(_ id: AssetID, _ table: DataTable, in session: EditorSession) {
        let record = session.assets?.record(id)
        self.init(asset: id, path: record?.path ?? "", columns: table.columns.map(\.name), rowCount: table.rows.count,
                  rows: table.rows.map(\.id),
                  warnings: session.tableWarnings(table) + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum TableNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Table" (the file gets ".table").
        public var name: String?
        public var columns: [DataTableColumn]?
        public var rows: [DataTableRow]?
        public init(folder: String? = nil, name: String? = nil, columns: [DataTableColumn]? = nil, rows: [DataTableRow]? = nil) {
            self.folder = folder
            self.name = name
            self.columns = columns
            self.rows = rows
        }
    }

    public static let id: CommandID = "table.new"
    public static let title = "New Data Table"
    public static let doc = "Writes a .table file in `folder` (default: the Assets root) with the given `columns` and optional `rows`, and imports it. Returns the asset, column names, row ids and warnings. Change it later with table.edit (add/update/remove rows and columns), table.set (whole contents) or table.importCsv. " + EditorDataTableCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TableResult {
        var table = DataTable(columns: arguments.columns ?? DataTable.starter.columns)
        table = try table.applying(DataTableEdit(addRows: arguments.rows))
        let id = try session.commands.require(session.createTableAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Table", table: table), title)
        return TableResult(id, table, in: session)
    }
}

public enum TableGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        /// The .table file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var table: DataTable
        public var warnings: [String]
    }

    public static let id: CommandID = "table.get"
    public static let title = "Get Data Table"
    public static let doc = "Reads a .table file: its columns and rows as stored, and the problems with its values and references. For filtered or sorted rows use table.query."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, table) = try session.resolveTable(arguments, title)
        let summary = TableResult(id, table, in: session)
        return Result(asset: id, path: summary.path, table: table, warnings: summary.warnings)
    }
}

public enum TableSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var table: DataTable
        public init(asset: AssetReference? = nil, path: String? = nil, table: DataTable) {
            self.asset = asset
            self.path = path
            self.table = table
        }
    }

    public static let id: CommandID = "table.set"
    public static let title = "Set Data Table"
    public static let doc = "Replaces a .table file's whole contents and reimports it (running games read the new data). Undoable. For a few changes, table.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TableResult {
        let (id, _) = try session.resolveTable(arguments, title)
        _ = try session.commands.require(session.applyTable(arguments.table, to: id, label: title), title)
        return TableResult(id, arguments.table, in: session)
    }
}

public enum TableEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Old column name → new name (cells follow).
        public var renameColumns: [String: String]?
        /// Columns to add, or to replace by name (cells stay).
        public var columns: [DataTableColumn]?
        public var removeColumns: [String]?
        /// Row ids to remove.
        public var removeRows: [String]?
        /// Rows to add, e.g. {"id": "orc", "hp": 40} (a taken id gets " 2"…; text meant for number/bool/color cells is parsed).
        public var addRows: [DataTableRow]?
        /// Row id → cells to change, e.g. {"goblin": {"hp": 35, "note": null}}; null clears a cell to its default; an "id" key renames the row.
        public var updateRows: [String: JSONValue]?
        public init(asset: AssetReference? = nil, path: String? = nil, renameColumns: [String: String]? = nil,
                    columns: [DataTableColumn]? = nil, removeColumns: [String]? = nil, removeRows: [String]? = nil,
                    addRows: [DataTableRow]? = nil, updateRows: [String: JSONValue]? = nil) {
            self.asset = asset
            self.path = path
            self.renameColumns = renameColumns
            self.columns = columns
            self.removeColumns = removeColumns
            self.removeRows = removeRows
            self.addRows = addRows
            self.updateRows = updateRows
        }

        var edit: DataTableEdit {
            DataTableEdit(renameColumns: renameColumns, columns: columns, removeColumns: removeColumns,
                          removeRows: removeRows, addRows: addRows, updateRows: updateRows)
        }
    }

    public static let id: CommandID = "table.edit"
    public static let title = "Edit Data Table"
    public static let doc = "Changes part of a .table file in one undoable step, in this order: renameColumns, columns (add or replace by name), removeColumns, removeRows, addRows, updateRows (row id → cells; null clears; \"id\" renames). Running games read the new data. Returns column names, row ids and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TableResult {
        let (id, original) = try session.resolveTable(arguments, title)
        let table: DataTable
        do { table = try original.applying(arguments.edit) } catch { throw CommandError.failed("\(title): \(error)") }
        _ = try session.commands.require(session.applyTable(table, to: id, label: title), title)
        return TableResult(id, table, in: session)
    }
}

public enum TableQueryCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Terms separated by spaces, all must match: a bare word (found in the id or any cell),
        /// `column op value` with op == != < <= > >= ~ (contains) !~, e.g. `hp >= 20 kind == ranged note ~ green`.
        /// Quote names or values with spaces. Empty: every row.
        public var filter: String?
        /// Column to sort by ("id" too).
        public var sort: String?
        public var descending: Bool?
        /// At most this many rows.
        public var limit: Int?
        /// Only these columns (default all).
        public var columns: [String]?
        public init(asset: AssetReference? = nil, path: String? = nil, filter: String? = nil, sort: String? = nil,
                    descending: Bool? = nil, limit: Int? = nil, columns: [String]? = nil) {
            self.asset = asset
            self.path = path
            self.filter = filter
            self.sort = sort
            self.descending = descending
            self.limit = limit
            self.columns = columns
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        /// Rows that matched before `limit`.
        public var matched: Int
        /// The rows as they read in game code: `id` plus every column (defaults filled in; colors as hex).
        public var rows: [JSONValue]
    }

    public static let id: CommandID = "table.query"
    public static let title = "Query Data Table"
    public static let doc = "Finds rows of a .table file by a text `filter` (see its format), optionally sorted and limited. Rows come back as game code reads them: id plus each column's value with defaults filled in."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, table) = try session.resolveTable(arguments, title)
        return try query(table, arguments, asset: id, path: session.assets?.path(of: id) ?? "")
    }

    /// The query's answer for `table` (pure, for tests).
    static func query(_ table: DataTable, _ arguments: Arguments, asset: AssetID, path: String) throws -> Result {
        let filter: DataTableFilter
        do {
            filter = try DataTableFilter(arguments.filter ?? "")
            try filter.validate(for: table)
        } catch { throw CommandError.failed("\(title): \(error)") }
        var indices = filter.indices(in: table)
        if let sort = arguments.sort {
            guard sort == "id" || table.column(sort) != nil else { throw CommandError.failed("\(title): no column named \(sort)") }
            indices = table.sortedIndices(by: sort, ascending: arguments.descending != true, among: indices)
        }
        let matched = indices.count
        if let limit = arguments.limit { indices = Array(indices.prefix(max(limit, 0))) }
        var shown = table.columns
        if let names = arguments.columns {
            let missing = names.filter { table.column($0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("\(title): no column named \(missing.joined(separator: ", "))") }
            shown = names.compactMap(table.column)
        }
        let rows: [JSONValue] = indices.map { i in
            var object: [String: JSONValue] = ["id": .string(table.rows[i].id)]
            for column in shown {
                let value = table.value(of: table.rows[i], column)
                object[column.name] = column.type == .color ? .string(DataTableValues.text(of: value, type: .color)) : value
            }
            return .object(object)
        }
        return Result(asset: asset, path: path, matched: matched, rows: rows)
    }
}

public enum TableImportCSVCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The CSV text.
        public var csv: String?
        /// Or a CSV file (absolute, or relative to `Assets/`).
        public var file: String?
        /// replace (default: the CSV's rows become the table's), merge (rows with a known id update those cells) or append.
        public var mode: DataTableCSV.Mode?
        /// Unknown headers become columns typed from their values (default false: they are skipped and reported).
        public var createColumns: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, csv: String? = nil, file: String? = nil,
                    mode: DataTableCSV.Mode? = nil, createColumns: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.csv = csv
            self.file = file
            self.mode = mode
            self.createColumns = createColumns
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var table: TableResult
        public var added: Int
        public var updated: Int
        public var skippedColumns: [String]
        public var createdColumns: [String]
        public var importWarnings: [String]
    }

    public static let id: CommandID = "table.importCsv"
    public static let title = "Import CSV into Data Table"
    public static let doc = "Reads CSV (RFC 4180: quoted fields, doubled quotes, line breaks inside quotes; the header is `id` plus column names, matched by name) from `csv` or `file` into a .table file as one undoable step. Modes: replace, merge (by id), append. Cells that don't fit their column are kept and reported in the table's warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, original) = try session.resolveTable(arguments, title)
        let text: String
        if let csv = arguments.csv {
            text = csv
        } else if let file = arguments.file {
            do { text = try String(contentsOf: session.csvURL(file), encoding: .utf8) } catch { throw CommandError.failed("\(title): can't read \(file): \(error)") }
        } else {
            throw CommandError.failed("\(title): give `csv` or `file`")
        }
        let imported: (table: DataTable, report: DataTableCSVReport)
        do { imported = try original.importingCSV(text, mode: arguments.mode ?? .replace, createColumns: arguments.createColumns ?? false) } catch {
            throw CommandError.failed("\(title): \(error)")
        }
        _ = try session.commands.require(session.applyTable(imported.table, to: id, label: title), title)
        let r = imported.report
        return Result(table: TableResult(id, imported.table, in: session), added: r.added, updated: r.updated,
                      skippedColumns: r.skippedColumns, createdColumns: r.createdColumns, importWarnings: r.warnings)
    }
}

public enum TableExportCSVCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Also write the CSV to this file (absolute, or relative to `Assets/`).
        public var file: String?
        public init(asset: AssetReference? = nil, path: String? = nil, file: String? = nil) {
            self.asset = asset
            self.path = path
            self.file = file
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var csv: String
        public var file: String?
    }

    public static let id: CommandID = "table.exportCsv"
    public static let title = "Export Data Table as CSV"
    public static let doc = "Returns a .table file as CSV text (header `id` plus the column names; fields with commas, quotes or line breaks are quoted), and writes it to `file` when given."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (_, table) = try session.resolveTable(arguments, title)
        let csv = DataTableCSV.export(table)
        if let file = arguments.file {
            let url = session.csvURL(file)
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try csv.write(to: url, atomically: true, encoding: .utf8)
            } catch { throw CommandError.failed("\(title): can't write \(file): \(error)") }
        }
        return Result(csv: csv, file: arguments.file)
    }
}

public enum TableOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TableTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "table.open"
    public static let title = "Open in Data Table"
    public static let doc = "Opens a .table file in the editor's Data Table tab (a grid with sort, filter, bulk edit and CSV import/export) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"dataTable\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveTable(arguments, title)
        session.openTable = id
        session.onOpenTable?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
