// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Metal is always used on Apple platforms. The Vulkan backend (Vulkan + GLFW) is
// always built on Linux/Windows, and on macOS it is built when the Vulkan SDK is
// installed (it then runs on top of MoltenVK — handy for testing the Vulkan path).
// Set ENGINE_DISABLE_VULKAN=1 to skip it on macOS.
// ENGINE_WASM=1: building for WebAssembly (swift build --swift-sdk <wasm sdk>). The manifest is
// evaluated on the host, so it can't see the target triple; this switch turns off what the WASI
// sysroot lacks (Vulkan/GLFW, system zlib). Spike: see docs/wasm-spike.md.
let wasmBuild = ProcessInfo.processInfo.environment["ENGINE_WASM"] != nil

#if os(macOS)
let vulkanEnabled: Bool = {
    if wasmBuild { return false }
    if ProcessInfo.processInfo.environment["ENGINE_DISABLE_VULKAN"] != nil { return false }
    let prefixes = ["/opt/homebrew", "/usr/local"]
    let sdk = ProcessInfo.processInfo.environment["VULKAN_SDK"].map { [$0] } ?? []
    return (prefixes + sdk).contains { FileManager.default.fileExists(atPath: "\($0)/include/vulkan/vulkan.h") }
}()
#else
let vulkanEnabled = true
#endif

// The engine is split into modules so release builds (whole-module optimization, which runs
// one module's optimizer on one core) can compile independent parts in parallel. `Engine` is
// the module everyone imports: it re-exports the rest (Sources/Engine/Exports.swift). Bottom
// up: EngineCore (math, input, logging, resources) → EngineScene (ECS, jobs, persistence) and
// EngineGraphics (the device API) → EngineBackends (Metal/Vulkan, windows), EngineText,
// EnginePhysics, EngineAudio → EngineAssets (database, importers, prefab component data),
// EngineNet, EngineUI → EngineRendering, and beside it EngineMeshBuild (the Mesh Builder's
// algorithms and the importers that run them) → Engine (the Engine class, packaging, game
// modules, editor tools).
var backendDependencies: [Target.Dependency] = []
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
    backendDependencies += ["CVulkan", "CGLFW"]
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

// No zlib in the WASI sysroot; code using it is behind `#if canImport(CZlib)`.
let zlibDependency: [Target.Dependency] = wasmBuild ? [] : ["CZlib"]
// astc-encoder needs std::mutex, which single-threaded WASI's libc++ lacks. A web build only
// loads textures the cooker already encoded, so the codec (`#if canImport(CTextureCodec)`) is left out.
let textureCodecDependency: [Target.Dependency] = wasmBuild ? [] : ["CTextureCodec"]

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

// Windows: a DLL can't leave symbols undefined, so a game module links against its host's
// import library and imports Engine from the running Editor.exe / GameRunner.exe by name. That
// needs Engine compiled with its public symbols exported (dllexport) and its importers using
// dllimport. SwiftPM compiles library targets with -static on Windows, which does neither,
// except targets in a .dynamic product. So on Windows Engine's product is .dynamic: Engine is
// compiled for export, the hosts (same package, so still linked statically) export its symbols
// and get Editor.lib / GameRunner.lib beside them, and game targets in other packages compile
// against it with dllimport. swift build also writes an Engine.dll that nothing loads.
#if os(Windows)
let engineProductType: Product.Library.LibraryType? = .dynamic
#else
let engineProductType: Product.Library.LibraryType? = nil
#endif

// Every engine module is in the Engine product, so on Windows (a .dynamic product) all of them
// are compiled with their public symbols exported.
let engineModules = ["EngineCore", "EngineScene", "EngineGraphics", "EngineBackends", "EngineText", "EnginePhysics", "EngineAudio",
                     "EngineAssets", "EngineMeshBuild", "EngineNet", "EngineUI", "EngineRendering", "Engine"]

// The builder tabs' modules (see the EditorBuilders target).
let editorBuilderModules = ["EditorBuildersMesh", "EditorBuildersWorld", "EditorBuilders2D", "EditorBuildersAnimation", "EditorBuildersLogic"]

// WebAssembly spike: a player with SampleGame linked in, built only with ENGINE_WASM=1.
let wasmSpikeTargets: [Target] = wasmBuild
    ? [.executableTarget(name: "WasmPlayer", dependencies: ["Engine", "SampleGame"], path: "Spikes/WasmPlayer",
                       swiftSettings: [.enableExperimentalFeature("Extern")])]
    : []

let package = Package(
    name: "Acro",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Engine", type: engineProductType, targets: engineModules),
        .library(name: "EngineMCP", targets: ["EngineMCP"]),
        .executable(name: "Demo", targets: ["Demo"]),
        .executable(name: "Editor", targets: ["Editor"]),
        .executable(name: "GameRunner", targets: ["GameRunner"]),
    ],
    // `as [Target]`: without it Swift 6.0's type checker gives up on this expression.
    targets: vulkanTargets + wasmSpikeTargets + ([
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
        .target(name: "EngineCore", dependencies: zlibDependency + ["CStbImage"], resources: [.copy("Shaders"), .copy("Fonts")],
                swiftSettings: engineSwiftSettings, linkerSettings: windowsLinkerSettings),
        .target(name: "EngineScene", dependencies: ["EngineCore"], swiftSettings: engineSwiftSettings, linkerSettings: windowsLinkerSettings),
        .target(name: "EngineGraphics", dependencies: ["EngineCore"] + textureCodecDependency, swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineBackends", dependencies: ["EngineGraphics"] + backendDependencies, swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        // UI/Icons: Lucide icon paths (ISC), see its LICENSES.md.
        .target(name: "EngineText", dependencies: ["EngineScene", "EngineGraphics", "CStbTrueType"], exclude: ["UI/Icons/LICENSES.md"],
                swiftSettings: engineSwiftSettings, linkerSettings: windowsLinkerSettings),
        .target(name: "EnginePhysics", dependencies: ["EngineScene", "EngineGraphics"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineAudio", dependencies: ["EngineScene", "CAudio"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineAssets", dependencies: ["EnginePhysics", "EngineAudio"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        // The Mesh Builder's algorithms (sculpting, looks, AO, LOD, foliage...) and the importers
        // that run them. Nothing below Engine depends on it, so it compiles alongside EngineRendering.
        .target(name: "EngineMeshBuild", dependencies: ["EngineAssets"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineNet", dependencies: ["EnginePhysics"] + zlibDependency, swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineUI", dependencies: ["EngineText", "EngineBackends", "EnginePhysics"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        .target(name: "EngineRendering", dependencies: ["EngineAssets", "EngineText"], swiftSettings: engineSwiftSettings,
                linkerSettings: windowsLinkerSettings),
        // EngineMCP (Foundation only) lets any game host an MCP server (`EngineConfig.mcp`).
        .target(
            name: "Engine",
            dependencies: ["EngineRendering", "EngineMeshBuild", "EngineUI", "EngineNet", "EngineBackends", "EngineAudio", "EngineMCP"] + backendDependencies,
            // WebAssembly: no processes, dynamic loading or Docker. Exporting and building or loading
            // game modules are editor-side; a web build links its game statically.
            exclude: wasmBuild ? ["Packaging/GameExporter.swift", "Packaging/GameExporterDocker.swift", "GameModule/GameModuleBuilder.swift",
                                  "GameModule/GameModuleFastBuild.swift", "GameModule/GameModuleLoader.swift"] : [],
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
        // WebAssembly: no sockets, stdio relay or URLSession; only the protocol core is built.
        .target(name: "EngineMCP", exclude: wasmBuild ? ["MCPStdioRelay.swift", "Socket.swift", "MCPHTTPTransport.swift", "MCPStdioTransport.swift"] : []),
        // The in-engine editor: its logic in EditorCore and the builder tabs' modules (unit-tested
        // by EditorTests), and a thin executable that runs it (`swift run Editor [scene.json]`).
        .target(name: "EditorCore", dependencies: ["Engine", "EngineMCP"], linkerSettings: windowsLinkerSettings),
        // The builder tabs, in modules that depend only on EditorCore so release builds compile
        // them in parallel (EditorCore/EditorBuilders.swift). EditorBuilders registers them all.
        .target(name: "EditorBuildersMesh", dependencies: ["EditorCore", "Engine"], linkerSettings: windowsLinkerSettings),
        .target(name: "EditorBuildersWorld", dependencies: ["EditorCore", "Engine"], linkerSettings: windowsLinkerSettings),
        .target(name: "EditorBuilders2D", dependencies: ["EditorCore", "Engine", "EngineMCP"], linkerSettings: windowsLinkerSettings),
        .target(name: "EditorBuildersAnimation", dependencies: ["EditorCore", "Engine"], linkerSettings: windowsLinkerSettings),
        .target(name: "EditorBuildersLogic", dependencies: ["EditorCore", "Engine"], linkerSettings: windowsLinkerSettings),
        .target(name: "EditorBuilders", dependencies: editorBuilderModules.map { .target(name: $0) } + ["EditorCore"],
                linkerSettings: windowsLinkerSettings),
        .executableTarget(name: "Editor", dependencies: ["EditorCore", "EditorBuilders", "Engine"], linkerSettings: windowsLinkerSettings + exportsSymbols),
        // A game as a game module: built as a target (not a product: a `.dynamic` product would
        // link its own copy of Engine) and linked into a shared library by GameModuleBuilder,
        // which the editor (`--game SampleGame`) and GameRunner load. See README "Game modules".
        .target(name: "SampleGame", dependencies: ["Engine"]),
        // Orbfall: a peg-clearing arcade game (the project at ~/Games/Peggle).
        .target(name: "Orbfall", dependencies: ["Engine"]),
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
        .testTarget(name: "EditorTests", dependencies: ["EditorCore", "EditorBuilders", "Engine", "EngineMCP"] + editorBuilderModules.map { .target(name: $0) },
                    linkerSettings: exportsSymbols),
        .testTarget(name: "EngineMCPTests", dependencies: ["EngineMCP"]),
    ] as [Target])
)
