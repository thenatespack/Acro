import EditorCore
import Engine
import Foundation

// The in-engine editor: `swift run -c release Editor [path/to/scene.json] [--backend metal|vulkan]`.
// Everything lives in EditorCore; this only reads the command line and runs it.

let usage = """
    Usage: Editor [scene.json] [--backend metal|vulkan]

    Opens the scene file, or starts with a new scene. Environment: EDITOR_PREFS=<file> moves the
    prefs file (dock layout, last scene); ENGINE_SCREENSHOT=<png> renders a deterministic frame and quits.
    """

var config = EngineConfig(title: "Editor", width: 1440, height: 900, showDebugOverlay: false)
var scenePath: String?
var arguments = Array(CommandLine.arguments.dropFirst())
while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--backend":
        guard let name = arguments.first, let backend = GraphicsBackend(rawValue: name) else {
            print("--backend needs one of: \(GraphicsBackend.available.map(\.rawValue).joined(separator: ", "))")
            exit(1)
        }
        arguments.removeFirst()
        config.backend = backend
    case "--help", "-h":
        print(usage)
        exit(0)
    default:
        if argument.hasPrefix("-") {
            print("Unknown option '\(argument)'\n\n\(usage)")
            exit(1)
        }
        scenePath = argument
    }
}

do {
    let engine = try Engine(config: config)
    let app = EditorApp(options: .fromEnvironment(scenePath: scenePath))
    try engine.run(app)
    app.savePrefs()
} catch {
    print("Fatal: \(error)")
    exit(1)
}
