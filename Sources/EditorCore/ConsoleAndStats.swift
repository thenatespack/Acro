import Engine
import Foundation

/// The console panel: the `EditorLog` with a level filter and a Clear button. Lines are
/// rebuilt only when the log or the filter changed, and the view follows new messages.
@MainActor
public final class ConsolePanel {
    public let log: EditorLog
    public let view: VStack
    /// Lines shown at most (the newest).
    public var maxLines = 300
    /// Whether lines start with the time stamp.
    public var showsTime = true

    public private(set) var minimumLevel: LogLevel = .info
    private let filter: Dropdown
    private let countLabel = Label("", role: .caption, name: "consoleCount")
    private let lines = VStack(spacing: 1, padding: EdgeInsets(top: 4, left: 8, bottom: 4, right: 8), name: "consoleLines")
    private let scroll: ScrollView
    private var shownChange = -1
    private var shownLevel: LogLevel?
    private var scrollToEnd = false

    static let levels: [(title: String, level: LogLevel)] = [("All", .info), ("Warnings", .warning), ("Errors", .error)]

    public init(log: EditorLog) {
        self.log = log
        filter = Dropdown(options: Self.levels.map(\.title), name: "consoleFilter")
        scroll = ScrollView(lines, name: "consoleScroll")
        scroll.scrollsHorizontally = true
        scroll.style.grow = 1
        scroll.style.shrink = 1
        view = VStack(spacing: 4, padding: EdgeInsets(top: 4, left: 4, bottom: 0, right: 4), name: "consolePanel")
        filter.style.width = 120
        filter.onChange = { [unowned self] index in minimumLevel = Self.levels[index].level }
        let bar = HStack(spacing: 8, padding: EdgeInsets(horizontal: 4, vertical: 0), [
            filter, Button("Clear", name: "consoleClear") { [unowned log] in log.clear() }, Spacer(), countLabel,
        ])
        view.addChildren([bar, scroll])
        refresh()
    }

    /// Shows only entries at `level` or above.
    public func setMinimumLevel(_ level: LogLevel) {
        minimumLevel = level
        if let index = Self.levels.firstIndex(where: { $0.level == level }) { filter.select(index) }
    }

    /// The text of the lines shown (for tests).
    public var shownLines: [String] {
        lines.children.compactMap { ($0 as? Label)?.text }
    }

    public func refresh() {
        if scrollToEnd {
            scrollToEnd = false
            scroll.scroll(to: .greatestFiniteMagnitude)
        }
        guard log.changeCount != shownChange || minimumLevel != shownLevel else { return }
        let grew = log.changeCount != shownChange
        shownChange = log.changeCount
        shownLevel = minimumLevel
        let entries = log.entries(atLeast: minimumLevel).suffix(maxLines)
        lines.removeAllChildren()
        for entry in entries {
            let label = Label(format(entry), role: entry.level == .info ? .secondary : .body)
            switch entry.level {
            case .info: break
            case .warning: label.color = UIColor(hex: 0xe8b04a)
            case .error: label.color = UIColor(hex: 0xf07167)
            }
            lines.addChild(label)
        }
        let warnings = log.count(of: .warning), errors = log.count(of: .error)
        countLabel.text = "\(log.entries.count) messages · \(warnings) warnings · \(errors) errors"
        if grew { scrollToEnd = true }
    }

    func format(_ entry: LogEntry) -> String {
        let tag = "[\(entry.level.tag)]".padding(toLength: 8, withPad: " ", startingAt: 0)
        guard showsTime else { return tag + entry.message }
        return String(format: "%7.2f  ", entry.time) + tag + entry.message
    }
}

/// Numbers for the stats panel, gathered by the host each frame.
public struct EditorStatsSnapshot: Sendable {
    public var frame = FrameStats()
    public var entityCount = 0
    public var viewportSize = (width: 0, height: 0)
    public var viewportDrawn = 0
    public var viewportCulled = 0
    public var undoDepth = 0
    public var redoDepth = 0
    public var isPlaying = false
    public var uiPaintTime: Double = 0

    public init() {}

    /// The panel's text, one line per entry.
    public var lines: [String] {
        func ms(_ seconds: Double) -> String { String(format: "%.2f ms", seconds * 1000) }
        var lines = [
            String(format: "%.0f FPS · frame %@", frame.fps, ms(frame.frameTime)),
            "CPU: update \(ms(frame.updateTime)), render \(ms(frame.renderTime)), UI paint \(ms(uiPaintTime))",
            "GPU: " + (frame.gpuTime.map(ms) ?? "n/a"),
        ]
        for pass in frame.gpuPassTimes { lines.append("    \(pass.name): \(ms(pass.seconds))") }
        lines += [
            "Draw calls: \(frame.drawCalls) · triangles: \(frame.triangles)",
            "Entities: \(entityCount) · viewport \(viewportSize.width)x\(viewportSize.height) px, "
                + "\(viewportDrawn) drawn / \(viewportCulled) culled",
            "Undo depth: \(undoDepth) · redo: \(redoDepth)",
            "Mode: " + (isPlaying ? "playing" : "editing"),
        ]
        return lines
    }
}

/// The stats panel: `EditorStatsSnapshot.lines`, refreshed a few times per second.
@MainActor
public final class StatsPanel {
    public let view: VStack
    /// Seconds between refreshes (text changes relayout the panel).
    public var interval: Double = 0.25
    private var lastRefresh = -Double.infinity

    public init() {
        view = VStack(spacing: 3, padding: EdgeInsets(10), name: "statsPanel")
    }

    public func refresh(_ stats: EditorStatsSnapshot, time: Double) {
        guard time - lastRefresh >= interval else { return }
        lastRefresh = time
        let lines = stats.lines
        while view.children.count < lines.count { view.addChild(Label("", role: .secondary)) }
        while view.children.count > lines.count { view.children.last?.removeFromParent() }
        for (label, line) in zip(view.children, lines) {
            if let label = label as? Label, label.text != line { label.text = line }
        }
    }
}
