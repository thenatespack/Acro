import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Checking scripts as you type: `GameModuleBuilder.typecheck` (the cached plan replayed with
// `-typecheck` and unsaved text in stand-in files), `ScriptChecker`, and the code editor's
// markers. The real-compiler tests use a two-file package with a hand-written plan (no Engine
// dependency), since `swift build` can't run inside `swift test` (the .build lock).

/// A package with `Sources/Game/{Mover,Uses}.swift` and a cached plan that compiles them with
/// plain `swiftc`.
private struct TinyPackage {
    let root: URL
    var mover: URL { root.appendingPathComponent("Sources/Game/Mover.swift") }
    var uses: URL { root.appendingPathComponent("Sources/Game/Uses.swift") }
    static let moverText = "public struct Mover {\n    public var speed: Float = 1\n    public init() {}\n}\n"
    static let usesText = "func go() -> Float {\n    let m = Mover()\n    return m.speed\n}\n"

    init(plan: Bool = true) throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("script-check-\(UUID().uuidString)", isDirectory: true)
        let folder = root.appendingPathComponent("Sources/Game", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try "// swift-tools-version:5.9\n".write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try Self.moverText.write(to: mover, atomically: true, encoding: .utf8)
        try Self.usesText.write(to: uses, atomically: true, encoding: .utf8)
        guard plan else { return }
        let builder = GameModuleBuilder(packageURL: root, target: "Game")
        let manifestDate = try #require(try FileManager.default.attributesOfItem(atPath: root.appendingPathComponent("Package.swift").path)[.modificationDate] as? Date)
        let sources = [mover, uses].map { GameModuleBuildPlan.standardPath($0.path) }.sorted()
        let cache: [String: Any] = [
            "manifestDate": manifestDate.timeIntervalSinceReferenceDate,
            "targets": ["target": "Game", "libraryTargets": [String](), "folders": ["Game": folder.path]],
            "plan": ["target": "Game", "arguments": ["swiftc", "-module-name", "Game", "-parse-as-library"], "sources": sources],
        ]
        try FileManager.default.createDirectory(at: builder.cacheFolder, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: cache)
            .write(to: builder.cacheFolder.appendingPathComponent("\(builder.configuration)-Game.json"))
    }

    var builder: GameModuleBuilder { GameModuleBuilder(packageURL: root, target: "Game") }
    func remove() { try? FileManager.default.removeItem(at: root) }
}

@Suite struct ScriptCheckerTests {
    @Test func diagnosticsParseWarningsWhenAsked() throws {
        let warning = "/p/Sources/Game/A.swift:3:9: warning: initialization of immutable value 'x' was never used"
        #expect(GameBuildDiagnostic(compilerLine: warning) == nil)  // errors only by default
        let parsed = try #require(GameBuildDiagnostic(compilerLine: warning, severities: [.error, .warning]))
        #expect(parsed.severity == .warning && parsed.line == 3 && parsed.column == 9)
        #expect(GameBuildDiagnostic(compilerLine: "/p/A.swift:1:1: note: here", severities: [.error, .warning]) == nil)
        // JSON from before severities existed decodes as errors.
        let old = #"{"file":"/p/A.swift","line":2,"column":4,"message":"boom"}"#
        #expect(try JSONDecoder().decode(GameBuildDiagnostic.self, from: Data(old.utf8)).severity == .error)
    }

    @Test func checkerOutputParsingDropsRepeatsAndColors() {
        let output = """
        \u{1B}[1m/p/A.swift:2:5: error: cannot find 'speeed' in scope\u{1B}[0m
        /p/A.swift:2:5: error: cannot find 'speeed' in scope
        /p/A.swift:1:1: note: did you mean 'speed'?
        /p/B.swift:7:3: warning: variable 'y' was never mutated
        """
        let found = ScriptChecker.diagnostics(in: output)
        #expect(found.map(\.summary) == ["A.swift:2:5: cannot find 'speeed' in scope", "B.swift:7:3: variable 'y' was never mutated"])
        #expect(found.map(\.severity) == [.error, .warning])
    }

    @Test func typecheckCommandAddsOnlyTheMode() {
        let plan = GameModuleBuildPlan(target: "Game", arguments: ["/tc/swiftc", "-module-name", "Game"], sources: ["/p/A.swift"])
        #expect(plan.typecheckCommand(sources: ["/s/A.swift"]) == ["/tc/swiftc", "-module-name", "Game", "/s/A.swift", "-typecheck"])
    }

    @Test func typecheckNeedsAPlan() throws {
        let package = try TinyPackage(plan: false)
        defer { package.remove() }
        guard case .unavailable(let reason) = package.builder.typecheck(overrides: [:]) else {
            Issue.record("checked without a plan")
            return
        }
        #expect(reason.contains("build the game once"))
    }

    @Test func typecheckUsesUnsavedTextAndReportsTheRealPath() throws {
        let package = try TinyPackage()
        defer { package.remove() }

        guard case .checked(let clean) = package.builder.typecheck(overrides: [package.uses.path: TinyPackage.usesText]) else {
            Issue.record("no check")
            return
        }
        #expect(clean.succeeded, "\(clean.output)")

        // Unsaved: a typo in Uses.swift. The file on disk stays as it was.
        let broken = TinyPackage.usesText.replacingOccurrences(of: "m.speed", with: "m.speeed")
        guard case .checked(let result) = package.builder.typecheck(overrides: [package.uses.path: broken]) else {
            Issue.record("no check")
            return
        }
        #expect(!result.succeeded)
        let diagnostics = ScriptChecker.diagnostics(in: result.output).filter { $0.severity == .error }
        let first = try #require(diagnostics.first, "\(result.output)")
        #expect(first.file == GameModuleBuildPlan.standardPath(package.uses.path))
        #expect(first.line == 3 && first.message.contains("speeed"))
        #expect(try String(contentsOf: package.uses, encoding: .utf8) == TinyPackage.usesText)
        // The stand-in folder is gone.
        let checks = package.builder.cacheFolder.appendingPathComponent("check")
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: checks.path)) ?? []).isEmpty)

        // Removing a field another file uses: the error is in that other file.
        let renamed = TinyPackage.moverText.replacingOccurrences(of: "speed", with: "pace")
        guard case .checked(let elsewhere) = package.builder.typecheck(overrides: [package.mover.path: renamed]) else {
            Issue.record("no check")
            return
        }
        #expect(ScriptChecker.diagnostics(in: elsewhere.output).contains { $0.file.hasSuffix("Uses.swift") && $0.severity == .error })
    }

    @Test func typecheckRefusesFilesOutsideTheTarget() throws {
        let package = try TinyPackage()
        defer { package.remove() }
        guard case .unavailable(let reason) = package.builder.typecheck(overrides: ["/elsewhere/Other.swift": "x"]) else {
            Issue.record("checked a file outside the target")
            return
        }
        #expect(reason.contains("not a source file"))
    }

    @MainActor @Test func checkerFindsErrorsInTheOpenFile() async throws {
        let package = try TinyPackage()
        defer { package.remove() }
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.gameModule.configure(GameModuleSettings(target: "Game", package: package.root.path), base: package.root)
        let checker = ScriptChecker(session: session)

        func settle() async throws {
            // Generous: CI runs the whole suite in parallel on a few cores, and the check's result
            // arrives through poll() on the main actor every @MainActor test shares. It returns
            // as soon as the check lands.
            let deadline = Date().addingTimeInterval(300)
            repeat {
                checker.poll()
                if !checker.isBusy { return }
                try await Task.sleep(nanoseconds: 20_000_000)
            } while Date() < deadline
            // The sleep can outlast the deadline when other tests hold the main actor (heavy
            // imports run on it), while the check runs on its own thread: look once more.
            checker.poll()
            if !checker.isBusy { return }
            Issue.record("the check didn't finish")
        }

        checker.textChanged(TinyPackage.usesText.replacingOccurrences(of: "m.speed", with: "m.speeed"), in: package.uses, now: true)
        #expect(checker.status == .checking)
        try await settle()
        guard case .checked(let errors, _, let other, _) = checker.status else {
            Issue.record("status \(checker.status)")
            return
        }
        #expect(errors == 1 && other == 0)
        #expect(checker.diagnostics.first?.line == 3)

        // Fixed: no errors. Another file's result clears the markers.
        checker.textChanged(TinyPackage.usesText, in: package.uses, now: true)
        try await settle()
        #expect(checker.diagnostics.isEmpty)
        if case .checked(let errors, _, _, _) = checker.status { #expect(errors == 0) } else { Issue.record("status \(checker.status)") }
        checker.textChanged(TinyPackage.moverText, in: package.mover)
        #expect(checker.checkedURL == package.mover.standardizedFileURL && checker.diagnostics.isEmpty)
    }

    @MainActor @Test func editorMarkersFollowAddedAndRemovedLines() {
        let editor = CodeEditorWidget(text: "a\nb\nc\nd")
        editor.diagnostics = [GameBuildDiagnostic(file: "/p/A.swift", line: 1, column: 1, message: "first"),
                              GameBuildDiagnostic(file: "/p/A.swift", line: 3, column: 1, message: "third")]
        // A new line after "a": the second marker moves down.
        editor.goTo(line: 1, column: 2)
        _ = editor.handleEvent(.text("\n"))
        #expect(editor.diagnostics.map(\.line) == [1, 4])
        #expect(editor.diagnosticsByLine[3]?.message == "third")
        // Replacing the text drops them.
        editor.text = "x"
        #expect(editor.diagnostics.isEmpty)
    }
}
