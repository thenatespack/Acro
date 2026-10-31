import Engine
import Foundation

/// The editor without a window or GPU (`Editor --mcp --headless`): an `EditorSession` driven
/// only by MCP clients, for CI, scripts and machines without a display. Commands that need the
/// window (layout, framing the camera) are unavailable; everything else behaves as in the app.
@MainActor
public enum EditorHeadless {
    /// Runs until the stdio client disconnects (forever with only HTTP). Returns the exit code.
    public static func run(options: EditorOptions) -> Int32 {
        let session = EditorSession(document: EditorDocument())
        let mcp = EditorMCP(session: session)
        mcp.fallbackConfigURL = options.prefsURL?.deletingLastPathComponent().appendingPathComponent("mcp.json")
        if options.mcp.stdio { mcp.startStdio() }

        if let path = options.projectPath { session.run(ProjectOpenCommand.self, .init(path: path)) }
        if options.scenePath.flatMap({ session.run(SceneOpenCommand.self, .init(path: $0)) }) == nil {
            session.run(SceneNewCommand.self)
        }
        if options.mcp.http {
            do {
                try mcp.startHTTP(port: options.mcp.port)
            } catch {
                session.log.error("MCP HTTP server unavailable: \(error)")
            }
        }
        guard options.mcp.stdio || mcp.http != nil else {
            session.log.error("Headless mode needs an MCP transport (--mcp, or HTTP)")
            return 1
        }
        session.log.info("Editor running headless")

        let clock = ContinuousClock()
        var last = clock.now
        while !mcp.stdioClientDisconnected {
            mcp.pump()
            // What the app's renderer would do: apply finished background imports.
            session.assets?.pump()
            let now = clock.now
            let elapsed = now - last
            last = now
            let dt = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            session.log.time += dt
            session.tick(dt: min(dt, 0.25))
            // Idle until a request arrives; keep ticking at ~60 Hz while playing or importing.
            let busy = session.isPlaying || mcp.server.hasPendingCalls || session.assets?.isLoading == true
            mcp.server.inbox.wait(timeout: busy ? 1.0 / 60 : 0.25)
        }
        mcp.pump()  // What arrived just before the client closed its end.
        mcp.stop()
        return 0
    }
}
