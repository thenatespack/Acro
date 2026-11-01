import Foundation

/// Draws the world's `TextMesh` entities inside the scene pass (`SceneRenderer` creates one with
/// the first `TextMesh`, calls `prepare` once per frame, and `draw` after the transparent
/// meshes and particles, for every view).
///
/// - `prepare` resolves each text's font (cached per font spec), lays the text out and builds its
///   quads, cached per entity until a field affecting the layout changes; glyphs new to the
///   shared `GlyphAtlas` are rasterized then, and the atlas's changed rectangles are uploaded
///   there too, outside any render pass.
/// - `draw` sorts the texts back to front by distance from the camera and issues one draw per atlas
///   page per text: alpha blended, depth tested, no depth writes, no culling (`text3d.vert` hides
///   the back of single-sided text). Billboards use the view's right and up vectors.
@MainActor
final class WorldTextRenderer {
    /// Must match `Text` in text3d.vert / text3d.frag (std140).
    struct DrawUniforms: BitwiseCopyable {
        var model: Mat4
        var right: Vec4
        var up: Vec4
        var color: Vec4
        var emissive: Vec4
        var outlineColor: Vec4
        var glowColor: Vec4
    }

    /// What decides the quads of a text.
    private struct LayoutKey: Equatable {
        var text: String
        var font: String
        var size: Float
        var alignment: TextAlignment
        var verticalAlignment: TextVerticalAlignment
        var lineSpacing: Float
        var maxWidth: Float

        init(_ mesh: TextMesh) {
            text = mesh.text
            font = mesh.font
            size = mesh.size
            alignment = mesh.alignment
            verticalAlignment = mesh.verticalAlignment
            lineSpacing = mesh.lineSpacing
            maxWidth = mesh.maxWidth
        }
    }

    private final class Cached {
        var key: LayoutKey
        var geometry: TextMeshGeometry
        var fontRevision: Int
        init(key: LayoutKey, geometry: TextMeshGeometry, fontRevision: Int) {
            self.key = key
            self.geometry = geometry
            self.fontRevision = fontRevision
        }
    }

    struct Item {
        var uniforms: DrawUniforms
        var position: Vec3
        fileprivate var geometry: TextMeshGeometry
    }

    let atlas = GlyphAtlas()
    private let device: RenderDevice
    private let shader: ShaderSource
    private let sampler: GPUSampler
    private var pipelines: [Bool: RenderPipeline] = [:]
    private var cache: [Entity: Cached] = [:]
    /// Loaded fonts by `TextMesh.font`; nil entries are specs that failed (reported once).
    private var fonts: [String: Font?] = [:]
    private var bundled: Font?
    private var fontRevision = 0
    private(set) var items: [Item] = []

    init(device: RenderDevice) throws {
        self.device = device
        shader = try ShaderSource.load(vertex: "text3d", fragment: "text3d", bundle: .module)
        sampler = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .clampToEdge))
    }

    /// Number of fonts loaded for texts so far (the bundled one included).
    var fontCount: Int { fonts.values.filter { $0 != nil }.count + (bundled == nil ? 0 : 1) }

    // MARK: - Fonts

    private func bundledFont() -> Font? {
        if bundled == nil {
            do { bundled = try Font.bundledUI() } catch { print("TextMesh: bundled font unavailable: \(error)") }
        }
        return bundled
    }

    /// The font `spec` names (see `TextMesh`), or Inter when it is empty or can't be loaded.
    func font(_ spec: String, assets: AssetDatabase?) -> Font? {
        if spec.isEmpty { return bundledFont() }
        if let known = fonts[spec] { return known ?? bundledFont() }
        let loaded = Self.loadFont(spec, assets: assets)
        fonts[spec] = .some(loaded)
        if loaded == nil { print("TextMesh: font '\(spec)' could not be loaded; using the bundled font") }
        return loaded ?? bundledFont()
    }

    static func loadFont(_ spec: String, assets: AssetDatabase?) -> Font? {
        var path = spec
        var index = 0
        if let hash = spec.lastIndex(of: "#"), let n = Int(spec[spec.index(after: hash)...]) {
            path = String(spec[..<hash])
            index = n
        }
        var candidates: [URL] = []
        if let reference = AssetReference(path), let assets, let relative = assets.path(of: reference.asset) {
            candidates.append(assets.project.url(forAssetPath: relative))
        } else {
            if path.hasPrefix("/") { candidates.append(URL(fileURLWithPath: path)) }
            if let assets {
                candidates.append(assets.project.url(forAssetPath: path))
                candidates.append(assets.project.root.appendingPathComponent(path))
            }
            if !path.hasPrefix("/") { candidates.append(URL(fileURLWithPath: path)) }
        }
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            if let font = try? Font(contentsOf: url, index: index) { return font }
        }
        return nil
    }

    // MARK: - Frame

    /// Gathers the world's visible texts (laying out those that changed) and uploads the atlas.
    func prepare(world: World, assets: AssetDatabase?) {
        items.removeAll(keepingCapacity: true)
        var seen = Set<Entity>()
        world.query(TextMesh.self, GlobalTransform.self) { entity, mesh, global in
            guard mesh.isVisible, mesh.opacity > 0, !mesh.text.isEmpty else { return }
            seen.insert(entity)
            let key = LayoutKey(mesh)
            let entry: Cached
            if let cached = cache[entity], cached.key == key, cached.fontRevision == fontRevision {
                entry = cached
            } else {
                guard let font = font(mesh.font, assets: assets) else { return }
                entry = Cached(key: key, geometry: TextMeshGeometry(mesh, font: font, atlas: atlas), fontRevision: fontRevision)
                cache[entity] = entry
            }
            guard entry.geometry.glyphCount > 0 else { return }
            let matrix = global.matrix
            let outline = min(max(mesh.outlineWidth, 0), TextMesh.maxEffectSize) * Self.distancePerEm
            let extent = min(max(mesh.glowSize, 0), TextMesh.maxEffectSize) * Self.distancePerEm
            let emissive = mesh.emissiveColor * mesh.emissiveStrength
            let glowBase = emissive == .zero ? mesh.color : emissive
            items.append(Item(
                uniforms: DrawUniforms(
                    model: matrix, right: Vec4(1, 0, 0, mesh.billboard ? 1 : 0), up: Vec4(0, 1, 0, mesh.doubleSided ? 0 : 1),
                    color: Vec4(mesh.color, min(mesh.opacity, 1)), emissive: Vec4(emissive, 0),
                    outlineColor: Vec4(mesh.outlineColor, outline), glowColor: Vec4(glowBase * mesh.glowStrength, extent)),
                position: Vec3(matrix.c3.x, matrix.c3.y, matrix.c3.z), geometry: entry.geometry))
        }
        if cache.count > seen.count { cache = cache.filter { seen.contains($0.key) } }
        guard !items.isEmpty else { return }
        do { try atlas.uploadDirtyPages(device: device) } catch { print("TextMesh: glyph atlas upload failed: \(error)") }
    }

    /// Distance-field units per em: 0.5 spans the atlas padding (`GlyphAtlas.padding` of `sdfSize`).
    static var distancePerEm: Float { 0.5 / (Float(GlyphAtlas.padding) / GlyphAtlas.sdfSize) }

    private func pipeline(reversedZ: Bool) -> RenderPipeline? {
        if let pipeline = pipelines[reversedZ] { return pipeline }
        var descriptor = PipelineDescriptor(shader: shader, vertexLayout: VertexLayout(
            stride: MemoryLayout<WorldTextVertex>.stride,
            attributes: [
                VertexAttribute(location: 0, format: .float2, offset: MemoryLayout<WorldTextVertex>.offset(of: \.position)!),
                VertexAttribute(location: 1, format: .float2, offset: MemoryLayout<WorldTextVertex>.offset(of: \.uv)!),
            ]))
        descriptor.cullMode = .none
        descriptor.depthWrite = false
        descriptor.depthCompare = reversedZ ? .greater : .less
        descriptor.alphaBlending = true
        do {
            let pipeline = try device.makePipeline(descriptor)
            pipelines[reversedZ] = pipeline
            return pipeline
        } catch {
            print("TextMesh: pipeline creation failed: \(error)")
            return nil
        }
    }

    /// Draws the prepared texts back to front for a camera at `eye` with `view`'s orientation. The
    /// frame uniforms (set 0) must be bound.
    func draw(in pass: RenderPass, view: Mat4, eye: Vec3, reversedZ: Bool) {
        guard !items.isEmpty, let pipeline = pipeline(reversedZ: reversedZ) else { return }
        let right = Vec3(view.c0.x, view.c1.x, view.c2.x), up = Vec3(view.c0.y, view.c1.y, view.c2.y)
        func distanceSquared(_ item: Item) -> Float {
            let d = item.position - eye
            return dot(d, d)
        }
        let order = items.indices.sorted { distanceSquared(items[$0]) > distanceSquared(items[$1]) }
        pass.setPipeline(pipeline)
        pass.setSampler(sampler, index: 1)
        for index in order {
            var uniforms = items[index].uniforms
            uniforms.right = Vec4(right, uniforms.right.w)
            uniforms.up = Vec4(up, uniforms.up.w)
            pass.setUniformData(uniforms, index: 2, stage: .all)
            for (page, vertices) in items[index].geometry.vertices.enumerated() where !vertices.isEmpty {
                guard let texture = atlas.texture(page: page) else { continue }
                pass.setTexture(texture, index: 1)
                pass.setVertexData(vertices)
                pass.draw(vertexCount: vertices.count)
            }
        }
    }
}
