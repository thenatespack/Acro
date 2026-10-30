import Foundation

/// What a `TransformGizmo` edits.
public enum GizmoMode: String, Sendable, CaseIterable {
    case translate, rotate, scale
}

/// The orientation of the gizmo's axes: the world's, or the primary entity's world rotation.
/// The scale gizmo always uses the entity's own axes (scale is stored per local axis).
public enum GizmoSpace: String, Sendable, CaseIterable {
    case world, local
}

/// Where the gizmo sits and what it rotates and scales around.
public enum GizmoPivot: String, Sendable, CaseIterable {
    /// The primary entity's origin.
    case primary
    /// The mean of the selected entities' origins.
    case center
}

/// A part of the gizmo the pointer can grab. Axis indices are 0 (x), 1 (y), 2 (z) of the
/// gizmo's frame.
public enum GizmoHandle: Hashable, Sendable {
    /// Translate along an axis (arrow) or, in scale mode, scale along it.
    case axis(Int)
    /// Translate in the plane perpendicular to the axis (the square between the other two).
    case plane(Int)
    /// Translate in the view plane (the center circle).
    case screen
    /// Rotate around an axis.
    case ring(Int)
    /// Rotate around the view direction (the outer circle).
    case viewRing
    /// Scale all axes uniformly (the center cube).
    case uniform
}

/// Snapping steps. Snapping is on while `isEnabled` differs from whether `modifier` is held,
/// so holding it toggles the setting for one drag.
public struct GizmoSnapping: Sendable, Equatable {
    public var isEnabled: Bool
    public var modifier: KeyModifiers
    /// World units (along the drag axis, or per axis of the gizmo frame for plane / screen drags).
    public var translateStep: Float
    public var rotateDegrees: Float
    /// Step of the scale factor (0.1: 1.0, 1.1, 1.2 …).
    public var scaleStep: Float

    public init(isEnabled: Bool = false, modifier: KeyModifiers = .shortcut, translateStep: Float = 0.5,
                rotateDegrees: Float = 15, scaleStep: Float = 0.1) {
        self.isEnabled = isEnabled
        self.modifier = modifier
        self.translateStep = translateStep
        self.rotateDegrees = rotateDegrees
        self.scaleStep = scaleStep
    }

    public func isActive(_ modifiers: KeyModifiers) -> Bool {
        isEnabled != (!modifier.isEmpty && modifiers.contains(modifier))
    }

    /// `value` rounded to a multiple of `step` (unchanged for a step ≤ 0).
    public static func snap(_ value: Float, step: Float) -> Float {
        step > 0 ? (value / step).rounded() * step : value
    }
}

/// Sizes (in points) and colors (linear RGBA) of a `TransformGizmo`.
public struct GizmoStyle: Sendable, Equatable {
    /// Length of the axes on screen.
    public var size: Float = 100
    /// How close the pointer must be to a handle to grab it.
    public var pickTolerance: Float = 7
    public var lineWidth: Float = 2.5
    /// Radius of the center handle (screen translate, uniform scale).
    public var centerRadius: Float = 9
    /// X, Y, Z, as in the debug grid and `DebugDraw.axes`.
    public var axisColors: [Vec4] = [Vec4(0.9, 0.12, 0.1, 1), Vec4(0.2, 0.8, 0.1, 1), Vec4(0.1, 0.3, 1, 1)]
    public var centerColor = Vec4(0.9, 0.9, 0.9, 1)
    public var highlightColor = Vec4(1, 0.85, 0.1, 1)
    /// Axes whose |cos| with the view direction is above this are hidden (seen end-on).
    public var axisHideCosine: Float = 0.985
    /// Planes whose normal's |cos| with the view direction is below this are hidden (edge-on).
    public var planeHideCosine: Float = 0.2

    public init() {}
}

/// Where and how a gizmo is drawn for a selection in a view.
public struct GizmoFrame: Sendable, Equatable {
    /// The pivot in world space.
    public var origin: Vec3
    /// Unit axes x, y, z (world, or the primary entity's rotation).
    public var axes: [Vec3]
    /// The world length of the axes (`style.size` points on screen).
    public var length: Float
    /// World units per point at the origin.
    public var unitsPerPoint: Float
    /// Unit direction from the origin toward the viewer.
    public var toViewer: Vec3
}

/// One entity's transform before and after a gizmo edit.
public struct TransformChange: Sendable, Equatable {
    public var entity: Entity
    /// Nil if the entity has no id (the world doesn't assign them); `GizmoEdit.undoCommand` gives it one.
    public var id: EntityID?
    /// The local `Transform` when the drag began.
    public var old: Transform
    /// The local `Transform` now.
    public var new: Transform
}

/// What a gizmo gesture did, reported by `TransformGizmo.handle` / `cancel`.
public struct GizmoEdit: Sendable {
    public enum Phase: Sendable, Equatable {
        /// A handle was grabbed (old == new).
        case began
        /// The drag moved the entities.
        case changed
        /// The handle was released: `changes` holds the final transforms; record them as one
        /// undo step (`record(in:)`).
        case ended
        /// Esc (`cancel`): every entity is back at `old` (new == old).
        case cancelled
    }

    public var phase: Phase
    public var mode: GizmoMode
    public var handle: GizmoHandle
    /// Per edited entity (the selection without entities whose ancestor is also selected).
    public var changes: [TransformChange]
    /// The world-space pivot the drag started at.
    public var pivot: Vec3
    /// The drag's value so far: world translation, world rotation around `pivot`, scale
    /// factors along the gizmo axes (identity values for the other modes).
    public var translation: Vec3
    public var rotation: Quat
    public var scale: Vec3

    /// "Move", "Rotate" or "Scale", for undo menus.
    public var label: String {
        switch mode {
        case .translate: "Move"
        case .rotate: "Rotate"
        case .scale: "Scale"
        }
    }

    /// Whether any transform differs from where it started.
    public var hasChanges: Bool { changes.contains { $0.old != $0.new } }
}

/// A translate / rotate / scale gizmo for the selected entities in an editor view.
///
/// Feed it pointer events with `handle(_:view:world:selection:primary:)` and draw it every
/// frame with `draw(into:view:world:selection:primary:)` into a `DebugDraw` rendered over the
/// scene. The selection is passed on every call (the gizmo keeps no selection of its own); it
/// edits the selected entities that have a `Transform`, minus those whose ancestor is selected
/// too (they move with it). `EditorSelection` converts ids to entities.
///
/// - Hover: handles are hit-tested in screen space (`style.pickTolerance` points); the one
///   under the pointer is highlighted. Axes seen end-on and planes seen edge-on are hidden and
///   can't be grabbed.
/// - Drag: translate along an axis (the closest point between the pointer ray and the axis
///   line), in a plane or the view plane (ray-plane intersection); rotate by the angle the
///   pointer sweeps around the axis on the ring's plane, or, for a ring seen nearly edge-on,
///   by the pointer's motion along the ring's projected tangent; scale by the ratio of the
///   pointer's position along the axis to where it grabbed, or uniformly by the pointer's
///   motion (right / up grows). Snapping rounds the drag's value (offset, angle, factor).
/// - Every selected entity gets the same world-space delta, converted into its parent's space,
///   so parented entities work. Changes are written to the world live (`appliesToWorld`).
/// - The returned `GizmoEdit` reports began / changed / ended / cancelled with each entity's
///   old and new local `Transform`; `cancel(world:)` (Esc) restores them, and `record(in:)` on
///   the ended edit makes the drag one undo step.
@MainActor
public final class TransformGizmo {
    public var mode: GizmoMode = .translate
    public var space: GizmoSpace = .world
    public var pivot: GizmoPivot = .center
    public var snapping = GizmoSnapping()
    public var style = GizmoStyle()
    /// Write the transforms into the world while dragging (and restore them on cancel).
    public var appliesToWorld = true
    /// The handle under the pointer (nil while dragging another or over nothing).
    public private(set) var hovered: GizmoHandle?
    /// The handle being dragged.
    public var activeHandle: GizmoHandle? { drag?.handle }
    public var isDragging: Bool { drag != nil }

    struct Target {
        var entity: Entity
        var id: EntityID?
        var local: Transform
        var world: Mat4
        var parentInverse: Mat4
        var parentRotation: Quat
    }

    enum Constraint {
        /// Along `axis` through the origin; `start` is the grab point's parameter.
        case line(axis: Int, start: Float)
        /// In the plane through the start point with `normal`; deltas are split along `axes`.
        case plane(normal: Vec3, start: Vec3, axes: [Vec3])
        /// Around `axis`: by the angle swept on the plane (`last` is the previous in-plane vector)
        /// or, with a `tangent` (points per radian at the grab point), along the projected tangent.
        case angle(axis: Vec3, last: Vec3, start: Vec3, tangent: Vec2?)
        /// Uniform scale from the pointer's motion.
        case uniform
    }

    struct Drag {
        var handle: GizmoHandle
        var mode: GizmoMode
        var frame: GizmoFrame
        var targets: [Target]
        var startPointer: Vec2
        var constraint: Constraint
        /// Unsnapped running angle (rotation drags).
        var angle: Float = 0
        var translation = Vec3.zero
        var rotation = Quat.identity
        var scale = Vec3.one
        var applied: [Transform]
    }

    private(set) var drag: Drag?

    public init() {}

    // MARK: - Frame

    /// The entities a gizmo edits: live ones with a `Transform`, without those whose ancestor
    /// is in the selection, in selection order, without duplicates.
    public static func editableEntities(_ selection: [Entity], in world: World) -> [Entity] {
        var seen = Set<Entity>()
        let candidates = selection.filter { world.isAlive($0) && world.has(Transform.self, for: $0) && seen.insert($0).inserted }
        let set = Set(candidates)
        return candidates.filter { entity in !set.contains { $0 != entity && world.isDescendant(entity, of: $0) } }
    }

    /// The gizmo's placement for `selection` in `view` (from the current `Transform`s), or nil
    /// when nothing editable is selected or the pivot is behind the camera.
    public func frame(view: ViewportProjection, world: World, selection: [Entity], primary: Entity?) -> GizmoFrame? {
        let entities = Self.editableEntities(selection, in: world)
        guard !entities.isEmpty else { return nil }
        let primary = primary.flatMap { world.isAlive($0) && world.has(Transform.self, for: $0) ? $0 : nil } ?? entities.last!
        let primaryWorld = world.worldMatrix(of: primary)
        let origin: Vec3
        switch pivot {
        case .primary:
            origin = Self.translation(primaryWorld)
        case .center:
            origin = entities.reduce(Vec3.zero) { $0 + Self.translation(world.worldMatrix(of: $1)) } / Float(entities.count)
        }
        let axes: [Vec3]
        if space == .local || mode == .scale {
            let m = Transform(matrix: primaryWorld).rotation.matrix
            axes = [m.c0, m.c1, m.c2].map { Vec3($0.x, $0.y, $0.z) }
        } else {
            axes = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)]
        }
        guard view.isInFront(origin), let unitsPerPoint = view.worldUnitsPerPoint(at: origin) else { return nil }
        return GizmoFrame(origin: origin, axes: axes, length: style.size * unitsPerPoint, unitsPerPoint: unitsPerPoint,
                          toViewer: view.directionToViewer(from: origin))
    }

    static func translation(_ m: Mat4) -> Vec3 { Vec3(m.c3.x, m.c3.y, m.c3.z) }

    // MARK: - Handles

    /// The handles of `mode` that can be grabbed in `frame` (not end-on / edge-on).
    func visibleHandles(_ frame: GizmoFrame) -> [GizmoHandle] {
        let facing = frame.axes.map { abs(dot($0, frame.toViewer)) }
        switch mode {
        case .translate:
            return (0..<3).filter { facing[$0] > style.planeHideCosine }.map { .plane($0) }
                + (0..<3).filter { facing[$0] < style.axisHideCosine }.map { .axis($0) } + [.screen]
        case .rotate:
            return [.viewRing] + (0..<3).map { .ring($0) }
        case .scale:
            return (0..<3).filter { facing[$0] < style.axisHideCosine }.map { .axis($0) } + [.uniform]
        }
    }

    /// Gizmo units (1 = the axis length) along the axes where handles start and end.
    static let axisStart: Float = 0.18
    static let planeRange: ClosedRange<Float> = 0.22...0.44
    static let ringRadius: Float = 1
    static let viewRingRadius: Float = 1.2
    static let ringSegments = 64

    /// The corners of a plane handle (perpendicular to axis `i`).
    static func planeCorners(_ i: Int, _ frame: GizmoFrame) -> [Vec3] {
        let u = frame.axes[(i + 1) % 3] * frame.length, v = frame.axes[(i + 2) % 3] * frame.length
        let (a, b) = (planeRange.lowerBound, planeRange.upperBound)
        return [frame.origin + u * a + v * a, frame.origin + u * b + v * a, frame.origin + u * b + v * b, frame.origin + u * a + v * b]
    }

    /// Points around a ring of `radius` gizmo units around `axis`, and whether each one is on
    /// the half facing the viewer.
    static func ringPoints(axis: Vec3, radius: Float, _ frame: GizmoFrame) -> [(point: Vec3, front: Bool)] {
        let (u, v) = DebugDraw.basis(axis)
        return (0...ringSegments).map { k in
            let angle = Float(k) / Float(ringSegments) * 2 * .pi
            let offset = (u * cosf(angle) + v * sinf(angle)) * (radius * frame.length)
            return (frame.origin + offset, dot(offset, frame.toViewer) >= -1e-4 * frame.length)
        }
    }

    /// The handle under `point` (viewport points), if any.
    public func hitTest(_ point: Vec2, view: ViewportProjection, world: World, selection: [Entity], primary: Entity?) -> GizmoHandle? {
        guard let frame = frame(view: view, world: world, selection: selection, primary: primary) else { return nil }
        return hitTest(point, view: view, frame: frame)
    }

    func hitTest(_ point: Vec2, view: ViewportProjection, frame: GizmoFrame) -> GizmoHandle? {
        var best: (handle: GizmoHandle, distance: Float)?
        for handle in visibleHandles(frame) {
            guard let distance = distance(from: point, to: handle, view: view, frame: frame),
                  distance <= style.pickTolerance, distance < best?.distance ?? .infinity else { continue }
            best = (handle, distance)
        }
        return best?.handle
    }

    /// Screen distance in points from `point` to `handle` (0 inside filled ones), nil if not on screen.
    func distance(from point: Vec2, to handle: GizmoHandle, view: ViewportProjection, frame: GizmoFrame) -> Float? {
        switch handle {
        case .axis(let i):
            let a = frame.origin + frame.axes[i] * (Self.axisStart * frame.length), b = frame.origin + frame.axes[i] * frame.length
            guard let pa = view.project(a), let pb = view.project(b) else { return nil }
            return Self.distance(point, segment: pa, pb)
        case .plane(let i):
            let corners = Self.planeCorners(i, frame).compactMap { view.project($0) }
            guard corners.count == 4 else { return nil }
            if Self.contains(corners, point) { return 0 }
            return (0..<4).map { Self.distance(point, segment: corners[$0], corners[($0 + 1) % 4]) }.min()
        case .screen, .uniform:
            guard let center = view.project(frame.origin) else { return nil }
            return max(Self.screenLength(point - center) - style.centerRadius, 0)
        case .ring(let i):
            return ringDistance(point, axis: frame.axes[i], radius: Self.ringRadius, frontOnly: true, view: view, frame: frame)
        case .viewRing:
            return ringDistance(point, axis: frame.toViewer, radius: Self.viewRingRadius, frontOnly: false, view: view, frame: frame)
        }
    }

    private func ringDistance(_ point: Vec2, axis: Vec3, radius: Float, frontOnly: Bool, view: ViewportProjection,
                              frame: GizmoFrame) -> Float? {
        let points = Self.ringPoints(axis: axis, radius: radius, frame)
        var best: Float?
        for k in 0..<Self.ringSegments where !frontOnly || (points[k].front && points[k + 1].front) {
            guard let a = view.project(points[k].point), let b = view.project(points[k + 1].point) else { continue }
            best = min(best ?? .infinity, Self.distance(point, segment: a, b))
        }
        return best
    }

    static func screenLength(_ v: Vec2) -> Float { (v * v).sum().squareRoot() }

    static func distance(_ p: Vec2, segment a: Vec2, _ b: Vec2) -> Float {
        let d = b - a
        let lengthSquared = (d * d).sum()
        let t = lengthSquared > 0 ? min(max(((p - a) * d).sum() / lengthSquared, 0), 1) : 0
        return screenLength(p - (a + d * t))
    }

    /// Whether a convex polygon (either winding) contains `p`.
    static func contains(_ polygon: [Vec2], _ p: Vec2) -> Bool {
        var sign: Float = 0
        for k in polygon.indices {
            let a = polygon[k], b = polygon[(k + 1) % polygon.count]
            let side = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
            if side == 0 { continue }
            if sign == 0 { sign = side } else if (side > 0) != (sign > 0) { return false }
        }
        return true
    }

    // MARK: - Interaction

    /// Handles a pointer event: hover on `.moved`, grab on `.pressed` over a handle, edit on
    /// `.dragged`, finish on `.released`. Returns the edit's phase when one began, changed or
    /// ended; nil otherwise (e.g. a press that missed every handle: pick instead).
    @discardableResult
    public func handle(_ pointer: ViewportPointer, view: ViewportProjection, world: World, selection: [Entity],
                       primary: Entity?) -> GizmoEdit? {
        switch pointer.phase {
        case .moved, .dragged:
            if drag != nil { return update(pointer, view: view, world: world) }
            hovered = hitTest(pointer.position, view: view, world: world, selection: selection, primary: primary)
            return nil
        case .pressed:
            if drag != nil { return update(pointer, view: view, world: world) }
            guard let frame = frame(view: view, world: world, selection: selection, primary: primary),
                  let handle = hitTest(pointer.position, view: view, frame: frame) else {
                hovered = nil
                return nil
            }
            return begin(handle, pointer: pointer, view: view, frame: frame, world: world, selection: selection)
        case .released:
            guard drag != nil else {
                hovered = hitTest(pointer.position, view: view, world: world, selection: selection, primary: primary)
                return nil
            }
            var edit = update(pointer, view: view, world: world) ?? makeEdit(.changed, world: world)
            edit.phase = .ended
            drag = nil
            hovered = hitTest(pointer.position, view: view, world: world, selection: selection, primary: primary)
            return edit
        }
    }

    /// Ends the drag in progress, putting every entity back where it started (Esc). Returns the
    /// cancelled edit, or nil when not dragging.
    @discardableResult
    public func cancel(world: World) -> GizmoEdit? {
        guard let drag else { return nil }
        if appliesToWorld {
            for target in drag.targets { world.add(target.local, to: target.entity) }
        }
        self.drag!.applied = drag.targets.map(\.local)
        self.drag!.translation = .zero
        self.drag!.rotation = .identity
        self.drag!.scale = .one
        let edit = makeEdit(.cancelled, world: world)
        self.drag = nil
        return edit
    }

    private func begin(_ handle: GizmoHandle, pointer: ViewportPointer, view: ViewportProjection, frame: GizmoFrame,
                       world: World, selection: [Entity]) -> GizmoEdit? {
        let ray = view.ray(through: pointer.position)
        let constraint: Constraint
        switch handle {
        case .axis(let i):
            guard let s = ray.closestParameter(onLine: frame.origin, direction: frame.axes[i]),
                  mode != .scale || abs(s) > frame.length * 1e-3 else { return nil }
            constraint = .line(axis: i, start: s)
        case .plane(let i):
            guard let t = ray.intersectPlane(point: frame.origin, normal: frame.axes[i]) else { return nil }
            constraint = .plane(normal: frame.axes[i], start: ray.point(at: t), axes: [frame.axes[(i + 1) % 3], frame.axes[(i + 2) % 3]])
        case .screen:
            guard let t = ray.intersectPlane(point: frame.origin, normal: frame.toViewer) else { return nil }
            constraint = .plane(normal: frame.toViewer, start: ray.point(at: t), axes: frame.axes)
        case .ring(let i):
            constraint = angleConstraint(axis: frame.axes[i], radius: Self.ringRadius, pointer: pointer.position, ray: ray, view: view,
                                         frame: frame)
        case .viewRing:
            constraint = angleConstraint(axis: frame.toViewer, radius: Self.viewRingRadius, pointer: pointer.position, ray: ray,
                                         view: view, frame: frame)
        case .uniform:
            constraint = .uniform
        }
        let targets = Self.editableEntities(selection, in: world).map { entity -> Target in
            let local = world.get(Transform.self, for: entity)!
            let parentWorld = world.parent(of: entity).map { world.worldMatrix(of: $0) } ?? .identity
            return Target(entity: entity, id: world.id(of: entity), local: local, world: parentWorld * local.matrix,
                          parentInverse: parentWorld.inverse, parentRotation: Transform(matrix: parentWorld).rotation)
        }
        drag = Drag(handle: handle, mode: mode, frame: frame, targets: targets, startPointer: pointer.position,
                    constraint: constraint, applied: targets.map(\.local))
        hovered = nil
        return makeEdit(.began, world: world)
    }

    /// Rotation drags measure the angle on the ring's plane while it faces the viewer, else
    /// along the projected tangent at the grab point (the plane is too oblique to intersect).
    private func angleConstraint(axis: Vec3, radius: Float, pointer: Vec2, ray: Ray, view: ViewportProjection,
                                 frame: GizmoFrame) -> Constraint {
        if abs(dot(axis, frame.toViewer)) >= 0.3, let t = ray.intersectPlane(point: frame.origin, normal: axis) {
            let v = Self.inPlane(ray.point(at: t) - frame.origin, axis)
            if length(v) > frame.length * 1e-3 { return .angle(axis: axis, last: v, start: normalize(v), tangent: nil) }
        }
        // The ring point nearest the pointer on screen (on the half facing the viewer: an edge-on
        // ring's halves overlap on screen), and how far it moves on screen per radian.
        let ring = Self.ringPoints(axis: axis, radius: radius, frame)
        let points = ring.filter(\.front).map(\.point)
        let grab = points.min { a, b in
            Self.screenLength((view.project(a) ?? Vec2(repeating: .infinity)) - pointer)
                < Self.screenLength((view.project(b) ?? Vec2(repeating: .infinity)) - pointer)
        }!
        let offset = grab - frame.origin
        let epsilon: Float = 1e-3
        var tangent: Vec2?
        if let p0 = view.project(grab), let p1 = view.project(grab + cross(axis, offset) * epsilon) {
            let t = (p1 - p0) / epsilon
            if Self.screenLength(t) > 1e-3 { tangent = t }
        }
        return .angle(axis: axis, last: offset, start: normalize(offset), tangent: tangent ?? Vec2(0, 0))
    }

    static func inPlane(_ v: Vec3, _ normal: Vec3) -> Vec3 { v - normal * dot(v, normal) }

    /// Applies the pointer to the drag; returns `.changed` if the transforms changed.
    private func update(_ pointer: ViewportPointer, view: ViewportProjection, world: World) -> GizmoEdit? {
        guard var drag else { return nil }
        let ray = view.ray(through: pointer.position)
        let snap = snapping.isActive(pointer.modifiers)
        let frame = drag.frame
        switch drag.constraint {
        case .line(let i, let start):
            guard let s = ray.closestParameter(onLine: frame.origin, direction: frame.axes[i]) else { break }
            if drag.mode == .scale {
                var factor = s / start
                if snap { factor = GizmoSnapping.snap(factor, step: snapping.scaleStep) }
                if abs(factor) < 1e-3 { factor = factor < 0 ? -1e-3 : 1e-3 }
                drag.scale = .one
                drag.scale[i] = factor
            } else {
                var offset = s - start
                if snap { offset = GizmoSnapping.snap(offset, step: snapping.translateStep) }
                drag.translation = frame.axes[i] * offset
            }
        case .plane(let normal, let start, let axes):
            guard let t = ray.intersectPlane(point: start, normal: normal) else { break }
            let delta = ray.point(at: t) - start
            drag.translation = axes.reduce(Vec3.zero) { sum, axis in
                var component = dot(delta, axis)
                if snap { component = GizmoSnapping.snap(component, step: snapping.translateStep) }
                return sum + axis * component
            }
        case .angle(let axis, let last, let start, let tangent):
            if let tangent {
                let lengthSquared = (tangent * tangent).sum()
                if lengthSquared > 0 { drag.angle = ((pointer.position - drag.startPointer) * tangent).sum() / lengthSquared }
            } else if let t = ray.intersectPlane(point: frame.origin, normal: axis) {
                let v = Self.inPlane(ray.point(at: t) - frame.origin, axis)
                if length(v) > frame.length * 1e-3 {
                    drag.angle += atan2f(dot(cross(last, v), axis), dot(last, v))
                    drag.constraint = .angle(axis: axis, last: v, start: start, tangent: nil)
                }
            }
            var angle = drag.angle
            if snap { angle = GizmoSnapping.snap(angle, step: snapping.rotateDegrees * .pi / 180) }
            drag.rotation = Quat(angle: angle, axis: axis)
        case .uniform:
            let d = pointer.position - drag.startPointer
            var factor = max(1 + (d.x - d.y) / style.size, 0.01)
            if snap { factor = max(GizmoSnapping.snap(factor, step: snapping.scaleStep), snapping.scaleStep > 0 ? snapping.scaleStep : 0.01) }
            drag.scale = Vec3(repeating: factor)
        }
        let transforms = drag.targets.map { Self.apply(drag, to: $0) }
        let changed = transforms != drag.applied
        drag.applied = transforms
        self.drag = drag
        guard changed else { return nil }
        if appliesToWorld {
            for (target, transform) in zip(drag.targets, transforms) { world.add(transform, to: target.entity) }
        }
        return makeEdit(.changed, world: world)
    }

    /// `target`'s local transform with the drag's world-space delta applied around the pivot.
    static func apply(_ drag: Drag, to target: Target) -> Transform {
        var local = target.local
        let position = translation(target.world)
        let pivot = drag.frame.origin
        var delta: Vec3
        switch drag.mode {
        case .translate:
            delta = drag.translation
        case .rotate:
            delta = drag.rotation * (position - pivot) - (position - pivot)
            let q = target.parentRotation
            local.rotation = (q.conjugate * drag.rotation * q * local.rotation).normalized
        case .scale:
            let offset = position - pivot
            delta = (0..<3).reduce(Vec3.zero) { $0 + drag.frame.axes[$1] * (dot(offset, drag.frame.axes[$1]) * (drag.scale[$1] - 1)) }
            local.scale *= drag.scale
        }
        if delta != .zero {
            let d = target.parentInverse * Vec4(delta, 0)
            local.position += Vec3(d.x, d.y, d.z)
        }
        return local
    }

    private func makeEdit(_ phase: GizmoEdit.Phase, world: World) -> GizmoEdit {
        let drag = drag!
        let changes = zip(drag.targets, drag.applied).map { target, transform in
            TransformChange(entity: target.entity, id: target.id ?? world.id(of: target.entity), old: target.local, new: transform)
        }
        return GizmoEdit(phase: phase, mode: drag.mode, handle: drag.handle, changes: changes, pivot: drag.frame.origin,
                         translation: drag.translation, rotation: drag.rotation, scale: drag.scale)
    }
}

extension TransformGizmo {
    /// `handle` with the selection given as an `EditorSelection`.
    @discardableResult
    public func handle(_ pointer: ViewportPointer, view: ViewportProjection, world: World, selection: EditorSelection) -> GizmoEdit? {
        handle(pointer, view: view, world: world, selection: selection.entities(in: world), primary: selection.primaryEntity(in: world))
    }

    /// `draw` with the selection given as an `EditorSelection`.
    public func draw(into debug: DebugDraw, view: ViewportProjection, world: World, selection: EditorSelection) {
        draw(into: debug, view: view, world: world, selection: selection.entities(in: world), primary: selection.primaryEntity(in: world))
    }
}

extension GizmoEdit {
    /// One undo step for this edit (a `GroupCommand` of a `SetComponentCommand` per changed
    /// entity, from `old` to `new`), or nil when nothing changed. Entities without an id get one.
    @MainActor public func undoCommand(in world: World) -> GroupCommand? {
        let commands: [any UndoCommand] = changes.compactMap { change in
            guard change.old != change.new, let id = change.id ?? world.ensureID(of: change.entity) else { return nil }
            return SetComponentCommand(id: id, old: change.old, new: change.new, label: label)
        }
        return commands.isEmpty ? nil : GroupCommand(label, commands)
    }

    /// Records the finished gesture as one undo step on `undo` (the world already has the new
    /// transforms; performing the step re-applies them). Returns false when nothing changed.
    @MainActor @discardableResult public func record(in undo: UndoStack) throws -> Bool {
        guard let command = undoCommand(in: undo.world) else { return false }
        try undo.perform(command)
        return true
    }
}
