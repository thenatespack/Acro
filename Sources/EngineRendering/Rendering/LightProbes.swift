import Foundation
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

// Light probes for `SceneRenderer` (see SceneRenderer+Probes.swift for the GPU side):
//
// - `ReflectionProbe`: a box-projected reflection captured at a point. Baked as six 128 px
//   faces (the scene drawn from the capture point, in the probe's own orientation), turned into
//   an equirectangular image (the device has 2D textures only, as for the sky) and prefiltered for
//   roughness 0, 0.2, … 1 like the environment (`ReflectionProbeImage`). PBR surfaces inside the
//   probe's influence box reflect it instead of the sky: the reflected ray is intersected with
//   the projection box and the image is looked up toward that point from the capture point, so
//   reflections line up with the room. Overlapping probes blend (the smallest, or the highest
//   `priority`, first) and fade out over `blendDistance` at the box's faces; what no probe
//   covers falls back to the environment.
// - `IrradianceVolume`: a grid of probes in a box, each storing the light arriving from every
//   direction as L2 spherical harmonics (nine RGB coefficients, as the sky's irradiance), baked
//   from 32 px captures. Surfaces inside the box (static and dynamic alike) take their indirect
//   diffuse light from the eight probes around them (trilinear), instead of the sky. Leaks
//   through walls are reduced three ways: the lookup point moves off the surface along its
//   normal (`normalBias`) and toward the viewer (`viewBias`), probes behind the surface weigh
//   less (a smooth backface term), and probes found inside geometry when baking (most of their
//   rays leave through back faces) are turned off. Several `bounces` bake again with the last
//   bounce's probes lighting the captures.
//
// Bakes are matched to probes by a key of everything that shapes the bake (`bakeKey`), cached in
// the project's `Library/Lighting` (`LightProbeBakeCache`), cooked into exported games and loaded
// from there instead of baking. Without a cached bake, `SceneRenderer.bakesProbesAutomatically`
// bakes on the GPU when probes appear.

/// A box-projected reflection probe: what the scene looks like from `captureOffset` (in the
/// entity's space), reflected by PBR surfaces inside its influence box (`size`, centered on the
/// entity and turned with it; scale is ignored). Baked in the editor (`lighting.bake`) or, without
/// a cached bake, when it first appears (`SceneRenderer.bakesProbesAutomatically`). Every key is optional.
public struct ReflectionProbe: Component, Codable, Equatable, Sendable {
    public static let componentName = "ReflectionProbe"
    public static var fieldHints: [String: FieldHints] {
        ["size": FieldHints(tooltip: "Width, height and depth of the influence box, centered on the entity, in meters"),
         "blendDistance": FieldHints(range: 0...10, step: 0.05, tooltip: "The reflection fades out over this distance inside the box's faces"),
         "boxProjection": FieldHints(tooltip: "Line reflections up with the box (a room): off treats the reflection as infinitely far, like the sky"),
         "projectionSize": FieldHints(tooltip: "The box reflections are projected onto (0 on every axis: the influence box)"),
         "captureOffset": FieldHints(tooltip: "Where the probe captures from, relative to the entity"),
         "intensity": FieldHints(range: 0...8, step: 0.01, tooltip: "Scales the reflection"),
         "priority": FieldHints(range: -10...10, step: 1, tooltip: "Higher priorities blend over lower ones; equal ones, smaller boxes first"),
         "nearClip": FieldHints(range: 0.001...10, step: 0.01, tooltip: "Nearest distance the capture sees"),
         "farClip": FieldHints(range: 1...10000, step: 1, tooltip: "Farthest distance the capture sees")]
    }

    /// The influence box's full size in meters.
    public var size: Vec3
    /// Distance inside the box's faces over which the reflection fades out (0: hard edges).
    public var blendDistance: Float
    /// Project reflections onto the box (`projectionSize`) so they line up with a room.
    public var boxProjection: Bool
    /// The projection box's full size; zero uses `size`.
    public var projectionSize: Vec3
    /// The capture point relative to the entity (in its space).
    public var captureOffset: Vec3
    public var intensity: Float
    /// Probes with a higher priority blend over others; equal priorities put smaller boxes first.
    public var priority: Int
    public var nearClip: Float
    public var farClip: Float
    public var isEnabled: Bool

    public init(size: Vec3 = Vec3(10, 5, 10), blendDistance: Float = 1, boxProjection: Bool = true, projectionSize: Vec3 = .zero,
                captureOffset: Vec3 = .zero, intensity: Float = 1, priority: Int = 0, nearClip: Float = 0.05, farClip: Float = 200,
                isEnabled: Bool = true) {
        self.size = size
        self.blendDistance = blendDistance
        self.boxProjection = boxProjection
        self.projectionSize = projectionSize
        self.captureOffset = captureOffset
        self.intensity = intensity
        self.priority = priority
        self.nearClip = nearClip
        self.farClip = farClip
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case size, blendDistance, boxProjection, projectionSize, captureOffset, intensity, priority, nearClip, farClip, isEnabled
    }

    /// Missing keys take their defaults.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReflectionProbe()
        self.init(size: try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size,
                  blendDistance: try c.decodeIfPresent(Float.self, forKey: .blendDistance) ?? d.blendDistance,
                  boxProjection: try c.decodeIfPresent(Bool.self, forKey: .boxProjection) ?? d.boxProjection,
                  projectionSize: try c.decodeIfPresent(Vec3.self, forKey: .projectionSize) ?? d.projectionSize,
                  captureOffset: try c.decodeIfPresent(Vec3.self, forKey: .captureOffset) ?? d.captureOffset,
                  intensity: try c.decodeIfPresent(Float.self, forKey: .intensity) ?? d.intensity,
                  priority: try c.decodeIfPresent(Int.self, forKey: .priority) ?? d.priority,
                  nearClip: try c.decodeIfPresent(Float.self, forKey: .nearClip) ?? d.nearClip,
                  farClip: try c.decodeIfPresent(Float.self, forKey: .farClip) ?? d.farClip,
                  isEnabled: try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled)
    }

    /// Half the influence box (never negative).
    public var halfExtents: Vec3 { simdMax(size, .zero) * 0.5 }
    /// Half the projection box: `projectionSize`, or the influence box when that is zero.
    public var projectionHalfExtents: Vec3 {
        projectionSize == .zero ? halfExtents : simdMax(projectionSize, .zero) * 0.5
    }

    /// The key bakes of this probe at `frame` (`LightProbeFrame`) are cached under: everything
    /// that shapes the captured image (not `intensity`, `priority` or `blendDistance`, which
    /// apply when shading).
    public func bakeKey(frame: LightProbeFrame) -> String {
        let fields = [LightProbeBakeCache.bakeVersion, 0].map { Float($0) } + frame.keyFields
            + [captureOffset.x, captureOffset.y, captureOffset.z, nearClip, farClip]
        return "reflection-" + LightProbeBakeCache.hash(fields)
    }
}

/// A grid of irradiance probes filling a box (`size`, centered on the entity and turned with it;
/// scale is ignored): `countX` x `countY` x `countZ` probes at the centers of equal cells. Each
/// holds L2 spherical harmonics of the light arriving at it; surfaces in the box take their
/// indirect diffuse light from the eight probes around them. Every key is optional.
public struct IrradianceVolume: Component, Codable, Equatable, Sendable {
    public static let componentName = "IrradianceVolume"
    public static var fieldHints: [String: FieldHints] {
        ["size": FieldHints(tooltip: "Width, height and depth of the box, centered on the entity, in meters"),
         "countX": FieldHints(range: 1...32, step: 1, tooltip: "Probes along X"),
         "countY": FieldHints(range: 1...32, step: 1, tooltip: "Probes along Y"),
         "countZ": FieldHints(range: 1...32, step: 1, tooltip: "Probes along Z"),
         "blendDistance": FieldHints(range: 0...10, step: 0.05, tooltip: "The volume's light fades into the sky's over this distance inside its faces"),
         "normalBias": FieldHints(range: 0...2, step: 0.01, tooltip: "Lookups move off the surface along its normal by this much (less light leaking through walls)"),
         "viewBias": FieldHints(range: 0...2, step: 0.01, tooltip: "Lookups move toward the viewer by this much"),
         "intensity": FieldHints(range: 0...8, step: 0.01, tooltip: "Scales the indirect light"),
         "bounces": FieldHints(range: 1...4, step: 1, tooltip: "Light bounces baked (each bake pass sees the previous one's light)")]
    }

    public var size: Vec3
    public var countX: Int
    public var countY: Int
    public var countZ: Int
    public var blendDistance: Float
    public var normalBias: Float
    public var viewBias: Float
    public var intensity: Float
    public var bounces: Int
    public var isEnabled: Bool

    public init(size: Vec3 = Vec3(10, 4, 10), countX: Int = 4, countY: Int = 2, countZ: Int = 4, blendDistance: Float = 0.5,
                normalBias: Float = 0.2, viewBias: Float = 0.1, intensity: Float = 1, bounces: Int = 2, isEnabled: Bool = true) {
        self.size = size
        self.countX = countX
        self.countY = countY
        self.countZ = countZ
        self.blendDistance = blendDistance
        self.normalBias = normalBias
        self.viewBias = viewBias
        self.intensity = intensity
        self.bounces = bounces
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case size, countX, countY, countZ, blendDistance, normalBias, viewBias, intensity, bounces, isEnabled
    }

    /// Missing keys take their defaults.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = IrradianceVolume()
        self.init(size: try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size,
                  countX: try c.decodeIfPresent(Int.self, forKey: .countX) ?? d.countX,
                  countY: try c.decodeIfPresent(Int.self, forKey: .countY) ?? d.countY,
                  countZ: try c.decodeIfPresent(Int.self, forKey: .countZ) ?? d.countZ,
                  blendDistance: try c.decodeIfPresent(Float.self, forKey: .blendDistance) ?? d.blendDistance,
                  normalBias: try c.decodeIfPresent(Float.self, forKey: .normalBias) ?? d.normalBias,
                  viewBias: try c.decodeIfPresent(Float.self, forKey: .viewBias) ?? d.viewBias,
                  intensity: try c.decodeIfPresent(Float.self, forKey: .intensity) ?? d.intensity,
                  bounces: try c.decodeIfPresent(Int.self, forKey: .bounces) ?? d.bounces,
                  isEnabled: try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled)
    }

    /// The probe counts per axis, each clamped to 0...`IrradianceVolume.maxCount`.
    public var counts: SIMD3<Int> {
        SIMD3(min(max(countX, 0), Self.maxCount), min(max(countY, 0), Self.maxCount), min(max(countZ, 0), Self.maxCount))
    }
    /// The most probes along one axis.
    public static let maxCount = 64
    public var probeCount: Int { counts.x * counts.y * counts.z }
    public var halfExtents: Vec3 { simdMax(size, .zero) * 0.5 }

    /// Probe `index` (x fastest, then y, then z) in the volume's own space: the center of its cell.
    public func localPosition(of index: Int) -> Vec3 {
        let n = counts
        let cell = SIMD3(index % n.x, (index / n.x) % n.y, index / (n.x * n.y))
        return localPosition(cell: cell)
    }

    public func localPosition(cell: SIMD3<Int>) -> Vec3 {
        let n = Vec3(Float(max(counts.x, 1)), Float(max(counts.y, 1)), Float(max(counts.z, 1)))
        let c = Vec3(Float(cell.x), Float(cell.y), Float(cell.z))
        return -halfExtents + (c + 0.5) / n * halfExtents * 2
    }

    /// The key bakes of this volume at `frame` are cached under (not `intensity`, the biases or
    /// `blendDistance`, which apply when shading).
    public func bakeKey(frame: LightProbeFrame) -> String {
        let n = counts
        let fields = [Float(LightProbeBakeCache.bakeVersion), 1] + frame.keyFields
            + [size.x, size.y, size.z, Float(n.x), Float(n.y), Float(n.z), Float(min(max(bounces, 1), 4))]
        return "irradiance-" + LightProbeBakeCache.hash(fields)
    }
}

/// Where a probe sits: its entity's world position and rotation (scale is ignored).
public struct LightProbeFrame: Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat

    public init(position: Vec3, rotation: Quat) {
        self.position = position
        self.rotation = rotation
    }

    /// The position and rotation of a world matrix (its columns normalized; scale dropped).
    public init(world m: Mat4) {
        func axis(_ c: Vec4) -> Vec4 {
            let v = Vec3(c.x, c.y, c.z)
            let l = length(v)
            return l > 1e-12 ? Vec4(v / l, 0) : Vec4(0, 0, 0, 0)
        }
        var r = Mat4(axis(m.c0), axis(m.c1), axis(m.c2), Vec4(0, 0, 0, 1))
        if r.c0 == .zero || r.c1 == .zero || r.c2 == .zero { r = .identity }
        self.init(position: Vec3(m.c3.x, m.c3.y, m.c3.z), rotation: Quat(rotationMatrix: r).normalized)
    }

    /// Local (probe) space to world space.
    public var matrix: Mat4 { Mat4(translation: position, rotation: rotation, scale: Vec3(1, 1, 1)) }
    /// World space to local space.
    public var inverse: Mat4 { matrix.inverse }

    public func toWorld(_ p: Vec3) -> Vec3 { position + rotation * p }
    public func toLocal(_ p: Vec3) -> Vec3 { rotation.conjugate * (p - position) }

    /// Rounded to tenths of a millimeter (and the rotation to 1e-4), so float noise from
    /// recomputing transforms doesn't change bake keys.
    var keyFields: [Float] {
        let q = rotation.vector.w < 0 ? Quat(vector: -rotation.vector) : rotation
        return [position.x, position.y, position.z].map { ($0 * 1e4).rounded() / 1e4 }
            + [q.x, q.y, q.z, q.w].map { ($0 * 1e4).rounded() / 1e4 }
    }
}

/// The math the probe shaders use (probes.glsl), on the CPU for tests and tools.
public enum LightProbeMath {
    /// The six capture faces in the probe's space, in order +X, -X, +Y, -Y, +Z, -Z: the direction
    /// each looks in and its up. Must match probe_equirect.frag.
    public static let faces: [(forward: Vec3, up: Vec3)] = [
        (Vec3(1, 0, 0), Vec3(0, 1, 0)), (Vec3(-1, 0, 0), Vec3(0, 1, 0)),
        (Vec3(0, 1, 0), Vec3(0, 0, 1)), (Vec3(0, -1, 0), Vec3(0, 0, -1)),
        (Vec3(0, 0, 1), Vec3(0, 1, 0)), (Vec3(0, 0, -1), Vec3(0, 1, 0)),
    ]

    /// The face direction `d` (probe space, unit) falls on and where on it: texture coordinates
    /// with v = 0 at the top, as the face's 90° camera (`faceView`) renders it.
    public static func face(of d: Vec3) -> (face: Int, uv: Vec2) {
        let a = simdAbs(d)
        let face = a.x >= a.y && a.x >= a.z ? (d.x >= 0 ? 0 : 1) : a.y >= a.z ? (d.y >= 0 ? 2 : 3) : (d.z >= 0 ? 4 : 5)
        let (f, u) = faces[face]
        let r = cross(f, u)
        let z = dot(d, f)
        return (face, Vec2(0.5 + 0.5 * dot(d, r) / z, 0.5 - 0.5 * dot(d, u) / z))
    }

    /// The direction (probe space) at `uv` of face `face`.
    public static func direction(face: Int, uv: Vec2) -> Vec3 {
        let (f, u) = faces[face]
        let r = cross(f, u)
        return normalize(f + r * (uv.x * 2 - 1) - u * (uv.y * 2 - 1))
    }

    /// The view matrix of capture face `face` from `eye`, turned by `rotation` (the probe's).
    public static func faceView(face: Int, eye: Vec3, rotation: Quat) -> Mat4 {
        let (f, u) = faces[face]
        return Mat4.lookAt(eye: eye, target: eye + rotation * f, up: rotation * u)
    }

    /// The square 90° projection the faces render with.
    public static func faceProjection(near: Float, far: Float) -> Mat4 {
        Mat4.perspective(fovY: .pi / 2, aspect: 1, near: max(near, 1e-4), far: max(far, near + 1e-3))
    }

    /// How much a probe's influence box (`half` extents) covers `local` (a point in its space):
    /// 1 at least `blend` inside every face, falling smoothly to 0 at the faces.
    public static func influence(local p: Vec3, half: Vec3, blend: Float) -> Float {
        let d = half - simdAbs(p)
        let inside = min(d.x, min(d.y, d.z))
        guard inside > 0 else { return 0 }
        guard blend > 0 else { return 1 }
        let t = min(inside / blend, 1)
        return t * t * (3 - 2 * t)
    }

    /// The direction to look up in a box-projected probe for the reflected ray `r` (probe space)
    /// leaving `local`: from the capture point toward where the ray leaves the projection box
    /// (`half` extents). A point outside the box is moved onto it first.
    public static func boxProjected(local p: Vec3, ray r: Vec3, half: Vec3, capture: Vec3) -> Vec3 {
        let o = simdClamp(p, -half, half)
        var t = Float.infinity
        for axis in 0..<3 where abs(r[axis]) > 1e-6 {
            let plane = r[axis] > 0 ? half[axis] : -half[axis]
            t = min(t, (plane - o[axis]) / r[axis])
        }
        guard t.isFinite else { return r }
        let d = o + r * max(t, 0) - capture
        return length(d) > 1e-6 ? normalize(d) : r
    }

    /// The smooth backface weight of a probe in direction `toProbe` (unit) from a surface with
    /// normal `n`: 1 straight above the surface, 0.2 straight behind it (probes.glsl).
    public static func backfaceWeight(toProbe: Vec3, normal n: Vec3) -> Float {
        let w = (dot(toProbe, n) + 1) * 0.5
        return w * w + 0.2
    }

    /// Fibonacci-sphere directions, nearly evenly spread (the rays baking tests probes with).
    public static func sphereDirections(_ count: Int) -> [Vec3] {
        let golden = Float.pi * (3 - 5.0.squareRoot().float)
        return (0..<count).map { i in
            let y = 1 - (Float(i) + 0.5) / Float(count) * 2
            let r = max(1 - y * y, 0).squareRoot()
            let a = golden * Float(i)
            return Vec3(cosf(a) * r, y, sinf(a) * r)
        }
    }
}

private extension Double {
    var float: Float { Float(self) }
}

@inline(__always) func simdMax(_ a: Vec3, _ b: Vec3) -> Vec3 { pointwiseMax(a, b) }
@inline(__always) func simdMin(_ a: Vec3, _ b: Vec3) -> Vec3 { pointwiseMin(a, b) }
@inline(__always) func simdMin(_ a: SIMD3<Int>, _ b: SIMD3<Int>) -> SIMD3<Int> { pointwiseMin(a, b) }
@inline(__always) func simdAbs(_ a: Vec3) -> Vec3 { Vec3(abs(a.x), abs(a.y), abs(a.z)) }
@inline(__always) func simdClamp(_ a: Vec3, _ lo: Vec3, _ hi: Vec3) -> Vec3 { pointwiseMin(pointwiseMax(a, lo), hi) }

/// Where a reflection probe's prefiltered image lives in the probe buffer: six equirectangular
/// levels (`EnvironmentMath.equirectUV` layout) for perceptual roughness 0, 0.2, … 1, stored one
/// after another, row by row, two 32-bit words (four half floats, RGBA) per texel. Must match probes.glsl.
public enum ReflectionProbeImage {
    /// The capture faces' size in pixels.
    public static let faceSize = 128
    /// Each level's first texel and size, sharpest first.
    public static let levels: [(offset: Int, width: Int, height: Int)] = [
        (0, 256, 128), (32768, 128, 64), (40960, 64, 32), (43008, 32, 16), (43520, 16, 8), (43648, 8, 4),
    ]
    public static let texelCount = 43680
    /// 32-bit words per probe image.
    public static let wordCount = texelCount * 2
}

/// The captures irradiance probes are baked from: 32 px faces, an equirectangular image of
/// `equirect` texels projected onto nine SH coefficients (env_sh.frag).
public enum IrradianceProbeCapture {
    public static let faceSize = 32
    public static let equirect = (width: 64, height: 32)
    /// Floats per probe in a bake (`IrradianceVolumeBake.coefficients`): nine RGBA coefficients
    /// (alpha of the first: 1, or 0 for a probe inside geometry). The probe buffer holds them as
    /// 28 half floats in 16 words.
    public static let wordCount = 36
}

/// A baked reflection probe: its prefiltered image as packed half floats (`ReflectionProbeImage`).
public struct ReflectionProbeBake: Equatable, Sendable {
    public var key: String
    /// `ReflectionProbeImage.wordCount` words: per texel, (r, g) and (b, a) as two half floats each.
    public var words: [UInt32]

    public init(key: String, words: [UInt32]) {
        self.key = key
        self.words = words
    }

    /// The image's texel at (`x`, `y`) of `level`, decoded (for tests and tools).
    public func texel(level: Int, x: Int, y: Int) -> Vec4 {
        let l = ReflectionProbeImage.levels[level]
        let i = (l.offset + y * l.width + x) * 2
        guard i + 1 < words.count else { return .zero }
        let rg = Self.unpackHalves(words[i]), ba = Self.unpackHalves(words[i + 1])
        return Vec4(rg.x, rg.y, ba.x, ba.y)
    }

    static func unpackHalves(_ word: UInt32) -> Vec2 {
        Vec2(Float(Float16(bitPattern: UInt16(word & 0xFFFF))), Float(Float16(bitPattern: UInt16(word >> 16))))
    }
}

/// A baked irradiance volume: nine RGBA coefficients per probe (x fastest, then y, then z).
public struct IrradianceVolumeBake: Equatable, Sendable {
    public var key: String
    public var counts: SIMD3<Int>
    /// `IrradianceProbeCapture.wordCount` floats per probe: the SH9 coefficients of irradiance / pi
    /// (`EnvironmentMath.projectIrradianceSH`) in the volume's space, the first's alpha its validity.
    public var coefficients: [Float]

    public init(key: String, counts: SIMD3<Int>, coefficients: [Float]) {
        self.key = key
        self.counts = counts
        self.coefficients = coefficients
    }

    public var probeCount: Int { counts.x * counts.y * counts.z }

    /// Probe `index`'s nine coefficients (RGB).
    public func sh(of index: Int) -> [Vec3] {
        let base = index * IrradianceProbeCapture.wordCount
        guard base + IrradianceProbeCapture.wordCount <= coefficients.count else { return Array(repeating: .zero, count: 9) }
        return (0..<9).map { Vec3(coefficients[base + $0 * 4], coefficients[base + $0 * 4 + 1], coefficients[base + $0 * 4 + 2]) }
    }

    /// Whether probe `index` is used (false: it was inside geometry).
    public func isValid(_ index: Int) -> Bool {
        let i = index * IrradianceProbeCapture.wordCount + 3
        return i < coefficients.count && coefficients[i] > 0.5
    }

    /// Irradiance / pi at `point` (world space) for a surface with normal `normal`, interpolated
    /// like the shader does for `volume` at `frame` (with its biases toward `viewer` when given):
    /// what a white diffuse surface there reflects. Nil outside the box.
    public func irradiance(at point: Vec3, normal: Vec3, viewer: Vec3? = nil, volume: IrradianceVolume, frame: LightProbeFrame) -> Vec3? {
        let n = counts
        guard n.x > 0, n.y > 0, n.z > 0 else { return nil }
        let half = volume.halfExtents
        let localNormal = frame.rotation.conjugate * normal
        let p = frame.toLocal(point)
        guard LightProbeMath.influence(local: p, half: half, blend: 0) > 0 else { return nil }
        var biased = point + normal * volume.normalBias
        if let viewer { biased += normalize(viewer - point) * volume.viewBias }
        let q = frame.toLocal(biased)
        let cells = Vec3(Float(n.x), Float(n.y), Float(n.z))
        let g = simdClamp((q + half) / simdMax(half * 2, Vec3(repeating: 1e-6)) * cells - 0.5, .zero, cells - 1)
        let g0 = simdMin(SIMD3<Int>(Int(g.x), Int(g.y), Int(g.z)), SIMD3(max(n.x - 2, 0), max(n.y - 2, 0), max(n.z - 2, 0)))
        let f = g - Vec3(Float(g0.x), Float(g0.y), Float(g0.z))
        var coefficients = [Vec3](repeating: .zero, count: 9), total: Float = 0
        for corner in 0..<8 {
            let o = SIMD3(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1)
            let c = simdMin(g0 &+ o, n &- 1)
            let index = c.x + n.x * (c.y + n.y * c.z)
            guard isValid(index) else { continue }
            let t = Vec3(o.x == 1 ? f.x : 1 - f.x, o.y == 1 ? f.y : 1 - f.y, o.z == 1 ? f.z : 1 - f.z)
            let toProbe = volume.localPosition(cell: c) - p
            let back = LightProbeMath.backfaceWeight(toProbe: length(toProbe) > 1e-5 ? normalize(toProbe) : .zero, normal: localNormal)
            let w = t.x * t.y * t.z * back
            for (k, c) in sh(of: index).enumerated() { coefficients[k] += c * w }
            total += w
        }
        return total > 1e-5 ? EnvironmentMath.irradiance(coefficients, normal: localNormal) / total : nil
    }
}

/// What a probe bake found (`SceneRenderer.bakeProbes`, `lighting.bake`).
public struct LightProbeBakeReport: Codable, Equatable, Sendable {
    public var reflectionProbes = 0
    public var irradianceVolumes = 0
    /// Irradiance probes baked, and how many of them were inside geometry (turned off).
    public var irradianceProbes = 0
    public var probesInsideGeometry = 0
    /// Bounces baked (the most any volume asked for).
    public var bounces = 0
    /// From the start of the bake until its results were read back (GPU time included).
    public var milliseconds: Double = 0
    /// Probes that couldn't be baked well: inside geometry, an empty box, a volume without probes.
    public var warnings: [String] = []
    /// Bakes written to the project's Library (file names in Library/Lighting).
    public var cacheFiles: [String] = []

    public init() {}
}

/// Baked probes by key: files in a folder (the project's `Library/Lighting`), and read-only
/// entries of an asset pack (exported games, which the cooker gives every file in `Library/Lighting`).
public final class LightProbeBakeCache: @unchecked Sendable {
    /// Bumped when baking changes, so older cached bakes are baked again.
    public static let bakeVersion = 1
    /// The file extension of cached probes.
    public static let fileExtension = "lightprobe"
    /// The folder under the project's Library.
    public static let libraryFolder = "Lighting"
    /// At most this many files stay in a folder (the oldest go).
    public var maxFiles = 512

    public let directory: URL?
    private let packed: (String) -> Data?

    /// A cache in `directory` (created when something is stored).
    public init(directory: URL) {
        self.directory = directory
        packed = { _ in nil }
    }

    /// The probes cooked into `pack` (read-only).
    public init(pack: AssetPack) {
        directory = nil
        packed = { key in
            guard let blob = pack.manifest.lighting?[key] else { return nil }
            return try? pack.bytes(of: blob)
        }
    }

    /// The cache for `assets`: its pack's probes, or its project's `Library/Lighting`.
    @MainActor
    public static func forAssets(_ assets: AssetDatabase) -> LightProbeBakeCache {
        if let pack = assets.pack { return LightProbeBakeCache(pack: pack) }
        return LightProbeBakeCache(directory: assets.project.libraryURL.appendingPathComponent(libraryFolder, isDirectory: true))
    }

    static func hash(_ fields: [Float]) -> String {
        var data = Data()
        for f in fields { withUnsafeBytes(of: f.bitPattern.littleEndian) { data.append(contentsOf: $0) } }
        return ContentHash.hex(data)
    }

    func url(_ key: String) -> URL? { directory?.appendingPathComponent(key + "." + Self.fileExtension) }

    private func data(_ key: String) -> Data? {
        if let url = url(key) { return try? Data(contentsOf: url) }
        return packed(key)
    }

    public func loadReflection(key: String) -> ReflectionProbeBake? {
        guard let file = data(key).flatMap(LightProbeFile.init), file.kind == 0, file.words.count == ReflectionProbeImage.wordCount else { return nil }
        return ReflectionProbeBake(key: key, words: file.words)
    }

    public func loadVolume(key: String) -> IrradianceVolumeBake? {
        guard let file = data(key).flatMap(LightProbeFile.init), file.kind == 1 else { return nil }
        let bake = IrradianceVolumeBake(key: key, counts: file.counts, coefficients: file.words.map { Float(bitPattern: $0) })
        guard bake.coefficients.count == bake.probeCount * IrradianceProbeCapture.wordCount else { return nil }
        return bake
    }

    /// Caches `bake` (no-op for a pack); returns the file name.
    @discardableResult
    public func store(_ bake: ReflectionProbeBake) -> String? {
        store(LightProbeFile(kind: 0, counts: .zero, words: bake.words), key: bake.key)
    }

    @discardableResult
    public func store(_ bake: IrradianceVolumeBake) -> String? {
        store(LightProbeFile(kind: 1, counts: bake.counts, words: bake.coefficients.map(\.bitPattern)), key: bake.key)
    }

    private func store(_ file: LightProbeFile, key: String) -> String? {
        guard let directory, let url = url(key) else { return nil }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try file.data.write(to: url, options: .engineAtomic)
            prune()
            return url.lastPathComponent
        } catch {
            EngineLog.warning("Lighting: couldn't cache a probe bake in \(directory.path): \(error)")
            return nil
        }
    }

    /// Every cached probe file in a folder, by key.
    public static func files(in directory: URL) -> [String: URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var out: [String: URL] = [:]
        for url in urls where url.pathExtension == fileExtension { out[url.deletingPathExtension().lastPathComponent] = url }
        return out
    }

    private func prune() {
        guard let directory else { return }
        let files = Self.files(in: directory).values
        guard files.count > maxFiles else { return }
        let dated = files.map { url in
            (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
        for (url, _) in dated.sorted(by: { $0.1 < $1.1 }).prefix(files.count - maxFiles) { try? FileManager.default.removeItem(at: url) }
    }
}

/// A cached probe file: "ALPB", version, kind (0 reflection, 1 irradiance), the volume's counts,
/// the word count and the words, all little-endian UInt32.
struct LightProbeFile {
    var kind: UInt32
    var counts: SIMD3<Int>
    var words: [UInt32]

    init(kind: UInt32, counts: SIMD3<Int>, words: [UInt32]) {
        self.kind = kind
        self.counts = counts
        self.words = words
    }

    init?(_ data: Data) {
        guard data.count >= 28, data.prefix(4) == Data("ALPB".utf8) else { return nil }
        func word(_ i: Int) -> UInt32 {
            data.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: i * 4, as: UInt32.self)) }
        }
        guard word(1) == UInt32(LightProbeBakeCache.bakeVersion) else { return nil }
        let count = Int(word(6))
        guard data.count == 28 + count * 4 else { return nil }
        kind = word(2)
        counts = SIMD3(Int(word(3)), Int(word(4)), Int(word(5)))
        words = data.withUnsafeBytes { raw in (0..<count).map { UInt32(littleEndian: raw.loadUnaligned(fromByteOffset: 28 + $0 * 4, as: UInt32.self)) } }
    }

    var data: Data {
        var out = Data("ALPB".utf8)
        out.reserveCapacity(28 + words.count * 4)
        for w in [UInt32(LightProbeBakeCache.bakeVersion), kind, UInt32(counts.x), UInt32(counts.y), UInt32(counts.z), UInt32(words.count)] + words {
            withUnsafeBytes(of: w.littleEndian) { out.append(contentsOf: $0) }
        }
        return out
    }
}

/// Debug views of the light probes (`SceneRenderer.probeDebug`, `lighting.debug`).
public struct LightProbeDebug: Equatable, Sendable {
    /// Draw a sphere at every probe: reflection probes as mirror balls showing their image,
    /// irradiance probes shaded by their SH (probes inside geometry in red).
    public var showsProbes = false
    /// Shade every surface with its indirect diffuse light only (white albedo): the probes', the
    /// sky's or the hemisphere's.
    public var irradianceOnly = false

    public init(showsProbes: Bool = false, irradianceOnly: Bool = false) {
        self.showsProbes = showsProbes
        self.irradianceOnly = irradianceOnly
    }
}

extension LightProbeDebug {
    /// Draws every enabled probe's boxes into `draw`: reflection probes' influence boxes (cyan),
    /// their inner blend boxes and projection boxes (dimmer), irradiance volumes (orange) with a
    /// point per probe.
    @MainActor
    public static func drawVolumes(of world: World, into draw: DebugDraw) {
        world.query(ReflectionProbe.self) { entity, probe in
            guard probe.isEnabled else { return }
            let frame = LightProbeFrame(world: world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity))
            let half = probe.halfExtents
            draw.box(center: frame.position, halfExtent: half, rotation: frame.rotation, color: Vec4(0.2, 0.9, 1, 1))
            let inner = simdMax(half - probe.blendDistance, .zero)
            if probe.blendDistance > 0, inner != half {
                draw.box(center: frame.position, halfExtent: inner, rotation: frame.rotation, color: Vec4(0.2, 0.9, 1, 0.35))
            }
            if probe.boxProjection, probe.projectionHalfExtents != half {
                draw.box(center: frame.position, halfExtent: probe.projectionHalfExtents, rotation: frame.rotation, color: Vec4(0.6, 0.6, 1, 0.6))
            }
            draw.sphere(center: frame.toWorld(probe.captureOffset), radius: 0.15, color: Vec4(0.2, 0.9, 1, 1))
        }
        world.query(IrradianceVolume.self) { entity, volume in
            guard volume.isEnabled else { return }
            let frame = LightProbeFrame(world: world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity))
            draw.box(center: frame.position, halfExtent: volume.halfExtents, rotation: frame.rotation, color: Vec4(1, 0.6, 0.15, 1))
            guard volume.probeCount <= 4096 else { return }
            for i in 0..<volume.probeCount {
                let p = frame.toWorld(volume.localPosition(of: i))
                draw.line(p - Vec3(0.05, 0, 0), p + Vec3(0.05, 0, 0), color: Vec4(1, 0.6, 0.15, 1))
                draw.line(p - Vec3(0, 0.05, 0), p + Vec3(0, 0.05, 0), color: Vec4(1, 0.6, 0.15, 1))
            }
        }
    }
}
