import Engine
import Foundation

/// The editor without a window or GPU (`Editor --mcp --headless`), driven only by MCP clients,
/// for CI, scripts and machines without a display. The panels are built anyway (laid out at
/// 1440x900 points, never drawn), so the UI tools (`ui.snapshot`, `ui.click`…) and the panel
/// tools work; screenshots are unavailable, everything else behaves as in the app.
@MainActor
public enum EditorHeadless {
    /// Runs until the stdio client disconnects (forever with only HTTP). Returns the exit code.
    public static func run(options: EditorOptions) -> Int32 {
        let app = EditorApp(options: options)
        guard let mcp = app.mcp else {
            FileHandle.standardError.write(Data("Headless mode needs an MCP transport (--mcp, or HTTP)\n".utf8))
            return 1
        }
        let session = app.session
        app.setupWithoutWindow()
        guard options.mcp.stdio || mcp.http != nil else {
            session.log.error("Headless mode needs an MCP transport (--mcp, or HTTP)")
            return 1
        }
        session.log.info("Editor running headless")

        let clock = ContinuousClock()
        var last = clock.now
        while !mcp.stdioClientDisconnected {
            let now = clock.now
            let elapsed = now - last
            last = now
            let dt = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            // MCP requests, finished background imports, the world and the panels, as a frame would.
            app.updateWithoutWindow(dt: Float(min(dt, 0.25)))
            // Idle until a request arrives; keep ticking at ~60 Hz while playing or importing.
            let busy = session.isPlaying || mcp.server.hasPendingCalls || session.assets?.isLoading == true
            mcp.server.inbox.wait(timeout: busy ? 1.0 / 60 : 0.25)
        }
        mcp.pump()  // What arrived just before the client closed its end.
        mcp.stop()
        app.shutdown(quitReason: "the MCP stdio client disconnected")
        return 0
    }
}
