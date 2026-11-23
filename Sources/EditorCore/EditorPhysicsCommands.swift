import Engine
import Foundation

/// Physics v2 tools: physics materials (`physicsMaterial.new`, `.get`, `.set`, `.edit`, `.list`),
/// what is under a point (`physics.materialAt`) and the character controller's moves
/// (`character.state`, `character.action`).
@MainActor
public enum EditorPhysicsCommands {
    public static let all: [any EditorCommand.Type] = [
        PhysicsMaterialNewCommand.self,
        PhysicsMaterialGetCommand.self,
        PhysicsMaterialSetCommand.self,
        PhysicsMaterialEditCommand.self,
        PhysicsMaterialListCommand.self,
        PhysicsMaterialAtCommand.self,
        CharacterStateCommand.self,
        CharacterActionCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A physics material (.physmat, every key optional) says what a surface is made of: friction (Coulomb, a pair uses \
        the geometric mean; ice 0.03, rubber 1), bounce (restitution 0-1, a pair uses the larger), density (kg/m³, for \
        dynamic bodies), climbable (characters climb walls of it), footstep / impact / scrape effects ({sound, vfx, volume, \
        pitch}: sound an audio file or .sfx path, vfx a .vfx or prefab path), minImpactSpeed (m/s, default 1.5), \
        minScrapeSpeed (default 0.5) and pairs ({"<other material>": {impact: {...}, scrape: {...}, footstep: {...}}}, used \
        instead of either material's own effects). Unset friction, bounce or density keep the Collider's own. Use it by \
        adding a PhysicsSurface component {material: "<path or built-in>"} to an entity with a Collider (or an ancestor of \
        one), a Mesh Builder part's `physicsMaterial` or a terrain layer's `physicsMaterial`. Built-ins: \
        \(PhysicsMaterial.builtInNames.joined(separator: ", ")).
        """
}

extension EditorSession {
    /// Writes a physics material to "`name`.physmat" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createPhysicsMaterialAsset(in folder: String, name: String = "New Physics Material",
                                           material: PhysicsMaterial = PhysicsMaterial(friction: 0.5, bounce: 0)) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Physics Material") else {
            log.error("New Physics Material: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".physmat"))
        do {
            let id = try assets.createPhysicsMaterial(material, at: path)
            log.info("Created physics material \(path)")
            return id
        } catch {
            log.error("New Physics Material failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.physmat` file.
    public func isPhysicsMaterialFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == PhysicsMaterialImporter().name
    }

    /// Replaces the contents of the physics material `id` as one undo step. Returns the
    /// import's warnings, nil on failure.
    @discardableResult
    public func applyPhysicsMaterial(_ material: PhysicsMaterial, to id: AssetID, label: String = "Edit Physics Material") -> [String]? {
        guard let assets, let old = assets.physicsMaterial(of: id) else {
            log.error("\(label): \(id) isn't a readable .physmat file")
            return nil
        }
        guard old != material else { return [] }
        let command = PhysicsMaterialFileEditCommand(asset: id, old: old, new: material, in: assets, label: label)
        guard perform(command) else { return nil }
        physics?.materials.reload()
        return command.warnings.value
    }

    /// The physics material named by `asset` / `path` and its contents.
    func resolvePhysicsMaterial(_ asset: AssetReference?, _ path: String?, _ title: String) throws -> (AssetID, PhysicsMaterial) {
        let id = try resolveAsset(asset, path: path, title)
        guard isPhysicsMaterialFile(id), let material = assets?.physicsMaterial(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .physmat file")
        }
        return (id, material)
    }

    /// A physics world for queries: the playing one, or (editing) one built from the scene's colliders now.
    func queryPhysics() -> PhysicsWorld {
        if let physics { return physics }
        let physics = PhysicsWorld()
        physics.materials.load(from: { [weak self] in self?.assets })
        physics.syncFromWorld(world, dt: 1.0 / 60)
        return physics
    }
}

/// Makes physics material edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct PhysicsMaterialFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: PhysicsMaterial
    public let new: PhysicsMaterial
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: PhysicsMaterial, new: PhysicsMaterial, in database: AssetDatabase, label: String = "Edit Physics Material") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ material: PhysicsMaterial) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writePhysicsMaterial(material, to: asset)
    }
}

/// What the physics material tools return.
public struct PhysicsMaterialResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// What to put in a PhysicsSurface's `material` (the path under Assets/).
    public var name: String
    public var material: PhysicsMaterial
    /// The numbers a collider gets (unset keys: the Collider's own, shown as the default material's).
    public var friction: Float
    public var bounce: Float
    public var density: Float
    public var warnings: [String]
}

extension PhysicsMaterialResult {
    @MainActor init(_ id: AssetID, _ material: PhysicsMaterial, warnings: [String], in session: EditorSession) {
        let path = session.assets?.path(of: id) ?? ""
        let record = session.assets?.record(id)
        let fallback = PhysicsMaterial.builtIn["default"]!
        let references = session.assets.map { assets in
            PhysicsMaterialImporter.referenceProblems(material) { assets.id(forPath: $0.hasPrefix("Assets/") ? String($0.dropFirst(7)) : $0) != nil }
        } ?? []
        self.init(asset: id, path: path, name: path, material: material, friction: material.friction ?? fallback.friction!,
                  bounce: material.bounce ?? fallback.bounce!, density: material.density ?? fallback.density!,
                  warnings: Array(Set(material.problems() + references + warnings)).sorted() + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum PhysicsMaterialNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Physics Material" (the file gets ".physmat").
        public var name: String?
        /// Start from a built-in's numbers (wood, metal, ice, rubber, …).
        public var preset: String?
        /// Or the whole contents (overrides `preset`).
        public var material: PhysicsMaterial?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, material: PhysicsMaterial? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.material = material
        }
    }

    public static let id: CommandID = "physicsMaterial.new"
    public static let title = "New Physics Material"
    public static let doc = "Writes a .physmat file in `folder` (default: the Assets root) from `preset` (a built-in's friction, bounce and density) or `material`. Returns the asset, the name to put in a PhysicsSurface, the effective numbers and warnings (out-of-range values, sounds or effects that don't exist, unknown pair materials). " + EditorPhysicsCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PhysicsMaterialResult {
        var material = arguments.material ?? PhysicsMaterial(friction: 0.5, bounce: 0)
        if arguments.material == nil, let preset = arguments.preset {
            guard let found = PhysicsMaterial.preset(preset) else {
                throw CommandError.failed("\(title): no built-in '\(preset)' (built-ins: \(PhysicsMaterial.builtInNames.joined(separator: ", ")))")
            }
            material = found
        }
        let id = try session.commands.require(session.createPhysicsMaterialAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Physics Material", material: material), title)
        return PhysicsMaterialResult(id, material, warnings: [], in: session)
    }
}

public enum PhysicsMaterialGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "physicsMaterial.get"
    public static let title = "Get Physics Material"
    public static let doc = "Reads a .physmat file: its keys, the friction, bounce and density colliders get, and warnings."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PhysicsMaterialResult {
        let (id, material) = try session.resolvePhysicsMaterial(arguments.asset, arguments.path, title)
        return PhysicsMaterialResult(id, material, warnings: [], in: session)
    }
}

public enum PhysicsMaterialSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys are unset, not the file's old values.
        public var material: PhysicsMaterial
        public init(asset: AssetReference? = nil, path: String? = nil, material: PhysicsMaterial) {
            self.asset = asset
            self.path = path
            self.material = material
        }
    }

    public static let id: CommandID = "physicsMaterial.set"
    public static let title = "Set Physics Material"
    public static let doc = "Replaces a .physmat file's whole contents and reimports it. Undoable. While playing, bodies pick the change up on their next sync. For a few changes, physicsMaterial.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PhysicsMaterialResult {
        let (id, _) = try session.resolvePhysicsMaterial(arguments.asset, arguments.path, title)
        let warnings = try session.commands.require(session.applyPhysicsMaterial(arguments.material, to: id, label: title), title)
        return PhysicsMaterialResult(id, arguments.material, warnings: warnings, in: session)
    }
}

public enum PhysicsMaterialEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Keys to change, e.g. {"friction": 0.05, "impact": {"sound": "Sounds/Clang.sfx"}}; null removes a key.
        public var changes: JSONValue
        public init(asset: AssetReference? = nil, path: String? = nil, changes: JSONValue) {
            self.asset = asset
            self.path = path
            self.changes = changes
        }
    }

    public static let id: CommandID = "physicsMaterial.edit"
    public static let title = "Edit Physics Material"
    public static let doc = "Changes some keys of a .physmat file in one undoable step (`changes`: key → new value, null to unset it; whole objects replace, e.g. `impact`). Returns the new contents, the numbers colliders get and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PhysicsMaterialResult {
        let (id, original) = try session.resolvePhysicsMaterial(arguments.asset, arguments.path, title)
        let material = try edited(original, with: arguments.changes)
        let warnings = try session.commands.require(session.applyPhysicsMaterial(material, to: id, label: title), title)
        return PhysicsMaterialResult(id, material, warnings: warnings, in: session)
    }

    /// `material` with `changes` applied (pure, for tests).
    public static func edited(_ material: PhysicsMaterial, with changes: JSONValue) throws -> PhysicsMaterial {
        guard case .object(let fields) = changes else { throw CommandError.failed("changes must be an object of keys") }
        guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(material)) else { return material }
        for (key, value) in fields {
            if case .null = value { current[key] = nil } else { current[key] = value }
        }
        do { return try JSONDecoder().decode(PhysicsMaterial.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
            throw CommandError.failed("changes: \(error)")
        }
    }
}

public enum PhysicsMaterialListCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public init() {}
    }

    public struct Entry: Codable, Equatable, Sendable {
        /// What a PhysicsSurface's `material` takes.
        public var name: String
        public var builtIn: Bool
        public var friction: Float?
        public var bounce: Float?
        public var density: Float?
        public var climbable: Bool?
        /// Which effects it has (footstep, impact, scrape) and how many pairs.
        public var effects: [String]
        public var pairs: Int
    }

    public struct Result: Codable, Equatable, Sendable {
        public var materials: [Entry]
    }

    public static let id: CommandID = "physicsMaterial.list"
    public static let title = "List Physics Materials"
    public static let doc = "Lists the physics materials a PhysicsSurface can name: the built-ins and the project's .physmat files, with friction, bounce, density, climbable and which effects each has."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        func entry(_ name: String, _ m: PhysicsMaterial, builtIn: Bool) -> Entry {
            Entry(name: name, builtIn: builtIn, friction: m.friction, bounce: m.bounce, density: m.density, climbable: m.climbable,
                  effects: PhysicsEffectKind.allCases.filter { m[$0].map { !$0.isEmpty } ?? false }.map(\.rawValue), pairs: m.pairs?.count ?? 0)
        }
        var all = PhysicsMaterial.builtInNames.map { entry($0, PhysicsMaterial.builtIn[$0]!, builtIn: true) }
        if let assets = session.assets {
            for path in assets.physicsMaterialPaths {
                if let id = assets.id(forPath: path), let m = assets.physicsMaterial(of: id) { all.append(entry(path, m, builtIn: false)) }
            }
        }
        return Result(materials: all)
    }
}

public enum PhysicsMaterialAtCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The world point to look under ([x, y, z]); a ray goes down from just above it.
        public var point: Vec3
        /// How far down to look (default 2 m).
        public var distance: Float?
        public init(point: Vec3, distance: Float? = nil) {
            self.point = point
            self.distance = distance
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var hit: Bool
        /// The material's name: a built-in or a .physmat path ("default" when nothing names one).
        public var material: String?
        public var friction: Float?
        public var bounce: Float?
        public var climbable: Bool?
        public var entity: EntityID?
        public var point: Vec3?
        public var normal: Vec3?
    }

    public static let id: CommandID = "physics.materialAt"
    public static let title = "Material Under Point"
    public static let doc = "Returns the physics material of the collider under `point` (a ray straight down up to `distance`, default 2 m): its name, friction, bounce and whether characters climb it, the entity and the surface point. Terrain colliders answer per painted layer. Works while playing and while editing (then from the scene's colliders as they are)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let physics = session.queryPhysics()
        guard let probe = physics.materialUnder(arguments.point, maxDistance: arguments.distance ?? 2) else {
            return Result(hit: false)
        }
        let material = probe.material
        let fallback = PhysicsMaterial.builtIn["default"]!
        return Result(hit: true, material: probe.name, friction: material.friction ?? fallback.friction,
                      bounce: material.bounce ?? fallback.bounce, climbable: material.climbable ?? false,
                      entity: probe.hit.entity.flatMap { session.world.id(of: $0) }, point: probe.hit.point, normal: probe.hit.normal)
    }
}

/// A character controller's state, as `character.state` returns it.
public struct CharacterStateResult: Codable, Equatable, Sendable {
    public var entity: EntityID
    public var position: Vec3
    /// walking, hanging, mantling or climbing.
    public var mode: String
    public var grounded: Bool
    public var sliding: Bool
    public var crouching: Bool
    /// Whether a crouching character has room to stand up.
    public var canStand: Bool
    public var verticalVelocity: Float
    /// The ledge or climbing hold and the wall's normal (hanging, mantling, climbing).
    public var ledgePoint: Vec3?
    public var wallNormal: Vec3?
    /// Where the hands go (IK targets) while hanging, mantling or climbing.
    public var leftHand: Vec3?
    public var rightHand: Vec3?
    /// The physics material under its feet while grounded.
    public var ground: String?
}

public enum CharacterStateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        public init(entity: EntityID) { self.entity = entity }
    }

    public static let id: CommandID = "character.state"
    public static let title = "Character State"
    public static let doc = "Returns an entity's CharacterController state: mode (walking, hanging, mantling, climbing), grounded, sliding, crouching and whether it has room to stand, the ledge point and wall normal, hand points for IK, and the physics material under its feet."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterStateResult {
        let e = try session.world.require(arguments.entity)
        guard let c = session.world.get(CharacterController.self, for: e) else {
            throw CommandError.failed("\(title): the entity has no CharacterController")
        }
        let feet = session.world.get(Transform.self, for: e)?.position ?? .zero
        let physics = session.queryPhysics()
        let body = physics.body(for: e)
        let hands = c.handTargets
        var ground: String?
        if c.isGrounded {
            ground = c.groundBody.map { physics.surfaceMaterialName(of: $0, at: feet) }
                ?? physics.materialUnder(feet, maxDistance: 0.3, filter: QueryFilter(mask: c.collisionMask, excluding: body.map { [$0] } ?? []))?.name
        }
        let holding = c.mode != .walking
        return CharacterStateResult(entity: arguments.entity, position: feet, mode: c.mode.rawValue, grounded: c.isGrounded, sliding: c.isSliding,
                                    crouching: c.isCrouching, canStand: physics.canStand(c, at: feet, body: body),
                                    verticalVelocity: c.verticalVelocity, ledgePoint: holding ? c.ledgePoint : nil,
                                    wallNormal: holding ? c.ledgeNormal : nil, leftHand: hands?.left, rightHand: hands?.right, ground: ground)
    }
}

public enum CharacterActionCommand: EditorCommand {
    /// What to make the character do.
    public enum Action: String, Codable, Sendable, CaseIterable {
        case crouch, stand, grabLedge, mantle, drop, jump
    }

    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        public var action: Action
        public init(entity: EntityID, action: Action) {
            self.entity = entity
            self.action = action
        }
    }

    public static let id: CommandID = "character.action"
    public static let title = "Character Action"
    public static let doc = "While playing, sets an input of an entity's CharacterController for its next step: crouch / stand (held until changed; it stands only with room above), grabLedge (grab a ledge within reach), mantle (pull up onto the ledge it hangs from or a low wall it walks toward), drop (let go of a ledge or climbing wall), jump. Step the game (play.step) and read character.state to see the result. Not recorded in playtests: drive characters there through input actions."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CharacterStateResult {
        let e = try session.world.require(arguments.entity)
        guard session.world.has(CharacterController.self, for: e) else {
            throw CommandError.failed("\(title): the entity has no CharacterController")
        }
        session.world.modify(CharacterController.self, for: e) { c in
            switch arguments.action {
            case .crouch: c.crouch = true
            case .stand: c.crouch = false
            case .grabLedge: c.grabLedge = true
            case .mantle: c.mantle = true
            case .drop: c.drop = true
            case .jump: c.jump = true
            }
        }
        return try CharacterStateCommand.run(.init(entity: arguments.entity), in: session)
    }
}
