import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Hot reload follow-ups (card 657): the reload hooks carrying non-ECS state, the undo history
// surviving reloads (values re-decoded into the new types, or kept as JSON), games of several
// targets, the direct-swiftc build plan, and crash recovery files.
//
// Tests that load modules or register components extend GameModuleTests, the one serialized
// suite that touches the global ComponentRegistry; the pure ones are in GameModuleReloadTests.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    // The tests save scenes in temporary folders: as if the editor had started there.
    session.startFolder = FileManager.default.temporaryDirectory
    session.newDocument()
    return session
}

private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

@MainActor
@discardableResult
private func load(_ target: String, into session: EditorSession) throws -> GameReloadReport {
    session.gameModule.configure(GameModuleSettings(target: target, package: packageRoot.path), base: packageRoot)
    switch try session.gameModule.reload(build: false).outcome {
    case .success(let report)?: return report
    case .failure(let error)?: throw error
    case nil: throw CommandError.failed("reload(build: false) didn't finish at once")
    }
}

@MainActor private func entity(named name: String, in world: World) -> Entity? {
    var found: Entity?
    world.query(Name.self) { entity, n in if n.value == name { found = entity } }
    return found
}

@MainActor private func fields(_ name: String, of entity: Entity, in world: World) -> [String: FieldValue?] {
    Dictionary(uniqueKeysWithValues: (world.fields(of: name, for: entity) ?? []).map { ($0.name, $0.value) })
}

extension GameModuleTests {
    @Test func reloadHooksCarryStateToTheNextVersion() throws {
        let session = makeSession()
        defer { try? session.gameModule.unload() }
        let first = try load("SampleGame", into: session)
        #expect(first.carriedStateBytes == nil)  // nothing to carry on a first load
        #expect(session.gameModule.loaded?.module.abiMinorVersion == GameModuleABI.minorVersion)
        let cube = try #require(entity(named: "Red Cube", in: session.world))
        try session.commands.run(ComponentAddCommand.self, .init(entity: try #require(session.world.id(of: cube)), component: "Bobber"))

        // v1's bob system counts frames in a static; v2 receives the count.
        session.play(paused: true)
        session.step(frames: 7, dt: 1.0 / 60)
        let v2 = try load("GameModuleTestFixture", into: session)
        #expect((v2.carriedStateBytes ?? 0) > 0)
        #expect(session.gameModule.loaded?.module.summary == "Version 2 (carried 7)")

        // Back to v1: it gets v2's state (frames -1) and counts the reload.
        try load("SampleGame", into: session)
        #expect(session.gameModule.loaded?.module.summary == "Bobbing and orbiting props (-1 frames, 1 reloads)")
        session.stop()

        // An unload keeps the state for the next load.
        try session.gameModule.unload()
        try load("GameModuleTestFixture", into: session)
        #expect(session.gameModule.loaded?.module.summary == "Version 2 (carried -1)")
    }

    @Test func undoHistorySurvivesReloadsIntoChangedTypes() throws {
        let session = makeSession()
        defer { try? session.gameModule.unload() }
        try load("SampleGame", into: session)
        let world = session.world
        let cube = try #require(entity(named: "Red Cube", in: world))
        let sphere = try #require(entity(named: "Blue Sphere", in: world))
        let cubeID = try #require(world.id(of: cube)), sphereID = try #require(world.id(of: sphere))

        // Steps holding game component values: add, a whole-component edit, a field edit, a removal.
        try session.commands.run(ComponentAddCommand.self, .init(entity: cubeID, component: "Bobber"))
        let before = try #require(world.component(named: "Bobber", of: cube))
        var after = before
        try after.setField("phase", to: .float(0.75))
        try #require(session.perform(SetComponentCommand(id: cubeID, old: before, new: after, label: "Phase")))
        try session.commands.run(ComponentAddCommand.self, .init(entity: sphereID, component: "Orbiter"))
        try session.commands.run(ComponentSetFieldCommand.self, .init(entity: sphereID, component: "Orbiter", path: "radius", value: .double(4)))
        try session.commands.run(ComponentRemoveCommand.self, .init(entity: sphereID, component: "Orbiter"))
        #expect(session.undo.undoDepth == 5)

        // v2: Bobber changed, Orbiter gone. The history is kept, its Bobbers converted.
        let report = try load("GameModuleTestFixture", into: session)
        #expect(session.undo.undoDepth == 5)
        #expect((report.undoValuesRestored ?? 0) >= 3)  // add, old and new of the edit (Orbiter values stay JSON)
        #expect(!session.log.entries.contains { $0.message.contains("undo history cleared") })

        // Undo the removal: the Orbiter type is gone, so its JSON comes back unresolved.
        try #require(try session.undo.undo())
        #expect(world.get(UnresolvedComponents.self, for: sphere)?.components["Orbiter"] != nil)
        // The radius edit names a field of a type that is gone: it fails and is dropped.
        #expect(throws: (any Error).self) { try session.undo.undo() }
        // Undo adding the Orbiter: its JSON goes.
        try #require(try session.undo.undo())
        #expect(world.get(UnresolvedComponents.self, for: sphere) == nil)
        // Undo the Bobber edit: v2's Bobber with phase back to 0, its new fields defaulted.
        #expect(session.undo.undoLabel == "Phase")
        try #require(try session.undo.undo())
        var bobber = fields("Bobber", of: cube, in: world)
        #expect(bobber["phase"] == .float(0) && bobber["height"] == .float(2) && bobber["wobble"] == .float(0.25))
        #expect(bobber["amplitude"] == nil)
        try #require(try session.undo.redo())
        bobber = fields("Bobber", of: cube, in: world)
        #expect(bobber["phase"] == .float(0.75) && bobber["height"] == .float(2))
        #expect(ObjectIdentifier(type(of: try #require(world.component(named: "Bobber", of: cube))))
                == ObjectIdentifier(try #require(ComponentRegistry.type(named: "Bobber"))))

        // Back to v1: everything that was held as JSON decodes again; undo to the start works.
        try load("SampleGame", into: session)
        while session.undo.canUndo { try session.undo.undo() }
        #expect(world.component(named: "Bobber", of: cube) == nil)
        #expect(world.component(named: "Orbiter", of: sphere) == nil)
        #expect(world.get(UnresolvedComponents.self, for: sphere) == nil)
    }

    @Test func gameOfTwoTargetsLinksItsLibraryTarget() throws {
        let session = makeSession()
        defer { try? session.gameModule.unload() }
        let report = try load("GameModuleTestMultiTarget", into: session)
        #expect(report.module == "MultiTargetGame")
        #expect(report.libraryTargets == ["GameModuleTestLibrary"])
        #expect(report.components == ["GameModuleReloadTestsSpinner"])
        let cube = try #require(entity(named: "Red Cube", in: session.world))
        try session.commands.run(ComponentAddCommand.self, .init(entity: try #require(session.world.id(of: cube)), component: "GameModuleReloadTestsSpinner"))
        session.play(paused: true)
        session.step(frames: 3, dt: 1.0 / 60)
        #expect(fields("GameModuleReloadTestsSpinner", of: cube, in: session.world)["turned"] == .float(30))
        session.stop()
    }

    // MARK: Undo through JSON, without modules

    struct ScoreV1: Component, Equatable {
        static let componentName = "GameModuleReloadTestsScore"
        var points: Int
        var label: String
    }

    struct ScoreV2: Component, Equatable {
        static let componentName = "GameModuleReloadTestsScore"
        var points: Int
        var bonus: Float
        static let fallback = ScoreV2(points: 0, bonus: 1.5)
    }

    @Test func undoStepsDetachAndResolveIntoTheNewType() throws {
        let world = World()
        let undo = UndoStack(world: world)
        let e = world.spawn(Name("e"))
        ComponentRegistry.register(ScoreV1.self)
        defer { ComponentRegistry.unregister(["GameModuleReloadTestsScore"]) }
        try undo.perform(AddComponentCommand(e, ScoreV1(points: 1, label: "a"), in: world))
        try undo.perform(SetComponentCommand(e, to: ScoreV1(points: 5, label: "b"), in: world))
        try undo.perform(RemoveComponentCommand(e, ScoreV1.self, in: world))

        // The reload: world and history to JSON, the type replaced.
        try world.detachComponents(named: ["GameModuleReloadTestsScore"])
        try undo.detachComponents(named: ["GameModuleReloadTestsScore"])
        ComponentRegistry.unregister(["GameModuleReloadTestsScore"])
        // Undo while no type has the name: the removed value comes back as JSON.
        try undo.undo()
        #expect(world.get(UnresolvedComponents.self, for: e)?.components["GameModuleReloadTestsScore"] != nil)
        try undo.redo()
        #expect(world.get(UnresolvedComponents.self, for: e) == nil)

        ComponentRegistry.register(ScoreV2.self)
        let defaults: (String) -> (any Component)? = { $0 == ScoreV2.componentName ? ScoreV2.fallback : nil }
        #expect(undo.resolveDetachedComponents(defaults: defaults) == 4)  // add, old + new of the set, the removed one
        try undo.undo()
        #expect(world.get(ScoreV2.self, for: e) == ScoreV2(points: 5, bonus: 1.5))
        try undo.undo()
        #expect(world.get(ScoreV2.self, for: e) == ScoreV2(points: 1, bonus: 1.5))
        try undo.undo()
        #expect(world.get(ScoreV2.self, for: e) == nil && !undo.canUndo)
        try undo.redo()
        try undo.redo()
        try undo.redo()
        #expect(world.get(ScoreV2.self, for: e) == nil && world.get(UnresolvedComponents.self, for: e) == nil)
    }
}

// MARK: Pure parts: build plans, target lists, recovery files

@MainActor
@Suite struct GameModuleReloadTests {
    private var scratch: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("GameModuleReloadTests-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func targetsOutsideTheHostAreLibraryTargets() throws {
        let json = """
            {"targets": [
              {"name": "Game", "path": "Sources/Game", "target_dependencies": ["Engine", "GameKit"]},
              {"name": "GameKit", "path": "Sources/GameKit", "target_dependencies": ["Engine", "GameMath", "EngineMCP"]},
              {"name": "GameMath", "path": "Sources/GameMath"},
              {"name": "Engine", "path": "Sources/Engine", "target_dependencies": ["EngineMCP", "CZlib"]},
              {"name": "EngineMCP", "path": "Sources/EngineMCP"},
              {"name": "CZlib", "path": "Sources/CZlib"},
              {"name": "Editor", "path": "Sources/Editor", "target_dependencies": ["Engine"]}
            ]}
            """
        let targets = try GamePackageTargets.from(description: Data(json.utf8), target: "Game", packageURL: URL(fileURLWithPath: "/p"))
        #expect(targets.libraryTargets == ["GameMath", "GameKit"])
        #expect(targets.folders == ["Game": "/p/Sources/Game", "GameKit": "/p/Sources/GameKit", "GameMath": "/p/Sources/GameMath"])
        #expect(throws: GameModuleError.self) { try GamePackageTargets.from(description: Data(json.utf8), target: "Nope", packageURL: URL(fileURLWithPath: "/p")) }
    }

    @Test func buildPlanFromVerboseSwiftBuildOutput() throws {
        let folder = scratch
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let list = folder.appendingPathComponent("Game.SwiftFileList")
        try "/p/Sources/Game/B.swift\n/p/Sources/Game/A.swift\n".write(to: list, atomically: true, encoding: .utf8)
        let output = """
            Planning Swift module Game (arm64)
                builtin-SwiftDriver -- /tc/swiftc -module-name Game -Onone @\(list.path) -emit-module
            Compile Game (arm64)
                builtin-Swift-Compilation -- /tc/swiftc -parse-as-library -module-name Game -Onone @\(list.path) -DDEBUG -Xcc -fmodule-map-file\\=/p/x.modulemap -I /p/.build/Products -c -j10 -enable-batch-mode -incremental -output-file-map /o/map.json -emit-module -emit-module-path /o/Game.swiftmodule -index-store-path /o/index -Xfrontend -experimental-skip-non-inlinable-function-bodies -g
            Build complete!
            """
        let plan = try #require(GameModuleBuildPlan.capture(fromBuildOutput: output, target: "Game"))
        #expect(plan.arguments == ["/tc/swiftc", "-parse-as-library", "-module-name", "Game", "-Onone", "-DDEBUG", "-Xcc",
                                   "-fmodule-map-file=/p/x.modulemap", "-I", "/p/.build/Products", "-j10", "-g"])
        #expect(plan.sources == ["/p/Sources/Game/A.swift", "/p/Sources/Game/B.swift"])
        let command = plan.command(sources: plan.sources, objects: [URL(fileURLWithPath: "/o/Lib.o")], output: URL(fileURLWithPath: "/o/Game.dylib"))
        #expect(command.suffix(GameModuleBuilder.undefinedSymbolFlags.count + 5).prefix(5)
                == ["/p/Sources/Game/B.swift", "/o/Lib.o", "-emit-library", "-o", "/o/Game.dylib"])
        #expect(GameModuleBuildPlan.capture(fromBuildOutput: output, target: "Other") == nil)
        #expect(GameModuleBuildPlan.shellWords(#"a 'b c' "d e" f\ g h\=i"#) == ["a", "b c", "d e", "f g", "h=i"])
    }

    @Test func recoveryFilesSurviveACrashAndOpenUnsaved() throws {
        let folder = scratch
        defer { try? FileManager.default.removeItem(at: folder) }
        let scene = folder.appendingPathComponent("level.json")

        // The session that will "crash": a saved scene, then an unsaved edit.
        let first = makeSession()
        _ = first.save(as: scene.path)
        let recovery = EditorRecovery(session: first, folder: folder, installsCrashHook: false)
        recovery.update()
        #expect(!FileManager.default.fileExists(atPath: recovery.ownFolder.path))  // nothing unsaved
        let cube = try #require(entity(named: "Red Cube", in: first.world))
        _ = first.rename(try #require(first.world.id(of: cube)), to: "Recovered Cube")
        #expect(first.document.isDirty)
        recovery.update(now: Date().addingTimeInterval(2))
        // The fatal hook writes the prepared buffers (no Foundation file APIs).
        RecoveryBuffers.shared.writeAll()
        let manifest = try JSONDecoder.iso.decode(RecoveryInfo.self, from: Data(contentsOf: recovery.ownFolder.appendingPathComponent("recovery.json")))
        #expect(manifest.reason == "the editor crashed or was killed" && manifest.unsaved && manifest.sceneName == "level.json")
        RecoveryBuffers.shared.set([])
        // As if that process were gone: a pid nothing runs.
        let dead = folder.appendingPathComponent("99999999", isDirectory: true)
        try FileManager.default.moveItem(at: recovery.ownFolder, to: dead)

        // The next session offers and opens it.
        let second = makeSession()
        let next = EditorRecovery(session: second, folder: folder, installsCrashHook: false)
        second.recovery = next
        let list = try second.commands.run(SceneListRecoveryCommand.self)
        #expect(list.sessions.map(\.id) == ["99999999"])
        let info = try second.commands.run(SceneRecoverCommand.self, .init())
        #expect(info.scenePath == scene.path)
        #expect(entity(named: "Recovered Cube", in: second.world) != nil)
        #expect(second.document.isDirty && second.document.url?.path == scene.path)
        #expect(!FileManager.default.fileExists(atPath: dead.path))
        #expect(!second.commands.isAvailable(SceneRecoverCommand.id))

        // A clean exit with unsaved changes keeps them, saying why; without, nothing stays.
        next.finish(quitReason: "the window's close button was clicked")
        let kept = try JSONDecoder.iso.decode(RecoveryInfo.self, from: Data(contentsOf: next.ownFolder.appendingPathComponent("recovery.json")))
        #expect(kept.reason == "closed with unsaved changes (the window's close button was clicked)")
        _ = second.save()
        next.finish(quitReason: nil)
        #expect(!FileManager.default.fileExists(atPath: next.ownFolder.path))
    }
}

private extension JSONDecoder {
    static var iso: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
