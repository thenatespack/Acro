import Engine

/// The viewport's selection and transform tool: the engine's `TransformGizmo` for the toolbar's
/// Move / Rotate / Scale mode, and `ScenePicker` for clicks that miss the gizmo.
///
/// A left press on a gizmo handle starts a drag inside an undo group (undo and redo are refused
/// while it is open), and the release records the whole drag as one step (`transform.set`, or
/// `GizmoEdit.record` without commands).
/// `cancelDrag` (Esc) puts every transform back. A left click that doesn't hit the gizmo and
/// doesn't travel more than `clickSlop` picks the nearest entity under the pointer, exactly
/// against its triangles: a plain click selects it (or clears the selection on empty space),
/// Shift or Cmd/Ctrl toggles it. Alt+left is left to the camera (orbit).
@MainActor
public final class TransformTool: ViewportTool {
    public let gizmo = TransformGizmo()
    public let picker: ScenePicker
    /// Pointer travel (points) after which a press no longer counts as a click.
    public var clickSlop: Float = 4
    private var pressPosition: Vec2?
    private var isGizmoDrag = false
    private var undo: UndoStack?

    /// Icons for the entities without a mesh (cameras, lights, audio, particles, triggers,
    /// sprites), drawn by the host over the viewport and picked by `picker` like meshes.
    public let billboards = ViewportBillboards()
    /// What gets a billboard (default: `EditorIcons.billboards(in:)`); nil shows none.
    public var billboardSource: ((World) -> [ViewportBillboard])? = { EditorIcons.billboards(in: $0) }

    public init(meshes: any PickMeshSource) {
        picker = ScenePicker(meshes: meshes)
        picker.billboards = billboards
        billboards.secondaryColor = UIColor(0.9, 0.36, 0.1)
    }

    /// Lays the billboards out for `view` (also run before every pick, so clicks see the current view).
    public func updateBillboards(view: ViewportProjection, world: World) {
        billboards.update(billboardSource?(world) ?? [], view: view, occluders: picker, world: world)
    }

    public var isDragging: Bool { gizmo.isDragging }

    public func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        if let button = event.button, button != .left { return false }
        gizmo.mode = Self.mode(for: context.toolMode)
        gizmo.snapping.isEnabled = context.snapping
        gizmo.snapping.translateStep = context.snapSteps.translateStep
        gizmo.snapping.rotateDegrees = context.snapSteps.rotateDegrees
        gizmo.snapping.scaleStep = context.snapSteps.scaleStep
        let view = ViewportProjection(context.view, size: context.viewportSize, pixelScale: context.pixelScale)
        let world = context.world
        let selection = context.selection.entities(in: world)
        let primary = context.selection.primaryEntity(in: world)
        let pointer = ViewportPointer(position: event.position, phase: Self.phase(event.phase), modifiers: event.modifiers)

        switch event.phase {
        case .moved:
            _ = gizmo.handle(pointer, view: view, world: world, selection: selection, primary: primary)  // hover highlight
            return false

        case .pressed:
            guard !event.modifiers.contains(.alt) else { return false }
            if let edit = gizmo.handle(pointer, view: view, world: world, selection: selection, primary: primary) {
                isGizmoDrag = true
                context.undo.beginGroup(edit.label)
                undo = context.undo
                return true
            }
            pressPosition = event.position
            return true

        case .dragged:
            if isGizmoDrag {
                _ = gizmo.handle(pointer, view: view, world: world, selection: selection, primary: primary)
                return true
            }
            if let start = pressPosition, length(Vec3(event.position - start, 0)) > clickSlop { pressPosition = nil }
            return true

        case .released:
            if isGizmoDrag {
                let edit = gizmo.handle(pointer, view: view, world: world, selection: selection, primary: primary)
                if let edit, edit.phase == .ended { record(edit, context: context) }
                finishGroup()
                return true
            }
            defer { pressPosition = nil }
            guard pressPosition != nil else { return true }
            updateBillboards(view: view, world: world)
            let hit = picker.pick(at: event.position, in: view, world: world)
            let id = hit.flatMap { world.id(of: $0.entity) }
            if event.modifiers.contains(.shift) || event.modifiers.contains(.shortcut) {
                if let id { context.selection.toggle(id) }
            } else {
                context.selection.select(id)
            }
            return true
        }
    }

    /// Cancels a gizmo drag (Esc), restoring every transform it changed. False when nothing was
    /// being dragged.
    @discardableResult
    public func cancelDrag(world: World) -> Bool {
        guard isGizmoDrag else { return false }
        _ = gizmo.cancel(world: world)
        finishGroup()
        return true
    }

    public func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {
        guard !context.selection.entities(in: context.world).isEmpty else { return }
        gizmo.mode = Self.mode(for: context.toolMode)
        let view = ViewportProjection(context.view, size: context.viewportSize, pixelScale: context.pixelScale)
        gizmo.draw(into: debugDraw, view: view, world: context.world, selection: context.selection.entities(in: context.world),
                   primary: context.selection.primaryEntity(in: context.world))
    }

    /// Records a finished drag: `transform.set` with every changed entity's start and end
    /// transforms (the world already has the new ones), or straight on the undo stack without commands.
    private func record(_ edit: GizmoEdit, context: ViewportToolContext) {
        guard let commands = context.commands else {
            _ = try? edit.record(in: context.undo)
            return
        }
        let changes = edit.changes.compactMap { change -> TransformSetCommand.Change? in
            guard change.old != change.new, let id = change.id ?? context.world.ensureID(of: change.entity) else { return nil }
            return TransformSetCommand.Change(entity: id, transform: change.new, previous: change.old)
        }
        guard !changes.isEmpty else { return }
        _ = try? commands.run(TransformSetCommand.self, .init(changes: changes, label: edit.label))
    }

    private func finishGroup() {
        isGizmoDrag = false
        undo?.endGroup()
        undo = nil
    }

    static func mode(for tool: EditorTool) -> GizmoMode {
        switch tool {
        case .move: .translate
        case .rotate: .rotate
        case .scale: .scale
        }
    }

    static func phase(_ phase: ViewportPointerPhase) -> ViewportPointer.Phase {
        switch phase {
        case .moved: .moved
        case .pressed: .pressed
        case .dragged: .dragged
        case .released: .released
        }
    }
}
