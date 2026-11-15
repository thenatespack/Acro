import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

@Suite struct ScriptEditorTests {
    // MARK: - CodeEditBuffer Tests

    @Test func bufferLineCountingAndIndexing() {
        let code = "import Engine\n\nstruct Player: Component {\n    var speed: Float = 5.0\n}\n"
        let buffer = CodeEditBuffer(code)

        #expect(buffer.lineCount == 6)
        #expect(buffer.lineString(0) == "import Engine")
        #expect(buffer.lineString(1) == "")
        #expect(buffer.lineString(2) == "struct Player: Component {")
        #expect(buffer.lineString(3) == "    var speed: Float = 5.0")
        #expect(buffer.lineString(4) == "}")
        #expect(buffer.lineString(5) == "")

        // Verify line index lookup
        #expect(buffer.lineIndex(for: 0) == 0)
        #expect(buffer.lineIndex(for: 13) == 0) // end of line 0
        #expect(buffer.lineIndex(for: 14) == 1) // line 1 (empty)
        #expect(buffer.lineIndex(for: 15) == 2) // start of line 2

        // Column index
        #expect(buffer.columnIndex(for: 0) == 0)
        #expect(buffer.columnIndex(for: 6) == 6)
        #expect(buffer.columnIndex(for: 15) == 0) // start of line 2
        #expect(buffer.columnIndex(for: 21) == 6) // 'struct' in line 2
    }

    @Test func bufferInsertionAndDeletion() {
        var buffer = CodeEditBuffer("func hello() {\n}")
        buffer.setCaret(14) // right after '{'
        buffer.insertNewline()

        #expect(buffer.lineCount == 3)
        // Auto-indentation after '{' should add 4 spaces
        #expect(buffer.lineString(1) == "    ")
        #expect(buffer.caret == 19)

        buffer.insert("print(\"hi\")")
        #expect(buffer.lineString(1) == "    print(\"hi\")")

        // Delete backward: when at col 4 with 4 spaces, deletes all 4 spaces (un-indent)
        var indentBuffer = CodeEditBuffer("    var x = 1")
        indentBuffer.setCaret(4)
        indentBuffer.deleteBackward()
        #expect(indentBuffer.text == "var x = 1")
    }

    @Test func bufferCaretMovement() {
        var buffer = CodeEditBuffer("Line 1\nLine 2\nLine 3")
        buffer.setCaret(0)
        buffer.moveDown()
        #expect(buffer.lineIndex(for: buffer.caret) == 1)
        #expect(buffer.columnIndex(for: buffer.caret) == 0)

        buffer.moveToLineEnd()
        #expect(buffer.columnIndex(for: buffer.caret) == 6)

        buffer.moveUp()
        #expect(buffer.lineIndex(for: buffer.caret) == 0)
        #expect(buffer.columnIndex(for: buffer.caret) == 6)

        buffer.moveToLineStart()
        #expect(buffer.columnIndex(for: buffer.caret) == 0)
    }

    @Test func bufferUndoRedo() {
        var buffer = CodeEditBuffer("initial")
        buffer.recordUndo()
        buffer.insert(" edit")
        #expect(buffer.text == "initial edit")

        let undone = buffer.undo()
        #expect(undone)
        #expect(buffer.text == "initial")

        let redone = buffer.redo()
        #expect(redone)
        #expect(buffer.text == "initial edit")
    }

    @Test func bufferIndentDedent() {
        var buffer = CodeEditBuffer("first\nsecond")
        buffer.select(0..<12) // select all
        buffer.indent()
        #expect(buffer.lineString(0) == "    first")
        #expect(buffer.lineString(1) == "    second")

        buffer.dedent()
        #expect(buffer.lineString(0) == "first")
        #expect(buffer.lineString(1) == "second")
    }

    // MARK: - SwiftSyntaxTokenizer Tests

    @Test func syntaxTokenizerIdentifiesTokens() {
        let line = "public struct Orbiter: Component { // movement"
        let tokens = SwiftSyntaxTokenizer.tokenize(line: line)

        let kinds = tokens.map(\.kind)
        #expect(kinds.contains(.keyword))
        #expect(kinds.contains(.type))
        #expect(kinds.contains(.comment))

        let keywordTokens = tokens.filter { $0.kind == .keyword }.map(\.text)
        #expect(keywordTokens.contains("public"))
        #expect(keywordTokens.contains("struct"))

        let typeTokens = tokens.filter { $0.kind == .type }.map(\.text)
        #expect(typeTokens.contains("Orbiter"))
        #expect(typeTokens.contains("Component"))

        let commentTokens = tokens.filter { $0.kind == .comment }.map(\.text)
        #expect(commentTokens.contains("// movement"))
    }

    // MARK: - Script Commands Tests

    @MainActor
    @Test func scriptCommandsWorkflow() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        session.startFolder = tempDir

        // 1. Create a new script via script.new
        let newResult = try session.commands.run(ScriptNewCommand.self, .init(name: "TestComponent.swift"))
        #expect(newResult.created)
        #expect(FileManager.default.fileExists(atPath: newResult.path))

        // 2. List scripts via script.list
        let listResult = try session.commands.run(ScriptListCommand.self, NoArguments())
        #expect(listResult.scripts.contains(where: { $0.hasSuffix("TestComponent.swift") }))

        // 3. Open script via script.open
        let openResult = try session.commands.run(ScriptOpenCommand.self, .init(path: newResult.path))
        #expect(openResult.content.contains("struct TestComponent: Script"))
        #expect(openResult.lineCount > 5)

        // 4. Save script modifications via script.save
        let modifiedCode = "// Updated script\nstruct TestComponent: Component {\n    var value: Int = 42\n}\n"
        let saveResult = try session.commands.run(ScriptSaveCommand.self, .init(path: newResult.path, content: modifiedCode, reload: false))
        #expect(saveResult.saved)

        // Verify written content
        let reloadedContent = try String(contentsOfFile: newResult.path, encoding: .utf8)
        #expect(reloadedContent == modifiedCode)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    @Test func scriptCommandsOnlyTouchProjectScripts() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptScope-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir

        // An engine-style source next to the project, plus a user script the project owns.
        let engineDir = tempDir.appendingPathComponent("Sources/Engine", isDirectory: true)
        try FileManager.default.createDirectory(at: engineDir, withIntermediateDirectories: true)
        let engineFile = engineDir.appendingPathComponent("Renderer.swift")
        try "struct Renderer {}".write(to: engineFile, atomically: true, encoding: .utf8)
        let userScript = try session.commands.run(ScriptNewCommand.self, .init(name: "camera-controller"))

        let listed = try session.commands.run(ScriptListCommand.self, NoArguments()).scripts
        #expect(listed.contains(where: { $0.hasSuffix("camera-controller.swift") }))
        #expect(!listed.contains(where: { $0.hasSuffix("Renderer.swift") }))
        #expect(throws: (any Error).self) {
            try session.commands.run(ScriptOpenCommand.self, .init(path: engineFile.path))
        }
        #expect(throws: (any Error).self) {
            try session.commands.run(ScriptSaveCommand.self, .init(path: engineFile.path, content: "// edited", reload: false))
        }
        #expect(try String(contentsOf: engineFile, encoding: .utf8) == "struct Renderer {}")
        #expect(throws: (any Error).self) {
            try session.commands.run(ScriptNewCommand.self, .init(name: "../Sources/Engine/Hack.swift"))
        }
        #expect(try session.commands.run(ScriptOpenCommand.self, .init(path: userScript.path)).content.contains("struct CameraController: Script"))
    }

    /// The Files panel lists scenes and scripts as folders; files.open opens a script in the
    /// Scripts editor and a scene in the Scene view.
    @MainActor
    @Test func filesListAndOpenScenesAndScripts() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FilesTest-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir
        let scenes = tempDir.appendingPathComponent("Assets/Scenes", isDirectory: true)
        try FileManager.default.createDirectory(at: scenes, withIntermediateDirectories: true)
        let saved = EditorDocument()
        _ = saved.world.spawn(Transform(), Name("Marker"))
        try saved.save(to: scenes.appendingPathComponent("Level.scene"))
        let script = try session.commands.run(ScriptNewCommand.self, .init(name: "CameraController"))
        var opened: [String] = []
        session.onOpenScript = { opened.append($0) }

        let listed = try session.commands.run(FilesListCommand.self, NoArguments()).files
        #expect(listed.map(\.path) == ["Assets/Scenes/Level.scene", "Scripts/CameraController.swift"])
        #expect(listed.map(\.kind) == [.scene, .script])

        let panel = FilesPanel(session: session)
        #expect(panel.tree.roots.map(\.title) == ["Assets", "Scripts"])
        panel.open(listed[1])
        #expect(opened.last.map { URL(fileURLWithPath: $0).standardizedFileURL.path } == URL(fileURLWithPath: script.path).standardizedFileURL.path)
        try session.commands.run(FilesOpenCommand.self, .init(path: "Assets/Scenes/Level.scene"))
        #expect(session.document.url?.lastPathComponent == "Level.scene")
        #expect(session.world.entities.contains { session.displayName(of: $0) == "Marker" })
        #expect(throws: (any Error).self) { try session.commands.run(FilesOpenCommand.self, .init(path: "README.md")) }
    }

    /// script.new turns the name into a type, registers it in the module's entry point once,
    /// refuses names that aren't types, existing files and duplicate type names.
    @MainActor
    @Test func scriptNewRegistersAndChecksNames() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptNew-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir
        let scripts = tempDir.appendingPathComponent("Scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
        let entry = scripts.appendingPathComponent("MyGame.swift")
        try """
            @_cdecl("acro_module_v1")
            public func registerMyGame(_ module: UnsafeMutableRawPointer) -> Int32 {
                GameModule.register(module) { game in
                    game.name = "MyGame"
                }
            }

            """.write(to: entry, atomically: true, encoding: .utf8)

        let result = try session.commands.run(ScriptNewCommand.self, .init(name: "camera controller"))
        #expect(result.typeName == "CameraController")
        #expect(result.registeredIn.map { URL(fileURLWithPath: $0).lastPathComponent } == "MyGame.swift")
        #expect(result.note == nil)
        let source = try String(contentsOf: URL(fileURLWithPath: result.path), encoding: .utf8)
        #expect(source.contains("public struct CameraController: Script"))
        #expect(try String(contentsOf: entry, encoding: .utf8).contains("""
                GameModule.register(module) { game in
                    game.script(CameraController.self)
                    game.name = "MyGame"
            """))

        // The same file again, a name that clashes with a declared type, and a non-type name.
        let again = #expect(throws: CommandError.self) { try session.commands.run(ScriptNewCommand.self, .init(name: "camera controller")) }
        #expect("\(again!)".contains("already exists"))
        let clash = #expect(throws: CommandError.self) { try session.commands.run(ScriptNewCommand.self, .init(name: "Camera_Controller")) }
        #expect("\(clash!)".contains("already declares"))
        let bad = #expect(throws: CommandError.self) { try session.commands.run(ScriptNewCommand.self, .init(name: "3D thing")) }
        #expect("\(bad!)".contains("Swift type name"))
        #expect(try String(contentsOf: entry, encoding: .utf8).components(separatedBy: ".script(").count == 2)
    }

    /// Without an entry point the script is still created, with a note saying what to add.
    @MainActor
    @Test func scriptNewWithoutEntryPointExplains() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptNewNoEntry-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir
        let result = try session.commands.run(ScriptNewCommand.self, .init(name: "Spinner"))
        #expect(result.created)
        #expect(result.registeredIn == nil)
        #expect(result.note?.contains("game.script(Spinner.self)") == true)
    }

    /// script.save says why it didn't reload instead of claiming it did.
    @MainActor
    @Test func scriptSaveExplainsSkippedReload() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptSaveNote-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir
        let script = try session.commands.run(ScriptNewCommand.self, .init(name: "Spinner"))
        let saved = try session.commands.run(ScriptSaveCommand.self, .init(path: script.path, content: "// x\n"))
        #expect(saved.saved)
        #expect(!saved.reloaded)
        #expect(saved.reloadNote?.contains("no game module") == true)
    }

    /// The panel's banner lists build errors, and Go to Error opens the file at the line.
    @MainActor
    @Test func scriptEditorPanelGoesToBuildError() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptGoTo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        session.startFolder = tempDir
        let script = try session.commands.run(ScriptNewCommand.self, .init(name: "Spinner"))
        let panel = ScriptEditorPanel(session: session)
        let diagnostic = GameBuildDiagnostic(file: script.path, line: 5, column: 9, message: "cannot find 'x' in scope")
        panel.showError("Build failed with 1 error", diagnostics: [diagnostic])
        panel.goToFirstError()
        #expect(panel.currentScriptURL?.lastPathComponent == "Spinner.swift")
        #expect(panel.editor.buffer.lineIndex(for: panel.editor.buffer.caret) == 4)
        #expect(panel.editor.buffer.columnIndex(for: panel.editor.buffer.caret) == 8)
        #expect(panel.shownDiagnostics == [diagnostic])
    }

    // MARK: - ScriptEditorPanel Tests

    @MainActor
    @Test func scriptEditorPanelLoadsAndEdits() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ScriptPanelTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        session.startFolder = tempDir

        // Create a dummy script in tempDir/Scripts/Enemy.swift
        let scriptsDir = tempDir.appendingPathComponent("Scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDir, withIntermediateDirectories: true)
        let fileURL = scriptsDir.appendingPathComponent("Enemy.swift")
        try "struct Enemy: Component {}".write(to: fileURL, atomically: true, encoding: .utf8)

        let files = FilesPanel(session: session)
        #expect(files.files.contains { $0.path == "Scripts/Enemy.swift" && $0.kind == .script })
        #expect(files.node(for: "Scripts")?.children.first?.title == "Enemy.swift")

        let panel = ScriptEditorPanel(session: session)
        panel.openScript(at: fileURL)
        #expect(panel.editor.text == "struct Enemy: Component {}")
        #expect(!panel.isDirty)

        // Simulate user typing code
        _ = panel.editor.handleEvent(.text(" // edited"))
        #expect(panel.isDirty)

        // Save
        panel.save()
        #expect(!panel.isDirty)

        let saved = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(saved == "struct Enemy: Component {} // edited")

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
}
