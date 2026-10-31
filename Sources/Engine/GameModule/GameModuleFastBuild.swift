import Foundation

// Building a game module quickly, and games made of several targets.
//
// `swift build --target <game>` spends most of a reload planning: with nothing to compile it
// still takes ~0.5-1 s (load the manifest, resolve, plan the build graph, check every task),
// and a one-line change adds the compile. So `GameModuleBuilder.buildModule(to:)` builds once
// with `swift build -v`, keeps the `swiftc` command line SwiftPM used for the game target (a
// `GameModuleBuildPlan`, cached under `.build/game-modules/`), and from then on recompiles the
// game target and links the module in one `swiftc -emit-library` call (~0.4 s for SampleGame,
// against ~1.3-1.9 s for `swift build` + link). The game target is recompiled whole (as one
// module, no incremental state), so this pays off while it is small to medium; put stable code
// in library targets, which are linked from their SwiftPM-built objects.
//
// The plan is only used while it still describes the build; otherwise the reload falls back to
// `swift build` (which also captures a fresh plan) and says why:
// - Package.swift changed (targets, flags or dependencies may have);
// - the game target gained or lost a source file;
// - a file of one of its library targets changed since the last full build (only SwiftPM
//   rebuilds those, and the target's own objects depend on their modules);
// - the direct compile failed for another reason than an error in the game's own sources.
// `GAME_MODULE_FAST_BUILD=0` turns the fast path off.
//
// Library targets: `describeTargets()` runs `swift package describe` (cached while
// Package.swift is unchanged) and takes the game target's transitive target dependencies minus
// Engine and Engine's own dependencies (the host has those). Their objects are linked into the
// module with the game's. Dependencies on other packages' products aren't followed (their code
// isn't linked; such games need a prebuilt `library` and their own build command).

/// A game's targets, from `swift package describe`.
public struct GamePackageTargets: Codable, Sendable, Equatable {
    /// The game target.
    public var target: String
    /// Library targets the game target depends on, directly or not, that the host doesn't
    /// contain (outside Engine and its dependencies); dependencies first.
    public var libraryTargets: [String]
    /// Every one of those targets' source folders (absolute paths), the game target's included.
    public var folders: [String: String]

    public init(target: String, libraryTargets: [String], folders: [String: String]) {
        self.target = target
        self.libraryTargets = libraryTargets
        self.folders = folders
    }

    /// From `swift package describe --type json` output for the package at `packageURL`; the
    /// host provides `hostTargets` and their dependencies.
    public static func from(description json: Data, target: String, packageURL: URL,
                            hostTargets: Set<String> = ["Engine"]) throws -> GamePackageTargets {
        struct Description: Decodable {
            struct Target: Decodable {
                var name: String
                var path: String
                var target_dependencies: [String]?
            }
            var targets: [Target]
        }
        let description = try JSONDecoder().decode(Description.self, from: json)
        let byName = Dictionary(description.targets.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        guard byName[target] != nil else { throw GameModuleError.buildFailed("No target '\(target)' in \(packageURL.path)") }
        // Everything the host links: its targets and their closure.
        var host = Set<String>()
        func addHost(_ name: String) {
            guard host.insert(name).inserted else { return }
            for dependency in byName[name]?.target_dependencies ?? [] { addHost(dependency) }
        }
        hostTargets.forEach(addHost)
        // The game's closure outside it, dependencies before dependents.
        var ordered: [String] = []
        var seen = Set<String>()
        func visit(_ name: String) {
            guard !host.contains(name), seen.insert(name).inserted, let info = byName[name] else { return }
            for dependency in info.target_dependencies ?? [] { visit(dependency) }
            ordered.append(name)
        }
        visit(target)
        var folders: [String: String] = [:]
        for name in ordered {
            let path = byName[name]!.path
            folders[name] = (path.hasPrefix("/") ? URL(fileURLWithPath: path) : packageURL.appendingPathComponent(path)).standardizedFileURL.path
        }
        return GamePackageTargets(target: target, libraryTargets: ordered.filter { $0 != target }, folders: folders)
    }
}

/// How SwiftPM compiled a game target, kept so it can be compiled again with one `swiftc` call
/// (see the notes at the top of the file).
public struct GameModuleBuildPlan: Codable, Sendable, Equatable {
    public var target: String
    /// `swiftc` (absolute) and the arguments SwiftPM gave it, minus sources, outputs and
    /// incremental-build bookkeeping.
    public var arguments: [String]
    /// The sources it compiled (absolute paths, sorted).
    public var sources: [String]

    public init(target: String, arguments: [String], sources: [String]) {
        self.target = target
        self.arguments = arguments
        self.sources = sources
    }

    /// The plan in `swift build -v` output, if the build compiled `target` (nil when it was up
    /// to date: nothing to learn from). Response files (`@file`) are read for the source list.
    public static func capture(fromBuildOutput output: String, target: String) -> GameModuleBuildPlan? {
        let lines = output.split(separator: "\n").map(String.init)
        // swift-build backend: "builtin-Swift-Compilation -- /…/swiftc …"; native: "/…/swiftc …".
        let candidates = lines.filter { $0.contains("swiftc") && $0.contains("-module-name") }
        let preferred = candidates.first { $0.contains("builtin-Swift-Compilation -- ") } ?? candidates.first
        for line in [preferred].compactMap({ $0 }) + candidates {
            let words = shellWords(line)
            guard let start = words.firstIndex(where: { $0 == "swiftc" || $0.hasSuffix("/swiftc") }),
                  let nameIndex = words.firstIndex(of: "-module-name"), nameIndex + 1 < words.count,
                  words[nameIndex + 1] == target else { continue }
            if let plan = make(target: target, words: Array(words[start...])) { return plan }
        }
        return nil
    }

    private static let droppedFlags: Set<String> = [
        "-c", "-enable-batch-mode", "-incremental", "-save-temps", "-emit-dependencies", "-emit-module",
        "-serialize-diagnostics", "-emit-objc-header", "-experimental-emit-module-separately", "-emit-const-values",
        "-color-diagnostics", "-parseable-output", "-validate-clang-modules-once", "-emit-module-interface",
        "-emit-library", "-whole-module-optimization", "-wmo", "-no-whole-module-optimization",
    ]
    private static let droppedWithValue: Set<String> = [
        "-o", "-output-file-map", "-emit-module-path", "-dependency-scan-serialize-diagnostics-path", "-emit-objc-header-path",
        "-index-store-path", "-const-gather-protocols-list", "-clang-build-session-file", "-emit-module-interface-path",
        "-emit-private-module-interface-path", "-emit-module-source-info-path", "-emit-module-doc-path",
        "-emit-abi-descriptor-path", "-index-file-path", "-index-unit-output-path", "-module-link-name",
    ]

    private static func make(target: String, words: [String]) -> GameModuleBuildPlan? {
        var arguments: [String] = []
        var sources: [String] = []
        var i = 0
        while i < words.count {
            let word = words[i]
            if droppedFlags.contains(word) { i += 1; continue }
            if droppedWithValue.contains(word) { i += 2; continue }
            // Frontend-only shortcuts for module emission (they skip function bodies).
            if word == "-Xfrontend", i + 1 < words.count, words[i + 1].hasPrefix("-experimental-skip") { i += 2; continue }
            if word.hasPrefix("@"), i > 0 {
                guard let list = try? String(contentsOfFile: String(word.dropFirst()), encoding: .utf8) else { return nil }
                sources += list.split(whereSeparator: \.isNewline).map { shellWords(String($0)).first ?? String($0) }
                i += 1
                continue
            }
            if i > 0, word.hasSuffix(".swift"), !word.hasPrefix("-") {
                sources.append(word)
                i += 1
                continue
            }
            arguments.append(word)
            i += 1
        }
        guard !sources.isEmpty else { return nil }
        return GameModuleBuildPlan(target: target, arguments: arguments, sources: sources.map(standardPath).sorted())
    }

    /// The command that compiles `sources` and links them, with `objects`, into `output`.
    public func command(sources: [String], objects: [URL], output: URL) -> [String] {
        arguments + sources + objects.map(\.path) + ["-emit-library", "-o", output.path] + GameModuleBuilder.undefinedSymbolFlags
    }

    /// Splits a shell-quoted command line: whitespace separates words; `'…'`, `"…"` and `\x`
    /// quote (swift-build escapes `=` as `\=`).
    static func shellWords(_ line: String) -> [String] {
        var words: [String] = []
        var current = ""
        var inWord = false
        var quote: Character?
        var escaped = false
        for c in line {
            if escaped {
                current.append(c)
                escaped = false
                inWord = true
            } else if c == "\\" && quote != "'" {
                escaped = true
            } else if let open = quote {
                if c == open { quote = nil } else { current.append(c) }
            } else if c == "'" || c == "\"" {
                quote = c
                inWord = true
            } else if c == " " || c == "\t" {
                if inWord { words.append(current) }
                current = ""
                inWord = false
            } else {
                current.append(c)
                inWord = true
            }
        }
        if inWord { words.append(current) }
        return words
    }

    static func standardPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }
}

/// What `GameModuleBuilder.buildModule(to:)` did.
public struct GameModuleBuildOutcome: Sendable {
    public enum Mode: String, Codable, Sendable {
        /// `swift build` (or the build command), then a link of the targets' objects.
        case swiftBuild
        /// One direct `swiftc` call compiled the game target and linked the module.
        case swiftc
    }

    public var mode: Mode
    /// The build step (`swift build`, or the `swiftc` call); its output.
    public var build: GameModuleBuilder.StepResult
    /// The link, after `swift build`.
    public var link: GameModuleBuilder.StepResult?
    /// Why the fast path wasn't used (nil when it was, or isn't available: a build command).
    public var fallbackReason: String?
    /// The failure, when the module wasn't produced (the build's output is in `build`).
    public var error: GameModuleError?
}

extension GameModuleBuilder {
    /// Where plans and target lists are cached: `.build/game-modules/` in the package.
    public var cacheFolder: URL {
        packageURL.appendingPathComponent(".build", isDirectory: true).appendingPathComponent("game-modules", isDirectory: true)
    }

    private struct Cache: Codable {
        var manifestDate: Date
        var targets: GamePackageTargets?
        var plan: GameModuleBuildPlan?
        /// When `swift build` last succeeded: library targets' files newer than this need another.
        var lastFullBuild: Date?
    }

    private var cacheURL: URL { cacheFolder.appendingPathComponent("\(configuration)-\(target).json") }
    private var manifestDate: Date { Self.modificationDate(packageURL.appendingPathComponent("Package.swift")) ?? .distantPast }

    private func loadCache() -> Cache? {
        guard let data = try? Data(contentsOf: cacheURL), let cache = try? JSONDecoder().decode(Cache.self, from: data),
              cache.manifestDate == manifestDate else { return nil }
        return cache
    }

    private func saveCache(_ cache: Cache) {
        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(cache).write(to: cacheURL, options: .atomic)
    }

    /// The game's targets (`swift package describe`, cached while Package.swift is unchanged).
    /// Blocks.
    public func describeTargets() throws -> GamePackageTargets {
        if let targets = loadCache()?.targets { return targets }
        // A scratch path of its own: the package's `.build` may be locked by a running
        // `swift build` / `swift test` (the editor's own build, or the one running the tests),
        // and describe would wait for it. A timeout keeps it from hanging the editor anyway;
        // then the shared path is tried once (packages whose dependencies would need resolving).
        let scratch = cacheFolder.appendingPathComponent("describe", isDirectory: true).path
        var result = Self.runCapturingOutput(["swift", "package", "--scratch-path", scratch, "describe", "--type", "json"],
                                             in: packageURL, timeout: 30)
        if !result.succeeded {
            result = Self.runCapturingOutput(["swift", "package", "describe", "--type", "json"], in: packageURL, timeout: 30)
        }
        guard result.succeeded, let start = result.output.firstIndex(of: "{") else {
            throw GameModuleError.buildFailed("swift package describe failed:\n\(result.output)")
        }
        let targets = try GamePackageTargets.from(description: Data(result.output[start...].utf8), target: target, packageURL: packageURL)
        var cache = loadCache() ?? Cache(manifestDate: manifestDate)
        cache.targets = targets
        saveCache(cache)
        return targets
    }

    /// The cached plan, if any (for tests and `game.info`).
    public var cachedPlan: GameModuleBuildPlan? { loadCache()?.plan }

    /// Builds the game and links the module at `output` (see the notes at the top of the file):
    /// with a usable plan, one `swiftc` call; otherwise `swift build -v` (capturing a plan) and
    /// a link of the game's targets' objects. Blocks for seconds; run it off the main thread.
    public func buildModule(to output: URL, allowFast: Bool = true) -> GameModuleBuildOutcome {
        var builder = self
        if let targets = try? describeTargets() { builder.libraryTargets = targets.libraryTargets }
        let fastAllowed = allowFast && buildCommand == nil && ProcessInfo.processInfo.environment["GAME_MODULE_FAST_BUILD"] != "0"
        var fallbackReason: String?
        if fastAllowed {
            switch builder.fastBuild(to: output) {
            case .built(let outcome): return outcome
            case .notUsable(let reason): fallbackReason = reason
            }
        }
        return builder.fullBuild(to: output, fallbackReason: fallbackReason)
    }

    private enum FastResult {
        case built(GameModuleBuildOutcome)
        case notUsable(String)
    }

    private func fastBuild(to output: URL) -> FastResult {
        guard let cache = loadCache(), let plan = cache.plan else { return .notUsable("no build plan yet (first build of \(target))") }
        if let reason = fastBuildBlocker(plan: plan, cache: cache) { return .notUsable(reason) }
        let objects: [URL]
        do { objects = try libraryTargets.flatMap { try objectFiles(of: $0) } } catch { return .notUsable("\(error)") }
        let sources = sourceFiles(of: target)
        var result = Self.run(plan.command(sources: sources, objects: objects, output: output), in: packageURL)
        // A source saved again while it compiled (an editor writing twice, a watcher reload):
        // compile the new text rather than paying for a full build.
        if !result.succeeded, result.output.contains("was modified during the build") {
            result = Self.run(plan.command(sources: sources, objects: objects, output: output), in: packageURL)
        }
        if result.succeeded { return .built(GameModuleBuildOutcome(mode: .swiftc, build: result, link: nil)) }
        // Errors in the game's own code are the answer; anything else may be a stale plan.
        let folder = sourceFolder(of: target)
        let ownErrors = result.output.split(separator: "\n").contains { $0.hasPrefix(folder + "/") && $0.contains(": error: ") }
        if ownErrors {
            return .built(GameModuleBuildOutcome(mode: .swiftc, build: result, link: nil, error: .buildFailed(result.output)))
        }
        return .notUsable("the direct compile failed:\n\(result.output.suffix(2000))")
    }

    /// Why `plan` can't be used now, or nil.
    private func fastBuildBlocker(plan: GameModuleBuildPlan, cache: Cache) -> String? {
        let sources = sourceFiles(of: target)
        if sources != plan.sources { return "\(target)'s source files were added, removed or renamed" }
        let since = cache.lastFullBuild ?? .distantPast
        for library in libraryTargets {
            if let changed = sourceFiles(of: library, extensions: nil).first(where: { (Self.modificationDate(URL(fileURLWithPath: $0)) ?? .distantFuture) > since }) {
                return "library target \(library) changed (\(URL(fileURLWithPath: changed).lastPathComponent))"
            }
        }
        if let swiftc = plan.arguments.first, swiftc.hasPrefix("/"), !FileManager.default.fileExists(atPath: swiftc) {
            return "\(swiftc) is gone"
        }
        return nil
    }

    private func fullBuild(to output: URL, fallbackReason: String?) -> GameModuleBuildOutcome {
        let start = Date()
        let verbose = buildCommand == nil
        let build = Self.run(verbose ? command + ["-v"] : command, in: packageURL)
        guard build.succeeded else {
            return GameModuleBuildOutcome(mode: .swiftBuild, build: build, link: nil, fallbackReason: fallbackReason,
                                          error: .buildFailed(build.output))
        }
        if verbose {
            var cache = loadCache() ?? Cache(manifestDate: manifestDate)
            if let plan = GameModuleBuildPlan.capture(fromBuildOutput: build.output, target: target) { cache.plan = plan }
            cache.lastFullBuild = start
            saveCache(cache)
        }
        // The verbose log is long; keep what a failure report needs.
        var trimmed = build
        if verbose { trimmed.output = Self.withoutVerboseLines(build.output) }
        do {
            let link = try self.link(to: output)
            return GameModuleBuildOutcome(mode: .swiftBuild, build: trimmed, link: link, fallbackReason: fallbackReason)
        } catch let error as GameModuleError {
            return GameModuleBuildOutcome(mode: .swiftBuild, build: trimmed, link: nil, fallbackReason: fallbackReason, error: error)
        } catch {
            return GameModuleBuildOutcome(mode: .swiftBuild, build: trimmed, link: nil, fallbackReason: fallbackReason,
                                          error: .linkFailed("\(error)"))
        }
    }

    /// The folder of `target` (from `describeTargets`, else `Sources/<target>`).
    func sourceFolder(of target: String) -> String {
        if let folder = loadCache()?.targets?.folders[target] { return GameModuleBuildPlan.standardPath(folder) }
        return GameModuleBuildPlan.standardPath(packageURL.appendingPathComponent("Sources/\(target)").path)
    }

    /// `target`'s files with `extensions` (nil: all), absolute and sorted.
    func sourceFiles(of target: String, extensions: Set<String>? = ["swift"]) -> [String] {
        let folder = URL(fileURLWithPath: sourceFolder(of: target), isDirectory: true)
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey],
                                                              options: [.skipsHiddenFiles]) else { return [] }
        var files: [String] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { continue }
            if let extensions, !extensions.contains(url.pathExtension) { continue }
            files.append(GameModuleBuildPlan.standardPath(url.path))
        }
        return files.sorted()
    }

    /// Build output without the command lines and target lists `-v` adds.
    static func withoutVerboseLines(_ output: String) -> String {
        output.split(separator: "\n", omittingEmptySubsequences: false).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !(trimmed.hasPrefix("builtin-") || trimmed.hasPrefix("info: ") || trimmed.hasPrefix("cd ")
                     || trimmed.hasPrefix("/") && trimmed.contains(" -") && !trimmed.contains(": error:") && !trimmed.contains(": warning:"))
        }.joined(separator: "\n")
    }

    /// Like `run`, but only standard output is collected (standard error is discarded), and the
    /// process is terminated after `timeout` seconds (a failure).
    static func runCapturingOutput(_ arguments: [String], in folder: URL, timeout: Double) -> StepResult {
        let start = Date()
        #if os(macOS) || os(Linux) || os(Windows)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = folder
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch {
            return StepResult(succeeded: false, output: "\(error)", seconds: 0)
        }
        let timer = DispatchWorkItem { [process] in if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        timer.cancel()
        return StepResult(succeeded: process.terminationStatus == 0 && process.terminationReason == .exit,
                          output: String(decoding: data, as: UTF8.self),
                          seconds: Date().timeIntervalSince(start))
        #else
        return StepResult(succeeded: false, output: "Can't run processes on this platform", seconds: 0)
        #endif
    }
}
