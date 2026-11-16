import Engine
import EngineMCP
import Foundation

// What every new project gets besides Project.json / Assets / Library (ProjectTemplate.create):
// its own Swift package, so game code can be written, built and hot-reloaded right away.
//
//   Package.swift                one library target, depending on the engine's package
//   Sources/<Target>/<Target>.swift   a game module: a component, a system, the entry point
//   .gitignore                   .build/, .swiftpm/, Build/ added
//   Project.json                 "game": {"target": "<Target>", "package": "."}
//   .mcp.json                    an MCP client config (Claude Code reads it) that starts the
//                                editor on this project over stdio: the running editor's
//                                executable, else `swift run Editor` in the engine's package
//   CLAUDE.md                    how the project is laid out and how an agent should work in it
//
// The two agent files are written even when the package is skipped.
//
// The engine's package is found above the working directory or the editor's executable
// (`ACRO_ENGINE` overrides it); the manifest names its absolute path, which the
// `ACRO_ENGINE` environment variable overrides at build time too (another checkout, a CI
// machine). Without an engine to point at there is no package (a warning says why). Files that
// already exist are left alone, and a folder that already has a Package.swift keeps it.

public enum ProjectScaffold {
    /// The environment variable naming the engine's package folder.
    public static let engineEnvironmentKey = "ACRO_ENGINE"
    /// The variable's name from before the engine was called Acro; still read.
    public static let legacyEngineEnvironmentKey = "SWIFT_GAME_ENGINE"

    /// What `write` made.
    public struct Result: Sendable, Equatable {
        /// The game target, or nil when no package was written.
        public var target: String?
        /// Why there is no package, when there isn't.
        public var skipped: String?
    }

    /// The engine's package: `ACRO_ENGINE`, else at or above the working directory or the
    /// running executable's folder. Nil for an installed editor without the sources.
    public static func findEngine(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        if let path = environment[engineEnvironmentKey] ?? environment[legacyEngineEnvironmentKey], !path.isEmpty {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            return GameExporter.isEnginePackage(url) ? url : nil
        }
        let starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                      URL(fileURLWithPath: CommandLine.arguments.first ?? "").deletingLastPathComponent()]
        return starts.lazy.compactMap(GameExporter.enginePackage(above:)).first
    }

    /// A Swift target name from a project name ("My Game!" → "MyGame"), not one of `reserved`
    /// (the engine package's targets: SwiftPM wants names unique across the package graph).
    public static func targetName(for name: String, reserved: Set<String> = []) -> String {
        var word = ""
        var upperNext = true
        for scalar in name.unicodeScalars {
            guard scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) else { upperNext = true; continue }
            let character = String(scalar)
            word += upperNext ? character.uppercased() : character
            upperNext = false
        }
        if word.isEmpty || word.first!.isNumber { word = "Game" + word }
        while reserved.contains(word) { word += "Game" }
        return word
    }

    /// The engine package's target names (folders under Sources/ and Tests/).
    static func engineTargets(_ engine: URL) -> Set<String> {
        let fm = FileManager.default
        return Set(["Sources", "Tests"].flatMap {
            (try? fm.contentsOfDirectory(atPath: engine.appendingPathComponent($0).path)) ?? []
        })
    }

    /// Writes the package into `project` and points its `game` setting at it (saved). `sources`
    /// replaces the generated Swift file: the files of that folder are copied instead.
    @discardableResult
    public static func write(into project: inout Project, engine: URL? = findEngine(), sources: URL? = nil,
                             editor: URL? = runningEditor()) throws -> Result {
        let fm = FileManager.default
        let root = project.root
        try addIgnores(in: root)
        let hasPackage = fm.fileExists(atPath: root.appendingPathComponent("Package.swift").path)
        let target = engine.map { targetName(for: project.name, reserved: engineTargets($0)) }
        try writeAgentFiles(in: root, name: project.name, target: hasPackage ? project.settings.game?.target : target,
                            engine: engine, editor: editor)
        if hasPackage {
            return Result(target: nil, skipped: "the folder already has a Package.swift")
        }
        guard let engine, let target else {
            return Result(target: nil, skipped: "the engine's package wasn't found (set \(engineEnvironmentKey) to its folder)")
        }
        try writeIfMissing(manifest(target: target, engine: engine), to: root.appendingPathComponent("Package.swift"))
        let folder = root.appendingPathComponent("Sources/\(target)", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        if let sources {
            for name in try fm.contentsOfDirectory(atPath: sources.path) where name.hasSuffix(".swift") {
                let destination = folder.appendingPathComponent(name)
                if !fm.fileExists(atPath: destination.path) { try fm.copyItem(at: sources.appendingPathComponent(name), to: destination) }
            }
        } else {
            try writeIfMissing(gameSource(target: target, name: project.name), to: folder.appendingPathComponent("\(target).swift"))
        }
        project.settings.game = GameModuleSettings(target: target, package: ".")
        try project.saveSettings()
        return Result(target: target, skipped: nil)
    }

    /// Adds `.build/`, `.swiftpm/` and `Build/` to the project's .gitignore (created if missing).
    static func addIgnores(in root: URL) throws {
        let url = root.appendingPathComponent(".gitignore")
        var text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let lines = Set(text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        let missing = ["/.build/", "/.swiftpm/", "/Build/"].filter { !lines.contains($0) }
        guard !missing.isEmpty else { return }
        if !text.isEmpty && !text.hasSuffix("\n") { text += "\n" }
        text += "# SwiftPM build products, and Build Game's output.\n" + missing.joined(separator: "\n") + "\n"
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    // MARK: Agent files

    /// The running process's executable when it is the editor (named "…Editor"), for `.mcp.json`.
    public static func runningEditor() -> URL? {
        guard let url = Bundle.main.executableURL ?? CommandLine.arguments.first.map({ URL(fileURLWithPath: $0) })
        else { return nil }
        let name = url.deletingPathExtension().lastPathComponent.lowercased()
        return name.hasSuffix("editor") && FileManager.default.isExecutableFile(atPath: url.path) ? url.standardizedFileURL : nil
    }

    /// Writes `.mcp.json` and `CLAUDE.md` into `root` where they're missing.
    static func writeAgentFiles(in root: URL, name: String, target: String?, engine: URL?, editor: URL?) throws {
        if let config = mcpConfig(engine: engine, editor: editor) {
            try writeIfMissing(config, to: root.appendingPathComponent(".mcp.json"))
        }
        try writeIfMissing(claudeMarkdown(name: name, target: target, engine: engine), to: root.appendingPathComponent("CLAUDE.md"))
    }

    /// The project's `.mcp.json`: one stdio server that opens the editor on the project (the
    /// client starts it in the project folder). The editor executable when known, else
    /// `swift run` in the engine's package; nil without either.
    public static func mcpConfig(engine: URL?, editor: URL?) -> String? {
        let editorArguments: [JSON] = ["--mcp", "--project", "."]
        let server: JSON
        if let editor {
            server = ["type": "stdio", "command": .string(editor.path), "args": .array(editorArguments)]
        } else if let engine {
            let run: [JSON] = ["run", "--package-path", .string(engine.standardizedFileURL.path), "-c", "release", "Editor"]
            server = ["type": "stdio", "command": "swift", "args": .array(run + editorArguments)]
        } else {
            return nil
        }
        let config: JSON = ["mcpServers": .object([EditorMCP.serverName: server])]
        return config.prettyText + "\n"
    }

    /// The project's `CLAUDE.md`: what an agent needs to work in an Acro project.
    public static func claudeMarkdown(name: String, target: String?, engine: URL?) -> String {
        let docs = engine.map { $0.standardizedFileURL.appendingPathComponent("docs").path }
        let code = target.map { "`Sources/\($0)/`" } ?? "the game module's sources (see `\"game\"` in `Project.json`)"
        var text = """
            # \(name)

            An Acro game project. Acro is a Swift game engine with an editor; this folder is
            opened by the editor and its game code is a Swift package the editor builds and
            hot-reloads.

            ## Layout

            - `Project.json`: project settings (name, build scenes, the `"game"` module).
            - `Assets/`: the source of truth for scenes, models, textures, sounds and builder files.
              Each file has a `.meta` sidecar holding its asset id and import settings; keep the
              two together when moving or renaming (prefer the editor's `asset.*` tools).
            - `Library/`: the import cache, rebuilt from `Assets/`. Never edit it; it is gitignored.
            - \(code): game code (components, systems, the module entry point).
            - `Package.swift`: the game's package, depending on the engine.
            - `Build/`: output of Build Game; gitignored.

            ## Driving the editor (MCP)

            `.mcp.json` registers the `acro` MCP server, which starts the editor on this project
            over stdio. Its tools are the editor's commands: scenes and entities (`scene.*`,
            `entity.*`, `component.*`, `prefab.*`), assets (`asset.*`), play mode (`play.*`),
            screenshots (`view.screenshot`), game code (`game.reload`) and the builders below.

            - Prefer the MCP tools over hand-editing files under `Assets/`: they validate, keep
              sidecars and references intact, and record undo steps labeled "AI:".
            - Destructive tools need `confirm: true`.
            - After a change, check the result: read the tool's warnings, and take a
              `view.screenshot` for anything visual.

            ## Builders

            Content is authored as JSON files under `Assets/`, each with `<name>.new / .get / .set /
            .edit / .open` tools and an editor tab: `.meshbuild` (models from shapes, `meshBuild.*`),
            `.vfx` (particle effects), `.sfx` (synth sound effects), `.postfx` (camera looks),
            `.table` (typed data tables, read from game code by row id) and `.terrain` (heightmap
            terrain). Every key in these files is optional.

            ## Game code

            - Components are `Component` structs with a unique `componentName`; register them and
              systems in the module's entry point (`GameModule.register`).
            - Run `game.reload` (Reload Game Code) after editing Swift code: it rebuilds the module
              and reloads it with the scene kept. Build errors come back in the result and the log.
            - Don't change the module entry point's `@_cdecl` name.

            """
        if let docs {
            text += """

                ## Reference

                - Builders: `\(docs)/Builders.md`
                - Every MCP tool and its arguments: `\(docs)/MCPTools.md`

                """
        }
        return text
    }

    static func writeIfMissing(_ text: String, to url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    static func literal(_ string: String) -> String {
        "\"" + string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    /// The project's Package.swift.
    public static func manifest(target: String, engine: URL) -> String {
        """
        // swift-tools-version: 6.0
        // The game's code: a game module the editor builds and hot-reloads (Reload Game Code),
        // and Build Game links into the shipped app. Set \(engineEnvironmentKey) to build against
        // another checkout of the engine.
        import PackageDescription
        import Foundation

        let enginePath = ProcessInfo.processInfo.environment[\(literal(engineEnvironmentKey))] ?? \(literal(engine.standardizedFileURL.path))
        let engine = URL(fileURLWithPath: enginePath).lastPathComponent.lowercased()

        let package = Package(
            name: \(literal(target)),
            platforms: [.macOS(.v14)],
            dependencies: [.package(path: enginePath)],
            targets: [
                // A plain target, not a product: the editor links only its objects into the game
                // module, and the module uses the editor's own copy of Engine.
                .target(name: \(literal(target)), dependencies: [.product(name: "Engine", package: engine)]),
            ]
        )

        """
    }

    /// The starting game module.
    public static func gameSource(target: String, name: String) -> String {
        let prefix = target.lowercased()
        return """
            import Engine
            import Foundation

            // \(name)'s game code: a game module. The editor builds and loads it with the project
            // (Reload Game Code rebuilds it with the scene kept); its components show up in Add
            // Component and its systems run in play mode. Build Game links it into the app.

            /// Spins its entity around an axis while the game runs.
            public struct Spinner: Component, Equatable, Sendable {
                public static let componentName = "Spinner"
                public static var fieldHints: [String: FieldHints] {
                    ["speed": FieldHints(range: -20...20, step: 0.1, tooltip: "Radians per second")]
                }

                public var speed: Float = 1
                public var axis = Vec3(0, 1, 0)

                public init(speed: Float = 1) { self.speed = speed }
            }

            /// The module's entry point: registers the game's components and systems.
            @_cdecl("\(GameModuleABI.entryPoint)")
            public func register\(target)(_ module: UnsafeMutableRawPointer) -> Int32 {
                GameModule.register(module) { game in
                    game.name = \(literal(name))
                    game.component(Spinner.self, icon: "rotate-cw") { Spinner() }
                    game.system("\(prefix).spin") { world, _ in
                        let dt = world.time.delta
                        world.queryMutating(Transform.self, Spinner.self) { _, transform, spinner in
                            transform.rotation = Quat(angle: spinner.speed * dt, axis: spinner.axis) * transform.rotation
                        }
                    }
                }
            }

            """
    }
}
