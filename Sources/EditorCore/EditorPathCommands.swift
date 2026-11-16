import Engine
import Foundation

/// The path builder tools: `path.new`, `.get`, `.set`, `.edit`, `.open`, `.sample`.
@MainActor
public enum EditorPathCommands {
    public static let all: [any EditorCommand.Type] = [
        PathNewCommand.self,
        PathGetCommand.self,
        PathSetCommand.self,
        PathEditCommand.self,
        PathOpenCommand.self,
        PathSampleCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A path is a spline through `points` (each [x,y,z] meters, or {position, bank (degrees, positive lowers the right side), \
        width (multiplies the profiles' widths there)}), `closed` (a loop), `smooth` (Catmull-Rom; false: straight lines), \
        `spacing` (meters between samples), `bank` (degrees added everywhere), `autoBank` (extra degrees in tight turns), \
        `kind` (road, rail, river, fence, cable, wall, custom), `profiles` (cross-sections swept into meshes; each: name, shape \
        flat|box|tube|custom, width, height, offset [right, up] meters from the centerline, sides (tube), points (custom outline \
        [right, up], counter-clockwise seen along the path), closedShape, sag (cables hang this far between control points), \
        color [r,g,b] 0-1 sRGB, opacity, metallic, roughness, glow, texture, textureScale [across, per meter along], material, \
        collider), `pieces` (repeated along the path; each: name, asset (a .meshbuild path or "asset:<id>#mesh/<name>"; empty uses \
        shape/size/color, a Mesh Builder shape such as box or cylinder), spacing meters, start, offset [right, up, forward], \
        rotation degrees, scale, upright, mirror (also on the other side), collider) and `terrain` {asset (a .terrain path), \
        offset (the terrain's origin in the path's space), height (meters above the ground)}: with a terrain every sample and \
        piece sits on its surface (point y is ignored). Forward is the direction of travel, right is level with the ground. \
        Every key is optional.
        """
}

extension EditorSession {
    /// Writes a path build to "`name`.path" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createPathBuildAsset(in folder: String, name: String = "New Path", build: PathBuild) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Path") else {
            log.error("New Path: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".path"))
        do {
            let id = try assets.createPathBuild(build, at: path)
            log.info("Created path \(path)")
            return id
        } catch {
            log.error("New Path failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.path` file.
    public func isPathBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == PathBuildImporter().name
    }

    /// Replaces the contents of the path build `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applyPathBuild(_ build: PathBuild, to id: AssetID, label: String = "Edit Path") -> [String]? {
        guard let assets, let old = assets.pathBuild(of: id) else {
            log.error("\(label): \(id) isn't a readable .path file")
            return nil
        }
        guard old != build else { return [] }
        let command = PathBuildFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// The terrain a path follows (nil when off or unreadable).
    func followedTerrain(of build: PathBuild) -> (id: AssetID, terrain: Terrain)? {
        guard build.terrain.isOn, let id = MeshBuildCheck.resolve(build.terrain.asset, session: self),
              var terrain = assets?.terrain(of: id) else { return nil }
        terrain.resolution = terrain.res
        terrain.normalizeData()
        return (id, terrain)
    }
}

/// Makes path edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct PathBuildFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: PathBuild
    public let new: PathBuild
    /// The last write's import warnings.
    let warnings = TerrainFileEditCommand.Box<[String]>([])
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: PathBuild, new: PathBuild, in database: AssetDatabase, label: String = "Edit Path") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: PathBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writePathBuild(build, to: asset)
    }
}

/// Arguments naming a `.path` file.
public protocol PathBuildTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The path build named by `target` and its contents.
    func resolvePathBuild(_ target: some PathBuildTarget, _ title: String) throws -> (AssetID, PathBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isPathBuildFile(id), let build = assets?.pathBuild(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .path file")
        }
        return (id, build)
    }
}

/// What the path tools return.
public struct PathBuildResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    public var kind: PathKind
    public var points: Int
    /// Meters along the curve (on the terrain when following one).
    public var length: Float
    public var profiles: [String]
    public var pieces: [String]
    /// Copies each piece rule places (same order as `pieces`).
    public var pieceCounts: [Int]
    /// The followed terrain's path, if any.
    public var terrain: String?
    /// Import problems and unresolved references.
    public var warnings: [String]
    /// Entities placed in the scene (path.new with `place`).
    public var entities: [EntityID]?
}

extension PathBuildResult {
    @MainActor init(_ id: AssetID, _ build: PathBuild, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        let ground = session.followedTerrain(of: build)
        let samples = build.samples(on: ground?.terrain)
        var all: [String] = []
        for w in warnings where !all.contains(w) { all.append(w) }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, kind: build.kind, points: build.points.count,
                  length: samples.last?.distance ?? 0, profiles: build.profiles.map(\.name), pieces: build.pieces.map(\.name),
                  pieceCounts: build.pieces.map { build.instances(of: $0, samples: samples, on: ground?.terrain).count },
                  terrain: ground.flatMap { session.assets?.path(of: $0.id) },
                  warnings: all + (record?.importError.map { ["import failed: \($0)"] } ?? []), entities: entities)
    }
}

/// Problems with a path's references, found without importing.
@MainActor
enum PathBuildCheck {
    static func problems(_ build: PathBuild, in session: EditorSession) -> [String] {
        var problems = build.problems
        if build.terrain.isOn {
            if let id = MeshBuildCheck.resolve(build.terrain.asset, session: session) {
                if !session.isTerrainFile(id) { problems.append("terrain: '\(build.terrain.asset)' isn't a .terrain file") }
            } else {
                problems.append("terrain: no terrain file '\(build.terrain.asset)'")
            }
        }
        for profile in build.profiles {
            for value in [profile.texture, profile.material] where !value.isEmpty
                && MeshBuildCheck.resolve(value.components(separatedBy: "#")[0], session: session) == nil {
                problems.append("profile '\(profile.name)': no asset '\(value)'")
            }
        }
        for piece in build.pieces where !piece.asset.isEmpty
            && MeshBuildCheck.resolve(piece.asset.components(separatedBy: "#")[0], session: session) == nil {
            problems.append("piece '\(piece.name)': no asset '\(piece.asset)'")
        }
        return problems
    }
}

public enum PathNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Path" (the file gets ".path").
        public var name: String?
        /// road, rail, river, fence, cable, wall or custom (default road): the starting profiles and pieces.
        public var kind: PathKind?
        /// Control points (default: an S curve 40 m long through the origin).
        public var points: [PathPoint]?
        public var closed: Bool?
        /// A .terrain to follow (path under Assets/).
        public var terrain: String?
        /// Also place it in the scene (default false).
        public var place: Bool?
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, kind: PathKind? = nil, points: [PathPoint]? = nil, closed: Bool? = nil,
                    terrain: String? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.kind = kind
            self.points = points
            self.closed = closed
            self.terrain = terrain
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "path.new"
    public static let title = "New Path"
    public static let doc = "Writes a .path file in `folder` (default: the Assets root) from a `kind` preset (road: a road bed with a center line and a collider; rail: ballast, two rails and sleepers; river: water over a bed; fence: posts and two rails; cable: a sagging wire 6 m up; wall: a wall with a cap), through `points` (default an S curve), optionally following a terrain and placed in the scene. Then reshape it with path.edit. " + EditorPathCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathBuildResult {
        let kind = arguments.kind ?? .road
        var build = PathBuild.preset(kind, points: arguments.points)
        if let closed = arguments.closed { build.closed = closed }
        if let terrain = arguments.terrain { build.terrain.asset = terrain }
        let id = try session.commands.require(session.createPathBuildAsset(in: arguments.folder ?? "", name: arguments.name ?? "New Path",
                                                                           build: build), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return PathBuildResult(id, build, warnings: PathBuildCheck.problems(build, in: session), entities: entities, in: session)
    }
}

public enum PathGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PathBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var summary: PathBuildResult
        public var build: PathBuild
    }

    public static let id: CommandID = "path.get"
    public static let title = "Get Path"
    public static let doc = "Reads a .path file: every field (defaults included) and a summary (length, piece counts, the followed terrain, problems). path.sample returns points along it."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, build) = try session.resolvePathBuild(arguments, title)
        return Result(summary: PathBuildResult(id, build, warnings: PathBuildCheck.problems(build, in: session), in: session), build: build)
    }
}

public enum PathSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PathBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var build: PathBuild
        public init(asset: AssetReference? = nil, path: String? = nil, build: PathBuild) {
            self.asset = asset
            self.path = path
            self.build = build
        }
    }

    public static let id: CommandID = "path.set"
    public static let title = "Set Path"
    public static let doc = "Replaces a .path file's whole contents and reimports it; placed copies update. Undoable. For a few changes path.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathBuildResult {
        let (id, _) = try session.resolvePathBuild(arguments, title)
        let warnings = try session.commands.require(session.applyPathBuild(arguments.build, to: id, label: title), title)
        return PathBuildResult(id, arguments.build, warnings: PathBuildCheck.problems(arguments.build, in: session) + warnings, in: session)
    }
}

/// A change to one control point (`path.edit` `updatePoints`).
public struct PathPointUpdate: Codable, Equatable, Sendable {
    /// The point's index (0 is the start).
    public var index: Int
    public var position: Vec3?
    public var bank: Float?
    public var width: Float?
    public init(index: Int, position: Vec3? = nil, bank: Float? = nil, width: Float? = nil) {
        self.index = index
        self.position = position
        self.bank = bank
        self.width = width
    }
}

/// Points to insert before `index` (`path.edit` `insertPoints`).
public struct PathPointInsert: Codable, Equatable, Sendable {
    public var index: Int
    public var points: [PathPoint]
    public init(index: Int, points: [PathPoint]) {
        self.index = index
        self.points = points
    }
}

public enum PathEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PathBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Replaces the profiles and pieces with this kind's preset (points and terrain stay).
        public var kind: PathKind?
        /// Replaces every control point.
        public var points: [PathPoint]?
        /// Point indices to remove.
        public var removePoints: [Int]?
        /// Points to insert before an index (after the removals).
        public var insertPoints: [PathPointInsert]?
        /// Points to append at the end.
        public var addPoints: [PathPoint]?
        /// Changes to single points (after the insertions, so use the new indices).
        public var updatePoints: [PathPointUpdate]?
        public var closed: Bool?
        public var smooth: Bool?
        public var spacing: Float?
        public var bank: Float?
        public var autoBank: Float?
        /// Fields to change on one profile (`profileName`, default the first).
        public var profile: JSONValue?
        public var profileName: String?
        public var removeProfiles: [String]?
        /// Profiles to add (a taken name gets " 2"…).
        public var addProfiles: [PathProfile]?
        /// Profile name → fields to change ("name" renames).
        public var updateProfiles: [String: JSONValue]?
        public var removePieces: [String]?
        public var addPieces: [PathPiece]?
        /// Piece name → fields to change ("name" renames).
        public var updatePieces: [String: JSONValue]?
        /// Fields to change on the terrain following ({"asset": ""} turns it off).
        public var terrain: JSONValue?
        public init(asset: AssetReference? = nil, path: String? = nil, kind: PathKind? = nil, points: [PathPoint]? = nil,
                    removePoints: [Int]? = nil, insertPoints: [PathPointInsert]? = nil, addPoints: [PathPoint]? = nil,
                    updatePoints: [PathPointUpdate]? = nil, closed: Bool? = nil, smooth: Bool? = nil, spacing: Float? = nil,
                    bank: Float? = nil, autoBank: Float? = nil, profile: JSONValue? = nil, profileName: String? = nil,
                    removeProfiles: [String]? = nil, addProfiles: [PathProfile]? = nil, updateProfiles: [String: JSONValue]? = nil,
                    removePieces: [String]? = nil, addPieces: [PathPiece]? = nil, updatePieces: [String: JSONValue]? = nil,
                    terrain: JSONValue? = nil) {
            self.asset = asset
            self.path = path
            self.kind = kind
            self.points = points
            self.removePoints = removePoints
            self.insertPoints = insertPoints
            self.addPoints = addPoints
            self.updatePoints = updatePoints
            self.closed = closed
            self.smooth = smooth
            self.spacing = spacing
            self.bank = bank
            self.autoBank = autoBank
            self.profile = profile
            self.profileName = profileName
            self.removeProfiles = removeProfiles
            self.addProfiles = addProfiles
            self.updateProfiles = updateProfiles
            self.removePieces = removePieces
            self.addPieces = addPieces
            self.updatePieces = updatePieces
            self.terrain = terrain
        }
    }

    public static let id: CommandID = "path.edit"
    public static let title = "Edit Path"
    public static let doc = "Changes a .path file in one undoable step, in this order: kind (applies that preset's profiles and pieces), points (replace all), removePoints, insertPoints, addPoints, updatePoints ({index, position?, bank?, width?}), the curve settings (closed, smooth, spacing, bank, autoBank), profile (fields to change on `profileName` or the first profile), removeProfiles, addProfiles, updateProfiles (name → fields), removePieces, addPieces, updatePieces, terrain (fields: asset, offset, height). Placed copies update. Returns the length, piece counts and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathBuildResult {
        let (id, original) = try session.resolvePathBuild(arguments, title)
        let build = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyPathBuild(build, to: id, label: title), title)
        return PathBuildResult(id, build, warnings: PathBuildCheck.problems(build, in: session) + warnings, in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ build: PathBuild, with arguments: Arguments) throws -> PathBuild {
        var b = build
        if let kind = arguments.kind { b.applyPreset(kind) }
        if let points = arguments.points { b.points = points }
        if let indices = arguments.removePoints, !indices.isEmpty {
            let bad = indices.filter { !b.points.indices.contains($0) }
            guard bad.isEmpty else { throw CommandError.failed("removePoints: no point \(bad.map(String.init).joined(separator: ", ")) (there are \(b.points.count))") }
            for i in Set(indices).sorted(by: >) { b.points.remove(at: i) }
        }
        for insert in arguments.insertPoints ?? [] {
            guard insert.index >= 0, insert.index <= b.points.count else {
                throw CommandError.failed("insertPoints: index \(insert.index) is outside 0...\(b.points.count)")
            }
            b.points.insert(contentsOf: insert.points, at: insert.index)
        }
        b.points += arguments.addPoints ?? []
        for update in arguments.updatePoints ?? [] {
            guard b.points.indices.contains(update.index) else {
                throw CommandError.failed("updatePoints: no point \(update.index) (there are \(b.points.count))")
            }
            if let p = update.position { b.points[update.index].position = p }
            if let v = update.bank { b.points[update.index].bank = v }
            if let v = update.width { b.points[update.index].width = v }
        }
        if let v = arguments.closed { b.closed = v }
        if let v = arguments.smooth { b.smooth = v }
        if let v = arguments.spacing {
            guard v >= 0.05, v <= 50 else { throw CommandError.failed("spacing must be 0.05...50 meters") }
            b.spacing = v
        }
        if let v = arguments.bank { b.bank = v }
        if let v = arguments.autoBank { b.autoBank = v }

        if let changes = arguments.profile {
            let index: Int
            if let name = arguments.profileName {
                guard let i = b.profiles.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No profile named \(name)") }
                index = i
            } else {
                if b.profiles.isEmpty { b.profiles.append(PathProfile()) }
                index = 0
            }
            try update(&b.profiles, at: index, with: changes, label: "profile")
        }
        if let names = arguments.removeProfiles, !names.isEmpty {
            let missing = names.filter { name in !b.profiles.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No profile named \(missing.joined(separator: ", "))") }
            b.profiles.removeAll { names.contains($0.name) }
        }
        for var profile in arguments.addProfiles ?? [] {
            profile.name = TerrainEditCommand.uniqueName(profile.name, among: b.profiles.map(\.name))
            b.profiles.append(profile)
        }
        for (name, changes) in (arguments.updateProfiles ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let i = b.profiles.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No profile named \(name)") }
            try update(&b.profiles, at: i, with: changes, label: "updateProfiles[\(name)]")
        }
        if let names = arguments.removePieces, !names.isEmpty {
            let missing = names.filter { name in !b.pieces.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No piece named \(missing.joined(separator: ", "))") }
            b.pieces.removeAll { names.contains($0.name) }
        }
        for var piece in arguments.addPieces ?? [] {
            piece.name = TerrainEditCommand.uniqueName(piece.name, among: b.pieces.map(\.name))
            b.pieces.append(piece)
        }
        for (name, changes) in (arguments.updatePieces ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let i = b.pieces.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No piece named \(name)") }
            try update(&b.pieces, at: i, with: changes, label: "updatePieces[\(name)]")
        }
        if let changes = arguments.terrain { b.terrain = try TerrainEditCommand.merged(b.terrain, changes, "terrain") }
        return b
    }

    /// Merges `changes` into `list[index]`, keeping names unique.
    private static func update<T: Codable & PathNamedItem>(_ list: inout [T], at index: Int, with changes: JSONValue, label: String) throws {
        let old = list[index].name
        var value = try TerrainEditCommand.merged(list[index], changes, label)
        let name = value.name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { value.name = old } else if name != old, list.contains(where: { $0.name == name }) {
            throw CommandError.failed("\(label): the name \(name) is taken")
        }
        list[index] = value
    }
}

/// Profiles and pieces have names.
protocol PathNamedItem {
    var name: String { get set }
}
extension PathProfile: PathNamedItem {}
extension PathPiece: PathNamedItem {}

public enum PathOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PathBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "path.open"
    public static let title = "Open in Path Builder"
    public static let doc = "Opens a .path file in the editor's Path Builder tab (a viewport showing the path over the terrain it follows, control-point handles you click and drag with the Move gizmo, and the points, profiles and pieces forms) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"pathBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolvePathBuild(arguments, title)
        session.openPathBuild = id
        session.onOpenPathBuild?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum PathSampleCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PathBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Evenly spaced points from start to end (default 11; 2...1000). Ignored with `distances`.
        public var count: Int?
        /// Meters along the path to sample instead.
        public var distances: [Float]?
        public init(asset: AssetReference? = nil, path: String? = nil, count: Int? = nil, distances: [Float]? = nil) {
            self.asset = asset
            self.path = path
            self.count = count
            self.distances = distances
        }
    }

    public struct Point: Codable, Equatable, Sendable {
        public var distance: Float
        public var position: Vec3
        public var forward: Vec3
        public var right: Vec3
        public var up: Vec3
    }

    public struct Result: Codable, Equatable, Sendable {
        public var length: Float
        public var points: [Point]
    }

    public static let id: CommandID = "path.sample"
    public static let title = "Sample Path"
    public static let doc = "Returns points along a .path's centerline (on its terrain when it follows one), in the path's space: position, forward (direction of travel), right and up (after banking), and the distance in meters. Use it to place things along a road or river (add the placed path entity's position)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (_, build) = try session.resolvePathBuild(arguments, title)
        let samples = build.samples(on: session.followedTerrain(of: build)?.terrain)
        let total = samples.last?.distance ?? 0
        let distances: [Float]
        if let given = arguments.distances {
            guard given.count <= 1000 else { throw CommandError.failed("\(title): at most 1000 distances") }
            distances = given
        } else {
            let n = min(max(arguments.count ?? 11, 2), 1000)
            distances = (0..<n).map { total * Float($0) / Float(n - 1) }
        }
        let wraps = build.closed && build.points.count > 2
        let points = distances.compactMap { d in
            PathBuild.sample(samples, atDistance: d, closed: wraps).map {
                Point(distance: $0.distance, position: $0.position, forward: $0.forward, right: $0.right, up: $0.up)
            }
        }
        return Result(length: total, points: points)
    }
}
