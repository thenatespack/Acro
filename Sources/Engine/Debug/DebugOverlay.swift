import Foundation

/// On-screen performance HUD: FPS, frame/CPU/GPU times, draw counts and a frame-time graph.
/// Everything is drawn as solid-colored quads (text included), streamed each frame via
/// `setVertexData`, so it needs no textures.
@MainActor
final class DebugOverlay {
    private struct Vertex {
        var x, y: Float
        var r, g, b, a: Float
    }

    private static let historyLength = 120
    /// Frame time at the top of the graph.
    private static let graphCeiling = 1.0 / 30.0
    private static let textRefreshInterval = 0.25

    private let pipeline: RenderPipeline
    private var vertices: [Vertex] = []
    private var history = [Double](repeating: 0, count: historyLength)
    private var historyIndex = 0

    // Averages shown as text, refreshed a few times per second so they're readable.
    private var lines: [String] = []
    private var lastRefresh = -Double.infinity
    private var accumulated = (frames: 0, frameTime: 0.0, cpuTime: 0.0)

    init(device: RenderDevice) throws {
        let shader = try ShaderSource.load(named: "overlay", bundle: .module)
        var descriptor = PipelineDescriptor(
            shader: shader,
            vertexLayout: VertexLayout(
                stride: MemoryLayout<Vertex>.stride,
                attributes: [
                    VertexAttribute(location: 0, format: .float2, offset: MemoryLayout<Vertex>.offset(of: \.x)!),
                    VertexAttribute(location: 1, format: .float4, offset: MemoryLayout<Vertex>.offset(of: \.r)!),
                ]))
        descriptor.cullMode = .none
        descriptor.depthTest = false
        descriptor.depthWrite = false
        descriptor.alphaBlending = true
        pipeline = try device.makePipeline(descriptor)
    }

    /// Feeds one frame of stats; call every frame, even when hidden, so the graph stays current.
    func record(_ stats: FrameStats) {
        history[historyIndex] = stats.frameTime
        historyIndex = (historyIndex + 1) % Self.historyLength
        accumulated.frames += 1
        accumulated.frameTime += stats.frameTime
        accumulated.cpuTime += stats.updateTime + stats.renderTime
    }

    func render(
        pass: RenderPass, stats: FrameStats, time: Double, framebufferSize: (width: Int, height: Int),
        contentScale: Float, backend: GraphicsBackend, deviceName: String
    ) {
        if time - lastRefresh >= Self.textRefreshInterval || lines.isEmpty {
            refreshText(stats: stats, framebufferSize: framebufferSize, backend: backend, deviceName: deviceName)
            lastRefresh = time
        }

        vertices.removeAll(keepingCapacity: true)
        let ui = max(contentScale, 1)
        let pixel = 2 * ui  // size of one font pixel
        let padding = 8 * ui
        let lineHeight = Float(BitmapFont.glyphHeight + 4) * pixel
        let barWidth = 2 * ui
        let graphWidth = Float(Self.historyLength) * barWidth
        let graphHeight = 48 * ui

        let longestLine = lines.map(\.count).max() ?? 0
        let textWidth = Float(longestLine * BitmapFont.advance - 1) * pixel
        let panelWidth = max(textWidth, graphWidth) + padding * 2
        let panelHeight = padding * 3 + Float(lines.count) * lineHeight - 4 * pixel + graphHeight
        let origin = (x: 10 * ui, y: 10 * ui)

        rect(origin.x, origin.y, panelWidth, panelHeight, color: (0, 0, 0, 0.65))

        var y = origin.y + padding
        for (index, line) in lines.enumerated() {
            let color: (Float, Float, Float, Float) = index == 0 ? fpsColor(stats.frameTime) : (0.85, 0.85, 0.85, 1)
            text(line, x: origin.x + padding, y: y, pixel: pixel, color: color)
            y += lineHeight
        }

        // Frame-time graph, oldest on the left. Bars are clamped at the ceiling.
        let graphTop = y - 4 * pixel + padding
        let graphLeft = origin.x + padding
        rect(graphLeft, graphTop, graphWidth, graphHeight, color: (1, 1, 1, 0.06))
        for i in 0..<Self.historyLength {
            let frameTime = history[(historyIndex + i) % Self.historyLength]
            guard frameTime > 0 else { continue }
            let height = Float(min(frameTime / Self.graphCeiling, 1)) * graphHeight
            rect(graphLeft + Float(i) * barWidth, graphTop + graphHeight - height, barWidth * 0.75, height,
                 color: fpsColor(frameTime))
        }
        // Reference line at 60 FPS.
        let target = graphTop + graphHeight - Float((1.0 / 60.0) / Self.graphCeiling) * graphHeight
        rect(graphLeft, target, graphWidth, max(ui, 1), color: (1, 1, 1, 0.35))

        pass.setPipeline(pipeline)
        pass.setPushConstants(Vec2(Float(framebufferSize.width), Float(framebufferSize.height)))
        pass.setVertexData(vertices)
        pass.draw(vertexCount: vertices.count)
    }

    private func refreshText(stats: FrameStats, framebufferSize: (width: Int, height: Int),
                             backend: GraphicsBackend, deviceName: String) {
        let frames = max(accumulated.frames, 1)
        let frameMs = accumulated.frameTime / Double(frames) * 1000
        let cpuMs = accumulated.cpuTime / Double(frames) * 1000
        accumulated = (0, 0, 0)

        let recent = history.filter { $0 > 0 }
        let minMs = (recent.min() ?? 0) * 1000
        let maxMs = (recent.max() ?? 0) * 1000
        let gpu = stats.gpuTime.map { String(format: "%.2f MS", $0 * 1000) } ?? "N/A"

        lines = [
            String(format: "%.0f FPS  %.2f MS", frameMs > 0 ? 1000 / frameMs : 0, frameMs),
            String(format: "MIN %.1f  MAX %.1f MS", minMs, maxMs),
            String(format: "CPU %.2f MS  GPU ", cpuMs) + gpu,
            "DRAWS \(stats.drawCalls)  TRIS \(stats.triangles)",
            "\(backend.rawValue) \(deviceName)",
            "\(framebufferSize.width)X\(framebufferSize.height)",
        ]
    }

    private func fpsColor(_ frameTime: Double) -> (Float, Float, Float, Float) {
        if frameTime <= 1.0 / 55.0 { return (0.3, 0.9, 0.4, 1) }
        if frameTime <= 1.0 / 28.0 { return (0.95, 0.8, 0.2, 1) }
        return (0.95, 0.3, 0.25, 1)
    }

    private func text(_ string: String, x: Float, y: Float, pixel: Float, color: (Float, Float, Float, Float)) {
        var penX = x
        for character in string {
            for (row, runs) in BitmapFont.runs(for: character).enumerated() {
                for run in runs {
                    rect(penX + Float(run.start) * pixel, y + Float(row) * pixel,
                         Float(run.length) * pixel, pixel, color: color)
                }
            }
            penX += Float(BitmapFont.advance) * pixel
        }
    }

    private func rect(_ x: Float, _ y: Float, _ width: Float, _ height: Float, color: (Float, Float, Float, Float)) {
        let (r, g, b, a) = color
        let x1 = x + width, y1 = y + height
        vertices.append(Vertex(x: x, y: y, r: r, g: g, b: b, a: a))
        vertices.append(Vertex(x: x1, y: y, r: r, g: g, b: b, a: a))
        vertices.append(Vertex(x: x1, y: y1, r: r, g: g, b: b, a: a))
        vertices.append(Vertex(x: x, y: y, r: r, g: g, b: b, a: a))
        vertices.append(Vertex(x: x1, y: y1, r: r, g: g, b: b, a: a))
        vertices.append(Vertex(x: x, y: y1, r: r, g: g, b: b, a: a))
    }
}
