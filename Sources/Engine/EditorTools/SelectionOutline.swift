/// How `SelectionOutlineRenderer` draws the outline.
public struct SelectionOutlineStyle: Sendable, Equatable {
    /// Width in points (times the view's pixel scale: constant on screen).
    public var width: Float
    /// Linear RGBA of the primary (most recently selected) entity's outline.
    public var primaryColor: Vec4
    /// Linear RGBA of the other selected entities' outlines.
    public var secondaryColor: Vec4
    /// Opacity of the outline where the selected entity is hidden behind unselected geometry.
    /// 1 draws it fully everywhere and skips the occlusion test (no occluder draws: cheaper).
    public var hiddenOpacity: Float
    /// Outline the selected entities' descendants too (selecting a parent outlines its subtree).
    public var includesDescendants: Bool

    public init(width: Float = 2, primaryColor: Vec4 = Vec4(1, 0.6, 0.08, 1), secondaryColor: Vec4 = Vec4(0.9, 0.25, 0.02, 1),
                hiddenOpacity: Float = 0.3, includesDescendants: Bool = true) {
        self.width = width
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.hiddenOpacity = hiddenOpacity
        self.includesDescendants = includesDescendants
    }

    /// The width in pixels and the search radius (whole pixels) of the composite for `pixelScale`.
    func pixels(scale: Float) -> (width: Float, radius: Int) {
        let width = max(self.width * scale, 0)
        return (width, Int((width + 1).rounded(.up)))
    }
}

/// The CPU side of the selection outline (unit-tested on its own): which entities are outlined,
/// the draws of the mask pass, the composite's screen rectangle, and a reference implementation
/// of the composite shader.
public enum SelectionOutline {
    /// Mask channels, as written by the mask pass (r, g, b of the mask target).
    public struct MaskTexel: OptionSet, Sendable, Hashable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let selected = MaskTexel(rawValue: 1)
        /// In front of every unselected occluder.
        public static let visible = MaskTexel(rawValue: 2)
        public static let primary = MaskTexel(rawValue: 4)
    }

    /// The entities to outline: the selection (live ones), plus with `includesDescendants` their
    /// subtrees, mapped to whether they belong to the primary entity (descendants inherit it
    /// from the nearest selected ancestor).
    @MainActor public static func outlinedEntities(selection: [Entity], primary: Entity?, includesDescendants: Bool,
                                                   in world: World) -> [Entity: Bool] {
        var result: [Entity: Bool] = [:]
        let selected = Set(selection)
        for root in selection where world.isAlive(root) {
            let isPrimary = root == primary
            result[root] = isPrimary || result[root] == true
            guard includesDescendants else { continue }
            var stack = world.children(of: root)
            while let entity = stack.popLast() {
                if selected.contains(entity) { continue }  // outlined on its own account
                result[entity] = isPrimary || result[entity] == true
                stack += world.children(of: entity)
            }
        }
        return result
    }

    /// A run of `instances` drawn with one mesh.
    public struct Batch: Equatable, Sendable {
        public var mesh: Int
        public var first: Int
        public var count: Int
        /// Occluders: draw both faces (double-sided material). Selected batches always do.
        public var doubleSided: Bool
        /// Selected batches: the primary entity's.
        public var primary: Bool
        /// The skinned item's `RenderItem.skin` (one instance, drawn posed), else -1.
        public var skin: Int = -1
    }

    /// The mask pass's draws for one view: occluders (opaque, unselected, in the frustum, only
    /// when `occlusion`), then selected entities' secondary and primary batches, laid out in one
    /// instance array. Batches keep the items' first-appearance order.
    public struct Draws: Sendable {
        public var instances: [MeshInstance] = []
        public var occluders: [Batch] = []
        public var selected: [Batch] = []
        /// World bounds of the selected items in the frustum (for the composite's scissor).
        public var selectedBounds: [Bounds] = []
    }

    /// Splits gathered render items into the mask pass's draws. `doubleSided` says whether a
    /// material id draws both faces (occluders are then not back-face culled).
    public static func draws(items: [RenderItem], outlined: [Entity: Bool], frustum: Frustum, occlusion: Bool,
                             doubleSided: (Int) -> Bool) -> Draws {
        var occluders: [Int: [MeshInstance]] = [:], occluderOrder: [Int] = []  // key: mesh * 2 + double-sided
        var selected: [Int: [MeshInstance]] = [:], selectedOrder: [Int] = []  // key: mesh * 2 + primary
        // Skinned items are drawn one at a time with their joint matrices, after the others.
        var skinnedOccluders: [(item: RenderItem, doubleSided: Bool)] = [], skinnedSelected: [(item: RenderItem, primary: Bool)] = []
        var draws = Draws()
        for item in items {
            let isPrimary = outlined[item.entity]
            if isPrimary == nil && (!occlusion || item.transparent) { continue }
            guard frustum.intersects(center: item.bounds.center, halfExtent: item.bounds.halfExtent) else { continue }
            if item.skin >= 0 {
                if let isPrimary {
                    skinnedSelected.append((item, isPrimary))
                    draws.selectedBounds.append(item.bounds)
                } else {
                    skinnedOccluders.append((item, doubleSided(item.material)))
                }
            } else if let isPrimary {
                let key = item.mesh * 2 + (isPrimary ? 1 : 0)
                if selected[key] == nil { selectedOrder.append(key) }
                selected[key, default: []].append(item.instance)
                draws.selectedBounds.append(item.bounds)
            } else {
                let key = item.mesh * 2 + (doubleSided(item.material) ? 1 : 0)
                if occluders[key] == nil { occluderOrder.append(key) }
                occluders[key, default: []].append(item.instance)
            }
        }
        for key in occluderOrder {
            let instances = occluders[key]!
            draws.occluders.append(Batch(mesh: key >> 1, first: draws.instances.count, count: instances.count,
                                         doubleSided: key & 1 == 1, primary: false))
            draws.instances += instances
        }
        for (item, doubleSided) in skinnedOccluders {
            draws.occluders.append(Batch(mesh: item.mesh, first: draws.instances.count, count: 1, doubleSided: doubleSided,
                                         primary: false, skin: item.skin))
            draws.instances.append(item.instance)
        }
        // Secondary before primary: where they overlap, the primary's flag is written last.
        for primary in [false, true] {
            for key in selectedOrder where (key & 1 == 1) == primary {
                let instances = selected[key]!
                draws.selected.append(Batch(mesh: key >> 1, first: draws.instances.count, count: instances.count,
                                            doubleSided: true, primary: primary))
                draws.instances += instances
            }
            for (item, isPrimary) in skinnedSelected where isPrimary == primary {
                draws.selected.append(Batch(mesh: item.mesh, first: draws.instances.count, count: 1, doubleSided: true,
                                            primary: primary, skin: item.skin))
                draws.instances.append(item.instance)
            }
        }
        return draws
    }

    /// The rectangle of a `width` x `height` target the composite has to cover: the projected
    /// bounds grown by `radius` pixels, or the whole target if a box reaches behind the eye; nil
    /// when nothing is on screen.
    public static func scissor(for bounds: [Bounds], viewProjection: Mat4, width: Int, height: Int, radius: Int) -> ScissorRect? {
        guard !bounds.isEmpty else { return nil }
        var lo = Vec2(repeating: .infinity), hi = Vec2(repeating: -.infinity)
        for box in bounds {
            for i in 0..<8 {
                let corner = box.center + box.halfExtent * Vec3(i & 1 == 0 ? -1 : 1, i & 2 == 0 ? -1 : 1, i & 4 == 0 ? -1 : 1)
                let clip = viewProjection * Vec4(corner, 1)
                guard clip.w > 1e-5 else { return ScissorRect(x: 0, y: 0, width: width, height: height) }
                let pixel = Vec2((clip.x / clip.w + 1) * 0.5 * Float(width), (1 - clip.y / clip.w) * 0.5 * Float(height))
                lo = pointwiseMin(lo, pixel)
                hi = pointwiseMax(hi, pixel)
            }
        }
        let pad = Float(radius + 1)
        let x0 = max(Int((lo.x - pad).rounded(.down)), 0), y0 = max(Int((lo.y - pad).rounded(.down)), 0)
        let x1 = min(Int((hi.x + pad).rounded(.up)), width), y1 = min(Int((hi.y + pad).rounded(.up)), height)
        guard x1 > x0, y1 > y0 else { return nil }
        return ScissorRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// The composite shader (outline_composite.frag) on the CPU: the outline color and alpha at
    /// pixel (x, y) of a `width`-wide mask, or nil where nothing is drawn.
    public static func coverage(mask: [MaskTexel], width: Int, x: Int, y: Int, style: SelectionOutlineStyle,
                                pixelScale: Float = 1) -> Vec4? {
        let height = mask.count / width
        if mask[y * width + x].contains(.selected) { return nil }
        let (lineWidth, radius) = style.pixels(scale: pixelScale)
        var nearest: Float = 1e9, nearestVisible: Float = 1e9, nearestPrimary: Float = 1e9
        for dy in -radius...radius {
            for dx in -radius...radius {
                let qx = x + dx, qy = y + dy
                guard qx >= 0, qy >= 0, qx < width, qy < height else { continue }
                let m = mask[qy * width + qx]
                guard m.contains(.selected) else { continue }
                let d = Float(dx * dx + dy * dy).squareRoot()
                nearest = min(nearest, d)
                if m.contains(.visible) { nearestVisible = min(nearestVisible, d) }
                if m.contains(.primary) { nearestPrimary = min(nearestPrimary, d) }
            }
        }
        let visible = min(max(lineWidth + 1 - nearestVisible, 0), 1)
        let hidden = min(max(lineWidth + 1 - nearest, 0), 1) * style.hiddenOpacity
        let alpha = max(visible, hidden)
        guard alpha > 0 else { return nil }
        let color = nearestPrimary <= nearest ? style.primaryColor : style.secondaryColor
        return Vec4(color.x, color.y, color.z, color.w * alpha)
    }
}

/// A silhouette outline around selected entities in an editor view, a constant number of
/// pixels wide, in a primary and a secondary color, and dimmed where the entity is hidden
/// behind other geometry.
///
/// Two steps per view, around `SceneRenderer.renderView`:
///
/// 1. `prepare` (after `beginViews`, before the view's `renderView`) renders a mask target the
///    size of the view's target: the unselected opaque entities depth-only, then the selected
///    ones (and their descendants) once without a depth test (selected) and once with it
///    (visible), flagging the primary selection. It reuses the entities `beginViews` gathered.
/// 2. `draw(in:)`, from `renderView`'s `overlay`, composites the outline into the view: a
///    fullscreen triangle, scissored to the selection's screen rectangle, that searches the
///    mask around each pixel (texel loads; see outline_composite.frag).
///
/// `renderView(...)` does both. Each view needs its own renderer (it owns the view's mask).
/// GPU time: the mask pass is timed under `maskLabel`; the composite counts toward the view's pass.
@MainActor
public final class SelectionOutlineRenderer {
    public let device: RenderDevice
    public var style = SelectionOutlineStyle()
    /// The last prepared mask (r: selected, g: visible, b: primary).
    public let mask: RenderTarget
    /// What the last `prepare` drew.
    public private(set) var lastDraws = SelectionOutline.Draws()

    private let maskShader: ShaderSource
    /// outline_mask_skinned.vert with the same fragment shader, loaded with the first skinned draw.
    private var skinnedMaskShader: ShaderSource?
    private let compositeShader: ShaderSource
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    private let sampler: GPUSampler
    /// Set by `prepare`, used by `draw`.
    private var pending: (scissor: ScissorRect, width: Float, radius: Int)?

    private enum PipelineKey: Hashable {
        case occluder(doubleSided: Bool, reversedZ: Bool, skinned: Bool)
        case selected(skinned: Bool)
        case visible(reversedZ: Bool, skinned: Bool)
        case composite

        var skinned: Bool {
            switch self {
            case .occluder(_, _, let skinned), .selected(let skinned), .visible(_, let skinned): return skinned
            case .composite: return false
            }
        }
    }

    /// Must match `PushConstants` in outline_mask.vert / .frag.
    struct MaskConstants: BitwiseCopyable {
        var viewProj: Mat4
        var color: Vec4
    }

    /// Must match `PushConstants` in outline_composite.frag.
    struct CompositeConstants: BitwiseCopyable {
        var primaryColor: Vec4
        var secondaryColor: Vec4
        var params: Vec4
        var maskMax: SIMD4<Int32>
    }

    /// Only the position (location 0) of `MeshVertex`.
    static let vertexLayout = VertexLayout(
        stride: MemoryLayout<MeshVertex>.stride,
        attributes: [VertexAttribute(location: 0, format: .float3, offset: MemoryLayout<MeshVertex>.offset(of: \.position)!)])
    /// Only the model matrix (locations 3–6) of `MeshInstance`.
    /// The position and the skinning attributes of `SkinnedMeshVertex`.
    static let skinnedVertexLayout = VertexLayout(
        stride: MemoryLayout<SkinnedMeshVertex>.stride,
        attributes: SkinnedMeshVertex.layout.attributes.filter { [0, 14, 15].contains($0.location) })
    static let instanceLayout = VertexLayout(
        stride: MemoryLayout<MeshInstance>.stride,
        attributes: (0..<4).map { VertexAttribute(location: 3 + $0, format: .float4, offset: $0 * MemoryLayout<Vec4>.stride) })

    public init(device: RenderDevice, maskLabel: String = "outline mask") throws {
        self.device = device
        maskShader = try ShaderSource.load(named: "outline_mask", bundle: .module)
        compositeShader = try ShaderSource.load(named: "outline_composite", bundle: .module)
        mask = try RenderTarget(device: device, width: 1, height: 1, multisampled: false, label: maskLabel)
        sampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
    }

    /// Renders the mask for `view` (drawn into `target`, at `pixelScale` pixels per point) of
    /// `selection` (`primary` gets the primary color). Call after `sceneRenderer.beginViews` and
    /// before the `renderView` whose overlay calls `draw(in:)`. Draws nothing when no selected
    /// entity is visible.
    public func prepare(selection: [Entity], primary: Entity?, world: World, sceneRenderer: SceneRenderer, view: SceneView,
                        target: RenderTarget, pixelScale: Float, frame: Frame) {
        pending = nil
        let outlined = SelectionOutline.outlinedEntities(selection: selection, primary: primary,
                                                         includesDescendants: style.includesDescendants, in: world)
        guard !outlined.isEmpty else {
            lastDraws = SelectionOutline.Draws()
            return
        }
        let prep = sceneRenderer.prep
        let occlusion = style.hiddenOpacity < 1
        let doubleSided = prep.materials.keys.map { sceneRenderer.material(MaterialHandle($0))?.doubleSided ?? false }
        let draws = SelectionOutline.draws(
            items: prep.items, outlined: outlined, frustum: Frustum(viewProjection: view.viewProjection), occlusion: occlusion,
            doubleSided: { doubleSided[$0] })
        lastDraws = draws
        let (width, radius) = style.pixels(scale: pixelScale)
        guard !draws.selected.isEmpty,
              let scissor = SelectionOutline.scissor(for: draws.selectedBounds, viewProjection: view.viewProjection,
                                                      width: target.width, height: target.height, radius: radius) else { return }
        do {
            try mask.resize(width: target.width, height: target.height)
        } catch {
            print("SelectionOutlineRenderer: resizing the mask failed: \(error)")
            return
        }

        let meshes = prep.meshes.keys.map { sceneRenderer.mesh(MeshHandle($0)) }
        let instances = frame.upload(draws.instances)
        let viewProj = view.viewProjection
        frame.renderPass(into: mask, clearColor: .zero, clearDepth: view.reversedZ ? 0 : 1) { pass in
            let mesh = { (batch: SelectionOutline.Batch) in meshes[batch.mesh] }
            for batch in draws.occluders {
                drawMask(pass, batch, mesh: mesh(batch), instances: instances, viewProj: viewProj,
                         key: .occluder(doubleSided: batch.doubleSided, reversedZ: view.reversedZ, skinned: batch.skin >= 0),
                         color: .zero, sceneRenderer: sceneRenderer)
            }
            // Without the occlusion test every selected texel counts as visible.
            for batch in draws.selected {
                drawMask(pass, batch, mesh: mesh(batch), instances: instances, viewProj: viewProj, key: .selected(skinned: batch.skin >= 0),
                         color: Vec4(1, occlusion ? 0 : 1, batch.primary ? 1 : 0, 1), sceneRenderer: sceneRenderer)
            }
            guard occlusion else { return }
            for batch in draws.selected {
                drawMask(pass, batch, mesh: mesh(batch), instances: instances, viewProj: viewProj,
                         key: .visible(reversedZ: view.reversedZ, skinned: batch.skin >= 0), color: Vec4(1, 1, batch.primary ? 1 : 0, 1),
                         sceneRenderer: sceneRenderer)
            }
        }
        pending = (scissor, width, radius)
    }

    private func drawMask(_ pass: RenderPass, _ batch: SelectionOutline.Batch, mesh: GPUMesh?, instances: TransientBuffer,
                          viewProj: Mat4, key: PipelineKey, color: Vec4, sceneRenderer: SceneRenderer) {
        guard let mesh, mesh.isSkinned == key.skinned, let pipeline = pipeline(key) else { return }
        pass.setPipeline(pipeline)
        pass.setPushConstants(MaskConstants(viewProj: viewProj, color: color))
        if batch.skin >= 0 { sceneRenderer.bindSkin(batch.skin, material: nil, in: pass) }
        pass.setVertexBuffer(mesh.vertexBuffer)
        pass.setIndexBuffer(mesh.indexBuffer, type: .uint32)
        pass.setVertexBuffer(instances.buffer, offset: instances.offset + batch.first * MemoryLayout<MeshInstance>.stride, index: 1)
        pass.drawIndexed(indexCount: mesh.indexCount, instanceCount: batch.count)
    }

    /// Composites the outline prepared by the last `prepare` into `pass` (the view's pass, e.g.
    /// in `renderView`'s `overlay`). Leaves the pass without a scissor.
    public func draw(in pass: RenderPass) {
        guard let pending, let pipeline = pipeline(.composite) else { return }
        pass.setPipeline(pipeline)
        pass.setScissorRect(pending.scissor)
        pass.setTexture(mask.texture, index: 1)
        pass.setSampler(sampler, index: 1)
        pass.setPushConstants(CompositeConstants(
            primaryColor: style.primaryColor, secondaryColor: style.secondaryColor,
            params: Vec4(pending.width, min(max(style.hiddenOpacity, 0), 1), Float(pending.radius), 0),
            maskMax: SIMD4(Int32(mask.width - 1), Int32(mask.height - 1), 0, 0)))
        pass.draw(vertexCount: 3)
        pass.setScissorRect(nil)
    }

    /// `prepare`, then `sceneRenderer.renderView` with the outline composited after `debugDraw`
    /// and before `overlay` (so gizmos drawn there stay on top of it).
    public func renderView(_ view: SceneView, sceneRenderer: SceneRenderer, world: World, selection: [Entity], primary: Entity?,
                           into target: RenderTarget, pixelScale: Float, frame: Frame, debugDraw: DebugDraw? = nil,
                           overlay: ((RenderPass) -> Void)? = nil) {
        prepare(selection: selection, primary: primary, world: world, sceneRenderer: sceneRenderer, view: view, target: target,
                pixelScale: pixelScale, frame: frame)
        sceneRenderer.renderView(view, into: target, frame: frame, debugDraw: debugDraw) { pass in
            self.draw(in: pass)
            overlay?(pass)
        }
    }

    private func pipeline(_ key: PipelineKey) -> RenderPipeline? {
        if let pipeline = pipelines[key] { return pipeline }
        var descriptor: PipelineDescriptor
        if key == .composite {
            descriptor = PipelineDescriptor(shader: compositeShader, vertexLayout: .none)
            descriptor.depthTest = false
            descriptor.depthWrite = false
            descriptor.alphaBlending = true
        } else if key.skinned {
            if skinnedMaskShader == nil {
                do {
                    skinnedMaskShader = try ShaderSource.load(vertex: "outline_mask_skinned", fragment: "outline_mask", bundle: .module)
                } catch {
                    print("SelectionOutlineRenderer: skinned mask shader unavailable: \(error)")
                    return nil
                }
            }
            descriptor = PipelineDescriptor(shader: skinnedMaskShader!, vertexLayout: Self.skinnedVertexLayout,
                                            instanceLayout: Self.instanceLayout)
        } else {
            descriptor = PipelineDescriptor(shader: maskShader, vertexLayout: Self.vertexLayout, instanceLayout: Self.instanceLayout)
        }
        descriptor.cullMode = .none
        descriptor.writesMotionVectors = false
        switch key {
        case .occluder(let doubleSided, let reversedZ, _):
            descriptor.cullMode = doubleSided ? .none : .back
            descriptor.colorWrites = false
            descriptor.depthCompare = reversedZ ? .greater : .less
        case .selected:
            descriptor.depthTest = false
            descriptor.depthWrite = false
        case .visible(let reversedZ, _):
            descriptor.depthWrite = false
            descriptor.depthCompare = reversedZ ? .greaterEqual : .lessEqual
        case .composite:
            break
        }
        do {
            let pipeline = try device.makePipeline(descriptor)
            pipelines[key] = pipeline
            return pipeline
        } catch {
            print("SelectionOutlineRenderer: pipeline creation failed: \(error)")
            return nil
        }
    }
}
