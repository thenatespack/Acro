import Engine

// Viewport tools: the extension point for everything that interacts with the scene inside
// the viewport (selection picking, transform gizmos, outlines). The viewport offers each
// frame's pointer event to its `tools` in order before its camera controls; a tool that
// consumes a press owns the pointer until the button is released. Tools also draw overlays
// into the viewport's debug-draw list every frame.

/// Where an event is in a pointer gesture.
public enum ViewportPointerPhase: Sendable, Equatable {
    /// No button went down or up this frame (hover, or a held button without a gesture).
    case moved
    /// A button went down this frame.
    case pressed
    /// The pointer moved (or stayed) while the button that started the gesture is held.
    case dragged
    /// The button that started the gesture went up this frame.
    case released
}

/// One frame's pointer state for viewport tools.
public struct ViewportPointerEvent: Sendable, Equatable {
    /// Position in viewport points, origin at the viewport's top-left corner, y down.
    public var position: Vec2
    /// The viewport's size in points.
    public var viewportSize: Vec2
    public var phase: ViewportPointerPhase
    /// The button that went down / is held / went up; nil for `.moved`.
    public var button: MouseButton?
    public var modifiers: KeyModifiers

    public init(position: Vec2, viewportSize: Vec2, phase: ViewportPointerPhase, button: MouseButton?, modifiers: KeyModifiers = []) {
        self.position = position
        self.viewportSize = viewportSize
        self.phase = phase
        self.button = button
        self.modifiers = modifiers
    }
}

/// Everything a tool may need about the viewport and the document this frame.
@MainActor
public struct ViewportToolContext {
    public let world: World
    public let selection: EditorSelection
    /// Record edits here (one step per gesture: `undo.beginGroup` on press, `endGroup` on release).
    public let undo: UndoStack
    /// The editor camera's view and projection.
    public let view: SceneView
    /// The viewport's rectangle in window points.
    public let viewportRect: UIRect
    /// Framebuffer pixels per point (the render target is `viewportRect.size * pixelScale` pixels).
    public let pixelScale: Float
    /// The transform tool selected in the toolbar.
    public let toolMode: EditorTool
    public let isPlaying: Bool
    /// Local bounds of a mesh (from the renderer), for picking and highlighting.
    public let meshBounds: (MeshHandle) -> Bounds?

    public init(world: World, selection: EditorSelection, undo: UndoStack, view: SceneView, viewportRect: UIRect,
                pixelScale: Float, toolMode: EditorTool, isPlaying: Bool, meshBounds: @escaping (MeshHandle) -> Bounds?) {
        self.world = world
        self.selection = selection
        self.undo = undo
        self.view = view
        self.viewportRect = viewportRect
        self.pixelScale = pixelScale
        self.toolMode = toolMode
        self.isPlaying = isPlaying
        self.meshBounds = meshBounds
    }

    public var viewportSize: Vec2 { Vec2(viewportRect.width, viewportRect.height) }

    /// The world-space ray through a point in viewport points.
    public func ray(at point: Vec2) -> ViewportRay {
        ViewportRay(through: point, viewportSize: viewportSize, view: view)
    }

    /// Where a world point appears, in viewport points (nil behind the camera).
    public func project(_ point: Vec3) -> Vec2? {
        let clip = view.viewProjection * Vec4(point, 1)
        guard clip.w > 1e-6 else { return nil }
        let ndc = Vec2(clip.x, clip.y) / clip.w
        return Vec2((ndc.x + 1) / 2 * viewportRect.width, (1 - ndc.y) / 2 * viewportRect.height)
    }

    /// `entity`'s world-space box: its mesh bounds transformed by its `GlobalTransform`, or nil
    /// if it has no `MeshRenderer` (or the mesh is unknown).
    public func worldBounds(of entity: Entity) -> Bounds? {
        guard let renderer = world.get(MeshRenderer.self, for: entity), let local = meshBounds(renderer.mesh) else { return nil }
        let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
        return local.transformed(by: matrix)
    }
}

/// Something that handles pointer input in the viewport and/or draws overlays there.
@MainActor public protocol ViewportTool: AnyObject {
    /// Called each frame while the viewport has the pointer; return true if the tool consumed the pointer (camera controls then ignore it).
    func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool
    /// Draw tool overlays (gizmos, outlines) for this view.
    func draw(into debugDraw: DebugDraw, context: ViewportToolContext)
}

/// A world-space ray (`direction` unit length).
public struct ViewportRay: Sendable, Equatable {
    public var origin: Vec3
    public var direction: Vec3

    public init(origin: Vec3, direction: Vec3) {
        self.origin = origin
        self.direction = normalize(direction)
    }

    /// The ray from the camera through `point` (viewport points, top-left origin): from the
    /// near plane toward the far plane (either depth convention).
    public init(through point: Vec2, viewportSize: Vec2, view: SceneView) {
        let ndc = Vec2(point.x / max(viewportSize.x, 1) * 2 - 1, 1 - point.y / max(viewportSize.y, 1) * 2)
        let inverse = view.viewProjection.inverse
        func unproject(_ depth: Float) -> Vec3 {
            let p = inverse * Vec4(ndc.x, ndc.y, depth, 1)
            return Vec3(p.x, p.y, p.z) / p.w
        }
        let near = unproject(view.reversedZ ? 1 : 0), far = unproject(view.reversedZ ? 0 : 1)
        self.init(origin: near, direction: far - near)
    }

    public func point(at t: Float) -> Vec3 { origin + direction * t }

    /// The distance along the ray to where it enters `bounds` (0 when it starts inside), or nil
    /// if it misses. Slab test; flat boxes (a plane's zero thickness) work.
    public func intersect(_ bounds: Bounds) -> Float? {
        let lo = bounds.center - bounds.halfExtent, hi = bounds.center + bounds.halfExtent
        var tMin: Float = 0, tMax = Float.infinity
        for axis in 0..<3 {
            let o = origin[axis], d = direction[axis]
            if abs(d) < 1e-9 {
                if o < lo[axis] || o > hi[axis] { return nil }
                continue
            }
            var t0 = (lo[axis] - o) / d, t1 = (hi[axis] - o) / d
            if t0 > t1 { swap(&t0, &t1) }
            tMin = max(tMin, t0)
            tMax = min(tMax, t1)
            if tMin > tMax { return nil }
        }
        return tMin
    }
}

/// The simple built-in picker: a left click (press and release without moving) selects the
/// nearest entity whose mesh's world AABB the ray hits; Shift or Cmd/Ctrl toggles it in the
/// selection; a click on nothing clears the selection. Alt+click is left to the camera (orbit).
/// Boxes are coarse (a rotated cube's AABB is bigger than the cube); a precise picker
/// replaces this tool later.
@MainActor
public final class BoundsClickSelectTool: ViewportTool {
    /// Pointer travel (points) after which a press no longer counts as a click.
    public var clickSlop: Float = 4
    private var pressPosition: Vec2?

    public init() {}

    public func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        switch event.phase {
        case .pressed:
            guard event.button == .left, !event.modifiers.contains(.alt) else { return false }
            pressPosition = event.position
            return true
        case .dragged:
            if let start = pressPosition, length(Vec3(event.position - start, 0)) > clickSlop { pressPosition = nil }
            return event.button == .left
        case .released:
            defer { pressPosition = nil }
            guard event.button == .left else { return false }
            guard pressPosition != nil else { return true }
            let hit = Self.pick(context.ray(at: event.position), context: context)
            let id = hit.flatMap { context.world.id(of: $0) }
            let additive = event.modifiers.contains(.shift) || event.modifiers.contains(.shortcut)
            if additive {
                if let id { context.selection.toggle(id) }
            } else {
                context.selection.select(id)
            }
            return true
        case .moved:
            return false
        }
    }

    public func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {}

    /// The nearest visible entity whose world bounds `ray` hits.
    public static func pick(_ ray: ViewportRay, context: ViewportToolContext) -> Entity? {
        var best: (entity: Entity, t: Float)?
        context.world.query(MeshRenderer.self) { entity, renderer in
            guard renderer.isVisible, let bounds = context.worldBounds(of: entity), let t = ray.intersect(bounds) else { return }
            if best == nil || t < best!.t { best = (entity, t) }
        }
        return best?.entity
    }
}

/// Local bounds of the built-in meshes, computed on the CPU (for tests and tools without a renderer).
public func builtinMeshBounds(_ handle: MeshHandle) -> Bounds? {
    switch handle {
    case .cube: BuiltinBounds.cube
    case .sphere: BuiltinBounds.sphere
    case .plane: BuiltinBounds.plane
    default: nil
    }
}

private enum BuiltinBounds {
    static let cube = MeshGeometry.cube().bounds
    static let sphere = MeshGeometry.sphere().bounds
    static let plane = MeshGeometry.plane().bounds
}
