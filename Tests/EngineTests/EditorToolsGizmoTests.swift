import Foundation
import Testing
@testable import Engine

// TransformGizmo: placement, handle hit-testing, drag math, cancel and undo.

@MainActor @Suite struct EditorToolsGizmoTests {
    let world = World()

    init() {
        world.assignsEntityIDs = true
    }

    func view(eye: Vec3, target: Vec3 = .zero, up: Vec3 = Vec3(0, 1, 0), reversedZ: Bool = false) -> ViewportProjection {
        let projection = reversedZ
            ? Mat4.perspective(fovY: .pi / 3, aspect: 4 / 3, near: 200, far: 0.1)
            : Mat4.perspective(fovY: .pi / 3, aspect: 4 / 3, near: 0.1, far: 200)
        return ViewportProjection(view: Mat4.lookAt(eye: eye, target: target, up: up), projection: projection, reversedZ: reversedZ,
                                  size: Vec2(800, 600), pixelScale: 2)
    }

    /// A press at `from`, drags through `points`, then a release at the last one.
    func drag(_ gizmo: TransformGizmo, _ view: ViewportProjection, _ selection: [Entity], primary: Entity? = nil, from: Vec2,
              to points: [Vec2], modifiers: KeyModifiers = [], release: Bool = true) -> [GizmoEdit] {
        var edits: [GizmoEdit] = []
        let send = { (position: Vec2, phase: ViewportPointer.Phase) in
            if let edit = gizmo.handle(ViewportPointer(position: position, phase: phase, modifiers: modifiers), view: view,
                                       world: world, selection: selection, primary: primary) { edits.append(edit) }
        }
        send(from, .pressed)
        for point in points { send(point, .dragged) }
        if release { send(points.last ?? from, .released) }
        return edits
    }

    func position(_ entity: Entity) -> Vec3 { TransformGizmo.translation(world.worldMatrix(of: entity)) }

    func close(_ a: Vec3, _ b: Vec3, _ tolerance: Float = 1e-3) -> Bool { length(a - b) < tolerance }

    /// Whether two rotations turn vectors the same way.
    func same(_ a: Quat, _ b: Quat, _ tolerance: Float = 1e-3) -> Bool {
        [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)].allSatisfy { length(a * $0 - b * $0) < tolerance }
    }

    // MARK: Frame and handles

    @Test func frameFollowsPivotSpaceAndScreenSize() throws {
        let parent = world.spawn(Transform(position: Vec3(0, 1, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))))
        let child = world.spawn(Transform(position: Vec3(2, 0, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))))
        world.setParent(child, to: parent)
        let other = world.spawn(Transform(position: Vec3(4, 3, -2)))
        let v = view(eye: Vec3(3, 6, 14))
        let gizmo = TransformGizmo()
        let center = try #require(gizmo.frame(view: v, world: world, selection: [other, child], primary: child))
        // The child is at parent * (2, 0, 0): rotated 90° about y, (0, 1, -2).
        #expect(close(center.origin, (Vec3(0, 1, -2) + Vec3(4, 3, -2)) / 2))
        #expect(center.axes == [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
        #expect(abs(center.length - gizmo.style.size * v.worldUnitsPerPoint(at: center.origin)!) < 1e-5)
        gizmo.pivot = .primary
        gizmo.space = .local
        let local = try #require(gizmo.frame(view: v, world: world, selection: [other, child], primary: child))
        #expect(close(local.origin, Vec3(0, 1, -2)))
        let rotation = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)) * Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))
        for i in 0..<3 { #expect(close(local.axes[i], rotation * [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)][i])) }
        // Nothing editable, or behind the camera: no gizmo.
        #expect(gizmo.frame(view: v, world: world, selection: [world.spawn()], primary: nil) == nil)
        #expect(gizmo.frame(view: view(eye: Vec3(4, 3, -10), target: Vec3(4, 3, -20)), world: world, selection: [other], primary: nil) == nil)
    }

    @Test func editableEntitiesDropDescendantsOfSelectedOnes() {
        let parent = world.spawn(Transform()), child = world.spawn(Transform()), loose = world.spawn(Transform()), bare = world.spawn()
        world.setParent(child, to: parent)
        #expect(TransformGizmo.editableEntities([child, loose, parent, bare, loose], in: world) == [loose, parent])
        #expect(TransformGizmo.editableEntities([child, loose], in: world) == [child, loose])
    }

    @Test func handlesAreHitTestedInScreenSpace() throws {
        let entity = world.spawn(Transform(position: Vec3(1, 0, -1)))
        let v = view(eye: Vec3(7, 5, 9))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        func at(_ p: Vec3) -> Vec2 { v.project(p)! }
        func hit(_ p: Vec2) -> GizmoHandle? { gizmo.hitTest(p, view: v, world: world, selection: [entity], primary: nil) }
        let o = frame.origin, l = frame.length
        #expect(hit(at(o)) == .screen)
        for i in 0..<3 {
            #expect(hit(at(o + frame.axes[i] * (0.9 * l))) == .axis(i))
            let j = frame.axes[(i + 1) % 3], k = frame.axes[(i + 2) % 3]
            #expect(hit(at(o + (j + k) * (0.33 * l))) == .plane(i))
        }
        // Within the tolerance of an arrow, but not beyond it or past its tip.
        #expect(hit(at(o + frame.axes[0] * (0.6 * l)) + Vec2(0, 5)) == .axis(0))
        #expect(hit(at(o + frame.axes[0] * (1.2 * l))) == nil)
        #expect(hit(at(o) + Vec2(300, -250)) == nil)

        gizmo.mode = .rotate
        let ringPoint = o + normalize(Vec3(1, 0, 1)) * l  // on the y ring, on the half facing the viewer
        #expect(hit(at(ringPoint)) == .ring(1))
        #expect(hit(at(o - normalize(Vec3(1, 0, 1)) * l)) == nil)  // its back half
        let (u, _) = DebugDraw.basis(frame.toViewer)
        #expect(hit(at(o + u * (1.2 * l))) == .viewRing)
        gizmo.mode = .scale
        #expect(hit(at(o + frame.axes[2] * (0.97 * l))) == .axis(2))
        #expect(hit(at(o)) == .uniform)
    }

    @Test func axesSeenEndOnAndPlanesSeenEdgeOnAreHidden() throws {
        let entity = world.spawn(Transform())
        let v = view(eye: Vec3(0, 0, 10))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        #expect(gizmo.visibleHandles(frame) == [.plane(2), .axis(0), .axis(1), .screen])
        gizmo.mode = .scale
        #expect(gizmo.visibleHandles(frame) == [.axis(0), .axis(1), .uniform])
        gizmo.mode = .rotate
        #expect(gizmo.visibleHandles(frame) == [.viewRing, .ring(0), .ring(1), .ring(2)])
    }

    @Test func hoverHighlightsTheHandleUnderThePointer() throws {
        let entity = world.spawn(Transform())
        let v = view(eye: Vec3(6, 4, 8))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let tip = v.project(frame.origin + frame.axes[1] * (0.9 * frame.length))!
        #expect(gizmo.handle(ViewportPointer(position: tip, phase: .moved), view: v, world: world, selection: [entity], primary: nil) == nil)
        #expect(gizmo.hovered == .axis(1))
        let debug = DebugDraw()
        gizmo.draw(into: debug, view: v, world: world, selection: [entity], primary: nil)
        let segments = debug.segments[.onTop] ?? []
        #expect(debug.segments[.tested]?.isEmpty ?? true)
        #expect(segments.contains { $0.color == gizmo.style.highlightColor })
        #expect(segments.allSatisfy { $0.start.w == 2.5 * 2 || $0.start.w == 1.5 * 2 || $0.start.w == 2 * 2 })  // points × pixel scale
        #expect((debug.triangles[.onTop]?.count ?? 0) > 0)  // cones and plane squares
        gizmo.handle(ViewportPointer(position: Vec2(5, 5), phase: .moved), view: v, world: world, selection: [entity], primary: nil)
        #expect(gizmo.hovered == nil)
    }

    // MARK: Translate

    @Test(arguments: [false, true]) func translateAlongAnAxis(reversedZ: Bool) throws {
        let entity = world.spawn(Transform(position: Vec3(1, 0.5, 0), scale: Vec3(2, 2, 2)))
        let v = view(eye: Vec3(6, 5, 9), reversedZ: reversedZ)
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let grab = frame.origin + Vec3(1, 0, 0) * (0.9 * frame.length)
        let edits = drag(gizmo, v, [entity], from: v.project(grab)!, to: [v.project(grab + Vec3(1, 0, 0))!, v.project(grab + Vec3(3, 0, 0))!])
        #expect(edits.map(\.phase) == [.began, .changed, .changed, .ended])
        #expect(edits[0].changes.allSatisfy { $0.old == $0.new } && !edits[0].hasChanges)
        #expect(close(edits[1].translation, Vec3(1, 0, 0)))
        let end = try #require(edits.last)
        #expect(close(end.changes[0].new.position, Vec3(4, 0.5, 0)) && end.changes[0].old.position == Vec3(1, 0.5, 0))
        #expect(end.changes[0].new.scale == Vec3(2, 2, 2) && end.label == "Move" && end.handle == .axis(0))
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(4, 0.5, 0)))
        #expect(!gizmo.isDragging)
    }

    @Test func snappingRoundsTheOffsetWhileTheModifierIsHeld() throws {
        let entity = world.spawn(Transform())
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let grab = frame.origin + Vec3(0, 0, 1) * (0.9 * frame.length)
        let target = v.project(grab + Vec3(0, 0, 1.3))!
        _ = drag(gizmo, v, [entity], from: v.project(grab)!, to: [target], modifiers: .shortcut)
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(0, 0, 1.5)))
        // With snapping on, the modifier turns it off.
        world.add(Transform(), to: entity)
        gizmo.snapping.isEnabled = true
        gizmo.snapping.translateStep = 0.25
        _ = drag(gizmo, v, [entity], from: v.project(grab)!, to: [target], modifiers: .shortcut)
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(0, 0, 1.3)))
        world.add(Transform(), to: entity)
        _ = drag(gizmo, v, [entity], from: v.project(grab)!, to: [target])
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(0, 0, 1.25)))
        #expect(GizmoSnapping.snap(-0.74, step: 0.5) == -0.5 && GizmoSnapping.snap(0.3, step: 0) == 0.3)
    }

    @Test func translateInAPlaneAndInTheViewPlane() throws {
        let entity = world.spawn(Transform(position: Vec3(0, 1, 0)))
        let v = view(eye: Vec3(6, 7, 9))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        // The y plane handle (x/z square).
        let square = frame.origin + (Vec3(1, 0, 0) + Vec3(0, 0, 1)) * (0.33 * frame.length)
        let edits = drag(gizmo, v, [entity], from: v.project(square)!, to: [v.project(square + Vec3(2, 0, -1.5))!])
        #expect(edits.first?.handle == .plane(1))
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(2, 1, -1.5)))
        // The center circle moves in the plane facing the viewer.
        let origin = Vec3(2, 1, -1.5)
        let toViewer = v.directionToViewer(from: origin)
        let offset = normalize(cross(toViewer, Vec3(0, 1, 0))) * 2 + normalize(cross(toViewer, Vec3(1, 0, 0))) * 0.5
        let screen = drag(gizmo, v, [entity], from: v.project(origin)!, to: [v.project(origin + offset)!])
        #expect(screen.first?.handle == .screen)
        #expect(close(world.get(Transform.self, for: entity)!.position, origin + offset))
    }

    @Test func localSpaceUsesThePrimaryEntitysAxes() throws {
        let entity = world.spawn(Transform(rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))))
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        gizmo.space = .local
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: entity))
        #expect(close(frame.axes[0], Vec3(0, 0, -1)))
        let grab = frame.origin + frame.axes[0] * (0.9 * frame.length)
        _ = drag(gizmo, v, [entity], from: v.project(grab)!, to: [v.project(grab + frame.axes[0] * 2)!])
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(0, 0, -2)))
    }

    @Test func parentedEntitiesGetTheWorldDeltaInTheirParentsSpace() throws {
        let parent = world.spawn(Transform(position: Vec3(5, 0, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)),
                                           scale: Vec3(2, 2, 2)))
        let child = world.spawn(Transform(position: Vec3(1, 0, 0)))
        world.setParent(child, to: parent)
        let loose = world.spawn(Transform(position: Vec3(-3, 0, 0)))
        #expect(close(position(child), Vec3(5, 0, -2)))
        let v = view(eye: Vec3(4, 8, 14))
        let gizmo = TransformGizmo()
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [child, loose], primary: child))
        let grab = frame.origin + Vec3(1, 0, 0) * (0.9 * frame.length)
        let edits = drag(gizmo, v, [child, loose], primary: child, from: v.project(grab)!, to: [v.project(grab + Vec3(3, 0, 0))!])
        #expect(edits.last?.changes.map(\.entity) == [child, loose])
        #expect(close(position(child), Vec3(8, 0, -2)) && close(position(loose), Vec3(0, 0, 0)))
        // In the parent's space (rotated 90° about y, scaled 2) world +x is local +z / 2.
        #expect(close(world.get(Transform.self, for: child)!.position, Vec3(1, 0, 1.5)))
        // Selecting the parent too moves only the parent; the child follows it.
        let before = world.get(Transform.self, for: child)!
        let frame2 = try #require(gizmo.frame(view: v, world: world, selection: [child, parent], primary: parent))
        let grab2 = frame2.origin + Vec3(0, 1, 0) * (0.9 * frame2.length)
        let edits2 = drag(gizmo, v, [child, parent], primary: parent, from: v.project(grab2)!, to: [v.project(grab2 + Vec3(0, 2, 0))!])
        #expect(edits2.last?.changes.map(\.entity) == [parent])
        #expect(world.get(Transform.self, for: child)! == before && close(position(child), Vec3(8, 2, -2)))
    }

    // MARK: Rotate

    @Test func rotateByTheAngleSweptOnTheRing() throws {
        let a = world.spawn(Transform(position: Vec3(2, 0, 0))), b = world.spawn(Transform(position: Vec3(-2, 0, 0)))
        let v = view(eye: Vec3(0, 12, 0), up: Vec3(0, 0, -1))  // looking down the y axis
        let gizmo = TransformGizmo()
        gizmo.mode = .rotate
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [a, b], primary: b))
        #expect(close(frame.origin, .zero))
        let start = normalize(Vec3(1, 0, 1)) * frame.length
        let path = stride(from: Float(20), through: 200, by: 20).map { v.project(Quat(angle: $0 * .pi / 180, axis: Vec3(0, 1, 0)) * start)! }
        let edits = drag(gizmo, v, [a, b], primary: b, from: v.project(start)!, to: path)
        #expect(edits.first?.handle == .ring(1))
        // Past 180° the angle keeps accumulating (no wrap to -160° partway).
        let expected = Quat(angle: 200 * .pi / 180, axis: Vec3(0, 1, 0))
        #expect(same(try #require(edits.last).rotation, expected))
        #expect(same(world.get(Transform.self, for: a)!.rotation, expected) && same(world.get(Transform.self, for: b)!.rotation, expected))
        // Both orbit the pivot between them.
        #expect(close(position(a), expected * Vec3(2, 0, 0)) && close(position(b), expected * Vec3(-2, 0, 0)))
        #expect(abs(TransformGizmo.angle(of: edits[5].rotation, around: Vec3(0, 1, 0)) - 100 * .pi / 180) < 1e-3)
    }

    @Test func rotationSnapsToTheAngleStep() throws {
        let entity = world.spawn(Transform(position: Vec3(1, 2, 3)))
        let v = view(eye: Vec3(1, 14, 3), target: Vec3(1, 2, 3), up: Vec3(0, 0, -1))
        let gizmo = TransformGizmo()
        gizmo.mode = .rotate
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let start = normalize(Vec3(1, 0, 1)) * frame.length
        let to = Quat(angle: 50 * .pi / 180, axis: Vec3(0, 1, 0)) * start
        _ = drag(gizmo, v, [entity], from: v.project(frame.origin + start)!, to: [v.project(frame.origin + to)!], modifiers: .shortcut)
        let transform = world.get(Transform.self, for: entity)!
        #expect(same(transform.rotation, Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))))
        #expect(transform.position == Vec3(1, 2, 3))  // the pivot is the entity itself: exactly unchanged
    }

    @Test func edgeOnRingsRotateAlongTheirProjectedTangent() throws {
        let entity = world.spawn(Transform())
        let v = view(eye: Vec3(12, 0, 0))  // the y ring is seen edge-on
        let gizmo = TransformGizmo()
        gizmo.mode = .rotate
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let grab = Quat(angle: -.pi / 6, axis: Vec3(0, 1, 0)) * Vec3(1, 0, 0) * frame.length  // (cos 30°, 0, sin 30°)
        let pointer = v.project(grab)!
        #expect(gizmo.hitTest(pointer, view: v, world: world, selection: [entity], primary: nil) == .ring(1))
        // Move the pointer as far as the grabbed point moves on screen for a 0.1 rad turn.
        let moved = v.project(Quat(angle: 0.1, axis: Vec3(0, 1, 0)) * grab)!
        let edits = drag(gizmo, v, [entity], from: pointer, to: [moved])
        let angle = TransformGizmo.angle(of: try #require(edits.last).rotation, around: Vec3(0, 1, 0))
        #expect(abs(angle - 0.1) < 0.012)  // linearized at the grab point
    }

    @Test func localRotationOfAParentedEntity() throws {
        let parent = world.spawn(Transform(rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(3, 3, 3)))
        let child = world.spawn(Transform(position: Vec3(0, 0, 1), rotation: Quat(angle: 0.4, axis: Vec3(0, 0, 1))))
        world.setParent(child, to: parent)
        let worldBefore = world.worldMatrix(of: child)
        let v = view(eye: Vec3(0, 14, 0.5), target: .zero, up: Vec3(0, 0, -1))
        let gizmo = TransformGizmo()
        gizmo.mode = .rotate
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [child], primary: nil))
        let start = normalize(Vec3(1, 0, 1)) * frame.length
        let to = Quat(angle: .pi / 3, axis: Vec3(0, 1, 0)) * start
        _ = drag(gizmo, v, [child], from: v.project(frame.origin + start)!, to: [v.project(frame.origin + to)!])
        // The child's world matrix turned 60° about world y around its own origin.
        let r = Quat(angle: .pi / 3, axis: Vec3(0, 1, 0))
        let after = world.worldMatrix(of: child)
        #expect(close(TransformGizmo.translation(after), TransformGizmo.translation(worldBefore)))
        for (column, before) in zip([after.c0, after.c1, after.c2], [worldBefore.c0, worldBefore.c1, worldBefore.c2]) {
            #expect(close(Vec3(column.x, column.y, column.z), r * Vec3(before.x, before.y, before.z), 2e-3))
        }
    }

    // MARK: Scale

    @Test func scaleAlongAnAxisByTheGrabRatio() throws {
        let entity = world.spawn(Transform(position: Vec3(0, 1, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)),
                                           scale: Vec3(1.5, 1, 1)))
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        gizmo.mode = .scale
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        #expect(close(frame.axes[0], Vec3(0, 0, -1)))  // scale always works in the entity's own axes
        let grab = frame.origin + frame.axes[0] * (0.95 * frame.length)
        let edits = drag(gizmo, v, [entity], from: v.project(grab)!, to: [v.project(frame.origin + frame.axes[0] * (1.9 * frame.length))!])
        #expect(try edits.first?.handle == .axis(0) && close(#require(edits.last).scale, Vec3(2, 1, 1)))
        let transform = world.get(Transform.self, for: entity)!
        #expect(close(transform.scale, Vec3(3, 1, 1)) && transform.position == Vec3(0, 1, 0))
        #expect(try #require(edits.last).label == "Scale")
        // Snapped to steps of 0.1 of the factor.
        world.add(Transform(position: Vec3(0, 1, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))), to: entity)
        _ = drag(gizmo, v, [entity], from: v.project(grab)!, to: [v.project(frame.origin + frame.axes[0] * (0.95 * 1.27 * frame.length))!],
                 modifiers: .shortcut)
        #expect(close(world.get(Transform.self, for: entity)!.scale, Vec3(1.3, 1, 1)))
    }

    @Test func uniformScaleAroundTheSelectionCenter() throws {
        let a = world.spawn(Transform(position: Vec3(1, 0, 0))), b = world.spawn(Transform(position: Vec3(-1, 0, 2), scale: Vec3(1, 2, 3)))
        let v = view(eye: Vec3(4, 6, 10))
        let gizmo = TransformGizmo()
        gizmo.mode = .scale
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [a, b], primary: a))
        let center = v.project(frame.origin)!
        // Right and up by 50 points each: factor 1 + 100 / size = 2.
        let edits = drag(gizmo, v, [a, b], primary: a, from: center, to: [center + Vec2(50, -50)])
        #expect(try edits.first?.handle == .uniform && close(#require(edits.last).scale, Vec3(2, 2, 2)))
        #expect(close(world.get(Transform.self, for: b)!.scale, Vec3(2, 4, 6)))
        #expect(close(position(a), Vec3(2, 0, -1)) && close(position(b), Vec3(-2, 0, 3)))  // offsets from (0, 0, 1) doubled
        // It never collapses to zero.
        _ = drag(gizmo, v, [a, b], primary: a, from: v.project(TransformGizmo.translation(world.worldMatrix(of: a)) / 2
            + TransformGizmo.translation(world.worldMatrix(of: b)) / 2)!, to: [center + Vec2(-900, 900)])
        #expect(world.get(Transform.self, for: a)!.scale.x > 0)
    }

    // MARK: Cancel and undo

    @Test func escapeCancelRestoresExactly() throws {
        let parent = world.spawn(Transform(position: Vec3(0.3, 0.1, -0.7), rotation: Quat(angle: 0.7, axis: Vec3(1, 2, 3)),
                                           scale: Vec3(1.1, 0.9, 1.3)))
        let child = world.spawn(Transform(position: Vec3(0.2, 0.4, 0.6), rotation: Quat(angle: 1.1, axis: Vec3(0, 1, 1))))
        world.setParent(child, to: parent)
        let loose = world.spawn(Transform(position: Vec3(2, 0, 1)))
        let originals = [child, loose].map { world.get(Transform.self, for: $0)! }
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        for mode in GizmoMode.allCases {
            gizmo.mode = mode
            let frame = try #require(gizmo.frame(view: v, world: world, selection: [child, loose], primary: loose))
            // The center handle, or the view ring.
            let from = mode == .rotate
                ? v.project(frame.origin + DebugDraw.basis(frame.toViewer).0 * (1.2 * frame.length))!
                : v.project(frame.origin)!
            let edits = drag(gizmo, v, [child, loose], primary: loose, from: from, to: [from + Vec2(37, 23)], release: false)
            #expect(edits.count == 2 && gizmo.isDragging)
            #expect(world.get(Transform.self, for: loose)! != originals[1])
            let cancelled = try #require(gizmo.cancel(world: world))
            #expect(cancelled.phase == .cancelled && !cancelled.hasChanges && !gizmo.isDragging)
            #expect([child, loose].map { world.get(Transform.self, for: $0)! } == originals)
            // The release that follows is just a hover.
            #expect(gizmo.handle(ViewportPointer(position: from, phase: .released), view: v, world: world, selection: [child, loose],
                                 primary: loose) == nil)
        }
        #expect(gizmo.cancel(world: world) == nil)
    }

    @Test func aDragIsOneUndoStepThatRestoresExactly() throws {
        let parent = world.spawn(Transform(position: Vec3(1, 0, 0), rotation: Quat(angle: 0.5, axis: Vec3(0, 1, 0)), scale: Vec3(2, 2, 2)))
        let child = world.spawn(Transform(position: Vec3(0.5, 1, 0)))
        world.setParent(child, to: parent)
        let loose = world.spawn(Transform(position: Vec3(-2, 0, 0)))
        let selection = [child, loose]
        let before = selection.map { world.get(Transform.self, for: $0)! }
        let undo = UndoStack(world: world)
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        gizmo.mode = .rotate
        let frame = try #require(gizmo.frame(view: v, world: world, selection: selection, primary: loose))
        let start = frame.origin + normalize(Vec3(1, 0, 1)) * frame.length
        let path = stride(from: Float(10), through: 70, by: 10).map {
            v.project(frame.origin + Quat(angle: $0 * .pi / 180, axis: Vec3(0, 1, 0)) * (start - frame.origin))!
        }
        let edits = drag(gizmo, v, selection, primary: loose, from: v.project(start)!, to: path)
        let ended = try #require(edits.last)
        #expect(ended.phase == .ended && ended.hasChanges)
        let after = selection.map { world.get(Transform.self, for: $0)! }
        #expect(after == ended.changes.map(\.new))
        #expect(try ended.record(in: undo))
        #expect(undo.undoDepth == 1 && undo.undoLabel == "Rotate")
        #expect(selection.map { world.get(Transform.self, for: $0)! } == after)  // recording re-applies the same values
        try undo.undo()
        #expect(selection.map { world.get(Transform.self, for: $0)! } == before)
        try undo.redo()
        #expect(selection.map { world.get(Transform.self, for: $0)! } == after)
        // A click without a drag records nothing.
        let center = v.project(TransformGizmo.translation(world.worldMatrix(of: loose)))!
        gizmo.mode = .translate
        let click = drag(gizmo, v, [loose], from: center, to: [])
        #expect(click.map(\.phase) == [.began, .ended] && !click[1].hasChanges)
        #expect(try !click[1].record(in: undo) && undo.undoDepth == 1)
    }

    @Test func editsCanLeaveTheWorldAlone() throws {
        let entity = world.spawn(Transform())
        let v = view(eye: Vec3(6, 5, 9))
        let gizmo = TransformGizmo()
        gizmo.appliesToWorld = false
        let frame = try #require(gizmo.frame(view: v, world: world, selection: [entity], primary: nil))
        let grab = frame.origin + Vec3(0, 1, 0) * (0.9 * frame.length)
        let edits = drag(gizmo, v, [entity], from: v.project(grab)!, to: [v.project(grab + Vec3(0, 2, 0))!])
        #expect(close(try #require(edits.last).changes[0].new.position, Vec3(0, 2, 0)))
        #expect(world.get(Transform.self, for: entity)! == Transform())
        // The host applies the edit itself, e.g. through the undo stack.
        let undo = UndoStack(world: world)
        #expect(try edits.last!.record(in: undo))
        #expect(close(world.get(Transform.self, for: entity)!.position, Vec3(0, 2, 0)))
    }
}
