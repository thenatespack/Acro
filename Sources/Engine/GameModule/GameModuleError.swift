// Kept out of GameModuleLoader.swift so builds without run-time loading (WebAssembly) have it.

/// Errors from building, linking and loading game modules.
public enum GameModuleError: Error, Equatable, CustomStringConvertible {
    /// No file at the path.
    case notFound(String)
    /// `dlopen` (`LoadLibraryW` on Windows) failed, often over a missing Engine symbol: the
    /// module was built against other Engine sources.
    case loadFailed(String)
    /// The library doesn't export `GameModuleABI.entryPoint`.
    case noEntryPoint(String)
    /// The module was built for another ABI version.
    case versionMismatch(Int32)
    /// The library contains its own copy of Engine.
    case embedsEngine(String)
    /// The build command failed; its output is in the message.
    case buildFailed(String)
    /// Linking the target's objects failed.
    case linkFailed(String)
    /// Engine was rebuilt after the host was linked; a module built against it may not match.
    case engineChanged
    /// The platform can't load code at run time.
    case unsupported

    public var description: String {
        switch self {
        case .notFound(let path): "No game module at \(path)"
        case .loadFailed(let message): "Couldn't load the game module: \(message)"
        case .noEntryPoint(let path): "\(path) is not a game module (no \(GameModuleABI.entryPoint))"
        case .versionMismatch(let version): "The game module was built for game module ABI \(version); this host uses \(GameModuleABI.version)"
        case .embedsEngine(let path):
            "\(path) links its own copy of Engine, so its types aren't the host's. Link the game target's objects only (GameModuleBuilder, or the editor's game.reload)"
        case .buildFailed(let output): "Build failed:\n\(output)"
        case .linkFailed(let output): "Link failed:\n\(output)"
        case .engineChanged: "Engine changed since this program was built: restart it (swift run …) before loading game code built against the new Engine"
        case .unsupported: "Game modules can't be loaded on this platform"
        }
    }
}
