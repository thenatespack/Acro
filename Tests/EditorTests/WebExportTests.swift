import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineAssets
@testable import EngineCore
@testable import EngineGraphics

// The Web export (GameExporterWeb.swift): the generated player package for WebAssembly, the
// static folder's layout in exactly the shape Web/loader.js fetches, finding the Wasm toolchain,
// and the Export dialog's Web choice. The real build (minutes, the Swift SDK for WebAssembly)
// runs only with WEB_EXPORT_TEST=1.

private func webExportTestsFolder() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("WebExportTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// The package root (this file is Tests/EditorTests/WebExportTests.swift).
private let webExportTestsRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

@MainActor @Suite struct WebExportTests {
    /// An exporter for a game package with one source file, for `platform`.
    private func exporter(_ folder: URL, platform: CookPlatform = .web, configuration: BuildConfiguration = .release) throws -> GameExporter {
        let sources = folder.appendingPathComponent("Sources/WebExportTestsGame")
        try write("import Engine\n", to: sources.appendingPathComponent("Game.swift"))
        let options = GameExportOptions(name: "Web Export Tests", gameTarget: "WebExportTestsGame", gamePackage: folder,
                                        enginePackage: webExportTestsRoot, output: folder.appendingPathComponent("Out"),
                                        cook: CookOptions(scenes: ["Main.scene"], target: CookTarget(platform: platform)),
                                        configuration: configuration)
        let plan = try AssetCooker.plan(database: AssetDatabase(project: try Project.create(at: folder.appendingPathComponent("Project-\(platform.rawValue)"))),
                                        options: CookOptions(scenes: [sources.appendingPathComponent("Game.swift").path]))
        return GameExporter(options: options, cookPlan: plan)
    }

    @Test func playerPackageForTheWeb() throws {
        let folder = webExportTestsFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let web = try exporter(folder)
        try web.writePlayerPackage()
        // Its own package, so WebAssembly products never mix with the native export's.
        #expect(web.playerPackage.path.hasSuffix(".build/game-export-web/WebExportTestsGame"))
        let manifest = try String(contentsOf: web.playerPackage.appendingPathComponent("Package.swift"), encoding: .utf8)
        #expect(manifest.contains(".package(url: \"https://github.com/swiftwasm/JavaScriptKit.git\", from: \"\(WebToolchain.javaScriptKitVersion)\")"))
        #expect(manifest.contains(".enableExperimentalFeature(\"Extern\")"))
        #expect(manifest.contains(#"[.unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))]"#))
        #expect(!manifest.contains("$ORIGIN/lib"))
        // Game and player are built with WebAssembly SIMD like the engine (it changes how Vec3 is passed).
        #expect(manifest.components(separatedBy: #".unsafeFlags(["-Xcc", "-msimd128"])"#).count == 3)
        let main = try String(contentsOf: web.playerPackage.appendingPathComponent("Sources/Player/main.swift"), encoding: .utf8)
        #expect(main.contains("@_extern(c, \"\(GameModuleABI.entryPoint)\")\nfunc gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32"))
        #expect(!main.contains("@_silgen_name("))

        // Built and packaged by the Wasm toolchain's `swift package js`, wasm-opt run afterwards.
        let command = web.buildCommand
        #expect(command.first == WebToolchain.find().swift.path)
        #expect(Array(command.dropFirst()) == ["package", "--swift-sdk", WebToolchain.find().sdk, "js", "--product", "WebExportTestsGamePlayer",
                                               "-c", "release", "--no-optimize"])
        #expect(web.buildEnvironment == ["ENGINE_WASM=1"])
        #expect(web.outputURL.lastPathComponent == "Web Export Tests")
        #expect(GameExporter.outputFolderName(platform: .web, architecture: .x86_64, configuration: .release) == "web")
        #expect(GameExporter.outputFolderName(platform: .web, architecture: .arm64, configuration: .debug) == "web-debug")

        // The native package of the same game keeps its own place and Linux rpath.
        let native = try exporter(folder, platform: .current)
        try native.writePlayerPackage()
        #expect(native.playerPackage.path.hasSuffix(".build/game-export/WebExportTestsGame"))
        let nativeManifest = try String(contentsOf: native.playerPackage.appendingPathComponent("Package.swift"), encoding: .utf8)
        #expect(nativeManifest.contains("$ORIGIN/lib") && !nativeManifest.contains("JavaScriptKit") && !nativeManifest.contains("msimd128"))
    }

    /// The folder holds exactly what Web/loader.js and Web/index.html fetch.
    @Test func folderLayoutMatchesTheLoader() throws {
        let folder = webExportTestsFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let packaged = folder.appendingPathComponent("Package", isDirectory: true)
        try write("wasm", to: packaged.appendingPathComponent("WebExportTestsGamePlayer.wasm"))
        try write("export {}", to: packaged.appendingPathComponent("instantiate.js"))
        try write("export {}", to: packaged.appendingPathComponent("runtime.js"))
        let shimPackage = folder.appendingPathComponent("node_modules/@bjorn3/browser_wasi_shim", isDirectory: true)
        try write("export {}", to: shimPackage.appendingPathComponent("dist/index.js"))
        try write("MIT", to: shimPackage.appendingPathComponent("LICENSE-MIT"))
        let resources = folder.appendingPathComponent("Acro_EngineCore.bundle", isDirectory: true)
        for file in ["Info.plist", "Shaders/ui.vert.wgsl", "Shaders/ui.vert.spv", "Shaders/ui.vert.metal", "Shaders/ui.frag.wgsl",
                     "Shaders/particle_spawn.comp.wgsl", "Shaders/particle_spawn.comp.spv", "Shaders/common.glsl",
                     "Fonts/Inter-Regular.ttf", "Fonts/Inter-LICENSE.txt"] {
            try write(file, to: resources.appendingPathComponent(file))
        }
        let pack = folder.appendingPathComponent("Web Export Tests.pack")
        // A pack header (magic, version, alignment, table of contents offset and size, its hash), padded.
        try write("SGEPACK\0" + String(repeating: "\u{1}", count: 24) + "0123456789abcdef" + String(repeating: " ", count: 80), to: pack)

        let site = folder.appendingPathComponent("Out/Web Export Tests", isDirectory: true)
        try write("stale", to: site.appendingPathComponent("old.txt"))
        let inputs = WebSiteInputs(page: webExportTestsRoot.appendingPathComponent("Web"), packaged: packaged,
                                   wasiShim: shimPackage.appendingPathComponent("dist"), engineResources: resources, pack: pack)
        let files = try GameExporter.assembleWebSite(at: site, inputs: inputs, wasmName: "WebExportTestsGamePlayer.wasm",
                                                     packName: "Web Export Tests.pack", gameName: "Web Export Tests")
        // Only the WGSL shaders and the fonts.
        let expected = ["Fonts/Inter-LICENSE.txt", "Fonts/Inter-Regular.ttf", "Shaders/particle_spawn.comp.wgsl",
                        "Shaders/ui.frag.wgsl", "Shaders/ui.vert.wgsl"]
        #expect(files == expected)

        let fm = FileManager.default
        #expect(!fm.fileExists(atPath: site.appendingPathComponent("old.txt").path))
        for path in ["index.html", "loader.js", "saves.js", "app/WebExportTestsGamePlayer.wasm", "app/instantiate.js", "app/runtime.js",
                     "vendor/browser_wasi_shim/index.js", "vendor/browser_wasi_shim/LICENSE-MIT", "game.pack", "player.json",
                     "README.txt", "engine/manifest.json"] + expected.map({ "engine/" + $0 }) {
            #expect(fm.fileExists(atPath: site.appendingPathComponent(path).path), "\(path)")
        }
        for path in ["engine/Info.plist", "engine/Shaders/ui.vert.spv", "engine/Shaders/ui.vert.metal", "engine/Shaders/common.glsl"] {
            #expect(!fm.fileExists(atPath: site.appendingPathComponent(path).path), "\(path)")
        }

        // engine/manifest.json and player.json as the loader reads them.
        let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: site.appendingPathComponent("engine/manifest.json"))) as? [String: Any]
        #expect(manifest?["files"] as? [String] == expected)
        let config = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: site.appendingPathComponent("player.json"))) as? [String: Any])
        #expect(config["wasm"] as? String == "app/WebExportTestsGamePlayer.wasm")
        #expect(config["pack"] as? String == "game.pack")
        #expect(config["packName"] as? String == "Web Export Tests.pack")
        #expect(config["engine"] as? String == "engine/manifest.json")
        #expect(config["args"] as? [String] == [])
        // For the download progress and the browser's cache.
        #expect(config["packSize"] as? Int == 128)
        #expect(config["packHash"] as? String == "0123456789abcdef")
        #expect(config["wasmSize"] as? Int == 4)
        for key in ["wasm", "pack", "engine"] {
            let path = try #require(config[key] as? String)
            #expect(fm.fileExists(atPath: site.appendingPathComponent(path).path), "player.json \(key): \(path)")
        }
        // What the page itself refers to.
        let loader = try String(contentsOf: site.appendingPathComponent("loader.js"), encoding: .utf8)
        #expect(loader.contains("url(\"player.json\")") && loader.contains("./app/instantiate.js"))
        let page = try String(contentsOf: site.appendingPathComponent("index.html"), encoding: .utf8)
        #expect(page.contains("./vendor/browser_wasi_shim/index.js"))
        let readme = try String(contentsOf: site.appendingPathComponent("README.txt"), encoding: .utf8)
        #expect(readme.contains("application/wasm") && readme.contains("WebGPU") && readme.hasPrefix("Web Export Tests"))
    }

    /// Game code that imports Foundation keeps it linked on the web; the WASI import block doesn't.
    @Test func detectsGameCodeImportingFoundation() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("WebExportFoundation-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("Game.swift")
        func imports(_ source: String) throws -> Bool {
            try source.write(to: file, atomically: true, encoding: .utf8)
            return GameExporter.importsFullFoundation(sourcesIn: dir)
        }
        #expect(try !imports("import Engine\n"))
        #expect(try imports("import Engine\nimport Foundation\n"))
        #expect(try imports("@preconcurrency import Foundation\n"))
        #expect(try imports("import struct Foundation.Date\n"))
        #expect(try !imports("#if os(WASI)\nimport WASIFoundation\n#else\nimport Foundation\n#endif\n"))
        #expect(try !imports("// import Foundation\nimport FoundationEssentials\n"))
    }

    @Test func engineResourcesForTheWeb() {
        #expect(GameExporter.isWebEngineResource("Shaders/mesh.vert.wgsl"))
        #expect(GameExporter.isWebEngineResource("Shaders/FidelityFX/x.comp.wgsl"))
        #expect(!GameExporter.isWebEngineResource("Shaders/mesh.vert.spv"))
        #expect(!GameExporter.isWebEngineResource("Shaders/mesh.frag.color0.metal"))
        #expect(!GameExporter.isWebEngineResource("Info.plist"))
        #expect(GameExporter.isWebEngineResource("Fonts/Inter-Regular.ttf"))
    }

    /// The toolchain is found without running anything, and its absence says how to install it.
    @Test func findsTheWasmToolchain() throws {
        let home = webExportTestsFolder()
        defer { try? FileManager.default.removeItem(at: home) }
        let environment = ["PATH": home.appendingPathComponent("bin").path]
        let none = WebToolchain.find(environment: environment, home: home.path)
        #expect(none.problem?.contains("swiftly install 6.4.2") == true)
        #expect(none.swift.path == home.appendingPathComponent(".swiftly/bin/swift").path)

        let swift = home.appendingPathComponent(".swiftly/bin/swift")
        try write("#!/bin/sh\n", to: swift)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: swift.path)
        let noSDK = WebToolchain.find(environment: environment, home: home.path)
        #expect(noSDK.problem?.contains("Swift SDK for WebAssembly (\(WebToolchain.defaultSDK))") == true)
        #expect(noSDK.problem?.contains("sdk install") == true)

        let bundle = home.appendingPathComponent(".swiftpm/swift-sdks/\(WebToolchain.defaultSDK).artifactbundle")
        try write(#"{"artifacts": {"\#(WebToolchain.defaultSDK)": {"type": "swiftSDK"}}, "schemaVersion": "1.0"}"#,
                  to: bundle.appendingPathComponent("info.json"))
        let found = WebToolchain.find(environment: environment, home: home.path)
        #expect(found.problem == nil)
        #expect(found.optimizationLevel == WebToolchain.defaultOptimizationLevel)
        #expect(WebToolchain.find(environment: environment.merging(["ACRO_WASM_OPT": "none"]) { $1 }, home: home.path).optimizationLevel == nil)
        #expect(WebToolchain.find(environment: environment.merging(["ACRO_WASM_SDK": "other_wasm"]) { $1 }, home: home.path).problem != nil)
        // The exporter and the dialog ask the same question.
        #expect(GameExporter.unbuildableReason(platform: .web, architecture: .x86_64, useDocker: false) == WebToolchain.find().problem)
        #expect(GameExporter.unbuildableReason(platform: .web, architecture: .current, useDocker: true) == "Docker builds Linux games only")
    }

    @Test func exportDialogOffersWeb() throws {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        try session.commands.run(ProjectNewCommand.self, .init(path: webExportTestsFolder().appendingPathComponent("WebExportTestsDialog").path))
        let dialog = ExportDialog(session: session)
        dialog.setPlatform(.web)
        #expect(dialog.choice.platform == .web && !dialog.choice.useDocker)
        #expect(dialog.choice.arguments.platform == .web)
        #expect(dialog.unavailableReason == WebToolchain.find().problem)
        #expect(dialog.outputFolder?.lastPathComponent == "web")
        let architecture = try #require(dialog.descendant(named: "exportArchitecture"))
        #expect(!architecture.isEnabled)
        dialog.setPlatform(.current)
        #expect(architecture.isEnabled)
    }

    /// A fragment variant loads from WGSL alone (a web export ships no SPIR-V or Metal).
    @Test func shaderVariantsLoadFromWGSLAlone() throws {
        let folder = webExportTestsFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        for file in ["Shaders/webexporttests.vert.wgsl", "Shaders/webexporttests.frag.wgsl", "Shaders/webexporttests_variant.frag.wgsl"] {
            try write("// \(file)", to: folder.appendingPathComponent(file))
        }
        let bundle = try #require(Bundle(url: folder))
        let source = try ShaderSource.load(vertex: "webexporttests", fragment: "webexporttests_variant", bundle: bundle)
        #expect(source.wgslFragment == "// Shaders/webexporttests_variant.frag.wgsl")
        #expect(source.spirvFragment == nil && source.wgslVertex != nil)
        #expect(throws: (any Error).self) { try ShaderSource.load(vertex: "webexporttests", fragment: "missing", bundle: bundle) }
    }

    /// The whole Web export of SampleGame: WEB_EXPORT_TEST=1 (a WebAssembly release build, minutes).
    @Test(.enabled(if: ProcessInfo.processInfo.environment["WEB_EXPORT_TEST"] == "1"))
    func exportsSampleGameForTheWeb() throws {
        let project = try Project.open(at: webExportTestsRoot.appendingPathComponent("Projects/SampleGame"))
        let database = AssetDatabase(project: project)
        database.scan()
        let out = webExportTestsFolder()
        let options = try GameExporter.options(for: project, output: out, target: CookTarget(platform: .web))
        let report = try GameExporter.prepare(database: database, options: options).run()
        let site = URL(fileURLWithPath: report.outputPath)
        for path in ["index.html", "loader.js", "player.json", "game.pack", "engine/manifest.json", "README.txt",
                     "vendor/browser_wasi_shim/index.js", "app/instantiate.js"] {
            #expect(FileManager.default.fileExists(atPath: site.appendingPathComponent(path).path), "\(path)")
        }
        #expect(report.executablePath.hasSuffix(".wasm") && report.executableBytes > 1_000_000)
    }
}
