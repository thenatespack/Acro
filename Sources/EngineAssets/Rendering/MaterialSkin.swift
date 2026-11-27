#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

// Skin and eye shading (roadmap 13A): the optional `Material` / `MaterialAsset` blocks that switch
// a PBR material to the skin shader variant (mesh_skin.frag, skin.glsl), the `skin` and `eye`
// presets, the separable subsurface scattering kernel (subsurface_blur.frag) and the eyeball mesh
// the eye shader expects. Everything is off by default: a material without these blocks draws
// exactly as before, and a frame without subsurface materials runs no extra pass.
//
// Research applied (see Tools.md "Skin and eyes"):
// - Jimenez, Zsolnai, Jarabo, Freude, Auzinger, Wu, von der Pahlen, Wimmer, Gutierrez,
//   "Separable Subsurface Scattering", Computer Graphics Forum 2015 (and its Activision tech
//   report / reference code): the screen-space kernel below, two 1D passes over the diffuse light
//   of subsurface pixels, widened by a per-material world width and shrunk with distance.
// - Jimenez, Whelan, Sundstedt, Gutierrez, "Real-Time Realistic Skin Translucency", IEEE CG&A
//   2010: light through thin parts (ears, nostrils, fingers) from the thickness the shadow map
//   sees, through d'Eon's skin profile.
// - Penner, "Pre-Integrated Skin Shading", GPU Pro 2 (2011): the fallback where the screen pass
//   can't run (WebGL 2, low quality, `ENGINE_SSS=preintegrated`): diffuse light pre-convolved with
//   the profile around a ring whose radius is the surface's curvature, which comes from the
//   normal's screen derivatives.
// - Dual-lobe specular (two GGX lobes, roughness x 0.75 and x 1.3 mixed 85 / 15, as in Unreal's
//   and Activision's skin) and a procedural micro normal (pores and fine creases, faded out by
//   pixel footprint) so skin doesn't look like plastic.
// - Jimenez, "Next-Generation Character Rendering", GDC 2013, for the eye: a wet cornea with a
//   sharp highlight and the environment's reflection, the iris seen through it with refraction,
//   a darker limbal ring, a slightly blue-grey veined sclera with soft shading and occlusion
//   toward the corners.

/// Light scattering under the surface (skin, wax, marble, leaves): with the screen-space pass the
/// diffuse light of these pixels is blurred by the skin profile (separable subsurface
/// scattering); without it (WebGL 2, low quality) the shader pre-integrates the profile over the
/// surface's curvature. `transmission` lets light through thin parts (ears, nostrils, fingers).
public struct MaterialSubsurface: Equatable, Sendable, Codable {
    /// 0 none ... 1 Jimenez's skin default (about half the red light, a quarter of the blue
    /// scattered) ... 2 a lot. Scales every channel's scattered share.
    public var strength: Float
    /// How far light spreads under the surface, in meters: the kernel's full reach. Real skin is
    /// a few millimeters; 0.004...0.012 reads well at character scale.
    public var radius: Float
    /// How far each channel travels relative to `radius` (Jimenez's falloff): red furthest in skin.
    public var falloff: Vec3
    /// 0...1: light passing through thin parts lit from behind (ears glowing red). 0: none.
    public var transmission: Float

    public init(strength: Float = 1, radius: Float = 0.008, falloff: Vec3 = Vec3(1, 0.37, 0.3), transmission: Float = 0.5) {
        self.strength = strength
        self.radius = radius
        self.falloff = falloff
        self.transmission = transmission
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialSubsurface()
        self.init(strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength,
                  radius: try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius,
                  falloff: try c.decodeIfPresent(Vec3.self, forKey: .falloff) ?? d.falloff,
                  transmission: try c.decodeIfPresent(Float.self, forKey: .transmission) ?? d.transmission)
    }

    /// Jimenez's per-channel strength at `strength` 1 (the reference code's default).
    public static let skinStrength = Vec3(0.48, 0.41, 0.28)

    /// The share of each channel's diffuse light that scatters (0...1).
    public var channelStrength: Vec3 {
        let s = min(max(strength.isFinite ? strength : 0, 0), 2)
        return Vec3(min(Self.skinStrength.x * s, 1), min(Self.skinStrength.y * s, 1), min(Self.skinStrength.z * s, 1))
    }
}

/// Two GGX specular lobes instead of one, mixed: skin's oily top layer gives a tight highlight
/// over a broad sheen. Roughnesses are the material's roughness times these factors.
public struct MaterialSpecularLobes: Equatable, Sendable, Codable {
    /// Roughness factors of the two lobes.
    public var roughness: Vec2
    /// 0...1: the second (broad) lobe's weight.
    public var mix: Float

    public init(roughness: Vec2 = Vec2(0.75, 1.3), mix: Float = 0.15) {
        self.roughness = roughness
        self.mix = mix
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialSpecularLobes()
        self.init(roughness: try c.decodeIfPresent(Vec2.self, forKey: .roughness) ?? d.roughness,
                  mix: try c.decodeIfPresent(Float.self, forKey: .mix) ?? d.mix)
    }
}

/// A procedural micro normal: pores and fine creases in the mesh's own space (so they stay put as
/// a skinned mesh moves), faded out where they'd be smaller than a pixel.
public struct MaterialDetailNormal: Equatable, Sendable, Codable {
    /// 0 none ... 1 strong bumps.
    public var strength: Float
    /// Pores per meter of the mesh's own space (700: about 1.4 mm apart).
    public var scale: Float

    public init(strength: Float = 0.15, scale: Float = 700) {
        self.strength = strength
        self.scale = scale
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialDetailNormal()
        self.init(strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength,
                  scale: try c.decodeIfPresent(Float.self, forKey: .scale) ?? d.scale)
    }
}

/// An eyeball, shaded procedurally in one material: wet cornea, refracted iris with a pupil and a
/// darker limbal ring, veined sclera. The mesh needs the eye's UV layout (`MeshGeometry.eyeball`):
/// on the front half, uv = 0.5 + 0.5 x (x, y) / radius in the eye's own frame (+Z the gaze, +Y up),
/// so the iris is centered at uv (0.5, 0.5); the back half maps outside that disc and shows sclera.
public struct MaterialEye: Equatable, Sendable, Codable {
    /// Linear iris color (the pattern varies around it).
    public var irisColor: Vec3
    /// Iris radius over eyeball radius (a human's is about 0.5).
    public var irisSize: Float
    /// Pupil radius over iris radius (0.2 bright light ... 0.6 dark).
    public var pupilSize: Float
    /// 0...1: how dark the ring at the iris edge is.
    public var limbalRing: Float
    /// Linear sclera color.
    public var scleraColor: Vec3
    /// 0...1: red veins toward the corners.
    public var veins: Float
    /// How deep the iris sits under the cornea's apex, in eyeball radii (refraction parallax).
    public var irisDepth: Float

    public init(irisColor: Vec3 = Vec3(0.09, 0.2, 0.32), irisSize: Float = 0.5, pupilSize: Float = 0.36, limbalRing: Float = 0.7,
                scleraColor: Vec3 = Vec3(0.74, 0.72, 0.72), veins: Float = 0.35, irisDepth: Float = 0.22) {
        self.irisColor = irisColor
        self.irisSize = irisSize
        self.pupilSize = pupilSize
        self.limbalRing = limbalRing
        self.scleraColor = scleraColor
        self.veins = veins
        self.irisDepth = irisDepth
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MaterialEye()
        self.init(irisColor: try c.decodeIfPresent(Vec3.self, forKey: .irisColor) ?? d.irisColor,
                  irisSize: try c.decodeIfPresent(Float.self, forKey: .irisSize) ?? d.irisSize,
                  pupilSize: try c.decodeIfPresent(Float.self, forKey: .pupilSize) ?? d.pupilSize,
                  limbalRing: try c.decodeIfPresent(Float.self, forKey: .limbalRing) ?? d.limbalRing,
                  scleraColor: try c.decodeIfPresent(Vec3.self, forKey: .scleraColor) ?? d.scleraColor,
                  veins: try c.decodeIfPresent(Float.self, forKey: .veins) ?? d.veins,
                  irisDepth: try c.decodeIfPresent(Float.self, forKey: .irisDepth) ?? d.irisDepth)
    }

    /// Iris colors for the presets (linear).
    public static let blue = Vec3(0.09, 0.2, 0.32)
    public static let green = Vec3(0.11, 0.2, 0.09)
    public static let hazel = Vec3(0.22, 0.14, 0.06)
    public static let brown = Vec3(0.12, 0.055, 0.025)
    public static let grey = Vec3(0.2, 0.22, 0.24)
}

/// Skin tones for `MaterialAsset.skin(_:)`, light to deep.
public enum SkinTone: String, Sendable, Codable, CaseIterable {
    case pale, light, medium, tan, brown, deep

    /// The base color, sRGB 0...1 (measured-skin-like albedos, not saturated).
    public var sRGB: Vec3 {
        switch self {
        case .pale: Vec3(0.93, 0.80, 0.72)
        case .light: Vec3(0.88, 0.70, 0.59)
        case .medium: Vec3(0.78, 0.57, 0.44)
        case .tan: Vec3(0.67, 0.46, 0.32)
        case .brown: Vec3(0.47, 0.30, 0.20)
        case .deep: Vec3(0.30, 0.19, 0.13)
        }
    }

    /// `sRGB` as linear color.
    public var linear: Vec3 {
        func decode(_ x: Float) -> Float { x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4) }
        return Vec3(decode(sRGB.x), decode(sRGB.y), decode(sRGB.z))
    }
}

extension MaterialAsset {
    /// The skin preset: PBR, subsurface scattering with transmission, two specular lobes and pores.
    /// Exposed skin of characters uses it (the material named `skin`).
    public static func skin(_ tone: SkinTone = .medium) -> MaterialAsset {
        let color = tone.linear
        var asset = MaterialAsset(shading: .pbr, baseColor: Vec4(color.x, color.y, color.z, 1), metallic: 0, roughness: 0.5)
        asset.subsurface = MaterialSubsurface()
        asset.specularLobes = MaterialSpecularLobes()
        asset.detailNormal = MaterialDetailNormal()
        return asset
    }

    /// The eye preset (one material for the whole eyeball; the mesh needs `MeshGeometry.eyeball`'s
    /// UV layout). Eyeballs use it (the material named `eye`).
    public static func eye(iris: Vec3 = MaterialEye.blue) -> MaterialAsset {
        var asset = MaterialAsset(shading: .pbr, baseColor: Vec4(1, 1, 1, 1), metallic: 0, roughness: 0.05)
        asset.eye = MaterialEye(irisColor: iris)
        return asset
    }
}

extension Material {
    /// Whether it draws with the skin shader variant (mesh_skin.frag): PBR with a subsurface,
    /// specular lobes, detail normal or eye block, not a graph or fur.
    package var usesSkinShading: Bool {
        shading == .pbr && graph == nil && fur == nil
            && (subsurface != nil || specularLobes != nil || detailNormal != nil || eye != nil)
    }

    /// Whether its pixels take part in the screen-space subsurface pass.
    package var scattersInScreenSpace: Bool {
        usesSkinShading && eye == nil && (subsurface?.channelStrength ?? .zero) != .zero && (subsurface?.radius ?? 0) > 0
    }

    /// The skin material presets as `Material`s (no textures).
    public static func skin(_ tone: SkinTone = .medium) -> Material { MaterialAsset.skin(tone).material(texture: nil) }
    public static func eye(iris: Vec3 = MaterialEye.blue) -> Material { MaterialAsset.eye(iris: iris).material(texture: nil) }
}

/// How skin materials scatter light this frame (`ENGINE_SSS`, quality and backend).
public enum SubsurfaceMode: String, Sendable, CaseIterable {
    /// The screen-space separable pass (default where the HDR post chain runs).
    case screen
    /// Penner's pre-integrated shading in the material shader only (WebGL 2, low quality).
    case preintegrated
    /// No scattering or transmission (lobes, pores and eyes still apply): the "before" look.
    case off

    /// `ENGINE_SSS` (`screen`/`1`/`on`, `preintegrated`, `off`/`0`), nil when unset or unknown.
    public static func environment(_ value: String?) -> SubsurfaceMode? {
        switch value?.lowercased() {
        case "screen", "1", "on": .screen
        case "preintegrated", "pre", "preintegrate": .preintegrated
        case "off", "0", "none": .off
        default: nil
        }
    }
}

/// Jimenez's separable subsurface scattering kernel (SeparableSSS::calculateKernel in the 2015
/// reference code): `count` taps, offsets in -range...range profile units (millimeters of the
/// skin profile; the shader maps range to `MaterialSubsurface.radius` in the world), weights from
/// d'Eon's skin profile (the red channel's five wide Gaussians, each channel widened by its
/// falloff), normalized per channel, then mixed toward the identity by the channel strength. Tap
/// 0 is the center.
public struct SubsurfaceKernel: Equatable, Sendable {
    /// xyz: per-channel weight, w: offset in profile units.
    public var taps: [Vec4]
    public var range: Float

    public init(strength: Vec3, falloff: Vec3, count: Int = 17) {
        let n = max(count | 1, 3)  // odd
        let range: Float = n > 20 ? 3 : 2
        self.range = range
        let exponent: Float = 2
        let step = 2 * range / Float(n - 1)
        var kernel = (0..<n).map { i -> Vec4 in
            let o = -range + Float(i) * step
            let sign: Float = o < 0 ? -1 : 1
            return Vec4(0, 0, 0, range * sign * abs(powf(o, exponent)) / powf(range, exponent))
        }
        for i in 0..<n {
            let w0 = i > 0 ? abs(kernel[i].w - kernel[i - 1].w) : 0
            let w1 = i < n - 1 ? abs(kernel[i].w - kernel[i + 1].w) : 0
            let area = (w0 + w1) / 2
            let t = Self.profile(kernel[i].w, falloff: falloff) * area
            kernel[i] = Vec4(t.x, t.y, t.z, kernel[i].w)
        }
        // The center first.
        let center = kernel.remove(at: n / 2)
        kernel.insert(center, at: 0)
        var sum = Vec3.zero
        for k in kernel { sum += Vec3(k.x, k.y, k.z) }
        for i in 0..<n {
            kernel[i].x /= max(sum.x, 1e-12)
            kernel[i].y /= max(sum.y, 1e-12)
            kernel[i].z /= max(sum.z, 1e-12)
        }
        // lerp(1, k0, strength) for the center, lerp(0, k, strength) for the others: weights still sum to 1.
        kernel[0].x = (1 - strength.x) + strength.x * kernel[0].x
        kernel[0].y = (1 - strength.y) + strength.y * kernel[0].y
        kernel[0].z = (1 - strength.z) + strength.z * kernel[0].z
        for i in 1..<n {
            kernel[i].x *= strength.x
            kernel[i].y *= strength.y
            kernel[i].z *= strength.z
        }
        taps = kernel
    }

    /// One Gaussian of the profile, widened per channel by `falloff`.
    static func gaussian(_ variance: Float, _ r: Float, falloff: Vec3) -> Vec3 {
        func g(_ f: Float) -> Float {
            let rr = r / (0.001 + f)
            return expf(-(rr * rr) / (2 * variance)) / (2 * 3.14 * variance)
        }
        return Vec3(g(falloff.x), g(falloff.y), g(falloff.z))
    }

    /// d'Eon's skin profile without its narrowest Gaussian (that light counts as unscattered).
    static func profile(_ r: Float, falloff: Vec3) -> Vec3 {
        gaussian(0.0484, r, falloff: falloff) * 0.100 + gaussian(0.187, r, falloff: falloff) * 0.118
            + gaussian(0.567, r, falloff: falloff) * 0.113 + gaussian(1.99, r, falloff: falloff) * 0.358
            + gaussian(7.41, r, falloff: falloff) * 0.078
    }
}

extension MeshGeometry {
    /// An eyeball for `MaterialEye`: a sphere of `radius` around the origin looking down +Z (+Y
    /// up), with a cornea bulging `cornea` radii over the iris (`irisSize` radii wide), and the
    /// eye's UV layout: the front half planar along the gaze, uv = 0.5 + 0.5 (x, y) / radius (u
    /// right, v up, so the iris is centered at (0.5, 0.5)); the back half outside that disc. Every
    /// tangent is the eye's +X axis (w 1), which the eye shader reads as its frame. Place one per
    /// eye, its +Z along the gaze. Merging it into another mesh (a skinned body) keeps working if
    /// the tangents are transformed with the positions and not regenerated.
    public static func eyeball(radius: Float = 0.012, segments: Int = 48, rings: Int = 32, irisSize: Float = 0.5,
                               cornea: Float = 0.08) -> MeshGeometry {
        precondition(segments >= 3 && rings >= 2)
        var geometry = MeshGeometry(vertices: [], indices: [])
        let irisAngle = asinf(min(max(irisSize, 0.05), 0.95))
        for ring in 0...rings {
            // From the front pole (+Z) to the back (-Z).
            let theta = Float(ring) / Float(rings) * .pi
            for segment in 0...segments {
                let phi = Float(segment) / Float(segments) * 2 * .pi
                let d = Vec3(sinf(theta) * cosf(phi), sinf(theta) * sinf(phi), cosf(theta))
                // The cornea: a smooth bulge over the iris, fading out at the limbus.
                let t = min(theta / irisAngle, 1)
                let bulge = cornea * (1 - t * t) * (1 - t * t)
                let position = d * (radius * (1 + bulge))
                // On the bulge's flank the normal leans away from the gaze axis (-dr/dθ / r along θ).
                let slope = cornea * 4 * t * (1 - t * t) / irisAngle
                let tangentialOut = Vec3(cosf(theta) * cosf(phi), cosf(theta) * sinf(phi), -sinf(theta))
                let normal = theta < irisAngle ? normalize(d + tangentialOut * slope / (1 + bulge)) : d
                let uv: Vec2
                if d.z >= 0 {
                    uv = Vec2(0.5 + 0.5 * d.x, 0.5 + 0.5 * d.y)
                } else {
                    // Outside the front disc: radius 1 ... 2 (in uv half-widths) toward the back pole.
                    let r = 2 - abs(sinf(theta))
                    uv = Vec2(0.5 + 0.5 * cosf(phi) * r, 0.5 + 0.5 * sinf(phi) * r)
                }
                // The tangent is the eye's own +X axis everywhere (the eye shader's frame), not dP/du.
                geometry.vertices.append(MeshVertex(position: position, normal: normal, uv: uv, tangent: Vec4(1, 0, 0, 1)))
            }
        }
        let stride = UInt32(segments + 1)
        for ring in 0..<UInt32(rings) {
            for segment in 0..<UInt32(segments) {
                let a = ring * stride + segment, b = a + 1, c = a + stride, d = c + 1
                // Counter-clockwise seen from outside (as `sphere`).
                if ring != 0 { geometry.indices += [a, c, b] }
                if ring != UInt32(rings) - 1 { geometry.indices += [b, c, d] }
            }
        }
        return geometry
    }
}

/// The skin shader's push constants (mesh_skin.frag's `SkinPush`, skin.glsl): 7 vec4s.
package struct SkinPushConstants: BitwiseCopyable, Equatable {
    /// rgb: subsurface falloff, w: subsurface strength (0: none).
    var subsurface: Vec4
    /// x: radius (m), y: transmission, z: 1 eye, w: 1 the screen pass scatters these pixels
    /// (alpha carries the specular), 0 pre-integrated.
    var scatter: Vec4
    /// x, y: lobe roughness factors, z: second lobe weight, w: 1 with two lobes.
    var lobes: Vec4
    /// x: detail strength, y: detail frequency (per meter), zw: unused.
    var detail: Vec4
    /// Eye: rgb iris color, w iris size.
    var iris: Vec4
    /// Eye: rgb sclera color, w pupil size.
    var sclera: Vec4
    /// Eye: x limbal ring, y veins, z iris depth.
    var eye: Vec4

    package init(_ material: Material, mode: SubsurfaceMode, screenPass: Bool) {
        let s = mode == .off ? nil : material.subsurface
        let strength = s.map { min(max($0.strength.isFinite ? $0.strength : 0, 0), 2) } ?? 0
        subsurface = Vec4(s?.falloff ?? Vec3(1, 0.37, 0.3), strength)
        scatter = Vec4(max(s?.radius ?? 0, 0), min(max(s?.transmission ?? 0, 0), 1), material.eye != nil ? 1 : 0,
                       screenPass && material.scattersInScreenSpace && mode == .screen ? 1 : 0)
        if let lobes = material.specularLobes {
            self.lobes = Vec4(max(lobes.roughness.x, 0.05), max(lobes.roughness.y, 0.05), min(max(lobes.mix, 0), 1), 1)
        } else {
            lobes = Vec4(1, 1, 0, 0)
        }
        let d = material.detailNormal
        detail = Vec4(max(d?.strength ?? 0, 0), max(d?.scale ?? 0, 0), 0, 0)
        let e = material.eye ?? MaterialEye()
        iris = Vec4(e.irisColor, min(max(e.irisSize, 0.05), 0.95))
        sclera = Vec4(e.scleraColor, min(max(e.pupilSize, 0.02), 0.95))
        eye = Vec4(min(max(e.limbalRing, 0), 1), min(max(e.veins, 0), 1), max(e.irisDepth, 0), 0)
    }
}
