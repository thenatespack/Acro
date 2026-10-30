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

var engineDependencies: [Target.Dependency] = ["CZlib"]
var engineSwiftSettings: [SwiftSetting] = []
var vulkanTargets: [Target] = []

if vulkanEnabled {
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
    engineDependencies += ["CVulkan", "CGLFW"]
    engineSwiftSettings.append(.define("ENGINE_VULKAN"))
}

let package = Package(
    name: "SwiftGameEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Engine", targets: ["Engine"]),
        .executable(name: "Demo", targets: ["Demo"]),
    ],
    targets: vulkanTargets + [
        // zlib for the PNG writer (Image.swift). Ships with macOS and virtually every Linux distro.
        .systemLibrary(
            name: "CZlib",
            pkgConfig: "zlib",
            providers: [.apt(["zlib1g-dev"]), .brew(["zlib"])]
        ),
        .target(
            name: "Engine",
            dependencies: engineDependencies,
            resources: [.copy("Shaders")],
            swiftSettings: engineSwiftSettings
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["Engine"],
            resources: [.copy("Shaders")]
        ),
        .testTarget(name: "EngineTests", dependencies: ["Engine", "CZlib"]),
    ]
)
