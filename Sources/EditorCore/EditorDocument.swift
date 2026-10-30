import Engine
import Foundation

/// One open scene: the `World` being edited (with `assignsEntityIDs` on), its `UndoStack`, the
/// file it came from and whether it has unsaved changes.
///
/// The world and the undo stack are created once and reused for every document (New / Open
/// clear the world and load into it), so panels holding them (`PropertyGrid(world:)`) and the
/// world's systems stay valid. Files are plain scene files (`World.save` / `load`, JSON).
@MainActor
public final class EditorDocument {
    public let world: World
    public let undo: UndoStack
    /// Where the document was opened from or last saved to; nil for a new, never-saved scene.
    public private(set) var url: URL?
    /// Called after New and Open replaced the world's contents (panels resync, the selection is pruned).
    public var onReload: (() -> Void)?

    public init(world: World = World()) {
        self.world = world
        world.assignsEntityIDs = true
        undo = UndoStack(world: world)
    }

    /// The file name, or "Untitled".
    public var displayName: String { url?.lastPathComponent ?? "Untitled" }

    /// Whether there are changes since the last save (or since New / Open).
    public var isDirty: Bool { undo.isDirty }

    /// "Untitled", "scene.json *" (unsaved changes).
    public var title: String { displayName + (isDirty ? " *" : "") }

    // MARK: New / Open / Save

    /// Replaces the contents with the starter scene. The new document is clean (nothing to
    /// save until it is edited) and has no file yet.
    public func newDocument() {
        clearWorld()
        StarterScene.build(in: world)
        url = nil
        finishReload()
    }

    /// Replaces the contents with the scene file at `url`. Throws, leaving the current
    /// document untouched, if the file can't be read or isn't a valid scene.
    public func open(_ url: URL) throws {
        let data = try Data(contentsOf: url)
        // Validate in a scratch world first: loading is atomic, but clearing isn't undoable.
        let scratch = World()
        _ = try scratch.load(data)
        clearWorld()
        _ = try world.load(data)
        self.url = url
        finishReload()
    }

    /// Saves to the document's file. Throws `EditorError.noFile` for a never-saved document.
    public func save() throws {
        guard let url else { throw EditorError.noFile }
        try save(to: url)
    }

    /// Saves to `url` (creating its directory if needed); it becomes the document's file.
    public func save(to url: URL) throws {
        let data = try world.save()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        self.url = url
        undo.markSaved()
    }

    private func clearWorld() {
        for root in world.roots { world.despawn(root) }
    }

    private func finishReload() {
        world.propagateTransforms()
        undo.clear()
        onReload?()
    }
}

public enum EditorError: Error, Equatable, CustomStringConvertible {
    /// Save without a file: use Save As.
    case noFile
    /// The action isn't available while playing.
    case playing
    /// No component type is registered under this name.
    case unknownComponent(String)

    public var description: String {
        switch self {
        case .noFile: "The scene has no file yet: enter a path and use Save As"
        case .playing: "Not available in play mode: press Stop first"
        case .unknownComponent(let name): "Unknown component '\(name)'"
        }
    }
}

/// The scene New creates: a camera, a sun, an environment, a floor, a few named primitives
/// and a small hierarchy (a spinning group, which shows play mode working).
public enum StarterScene {
    /// Material keys the scene uses besides `default`; the host registers them with its renderer.
    public static let checkerMaterial = MaterialHandle("checker")
    public static let skyColor = Vec3(0.55, 0.62, 0.74)

    @MainActor
    public static func build(in world: World) {
        _ = world.spawn(Name("Main Camera"), Transform.looking(from: Vec3(7, 4.5, 9), at: Vec3(0, 1, 0)),
                        Camera(fovY: .pi / 3.4, near: 0.1, far: 200, clearColor: Vec4(skyColor, 1)))
        _ = world.spawn(Name("Sun"), Transform(position: Vec3(-4, 6, -3), rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.35))),
                        DirectionalLight(intensity: 1.3, shadowExtent: 14))
        _ = world.spawn(Name("Environment"), SceneEnvironment(fogColor: skyColor, fogDensity: 0.01))
        _ = world.spawn(Name("Floor"), Transform(position: Vec3(0, -0.5, 0), scale: Vec3(20, 1, 20)),
                        MeshRenderer(mesh: .cube, material: checkerMaterial, tint: Vec3(0.8, 0.8, 0.78), castsShadows: false))

        let props = world.spawn(Name("Props"), Transform())
        let cube = world.spawn(Name("Red Cube"), Transform(position: Vec3(-2.5, 0.5, 0.5)),
                               MeshRenderer(mesh: .cube, tint: Vec3(0.85, 0.22, 0.18)))
        let sphere = world.spawn(Name("Blue Sphere"), Transform(position: Vec3(0, 0.75, 2), scale: Vec3(repeating: 1.5)),
                                 MeshRenderer(mesh: .sphere, tint: Vec3(0.2, 0.42, 0.9)))
        let pillar = world.spawn(Name("Green Pillar"), Transform(position: Vec3(-3, 1.25, -2.5), scale: Vec3(0.8, 2.5, 0.8)),
                                 MeshRenderer(mesh: .cube, tint: Vec3(0.25, 0.7, 0.35)))
        for child in [cube, sphere, pillar] { world.setParent(child, to: props) }

        let spinner = world.spawn(Name("Spinner"), Transform(position: Vec3(2.5, 1.2, -0.5)), Spin(speed: 1.2))
        let hub = world.spawn(Name("Hub"), Transform(scale: Vec3(repeating: 0.6)),
                              MeshRenderer(mesh: .sphere, tint: Vec3(0.95, 0.75, 0.25)))
        let armA = world.spawn(Name("Arm A"), Transform(position: Vec3(1.1, 0, 0), scale: Vec3(1.4, 0.3, 0.3)),
                               MeshRenderer(mesh: .cube, tint: Vec3(0.9, 0.55, 0.2)))
        let armB = world.spawn(Name("Arm B"), Transform(position: Vec3(-1.1, 0, 0), scale: Vec3(1.4, 0.3, 0.3)),
                               MeshRenderer(mesh: .cube, tint: Vec3(0.9, 0.55, 0.2)))
        for child in [hub, armA, armB] { world.setParent(child, to: spinner) }
    }
}
