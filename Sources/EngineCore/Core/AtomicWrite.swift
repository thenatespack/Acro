import Foundation

extension Data.WritingOptions {
    /// `.atomic` (write a temporary file, then rename it over the target), except in WebAssembly,
    /// where WASI has no temporary files and Foundation makes `.atomic` unavailable.
    public static var engineAtomic: Data.WritingOptions {
        #if os(WASI)
        []
        #else
        .atomic
        #endif
    }
}
