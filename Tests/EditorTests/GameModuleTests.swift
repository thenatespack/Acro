import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Game modules (EditorGameModule.swift): SampleGame linked from its built objects and loaded
// into the test process, its components in Add Component and its systems in play mode;
// reloading into a changed version (GameModuleTestFixture, "SampleGame v2") while playing,
// with entities, play state and removed types kept; a failed load keeping the old module; the
// MCP-facing commands; and the tolerant decoding underneath, with test components.
//
// The modules register components in the process-wide registry, so every test unloads what it
// loaded before returning, and the tests are synchronous (other main-actor tests can't run in
// between). The objects come from the test build (`swift build` builds every target).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// The package root (this file is Tests/EditorTests/GameModuleTests.swift).
private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

@MainActor
@Suite(.serialized) struct GameModuleTests {
    /// Loads `target` (linked from its built objects, no build) into `session`.
    @discardableResult
    private func load(_ target: String, into session: EditorSession, sourceLocation: SourceLocation = #_sourceLocation) throws -> GameReloadReport {
        session.gameModule.configure(GameModuleSettings(target: target, package: packageRoot.path), base: packageRoot)
        let future = try session.gameModule.reload(build: false)
        switch future.outcome {
        case .success(let report)?: return report
        case .failure(let error)?: throw error
        case nil: throw CommandError.failed("reload(build: false) didn't finish at once")
        }
    }

    private func unload(_ session: EditorSession) {
        try? session.gameModule.unload()
        #expect(ComponentRegistry.type(named: "Bobber") == nil)
        #expect(ComponentRegistry.type(named: "GameModuleTestsPulser") == nil)
    }

    private func entity(named name: String, in session: EditorSession) -> Entity? {
        let world = session.world
        var found: Entity?
        world.query(Name.self) { entity, n in if n.value == name { found = entity } }
        return found
    }

    @Test func sampleModuleLoadsAndRunsInPlayMode() throws {
        let session = makeSession()
        defer { unload(session) }
        let report = try load("SampleGame", into: session)
        #expect(report.module == "SampleGame")
        #expect(report.components == ["Bobber", "Orbiter"])
        #expect(report.systems == ["sample.bob", "sample.orbit"])
        #expect(report.linkSeconds != nil && report.buildSeconds == nil)
        #expect(EditorComponentCatalog.addableNames.contains("Bobber"))
        #expect(ComponentRegistry.type(named: "Orbiter") != nil)

        // Add Component, through the command as the inspector does.
        let cube = try #require(entity(named: "Red Cube", in: session))
        let id = try #require(session.world.id(of: cube))
        try session.commands.run(ComponentAddCommand.self, .init(entity: id, component: "Bobber"))
        #expect((session.world.fields(of: "Bobber", for: cube) ?? []).map(\.name).contains("amplitude"))
        let y0 = try #require(session.world.get(Transform.self, for: cube)).position.y

        // The systems run only in play mode.
        session.tick(dt: 0.1)
        #expect(session.world.get(Transform.self, for: cube)?.position.y == y0)
        session.play(paused: true)
        #expect(session.world.systemNames(in: .update).contains("sample.bob"))
        session.step(frames: 20, dt: 1.0 / 60)
        let y1 = try #require(session.world.get(Transform.self, for: cube)).position.y
        #expect(abs(y1 - y0) > 0.05)
        session.stop()
        #expect(!session.world.systemNames(in: .update).contains("sample.bob"))
        #expect(session.world.get(Transform.self, for: cube)?.position.y == y0)

        let info = try session.commands.run(GameInfoCommand.self)
        #expect(info.loaded && info.module == "SampleGame" && info.components == ["Bobber", "Orbiter"])
    }

    /// SampleGame's networked world (ABI 1.3), built on both sides with ids numbered in spawn
    /// order as `GameRunner --server` / `--connect` do: the client's entities are matched, not
    /// duplicated, and follow the server's systems.
    @Test func sampleModuleNetworkedWorld() throws {
        let session = makeSession()
        defer { unload(session) }
        try load("SampleGame", into: session)
        let module = try #require(session.gameModule.loaded?.module)
        #expect(module.abiMinorVersion >= 3)
        let populate = try #require(module.populateNetworkedWorld)
        func makeWorld() -> World {
            let world = World()
            var next: UInt64 = 0
            world.entityIDGenerator = {
                next += 1
                return EntityID(high: 1, low: next)
            }
            world.assignsEntityIDs = true
            populate(world)
            world.assignsEntityIDs = false
            return world
        }
        let serverWorld = makeWorld(), clientWorld = makeWorld()
        let count = clientWorld.entityCount
        module.addSystems(to: serverWorld, context: GameContext(input: Input()))
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.03, loss: 0.05), seed: 3)
        let serverEnd = network.makeEndpoint(), clientEnd = network.makeEndpoint()
        let server = NetServer(world: serverWorld, transport: serverEnd, secret: 1)
        let client = NetClient(world: clientWorld, transport: clientEnd, server: serverEnd.id, salt: 2)
        var time = 0.0
        for _ in 0..<120 {
            network.now = time
            serverWorld.update(dt: 1.0 / 60)
            server.update(time: time)
            client.update(dt: 1.0 / 60)
            time += 1.0 / 60
        }
        #expect(client.replicatedEntityCount == serverWorld.count(of: Replicated.self))
        #expect(client.replicatedEntityCount == 6)
        #expect(clientWorld.entityCount == count)
        // The props moved on the client as on the server (bobbing).
        var moved = 0
        clientWorld.query(Replicated.self) { entity, _ in
            let id = clientWorld.id(of: entity)!
            let a = clientWorld.get(Transform.self, for: entity)!.position
            let b = serverWorld.get(Transform.self, for: serverWorld.entity(for: id)!)!.position
            if length(a - b) < 0.5 && a.y != 0.8 { moved += 1 }
        }
        #expect(moved >= 5)
    }

    @Test func reloadingAChangedModuleWhilePlayingKeepsTheScene() throws {
        let session = makeSession()
        defer { unload(session) }
        try load("SampleGame", into: session)
        let world = session.world
        let cube = try #require(entity(named: "Red Cube", in: session))
        let sphere = try #require(entity(named: "Blue Sphere", in: session))
        let bobberType = try #require(ComponentRegistry.type(named: "Bobber"))
        try session.commands.run(ComponentAddCommand.self, .init(entity: try #require(world.id(of: cube)), component: "Bobber"))
        try world.setField("phase", of: "Bobber", for: cube, to: .float(0.5))
        try world.setField("amplitude", of: "Bobber", for: cube, to: .float(1.25))
        try session.commands.run(ComponentAddCommand.self, .init(entity: try #require(world.id(of: sphere)), component: "Orbiter"))
        try world.setField("radius", of: "Orbiter", for: sphere, to: .float(3))
        let entityCount = world.entityCount
        session.selection.select(world.id(of: cube))

        session.play(paused: true)
        session.step(frames: 5, dt: 1.0 / 60)
        let origin = try #require((world.fields(of: "Bobber", for: cube) ?? []).first { $0.name == "origin" })
        #expect(origin.value != .null)
        let sphereInPlay = try #require(world.get(Transform.self, for: sphere)).position

        // v2: Bobber changed, Orbiter gone, a new component; swapped in while playing.
        let report = try load("GameModuleTestFixture", into: session)
        #expect(report.playing)
        #expect(report.summaryOK)
        #expect(report.added == ["GameModuleTestsPulser"])
        #expect(report.removed == ["Orbiter": 1])
        #expect(report.resetFields["Bobber"] == ["speed"])
        #expect(report.restored >= 2)  // the cube's Bobber, live and in the play snapshot
        #expect(world.entityCount == entityCount)
        #expect(world.isAlive(cube) && world.isAlive(sphere))
        #expect(session.selection.primary == world.id(of: cube))
        #expect(ObjectIdentifier(try #require(ComponentRegistry.type(named: "Bobber"))) != ObjectIdentifier(bobberType))
        #expect(ComponentRegistry.type(named: "Orbiter") == nil)
        #expect(!EditorComponentCatalog.addableNames.contains("Orbiter"))
        #expect(EditorComponentCatalog.addableNames.contains("GameModuleTestsPulser"))

        // The live Bobber kept its data (phase, origin: the play state), took defaults for new
        // fields and reset the one whose type changed; the old amplitude is dropped.
        let fields = Dictionary(uniqueKeysWithValues: (world.fields(of: "Bobber", for: cube) ?? []).map { ($0.name, $0.value) })
        #expect(fields["phase"] == .float(0.5))
        #expect(fields["height"] == .float(2))
        #expect(fields["wobble"] == .float(0.25))
        #expect(fields["speed"] == .string("fast"))
        #expect(fields["origin"] == origin.value)
        #expect(fields["amplitude"] == nil)
        // The removed Orbiter is JSON now; the sphere still sits where play put it.
        #expect(world.get(UnresolvedComponents.self, for: sphere)?.components["Orbiter"] != nil)
        #expect(world.get(Transform.self, for: sphere)?.position == sphereInPlay)

        // The new code runs: v2's bob lifts the cube to origin + height.
        #expect(world.systemNames(in: .update).contains("sample.bob"))
        #expect(!world.systemNames(in: .update).contains("sample.orbit"))
        session.step(frames: 1, dt: 1.0 / 60)
        if case .vec3(let o) = origin.value {
            #expect(abs((world.get(Transform.self, for: cube)?.position.y ?? 0) - (o.y + 2)) < 1e-4)
        } else {
            Issue.record("origin isn't a vec3: \(origin.value)")
        }

        // Stop restores the edit-time scene, converted too: the new Bobber without play's origin.
        session.stop()
        let edit = Dictionary(uniqueKeysWithValues: (world.fields(of: "Bobber", for: cube) ?? []).map { ($0.name, $0.value) })
        #expect(edit["phase"] == .float(0.5))
        #expect(edit["origin"] == .null)
        #expect(!world.systemNames(in: .update).contains("sample.bob"))
        // Saving writes the removed Orbiter back unchanged.
        let saved = String(decoding: try world.save(), as: UTF8.self)
        #expect(saved.contains("\"Orbiter\"") && saved.contains("\"radius\" : 3"))

        // Back to v1: the Orbiter comes back typed with its radius; Bobber's amplitude is v1's default.
        let back = try load("SampleGame", into: session)
        #expect(back.removed == ["GameModuleTestsPulser": 0])
        #expect(world.get(UnresolvedComponents.self, for: sphere) == nil)
        #expect((world.fields(of: "Orbiter", for: sphere) ?? []).first { $0.name == "radius" }?.value == .float(3))
        #expect((world.fields(of: "Bobber", for: cube) ?? []).first { $0.name == "amplitude" }?.value == .float(0.5))
        // The history survived both reloads: undoing the two Adds removes today's types.
        #expect(session.undo.undoDepth == 2)
        #expect((try? session.undo.undo()) == true && (try? session.undo.undo()) == true)
        #expect(world.component(named: "Bobber", of: cube) == nil && world.component(named: "Orbiter", of: sphere) == nil)
        #expect(world.get(UnresolvedComponents.self, for: sphere) == nil)
    }

    @Test func failedLoadKeepsTheOldModule() throws {
        let session = makeSession()
        defer { unload(session) }
        try load("SampleGame", into: session)
        session.gameModule.configure(GameModuleSettings(library: "/nonexistent/Game.dylib"), base: packageRoot)
        #expect(throws: (any Error).self) { try session.commands.start(GameReloadCommand.self, .init(build: false)).outcome?.get() }
        #expect(session.gameModule.loaded?.module.name == "SampleGame")
        #expect(ComponentRegistry.type(named: "Bobber") != nil)
        #expect(session.gameModule.lastError?.contains("No game module at") == true)
        #expect(session.log.entries.contains { $0.level == .error && $0.message.contains("No game module at") })
    }

    @Test func commandsOverJSON() throws {
        let session = makeSession()
        defer { unload(session) }
        #expect(!session.commands.isAvailable(GameReloadCommand.id))
        #expect(session.commands.unavailableReason(GameReloadCommand.id)?.contains("--game") == true)
        let arguments = try JSONEncoder().encode(GameLoadCommand.Arguments(target: "SampleGame", package: packageRoot.path, build: false))
        let future = try session.commands.start(GameLoadCommand.id, json: arguments)
        let data = try #require(try future.outcome?.get())
        let report = try JSONDecoder().decode(GameReloadReport.self, from: data)
        #expect(report.components == ["Bobber", "Orbiter"])
        #expect(session.commands.isAvailable(GameReloadCommand.id))
        let reload = try session.commands.start(GameReloadCommand.id, json: Data(#"{"build": false}"#.utf8))
        #expect(try reload.outcome?.get() != nil)
        let info = try JSONDecoder().decode(GameInfoResult.self, from: try session.commands.run(GameInfoCommand.id))
        #expect(info.lastReport?.module == "SampleGame")
        try session.commands.run(GameUnloadCommand.self)
        #expect(session.gameModule.loaded == nil && !session.gameModule.isConfigured)
    }

    @Test func loaderRejectsWhatIsntAGameModule() throws {
        // A library without the entry point: stb_image's objects linked like a game.
        let builder = GameModuleBuilder(packageURL: packageRoot, target: "CStbImage")
        let library = try GameModuleLoader.uniqueCopyURL(for: URL(fileURLWithPath: "CStbImage.\(GameModuleLoader.libraryExtension)"))
        try builder.link(to: library)
        #expect(throws: GameModuleError.noEntryPoint("CStbImage-\(library.deletingPathExtension().lastPathComponent.split(separator: "-").last!).\(GameModuleLoader.libraryExtension)")) {
            try GameModuleLoader.load(library, copy: false)
        }
        // Not a library at all.
        let text = library.deletingLastPathComponent().appendingPathComponent("not-a-library.\(GameModuleLoader.libraryExtension)")
        try Data("hello".utf8).write(to: text)
        #expect {
            try GameModuleLoader.load(text)
        } throws: { error in
            if case .loadFailed = error as? GameModuleError { true } else { false }
        }
        #expect(throws: GameModuleError.notFound("/nonexistent.dylib")) { try GameModuleLoader.load(URL(fileURLWithPath: "/nonexistent.dylib")) }
    }

    @Test func buildErrorsAreTheCompilersDiagnostics() {
        let output = """
            [3/9] Compiling SampleGame SampleGame.swift
            error: SwiftCompile normal arm64 /p/Sources/SampleGame/SampleGame.swift failed with a nonzero exit code. Command line: cd /p
            /p/Sources/SampleGame/SampleGame.swift:71:106: \u{1B}[1;31merror: \u{1B}[1;39mcannot find 'oops' in scope\u{1B}[0;0m
            /p/Sources/SampleGame/SampleGame.swift:71:106: \u{1B}[1;31merror: \u{1B}[1;39mcannot find 'oops' in scope\u{1B}[0;0m
            error: Build failed
            """
        #expect(EditorGameModule.compilerErrors(in: output) == ["/p/Sources/SampleGame/SampleGame.swift:71:106: error: cannot find 'oops' in scope"])
        #expect(EditorGameModule.compilerErrors(in: "error: no such target\n") == ["error: no such target"])
    }

    // MARK: Detach and tolerant resolve, without a module

    struct HealthV1: Component, Equatable {
        static let componentName = "GameModuleTestsHealth"
        var points: Int
        var regen: Float
        var target: Entity?
    }

    struct HealthV2: Component, Equatable {
        static let componentName = "GameModuleTestsHealth"
        var points: String  // changed type
        var armor: Float  // new field
        var target: Entity?
        static let fallback = HealthV2(points: "full", armor: 7, target: nil)
    }

    @Test func detachThenResolveIntoAChangedType() throws {
        let world = World()
        let a = world.spawn(Transform(position: Vec3(1, 2, 3)))
        let b = world.spawn(Name("b"))
        ComponentRegistry.register(HealthV1.self)
        defer { ComponentRegistry.unregister(["GameModuleTestsHealth"]) }
        world.add(HealthV1(points: 5, regen: 0.5, target: b), to: a)

        #expect(try world.detachComponents(named: ["GameModuleTestsHealth"]) == 1)
        ComponentRegistry.unregister(["GameModuleTestsHealth"])
        #expect(world.get(HealthV1.self, for: a) == nil)
        #expect(!world.registeredComponentTypes.contains { $0 == HealthV1.self })
        #expect(world.unresolvedComponentCounts() == ["GameModuleTestsHealth": 1])
        #expect(world.get(Transform.self, for: a)?.position == Vec3(1, 2, 3))

        // Not registered: stays raw.
        var report = world.resolveUnresolvedComponents(defaults: { _ in nil })
        #expect(report.resolved == 0 && report.unresolvedNames == ["GameModuleTestsHealth"])

        ComponentRegistry.register(HealthV2.self)
        // Without a default the changed type can't decode: kept, reported.
        report = world.resolveUnresolvedComponents(defaults: { _ in nil })
        #expect(report.resolved == 0 && report.failures["GameModuleTestsHealth"] != nil)
        // With one: points reset, armor from the default, the entity handle kept.
        report = world.resolveUnresolvedComponents(defaults: { $0 == "GameModuleTestsHealth" ? HealthV2.fallback : nil })
        #expect(report.resolved == 1 && report.resetFields == ["GameModuleTestsHealth": ["points"]])
        #expect(world.get(HealthV2.self, for: a) == HealthV2(points: "full", armor: 7, target: b))
        #expect(world.get(UnresolvedComponents.self, for: a) == nil)
    }
}

private extension GameReloadReport {
    /// Times are filled in and nothing failed.
    var summaryOK: Bool { failed.isEmpty && loadSeconds >= 0 && swapSeconds >= 0 && totalSeconds >= swapSeconds }
}
