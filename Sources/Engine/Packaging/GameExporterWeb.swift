#if !os(WASI)
import Foundation
import EngineAssets
import EngineCore

// The Web export (`CookPlatform.web`): the game as one static folder any web server can host.
//
// ```
// <out>/<Name>/index.html, loader.js, saves.js   the page and its loader (the engine's Web/, as is)
//              app/<Target>Player.wasm    the player (Engine + game), packaged by JavaScriptKit's PackageToJS
//              app/instantiate.js, runtime.js, …   PackageToJS's JS glue
//              vendor/browser_wasi_shim/  the WASI shim the glue was made for (@bjorn3/browser_wasi_shim)
//              webgl2.js                  the WebGL 2 renderer's side in JavaScript (the fallback without WebGPU)
//              engine/manifest.json       the engine resources the loader fetches: Shaders/*.wgsl, *.gles and Fonts/
//              game.pack, player.json     the cooked pack, and what the loader starts (wasm, pack, engine)
//              README.txt                 how to host it
// ```
//
// - **Build.** The same generated player package as the other targets (its own copy in
//   `.build/game-export-web/<Target>`), built with the open-source Swift toolchain (swiftly,
//   `~/.swiftly/bin/swift`) and the Swift SDK for WebAssembly, `ENGINE_WASM=1` (the engine's
//   manifest then leaves out what WASI lacks), and packaged by `swift package js` (JavaScriptKit,
//   a dependency of the generated package). docs/wasm-spike.md has the details.
// - **Size.** Release: the linker drops DWARF (`--strip-debug`), then `wasm-opt -Oz` (binaryen,
//   when installed) shrinks the module. Without wasm-opt the export says so and ships it as built.
//   SampleGame (2026-11-23): 79.0 MB linked, 54.5 MB after -Oz (-Os: 55.0 MB, same 45-60 s), 21.5 MB
//   gzip -9, 14.2 MB brotli -q 11. The report gives the gzip and brotli sizes of release exports.
// - **Engine resources.** Only what the web backends read: WGSL (WebGPU) and GLSL ES (WebGL 2)
//   shaders (no Metal or SPIR-V), and the fonts.
// - **Renderer.** `renderer` in player.json (`GameExportOptions.webRenderer`, default auto): WebGPU,
//   else WebGL 2; the player can switch (see Web/loader.js).
// - **Hosting.** Any static server; `.wasm` must be served as `application/wasm`. A WebGPU or WebGL 2 browser.
//   Scripts/web-player.sh `--export` builds and serves an export locally.

/// The tools a Web export needs: the open-source Swift toolchain with the WebAssembly SDK, and
/// optionally binaryen's `wasm-opt`, `npm` (to fetch the WASI shim once) and gzip / brotli (sizes).
public struct WebToolchain: Sendable, Equatable {
    /// The Swift SDK the engine is built with for the web (docs/wasm-spike.md).
    public static let defaultSDK = "swift-6.4.2-RELEASE_wasm"
    /// The JavaScriptKit the generated package asks for (the engine's Package.swift's).
    public static let javaScriptKitVersion = "0.63.0"
    /// The wasm-opt level release exports use (`ACRO_WASM_OPT` overrides it: "-Os", "-O3", or "none").
    public static let defaultOptimizationLevel = "-Oz"

    /// The toolchain's `swift` (`ACRO_WASM_SWIFT`, else `~/.swiftly/bin/swift`).
    public var swift: URL
    /// The Swift SDK's id (`ACRO_WASM_SDK`, else `defaultSDK`).
    public var sdk: String
    /// Why a Web export can't be built here, or nil.
    public var problem: String?
    public var wasmOpt: URL?
    public var optimizationLevel: String?
    public var npm: URL?
    public var gzip: URL?
    public var brotli: URL?

    /// This machine's (looked up once per process: restart the editor after installing).
    public static func find() -> WebToolchain { cached }
    private static let cached = find(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())

    /// The tools for `environment` and the home folder `home` (no processes are run).
    public static func find(environment: [String: String], home: String) -> WebToolchain {
        let fm = FileManager.default
        let swift = URL(fileURLWithPath: environment["ACRO_WASM_SWIFT"].flatMap { $0.isEmpty ? nil : $0 } ?? "\(home)/.swiftly/bin/swift")
        let sdk = environment["ACRO_WASM_SDK"].flatMap { $0.isEmpty ? nil : $0 } ?? defaultSDK
        let level = environment["ACRO_WASM_OPT"].flatMap { $0.isEmpty ? nil : $0 } ?? defaultOptimizationLevel
        let tool = { (name: String) in tool(name, environment: environment, home: home) }
        var toolchain = WebToolchain(swift: swift, sdk: sdk, problem: nil, wasmOpt: tool("wasm-opt"),
                                     optimizationLevel: level == "none" ? nil : level, npm: tool("npm"), gzip: tool("gzip"),
                                     brotli: tool("brotli"))
        if !fm.isExecutableFile(atPath: swift.path) {
            toolchain.problem = "Web export needs the open-source Swift 6.4.2 toolchain (Xcode's can't build for WebAssembly), "
                + "which isn't at \(swift.path): install swiftly (https://www.swift.org/install), then run `swiftly install 6.4.2`. "
                + "ACRO_WASM_SWIFT can name another swift."
        } else if !sdkInstalled(sdk, home: home, environment: environment) {
            toolchain.problem = "Web export needs the Swift SDK for WebAssembly (\(sdk)), which isn't installed: run "
                + "`\(swift.path) sdk install <url> --checksum <checksum>` with the \(sdk).artifactbundle.tar.gz link and checksum "
                + "from https://www.swift.org/install (Swift SDK for WebAssembly). ACRO_WASM_SDK can name another SDK."
        }
        return toolchain
    }

    /// Where SwiftPM keeps installed Swift SDKs.
    static func sdkFolders(home: String, environment: [String: String]) -> [URL] {
        var folders = ["\(home)/Library/org.swift.swiftpm/swift-sdks", "\(home)/.swiftpm/swift-sdks",
                       "\(environment["XDG_CONFIG_HOME"] ?? "\(home)/.config")/swiftpm/swift-sdks"]
        if let custom = environment["SWIFTPM_SWIFT_SDKS_PATH"] { folders.insert(custom, at: 0) }
        return folders.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    /// Whether an installed artifact bundle provides the Swift SDK `id` (its info.json lists it).
    static func sdkInstalled(_ id: String, home: String, environment: [String: String]) -> Bool {
        let fm = FileManager.default
        for folder in sdkFolders(home: home, environment: environment) {
            for bundle in (try? fm.contentsOfDirectory(atPath: folder.path)) ?? [] where bundle.hasSuffix(".artifactbundle") {
                let info = folder.appendingPathComponent(bundle).appendingPathComponent("info.json")
                guard let data = fm.contents(atPath: info.path),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let artifacts = json["artifacts"] as? [String: Any] else { continue }
                if artifacts[id] != nil { return true }
            }
        }
        return false
    }

    /// `name` in PATH, else where Homebrew, swiftly and system installs put it (an app started
    /// from Finder has a short PATH).
    static func tool(_ name: String, environment: [String: String], home: String) -> URL? {
        let path = environment["PATH"]?.split(separator: ":").map(String.init) ?? []
        return (path + ["/opt/homebrew/bin", "/usr/local/bin", "\(home)/.swiftly/bin", "/usr/bin", "/bin"]).lazy
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}

/// The renderer a Web export's page starts with (`renderer` in player.json; Web/loader.js). A
/// `?renderer=` page option and the player's saved choice (`WebHost.setRenderer`) come first.
public enum WebRenderer: String, Sendable, Codable, CaseIterable {
    /// WebGPU when the browser has it (an adapter and a device come up), else WebGL 2.
    case auto
    case webgpu
    /// WebGL 2 even where WebGPU works (no compute: no GPU particles, light probes or material graphs).
    case webgl2

    public var title: String {
        switch self {
        case .auto: "Auto (WebGPU, else WebGL 2)"
        case .webgpu: "WebGPU"
        case .webgl2: "WebGL 2"
        }
    }
}

/// What a Web export's folder is made of (GameExporter.assembleWebSite).
struct WebSiteInputs {
    /// The engine's `Web/` (index.html, loader.js, saves.js).
    var page: URL
    /// PackageToJS's output folder (`<wasm name>`, instantiate.js, …).
    var packaged: URL
    /// The WASI shim's `dist` folder.
    var wasiShim: URL
    /// The engine's resources (Shaders/, Fonts/), as built or as in Sources/EngineCore.
    var engineResources: URL
    /// The cooked pack.
    var pack: URL
}

extension GameExporter {
    /// The pack's name in a Web export's folder (player.json names it).
    static let webPackFile = "game.pack"

    /// Whether a file of the engine's resources (path relative to them) goes into a Web export:
    /// WGSL and GLSL ES shaders only (the Metal and SPIR-V ones are for the native backends),
    /// everything else (the fonts and their licence) but the bundle's Info.plist.
    static func isWebEngineResource(_ path: String) -> Bool {
        if path == "Info.plist" || path.hasSuffix("/.DS_Store") || path == ".DS_Store" { return false }
        if path.hasPrefix("Shaders/") { return path.hasSuffix(".wgsl") || path.hasSuffix(".gles") }
        return true
    }

    /// `player.json`: what Web/loader.js starts. `packSize` and `wasmSize` (bytes) let the page
    /// show download progress when the server doesn't say how big they are (or compresses them);
    /// `packHash` (`packHash(of:)`) names the pack in the browser's cache, so a new export is
    /// downloaded again. `renderer` is the one the page starts with (`WebRenderer`).
    static func webPlayerConfig(wasm: String, packName: String, packSize: Int? = nil, packHash: String? = nil,
                                wasmSize: Int? = nil, renderer: WebRenderer = .auto) -> [String: Any] {
        var config: [String: Any] = ["wasm": "app/\(wasm)", "pack": webPackFile, "packName": packName, "engine": "engine/manifest.json",
                                     "args": [String](), "renderer": renderer.rawValue]
        if let packSize { config["packSize"] = packSize }
        if let packHash { config["packHash"] = packHash }
        if let wasmSize { config["wasmSize"] = wasmSize }
        return config
    }

    /// Writes `site`'s player.json for its pack and wasm as they are now.
    static func writeWebPlayerConfig(site: URL, wasmName: String, packName: String, renderer: WebRenderer = .auto) throws {
        let pack = site.appendingPathComponent(webPackFile), wasm = site.appendingPathComponent("app/\(wasmName)")
        let config = webPlayerConfig(wasm: wasmName, packName: packName, packSize: fileSize(pack), packHash: packHash(of: pack),
                                     wasmSize: fileSize(wasm), renderer: renderer)
        try json(config).write(to: site.appendingPathComponent("player.json"))
    }

    private static func fileSize(_ url: URL) -> Int? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue
    }

    /// The hash in a pack's header (its table of contents', which lists every blob's hash): it
    /// changes whenever the pack's content does.
    static func packHash(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 48), header.count == 48 else { return nil }
        let hash = String(decoding: header[32..<48], as: UTF8.self)
        return hash.allSatisfy(\.isHexDigit) ? hash : nil
    }

    /// Lays out a Web export in `folder` (made, or replaced) from `inputs` (see the notes at the
    /// top of the file); returns the engine files it copied, relative to `engine/`.
    @discardableResult
    static func assembleWebSite(at folder: URL, inputs: WebSiteInputs, wasmName: String, packName: String, gameName: String,
                                renderer: WebRenderer = .auto) throws -> [String] {
        let fm = FileManager.default
        try? fm.removeItem(at: folder)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        for page in ["index.html", "loader.js", "saves.js", "webgl2.js"] {
            try fm.copyItem(at: inputs.page.appendingPathComponent(page), to: folder.appendingPathComponent(page))
        }
        try fm.copyItem(at: inputs.packaged, to: folder.appendingPathComponent("app", isDirectory: true))
        let vendor = folder.appendingPathComponent("vendor", isDirectory: true)
        try fm.createDirectory(at: vendor, withIntermediateDirectories: true)
        let shim = vendor.appendingPathComponent("browser_wasi_shim", isDirectory: true)
        try fm.copyItem(at: inputs.wasiShim, to: shim)
        // Its licences (next to `dist` in the npm package).
        let shimPackage = inputs.wasiShim.deletingLastPathComponent()
        for license in ((try? fm.contentsOfDirectory(atPath: shimPackage.path)) ?? []).sorted() where license.hasPrefix("LICENSE") {
            try? fm.copyItem(at: shimPackage.appendingPathComponent(license), to: shim.appendingPathComponent(license))
        }

        let engine = folder.appendingPathComponent("engine", isDirectory: true)
        var files: [String] = []
        let root = inputs.engineResources.resolvingSymlinksInPath().standardizedFileURL
        if let walker = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let file as URL in walker where (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                let path = String(file.resolvingSymlinksInPath().standardizedFileURL.path.dropFirst(root.path.count + 1))
                guard isWebEngineResource(path) else { continue }
                let destination = engine.appendingPathComponent(path)
                try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fm.copyItem(at: file, to: destination)
                files.append(path)
            }
        }
        files.sort()
        try fm.createDirectory(at: engine, withIntermediateDirectories: true)
        try json(["files": files]).write(to: engine.appendingPathComponent("manifest.json"))
        try fm.copyItem(at: inputs.pack, to: folder.appendingPathComponent(webPackFile))
        try writeWebPlayerConfig(site: folder, wasmName: wasmName, packName: packName, renderer: renderer)
        try Data(webReadme(name: gameName).utf8).write(to: folder.appendingPathComponent("README.txt"))
        return files
    }

    private static func json(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) + Data("\n".utf8)
    }

    static func webReadme(name: String) -> String {
        """
        \(name): a web build (exported by the Acro engine)

        This folder is a static website. Upload all of it to any web server or static host (GitHub
        Pages, Netlify, S3, nginx, Apache, ...) and open index.html there. Opening index.html from
        the disk (file://) doesn't work: browsers only load WebAssembly over HTTP(S).

        Hosting
        - Serve .wasm files as application/wasm (most servers and hosts already do). With another
          type the browser refuses to compile the game.
        - Turn on gzip or brotli compression if the host offers it: the .wasm is much smaller
          compressed.
        - Nothing else is needed: no special headers (no cross-origin isolation), no server code.

        Trying it locally
            python3 -m http.server 8080      (in this folder), then open http://localhost:8080/

        Browsers
        The game renders with WebGPU where the browser has it (a recent Chrome or Edge, Safari 26 or
        later) and falls back to WebGL 2 elsewhere (any current browser; GPU particles, light probes
        and material graphs need WebGPU). Add ?renderer=webgpu, webgl2 or auto to the address to
        pick one; the choice is remembered. Hardware acceleration must be on.

        Files
        index.html, loader.js   the page and its loader (saves.js keeps saves in the browser,
                                webgl2.js is the WebGL 2 renderer's JavaScript side)
        app/                    the game (WebAssembly) and its JavaScript glue
        vendor/                 the WASI shim the game runs on (@bjorn3/browser_wasi_shim, MIT/Apache-2.0)
        engine/                 the engine's shaders (WGSL, GLSL ES) and fonts (manifest.json lists them)
        game.pack               the game's assets
        player.json             what the loader starts (page options: ?scene=<path>, ?args=a,b)

        """
    }

    /// A Web export from the generated player package (cooked already): build and package the
    /// player, optimize it, and lay out the folder.
    func runWeb(cook: CookReport, start: Date, progress: (@Sendable (String) -> Void)?) throws -> GameExportReport {
        let fm = FileManager.default
        let toolchain = WebToolchain.find()
        if let problem = toolchain.problem { throw GameExportError.webToolchain(problem) }
        let site = outputURL

        progress?("Building \(options.gameTarget) with Engine for WebAssembly (\(options.configuration.rawValue)) "
                  + "(in \(playerPackage.path): \((buildEnvironment + buildCommand).joined(separator: " ")))")
        let build = GameModuleBuilder.run(buildEnvironment + buildCommand, in: playerPackage)
        guard build.succeeded else { throw GameExportError.buildFailed(build.output) }
        progress?(String(format: "Built and packaged in %.1f s", build.seconds))
        let packaged = playerPackage.appendingPathComponent(".build/plugins/PackageToJS/outputs/Package", isDirectory: true)
        let wasmName = "\(playerTarget).wasm"
        guard fm.fileExists(atPath: packaged.appendingPathComponent(wasmName).path) else {
            throw GameExportError.missingProduct(packaged.appendingPathComponent(wasmName).path)
        }

        let shim = try webWASIShim(packaged: packaged, toolchain: toolchain, progress: progress)
        let inputs = WebSiteInputs(page: options.enginePackage.appendingPathComponent("Web", isDirectory: true), packaged: packaged,
                                   wasiShim: shim, engineResources: webEngineResources(toolchain: toolchain),
                                   pack: URL(fileURLWithPath: cook.packPath))
        progress?("Writing \(site.path)")
        let renderer = options.webRenderer ?? .auto
        let engineFiles = try Self.assembleWebSite(at: site, inputs: inputs, wasmName: wasmName, packName: "\(options.name).pack",
                                                   gameName: options.name, renderer: renderer)
        progress?("Engine resources: \(engineFiles.count) files (WGSL and GLSL ES shaders, fonts); renderer \(renderer.rawValue)")

        let wasm = site.appendingPathComponent("app/\(wasmName)")
        var optimizeSeconds = 0.0
        if options.configuration == .release {
            if let wasmOpt = toolchain.wasmOpt, let level = toolchain.optimizationLevel {
                let before = Self.size(of: wasm)
                let optimized = wasm.appendingPathExtension("opt")
                let step = GameModuleBuilder.run([wasmOpt.path, level, "--strip-dwarf", "--strip-producers", wasm.path, "-o", optimized.path],
                                                 in: site)
                optimizeSeconds = step.seconds
                if step.succeeded {
                    _ = try fm.replaceItemAt(wasm, withItemAt: optimized)
                    try Self.writeWebPlayerConfig(site: site, wasmName: wasmName, packName: "\(options.name).pack",
                                                  renderer: renderer)  // the new wasmSize
                    let mb = { (bytes: Int) in String(format: "%.1f MB", Double(bytes) / 1_048_576) }
                    progress?(String(format: "wasm-opt \(level): \(mb(before)) → \(mb(Self.size(of: wasm))) in %.0f s", step.seconds))
                } else {
                    try? fm.removeItem(at: optimized)
                    progress?("Warning: wasm-opt failed, the module ships unoptimized: \(step.output.suffix(500))")
                }
            } else if toolchain.wasmOpt == nil {
                progress?("Note: wasm-opt isn't installed, so the module isn't optimized for size (install binaryen: `brew install binaryen`)")
            }
        }

        var report = GameExportReport(outputPath: site.path, executablePath: wasm.path,
                                      packPath: site.appendingPathComponent(Self.webPackFile).path, cook: cook,
                                      buildSeconds: build.seconds + optimizeSeconds, totalSeconds: 0, executableBytes: Self.size(of: wasm),
                                      totalBytes: Self.size(of: site), linking: "static")
        if options.configuration == .release {
            // What a host serves with compression on (brotli at its best quality, as for precompressed files: 2-3 min).
            if toolchain.brotli != nil { progress?("Measuring the compressed sizes (gzip -9, brotli -q 11)") }
            report.wasmGzipBytes = toolchain.gzip.flatMap { Self.compressedSize(of: wasm, with: [$0.path, "-9", "-c"]) }
            report.wasmBrotliBytes = toolchain.brotli.flatMap { Self.compressedSize(of: wasm, with: [$0.path, "-q", "11", "-c"]) }
        }
        report.cook.packPath = report.packPath
        report.totalSeconds = Date().timeIntervalSince(start)
        progress?(report.summary)
        return report
    }

    /// The bytes `command` (writing to standard output) compresses `file` to, or nil.
    static func compressedSize(of file: URL, with command: [String]) -> Int? {
        let quoted = (command + [file.path]).map { "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'" }.joined(separator: " ")
        let result = GameModuleBuilder.run(["sh", "-c", "\(quoted) | wc -c"], in: file.deletingLastPathComponent())
        guard result.succeeded else { return nil }
        return Int(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// The engine resources the build produced (`<package>_EngineCore.bundle`), else the engine's sources.
    func webEngineResources(toolchain: WebToolchain) -> URL {
        let show = GameModuleBuilder.run(buildEnvironment + [toolchain.swift.path, "build"] + buildFlags
                                         + ["-c", options.configuration.rawValue, "--show-bin-path"], in: playerPackage)
        if show.succeeded, let path = Self.lastAbsolutePath(in: show.output) {
            let bin = URL(fileURLWithPath: path, isDirectory: true)
            let names = (try? FileManager.default.contentsOfDirectory(atPath: bin.path)) ?? []
            if let bundle = names.sorted().first(where: { $0.hasSuffix("_EngineCore.bundle") || $0.hasSuffix("_EngineCore.resources") }) {
                return bin.appendingPathComponent(bundle, isDirectory: true)
            }
        }
        return options.enginePackage.appendingPathComponent("Sources/EngineCore", isDirectory: true)
    }

    /// The WASI shim PackageToJS's glue was made for (its package.json's version): a cached copy
    /// (this export's, Scripts/web-player.sh's or ~/.acro-webtools'), else fetched with npm once.
    func webWASIShim(packaged: URL, toolchain: WebToolchain, progress: (@Sendable (String) -> Void)?) throws -> URL {
        let fm = FileManager.default
        let package = (try? Data(contentsOf: packaged.appendingPathComponent("package.json")))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let dependencies = package?["dependencies"] as? [String: String] ?? [:]
        guard let version = dependencies["@bjorn3/browser_wasi_shim"] else {
            throw GameExportError.missingProduct(packaged.appendingPathComponent("package.json").path + " (with @bjorn3/browser_wasi_shim)")
        }
        let module = "node_modules/@bjorn3/browser_wasi_shim"
        let cache = playerPackage.appendingPathComponent(".build/web-deps/browser_wasi_shim-\(version)", isDirectory: true)
        let candidates = [cache, options.enginePackage.appendingPathComponent(".build-wasm/web-deps/browser_wasi_shim-\(version)"),
                          URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".acro-webtools")]
            .map { $0.appendingPathComponent(module, isDirectory: true) }
        for candidate in candidates {
            guard let data = fm.contents(atPath: candidate.appendingPathComponent("package.json").path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], json["version"] as? String == version,
                  fm.fileExists(atPath: candidate.appendingPathComponent("dist/index.js").path) else { continue }
            return candidate.appendingPathComponent("dist", isDirectory: true)
        }
        guard let npm = toolchain.npm else {
            throw GameExportError.webToolchain("Web export needs the WASI shim @bjorn3/browser_wasi_shim@\(version), fetched once with npm, "
                                               + "which isn't installed: install Node.js (https://nodejs.org or `brew install node`)")
        }
        progress?("Fetching @bjorn3/browser_wasi_shim@\(version) (once)")
        try fm.createDirectory(at: cache, withIntermediateDirectories: true)
        // npm is a script run by node: its folder goes on PATH.
        let path = "PATH=\(npm.deletingLastPathComponent().path):\(ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin")"
        let install = GameModuleBuilder.run([path, npm.path, "install", "--prefix", cache.path, "--no-save", "--no-package-lock", "--silent",
                                             "@bjorn3/browser_wasi_shim@\(version)"], in: cache)
        let dist = cache.appendingPathComponent(module + "/dist", isDirectory: true)
        guard install.succeeded, fm.fileExists(atPath: dist.appendingPathComponent("index.js").path) else {
            throw GameExportError.webToolchain("Fetching @bjorn3/browser_wasi_shim@\(version) with npm failed:\n\(install.output)")
        }
        return dist
    }
}
#endif
