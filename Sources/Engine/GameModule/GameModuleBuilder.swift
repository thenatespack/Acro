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

/// Builds a game's SwiftPM target and links it into a game module (see GameModule.swift for
/// why the link is ours and not SwiftPM's).
///
/// 1. `build()` runs `swift build --target <target> -c <configuration>` in the package (or the
///    configured command). That compiles the target and whatever it depends on.
/// 2. `link(to:)` links only the target's object files into a shared library, leaving Engine's
///    symbols to the host: `swiftc -emit-library <objects> -undefined dynamic_lookup` on macOS.
///    Windows DLLs can't leave symbols undefined, so there the module is linked against the
///    host's import library (`Editor.lib` next to `Editor.exe`, see `hostImportLibrary`) and
///    imports Engine's symbols from the running host by name.
///    SwiftPM's swift-build backend leaves one prelinked `<Target>.o` in the bin folder; the
///    native backend a `<Target>.build/` folder of objects. Both are handled.
///
/// A game can be several targets: the game target and library targets it depends on (directly
/// or not) that the host doesn't contain, i.e. everything outside Engine and its dependencies.
/// `libraryTargets` names them (`describeTargets()` finds them with `swift package describe`)
/// and `link(to:)` links their objects into the module too. Rebuilding after a change in one
/// of them is still one `swift build --target <game>`, which recompiles only what changed.
///
/// `buildModule(to:)` (GameModuleFastBuild.swift) wraps both steps and, after the first build,
/// recompiles the game target with one direct `swiftc` call instead (no SwiftPM planning).
///
/// The configuration must be the host's (`currentConfiguration`), and so must Engine:
/// `engineChangedSinceHostBuilt()` is true when Engine's build products are newer than the
/// running executable, i.e. a game built now would be compiled against another Engine.
///
/// `build()` and `link(to:)` block for seconds; run them off the main thread.
public struct GameModuleBuilder: Sendable {
    /// The package folder (with `Package.swift`).
    public var packageURL: URL
    /// The game's target.
    public var target: String
    /// "debug" or "release".
    public var configuration: String
    /// Replaces `swift build --target …` when set; run in the package folder.
    public var buildCommand: [String]?
    /// Library targets of the game linked into the module with `target` (see above).
    public var libraryTargets: [String] = []
    /// Windows: the import library of the host that will load the module (default
    /// `defaultHostImportLibrary`). Unused elsewhere.
    public var hostImportLibrary: URL? = GameModuleBuilder.defaultHostImportLibrary

    public init(packageURL: URL, target: String, configuration: String = GameModuleBuilder.currentConfiguration,
                buildCommand: [String]? = nil) {
        self.packageURL = packageURL
        self.target = target
        self.configuration = configuration
        self.buildCommand = buildCommand
    }

    /// The configuration this program was built in.
    public static var currentConfiguration: String {
        #if DEBUG
        "debug"
        #else
        "release"
        #endif
    }

    /// The build products folder (`.build/<configuration>`, symlinks resolved).
    public var binURL: URL {
        packageURL.appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent(configuration, isDirectory: true).resolvingSymlinksInPath()
    }

    /// The command `build()` runs.
    public var command: [String] {
        buildCommand ?? ["swift", "build", "--target", target, "-c", configuration]
    }

    /// The outcome of a build or link step.
    public struct StepResult: Sendable {
        public var succeeded: Bool
        /// Everything the command printed (standard output and error).
        public var output: String
        public var seconds: Double
    }

    /// Runs the build command. Blocks.
    public func build() -> StepResult {
        Self.run(command, in: packageURL)
    }

    /// The compiled objects of the game target and its library targets.
    public func objectFiles() throws -> [URL] {
        try ([target] + libraryTargets).flatMap { try objectFiles(of: $0) }
    }

    /// One target's compiled objects.
    public func objectFiles(of target: String) throws -> [URL] {
        let bin = binURL
        let prelinked = bin.appendingPathComponent("\(target).o")
        if FileManager.default.fileExists(atPath: prelinked.path) { return [prelinked] }
        // swift-build on Windows: a `<Target>.objlib` folder of objects; native: `<Target>.build`.
        let objectExtensions: Set<String> = ["o", "obj"]
        var objects: [URL] = []
        for folderName in ["\(target).objlib", "\(target).build"] where objects.isEmpty {
            let folder = bin.appendingPathComponent(folderName, isDirectory: true)
            objects = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))?
                .filter { objectExtensions.contains($0.pathExtension) }.sorted { $0.path < $1.path } ?? []
        }
        guard !objects.isEmpty else {
            throw GameModuleError.linkFailed("No objects for target '\(target)' in \(bin.path): build it first (swift build --target \(target) -c \(configuration))")
        }
        return objects
    }

    /// The command `link(to:)` runs.
    public func linkCommand(objects: [URL], output: URL) -> [String] {
        var arguments = ["swiftc", "-emit-library", "-o", output.path] + objects.map(\.path)
        #if os(macOS)
        #if arch(arm64)
        arguments += ["-target", "arm64-apple-macosx14.0"]
        #else
        arguments += ["-target", "x86_64-apple-macosx14.0"]
        #endif
        #endif
        return arguments + Self.undefinedSymbolFlags + windowsLinkFlags(objects: objects)
    }

    /// Linker flags that leave Engine's symbols to the host (none needed on Linux; on Windows
    /// see `windowsLinkFlags`).
    static var undefinedSymbolFlags: [String] {
        #if os(macOS)
        ["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"]
        #else
        []
        #endif
    }

    /// Windows: the host's import library, which resolves Engine's symbols to imports from the
    /// host executable, and an export of the entry point. SwiftPM compiles the game target with
    /// `-static`, which leaves `@_cdecl` functions unexported, so the link exports it by name.
    /// Empty elsewhere.
    func windowsLinkFlags(objects: [URL]) -> [String] {
        #if os(Windows)
        var flags: [String] = []
        if let hostImportLibrary { flags.append(hostImportLibrary.path) }
        // The objects ask for the libraries of Engine's C modules (autolinking through the
        // module maps under Windows/). The host already has them and the module gets those
        // symbols from it, and a machine with only the editor installed has no zlib.lib to
        // find; Engine's own libraries would bind imports to the unused Engine.dll.
        for library in Self.hostOnlyLibraries { flags += ["-Xlinker", "/NODEFAULTLIB:\(library).lib"] }
        return flags + ["-Xlinker", "/EXPORT:\(Self.entryPointSymbol(in: objects))"]
        #else
        return []
        #endif
    }

    /// The engine's modules (Package.swift's `engineModules`): `Engine` re-exports the rest.
    static let engineModules = ["EngineCore", "EngineScene", "EngineGraphics", "EngineBackends", "EngineText", "EnginePhysics",
                                "EngineAudio", "EngineAssets", "EngineMeshBuild", "EngineNet", "EngineUI", "EngineRendering", "Engine"]

    /// Libraries a game module's objects autolink that only the host links (Windows).
    static let hostOnlyLibraries = ["zlib", "vulkan-1", "glfw3", "EngineMCP"] + engineModules

    /// The entry point the objects define: `GameModuleABI.entryPoint`, or the legacy name when
    /// only that one appears in them.
    static func entryPointSymbol(in objects: [URL]) -> String {
        let current = Data(GameModuleABI.entryPoint.utf8)
        let legacy = Data(GameModuleABI.legacyEntryPoint.utf8)
        var sawLegacy = false
        for object in objects {
            guard let data = try? Data(contentsOf: object, options: .mappedIfSafe) else { continue }
            if data.range(of: current) != nil { return GameModuleABI.entryPoint }
            if data.range(of: legacy) != nil { sawLegacy = true }
        }
        return sawLegacy ? GameModuleABI.legacyEntryPoint : GameModuleABI.entryPoint
    }

    /// The running executable's import library (`<executable>.lib` beside it), which the
    /// Windows linker writes for an executable that exports symbols: Editor.exe and
    /// GameRunner.exe export Engine's (Engine is a `.dynamic` product on Windows, so it is
    /// compiled with its public symbols exported, and the hosts link it in). `ACRO_HOST_IMPORT_LIBRARY`
    /// overrides it. Nil elsewhere or when there is none.
    public static var defaultHostImportLibrary: URL? {
        #if os(Windows)
        if let path = ProcessInfo.processInfo.environment["ACRO_HOST_IMPORT_LIBRARY"], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else { return nil }
        let library = executable.deletingPathExtension().appendingPathExtension("lib")
        return FileManager.default.fileExists(atPath: library.path) ? library : nil
        #else
        return nil
        #endif
    }

    /// Links the target's objects into a game module at `output`. Blocks.
    @discardableResult
    public func link(to output: URL) throws -> StepResult {
        #if os(Windows)
        guard hostImportLibrary != nil else {
            let name = Bundle.main.executableURL?.deletingPathExtension().lastPathComponent ?? "the host"
            throw GameModuleError.linkFailed("No \(name).lib next to \(name).exe: game modules on Windows link against the host's import library, which builds of this engine write beside the executable (set ACRO_HOST_IMPORT_LIBRARY to use another)")
        }
        #endif
        let result = Self.run(linkCommand(objects: try objectFiles(), output: output), in: packageURL)
        guard result.succeeded else { throw GameModuleError.linkFailed(result.output) }
        return result
    }

    /// Whether the engine's build products (any of its modules) are newer than the running executable, when that
    /// executable was built in this package's bin folder (false otherwise: nothing to compare).
    public func engineChangedSinceHostBuilt() -> Bool {
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath(),
              executable.path.hasPrefix(binURL.path + "/"),
              let hostDate = Self.modificationDate(executable) else { return false }
        let bin = binURL
        let candidates = Self.engineModules.flatMap { name in
            [bin.appendingPathComponent("\(name).o"), bin.appendingPathComponent("\(name).swiftmodule"),
             bin.appendingPathComponent("Modules/\(name).swiftmodule")]
        }
        return candidates.compactMap(Self.modificationDate).contains { $0 > hostDate }
    }

    /// The package folder at or above `start` (the folder with `Package.swift`).
    public static func findPackage(from start: URL) -> URL? {
        var folder = start.standardizedFileURL
        while true {
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent("Package.swift").path) { return folder }
            let parent = folder.deletingLastPathComponent()
            if parent.path == folder.path { return nil }
            folder = parent
        }
    }

    static func modificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    /// The executable and arguments that run `arguments` with its first word looked up in PATH:
    /// `/usr/bin/env` does the lookup on macOS and Linux; Windows has no `env`, so the program
    /// is found here (trying PATHEXT's extensions, `.exe` first).
    static func launch(_ arguments: [String]) -> (URL, [String]) {
        #if os(Windows)
        guard let name = arguments.first else { return (URL(fileURLWithPath: "swift.exe"), []) }
        return (findExecutable(name) ?? URL(fileURLWithPath: name), Array(arguments.dropFirst()))
        #else
        return (URL(fileURLWithPath: "/usr/bin/env"), arguments)
        #endif
    }

    #if os(Windows)
    /// `name` (a path, or a program name looked up in PATH), or nil.
    static func findExecutable(_ name: String) -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let extensions = [""] + [".exe"] + (environment["PATHEXT"] ?? ".COM;.EXE;.BAT;.CMD")
            .split(separator: ";").map { String($0).lowercased() }.filter { $0 != ".exe" }
        let hasExtension = !URL(fileURLWithPath: name).pathExtension.isEmpty
        func candidate(_ base: String) -> URL? {
            for ext in hasExtension ? [""] : extensions.dropFirst() {
                let path = base + ext
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue {
                    return URL(fileURLWithPath: path)
                }
            }
            return nil
        }
        if name.contains("\\") || name.contains("/") { return candidate(name) }
        let path = environment.first { $0.key.uppercased() == "PATH" }?.value ?? ""
        for folder in path.split(separator: ";") where !folder.isEmpty {
            if let found = candidate(String(folder) + "\\" + name) { return found }
        }
        return nil
    }
    #endif

    /// Runs `arguments` (looked up in PATH) in `folder`, collecting its output. Blocks.
    public static func run(_ arguments: [String], in folder: URL) -> StepResult {
        let start = Date()
        #if os(macOS) || os(Linux) || os(Windows)
        let process = Process()
        (process.executableURL, process.arguments) = launch(arguments)
        process.currentDirectoryURL = folder
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return StepResult(succeeded: false, output: "Couldn't run \(arguments.joined(separator: " ")): \(error)",
                              seconds: Date().timeIntervalSince(start))
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self)
        return StepResult(succeeded: process.terminationStatus == 0, output: output, seconds: Date().timeIntervalSince(start))
        #else
        return StepResult(succeeded: false, output: "Can't run processes on this platform", seconds: 0)
        #endif
    }
}
