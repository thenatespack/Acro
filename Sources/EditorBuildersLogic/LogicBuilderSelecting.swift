import EditorCore
import Engine

// `builder.select` in the Behavior Tree, Dialogue and Visual Script tabs: nodes by id
// (EditorCore/EditorBuilderSelect.swift).

extension BehaviorTreeWorkspace: EditorBuilderSelecting {
    package var selectionAsset: AssetID? { asset }
    package var selectableItems: [String] { tree.nodes.map(\.id) }
    package var selectedItems: [String] { selectedNode.map { [$0] } ?? [] }

    package func selectItem(_ item: String?) throws {
        if let item, tree.node(item) == nil { throw unknownItem(item) }
        select(item)
        update()
    }
}

extension DialogueWorkspace: EditorBuilderSelecting {
    package var selectionAsset: AssetID? { asset }
    package var selectableItems: [String] { dialogue.nodes.map(\.id) }
    package var selectedItems: [String] { selectedNode.map { [$0] } ?? [] }

    package func selectItem(_ item: String?) throws {
        if let item, dialogue.node(item) == nil { throw unknownItem(item) }
        // As a click on the graph does.
        graph.selected = item
        graph.onSelect?(item)
        update()
    }
}

extension VisualScriptWorkspace: EditorBuilderSelecting {
    package var selectionAsset: AssetID? { asset }
    /// The nodes of the body shown (the event graph, or the function open).
    package var selectableItems: [String] { bodyNodes.map(\.id) }
    package var selectedItems: [String] { selection.sorted() }

    package func selectItem(_ item: String?) throws {
        if let item, !bodyNodes.contains(where: { $0.id == item }) { throw unknownItem(item) }
        let ids: Set<String> = item.map { [$0] } ?? []
        canvas.selection = ids
        canvas.onSelect?(ids)
        update()
    }
}
