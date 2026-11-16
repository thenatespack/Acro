import Engine
import Foundation

// The light mesh builds are shown in by `meshBuild.preview` and the Mesh Builder tab. Metals
// only look like metal when they have something to reflect, so the default is a photo studio:
// an HDR environment map made here (no asset) that lights the model through the engine's
// image-based lighting (`SceneEnvironment.sky = .map`: SH9 diffuse irradiance and GGX-prefiltered
// reflections, EnvironmentLighting.swift), next to the usual key light.
//
// The studio is neutral gray, so colors read true: walls brightening softly from the horizon to
// the ceiling, a faint lighter band just above the horizon, a darker floor, and five white
// softboxes (a big key front right and above, a dimmer fill front left, a long strip overhead
// and two narrow rim strips behind). The preview's orthographic views look straight along the
// horizon or straight down, so their background stays one flat gray close to the old one.

/// What a mesh build is lit by in previews (`meshBuild.preview {environment}`) and the Mesh Builder tab.
public enum MeshBuildPreviewEnvironment: String, Codable, CaseIterable, Sendable {
    /// A neutral photo studio (an HDR map with softboxes) lighting the model and reflected by it (default).
    case studio
    /// The procedural sky (blue above, ground below, the sun's glow), as outdoors.
    case outdoor
    /// The hemisphere ambient alone (no image-based lighting, nothing to reflect): the old look.
    case flat

    /// The key the studio map is registered under with a `SceneRenderer` (`registerStudio(in:)`).
    static let studioTextureKey = "editor:meshBuildStudio"
    static let studioSize = (width: 512, height: 256)

    /// The scene's `SceneEnvironment` for this light.
    var sceneEnvironment: SceneEnvironment {
        switch self {
        case .studio:
            SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0, sky: .map, environmentMap: TextureHandle(Self.studioTextureKey))
        case .outdoor:
            SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0, sky: .procedural)
        case .flat:
            SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0)
        }
    }

    /// Uploads the studio map to `renderer` (call once per renderer).
    @MainActor static func registerStudio(in renderer: SceneRenderer) {
        do {
            renderer.registerTexture(try renderer.device.makeTexture(image: studioImage), key: studioTextureKey)
        } catch {
            print("Mesh Builder: the studio light map can't be uploaded: \(error)")
        }
    }

    /// The studio map (made once).
    static let studioImage = studio(width: studioSize.width, height: studioSize.height)

    /// A softbox: centered at `azimuth` (degrees, 0 toward -Z, 90 toward +X) and `elevation`
    /// (degrees above the horizon), `halfWidth` x `halfHeight` degrees, of `radiance`.
    struct Softbox {
        var azimuth: Float
        var elevation: Float
        var halfWidth: Float
        var halfHeight: Float
        var radiance: Float
    }

    static let softboxes = [
        Softbox(azimuth: 40, elevation: 32, halfWidth: 22, halfHeight: 15, radiance: 2.6),   // key, front right
        Softbox(azimuth: -55, elevation: 22, halfWidth: 18, halfHeight: 20, radiance: 1.0),  // fill, front left
        Softbox(azimuth: 0, elevation: 80, halfWidth: 60, halfHeight: 7, radiance: 1.6),     // strip overhead
        Softbox(azimuth: 150, elevation: 18, halfWidth: 5, halfHeight: 22, radiance: 2.0),   // rims behind
        Softbox(azimuth: -150, elevation: 18, halfWidth: 5, halfHeight: 22, radiance: 2.0),
    ]

    /// Linear radiance of the studio in direction `d` (unit).
    static func studioRadiance(_ d: Vec3) -> Float {
        func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
            let t = min(max((x - a) / (b - a), 0), 1)
            return t * t * (3 - 2 * t)
        }
        let elevation = asinf(min(max(d.y, -1), 1)) * 180 / .pi
        let azimuth = atan2f(d.x, -d.z) * 180 / .pi
        var wall = 0.11 + 0.15 * powf(max(d.y, 0), 0.7)
        wall += 0.05 * expf(-powf((elevation - 6) / 5, 2))  // a faint band above the horizon
        let floor: Float = 0.07
        var value = floor + (wall - floor) * smooth(-3, 1, elevation)
        for box in softboxes {
            var da = (azimuth - box.azimuth + 180).truncatingRemainder(dividingBy: 360)
            if da < 0 { da += 360 }
            let across = abs(da - 180) * cosf(box.elevation * .pi / 180)
            let inside = smooth(box.halfWidth + 1.5, box.halfWidth - 1.5, across)
                * smooth(box.halfHeight + 1.5, box.halfHeight - 1.5, abs(elevation - box.elevation))
            value += (box.radiance - value) * inside
        }
        return value
    }

    /// The studio as an equirectangular image (`EnvironmentMath.equirectDirection` layout).
    static func studio(width: Int, height: Int) -> FloatImage {
        var pixels = [Float](repeating: 1, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let d = EnvironmentMath.equirectDirection(Vec2((Float(x) + 0.5) / Float(width), (Float(y) + 0.5) / Float(height)))
                let v = studioRadiance(d)
                let i = (y * width + x) * 4
                pixels[i] = v; pixels[i + 1] = v; pixels[i + 2] = v
            }
        }
        return FloatImage(width: width, height: height, pixels: pixels)
    }
}
