import Engine
import Foundation

/// The retained widget toolkit (`UIContext`): stacks with flex layout, buttons, checkboxes and
/// switches, sliders, text fields, a dropdown, a scroll view, a virtualized list, a tree and a
/// color picker, all in one ordered draw list with SDF text. The initial state shows a focused
/// text field with a selection, an open dropdown, a scrolled view and an expanded tree, so the
/// (input-free) screenshot covers those states; compare window screenshots
/// (`ENGINE_SCREENSHOT_SOURCE=window`). Interact with the mouse and keyboard: Tab / Shift-Tab
/// move focus, Esc closes the menu, then unfocuses (after which the demo's keys work again).
final class WidgetsScene: DemoScene {
    static let name = "widgets"
    static let summary = "Retained UI widgets: layout, focus, text field, dropdown, scroll view, list, tree, color picker"

    let ui: UIContext
    private var clicks = 0
    private let statusLabel = Label("Ready", role: .caption, name: "status")

    init(renderer: Renderer) throws {
        var theme = UITheme.dark()
        // Screenshots must not depend on where the caret blink is at the captured frame.
        if ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil { theme.caretBlinkPeriod = 0 }
        ui = UIContext(theme: theme)
        build()
    }

    var uiContext: UIContext? { ui }
    var lighting: Lighting { Lighting(fogColor: Vec3(0.006, 0.007, 0.012)) }
    var initialView: OrbitView { OrbitView(distance: 10) }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ list: UIDrawList) {
        ui.draw(into: list)
    }

    // MARK: Building

    private func panel(_ title: String, _ children: [Widget]) -> Stack {
        let theme = ui.theme
        let stack = VStack(spacing: 8, padding: EdgeInsets(theme.panelPadding), name: title, [Label(title, role: .heading)] + children)
        stack.background = theme.panelBackground
        stack.borderColor = theme.panelBorder
        stack.cornerRadius = 10
        stack.style.grow = 1
        stack.style.shrink = 1
        stack.style.width = 0  // equal columns: all width comes from grow
        return stack
    }

    private func row(_ label: String, _ control: Widget, value: Label? = nil) -> HStack {
        let title = Label(label, role: .secondary)
        title.style.width = 74
        control.style.grow = 1
        var children: [Widget] = [title, control]
        if let value {
            value.style.width = 40
            value.alignment = .right
            children.append(value)
        }
        return HStack(spacing: 8, children)
    }

    private func build() {
        // Column 1: controls.
        let volumeValue = Label("", role: .secondary)
        let volume = Slider(value: 0.62, name: "volume") { volumeValue.text = "\(Int(($0 * 100).rounded()))%" }
        volumeValue.text = "\(Int((volume.value * 100).rounded()))%"
        let qualityValue = Label("", role: .secondary)
        let quality = Slider(value: 2, in: 0...4, step: 1, name: "quality") { qualityValue.text = "\(Int($0))" }
        qualityValue.text = "\(Int(quality.value))"

        let name = TextField(text: "Player One", placeholder: "Name", name: "name")
        let search = TextField(placeholder: "Search…", name: "search")
        let upscaler = Dropdown(options: ["Bilinear", "FSR 1", "TAAU", "MetalFX spatial", "MetalFX temporal"],
                                selectedIndex: 1, name: "upscaler") { [statusLabel] in statusLabel.text = "Upscaler option \($0)" }
        let disabled = Button("Disabled", name: "disabled")
        disabled.isEnabled = false

        let controls = panel("Controls", [
            Label("Click, drag, type; Tab moves focus.", role: .caption),
            HStack(spacing: 8, [
                Button("Save", role: .primary, name: "save") { [unowned self] in clicks += 1; statusLabel.text = "Saved \(clicks)x" },
                Button("Cancel", name: "cancel") { [statusLabel] in statusLabel.text = "Cancelled" },
                disabled,
            ]),
            Separator(),
            Checkbox("Show grid", isOn: true, name: "grid"),
            Checkbox("Snap to pixels", name: "snap"),
            Checkbox("Vertical sync", isOn: true, kind: .toggleSwitch, name: "vsync"),
            Checkbox("Disabled switch", kind: .toggleSwitch, name: "disabledSwitch").disabled(),
            row("Volume", volume, value: volumeValue),
            row("Quality", quality, value: qualityValue),
            Separator(),
            row("Name", name),
            row("Search", search),
            row("Upscaler", upscaler),
            Spacer(),
            statusLabel,
        ])

        // Column 2: a scroll view of settings and a long, virtualized list.
        let settings = VStack(spacing: 6, padding: EdgeInsets(top: 4, left: 4, bottom: 4, right: 14))
        for i in 1...24 {
            if i % 3 == 0 {
                settings.addChild(row("Mix \(i)", Slider(value: Float(i % 7) / 6)))
            } else {
                settings.addChild(Checkbox("Option \(i)", isOn: i % 4 == 1, kind: i % 2 == 0 ? .toggleSwitch : .checkbox))
            }
        }
        let scroll = ScrollView(settings, name: "settingsScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        scroll.background = ui.theme.fieldBackground.withAlpha(0.5)
        scroll.cornerRadius = 6
        scroll.padding = EdgeInsets(4)
        scroll.scroll(to: 150)

        let list = ListView(items: (1...1000).map { String(format: "Asset %04d.png", $0) }, name: "assets")
        list.style.height = 170
        list.selectRow(4)
        list.onSelect = { [statusLabel] row in statusLabel.text = "Selected asset \(row.map(String.init) ?? "none")" }

        let scrolling = panel("Scroll view", [scroll, Label("List (1000 rows, virtualized)", role: .caption), list])

        // Column 3: the hierarchy tree and a color picker.
        let world = TreeNode("World", isExpanded: true, children: [
            TreeNode("Camera"),
            TreeNode("Sun"),
            TreeNode("Player", isExpanded: true, children: [
                TreeNode("Body"), TreeNode("Weapon", children: [TreeNode("Muzzle flash")]), TreeNode("Flashlight"),
            ]),
            TreeNode("Level", isExpanded: true, children: [
                TreeNode("Terrain"),
                TreeNode("Buildings", children: (1...12).map { TreeNode("Building \($0)") }),
                TreeNode("Props", isExpanded: true, children: [TreeNode("Crate"), TreeNode("Barrel"), TreeNode("Lamp")]),
            ]),
        ])
        let tree = TreeView(roots: [world, TreeNode("UI Root", children: [TreeNode("HUD")])], name: "hierarchy")
        tree.style.grow = 1
        tree.style.shrink = 1
        tree.preferredVisibleRows = 6
        if let player = world.children.first(where: { $0.title == "Player" }) { tree.select(player.children[1]) }
        tree.onSelect = { [statusLabel] node in statusLabel.text = "Selected \(node?.title ?? "nothing")" }

        let colorValue = Label("", role: .caption)
        let picker = ColorPicker(color: UIColor(hex: 0x3fa7d6), name: "color") { colorValue.text = "Tint \($0.hexString)" }
        colorValue.text = "Tint \(picker.color.hexString)"
        let hierarchy = panel("Hierarchy", [tree, Label("Color", role: .heading), picker, colorValue])

        let columns = HStack(spacing: 16, alignment: .stretch, padding: EdgeInsets(20), name: "columns",
                             [controls, scrolling, hierarchy])
        columns.isHitTestable = false
        ui.root.addChild(columns)

        // Initial state worth a screenshot: a focused field with a selection, an open menu.
        ui.focus(name)
        name.select(7..<10)
        upscaler.open()
    }
}

extension Widget {
    /// Disables the widget and returns it (for building trees inline).
    func disabled() -> Self {
        isEnabled = false
        return self
    }
}
