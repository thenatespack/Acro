import Engine
import Foundation

// `meshBuild.preview`: one PNG of a mesh build from several fixed angles, so an agent sees what it
// built in one call. The model is placed in a world of its own (light, environment, nothing
// else), never in the user's scene, and rendered by the host from cameras that don't touch the
// editor's (`EditorHost.capture(world:views:)`). Front, right and top are orthographic, so sizes
// and alignment read straight off the grid; the 3/4 view is a perspective.
//
// The engine's forward is -Z (cameras, lights and `transform.lookAt` look down local -Z), so a
// model's front faces -Z: the front view's camera is on the -Z side looking toward +Z, which puts
// +X on the image's left, as when facing someone.

/// The fixed views of `meshBuild.preview`.
public enum MeshBuildPreviewView: String, Codable, CaseIterable, Sendable {
    /// From -Z (the model's front), orthographic.
    case front
    /// From +X, orthographic.
    case right
    /// From above, front (-Z) up, orthographic.
    case top
    /// From the front right, above, in perspective.
    case threeQuarter
    /// From +Z, orthographic.
    case back
    /// From -X, orthographic.
    case left

    var title: String {
        switch self {
        case .front: "Front (from -Z)"
        case .right: "Right (from +X)"
        case .top: "Top (front -Z up)"
        case .threeQuarter: "3/4 front right"
        case .back: "Back (from +Z)"
        case .left: "Left (from -X)"
        }
    }

    /// For orthographic views: the direction from the model to the camera, and the image's up.
    var orthographic: (toCamera: Vec3, up: Vec3)? {
        switch self {
        case .front: (Vec3(0, 0, -1), Vec3(0, 1, 0))
        case .back: (Vec3(0, 0, 1), Vec3(0, 1, 0))
        case .right: (Vec3(1, 0, 0), Vec3(0, 1, 0))
        case .left: (Vec3(-1, 0, 0), Vec3(0, 1, 0))
        case .top: (Vec3(0, 1, 0), Vec3(0, 0, -1))
        case .threeQuarter: nil
        }
    }
}

/// A mesh build placed in a world of its own with the cameras of its preview (see the notes at the top of this file).
@MainActor
struct MeshBuildPreviewScene {
    static let defaultViews: [MeshBuildPreviewView] = [.front, .right, .top, .threeQuarter]
    static let defaultTileSize = 384
    static let tileSizes = 96...1024
    /// Room around the model in each tile.
    static let margin: Float = 1.15
    static let perspectiveFOV: Float = 35
    static let background = Vec4(0.12, 0.13, 0.15, 1)

    let world = World()
    /// Each part's entity, by name.
    private(set) var parts: [String: Entity] = [:]
    /// The posed model's box in world space.
    private(set) var lo = Vec3.zero
    private(set) var hi = Vec3.zero
    /// The grid's spacing, meters.
    private(set) var gridSpacing: Float = 1
    private(set) var views: [WorldCaptureView] = []

    /// Places `prefab` (the import of `build`), poses `animation` at `time`, and sets up `views`.
    /// `meshes` gives a mesh handle's geometry.
    init(build: MeshBuild, prefab: PrefabAsset, views: [MeshBuildPreviewView], tileSize: Int, labels: Bool, highlight: [String],
         animation: String?, time: Float?, environment: MeshBuildPreviewEnvironment = .studio,
         meshes: (MeshHandle) -> MeshGeometry?) throws {
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-55, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.2, castsShadows: true))
        world.spawn(Name("Environment"), environment.sceneEnvironment)
        world.addBuiltinAnimationSystems()
        guard let root = world.instantiate(prefab).first else { throw CommandError.failed("The mesh build's model didn't load") }
        var stack = world.children(of: root)
        while let entity = stack.popLast() {
            if let name = world.get(Name.self, for: entity)?.value, parts[name] == nil { parts[name] = entity }
            world.remove(FieldAnimator.self, from: entity)  // the rest pose unless an animation is asked for
            stack += world.children(of: entity)
        }
        world.propagateTransforms()
        if let animation { try pose(build, animation: animation, time: time) }

        // A sculpt with several looks draws a mesh per look on nodes of their own (MeshBuildSculptLooks.swift).
        let expansion = build.expansion()
        let sculpting = expansion.build.gatheringSculpts(sources: expansion.sources)
        let pieces = sculpting.splittingLooks(blending: true)  // blend layers are pieces too
        var pieceSculpt: [String: String] = [:]
        for (index, sculpt) in pieces.pieceOf { pieceSculpt[pieces.build.parts[index].name] = pieces.build.parts[sculpt].name }

        // The posed model's box, from the meshes as placed; a label per part (a sculpt's over all its looks).
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        var labelBoxes: [String: (Vec3, Vec3)] = [:]
        for (name, entity) in parts.sorted(by: { $0.key < $1.key }) {
            guard let renderer = world.get(MeshRenderer.self, for: entity), let geometry = meshes(renderer.mesh),
                  !geometry.vertices.isEmpty else { continue }
            let b = geometry.bounds.transformed(by: world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity))
            lo = pointwiseMin(lo, b.center - b.halfExtent)
            hi = pointwiseMax(hi, b.center + b.halfExtent)
            let label = pieceSculpt[name] ?? name
            let known = labelBoxes[label] ?? (Vec3(repeating: .infinity), Vec3(repeating: -.infinity))
            labelBoxes[label] = (pointwiseMin(known.0, b.center - b.halfExtent), pointwiseMax(known.1, b.center + b.halfExtent))
        }
        let partBoxes = labelBoxes.sorted { $0.key < $1.key }.map { ($0.key, ($0.value.0 + $0.value.1) / 2) }
        guard lo.x <= hi.x else { throw CommandError.failed("The mesh build has no parts with a mesh to show") }
        self.lo = lo
        self.hi = hi

        let unknown = highlight.filter { parts[$0] == nil }
        guard unknown.isEmpty else {
            throw CommandError.failed("No part named \(unknown.joined(separator: ", ")) to highlight (parts: \(build.parts.map(\.name).joined(separator: ", ")))")
        }
        // A sculpt child outlines the mesh of its look (its sculpt's when the sculpt has one look).
        let outlined = highlight.flatMap { name -> [Entity] in
            let looks = pieces.owners.filter { $0.value.contains(name) }.keys.sorted().compactMap { parts[$0] }
            if !looks.isEmpty { return looks }
            if let sculpt = sculpting.sculptOf[name], let entity = parts[sculpt] { return [entity] }
            return parts[name].map { [$0] } ?? []
        }
        // The ground is part of every picture, so a model off y = 0 shows it.
        let frameLo = Vec3(lo.x, min(lo.y, 0), lo.z), frameHi = Vec3(hi.x, max(hi.y, 0), hi.z)
        let extent = frameHi - frameLo
        gridSpacing = Self.gridSpacing(for: max(extent.x, extent.y, extent.z))
        let size = min(max(tileSize, Self.tileSizes.lowerBound), Self.tileSizes.upperBound)
        for kind in views {
            let draw = DebugDraw()
            let view = kind.orthographic.map { orthographicView($0.toCamera, up: $0.up, lo: frameLo, hi: frameHi, draw: draw) }
                ?? perspectiveView(lo: frameLo, hi: frameHi, draw: draw)
            if labels {
                for (name, center) in partBoxes {
                    draw.text(name, at: center, color: Vec4(1, 0.95, 0.6, 1), size: max(10, Float(size) / 34), shadow: Vec4(0, 0, 0, 0.9))
                }
            }
            self.views.append(WorldCaptureView(view: view, width: size, height: size, draw: draw, outline: outlined,
                                               title: "\(kind.title) · grid \(MeshBuildSpatial.meters(gridSpacing)) m"))
        }
    }

    /// Plays `animation` (autoplay or not) from its start to `time` (default: a quarter of its
    /// length, where swings and bobs are near their furthest).
    private mutating func pose(_ build: MeshBuild, animation name: String, time: Float?) throws {
        guard var animation = build.animations.first(where: { $0.name == name }) else {
            throw CommandError.failed("No animation named \(name) (animations: \(build.animations.map(\.name).joined(separator: ", ")))")
        }
        animation.autoplay = true
        let only = MeshBuild(parts: build.parts, animations: [animation])
        let length = animation.allTracks.flatMap(\.keys).map(\.time).max() ?? 0
        let time = max(time ?? length / 4, 0)
        for (name, entity) in parts {
            let tracks = only.animatorTracks(for: name)
            if !tracks.isEmpty { world.add(FieldAnimator(tracks: tracks), to: entity) }
        }
        var t: Float = 0
        let step: Float = 1.0 / 60
        while t < time - 1e-6 {
            let dt = min(step, time - t)
            world.update(dt: Double(dt))
            t += dt
        }
        world.propagateTransforms()
    }

    /// The grid's spacing for a model `size` meters across: a round number giving a few cells.
    static func gridSpacing(for size: Float) -> Float {
        let steps: [Float] = [0.01, 0.02, 0.05, 0.1, 0.2, 0.25, 0.5, 1, 2, 5, 10, 20, 50, 100]
        return steps.first { size / $0 <= 10 } ?? 100
    }

    private func orthographicView(_ toCamera: Vec3, up: Vec3, lo: Vec3, hi: Vec3, draw: DebugDraw) -> SceneView {
        let center = (lo + hi) / 2, half = (hi - lo) / 2
        let right = normalize(cross(-toCamera, up))
        // Half the picture: the box's extent along the image's axes, square, with a margin.
        let across = abs(dot(half, Vec3(abs(right.x), abs(right.y), abs(right.z))))
        let tall = abs(dot(half, Vec3(abs(up.x), abs(up.y), abs(up.z))))
        let r = max(max(across, tall) * Self.margin, 0.05)
        let depth = length(half) + 1
        let eye = center + toCamera * depth
        let view = SceneView(view: Mat4.lookAt(eye: eye, target: center, up: up),
                             projection: Mat4.orthographic(left: -r, right: r, bottom: -r, top: r, near: 0.01, far: depth * 2 + 1),
                             clearColor: Self.background)
        // A grid on the plane behind the model (the ground, seen from above), cut to the picture.
        let behind = -toCamera
        let origin = toCamera.y > 0.5 ? Vec3(center.x, 0, center.z) : center + behind * (abs(dot(half, behind)) + 0.001)
        grid(draw, origin: origin, u: right, v: up, halfSize: r)
        if toCamera.y < 0.5 {
            // The ground line.
            let a = Vec3(center.x, 0, center.z) - right * r, b = Vec3(center.x, 0, center.z) + right * r
            draw.line(a, b, color: Vec4(0.85, 0.85, 0.9, 1), style: DebugDraw.Style(width: 2))
        }
        return view
    }

    private func perspectiveView(lo: Vec3, hi: Vec3, draw: DebugDraw) -> SceneView {
        let center = (lo + hi) / 2
        let radius = max(length(hi - lo) / 2, 0.05)
        let direction = normalize(Vec3(1, 0.75, -1.25))  // front (-Z) right (+X), above
        let fov = Self.perspectiveFOV * .pi / 180
        // Close enough that the box's corners just fit (with the margin).
        let right = normalize(cross(-direction, Vec3(0, 1, 0))), up = cross(right, -direction)
        let slope = tanf(fov / 2) / Self.margin
        var distance: Float = radius * 0.5
        for i in 0..<8 {
            let corner = Vec3(i & 1 == 0 ? lo.x : hi.x, i & 2 == 0 ? lo.y : hi.y, i & 4 == 0 ? lo.z : hi.z) - center
            let toward = dot(corner, direction)
            distance = max(distance, abs(dot(corner, right)) / slope + toward, abs(dot(corner, up)) / slope + toward)
        }
        let view = SceneView(view: Mat4.lookAt(eye: center + direction * distance, target: center),
                             projection: Mat4.perspective(fovY: fov, aspect: 1, near: max(distance - radius * 3, 0.01),
                                                          far: distance + radius * 3 + 1),
                             clearColor: Self.background)
        grid(draw, origin: Vec3(center.x, 0, center.z), u: Vec3(1, 0, 0), v: Vec3(0, 0, 1), halfSize: radius * 1.6)
        return view
    }

    /// Grid lines every `gridSpacing` on the plane through `origin` spanned by `u` and `v`, aligned
    /// to world multiples of the spacing; the world X and Z axes (x = 0, z = 0) in red and blue.
    private func grid(_ draw: DebugDraw, origin: Vec3, u: Vec3, v: Vec3, halfSize: Float) {
        let s = gridSpacing
        let minor = Vec4(0.42, 0.44, 0.5, 0.55), major = Vec4(0.6, 0.62, 0.7, 0.8)
        let style = DebugDraw.Style(width: 1)
        for (axis, other) in [(u, v), (v, u)] {
            let o = dot(origin, axis)
            let first = ((o - halfSize) / s).rounded(.down), last = ((o + halfSize) / s).rounded(.up)
            guard last - first < 400 else { continue }
            var k = first
            while k <= last {
                let at = k * s
                let base = origin + axis * (at - o)
                let a = base - other * halfSize, b = base + other * halfSize
                var color = Int(k) % 5 == 0 ? major : minor
                // A line where x = 0 (the Z axis) or z = 0 (the X axis), on a ground grid.
                if abs(at) < s * 1e-3 && abs(other.y) < 0.5 {
                    if abs(axis.x) > 0.5 { color = Vec4(0.25, 0.4, 1, 0.95) }
                    if abs(axis.z) > 0.5 { color = Vec4(1, 0.25, 0.2, 0.95) }
                }
                draw.line(a, b, color: color, style: style)
                k += 1
            }
        }
    }

    /// The tiles side by side: one row of up to two, else rows of two (three for five or six).
    static func compose(_ tiles: [Image], gap: Int = 2) -> Image {
        guard let first = tiles.first else { return Image(width: 1, height: 1, pixels: [0, 0, 0, 255]) }
        let columns = tiles.count <= 2 ? tiles.count : tiles.count <= 4 ? 2 : 3
        let rows = (tiles.count + columns - 1) / columns
        let w = first.width, h = first.height
        let width = columns * w + (columns - 1) * gap, height = rows * h + (rows - 1) * gap
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            pixels[i] = 20; pixels[i + 1] = 21; pixels[i + 2] = 24; pixels[i + 3] = 255
        }
        for (index, tile) in tiles.enumerated() where tile.width == w && tile.height == h {
            let x0 = (index % columns) * (w + gap), y0 = (index / columns) * (h + gap)
            for row in 0..<h {
                let source = row * w * 4, destination = ((y0 + row) * width + x0) * 4
                pixels.replaceSubrange(destination..<(destination + w * 4), with: tile.pixels[source..<(source + w * 4)])
            }
        }
        return Image(width: width, height: height, pixels: pixels)
    }
}

public enum MeshBuildPreviewCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable, MeshBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Which views, in order (default front, right, top, threeQuarter).
        public var views: [MeshBuildPreviewView]?
        /// Each view's size in pixels (square; default 384).
        public var size: Int?
        /// Write every part's name at its center (default false).
        public var labels: Bool?
        /// Parts to outline.
        public var highlight: [String]?
        /// Pose this animation (by name; autoplay or not) at `time` seconds (default: a quarter
        /// of its length). Without it the model is in its rest pose.
        public var animation: String?
        public var time: Float?
        /// What lights the model: studio (default), outdoor or flat.
        public var environment: MeshBuildPreviewEnvironment?

        public init(asset: AssetReference? = nil, path: String? = nil, views: [MeshBuildPreviewView]? = nil, size: Int? = nil,
                    labels: Bool? = nil, highlight: [String]? = nil, animation: String? = nil, time: Float? = nil,
                    environment: MeshBuildPreviewEnvironment? = nil) {
            self.environment = environment
            self.asset = asset
            self.path = path
            self.views = views
            self.size = size
            self.labels = labels
            self.highlight = highlight
            self.animation = animation
            self.time = time
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The PNG (sent as image content over MCP).
        public var image: CommandImage
        /// Size, part count and grid spacing in words.
        public var summary: String
        public var views: [MeshBuildPreviewView]
        public var bounds: MeshBuildBounds?
        public var warnings: [String]
    }

    public static let id: CommandID = "meshBuild.preview"
    public static let title = "Preview Mesh Build"
    public static let doc = "Returns one PNG of a .meshbuild model from fixed angles, tiled: by default front (camera at -Z, the model's front; +X is on the image's left), right (from +X), top (front up) and a 3/4 perspective; `views` picks and orders them (also back, left). Front / right / top are orthographic, each auto-framed with a ground grid (spacing in the caption; red line z=0, blue x=0) and a white ground line at y=0. `size`: tile pixels (default 384). `labels`: part names at their centers. `highlight`: part names to outline (a sculpt child outlines the surface it owns: its look's mesh). `animation` + `time`: pose that animation at `time` seconds. `environment`: what lights the model, \"studio\" (default: a neutral photo studio with softboxes that metals reflect), \"outdoor\" (the procedural sky) or \"flat\" (plain ambient light, nothing to reflect). Also returns a summary (size in m, part count), the bounds and the same warnings as meshBuild.get. Read-only: the model is shown in a world of its own, not the scene. Finishes after a few frames. Needs the editor window."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) && session.host?.canRender == true }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.project == nil ? noProjectReason : "previews need the editor window and GPU (the editor is running headless)"
    }

    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<Result> {
        let (id, build) = try session.resolveMeshBuild(arguments, title)
        guard let host = session.host, let assets = session.assets else {
            throw CommandError.failed(unavailableReason(in: session) ?? "No window")
        }
        if let error = assets.record(id)?.importError { throw CommandError.failed("\(title): the model didn't import: \(error)") }
        guard let prefab = assets.prefab(AssetReference(id)) else { throw CommandError.failed("\(title): the model didn't import") }
        let views = arguments.views.flatMap { $0.isEmpty ? nil : $0 } ?? MeshBuildPreviewScene.defaultViews
        let scene = try MeshBuildPreviewScene(
            build: build, prefab: prefab, views: views, tileSize: arguments.size ?? MeshBuildPreviewScene.defaultTileSize,
            labels: arguments.labels ?? false, highlight: arguments.highlight ?? [], animation: arguments.animation,
            time: arguments.time, environment: arguments.environment ?? .studio) { handle in
                handle.assetReference.flatMap { assets.mesh($0) } ?? MeshGeometry.builtin(handle)
            }
        let check = MeshBuildResult(id, build, in: session)
        let size = scene.hi - scene.lo
        // Parts inside a sculpt are drawn as part of its mesh.
        let sculpting = build.gatheringSculpts()
        let inSculpts = sculpting.sculpted.count
        let meshParts = sculpting.drawnParts.filter { $0.geometry() != nil }.count
        var summary = "\(check.path): \(MeshBuildSpatial.meters(size.x)) x \(MeshBuildSpatial.meters(size.y)) x "
            + "\(MeshBuildSpatial.meters(size.z)) m (x, y, z), \(build.parts.count) part\(build.parts.count == 1 ? "" : "s")"
        let unmeshed = build.parts.count - inSculpts - meshParts
        let notes = (inSculpts > 0 ? ["\(inSculpts) in sculpts"] : []) + (unmeshed > 0 ? ["\(unmeshed) without a mesh"] : [])
        if !notes.isEmpty { summary += " (\(notes.joined(separator: ", ")))" }
        summary += ", lowest point at y=\(MeshBuildSpatial.meters(scene.lo.y)); grid \(MeshBuildSpatial.meters(scene.gridSpacing)) m"
        if let animation = arguments.animation { summary += "; posed: \(animation)" }
        summary += check.warnings.isEmpty ? "; no warnings" : "; \(check.warnings.count) warning\(check.warnings.count == 1 ? "" : "s")"
        guard let future = host.capture(world: scene.world, views: scene.views) else {
            throw CommandError.failed("This editor can't render previews")
        }
        return future.map { tiles in
            guard tiles.count == views.count else { throw CommandError.failed("\(title): a view didn't render") }
            return Result(image: CommandImage(png: MeshBuildPreviewScene.compose(tiles)), summary: summary, views: views,
                          bounds: check.bounds, warnings: check.warnings)
        }
    }
}
