import Foundation

// A model built from shapes: the contents of a `.meshbuild` file (JSON, every key optional).
// `MeshBuildImporter` turns it into one mesh and one material per part plus a prefab of the part
// tree, so it is placed, instanced and reimported like any glTF model. Animations become
// `FieldAnimator`s on the parts and play in play mode and built games.
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

    public static var fieldHints: [String: FieldHints] {
        ["parent": FieldHints(tooltip: "The part this one is attached to (moves with it)"),
         "rotation": FieldHints(step: 1, tooltip: "Degrees"),
         "size": FieldHints(step: 0.05, tooltip: "Meters: the box the shape fills"),
         "position": FieldHints(step: 0.05, tooltip: "Meters, in the parent's space"),
         "segments": FieldHints(range: 3...128, step: 1, tooltip: "Smoothness of round shapes"),
         "thickness": FieldHints(range: 0.001...100, step: 0.01, tooltip: "Tube wall thickness"),
         "color": FieldHints(color: true), "glow": FieldHints(color: true, tooltip: "Emitted light color (black: none)"),
         "opacity": FieldHints(range: 0...1, step: 0.01), "metallic": FieldHints(range: 0...1, step: 0.01),
         "roughness": FieldHints(range: 0...1, step: 0.01), "glowStrength": FieldHints(range: 0...100, step: 0.1),
         "textureScale": FieldHints(step: 0.1, tooltip: "Texture repeats (per meter with World UV)"),
         "worldUV": FieldHints(displayName: "World UV", tooltip: "Keep the texture's size in meters instead of stretching it"),
         "texture": FieldHints(tooltip: "A texture asset (image or .proctex)"),
         "material": FieldHints(tooltip: "A material asset that replaces the look fields")]
    }

    public init(name: String = "Part", shape: MeshBuildShape = .box, parent: String = "", position: Vec3 = .zero,
                rotation: Vec3 = .zero, size: Vec3 = Vec3(1, 1, 1), segments: Int = 24, thickness: Float = 0.1,
                color: Vec3 = Vec3(0.8, 0.8, 0.8), opacity: Float = 1, texture: String = "", textureScale: Vec2 = Vec2(1, 1),
                worldUV: Bool = false, metallic: Float = 0, roughness: Float = 0.5, glow: Vec3 = .zero, glowStrength: Float = 1,
                material: String = "") {
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
    }

    private enum CodingKeys: String, CodingKey {
        case name, shape, parent, position, rotation, size, segments, thickness, color, opacity, texture, textureScale, worldUV,
             metallic, roughness, glow, glowStrength, material
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
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material)
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

    public init(parts: [MeshBuildPart] = [], animations: [MeshBuildAnimation] = []) {
        self.parts = parts
        self.animations = animations
    }

    private enum CodingKeys: String, CodingKey { case parts, animations }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(parts: try c.decodeIfPresent([MeshBuildPart].self, forKey: .parts) ?? [],
                  animations: try c.decodeIfPresent([MeshBuildAnimation].self, forKey: .animations) ?? [])
    }

    /// A one-part starting point: a light gray unit cube resting on the ground.
    public static var starter: MeshBuild {
        MeshBuild(parts: [MeshBuildPart(name: "Base", position: Vec3(0, 0.5, 0))])
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// A name not used by any part: `base`, else "`base` 2", "`base` 3"…
    public func uniquePartName(_ base: String) -> String {
        let names = Set(parts.map(\.name))
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

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

// MARK: - Geometry

extension MeshBuildPart {
    /// The part's mesh in its own space (nil for a `group`): the shape fitted to `size`, with
    /// world-projected UVs under `worldUV`.
    public func geometry() -> MeshGeometry? {
        let s = Vec3(abs(size.x), abs(size.y), abs(size.z))
        let segments = min(max(segments, 3), 128)
        var g: MeshGeometry
        switch shape {
        case .group: return nil
        case .box: g = .cube(size: 1)
        case .sphere: g = .sphere(radius: 0.5, segments: segments, rings: max(segments / 2, 2))
        case .hemisphere: g = MeshGeometry.hemisphere(segments: segments)
        case .cylinder: g = .cylinder(radius: 0.5, height: 1, segments: segments)
        case .cone: g = .cone(radius: 0.5, height: 1, segments: segments)
        case .capsule:
            // A capsule's caps must stay round, so it is built at its real size.
            let r = min(s.x, s.z) / 2
            g = .capsule(radius: min(r, s.y / 2), height: s.y, segments: segments, rings: max(segments / 4, 2))
            g.scale(by: Vec3(r > 0 ? s.x / 2 / r : 1, 1, r > 0 ? s.z / 2 / r : 1))
            return finish(g)
        case .torus:
            let minor = min(s.y, min(s.x, s.z) / 2) / 2
            let major = max(min(s.x, s.z) / 2 - minor, 0)
            g = .torus(majorRadius: major, minorRadius: minor, segments: segments, sides: max(segments / 2, 3))
            let ring = major + minor
            g.scale(by: Vec3(ring > 0 ? s.x / 2 / ring : 1, 1, ring > 0 ? s.z / 2 / ring : 1))
            return finish(g)
        case .tube:
            g = MeshGeometry.tube(outerRadius: 0.5, innerRadius: max(0.5 - thickness / max(min(s.x, s.z), 1e-4), 0),
                                  segments: segments)
        case .plane: g = .plane(size: 1)
        case .wedge:
            g = MeshGeometry.convexHullFaces([
                [Vec3(-0.5, -0.5, -0.5), Vec3(0.5, -0.5, -0.5), Vec3(0.5, -0.5, 0.5), Vec3(-0.5, -0.5, 0.5)],  // bottom
                [Vec3(-0.5, -0.5, -0.5), Vec3(-0.5, 0.5, -0.5), Vec3(0.5, 0.5, -0.5), Vec3(0.5, -0.5, -0.5)],  // back
                [Vec3(-0.5, 0.5, -0.5), Vec3(-0.5, -0.5, 0.5), Vec3(0.5, -0.5, 0.5), Vec3(0.5, 0.5, -0.5)],    // slope
                [Vec3(-0.5, -0.5, -0.5), Vec3(-0.5, -0.5, 0.5), Vec3(-0.5, 0.5, -0.5)],                        // left
                [Vec3(0.5, -0.5, -0.5), Vec3(0.5, 0.5, -0.5), Vec3(0.5, -0.5, 0.5)],                           // right
            ])
        case .pyramid:
            let apex = Vec3(0, 0.5, 0)
            let b = [Vec3(-0.5, -0.5, -0.5), Vec3(0.5, -0.5, -0.5), Vec3(0.5, -0.5, 0.5), Vec3(-0.5, -0.5, 0.5)]
            g = MeshGeometry.convexHullFaces([b] + (0..<4).map { [b[$0], b[($0 + 1) % 4], apex] })
        }
        g.scale(by: Vec3(s.x, shape == .plane ? 1 : s.y, s.z))
        return finish(g)
    }

    private func finish(_ geometry: MeshGeometry) -> MeshGeometry {
        var g = geometry
        if worldUV {
            // Planar projection along each vertex's dominant normal axis, in meters.
            for i in g.vertices.indices {
                let p = g.vertices[i].position, n = g.vertices[i].normal
                let a = Vec3(abs(n.x), abs(n.y), abs(n.z))
                if a.x >= a.y && a.x >= a.z {
                    g.vertices[i].uv = Vec2(n.x > 0 ? -p.z : p.z, -p.y)
                } else if a.y >= a.z {
                    g.vertices[i].uv = Vec2(p.x, n.y > 0 ? p.z : -p.z)
                } else {
                    g.vertices[i].uv = Vec2(n.z > 0 ? p.x : -p.x, -p.y)
                }
            }
        }
        return g
    }
}

extension MeshGeometry {
    /// Scales positions by `factor` per axis and corrects the normals (inverse-transpose).
    mutating func scale(by factor: Vec3) {
        guard factor != Vec3(1, 1, 1) else { return }
        let inverse = Vec3(factor.x != 0 ? 1 / factor.x : 0, factor.y != 0 ? 1 / factor.y : 0, factor.z != 0 ? 1 / factor.z : 0)
        for i in vertices.indices {
            vertices[i].position *= factor
            let n = vertices[i].normal * inverse
            let len = length(n)
            vertices[i].normal = len > 0 ? n / len : vertices[i].normal
        }
        // A negative scale mirrors the mesh: flip the winding to keep faces counter-clockwise.
        if factor.x * factor.y * factor.z < 0 {
            for t in stride(from: 0, to: indices.count - 2, by: 3) { indices.swapAt(t + 1, t + 2) }
        }
    }

    /// The top half of a sphere of radius 0.5 squashed to unit height: base at y = -0.5 (a flat
    /// disc), top at +0.5, diameter 1.
    static func hemisphere(segments: Int) -> MeshGeometry {
        let rings = max(segments / 4, 2)
        var profile: [LatheRing] = []
        for i in 0...rings {
            let a = Float(i) / Float(rings) * .pi / 2
            // A radius-0.5 dome of height 1: y = -0.5 + cos(a), normals of the stretched sphere.
            let n = normalize(Vec3(sinf(a), cosf(a) / 2, 0))
            profile.append((0.5 * sinf(a), -0.5 + cosf(a), n.x, n.y, Float(i) / Float(rings)))
        }
        var g = MeshGeometry(vertices: [], indices: [])
        g.appendLathe(profile, segments: segments)
        g.appendCap(radius: 0.5, y: -0.5, up: false, segments: segments)
        return g
    }

    /// A hollow cylinder along Y of height 1 between `innerRadius` and `outerRadius`, with flat rings at both ends.
    static func tube(outerRadius: Float, innerRadius: Float, segments: Int) -> MeshGeometry {
        let ro = outerRadius, ri = min(innerRadius, outerRadius * 0.999)
        var g = MeshGeometry(vertices: [], indices: [])
        // Each lathe piece runs in the direction that makes its normal (profile direction turned
        // +90 degrees in (r, y)) point outward: top inner→outer, outer wall down, bottom outer→inner, inner wall up.
        g.appendLathe([(ri, 0.5, 0, 1, 0), (ro, 0.5, 0, 1, 0.1)], segments: segments)
        g.appendLathe([(ro, 0.5, 1, 0, 0.1), (ro, -0.5, 1, 0, 0.5)], segments: segments)
        g.appendLathe([(ro, -0.5, 0, -1, 0.5), (ri, -0.5, 0, -1, 0.6)], segments: segments)
        if ri > 0 { g.appendLathe([(ri, -0.5, -1, 0, 0.6), (ri, 0.5, -1, 0, 1)], segments: segments) }
        return g
    }

    /// A flat-shaded convex solid from its faces (each a planar loop of corners in either
    /// order): every face is wound counter-clockwise seen from outside (judged against the
    /// solid's center), fan-triangulated, with planar 0–1 UVs.
    static func convexHullFaces(_ faces: [[Vec3]]) -> MeshGeometry {
        let all = faces.flatMap { $0 }
        let center = all.reduce(Vec3.zero, +) / Float(max(all.count, 1))
        var g = MeshGeometry(vertices: [], indices: [])
        for var face in faces where face.count >= 3 {
            var n = Vec3.zero  // Newell's method
            for i in face.indices {
                let a = face[i], b = face[(i + 1) % face.count]
                n += Vec3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
            }
            let faceCenter = face.reduce(Vec3.zero, +) / Float(face.count)
            if dot(n, faceCenter - center) < 0 { face.reverse(); n = -n }
            n = normalize(n)
            // UV axes in the face's plane: u along the first edge, v perpendicular.
            let u = normalize(face[1] - face[0]), v = cross(n, u)
            let coords = face.map { Vec2(dot($0 - face[0], u), dot($0 - face[0], v)) }
            let lo = coords.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
            let hi = coords.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
            let extent = pointwiseMax(hi - lo, Vec2(1e-6, 1e-6))
            let base = UInt32(g.vertices.count)
            for (p, c) in zip(face, coords) {
                let t = (c - lo) / extent
                g.vertices.append(MeshVertex(position: p, normal: n, uv: Vec2(t.x, 1 - t.y)))
            }
            for i in 1..<UInt32(face.count - 1) { g.indices += [base, base + i, base + i + 1] }
        }
        return g
    }
}

// MARK: - Importer

/// Imports `.meshbuild` files (a `MeshBuild` as JSON): `mesh/<part>` and `material/<part>` per
/// part (no material for parts using a `material` asset, no mesh for groups) and the main
/// `prefab/<file name>`: a root node named after the file holding the part tree, with a
/// `FieldAnimator` on every part an autoplay animation moves. Editing the file (in the editor's
/// Mesh Builder, with the `meshBuild.*` tools or by hand) reimports it and updates placed copies.
public struct MeshBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "meshbuild" }
    public var fileExtensions: [String] { ["meshbuild"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: MeshBuild
        do { build = try AssetJSON.decoder().decode(MeshBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a mesh build: \(error)")
        }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()

        // Part names must be unique for parenting and tracks; later duplicates are only drawn.
        var firstIndex: [String: Int] = [:]
        for (i, part) in build.parts.enumerated() {
            if firstIndex[part.name] == nil { firstIndex[part.name] = i } else { context.warn("two parts are named '\(part.name)'") }
        }
        let partNames = Set(firstIndex.keys)
        for animation in build.animations {
            for track in animation.allTracks where !partNames.contains(track.part) {
                context.warn("animation '\(animation.name)' moves a part that doesn't exist: '\(track.part)'")
            }
        }

        var nodes: [PrefabNode] = []
        for (i, part) in build.parts.enumerated() {
            var node = PrefabNode(name: part.name, transform: part.transform)
            if let geometry = part.geometry(), !geometry.indices.isEmpty {
                let meshID = namer.id(kind: "mesh", name: part.name, index: i)
                asset.add(meshID, name: part.name, .mesh(geometry))
                node.mesh = context.reference(meshID)
                if let material = resolve(part.material, kind: "material", part: part.name, &context) {
                    node.material = material
                } else {
                    let materialID = namer.id(kind: "material", name: part.name, index: i)
                    asset.add(materialID, name: part.name,
                              .material(Self.material(for: part, texture: resolve(part.texture, kind: "texture", part: part.name, &context))))
                    node.material = context.reference(materialID)
                }
            }
            if firstIndex[part.name] == i {
                let tracks = build.animatorTracks(for: part.name)
                if !tracks.isEmpty { node.animator = FieldAnimator(tracks: tracks) }
            }
            nodes.append(node)
        }

        // The tree: a part hangs from the first part with its `parent` name, unless that would
        // make a loop or the parent is missing (then from the root).
        func parentIndex(of i: Int) -> Int? {
            let parent = build.parts[i].parent
            guard !parent.isEmpty else { return nil }
            guard let p = firstIndex[parent], p != i else {
                context.warn("part '\(build.parts[i].name)' has a missing parent '\(parent)'")
                return nil
            }
            var seen: Set<Int> = [i], up: Int? = p
            while let u = up {
                if seen.contains(u) {
                    context.warn("part '\(build.parts[i].name)' is its own ancestor; attached to the root")
                    return nil
                }
                seen.insert(u)
                let name = build.parts[u].parent
                up = name.isEmpty ? nil : firstIndex[name]
            }
            return p
        }
        var children: [Int: [Int]] = [:]
        var roots: [Int] = []
        for i in build.parts.indices {
            if let p = parentIndex(of: i) { children[p, default: []].append(i) } else { roots.append(i) }
        }
        func tree(_ i: Int) -> PrefabNode {
            var node = nodes[i]
            node.children = (children[i] ?? []).map(tree)
            return node
        }
        let root = PrefabNode(name: stem, children: roots.map(tree))
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [root])))
        asset.main = prefab
        return asset
    }

    /// The material of a part without a `material` asset.
    static func material(for part: MeshBuildPart, texture: AssetReference?) -> MaterialAsset {
        let opacity = min(max(part.opacity, 0), 1)
        let color = MeshBuildColor.linear(fromSRGB: part.color)
        return MaterialAsset(shading: .pbr, baseColor: Vec4(color.x, color.y, color.z, opacity), texture: texture,
                             uvScale: part.textureScale, metallic: min(max(part.metallic, 0), 1),
                             roughness: min(max(part.roughness, 0), 1), emissiveColor: MeshBuildColor.linear(fromSRGB: part.glow),
                             emissiveStrength: max(part.glowStrength, 0), alphaMode: opacity < 1 ? .blend : .opaque,
                             doubleSided: part.shape == .plane)
    }

    /// The asset `value` names ("" is none): a reference ("asset:<id>[#object]"), else a path
    /// relative to `Assets/`, else relative to the mesh build's folder. A file reference gets
    /// `kind` as its object ("texture", "material").
    private func resolve(_ value: String, kind: String, part: String, _ context: inout ImportContext) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: kind) : reference
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        if let id = context.assetsByPath[path] ?? context.asset(atRelativePath: path) {
            return AssetReference(id, subAsset: kind)
        }
        context.warn("part '\(part)': no \(kind) asset '\(value)'")
        return nil
    }
}

/// sRGB to linear conversion for display colors.
enum MeshBuildColor {
    /// The linear value of a display (sRGB) color, per channel.
    static func linear(fromSRGB c: Vec3) -> Vec3 {
        func f(_ x: Float) -> Float {
            let x = min(max(x, 0), 1)
            return x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4)
        }
        return Vec3(f(c.x), f(c.y), f(c.z))
    }
}
