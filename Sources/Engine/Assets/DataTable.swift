import Foundation

// Typed spreadsheets for game data: the contents of a `.table` file (JSON, every key optional).
// Columns say what each cell holds; rows are objects keyed by column name plus a unique `id`
// that game code looks them up by. A missing cell takes its column's `default`.
//
// ```json
// {
//   "columns": [
//     {"name": "hp", "type": "number", "default": 10, "min": 1},
//     {"name": "kind", "type": "enum", "options": ["melee", "ranged"]},
//     {"name": "tint", "type": "color", "default": "#FF8800"},
//     {"name": "icon", "type": "asset"},
//     {"name": "drops", "type": "row"}
//   ],
//   "rows": [
//     {"id": "goblin", "hp": 30, "kind": "melee", "drops": "gold"},
//     {"id": "gold", "hp": 1}
//   ]
// }
// ```
//
// Cell values are JSON: numbers, strings, booleans; a color is "#RRGGBB[AA]" or [r, g, b, a]
// (sRGB 0...1); an enum is one of the column's `options`; an asset is a path under `Assets/`
// or "asset:<id>"; a row reference is a row id (of this table, or of the table at the column's
// `table` path). A cell of the wrong kind is kept (so nothing is lost) and reported by
// `DataTable.validate`; reading it gives the column's default.
//
// Game code: `assets.dataTable(path: "Data/enemies.table")?.row("goblin")?.number("hp")`.

/// What a column holds.
public enum DataTableColumnType: String, Codable, CaseIterable, Sendable {
    case number
    case text
    case bool
    /// "#RRGGBB[AA]" or [r, g, b, a] in sRGB 0...1.
    case color
    /// One of the column's `options`.
    case choice = "enum"
    /// A project asset: a path under `Assets/` or "asset:<id>".
    case asset
    /// The id of a row in this table (or in the table at the column's `table`).
    case row
}

/// One column: a name, what its cells hold and what an empty cell means.
public struct DataTableColumn: Codable, Equatable, Sendable {
    public var name: String
    public var type: DataTableColumnType
    /// The value of a row without this cell. nil: 0, "", false, white or the first option.
    public var defaultValue: JSONValue?
    /// The allowed values of an `enum` column.
    public var options: [String]
    /// For a `row` column: the `.table` (path under `Assets/`) whose rows it names; "" is this table.
    public var table: String
    /// For a `number` column: the allowed range (values outside are reported, not clamped).
    public var min: Double?
    public var max: Double?

    public init(name: String = "", type: DataTableColumnType = .text, defaultValue: JSONValue? = nil, options: [String] = [],
                table: String = "", min: Double? = nil, max: Double? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.options = options
        self.table = table
        self.min = min
        self.max = max
    }

    private enum CodingKeys: String, CodingKey { case name, type, defaultValue = "default", options, table, min, max }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "",
                  type: try c.decodeIfPresent(DataTableColumnType.self, forKey: .type) ?? .text,
                  defaultValue: try c.decodeIfPresent(JSONValue.self, forKey: .defaultValue).flatMap { $0 == .null ? nil : $0 },
                  options: try c.decodeIfPresent([String].self, forKey: .options) ?? [],
                  table: try c.decodeIfPresent(String.self, forKey: .table) ?? "",
                  min: try c.decodeIfPresent(Double.self, forKey: .min),
                  max: try c.decodeIfPresent(Double.self, forKey: .max))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(defaultValue, forKey: .defaultValue)
        if !options.isEmpty { try c.encode(options, forKey: .options) }
        if !table.isEmpty { try c.encode(table, forKey: .table) }
        try c.encodeIfPresent(min, forKey: .min)
        try c.encodeIfPresent(max, forKey: .max)
    }

    /// What an empty cell of this column reads as: `defaultValue` when it fits, else the type's zero.
    public var effectiveDefault: JSONValue {
        if let defaultValue, DataTableValues.problem(with: defaultValue, in: self) == nil { return defaultValue }
        switch type {
        case .number: return .int(0)
        case .text, .asset, .row: return .string("")
        case .bool: return .bool(false)
        case .color: return .string("#FFFFFF")
        case .choice: return .string(options.first ?? "")
        }
    }
}

/// One row: its id and the cells it sets. On disk it is one flat object: `{"id": "goblin", "hp": 30}`.
public struct DataTableRow: Codable, Equatable, Sendable {
    public var id: String
    /// Cells by column name; a column missing here uses its default.
    public var values: [String: JSONValue]

    public init(id: String = "", values: [String: JSONValue] = [:]) {
        self.id = id
        self.values = values
    }

    public init(from decoder: any Decoder) throws {
        guard case .object(var fields) = try JSONValue(from: decoder) else {
            throw DecodingError.typeMismatch(DataTableRow.self, .init(codingPath: decoder.codingPath, debugDescription: "a row is an object"))
        }
        if case .string(let id)? = fields.removeValue(forKey: "id") { self.id = id } else { id = "" }
        values = fields.filter { $0.value != .null }
    }

    public func encode(to encoder: any Encoder) throws {
        var fields = values
        fields["id"] = .string(id)
        try JSONValue.object(fields).encode(to: encoder)
    }
}

/// A problem found by `DataTable.validate`: where it is and what is wrong.
public struct DataTableIssue: Codable, Equatable, Sendable, CustomStringConvertible {
    /// The row id (nil for a problem with a column or the table).
    public var row: String?
    public var column: String?
    public var message: String

    public init(row: String? = nil, column: String? = nil, _ message: String) {
        self.row = row
        self.column = column
        self.message = message
    }

    public var description: String {
        var place = ""
        if let row { place += "row '\(row)'" }
        if let column { place += (place.isEmpty ? "" : ", ") + "column '\(column)'" }
        return place.isEmpty ? message : "\(place): \(message)"
    }
}

public struct DataTableError: Error, CustomStringConvertible, Equatable, Sendable {
    public var message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// A spreadsheet of typed rows: the contents of a `.table` file.
public struct DataTable: Codable, Equatable, Sendable {
    /// The column names rows can't use (`id` is every row's key).
    public static let reservedColumnNames: Set<String> = ["id"]

    public var columns: [DataTableColumn]
    public var rows: [DataTableRow]

    public init(columns: [DataTableColumn] = [], rows: [DataTableRow] = []) {
        self.columns = columns
        self.rows = rows
    }

    private enum CodingKeys: String, CodingKey { case columns, rows }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        columns = try c.decodeIfPresent([DataTableColumn].self, forKey: .columns) ?? []
        rows = try c.decodeIfPresent([DataTableRow].self, forKey: .rows) ?? []
    }

    /// A new table: one text column and no rows.
    public static var starter: DataTable {
        DataTable(columns: [DataTableColumn(name: "name", type: .text)], rows: [])
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    public func column(_ name: String) -> DataTableColumn? { columns.first { $0.name == name } }
    public func rowIndex(id: String) -> Int? { rows.firstIndex { $0.id == id } }
    public func row(id: String) -> DataTableRow? { rowIndex(id: id).map { rows[$0] } }

    /// A row id not used yet: `base`, else "`base` 2", "`base` 3"…
    public func uniqueRowID(_ base: String) -> String {
        let base = base.isEmpty ? "row" : base
        let ids = Set(rows.map(\.id))
        guard ids.contains(base) else { return base }
        var n = 2
        while ids.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// A column name not used yet.
    public func uniqueColumnName(_ base: String) -> String {
        let base = base.isEmpty ? "column" : base
        let names = Set(columns.map(\.name)).union(Self.reservedColumnNames)
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// What `row` holds in `column` as it reads: the cell if it fits the column, else the column's default.
    public func value(of row: DataTableRow, _ column: DataTableColumn) -> JSONValue {
        if let cell = row.values[column.name], DataTableValues.problem(with: cell, in: column) == nil { return cell }
        return column.effectiveDefault
    }

    /// The cell as the grid shows it: the stored value as text, even when it doesn't fit (so
    /// the mistake is visible). An empty cell shows as "" (the default applies).
    public func displayText(of row: DataTableRow, _ column: DataTableColumn) -> String {
        guard let cell = row.values[column.name] else { return "" }
        return DataTableValues.text(of: cell, type: column.type)
    }

    // MARK: Validation

    /// Problems with the table, in column then row order. `assetExists` says whether an asset
    /// value names a project asset and `table(path)` loads another table for cross-table row
    /// references; a nil closure skips that check.
    public func validate(assetExists: ((String) -> Bool)? = nil, table: ((String) -> DataTable?)? = nil) -> [DataTableIssue] {
        var issues: [DataTableIssue] = []
        var seenColumns: Set<String> = []
        for column in columns {
            if column.name.trimmingCharacters(in: .whitespaces).isEmpty {
                issues.append(DataTableIssue("a column has no name"))
            } else if Self.reservedColumnNames.contains(column.name) {
                issues.append(DataTableIssue(column: column.name, "'\(column.name)' is reserved for the row id"))
            } else if !seenColumns.insert(column.name).inserted {
                issues.append(DataTableIssue(column: column.name, "two columns are named '\(column.name)'; the first is used"))
            }
            if column.type == .choice {
                if column.options.isEmpty { issues.append(DataTableIssue(column: column.name, "an enum column needs options")) }
                if Set(column.options).count != column.options.count { issues.append(DataTableIssue(column: column.name, "duplicate options")) }
            }
            if let low = column.min, let high = column.max, low > high {
                issues.append(DataTableIssue(column: column.name, "min \(low) is above max \(high)"))
            }
            if let value = column.defaultValue, let problem = DataTableValues.problem(with: value, in: column) {
                issues.append(DataTableIssue(column: column.name, "default value: \(problem)"))
            }
        }
        let known = Set(columns.map(\.name))
        var seenRows: Set<String> = []
        var reported: Set<String> = []
        let ownIDs = Set(rows.map(\.id))
        var others: [String: DataTable?] = [:]
        for row in rows {
            if row.id.trimmingCharacters(in: .whitespaces).isEmpty {
                issues.append(DataTableIssue(row: row.id, "a row has no id"))
            } else if !seenRows.insert(row.id).inserted, reported.insert(row.id).inserted {
                issues.append(DataTableIssue(row: row.id, "duplicate row id; lookups find the first"))
            }
            for key in row.values.keys.sorted() where !known.contains(key) {
                issues.append(DataTableIssue(row: row.id, column: key, "no such column"))
            }
            for column in columns {
                guard let cell = row.values[column.name] else { continue }
                if let problem = DataTableValues.problem(with: cell, in: column) {
                    issues.append(DataTableIssue(row: row.id, column: column.name, problem))
                    continue
                }
                guard case .string(let text) = cell, !text.isEmpty else { continue }
                switch column.type {
                case .asset:
                    if let assetExists, !assetExists(text) { issues.append(DataTableIssue(row: row.id, column: column.name, "no asset '\(text)'")) }
                case .row:
                    if column.table.isEmpty {
                        if !ownIDs.contains(text) { issues.append(DataTableIssue(row: row.id, column: column.name, "no row '\(text)'")) }
                    } else if let table {
                        if others[column.table] == nil { others[column.table] = .some(table(column.table)) }
                        if let other = others[column.table] ?? nil {
                            if other.rowIndex(id: text) == nil {
                                issues.append(DataTableIssue(row: row.id, column: column.name, "no row '\(text)' in \(column.table)"))
                            }
                        } else {
                            issues.append(DataTableIssue(row: row.id, column: column.name, "no table '\(column.table)'"))
                        }
                    }
                default: break
                }
            }
        }
        return issues
    }

    // MARK: Sorting

    /// The indices of `rows` (or of `among`) ordered by `column` ("id" sorts by row id):
    /// numbers by value, text without regard to case, bools false first. Stable.
    public func sortedIndices(by column: String, ascending: Bool = true, among indices: [Int]? = nil) -> [Int] {
        let indices = indices ?? Array(rows.indices)
        let col = self.column(column)
        func key(_ i: Int) -> (Double, String) {
            guard let col else { return (0, rows[i].id.lowercased()) }
            let v = value(of: rows[i], col)
            switch col.type {
            case .number: return (DataTableValues.number(v) ?? 0, "")
            case .bool: return (DataTableValues.bool(v) == true ? 1 : 0, "")
            default: return (0, DataTableValues.text(of: v, type: col.type).lowercased())
            }
        }
        let keys = Dictionary(uniqueKeysWithValues: indices.map { ($0, key($0)) })
        return indices.enumerated().sorted { a, b in
            let ka = keys[a.element]!, kb = keys[b.element]!
            if ka.0 != kb.0 { return ascending ? ka.0 < kb.0 : ka.0 > kb.0 }
            if ka.1 != kb.1 { return ascending ? ka.1 < kb.1 : ka.1 > kb.1 }
            return a.offset < b.offset
        }.map(\.element)
    }
}

/// Reading, checking and formatting cell values.
public enum DataTableValues {
    public static func number(_ value: JSONValue) -> Double? {
        switch value {
        case .int(let n): return Double(n)
        case .double(let d): return d.isFinite ? d : nil
        default: return nil
        }
    }

    public static func bool(_ value: JSONValue) -> Bool? {
        if case .bool(let b) = value { return b }
        return nil
    }

    public static func string(_ value: JSONValue) -> String? {
        if case .string(let s) = value { return s }
        return nil
    }

    /// sRGB RGBA 0...1 from "#RGB", "#RRGGBB", "#RRGGBBAA" or [r, g, b(, a)].
    public static func color(_ value: JSONValue) -> Vec4? {
        switch value {
        case .string(let text):
            var hex = text.trimmingCharacters(in: .whitespaces)
            guard hex.hasPrefix("#") else { return nil }
            hex.removeFirst()
            if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
            guard hex.count == 6 || hex.count == 8, let bits = UInt32(hex, radix: 16) else { return nil }
            let hasAlpha = hex.count == 8
            let r = hasAlpha ? (bits >> 24) & 255 : (bits >> 16) & 255
            let g = hasAlpha ? (bits >> 16) & 255 : (bits >> 8) & 255
            let b = hasAlpha ? (bits >> 8) & 255 : bits & 255
            let a = hasAlpha ? bits & 255 : 255
            return Vec4(Float(r) / 255, Float(g) / 255, Float(b) / 255, Float(a) / 255)
        case .array(let items) where items.count == 3 || items.count == 4:
            let numbers = items.compactMap(number)
            guard numbers.count == items.count else { return nil }
            return Vec4(Float(numbers[0]), Float(numbers[1]), Float(numbers[2]), numbers.count == 4 ? Float(numbers[3]) : 1)
        default: return nil
        }
    }

    /// "#RRGGBB", or "#RRGGBBAA" when not opaque.
    public static func hex(_ c: Vec4) -> String {
        func byte(_ x: Float) -> Int { Int((min(max(x, 0), 1) * 255).rounded()) }
        let rgb = String(format: "#%02X%02X%02X", byte(c.x), byte(c.y), byte(c.z))
        return byte(c.w) == 255 ? rgb : rgb + String(format: "%02X", byte(c.w))
    }

    /// Why `value` doesn't fit `column` (nil: it does).
    public static func problem(with value: JSONValue, in column: DataTableColumn) -> String? {
        switch column.type {
        case .number:
            guard let n = number(value) else { return "expected a number, got \(describe(value))" }
            if let low = column.min, n < low { return "\(format(n)) is below the minimum \(format(low))" }
            if let high = column.max, n > high { return "\(format(n)) is above the maximum \(format(high))" }
        case .text, .asset, .row:
            if string(value) == nil { return "expected text, got \(describe(value))" }
        case .bool:
            if bool(value) == nil { return "expected true or false, got \(describe(value))" }
        case .color:
            if color(value) == nil { return "expected a color (\"#RRGGBB\" or [r,g,b,a]), got \(describe(value))" }
        case .choice:
            guard let s = string(value) else { return "expected one of the options, got \(describe(value))" }
            if !column.options.contains(s) { return "'\(s)' is not one of \(column.options.joined(separator: ", "))" }
        }
        return nil
    }

    static func describe(_ value: JSONValue) -> String {
        switch value {
        case .null: return "nothing"
        case .bool(let b): return "\(b)"
        case .int, .double: return text(of: value, type: .number)
        case .string(let s): return "text '\(s)'"
        case .array: return "a list"
        case .object, .entity: return "an object"
        }
    }

    /// A number as short text: "30", "0.25".
    public static func format(_ n: Double) -> String {
        if n == n.rounded(), abs(n) < 1e15 { return String(Int64(n)) }
        return String(n)
    }

    /// `value` as editable text (a color as hex).
    public static func text(of value: JSONValue, type: DataTableColumnType) -> String {
        switch value {
        case .null: return ""
        case .bool(let b): return b ? "true" : "false"
        case .int(let n): return String(n)
        case .double(let d): return d.isFinite ? format(d) : String(d)
        case .string(let s): return s
        case .array:
            if type == .color, let c = color(value) { return hex(c) }
            return (try? String(data: JSONEncoder().encode(value), encoding: .utf8)) ?? ""
        case .object, .entity: return ""
        }
    }

    /// The cell value that `text` means in `column` (colors become hex). With `strict`, nil
    /// when it doesn't fit; otherwise a misfit is kept as text, to be reported by validation.
    public static func parse(_ text: String, as column: DataTableColumn, strict: Bool = false) -> JSONValue? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let value: JSONValue
        switch column.type {
        case .text:
            value = .string(text)
        case .asset, .row, .choice:
            value = .string(trimmed)
        case .number:
            if let d = Double(trimmed), d.isFinite { value = d == d.rounded() && abs(d) < 1e15 ? .int(Int64(d)) : .double(d) }
            else { value = .string(text) }
        case .bool:
            switch trimmed.lowercased() {
            case "true", "yes", "1", "on": value = .bool(true)
            case "false", "no", "0", "off": value = .bool(false)
            default: value = .string(text)
            }
        case .color:
            if let c = color(.string(trimmed)) { value = .string(hex(c)) }
            else if let c = color(.string("#" + trimmed)) { value = .string(hex(c)) }
            else { value = .string(text) }
        }
        if strict, problem(with: value, in: column) != nil { return nil }
        return value
    }
}
