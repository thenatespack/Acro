#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics
import EngineAssets

// A character rig's body mesh, built from Mesh Builder shapes (here, not with `CharacterRig` in
// EngineAssets, because shape geometry is part of this module).

extension CharacterRig {
    /// Bounds of the body shapes in the rest pose.
    public var bounds: Bounds {
        let points = bodyMeshes(segments: 8, smooth: false).flatMap { $0.geometry.vertices.map(\.position) }
        return points.isEmpty ? Bounds(center: Vec3(0, 0.5, 0), halfExtent: Vec3(0.5, 0.5, 0.5)) : Bounds(enclosing: points)
    }

    /// The skinned body: one mesh per color region that has shapes (joints index `bones`), in
    /// `CharacterRegion` order. `segments` slices round shapes; `smooth` blends weights at joints.
    public func bodyMeshes(segments slices: Int = 12, smooth: Bool = true) -> [(region: CharacterRegion, geometry: MeshGeometry)] {
        var result: [(CharacterRegion, MeshGeometry)] = []
        for region in CharacterRegion.allCases {
            var mesh = MeshGeometry(vertices: [], indices: [], skin: [])
            for segment in segments where segment.region == region {
                append(segment, slices: min(max(slices, 6), 32), smooth: smooth, to: &mesh)
            }
            if !mesh.indices.isEmpty { result.append((region, mesh)) }
        }
        return result
    }

    private func append(_ s: CharacterSegment, slices: Int, smooth: Bool, to mesh: inout MeshGeometry) {
        let axis = s.to - s.from
        let span = max(length(axis), 1e-4)
        let dir = axis / span
        var part = MeshBuildPart(shape: s.shape, size: Vec3(s.radius.x * 2, span, s.radius.y * 2), segments: slices)
        part.segments = s.shape == .box ? 1 : slices
        guard let geometry = part.geometry() else { return }
        let rotation = Self.rotation(from: Vec3(0, 1, 0), to: dir)
        let center = (s.from + s.to) / 2
        let base = UInt32(mesh.vertices.count)
        for v in geometry.vertices {
            let p = center + rotation * v.position
            mesh.vertices.append(MeshVertex(position: p, normal: rotation * v.normal, uv: v.uv))
            // 0 at `from`, 1 at `to`.
            let t = min(max(v.position.y / span + 0.5, 0), 1)
            var weights: [(Int, Float)] = [(s.bone, 1)]
            if smooth, s.blend > 0 {
                if let start = s.startBone, t < s.blend {
                    let w = 0.5 * (1 - t / s.blend)
                    weights = [(s.bone, 1 - w), (start, w)]
                } else if let end = s.endBone, t > 1 - s.blend {
                    let w = 0.5 * (1 - (1 - t) / s.blend)
                    weights = [(s.bone, 1 - w), (end, w)]
                }
            }
            var joints = SIMD4<UInt16>(0, 0, 0, 0), values = Vec4.zero
            for (k, (bone, w)) in weights.prefix(4).enumerated() {
                joints[k] = UInt16(bone)
                values[k] = w
            }
            mesh.skin?.append(SkinInfluence(joints: joints, weights: values))
        }
        mesh.indices += geometry.indices.map { $0 + base }
    }
}
