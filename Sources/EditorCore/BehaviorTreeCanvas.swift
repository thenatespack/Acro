import Engine
import Foundation

/// Where a node dragged on the Behavior Tree canvas lands.
public enum BehaviorDropTarget: Equatable, Sendable {
    /// The last child of this composite or decorator.
    case child(of: String)
    /// Just before this node among its parent's children.
    case before(String)
    /// Just after this node among its parent's children.
    case after(String)
}

/// The node boxes of a behavior tree laid out top-down: parents centered over their children,
/// siblings left to right in run order. Nodes not reached from the root are laid out as
/// their own little trees to the right.
public struct BehaviorTreeLayout: Equatable, Sendable {
    /// Each node's box top-left, in graph points.
    public var positions: [String: Vec2] = [:]
    /// Parent → child links in draw order (each node drawn under one parent).
    public var edges: [(parent: String, child: String)] = []
    /// Nodes not under the root.
    public var loose: Set<String> = []
    /// Where the loose nodes start (graph x), nil when there are none.
    public var looseStartX: Float?

    public static let nodeSize = Vec2(164, 52)
    public static let columnWidth: Float = 182
    public static let rowHeight: Float = 96

    public static func == (a: Self, b: Self) -> Bool {
        a.positions == b.positions && a.loose == b.loose && a.looseStartX == b.looseStartX
            && a.edges.map { $0.parent + ">" + $0.child } == b.edges.map { $0.parent + ">" + $0.child }
    }

    public init() {}

    public init(_ tree: BehaviorTree) {
        var placed = Set<String>()
        var slot: Float = 0
        func place(_ id: String, depth: Int) -> Float? {
            guard let node = tree.node(id), placed.insert(id).inserted else { return nil }
            let kids = (node.kind?.isLeaf ?? false) ? [] : node.children
            var xs: [Float] = []
            for child in kids {
                if let x = place(child, depth: depth + 1) {
                    xs.append(x)
                    edges.append((id, child))
                }
            }
            let x: Float
            if let first = xs.first, let last = xs.last { x = (first + last) / 2 } else { x = slot; slot += 1 }
            positions[id] = Vec2(x * Self.columnWidth, Float(depth) * Self.rowHeight)
            return x
        }
        if let root = tree.rootID { _ = place(root, depth: 0) }
        let rest = tree.nodes.map(\.id).filter { !placed.contains($0) }
        guard !rest.isEmpty else { return }
        slot += placed.isEmpty ? 0 : 0.6
        looseStartX = slot * Self.columnWidth
        // Start each loose tree at a node no other loose node lists as a child.
        let restSet = Set(rest)
        let looseChildren = Set(tree.nodes.filter { restSet.contains($0.id) }.flatMap(\.children))
        for id in rest where !looseChildren.contains(id) { _ = place(id, depth: 0) }
        for id in rest where !placed.contains(id) { _ = place(id, depth: 0) }  // cycles among loose nodes
        loose = restSet
    }

    /// The box around every node (graph points), nil for an empty tree.
    public var bounds: UIRect? {
        guard !positions.isEmpty else { return nil }
        let xs = positions.values.map(\.x), ys = positions.values.map(\.y)
        let minX = xs.min()!, minY = ys.min()!
        return UIRect(x: minX, y: minY, width: xs.max()! - minX + Self.nodeSize.x, height: ys.max()! - minY + Self.nodeSize.y)
    }
}

/// The Behavior Tree tab's canvas: the tree drawn as connected boxes from the root down.
///
/// - Click a node to select it; drag empty space or scroll to pan; the toolbar zooms.
/// - Drag a node (with everything under it) onto a composite or decorator to make it that
///   node's last child, or onto the left / right part of any node to put it just before /
///   after that node among its siblings. Dropping on empty space cancels.
/// - While playing, each box is tinted with what the node returned on the last tick
///   (`statuses`: running yellow, success green, failure red).
@MainActor
public final class BehaviorTreeCanvas: Widget {
    public var tree = BehaviorTree() {
        didSet {
            guard tree != oldValue else { return }
            layout = BehaviorTreeLayout(tree)
            setNeedsDisplay()
        }
    }
    public private(set) var layout = BehaviorTreeLayout()
    public var selected: String? { didSet { setNeedsDisplay() } }
    /// The debugged entity's last statuses by node id.
    public var statuses: [String: BehaviorStatus] = [:] { didSet { if statuses != oldValue { setNeedsDisplay() } } }
    /// Nodes `BehaviorTree.validate` complains about (marked with a red corner).
    public var problemNodes: Set<String> = [] { didSet { setNeedsDisplay() } }
    /// Graph point at the view's top-left.
    public var pan = Vec2(-30, -30) { didSet { setNeedsDisplay() } }
    public var zoom: Float = 1 { didSet { zoom = max(0.3, min(zoom, 2)); setNeedsDisplay() } }
    public var onSelect: ((String?) -> Void)?
    /// A node was dragged and dropped on a valid target.
    public var onDrop: ((String, BehaviorDropTarget) -> Void)?

    private enum Drag {
        case pending(id: String, start: Vec2)
        case node(id: String, at: Vec2, grab: Vec2)
        case pan(start: Vec2, startPan: Vec2)
    }
    private var drag: Drag?

    public override init(name: String = "behaviorCanvas") {
        super.init(name: name)
        clipsContent = true
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(400, 300) }

    // MARK: Geometry

    /// A graph point in window points.
    func toView(_ p: Vec2) -> Vec2 { (p - pan) * zoom + Vec2(frame.x, frame.y) }
    /// A window point in graph points.
    func toGraph(_ p: Vec2) -> Vec2 { (p - Vec2(frame.x, frame.y)) / zoom + pan }

    /// The node's box in window points (nil when it isn't laid out).
    public func rect(of id: String) -> UIRect? {
        guard let p = layout.positions[id] else { return nil }
        let v = toView(p)
        return UIRect(x: v.x, y: v.y, width: BehaviorTreeLayout.nodeSize.x * zoom, height: BehaviorTreeLayout.nodeSize.y * zoom)
    }

    /// The node under a window point.
    public func node(at point: Vec2) -> String? {
        tree.nodes.last { rect(of: $0.id)?.contains(point) == true }?.id
    }

    /// Pans (and zooms out if needed) so the whole tree is in view.
    public func frameAll() {
        guard let b = layout.bounds else { pan = Vec2(-30, -30); return }
        if frame.width > 0, frame.height > 0 {
            zoom = min(1, (frame.width - 40) / b.width, (frame.height - 40) / b.height)
            pan = Vec2(b.x + b.width / 2 - frame.width / zoom / 2, b.y - 20 / zoom)
            if b.width * zoom < frame.width - 40 { pan.x = b.x + b.width / 2 - frame.width / zoom / 2 }
        } else {
            pan = Vec2(b.x - 30, b.y - 30)
        }
    }

    /// Set to frame the tree (`frameStart`) at the next layout, once the canvas has a size.
    public var framesAtNextLayout = false

    public override func layoutChildren() {
        super.layoutChildren()
        if framesAtNextLayout, frame.width > 0, frame.height > 0 {
            framesAtNextLayout = false
            frameStart()
        }
    }

    /// How a tree opens: the whole tree when it fits at a readable zoom, else the root at the
    /// top middle at that zoom.
    public func frameStart() {
        guard let b = layout.bounds, frame.width > 0, frame.height > 0 else { frameAll(); return }
        zoom = max(0.75, min(1, (frame.width - 40) / b.width, (frame.height - 40) / b.height))
        let centerX = b.width * zoom <= frame.width - 40 ? b.x + b.width / 2
            : (layout.positions[tree.rootID ?? ""]?.x ?? b.x) + BehaviorTreeLayout.nodeSize.x / 2
        pan = Vec2(centerX - frame.width / zoom / 2, b.y - 20 / zoom)
    }

    /// Pans so `id` is in view.
    public func reveal(_ id: String) {
        guard let r = rect(of: id), frame.width > 0 else { return }
        if r.x < frame.x || r.y < frame.y || r.maxX > frame.maxX || r.maxY > frame.maxY {
            let p = layout.positions[id]!
            pan = p + BehaviorTreeLayout.nodeSize / 2 - Vec2(frame.width, frame.height) / zoom / 2
        }
    }

    /// Where dropping `dragged` at window point `point` would put it (nil: nowhere valid).
    public func dropTarget(for dragged: String, at point: Vec2) -> BehaviorDropTarget? {
        guard let id = node(at: point), let r = rect(of: id) else { return nil }
        let moving = tree.subtree(dragged)
        guard !moving.contains(id), let node = tree.node(id) else { return nil }
        let fraction = (point.x - r.x) / max(r.width, 1)
        let hasParent = tree.parent(of: id) != nil
        let canHold: Bool = {
            guard let kind = node.kind, !kind.isLeaf else { return false }
            if kind.category == .decorator { return node.children.isEmpty || node.children == [dragged] }
            return true
        }()
        if hasParent, fraction < (canHold ? 0.25 : 0.5) { return .before(id) }
        if hasParent, fraction > (canHold ? 0.75 : 0.5) { return .after(id) }
        return canHold ? .child(of: id) : nil
    }

    // MARK: Input

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let p):
            if let id = node(at: p.position) {
                selected = id
                onSelect?(id)
                drag = .pending(id: id, start: p.position)
            } else {
                drag = .pan(start: p.position, startPan: pan)
            }
            return true
        case .pointerDrag(let p):
            switch drag {
            case .pending(let id, let start)?:
                let d = p.position - start
                if (d.x * d.x + d.y * d.y).squareRoot() > 4, let r = rect(of: id) {
                    drag = .node(id: id, at: p.position, grab: start - Vec2(r.x, r.y))
                }
            case .node(let id, _, let grab)?:
                drag = .node(id: id, at: p.position, grab: grab)
            case .pan(let start, let startPan)?:
                pan = startPan - (p.position - start) / zoom
            case nil:
                break
            }
            setNeedsDisplay()
            return true
        case .pointerUp(let p):
            defer { drag = nil; setNeedsDisplay() }
            switch drag {
            case .node(let id, _, _)?:
                if let target = dropTarget(for: id, at: p.position) { onDrop?(id, target) }
            case .pan(let start, _)?:
                let d = p.position - start
                if (d.x * d.x + d.y * d.y).squareRoot() < 3 {
                    selected = nil
                    onSelect?(nil)
                }
            default:
                break
            }
            return true
        case .scroll(let delta, _):
            pan -= delta / zoom
            return true
        default:
            return false
        }
    }

    public override func cursor(at point: Vec2) -> UICursor? {
        node(at: point) != nil ? .pointingHand : nil
    }

    public override func tooltip(at point: Vec2) -> String? {
        guard let id = node(at: point), let node = tree.node(id) else {
            return "Drag a node onto a composite to make it a child, or onto a node's left / right edge to reorder; drag empty space to pan"
        }
        var text = "\(id) (\(node.type))"
        if let doc = node.kind?.doc { text += "\n\(doc)" }
        if let status = statuses[id] { text += "\nLast tick: \(status.rawValue)" }
        return text
    }

    // MARK: Drawing

    static func color(_ category: BehaviorNodeCategory?) -> UIColor {
        switch category {
        case .composite?: UIColor(hex: 0x3b82c4)
        case .decorator?: UIColor(hex: 0x8a5cc4)
        case .condition?: UIColor(hex: 0x2f9e8f)
        case .action?: UIColor(hex: 0xc4802b)
        case nil: UIColor(hex: 0x6b7280)
        }
    }

    static func statusColor(_ status: BehaviorStatus) -> UIColor {
        switch status {
        case .running: UIColor(hex: 0xf2c033)
        case .success: UIColor(hex: 0x4cc46a)
        case .failure: UIColor(hex: 0xe5534b)
        }
    }

    /// A short line under the title: the type and the parameters set on the node.
    static func summary(_ node: BehaviorNode) -> String {
        var parts: [String] = [node.type]
        for key in node.params.keys.sorted() where key != "leaf" || node.kind != .custom {
            let value = node.params[key]!
            let text: String
            if case .array(let items) = value, BehaviorJSON.vector(value) == nil { text = "\(items.count) pts" }
            else { text = BehaviorJSON.text(value) }
            parts.append("\(key) \(text)")
        }
        if node.kind == .custom { parts[0] = "custom " + node.string("leaf") }
        return parts.joined(separator: " · ")
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: UIColor(0.075, 0.085, 0.105, 1))
        list.withClip(frame) {
            drawGrid(list)
            var moving: Set<String> = []
            var target: BehaviorDropTarget?
            if case .node(let id, let at, _)? = drag {
                moving = tree.subtree(id)
                target = dropTarget(for: id, at: at)
            }
            if let x = layout.looseStartX {
                let v = toView(Vec2(x - 14, -40))
                list.drawLine(from: Vec2(v.x, frame.y), to: Vec2(v.x, frame.maxY), width: 1, color: UIColor(1, 1, 1, 0.12))
                list.drawText("Not connected to the root", at: Vec2(v.x + 8, max(frame.y + 6, v.y)), size: 11, color: theme.secondaryTextColor)
            }
            // Running links last, so the running path stays on top where links share a line.
            let edges = layout.edges.filter { statuses[$0.child] != .running } + layout.edges.filter { statuses[$0.child] == .running }
            for edge in edges { drawEdge(edge.parent, edge.child, faded: moving.contains(edge.child), list: list) }
            for node in tree.nodes where layout.positions[node.id] != nil {
                drawNode(node, list: list, theme: theme, faded: moving.contains(node.id))
            }
            if let target { drawTarget(target, list: list, theme: theme) }
            if case .node(let id, let at, let grab)? = drag, let node = tree.node(id) {
                let size = BehaviorTreeLayout.nodeSize * zoom
                let ghost = UIRect(x: at.x - grab.x, y: at.y - grab.y, width: size.x, height: size.y)
                list.withOpacity(0.85) { drawBox(node, in: ghost, list: list, theme: theme) }
                if target == nil {
                    list.strokeRect(ghost, color: UIColor(hex: 0xe5534b), width: 2, radii: UICornerRadii(6 * zoom))
                }
            }
            if tree.nodes.isEmpty {
                list.drawText("The tree is empty: add a node in the sidebar or pick a preset.", at: Vec2(frame.x + 16, frame.y + 16), size: 12,
                              color: theme.secondaryTextColor)
            }
        }
    }

    private func drawGrid(_ list: UIDrawList) {
        let step: Float = 40 * zoom
        let color = UIColor(1, 1, 1, 0.04)
        let origin = toView(.zero)
        var x = frame.x + (origin.x - frame.x).truncatingRemainder(dividingBy: step)
        if x > frame.x { x -= step }
        while x < frame.maxX { list.drawLine(from: Vec2(x, frame.y), to: Vec2(x, frame.maxY), color: color); x += step }
        var y = frame.y + (origin.y - frame.y).truncatingRemainder(dividingBy: step)
        if y > frame.y { y -= step }
        while y < frame.maxY { list.drawLine(from: Vec2(frame.x, y), to: Vec2(frame.maxX, y), color: color); y += step }
    }

    private func drawEdge(_ parent: String, _ child: String, faded: Bool, list: UIDrawList) {
        guard let a = rect(of: parent), let b = rect(of: child) else { return }
        let start = Vec2(a.x + a.width / 2, a.maxY)
        let end = Vec2(b.x + b.width / 2, b.y)
        let midY = (start.y + end.y) / 2
        var color = UIColor(0.62, 0.66, 0.74, faded ? 0.25 : 0.8)
        if !faded, let status = statuses[child] { color = Self.statusColor(status).withAlpha(status == .running ? 0.95 : 0.6) }
        let width: Float = statuses[child] == .running && !faded ? 2.5 : 1.5
        list.drawLine(from: start, to: Vec2(start.x, midY), width: width, color: color, cap: .round)
        list.drawLine(from: Vec2(start.x, midY), to: Vec2(end.x, midY), width: width, color: color, cap: .round)
        list.drawLine(from: Vec2(end.x, midY), to: end, width: width, color: color, cap: .round)
    }

    private func drawNode(_ node: BehaviorNode, list: UIDrawList, theme: UITheme, faded: Bool) {
        guard let r = rect(of: node.id), r.intersects(frame) else { return }
        if faded {
            list.withOpacity(0.3) { drawBox(node, in: r, list: list, theme: theme) }
        } else {
            drawBox(node, in: r, list: list, theme: theme)
        }
    }

    private func drawBox(_ node: BehaviorNode, in r: UIRect, list: UIDrawList, theme: UITheme) {
        let z = zoom
        let radii = UICornerRadii(6 * z)
        let accent = Self.color(node.kind?.category)
        let status = statuses[node.id]
        list.fillRect(r, color: UIColor(0.13, 0.145, 0.18, 0.97), radii: radii)
        if let status { list.fillRect(r, color: Self.statusColor(status).withAlpha(status == .running ? 0.30 : 0.22), radii: radii) }
        list.fillRect(UIRect(x: r.x, y: r.y, width: 5 * z, height: r.height), color: accent,
                      radii: UICornerRadii(topLeft: 6 * z, topRight: 0, bottomRight: 0, bottomLeft: 6 * z))
        var title = node.title
        if node.id == tree.rootID { title = "▶ " + title }
        list.drawText(title, at: Vec2(r.x + 12 * z, r.y + 7 * z), size: 12 * z, color: theme.textColor, maxWidth: r.width - 20 * z)
        list.withClip(UIRect(x: r.x + 10 * z, y: r.y + 24 * z, width: r.width - 18 * z, height: r.height - 26 * z)) {
            list.drawText(Self.summary(node), at: Vec2(r.x + 12 * z, r.y + 28 * z), size: 10 * z, color: accent.mixed(with: .white, 0.35))
        }
        if let status {
            let label = status.rawValue
            list.drawText(label, at: Vec2(r.maxX - 66 * z, r.maxY + 3 * z), size: 9 * z, color: Self.statusColor(status), maxWidth: 62 * z,
                          alignment: .right)
        }
        if problemNodes.contains(node.id) {
            let s = 8 * z
            list.fillRect(UIRect(x: r.maxX - s - 4 * z, y: r.y + 4 * z, width: s, height: s), color: UIColor(hex: 0xe5534b), radii: UICornerRadii(s / 2))
        }
        if node.id == selected {
            list.strokeRect(r, color: theme.accent, width: 2, radii: radii)
        } else if let status {
            list.strokeRect(r, color: Self.statusColor(status).withAlpha(0.8), width: status == .running ? 2 : 1, radii: radii)
        } else {
            list.strokeRect(r, color: UIColor(1, 1, 1, 0.12), width: 1, radii: radii)
        }
    }

    private func drawTarget(_ target: BehaviorDropTarget, list: UIDrawList, theme: UITheme) {
        let good = UIColor(hex: 0x4ade80)
        switch target {
        case .child(let id):
            guard let r = rect(of: id) else { return }
            list.strokeRect(r.inset(by: -3), color: good, width: 2, radii: UICornerRadii(8 * zoom))
            let p = Vec2(r.x + r.width / 2, r.maxY + 4)
            list.drawLine(from: p, to: p + Vec2(0, 14 * zoom), width: 2, color: good, cap: .round)
        case .before(let id), .after(let id):
            guard let r = rect(of: id) else { return }
            let isBefore = { if case .before = target { return true } else { return false } }()
            let x = isBefore ? r.x - 6 * zoom : r.maxX + 6 * zoom
            list.drawLine(from: Vec2(x, r.y - 4), to: Vec2(x, r.maxY + 4), width: 3, color: good, cap: .round)
        }
    }
}
