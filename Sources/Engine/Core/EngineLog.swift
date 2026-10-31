import Foundation

/// Messages the engine reports from its backends (Vulkan's validation layer, with
/// `ENGINE_VULKAN_VALIDATION=1`). They are printed unless a handler is installed; the editor
/// installs one that moves them into its console, where `log.read` and `diagnostics.get` see
/// them. Posting is thread-safe (validation messages arrive on driver threads); the handler
/// runs on the posting thread.
public enum EngineLog {
    public enum Level: Int, Sendable, Comparable {
        case info, warning, error

        public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
    }

    public typealias Handler = @Sendable (Level, String) -> Void

    private static let lock = NSLock()
    nonisolated(unsafe) private static var handler: Handler?

    /// Replaces the handler (nil: print again).
    public static func setHandler(_ handler: Handler?) {
        lock.withLock { self.handler = handler }
    }

    /// Reports `message`: to the handler if one is installed, else printed.
    public static func post(_ level: Level, _ message: String) {
        if let handler = lock.withLock({ handler }) {
            handler(level, message)
        } else {
            print(message)
        }
    }
}
