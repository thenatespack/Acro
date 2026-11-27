/// Per-guide hair dynamics for card hair (`GroomStyle.cards`; SceneRenderer+HairSim.swift draws it).
///
/// Every guide (`GroomGeometry.Guide`: the curve a card follows) is a chain of particles, its
/// root pinned to the moving scalp (the entity's transform, times the guide's skin for a skinned
/// mesh). Clump leaders (and strands without a clump) are simulated; followers take their
/// leader's offset from its rest shape at the same point along the strand, then are kept at
/// their lengths and out of the colliders; the inner layer just rides the scalp. Each frame:
/// - inertia: the strands follow `follow` (0.7) of the root's motion rigidly, so only the rest
///   of it swings them (a turned head drags the hair a little, not as if the hair stood still);
/// - substeps of at most 1/120 s, Verlet integrated: gravity (only what the rest shape doesn't
///   already hold: the grown shape hangs, so gravity acts by how far the head is tilted from
///   upright), wind (`SceneEnvironment.wind` x the groom's `wind`, gusts rolling across the
///   scene and fluttering along each strand), air damping, and a pull toward the rest shape
///   carried by the root (`stiffness`; stronger toward the root);
/// - follow-the-leader inextensibility (Müller et al. 2012, "Fast Simulation of Inextensible
///   Hair and Fur", with its velocity correction), each segment first turned toward its rest
///   direction (bending), then pushed out of the groom's `colliders` (moving with the bone
///   nearest them on a skinned mesh) and the scalp mesh, and set back to its length.
/// Points that lie on the scalp at rest (from the root, within a few millimeters of it) stay on
/// it, so partings and the hair lying along the head keep their style.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineScene

/// What a groom's simulation needs that doesn't change while it plays: the guides' rest shape
/// in the mesh's space, who follows whom, the colliders and the scalp. Built with the fur meshes
/// (on a background job); shared by every entity wearing that groom on that mesh.
final class HairRig: @unchecked Sendable {
    /// Point range of guide g: `first[g]..<first[g + 1]`.
    let first: [Int]
    let rest: [Vec3]
    /// The way each point's card faces at rest.
    let restFacing: [Vec3]
    /// Rest distance to the previous point (0 at roots), mesh space.
    let segment: [Float]
    /// 0 at the root ... 1 at the tip.
    let along: [Float]
    /// Points from the root on that lie on the scalp at rest (held there).
    let hugged: [Bool]
    let skins: [SkinInfluence?]
    /// Each card's width as a multiple of the level's (`Guide.width`).
    let widths: [Float]
    /// Per guide: -1 rides the scalp rigidly; itself when simulated; else the leader it follows.
    let leader: [Int32]
    let simulated: [Int]
    /// The groom's colliders and the joint each moves with (-1: the entity).
    let colliders: [(shape: GroomCollider, joint: Int)]
    /// Per point: bit c set when the rest point is inside collider c (left alone by it).
    let restInside: [UInt32]
    /// The scalp: the mesh the hair grows on (closest-point queries in the mesh's space), one
    /// copy per parallel batch (a query marks the triangles it visited).
    let surfaces: [GroomSurface]
    /// Guides that follow a leader or ride the scalp (not simulated themselves).
    let followers: [Int]
    /// Each guide's first vertex in a card mesh (`GroomGeometry.cardSpans`).
    let firstVertex: [Int]
    /// The most batches the simulation splits its guides into.
    static let batches = 8
    let stiffness: Float
    let windScale: Float
    /// Meters strands are kept off the colliders and the scalp (mesh space).
    let margin: Float

    var guideCount: Int { first.count - 1 }

    init(guides: [GroomGeometry.Guide], fur: MaterialFur, base: MeshGeometry?) {
        let g = fur.groom
        var first = [0], rest: [Vec3] = [], facing: [Vec3] = [], segment: [Float] = [], along: [Float] = []
        var skins: [SkinInfluence?] = [], leader: [Int32] = []
        for (i, guide) in guides.enumerated() {
            let n = guide.points.count
            for k in 0..<n {
                rest.append(guide.points[k])
                facing.append(k < guide.normals.count ? guide.normals[k] : guide.normal)
                segment.append(k == 0 ? 0 : length(guide.points[k] - guide.points[k - 1]))
                along.append(n > 1 ? Float(k) / Float(n - 1) : 0)
            }
            first.append(rest.count)
            skins.append(guide.skin)
            if n < 2 || guide.layer == .inner {
                leader.append(-1)
            } else if guide.clump >= 0, guide.clump < guides.count, guide.clump != i, guides[guide.clump].points.count >= 2,
                      guides[guide.clump].layer != .inner {
                leader.append(Int32(guide.clump))
            } else {
                leader.append(Int32(i))
            }
        }
        self.first = first
        self.rest = rest
        restFacing = facing
        self.segment = segment
        self.along = along
        self.skins = skins
        widths = guides.map { $0.width.isFinite ? max($0.width, 0.05) : 1 }
        self.leader = leader
        simulated = leader.indices.filter { leader[$0] == Int32($0) }
        followers = leader.indices.filter { leader[$0] != Int32($0) }
        var vertex = 0
        firstVertex = guides.map { guide in
            defer { if guide.points.count >= 2 { vertex += guide.points.count * 2 } }
            return vertex
        }
        stiffness = GroomGeometry.clamp01(g.stiffness)
        windScale = g.wind.isFinite ? min(max(g.wind, 0), 10) : 0
        let cardWidth = g.cardWidth.isFinite ? min(max(g.cardWidth, 0.0005), 0.5) : 0.012
        margin = 0.001 + cardWidth * 0.1

        // Colliders: on a skinned mesh, each moves with the joint of the vertex nearest its center.
        var colliders: [(GroomCollider, Int)] = []
        for collider in g.collide ? g.colliders : [] {
            var joint = -1
            if let base, let skin = base.skin, skin.count == base.vertices.count {
                var best = Float.greatestFiniteMagnitude
                for (v, vertex) in base.vertices.enumerated() {
                    let d = length(vertex.position - collider.center)
                    if d < best {
                        best = d
                        let w = skin[v].weights
                        let k = w.x >= w.y && w.x >= w.z && w.x >= w.w ? 0 : w.y >= w.z && w.y >= w.w ? 1 : w.z >= w.w ? 2 : 3
                        joint = Int(skin[v].joints[k])
                    }
                }
            }
            colliders.append((collider, joint))
        }
        self.colliders = Array(colliders.prefix(31))
        let surface = base.flatMap { $0.indices.isEmpty ? nil : GroomSurface($0, cell: max(g.clampedLength * 0.03, 0.005)) }
        surfaces = g.collide && surface != nil
            ? [surface!] + (1..<Self.batches).map { _ in GroomSurface(base!, cell: max(g.clampedLength * 0.03, 0.005)) } : []
        // Which rest points sit inside a collider (styled into it on purpose, or grown before
        // the collider was added): those leave that collider alone rather than jump out of it.
        var inside = [UInt32](repeating: 0, count: rest.count)
        for (c, collider) in self.colliders.enumerated() {
            for p in rest.indices {
                var q = rest[p]
                if collider.0.pushOut(&q, offset: 0) != nil { inside[p] |= 1 << UInt32(c) }
            }
        }
        restInside = inside
        // Points lying on the scalp, from the root on: held to the scalp.
        var hugged = [Bool](repeating: false, count: rest.count)
        if let surface = surfaces.first {
            let reach = margin + Self.clamp(g.volume, 0, 1) * min(g.clampedLength * 0.1, 0.025) + 0.006
            for guide in 0..<guides.count where leader[guide] >= 0 {
                hugged[first[guide]] = true
                for p in (first[guide] + 1)..<first[guide + 1] {
                    guard surface.closest(rest[p], within: reach) != nil else { break }
                    hugged[p] = true
                }
            }
        }
        self.hugged = hugged
    }

    private static func clamp(_ x: Float, _ lo: Float, _ hi: Float) -> Float { x.isFinite ? min(max(x, lo), hi) : lo }
}

/// One entity's hair in motion: world-space points for every guide of its `HairRig`.
struct HairSimulation {
    struct Wind {
        var direction: Vec3
        var strength: Float
        var gustiness: Float
        static let calm = Wind(direction: Vec3(1, 0, 0), strength: 0, gustiness: 0)
    }

    typealias ColliderFrame = (frame: Mat4, inverse: Mat4, center: Vec3, reach: Float)

    let rig: HairRig
    /// World positions of every guide point (the simulated ones are the state).
    private(set) var position: [Vec3]
    private var previous: [Vec3]
    /// Where each point would be at rest this frame (its root's transform times the rest shape).
    private var goal: [Vec3]
    /// Each guide's root transform (mesh to world), this frame and the last.
    private(set) var frames: [Mat4]
    private var lastFrames: [Mat4]
    private var colliderFrames: [ColliderFrame] = []
    private(set) var started = false
    /// Fraction of the root's motion the strands follow rigidly (the rest swings them).
    var follow: Float = 0.7
    /// Simulation substeps taken (for tests and timing).
    private(set) var steps = 0

    init(rig: HairRig) {
        self.rig = rig
        position = rig.rest
        previous = rig.rest
        goal = rig.rest
        frames = Array(repeating: .identity, count: rig.guideCount)
        lastFrames = frames
    }

    @inline(__always) static func point(_ m: Mat4, _ p: Vec3) -> Vec3 {
        let x = m.c0 * p.x + m.c1 * p.y + m.c2 * p.z + m.c3
        return Vec3(x.x, x.y, x.z)
    }

    @inline(__always) static func vector(_ m: Mat4, _ v: Vec3) -> Vec3 {
        let x = m.c0 * v.x + m.c1 * v.y + m.c2 * v.z
        return Vec3(x.x, x.y, x.z)
    }

    @inline(__always) static func scale(_ m: Mat4) -> Float { length(Vec3(m.c0.x, m.c0.y, m.c0.z)) }

    @inline(__always) static func direction(_ v: Vec3, _ fallback: Vec3) -> Vec3 {
        let l2 = dot(v, v)
        if l2 > 1e-14 && l2.isFinite { return v / l2.squareRoot() }
        let f2 = dot(fallback, fallback)
        return f2 > 1e-14 ? fallback / f2.squareRoot() : Vec3(0, -1, 0)
    }

    /// The root transform of guide `g` (mesh to world): `model`, times its skin's joints.
    private static func rootFrame(_ skin: SkinInfluence?, model: Mat4, joints: [Mat4]) -> Mat4 {
        guard let skin else { return model }
        var m = Mat4(.zero, .zero, .zero, .zero)
        var total: Float = 0
        for k in 0..<4 {
            let w = skin.weights[k]
            let j = Int(skin.joints[k])
            guard w > 0, j < joints.count else { continue }
            let joint = joints[j]
            m.c0 += joint.c0 * w; m.c1 += joint.c1 * w; m.c2 += joint.c2 * w; m.c3 += joint.c3 * w
            total += w
        }
        guard total > 1e-4 else { return model }
        m.c0 /= total; m.c1 /= total; m.c2 /= total; m.c3 /= total
        return model * m
    }

    /// Snaps every strand to its rest shape at the current frames.
    mutating func reset() {
        position = goal
        previous = goal
        started = true
    }

    /// What the per-guide work reads and writes (disjoint per guide, so guides run in parallel).
    private struct Kernel {
        let rig: HairRig
        let position: UnsafeMutablePointer<Vec3>
        let previous: UnsafeMutablePointer<Vec3>
        let goal: UnsafeMutablePointer<Vec3>
        let frames: UnsafePointer<Mat4>
        let lastFrames: UnsafePointer<Mat4>
        let colliders: [ColliderFrame]
        /// The motion of every root when the entity is rigid (else per guide).
        let sharedDelta: Mat4?
        let sharedInverse: Mat4?
        let follow: Float
        let substeps: Int
        let h: Float
        let time: Float
        let dt: Float
        let wind: Vec3
        let gustiness: Float

        /// Pushes world point `q` out of the colliders (but those its rest point is inside,
        /// `mask`) and, given `scalp`, out of the scalp (`inverse` maps world to mesh space).
        @inline(__always) func collide(_ q: inout Vec3, mask: UInt32, scalp: GroomSurface?, frame: Mat4, inverse: Mat4) {
            for c in colliders.indices where mask & (1 << UInt32(c)) == 0 {
                let f = colliders[c]
                let d = q - f.center
                if dot(d, d) > f.reach * f.reach { continue }
                var local = HairSimulation.point(f.inverse, q)
                if rig.colliders[c].shape.pushOut(&local, offset: rig.margin) != nil { q = HairSimulation.point(f.frame, local) }
            }
            if let scalp {
                var local = HairSimulation.point(inverse, q)
                if scalp.pushOut(&local, offset: rig.margin, within: 0.008) != nil { q = HairSimulation.point(frame, local) }
            }
        }

        /// Every substep of simulated guide `g` (`scalp`: this batch's copy of the scalp).
        func simulate(_ g: Int, scalp: GroomSurface?) {
            let a = rig.first[g], b = rig.first[g + 1]
            let frame = frames[g]
            let inverse = sharedInverse ?? frame.inverse
            // Inertia: follow `follow` of the root's motion rigidly.
            let delta = sharedDelta ?? frame * lastFrames[g].inverse
            for p in a..<b {
                position[p] += (HairSimulation.point(delta, position[p]) - position[p]) * follow
                previous[p] += (HairSimulation.point(delta, previous[p]) - previous[p]) * follow
            }
            let scale = HairSimulation.scale(frame)
            // Gravity the rest shape doesn't hold: world down minus the rest's down carried by the root.
            let restDown = HairSimulation.vector(frame, Vec3(0, -1, 0)) / max(scale, 1e-6)
            let gravity = (Vec3(0, -1, 0) - restDown) * 9.81
            // Gusts roll across the scene (as fur.glsl's) and flutter along the strand.
            let root = goal[a]
            let horizontal = SIMD2(wind.x, wind.z)
            let windLength = (horizontal * horizontal).sum().squareRoot()
            let dir = windLength > 1e-6 ? horizontal / windLength : SIMD2<Float>(1, 0)
            let phase = (SIMD2(root.x, root.z) * dir).sum() * 0.35 + (SIMD2(root.x, root.z) * SIMD2(0.83, -0.57)).sum() * 1.7
            let noise = dot(root, Vec3(3.1, 2.3, 2.7)) * 3
            let h2 = h * h
            let damping = expf(-2.5 * h)
            let stiff = rig.stiffness
            // Spring rates (1/s²) pulling toward the rest shape, root to tip, and the bending.
            let pullRoot = 60 + 900 * stiff * stiff, pullTip = 6 + 140 * stiff * stiff
            let bend = 0.04 + 0.3 * stiff
            position[a] = goal[a]
            previous[a] = goal[a]
            for s in 0..<substeps {
                // (The scalp, a mesh query, only in the last substep; the colliders in every one.)
                let lastSubstep = s == substeps - 1
                let t = time - dt + h * Float(s + 1)
                let gust = 1 + gustiness * ((0.5 + 0.5 * sinf(t * 0.61 + phase) * sinf(t * 0.23 + phase * 0.7)) * 1.6 - 0.6)
                for p in (a + 1)..<b {
                    if rig.hugged[p] {
                        position[p] = goal[p]
                        previous[p] = goal[p]
                        continue
                    }
                    let along = rig.along[p]
                    let velocity = (position[p] - previous[p]) * damping
                    previous[p] = position[p]
                    let flutter = 0.65 + 0.35 * sinf(t * 4.7 + noise - along * 3.1) * sinf(t * 2.9 + noise * 0.37 + along * 1.7)
                    let pull = pullRoot + (pullTip - pullRoot) * along
                    let acceleration = gravity + wind * (gust * flutter * 3) + (goal[p] - position[p]) * pull
                    position[p] += velocity + acceleration * h2
                }
                // Follow the leader: bend toward the rest direction, keep out of the colliders and
                // the scalp, keep the length; then pass 90% of each correction back as the
                // parent's velocity (Müller et al.'s dynamic follow-the-leader).
                for p in (a + 1)..<b {
                    if rig.hugged[p] { continue }
                    let parent = position[p - 1]
                    let restDirection = HairSimulation.direction(goal[p] - goal[p - 1], Vec3(0, -1, 0))
                    let length = rig.segment[p] * scale
                    let current = HairSimulation.direction(position[p] - parent, restDirection)
                    var q = parent + HairSimulation.direction(current * (1 - bend) + restDirection * bend, restDirection) * length
                    // Pushed out, set back to its length (which can tip it back in where the
                    // parent lies along the collider), out again: the residue is a sliver of length.
                    for _ in 0..<2 {
                        collide(&q, mask: rig.restInside[p], scalp: lastSubstep ? scalp : nil, frame: frame, inverse: inverse)
                        q = parent + HairSimulation.direction(q - parent, restDirection) * length
                    }
                    collide(&q, mask: rig.restInside[p], scalp: lastSubstep ? scalp : nil, frame: frame, inverse: inverse)
                    let correction = q - position[p]
                    position[p] = q
                    if p - 1 > a && !rig.hugged[p - 1] { previous[p - 1] += correction * 0.9 }
                }
            }
            let tip = position[b - 1]
            if !tip.x.isFinite || !tip.y.isFinite || !tip.z.isFinite {
                for p in a..<b {
                    position[p] = goal[p]
                    previous[p] = goal[p]
                }
            }
        }

        /// A follower takes its leader's offset from rest at the same point along the strand,
        /// then keeps its lengths and stays out of the colliders; the inner layer rides the scalp.
        func follow(_ g: Int) {
            let l = Int(rig.leader[g])
            let range = rig.first[g]..<rig.first[g + 1]
            guard l >= 0 else {
                for p in range { position[p] = goal[p] }
                return
            }
            let leaderFirst = rig.first[l], leaderCount = rig.first[l + 1] - leaderFirst
            let count = range.count
            let frame = frames[g]
            let scale = HairSimulation.scale(frame)
            for (k, p) in range.enumerated() {
                if rig.hugged[p] {
                    position[p] = goal[p]
                    continue
                }
                let j = leaderFirst + min(count > 1 ? k * (leaderCount - 1) / (count - 1) : 0, leaderCount - 1)
                var q = goal[p] + (position[j] - goal[j])
                let parent = position[p - 1]
                let length = rig.segment[p] * scale
                let restDirection = goal[p] - goal[p - 1]
                q = parent + HairSimulation.direction(q - parent, restDirection) * length
                for _ in 0..<2 {
                    collide(&q, mask: rig.restInside[p], scalp: nil, frame: frame, inverse: frame)
                    q = parent + HairSimulation.direction(q - parent, restDirection) * length
                }
                collide(&q, mask: rig.restInside[p], scalp: nil, frame: frame, inverse: frame)
                position[p] = q
            }
        }
    }

    /// Advances by `dt` seconds with the entity drawn at `model` (and, skinned, posed by `joints`,
    /// the mesh-space joint matrices of `SkinPose.joints`), at clock `time`, in `wind`; guides
    /// run in parallel on `jobs`.
    mutating func step(model: Mat4, joints: [Mat4]?, dt: Float, time: Float, wind: Wind, jobs: JobSystem = .shared) {
        let rig = self.rig
        let guideCount = rig.guideCount
        guard guideCount > 0 else { return }
        swap(&frames, &lastFrames)
        let rigid = joints == nil || !rig.skins.contains { $0 != nil }
        let batch = max(64, (guideCount + HairRig.batches - 1) / HairRig.batches)
        frames.withUnsafeMutableBufferPointer { frames in
            goal.withUnsafeMutableBufferPointer { goal in
                rig.rest.withUnsafeBufferPointer { rest in
                    jobs.parallelFor(0..<guideCount, batchSize: batch, name: "hair frames") { range in
                        for g in range {
                            let m = rigid ? model : Self.rootFrame(rig.skins[g], model: model, joints: joints!)
                            frames[g] = m
                            for p in rig.first[g]..<rig.first[g + 1] { goal[p] = Self.point(m, rest[p]) }
                        }
                    }
                }
            }
        }
        colliderFrames = rig.colliders.map { collider in
            let frame = collider.joint >= 0 && joints != nil && collider.joint < joints!.count ? model * joints![collider.joint] : model
            let shape = collider.shape
            let scale = max(Self.scale(frame), length(Vec3(frame.c1.x, frame.c1.y, frame.c1.z)), length(Vec3(frame.c2.x, frame.c2.y, frame.c2.z)))
            let mid = shape.end.map { (shape.center + $0) * 0.5 } ?? shape.center
            let size = shape.end.map { length($0 - shape.center) * 0.5 + shape.radius } ?? (shape.radii.map { $0.max() } ?? shape.radius)
            return (frame, frame.inverse, Self.point(frame, mid), (size + rig.margin) * scale + 1e-3)
        }
        // A first frame, a long pause or a jump (teleport, new animation): start at rest.
        let jumped = started && length(Self.point(frames[0], .zero) - Self.point(lastFrames[0], .zero)) > 1.5
        guard started, dt > 0, dt < 0.5, !jumped else {
            reset()
            return
        }
        let substeps = min(max(Int((dt * 120).rounded(.up)), 1), 4)
        let h = min(dt, 1.0 / 30) / Float(substeps)
        steps += substeps
        let shared = rigid ? (delta: model * lastFrames[0].inverse, inverse: model.inverse) : nil
        let windGustiness = wind.gustiness
        let wind = wind.direction * (wind.strength * rig.windScale)
        let colliders = colliderFrames
        let follow = self.follow
        position.withUnsafeMutableBufferPointer { position in
            previous.withUnsafeMutableBufferPointer { previous in
                goal.withUnsafeMutableBufferPointer { goal in
                    frames.withUnsafeBufferPointer { frames in
                        lastFrames.withUnsafeBufferPointer { lastFrames in
                            let kernel = Kernel(rig: rig, position: position.baseAddress!, previous: previous.baseAddress!,
                                                goal: goal.baseAddress!, frames: frames.baseAddress!, lastFrames: lastFrames.baseAddress!,
                                                colliders: colliders, sharedDelta: shared?.delta, sharedInverse: shared?.inverse,
                                                follow: follow, substeps: substeps, h: h, time: time, dt: dt, wind: wind,
                                                gustiness: windGustiness)
                            let simulated = rig.simulated
                            let simBatch = max(16, (simulated.count + HairRig.batches - 1) / HairRig.batches)
                            jobs.parallelFor(0..<simulated.count, batchSize: simBatch, name: "hair simulation") { range in
                                let scalp = rig.surfaces.isEmpty ? nil : rig.surfaces[min(range.lowerBound / simBatch, rig.surfaces.count - 1)]
                                for i in range { kernel.simulate(simulated[i], scalp: scalp) }
                            }
                            let followers = rig.followers
                            jobs.parallelFor(0..<followers.count, batchSize: max(64, (followers.count + HairRig.batches - 1) / HairRig.batches),
                                             name: "hair followers") { range in
                                for i in range { kernel.follow(followers[i]) }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Writes the cards of the first `count` guides (`GroomGeometry.writeCard`, as `cards` builds
    /// them: `width` wide at the root, `taper`) at the simulated points into `out`, world space.
    func writeCards(count: Int, width: Float, taper: Float, into out: UnsafeMutablePointer<MeshVertex>, jobs: JobSystem = .shared) {
        let rig = self.rig
        let count = min(count, rig.guideCount)
        frames.withUnsafeBufferPointer { frames in
            position.withUnsafeBufferPointer { position in
                jobs.parallelFor(0..<count, batchSize: max(64, (count + HairRig.batches - 1) / HairRig.batches), name: "hair cards") { range in
                    var facing: [Vec3] = []
                    for g in range {
                        let a = rig.first[g], b = rig.first[g + 1]
                        guard b - a >= 2 else { continue }
                        let frame = frames[g]
                        facing.removeAll(keepingCapacity: true)
                        for p in a..<b { facing.append(Self.direction(Self.vector(frame, rig.restFacing[p]), Vec3(0, 0, 1))) }
                        facing.withUnsafeBufferPointer { facing in
                            GroomGeometry.writeCard(points: UnsafeBufferPointer(rebasing: position[a..<b]), facing: facing,
                                                    width: width * rig.widths[g] * Self.scale(frame), taper: taper,
                                                    random: GroomGeometry.cardRandom(g), into: out + rig.firstVertex[g])
                        }
                    }
                }
            }
        }
    }
}
