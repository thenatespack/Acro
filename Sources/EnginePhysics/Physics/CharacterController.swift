#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineScene

// A kinematic capsule character controller built on the shape-cast queries. It doesn't
// simulate a body: each fixed step it moves a capsule through the world itself and the game
// moves a kinematic body (or entity) to where it ended up, so triggers fire and the character
// carries nothing but itself.
//
// One `moveCharacter` step:
// 1. Depenetrate (a platform may have moved into the capsule).
// 2. Carry: move with the velocity of what it stands on (a kinematic platform's last step, a
//    dynamic body's velocity).
// 3. Jump / gravity into `verticalVelocity`.
// 4. Walk: the wanted horizontal motion, along the ground plane when grounded, as collide-and-
//    slide: sweep the capsule, stop `skinWidth` short of the surface, slide the rest along it
//    (up to `maxIterations`, creases handled). Surfaces steeper than `maxSlopeAngle` act as
//    walls (no climbing). A wall that blocks a grounded walker is tried as a step: up by at
//    most `stepHeight` (less under a ceiling), forward, down onto walkable ground; taken if it
//    gets further than sliding did.
// 5. Fall (airborne only): the vertical motion slid the same way, so steep slopes slide the
//    character down.
// 6. Ground probe straight down (up to `stepHeight` when it was grounded, which snaps it to
//    the stair or slope below). Ground counts when its normal is within `maxSlopeAngle`; an
//    edge's normal (a stair nosing) is replaced by the surface under the capsule's axis.
// 7. Dynamic bodies it ran into along the way are pushed with `pushForce` (for one step).
// Everything is a function of the world's state and the inputs, in a fixed order.
//
// Version 2 moves (CharacterControllerMoves.swift) run instead of steps 2-6 outside `.walking`:
// crouching (a shorter capsule, standing up only when there is room), hanging from a ledge
// (grabbed with `grabLedge`, or caught while falling toward it with `grabLedges`), mantling onto
// it, and climbing surfaces whose physics material is `climbable`. Platforms carry the
// character in every mode; jumping off a rising one adds its upward speed.

/// A capsule character: settings, this step's input and the state the controller keeps. As a
/// component (with a kinematic `Collider` / `RigidBody` on the same entity so triggers see it),
/// the "character" system moves the entity's `Transform.position` (the feet) each fixed step.
/// Without ECS call `PhysicsWorld.moveCharacter`.
public struct CharacterController: Component, Codable, Equatable, Sendable {
    public static let componentName = "CharacterController"
    public static var fieldHints: [String: FieldHints] {
        ["radius": FieldHints(range: 0.05...2, step: 0.01), "height": FieldHints(range: 0.2...4, step: 0.01, tooltip: "Total, caps included; the entity origin is at the feet"),
         "skinWidth": FieldHints(range: 0.001...0.2, step: 0.001, tooltip: "Gap kept to surfaces"),
         "maxSlopeAngle": FieldHints(range: 0...89, step: 1, tooltip: "Degrees; steeper ground can't be walked on and slides the character down"),
         "stepHeight": FieldHints(range: 0...2, step: 0.01, tooltip: "Highest stair stepped up; the drop it stays on the ground over"),
         "gravityScale": FieldHints(range: -10...10, step: 0.1), "jumpSpeed": FieldHints(range: 0...30, step: 0.1),
         "pushForce": FieldHints(range: 0...100_000, step: 10, tooltip: "N applied to dynamic bodies it walks into"),
         "collisionMask": FieldHints(tooltip: "Layers it collides with"),
         "maxIterations": FieldHints(range: 1...8, step: 1),
         "moveVelocity": FieldHints(tooltip: "Wanted m/s in world space (y ignored); set by game code"),
         "jump": FieldHints(tooltip: "Jump on the next step if grounded; cleared by the step"),
         "verticalVelocity": FieldHints(tooltip: "Written by the controller"),
         "crouchHeight": FieldHints(range: 0.2...4, step: 0.01, tooltip: "Capsule height while crouching (total, caps included)"),
         "crouchSpeedScale": FieldHints(range: 0...1, step: 0.05, tooltip: "Walking speed multiplier while crouching"),
         "grabLedges": FieldHints(tooltip: "Catch ledges automatically while falling toward them"),
         "climbSpeed": FieldHints(range: 0...20, step: 0.1, tooltip: "m/s on climbable surfaces (0: never climbs)"),
         "mantleTime": FieldHints(range: 0.05...3, step: 0.05, tooltip: "Seconds to pull up onto a ledge"),
         "crouch": FieldHints(tooltip: "Crouch while set; stands up when cleared and there is room"),
         "grabLedge": FieldHints(tooltip: "Grab a ledge within reach on the next step; cleared by the step"),
         "mantle": FieldHints(tooltip: "Pull up onto the ledge it hangs from (or a low wall in front); cleared by the step"),
         "drop": FieldHints(tooltip: "Let go of a ledge or climbing surface; cleared by the step"),
         "mode": FieldHints(tooltip: "Written by the controller: walking, hanging, mantling or climbing"),
         "isCrouching": FieldHints(tooltip: "Written by the controller")]
    }

    // Settings.
    public var radius: Float
    /// Total height, caps included. The entity origin (and `moveCharacter`'s position) is at the feet.
    public var height: Float
    /// The gap kept between the capsule and surfaces, so sweeps never start touching.
    public var skinWidth: Float
    /// Degrees from horizontal; steeper ground is a wall for walking and slides the character down.
    public var maxSlopeAngle: Float
    /// The highest stair it steps up, and how far down it still sticks to the ground.
    public var stepHeight: Float
    public var gravityScale: Float
    public var jumpSpeed: Float
    /// Newtons applied (for one step) to dynamic bodies it walks into.
    public var pushForce: Float
    /// Layers it collides with.
    public var collisionMask: UInt32
    /// Slide iterations per sweep.
    public var maxIterations: Int

    // Input.
    /// The wanted velocity in world space (m/s); y is ignored.
    public var moveVelocity: Vec3
    /// Jump on the next step if grounded; the step clears it.
    public var jump: Bool

    // State, written by the controller.
    public var verticalVelocity: Float
    public var isGrounded: Bool
    /// The ground's normal while grounded (up otherwise).
    public var groundNormal: Vec3
    /// The velocity of the ground it stands on (a platform it is carried by).
    public var groundVelocity: Vec3
    /// On ground steeper than `maxSlopeAngle` (it is sliding down it).
    public var isSliding: Bool
    /// What it stands on (not saved).
    public var groundBody: BodyID?
    /// Horizontal velocity kept while airborne: what it left the ground with (a platform's) and
    /// what sliding down a steep slope gave it.
    public var launchVelocity: Vec3

    // Version 2 settings.
    /// Capsule height while crouching (total, caps included).
    public var crouchHeight: Float
    /// Multiplies `moveVelocity` while crouching on the ground.
    public var crouchSpeedScale: Float
    /// Catch a ledge automatically when falling past one while moving toward it.
    public var grabLedges: Bool
    /// Speed on surfaces whose physics material is `climbable` (0: never climbs).
    public var climbSpeed: Float
    /// Seconds a mantle (pulling up onto a ledge) takes.
    public var mantleTime: Float

    // Version 2 input.
    /// Crouch while set. Clearing it stands up as soon as there is room above.
    public var crouch: Bool
    /// Grab a ledge within reach on the next step (cleared by the step).
    public var grabLedge: Bool
    /// Pull up onto the ledge it hangs from, or onto a low wall in front while on the ground (cleared by the step).
    public var mantle: Bool
    /// Let go of a ledge or a climbing surface (cleared by the step).
    public var drop: Bool

    // Version 2 state, written by the controller.
    public var mode: CharacterMode
    public var isCrouching: Bool
    /// Hanging, mantling: the ledge's edge, where the hands are. Climbing: where the hands
    /// touch the wall.
    public var ledgePoint: Vec3
    /// The wall's horizontal normal under the ledge (or of the climbed surface).
    public var ledgeNormal: Vec3
    /// What it hangs from or climbs (not saved).
    public var ledgeBody: BodyID?
    /// Mantling: start, the point above the start at the top's height, and the end on the top.
    public var mantleFrom: Vec3
    public var mantleTo: Vec3
    /// Mantling: 0...1.
    public var mantleProgress: Float

    private enum CodingKeys: String, CodingKey {
        case radius, height, skinWidth, maxSlopeAngle, stepHeight, gravityScale, jumpSpeed, pushForce, collisionMask
        case maxIterations, moveVelocity, jump, verticalVelocity, isGrounded, groundNormal, groundVelocity, isSliding
        case launchVelocity
        case crouchHeight, crouchSpeedScale, grabLedges, climbSpeed, mantleTime, crouch, grabLedge, mantle, drop, mode, isCrouching
        case ledgePoint, ledgeNormal, mantleFrom, mantleTo, mantleProgress
    }

    public init(radius: Float = 0.3, height: Float = 1.8, skinWidth: Float = 0.02, maxSlopeAngle: Float = 45,
                stepHeight: Float = 0.35, gravityScale: Float = 1, jumpSpeed: Float = 5.5, pushForce: Float = 400,
                collisionMask: UInt32 = .max, maxIterations: Int = 4) {
        self.radius = radius
        self.height = height
        self.skinWidth = skinWidth
        self.maxSlopeAngle = maxSlopeAngle
        self.stepHeight = stepHeight
        self.gravityScale = gravityScale
        self.jumpSpeed = jumpSpeed
        self.pushForce = pushForce
        self.collisionMask = collisionMask
        self.maxIterations = maxIterations
        moveVelocity = .zero
        jump = false
        verticalVelocity = 0
        isGrounded = false
        groundNormal = Vec3(0, 1, 0)
        groundVelocity = .zero
        isSliding = false
        groundBody = nil
        launchVelocity = .zero
        crouchHeight = 1
        crouchSpeedScale = 0.5
        grabLedges = false
        climbSpeed = 2
        mantleTime = 0.45
        crouch = false
        grabLedge = false
        mantle = false
        drop = false
        mode = .walking
        isCrouching = false
        ledgePoint = .zero
        ledgeNormal = .zero
        ledgeBody = nil
        mantleFrom = .zero
        mantleTo = .zero
        mantleProgress = 0
    }

    /// Every key is optional (scenes saved before version 2 lack its keys).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        func read<T: Decodable>(_ key: CodingKeys, _ value: inout T) throws {
            if let v = try c.decodeIfPresent(T.self, forKey: key) { value = v }
        }
        try read(.radius, &radius); try read(.height, &height); try read(.skinWidth, &skinWidth)
        try read(.maxSlopeAngle, &maxSlopeAngle); try read(.stepHeight, &stepHeight); try read(.gravityScale, &gravityScale)
        try read(.jumpSpeed, &jumpSpeed); try read(.pushForce, &pushForce); try read(.collisionMask, &collisionMask)
        try read(.maxIterations, &maxIterations); try read(.moveVelocity, &moveVelocity); try read(.jump, &jump)
        try read(.verticalVelocity, &verticalVelocity); try read(.isGrounded, &isGrounded); try read(.groundNormal, &groundNormal)
        try read(.groundVelocity, &groundVelocity); try read(.isSliding, &isSliding); try read(.launchVelocity, &launchVelocity)
        try read(.crouchHeight, &crouchHeight); try read(.crouchSpeedScale, &crouchSpeedScale); try read(.grabLedges, &grabLedges)
        try read(.climbSpeed, &climbSpeed); try read(.mantleTime, &mantleTime); try read(.crouch, &crouch)
        try read(.grabLedge, &grabLedge); try read(.mantle, &mantle); try read(.drop, &drop); try read(.mode, &mode)
        try read(.isCrouching, &isCrouching); try read(.ledgePoint, &ledgePoint); try read(.ledgeNormal, &ledgeNormal)
        try read(.mantleFrom, &mantleFrom); try read(.mantleTo, &mantleTo); try read(.mantleProgress, &mantleProgress)
    }

    /// The capsule height now: `crouchHeight` while crouching, else `height`.
    public var currentHeight: Float { isCrouching ? min(max(crouchHeight, radius * 2), height) : height }

    /// The capsule's collision shape (to put on the entity's `Collider`, offset up by
    /// `colliderOffset` so its feet are at the origin). It follows `currentHeight`: the
    /// "character" system updates a capsule `Collider` on the entity when crouching changes.
    public var colliderShape: ColliderShape { Self.capsule(radius: radius, height: currentHeight) }
    public var colliderOffset: Vec3 { Vec3(0, currentHeight / 2, 0) }

    static func capsule(radius: Float, height: Float) -> ColliderShape { .capsule(radius: radius, halfHeight: max(height / 2 - radius, 0)) }

    /// Where the hands go while hanging, mantling or climbing (IK targets: `Animator.setIKTarget`),
    /// shoulder width apart along the ledge; nil while walking. Left and right as seen by the
    /// character facing the wall.
    public var handTargets: (left: Vec3, right: Vec3)? {
        guard mode != .walking, lengthSquared(ledgeNormal) > 1e-6 else { return nil }
        let right = normalize(cross(-ledgeNormal, Vec3(0, 1, 0)))
        let half = max(radius * 0.8, 0.12)
        return (ledgePoint - right * half, ledgePoint + right * half)
    }
}

/// What a `CharacterController` is doing.
public enum CharacterMode: String, Codable, Sendable, CaseIterable {
    /// On the ground or in the air (walking, jumping, falling, sliding).
    case walking
    /// Hanging from a ledge by the hands.
    case hanging
    /// Pulling up onto a ledge (scripted motion over `mantleTime`).
    case mantling
    /// On a climbable surface.
    case climbing
}

extension PhysicsWorld {
    /// Moves the character one step of `dt` from the feet position `position`, returns where it
    /// ends up and updates `controller` (grounded, velocities, ...). Pass the character's
    /// kinematic `body` (a capsule from `colliderShape` / `colliderOffset` in a body frame at the
    /// feet) to have it skipped by the queries and moved there with `moveKinematic`, which
    /// also fires triggers. Dynamic bodies it walks into get `pushForce` as an impulse.
    @discardableResult
    public func moveCharacter(_ controller: inout CharacterController, from position: Vec3, dt: Float, body: BodyID? = nil) -> Vec3 {
        stepCharacter(&controller, from: position, dt: dt, body: body, sideEffects: true)
    }

    /// The same step as `moveCharacter` without touching the world: no pushes, and `body` (only
    /// skipped by the queries) isn't moved. Re-runnable from any saved `controller` and
    /// position, which is what client-side prediction needs: rewind to the server's state and
    /// replay the inputs since (see `NetCharacterPrediction`). The position and controller it
    /// produces are exactly `moveCharacter`'s in the same world.
    @discardableResult
    public func predictCharacter(_ controller: inout CharacterController, from position: Vec3, dt: Float, ignoring body: BodyID? = nil) -> Vec3 {
        stepCharacter(&controller, from: position, dt: dt, body: body, sideEffects: false)
    }

    private func stepCharacter(_ controller: inout CharacterController, from position: Vec3, dt: Float, body: BodyID?, sideEffects: Bool) -> Vec3 {
        guard dt > 0 else { return position }
        var c = controller
        var pos = position
        updateCrouch(&c, at: pos, body: body)
        var sweep = CharacterSweep(world: self, controller: c, body: body)
        sweep.depenetrate(&pos)
        if c.mode != .walking {
            pos = stepMove(&c, from: pos, dt: dt, sweep: sweep)
            c.jump = false
            c.grabLedge = false
            c.mantle = false
            c.drop = false
            controller = c
            if sideEffects, let body, let current = self.pose(of: body) {
                moveKinematic(body, to: Pose(position: pos, rotation: current.rotation), dt: dt)
            }
            return pos
        }
        // Mantle onto a low wall in front, from the ground.
        if c.mantle && c.isGrounded, startMantle(&c, from: pos, sweep: sweep, fromGround: true) {
            c.mantle = false
            c.jump = false
            c.grabLedge = false
            c.drop = false
            controller = c
            return pos
        }

        // Carry: the ground's own motion, as a sweep (so platforms can't push it through walls).
        c.groundVelocity = .zero
        if let ground = c.groundBody, contains(ground) {
            c.groundVelocity = velocity(of: ground, at: pos)
            _ = sweep.slide(&pos, c.groundVelocity * dt, pushes: false)
        } else {
            c.groundBody = nil
        }

        var wasGrounded = c.isGrounded
        let gravityY = gravity.y * c.gravityScale
        var jumped = false
        if wasGrounded && c.jump {
            // Off a rising platform the jump keeps its upward speed.
            c.verticalVelocity = c.jumpSpeed + max(c.groundVelocity.y, 0)
            c.launchVelocity = Vec3(c.groundVelocity.x, 0, c.groundVelocity.z)
            wasGrounded = false
            jumped = true
        } else if wasGrounded {
            c.verticalVelocity = 0
        } else {
            c.verticalVelocity = max(c.verticalVelocity + gravityY * dt, -60)
        }
        c.jump = false

        // Walk.
        let speedScale: Float = c.isCrouching && wasGrounded ? max(c.crouchSpeedScale, 0) : 1
        var wanted = Vec3(c.moveVelocity.x, 0, c.moveVelocity.z) * (dt * speedScale)
        if !wasGrounded { wanted += Vec3(c.launchVelocity.x, 0, c.launchVelocity.z) * dt }
        let flat = wanted
        if wasGrounded {
            // Along the ground plane, at the same speed.
            let n = c.groundNormal
            let along = wanted - n * dot(wanted, n)
            let l = length(along)
            if l > 1e-6 { wanted = along * (length(wanted) / l) }
        }
        let start = pos
        let walk = sweep.slide(&pos, wanted, pushes: true)
        if wasGrounded, let wall = walk.wall, let stepped = sweep.stepUp(from: start, flat: flat, slid: pos, wall: wall) { pos = stepped }
        var hits = walk.hits

        // Fall.
        if !wasGrounded {
            let before = pos
            let fall = sweep.slide(&pos, Vec3(0, c.verticalVelocity * dt, 0), pushes: true)
            if !fall.hits.isEmpty {
                // Slid along a surface: the speed it keeps, sideways too (down a steep slope it builds up).
                let moved = (pos - before) / dt
                c.verticalVelocity = moved.y
                c.launchVelocity += Vec3(moved.x, 0, moved.z)
                if length(c.launchVelocity) > 30 { c.launchVelocity = normalize(c.launchVelocity) * 30 }
            }
            hits += fall.hits
        }

        // Ground.
        let rising = c.verticalVelocity > 0.01 && !wasGrounded
        let reach = wasGrounded ? c.stepHeight + c.skinWidth + 0.01 : c.skinWidth + 0.03
        c.isSliding = false
        var grounded = false
        if !rising, let probe = sweep.probeGround(from: pos, reach: reach) {
            if probe.walkable {
                pos.y -= max(probe.distance - c.skinWidth, 0)
                grounded = true
                c.groundNormal = probe.normal
                c.groundBody = probe.body
                c.verticalVelocity = 0
                c.launchVelocity = .zero
            } else {
                c.isSliding = true
            }
        }
        if !grounded {
            if wasGrounded && !jumped { c.launchVelocity = Vec3(c.groundVelocity.x, 0, c.groundVelocity.z) }
            c.groundNormal = Vec3(0, 1, 0)
            c.groundBody = nil
        }
        c.isGrounded = grounded

        // Version 2: start climbing a climbable wall it walked into, or grab a ledge.
        let hands = c.height * 1.1
        // Caught automatically only while moving toward it; `grabLedge` looks all around when standing still.
        let reaching = Vec3(c.moveVelocity.x, 0, c.moveVelocity.z) + c.launchVelocity
        if c.climbSpeed > 0 && !c.drop && !c.isCrouching, let wall = climbableWall(in: hits, moving: flat, sweep: sweep) {
            beginClimb(&c, on: wall, at: pos)
        } else if !grounded || c.grabLedge, !c.isCrouching,
                  c.grabLedge || (c.grabLedges && c.verticalVelocity <= 1 && lengthSquared(reaching) > 1e-6),
                  let ledge = sweep.findLedge(from: pos, toward: reaching,
                                              low: c.grabLedge ? c.height * 0.55 : hands - 0.12,
                                              high: c.grabLedge ? hands + 0.25 : hands + 0.08 + max(-c.verticalVelocity * dt, 0),
                                              hangs: true) {
            hang(&c, from: ledge)
            pos = ledge.hang
        }
        c.grabLedge = false
        c.mantle = false
        c.drop = false

        // Push what it ran into (once per body), along the way it is walking.
        if sideEffects, c.pushForce > 0, lengthSquared(flat) > 1e-12 {
            let direction = normalize(flat)
            var pushed: [BodyID] = []
            for hit in hits where hit.normal.y < sweep.walkable && !pushed.contains(hit.body) && motion(of: hit.body) == .dynamic {
                if dot(direction, -hit.normal) > 0.1 { applyImpulse(hit.body, direction * (c.pushForce * dt)) }
                pushed.append(hit.body)
            }
        }

        controller = c
        if sideEffects, let body, let current = self.pose(of: body) {
            moveKinematic(body, to: Pose(position: pos, rotation: current.rotation), dt: dt)
        }
        return pos
    }

    /// The ECS system: moves every `CharacterController` entity (its `Transform.position`, the
    /// feet, in world space: don't parent it) one step. `addPhysics` runs it in `.fixedUpdate`
    /// before the sync, so the kinematic body follows in the same step.
    public func updateCharacters(in world: World, dt: Float) {
        var entities: [Entity] = []
        world.query(CharacterController.self) { e, _ in entities.append(e) }
        for e in entities {
            guard var controller = world.get(CharacterController.self, for: e), var transform = world.get(Transform.self, for: e) else { continue }
            let old = controller
            let position = moveCharacter(&controller, from: transform.position, dt: dt, body: body(for: e))
            if position != transform.position {
                transform.position = position
                world.add(transform, to: e)
            }
            if controller != old { world.add(controller, to: e) }
            // Crouching changed the capsule: a capsule collider on the entity follows it.
            if controller.isCrouching != old.isCrouching, var collider = world.get(Collider.self, for: e),
               case .capsule = collider.shape {
                collider.shape = controller.colliderShape
                collider.offset = controller.colliderOffset
                world.add(collider, to: e)
            }
        }
    }
}

/// The capsule and the queries one `moveCharacter` step makes.
@MainActor
struct CharacterSweep {
    let world: PhysicsWorld
    let c: CharacterController
    let shape: ColliderShape
    let baked: Shape
    let filter: QueryFilter
    /// `normal.y` at or above this is ground.
    let walkable: Float
    let down = Vec3(0, -1, 0)

    init(world: PhysicsWorld, controller: CharacterController, body: BodyID?) {
        self.world = world
        c = controller
        shape = controller.colliderShape
        baked = Shape(shape)
        // Its own ragdoll's hit boxes (a `Ragdoll` on the same entity) don't block it.
        let ragdoll = body.flatMap { world.entity(of: $0) }.map { world.ragdollBodies(of: $0) } ?? []
        filter = QueryFilter(mask: controller.collisionMask, excluding: (body.map { [$0] } ?? []) + ragdoll)
        walkable = cosf(min(max(controller.maxSlopeAngle, 0), 89.9) * .pi / 180)
    }

    func pose(_ feet: Vec3) -> Pose { Pose(position: feet + c.colliderOffset) }

    func cast(_ feet: Vec3, _ direction: Vec3, _ distance: Float) -> RaycastHit? {
        world.shapeCast(shape, pose: pose(feet), direction: direction, maxDistance: distance, filter: filter)
    }

    /// Pushes the capsule out of whatever it overlaps or is closer to than half a skin (a
    /// platform that moved into it, a spawn on the ground), so sweeps never start in contact.
    func depenetrate(_ feet: inout Vec3) {
        let wanted = c.skinWidth * 0.5
        for _ in 0..<4 {
            var found: [Int] = []
            let box = baked.bounds(at: pose(feet))
            world.tree.query(box) { i in
                if world.accepts(i, filter) { found.append(i) }
                return true
            }
            var moved = false
            for i in found.sorted() {
                let target = world.bodies[i]
                let points = Narrowphase.collide(baked, pose(feet), target.shape!, target.shapePose, margin: wanted)
                if let deepest = points.min(by: { $0.separation < $1.separation }), deepest.separation < wanted - 1e-4 {
                    feet += deepest.normal * (deepest.separation - wanted)
                    moved = true
                }
            }
            if !moved { break }
        }
    }

    struct Slide {
        var hits: [RaycastHit] = []
        /// The first thing it ran into that isn't ground (or a ceiling).
        var wall: RaycastHit?
    }

    /// Collide and slide: moves `feet` by `motion`, stopping `skinWidth` from surfaces and
    /// sliding the rest along them.
    @discardableResult
    func slide(_ feet: inout Vec3, _ motion: Vec3, pushes: Bool) -> Slide {
        var result = Slide()
        var remaining = motion
        var planes: [Vec3] = []
        for _ in 0..<max(c.maxIterations, 1) {
            let distance = length(remaining)
            if distance < 1e-5 { break }
            let direction = remaining / distance
            guard let hit = cast(feet, direction, distance + c.skinWidth) else {
                feet += remaining
                break
            }
            // Touching but not moving into it (numerical): let it pass.
            if hit.distance <= c.skinWidth && dot(direction, hit.normal) >= -1e-4 {
                feet += remaining
                break
            }
            let travel = max(hit.distance - c.skinWidth, 0)
            feet += direction * travel
            remaining = direction * max(distance - travel, 0)
            if pushes || hit.normal.y >= walkable { result.hits.append(hit) }
            var n = hit.normal
            if n.y < walkable {
                if result.wall == nil && n.y > -0.7 { result.wall = hit }
                // Steep ground is a wall while walking: sliding along it must not climb it.
                if n.y > 0 && remaining.y >= 0 { n = normalize(Vec3(n.x, 0, n.z)) }
            }
            var v = remaining - n * min(dot(remaining, n), 0)
            for p in planes where dot(v, p) < -1e-5 {
                v -= p * dot(v, p)
                if dot(v, n) < -1e-5 {
                    // Wedged between two planes: along their crease.
                    let line = normalize(cross(n, p))
                    v = line * dot(remaining, line)
                }
            }
            planes.append(n)
            remaining = v
        }
        return result
    }

    /// Ground under `feet` within `reach`: the distance down to it, its normal and whether it is
    /// walkable. A normal that isn't (the edge of a stair) is checked against the surface just
    /// behind the contact point and under the capsule's axis.
    func probeGround(from feet: Vec3, reach: Float) -> (distance: Float, normal: Vec3, walkable: Bool, body: BodyID)? {
        guard let hit = cast(feet, down, reach) else { return nil }
        var normal = hit.normal
        if normal.y < walkable {
            // Probably an edge: the surface just behind the contact point, and right under the axis.
            let inward = Vec3(-hit.normal.x, 0, -hit.normal.z)
            let behind = lengthSquared(inward) > 1e-8 ? normalize(inward) * 0.02 : .zero
            for origin in [hit.point + behind + Vec3(0, 0.1, 0), feet + Vec3(0, c.radius, 0)] {
                if let under = world.raycast(Ray(origin: origin, direction: down), maxDistance: c.radius + reach + c.skinWidth, filter: filter),
                   under.body == hit.body, abs(under.point.y - hit.point.y) < 0.03, under.normal.y >= walkable {
                    normal = under.normal
                    break
                }
            }
        }
        return (hit.distance, normal, normal.y >= walkable, hit.body)
    }

    /// Tries to get over `wall`, what blocked the walk from `start` (`slid` is where sliding
    /// ended): a ray down just behind the contact point measures the step; if its top is walkable
    /// and at most `stepHeight` above the feet, the capsule is lifted onto it (under any ceiling)
    /// and walks `flat` from there. Nil if that doesn't get further than sliding did.
    func stepUp(from start: Vec3, flat: Vec3, slid: Vec3, wall: RaycastHit) -> Vec3? {
        guard c.stepHeight > 0 else { return nil }
        let inward = Vec3(-wall.normal.x, 0, -wall.normal.z)
        guard lengthSquared(inward) > 1e-8 else { return nil }
        let origin = Vec3(wall.point.x, start.y + c.stepHeight + 0.05, wall.point.z) + normalize(inward) * 0.03
        guard let tread = world.raycast(Ray(origin: origin, direction: down), maxDistance: c.stepHeight + 0.05 + c.skinWidth, filter: filter),
              tread.normal.y >= walkable, tread.point.y > start.y + 0.005, tread.point.y <= start.y + c.stepHeight + 0.005 else { return nil }
        let lift = tread.point.y + c.skinWidth - start.y
        if let ceiling = cast(start, Vec3(0, 1, 0), lift + c.skinWidth), ceiling.distance < lift + c.skinWidth * 0.5 { return nil }
        var p = start + Vec3(0, lift, 0)
        slide(&p, flat, pushes: false)
        func horizontal(_ a: Vec3, _ b: Vec3) -> Float { length(Vec3(a.x - b.x, 0, a.z - b.z)) }
        guard horizontal(p, start) > horizontal(slid, start) + max(length(flat) * 0.25, 1e-3) else { return nil }
        return p
    }
}
