import Foundation

// Debug visualization of a PhysicsWorld2D through DebugDraw, in the plane z = `z`: collider
// outlines (colored by motion and sleep state; triggers yellow), contact points with normals,
// fat AABBs, joints and centers of mass. Uses the 3D world's options and colors.

extension PhysicsWorld2D {
    /// Adds the selected visualizations to `draw` (for this frame).
    public func drawDebug(into draw: DebugDraw, options: PhysicsDebugOptions = [.colliders, .contacts, .joints], z: Float = 0,
                          colors: PhysicsWorld.DebugColors = PhysicsWorld.DebugColors()) {
        let thin = DebugDraw.Style(width: 1.2)
        func v3(_ p: Vec2) -> Vec3 { Vec3(p.x, p.y, z) }
        for i in bodies.indices.dropFirst() where bodies[i].isAlive {
            let b = bodies[i]
            if options.contains(.colliders) {
                var color: Vec4
                switch b.motion {
                case .static: color = colors.staticBody
                case .kinematic: color = colors.kinematic
                case .dynamic: color = b.isAwake ? colors.dynamic : colors.sleeping
                }
                if b.isTrigger { color = colors.trigger }
                for f in b.fixtures { drawGeom(fixtures[f].geom.placed(b.pose), color: color, style: thin, into: draw, z: z) }
            }
            if options.contains(.bounds) {
                for f in b.fixtures {
                    let box = fixtures[f].fatBox
                    draw.polyline([v3(box.min), v3(Vec2(box.max.x, box.min.y)), v3(box.max), v3(Vec2(box.min.x, box.max.y))],
                                  closed: true, color: colors.bounds, style: DebugDraw.Style(width: 1))
                }
            }
            if options.contains(.centersOfMass) && b.motion == .dynamic {
                let x = b.pose.rotation.rotate(Vec2(0.2, 0)), y = leftPerp(x)
                draw.line(v3(b.center), v3(b.center + x), color: Vec4(1, 0.3, 0.3, 1), style: DebugDraw.Style(width: 1.5))
                draw.line(v3(b.center), v3(b.center + y), color: Vec4(0.3, 1, 0.3, 1), style: DebugDraw.Style(width: 1.5))
            }
        }
        if options.contains(.contacts) {
            let style = DebugDraw.Style(width: 2, depth: .onTop)
            for c in contacts where !c.isTrigger {
                for p in c.points {
                    let color = p.separation <= linearSlop * 2 ? colors.contact : colors.speculative
                    draw.line(v3(p.position - Vec2(0.04, 0)), v3(p.position + Vec2(0.04, 0)), color: color, style: style)
                    draw.line(v3(p.position - Vec2(0, 0.04)), v3(p.position + Vec2(0, 0.04)), color: color, style: style)
                    draw.line(v3(p.position), v3(p.position + c.normal * 0.3), color: color, style: DebugDraw.Style(width: 1.5, depth: .onTop))
                }
            }
        }
        if options.contains(.joints) {
            let style = DebugDraw.Style(width: 2, depth: .onTop)
            for j in joints where j.isAlive {
                let a = bodies[j.a], b = bodies[j.b]
                let pA = a.center + a.pose.rotation.rotate(j.localAnchorA), pB = b.center + b.pose.rotation.rotate(j.localAnchorB)
                if j.isMouse {
                    draw.line(v3(pB), v3(j.target), color: colors.joint, style: style)
                    continue
                }
                if j.a != 0 { draw.line(v3(a.center), v3(pA), color: colors.joint, style: style) }
                if j.b != 0 { draw.line(v3(b.center), v3(pB), color: colors.joint, style: style) }
                if j.kind == .distance { draw.line(v3(pA), v3(pB), color: colors.joint, style: style) }
                draw.circle(center: v3(pA), normal: Vec3(0, 0, 1), radius: 0.06, color: colors.joint, segments: 8, style: style)
            }
        }
    }

    private func drawGeom(_ g: Geom2D, color: Vec4, style: DebugDraw.Style, into draw: DebugDraw, z: Float) {
        func v3(_ p: Vec2) -> Vec3 { Vec3(p.x, p.y, z) }
        func arc(_ center: Vec2, from start: Float, radius: Float, segments: Int = 10) -> [Vec3] {
            (0...segments).map { k in
                let a = start + Float(k) / Float(segments) * .pi
                return v3(center + Vec2(cosf(a), sinf(a)) * radius)
            }
        }
        switch g.count {
        case 1:
            let c = g.verts[0]
            let ring = (0..<24).map { k -> Vec3 in
                let a = Float(k) / 24 * 2 * .pi
                return v3(c + Vec2(cosf(a), sinf(a)) * g.radius)
            }
            draw.polyline(ring, closed: true, color: color, style: style)
            draw.line(v3(c), v3(c + Vec2(g.radius, 0)), color: color, style: style)
        case 2 where g.radius > 0:
            let a = g.verts[0], b = g.verts[1], n = g.normals[0] * g.radius
            draw.line(v3(a + n), v3(b + n), color: color, style: style)
            draw.line(v3(a - n), v3(b - n), color: color, style: style)
            let start = atan2f(n.y, n.x)
            draw.polyline(arc(b, from: start, radius: g.radius), color: color, style: style)
            draw.polyline(arc(a, from: start + .pi, radius: g.radius), color: color, style: style)
        case 2:
            draw.line(v3(g.verts[0]), v3(g.verts[1]), color: color, style: style)
        default:
            draw.polyline(g.verts.map(v3), closed: true, color: color, style: style)
        }
    }
}
