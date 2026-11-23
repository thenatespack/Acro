import EditorCore
import Engine
import Foundation

// `groom.preview`: one PNG of a groom grown on its preview (the `previewMesh`: a sphere by
// default, or a `.meshbuild`'s parts), from the front right in perspective and as a close-up of
// the surface, in a world of its own (studio light, still air), rendered by the host
// (`EditorHost.capture(world:views:)`) like `meshBuild.preview`.

public enum GroomPreviewCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable, GroomTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Each view's size in pixels (square; default 384).
        public var size: Int?
        /// Add a close-up of the surface (default true).
        public var closeUp: Bool?
        /// What lights it: studio (default), outdoor or flat.
        public var environment: MeshBuildPreviewEnvironment?
        public init(asset: AssetReference? = nil, path: String? = nil, size: Int? = nil, closeUp: Bool? = nil,
                    environment: MeshBuildPreviewEnvironment? = nil) {
            self.asset = asset
            self.path = path
            self.size = size
            self.closeUp = closeUp
            self.environment = environment
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The PNG (sent as image content over MCP).
        public var image: CommandImage
        public var summary: String
        public var warnings: [String]
    }

    public static let id: CommandID = "groom.preview"
    public static let title = "Preview Groom"
    public static let doc = "Returns one PNG of a .groom's fur grown on its previewMesh (a sphere by default, or a .meshbuild's parts): a 3/4 view from the front right and (closeUp, default true) a close-up of the surface, studio-lit (`environment` studio|outdoor|flat) in still air. `size`: tile pixels (default 384). Also returns a summary (style, length, detail levels, fur triangles on the preview mesh) and warnings. Read-only: shown in a world of its own. Finishes after a few frames. Needs the editor window."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) && session.host?.canRender == true }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.project == nil ? noProjectReason : "previews need the editor window and GPU (the editor is running headless)"
    }

    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<Result> {
        let (id, build) = try session.resolveGroom(arguments, title)
        guard let host = session.host, let assets = session.assets else {
            throw CommandError.failed(unavailableReason(in: session) ?? "No window")
        }
        if let error = assets.record(id)?.importError { throw CommandError.failed("\(title): the groom didn't import: \(error)") }
        guard let prefab = assets.prefab(AssetReference(id)) else { throw CommandError.failed("\(title): the groom didn't import") }
        let world = World()
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.2, castsShadows: true, shadowExtent: 3))
        var environment = (arguments.environment ?? .studio).sceneEnvironment
        environment.wind = .calm
        world.spawn(Name("Environment"), environment)
        guard let root = world.instantiate(prefab).first else { throw CommandError.failed("\(title): the preview didn't load") }
        world.propagateTransforms()

        // Frame the furred meshes.
        let fur = assets.material(AssetReference(id, subAsset: GroomRenderer.furSubAsset))?.fur ?? MaterialFur(groom: build)
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        var furTriangles = 0
        var warnings = GroomCheck.problems(build)
        var stack = [root]
        while let e = stack.popLast() {
            stack += world.children(of: e)
            guard let renderer = world.get(MeshRenderer.self, for: e),
                  let geometry = renderer.mesh.assetReference.flatMap({ assets.mesh($0) }) ?? MeshGeometry.builtin(renderer.mesh) else { continue }
            let b = geometry.bounds.transformed(by: world.get(GlobalTransform.self, for: e)?.matrix ?? world.worldMatrix(of: e))
            lo = pointwiseMin(lo, b.center - b.halfExtent)
            hi = pointwiseMax(hi, b.center + b.halfExtent)
            if world.get(GroomRenderer.self, for: e) != nil {
                let report = GroomGeometry.report(geometry, fur: fur)
                furTriangles += report.furTriangles
                warnings += report.warnings.filter { !warnings.contains($0) }
            }
        }
        guard lo.x <= hi.x else { throw CommandError.failed("\(title): the preview has no mesh") }
        let pad = Vec3(repeating: build.clampedLength)
        lo -= pad
        hi += pad
        let size = min(max(arguments.size ?? 384, 96), 1024)
        let center = (lo + hi) / 2
        let radius = max(length(hi - lo) / 2, 0.05)
        let fov: Float = 35 * .pi / 180
        func view(direction: Vec3, distance: Float, target: Vec3) -> SceneView {
            SceneView(view: Mat4.lookAt(eye: target + normalize(direction) * distance, target: target),
                      projection: Mat4.perspective(fovY: fov, aspect: 1, near: max(distance * 0.05, 0.005), far: distance + radius * 4 + 1),
                      clearColor: Vec4(0.12, 0.13, 0.15, 1))
        }
        let whole = radius / sinf(fov / 2) * 1.05
        var views = [WorldCaptureView(view: view(direction: Vec3(1, 0.6, 1.3), distance: whole, target: center), width: size, height: size,
                                      title: "3/4 front right")]
        if arguments.closeUp ?? true {
            // A spot on the upper front of the surface, seen from a hand's width away.
            let spot = Vec3(center.x, center.y + (hi.y - center.y) * 0.35, hi.z - pad.z)
            views.append(WorldCaptureView(view: view(direction: Vec3(0.4, 0.5, 1), distance: max(radius * 0.55, build.clampedLength * 8),
                                                     target: spot), width: size, height: size, title: "Close-up"))
        }
        let levels = build.drawnStyle == .shell ? build.shellLevels.map(String.init).joined(separator: "/") + " shells"
            : build.cardLevels.map { String(format: "%g", $0) }.joined(separator: "/") + " of the cards"
        let summary = "\(assets.path(of: id) ?? ""): \(build.drawnStyle.rawValue) fur \(String(format: "%.3g", build.clampedLength)) m long on "
            + "'\(build.previewMesh.isEmpty ? "sphere" : build.previewMesh)'; detail levels \(levels) (at \(build.lodDistances.map { String(format: "%g", $0) }.joined(separator: ", ")) m); "
            + "about \(furTriangles) fur triangles at full detail"
        guard let future = host.capture(world: world, views: views) else { throw CommandError.failed("This editor can't render previews") }
        return future.map { tiles in
            guard tiles.count == views.count else { throw CommandError.failed("\(title): a view didn't render") }
            return Result(image: CommandImage(png: MeshBuildPreviewScene.compose(tiles)), summary: summary, warnings: warnings)
        }
    }
}
