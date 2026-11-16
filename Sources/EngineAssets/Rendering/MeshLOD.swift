/// Draws coarser meshes in place of its entity's `MeshRenderer` mesh as the camera moves away.
/// Level 0 is the renderer's own mesh; `meshes[i]` is level i + 1 and takes over once the camera
/// is `distances[i]` meters from the nearest point of the level-0 mesh's world bounds. The choice
/// is made when the frame is gathered (`RenderPrep.lodViewpoint`, the camera), so the component
/// stays as written (nothing to save or undo) and shadows use the same level as the camera.
///
/// `hysteresis` keeps a level from flickering when the camera hovers near a threshold: a coarser
/// level starts only past `distance x (1 + hysteresis)` and a finer one only inside
/// `distance x (1 - hysteresis)`. A level whose mesh isn't loaded yet keeps drawing the level
/// it had (the load starts at once). Terrains use it for their chunks (`Terrain.lods`), whose
/// level meshes hang skirts along chunk borders so neighbors at different levels don't crack.
///
/// `lowQualityMaterial` replaces the renderer's material when the renderer's quality is `.low`
/// (a terrain's baked albedo instead of its per-pixel layer blend).
import EngineCore
import EngineScene

public struct MeshLOD: Component, Codable, Equatable, Sendable {
    public static let componentName = "MeshLOD"
    public static var fieldHints: [String: FieldHints] {
        ["meshes": FieldHints(tooltip: "Level 1, 2, … meshes (level 0 is the MeshRenderer's mesh)"),
         "distances": FieldHints(tooltip: "Meters from the camera where each level takes over (ascending)"),
         "hysteresis": FieldHints(range: 0...0.5, step: 0.01, tooltip: "Fraction past a threshold before the level changes"),
         "lowQualityMaterial": FieldHints(tooltip: "Drawn instead of the MeshRenderer's material on low quality")]
    }

    /// Meshes of levels 1, 2, … (level 0 is the `MeshRenderer`'s own).
    public var meshes: [MeshHandle]
    /// Meters where each of `meshes` takes over, ascending (extra entries on either side are ignored).
    public var distances: [Float]
    /// 0...0.5: the fraction of a threshold the camera must move past it before the level changes.
    public var hysteresis: Float
    /// Drawn instead of the `MeshRenderer`'s material when the renderer's quality is low (nil: never).
    public var lowQualityMaterial: MaterialHandle?

    public init(meshes: [MeshHandle] = [], distances: [Float] = [], hysteresis: Float = 0.1, lowQualityMaterial: MaterialHandle? = nil) {
        self.meshes = meshes
        self.distances = distances
        self.hysteresis = hysteresis
        self.lowQualityMaterial = lowQualityMaterial
    }

    /// Every field is optional.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(meshes: try c.decodeIfPresent([MeshHandle].self, forKey: .meshes) ?? [],
                  distances: try c.decodeIfPresent([Float].self, forKey: .distances) ?? [],
                  hysteresis: try c.decodeIfPresent(Float.self, forKey: .hysteresis) ?? 0.1,
                  lowQualityMaterial: try c.decodeIfPresent(MaterialHandle.self, forKey: .lowQualityMaterial))
    }

    /// The levels there are besides level 0.
    public var levelCount: Int { min(meshes.count, distances.count) }

    /// The level to draw for a camera `distance` meters away, when level `current` is drawn now
    /// (negative: none yet, so no hysteresis applies).
    public func level(distance: Float, current: Int = -1) -> Int {
        let count = levelCount
        guard count > 0, distance.isFinite else { return 0 }
        if current < 0 {
            var level = 0
            while level < count && distance >= distances[level] { level += 1 }
            return level
        }
        let h = min(max(hysteresis, 0), 0.5)
        var level = min(current, count)
        while level < count && distance > distances[level] * (1 + h) { level += 1 }
        while level > 0 && distance < distances[level - 1] * (1 - h) { level -= 1 }
        return level
    }

    /// The mesh of `level` (0: `base`, the renderer's).
    public func mesh(level: Int, base: MeshHandle) -> MeshHandle {
        level > 0 && level <= levelCount ? meshes[level - 1] : base
    }

    /// Meters from `point` to the nearest point of `bounds` (0 inside).
    public static func distance(from point: Vec3, to bounds: Bounds) -> Float {
        let d = pointwiseMax(Vec3(abs(point.x - bounds.center.x), abs(point.y - bounds.center.y), abs(point.z - bounds.center.z))
                             - bounds.halfExtent, .zero)
        return length(d)
    }
}
