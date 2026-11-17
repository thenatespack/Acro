import EditorCore
import Engine
import Foundation

/// The Dialogue tab's graph: one box per node at its `position`, arrows for its links.
///
/// - Click a node to select it; drag it to move it (one undo step when released).
/// - Drag from a node's right-hand port (the dot) onto another node to link them (`onConnect`).
/// - Drag empty space or scroll to pan.
@MainActor
public final class DialogueGraphView: Widget {
    public var dialogue = DialogueAsset() { didSet { setNeedsDisplay() } }
    public var selected: String? { didSet { setNeedsDisplay() } }
    /// The node the preview is at (highlighted).
    public var current: String? { didSet { setNeedsDisplay() } }
    /// Graph point at the view's top-left.
    public var pan = Vec2(-40, -40) { didSet { setNeedsDisplay() } }
    public var onSelect: ((String?) -> Void)?
    /// A node was dragged to a new position (graph points).
    public var onMove: ((String, Vec2) -> Void)?
    /// A link was dragged from the first node onto the second.
    public var onConnect: ((String, String) -> Void)?

    public static let nodeSize = Vec2(200, 74)
    private static let portRadius: Float = 6

    private enum Drag {
        case node(id: String, grab: Vec2, at: Vec2)
        case link(from: String, to: Vec2)
        case pan(start: Vec2, startPan: Vec2)
    }
    private var drag: Drag?

    public override init(name: String = "dialogueGraph") {
        super.init(name: name)
        clipsContent = true
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(400, 300) }

    // MARK: Geometry

    func origin(of node: DialogueNode) -> Vec2 {
        if case .node(let id, _, let at)? = drag, id == node.id { return at }
        return node.position ?? .zero
    }

    /// The node's box in window points.
    func rect(of node: DialogueNode) -> UIRect {
        let p = origin(of: node) - pan + Vec2(frame.x, frame.y)
        return UIRect(x: p.x, y: p.y, width: Self.nodeSize.x, height: Self.nodeSize.y)
    }

    func port(of node: DialogueNode) -> Vec2 {
        let r = rect(of: node)
        return Vec2(r.maxX, r.y + r.height / 2)
    }

    /// The node under a window point (topmost: last in the file).
    public func node(at point: Vec2) -> DialogueNode? {
        dialogue.nodes.last { rect(of: $0).contains(point) }
    }

    /// Pans so `id` is in view.
    public func reveal(_ id: String) {
        guard let node = dialogue.node(id), frame.width > 0 else { return }
        let p = origin(of: node)
        if p.x < pan.x || p.y < pan.y || p.x + Self.nodeSize.x > pan.x + frame.width || p.y + Self.nodeSize.y > pan.y + frame.height {
            pan = p - Vec2(max(frame.width - Self.nodeSize.x, 0) / 2, max(frame.height - Self.nodeSize.y, 0) / 2)
        }
    }

    /// Pans so the whole graph's top-left is in view.
    public func frameAll() {
        let xs = dialogue.nodes.map { origin(of: $0).x }, ys = dialogue.nodes.map { origin(of: $0).y }
        pan = Vec2((xs.min() ?? 0) - 40, (ys.min() ?? 0) - 40)
    }

    // MARK: Input

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let p):
            if let node = dialogue.nodes.last(where: { distance(port(of: $0), p.position) <= Self.portRadius + 4 }), node.type != .end {
                drag = .link(from: node.id, to: p.position)
                return true
            }
            if let node = node(at: p.position) {
                selected = node.id
                onSelect?(node.id)
                drag = .node(id: node.id, grab: p.position - Vec2(rect(of: node).x, rect(of: node).y), at: origin(of: node))
            } else {
                drag = .pan(start: p.position, startPan: pan)
            }
            return true
        case .pointerDrag(let p):
            switch drag {
            case .node(let id, let grab, _)?:
                drag = .node(id: id, grab: grab, at: p.position - grab - Vec2(frame.x, frame.y) + pan)
            case .link(let from, _)?:
                drag = .link(from: from, to: p.position)
            case .pan(let start, let startPan)?:
                pan = startPan - (p.position - start)
            case nil:
                break
            }
            setNeedsDisplay()
            return true
        case .pointerUp(let p):
            defer { drag = nil; setNeedsDisplay() }
            switch drag {
            case .node(let id, _, let at)?:
                if let node = dialogue.node(id), at != (node.position ?? .zero) {
                    let snapped = Vec2((at.x / 10).rounded() * 10, (at.y / 10).rounded() * 10)
                    // Keep showing it where it was dropped until the file catches up.
                    if let i = dialogue.nodeIndex(id) { dialogue.nodes[i].position = snapped }
                    onMove?(id, snapped)
                }
            case .link(let from, _)?:
                if let target = node(at: p.position), target.id != from { onConnect?(from, target.id) }
            case .pan(let start, _)?:
                if distance(start, p.position) < 3 {
                    selected = nil
                    onSelect?(nil)
                }
            case nil:
                break
            }
            return true
        case .scroll(let delta, _):
            pan -= delta
            return true
        default:
            return false
        }
    }

    public override func cursor(at point: Vec2) -> UICursor? {
        if dialogue.nodes.contains(where: { distance(port(of: $0), point) <= Self.portRadius + 4 && $0.type != .end }) { return .pointingHand }
        return nil
    }

    public override func tooltip(at point: Vec2) -> String? {
        guard let node = node(at: point) else { return "Drag to pan; drag from a node's dot onto another node to link them" }
        var text = "\(node.id) (\(node.type.rawValue)): \(node.summary)"
        if !node.comment.isEmpty { text += "\n\(node.comment)" }
        return text
    }

    private func distance(_ a: Vec2, _ b: Vec2) -> Float { let d = a - b; return (d.x * d.x + d.y * d.y).squareRoot() }

    // MARK: Drawing

    static func color(_ type: DialogueNodeType) -> UIColor {
        switch type {
        case .line: return UIColor(hex: 0x3b82c4)
        case .choice: return UIColor(hex: 0xc48a2b)
        case .condition: return UIColor(hex: 0x8a5cc4)
        case .set: return UIColor(hex: 0x3a9a63)
        case .event: return UIColor(hex: 0xc4513b)
        case .end: return UIColor(hex: 0x6b7280)
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: UIColor(0.075, 0.085, 0.105, 1))
        list.withClip(frame) {
            drawGrid(list)
            for node in dialogue.nodes { drawLinks(of: node, list: list, theme: theme) }
            if case .link(let from, let to)? = drag, let node = dialogue.node(from) {
                list.drawLine(from: port(of: node), to: to, width: 2, color: theme.accent, cap: .round)
            }
            for node in dialogue.nodes { drawNode(node, list: list, theme: theme) }
            if dialogue.nodes.isEmpty {
                list.drawText("No nodes yet: add one with the toolbar buttons.", at: Vec2(frame.x + 16, frame.y + 16), size: 12,
                              color: theme.secondaryTextColor)
            }
        }
    }

    private func drawGrid(_ list: UIDrawList) {
        let step: Float = 40
        let color = UIColor(1, 1, 1, 0.04)
        var x = frame.x - pan.x.truncatingRemainder(dividingBy: step)
        if x > frame.x { x -= step }
        while x < frame.maxX { list.drawLine(from: Vec2(x, frame.y), to: Vec2(x, frame.maxY), color: color); x += step }
        var y = frame.y - pan.y.truncatingRemainder(dividingBy: step)
        if y > frame.y { y -= step }
        while y < frame.maxY { list.drawLine(from: Vec2(frame.x, y), to: Vec2(frame.maxX, y), color: color); y += step }
    }

    private func drawLinks(of node: DialogueNode, list: UIDrawList, theme: UITheme) {
        let links = node.links
        let from = rect(of: node)
        for (k, link) in links.enumerated() {
            guard let target = dialogue.node(link.target) else { continue }
            let t = rect(of: target)
            let start = Vec2(from.maxX, from.y + from.height * Float(k + 1) / Float(links.count + 1))
            let end = Vec2(t.x, t.y + t.height / 2)
            let color: UIColor = link.label == "else" ? UIColor(hex: 0xc4513b) : link.label.hasPrefix("choice") ? UIColor(hex: 0xc48a2b) : UIColor(0.75, 0.78, 0.85, 1)
            // An S-curve of a few segments.
            let mid = max(abs(end.x - start.x) / 2, 30)
            var last = start
            for i in 1...12 {
                let s = Float(i) / 12
                let a = start, b = start + Vec2(mid, 0), c = end - Vec2(mid, 0), d = end
                let u = 1 - s
                let p = a * (u * u * u) + b * (3 * u * u * s) + c * (3 * u * s * s) + d * (s * s * s)
                list.drawLine(from: last, to: p, width: 1.5, color: color.withAlpha(0.85), cap: .round)
                last = p
            }
            list.fillRect(UIRect(x: end.x - 4, y: end.y - 4, width: 8, height: 8), color: color, radii: UICornerRadii(4))
            if link.label != "next" {
                let label = link.label.hasPrefix("choice ") ? String(link.label.dropFirst(7)) : link.label
                list.drawText(label, at: start + Vec2(6, -14), size: 10, color: color)
            }
        }
    }

    private func drawNode(_ node: DialogueNode, list: UIDrawList, theme: UITheme) {
        let r = rect(of: node)
        guard r.intersects(frame) else { return }
        let accent = Self.color(node.type)
        let radii = UICornerRadii(6)
        list.fillRect(r, color: UIColor(0.13, 0.145, 0.18, 0.97), radii: radii)
        list.fillRect(UIRect(x: r.x, y: r.y, width: r.width, height: 20), color: accent.withAlpha(0.9),
                      radii: UICornerRadii(topLeft: 6, topRight: 6, bottomRight: 0, bottomLeft: 0))
        var title = node.id.isEmpty ? "(no id)" : node.id
        if node.id == dialogue.startNode { title = "▶ " + title }
        list.drawText(title, at: Vec2(r.x + 8, r.y + 3), size: 11, color: .white, maxWidth: r.width - 60)
        list.drawText(node.type.rawValue, at: Vec2(r.maxX - 56, r.y + 4), size: 10, color: UIColor(1, 1, 1, 0.75), maxWidth: 50,
                      alignment: .right)
        var body = node.summary
        if (node.type == .line || node.type == .choice), !node.speaker.isEmpty {
            body = "\(dialogue.speaker(node.speaker)?.displayName ?? node.speaker): " + body
        }
        if body.count > 90 { body = String(body.prefix(88)) + "…" }
        list.withClip(UIRect(x: r.x + 6, y: r.y + 22, width: r.width - 12, height: r.height - 26)) {
            list.drawText(body, at: Vec2(r.x + 8, r.y + 25), size: 11, color: theme.textColor, maxWidth: r.width - 16)
        }
        if node.id == current {
            list.strokeRect(r.inset(by: -3), color: UIColor(hex: 0x4ade80), width: 2, radii: UICornerRadii(8))
        }
        if node.id == selected {
            list.strokeRect(r, color: theme.accent, width: 2, radii: radii)
        } else {
            list.strokeRect(r, color: UIColor(1, 1, 1, 0.12), width: 1, radii: radii)
        }
        if node.type != .end {
            let p = port(of: node)
            list.fillRect(UIRect(x: p.x - Self.portRadius, y: p.y - Self.portRadius, width: Self.portRadius * 2, height: Self.portRadius * 2),
                          color: accent, radii: UICornerRadii(Self.portRadius))
        }
    }
}
