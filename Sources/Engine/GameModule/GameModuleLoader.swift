import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Errors from building, linking and loading game modules.
public enum GameModuleError: Error, Equatable, CustomStringConvertible {
    /// No file at the path.
    case notFound(String)
    /// `dlopen` failed (often a missing Engine symbol: the module was built against other Engine sources).
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

/// A game module loaded into this process (`GameModuleLoader.load`).
///
/// The library stays mapped for the life of the process, also after the host lets go of the
/// module: the Swift runtime caches type metadata and protocol conformances from loaded
/// images and has no way to forget them, and Darwin's dyld doesn't unmap images with Swift or
/// Objective-C metadata anyway. Unloading a module means detaching everything that refers to
/// its types (see the editor's `EditorGameModule`); the old code is never called again. Each
/// load maps a new copy under a unique name, so a rebuilt library always loads afresh.
@MainActor
public final class LoadedGameModule {
    /// What the module registered.
    public let module: GameModule
    /// The library that was loaded (before copying).
    public let sourceURL: URL
    /// The uniquely named copy that is mapped.
    public let loadedURL: URL
    /// When it was loaded.
    public let loadedAt = Date()
    /// How many "Class X is implemented in both" warnings the Objective-C runtime printed while
    /// mapping it (filtered out; see `GameModuleLoader.load`).
    public internal(set) var duplicateClassWarnings = 0
    let handle: UnsafeMutableRawPointer

    init(module: GameModule, sourceURL: URL, loadedURL: URL, handle: UnsafeMutableRawPointer) {
        self.module = module
        self.sourceURL = sourceURL
        self.loadedURL = loadedURL
        self.handle = handle
    }
}

/// Loads game modules (see GameModule.swift).
@MainActor
public enum GameModuleLoader {
    private static var loads = 0

    /// Where loaded copies go: a folder per process under the temporary directory.
    public static var copiesFolder: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-game-modules", isDirectory: true)
            .appendingPathComponent(String(ProcessInfo.processInfo.processIdentifier), isDirectory: true)
    }

    /// Copies the library at `url` to a unique name (unless `copy` is false: the caller made
    /// a unique file already), maps it, checks it and calls its entry point.
    public static func load(_ url: URL, copy: Bool = true) throws -> LoadedGameModule {
        #if os(macOS) || os(Linux)
        guard FileManager.default.fileExists(atPath: url.path) else { throw GameModuleError.notFound(url.path) }
        let loadedURL = copy ? try makeCopy(of: url) : url
        // RTLD_LOCAL: two versions of a module may define the same symbols.
        let (opened, duplicates) = filteringDuplicateClassWarnings { dlopen(loadedURL.path, RTLD_NOW | RTLD_LOCAL) }
        guard let handle = opened else {
            throw GameModuleError.loadFailed(dlerror().map { String(cString: $0) } ?? "dlopen failed")
        }
        // A copy of Engine inside the module would define the marker at another address.
        if let theirs = dlsym(handle, GameModuleABI.engineMarker), theirs != swiftGameEngineHostMarkerAddress {
            throw GameModuleError.embedsEngine(url.lastPathComponent)
        }
        guard let symbol = dlsym(handle, GameModuleABI.entryPoint) else {
            throw GameModuleError.noEntryPoint(url.lastPathComponent)
        }
        typealias Entry = @convention(c) (UnsafeMutableRawPointer) -> Int32
        let entry = unsafeBitCast(symbol, to: Entry.self)
        let module = GameModule()
        let version = withExtendedLifetime(module) { entry(Unmanaged.passUnretained(module).toOpaque()) }
        guard version == GameModuleABI.version else { throw GameModuleError.versionMismatch(version) }
        if module.name.isEmpty { module.name = url.deletingPathExtension().lastPathComponent }
        let loaded = LoadedGameModule(module: module, sourceURL: url, loadedURL: loadedURL, handle: handle)
        loaded.duplicateClassWarnings = duplicates
        return loaded
        #else
        throw GameModuleError.unsupported
        #endif
    }

    /// Runs `body` (a `dlopen`) with standard error going to a temporary file, then passes on
    /// what was printed except the Objective-C runtime's "Class X is implemented in both A
    /// and B" lines, returning how many it dropped.
    ///
    /// Every Swift class on Darwin, not only NSObject subclasses, is registered with the
    /// Objective-C runtime under its mangled name, so mapping a second copy of a module
    /// (a reload) re-registers the same names and the runtime warns once per class. Here that
    /// is expected and harmless: Swift code finds types through metadata pointers, not class
    /// names, and the old copy is never called again. The only way to avoid the registration
    /// is a different module name per build, which SwiftPM-built objects can't have. Lines
    /// from other threads in that window are passed on after it, in order.
    static func filteringDuplicateClassWarnings<T>(_ body: () -> T) -> (T, Int) {
        #if canImport(Darwin)
        var template = Array((NSTemporaryDirectory() + "game-module-stderr-XXXXXX").utf8CString)
        let file = template.withUnsafeMutableBufferPointer { mkstemp($0.baseAddress!) }
        guard file >= 0 else { return (body(), 0) }
        let path = String(cString: template)
        unlink(path)
        fflush(stderr)
        let saved = dup(2)
        dup2(file, 2)
        let result = body()
        fflush(stderr)
        dup2(saved, 2)
        close(saved)
        lseek(file, 0, SEEK_SET)
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            let count = buffer.withUnsafeMutableBytes { read(file, $0.baseAddress, $0.count) }
            if count <= 0 { break }
            data.append(contentsOf: buffer[0..<count])
        }
        close(file)
        var dropped = 0
        let kept = String(decoding: data, as: UTF8.self).split(separator: "\n", omittingEmptySubsequences: false).filter { line in
            let duplicate = line.hasPrefix("objc[") && line.contains(" is implemented in both ")
            if duplicate { dropped += 1 }
            return !duplicate
        }.joined(separator: "\n")
        if !kept.isEmpty { FileHandle.standardError.write(Data(kept.utf8)) }
        return (result, dropped)
        #else
        return (body(), 0)
        #endif
    }

    /// A unique path in `copiesFolder` for a new copy of a library named like `url`.
    public static func uniqueCopyURL(for url: URL) throws -> URL {
        let folder = copiesFolder
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        loads += 1
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.isEmpty ? libraryExtension : url.pathExtension
        return folder.appendingPathComponent("\(base)-\(loads).\(ext)")
    }

    private static func makeCopy(of url: URL) throws -> URL {
        let destination = try uniqueCopyURL(for: url)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    /// "dylib" on Apple platforms, "so" elsewhere.
    public static var libraryExtension: String {
        #if canImport(Darwin)
        "dylib"
        #else
        "so"
        #endif
    }
}
