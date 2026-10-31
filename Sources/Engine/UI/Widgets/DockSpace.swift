import Foundation

/// A side of a tab group or of the whole dock space.
public enum DockEdge: String, Codable, Sendable, CaseIterable {
    case left, right, top, bottom

    /// The axis of the split that docking on this edge creates.
    public var axis: Axis { self == .left || self == .right ? .horizontal : .vertical }
    /// Left and top come first in a split.
    var isLeading: Bool { self == .left || self == .top }
}

/// Where `DockSpace.dock(_:at:)` puts a panel.
public enum DockPosition: Sendable, Equatable {
    /// As a tab in the group showing panel `with` (appended without an index).
    case tab(with: String, index: Int? = nil)
    /// In a new group beside the group showing panel `beside`, taking `fraction` of its space.
    case split(beside: String, edge: DockEdge, fraction: Float = 0.5)
    /// In a new group along an edge of the whole dock space, taking `fraction` of it.
    case edge(DockEdge, fraction: Float = 0.25)
    /// In a floating window; `frame` is in points relative to the dock space's top-left corner.
    case floating(UIRect)
}

/// A saved dock arrangement: the docked tree (splits with fractions, tab groups with panel IDs
/// and the selected one) and the floating windows. Plain data, Codable as readable JSON:
///
///     {"floating":[{"active":"color","frame":[560,96,250,250],"tabs":["color"]}],
///      "root":{"children":[{"active":"hierarchy","tabs":["hierarchy"]}, …],
///              "fractions":[0.2,0.56,0.24],"split":"horizontal"},
///      "version":1}
///
/// `DockSpace.restoreLayout` drops IDs it has no panel for (and repeats of an ID), then
/// collapses what became empty, so layouts survive panels being renamed or removed.
public struct DockLayout: Codable, Equatable, Sendable {
    public indirect enum Node: Equatable, Sendable {
        /// Children side by side (`.horizontal`) or stacked; `fractions` are their shares.
        case split(axis: Axis, fractions: [Float], children: [Node])
        /// A tab group: panel IDs in tab order and the selected one.
        case tabs(panels: [String], active: String?)
    }

    public struct Floating: Codable, Equatable, Sendable {
        /// Points, relative to the dock space's top-left corner.
        public var frame: UIRect
        public var panels: [String]
        public var active: String?

        public init(frame: UIRect, panels: [String], active: String? = nil) {
            self.frame = frame
            self.panels = panels
            self.active = active
        }

        private enum CodingKeys: String, CodingKey { case frame, tabs, active }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let f = try c.decode([Float].self, forKey: .frame)
            guard f.count == 4 else {
                throw DecodingError.dataCorruptedError(forKey: .frame, in: c, debugDescription: "frame needs [x, y, width, height]")
            }
            frame = UIRect(x: f[0], y: f[1], width: f[2], height: f[3])
            panels = try c.decode([String].self, forKey: .tabs)
            active = try c.decodeIfPresent(String.self, forKey: .active)
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode([frame.x, frame.y, frame.width, frame.height], forKey: .frame)
            try c.encode(panels, forKey: .tabs)
            try c.encodeIfPresent(active, forKey: .active)
        }
    }

    public static let currentVersion = 1
    public var version: Int
    /// The docked tree; nil when nothing is docked.
    public var root: Node?
    /// Floating windows, back to front.
    public var floating: [Floating]

    public init(root: Node?, floating: [Floating] = []) {
        version = Self.currentVersion
        self.root = root
        self.floating = floating
    }

    /// Every panel ID in the layout: the docked tree depth first, then the floating windows.
    public var panelIDs: [String] {
        func visit(_ node: Node) -> [String] {
            switch node {
            case .split(_, _, let children): return children.flatMap(visit)
            case .tabs(let panels, _): return panels
            }
        }
        return (root.map(visit) ?? []) + floating.flatMap(\.panels)
    }

    /// Pretty-printed JSON with sorted keys (stable for version control).
    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(json data: Data) throws -> DockLayout {
        try JSONDecoder().decode(DockLayout.self, from: data)
    }

    private enum CodingKeys: String, CodingKey { case version, root, floating }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? Self.currentVersion
        root = try c.decodeIfPresent(Node.self, forKey: .root)
        floating = try c.decodeIfPresent([Floating].self, forKey: .floating) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encodeIfPresent(root, forKey: .root)
        try c.encode(floating, forKey: .floating)
    }
}

extension DockLayout.Node: Codable {
    private enum CodingKeys: String, CodingKey { case split, fractions, children, tabs, active }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let axis = try c.decodeIfPresent(String.self, forKey: .split) {
            guard axis == "horizontal" || axis == "vertical" else {
                throw DecodingError.dataCorruptedError(forKey: .split, in: c, debugDescription: "split must be horizontal or vertical")
            }
            self = .split(axis: axis == "horizontal" ? .horizontal : .vertical,
                          fractions: try c.decodeIfPresent([Float].self, forKey: .fractions) ?? [],
                          children: try c.decode([DockLayout.Node].self, forKey: .children))
        } else {
            self = .tabs(panels: try c.decode([String].self, forKey: .tabs),
                         active: try c.decodeIfPresent(String.self, forKey: .active))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .split(let axis, let fractions, let children):
            try c.encode(axis == .horizontal ? "horizontal" : "vertical", forKey: .split)
            try c.encode(fractions, forKey: .fractions)
            try c.encode(children, forKey: .children)
        case .tabs(let panels, let active):
            try c.encode(panels, forKey: .tabs)
            try c.encodeIfPresent(active, forKey: .active)
        }
    }
}

/// A node of the live dock tree: a split (`axis` set) or a tab group.
@MainActor
final class DockNode {
    var axis: Axis?
    var children: [DockNode] = []
    var fractions: [Float] = []
    var panels: [String] = []
    var active: String?
    weak var parent: DockNode?
    /// The `SplitView` or `TabView` built for it by the last rebuild.
    weak var view: Widget?

    init(panels: [String], active: String? = nil) {
        self.panels = panels
        self.active = active ?? panels.first
    }

    init(axis: Axis, children: [DockNode], fractions: [Float]) {
        self.axis = axis
        self.children = children
        self.fractions = SplitLayout.normalized(fractions, count: children.count)
        for child in children { child.parent = self }
    }

    var isGroup: Bool { axis == nil }

    func replace(_ child: DockNode, with node: DockNode) {
        guard let i = children.firstIndex(where: { $0 === child }) else { return }
        children[i] = node
        node.parent = self
    }
}

/// A floating window's state: its frame (relative to the dock space) and its tab group.
@MainActor
final class DockFloat {
    var frame: UIRect
    let group: DockNode

    init(frame: UIRect, group: DockNode) {
        self.frame = frame
        self.group = group
    }
}

/// Where a dragged tab would land.
@MainActor
enum DockDropTarget {
    case tab(DockNode, index: Int)
    case split(DockNode, DockEdge)
    case edge(DockEdge)
    case floating(UIRect)
}

/// Editor-style docking: `DockPanel`s arranged in tab groups (`TabView`s) inside a tree of
/// splits (`SplitView`s), plus floating windows above them.
///
/// Register panels with `addPanel`, then arrange them with `dock(_:at:)` or `restoreLayout`.
/// The user can:
/// - drag a tab along its bar to reorder it;
/// - drag it off the bar onto another group's bar (inserted where the marker shows) or onto the
///   middle of a group (added as a tab), onto the outer quarter of a group (splits the group on
///   that side), onto the outermost strip of the dock space (a full-length group along that
///   edge), or anywhere else (a new floating window); a highlight shows the result while
///   dragging, and Esc cancels;
/// - drag dividers (double-click resets a split to equal shares);
/// - move a floating window by the empty part of its tab bar, resize it by its edges and
///   corners, and bring it to the front by clicking in it;
/// - close a tab (closing the last tab of a group removes the group and collapses its split).
///
/// `layout` / `restoreLayout` save and restore the arrangement as a Codable `DockLayout`, and
/// `onLayoutChange` reports every user change. Floating windows live inside the main window;
/// separate OS windows are not supported.
public final class DockSpace: Widget {
    public private(set) var panels: [String: DockPanel] = [:]
    /// Called after the user changes the layout (drop, close, divider drag, tab selection or
    /// order, floating window move or resize). Save `layout` here.
    public var onLayoutChange: ((DockLayout) -> Void)?
    /// Space between docked groups (points).
    public var dividerThickness: Float = 4 { didSet { if dividerThickness != oldValue { rebuild() } } }
    /// The color of that space; nil uses the theme's field background.
    public var gapColor: UIColor? { didSet { rebuild() } }
    /// Width of the strip along the dock space's edges that docks along the whole edge (points).
    public var edgeDropBand: Float = 24
    /// Height of every group's tab bar (points).
    public var tabBarHeight: Float = 28 { didSet { if tabBarHeight != oldValue { rebuild() } } }
    /// Smallest floating window (points).
    public var minFloatingSize = Vec2(160, 100)

    var root: DockNode?
    var floats: [DockFloat] = []
    private weak var activeNode: DockNode?
    private var tabDrag: (panel: DockPanel, source: DockNode, target: DockDropTarget?)?

    public override init(name: String = "dock") {
        super.init(name: name)
        isHitTestable = false
    }

    /// The tab group the user last clicked in (its selected tab gets the accent line).
    public var activeGroup: TabView? { activeNode?.view as? TabView }

    // MARK: Panels

    /// Registers a panel so layouts can show it. It isn't visible until docked.
    public func addPanel(_ panel: DockPanel) {
        if let old = panels[panel.id], old !== panel, isOpen(panel.id) {
            detach(panel.id)
            normalize()
        }
        panels[panel.id] = panel
        rebuild()
    }

    /// Closes and unregisters a panel.
    public func removePanel(_ id: String) {
        guard panels[id] != nil else { return }
        detach(id)
        normalize()
        panels[id] = nil
        rebuild()
    }

    public func panel(_ id: String) -> DockPanel? { panels[id] }

    /// Whether the panel is in the layout (docked or floating).
    public func isOpen(_ id: String) -> Bool { group(containing: id) != nil }

    /// IDs of the panels in the layout (docked depth first, then floating).
    public var openPanelIDs: [String] { layout.panelIDs }

    /// Docks (or moves) a registered panel and selects it. Positions relative to a panel that
    /// isn't open fall back to the right edge.
    public func dock(_ id: String, at position: DockPosition) {
        guard panels[id] != nil else { return }
        switch position {
        case .tab(let other, let index):
            guard let g = group(containing: other) else { return dock(id, at: .edge(.right)) }
            move(id, to: .tab(g, index: index ?? g.panels.count))
        case .split(let other, let edge, let fraction):
            guard let g = group(containing: other) else { return dock(id, at: .edge(edge, fraction: fraction)) }
            // Floating windows hold a single group: docking beside one adds a tab instead.
            move(id, to: isFloating(g) ? .tab(g, index: g.panels.count) : .split(g, edge), fraction: fraction)
        case .edge(let edge, let fraction):
            move(id, to: .edge(edge), fraction: fraction)
        case .floating(let frame):
            move(id, to: .floating(frame))
        }
    }

    /// Closes a panel as the user would: removes it from the layout (collapsing an emptied
    /// group and split) and calls its `onClose`. It stays registered and can be docked again.
    public func closePanel(_ id: String) {
        guard let panel = panels[id], isOpen(id) else { return }
        detach(id)
        normalize()
        rebuild()
        panel.onClose?()
        layoutChanged()
    }

    /// Selects the panel's tab and brings its floating window to the front.
    public func focusPanel(_ id: String) {
        guard let g = group(containing: id) else { return }
        g.active = id
        if let view = g.view as? TabView, let i = view.index(of: id) { view.select(i) }
        if let f = floats.firstIndex(where: { $0.group === g }) { bringToFront(f) }
        activeNode = g
        setNeedsDisplay()
    }

    // MARK: Persistence

    /// The current arrangement.
    public var layout: DockLayout {
        func node(_ n: DockNode) -> DockLayout.Node {
            if let axis = n.axis { return .split(axis: axis, fractions: n.fractions, children: n.children.map(node)) }
            return .tabs(panels: n.panels, active: n.active)
        }
        return DockLayout(root: root.map(node), floating: floats.map {
            DockLayout.Floating(frame: $0.frame, panels: $0.group.panels, active: $0.group.active)
        })
    }

    /// Replaces the arrangement. Unknown panel IDs and repeated ones are dropped, groups left
    /// empty disappear and splits collapse; fractions are normalized.
    public func restoreLayout(_ layout: DockLayout) {
        var seen = Set<String>()
        func ids(_ list: [String]) -> [String] {
            list.filter { panels[$0] != nil && seen.insert($0).inserted }
        }
        func build(_ node: DockLayout.Node) -> DockNode {
            switch node {
            case .split(let axis, let fractions, let children):
                return DockNode(axis: axis, children: children.map(build), fractions: fractions)
            case .tabs(let list, let active):
                let kept = ids(list)
                return DockNode(panels: kept, active: active.flatMap { kept.contains($0) ? $0 : nil })
            }
        }
        root = layout.root.map(build)
        root?.parent = nil
        floats = layout.floating.map { f in
            let kept = ids(f.panels)
            return DockFloat(frame: f.frame, group: DockNode(panels: kept, active: f.active.flatMap { kept.contains($0) ? $0 : nil }))
        }
        normalize()
        rebuild()
    }

    // MARK: Tree operations

    private func isFloating(_ node: DockNode) -> Bool { floats.contains { $0.group === node } }

    func group(containing id: String) -> DockNode? {
        func find(_ node: DockNode) -> DockNode? {
            if node.isGroup { return node.panels.contains(id) ? node : nil }
            for child in node.children { if let g = find(child) { return g } }
            return nil
        }
        if let root, let g = find(root) { return g }
        return floats.first { $0.group.panels.contains(id) }?.group
    }

    /// Takes `id` out of its group, leaving an empty group in place (see `normalize`).
    private func detach(_ id: String) {
        guard let g = group(containing: id), let i = g.panels.firstIndex(of: id) else { return }
        g.panels.remove(at: i)
        if g.active == id { g.active = g.panels.isEmpty ? nil : g.panels[min(i, g.panels.count - 1)] }
    }

    /// Puts `id` (not in the tree) at `target`. `fraction` is the new group's share for splits and edges.
    private func insert(_ id: String, at target: DockDropTarget, fraction: Float) {
        let fraction = min(max(fraction.isFinite ? fraction : 0.5, 0.05), 0.95)
        switch target {
        case .tab(let g, let index):
            g.panels.insert(id, at: min(max(index, 0), g.panels.count))
            g.active = id
        case .split(let g, let edge):
            let new = DockNode(panels: [id])
            if let parent = g.parent, parent.axis == edge.axis, let i = parent.children.firstIndex(where: { $0 === g }) {
                let share = parent.fractions[i]
                parent.fractions[i] = share * (1 - fraction)
                let at = edge.isLeading ? i : i + 1
                parent.children.insert(new, at: at)
                parent.fractions.insert(share * fraction, at: at)
                new.parent = parent
            } else {
                let parent = g.parent
                let split = DockNode(axis: edge.axis, children: edge.isLeading ? [new, g] : [g, new],
                                     fractions: edge.isLeading ? [fraction, 1 - fraction] : [1 - fraction, fraction])
                if let parent { parent.replace(g, with: split) } else if root === g { root = split; split.parent = nil }
            }
        case .edge(let edge):
            let new = DockNode(panels: [id])
            guard let old = root else {
                root = new
                return
            }
            if old.axis == edge.axis {
                old.fractions = old.fractions.map { $0 * (1 - fraction) }
                let at = edge.isLeading ? 0 : old.children.count
                old.children.insert(new, at: at)
                old.fractions.insert(fraction, at: at)
                new.parent = old
            } else {
                root = DockNode(axis: edge.axis, children: edge.isLeading ? [new, old] : [old, new],
                                fractions: edge.isLeading ? [fraction, 1 - fraction] : [1 - fraction, fraction])
            }
        case .floating(let frame):
            floats.append(DockFloat(frame: frame, group: DockNode(panels: [id])))
        }
    }

    /// Drops empty groups, collapses splits left with one child, merges a split into a parent
    /// split of the same axis, and renormalizes fractions.
    private func normalize() {
        func clean(_ node: DockNode) -> DockNode? {
            if node.isGroup {
                if node.panels.isEmpty { return nil }
                if node.active == nil || !node.panels.contains(node.active!) { node.active = node.panels.first }
                return node
            }
            var children: [DockNode] = [], fractions: [Float] = []
            let own = SplitLayout.normalized(node.fractions, count: node.children.count)
            for (child, share) in zip(node.children, own) {
                guard let kept = clean(child) else { continue }
                if kept.axis != nil && kept.axis == node.axis {
                    for (grandchild, inner) in zip(kept.children, kept.fractions) {
                        children.append(grandchild)
                        fractions.append(share * inner)
                    }
                } else {
                    children.append(kept)
                    fractions.append(share)
                }
            }
            if children.isEmpty { return nil }
            if children.count == 1 { return children[0] }
            node.children = children
            node.fractions = SplitLayout.normalized(fractions, count: children.count)
            for child in children { child.parent = node }
            return node
        }
        root = root.flatMap(clean)
        root?.parent = nil
        floats.removeAll { clean($0.group) == nil }
        // Removed groups are the empty ones; anything else still hangs from the root or a float.
        if let active = activeNode {
            var top = active
            while let parent = top.parent { top = parent }
            if active.panels.isEmpty || !(top === root || isFloating(top)) { activeNode = nil }
        }
    }

    /// Moves a registered panel (open or not) to `target` and rebuilds.
    private func move(_ id: String, to target: DockDropTarget, fraction: Float = 0.5) {
        var target = target
        if case .tab(let g, let index) = target, let from = g.panels.firstIndex(of: id) {
            target = .tab(g, index: from < index ? index - 1 : index)
        }
        detach(id)
        insert(id, at: target, fraction: fraction)
        normalize()
        rebuild()
        focusPanel(id)
    }

    // MARK: Widgets

    /// Recreates the split and tab widgets from the tree (panel contents are moved, not recreated).
    func rebuild() {
        let focused = context?.focusedWidget
        removeAllChildren()
        if let root { addChild(makeView(root)) }
        for f in floats { addChild(DockFloatingWindow(dock: self, state: f, group: makeView(f.group) as! TabView)) }
        if let focused, focused.isDescendant(of: self), let context, context.isFocusable(focused) { context.focus(focused) }
        setNeedsLayout()
    }

    private func minSize(_ node: DockNode, tabBar: Float) -> Vec2 {
        guard let axis = node.axis else {
            return node.panels.reduce(Vec2(0, tabBar)) { size, id in
                pointwiseMax(size, (panels[id]?.minSize ?? .zero) + Vec2(0, tabBar))
            }
        }
        let sizes = node.children.map { minSize($0, tabBar: tabBar) }
        let gaps = dividerThickness * Float(max(sizes.count - 1, 0))
        return axis == .horizontal
            ? Vec2(sizes.reduce(gaps) { $0 + $1.x }, sizes.map(\.y).max() ?? 0)
            : Vec2(sizes.map(\.x).max() ?? 0, sizes.reduce(gaps) { $0 + $1.y })
    }

    private func makeView(_ node: DockNode) -> Widget {
        if let axis = node.axis {
            let tabBar = tabBarHeight
            let mins = node.children.map { minSize($0, tabBar: tabBar) }.map { axis == .horizontal ? $0.x : $0.y }
            let split = SplitView(axis, panes: node.children.map(makeView), fractions: node.fractions, minSizes: mins,
                                  name: "dockSplit")
            split.dividerThickness = dividerThickness
            split.dividerColor = gapColor ?? theme.fieldBackground
            split.defaultFractions = SplitLayout.normalized([], count: node.children.count)
            split.onResize = { [weak self, weak node] fractions in
                node?.fractions = fractions
                self?.layoutChanged()
            }
            node.view = split
            return split
        }
        let selected = node.active.flatMap { node.panels.firstIndex(of: $0) } ?? 0
        let tabs = TabView(tabs: node.panels.compactMap { panels[$0] }, selectedIndex: selected, name: "dockGroup")
        tabs.dock = self
        tabs.tabBarHeight = tabBarHeight
        tabs.onSelect = { [weak self, weak node, weak tabs] index in
            guard let node, let tabs else { return }
            node.active = tabs.tabs[index].id
            self?.layoutChanged()
        }
        tabs.onReorder = { [weak self, weak node] order in
            node?.panels = order.map(\.id)
            self?.layoutChanged()
        }
        node.view = tabs
        return tabs
    }

    private var floatingWindows: [DockFloatingWindow] { children.compactMap { $0 as? DockFloatingWindow } }

    private func bringToFront(_ index: Int) {
        guard floats.indices.contains(index), index != floats.count - 1 else { return }
        let f = floats.remove(at: index)
        floats.append(f)
        if let window = floatingWindows.first(where: { $0.state === f }) { bringChildToFront(window) }
        layoutChanged()
    }

    /// A floating window's frame in window points: the stored frame, kept large enough and
    /// with its tab bar reachable inside the dock space.
    func windowFrame(for state: DockFloat) -> UIRect {
        let content = contentRect
        return clampedFloatingFrame(state.frame).offsetBy(Vec2(content.x, content.y))
    }

    /// A floating frame (relative to the dock space) at least `minFloatingSize`, with its tab bar
    /// inside; `fullyVisible` also keeps the whole window inside when it fits.
    func clampedFloatingFrame(_ frame: UIRect, fullyVisible: Bool = false) -> UIRect {
        let size = Vec2(contentRect.width, contentRect.height)
        var f = frame
        f.width = max(f.width, minFloatingSize.x)
        f.height = max(f.height, minFloatingSize.y)
        if fullyVisible {
            f.x = max(min(f.x, size.x - f.width), 0)
            f.y = max(min(f.y, size.y - f.height), 0)
        }
        f.x = min(max(f.x, 60 - f.width), size.x - 60)
        f.y = min(max(f.y, 0), size.y - 30)
        return f
    }

    func layoutChanged() {
        setNeedsDisplay()
        onLayoutChange?(layout)
    }

    public override func layoutChildren() {
        let content = contentRect
        for child in children {
            if let window = child as? DockFloatingWindow {
                window.layout(in: windowFrame(for: window.state))
            } else {
                child.layout(in: content)
            }
        }
    }

    public override func pointerWillPress(_ event: PointerEvent) {
        // Any press in a floating window brings it to the front; the group pressed becomes active.
        if let window = floatingWindows.last(where: { $0.frame.contains(event.position) }) {
            if let i = floats.firstIndex(where: { $0 === window.state }) { bringToFront(i) }
            activeNode = window.state.group
        } else if let group = dockedGroups.first(where: { $0.frame.contains(event.position) }) {
            activeNode = nodeFor(group)
        }
        setNeedsDisplay()
    }

    /// The docked tab views, in tree order.
    private var dockedGroups: [TabView] {
        var result: [TabView] = []
        func visit(_ node: DockNode) {
            if node.isGroup, let view = node.view as? TabView { result.append(view) }
            node.children.forEach(visit)
        }
        if let root { visit(root) }
        return result
    }

    private func nodeFor(_ view: TabView) -> DockNode? {
        func find(_ node: DockNode) -> DockNode? {
            if node.view === view { return node }
            for child in node.children { if let n = find(child) { return n } }
            return nil
        }
        return root.flatMap(find) ?? floats.first { $0.group.view === view }?.group
    }

    // MARK: Dragging tabs

    /// Whether a tab is being dragged over the dock space.
    public var isDraggingTab: Bool { tabDrag != nil }

    /// The area the dragged tab would occupy if dropped now (window points), for the highlight.
    public var dropPreview: UIRect? { tabDrag?.target.map(previewRect) }

    func beginTabDrag(_ panel: DockPanel, from view: TabView) {
        guard let source = nodeFor(view) else { return }
        tabDrag = (panel, source, nil)
        setNeedsDisplay()
    }

    func updateTabDrag(at point: Vec2) {
        guard tabDrag != nil else { return }
        let target = dropTarget(at: point)
        tabDrag?.target = target
        setNeedsDisplay()
    }

    func endTabDrag(at point: Vec2, commit: Bool) {
        guard let drag = tabDrag else { return }
        let target = commit ? dropTarget(at: point) : nil
        tabDrag = nil
        setNeedsDisplay()
        guard let target else { return }
        // A lone tab dragged out of a floating window just moves the window.
        if case .floating(let frame) = target, let f = floats.first(where: { $0.group === drag.source }),
           drag.source.panels == [drag.panel.id] {
            f.frame = frame
            setNeedsLayout()
            layoutChanged()
            return
        }
        let fraction: Float
        if case .edge = target { fraction = root == nil ? 1 : 0.25 } else { fraction = 0.5 }
        move(drag.panel.id, to: target, fraction: fraction)
        layoutChanged()
    }

    /// The drop target under `point` for the tab being dragged (nil: dropping changes nothing).
    func dropTarget(at point: Vec2) -> DockDropTarget? {
        guard let drag = tabDrag else { return nil }
        let content = contentRect
        let lone = drag.source.panels.count == 1
        func groupTarget(_ view: TabView, allowSplit: Bool) -> DockDropTarget? {
            guard let node = nodeFor(view) else { return nil }
            if node === drag.source && lone { return nil }
            if view.barRect.contains(point) { return .tab(node, index: view.insertionIndex(at: point.x)) }
            let r = view.contentArea
            guard allowSplit, r.width > 0, r.height > 0 else { return .tab(node, index: node.panels.count) }
            let nx = (point.x - r.x) / r.width, ny = (point.y - r.y) / r.height
            let edges: [(DockEdge, Float)] = [(.left, nx), (.right, 1 - nx), (.top, ny), (.bottom, 1 - ny)]
            let nearest = edges.min { $0.1 < $1.1 }!
            return nearest.1 < 0.25 ? .split(node, nearest.0) : .tab(node, index: node.panels.count)
        }
        if content.contains(point) {
            if let window = floatingWindows.last(where: { $0.frame.contains(point) }) {
                return groupTarget(window.group, allowSplit: false)
            }
            guard root != nil else { return .edge(.left) }
            // Tab bars first: the top row of bars lies inside the edge band.
            if let view = dockedGroups.first(where: { $0.barRect.contains(point) }) {
                return groupTarget(view, allowSplit: true)
            }
            let distances: [(DockEdge, Float)] = [(.left, point.x - content.x), (.right, content.maxX - point.x),
                                                  (.top, point.y - content.y), (.bottom, content.maxY - point.y)]
            let nearest = distances.min { $0.1 < $1.1 }!
            if nearest.1 < edgeDropBand { return .edge(nearest.0) }
            if let view = dockedGroups.first(where: { $0.frame.contains(point) }) {
                return groupTarget(view, allowSplit: true)
            }
        }
        // Anywhere else: a floating window under the pointer, sized like the group it came from.
        let sourceSize = drag.source.view.map { Vec2($0.frame.width, $0.frame.height) } ?? Vec2(300, 220)
        let size = pointwiseMin(pointwiseMax(sourceSize, minFloatingSize), Vec2(420, 320))
        let frame = UIRect(x: snap(point.x - 40 - content.x), y: snap(point.y - 14 - content.y), width: size.x, height: size.y)
        return .floating(clampedFloatingFrame(frame, fullyVisible: true))
    }

    private func previewRect(_ target: DockDropTarget) -> UIRect {
        let content = contentRect
        switch target {
        case .tab(let node, _):
            return node.view?.frame ?? .zero
        case .split(let node, let edge):
            let r = node.view?.frame ?? .zero
            switch edge {
            case .left: return UIRect(x: r.x, y: r.y, width: r.width / 2, height: r.height)
            case .right: return UIRect(x: r.x + r.width / 2, y: r.y, width: r.width / 2, height: r.height)
            case .top: return UIRect(x: r.x, y: r.y, width: r.width, height: r.height / 2)
            case .bottom: return UIRect(x: r.x, y: r.y + r.height / 2, width: r.width, height: r.height / 2)
            }
        case .edge(let edge):
            guard root != nil else { return content }
            let w = content.width / 4, h = content.height / 4
            switch edge {
            case .left: return UIRect(x: content.x, y: content.y, width: w, height: content.height)
            case .right: return UIRect(x: content.maxX - w, y: content.y, width: w, height: content.height)
            case .top: return UIRect(x: content.x, y: content.y, width: content.width, height: h)
            case .bottom: return UIRect(x: content.x, y: content.maxY - h, width: content.width, height: h)
            }
        case .floating(let frame):
            return frame.offsetBy(Vec2(content.x, content.y))
        }
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        guard let drag = tabDrag else { return }
        if let target = drag.target {
            let rect = snappedRect(previewRect(target)).inset(by: 2)
            list.fillRect(rect, color: theme.accent.withAlpha(0.22), radii: UICornerRadii(theme.smallCornerRadius))
            list.strokeRect(rect, color: theme.accent.withAlpha(0.85), width: 2, radii: UICornerRadii(theme.smallCornerRadius))
            // Where in the bar the tab goes.
            if case .tab(let node, let index) = target, let view = node.view as? TabView {
                let rects = view.tabRects
                let x = index < rects.count ? rects[index].x : (rects.last?.maxX ?? view.barRect.x)
                list.fillRect(UIRect(x: snap(x - 1), y: view.barRect.y + 3, width: 2, height: view.barRect.height - 6),
                              color: theme.accent)
            }
        }
        // The tab follows the pointer.
        guard let pointer = context?.pointerPosition else { return }
        let layout = cachedLayout(drag.panel.title, size: theme.fontSize)
        let width = (layout.width * scale).rounded(.up) / scale + 2 * theme.controlPaddingX
        let ghost = snappedRect(UIRect(x: pointer.x + 10, y: pointer.y + 8, width: width, height: theme.controlHeight))
        list.fillRect(ghost.offsetBy(Vec2(0, 2)), color: theme.shadow, radii: UICornerRadii(theme.cornerRadius))
        list.fillRect(ghost, color: theme.popupBackground, radii: UICornerRadii(theme.cornerRadius))
        list.strokeRect(ghost, color: theme.accent, width: theme.borderWidth, radii: UICornerRadii(theme.cornerRadius))
        drawLine(layout, font: theme.font, in: ghost, alignment: .center, color: theme.textColor, list: list)
    }
}

/// A floating window of a `DockSpace`: one tab group in a frame with a shadow. The empty part
/// of the tab bar moves it, edges and corners resize it.
final class DockFloatingWindow: Widget {
    unowned let dock: DockSpace
    let state: DockFloat
    let group: TabView
    /// Width of the resize band inside the border (points); it reaches as far outside.
    let resizeBand: Float = 5

    private struct Edges: OptionSet {
        let rawValue: UInt8
        static let left = Edges(rawValue: 1), right = Edges(rawValue: 2), top = Edges(rawValue: 4), bottom = Edges(rawValue: 8)
    }
    private enum Action {
        case move(grab: Vec2)
        case resize(Edges, start: Vec2, frame: UIRect)
    }
    private var action: Action?

    init(dock: DockSpace, state: DockFloat, group: TabView) {
        self.dock = dock
        self.state = state
        self.group = group
        super.init(name: "dockFloating")
        padding = EdgeInsets(1)
        addChild(group)
    }

    private func edges(at point: Vec2) -> Edges {
        let outer = frame.inset(by: -resizeBand)
        guard outer.contains(point), !frame.inset(by: resizeBand).contains(point) else { return [] }
        var e: Edges = []
        if point.x < frame.x + resizeBand { e.insert(.left) } else if point.x >= frame.maxX - resizeBand { e.insert(.right) }
        if point.y < frame.y + resizeBand { e.insert(.top) } else if point.y >= frame.maxY - resizeBand { e.insert(.bottom) }
        return e
    }

    private static func cursor(for edges: Edges) -> UICursor? {
        switch edges {
        case [.left, .top], [.right, .bottom]: return .resizeDiagonal
        case [.right, .top], [.left, .bottom]: return .resizeAntiDiagonal
        case .left, .right: return .resizeLeftRight
        case .top, .bottom: return .resizeUpDown
        default: return nil
        }
    }

    override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden else { return nil }
        if !edges(at: point).isEmpty { return self }
        return super.hitTest(point)
    }

    override func cursor(at point: Vec2) -> UICursor? {
        switch action {
        case .move: return .move
        case .resize(let e, _, _): return Self.cursor(for: e)
        case nil: return Self.cursor(for: edges(at: point))
        }
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            let grabbed = edges(at: e.position)
            if !grabbed.isEmpty {
                action = .resize(grabbed, start: e.position, frame: state.frame)
                return true
            }
            if group.barRect.contains(e.position) {
                action = .move(grab: e.position - Vec2(frame.x, frame.y))
                return true
            }
            return false
        case .pointerDrag(let e):
            guard let action else { return false }
            let content = dock.contentRect
            switch action {
            case .move(let grab):
                let origin = e.position - grab - Vec2(content.x, content.y)
                state.frame = dock.clampedFloatingFrame(UIRect(x: snap(origin.x), y: snap(origin.y), width: state.frame.width,
                                                               height: state.frame.height))
            case .resize(let edges, let start, let initial):
                let d = e.position - start
                var f = initial
                let minSize = dock.minFloatingSize
                if edges.contains(.left) {
                    let x = min(initial.x + d.x, initial.maxX - minSize.x)
                    f.width = initial.maxX - x
                    f.x = x
                }
                if edges.contains(.right) { f.width = max(initial.width + d.x, minSize.x) }
                if edges.contains(.top) {
                    let y = min(initial.y + d.y, initial.maxY - minSize.y)
                    f.height = initial.maxY - y
                    f.y = y
                }
                if edges.contains(.bottom) { f.height = max(initial.height + d.y, minSize.y) }
                state.frame = UIRect(x: snap(f.x), y: snap(f.y), width: snap(f.width), height: snap(f.height))
            }
            dock.setNeedsLayout()
            return true
        case .pointerUp:
            guard action != nil else { return false }
            action = nil
            dock.layoutChanged()
            return true
        default:
            return false
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.popupCornerRadius)
        for i in 1...3 {
            let grow = Float(i) * 3
            list.fillRect(UIRect(x: frame.x - grow / 2, y: frame.y + grow, width: frame.width + grow, height: frame.height),
                          color: theme.shadow.withAlpha(theme.shadow.a / 3), radii: UICornerRadii(theme.popupCornerRadius - 1 + grow))
        }
        list.fillRect(frame, color: theme.panelBackground, radii: radii)
    }

    override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        list.strokeRect(frame, color: theme.popupBorder, width: theme.borderWidth, radii: UICornerRadii(theme.popupCornerRadius))
    }
}
