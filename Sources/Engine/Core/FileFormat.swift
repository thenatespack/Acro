/// The `"format"` tags in the engine's JSON files ("Acro.Scene", "Acro.Project"…).
///
/// Files are written with the "Acro." prefix. Files from before the rename used
/// "SwiftGameEngine." and are still read.
enum FileFormat {
    static let prefix = "Acro."
    static let legacyPrefix = "SwiftGameEngine."

    /// The tag for a kind of file ("Scene" → "Acro.Scene").
    static func tag(_ kind: String) -> String { prefix + kind }

    /// Whether `found` is `expected` (an "Acro." tag) or its pre-rename spelling.
    static func matches(_ found: String?, _ expected: String) -> Bool {
        guard let found else { return false }
        return found == expected || (expected.hasPrefix(prefix) && found == legacyPrefix + expected.dropFirst(prefix.count))
    }
}
