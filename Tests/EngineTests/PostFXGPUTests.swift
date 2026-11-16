import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineAssets
@testable import EngineRendering

// The post pass on the GPU, on every backend (Metal, and Vulkan through MoltenVK on macOS):
// the same scene and settings give the same bytes everywhere.

/// A small lit set: a red cube near the camera (2.5 m), a row of alternating light and dark
/// blocks 14 m away and a dark floor, seen by a camera.
@MainActor func postFXGPUTestWorld() -> (World, Entity) {
    let world = World()
    world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-45, 40, 0))), DirectionalLight(intensity: 1.2, castsShadows: false))
    world.spawn(SceneEnvironment(ambientIntensity: 0.3, fogDensity: 0))
    let camera = world.spawn(Transform(position: Vec3(0, 1, 6)), Name("PostFXGPUTestsCamera"),
                             Camera(fovY: 50 * .pi / 180, near: 0.1, far: 100, clearColor: Vec4(0.2, 0.3, 0.5, 1)))
    var floor = MeshRenderer(mesh: .cube)
    floor.tint = Vec3(0.25, 0.25, 0.25)
    world.spawn(Transform(position: Vec3(0, -0.05, 0), scale: Vec3(40, 0.1, 40)), floor)
    var near = MeshRenderer(mesh: .cube)
    near.tint = Vec3(0.9, 0.15, 0.1)
    world.spawn(Transform(position: Vec3(-0.6, 0.6, 3.5), scale: Vec3(0.6, 0.6, 0.6)), Name("PostFXGPUTestsNear"), near)
    for i in 0..<15 {
        var block = MeshRenderer(mesh: i % 3 == 2 ? .sphere : .cube)
        block.tint = i % 2 == 0 ? Vec3(0.95, 0.9, 0.8) : Vec3(0.05, 0.1, 0.2)
        world.spawn(Transform(position: Vec3(Float(i) * 0.8 - 5.6, 1.2, -8), scale: Vec3(0.8, 2.4, 0.8)), block)
    }
    world.propagateTransforms()
    return (world, camera)
}

@MainActor @Suite(.serialized) struct PostFXGPUTests {
    static let size = (width: 96, height: 64)

    /// Renders the test world, runs `settings` over it with the preview path, returns the bytes.
    /// `depth`: render the view's depth and pass it (depth of field).
    /// `assets`: where LUTs are looked up.
    static func render(_ settings: [PostProcessSettings], split: Float = 0, depth: Bool = false,
                       assets: AssetDatabase? = nil) throws -> [String: [[UInt8]]] {
        var out: [String: [[UInt8]]] = [:]
        try TestDevices.forEachBackend { device, frames in
            let (world, cameraEntity) = postFXGPUTestWorld()
            let renderer = try SceneRenderer(device: device, quality: .high)
            let processor = try PostProcessor(device: device)
            processor.splitPreview = split
            processor.assets = assets
            let target = try RenderTarget(device: device, width: size.width, height: size.height, multisampled: false)
            let output = try device.makeRenderTarget(.color(width: size.width, height: size.height, format: .rgba8Srgb))
            let view = try #require(SceneView(camera: cameraEntity, in: world, aspect: target.aspectRatio))
            var images: [[UInt8]] = []
            for profile in settings {
                try frames.run { frame in
                    renderer.beginViews(world: world, frame: frame, shadowFocus: view)
                    renderer.renderView(view, into: target, frame: frame)
                    let sceneDepth = depth ? renderer.renderDepth(for: view, size: size, frame: frame) : nil
                    processor.renderPreview(scene: target.texture, settings: profile, into: output, dt: 1.0 / 60, depth: sceneDepth)
                    device.readBack(output) { images.append($0.pixels) }
                }
            }
            out[device.backend.rawValue] = images
        }
        return out
    }

    /// With POSTFX_GPU_DUMP=<folder>, writes the images there as PNGs (to look at them).
    static func dump(_ images: [[UInt8]], _ name: String) {
        guard let folder = ProcessInfo.processInfo.environment["POSTFX_GPU_DUMP"] else { return }
        for (i, pixels) in images.enumerated() {
            try? Image(width: size.width, height: size.height, pixels: pixels)
                .writePNG(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name)-\(i).png"))
        }
    }

    static func hash(_ bytes: [UInt8]) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return String(h, radix: 16)
    }

    /// Existing looks (no depth of field, no LUT): hashes printed so a change to the shaders can
    /// be checked against the output from before it.
    @Test func existingLooksMatchAcrossBackends() throws {
        var looks = PostFXPreset.allCases.map(\.settings)
        looks.append(.passthrough)
        let results = try Self.render(looks)
        let split = try Self.render([PostFXPreset.cinematic.settings], split: 0.4)
        for (backend, images) in results.sorted(by: { $0.key < $1.key }) {
            print("PostFXGPUTests \(backend): " + (images + (split[backend] ?? [])).map(Self.hash).joined(separator: " "))
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] {
            #expect(metal == vulkan)
            #expect(split["metal"] == split["vulkan"])
        }
    }

    /// Sum of squared differences between horizontal neighbours (rgb): how sharp the edges are
    /// (a blur spreads an edge's step over several pixels, which lowers the sum of squares).
    static func edgeEnergy(_ bytes: [UInt8], in rows: Range<Int>? = nil, columns: Range<Int>? = nil) -> Int {
        let rows = rows ?? 0..<size.height, columns = columns ?? 0..<size.width
        var sum = 0
        for y in rows {
            for x in columns.lowerBound..<(columns.upperBound - 1) {
                for c in 0..<3 {
                    let d = Int(bytes[(y * size.width + x) * 4 + c]) - Int(bytes[(y * size.width + x + 1) * 4 + c])
                    sum += d * d
                }
            }
        }
        return sum
    }

    static func meanDifference(_ a: [UInt8], _ b: [UInt8], rows: Range<Int>, columns: Range<Int>) -> Double {
        var sum = 0, count = 0
        for y in rows {
            for x in columns {
                for c in 0..<3 { sum += abs(Int(a[(y * size.width + x) * 4 + c]) - Int(b[(y * size.width + x) * 4 + c])); count += 1 }
            }
        }
        return Double(sum) / Double(max(count, 1))
    }

    /// Depth of field, focused on the far wall: the near cube (left of center, lower half) blurs,
    /// the wall stays nearly as it was; focused on the near cube, the wall blurs instead. Both
    /// backends give the same bytes, and switching it on without depth or blur changes nothing.
    @Test func depthOfFieldBlursByDepthOnEveryBackend() throws {
        var plain = PostProcessSettings(tonemapper: .neutral)
        plain.depthOfField = false
        var far = plain
        far.depthOfField = true
        far.focusDistance = 14
        far.focusRange = 2
        far.aperture = 1.4
        far.focalLength = 100
        far.maxBlur = 8
        var near = far
        near.focusDistance = 2.6
        near.focusRange = 0.5
        var noBlur = far
        noBlur.maxBlur = 0
        let results = try Self.render([plain, far, near, noBlur], depth: true)
        let withoutDepth = try Self.render([far])
        for (backend, images) in results.sorted(by: { $0.key < $1.key }) {
            print("PostFXGPUTests DOF \(backend): " + images.map(Self.hash).joined(separator: " "))
            Self.dump(images, "dof-\(backend)")
            #expect(images[3] == images[0], "\(backend): no blur is the plain image")
            #expect(withoutDepth[backend]?.first == images[0], "\(backend): no depth, no depth of field")
            // The far blocks: rows around their middle, the whole width; the near cube's edges.
            let wallRows = 26..<34, nearRows = 34..<54, nearColumns = 14..<46
            let wallSharp = Self.edgeEnergy(images[0], in: wallRows)
            #expect(Self.edgeEnergy(images[1], in: wallRows) > wallSharp * 3 / 4, "\(backend): wall in focus stays sharp")
            #expect(Self.edgeEnergy(images[2], in: wallRows) < wallSharp * 2 / 3, "\(backend): wall out of focus blurs")
            let nearSharp = Self.edgeEnergy(images[0], in: nearRows, columns: nearColumns)
            #expect(Self.edgeEnergy(images[1], in: nearRows, columns: nearColumns) < nearSharp * 2 / 3, "\(backend): near cube blurs")
            #expect(Self.meanDifference(images[2], images[0], rows: nearRows, columns: nearColumns) < 6,
                    "\(backend): near cube in focus")
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] { #expect(metal == vulkan) }
    }

    /// LUT grading on both backends: an identity LUT leaves the image (within a code of
    /// rounding), an inverting one turns every byte into 255 minus it (the LUT works on the
    /// sRGB-encoded values the target stores), half intensity lands in between, and the same
    /// bytes come out of Metal and Vulkan.
    @Test func lutGradingOnEveryBackend() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXGPUTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "PostFXGPU")
        defer { try? FileManager.default.removeItem(at: url) }
        let assets = AssetDatabase(project: project)
        for (name, transform) in [("identity", { (c: Vec3) in c }), ("invert", { (c: Vec3) in Vec3(1, 1, 1) - c })] {
            let file = project.url(forAssetPath: "\(name).cube")
            try Data(postFXLUTTestsCube(size: 17, transform).utf8).write(to: file)
        }
        assets.scan()
        let plain = PostProcessSettings(tonemapper: .neutral)
        var identity = plain, invert = plain, half = plain
        identity.lut = "identity.cube"
        invert.lut = "Assets/invert.cube"
        half.lut = "asset:" + (assets.id(forPath: "invert.cube")?.description ?? "")
        half.lutIntensity = 0.5
        let results = try Self.render([plain, identity, invert, half], assets: assets)
        for (backend, images) in results.sorted(by: { $0.key < $1.key }) {
            print("PostFXGPUTests LUT \(backend): " + images.map(Self.hash).joined(separator: " "))
            Self.dump(images, "lut-\(backend)")
            var identityError = 0, invertError = 0
            for i in images[0].indices where i % 4 != 3 {
                identityError = max(identityError, abs(Int(images[1][i]) - Int(images[0][i])))
                invertError = max(invertError, abs(Int(images[2][i]) - (255 - Int(images[0][i]))))
            }
            #expect(identityError <= 1, "\(backend): identity LUT off by \(identityError)")
            #expect(invertError <= 2, "\(backend): inverting LUT off by \(invertError)")
            #expect(images[3] != images[0] && images[3] != images[2])
        }
        if let metal = results["metal"], let vulkan = results["vulkan"] { #expect(metal == vulkan) }
    }

    /// The before/after split the Scene view and the Post-FX tab show, with depth of field and a
    /// LUT in the look: left of the line is the plain scene (no blur, no LUT), the same bytes as
    /// the split of a plain look; right of it the look. Same bytes on both backends.
    @Test func splitPreviewShowsThePlainSceneBeforeEveryEffect() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PostFXGPUTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "PostFXGPUSplit")
        defer { try? FileManager.default.removeItem(at: url) }
        let assets = AssetDatabase(project: project)
        try Data(postFXLUTTestsCube(size: 9) { Vec3($0.y, $0.z, $0.x) }.utf8).write(to: project.url(forAssetPath: "swap.cube"))
        assets.scan()
        var look = PostFXPreset.warm.settings
        look.filmGrain = 0
        look.depthOfField = true
        look.focusDistance = 2.6
        look.aperture = 1.4
        look.focalLength = 100
        look.maxBlur = 8
        look.lut = "swap.cube"
        let plain = try Self.render([.passthrough], split: 0.5, depth: true, assets: assets)
        let looks = try Self.render([look], split: 0.5, depth: true, assets: assets)
        let line = Self.size.width / 2
        for (backend, images) in looks.sorted(by: { $0.key < $1.key }) {
            let before = try #require(plain[backend]?.first), after = images[0]
            print("PostFXGPUTests split \(backend): " + Self.hash(after))
            Self.dump([before, after], "split-\(backend)")
            #expect(Self.meanDifference(after, before, rows: 0..<Self.size.height, columns: 0..<(line - 1)) == 0, "\(backend): left is plain")
            #expect(Self.meanDifference(after, before, rows: 0..<Self.size.height, columns: (line + 1)..<Self.size.width) > 5, "\(backend): right is the look")
            for y in 0..<Self.size.height { #expect(after[(y * Self.size.width + line) * 4] == 255) }  // the white line
        }
        if let metal = looks["metal"], let vulkan = looks["vulkan"] { #expect(metal == vulkan) }
    }

    /// The game path: with depth of field on (here from the scene's `PostProcess`, auto-focused
    /// on the near cube), `SceneRenderer.prepare` / `renderShadows` hand the post-processor the
    /// camera's depth at the render size; with it off they hand it none.
    @Test func sceneRendererHandsTheCameraDepthToThePostProcessor() throws {
        try TestDevices.forEachBackend { device, frames in
            let (world, _) = postFXGPUTestWorld()
            var look = PostProcessSettings()
            look.depthOfField = true
            look.focusTarget = "PostFXGPUTestsNear"
            let holder = world.spawn(look)
            let host = try PostFXGPUTestsHost(device: device)
            let renderer = try SceneRenderer(device: device, quality: .high)
            try frames.run { frame in renderer.renderOffscreen(world: world, engine: host, frame: frame) }
            #expect(abs((host.postProcess?.focusDistance ?? 0) - 2.5) < 0.01, "auto-focus: the near cube is 2.5 m ahead")
            let depth = try #require(host.postProcessor?.sceneDepth)
            #expect(depth.texture.width == host.renderSize.width && depth.texture.height == host.renderSize.height)
            look.depthOfField = false
            world.add(look, to: holder)
            try frames.run { frame in renderer.renderOffscreen(world: world, engine: host, frame: frame) }
            #expect(host.postProcessor?.sceneDepth == nil)
        }
    }
}

/// A stand-in for `Engine` as `SceneRenderer` sees it.
@MainActor final class PostFXGPUTestsHost: SceneRenderHost {
    let device: RenderDevice
    let quality = RenderQuality.high
    let debugDraw = DebugDraw()
    let renderSize = (width: 96, height: 64)
    var aspectRatio: Float { 96.0 / 64.0 }
    var clearColor = Vec4(0, 0, 0, 1)
    var clearDepth: Float = 1
    var postProcess: PostProcessSettings?
    let postProcessor: PostProcessor?

    init(device: RenderDevice) throws {
        self.device = device
        postProcessor = try PostProcessor(device: device)
    }

    func jittered(_ projection: Mat4) -> Mat4 { projection }
}
