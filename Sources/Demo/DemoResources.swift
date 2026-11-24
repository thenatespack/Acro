import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

extension Bundle {
    /// The Demo's resources (Shaders/, Models/). In a browser (WASI) `Bundle.module` traps, so
    /// the page mounts them in the WASI filesystem at `DEMO_RESOURCES` (default /demo).
    static var demo: Bundle {
        #if os(WASI)
        let path = ProcessInfo.processInfo.environment["DEMO_RESOURCES"] ?? "/demo"
        guard let bundle = Bundle(path: path) else { fatalError("No Demo resources at \(path) (set DEMO_RESOURCES)") }
        return bundle
        #else
        .module
        #endif
    }

    /// A model in the Demo's Models/ folder.
    static func demoModel(_ name: String) -> URL? {
        demo.engineResourceURL(name, withExtension: "glb", subdirectory: "Models")
    }
}
