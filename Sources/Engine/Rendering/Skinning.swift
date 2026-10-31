/// Skeletal skinning for `SceneRenderer`: the `Skin` component that binds a skinned mesh to
/// joint entities, the per-frame joint matrices (`SkinPose`) computed while gathering, and the
/// uniform block the skinning shaders read.
///
/// A skinned mesh (`MeshGeometry.skin` set) is drawn by the skinning variants of the mesh
/// shaders (`mesh_skinned.vert`, `mesh_shadow_skinned.vert`, …), which blend up to four joint
/// matrices per vertex. Each frame, `RenderPrep.gather` computes the entity's joint matrices
/// from the joints' `GlobalTransform`s (moved by an `Animator`, physics, or anything else) and
/// keeps last frame's for motion vectors. Skinned entities are drawn one per draw call (their
/// joint matrices differ), in every pass: screen, shadow and the selection outline mask.

/// Binds the `MeshRenderer` of its entity, whose mesh must be skinned, to a skeleton: joint `j`
/// of the mesh's `SkinInfluence`s follows `joints[j]`, a vertex moving from the bind pose by
/// `inverse(meshWorld) · jointWorld · inverseBindMatrices[j]`. Joints are ordinary entities
/// (the bones of an imported model, see `ImportedModel.instantiate`). A skinned mesh without a
/// `Skin` (or with stale joints) is drawn in its bind pose.
public struct Skin: Component, Codable, Equatable, Sendable {
    public static let componentName = "Skin"
    public static var fieldHints: [String: FieldHints] { ["inverseBindMatrices": FieldHints(readOnly: true)] }

    public var joints: [Entity]
    /// Mesh space to each joint's space in the bind pose (glTF `inverseBindMatrices`).
    public var inverseBindMatrices: [Mat4]

    public init(joints: [Entity], inverseBindMatrices: [Mat4]) {
        self.joints = joints
        self.inverseBindMatrices = inverseBindMatrices
    }
}

/// What the renderer keeps about a registered skinned mesh: how many joints it uses and the
/// bounds of the vertices each one moves (`MeshGeometry.jointBounds`), from which `RenderPrep`
/// bounds the posed mesh for culling.
public struct SkinnedMeshInfo: Sendable {
    public var jointCount: Int
    public var jointBounds: [Bounds?]

    public init(jointBounds: [Bounds?]) {
        self.jointBounds = jointBounds
        jointCount = jointBounds.count
    }
}

/// One skinned entity's joint matrices this frame (mesh space, bind pose to posed), and last
/// frame's for motion vectors (equal on the first frame it is drawn).
public struct SkinPose: Sendable {
    public var joints: [Mat4]
    public var previousJoints: [Mat4]

    /// Most joints a skinned mesh may use (the shaders' palette size, `MAX_JOINTS` in skinning.glsl).
    public static let maxJoints = 128

    /// The joint matrices of `skin` for a mesh drawn at `meshWorld` with `jointCount` joints,
    /// reading joint world matrices through `jointWorld` (nil for a missing joint, which then
    /// stays in the bind pose, as do joints past the skin's list).
    public static func joints(of skin: Skin?, meshWorld: Mat4, jointCount: Int, jointWorld: (Entity) -> Mat4?) -> [Mat4] {
        var result = Array(repeating: Mat4.identity, count: jointCount)
        guard let skin else { return result }
        let toMesh = meshWorld.inverse
        for j in 0..<min(jointCount, skin.joints.count) {
            guard let world = jointWorld(skin.joints[j]) else { continue }
            let inverseBind = j < skin.inverseBindMatrices.count ? skin.inverseBindMatrices[j] : .identity
            result[j] = toMesh * world * inverseBind
        }
        return result
    }

    /// Mesh-space bounds of the mesh posed by `joints`: the union of each joint's vertex bounds
    /// moved by its matrix (nil when no joint moves any vertex).
    public static func bounds(_ jointBounds: [Bounds?], joints: [Mat4]) -> Bounds? {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for (bounds, matrix) in zip(jointBounds, joints) {
            guard let bounds else { continue }
            let b = bounds.transformed(by: matrix)
            lo = pointwiseMin(lo, b.center - b.halfExtent)
            hi = pointwiseMax(hi, b.center + b.halfExtent)
        }
        guard lo.x <= hi.x else { return nil }
        return Bounds(center: (lo + hi) / 2, halfExtent: (hi - lo) / 2)
    }

    /// The skinning shaders' uniform block (buffer 2, see skinning.glsl): `material` (the
    /// fragment shader's `MaterialData`, read as a prefix of the block) padded to 128 bytes, then
    /// `maxJoints` current and `maxJoints` previous joint matrices as three rows each (they are
    /// affine). Always the full size, so the binding covers the block the shaders declare.
    static func uniformBlock<M: BitwiseCopyable>(material: M?, pose: SkinPose?, into block: inout [Vec4]) {
        let count = blockVec4s
        if block.count != count { block = Array(repeating: .zero, count: count) }
        block.withUnsafeMutableBufferPointer { out in
            for i in 0..<materialVec4s { out[i] = .zero }
            if let material {
                precondition(MemoryLayout<M>.size <= materialVec4s * MemoryLayout<Vec4>.stride)
                withUnsafeBytes(of: material) { bytes in
                    UnsafeMutableRawBufferPointer(out).copyMemory(from: bytes)
                }
            }
            func write(_ joints: [Mat4]?, at base: Int) {
                for j in 0..<maxJoints {
                    let m = joints.flatMap { j < $0.count ? $0[j] : nil } ?? .identity
                    out[base + j * 3] = Vec4(m.c0.x, m.c1.x, m.c2.x, m.c3.x)
                    out[base + j * 3 + 1] = Vec4(m.c0.y, m.c1.y, m.c2.y, m.c3.y)
                    out[base + j * 3 + 2] = Vec4(m.c0.z, m.c1.z, m.c2.z, m.c3.z)
                }
            }
            write(pose?.joints, at: materialVec4s)
            write(pose?.previousJoints, at: materialVec4s + maxJoints * 3)
        }
    }

    static let materialVec4s = 8
    static let blockVec4s = materialVec4s + maxJoints * 6
}

/// Each skinned entity's joint matrices from the previous frame, like `MotionHistory`: keyed by
/// entity slot and generation, and only valid if recorded in the immediately preceding frame.
public struct SkinHistory: Sendable {
    private var slots: [(generation: UInt32, frame: Int, joints: [Mat4])] = []

    public init() {}

    /// Returns `entity`'s joint matrices from frame `frame - 1` (or `current`) and records `current` for `frame`.
    public mutating func previousJoints(for entity: Entity, current: [Mat4], frame: Int) -> [Mat4] {
        let index = Int(entity.index)
        if index >= slots.count {
            slots.append(contentsOf: repeatElement((UInt32.max, Int.min, []), count: max(index + 1 - slots.count, slots.count)))
        }
        let slot = slots[index]
        let previous = slot.generation == entity.generation && slot.frame == frame - 1 && slot.joints.count == current.count
            ? slot.joints : current
        slots[index] = (entity.generation, frame, current)
        return previous
    }
}

extension World {
    /// Draws every skeleton bound by a `Skin`: a line from each joint to its parent when the
    /// parent is a joint of the same skin, and a small cross at every joint. On top of the scene
    /// by default.
    public func drawSkeletons(into debug: DebugDraw, color: Vec4 = Vec4(1, 0.85, 0.2, 1), jointSize: Float = 0.03,
                              style: DebugDraw.Style = DebugDraw.Style(width: 2, depth: .onTop)) {
        query(Skin.self) { _, skin in
            let joints = Set(skin.joints)
            for joint in skin.joints {
                guard let matrix = get(GlobalTransform.self, for: joint)?.matrix else { continue }
                let p = Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z)
                if let parent = parent(of: joint), joints.contains(parent), let pm = get(GlobalTransform.self, for: parent)?.matrix {
                    debug.line(Vec3(pm.c3.x, pm.c3.y, pm.c3.z), p, color: color, style: style)
                }
                for axis in [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)] {
                    debug.line(p - axis * jointSize, p + axis * jointSize, color: color, style: style)
                }
            }
        }
    }
}
