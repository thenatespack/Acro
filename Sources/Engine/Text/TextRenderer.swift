import Foundation

/// One corner of a glyph quad as the text shader consumes it. `color` is linear RGB with
/// straight (non-premultiplied) alpha; the shader multiplies the alpha by the glyph coverage.
public struct TextVertex: Sendable, BitwiseCopyable {
    public var position: Vec2
    public var uv: Vec2
    public var color: Vec4
}

/// Glyph quads grouped by atlas page (two triangles each, 6 vertices), ready for one draw per
/// page. Positions are framebuffer pixels with the origin at the top-left. Use this directly
/// to feed another batcher: `GlyphAtlas.appendQuads` fills it, and `vertices[page]` plus
/// `atlas.texture(page:)` are what a draw needs.
public struct TextQuads {
    public var vertices: [[TextVertex]] = []

    public init() {}

    public var isEmpty: Bool { vertices.allSatisfy(\.isEmpty) }

    public mutating func removeAll() {
        for i in vertices.indices { vertices[i].removeAll(keepingCapacity: true) }
    }

    mutating func append(page: Int, min: Vec2, max: Vec2, uvMin: Vec2, uvMax: Vec2, color: Vec4) {
        while vertices.count <= page { vertices.append([]) }
        let corners = [
            TextVertex(position: Vec2(min.x, min.y), uv: Vec2(uvMin.x, uvMin.y), color: color),
            TextVertex(position: Vec2(max.x, min.y), uv: Vec2(uvMax.x, uvMin.y), color: color),
            TextVertex(position: Vec2(max.x, max.y), uv: Vec2(uvMax.x, uvMax.y), color: color),
            TextVertex(position: Vec2(min.x, max.y), uv: Vec2(uvMin.x, uvMax.y), color: color),
        ]
        vertices[page].append(contentsOf: [corners[0], corners[1], corners[2], corners[0], corners[2], corners[3]])
    }
}

extension GlyphAtlas {
    /// Rasterizes the glyphs of `layout` as needed and appends their quads to `quads`.
    /// `origin` is the top-left of the layout box in pixels. Glyphs without an outline
    /// (spaces) produce no quad.
    public func appendQuads(_ layout: TextLayout, font: Font, origin: Vec2, color: Vec4, to quads: inout TextQuads) {
        for placed in layout.glyphs {
            guard let info = info(for: placed.glyph, in: font) else { continue }
            let min = origin + Vec2(placed.x, placed.y) + info.offset * layout.size
            quads.append(page: info.page, min: min, max: min + info.extent * layout.size,
                         uvMin: info.uvMin, uvMax: info.uvMax, color: color)
        }
    }
}

/// Draws SDF text in screen pixels: queue strings with `draw`, then `render` into a pass to
/// issue one draw per atlas page.
///
/// Output is straight alpha onto the pass with standard alpha blending, and `color` is linear
/// RGB (the swapchain is sRGB). Depth is neither tested nor written, so draw text last in a
/// pass. Coordinates are pixels of the pass being drawn into, top-left origin, y down.
@MainActor
public final class TextRenderer {
    public let font: Font
    public let atlas: GlyphAtlas
    private let device: RenderDevice
    private let pipeline: RenderPipeline
    private let sampler: GPUSampler
    private var quads = TextQuads()

    /// Uses the bundled UI font unless `font` is given.
    public init(device: RenderDevice, font: Font? = nil, atlas: GlyphAtlas = GlyphAtlas()) throws {
        self.device = device
        self.font = try font ?? Font.bundledUI()
        self.atlas = atlas
        var descriptor = PipelineDescriptor(
            shader: try ShaderSource.load(named: "text", bundle: .module),
            vertexLayout: VertexLayout(
                stride: MemoryLayout<TextVertex>.stride,
                attributes: [
                    VertexAttribute(location: 0, format: .float2, offset: MemoryLayout<TextVertex>.offset(of: \.position)!),
                    VertexAttribute(location: 1, format: .float2, offset: MemoryLayout<TextVertex>.offset(of: \.uv)!),
                    VertexAttribute(location: 2, format: .float4, offset: MemoryLayout<TextVertex>.offset(of: \.color)!),
                ]))
        descriptor.cullMode = .none
        descriptor.depthTest = false
        descriptor.depthWrite = false
        descriptor.alphaBlending = true
        pipeline = try device.makePipeline(descriptor)
        sampler = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .clampToEdge))
    }

    /// Queues `text` with its top-left at `position`. `size` is the em size in pixels. With
    /// `maxWidth` the text wraps and is aligned within that width (see `TextLayout`).
    public func draw(_ text: String, at position: Vec2, size: Float, color: Vec4 = Vec4(1, 1, 1, 1),
                     maxWidth: Float? = nil, alignment: TextAlignment = .left, lineSpacing: Float = 1, font: Font? = nil) {
        let font = font ?? self.font
        let layout = TextLayout(text, font: font, size: size, maxWidth: maxWidth, alignment: alignment, lineSpacing: lineSpacing)
        atlas.appendQuads(layout, font: font, origin: position, color: color, to: &quads)
    }

    /// Size in pixels that `draw` would cover (see `TextLayout.bounds`).
    public func measure(_ text: String, size: Float, maxWidth: Float? = nil, lineSpacing: Float = 1, font: Font? = nil) -> Vec2 {
        TextLayout(text, font: font ?? self.font, size: size, maxWidth: maxWidth, lineSpacing: lineSpacing).bounds
    }

    /// Uploads atlas changes, draws everything queued (one draw per atlas page) and clears
    /// the queue. `screenSize` is the size in pixels of the pass's target.
    public func render(into pass: RenderPass, screenSize: (width: Int, height: Int)) throws {
        defer { quads.removeAll() }
        guard !quads.isEmpty else { return }
        try atlas.uploadDirtyPages(device: device)
        pass.setPipeline(pipeline)
        pass.setPushConstants(Vec2(Float(screenSize.width), Float(screenSize.height)))
        pass.setSampler(sampler, index: 1)
        for (page, vertices) in quads.vertices.enumerated() where !vertices.isEmpty {
            guard let texture = atlas.texture(page: page) else { continue }
            pass.setTexture(texture, index: 1)
            pass.setVertexData(vertices)
            pass.draw(vertexCount: vertices.count)
        }
    }
}
