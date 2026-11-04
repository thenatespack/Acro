import Engine
import Foundation

// `Editor --cook` and `Editor --build-game`: cooking and exporting without a window.
//
//   Editor --cook <project> [--scenes a.scene,b.scene] [--platform macos|linux|windows] [--gpu bc|astc]
//                 [--textures compress|asImported] [--quality fast|normal|high] [--include <path or id>]… [--out <dir>]
//   Editor --build-game <project> [--scenes …] [--config release|debug] [--arch x86_64|arm64] [--docker] [--gpu bc|astc] [--textures …]
//                       [--game <target>] [--out <dir>]

public enum EditorPackagingCLI {
    public static let usage = """
        Editor --cook <project> [--scenes a.scene,b.scene] [--platform macos|linux|windows] [--gpu bc|astc]
                      [--textures compress|asImported] [--quality fast|normal|high] [--include <asset path or id>]... [--out <dir>]
        Editor --build-game <project> [--scenes ...] [--config release|debug] [--arch x86_64|arm64] [--docker]
                            [--platform linux] [--gpu bc|astc] [--textures ...] [--game <target>] [--out <dir>]

        --cook writes <out>/<name>.pack and <name>.manifest.json (default out: <project>/Build/<platform>-pack): every
        asset reachable from the scenes (default: Project.json "build.scenes"), textures compressed for the GPU family
        (default: astc for macos, bc otherwise). --build-game also builds the game module and Engine (release by default;
        this machine's architecture unless --arch, which macOS accepts either of) into one executable and writes a
        runnable app to <out> (default <project>/Build/<platform>-<arch>, plus -debug for --config debug). --docker builds a
        Linux game in a Docker container (implies --platform linux; either --arch, from any machine).
        """

    /// Whether `arguments` (without the program name) ask for cooking or exporting.
    public static func handles(_ arguments: [String]) -> Bool {
        arguments.first == "--cook" || arguments.first == "--build-game"
    }

    /// Runs `--cook` or `--build-game`; returns the exit status.
    @MainActor
    public static func run(_ arguments: [String]) -> Int32 {
        do {
            var rest = arguments[...]
            let mode = rest.popFirst() ?? ""
            guard let projectPath = rest.popFirst(), !projectPath.hasPrefix("-") else { throw CLIError("\(mode) needs a project folder\n\n\(usage)") }
            var scenes: [String]?
            var platform = CookPlatform.current
            var family: TextureFamily?
            var textures: TextureCookMode?
            var quality: TextureCompressionQuality?
            var include: [String] = []
            var out: String?
            var game: String?
            var configuration = BuildConfiguration.release
            var architecture = BuildArchitecture.current
            var useDocker = false
            func value(_ flag: String) throws -> String {
                guard let next = rest.popFirst() else { throw CLIError("\(flag) needs a value") }
                return next
            }
            func parse<T: RawRepresentable>(_ flag: String, _: T.Type) throws -> T where T.RawValue == String, T: CaseIterable {
                let raw = try value(flag)
                guard let parsed = T(rawValue: raw) else {
                    throw CLIError("\(flag): '\(raw)' isn't one of \(T.allCases.map(\.rawValue).joined(separator: ", "))")
                }
                return parsed
            }
            while let flag = rest.popFirst() {
                switch flag {
                case "--scenes": scenes = try value(flag).split(separator: ",").map(String.init)
                case "--platform": platform = try parse(flag, CookPlatform.self)
                case "--config": configuration = try parse(flag, BuildConfiguration.self)
                case "--arch": architecture = try parse(flag, BuildArchitecture.self)
                case "--docker":
                    useDocker = true
                    platform = .linux
                case "--gpu": family = try parse(flag, TextureFamily.self)
                case "--textures": textures = try parse(flag, TextureCookMode.self)
                case "--quality": quality = try parse(flag, TextureCompressionQuality.self)
                case "--include": include.append(try value(flag))
                case "--out": out = try value(flag)
                case "--game": game = try value(flag)
                default: throw CLIError("Unknown option '\(flag)'\n\n\(usage)")
                }
            }
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            let projectURL = URL(fileURLWithPath: projectPath, relativeTo: cwd).standardizedFileURL
            let project = try Project.open(at: projectURL)
            let database = AssetDatabase(project: project)
            database.scan()
            let build = project.settings.build ?? GameBuildSettings()
            let target = CookTarget(platform: platform, textureFamily: family ?? build.textureFamily)
            let outURL = out.map { URL(fileURLWithPath: $0, relativeTo: cwd).standardizedFileURL }
            let progress: @Sendable (String) -> Void = { print($0) }
            if mode == "--cook" {
                let options = CookOptions(scenes: scenes ?? build.scenes ?? [], include: include + (build.include ?? []), target: target,
                                          textures: textures ?? build.textures ?? .compress, textureQuality: quality,
                                          packName: build.name ?? project.name)
                let folder = outURL ?? project.root.appendingPathComponent(build.output ?? "Build", isDirectory: true)
                    .appendingPathComponent("\(platform.rawValue)-pack", isDirectory: true)
                let report = try AssetCooker.plan(database: database, options: options).run(to: folder)
                for warning in report.warnings { print("warning: \(warning)") }
                print(report.summary)
                print(report.packPath)
            } else {
                var options = try GameExporter.options(for: project, game: game.map { GameModuleSettings(target: $0) }, gameBase: cwd,
                                                       scenes: scenes, output: outURL, target: target,
                                                       configuration: configuration, architecture: architecture)
                if let textures { options.cook.textures = textures }
                options.useDocker = useDocker
                options.cook.textureQuality = quality
                options.cook.include += include
                let report = try GameExporter.prepare(database: database, options: options).run(progress: progress)
                print(report.outputPath)
            }
            return 0
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            return 1
        }
    }

    struct CLIError: Error, CustomStringConvertible {
        var description: String
        init(_ description: String) { self.description = description }
    }
}
