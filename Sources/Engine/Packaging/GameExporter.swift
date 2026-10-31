import Foundation

// Exporting a game: the project's game module and Engine linked statically into one release
// executable, its assets cooked into a pack (AssetCooker), laid out as something that runs on
// its own.
//
// ```
// macOS   <out>/<Name>.app/Contents/Info.plist
//                                  /MacOS/<Name>                       Engine + game module, one executable
//                                  /Resources/<Name>.pack              the cooked assets
//                                  /Resources/SwiftGameEngine_Engine.bundle   shaders, fonts
// Linux   <out>/<Name>/<Name>, <Name>.pack, SwiftGameEngine_Engine.resources/, run.sh
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

    public init(name: String, gameTarget: String, gamePackage: URL, enginePackage: URL, output: URL, cook: CookOptions) {
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
    case missingSources(String)
    case buildFailed(String)
    case missingProduct(String)

    public var description: String {
        switch self {
        case .noGame: "The project has no game code to export: set \"game\": {\"target\": …} in Project.json (or load one with --game)"
        case .noEnginePackage(let from): "Couldn't find the engine's package from \(from): set \"build\": {\"enginePackage\": …} in Project.json"
        case .wrongPlatform(let platform): "This machine can't build a \(platform.rawValue) executable (cross-compiling isn't supported); cook the pack alone with --cook"
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
        guard options.cook.target.platform == .current else { throw GameExportError.wrongPlatform(options.cook.target.platform) }
        return GameExporter(options: options, cookPlan: try AssetCooker.plan(database: database, options: options.cook))
    }

    /// Export options for `project` from its settings (`"game"`, `"build"`), with overrides.
    /// `game` replaces the project's game setting (the editor's `--game`), its package relative
    /// to `gameBase` (default: the project folder).
    @MainActor
    public static func options(for project: Project, game: GameModuleSettings? = nil, gameBase: URL? = nil, scenes: [String]? = nil,
                               output: URL? = nil, target: CookTarget? = nil) throws -> GameExportOptions {
        let build = project.settings.build ?? GameBuildSettings()
        guard let settings = game ?? project.settings.game, let gameTarget = settings.target else { throw GameExportError.noGame }
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
        let out = output ?? URL(fileURLWithPath: build.output ?? "Build", relativeTo: project.root).standardizedFileURL
            .appendingPathComponent(CookPlatform.current.rawValue, isDirectory: true)
        var cook = CookOptions(scenes: scenes ?? build.scenes ?? [], include: build.include ?? [],
                               target: target ?? CookTarget(platform: .current, textureFamily: build.textureFamily),
                               textures: build.textures ?? .compress, writesManifest: false)
        let name = build.name ?? project.name
        cook.packName = name
        return GameExportOptions(name: name, gameTarget: gameTarget, gamePackage: gamePackage, enginePackage: engine, output: out, cook: cook)
    }

    /// The engine's package: `gamePackage` itself when it holds Engine, else one of its
    /// resolved dependencies (`swift package show-dependencies`).
    public static func findEnginePackage(from gamePackage: URL) -> URL? {
        func isEngine(_ url: URL) -> Bool {
            FileManager.default.fileExists(atPath: url.appendingPathComponent("Sources/Engine/GameModule/GameModule.swift").path)
        }
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
    public var playerPackage: URL {
        options.gamePackage.appendingPathComponent(".build/game-export/\(options.gameTarget)", isDirectory: true)
    }

    /// The executable target of the generated package.
    var playerTarget: String { "\(options.gameTarget)Player" }

    /// The app bundle (macOS) or folder (elsewhere) the export produces.
    public var outputURL: URL {
        #if os(macOS)
        options.output.appendingPathComponent("\(options.name).app", isDirectory: true)
        #else
        options.output.appendingPathComponent(options.name, isDirectory: true)
        #endif
    }

    /// Writes the generated player package (only files whose contents changed, so builds stay incremental).
    public func writePlayerPackage() throws {
        let fm = FileManager.default
        let sources = options.gamePackage.appendingPathComponent("Sources/\(options.gameTarget)", isDirectory: true)
        guard fm.fileExists(atPath: sources.path) else { throw GameExportError.missingSources(sources.path) }
        let root = playerPackage
        try fm.createDirectory(at: root.appendingPathComponent("Sources/Player"), withIntermediateDirectories: true)
        let link = root.appendingPathComponent("Sources/\(options.gameTarget)")
        if (try? fm.destinationOfSymbolicLink(atPath: link.path)) != sources.path {
            try? fm.removeItem(at: link)
            try fm.createSymbolicLink(at: link, withDestinationURL: sources)
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
                                      path: "Sources/Player"),
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
        var command = ["swift", "build", "-c", "release", "--product", playerTarget]
        #if os(Linux)
        command.append("--static-swift-stdlib")
        #endif
        return command
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
        progress?("Building \(options.gameTarget) with Engine in release (\(buildCommand.joined(separator: " ")))")
        let build = GameModuleBuilder.run(buildCommand, in: playerPackage)
        guard build.succeeded else { throw GameExportError.buildFailed(build.output) }
        progress?(String(format: "Built in %.1f s", build.seconds))
        let bin = playerPackage.appendingPathComponent(".build/release", isDirectory: true).resolvingSymlinksInPath()
        let executable = bin.appendingPathComponent(playerTarget)
        guard fm.fileExists(atPath: executable.path) else { throw GameExportError.missingProduct(executable.path) }
        let bundles = ((try? fm.contentsOfDirectory(atPath: bin.path)) ?? [])
            .filter { $0.hasSuffix(".bundle") || $0.hasSuffix(".resources") }.sorted()

        // 3. Lay it out.
        progress?("Writing \(app.path)")
        try? fm.removeItem(at: app)
        #if os(macOS)
        let contents = app.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        let executableURL = contents.appendingPathComponent("MacOS/\(options.name)")
        try fm.createDirectory(at: executableURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.createDirectory(at: resources, withIntermediateDirectories: true)
        try Data(infoPlist.utf8).write(to: contents.appendingPathComponent("Info.plist"))
        #else
        let resources = app
        let executableURL = app.appendingPathComponent(options.name)
        try fm.createDirectory(at: app, withIntermediateDirectories: true)
        #endif
        try fm.copyItem(at: executable, to: executableURL)
        for bundle in bundles { try fm.copyItem(at: bin.appendingPathComponent(bundle), to: resources.appendingPathComponent(bundle)) }
        let pack = resources.appendingPathComponent("\(options.name).pack")
        try fm.moveItem(at: URL(fileURLWithPath: cook.packPath), to: pack)
        #if os(macOS)
        // Ad-hoc signature over the whole bundle (the linker signed only the executable).
        _ = GameModuleBuilder.run(["codesign", "--force", "--sign", "-", app.path], in: options.output)
        #else
        let script = app.appendingPathComponent("run.sh")
        try Data(launcher.utf8).write(to: script)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        #endif

        var report = GameExportReport(outputPath: app.path, executablePath: executableURL.path, packPath: pack.path, cook: cook,
                                      buildSeconds: build.seconds, totalSeconds: 0, executableBytes: Self.size(of: executableURL),
                                      totalBytes: Self.size(of: app), linking: "static")
        report.cook.packPath = pack.path
        report.totalSeconds = Date().timeIntervalSince(start)
        progress?(report.summary)
        return report
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
