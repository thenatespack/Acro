import Foundation

// Exporting a game: the project's game module and Engine linked statically into one executable
// (release or debug, for the chosen architecture), its assets cooked into a pack (AssetCooker), laid out as something that runs on
// its own.
//
// ```
// macOS   <out>/<Name>.app/Contents/Info.plist
//                                  /MacOS/<Name>                       Engine + game module, one executable
//                                  /Resources/<Name>.pack              the cooked assets
//                                  /Resources/SwiftGameEngine_Engine.bundle   shaders, fonts
// Linux   <out>/<Name>/<Name>, <Name>.pack, SwiftGameEngine_Engine.bundle/ (or .resources/), lib/libglfw.so.3, run.sh
// ```
//
// **Static linking.** In the editor a game is a module loaded at run time (GameModule.swift):
// the host owns Engine and the module only its own objects. A shipped game needs neither the
// loader nor `-undefined dynamic_lookup`, so the exporter writes a small package next to the
// build products (`<game package>/.build/game-export/<Target>/`): it depends on the engine's
// package by path, compiles the game target's sources (a symlink to `Sources/<Target>`) as a
// target of its own, and has one executable whose `main.swift` calls the module's entry
// point directly (GamePlayer.swift). `swift build -c release` there links Engine, the game
// and the C libraries into one executable; nothing is loaded at run time, the linker can
// dead-strip, and there is no Engine/module mismatch to check. The package's `.build` stays,
// so the next export only recompiles what changed (the first one builds Engine in release).
// Limits: the game target may depend only on Engine (and must live in `Sources/<Target>`);
// it can't have resources of its own yet.

/// How the exported executable is compiled.
public enum BuildConfiguration: String, Codable, Sendable, CaseIterable {
    /// Optimized (`swift build -c release`): what to ship.
    case release
    /// Unoptimized with assertions and full debug info (`-c debug`): for debugging the shipped layout.
    case debug

    public var title: String { self == .release ? "Release" : "Debug" }
}

/// The CPU architecture the exported executable is built for.
public enum BuildArchitecture: String, Codable, Sendable, CaseIterable {
    case x86_64
    case arm64

    /// The architecture this program runs on.
    public static var current: BuildArchitecture {
        #if arch(x86_64)
        .x86_64
        #else
        .arm64
        #endif
    }

    /// What the menus show ("arm64 (Apple silicon)" on macOS, "aarch64" elsewhere).
    public func title(on platform: CookPlatform) -> String {
        switch (self, platform) {
        case (.x86_64, .macos): "x86_64 (Intel)"
        case (.x86_64, _): "x86_64"
        case (.arm64, .macos): "arm64 (Apple silicon)"
        case (.arm64, _): "aarch64 (arm64)"
        }
    }

    /// Whether this machine can build `platform` executables for this architecture: any on macOS
    /// (`swift build --arch`), only the machine's own architecture elsewhere (the C libraries the
    /// engine links are the system's, for one architecture).
    public func canBuild(for platform: CookPlatform) -> Bool {
        guard platform == .current else { return false }
        return platform == .macos || self == .current
    }
}

/// What `GameExporter` needs.
public struct GameExportOptions: Equatable, Sendable, Codable {
    /// The app's name (executable, bundle and pack).
    public var name: String
    /// The game's SwiftPM target.
    public var gameTarget: String
    /// The package holding it.
    public var gamePackage: URL
    /// The engine's package (with the `Engine` library product).
    public var enginePackage: URL
    /// The folder the app (macOS) or the game folder (Linux) goes in.
    public var output: URL
    public var cook: CookOptions
    /// No game code: `gameTarget` is a generated module with just the entry point (the scenes
    /// play with the engine's built-in systems), written into `gamePackage` (the project's
    /// `Library/GameExport`) instead of linked from a package.
    public var sceneOnly: Bool
    public var configuration: BuildConfiguration
    public var architecture: BuildArchitecture
    /// Build a Linux game in a Docker container (GameExporterDocker.swift): from any host, for
    /// either architecture (the other one emulated, slowly).
    public var useDocker: Bool

    public init(name: String, gameTarget: String, gamePackage: URL, enginePackage: URL, output: URL, cook: CookOptions,
                sceneOnly: Bool = false, configuration: BuildConfiguration = .release, architecture: BuildArchitecture = .current,
                useDocker: Bool = false) {
        self.sceneOnly = sceneOnly
        self.useDocker = useDocker
        self.configuration = configuration
        self.architecture = architecture
        self.name = name
        self.gameTarget = gameTarget
        self.gamePackage = gamePackage
        self.enginePackage = enginePackage
        self.output = output
        self.cook = cook
    }
}

/// What an export produced.
public struct GameExportReport: Codable, Equatable, Sendable {
    /// The app bundle (macOS) or game folder (Linux): what to ship.
    public var outputPath: String
    public var executablePath: String
    public var packPath: String
    public var cook: CookReport
    public var buildSeconds: Double
    public var totalSeconds: Double
    public var executableBytes: Int
    public var totalBytes: Int
    /// How the game code is linked ("static": one executable).
    public var linking: String

    public var summary: String {
        let mb = { (bytes: Int) in String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        return "Exported \(outputPath) (\(mb(totalBytes)): executable \(mb(executableBytes)), pack \(mb(cook.packBytes))); "
            + String(format: "cook %.2f s, build %.1f s, total %.1f s", cook.seconds, buildSeconds, totalSeconds)
    }
}

public enum GameExportError: Error, Equatable, CustomStringConvertible {
    case noGame
    case noEnginePackage(String)
    case wrongPlatform(CookPlatform)
    case wrongArchitecture(BuildArchitecture)
    case docker(String)
    case missingSources(String)
    case buildFailed(String)
    case missingProduct(String)

    public var description: String {
        switch self {
        case .noGame: "The project has no game code to export: set \"game\": {\"target\": …} in Project.json (or load one with --game)"
        case .noEnginePackage(let from): "Couldn't find the engine's package from \(from): set \"build\": {\"enginePackage\": …} in Project.json (Settings › Project)"
        case .wrongPlatform(let platform): "This machine can't build a \(platform.rawValue) executable (cross-compiling isn't supported); cook the pack alone with --cook"
        case .wrongArchitecture(let arch): "This machine can't build a \(CookPlatform.current.rawValue) \(arch.rawValue) executable (only \(BuildArchitecture.current.rawValue): the engine's C libraries are the system's)"
        case .docker(let reason): reason
        case .missingSources(let path): "The game target's sources aren't at \(path) (exporting needs Sources/<Target>)"
        case .buildFailed(let output): "Building the player failed:\n\(output)"
        case .missingProduct(let path): "The build finished but \(path) is missing"
        }
    }
}

/// Exports a game (see the notes above). `prepare` on the main actor, `run` on any thread.
public struct GameExporter: Sendable {
    public let options: GameExportOptions
    let cookPlan: CookPlan

    /// Prepares an export from a scanned database (the cook plan is taken now).
    @MainActor
    public static func prepare(database: AssetDatabase, options: GameExportOptions) throws -> GameExporter {
        let platform = options.cook.target.platform
        if options.useDocker {
            if let reason = unbuildableReason(platform: platform, architecture: options.architecture, useDocker: true) {
                throw GameExportError.docker(reason)
            }
        } else {
            guard platform == .current else { throw GameExportError.wrongPlatform(platform) }
            guard options.architecture.canBuild(for: .current) else { throw GameExportError.wrongArchitecture(options.architecture) }
        }
        return GameExporter(options: options, cookPlan: try AssetCooker.plan(database: database, options: options.cook))
    }

    /// Why this machine can't build a game for `platform` / `architecture` (in Docker with
    /// `useDocker`), or nil when it can.
    public static func unbuildableReason(platform: CookPlatform, architecture: BuildArchitecture, useDocker: Bool) -> String? {
        if useDocker {
            guard platform == .linux else { return "Docker builds Linux games only" }
            guard dockerExecutable != nil else {
                return "Docker isn't installed (no docker in PATH, ~/.docker/bin, /usr/local/bin or /opt/homebrew/bin)"
            }
            return nil
        }
        if platform != .current {
            let docker = platform == .linux ? " (or build in Docker)" : ""
            return "\(platform.title) games are built on \(platform.title)\(docker); this is \(CookPlatform.current.title)"
        }
        if !architecture.canBuild(for: platform) {
            let docker = platform == .linux ? " (or build in Docker)" : ""
            return "This \(platform.title) machine builds \(BuildArchitecture.current.rawValue) only\(docker): the engine links the system's C libraries"
        }
        return nil
    }

    /// Export options for `project` from its settings (`"game"`, `"build"`), with overrides.
    /// `game` replaces the project's game setting (the editor's `--game`), its package relative
    /// to `gameBase` (default: the project folder).
    @MainActor
    public static func options(for project: Project, game: GameModuleSettings? = nil, gameBase: URL? = nil, scenes: [String]? = nil,
                               output: URL? = nil, target: CookTarget? = nil, configuration: BuildConfiguration = .release,
                               architecture: BuildArchitecture = .current) throws -> GameExportOptions {
        let build = project.settings.build ?? GameBuildSettings()
        guard let settings = game ?? project.settings.game, let gameTarget = settings.target else {
            let options = try sceneOnlyOptions(for: project, build: build, scenes: scenes, output: output, target: target,
                                               configuration: configuration, architecture: architecture)
            return options
        }
        let base = game != nil ? (gameBase ?? project.root) : project.root
        let gamePackage: URL
        if let package = settings.package {
            gamePackage = URL(fileURLWithPath: package, relativeTo: base).standardizedFileURL
        } else {
            guard let found = GameModuleBuilder.findPackage(from: base) else { throw GameExportError.noEnginePackage(base.path) }
            gamePackage = found
        }
        let engine: URL
        if let path = build.enginePackage {
            engine = URL(fileURLWithPath: path, relativeTo: project.root).standardizedFileURL
        } else {
            guard let found = findEnginePackage(from: gamePackage) else { throw GameExportError.noEnginePackage(gamePackage.path) }
            engine = found
        }
        let out = output ?? defaultOutput(for: project, build: build, platform: target?.platform ?? .current,
                                                      configuration: configuration, architecture: architecture)
        var cook = CookOptions(scenes: scenes ?? build.scenes ?? [], include: build.include ?? [],
                               target: target ?? CookTarget(platform: .current, textureFamily: build.textureFamily),
                               textures: build.textures ?? .compress, writesManifest: false)
        let name = build.name ?? project.name
        cook.packName = name
        cook.runtime = project.settings.runtime
        return GameExportOptions(name: name, gameTarget: gameTarget, gamePackage: gamePackage, enginePackage: engine, output: out, cook: cook,
                                 configuration: configuration, architecture: architecture)
    }

    /// Export options for a project without game code: a generated module plays its scenes.
    /// The engine's package is `build.enginePackage`, else found above `engineSearchStarts`
    /// (default: the working directory and the running executable's folder, which finds the
    /// engine an editor built from source runs from).
    @MainActor
    static func sceneOnlyOptions(for project: Project, build: GameBuildSettings, scenes: [String]?, output: URL?, target: CookTarget?,
                                 configuration: BuildConfiguration = .release, architecture: BuildArchitecture = .current,
                                 engineSearchStarts: [URL]? = nil) throws -> GameExportOptions {
        let engine: URL
        if let path = build.enginePackage {
            engine = URL(fileURLWithPath: path, relativeTo: project.root).standardizedFileURL
        } else {
            let starts = engineSearchStarts ?? [URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                                                 URL(fileURLWithPath: CommandLine.arguments.first ?? "").deletingLastPathComponent()]
            guard let found = starts.lazy.compactMap(Self.enginePackage(above:)).first else {
                throw GameExportError.noEnginePackage(starts.map(\.path).joined(separator: " or "))
            }
            engine = found
        }
        let out = output ?? defaultOutput(for: project, build: build, platform: target?.platform ?? .current,
                                                      configuration: configuration, architecture: architecture)
        let name = build.name ?? project.name
        var cook = CookOptions(scenes: scenes ?? build.scenes ?? [], include: build.include ?? [],
                               target: target ?? CookTarget(platform: .current, textureFamily: build.textureFamily),
                               textures: build.textures ?? .compress, writesManifest: false)
        cook.packName = name
        cook.runtime = project.settings.runtime
        return GameExportOptions(name: name, gameTarget: moduleName(for: name),
                                 gamePackage: project.libraryURL.appendingPathComponent("GameExport", isDirectory: true),
                                 enginePackage: engine, output: out, cook: cook, sceneOnly: true,
                                 configuration: configuration, architecture: architecture)
    }

    /// `<build.output or Build>/<platform>-<arch>[-debug]` (`outputFolderName`): where an export goes by default.
    @MainActor
    public static func defaultOutput(for project: Project, build: GameBuildSettings? = nil, platform: CookPlatform = .current,
                                     configuration: BuildConfiguration = .release, architecture: BuildArchitecture = .current) -> URL {
        let build = build ?? project.settings.build ?? GameBuildSettings()
        return URL(fileURLWithPath: build.output ?? "Build", relativeTo: project.root).standardizedFileURL
            .appendingPathComponent(outputFolderName(platform: platform, architecture: architecture, configuration: configuration),
                                    isDirectory: true)
    }

    /// The output folder's name for an export: "macos-arm64", "linux-x86_64-debug".
    public static func outputFolderName(platform: CookPlatform, architecture: BuildArchitecture, configuration: BuildConfiguration) -> String {
        "\(platform.rawValue)-\(architecture.rawValue)" + (configuration == .debug ? "-debug" : "")
    }

    /// The engine's package at or above `start` (8 levels at most).
    public static func enginePackage(above start: URL) -> URL? {
        var folder = start.standardizedFileURL
        for _ in 0..<8 {
            if isEngine(folder) { return folder }
            guard folder.pathComponents.count > 1 else { return nil }
            folder.deleteLastPathComponent()
        }
        return nil
    }

    static func isEngine(_ url: URL) -> Bool { isEnginePackage(url) }

    /// Whether `url` is the engine's package folder.
    public static func isEnginePackage(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appendingPathComponent("Sources/Engine/GameModule/GameModule.swift").path)
    }

    /// A Swift module name from an app name ("Cyber Funk!" → "CyberFunkScenes").
    static func moduleName(for name: String) -> String {
        var word = String(name.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) && $0.isASCII }.map(Character.init))
        if word.isEmpty || word.first!.isNumber { word = "Game" + word }
        return word + "Scenes"
    }

    /// The engine's package: `gamePackage` itself when it holds Engine, else one of its
    /// resolved dependencies (`swift package show-dependencies`).
    public static func findEnginePackage(from gamePackage: URL) -> URL? {
        if isEngine(gamePackage) { return gamePackage }
        let result = GameModuleBuilder.run(["swift", "package", "show-dependencies", "--format", "json"], in: gamePackage)
        guard result.succeeded, let start = result.output.firstIndex(of: "{"),
              let json = try? JSONSerialization.jsonObject(with: Data(result.output[start...].utf8)) else { return nil }
        var stack: [Any] = [json]
        while let node = stack.popLast() {
            guard let object = node as? [String: Any] else { continue }
            if let path = object["path"] as? String, isEngine(URL(fileURLWithPath: path)) { return URL(fileURLWithPath: path) }
            stack += (object["dependencies"] as? [Any]) ?? []
        }
        return nil
    }

    /// Where the generated player package lives.
    /// (A Docker build gets its own, so its products never mix with the host's.)
    public var playerPackage: URL {
        let suffix = options.useDocker ? "-docker" : ""
        return options.sceneOnly
            ? options.gamePackage.appendingPathComponent(options.gameTarget + suffix, isDirectory: true)
            : options.gamePackage.appendingPathComponent(".build/game-export\(suffix)/\(options.gameTarget)", isDirectory: true)
    }

    /// The executable target of the generated package.
    var playerTarget: String { "\(options.gameTarget)Player" }

    /// The app bundle (macOS) or folder (elsewhere) the export produces.
    public var outputURL: URL {
        options.cook.target.platform == .macos ? options.output.appendingPathComponent("\(options.name).app", isDirectory: true)
            : options.output.appendingPathComponent(options.name, isDirectory: true)
    }

    /// Writes the generated player package (only files whose contents changed, so builds stay incremental).
    public func writePlayerPackage() throws {
        let fm = FileManager.default
        let root = playerPackage
        try fm.createDirectory(at: root.appendingPathComponent("Sources/Player"), withIntermediateDirectories: true)
        let link = root.appendingPathComponent("Sources/\(options.gameTarget)")
        if options.sceneOnly {
            // No game code: a module with just the entry point, so the scenes play with the built-in systems.
            if (try? fm.destinationOfSymbolicLink(atPath: link.path)) != nil { try? fm.removeItem(at: link) }
            try fm.createDirectory(at: link, withIntermediateDirectories: true)
            let stub = """
                // Generated by GameExporter for a project without game code; rewritten on every export.
                import Engine

                @_cdecl("\(GameModuleABI.entryPoint)")
                public func registerSceneOnlyGame(_ module: UnsafeMutableRawPointer) -> Int32 {
                    GameModule.register(module) { game in
                        game.name = \(Self.literal(options.name))
                    }
                }

                """
            try Self.writeIfChanged(stub, to: link.appendingPathComponent("Game.swift"))
        } else {
            let sources = options.gamePackage.appendingPathComponent("Sources/\(options.gameTarget)", isDirectory: true)
            guard fm.fileExists(atPath: sources.path) else { throw GameExportError.missingSources(sources.path) }
            if (try? fm.destinationOfSymbolicLink(atPath: link.path)) != sources.path {
                try? fm.removeItem(at: link)
                try fm.createSymbolicLink(at: link, withDestinationURL: sources)
            }
        }
        let engine = options.enginePackage.standardizedFileURL
        let identity = engine.lastPathComponent.lowercased()
        let manifest = """
            // swift-tools-version: 6.0
            // Generated by GameExporter (Sources/Engine/Packaging/GameExporter.swift); rewritten on every export.
            // Links \(options.gameTarget) and Engine statically into one executable.
            import PackageDescription

            let package = Package(
                name: "\(options.gameTarget)Export",
                platforms: [.macOS(.v14)],
                dependencies: [.package(path: \(Self.literal(engine.path)))],
                targets: [
                    .target(name: \(Self.literal(options.gameTarget)), dependencies: [.product(name: "Engine", package: \(Self.literal(identity)))],
                            path: \(Self.literal("Sources/\(options.gameTarget)"))),
                    .executableTarget(name: \(Self.literal(playerTarget)),
                                      dependencies: [\(Self.literal(options.gameTarget)), .product(name: "Engine", package: \(Self.literal(identity)))],
                                      path: "Sources/Player",
                                      // Linux: shared libraries the export bundles (GLFW) are looked up in lib/ next to the executable.
                                      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$ORIGIN/lib"], .when(platforms: [.linux]))]),
                ]
            )

            """
        let main = """
            // Generated by GameExporter. The game module's entry point, linked in statically (see GamePlayer.swift).
            import Engine

            @_silgen_name("\(GameModuleABI.entryPoint)")
            func gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32

            MainActor.assumeIsolated {
                GamePlayer.main(module: gameModuleEntry)
            }

            """
        try Self.writeIfChanged(manifest, to: root.appendingPathComponent("Package.swift"))
        try Self.writeIfChanged(main, to: root.appendingPathComponent("Sources/Player/main.swift"))
    }

    /// The build command for the player.
    public var buildCommand: [String] {
        ["swift", "build"] + buildFlags + ["--product", playerTarget]
    }

    /// `NAME=value` settings for the build (`/usr/bin/env` takes them before the command): a
    /// macOS export builds without the Vulkan backend (Metal only, what macOS uses anyway). With
    /// the Vulkan SDK installed it would otherwise link Homebrew's Vulkan loader and GLFW
    /// (`/opt/homebrew/...dylib`), which players' Macs don't have, and which exist for this
    /// machine's architecture only.
    var buildEnvironment: [String] {
        options.cook.target.platform == .macos ? ["ENGINE_DISABLE_VULKAN=1"] : []
    }

    /// The flags that pick the build's products folder (shared by `buildCommand` and `--show-bin-path`).
    var buildFlags: [String] {
        var flags = ["-c", options.configuration.rawValue]
        switch options.cook.target.platform {
        case .macos:
            // Always explicit, so an x86_64 export doesn't reuse (or overwrite) the native products.
            flags += ["--arch", options.architecture.rawValue]
        case .linux:
            flags.append("--static-swift-stdlib")
        case .windows:
            break
        }
        return flags
    }

    /// Cooks, builds and lays out the game. Blocks for seconds (minutes the first time, when
    /// Engine is built in release); run it off the main thread.
    public func run(progress: (@Sendable (String) -> Void)? = nil) throws -> GameExportReport {
        let start = Date()
        let fm = FileManager.default
        let app = outputURL
        let staging = options.output.appendingPathComponent(".\(options.name)-export", isDirectory: true)
        try? fm.removeItem(at: staging)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }

        // 1. Cook (fast, and fails early on asset problems).
        progress?("Cooking \(options.cook.scenes.joined(separator: ", ")) for \(options.cook.target.platform.rawValue) (\(options.cook.target.textureFamily.rawValue) textures)")
        let cook = try cookPlan.run(to: staging)
        progress?("Cooked: \(cook.summary)")
        for warning in cook.warnings { progress?("Warning: \(warning)") }

        // 2. Build the player.
        try writePlayerPackage()
        let built = options.useDocker ? try buildInDocker(staging: staging, progress: progress) : try buildNatively(progress: progress)

        // 3. Lay it out.
        progress?("Writing \(app.path)")
        try? fm.removeItem(at: app)
        let resources: URL
        let executableURL: URL
        if options.cook.target.platform == .macos {
            let contents = app.appendingPathComponent("Contents", isDirectory: true)
            resources = contents.appendingPathComponent("Resources", isDirectory: true)
            executableURL = contents.appendingPathComponent("MacOS/\(options.name)")
            try fm.createDirectory(at: executableURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fm.createDirectory(at: resources, withIntermediateDirectories: true)
            try Data(infoPlist.utf8).write(to: contents.appendingPathComponent("Info.plist"))
        } else {
            resources = app
            executableURL = app.appendingPathComponent(options.name)
            try fm.createDirectory(at: app, withIntermediateDirectories: true)
        }
        try fm.copyItem(at: built.executable, to: executableURL)
        for bundle in built.bundles { try fm.copyItem(at: bundle, to: resources.appendingPathComponent(bundle.lastPathComponent)) }
        let pack = resources.appendingPathComponent("\(options.name).pack")
        try fm.moveItem(at: URL(fileURLWithPath: cook.packPath), to: pack)
        if options.cook.target.platform == .macos {
            // Ad-hoc signature over the whole bundle (the linker signed only the executable).
            _ = GameModuleBuilder.run(["codesign", "--force", "--sign", "-", app.path], in: options.output)
        } else {
            if let libraries = built.libraries {
                // Built in Docker: stripped and its libraries collected in the container.
                for library in ((try? fm.contentsOfDirectory(atPath: libraries.path)) ?? []).sorted() {
                    let lib = app.appendingPathComponent("lib", isDirectory: true)
                    try fm.createDirectory(at: lib, withIntermediateDirectories: true)
                    try fm.copyItem(at: libraries.appendingPathComponent(library), to: lib.appendingPathComponent(library))
                    progress?("Bundled \(library)")
                }
            } else {
                // Debug info only: the symbols stay, so crash reports still have function names (about a quarter smaller).
                // A debug export keeps it, for the debugger.
                if options.configuration == .release, GameModuleBuilder.run(["strip", "-g", executableURL.path], in: options.output).succeeded {
                    progress?("Stripped debug info from \(options.name)")
                }
                for library in try bundleSharedLibraries(of: executableURL, into: app.appendingPathComponent("lib", isDirectory: true)) {
                    progress?("Bundled \(library)")
                }
            }
            let script = app.appendingPathComponent("run.sh")
            try Data(launcher.utf8).write(to: script)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        }

        var report = GameExportReport(outputPath: app.path, executablePath: executableURL.path, packPath: pack.path, cook: cook,
                                      buildSeconds: built.seconds, totalSeconds: 0, executableBytes: Self.size(of: executableURL),
                                      totalBytes: Self.size(of: app), linking: "static")
        report.cook.packPath = pack.path
        report.totalSeconds = Date().timeIntervalSince(start)
        progress?(report.summary)
        return report
    }

    /// A built player: the executable, its resource bundles and (Docker) the libraries to bundle.
    struct BuiltPlayer {
        var executable: URL
        var bundles: [URL]
        /// A folder with the shared libraries for `lib/`, already collected (nil: collect them with `ldd`).
        var libraries: URL?
        var seconds: Double
    }

    /// Builds the player with this machine's toolchain.
    func buildNatively(progress: (@Sendable (String) -> Void)?) throws -> BuiltPlayer {
        progress?("Building \(options.gameTarget) with Engine (\(options.configuration.rawValue), \(options.architecture.rawValue)) "
                  + "(in \(playerPackage.path): \(buildCommand.joined(separator: " ")))")
        let build = GameModuleBuilder.run(buildEnvironment + buildCommand, in: playerPackage)
        guard build.succeeded else { throw GameExportError.buildFailed(build.output) }
        progress?(String(format: "Built in %.1f s", build.seconds))
        let binPath = GameModuleBuilder.run(buildEnvironment + ["swift", "build"] + buildFlags + ["--show-bin-path"], in: playerPackage)
        let shown = binPath.output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.last { $0.hasPrefix("/") }
        let shownBin = binPath.succeeded ? shown.map { URL(fileURLWithPath: $0, isDirectory: true) } : nil
        let bin = (shownBin ?? playerPackage.appendingPathComponent(".build/\(options.configuration.rawValue)", isDirectory: true))
            .resolvingSymlinksInPath()
        let executable = bin.appendingPathComponent(playerTarget)
        guard FileManager.default.fileExists(atPath: executable.path) else { throw GameExportError.missingProduct(executable.path) }
        let bundles = ((try? FileManager.default.contentsOfDirectory(atPath: bin.path)) ?? [])
            .filter { $0.hasSuffix(".bundle") || $0.hasSuffix(".resources") }.sorted().map { bin.appendingPathComponent($0) }
        return BuiltPlayer(executable: executable, bundles: bundles, libraries: nil, seconds: build.seconds)
    }

    /// Shared libraries a Linux export carries in `lib/` (found through the executable's rpath,
    /// `$ORIGIN/lib`) because desktop distributions don't install them by default. The Vulkan
    /// loader, libX11 and zlib are left to the system: they come with any desktop that has GPU
    /// drivers, and the Vulkan loader has to match the installed drivers.
    static let bundledLibraryPrefixes = ["libglfw.so"]

    /// Copies the `bundledLibraryPrefixes` libraries `executable` links (per `ldd`) into `folder`;
    /// returns their names. Nothing when `ldd` isn't available.
    func bundleSharedLibraries(of executable: URL, into folder: URL) throws -> [String] {
        let ldd = GameModuleBuilder.run(["ldd", executable.path], in: options.output)
        guard ldd.succeeded else { return [] }
        var copied: [String] = []
        for (name, path) in Self.sharedLibraries(inLDDOutput: ldd.output)
        where Self.bundledLibraryPrefixes.contains(where: { name.hasPrefix($0) }) {
            let fm = FileManager.default
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            // Under the soname the executable asks for, with the real file's contents (not a symlink).
            try fm.copyItem(at: URL(fileURLWithPath: path).resolvingSymlinksInPath(), to: folder.appendingPathComponent(name))
            copied.append(name)
        }
        return copied
    }

    /// `soname => /path` pairs from `ldd`'s output (libraries it found).
    static func sharedLibraries(inLDDOutput output: String) -> [(name: String, path: String)] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 3, parts[1] == "=>", parts[2].hasPrefix("/") else { return nil }
            return (String(parts[0]), String(parts[2]))
        }
    }

    var infoPlist: String {
        let identifier = "local.swiftgameengine." + options.name.filter { $0.isLetter || $0.isNumber }.lowercased()
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            \t<key>CFBundleDevelopmentRegion</key>
            \t<string>en</string>
            \t<key>CFBundleExecutable</key>
            \t<string>\(Self.xml(options.name))</string>
            \t<key>CFBundleIdentifier</key>
            \t<string>\(identifier)</string>
            \t<key>CFBundleInfoDictionaryVersion</key>
            \t<string>6.0</string>
            \t<key>CFBundleName</key>
            \t<string>\(Self.xml(options.name))</string>
            \t<key>CFBundlePackageType</key>
            \t<string>APPL</string>
            \t<key>CFBundleShortVersionString</key>
            \t<string>1.0</string>
            \t<key>CFBundleVersion</key>
            \t<string>1</string>
            \t<key>LSMinimumSystemVersion</key>
            \t<string>14.0</string>
            \t<key>NSHighResolutionCapable</key>
            \t<true/>
            </dict>
            </plist>

            """
    }

    var launcher: String {
        """
        #!/bin/sh
        # Runs \(options.name) with its pack (generated by GameExporter).
        here="$(cd "$(dirname "$0")" && pwd)"
        exec "$here/\(options.name)" --pack "$here/\(options.name).pack" "$@"

        """
    }

    static func literal(_ string: String) -> String {
        "\"" + string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    static func xml(_ string: String) -> String {
        string.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }

    static func writeIfChanged(_ text: String, to url: URL) throws {
        let data = Data(text.utf8)
        if FileManager.default.contents(atPath: url.path) == data { return }
        try data.write(to: url, options: .atomic)
    }

    /// Bytes of a file, or of everything in a folder.
    static func size(of url: URL) -> Int {
        let fm = FileManager.default
        var isFolder: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isFolder) else { return 0 }
        guard isFolder.boolValue else { return (try? fm.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0 }
        guard let files = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else { return 0 }
        var total = 0
        for case let file as URL in files {
            if (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                total += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            }
        }
        return total
    }
}

/// `Project.json`'s `"build"` object: defaults for Build Game (`game.build`) and `--cook`.
///
/// ```json
/// "build": {"scenes": ["Scenes/Main.scene"], "include": ["Audio/theme.ogg"], "name": "My Game",
///           "output": "Build", "textureFamily": "astc", "textures": "compress", "enginePackage": "../engine"}
/// ```
public struct GameBuildSettings: Equatable, Sendable, Codable {
    /// Scenes to cook, the start scene first (paths relative to the project folder or `Assets/`).
    public var scenes: [String]?
    /// More assets to cook: ones only code refers to (paths relative to `Assets/`, or ids).
    public var include: [String]?
    /// The app's name; default: the project's.
    public var name: String?
    /// The output folder, relative to the project folder (default `Build`); a folder per platform goes inside.
    public var output: String?
    /// Default: ASTC on macOS, BC elsewhere.
    public var textureFamily: TextureFamily?
    public var textures: TextureCookMode?
    /// The engine's package, when it can't be found from the game's package.
    public var enginePackage: String?

    public init(scenes: [String]? = nil, include: [String]? = nil, name: String? = nil, output: String? = nil,
                textureFamily: TextureFamily? = nil, textures: TextureCookMode? = nil, enginePackage: String? = nil) {
        self.scenes = scenes
        self.include = include
        self.name = name
        self.output = output
        self.textureFamily = textureFamily
        self.textures = textures
        self.enginePackage = enginePackage
    }
}
