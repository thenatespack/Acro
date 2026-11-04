import Foundation
import Testing
@testable import EditorCore
@testable import Engine

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
        #expect(openResult.content.contains("struct TestComponent: Component"))
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
        #expect(try session.commands.run(ScriptOpenCommand.self, .init(path: userScript.path)).content.contains("Component"))
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
