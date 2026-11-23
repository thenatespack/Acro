// Physics materials: what a surface is made of. A material sets friction, bounce and density
// (each optional: unset keeps the `Collider`'s own number), whether characters can climb it,
// and the footstep, impact and scrape effects (a sound and a VFX each) it makes, with
// overrides per pair of materials.
//
// Materials are named: a built-in (`PhysicsMaterial.builtIn`: wood, metal, stone, ice…), one
// registered in code (`physics.materials.register`) or a `.physmat` file under `Assets/` by
// its path ("Physics/Ice.physmat"), which the asset layer loads through
// `PhysicsMaterialLibrary.loader`.
//
// A `PhysicsSurface` component names an entity's material. The ECS sync applies it to the
// entity's `Collider` (the entity's own surface, else its nearest ancestor's), so friction,
// bounce and density come from the material. Queries ask what is under a point
// (`physics.materialUnder`) or at a hit (`physics.surfaceMaterialName(of:at:)`); a surface may
// carry a grid of materials over its entity's local XZ plane (terrain layers), so a single
// collider can be grass in one place and rock in another.
//
// `.physmat` files (JSON, every key optional):
//
// ```json
// {"friction": 0.05, "bounce": 0.1, "density": 917, "climbable": false,
//  "footstep": {"sound": "Sounds/IceStep.sfx", "vfx": "Effects/Frost.vfx", "volume": 0.8},
//  "impact": {"sound": "Sounds/IceHit.sfx"}, "scrape": {"sound": "Sounds/IceScrape.sfx"},
//  "minImpactSpeed": 1.5, "minScrapeSpeed": 0.5,
//  "pairs": {"metal": {"impact": {"sound": "Sounds/Clang.sfx"}}}}
// ```
import EngineCore
import EngineGraphics
import EngineScene

/// One effect a material makes: a sound and a visual effect, both optional (asset paths or
/// references, as `AudioEmitter.clip` and the `vfx.spawn` node take them).
public struct PhysicsMaterialEffect: Codable, Equatable, Sendable {
    public var sound: String?
    public var vfx: String?
    /// 0...1, default 1 (impacts and scrapes also scale it by speed).
    public var volume: Float?
    /// Playback rate, default 1.
    public var pitch: Float?

    public init(sound: String? = nil, vfx: String? = nil, volume: Float? = nil, pitch: Float? = nil) {
        self.sound = sound
        self.vfx = vfx
        self.volume = volume
        self.pitch = pitch
    }

    /// Neither a sound nor a VFX.
    public var isEmpty: Bool { (sound ?? "").isEmpty && (vfx ?? "").isEmpty }
}

/// What makes an effect.
public enum PhysicsEffectKind: String, Codable, Sendable, CaseIterable {
    /// A character's foot touching the ground (every stride while walking).
    case footstep
    /// Two bodies hitting each other faster than `minImpactSpeed`.
    case impact
    /// Two bodies sliding along each other faster than `minScrapeSpeed`.
    case scrape
}

/// The effects of one pair of materials (`PhysicsMaterial.pairs`).
public struct PhysicsMaterialEffects: Codable, Equatable, Sendable {
    public var footstep: PhysicsMaterialEffect?
    public var impact: PhysicsMaterialEffect?
    public var scrape: PhysicsMaterialEffect?

    public init(footstep: PhysicsMaterialEffect? = nil, impact: PhysicsMaterialEffect? = nil, scrape: PhysicsMaterialEffect? = nil) {
        self.footstep = footstep
        self.impact = impact
        self.scrape = scrape
    }

    public subscript(kind: PhysicsEffectKind) -> PhysicsMaterialEffect? {
        switch kind {
        case .footstep: footstep
        case .impact: impact
        case .scrape: scrape
        }
    }
}

/// A surface's physical properties and effects. Every key is optional; see the notes at the top
/// of PhysicsMaterial.swift.
public struct PhysicsMaterial: Codable, Equatable, Sendable {
    /// Coulomb friction (a pair uses the geometric mean of both); nil keeps the collider's.
    public var friction: Float?
    /// Restitution 0...1 (a pair uses the larger); nil keeps the collider's.
    public var bounce: Float?
    /// kg/m³ for dynamic bodies; nil keeps the collider's.
    public var density: Float?
    /// Characters (`CharacterController.climbSpeed` > 0) climb walls of this material.
    public var climbable: Bool?
    public var footstep: PhysicsMaterialEffect?
    public var impact: PhysicsMaterialEffect?
    public var scrape: PhysicsMaterialEffect?
    /// Effects against another material (its name: a built-in or a `.physmat` path), used
    /// instead of either material's own. Either material of a pair may list the other.
    public var pairs: [String: PhysicsMaterialEffects]?
    /// Impacts slower than this (m/s along the normal) make no effect. Default 1.5.
    public var minImpactSpeed: Float?
    /// Slides slower than this (m/s) make no scrape. Default 0.5.
    public var minScrapeSpeed: Float?

    public init(friction: Float? = nil, bounce: Float? = nil, density: Float? = nil, climbable: Bool? = nil,
                footstep: PhysicsMaterialEffect? = nil, impact: PhysicsMaterialEffect? = nil, scrape: PhysicsMaterialEffect? = nil,
                pairs: [String: PhysicsMaterialEffects]? = nil, minImpactSpeed: Float? = nil, minScrapeSpeed: Float? = nil) {
        self.friction = friction
        self.bounce = bounce
        self.density = density
        self.climbable = climbable
        self.footstep = footstep
        self.impact = impact
        self.scrape = scrape
        self.pairs = pairs
        self.minImpactSpeed = minImpactSpeed
        self.minScrapeSpeed = minScrapeSpeed
    }

    public static let defaultMinImpactSpeed: Float = 1.5
    public static let defaultMinScrapeSpeed: Float = 0.5

    public subscript(kind: PhysicsEffectKind) -> PhysicsMaterialEffect? {
        switch kind {
        case .footstep: footstep
        case .impact: impact
        case .scrape: scrape
        }
    }

    /// `collider` with this material's friction, bounce and density where it sets them.
    public func applied(to collider: Collider) -> Collider {
        var c = collider
        if let friction { c.friction = max(friction, 0) }
        if let bounce { c.restitution = min(max(bounce, 0), 1) }
        if let density, density > 0 { c.density = density }
        return c
    }

    /// Problems worth a warning: values out of range, effects naming nothing.
    public func problems() -> [String] {
        var found: [String] = []
        if let friction, !(0...4).contains(friction) { found.append("friction \(friction) is outside 0...4 (ice is about 0.03, rubber 1)") }
        if let bounce, !(0...1).contains(bounce) { found.append("bounce \(bounce) is outside 0...1 (it is clamped)") }
        if let density, density <= 0 { found.append("density \(density) must be above 0 kg/m³ (it is ignored)") }
        if let density, density > 25_000 { found.append("density \(density) kg/m³ is heavier than any real material (lead: 11340)") }
        if let minImpactSpeed, minImpactSpeed < 0 { found.append("minImpactSpeed \(minImpactSpeed) is negative") }
        if let minScrapeSpeed, minScrapeSpeed < 0 { found.append("minScrapeSpeed \(minScrapeSpeed) is negative") }
        func check(_ effect: PhysicsMaterialEffect?, _ label: String) {
            guard let effect else { return }
            if effect.isEmpty { found.append("\(label) has neither a sound nor a vfx") }
            if let volume = effect.volume, !(0...4).contains(volume) { found.append("\(label).volume \(volume) is outside 0...4") }
            if let pitch = effect.pitch, !(0.05...8).contains(pitch) { found.append("\(label).pitch \(pitch) is outside 0.05...8") }
        }
        for kind in PhysicsEffectKind.allCases { check(self[kind], kind.rawValue) }
        for (other, effects) in (pairs ?? [:]).sorted(by: { $0.key < $1.key }) {
            if other.trimmingCharacters(in: .whitespaces).isEmpty { found.append("pairs: a pair has an empty material name") }
            for kind in PhysicsEffectKind.allCases { check(effects[kind], "pairs.\(other).\(kind.rawValue)") }
        }
        return found
    }

    /// Every sound and VFX it names, with where (for reference checks).
    public var effectReferences: [(label: String, sound: String?, vfx: String?)] {
        var all: [(String, String?, String?)] = []
        for kind in PhysicsEffectKind.allCases {
            if let e = self[kind] { all.append((kind.rawValue, e.sound, e.vfx)) }
        }
        for (other, effects) in (pairs ?? [:]).sorted(by: { $0.key < $1.key }) {
            for kind in PhysicsEffectKind.allCases {
                if let e = effects[kind] { all.append(("pairs.\(other).\(kind.rawValue)", e.sound, e.vfx)) }
            }
        }
        return all
    }

    // MARK: Built-ins

    /// Materials every project has, by name (no sounds or effects: give those in a `.physmat`).
    public static let builtIn: [String: PhysicsMaterial] = [
        "default": PhysicsMaterial(friction: 0.5, bounce: 0, density: 1000),
        "wood": PhysicsMaterial(friction: 0.5, bounce: 0.15, density: 700),
        "metal": PhysicsMaterial(friction: 0.35, bounce: 0.1, density: 7800),
        "stone": PhysicsMaterial(friction: 0.7, bounce: 0.05, density: 2500),
        "concrete": PhysicsMaterial(friction: 0.8, bounce: 0.05, density: 2400),
        "brick": PhysicsMaterial(friction: 0.75, bounce: 0.05, density: 1900),
        "dirt": PhysicsMaterial(friction: 0.75, bounce: 0, density: 1500),
        "grass": PhysicsMaterial(friction: 0.6, bounce: 0, density: 1200),
        "sand": PhysicsMaterial(friction: 0.9, bounce: 0, density: 1600),
        "mud": PhysicsMaterial(friction: 1.0, bounce: 0, density: 1800),
        "ice": PhysicsMaterial(friction: 0.03, bounce: 0.05, density: 917),
        "rubber": PhysicsMaterial(friction: 1.0, bounce: 0.8, density: 1100),
        "glass": PhysicsMaterial(friction: 0.4, bounce: 0.1, density: 2500),
        "plastic": PhysicsMaterial(friction: 0.4, bounce: 0.3, density: 950),
        "fabric": PhysicsMaterial(friction: 0.8, bounce: 0, density: 300),
        "ceramic": PhysicsMaterial(friction: 0.45, bounce: 0.1, density: 2300),
        "climbingWall": PhysicsMaterial(friction: 0.8, bounce: 0, density: 2000, climbable: true),
    ]

    /// The built-in names, sorted.
    public static var builtInNames: [String] { builtIn.keys.sorted() }

    /// The built-in material called `name` (any case).
    public static func builtIn(named name: String) -> PhysicsMaterial? {
        if let m = builtIn[name] { return m }
        let lower = name.lowercased()
        return builtIn.first { $0.key.lowercased() == lower }?.value
    }
}

/// The materials a `PhysicsWorld` knows by name: ones registered in code, the built-ins, and
/// files the asset layer loads through `loader` (cached until `reload()`).
@MainActor
public final class PhysicsMaterialLibrary {
    /// Loads a material by name (a `.physmat` path); the asset layer sets it while playing.
    public var loader: ((String) -> PhysicsMaterial?)? {
        didSet { cache.removeAll() }
    }
    private var registered: [String: PhysicsMaterial] = [:]
    private var cache: [String: PhysicsMaterial?] = [:]

    public init() {}

    /// Makes `material` known as `name` (wins over a built-in or a file of that name).
    public func register(_ name: String, _ material: PhysicsMaterial) {
        registered[name] = material
        cache.removeAll()
    }

    /// Forgets loaded files (call after a `.physmat` changes).
    public func reload() { cache.removeAll() }

    /// The material called `name`: registered, built-in, or loaded. Nil for "" and unknown names.
    public func material(named name: String) -> PhysicsMaterial? {
        guard !name.isEmpty else { return nil }
        if let m = registered[name] { return m }
        if let m = PhysicsMaterial.builtIn(named: name) { return m }
        if let cached = cache[name] { return cached }
        let loaded = loader?(name)
        cache[name] = loaded
        return loaded
    }

    /// `material(named:)`, or the built-in "default".
    public func resolved(_ name: String) -> PhysicsMaterial {
        material(named: name) ?? PhysicsMaterial.builtIn["default"]!
    }

    /// The effect of `kind` when material `a` meets material `b`: a pair entry in either
    /// (`a`'s first), else `b`'s own effect, else `a`'s. `b` is the surface (the ground under a
    /// footstep, the thing hit).
    public func effect(_ kind: PhysicsEffectKind, _ a: String, _ b: String) -> PhysicsMaterialEffect? {
        let ma = material(named: a), mb = material(named: b)
        if let e = ma?.pairs?[b]?[kind], !e.isEmpty { return e }
        if let e = mb?.pairs?[a]?[kind], !e.isEmpty { return e }
        if let e = mb?[kind], !e.isEmpty { return e }
        if let e = ma?[kind], !e.isEmpty { return e }
        return nil
    }
}

/// A grid of material names over an entity's local XZ plane (a terrain's layers): cell
/// (column, row) covers `origin + (column, row) * cellSize` (x, z meters). Cells hold an index into
/// `materials`; 255 means the surface's own `material`.
public struct PhysicsSurfaceGrid: Codable, Equatable, Sendable {
    public var materials: [String]
    /// The local (x, z) of cell (0, 0)'s corner.
    public var origin: Vec2
    public var cellSize: Vec2
    public var columns: Int
    public var rows: Int
    /// Row-major material indices (`rows * columns`), saved as base64.
    public var cells: [UInt8]

    public init(materials: [String], origin: Vec2, cellSize: Vec2, columns: Int, rows: Int, cells: [UInt8]) {
        self.materials = materials
        self.origin = origin
        self.cellSize = cellSize
        self.columns = columns
        self.rows = rows
        self.cells = cells
    }

    private enum CodingKeys: String, CodingKey { case materials, origin, cellSize, columns, rows, cells }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        materials = try c.decodeIfPresent([String].self, forKey: .materials) ?? []
        origin = try c.decodeIfPresent(Vec2.self, forKey: .origin) ?? .zero
        cellSize = try c.decodeIfPresent(Vec2.self, forKey: .cellSize) ?? Vec2(1, 1)
        columns = try c.decodeIfPresent(Int.self, forKey: .columns) ?? 0
        rows = try c.decodeIfPresent(Int.self, forKey: .rows) ?? 0
        let text = try c.decodeIfPresent(String.self, forKey: .cells) ?? ""
        cells = Self.decodeBase64(text)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(materials, forKey: .materials)
        try c.encode(origin, forKey: .origin)
        try c.encode(cellSize, forKey: .cellSize)
        try c.encode(columns, forKey: .columns)
        try c.encode(rows, forKey: .rows)
        try c.encode(Self.encodeBase64(cells), forKey: .cells)
    }

    /// The material name at local (x, z); nil outside the grid or for a 255 cell.
    public func material(atLocal x: Float, _ z: Float) -> String? {
        guard cellSize.x > 0, cellSize.y > 0, columns > 0, rows > 0, cells.count == columns * rows else { return nil }
        let cx = Int(((x - origin.x) / cellSize.x).rounded(.down)), cz = Int(((z - origin.y) / cellSize.y).rounded(.down))
        guard (0..<columns).contains(cx), (0..<rows).contains(cz) else { return nil }
        let index = Int(cells[cz * columns + cx])
        return materials.indices.contains(index) ? materials[index] : nil
    }

    // Base64 without Foundation (EnginePhysics doesn't import it).
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)

    static func encodeBase64(_ bytes: [UInt8]) -> String {
        var out: [UInt8] = []
        out.reserveCapacity((bytes.count + 2) / 3 * 4)
        var i = 0
        while i < bytes.count {
            let b0 = UInt32(bytes[i]), b1 = i + 1 < bytes.count ? UInt32(bytes[i + 1]) : 0, b2 = i + 2 < bytes.count ? UInt32(bytes[i + 2]) : 0
            let v = b0 << 16 | b1 << 8 | b2
            out.append(alphabet[Int(v >> 18 & 63)])
            out.append(alphabet[Int(v >> 12 & 63)])
            out.append(i + 1 < bytes.count ? alphabet[Int(v >> 6 & 63)] : UInt8(ascii: "="))
            out.append(i + 2 < bytes.count ? alphabet[Int(v & 63)] : UInt8(ascii: "="))
            i += 3
        }
        return String(decoding: out, as: UTF8.self)
    }

    static func decodeBase64(_ text: String) -> [UInt8] {
        var lookup = [Int](repeating: -1, count: 256)
        for (i, c) in alphabet.enumerated() { lookup[Int(c)] = i }
        var out: [UInt8] = []
        var buffer: UInt32 = 0, bits = 0
        for c in text.utf8 {
            let v = lookup[Int(c)]
            guard v >= 0 else { continue }
            buffer = buffer << 6 | UInt32(v)
            bits += 6
            if bits >= 8 {
                bits -= 8
                out.append(UInt8(buffer >> UInt32(bits) & 0xFF))
            }
        }
        return out
    }
}

/// Names what an entity is made of (see PhysicsMaterial.swift). On an entity with a `Collider`
/// (or an ancestor of one) it sets the body's friction, bounce and density; queries and the
/// footstep / impact / scrape effects read it.
public struct PhysicsSurface: Component, Codable, Equatable, Sendable {
    public static let componentName = "PhysicsSurface"
    public static var fieldHints: [String: FieldHints] {
        ["material": FieldHints(tooltip: "A built-in material (wood, metal, stone, ice, rubber, …) or a .physmat path under Assets/"),
         "regions": FieldHints(readOnly: true, tooltip: "Materials by area (terrain layers), written by importers")]
    }

    /// A built-in name or a `.physmat` path; "" is the "default" material.
    public var material: String
    /// Materials by area of the entity's local XZ plane (terrains); nil: `material` everywhere.
    public var regions: PhysicsSurfaceGrid?

    public init(material: String = "default", regions: PhysicsSurfaceGrid? = nil) {
        self.material = material
        self.regions = regions
    }

    private enum CodingKeys: String, CodingKey { case material, regions }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        material = try c.decodeIfPresent(String.self, forKey: .material) ?? ""
        regions = try c.decodeIfPresent(PhysicsSurfaceGrid.self, forKey: .regions)
    }

    /// The material name at a point given in the entity's local frame.
    public func material(atLocal p: Vec3) -> String {
        regions?.material(atLocal: p.x, p.z) ?? material
    }
}

/// What `PhysicsWorld.materialUnder` found.
public struct SurfaceProbe: Equatable, Sendable {
    /// The material's name ("default" when nothing names one).
    public var name: String
    public var material: PhysicsMaterial
    public var hit: RaycastHit
}

extension PhysicsWorld {
    /// The material name of `body` at the world point `point` ("default" when it has none).
    public func surfaceMaterialName(of body: BodyID, at point: Vec3) -> String {
        guard let i = index(of: body), let surface = bodies[i].surface else { return "default" }
        let name = surface.material(atLocal: bodies[i].pose.inverseTransform(point))
        return name.isEmpty ? "default" : name
    }

    /// The material of `body` at `point`.
    public func surfaceMaterial(of body: BodyID, at point: Vec3) -> PhysicsMaterial {
        materials.resolved(surfaceMaterialName(of: body, at: point))
    }

    /// Whether characters climb `body` at `point` (its material is `climbable`).
    public func isClimbable(_ body: BodyID, at point: Vec3) -> Bool {
        surfaceMaterial(of: body, at: point).climbable ?? false
    }

    /// The surface below `point` within `maxDistance` (a ray straight down from just above it)
    /// and its material.
    public func materialUnder(_ point: Vec3, maxDistance: Float = 2, filter: QueryFilter = .default) -> SurfaceProbe? {
        let lift: Float = 0.05
        guard let hit = raycast(Ray(origin: point + Vec3(0, lift, 0), direction: Vec3(0, -1, 0)), maxDistance: maxDistance + lift,
                                filter: filter) else { return nil }
        let name = surfaceMaterialName(of: hit.body, at: hit.point)
        return SurfaceProbe(name: name, material: materials.resolved(name), hit: hit)
    }

    /// The `PhysicsSurface` that applies to `entity`: its own, else its nearest ancestor's.
    public func surface(for entity: Entity, in world: World) -> PhysicsSurface? {
        var current: Entity? = entity
        while let e = current {
            if let s = world.get(PhysicsSurface.self, for: e) { return s }
            current = world.parent(of: e)
        }
        return nil
    }
}
