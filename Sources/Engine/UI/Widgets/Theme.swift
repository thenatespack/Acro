import Foundation

/// Colors (sRGB, like every UI color), font, sizes and metrics shared by all widgets. Assign a
/// modified copy, or another preset, to `UIContext.theme` to restyle everything at runtime (it
/// relayouts). `dark()` is the default look; `light()`, `highContrast()` and `game()` are the
/// other built-in presets (`UITheme.named(_:)` looks them up by `name`).
///
/// Per-widget overrides: `styles` maps a style key to a `UIWidgetStyle` whose non-nil fields
/// replace the theme's for matching widgets: a widget's `styleClass` first, then its type name
/// (`"Button"`, `"Slider"`, …). Built-in controls, labels, progress bars and option selectors honor them.
@MainActor
public struct UITheme {
    /// The preset's name ("Dark", "Light", "High Contrast", "Game"), for menus and `named(_:)`.
    public var name = "Dark"

    // Text
    public var font: Font
    public var fontSize: Float = 13
    public var smallFontSize: Float = 11
    public var headingFontSize: Float = 17
    public var textColor = UIColor(hex: 0xe6e9ef)
    public var secondaryTextColor = UIColor(hex: 0x98a1b3)
    /// Disabled text and icons: dimmer than secondary text but at least 3:1 on every surface
    /// (WCAG exempts inactive controls; under 3:1 they were hard to read at all).
    public var disabledTextColor = UIColor(hex: 0x767f92)
    public var placeholderColor = UIColor(hex: 0x7e879a)
    /// Warning and error text (log lines, validation messages) on panels and fields.
    public var warningTextColor = UIColor(hex: 0xe8b04a)
    public var errorTextColor = UIColor(hex: 0xf07167)
    /// X, Y, Z, W: the prefixes of vector fields (`VectorField`).
    public var axisColors = [UIColor(hex: 0xe5484d), UIColor(hex: 0x46b86a), UIColor(hex: 0x4f8cff), UIColor(hex: 0x9aa1b2)]

    // Surfaces
    public var panelBackground = UIColor(hex: 0x1b202b)
    public var panelBorder = UIColor(hex: 0x2f3747)
    public var popupBackground = UIColor(hex: 0x252c3a)
    public var popupBorder = UIColor(hex: 0x3d475c)
    public var shadow = UIColor(0, 0, 0, 0.35)
    /// Laid over the whole window behind a modal dialog.
    public var modalDim = UIColor(0, 0, 0, 0.5)

    // Controls
    public var controlBackground = UIColor(hex: 0x2a3140)
    public var controlHover = UIColor(hex: 0x323a4c)
    public var controlPressed = UIColor(hex: 0x222834)
    public var controlBorder = UIColor(hex: 0x3a4357)
    public var fieldBackground = UIColor(hex: 0x141821)
    // White `accentText` on the accent stays above 4.5:1 (WCAG AA) at rest, hovered and pressed.
    public var accent = UIColor(hex: 0x2a66dc)
    public var accentHover = UIColor(hex: 0x2f6fe6)
    public var accentPressed = UIColor(hex: 0x2458c2)
    public var accentText = UIColor.white
    public var trackBackground = UIColor(hex: 0x394155)
    public var thumb = UIColor(hex: 0xf2f4f8)
    public var focusRing = UIColor(hex: 0x6aa1ff, alpha: 0.9)
    public var textSelection = UIColor(hex: 0x3478f6, alpha: 0.45)
    public var caret = UIColor(hex: 0xf2f4f8)
    public var rowHover = UIColor(hex: 0xffffff, alpha: 0.05)
    public var rowSelected = UIColor(hex: 0x3478f6, alpha: 0.35)
    public var rowSelectedFocused = UIColor(hex: 0x3478f6, alpha: 0.6)
    public var scrollbarThumb = UIColor(hex: 0xffffff, alpha: 0.22)
    public var scrollbarThumbActive = UIColor(hex: 0xffffff, alpha: 0.4)
    public var tooltipBackground = UIColor(hex: 0x252c3a)
    public var tooltipBorder = UIColor(hex: 0x3d475c)
    public var tooltipText = UIColor(hex: 0xe6e9ef)

    // HUD and game menus
    /// Progress and health bars: the empty part, and the colors `ProgressBar.Kind` picks.
    public var barBackground = UIColor(0, 0, 0, 0.45)
    public var healthColor = UIColor(hex: 0x4cc46a)
    public var warningColor = UIColor(hex: 0xf2b33d)
    public var dangerColor = UIColor(hex: 0xe5484d)
    /// Text over the game world (HUD labels, counters, world labels): color and a drop shadow.
    public var hudTextColor = UIColor(hex: 0xf4f6fa)
    public var hudTextShadow = UIColor(0, 0, 0, 0.6)

    // Metrics (points)
    public var spacing: Float = 6
    public var panelPadding: Float = 12
    public var controlHeight: Float = 26
    public var controlPaddingX: Float = 10
    public var cornerRadius: Float = 5
    /// Checkboxes, tooltips, color pickers and drop highlights.
    public var smallCornerRadius: Float = 4
    /// List and tree rows, tab close buttons.
    public var rowCornerRadius: Float = 3
    /// Popup menus, floating panels and the color swatch popup.
    public var popupCornerRadius: Float = 6
    /// The card of a `ConfirmDialog`.
    public var dialogCornerRadius: Float = 8
    /// Borders of controls, fields, popups and tooltips.
    public var borderWidth: Float = 1
    /// Chevrons, close crosses and other line icons.
    public var iconStrokeWidth: Float = 1.5
    /// Edge of `VectorIcon`s in buttons, labels, rows, tabs and menus.
    public var iconSize: Float = 16
    public var checkmarkWidth: Float = 2
    /// List, tree and menu rows; at least `minimumHitSize`, so a row's disclosure triangle can be.
    public var rowHeight: Float = 24
    public var treeIndent: Float = 16
    /// The smallest pointer target (points) small controls get, whatever their glyph's size:
    /// tab close buttons, disclosure triangles and checkboxes (WCAG 2.2's 24x24 minimum).
    public var minimumHitSize: Float = 24
    public var checkboxSize: Float = 16
    public var switchSize = Vec2(30, 18)
    public var sliderTrackHeight: Float = 4
    public var sliderThumbSize: Float = 14
    public var scrollbarWidth: Float = 6
    public var focusRingWidth: Float = 2
    /// Gap between a widget and the focus ring drawn around it.
    public var focusRingOffset: Float = 1
    /// `ConfirmDialog` card: padding, spacing between its rows and between its buttons, widest width.
    public var dialogPadding: Float = 18
    public var dialogSpacing: Float = 12
    public var buttonSpacing: Float = 8
    public var dialogMaxWidth: Float = 420
    public var progressBarHeight: Float = 10
    /// Insets HUD layers keep from the window edges (TV overscan, notches, rounded corners).
    public var hudSafeArea = EdgeInsets(24)
    /// Seconds a `MenuStack` push or pop animates.
    public var menuTransitionDuration: Double = 0.18
    /// Caret blink period in seconds (visible for the first half); 0 keeps it solid.
    public var caretBlinkPeriod: Double = 1.06
    /// Seconds the pointer rests on a widget before its tooltip shows.
    public var tooltipDelay: Double = 0.5
    /// Seconds after a tooltip went away during which the next one shows without the delay.
    public var tooltipSwitchWindow: Double = 0.4
    public var tooltipFontSize: Float = 12
    /// Widest a tooltip box gets (padding included); longer text wraps.
    public var tooltipMaxWidth: Float = 300
    /// Space between the box edge and its text.
    public var tooltipPadding = Vec2(8, 5)

    /// Per-widget overrides by `Widget.styleClass` or type name (see the type's notes).
    public var styles: [String: UIWidgetStyle] = [:]

    public init(font: Font = UIDrawList.defaultFont) {
        self.font = font
    }

    /// Height of a line of text at `size` (the font's line height).
    public func lineHeight(_ size: Float) -> Float { font.lineHeight * size }

    /// The override for `widget`: its `styleClass` entry, else its type name's, else an empty style.
    public func style(for widget: Widget) -> UIWidgetStyle {
        guard !styles.isEmpty else { return UIWidgetStyle() }
        if let key = widget.styleClass, let style = styles[key] { return style }
        return styles[String(describing: type(of: widget))] ?? UIWidgetStyle()
    }

    // MARK: Presets

    /// The default dark theme with the bundled font (the editor's look).
    public static func dark() -> UITheme { UITheme() }

    /// Dark text on light gray surfaces with the same metrics as `dark()`.
    public static func light() -> UITheme {
        var t = UITheme()
        t.name = "Light"
        t.textColor = UIColor(hex: 0x1d2330)
        t.secondaryTextColor = UIColor(hex: 0x5a6375)
        t.disabledTextColor = UIColor(hex: 0x848b99)
        t.placeholderColor = UIColor(hex: 0x687083)
        t.warningTextColor = UIColor(hex: 0x8a5a00)
        t.errorTextColor = UIColor(hex: 0xb42318)
        t.axisColors = [UIColor(hex: 0xc8323a), UIColor(hex: 0x1f7a44), UIColor(hex: 0x2563eb), UIColor(hex: 0x6b7385)]
        t.panelBackground = UIColor(hex: 0xf3f4f7)
        t.panelBorder = UIColor(hex: 0xd5d9e1)
        t.popupBackground = UIColor(hex: 0xffffff)
        t.popupBorder = UIColor(hex: 0xc6ccd7)
        t.shadow = UIColor(0, 0, 0, 0.18)
        t.modalDim = UIColor(0.1, 0.12, 0.16, 0.35)
        t.controlBackground = UIColor(hex: 0xffffff)
        t.controlHover = UIColor(hex: 0xeef1f6)
        t.controlPressed = UIColor(hex: 0xe1e5ec)
        t.controlBorder = UIColor(hex: 0xc3c9d4)
        t.fieldBackground = UIColor(hex: 0xffffff)
        t.accent = UIColor(hex: 0x2563eb)
        t.accentHover = UIColor(hex: 0x316cec)  // white text 4.7:1 (0x3b74f0 was 4.25)
        t.accentPressed = UIColor(hex: 0x1d4fc4)
        t.trackBackground = UIColor(hex: 0xd3d8e1)
        t.thumb = UIColor(hex: 0xffffff)
        t.focusRing = UIColor(hex: 0x2563eb, alpha: 0.8)
        t.textSelection = UIColor(hex: 0x2563eb, alpha: 0.25)
        t.caret = UIColor(hex: 0x1d2330)
        t.rowHover = UIColor(hex: 0x000000, alpha: 0.05)
        t.rowSelected = UIColor(hex: 0x2563eb, alpha: 0.15)
        t.rowSelectedFocused = UIColor(hex: 0x2563eb, alpha: 0.28)
        t.scrollbarThumb = UIColor(hex: 0x000000, alpha: 0.22)
        t.scrollbarThumbActive = UIColor(hex: 0x000000, alpha: 0.4)
        t.tooltipBackground = UIColor(hex: 0x1d2330)
        t.tooltipBorder = UIColor(hex: 0x1d2330)
        t.tooltipText = UIColor(hex: 0xf3f4f7)
        t.barBackground = UIColor(0, 0, 0, 0.12)
        t.hudTextColor = UIColor(hex: 0x1d2330)
        t.hudTextShadow = UIColor(1, 1, 1, 0.5)
        return t
    }

    /// Black surfaces, white text, yellow accent and focus, thicker borders and focus ring
    /// (for low vision; every state differs in more than color).
    public static func highContrast() -> UITheme {
        var t = UITheme()
        t.name = "High Contrast"
        t.textColor = .white
        t.secondaryTextColor = UIColor(hex: 0xe0e0e0)
        t.disabledTextColor = UIColor(hex: 0x8c8c8c)
        t.placeholderColor = UIColor(hex: 0xb0b0b0)
        t.warningTextColor = UIColor(hex: 0xffd600)
        t.errorTextColor = UIColor(hex: 0xff6b6b)
        t.panelBackground = .black
        t.panelBorder = .white
        t.popupBackground = .black
        t.popupBorder = .white
        t.shadow = .clear
        t.modalDim = UIColor(0, 0, 0, 0.75)
        t.controlBackground = .black
        t.controlHover = UIColor(hex: 0x303030)
        t.controlPressed = UIColor(hex: 0x505050)
        t.controlBorder = .white
        t.fieldBackground = .black
        t.accent = UIColor(hex: 0xffd600)
        t.accentHover = UIColor(hex: 0xffe24d)
        t.accentPressed = UIColor(hex: 0xd9b600)
        t.accentText = .black
        t.trackBackground = UIColor(hex: 0x6b6b6b)
        t.thumb = .white
        t.focusRing = UIColor(hex: 0xffd600)
        t.textSelection = UIColor(hex: 0xffd600, alpha: 0.5)
        t.caret = .white
        t.rowHover = UIColor(hex: 0xffffff, alpha: 0.15)
        t.rowSelected = UIColor(hex: 0xffd600, alpha: 0.35)
        // White text keeps 6:1 on it (at 0.55 it was 4.46).
        t.rowSelectedFocused = UIColor(hex: 0xffd600, alpha: 0.45)
        t.scrollbarThumb = UIColor(hex: 0xffffff, alpha: 0.6)
        t.scrollbarThumbActive = .white
        t.tooltipBackground = .black
        t.tooltipBorder = UIColor(hex: 0xffd600)
        t.tooltipText = .white
        t.barBackground = UIColor(0, 0, 0, 0.85)
        t.healthColor = UIColor(hex: 0x00e676)
        t.warningColor = UIColor(hex: 0xffd600)
        t.dangerColor = UIColor(hex: 0xff3d3d)
        t.hudTextShadow = .black
        t.borderWidth = 2
        t.focusRingWidth = 3
        t.focusRingOffset = 2
        t.iconStrokeWidth = 2
        return t
    }

    /// Big, gamepad-friendly game menus and HUDs: larger type and controls, translucent dark
    /// panels, a warm accent and a thick focus ring.
    public static func game() -> UITheme {
        var t = UITheme()
        t.name = "Game"
        t.fontSize = 18
        t.smallFontSize = 14
        t.headingFontSize = 30
        t.textColor = UIColor(hex: 0xf4f1ea)
        t.secondaryTextColor = UIColor(hex: 0xb9b2a4)
        t.disabledTextColor = UIColor(hex: 0x6f6a60)
        t.placeholderColor = UIColor(hex: 0x8f897c)
        t.panelBackground = UIColor(hex: 0x12141a, alpha: 0.82)
        t.panelBorder = UIColor(hex: 0xffffff, alpha: 0.14)
        t.popupBackground = UIColor(hex: 0x1a1d25, alpha: 0.96)
        t.popupBorder = UIColor(hex: 0xffffff, alpha: 0.2)
        t.modalDim = UIColor(0.02, 0.02, 0.04, 0.6)
        t.controlBackground = UIColor(hex: 0xffffff, alpha: 0.08)
        t.controlHover = UIColor(hex: 0xffffff, alpha: 0.16)
        t.controlPressed = UIColor(hex: 0xffffff, alpha: 0.04)
        t.controlBorder = UIColor(hex: 0xffffff, alpha: 0.18)
        t.fieldBackground = UIColor(hex: 0x000000, alpha: 0.35)
        t.accent = UIColor(hex: 0xf59e2b)
        t.accentHover = UIColor(hex: 0xffb24d)
        t.accentPressed = UIColor(hex: 0xd9831a)
        t.accentText = UIColor(hex: 0x1a1206)
        t.trackBackground = UIColor(hex: 0xffffff, alpha: 0.2)
        t.thumb = UIColor(hex: 0xfff6e8)
        t.focusRing = UIColor(hex: 0xffc266)
        t.rowSelected = UIColor(hex: 0xf59e2b, alpha: 0.35)
        t.rowSelectedFocused = UIColor(hex: 0xf59e2b, alpha: 0.55)
        t.spacing = 10
        t.panelPadding = 22
        t.controlHeight = 44
        t.controlPaddingX = 18
        t.cornerRadius = 8
        t.smallCornerRadius = 6
        t.popupCornerRadius = 10
        t.dialogCornerRadius = 14
        t.checkboxSize = 22
        // List, tree and menu rows fit the 18-pt text.
        t.rowHeight = 30
        t.treeIndent = 20
        t.switchSize = Vec2(44, 26)
        t.sliderTrackHeight = 6
        t.sliderThumbSize = 20
        t.focusRingWidth = 3
        t.focusRingOffset = 2
        t.checkmarkWidth = 3
        t.iconStrokeWidth = 2.5
        t.iconSize = 22
        t.dialogPadding = 26
        t.dialogSpacing = 18
        t.buttonSpacing = 12
        t.dialogMaxWidth = 520
        t.progressBarHeight = 14
        t.hudSafeArea = EdgeInsets(horizontal: 40, vertical: 28)
        t.menuTransitionDuration = 0.22
        return t
    }

    /// The built-in presets, in menu order.
    public static var presets: [UITheme] { [dark(), light(), highContrast(), game()] }

    /// The preset called `name` (case-insensitive), or nil.
    public static func named(_ name: String) -> UITheme? {
        presets.first { $0.name.lowercased() == name.lowercased() }
    }
}

/// Overrides for one kind of widget (see `UITheme.styles`). Nil fields use the theme's values.
public struct UIWidgetStyle: Sendable, Equatable {
    public var background: UIColor?
    public var hoverBackground: UIColor?
    public var pressedBackground: UIColor?
    public var borderColor: UIColor?
    public var borderWidth: Float?
    public var cornerRadius: Float?
    public var textColor: UIColor?
    /// The accent (primary buttons, checked boxes, slider fill, progress fill).
    public var accent: UIColor?
    public var fontSize: Float?
    /// Control height in points.
    public var height: Float?
    /// Horizontal padding inside buttons and selectors.
    public var paddingX: Float?

    public init(background: UIColor? = nil, hoverBackground: UIColor? = nil, pressedBackground: UIColor? = nil,
                borderColor: UIColor? = nil, borderWidth: Float? = nil, cornerRadius: Float? = nil,
                textColor: UIColor? = nil, accent: UIColor? = nil, fontSize: Float? = nil, height: Float? = nil,
                paddingX: Float? = nil) {
        self.background = background
        self.hoverBackground = hoverBackground
        self.pressedBackground = pressedBackground
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.textColor = textColor
        self.accent = accent
        self.fontSize = fontSize
        self.height = height
        self.paddingX = paddingX
    }
}

extension UIColor {
    /// WCAG relative luminance of the (sRGB) color, ignoring alpha.
    public var relativeLuminance: Float {
        func linear(_ c: Float) -> Float { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// This color with its alpha blended over an opaque `background` (in sRGB, as the UI draws).
    public func composited(over background: UIColor) -> UIColor {
        UIColor(background.r + (r - background.r) * a, background.g + (g - background.g) * a,
                background.b + (b - background.b) * a, 1)
    }

    /// The WCAG contrast ratio (1…21) between this color and `other`, both taken as opaque.
    /// AA asks 4.5 for body text, 3 for large text and UI glyphs.
    public func contrastRatio(with other: UIColor) -> Float {
        let (x, y) = (relativeLuminance, other.relativeLuminance)
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
}
