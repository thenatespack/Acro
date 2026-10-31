import EditorCore
import Engine
import Foundation

// The in-engine editor: `swift run -c release Editor [path/to/scene.json] [--project <folder>] [--backend metal|vulkan]`.
// Everything lives in EditorCore; this only reads the command line and runs it.

let usage = """
    Usage: Editor [scene.json] [--project <folder>] [--game <target | module.dylib>] [--game-watch] [--backend metal|vulkan]
                  [--mcp] [--headless] [--mcp-port <port>] [--mcp-http | --no-mcp-http] [--mcp-read-only]
           Editor --mcp-tool-docs
           Editor --cook <project> [...] | --build-game <project> [...]   (see Editor --cook --help)

    Opens the scene file, or starts with a new scene; --project opens a project (Project.json,
    Assets/, Library/) and imports its assets. Environment: EDITOR_PREFS=<file> moves the
    prefs file (dock layout, last scene); ENGINE_SCREENSHOT=<png> renders a deterministic frame and quits.

    Game code: --game SampleGame builds that SwiftPM target (in the package at or above the working
    directory) and loads it as a game module: its components in Add Component, its systems in play
    mode, Reload Game Code to rebuild and reload it with the scene kept; --game-watch reloads when its
    sources change. --game <path>.dylib loads a prebuilt module. Overrides the project's "game" setting.

    MCP (AI clients drive the editor; see README): the editor serves Streamable HTTP on
    127.0.0.1:7333 (--mcp-port, EDITOR_MCP_PORT; the next free port if taken) with a bearer token
    written to <project>/Library/mcp.json; --no-mcp-http or EDITOR_MCP_HTTP=0 turns it off.
    --mcp serves a client on stdin/stdout instead (`claude mcp add swift-engine -- swift run Editor --mcp`);
    add --mcp-http to serve HTTP too. --headless runs without a window (needs --mcp or --mcp-http).
    --mcp-read-only exposes only read-only tools. --mcp-tool-docs prints the tool reference
    (docs/MCPTools.md) generated from the command registry.
    """

var config = EngineConfig(title: "Editor", width: 1440, height: 900, showDebugOverlay: false)
var scenePath: String?
var projectPath: String?
var mcpStdio = false
var headless = false
var mcpHTTP: Bool?
var mcpPort: UInt16?
var mcpReadOnly = false
var game: GameModuleSettings?
var gameWatch = false
var arguments = Array(CommandLine.arguments.dropFirst())

// Cooking and exporting run without a window (EditorPackagingCLI).
if EditorPackagingCLI.handles(arguments) {
    exit(MainActor.assumeIsolated { EditorPackagingCLI.run(arguments) })
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--backend":
        guard let name = arguments.first, let backend = GraphicsBackend(rawValue: name) else {
            fail("--backend needs one of: \(GraphicsBackend.available.map(\.rawValue).joined(separator: ", "))")
        }
        arguments.removeFirst()
        config.backend = backend
    case "--project":
        guard let path = arguments.first else { fail("--project needs a folder") }
        arguments.removeFirst()
        projectPath = path
    case "--game":
        guard let value = arguments.first else { fail("--game needs a target name or a module path") }
        arguments.removeFirst()
        game = GameModuleSettings(argument: value)
    case "--game-watch":
        gameWatch = true
    case "--mcp":
        mcpStdio = true
    case "--headless":
        headless = true
    case "--mcp-http":
        mcpHTTP = true
    case "--no-mcp-http":
        mcpHTTP = false
    case "--mcp-read-only":
        mcpReadOnly = true
    case "--mcp-tool-docs":
        print(EditorToolReference.markdown(), terminator: "")
        exit(0)
    case "--mcp-port":
        guard let port = arguments.first.flatMap({ UInt16($0) }) else { fail("--mcp-port needs a port number") }
        arguments.removeFirst()
        mcpPort = port
    case "--help", "-h":
        print(usage)
        exit(0)
    default:
        if argument.hasPrefix("-") { fail("Unknown option '\(argument)'\n\n\(usage)") }
        scenePath = argument
    }
}

var options = EditorOptions.fromEnvironment(scenePath: scenePath, projectPath: projectPath)
options.mcp.stdio = mcpStdio
// With stdio the client launched the editor; HTTP only when asked (another editor may hold the port).
options.mcp.http = mcpHTTP ?? (mcpStdio ? false : options.mcp.http)
if let mcpPort { options.mcp.port = mcpPort }
options.mcp.readOnly = mcpReadOnly
if gameWatch { game?.watch = true }
options.game = game

if headless {
    exit(EditorHeadless.run(options: options))
}

do {
    // The app first: with --mcp it claims stdout before the engine prints anything.
    let app = EditorApp(options: options)
    let engine = try Engine(config: config)
    try engine.run(app)
    app.shutdown(quitReason: engine.quitReason)
} catch {
    fail("Fatal: \(error)")
}
