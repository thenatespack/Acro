// WebAssembly builds only (ENGINE_WASM=1): the engine's Foundation.
//
// `import Foundation` on WASI links all of swift-corelibs-foundation, FoundationInternationalization
// and ICU with its ~35 MB data table, even if nothing from them is used (the autolink entries pull
// the libraries in whole). The runtime modules import this module there instead: it re-exports
// FoundationEssentials (Data, URL, Date, JSON coders, FileManager, ProcessInfo...) and the C
// library, and adds the few Foundation-only APIs the engine uses, with the same names and
// signatures so call sites need no `#if`. Native builds never build this module and import
// Foundation as before (see docs/wasm-spike.md, "Size").
//
// wasm32-unknown-wasip1 has no threads, so locks are no-ops, and waiting on a condition that
// nothing else can signal is a fatal error rather than a hang.
@_exported import FoundationEssentials
@_exported import WASILibc

// MARK: Locks

public protocol NSLocking {
    func lock()
    func unlock()
}

extension NSLocking {
    @discardableResult
    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try body()
    }
}

/// Single-threaded: never contended.
public final class NSLock: NSLocking, @unchecked Sendable {
    public var name: String?
    public init() {}
    public func lock() {}
    public func unlock() {}
    public func `try`() -> Bool { true }
    public func lock(before limit: Date) -> Bool { true }
}

public final class NSRecursiveLock: NSLocking, @unchecked Sendable {
    public var name: String?
    public init() {}
    public func lock() {}
    public func unlock() {}
    public func `try`() -> Bool { true }
}

/// Single-threaded: a `wait` could only be woken by this same thread, so it is a deadlock.
public final class NSCondition: NSLocking, @unchecked Sendable {
    public var name: String?
    public init() {}
    public func lock() {}
    public func unlock() {}
    public func wait() { fatalError("NSCondition.wait() would deadlock: WebAssembly builds are single-threaded") }
    public func wait(until limit: Date) -> Bool {
        fatalError("NSCondition.wait(until:) would deadlock: WebAssembly builds are single-threaded")
    }
    public func signal() {}
    public func broadcast() {}
}

// MARK: Thread

/// The one thread. No `init(block:)`: code that starts threads must be left out on WASI.
public final class Thread: @unchecked Sendable {
    nonisolated(unsafe) private static let main = Thread()
    public var name: String?
    private init() {}
    public static var current: Thread { main }
    public static var isMainThread: Bool { true }
    public var isMainThread: Bool { true }
    public static var callStackSymbols: [String] { [] }
    public static func sleep(forTimeInterval interval: Double) {
        guard interval > 0 else { return }
        var request = timespec(tv_sec: time_t(interval), tv_nsec: Int((interval - Double(Int(interval))) * 1e9))
        var remaining = timespec()
        while nanosleep(&request, &remaining) != 0 && errno == EINTR { request = remaining }
    }
}

// MARK: FileHandle

/// A file descriptor with the parts of Foundation's API the engine uses.
public final class FileHandle: @unchecked Sendable {
    public let fileDescriptor: Int32
    private let closeOnDealloc: Bool
    private var closed = false

    public init(fileDescriptor: Int32, closeOnDealloc: Bool) {
        self.fileDescriptor = fileDescriptor
        self.closeOnDealloc = closeOnDealloc
    }

    public convenience init(fileDescriptor: Int32) { self.init(fileDescriptor: fileDescriptor, closeOnDealloc: false) }

    public convenience init(forReadingFrom url: URL) throws { try self.init(path: url.path, flags: O_RDONLY) }
    /// Like Foundation, the file must exist.
    public convenience init(forWritingTo url: URL) throws { try self.init(path: url.path, flags: O_WRONLY) }
    public convenience init(forUpdating url: URL) throws { try self.init(path: url.path, flags: O_RDWR) }

    private convenience init(path: String, flags: Int32) throws {
        let fd = open(path, flags)
        guard fd >= 0 else { throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: path]) }
        self.init(fileDescriptor: fd, closeOnDealloc: true)
    }

    deinit { if closeOnDealloc && !closed { _ = WASILibc.close(fileDescriptor) } }

    public static let standardInput = FileHandle(fileDescriptor: 0)
    public static let standardOutput = FileHandle(fileDescriptor: 1)
    public static let standardError = FileHandle(fileDescriptor: 2)

    private func ioError() -> CocoaError { CocoaError(.fileWriteUnknown, userInfo: ["errno": Int(errno)]) }

    public func write<T: DataProtocol>(contentsOf data: T) throws {
        for region in data.regions {
            try region.withUnsafeBytes { bytes in
                var offset = 0
                while offset < bytes.count {
                    let n = WASILibc.write(fileDescriptor, bytes.baseAddress! + offset, bytes.count - offset)
                    if n < 0 {
                        if errno == EINTR { continue }
                        throw ioError()
                    }
                    offset += n
                }
            }
        }
    }

    /// Foundation's non-throwing write (errors are ignored here; Foundation raises).
    public func write(_ data: Data) { try? write(contentsOf: data) }

    public func read(upToCount count: Int) throws -> Data? {
        var data = Data(count: count)
        var total = 0
        try data.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            while total < count {
                let n = WASILibc.read(fileDescriptor, bytes.baseAddress! + total, count - total)
                if n < 0 {
                    if errno == EINTR { continue }
                    throw ioError()
                }
                if n == 0 { break }
                total += n
            }
        }
        if total == 0 && count > 0 { return nil }
        data.count = total
        return data
    }

    public func readToEnd() throws -> Data? {
        var result = Data()
        while let chunk = try read(upToCount: 64 * 1024) { result.append(chunk) }
        return result.isEmpty ? nil : result
    }

    public func readData(ofLength length: Int) -> Data { (try? read(upToCount: length)) ?? Data() }
    public func readDataToEndOfFile() -> Data { (try? readToEnd()) ?? Data() }

    @discardableResult
    public func seekToEnd() throws -> UInt64 {
        let offset = lseek(fileDescriptor, 0, SEEK_END)
        guard offset >= 0 else { throw ioError() }
        return UInt64(offset)
    }

    public func seek(toOffset offset: UInt64) throws {
        guard lseek(fileDescriptor, off_t(offset), SEEK_SET) >= 0 else { throw ioError() }
    }

    public func offset() throws -> UInt64 {
        let offset = lseek(fileDescriptor, 0, SEEK_CUR)
        guard offset >= 0 else { throw ioError() }
        return UInt64(offset)
    }

    public func synchronize() throws { _ = fsync(fileDescriptor) }

    public func close() throws {
        guard !closed else { return }
        closed = true
        guard WASILibc.close(fileDescriptor) == 0 else { throw ioError() }
    }
}

// MARK: Strings

/// The character sets the engine uses, with Foundation's definitions.
public struct CharacterSet: Sendable {
    private let test: @Sendable (Unicode.Scalar) -> Bool
    private init(_ test: @escaping @Sendable (Unicode.Scalar) -> Bool) { self.test = test }

    public init(charactersIn string: String) {
        let scalars = Set(string.unicodeScalars)
        self.init { scalars.contains($0) }
    }

    public func contains(_ scalar: Unicode.Scalar) -> Bool { test(scalar) }
    public var inverted: CharacterSet { let test = test; return CharacterSet { !test($0) } }
    public func union(_ other: CharacterSet) -> CharacterSet {
        let a = test, b = other.test
        return CharacterSet { a($0) || b($0) }
    }

    /// Unicode general category Zs, and tab.
    public static let whitespaces = CharacterSet { $0 == "\t" || $0.properties.generalCategory == .spaceSeparator }
    /// U+000A–U+000D, U+0085, U+2028, U+2029.
    public static let newlines = CharacterSet { (0x0A...0x0D).contains($0.value) || $0.value == 0x85 || $0.value == 0x2028 || $0.value == 0x2029 }
    /// Unicode general category Z*, U+000A–U+000D and U+0085.
    public static let whitespacesAndNewlines = CharacterSet {
        switch $0.properties.generalCategory {
        case .spaceSeparator, .lineSeparator, .paragraphSeparator: return true
        default: return $0 == "\t" || (0x0A...0x0D).contains($0.value) || $0.value == 0x85
        }
    }
    /// Unicode general category Nd.
    public static let decimalDigits = CharacterSet { $0.properties.generalCategory == .decimalNumber }
    /// Unicode general categories L* and M*.
    public static let letters = CharacterSet {
        switch $0.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
             .nonspacingMark, .spacingMark, .enclosingMark: return true
        default: return false
        }
    }
    /// Unicode general categories L*, M* and N*.
    public static let alphanumerics = CharacterSet {
        switch $0.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
             .nonspacingMark, .spacingMark, .enclosingMark, .decimalNumber, .letterNumber, .otherNumber: return true
        default: return false
        }
    }
}

extension StringProtocol {
    /// Trims unicode scalars in `set` from both ends (as NSString does).
    public func trimmingCharacters(in set: CharacterSet) -> String {
        let scalars = unicodeScalars
        guard let first = scalars.firstIndex(where: { !set.contains($0) }) else { return "" }
        let last = scalars.lastIndex(where: { !set.contains($0) })!
        var trimmed = String.UnicodeScalarView()
        trimmed.append(contentsOf: scalars[first...last])
        return String(trimmed)
    }

    public func components(separatedBy separators: CharacterSet) -> [String] {
        var result: [String] = []
        var current = String.UnicodeScalarView()
        for scalar in unicodeScalars {
            if separators.contains(scalar) {
                result.append(String(current))
                current = String.UnicodeScalarView()
            } else {
                current.append(scalar)
            }
        }
        result.append(String(current))
        return result
    }

    public func rangeOfCharacter(from set: CharacterSet) -> Range<Index>? {
        var index = startIndex
        while index < endIndex {
            let next = self.index(after: index)
            if self[index].unicodeScalars.contains(where: { set.contains($0) }) { return index..<next }
            index = next
        }
        return nil
    }

    public func replacingOccurrences<Target: StringProtocol, Replacement: StringProtocol>(
        of target: Target, with replacement: Replacement
    ) -> String {
        guard !target.isEmpty else { return String(self) }
        return String(self).replacing(String(target), with: String(replacement))
    }

    public func range<T: StringProtocol>(of other: T) -> Range<Index>? {
        guard !other.isEmpty else { return nil }
        return firstRange(of: String(other))
    }
}

extension String {
    /// printf-style formatting through the C library. `%@` is not supported (format Strings
    /// with interpolation).
    public init(format: String, _ arguments: any CVarArg...) {
        self.init(format: format, arguments: arguments)
    }

    public init(format: String, arguments: [any CVarArg]) {
        precondition(!format.contains("%@"), "String(format:) on WASI doesn't support %@")
        self = withVaList(arguments) { list in
            var buffer = [CChar](repeating: 0, count: 256)
            let needed = Int(vsnprintf(&buffer, buffer.count, format, list))
            if needed < buffer.count { return String(cString: buffer) }
            buffer = [CChar](repeating: 0, count: needed + 1)
            return withVaList(arguments) { again in
                _ = vsnprintf(&buffer, buffer.count, format, again)
                return String(cString: buffer)
            }
        }
    }
}

// MARK: Dates

/// `dateFormat` patterns made of yyyy, MM, dd, HH, mm and ss (and literal characters), in the
/// local time zone. That is all the engine formats (file names).
public final class DateFormatter: @unchecked Sendable {
    public var dateFormat: String = ""
    public var locale: Locale?
    public init() {}

    public func string(from date: Date) -> String {
        var seconds = time_t(date.timeIntervalSince1970.rounded(.down))
        var parts = tm()
        localtime_r(&seconds, &parts)
        func pad(_ value: Int32, _ width: Int) -> String {
            let digits = String(value)
            return String(repeating: "0", count: max(0, width - digits.count)) + digits
        }
        var result = ""
        var rest = Substring(dateFormat)
        let tokens: [(String, () -> String)] = [
            ("yyyy", { pad(parts.tm_year + 1900, 4) }), ("MM", { pad(parts.tm_mon + 1, 2) }), ("dd", { pad(parts.tm_mday, 2) }),
            ("HH", { pad(parts.tm_hour, 2) }), ("mm", { pad(parts.tm_min, 2) }), ("ss", { pad(parts.tm_sec, 2) }),
        ]
        outer: while !rest.isEmpty {
            for (token, value) in tokens where rest.hasPrefix(token) {
                result += value()
                rest = rest.dropFirst(token.count)
                continue outer
            }
            result.append(rest.removeFirst())
        }
        return result
    }
}

public final class ISO8601DateFormatter: @unchecked Sendable {
    public init() {}
    public func string(from date: Date) -> String { date.formatted(Date.ISO8601FormatStyle()) }
}

// MARK: JSONSerialization

/// Numbers from `JSONSerialization` (booleans come back as `Bool`).
public final class NSNumber: @unchecked Sendable {
    public let doubleValue: Double
    public init(value: Double) { doubleValue = value }
    public var floatValue: Float { Float(doubleValue) }
    public var intValue: Int { Int(doubleValue) }
    public var int64Value: Int64 { Int64(doubleValue) }
    public var uint64Value: UInt64 { UInt64(doubleValue) }
    public var boolValue: Bool { doubleValue != 0 }
}

/// `jsonObject(with:)` only: objects as `[String: Any]`, arrays as `[Any]`, strings, numbers as
/// `NSNumber`, booleans as `Bool` and null as `NSNull`.
public enum JSONSerialization {
    public struct ReadingOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let mutableContainers = ReadingOptions(rawValue: 1)
        public static let mutableLeaves = ReadingOptions(rawValue: 2)
        public static let fragmentsAllowed = ReadingOptions(rawValue: 4)
    }

    public static func jsonObject(with data: Data, options: ReadingOptions = []) throws -> Any {
        let value = try JSONDecoder().decode(AnyJSON.self, from: data).value
        if !options.contains(.fragmentsAllowed), !(value is [String: Any]), !(value is [Any]) {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "JSON text did not start with an array or object"))
        }
        return value
    }

    private struct AnyJSON: Decodable {
        let value: Any
        private struct Key: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }
        init(from decoder: any Decoder) throws {
            if let object = try? decoder.container(keyedBy: Key.self) {
                var result: [String: Any] = [:]
                for key in object.allKeys { result[key.stringValue] = try object.decode(AnyJSON.self, forKey: key).value }
                value = result
            } else if var array = try? decoder.unkeyedContainer() {
                var result: [Any] = []
                while !array.isAtEnd { result.append(try array.decode(AnyJSON.self).value) }
                value = result
            } else {
                let single = try decoder.singleValueContainer()
                if single.decodeNil() { value = NSNull() }
                else if let bool = try? single.decode(Bool.self) { value = bool }
                else if let number = try? single.decode(Double.self) { value = NSNumber(value: number) }
                else { value = try single.decode(String.self) }
            }
        }
    }
}

public final class NSNull: @unchecked Sendable {
    public init() {}
}

// MARK: Bundle

/// A folder of resources. SwiftPM's `Bundle.module` and Foundation's `Bundle.main` don't work
/// under WASI (they trap), so `main` has no URLs and resource bundles are opened by path
/// (`Bundle.engineResources`, see EngineCore).
public final class Bundle: @unchecked Sendable {
    public let bundleURL: URL
    public var bundlePath: String { bundleURL.path }
    public var resourceURL: URL? { isMain ? nil : bundleURL }
    public var executableURL: URL? { nil }
    private let isMain: Bool

    private init(url: URL, isMain: Bool) {
        bundleURL = url
        self.isMain = isMain
    }

    public convenience init?(url: URL) {
        var isDirectory = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory else { return nil }
        self.init(url: url, isMain: false)
    }

    public convenience init?(path: String) { self.init(url: URL(fileURLWithPath: path, isDirectory: true)) }

    public static let main = Bundle(url: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true), isMain: true)

    public func url(forResource name: String?, withExtension ext: String?, subdirectory: String? = nil) -> URL? {
        guard let name, let resources = resourceURL else { return nil }
        var url = resources
        if let subdirectory { url.appendPathComponent(subdirectory, isDirectory: true) }
        url.appendPathComponent(ext.map { $0.isEmpty ? name : "\(name).\($0)" } ?? name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

// MARK: Errors

public let NSFilePathErrorKey = "NSFilePath"

/// Swift errors have no NSError bridge here: their description.
extension Error {
    public var localizedDescription: String { String(describing: self) }
}

/// `fileExists(atPath:isDirectory:)` takes a `Bool` in FoundationEssentials.
public typealias ObjCBool = Bool

extension Bool {
    public var boolValue: Bool { self }
}

extension StringProtocol {
    /// Decodes %XX escapes as UTF-8; nil if an escape is malformed or the bytes aren't UTF-8.
    public var removingPercentEncoding: String? {
        var bytes: [UInt8] = []
        var utf8 = Array(self.utf8)[...]
        while let byte = utf8.popFirst() {
            guard byte == UInt8(ascii: "%") else { bytes.append(byte); continue }
            guard utf8.count >= 2, let high = hexDigitValue(utf8.removeFirst()), let low = hexDigitValue(utf8.removeFirst()) else { return nil }
            bytes.append(high << 4 | low)
        }
        return String(validating: bytes, as: UTF8.self)
    }
}

private func hexDigitValue(_ c: UInt8) -> UInt8? {
    switch c {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): c - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"): c - UInt8(ascii: "a") + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"): c - UInt8(ascii: "A") + 10
    default: nil
    }
}

// MARK: URL resource values and directory enumeration

/// The resource keys the engine reads. (FoundationEssentials declares an empty `URLResourceKey`;
/// this one shadows it for modules importing WASIFoundation.)
public struct URLResourceKey: Hashable, RawRepresentable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let isDirectoryKey = URLResourceKey("NSURLIsDirectoryKey")
    public static let isRegularFileKey = URLResourceKey("NSURLIsRegularFileKey")
    public static let fileSizeKey = URLResourceKey("NSURLFileSizeKey")
    public static let contentModificationDateKey = URLResourceKey("NSURLContentModificationDateKey")
}

public struct URLResourceValues: Sendable {
    public var isDirectory: Bool?
    public var isRegularFile: Bool?
    public var fileSize: Int?
    public var contentModificationDate: Date?
}

extension URL {
    /// From stat(2) (following a symlink at the URL, like Foundation).
    public func resourceValues(forKeys keys: Set<URLResourceKey>) throws -> URLResourceValues {
        var info = stat()
        guard stat(path, &info) == 0 else { throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path]) }
        var values = URLResourceValues()
        let type = info.st_mode & S_IFMT
        if keys.contains(.isDirectoryKey) { values.isDirectory = type == S_IFDIR }
        if keys.contains(.isRegularFileKey) { values.isRegularFile = type == S_IFREG }
        if keys.contains(.fileSizeKey) { values.fileSize = type == S_IFREG ? Int(info.st_size) : nil }
        if keys.contains(.contentModificationDateKey) {
            let time = info.st_mtim
            values.contentModificationDate = Date(timeIntervalSince1970: Double(time.tv_sec) + Double(time.tv_nsec) / 1e9)
        }
        return values
    }
}

extension FileManager {
    /// Every item under `url`, depth first (each directory before its contents, names in order),
    /// as `URL`s. Honors `.skipsHiddenFiles` and `.skipsSubdirectoryDescendants`.
    public func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?,
                           options mask: DirectoryEnumerationOptions = [],
                           errorHandler handler: ((URL, any Error) -> Bool)? = nil) -> URLDirectoryEnumerator? {
        guard (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { return nil }
        return URLDirectoryEnumerator(root: url, options: mask, errorHandler: handler)
    }

    /// The items directly in `url` (names in order). Honors `.skipsHiddenFiles`.
    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?,
                                    options mask: DirectoryEnumerationOptions = []) throws -> [URL] {
        var names = try contentsOfDirectory(atPath: url.path)
        if mask.contains(.skipsHiddenFiles) { names.removeAll { $0.hasPrefix(".") } }
        return names.sorted().map { url.appendingPathComponent($0) }
    }
}

/// Elements are `URL`s typed `Any`, as with Foundation's `NSEnumerator` (`for case let url as URL in …`).
public final class URLDirectoryEnumerator: Sequence, IteratorProtocol {
    private var stack: [URL] = []
    private let options: FileManager.DirectoryEnumerationOptions
    private let errorHandler: ((URL, any Error) -> Bool)?
    private var pendingDirectory: URL?
    private var stopped = false

    init(root: URL, options: FileManager.DirectoryEnumerationOptions, errorHandler: ((URL, any Error) -> Bool)?) {
        self.options = options
        self.errorHandler = errorHandler
        push(contentsOf: root)
    }

    private func push(contentsOf directory: URL) {
        do {
            var names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            if options.contains(.skipsHiddenFiles) { names.removeAll { $0.hasPrefix(".") } }
            // Reversed so the stack pops them in name order.
            for name in names.sorted().reversed() {
                let child = directory.appendingPathComponent(name)
                let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                stack.append(isDirectory ? directory.appendingPathComponent(name, isDirectory: true) : child)
            }
        } catch {
            if let errorHandler, !errorHandler(directory, error) { stopped = true }
        }
    }

    /// Don't descend into the directory `next()` returned last.
    public func skipDescendants() { pendingDirectory = nil }

    public func next() -> Any? {
        if let directory = pendingDirectory {
            pendingDirectory = nil
            push(contentsOf: directory)
        }
        guard !stopped, let url = stack.popLast() else { return nil }
        if url.hasDirectoryPath && !options.contains(.skipsSubdirectoryDescendants) { pendingDirectory = url }
        return url
    }
}
