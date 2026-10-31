import Foundation

/// Mirrors a sprite across its own vertical and/or horizontal axis (the pivot stays put).
public struct SpriteFlip: OptionSet, Codable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let horizontal = SpriteFlip(rawValue: 1)
    public static let vertical = SpriteFlip(rawValue: 2)
}

/// How a sprite is combined with what is already in the target. Sprites with different
/// blend modes never share a draw call.
public enum SpriteBlend: String, Codable, Sendable {
    /// Standard straight-alpha blending.
    case alpha
    /// Replaces the target (no blending, alpha is ignored): backgrounds and solid tiles.
    case opaque
}

/// One corner of a sprite quad as the sprite shader consumes it. `color` is linear RGBA with
/// straight alpha.
public struct SpriteVertex: Sendable, BitwiseCopyable {
    /// x, y, then depth (`z` follows `position` in memory: the shader reads them as a float3).
    public var position: Vec2
    public var z: Float
    public var uv: Vec2
    public var color: Vec4

    static let layout = VertexLayout(
        stride: MemoryLayout<SpriteVertex>.stride,
        attributes: [
            VertexAttribute(location: 0, format: .float3, offset: MemoryLayout<SpriteVertex>.offset(of: \.position)!),
            VertexAttribute(location: 1, format: .float2, offset: MemoryLayout<SpriteVertex>.offset(of: \.uv)!),
            VertexAttribute(location: 2, format: .float4, offset: MemoryLayout<SpriteVertex>.offset(of: \.color)!),
        ])
}

/// A run of consecutive sprites that one draw call renders.
public struct SpriteDraw {
    public var texture: GPUTexture
    public var sampler: GPUSampler?
    public var blend: SpriteBlend
    public var firstIndex: Int
    public var indexCount: Int
    public var spriteCount: Int { indexCount / 6 }
}

public struct SpriteBatchStats: Sendable, Equatable {
    public var sprites = 0
    public var drawCalls = 0
    public var vertices = 0
}

/// The sorted vertices and draws for one frame (`SpriteBatch.prepare()`).
public struct SpriteBatchData {
    public var vertices: [SpriteVertex] = []
    public var indices: [UInt32] = []
    public var draws: [SpriteDraw] = []
}

/// Collects sprites (textured quads) during a frame and orders them into as few draws as
/// possible. CPU only; `SpriteRenderer` draws the result.
///
/// Sprites are drawn in ascending `order` (a larger value is in front). Among sprites with the
/// same `order`, those sharing a texture, sampler and blend mode are grouped so they batch,
/// which changes their relative drawing order: give overlapping sprites different `order`
/// values, or set `sortsByTexture` to false to keep submission order within an `order` (more
/// draws when textures alternate). Sorting is stable and deterministic.
///
/// World space is whatever the camera matrix passed to `SpriteRenderer.render` expects: with
/// `SpriteCamera` it is y-up. A sprite's quad is `size` units big, with `pivot` (0...1 from
/// the bottom-left) at the transform's origin; the transform may be any matrix, so sprites can
/// sit in a 3D scene too. There is no depth test.
@MainActor
public final class SpriteBatch {
    /// Group sprites of equal `order` by texture (default; fewer draws).
    public var sortsByTexture = true

    private struct Group {
        var texture: GPUTexture
        var sampler: GPUSampler?
        var blend: SpriteBlend
    }
    private struct Key: Hashable {
        var texture: ObjectIdentifier
        var sampler: ObjectIdentifier?
        var blend: SpriteBlend
    }
    private struct Entry {
        var group: Int
        var order: Float
        var corners: (SpriteVertex, SpriteVertex, SpriteVertex, SpriteVertex)
    }
    private var groups: [Group] = []
    private var groupIndex: [Key: Int] = [:]
    private var entries: [Entry] = []

    public init() {}

    /// Sprites queued since the last `clear()`.
    public var count: Int { entries.count }

    public func clear() {
        entries.removeAll(keepingCapacity: true)
        groups.removeAll(keepingCapacity: true)
        groupIndex.removeAll(keepingCapacity: true)
    }

    /// Queues a quad sampling `uvMin`...`uvMax` of `texture`. `size` is in world units,
    /// `transform` places the pivot, `tint` is linear RGBA multiplied with the texture.
    public func draw(texture: GPUTexture, sampler: GPUSampler? = nil, uvMin: Vec2 = .zero, uvMax: Vec2 = Vec2(1, 1),
                     size: Vec2, pivot: Vec2 = Vec2(0.5, 0.5), transform: Mat4 = .identity,
                     tint: Vec4 = Vec4(1, 1, 1, 1), flip: SpriteFlip = [], order: Float = 0, blend: SpriteBlend = .alpha) {
        let key = Key(texture: ObjectIdentifier(texture), sampler: sampler.map(ObjectIdentifier.init), blend: blend)
        let group: Int
        if let existing = groupIndex[key] {
            group = existing
        } else {
            group = groups.count
            groups.append(Group(texture: texture, sampler: sampler, blend: blend))
            groupIndex[key] = group
        }
        var u0 = uvMin.x, u1 = uvMax.x, v0 = uvMin.y, v1 = uvMax.y
        if flip.contains(.horizontal) { swap(&u0, &u1) }
        if flip.contains(.vertical) { swap(&v0, &v1) }
        let x0 = -pivot.x * size.x, x1 = (1 - pivot.x) * size.x
        let y0 = -pivot.y * size.y, y1 = (1 - pivot.y) * size.y
        func corner(_ x: Float, _ y: Float, _ u: Float, _ v: Float) -> SpriteVertex {
            let p = transform * Vec4(x, y, 0, 1)
            return SpriteVertex(position: Vec2(p.x, p.y), z: p.z, uv: Vec2(u, v), color: tint)
        }
        // Counter-clockwise from the bottom-left (v grows downward, so the bottom has v1).
        entries.append(Entry(group: group, order: order, corners: (
            corner(x0, y0, u0, v1), corner(x1, y0, u1, v1), corner(x1, y1, u1, v0), corner(x0, y1, u0, v0))))
    }

    /// Queues frame `frame` of `atlas` at `position` (and depth `z`), rotated by `rotation`
    /// radians counter-clockwise and scaled by `scale`. `pivot` overrides the frame's.
    public func draw(_ atlas: SpriteAtlas, frame: Int, position: Vec2, z: Float = 0, rotation: Float = 0,
                     scale: Vec2 = Vec2(1, 1), pivot: Vec2? = nil, tint: Vec4 = Vec4(1, 1, 1, 1),
                     flip: SpriteFlip = [], order: Float = 0, blend: SpriteBlend = .alpha) {
        let transform = Mat4(translation: Vec3(position.x, position.y, z), rotation: Quat(angle: rotation, axis: Vec3(0, 0, 1)),
                             scale: Vec3(scale.x, scale.y, 1))
        draw(atlas, frame: frame, transform: transform, pivot: pivot, tint: tint, flip: flip, order: order, blend: blend)
    }

    /// Queues frame `frame` of `atlas` under `transform` (its pivot at the origin).
    public func draw(_ atlas: SpriteAtlas, frame: Int, transform: Mat4, size: Vec2? = nil, pivot: Vec2? = nil,
                     tint: Vec4 = Vec4(1, 1, 1, 1), flip: SpriteFlip = [], order: Float = 0, blend: SpriteBlend = .alpha) {
        guard atlas.frames.indices.contains(frame) else { return }
        let f = atlas.frames[frame]
        draw(texture: atlas.texture, sampler: atlas.sampler, uvMin: f.uvMin, uvMax: f.uvMax,
             size: size ?? f.size / atlas.pixelsPerUnit, pivot: pivot ?? f.pivot, transform: transform,
             tint: tint, flip: flip, order: order, blend: blend)
    }

    /// Sorts the queued sprites and builds their vertices, indices and draws (consecutive
    /// sprites with the same texture, sampler and blend mode share a draw). Does not clear.
    public func prepare() -> SpriteBatchData {
        var data = SpriteBatchData()
        data.vertices.reserveCapacity(entries.count * 4)
        data.indices.reserveCapacity(entries.count * 6)
        let byTexture = sortsByTexture
        // Ties on everything else keep submission order.
        let sorted = entries.indices.sorted { a, b in
            let ea = entries[a], eb = entries[b]
            if ea.order != eb.order { return ea.order < eb.order }
            if byTexture && ea.group != eb.group { return ea.group < eb.group }
            return a < b
        }
        var currentGroup = -1
        for (n, i) in sorted.enumerated() {
            let entry = entries[i]
            if entry.group != currentGroup {
                let group = groups[entry.group]
                data.draws.append(SpriteDraw(texture: group.texture, sampler: group.sampler, blend: group.blend,
                                             firstIndex: n * 6, indexCount: 0))
                currentGroup = entry.group
            }
            data.draws[data.draws.count - 1].indexCount += 6
            let base = UInt32(data.vertices.count)
            data.vertices.append(contentsOf: [entry.corners.0, entry.corners.1, entry.corners.2, entry.corners.3])
            data.indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
        }
        return data
    }
}
