#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// A model built from shapes: the contents of a `.meshbuild` file (JSON, every key optional).
// `MeshBuildImporter` turns it into one mesh and one material per part plus a prefab of the part
// tree, so it is placed, instanced and reimported like any glTF model. Animations become
// `FieldAnimator`s on the parts and play in play mode and built games. A part's `mirror` and
// `repeat` stand for mirrored and repeated copies of it (see MeshBuildExpansion.swift).
//
// ```json
// {
//   "parts": [
//     {"name": "Body", "shape": "box", "size": [2, 0.6, 1], "position": [0, 0.5, 0], "color": [0.8, 0.1, 0.1]},
//     {"name": "Wheel", "shape": "cylinder", "parent": "Body", "size": [0.5, 0.2, 0.5],
//      "position": [0.7, -0.3, 0.55], "rotation": [90, 0, 0], "texture": "Textures/tire.png"}
//   ],
//   "animations": [
//     {"name": "Drive", "motions": [{"part": "Wheel", "kind": "spin", "axis": "y", "period": 1}]},
//     {"name": "Hop", "tracks": [{"part": "Body", "property": "position", "interpolation": "hermite",
//      "keys": [{"time": 0, "value": [0, 0, 0]}, {"time": 0.5, "value": [0, 0.3, 0]}, {"time": 1, "value": [0, 0, 0]}]}]}
//   ]
// }
// ```

/// The shape a `MeshBuildPart` draws, fitted to its `size` box (centered on the part's origin).
public enum MeshBuildShape: String, Codable, CaseIterable, Sendable {
    /// No mesh: a pivot that other parts hang from (a hinge, a turret base).
    case group
    case box
    /// An ellipsoid filling the box.
    case sphere
    /// The top half of a sphere: flat base at the bottom of the box, dome up to its top.
    case hemisphere
    /// Along Y: diameter `size.x` by `size.z`, height `size.y`.
    case cylinder
    /// Along Y with the tip up.
    case cone
    /// Along Y with rounded ends.
    case capsule
    /// A ring in XZ: outer diameter `size.x` / `size.z`, tube thickness `size.y`.
    case torus
    /// A hollow cylinder along Y whose wall is `thickness` thick.
    case tube
    /// A flat quad in XZ facing up (`size.y` is ignored).
    case plane
    /// A ramp: full height at -Z sloping down to nothing at +Z.
    case wedge
    /// A square-based pyramid with its tip up.
    case pyramid
    /// A round solid turned from `profile` (`[radius, height]` points in meters, bottom to top)
    /// around Y, like a vase, bottle or chess piece. See `MeshBuildPart.shapesDoc`.
    case lathe
    /// A flat outline (`profile`, `[x, y]` points in meters) pushed out along Z by `size.z`
    /// meters, like a sign, a letter or a blade. See `MeshBuildPart.shapesDoc`.
    case extrude
    /// Its children (the whole subtree) melted, cut and combined into one smooth surface instead
    /// of drawn on their own. See MeshBuildSculpt.swift and `MeshBuildPart.sculptDoc`.
    case sculpt
    // Curves (MeshBuildCurves.swift):
    /// A section (a circle of `radius` or a `profile`) moved along a smooth 3D `path`, like a pipe,
    /// cable, handle, railing, branch or horn. See `MeshBuildPart.curvesDoc`.
    case sweep
    /// A skin through a stack of `sections` along `axis`, like a hull, bottle, fuselage or blade.
    case loft
    /// Leaf cards (a leaf `look`) filling the ellipsoid of `size`, or growing `on` other parts:
    /// tree crowns, shrubs, grass, flowers, ivy. See MeshBuildFoliage.swift and `MeshBuildPart.foliageDoc`.
    case foliage
}

/// One shape of a mesh build: geometry, placement in its parent and its look.
///
/// Colors are display (sRGB) values 0...1, like a color picker's. `texture` and `material` name
/// project assets by path relative to `Assets/` ("Textures/brick.png", a `.proctex` file works
/// too) or by reference ("asset:<id>"). A `material` replaces every look field.
public struct MeshBuildPart: Codable, Equatable, Sendable {
    public var name: String
    public var shape: MeshBuildShape
    /// Another part's name; "" hangs this part from the model's root.
    public var parent: String
    /// In the parent's space, meters.
    public var position: Vec3
    /// Euler angles in degrees.
    public var rotation: Vec3
    /// The box the shape fills, meters. Baked into the mesh (children don't inherit it).
    public var size: Vec3
    /// Slices around round shapes (3...128).
    public var segments: Int
    /// Wall thickness of a `tube`, meters.
    public var thickness: Float
    public var color: Vec3
    /// 1 is opaque; less blends.
    public var opacity: Float
    public var texture: String
    /// Texture repeats across the part (with `worldUV`: per meter).
    public var textureScale: Vec2
    /// Projects texture coordinates from positions in meters, so a texture keeps its size on
    /// parts of any size instead of stretching.
    public var worldUV: Bool
    public var metallic: Float
    public var roughness: Float
    /// Emitted color (black: none).
    public var glow: Vec3
    public var glowStrength: Float
    /// A material asset to use instead of the fields above.
    public var material: String
    /// The radius of a `box`'s rounded edges or a `cylinder`'s rounded rims, meters (nil or 0:
    /// sharp; clamped to half the smallest size). `segments` sets how smooth the rounding is.
    public var bevel: Float?
    /// The outline of a `lathe` (`[radius, height]`) or an `extrude` (`[x, y]`), meters. Unlike
    /// the other shapes it isn't fitted to `size`: its coordinates are used as written (the
    /// part's origin is the profile's origin), and `size` multiplies them, so leave `size` at
    /// [1, 1, 1] to get exactly the profile (an extrude's depth is `size.z` meters).
    public var profile: [Vec2]?
    /// Also draw a mirror image of the part and its subtree across these axes of the parent
    /// (see MeshBuildExpansion.swift).
    public var mirror: MeshBuildMirror?
    /// Copies of the part and its subtree in a line or a ring (`"repeat"` in the file; see
    /// MeshBuildExpansion.swift).
    public var repetition: MeshBuildRepeat?

    // Curves and deformers (MeshBuildCurves.swift, MeshBuildDeform.swift); all optional, left out of the file when nil.
    /// A `sweep`'s path, `[x, y, z]` points in meters in the part's space.
    public var path: [Vec3]?
    /// A `sweep`'s circle radius, meters (default 0.05; unused with a `profile`).
    public var radius: Float?
    /// A `sweep`'s section multiplier at each path point (taper).
    public var radii: [Float]?
    /// A `sweep` whose path loops back to its start.
    public var closed: Bool?
    /// A `sweep` or `loft` made of straight segments with sharp corners (true) instead of a
    /// smooth spline through its points (nil or false, the default). Not `smooth`: that key is a
    /// sculpt child's melt radius.
    public var straight: Bool?
    /// A `loft`'s cross-sections.
    public var sections: [MeshBuildSection]?
    /// The axis a `loft` runs along (default y).
    public var axis: MeshBuildAxis?
    /// Deformers applied in order to the part's mesh, before mirroring.
    public var deform: [MeshBuildDeform]?
    /// How finely the mesh is split before deforming (0...6, default 3).
    public var subdivide: Int?

    // Looks (MeshBuildLooks.swift): a realistic surface from generated textures.
    /// A `MeshBuildLook` name ("wood", "rustyMetal"…); `color` tints it (its average color),
    /// leave `color` at the default for the look's own. Unknown names warn.
    public var look: String?
    /// Meters one texture tile of the look covers (default per look).
    public var lookScale: Float?
    /// 0...1: grime in low spots, scratches, chipped paint, darker creases.
    public var wear: Float?
    /// The part axis the look's grain runs along (default: Y for round shapes, else the longest side).
    public var grain: MeshBuildAxis?
    /// Not in the file: the signs (±1 per axis) the mesh is reflected by, set on mirror copies by
    /// `MeshBuild.expansion()`; `geometry()` applies it.
    public var reflection = Vec3(1, 1, 1)

    // Sculpt fields (MeshBuildSculpt.swift). Not in `init`'s parameters: set them after.
    /// A sculpt child's way of combining with the children before it (nil: add).
    public var blend: MeshBuildBlend? = nil
    /// A sculpt child's smoothing radius with the children before it, meters (nil: 0, sharp).
    public var smooth: Float? = nil
    /// A sculpt's grid: cells along its longest side (nil: the default).
    public var resolution: Int? = nil
    /// A sculpt's surface bumps.
    public var noise: MeshBuildNoise? = nil
    /// Not in the file: a sculpt's children in its space, set by `MeshBuild.gatheringSculpts`; `geometry()` meshes them.
    public var sculptChildren: [MeshBuildSculptChild] = []

    // Foliage and ribbons (MeshBuildFoliage.swift, MeshBuildRibbon.swift). Not in `init`'s parameters: set them after.
    /// A foliage card's side, meters (nil: the leaf look's default).
    public var cardSize: Float? = nil
    /// Exactly this many foliage cards (nil: from `density`).
    public var count: Int? = nil
    /// How thickly foliage cards cover (nil: 1, a full canopy).
    public var density: Float? = nil
    /// Changes which cards a foliage part makes.
    public var seed: Int? = nil
    /// Parts foliage grows on (a name or a list in the file).
    public var on: [String]? = nil
    /// Where along the `on` sweeps leaves grow: [from, to] fractions of their length.
    public var along: Vec2? = nil
    /// A sweep whose `profile` is an open curve: a double-sided surface without caps.
    public var open: Bool? = nil
    /// A sweep drawn as a flat strip this many meters wide (times `radii`).
    public var ribbon: Float? = nil
    /// The physics material (a built-in name or a `.physmat` path) placed copies' colliders and
    /// footsteps use; unset: the one its `look` implies (MeshBuildPhysicsMaterials.swift).
    public var physicsMaterial: String? = nil
    /// Not in the file: a foliage part's `on` targets in its space, set by `MeshBuild.attachingFoliageTargets`.
    public var foliageTargets: [MeshBuildFoliageTarget] = []
    /// Not in the file: problems with its `on` names, found with the targets.
    public var foliageContextWarnings: [String] = []
    /// Not in the file: how much farther apart a sweep's rings are than usual (detail levels, MeshBuildLOD.swift).
    package var curveRingStep: Float = 1
    /// A `.groom` file (path under `Assets/` or "asset:<id>"): fur or hair grown on this part's
    /// mesh (GroomBuild.swift). Not in `init`'s parameters: set it after.
    public var groom: String? = nil

    public static var fieldHints: [String: FieldHints] {
        ["parent": FieldHints(tooltip: "The part this one is attached to (moves with it)"),
         "rotation": FieldHints(step: 1, tooltip: "Degrees"),
         "size": FieldHints(step: 0.05, tooltip: "Meters: the box the shape fills"),
         "position": FieldHints(step: 0.05, tooltip: "Meters, in the parent's space"),
         "segments": FieldHints(range: 3...128, step: 1, tooltip: "Smoothness of round shapes"),
         "thickness": FieldHints(range: 0.001...100, step: 0.01, tooltip: "Tube wall thickness"),
         "color": FieldHints(color: true, srgb: true), "glow": FieldHints(color: true, srgb: true, tooltip: "Emitted light color (black: none)"),
         "opacity": FieldHints(range: 0...1, step: 0.01), "metallic": FieldHints(range: 0...1, step: 0.01),
         "roughness": FieldHints(range: 0...1, step: 0.01), "glowStrength": FieldHints(range: 0...100, step: 0.1),
         "textureScale": FieldHints(step: 0.1, tooltip: "Texture repeats (per meter with World UV)"),
         "worldUV": FieldHints(displayName: "World UV", tooltip: "Keep the texture's size in meters instead of stretching it"),
         "texture": FieldHints(tooltip: "A texture asset (image or .proctex)"),
         "material": FieldHints(tooltip: "A material asset that replaces the look fields"),
         // Edited by the Mesh Builder's own widgets, shown only for the shapes that use them.
         "bevel": FieldHints(hidden: true), "profile": FieldHints(hidden: true),
         // Edited in the Mesh Builder's own Mirror / Repeat rows.
         "mirror": FieldHints(hidden: true), "repeat": FieldHints(hidden: true),
         // Edited in the Mesh Builder's Sculpt rows.
         "blend": FieldHints(hidden: true), "smooth": FieldHints(hidden: true), "resolution": FieldHints(hidden: true),
         "noise": FieldHints(hidden: true),
         // Curves and deformers: edited in the Mesh Builder's own rows.
         "path": FieldHints(hidden: true), "radius": FieldHints(hidden: true), "radii": FieldHints(hidden: true),
         "closed": FieldHints(hidden: true), "straight": FieldHints(hidden: true), "sections": FieldHints(hidden: true),
         "axis": FieldHints(hidden: true), "deform": FieldHints(hidden: true), "subdivide": FieldHints(hidden: true),
         // Edited in the Mesh Builder's own Look rows.
         "look": FieldHints(hidden: true), "lookScale": FieldHints(hidden: true), "wear": FieldHints(hidden: true),
         "grain": FieldHints(hidden: true),
         // Foliage and ribbons: edited in the Mesh Builder's own Foliage rows.
         "cardSize": FieldHints(hidden: true), "count": FieldHints(hidden: true), "density": FieldHints(hidden: true),
         "seed": FieldHints(hidden: true), "on": FieldHints(hidden: true), "along": FieldHints(hidden: true),
         "open": FieldHints(hidden: true), "ribbon": FieldHints(hidden: true),
         "groom": FieldHints(tooltip: "A .groom file: fur or hair grown on this part")]
    }

    public init(name: String = "Part", shape: MeshBuildShape = .box, parent: String = "", position: Vec3 = .zero,
                rotation: Vec3 = .zero, size: Vec3 = Vec3(1, 1, 1), segments: Int = 24, thickness: Float = 0.1,
                color: Vec3 = Vec3(0.8, 0.8, 0.8), opacity: Float = 1, texture: String = "", textureScale: Vec2 = Vec2(1, 1),
                worldUV: Bool = false, metallic: Float = 0, roughness: Float = 0.5, glow: Vec3 = .zero, glowStrength: Float = 1,
                material: String = "", bevel: Float? = nil, profile: [Vec2]? = nil, mirror: MeshBuildMirror? = nil, repetition: MeshBuildRepeat? = nil,
                // Curves and deformers.
                path: [Vec3]? = nil, radius: Float? = nil, radii: [Float]? = nil, closed: Bool? = nil, straight: Bool? = nil,
                sections: [MeshBuildSection]? = nil, axis: MeshBuildAxis? = nil, deform: [MeshBuildDeform]? = nil, subdivide: Int? = nil,
                // Looks.
                look: String? = nil, lookScale: Float? = nil, wear: Float? = nil, grain: MeshBuildAxis? = nil) {
        self.name = name
        self.shape = shape
        self.parent = parent
        self.position = position
        self.rotation = rotation
        self.size = size
        self.segments = segments
        self.thickness = thickness
        self.color = color
        self.opacity = opacity
        self.texture = texture
        self.textureScale = textureScale
        self.worldUV = worldUV
        self.metallic = metallic
        self.roughness = roughness
        self.glow = glow
        self.glowStrength = glowStrength
        self.material = material
        self.bevel = bevel
        self.profile = profile
        self.mirror = mirror
        self.repetition = repetition
        // Curves and deformers.
        self.path = path
        self.radius = radius
        self.radii = radii
        self.closed = closed
        self.straight = straight
        self.sections = sections
        self.axis = axis
        self.deform = deform
        self.subdivide = subdivide
        // Looks.
        self.look = look
        self.lookScale = lookScale
        self.wear = wear
        self.grain = grain
    }

    private enum CodingKeys: String, CodingKey {
        case name, shape, parent, position, rotation, size, segments, thickness, color, opacity, texture, textureScale, worldUV,
             metallic, roughness, glow, glowStrength, material, bevel, profile, mirror
        case repetition = "repeat"
        // Sculpt fields (MeshBuildSculpt.swift).
        case blend, smooth, resolution, noise
        // Curves and deformers.
        case path, radius, radii, closed, straight, sections, axis, deform, subdivide
        // Looks.
        case look, lookScale, wear, grain
        // Foliage and ribbons.
        case cardSize, count, density, seed, on, along, open, ribbon
        // Fur and hair (GroomBuild.swift).
        case groom
        // Physics (MeshBuildPhysicsMaterials.swift).
        case physicsMaterial
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MeshBuildPart()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  shape: try c.decodeIfPresent(MeshBuildShape.self, forKey: .shape) ?? d.shape,
                  parent: try c.decodeIfPresent(String.self, forKey: .parent) ?? d.parent,
                  position: try c.decodeIfPresent(Vec3.self, forKey: .position) ?? d.position,
                  rotation: try c.decodeIfPresent(Vec3.self, forKey: .rotation) ?? d.rotation,
                  size: try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size,
                  segments: try c.decodeIfPresent(Int.self, forKey: .segments) ?? d.segments,
                  thickness: try c.decodeIfPresent(Float.self, forKey: .thickness) ?? d.thickness,
                  color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  opacity: try c.decodeIfPresent(Float.self, forKey: .opacity) ?? d.opacity,
                  texture: try c.decodeIfPresent(String.self, forKey: .texture) ?? d.texture,
                  textureScale: try c.decodeIfPresent(Vec2.self, forKey: .textureScale) ?? d.textureScale,
                  worldUV: try c.decodeIfPresent(Bool.self, forKey: .worldUV) ?? d.worldUV,
                  metallic: try c.decodeIfPresent(Float.self, forKey: .metallic) ?? d.metallic,
                  roughness: try c.decodeIfPresent(Float.self, forKey: .roughness) ?? d.roughness,
                  glow: try c.decodeIfPresent(Vec3.self, forKey: .glow) ?? d.glow,
                  glowStrength: try c.decodeIfPresent(Float.self, forKey: .glowStrength) ?? d.glowStrength,
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material,
                  bevel: try c.decodeIfPresent(Float.self, forKey: .bevel),
                  profile: try c.decodeIfPresent([Vec2].self, forKey: .profile),
                  mirror: try c.decodeIfPresent(MeshBuildMirror.self, forKey: .mirror),
                  repetition: try c.decodeIfPresent(MeshBuildRepeat.self, forKey: .repetition),
                  // Curves and deformers (a single deform object is taken as a list of one).
                  path: try c.decodeIfPresent([Vec3].self, forKey: .path),
                  radius: try? c.decodeIfPresent(Float.self, forKey: .radius),
                  radii: try c.decodeIfPresent([Float].self, forKey: .radii),
                  closed: try? c.decodeIfPresent(Bool.self, forKey: .closed),
                  straight: try? c.decodeIfPresent(Bool.self, forKey: .straight),
                  sections: try c.decodeIfPresent([MeshBuildSection].self, forKey: .sections),
                  axis: try? c.decodeIfPresent(MeshBuildAxis.self, forKey: .axis),
                  deform: (try? c.decodeIfPresent([MeshBuildDeform].self, forKey: .deform))
                      ?? (try? c.decodeIfPresent(MeshBuildDeform.self, forKey: .deform)).flatMap { $0.map { [$0] } },
                  subdivide: try? c.decodeIfPresent(Int.self, forKey: .subdivide),
                  // Looks: lenient, a value of the wrong type reads as unset.
                  look: (try? c.decodeIfPresent(String.self, forKey: .look)) ?? nil,
                  lookScale: (try? c.decodeIfPresent(Float.self, forKey: .lookScale)) ?? nil,
                  wear: (try? c.decodeIfPresent(Float.self, forKey: .wear)) ?? nil,
                  grain: (try? c.decodeIfPresent(MeshBuildAxis.self, forKey: .grain)) ?? nil)
        // Sculpt fields (MeshBuildSculpt.swift).
        blend = try c.decodeIfPresent(MeshBuildBlend.self, forKey: .blend)
        smooth = try c.decodeIfPresent(Float.self, forKey: .smooth)
        resolution = try c.decodeIfPresent(Int.self, forKey: .resolution)
        noise = try c.decodeIfPresent(MeshBuildNoise.self, forKey: .noise)
        // Foliage and ribbons: lenient; `on` is a name or a list of names.
        cardSize = (try? c.decodeIfPresent(Float.self, forKey: .cardSize)) ?? nil
        count = (try? c.decodeIfPresent(Int.self, forKey: .count)) ?? nil
        density = (try? c.decodeIfPresent(Float.self, forKey: .density)) ?? nil
        seed = (try? c.decodeIfPresent(Int.self, forKey: .seed)) ?? nil
        on = (try? c.decodeIfPresent([String].self, forKey: .on)) ?? (try? c.decodeIfPresent(String.self, forKey: .on)).flatMap { $0.map { [$0] } }
        along = (try? c.decodeIfPresent(Vec2.self, forKey: .along)) ?? nil
        open = (try? c.decodeIfPresent(Bool.self, forKey: .open)) ?? nil
        ribbon = (try? c.decodeIfPresent(Float.self, forKey: .ribbon)) ?? nil
        groom = (try? c.decodeIfPresent(String.self, forKey: .groom)) ?? nil
        physicsMaterial = (try? c.decodeIfPresent(String.self, forKey: .physicsMaterial)) ?? nil
    }

    /// The part's local transform (its size is in the mesh, not the scale).
    public var transform: Transform {
        Transform(position: position, rotation: Quat(eulerDegrees: rotation))
    }
}

/// What a `MeshBuildTrack` moves. Values are relative to the part's rest pose, so a part keeps
/// wherever it was placed: `position` is an offset in meters (parent space), `rotation` degrees
/// added about the part's own axes, `scale` a multiplier (1 is unchanged).
public enum MeshBuildProperty: String, Codable, CaseIterable, Sendable {
    case position, rotation, scale
}

/// A keyframe: `value` at `time` seconds.
public struct MeshBuildKey: Codable, Equatable, Sendable {
    public var time: Float
    public var value: Vec3

    public init(_ time: Float, _ value: Vec3) {
        self.time = time
        self.value = value
    }

    private enum CodingKeys: String, CodingKey { case time, value }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try c.decodeIfPresent(Float.self, forKey: .time) ?? 0, try c.decodeIfPresent(Vec3.self, forKey: .value) ?? .zero)
    }
}

/// Keyframes of one property of one part. The track loops (or plays once, or ping-pongs, per
/// its animation) over its own keys; give tracks that must stay in step the same last key time.
/// A track whose first key is after 0 holds that key's value until then.
public struct MeshBuildTrack: Codable, Equatable, Sendable {
    public var part: String
    public var property: MeshBuildProperty
    /// `linear`, `hermite` (smooth) or `step`.
    public var interpolation: KeyInterpolation
    public var keys: [MeshBuildKey]

    public init(part: String = "", property: MeshBuildProperty = .position, interpolation: KeyInterpolation = .linear,
                keys: [MeshBuildKey] = []) {
        self.part = part
        self.property = property
        self.interpolation = interpolation
        self.keys = keys
    }

    private enum CodingKeys: String, CodingKey { case part, property, interpolation, keys }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(part: try c.decodeIfPresent(String.self, forKey: .part) ?? "",
                  property: try c.decodeIfPresent(MeshBuildProperty.self, forKey: .property) ?? .position,
                  interpolation: try c.decodeIfPresent(KeyInterpolation.self, forKey: .interpolation) ?? .linear,
                  keys: try c.decodeIfPresent([MeshBuildKey].self, forKey: .keys) ?? [])
    }
}

/// An axis of a part.
public enum MeshBuildAxis: String, Codable, CaseIterable, Sendable {
    case x, y, z

    public var index: Int { self == .x ? 0 : self == .y ? 1 : 2 }
    public var unit: Vec3 { var v = Vec3.zero; v[index] = 1; return v }
}

/// A ready-made motion, expanded into a `MeshBuildTrack` (`track`), so common animations need no keys.
public struct MeshBuildMotion: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        /// Turns `amount` full turns about `axis` every `period` (negative: the other way).
        case spin
        /// Moves up to `amount` meters along `axis` and back.
        case bob
        /// Rocks `amount` degrees each way about `axis`.
        case swing
        /// Grows to 1 + `amount` times its size and back.
        case pulse
        /// Shakes `amount` meters along `axis`, quickly.
        case shake
    }

    public var part: String
    public var kind: Kind
    public var axis: MeshBuildAxis
    /// Default per kind: spin 1 turn, bob 0.25 m, swing 30°, pulse 0.15, shake 0.05 m.
    public var amount: Float?
    /// Seconds per cycle (default 2; shake 0.2).
    public var period: Float?

    public init(part: String = "", kind: Kind = .spin, axis: MeshBuildAxis = .y, amount: Float? = nil, period: Float? = nil) {
        self.part = part
        self.kind = kind
        self.axis = axis
        self.amount = amount
        self.period = period
    }

    private enum CodingKeys: String, CodingKey { case part, kind, axis, amount, period }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(part: try c.decodeIfPresent(String.self, forKey: .part) ?? "",
                  kind: try c.decodeIfPresent(Kind.self, forKey: .kind) ?? .spin,
                  axis: try c.decodeIfPresent(MeshBuildAxis.self, forKey: .axis) ?? .y,
                  amount: try c.decodeIfPresent(Float.self, forKey: .amount),
                  period: try c.decodeIfPresent(Float.self, forKey: .period))
    }

    /// The motion as keyframes.
    public var track: MeshBuildTrack {
        let p = max(period ?? (kind == .shake ? 0.2 : 2), 0.01)
        let axis = axis.unit
        switch kind {
        case .spin:
            let turns = amount ?? 1
            return MeshBuildTrack(part: part, property: .rotation, interpolation: .linear,
                                  keys: [MeshBuildKey(0, .zero), MeshBuildKey(p, axis * (360 * turns))])
        case .bob:
            let a = amount ?? 0.25
            return MeshBuildTrack(part: part, property: .position, interpolation: .hermite,
                                  keys: [MeshBuildKey(0, .zero), MeshBuildKey(p / 2, axis * a), MeshBuildKey(p, .zero)])
        case .swing:
            let a = amount ?? 30
            return MeshBuildTrack(part: part, property: .rotation, interpolation: .hermite,
                                  keys: [MeshBuildKey(0, .zero), MeshBuildKey(p / 4, axis * a), MeshBuildKey(p * 3 / 4, axis * -a),
                                         MeshBuildKey(p, .zero)])
        case .pulse:
            let a = amount ?? 0.15
            return MeshBuildTrack(part: part, property: .scale, interpolation: .hermite,
                                  keys: [MeshBuildKey(0, Vec3(1, 1, 1)), MeshBuildKey(p / 2, Vec3(repeating: 1 + a)),
                                         MeshBuildKey(p, Vec3(1, 1, 1))])
        case .shake:
            let a = amount ?? 0.05
            return MeshBuildTrack(part: part, property: .position, interpolation: .linear,
                                  keys: [MeshBuildKey(0, .zero), MeshBuildKey(p * 0.25, axis * a), MeshBuildKey(p * 0.5, .zero),
                                         MeshBuildKey(p * 0.75, axis * -a), MeshBuildKey(p, .zero)])
        }
    }
}

/// A named set of tracks (keyframed and ready-made motions). Every animation with `autoplay`
/// plays at once, from the start of play mode or the game, so animations can be layered (a
/// wheel spin plus a body bob); turn `autoplay` off to keep one in the file without playing it.
public struct MeshBuildAnimation: Codable, Equatable, Sendable {
    public var name: String
    public var autoplay: Bool
    /// `loop` (default), `once` (holds the last key) or `pingPong`.
    public var loop: AnimationLoop
    /// Multiplies playback speed.
    public var speed: Float
    public var tracks: [MeshBuildTrack]
    public var motions: [MeshBuildMotion]

    public init(name: String = "Animation", autoplay: Bool = true, loop: AnimationLoop = .loop, speed: Float = 1,
                tracks: [MeshBuildTrack] = [], motions: [MeshBuildMotion] = []) {
        self.name = name
        self.autoplay = autoplay
        self.loop = loop
        self.speed = speed
        self.tracks = tracks
        self.motions = motions
    }

    private enum CodingKeys: String, CodingKey { case name, autoplay, loop, speed, tracks, motions }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "Animation",
                  autoplay: try c.decodeIfPresent(Bool.self, forKey: .autoplay) ?? true,
                  loop: try c.decodeIfPresent(AnimationLoop.self, forKey: .loop) ?? .loop,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? 1,
                  tracks: try c.decodeIfPresent([MeshBuildTrack].self, forKey: .tracks) ?? [],
                  motions: try c.decodeIfPresent([MeshBuildMotion].self, forKey: .motions) ?? [])
    }

    /// Keyframed tracks followed by the motions' tracks.
    public var allTracks: [MeshBuildTrack] { tracks + motions.map(\.track) }
}

/// The contents of a `.meshbuild` file. See the notes at the top of this file.
public struct MeshBuild: Codable, Equatable, Sendable {
    public var parts: [MeshBuildPart]
    public var animations: [MeshBuildAnimation]
    /// Baked ambient occlusion: parts darken where they meet (MeshBuildAO.swift). nil is off:
    /// baking tessellates every mesh first (to about 30k triangles a model), too heavy for simple
    /// pieces such as GridMap tiles.
    public var ao: Bool?
    /// Detail levels and an impostor (MeshBuildLOD.swift). nil: on for builds with foliage.
    public var lod: Bool?
    /// Meters where levels 1, 2 and the impostor take over (nil: from the model's size).
    public var lodDistances: [Float]?
    /// How much a plant sways in the scene's wind (1 by default for builds with foliage, 0: still).
    public var wind: Float?

    public init(parts: [MeshBuildPart] = [], animations: [MeshBuildAnimation] = [], ao: Bool? = nil, lod: Bool? = nil,
                lodDistances: [Float]? = nil, wind: Float? = nil) {
        self.parts = parts
        self.animations = animations
        self.ao = ao
        self.lod = lod
        self.lodDistances = lodDistances
        self.wind = wind
    }

    private enum CodingKeys: String, CodingKey { case parts, animations, ao, lod, lodDistances, wind }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(parts: try c.decodeIfPresent([MeshBuildPart].self, forKey: .parts) ?? [],
                  animations: try c.decodeIfPresent([MeshBuildAnimation].self, forKey: .animations) ?? [],
                  ao: (try? c.decodeIfPresent(Bool.self, forKey: .ao)) ?? nil,
                  lod: (try? c.decodeIfPresent(Bool.self, forKey: .lod)) ?? nil,
                  lodDistances: (try? c.decodeIfPresent([Float].self, forKey: .lodDistances)) ?? nil,
                  wind: (try? c.decodeIfPresent(Float.self, forKey: .wind)) ?? nil)
    }

    /// A one-part starting point: a light gray unit cube resting on the ground.
    public static var starter: MeshBuild {
        MeshBuild(parts: [MeshBuildPart(name: "Base", position: Vec3(0, 0.5, 0))])
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// Renames a part and every reference to it (children's `parent`, tracks, motions).
    public mutating func renamePart(_ old: String, to new: String) {
        guard old != new else { return }
        for i in parts.indices {
            if parts[i].name == old { parts[i].name = new }
            if parts[i].parent == old { parts[i].parent = new }
        }
        for a in animations.indices {
            for t in animations[a].tracks.indices where animations[a].tracks[t].part == old { animations[a].tracks[t].part = new }
            for m in animations[a].motions.indices where animations[a].motions[m].part == old { animations[a].motions[m].part = new }
        }
    }

    /// Removes the named parts and their animation tracks; their children move up to the removed
    /// part's parent (keeping their local placement).
    public mutating func removeParts(_ names: Set<String>) {
        var parentOf: [String: String] = [:]
        for part in parts where names.contains(part.name) { parentOf[part.name] = part.parent }
        func survivingParent(_ name: String) -> String {
            var name = name, steps = 0
            while let up = parentOf[name], steps < parts.count { name = up; steps += 1 }
            return parentOf[name] == nil && !names.contains(name) ? name : ""
        }
        parts.removeAll { names.contains($0.name) }
        for i in parts.indices where names.contains(parts[i].parent) { parts[i].parent = survivingParent(parts[i].parent) }
        for a in animations.indices {
            animations[a].tracks.removeAll { names.contains($0.part) }
            animations[a].motions.removeAll { names.contains($0.part) }
        }
    }

    /// The `FieldAnimator` tracks that play the `autoplay` animations on the part named `part`
    /// (empty: it doesn't move). Each keyframe track becomes one additive curve per axis that
    /// moves; scale keys become offsets from 1.
    public func animatorTracks(for part: String) -> [AnimationTrack] {
        var result: [AnimationTrack] = []
        for animation in animations where animation.autoplay {
            let wrap: CurveWrap = animation.loop == .loop ? .loop : animation.loop == .pingPong ? .pingPong : .clamp
            for track in animation.allTracks where track.part == part && !track.keys.isEmpty {
                var keys = track.keys.sorted { $0.time < $1.time }
                if keys[0].time > 0 { keys.insert(MeshBuildKey(0, keys[0].value), at: 0) }
                let rest: Float = track.property == .scale ? 1 : 0
                for axis in 0..<3 where keys.contains(where: { $0.value[axis] != rest }) {
                    let curve = AnimationCurve<Float>(
                        keys: keys.map { Keyframe(max($0.time, 0), $0.value[axis] - rest, interpolation: track.interpolation) },
                        wrap: wrap)
                    let target = "Transform.\(track.property.rawValue).\(["x", "y", "z"][axis])"
                    result.append(AnimationTrack(target: target, mode: .curve, additive: true, curve: curve,
                                                 speed: animation.speed))
                }
            }
        }
        return result
    }
}

/// sRGB to linear conversion for display colors.
package enum MeshBuildColor {
    /// The linear value of a display (sRGB) color, per channel.
    package static func linear(fromSRGB c: Vec3) -> Vec3 {
        func f(_ x: Float) -> Float {
            let x = min(max(x, 0), 1)
            return x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4)
        }
        return Vec3(f(c.x), f(c.y), f(c.z))
    }
}
