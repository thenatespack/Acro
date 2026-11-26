import Foundation
import EngineAssets
import EngineAudio
import EngineBackends
import EngineCore
import EngineGraphics
import EngineNet
import EnginePhysics
import EngineRendering
import EngineScene
import EngineText
import EngineUI

// Exporting a game: the project's game module and Engine linked statically into one executable
// (release or debug, for the chosen architecture), its assets cooked into a pack (AssetCooker), laid out as something that runs on
// its own.
//
// ```
// macOS   <out>/<Name>.app/Contents/Info.plist
//                                  /MacOS/<Name>                       Engine + game module, one executable
//                                  /Resources/<Name>.pack              the cooked assets
//                                  /Resources/Acro_EngineCore.bundle   shaders, fonts
// Linux   <out>/<Name>/<Name>, <Name>.pack, Acro_EngineCore.bundle/ (or .resources/), lib/libglfw.so.3, run.sh
// Windows <out>/<Name>/<Name>.exe, <Name>.pack, Acro_EngineCore.resources/, Engine.dll, the Swift runtime and zlib DLLs
// Web     <out>/<Name>/index.html, loader.js, app/, vendor/, engine/, game.pack, player.json, README.txt
//         (a static site: GameExporterWeb.swift)
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
    /// Web: the renderer the page starts with (`renderer` in player.json). nil is `.auto`: WebGPU
    /// where the browser has it, else WebGL 2. Players can still switch (Web/loader.js).
    public var webRenderer: WebRenderer?

    /// The cook target's platform: what the export builds.
    public var platform: CookPlatform { cook.target.platform }

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
    /// Web: the `.wasm` compressed with gzip -9 and brotli (what a server sends with compression on), when those tools exist.
    public var wasmGzipBytes: Int?
    public var wasmBrotliBytes: Int?

    public var summary: String {
        let mb = { (bytes: Int) in String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        var compressed = ""
        if wasmGzipBytes != nil || wasmBrotliBytes != nil {
            compressed = " (" + [wasmGzipBytes.map { "\(mb($0)) gzip" }, wasmBrotliBytes.map { "\(mb($0)) brotli" }]
                .compactMap { $0 }.joined(separator: ", ") + ")"
        }
        return "Exported \(outputPath) (\(mb(totalBytes)): executable \(mb(executableBytes))\(compressed), pack \(mb(cook.packBytes))); "
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
    /// Web: the Wasm toolchain or SDK isn't installed, or a tool the web export needs is missing.
    case webToolchain(String)

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
        case .webToolchain(let reason): reason
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
        } else if platform == .web {
            if let reason = WebToolchain.find().problem { throw GameExportError.webToolchain(reason) }
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
        if platform == .web {
            // WebAssembly: one target for every machine (the architecture doesn't apply).
            return WebToolchain.find().problem
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

    /// The output folder's name for an export: "macos-arm64", "linux-x86_64-debug", "web" (no architecture).
    public static func outputFolderName(platform: CookPlatform, architecture: BuildArchitecture, configuration: BuildConfiguration) -> String {
        (platform == .web ? "web" : "\(platform.rawValue)-\(architecture.rawValue)") + (configuration == .debug ? "-debug" : "")
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
    /// (A Docker or Web build gets its own, so its products never mix with the host's.)
    public var playerPackage: URL {
        let suffix = options.useDocker ? "-docker" : options.platform == .web ? "-web" : ""
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
    /// Whether game sources import full Foundation outside a `#if os(WASI)` / `#else` block:
    /// such code needs Foundation linked on the web (see `writePlayerPackage`).
    package static func importsFullFoundation(sourcesIn directory: URL) -> Bool {
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return false }
        for case let file as URL in files where file.pathExtension == "swift" {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            var previous = ""
            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                let code = line.trimmingCharacters(in: .whitespaces)
                if code.isEmpty || code.hasPrefix("//") { continue }
                // `import Foundation`, `@preconcurrency import Foundation`, `import struct Foundation.Date`, ...
                let words = code.split(separator: " ").filter { !$0.hasPrefix("@") }
                if words.first == "import", let module = words.last?.split(separator: ".").first, module == "Foundation",
                   previous != "#else" {
                    return true
                }
                previous = code
            }
        }
        return false
    }

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
        // Game code from before the rename may still export the legacy entry point's name.
        var entryPoint = GameModuleABI.entryPoint
        if !options.sceneOnly, let files = fm.enumerator(at: link.resolvingSymlinksInPath(), includingPropertiesForKeys: nil) {
            let legacy = "@_cdecl(\"\(GameModuleABI.legacyEntryPoint)\")"
            for case let file as URL in files where file.pathExtension == "swift" {
                if let text = try? String(contentsOf: file, encoding: .utf8), text.contains(legacy) {
                    entryPoint = GameModuleABI.legacyEntryPoint
                    break
                }
            }
        }
        let gameUsesFoundation = !options.sceneOnly && Self.importsFullFoundation(sourcesIn: link.resolvingSymlinksInPath())
        let engine = options.enginePackage.standardizedFileURL
        let identity = engine.lastPathComponent.lowercased()
        let web = options.platform == .web
        // Web: JavaScriptKit's `js` plugin packages the player (a command plugin has to come from
        // a direct dependency); the engine's package depends on it too with ENGINE_WASM=1.
        let webPackage = web ? ",\n        .package(url: \"https://github.com/swiftwasm/JavaScriptKit.git\", from: \"\(WebToolchain.javaScriptKitVersion)\")" : ""
        let linkerSettings = web
            // wasm-ld drops DWARF in release (a third of the module; names stay for stack traces).
            ? #"[.unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))]"#
            // Linux: shared libraries the export bundles (GLFW) are looked up in lib/ next to the executable.
            : #"[.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "$ORIGIN/lib"], .when(platforms: [.linux]))]"#
        // Web: no Foundation autolinking and member import visibility, as the engine's own wasm
        // targets (Package.swift's `wasmFoundationSettings`): one stray `import Foundation` would
        // otherwise link ICU (about 35 MB) into the module. Game code imports WASIFoundation on WASI.
        let wasmSettings = web
            ? #".enableUpcomingFeature("MemberImportVisibility"), .unsafeFlags(["Foundation", "FoundationInternationalization", "_FoundationICU", "CoreFoundation"].flatMap { ["-Xfrontend", "-disable-autolink-library", "-Xfrontend", $0] })"#
            : ""
        // A game whose code imports Foundation (JSONSerialization, String(format:), ...) links all
        // of it, ICU included: its target keeps autolinking. `run` says what that costs.
        // Both targets get WebAssembly SIMD like the engine (Package.swift's `wasmFoundationSettings`):
        // it changes how `SIMD3<Float>` / `SIMD4<Float>` (Vec3, Quat) are passed, so game code built
        // without it traps ("signature_mismatch") the first time it calls the engine with one.
        let wasmSIMD = #".unsafeFlags(["-Xcc", "-msimd128"])"#
        let gameWasmSettings = (gameUsesFoundation ? #".enableUpcomingFeature("MemberImportVisibility")"# : wasmSettings) + ", \(wasmSIMD)"
        let gameSettings = web ? ",\n                            swiftSettings: [\(gameWasmSettings)]" : ""
        let playerSettings = web ? ", \(wasmSettings), \(wasmSIMD)" : ""
        let manifest = """
            // swift-tools-version: 6.0
            // Generated by GameExporter (Sources/Engine/Packaging/GameExporter.swift); rewritten on every export.
            // Links \(options.gameTarget) and Engine statically into one executable.
            import PackageDescription

            let package = Package(
                name: "\(options.gameTarget)Export",
                platforms: [.macOS(.v14)],
                dependencies: [.package(path: \(Self.literal(engine.path)))\(webPackage)],
                targets: [
                    .target(name: \(Self.literal(options.gameTarget)), dependencies: [.product(name: "Engine", package: \(Self.literal(identity)))],
                            path: \(Self.literal("Sources/\(options.gameTarget)"))\(gameSettings)),
                    .executableTarget(name: \(Self.literal(playerTarget)),
                                      dependencies: [\(Self.literal(options.gameTarget)), .product(name: "Engine", package: \(Self.literal(identity)))],
                                      path: "Sources/Player",
                                      // `@_extern(c)` in main.swift.
                                      swiftSettings: [.enableExperimentalFeature("Extern")\(playerSettings)],
                                      linkerSettings: \(linkerSettings)),
                ]
            )

            """
        let main = """
            // Generated by GameExporter. The game module's entry point, linked in statically (see GamePlayer.swift).
            // Declared as the C function it is (`@_cdecl`): a Swift-convention declaration (`@_silgen_name`)
            // happens to work natively, but WebAssembly traps on the signature mismatch.
            import Engine

            @_extern(c, "\(entryPoint)")
            func gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32

            MainActor.assumeIsolated {
                GamePlayer.main(module: { gameModuleEntry($0) })
            }

            """
        try Self.writeIfChanged(manifest, to: root.appendingPathComponent("Package.swift"))
        try Self.writeIfChanged(main, to: root.appendingPathComponent("Sources/Player/main.swift"))
    }

    /// The build command for the player. Web: the Wasm toolchain's `swift package js` (JavaScriptKit's
    /// PackageToJS) builds and packages it; wasm-opt runs afterwards (`webOptimize`).
    public var buildCommand: [String] {
        if options.platform == .web {
            return [WebToolchain.find().swift.path, "package"] + buildFlags
                + ["js", "--product", playerTarget, "-c", options.configuration.rawValue, "--no-optimize"]
        }
        return ["swift", "build"] + buildFlags + ["--product", playerTarget]
    }

    /// `NAME=value` settings for the build (`/usr/bin/env` takes them before the command): a
    /// macOS export builds without the Vulkan backend (Metal only, what macOS uses anyway). With
    /// the Vulkan SDK installed it would otherwise link Homebrew's Vulkan loader and GLFW
    /// (`/opt/homebrew/...dylib`), which players' Macs don't have, and which exist for this
    /// machine's architecture only.
    var buildEnvironment: [String] {
        switch options.platform {
        case .macos: ["ENGINE_DISABLE_VULKAN=1"]
        // The engine's manifest leaves out what WASI lacks (docs/wasm-spike.md).
        case .web: ["ENGINE_WASM=1"]
        case .linux, .windows: []
        }
    }

    /// The flags that pick the build's products folder (shared by `buildCommand` and `--show-bin-path`).
    var buildFlags: [String] {
        if options.platform == .web { return ["--swift-sdk", WebToolchain.find().sdk] }
        var flags = ["-c", options.configuration.rawValue]
        switch options.cook.target.platform {
        case .macos:
            // Always explicit, so an x86_64 export doesn't reuse (or overwrite) the native products.
            flags += ["--arch", options.architecture.rawValue]
        case .linux:
            flags.append("--static-swift-stdlib")
        case .windows, .web:
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
        if options.platform == .web {
            let sources = options.gamePackage.appendingPathComponent("Sources/\(options.gameTarget)", isDirectory: true)
            if !options.sceneOnly, Self.importsFullFoundation(sourcesIn: sources) {
                progress?("Note: \(options.gameTarget) imports Foundation, so the web build links all of it (ICU included: "
                          + "about 35 MB more, 10 MB compressed). To leave it out, import it as "
                          + "`#if os(WASI) import WASIFoundation #else import Foundation #endif` (see docs/wasm-spike.md)")
            }
            return try runWeb(cook: cook, start: start, progress: progress)
        }
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
            executableURL = app.appendingPathComponent(options.name + executableSuffix)
            try fm.createDirectory(at: app, withIntermediateDirectories: true)
        }
        try fm.copyItem(at: built.executable, to: executableURL)
        for bundle in built.bundles { try fm.copyItem(at: bundle, to: resources.appendingPathComponent(bundle.lastPathComponent)) }
        let pack = resources.appendingPathComponent("\(options.name).pack")
        try fm.moveItem(at: URL(fileURLWithPath: cook.packPath), to: pack)
        if options.cook.target.platform == .macos {
            // Ad-hoc signature over the whole bundle (the linker signed only the executable).
            _ = GameModuleBuilder.run(["codesign", "--force", "--sign", "-", app.path], in: options.output)
        } else if options.cook.target.platform == .windows {
            // No run.sh, strip or ldd: the .exe finds its pack next to it, and the DLLs it loads go beside it.
            let sources = Self.windowsLibraries(builtIn: built.executable.deletingLastPathComponent(),
                                                environment: ProcessInfo.processInfo.environment)
            for source in sources {
                let destination = app.appendingPathComponent(source.lastPathComponent)
                guard !fm.fileExists(atPath: destination.path) else { continue }
                try fm.copyItem(at: source, to: destination)
            }
            progress?("Bundled \(sources.count) DLLs (Engine, the Swift runtime, zlib)")
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

    /// The executable file extension for the export's platform (".exe" on Windows).
    var executableSuffix: String { options.cook.target.platform == .windows ? ".exe" : "" }

    /// The last line of `output` that is an absolute path: `/...` or, on Windows, `C:\...` or `\\server\...`
    /// (`swift build --show-bin-path` can print warnings before it).
    static func lastAbsolutePath(in output: String) -> String? {
        output.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.last { line in
            if line.hasPrefix("/") || line.hasPrefix("\\\\") { return true }
            let chars = Array(line.prefix(3))
            return chars.count == 3 && chars[0].isLetter && chars[1] == ":" && (chars[2] == "\\" || chars[2] == "/")
        }
    }

    /// Builds the player with this machine's toolchain.
    func buildNatively(progress: (@Sendable (String) -> Void)?) throws -> BuiltPlayer {
        progress?("Building \(options.gameTarget) with Engine (\(options.configuration.rawValue), \(options.architecture.rawValue)) "
                  + "(in \(playerPackage.path): \(buildCommand.joined(separator: " ")))")
        let build = GameModuleBuilder.run(buildEnvironment + buildCommand, in: playerPackage)
        guard build.succeeded else { throw GameExportError.buildFailed(build.output) }
        progress?(String(format: "Built in %.1f s", build.seconds))
        let binPath = GameModuleBuilder.run(buildEnvironment + ["swift", "build"] + buildFlags + ["--show-bin-path"], in: playerPackage)
        let shown = Self.lastAbsolutePath(in: binPath.output)
        let shownBin = binPath.succeeded ? shown.map { URL(fileURLWithPath: $0, isDirectory: true) } : nil
        let bin = (shownBin ?? playerPackage.appendingPathComponent(".build/\(options.configuration.rawValue)", isDirectory: true))
            .resolvingSymlinksInPath()
        let executable = bin.appendingPathComponent(playerTarget + executableSuffix)
        guard FileManager.default.fileExists(atPath: executable.path) else { throw GameExportError.missingProduct(executable.path) }
        let bundles = ((try? FileManager.default.contentsOfDirectory(atPath: bin.path)) ?? [])
            .filter { $0.hasSuffix(".bundle") || $0.hasSuffix(".resources") }.sorted().map { bin.appendingPathComponent($0) }
        return BuiltPlayer(executable: executable, bundles: bundles, libraries: nil, seconds: build.seconds)
    }

    /// The DLLs a Windows export carries next to its .exe, as `Scripts/package-release.ps1` does
    /// for the editor: every DLL in the build's products folder (`Engine.dll`: on Windows Engine
    /// is a .dynamic product, see Package.swift), every DLL in the Swift runtime's folder (the one
    /// on `Path` holding `swiftCore.dll`: the standard library, Foundation, ICU…), and zlib's
    /// (`$ZLIB_DIR\bin\z*.dll` and `libz*.dll`, else `zlib1.dll`, `z.dll` or `libz.dll` on `Path`; vcpkg's
    /// zlib 1.4 builds `libz.dll`). The Vulkan loader comes
    /// with the GPU driver and GLFW is linked statically; the MSVC runtime is the player's
    /// Visual C++ Redistributable. One file per name, first found wins.
    static func windowsLibraries(builtIn bin: URL, environment: [String: String]) -> [URL] {
        let fm = FileManager.default
        func dlls(in folder: URL, matching keep: (String) -> Bool = { _ in true }) -> [URL] {
            ((try? fm.contentsOfDirectory(atPath: folder.path)) ?? []).sorted()
                .filter { $0.lowercased().hasSuffix(".dll") && keep($0.lowercased()) }
                .map { folder.appendingPathComponent($0) }
        }
        // Windows environment names are case-insensitive ("Path" or "PATH").
        let pathValue = environment.first { $0.key.uppercased() == "PATH" }?.value ?? ""
        let pathFolders = pathValue.split(separator: ";").map { URL(fileURLWithPath: String($0), isDirectory: true) }
        func onPath(_ name: String) -> URL? {
            pathFolders.lazy.map { $0.appendingPathComponent(name) }.first { fm.fileExists(atPath: $0.path) }
        }

        var found = dlls(in: bin)
        if let swiftCore = onPath("swiftCore.dll") { found += dlls(in: swiftCore.deletingLastPathComponent()) }
        let zlibBin = environment.first { $0.key.uppercased() == "ZLIB_DIR" }.map {
            URL(fileURLWithPath: $0.value, isDirectory: true).appendingPathComponent("bin", isDirectory: true)
        }
        let zlib = zlibBin.map { dlls(in: $0) { $0.hasPrefix("z") || $0.hasPrefix("libz") } } ?? []
        found += zlib.isEmpty ? ["zlib1.dll", "z.dll", "libz.dll"].compactMap(onPath) : zlib

        var names = Set<String>()
        return found.filter { names.insert($0.lastPathComponent.lowercased()).inserted }
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
        let identifier = "local.acro." + options.name.filter { $0.isLetter || $0.isNumber }.lowercased()
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
        try data.write(to: url, options: .engineAtomic)
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

