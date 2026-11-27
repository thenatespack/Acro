#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

// Fur and hair: the contents of a `.groom` file (JSON, every key optional). `GroomImporter`
// turns it into a fur material (`material/fur`, a `MaterialAsset` whose `fur` holds the groom)
// and a preview prefab (the groom on a sphere). A `GroomRenderer` next to a `MeshRenderer` grows
// the fur on that mesh at run time (Groom.swift, GroomGeometry.swift), so one groom dresses any
// mesh, character region or Mesh Builder part.
//
// ```json
// {
//   "style": "shell",
//   "length": 0.04, "density": 40, "thickness": [0.8, 0.15],
//   "clumping": 0.3, "curl": 0, "frizz": 0.1, "gravity": 0.4, "stiffness": 0.4,
//   "rootColor": [0.25, 0.16, 0.1], "tipColor": [0.75, 0.6, 0.42], "colorNoise": 0.2,
//   "combDirection": "followSurface", "combStrength": 0.5,
//   "mask": {"parts": ["Body", "Tail"]},
//   "comb": [{"center": [0, 0.5, 0.3], "radius": 0.2, "direction": [0, -1, 0], "strength": 1}],
//   "cut": [{"center": [0, 0.2, 0.5], "radius": 0.1, "length": 0}],
//   "wind": 1,
//   "lod": {"shells": [24, 12, 6], "distances": [4, 10, 25]}
// }
// ```
//
// Shell fur (`shell`): the mesh drawn again `shells` times, each copy pushed out along the
// normals by a fraction of `length` and cut to strands by noise in the fragment shader. Hair
// cards (`cards`): ribbon strips grown along guide curves from the surface, each drawing
// `strandsPerCard` strands. Both draw an opaque fur-colored "undercoat" shell just above the
// surface, which is all that is left past the last detail level.
//
// Distances are meters in the mesh's own space; `density` is strands (shells) or cards per square
// centimeter. Colors are display (sRGB) values 0...1. Edits an agent writes: `comb` strokes turn
// strands toward a direction inside a sphere, `cut` strokes set the length (0 removes fur, 1
// restores it) inside a sphere; strokes apply in order.

/// How fur is drawn.
public enum GroomStyle: String, Codable, CaseIterable, Sendable {
    /// Short fur, moss, velvet: instanced shells.
    case shell
    /// Longer hair, manes, feathers: ribbon cards along guide curves.
    case cards
    /// Reserved for strand rendering; draws as cards for now (with a warning).
    case strands
}

/// Where strands point before gravity and wind: straight out, combed toward a direction, or lying along the surface.
public enum GroomDirection: Equatable, Sendable, Codable {
    /// Straight out along the normal.
    case normal
    /// Lying along the surface, flowing down (the mesh's -Y projected onto the surface; backward, -Z, near the top).
    case followSurface
    /// Combed toward this direction in the mesh's space (projected onto the surface).
    case vector(Vec3)

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let text = try? c.decode(String.self) {
            switch text.lowercased() {
            case "followsurface", "surface": self = .followSurface
            default: self = .normal
            }
        } else {
            self = .vector(try c.decode(Vec3.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .normal: try c.encode("normal")
        case .followSurface: try c.encode("followSurface")
        case .vector(let v): try c.encode(v)
        }
    }
}

/// Where fur grows and how long it is there (all multiply; an empty mask grows fur everywhere).
public struct GroomMask: Codable, Equatable, Sendable {
    /// An image (path under `Assets/` or "asset:<id>"): its red channel scales the length (black: bald).
    public var texture: String
    /// A vertex paint channel ("r", "g", "b" or "a" of the mesh's `VertexPaint` color) that scales the length ("" off).
    public var vertexPaint: String
    /// Mesh Builder part names (or entity names) the fur grows on; empty: every part.
    public var parts: [String]
    /// Swaps grown and bald (for the texture and vertex paint).
    public var invert: Bool

    public init(texture: String = "", vertexPaint: String = "", parts: [String] = [], invert: Bool = false) {
        self.texture = texture
        self.vertexPaint = vertexPaint
        self.parts = parts
        self.invert = invert
    }

    private enum CodingKeys: String, CodingKey { case texture, vertexPaint, parts, invert }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(texture: try c.decodeIfPresent(String.self, forKey: .texture) ?? "",
                  vertexPaint: try c.decodeIfPresent(String.self, forKey: .vertexPaint) ?? "",
                  parts: (try? c.decodeIfPresent([String].self, forKey: .parts)) ?? (try? c.decodeIfPresent(String.self, forKey: .parts)).flatMap { $0.map { [$0] } } ?? [],
                  invert: try c.decodeIfPresent(Bool.self, forKey: .invert) ?? false)
    }

    public var isEmpty: Bool { texture.isEmpty && vertexPaint.isEmpty && parts.isEmpty }
}

/// A comb stroke: inside the sphere, strands turn toward `direction` (mesh space) by `strength`,
/// fading out toward the rim.
public struct GroomComb: Codable, Equatable, Sendable {
    public var center: Vec3
    public var radius: Float
    public var direction: Vec3
    public var strength: Float

    public init(center: Vec3 = .zero, radius: Float = 0.1, direction: Vec3 = Vec3(0, -1, 0), strength: Float = 1) {
        self.center = center
        self.radius = radius
        self.direction = direction
        self.strength = strength
    }

    private enum CodingKeys: String, CodingKey { case center, radius, direction, strength }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomComb()
        self.init(center: try c.decodeIfPresent(Vec3.self, forKey: .center) ?? d.center,
                  radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius,
                  direction: try c.decodeIfPresent(Vec3.self, forKey: .direction) ?? d.direction,
                  strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength)
    }
}

/// A cut (or length) stroke: inside the sphere, the length factor moves toward `length` (0 bald,
/// 1 full, up to 2 longer) by `strength`, fading out toward the rim.
public struct GroomCut: Codable, Equatable, Sendable {
    public var center: Vec3
    public var radius: Float
    public var length: Float
    public var strength: Float

    public init(center: Vec3 = .zero, radius: Float = 0.1, length: Float = 0, strength: Float = 1) {
        self.center = center
        self.radius = radius
        self.length = length
        self.strength = strength
    }

    private enum CodingKeys: String, CodingKey { case center, radius, length, strength }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomCut()
        self.init(center: try c.decodeIfPresent(Vec3.self, forKey: .center) ?? d.center,
                  radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius,
                  length: try c.decodeIfPresent(Float.self, forKey: .length) ?? d.length,
                  strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength)
    }
}

/// Detail levels: fewer shells (or cards) farther away, then only the fur-colored undercoat.
public struct GroomLOD: Codable, Equatable, Sendable {
    /// Shells drawn at each level (shell style); level 0 defaults to the file's `shells`.
    public var shells: [Int]
    /// The fraction of cards drawn at each level (cards style).
    public var cards: [Float]
    /// Meters from the camera where each level after the first starts; past the last one only
    /// the undercoat (a fur-tinted surface) is drawn.
    public var distances: [Float]

    public init(shells: [Int] = [], cards: [Float] = [1, 0.5, 0.25], distances: [Float] = [6, 14, 30]) {
        self.shells = shells
        self.cards = cards
        self.distances = distances
    }

    private enum CodingKeys: String, CodingKey { case shells, cards, distances }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomLOD()
        self.init(shells: try c.decodeIfPresent([Int].self, forKey: .shells) ?? d.shells,
                  cards: try c.decodeIfPresent([Float].self, forKey: .cards) ?? d.cards,
                  distances: try c.decodeIfPresent([Float].self, forKey: .distances) ?? d.distances)
    }
}

/// A hair part: strands comb away from a line over the top of the head (`center`, `side` at
/// `offset`, or a `curve` of points in the mesh's space), ending at the crown, behind which hair
/// flows down from the crown point.
public enum GroomPartStyle: String, Codable, CaseIterable, Sendable { case none, center, side, curve }

/// Where hair parts (see `GroomPartStyle`). Positions other than `points` are in the hair's bounds
/// (the furry area's bounding box: -1 left/bottom/back, 1 right/top/front; the face toward +Z).
public struct GroomPart: Codable, Equatable, Sendable {
    public var style: GroomPartStyle
    /// Across the head (bounds x, -1...1); a `side` part with 0 sits at 0.4.
    public var offset: Float
    /// Where the part ends toward the back (bounds z; -1 the back, 1 the front).
    public var crown: Float
    /// The part line for `curve` (mesh space, front to back).
    public var points: [Vec3]
    /// 0...1: how much the part wins over `combDirection`.
    public var strength: Float
    /// Meters of bare scalp along the line.
    public var width: Float

    public init(style: GroomPartStyle = .none, offset: Float = 0, crown: Float = -0.3, points: [Vec3] = [], strength: Float = 1, width: Float = 0.004) {
        self.style = style
        self.offset = offset
        self.crown = crown
        self.points = points
        self.strength = strength
        self.width = width
    }

    private enum CodingKeys: String, CodingKey { case style, offset, crown, points, strength, width }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomPart()
        self.init(style: try c.decodeIfPresent(GroomPartStyle.self, forKey: .style) ?? d.style,
                  offset: try c.decodeIfPresent(Float.self, forKey: .offset) ?? d.offset,
                  crown: try c.decodeIfPresent(Float.self, forKey: .crown) ?? d.crown,
                  points: try c.decodeIfPresent([Vec3].self, forKey: .points) ?? d.points,
                  strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength,
                  width: try c.decodeIfPresent(Float.self, forKey: .width) ?? d.width)
    }

    public var isActive: Bool { style != .none && (style != .curve || !points.isEmpty) && strength > 0 }
}

/// Bangs: hair at the front of the head combed forward and down over the forehead, `length` long.
public struct GroomFringe: Codable, Equatable, Sendable {
    /// 0...1: how much of the front hairline is fringe (0: none).
    public var amount: Float
    /// The fringe's strand length in meters.
    public var length: Float
    /// -1...1: sweeps the fringe toward -X or +X.
    public var sweep: Float

    public init(amount: Float = 0, length: Float = 0.08, sweep: Float = 0) {
        self.amount = amount
        self.length = length
        self.sweep = sweep
    }

    private enum CodingKeys: String, CodingKey { case amount, length, sweep }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomFringe()
        self.init(amount: try c.decodeIfPresent(Float.self, forKey: .amount) ?? d.amount,
                  length: try c.decodeIfPresent(Float.self, forKey: .length) ?? d.length,
                  sweep: try c.decodeIfPresent(Float.self, forKey: .sweep) ?? d.sweep)
    }
}

/// Length multipliers by where the root is on the head (blended by direction from the hair's center).
public struct GroomLengthProfile: Codable, Equatable, Sendable {
    public var front: Float
    public var back: Float
    public var top: Float
    public var sides: Float

    public init(front: Float = 1, back: Float = 1, top: Float = 1, sides: Float = 1) {
        self.front = front
        self.back = back
        self.top = top
        self.sides = sides
    }

    private enum CodingKeys: String, CodingKey { case front, back, top, sides }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(front: try c.decodeIfPresent(Float.self, forKey: .front) ?? 1, back: try c.decodeIfPresent(Float.self, forKey: .back) ?? 1,
                  top: try c.decodeIfPresent(Float.self, forKey: .top) ?? 1, sides: try c.decodeIfPresent(Float.self, forKey: .sides) ?? 1)
    }

    public var isFlat: Bool { front == 1 && back == 1 && top == 1 && sides == 1 }
}

/// A blunt cut: strand tips end at a height (bounds y, -1 the bottom of the hair area, 1 its top),
/// `back` at the back of the head blending to `front` at the face (a bob, an A-line).
public struct GroomHemline: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var back: Float
    public var front: Float
    /// Random raggedness of the edge, in bounds units.
    public var softness: Float

    public init(enabled: Bool = false, back: Float = -1.5, front: Float = -1.5, softness: Float = 0.08) {
        self.enabled = enabled
        self.back = back
        self.front = front
        self.softness = softness
    }

    private enum CodingKeys: String, CodingKey { case enabled, back, front, softness }

    /// Present in a file means on, unless it says `"enabled": false`.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomHemline()
        self.init(enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true, back: try c.decodeIfPresent(Float.self, forKey: .back) ?? d.back,
                  front: try c.decodeIfPresent(Float.self, forKey: .front) ?? d.front,
                  softness: try c.decodeIfPresent(Float.self, forKey: .softness) ?? d.softness)
    }
}

/// A ponytail (or bun) tie: strands run along the scalp to `point` (bounds space) and hang from
/// it as a tail `tail` meters long.
public struct GroomTie: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var point: Vec3
    /// The tail's length in meters below the tie.
    public var tail: Float
    /// Meters: the tie's radius (how thick the gathered tail is).
    public var radius: Float

    public init(enabled: Bool = false, point: Vec3 = Vec3(0, 0.1, -1.05), tail: Float = 0.25, radius: Float = 0.015) {
        self.enabled = enabled
        self.point = point
        self.tail = tail
        self.radius = radius
    }

    private enum CodingKeys: String, CodingKey { case enabled, point, tail, radius }

    /// Present in a file means on, unless it says `"enabled": false`.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomTie()
        self.init(enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true, point: try c.decodeIfPresent(Vec3.self, forKey: .point) ?? d.point,
                  tail: try c.decodeIfPresent(Float.self, forKey: .tail) ?? d.tail, radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius)
    }
}

/// A shape card hair stays outside of (mesh space): a sphere (`radius`), an ellipsoid (`radii`)
/// or a capsule from `center` to `end` (`radius`). For a scalp that doesn't cover the whole head,
/// add the head, neck and shoulders.
public struct GroomCollider: Codable, Equatable, Sendable {
    public var center: Vec3
    public var radius: Float
    /// Ellipsoid radii (overrides `radius` when set).
    public var radii: Vec3?
    /// A capsule's other end.
    public var end: Vec3?

    public init(center: Vec3 = .zero, radius: Float = 0.1, radii: Vec3? = nil, end: Vec3? = nil) {
        self.center = center
        self.radius = radius
        self.radii = radii
        self.end = end
    }

    private enum CodingKeys: String, CodingKey { case center, radius, radii, end }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(center: try c.decodeIfPresent(Vec3.self, forKey: .center) ?? .zero, radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? 0.1,
                  radii: try c.decodeIfPresent(Vec3.self, forKey: .radii), end: try c.decodeIfPresent(Vec3.self, forKey: .end))
    }
}

/// Where card roots go: evenly spaced (blue noise) or purely random.
public enum GroomRootPlacement: String, Codable, CaseIterable, Sendable { case even, random }

/// A groom: the contents of a `.groom` file. See the notes at the top of this file.
public struct GroomBuild: Codable, Equatable, Sendable {
    public var style: GroomStyle
    /// Strand length in meters.
    public var length: Float
    /// 0...1: how much shorter random strands are (0: all full length).
    public var lengthVariation: Float
    /// Strands (shell) or cards (cards) per square centimeter.
    public var density: Float
    /// Strand thickness at the root and the tip, 0...1 of the strand spacing.
    public var thickness: Vec2
    /// 0...1: strands gather into pointed clumps toward their tips.
    public var clumping: Float
    /// 0...1: strands spiral (curly fur, ringlets).
    public var curl: Float
    /// 0...1: random wobble along each strand.
    public var frizz: Float
    /// 0...1: how much strands droop.
    public var gravity: Float
    /// 0...1: resists gravity, wind and motion.
    public var stiffness: Float
    public var rootColor: Vec3
    public var tipColor: Vec3
    /// 0...1: per-strand brightness variation.
    public var colorNoise: Float
    /// 0...1: the strength of the anisotropic highlights.
    public var specular: Float
    public var mask: GroomMask
    public var combDirection: GroomDirection
    /// 0...1: how far strands lean toward `combDirection` (1: lying on the surface).
    public var combStrength: Float
    /// An image (path or "asset:<id>"): its red and green channels give a direction in UV space
    /// (0.5 none) that strands are combed toward, over `combDirection`.
    public var flowTexture: String
    /// Scales `SceneEnvironment.wind` on the fur (0: still).
    public var wind: Float
    /// Shells at full detail (shell style; 2...64).
    public var shells: Int
    /// A card's width in meters (cards style).
    public var cardWidth: Float
    /// Segments along each card (2...16).
    public var cardSegments: Int
    /// Strands drawn across each card (1...32).
    public var strandsPerCard: Int
    public var lod: GroomLOD
    public var comb: [GroomComb]
    public var cut: [GroomCut]
    public var seed: Int
    /// What the Groom Builder tab and `groom.preview` grow the fur on when no target is open:
    /// "sphere", "cube", "capsule", "plane" or a `.meshbuild` path.
    public var previewMesh: String

    // Hair styling (cards; GroomGeometry.swift). Positions in parts, hemlines and ties are in the
    // hair's bounds (-1...1 over the furry area's box), so presets fit any head.
    /// Where the hair parts.
    public var part: GroomPart
    /// 0...1: how far along each strand (a fraction of its length) it lies on the scalp before it falls.
    public var scalpHug: Float
    /// 0...1: how far hair stands off the scalp where it lies on it (0 flat, 1 big hair).
    public var volume: Float
    /// Keep cards out of the mesh they grow on and out of `colliders`.
    public var collide: Bool
    public var colliders: [GroomCollider]
    public var rootPlacement: GroomRootPlacement
    /// Meters inside the hair's edge (bald areas and open mesh edges) where cards thin out and shorten.
    public var hairlineWidth: Float
    /// 0...1: the fraction of cards in a short inner layer lying flat on the scalp (hides it).
    public var innerLayer: Float
    /// 0...1: the fraction of stray, frizzy, lifted cards.
    public var flyaways: Float
    /// Cards per clump (2...64).
    public var clumpSize: Int
    /// 0...1: how much narrower cards are at their tips.
    public var cardTaper: Float
    /// 0...1: flat waves along each strand (curl makes spirals).
    public var wave: Float
    /// Turns of curl (and waves) along a strand.
    public var curlFrequency: Float
    /// Length multipliers at the front, back, top and sides of the head.
    public var lengthProfile: GroomLengthProfile
    /// A blunt cut line (bob).
    public var hemline: GroomHemline
    public var fringe: GroomFringe
    /// A ponytail tie.
    public var tie: GroomTie
    /// 0...1: hair at the front is combed back and to the sides, away from the face (not the fringe).
    public var sweepBack: Float

    public init(style: GroomStyle = .shell, length: Float = 0.03, lengthVariation: Float = 0.3, density: Float = 40,
                thickness: Vec2 = Vec2(0.8, 0.15), clumping: Float = 0.2, curl: Float = 0, frizz: Float = 0.1, gravity: Float = 0.3,
                stiffness: Float = 0.5, rootColor: Vec3 = Vec3(0.28, 0.18, 0.11), tipColor: Vec3 = Vec3(0.72, 0.56, 0.38),
                colorNoise: Float = 0.2, specular: Float = 0.5, mask: GroomMask = GroomMask(), combDirection: GroomDirection = .normal,
                combStrength: Float = 0.5, flowTexture: String = "", wind: Float = 1, shells: Int = 24, cardWidth: Float = 0.012,
                cardSegments: Int = 6, strandsPerCard: Int = 8, lod: GroomLOD = GroomLOD(), comb: [GroomComb] = [], cut: [GroomCut] = [],
                seed: Int = 1, previewMesh: String = "sphere", part: GroomPart = GroomPart(), scalpHug: Float = 0, volume: Float = 0.3,
                collide: Bool = true, colliders: [GroomCollider] = [], rootPlacement: GroomRootPlacement = .even, hairlineWidth: Float = 0,
                innerLayer: Float = 0, flyaways: Float = 0, clumpSize: Int = 8, cardTaper: Float = 0.45, wave: Float = 0,
                curlFrequency: Float = 2, lengthProfile: GroomLengthProfile = GroomLengthProfile(), hemline: GroomHemline = GroomHemline(),
                fringe: GroomFringe = GroomFringe(), tie: GroomTie = GroomTie(), sweepBack: Float = 0) {
        self.style = style
        self.length = length
        self.lengthVariation = lengthVariation
        self.density = density
        self.thickness = thickness
        self.clumping = clumping
        self.curl = curl
        self.frizz = frizz
        self.gravity = gravity
        self.stiffness = stiffness
        self.rootColor = rootColor
        self.tipColor = tipColor
        self.colorNoise = colorNoise
        self.specular = specular
        self.mask = mask
        self.combDirection = combDirection
        self.combStrength = combStrength
        self.flowTexture = flowTexture
        self.wind = wind
        self.shells = shells
        self.cardWidth = cardWidth
        self.cardSegments = cardSegments
        self.strandsPerCard = strandsPerCard
        self.lod = lod
        self.comb = comb
        self.cut = cut
        self.seed = seed
        self.previewMesh = previewMesh
        self.part = part
        self.scalpHug = scalpHug
        self.volume = volume
        self.collide = collide
        self.colliders = colliders
        self.rootPlacement = rootPlacement
        self.hairlineWidth = hairlineWidth
        self.innerLayer = innerLayer
        self.flyaways = flyaways
        self.clumpSize = clumpSize
        self.cardTaper = cardTaper
        self.wave = wave
        self.curlFrequency = curlFrequency
        self.lengthProfile = lengthProfile
        self.hemline = hemline
        self.fringe = fringe
        self.tie = tie
        self.sweepBack = sweepBack
    }

    private enum CodingKeys: String, CodingKey {
        case style, length, lengthVariation, density, thickness, clumping, curl, frizz, gravity, stiffness, rootColor, tipColor
        case colorNoise, specular, mask, combDirection, combStrength, flowTexture, wind, shells, cardWidth, cardSegments
        case strandsPerCard, lod, comb, cut, seed, previewMesh
        case part, scalpHug, volume, collide, colliders, rootPlacement, hairlineWidth, innerLayer, flyaways, clumpSize, cardTaper
        case wave, curlFrequency, lengthProfile, hemline, fringe, tie, sweepBack
    }

    /// Every key is optional; `thickness` may be one number (root and tip alike).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GroomBuild()
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) throws -> T { try c.decodeIfPresent(T.self, forKey: key) ?? fallback }
        let thickness = (try? c.decodeIfPresent(Vec2.self, forKey: .thickness)) ?? nil
            ?? (try? c.decodeIfPresent(Float.self, forKey: .thickness)).flatMap { $0.map { Vec2($0, $0) } } ?? d.thickness
        self.init(style: try value(.style, d.style), length: try value(.length, d.length),
                  lengthVariation: try value(.lengthVariation, d.lengthVariation), density: try value(.density, d.density),
                  thickness: thickness, clumping: try value(.clumping, d.clumping), curl: try value(.curl, d.curl),
                  frizz: try value(.frizz, d.frizz), gravity: try value(.gravity, d.gravity), stiffness: try value(.stiffness, d.stiffness),
                  rootColor: try value(.rootColor, d.rootColor), tipColor: try value(.tipColor, d.tipColor),
                  colorNoise: try value(.colorNoise, d.colorNoise), specular: try value(.specular, d.specular),
                  mask: try value(.mask, d.mask), combDirection: try value(.combDirection, d.combDirection),
                  combStrength: try value(.combStrength, d.combStrength), flowTexture: try value(.flowTexture, d.flowTexture),
                  wind: try value(.wind, d.wind), shells: try value(.shells, d.shells), cardWidth: try value(.cardWidth, d.cardWidth),
                  cardSegments: try value(.cardSegments, d.cardSegments), strandsPerCard: try value(.strandsPerCard, d.strandsPerCard),
                  lod: try value(.lod, d.lod), comb: try value(.comb, d.comb), cut: try value(.cut, d.cut), seed: try value(.seed, d.seed),
                  previewMesh: try value(.previewMesh, d.previewMesh), part: try value(.part, d.part), scalpHug: try value(.scalpHug, d.scalpHug),
                  volume: try value(.volume, d.volume), collide: try value(.collide, d.collide), colliders: try value(.colliders, d.colliders),
                  rootPlacement: try value(.rootPlacement, d.rootPlacement), hairlineWidth: try value(.hairlineWidth, d.hairlineWidth),
                  innerLayer: try value(.innerLayer, d.innerLayer), flyaways: try value(.flyaways, d.flyaways),
                  clumpSize: try value(.clumpSize, d.clumpSize), cardTaper: try value(.cardTaper, d.cardTaper), wave: try value(.wave, d.wave),
                  curlFrequency: try value(.curlFrequency, d.curlFrequency), lengthProfile: try value(.lengthProfile, d.lengthProfile),
                  hemline: try value(.hemline, d.hemline), fringe: try value(.fringe, d.fringe), tie: try value(.tie, d.tie),
                  sweepBack: try value(.sweepBack, d.sweepBack))
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    public static var fieldHints: [String: FieldHints] {
        ["style": FieldHints(tooltip: "shell: short fur, moss, velvet; cards: longer hair, manes, feathers"),
         "length": FieldHints(range: 0.001...1, step: 0.001, tooltip: "Strand length in meters"),
         "lengthVariation": FieldHints(range: 0...1, step: 0.01, tooltip: "How much shorter random strands are"),
         "density": FieldHints(range: 0.01...400, step: 0.5, tooltip: "Strands (shell) or cards (cards) per square centimeter"),
         "thickness": FieldHints(step: 0.01, tooltip: "Strand thickness at the root and the tip, 0-1 of the strand spacing"),
         "clumping": FieldHints(range: 0...1, step: 0.01, tooltip: "Strands gather into pointed clumps toward their tips"),
         "curl": FieldHints(range: 0...1, step: 0.01, tooltip: "Strands spiral"),
         "frizz": FieldHints(range: 0...1, step: 0.01, tooltip: "Random wobble along each strand"),
         "gravity": FieldHints(range: 0...1, step: 0.01, tooltip: "How much strands droop"),
         "stiffness": FieldHints(range: 0...1, step: 0.01, tooltip: "Resists gravity, wind and motion"),
         "rootColor": FieldHints(color: true, srgb: true, tooltip: "Color at the roots"),
         "tipColor": FieldHints(color: true, srgb: true, tooltip: "Color at the tips"),
         "colorNoise": FieldHints(range: 0...1, step: 0.01, tooltip: "Per-strand brightness variation"),
         "specular": FieldHints(range: 0...1, step: 0.01, tooltip: "Strength of the strand highlights"),
         "combStrength": FieldHints(range: 0...1, step: 0.01, tooltip: "How far strands lean toward the comb direction (1: flat)"),
         "flowTexture": FieldHints(tooltip: "A flow map (red/green: direction in UV space) strands are combed along"),
         "wind": FieldHints(range: 0...4, step: 0.05, tooltip: "Scales the scene's wind on the fur (0: still)"),
         "shells": FieldHints(range: 2...64, step: 1, tooltip: "Shells at full detail (shell style)"),
         "cardWidth": FieldHints(range: 0.001...0.2, step: 0.001, tooltip: "Card width in meters (cards style)"),
         "cardSegments": FieldHints(range: 2...16, step: 1, tooltip: "Segments along each card"),
         "strandsPerCard": FieldHints(range: 1...32, step: 1, tooltip: "Strands drawn across each card"),
         "seed": FieldHints(step: 1, tooltip: "Changes where strands and cards grow"),
         "previewMesh": FieldHints(tooltip: "What the preview grows the fur on: sphere, cube, capsule, plane or a .meshbuild path"),
         "scalpHug": FieldHints(range: 0...1, step: 0.01, tooltip: "How far along each strand it lies on the scalp before it falls (cards)"),
         "volume": FieldHints(range: 0...1, step: 0.01, tooltip: "How far hair stands off the scalp where it lies on it (cards)"),
         "collide": FieldHints(tooltip: "Keep cards out of the mesh and the colliders"),
         "rootPlacement": FieldHints(tooltip: "even: blue-noise spaced roots; random: pure random"),
         "hairlineWidth": FieldHints(range: 0...0.2, step: 0.001, tooltip: "Meters inside the hair's edge where cards thin out and shorten"),
         "innerLayer": FieldHints(range: 0...1, step: 0.01, tooltip: "Fraction of cards in a short flat layer that hides the scalp"),
         "flyaways": FieldHints(range: 0...1, step: 0.005, tooltip: "Fraction of stray, frizzy cards"),
         "clumpSize": FieldHints(range: 2...64, step: 1, tooltip: "Cards per clump"),
         "cardTaper": FieldHints(range: 0...1, step: 0.01, tooltip: "How much narrower cards are at their tips"),
         "wave": FieldHints(range: 0...1, step: 0.01, tooltip: "Flat waves along each strand"),
         "sweepBack": FieldHints(range: 0...1, step: 0.01, tooltip: "Front hair combed back and to the sides, away from the face"),
         "curlFrequency": FieldHints(range: 0.25...12, step: 0.25, tooltip: "Turns of curl or waves along a strand"),
         // Edited in the Groom Builder's own rows and brushes.
         "comb": FieldHints(hidden: true), "cut": FieldHints(hidden: true), "combDirection": FieldHints(hidden: true),
         "mask": FieldHints(hidden: true), "lod": FieldHints(hidden: true), "part": FieldHints(hidden: true),
         "colliders": FieldHints(hidden: true), "lengthProfile": FieldHints(hidden: true), "hemline": FieldHints(hidden: true),
         "fringe": FieldHints(hidden: true), "tie": FieldHints(hidden: true)]
    }

    // MARK: Derived values

    /// The style the renderer draws (strands are reserved and draw as cards).
    public var drawnStyle: GroomStyle { style == .shell ? .shell : .cards }

    /// `length` limited to a sane range.
    public var clampedLength: Float { length.isFinite ? min(max(length, 0.0005), 2) : 0.03 }

    /// Meters between strands on a shell (1 / sqrt(density per m²)).
    public var strandSpacing: Float {
        let d = density.isFinite ? min(max(density, 0.01), 2000) : 40
        return 0.01 / d.squareRoot()
    }

    /// Shells at each detail level, level 0 first.
    public var shellLevels: [Int] {
        let base = min(max(shells, 2), 64)
        var levels = lod.shells.isEmpty ? [base, max(base / 2, 2), max(base / 4, 2)] : lod.shells.map { min(max($0, 1), 64) }
        if levels.isEmpty { levels = [base] }
        return levels
    }

    /// The fraction of cards at each detail level, level 0 first.
    public var cardLevels: [Float] {
        let levels = lod.cards.map { $0.isFinite ? min(max($0, 0.02), 1) : 1 }
        return levels.isEmpty ? [1] : levels
    }

    /// Where levels after the first start (ascending, positive), one fewer than the levels plus the
    /// distance past which only the undercoat is drawn.
    public var lodDistances: [Float] {
        var out: [Float] = []
        for d in lod.distances where d.isFinite && d > (out.last ?? 0) { out.append(d) }
        return out
    }

    /// The display colors as linear RGB.
    public var linearRootColor: Vec3 { MeshBuildColor.linear(fromSRGB: rootColor) }
    public var linearTipColor: Vec3 { MeshBuildColor.linear(fromSRGB: tipColor) }
}

// MARK: Presets

extension GroomBuild {
    /// The built-in grooms (`groom.presets`).
    public static let presetNames = ["shortFur", "shaggyFur", "velvet", "moss", "tufts", "straightHair", "shortCrop", "bob", "bangs",
                                     "longStraight", "wavy", "curly", "ponytail", "mane", "feathers"]

    /// The hairstyle presets (card hair styled for a scalp or head: face toward +Z, up +Y).
    public static let hairstyleNames = ["straightHair", "shortCrop", "bob", "bangs", "longStraight", "wavy", "curly", "ponytail"]

    /// What each preset is for, and its rough cost (`groom.presets`).
    public static func presetSummary(_ name: String) -> String {
        switch name {
        case "shortFur": "Short dense animal fur (cats, rodents, plush). 24 shells; budget ~1.5 ms GPU for a creature filling a third of a 1440p view."
        case "shaggyFur": "Long clumped shaggy fur (bears, sheepdogs, yetis). 32 shells; budget ~2 ms for a creature filling a third of a 1440p view (measured 1.8 ms in the fur scene, 4.6 ms filling the view)."
        case "velvet": "Very short fine pile (velvet, felt, peach skin). 8 shells; budget ~0.5 ms."
        case "moss": "Moss and lichen on rocks and logs, swaying a little in the wind. 12 shells; budget ~1 ms for a few rocks in view."
        case "tufts": "Grass-like tufts for lawns and meadows (terrain scatter, ground patches). 16 shells; budget ~1.5 ms for a patch filling a third of the view."
        case "straightHair": "Straight shoulder-length hair with a center part, lying on the scalp and falling to the shoulders. Cards; budget ~1 ms for ~1500 cards (measured 2 ms for a head filling a quarter of a 1440p view)."
        case "shortCrop": "A short crop: short cards lying on the scalp, longer on top, tapered at the sides and back. Cards; budget ~0.7 ms."
        case "bob": "A chin-length bob with a side part, cut blunt and a little longer at the front (A-line). Cards; budget ~1 ms."
        case "bangs": "A bob with a fringe (bangs) combed down over the forehead. Cards; budget ~1 ms."
        case "longStraight": "Long straight hair to mid-back with a center part and face-framing layers. Cards; budget ~1.5 ms."
        case "wavy": "Shoulder-length wavy hair with a side part and volume. Cards; budget ~1.5 ms."
        case "curly": "Curly hair: springy spiral clumps standing off the head. Cards; budget ~2 ms (more segments per card)."
        case "ponytail": "Hair pulled back along the scalp into a tie at the back of the head, hanging as a tail. Cards; budget ~1 ms."
        case "mane": "A thick mane or beard of clumped cards. Cards; budget ~1.5 ms."
        case "feathers": "Broad flat feather cards lying along the body. Cards; budget ~1 ms."
        default: ""
        }
    }

    /// What the hairstyle presets share: cards hugging the scalp then falling, combed down,
    /// a flat inner layer under the styled one, a few flyaways, tapered clumps.
    static func hairBase() -> GroomBuild {
        GroomBuild(style: .cards, length: 0.25, lengthVariation: 0.12, density: 2, thickness: Vec2(0.6, 0.35), clumping: 0.4,
                   frizz: 0.02, gravity: 0.9, stiffness: 0.3, rootColor: Vec3(0.2, 0.13, 0.08), tipColor: Vec3(0.42, 0.29, 0.17),
                   colorNoise: 0.15, specular: 0.7, combDirection: .followSurface, combStrength: 0.9, wind: 0.8, cardWidth: 0.014,
                   cardSegments: 10, strandsPerCard: 10, scalpHug: 0.35, volume: 0.35, hairlineWidth: 0.012, innerLayer: 0.3,
                   flyaways: 0.015, clumpSize: 6, cardTaper: 0.55, sweepBack: 0.7)
    }

    /// A ready-made groom by name (case-insensitive; "short fur", "short-fur" work too); nil for an unknown name.
    public static func preset(_ name: String) -> GroomBuild? {
        let key = name.lowercased().filter { $0.isLetter }
        switch key {
        case "shortfur", "fur":
            return GroomBuild(length: 0.025, density: 60, thickness: Vec2(0.75, 0.1), clumping: 0.15, frizz: 0.1, gravity: 0.2,
                              stiffness: 0.6, rootColor: Vec3(0.3, 0.2, 0.12), tipColor: Vec3(0.78, 0.62, 0.42), colorNoise: 0.2,
                              combDirection: .followSurface, combStrength: 0.35, shells: 24)
        case "shaggyfur", "shaggy":
            return GroomBuild(length: 0.07, lengthVariation: 0.4, density: 25, thickness: Vec2(0.9, 0.1), clumping: 0.55, curl: 0.15,
                              frizz: 0.3, gravity: 0.6, stiffness: 0.3, rootColor: Vec3(0.18, 0.13, 0.1), tipColor: Vec3(0.55, 0.44, 0.33),
                              colorNoise: 0.3, combDirection: .followSurface, combStrength: 0.4, shells: 32,
                              lod: GroomLOD(shells: [32, 16, 8], distances: [6, 14, 30]))
        case "velvet", "velvetmoss":
            return GroomBuild(length: 0.004, lengthVariation: 0.1, density: 200, thickness: Vec2(0.7, 0.5), clumping: 0, frizz: 0,
                              gravity: 0, stiffness: 1, rootColor: Vec3(0.35, 0.05, 0.12), tipColor: Vec3(0.6, 0.12, 0.22),
                              colorNoise: 0.05, specular: 0.8, wind: 0, shells: 8,
                              lod: GroomLOD(shells: [8, 4, 2], distances: [3, 8, 16]))
        case "moss":
            return GroomBuild(length: 0.018, lengthVariation: 0.5, density: 30, thickness: Vec2(0.9, 0.35), clumping: 0.35, curl: 0.1,
                              frizz: 0.35, gravity: 0.05, stiffness: 0.7, rootColor: Vec3(0.12, 0.17, 0.05), tipColor: Vec3(0.42, 0.55, 0.16),
                              colorNoise: 0.35, specular: 0.15, wind: 0.6, shells: 12,
                              lod: GroomLOD(shells: [12, 6, 3], distances: [8, 18, 40]))
        case "tufts", "grass", "grasstufts", "grasslike", "grassliketufts":
            return GroomBuild(length: 0.09, lengthVariation: 0.5, density: 6, thickness: Vec2(0.9, 0.05), clumping: 0.6, frizz: 0.15,
                              gravity: 0.15, stiffness: 0.5, rootColor: Vec3(0.12, 0.2, 0.06), tipColor: Vec3(0.55, 0.68, 0.25),
                              colorNoise: 0.3, specular: 0.2, wind: 1.5, shells: 16,
                              lod: GroomLOD(shells: [16, 8, 4], distances: [8, 18, 40]))
        case "straighthair", "hair":
            var h = hairBase()
            h.length = 0.25
            h.part = GroomPart(style: .center)
            h.lengthProfile = GroomLengthProfile(front: 0.8)
            return h
        case "shortcrop", "crop", "short", "shorthair":
            var h = hairBase()
            h.length = 0.055
            h.lengthVariation = 0.2
            h.density = 3
            h.scalpHug = 0.85
            h.volume = 0.5
            h.gravity = 0.3
            h.stiffness = 0.6
            h.clumping = 0.35
            h.clumpSize = 5
            h.combDirection = .vector(Vec3(0, 0.15, -1))
            h.part = GroomPart(style: .side, strength: 0.7)
            h.lengthProfile = GroomLengthProfile(front: 1.1, back: 0.55, top: 1.3, sides: 0.45)
            h.cardWidth = 0.009
            h.cardSegments = 5
            h.strandsPerCard = 8
            h.flyaways = 0.01
            return h
        case "bob":
            var h = hairBase()
            h.length = 0.24
            h.part = GroomPart(style: .side, offset: 0.35)
            h.scalpHug = 0.4
            h.volume = 0.4
            h.hemline = GroomHemline(enabled: true, back: -1.55, front: -1.85, softness: 0.05)
            h.clumping = 0.35
            return h
        case "bangs", "fringe", "bobwithbangs":
            var h = preset("bob")!
            h.part = GroomPart(style: .none)
            h.fringe = GroomFringe(amount: 0.75, length: 0.1)
            return h
        case "longstraight", "long", "longhair":
            var h = hairBase()
            h.length = 0.45
            h.lengthVariation = 0.08
            h.part = GroomPart(style: .center)
            h.scalpHug = 0.3
            h.lengthProfile = GroomLengthProfile(front: 0.55, back: 1.05, top: 1, sides: 0.85)
            h.cardSegments = 12
            return h
        case "wavy", "waves":
            var h = hairBase()
            h.length = 0.32
            h.part = GroomPart(style: .side, offset: -0.35)
            h.scalpHug = 0.3
            h.volume = 0.6
            h.wave = 0.7
            h.curlFrequency = 2.5
            h.clumping = 0.5
            h.clumpSize = 6
            h.cardSegments = 14
            h.lengthProfile = GroomLengthProfile(front: 0.75)
            return h
        case "curly", "curls":
            var h = hairBase()
            h.length = 0.2
            h.lengthVariation = 0.25
            h.density = 2.5
            h.scalpHug = 0.12
            h.volume = 0.9
            h.gravity = 0.45
            h.stiffness = 0.45
            h.curl = 0.7
            h.curlFrequency = 3.5
            h.clumping = 0.6
            h.clumpSize = 5
            h.flyaways = 0.04
            h.cardWidth = 0.018
            h.cardSegments = 16
            h.cardTaper = 0.3
            h.rootColor = Vec3(0.12, 0.08, 0.05)
            h.tipColor = Vec3(0.3, 0.2, 0.12)
            return h
        case "ponytail":
            var h = hairBase()
            h.length = 0.3
            h.rootColor = Vec3(0.35, 0.2, 0.08)
            h.tipColor = Vec3(0.62, 0.42, 0.2)
            h.tie = GroomTie(enabled: true, point: Vec3(0, 0.15, -1.08), tail: 0.3, radius: 0.016)
            h.density = 2.6
            h.volume = 0.1
            h.clumping = 0.5
            h.innerLayer = 0.35
            h.flyaways = 0.01
            h.cardSegments = 14
            return h
        case "mane", "beard":
            return GroomBuild(style: .cards, length: 0.18, lengthVariation: 0.35, density: 1.2, thickness: Vec2(0.8, 0.2),
                              clumping: 0.7, curl: 0.1, frizz: 0.25, gravity: 0.5, stiffness: 0.35, rootColor: Vec3(0.25, 0.14, 0.06),
                              tipColor: Vec3(0.6, 0.38, 0.16), colorNoise: 0.25, specular: 0.5, combDirection: .followSurface,
                              combStrength: 0.45, wind: 1, cardWidth: 0.02, cardSegments: 7, strandsPerCard: 12)
        case "feathers", "feather":
            return GroomBuild(style: .cards, length: 0.08, lengthVariation: 0.2, density: 0.6, thickness: Vec2(1, 0.7), clumping: 0,
                              frizz: 0.02, gravity: 0.2, stiffness: 0.8, rootColor: Vec3(0.85, 0.85, 0.82), tipColor: Vec3(0.35, 0.45, 0.6),
                              colorNoise: 0.1, specular: 0.4, combDirection: .vector(Vec3(0, -0.3, -1)), combStrength: 0.9, wind: 0.5,
                              cardWidth: 0.04, cardSegments: 3, strandsPerCard: 24)
        default:
            return nil
        }
    }
}

// MARK: Checks

/// Problems with a groom on its own (shown as warnings; nothing here stops it importing).
public enum GroomCheck {
    public static func problems(_ build: GroomBuild) -> [String] {
        var out: [String] = []
        func range(_ name: String, _ value: Float, _ r: ClosedRange<Float>) {
            if !value.isFinite || !r.contains(value) { out.append("\(name) \(value) is outside \(r.lowerBound)...\(r.upperBound); it is clamped") }
        }
        if build.style == .strands { out.append("style 'strands' is reserved for later; it draws as cards") }
        range("length", build.length, 0.0005...2)
        range("density", build.density, 0.01...2000)
        range("thickness root", build.thickness.x, 0...1)
        range("thickness tip", build.thickness.y, 0...1)
        for (name, v) in [("clumping", build.clumping), ("curl", build.curl), ("frizz", build.frizz), ("gravity", build.gravity),
                          ("stiffness", build.stiffness), ("colorNoise", build.colorNoise), ("combStrength", build.combStrength),
                          ("lengthVariation", build.lengthVariation), ("specular", build.specular)] {
            range(name, v, 0...1)
        }
        range("wind", build.wind, 0...10)
        for (name, v) in [("scalpHug", build.scalpHug), ("volume", build.volume), ("innerLayer", build.innerLayer), ("flyaways", build.flyaways),
                          ("cardTaper", build.cardTaper), ("wave", build.wave), ("sweepBack", build.sweepBack),
                          ("part.strength", build.part.strength), ("fringe.amount", build.fringe.amount)] {
            range(name, v, 0...1)
        }
        if build.clumpSize < 2 || build.clumpSize > 64 { out.append("clumpSize \(build.clumpSize) is outside 2...64; it is clamped") }
        if build.part.style == .curve && build.part.points.isEmpty { out.append("part.style 'curve' needs points; there is no part") }
        for (i, c) in build.colliders.enumerated() where !(c.radius > 0) && c.radii == nil {
            out.append("colliders[\(i)] needs a positive radius (or radii)")
        }
        if build.drawnStyle == .shell && (build.scalpHug > 0 || build.tie.enabled || build.hemline.enabled || build.innerLayer > 0) {
            out.append("scalpHug, tie, hemline and innerLayer shape card hair; shell fur ignores them")
        }
        if build.shells < 2 || build.shells > 64 { out.append("shells \(build.shells) is outside 2...64; it is clamped") }
        if build.drawnStyle == .cards {
            range("cardWidth", build.cardWidth, 0.0005...0.5)
            if build.cardSegments < 2 || build.cardSegments > 16 { out.append("cardSegments \(build.cardSegments) is outside 2...16; it is clamped") }
            if build.strandsPerCard < 1 || build.strandsPerCard > 32 { out.append("strandsPerCard \(build.strandsPerCard) is outside 1...32; it is clamped") }
        }
        let d = build.lod.distances
        if zip(d, d.dropFirst()).contains(where: { $0 >= $1 }) || d.contains(where: { !$0.isFinite || $0 <= 0 }) {
            out.append("lod.distances must be positive and ascending; out-of-order entries are ignored")
        }
        if build.drawnStyle == .shell, !build.lod.shells.isEmpty, zip(build.lod.shells, build.lod.shells.dropFirst()).contains(where: { $0 < $1 }) {
            out.append("lod.shells should not grow with distance")
        }
        if !["", "r", "g", "b", "a"].contains(build.mask.vertexPaint.lowercased()) {
            out.append("mask.vertexPaint '\(build.mask.vertexPaint)' isn't a channel (r, g, b or a)")
        }
        for (i, stroke) in build.comb.enumerated() where !(stroke.radius > 0) || length(stroke.direction) < 1e-6 {
            out.append("comb[\(i)] needs a positive radius and a direction")
        }
        for (i, stroke) in build.cut.enumerated() where !(stroke.radius > 0) {
            out.append("cut[\(i)] needs a positive radius")
        }
        if build.cut.contains(where: { $0.radius > 1e5 && $0.length <= 0 && $0.strength >= 1 }) {
            out.append("a cut stroke covers everything with length 0: no fur grows")
        }
        return out
    }
}
