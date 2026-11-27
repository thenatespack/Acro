import Engine
import Foundation

// Builder tabs keep their forms in a side panel next to their view (`EditorBuilderTab.sidebar`).
// While the Inspector is open, the panel of the builder in front moves into the Inspector
// instead, so the builder's view gets the tab's whole width; it goes back into its tab when
// another builder, the Scene or the Game view comes to the front, or the Inspector closes. A
// popped-out builder (its own window, or floating: `EditorApp.popOutPanel`) keeps its panel.

/// Where a builder's side panel was taken from, to put it back.
@MainActor
struct BuilderSidebarPlacement {
    var panelID: String
    var sidebar: Widget
    var parent: Widget
    var index: Int
    /// The vertical separator before it in the tab, hidden while the panel is away.
    var separator: Widget?
    /// Its fixed width in the tab (the Inspector's width applies there instead).
    var style: LayoutStyle
}

extension EditorApp {
    /// The builder whose side panel belongs in the Inspector: the builder tab in front in the
    /// dock group used last; else the one already there while it stays in front (pressing in the
    /// Inspector or elsewhere keeps it); none once the Scene or Game view was picked.
    func builderShowingInInspector() -> String? {
        guard dock.isOpen(EditorLayout.inspector) else { return nil }
        // A popped-out builder keeps its panel in its own window.
        let builders = zip(EditorBuilderRegistry.modules, builderTabs).compactMap {
            $0.1.sidebar == nil || keepsOwnSidebar($0.0.panelID) ? nil : $0.0.panelID
        }
        if let active = dock.activeGroup?.selectedTab?.id {
            if builders.contains(active) { return active }
            if active == EditorLayout.viewport || active == EditorLayout.game { return nil }
        }
        if let current = builderSidebarPlacement?.panelID, isFront(current), !keepsOwnSidebar(current) { return current }
        return nil
    }

    /// A builder floating over the editor or in a window of its own keeps its side panel there.
    private func keepsOwnSidebar(_ id: String) -> Bool { isFloating(id) || isPoppedOut(id) }

    /// Moves the front builder's side panel into the Inspector, or back into its tab. Call every
    /// frame before the Inspector refreshes (`syncPanels`).
    func syncBuilderSidebars() {
        let wanted = builderShowingInInspector()
        guard wanted != builderSidebarPlacement?.panelID else { return }
        if let placement = builderSidebarPlacement {
            inspector.showBuilderPanel(nil)
            restoreBuilderSidebar(placement)
            builderSidebarPlacement = nil
        }
        guard let wanted, let index = EditorBuilderRegistry.modules.firstIndex(where: { $0.panelID == wanted }),
              let sidebar = builderTabs[index].sidebar, let parent = sidebar.parent,
              let position = parent.children.firstIndex(where: { $0 === sidebar }) else { return }
        let separator = position > 0 ? parent.children[position - 1] as? Separator : nil
        let placement = BuilderSidebarPlacement(panelID: wanted, sidebar: sidebar, parent: parent, index: position,
                                                separator: separator, style: sidebar.style)
        sidebar.removeFromParent()
        separator?.isHidden = true
        sidebar.style.width = nil
        sidebar.style.grow = 1
        sidebar.style.shrink = 1
        let module = EditorBuilderRegistry.modules[index]
        inspector.showBuilderPanel(sidebar, title: module.title,
                                   icon: EditorIcons.panelIconNames[module.panelID].flatMap { EditorIcons.named($0) })
        builderSidebarPlacement = placement
    }

    private func restoreBuilderSidebar(_ placement: BuilderSidebarPlacement) {
        placement.sidebar.removeFromParent()
        placement.sidebar.style = placement.style
        placement.parent.insertChild(placement.sidebar, at: min(placement.index, placement.parent.children.count))
        placement.separator?.isHidden = false
    }
}
