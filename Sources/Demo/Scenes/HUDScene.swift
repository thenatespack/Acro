import Engine
import Foundation

/// The options the menu persists (see `SettingsStore`): missing keys keep these defaults.
struct HUDSettings: Settings {
    var theme = "Game"
    var uiScale: Float = 1
    var quality = 2
    var volume: Float = 0.7
    var invertLook = false
    var subtitles = true
}

/// A game HUD and menus over a 3D scene, in the "game" theme: health / stamina bars with a
/// damage trail, an ammo counter, a minimap panel and objective text pinned to the corners of
/// the safe area; floating name tags and health bars over the units (world-space widgets that
/// shrink with distance, fade out far away and dim behind the terminal); and an in-world
/// terminal whose UI is drawn into a render target shown on a quad, with the mouse mapped onto
/// it through a ray hit (click its buttons).
///
/// M or Start opens the pause menu (a `MenuStack`): arrows / D-pad / left stick move focus
/// (spatially, wrapping), Enter / A activates, Esc / B goes back, Left / Right change sliders and
/// option selectors. Options switch the theme (dark, light, high contrast, game) and the UI
/// scale at runtime; "Reset" and "Quit" ask with a `ConfirmDialog`. The scene takes the
/// keyboard only while the menu or a dialog is open, so the demo's own keys (scene switching,
/// Esc to quit) work while playing. Screenshot runs (or
/// `HUD_MENU=1`; `HUD_MENU=0` turns it off) start with the menu open on its options screen, so it is covered.
/// The options (theme, UI scale, quality, volume, toggles) are kept in `settings.json` in the
/// user data folder and restored at start. Screenshot runs use the defaults and write nothing,
/// unless `ENGINE_USER_DATA_DIR` points at a scratch folder.
final class HUDScene: DemoScene {
    static let name = "hud"
    static let summary = "game HUD and menus: themes, gamepad/keyboard navigation, menu stack, world-space labels, UI on a 3D screen"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private let screenEntity: Entity
    private var units: [Unit] = []
    private var time: Float = 0
    private var lastDt: Float = 0
    private weak var engine: Engine?
    private static let fogColor = Vec3(0.5, 0.58, 0.7)

    let ui: UIContext
    private let worldLayer = WorldSpaceLayer()
    private let hud = HUDLayer()
    private let pauseOverlay = Backdrop()
    private let menu = MenuStack()
    private let healthBar = ProgressBar(value: 0.72, kind: .health, name: "health")
    private let healthText = IconLabel("72", name: "healthText")
    private let staminaBar = ProgressBar(value: 0.45, name: "stamina")
    private let ammo = IconLabel("24 / 120", name: "ammo")
    private let objective = IconLabel("Reach the terminal  (2 / 3)", name: "objective")
    private var minimap: Minimap!
    private let panel: WorldUIPanel
    private let panelStatus = Label("Door locked", role: .secondary, name: "panelStatus")
    private let actions: InputActions
    private var closedMenuThisFrame = false
    private var settings = HUDSettings()
    private let settingsStore: SettingsStore<HUDSettings>?

    private struct Unit {
        var entity: Entity
        var name: String
        var base: Vec3
        var phase: Float
        var health: Float
        var anchor: WorldAnchor
        var bar: ProgressBar
    }

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        var theme = UITheme.game()
        let screenshotRun = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil
        // Screenshot runs stay deterministic: never the real user's settings.
        settingsStore = screenshotRun && !UserData.isOverridden ? nil : SettingsStore(app: "SwiftGameEngineDemo")
        let saved = settingsStore?.load() ?? HUDSettings()
        if let preset = UITheme.presets.first(where: { $0.name == saved.theme }) { theme = preset }
        if screenshotRun { theme.caretBlinkPeriod = 0 }
        settings = saved
        ui = UIContext(theme: theme)
        ui.uiScale = [1, 1.25, 1.5].contains(saved.uiScale) ? saved.uiScale : 1
        ui.directionalNavigation = true
        ui.navigationWraps = true
        ui.gamepadNavigation = UINavigationInput()
        panel = try WorldUIPanel(device: renderer.device, size: Vec2(360, 240), pixelsPerPoint: 2,
                                 theme: theme.name == "Game" ? .dark() : theme, label: "terminal")
        panel.clearColor = Vec4(0.012, 0.016, 0.026, 1)

        var bindings = InputBindings()
        bindings.buttons.append(.init("pause", [.key(.m), .gamepadButton(.start)]))
        actions = InputActions(bindings: bindings)

        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.5, 0.52, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), specular: 0.35, shininess: 40), key: "paint")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.16, 0.17, 0.2, 1), specular: 0.5), key: "metal")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), texture: panel.texture, emissive: 1), key: "screen")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 9, 22), at: Vec3(0, 2, 0)),
            Camera(fovY: .pi / 3.4, near: 0.3, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.008))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.45))),
            DirectionalLight(intensity: 1.3, shadowExtent: 24))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(60, 1, 60)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))

        // The terminal: a frame and the screen quad (a plane stood up to face +Z, slightly turned).
        let screenRotation = Quat(angle: -0.6, axis: Vec3(0, 1, 0)) * Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))
        let screenPosition = Vec3(10.5, 3.2, -2)
        _ = world.spawn(
            Transform(position: screenPosition - Quat(angle: -0.6, axis: Vec3(0, 1, 0)) * Vec3(0, 0, 0.12),
                      rotation: Quat(angle: -0.6, axis: Vec3(0, 1, 0)), scale: Vec3(6.4, 4.4, 0.2)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("metal")))
        _ = world.spawn(
            Transform(position: Vec3(screenPosition.x, 0.5, screenPosition.z - 0.3), scale: Vec3(0.5, 1.4, 0.5)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("metal")))
        screenEntity = world.spawn(
            Transform(position: screenPosition, rotation: screenRotation, scale: Vec3(6, 1, 4)),
            MeshRenderer(mesh: .plane, material: MaterialHandle("screen"), castsShadows: false))
        for (i, x) in [Float(-9), -4, 9, 12].enumerated() {
            _ = world.spawn(
                Transform(position: Vec3(x, 1, -8 + Float(i % 2) * 3), scale: Vec3(2, 2, 2)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: Vec3(0.55, 0.5, 0.42)))
        }
        world.propagateTransforms()

        minimap = Minimap { [unowned self] in
            units.map { (Vec2($0.base.x, $0.base.z) + Self.wander($0, time: time), $0.health) }
        }
        buildUnits()
        buildHUD()
        buildMenu()
        buildPanel()

        let env = ProcessInfo.processInfo.environment
        if env["HUD_MENU"] != "0" && (env["ENGINE_SCREENSHOT"] != nil || env["HUD_MENU"] == "1") {
            openMenu(animated: false)
            menu.push(optionsScreen(), animated: false)
        }
    }

    var uiContext: UIContext? { ui }
    /// While the menu or a dialog is open, and on the frame the menu closed (so the Esc that
    /// closed it doesn't also quit the demo).
    var wantsKeyboard: Bool { isPaused || !ui.overlays.isEmpty || closedMenuThisFrame }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var initialView: OrbitView { OrbitView(yaw: 0.25, pitch: 0.42, distance: 24, target: Vec3(1, 2, 0)) }
    var status: String { pauseOverlay.isHidden ? "playing" : "paused: \(menu.top?.name ?? "")" }

    // MARK: Building

    private func buildUnits() {
        let specs: [(String, Vec3, Float, Vec3)] = [
            ("Scout", Vec3(-6, 0, 2), 0.86, Vec3(0.3, 0.7, 0.95)),
            ("Medic", Vec3(-1, 0, 6), 0.45, Vec3(0.95, 0.95, 0.95)),
            ("Heavy", Vec3(3, 0, 2.5), 0.18, Vec3(0.9, 0.45, 0.25)),
            ("Drone", Vec3(13, 0, -5.5), 1, Vec3(0.55, 0.9, 0.45)),
        ]
        for (i, (name, base, health, tint)) in specs.enumerated() {
            let entity = world.spawn(Transform(position: base))
            let body = world.spawn(
                Transform(position: Vec3(0, 0.8, 0), scale: Vec3(0.9, 1.6, 0.9)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: tint))
            world.setParent(body, to: entity)
            let head = world.spawn(
                Transform(position: Vec3(0, 1.95, 0), scale: Vec3(repeating: 0.7)),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("paint"), tint: Vec3(0.95, 0.85, 0.75)))
            world.setParent(head, to: entity)

            let bar = ProgressBar(value: health, kind: .health, name: "\(name).health")
            bar.style.width = 96
            bar.style.height = 9
            let label = IconLabel(name, fontSize: 15, name: "\(name).tag")
            let tag = VStack(spacing: 4, alignment: .center, name: "\(name).nameplate", [label, bar])
            let anchor = worldLayer.add(tag, at: base + Vec3(0, 2.7, 0))
            anchor.referenceDistance = 18
            anchor.scaleRange = 0.55...1.2
            anchor.fadeDistance = 34...48
            units.append(Unit(entity: entity, name: name, base: base, phase: Float(i) * 1.7, health: health, anchor: anchor, bar: bar))
        }
    }

    private func buildHUD() {
        healthBar.showsTrail = true
        healthBar.style.width = 260
        healthBar.segments = 4
        staminaBar.style.width = 200
        staminaBar.fillColor = UIColor(hex: 0x4fb8e8)
        healthText.icon = .custom(Self.drawHeart)
        healthText.fontSize = 22
        let vitals = VStack(spacing: 8, alignment: .start, name: "vitals", [
            HStack(spacing: 10, [healthText, healthBar]),
            HStack(spacing: 10, [IconLabel("", icon: .custom(Self.drawBolt), fontSize: 22), staminaBar]),
        ])
        hud.add(vitals, at: .topLeft)

        objective.icon = .custom(Self.drawDiamond)
        objective.fontSize = 20
        hud.add(objective, at: .top)

        hud.add(minimap, at: .topRight)

        ammo.icon = .custom(Self.drawBullet)
        ammo.fontSize = 34
        hud.add(ammo, at: .bottomRight)

        let hint = IconLabel("M / Start  pause", fontSize: 15, name: "hint")
        hint.color = UIColor(1, 1, 1, 0.7)
        hud.add(hint, at: .bottomLeft)
        hud.add(Crosshair(), at: .center)

        ui.root.addChildren([worldLayer, hud, pauseOverlay])
    }

    private func buildMenu() {
        pauseOverlay.isHidden = true
        pauseOverlay.addChild(menu)
        menu.onBackAtRoot = { [unowned self] in closeMenu() }
    }

    private func pauseScreen() -> MenuScreen {
        let screen = MenuScreen(title: "Paused", width: 420, name: "pause")
        screen.addItem(Button("Resume", role: .primary, name: "resume") { [unowned self] in closeMenu() })
        screen.addItem(Button("Options", name: "options") { [unowned self] in menu.push(optionsScreen()) })
        screen.addItem(Button("Restart checkpoint", name: "restart") { [unowned self] in
            confirm("Restart from the checkpoint?", "Unsaved progress since the last checkpoint is lost.", "Restart") { [unowned self] in
                for i in units.indices { units[i].health = 1; units[i].bar.value = 1 }
                healthBar.value = 1
                healthText.text = "100"
                closeMenu()
            }
        })
        screen.addItem(Button("Quit demo", name: "quit") { [unowned self] in
            confirm("Quit the demo?", "The window closes.", "Quit") { [weak self] in self?.engine?.quit() }
        })
        return screen
    }

    private func optionsScreen() -> MenuScreen {
        let screen = MenuScreen(title: "Options", width: 520, name: "optionsScreen")
        let themes = UITheme.presets.map(\.name)
        let theme = OptionSelector("Theme", options: themes, selectedIndex: themes.firstIndex(of: ui.theme.name) ?? 0,
                                   name: "theme") { [unowned self] index in
            applyTheme(UITheme.presets[index])
            settings.theme = UITheme.presets[index].name
            persistSettings()
        }
        let scales: [Float] = [1, 1.25, 1.5]
        let scale = OptionSelector("UI scale", options: scales.map { "\(Int($0 * 100))%" },
                                   selectedIndex: scales.firstIndex(of: ui.uiScale) ?? 0, name: "uiScale") { [unowned self] in
            ui.uiScale = scales[$0]
            settings.uiScale = scales[$0]
            persistSettings()
        }
        let quality = OptionSelector("Quality", options: ["Low", "Medium", "High", "Ultra"], selectedIndex: settings.quality,
                                     name: "quality") { [unowned self] in
            settings.quality = $0
            persistSettings()
        }
        let volumeTitle = Label("Volume", name: "volumeTitle")
        volumeTitle.style.width = 140
        let volume = Slider(value: settings.volume, name: "volume") { [unowned self] in
            settings.volume = $0
            persistSettings()
        }
        volume.style.grow = 1
        let invert = Checkbox("Invert look", isOn: settings.invertLook, kind: .toggleSwitch, name: "invert") { [unowned self] in
            settings.invertLook = $0
            persistSettings()
        }
        let subtitles = Checkbox("Subtitles", isOn: settings.subtitles, kind: .toggleSwitch, name: "subtitles") { [unowned self] in
            settings.subtitles = $0
            persistSettings()
        }
        let reset = Button("Reset to defaults", name: "reset") { [unowned self] in
            confirm("Reset all options?", "Theme, scale and audio go back to their defaults.", "Reset") { [unowned self] in
                ui.uiScale = 1
                applyTheme(.game())
                settings = HUDSettings()
                persistSettings()
                menu.pop(animated: false)
                menu.push(optionsScreen(), animated: false)
            }
        }
        let back = Button("Back", name: "back") { [unowned self] in menu.pop() }
        for item in [theme, scale, quality, HStack(spacing: 12, [volumeTitle, volume]), invert, subtitles,
                     HStack(spacing: 12, [reset, Spacer(), back])] as [Widget] {
            screen.addItem(item)
        }
        return screen
    }

    private func buildPanel() {
        let title = Label("Terminal 7", role: .heading)
        let door = ProgressBar(value: 0.35, name: "doorPower")
        door.text = "Power 35%"
        door.style.height = 16
        let open = Button("Open door", role: .primary, name: "openDoor") { [unowned self] in
            door.value = min(door.value + 0.25, 1)
            door.text = "Power \(Int((door.value * 100).rounded()))%"
            panelStatus.text = door.value >= 1 ? "Door open" : "Charging…"
        }
        let alarm = Checkbox("Alarm", isOn: true, kind: .toggleSwitch, name: "alarm")
        let column = VStack(spacing: 10, padding: EdgeInsets(16), name: "terminal", [
            title, Label("Click the screen to use it.", role: .caption), door, HStack(spacing: 8, [open, alarm]),
            Spacer(), panelStatus,
        ])
        panel.ui.root.addChild(column)
    }

    // MARK: Menu

    private func openMenu(animated: Bool = true) {
        guard pauseOverlay.isHidden else { return }
        pauseOverlay.isHidden = false
        if menu.screens.isEmpty {
            menu.push(pauseScreen(), animated: false)
        } else {
            menu.popToRoot(animated: false)
            menu.focusTop()
        }
    }

    private func closeMenu() {
        guard !pauseOverlay.isHidden else { return }
        menu.popToRoot(animated: false)
        pauseOverlay.isHidden = true
        ui.focus(nil)
        closedMenuThisFrame = true
    }

    private func confirm(_ title: String, _ message: String, _ action: String, onConfirm: @escaping () -> Void) {
        let dialog = ConfirmDialog(title: title, message: message, confirmTitle: action)
        dialog.isNavigationScope = true
        dialog.onConfirm = onConfirm
        let previous = ui.focusedWidget
        dialog.onCancel = { [unowned self] in if let previous { ui.focus(previous, visible: true) } }
        dialog.present(in: ui)
        ui.focus(dialog.confirmButton, visible: true)
    }

    /// Writes the options; a failure (read-only disk) only costs the persistence.
    private func persistSettings() {
        guard let settingsStore else { return }
        settingsStore.values = settings
        do { try settingsStore.save() } catch { print("HUD: couldn't save settings: \(error)") }
    }

    private func applyTheme(_ theme: UITheme) {
        var theme = theme
        theme.caretBlinkPeriod = ui.theme.caretBlinkPeriod
        ui.theme = theme
        panel.ui.theme = theme.name == "Game" ? .dark() : theme
    }

    // MARK: Frame

    private var isPaused: Bool { !pauseOverlay.isHidden }

    func update(engine: Engine, dt: Float, time t: Float) {
        self.engine = engine
        lastDt = dt
        actions.update(engine.input)
        if actions.wasPressed("pause") && !closedMenuThisFrame && !isPaused && ui.overlays.isEmpty { openMenu() }
        closedMenuThisFrame = false

        // The terminal takes the mouse where the pointer ray hits its quad (not while paused).
        var pointer: Vec2?
        if !isPaused, let projection = projection(size: engine.ui.size) {
            let ray = projection.ray(through: engine.input.mousePosition)
            pointer = WorldUIPanel.hit(ray: ray, planeTransform: world.worldMatrix(of: screenEntity)).map { $0 * panel.size }
        }
        panel.update(input: engine.input, dt: dt, pointer: pointer)

        guard !isPaused else { return }
        time = t
        // Units wander; the player's health dips and recovers for the damage trail.
        for unit in units {
            let p = unit.base + Vec3(Self.wander(unit, time: t).x, 0, Self.wander(unit, time: t).y)
            world.add(Transform(position: p, rotation: Quat(angle: sinf(t * 0.6 + unit.phase), axis: Vec3(0, 1, 0))), to: unit.entity)
            unit.anchor.position = p + Vec3(0, 2.7, 0)
        }
        let health = 0.6 + 0.25 * sinf(t * 0.7)
        healthBar.value = health
        healthText.text = "\(Int((health * 100).rounded()))"
        staminaBar.value = 0.5 + 0.4 * sinf(t * 1.3)
        world.update(dt: Double(dt))
    }

    private static func wander(_ unit: Unit, time t: Float) -> Vec2 {
        Vec2(sinf(t * 0.5 + unit.phase) * 1.5, cosf(t * 0.4 + unit.phase * 1.3) * 1.2)
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        world.add(Transform.looking(from: orbitEye, at: target), to: cameraEntity)
        world.propagateTransforms()
        return ViewCamera(eye: orbitEye, target: target)
    }

    /// The main camera in window points (for world labels and the pointer ray).
    private func projection(size: Vec2) -> ViewportProjection? {
        guard size.x > 0, size.y > 0, let view = SceneView(camera: cameraEntity, in: world, aspect: size.x / size.y) else { return nil }
        return ViewportProjection(view, size: size)
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        panel.render(frame: frame)
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }

    func drawUI(_ list: UIDrawList) {
        if let projection = projection(size: ui.viewport.width > 0 ? Vec2(ui.viewport.width, ui.viewport.height) : list.size) {
            // Labels behind the terminal (seen through its screen) dim.
            let screen = world.worldMatrix(of: screenEntity)
            for unit in units {
                let toEye = projection.eye - unit.anchor.position
                unit.anchor.isOccluded = WorldUIPanel.hit(ray: Ray(origin: projection.eye, direction: -toEye), planeTransform: screen) != nil
                    && dot(toEye, toEye) > Self.distanceSquared(projection.eye, screen)
            }
            worldLayer.update(projection: projection, dt: lastDt)
        }
        ui.draw(into: list)
    }

    private static func distanceSquared(_ eye: Vec3, _ m: Mat4) -> Float {
        let d = Vec3(m.c3.x, m.c3.y, m.c3.z) - eye
        return dot(d, d)
    }

    // MARK: Icons

    private static func drawHeart(_ list: UIDrawList, _ r: UIRect, _ color: UIColor) {
        let s = r.width
        let lobe = s * 0.3
        list.fillRect(UIRect(x: r.x + s * 0.14, y: r.y + s * 0.18, width: lobe * 1.15, height: lobe * 1.15),
                      color: color, radii: UICornerRadii(lobe))
        list.fillRect(UIRect(x: r.x + s * 0.48, y: r.y + s * 0.18, width: lobe * 1.15, height: lobe * 1.15),
                      color: color, radii: UICornerRadii(lobe))
        list.drawLine(from: Vec2(r.x + s * 0.27, r.y + s * 0.47), to: Vec2(r.x + s * 0.5, r.y + s * 0.74), width: s * 0.3, color: color)
        list.drawLine(from: Vec2(r.x + s * 0.73, r.y + s * 0.47), to: Vec2(r.x + s * 0.5, r.y + s * 0.74), width: s * 0.3, color: color)
    }

    private static func drawBolt(_ list: UIDrawList, _ r: UIRect, _ color: UIColor) {
        let s = r.width
        list.drawLine(from: Vec2(r.x + s * 0.6, r.y + s * 0.12), to: Vec2(r.x + s * 0.36, r.y + s * 0.52), width: s * 0.14, color: color, cap: .round)
        list.drawLine(from: Vec2(r.x + s * 0.36, r.y + s * 0.52), to: Vec2(r.x + s * 0.64, r.y + s * 0.48), width: s * 0.14, color: color, cap: .round)
        list.drawLine(from: Vec2(r.x + s * 0.64, r.y + s * 0.48), to: Vec2(r.x + s * 0.4, r.y + s * 0.88), width: s * 0.14, color: color, cap: .round)
    }

    private static func drawDiamond(_ list: UIDrawList, _ r: UIRect, _ color: UIColor) {
        let c = r.center, s = r.width * 0.26
        list.drawLine(from: c + Vec2(-s, 0) * 0.7, to: c + Vec2(s, 0) * 0.7, width: s * 1.4, color: UIColor(hex: 0xf5c542).withAlpha(color.a))
        list.drawLine(from: c + Vec2(0, -s), to: c + Vec2(0, s), width: s * 0.5, color: UIColor(hex: 0xf5c542).withAlpha(color.a))
    }

    private static func drawBullet(_ list: UIDrawList, _ r: UIRect, _ color: UIColor) {
        let s = r.width
        let body = UIRect(x: r.x + s * 0.36, y: r.y + s * 0.3, width: s * 0.28, height: s * 0.58)
        list.fillRect(body, color: color, radii: UICornerRadii(topLeft: s * 0.14, topRight: s * 0.14, bottomRight: 1, bottomLeft: 1))
        list.fillRect(UIRect(x: body.x, y: r.y + s * 0.12, width: body.width, height: s * 0.3), color: UIColor(hex: 0xe0a83a).withAlpha(color.a),
                      radii: UICornerRadii(topLeft: s * 0.14, topRight: s * 0.14, bottomRight: 0, bottomLeft: 0))
    }
}

/// The dimmed layer behind the pause menu: it takes every click, so the game doesn't.
private final class Backdrop: Widget {
    init() {
        super.init(name: "pauseOverlay")
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim)
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown, .pointerUp, .scroll: true
        default: false
        }
    }
}

/// A small cross at the screen center.
private final class Crosshair: Widget {
    init() {
        super.init(name: "crosshair")
        isHitTestable = false
    }

    override func measureContent(width: Float?) -> Vec2 { Vec2(22, 22) }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let c = frame.center
        for (a, b) in [(Vec2(-9, 0), Vec2(-4, 0)), (Vec2(4, 0), Vec2(9, 0)), (Vec2(0, -9), Vec2(0, -4)), (Vec2(0, 4), Vec2(0, 9))] {
            list.drawLine(from: c + a + Vec2(0, 1), to: c + b + Vec2(0, 1), width: 2, color: theme.hudTextShadow)
            list.drawLine(from: c + a, to: c + b, width: 2, color: theme.hudTextColor)
        }
    }
}

/// A round-cornered top-down map of the units around the player (the center), in the panel colors.
private final class Minimap: Widget {
    private let units: () -> [(position: Vec2, health: Float)]

    init(units: @escaping () -> [(position: Vec2, health: Float)]) {
        self.units = units
        super.init(name: "minimap")
        isHitTestable = false
    }

    override func measureContent(width: Float?) -> Vec2 { Vec2(180, 180) }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(frame, color: theme.panelBackground, radii: radii)
        list.withClip(frame.inset(by: 2)) {
            let c = frame.center
            for i in -3...3 where i != 0 {
                let o = snap(Float(i) * frame.width / 7)
                list.fillRect(UIRect(x: c.x + o, y: frame.y, width: 1, height: frame.height), color: theme.panelBorder)
                list.fillRect(UIRect(x: frame.x, y: c.y + o, width: frame.width, height: 1), color: theme.panelBorder)
            }
            let metersToPoints = frame.width / 30
            for unit in units() {
                let p = c + unit.position * metersToPoints
                let color = unit.health <= 0.25 ? theme.dangerColor : unit.health <= 0.5 ? theme.warningColor : theme.healthColor
                list.fillRect(UIRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8), color: color, radii: UICornerRadii(4))
            }
            // The terminal, and the player as an arrow at the center.
            let terminal = c + Vec2(10.5, -2) * metersToPoints
            list.fillRect(UIRect(x: terminal.x - 5, y: terminal.y - 5, width: 10, height: 10), color: UIColor(hex: 0xf5c542),
                          radii: UICornerRadii(2))
            list.drawLine(from: c + Vec2(0, -8), to: c + Vec2(-6, 7), width: 3, color: theme.hudTextColor, cap: .round)
            list.drawLine(from: c + Vec2(0, -8), to: c + Vec2(6, 7), width: 3, color: theme.hudTextColor, cap: .round)
        }
        list.strokeRect(frame, color: theme.panelBorder, width: theme.borderWidth, radii: radii)
        let label = TextLayout("N", font: theme.font, size: theme.smallFontSize)
        list.drawText(label, font: theme.font, at: Vec2(frame.center.x - label.width / 2, frame.y + 6), color: theme.secondaryTextColor)
    }
}
