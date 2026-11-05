import Foundation

// A heightmap terrain: the contents of a `.terrain` file (JSON, every key optional).
// `TerrainImporter` turns it into chunk meshes (with normals and a triangle-mesh collider each),
// one material with the painted layers baked into its albedo texture, and a prefab of the chunks
// plus the scattered props (drawn instanced, since equal mesh and material batch together).
//
// The terrain is centered on its origin: local x runs -size.x/2...size.x/2, z likewise, y up
// from 0. Heights are quantized to 16 bits over `heightRange` meters and stored as base64, as
// are the layer weights (8 bits each, `resolution` x `resolution`).
//
// ```json
// {
//   "size": [128, 128], "resolution": 129, "heightRange": 64, "seed": 7,
//   "layers": [{"name": "Grass", "color": [0.2, 0.5, 0.15]},
//              {"name": "Rock", "texture": "Textures/rock.png", "tileSize": 6}],
//   "scatter": [{"name": "Pines", "asset": "Models/pine.meshbuild", "density": 20, "maxSlope": 30,
//                "layer": "Grass"}],
//   "heights": "<base64>", "splat": ["<base64>", "<base64>"]
// }
// ```

/// A sculpting brush.
public enum TerrainBrush: String, Codable, CaseIterable, Sendable {
    /// Adds up to `strength` meters per point at the center.
    case raise
    /// Removes up to `strength` meters per point at the center.
    case lower
    /// Blends toward the average of the neighbors by `strength` (0...1).
    case smooth
    /// Blends toward `height` (default: the terrain's height at the first point) by `strength` (0...1).
    case flatten
    /// Adds fractal noise of up to `strength` meters.
    case noise
}

/// A ground texture: a flat `color`, or a tiled `texture` (image or `.proctex`).
public struct TerrainLayer: Codable, Equatable, Sendable {
    public var name: String
    /// Display (sRGB) color 0...1, used when there is no texture (or it can't be read).
    public var color: Vec3
    /// A path under `Assets/` ("Textures/rock.png", a `.proctex`).
    public var texture: String
    /// Meters one repeat of the texture covers.
    public var tileSize: Float

    public static var fieldHints: [String: FieldHints] {
        ["color": FieldHints(color: true), "texture": FieldHints(tooltip: "An image or .proctex under Assets/"),
         "tileSize": FieldHints(range: 0.1...1000, step: 0.1, tooltip: "Meters per texture repeat")]
    }

    public init(name: String = "Layer", color: Vec3 = Vec3(0.4, 0.4, 0.4), texture: String = "", tileSize: Float = 4) {
        self.name = name
        self.color = color
        self.texture = texture
        self.tileSize = tileSize
    }

    private enum CodingKeys: String, CodingKey { case name, color, texture, tileSize }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TerrainLayer()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  color: try c.decodeIfPresent(Vec3.self, forKey: .color) ?? d.color,
                  texture: try c.decodeIfPresent(String.self, forKey: .texture) ?? d.texture,
                  tileSize: try c.decodeIfPresent(Float.self, forKey: .tileSize) ?? d.tileSize)
    }
}

/// A rule that scatters props over the terrain. `density` candidate spots per 100 m² are tried
/// on a jittered grid (seeded, so the result is stable); a spot is kept where the slope, height
/// and layer rules hold.
public struct TerrainScatter: Codable, Equatable, Sendable {
    public var name: String
    /// What to place: a `.meshbuild` path (every part of it is drawn), or a mesh reference
    /// "asset:<id>#mesh/<name>" (with `material` for its look).
    public var asset: String
    /// A material for a mesh reference ("asset:<id>#material", or a path to a `.material`).
    public var material: String
    /// Candidate spots per 100 m².
    public var density: Float
    /// Degrees from flat.
    public var minSlope: Float
    public var maxSlope: Float
    /// Meters above the terrain's origin plane.
    public var minHeight: Float
    public var maxHeight: Float
    /// Uniform scale range.
    public var minScale: Float
    public var maxScale: Float
    /// Only where this layer's weight is above 0.5 ("" anywhere).
    public var layer: String
    /// Tilts props to the ground's normal instead of standing them upright.
    public var alignToNormal: Bool
    public var seed: Int
    /// A cap on instances of this rule.
    public var maxCount: Int

    public static var fieldHints: [String: FieldHints] {
        ["density": FieldHints(range: 0...1000, step: 0.5, tooltip: "Candidate spots per 100 m²"),
         "minSlope": FieldHints(range: 0...90, step: 1), "maxSlope": FieldHints(range: 0...90, step: 1),
         "minScale": FieldHints(range: 0.01...100, step: 0.05), "maxScale": FieldHints(range: 0.01...100, step: 0.05),
         "asset": FieldHints(tooltip: "A .meshbuild path, or asset:<id>#mesh/<name>"),
         "layer": FieldHints(tooltip: "Only where this layer is painted (blank: anywhere)"),
         "maxCount": FieldHints(range: 0...20000, step: 100)]
    }

    public init(name: String = "Scatter", asset: String = "", material: String = "", density: Float = 5, minSlope: Float = 0,
                maxSlope: Float = 35, minHeight: Float = -10000, maxHeight: Float = 10000, minScale: Float = 0.8,
                maxScale: Float = 1.2, layer: String = "", alignToNormal: Bool = false, seed: Int = 1, maxCount: Int = 5000) {
        self.name = name
        self.asset = asset
        self.material = material
        self.density = density
        self.minSlope = minSlope
        self.maxSlope = maxSlope
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.minScale = minScale
        self.maxScale = maxScale
        self.layer = layer
        self.alignToNormal = alignToNormal
        self.seed = seed
        self.maxCount = maxCount
    }

    private enum CodingKeys: String, CodingKey {
        case name, asset, material, density, minSlope, maxSlope, minHeight, maxHeight, minScale, maxScale, layer, alignToNormal, seed, maxCount
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TerrainScatter()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  asset: try c.decodeIfPresent(String.self, forKey: .asset) ?? d.asset,
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material,
                  density: try c.decodeIfPresent(Float.self, forKey: .density) ?? d.density,
                  minSlope: try c.decodeIfPresent(Float.self, forKey: .minSlope) ?? d.minSlope,
                  maxSlope: try c.decodeIfPresent(Float.self, forKey: .maxSlope) ?? d.maxSlope,
                  minHeight: try c.decodeIfPresent(Float.self, forKey: .minHeight) ?? d.minHeight,
                  maxHeight: try c.decodeIfPresent(Float.self, forKey: .maxHeight) ?? d.maxHeight,
                  minScale: try c.decodeIfPresent(Float.self, forKey: .minScale) ?? d.minScale,
                  maxScale: try c.decodeIfPresent(Float.self, forKey: .maxScale) ?? d.maxScale,
                  layer: try c.decodeIfPresent(String.self, forKey: .layer) ?? d.layer,
                  alignToNormal: try c.decodeIfPresent(Bool.self, forKey: .alignToNormal) ?? d.alignToNormal,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  maxCount: try c.decodeIfPresent(Int.self, forKey: .maxCount) ?? d.maxCount)
    }
}

/// One placed prop of a scatter rule, in terrain space.
public struct TerrainInstance: Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat
    public var scale: Float
}

/// The contents of a `.terrain` file. See the notes at the top of this file.
public struct Terrain: Codable, Equatable, Sendable {
    public static let minResolution = 3
    public static let maxResolution = 1025
    public static let maxScatterInstances = 20_000

    /// Width (x) and depth (z) in meters.
    public var size: Vec2
    /// Height samples per side (3...1025); the grid has `resolution - 1` cells per side.
    public var resolution: Int
    /// Meters a full-scale height sample (1.0) stands for; heights span 0...`heightRange`.
    public var heightRange: Float
    /// Grid cells per chunk side (each chunk is its own mesh, so it culls separately).
    public var chunkCells: Int
    /// Mesh detail levels generated per chunk (1...4; level n uses every 2^n-th sample).
    /// The prefab uses level 0; the others are extra mesh sub-assets ("mesh/chunk 0_0 lod1").
    public var lods: Int
    /// Give each chunk a triangle-mesh collider.
    public var collider: Bool
    /// Every 2^n-th sample is used for colliders (0: full detail; 1...3 for big terrains).
    public var colliderLod: Int
    /// Side of the baked albedo texture in pixels (0: automatic, 4 per meter up to 2048).
    public var albedoSize: Int
    public var seed: Int
    public var layers: [TerrainLayer]
    public var scatter: [TerrainScatter]
    /// Height samples, row-major (z rows of x), 0...65535 over `heightRange`. Empty: flat at 0.
    public var heightData: [UInt16]
    /// Layer weights 0...255, one array per layer. Layers with no data are 0 (the first is 1
    /// everywhere when none have data).
    public var splatData: [[UInt8]]

    public static var fieldHints: [String: FieldHints] {
        ["size": FieldHints(range: 1...8192, step: 1, tooltip: "Meters (x, z)"),
         "resolution": FieldHints(range: Double(minResolution)...Double(maxResolution), step: 1, tooltip: "Height samples per side"),
         "heightRange": FieldHints(range: 0.1...2000, step: 1, tooltip: "Meters at full height"),
         "chunkCells": FieldHints(range: 2...256, step: 1), "lods": FieldHints(range: 1...4, step: 1),
         "colliderLod": FieldHints(range: 0...3, step: 1), "albedoSize": FieldHints(range: 0...2048, step: 1)]
    }

    public init(size: Vec2 = Vec2(128, 128), resolution: Int = 129, heightRange: Float = 64, chunkCells: Int = 32, lods: Int = 1,
                collider: Bool = true, colliderLod: Int = 0, albedoSize: Int = 0, seed: Int = 1, layers: [TerrainLayer] = [],
                scatter: [TerrainScatter] = [], heightData: [UInt16] = [], splatData: [[UInt8]] = []) {
        self.size = size
        self.resolution = resolution
        self.heightRange = heightRange
        self.chunkCells = chunkCells
        self.lods = lods
        self.collider = collider
        self.colliderLod = colliderLod
        self.albedoSize = albedoSize
        self.seed = seed
        self.layers = layers
        self.scatter = scatter
        self.heightData = heightData
        self.splatData = splatData
    }

    private enum CodingKeys: String, CodingKey {
        case size, resolution, heightRange, chunkCells, lods, collider, colliderLod, albedoSize, seed, layers, scatter, heights, splat
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Terrain()
        self.init(size: try c.decodeIfPresent(Vec2.self, forKey: .size) ?? d.size,
                  resolution: try c.decodeIfPresent(Int.self, forKey: .resolution) ?? d.resolution,
                  heightRange: try c.decodeIfPresent(Float.self, forKey: .heightRange) ?? d.heightRange,
                  chunkCells: try c.decodeIfPresent(Int.self, forKey: .chunkCells) ?? d.chunkCells,
                  lods: try c.decodeIfPresent(Int.self, forKey: .lods) ?? d.lods,
                  collider: try c.decodeIfPresent(Bool.self, forKey: .collider) ?? d.collider,
                  colliderLod: try c.decodeIfPresent(Int.self, forKey: .colliderLod) ?? d.colliderLod,
                  albedoSize: try c.decodeIfPresent(Int.self, forKey: .albedoSize) ?? d.albedoSize,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  layers: try c.decodeIfPresent([TerrainLayer].self, forKey: .layers) ?? [],
                  scatter: try c.decodeIfPresent([TerrainScatter].self, forKey: .scatter) ?? [])
        if let text = try c.decodeIfPresent(String.self, forKey: .heights), let data = Data(base64Encoded: text) {
            let bytes = [UInt8](data)
            heightData = stride(from: 0, to: bytes.count - 1, by: 2).map { UInt16(bytes[$0]) | UInt16(bytes[$0 + 1]) << 8 }
        }
        if let texts = try c.decodeIfPresent([String].self, forKey: .splat) {
            splatData = texts.map { [UInt8](Data(base64Encoded: $0) ?? Data()) }
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(size, forKey: .size)
        try c.encode(resolution, forKey: .resolution)
        try c.encode(heightRange, forKey: .heightRange)
        try c.encode(chunkCells, forKey: .chunkCells)
        try c.encode(lods, forKey: .lods)
        try c.encode(collider, forKey: .collider)
        try c.encode(colliderLod, forKey: .colliderLod)
        try c.encode(albedoSize, forKey: .albedoSize)
        try c.encode(seed, forKey: .seed)
        try c.encode(layers, forKey: .layers)
        try c.encode(scatter, forKey: .scatter)
        var bytes = Data(capacity: heightData.count * 2)
        for h in heightData { bytes.append(UInt8(h & 0xFF)); bytes.append(UInt8(h >> 8)) }
        try c.encode(bytes.base64EncodedString(), forKey: .heights)
        try c.encode(splatData.map { Data($0).base64EncodedString() }, forKey: .splat)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    // MARK: Creating

    /// A new terrain of `size` meters with rolling hills made from `seed`; `hilliness` 0 is flat
    /// (at 25% of the height range), 1 is rugged. Grass, rock and dirt layers, grass everywhere.
    public static func generated(size: Vec2 = Vec2(128, 128), resolution: Int = 129, seed: Int = 1, hilliness: Float = 0.5,
                                 heightRange: Float = 64) -> Terrain {
        var t = Terrain(size: size, resolution: resolution, heightRange: heightRange, seed: seed,
                        layers: [TerrainLayer(name: "Grass", color: Vec3(0.25, 0.5, 0.15)),
                                 TerrainLayer(name: "Rock", color: Vec3(0.45, 0.43, 0.4)),
                                 TerrainLayer(name: "Dirt", color: Vec3(0.4, 0.3, 0.2))])
        t.resolution = t.res
        t.normalizeData()
        let n = t.res
        let amplitude = min(max(hilliness, 0), 1)
        for z in 0..<n {
            for x in 0..<n {
                // Noise in meters, so the hills keep their size at any resolution.
                let px = Float(x) / Float(n - 1) * t.size.x, pz = Float(z) / Float(n - 1) * t.size.y
                let v = TerrainNoise.fractal(px / 40, pz / 40, seed: seed, octaves: 4)
                let height = 0.25 + (v - 0.5) * amplitude
                t.heightData[z * n + x] = UInt16(min(max(height, 0), 1) * 65535)
            }
        }
        return t
    }

    // MARK: Access

    /// The resolution clamped to the supported range.
    public var res: Int { min(max(resolution, Self.minResolution), Self.maxResolution) }
    var cells: Int { res - 1 }
    var cellSize: Vec2 { Vec2(max(size.x, 0.001), max(size.y, 0.001)) / Float(cells) }

    /// Makes `heightData` and `splatData` the size `resolution` and `layers` call for (padding
    /// with flat ground, and the first layer where nothing is painted).
    public mutating func normalizeData() {
        let n = res * res
        if heightData.count != n {
            heightData = Array(heightData.prefix(n)) + [UInt16](repeating: 0, count: max(n - heightData.count, 0))
        }
        if layers.isEmpty { splatData = []; return }
        var data = splatData
        let fresh = data.allSatisfy { $0.count != n }
        if data.count > layers.count { data.removeLast(data.count - layers.count) }
        while data.count < layers.count { data.append([]) }
        for i in data.indices where data[i].count != n {
            data[i] = [UInt8](repeating: i == 0 && fresh ? 255 : 0, count: n)
        }
        splatData = data
    }

    /// The height in meters of grid sample (x, z) (clamped to the grid).
    public func height(x: Int, z: Int) -> Float {
        let n = res
        let i = min(max(z, 0), n - 1) * n + min(max(x, 0), n - 1)
        return i < heightData.count ? Float(heightData[i]) / 65535 * heightRange : 0
    }

    /// Grid coordinates (fractional) of terrain-space (x, z) meters.
    func gridPosition(_ x: Float, _ z: Float) -> Vec2 {
        Vec2((x / max(size.x, 0.001) + 0.5) * Float(cells), (z / max(size.y, 0.001) + 0.5) * Float(cells))
    }

    /// Terrain-space x/z of grid sample (x, z).
    public func position(x: Int, z: Int) -> Vec2 {
        Vec2((Float(x) / Float(cells) - 0.5) * size.x, (Float(z) / Float(cells) - 0.5) * size.y)
    }

    /// The surface height in meters at terrain-space (x, z) (bilinear; clamped at the edges).
    public func heightAt(x: Float, z: Float) -> Float {
        let g = gridPosition(x, z)
        let gx = min(max(g.x, 0), Float(cells)), gz = min(max(g.y, 0), Float(cells))
        let x0 = min(Int(gx), cells - 1), z0 = min(Int(gz), cells - 1)
        let fx = gx - Float(x0), fz = gz - Float(z0)
        let a = height(x: x0, z: z0), b = height(x: x0 + 1, z: z0), c = height(x: x0, z: z0 + 1), d = height(x: x0 + 1, z: z0 + 1)
        return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz
    }

    /// The upward surface normal at grid sample (x, z), from central differences over the whole
    /// grid (so chunk seams agree).
    public func normal(x: Int, z: Int) -> Vec3 {
        let cs = cellSize
        let dx = (height(x: x + 1, z: z) - height(x: x - 1, z: z)) / (cs.x * Float((x > 0 && x < cells) ? 2 : 1))
        let dz = (height(x: x, z: z + 1) - height(x: x, z: z - 1)) / (cs.y * Float((z > 0 && z < cells) ? 2 : 1))
        return normalize(Vec3(-dx, 1, -dz))
    }

    /// The upward surface normal at terrain-space (x, z) (bilinear over the samples' normals).
    public func normalAt(x: Float, z: Float) -> Vec3 {
        let g = gridPosition(x, z)
        let gx = min(max(g.x, 0), Float(cells)), gz = min(max(g.y, 0), Float(cells))
        let x0 = min(Int(gx), cells - 1), z0 = min(Int(gz), cells - 1)
        let fx = gx - Float(x0), fz = gz - Float(z0)
        let n = (normal(x: x0, z: z0) * (1 - fx) + normal(x: x0 + 1, z: z0) * fx) * (1 - fz)
            + (normal(x: x0, z: z0 + 1) * (1 - fx) + normal(x: x0 + 1, z: z0 + 1) * fx) * fz
        return normalize(n)
    }

    /// Degrees the ground tilts from flat at terrain-space (x, z).
    public func slopeAt(x: Float, z: Float) -> Float {
        acosf(min(max(normalAt(x: x, z: z).y, -1), 1)) * 180 / .pi
    }

    /// The weight 0...1 of layer `layer` at grid sample (x, z).
    public func weight(layer: Int, x: Int, z: Int) -> Float {
        let n = res
        guard layers.indices.contains(layer) else { return 0 }
        let i = min(max(z, 0), n - 1) * n + min(max(x, 0), n - 1)
        if layer < splatData.count, i < splatData[layer].count { return Float(splatData[layer][i]) / 255 }
        // A terrain with no paint anywhere is all first layer.
        let painted = splatData.contains { $0.count == n * n }
        return layer == 0 && !painted ? 1 : 0
    }

    /// The weight of layer `layer` at terrain-space (x, z) (nearest sample).
    public func weightAt(layer: Int, x: Float, z: Float) -> Float {
        let g = gridPosition(x, z)
        return weight(layer: layer, x: Int(g.x.rounded()), z: Int(g.y.rounded()))
    }

    // MARK: Brushes

    /// 1 at the center to 0 at the edge: `falloff` 0 is a flat-topped disc, 1 a smooth dome.
    static func brushWeight(distance: Float, radius: Float, falloff: Float) -> Float {
        guard distance < radius else { return 0 }
        let t = distance / radius
        let smooth = 1 - t * t * (3 - 2 * t)
        let f = min(max(falloff, 0), 1)
        return 1 - f + f * smooth
    }

    private func samples(near p: Vec2, radius: Float) -> (x: ClosedRange<Int>, z: ClosedRange<Int>)? {
        let g = gridPosition(p.x, p.y)
        let rx = radius / cellSize.x, rz = radius / cellSize.y
        let x0 = max(Int((g.x - rx).rounded(.up)), 0), x1 = min(Int((g.x + rx).rounded(.down)), cells)
        let z0 = max(Int((g.y - rz).rounded(.up)), 0), z1 = min(Int((g.y + rz).rounded(.down)), cells)
        guard x0 <= x1, z0 <= z1 else { return nil }
        return (x0...x1, z0...z1)
    }

    /// Applies `brush` at each of `points` (terrain-space x, z meters) in order. `radius` is in
    /// meters, `strength` as described by `TerrainBrush`, `falloff` 0...1 (see `brushWeight`).
    /// Returns whether any height changed.
    @discardableResult
    public mutating func sculpt(_ brush: TerrainBrush, at points: [Vec2], radius: Float = 8, strength: Float = 0.5,
                                falloff: Float = 0.7, height target: Float? = nil) -> Bool {
        normalizeData()
        let n = res, before = heightData
        let radius = max(radius, 0.001)
        let flatHeight = target ?? points.first.map { heightAt(x: $0.x, z: $0.y) } ?? 0
        let range = max(heightRange, 0.001)
        for p in points {
            guard let box = samples(near: p, radius: radius) else { continue }
            var updates: [(Int, Float)] = []
            for z in box.z {
                for x in box.x {
                    let q = position(x: x, z: z)
                    let w = Self.brushWeight(distance: hypotf(q.x - p.x, q.y - p.y), radius: radius, falloff: falloff)
                    guard w > 0 else { continue }
                    let h = height(x: x, z: z)
                    var new = h
                    switch brush {
                    case .raise: new = h + strength * w
                    case .lower: new = h - strength * w
                    case .smooth:
                        var sum: Float = 0
                        for dz in -1...1 { for dx in -1...1 { sum += height(x: x + dx, z: z + dz) } }
                        new = h + (sum / 9 - h) * min(max(strength * w, 0), 1)
                    case .flatten: new = h + (flatHeight - h) * min(max(strength * w, 0), 1)
                    case .noise:
                        let v = TerrainNoise.fractal(q.x / 6, q.y / 6, seed: seed &+ 101, octaves: 3)
                        new = h + (v - 0.5) * 2 * strength * w
                    }
                    updates.append((z * n + x, min(max(new, 0), range)))
                }
            }
            // Applied after the sweep so one point reads unmodified neighbors.
            for (i, meters) in updates { heightData[i] = UInt16((meters / range * 65535).rounded()) }
        }
        return heightData != before
    }

    /// Paints layer `layer` (adding weight, or removing it with `erase`) at each of `points`.
    /// `strength` 0...1 is how much of the missing weight one point adds at its center. The
    /// other layers give way so weights keep summing to 1. Returns whether the layer exists.
    @discardableResult
    public mutating func paint(layer: Int, at points: [Vec2], radius: Float = 8, strength: Float = 0.8, falloff: Float = 0.7,
                               erase: Bool = false) -> Bool {
        guard layers.indices.contains(layer) else { return false }
        normalizeData()
        let n = res, count = layers.count
        let radius = max(radius, 0.001)
        for p in points {
            guard let box = samples(near: p, radius: radius) else { continue }
            for z in box.z {
                for x in box.x {
                    let w = Self.brushWeight(distance: { let q = position(x: x, z: z); return hypotf(q.x - p.x, q.y - p.y) }(), radius: radius, falloff: falloff)
                    guard w > 0 else { continue }
                    let amount = min(max(strength * w, 0), 1)
                    var weights = (0..<count).map { Float(splatData[$0][z * n + x]) / 255 }
                    let others = weights.enumerated().filter { $0.offset != layer }.map(\.element).reduce(0, +)
                    if erase {
                        let removed = weights[layer] * amount
                        weights[layer] -= removed
                        if others > 0.0001 {
                            for i in 0..<count where i != layer { weights[i] *= (others + removed) / others }
                        } else if count > 1 {
                            weights[layer == 0 ? 1 : 0] += removed
                        } else {
                            weights[layer] += removed
                        }
                    } else {
                        weights[layer] += (1 - weights[layer]) * amount
                        let room = 1 - weights[layer]
                        if others > 0.0001 {
                            for i in 0..<count where i != layer { weights[i] *= room / others }
                        }
                    }
                    for i in 0..<count { splatData[i][z * n + x] = UInt8(min(max(weights[i], 0), 1) * 255 + 0.5) }
                }
            }
        }
        return true
    }

    /// The index of the layer named `name` (nil if none).
    public func layerIndex(named name: String) -> Int? { layers.firstIndex { $0.name == name } }

    // MARK: Scatter

    /// The props rule `rule` places (terrain space), deterministic for its `seed` and the
    /// terrain's ground. Candidates are spread by a jittered grid so props don't clump.
    public func instances(of rule: TerrainScatter) -> [TerrainInstance] {
        guard rule.density > 0, size.x > 0, size.y > 0 else { return [] }
        let area = size.x * size.y
        let candidates = min(Int(rule.density * area / 100), Self.maxScatterInstances * 4)
        guard candidates > 0 else { return [] }
        var rng = TerrainRandom(seed: UInt64(bitPattern: Int64(rule.seed)) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(bitPattern: Int64(seed)))
        let layer = rule.layer.isEmpty ? nil : layerIndex(named: rule.layer)
        if !rule.layer.isEmpty && layer == nil { return [] }
        let columns = max(Int((Double(candidates) * Double(size.x / size.y)).squareRoot()), 1)
        let rows = max(Int((Double(candidates) / Double(columns)).rounded(.up)), 1)
        let cap = min(max(rule.maxCount, 0), Self.maxScatterInstances)
        var result: [TerrainInstance] = []
        for row in 0..<rows {
            for column in 0..<columns {
                // Always draw the same numbers so one rejection doesn't shift later props.
                let jx = rng.next(), jz = rng.next(), yaw = rng.next(), sc = rng.next()
                guard result.count < cap else { return result }
                let x = (Float(column) + jx) / Float(columns) * size.x - size.x / 2
                let z = (Float(row) + jz) / Float(rows) * size.y - size.y / 2
                let h = heightAt(x: x, z: z)
                guard h >= rule.minHeight, h <= rule.maxHeight else { continue }
                let slope = slopeAt(x: x, z: z)
                guard slope >= rule.minSlope, slope <= rule.maxSlope else { continue }
                if let layer, weightAt(layer: layer, x: x, z: z) <= 0.5 { continue }
                var rotation = Quat(angle: yaw * 2 * .pi, axis: Vec3(0, 1, 0))
                if rule.alignToNormal {
                    let n = normalAt(x: x, z: z)
                    let axis = cross(Vec3(0, 1, 0), n)
                    if length(axis) > 1e-5 { rotation = Quat(angle: acosf(min(max(n.y, -1), 1)), axis: axis) * rotation }
                }
                let scale = rule.minScale + (rule.maxScale - rule.minScale) * sc
                result.append(TerrainInstance(position: Vec3(x, h, z), rotation: rotation, scale: max(scale, 0.001)))
            }
        }
        return result
    }
}

// MARK: - Geometry

extension Terrain {
    /// Chunks along x and along z.
    public var chunkCounts: (x: Int, z: Int) {
        let c = min(max(chunkCells, 2), 256)
        let n = (cells + c - 1) / c
        return (n, n)
    }

    /// The grid sample range [first, last] chunk `(cx, cz)` covers.
    func chunkRange(_ cx: Int, _ cz: Int) -> (x: ClosedRange<Int>, z: ClosedRange<Int>) {
        let c = min(max(chunkCells, 2), 256)
        return (cx * c...min((cx + 1) * c, cells), cz * c...min((cz + 1) * c, cells))
    }

    /// Chunk `(cx, cz)` at detail level `lod` (0: every sample, n: every 2^n-th), in terrain
    /// space, with normals from the full grid, UVs spanning the whole terrain 0...1 and
    /// counter-clockwise (upward) faces. The last row and column of a chunk always exist, so
    /// neighbors at the same level meet exactly.
    public func chunkMesh(_ cx: Int, _ cz: Int, lod: Int = 0) -> MeshGeometry {
        let range = chunkRange(cx, cz)
        let step = 1 << min(max(lod, 0), 6)
        func axis(_ r: ClosedRange<Int>) -> [Int] {
            var v = Array(stride(from: r.lowerBound, to: r.upperBound, by: step))
            v.append(r.upperBound)
            return v
        }
        let xs = axis(range.x), zs = axis(range.z)
        var g = MeshGeometry(vertices: [], indices: [])
        g.vertices.reserveCapacity(xs.count * zs.count)
        for z in zs {
            for x in xs {
                let p = position(x: x, z: z)
                g.vertices.append(MeshVertex(position: Vec3(p.x, height(x: x, z: z), p.y), normal: normal(x: x, z: z),
                                             uv: Vec2(Float(x) / Float(cells), Float(z) / Float(cells))))
            }
        }
        let w = xs.count
        for j in 0..<(zs.count - 1) {
            for i in 0..<(xs.count - 1) {
                let a = UInt32(j * w + i), b = a + 1, c = a + UInt32(w), d = c + 1
                g.indices += [a, c, b, b, c, d]
            }
        }
        return g
    }

    /// Chunk `(cx, cz)`'s collision shape at `colliderLod`, in terrain space.
    public func chunkCollider(_ cx: Int, _ cz: Int) -> ColliderShape {
        let mesh = chunkMesh(cx, cz, lod: colliderLod)
        return .triangleMesh(vertices: mesh.vertices.map(\.position), indices: mesh.indices)
    }

    /// The whole terrain as one mesh (for previews and tests; large terrains should use chunks).
    public func fullMesh(lod: Int = 0) -> MeshGeometry {
        var all = MeshGeometry(vertices: [], indices: [])
        let counts = chunkCounts
        for cz in 0..<counts.z {
            for cx in 0..<counts.x {
                let m = chunkMesh(cx, cz, lod: lod), base = UInt32(all.vertices.count)
                all.vertices += m.vertices
                all.indices += m.indices.map { $0 + base }
            }
        }
        return all
    }

    /// The albedo texture: the layers blended by their painted weights (in display sRGB space),
    /// textured layers repeating every `tileSize` meters. `images` are the layers' decoded
    /// textures (nil: use the layer's flat color), by layer index.
    public func bakeAlbedo(images: [Image?] = []) -> Image {
        let auto = max(Int(max(size.x, size.y) * 4), 16)
        var pot = 16
        while pot < auto { pot *= 2 }
        let side = min(max(albedoSize > 0 ? albedoSize : pot, 4), 2048)
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        let count = layers.count
        for py in 0..<side {
            for px in 0..<side {
                let u = (Float(px) + 0.5) / Float(side), v = (Float(py) + 0.5) / Float(side)
                let x = (u - 0.5) * size.x, z = (v - 0.5) * size.y
                let g = gridPosition(x, z)
                let gx = min(max(g.x, 0), Float(cells)), gz = min(max(g.y, 0), Float(cells))
                let x0 = min(Int(gx), cells - 1), z0 = min(Int(gz), cells - 1)
                let fx = gx - Float(x0), fz = gz - Float(z0)
                var color = Vec3.zero
                for l in 0..<count {
                    let w = (weight(layer: l, x: x0, z: z0) * (1 - fx) + weight(layer: l, x: x0 + 1, z: z0) * fx) * (1 - fz)
                        + (weight(layer: l, x: x0, z: z0 + 1) * (1 - fx) + weight(layer: l, x: x0 + 1, z: z0 + 1) * fx) * fz
                    guard w > 0.001 else { continue }
                    let layer = layers[l]
                    var c = layer.color
                    if l < images.count, let image = images[l], image.width > 0, image.height > 0 {
                        let tile = max(layer.tileSize, 0.01)
                        let tx = x / tile, tz = z / tile
                        let ix = min(Int((tx - tx.rounded(.down)) * Float(image.width)), image.width - 1)
                        let iy = min(Int((tz - tz.rounded(.down)) * Float(image.height)), image.height - 1)
                        let o = (iy * image.width + ix) * 4
                        c = Vec3(Float(image.pixels[o]), Float(image.pixels[o + 1]), Float(image.pixels[o + 2])) / 255
                    }
                    color += c * w
                }
                let o = (py * side + px) * 4
                pixels[o] = UInt8(min(max(color.x, 0), 1) * 255 + 0.5)
                pixels[o + 1] = UInt8(min(max(color.y, 0), 1) * 255 + 0.5)
                pixels[o + 2] = UInt8(min(max(color.z, 0), 1) * 255 + 0.5)
            }
        }
        return Image(width: side, height: side, pixels: pixels)
    }
}

// MARK: - Noise

/// Deterministic value noise from integer hashing.
enum TerrainNoise {
    static func hash(_ x: Int, _ y: Int, _ seed: Int) -> Float {
        var h = UInt64(bitPattern: Int64(x)) &* 0x9E37_79B1_85EB_CA87 ^ UInt64(bitPattern: Int64(y)) &* 0xC2B2_AE3D_27D4_EB4F
            ^ UInt64(bitPattern: Int64(seed)) &* 0x1656_67B1_9E37_79F9
        h ^= h >> 33; h = h &* 0xFF51_AFD7_ED55_8CCD; h ^= h >> 33; h = h &* 0xC4CE_B9FE_1A85_EC53; h ^= h >> 33
        return Float(h >> 40) / Float(1 << 24)
    }

    /// Smooth value noise in 0...1.
    static func value(_ x: Float, _ y: Float, seed: Int) -> Float {
        let x0 = Int(x.rounded(.down)), y0 = Int(y.rounded(.down))
        let fx = x - Float(x0), fy = y - Float(y0)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        let a = hash(x0, y0, seed), b = hash(x0 + 1, y0, seed), c = hash(x0, y0 + 1, seed), d = hash(x0 + 1, y0 + 1, seed)
        return (a * (1 - sx) + b * sx) * (1 - sy) + (c * (1 - sx) + d * sx) * sy
    }

    /// Fractal sum of `octaves` value-noise layers, in 0...1.
    static func fractal(_ x: Float, _ y: Float, seed: Int, octaves: Int) -> Float {
        var sum: Float = 0, amplitude: Float = 1, total: Float = 0, frequency: Float = 1
        for o in 0..<octaves {
            sum += value(x * frequency, y * frequency, seed: seed &+ o * 7919) * amplitude
            total += amplitude
            amplitude *= 0.5
            frequency *= 2
        }
        return sum / total
    }
}

/// SplitMix64 as floats in 0..<1.
struct TerrainRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Float {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Float(z >> 40) / Float(1 << 24)
    }
}
