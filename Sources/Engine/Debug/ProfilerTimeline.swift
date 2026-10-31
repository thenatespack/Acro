import Foundation

/// The profiler's part of the overlay: the last frames as stacked bars (CPU scopes at the top
/// level of the main thread, then that frame's GPU passes next to them) and the newest frame
/// as an icicle chart of its nested scopes, with a lane per other thread (job workers) below it
/// on the same time axis.
extension DebugOverlay {
    private static let timelineFrames = 80
    /// Bar height reaches the top at this frame time.
    private static let timelineCeiling = 1.0 / 30.0
    private static let icicleRows = 6
    /// Most worker lanes shown under the icicle chart.
    private static let maxLanes = 16

    private static let palette: [(Float, Float, Float, Float)] = [
        (0.35, 0.65, 0.95, 1), (0.95, 0.60, 0.25, 1), (0.45, 0.80, 0.45, 1), (0.80, 0.50, 0.85, 1),
        (0.90, 0.80, 0.30, 1), (0.40, 0.80, 0.80, 1), (0.90, 0.45, 0.50, 1), (0.65, 0.65, 0.70, 1),
    ]

    /// The same name always gets the same color (a stable hash, not `String.hashValue`).
    static func color(for name: String) -> (Float, Float, Float, Float) {
        var hash: UInt32 = 2166136261
        for byte in name.utf8 { hash = (hash ^ UInt32(byte)) &* 16777619 }
        return palette[Int(hash % UInt32(palette.count))]
    }

    func appendProfilerTimeline(framebufferSize: (width: Int, height: Int), scale ui: Float) {
        let frames = Array(Profiler.frames.suffix(Self.timelineFrames))
        // Other threads of the newest frame, in profiler order (workers register in order).
        let lanes = Array(Set(frames.last?.events.lazy.filter { $0.thread != 0 }.map(\.thread) ?? []).sorted().prefix(Self.maxLanes))
        let pixel = ui
        let padding = 8 * ui
        let columnWidth = 6 * ui
        let barWidth = 2.5 * ui
        let width = Float(Self.timelineFrames) * columnWidth
        let barsHeight = 64 * ui
        let rowHeight = Float(BitmapFont.glyphHeight + 2) * pixel
        let headerHeight = Float(BitmapFont.glyphHeight + 3) * 1.5 * ui
        let icicleHeight = Float(Self.icicleRows + lanes.count) * rowHeight
        let panelWidth = width + padding * 2
        let panelHeight = padding * 4 + headerHeight * 2 + barsHeight + icicleHeight
        let originX = 10 * ui
        let originY = Float(framebufferSize.height) - panelHeight - 10 * ui
        rect(originX, originY, panelWidth, panelHeight, color: (0, 0, 0, 0.65))

        let left = originX + padding
        var y = originY + padding
        let last = frames.last
        let lastMs = (last?.duration ?? 0) * 1000
        text("CPU PROFILER  \(String(format: "%.1f", lastMs)) MS  (F3 OFF, F4 SAVE TRACE)", x: left, y: y, pixel: 1.5 * ui,
             color: (0.85, 0.85, 0.85, 1))
        y += headerHeight + padding / 2

        // Per frame: CPU top-level scopes stacked (left bar), GPU passes stacked (right bar).
        let barsTop = y
        rect(left, barsTop, width, barsHeight, color: (1, 1, 1, 0.06))
        func stack(_ segments: [(name: String, seconds: Double)], x: Float, barWidth: Float) {
            var bottom = barsTop + barsHeight
            for segment in segments {
                let height = Float(min(segment.seconds / Self.timelineCeiling, 1)) * barsHeight
                guard height > 0.25 else { continue }
                let top = max(bottom - height, barsTop)
                rect(x, top, barWidth, bottom - top, color: Self.color(for: segment.name))
                bottom = top
            }
        }
        for (i, frame) in frames.enumerated() {
            let x = left + Float(i) * columnWidth
            let cpu = frame.events.filter { $0.thread == 0 && $0.depth == 0 }.sorted { $0.start < $1.start }
            stack(cpu.map { ($0.name, $0.duration) }, x: x, barWidth: barWidth)
            stack(frame.gpuPasses.map { ($0.name, $0.seconds) }, x: x + barWidth, barWidth: barWidth * 0.6)
        }
        let target = barsTop + barsHeight - Float((1.0 / 60.0) / Self.timelineCeiling) * barsHeight
        rect(left, target, width, max(ui, 1), color: (1, 1, 1, 0.35))
        y = barsTop + barsHeight + padding

        // The newest frame's nested scopes on the main thread, each row one depth, then one
        // row per other thread with its outermost scopes (jobs, loop shares).
        let threads = JobSystem.shared.threadCount
        text("LAST FRAME  (\(threads) JOB THREAD\(threads == 1 ? "" : "S"))", x: left, y: y, pixel: 1.5 * ui, color: (0.85, 0.85, 0.85, 1))
        y += headerHeight
        guard let last else { return }
        let mainEvents = last.events.filter { $0.thread == 0 }
        let origin = min(last.start, mainEvents.map(\.start).min() ?? last.start)
        let span = max(last.end, mainEvents.map { $0.start + $0.duration }.max() ?? last.end) - origin
        guard span > 0 else { return }
        rect(left, y, width, icicleHeight, color: (1, 1, 1, 0.06))
        var rows: [(event: ProfilerEvent, row: Int)] = mainEvents.filter { $0.depth < Self.icicleRows }.map { ($0, $0.depth) }
        for (lane, thread) in lanes.enumerated() {
            rect(left, y + Float(Self.icicleRows + lane) * rowHeight, width, max(ui, 1), color: (1, 1, 1, 0.12))
            rows += last.events.filter { $0.thread == thread && $0.depth == 0 }.map { ($0, Self.icicleRows + lane) }
        }
        for (event, row) in rows {
            let x0 = left + Float(max(event.start - origin, 0) / span) * width
            guard x0 < left + width else { continue }
            let w = min(max(Float(event.duration / span) * width, 1), left + width - x0)
            let top = y + Float(row) * rowHeight
            rect(x0, top, w - 1, rowHeight - 1, color: Self.color(for: event.name))
            let label = event.name.uppercased()
            if Float(label.count * BitmapFont.advance) * pixel + 2 * pixel <= w {
                text(label, x: x0 + pixel, y: top + pixel, pixel: pixel, color: (0, 0, 0, 0.9))
            }
        }
    }
}
