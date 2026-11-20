import Engine
import Foundation

// `builder.select`: selects something inside a builder tab (a Mesh Builder part, an Animation
// Graph state, a Dialogue node…) the way a click on its canvas or list does, so an MCP client
// can bring up the panels that only show for a selection (an Animation Graph state's 2D blend
// plot, clip events and layer masks…) and check them with `ui.snapshot` or `view.screenshot`.
// A tab takes part by its workspace adopting `EditorBuilderSelecting` (the builder modules do
// it in their own files).

/// A builder workspace whose selection `builder.select` can read and set.
@MainActor
package protocol EditorBuilderSelecting: AnyObject {
    /// The file the tab shows (nil: none open).
    var selectionAsset: AssetID? { get }
    /// Everything that can be selected now, as `selectItem` takes it ("state:Run", a part's name…).
    var selectableItems: [String] { get }
    /// What is selected, in the same form.
    var selectedItems: [String] { get }
    /// Selects `item` (one of `selectableItems`), or clears the selection for nil. Throws a
    /// `CommandError` naming the choices for anything else.
    func selectItem(_ item: String?) throws
}

extension EditorBuilderSelecting {
    /// The error for an item the tab doesn't have.
    package func unknownItem(_ item: String) -> CommandError {
        let items = selectableItems
        let list = items.prefix(40).joined(separator: ", ")
        return CommandError.failed("Nothing named '\(item)' to select here" + (items.isEmpty ? " (the tab has nothing to select)" : ": pick one of \(list)\(items.count > 40 ? ", …" : "")"))
    }
}

public enum BuilderSelectCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The builder tab: its panel id ("animationGraph") or title ("Animation Graph"), any case. Default: the builder tab in front.
        public var panel: String?
        /// What to select, as `items` lists it ("state:Run", a Mesh Builder part's name, a node id…); "" clears the selection. Leave it out to only read the selection.
        public var item: String?
        public init(panel: String? = nil, item: String? = nil) {
            self.panel = panel
            self.item = item
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The tab's panel id.
        public var panel: String
        /// The file it shows.
        public var asset: AssetID?
        /// What is selected now.
        public var selected: [String]
        /// What can be selected.
        public var items: [String]
    }

    public static let id: CommandID = "builder.select"
    public static let title = "Select in Builder Tab"
    public static let doc = """
        Selects something inside a builder tab as a click there does, bringing up the panels that only show for a selection \
        (check them with ui.snapshot or view.screenshot): `panel` names the tab (panel id or title; default: the builder tab \
        in front), `item` what to select ("" clears; leave it out to just read). Returns the selection and every selectable \
        item. Items: Mesh Builder parts by name; Animation Graph "state:<name>", "transition:<index>", "anyState", \
        "parameter:<name>", "layer:<name>"; Behavior Tree, Dialogue and Visual Script nodes by id. Open the file first \
        (meshBuild.open, animGraph.open…). Needs the editor window.
        """
    public static func isAvailable(in session: EditorSession) -> Bool { session.host is EditorApp }
    public static func unavailableReason(in session: EditorSession) -> String? { noWindowReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let app = session.host as? EditorApp else { throw CommandError.failed("\(title): \(noWindowReason)") }
        let tabs = Array(zip(EditorBuilderRegistry.modules, app.builderTabs))
        let selecting = tabs.filter { $0.1.workspace is any EditorBuilderSelecting }
        let names = selecting.map(\.0.panelID).joined(separator: ", ")
        let found: (EditorBuilderModule, EditorBuilderTab)
        if let panel = arguments.panel?.trimmingCharacters(in: .whitespaces), !panel.isEmpty {
            let key = panel.lowercased()
            guard let tab = tabs.first(where: { $0.0.panelID.lowercased() == key || $0.0.title.lowercased() == key }) else {
                throw CommandError.failed("No builder tab '\(panel)': tabs with a selection are \(names)")
            }
            found = tab
        } else {
            guard let tab = selecting.first(where: { app.isFront($0.0.panelID) }) else {
                throw CommandError.failed("No builder tab with a selection is in front: name one in `panel` (\(names))")
            }
            found = tab
        }
        guard let workspace = found.1.workspace as? any EditorBuilderSelecting else {
            throw CommandError.failed("The \(found.0.title) tab has no selection to set (tabs with one: \(names))")
        }
        if let item = arguments.item {
            guard workspace.selectionAsset != nil else {
                throw CommandError.failed("The \(found.0.title) tab has no file open: open one first")
            }
            let trimmed = item.trimmingCharacters(in: .whitespaces)
            try workspace.selectItem(trimmed.isEmpty ? nil : trimmed)
            app.ui?.layoutIfNeeded()
        }
        return Result(panel: found.0.panelID, asset: workspace.selectionAsset, selected: workspace.selectedItems,
                      items: workspace.selectableItems)
    }
}
