import Foundation

/// A mirror plane for `SceneRenderer`: the plane through its entity's position along the
/// entity's up axis (local +Y of the `GlobalTransform`; scale is ignored). The first enabled one
/// by entity index is used; without one, nothing extra is rendered or sampled (no cost).
///
/// Each frame, per view, the renderer draws the scene again from the camera mirrored in the
/// plane, into an offscreen image of `resolutionScale` times the view's size, keeping only what
/// lies above the plane (an oblique near plane). PBR materials without an occlusion texture
/// then sample it where their surface lies on the plane (within `tolerance`, facing along its
/// normal): the image replaces the environment's reflection, blurred with the material's
/// roughness (a 12-tap spiral of `blur` x roughness), faded out toward `maxRoughness`, scaled
/// by the usual split-sum Fresnel term, and shifted by the normal map's tilt (`distortion`).
/// The reflection pass draws meshes and the sky (no particles or debug shapes) with the real
/// lights and shadows. The image is LDR (stores c / (1 + c)); keys missing from older scene
/// files take their defaults.
public struct PlanarReflection: Component, Codable, Equatable, Sendable {
    public static let componentName = "PlanarReflection"
    public static var fieldHints: [String: FieldHints] {
        ["resolutionScale": FieldHints(range: 0.1...1, step: 0.05, tooltip: "Size of the reflection image relative to the view"),
         "strength": FieldHints(range: 0...1, step: 0.01, tooltip: "Blend of the reflection over the environment's"),
         "maxRoughness": FieldHints(range: 0.05...1, step: 0.01, tooltip: "Roughness at which the reflection has faded out"),
         "blur": FieldHints(range: 0...0.5, step: 0.005, tooltip: "Blur radius at roughness 1, as a fraction of the image height"),
         "distortion": FieldHints(range: 0...8, step: 0.05, tooltip: "How far the normal map's tilt shifts the reflection, world units"),
         "tolerance": FieldHints(range: 0.001...2, step: 0.005, tooltip: "Surfaces within this distance of the plane receive it"),
         "clipBias": FieldHints(range: 0...1, step: 0.005, tooltip: "Geometry below this height above the plane is left out")]
    }
    /// The reflection image's size relative to the view's (0.5: half resolution).
    public var resolutionScale: Float
    /// How much of the reflection replaces the environment's, 0...1.
    public var strength: Float
    /// Perceptual roughness where the reflection has faded out completely (it starts to fade at half of it).
    public var maxRoughness: Float
    /// Blur radius at roughness 1, as a fraction of the image height (scaled by the roughness).
    public var blur: Float
    /// World units the reflection shifts per unit of the normal map's tilt away from the plane's normal.
    public var distortion: Float
    /// Receivers are surfaces within this distance of the plane (fading out over its upper half).
    public var tolerance: Float
    /// Geometry less than this far above the plane isn't drawn into the reflection, so a
    /// double-sided floor on the plane doesn't hide it.
    public var clipBias: Float
    public var isEnabled: Bool

    public init(resolutionScale: Float = 0.5, strength: Float = 1, maxRoughness: Float = 0.6, blur: Float = 0.06, distortion: Float = 1,
                tolerance: Float = 0.05, clipBias: Float = 0.01, isEnabled: Bool = true) {
        self.resolutionScale = resolutionScale
        self.strength = strength
        self.maxRoughness = maxRoughness
        self.blur = blur
        self.distortion = distortion
        self.tolerance = tolerance
        self.clipBias = clipBias
        self.isEnabled = isEnabled
    }

    /// Missing fields take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PlanarReflection()
        self.init(
            resolutionScale: try c.decodeIfPresent(Float.self, forKey: .resolutionScale) ?? d.resolutionScale,
            strength: try c.decodeIfPresent(Float.self, forKey: .strength) ?? d.strength,
            maxRoughness: try c.decodeIfPresent(Float.self, forKey: .maxRoughness) ?? d.maxRoughness,
            blur: try c.decodeIfPresent(Float.self, forKey: .blur) ?? d.blur,
            distortion: try c.decodeIfPresent(Float.self, forKey: .distortion) ?? d.distortion,
            tolerance: try c.decodeIfPresent(Float.self, forKey: .tolerance) ?? d.tolerance,
            clipBias: try c.decodeIfPresent(Float.self, forKey: .clipBias) ?? d.clipBias,
            isEnabled: try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled)
    }
}

/// The geometry of a mirror plane `normal · p = offset` and the matrices of the camera
/// mirrored in it (unit-tested on their own).
public struct ReflectionPlane: Equatable, Sendable {
    /// Unit normal, pointing to the side that is reflected (where the real camera is).
    public var normal: Vec3
    public var offset: Float

    public init(normal: Vec3, offset: Float) {
        self.normal = normal
        self.offset = offset
    }

    /// The plane through the origin of `world` along its +Y axis.
    public init(world: Mat4) {
        let n = normalize(Vec3(world.c1.x, world.c1.y, world.c1.z))
        self.init(normal: n, offset: dot(n, Vec3(world.c3.x, world.c3.y, world.c3.z)))
    }

    /// Signed distance of `p` from the plane (positive on the normal's side).
    public func distance(to p: Vec3) -> Float { dot(normal, p) - offset }

    /// The world-space reflection about the plane (an involution; flips handedness).
    public var mirror: Mat4 {
        let n = normal
        return Mat4(Vec4(1 - 2 * n.x * n.x, -2 * n.x * n.y, -2 * n.x * n.z, 0),
                    Vec4(-2 * n.x * n.y, 1 - 2 * n.y * n.y, -2 * n.y * n.z, 0),
                    Vec4(-2 * n.x * n.z, -2 * n.y * n.z, 1 - 2 * n.z * n.z, 0),
                    Vec4(2 * offset * n.x, 2 * offset * n.y, 2 * offset * n.z, 1))
    }

    /// `projection` with its near plane replaced by `plane` (x, y, z: normal, w: offset in
    /// camera space; the visible side positive), Lengyel's oblique clipping adapted to depth in
    /// [0, 1], standard or `reversedZ`. The far plane stays where it was (at the far corner on
    /// the plane's side).
    public static func oblique(_ projection: Mat4, plane c: Vec4, reversedZ: Bool) -> Mat4 {
        let q = projection.inverse * Vec4(c.x >= 0 ? 1 : -1, c.y >= 0 ? 1 : -1, reversedZ ? 0 : 1, 1)
        let w = Vec4(projection.c0.w, projection.c1.w, projection.c2.w, projection.c3.w)
        let k = (w * q).sum() / (c * q).sum()
        let row = reversedZ ? w - k * c : k * c
        var m = projection
        m.c0.z = row.x
        m.c1.z = row.y
        m.c2.z = row.z
        m.c3.z = row.w
        return m
    }

    /// The view and projection of the camera (`view`, `projection`) mirrored in the plane, for
    /// an image that shows only what is more than `clipBias` above it. The projection mirrors
    /// the image horizontally, which cancels the mirror's flip of the triangle winding, so
    /// pipelines cull as usual; the receivers' lookup uses `viewProjection`, which includes it.
    public func mirroredCamera(view: Mat4, projection: Mat4, reversedZ: Bool, clipBias: Float) -> (view: Mat4, projection: Mat4) {
        let mirroredView = view * mirror
        // The visible half-space `normal · p - offset - clipBias >= 0` in the mirrored camera's space.
        let world = Vec4(normal, -offset - clipBias)
        let inverse = mirroredView.inverse
        let clip = Vec4((inverse.c0 * world).sum(), (inverse.c1 * world).sum(), (inverse.c2 * world).sum(), (inverse.c3 * world).sum())
        let clipped = Self.oblique(projection, plane: clip, reversedZ: reversedZ)
        return (mirroredView, Mat4.scale(Vec3(-1, 1, 1)) * clipped)
    }
}

/// One view's reflection pass, from `SceneRenderer.prepareReflection` / `renderViewReflection`.
struct ReflectionPass {
    var plane: ReflectionPlane
    var settings: PlanarReflection
    var view: Mat4
    /// Mirrored horizontally (see `ReflectionPlane.mirroredCamera`).
    var projection: Mat4
    var viewProjection: Mat4 { projection * view }
    var eye: Vec3
    var reversedZ: Bool
    var size: (width: Int, height: Int)
    var clearColor: Vec4
}

/// `SceneRenderer`'s planar reflection state: the plane in the world, the images (one for the
/// `prepare` path, one per `renderView` of the frame), and scratch for the pass's culling and lights.
@MainActor struct ReflectionState {
    var plane: (settings: PlanarReflection, plane: ReflectionPlane)?
    /// The `prepare` camera's pass, set when its image is to be rendered by `renderShadows`.
    var pass: ReflectionPass?
    var rendered = false
    var main: RenderTarget?
    /// `renderView`'s images, reused in order each frame (views sampling one image would race the next view's rewrite).
    var views: [RenderTarget] = []
    var nextView = 0
    var list = RenderList()
    var clusters = LightClusters()
    var lightData = LightClusters.GPUData()
    var reportedFailure = false

    /// The image receivers of the `prepare` camera sample, once it is rendered.
    var mainTexture: GPUTexture? { rendered ? main?.texture : nil }

    /// Takes the first enabled `PlanarReflection` (by entity index) and forgets last frame's passes.
    mutating func find(in world: World) {
        pass = nil
        rendered = false
        nextView = 0
        plane = nil
        var best: (entity: Entity, settings: PlanarReflection)?
        world.query(PlanarReflection.self) { entity, settings in
            if settings.isEnabled, best == nil || entity.index < best!.entity.index { best = (entity, settings) }
        }
        guard let (entity, settings) = best else { return }
        let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
        plane = (settings, ReflectionPlane(world: matrix))
    }
}

extension SceneRenderer.FrameUniforms {
    /// Makes receivers sample the reflection `pass` renders.
    mutating func setReflection(_ pass: ReflectionPass) {
        let s = pass.settings
        reflectionViewProj = pass.viewProjection
        reflectionPlane = Vec4(pass.plane.normal, pass.plane.offset)
        reflectionParams = Vec4(min(max(s.strength, 0), 1), max(s.maxRoughness, 0.01), max(s.blur, 0), s.distortion)
        reflectionExtra = Vec4(max(s.tolerance, 1e-4), Float(pass.size.height) / Float(max(pass.size.width, 1)), 1, 0)
    }
}

extension SceneRenderer {
    /// The reflection pass for a camera, or nil when there is no plane or the camera is not above it.
    private func makeReflectionPass(view: Mat4, projection: Mat4, reversedZ: Bool, eye: Vec3, size: (width: Int, height: Int),
                                    clearColor: Vec4) -> ReflectionPass? {
        guard let (settings, plane) = reflections.plane, plane.distance(to: eye) > settings.clipBias else { return nil }
        let camera = plane.mirroredCamera(view: view, projection: projection, reversedZ: reversedZ, clipBias: settings.clipBias)
        let scale = min(max(settings.resolutionScale, 0.05), 1)
        let width = max(Int((Float(size.width) * scale).rounded()), 8), height = max(Int((Float(size.height) * scale).rounded()), 8)
        let mirrored = plane.mirror * Vec4(eye, 1)
        return ReflectionPass(plane: plane, settings: settings, view: camera.view, projection: camera.projection,
                              eye: Vec3(mirrored.x, mirrored.y, mirrored.z), reversedZ: reversedZ, size: (width, height),
                              clearColor: clearColor)
    }

    /// `prepare`'s part: sets the `prepare` camera's uniforms to sample the reflection (rendered later by `renderShadows`).
    /// `projection` is the camera's, unjittered.
    func prepareReflection(view: Mat4, projection: Mat4, reversedZ: Bool, eye: Vec3, size: (width: Int, height: Int), clearColor: Vec4) {
        guard reflections.plane != nil, uniforms != nil,
              let pass = makeReflectionPass(view: view, projection: projection, reversedZ: reversedZ, eye: eye, size: size,
                                            clearColor: clearColor) else { return }
        reflections.pass = pass
        uniforms!.setReflection(pass)
    }

    /// Renders the `prepare` camera's reflection image (from `renderShadows`).
    func renderReflection(frame: Frame) {
        guard let pass = reflections.pass, let base = uniforms else { return }
        if reflections.main == nil { reflections.main = makeReflectionTarget(size: pass.size) }
        guard let target = reflections.main, (try? target.resize(width: pass.size.width, height: pass.size.height)) != nil else { return }
        renderReflectionPass(pass, base: base, shadows: shadowsActive ? shadowSetup : nil, into: target, frame: frame)
        reflections.rendered = true
    }

    /// Renders a view's reflection image and sets `uniforms` to sample it; returns the image (nil without a plane).
    func renderViewReflection(_ view: SceneView, uniforms: inout FrameUniforms, size: (width: Int, height: Int), shadows: ShadowSetup?,
                              frame: Frame) -> GPUTexture? {
        guard reflections.plane != nil,
              let pass = makeReflectionPass(view: view.view, projection: view.projection, reversedZ: view.reversedZ, eye: view.eye,
                                            size: size, clearColor: view.clearColor) else { return nil }
        let index = reflections.nextView
        reflections.nextView += 1
        if reflections.views.count <= index {
            guard let target = makeReflectionTarget(size: pass.size) else { return nil }
            reflections.views.append(target)
        }
        let target = reflections.views[index]
        guard (try? target.resize(width: pass.size.width, height: pass.size.height)) != nil else { return nil }
        uniforms.setReflection(pass)
        renderReflectionPass(pass, base: uniforms, shadows: shadows, into: target, frame: frame)
        return target.texture
    }

    private func makeReflectionTarget(size: (width: Int, height: Int)) -> RenderTarget? {
        do {
            return try RenderTarget(device: device, width: size.width, height: size.height, multisampled: false, label: "reflection")
        } catch {
            if !reflections.reportedFailure {
                reflections.reportedFailure = true
                print("SceneRenderer: reflection target unavailable: \(error)")
            }
            return nil
        }
    }

    /// Draws the world from the mirrored camera into `target`: culled and lit for that camera, meshes and the sky only.
    private func renderReflectionPass(_ pass: ReflectionPass, base: FrameUniforms, shadows: ShadowSetup?, into target: RenderTarget,
                                      frame: Frame) {
        reflections.list.build(items: prep.items, view: Frustum(viewProjection: pass.viewProjection), cameraPosition: pass.eye, shadows: nil)
        let instances = reflections.list.instances.isEmpty ? nil : frame.upload(reflections.list.instances)
        var uniforms = base
        uniforms.viewProj = pass.viewProjection
        uniforms.currentViewProj = pass.viewProjection
        uniforms.previousViewProj = pass.viewProjection
        uniforms.cameraPos = Vec4(pass.eye, 0)
        uniforms.reflectionParams = .zero
        uniforms.reflectionExtra = Vec4(0, 0, 0, 1)
        uniforms.viewDepth = .zero
        uniforms.clusterScale = .zero
        uniforms.clusterGrid = .zero
        reflections.clusters.build(lights: punctualLights, view: pass.view, projection: pass.projection)
        reflections.clusters.write(to: &reflections.lightData)
        uniforms.setClusters(reflections.clusters, view: pass.view, size: pass.size)
        if let shadows { uniforms.shadows = shadows.uniforms(for: reflections.clusters) }
        let lights = reflections.clusters.isEmpty ? nil : reflections.lightData
        // The target is LDR: the clear color goes in as c / (1 + c) with no coverage.
        let clear = Vec4(pass.clearColor.x / (1 + pass.clearColor.x), pass.clearColor.y / (1 + pass.clearColor.y),
                         pass.clearColor.z / (1 + pass.clearColor.z), 0)
        frame.renderPass(into: target, clearColor: clear, clearDepth: pass.reversedZ ? 0 : 1) { renderPass in
            draw(renderPass, list: reflections.list, uniforms: uniforms, instances: instances, reversedZ: pass.reversedZ, lights: lights,
                 sky: (pass.view, pass.projection), particleDepth: nil, drawsParticles: false, encodesSky: true)
        }
    }
}
