import Engine
import Foundation

// Playtests from the command line (see Sources/Engine/Playtest/Playtest.swift):
//
// ```sh
// swift run GameRunner SampleGame --playtest Projects/SampleGame/Playtests        # every *.playtest.json in it
// swift run GameRunner SampleGame --playtest walk.playtest.json --report out.json  # exit 1 when an assertion fails
// swift run GameRunner SampleGame Projects/SampleGame/Assets/Scenes/Main.scene --mcp  # headless MCP server
// ```
//
// Each playtest plays its `scene` (resolved next to the file or in the project above it; a scene
// given on the command line wins) headless at a fixed dt, so a run is the same on every machine.
// The exit code is 0 when every playtest passed, 1 when one failed and 2 when one couldn't run.

@MainActor
enum PlaytestRun {
    /// Runs the playtests and returns the exit code.
    static func run(module: GameModule, scenePath: String?, playtests: [String], reportPath: String?) -> Int32 {
        var files: [URL] = []
        for path in playtests {
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            var isFolder: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder) else {
                printError("No playtest at \(path)")
                return 2
            }
            if isFolder.boolValue {
                let found = (FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? [])
                    .filter { $0.lastPathComponent.hasSuffix(Playtest.fileSuffix) }
                    .sorted { $0.path < $1.path }
                if found.isEmpty { printError("No *\(Playtest.fileSuffix) files in \(path)") }
                files += found
            } else {
                files.append(url)
            }
        }
        guard !files.isEmpty else { return 2 }
        var reports: [Report] = []
        var code: Int32 = 0
        for file in files {
            print("Playtest \(file.lastPathComponent)")
            let report = runOne(module: module, scenePath: scenePath, file: file)
            print(report.result.report.split(separator: "\n").map { "  " + $0 }.joined(separator: "\n"))
            if report.result.checks.isEmpty && report.result.errors.isEmpty { print("  (no assertions)") }
            reports.append(report)
            if !report.ran { code = max(code, 2) } else if !report.result.passed { code = max(code, 1) }
        }
        let failed = reports.filter { !$0.result.passed }.count
        print(failed == 0 ? "All \(reports.count) playtests passed" : "\(failed) of \(reports.count) playtests failed")
        if let reportPath {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            do {
                try encoder.encode(reports).write(to: URL(fileURLWithPath: reportPath), options: .atomic)
            } catch {
                printError("Couldn't write \(reportPath): \(error)")
                code = max(code, 2)
            }
        }
        return code
    }

    struct Report: Codable {
        var file: String
        var scene: String?
        /// False when the playtest or its scene couldn't load.
        var ran: Bool
        var result: PlaytestResult
    }

    private static func runOne(module: GameModule, scenePath: String?, file: URL) -> Report {
        func failure(_ message: String, scene: String? = nil) -> Report {
            Report(file: file.path, scene: scene, ran: false,
                   result: PlaytestResult(name: nil, checks: [], errors: [message], frames: 0, time: 0))
        }
        let playtest: Playtest
        do {
            playtest = try Playtest(contentsOf: file)
        } catch {
            return failure("\(file.lastPathComponent) isn't a readable playtest: \(error)")
        }
        let sceneURL: URL
        if let scenePath {
            sceneURL = URL(fileURLWithPath: scenePath)
        } else if let scene = playtest.scene {
            sceneURL = PlaytestHeadlessHost.resolve(scene, from: file)
        } else {
            return failure("\(file.lastPathComponent) names no scene: pass one on the command line")
        }
        do {
            let host = try PlaytestHeadlessHost(module: module, sceneURL: sceneURL, log: { print("  " + $0) })
            return Report(file: file.path, scene: sceneURL.path, ran: true, result: host.run(playtest))
        } catch {
            return failure("The scene \(sceneURL.path) didn't load: \(error)", scene: sceneURL.path)
        }
    }

    /// Serves the scene headless over MCP on standard input / output until the client closes it.
    static func serve(module: GameModule, sceneURL: URL, output: FileHandle) throws {
        let host = try PlaytestHeadlessHost(module: module, sceneURL: sceneURL, log: { printError($0) })
        let mcp = PlaytestMCP(host: host)
        printError("Serving \(sceneURL.lastPathComponent) headless over MCP (stdio); playtest.start begins a session")
        mcp.serveStandardIO(output: output)
    }

    static func printError(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}
