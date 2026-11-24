// Character controller version 2: crouching, ledges, mantling and climbing (see the notes at the
// top of CharacterController.swift for the walking step these hook into).
//
// - Crouch: `crouch` shrinks the capsule to `crouchHeight` at once; clearing it stands up only
//   when a cast up from the crouched capsule finds room for the full height (`canStand`).
// - Ledges: a ledge is a walkable top whose wall the character faces. Forward rays from the
//   capsule's axis, from the top of the reach down, find the wall; a ray down from above it,
//   just past the wall, finds the top (its start must be free, so a taller wall isn't a ledge);
//   a ray just under the top finds the wall's face, whose point at the top's height is the
//   edge. Hanging, the hands are at the edge (`ledgePoint`), the feet `height * 1.1` below it,
//   the capsule a skin away from the wall, and the capsule must fit there.
//   `grabLedge` looks within reach (in the move direction, else all around); `grabLedges`
//   catches a ledge at the hands' height while falling toward it. While hanging, moving sideways
//   shimmies along the ledge (where it continues), `drop` lets go, `mantle` or `jump` pulls up.
// - Mantle: the end is on the top, one radius past the edge; the capsule must fit there standing,
//   else crouched (it stays crouched until there's room), and straight above the start at the
//   top's height. The motion goes up (60% of `mantleTime`), then forward. From the ground
//   `mantle` climbs a wall in front between step height and the character's height.
// - Climb: walking into a wall whose physics material is `climbable` (and `climbSpeed` > 0)
//   starts climbing. Moving toward the wall climbs up, away climbs down, sideways moves along
//   it, at most `climbSpeed`. The capsule keeps a skin from the wall; a ray at hand height must
//   still find climbable wall, else the character mantles onto the top (or lets go). Down onto
//   walkable ground it walks again; `drop` lets go, `jump` jumps off the wall.
// Ledges and climbed walls carry the character when they move (kinematic or dynamic bodies).
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineScene

/// A ledge `findLedge` found.
struct CharacterLedge {
    /// The edge, where the hands go.
    var point: Vec3
    /// The wall's horizontal normal under the edge.
    var normal: Vec3
    var body: BodyID
    /// Where the feet go while hanging from it.
    var hang: Vec3
}

extension PhysicsWorld {
    /// Whether a crouching character at `feet` has room to stand up to its full `height`
    /// (true when it isn't crouching). `body` is its own kinematic body, skipped by the cast.
    public func canStand(_ controller: CharacterController, at feet: Vec3, body: BodyID? = nil) -> Bool {
        guard controller.isCrouching else { return true }
        let sweep = CharacterSweep(world: self, controller: controller, body: body)
        let rise = controller.height - controller.currentHeight
        guard rise > 1e-4 else { return true }
        guard let hit = sweep.cast(feet, Vec3(0, 1, 0), rise + controller.skinWidth) else { return true }
        return hit.distance >= rise + controller.skinWidth * 0.5
    }

    /// Crouch input: crouch at once, stand up when there is room.
    func updateCrouch(_ c: inout CharacterController, at feet: Vec3, body: BodyID?) {
        guard c.mode == .walking else { return }
        if c.crouch && !c.isCrouching {
            c.isCrouching = true
        } else if !c.crouch && c.isCrouching && canStand(c, at: feet, body: body) {
            c.isCrouching = false
        }
    }

    /// One step while hanging, mantling or climbing.
    func stepMove(_ c: inout CharacterController, from position: Vec3, dt: Float, sweep: CharacterSweep) -> Vec3 {
        c.isGrounded = false
        c.isSliding = false
        c.groundBody = nil
        c.groundNormal = Vec3(0, 1, 0)
        c.verticalVelocity = 0
        // What it holds on to carries it.
        c.groundVelocity = .zero
        if let held = c.ledgeBody {
            guard contains(held) else {
                letGo(&c)
                return position
            }
            c.groundVelocity = velocity(of: held, at: c.ledgePoint)
        }
        switch c.mode {
        case .hanging: return stepHanging(&c, from: position, dt: dt, sweep: sweep)
        case .mantling: return stepMantling(&c, from: position, dt: dt)
        case .climbing: return stepClimbing(&c, from: position, dt: dt, sweep: sweep)
        case .walking: return position
        }
    }

    /// Lets go: back to walking (falling), keeping what the ledge was moving at.
    private func letGo(_ c: inout CharacterController, push: Vec3 = .zero) {
        c.mode = .walking
        c.launchVelocity = Vec3(c.groundVelocity.x, 0, c.groundVelocity.z) + push
        c.verticalVelocity = max(c.groundVelocity.y, 0)
        c.ledgeBody = nil
        c.mantleProgress = 0
    }

    /// Starts hanging from `ledge`.
    func hang(_ c: inout CharacterController, from ledge: CharacterLedge) {
        c.mode = .hanging
        c.ledgePoint = ledge.point
        c.ledgeNormal = ledge.normal
        c.ledgeBody = ledge.body
        c.isGrounded = false
        c.isSliding = false
        c.groundBody = nil
        c.verticalVelocity = 0
        c.launchVelocity = .zero
    }

    /// Where the feet are while hanging from the edge `point` of a wall facing `normal`.
    static func hangPosition(_ c: CharacterController, point: Vec3, normal: Vec3) -> Vec3 {
        point + normal * (c.radius + c.skinWidth) - Vec3(0, c.height * 1.1, 0)
    }

    private func stepHanging(_ c: inout CharacterController, from position: Vec3, dt: Float, sweep: CharacterSweep) -> Vec3 {
        c.ledgePoint += c.groundVelocity * dt
        var pos = Self.hangPosition(c, point: c.ledgePoint, normal: c.ledgeNormal)
        if c.drop {
            letGo(&c, push: c.ledgeNormal * 0.5)
            return pos + c.ledgeNormal * 0.02
        }
        if c.mantle || c.jump, startMantle(&c, from: pos, sweep: sweep, fromGround: false) { return pos }
        // Shimmy along the ledge, where it continues.
        let right = normalize(cross(-c.ledgeNormal, Vec3(0, 1, 0)))
        let side = dot(Vec3(c.moveVelocity.x, 0, c.moveVelocity.z), right)
        if abs(side) > 1e-3 {
            let target = pos + right * (side * 0.5 * dt)
            if let ledge = sweep.findLedge(from: target, toward: -c.ledgeNormal, low: c.height * 1.1 - 0.15, high: c.height * 1.1 + 0.15,
                                           hangs: true), abs(ledge.point.y - c.ledgePoint.y) < 0.2 {
                c.ledgePoint = ledge.point
                c.ledgeNormal = ledge.normal
                c.ledgeBody = ledge.body
                pos = ledge.hang
            }
        }
        return pos
    }

    /// Starts a mantle from `position`: onto the ledge it hangs from or climbs to, or (`fromGround`)
    /// onto a wall in front between step height and its height. False when there is none or the
    /// character wouldn't fit on top.
    func startMantle(_ c: inout CharacterController, from position: Vec3, sweep: CharacterSweep, fromGround: Bool) -> Bool {
        var point = c.ledgePoint, normal = c.ledgeNormal, body = c.ledgeBody
        if fromGround || c.mode == .climbing {
            let direction = fromGround ? Vec3(c.moveVelocity.x, 0, c.moveVelocity.z) : -c.ledgeNormal
            // From the ground it mantles what it walks toward.
            guard lengthSquared(direction) > 1e-6 else { return false }
            let low = fromGround ? c.stepHeight + 0.02 : c.height * 0.3
            let high = fromGround ? c.height : c.height * 1.1
            guard let ledge = sweep.findLedge(from: position, toward: direction, low: low, high: high, hangs: false) else { return false }
            point = ledge.point
            normal = ledge.normal
            body = ledge.body
        }
        guard lengthSquared(normal) > 1e-6 else { return false }
        let end = point - normal * (c.radius + 0.12) + Vec3(0, c.skinWidth, 0)
        let above = Vec3(position.x, end.y, position.z)
        var crouched = false
        if !(sweep.fits(end, height: c.height) && sweep.fits(above, height: c.height)) {
            let low = min(max(c.crouchHeight, c.radius * 2), c.height)
            guard sweep.fits(end, height: low) && sweep.fits(above, height: low) else { return false }
            crouched = true
        }
        c.mode = .mantling
        c.isCrouching = c.isCrouching || crouched
        c.mantleFrom = position
        c.mantleTo = end
        c.mantleProgress = 0
        c.ledgePoint = point
        c.ledgeNormal = normal
        c.ledgeBody = body
        c.isGrounded = false
        c.verticalVelocity = 0
        c.launchVelocity = .zero
        return true
    }

    private func stepMantling(_ c: inout CharacterController, from position: Vec3, dt: Float) -> Vec3 {
        let carried = c.groundVelocity * dt
        c.mantleFrom += carried
        c.mantleTo += carried
        c.ledgePoint += carried
        c.mantleProgress = min(c.mantleProgress + dt / max(c.mantleTime, 0.01), 1)
        let above = Vec3(c.mantleFrom.x, c.mantleTo.y, c.mantleFrom.z)
        func ease(_ t: Float) -> Float { t * t * (3 - 2 * t) }
        let p = c.mantleProgress
        let pos = p < 0.6 ? c.mantleFrom + (above - c.mantleFrom) * ease(p / 0.6) : above + (c.mantleTo - above) * ease((p - 0.6) / 0.4)
        if p >= 1 {
            // On top: the next walking step's ground probe snaps it down.
            c.mode = .walking
            c.isGrounded = true
            c.groundBody = c.ledgeBody
            c.ledgeBody = nil
            c.mantleProgress = 0
        }
        return pos
    }

    /// The climbable wall among `hits` the character walked into (moving along `moving`).
    func climbableWall(in hits: [RaycastHit], moving: Vec3, sweep: CharacterSweep) -> RaycastHit? {
        guard lengthSquared(moving) > 1e-10 else { return nil }
        let direction = normalize(Vec3(moving.x, 0, moving.z))
        for hit in hits where abs(hit.normal.y) < 0.5 {
            let n = normalize(Vec3(hit.normal.x, 0, hit.normal.z))
            if dot(direction, -n) > 0.5 && isClimbable(hit.body, at: hit.point) { return hit }
        }
        return nil
    }

    /// Starts climbing `wall` from `feet`.
    func beginClimb(_ c: inout CharacterController, on wall: RaycastHit, at feet: Vec3) {
        guard !c.isCrouching else { return }
        let n = normalize(Vec3(wall.normal.x, 0, wall.normal.z))
        c.mode = .climbing
        c.ledgeNormal = n
        c.ledgeBody = wall.body
        c.ledgePoint = feet + Vec3(0, c.height * 0.9, 0) - n * (c.radius + c.skinWidth)
        c.isGrounded = false
        c.isSliding = false
        c.groundBody = nil
        c.verticalVelocity = 0
        c.launchVelocity = .zero
    }

    private func stepClimbing(_ c: inout CharacterController, from position: Vec3, dt: Float, sweep: CharacterSweep) -> Vec3 {
        var pos = position
        var n = c.ledgeNormal
        if c.drop {
            letGo(&c, push: n * 0.5)
            return pos
        }
        if c.jump {
            letGo(&c, push: n * 2.5)
            c.verticalVelocity = c.jumpSpeed * 0.6
            return pos
        }
        if lengthSquared(c.groundVelocity) > 0 { sweep.slide(&pos, c.groundVelocity * dt, pushes: false) }
        // Toward the wall climbs up, away climbs down, sideways moves along it.
        let right = normalize(cross(-n, Vec3(0, 1, 0)))
        let move = Vec3(c.moveVelocity.x, 0, c.moveVelocity.z)
        var climb = Vec3(0, 1, 0) * dot(move, -n) + right * dot(move, right)
        let speed = length(climb)
        if speed > c.climbSpeed { climb *= c.climbSpeed / speed }
        if speed > 1e-5 { sweep.slide(&pos, climb * dt, pushes: false) }

        // The hands still on climbable wall?
        let handHeight = c.height * 0.9
        let reach = c.radius + c.skinWidth + 0.3
        let hands = world(raycast: Ray(origin: pos + Vec3(0, handHeight, 0), direction: -n), reach, sweep)
        guard let hands, abs(hands.normal.y) < 0.5, isClimbable(hands.body, at: hands.point) else {
            // Over the top: pull up onto it. Otherwise (the wall ended sideways) let go.
            if climb.y >= 0, startMantle(&c, from: pos, sweep: sweep, fromGround: false) { return pos }
            letGo(&c)
            return pos
        }
        // Keep a skin from the wall (the body, at waist height).
        if let wall = sweep.cast(pos, -n, reach), abs(wall.normal.y) < 0.5 {
            pos += -n * (wall.distance - c.skinWidth)
            n = normalize(Vec3(wall.normal.x, 0, wall.normal.z))
        } else {
            n = normalize(Vec3(hands.normal.x, 0, hands.normal.z))
        }
        c.ledgeNormal = n
        c.ledgeBody = hands.body
        c.ledgePoint = hands.point
        // Climbed down onto the ground.
        if climb.y < 0, let ground = sweep.probeGround(from: pos, reach: c.skinWidth + 0.03), ground.walkable {
            c.mode = .walking
            c.isGrounded = true
            c.groundBody = ground.body
            c.groundNormal = ground.normal
            c.ledgeBody = nil
        }
        return pos
    }

    private func world(raycast ray: Ray, _ distance: Float, _ sweep: CharacterSweep) -> RaycastHit? {
        raycast(ray, maxDistance: distance, filter: sweep.filter)
    }
}

extension CharacterSweep {
    /// Whether a capsule of this radius and `height` at `feet` overlaps nothing.
    func fits(_ feet: Vec3, height: Float) -> Bool {
        let capsule = Shape(CharacterController.capsule(radius: c.radius, height: height))
        let pose = Pose(position: feet + Vec3(0, height / 2, 0))
        var clear = true
        world.tree.query(capsule.bounds(at: pose)) { i in
            guard world.accepts(i, filter), let target = world.bodies[i].shape else { return true }
            let points = Narrowphase.collide(capsule, pose, target, world.bodies[i].shapePose, margin: 0)
            if points.contains(where: { $0.separation < -1e-3 }) { clear = false }
            return clear
        }
        return clear
    }

    /// A ledge whose top is `low...high` above `feet`, in `direction` (horizontal; zero looks all
    /// around and takes the nearest). `hangs`: the character must fit hanging from it.
    func findLedge(from feet: Vec3, toward direction: Vec3, low: Float, high: Float, hangs: Bool) -> CharacterLedge? {
        let flat = Vec3(direction.x, 0, direction.z)
        var directions: [Vec3]
        if lengthSquared(flat) > 1e-6 {
            directions = [normalize(flat)]
        } else {
            directions = (0..<8).map { k in
                let a = Float(k) * .pi / 4
                return Vec3(sinf(a), 0, -cosf(a))
            }
        }
        var best: (ledge: CharacterLedge, distance: Float)?
        for d in directions {
            guard let ledge = ledge(from: feet, d, low: low, high: high, hangs: hangs) else { continue }
            let distance = length(Vec3(ledge.point.x - feet.x, 0, ledge.point.z - feet.z))
            if best == nil || distance < best!.distance { best = (ledge, distance) }
        }
        return best?.ledge
    }

    private func ledge(from feet: Vec3, _ d: Vec3, low: Float, high: Float, hangs: Bool) -> CharacterLedge? {
        let reach = c.radius + 0.45
        // The wall: forward rays from the axis, from the top of the range down.
        var wall: RaycastHit?
        var y = high
        while y >= low - 0.06 {
            // A ray starting inside something (a ceiling) hits at 0: not a wall in front.
            if let hit = world.raycast(Ray(origin: feet + Vec3(0, y, 0), direction: d), maxDistance: reach, filter: filter),
               hit.distance > 0.01, abs(hit.normal.y) < 0.6 {
                wall = hit
                break
            }
            y -= 0.1
        }
        guard let wall else { return nil }
        let wallNormal = normalize(Vec3(wall.normal.x, 0, wall.normal.z))
        // The top: a ray down from above, just past the wall; it must start in free space.
        let probe = Vec3(wall.point.x, feet.y + high + 0.1, wall.point.z) - wallNormal * 0.08
        guard world.overlap(.sphere(radius: 0.02), pose: Pose(position: probe), filter: filter).isEmpty,
              let top = world.raycast(Ray(origin: probe, direction: Vec3(0, -1, 0)), maxDistance: high - low + 0.2, filter: filter),
              top.distance > 0.01, top.normal.y >= walkable else { return nil }
        let height = top.point.y - feet.y
        guard height >= low - 1e-3, height <= high + 1e-3 else { return nil }
        // The face just under the top: the edge is its point at the top's height.
        var edge = Vec3(wall.point.x, top.point.y, wall.point.z)
        var normal = wallNormal
        if let face = world.raycast(Ray(origin: Vec3(feet.x, top.point.y - 0.04, feet.z), direction: d), maxDistance: reach + 0.1, filter: filter),
           face.distance > 0.01, abs(face.normal.y) < 0.6 {
            edge = Vec3(face.point.x, top.point.y, face.point.z)
            normal = normalize(Vec3(face.normal.x, 0, face.normal.z))
        }
        let hang = PhysicsWorld.hangPosition(c, point: edge, normal: normal)
        if hangs && !fits(hang, height: c.height) { return nil }
        return CharacterLedge(point: edge, normal: normal, body: top.body, hang: hang)
    }
}
