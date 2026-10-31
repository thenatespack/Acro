import Foundation

// Debug visualization of a PhysicsWorld through DebugDraw: collider wireframes (colored by
// motion and sleep state; triggers yellow), contact points with normals, fat AABBs, joints
// and centers of mass.

extension PhysicsWorld {
    public struct DebugColors: Sendable {
        public var staticBody = Vec4(0.55, 0.6, 0.65, 1)
        public var kinematic = Vec4(0.3, 0.6, 1, 1)
        public var dynamic = Vec4(0.35, 1, 0.45, 1)
        public var sleeping = Vec4(0.45, 0.5, 0.5, 1)
        public var trigger = Vec4(1, 0.85, 0.2, 1)
        public var contact = Vec4(1, 0.2, 0.15, 1)
        public var speculative = Vec4(1, 0.6, 0.1, 1)
        public var bounds = Vec4(0.8, 0.4, 1, 0.8)
        public var joint = Vec4(0.2, 0.9, 1, 1)
        public init() {}
    }

    /// Adds the selected visualizations to `draw` (for this frame). Mesh colliders with more
    /// than `maxMeshTriangles` triangles draw only their bounds.
    public func drawDebug(into draw: DebugDraw, options: PhysicsDebugOptions = [.colliders, .contacts, .joints],
                          colors: DebugColors = DebugColors(), maxMeshTriangles: Int = 4096) {
        let thin = DebugDraw.Style(width: 1.2)
        for i in bodies.indices.dropFirst() where bodies[i].isAlive {
            let b = bodies[i]
            guard let shape = b.shape else { continue }
            if options.contains(.colliders) {
                var color: Vec4
                switch b.motion {
                case .static: color = colors.staticBody
                case .kinematic: color = colors.kinematic
                case .dynamic: color = b.isAwake ? colors.dynamic : colors.sleeping
                }
                if b.isTrigger { color = colors.trigger }
                drawShape(shape, b.shapePose, color: color, style: thin, into: draw, maxMeshTriangles: maxMeshTriangles)
            }
            if options.contains(.bounds) {
                draw.box(b.fatBox.bounds, color: colors.bounds, style: DebugDraw.Style(width: 1))
            }
            if options.contains(.centersOfMass) && b.motion == .dynamic {
                draw.axes(Pose(position: b.center, rotation: b.pose.rotation).matrix, length: 0.25, style: DebugDraw.Style(width: 1.5))
            }
        }
        if options.contains(.contacts) {
            let style = DebugDraw.Style(width: 2, depth: .onTop)
            for c in contacts where !c.isTrigger {
                for p in c.points {
                    let color = p.separation <= linearSlop * 2 ? colors.contact : colors.speculative
                    draw.line(p.position - Vec3(0.04, 0, 0), p.position + Vec3(0.04, 0, 0), color: color, style: style)
                    draw.line(p.position - Vec3(0, 0, 0.04), p.position + Vec3(0, 0, 0.04), color: color, style: style)
                    draw.line(p.position, p.position + p.normal * 0.3, color: color, style: DebugDraw.Style(width: 1.5, depth: .onTop))
                }
            }
        }
        if options.contains(.joints) {
            let style = DebugDraw.Style(width: 2, depth: .onTop)
            for j in joints where j.isAlive {
                let a = bodies[j.a], b = bodies[j.b]
                let pA = a.center + a.pose.rotation * j.localAnchorA, pB = b.center + b.pose.rotation * j.localAnchorB
                if j.a != 0 { draw.line(a.center, pA, color: colors.joint, style: style) }
                if j.b != 0 { draw.line(b.center, pB, color: colors.joint, style: style) }
                if j.kind == .distance { draw.line(pA, pB, color: colors.joint, style: style) }
                draw.sphere(center: pA, radius: 0.06, color: colors.joint, segments: 8, style: style)
                if j.kind == .hinge {
                    let axis = a.pose.rotation * j.localAxisA * 0.35
                    draw.line(pA - axis, pA + axis, color: colors.joint, style: style)
                }
            }
        }
    }

    private func drawShape(_ shape: Shape, _ pose: Pose, color: Vec4, style: DebugDraw.Style, into draw: DebugDraw,
                           maxMeshTriangles: Int) {
        switch shape.kind {
        case .sphere:
            draw.sphere(center: pose.position, radius: shape.radius, color: color, segments: 20, style: style)
            // A meridian marker so rolling reads.
            draw.line(pose.position, pose.transform(Vec3(shape.radius, 0, 0)), color: color, style: style)
        case .capsule(let h):
            let r = shape.radius
            let a = pose.transform(Vec3(0, -h, 0)), b = pose.transform(Vec3(0, h, 0))
            let up = pose.rotation * Vec3(0, 1, 0), x = pose.rotation * Vec3(1, 0, 0), z = pose.rotation * Vec3(0, 0, 1)
            draw.circle(center: a, normal: up, radius: r, color: color, segments: 20, style: style)
            draw.circle(center: b, normal: up, radius: r, color: color, segments: 20, style: style)
            for side in [x, -x, z, -z] { draw.line(a + side * r, b + side * r, color: color, style: style) }
            // Half circles for the caps, in the two planes through the axis.
            for side in [x, z] {
                for (center, sign) in [(b, Float(1)), (a, Float(-1))] {
                    let points = (0...10).map { k -> Vec3 in
                        let angle = Float(k) / 10 * .pi
                        return center + side * (cosf(angle) * r) + up * (sign * sinf(angle) * r)
                    }
                    draw.polyline(points, color: color, style: style)
                }
            }
        case .compound(let parts):
            for part in parts {
                drawShape(part.shape, pose * part.pose, color: color, style: style, into: draw, maxMeshTriangles: maxMeshTriangles)
            }
        case .polyhedron(let p):
            for e in p.edges { draw.line(pose.transform(p.vertices[e.a]), pose.transform(p.vertices[e.b]), color: color, style: style) }
        case .mesh(let mesh):
            if mesh.triangleCount > maxMeshTriangles {
                draw.box(shape.bounds(at: pose).bounds, color: color, style: style)
                return
            }
            for t in 0..<mesh.triangleCount {
                let (a, b, c) = mesh.triangle(t)
                draw.polyline([pose.transform(a), pose.transform(b), pose.transform(c)], closed: true, color: color, style: style)
            }
        }
    }
}
