import Foundation

/// Builds a game's SwiftPM target and links it into a game module (see GameModule.swift for
/// why the link is ours and not SwiftPM's).
///
/// 1. `build()` runs `swift build --target <target> -c <configuration>` in the package (or the
///    configured command). That compiles the target and whatever it depends on.
/// 2. `link(to:)` links only the target's object files into a shared library, leaving Engine's
///    symbols to the host: `swiftc -emit-library <objects> -undefined dynamic_lookup` on macOS.
///    SwiftPM's swift-build backend leaves one prelinked `<Target>.o` in the bin folder; the
///    native backend a `<Target>.build/` folder of objects. Both are handled.
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

    /// The target's compiled objects.
    public func objectFiles() throws -> [URL] {
        let bin = binURL
        let prelinked = bin.appendingPathComponent("\(target).o")
        if FileManager.default.fileExists(atPath: prelinked.path) { return [prelinked] }
        let folder = bin.appendingPathComponent("\(target).build", isDirectory: true)
        let objects = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "o" }.sorted { $0.path < $1.path } ?? []
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
        arguments += ["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"]
        #endif
        return arguments
    }

    /// Links the target's objects into a game module at `output`. Blocks.
    @discardableResult
    public func link(to output: URL) throws -> StepResult {
        let result = Self.run(linkCommand(objects: try objectFiles(), output: output), in: packageURL)
        guard result.succeeded else { throw GameModuleError.linkFailed(result.output) }
        return result
    }

    /// Whether Engine's build products are newer than the running executable, when that
    /// executable was built in this package's bin folder (false otherwise: nothing to compare).
    public func engineChangedSinceHostBuilt() -> Bool {
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath(),
              executable.path.hasPrefix(binURL.path + "/"),
              let hostDate = Self.modificationDate(executable) else { return false }
        let bin = binURL
        let candidates = [bin.appendingPathComponent("Engine.o"),
                          bin.appendingPathComponent("Engine.swiftmodule"),
                          bin.appendingPathComponent("Modules/Engine.swiftmodule")]
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

    private static func modificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    /// Runs `arguments` (looked up in PATH) in `folder`, collecting its output. Blocks.
    public static func run(_ arguments: [String], in folder: URL) -> StepResult {
        let start = Date()
        #if os(macOS) || os(Linux) || os(Windows)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
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
