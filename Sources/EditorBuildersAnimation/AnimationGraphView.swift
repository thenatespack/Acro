import EditorCore
import Engine
import Foundation

// The Animation Graph Builder's node editor and sidebar form for an `.animgraph` file.
//
// `AnimGraphCanvas` draws the states as nodes, the Any State node and the transitions as arrows
// (the playing state highlighted with its progress). Click selects, dragging a node moves it,
// dragging from a node's right-hand port to another node adds a transition, dragging the empty
// background pans. `AnimationGraphView` is the sidebar: preview model, parameters (with live
// controls that drive the preview), the selected state or transition, layers and problems.
// Every change is written to the file as one undo step (`EditorSession.applyAnimationGraph`).

/// What is selected in the graph.
public enum AnimGraphSelection: Equatable, Sendable {
    case none
    case state(String)
    case transition(Int)
    case anyState
}

/// The node editor.
@MainActor
public final class AnimGraphCanvas: Widget {
    public var graph = AnimationGraph() { didSet { setNeedsDisplay() } }
    public var selection: AnimGraphSelection = .none { didSet { setNeedsDisplay() } }
    /// The state the preview is playing, and how far through its cycle (0...1).
    public var activeState: String? { didSet { if activeState != oldValue { setNeedsDisplay() } } }
    public var activeProgress: Float = 0 { didSet { setNeedsDisplay() } }
    /// Display names of clips.
    public var clipName: (String) -> String = { $0 }
    /// Scroll of the graph (points).
    public private(set) var pan = Vec2(0, 0)

    public var onSelect: ((AnimGraphSelection) -> Void)?
    /// A node was dragged: its name (nil for the Any State node) and new graph position.
    public var onMove: ((String?, Vec2) -> Void)?
    /// A transition was drawn from a state (nil: Any State) to a state.
    public var onConnect: ((String?, String) -> Void)?
    public var onDelete: (() -> Void)?
    /// A state node was double-clicked (opens a sub-state machine).
    public var onOpen: ((String) -> Void)?
    /// States of the enclosing levels, when the canvas shows a sub-state machine.
    public var outerStates: [String] = [] { didSet { setNeedsDisplay() } }

    static let nodeSize = Vec2(156, 46)
    static let anyStateName = "\u{1}any"

    private enum Drag {
        case node(String?, grab: Vec2, moved: Bool)
        case connect(from: String?, to: Vec2)
        case pan(last: Vec2)
    }
    private var drag: Drag?
    private var dragPositions: [String: Vec2] = [:]

    public override init(name: String = "animGraphCanvas") {
        super.init(name: name)
        clipsContent = true
    }

    public override var acceptsFocus: Bool { true }
    public override func measureContent(width: Float?) -> Vec2 { Vec2(320, 220) }

    // MARK: Geometry

    private var origin: Vec2 {
        let r = contentRect
        return Vec2(r.x + 40, r.y + r.height / 2 - Self.nodeSize.y / 2) + pan
    }

    private func position(of name: String?) -> Vec2 {
        let key = name ?? Self.anyStateName
        if let p = dragPositions[key] { return p }
        if let name { return graph.state(named: name)?.position ?? .zero }
        return graph.anyStatePosition
    }

    func rect(of name: String?) -> UIRect {
        let p = origin + position(of: name)
        return UIRect(x: p.x, y: p.y, width: Self.nodeSize.x, height: name == nil ? 30 : Self.nodeSize.y)
    }

    private func center(_ r: UIRect) -> Vec2 { Vec2(r.x + r.width / 2, r.y + r.height / 2) }

    private func port(of name: String?) -> Vec2 {
        let r = rect(of: name)
        return Vec2(r.x + r.width, r.y + r.height / 2)
    }

    /// The node under `point` (nil name = Any State); nil when none.
    func node(at point: Vec2) -> String?? {
        for state in graph.states.reversed() where rect(of: state.name).contains(point) { return .some(state.name) }
        if rect(of: nil).contains(point) { return .some(nil) }
        return nil
    }

    private func isOnPort(_ point: Vec2, of name: String?) -> Bool {
        let p = port(of: name)
        return length(point - p) <= 9
    }

    /// The two ends of a transition's arrow, offset sideways when the opposite one exists too.
    private func segment(_ transition: AnimationGraphTransition) -> (Vec2, Vec2)? {
        guard transition.from.map({ graph.state(named: $0) != nil }) ?? true else { return nil }
        if graph.state(named: transition.to) == nil {
            // Out of a sub-state machine (to a state of an enclosing level): a stub down from the node.
            guard isLeaving(transition) else { return nil }
            let r = rect(of: transition.from)
            let a = Vec2(r.x + r.width - 18, r.y + r.height)
            return (a, a + Vec2(0, 34))
        }
        let a = center(rect(of: transition.from)), b = center(rect(of: transition.to))
        let d = b - a
        let len = length(d)
        guard len > 1 else { return nil }
        let side = Vec2(-d.y, d.x) / len * 7
        return (a + side, b + side)
    }

    /// Whether `transition` goes to a state outside this level (only inside a sub-state machine).
    func isLeaving(_ transition: AnimationGraphTransition) -> Bool {
        outerStates.contains(transition.to) && graph.state(named: transition.to) == nil
    }

    func transition(at point: Vec2) -> Int? {
        var best: (Int, Float)?
        for (i, t) in graph.transitions.enumerated() {
            guard let (a, b) = segment(t) else { continue }
            let ab = b - a
            let u = min(max(dot(point - a, ab) / max(dot(ab, ab), 1e-4), 0), 1)
            let dist = length(point - (a + ab * u))
            if dist < 7, dist < (best?.1 ?? .infinity) { best = (i, dist) }
        }
        return best?.0
    }

    // MARK: Drawing

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let r = contentRect
        list.fillRect(r, color: UIColor(0.07, 0.08, 0.1, 1))
        // Grid.
        let step: Float = 40
        let o = origin
        var x = r.x + (o.x - r.x).truncatingRemainder(dividingBy: step)
        while x < r.x + r.width {
            list.drawLine(from: Vec2(x, r.y), to: Vec2(x, r.y + r.height), width: 1, color: UIColor(1, 1, 1, 0.04))
            x += step
        }
        var y = r.y + (o.y - r.y).truncatingRemainder(dividingBy: step)
        while y < r.y + r.height {
            list.drawLine(from: Vec2(r.x, y), to: Vec2(r.x + r.width, y), width: 1, color: UIColor(1, 1, 1, 0.04))
            y += step
        }
        // Transitions.
        for (i, t) in graph.transitions.enumerated() {
            guard let (a, b) = segment(t) else { continue }
            let selected = selection == .transition(i)
            let color = selected ? theme.accent : (t.isAnyState ? UIColor(0.85, 0.65, 0.3, 0.8) : UIColor(0.75, 0.78, 0.85, 0.7))
            list.drawLine(from: a, to: b, width: selected ? 3 : 2, color: color)
            let mid = (a + b) / 2, dir = normalize(b - a), side = Vec2(-dir.y, dir.x)
            let tip = mid + dir * 6
            list.drawLine(from: tip, to: tip - dir * 10 + side * 6, width: 2, color: color)
            list.drawLine(from: tip, to: tip - dir * 10 - side * 6, width: 2, color: color)
            if isLeaving(t) { list.drawText("↑ " + t.to, at: b + Vec2(-10, 3), size: 11, color: color) }
        }
        if case .connect(let from, let to)? = drag {
            list.drawLine(from: port(of: from), to: to, width: 2, color: theme.accent)
        }
        // Any State node.
        let any = rect(of: nil)
        list.fillRect(any, color: UIColor(0.3, 0.22, 0.1, 1), radii: UICornerRadii(6))
        list.strokeRect(any, color: selection == .anyState ? theme.accent : UIColor(0.85, 0.65, 0.3, 1), width: selection == .anyState ? 2 : 1,
                        radii: UICornerRadii(6))
        list.drawText("Any State", at: Vec2(any.x + 10, any.y + 8), size: 12, color: theme.textColor)
        drawPort(list, at: port(of: nil), theme: theme)
        // States.
        let initial = graph.initialState.flatMap { graph.state(named: $0)?.name } ?? graph.states.first?.name
        for state in graph.states {
            let box = rect(of: state.name)
            let active = state.name == activeState
            list.fillRect(box, color: active ? UIColor(0.12, 0.26, 0.17, 1) : UIColor(0.16, 0.19, 0.25, 1), radii: UICornerRadii(6))
            let selected = selection == .state(state.name)
            let border = selected ? theme.accent : active ? UIColor(0.35, 0.8, 0.5, 1) : UIColor(0.32, 0.36, 0.46, 1)
            list.strokeRect(box, color: border, width: selected || active ? 2 : 1, radii: UICornerRadii(6))
            if state.machine != nil {
                list.strokeRect(UIRect(x: box.x + 3, y: box.y + 3, width: box.width - 6, height: box.height - 6), color: border.withAlpha(0.6),
                                width: 1, radii: UICornerRadii(4))
            }
            if state.name == initial {
                list.fillRect(UIRect(x: box.x, y: box.y + 6, width: 4, height: box.height - 12), color: UIColor(0.95, 0.7, 0.25, 1))
            }
            list.drawText(state.name, at: Vec2(box.x + 10, box.y + 6), size: 13, color: theme.textColor)
            let detail: String
            if let machine = state.machine {
                detail = "Sub-machine · \(machine.states.count) states"
            } else if let blend = state.blend {
                let parameters = [blend.parameter] + (blend.parameterY.map { [$0] } ?? [])
                // Clip count before the parameters, so a long parameter name is what gets cut.
                detail = "Blend\(blend.is2D ? " 2D" : "") · \(blend.clips.count) clips · \(parameters.map { $0.isEmpty ? "?" : $0 }.joined(separator: ", "))"
            } else {
                detail = clipName(state.clip ?? "")
            }
            list.drawText(String(detail.prefix(24)), at: Vec2(box.x + 10, box.y + 25), size: 11, color: theme.secondaryTextColor)
            if active {
                let w = (box.width - 12) * min(max(activeProgress, 0), 1)
                list.fillRect(UIRect(x: box.x + 6, y: box.y + box.height - 5, width: w, height: 2), color: UIColor(0.35, 0.8, 0.5, 1))
            }
            drawPort(list, at: port(of: state.name), theme: theme)
        }
        if graph.states.isEmpty {
            list.drawText("No states: Add State in the sidebar", at: Vec2(r.x + 12, r.y + 12), size: 12, color: theme.secondaryTextColor)
        }
        list.drawText("Drag nodes to move · drag from a port to connect · drag the background to pan",
                      at: Vec2(r.x + 8, r.y + r.height - 18), size: 10, color: theme.secondaryTextColor.withAlpha(0.7))
    }

    private func drawPort(_ list: UIDrawList, at p: Vec2, theme: UITheme) {
        list.fillRect(UIRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10), color: UIColor(0.85, 0.87, 0.92, 1), radii: UICornerRadii(5))
    }

    // MARK: Events

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            context?.focus(self)
            let p = e.position
            for state in graph.states.reversed() where isOnPort(p, of: state.name) {
                drag = .connect(from: state.name, to: p)
                return true
            }
            if isOnPort(p, of: nil) {
                drag = .connect(from: nil, to: p)
                return true
            }
            if let hit = node(at: p) {
                if e.clickCount == 2, let name = hit, graph.state(named: name)?.machine != nil {
                    onOpen?(name)
                    return true
                }
                select(hit.map { .state($0) } ?? .anyState)
                drag = .node(hit, grab: p - origin - position(of: hit), moved: false)
            } else if let t = transition(at: p) {
                select(.transition(t))
            } else {
                select(.none)
                drag = .pan(last: p)
            }
            return true
        case .pointerDrag(let e):
            switch drag {
            case .node(let name, let grab, _)?:
                dragPositions[name ?? Self.anyStateName] = (e.position - origin - grab).rounded(to: 10)
                drag = .node(name, grab: grab, moved: true)
                setNeedsDisplay()
            case .connect(let from, _)?:
                drag = .connect(from: from, to: e.position)
                setNeedsDisplay()
            case .pan(let last)?:
                pan += e.position - last
                drag = .pan(last: e.position)
                setNeedsDisplay()
            case nil: break
            }
            return true
        case .pointerUp(let e):
            switch drag {
            case .node(let name, _, true)?:
                if let p = dragPositions[name ?? Self.anyStateName] { onMove?(name, p) }
            case .connect(let from, _)?:
                if case .some(.some(let target)) = node(at: e.position), target != from { onConnect?(from, target) }
            default: break
            }
            drag = nil
            dragPositions.removeAll()
            setNeedsDisplay()
            return true
        case .key(let k) where k.key == .delete || k.key == .backspace:
            guard selection != .none, selection != .anyState else { return false }
            onDelete?()
            return true
        default:
            return false
        }
    }

    private func select(_ s: AnimGraphSelection) {
        selection = s
        onSelect?(s)
    }

    /// Centers the view on the nodes.
    public func frameAll() {
        pan = .zero
        setNeedsDisplay()
    }
}

private extension Vec2 {
    func rounded(to step: Float) -> Vec2 { Vec2((x / step).rounded() * step, (y / step).rounded() * step) }
}

private func length(_ v: Vec2) -> Float { (v.x * v.x + v.y * v.y).squareRoot() }
private func dot(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
private func normalize(_ v: Vec2) -> Vec2 { let l = length(v); return l > 0 ? v / l : v }

// MARK: - Proxy components for the property grids

/// A state's plain settings.
struct AnimGraphStateComponent: Component {
    static var componentName: String { "AnimGraphState" }
    static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(range: 0...10, step: 0.05, tooltip: "Playback rate (1 is the clip's own speed)"),
         "loops": FieldHints(tooltip: "Repeat; otherwise hold the last frame"),
         "speedParameter": FieldHints(tooltip: "A float parameter multiplying the speed (empty: none)")]
    }
    var name: String
    var speed: Float
    var speedParameter: String
    var loops: Bool
}

/// A transition's plain settings.
struct AnimGraphTransitionComponent: Component {
    static var componentName: String { "AnimGraphTransition" }
    static var fieldHints: [String: FieldHints] {
        ["duration": FieldHints(range: 0...5, step: 0.01, tooltip: "Crossfade seconds"),
         "hasExitTime": FieldHints(displayName: "Exit Time", tooltip: "Fire only when the source state's normalized time reaches Exit At"),
         "exitAt": FieldHints(range: 0...10, step: 0.01, tooltip: "Normalized time of the source state (0.9: near the end of a cycle)"),
         "canTransitionToSelf": FieldHints(tooltip: "An Any State transition may restart the state it targets")]
    }
    var duration: Float
    var hasExitTime: Bool
    var exitAt: Float
    var canTransitionToSelf: Bool
}

/// A parameter's name and default.
struct AnimGraphParameterComponent: Component {
    static var componentName: String { "AnimGraphParameter" }
    static var fieldHints: [String: FieldHints] { ["defaultValue": FieldHints(step: 0.05, displayName: "Default")] }
    var name: String
    var defaultValue: Float
}

/// A layer's settings.
struct AnimGraphLayerComponent: Component {
    static var componentName: String { "AnimGraphLayer" }
    static var fieldHints: [String: FieldHints] {
        ["weight": FieldHints(range: 0...1, step: 0.01), "speed": FieldHints(range: 0...10, step: 0.05),
         "referenceTime": FieldHints(step: 0.01, tooltip: "Seconds into the clip of the pose the layer is relative to")]
    }
    var name: String
    var weight: Float
    var speed: Float
    var referenceTime: Float
}

/// An IK node's settings (bones as comma-separated names; legs as "hip, knee, ankle; …").
struct AnimGraphIKComponent: Component {
    static var componentName: String { "AnimGraphIK" }
    static var fieldHints: [String: FieldHints] {
        ["weight": FieldHints(range: 0...1, step: 0.01),
         "weightParameter": FieldHints(tooltip: "A float parameter multiplying the weight (empty: none)"),
         "bones": FieldHints(tooltip: "Bone names, root to tip, separated by commas (twoBoneIK: root, middle, end)"),
         "targetEntity": FieldHints(tooltip: "Follow the first entity with this Name (empty: the target point, or one set at run time)"),
         "target": FieldHints(tooltip: "World-space point when no target entity is set"),
         "pole": FieldHints(tooltip: "twoBoneIK and footPlacement: the way the middle joint bends, in the character's space (zero: keep the animated bend)"),
         "aimAxis": FieldHints(tooltip: "aim: the last bone's axis that points at the target"),
         "maxAngle": FieldHints(range: 0...180, step: 1, tooltip: "aim: the most each bone turns, degrees"),
         "legs": FieldHints(tooltip: "footPlacement: hip, knee, ankle per leg; legs separated by semicolons"),
         "pelvis": FieldHints(tooltip: "footPlacement: the bone that drops so the lower foot reaches")]
    }
    var name: String
    var weight: Float
    var weightParameter: String
    var bones: String
    var targetEntity: String
    var target: Vec3
    var pole: Vec3
    var aimAxis: Vec3
    var maxAngle: Float
    var legs: String
    var pelvis: String

    init(_ node: AnimationIKNode) {
        name = node.name
        weight = node.weight
        weightParameter = node.weightParameter ?? ""
        bones = node.bones.joined(separator: ", ")
        targetEntity = node.targetEntity ?? ""
        target = node.target ?? .zero
        pole = node.pole ?? .zero
        aimAxis = node.aimAxis
        maxAngle = node.maxAngle
        legs = node.legs.map { $0.joined(separator: ", ") }.joined(separator: "; ")
        pelvis = node.pelvis ?? ""
    }

    /// `node` with these settings.
    func applied(to node: AnimationIKNode) -> AnimationIKNode {
        func names(_ text: String) -> [String] { text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        var n = node
        n.weight = min(max(weight, 0), 1)
        n.weightParameter = weightParameter.isEmpty ? nil : weightParameter
        n.bones = names(bones)
        n.targetEntity = targetEntity.isEmpty ? nil : targetEntity
        n.target = target == .zero && node.target == nil ? nil : target
        n.pole = pole == .zero ? nil : pole
        n.aimAxis = aimAxis
        n.maxAngle = maxAngle
        n.legs = legs.split(separator: ";").map { names(String($0)) }.filter { !$0.isEmpty }
        n.pelvis = pelvis.isEmpty ? nil : pelvis
        return n
    }
}

// MARK: - Sidebar

@MainActor
public final class AnimationGraphView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    /// The level the canvas and form show and edit: the whole graph, or a sub-state machine's
    /// (`AnimationGraph.level(at:)`) with the graph-wide settings.
    public private(set) var graph: AnimationGraph
    /// The file's whole graph.
    public private(set) var fileGraph: AnimationGraph
    /// The sub-state machine shown (state names from the root); empty for the top level.
    public private(set) var path: [String] = []
    public private(set) var selection: AnimGraphSelection = .none
    /// The selected parameter (its name and default grid).
    public private(set) var selectedParameter: String?
    public private(set) var selectedLayer: String?
    /// The IK node whose settings show.
    public private(set) var selectedIK: String?
    private var newIKType = 0
    public let canvas = AnimGraphCanvas()

    /// Live parameter values for the preview (not saved).
    public var liveValue: (String) -> AnimationParameter? = { _ in nil }
    public var onSetLive: ((String, AnimationParameter) -> Void)?
    /// The state the preview plays (a flattened name) and how far through its cycle (0...1).
    public var previewPlayback: () -> (state: String, phase: Float)? = { nil }
    /// Assigns the graph to the scene selection.
    public var onAssign: (() -> Void)?

    private let gridWorld = World()
    private var grids: [PropertyGrid] = []
    private var proxies: [Entity] = []
    private var pending: (graph: AnimationGraph, label: String)?
    private var liveControls: [(name: String, refresh: () -> Void)] = []
    private static var selections: [AssetID: AnimGraphSelection] = [:]
    private static var paths: [AssetID: [String]] = [:]
    /// The clip whose events the state editor shows, when the state plays several.
    private var eventsClip: String?

    public init?(session: EditorSession, asset: AssetID) {
        guard session.isAnimationGraphFile(asset), let graph = session.assets?.animationGraph(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        fileGraph = graph
        path = Self.paths[asset] ?? []
        if let level = graph.level(at: path) { self.graph = level } else { self.graph = graph; path = [] }
        view = VStack(spacing: 6, name: "animGraphForm")
        selection = Self.selections[asset] ?? .none
        canvas.clipName = { [unowned session] in session.clipDisplayName($0) }
        canvas.onSelect = { [unowned self] s in select(s) }
        canvas.onMove = { [unowned self] name, p in moveNode(name, to: p) }
        canvas.onConnect = { [unowned self] from, to in connect(from: from, to: to) }
        canvas.onDelete = { [unowned self] in deleteSelected() }
        canvas.onOpen = { [unowned self] name in enter(name) }
        sanitizeSelection()
        layout()
    }

    /// Call every frame: applies the pending edit and keeps grids and live controls current.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.graph, label: pending.label)
        }
        for grid in grids { grid.refresh() }
        for control in liveControls { control.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let graph = session.assets?.animationGraph(of: asset) else { return }
        setFileGraph(graph)
        sanitizeSelection()
        layout()
    }

    /// Takes the file's graph and shows the current level of it (the nearest one that still exists).
    private func setFileGraph(_ whole: AnimationGraph) {
        fileGraph = whole
        while !path.isEmpty, whole.level(at: path) == nil { path.removeLast() }
        Self.paths[asset] = path
        graph = whole.level(at: path) ?? whole
    }

    /// Shows the sub-state machine `name` of the current level.
    public func enter(_ name: String) {
        guard let level = fileGraph.level(at: path + [name]) else { return }
        path.append(name)
        Self.paths[asset] = path
        graph = level
        selection = .none
        Self.selections[asset] = selection
        sanitizeSelection()
        layout()
    }

    /// Shows the level `depth` steps from the top (0: the whole graph).
    public func goUp(to depth: Int? = nil) {
        guard !path.isEmpty else { return }
        let left = path.last!
        path = Array(path.prefix(depth ?? path.count - 1))
        Self.paths[asset] = path
        graph = fileGraph.level(at: path) ?? fileGraph
        selection = graph.state(named: left) != nil ? .state(left) : .none
        Self.selections[asset] = selection
        sanitizeSelection()
        layout()
    }

    /// States of the levels enclosing the current one (innermost first), which its transitions may go to.
    var outerStateNames: [String] {
        var names: [String] = []
        for depth in stride(from: path.count - 1, through: 0, by: -1) {
            for name in fileGraph.level(at: Array(path.prefix(depth)))?.states.map(\.name) ?? [] where !names.contains(name) {
                names.append(name)
            }
        }
        return names.filter { graph.state(named: $0) == nil }
    }

    /// The node of the current level a playing state (a flattened name, "Combat/Slash") is in.
    public func levelState(ofPlaying name: String?) -> String? {
        guard let parts = name?.components(separatedBy: AnimationGraph.levelSeparator), parts.count > path.count,
              Array(parts.prefix(path.count)) == path else { return nil }
        return parts[path.count]
    }

    private func sanitizeSelection() {
        switch selection {
        case .state(let name) where graph.state(named: name) == nil: selection = .none
        case .transition(let i) where !graph.transitions.indices.contains(i): selection = .none
        default: break
        }
        if let p = selectedParameter, graph.parameter(named: p) == nil { selectedParameter = nil }
        if let l = selectedLayer, !graph.layers.contains(where: { $0.name == l }) { selectedLayer = nil }
        canvas.graph = graph
        canvas.outerStates = outerStateNames
        canvas.selection = selection
    }

    // MARK: Edits

    func apply(_ edited: AnimationGraph, label: String) {
        pending = (edited, label)
    }

    private func commit(_ edited: AnimationGraph, label: String) {
        let whole = fileGraph.replacingLevel(at: path, with: edited) ?? edited
        guard session.applyAnimationGraph(whole, to: asset, label: label) != nil else { return }
        setFileGraph(session.assets?.animationGraph(of: asset) ?? whole)
        sanitizeSelection()
        layout()
    }

    public func select(_ s: AnimGraphSelection) {
        selection = s
        Self.selections[asset] = s
        canvas.selection = s
        layout()
    }

    /// Opens parameter `name`'s editor in the sidebar (nil closes it), as clicking its name does.
    public func selectParameter(_ name: String?) {
        selectedParameter = name
        layout()
    }

    /// Opens layer `name`'s editor (weight, mask…) in the sidebar (nil closes it), as clicking its name does.
    public func selectLayer(_ name: String?) {
        selectedLayer = name
        layout()
    }

    /// Shows the IK node `name`'s settings (nil: none).
    public func selectIK(_ name: String?) {
        selectedIK = name
        layout()
    }

    func moveNode(_ name: String?, to p: Vec2) {
        var edited = graph
        if let name, let i = edited.states.firstIndex(where: { $0.name == name }) {
            edited.states[i].position = p
        } else if name == nil {
            edited.anyStatePosition = p
        }
        apply(edited, label: "Move Node")
    }

    func connect(from: String?, to: String) {
        var edited = graph
        let conditions = edited.parameters.first.map { p in
            [AnimationGraphCondition(parameter: p.name, test: p.type == .float ? .greater : p.type == .bool ? .isTrue : .triggered, value: 0.5)]
        } ?? []
        // Without a parameter to test, wait for the end of the source state's cycle instead.
        edited.transitions.append(AnimationGraphTransition(from: from, to: to, conditions: conditions,
                                                           exitTime: conditions.isEmpty ? 1 : nil))
        selection = .transition(edited.transitions.count - 1)
        Self.selections[asset] = selection
        apply(edited, label: "Add Transition")
    }

    public func addState() {
        var edited = graph
        let name = edited.uniqueStateName("State")
        var position = AnimGraphEditCommand.nextNodePosition(in: edited)
        if edited.states.isEmpty { position = .zero }
        let clip = session.animationClipChoices(for: graph).first
        edited.states.append(AnimationGraphState(name: name, clip: clip, position: position))
        if edited.states.count == 1 { edited.initialState = name }
        selection = .state(name)
        Self.selections[asset] = selection
        apply(edited, label: "Add State")
    }

    public func deleteSelected() {
        var edited = graph
        switch selection {
        case .state(let name): edited.removeState(name)
        case .transition(let i) where edited.transitions.indices.contains(i): edited.transitions.remove(at: i)
        default: return
        }
        selection = .none
        Self.selections[asset] = selection
        apply(edited, label: "Delete")
    }

    private func editState(_ label: String, _ change: (inout AnimationGraphState) -> Void) {
        guard case .state(let name) = selection, let i = graph.states.firstIndex(where: { $0.name == name }) else { return }
        var edited = graph
        change(&edited.states[i])
        apply(edited, label: label)
    }

    private func editTransition(_ label: String, _ change: (inout AnimationGraphTransition) -> Void) {
        guard case .transition(let i) = selection, graph.transitions.indices.contains(i) else { return }
        var edited = graph
        change(&edited.transitions[i])
        apply(edited, label: label)
    }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        for entity in proxies { gridWorld.despawn(entity) }
        proxies.removeAll()
        grids.removeAll()
        liveControls.removeAll()

        let assign = Button("Put on Selection", role: .primary, name: "animGraphAssign") { [unowned self] in onAssign?() }
        assign.command = AnimGraphAssignCommand.id.rawValue
        assign.tooltip = "Give the entity selected in the scene (a placed model's root) an Animator playing this graph"
        view.addChild(HStack(spacing: 6, [assign, Spacer()]))
        addLevelBar()

        addPreviewSection()
        addRetargetSection()
        addParametersSection()
        view.addChild(Separator())
        addSelectionSection()
        view.addChild(Separator())
        addLayersSection()
        view.addChild(Separator())
        addIKSection()
        let problems = session.animationGraphProblems(fileGraph)
        if !problems.isEmpty {
            view.addChild(Separator())
            view.addChild(Label("Problems", role: .secondary))
            for problem in problems {
                let label = Label("• " + problem, role: .caption, name: "animGraphProblem")
                label.wraps = true
                view.addChild(label)
            }
        }
    }

    /// Where the canvas is: the top level or a sub-state machine, with a way back up.
    private func addLevelBar() {
        guard !path.isEmpty else { return }
        let row = HStack(spacing: 4, name: "animGraphLevel")
        let top = Button("Graph", name: "animGraphLevelTop") { [unowned self] in goUp(to: 0) }
        top.tooltip = "Back to the top level"
        row.addChild(top)
        for (depth, name) in path.enumerated() {
            row.addChild(Label("›", role: .secondary))
            let step = Button(name, name: "animGraphLevelStep") { [unowned self] in goUp(to: depth + 1) }
            step.isEnabled = depth + 1 < path.count
            row.addChild(step)
        }
        row.addChild(Spacer())
        let up = Button("Up", name: "animGraphLevelUp") { [unowned self] in goUp() }
        up.tooltip = "Leave this sub-state machine"
        row.addChild(up)
        view.addChild(row)
        view.addChild(note("Inside a sub-state machine: transitions may go to its states or to states outside it (by name); Any State here means any state inside. Parameters and layers belong to the whole graph."))
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "animGraphNote")
        label.wraps = true
        return label
    }

    private func addPreviewSection() {
        view.addChild(Label("Preview Model", role: .secondary))
        let prefabs = session.assets?.references(of: .prefab).filter { ref in
            let path = session.assets?.path(of: ref.asset) ?? ""
            return !path.hasSuffix(".vfx") && !path.hasSuffix(".postfx") && !path.hasSuffix(".terrain")
        } ?? []
        let keys = prefabs.map { AssetReference($0.asset).description }
        var options = ["(none)"] + prefabs.map { session.assets?.displayName(of: $0) ?? $0.description }
        var selected = graph.preview.flatMap { p in keys.firstIndex(of: p).map { $0 + 1 } } ?? 0
        if let preview = graph.preview, selected == 0 {
            options.append(preview)
            selected = options.count - 1
        }
        let picker = Dropdown(options: options, selectedIndex: selected, name: "animGraphPreview") { [unowned self] index in
            var edited = graph
            edited.preview = index == 0 ? nil : keys.indices.contains(index - 1) ? keys[index - 1] : graph.preview
            apply(edited, label: "Set Preview Model")
        }
        picker.tooltip = "The model the graph is previewed on (a glTF file with clips, or any prefab)"
        view.addChild(picker)
    }

    /// The skeleton of the graph's first clip that records one, and that clip's animated bones.
    private func clipSkeleton() -> (skeleton: AnimationSkeleton, animated: Set<Int>)? {
        guard let assets = session.assets else { return nil }
        for key in graph.clipKeys {
            if let clip = AssetReference(key).flatMap({ assets.animationClip($0) }), let skeleton = clip.skeleton {
                return (skeleton, Set(clip.channels.map(\.target)))
            }
        }
        return nil
    }

    private func addRetargetSection() {
        let on = graph.retarget != nil
        let toggle = Checkbox("Retarget clips by bone name", isOn: on, kind: .toggleSwitch, name: "animGraphRetarget") { [unowned self] isOn in
            var edited = graph
            edited.retarget = isOn ? AnimationRetargetOptions() : nil
            apply(edited, label: isOn ? "Retarget Clips" : "Stop Retargeting Clips")
        }
        toggle.tooltip = "Play clips made for another skeleton (another glTF file, a .character) by matching bones by name"
        view.addChild(toggle)
        guard let options = graph.retarget else { return }
        func set(_ label: String, _ change: @escaping (inout AnimationRetargetOptions) -> Void) {
            var edited = graph
            var options = edited.retarget ?? AnimationRetargetOptions()
            change(&options)
            edited.retarget = options
            apply(edited, label: label)
        }
        let rotations = AnimationRetargetOptions.Rotation.allCases, translations = AnimationRetargetOptions.Translation.allCases
        let rotation = Dropdown(options: ["Rotation: model space", "Rotation: local", "Rotation: copy"],
                                selectedIndex: rotations.firstIndex(of: options.rotation) ?? 0, name: "animGraphRetargetRotation") { index in
            set("Set Retarget Rotation") { $0.rotation = rotations[index] }
        }
        rotation.tooltip = "Model space handles bones whose rest orientations differ (resampled); local keeps the keys; copy takes values as they are"
        let translation = Dropdown(options: ["Move: none", "Move: root", "Move: all"],
                                   selectedIndex: translations.firstIndex(of: options.translation) ?? 0, name: "animGraphRetargetTranslation") { index in
            set("Set Retarget Translation") { $0.translation = translations[index] }
        }
        translation.tooltip = "Which bones keep their clip movement (scaled to the model's size); the others keep the model's bone lengths"
        view.addChild(HStack(spacing: 6, [rotation, translation]))

        let target = graph.preview.flatMap(AssetReference.init).flatMap { session.assets?.animationSkeleton(of: $0) }
        let source = clipSkeleton()
        if let target, let source {
            let map = AnimationRetargetMap(source: source.skeleton, target: target, options: options)
            let used = Set(map.sourceOfTarget.compactMap { $0 })
            let loose = source.animated.filter { !used.contains($0) }.map { source.skeleton.bones[$0].name }.sorted()
            var summary = "\(map.matchedCount) of \(target.count) model bones matched"
            if !loose.isEmpty { summary += "; animated clip bones with no match: " + loose.prefix(8).joined(separator: ", ") + (loose.count > 8 ? "…" : "") }
            view.addChild(note(summary))
        } else {
            view.addChild(note("Pick a preview model and a clip from an imported file to see which bones match."))
        }
        for (from, to) in options.boneMap.sorted(by: { $0.key < $1.key }) {
            let remove = Button("✕", name: "animGraphBoneMapRemove") { set("Remove Bone Mapping") { $0.boneMap[from] = nil } }
            remove.tooltip = "Remove this mapping"
            view.addChild(HStack(spacing: 6, [Label("\(from) → \(to)", role: .caption, name: "animGraphBoneMap"), Spacer(), remove]))
        }
        if let target, let source {
            let sourceNames = source.skeleton.names, targetNames = target.names
            var pickedSource = 0, pickedTarget = 0
            let from = Dropdown(options: sourceNames, selectedIndex: 0, name: "animGraphBoneMapFrom") { pickedSource = $0 }
            from.tooltip = "A bone of the clip"
            let to = Dropdown(options: targetNames, selectedIndex: 0, name: "animGraphBoneMapTo") { pickedTarget = $0 }
            to.tooltip = "The model bone it drives"
            let add = Button("Map", name: "animGraphBoneMapAdd") {
                guard sourceNames.indices.contains(pickedSource), targetNames.indices.contains(pickedTarget) else { return }
                set("Map Bone") { $0.boneMap[sourceNames[pickedSource]] = targetNames[pickedTarget] }
            }
            add.tooltip = "Drive the model bone with this clip bone, whatever their names"
            view.addChild(HStack(spacing: 6, [from, to, add]))
        }
    }

    private func addParametersSection() {
        view.addChild(Label("Parameters", role: .secondary))
        for parameter in graph.parameters {
            let row = HStack(spacing: 6, name: "animGraphParam")
            let name = Button(parameter.name + " · " + parameter.type.rawValue, name: "animGraphParamName") { [unowned self] in
                selectedParameter = selectedParameter == parameter.name ? nil : parameter.name
                layout()
            }
            name.tooltip = "Edit this parameter's name and default"
            row.addChild(name)
            row.addChild(Spacer())
            switch parameter.type {
            case .float:
                let current: Float = { if case .float(let v)? = liveValue(parameter.name) { return v }; return parameter.defaultValue }()
                let field = NumberField(value: Double(current), step: 0.05, name: "animGraphLive")
                field.preferredWidth = 70
                field.onChange = { [unowned self] v in onSetLive?(parameter.name, .float(Float(v))) }
                field.tooltip = "Drive the preview (not saved)"
                liveControls.append((parameter.name, { [unowned self, unowned field] in
                    if !field.isInteracting, case .float(let v)? = liveValue(parameter.name), Double(v) != field.value { field.setValue(Double(v)) }
                }))
                row.addChild(field)
            case .bool:
                let current: Bool = { if case .bool(let v)? = liveValue(parameter.name) { return v }; return parameter.defaultValue != 0 }()
                let toggle = Checkbox("", isOn: current, kind: .toggleSwitch, name: "animGraphLive") { [unowned self] on in
                    onSetLive?(parameter.name, .bool(on))
                }
                toggle.tooltip = "Drive the preview (not saved)"
                liveControls.append((parameter.name, { [unowned self, unowned toggle] in
                    if case .bool(let v)? = liveValue(parameter.name), v != toggle.isOn { toggle.isOn = v }
                }))
                row.addChild(toggle)
            case .trigger:
                let fire = Button("Fire", name: "animGraphLive") { [unowned self] in onSetLive?(parameter.name, .trigger(true)) }
                fire.tooltip = "Set the trigger in the preview"
                row.addChild(fire)
            }
            let remove = Button("✕", name: "animGraphParamRemove") { [unowned self] in
                var edited = graph
                edited.parameters.removeAll { $0.name == parameter.name }
                apply(edited, label: "Remove Parameter")
            }
            remove.tooltip = "Remove this parameter"
            row.addChild(remove)
            view.addChild(row)
            if selectedParameter == parameter.name { addParameterGrid(parameter) }
        }
        let adds = HStack(spacing: 4, name: "animGraphAddParams")
        for type in AnimationGraphParameterType.allCases {
            let add = Button("+ " + type.rawValue.capitalized, name: "animGraphAdd\(type.rawValue.capitalized)") { [unowned self] in
                var edited = graph
                let name = edited.uniqueParameterName(type == .float ? "speed" : type == .bool ? "grounded" : "jump")
                edited.parameters.append(AnimationGraphParameter(name: name, type: type))
                selectedParameter = name
                apply(edited, label: "Add Parameter")
            }
            add.command = AnimGraphEditCommand.id.rawValue
            add.tooltip = "Add a \(type.rawValue) parameter"
            adds.addChild(add)
        }
        adds.addChild(Spacer())
        view.addChild(adds)
    }

    private func addGrid<C: Component>(_ component: C, name: String, onEnd: @escaping (C) -> Void) {
        let entity = gridWorld.spawn(component)
        proxies.append(entity)
        let grid = PropertyGrid(world: gridWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 96
        grid.entity = entity
        grid.command = AnimGraphEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: C.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Animation graph \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let value = gridWorld.get(C.self, for: entity) { onEnd(value) }
        }
        grids.append(grid)
        view.addChild(grid)
    }

    private func addParameterGrid(_ parameter: AnimationGraphParameter) {
        addGrid(AnimGraphParameterComponent(name: parameter.name, defaultValue: parameter.defaultValue), name: "animGraphParamGrid") {
            [unowned self] value in
            var edited = graph
            guard let i = edited.parameters.firstIndex(where: { $0.name == parameter.name }) else { return }
            edited.parameters[i].defaultValue = value.defaultValue
            let newName = value.name.trimmingCharacters(in: .whitespaces)
            if !newName.isEmpty, newName != parameter.name, edited.parameter(named: newName) == nil {
                edited.renameParameter(parameter.name, to: newName)
                selectedParameter = newName
            }
            apply(edited, label: "Edit Parameter")
        }
    }

    // MARK: Selection

    private func addSelectionSection() {
        let add = Button("Add State", name: "animGraphAddState") { [unowned self] in addState() }
        add.command = AnimGraphEditCommand.id.rawValue
        add.tooltip = "Add a state playing a clip"
        let delete = Button("Delete", name: "animGraphDelete") { [unowned self] in deleteSelected() }
        delete.tooltip = "Delete the selected state or transition"
        delete.isEnabled = selection != .none && selection != .anyState
        view.addChild(HStack(spacing: 6, [add, delete, Spacer()]))
        switch selection {
        case .state(let name):
            if let state = graph.state(named: name) { addStateEditor(state) }
        case .transition(let i):
            if graph.transitions.indices.contains(i) { addTransitionEditor(graph.transitions[i], index: i) }
        case .anyState:
            view.addChild(Label("Any State", role: .secondary))
            view.addChild(note("Transitions from Any State are checked from every state. Drag from its port to a state, or:"))
            addNewTransitionRow(from: nil)
        case .none:
            view.addChild(note("Click a node to edit it. Drag from a node's port (the dot on its right) to another node to add a "
                               + "transition; drag nodes to arrange them. Parameters drive the preview live."))
        }
    }

    private func clipDropdown(_ current: String?, name: String, onPick: @escaping (String) -> Void) -> Dropdown {
        var keys = session.animationClipChoices(for: graph)
        if let current, !current.isEmpty, !keys.contains(current) { keys.insert(current, at: 0) }
        let options = keys.isEmpty ? ["(no clips: import a glTF with animations)"] : keys.map { session.clipDisplayName($0) }
        let picker = Dropdown(options: options, selectedIndex: current.flatMap { keys.firstIndex(of: $0) } ?? 0, name: name) { index in
            if keys.indices.contains(index) { onPick(keys[index]) }
        }
        picker.isEnabled = !keys.isEmpty
        picker.tooltip = "The clip (from the preview model first)"
        return picker
    }

    private func addStateEditor(_ state: AnimationGraphState) {
        let isInitial = (graph.initialState.flatMap { graph.state(named: $0)?.name } ?? graph.states.first?.name) == state.name
        let initial = Button(isInitial ? "Initial State" : "Set as Initial", name: "animGraphSetInitial") { [unowned self] in
            var edited = graph
            edited.initialState = state.name
            apply(edited, label: "Set Initial State")
        }
        initial.isEnabled = !isInitial
        view.addChild(HStack(spacing: 6, [Label("State: \(state.name)", role: .secondary), Spacer(), initial]))
        addGrid(AnimGraphStateComponent(name: state.name, speed: state.speed, speedParameter: state.speedParameter ?? "", loops: state.loops),
                name: "animGraphStateGrid") { [unowned self] value in
            var edited = graph
            guard let i = edited.states.firstIndex(where: { $0.name == state.name }) else { return }
            edited.states[i].speed = value.speed
            edited.states[i].loops = value.loops
            edited.states[i].speedParameter = value.speedParameter.isEmpty ? nil : value.speedParameter
            let newName = value.name.trimmingCharacters(in: .whitespaces)
            if !newName.isEmpty, newName != state.name {
                if edited.state(named: newName) != nil {
                    session.log.warning("Animation graph: a state is already named \(newName)")
                } else {
                    edited.renameState(state.name, to: newName)
                    selection = .state(newName)
                    Self.selections[asset] = selection
                }
            }
            apply(edited, label: "Edit State")
        }
        let motionIndex = state.machine != nil ? 3 : state.blend == nil ? 0 : state.blend!.is2D ? 2 : 1
        let motion = Dropdown(options: ["One clip", "1D blend space", "2D blend space", "Sub-state machine"], selectedIndex: motionIndex,
                              name: "animGraphMotion") {
            [unowned self] index in
            editState("Change Motion") { s in
                let floats = graph.parameters.filter { $0.type == .float }.map(\.name)
                if index == 3 {
                    guard s.machine == nil else { return }
                    // The state's motion becomes the machine's first state.
                    var inner = s
                    inner.name = "Start"
                    inner.position = .zero
                    s.machine = AnimationGraphMachine(states: [inner], initialState: inner.name)
                    s.clip = nil
                    s.blend = nil
                    return
                }
                if let machine = s.machine {
                    // Back to a clip: the machine's first clip.
                    s.machine = nil
                    s.clip = machine.states.flatMap(\.clips).first
                    if index == 0 { return }
                }
                if index == 0, let blend = s.blend {
                    s.clip = blend.clips.first?.clip
                    s.blend = nil
                    return
                }
                guard index > 0 else { return }
                if s.blend == nil {
                    s.blend = AnimationGraphBlend(parameter: floats.first ?? "", clips: s.clip.map { [AnimationGraphBlendClip(clip: $0, position: 0)] } ?? [])
                    s.clip = nil
                }
                if index == 2, s.blend?.parameterY == nil {
                    let x = s.blend?.parameter
                    s.blend?.parameterY = floats.first { $0 != x } ?? floats.first ?? ""
                    for k in s.blend!.clips.indices where s.blend!.clips[k].y == nil { s.blend!.clips[k].y = 0 }
                } else if index == 1, s.blend?.parameterY != nil {
                    s.blend?.parameterY = nil
                    for k in s.blend!.clips.indices { s.blend!.clips[k].y = nil }
                }
            }
        }
        motion.tooltip = "Play one clip, mix clips by one float parameter (1D) or two (2D, e.g. strafe direction), or nest a state machine"
        view.addChild(HStack(spacing: 6, [Label("Motion"), Spacer(), motion]))
        if let machine = state.machine {
            let open = Button("Open Sub-Machine", role: .primary, name: "animGraphOpenMachine") { [unowned self] in enter(state.name) }
            open.tooltip = "Edit the states inside (or double-click the node)"
            view.addChild(HStack(spacing: 6, [open, Spacer()]))
            let entry = machine.initialState ?? machine.states.first?.name ?? "none"
            view.addChild(note("\(machine.states.count) state\(machine.states.count == 1 ? "" : "s") inside, entered at \(entry). This state's transitions leave from any of them."))
        } else if let blend = state.blend {
            let floats = graph.parameters.filter { $0.type == .float }.map(\.name)
            let options = floats.isEmpty ? ["(add a float parameter)"] : floats
            let parameter = Dropdown(options: options, selectedIndex: floats.firstIndex(of: blend.parameter) ?? 0, name: "animGraphBlendParam") {
                [unowned self] index in
                guard floats.indices.contains(index) else { return }
                editState("Set Blend Parameter") { $0.blend?.parameter = floats[index] }
            }
            parameter.isEnabled = !floats.isEmpty
            view.addChild(HStack(spacing: 6, [Label(blend.is2D ? "Parameter X" : "Parameter"), Spacer(), parameter]))
            if let parameterY = blend.parameterY {
                let y = Dropdown(options: options, selectedIndex: floats.firstIndex(of: parameterY) ?? 0, name: "animGraphBlendParamY") {
                    [unowned self] index in
                    guard floats.indices.contains(index) else { return }
                    editState("Set Blend Parameter") { $0.blend?.parameterY = floats[index] }
                }
                y.isEnabled = !floats.isEmpty
                view.addChild(HStack(spacing: 6, [Label("Parameter Y"), Spacer(), y]))
                addBlend2DPlot(blend, x: blend.parameter, y: parameterY)
            }
            for (k, entry) in blend.clips.enumerated() {
                let clip = clipDropdown(entry.clip, name: "animGraphBlendClip") { [unowned self] key in
                    editState("Set Blend Clip") { $0.blend?.clips[k].clip = key }
                }
                clip.style.shrink = 1
                let position = NumberField(value: Double(entry.position), step: 0.05, name: "animGraphBlendPosition")
                position.preferredWidth = 56
                position.tooltip = "Where this clip sits along the parameter"
                position.onEditEnded = { [unowned self] _, end in editState("Move Blend Clip") { $0.blend?.clips[k].position = Float(end) } }
                let remove = Button("✕", name: "animGraphBlendRemove") { [unowned self] in
                    editState("Remove Blend Clip") { _ = $0.blend?.clips.remove(at: k) }
                }
                if blend.is2D {
                    position.tooltip = "Where this clip sits along parameter X"
                    let y = NumberField(value: Double(entry.y ?? 0), step: 0.05, name: "animGraphBlendPositionY")
                    y.preferredWidth = 56
                    y.tooltip = "Where this clip sits along parameter Y"
                    y.onEditEnded = { [unowned self] _, end in editState("Move Blend Clip") { $0.blend?.clips[k].y = Float(end) } }
                    view.addChild(HStack(spacing: 4, [clip, position, y, remove]))
                } else {
                    view.addChild(HStack(spacing: 4, [clip, position, remove]))
                }
            }
            let addClip = Button("Add Clip", name: "animGraphBlendAdd") { [unowned self] in
                editState("Add Blend Clip") { s in
                    let next = (s.blend?.clips.map(\.position).max() ?? -1) + 1
                    let key = session.animationClipChoices(for: graph).first ?? ""
                    let is2D = s.blend?.is2D == true
                    s.blend?.clips.append(AnimationGraphBlendClip(clip: key, position: next, y: is2D ? 0 : nil))
                }
            }
            view.addChild(HStack(spacing: 6, [addClip, Spacer()]))
        } else {
            view.addChild(clipDropdown(state.clip, name: "animGraphClip") { [unowned self] key in editState("Set Clip") { $0.clip = key } })
        }
        if state.machine == nil { addEventsSection(state) }
        view.addChild(Label("Transitions from \(state.name)", role: .secondary))
        for (i, t) in graph.transitions.enumerated() where t.from == state.name {
            let go = Button("→ \(t.to)  ·  \(t.conditions.count) condition\(t.conditions.count == 1 ? "" : "s")", name: "animGraphGoTransition") {
                [unowned self] in select(.transition(i))
            }
            view.addChild(HStack(spacing: 6, [go, Spacer()]))
        }
        addNewTransitionRow(from: state.name)
    }

    /// The 2D blend space's points, with the live value as a cross that dragging moves.
    private func addBlend2DPlot(_ blend: AnimationGraphBlend, x: String, y: String) {
        let plot = BlendSpace2DPlot()
        plot.points = blend.clips.map { BlendSpace2DPlot.Point(label: session.clipDisplayName($0.clip).components(separatedBy: " › ").last ?? $0.clip,
                                                               position: Vec2($0.position, $0.y ?? 0)) }
        plot.axisNames = (x, y)
        func live(_ name: String) -> Float {
            if case .float(let v)? = liveValue(name) { return v }
            return graph.parameter(named: name)?.defaultValue ?? 0
        }
        plot.value = Vec2(live(x), live(y))
        plot.onPick = { [unowned self] p in
            onSetLive?(x, .float(p.x))
            onSetLive?(y, .float(p.y))
        }
        plot.tooltip = "Clips at their points (bigger: more weight now); drag to try values on the preview"
        liveControls.append((x, { [unowned plot] in plot.value = Vec2(live(x), live(y)) }))
        view.addChild(plot)
    }

    /// The events of the selected state's clip (one of them, for a blend space), editable when
    /// the clip comes from a glTF file (`EditorSession.setClipEvents`).
    private func addEventsSection(_ state: AnimationGraphState) {
        var clips: [String] = []
        for key in state.clips where !key.isEmpty && !clips.contains(key) { clips.append(key) }
        guard !clips.isEmpty else { return }
        let key = eventsClip.flatMap { clips.contains($0) ? $0 : nil } ?? clips[0]
        view.addChild(Label("Clip Events", role: .secondary))
        if clips.count > 1 {
            let pick = Dropdown(options: clips.map { session.clipDisplayName($0) }, selectedIndex: clips.firstIndex(of: key) ?? 0,
                                name: "animGraphEventsClip") { [unowned self] index in
                eventsClip = clips[index]
                layout()
            }
            pick.tooltip = "Which of the state's clips to show events of"
            view.addChild(pick)
        }
        guard let events = session.clipEvents(key) else {
            view.addChild(note("The clip isn't imported yet."))
            return
        }
        let editable = session.editableClip(key) != nil
        let duration = session.assets.flatMap { AssetReference(key).flatMap($0.animationClip) }?.duration ?? 0
        func write(_ events: [AnimationEvent], _ label: String) {
            session.setClipEvents(events, of: key, label: label)
            layout()
        }
        if events.isEmpty { view.addChild(note(editable ? "No events. Add one to fire it as the clip plays past its time." : "No events.")) }
        for (k, event) in events.enumerated() {
            let time = NumberField(value: Double(event.time), step: 0.01, name: "animGraphEventTime")
            time.preferredWidth = 64
            time.tooltip = "Seconds from the clip's start (it lasts \(String(format: "%.2f", duration)) s)"
            time.isEnabled = editable
            time.onEditEnded = { _, end in
                var edited = events
                edited[k].time = min(max(Float(end), 0), duration)
                write(edited, "Move Clip Event")
            }
            let name = TextField(text: event.name, placeholder: "event name", name: "animGraphEventName")
            name.isEnabled = editable
            name.style.shrink = 1
            name.onEndEditing = { text in
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, trimmed != event.name else { return }
                var edited = events
                edited[k].name = trimmed
                write(edited, "Rename Clip Event")
            }
            let remove = Button("✕", name: "animGraphEventRemove") {
                var edited = events
                edited.remove(at: k)
                write(edited, "Remove Clip Event")
            }
            remove.isEnabled = editable
            view.addChild(HStack(spacing: 4, [time, name, remove]))
        }
        guard editable else {
            view.addChild(note("Only clips imported from glTF files have editable events."))
            return
        }
        let add = Button("Add Event", name: "animGraphEventAdd") { [unowned self] in
            // At the preview's time when it plays this state, else at the start.
            var time: Float = 0
            if let playing = previewPlayback(), levelState(ofPlaying: playing.state) == state.name, path.count + 1 == playing.state.components(separatedBy: "/").count {
                time = playing.phase * duration
            }
            var name = "event", n = 2
            while events.contains(where: { $0.name == name }) { name = "event\(n)"; n += 1 }
            write(events + [AnimationEvent(time: time, name: name)], "Add Clip Event")
        }
        add.command = AnimGraphSetClipEventsCommand.id.rawValue
        add.tooltip = "Add an event at the preview's current time in this state (game code and scripts receive it as the clip passes it)"
        view.addChild(HStack(spacing: 6, [add, Spacer()]))
    }

    private func addNewTransitionRow(from: String?) {
        let targets = graph.states.map(\.name).filter { $0 != from || from == nil } + outerStateNames
        guard !targets.isEmpty else { return }
        var target = 0
        let labels = targets.map { graph.state(named: $0) == nil ? "↑ " + $0 : $0 }
        let to = Dropdown(options: labels, selectedIndex: 0, name: "animGraphNewTransitionTarget") { index in target = index }
        let add = Button("Add Transition", name: "animGraphAddTransition") { [unowned self] in
            if targets.indices.contains(target) { connect(from: from, to: targets[target]) }
        }
        add.command = AnimGraphEditCommand.id.rawValue
        view.addChild(HStack(spacing: 6, [to, add, Spacer()]))
    }

    private func addTransitionEditor(_ t: AnimationGraphTransition, index: Int) {
        view.addChild(Label("Transition \(index): \(t.from ?? "Any State") → \(t.to)", role: .secondary))
        let up = Button("Earlier", name: "animGraphTransitionUp") { [unowned self] in moveTransition(index, by: -1) }
        up.isEnabled = index > 0
        up.tooltip = "Check this transition before the one above it (the first that applies fires)"
        let down = Button("Later", name: "animGraphTransitionDown") { [unowned self] in moveTransition(index, by: 1) }
        down.isEnabled = index < graph.transitions.count - 1
        view.addChild(HStack(spacing: 6, [up, down, Spacer()]))
        addGrid(AnimGraphTransitionComponent(duration: t.duration, hasExitTime: t.exitTime != nil, exitAt: t.exitTime ?? 1,
                                             canTransitionToSelf: t.canTransitionToSelf), name: "animGraphTransitionGrid") {
            [unowned self] value in
            editTransition("Edit Transition") { t in
                t.duration = max(value.duration, 0)
                t.exitTime = value.hasExitTime ? max(value.exitAt, 0) : nil
                t.canTransitionToSelf = value.canTransitionToSelf
            }
        }
        view.addChild(Label("Conditions (all must hold)", role: .secondary))
        let names = graph.parameters.map(\.name)
        for (k, condition) in t.conditions.enumerated() {
            var options = names
            if !options.contains(condition.parameter) { options.insert(condition.parameter, at: 0) }
            let parameter = Dropdown(options: options.isEmpty ? ["(none)"] : options, selectedIndex: options.firstIndex(of: condition.parameter) ?? 0,
                                     name: "animGraphConditionParam") { [unowned self] i in
                guard options.indices.contains(i) else { return }
                editTransition("Edit Condition") { t in
                    t.conditions[k].parameter = options[i]
                    if let type = graph.parameter(named: options[i])?.type, t.conditions[k].test.parameterType != type {
                        t.conditions[k].test = type == .float ? .greater : type == .bool ? .isTrue : .triggered
                    }
                }
            }
            parameter.style.shrink = 1
            let tests = AnimationGraphTest.allCases
            let test = Dropdown(options: tests.map(\.rawValue), selectedIndex: tests.firstIndex(of: condition.test) ?? 0, name: "animGraphConditionTest") {
                [unowned self] i in editTransition("Edit Condition") { $0.conditions[k].test = tests[i] }
            }
            var row: [Widget] = [parameter, test]
            if condition.test == .greater || condition.test == .less {
                let value = NumberField(value: Double(condition.value), step: 0.05, name: "animGraphConditionValue")
                value.preferredWidth = 52
                value.onEditEnded = { [unowned self] _, end in editTransition("Edit Condition") { $0.conditions[k].value = Float(end) } }
                row.append(value)
            }
            row.append(Button("✕", name: "animGraphConditionRemove") { [unowned self] in
                editTransition("Remove Condition") { _ = $0.conditions.remove(at: k) }
            })
            view.addChild(HStack(spacing: 4, row))
        }
        let addCondition = Button("Add Condition", name: "animGraphAddCondition") { [unowned self] in
            editTransition("Add Condition") { t in
                let p = graph.parameters.first
                t.conditions.append(AnimationGraphCondition(parameter: p?.name ?? "", test: p.map { $0.type == .float ? .greater : $0.type == .bool ? .isTrue : .triggered } ?? .greater))
            }
        }
        addCondition.isEnabled = !graph.parameters.isEmpty
        addCondition.tooltip = graph.parameters.isEmpty ? "Add a parameter first" : "Test a parameter"
        view.addChild(HStack(spacing: 6, [addCondition, Spacer()]))
        if t.conditions.isEmpty && t.exitTime == nil {
            view.addChild(note("With no conditions and no exit time this transition never fires."))
        }
    }

    private func moveTransition(_ index: Int, by delta: Int) {
        let target = index + delta
        guard graph.transitions.indices.contains(index), graph.transitions.indices.contains(target) else { return }
        var edited = graph
        edited.transitions.swapAt(index, target)
        selection = .transition(target)
        Self.selections[asset] = selection
        apply(edited, label: "Reorder Transitions")
    }

    // MARK: Layers

    private func addLayersSection() {
        view.addChild(Label("Layers", role: .secondary))
        for layer in graph.layers {
            let name = Button(layer.name, name: "animGraphLayerName") { [unowned self] in
                selectedLayer = selectedLayer == layer.name ? nil : layer.name
                layout()
            }
            let clip = clipDropdown(layer.clip, name: "animGraphLayerClip") { [unowned self] key in
                var edited = graph
                guard let i = edited.layers.firstIndex(where: { $0.name == layer.name }) else { return }
                edited.layers[i].clip = key
                apply(edited, label: "Set Layer Clip")
            }
            clip.style.shrink = 1
            let remove = Button("✕", name: "animGraphLayerRemove") { [unowned self] in
                var edited = graph
                edited.layers.removeAll { $0.name == layer.name }
                apply(edited, label: "Remove Layer")
            }
            view.addChild(HStack(spacing: 4, [name, clip, remove]))
            if selectedLayer == layer.name {
                addGrid(AnimGraphLayerComponent(name: layer.name, weight: layer.weight, speed: layer.speed, referenceTime: layer.referenceTime),
                        name: "animGraphLayerGrid") { [unowned self] value in
                    var edited = graph
                    guard let i = edited.layers.firstIndex(where: { $0.name == layer.name }) else { return }
                    edited.layers[i].weight = min(max(value.weight, 0), 1)
                    edited.layers[i].speed = value.speed
                    edited.layers[i].referenceTime = value.referenceTime
                    let newName = value.name.trimmingCharacters(in: .whitespaces)
                    if !newName.isEmpty, newName != layer.name, !edited.layers.contains(where: { $0.name == newName }) {
                        edited.layers[i].name = newName
                        selectedLayer = newName
                    }
                    apply(edited, label: "Edit Layer")
                }
                addLayerBlendAndMask(layer)
            }
        }
        let add = Button("Add Layer", name: "animGraphAddLayer") { [unowned self] in
            var edited = graph
            let name = edited.uniqueLayerName("Layer")
            edited.layers.append(AnimationGraphLayer(name: name, clip: session.animationClipChoices(for: graph).first ?? ""))
            selectedLayer = name
            apply(edited, label: "Add Layer")
        }
        add.command = AnimGraphEditCommand.id.rawValue
        add.tooltip = "Add a clip on top of the states (additive: its difference from its first frame is added; override: it replaces the bones it animates)"
        view.addChild(HStack(spacing: 6, [add, Spacer()]))
    }

    // MARK: IK

    /// The graph's IK nodes (run after the states and layers): pick one to edit, add, remove.
    private func addIKSection() {
        view.addChild(Label("IK", role: .secondary))
        if graph.ik.isEmpty {
            view.addChild(note("No IK. Add two-bone (arms, legs), aim (look at), chain (FABRIK: tails) or foot placement nodes; they run after the states and layers, in order."))
        }
        for node in graph.ik {
            let name = Button(node.name, role: selectedIK == node.name ? .primary : .normal, name: "animGraphIKName") { [unowned self] in
                selectedIK = selectedIK == node.name ? nil : node.name
                layout()
            }
            let remove = Button("✕", name: "animGraphIKRemove") { [unowned self] in
                var edited = graph
                edited.ik.removeAll { $0.name == node.name }
                apply(edited, label: "Remove IK")
            }
            remove.tooltip = "Remove this IK node"
            view.addChild(HStack(spacing: 4, [name, Label(node.type.rawValue, role: .caption), Spacer(), remove]))
            if selectedIK == node.name {
                addGrid(AnimGraphIKComponent(node), name: "animGraphIKGrid") { [unowned self] value in
                    var edited = graph
                    guard let i = edited.ik.firstIndex(where: { $0.name == node.name }) else { return }
                    edited.ik[i] = value.applied(to: edited.ik[i])
                    let newName = value.name.trimmingCharacters(in: .whitespaces)
                    if !newName.isEmpty, newName != node.name, !edited.ik.contains(where: { $0.name == newName }) {
                        edited.ik[i].name = newName
                        selectedIK = newName
                    }
                    apply(edited, label: "Edit IK")
                }
            }
        }
        let types = AnimationIKType.allCases
        let type = Dropdown(options: types.map(\.rawValue), selectedIndex: min(newIKType, types.count - 1), name: "animGraphIKType") { [unowned self] i in
            newIKType = i
        }
        type.tooltip = "twoBoneIK: an arm or leg reaches a point; aim: a chain turns to look; chainIK: FABRIK for tails; footPlacement: feet on uneven ground"
        let add = Button("Add IK", name: "animGraphAddIK") { [unowned self] in
            let kind = types[min(newIKType, types.count - 1)]
            var edited = graph
            let name = edited.uniqueIKName(kind == .footPlacement ? "Feet" : kind == .aim ? "Look" : kind.rawValue)
            var node = kind == .footPlacement ? AnimationIKNode.humanoidFeet(name: name) : AnimationIKNode(name: name, type: kind)
            if kind == .aim { node.bones = ["spine", "chest", "neck", "head"] }
            if kind == .twoBoneIK { node.bones = ["upperArm.R", "lowerArm.R", "hand.R"] }
            edited.ik.append(node)
            selectedIK = name
            apply(edited, label: "Add IK")
        }
        add.command = AnimGraphEditCommand.id.rawValue
        add.tooltip = "Add an IK node (bones default to a Character Builder humanoid's; edit them for other rigs)"
        view.addChild(HStack(spacing: 6, [type, add, Spacer()]))
    }

    private func editLayer(_ name: String, _ label: String, _ change: (inout AnimationGraphLayer) -> Void) {
        var edited = graph
        guard let i = edited.layers.firstIndex(where: { $0.name == name }) else { return }
        change(&edited.layers[i])
        apply(edited, label: label)
    }

    /// The selected layer's blend mode and bone mask.
    private func addLayerBlendAndMask(_ layer: AnimationGraphLayer) {
        let blend = Dropdown(options: ["Additive", "Override"], selectedIndex: layer.isOverride ? 1 : 0, name: "animGraphLayerBlend") {
            [unowned self] index in
            editLayer(layer.name, "Set Layer Blend") { $0.blend = index == 1 ? .override : nil }
        }
        blend.tooltip = "Additive adds the clip's motion; override replaces the bones the clip animates, mixed in by the weight"
        view.addChild(HStack(spacing: 6, [Label("Blend"), Spacer(), blend]))
        let skeleton = graph.preview.flatMap(AssetReference.init).flatMap { session.assets?.animationSkeleton(of: $0) }
        let mask = layer.mask ?? []
        if mask.isEmpty {
            view.addChild(note("Affects every bone. Add a mask bone to limit the layer to that bone and the bones below it."))
        } else {
            if let skeleton {
                let count = Animator.maskTargets(mask, in: skeleton).count
                view.addChild(note("Affects \(count) of \(skeleton.count) bones of the preview model."))
            }
            for bone in mask {
                let remove = Button("✕", name: "animGraphLayerMaskRemove") { [unowned self] in
                    editLayer(layer.name, "Remove Mask Bone") { l in
                        l.mask?.removeAll { $0 == bone }
                        if l.mask?.isEmpty == true { l.mask = nil }
                    }
                }
                remove.tooltip = "Stop limiting the layer to this bone's subtree"
                view.addChild(HStack(spacing: 6, [Label("Mask: " + bone, role: .caption, name: "animGraphLayerMaskBone"), Spacer(), remove]))
            }
        }
        guard let skeleton else {
            view.addChild(note("Pick a preview model to choose mask bones."))
            return
        }
        let depths = skeleton.depths
        let names = skeleton.names
        let labels = names.indices.map { String(repeating: "  ", count: min(depths[$0], 12)) + (names[$0].isEmpty ? "(unnamed)" : names[$0]) }
        var picked = 0
        let bones = Dropdown(options: labels, selectedIndex: 0, name: "animGraphLayerMaskPick") { picked = $0 }
        bones.tooltip = "A bone of the preview model; the layer affects it and every bone below it"
        bones.style.shrink = 1
        let add = Button("Add to Mask", name: "animGraphLayerMaskAdd") { [unowned self] in
            guard names.indices.contains(picked), !names[picked].isEmpty, !mask.contains(names[picked]) else { return }
            editLayer(layer.name, "Add Mask Bone") { $0.mask = ($0.mask ?? []) + [names[picked]] }
        }
        view.addChild(HStack(spacing: 6, [bones, add]))
    }
}
