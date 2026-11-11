import Engine
import Foundation

/// The procedural texture tools: `asset.newProceduralTexture`, `asset.setProceduralTexture`.
@MainActor
public enum EditorProceduralTextureCommands {
    public static let all: [any EditorCommand.Type] = [
        AssetNewProceduralTextureCommand.self,
        AssetSetProceduralTextureCommand.self,
    ]
}

extension EditorSession {
    /// Writes a procedural texture to "New Texture.proctex" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createProceduralTextureAsset(in folder: String, name: String = "New Texture",
                                             texture: ProceduralTexture = ProceduralTexture()) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Procedural Texture") else {
            log.error("New Procedural Texture: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".proctex"))
        do {
            let id = try assets.createProceduralTexture(texture, at: path)
            log.info("Created procedural texture \(path)")
            return id
        } catch {
            log.error("New Procedural Texture failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.proctex` file.
    public func isProceduralTextureFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == ProceduralTextureImporter().name
    }
}

public enum AssetNewProceduralTextureCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Texture" (the file gets ".proctex").
        public var name: String?
        /// Starting point when `texture` is not given (default windowGrid).
        public var generator: ProceduralTexture.Generator?
        /// Its parameters (every key optional; default: the generator's preset).
        public var texture: ProceduralTexture?
        public init(folder: String? = nil, name: String? = nil, generator: ProceduralTexture.Generator? = nil,
                    texture: ProceduralTexture? = nil) {
            self.folder = folder
            self.name = name
            self.generator = generator
            self.texture = texture
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The file; materials reference its `texture` object ("asset:<id>#texture").
        public var asset: AssetID
        public var path: String
    }

    public static let id: CommandID = "asset.newProceduralTexture"
    public static let title = "New Procedural Texture"
    public static let doc = "Writes a .proctex file in `folder`: a texture generated from parameters (generator windowGrid, checker, gradient, noise, bricks or stripes; size, colors, seed, counts, margin, variation), imported like any texture so materials can use its `texture` object. Returns its asset id and path. Change it with asset.setProceduralTexture."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let texture = arguments.texture ?? ProceduralTexture.preset(arguments.generator ?? .windowGrid)
        let id = try session.commands.require(session.createProceduralTextureAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Texture", texture: texture), title)
        return Result(asset: id, path: session.assets?.path(of: id) ?? "")
    }
}

public enum AssetSetProceduralTextureCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The .proctex file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        /// The new parameters. Omitted keys take the defaults, not the file's old values.
        public var texture: ProceduralTexture
        public init(asset: AssetReference? = nil, path: String? = nil, texture: ProceduralTexture) {
            self.asset = asset
            self.path = path
            self.texture = texture
        }
    }

    public static let id: CommandID = "asset.setProceduralTexture"
    public static let title = "Set Procedural Texture"
    public static let doc = "Overwrites a .proctex file with `texture` and reimports it, so materials using it update. Not undoable."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let assets = try session.commands.require(session.assets, title)
        let id = try session.resolveAsset(arguments.asset, path: arguments.path, title)
        guard session.isProceduralTextureFile(id) else { throw CommandError.failed("\(id) isn't a .proctex file") }
        do { try assets.writeProceduralTexture(arguments.texture, to: id) } catch {
            throw CommandError.failed("\(title): \(error)")
        }
        return PathResult(path: assets.path(of: id) ?? "")
    }
}

/// The proxy component for a procedural texture: encodes and decodes as `ProceduralTexture`,
/// so its fields are the inspector grid's rows.
struct ProceduralTextureComponent: Component {
    static var componentName: String { "Procedural Texture" }
    static var fieldHints: [String: FieldHints] { ProceduralTexture.fieldHints }

    var texture: ProceduralTexture

    init(texture: ProceduralTexture) { self.texture = texture }
    init(from decoder: any Decoder) throws { texture = try ProceduralTexture(from: decoder) }
    func encode(to encoder: any Encoder) throws { try texture.encode(to: encoder) }
}

/// Edits one `.proctex` file's parameters through a form: `setField` changes pending values,
/// `apply()` writes the file and reimports (`asset.setProceduralTexture`), `revert()` reloads it.
@MainActor
public final class ProceduralTextureEditor {
    public let session: EditorSession
    public let asset: AssetID
    public let world = World()
    public let entity: Entity
    public private(set) var stored: ProceduralTexture

    /// Nil when `asset` isn't a readable `.proctex` file.
    public init?(session: EditorSession, asset: AssetID) {
        guard let texture = session.assets?.proceduralTexture(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        stored = texture
        entity = world.spawn(ProceduralTextureComponent(texture: texture))
    }

    public var componentName: String { ProceduralTextureComponent.componentName }

    /// The form's current values.
    public var pending: ProceduralTexture {
        world.get(ProceduralTextureComponent.self, for: entity)?.texture ?? stored
    }

    public var isModified: Bool { pending != stored }

    public func setField(_ path: String, to value: FieldValue) throws {
        try world.setField(path, of: componentName, for: entity, to: value)
    }

    @discardableResult
    public func apply() -> Bool {
        guard session.run(AssetSetProceduralTextureCommand.self, .init(asset: AssetReference(asset), texture: pending)) != nil else {
            return false
        }
        stored = pending
        return true
    }

    public func revert() {
        guard let texture = session.assets?.proceduralTexture(of: asset) else { return }
        stored = texture
        world.add(ProceduralTextureComponent(texture: texture), to: entity)
    }
}
