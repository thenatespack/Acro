import Engine
import Foundation

/// The mesh builder tools: `meshBuild.new`, `meshBuild.get`, `meshBuild.set`, `meshBuild.edit`.
@MainActor
public enum EditorMeshBuildCommands {
    public static let all: [any EditorCommand.Type] = [
        MeshBuildNewCommand.self,
        MeshBuildGetCommand.self,
        MeshBuildSetCommand.self,
        MeshBuildEditCommand.self,
        MeshBuildOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A mesh build is a model made of shapes: `parts` (each: name, shape \
        group|box|sphere|hemisphere|cylinder|cone|capsule|torus|tube|plane|wedge|pyramid, parent (another part's name; \
        children move with it), position [x,y,z] m in the parent's space, rotation [x,y,z] degrees, size [x,y,z] m (the box \
        the shape fills; cylinders/cones/capsules run along Y), segments, thickness (tube wall), color [r,g,b] 0-1 sRGB, \
        opacity, texture (path under Assets/ such as "Textures/brick.png" or a .proctex, or "asset:<id>"), textureScale \
        [u,v], worldUV (texture keeps its size in meters), metallic, roughness, glow [r,g,b] emitted color, glowStrength, \
        material (a .material asset replacing the look)) and `animations` (each: name, autoplay (default true; every \
        autoplay animation plays at once in play mode and games), loop loop|once|pingPong, speed, motions (ready-made: \
        {part, kind spin|bob|swing|pulse|shake, axis x|y|z, amount (spin: turns, bob/shake: m, swing: degrees, pulse: \
        growth fraction), period seconds}) and tracks (keyframes: {part, property position|rotation|scale, interpolation \
        linear|hermite|step, keys [{time, value [x,y,z]}]}; values are relative to the part's rest pose: position offset \
        in m, rotation degrees added, scale multiplier (1 = unchanged))). Every key is optional. A group part has no mesh: \
        use it as a pivot (hinge, turret) for animated children.
        """
}

extension EditorSession {
    /// Writes a mesh build to "`name`.meshbuild" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createMeshBuildAsset(in folder: String, name: String = "New Model", build: MeshBuild = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Mesh Build") else {
            log.error("New Mesh Build: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".meshbuild"))
        do {
            let id = try assets.createMeshBuild(build, at: path)
            log.info("Created mesh build \(path)")
            return id
        } catch {
            log.error("New Mesh Build failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.meshbuild` file.
    public func isMeshBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == MeshBuildImporter().name
    }

    /// Replaces the contents of the mesh build `id` as one undo step (undo writes the old
    /// contents back; placed copies follow). Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyMeshBuild(_ build: MeshBuild, to id: AssetID, label: String = "Edit Mesh Build") -> [String]? {
        guard let assets, let old = assets.meshBuild(of: id) else {
            log.error("\(label): \(id) isn't a readable .meshbuild file")
            return nil
        }
        guard old != build else { return [] }
        let command = MeshBuildFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes mesh build edits undoable: performing writes `new` to the file, reverting writes `old`
/// back. Each write reimports it and the session rebuilds placed copies.
public struct MeshBuildFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: MeshBuild
    public let new: MeshBuild
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: MeshBuild, new: MeshBuild, in database: AssetDatabase, label: String = "Edit Mesh Build") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: MeshBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeMeshBuild(build, to: asset)
    }
}

/// Arguments naming a `.meshbuild` file.
public protocol MeshBuildTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The mesh build named by `target` and its contents.
    func resolveMeshBuild(_ target: some MeshBuildTarget, _ title: String) throws -> (AssetID, MeshBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isMeshBuildFile(id), let build = assets?.meshBuild(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .meshbuild file")
        }
        return (id, build)
    }
}

/// What the editing tools return.
public struct MeshBuildResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    /// Part names in file order.
    public var parts: [String]
    public var animations: [String]
    /// Import problems (missing parents, textures, animated parts that don't exist).
    public var warnings: [String]
    /// Entities placed in the scene (meshBuild.new with `place`).
    public var entities: [EntityID]?
}

extension MeshBuildResult {
    @MainActor init(_ id: AssetID, _ build: MeshBuild, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, parts: build.parts.map(\.name),
                  animations: build.animations.map(\.name), warnings: warnings + (record?.importError.map { ["import failed: \($0)"] } ?? []),
                  entities: entities)
    }
}

public enum MeshBuildNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Model" (the file gets ".meshbuild").
        public var name: String?
        /// The contents (default: one box).
        public var build: MeshBuild?
        /// Also place it in the scene (default false).
        public var place: Bool?
        /// Where to place it.
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, build: MeshBuild? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.build = build
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "meshBuild.new"
    public static let title = "New Mesh Build"
    public static let doc = "Writes a .meshbuild file in `folder` (default: the Assets root) and imports it as a model (a prefab of its parts, one mesh and material per part), optionally placing it in the scene (`place`, at `position`; undoable). Returns the asset, its prefab, the part names and import warnings. Edit it later with meshBuild.edit (small changes) or meshBuild.set (whole contents); placed copies update. " + EditorMeshBuildCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MeshBuildResult {
        let build = arguments.build ?? .starter
        let id = try session.commands.require(session.createMeshBuildAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Model", build: build), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return MeshBuildResult(id, build, warnings: MeshBuildCheck.problems(build, in: session), entities: entities, in: session)
    }
}

/// Problems with a mesh build's references, found without importing (the same ones the importer warns about).
@MainActor
enum MeshBuildCheck {
    static func problems(_ build: MeshBuild, in session: EditorSession) -> [String] {
        var problems: [String] = []
        let names = build.parts.map(\.name)
        let known = Set(names)
        if known.count != names.count { problems.append("some parts share a name; parenting and animation use the first") }
        for part in build.parts {
            if !part.parent.isEmpty && !known.contains(part.parent) { problems.append("part '\(part.name)' has a missing parent '\(part.parent)'") }
            for (value, kind) in [(part.texture, AssetKind.texture), (part.material, .material)] where !value.isEmpty {
                if MeshBuildCheck.resolve(value, session: session) == nil { problems.append("part '\(part.name)': no \(kind.rawValue) asset '\(value)'") }
            }
        }
        for animation in build.animations {
            for track in animation.allTracks where !known.contains(track.part) {
                problems.append("animation '\(animation.name)' moves a part that doesn't exist: '\(track.part)'")
            }
        }
        return problems
    }

    static func resolve(_ value: String, session: EditorSession) -> AssetID? {
        if let reference = AssetReference(value), value.hasPrefix(AssetReference.scheme) {
            return session.assets?.record(reference.asset) != nil ? reference.asset : nil
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        return session.assets?.id(forPath: path)
    }
}

public enum MeshBuildGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MeshBuildTarget {
        /// The .meshbuild file.
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
        public var build: MeshBuild
        public var warnings: [String]
    }

    public static let id: CommandID = "meshBuild.get"
    public static let title = "Get Mesh Build"
    public static let doc = "Reads a .meshbuild file: its parts and animations (every field, defaults included), the prefab to place, and problems with its references."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, build) = try session.resolveMeshBuild(arguments, title)
        let summary = MeshBuildResult(id, build, warnings: MeshBuildCheck.problems(build, in: session), in: session)
        return Result(asset: id, path: summary.path, prefab: summary.prefab, build: build, warnings: summary.warnings)
    }
}

public enum MeshBuildSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MeshBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var build: MeshBuild
        public init(asset: AssetReference? = nil, path: String? = nil, build: MeshBuild) {
            self.asset = asset
            self.path = path
            self.build = build
        }
    }

    public static let id: CommandID = "meshBuild.set"
    public static let title = "Set Mesh Build"
    public static let doc = "Replaces a .meshbuild file's whole contents and reimports it; placed copies update. Undoable. For a few changes, meshBuild.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MeshBuildResult {
        let (id, _) = try session.resolveMeshBuild(arguments, title)
        _ = try session.commands.require(session.applyMeshBuild(arguments.build, to: id, label: title), title)
        return MeshBuildResult(id, arguments.build, warnings: MeshBuildCheck.problems(arguments.build, in: session), in: session)
    }
}

public enum MeshBuildEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MeshBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Parts to remove by name (their children move up to the removed part's parent).
        public var removeParts: [String]?
        /// Parts to add (a name already taken gets " 2"…; the result lists the final names).
        public var addParts: [MeshBuildPart]?
        /// Changes to existing parts: part name → the fields to change, e.g.
        /// {"Wheel": {"color": [0,0,0], "size": [0.6, 0.2, 0.6]}}. A "name" key renames the part
        /// and every reference to it.
        public var updateParts: [String: JSONValue]?
        /// Animations to remove by name.
        public var removeAnimations: [String]?
        /// Animations to add (replacing any with the same name).
        public var addAnimations: [MeshBuildAnimation]?
        /// Ready-made motions to add to the animation named `animation`.
        public var addMotions: [MeshBuildMotion]?
        /// Keyframe tracks to add to the animation named `animation`.
        public var addTracks: [MeshBuildTrack]?
        /// The animation `addMotions` / `addTracks` go into (created when missing). Default: the first animation, else "Idle".
        public var animation: String?
        public init(asset: AssetReference? = nil, path: String? = nil, removeParts: [String]? = nil, addParts: [MeshBuildPart]? = nil,
                    updateParts: [String: JSONValue]? = nil, removeAnimations: [String]? = nil,
                    addAnimations: [MeshBuildAnimation]? = nil, addMotions: [MeshBuildMotion]? = nil,
                    addTracks: [MeshBuildTrack]? = nil, animation: String? = nil) {
            self.asset = asset
            self.path = path
            self.removeParts = removeParts
            self.addParts = addParts
            self.updateParts = updateParts
            self.removeAnimations = removeAnimations
            self.addAnimations = addAnimations
            self.addMotions = addMotions
            self.addTracks = addTracks
            self.animation = animation
        }
    }

    public static let id: CommandID = "meshBuild.edit"
    public static let title = "Edit Mesh Build"
    public static let doc = "Changes part of a .meshbuild file in one undoable step, in this order: removeParts, addParts, updateParts (name → fields to change; \"name\" renames), removeAnimations, addAnimations, then addMotions / addTracks into `animation`. Placed copies update. Returns the part and animation names and import warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MeshBuildResult {
        let (id, original) = try session.resolveMeshBuild(arguments, title)
        let build = try edited(original, with: arguments)
        _ = try session.commands.require(session.applyMeshBuild(build, to: id, label: title), title)
        return MeshBuildResult(id, build, warnings: MeshBuildCheck.problems(build, in: session), in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ build: MeshBuild, with arguments: Arguments) throws -> MeshBuild {
        var build = build
        if let names = arguments.removeParts, !names.isEmpty {
            let missing = names.filter { name in !build.parts.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No part named \(missing.joined(separator: ", "))") }
            build.removeParts(Set(names))
        }
        for var part in arguments.addParts ?? [] {
            part.name = build.uniquePartName(part.name)
            build.parts.append(part)
        }
        for (name, changes) in (arguments.updateParts ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = build.parts.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No part named \(name)") }
            guard case .object(let fields) = changes else { throw CommandError.failed("updateParts[\(name)] must be an object of fields") }
            var json = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(build.parts[index]))
            guard case .object(var current) = json else { continue }
            for (key, value) in fields { current[key] = value }
            json = .object(current)
            let updated: MeshBuildPart
            do { updated = try JSONDecoder().decode(MeshBuildPart.self, from: JSONEncoder().encode(json)) } catch {
                throw CommandError.failed("updateParts[\(name)]: \(error)")
            }
            let newName = updated.name
            build.parts[index] = updated
            build.parts[index].name = name
            if newName != name {
                guard !build.parts.contains(where: { $0.name == newName }) else { throw CommandError.failed("A part is already named \(newName)") }
                build.renamePart(name, to: newName)
            }
        }
        if let names = arguments.removeAnimations { build.animations.removeAll { names.contains($0.name) } }
        for animation in arguments.addAnimations ?? [] {
            if let i = build.animations.firstIndex(where: { $0.name == animation.name }) {
                build.animations[i] = animation
            } else {
                build.animations.append(animation)
            }
        }
        let motions = arguments.addMotions ?? [], tracks = arguments.addTracks ?? []
        if !motions.isEmpty || !tracks.isEmpty {
            let name = arguments.animation ?? build.animations.first?.name ?? "Idle"
            if !build.animations.contains(where: { $0.name == name }) { build.animations.append(MeshBuildAnimation(name: name)) }
            let i = build.animations.firstIndex { $0.name == name }!
            build.animations[i].motions += motions
            build.animations[i].tracks += tracks
        }
        return build
    }
}
