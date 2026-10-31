import Foundation

/// A point or spot light as `SceneRenderer` shades it: world-space position and direction,
/// color premultiplied by intensity, and the cone as cosines. Gathered from `PointLight` /
/// `SpotLight` entities with `PunctualLight.gather(in:)`.
public struct PunctualLight: Equatable, Sendable {
    public var position: Vec3
    /// Unit direction the light travels in (spot lights; zero for point lights).
    public var direction: Vec3
    /// Linear RGB × intensity.
    public var color: Vec3
    public var range: Float
    /// Cosines of the cone's half-angles (spot lights; both -1 for point lights, i.e. no cone).
    public var cosInner: Float
    public var cosOuter: Float

    public var isSpot: Bool { direction != .zero }

    /// The largest outer cone half-angle: just below 90°, so the cone has a bounded sphere.
    public static let maxConeAngle: Float = 89 * .pi / 180

    public init(point light: PointLight, position: Vec3) {
        self.position = position
        direction = .zero
        color = light.color * light.intensity
        range = light.range
        cosInner = -1
        cosOuter = -1
    }

    /// `direction` is the entity's forward axis (normalized here).
    public init(spot light: SpotLight, position: Vec3, direction: Vec3) {
        self.position = position
        self.direction = normalize(direction)
        color = light.color * light.intensity
        range = light.range
        let outer = min(max(light.outerConeAngle, 0), Self.maxConeAngle)
        let inner = min(max(light.innerConeAngle, 0), outer)
        cosOuter = cosf(outer)
        cosInner = cosf(inner)
    }

    /// Every enabled point and spot light of `world` (positioned by `GlobalTransform`), point
    /// lights first, each in query order. Lights with no range or no color are skipped.
    @MainActor public static func gather(in world: World, into lights: inout [PunctualLight]) {
        lights.removeAll(keepingCapacity: true)
        world.query(PointLight.self, GlobalTransform.self) { _, light, transform in
            let m = transform.matrix
            let gathered = PunctualLight(point: light, position: Vec3(m.c3.x, m.c3.y, m.c3.z))
            if gathered.contributes { lights.append(gathered) }
        }
        world.query(SpotLight.self, GlobalTransform.self) { _, light, transform in
            let m = transform.matrix
            let forward = -Vec3(m.c2.x, m.c2.y, m.c2.z)
            guard forward != .zero else { return }
            let gathered = PunctualLight(spot: light, position: Vec3(m.c3.x, m.c3.y, m.c3.z), direction: forward)
            if gathered.contributes { lights.append(gathered) }
        }
    }

    @MainActor public static func gather(in world: World) -> [PunctualLight] {
        var lights: [PunctualLight] = []
        gather(in: world, into: &lights)
        return lights
    }

    var contributes: Bool { range > 0 && color.max() > 0 && range.isFinite }

    /// A sphere around everything the light can reach: the range sphere for point lights,
    /// the smallest sphere around the cone's spherical sector for spot lights
    /// (Wronski, "Cull that cone", 2017).
    public var boundingSphere: (center: Vec3, radius: Float) {
        guard isSpot else { return (position, range) }
        if cosOuter >= 0.70710678 {
            // Narrow cone: the sphere through the apex and the rim.
            let radius = range / (2 * cosOuter)
            return (position + direction * radius, radius)
        }
        let sinOuter = (1 - cosOuter * cosOuter).squareRoot()
        return (position + direction * (range * cosOuter), range * sinOuter)
    }
}

/// Clustered forward shading's CPU side: bins point and spot lights into a view-space grid of
/// `tilesX × tilesY` screen tiles by `slices` depth slices (froxels), so each fragment loops
/// only over the lights that can reach its cluster.
///
/// Slices are spaced logarithmically in view depth between the nearest and farthest light
/// bound (slice 0 also holds everything nearer, the last one everything farther). A light goes
/// into every cluster whose view-space box its bounding sphere touches, tested per slice
/// against the sphere's cross-section, so the binning is conservative: a fragment the light
/// reaches always finds it in its cluster. Rebuilt on the CPU every frame (`build`); no compute.
///
/// The GPU data is five uniform buffers of `maxUniformBufferSize` (16 KiB) each, bound as
/// uniform buffers 3–7 of mesh.frag (see mesh_surface.glsl), which sets the limits:
/// - `maxLights` (1024) visible lights per view, nearest (by bounding sphere) first; the
///   rest are dropped. Lights entirely outside the view are culled before counting.
/// - `maxReferences` (12288) light-in-cluster entries per view in total (10-bit indices, 3 per word).
/// - `maxLightsPerCluster` (255) per cluster, the nearest ones kept.
/// When a limit is hit, the farthest lights lose clusters first (`stats.droppedReferences`).
public struct LightClusters: Sendable {
    public static let tilesX = 16
    public static let tilesY = 9
    public static let slices = 16
    public static let clusterCount = tilesX * tilesY * slices
    public static let maxLights = 1024
    public static let maxReferences = 12288
    public static let maxLightsPerCluster = 255
    /// Slice 0 starts no nearer than this view depth.
    public static let minimumNear: Float = 0.1

    public struct Stats: Equatable, Sendable {
        /// Lights inside the view (uploaded), and references kept / dropped by the limits.
        public var lights = 0
        public var references = 0
        public var droppedReferences = 0
        /// The most lights in one cluster.
        public var maxClusterLights = 0
    }

    /// The lights as uploaded (visible ones, nearest first); clusters index into this.
    public private(set) var lights: [PunctualLight] = []
    public private(set) var stats = Stats()
    /// View depth where slice 0 ends its logarithmic range and the slice scale:
    /// slice(d) = floor(log2(d / near) × sliceScale), clamped to the grid.
    public private(set) var near: Float = 1
    public private(set) var sliceScale: Float = 1
    /// Per cluster: first index into `indices` and light count.
    public private(set) var cellFirst: [UInt16] = []
    public private(set) var cellCount: [UInt16] = []
    public private(set) var indices: [UInt16] = []

    public var isEmpty: Bool { lights.isEmpty }

    public init() {}

    // MARK: - Lookups (as the shader does them)

    public static func clusterIndex(tileX: Int, tileY: Int, slice: Int) -> Int {
        (slice * tilesY + tileY) * tilesX + tileX
    }

    /// The slice a view depth (distance in front of the camera) falls in.
    public func slice(depth: Float) -> Int {
        guard depth > 0 else { return 0 }
        let s = (log2f(depth / near) * sliceScale).rounded(.down)
        return Int(min(max(s, 0), Float(Self.slices - 1)))
    }

    /// The tile a point in normalized device coordinates (y up, the top row is tile 0) falls in.
    public static func tile(ndc: Vec2) -> (x: Int, y: Int) {
        let x = Int(((ndc.x + 1) * 0.5 * Float(tilesX)).rounded(.down))
        let y = Int(((1 - ndc.y) * 0.5 * Float(tilesY)).rounded(.down))
        return (min(max(x, 0), tilesX - 1), min(max(y, 0), tilesY - 1))
    }

    /// The cluster of a view-space point, or nil if it's not in front of the camera.
    public func cluster(viewPosition p: Vec3, projection: Mat4) -> Int? {
        let clip = projection * Vec4(p, 1)
        guard clip.w > 0 else { return nil }
        let tile = Self.tile(ndc: Vec2(clip.x / clip.w, clip.y / clip.w))
        return Self.clusterIndex(tileX: tile.x, tileY: tile.y, slice: slice(depth: -p.z))
    }

    /// Indices into `lights` of the lights binned into `cluster`.
    public func lights(inCluster cluster: Int) -> [Int] {
        guard cluster < cellFirst.count else { return [] }
        let first = Int(cellFirst[cluster])
        return (first..<first + Int(cellCount[cluster])).map { Int(indices[$0]) }
    }

    // MARK: - Building

    /// Bins `input` for a camera with world-to-view matrix `view` and the projection the
    /// screen pass rasterizes with (jitter included). Perspective or orthographic.
    public mutating func build(lights input: [PunctualLight], view: Mat4, projection: Mat4) {
        lights.removeAll(keepingCapacity: true)
        indices.removeAll(keepingCapacity: true)
        stats = Stats()
        cellFirst = [UInt16](repeating: 0, count: Self.clusterCount)
        cellCount = [UInt16](repeating: 0, count: Self.clusterCount)
        let projector = Projector(projection)

        // Cull lights outside the view, then keep the nearest.
        var visible: [(light: Int, center: Vec3, radius: Float, distance: Float)] = []
        for (i, light) in input.enumerated() {
            let sphere = light.boundingSphere
            let c4 = view * Vec4(sphere.center, 1)
            let c = Vec3(c4.x, c4.y, c4.z), r = sphere.radius
            let depth = -c.z
            guard depth + r > 0, let rect = projector.rect(center: c, radius: r, near: depth - r, far: depth + r),
                  rect.x0 < rect.x1, rect.y0 < rect.y1 else { continue }
            visible.append((i, c, r, max(length(c) - r, 0)))
        }
        guard !visible.isEmpty else { return }
        visible.sort { $0.distance != $1.distance ? $0.distance < $1.distance : $0.light < $1.light }
        if visible.count > Self.maxLights { visible.removeLast(visible.count - Self.maxLights) }

        var nearest = Float.infinity, farthest: Float = 0
        for v in visible {
            nearest = min(nearest, -v.center.z - v.radius)
            farthest = max(farthest, -v.center.z + v.radius)
        }
        near = max(nearest, Self.minimumNear)
        let far = max(farthest, near * 1.01)
        sliceScale = Float(Self.slices) / log2f(far / near)

        // Slice boundaries in view depth (slice 0 from the camera, the last one to `far`).
        var sliceDepths = [Float](repeating: 0, count: Self.slices + 1)
        for s in 1..<Self.slices { sliceDepths[s] = near * exp2f(Float(s) / sliceScale) }
        sliceDepths[Self.slices] = far

        // (cluster, light) pairs, nearest light first.
        var references: [(cluster: Int32, light: UInt16)] = []
        for (index, v) in visible.enumerated() {
            lights.append(input[v.light])
            let c = v.center, r = v.radius, depth = -c.z
            // Padded a little, so a fragment on a slice boundary that the GPU's log2 rounds
            // into the neighboring slice still finds the light.
            let s0 = slice(depth: (depth - r) * 0.999), s1 = slice(depth: (depth + r) * 1.001)
            for s in s0...s1 {
                // The part of the sphere's depth range inside the slab (a padded neighbor
                // slice gets the sphere's near or far end).
                let za = min(max(sliceDepths[s], depth - r), depth + r)
                let zb = max(min(sliceDepths[s + 1], depth + r), za)
                // The sphere's widest cross-section within the slab.
                let gap = depth < za ? za - depth : (depth > zb ? depth - zb : 0)
                let crossSection = (max(r * r - gap * gap, 0)).squareRoot()
                guard let rect = projector.rect(center: c, radius: crossSection, near: za, far: zb) else { continue }
                let tx0 = max(Int(((rect.x0 + 1) * 0.5 * Float(Self.tilesX)).rounded(.down)), 0)
                let tx1 = min(Int(((rect.x1 + 1) * 0.5 * Float(Self.tilesX)).rounded(.down)), Self.tilesX - 1)
                let ty0 = max(Int(((1 - rect.y1) * 0.5 * Float(Self.tilesY)).rounded(.down)), 0)
                let ty1 = min(Int(((1 - rect.y0) * 0.5 * Float(Self.tilesY)).rounded(.down)), Self.tilesY - 1)
                guard tx0 <= tx1, ty0 <= ty1 else { continue }
                for ty in ty0...ty1 {
                    for tx in tx0...tx1 {
                        let box = projector.clusterBox(tileX: tx, tileY: ty, near: sliceDepths[s], far: sliceDepths[s + 1])
                        let closest = c.clamped(lowerBound: box.min, upperBound: box.max)
                        guard length(closest - c) <= r * 1.001 + 1e-4 else { continue }
                        references.append((Int32(Self.clusterIndex(tileX: tx, tileY: ty, slice: s)), UInt16(index)))
                    }
                }
            }
        }

        // Counting sort into per-cluster lists, within the limits.
        var kept = [Bool](repeating: false, count: references.count)
        var total = 0
        for (i, ref) in references.enumerated() {
            let cluster = Int(ref.cluster)
            guard total < Self.maxReferences, Int(cellCount[cluster]) < Self.maxLightsPerCluster else {
                stats.droppedReferences += 1
                continue
            }
            cellCount[cluster] += 1
            total += 1
            kept[i] = true
        }
        var first = 0
        for cluster in 0..<Self.clusterCount {
            cellFirst[cluster] = UInt16(first)
            first += Int(cellCount[cluster])
            stats.maxClusterLights = max(stats.maxClusterLights, Int(cellCount[cluster]))
        }
        indices = [UInt16](repeating: 0, count: total)
        var fill = cellFirst.map(Int.init)
        for (i, ref) in references.enumerated() where kept[i] {
            indices[fill[Int(ref.cluster)]] = ref.light
            fill[Int(ref.cluster)] += 1
        }
        stats.lights = lights.count
        stats.references = total
    }

    // MARK: - GPU data

    /// Must match the light blocks in mesh_surface.glsl (uniform buffers 3–7, std140).
    public struct GPUData {
        public static let entries = maxUniformBufferSize / 16
        /// xyz: position, w: 1 / range².
        public var positions = [Vec4](repeating: .zero, count: entries)
        /// rgb: color × intensity, w: spot scale (0 for point lights).
        public var colors = [Vec4](repeating: .zero, count: entries)
        /// xyz: spot direction (travel), w: spot offset (1 for point lights).
        public var directions = [Vec4](repeating: .zero, count: entries)
        /// One 32-bit word per cluster, 4 per vec4: first index | count << 16.
        public var cells = [SIMD4<UInt32>](repeating: .zero, count: entries)
        /// 10-bit light indices, 3 per 32-bit word (bits 0, 10, 20), 4 words per vec4.
        public var indices = [SIMD4<UInt32>](repeating: .zero, count: entries)

        public init() {}
    }

    /// Fills `data` with this frame's lights and clusters (`data` is reused between frames).
    public func write(to data: inout GPUData) {
        for (i, light) in lights.enumerated() {
            // The cone falloff is saturate(cos × scale + offset)²: 0 at the outer cone, 1 inside the inner one.
            var scale: Float = 0, offset: Float = 1
            if light.isSpot {
                scale = 1 / max(light.cosInner - light.cosOuter, 1e-4)
                offset = -light.cosOuter * scale
            }
            data.positions[i] = Vec4(light.position, 1 / (light.range * light.range))
            data.colors[i] = Vec4(light.color, scale)
            data.directions[i] = Vec4(light.direction, offset)
        }
        for cluster in 0..<Self.clusterCount {
            data.cells[cluster >> 2][cluster & 3] = UInt32(cellFirst[cluster]) | UInt32(cellCount[cluster]) << 16
        }
        for (i, index) in indices.enumerated() {
            let word = i / 3
            let shift = UInt32(i % 3 * 10)
            var value = data.indices[word >> 2][word & 3]
            value = value & ~(0x3FF << shift) | UInt32(index) << shift
            data.indices[word >> 2][word & 3] = value
        }
    }
}

/// Projects view-space boxes to NDC rectangles and tiles back to view-space boxes, for any
/// projection whose x / y rows don't mix (perspective, off-center or jittered, orthographic).
private struct Projector {
    // clip.x = p00 x + p20 z + p30, clip.y = p11 y + p21 z + p31, clip.w = p23 z + p33
    let p00, p20, p30, p11, p21, p31, p23, p33: Float

    init(_ m: Mat4) {
        (p00, p20, p30) = (m.c0.x, m.c2.x, m.c3.x)
        (p11, p21, p31) = (m.c1.y, m.c2.y, m.c3.y)
        (p23, p33) = (m.c2.w, m.c3.w)
    }

    /// The NDC rectangle of the box `center ± radius` in x and y between view depths `near`
    /// and `far`; the whole screen if the box reaches the camera plane. Nil if it's behind.
    func rect(center c: Vec3, radius r: Float, near: Float, far: Float) -> (x0: Float, x1: Float, y0: Float, y1: Float)? {
        let wNear = p33 - p23 * near, wFar = p33 - p23 * far
        guard max(wNear, wFar) > 0 else { return nil }
        guard min(wNear, wFar) > 1e-4 else { return (-1, 1, -1, 1) }
        var x0 = Float.infinity, x1 = -Float.infinity, y0 = Float.infinity, y1 = -Float.infinity
        // x / w is monotonic in x and in z over a box in front of the camera: the corners bound it.
        for depth in [near, far] {
            let z = -depth, w = p33 + p23 * z
            for x in [c.x - r, c.x + r] {
                let ndc = (p00 * x + p20 * z + p30) / w
                x0 = min(x0, ndc); x1 = max(x1, ndc)
            }
            for y in [c.y - r, c.y + r] {
                let ndc = (p11 * y + p21 * z + p31) / w
                y0 = min(y0, ndc); y1 = max(y1, ndc)
            }
        }
        // A sliver of padding against rounding differences with the rasterizer.
        let pad: Float = 1e-3
        x0 = max(x0 - pad, -1); x1 = min(x1 + pad, 1)
        y0 = max(y0 - pad, -1); y1 = min(y1 + pad, 1)
        return (x0, x1, y0, y1)
    }

    /// The view-space bounding box of a tile between two view depths.
    func clusterBox(tileX: Int, tileY: Int, near: Float, far: Float) -> (min: Vec3, max: Vec3) {
        let nx0 = Float(tileX) / Float(LightClusters.tilesX) * 2 - 1, nx1 = Float(tileX + 1) / Float(LightClusters.tilesX) * 2 - 1
        let ny1 = 1 - Float(tileY) / Float(LightClusters.tilesY) * 2, ny0 = 1 - Float(tileY + 1) / Float(LightClusters.tilesY) * 2
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for depth in [near, far] {
            let z = -depth, w = p33 + p23 * z
            for nx in [nx0, nx1] {
                for ny in [ny0, ny1] {
                    let p = Vec3((nx * w - p20 * z - p30) / p00, (ny * w - p21 * z - p31) / p11, z)
                    lo = pointwiseMin(lo, p); hi = pointwiseMax(hi, p)
                }
            }
        }
        return (lo, hi)
    }
}
