import EditorCore
import Engine
import Foundation

/// The Groom Builder tools: `groom.new`, `.get`, `.set`, `.edit`, `.open`, `.preview`, `.examples`,
/// `.presets` and `.apply`.
@MainActor
public enum EditorGroomCommands {
    public static let all: [any EditorCommand.Type] = [
        GroomNewCommand.self,
        GroomGetCommand.self,
        GroomSetCommand.self,
        GroomEditCommand.self,
        GroomOpenCommand.self,
        GroomPreviewCommand.self,
        GroomExamplesCommand.self,
        GroomPresetsCommand.self,
        GroomApplyCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A .groom file is fur or hair any mesh can wear (every key optional): style shell (short fur, moss, velvet: \
        instanced shells) | cards (longer hair, manes, feathers: ribbon cards along guide curves) | strands (reserved, draws as \
        cards); length (m), lengthVariation 0-1, density (strands per cm² for shells, cards per cm² for cards), thickness \
        [root, tip] (0-1 of the strand spacing), clumping, curl, frizz, gravity, stiffness (0-1), rootColor / tipColor \
        ([r,g,b] 0-1 sRGB), colorNoise, specular (0-1), mask {texture (red scales the length), vertexPaint "r"|"g"|"b"|"a", \
        parts [Mesh Builder part / entity names], invert}, combDirection "normal" | "followSurface" | [x,y,z] (mesh space) with \
        combStrength 0-1 (1 lies flat), flowTexture (red/green: a direction in UV space), wind (scales the scene's wind; 0 \
        still), shells (2-64 at full detail), cardWidth (m), cardSegments (2-16), strandsPerCard (1-32), lod {shells [per \
        level], cards [fraction per level], distances [m where levels 1, 2… start; past the last only a fur-colored undercoat \
        is drawn]}, comb [{center [x,y,z], radius, direction [x,y,z], strength}] and cut [{center, radius, length (0 bald, 1 \
        full, up to 2), strength}] strokes in the mesh's space, applied in order, seed, previewMesh (sphere, cube, capsule, \
        plane or a .meshbuild path). Hair styling (cards; positions in the hair's bounds, -1...1 over the furry area, face \
        toward +Z): part {style none|center|side|curve, offset -1..1, crown, points [[x,y,z]] (curve, mesh space), \
        strength, width m}, scalpHug 0-1 (how far along a strand it lies on the scalp before falling), volume 0-1, \
        sweepBack 0-1 (front hair combed away from the face), collide (keep cards out of the mesh, default true), colliders \
        [{center, radius, radii [x,y,z] (ellipsoid), end [x,y,z] (capsule)}] (mesh space; head, neck, shoulders for a \
        scalp), rootPlacement even|random, hairlineWidth m (cards thin and shorten toward the hair's edge), innerLayer 0-1 \
        (short flat cards hiding the scalp), flyaways 0-1, clumpSize (cards per clump), cardTaper 0-1, wave 0-1, \
        curlFrequency (turns), lengthProfile {front, back, top, sides}, hemline {back, front, softness} (a blunt cut \
        height), fringe {amount 0-1, length m, sweep -1..1} (bangs), tie {point [x,y,z], tail m, radius m} (ponytail). \
        Presets: \(GroomBuild.presetNames.joined(separator: ", ")) (groom.presets). Put it on \
        a mesh with groom.apply (an entity, a .character body region or attachment, or a .meshbuild part).
        """
}

extension EditorSession {
    /// Writes a groom to "`name`.groom" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createGroomAsset(in folder: String, name: String = "New Groom", build: GroomBuild = GroomBuild()) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Groom") else {
            log.error("New Groom: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".groom"))
        do {
            let id = try assets.createGroom(build, at: path)
            log.info("Created groom \(path)")
            return id
        } catch {
            log.error("New Groom failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.groom` file.
    public func isGroomFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == GroomImporter().name
    }

    /// Replaces the contents of the groom `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyGroom(_ build: GroomBuild, to id: AssetID, label: String = "Edit Groom") -> [String]? {
        guard let assets, let old = assets.groom(of: id) else {
            log.error("\(label): \(id) isn't a readable .groom file")
            return nil
        }
        guard old != build else { return [] }
        let command = GroomFileEditCommand(asset: id, contents: .groom(old), new: .groom(build), in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    func resolveGroom(_ target: some GroomTarget, _ title: String) throws -> (AssetID, GroomBuild) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isGroomFile(id), let build = assets?.groom(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .groom file")
        }
        return (id, build)
    }
}

/// Makes groom edits (and the `.character` / `.meshbuild` edits of groom.apply) undoable:
/// performing writes `new`, reverting writes the old contents back.
public struct GroomFileEditCommand: UndoCommand {
    /// The file's contents, by kind.
    public enum Contents: Equatable, Sendable {
        case groom(GroomBuild)
        case character(CharacterBuild)
        case meshBuild(MeshBuild)
    }

    public var label: String
    public let asset: AssetID
    public let old: Contents
    public let new: Contents
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, contents old: Contents, new: Contents, in database: AssetDatabase, label: String = "Edit Groom") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ contents: Contents) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        switch contents {
        case .groom(let build): warnings.value = try database.writeGroom(build, to: asset)
        case .character(let build): warnings.value = try database.writeCharacter(build, to: asset)
        case .meshBuild(let build): warnings.value = try database.writeMeshBuild(build, to: asset)
        }
    }
}

/// Arguments naming a `.groom` file.
public protocol GroomTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

/// What the editing tools return.
public struct GroomResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The fur material a GroomRenderer names (groom.apply sets it).
    public var material: AssetReference
    /// The preview prefab (the groom on its previewMesh), to place with asset.instantiate.
    public var prefab: AssetReference
    public var style: GroomStyle
    /// Shells at each detail level (shell style) or the fraction of cards (cards style), level 0 first.
    public var levels: [Float]
    public var warnings: [String]
}

extension GroomResult {
    static func merged(_ problems: [String], _ imported: [String]) -> [String] {
        problems + imported.filter { !problems.contains($0) }
    }

    @MainActor init(_ id: AssetID, _ build: GroomBuild, warnings: [String], in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", material: AssetReference(id, subAsset: GroomRenderer.furSubAsset),
                  prefab: prefab, style: build.drawnStyle,
                  levels: build.drawnStyle == .shell ? build.shellLevels.map(Float.init) : build.cardLevels,
                  warnings: warnings + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum GroomNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Groom" or the preset's name (the file gets ".groom").
        public var name: String?
        /// A built-in groom (groom.presets): shortFur, shaggyFur, velvet, moss, tufts, straightHair, ponytail, mane, feathers.
        public var preset: String?
        /// The contents instead of a preset (default: short fur).
        public var groom: GroomBuild?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, groom: GroomBuild? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.groom = groom
        }
    }

    public static let id: CommandID = "groom.new"
    public static let title = "New Groom"
    public static let doc = "Writes a .groom file in `folder` (default: the Assets root) from a `preset` (or `groom` contents) and imports it as a fur material and a preview prefab. Returns the asset, its fur material, the preview prefab, detail levels and warnings. Put it on a mesh with groom.apply; edit it with groom.edit or groom.set (fur using it updates). " + EditorGroomCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GroomResult {
        var build = arguments.groom ?? GroomBuild.preset("shortFur")!
        if let preset = arguments.preset {
            guard let found = GroomBuild.preset(preset) else {
                throw CommandError.failed("\(title): no preset '\(preset)' (try \(GroomBuild.presetNames.joined(separator: ", ")))")
            }
            build = found
        }
        let fallback = arguments.preset.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? "New Groom"
        let id = try session.commands.require(session.createGroomAsset(in: arguments.folder ?? "", name: arguments.name ?? fallback,
                                                                       build: build), title)
        return GroomResult(id, build, warnings: GroomCheck.problems(build), in: session)
    }
}

public enum GroomGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GroomTarget {
        /// The .groom file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var summary: GroomResult
        public var groom: GroomBuild
    }

    public static let id: CommandID = "groom.get"
    public static let title = "Get Groom"
    public static let doc = "Reads a .groom file: every field (defaults included), its fur material and preview prefab, detail levels and problems found."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, build) = try session.resolveGroom(arguments, title)
        return Result(summary: GroomResult(id, build, warnings: GroomCheck.problems(build), in: session), groom: build)
    }
}

public enum GroomSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GroomTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var groom: GroomBuild
        public init(asset: AssetReference? = nil, path: String? = nil, groom: GroomBuild) {
            self.asset = asset
            self.path = path
            self.groom = groom
        }
    }

    public static let id: CommandID = "groom.set"
    public static let title = "Set Groom"
    public static let doc = "Replaces a .groom file's whole contents and reimports it; fur using it updates. Undoable. For a few changes, groom.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GroomResult {
        let (id, _) = try session.resolveGroom(arguments, title)
        let imported = try session.commands.require(session.applyGroom(arguments.groom, to: id, label: title), title)
        return GroomResult(id, arguments.groom, warnings: GroomResult.merged(GroomCheck.problems(arguments.groom), imported), in: session)
    }
}

public enum GroomEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GroomTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Fields to change, e.g. {"length": 0.05, "tipColor": [0.9, 0.8, 0.6], "lod": {"distances": [5, 12, 30]}}.
        public var changes: JSONValue?
        /// Comb strokes to append (applied after the file's).
        public var addComb: [GroomComb]?
        /// Cut / length strokes to append.
        public var addCut: [GroomCut]?
        /// Remove every comb and cut stroke first.
        public var clearStrokes: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, changes: JSONValue? = nil, addComb: [GroomComb]? = nil,
                    addCut: [GroomCut]? = nil, clearStrokes: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.changes = changes
            self.addComb = addComb
            self.addCut = addCut
            self.clearStrokes = clearStrokes
        }
    }

    public static let id: CommandID = "groom.edit"
    public static let title = "Edit Groom"
    public static let doc = "Changes part of a .groom file in one undoable step, in this order: clearStrokes, changes (top-level fields; nested objects such as mask or lod are replaced whole), addComb, addCut. Strokes are spheres in the mesh's space: comb {center [x,y,z], radius, direction [x,y,z], strength} turns strands toward a direction; cut {center, radius, length 0 (bald) … 1 (full) … 2, strength} sets the length (a mask). Fur using the groom updates. Returns detail levels and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GroomResult {
        let (id, original) = try session.resolveGroom(arguments, title)
        let build = try edited(original, with: arguments)
        let imported = try session.commands.require(session.applyGroom(build, to: id, label: title), title)
        return GroomResult(id, build, warnings: GroomResult.merged(GroomCheck.problems(build), imported), in: session)
    }

    /// `build` with the edits of `arguments` applied (pure, for tests and the tab).
    public static func edited(_ build: GroomBuild, with arguments: Arguments) throws -> GroomBuild {
        var build = build
        if arguments.clearStrokes == true {
            build.comb = []
            build.cut = []
        }
        if let changes = arguments.changes {
            guard case .object(let fields) = changes else { throw CommandError.failed("changes must be an object of fields") }
            guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(build)) else {
                return build
            }
            for (key, value) in fields { current[key] = value }
            do { build = try AssetJSON.decoder().decode(GroomBuild.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
                throw CommandError.failed("changes: \(error)")
            }
        }
        build.comb += arguments.addComb ?? []
        build.cut += arguments.addCut ?? []
        return build
    }
}

public enum GroomExamplesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// One example by name (default: all).
        public var name: String?
        public init(name: String? = nil) { self.name = name }
    }

    public struct Example: Codable, Equatable, Sendable {
        public var name: String
        public var about: String
        public var groom: GroomBuild
    }

    public struct Result: Codable, Equatable, Sendable {
        public var examples: [Example]
    }

    /// Warning-free grooms to copy: fur with comb and cut strokes, long hair cards, moss.
    public static var examples: [Example] {
        var fox = GroomBuild.preset("shortFur")!
        fox.rootColor = Vec3(0.55, 0.25, 0.08)
        fox.tipColor = Vec3(0.95, 0.55, 0.2)
        fox.length = 0.03
        fox.combDirection = .vector(Vec3(0, 0, -1))
        fox.combStrength = 0.55
        fox.comb = [GroomComb(center: Vec3(0, 0.3, 0.35), radius: 0.15, direction: Vec3(0, -1, 0), strength: 0.8)]
        fox.cut = [GroomCut(center: Vec3(0, 0.15, 0.48), radius: 0.08, length: 0.3, strength: 1)]
        var hair = GroomBuild.preset("straightHair")!
        hair.length = 0.3
        hair.part = GroomPart(style: .side, offset: 0.4)
        hair.cut = [GroomCut(center: Vec3(0, 0.06, 0.13), radius: 0.09, length: 0, strength: 1)]
        hair.colliders = [GroomCollider(center: .zero, radii: Vec3(0.11, 0.13, 0.12))]
        hair.previewMesh = "sphere"
        var moss = GroomBuild.preset("moss")!
        moss.mask = GroomMask(vertexPaint: "", parts: [])
        moss.combDirection = .vector(Vec3(1, 0, 0))
        moss.combStrength = 0.2
        moss.cut = [GroomCut(center: Vec3(0, -0.5, 0), radius: 0.35, length: 0, strength: 1)]
        return [
            Example(name: "Fox Fur", about: "Short orange fur combed back (-Z), a comb stroke smoothing the chest down and a cut stroke keeping the muzzle short. Apply to a quadruped's body region.", groom: fox),
            Example(name: "Long Hair", about: "Straight hair cards with a side part, lying on the scalp and falling past the ears, a flat inner layer and a few flyaways, cut away from the face and kept out of a head-sized ellipsoid (a scalp centered on the head, face toward +Z).", groom: hair),
            Example(name: "Moss Patch", about: "Moss shells leaning a little toward +X, bald underneath (a cut stroke at the bottom), swaying a little in the wind. Apply to a rock or log.", groom: moss),
        ]
    }

    public static let id: CommandID = "groom.examples"
    public static let title = "Groom Examples"
    public static let doc = "Returns three warning-free .groom files to copy or adapt: fur with comb and cut strokes, long hair cards, and moss. Pass `name` for one."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let name = arguments.name else { return Result(examples: examples) }
        guard let found = examples.first(where: { $0.name.lowercased() == name.lowercased() }) else {
            throw CommandError.failed("\(title): no example '\(name)' (\(examples.map(\.name).joined(separator: ", ")))")
        }
        return Result(examples: [found])
    }
}

public enum GroomPresetsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public init() {}
    }

    public struct Preset: Codable, Equatable, Sendable {
        public var name: String
        public var style: GroomStyle
        /// What it's for and its GPU budget.
        public var about: String
        public var groom: GroomBuild
    }

    public struct Result: Codable, Equatable, Sendable {
        public var presets: [Preset]
    }

    public static let id: CommandID = "groom.presets"
    public static let title = "Groom Presets"
    public static let doc = "Lists the built-in grooms (short fur, shaggy fur, velvet, moss, grass-like tufts, the hairstyles straight hair, short crop, bob, bangs, long straight, wavy, curly and ponytail, mane, feathers) with what each is for, its GPU budget and its full contents. groom.new {preset} makes a file from one."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        Result(presets: GroomBuild.presetNames.compactMap { name in
            GroomBuild.preset(name).map { Preset(name: name, style: $0.drawnStyle, about: GroomBuild.presetSummary(name), groom: $0) }
        })
    }
}

public enum GroomApplyCommand: EditorCommand {
    /// What to grow the fur on: one of `entity`, `character` (+ `part`) or `meshBuild` (+ `part`).
    public struct Target: Codable, Equatable, Sendable {
        /// A scene entity with a MeshRenderer, or a parent (a placed model): its descendants with
        /// MeshRenderers get the fur (those the groom's mask.parts names, if any).
        public var entity: EntityID?
        /// A .character file (path or "asset:<id>") with `part`: a body region (skin, body, legs,
        /// accent, eyes) or an attachment's name.
        public var character: String?
        /// A .meshbuild file (path or "asset:<id>") with `part`: a part's name.
        public var meshBuild: String?
        public var part: String?

        public init(entity: EntityID? = nil, character: String? = nil, meshBuild: String? = nil, part: String? = nil) {
            self.entity = entity
            self.character = character
            self.meshBuild = meshBuild
            self.part = part
        }
    }

    public struct Arguments: Codable, Equatable, Sendable {
        /// The .groom file (path relative to Assets/ or "asset:<id>").
        public var groom: String
        public var target: Target
        /// Take the fur off instead (the groom is then only used to name what to clear; "" works).
        public var remove: Bool?
        public init(groom: String, target: Target, remove: Bool? = nil) {
            self.groom = groom
            self.target = target
            self.remove = remove
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// What wears the fur now: entity names, "region body", "attachment Hat / part Brim", "part Rock".
        public var applied: [String]
        /// Fur triangles at full detail over every target (shells x furry triangles, or card triangles).
        public var furTriangles: Int
        /// Missing UVs, fur too dense for the triangle count, masks that cover nothing, import warnings.
        public var warnings: [String]
    }

    public static let id: CommandID = "groom.apply"
    public static let title = "Apply Groom"
    public static let doc = "Grows a .groom's fur on a mesh in one undoable step. `target`: {entity} (a scene entity with a MeshRenderer, or a placed model whose parts get it: those the groom's mask.parts names, or all), {character, part} (a .character body region skin|body|legs|accent|eyes, skinned with the body so it follows the animation, or an attachment's name: its parts), or {meshBuild, part} (a .meshbuild part's `groom` key). `remove: true` takes it off. Warns about meshes without UVs, fur too dense for the triangle count and masks that cover nothing. The fur draws in the editor views (needs the groom imported)."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let assets = session.assets else { throw CommandError.failed(noProjectReason) }
        let remove = arguments.remove == true
        var build = GroomBuild()
        var groomID: AssetID?
        if !remove || !arguments.groom.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let id = assets.groomID(arguments.groom), let found = assets.groom(of: id) else {
                throw CommandError.failed("\(title): '\(arguments.groom)' isn't a .groom file in the project")
            }
            groomID = id
            build = found
        }
        let fur = groomID.flatMap { assets.material(AssetReference($0, subAsset: GroomRenderer.furSubAsset))?.fur } ?? MaterialFur(groom: build)
        let target = arguments.target
        let chosen = [target.entity != nil, target.character != nil, target.meshBuild != nil].filter { $0 }.count
        guard chosen == 1 else { throw CommandError.failed("\(title): give exactly one of target.entity, target.character or target.meshBuild") }
        var applied: [String] = [], warnings: [String] = [], triangles = 0
        func check(_ geometry: MeshGeometry?, _ label: String) {
            guard !remove, let geometry else { return }
            let report = GroomGeometry.report(geometry, fur: fur)
            triangles += report.furTriangles
            warnings += report.warnings.map { "\(label): \($0)" }
        }

        if let id = target.entity {
            let world = session.world
            let entity = try world.require(id)
            // The entity itself when it draws a mesh; else its descendants that do (masked by name).
            var targets: [Entity] = []
            let masked = build.mask.parts.isEmpty || remove ? nil : Set(build.mask.parts)
            if world.get(MeshRenderer.self, for: entity) != nil {
                targets = [entity]
            } else {
                var stack = world.children(of: entity).reversed() as [Entity]
                while let e = stack.popLast() {
                    if world.get(MeshRenderer.self, for: e) != nil,
                       masked.map({ $0.contains(world.get(Name.self, for: e)?.value ?? "") }) ?? true {
                        targets.append(e)
                    }
                    stack += world.children(of: e).reversed()
                }
            }
            if remove { targets = targets.filter { world.get(GroomRenderer.self, for: $0) != nil } }
            guard !targets.isEmpty else {
                throw CommandError.failed("\(title): \(world.get(Name.self, for: entity)?.value ?? id.description) has no MeshRenderer"
                                          + (masked != nil ? " named in the groom's mask.parts (\(build.mask.parts.joined(separator: ", ")))" : "")
                                          + (remove ? " with fur" : ""))
            }
            session.undo.beginGroup(remove ? "Remove Groom" : title)
            defer { session.undo.endGroup() }
            for e in targets {
                let name = world.get(Name.self, for: e)?.value ?? "entity"
                if remove {
                    _ = session.removeComponent(named: GroomRenderer.componentName, from: try session.commands.require(world.id(of: e), title))
                } else {
                    let component = GroomRenderer(groom: GroomRenderer.material(ofGroom: groomID!))
                    guard session.perform(try AddComponentCommand(e, component, in: world, label: title)) else { continue }
                    let mesh = world.get(MeshRenderer.self, for: e)!.mesh
                    check(mesh.assetReference.flatMap { assets.mesh($0) } ?? MeshGeometry.builtin(mesh), name)
                }
                applied.append(name)
            }
        } else if let value = target.character {
            guard let id = assets.id(forReference: value), let old = assets.character(of: id) else {
                throw CommandError.failed("\(title): '\(value)' isn't a .character file in the project")
            }
            guard let part = target.part, !part.isEmpty else { throw CommandError.failed("\(title): give target.part (a body region or an attachment)") }
            var new = old
            let groomValue = remove ? nil : assets.path(of: groomID!)
            var meshNames: [String] = []
            if let region = CharacterRegion(rawValue: part) {
                new.grooms[region.rawValue] = groomValue
                applied.append("region \(region.rawValue)")
                meshNames = ["body \(region.rawValue)"]
            } else if let index = new.attachments.firstIndex(where: { $0.name == part }) {
                new.attachments[index].groom = groomValue
                applied.append("attachment \(part)")
                meshNames = [part + " "]
            } else {
                throw CommandError.failed("\(title): '\(part)' is neither a body region (\(CharacterRegion.allCases.map(\.rawValue).joined(separator: ", "))) nor an attachment of \(value) (\(old.attachments.map(\.name).joined(separator: ", ")))")
            }
            if new != old {
                let command = GroomFileEditCommand(asset: id, contents: .character(old), new: .character(new), in: assets, label: title)
                try session.commands.check(session.perform(command), title)
                warnings += command.warnings.value.filter { $0.contains("groom") || $0.contains("mask") }
            }
            for object in assets.record(id)?.objects ?? [] where object.kind == .mesh
                && meshNames.contains(where: { object.name == $0 || ($0.hasSuffix(" ") && object.name.hasPrefix($0)) }) {
                let partName = String(object.name.dropFirst(meshNames[0].hasSuffix(" ") ? meshNames[0].count : 0))
                if !build.mask.parts.isEmpty, meshNames[0].hasSuffix(" "), !build.mask.parts.contains(partName) { continue }
                check(assets.mesh(AssetReference(id, subAsset: object.id)), object.name)
            }
        } else if let value = target.meshBuild {
            guard let id = assets.id(forReference: value), let old = assets.meshBuild(of: id) else {
                throw CommandError.failed("\(title): '\(value)' isn't a .meshbuild file in the project")
            }
            guard let part = target.part, let index = old.parts.firstIndex(where: { $0.name == part }) else {
                throw CommandError.failed("\(title): give target.part, one of \(old.parts.map(\.name).joined(separator: ", "))")
            }
            var new = old
            new.parts[index].groom = remove ? nil : assets.path(of: groomID!)
            if new != old {
                let command = GroomFileEditCommand(asset: id, contents: .meshBuild(old), new: .meshBuild(new), in: assets, label: title)
                try session.commands.check(session.perform(command), title)
                warnings += command.warnings.value.filter { $0.contains("groom") }
            }
            applied.append("part \(part)")
            for object in assets.record(id)?.objects ?? [] where object.kind == .mesh && object.name == part {
                check(assets.mesh(AssetReference(id, subAsset: object.id)), "part \(part)")
            }
        }
        if !remove, let groomID, let error = assets.record(groomID)?.importError { warnings.append("the groom didn't import: \(error)") }
        return Result(applied: applied, furTriangles: triangles, warnings: warnings)
    }
}

extension AssetDatabase {
    /// The asset `value` names: "asset:<id>[#…]" or a path under `Assets/` (with or without the prefix).
    func id(forReference value: String) -> AssetID? {
        let value = value.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix(AssetReference.scheme) { return AssetReference(value).flatMap { record($0.asset) != nil ? $0.asset : nil } }
        return id(forPath: value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value)
    }
}
