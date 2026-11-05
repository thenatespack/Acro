import Foundation

/// A batch of changes to a table, applied by `DataTable.applying` (the `table.edit` tool and the
/// editor's grid use the same code). Order: renameColumns, columns, removeColumns, removeRows,
/// addRows, updateRows.
public struct DataTableEdit: Codable, Equatable, Sendable {
    /// Old column name → new name (cells follow).
    public var renameColumns: [String: String]?
    /// Columns to add, or to replace by name (their cells stay; a cell that no longer fits is reported by validation).
    public var columns: [DataTableColumn]?
    public var removeColumns: [String]?
    public var removeRows: [String]?
    /// Rows to add (an id already taken gets " 2"…; a missing id becomes "row").
    public var addRows: [DataTableRow]?
    /// Row id → cells to change; null clears a cell back to its default, an "id" key renames the row.
    public var updateRows: [String: JSONValue]?

    public init(renameColumns: [String: String]? = nil, columns: [DataTableColumn]? = nil, removeColumns: [String]? = nil,
                removeRows: [String]? = nil, addRows: [DataTableRow]? = nil, updateRows: [String: JSONValue]? = nil) {
        self.renameColumns = renameColumns
        self.columns = columns
        self.removeColumns = removeColumns
        self.removeRows = removeRows
        self.addRows = addRows
        self.updateRows = updateRows
    }
}

extension DataTable {
    /// `value` for `column`: a string meant for a number or bool column is parsed (so "30" and
    /// "true" from tools or CSV work); anything else is kept as given.
    public func coerced(_ value: JSONValue, for column: DataTableColumn?) -> JSONValue {
        guard let column, case .string(let text) = value else { return value }
        switch column.type {
        case .number, .bool, .color: return DataTableValues.parse(text, as: column) ?? value
        default: return value
        }
    }

    /// This table with `edit` applied. Throws when it names a column or row that doesn't exist.
    public func applying(_ edit: DataTableEdit) throws -> DataTable {
        var table = self
        for (old, new) in (edit.renameColumns ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = table.columns.firstIndex(where: { $0.name == old }) else { throw DataTableError("No column named \(old)") }
            guard new == old || table.column(new) == nil, !Self.reservedColumnNames.contains(new), !new.isEmpty else {
                throw DataTableError("Can't rename '\(old)' to '\(new)': that name is taken or reserved")
            }
            table.columns[index].name = new
            for r in table.rows.indices { table.rows[r].values[new] = table.rows[r].values.removeValue(forKey: old) }
        }
        for column in edit.columns ?? [] {
            guard !column.name.isEmpty, !Self.reservedColumnNames.contains(column.name) else {
                throw DataTableError("'\(column.name)' isn't a usable column name (empty or reserved)")
            }
            if let index = table.columns.firstIndex(where: { $0.name == column.name }) { table.columns[index] = column } else { table.columns.append(column) }
        }
        if let names = edit.removeColumns, !names.isEmpty {
            let missing = names.filter { table.column($0) == nil }
            guard missing.isEmpty else { throw DataTableError("No column named \(missing.joined(separator: ", "))") }
            table.columns.removeAll { names.contains($0.name) }
            for r in table.rows.indices { for name in names { table.rows[r].values[name] = nil } }
        }
        if let ids = edit.removeRows, !ids.isEmpty {
            let missing = ids.filter { table.rowIndex(id: $0) == nil }
            guard missing.isEmpty else { throw DataTableError("No row with id \(missing.joined(separator: ", "))") }
            table.rows.removeAll { ids.contains($0.id) }
        }
        for var row in edit.addRows ?? [] {
            row.id = table.uniqueRowID(row.id)
            for (key, value) in row.values { row.values[key] = table.coerced(value, for: table.column(key)) }
            table.rows.append(row)
        }
        for (id, changes) in (edit.updateRows ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = table.rowIndex(id: id) else { throw DataTableError("No row with id \(id)") }
            guard case .object(let fields) = changes else { throw DataTableError("updateRows[\(id)] must be an object of cells") }
            for (key, value) in fields.sorted(by: { $0.key < $1.key }) {
                if key == "id" {
                    guard case .string(let newID) = value, !newID.isEmpty else { throw DataTableError("A row id must be non-empty text") }
                    if newID != id, table.rowIndex(id: newID) != nil { throw DataTableError("A row already has the id \(newID)") }
                    table.rows[index].id = newID
                } else if value == .null {
                    table.rows[index].values[key] = nil
                } else {
                    table.rows[index].values[key] = table.coerced(value, for: table.column(key))
                }
            }
        }
        return table
    }

    /// Sets `column` to `value` (nil: clears it to the default) in the rows with `ids` (all rows when nil).
    public mutating func setCells(column: String, to value: JSONValue?, rows ids: Set<String>? = nil) throws {
        guard let col = self.column(column) else { throw DataTableError("No column named \(column)") }
        let value = value.map { coerced($0, for: col) }
        for r in rows.indices where ids?.contains(rows[r].id) ?? true { rows[r].values[column] = value }
    }
}

// MARK: Filtering

/// A row filter written as text, for the grid's filter box and `table.query`. Terms are
/// separated by spaces (all must match; the word `and` is optional):
///
/// - `goblin`: the word appears (any case) in the row id or any cell.
/// - `hp > 10`, `hp>=10`, `kind == melee`, `kind != ranged`: compare a column ("id" too) with a
///   value. Numbers compare by value, text without regard to case; `<`, `>` on text compare alphabetically.
/// - `name ~ gob`: the cell contains the text; `name !~ gob`: it doesn't.
/// - `"max hp" > 3`: quote names or values with spaces.
public struct DataTableFilter: Equatable, Sendable {
    enum Operation: String, Sendable { case equal = "==", notEqual = "!=", less = "<", lessEqual = "<=", greater = ">", greaterEqual = ">=", contains = "~", notContains = "!~" }

    enum Term: Equatable, Sendable {
        case text(String)
        case compare(column: String, Operation, String)
    }

    let terms: [Term]

    public var isEmpty: Bool { terms.isEmpty }

    public init() { terms = [] }

    /// Parses `text`. Throws for a missing value after an operator.
    public init(_ text: String) throws {
        enum Token { case word(String), quoted(String), op(Operation) }
        var tokens: [Token] = []
        let chars = Array(text)
        var i = 0
        let opChars = Set("<>=!~")
        while i < chars.count {
            let ch = chars[i]
            if ch.isWhitespace { i += 1; continue }
            if ch == "\"" {
                var s = ""
                i += 1
                while i < chars.count, chars[i] != "\"" { s.append(chars[i]); i += 1 }
                i += 1
                tokens.append(.quoted(s))
            } else if opChars.contains(ch) {
                var s = ""
                while i < chars.count, opChars.contains(chars[i]) { s.append(chars[i]); i += 1 }
                guard let op = Operation(rawValue: s == "=" ? "==" : s) else { throw DataTableError("Unknown operator '\(s)' in filter") }
                tokens.append(.op(op))
            } else {
                var s = ""
                while i < chars.count, !chars[i].isWhitespace, chars[i] != "\"", !opChars.contains(chars[i]) { s.append(chars[i]); i += 1 }
                tokens.append(.word(s))
            }
        }
        func string(_ t: Token) -> String? {
            switch t { case .word(let s), .quoted(let s): return s; case .op: return nil }
        }
        var terms: [Term] = []
        var k = 0
        while k < tokens.count {
            if k + 1 < tokens.count, case .op(let op) = tokens[k + 1], let column = string(tokens[k]) {
                guard k + 2 < tokens.count, let value = string(tokens[k + 2]) else { throw DataTableError("Filter: '\(column) \(op.rawValue)' needs a value") }
                terms.append(.compare(column: column, op, value))
                k += 3
            } else if case .op(let op) = tokens[k] {
                throw DataTableError("Filter: '\(op.rawValue)' needs a column before it")
            } else if case .word(let w) = tokens[k], w.lowercased() == "and" {
                k += 1
            } else if let s = string(tokens[k]) {
                terms.append(.text(s))
                k += 1
            }
        }
        self.terms = terms
    }

    /// Throws when a term names a column the table doesn't have.
    public func validate(for table: DataTable) throws {
        for case .compare(let column, _, _) in terms where column != "id" && table.column(column) == nil {
            throw DataTableError("Filter: no column named \(column)")
        }
    }

    /// Whether `row` of `table` passes.
    public func matches(_ row: DataTableRow, in table: DataTable) -> Bool {
        for term in terms {
            switch term {
            case .text(let word):
                let w = word.lowercased()
                var hit = row.id.lowercased().contains(w)
                if !hit {
                    hit = table.columns.contains { column in
                        let shown = row.values[column.name] == nil
                            ? DataTableValues.text(of: column.effectiveDefault, type: column.type) : table.displayText(of: row, column)
                        return shown.lowercased().contains(w)
                    }
                }
                if !hit { return false }
            case .compare(let name, let op, let operand):
                guard Self.compare(row, name, op, operand, table) else { return false }
            }
        }
        return true
    }

    private static func compare(_ row: DataTableRow, _ name: String, _ op: Operation, _ operand: String, _ table: DataTable) -> Bool {
        let type: DataTableColumnType
        let value: JSONValue
        if name == "id" {
            type = .text
            value = .string(row.id)
        } else if let column = table.column(name) {
            type = column.type
            value = table.value(of: row, column)
        } else {
            return false
        }
        if type == .number, let lhs = DataTableValues.number(value), let rhs = Double(operand.trimmingCharacters(in: .whitespaces)), op != .contains, op != .notContains {
            switch op {
            case .equal: return lhs == rhs
            case .notEqual: return lhs != rhs
            case .less: return lhs < rhs
            case .lessEqual: return lhs <= rhs
            case .greater: return lhs > rhs
            case .greaterEqual: return lhs >= rhs
            default: return false
            }
        }
        let lhs = DataTableValues.text(of: value, type: type).lowercased(), rhs = operand.lowercased()
        switch op {
        case .equal: return lhs == rhs
        case .notEqual: return lhs != rhs
        case .less: return lhs < rhs
        case .lessEqual: return lhs <= rhs
        case .greater: return lhs > rhs
        case .greaterEqual: return lhs >= rhs
        case .contains: return lhs.contains(rhs)
        case .notContains: return !lhs.contains(rhs)
        }
    }

    /// The indices of the rows of `table` that pass, in table order.
    public func indices(in table: DataTable) -> [Int] {
        table.rows.indices.filter { matches(table.rows[$0], in: table) }
    }
}
