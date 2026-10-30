/// The camera and target a `DebugDraw` is drawn for.
public struct DebugView: Sendable {
    /// The view-projection the scene in the pass was drawn with (jittered, if it was).
    public var viewProjection: Mat4
    public var cameraPosition: Vec3
    /// Size of the pass's target in pixels (line widths are in these pixels).
    public var viewportSize: (width: Int, height: Int)
    /// The scene uses reversed-Z depth (near = 1, depth compare `.greater`).
    public var reversedZ: Bool
    /// `projection.c1.y`, which converts world-unit line widths to pixels.
    public var projectionScale: Float

    public init(viewProjection: Mat4, cameraPosition: Vec3, viewportSize: (width: Int, height: Int), reversedZ: Bool,
                projectionScale: Float) {
        self.viewProjection = viewProjection
        self.cameraPosition = cameraPosition
        self.viewportSize = viewportSize
        self.reversedZ = reversedZ
        self.projectionScale = projectionScale
    }

    /// From a view matrix (world to camera) and a projection.
    public init(view: Mat4, projection: Mat4, viewportSize: (width: Int, height: Int), reversedZ: Bool) {
        let eye = view.inverse.c3
        self.init(viewProjection: projection * view, cameraPosition: Vec3(eye.x, eye.y, eye.z), viewportSize: viewportSize,
                  reversedZ: reversedZ, projectionScale: projection.c1.y)
    }
}

/// Draws `DebugDraw` lists into a pass: the grid, then the depth-tested triangles and lines, then
/// the triangles and lines on top (one instanced draw each), then the labels (one draw per
/// glyph-atlas page).
/// `SceneRenderer` owns one and calls it for its `debugDraw` in every view it renders; use one
/// directly to draw debug geometry in your own passes. Pipelines are `.screen` ones, so it works in
/// the scene pass and in render targets alike.
@MainActor
public final class DebugDrawRenderer {
    public let device: RenderDevice
    private let lineShader: ShaderSource
    private let gridShader: ShaderSource
    private let fillShader: ShaderSource
    private var pipelines: [PipelineKey: RenderPipeline] = [:]
    private var text: TextRenderer?

    private struct PipelineKey: Hashable {
        var kind: Kind
        var depth: DebugDepth
        var reversedZ: Bool
    }

    private enum Kind: Hashable { case grid, lines, fills }

    /// Must match `PushConstants` in debug_line.vert.
    struct LineConstants: BitwiseCopyable {
        var viewProj: Mat4
        var viewport: Vec4
    }

    /// Must match `Grid` in debug_grid.vert / .frag (std140: only mat4 and vec4).
    struct GridUniforms: BitwiseCopyable {
        var viewProj: Mat4
        var camera: Vec4
        var params: Vec4
        var minorColor: Vec4
        var majorColor: Vec4
        var xAxisColor: Vec4
        var zAxisColor: Vec4
    }

    public init(device: RenderDevice) throws {
        self.device = device
        lineShader = try ShaderSource.load(named: "debug_line", bundle: .module)
        gridShader = try ShaderSource.load(named: "debug_grid", bundle: .module)
        fillShader = try ShaderSource.load(named: "debug_fill", bundle: .module)
    }

    /// Records `debug` into `pass` for `view`. Draws nothing when it's empty.
    public func draw(_ debug: DebugDraw, in pass: RenderPass, view: DebugView) {
        guard !debug.isEmpty else { return }
        let viewport = Vec4(Float(view.viewportSize.width), Float(view.viewportSize.height), view.reversedZ ? 1 : 0,
                            view.projectionScale)
        if let grid = debug.grid, let pipeline = pipeline(PipelineKey(kind: .grid, depth: .tested, reversedZ: view.reversedZ)) {
            pass.setPipeline(pipeline)
            pass.setUniformData(GridUniforms(
                viewProj: view.viewProjection,
                camera: Vec4(view.cameraPosition, grid.height),
                params: Vec4(max(grid.spacing, 1e-4), Float(max(grid.majorEvery, 1)), grid.fadeDistance, grid.lineWidth),
                minorColor: grid.minorColor, majorColor: grid.majorColor,
                xAxisColor: grid.xAxisColor, zAxisColor: grid.zAxisColor), index: 2)
            pass.draw(vertexCount: 6)
        }
        for depth in DebugDepth.allCases {
            if let triangles = debug.triangles[depth], !triangles.isEmpty,
               let pipeline = pipeline(PipelineKey(kind: .fills, depth: depth, reversedZ: view.reversedZ)) {
                pass.setPipeline(pipeline)
                pass.setPushConstants(LineConstants(viewProj: view.viewProjection, viewport: viewport))
                pass.setVertexData(triangles, index: 1)
                pass.draw(vertexCount: 3, instanceCount: triangles.count)
            }
            guard let segments = debug.segments[depth], !segments.isEmpty,
                  let pipeline = pipeline(PipelineKey(kind: .lines, depth: depth, reversedZ: view.reversedZ)) else { continue }
            pass.setPipeline(pipeline)
            pass.setPushConstants(LineConstants(viewProj: view.viewProjection, viewport: viewport))
            pass.setVertexData(segments, index: 1)
            pass.draw(vertexCount: 6, instanceCount: segments.count)
        }
        if !debug.labels.isEmpty { drawLabels(debug.labels, in: pass, view: view) }
    }

    private func drawLabels(_ labels: [DebugDraw.Label], in pass: RenderPass, view: DebugView) {
        if text == nil {
            do {
                text = try TextRenderer(device: device)
            } catch {
                print("DebugDrawRenderer: no text renderer for labels: \(error)")
            }
        }
        guard let text else { return }
        let size = Vec2(Float(view.viewportSize.width), Float(view.viewportSize.height))
        for label in labels {
            let clip = view.viewProjection * Vec4(label.position, 1)
            // In front of the near plane only (clip z in front of 0, or of w with reversed-Z).
            let depth = view.reversedZ ? clip.w - clip.z : clip.z
            guard clip.w > 0, depth >= 0 else { continue }
            let pixel = Vec2(clip.x / clip.w + 1, 1 - clip.y / clip.w) * 0.5 * size
            let extent = text.measure(label.text, size: label.size)
            // Snapped to whole pixels so glyphs stay sharp.
            let origin = Vec2((pixel.x - extent.x / 2).rounded(), (pixel.y - extent.y / 2).rounded())
            text.draw(label.text, at: origin, size: label.size, color: label.color)
        }
        do {
            try text.render(into: pass, screenSize: view.viewportSize)
        } catch {
            print("DebugDrawRenderer: labels failed: \(error)")
        }
    }

    private func pipeline(_ key: PipelineKey) -> RenderPipeline? {
        if let pipeline = pipelines[key] { return pipeline }
        var descriptor = switch key.kind {
        case .grid: PipelineDescriptor(shader: gridShader, vertexLayout: .none)
        case .lines: PipelineDescriptor(shader: lineShader, vertexLayout: .none, instanceLayout: DebugSegment.layout)
        case .fills: PipelineDescriptor(shader: fillShader, vertexLayout: .none, instanceLayout: DebugTriangle.layout)
        }
        descriptor.cullMode = .none
        descriptor.depthTest = key.depth == .tested
        descriptor.depthCompare = key.reversedZ ? .greaterEqual : .lessEqual
        descriptor.depthWrite = false
        descriptor.alphaBlending = true
        descriptor.writesMotionVectors = false  // temporal upscalers see the motion of what's behind
        do {
            let pipeline = try device.makePipeline(descriptor)
            pipelines[key] = pipeline
            return pipeline
        } catch {
            print("DebugDrawRenderer: pipeline creation failed: \(error)")
            return nil
        }
    }
}
