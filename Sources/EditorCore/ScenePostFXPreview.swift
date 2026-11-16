import Engine
import Foundation

// The Scene view's post-processing preview (`view.scenePostFX`, the View menu's Scene Post-FX
// items): the editor view's image run through the look the game would use at the editor
// camera's position (the scene camera's profile, or the scene's PostProcess component, with the
// PostFXVolumes the editor camera is in blended over it), either whole or as a before/after
// split. Off by default: the Scene view then shows the plain scene as before.
//
// Like the Post-FX tab, it post-processes the view's 8-bit image (highlights are already
// clipped, so bloom looks weaker than in the game), and the gizmos drawn into that image are
// graded along with the scene.

/// How the Scene view shows post-processing.
public struct ScenePostFXSettings: Codable, Equatable, Sendable {
    public enum Mode: String, Codable, CaseIterable, Sendable {
        /// The plain scene (the default).
        case off
        /// The whole view through the look.
        case on
        /// The plain scene left of `split`, the look right of it, a white line between.
        case split
    }

    public var mode: Mode = .off
    /// Where the split line is, 0.05...0.95 of the width.
    public var split: Float = 0.5

    public init(mode: Mode = .off, split: Float = 0.5) {
        self.mode = mode
        self.split = split
    }
}

@MainActor
public final class ScenePostFXPreview {
    private var processor: PostProcessor?
    private var output: GPURenderTarget?
    private var failed = false
    /// The look applied to the last frame (nil: off, or the scene has no post-processing and it
    /// showed as passthrough).
    public private(set) var lastSettings: PostProcessSettings?

    public init() {}

    /// The look the game would use, seen from `view` (nil: the scene has no post-processing).
    public static func settings(world: World, view: SceneView, assets: AssetDatabase?) -> PostProcessSettings? {
        let camera = RenderPrep.findCamera(in: world)?.camera ?? Camera()
        let eye = view.view.inverse
        return PostFXResolver.resolve(world: world, camera: camera, cameraWorld: eye, assets: assets)
    }

    /// The texture the Scene view shows this frame: the preview's output (sized to `target`) while
    /// `settings` turns it on, else nil (show `target` itself). Call after the target is sized.
    public func texture(for target: RenderTarget, settings: ScenePostFXSettings) -> GPUTexture? {
        guard settings.mode != .off, !failed else {
            output = nil
            return nil
        }
        do {
            if processor == nil { processor = try PostProcessor(device: target.device) }
            if output.map({ $0.texture.width != target.width || $0.texture.height != target.height }) ?? true {
                output = try target.device.makeRenderTarget(.color(width: target.width, height: target.height, format: .rgba8Srgb))
            }
        } catch {
            print("Scene view post-fx preview unavailable: \(error)")
            failed = true
            processor = nil
            output = nil
        }
        return output?.texture
    }

    /// Runs the look over `target` (the Scene view's image of `world` from `view`) into the
    /// output `texture(for:settings:)` returned. Call in `renderOffscreen`, after the view is drawn.
    public func render(view: SceneView, target: RenderTarget, world: World, renderer: SceneRenderer, assets: AssetDatabase?,
                       settings: ScenePostFXSettings, frame: Frame, dt: Float) {
        guard settings.mode != .off, let processor, let output,
              output.texture.width == target.width, output.texture.height == target.height else {
            lastSettings = nil
            return
        }
        var look = Self.settings(world: world, view: view, assets: assets)
        lastSettings = look
        if look?.depthOfField == true { look = PostFXResolver.autoFocused(look, world: world, cameraWorld: view.view.inverse) }
        let depth = look?.depthOfField == true ? renderer.renderDepth(for: view, size: (target.width, target.height), frame: frame) : nil
        processor.assets = assets
        processor.splitPreview = settings.mode == .split ? min(max(settings.split, 0.05), 0.95) : 0
        processor.renderPreview(scene: target.texture, settings: look ?? .passthrough, into: output, dt: dt, depth: depth)
    }

    /// What the Scene view's caption adds.
    public func caption(_ settings: ScenePostFXSettings) -> String? {
        switch settings.mode {
        case .off: nil
        case .on: lastSettings == nil ? "Post-FX: none in this scene" : "Post-FX"
        case .split: lastSettings == nil ? "Post-FX split: none in this scene" : "Left: plain · right: Post-FX"
        }
    }
}

public enum ViewScenePostFXCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// off, on or split.
        public var mode: ScenePostFXSettings.Mode?
        /// The split line, 0.05...0.95 of the width.
        public var split: Float?
        public init(mode: ScenePostFXSettings.Mode? = nil, split: Float? = nil) {
            self.mode = mode
            self.split = split
        }
    }

    public static let id: CommandID = "view.scenePostFX"
    public static let title = "Scene View Post-FX"
    public static let doc = """
        Shows post-processing in the Scene view (the View menu's Scene Post-FX items): `mode` off (the plain scene, \
        the default), on (the look the game would use at the editor camera: the scene camera's post-fx profile or the \
        scene's PostProcess component, with the PostFXVolumes the editor camera is in blended over it) or split (plain \
        left of `split`, 0.05-0.95 of the width, the look right of it). Without arguments it only returns the setting. \
        view.screenshot {source: "window"} shows the result (the "viewport" source renders without it).
        """
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScenePostFXSettings {
        if let mode = arguments.mode { session.scenePostFX.mode = mode }
        if let split = arguments.split {
            guard split.isFinite else { throw CommandError.failed("\(title): split must be a number") }
            session.scenePostFX.split = min(max(split, 0.05), 0.95)
        }
        return session.scenePostFX
    }
}
