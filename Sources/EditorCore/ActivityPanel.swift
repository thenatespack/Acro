import Engine
import Foundation

/// The Activity panel: every call AI clients made over MCP (newest at the bottom) with its
/// arguments, outcome and the undo step it recorded, a Revert button per call that made one
/// (`activity.revert {entry}`: undoes it and the AI steps after it) and Revert AI Changes for
/// the whole last AI batch, Clear, and the AI settings (`ai.settings`): read-only mode, asking
/// before destructive calls, and the HTTP server.
@MainActor
public final class ActivityPanel {
    public let session: EditorSession
    public let view: VStack
    /// Lines shown at most (the newest).
    public var maxRows = 100

    private let revertAll = Button("Revert AI Changes", name: "activityRevertAll")
    private let clearButton = Button("Clear", name: "activityClear")
    private let readOnly = Checkbox("Read-only", name: "aiReadOnly")
    private let askFirst = Checkbox("Ask before destructive", name: "aiAskBeforeDestructive")
    private let http = Checkbox("HTTP server", name: "aiHTTP")
    private let summary = Label("", role: .caption, name: "activityCount")
    private let rows = VStack(spacing: 2, padding: EdgeInsets(top: 4, left: 8, bottom: 4, right: 8), name: "activityRows")
    private let scroll: ScrollView
    private var shownKey: [Int] = []

    public init(session: EditorSession) {
        self.session = session
        scroll = ScrollView(rows, name: "activityScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        view = VStack(spacing: 4, padding: EdgeInsets(top: 4, left: 4, bottom: 0, right: 4), name: "activityPanel")

        revertAll.command = ActivityRevertCommand.id.rawValue
        revertAll.tooltip = "Undo every change AI clients made since your last edit"
        revertAll.action = { [unowned session] in session.run(ActivityRevertCommand.self, .init()) }
        clearButton.command = ActivityClearCommand.id.rawValue
        clearButton.tooltip = "Clear the activity log (the undo history stays)"
        clearButton.action = { [unowned session] in session.run(ActivityClearCommand.self) }
        for box in [readOnly, askFirst, http] { box.command = AISettingsCommand.id.rawValue }
        readOnly.tooltip = "AI clients may only look (perception and query tools)"
        askFirst.tooltip = "Ask here before an AI client deletes files or discards unsaved changes"
        http.tooltip = "Serve MCP over HTTP on localhost (token required) while the editor runs"
        readOnly.onChange = { [unowned session] on in session.run(AISettingsCommand.self, .init(readOnly: on)) }
        askFirst.onChange = { [unowned session] on in session.run(AISettingsCommand.self, .init(askBeforeDestructive: on)) }
        http.onChange = { [unowned session] on in session.run(AISettingsCommand.self, .init(httpEnabled: on)) }

        let bar = HStack(spacing: 8, padding: EdgeInsets(horizontal: 4, vertical: 0), name: "activityBar", [
            revertAll, clearButton, Separator(.vertical), readOnly, askFirst, http, Spacer(), summary,
        ])
        view.addChildren([bar, scroll])
        refresh()
    }

    /// Re-reads the log, the undo history and the settings; call every frame.
    public func refresh() {
        let settings = session.aiSettings
        if readOnly.isOn != settings.readOnly { readOnly.isOn = settings.readOnly }
        if askFirst.isOn != settings.askBeforeDestructive { askFirst.isOn = settings.askBeforeDestructive }
        if http.isOn != settings.httpEnabled { http.isOn = settings.httpEnabled }
        let canRevert = session.commands.isAvailable(ActivityRevertCommand.id)
        if revertAll.isEnabled != canRevert { revertAll.isEnabled = canRevert }

        let key = [session.activity.changeCount, session.undo.changeCount]
        guard key != shownKey else { return }
        shownKey = key
        let entries = session.activity.entries.suffix(maxRows)
        let calls = session.activity.entries.count
        summary.text = calls == 0 ? "No AI activity" : "\(calls) call\(calls == 1 ? "" : "s")"
        rows.removeAllChildren()
        let history = session.undo.undoHistory
        for entry in entries {
            let text = "\(Self.time(entry.time))  \(entry.tool) \(Self.compact(entry.arguments))  →  \(entry.outcome.rawValue)"
                + (entry.outcome == .ok || entry.summary.isEmpty ? "" : ": \(entry.summary)")
            let line = Label(text, role: entry.outcome == .ok || entry.outcome == .running ? .body : .secondary,
                             name: "activity.\(entry.id)")
            line.style.grow = 1
            line.style.shrink = 1
            line.style.width = 0
            line.tooltip = "\(entry.tool) \(entry.arguments)\n\(entry.summary)"
            var children: [Widget] = [line]
            if let label = entry.undoLabel {
                let step = Label(label, role: .caption, name: "activityStep.\(entry.id)")
                children.append(step)
                let revert = Button("Revert", name: "activityRevert.\(entry.id)") { [unowned session] in
                    session.run(ActivityRevertCommand.self, .init(entry: entry.id))
                }
                revert.command = ActivityRevertCommand.id.rawValue
                revert.tooltip = "Undo this call's change (and the AI changes after it)"
                revert.isEnabled = Self.canRevert(entry, history: history, depth: session.undo.undoDepth)
                children.append(revert)
            }
            rows.addChild(HStack(spacing: 6, name: "activityRow.\(entry.id)", children))
        }
        scroll.scroll(to: .greatestFiniteMagnitude)
    }

    /// Whether `activity.revert {entry}` would work now.
    static func canRevert(_ entry: ActivityEntry, history: [String], depth: Int) -> Bool {
        guard let label = entry.undoLabel, let after = entry.undoDepth else { return false }
        let steps = depth - (after - 1)
        return steps >= 1 && steps <= history.count && history[steps - 1] == label
            && history.prefix(steps).allSatisfy { $0.hasPrefix(EditorSession.aiUndoPrefix) }
    }

    private static func time(_ seconds: Double) -> String {
        let total = Int(seconds.rounded(.down))
        return String(format: "%02d:%02d", total / 60 % 60, total % 60)
    }

    private static func compact(_ arguments: String) -> String {
        arguments == "{}" ? "" : EditorActivityLog.shorten(arguments, limit: 120)
    }
}
