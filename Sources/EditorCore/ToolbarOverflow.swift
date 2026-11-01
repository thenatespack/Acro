import Engine

/// The toolbar's row: one row always. When the controls don't fit the window, buttons leave the
/// row in `overflowOrder` (least used first) and go into a "More" (») menu at its end instead of
/// wrapping onto a second row.
///
/// Overflowed buttons stay in `ui.snapshot` as items of the row ("overflow:<name>", their title
/// as label, their command, enabled or not), placed on the More button; `ui.click` on one opens
/// the menu and clicks its entry (`EditorUIDriver.click`).
@MainActor
final class ToolbarRow: Stack {
    /// Buttons that may overflow, the first to go first.
    var overflowOrder: [Button] = [] { didSet { setNeedsLayout() } }
    /// Buttons the toolbar hides for its own reasons (Build Game without a project).
    private(set) var unavailable = Set<ObjectIdentifier>()
    /// Buttons in the More menu right now, in toolbar order.
    private(set) var overflowed: [Button] = []
    let moreButton = Button("More", name: "more")

    init(spacing: Float, padding: EdgeInsets, name: String) {
        super.init(.horizontal, spacing: spacing, alignment: .center, padding: padding, name: name)
        moreButton.icon = EditorIcons.named("overflow")
        moreButton.showsTitle = false
        moreButton.tooltip = "More: the toolbar buttons the window has no room for"
        // A UI-only affordance: an agent clicks the overflowed entries themselves (ui.click).
        moreButton.command = UIClickCommand.id.rawValue
        moreButton.isHidden = true
        moreButton.action = { [unowned self] in showOverflowMenu() }
    }

    /// Shows or hides `button` for the toolbar's own reasons (overflow aside).
    func setAvailable(_ button: Button, _ available: Bool) {
        let id = ObjectIdentifier(button)
        guard unavailable.contains(id) == available else { return }
        if available { unavailable.remove(id) } else { unavailable.insert(id) }
        setNeedsLayout()
    }

    override func layoutChildren() {
        fit(width: contentRect.width)
        super.layoutChildren()
    }

    /// Decides what stays in the row for `width` points: everything if it fits, else buttons
    /// leave in `overflowOrder` until the rest plus the More button fit.
    private func fit(width: Float) {
        if moreButton.parent !== self { addChild(moreButton) }
        // Buttons this row manages: the overflow candidates and any it hid before (the order may change).
        let candidates = Set(overflowOrder.map(ObjectIdentifier.init)).union(overflowed.map(ObjectIdentifier.init))
        var out = Set<ObjectIdentifier>()
        func needed(more: Bool) -> Float {
            var items: [Widget] = children.filter { child in
                guard child !== moreButton, child.style.position == .flow else { return false }
                let id = ObjectIdentifier(child)
                if candidates.contains(id) || unavailable.contains(id) { return !unavailable.contains(id) && !out.contains(id) }
                return !child.isHidden
            }
            if more { items.append(moreButton) }
            let widths = items.map { $0.style.shrink > 0 ? $0.style.minWidth : $0.measure(width: nil).x }
            return widths.reduce(0, +) + spacing * Float(max(items.count - 1, 0))
        }
        if needed(more: false) > width + 0.5 {
            for button in overflowOrder where !unavailable.contains(ObjectIdentifier(button)) {
                out.insert(ObjectIdentifier(button))
                if needed(more: true) <= width + 0.5 { break }
            }
        }
        for child in children {
            let id = ObjectIdentifier(child)
            guard candidates.contains(id) || unavailable.contains(id) else { continue }
            let hidden = unavailable.contains(id) || out.contains(id)
            if child.isHidden != hidden { child.isHidden = hidden }
        }
        let hideMore = out.isEmpty
        if moreButton.isHidden != hideMore { moreButton.isHidden = hideMore }
        overflowed = children.compactMap { $0 as? Button }.filter { out.contains(ObjectIdentifier($0)) }
    }

    /// The overflowed buttons as items placed on the More button.
    override var accessibilityItems: [UIAccessibilityItem] {
        super.accessibilityItems + overflowed.map { button in
            UIAccessibilityItem(key: "overflow:\(button.name)", role: .button, label: button.title, frame: moreButton.frame,
                                isEnabled: button.isEnabled, tooltip: button.tooltip(at: button.frame.center),
                                command: button.command)
        }
    }

    /// The menu of overflowed buttons (title, icon, command); picking one runs its action.
    @discardableResult
    func showOverflowMenu() -> PopupMenu? {
        guard let context, !overflowed.isEmpty else { return nil }
        let buttons = overflowed
        let menu = PopupMenu(items: buttons.map(\.title), anchor: moreButton, name: "overflowMenu")
        menu.itemCommandIDs = buttons.map(\.command)
        menu.itemIcons = buttons.map(\.icon)
        menu.disabledIndices = Set(buttons.indices.filter { !buttons[$0].isEffectivelyEnabled })
        menu.onSelect = { index in
            let button = buttons[index]
            if button.isEffectivelyEnabled { button.action?() }
        }
        context.presentOverlay(menu)
        return menu
    }
}
