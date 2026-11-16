import Foundation
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// A path build: the contents of a `.path` file (JSON, every key optional). A spline through
// control points that generates geometry along it: roads, rails, rivers, fences, cables and
// walls. `PathBuildImporter` turns it into one mesh per cross-section profile (swept along the
// curve, with an optional triangle-mesh collider) plus repeated pieces (posts, sleepers, a
// `.meshbuild`) placed every few meters, all in one prefab.
//
// The curve is the Catmull-Rom spline `CameraPath` uses (`CatmullRom`), sampled every `spacing`
// meters. Each sample has a frame: forward along the curve, right level with the ground, up;
// banking rolls it about forward. Cables sag between control points like a `LineRenderer`
// (`CableSag`). With `terrain` set, every sample (and every piece) sits on that `.terrain`'s
// surface plus `terrain.height`, so a road hugs the hills between its control points.
//
// ```json
// {
//   "kind": "road",
//   "points": [{"position": [0, 0, 0]}, {"position": [20, 0, 10], "bank": 8}, [40, 0, 0]],
//   "profiles": [{"name": "Road", "shape": "box", "width": 6, "height": 0.3, "offset": [0, -0.25],
//                 "color": [0.2, 0.2, 0.22], "collider": true}],
//   "pieces": [{"name": "Posts", "shape": "cylinder", "size": [0.12, 1, 0.12], "spacing": 6,
//               "offset": [3.4, 0.5, 0], "mirror": true}],
//   "terrain": {"asset": "Maps/Hills.terrain", "height": 0.05}
// }
// ```

/// What a path is for: picks the starting profiles and pieces (`PathBuild.preset`).
public enum PathKind: String, Codable, CaseIterable, Sendable {
    case road, rail, river, fence, cable, wall, custom
}

/// A control point.
public struct PathPoint: Codable, Equatable, Sendable {
    /// Meters, in the path's space.
    public var position: Vec3
    /// Roll in degrees about the direction of travel; positive lowers the right side (into a right turn).
    public var bank: Float
    /// Multiplies the profiles' widths here (rivers that widen, roads that narrow).
    public var width: Float

    public static var fieldHints: [String: FieldHints] {
        ["position": FieldHints(step: 0.1, tooltip: "Meters (y is ignored when following a terrain)"),
         "bank": FieldHints(range: -89...89, step: 1, tooltip: "Degrees; positive lowers the right side"),
         "width": FieldHints(range: 0.01...100, step: 0.05, tooltip: "Multiplies the profiles' widths here")]
    }

    public init(_ position: Vec3 = .zero, bank: Float = 0, width: Float = 1) {
        self.position = position
        self.bank = bank
        self.width = width
    }

    private enum CodingKeys: String, CodingKey { case position, bank, width }

    /// An object (`{"position": [x, y, z], "bank": 5}`) or just `[x, y, z]`.
    public init(from decoder: any Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let position = try? single.decode(Vec3.self) {
            self.init(position)
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try c.decodeIfPresent(Vec3.self, forKey: .position) ?? .zero,
                  bank: try c.decodeIfPresent(Float.self, forKey: .bank) ?? 0,
                  width: try c.decodeIfPresent(Float.self, forKey: .width) ?? 1)
    }
}

/// A cross-section's outline.
public enum PathProfileShape: String, Codable, CaseIterable, Sendable {
    /// A strip `width` wide facing up (a road surface, water).
    case flat
    /// A `width` x `height` block standing on the centerline (a road bed, a wall, a rail).
    case box
    /// A round tube `width` across, centered on the centerline (a cable, a pipe).
    case tube
    /// `points` as the outline ([right, up] meters, counter-clockwise seen along the path).
    case custom
}

/// A cross-section swept along the path into one mesh.
public struct PathProfile: Codable, Equatable, Sendable {
    public var name: String
    public var shape: PathProfileShape
    /// Meters across (a tube's diameter).
    public var width: Float
    /// Meters tall (box).
    public var height: Float
    /// [right, up] meters from the centerline (two rails are two profiles at ±x).
    public var offset: Vec2
    /// Corners of a tube.
    public var sides: Int
    /// A custom outline, [right, up] meters.
    public var points: [Vec2]
    /// Join a custom outline's last point to its first.
    public var closedShape: Bool
    /// Drop of the middle of each span between control points below its ends (cables).
    public var sag: Float
    /// Display (sRGB) color 0...1.
    public var color: Vec3
    /// 1 is opaque; less blends (water).
    public var opacity: Float
    public var metallic: Float
    public var roughness: Float
    public var glow: Vec3
    /// An image or `.proctex` under `Assets/`.
    public var texture: String
    /// Texture repeats across the profile, and per meter along the path.
    public var textureScale: Vec2
    /// A material asset to use instead of the color fields.
    public var material: String
    /// Give the mesh a triangle-mesh collider.
    public var collider: Bool

    public static var fieldHints: [String: FieldHints] {
        ["width": FieldHints(range: 0.001...200, step: 0.05, tooltip: "Meters across (a tube's diameter)"),
         "height": FieldHints(range: 0.001...200, step: 0.05, tooltip: "Meters tall (box)"),
         "offset": FieldHints(step: 0.05, tooltip: "[right, up] meters from the centerline"),
         "sides": FieldHints(range: 3...32, step: 1, tooltip: "Corners of a tube"),
         "points": FieldHints(tooltip: "Custom outline: [right, up] meters, counter-clockwise seen along the path"),
         "closedShape": FieldHints(tooltip: "Join a custom outline's last point to its first"),
         "sag": FieldHints(range: 0...50, step: 0.05, tooltip: "How far each span between control points hangs (cables)"),
         "color": FieldHints(color: true), "glow": FieldHints(color: true, tooltip: "Emitted light color (black: none)"),
         "opacity": FieldHints(range: 0...1, step: 0.01), "metallic": FieldHints(range: 0...1, step: 0.01),
         "roughness": FieldHints(range: 0...1, step: 0.01),
         "texture": FieldHints(tooltip: "An image or .proctex under Assets/"),
         "textureScale": FieldHints(step: 0.05, tooltip: "Repeats across, and per meter along"),
         "material": FieldHints(tooltip: "A material asset that replaces the look fields"),
         "collider": FieldHints(tooltip: "A triangle-mesh collider, so things can stand on it")]
    }

    public init(name: String = "Surface", shape: PathProfileShape = .flat, width: Float = 4, height: Float = 0.2, offset: Vec2 = .zero,
                sides: Int = 8, points: [Vec2] = [], closedShape: Bool = true, sag: Float = 0, color: Vec3 = Vec3(0.5, 0.5, 0.5),
                opacity: Float = 1, metallic: Float = 0, roughness: Float = 0.8, glow: Vec3 = .zero, texture: String = "",
                textureScale: Vec2 = Vec2(1, 0.25), material: String = "", collider: Bool = false) {
        self.name = name
        self.shape = shape
        self.width = width
        self.height = height
        self.offset = offset
        self.sides = sides
        self.points = points
        self.closedShape = closedShape
        self.sag = sag
        self.color = color
        self.opacity = opacity
        self.metallic = metallic
        self.roughness = roughness
        self.glow = glow
        self.texture = texture
        self.textureScale = textureScale
        self.material = material
        self.collider = collider
    }

    private enum CodingKeys: String, CodingKey {
        case name, shape, width, height, offset, sides, points, closedShape, sag, color, opacity, metallic, roughness, glow, texture
        case textureScale, material, collider
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathProfile()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  shape: try c.decodeIfPresent(PathProfileShape.self, forKey: .shape) ?? d.shape,
                  width: try c.decodeIfPresent(Float.self, forKey: .width) ?? d.width,
                  height: try c.decodeIfPresent(Float.self, forKey: .height) ?? d.height,
                  offset: try c.decodeIfPresent(Vec2.self, forKey: .offset) ?? d.offset,
                  sides: try c.decodeIfPresent(Int.self, forKey: .sides) ?? d.sides,
                  points: try c.decodeIfPresent([Vec2].self, forKey: .points) ?? d.points,
                  closedShape: try c.decodeIfPresent(Bool.self, forKey: .closedShape) ?? d.closedShape,
                  sag: try c.decodeIfPresent(Float.self, forKey: .sag) ?? d.sag,
                  color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  opacity: try c.decodeIfPresent(Float.self, forKey: .opacity) ?? d.opacity,
                  metallic: try c.decodeIfPresent(Float.self, forKey: .metallic) ?? d.metallic,
                  roughness: try c.decodeIfPresent(Float.self, forKey: .roughness) ?? d.roughness,
                  glow: try c.decodeIfPresent(Vec3.self, forKey: .glow) ?? d.glow,
                  texture: try c.decodeIfPresent(String.self, forKey: .texture) ?? d.texture,
                  textureScale: try c.decodeIfPresent(Vec2.self, forKey: .textureScale) ?? d.textureScale,
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material,
                  collider: try c.decodeIfPresent(Bool.self, forKey: .collider) ?? d.collider)
    }

    /// The outline as edges in [right, up] meters (before `offset`), each with its outward
    /// normal, and whether its corners are smooth (tubes) — plus whether it is a closed loop.
    func outline(widthScale: Float) -> (points: [Vec2], closed: Bool, smooth: Bool) {
        let w = max(width, 0.001) * widthScale / 2
        switch shape {
        case .flat:
            // Right to left, so the face normal (dy, -dx) points up.
            return ([Vec2(w, 0), Vec2(-w, 0)], false, false)
        case .box:
            let h = max(height, 0.001)
            return ([Vec2(-w, 0), Vec2(w, 0), Vec2(w, h), Vec2(-w, h)], true, false)
        case .tube:
            let n = min(max(sides, 3), 64)
            return ((0..<n).map { i in
                let a = Float(i) / Float(n) * 2 * .pi
                return Vec2(cosf(a) * w, sinf(a) * w)
            }, true, true)
        case .custom:
            let pts = points.map { Vec2($0.x * widthScale, $0.y) }
            return (pts, closedShape && pts.count > 2, false)
        }
    }
}

/// A piece repeated along the path every `spacing` meters: a built-in shape, a `.meshbuild`, or a mesh.
public struct PathPiece: Codable, Equatable, Sendable {
    public var name: String
    /// A `.meshbuild` path (every part is drawn) or a mesh reference "asset:<id>#mesh/<name>";
    /// empty uses `shape`, `size` and `color`.
    public var asset: String
    /// A material for a mesh reference.
    public var material: String
    public var shape: MeshBuildShape
    /// Meters: the box the shape fills.
    public var size: Vec3
    /// Display (sRGB) color.
    public var color: Vec3
    public var metallic: Float
    public var roughness: Float
    /// Meters between pieces along the path.
    public var spacing: Float
    /// Meters along the path before the first piece.
    public var start: Float
    /// [right, up, forward] meters from the centerline.
    public var offset: Vec3
    /// Extra rotation, Euler degrees.
    public var rotation: Vec3
    public var scale: Float
    /// Stand straight up (only turn to the path's heading) instead of tilting with slope and bank.
    public var upright: Bool
    /// Also place a copy on the other side (offset x negated).
    public var mirror: Bool
    /// A box collider on each built-in piece.
    public var collider: Bool

    public static var fieldHints: [String: FieldHints] {
        ["asset": FieldHints(tooltip: "A .meshbuild, or asset:<id>#mesh/<name> (blank: the shape below)"),
         "size": FieldHints(step: 0.05, tooltip: "Meters: the box the shape fills"),
         "color": FieldHints(color: true), "metallic": FieldHints(range: 0...1, step: 0.01),
         "roughness": FieldHints(range: 0...1, step: 0.01),
         "spacing": FieldHints(range: 0.05...1000, step: 0.1, tooltip: "Meters between pieces"),
         "start": FieldHints(range: 0...10000, step: 0.1, tooltip: "Meters before the first piece"),
         "offset": FieldHints(step: 0.05, tooltip: "[right, up, forward] meters from the centerline"),
         "rotation": FieldHints(step: 1, tooltip: "Extra rotation, degrees"),
         "scale": FieldHints(range: 0.01...100, step: 0.05),
         "upright": FieldHints(tooltip: "Stand straight up instead of tilting with slope and bank"),
         "mirror": FieldHints(tooltip: "Also place one on the other side"),
         "collider": FieldHints(tooltip: "A box collider on each built-in piece")]
    }

    public init(name: String = "Piece", asset: String = "", material: String = "", shape: MeshBuildShape = .box,
                size: Vec3 = Vec3(0.2, 1, 0.2), color: Vec3 = Vec3(0.45, 0.33, 0.2), metallic: Float = 0, roughness: Float = 0.8,
                spacing: Float = 2, start: Float = 0, offset: Vec3 = .zero, rotation: Vec3 = .zero, scale: Float = 1,
                upright: Bool = true, mirror: Bool = false, collider: Bool = false) {
        self.name = name
        self.asset = asset
        self.material = material
        self.shape = shape
        self.size = size
        self.color = color
        self.metallic = metallic
        self.roughness = roughness
        self.spacing = spacing
        self.start = start
        self.offset = offset
        self.rotation = rotation
        self.scale = scale
        self.upright = upright
        self.mirror = mirror
        self.collider = collider
    }

    private enum CodingKeys: String, CodingKey {
        case name, asset, material, shape, size, color, metallic, roughness, spacing, start, offset, rotation, scale, upright, mirror, collider
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathPiece()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  asset: try c.decodeIfPresent(String.self, forKey: .asset) ?? d.asset,
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material,
                  shape: try c.decodeIfPresent(MeshBuildShape.self, forKey: .shape) ?? d.shape,
                  size: try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size,
                  color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  metallic: try c.decodeIfPresent(Float.self, forKey: .metallic) ?? d.metallic,
                  roughness: try c.decodeIfPresent(Float.self, forKey: .roughness) ?? d.roughness,
                  spacing: try c.decodeIfPresent(Float.self, forKey: .spacing) ?? d.spacing,
                  start: try c.decodeIfPresent(Float.self, forKey: .start) ?? d.start,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? d.offset,
                  rotation: try c.decodeIfPresent(Vec3.self, forKey: .rotation) ?? d.rotation,
                  scale: try c.decodeIfPresent(Float.self, forKey: .scale) ?? d.scale,
                  upright: try c.decodeIfPresent(Bool.self, forKey: .upright) ?? d.upright,
                  mirror: try c.decodeIfPresent(Bool.self, forKey: .mirror) ?? d.mirror,
                  collider: try c.decodeIfPresent(Bool.self, forKey: .collider) ?? d.collider)
    }
}

/// Terrain following: put the path on a `.terrain`'s surface.
public struct PathTerrain: Codable, Equatable, Sendable {
    /// A `.terrain` path under `Assets/`; empty turns following off.
    public var asset: String
    /// Where the terrain's origin is in the path's space (both placed at the same spot: zero).
    public var offset: Vec3
    /// Meters above the ground.
    public var height: Float

    public static var fieldHints: [String: FieldHints] {
        ["asset": FieldHints(tooltip: "A .terrain to follow (blank: off)"),
         "offset": FieldHints(step: 0.1, tooltip: "The terrain's origin in the path's space (zero when both are placed at the same spot)"),
         "height": FieldHints(range: -100...100, step: 0.01, tooltip: "Meters above the ground")]
    }

    public init(asset: String = "", offset: Vec3 = .zero, height: Float = 0.05) {
        self.asset = asset
        self.offset = offset
        self.height = height
    }

    private enum CodingKeys: String, CodingKey { case asset, offset, height }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathTerrain()
        self.init(asset: try c.decodeIfPresent(String.self, forKey: .asset) ?? d.asset,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? d.offset,
                  height: try c.decodeIfPresent(Float.self, forKey: .height) ?? d.height)
    }

    public var isOn: Bool { !asset.trimmingCharacters(in: .whitespaces).isEmpty }
}

/// One sample of a path's curve, in the path's space.
public struct PathSample: Equatable, Sendable {
    public var position: Vec3
    /// Unit direction of travel.
    public var forward: Vec3
    /// Unit right and up after banking.
    public var right: Vec3
    public var up: Vec3
    /// Meters from the start along the curve.
    public var distance: Float
    /// The spline parameter (control point i is at u = i).
    public var u: Float
    /// Bank in degrees, and the width multiplier.
    public var bank: Float
    public var width: Float
}

/// One placed piece, in the path's space.
public struct PathPieceInstance: Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat
    public var scale: Float
}

/// The contents of a `.path` file. See the notes at the top of this file.
public struct PathBuild: Codable, Equatable, Sendable {
    public static let maxSamples = 20_000
    public static let maxPieces = 10_000

    public var kind: PathKind
    public var points: [PathPoint]
    /// Join the end back to the start.
    public var closed: Bool
    /// Round the curve through the points (false: straight lines between them).
    public var smooth: Bool
    /// Meters between samples along the curve (smaller is smoother and heavier).
    public var spacing: Float
    /// Degrees added to every point's bank.
    public var bank: Float
    /// Up to this many degrees of extra bank in tight turns (a 10 m radius gets all of it).
    public var autoBank: Float
    public var profiles: [PathProfile]
    public var pieces: [PathPiece]
    public var terrain: PathTerrain

    public static var fieldHints: [String: FieldHints] {
        ["closed": FieldHints(tooltip: "Join the end back to the start (a loop)"),
         "smooth": FieldHints(tooltip: "Round the curve through the points (off: straight lines)"),
         "spacing": FieldHints(range: 0.05...50, step: 0.05, tooltip: "Meters between samples along the curve"),
         "bank": FieldHints(range: -89...89, step: 1, tooltip: "Degrees added to every point's bank"),
         "autoBank": FieldHints(range: -60...60, step: 1, tooltip: "Extra bank in tight turns, up to this many degrees")]
    }

    public init(kind: PathKind = .custom, points: [PathPoint] = [PathPoint(Vec3(-10, 0, 0)), PathPoint(Vec3(10, 0, 0))],
                closed: Bool = false, smooth: Bool = true, spacing: Float = 0.5, bank: Float = 0, autoBank: Float = 0,
                profiles: [PathProfile] = [PathProfile()], pieces: [PathPiece] = [], terrain: PathTerrain = PathTerrain()) {
        self.kind = kind
        self.points = points
        self.closed = closed
        self.smooth = smooth
        self.spacing = spacing
        self.bank = bank
        self.autoBank = autoBank
        self.profiles = profiles
        self.pieces = pieces
        self.terrain = terrain
    }

    private enum CodingKeys: String, CodingKey { case kind, points, closed, smooth, spacing, bank, autoBank, profiles, pieces, terrain }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathBuild()
        self.init(kind: try c.decodeIfPresent(PathKind.self, forKey: .kind) ?? d.kind,
                  points: try c.decodeIfPresent([PathPoint].self, forKey: .points) ?? d.points,
                  closed: try c.decodeIfPresent(Bool.self, forKey: .closed) ?? d.closed,
                  smooth: try c.decodeIfPresent(Bool.self, forKey: .smooth) ?? d.smooth,
                  spacing: try c.decodeIfPresent(Float.self, forKey: .spacing) ?? d.spacing,
                  bank: try c.decodeIfPresent(Float.self, forKey: .bank) ?? d.bank,
                  autoBank: try c.decodeIfPresent(Float.self, forKey: .autoBank) ?? d.autoBank,
                  profiles: try c.decodeIfPresent([PathProfile].self, forKey: .profiles) ?? d.profiles,
                  pieces: try c.decodeIfPresent([PathPiece].self, forKey: .pieces) ?? d.pieces,
                  terrain: try c.decodeIfPresent(PathTerrain.self, forKey: .terrain) ?? d.terrain)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    // MARK: Presets

    /// A starting path of `kind` through `points` (default: a gentle S curve 40 m long).
    public static func preset(_ kind: PathKind, points: [PathPoint]? = nil) -> PathBuild {
        let curve = points ?? [PathPoint(Vec3(-20, 0, 0)), PathPoint(Vec3(-7, 0, -6)), PathPoint(Vec3(7, 0, 6)), PathPoint(Vec3(20, 0, 0))]
        var build = PathBuild(kind: kind, points: curve)
        build.applyPreset(kind)
        return build
    }

    /// Replaces the profiles and pieces (and the curve settings that go with them) with `kind`'s;
    /// the points and terrain stay.
    public mutating func applyPreset(_ kind: PathKind) {
        self.kind = kind
        smooth = true
        spacing = 0.5
        switch kind {
        case .road:
            profiles = [
                PathProfile(name: "Road", shape: .box, width: 6, height: 0.3, offset: Vec2(0, -0.25), color: Vec3(0.18, 0.18, 0.2),
                            roughness: 0.9, collider: true),
                PathProfile(name: "Center Line", shape: .flat, width: 0.15, offset: Vec2(0, 0.06), color: Vec3(0.95, 0.85, 0.3), roughness: 0.6),
            ]
            pieces = []
        case .rail:
            profiles = [
                PathProfile(name: "Ballast", shape: .custom, offset: Vec2(0, -0.3),
                            points: [Vec2(-1.6, 0), Vec2(1.6, 0), Vec2(1.1, 0.3), Vec2(-1.1, 0.3)],
                            color: Vec3(0.4, 0.38, 0.35), roughness: 1, collider: true),
                PathProfile(name: "Left Rail", shape: .box, width: 0.08, height: 0.12, offset: Vec2(-0.72, 0.08), color: Vec3(0.55, 0.55, 0.58),
                            metallic: 1, roughness: 0.35),
                PathProfile(name: "Right Rail", shape: .box, width: 0.08, height: 0.12, offset: Vec2(0.72, 0.08), color: Vec3(0.55, 0.55, 0.58),
                            metallic: 1, roughness: 0.35),
            ]
            pieces = [PathPiece(name: "Sleepers", size: Vec3(2.4, 0.1, 0.25), color: Vec3(0.3, 0.2, 0.12), spacing: 0.65,
                                offset: Vec3(0, 0.03, 0), upright: false)]
        case .river:
            profiles = [
                PathProfile(name: "Water", shape: .flat, width: 8, offset: Vec2(0, -0.2), color: Vec3(0.12, 0.35, 0.5), opacity: 0.75,
                            metallic: 0, roughness: 0.08),
                PathProfile(name: "Bed", shape: .custom, offset: Vec2(0, -0.2),
                            points: [Vec2(-4.5, 0.25), Vec2(-3, -0.9), Vec2(3, -0.9), Vec2(4.5, 0.25)], closedShape: false,
                            color: Vec3(0.3, 0.25, 0.18), roughness: 1),
            ]
            pieces = []
        case .fence:
            profiles = [
                PathProfile(name: "Top Rail", shape: .box, width: 0.06, height: 0.1, offset: Vec2(0, 0.95), color: Vec3(0.5, 0.36, 0.22)),
                PathProfile(name: "Low Rail", shape: .box, width: 0.06, height: 0.1, offset: Vec2(0, 0.45), color: Vec3(0.5, 0.36, 0.22)),
            ]
            pieces = [PathPiece(name: "Posts", size: Vec3(0.14, 1.2, 0.14), color: Vec3(0.42, 0.3, 0.18), spacing: 2.5,
                                offset: Vec3(0, 0.6, 0), collider: true)]
        case .cable:
            profiles = [PathProfile(name: "Cable", shape: .tube, width: 0.05, offset: Vec2(0, 6), sides: 6, sag: 1.2,
                                    color: Vec3(0.08, 0.08, 0.08), roughness: 0.6)]
            pieces = []
            smooth = false
        case .wall:
            profiles = [PathProfile(name: "Wall", shape: .box, width: 0.6, height: 3, color: Vec3(0.55, 0.52, 0.48), roughness: 0.95,
                                    textureScale: Vec2(1, 0.5), collider: true),
                        PathProfile(name: "Cap", shape: .box, width: 0.8, height: 0.15, offset: Vec2(0, 3), color: Vec3(0.45, 0.43, 0.4))]
            pieces = []
            smooth = false
        case .custom:
            profiles = [PathProfile()]
            pieces = []
        }
    }

    // MARK: Curve

    /// The control points' positions.
    public var controlPositions: [Vec3] { points.map(\.position) }

    var segmentCount: Int { CatmullRom.segmentCount(points.count, closed: closed) }
    var wraps: Bool { closed && points.count > 2 }

    /// The curve at parameter `u` (control point i at u = i), before terrain following.
    public func curvePosition(at u: Float) -> Vec3 {
        let p = controlPositions
        guard smooth else {
            let segments = segmentCount
            guard segments > 0 else { return p.first ?? .zero }
            let clamped = min(max(u, 0), Float(segments))
            let i = min(Int(clamped), segments - 1)
            let t = clamped - Float(i)
            return p[i % p.count] + (p[(i + 1) % p.count] - p[i % p.count]) * t
        }
        return CatmullRom.position(at: u, points: p, closed: closed)
    }

    /// Bank (degrees, before auto bank) and width at parameter `u`, linear between control points.
    func pointValues(at u: Float) -> (bank: Float, width: Float) {
        guard !points.isEmpty else { return (bank, 1) }
        let segments = segmentCount
        guard segments > 0 else { return (points[0].bank + bank, points[0].width) }
        let clamped = min(max(u, 0), Float(segments))
        let i = min(Int(clamped), segments - 1)
        let t = clamped - Float(i)
        let a = points[i % points.count], b = points[(i + 1) % points.count]
        return (a.bank + (b.bank - a.bank) * t + bank, a.width + (b.width - a.width) * t)
    }

    /// The length of the curve in meters (before terrain following).
    public var length: Float { samples().last?.distance ?? 0 }

    /// The curve sampled about every `spacing` meters, with frames, on `terrain` when given
    /// (in the path's space; `self.terrain.offset` places it). At most `maxSamples` samples.
    public func samples(on ground: Terrain? = nil) -> [PathSample] {
        let segments = segmentCount
        guard segments > 0 else { return [] }
        // A fine table of the curve, then equal-distance steps along it.
        let perSegment = 32
        let steps = segments * perSegment
        var table: [(u: Float, p: Vec3, d: Float)] = []
        table.reserveCapacity(steps + 1)
        var total: Float = 0
        var previous = curvePosition(at: 0)
        for k in 0...steps {
            let u = Float(k) / Float(perSegment)
            let p = curvePosition(at: u)
            if k > 0 { total += EngineCore.length(p - previous) }
            table.append((u, p, total))
            previous = p
        }
        guard total > 1e-5 else { return [] }
        let step = max(spacing, 0.05)
        let count = min(max(Int((total / step).rounded(.up)), segments), Self.maxSamples - 1)
        var us: [Float] = []
        us.reserveCapacity(count + 1)
        var j = 0
        for s in 0...count {
            let target = total * Float(s) / Float(count)
            while j < steps - 1 && table[j + 1].d < target { j += 1 }
            let a = table[j], b = table[j + 1]
            let f = b.d > a.d ? (target - a.d) / (b.d - a.d) : 0
            us.append(a.u + (b.u - a.u) * min(max(f, 0), 1))
        }
        // Make sure every control point is a sample (sharp corners of straight paths stay sharp).
        if !smooth {
            us = Array(Set(us + (0...segments).map(Float.init))).sorted()
        }

        var positions = us.map { curvePosition(at: $0) }
        if let ground {
            for i in positions.indices { positions[i].y = groundHeight(ground, x: positions[i].x, z: positions[i].z) }
        }
        let n = positions.count
        var result: [PathSample] = []
        result.reserveCapacity(n)
        var distance: Float = 0
        var lastRight = Vec3(1, 0, 0)
        for i in 0..<n {
            if i > 0 { distance += EngineCore.length(positions[i] - positions[i - 1]) }
            let ahead: Vec3, behind: Vec3
            if wraps {
                // The last sample repeats the first; neighbors wrap past it.
                ahead = i == n - 1 ? positions[1] : positions[i + 1]
                behind = i == 0 ? positions[n - 2] : positions[i - 1]
            } else {
                ahead = positions[min(i + 1, n - 1)]
                behind = positions[max(i - 1, 0)]
            }
            var forward = ahead - behind
            if !(EngineCore.length(forward) > 1e-6) { forward = result.last?.forward ?? Vec3(0, 0, -1) }
            forward = normalize(forward)
            var right = cross(forward, Vec3(0, 1, 0))
            if EngineCore.length(right) > 1e-4 { right = normalize(right); lastRight = right } else { right = lastRight }
            var up = normalize(cross(right, forward))
            // Auto bank from the turn: the heading change per meter, signed (right turn positive).
            let values = pointValues(at: us[i])
            var bankDegrees = values.bank
            if autoBank != 0 {
                let a = Vec2(ahead.x - positions[i].x, ahead.z - positions[i].z), b = Vec2(positions[i].x - behind.x, positions[i].z - behind.z)
                let la = hypotf(a.x, a.y), lb = hypotf(b.x, b.y)
                if la > 1e-5 && lb > 1e-5 {
                    let turn = atan2f(b.x * a.y - b.y * a.x, a.x * b.x + a.y * b.y)  // radians, right turn positive
                    let curvature = turn / ((la + lb) / 2)
                    bankDegrees += autoBank * min(max(curvature * 10, -1), 1)
                }
            }
            if bankDegrees != 0 {
                let r = bankDegrees * .pi / 180
                let c = cosf(r), s = sinf(r)
                let banked = right * c - up * s
                up = up * c + right * s
                right = banked
            }
            result.append(PathSample(position: positions[i], forward: forward, right: right, up: up, distance: distance, u: us[i],
                                     bank: bankDegrees, width: max(values.width, 0.001)))
        }
        return result
    }

    /// The ground height (plus `terrain.height`) under path-space (x, z).
    public func groundHeight(_ ground: Terrain, x: Float, z: Float) -> Float {
        ground.heightAt(x: x - terrain.offset.x, z: z - terrain.offset.z) + terrain.offset.y + terrain.height
    }

    /// The point `distance` meters along `samples` (clamped; wraps on a closed path).
    public static func sample(_ samples: [PathSample], atDistance distance: Float, closed: Bool = false) -> PathSample? {
        guard let first = samples.first, let last = samples.last else { return nil }
        var d = distance
        if closed && last.distance > 0 { d = d.truncatingRemainder(dividingBy: last.distance); if d < 0 { d += last.distance } }
        d = min(max(d, 0), last.distance)
        guard samples.count > 1, d > first.distance else { return first }
        var lo = 0, hi = samples.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if samples[mid].distance <= d { lo = mid } else { hi = mid }
        }
        let a = samples[lo], b = samples[hi]
        let f = b.distance > a.distance ? (d - a.distance) / (b.distance - a.distance) : 0
        func mix(_ x: Vec3, _ y: Vec3) -> Vec3 { x + (y - x) * f }
        func unit(_ v: Vec3, _ fallback: Vec3) -> Vec3 { EngineCore.length(v) > 1e-6 ? normalize(v) : fallback }
        return PathSample(position: mix(a.position, b.position), forward: unit(mix(a.forward, b.forward), a.forward),
                          right: unit(mix(a.right, b.right), a.right), up: unit(mix(a.up, b.up), a.up), distance: d,
                          u: a.u + (b.u - a.u) * f, bank: a.bank + (b.bank - a.bank) * f, width: a.width + (b.width - a.width) * f)
    }

    // MARK: Geometry

    /// The mesh of `profile` swept along `samples`, in the path's space, or nil when there is
    /// nothing to draw. Hard edges get their own vertices; tubes are smooth. Closed outlines get
    /// end caps on open paths. UVs: U across the outline, V along the path, scaled by `textureScale`.
    public func mesh(_ profile: PathProfile, samples: [PathSample]) -> MeshGeometry? {
        guard samples.count >= 2 else { return nil }
        let base = profile.outline(widthScale: 1)
        guard base.points.count >= 2 else { return nil }
        let k = base.points.count
        let edgeCount = base.closed ? k : k - 1
        // Each sample's outline in 3D (sagged for cables).
        let sagSpans = profile.sag > 0
        let p = controlPositions
        var rings: [[Vec3]] = []
        rings.reserveCapacity(samples.count)
        for s in samples {
            let outline = profile.outline(widthScale: s.width).points
            var center = s.position + s.right * profile.offset.x + s.up * profile.offset.y
            if sagSpans, segmentCount > 0 {
                let i = min(Int(s.u), segmentCount - 1)
                let t = s.u - Float(i)
                let chord = EngineCore.length(p[(i + 1) % p.count] - p[i % p.count])
                center.y -= profile.sag * CableSag.profile(catenary: true, t: t, sag: profile.sag, chord: chord)
            }
            rings.append(outline.map { center + s.right * $0.x + s.up * $0.y })
        }
        // Distance across the outline for U.
        var across = [Float](repeating: 0, count: k + 1)
        for e in 0..<edgeCount {
            let a = base.points[e], b = base.points[(e + 1) % k]
            across[e + 1] = across[e] + hypotf(b.x - a.x, b.y - a.y)
        }
        let perimeter = max(across[edgeCount], 1e-5)
        let uScale = profile.textureScale.x, vScale = profile.textureScale.y

        var g = MeshGeometry(vertices: [], indices: [])
        func addQuad(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32, normal: Vec3) {
            // a, b on this ring; c, d on the next. Wind so the face looks along `normal`.
            let pa = g.vertices[Int(a)].position, pb = g.vertices[Int(b)].position, pc = g.vertices[Int(c)].position
            if dot(cross(pb - pa, pc - pa), normal) >= 0 { g.indices += [a, b, c, b, d, c] } else { g.indices += [a, c, b, b, c, d] }
        }
        if base.smooth {
            // One vertex per outline point per ring (plus a seam column), radial normals.
            let cols = k + 1
            for (r, s) in samples.enumerated() {
                let center = rings[r].reduce(Vec3.zero, +) / Float(k)
                for c in 0..<cols {
                    let pos = rings[r][c % k]
                    var normal = pos - center
                    normal = EngineCore.length(normal) > 1e-6 ? normalize(normal) : s.up
                    g.vertices.append(MeshVertex(position: pos, normal: normal,
                                                 uv: Vec2(Float(c) / Float(k) * uScale, s.distance * vScale)))
                }
            }
            for r in 0..<(samples.count - 1) {
                for c in 0..<k {
                    let a = UInt32(r * cols + c), b = a + 1, cc = a + UInt32(cols), d = cc + 1
                    addQuad(a, b, cc, d, normal: g.vertices[Int(a)].normal)
                }
            }
        } else {
            // Each edge is its own strip with a flat normal per ring.
            for e in 0..<edgeCount {
                let a2 = base.points[e], b2 = base.points[(e + 1) % k]
                let d2 = b2 - a2
                let n2 = Vec2(d2.y, -d2.x)  // outward for counter-clockwise outlines
                let start = UInt32(g.vertices.count)
                for (r, s) in samples.enumerated() {
                    var normal = s.right * n2.x + s.up * n2.y
                    normal = EngineCore.length(normal) > 1e-6 ? normalize(normal) : s.up
                    for (corner, uFrac) in [(e, across[e]), ((e + 1) % k, across[e + 1])] {
                        g.vertices.append(MeshVertex(position: rings[r][corner], normal: normal,
                                                     uv: Vec2(uFrac / perimeter * uScale, s.distance * vScale)))
                    }
                }
                for r in 0..<UInt32(samples.count - 1) {
                    let a = start + r * 2, b = a + 1, c = a + 2, d = a + 3
                    addQuad(a, b, c, d, normal: g.vertices[Int(a)].normal)
                }
            }
        }
        // End caps on closed outlines of open paths (fans around the outline's center).
        if base.closed && !wraps {
            for (r, sign) in [(0, Float(-1)), (samples.count - 1, Float(1))] {
                let ring = rings[r]
                let normal = samples[r].forward * sign
                let center = ring.reduce(Vec3.zero, +) / Float(ring.count)
                let start = UInt32(g.vertices.count)
                g.vertices.append(MeshVertex(position: center, normal: normal, uv: Vec2(0.5, 0.5)))
                for (i, pos) in ring.enumerated() {
                    let o = base.points[i]
                    g.vertices.append(MeshVertex(position: pos, normal: normal, uv: Vec2(o.x * uScale, o.y * uScale)))
                }
                for i in 0..<UInt32(k) {
                    let a = start + 1 + i, b = start + 1 + (i + 1) % UInt32(k)
                    let pa = g.vertices[Int(a)].position, pb = g.vertices[Int(b)].position
                    if dot(cross(pa - center, pb - center), normal) >= 0 { g.indices += [start, a, b] } else { g.indices += [start, b, a] }
                }
            }
        }
        return g.indices.isEmpty ? nil : g
    }

    /// Where `piece` goes along `samples` (on `ground` when given), at most `limit` of them.
    public func instances(of piece: PathPiece, samples: [PathSample], on ground: Terrain? = nil,
                          limit: Int = PathBuild.maxPieces) -> [PathPieceInstance] {
        guard let total = samples.last?.distance, total > 0, limit > 0 else { return [] }
        let spacing = max(piece.spacing, 0.05)
        var result: [PathPieceInstance] = []
        let extra = Quat(eulerDegrees: piece.rotation)
        var d = max(piece.start, 0)
        // A closed path doesn't repeat a piece at its end (it is the start).
        let end = wraps ? total - spacing * 0.5 : total + 1e-4
        while d <= end, result.count < limit {
            guard let s = Self.sample(samples, atDistance: d, closed: wraps) else { break }
            var forward = s.forward, right = s.right, up = s.up
            if piece.upright {
                let flat = Vec3(s.forward.x, 0, s.forward.z)
                forward = EngineCore.length(flat) > 1e-5 ? normalize(flat) : Vec3(0, 0, -1)
                right = normalize(cross(forward, Vec3(0, 1, 0)))
                up = Vec3(0, 1, 0)
            }
            let rotation = Quat(rotationMatrix: Mat4(Vec4(right, 0), Vec4(up, 0), Vec4(-forward, 0), Vec4(0, 0, 0, 1))).normalized
            for side in piece.mirror ? [Float(1), -1] : [1] {
                let o = Vec3(piece.offset.x * side * s.width, piece.offset.y, piece.offset.z)
                var position = s.position + right * o.x + up * o.y + forward * o.z
                if let ground {
                    // On the ground under the piece itself (a fence post beside the road stands on its own spot).
                    position.y = groundHeight(ground, x: position.x, z: position.z) + o.y
                }
                result.append(PathPieceInstance(position: position, rotation: (rotation * extra).normalized, scale: max(piece.scale, 0.001)))
            }
            d += spacing
        }
        return Array(result.prefix(limit))
    }

    /// Problems found without reading other files (more come from the importer).
    public var problems: [String] {
        var problems: [String] = []
        if points.count < 2 { problems.append("a path needs at least 2 points (it has \(points.count))") }
        if closed && points.count < 3 { problems.append("a closed path needs at least 3 points") }
        for profile in profiles where profile.shape == .custom && profile.points.count < 2 {
            problems.append("profile '\(profile.name)': a custom shape needs at least 2 points")
        }
        let names = profiles.map(\.name) + pieces.map(\.name)
        if Set(names).count != names.count { problems.append("some profiles or pieces share a name") }
        return problems
    }
}
