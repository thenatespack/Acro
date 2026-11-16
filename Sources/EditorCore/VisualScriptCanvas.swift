import Engine
import Foundation

/// One node as the canvas draws it.
struct VisualScriptCanvasNode {
    var id: String
    var title: String
    var kind: VisualScriptNodeKind
    var known: Bool
    var position: Vec2
    var size: Vec2
    var inputs: [VisualScriptPin]
    var outputs: [VisualScriptPin]
    /// Literal text shown beside unconnected inputs, by pin name.
    var literals: [String: String]
    var breakpoint: Bool
    var collapsed: Bool
    var comment: String?
    var doc: String
    /// A reroute point: a small pill with one pin each side, no title.
    var isReroute = false
}

/// The node graph view of the Visual Script tab: nodes, wires, comments and live flow, with
/// dragging to move nodes and to draw wires, panning (right / middle drag or drag on empty
/// space) and zooming (scroll). It holds no graph state of its own: the workspace hands it
/// what to draw and turns its callbacks into file edits.
@MainActor
final class VisualScriptCanvas: Widget {
    static let headerHeight: Float = 24
    static let rowHeight: Float = 20

    var nodes: [VisualScriptCanvasNode] = [] { didSet { index = Dictionary(nodes.indices.map { (nodes[$0].id, $0) }, uniquingKeysWith: { a, _ in a }) } }
    var links: [VisualScriptLink] = []
    var comments: [VisualScriptComment] = []
    var issues: [String: [VisualScriptIssue]] = [:]
    var selection: Set<String> = []
    /// Node id → seconds since it last ran (play mode), for the flow highlight.
    var activity: [String: Double] = [:]
    /// Live output values by "node.pin" (play mode).
    var values: [String: String] = [:]
    /// The node play is paused at while stepping after a breakpoint (outlined in green, with an arrow).
    var pausedAt: String?
    var pan = Vec2(40, 40)
    var zoom: Float = 1
    var emptyText = ""

    var onSelect: ((Set<String>) -> Void)?
    var onMove: (([String: Vec2]) -> Void)?
    var onConnect: ((String, String) -> Void)?
    /// A pin's wires should go ("node.pin", is it an input).
    var onDisconnect: ((String, Bool) -> Void)?
    /// Search-to-add at a graph position, optionally from a dragged pin ("node.pin", is it an output, its type).
    var onRequestAdd: ((Vec2, (pin: String, isOutput: Bool, type: VisualScriptType)?) -> Void)?
    var onKey: ((KeyEvent) -> Bool)?
    /// A wire was double-clicked: put a reroute point on it at this graph position.
    var onInsertReroute: ((VisualScriptLink, Vec2) -> Void)?

    private var index: [String: Int] = [:]
    private enum Drag {
        case none
        case move(start: Vec2, original: [String: Vec2], moved: Bool)
        case pan(start: Vec2, original: Vec2, button: MouseButton, moved: Bool)
        case wire(pin: String, isOutput: Bool, type: VisualScriptType, from: Vec2, to: Vec2)
    }
    private var drag = Drag.none
    private var hover: Vec2?

    override init(name: String = "visualScriptCanvas") {
        super.init(name: name)
        clipsContent = true
    }

    override var acceptsFocus: Bool { true }
    override var showsFocusRing: Bool { false }
    override func measureContent(width: Float?) -> Vec2 { Vec2(400, 300) }

    // MARK: Geometry

    func toScreen(_ p: Vec2) -> Vec2 { Vec2(frame.x, frame.y) + (p + pan) * zoom }
    func toGraph(_ p: Vec2) -> Vec2 { (p - Vec2(frame.x, frame.y)) / zoom - pan }

    static func pinY(_ row: Int) -> Float { headerHeight + Float(row) * rowHeight + rowHeight / 2 }

    /// The size of a reroute point.
    static let rerouteSize = Vec2(28, 16)

    /// Where pin `row` sits relative to its node.
    static func pinOffset(_ node: VisualScriptCanvasNode, row: Int, isOutput: Bool) -> Vec2 {
        if node.isReroute { return Vec2(isOutput ? node.size.x : 0, node.size.y / 2) }
        if node.collapsed { return Vec2(isOutput ? node.size.x : 0, headerHeight / 2) }
        return Vec2(isOutput ? node.size.x : 0, pinY(row))
    }

    /// A pin's position in graph space.
    func pinPosition(node: VisualScriptCanvasNode, pin: String, isOutput: Bool) -> Vec2? {
        let list = isOutput ? node.outputs : node.inputs
        guard let row = list.firstIndex(where: { $0.name == pin }) else { return nil }
        return node.position + Self.pinOffset(node, row: row, isOutput: isOutput)
    }

    /// The wire under `screen` (within a few pixels), if any.
    func link(at screen: Vec2) -> VisualScriptLink? {
        for link in links.reversed() {
            guard let from = link.source, let to = link.target, let a = index[from.node], let b = index[to.node],
                  let p = pinPosition(node: nodes[a], pin: from.pin, isOutput: true),
                  let q = pinPosition(node: nodes[b], pin: to.pin, isOutput: false) else { continue }
            let points = Self.wirePoints(toScreen(p), toScreen(q), zoom: zoom)
            for (u, v) in zip(points, points.dropFirst()) where Self.distance(screen, u, v) < 5 { return link }
        }
        return nil
    }

    private static func distance(_ p: Vec2, _ a: Vec2, _ b: Vec2) -> Float {
        let ab = b - a
        let t = max(0, min(1, ((p - a).x * ab.x + (p - a).y * ab.y) / max(ab.x * ab.x + ab.y * ab.y, 1e-6)))
        let d = a + ab * t - p
        return (d.x * d.x + d.y * d.y).squareRoot()
    }

    /// The points of the curve drawn for a wire from `a` to `b` (screen space).
    static func wirePoints(_ a: Vec2, _ b: Vec2, zoom: Float) -> [Vec2] {
        let dx = max(abs(b.x - a.x) * 0.5, 40 * zoom)
        let c1 = a + Vec2(dx, 0), c2 = b - Vec2(dx, 0)
        return (0...20).map { i in
            let t = Float(i) / 20, u = 1 - t
            return a * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + b * (t * t * t)
        }
    }

    private func pin(at screen: Vec2) -> (ref: String, isOutput: Bool, type: VisualScriptType, position: Vec2)? {
        let p = toGraph(screen)
        let radius: Float = 9 / max(zoom, 0.3)
        for node in nodes.reversed() where !node.collapsed {
            for (isOutput, list) in [(false, node.inputs), (true, node.outputs)] {
                for (row, pin) in list.enumerated() {
                    let at = node.position + Self.pinOffset(node, row: row, isOutput: isOutput)
                    // Generous on the inner side, so the pin's label counts too (not on a reroute: its middle moves it).
                    let dx = isOutput ? at.x - p.x : p.x - at.x
                    if abs(p.y - at.y) < radius, dx > -radius, dx < (node.isReroute ? 7 : 60) { return ("\(node.id).\(pin.name)", isOutput, pin.type, at) }
                }
            }
        }
        return nil
    }

    private func node(at screen: Vec2) -> VisualScriptCanvasNode? {
        let p = toGraph(screen)
        return nodes.last { p.x >= $0.position.x && p.x <= $0.position.x + $0.size.x && p.y >= $0.position.y && p.y <= $0.position.y + $0.size.y }
    }

    // MARK: Events

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e):
            context?.focus(self)
            if e.button == .left {
                if e.clickCount >= 2, pin(at: e.position) == nil, node(at: e.position) == nil, let link = link(at: e.position) {
                    onInsertReroute?(link, toGraph(e.position))
                    drag = .none
                    return true
                }
                if let pin = pin(at: e.position) {
                    drag = .wire(pin: pin.ref, isOutput: pin.isOutput, type: pin.type, from: pin.position, to: toGraph(e.position))
                } else if let node = node(at: e.position) {
                    var selected = selection
                    if e.modifiers.contains(.shift) || e.modifiers.contains(.command) {
                        if selected.contains(node.id) { selected.remove(node.id) } else { selected.insert(node.id) }
                    } else if !selected.contains(node.id) {
                        selected = [node.id]
                    }
                    if selected != selection { selection = selected; onSelect?(selected) }
                    var original: [String: Vec2] = [:]
                    for id in selected { if let i = index[id] { original[id] = nodes[i].position } }
                    drag = .move(start: e.position, original: original, moved: false)
                } else {
                    if !selection.isEmpty && !e.modifiers.contains(.shift) { selection = []; onSelect?([]) }
                    drag = .pan(start: e.position, original: pan, button: .left, moved: false)
                }
            } else {
                drag = .pan(start: e.position, original: pan, button: e.button, moved: false)
            }
            setNeedsDisplay()
            return true
        case .pointerDrag(let e):
            switch drag {
            case .move(let start, let original, _):
                let delta = (e.position - start) / zoom
                for (id, position) in original { if let i = index[id] { nodes[i].position = position + delta } }
                drag = .move(start: start, original: original, moved: true)
            case .pan(let start, let original, let button, let moved):
                pan = original + (e.position - start) / zoom
                drag = .pan(start: start, original: original, button: button, moved: moved || ((e.position - start) * (e.position - start)).sum() > 9)
            case .wire(let pin, let isOutput, let type, let from, _):
                drag = .wire(pin: pin, isOutput: isOutput, type: type, from: from, to: toGraph(e.position))
            case .none: break
            }
            setNeedsDisplay()
            return true
        case .pointerUp(let e):
            finishDrag(at: e.position)
            setNeedsDisplay()
            return true
        case .pointerMove(let e):
            hover = e.position
            return false
        case .scroll(let delta, let position):
            let before = toGraph(position)
            zoom = min(max(zoom * powf(1.0015, delta.y), 0.25), 2.5)
            pan = (position - Vec2(frame.x, frame.y)) / zoom - before
            setNeedsDisplay()
            return true
        case .key(let key):
            return onKey?(key) ?? false
        default:
            return false
        }
    }

    private func finishDrag(at position: Vec2) {
        defer { drag = .none }
        switch drag {
        case .move(_, let original, let moved):
            guard moved else { return }
            var moves: [String: Vec2] = [:]
            for id in original.keys { if let i = index[id] { moves[id] = nodes[i].position } }
            onMove?(moves)
        case .pan(_, _, let button, let moved):
            guard !moved, button == .right else { return }
            if let pin = pin(at: position) {
                onDisconnect?(pin.ref, !pin.isOutput)
            } else {
                onRequestAdd?(toGraph(position), nil)
            }
        case .wire(let from, let isOutput, let type, _, _):
            if let target = pin(at: position), target.isOutput != isOutput, target.ref != from {
                isOutput ? onConnect?(from, target.ref) : onConnect?(target.ref, from)
            } else if pin(at: position) == nil {
                onRequestAdd?(toGraph(position), (from, isOutput, type))
            }
        case .none: break
        }
    }

    override func tooltip(at point: Vec2) -> String? {
        if let pin = pin(at: point) {
            var text = "\(pin.ref): \(pin.type.rawValue)"
            if let value = values[pin.ref] { text += " = \(value)" }
            return text
        }
        guard let node = node(at: point) else { return nil }
        var lines = [node.doc.isEmpty ? node.title : node.doc]
        for issue in issues[node.id] ?? [] { lines.append("\(issue.severity.rawValue): \(issue.message)") }
        if let comment = node.comment { lines.append(comment) }
        return lines.joined(separator: "\n")
    }

    // MARK: Drawing

    static func color(_ type: VisualScriptType) -> UIColor {
        switch type {
        case .exec: UIColor(0.95, 0.95, 0.95)
        case .bool: UIColor(0.86, 0.25, 0.25)
        case .int: UIColor(0.2, 0.8, 0.7)
        case .float: UIColor(0.55, 0.85, 0.3)
        case .string: UIColor(0.95, 0.4, 0.8)
        case .vec2: UIColor(0.85, 0.75, 0.2)
        case .vec3: UIColor(1, 0.8, 0.2)
        case .vec4: UIColor(0.35, 0.6, 1)
        case .color: UIColor(1, 0.55, 0.2)
        case .quat: UIColor(0.6, 0.6, 1)
        case .entity: UIColor(0.3, 0.75, 1)
        case .asset: UIColor(0.8, 0.5, 0.3)
        case .array: UIColor(0.75, 0.75, 0.75)
        case .map: UIColor(0.65, 0.45, 0.95)
        case .any: UIColor(0.55, 0.55, 0.55)
        }
    }

    static func headerColor(_ kind: VisualScriptNodeKind, known: Bool) -> UIColor {
        guard known else { return UIColor(0.45, 0.1, 0.1) }
        switch kind {
        case .event: return UIColor(0.55, 0.16, 0.16)
        case .action: return UIColor(0.16, 0.3, 0.55)
        case .pure: return UIColor(0.18, 0.42, 0.24)
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let rect = frame
        list.fillRect(rect, color: UIColor(0.09, 0.095, 0.11))
        drawGrid(list, rect)
        if nodes.isEmpty && !emptyText.isEmpty {
            list.drawText(emptyText, at: Vec2(rect.x + 16, rect.y + 16), size: 13, color: theme.secondaryTextColor, maxWidth: rect.width - 32)
        }
        for comment in comments {
            let origin = toScreen(Vec2(comment.x, comment.y))
            let r = UIRect(x: origin.x, y: origin.y, width: comment.width * zoom, height: comment.height * zoom)
            let tint = comment.color.flatMap { VisualScriptValue(json: .string($0), as: .color)?.asVec4 } ?? Vec4(0.4, 0.45, 0.55, 1)
            list.fillRect(r, color: UIColor(tint.x, tint.y, tint.z, 0.12), radii: UICornerRadii(6))
            list.strokeRect(r, color: UIColor(tint.x, tint.y, tint.z, 0.5), width: 1, radii: UICornerRadii(6))
            list.drawText(comment.text, at: origin + Vec2(8, 6), size: 13 * zoom, color: UIColor(0.9, 0.9, 0.9, 0.9))
        }
        // Wires under the nodes.
        for link in links {
            guard let from = link.source, let to = link.target, let a = index[from.node], let b = index[to.node],
                  let p = pinPosition(node: nodes[a], pin: from.pin, isOutput: true),
                  let q = pinPosition(node: nodes[b], pin: to.pin, isOutput: false) else { continue }
            let type = nodes[a].outputs.first { $0.name == from.pin }?.type ?? .any
            let targetType = nodes[b].inputs.first { $0.name == to.pin }?.type ?? .any
            let bad = !type.converts(to: targetType)
            let recent = (activity[from.node] ?? 99) < 0.25 && (type == .exec)
            var color = bad ? UIColor(1, 0.2, 0.2) : Self.color(type)
            if recent { color = UIColor(1, 0.95, 0.4) }
            drawWire(list, toScreen(p), toScreen(q), color: color, width: (type == .exec ? 2.5 : 1.8) * max(zoom, 0.5) * (recent ? 1.6 : 1))
            if !bad, type != targetType, type != .any, targetType != .any {
                // An automatic conversion: a small dot in the middle.
                let mid = toScreen((p + q) / 2)
                list.fillRect(UIRect(x: mid.x - 3, y: mid.y - 3, width: 6, height: 6), color: Self.color(targetType), radii: UICornerRadii(3))
            }
        }
        if case .wire(_, let isOutput, let type, let from, let to) = drag {
            isOutput ? drawWire(list, toScreen(from), toScreen(to), color: Self.color(type), width: 2)
                     : drawWire(list, toScreen(to), toScreen(from), color: Self.color(type), width: 2)
        }
        for node in nodes { drawNode(list, node, theme: theme) }
    }

    private func drawGrid(_ list: UIDrawList, _ rect: UIRect) {
        let step = 32 * zoom
        guard step > 6 else { return }
        let origin = toScreen(.zero)
        var x = rect.x + (origin.x - rect.x).truncatingRemainder(dividingBy: step)
        if x < rect.x { x += step }
        while x < rect.maxX {
            list.drawLine(from: Vec2(x, rect.y), to: Vec2(x, rect.maxY), width: 1, color: UIColor(1, 1, 1, 0.035))
            x += step
        }
        var y = rect.y + (origin.y - rect.y).truncatingRemainder(dividingBy: step)
        if y < rect.y { y += step }
        while y < rect.maxY {
            list.drawLine(from: Vec2(rect.x, y), to: Vec2(rect.maxX, y), width: 1, color: UIColor(1, 1, 1, 0.035))
            y += step
        }
    }

    private func drawWire(_ list: UIDrawList, _ a: Vec2, _ b: Vec2, color: UIColor, width: Float) {
        let points = Self.wirePoints(a, b, zoom: zoom)
        var previous = a
        for p in points.dropFirst() {
            list.drawLine(from: previous, to: p, width: width, color: color, cap: .round)
            previous = p
        }
    }

    private func drawNode(_ list: UIDrawList, _ node: VisualScriptCanvasNode, theme: UITheme) {
        let origin = toScreen(node.position)
        let size = node.size * zoom
        let rect = UIRect(x: origin.x, y: origin.y, width: size.x, height: size.y)
        guard rect.maxX > frame.x, rect.x < frame.maxX, rect.maxY > frame.y, rect.y < frame.maxY else { return }
        if node.isReroute {
            let type = node.outputs.first?.type ?? .any
            let color = Self.color(type)
            if let since = activity[node.id], since < 0.4 {
                list.fillRect(rect.inset(by: -3 * zoom), color: UIColor(1, 0.9, 0.3, Float(0.45 * (1 - since / 0.4))), radii: UICornerRadii(size.y / 2 + 3 * zoom))
            }
            list.fillRect(rect, color: UIColor(0.16, 0.17, 0.19, 0.96), radii: UICornerRadii(size.y / 2))
            let selected = selection.contains(node.id)
            list.strokeRect(rect, color: selected ? UIColor(1, 0.75, 0.2) : color, width: selected ? 2 : 1.5, radii: UICornerRadii(size.y / 2))
            if pausedAt == node.id { list.strokeRect(rect.inset(by: -3 * zoom), color: UIColor(0.3, 0.95, 0.45), width: 2.5, radii: UICornerRadii(size.y / 2 + 3 * zoom)) }
            for (isOutput, pins) in [(false, node.inputs), (true, node.outputs)] where !pins.isEmpty {
                drawPin(list, Vec2(isOutput ? rect.maxX : rect.x, rect.y + size.y / 2), type,
                        filled: isConnected(node.id, pins[0].name, input: !isOutput))
            }
            if let value = values["\(node.id).out"] {
                list.drawText(value, at: Vec2(rect.x, rect.y - 14 * zoom), size: 10 * zoom, color: UIColor(0.85, 0.85, 0.85))
            }
            return
        }
        let nodeIssues = issues[node.id] ?? []
        let worst = nodeIssues.contains { $0.severity == .error } ? VisualScriptIssue.Severity.error
            : nodeIssues.contains { $0.severity == .warning } ? .warning : nil
        if let since = activity[node.id], since < 0.4 {
            let glow = rect.inset(by: -4 * zoom)
            list.fillRect(glow, color: UIColor(1, 0.9, 0.3, Float(0.45 * (1 - since / 0.4))), radii: UICornerRadii(8 * zoom))
        }
        list.fillRect(rect, color: UIColor(0.16, 0.17, 0.19, 0.96), radii: UICornerRadii(6 * zoom))
        let header = UIRect(x: rect.x, y: rect.y, width: rect.width, height: Self.headerHeight * zoom)
        list.fillRect(header, color: Self.headerColor(node.kind, known: node.known),
                      radii: UICornerRadii(topLeft: 6 * zoom, topRight: 6 * zoom, bottomRight: node.collapsed ? 6 * zoom : 0, bottomLeft: node.collapsed ? 6 * zoom : 0))
        let border: UIColor = selection.contains(node.id) ? UIColor(1, 0.75, 0.2)
            : worst == .error ? UIColor(1, 0.25, 0.25) : worst == .warning ? UIColor(1, 0.75, 0.2, 0.7) : UIColor(0, 0, 0, 0.6)
        list.strokeRect(rect, color: border, width: selection.contains(node.id) ? 2 : 1, radii: UICornerRadii(6 * zoom))
        if pausedAt == node.id {
            let paused = UIColor(0.3, 0.95, 0.45)
            list.strokeRect(rect.inset(by: -3 * zoom), color: paused, width: 2.5, radii: UICornerRadii(8 * zoom))
            list.drawText("▶", at: Vec2(rect.x - 16 * zoom, rect.y + 4 * zoom), size: 13 * zoom, color: paused)
        }
        let textSize = 12 * zoom
        guard textSize > 4 else { return }
        var titleX = rect.x + 8 * zoom
        if node.breakpoint {
            list.fillRect(UIRect(x: titleX, y: rect.y + 7 * zoom, width: 10 * zoom, height: 10 * zoom), color: UIColor(0.95, 0.2, 0.2), radii: UICornerRadii(5 * zoom))
            titleX += 14 * zoom
        }
        list.drawText(node.title, at: Vec2(titleX, rect.y + 5 * zoom), size: textSize, color: .white)
        if worst != nil {
            list.drawText("!", at: Vec2(rect.maxX - 14 * zoom, rect.y + 5 * zoom), size: textSize,
                          color: worst == .error ? UIColor(1, 0.4, 0.4) : UIColor(1, 0.8, 0.3))
        }
        if node.collapsed { return }
        let small = 11 * zoom
        for (row, pin) in node.inputs.enumerated() {
            let y = rect.y + Self.pinY(row) * zoom
            drawPin(list, Vec2(rect.x, y), pin.type, filled: isConnected(node.id, pin.name, input: true))
            var label = pin.displayName
            if pin.type != .exec, let literal = node.literals[pin.name], !isConnected(node.id, pin.name, input: true) { label += " = " + literal }
            if pin.type == .exec && pin.name == "in" { label = "" }
            list.drawText(label, at: Vec2(rect.x + 10 * zoom, y - 7 * zoom), size: small, color: UIColor(0.85, 0.85, 0.85))
        }
        for (row, pin) in node.outputs.enumerated() {
            let y = rect.y + Self.pinY(row) * zoom
            drawPin(list, Vec2(rect.maxX, y), pin.type, filled: isConnected(node.id, pin.name, input: false))
            var label = pin.type == .exec && pin.name == "out" ? "" : pin.displayName
            if let value = values["\(node.id).\(pin.name)"] { label += " = " + value }
            let width = TextLayout(label, font: UIDrawList.defaultFont, size: small).bounds.x
            list.drawText(label, at: Vec2(rect.maxX - 10 * zoom - width, y - 7 * zoom), size: small, color: UIColor(0.85, 0.85, 0.85))
        }
    }

    private func drawPin(_ list: UIDrawList, _ at: Vec2, _ type: VisualScriptType, filled: Bool) {
        let r = (type == .exec ? 5 : 4.5) * zoom
        let rect = UIRect(x: at.x - r, y: at.y - r, width: 2 * r, height: 2 * r)
        let color = Self.color(type)
        if filled {
            list.fillRect(rect, color: color, radii: UICornerRadii(type == .exec ? 1 : r))
        } else {
            list.fillRect(rect, color: UIColor(0.12, 0.12, 0.14), radii: UICornerRadii(type == .exec ? 1 : r))
            list.strokeRect(rect, color: color, width: 1.5, radii: UICornerRadii(type == .exec ? 1 : r))
        }
    }

    private func isConnected(_ node: String, _ pin: String, input: Bool) -> Bool {
        let ref = "\(node).\(pin)"
        return links.contains { input ? $0.to == ref : $0.from == ref }
    }

    /// The size a node needs for its title and pins.
    static func size(title: String, inputs: [VisualScriptPin], outputs: [VisualScriptPin], literals: [String: String], collapsed: Bool) -> Vec2 {
        func width(_ s: String, _ size: Float) -> Float { TextLayout(s, font: UIDrawList.defaultFont, size: size).bounds.x }
        var w = width(title, 12) + 40
        let rows = max(inputs.count, outputs.count)
        for row in 0..<rows {
            var left: Float = 0, right: Float = 0
            if row < inputs.count {
                let pin = inputs[row]
                left = width(pin.displayName + (literals[pin.name].map { " = " + $0 } ?? ""), 11)
            }
            if row < outputs.count { right = width(outputs[row].displayName, 11) + 40 }
            w = max(w, left + right + 40)
        }
        w = min(max(w, 140), 420)
        return Vec2(w, collapsed ? headerHeight : headerHeight + Float(max(rows, 1)) * rowHeight + 8)
    }
}
