import Engine
import Foundation

private enum Faction: String, Codable, CaseIterable { case neutral, friendly, hostile }

private struct CombatStats: Codable, Equatable {
    var health = 100
    var armor: Float = 0.25
    var regenPerSecond: Float = 1.5
}

/// A demo component with one field of every kind the property grid knows.
private struct Showcase: Component, Equatable {
    static let componentName = "Showcase"
    static var fieldHints: [String: FieldHints] {
        [
            "level": FieldHints(range: 1...20, step: 1, tooltip: "Integer with a range: drag, type or use the arrow keys."),
            "intensity": FieldHints(range: 0...10, step: 0.1),
            "mass": FieldHints(step: 0.5, displayName: "Mass (kg)"),
            "tint": FieldHints(color: true),
            "glow": FieldHints(color: true),
            "debugId": FieldHints(readOnly: true),
            "internalNote": FieldHints(hidden: true),
            "stats.armor": FieldHints(range: 0...1, step: 0.01),
            "waypoints.*": FieldHints(step: 0.25),
        ]
    }

    var isEnabled = true
    var level = 7
    var intensity: Float = 2.5
    var mass: Float = 72.5
    var label = "Hero"
    var uv = Vec2(0.25, 0.75)
    var offset = Vec3(1, 2, -3.5)
    var tint = Vec3(0.9, 0.45, 0.12)
    var glow = Vec4(0.1, 0.6, 1, 1)
    var spin = Quat(eulerDegrees: Vec3(15, 40, 0))
    var faction = Faction.friendly
    var stats = CombatStats()
    var waypoints = [Vec3(0, 0, 0), Vec3(4, 0, 2), Vec3(8, 1, 2)]
    var target = Entity.invalid
    var debugId = 42
    var internalNote = "not shown"
    var bonus: Float?
}

/// The entity's name in the hierarchy (a demo component: the engine has none yet).
private struct Named: Component, Equatable {
    static let componentName = "Named"
    var name: String
}

/// The editor's two main panels on a small ECS world: a hierarchy `TreeView` (multi-select,
/// rename in place with F2 / double click, drag to reparent) and an inspector `PropertyGrid`
/// for the primary selected entity, built from reflection. No 3D view. The initial state is
/// deterministic: three rows selected (Player is the primary one the inspector shows), the
/// Player's components expanded.
final class InspectorScene: DemoScene {
    static let name = "inspector"
    static let summary = "Editor panels: hierarchy tree (multi-select, rename, drag to reparent) and a reflection-driven property grid"

    let ui: UIContext
    private let world = World()
    private let tree: TreeView
    private let grid: PropertyGrid
    private let status = Label("Ready", role: .caption, name: "status")
    private let title = Label("", role: .heading, name: "title")
    private let subtitle = Label("", role: .caption, name: "subtitle")
    private var entities: [String: Entity] = [:]
    private let benchmarking = ProcessInfo.processInfo.environment["INSPECTOR_BENCH"] != nil
    private var paintFrames = 0
    private var paintTotal = 0.0

    init(renderer: Renderer) throws {
        var theme = UITheme.dark()
        // Screenshots must not depend on where the caret blink is at the captured frame.
        if ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil { theme.caretBlinkPeriod = 0 }
        ui = UIContext(theme: theme)
        grid = PropertyGrid(world: world)
        tree = TreeView(roots: [], name: "hierarchy")
        build()
        if ProcessInfo.processInfo.environment["INSPECTOR_BENCH"] != nil { bench() }
    }

    var uiContext: UIContext? { ui }
    var lighting: Lighting { Lighting(fogColor: Vec3(0.006, 0.007, 0.012)) }
    var initialView: OrbitView { OrbitView(distance: 10) }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func update(input: Input, dt: Float, time: Float) {
        grid.refresh()
    }

    func drawUI(_ list: UIDrawList) {
        ui.draw(into: list)
        if benchmarking {
            paintFrames += 1
            if paintFrames > 30 { paintTotal += ui.stats.paintTime }
            if paintFrames == 330 {
                print(String(format: "inspector bench: paint %.3f ms avg over 300 frames (%d items)", paintTotal / 300 * 1e3,
                             ui.stats.paintedItems))
            }
        }
    }

    // MARK: World

    @discardableResult
    private func spawn(_ name: String, parent: Entity? = nil, at position: Vec3 = .zero, _ extra: [any Component] = []) -> Entity {
        let e = world.spawn(Named(name: name), Transform(position: position))
        for component in extra { world.add(component, to: e) }
        if let parent { world.setParent(e, to: parent) }
        entities[name] = e
        return e
    }

    private func buildWorld() {
        let scene = spawn("Scene")
        spawn("Main Camera", parent: scene, at: Vec3(0, 3, 10), [Camera(fovY: 0.9, far: 800)])
        let sun = spawn("Sun", parent: scene, [DirectionalLight(color: Vec3(1, 0.95, 0.85), intensity: 2.8)])
        world.modify(Transform.self, for: sun) { $0.rotation = Quat(eulerDegrees: Vec3(-50, 30, 0)) }
        let mesh = MeshRenderer(mesh: .cube, tint: Vec3(0.8, 0.8, 0.9), opacity: 1)
        var showcase = Showcase()
        showcase.target = sun
        let player = spawn("Player", parent: scene, at: Vec3(2, 0, -1), [mesh, showcase])
        spawn("Body", parent: player, [mesh])
        let weapon = spawn("Weapon", parent: player, at: Vec3(0.4, 1, 0.2), [mesh])
        spawn("Muzzle", parent: weapon)
        spawn("Flashlight", parent: player)
        let level = spawn("Level", parent: scene)
        spawn("Terrain", parent: level, [MeshRenderer(mesh: .plane)])
        let props = spawn("Props", parent: level)
        for (i, name) in ["Crate", "Barrel", "Lamp"].enumerated() {
            spawn(name, parent: props, at: Vec3(Float(i) * 2, 0, 3), [mesh])
        }
        let buildings = spawn("Buildings", parent: level)
        for i in 1...8 { spawn("Building \(i)", parent: buildings, at: Vec3(Float(i) * 6, 0, -12)) }
    }

    private func node(for entity: Entity) -> TreeNode {
        let name = world.get(Named.self, for: entity)?.name ?? "Entity"
        let children = world.children(of: entity).map(node(for:))
        let node = TreeNode(name, children: children, userData: entity)
        // Icons (VectorIcon, built-in Lucide names) by what the entity is.
        let icon = world.has(Camera.self, for: entity) ? "video" : world.has(DirectionalLight.self, for: entity) ? "sun"
            : world.has(MeshRenderer.self, for: entity) ? "box" : children.isEmpty ? "circle-dashed" : "layers"
        node.icon = VectorIcon.named(icon)
        return node
    }

    /// Section header icons by component name.
    private static let componentIcons = ["Transform": "move-3d", "Camera": "video", "DirectionalLight": "sun", "MeshRenderer": "box",
                                         "Named": "tag"]

    // MARK: UI

    private func panel(_ children: [Widget], name: String) -> Stack {
        let theme = ui.theme
        let stack = VStack(spacing: 8, padding: EdgeInsets(theme.panelPadding), name: name, children)
        stack.background = theme.panelBackground
        stack.borderColor = theme.panelBorder
        stack.cornerRadius = 10
        return stack
    }

    private func build() {
        buildWorld()
        let root = node(for: entities["Scene"]!)
        func find(_ node: TreeNode, _ title: String) -> TreeNode? {
            if node.title == title { return node }
            for child in node.children { if let found = find(child, title) { return found } }
            return nil
        }
        // Expanded: the scene, the player and its weapon, the level and its props. Buildings stays folded.
        for title in ["Scene", "Player", "Weapon", "Level", "Props"] { find(root, title)?.isExpanded = true }

        tree.roots = [root]
        grid.componentIcon = { VectorIcon.named(Self.componentIcons[$0] ?? "puzzle") }
        tree.allowsMultipleSelection = true
        tree.allowsRename = true
        tree.allowsDragAndDrop = true
        tree.style.grow = 1
        tree.style.shrink = 1
        tree.onSelect = { [unowned self] node in
            let entity = node?.userData as? Entity
            grid.entity = entity
            title.text = node?.title ?? "Nothing selected"
            updateSubtitle()
        }
        tree.onSelectionChange = { [unowned self] _ in updateSubtitle() }
        tree.onRename = { [unowned self] node, newName in
            guard let entity = node.userData as? Entity else { return false }
            world.add(Named(name: newName), to: entity)
            title.text = newName
            return true
        }
        tree.onMove = { [unowned self] nodes, parent, _ in
            for node in nodes {
                guard let entity = node.userData as? Entity else { return false }
                // The world keeps children in attach order, so only the parent change is mirrored here.
                _ = world.setParent(entity, to: parent?.userData as? Entity)
            }
            status.text = "Moved \(nodes.count) node\(nodes.count == 1 ? "" : "s")"
            return true
        }

        grid.entityName = { [unowned self] e in world.get(Named.self, for: e)?.name }
        grid.componentFilter = { $0 != "Named" }
        grid.onFieldEdit = { [unowned self] edit in
            if edit.phase == .ended { status.text = "\(edit.componentName).\(edit.path) = \(Self.describe(edit.newValue))" }
        }
        grid.onRemoveComponent = { [unowned self] entity, name in status.text = "Remove \(name) from \(entity)?" }

        let scroll = ScrollView(grid, name: "inspectorScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        scroll.padding = EdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        grid.padding = EdgeInsets(top: 0, left: 0, bottom: 0, right: 8)

        let hierarchy = panel([Label("Hierarchy", role: .heading), tree], name: "hierarchyPanel")
        hierarchy.style.width = 300
        let inspector = panel([Label("Inspector", role: .heading), title, subtitle, Separator(), scroll, status], name: "inspectorPanel")
        inspector.style.grow = 1
        inspector.style.width = 0

        let columns = HStack(spacing: 16, alignment: .stretch, padding: EdgeInsets(20), name: "columns", [hierarchy, inspector])
        columns.isHitTestable = false
        ui.root.addChild(columns)

        // Initial state worth a screenshot: a multi-selection, the player shown in the inspector.
        let player = find(root, "Player")!
        tree.setSelection([player, find(root, "Weapon")!, find(root, "Crate")!], primary: player)
        // Fold the plain components so the Showcase's enum, color, struct and array rows fit on screen.
        grid.setCollapsed(true, component: "Transform")
        grid.setCollapsed(true, component: "MeshRenderer")
        grid.refresh()
    }

    private func updateSubtitle() {
        let count = tree.selectedNodes.count
        subtitle.text = count > 1 ? "\(count) entities selected, showing the first" : count == 1 ? "1 entity" : ""
    }

    private static func describe(_ value: FieldValue) -> String {
        switch value {
        case .null: "none"
        case .bool(let b): "\(b)"
        case .int(let i): "\(i)"
        case .float(let d): String(format: "%.3f", d)
        case .string(let s): "\"\(s)\""
        case .vec2(let v): "(\(v.x), \(v.y))"
        case .vec3(let v): "(\(v.x), \(v.y), \(v.z))"
        case .vec4(let v): "(\(v.x), \(v.y), \(v.z), \(v.w))"
        case .quat(let q): "(\(q.x), \(q.y), \(q.z), \(q.w))"
        case .entity(let e): "\(e)"
        case .enumCase(let c): c
        }
    }

    /// `INSPECTOR_BENCH=1`: prints CPU time of `PropertyGrid.refresh()` at startup and of painting the UI after 330 frames.
    private func bench() {
        ui.setViewport(size: Vec2(1280, 720), scale: 1)
        ui.layoutIfNeeded()
        let clock = ContinuousClock()
        func ms(_ d: Duration) -> Double { Double(d.components.seconds) * 1e3 + Double(d.components.attoseconds) * 1e-15 }
        let n = 2000
        let refresh = clock.measure { for _ in 0..<n { grid.refresh() } }
        // Reflection alone, for comparison: reading every field of the shown entity.
        let player = tree.selectedNode?.userData as? Entity
        let reading = clock.measure {
            for _ in 0..<n { for c in world.components(of: player!) { _ = c.fields() } }
        }
        print(String(format: "inspector bench: refresh %.3f ms, reflection read only %.3f ms, layout %.3f ms",
                     ms(refresh) / Double(n), ms(reading) / Double(n), ui.stats.layoutTime * 1e3))
    }
}
