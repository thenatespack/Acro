// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Metal is always used on Apple platforms. The Vulkan backend (Vulkan + GLFW) is
// always built on Linux/Windows, and on macOS it is built when the Vulkan SDK is
// installed (it then runs on top of MoltenVK — handy for testing the Vulkan path).
// Set ENGINE_DISABLE_VULKAN=1 to skip it on macOS.
#if os(macOS)
let vulkanEnabled: Bool = {
    if ProcessInfo.processInfo.environment["ENGINE_DISABLE_VULKAN"] != nil { return false }
    let prefixes = ["/opt/homebrew", "/usr/local"]
    let sdk = ProcessInfo.processInfo.environment["VULKAN_SDK"].map { [$0] } ?? []
    return (prefixes + sdk).contains { FileManager.default.fileExists(atPath: "\($0)/include/vulkan/vulkan.h") }
}()
#else
let vulkanEnabled = true
#endif

var engineDependencies: [Target.Dependency] = []
var engineSwiftSettings: [SwiftSetting] = []
var vulkanTargets: [Target] = []

if vulkanEnabled {
    #if os(Windows)
    // No pkg-config on Windows. Separate module maps (under Windows/) link vulkan-1 and
    // glfw3; header and library locations come from VULKAN_SDK / GLFW_DIR (see below).
    vulkanTargets = [
        .systemLibrary(name: "CVulkan", path: "Windows/CVulkan"),
        .systemLibrary(name: "CGLFW", path: "Windows/CGLFW"),
    ]
    #else
    vulkanTargets = [
        .systemLibrary(
            name: "CVulkan",
            pkgConfig: "vulkan",
            providers: [.brew(["vulkan-loader", "vulkan-headers", "molten-vk"]), .apt(["libvulkan-dev"])]
        ),
        .systemLibrary(
            name: "CGLFW",
            pkgConfig: "glfw3",
            providers: [.brew(["glfw"]), .apt(["libglfw3-dev"])]
        ),
    ]
    #endif
    engineDependencies += ["CVulkan", "CGLFW"]
    engineSwiftSettings.append(.define("ENGINE_VULKAN"))
}

// Windows: point the compiler and linker at the Vulkan SDK ($VULKAN_SDK\Include, \Lib) and GLFW
// ($GLFW_DIR\include, \lib). These use unsafeFlags, so on Windows this package can only be
// built as a root package, not consumed as a dependency. Without the env vars, set
// CPATH / LIB yourself or pass -Xcc -I... -Xlinker /LIBPATH:... on the command line.
var windowsLinkerSettings: [LinkerSetting] = []
#if os(Windows)
if vulkanEnabled {
    let env = ProcessInfo.processInfo.environment
    var cFlags: [String] = []
    var libFlags: [String] = []
    if let sdk = env["VULKAN_SDK"] {
        cFlags += ["-Xcc", "-I\(sdk)\\Include"]
        libFlags += ["-L\(sdk)\\Lib"]
    }
    if let glfw = env["GLFW_DIR"] {
        cFlags += ["-Xcc", "-I\(glfw)\\include"]
        libFlags += ["-L\(glfw)\\lib"]
    }
    if !cFlags.isEmpty { engineSwiftSettings.append(.unsafeFlags(cFlags)) }
    if !libFlags.isEmpty { windowsLinkerSettings = [.unsafeFlags(libFlags)] }
}
#endif

let package = Package(
    name: "SwiftGameEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Engine", targets: ["Engine"]),
        .executable(name: "Demo", targets: ["Demo"]),
    ],
    targets: vulkanTargets + [
        .target(
            name: "Engine",
            dependencies: engineDependencies,
            resources: [.copy("Shaders")],
            swiftSettings: engineSwiftSettings,
            linkerSettings: windowsLinkerSettings
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["Engine"],
            resources: [.copy("Shaders")],
            linkerSettings: windowsLinkerSettings
        ),
        .testTarget(name: "EngineTests", dependencies: ["Engine"]),
    ]
)
