import Engine
import EngineMCP
import Foundation

// Commands that let a remote caller see what the user sees: screenshots of the viewport, the
// game camera, any camera, the window, a panel or an asset thumbnail (`view.screenshot`),
// picking at a pixel of such a picture or along a ray (`view.pick`, `scene.raycast`), the
// console (`log.read`), frame and GPU numbers (`stats.get`) and problems (`diagnostics.get`).
//
// Screenshots need the GPU, so they go through the host (`EditorHost.capture`): the command
// starts a capture and returns a future, the app renders it in the next frame's offscreen pass
// (or reads the window back at the end of that frame) and fulfills the future; the MCP server
// answers once it is fulfilled. Nothing waits in between, so a screenshot costs the frame that
// renders it and the GPU wait at its end. Picking runs on the CPU (`ScenePicker`), so it works
// headless for every view but the viewport, whose camera lives in the window.

// MARK: Views

/// What `view.screenshot` shows (and `view.pick` picks in).
public enum ScreenshotSource: String, Codable, CaseIterable, Sendable {
    /// The scene viewport, from the editor camera, as the user sees it.
    case viewport
    /// The scene's Camera entity (`camera`, else the first one), as the game sees it.
    case game
    /// A camera at `eye` looking at `target`; the user's view doesn't move.
    case camera
    /// The whole editor window.
    case window
    /// One dock panel (`panel`: viewport, hierarchy, inspector, console, stats, assets).
    case panel
    /// An asset's thumbnail (`asset`), as the asset browser shows it.
    case thumbnail
}

/// A screenshot for `EditorHost.capture` to render.
public struct ScreenshotRequest: Sendable {
    public var source: ScreenshotSource
    /// The view for `.game` and `.camera`; nil for `.viewport` (its view when it renders).
    public var view: SceneView?
    /// The image size in pixels for `.viewport`, `.game` and `.camera`.
    public var width: Int
    public var height: Int
    /// What the viewport draws over the scene: the grid, camera / light gizmos and the
    /// transform gizmo, and the selection outline.
    public var grid: Bool
    public var gizmos: Bool
    public var outline: Bool
    /// `.panel`: the dock panel id (`EditorLayout`).
    public var panel: String?
    /// `.thumbnail`: the asset or object.
    public var asset: AssetReference?

    public init(source: ScreenshotSource, view: SceneView? = nil, width: Int = 0, height: Int = 0, grid: Bool = true,
                gizmos: Bool = true, outline: Bool = true, panel: String? = nil, asset: AssetReference? = nil) {
        self.source = source
        self.view = view
        self.width = width
        self.height = height
        self.grid = grid
        self.gizmos = gizmos
        self.outline = outline
        self.panel = panel
        self.asset = asset
    }
}

/// An image in a command result. In JSON `data` is the PNG, base64-encoded; the MCP server
/// sends it as image content instead and leaves `data` out of the structured result.
public struct CommandImage: Codable, Equatable, Sendable {
    public var mimeType: String
    public var width: Int
    public var height: Int
    /// Base64 of the file.
    public var data: String?

    public init(png image: Image) {
        mimeType = "image/png"
        width = image.width
        height = image.height
        data = image.pngData().base64EncodedString()
    }

    /// The decoded file.
    public var bytes: Data? { data.flatMap { Data(base64Encoded: $0) } }
}

/// The view arguments `view.screenshot` and `view.pick` share, so a pixel of a screenshot is
/// picked by repeating its arguments with `x` and `y`.
struct ViewSpec {
    var source: ScreenshotSource
    var camera: EntityID?
    var eye: Vec3?
    var target: Vec3?
    var fov: Float?
    var width: Int?
    var height: Int?
    var maxSize: Int?

    static let defaultSize = (width: 1280, height: 720)
}

/// A camera view at a size, ready to render or pick in.
struct ResolvedView {
    /// nil for the viewport when its view is taken at render time.
    var view: SceneView
    var width: Int
    var height: Int
    /// The camera entity of `.game`.
    var camera: EntityID?
}

extension EditorSession {
    /// The view `spec` names, at its size in pixels (before `maxSize`).
    func resolveView(_ spec: ViewSpec) throws -> ResolvedView {
        let viewport = host?.viewportView
        func size(_ fallback: (width: Int, height: Int)) -> (Int, Int) {
            (min(max(spec.width ?? fallback.width, 16), 4096), min(max(spec.height ?? fallback.height, 16), 4096))
        }
        let defaultSize = viewport.map { ($0.width, $0.height) } ?? ViewSpec.defaultSize
        switch spec.source {
        case .viewport:
            guard let viewport else {
                throw CommandError.failed("The viewport needs the editor window (headless: use source \"game\" or \"camera\")")
            }
            return ResolvedView(view: viewport.view, width: viewport.width, height: viewport.height)
        case .game:
            let entity: Entity
            if let id = spec.camera {
                entity = try world.require(id)
            } else {
                guard let found = RenderPrep.findCamera(in: world)?.entity else {
                    throw CommandError.failed("The scene has no Camera entity (use source \"camera\" with eye and target)")
                }
                entity = found
            }
            let (width, height) = size(defaultSize)
            guard let view = SceneView(camera: entity, in: world, aspect: Float(width) / Float(height)) else {
                throw CommandError.failed("\(displayName(of: entity)) has no Camera component")
            }
            return ResolvedView(view: view, width: width, height: height, camera: world.id(of: entity))
        case .camera:
            guard let eye = spec.eye, let target = spec.target else {
                throw CommandError.failed("Source \"camera\" needs `eye` and `target` ([x, y, z])")
            }
            guard length(target - eye) > 1e-5 else { throw CommandError.failed("`eye` and `target` must differ") }
            let (width, height) = size(defaultSize)
            let up = abs(normalize(target - eye).y) > 0.999 ? Vec3(0, 0, -1) : Vec3(0, 1, 0)
            let fov = min(max(spec.fov ?? 60, 1), 170) * .pi / 180
            let view = SceneView(view: Mat4.lookAt(eye: eye, target: target, up: up),
                                 projection: Mat4.perspective(fovY: fov, aspect: Float(width) / Float(height), near: 0.05, far: 1000),
                                 clearColor: viewportClearColor)
            return ResolvedView(view: view, width: width, height: height)
        case .window, .panel, .thumbnail:
            throw CommandError.failed("Source \"\(spec.source.rawValue)\" isn't a camera view")
        }
    }

    /// What the viewport clears to: the scene's fog color when it has fog.
    var viewportClearColor: Vec4 {
        let environment = RenderPrep.findEnvironment(in: world)
        return environment.fogDensity > 0 ? Vec4(environment.fogColor, 1) : Vec4(0.08, 0.09, 0.11, 1)
    }
}

/// The size of `width` x `height` scaled down so its longer side is at most `maxSize`
/// (`AssetThumbnails.downsample`'s rounding).
func downsampledSize(width: Int, height: Int, maxSize: Int?) -> (width: Int, height: Int) {
    guard let maxSize, maxSize > 0, max(width, height) > maxSize else { return (width, height) }
    let factor = Float(max(width, height)) / Float(maxSize)
    return (max(1, Int((Float(width) / factor).rounded())), max(1, Int((Float(height) / factor).rounded())))
}

// MARK: Screenshots

public enum ViewScreenshotCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// What to show (default "viewport").
        public var source: ScreenshotSource?
        /// "game": this Camera entity (default: the scene's first camera).
        public var camera: EntityID?
        /// "camera": where it is and what it looks at ([x, y, z]), and the vertical field of
        /// view in degrees (default 60).
        public var eye: Vec3?
        public var target: Vec3?
        public var fov: Float?
        /// "game" / "camera": the image size in pixels (default: the viewport's, else 1280x720).
        public var width: Int?
        public var height: Int?
        /// Scale the image down so its longer side is at most this many pixels.
        public var maxSize: Int?
        /// Draw the grid, the camera / light gizmos and transform gizmo, the selection outline
        /// (default: on for "viewport", off for "game" and "camera").
        public var grid: Bool?
        public var gizmos: Bool?
        public var outline: Bool?
        /// "panel": viewport, hierarchy, inspector, console, stats or assets.
        public var panel: String?
        /// "thumbnail": the asset or object (asset:<id>[#<object>]).
        public var asset: AssetReference?

        public init(source: ScreenshotSource? = nil, camera: EntityID? = nil, eye: Vec3? = nil, target: Vec3? = nil,
                    fov: Float? = nil, width: Int? = nil, height: Int? = nil, maxSize: Int? = nil, grid: Bool? = nil,
                    gizmos: Bool? = nil, outline: Bool? = nil, panel: String? = nil, asset: AssetReference? = nil) {
            self.source = source
            self.camera = camera
            self.eye = eye
            self.target = target
            self.fov = fov
            self.width = width
            self.height = height
            self.maxSize = maxSize
            self.grid = grid
            self.gizmos = gizmos
            self.outline = outline
            self.panel = panel
            self.asset = asset
        }

        var viewSpec: ViewSpec {
            ViewSpec(source: source ?? .viewport, camera: camera, eye: eye, target: target, fov: fov, width: width, height: height,
                     maxSize: maxSize)
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The PNG (sent as image content over MCP).
        public var image: CommandImage
        public var source: ScreenshotSource
        /// Camera views: where the camera is and the direction it looks in.
        public var eye: Vec3?
        public var forward: Vec3?
        /// "game": the camera entity.
        public var camera: EntityID?
    }

    public static let id: CommandID = "view.screenshot"
    public static let title = "Screenshot"
    public static let doc = "Returns a PNG of `source`: \"viewport\" (default; what the user sees, from the editor camera), \"game\" (the scene's Camera, or `camera`), \"camera\" (from `eye` looking at `target`, `fov` degrees, without moving the user's view), \"window\", \"panel\" (`panel`) or \"thumbnail\" (`asset`). `grid`, `gizmos` and `outline` toggle the viewport overlays; `maxSize` scales it down. Finishes after the next frame renders. Needs the editor window."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.host != nil }
    public static func unavailableReason(in session: EditorSession) -> String? {
        "screenshots need the editor window and GPU (the editor is running headless)"
    }

    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<Result> {
        guard let host = session.host else { throw CommandError.failed(unavailableReason(in: session) ?? "No window") }
        let spec = arguments.viewSpec
        var request = ScreenshotRequest(source: spec.source)
        var described: ResolvedView?
        switch spec.source {
        case .viewport, .game, .camera:
            let resolved = try session.resolveView(spec)
            described = resolved
            request.view = spec.source == .viewport ? nil : resolved.view
            request.width = resolved.width
            request.height = resolved.height
            let overlays = spec.source == .viewport
            request.grid = arguments.grid ?? overlays
            request.gizmos = arguments.gizmos ?? overlays
            request.outline = arguments.outline ?? overlays
        case .window:
            break
        case .panel:
            guard let panel = arguments.panel, EditorLayout.panelIDs.contains(panel) else {
                throw CommandError.failed("Source \"panel\" needs `panel`: one of \(EditorLayout.panelIDs.joined(separator: ", "))")
            }
            request.panel = panel
        case .thumbnail:
            guard let asset = arguments.asset else { throw CommandError.failed("Source \"thumbnail\" needs `asset`") }
            guard let assets = session.assets else { throw CommandError.failed("No project is open (run project.open first)") }
            guard assets.record(asset.asset) != nil else { throw CommandError.failed("No asset \(asset)") }
            request.asset = asset
        }
        guard let future = host.capture(request) else {
            throw CommandError.failed("This editor can't take screenshots")
        }
        let maxSize = arguments.maxSize
        return future.map { image in
            var image = image
            if let maxSize, max(image.width, image.height) > maxSize { image = AssetThumbnails.downsample(image, to: maxSize) }
            return Result(image: CommandImage(png: image), source: spec.source, eye: described?.view.eye,
                          forward: described?.view.forward, camera: described?.camera)
        }
    }
}

// MARK: Picking

/// What `view.pick` and `scene.raycast` hit.
public struct PickResult: Codable, Equatable, Sendable {
    public var hit: Bool
    public var entity: EntityID?
    public var name: String?
    /// The surface point and its normal, in world space.
    public var point: Vec3?
    public var normal: Vec3?
    public var distance: Float?
    /// The ray that was cast.
    public var origin: Vec3
    public var direction: Vec3
}

extension EditorSession {
    /// The closest pickable entity along `ray` (exactly against its triangles).
    func pick(_ ray: Ray, maxDistance: Float? = nil) -> PickResult {
        let picker = ScenePicker(meshes: pickMeshes)
        guard let hit = picker.pick(ray, in: world), hit.distance <= (maxDistance ?? .infinity) else {
            return PickResult(hit: false, origin: ray.origin, direction: ray.direction)
        }
        return PickResult(hit: true, entity: world.id(of: hit.entity), name: displayName(of: hit.entity), point: hit.point,
                          normal: hit.normal, distance: hit.distance, origin: ray.origin, direction: ray.direction)
    }
}

public enum ViewPickCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The pixel, from the top left, in the image `view.screenshot` returns for the same
        /// view arguments (with `maxSize`, in the scaled image).
        public var x: Float
        public var y: Float
        /// The view, as for view.screenshot: "viewport" (default), "game" or "camera".
        public var source: ScreenshotSource?
        public var camera: EntityID?
        public var eye: Vec3?
        public var target: Vec3?
        public var fov: Float?
        public var width: Int?
        public var height: Int?
        public var maxSize: Int?

        public init(x: Float, y: Float, source: ScreenshotSource? = nil, camera: EntityID? = nil, eye: Vec3? = nil,
                    target: Vec3? = nil, fov: Float? = nil, width: Int? = nil, height: Int? = nil, maxSize: Int? = nil) {
            self.x = x
            self.y = y
            self.source = source
            self.camera = camera
            self.eye = eye
            self.target = target
            self.fov = fov
            self.width = width
            self.height = height
            self.maxSize = maxSize
        }
    }

    public static let id: CommandID = "view.pick"
    public static let title = "Pick"
    public static let doc = "Returns the entity and surface point (world space, with the normal) at pixel (`x`, `y`) of a view: pass the same view arguments as view.screenshot (source \"viewport\" (default), \"game\" or \"camera\", camera, eye, target, fov, width, height, maxSize) to pick in its image. \"game\" and \"camera\" work headless."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PickResult {
        let spec = ViewSpec(source: arguments.source ?? .viewport, camera: arguments.camera, eye: arguments.eye,
                            target: arguments.target, fov: arguments.fov, width: arguments.width, height: arguments.height,
                            maxSize: arguments.maxSize)
        let resolved = try session.resolveView(spec)
        let image = downsampledSize(width: resolved.width, height: resolved.height, maxSize: spec.maxSize)
        let point = Vec2(arguments.x * Float(resolved.width) / Float(image.width),
                         arguments.y * Float(resolved.height) / Float(image.height))
        let projection = ViewportProjection(resolved.view, size: Vec2(Float(resolved.width), Float(resolved.height)))
        return session.pick(projection.ray(through: point))
    }
}

public enum SceneRaycastCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// World-space start and direction ([x, y, z]; needn't be normalized).
        public var origin: Vec3
        public var direction: Vec3
        /// Ignore hits farther than this.
        public var maxDistance: Float?
        public init(origin: Vec3, direction: Vec3, maxDistance: Float? = nil) {
            self.origin = origin
            self.direction = direction
            self.maxDistance = maxDistance
        }
    }

    public static let id: CommandID = "scene.raycast"
    public static let title = "Raycast"
    public static let doc = "Casts a ray from world-space `origin` along `direction` and returns the first entity it hits exactly (against its triangles), with the point, normal and distance."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PickResult {
        guard length(arguments.direction) > 1e-6 else { throw CommandError.failed("`direction` must not be zero") }
        return session.pick(Ray(origin: arguments.origin, direction: arguments.direction), maxDistance: arguments.maxDistance)
    }
}

// MARK: Console, stats, diagnostics

/// A log level by name.
public enum LogLevelName: String, Codable, CaseIterable, Sendable {
    case info, warning, error

    var level: LogLevel {
        switch self {
        case .info: .info
        case .warning: .warning
        case .error: .error
        }
    }

    init(_ level: LogLevel) {
        switch level {
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        }
    }
}

/// One console line.
public struct LogLine: Codable, Equatable, Sendable {
    /// Increases by one per message; pass the last one + 1 as `since` to read only new ones.
    public var sequence: Int
    public var level: LogLevelName
    public var message: String
    /// Seconds since the editor started.
    public var time: Double

    init(_ entry: LogEntry) {
        sequence = entry.sequence
        level = LogLevelName(entry.level)
        message = entry.message
        time = entry.time
    }
}

public enum LogReadCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only messages at this level or above ("info", "warning", "error"; default all).
        public var level: LogLevelName?
        /// Only messages with `sequence` at least this (the `next` of an earlier read).
        public var since: Int?
        /// Only messages containing this text (any case).
        public var contains: String?
        /// At most this many, the newest (default 100).
        public var limit: Int?
        public init(level: LogLevelName? = nil, since: Int? = nil, contains: String? = nil, limit: Int? = nil) {
            self.level = level
            self.since = since
            self.contains = contains
            self.limit = limit
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entries: [LogLine]
        /// Pass as `since` to read only what comes after.
        public var next: Int
    }

    public static let id: CommandID = "log.read"
    public static let title = "Read Console"
    public static let doc = "Returns console messages, oldest first: at `level` or above, from sequence `since` on, containing `contains`, the newest `limit` (default 100). `next` is the `since` for the following read. The editor://log resource (and editor://log/{level}) is the same, subscribable."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let log = session.log
        let text = arguments.contains?.lowercased()
        let entries = log.entries(atLeast: arguments.level?.level ?? .info).filter { entry in
            entry.sequence >= (arguments.since ?? 0) && (text.map { entry.message.lowercased().contains($0) } ?? true)
        }
        return Result(entries: entries.suffix(max(arguments.limit ?? 100, 0)).map(LogLine.init), next: log.nextSequence)
    }
}

/// One pass's GPU time.
public struct PassTimeInfo: Codable, Equatable, Sendable {
    public var name: String
    public var milliseconds: Double
}

public enum StatsGetCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// Frame numbers; nil headless (no renderer).
        public var fps: Double?
        public var frameMilliseconds: Double?
        public var updateMilliseconds: Double?
        public var renderMilliseconds: Double?
        public var uiPaintMilliseconds: Double?
        /// GPU time of a recent frame and its passes, when the backend measures them.
        public var gpuMilliseconds: Double?
        public var gpuPasses: [PassTimeInfo]
        public var drawCalls: Int?
        public var triangles: Int?
        /// "metal" or "vulkan", and the GPU.
        public var backend: String?
        public var device: String?
        /// The viewport's size in pixels and what it drew.
        public var viewport: [Int]?
        public var viewportDrawn: Int?
        public var viewportCulled: Int?
        public var entities: Int
        public var undoDepth: Int
        public var redoDepth: Int
        public var playing: Bool
    }

    public static let id: CommandID = "stats.get"
    public static let title = "Stats"
    public static let doc = "Returns the stats panel's numbers: FPS, frame / CPU / GPU times in milliseconds with each GPU pass, draw calls, triangles, the viewport's size and culling, entity count, undo depth and play state. Frame numbers are missing headless."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let stats = session.host?.frameStats
        let frame = stats?.frame
        func ms(_ seconds: Double?) -> Double? { seconds.map { ($0 * 1e6).rounded() / 1e3 } }
        return Result(fps: frame.map { ($0.fps * 10).rounded() / 10 }, frameMilliseconds: ms(frame?.frameTime),
                      updateMilliseconds: ms(frame?.updateTime), renderMilliseconds: ms(frame?.renderTime),
                      uiPaintMilliseconds: ms(stats?.uiPaintTime), gpuMilliseconds: ms(frame?.gpuTime),
                      gpuPasses: frame?.gpuPassTimes.map { PassTimeInfo(name: $0.name, milliseconds: ms($0.seconds) ?? 0) } ?? [],
                      drawCalls: frame?.drawCalls, triangles: frame?.triangles,
                      backend: stats.flatMap { $0.backend.isEmpty ? nil : $0.backend },
                      device: stats.flatMap { $0.deviceName.isEmpty ? nil : $0.deviceName },
                      viewport: stats.map { [$0.viewportSize.width, $0.viewportSize.height] },
                      viewportDrawn: stats?.viewportDrawn, viewportCulled: stats?.viewportCulled,
                      entities: session.world.entityCount, undoDepth: session.undo.undoDepth, redoDepth: session.undo.redoDepth,
                      playing: session.isPlaying)
    }
}

/// An asset that failed to import.
public struct ImportProblem: Codable, Equatable, Sendable {
    /// Relative to `Assets/`.
    public var path: String
    public var message: String
}

public enum DiagnosticsGetCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// Assets whose import failed (fix the file or its settings, then they reimport).
        public var importErrors: [ImportProblem]
        /// Assets still importing in the background.
        public var importing: Int
        /// Graphics validation messages that reached the console (Vulkan's validation layer,
        /// with ENGINE_VULKAN_VALIDATION=1, through `EngineLog`).
        public var validation: [LogLine]
        /// Whether ENGINE_VULKAN_VALIDATION=1 is set.
        public var validationEnabled: Bool
        /// The latest warnings and errors in the console (at most 50).
        public var problems: [LogLine]
        public var backend: String?
    }

    public static let id: CommandID = "diagnostics.get"
    public static let title = "Diagnostics"
    public static let doc = "Returns what is wrong: assets whose import failed (with the importer's message), how many are still importing, graphics validation messages in the console, and the latest console warnings and errors."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let assets = session.assets
        let failed = assets?.allRecords.compactMap { record in
            record.importError.map { ImportProblem(path: record.path, message: $0) }
        } ?? []
        let problems = session.log.entries(atLeast: .warning)
        let validation = session.log.entries.filter { entry in
            ["validation error", "validation warning", "vuid-", "validation layer"].contains { entry.message.lowercased().contains($0) }
        }
        let backend = session.host?.frameStats?.backend
        return Result(importErrors: failed, importing: assets?.pendingLoadCount ?? 0, validation: validation.suffix(50).map(LogLine.init),
                      validationEnabled: ProcessInfo.processInfo.environment["ENGINE_VULKAN_VALIDATION"] == "1",
                      problems: problems.suffix(50).map(LogLine.init), backend: backend.flatMap { $0.isEmpty ? nil : $0 })
    }
}
