import Engine
import Foundation

// Open in Pop-Out puts a panel (a builder with its file, the Console, the Assets…) in an OS
// window of its own (`Engine.openWindow`: Metal on macOS, Vulkan on Windows, Linux and macOS),
// which can go on another display. The panel leaves the dock (`DockSpace.showExternally`), its
// content moves into the window's own `UIContext`, and the window's input drives it: its
// widgets, the editor's shortcuts, and a builder's view (`EditorBuilderTab.update`). Closing the
// window docks the panel again. Where no OS window can open (headless runs, a build without a
// desktop backend), and for the Scene and Game views (drawn from the main window's input),
// pop-outs float inside the editor window instead (`EditorApp.popOutPanel`).

/// A panel in an OS window of its own.
@MainActor
final class EditorPopOut {
    let panelID: String
    let window: EngineWindow
    let ui: UIContext
    /// Holds the panel's content and paints the panel background behind it.
    let container: Widget

    init(panelID: String, window: EngineWindow, ui: UIContext, container: Widget) {
        self.panelID = panelID
        self.window = window
        self.ui = ui
        self.container = container
    }
}

extension EditorApp {
    /// Whether panel `id` is in a pop-out window of its own.
    package func isPoppedOut(_ id: String) -> Bool { popOuts.contains { $0.panelID == id } }

    /// The window panel `id` is popped out in (nil when it isn't).
    package func popOutWindow(of id: String) -> EngineWindow? { popOuts.first { $0.panelID == id }?.window }

    /// Panels drawn from the main window's input, which only float inside it.
    static let mainWindowPanels: Set<String> = [EditorLayout.viewport, EditorLayout.game]

    /// Opens panel `id` in an OS window (`windowOpener`, else the engine's) at about the size it
    /// has in the dock. false when none can open here; the caller floats it instead.
    func openPopOutWindow(_ id: String) -> Bool {
        guard let panel = dock.panel(id), !Self.mainWindowPanels.contains(id) else { return false }
        let bounds = dock.frame
        let docked = dock.isOpen(id) && panel.content.frame.width >= 320 && panel.content.frame.height >= 240
            ? Vec2(panel.content.frame.width, panel.content.frame.height + dock.tabBarHeight) : nil
        let size = pointwiseMax(docked ?? Vec2(bounds.width * 0.6, bounds.height * 0.7), Vec2(560, 400)) * ui.uiScale
        let window: EngineWindow?
        do {
            if let windowOpener {
                window = try windowOpener(panel.title, size)
            } else {
                window = try engine?.openWindow(title: panel.title, width: Int(size.x.rounded()), height: Int(size.y.rounded()))
            }
        } catch {
            session.log.warning("Couldn't open a window for \(panel.title) (\(error)); it floats in the editor instead")
            return false
        }
        guard let window else { return false }

        dock.showExternally(id)
        let context = UIContext(theme: ui.theme)
        context.uiScale = ui.uiScale
        context.clipboard = ui.clipboard
        let container = Widget(name: "popOut")
        container.background = ui.theme.panelBackground
        container.isHitTestable = false
        panel.content.removeFromParent()
        panel.content.isHidden = false
        container.addChild(panel.content)
        context.root.addChild(container)
        window.clearColor = Self.clearColor(ui.theme.panelBackground)
        popOuts.append(EditorPopOut(panelID: id, window: window, ui: context, container: container))
        context.setViewport(size: window.size / context.uiScale, scale: window.contentScale * context.uiScale)
        context.layoutIfNeeded()
        window.activate()
        return true
    }

    /// Puts popped-out panel `id` back in the dock and closes its window: a builder where the
    /// Scene view is, another panel where the default layout has it.
    package func dockBack(_ id: String) {
        guard let index = popOuts.firstIndex(where: { $0.panelID == id }) else { return }
        let popOut = popOuts.remove(at: index)
        popOut.ui.resign(input: popOut.window.input)
        if let panel = dock.panel(id) { panel.content.removeFromParent() }
        popOut.window.close()
        dock.endExternal(id)
        if EditorBuilderRegistry.modules.contains(where: { $0.panelID == id }) {
            showBuilderPanel(id)
        } else {
            dock.dock(id, at: EditorLayout.defaultPosition(of: id, in: dock))
            dock.focusPanel(id)
        }
    }

    /// Closes popped-out panel `id` (its window closes; the panel stays closed).
    package func closePopOut(_ id: String) {
        guard let index = popOuts.firstIndex(where: { $0.panelID == id }) else { return }
        let popOut = popOuts.remove(at: index)
        popOut.ui.resign(input: popOut.window.input)
        if let panel = dock.panel(id) { panel.content.removeFromParent() }
        popOut.window.close()
        dock.endExternal(id)
    }

    /// `color` (sRGB) as a window clear color (linear).
    private static func clearColor(_ color: UIColor) -> Vec4 {
        func linear(_ c: Float) -> Float { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return Vec4(linear(color.r), linear(color.g), linear(color.b), 1)
    }

    /// The builder tab shown in panel `id` (nil for other panels).
    private func builderTab(_ id: String) -> EditorBuilderTab? {
        EditorBuilderRegistry.modules.firstIndex { $0.panelID == id }.map { builderTabs[$0] }
    }

    /// Runs each pop-out's frame from its window's input: its UI, the editor's shortcuts while
    /// it has the keyboard, and a builder's view. A window whose close button was clicked docks
    /// its panel again. Call once per frame after the main UI's update.
    func updatePopOuts(dt: Float, shortcutsEnabled: Bool) {
        for popOut in popOuts {
            let window = popOut.window, context = popOut.ui, input = window.input
            if window.closeRequested {
                dockBack(popOut.panelID)
                continue
            }
            if context.theme.name != ui.theme.name {
                context.theme = ui.theme
                popOut.container.background = ui.theme.panelBackground
                window.clearColor = Self.clearColor(ui.theme.panelBackground)
            }
            if context.uiScale != ui.uiScale { context.uiScale = ui.uiScale }
            if let panel = dock.panel(popOut.panelID) { window.title = panel.title }

            func textEditing() -> Bool { context.focusedWidget?.wantsTextInput == true || input.isTextInputActive }
            let textBefore = textEditing(), focusedBefore = context.focusedWidget != nil, overlayBefore = !context.overlays.isEmpty
            context.update(input: input, dt: dt, viewportSize: window.size, scale: window.contentScale)
            let focus = EditorShortcuts.Focus(textEditing: textBefore || textEditing(), overlayOpen: overlayBefore,
                                              widgetFocused: focusedBefore)
            if shortcutsEnabled {
                let claimer = context.focusedWidget as? EditorShortcutClaiming
                var presses = claimer.map { c in input.keyPresses.filter { !c.claimsShortcut($0) } } ?? input.keyPresses
                if context.focusedWidget is RowListView { presses.removeAll { $0.key == .home } }
                for command in shortcuts.actions(for: presses, focus: focus) { invoke(command) }
            }
            if let tab = builderTab(popOut.panelID) {
                if !focus.textEditing, !focus.overlayOpen {
                    tab.handleKeys?(input.keyPresses, input.mousePosition / context.uiScale)
                }
                tab.update?(workspaceInput(input, dt: dt, ui: context), dt)
            }
        }
    }

    /// Lays each pop-out out, readies a builder's view at its window's scale and paints the UI
    /// into its window. Call once per frame after `updatePopOuts`.
    func drawPopOuts() {
        for popOut in popOuts {
            let window = popOut.window, context = popOut.ui
            context.setViewport(size: window.size / context.uiScale, scale: window.contentScale * context.uiScale)
            context.layoutIfNeeded()
            builderTab(popOut.panelID)?.prepareFrame?(context.scale)
            window.ui.beginFrame(framebufferSize: window.framebufferSize, scale: window.contentScale)
            context.draw(into: window.ui)
            window.input.cursor = cursorShape(for: context.desiredCursor)
        }
    }
}
