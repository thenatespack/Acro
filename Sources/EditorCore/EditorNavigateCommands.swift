import Engine
import Foundation

// Getting around the Scene view: Return to Origin (`view.home`, Home) puts the camera back on
// the origin from the default angle; Go to Object (`view.goTo`, Cmd/Ctrl+G) finds an entity by
// name, selects it and frames it the way `view.frameSelection` does. In the editor, Cmd/Ctrl+G
// opens `GoToObjectDialog`, which filters the scene's entities as you type.

/// The Scene view's camera after `view.home` / `view.goTo`.
public struct ViewCameraResult: Codable, Equatable, Sendable {
    /// The point the camera orbits and looks at.
    public var pivot: Vec3
    /// The camera position.
    public var eye: Vec3
    /// Radians about +Y (0 looks down -Z).
    public var yaw: Float
    /// Radians; positive looks down.
    public var pitch: Float
    /// Meters from the eye to the pivot.
    public var distance: Float

    init(_ camera: EditorCamera) {
        pivot = camera.pivot
        eye = camera.eye
        yaw = camera.yaw
        pitch = camera.pitch
        distance = camera.distance
    }
}

public enum ViewHomeCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Look at this point instead of the origin's home pivot [0, 0.5, 0].
        public var pivot: Vec3?
        /// Meters from the pivot (default 15).
        public var distance: Float?
        public init(pivot: Vec3? = nil, distance: Float? = nil) {
            self.pivot = pivot
            self.distance = distance
        }
    }

    public static let id: CommandID = .returnHome
    public static let title = "Return to Origin"
    public static let doc = """
        Puts the Scene view's camera back on its default view of the origin (Home key, View menu): pivot [0, 0.5, 0], \
        the default yaw and pitch, 15 m away. `pivot` and `distance` aim it elsewhere from the same angle. Returns the \
        camera. Needs the editor window.
        """
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.host != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noWindowReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ViewCameraResult {
        if let distance = arguments.distance, !(distance > 0) || !distance.isFinite {
            throw CommandError.failed("distance must be a positive number of meters")
        }
        guard let camera = session.host?.returnHome(pivot: arguments.pivot, distance: arguments.distance) else {
            throw CommandError.failed("\(title): \(noWindowReason)")
        }
        return ViewCameraResult(camera)
    }
}

public enum ViewGoToCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The entity to go to.
        public var entity: EntityID?
        /// Or its name (any case): a whole name or "Parent/Child" path first, else part of one. A name more than one entity matches is an error listing them.
        public var name: String?
        public init(entity: EntityID? = nil, name: String? = nil) {
            self.entity = entity
            self.name = name
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entity: EntityID
        public var name: String
        /// Names from the root down, joined with "/".
        public var path: String
        /// The Scene view's camera after framing it.
        public var camera: ViewCameraResult?
    }

    public static let id: CommandID = .goToObject
    public static let title = "Go to Object"
    public static let doc = """
        Selects an entity and frames it in the Scene view, as Frame Selection does (in the editor, Cmd/Ctrl+G opens a \
        search that filters the scene's entities by name as you type). Give `entity`, or `name`: matched without regard \
        to case against whole names and "Parent/Child" paths first, then as part of a name. A name that matches more \
        than one entity fails and lists the candidates with their ids; pass one as `entity`. Needs the editor window.
        """
    public static func isAvailable(in session: EditorSession) -> Bool { session.host != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noWindowReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let match: EntityMatch
        if let id = arguments.entity {
            _ = try session.world.require(id)
            guard let found = candidates(in: session).first(where: { $0.id == id }) else { throw UndoError.entityNotFound(id) }
            match = found
        } else if let name = arguments.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
            let found = matches(for: name, in: candidates(in: session), exactFirst: true)
            switch found.count {
            case 0: throw CommandError.failed("No entity is named '\(name)' (entity.find lists them)")
            case 1: match = found[0]
            default:
                let list = found.prefix(20).map { "\($0.path) (\($0.id))" }.joined(separator: ", ")
                throw CommandError.failed("'\(name)' matches \(found.count) entities: \(list)\(found.count > 20 ? ", …" : ""). Pass one as `entity`")
            }
        } else {
            throw CommandError.failed("Give `entity` (an id) or `name`")
        }
        guard let host = session.host else { throw CommandError.failed("\(title): \(noWindowReason)") }
        let entity = try session.world.require(match.id)
        session.selection.set([match.id], primary: match.id)
        session.inspectedAsset = nil
        host.frame([entity])
        return Result(entity: match.id, name: match.name, path: match.path, camera: host.viewCamera.map(ViewCameraResult.init))
    }

    /// Every entity in the scene, in hierarchy order, with its path.
    static func candidates(in session: EditorSession) -> [EntityMatch] {
        (try? EntityFindCommand.run(.init(), in: session).entities) ?? []
    }

    /// The candidates `query` names, best first. With `exactFirst` (the MCP form), whole names and
    /// paths that equal `query` win outright; otherwise (and when none do) names that start with
    /// it come before names that contain it, then paths that contain it. Any case.
    static func matches(for query: String, in candidates: [EntityMatch], exactFirst: Bool = false) -> [EntityMatch] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return candidates }
        if exactFirst {
            let exact = candidates.filter { $0.name.lowercased() == q || $0.path.lowercased() == q }
            if !exact.isEmpty { return exact }
        }
        var prefix: [EntityMatch] = [], contains: [EntityMatch] = [], inPath: [EntityMatch] = []
        for candidate in candidates {
            let name = candidate.name.lowercased()
            if name.hasPrefix(q) {
                prefix.append(candidate)
            } else if name.contains(q) {
                contains.append(candidate)
            } else if candidate.path.lowercased().contains(q) {
                inPath.append(candidate)
            }
        }
        // With exact matching (MCP), a name is meant: paths only count when no name matches.
        if exactFirst { return prefix.isEmpty && contains.isEmpty ? inPath : prefix + contains }
        return prefix + contains + inPath
    }
}

/// The Go to Object search (Cmd/Ctrl+G, the View menu): a field over a list of the scene's
/// entities, filtered by name as you type. Up / Down move through the matches, Enter or a click
/// goes to one (`view.goTo`: select and frame), Esc closes it.
@MainActor
public final class GoToObjectDialog: Widget {
    public let field: TextField
    public let list: GoToObjectList
    private let card: VStack
    private let candidates: [EntityMatch]
    /// What the list shows, best match first.
    public private(set) var shown: [EntityMatch] = []
    /// Runs `view.goTo` for the picked entity (the dialog has closed by then).
    public var onPick: ((EntityMatch) -> Void)?
    private var closed = false

    public init(candidates: [EntityMatch]) {
        self.candidates = candidates
        field = TextField(text: "", placeholder: "Go to object: type part of a name", name: "goToObjectField")
        list = GoToObjectList(name: "goToObjectList")
        let heading = Label("Go to Object", role: .heading, name: "goToObjectTitle")
        card = VStack(spacing: 8, padding: EdgeInsets(14), name: "goToObjectCard", [heading, field, list])
        super.init(name: "goToObjectDialog")
        card.background = .clear  // drawn by `draw`
        addChild(card)
        field.command = ViewGoToCommand.id.rawValue
        list.command = ViewGoToCommand.id.rawValue
        list.itemCommands = ["row": ViewGoToCommand.id.rawValue]
        list.preferredVisibleRows = 10
        field.onChange = { [unowned self] text in filter(text) }
        field.onSubmit = { [unowned self] _ in pickSelected() }
        field.onKey = { [unowned self] key in
            switch key.key {
            case .up: moveSelection(by: -1)
            case .down: moveSelection(by: 1)
            case .pageUp: moveSelection(by: -list.preferredVisibleRows)
            case .pageDown: moveSelection(by: list.preferredVisibleRows)
            default: return false
            }
            return true
        }
        list.onPick = { [unowned self] row in pick(row) }
        filter("")
    }

    public override var accessibilityRole: UIAccessibilityRole { .dialog }
    public override var accessibilityText: String? { "Go to Object" }

    /// Shows it over everything in `context` with the search field focused.
    public func present(in context: UIContext) {
        context.presentOverlay(self)
        context.focus(field)
    }

    /// Shows the entities `text` matches (all of them for no text), the best one selected.
    public func filter(_ text: String) {
        shown = ViewGoToCommand.matches(for: text, in: candidates)
        list.items = shown.map { $0.path == $0.name ? $0.name : "\($0.name) — \($0.path)" }
        list.selectRow(shown.isEmpty ? nil : 0)
    }

    private func moveSelection(by delta: Int) {
        guard !shown.isEmpty else { return }
        list.selectRow((list.selectedRow ?? -1) + delta)
    }

    /// Goes to the selected match (Enter).
    public func pickSelected() {
        guard let row = list.selectedRow ?? (shown.isEmpty ? nil : 0) else { return }
        pick(row)
    }

    private func pick(_ row: Int) {
        guard shown.indices.contains(row) else { return }
        let match = shown[row]
        close()
        onPick?(match)
    }

    public func close() {
        guard !closed else { return }
        closed = true
        context?.dismissOverlay(self)
    }

    public override func overlayDismissed() { closed = true }

    public override func overlayFrame(in viewport: UIRect) -> UIRect { viewport }

    public override func layoutChildren() {
        let theme = theme
        let width = min(theme.dialogMaxWidth + 80, max(frame.width - 32, 160))
        let height = card.measure(width: width).y
        // Near the top, as search popups sit, so the list grows down.
        card.layout(in: UIRect(x: (frame.x + (frame.width - width) / 2).rounded(), y: (frame.y + min(frame.height * 0.15, 120)).rounded(),
                               width: width, height: height))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e):
            // A click outside the card closes it; inside, nothing behind it reacts.
            if !card.frame.contains(e.position) { close() }
            return true
        case .pointerUp, .pointerMove, .pointerDrag, .scroll:
            return true
        case .key(let e) where e.key == .escape:
            close()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim.withAlpha(theme.modalDim.a * 0.5))
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2), radii: UICornerRadii(theme.dialogCornerRadius + 6))
        list.fillRect(card.frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }
}

/// The Go to Object matches: a list whose rows go to their entity on a single click.
@MainActor
public final class GoToObjectList: RowListView {
    public var items: [String] = [] {
        didSet { setNeedsLayout() }
    }
    var onPick: ((Int) -> Void)?

    public override var rowCount: Int { items.count }
    public override func rowAccessibilityLabel(_ row: Int) -> String? { items[row] }
    public override func rowActivated(_ row: Int) { onPick?(row) }

    public override func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool {
        selectRow(row)
        onPick?(row)
        return true
    }

    public override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let text = items[row], size = theme.fontSize, width = rect.width - 16
        guard width > 4 else { return }
        var layout = context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)
        if layout.width > width + 1 / scale, let short = TextEllipsis.fit(text, font: theme.font, size: size, width: width) {
            layout = context?.textLayout(short, size: size) ?? TextLayout(short, font: theme.font, size: size)
        }
        list.drawText(layout, font: theme.font, at: Vec2(snap(rect.x + 8), snap(rect.y + (rect.height - layout.height) / 2)), color: theme.textColor)
    }
}
