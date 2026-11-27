#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineAssets

// The realistic humanoid (`CharacterStyle.realistic`): one continuous body from an anatomical
// distance field (CharacterHumanField.swift), meshed as the skin that shows (head and neck,
// forearms and hands) plus clothing shells over the rest (a T-shirt, trousers, shoes), with
// separate eye meshes (sclera, iris, pupil, cornea). Built in code from the rig's bones, so the
// proportion sliders move it; skin weights run along bone chains blended across each joint.
//
// Proportions of the default rig (1.77 m): 7.5 heads tall, shoulders about two head heights
// wide, elbows at the waist, wrists at the crotch, knees halfway down the leg. The head follows
// the Loomis construction: a cranium ball with the face hung in front, brow line, nose base and
// chin a third apart, eyes halfway down the head and a fifth of its width, ears between the brow
// and the nose base.

/// How a body part looks: its color from the region's (times `tint`) or fixed, roughness and opacity.
public struct CharacterPartLook: Equatable, Sendable {
    public var tint: Vec3
    /// A fixed display (sRGB) color instead of the region's.
    public var color: Vec3?
    public var roughness: Float
    /// Below 1: alpha blended (the cornea).
    public var opacity: Float

    public init(tint: Vec3 = Vec3(1, 1, 1), color: Vec3? = nil, roughness: Float = 0.75, opacity: Float = 1) {
        self.tint = tint
        self.color = color
        self.roughness = roughness
        self.opacity = opacity
    }

    /// The linear base color, given the region's display (sRGB) color.
    public func baseColor(region: Vec3) -> Vec4 {
        let c = MeshBuildColor.linear(fromSRGB: color ?? pointwiseMin(region * tint, Vec3(repeating: 1)))
        return Vec4(c.x, c.y, c.z, opacity)
    }

    /// A material asset of this look over `region`'s color.
    public func material(region: Vec3) -> MaterialAsset {
        var m = MaterialAsset(shading: .pbr, baseColor: baseColor(region: region), metallic: 0, roughness: roughness)
        if opacity < 1 { m.alphaMode = .blend }
        return m
    }

    /// A run-time material of this look over `region`'s color (scenes that register meshes directly).
    public func runtimeMaterial(region: Vec3) -> Material {
        var m = Material(baseColor: baseColor(region: region), roughness: roughness)
        if opacity < 1 { m.alphaMode = .blend }
        return m
    }
}

/// One mesh of a character's body: `name` is its region's name for the main parts ("skin",
/// "body", "legs", "accent", "eyes") or a sub-part ("lips", "nails", "shoe.sole", "eye.sclera",
/// "eye.iris", "eye.pupil", "eye.cornea").
public struct CharacterBodyPart: Sendable {
    public var name: String
    public var region: CharacterRegion
    public var geometry: MeshGeometry
    public var look: CharacterPartLook

    public init(name: String, region: CharacterRegion, geometry: MeshGeometry, look: CharacterPartLook) {
        self.name = name
        self.region = region
        self.geometry = geometry
        self.look = look
    }
}

/// The realistic body's built meshes (cached per rig).
struct HumanBodyMeshes: Sendable {
    var parts: [CharacterBodyPart]
    /// The head's skin where hair grows, 1.5 mm out, in the head bone's space.
    var scalp: MeshGeometry
    var seconds: Double
}

final class HumanBodyCache: @unchecked Sendable {
    static let shared = HumanBodyCache()
    private let lock = NSLock()
    private var entries: [String: HumanBodyMeshes] = [:]
    private var order: [String] = []

    func meshes(for rig: CharacterRig) -> HumanBodyMeshes {
        let p = rig.proportions
        let key = CharacterProportions.names.map { String(p[$0] ?? 1) }.joined(separator: ",")
        lock.lock()
        if let hit = entries[key] { lock.unlock(); return hit }
        lock.unlock()
        let built = HumanBodyBuilder(rig: rig).build()
        lock.lock()
        if entries[key] == nil { order.append(key) }
        entries[key] = built
        while order.count > 8 { entries[order.removeFirst()] = nil }
        lock.unlock()
        return built
    }
}

extension CharacterRig {
    /// The realistic human's scalp: its head skin above the hairline (forehead, temples, around
    /// the ears, the nape), 1.5 mm out, in the head bone's space; nil for other rigs. Grow hair on it
    /// (a `GroomRenderer` on an entity at the head bone's origin).
    public var humanScalp: MeshGeometry? {
        isRealisticHuman ? HumanBodyCache.shared.meshes(for: self).scalp : nil
    }

    /// Seconds the realistic body took to build (0 for other rigs or when it was cached).
    public var humanBuildSeconds: Double { isRealisticHuman ? HumanBodyCache.shared.meshes(for: self).seconds : 0 }

    /// Where the realistic head's features are, in the head bone's space (scaled with the head and
    /// the height): for fitting hair colliders and attachments.
    public var humanHead: (cranium: Vec3, craniumRadii: Vec3, eyeHeight: Float, ear: Vec3, chin: Vec3) {
        let s = proportions.head * proportions.height
        return (Vec3(0, 0.148, -0.018) * s, Vec3(0.075, 0.096, 0.097) * s, 0.124 * s, Vec3(0.074, 0.105, -0.02) * s, Vec3(0, 0.0, 0.085) * s)
    }
}

// MARK: - Building

/// Part tags (`HumanPrim.tag`, `HumanPiece.tag`).
enum HumanTag {
    static let skin: UInt8 = 0
    static let lips: UInt8 = 1
    static let nails: UInt8 = 2
    static let shirt: UInt8 = 3
    static let trousers: UInt8 = 4
    static let shoe: UInt8 = 5
    static let sole: UInt8 = 6
    static let names = ["skin", "lips", "nails", "body", "legs", "accent", "shoe.sole"]
    static let regions: [CharacterRegion] = [.skin, .skin, .skin, .body, .legs, .accent, .accent]
    static let looks: [CharacterPartLook] = [
        CharacterPartLook(roughness: 0.52),
        CharacterPartLook(tint: Vec3(0.94, 0.76, 0.74), roughness: 0.42),
        CharacterPartLook(tint: Vec3(1.04, 0.94, 0.92), roughness: 0.3),
        CharacterPartLook(roughness: 0.9),
        CharacterPartLook(roughness: 0.85),
        CharacterPartLook(roughness: 0.42),
        CharacterPartLook(color: Vec3(0.11, 0.1, 0.095), roughness: 0.8),
    ]
}

struct HumanBodyBuilder {
    let rig: CharacterRig
    let field = HumanField()
    /// Bone positions without the height scale.
    let bone: [Vec3]
    let W: Float, H: Float, A: Float, L: Float, T: Float, N: Float

    init(rig: CharacterRig) {
        self.rig = rig
        let p = rig.proportions
        bone = rig.bones.map { $0.position / p.height }
        W = p.width; H = p.head; A = p.arms; L = p.legs; T = p.torso; N = p.neck
        field.boneCount = rig.bones.count
    }

    func b(_ name: String) -> Int { rig.index(of: name) ?? 0 }

    // MARK: Prim helpers

    @discardableResult
    func add(_ prim: HumanPrim) -> Int {
        field.prims.append(prim)
        return field.prims.count - 1
    }

    func ellipsoid(_ center: Vec3, _ radii: Vec3, group: Int32, chain: Int32, k: Float, op: HumanPrim.Op = .add,
                   tag: UInt8 = 255, x: Vec3 = Vec3(1, 0, 0), y: Vec3 = Vec3(0, 1, 0)) {
        var p = HumanPrim(kind: .ellipsoid, center: center)
        let ux = normalize(x), uz = normalize(cross(ux, normalize(y))), uy = cross(uz, ux)
        p.setAxes(x: ux, y: uy, z: uz)
        p.a = radii.x; p.b = radii.y; p.c = radii.z
        p.group = group; p.chain = chain; p.k = k; p.op = op; p.tag = tag
        add(p)
    }

    func sphere(_ center: Vec3, _ r: Float, group: Int32, chain: Int32, k: Float, op: HumanPrim.Op = .add, tag: UInt8 = 255) {
        var p = HumanPrim(kind: .sphere, center: center)
        p.a = r
        p.group = group; p.chain = chain; p.k = k; p.op = op; p.tag = tag
        add(p)
    }

    /// A round cone from `a` (radius r1) to `b` (radius r2); its cross-section scaled by `sx` along
    /// `side` and `sz` across both.
    func cone(_ a: Vec3, _ b: Vec3, _ r1: Float, _ r2: Float, group: Int32, chain: Int32, k: Float, op: HumanPrim.Op = .add,
              tag: UInt8 = 255, side: Vec3 = Vec3(1, 0, 0), sx: Float = 1, sz: Float = 1) {
        var p = HumanPrim(kind: .cone, center: a)
        let h = max(length(b - a), 1e-5)
        let uy = (b - a) / h
        var ux = side - uy * dot(side, uy)
        if length(ux) < 1e-4 { ux = abs(uy.x) < 0.9 ? Vec3(1, 0, 0) : Vec3(0, 0, 1); ux -= uy * dot(ux, uy) }
        ux = normalize(ux)
        let uz = cross(ux, uy)
        p.setAxes(x: ux, y: uy, z: uz)
        p.a = r1; p.b = r2; p.d = h; p.e = sx; p.f = sz
        p.group = group; p.chain = chain; p.k = k; p.op = op; p.tag = tag
        add(p)
    }

    func torus(_ center: Vec3, normal: Vec3, front: Vec3, radii: Vec2, tube: Float, group: Int32, chain: Int32, k: Float, op: HumanPrim.Op = .add) {
        var p = HumanPrim(kind: .torus, center: center)
        let uy = normalize(normal)
        let uz = normalize(front - uy * dot(front, uy))
        let ux = cross(uy, uz)
        p.setAxes(x: ux, y: uy, z: uz)
        p.a = radii.x; p.c = radii.y; p.b = tube
        p.group = group; p.chain = chain; p.k = k; p.op = op
        add(p)
    }

    func group(_ g: HumanGroup) -> Int32 {
        field.groups.append(g)
        return Int32(field.groups.count - 1)
    }

    func chain(_ c: HumanChain) -> Int32 {
        field.chains.append(c)
        return Int32(field.chains.count - 1)
    }

    // MARK: Body

    /// Default torso heights (rig at proportion 1) mapped through the actual spine.
    func ty(_ y: Float) -> Float {
        let knots: [(Float, Int)] = [(0.94, b("hips")), (1.04, b("spine")), (1.24, b("chest")), (1.44, b("neck")), (1.52, b("head"))]
        if y <= knots[0].0 { return bone[knots[0].1].y + (y - knots[0].0) }
        for i in 1..<knots.count where y <= knots[i].0 {
            let t = (y - knots[i - 1].0) / (knots[i].0 - knots[i - 1].0)
            return bone[knots[i - 1].1].y + (bone[knots[i].1].y - bone[knots[i - 1].1].y) * t
        }
        return bone[knots.last!.1].y + (y - knots.last!.0)
    }

    /// A torso point from default coordinates.
    func tp(_ x: Float, _ y: Float, _ z: Float) -> Vec3 { Vec3(x * W, ty(y), z * W) }
    /// Torso radii (vertical ones follow the torso slider).
    func tr(_ x: Float, _ y: Float, _ z: Float) -> Vec3 { Vec3(x * W, y * T, z * W) }
    /// A head point from head-local coordinates (origin at the head bone).
    func hp(_ x: Float, _ y: Float, _ z: Float) -> Vec3 { bone[b("head")] + Vec3(x, y, z) * H }

    func build() -> HumanBodyMeshes {
        let start = Date()
        let hips = b("hips"), spine = b("spine"), chest = b("chest"), neck = b("neck"), head = b("head")

        // Weight chains.
        let up = Vec3(0, 1, 0)
        let torsoChain = chain(HumanChain(bones: [hips, spine, chest, neck, head], joints: [
            (bone[spine], up, 0.07), (bone[chest] - Vec3(0, 0.02, 0), up, 0.09), (bone[neck] + Vec3(0, 0.035, 0), up, 0.035),
            (bone[head] + Vec3(0, 0.02, 0), up, 0.03),
        ]))
        let headChain = chain(HumanChain(bones: [neck, head], joints: [(bone[head] - Vec3(0, 0.015, 0), up, 0.02)]))

        // Groups, in join order.
        let gTorso = group(HumanGroup(kNear: 0))
        let gNeck = group(HumanGroup(kNear: 0.03 * W))
        let gHead = group(HumanGroup(kNear: 0.022))
        buildTorso(group: gTorso, chain: torsoChain)
        buildNeck(group: gNeck, chain: torsoChain)
        buildHead(group: gHead, chain: headChain)
        var armGroups: [Int32] = [], legGroups: [Int32] = [], handGroups: [[Int32]] = [], shoeGroups: [Int32] = []
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            let (arm, hand) = buildArm(side: side, s: s, torsoChain: torsoChain)
            armGroups.append(arm)
            handGroups.append(hand)
        }
        for (side, s) in [("L", Float(1)), ("R", Float(-1))] {
            let (leg, shoe) = buildLeg(side: side, s: s)
            legGroups.append(leg)
            shoeGroups.append(shoe)
        }
        field.finish()

        // Pieces.
        typealias Post = (Float, Float, Float, Float) -> Float
        var jobs: [(piece: HumanPiece, post: Post)] = []
        let headPos = bone[head]
        let shirt = shirtShape(armGroups: armGroups)
        var headPiece = HumanPiece(kind: .skin, groups: [gTorso, gNeck, gHead],
                                   lo: Vec3(-0.17 * W - 0.02, ty(1.37), headPos.z - 0.14 * H),
                                   hi: Vec3(0.17 * W + 0.02, headPos.y + 0.26 * H, headPos.z + 0.14 * H),
                                   fineLo: Vec3(-0.088 * H, headPos.y - 0.005 * H, headPos.z - 0.06 * H),
                                   fineHi: Vec3(0.088 * H, headPos.y + 0.215 * H, headPos.z + 0.13 * H),
                                   fine: 0.0017 * H, coarse: 0.0042, tag: HumanTag.skin)
        headPiece.keep = [(Vec3(0, ty(1.385), 0), up)]
        jobs.append((headPiece, { _, _, _, d in d }))

        for (i, s) in [Float(1), -1].enumerated() {
            let shoulder = bone[b(i == 0 ? "upperArm.L" : "upperArm.R")], elbow = bone[b(i == 0 ? "lowerArm.L" : "lowerArm.R")]
            let wrist = bone[b(i == 0 ? "hand.L" : "hand.R")]
            let along = normalize(elbow - shoulder)
            let cut = shoulder + (elbow - shoulder) * 0.42
            let hs = (A * W).squareRoot()
            let tip = wrist + normalize(wrist - elbow) * 0.2 * hs
            var piece = HumanPiece(kind: .skin, groups: Set([armGroups[i]] + handGroups[i]),
                                   lo: pointwiseMin(cut, tip) - Vec3(0.075, 0.01, 0.075) * W,
                                   hi: pointwiseMax(cut, tip) + Vec3(0.075, 0.01, 0.075) * W,
                                   fineLo: Vec3(min(wrist.x, tip.x) - 0.05, tip.y - 0.01, -0.07), fineHi: Vec3(max(wrist.x, tip.x) + 0.05, wrist.y + 0.03, 0.08),
                                   fine: 0.0021 * hs, coarse: 0.0036, tag: HumanTag.skin)
            piece.keep = [(cut, along)]
            _ = s
            jobs.append((piece, { _, _, _, d in d }))
        }

        let shirtPiece = HumanPiece(kind: .shirt, groups: Set([gTorso, gNeck] + armGroups),
                                    lo: Vec3(-0.32 * W, ty(0.86), -0.17 * W), hi: Vec3(0.32 * W, ty(1.56), 0.17 * W),
                                    fineLo: Vec3(-0.11 * W, ty(1.4), -0.12 * W), fineHi: Vec3(0.11 * W, ty(1.53), 0.12 * W),
                                    fine: 0.003, coarse: 0.0055, tag: HumanTag.shirt)
        jobs.append((shirtPiece, shirt))

        let trousers = trouserShape(legGroups: legGroups)
        let trouserPiece = HumanPiece(kind: .trousers, groups: Set([gTorso] + legGroups),
                                      lo: Vec3(-0.24 * W, 0.04, -0.17 * W), hi: Vec3(0.24 * W, ty(1.06), 0.17 * W),
                                      fineLo: .zero, fineHi: .zero, fine: 0.0055, coarse: 0.0055, tag: HumanTag.trousers)
        jobs.append((trouserPiece, trousers))

        for (i, s) in [Float(1), -1].enumerated() {
            let foot = bone[b(i == 0 ? "foot.L" : "foot.R")]
            let fs = L.squareRoot()
            let shoePiece = HumanPiece(kind: .shoes, groups: [shoeGroups[i]],
                                       lo: Vec3(foot.x - 0.07, -0.01, foot.z - 0.1 * fs), hi: Vec3(foot.x + 0.07, foot.y + 0.08, foot.z + 0.25 * fs),
                                       fineLo: .zero, fineHi: .zero, fine: 0.0034, coarse: 0.0034, tag: HumanTag.shoe)
            _ = s
            jobs.append((shoePiece, shoeShape(group: shoeGroups[i], foot: foot)))
        }
        // Every piece at once (each also spreads its own work over the cores).
        var results = [HumanSurface](repeating: HumanSurface(), count: jobs.count)
        results.withUnsafeMutableBufferPointer { out in
            concurrentPerform(iterations: jobs.count) { j in out[j] = mesh(jobs[j].piece, post: jobs[j].post) }
        }
        let surfaces = zip(jobs.map(\.piece), results).map { ($0, $1) }

        // Parts by tag, smoothed weights, scaled to the rig's height.
        let scale = rig.proportions.height
        var byTag: [UInt8: MeshGeometry] = [:]
        for (_, surface) in surfaces {
            append(surface, scale: scale, to: &byTag)
        }
        var parts: [CharacterBodyPart] = []
        for tag in UInt8(0)..<UInt8(HumanTag.names.count) {
            guard let geometry = byTag[tag], !geometry.indices.isEmpty else { continue }
            parts.append(CharacterBodyPart(name: HumanTag.names[Int(tag)], region: HumanTag.regions[Int(tag)], geometry: geometry,
                                           look: HumanTag.looks[Int(tag)]))
        }
        parts += eyeParts(scale: scale)
        let scalp = scalpMesh(surfaces[0].1, scale: scale)
        return HumanBodyMeshes(parts: parts, scalp: scalp, seconds: Date().timeIntervalSince(start))
    }

    func mesh(_ piece: HumanPiece, post: @escaping (Float, Float, Float, Float) -> Float) -> HumanSurface {
        let keep = piece.keep
        let start = Date()
        let mesher = HumanMesher(field: field, piece: piece, post: { x, y, z, d in
            var v = post(x, y, z, d)
            for plane in keep {
                v = max(v, -((x - plane.point.x) * plane.normal.x + (y - plane.point.y) * plane.normal.y + (z - plane.point.z) * plane.normal.z))
            }
            return v
        })
        var surface = mesher.contour()
        if piece.kind == .shoes {
            // The sole is everything below its top edge.
            for v in surface.positions.indices where surface.positions[v].y < 0.0215 { surface.tags[v] = HumanTag.sole }
        }
        let meshed = Date(), before = surface.triangles.count
        surface.simplify(tolerance: piece.kind == .skin ? 0.00015 : piece.kind == .shoes ? 0.00025 : 0.0004, keep: 0.22)
        let simplified = Date()
        mesher.finish(&surface)
        if ProcessInfo.processInfo.environment["HUMAN_TIMING"] == "1" {
            print(String(format: "Human: %@ piece %.0f ms + simplify %.0f ms + finish %.0f ms, %d -> %d triangles", "\(piece.kind)",
                         meshed.timeIntervalSince(start) * 1000, simplified.timeIntervalSince(meshed) * 1000,
                         Date().timeIntervalSince(simplified) * 1000, before, surface.triangles.count))
        }
        return surface
    }

    /// Adds a surface's triangles to the meshes of their tags (a triangle takes the tag most of its
    /// corners have).
    func append(_ surface: HumanSurface, scale: Float, to byTag: inout [UInt8: MeshGeometry]) {
        guard !surface.positions.isEmpty else { return }
        // Smooth the weights a little over the mesh.
        var weights = surface.weights
        var neighbors = [[Int]](repeating: [], count: surface.positions.count)
        for t in surface.triangles {
            for n in 0..<3 {
                let a = Int(t[n]), b = Int(t[(n + 1) % 3])
                neighbors[a].append(b)
                neighbors[b].append(a)
            }
        }
        for _ in 0..<3 {
            var next = weights
            for v in weights.indices where !neighbors[v].isEmpty {
                var sum = [Float](repeating: 0, count: weights[v].count)
                for n in neighbors[v] { for k in sum.indices { sum[k] += weights[n][k] } }
                let inv = 1 / Float(neighbors[v].count)
                for k in sum.indices { next[v][k] = weights[v][k] * 0.5 + sum[k] * inv * 0.5 }
            }
            weights = next
        }
        var triangleTags = [UInt8](repeating: 0, count: surface.triangles.count)
        for (i, t) in surface.triangles.enumerated() {
            let a = surface.tags[Int(t.x)], b = surface.tags[Int(t.y)], c = surface.tags[Int(t.z)]
            triangleTags[i] = b == c ? b : a
        }
        for tag in Set(triangleTags).sorted() {
            var mesh = byTag[tag] ?? MeshGeometry(vertices: [], indices: [], skin: [])
            byTag[tag] = nil
            var map = [Int32](repeating: -1, count: surface.positions.count)
            for (i, t) in surface.triangles.enumerated() where triangleTags[i] == tag {
            for n in 0..<3 {
                let v = Int(t[n])
                if map[v] < 0 {
                    map[v] = Int32(mesh.vertices.count)
                    let p = surface.positions[v], nrm = surface.normals[v]
                    var tangent = cross(Vec3(0, 1, 0), nrm)
                    if length(tangent) < 1e-3 { tangent = cross(Vec3(1, 0, 0), nrm) }
                    tangent = normalize(tangent)
                    let u = atan2f(p.x, p.z) / (2 * .pi) + 0.5
                    mesh.vertices.append(MeshVertex(position: p * scale, normal: nrm, uv: Vec2(u, p.y),
                                                    tangent: Vec4(tangent.x, tangent.y, tangent.z, surface.occlusion[v])))
                    mesh.skin?.append(Self.influence(weights[v]))
                }
                mesh.indices.append(UInt32(map[v]))
            }
            }
            byTag[tag] = mesh
        }
    }

    /// The four largest weights, normalized.
    static func influence(_ w: [Float]) -> SkinInfluence {
        let top = w.enumerated().filter { $0.element > 0.002 }.sorted { $0.element > $1.element }.prefix(4)
        let total = top.reduce(0) { $0 + $1.element }
        guard total > 0 else { return SkinInfluence(joint: 0) }
        var joints = SIMD4<UInt16>(0, 0, 0, 0), values = Vec4.zero
        for (k, entry) in top.enumerated() {
            joints[k] = UInt16(entry.offset)
            values[k] = entry.element / total
        }
        return SkinInfluence(joints: joints, weights: values)
    }

    // MARK: Torso

    func buildTorso(group g: Int32, chain c: Int32) {
        // Ribcage: an egg, broad at the top.
        ellipsoid(tp(0, 1.325, -0.008), tr(0.152, 0.125, 0.098), group: g, chain: c, k: 0)
        ellipsoid(tp(0, 1.2, 0.0), tr(0.137, 0.11, 0.094), group: g, chain: c, k: 0.04)
        // Back: lats and shoulder blades.
        ellipsoid(tp(0, 1.27, -0.03), tr(0.148, 0.14, 0.075), group: g, chain: c, k: 0.04)
        for s: Float in [1, -1] {
            ellipsoid(tp(s * 0.075, 1.33, -0.055), tr(0.05, 0.065, 0.04), group: g, chain: c, k: 0.03)
            // Pectorals.
            ellipsoid(tp(s * 0.066, 1.318, 0.05), tr(0.066, 0.046, 0.042), group: g, chain: c, k: 0.03,
                      x: Vec3(1, s * 0.18, 0))
            // Clavicles.
            cone(tp(s * 0.022, 1.447, 0.05), tp(s * 0.165, 1.468, 0.0), 0.0085 * W, 0.009 * W, group: g, chain: c, k: 0.014)
            // Trapezius from the neck to the shoulder.
            cone(tp(s * 0.04, 1.505, -0.035), tp(s * 0.165, 1.45, -0.018), 0.022 * W, 0.02 * W, group: g, chain: c, k: 0.03)
            // The top of the shoulder (acromion).
            cone(tp(s * 0.12, 1.448, -0.006), tp(s * 0.19, 1.436, -0.002), 0.026 * W, 0.032 * W, group: g, chain: c, k: 0.03)
            // Glutes and the outer hip.
            ellipsoid(tp(s * 0.066, 0.895, -0.056), tr(0.073, 0.082, 0.064), group: g, chain: c, k: 0.03)
            ellipsoid(tp(s * 0.128, 0.885, -0.004), tr(0.05, 0.07, 0.068), group: g, chain: c, k: 0.035)
        }
        // Abdomen, waist and pelvis.
        ellipsoid(tp(0, 1.09, 0.01), tr(0.13, 0.1, 0.092), group: g, chain: c, k: 0.05)
        ellipsoid(tp(0, 0.95, -0.006), tr(0.158, 0.1, 0.1), group: g, chain: c, k: 0.05)
        ellipsoid(tp(0, 1.03, 0.04), tr(0.11, 0.07, 0.06), group: g, chain: c, k: 0.04)
    }

    func buildNeck(group g: Int32, chain c: Int32) {
        let neck = bone[b("neck")], head = bone[b("head")]
        cone(Vec3(0, neck.y - 0.02, -0.012), Vec3(0, head.y + 0.045 * H, -0.01 * H), 0.061 * W, 0.053 * W, group: g, chain: c, k: 0,
             sx: 1.0, sz: 0.94)
        for s: Float in [1, -1] {
            // Sternocleidomastoid: behind the ear to the top of the sternum.
            cone(hp(s * 0.056, 0.085, -0.028), Vec3(s * 0.016 * W, neck.y + 0.004, 0.05 * W), 0.012 * W, 0.0105 * W, group: g, chain: c, k: 0.02)
        }
        // Adam's apple.
        ellipsoid(Vec3(0, neck.y + (head.y - neck.y) * 0.55, 0.05 * W), Vec3(0.009, 0.012, 0.007) * W, group: g, chain: c, k: 0.012)
    }

    // MARK: Head

    func buildHead(group g: Int32, chain c: Int32) {
        func E(_ x: Float, _ y: Float, _ z: Float, _ rx: Float, _ ry: Float, _ rz: Float, k: Float, op: HumanPrim.Op = .add,
               tag: UInt8 = 255, ax: Vec3 = Vec3(1, 0, 0), ay: Vec3 = Vec3(0, 1, 0), mirror: Bool = false) {
            for s: Float in mirror ? [1, -1] : [1] {
                ellipsoid(hp(s * x, y, z), Vec3(rx, ry, rz) * H, group: g, chain: c, k: k * H, op: op, tag: tag,
                          x: Vec3(ax.x, s * ax.y, s * ax.z), y: Vec3(s * ay.x, ay.y, ay.z))
            }
        }
        func C(_ a: Vec3, _ b: Vec3, _ r1: Float, _ r2: Float, k: Float, op: HumanPrim.Op = .add, tag: UInt8 = 255, mirror: Bool = false) {
            for s: Float in mirror ? [1, -1] : [1] {
                cone(hp(s * a.x, a.y, a.z), hp(s * b.x, b.y, b.z), r1 * H, r2 * H, group: g, chain: c, k: k * H, op: op, tag: tag)
            }
        }
        // Cranium (the Loomis ball) and the back of the skull.
        E(0, 0.148, -0.018, 0.075, 0.096, 0.097, k: 0)
        E(0, 0.158, -0.045, 0.073, 0.08, 0.072, k: 0.02)
        // Forehead and brow ridge.
        E(0, 0.168, 0.03, 0.062, 0.06, 0.055, k: 0.02)
        E(0.03, 0.142, 0.077, 0.027, 0.0105, 0.016, k: 0.012, ax: Vec3(1, -0.16, -0.2), mirror: true)
        E(0, 0.139, 0.084, 0.015, 0.012, 0.01, k: 0.01)
        // Temples flatten into the cheekbones.
        E(0.056, 0.13, 0.02, 0.014, 0.03, 0.04, k: 0.025, mirror: true)
        // Mid-face (maxilla), cheekbones and their arches, cheeks.
        E(0, 0.086, 0.046, 0.054, 0.052, 0.048, k: 0.02)
        E(0.051, 0.106, 0.052, 0.017, 0.013, 0.024, k: 0.015, ax: Vec3(1, 0, -0.55), mirror: true)
        C(Vec3(0.056, 0.104, 0.04), Vec3(0.066, 0.098, 0.0), 0.0085, 0.0075, k: 0.015, mirror: true)
        E(0.039, 0.077, 0.055, 0.026, 0.032, 0.031, k: 0.02, mirror: true)
        E(0.043, 0.056, 0.036, 0.017, 0.026, 0.026, k: 0.02, mirror: true)
        // Dental arch (the muzzle the lips wrap around), jaw and chin.
        E(0, 0.052, 0.067, 0.033, 0.03, 0.031, k: 0.015)
        E(0, 0.042, 0.035, 0.044, 0.04, 0.048, k: 0.02)
        C(Vec3(0.016, 0.012, 0.078), Vec3(0.051, 0.03, -0.004), 0.012, 0.0115, k: 0.015, mirror: true)
        C(Vec3(0.051, 0.03, -0.004), Vec3(0.06, 0.088, -0.012), 0.0115, 0.011, k: 0.012, mirror: true)
        E(0, 0.016, 0.085, 0.021, 0.0165, 0.0152, k: 0.012)
        // Eye sockets carved under the brow, then the eyeball mounds the lids lie on.
        let eye = Vec3(0.032, 0.124, 0.071)
        E(0.033, 0.128, 0.085, 0.018, 0.0115, 0.0145, k: 0.008, op: .subtract, mirror: true)
        for s: Float in [1, -1] {
            sphere(hp(s * eye.x, eye.y, eye.z), 0.0143 * H, group: g, chain: c, k: 0.004 * H)
        }
        // Soft lower lids.
        E(0.033, 0.1135, 0.0765, 0.011, 0.0035, 0.006, k: 0.005, mirror: true)
        // Nose: bridge, tip, wings, columella, nostrils.
        C(Vec3(0, 0.129, 0.087), Vec3(0, 0.093, 0.112), 0.0065, 0.0092, k: 0.011)
        E(0, 0.0865, 0.111, 0.0096, 0.0092, 0.009, k: 0.004)
        E(0.0135, 0.0775, 0.1, 0.0078, 0.0074, 0.0085, k: 0.004, mirror: true)
        E(0, 0.0805, 0.097, 0.016, 0.0095, 0.01, k: 0.006)
        C(Vec3(0, 0.08, 0.1095), Vec3(0, 0.0725, 0.1005), 0.0034, 0.0034, k: 0.003)
        E(0.0074, 0.0745, 0.1042, 0.0036, 0.0021, 0.0052, k: 0.0018, op: .subtract, ax: Vec3(1, 0, 0.3), ay: Vec3(0, 1, -0.35), mirror: true)
        // Lips: upper with a cupid's bow, lower, the mouth line and its corners.
        E(0, 0.0552, 0.0935, 0.021, 0.0056, 0.0075, k: 0.004, tag: HumanTag.lips)
        E(0.0045, 0.0578, 0.0962, 0.0058, 0.0028, 0.0036, k: 0.003, tag: HumanTag.lips, mirror: true)
        E(0, 0.0425, 0.0925, 0.0185, 0.0062, 0.0078, k: 0.004, tag: HumanTag.lips)
        E(0, 0.0487, 0.0995, 0.024, 0.00095, 0.0135, k: 0.0014, op: .subtract)
        E(0.0222, 0.0488, 0.0872, 0.0022, 0.0018, 0.0022, k: 0.003, op: .subtract, mirror: true)
        // Philtrum groove, the crease under the lower lip.
        C(Vec3(0, 0.0705, 0.1015), Vec3(0, 0.0612, 0.1035), 0.0021, 0.0024, k: 0.003, op: .subtract)
        E(0, 0.0292, 0.0995, 0.016, 0.003, 0.0055, k: 0.006, op: .subtract)
        // Ears: pinna, helix rim, lobe, tragus; the concha and canal carved.
        for s: Float in [1, -1] {
            let center = hp(s * 0.073, 0.106, -0.02)
            let n = normalize(Vec3(s * 0.94, 0, 0.3))
            let upAxis = normalize(Vec3(0, 0.97, -0.25))
            let fwd = normalize(cross(upAxis, n)) * -s  // toward the face
            func at(_ f: Float, _ u: Float, _ o: Float) -> Vec3 { center + (fwd * f + upAxis * u + n * o) * H }
            ellipsoid(at(0, 0, 0.004), Vec3(0.017, 0.03, 0.0045) * H, group: g, chain: c, k: 0.003 * H, x: fwd, y: upAxis)
            var rim = HumanPrim(kind: .torus, center: at(-0.0005, 0.001, 0.0068))
            rim.setAxes(x: fwd, y: n, z: upAxis)
            rim.a = 0.0152 * H; rim.c = 0.0278 * H; rim.b = 0.0027 * H
            rim.group = g; rim.chain = c; rim.k = 0.002 * H
            add(rim)
            ellipsoid(at(0.002, -0.024, 0.0025), Vec3(0.0085, 0.0092, 0.0045) * H, group: g, chain: c, k: 0.004 * H, x: fwd, y: upAxis)
            ellipsoid(at(0.0125, -0.006, 0.0058), Vec3(0.0042, 0.005, 0.003) * H, group: g, chain: c, k: 0.002 * H, x: fwd, y: upAxis)
            ellipsoid(at(0.011, 0.002, -0.002), Vec3(0.006, 0.02, 0.006) * H, group: g, chain: c, k: 0.006 * H, x: fwd, y: upAxis)
            ellipsoid(at(0.004, -0.005, 0.0088), Vec3(0.0085, 0.0105, 0.0045) * H, group: g, chain: c, k: 0.003 * H, op: .subtract,
                      x: fwd, y: upAxis)
            ellipsoid(at(-0.002, 0.012, 0.0095), Vec3(0.0085, 0.009, 0.003) * H, group: g, chain: c, k: 0.002 * H, op: .subtract,
                      x: fwd, y: upAxis)
            sphere(at(0.009, -0.006, 0.0035), 0.0028 * H, group: g, chain: c, k: 0.002 * H, op: .subtract)
        }
        // The eye openings, last: almonds through the lids down to the eyeball.
        for s: Float in [1, -1] {
            var opening = HumanPrim(kind: .almond, center: hp(s * eye.x, eye.y, eye.z))
            opening.setAxes(x: Vec3(s, 0, 0), y: Vec3(0, 1, 0), z: Vec3(0, 0, 1))
            opening.a = 0.0098 * H; opening.b = 0.0168 * H
            opening.c = -1.02; opening.d = 1.18
            opening.e = 0.42; opening.f = 0.5
            opening.group = g; opening.chain = -1; opening.k = 0.0007 * H; opening.op = .subtract
            add(opening)
        }
    }

    // MARK: Arms and hands

    /// The arm's group and its hand's finger groups.
    func buildArm(side: String, s: Float, torsoChain: Int32) -> (Int32, [Int32]) {
        let chest = b("chest"), upper = b("upperArm.\(side)"), lower = b("lowerArm.\(side)"), hand = b("hand.\(side)")
        let shoulder = bone[upper], elbow = bone[lower], wrist = bone[hand]
        let armDir = normalize(elbow - shoulder), foreDir = normalize(wrist - elbow)
        let z = Vec3(0, 0, 1)
        let outward = normalize(cross(z, foreDir)) * s  // lateral, perpendicular to the forearm
        let armChain = chain(HumanChain(bones: [chest, upper, lower, hand], joints: [
            (shoulder + Vec3(-s * 0.01, -0.01, 0), normalize(Vec3(s * 1, -1.1, 0)), 0.055 * W),
            (elbow, normalize(armDir + foreDir), 0.045 * W),
            (wrist - foreDir * 0.005, foreDir, 0.028 * W),
        ]))
        let g = group(HumanGroup(center: shoulder + Vec3(-s * 0.01, 0.02, 0), radius: 0.06 * W, fade: 0.05 * W, kNear: 0.035 * W, kFar: 0.003))
        let upperLen = length(elbow - shoulder)
        func onUpper(_ t: Float, out o: Float = 0, front f: Float = 0) -> Vec3 {
            shoulder + armDir * (upperLen * t) + normalize(cross(z, armDir)) * s * o + z * f
        }
        let armSide = normalize(cross(z, armDir)) * s
        // Deltoid, upper arm, biceps, triceps.
        ellipsoid(shoulder + Vec3(-s * 0.012, -0.012, 0.0) * W, Vec3(0.047, 0.075, 0.054) * W, group: g, chain: armChain, k: 0.03 * W,
                  x: armSide, y: armDir)
        cone(onUpper(-0.02), onUpper(1.0), 0.046 * W, 0.036 * W, group: g, chain: armChain, k: 0.02 * W, side: armSide, sx: 0.95, sz: 1.0)
        ellipsoid(onUpper(0.48, front: 0.016 * W), Vec3(0.032, 0.07, 0.03) * W, group: g, chain: armChain, k: 0.02 * W, x: armSide, y: armDir)
        ellipsoid(onUpper(0.42, out: 0.004 * W, front: -0.017 * W), Vec3(0.034, 0.075, 0.032) * W, group: g, chain: armChain, k: 0.02 * W,
                  x: armSide, y: armDir)
        // Elbow (olecranon), forearm with its muscle belly, wrist.
        ellipsoid(elbow + Vec3(0, 0.004, -0.012 * W), Vec3(0.03, 0.03, 0.028) * W, group: g, chain: armChain, k: 0.018 * W)
        let foreLen = length(wrist - elbow)
        cone(elbow - foreDir * 0.01, wrist, 0.04 * W, 0.0255 * W, group: g, chain: armChain, k: 0.02 * W, side: outward, sx: 0.8, sz: 1.12)
        ellipsoid(elbow + foreDir * (0.27 * foreLen) + outward * 0.004 * W + z * 0.008 * W, Vec3(0.034, 0.075 * A, 0.037) * W,
                  group: g, chain: armChain, k: 0.03 * W, x: outward, y: foreDir)
        ellipsoid(wrist - foreDir * 0.006, Vec3(0.019, 0.02, 0.0275) * W, group: g, chain: armChain, k: 0.012 * W, x: outward, y: foreDir)

        // The hand: palm toward the thigh, thumb forward, fingers relaxed and slightly curled.
        let hs = (A * W).squareRoot()
        let d = foreDir, v = outward  // along the hand, back of the hand
        let palmGroup = group(HumanGroup(center: wrist, radius: 0.03, fade: 0.03, kNear: 0.02 * hs, kFar: 0.012 * hs))
        let handChain = armChain
        func hpnt(_ u: Float, _ vv: Float, _ w: Float) -> Vec3 { wrist + (d * u + v * vv + z * w) * hs }
        ellipsoid(hpnt(0.008, 0.0, 0.0), Vec3(0.019, 0.02, 0.028) * hs, group: palmGroup, chain: handChain, k: 0.01 * hs, x: v, y: d)
        ellipsoid(hpnt(0.052, 0.001, 0.0), Vec3(0.0145, 0.05, 0.04) * hs, group: palmGroup, chain: handChain, k: 0.012 * hs, x: v, y: d)
        ellipsoid(hpnt(0.04, -0.008, 0.025), Vec3(0.013, 0.028, 0.017) * hs, group: palmGroup, chain: handChain, k: 0.012 * hs, x: v, y: d)
        ellipsoid(hpnt(0.055, -0.006, -0.027), Vec3(0.011, 0.038, 0.013) * hs, group: palmGroup, chain: handChain, k: 0.012 * hs, x: v, y: d)
        var groups = [palmGroup]
        // Fingers: index, middle, ring, little.
        let knuckleW: [Float] = [0.026, 0.008, -0.01, -0.026]
        let knuckleU: [Float] = [0.093, 0.097, 0.094, 0.086]
        let fan: [Float] = [0.05, 0.0, -0.05, -0.12]
        let lengths: [[Float]] = [[0.041, 0.024, 0.021], [0.046, 0.028, 0.023], [0.043, 0.027, 0.022], [0.034, 0.02, 0.019]]
        let radii: [Float] = [0.0086, 0.009, 0.0084, 0.0074]
        let curl: [Float] = [0.2, 0.42, 0.32]
        for f in 0..<4 {
            let knuckle = hpnt(knuckleU[f], 0.002, knuckleW[f])
            let fg = group(HumanGroup(center: knuckle, radius: 0.007 * hs, fade: 0.01 * hs, kNear: 0.007 * hs, kFar: 0.0005))
            groups.append(fg)
            sphere(knuckle + v * 0.002 * hs, radii[f] * 1.12 * hs, group: palmGroup, chain: handChain, k: 0.006 * hs)
            var dir = normalize(d * cosf(fan[f]) + z * sinf(fan[f]))
            var p = knuckle
            var r = radii[f] * hs
            var angle: Float = 0
            for (n, segment) in lengths[f].enumerated() {
                angle += curl[n] * (f == 3 ? 1.15 : 1)
                // Curl toward the palm (-v).
                let along = normalize(dir * cosf(angle) - v * sinf(angle))
                let next = p + along * segment * hs
                let r2 = r * (n == 2 ? 0.86 : 0.9)
                cone(p, next, r, r2, group: fg, chain: handChain, k: 0.0025 * hs, side: v, sx: 1.0, sz: 0.95)
                if n == 2 {
                    // The nail on the back of the last segment.
                    let back = normalize(v * cosf(angle) + dir * sinf(angle))
                    ellipsoid(p + along * segment * 0.62 * hs + back * r2 * 0.78, Vec3(r2 * 0.78, segment * 0.36 * hs, r2 * 0.3),
                              group: fg, chain: handChain, k: 0.0012 * hs, tag: HumanTag.nails, x: z, y: along)
                }
                p = next
                r = r2
            }
            _ = dir
            dir = d
        }
        // Thumb: lying along the index finger, its pad toward it.
        let tg = group(HumanGroup(center: hpnt(0.03, -0.006, 0.026), radius: 0.018 * hs, fade: 0.014 * hs, kNear: 0.012 * hs, kFar: 0.0005))
        groups.append(tg)
        let joints = [hpnt(0.018, -0.004, 0.02), hpnt(0.054, -0.013, 0.044), hpnt(0.082, -0.017, 0.053), hpnt(0.104, -0.02, 0.056)]
        let thumbR: [Float] = [0.0125, 0.0108, 0.0098, 0.0084]
        for n in 0..<3 {
            cone(joints[n], joints[n + 1], thumbR[n] * hs, thumbR[n + 1] * hs, group: tg, chain: handChain, k: 0.003 * hs, side: v)
        }
        let thumbAlong = normalize(joints[3] - joints[2])
        let thumbBack = normalize(normalize(v * 0.35 + z * 0.94) - thumbAlong * dot(normalize(v * 0.35 + z * 0.94), thumbAlong))
        ellipsoid(joints[2] + (joints[3] - joints[2]) * 0.6 + thumbBack * thumbR[3] * 0.85 * hs,
                  Vec3(thumbR[3] * 0.82 * hs, 0.0085 * hs, thumbR[3] * 0.3 * hs), group: tg, chain: handChain, k: 0.0012 * hs,
                  tag: HumanTag.nails, x: normalize(cross(thumbAlong, thumbBack)), y: thumbAlong)
        _ = upper; _ = lower; _ = torsoChain
        return (g, groups)
    }

    // MARK: Legs and shoes

    func buildLeg(side: String, s: Float) -> (Int32, Int32) {
        let hips = b("hips"), upper = b("upperLeg.\(side)"), lower = b("lowerLeg.\(side)"), footBone = b("foot.\(side)")
        let hip = bone[upper], knee = bone[lower], ankle = bone[footBone]
        let down = Vec3(0, -1, 0)
        let legChain = chain(HumanChain(bones: [hips, upper, lower, footBone], joints: [
            (hip + Vec3(0, 0.01, 0), down, 0.06), (knee, down, 0.05), (ankle + Vec3(0, 0.01, 0), down, 0.03),
        ]))
        let g = group(HumanGroup(center: hip + Vec3(0, 0.02, -0.01), radius: 0.09 * W, fade: 0.04, kNear: 0.04 * W, kFar: 0.004))
        let thighLen = length(knee - hip)
        func onThigh(_ t: Float) -> Vec3 { hip + (knee - hip) * t }
        cone(hip + Vec3(s * 0.006, 0.03, 0), knee, 0.078 * W, 0.052 * W, group: g, chain: legChain, k: 0, sx: 0.9, sz: 1.0)
        ellipsoid(onThigh(0.45) + Vec3(s * 0.006, 0, 0.022) * W, Vec3(0.064, 0.16 * thighLen / 0.42, 0.058) * W,
                  group: g, chain: legChain, k: 0.04 * W)
        ellipsoid(knee + Vec3(0, 0.005, 0.012 * W), Vec3(0.046, 0.05, 0.048) * W, group: g, chain: legChain, k: 0.02 * W)
        let shinLen = length(ankle - knee)
        cone(knee, ankle + Vec3(0, 0.015, 0), 0.05 * W, 0.03 * W, group: g, chain: legChain, k: 0.02 * W)
        ellipsoid(knee + (ankle - knee) * 0.3 + Vec3(s * 0.002, 0, -0.026) * W, Vec3(0.044, 0.085 * shinLen / 0.4, 0.042) * W,
                  group: g, chain: legChain, k: 0.03 * W)
        ellipsoid(ankle + Vec3(0, 0.005, -0.005), Vec3(0.03, 0.026, 0.035) * W, group: g, chain: legChain, k: 0.015)

        // The shoe: heel counter, instep, toe box, collar and tongue (its own group: a piece of its own).
        let fs = L.squareRoot()
        let shoe = group(HumanGroup(kNear: 0))
        let x = ankle.x, z0 = ankle.z
        func f(_ dx: Float, _ y: Float, _ dz: Float) -> Vec3 { Vec3(x + s * dx * W, y, z0 + dz * fs) }
        ellipsoid(f(0, 0.046, -0.034), Vec3(0.037 * W, 0.046, 0.046 * fs), group: shoe, chain: legChain, k: 0)
        ellipsoid(f(0.002, 0.047, 0.05), Vec3(0.043 * W, 0.045, 0.088 * fs), group: shoe, chain: legChain, k: 0.03)
        ellipsoid(f(0.006, 0.031, 0.148), Vec3(0.044 * W, 0.031, 0.062 * fs), group: shoe, chain: legChain, k: 0.03)
        ellipsoid(f(0, 0.086, -0.012), Vec3(0.04 * W, 0.03, 0.046 * fs), group: shoe, chain: legChain, k: 0.02)
        cone(f(0, 0.108, 0.018), f(0.002, 0.066, 0.09), 0.021 * W, 0.02 * W, group: shoe, chain: legChain, k: 0.02)
        return (g, shoe)
    }

    // MARK: Clothing

    /// The T-shirt: the torso, neck and upper arms grown by an ease (looser low on the body), with
    /// a soft drape over the belly, gentle folds, a hem at the hips, sleeves to mid-arm, a crew
    /// collar with a ribbed band, and hollow just inside each opening.
    func shirtShape(armGroups: [Int32]) -> (Float, Float, Float, Float) -> Float {
        let hemY = ty(0.925)
        let neck = bone[b("neck")]
        var sleeves: [(hem: Vec3, axis: Vec3)] = []
        for side in ["L", "R"] {
            let shoulder = bone[b("upperArm.\(side)")], elbow = bone[b("lowerArm.\(side)")]
            sleeves.append((shoulder + (elbow - shoulder) * 0.5, normalize(elbow - shoulder)))
        }
        let collarCenter = Vec3(0, neck.y + 0.035, 0.0)
        let collarTilt = normalize(Vec3(0, 1, 0.33))  // the opening dips in front
        let collarR = Vec2(0.079 * W, 0.073 * W)
        let drapeCenter = tp(0, 1.1, 0.004), drapeRadii = tr(0.142, 0.2, 0.1)
        let W = self.W
        return { x, y, z, body in
            let p = Vec3(x, y, z)
            var ease: Float = 0.009 + 0.008 * HumanField.smoothstep(1.2, 0.98, y) + 0.003 * HumanField.smoothstep(0, -0.08, z)
            // Folds: soft horizontal ripples low on the shirt, gentle wrinkles elsewhere (only outward).
            ease += 0.0024 * (0.5 + 0.5 * sinf(y * 75 + 2.5 * sinf(x * 23 + z * 9))) * HumanField.smoothstep(1.16, 1.0, y)
            ease += 0.0016 * (0.5 + 0.5 * sinf(x * 41 + y * 13 + 0.7) * sinf(z * 37 + 1.3))
            var d = body - ease
            // Drape: the cloth falls from the chest over the belly instead of following it in.
            let q = (p - drapeCenter) / drapeRadii
            let k0 = length(q), k1 = length(q / drapeRadii)
            let drape = k1 > 1e-6 ? k0 * (k0 - 1) / k1 : -0.1
            d = humanSmin(d, drape - ease * 0.6, 0.04 * W)
            // Hem at the hips (a little lower at the back).
            d = max(d, hemY - 0.01 * HumanField.smoothstep(0, -0.1, z) - y)
            // Sleeves end at mid-arm.
            for sleeve in sleeves {
                let along = dot(p - sleeve.hem, sleeve.axis)
                let radial = length((p - sleeve.hem) - sleeve.axis * along)
                let cut = max(-along, radial - 0.085 * W)
                d = max(d, -cut)
            }
            // Crew neck: cut around the neck, a ribbed band at the edge.
            let rel = p - collarCenter
            let h = dot(rel, collarTilt)
            let flat = rel - collarTilt * h
            let rx = flat.x / collarR.x, rz = flat.z / collarR.y
            let ring = ((rx * rx + rz * rz).squareRoot() - 1) * min(collarR.x, collarR.y)
            d = max(d, -max(ring, -h))
            let band = ((ring + 0.002) * (ring + 0.002) + (h + 0.005) * (h + 0.005)).squareRoot() - 0.0068
            d = humanSmin(d, max(band, -(body - 0.004)), 0.003)
            // Hollow near the openings (so they read as cloth, not a solid).
            let fromHem = abs(y - hemY)
            var fromOpening = min(fromHem, (ring * ring + h * h).squareRoot())
            for sleeve in sleeves { fromOpening = min(fromOpening, abs(dot(p - sleeve.hem, sleeve.axis))) }
            d = max(d, -(body - 0.0025) - 4 * max(0, fromOpening - 0.03))
            return d
        }
    }

    /// The trousers: hips and legs grown by an ease, falling straight from the knee, a waist under the
    /// shirt, hems resting on the shoes, soft folds at the knees and ankles.
    func trouserShape(legGroups: [Int32]) -> (Float, Float, Float, Float) -> Float {
        let waistY = ty(1.05)
        var legs: [(top: Vec3, bottom: Vec3)] = []
        for side in ["L", "R"] {
            let knee = bone[b("lowerLeg.\(side)")], ankle = bone[b("foot.\(side)")]
            legs.append((knee + Vec3(0, 0.12, 0.006), Vec3(ankle.x, 0.06, ankle.z + 0.008)))
        }
        let hemY: Float = 0.072
        let W = self.W
        return { x, y, z, body in
            let p = Vec3(x, y, z)
            var ease: Float = 0.009 + 0.004 * HumanField.smoothstep(0.75, 0.5, y)
            ease += 0.0025 * sinf(y * 60 + 3 * sinf(x * 19 + z * 7)) * (HumanField.smoothstep(0.62, 0.48, y) * HumanField.smoothstep(0.32, 0.45, y)
                                                                         + HumanField.smoothstep(0.22, 0.1, y))
            var d = body - ease
            // Straight legs below the knee.
            for leg in legs {
                let axis = leg.bottom - leg.top
                let t = max(0, min(1, dot(p - leg.top, axis) / dot(axis, axis)))
                let r = (0.066 + (0.064 - 0.066) * t) * W
                d = humanSmin(d, length(p - (leg.top + axis * t)) - r, 0.035 * W)
            }
            d = max(d, y - waistY)
            // Hems resting on the shoes, a little lower at the heel.
            let hem = hemY + 0.012 * HumanField.smoothstep(-0.05, 0.08, z)
            d = max(d, hem - y)
            // Hollow just inside the hems.
            d = max(d, -(body - 0.004) - 4 * max(0, y - hem - 0.05))
            return d
        }
    }

    /// The shoe: its upper flattened on the ground, on a sole a little wider than the upper.
    func shoeShape(group shoeGroup: Int32, foot: Vec3) -> (Float, Float, Float, Float) -> Float {
        let field = self.field
        let list = field.prims.indices.filter { field.prims[$0].group == shoeGroup }.map { Int32($0) }
        return { x, y, z, body in
            var d = max(body, 0.012 - y)
            // The sole: the upper's footprint at 2 cm, extruded 0...2.2 cm, 3 mm wider.
            let footprint = field.prims.withUnsafeBufferPointer { prims in
                field.groups.withUnsafeBufferPointer { groups in
                    list.withUnsafeBufferPointer { l in field.evaluate(x, 0.024, z, l, prims.baseAddress!, groups.baseAddress!) }
                }
            }
            let sole = max(footprint - 0.003, max(y - 0.022, -y))
            d = humanSmin(d, sole, 0.002)
            return d
        }
    }

    // MARK: Eyes

    /// Sclera, iris, pupil and cornea for both eyes, on the head bone.
    func eyeParts(scale: Float) -> [CharacterBodyPart] {
        let head = b("head")
        let r: Float = 0.012
        let limbus: Float = 0.52  // the iris's edge, radians from the eye's axis
        let pupil: Float = 0.0021
        var sclera = MeshGeometry(vertices: [], indices: [], skin: []), iris = sclera, pupilMesh = sclera, cornea = sclera
        for s: Float in [1, -1] {
            // Looking straight ahead, a touch outward.
            let center = hp(s * 0.032, 0.124, 0.071)
            let forward = normalize(Vec3(s * 0.03, 0, 1))
            let right = normalize(cross(Vec3(0, 1, 0), forward)), upAxis = cross(forward, right)
            func place(_ q: Vec3) -> Vec3 { (center + (right * q.x + upAxis * q.y + forward * q.z) * H) * scale }
            func turn(_ q: Vec3) -> Vec3 { normalize(right * q.x + upAxis * q.y + forward * q.z) }
            // Sclera: a sphere open where the cornea sits.
            Self.cap(into: &sclera, from: limbus, to: .pi, radius: r, rings: 22, segments: 40, place: place, turn: turn, bone: head)
            // Iris: a shallow cone from the limbus in toward the pupil, behind the cornea.
            let irisZ = r * cosf(limbus) - 0.0005
            let irisR = r * sinf(limbus)
            Self.disc(into: &iris, inner: pupil, outer: irisR, z: { t in irisZ + 0.0004 * (1 - t) }, normalTilt: 0.25,
                      segments: 40, rings: 6, place: place, turn: turn, bone: head)
            Self.disc(into: &pupilMesh, inner: 0, outer: pupil, z: { _ in irisZ + 0.00041 }, normalTilt: 0, segments: 24, rings: 1,
                      place: place, turn: turn, bone: head)
            // Cornea: a clear dome (radius 7.8 mm) meeting the sclera at the limbus.
            let zl = r * cosf(limbus + 0.02), al = r * sinf(limbus + 0.02)
            let rc: Float = 0.0078
            let zc = zl - (rc * rc - al * al).squareRoot()
            let open = asinf(al / rc)
            let base = UInt32(cornea.vertices.count)
            let rings = 10, segments = 40
            for i in 0...rings {
                let a = open * Float(i) / Float(rings)
                for j in 0...segments {
                    let phi = Float(j) / Float(segments) * 2 * .pi
                    let n = Vec3(sinf(a) * cosf(phi), sinf(a) * sinf(phi), cosf(a))
                    let q = Vec3(0, 0, zc) + n * rc
                    let normal = turn(n)
                    cornea.vertices.append(MeshVertex(position: place(q), normal: normal, uv: Vec2(Float(j) / Float(segments), Float(i) / Float(rings)),
                                                      tangent: Self.tangent(normal)))
                    cornea.skin?.append(SkinInfluence(joint: UInt16(head)))
                }
            }
            for i in 0..<rings {
                for j in 0..<segments {
                    let a = base + UInt32(i * (segments + 1) + j), bb = a + 1, c = a + UInt32(segments + 1), d = c + 1
                    cornea.indices += [a, bb, c, bb, d, c]
                }
            }
        }
        return [
            CharacterBodyPart(name: "eye.sclera", region: .eyes, geometry: sclera,
                              look: CharacterPartLook(color: Vec3(0.9, 0.87, 0.84), roughness: 0.3)),
            CharacterBodyPart(name: "eye.iris", region: .eyes, geometry: iris, look: CharacterPartLook(roughness: 0.4)),
            CharacterBodyPart(name: "eye.pupil", region: .eyes, geometry: pupilMesh,
                              look: CharacterPartLook(color: Vec3(0.012, 0.01, 0.01), roughness: 0.3)),
            CharacterBodyPart(name: "eye.cornea", region: .eyes, geometry: cornea,
                              look: CharacterPartLook(color: Vec3(1, 1, 1), roughness: 0.03, opacity: 0.08)),
        ]
    }

    static func tangent(_ n: Vec3) -> Vec4 {
        var t = cross(Vec3(0, 1, 0), n)
        if length(t) < 1e-3 { t = cross(Vec3(1, 0, 0), n) }
        t = normalize(t)
        return Vec4(t.x, t.y, t.z, 1)
    }

    /// A band of a sphere from polar angle `from` to `to` (around +z), facing out.
    static func cap(into mesh: inout MeshGeometry, from: Float, to: Float, radius: Float, rings: Int, segments: Int,
                    place: (Vec3) -> Vec3, turn: (Vec3) -> Vec3, bone: Int) {
        let base = UInt32(mesh.vertices.count)
        for i in 0...rings {
            let a = from + (to - from) * Float(i) / Float(rings)
            for j in 0...segments {
                let phi = Float(j) / Float(segments) * 2 * .pi
                let n = Vec3(sinf(a) * cosf(phi), sinf(a) * sinf(phi), cosf(a))
                let normal = turn(n)
                mesh.vertices.append(MeshVertex(position: place(n * radius), normal: normal,
                                                uv: Vec2(Float(j) / Float(segments), Float(i) / Float(rings)), tangent: tangent(normal)))
                mesh.skin?.append(SkinInfluence(joint: UInt16(bone)))
            }
        }
        for i in 0..<rings {
            for j in 0..<segments {
                let a = base + UInt32(i * (segments + 1) + j), b = a + 1, c = a + UInt32(segments + 1), d = c + 1
                mesh.indices += [a, b, c, b, d, c]
            }
        }
    }

    /// A flat ring facing +z from radius `inner` to `outer` at depth `z(t)` (t 0 inner, 1 outer),
    /// its normals tilted out by `normalTilt` toward the rim.
    static func disc(into mesh: inout MeshGeometry, inner: Float, outer: Float, z: (Float) -> Float, normalTilt: Float, segments: Int, rings: Int,
                     place: (Vec3) -> Vec3, turn: (Vec3) -> Vec3, bone: Int) {
        let base = UInt32(mesh.vertices.count)
        for i in 0...rings {
            let t = Float(i) / Float(rings)
            let r = inner + (outer - inner) * t
            for j in 0...segments {
                let phi = Float(j) / Float(segments) * 2 * .pi
                let radial = Vec3(cosf(phi), sinf(phi), 0)
                let normal = turn(normalize(Vec3(0, 0, 1) - radial * normalTilt * (t - 0.5)))
                mesh.vertices.append(MeshVertex(position: place(radial * r + Vec3(0, 0, z(t))), normal: normal,
                                                uv: Vec2(Float(j) / Float(segments), t), tangent: tangent(normal)))
                mesh.skin?.append(SkinInfluence(joint: UInt16(bone)))
            }
        }
        for i in 0..<rings {
            for j in 0..<segments {
                let a = base + UInt32(i * (segments + 1) + j), b = a + 1, c = a + UInt32(segments + 1), d = c + 1
                mesh.indices += [a, c, b, b, c, d]
            }
        }
    }

    // MARK: Scalp

    /// The head piece's skin above the hairline, 1.5 mm out, in the head bone's space.
    func scalpMesh(_ surface: HumanSurface, scale: Float) -> MeshGeometry {
        let headPos = bone[b("head")]
        // The hairline's height over the head bone by azimuth around the skull (degrees from the front).
        let line: [(Float, Float)] = [(0, 0.201), (25, 0.198), (45, 0.188), (58, 0.168), (66, 0.13), (72, 0.108), (78, 0.112),
                                      (84, 0.15), (95, 0.158), (106, 0.148), (114, 0.1), (124, 0.06), (145, 0.035), (180, 0.025)]
        func hairline(_ degrees: Float) -> Float {
            for i in 1..<line.count where degrees <= line[i].0 {
                let t = (degrees - line[i - 1].0) / (line[i].0 - line[i - 1].0)
                return line[i - 1].1 + (line[i].1 - line[i - 1].1) * t
            }
            return line.last!.1
        }
        let ears = [Vec3(0.074, 0.105, -0.02), Vec3(-0.074, 0.105, -0.02)]
        let hair = surface.positions.map { p -> Bool in
            let q = (p - headPos) / H
            let azimuth = abs(atan2f(q.x, q.z + 0.015)) * 180 / .pi
            guard q.y > hairline(azimuth) else { return false }
            return ears.allSatisfy { length(q - $0) > 0.036 }
        }
        var mesh = MeshGeometry(vertices: [], indices: [])
        var map = [Int32](repeating: -1, count: surface.positions.count)
        for t in surface.triangles where hair[Int(t.x)] && hair[Int(t.y)] && hair[Int(t.z)] {
            for n in 0..<3 {
                let v = Int(t[n])
                if map[v] < 0 {
                    map[v] = Int32(mesh.vertices.count)
                    let q = surface.positions[v] + surface.normals[v] * 0.0015 - headPos
                    let normal = surface.normals[v]
                    mesh.vertices.append(MeshVertex(position: q * scale, normal: normal,
                                                    uv: Vec2(atan2f(q.x, q.z) / (2 * .pi) + 0.5, q.y / (0.26 * H))))
                }
                mesh.indices.append(UInt32(map[v]))
            }
        }
        return mesh
    }
}
