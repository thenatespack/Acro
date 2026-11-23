import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineRendering

// The light probe tools as an agent uses them: lighting.bake (through the host's renderer) and
// lighting.debug, plus the components' Add Component entries and icons.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// A host whose renderer "bakes" by finishing the future when the test says so.
@MainActor private final class LightingToolsTestsHost: EditorHost {
    var bakes: [(world: ObjectIdentifier, future: CommandFuture<LightProbeBakeReport>)] = []
    func resetLayout() {}
    func frameSelection() {}
    func bakeLighting(in world: World) -> CommandFuture<LightProbeBakeReport>? {
        let future = CommandFuture<LightProbeBakeReport>()
        bakes.append((ObjectIdentifier(world), future))
        return future
    }
}

@MainActor
@Suite struct LightingToolsTests {
    @Test func probesAreAddableWithIcons() {
        EditorComponentCatalog.registerBuiltins()
        for name in [ReflectionProbe.componentName, IrradianceVolume.componentName] {
            #expect(EditorComponentCatalog.addableNames.contains(name))
            #expect(EditorIcons.componentIconNames[name] != nil)
        }
        let session = makeSession()
        let entity = session.world.spawn(Name("LightingToolsTests probe"), Transform(), IrradianceVolume())
        #expect(EditorIcons.entityKind(entity, in: session.world).component == IrradianceVolume.componentName)
    }

    @Test func bakeGoesThroughTheHostAndReportsWhatItBaked() throws {
        let session = makeSession()
        // Headless: unavailable, with the reason.
        #expect(throws: (any Error).self) { try session.commands.run(LightingBakeCommand.self, .init()) }

        let host = LightingToolsTestsHost()
        session.host = host
        // Nothing to bake: finished at once, with a warning, without the renderer.
        let empty = try session.commands.start(LightingBakeCommand.self, .init())
        guard case .success(let nothing)? = empty.outcome else { Issue.record("no result"); return }
        #expect(nothing.warnings.first?.contains("Nothing to bake") == true && host.bakes.isEmpty)

        session.world.spawn(Name("LightingToolsTests room"), Transform(), IrradianceVolume(countX: 2, countY: 2, countZ: 2))
        session.world.spawn(Name("LightingToolsTests mirror"), Transform(), ReflectionProbe())
        let future = try session.commands.start(LightingBakeCommand.self, .init(show: true))
        #expect(!future.isFinished && host.bakes.count == 1 && host.bakes[0].world == ObjectIdentifier(session.world))
        #expect(session.lightProbeDebug.showsProbes && session.sceneOverlays[EditorLightingCommands.overlayName] != nil)
        var report = LightProbeBakeReport()
        report.reflectionProbes = 1
        report.irradianceVolumes = 1
        report.irradianceProbes = 8
        report.milliseconds = 12.5
        report.warnings = ["IrradianceVolume 'LightingToolsTests room': 1 of 8 probes are inside geometry (turned off)"]
        report.cacheFiles = ["irradiance-abc.lightprobe"]
        host.bakes[0].future.resolve(report)
        guard case .success(let result)? = future.outcome else { Issue.record("no result"); return }
        #expect(result.irradianceProbes == 8 && result.milliseconds == 12.5)
        #expect(result.cacheFiles == ["Library/Lighting/irradiance-abc.lightprobe"])
        #expect(result.warnings.count == 1)
    }

    @Test func debugViewsToggleAndCountProbes() throws {
        let session = makeSession()
        session.world.spawn(Name("LightingToolsTests volume"), Transform(), IrradianceVolume(countX: 3, countY: 1, countZ: 2))
        session.world.spawn(Name("LightingToolsTests off"), Transform(), ReflectionProbe(isEnabled: false))
        var result = try session.commands.run(LightingDebugCommand.self, .init(probes: true, irradianceOnly: true))
        #expect(result.probes && result.irradianceOnly && !result.volumes)
        #expect(result.irradianceVolumes == 1 && result.irradianceProbes == 6 && result.reflectionProbes == 0)
        result = try session.commands.run(LightingDebugCommand.self, .init(volumes: true, irradianceOnly: false))
        #expect(result.probes && result.volumes && !result.irradianceOnly)
        #expect(session.lightProbeDebug == LightProbeDebug(showsProbes: true, irradianceOnly: false))
        // The overlay draws the volume's box and probe points.
        let draw = DebugDraw()
        session.sceneOverlays[EditorLightingCommands.overlayName]?(draw, session.world)
        #expect(!draw.isEmpty)
    }
}
