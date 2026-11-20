import EditorCore
import Engine

// `builder.select` in the Animation Graph tab (EditorCore/EditorBuilderSelect.swift), at the
// level shown: "state:<name>", "transition:<index>", "anyState", and the sidebar's
// "parameter:<name>" and "layer:<name>" (their editors open below them).

extension AnimationGraphWorkspace: EditorBuilderSelecting {
    package var selectionAsset: AssetID? { asset }

    package var selectableItems: [String] {
        guard let graph = form?.graph else { return [] }
        return graph.states.map { "state:\($0.name)" } + graph.transitions.indices.map { "transition:\($0)" } + ["anyState"]
            + graph.parameters.map { "parameter:\($0.name)" } + graph.layers.map { "layer:\($0.name)" }
    }

    package var selectedItems: [String] {
        guard let form else { return [] }
        var items: [String] = []
        switch form.selection {
        case .none: break
        case .state(let name): items.append("state:\(name)")
        case .transition(let index): items.append("transition:\(index)")
        case .anyState: items.append("anyState")
        }
        if let parameter = form.selectedParameter { items.append("parameter:\(parameter)") }
        if let layer = form.selectedLayer { items.append("layer:\(layer)") }
        return items
    }

    package func selectItem(_ item: String?) throws {
        guard let form else { return }
        guard let item else {
            form.select(.none)
            form.selectParameter(nil)
            form.selectLayer(nil)
            return
        }
        guard selectableItems.contains(item) else { throw unknownItem(item) }
        if item == "anyState" { return form.select(.anyState) }
        let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
        let value = parts.count == 2 ? parts[1] : ""
        switch parts[0] {
        case "state": form.select(.state(value))
        case "transition": form.select(.transition(Int(value) ?? 0))
        case "parameter": form.selectParameter(value)
        case "layer": form.selectLayer(value)
        default: throw unknownItem(item)
        }
    }
}
