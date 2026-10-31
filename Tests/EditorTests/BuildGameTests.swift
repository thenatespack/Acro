import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Build Game (`game.build`, EditorBuildGame.swift) and the exporter's pieces: cooking from the
// open project in the background with progress on the console, availability, export options
// from Project.json, the generated player package, and the CLI. The full export (a release
// build of Engine, minutes the first time) runs only with BUILD_GAME_EXPORT_TEST=1; the
// exported player itself is checked by running it (README "Shipping a game").

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryFolder() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("BuildGameTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// The package root (this file is Tests/EditorTests/BuildGameTests.swift).
private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// Ticks the session until `future` finishes (the export's work runs on another thread).
@MainActor private func wait<T>(for future: CommandFuture<T>, in session: EditorSession, timeout: TimeInterval) throws -> T {
    let deadline = Date(timeIntervalSinceNow: timeout)
    while future.outcome == nil {
        guard Date() < deadline else { throw CommandError.failed("timed out") }
        Thread.sleep(forTimeInterval: 0.01)
        session.tick(dt: 1.0 / 60)
    }
    return try future.outcome!.get()
}

@MainActor @Suite struct BuildGameTests {
    /// A project with a material using a texture and a saved scene that uses the material.
    private func projectWithScene(_ session: EditorSession) throws -> URL {
        let root = temporaryFolder().appendingPathComponent("BuildGameTestsGame")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path))
        let image = Image(width: 8, height: 8, pixels: [UInt8](repeating: 180, count: 8 * 8 * 4))
        try image.writePNG(to: root.appendingPathComponent("Assets/wall.png"))
        let assets = try #require(session.assets)
        assets.refresh()
        let texture = try #require(assets.id(forPath: "wall.png"))
        let material = try assets.createMaterial(MaterialAsset(texture: AssetReference(texture)), at: "Wall.material")
        let world = session.world
        _ = world.spawn(Transform(), Name("BuildGameTestsWall"), MeshRenderer(mesh: .cube, material: MaterialHandle(AssetReference(material))))
        let scene = root.appendingPathComponent("Assets/Main.scene")
        try session.commands.run(SceneSaveAsCommand.self, .init(path: scene.path))
        return root
    }

    @Test func cookOnlyRunsInTheBackgroundAndLogsToTheConsole() throws {
        let session = makeSession()
        let root = try projectWithScene(session)
        #expect(session.commands.isAvailable(GameBuildCommand.self))
        let future = try session.commands.start(GameBuildCommand.self, .init(textureFamily: .bc, cookOnly: true))
        #expect(session.gameExport.isBusy)
        #expect(session.commands.unavailableReason(GameBuildCommand.id) == "a build is already running")
        let result = try wait(for: future, in: session, timeout: 120)
        // No "build" settings: the open scene was cooked, into Build/<platform>-pack.
        #expect(result.cook.scenes == ["Main.scene"])
        #expect(result.cook.assetCount == 2)
        #expect(result.executablePath == nil)
        let expected = root.appendingPathComponent("Build/\(CookPlatform.current.rawValue)-pack/BuildGameTestsGame.pack")
        #expect(URL(fileURLWithPath: result.packPath).standardizedFileURL.path == expected.standardizedFileURL.path)
        let pack = try AssetPack(url: expected)
        #expect(pack.manifest.textureFamily == .bc && pack.manifest.assets.count == 2)
        let lines = session.log.entries(atLeast: .info).map(\.message)
        #expect(lines.contains { $0.hasPrefix("Build: cooking Main.scene") })
        #expect(lines.contains { $0.hasPrefix("Build: Cooking wall.png") })
        #expect(lines.contains { $0.hasPrefix("Build: done: ") })
        #expect(!session.gameExport.isBusy && session.gameExport.lastResult == result)
    }

    @Test func problemsFailBeforeAnythingRuns() throws {
        let session = makeSession()
        _ = try projectWithScene(session)
        // A game export needs game code; this project has none.
        #expect(throws: GameExportError.noGame) { try session.gameExport.start(.init()) }
        // The plan is made at once: a missing scene fails before anything runs in the background.
        #expect(throws: CookError.sceneNotFound("Missing.scene")) { try session.gameExport.start(.init(scenes: ["Missing.scene"], cookOnly: true)) }
        #expect(!session.gameExport.isBusy)
        #expect(throws: (any Error).self) { try session.commands.start(GameBuildCommand.self, .init(scenes: ["Missing.scene"], cookOnly: true)) }
    }

    @Test func unavailableWithoutAProject() {
        let session = makeSession()
        #expect(!session.commands.isAvailable(GameBuildCommand.self))
        #expect(session.commands.unavailableReason(GameBuildCommand.id) == "no project is open")
    }

    @Test func exportOptionsComeFromProjectJSON() throws {
        let project = try Project.open(at: packageRoot.appendingPathComponent("Projects/SampleGame"))
        let options = try GameExporter.options(for: project)
        #expect(options.name == "SampleGame" && options.gameTarget == "SampleGame")
        #expect(options.gamePackage.standardizedFileURL.path == packageRoot.standardizedFileURL.path)
        #expect(options.enginePackage.standardizedFileURL.path == packageRoot.standardizedFileURL.path)
        #expect(options.cook.scenes == ["Scenes/Main.scene"])
        #expect(options.cook.target == CookTarget(platform: .current))
        #expect(options.output.path.hasSuffix("Projects/SampleGame/Build/\(CookPlatform.current.rawValue)"))
        // A project without game code can't be exported.
        let bare = try Project.create(at: temporaryFolder().appendingPathComponent("BuildGameTestsBare"))
        #expect(throws: GameExportError.noGame) { try GameExporter.options(for: bare) }
    }

    @Test func playerPackageLinksTheGameStatically() throws {
        let game = temporaryFolder().appendingPathComponent("BuildGameTestsPackage")
        let sources = game.appendingPathComponent("Sources/BuildGameTestsGame")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try Data("import Engine\n".utf8).write(to: sources.appendingPathComponent("Game.swift"))
        let options = GameExportOptions(name: "Build Game Tests", gameTarget: "BuildGameTestsGame", gamePackage: game,
                                        enginePackage: packageRoot, output: game.appendingPathComponent("Out"),
                                        cook: CookOptions(scenes: ["Main.scene"]))
        let exporter = GameExporter(options: options, cookPlan: try AssetCooker.plan(
            database: AssetDatabase(project: try Project.create(at: game.appendingPathComponent("Project"))),
            options: CookOptions(scenes: [game.appendingPathComponent("Sources/BuildGameTestsGame/Game.swift").path])))
        try exporter.writePlayerPackage()
        let root = exporter.playerPackage
        let manifest = try String(contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8)
        #expect(manifest.contains(".package(path: \"\(packageRoot.standardizedFileURL.path)\")"))
        #expect(manifest.contains(".product(name: \"Engine\", package: \"\(packageRoot.standardizedFileURL.lastPathComponent.lowercased())\")"))
        #expect(manifest.contains(".executableTarget(name: \"BuildGameTestsGamePlayer\""))
        let main = try String(contentsOf: root.appendingPathComponent("Sources/Player/main.swift"), encoding: .utf8)
        #expect(main.contains("@_silgen_name(\"\(GameModuleABI.entryPoint)\")") && main.contains("GamePlayer.main(module: gameModuleEntry)"))
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: root.appendingPathComponent("Sources/BuildGameTestsGame").path) == sources.path)
        // Unchanged files aren't rewritten (the build stays incremental).
        let date = try FileManager.default.attributesOfItem(atPath: root.appendingPathComponent("Package.swift").path)[.modificationDate] as? Date
        try exporter.writePlayerPackage()
        #expect(try FileManager.default.attributesOfItem(atPath: root.appendingPathComponent("Package.swift").path)[.modificationDate] as? Date == date)
        #expect(exporter.buildCommand.prefix(5) == ["swift", "build", "-c", "release", "--product"])
        #if os(macOS)
        #expect(exporter.outputURL.lastPathComponent == "Build Game Tests.app")
        #expect(exporter.infoPlist.contains("<string>Build Game Tests</string>") && exporter.infoPlist.contains("local.swiftgameengine.buildgametests"))
        #else
        #expect(exporter.launcher.contains("--pack \"$here/Build Game Tests.pack\""))
        #endif
    }

    @Test func commandLineCooks() throws {
        let session = makeSession()
        let root = try projectWithScene(session)
        let out = root.appendingPathComponent("CLI")
        #expect(EditorPackagingCLI.handles(["--cook", root.path]))
        #expect(!EditorPackagingCLI.handles(["scene.json"]))
        #expect(EditorPackagingCLI.run(["--cook", root.path, "--scenes", "Main.scene", "--platform", "linux", "--out", out.path]) == 0)
        let pack = try AssetPack(url: out.appendingPathComponent("BuildGameTestsGame.pack"))
        #expect(pack.manifest.platform == .linux && pack.manifest.textureFamily == .bc)
        #expect(EditorPackagingCLI.run(["--cook", root.path, "--gpu", "pvrtc"]) == 1)
        #expect(EditorPackagingCLI.run(["--cook"]) == 1)
    }

    /// The whole export, as Build Game runs it: BUILD_GAME_EXPORT_TEST=1 (a release build).
    @Test(.enabled(if: ProcessInfo.processInfo.environment["BUILD_GAME_EXPORT_TEST"] == "1"))
    func exportsSampleGame() throws {
        let project = try Project.open(at: packageRoot.appendingPathComponent("Projects/SampleGame"))
        let database = AssetDatabase(project: project)
        database.scan()
        let out = temporaryFolder()
        let options = try GameExporter.options(for: project, output: out)
        let report = try GameExporter.prepare(database: database, options: options).run()
        #expect(FileManager.default.isExecutableFile(atPath: report.executablePath))
        #expect(FileManager.default.fileExists(atPath: report.packPath))
        #expect(report.linking == "static")
    }
}
