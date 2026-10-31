import Testing
@testable import Engine

// Directional focus navigation, gamepad input, the menu stack, option selectors, HUD anchoring
// and world-space anchoring.

@MainActor private final class Cell: Widget {
    init(_ name: String) { super.init(name: name) }
    override var acceptsFocus: Bool { true }
    override func measureContent(width: Float?) -> Vec2 { Vec2(40, 20) }
}

@MainActor private final class Rig {
    let input = Input()
    let ui = UIContext()
    let size = Vec2(400, 300)

    init() {
        ui.directionalNavigation = true
        ui.setViewport(size: size, scale: 1)
    }

    func frame(_ body: (Input) -> Void = { _ in }) {
        input.beginFrame()
        body(input)
        input.endEvents()
        ui.update(input: input, dt: 1.0 / 60, viewportSize: size, scale: 1)
    }

    func key(_ key: Key, _ modifiers: KeyModifiers = [], isRepeat: Bool = false) {
        frame { $0.recordKeyPress(key, modifiers: modifiers, isRepeat: isRepeat) }
    }

    func pad(_ buttons: Set<GamepadButton> = [], stick: Vec2 = .zero, dt: Float = 1.0 / 60) {
        input.beginFrame()
        input.updateGamepads([GamepadSnapshot(id: 1, buttons: buttons, leftStick: stick)])
        input.endEvents()
        ui.update(input: input, dt: dt, viewportSize: size, scale: 1)
    }

    /// A 3x3 grid of cells named "r<row>c<col>" at absolute positions.
    func grid() -> [[Cell]] {
        (0..<3).map { r in
            (0..<3).map { c in
                let cell = Cell("r\(r)c\(c)")
                cell.style.position = .absolute(Anchors(left: Float(20 + c * 100), top: Float(20 + r * 60)))
                ui.root.addChild(cell)
                return cell
            }
        }
    }
}

private func rect(_ x: Float, _ y: Float, _ w: Float = 40, _ h: Float = 20) -> UIRect { UIRect(x: x, y: y, width: w, height: h) }

// MARK: Spatial search

@Test @MainActor func nearestPrefersTheSameRowOrColumn() {
    let from = rect(100, 100)
    let candidates = [rect(400, 100), rect(120, 140), rect(40, 100), rect(100, 200)]
    #expect(UINavigation.nearest(from: from, direction: .right, candidates: candidates) == 0)  // same row, though farther
    #expect(UINavigation.nearest(from: from, direction: .left, candidates: candidates) == 2)
    #expect(UINavigation.nearest(from: from, direction: .down, candidates: candidates) == 1)  // overlaps the column
    #expect(UINavigation.nearest(from: from, direction: .up, candidates: candidates) == nil)
    // Without an overlapping candidate the nearest diagonal one is taken.
    #expect(UINavigation.nearest(from: from, direction: .right, candidates: [rect(300, 400), rect(200, 160)]) == 1)
}

@Test @MainActor func navDirectionFromVectorsAndKeys() {
    #expect(UINavDirection(vector: Vec2(0.9, 0.2)) == .right)
    #expect(UINavDirection(vector: Vec2(0.1, 0.8)) == .up)  // stick y is up
    #expect(UINavDirection(vector: Vec2(0, -0.6)) == .down)
    #expect(UINavDirection(vector: Vec2(0.3, 0.3)) == nil)
    #expect(UINavDirection(key: .left) == .left && UINavDirection(key: .a) == nil)
}

@Test @MainActor func arrowKeysMoveFocusThroughAGrid() {
    let rig = Rig()
    let g = rig.grid()
    rig.ui.layoutIfNeeded()
    rig.ui.focus(g[1][1])
    rig.key(.right)
    #expect(rig.ui.focusedWidget === g[1][2] && rig.ui.focusVisible)
    rig.key(.down)
    #expect(rig.ui.focusedWidget === g[2][2])
    rig.key(.down)  // no wrap by default
    #expect(rig.ui.focusedWidget === g[2][2])
    rig.ui.navigationWraps = true
    rig.key(.down)
    #expect(rig.ui.focusedWidget === g[0][2])
    rig.key(.left)
    rig.key(.left)
    #expect(rig.ui.focusedWidget === g[0][0])
    rig.key(.left)  // wraps to the far end of the row
    #expect(rig.ui.focusedWidget === g[0][2])
}

@Test @MainActor func arrowsAreLeftAloneWithoutDirectionalNavigation() {
    let rig = Rig()
    rig.ui.directionalNavigation = false
    let g = rig.grid()
    rig.ui.layoutIfNeeded()
    rig.ui.focus(g[0][0])
    rig.key(.right)
    #expect(rig.ui.focusedWidget === g[0][0])
}

@Test @MainActor func explicitLinksOverrideTheSpatialSearch() {
    let rig = Rig()
    let g = rig.grid()
    rig.ui.layoutIfNeeded()
    g[0][0].setNavigation(.right, to: g[2][2])
    rig.ui.focus(g[0][0])
    rig.key(.right)
    #expect(rig.ui.focusedWidget === g[2][2])
    g[0][0].setNavigation(.right, to: nil)
    #expect(g[0][0].navigationTarget(.right) == nil)
}

@Test @MainActor func navigationStaysInsideItsScope() {
    let rig = Rig()
    let a = Cell("a"), b = Cell("b"), outside = Cell("outside")
    let scope = VStack(spacing: 4, alignment: .start, [a, b])
    scope.isNavigationScope = true
    scope.style.position = .absolute(Anchors(left: 0, top: 0))
    outside.style.position = .absolute(Anchors(left: 0, top: 200))
    rig.ui.root.addChildren([scope, outside])
    rig.ui.layoutIfNeeded()
    rig.ui.focus(b)
    rig.key(.down)
    #expect(rig.ui.focusedWidget === b)
    rig.key(.up)
    #expect(rig.ui.focusedWidget === a)
}

@Test @MainActor func slidersKeepLeftRightButLetUpDownNavigate() {
    let rig = Rig()
    let button = Button("Top")
    let slider = Slider(value: 0.5, step: 0.1)
    rig.ui.root.addChild(VStack(spacing: 4, alignment: .start, [button, slider]))
    rig.ui.layoutIfNeeded()
    rig.ui.focus(slider)
    rig.key(.right)
    #expect(abs(slider.value - 0.6) < 1e-5 && rig.ui.focusedWidget === slider)
    rig.key(.up)
    #expect(rig.ui.focusedWidget === button && abs(slider.value - 0.6) < 1e-5)
}

// MARK: Gamepad

@Test @MainActor func repeaterFiresOnceThenRepeatsAfterTheDelay() {
    var r = UINavigationRepeater(delay: 0.4, interval: 0.1)
    #expect(r.update(direction: .down, dt: 0.016)?.isRepeat == false)
    #expect(r.update(direction: .down, dt: 0.3) == nil)
    let first = r.update(direction: .down, dt: 0.1)
    #expect(first?.count == 1 && first?.isRepeat == true)
    #expect(r.update(direction: .down, dt: 0.25)?.count == 2)
    #expect(r.update(direction: .left, dt: 0.016)?.isRepeat == false)  // a new direction starts over
    #expect(r.update(direction: nil, dt: 0.016) == nil)
    #expect(r.update(direction: .left, dt: 0.016)?.isRepeat == false)
}

@Test @MainActor func gamepadDrivesFocusActivationAndBack() {
    let rig = Rig()
    rig.ui.directionalNavigation = false
    rig.ui.gamepadNavigation = UINavigationInput()
    var pressed: [String] = []
    let first = Button("First") { pressed.append("first") }
    let second = Button("Second") { pressed.append("second") }
    rig.ui.root.addChild(VStack(spacing: 4, alignment: .start, [first, second]))
    rig.ui.layoutIfNeeded()
    rig.ui.focus(first)
    rig.pad([.dpadDown])
    #expect(rig.ui.focusedWidget === second)
    rig.pad([])
    rig.pad([.south])
    #expect(pressed == ["second"])
    rig.pad([])
    rig.pad(stick: Vec2(0, 0.9))  // stick up
    #expect(rig.ui.focusedWidget === first)
    rig.pad([])
    rig.pad([.east])  // B: back clears focus with nothing else to close
    #expect(rig.ui.focusedWidget == nil)
}

@Test @MainActor func shouldersSwitchTabs() {
    let rig = Rig()
    rig.ui.gamepadNavigation = UINavigationInput()
    let content = Button("In tab")
    let tabs = TabView(tabs: [DockPanel(id: "a", title: "A", content: content), DockPanel(id: "b", title: "B", content: Button("B"))])
    rig.ui.root.addChild(tabs)
    rig.ui.layoutIfNeeded()
    rig.ui.focus(content)
    rig.pad([.rightShoulder])
    #expect(tabs.selectedIndex == 1)
    // The focused content left with its tab; focus the bar to keep switching.
    rig.ui.focus(tabs)
    rig.pad([])
    rig.pad([.leftShoulder])
    #expect(tabs.selectedIndex == 0)
}

// MARK: Menus

@Test @MainActor func menuStackPushesPopsAndRestoresFocus() {
    let rig = Rig()
    let resume = Button("Resume"), options = Button("Options")
    let root = MenuScreen(title: "Paused", items: [resume, options])
    let menu = MenuStack()
    menu.transition = .none
    var backAtRoot = 0
    menu.onBackAtRoot = { backAtRoot += 1 }
    rig.ui.root.addChild(menu)
    menu.push(root)
    #expect(rig.ui.focusedWidget === resume && rig.ui.focusVisible)
    rig.key(.down)
    #expect(rig.ui.focusedWidget === options)

    let selector = OptionSelector("Quality", options: ["Low", "Medium", "High"], selectedIndex: 1)
    let options2 = MenuScreen(title: "Options", items: [selector])
    menu.push(options2)
    #expect(menu.top === options2 && root.isHidden && rig.ui.focusedWidget === selector)
    rig.key(.down)  // nothing else in this screen: stays
    #expect(rig.ui.focusedWidget === selector)
    rig.key(.escape)  // back pops and restores the focus the root had
    #expect(menu.top === root && options2.parent == nil && rig.ui.focusedWidget === options)
    rig.key(.escape)
    #expect(backAtRoot == 1 && menu.screens.count == 1)
}

@Test @MainActor func menuTransitionAnimatesThenSettles() {
    let rig = Rig()
    let menu = MenuStack()
    rig.ui.root.addChild(menu)
    let a = MenuScreen(title: "A", items: [Button("x")]), b = MenuScreen(title: "B", items: [Button("y")])
    menu.push(a, animated: false)
    menu.push(b)
    #expect(menu.isAnimating && !a.isHidden)
    let list = UIDrawList()
    for _ in 0..<30 {
        rig.frame()
        list.beginFrame(framebufferSize: (400, 300), scale: 1)
        rig.ui.draw(into: list)
    }
    #expect(!menu.isAnimating && a.isHidden && b.opacity == 1 && b.visualOffset == .zero)
    #expect(menu.hitTest(b.cardFrame.center) != nil)
}

@Test @MainActor func optionSelectorStepsAndWraps() {
    let rig = Rig()
    var changes: [Int] = []
    let selector = OptionSelector("Quality", options: ["Low", "Medium", "High"], selectedIndex: 2) { changes.append($0) }
    rig.ui.root.addChild(VStack(alignment: .start, [selector]))
    rig.ui.layoutIfNeeded()
    rig.ui.focus(selector)
    rig.key(.right)
    #expect(selector.selectedIndex == 0 && selector.selectedOption == "Low")
    rig.key(.left)
    #expect(selector.selectedIndex == 2)
    selector.wraps = false
    rig.key(.right)
    #expect(selector.selectedIndex == 2)
    rig.key(.enter)
    #expect(selector.selectedIndex == 2)
    #expect(changes == [0, 2])
}

@Test @MainActor func confirmDialogButtonsAreReachableByDirection() {
    let rig = Rig()
    var result: Bool?
    let dialog = ConfirmDialog(title: "Quit?", message: "Sure?", confirmTitle: "Quit")
    dialog.onConfirm = { result = true }
    dialog.onCancel = { result = false }
    rig.ui.root.addChild(Button("Behind"))
    dialog.present(in: rig.ui)
    rig.ui.layoutIfNeeded()
    #expect(rig.ui.focusedWidget === dialog.confirmButton)
    rig.key(.left)
    #expect(rig.ui.focusedWidget === dialog.cancelButton)
    rig.key(.up)  // the button behind the modal isn't a candidate
    #expect(rig.ui.focusedWidget === dialog.cancelButton)
    rig.key(.enter)
    #expect(result == false)
}

// MARK: HUD and world space

@Test @MainActor func hudAnchorsRespectTheSafeArea() {
    let rig = Rig()
    let hud = HUDLayer()
    hud.safeArea = EdgeInsets(horizontal: 20, vertical: 10)
    let tl = Cell("tl"), br = Cell("br"), c = Cell("c"), top = Cell("top")
    hud.add(tl, at: .topLeft)
    hud.add(br, at: .bottomRight, offset: Vec2(5, 5))
    hud.add(c, at: .center)
    hud.add(top, at: .top, offset: Vec2(0, 4))
    rig.ui.root.addChild(hud)
    rig.ui.layoutIfNeeded()
    #expect(tl.frame == UIRect(x: 20, y: 10, width: 40, height: 20))
    #expect(br.frame == UIRect(x: 400 - 20 - 5 - 40, y: 300 - 10 - 5 - 20, width: 40, height: 20))
    #expect(c.frame == UIRect(x: 180, y: 140, width: 40, height: 20))
    #expect(top.frame == UIRect(x: 180, y: 14, width: 40, height: 20))
    #expect(hud.hitTest(Vec2(200, 100)) == nil)
}

@Test @MainActor func progressBarClampsAndPicksHealthColors() {
    let theme = UITheme()
    let bar = ProgressBar(value: 2, kind: .health)
    #expect(bar.value == 1 && bar.currentFillColor(theme) == theme.healthColor)
    bar.value = 0.4
    #expect(bar.currentFillColor(theme) == theme.warningColor)
    bar.value = -1
    #expect(bar.value == 0 && bar.currentFillColor(theme) == theme.dangerColor)
}

@MainActor private func testProjection(size: Vec2 = Vec2(400, 300)) -> ViewportProjection {
    ViewportProjection(view: Mat4.lookAt(eye: Vec3(0, 0, 10), target: .zero),
                       projection: Mat4.perspective(fovY: .pi / 2, aspect: size.x / size.y, near: 0.1, far: 100), size: size)
}

@Test @MainActor func worldPointsProjectToTheScreen() {
    let p = testProjection()
    let center = p.screenPoint(of: .zero)
    #expect(center != nil)
    #expect(abs(center!.position.x - 200) < 1e-3 && abs(center!.position.y - 150) < 1e-3)
    #expect(abs(center!.distance - 10) < 1e-4)
    let up = p.screenPoint(of: Vec3(0, 2, 0))!
    #expect(up.position.y < 150)  // world up is screen up
    #expect(p.screenPoint(of: Vec3(0, 0, 20)) == nil)  // behind the camera

    #expect(WorldUIScaling.scale(distance: 20, reference: 10, range: 0.25...2) == 0.5)
    #expect(WorldUIScaling.scale(distance: 1, reference: 10, range: 0.25...2) == 2)
    #expect(WorldUIScaling.fade(distance: 5, range: 10...20) == 1)
    #expect(WorldUIScaling.fade(distance: 15, range: 10...20) == 0.5)
    #expect(WorldUIScaling.fade(distance: 25, range: 10...20) == 0)
}

@Test @MainActor func worldSpaceLayerPlacesScalesAndHidesWidgets() {
    let rig = Rig()
    let layer = WorldSpaceLayer()
    let near = Cell("near"), far = Cell("far"), behind = Cell("behind")
    let nearAnchor = layer.add(near, at: .zero)  // 10 units away: scale 1
    let farAnchor = layer.add(far, at: Vec3(0, 0, -10))  // 20 away: scale 0.5
    farAnchor.fadeDistance = 15...25
    let behindAnchor = layer.add(behind, at: Vec3(0, 0, 30))
    rig.ui.root.addChild(layer)
    rig.ui.layoutIfNeeded()
    layer.update(projection: testProjection(), dt: 1 / 60)

    // Bottom center (the default pivot) on the projected point.
    #expect(nearAnchor.scale == 1)
    #expect(near.frame.x + near.visualOffset.x == 180 && near.frame.y + near.visualOffset.y == 130)
    #expect(farAnchor.scale == 0.5 && far.visualScale == 0.5)
    #expect(abs(far.opacity - 0.5) < 1e-4)
    #expect(behindAnchor.screenPoint == nil && behind.opacity == 0)
    // Painted far to near.
    let order = layer.children.map(\.name)
    #expect(order.firstIndex(of: "far")! < order.firstIndex(of: "near")!)

    // Occlusion fades over time.
    nearAnchor.isOccluded = true
    nearAnchor.occlusionFadeSpeed = 2
    layer.update(projection: testProjection(), dt: 0.25)
    #expect(abs(near.opacity - 0.5) < 1e-4)
    layer.update(projection: testProjection(), dt: 1)
    #expect(abs(near.opacity - nearAnchor.occludedOpacity) < 1e-4)
}

@Test @MainActor func rayHitsMapToPanelUV() {
    // A plane stood up facing +Z, 4 wide and 2 tall, centered at (0, 1, 0).
    let m = Mat4(translation: Vec3(0, 1, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(4, 1, 2))
    let center = WorldUIPanel.hit(ray: Ray(origin: Vec3(0, 1, 5), direction: Vec3(0, 0, -1)), planeTransform: m)
    #expect(center != nil && abs(center!.x - 0.5) < 1e-4 && abs(center!.y - 0.5) < 1e-4)
    let topLeft = WorldUIPanel.hit(ray: Ray(origin: Vec3(-1.5, 1.75, 5), direction: Vec3(0, 0, -1)), planeTransform: m)!
    #expect(abs(topLeft.x - 0.125) < 1e-4 && abs(topLeft.y - 0.125) < 1e-4)
    #expect(WorldUIPanel.hit(ray: Ray(origin: Vec3(3, 1, 5), direction: Vec3(0, 0, -1)), planeTransform: m) == nil)  // beside
    #expect(WorldUIPanel.hit(ray: Ray(origin: Vec3(0, 1, -5), direction: Vec3(0, 0, 1)), planeTransform: m) == nil)  // back
}

@Test @MainActor func pointerMappingRoutesAPanelsPointer() {
    let rig = Rig()
    let button = Button("Panel")
    button.style.position = .absolute(Anchors(left: 0, top: 0))
    rig.ui.root.addChild(button)
    rig.ui.pointerMapping = { _ in Vec2(5, 5) }
    rig.frame { $0.mousePosition = Vec2(390, 290) }
    #expect(rig.ui.hoveredWidget === button)
    rig.ui.pointerMapping = { _ in nil }
    rig.frame { $0.mousePosition = Vec2(5, 5) }
    #expect(rig.ui.hoveredWidget == nil)
}
