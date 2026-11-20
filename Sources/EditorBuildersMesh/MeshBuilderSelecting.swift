import EditorCore
import Engine

// `builder.select` in the Mesh Builder tab: parts by name (EditorCore/EditorBuilderSelect.swift).

extension MeshBuilderWorkspace: EditorBuilderSelecting {
    package var selectionAsset: AssetID? { asset }
    package var selectableItems: [String] { builder?.build.parts.map(\.name) ?? [] }
    package var selectedItems: [String] { builder?.selectedPart.map { [$0] } ?? [] }

    package func selectItem(_ item: String?) throws {
        guard let builder else { return }
        if let item, !builder.build.parts.contains(where: { $0.name == item }) { throw unknownItem(item) }
        builder.selectPart(item)
    }
}
