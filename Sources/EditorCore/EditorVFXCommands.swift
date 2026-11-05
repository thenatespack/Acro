import Engine
import Foundation

/// The VFX builder tools: `vfx.new`, `vfx.get`, `vfx.set`, `vfx.edit`, `vfx.open`.
@MainActor
public enum EditorVFXCommands {
    public static let all: [any EditorCommand.Type] = [
        VFXNewCommand.self,
        VFXGetCommand.self,
        VFXSetCommand.self,
        VFXEditCommand.self,
        VFXOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A VFX effect is a stack of GPU particle emitters: `emitters` (each: name, position [x,y,z] m and rotation [x,y,z] \
        degrees relative to the effect, delay (seconds before it starts: timing offset), rate (particles/s), bursts \
        [{time, count, interval, cycles}], capacity, prewarm (seconds pre-simulated so a continuous effect starts \
        steady), lifetime [min,max] s, shape point|sphere|box|disc, shapeSize, direction [x,y,z], spread (cone half-angle, \
        radians), speed [min,max], gravity [x,y,z], drag, turbulence, turbulenceFrequency, attraction, orbit, spiralArms, \
        spiralTwist, armWidth, size [min,max] (half-width m), spin, sizeOverLife [{time, value}] (up to 4), color \
        [{time, color [r,g,b,a] linear}] (up to 4, alpha fades), intensity (HDR glow), brightnessVariation, blend \
        additive|alpha (alpha = smoke/dust, sorted, at most 262144 particles), stretch, stretchMode scaled|streak, \
        collidesWithGround, groundHeight, bounce, friction, softness, lit, seed), plus `duration` (seconds one run lasts; \
        the editor preview loops after it), `background` [r,g,b] and `ground` (preview only). Every key is optional. \
        Presets: \(VFXBuild.presetNames.joined(separator: ", ")).
        """
}

extension EditorSession {
    /// Writes an effect to "`name`.vfx" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createVFXAsset(in folder: String, name: String = "New Effect", build: VFXBuild = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New VFX") else {
            log.error("New VFX: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".vfx"))
        do {
            let id = try assets.createVFX(build, at: path)
            log.info("Created VFX \(path)")
            return id
        } catch {
            log.error("New VFX failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.vfx` file.
    public func isVFXFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == VFXBuildImporter().name
    }

    /// Replaces the contents of the effect `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyVFX(_ build: VFXBuild, to id: AssetID, label: String = "Edit VFX") -> [String]? {
        guard let assets, let old = assets.vfx(of: id) else {
            log.error("\(label): \(id) isn't a readable .vfx file")
            return nil
        }
        guard old != build else { return [] }
        let command = VFXFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes effect edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct VFXFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: VFXBuild
    public let new: VFXBuild
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: VFXBuild, new: VFXBuild, in database: AssetDatabase, label: String = "Edit VFX") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: VFXBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeVFX(build, to: asset)
    }
}

/// Arguments naming a `.vfx` file.
public protocol VFXTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    func resolveVFX(_ target: some VFXTarget, _ title: String) throws -> (AssetID, VFXBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isVFXFile(id), let build = assets?.vfx(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .vfx file")
        }
        return (id, build)
    }
}

/// What the editing tools return.
public struct VFXResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    /// Emitter names in file order.
    public var emitters: [String]
    public var duration: Float
    /// Import problems.
    public var warnings: [String]
    /// Entities placed in the scene (vfx.new with `place`).
    public var entities: [EntityID]?
}

extension VFXResult {
    @MainActor init(_ id: AssetID, _ build: VFXBuild, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, emitters: build.emitters.map(\.name),
                  duration: build.duration,
                  warnings: warnings + (record?.importError.map { ["import failed: \($0)"] } ?? []), entities: entities)
    }
}

public enum VFXNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Effect" (the file gets ".vfx").
        public var name: String?
        /// A ready-made effect: fire, smoke, sparks, explosion, magicHit, rain, snow, dust, portal.
        public var preset: String?
        /// The contents instead of a preset (default: the smoke preset).
        public var effect: VFXBuild?
        /// Also place it in the scene (default false).
        public var place: Bool?
        /// Where to place it.
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, effect: VFXBuild? = nil,
                    place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.effect = effect
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "vfx.new"
    public static let title = "New VFX"
    public static let doc = "Writes a .vfx file in `folder` (default: the Assets root) and imports it as a prefab of particle emitters, from a `preset` (or `effect` contents), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the emitter names and import warnings. Edit it later with vfx.edit (small changes) or vfx.set (whole contents); placed copies update. " + EditorVFXCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VFXResult {
        var build = arguments.effect ?? .starter
        if let preset = arguments.preset {
            guard let found = VFXBuild.preset(preset) else {
                throw CommandError.failed("\(title): no preset '\(preset)' (try \(VFXBuild.presetNames.joined(separator: ", ")))")
            }
            build = found
        }
        let fallbackName = arguments.preset.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? "New Effect"
        let id = try session.commands.require(session.createVFXAsset(
            in: arguments.folder ?? "", name: arguments.name ?? fallbackName, build: build), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return VFXResult(id, build, warnings: VFXBuildCheck.problems(build), entities: entities, in: session)
    }
}

public enum VFXGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VFXTarget {
        /// The .vfx file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var prefab: AssetReference
        public var effect: VFXBuild
        public var warnings: [String]
    }

    public static let id: CommandID = "vfx.get"
    public static let title = "Get VFX"
    public static let doc = "Reads a .vfx file: its emitters (every field, defaults included), duration, preview settings, the prefab to place, and problems found."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, build) = try session.resolveVFX(arguments, title)
        let summary = VFXResult(id, build, warnings: VFXBuildCheck.problems(build), in: session)
        return Result(asset: id, path: summary.path, prefab: summary.prefab, effect: build, warnings: summary.warnings)
    }
}

public enum VFXSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VFXTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var effect: VFXBuild
        public init(asset: AssetReference? = nil, path: String? = nil, effect: VFXBuild) {
            self.asset = asset
            self.path = path
            self.effect = effect
        }
    }

    public static let id: CommandID = "vfx.set"
    public static let title = "Set VFX"
    public static let doc = "Replaces a .vfx file's whole contents and reimports it; placed copies update. Undoable. For a few changes, vfx.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VFXResult {
        let (id, _) = try session.resolveVFX(arguments, title)
        _ = try session.commands.require(session.applyVFX(arguments.effect, to: id, label: title), title)
        return VFXResult(id, arguments.effect, warnings: VFXBuildCheck.problems(arguments.effect), in: session)
    }
}

public enum VFXEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VFXTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Emitters to remove by name.
        public var removeEmitters: [String]?
        /// Emitters to add (a name already taken gets " 2"…; the result lists the final names).
        public var addEmitters: [VFXEmitter]?
        /// Changes to existing emitters: name → the fields to change, e.g.
        /// {"Flames": {"rate": 300, "delay": 0.5}}. A "name" key renames the emitter.
        public var updateEmitters: [String: JSONValue]?
        /// The effect's duration in seconds (the preview loop length).
        public var duration: Float?
        /// The preview background, sRGB [r,g,b].
        public var background: Vec3?
        /// Whether the preview shows a ground plane.
        public var ground: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, removeEmitters: [String]? = nil,
                    addEmitters: [VFXEmitter]? = nil, updateEmitters: [String: JSONValue]? = nil, duration: Float? = nil,
                    background: Vec3? = nil, ground: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.removeEmitters = removeEmitters
            self.addEmitters = addEmitters
            self.updateEmitters = updateEmitters
            self.duration = duration
            self.background = background
            self.ground = ground
        }
    }

    public static let id: CommandID = "vfx.edit"
    public static let title = "Edit VFX"
    public static let doc = "Changes part of a .vfx file in one undoable step, in this order: removeEmitters, addEmitters, updateEmitters (name → fields to change; \"name\" renames), then duration / background / ground. Placed copies update. Returns the emitter names and import warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VFXResult {
        let (id, original) = try session.resolveVFX(arguments, title)
        let build = try edited(original, with: arguments)
        _ = try session.commands.require(session.applyVFX(build, to: id, label: title), title)
        return VFXResult(id, build, warnings: VFXBuildCheck.problems(build), in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ build: VFXBuild, with arguments: Arguments) throws -> VFXBuild {
        var build = build
        if let names = arguments.removeEmitters, !names.isEmpty {
            let missing = names.filter { name in !build.emitters.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No emitter named \(missing.joined(separator: ", "))") }
            build.emitters.removeAll { names.contains($0.name) }
        }
        for var emitter in arguments.addEmitters ?? [] {
            emitter.name = build.uniqueEmitterName(emitter.name)
            build.emitters.append(emitter)
        }
        for (name, changes) in (arguments.updateEmitters ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = build.emitters.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No emitter named \(name)") }
            guard case .object(let fields) = changes else { throw CommandError.failed("updateEmitters[\(name)] must be an object of fields") }
            guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(build.emitters[index]))
            else { continue }
            for (key, value) in fields { current[key] = value }
            let updated: VFXEmitter
            do { updated = try JSONDecoder().decode(VFXEmitter.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
                throw CommandError.failed("updateEmitters[\(name)]: \(error)")
            }
            if updated.name != name, build.emitters.contains(where: { $0.name == updated.name }) {
                throw CommandError.failed("An emitter is already named \(updated.name)")
            }
            build.emitters[index] = updated
        }
        if let duration = arguments.duration { build.duration = max(duration, 0.1) }
        if let background = arguments.background { build.background = background }
        if let ground = arguments.ground { build.ground = ground }
        return build
    }
}
