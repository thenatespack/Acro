/// A modal question: dims the whole window and shows a card with a title, a message and Cancel
/// / confirm buttons. Present it with `present(in:)`.
///
/// It covers the viewport, so clicks behind it go nowhere (a click on the dimmed area does
/// nothing). The confirm button starts focused: Enter or Space confirms, Esc or Cancel cancels.
/// Exactly one of `onConfirm` / `onCancel` runs, then the dialog closes. With directional
/// navigation (`UIContext.directionalNavigation` or a gamepad) Left / Right move between the
/// buttons, A confirms the focused one and B cancels. Sizes and colors come from the theme
/// (`dialogPadding`, `dialogSpacing`, `buttonSpacing`, `dialogMaxWidth`, `modalDim`).
@MainActor
public final class ConfirmDialog: Widget {
    public var onConfirm: (() -> Void)?
    public var onCancel: (() -> Void)?
    public let confirmButton: Button
    public let cancelButton: Button
    private let card: VStack
    private let buttons: HStack
    private var resolved = false

    /// - Parameter confirmTitle: the confirm button's title, naming the action ("Delete").
    public init(title: String, message: String, confirmTitle: String, name: String = "confirmDialog") {
        confirmButton = Button(confirmTitle, role: .primary, name: "confirm")
        cancelButton = Button("Cancel", name: "cancel")
        let heading = Label(title, role: .heading, name: "confirmTitle")
        let body = Label(message, role: .body, name: "confirmMessage")
        body.wraps = true
        buttons = HStack(spacing: 8, name: "confirmButtons", [Spacer(), cancelButton, confirmButton])
        card = VStack(spacing: 12, padding: EdgeInsets(18), name: "confirmCard", [heading, body, buttons])
        super.init(name: name)
        card.background = .clear  // drawn by `draw`, with its shadow
        addChild(card)
        confirmButton.action = { [unowned self] in resolve(confirmed: true) }
        cancelButton.action = { [unowned self] in resolve(confirmed: false) }
    }

    public override var accessibilityRole: UIAccessibilityRole { .dialog }
    public override var accessibilityText: String? { (card.children.first as? Label)?.text }

    /// Shows the dialog over everything in `context` and focuses the confirm button.
    public func present(in context: UIContext) {
        context.presentOverlay(self)
        context.focus(confirmButton)
    }

    /// Confirms or cancels as if the button had been clicked.
    public func resolve(confirmed: Bool) {
        guard !resolved else { return }
        resolved = true
        context?.dismissOverlay(self)
        if confirmed { onConfirm?() } else { onCancel?() }
    }

    public override func overlayFrame(in viewport: UIRect) -> UIRect { viewport }

    public override func layoutChildren() {
        let theme = theme
        card.spacing = theme.dialogSpacing
        card.padding = EdgeInsets(theme.dialogPadding)
        buttons.spacing = theme.buttonSpacing
        let width = min(theme.dialogMaxWidth, max(frame.width - 32, 120))
        let height = card.measure(width: width).y
        card.layout(in: UIRect(x: (frame.x + (frame.width - width) / 2).rounded(), y: (frame.y + (frame.height - height) / 2.4).rounded(),
                               width: width, height: height))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown, .pointerUp, .pointerMove, .scroll:
            return true  // modal: nothing behind it reacts
        case .key(let e) where e.key == .escape:
            resolve(confirmed: false)
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim)
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2), radii: UICornerRadii(theme.dialogCornerRadius + 6))
        list.fillRect(card.frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }

    /// Esc (handled by the context) or `dismissOverlay` from elsewhere counts as Cancel.
    public override func overlayDismissed() {
        guard !resolved else { return }
        resolved = true
        onCancel?()
    }
}
