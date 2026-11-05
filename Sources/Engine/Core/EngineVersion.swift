/// The engine's version (semantic versioning). Shown by the editor (launcher, window title,
/// MCP `serverInfo`) and by games (`--version`, the debug overlay); written to `Project.json`
/// (`"engineVersion"`) and to asset packs, so a project or pack made by another engine version
/// is noticed when it is opened. Numbered by `Scripts/version.sh` (its pre-commit hook bumps
/// PATCH when sources change and MINOR when Engine's public API changes; MAJOR is bumped by hand
/// with `Scripts/version.sh major`), so don't edit the literal below by hand.
public enum EngineVersion {
    public static let current = "0.5.0"
    /// "Acro 0.1.0".
    public static var displayName: String { "Acro \(current)" }
}

/// A project or pack made with an engine version other than this one.
public struct EngineVersionMismatch: Equatable, Sendable, CustomStringConvertible {
    /// The version that made it.
    public var saved: String
    /// This engine's (`EngineVersion.current`).
    public var current: String

    public init(saved: String, current: String = EngineVersion.current) {
        self.saved = saved
        self.current = current
    }

    /// The mismatch, if `saved` is set and its MAJOR.MINOR differs from this engine's (nil: same
    /// release line, or unknown). PATCH is bumped on every source change and doesn't count.
    public static func check(_ saved: String?, current: String = EngineVersion.current) -> EngineVersionMismatch? {
        guard let saved, !sameRelease(saved, current) else { return nil }
        return EngineVersionMismatch(saved: saved, current: current)
    }

    /// Whether two versions share MAJOR.MINOR ("0.3.1" and "0.3.7" do).
    public static func sameRelease(_ a: String, _ b: String) -> Bool {
        let x = parts(a), y = parts(b)
        return (x.first ?? 0, x.dropFirst().first ?? 0) == (y.first ?? 0, y.dropFirst().first ?? 0)
    }

    static func parts(_ v: String) -> [Int] { v.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 } }

    /// Whether the other version is newer than this engine (numeric comparison of dotted parts).
    public var isNewer: Bool {
        let a = Self.parts(saved), b = Self.parts(current)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0, y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    public var description: String {
        "made with engine \(saved) (\(isNewer ? "newer than" : "older than") this engine, \(current))"
    }
}
