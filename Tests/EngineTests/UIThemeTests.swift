import Testing
@testable import Engine

// Theme presets, per-widget overrides, runtime switching, and HiDPI / UI scale handling.

@MainActor private final class Box: Widget {
    var size: Vec2
    var focusable = true
    init(_ size: Vec2, name: String = "") {
        self.size = size
        super.init(name: name)
    }
    override var acceptsFocus: Bool { focusable }
    override func measureContent(width: Float?) -> Vec2 { size }
}

// MARK: Presets

@MainActor @Test func darkThemeKeepsTheOriginalValues() {
    let t = UITheme.dark()
    #expect(t.name == "Dark")
    #expect(t.fontSize == 13 && t.smallFontSize == 11 && t.headingFontSize == 17)
    #expect(t.textColor == UIColor(hex: 0xe6e9ef) && t.panelBackground == UIColor(hex: 0x1b202b))
    #expect(t.accent == UIColor(hex: 0x3478f6) && t.focusRing == UIColor(hex: 0x6aa1ff, alpha: 0.9))
    #expect(t.controlHeight == 26 && t.controlPaddingX == 10 && t.spacing == 6 && t.panelPadding == 12)
    // The constants the widgets used to hard-code, now theme metrics.
    #expect(t.cornerRadius == 5)
    #expect(t.smallCornerRadius == 4 && t.rowCornerRadius == 3)
    #expect(t.popupCornerRadius == t.cornerRadius + 1)
    #expect(t.dialogCornerRadius == t.cornerRadius + 3 && t.dialogCornerRadius + 6 == t.cornerRadius + 9)
    #expect(t.borderWidth == 1 && t.iconStrokeWidth == 1.5 && t.checkmarkWidth == 2)
    #expect(t.focusRingWidth == 2 && t.focusRingOffset == 1)
    #expect(t.modalDim == UIColor(0, 0, 0, 0.5))
    #expect(t.dialogPadding == 18 && t.dialogSpacing == 12 && t.buttonSpacing == 8 && t.dialogMaxWidth == 420)
    #expect(t.styles.isEmpty)
}

@MainActor @Test func presetsAreDistinctAndFoundByName() {
    let names = UITheme.presets.map(\.name)
    #expect(names == ["Dark", "Light", "High Contrast", "Game"])
    #expect(UITheme.named("game")?.controlHeight == UITheme.game().controlHeight)
    #expect(UITheme.named("nope") == nil)
    #expect(UITheme.light().panelBackground != UITheme.dark().panelBackground)
    #expect(UITheme.light().textColor != UITheme.dark().textColor)
    #expect(UITheme.highContrast().borderWidth > 1 && UITheme.highContrast().focusRingWidth > UITheme.dark().focusRingWidth)
    #expect(UITheme.game().fontSize > UITheme.dark().fontSize && UITheme.game().controlHeight > UITheme.dark().controlHeight)
}

@MainActor @Test func styleOverridesMatchClassThenTypeName() {
    var theme = UITheme()
    theme.styles["Button"] = UIWidgetStyle(height: 40)
    theme.styles["big"] = UIWidgetStyle(fontSize: 30, height: 60)
    let plain = Button("A"), classed = Button("B"), label = Label("C")
    classed.styleClass = "big"
    #expect(theme.style(for: plain).height == 40)
    #expect(theme.style(for: classed).height == 60 && theme.style(for: classed).fontSize == 30)
    #expect(theme.style(for: label) == UIWidgetStyle())

    let ui = UIContext(theme: theme)
    ui.root.addChildren([VStack(spacing: 0, alignment: .start, [plain, classed])])
    ui.setViewport(size: Vec2(400, 300), scale: 1)
    ui.layoutIfNeeded()
    #expect(plain.frame.height == 40 && classed.frame.height == 60)
}

@MainActor @Test func switchingThemesRelayouts() {
    let ui = UIContext()
    let button = Button("Resume")
    ui.root.addChild(VStack(alignment: .start, [button]))
    ui.setViewport(size: Vec2(400, 300), scale: 1)
    ui.layoutIfNeeded()
    #expect(button.frame.height == 26)
    let passes = ui.stats.layoutPasses
    ui.theme = .game()
    ui.layoutIfNeeded()
    #expect(ui.stats.layoutPasses == passes + 1)
    #expect(button.frame.height == UITheme.game().controlHeight)
    ui.theme = .dark()
    ui.layoutIfNeeded()
    #expect(button.frame.height == 26)
}

// MARK: HiDPI

@MainActor @Test func snappingLandsOnThePixelGridAtFractionalScales() {
    for scale: Float in [1, 1.25, 1.5, 2] {
        for value: Float in [0, 0.3, 7.1, 13.37, 101.6] {
            let snapped = UILayout.snap(value, scale: scale)
            let pixels = snapped * scale
            #expect(abs(pixels - pixels.rounded()) < 1e-3, "scale \(scale) value \(value)")
            #expect(abs(snapped - value) <= 0.5 / scale + 1e-4)
        }
    }
}

@MainActor @Test func layoutFramesArePixelAlignedAtEveryScale() {
    for scale: Float in [1, 1.25, 1.5, 2] {
        let ui = UIContext()
        let boxes = (0..<5).map { Box(Vec2(33.3, 17.7), name: "b\($0)") }
        ui.root.addChild(VStack(spacing: 3.3, alignment: .start, padding: EdgeInsets(5.1), boxes))
        ui.setViewport(size: Vec2(300.7, 200.3), scale: scale)
        ui.layoutIfNeeded()
        for box in boxes {
            for edge in [box.frame.x, box.frame.y, box.frame.maxX, box.frame.maxY] {
                let px = edge * scale
                #expect(abs(px - px.rounded()) < 1e-3, "scale \(scale): edge \(edge)")
            }
        }
        // Adjacent boxes neither overlap nor leave a gap beyond the spacing (snapped).
        for (a, b) in zip(boxes, boxes.dropFirst()) { #expect(b.frame.y >= a.frame.maxY) }
    }
}

@MainActor @Test func strokesAreWholePixelsAtFractionalScales() {
    #expect(UIDrawList.strokePixels(1, scale: 1) == 1)
    #expect(UIDrawList.strokePixels(1, scale: 2) == 2)
    #expect(UIDrawList.strokePixels(1.5, scale: 2) == 3)
    #expect(UIDrawList.strokePixels(1.5, scale: 1) == 1.5)  // integral scales draw as given
    #expect(UIDrawList.strokePixels(1, scale: 1.25) == 1)
    #expect(UIDrawList.strokePixels(1, scale: 1.5) == 2)
    #expect(UIDrawList.strokePixels(0.2, scale: 1.25) == 1)  // never thinner than a pixel

    let list = UIDrawList()
    list.beginFrame(framebufferSize: (500, 500), scale: 1.25)
    list.strokeRect(UIRect(x: 8, y: 8, width: 40, height: 20), color: .white, width: 1)
    #expect(list.vertices[0].params.x == 1)
    #expect(list.vertices[0].halfSize == Vec2(25, 12.5))
}

@MainActor @Test func textRasterizesAtTheTransformedPixelSize() {
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (800, 600), scale: 1.5)
    let layout = TextLayout("H", font: UIDrawList.defaultFont, size: 20)
    list.drawText(layout, font: UIDrawList.defaultFont, at: Vec2(10, 10), color: .white)
    let plain = list.vertices
    list.beginFrame(framebufferSize: (800, 600), scale: 1.5)
    list.withTransform(scale: 2) {
        list.drawText(layout, font: UIDrawList.defaultFont, at: Vec2(5, 5), color: .white)
    }
    let zoomed = list.vertices
    #expect(plain.count == 4 && zoomed.count == 4)
    // Same origin in pixels (10 * 1.5 vs 5 * 2 * 1.5), twice the glyph size, sharper SDF smoothing.
    let w0 = plain[1].position.x - plain[0].position.x, w1 = zoomed[1].position.x - zoomed[0].position.x
    #expect(abs(w1 - 2 * w0) < 1e-3)
    #expect(zoomed[0].params.z < plain[0].params.z)
}

@MainActor @Test func transformsAndOpacityAreExactWhenIdentity() {
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (400, 300), scale: 2)
    list.fillRect(UIRect(x: 10.25, y: 3, width: 20, height: 9), color: UIColor(0.2, 0.4, 0.6, 0.8))
    let plain = list.vertices.map(\.position)
    list.beginFrame(framebufferSize: (400, 300), scale: 2)
    list.withTransform(scale: 1, offset: .zero) {
        list.withOpacity(1) {
            list.fillRect(UIRect(x: 10.25, y: 3, width: 20, height: 9), color: UIColor(0.2, 0.4, 0.6, 0.8))
        }
    }
    #expect(list.vertices.map(\.position) == plain)
    #expect(list.vertices[0].color.w == 0.8)

    list.beginFrame(framebufferSize: (400, 300), scale: 2)
    list.withTransform(scale: 2, offset: Vec2(5, 0)) {
        list.withOpacity(0.5) { list.fillRect(UIRect(x: 0, y: 0, width: 10, height: 10), color: .white) }
        #expect(list.clipBounds == UIRect(x: -2.5, y: 0, width: 100, height: 75))
    }
    // (0,0) -> (5,0) points -> (10,0) pixels; 10 points wide -> 40 pixels.
    #expect(list.vertices[0].position == Vec2(10, 0) - Vec2(repeating: UIDrawList.antialiasMargin))
    #expect(list.vertices[0].halfSize == Vec2(20, 20))
    #expect(list.vertices[0].color.w == 0.5)
}

@MainActor @Test func uiScaleZoomsLayoutPointerAndDrawing() {
    for backing: Float in [1, 2] {
        let input = Input()
        let ui = UIContext()
        ui.uiScale = 1.5
        let box = Box(Vec2(40, 20))
        box.style.position = .absolute(Anchors(left: 10, top: 10))
        ui.root.addChild(box)
        input.beginFrame()
        input.mousePosition = Vec2(30, 30)  // window points: 20, 20 in zoomed points, inside the box
        input.endEvents()
        ui.update(input: input, dt: 1 / 60, viewportSize: Vec2(600, 300), scale: backing)
        #expect(ui.viewport.width == 400 && ui.viewport.height == 200)
        #expect(ui.scale == backing * 1.5)
        #expect(ui.pointerPosition == Vec2(20, 20))
        #expect(ui.hoveredWidget === box)

        // The draw list maps the zoomed points back to window pixels.
        let list = UIDrawList()
        list.beginFrame(framebufferSize: (Int(600 * backing), Int(300 * backing)), scale: backing)
        list.withTransform(scale: ui.uiScale) { list.fillRect(box.frame, color: .white) }
        let m = UIDrawList.antialiasMargin
        #expect(list.vertices[0].position == Vec2(10 * 1.5 * backing - m, 10 * 1.5 * backing - m))
    }
}

@MainActor @Test func zoomOfOneChangesNothing() {
    let input = Input()
    let ui = UIContext()
    ui.uiScale = 1
    input.beginFrame()
    input.mousePosition = Vec2(33.3, 44.4)
    input.endEvents()
    ui.update(input: input, dt: 1 / 60, viewportSize: Vec2(640.5, 480), scale: 1.25)
    #expect(ui.viewport.width == 640.5 && ui.scale == 1.25 && ui.pointerPosition == Vec2(33.3, 44.4))
}
