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
        guard let handle = dlopen(loadedURL.path, RTLD_NOW | RTLD_LOCAL) else {
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
        return LoadedGameModule(module: module, sourceURL: url, loadedURL: loadedURL, handle: handle)
        #else
        throw GameModuleError.unsupported
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
