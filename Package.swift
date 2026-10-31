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

// EngineMCP (Foundation only) lets any game host an MCP server (`EngineConfig.mcp`).
var engineDependencies: [Target.Dependency] = ["CZlib", "CStbTrueType", "CStbImage", "CAudio", "CTextureCodec", "EngineMCP"]
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

// Windows: point the compiler and linker at the Vulkan SDK ($VULKAN_SDK\Include, \Lib), GLFW
// ($GLFW_DIR\include, \lib) and zlib ($ZLIB_DIR\include, \lib). These use unsafeFlags, so on
// Windows this package can only be built as a root package, not consumed as a dependency.
// Without the env vars, set CPATH / LIB yourself or pass -Xcc -I... -Xlinker /LIBPATH:... on
// the command line.
var windowsLinkerSettings: [LinkerSetting] = []
#if os(Windows)
do {
    let env = ProcessInfo.processInfo.environment
    var cFlags: [String] = []
    var libFlags: [String] = []
    var dirs: [String] = env["ZLIB_DIR"].map { [$0] } ?? []
    if vulkanEnabled, let sdk = env["VULKAN_SDK"] {
        cFlags += ["-Xcc", "-I\(sdk)\\Include"]
        libFlags += ["-L\(sdk)\\Lib"]
    }
    if vulkanEnabled, let glfw = env["GLFW_DIR"] { dirs.append(glfw) }
    for dir in dirs {
        cFlags += ["-Xcc", "-I\(dir)\\include"]
        libFlags += ["-L\(dir)\\lib"]
    }
    if !cFlags.isEmpty { engineSwiftSettings.append(.unsafeFlags(cFlags)) }
    if !libFlags.isEmpty { windowsLinkerSettings = [.unsafeFlags(libFlags)] }
}
#endif

// zlib for the PNG writer (Image.swift). Ships with macOS and virtually every Linux distro;
// on Windows it comes from vcpkg or similar (see ZLIB_DIR above).
#if os(Windows)
let zlibTarget: Target = .systemLibrary(name: "CZlib", path: "Windows/CZlib")
#else
let zlibTarget: Target = .systemLibrary(
    name: "CZlib",
    pkgConfig: "zlib",
    providers: [.apt(["zlib1g-dev"]), .brew(["zlib"])]
)
#endif

// The block-compression encoders (CTextureCodec) are optimized in debug builds too: unoptimized,
// astc-encoder's SIMD wrappers are many times slower (an uncached debug cook of SampleGame: 17 s
// instead of 2.8 s), and debug editors and tests encode. That needs unsafeFlags, which SwiftPM
// refuses in packages used as versioned dependencies, so they are only added when this package
// is not such a checkout. SwiftPM (.build/checkouts, or <--scratch-path>/checkouts) and Xcode
// (SourcePackages/checkouts) put dependencies in a folder named "checkouts". See README "Building".
let isDependencyCheckout = URL(fileURLWithPath: Context.packageDirectory).deletingLastPathComponent().lastPathComponent == "checkouts"
let textureCodecCFlags: [CSetting] = isDependencyCheckout ? [] : [.unsafeFlags(["-O2"], .when(configuration: .debug))]
let textureCodecCXXFlags: [CXXSetting] = isDependencyCheckout ? [] : [.unsafeFlags(["-O2"], .when(configuration: .debug))]

// Game modules (Sources/Engine/GameModule) resolve Engine's symbols against the host process
// when loaded, so hosts export them: executables do on macOS; on Linux they need
// --export-dynamic. unsafeFlags, so only in a checkout of this package (see above).
let exportsSymbols: [LinkerSetting] = isDependencyCheckout ? [] : [.unsafeFlags(["-Xlinker", "--export-dynamic"], .when(platforms: [.linux]))]

let package = Package(
    name: "SwiftGameEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Engine", targets: ["Engine"]),
        .library(name: "EngineMCP", targets: ["EngineMCP"]),
        .executable(name: "Demo", targets: ["Demo"]),
        .executable(name: "Editor", targets: ["Editor"]),
        .executable(name: "GameRunner", targets: ["GameRunner"]),
    ],
    // `as [Target]`: without it Swift 6.0's type checker gives up on this expression.
    targets: vulkanTargets + ([
        zlibTarget,
        // Vendored stb_truetype (public domain): font parsing, kerning and SDF glyph rasterization.
        .target(name: "CStbTrueType"),
        // Vendored stb_image v2.30 (public domain): PNG/JPEG/TGA/HDR decoding from memory.
        .target(name: "CStbImage"),
        // Vendored audio: miniaudio (device output on Linux/Windows), stb_vorbis and dr_mp3
        // (decoders); public domain / MIT-0. See Sources/CAudio/LICENSES.md.
        .target(
            name: "CAudio",
            exclude: ["LICENSES.md"],
            linkerSettings: [.linkedLibrary("dl", .when(platforms: [.linux])), .linkedLibrary("pthread", .when(platforms: [.linux])),
                             .linkedLibrary("m", .when(platforms: [.linux]))]
        ),
        // Vendored texture block compression: bc7enc / bc7decomp (MIT or public domain), Convection
        // Texture Tools' BC6H kernels (MIT) and Arm's astc-encoder 5.7.0 library sources (Apache-2.0). See Sources/CTextureCodec/LICENSES.md.
        .target(
            name: "CTextureCodec",
            exclude: ["LICENSES.md", "vendor/bc7enc/LICENSE", "vendor/astcenc/LICENSE.txt", "vendor/cvtt/LICENSE.txt"],
            cSettings: textureCodecCFlags,
            // Only 4x4 blocks are used: smaller per-block working sets.
            cxxSettings: [.define("ASTCENC_BLOCK_MAX_TEXELS", to: "16")] + textureCodecCXXFlags
        ),
        .target(
            name: "Engine",
            dependencies: engineDependencies,
            // UI/Icons: Lucide icon paths (ISC), see its LICENSES.md.
            exclude: ["UI/Icons/LICENSES.md"],
            resources: [.copy("Shaders"), .copy("Fonts")],
            swiftSettings: engineSwiftSettings,
            linkerSettings: windowsLinkerSettings
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["Engine"],
            resources: [.copy("Shaders"), .copy("Models")],
            linkerSettings: windowsLinkerSettings
        ),
        // A Model Context Protocol server (JSON-RPC, stdio and Streamable HTTP transports, JSON
        // Schemas from Codable types). Foundation only, so games can embed it too.
        .target(name: "EngineMCP"),
        // The in-engine editor: all logic in EditorCore (unit-tested by EditorTests), and a
        // thin executable that runs it (`swift run Editor [scene.json]`).
        .target(name: "EditorCore", dependencies: ["Engine", "EngineMCP"], linkerSettings: windowsLinkerSettings),
        .executableTarget(name: "Editor", dependencies: ["EditorCore", "Engine"], linkerSettings: windowsLinkerSettings + exportsSymbols),
        // A game as a game module: built as a target (not a product: a `.dynamic` product would
        // link its own copy of Engine) and linked into a shared library by GameModuleBuilder,
        // which the editor (`--game SampleGame`) and GameRunner load. See README "Game modules".
        .target(name: "SampleGame", dependencies: ["Engine"]),
        // Runs a game module standalone: `swift run GameRunner SampleGame [scene.json]`.
        .executableTarget(name: "GameRunner", dependencies: ["Engine"], linkerSettings: windowsLinkerSettings + exportsSymbols),
        // A changed version of SampleGame for GameModuleTests' reload test (linked like it).
        .target(name: "GameModuleTestFixture", dependencies: ["Engine"], path: "Tests/GameModuleTestFixture"),
        // A game made of two targets for GameModuleReloadTests: the game target and a library target it uses.
        .target(name: "GameModuleTestLibrary", dependencies: ["Engine"], path: "Tests/GameModuleTestLibrary"),
        .target(name: "GameModuleTestMultiTarget", dependencies: ["Engine", "GameModuleTestLibrary"], path: "Tests/GameModuleTestMultiTarget"),
        // ENGINE_VULKAN lets GPU tests (ComputeTests) run on the Vulkan backend too.
        .testTarget(name: "EngineTests", dependencies: ["Engine", "CZlib"], resources: [.copy("Resources")],
                    swiftSettings: vulkanEnabled ? [.define("ENGINE_VULKAN")] : []),
        .testTarget(name: "EditorTests", dependencies: ["EditorCore", "Engine", "EngineMCP"], linkerSettings: exportsSymbols),
        .testTarget(name: "EngineMCPTests", dependencies: ["EngineMCP"]),
    ] as [Target])
)
