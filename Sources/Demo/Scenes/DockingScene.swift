import Engine
import Foundation

/// Editor-style docking (`DockSpace`): a hierarchy, a scene viewport placeholder, an
/// inspector, a bottom tab group of three panels (the console scrolls both ways), and a
/// floating color panel. The layout is restored from a `DockLayout`, so the initial state is
/// fixed for screenshots (compare window screenshots, `ENGINE_SCREENSHOT_SOURCE=window`).
/// Drag tabs to reorder them or onto another group, a group's edge or the window's edge to dock
/// there, or into empty space to float them; drag dividers (double-click resets); drag a
/// floating window by its tab bar and resize it by its edges; Ctrl-Tab cycles tabs in the
/// focused group. The window title shows the cursor the UI asks for.
final class DockingScene: DemoScene {
    static let name = "docking"
    static let summary = "Docking panels: splits, tab groups, drag-and-drop docking, floating panel, 2-axis scrolling"

    let ui: UIContext
    private let dock = DockSpace()

    init(renderer: Renderer) throws {
        var theme = UITheme.dark()
        if ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil { theme.caretBlinkPeriod = 0 }
        ui = UIContext(theme: theme)
        build()
    }

    var uiContext: UIContext? { ui }
    var lighting: Lighting { Lighting(fogColor: Vec3(0.006, 0.007, 0.012)) }
    var initialView: OrbitView { OrbitView(distance: 10) }
    var status: String { "\(dock.openPanelIDs.count) panels open, cursor \(ui.desiredCursor)" }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ list: UIDrawList) {
        ui.draw(into: list)
    }

    // MARK: Building

    /// The layout the scene starts with (also what "Reset layout" restores).
    static let initialLayout = DockLayout(
        root: .split(axis: .horizontal, fractions: [0.2, 0.56, 0.24], children: [
            .tabs(panels: ["hierarchy"], active: "hierarchy"),
            .split(axis: .vertical, fractions: [0.64, 0.36], children: [
                .tabs(panels: ["scene", "game"], active: "scene"),
                .tabs(panels: ["console", "assets", "profiler"], active: "console"),
            ]),
            .tabs(panels: ["inspector"], active: "inspector"),
        ]),
        floating: [DockLayout.Floating(frame: UIRect(x: 560, y: 96, width: 250, height: 250), panels: ["color"])])

    private func build() {
        let theme = ui.theme
        let header = HStack(spacing: 10, padding: EdgeInsets(horizontal: 12, vertical: 0), name: "header", [
            Label("Docking", role: .heading),
            Label("Drag tabs onto groups, edges or empty space · drag dividers · Ctrl-Tab cycles tabs", role: .caption),
            Spacer(),
            Button("Reset layout", name: "reset") { [dock] in dock.restoreLayout(Self.initialLayout) },
        ])
        header.style.height = 36
        header.background = theme.panelBackground

        for panel in [hierarchyPanel(), scenePanel(), gamePanel(), consolePanel(), assetsPanel(), profilerPanel(),
                      inspectorPanel(), colorPanel()] {
            dock.addPanel(panel)
        }
        dock.restoreLayout(Self.initialLayout)
        dock.style.grow = 1
        dock.padding = EdgeInsets(top: 0, left: 4, bottom: 4, right: 4)
        dock.background = theme.fieldBackground

        let column = VStack(name: "column", [header, dock])
        column.isHitTestable = false
        ui.root.addChild(column)
    }

    private func padded(_ children: [Widget], spacing: Float = 8) -> VStack {
        VStack(spacing: spacing, padding: EdgeInsets(10), children)
    }

    private func hierarchyPanel() -> DockPanel {
        let tree = TreeView(roots: [
            TreeNode("World", isExpanded: true, children: [
                TreeNode("Main Camera"), TreeNode("Sun"),
                TreeNode("Player", isExpanded: true, children: [TreeNode("Body"), TreeNode("Weapon"), TreeNode("Flashlight")]),
                TreeNode("Level", isExpanded: true, children: [
                    TreeNode("Terrain"), TreeNode("Buildings", children: (1...8).map { TreeNode("Building \($0)") }),
                    TreeNode("Props", isExpanded: true, children: [TreeNode("Crate"), TreeNode("Barrel"), TreeNode("Lamp")]),
                ]),
            ]),
        ], name: "tree")
        tree.style.grow = 1
        tree.background = .clear
        if let player = tree.roots.first?.children.first(where: { $0.title == "Player" }) { tree.select(player) }
        let content = VStack(padding: EdgeInsets(4), [tree])
        return DockPanel(id: "hierarchy", title: "Hierarchy", content: content)
    }

    private func scenePanel() -> DockPanel {
        let panel = DockPanel(id: "scene", title: "Scene", content: ViewportPlaceholder(), isClosable: false, minSize: Vec2(200, 120))
        // Empty parts of the viewport belong to the game (camera controls).
        panel.passesPointerThrough = true
        return panel
    }

    private func gamePanel() -> DockPanel {
        DockPanel(id: "game", title: "Game", content: padded([Label("Game view (play mode)", role: .secondary)]))
    }

    private func consolePanel() -> DockPanel {
        let lines = VStack(spacing: 2, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        let messages = [
            "[info]  Engine started: metal backend, 4x MSAA, 1280x720 points at 2x",
            "[info]  Loaded scene 'Level 1' (2,431 entities, 118 meshes, 64 materials) in 182 ms",
            "[warn]  Texture 'rock_albedo.png' is not a power of two (1000x750); mipmaps are generated on the CPU",
            "[info]  Shader cache: 42 pipelines compiled, 0 failed",
            "[error] Script 'PlayerController': value of optional type 'Weapon?' must be unwrapped at line 118, column 22",
            "[info]  Autosave written to ~/Library/Application Support/Demo/autosave-2026-10-30T09-41-12.json",
        ]
        for i in 0..<18 {
            let message = messages[i % messages.count]
            let label = Label(String(format: "%02d:%02d.%03d  ", 9 + i / 60, 41 + i % 19, (i * 137) % 1000) + message,
                              role: message.hasPrefix("[info]") ? .secondary : .body, name: "line\(i)")
            if message.hasPrefix("[warn]") { label.color = UIColor(hex: 0xe8b04a) }
            if message.hasPrefix("[error]") { label.color = UIColor(hex: 0xf07167) }
            lines.addChild(label)
        }
        let scroll = ScrollView(lines, name: "consoleScroll")
        scroll.scrollsHorizontally = true
        scroll.scroll(toX: 40)
        scroll.scroll(to: 40)
        return DockPanel(id: "console", title: "Console", content: scroll)
    }

    private func assetsPanel() -> DockPanel {
        let list = ListView(items: (1...200).map { String(format: "Asset %03d.png", $0) }, name: "assetList")
        list.style.grow = 1
        return DockPanel(id: "assets", title: "Assets", content: VStack(padding: EdgeInsets(4), [list]))
    }

    private func profilerPanel() -> DockPanel {
        DockPanel(id: "profiler", title: "Profiler", content: padded([Label("Frame 16.6 ms · GPU 3.1 ms", role: .secondary)]))
    }

    private func inspectorPanel() -> DockPanel {
        func row(_ title: String, _ control: Widget) -> HStack {
            let label = Label(title, role: .secondary)
            label.style.width = 70
            control.style.grow = 1
            control.style.shrink = 1
            control.style.width = 0
            return HStack(spacing: 8, [label, control])
        }
        let content = padded([
            Label("Player", role: .heading),
            row("Name", TextField(text: "Player", name: "entityName")),
            Checkbox("Active", isOn: true, name: "active"),
            Separator(),
            Label("Transform", role: .body),
            row("X", Slider(value: 0.3, name: "x")),
            row("Y", Slider(value: 0.55, name: "y")),
            row("Z", Slider(value: 0.8, name: "z")),
            Separator(),
            Label("Mesh Renderer", role: .body),
            row("Material", Dropdown(options: ["Default", "Metal", "Glass"], name: "material")),
            Checkbox("Cast shadows", isOn: true, kind: .toggleSwitch, name: "shadows"),
            Checkbox("Receive shadows", isOn: true, kind: .toggleSwitch, name: "receive"),
        ])
        return DockPanel(id: "inspector", title: "Inspector", content: content, minSize: Vec2(180, 120))
    }

    private func colorPanel() -> DockPanel {
        let picker = ColorPicker(color: UIColor(hex: 0x3fa7d6), name: "tint")
        return DockPanel(id: "color", title: "Tint", content: padded([picker]))
    }
}

/// Stands in for the scene viewport (render-to-texture comes later): a dark gradient with a
/// perspective-free grid and a caption. Not hit-testable, so the game gets the clicks.
private final class ViewportPlaceholder: Widget {
    init() {
        super.init(name: "viewport")
        isHitTestable = false
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, fill: .linearGradient(start: UIColor(hex: 0x1d2433), end: UIColor(hex: 0x0e1118)))
        list.withClip(frame) {
            let step: Float = 40
            let center = Vec2(snap(frame.center.x), snap(frame.center.y))
            var x = center.x - (((center.x - frame.x) / step).rounded(.down)) * step
            while x < frame.maxX {
                list.fillRect(UIRect(x: x, y: frame.y, width: 1, height: frame.height),
                              color: UIColor(hex: 0xffffff, alpha: x == center.x ? 0.16 : 0.05))
                x += step
            }
            var y = center.y - (((center.y - frame.y) / step).rounded(.down)) * step
            while y < frame.maxY {
                list.fillRect(UIRect(x: frame.x, y: y, width: frame.width, height: 1),
                              color: UIColor(hex: 0xffffff, alpha: y == center.y ? 0.16 : 0.05))
                y += step
            }
        }
        let layout = context?.textLayout("Scene viewport", size: theme.fontSize) ?? TextLayout("Scene viewport", font: theme.font, size: theme.fontSize)
        list.drawText(layout, font: theme.font, at: Vec2(snap(frame.x + 12), snap(frame.y + 10)), color: theme.secondaryTextColor)
    }
}
