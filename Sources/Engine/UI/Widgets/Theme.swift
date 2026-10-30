import Foundation

/// Colors (sRGB, like every UI color), font, sizes and metrics shared by all widgets. Assign a
/// modified copy to `UIContext.theme` to restyle everything (it relayouts).
@MainActor
public struct UITheme {
    // Text
    public var font: Font
    public var fontSize: Float = 13
    public var smallFontSize: Float = 11
    public var headingFontSize: Float = 17
    public var textColor = UIColor(hex: 0xe6e9ef)
    public var secondaryTextColor = UIColor(hex: 0x98a1b3)
    public var disabledTextColor = UIColor(hex: 0x5c6475)
    public var placeholderColor = UIColor(hex: 0x6b7385)

    // Surfaces
    public var panelBackground = UIColor(hex: 0x1b202b)
    public var panelBorder = UIColor(hex: 0x2f3747)
    public var popupBackground = UIColor(hex: 0x252c3a)
    public var popupBorder = UIColor(hex: 0x3d475c)
    public var shadow = UIColor(0, 0, 0, 0.35)

    // Controls
    public var controlBackground = UIColor(hex: 0x2a3140)
    public var controlHover = UIColor(hex: 0x323a4c)
    public var controlPressed = UIColor(hex: 0x222834)
    public var controlBorder = UIColor(hex: 0x3a4357)
    public var fieldBackground = UIColor(hex: 0x141821)
    public var accent = UIColor(hex: 0x3478f6)
    public var accentHover = UIColor(hex: 0x4a88f8)
    public var accentPressed = UIColor(hex: 0x2a64d4)
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

    // Metrics (points)
    public var spacing: Float = 6
    public var panelPadding: Float = 12
    public var controlHeight: Float = 26
    public var controlPaddingX: Float = 10
    public var cornerRadius: Float = 5
    public var rowHeight: Float = 22
    public var treeIndent: Float = 16
    public var checkboxSize: Float = 16
    public var switchSize = Vec2(30, 18)
    public var sliderTrackHeight: Float = 4
    public var sliderThumbSize: Float = 14
    public var scrollbarWidth: Float = 6
    public var focusRingWidth: Float = 2
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

    public init(font: Font = UIDrawList.defaultFont) {
        self.font = font
    }

    /// The default dark theme with the bundled font.
    public static func dark() -> UITheme { UITheme() }

    /// Height of a line of text at `size` (the font's line height).
    public func lineHeight(_ size: Float) -> Float { font.lineHeight * size }
}
