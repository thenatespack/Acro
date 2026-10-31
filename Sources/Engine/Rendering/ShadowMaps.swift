import Foundation

/// The CPU side of `SceneRenderer`'s shadows, free of GPU resources (and unit-tested on its own):
///
/// - `ShadowCascades`: split distances and texel-snapped, sphere-fitted cascade projections
///   for a `DirectionalLight` that follows the camera.
/// - `ShadowAtlasLayout`: where cascades, spot-light maps and point-light faces live in the
///   one depth texture all shadows share (the render device has no texture arrays or cube maps).
/// - `ShadowedLights`: which point / spot lights get one of the few shadow slots.
/// - `LocalLightShadows`: the projections of a spot light's map and a point light's six faces.
/// - `ShadowCasterBatches`: casters culled and batched per atlas tile.
/// - `ShadowSetup`: all of it for one frame, plus the shader's uniforms (`ShadowUniforms`).
///
/// Every tile is rendered in one depth pass over the whole atlas: each tile's projection is
/// followed by a clip-space scale and offset onto its rectangle, and a scissor keeps
/// primitives that leave the rectangle out of the neighbors. The shader (shadows.glsl) maps
/// world positions to tile coordinates with the same projections and offsets them into the atlas.

/// A rectangle of the shadow atlas in texels, origin at the top left.
public struct ShadowRect: Equatable, Sendable {
    public var x, y, width, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public func intersects(_ other: ShadowRect) -> Bool {
        x < other.x + other.width && other.x < x + width && y < other.y + other.height && other.y < y + height
    }
}

// MARK: - Cascades

/// Cascaded shadow maps for a directional light following the camera.
///
/// The view depth range from the camera's near plane to `maxDistance` is split with the
/// "practical" scheme (Zhang et al. 2006): each split is `lambda` × the logarithmic split plus
/// `1 - lambda` × the uniform one. Each cascade is fitted to its slice of the view frustum by
/// the slice's bounding sphere, which depends only on the depths and the field of view, not
/// on where the camera looks, so a cascade's size and texel size stay constant while the
/// camera moves or turns. The sphere's center is then snapped to whole texels in a light
/// space of fixed orientation, so shadow edges don't shimmer. Consecutive cascades overlap by
/// the blend band (`blend` × the cascade's depth range), where the shader fades from one to the next.
public enum ShadowCascades {
    public static let maxCascades = 4
    /// Texels kept free around a cascade's bounding sphere, so filter taps, the normal offset
    /// and snapping stay inside the cascade's tile.
    public static let marginTexels = 4

    /// The far view depth of each of `count` cascades between `near` and `far` (the last is `far`).
    public static func splitDistances(near: Float, far: Float, count: Int, lambda: Float) -> [Float] {
        let n = max(near, 1e-4), f = max(far, n * 1.001), count = max(count, 1)
        return (1...count).map { i in
            if i == count { return f }
            let t = Float(i) / Float(count)
            let logarithmic = n * powf(f / n, t)
            let uniform = n + (f - n) * t
            return lambda * logarithmic + (1 - lambda) * uniform
        }
    }

    /// The smallest sphere around the slice of a perspective frustum between view depths
    /// `near` and `far`, whose corners lie at `tan` × depth from the axis (`tan` is the
    /// tangent of the half-diagonal angle: √(tanX² + tanY²)). Returns the center's view depth
    /// and the radius.
    public static func boundingSphere(near: Float, far: Float, tan: Float) -> (depth: Float, radius: Float) {
        let k2 = tan * tan
        // Equidistant from a near corner and a far corner, on the axis.
        let depth = (far + near) * 0.5 * (1 + k2)
        if depth >= far {
            // The far cap alone decides (wide field of view): centered on it.
            return (far, far * tan)
        }
        let dn = depth - near, rn = near * tan
        let df = far - depth, rf = far * tan
        return (depth, max((dn * dn + rn * rn).squareRoot(), (df * df + rf * rf).squareRoot()))
    }

    /// Field of view tangents (widened by any off-center shift) and near / far depths of a
    /// perspective projection made like `Mat4.perspective` (standard or reversed depth);
    /// nil for other projections.
    public static func perspectiveParameters(_ projection: Mat4) -> (tanX: Float, tanY: Float, near: Float, far: Float)? {
        let p = projection
        guard abs(p.c2.w + 1) < 1e-5, abs(p.c3.w) < 1e-5, p.c0.x > 0, p.c1.y > 0, p.c2.z != 0, p.c2.z != -1 else { return nil }
        let a = p.c3.z / p.c2.z, b = p.c3.z / (p.c2.z + 1)
        let near = min(a, b), far = max(a, b)
        guard near > 0, far.isFinite else { return nil }
        return ((1 + abs(p.c2.x)) / p.c0.x, (1 + abs(p.c2.y)) / p.c1.y, near, far)
    }

    public struct Cascade: Equatable, Sendable {
        /// World to the cascade's clip space (orthographic, depth 0–1 from the light).
        public var viewProjection: Mat4
        /// View depths the cascade's fit covers (the start overlaps the previous cascade's blend band).
        public var start: Float
        public var end: Float
        /// Where its blend into the next cascade begins (= `end` without blending).
        public var blendStart: Float
        /// World units per shadow-map texel.
        public var texelSize: Float
        /// The bounding sphere (before snapping) and the square's half-size (sphere plus margin).
        public var center: Vec3
        public var radius: Float
        public var extent: Float
    }

    /// The cascades for a camera with world-to-view matrix `view` and an unjittered perspective
    /// `projection`, covering view depths out to `maxDistance` (at most the far plane). Each is a
    /// `tileSize` square map seeing casters up to `casterDistance` beyond its sphere toward the
    /// light. Nil if the projection isn't perspective.
    public static func fit(view: Mat4, projection: Mat4, maxDistance: Float, count: Int, lambda: Float, blend: Float,
                           toLight: Vec3, casterDistance: Float, tileSize: Int) -> [Cascade]? {
        guard let p = perspectiveParameters(projection) else { return nil }
        let count = min(max(count, 1), maxCascades)
        let far = min(p.far, max(maxDistance, p.near * 2))
        let splits = splitDistances(near: p.near, far: far, count: count, lambda: lambda)
        let tan = (p.tanX * p.tanX + p.tanY * p.tanY).squareRoot()
        let inverse = view.inverse
        let eye = Vec3(inverse.c3.x, inverse.c3.y, inverse.c3.z)
        let forward = normalize(-Vec3(inverse.c2.x, inverse.c2.y, inverse.c2.z))
        let blend = min(max(blend, 0), 0.5)
        let padding = Float(tileSize) / Float(max(tileSize - 2 * marginTexels, 1))

        var cascades: [Cascade] = []
        var start = p.near
        for i in 0..<count {
            let end = splits[i]
            let nominalStart = i == 0 ? p.near : splits[i - 1]
            let blendStart = end - blend * (end - nominalStart)
            let sphere = boundingSphere(near: start, far: end, tan: tan)
            let extent = sphere.radius * padding
            let center = eye + forward * sphere.depth
            let viewProjection = SceneRenderer.lightViewProjection(
                toLight: toLight, center: center, extent: extent, distance: extent + casterDistance, mapSize: tileSize, snap: true)
            cascades.append(Cascade(viewProjection: viewProjection, start: start, end: end, blendStart: blendStart,
                                    texelSize: 2 * extent / Float(tileSize), center: center, radius: sphere.radius, extent: extent))
            start = blendStart
        }
        return cascades
    }
}

// MARK: - Atlas

/// Where every shadow map lives in the shadow atlas, one `.depth32Float` texture.
///
/// Cascades are `tileSize` squares in two columns at the top (cascade `c` at column `c % 2`,
/// row `c / 2`; a single cascade makes the atlas one tile wide). With local shadows, shelves
/// below them hold `maxSpotShadows` spot-light squares of `tileSize / 4` and
/// `maxPointShadows` point-light blocks of 3 × 2 faces of `tileSize / 8` (+X, -X, +Y on the
/// top row, -Y, +Z, -Z below), packed left to right.
public struct ShadowAtlasLayout: Equatable, Sendable {
    public static let maxSpotShadows = 8
    public static let maxPointShadows = 4

    public let tileSize: Int
    public let cascades: Int
    public let width: Int
    public let height: Int
    public let spotSize: Int
    public let faceSize: Int
    public let cascadeRects: [ShadowRect]
    /// Empty without local shadows.
    public let spotRects: [ShadowRect]
    /// Each point light's 3 × 2 face block.
    public let pointRects: [ShadowRect]

    public var hasLocalShadows: Bool { !spotRects.isEmpty }

    public init(tileSize: Int, cascades: Int, localShadows: Bool) {
        let cascades = min(max(cascades, 1), ShadowCascades.maxCascades)
        self.tileSize = tileSize
        self.cascades = cascades
        let columns = cascades == 1 ? 1 : 2
        width = tileSize * columns
        cascadeRects = (0..<cascades).map {
            ShadowRect(x: ($0 % 2) * tileSize, y: ($0 / 2) * tileSize, width: tileSize, height: tileSize)
        }
        let top = (cascades + columns - 1) / columns * tileSize
        spotSize = max(tileSize / 4, 16)
        faceSize = max(tileSize / 8, 8)
        guard localShadows else {
            height = top
            spotRects = []
            pointRects = []
            return
        }
        let sizes = Array(repeating: (spotSize, spotSize), count: Self.maxSpotShadows)
            + Array(repeating: (faceSize * 3, faceSize * 2), count: Self.maxPointShadows)
        let (rects, shelves) = Self.packShelves(sizes, width: width)
        let placed = rects.map { ShadowRect(x: $0.x, y: $0.y + top, width: $0.width, height: $0.height) }
        spotRects = Array(placed[..<Self.maxSpotShadows])
        pointRects = Array(placed[Self.maxSpotShadows...])
        height = top + shelves
    }

    /// Packs rectangles into shelves `width` wide, tallest first (stable), left to right.
    /// Returns each rectangle's place, in input order, and the total height.
    static func packShelves(_ sizes: [(width: Int, height: Int)], width: Int) -> (rects: [ShadowRect], height: Int) {
        let order = sizes.indices.sorted { sizes[$0].height != sizes[$1].height ? sizes[$0].height > sizes[$1].height : $0 < $1 }
        var rects = [ShadowRect](repeating: ShadowRect(x: 0, y: 0, width: 0, height: 0), count: sizes.count)
        var x = 0, y = 0, shelf = 0
        for i in order {
            let (w, h) = sizes[i]
            if x + w > width, x > 0 {
                y += shelf
                x = 0
                shelf = 0
            }
            rects[i] = ShadowRect(x: x, y: y, width: w, height: h)
            x += w
            shelf = max(shelf, h)
        }
        return (rects, y + shelf)
    }

    /// The clip-space transform that squeezes a full-target projection onto `rect`: applied
    /// after a tile's projection, the tile renders into its rectangle of the atlas.
    public func clipTransform(onto rect: ShadowRect) -> Mat4 {
        let w = Float(width), h = Float(height)
        let sx = Float(rect.width) / w, ox = Float(2 * rect.x + rect.width) / w - 1
        let sy = Float(rect.height) / h, oy = 1 - Float(2 * rect.y + rect.height) / h
        return Mat4(Vec4(sx, 0, 0, 0), Vec4(0, sy, 0, 0), Vec4(0, 0, 1, 0), Vec4(ox, oy, 0, 1))
    }

    /// Clip space to texture coordinates (x right, y down, 0–1) with depth unchanged; after the
    /// perspective divide, a tile projection followed by this gives coordinates in the tile.
    public static let clipToTexture = Mat4(Vec4(0.5, 0, 0, 0), Vec4(0, -0.5, 0, 0), Vec4(0, 0, 1, 0), Vec4(0.5, 0.5, 0, 1))
}

// MARK: - Local light shadows

/// Which point and spot lights get a shadow map: those whose component asks for one, inside
/// the view, ranked by how large they appear (bounding-sphere radius over its distance from
/// the eye), at most `maxSpots` spot lights and `maxPoints` point lights.
public enum ShadowedLights {
    /// Sets each light's `shadowSlot` (0..<maxSpots for spots, 0..<maxPoints for points, in
    /// order of priority; -1 for the rest). With no `view`, every light counts as visible.
    public static func select(_ lights: inout [PunctualLight], eye: Vec3, view: Frustum?,
                              maxSpots: Int = ShadowAtlasLayout.maxSpotShadows,
                              maxPoints: Int = ShadowAtlasLayout.maxPointShadows) {
        var candidates: [(index: Int, score: Float)] = []
        for i in lights.indices {
            lights[i].shadowSlot = -1
            guard lights[i].castsShadows else { continue }
            let (center, radius) = lights[i].boundingSphere
            if let view, !view.intersects(center: center, halfExtent: Vec3(repeating: radius)) { continue }
            let distance = max(length(center - eye) - radius, radius * 0.01, 1e-4)
            candidates.append((i, radius / distance))
        }
        candidates.sort { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        var spots = 0, points = 0
        for candidate in candidates {
            if lights[candidate.index].isSpot {
                guard spots < maxSpots else { continue }
                lights[candidate.index].shadowSlot = spots
                spots += 1
            } else {
                guard points < maxPoints else { continue }
                lights[candidate.index].shadowSlot = points
                points += 1
            }
        }
    }
}

/// The projections of point and spot light shadow maps. Each covers a little more than its
/// light's cone (or cube face) so the filter's taps near the edge stay inside the tile: the
/// field of view is widened by `borderScale(size:)`.
public enum LocalLightShadows {
    /// Point-light faces: the axis each looks along and its up vector; right = forward × up.
    /// shadows.glsl has the same table.
    public static let faces: [(forward: Vec3, up: Vec3)] = [
        (Vec3(1, 0, 0), Vec3(0, 1, 0)), (Vec3(-1, 0, 0), Vec3(0, 1, 0)),
        (Vec3(0, 1, 0), Vec3(0, 0, -1)), (Vec3(0, -1, 0), Vec3(0, 0, 1)),
        (Vec3(0, 0, 1), Vec3(0, 1, 0)), (Vec3(0, 0, -1), Vec3(0, 1, 0)),
    ]
    /// The widest spot cone that gets a shadow map (half-angle); wider cones are clipped.
    public static let maxSpotAngle: Float = 80 * .pi / 180

    /// How much a map `size` texels wide widens its field of view (tangent scale) to keep
    /// `ShadowCascades.marginTexels` free on each side.
    public static func borderScale(size: Int) -> Float {
        Float(size) / Float(max(size - 2 * ShadowCascades.marginTexels, 1))
    }

    /// The near plane of a local light's maps.
    public static func near(range: Float) -> Float { max(range * 0.01, 0.02) }

    /// A spot light's shadow projection (world to clip, depth 0–1 from `near` to the range),
    /// and the world size of one texel per unit of distance from the light.
    public static func spot(_ light: PunctualLight, size: Int) -> (viewProjection: Mat4, texelPerDistance: Float) {
        let sinOuter = max(1 - light.cosOuter * light.cosOuter, 0).squareRoot()
        let half = min(atan2f(sinOuter, light.cosOuter), maxSpotAngle)
        let tangent = tanf(half) * borderScale(size: size)
        let up = abs(light.direction.y) > 0.99 ? Vec3(0, 0, 1) : Vec3(0, 1, 0)
        let view = Mat4.lookAt(eye: light.position, target: light.position + light.direction, up: up)
        let projection = Mat4.perspective(fovY: 2 * atanf(tangent), aspect: 1, near: near(range: light.range), far: light.range)
        return (projection * view, 2 * tangent / Float(size))
    }

    /// Depth = a + b / d for a point at distance d along a point-light face's axis (0 at the
    /// near plane, 1 at the range).
    public static func pointDepth(range: Float) -> (a: Float, b: Float) {
        let n = near(range: range), f = max(range, n * 1.001)
        return (f / (f - n), -f * n / (f - n))
    }

    /// Face `face` of a point light's shadow: a 90° (widened) frustum along `faces[face]`.
    public static func pointFace(_ light: PunctualLight, face: Int, size: Int) -> Mat4 {
        let (forward, up) = faces[face]
        let right = cross(forward, up)
        let k = borderScale(size: size)
        let (a, b) = pointDepth(range: light.range)
        let p = light.position
        // Rows: x = right·d / k, y = up·d / k, z = a (forward·d) + b, w = forward·d.
        let rows = [Vec4(right / k, -dot(right, p) / k), Vec4(up / k, -dot(up, p) / k),
                    Vec4(forward * a, -dot(forward, p) * a + b), Vec4(forward, -dot(forward, p))]
        return Mat4(Vec4(rows[0].x, rows[1].x, rows[2].x, rows[3].x), Vec4(rows[0].y, rows[1].y, rows[2].y, rows[3].y),
                    Vec4(rows[0].z, rows[1].z, rows[2].z, rows[3].z), Vec4(rows[0].w, rows[1].w, rows[2].w, rows[3].w))
    }

    /// World size of a point-light face texel per unit of distance.
    public static func pointTexelPerDistance(size: Int) -> Float { 2 * borderScale(size: size) / Float(size) }
}

// MARK: - Casters

/// Which casters one atlas tile draws: those whose bounds touch the tile's frustum (and the
/// light's range sphere, for local lights) and, for cascades, whose shadow can reach the
/// camera's view (`ShadowCasterCulling`).
public struct ShadowTileCulling: Sendable {
    public var frustum: Frustum
    /// Cascades: the sweep test against `view`.
    public var sweep: ShadowCasterCulling?
    public var view: Frustum?
    /// Local lights: the light's bounding sphere.
    public var sphere: (center: Vec3, radius: Float)?

    public init(frustum: Frustum, sweep: ShadowCasterCulling? = nil, view: Frustum? = nil, sphere: (center: Vec3, radius: Float)? = nil) {
        self.frustum = frustum
        self.sweep = sweep
        self.view = view
        self.sphere = sphere
    }

    public func draws(_ bounds: Bounds) -> Bool {
        if let sphere {
            let o = bounds.center - sphere.center
            let d = pointwiseMax(Vec3(abs(o.x), abs(o.y), abs(o.z)) - bounds.halfExtent, .zero)
            guard dot(d, d) <= sphere.radius * sphere.radius else { return false }
        }
        if let sweep, let view { return sweep.castsVisibleShadow(bounds, view: view) }
        return frustum.intersects(center: bounds.center, halfExtent: bounds.halfExtent)
    }
}

/// Shadow casters culled and batched for every tile of the atlas, in one instance array (tile
/// by tile; within a tile, batches by mesh, alpha-tested casters by mesh and material, like
/// `RenderList.shadow`).
public struct ShadowCasterBatches {
    public private(set) var instances: [MeshInstance] = []
    public private(set) var batches: [RenderBatch] = []
    /// Each tile's range of `batches`.
    public private(set) var tileBatches: [Range<Int>] = []
    /// Caster instances drawn over all tiles, and caster-tile pairs culled.
    public private(set) var drawn = 0
    public private(set) var culled = 0

    private var slots: [Int: Int] = [:]
    private var members: [(batch: Int32, item: Int32)] = []

    public init() {}

    public mutating func build(items: [RenderItem], tiles: [ShadowTileCulling]) {
        instances.removeAll(keepingCapacity: true)
        batches.removeAll(keepingCapacity: true)
        tileBatches.removeAll(keepingCapacity: true)
        drawn = 0
        culled = 0
        for tile in tiles {
            slots.removeAll(keepingCapacity: true)
            members.removeAll(keepingCapacity: true)
            let first = batches.count
            for (i, item) in items.enumerated() where item.castsShadows {
                guard tile.draws(item.bounds) else {
                    culled += 1
                    continue
                }
                let material = item.alphaTested ? item.material : -1
                let key = item.mesh << 32 | (material & 0xffff_ffff)
                let slot: Int
                if let existing = slots[key] {
                    slot = existing
                } else {
                    slot = batches.count
                    slots[key] = slot
                    batches.append(RenderBatch(mesh: item.mesh, material: material, first: 0, count: 0))
                }
                batches[slot].count += 1
                members.append((Int32(slot), Int32(i)))
            }
            // Lay this tile's batches out after everything before it.
            var next = instances.count
            for slot in first..<batches.count {
                batches[slot].first = next
                next += batches[slot].count
            }
            var fill = batches[first...].map(\.first)
            instances.append(contentsOf: repeatElement(.zero, count: members.count))
            for member in members {
                let slot = Int(member.batch) - first
                instances[fill[slot]] = items[Int(member.item)].instance
                fill[slot] += 1
            }
            drawn += members.count
            tileBatches.append(first..<batches.count)
        }
    }
}

// MARK: - Frame setup

/// Must match the shadow fields at the end of `Frame` in mesh_surface.glsl (std140).
struct ShadowUniforms: BitwiseCopyable {
    /// World to cascade-tile coordinates (x, y in 0–1 across the tile, z depth).
    var cascadeMatrices: (Mat4, Mat4, Mat4, Mat4) = (.identity, .identity, .identity, .identity)
    /// World to spot-tile coordinates, before the perspective divide (by shadowed-spot index).
    var spotMatrices: (Mat4, Mat4, Mat4, Mat4, Mat4, Mat4, Mat4, Mat4) =
        (.identity, .identity, .identity, .identity, .identity, .identity, .identity, .identity)
    /// Far view depth of each cascade, and where its blend into the next begins.
    var cascadeSplits = Vec4.zero
    var cascadeBlendStarts = Vec4.zero
    /// World-space normal offset and depth bias of each cascade.
    var cascadeNormalOffsets = Vec4.zero
    var cascadeBiases = Vec4.zero
    /// View depth of a world position p: dot(xyz, p) + w.
    var depthRow = Vec4.zero
    /// x: cascades (0: no directional shadow), z: shadowed spots, w: shadowed points (light index order).
    var info = Vec4.zero
    /// xy: 1 / atlas size, z: PCF radius in texels, w: 1 tints cascades (debug).
    var atlas = Vec4.zero
    /// xy: a cascade tile's size, zw: a spot tile's size (atlas texture coordinates).
    var tiles = Vec4.zero
    /// xy: a point-light face's size (atlas texture coordinates), z: face tangent scale.
    var faces = Vec4.zero
    /// Local lights: x: normal offset, y: depth bias (both in texels at the receiver's distance).
    var local = Vec4.zero
    /// Per shadowed spot: xy: tile origin, z: texel size per unit distance.
    var spotParams: (Vec4, Vec4, Vec4, Vec4, Vec4, Vec4, Vec4, Vec4) = (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero)
    /// Per shadowed point light: xyz: position, w: texel size per unit distance.
    var pointPositions: (Vec4, Vec4, Vec4, Vec4) = (.zero, .zero, .zero, .zero)
    /// Per shadowed point light: xy: face-block origin, z / w: depth = z + w / distance along the face axis.
    var pointParams: (Vec4, Vec4, Vec4, Vec4) = (.zero, .zero, .zero, .zero)

    static func set<T, Tuple>(_ tuple: inout Tuple, _ index: Int, _ value: T) {
        withUnsafeMutableBytes(of: &tuple) { $0.bindMemory(to: T.self)[index] = value }
    }
}

/// One tile to render into the atlas.
struct ShadowTile {
    var rect: ShadowRect
    /// World to the atlas's clip space (the tile's projection squeezed onto `rect`).
    var clip: Mat4
    var culling: ShadowTileCulling
}

/// Counters from the last frame's shadows.
public struct ShadowStats: Equatable, Sendable {
    public var cascades = 0
    public var spotShadows = 0
    public var pointShadows = 0
    /// Tiles rendered (cascades + spots + 6 per point light).
    public var tiles = 0
    public var atlasWidth = 0
    public var atlasHeight = 0
}

/// Everything about one frame's shadows: the atlas layout, the tiles to render and the
/// shader's uniforms (with the local lights in slot order; `uniforms(for:)` reorders them
/// to match a view's light list).
struct ShadowSetup {
    var layout: ShadowAtlasLayout
    var tiles: [ShadowTile] = []
    var base = ShadowUniforms()
    var spotSlots: [(matrix: Mat4, params: Vec4)] = []
    var pointSlots: [(position: Vec4, params: Vec4)] = []
    var stats = ShadowStats()

    /// The camera the shadows are set up for.
    struct Focus {
        var view: Mat4
        /// Unjittered; cascades need a perspective one.
        var projection: Mat4?
        /// What it sees (casters and lights outside can be skipped); nil keeps everything in the light's reach.
        var frustum: Frustum?
    }

    /// Default receiver normal offset and depth bias of point / spot shadows, in texels.
    static let localNormalOffset: Float = 1.5
    static let localDepthBias: Float = 1.5

    /// Builds the frame's shadows: the directional light's cascades (or its single map with a
    /// fixed `shadowCenter`, or when the focus has no perspective projection: a square of
    /// `shadowExtent` in front of the eye), and the selected local lights' maps (their
    /// `shadowSlot`s are set here). Nil if nothing casts shadows.
    static func build(light: DirectionalLight?, toLight: Vec3, focus: Focus, lights: inout [PunctualLight],
                      items: [RenderItem], quality: RenderQuality, showCascades: Bool) -> ShadowSetup? {
        let inverse = focus.view.inverse
        let eye = Vec3(inverse.c3.x, inverse.c3.y, inverse.c3.z)
        let forward = normalize(-Vec3(inverse.c2.x, inverse.c2.y, inverse.c2.z))
        ShadowedLights.select(&lights, eye: eye, view: focus.frustum)
        let hasLocal = lights.contains { $0.shadowSlot >= 0 }
        let sun = light.flatMap { $0.castsShadows ? $0 : nil }
        guard sun != nil || hasLocal else { return nil }

        let tileSize = quality.shadowMapSize
        var cascades: [ShadowCascades.Cascade] = []
        var fixed: (viewProjection: Mat4, extent: Float)?
        if let sun {
            if sun.shadowCenter == nil, let projection = focus.projection,
               let fitted = ShadowCascades.fit(
                view: focus.view, projection: projection, maxDistance: sun.shadowMaxDistance ?? sun.shadowExtent * 2,
                count: sun.cascadeCount ?? quality.shadowCascades, lambda: sun.cascadeSplitLambda, blend: sun.cascadeBlend,
                toLight: toLight, casterDistance: sun.shadowDistance, tileSize: tileSize) {
                cascades = fitted
            } else {
                // One square: fixed, or following the eye (snapped) when there's no perspective to fit.
                fixed = (SceneRenderer.lightViewProjection(
                    toLight: toLight, center: sun.shadowCenter ?? eye + forward * sun.shadowExtent, extent: sun.shadowExtent,
                    distance: sun.shadowDistance, mapSize: tileSize, snap: sun.shadowCenter == nil), sun.shadowExtent)
            }
        }
        let cascadeCount = fixed != nil ? 1 : max(cascades.count, 1)
        var setup = ShadowSetup(layout: ShadowAtlasLayout(tileSize: tileSize, cascades: cascadeCount, localShadows: hasLocal))
        let layout = setup.layout
        let atlasSize = Vec2(Float(layout.width), Float(layout.height))
        setup.stats.atlasWidth = layout.width
        setup.stats.atlasHeight = layout.height
        var u = ShadowUniforms()
        u.atlas = Vec4(1 / atlasSize.x, 1 / atlasSize.y, Float(quality.shadowFilterRadius), showCascades ? 1 : 0)
        u.tiles = Vec4(Float(tileSize) / atlasSize.x, Float(tileSize) / atlasSize.y,
                       Float(layout.spotSize) / atlasSize.x, Float(layout.spotSize) / atlasSize.y)
        u.faces = Vec4(Float(layout.faceSize) / atlasSize.x, Float(layout.faceSize) / atlasSize.y,
                       LocalLightShadows.borderScale(size: layout.faceSize), 0)
        u.local = Vec4(localNormalOffset, localDepthBias, 0, 0)
        u.depthRow = Vec4(forward, -dot(forward, eye))

        // Directional light.
        if let sun {
            var floor = Float.infinity
            for item in items where item.instance.params.x > 0 {
                floor = min(floor, item.bounds.center.y - item.bounds.halfExtent.y)
            }
            let receiverFloor = floor.isFinite ? floor : -.infinity
            let maps: [(viewProjection: Mat4, extent: Float, texel: Float)] = fixed.map {
                [($0.viewProjection, $0.extent, 2 * $0.extent / Float(tileSize))]
            } ?? cascades.map { ($0.viewProjection, $0.extent, $0.texelSize) }
            for (c, map) in maps.enumerated() {
                let rect = layout.cascadeRects[c]
                let culling = ShadowCasterCulling(
                    lightFrustum: Frustum(viewProjection: map.viewProjection), toLight: toLight, receiverFloor: receiverFloor,
                    maxSweep: sun.shadowDistance + map.extent * 2)
                setup.tiles.append(ShadowTile(
                    rect: rect, clip: layout.clipTransform(onto: rect) * map.viewProjection,
                    culling: ShadowTileCulling(frustum: culling.lightFrustum, sweep: culling, view: focus.frustum ?? culling.lightFrustum)))
                ShadowUniforms.set(&u.cascadeMatrices, c, ShadowAtlasLayout.clipToTexture * map.viewProjection)
                u.cascadeNormalOffsets[c] = map.texel * sun.shadowNormalOffset
                u.cascadeBiases[c] = sun.shadowBias
                if fixed != nil {
                    u.cascadeSplits[c] = .greatestFiniteMagnitude
                    u.cascadeBlendStarts[c] = .greatestFiniteMagnitude
                } else {
                    u.cascadeSplits[c] = cascades[c].end
                    u.cascadeBlendStarts[c] = cascades[c].blendStart
                }
            }
            u.info.x = Float(maps.count)
            setup.stats.cascades = maps.count
        }

        // Spot and point lights, in slot order.
        let spots = lights.filter { $0.shadowSlot >= 0 && $0.isSpot }.sorted { $0.shadowSlot < $1.shadowSlot }
        let points = lights.filter { $0.shadowSlot >= 0 && !$0.isSpot }.sorted { $0.shadowSlot < $1.shadowSlot }
        for (slot, light) in spots.enumerated() {
            let rect = layout.spotRects[slot]
            let (viewProjection, texel) = LocalLightShadows.spot(light, size: layout.spotSize)
            setup.tiles.append(ShadowTile(
                rect: rect, clip: layout.clipTransform(onto: rect) * viewProjection,
                culling: ShadowTileCulling(frustum: Frustum(viewProjection: viewProjection), sphere: light.boundingSphere)))
            setup.spotSlots.append((ShadowAtlasLayout.clipToTexture * viewProjection,
                                    Vec4(Float(rect.x) / atlasSize.x, Float(rect.y) / atlasSize.y, texel, 0)))
        }
        for (slot, light) in points.enumerated() {
            let block = layout.pointRects[slot]
            for face in 0..<6 {
                let rect = ShadowRect(x: block.x + face % 3 * layout.faceSize, y: block.y + face / 3 * layout.faceSize,
                                      width: layout.faceSize, height: layout.faceSize)
                let viewProjection = LocalLightShadows.pointFace(light, face: face, size: layout.faceSize)
                setup.tiles.append(ShadowTile(
                    rect: rect, clip: layout.clipTransform(onto: rect) * viewProjection,
                    culling: ShadowTileCulling(frustum: Frustum(viewProjection: viewProjection), sphere: (light.position, light.range))))
            }
            let (a, b) = LocalLightShadows.pointDepth(range: light.range)
            setup.pointSlots.append((Vec4(light.position, LocalLightShadows.pointTexelPerDistance(size: layout.faceSize)),
                                     Vec4(Float(block.x) / atlasSize.x, Float(block.y) / atlasSize.y, a, b)))
        }
        setup.stats.spotShadows = spots.count
        setup.stats.pointShadows = points.count
        setup.stats.tiles = setup.tiles.count
        setup.base = u
        return setup
    }

    /// The uniforms for a view whose light list is `clusters.lights`: its leading shadowed
    /// spot and point lights get their slot's data, at their index.
    func uniforms(for clusters: LightClusters) -> ShadowUniforms {
        var u = base
        let lights = clusters.lights
        for j in 0..<clusters.shadowedSpots {
            let slot = spotSlots[lights[j].shadowSlot]
            ShadowUniforms.set(&u.spotMatrices, j, slot.matrix)
            ShadowUniforms.set(&u.spotParams, j, slot.params)
        }
        for j in 0..<clusters.shadowedPoints {
            let slot = pointSlots[lights[clusters.shadowedSpots + j].shadowSlot]
            ShadowUniforms.set(&u.pointPositions, j, slot.position)
            ShadowUniforms.set(&u.pointParams, j, slot.params)
        }
        u.info.z = Float(clusters.shadowedSpots)
        u.info.w = Float(clusters.shadowedPoints)
        return u
    }
}
