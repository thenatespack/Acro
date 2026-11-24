#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

extension Bundle {
    /// The engine's resource bundle: shaders under `Shaders/`, fonts under `Fonts/`. The engine
    /// is several modules, but its resources live in this one, so code in any of them loads
    /// them through this rather than its own `Bundle.module`.
    package static var engineResources: Bundle {
        #if os(WASI)
        // SwiftPM's `Bundle.module` locates resources from `Bundle.main`, which traps under WASI.
        // Spike: the resource folder is mounted at `ENGINE_RESOURCES` (default /engine).
        wasmEngineResources
        #else
        .module
        #endif
    }
}

#if os(WASI)
private let wasmEngineResources: Bundle = {
    let path = ProcessInfo.processInfo.environment["ENGINE_RESOURCES"] ?? "/engine"
    guard let bundle = Bundle(path: path) else { fatalError("No engine resources at \(path) (set ENGINE_RESOURCES)") }
    return bundle
}()
#endif

extension Bundle {
    /// `url(forResource:withExtension:subdirectory:)`, which the engine uses for every resource
    /// lookup. Under WASI, Foundation's version drops the extension's last character
    /// (swift-corelibs-foundation, Swift 6.4.2: "Inter-Regular.ttf" comes back as
    /// "Inter-Regular.tt"), so there the path is built directly.
    package func engineResourceURL(_ name: String, withExtension ext: String?, subdirectory: String?) -> URL? {
        #if os(WASI)
        var url = bundleURL
        if let subdirectory { url.appendPathComponent(subdirectory, isDirectory: true) }
        url.appendPathComponent(ext.map { $0.isEmpty ? name : "\(name).\($0)" } ?? name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
        #else
        url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        #endif
    }
}
