import Engine
import Foundation

// What every new project gets besides Project.json / Assets / Library (ProjectTemplate.create):
// its own Swift package, so game code can be written, built and hot-reloaded right away.
//
//   Package.swift                one library target, depending on the engine's package
//   Sources/<Target>/<Target>.swift   a game module: a component, a system, the entry point
//   .gitignore                   .build/, .swiftpm/, Build/ added
//   Project.json                 "game": {"target": "<Target>", "package": "."}
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
    public static func write(into project: inout Project, engine: URL? = findEngine(), sources: URL? = nil) throws -> Result {
        let fm = FileManager.default
        let root = project.root
        try addIgnores(in: root)
        if fm.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            return Result(target: nil, skipped: "the folder already has a Package.swift")
        }
        guard let engine else {
            return Result(target: nil, skipped: "the engine's package wasn't found (set \(engineEnvironmentKey) to its folder)")
        }
        let target = targetName(for: project.name, reserved: engineTargets(engine))
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
