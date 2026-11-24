#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// NSString's path functions on `String`. FoundationEssentials (WebAssembly builds) has no
/// NSString, so code uses these instead of `(path as NSString).…`; elsewhere they are exactly
/// NSString's.
extension String {
    /// `NSString.lastPathComponent`: "a/b.txt" → "b.txt", "a/b/" → "b", "/" → "/".
    package var pathLastComponent: String {
        #if os(WASI)
        let trimmed = Self.trimmingTrailingSlashes(self)
        if trimmed == "/" || trimmed.isEmpty { return trimmed }
        if let slash = trimmed.lastIndex(of: "/") { return String(trimmed[trimmed.index(after: slash)...]) }
        return trimmed
        #else
        (self as NSString).lastPathComponent
        #endif
    }

    /// `NSString.pathExtension`: "a/b.tar.gz" → "gz", "a/.hidden" → "", "a/b" → "".
    package var pathFileExtension: String {
        #if os(WASI)
        let name = pathLastComponent
        guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return "" }
        return String(name[name.index(after: dot)...])
        #else
        (self as NSString).pathExtension
        #endif
    }

    /// `NSString.deletingPathExtension`: "a/b.tar.gz" → "a/b.tar", "a/b" → "a/b".
    package var pathDeletingExtension: String {
        #if os(WASI)
        let trimmed = Self.trimmingTrailingSlashes(self)
        let ext = trimmed.pathFileExtension
        guard !ext.isEmpty else { return trimmed }
        return String(trimmed.dropLast(ext.count + 1))
        #else
        (self as NSString).deletingPathExtension
        #endif
    }

    /// `NSString.deletingLastPathComponent`: "a/b" → "a", "/a" → "/", "a" → "".
    package var pathDeletingLastComponent: String {
        #if os(WASI)
        let trimmed = Self.trimmingTrailingSlashes(self)
        if trimmed == "/" { return "/" }
        guard let slash = trimmed.lastIndex(of: "/") else { return "" }
        if slash == trimmed.startIndex { return "/" }
        return Self.trimmingTrailingSlashes(String(trimmed[..<slash]))
        #else
        (self as NSString).deletingLastPathComponent
        #endif
    }

    /// `NSString.expandingTildeInPath`: a leading "~" becomes the home folder.
    package var pathExpandingTilde: String {
        #if os(WASI)
        guard hasPrefix("~"), dropFirst().isEmpty || dropFirst().hasPrefix("/"),
              let home = ProcessInfo.processInfo.environment["HOME"] else { return self }
        return home + dropFirst()
        #else
        (self as NSString).expandingTildeInPath
        #endif
    }

    #if os(WASI)
    private static func trimmingTrailingSlashes(_ path: String) -> String {
        var path = Substring(path)
        while path.count > 1 && path.hasSuffix("/") { path = path.dropLast() }
        return String(path)
    }
    #endif
}
