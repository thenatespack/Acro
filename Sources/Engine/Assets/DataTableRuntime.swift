import Foundation

/// A table read by game code, with rows found by id and cells read with their column's type.
///
/// ```swift
/// let enemies = assets.dataTable(path: "Data/enemies.table")
/// let hp = enemies?.row("goblin")?.number("hp") ?? 10
/// let tint = enemies?.row("goblin")?.color("tint")          // Vec4, sRGB
/// let loot = enemies?.row("goblin")?.reference("drops")     // the row "drops" names
/// for row in enemies?.rows ?? [] where row.bool("boss") == true { ... }
/// ```
///
/// A cell that is missing or doesn't fit its column reads as the column's default, so reading
/// never fails midway (`DataTable.validate` reports the misfit). An accessor returns nil only
/// when the column doesn't exist or has another type. Hold on to the `AssetDatabase` lookup,
/// not the reader: after the file is edited (hot reload) the database hands out a new reader.
public final class DataTableReader: Sendable {
    public let table: DataTable
    private let columnIndex: [String: Int]
    private let rowIndex: [String: Int]

    public init(_ table: DataTable) {
        self.table = table
        var columns: [String: Int] = [:]
        for (i, column) in table.columns.enumerated() where columns[column.name] == nil { columns[column.name] = i }
        var rows: [String: Int] = [:]
        for (i, row) in table.rows.enumerated() where rows[row.id] == nil { rows[row.id] = i }
        columnIndex = columns
        rowIndex = rows
    }

    /// Row ids in file order.
    public var ids: [String] { table.rows.map(\.id) }
    public var count: Int { table.rows.count }
    public var columns: [DataTableColumn] { table.columns }

    /// The row with `id` (the first, if the file repeats one).
    public func row(_ id: String) -> DataTableRowView? { rowIndex[id].map { DataTableRowView(reader: self, index: $0) } }

    /// Every row, in file order.
    public var rows: [DataTableRowView] { table.rows.indices.map { DataTableRowView(reader: self, index: $0) } }

    /// The rows that pass a filter written as text (see `DataTableFilter`), in file order.
    public func rows(where filter: String) throws -> [DataTableRowView] {
        let parsed = try DataTableFilter(filter)
        try parsed.validate(for: table)
        return parsed.indices(in: table).map { DataTableRowView(reader: self, index: $0) }
    }

    fileprivate func cell(_ index: Int, _ name: String, as type: DataTableColumnType) -> JSONValue? {
        guard let c = columnIndex[name], table.columns[c].type == type else { return nil }
        return table.value(of: table.rows[index], table.columns[c])
    }

    fileprivate func column(_ name: String) -> DataTableColumn? { columnIndex[name].map { table.columns[$0] } }
}

/// One row of a `DataTableReader`.
public struct DataTableRowView: Sendable {
    let reader: DataTableReader
    let index: Int

    public var id: String { reader.table.rows[index].id }

    public func number(_ column: String) -> Double? { reader.cell(index, column, as: .number).flatMap(DataTableValues.number) }
    public func int(_ column: String) -> Int? { number(column).map { Int($0.rounded()) } }
    public func float(_ column: String) -> Float? { number(column).map { Float($0) } }
    public func bool(_ column: String) -> Bool? { reader.cell(index, column, as: .bool).flatMap(DataTableValues.bool) }
    /// A text cell.
    public func string(_ column: String) -> String? { reader.cell(index, column, as: .text).flatMap(DataTableValues.string) }
    /// An enum cell (one of the column's options).
    public func choice(_ column: String) -> String? { reader.cell(index, column, as: .choice).flatMap(DataTableValues.string) }
    /// A color cell, sRGB RGBA 0...1.
    public func color(_ column: String) -> Vec4? { reader.cell(index, column, as: .color).flatMap(DataTableValues.color) }
    /// An asset cell as written ("" for none): a path under `Assets/` or "asset:<id>". See `AssetDatabase.assetID(forTableValue:)`.
    public func assetPath(_ column: String) -> String? { reader.cell(index, column, as: .asset).flatMap(DataTableValues.string) }
    /// The id a row column holds ("" for none), even when that row is in another table.
    public func referenceID(_ column: String) -> String? { reader.cell(index, column, as: .row).flatMap(DataTableValues.string) }

    /// The row a row column names in this table (nil when empty, missing or the column points at another table).
    public func reference(_ column: String) -> DataTableRowView? {
        guard let c = reader.column(column), c.table.isEmpty, let target = referenceID(column), !target.isEmpty else { return nil }
        return reader.row(target)
    }

    /// The cell as text, whatever the column's type (nil for no such column).
    public func text(_ column: String) -> String? {
        guard let c = reader.column(column) else { return nil }
        return DataTableValues.text(of: reader.table.value(of: reader.table.rows[index], c), type: c.type)
    }
}

/// Imports a `.table` file: it validates that the JSON decodes and warns about problems with
/// the cells and references. A table has no objects; game code reads it with
/// `AssetDatabase.dataTable(_:)`, which reads the file again whenever it is reimported, so
/// edits show up while a game runs. A cooked game keeps the file as it is.
public struct DataTableImporter: AssetImporter {
    public init() {}

    public var name: String { "table" }
    public var fileExtensions: [String] { ["table"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let table: DataTable
        do { table = try AssetJSON.decoder().decode(DataTable.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a data table: \(error)")
        }
        let paths = context.assetsByPath
        for issue in table.validate(assetExists: { DataTableImporter.exists($0, in: paths) }) {
            context.warn(issue.description)
        }
        return ImportedAsset()
    }

    /// Whether `value` names an asset among `paths` (relative to `Assets/`) or an "asset:<id>" among them.
    static func exists(_ value: String, in paths: [String: AssetID]) -> Bool {
        if value.hasPrefix(AssetReference.scheme) {
            guard let reference = AssetReference(value) else { return false }
            return paths.values.contains(reference.asset)
        }
        return paths[DataTableImporter.relativePath(value)] != nil
    }

    static func relativePath(_ value: String) -> String {
        value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
    }
}

extension AssetDatabase {
    /// The asset a table cell names (a path under `Assets/` or "asset:<id>"), if it exists.
    public func assetID(forTableValue value: String) -> AssetID? {
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme) {
            guard let reference = AssetReference(value), record(reference.asset) != nil else { return nil }
            return reference.asset
        }
        return id(forPath: DataTableImporter.relativePath(value))
    }

    /// Writes `table` to a new `.table` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createDataTable(_ table: DataTable, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try table.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.table` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func dataTableContents(of id: AssetID) -> DataTable? {
        guard record(id)?.importer == DataTableImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(DataTable.self, from: data)
    }

    /// Overwrites the `.table` asset `id` with `table` and reimports it. Returns the import's
    /// warnings about it (bad cells, dangling references).
    @discardableResult
    public func writeDataTable(_ table: DataTable, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try table.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The table `id` for game code. The reader is cached until the file is reimported (hot
    /// reload while playing), so call this where you need the data instead of keeping the result.
    /// nil when `id` isn't a readable `.table`.
    public func dataTable(_ id: AssetID) -> DataTableReader? {
        guard record(id)?.importer == DataTableImporter().name else { return nil }
        if pack == nil { _ = asset(id) }  // imports it if out of date, which bumps the revision
        let revision = pack == nil ? self.revision(of: id) : 0
        if let cached = tableReaders[id], cached.revision == revision { return cached.reader }
        let reader = dataTableContents(of: id).map(DataTableReader.init)
        tableReaders[id] = (revision, reader)
        return reader
    }

    /// The table at `path` (relative to `Assets/`; a leading `Assets/` is allowed).
    public func dataTable(path: String) -> DataTableReader? {
        id(forPath: DataTableImporter.relativePath(path)).flatMap { dataTable($0) }
    }

    /// Problems with the table `id`: its own (see `DataTable.validate`) with asset and
    /// cross-table references resolved against the project.
    public func dataTableIssues(of id: AssetID) -> [DataTableIssue] {
        guard let table = dataTableContents(of: id) else { return [] }
        return dataTableIssues(table)
    }

    public func dataTableIssues(_ table: DataTable) -> [DataTableIssue] {
        table.validate(assetExists: { [unowned self] in assetID(forTableValue: $0) != nil },
                       table: { [unowned self] path in id(forPath: DataTableImporter.relativePath(path)).flatMap { dataTableContents(of: $0) } })
    }
}
