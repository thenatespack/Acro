import Engine
import Foundation

/// Checks the script being edited as you type: a short pause after the last change, the game
/// target is type-checked with the editor's unsaved text (`GameModuleBuilder.typecheck`), in the
/// background, one check at a time. Nothing is saved, built or reloaded; the running game is
/// untouched. Results arrive through `poll()`, which the script editor calls every frame.
@MainActor
public final class ScriptChecker {
    public unowned let session: EditorSession
    /// Seconds without changes before a check starts.
    public var delay: Double = 0.4
    /// Whether text changes start checks at all.
    public var isEnabled = true

    public enum Status: Equatable, Sendable {
        /// Nothing checked yet (or the file changed and the last result was dropped).
        case idle
        /// Changes are waiting for the pause, or a check is running.
        case checking
        /// The last check's counts: in the checked file, and in the target's other files (an
        /// edit can break code that uses it).
        case checked(errors: Int, warnings: Int, otherFileErrors: Int, seconds: Double)
        /// Why there's no check (no game target, no build yet, files added, ...).
        case unavailable(String)
    }

    public private(set) var status: Status = .idle
    /// The checked file, and the last check's diagnostics in it (errors first).
    public private(set) var checkedURL: URL?
    public private(set) var diagnostics: [GameBuildDiagnostic] = []
    /// Every diagnostic the last check found, in any file.
    public private(set) var allDiagnostics: [GameBuildDiagnostic] = []
    /// Goes up whenever `status` or the diagnostics change.
    public private(set) var version = 0

    private var pending: (url: URL, text: String, due: Date)?
    private var running: Job?

    private final class Job: @unchecked Sendable {
        let url: URL
        private let lock = NSLock()
        private var outcome: GameModuleBuilder.TypecheckOutcome?
        init(url: URL) { self.url = url }
        func finish(_ outcome: GameModuleBuilder.TypecheckOutcome) { lock.withLock { self.outcome = outcome } }
        func take() -> GameModuleBuilder.TypecheckOutcome? { lock.withLock { outcome } }
    }

    public init(session: EditorSession) {
        self.session = session
    }

    /// The file at `url` now reads `text` (unsaved): check it after the pause, or with `now`
    /// set, at the next `poll()`.
    public func textChanged(_ text: String, in url: URL, now: Bool = false) {
        guard isEnabled else { return }
        let url = url.standardizedFileURL
        if url != checkedURL { clear(keeping: url) }
        pending = (url, text, now ? .distantPast : Date().addingTimeInterval(delay))
        set(.checking)
    }

    /// Forgets the pending check and the results (another file opened, the editor closed it).
    public func clear(keeping url: URL? = nil) {
        pending = nil
        checkedURL = url
        diagnostics = []
        allDiagnostics = []
        set(.idle)
    }

    /// Finishes a check that's done and starts the pending one once its pause has passed.
    public func poll(now: Date = Date()) {
        if let job = running, let outcome = job.take() {
            running = nil
            apply(outcome, for: job.url)
        }
        guard running == nil, let pending, pending.due <= now else { return }
        self.pending = nil
        let builder: GameModuleBuilder
        do { builder = try makeBuilder() } catch {
            set(.unavailable("\(error)"))
            return
        }
        let job = Job(url: pending.url)
        running = job
        let overrides = [pending.url.path: pending.text]
        DispatchQueue.global(qos: .userInitiated).async {
            job.finish(builder.typecheck(overrides: overrides))
        }
    }

    /// Whether a check is running or waiting.
    public var isBusy: Bool { running != nil || pending != nil }

    private func makeBuilder() throws -> GameModuleBuilder {
        guard let settings = session.gameModule.settings else { throw CommandError.failed("no game module") }
        guard let target = settings.target else { throw CommandError.failed("the game is a prebuilt library") }
        return GameModuleBuilder(packageURL: try session.gameModule.packageURL(), target: target, buildCommand: settings.buildCommand)
    }

    private func apply(_ outcome: GameModuleBuilder.TypecheckOutcome, for url: URL) {
        guard url == checkedURL else { return }  // another file was opened meanwhile
        switch outcome {
        case .unavailable(let reason):
            diagnostics = []
            allDiagnostics = []
            set(.unavailable(reason))
        case .checked(let result):
            let found = Self.diagnostics(in: result.output)
            let path = url.path
            let resolved = url.resolvingSymlinksInPath().path
            let inFile = found.filter { $0.file == path || $0.file == resolved }
            diagnostics = inFile.sorted { ($0.severity == .error ? 0 : 1, $0.line, $0.column) < ($1.severity == .error ? 0 : 1, $1.line, $1.column) }
            allDiagnostics = found
            let errors = inFile.filter { $0.severity == .error }.count
            let other = found.filter { $0.severity == .error }.count - errors
            set(.checked(errors: errors, warnings: inFile.count - errors, otherFileErrors: other, seconds: result.seconds))
        }
    }

    private func set(_ status: Status) {
        self.status = status
        version += 1
    }

    /// The errors and warnings in compiler output, once each (no notes).
    nonisolated static func diagnostics(in output: String) -> [GameBuildDiagnostic] {
        var seen = Set<String>()
        return output.split(separator: "\n").compactMap { line in
            let clean = EditorGameModule.strippingEscapes(String(line)).trimmingCharacters(in: .whitespaces)
            guard seen.insert(clean).inserted else { return nil }
            return GameBuildDiagnostic(compilerLine: clean, severities: [.error, .warning])
        }
    }
}
