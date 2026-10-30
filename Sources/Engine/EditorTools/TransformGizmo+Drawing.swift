import Foundation

extension TransformGizmo {
    /// Draws the gizmo for `selection` into `debug` (on top of everything, line widths in
    /// points times the view's pixel scale). The hovered or dragged handle is highlighted;
    /// while dragging, the other handles are hidden and a guide shows the constraint (the axis
    /// line, or the swept angle). Draw `debug` into the same view, after the scene (and after
    /// the selection outline, so the gizmo stays on top).
    public func draw(into debug: DebugDraw, view: ViewportProjection, world: World, selection: [Entity], primary: Entity?) {
        guard let current = frame(view: view, world: world, selection: selection, primary: primary) else { return }
        var frame = current
        // While dragging, keep the orientation the drag measures in (it matters for local
        // rotation, where the entity's own axes turn).
        if let drag { frame.axes = drag.frame.axes }
        let painter = GizmoPainter(debug: debug, frame: frame, scale: view.pixelScale, style: style)
        let visible = visibleHandles(frame)
        let shown = drag.map { [$0.handle] } ?? visible
        let highlight = drag?.handle ?? hovered

        switch mode {
        case .translate:
            if let drag, case .axis(let i) = drag.handle { painter.guide(axis: frame.axes[i]) }
            for case .plane(let i) in shown { painter.planeHandle(i, highlighted: highlight == .plane(i)) }
            // Far axes first, so nearer ones draw over them.
            for i in Self.depthOrder(frame) where shown.contains(.axis(i)) {
                painter.arrow(i, highlighted: highlight == .axis(i))
            }
            if shown.contains(.screen) { painter.centerCircle(highlighted: highlight == .screen) }
        case .rotate:
            painter.circle(normal: frame.toViewer, radius: Self.ringRadius, color: Vec4(0.6, 0.6, 0.6, 0.35), width: 1)
            for i in Self.depthOrder(frame) where shown.contains(.ring(i)) {
                painter.ring(axis: frame.axes[i], color: style.axisColors[i], highlighted: highlight == .ring(i),
                             backHalf: drag == nil)
            }
            if shown.contains(.viewRing) {
                painter.circle(normal: frame.toViewer, radius: Self.viewRingRadius,
                               color: highlight == .viewRing ? style.highlightColor : style.centerColor, width: style.lineWidth)
            }
            if let drag, case .angle(let axis, _, let start, _) = drag.constraint {
                let radius = drag.handle == .viewRing ? Self.viewRingRadius : Self.ringRadius
                painter.sweep(axis: axis, start: start, angle: Self.angle(of: drag.rotation, around: axis), radius: radius)
            }
        case .scale:
            let factors = drag?.scale ?? .one
            for i in Self.depthOrder(frame) where shown.contains(.axis(i)) {
                painter.scaleHandle(i, stretch: factors[i], highlighted: highlight == .axis(i))
            }
            if shown.contains(.uniform) { painter.centerCube(highlighted: highlight == .uniform) }
        }
    }

    /// Axis indices from the one pointing farthest away from the viewer to the nearest.
    static func depthOrder(_ frame: GizmoFrame) -> [Int] {
        (0..<3).sorted { dot(frame.axes[$0], frame.toViewer) < dot(frame.axes[$1], frame.toViewer) }
    }

    /// The signed angle of `rotation` around `axis` (which it rotates around).
    static func angle(of rotation: Quat, around axis: Vec3) -> Float {
        2 * atan2f(dot(rotation.imaginary, normalize(axis)), rotation.w)
    }
}

/// Turns gizmo-unit shapes into `DebugDraw` calls for one frame.
@MainActor
struct GizmoPainter {
    let debug: DebugDraw
    let frame: GizmoFrame
    /// Pixels per point.
    let scale: Float
    let style: GizmoStyle

    func point(_ axis: Int, _ t: Float) -> Vec3 { frame.origin + frame.axes[axis] * (t * frame.length) }
    func line(width: Float) -> DebugDraw.Style { DebugDraw.Style(width: width * scale, depth: .onTop) }
    func color(_ axis: Int, _ highlighted: Bool) -> Vec4 { highlighted ? style.highlightColor : style.axisColors[axis] }

    func arrow(_ i: Int, highlighted: Bool) {
        let c = color(i, highlighted)
        debug.line(point(i, TransformGizmo.axisStart), point(i, 0.8), color: c, style: line(width: style.lineWidth))
        debug.cone(base: point(i, 0.78), tip: point(i, 1), radius: 0.065 * frame.length, color: c, depth: .onTop)
    }

    func planeHandle(_ i: Int, highlighted: Bool) {
        let corners = TransformGizmo.planeCorners(i, frame)
        var fill = color(i, highlighted)
        fill.w = highlighted ? 0.55 : 0.3
        debug.quad(corners[0], corners[1], corners[2], corners[3], color: fill, depth: .onTop)
        debug.polyline(corners, closed: true, color: color(i, highlighted), style: line(width: 1.5))
    }

    func centerCircle(highlighted: Bool) {
        let radius = style.centerRadius * frame.unitsPerPoint
        if highlighted {
            var fill = style.highlightColor
            fill.w = 0.35
            debug.disc(center: frame.origin, normal: frame.toViewer, radius: radius, color: fill, segments: 24, depth: .onTop)
        }
        debug.circle(center: frame.origin, normal: frame.toViewer, radius: radius,
                     color: highlighted ? style.highlightColor : style.centerColor, segments: 24, style: line(width: 2))
    }

    func scaleHandle(_ i: Int, stretch: Float, highlighted: Bool) {
        let c = color(i, highlighted)
        let end = 0.94 * stretch
        debug.line(point(i, TransformGizmo.axisStart), point(i, end), color: c, style: line(width: style.lineWidth))
        let half = 0.06 * frame.length
        let m = Mat4(Vec4(frame.axes[0] * half, 0), Vec4(frame.axes[1] * half, 0), Vec4(frame.axes[2] * half, 0), Vec4(point(i, end), 1))
        debug.solidBox(m, color: c, depth: .onTop)
    }

    func centerCube(highlighted: Bool) {
        let half = 0.08 * frame.length
        let m = Mat4(Vec4(frame.axes[0] * half, 0), Vec4(frame.axes[1] * half, 0), Vec4(frame.axes[2] * half, 0), Vec4(frame.origin, 1))
        debug.solidBox(m, color: highlighted ? style.highlightColor : style.centerColor, depth: .onTop)
    }

    /// A circle of `radius` gizmo units around `normal`.
    func circle(normal: Vec3, radius: Float, color: Vec4, width: Float) {
        debug.circle(center: frame.origin, normal: normal, radius: radius * frame.length, color: color,
                     segments: TransformGizmo.ringSegments, style: line(width: width))
    }

    /// A rotation ring: the half facing the viewer solid, the other half faint (or omitted).
    func ring(axis: Vec3, color: Vec4, highlighted: Bool, backHalf: Bool) {
        let points = TransformGizmo.ringPoints(axis: axis, radius: TransformGizmo.ringRadius, frame)
        let front = highlighted ? style.highlightColor : color
        let back = Vec4(color.x, color.y, color.z, 0.25)
        for k in 0..<TransformGizmo.ringSegments {
            let isFront = points[k].front && points[k + 1].front
            guard isFront || backHalf else { continue }
            debug.line(points[k].point, points[k + 1].point, color: isFront ? front : back,
                       style: line(width: isFront ? style.lineWidth : 1))
        }
    }

    /// The angle swept by a rotation drag: a translucent pie from `start` around `axis`.
    func sweep(axis: Vec3, start: Vec3, angle: Float, radius: Float) {
        let r = radius * frame.length
        let steps = max(Int(abs(angle) / (2 * .pi) * Float(TransformGizmo.ringSegments)) + 1, 1)
        var fill = style.highlightColor
        fill.w = 0.25
        var previous = frame.origin + start * r
        for k in 1...steps {
            let next = frame.origin + Quat(angle: angle * Float(k) / Float(steps), axis: axis) * start * r
            debug.triangle(frame.origin, previous, next, color: fill, depth: .onTop)
            previous = next
        }
        let edge = line(width: 1.5)
        debug.line(frame.origin, frame.origin + start * r, color: style.highlightColor, style: edge)
        debug.line(frame.origin, previous, color: style.highlightColor, style: edge)
    }

    /// A long faint line along `axis` through the origin (the constraint of an axis drag).
    func guide(axis: Vec3) {
        let reach = axis * (frame.length * 40)
        var c = style.highlightColor
        c.w = 0.5
        debug.line(frame.origin - reach, frame.origin + reach, color: c, style: line(width: 1))
    }
}
