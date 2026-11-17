import Foundation
import EngineCore
import EngineGraphics

/// Per-vertex factors on a mesh's material (`MeshGeometry.paint`): the optional second vertex
/// stream of `SceneRenderer` meshes (vertex buffer 2, attributes 14 and 15, the slots skinned
/// meshes use for their joints, so a painted mesh can't also be skinned). The lit shaders
/// multiply them in (mesh_paint.vert / mesh_paint(_mask).frag): albedo by `color.rgb`, opacity by
/// `color.a`, roughness by `surface.x`, metallic by `surface.y` and emission by `surface.z`
/// (`surface.w` is unused). Interpolated across each triangle like any vertex attribute.
///
/// Mesh builds paint sculpts whose children have different looks, so the looks blend across their
/// boundary (MeshBuildSculptBlend.swift), and vary their leaf cards' color (MeshBuildFoliage.swift).
public struct VertexPaint: Equatable, Sendable, BitwiseCopyable {
    public var color: Vec4
    public var surface: Vec4

    public init(color: Vec4 = Vec4(1, 1, 1, 1), surface: Vec4 = Vec4(1, 1, 1, 0)) {
        self.color = color
        self.surface = surface
    }

    /// No change: every factor 1.
    public static let none = VertexPaint()

    package static let layout = VertexLayout(
        stride: MemoryLayout<VertexPaint>.stride,
        attributes: [
            VertexAttribute(location: 14, format: .float4, offset: MemoryLayout<VertexPaint>.offset(of: \.color)!),
            VertexAttribute(location: 15, format: .float4, offset: MemoryLayout<VertexPaint>.offset(of: \.surface)!),
        ])
}

extension MeshGeometry {
    /// Appends `vertex` with the paint halfway between vertices `a` and `b` (when painted): for
    /// steps that split edges.
    package mutating func appendMidpoint(_ vertex: MeshVertex, between a: Int, _ b: Int) {
        vertices.append(vertex)
        if paint != nil {
            let pa = paint![a], pb = paint![b]
            paint!.append(VertexPaint(color: (pa.color + pb.color) * 0.5, surface: (pa.surface + pb.surface) * 0.5))
        }
    }

    /// Appends source vertex `i` of `source` (vertex and paint): for steps that rebuild a mesh.
    package mutating func append(vertex: MeshVertex, from source: MeshGeometry, _ i: Int) {
        vertices.append(vertex)
        if let sourcePaint = source.paint {
            if paint == nil { paint = [] }
            paint!.append(sourcePaint[i])
        }
    }
}
