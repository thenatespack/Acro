import Foundation

/// CSV (RFC 4180) reading and writing for tables. The first line is the header: `id` plus one
/// column name each. Fields containing a comma, a quote or a line break are quoted, with quotes
/// doubled; a quoted field may span lines. Both `\n` and `\r\n` line ends are read; a leading
/// byte order mark is ignored. Colors are written as hex and enums, assets and row references as text.
public enum DataTableCSV {
    /// How `DataTable.importCSV` treats rows already in the table.
    public enum Mode: String, Codable, CaseIterable, Sendable {
        /// The CSV's rows become the table's rows.
        case replace
        /// Rows with an id already present update those cells (other cells stay); new ids are added.
        case merge
        /// Every CSV row is added (a taken id gets " 2"…).
        case append
    }

    // MARK: Parsing

    /// The records of `text` as lists of fields. A trailing line break doesn't start another
    /// record, and blank lines are skipped. Throws on a quote that is never closed.
    public static func parse(_ text: String) throws -> [[String]] {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var fieldWasQuoted = false
        var started = false  // anything seen on this record
        var scalars = Array(text.unicodeScalars)[...]
        if scalars.first == "\u{FEFF}" { scalars = scalars.dropFirst() }
        var i = scalars.startIndex
        func endField() {
            record.append(field)
            field = ""
            fieldWasQuoted = false
        }
        func endRecord() {
            if started || !record.isEmpty || fieldWasQuoted {
                endField()
                records.append(record)
            }
            record = []
            started = false
        }
        while i < scalars.endIndex {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    let next = scalars.index(after: i)
                    if next < scalars.endIndex, scalars[next] == "\"" {
                        field.unicodeScalars.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else {
                switch c {
                case "\"" where field.isEmpty && !fieldWasQuoted:
                    inQuotes = true
                    fieldWasQuoted = true
                    started = true
                case ",":
                    started = true
                    endField()
                case "\n":
                    endRecord()
                case "\r":
                    let next = scalars.index(after: i)
                    if next < scalars.endIndex, scalars[next] == "\n" { i = next }
                    endRecord()
                default:
                    started = true
                    field.unicodeScalars.append(c)
                }
            }
            i = scalars.index(after: i)
        }
        if inQuotes { throw DataTableError("CSV: a quoted field is never closed") }
        endRecord()
        return records
    }

    // MARK: Writing

    /// `field` as a CSV field: quoted when it has a comma, quote, line break or edge spaces.
    public static func escape(_ field: String) -> String {
        let needsQuotes = field.contains { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }
            || field.hasPrefix(" ") || field.hasSuffix(" ")
        guard needsQuotes else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// The whole table as CSV text ("\n" line ends, a trailing one included). Cells the rows
    /// leave empty are written empty, so importing the text back changes nothing.
    public static func export(_ table: DataTable) -> String {
        var lines = [(["id"] + table.columns.map(\.name)).map(escape).joined(separator: ",")]
        for row in table.rows {
            lines.append(([row.id] + table.columns.map { table.displayText(of: row, $0) }).map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

/// What a CSV import did.
public struct DataTableCSVReport: Equatable, Sendable {
    public var added = 0
    public var updated = 0
    /// Header names with no column that were dropped (or became columns).
    public var skippedColumns: [String] = []
    public var createdColumns: [String] = []
    public var warnings: [String] = []
}

extension DataTable {
    /// Reads `csv` into this table. Header names match columns exactly (then without regard to
    /// case); the `id` header (or, lacking one, the first column, with a warning) is the row id.
    /// With `createColumns`, unknown headers become columns typed from their values (all numbers
    /// -> number, all true/false -> bool, else text); otherwise they are skipped and reported.
    public func importingCSV(_ csv: String, mode: DataTableCSV.Mode = .replace, createColumns: Bool = false) throws -> (table: DataTable, report: DataTableCSVReport) {
        let records = try DataTableCSV.parse(csv)
        guard let header = records.first else { throw DataTableError("CSV: no header line") }
        var table = self
        var report = DataTableCSVReport()
        let names = header.map { $0.trimmingCharacters(in: .whitespaces) }
        var idColumn = names.firstIndex { $0.lowercased() == "id" }
        if idColumn == nil {
            idColumn = 0
            report.warnings.append("no 'id' header; using the first column '\(names.first ?? "")' as the row id")
        }
        let body = Array(records.dropFirst())
        // Header index -> the column it fills.
        var mapping: [Int: DataTableColumn] = [:]
        for (i, name) in names.enumerated() where i != idColumn {
            if name.isEmpty { report.skippedColumns.append("(column \(i + 1))"); continue }
            if let column = table.columns.first(where: { $0.name == name }) ?? table.columns.first(where: { $0.name.lowercased() == name.lowercased() }) {
                mapping[i] = column
            } else if createColumns, !Self.reservedColumnNames.contains(name) {
                let values = body.compactMap { i < $0.count && !$0[i].isEmpty ? $0[i] : nil }
                let type: DataTableColumnType
                if !values.isEmpty, values.allSatisfy({ Double($0.trimmingCharacters(in: .whitespaces)) != nil }) { type = .number }
                else if !values.isEmpty, values.allSatisfy({ ["true", "false"].contains($0.lowercased()) }) { type = .bool }
                else { type = .text }
                let column = DataTableColumn(name: name, type: type)
                table.columns.append(column)
                mapping[i] = column
                report.createdColumns.append(name)
            } else {
                report.skippedColumns.append(name)
            }
        }
        if mode == .replace { table.rows = [] }
        for (n, fields) in body.enumerated() {
            let id = idColumn! < fields.count ? fields[idColumn!].trimmingCharacters(in: .whitespaces) : ""
            var values: [String: JSONValue] = [:]
            for (i, column) in mapping where i < fields.count && !fields[i].isEmpty {
                values[column.name] = DataTableValues.parse(fields[i], as: column)
            }
            if fields.count != names.count { report.warnings.append("line \(n + 2): \(fields.count) fields, the header has \(names.count)") }
            if mode == .merge, !id.isEmpty, let index = table.rowIndex(id: id) {
                for (key, value) in values { table.rows[index].values[key] = value }
                report.updated += 1
            } else {
                if id.isEmpty { report.warnings.append("line \(n + 2): no id; named automatically") }
                table.rows.append(DataTableRow(id: table.uniqueRowID(id), values: values))
                report.added += 1
            }
        }
        return (table, report)
    }
}
