import Foundation

/// Where a game keeps per-user files (settings, save games), and how it writes them.
///
/// - macOS: `~/Library/Application Support/<app>/`
/// - Linux: `$XDG_CONFIG_HOME/<app>/`, or `~/.config/<app>/`
/// - Windows: `%APPDATA%\<app>\`
///
/// `ENGINE_USER_DATA_DIR` replaces the whole directory (no `<app>` is appended), so tests and
/// screenshot runs can point the game at a scratch folder and never see, or touch, the real
/// user's files.
public enum UserData {
    /// The environment variable that overrides the directory.
    public static let overrideVariable = "ENGINE_USER_DATA_DIR"

    /// Whether the directory is overridden (tests, screenshot runs).
    public static var isOverridden: Bool {
        guard let value = ProcessInfo.processInfo.environment[overrideVariable] else { return false }
        return !value.isEmpty
    }

    /// The directory for `app`'s files. Not created; `AtomicFile.write` creates it on demand.
    public static func directory(app: String) -> URL {
        let env = ProcessInfo.processInfo.environment
        if let value = env[overrideVariable], !value.isEmpty {
            return URL(fileURLWithPath: value, isDirectory: true)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let base: URL
        #if os(Windows)
        base = env["APPDATA"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? home.appendingPathComponent("AppData/Roaming", isDirectory: true)
        #elseif os(Linux)
        if let xdg = env["XDG_CONFIG_HOME"], !xdg.isEmpty {
            base = URL(fileURLWithPath: xdg, isDirectory: true)
        } else {
            base = home.appendingPathComponent(".config", isDirectory: true)
        }
        #else
        base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? home.appendingPathComponent("Library/Application Support", isDirectory: true)
        #endif
        return base.appendingPathComponent(app, isDirectory: true)
    }
}

/// Crash-safe file writes: the data goes to a temporary file next to the destination, which
/// then replaces it in one step, so a crash or a full disk leaves either the old file or the new
/// one, never half of each.
public enum AtomicFile {
    /// Writes `data` to `url`, creating its folder. On failure the previous file (if any) is
    /// untouched and the temporary file is removed.
    public static func write(_ data: Data, to url: URL) throws {
        try write(data, to: url, beforeCommit: nil)
    }

    /// `beforeCommit` runs after the temporary file is written and before it replaces the
    /// destination; tests throw from it to check a failed write leaves the old file alone.
    static func write(_ data: Data, to url: URL, beforeCommit: (() throws -> Void)?) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temp = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
        do {
            try data.write(to: temp)
            try beforeCommit?()
            if fm.fileExists(atPath: url.path) {
                _ = try fm.replaceItemAt(url, withItemAt: temp)
            } else {
                try fm.moveItem(at: temp, to: url)
            }
        } catch {
            try? fm.removeItem(at: temp)
            throw error
        }
    }
}
