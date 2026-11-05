import Engine
import Foundation

// The Data Table tab: a grid for one `.table` file, tabbed with the Scene view, with a sidebar form.
//
// - The grid shows one row per table row: an id field, then a cell per column (text fields,
//   checkboxes for bool, dropdowns for enum). Click a header to sort the view (again to reverse);
//   the filter box takes the same text as `table.query` (`hp > 10 kind == ranged goblin`).
//   Cells with a wrong value (reported by validation) have a tooltip saying what is wrong.
// - The sidebar edits the selected column (name, type, default, options, range, target table),
//   applies a value to every shown row (bulk edit), writes the current sort into the file,
//   lists the table's problems and imports / exports CSV.
//
// The file is the truth: every change is written as one undo step of the editor (Ctrl+Z), the
// table reimports (running games read the new data) and the grid is rebuilt. Edits made by
// widget callbacks are applied on the next `update` so no widget is torn down while it handles an event.

@MainActor
public final class DataTableWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The table being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var table = DataTable()
    public private(set) var filterText = ""
    public private(set) var sortColumn: String?
    public private(set) var sortAscending = true
    public private(set) var selectedColumn: String?
    /// The most rows the grid draws at once (filter to reach the others).
    public static let rowLimit = 300

    private let title = Label("Data Table", role: .heading, name: "dataTableTitle")
    private let filterField = TextField(text: "", placeholder: "Filter: hp > 10 kind == ranged goblin", name: "dataTableFilter")
    private let countLabel = Label("", role: .caption, name: "dataTableCount")
    private let gridHost = VStack(spacing: 2, name: "dataTableGrid")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "dataTableSidebar")
    private var shownRevision = -1
    private var dirty = true
    private var pending: (table: DataTable, label: String, select: String?)?
    private var bulkColumn: String?
    private var bulkValue = ""
    private var csvFile = ""
    private var csvMode = DataTableCSV.Mode.replace
    private var shownRows: [Int] = []

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "dataTableWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.table` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isTableFile(id), let table = session.assets?.dataTableContents(of: id) else { return false }
        if asset != id {
            asset = id
            sortColumn = nil
            selectedColumn = table.columns.first?.name
            filterText = ""
            filterField.text = ""
            bulkColumn = nil
            let stem = ((session.assets?.path(of: id) ?? "table") as NSString).deletingPathExtension
            csvFile = stem + ".csv"
        }
        self.table = table
        shownRevision = session.assets?.revision(of: id) ?? 0
        title.text = session.assets?.record(id)?.fileName ?? "Data Table"
        dirty = true
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        pending = nil
        showEmpty()
    }

    // MARK: Chrome

    private func layOutChrome() {
        title.style.shrink = 1
        title.icon = EditorIcons.asset(.model)
        filterField.style.grow = 1
        filterField.onChange = { [unowned self] text in
            filterText = text
            dirty = true
        }
        let addRow = Button("Add Row", role: .primary, name: "dataTableAddRow") { [unowned self] in addRow() }
        addRow.command = TableEditCommand.id.rawValue
        addRow.tooltip = "Add a row with every column at its default"
        let close = Button("Close", name: "dataTableClose") { [unowned self] in close() }
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "dataTableToolbar",
                         [title, filterField, countLabel, addRow, close])
        let scroll = ScrollView(gridHost, name: "dataTableScroll")
        scroll.scrollsHorizontally = true
        scroll.style.grow = 1
        scroll.style.shrink = 1
        let side = ScrollView(sidebar, name: "dataTableSidebarScroll")
        side.style.width = 320
        let body = HStack(spacing: 0, alignment: .stretch, name: "dataTableBody", [scroll, Separator(.vertical), side])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Data Table"
        gridHost.removeAllChildren()
        sidebar.removeAllChildren()
        countLabel.text = ""
        let note = Label("Open a .table file from the Assets panel (New Data Table in its menu, or table.open).", role: .caption)
        note.wraps = true
        gridHost.addChild(note)
    }

    // MARK: Per frame

    /// Call every frame: applies the pending edit, follows the file (undo, MCP, other panels) and rebuilds what changed.
    public func update() {
        guard let asset, let assets = session.assets else { return }
        if let pending {
            self.pending = nil
            commit(pending.table, label: pending.label, select: pending.select)
        }
        let revision = assets.revision(of: asset)
        if revision != shownRevision, let fresh = assets.dataTableContents(of: asset) {
            shownRevision = revision
            if fresh != table { table = fresh }
            dirty = true
        }
        if dirty {
            dirty = false
            rebuild()
        }
    }

    /// Whether an edit is waiting for `update`.
    public var hasPendingEdit: Bool { pending != nil }

    // MARK: Edits

    private func apply(_ edited: DataTable, label: String, select: String? = nil) {
        pending = (edited, label, select)
    }

    private func commit(_ edited: DataTable, label: String, select: String?) {
        guard let asset, session.applyTable(edited, to: asset, label: label) != nil else { return }
        table = session.assets?.dataTableContents(of: asset) ?? edited
        shownRevision = session.assets?.revision(of: asset) ?? shownRevision
        if let select { selectedColumn = select }
        if let selectedColumn, table.column(selectedColumn) == nil { self.selectedColumn = table.columns.first?.name }
        dirty = true
    }

    /// Adds a row (the filter keeps showing it only if it matches; the id is "row", "row 2"…).
    public func addRow() {
        var edited = table
        edited.rows.append(DataTableRow(id: edited.uniqueRowID("row")))
        apply(edited, label: "Add Row")
    }

    func deleteRow(_ id: String) {
        var edited = table
        edited.rows.removeAll { $0.id == id }
        apply(edited, label: "Delete Row")
    }

    /// Writes `text` into a cell (empty clears it to the default). A misfit is kept and flagged.
    public func setCell(row id: String, column name: String, text: String) {
        guard let r = table.rowIndex(id: id), let column = table.column(name) else { return }
        var edited = table
        edited.rows[r].values[name] = text.isEmpty && column.type != .text ? nil : DataTableValues.parse(text, as: column)
        if column.type == .text, text.isEmpty { edited.rows[r].values[name] = nil }
        apply(edited, label: "Edit Cell")
    }

    func setCellValue(row id: String, column name: String, value: JSONValue?) {
        guard let r = table.rowIndex(id: id) else { return }
        var edited = table
        edited.rows[r].values[name] = value
        apply(edited, label: "Edit Cell")
    }

    func renameRow(_ id: String, to new: String) {
        let new = new.trimmingCharacters(in: .whitespaces)
        guard new != id, let r = table.rowIndex(id: id) else { return }
        guard !new.isEmpty, table.rowIndex(id: new) == nil else {
            session.log.warning("Data table: the id '\(new)' is empty or already used")
            dirty = true
            return
        }
        var edited = table
        edited.rows[r].id = new
        apply(edited, label: "Rename Row")
    }

    /// Sets `bulkColumn` to the bulk value (`nil` clears to the default) in every shown row.
    public func applyBulk(clear: Bool = false) {
        guard let name = bulkColumn ?? table.columns.first?.name, let column = table.column(name) else { return }
        let ids = Set(shownRows.map { table.rows[$0].id })
        var edited = table
        let value: JSONValue? = clear || (bulkValue.isEmpty && column.type != .text) ? nil : DataTableValues.parse(bulkValue, as: column)
        do { try edited.setCells(column: name, to: value, rows: ids) } catch { return }
        apply(edited, label: "Set \(name) in \(ids.count) Rows")
    }

    /// Reorders the file's rows by the current sort.
    public func applySortToFile() {
        guard let sortColumn else { return }
        var edited = table
        edited.rows = table.sortedIndices(by: sortColumn, ascending: sortAscending).map { table.rows[$0] }
        apply(edited, label: "Sort Rows")
    }

    func sort(by column: String) {
        if sortColumn == column { sortAscending.toggle() } else { sortColumn = column; sortAscending = true }
        dirty = true
    }

    private func updateColumn(_ name: String, label: String, _ change: (inout DataTableColumn) -> Void) {
        guard let i = table.columns.firstIndex(where: { $0.name == name }) else { return }
        var edited = table
        change(&edited.columns[i])
        apply(edited, label: label)
    }

    private func renameColumn(_ old: String, to new: String) {
        let new = new.trimmingCharacters(in: .whitespaces)
        guard new != old, !new.isEmpty else { dirty = true; return }
        do {
            let edited = try table.applying(DataTableEdit(renameColumns: [old: new]))
            if sortColumn == old { sortColumn = new }
            apply(edited, label: "Rename Column", select: new)
        } catch {
            session.log.warning("Data table: \(error)")
            dirty = true
        }
    }

    func addColumn() {
        var edited = table
        edited.columns.append(DataTableColumn(name: edited.uniqueColumnName("column"), type: .text))
        apply(edited, label: "Add Column", select: edited.columns.last?.name)
    }

    func deleteColumn() {
        guard let name = selectedColumn else { return }
        var edited = table
        edited.columns.removeAll { $0.name == name }
        for r in edited.rows.indices { edited.rows[r].values[name] = nil }
        apply(edited, label: "Delete Column")
    }

    // MARK: Layout

    private func rebuild() {
        gridHost.removeAllChildren()
        sidebar.removeAllChildren()
        let filter = (try? DataTableFilter(filterText)) ?? DataTableFilter()
        let filterError: String? = {
            do { let f = try DataTableFilter(filterText); try f.validate(for: table); return nil } catch { return "\(error)" }
        }()
        var indices = filterError == nil ? filter.indices(in: table) : Array(table.rows.indices)
        if let sortColumn { indices = table.sortedIndices(by: sortColumn, ascending: sortAscending, among: indices) }
        shownRows = indices
        countLabel.text = filterError ?? "\(indices.count) of \(table.rows.count) rows"
        let issues = session.assets?.dataTableIssues(table) ?? table.validate()
        var cellIssues: [String: String] = [:]
        for issue in issues {
            if let row = issue.row, let column = issue.column { cellIssues["\(row)\u{1F}\(column)", default: issue.message] = issue.message }
        }

        gridHost.addChild(headerRow())
        for i in indices.prefix(Self.rowLimit) { gridHost.addChild(gridRow(i, cellIssues)) }
        if indices.count > Self.rowLimit {
            gridHost.addChild(Label("Showing the first \(Self.rowLimit) rows; filter to see others.", role: .caption))
        }
        if table.columns.isEmpty { gridHost.addChild(Label("No columns yet: add one in the sidebar.", role: .caption)) }
        layOutSidebar(issues)
    }

    private static let idWidth: Float = 130
    private static let cellWidth: Float = 130

    private func headerRow() -> Widget {
        func header(_ name: String, width: Float) -> Button {
            let arrow = sortColumn == name ? (sortAscending ? " ▲" : " ▼") : ""
            let button = Button(name + arrow, name: "dataTableHeader.\(name)") { [unowned self] in
                sort(by: name)
                selectedColumn = name == "id" ? selectedColumn : name
            }
            button.style.width = width
            button.tooltip = "Sort by \(name); click again to reverse"
            return button
        }
        let delete = Spacer()
        delete.style.width = 28
        return HStack(spacing: 2, [delete, header("id", width: Self.idWidth)] + table.columns.map { header($0.name, width: Self.cellWidth) })
    }

    private func gridRow(_ index: Int, _ cellIssues: [String: String]) -> Widget {
        let row = table.rows[index]
        let remove = Button("×", name: "dataTableDelete.\(row.id)") { [unowned self] in deleteRow(row.id) }
        remove.style.width = 28
        remove.tooltip = "Delete this row"
        let id = TextField(text: row.id, name: "dataTableCell.\(row.id).id")
        id.style.width = Self.idWidth
        id.onEndEditing = { [unowned self] text in renameRow(row.id, to: text) }
        id.onSubmit = { [unowned self] text in renameRow(row.id, to: text) }
        var widgets: [Widget] = [remove, id]
        for column in table.columns {
            let cell = cellWidget(row: row, column: column)
            cell.style.width = Self.cellWidth
            cell.tooltip = cellIssues["\(row.id)\u{1F}\(column.name)"].map { "Problem: \($0)" } ?? column.type.rawValue
            widgets.append(cell)
        }
        return HStack(spacing: 2, widgets)
    }

    private func cellWidget(row: DataTableRow, column: DataTableColumn) -> Widget {
        let name = "dataTableCell.\(row.id).\(column.name)"
        switch column.type {
        case .bool:
            let current = table.value(of: row, column) == .bool(true)
            let box = Checkbox("", isOn: current, name: name)
            box.onChange = { [unowned self] on in setCellValue(row: row.id, column: column.name, value: .bool(on)) }
            return box
        case .choice:
            var options = ["(default)"] + column.options
            var selected = 0
            if let stored = row.values[column.name] {
                let text = DataTableValues.text(of: stored, type: .choice)
                if let k = column.options.firstIndex(of: text) { selected = k + 1 } else { options.append(text); selected = options.count - 1 }
            }
            let dropdown = Dropdown(options: options, selectedIndex: selected, name: name)
            let choices = column.options
            dropdown.onChange = { [unowned self] k in
                setCellValue(row: row.id, column: column.name, value: k == 0 || k > choices.count ? nil : .string(choices[k - 1]))
            }
            return dropdown
        default:
            let shown = table.displayText(of: row, column)
            let field = TextField(text: shown, placeholder: DataTableValues.text(of: column.effectiveDefault, type: column.type), name: name)
            let commitText: (String) -> Void = { [unowned self] text in
                guard text != shown else { return }
                setCell(row: row.id, column: column.name, text: text)
            }
            field.onEndEditing = commitText
            field.onSubmit = commitText
            return field
        }
    }

    private func layOutSidebar(_ issues: [DataTableIssue]) {
        sidebar.addChild(Label("Columns", role: .secondary))
        let list = ListView(items: table.columns.map { "\($0.name)  ·  \($0.type.rawValue)" }, name: "dataTableColumns")
        list.style.height = 110
        if let selectedColumn, let row = table.columns.firstIndex(where: { $0.name == selectedColumn }) { list.selectRow(row, reveal: true) }
        list.onSelect = { [unowned self] row in
            guard let row, table.columns.indices.contains(row), table.columns[row].name != selectedColumn else { return }
            selectedColumn = table.columns[row].name
            dirty = true
        }
        sidebar.addChild(list)
        let add = Button("Add Column", name: "dataTableAddColumn") { [unowned self] in addColumn() }
        add.command = TableEditCommand.id.rawValue
        let delete = Button("Delete Column", name: "dataTableDeleteColumn") { [unowned self] in deleteColumn() }
        delete.command = TableEditCommand.id.rawValue
        delete.isEnabled = selectedColumn != nil
        sidebar.addChild(HStack(spacing: 6, [add, delete, Spacer()]))
        if let selectedColumn, let column = table.column(selectedColumn) { addColumnForm(column) }

        sidebar.addChild(Separator())
        addBulkSection()

        sidebar.addChild(Separator())
        sidebar.addChild(Label("Sort and filter", role: .secondary))
        let sortNote = sortColumn.map { "Sorted by \($0) \(sortAscending ? "ascending" : "descending") (view only)." } ?? "Click a column header to sort the view."
        sidebar.addChild(note(sortNote))
        let applySort = Button("Write Sort to File", name: "dataTableApplySort") { [unowned self] in applySortToFile() }
        applySort.command = TableEditCommand.id.rawValue
        applySort.isEnabled = sortColumn != nil
        applySort.tooltip = "Reorder the file's rows to match the sort (undoable)"
        sidebar.addChild(HStack(spacing: 6, [applySort, Spacer()]))

        sidebar.addChild(Separator())
        addCSVSection()

        sidebar.addChild(Separator())
        sidebar.addChild(Label(issues.isEmpty ? "No problems" : "Problems (\(issues.count))", role: .secondary))
        for issue in issues.prefix(30) { sidebar.addChild(note(issue.description)) }
        if issues.count > 30 { sidebar.addChild(note("…and \(issues.count - 30) more (table.get lists all)")) }
    }

    private func addColumnForm(_ column: DataTableColumn) {
        sidebar.addChild(Label("Column \(column.name)", role: .secondary))
        func field(_ label: String, _ text: String, placeholder: String = "", name: String, _ set: @escaping (String) -> Void) {
            let editor = TextField(text: text, placeholder: placeholder, name: "dataTableColumn.\(name)")
            editor.style.grow = 1
            editor.onEndEditing = set
            editor.onSubmit = set
            let caption = Label(label, role: .caption)
            caption.style.width = 70
            sidebar.addChild(HStack(spacing: 6, [caption, editor]))
        }
        let name = column.name
        field("Name", name, name: "name") { [unowned self] text in renameColumn(name, to: text) }
        let type = Dropdown(options: DataTableColumnType.allCases.map(\.rawValue),
                            selectedIndex: DataTableColumnType.allCases.firstIndex(of: column.type) ?? 0, name: "dataTableColumn.type")
        type.onChange = { [unowned self] k in
            updateColumn(name, label: "Change Column Type") { $0.type = DataTableColumnType.allCases[k] }
        }
        let typeCaption = Label("Type", role: .caption)
        typeCaption.style.width = 70
        sidebar.addChild(HStack(spacing: 6, [typeCaption, type, Spacer()]))
        field("Default", column.defaultValue.map { DataTableValues.text(of: $0, type: column.type) } ?? "",
              placeholder: DataTableValues.text(of: column.effectiveDefault, type: column.type), name: "default") { [unowned self] text in
            updateColumn(name, label: "Set Default") { $0.defaultValue = text.isEmpty ? nil : DataTableValues.parse(text, as: $0) }
        }
        switch column.type {
        case .choice:
            field("Options", column.options.joined(separator: ", "), placeholder: "melee, ranged", name: "options") { [unowned self] text in
                updateColumn(name, label: "Set Options") {
                    $0.options = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                }
            }
        case .number:
            field("Min", column.min.map(DataTableValues.format) ?? "", name: "min") { [unowned self] text in
                updateColumn(name, label: "Set Minimum") { $0.min = Double(text.trimmingCharacters(in: .whitespaces)) }
            }
            field("Max", column.max.map(DataTableValues.format) ?? "", name: "max") { [unowned self] text in
                updateColumn(name, label: "Set Maximum") { $0.max = Double(text.trimmingCharacters(in: .whitespaces)) }
            }
        case .row:
            field("Table", column.table, placeholder: "(this table)", name: "table") { [unowned self] text in
                updateColumn(name, label: "Set Row Table") { $0.table = text.trimmingCharacters(in: .whitespaces) }
            }
        default: break
        }
    }

    private func addBulkSection() {
        sidebar.addChild(Label("Bulk edit", role: .secondary))
        guard !table.columns.isEmpty else { sidebar.addChild(note("Add a column first.")); return }
        let current = table.columns.firstIndex { $0.name == bulkColumn } ?? 0
        bulkColumn = table.columns[current].name
        let picker = Dropdown(options: table.columns.map(\.name), selectedIndex: current, name: "dataTableBulkColumn")
        picker.onChange = { [unowned self] k in bulkColumn = table.columns[k].name }
        let value = TextField(text: bulkValue, placeholder: "value", name: "dataTableBulkValue")
        value.style.grow = 1
        value.onChange = { [unowned self] text in bulkValue = text }
        sidebar.addChild(HStack(spacing: 6, [picker, value]))
        let apply = Button("Set \(shownRows.count) Shown Rows", name: "dataTableBulkApply") { [unowned self] in applyBulk() }
        apply.command = TableEditCommand.id.rawValue
        apply.isEnabled = !shownRows.isEmpty
        apply.tooltip = "Write the value into this column of every row the filter shows (empty: back to the default)"
        let clear = Button("Clear", name: "dataTableBulkClear") { [unowned self] in applyBulk(clear: true) }
        clear.command = TableEditCommand.id.rawValue
        clear.isEnabled = !shownRows.isEmpty
        sidebar.addChild(HStack(spacing: 6, [apply, clear, Spacer()]))
    }

    private func addCSVSection() {
        sidebar.addChild(Label("CSV", role: .secondary))
        let file = TextField(text: csvFile, placeholder: "Data/enemies.csv", name: "dataTableCSVFile")
        file.style.grow = 1
        file.onChange = { [unowned self] text in csvFile = text }
        let mode = Dropdown(options: DataTableCSV.Mode.allCases.map(\.rawValue),
                            selectedIndex: DataTableCSV.Mode.allCases.firstIndex(of: csvMode) ?? 0, name: "dataTableCSVMode")
        mode.tooltip = "replace: the CSV's rows become the table; merge: rows with a known id update; append: add all"
        mode.onChange = { [unowned self] k in csvMode = DataTableCSV.Mode.allCases[k] }
        sidebar.addChild(file)
        let importButton = Button("Import", name: "dataTableCSVImport") { [unowned self] in importCSV() }
        importButton.command = TableImportCSVCommand.id.rawValue
        importButton.tooltip = "Read the file (relative to Assets/, or absolute); unknown headers become columns"
        let export = Button("Export", name: "dataTableCSVExport") { [unowned self] in exportCSV() }
        export.command = TableExportCSVCommand.id.rawValue
        sidebar.addChild(HStack(spacing: 6, [mode, importButton, export, Spacer()]))
    }

    /// Imports `csvFile` with the chosen mode (unknown headers become columns).
    public func importCSV() {
        guard let asset, !csvFile.isEmpty else { return }
        session.run(TableImportCSVCommand.self, .init(asset: AssetReference(asset), file: csvFile, mode: csvMode, createColumns: true))
        dirty = true
    }

    /// Writes the table to `csvFile`.
    public func exportCSV() {
        guard let asset, !csvFile.isEmpty else { return }
        session.run(TableExportCSVCommand.self, .init(asset: AssetReference(asset), file: csvFile))
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "dataTableNote")
        label.wraps = true
        return label
    }
}
