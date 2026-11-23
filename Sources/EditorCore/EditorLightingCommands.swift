import Engine
import Foundation

// The light probe tools: `lighting.bake` bakes the current world's ReflectionProbes and
// IrradianceVolumes on the GPU (through the host's renderer, so it finishes a few frames later)
// and caches them in the project's Library/Lighting, which the cooker ships with exported games;
// `lighting.debug` shows the probes (spheres, boxes) and the irradiance-only view in the Scene view.

/// The lighting tools.
@MainActor
public enum EditorLightingCommands {
    public static let all: [any EditorCommand.Type] = [LightingBakeCommand.self, LightingDebugCommand.self]

    static let overlayName = "lighting"

    /// Shows or hides the probe boxes overlay of `session` (influence boxes, volumes and their probes).
    static func setVolumesOverlay(_ show: Bool, in session: EditorSession) {
        guard show else {
            session.sceneOverlays[overlayName] = nil
            return
        }
        session.sceneOverlays[overlayName] = { draw, world in LightProbeDebug.drawVolumes(of: world, into: draw) }
    }

    /// The light probes `world` has: reflection probes, irradiance volumes and their probes.
    static func counts(in world: World) -> (reflection: Int, volumes: Int, probes: Int) {
        var reflection = 0, volumes = 0, probes = 0
        world.query(ReflectionProbe.self) { _, probe in if probe.isEnabled { reflection += 1 } }
        world.query(IrradianceVolume.self) { _, volume in
            guard volume.isEnabled else { return }
            volumes += 1
            probes += volume.probeCount
        }
        return (reflection, volumes, probes)
    }
}

public enum LightingBakeCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Show the probe spheres and boxes in the Scene view afterwards (default: leave the debug views as they are).
        public var show: Bool?
        public init(show: Bool? = nil) { self.show = show }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var reflectionProbes: Int
        public var irradianceVolumes: Int
        public var irradianceProbes: Int
        /// Irradiance probes found inside geometry (turned off).
        public var probesInsideGeometry: Int
        public var bounces: Int
        /// From the start of the bake until its results were read back, GPU time included.
        public var milliseconds: Double
        /// Probes inside geometry, empty boxes, volumes without probes.
        public var warnings: [String]
        /// The bakes written to the project's Library (paths relative to the project).
        public var cacheFiles: [String]

        init(_ report: LightProbeBakeReport) {
            reflectionProbes = report.reflectionProbes
            irradianceVolumes = report.irradianceVolumes
            irradianceProbes = report.irradianceProbes
            probesInsideGeometry = report.probesInsideGeometry
            bounces = report.bounces
            milliseconds = report.milliseconds
            warnings = report.warnings
            cacheFiles = report.cacheFiles.map { "Library/\(LightProbeBakeCache.libraryFolder)/\($0)" }
        }
    }

    public static let id: CommandID = "lighting.bake"
    public static let title = "Bake Lighting"
    public static let doc = "Bakes the light probes of the current world (the play world while playing) on the GPU: every ReflectionProbe (a box-projected reflection captured from its point, blended by its influence box with `blendDistance`) and IrradianceVolume (a grid of L2 spherical-harmonic probes giving indirect diffuse light to everything in its box, `bounces` light bounces). Reports the probe counts, the bake time and warnings (irradiance probes inside geometry, which are turned off; volumes with no probes; empty boxes; reflection probes capturing from inside geometry). Bakes are cached in the project's Library/Lighting by what they were baked from and cooked into exported games, which load them instead of baking. Finishes a few frames later. Needs the editor window (GPU). Game code: `SceneRenderer.bakeProbes`."
    public static func isAvailable(in session: EditorSession) -> Bool { session.host?.canRender == true }
    public static func unavailableReason(in session: EditorSession) -> String? {
        "baking light probes needs the editor window and GPU (the editor is running headless)"
    }

    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<Result> {
        let counts = EditorLightingCommands.counts(in: session.world)
        guard counts.reflection + counts.volumes > 0 else {
            var report = LightProbeBakeReport()
            report.warnings = ["Nothing to bake: the world has no enabled ReflectionProbe or IrradianceVolume (add one with component.add)"]
            return CommandFuture(Result(report))
        }
        guard let host = session.host, let future = host.bakeLighting(in: session.world) else {
            throw CommandError.failed(unavailableReason(in: session) ?? "No window")
        }
        if let show = arguments.show {
            session.lightProbeDebug.showsProbes = show
            EditorLightingCommands.setVolumesOverlay(show, in: session)
        }
        session.log.info("Baking light probes: \(counts.reflection) reflection, \(counts.probes) irradiance")
        return future.map { [weak session] report in
            session?.log.info("Baked light probes in \(Int(report.milliseconds)) ms" + (report.warnings.isEmpty ? "" : " (\(report.warnings.count) warnings)"))
            for warning in report.warnings { session?.log.warning(warning) }
            return Result(report)
        }
    }
}

public enum LightingDebugCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Draw a sphere at every probe: reflection probes as mirror balls showing their baked
        /// image, irradiance probes shaded by their light (red: inside geometry).
        public var probes: Bool?
        /// Draw the reflection probes' influence (and projection) boxes and the irradiance volumes.
        public var volumes: Bool?
        /// Shade every surface with its indirect diffuse light only (the probes', or the sky's).
        public var irradianceOnly: Bool?
        public init(probes: Bool? = nil, volumes: Bool? = nil, irradianceOnly: Bool? = nil) {
            self.probes = probes
            self.volumes = volumes
            self.irradianceOnly = irradianceOnly
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var probes: Bool
        public var volumes: Bool
        public var irradianceOnly: Bool
        /// Enabled probes in the current world.
        public var reflectionProbes: Int
        public var irradianceVolumes: Int
        public var irradianceProbes: Int
    }

    public static let id: CommandID = "lighting.debug"
    public static let title = "Light Probe Views"
    public static let doc = "Shows or hides the light probe debug views in the Scene view (what isn't given stays as it is): `probes` draws a sphere at every baked probe (reflection probes as mirror balls showing their image, irradiance probes shaded by their SH, red inside geometry), `volumes` the reflection probes' influence and projection boxes and the irradiance volumes with their probe points, `irradianceOnly` shades every surface with its indirect diffuse light only. Returns the views' state and the probe counts. view.screenshot shows them (boxes with gizmos on)."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if let probes = arguments.probes { session.lightProbeDebug.showsProbes = probes }
        if let irradianceOnly = arguments.irradianceOnly { session.lightProbeDebug.irradianceOnly = irradianceOnly }
        if let volumes = arguments.volumes { EditorLightingCommands.setVolumesOverlay(volumes, in: session) }
        let counts = EditorLightingCommands.counts(in: session.world)
        return Result(probes: session.lightProbeDebug.showsProbes, volumes: session.sceneOverlays[EditorLightingCommands.overlayName] != nil,
                      irradianceOnly: session.lightProbeDebug.irradianceOnly, reflectionProbes: counts.reflection,
                      irradianceVolumes: counts.volumes, irradianceProbes: counts.probes)
    }
}
