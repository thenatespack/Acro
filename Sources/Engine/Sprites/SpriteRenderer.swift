import Foundation

/// A 2D camera for sprites: world units are y-up, `zoom` is pixels per world unit.
public struct SpriteCamera: Sendable, Equatable {
    /// World position shown at the center of the viewport.
    public var position: Vec2
    /// Pixels per world unit (2 shows everything twice as big).
    public var zoom: Float
    /// Radians the view is rotated counter-clockwise.
    public var rotation: Float
    /// Size of the render target in pixels.
    public var viewport: Vec2

    public init(position: Vec2 = .zero, zoom: Float = 1, rotation: Float = 0, viewport: Vec2) {
        self.position = position
        self.zoom = zoom
        self.rotation = rotation
        self.viewport = viewport
    }

    /// World (x, y) to clip space. Depth covers z from -1000 to 1000.
    public var viewProjection: Mat4 {
        let halfWidth = viewport.x / (2 * zoom), halfHeight = viewport.y / (2 * zoom)
        let projection = Mat4.orthographic(left: -halfWidth, right: halfWidth, bottom: -halfHeight, top: halfHeight,
                                           near: -1000, far: 1000)
        let view = Mat4(translation: Vec3(0, 0, 0), rotation: Quat(angle: -rotation, axis: Vec3(0, 0, 1)), scale: .one)
            * Mat4(translation: Vec3(-position.x, -position.y, 0), rotation: .identity, scale: .one)
        return projection * view
    }

    /// The world position under a pixel of the viewport (top-left origin, y down).
    public func worldPosition(ofPixel pixel: Vec2) -> Vec2 {
        let centered = Vec2(pixel.x - viewport.x / 2, viewport.y / 2 - pixel.y) / zoom
        let c = cosf(rotation), s = sinf(rotation)
        return position + Vec2(c * centered.x - s * centered.y, s * centered.x + c * centered.y)
    }
}

/// Draws sprites: queue them on `batch` (or with `draw(world:)` for entities), then `render`
/// into a pass to issue one indexed draw per run of sprites sharing a texture and blend mode.
///
/// Output is straight alpha, blended in the pass's (linear) color space; tints are linear RGBA
/// and `.rgba8Srgb` atlas textures sample as linear. Depth is neither tested nor written, so
/// the result depends on `order` only: draw sprites after the 3D scene in a pass, or inside
/// it for world-space billboards.
@MainActor
public final class SpriteRenderer {
    public let batch = SpriteBatch()
    /// Sprites, vertices and draw calls of the last `render`.
    public private(set) var stats = SpriteBatchStats()

    /// One pipeline per `SpriteBlend`.
    private let pipelines: [SpriteBlend: RenderPipeline]
    private let defaultSampler: GPUSampler
    private var atlases: [String: SpriteAtlas] = [:]

    public init(device: RenderDevice) throws {
        let shader = try ShaderSource.load(named: "sprite", bundle: .module)
        var pipelines: [SpriteBlend: RenderPipeline] = [:]
        for blend in [SpriteBlend.alpha, .opaque, .additive] {
            var descriptor = PipelineDescriptor(shader: shader, vertexLayout: SpriteVertex.layout)
            descriptor.cullMode = .none
            descriptor.depthTest = false
            descriptor.depthWrite = false
            descriptor.blendMode = blend.blendMode
            pipelines[blend] = try device.makePipeline(descriptor)
        }
        self.pipelines = pipelines
        defaultSampler = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .clampToEdge))
    }

    /// Names `atlas` so `Sprite` components can refer to it by `SpriteAtlasHandle`.
    public func registerAtlas(_ atlas: SpriteAtlas, key: String) {
        atlases[key] = atlas
    }

    public func atlas(for handle: SpriteAtlasHandle) -> SpriteAtlas? { atlases[handle.key] }

    /// Queues every `Sprite` entity: sized from its atlas frame (or `Sprite.size`) and placed
    /// by the entity's `GlobalTransform` (so call `world.propagateTransforms()` first; the
    /// world's update does). Sprites whose atlas isn't registered are skipped.
    public func draw(world: World) {
        world.query(Sprite.self, GlobalTransform.self) { _, sprite, global in
            guard sprite.visible, let atlas = atlases[sprite.atlas.key] else { return }
            batch.draw(atlas, frame: sprite.frame, transform: global.matrix, size: sprite.size, pivot: sprite.pivot,
                       tint: sprite.tint, flip: sprite.flip, order: sprite.order, blend: sprite.blend)
        }
    }

    /// Sorts and draws everything queued on `batch` with `viewProjection` (see `SpriteCamera`),
    /// then clears it. Returns the statistics (also kept in `stats`).
    @discardableResult
    public func render(into pass: RenderPass, viewProjection: Mat4) -> SpriteBatchStats {
        defer { batch.clear() }
        let data = batch.prepare()
        stats = SpriteBatchStats(sprites: batch.count, drawCalls: data.draws.count, vertices: data.vertices.count)
        guard !data.draws.isEmpty else { return stats }
        var pipeline = data.draws[0].blend
        pass.setPipeline(pipelines[pipeline]!)
        pass.setPushConstants(viewProjection)
        pass.setVertexData(data.vertices)
        pass.setIndexData(data.indices)
        var texture: GPUTexture?
        var sampler: GPUSampler?
        for draw in data.draws {
            if pipeline != draw.blend {
                pass.setPipeline(pipelines[draw.blend]!)
                pipeline = draw.blend
            }
            if texture !== draw.texture {
                pass.setTexture(draw.texture, index: 1)
                texture = draw.texture
            }
            let drawSampler = draw.sampler ?? defaultSampler
            if sampler !== drawSampler {
                pass.setSampler(drawSampler, index: 1)
                sampler = drawSampler
            }
            pass.drawIndexed(indexCount: draw.indexCount, instanceCount: 1, firstIndex: draw.firstIndex)
        }
        return stats
    }
}
