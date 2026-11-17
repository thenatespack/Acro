import EditorCore
import Engine
import Foundation

/// The Material Builder tools: `materialGraph.new`, `.get`, `.set`, `.edit`, `.nodes`, `.assign`
/// (and `materialGraph.open` in MaterialBuilderWorkspace.swift). They edit the `graph` of a
/// `.material` file; `material.get` / `material.set` keep editing its fixed PBR fields.
@MainActor
public enum EditorMaterialGraphCommands {
    public static let all: [any EditorCommand.Type] = [
        MaterialGraphNewCommand.self,
        MaterialGraphGetCommand.self,
        MaterialGraphSetCommand.self,
        MaterialGraphEditCommand.self,
        MaterialGraphNodesCommand.self,
        MaterialGraphAssignCommand.self,
        MaterialGraphOpenCommand.self,
    ]

    /// What the tool docs say about the graph format, shared by the tools.
    static let formatDoc = """
        A material graph lives in a .material file's `graph` key: {"nodes": [...], "output": {...}}. A node is {"id", "type", \
        ...keys}; an input key holds a constant (number or [2-4 numbers]) or a link "nodeId" / "nodeId.swizzle" ("tex.rgb", \
        "n.x"); a link may also name a built-in: uv, position, normal, viewDir, vertexColor, time. Sizes convert as in GLSL \
        (a scalar fills a vector). Node types: \(MaterialGraphNodeType.all.map(\.name).joined(separator: ", ")) (see \
        materialGraph.nodes for inputs and settings). `output` maps the PBR inputs \
        \(MaterialGraph.outputs.map { "\($0.name) (\($0.size == 1 ? "float" : "vec\($0.size)"), default \($0.defaultValue.map { String(format: "%g", $0) }.joined(separator: ",")))" }.joined(separator: ", ")); \
        normal is tangent-space, emissive is linear light added after lighting. Colors are linear. Texture settings take a path \
        under Assets/ (image or .proctex) or asset:<id>; up to \(MaterialGraphCompiler.maxTextures) different textures. The graph \
        compiles into a shader variant for Metal and Vulkan at import; constants are data, so changing one doesn't recompile. \
        Opacity needs alphaMode "blend" (or "mask" with alphaCutoff). Presets: \(MaterialGraph.presetNames.joined(separator: ", ")).
        """
}

extension EditorSession {
    /// Writes a material with `graph` to "`name`.material" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createMaterialGraphAsset(in folder: String, name: String = "New Material Graph", material: MaterialAsset) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Material Graph") else {
            log.error("New Material Graph: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".material"))
        do {
            let id = try assets.createMaterial(material, at: path)
            log.info("Created material graph \(path)")
            return id
        } catch {
            log.error("New Material Graph failed: \(error)")
            return nil
        }
    }

    /// Replaces the `.material` file `id` (as written, see `AssetDatabase.materialFile`) as one undo
    /// step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyMaterialFile(_ material: MaterialAsset, to id: AssetID, label: String = "Edit Material Graph") -> [String]? {
        guard let assets, let old = assets.materialFile(of: id) else {
            log.error("\(label): \(id) isn't a readable .material file")
            return nil
        }
        guard old != material else { return assets.materialGraphWarnings(material) }
        let command = MaterialFileEditCommand(asset: id, old: old, new: material, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    func resolveMaterialFile(_ target: some MaterialGraphTarget, _ title: String) throws -> (AssetID, MaterialAsset) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isMaterialFile(id), let material = assets?.materialFile(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .material file")
        }
        return (id, material)
    }
}

/// Makes material file edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct MaterialFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: MaterialAsset
    public let new: MaterialAsset
    let warnings = EditorBuilderSupport.Box<[String]>([])
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: MaterialAsset, new: MaterialAsset, in database: AssetDatabase, label: String = "Edit Material Graph") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ material: MaterialAsset) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeMaterialFile(material, to: asset)
    }
}

/// Arguments naming a `.material` file.
public protocol MaterialGraphTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

/// What the material graph tools return.
public struct MaterialGraphResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The graph as written (nil: the material uses its fixed PBR fields).
    public var graph: MaterialGraph?
    /// "opaque", "mask" or "blend".
    public var alphaMode: String
    public var alphaCutoff: Float
    public var doubleSided: Bool
    /// Node ids added by this call (materialGraph.edit addNodes).
    public var added: [String]?
    /// Graph and import problems.
    public var warnings: [String]
    /// The generated shader code of the graph (materialGraph.get with `code`).
    public var code: String?
}

extension MaterialGraphResult {
    @MainActor init(_ id: AssetID, _ material: MaterialAsset, warnings: [String]? = nil, added: [String]? = nil, code: Bool = false,
                    in session: EditorSession) {
        let record = session.assets?.record(id)
        let graphWarnings = warnings ?? session.assets?.materialGraphWarnings(material) ?? []
        var program: String?
        if code, let graph = material.graph { program = MaterialGraphCompiler.compile(graph).program?.code }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", graph: material.graph,
                  alphaMode: material.alphaMode.rawValue.lowercased(), alphaCutoff: material.alphaCutoff, doubleSided: material.doubleSided,
                  added: added, warnings: Array(Set(graphWarnings)).sorted() + (record?.importError.map { ["import failed: \($0)"] } ?? []),
                  code: program)
    }
}

/// The material keys the graph tools can change besides the graph.
public struct MaterialGraphSettings: Codable, Equatable, Sendable {
    /// "opaque", "mask" or "blend".
    public var alphaMode: String?
    public var alphaCutoff: Float?
    public var doubleSided: Bool?
    /// "linear" or "nearest" texture filtering.
    public var filter: String?
    /// "repeat", "clampToEdge" or "mirrorRepeat".
    public var addressMode: String?
    public init(alphaMode: String? = nil, alphaCutoff: Float? = nil, doubleSided: Bool? = nil, filter: String? = nil, addressMode: String? = nil) {
        self.alphaMode = alphaMode
        self.alphaCutoff = alphaCutoff
        self.doubleSided = doubleSided
        self.filter = filter
        self.addressMode = addressMode
    }

    func apply(to material: inout MaterialAsset) throws {
        if let alphaMode {
            guard let mode = AlphaMode(rawValue: alphaMode.uppercased()) else {
                throw CommandError.failed("alphaMode must be opaque, mask or blend")
            }
            material.alphaMode = mode
        }
        if let alphaCutoff { material.alphaCutoff = min(max(alphaCutoff, 0), 1) }
        if let doubleSided { material.doubleSided = doubleSided }
        if let filter { material.filter = filter == "nearest" ? .nearest : .linear }
        if let addressMode {
            material.addressMode = switch addressMode {
            case "clampToEdge": .clampToEdge
            case "mirrorRepeat": .mirrorRepeat
            default: .repeat
            }
        }
    }
}

/// A material for a preset graph: blended for the presets that drive opacity.
func materialForGraphPreset(_ name: String) throws -> MaterialAsset {
    guard let graph = MaterialGraph.preset(name) else {
        throw CommandError.failed("Unknown preset '\(name)'; use \(MaterialGraph.presetNames.joined(separator: ", "))")
    }
    var material = MaterialAsset(alphaMode: graph.output["opacity"] != nil ? .blend : .opaque, doubleSided: false)
    material.graph = graph
    return material
}

/// A graph that reproduces `material`'s fixed fields (base color, texture, metallic, roughness,
/// emissive), for converting a plain material.
public func graphFromFixedFields(_ material: MaterialAsset) -> MaterialGraph {
    func v(_ values: [Float]) -> JSONValue { values.count == 1 ? .double(Double(values[0])) : .array(values.map { .double(Double($0)) }) }
    var graph = MaterialGraph()
    let color = MaterialGraphNode(id: "baseColor", type: "color", position: Vec2(0, 0),
                                  fields: ["value": v([material.baseColor.x, material.baseColor.y, material.baseColor.z, material.baseColor.w])])
    graph.nodes.append(color)
    if let texture = material.texture {
        graph.nodes.append(MaterialGraphNode(id: "albedo", type: "texture", position: Vec2(0, 1), fields: ["texture": .string(texture.description)]))
        graph.nodes.append(MaterialGraphNode(id: "tinted", type: "math", position: Vec2(1, 0),
                                             fields: ["op": .string("multiply"), "a": .string("baseColor"), "b": .string("albedo")]))
        graph.output["baseColor"] = .string("tinted.rgb")
        graph.output["opacity"] = .string("tinted.a")
    } else {
        graph.output["baseColor"] = .string("baseColor.rgb")
        if material.baseColor.w < 1 { graph.output["opacity"] = .string("baseColor.a") }
    }
    graph.output["metallic"] = v([material.metallic])
    graph.output["roughness"] = v([material.roughness])
    let glow = material.emissiveColor * material.emissiveStrength
    if glow != .zero { graph.output["emissive"] = v([glow.x, glow.y, glow.z]) }
    return graph
}

public enum MaterialGraphNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Material Graph" (the file gets ".material").
        public var name: String?
        /// basic, lava, water, hologram, stone or pulse (default basic).
        public var preset: String?
        /// A whole graph instead of the preset.
        public var graph: MaterialGraph?
        public var settings: MaterialGraphSettings?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, graph: MaterialGraph? = nil,
                    settings: MaterialGraphSettings? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.graph = graph
            self.settings = settings
        }
    }

    public static let id: CommandID = "materialGraph.new"
    public static let title = "New Material Graph"
    public static let doc = "Writes a .material file with a node graph in `folder` (default: the Assets root) from a `preset` (default basic) or a whole `graph`, with optional `settings` (alphaMode, alphaCutoff, doubleSided, filter, addressMode), and imports it. Returns the asset, the graph and warnings. Use it on a MeshRenderer (materialGraph.assign) or a mesh build part's `material`. " + EditorMaterialGraphCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MaterialGraphResult {
        var material = try materialForGraphPreset(arguments.preset ?? "basic")
        if let graph = arguments.graph { material.graph = graph }
        try arguments.settings?.apply(to: &material)
        let id = try session.commands.require(
            session.createMaterialGraphAsset(in: arguments.folder ?? "", name: arguments.name ?? "New Material Graph", material: material), title)
        return MaterialGraphResult(id, material, in: session)
    }
}

public enum MaterialGraphGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MaterialGraphTarget {
        public var asset: AssetReference?
        /// Or the path relative to `Assets/`.
        public var path: String?
        /// Also return the generated shader code of `graphSurface` (MSL).
        public var code: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, code: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.code = code
        }
    }

    public static let id: CommandID = "materialGraph.get"
    public static let title = "Get Material Graph"
    public static let doc = "Reads a .material file's node graph as written, its alpha mode and sidedness, and the graph's problems (unknown nodes, missing links, cycles, missing textures). `code: true` adds the generated shader code."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MaterialGraphResult {
        let (id, material) = try session.resolveMaterialFile(arguments, title)
        return MaterialGraphResult(id, material, code: arguments.code == true, in: session)
    }
}

public enum MaterialGraphSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MaterialGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new graph (replaces the old one), or start from a `preset`.
        public var graph: MaterialGraph?
        public var preset: String?
        /// Remove the graph: the material goes back to its fixed PBR fields.
        public var clear: Bool?
        public var settings: MaterialGraphSettings?
        public init(asset: AssetReference? = nil, path: String? = nil, graph: MaterialGraph? = nil, preset: String? = nil,
                    clear: Bool? = nil, settings: MaterialGraphSettings? = nil) {
            self.asset = asset
            self.path = path
            self.graph = graph
            self.preset = preset
            self.clear = clear
            self.settings = settings
        }
    }

    public static let id: CommandID = "materialGraph.set"
    public static let title = "Set Material Graph"
    public static let doc = "Replaces a .material file's whole node graph (`graph` or a `preset`; `clear: true` removes it) and optional `settings`, then reimports it; everything using the material updates. Undoable. For a few changes, materialGraph.edit is shorter. " + EditorMaterialGraphCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MaterialGraphResult {
        let (id, original) = try session.resolveMaterialFile(arguments, title)
        var material = original
        if arguments.clear == true {
            material.graph = nil
        } else if let graph = arguments.graph {
            material.graph = graph
        } else if let preset = arguments.preset {
            let presetMaterial = try materialForGraphPreset(preset)
            material.graph = presetMaterial.graph
            material.alphaMode = presetMaterial.alphaMode
        } else if arguments.settings == nil {
            throw CommandError.failed("\(title): give `graph`, `preset`, `clear` or `settings`")
        }
        try arguments.settings?.apply(to: &material)
        let warnings = try session.commands.require(session.applyMaterialFile(material, to: id, label: title), title)
        return MaterialGraphResult(id, material, warnings: warnings, in: session)
    }
}

public enum MaterialGraphEditCommand: EditorCommand {
    /// A link to make: `from` (a node, "node.swizzle", a built-in or a constant) into `to` ("node.input" or "output.baseColor").
    public struct Connection: Codable, Equatable, Sendable {
        public var from: JSONValue
        public var to: String
        public init(from: JSONValue, to: String) {
            self.from = from
            self.to = to
        }
    }

    public struct Arguments: Codable, Equatable, Sendable, MaterialGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Start over from this preset before the other changes.
        public var preset: String?
        /// Nodes to add: {"type": "noise", "id"?: "n1", ...keys}. A missing or taken id gets a fresh one (returned in `added`).
        public var addNodes: [MaterialGraphNode]?
        /// Node ids to remove; links to them fall back to the input's default.
        public var removeNodes: [String]?
        /// Links (or constants) to set, e.g. {"from": "noise1.x", "to": "blend1.factor"} or {"from": "tex.rgb", "to": "output.baseColor"}.
        public var connect: [Connection]?
        /// Inputs to reset to their default: "node.input" or "output.normal".
        public var disconnect: [String]?
        /// Keys to set per node: {"noise1": {"scale": 12, "kind": "fbm"}}; null removes a key.
        public var params: [String: [String: JSONValue]]?
        /// Output keys to set, as in the graph's `output` (null resets one).
        public var output: [String: JSONValue]?
        public var settings: MaterialGraphSettings?
        public init(asset: AssetReference? = nil, path: String? = nil, preset: String? = nil, addNodes: [MaterialGraphNode]? = nil,
                    removeNodes: [String]? = nil, connect: [Connection]? = nil, disconnect: [String]? = nil,
                    params: [String: [String: JSONValue]]? = nil, output: [String: JSONValue]? = nil, settings: MaterialGraphSettings? = nil) {
            self.asset = asset
            self.path = path
            self.preset = preset
            self.addNodes = addNodes
            self.removeNodes = removeNodes
            self.connect = connect
            self.disconnect = disconnect
            self.params = params
            self.output = output
            self.settings = settings
        }
    }

    public static let id: CommandID = "materialGraph.edit"
    public static let title = "Edit Material Graph"
    public static let doc = "Changes a .material file's node graph in one undoable step, in this order: optional `preset` restart, `removeNodes`, `addNodes` ({type, id?, ...keys}), `params` ({nodeId: {key: value}}), `connect` ([{from, to}] with to \"node.input\" or \"output.<pbr input>\"), `disconnect` ([\"node.input\"]), `output`, `settings`. A material without a graph gets an empty one first. Returns the full graph, the ids of added nodes and warnings. " + EditorMaterialGraphCommands.formatDoc
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> MaterialGraphResult {
        let (id, original) = try session.resolveMaterialFile(arguments, title)
        let (material, added) = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyMaterialFile(material, to: id, label: title), title)
        return MaterialGraphResult(id, material, warnings: warnings, added: added, in: session)
    }

    /// `material` with the edits applied and the ids of the nodes added (pure, for tests).
    public static func edited(_ material: MaterialAsset, with arguments: Arguments) throws -> (MaterialAsset, [String]) {
        var material = material
        if let preset = arguments.preset {
            let presetMaterial = try materialForGraphPreset(preset)
            material.graph = presetMaterial.graph
            material.alphaMode = presetMaterial.alphaMode
        }
        var graph = material.graph ?? MaterialGraph()
        for id in arguments.removeNodes ?? [] {
            guard graph.node(id) != nil else { throw CommandError.failed("removeNodes: no node '\(id)'") }
            removeNode(id, from: &graph)
        }
        var added: [String] = []
        for var node in arguments.addNodes ?? [] {
            guard MaterialGraphNodeType.catalog[node.type] != nil else {
                throw CommandError.failed("addNodes: unknown node type '\(node.type)'; types: \(MaterialGraphNodeType.all.map(\.name).joined(separator: ", "))")
            }
            if node.id.isEmpty || graph.node(node.id) != nil { node.id = graph.uniqueID(node.id.isEmpty ? node.type : node.id) }
            if node.position == nil { node.position = autoPosition(for: graph) }
            graph.nodes.append(node)
            added.append(node.id)
        }
        for (id, fields) in arguments.params ?? [:] {
            guard let i = graph.index(of: id) else { throw CommandError.failed("params: no node '\(id)'") }
            for (key, value) in fields {
                if key == "type" {
                    guard case .string(let type) = value, MaterialGraphNodeType.catalog[type] != nil else {
                        throw CommandError.failed("params: '\(id)'.type must be a node type")
                    }
                    graph.nodes[i].type = type
                } else if key == "position" {
                    graph.nodes[i].position = MaterialGraph.numbers(value).flatMap { $0.count == 2 ? Vec2($0[0], $0[1]) : nil }
                } else if key != "id" {
                    graph.nodes[i][key] = value == .null ? nil : value
                }
            }
        }
        for connection in arguments.connect ?? [] {
            try setInput(connection.to, to: connection.from, in: &graph)
        }
        for target in arguments.disconnect ?? [] {
            try setInput(target, to: .null, in: &graph)
        }
        for (key, value) in arguments.output ?? [:] {
            try setInput("output.\(key)", to: value, in: &graph)
        }
        material.graph = graph
        try arguments.settings?.apply(to: &material)
        return (material, added)
    }

    /// Sets `target` ("node.input" or "output.name") to `value` (null resets it).
    static func setInput(_ target: String, to value: JSONValue, in graph: inout MaterialGraph) throws {
        guard let dot = target.lastIndex(of: ".") else {
            throw CommandError.failed("'\(target)': use \"node.input\" or \"output.<\(MaterialGraph.outputs.map(\.name).joined(separator: "|"))>\"")
        }
        let owner = String(target[..<dot]), key = String(target[target.index(after: dot)...])
        if case .string(let link) = value, let parsed = MaterialGraphLink(link), graph.node(parsed.node) == nil,
           !["uv", "position", "normal", "viewDir", "vertexColor", "time"].contains(parsed.node) {
            throw CommandError.failed("'\(link)' links to no node")
        }
        if owner == "output" && graph.node("output") == nil {
            guard MaterialGraph.outputs.contains(where: { $0.name == key }) else {
                throw CommandError.failed("No output '\(key)'; outputs: \(MaterialGraph.outputs.map(\.name).joined(separator: ", "))")
            }
            graph.output[key] = value == .null ? nil : value
            return
        }
        guard let i = graph.index(of: owner) else { throw CommandError.failed("'\(target)': no node '\(owner)'") }
        let type = MaterialGraphNodeType.catalog[graph.nodes[i].type]
        guard type?.input(key) != nil || type?.setting(key) != nil else {
            let names = (type?.inputs.map(\.name) ?? []) + (type?.settings.map(\.name) ?? [])
            throw CommandError.failed("'\(target)': a \(graph.nodes[i].type) node has no input '\(key)' (has: \(names.joined(separator: ", ")))")
        }
        graph.nodes[i][key] = value == .null ? nil : value
    }

    /// Removes node `id` and resets every input and output linked to it.
    static func removeNode(_ id: String, from graph: inout MaterialGraph) {
        graph.nodes.removeAll { $0.id == id }
        func linksToRemoved(_ value: JSONValue) -> Bool {
            if case .string(let s) = value, MaterialGraphLink(s)?.node == id { return true }
            return false
        }
        for i in graph.nodes.indices {
            for (key, value) in graph.nodes[i].fields where linksToRemoved(value) { graph.nodes[i][key] = nil }
        }
        for (key, value) in graph.output where linksToRemoved(value) { graph.output[key] = nil }
    }

    /// A free canvas spot for a new node: right of the rightmost column.
    static func autoPosition(for graph: MaterialGraph) -> Vec2 {
        let positions = graph.nodes.compactMap(\.position)
        guard let maxX = positions.map(\.x).max() else { return Vec2(0, 0) }
        let column = positions.filter { $0.x == maxX }
        return column.count < 4 ? Vec2(maxX, (column.map(\.y).max() ?? -1) + 1) : Vec2(maxX + 1, 0)
    }
}

public enum MaterialGraphNodesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public init() {}
    }

    public struct NodeInfo: Codable, Equatable, Sendable {
        public var type: String
        public var category: String
        public var summary: String
        /// "name (size, default …)" per input; size 0 adapts to what's connected.
        public var inputs: [String]
        public var settings: [String]
        public var output: String
    }

    public struct Result: Codable, Equatable, Sendable {
        public var nodes: [NodeInfo]
        public var outputs: [String]
        public var builtins: [String]
        public var presets: [String]
    }

    public static let id: CommandID = "materialGraph.nodes"
    public static let title = "Material Graph Node Types"
    public static let doc = "Lists every material graph node type with its inputs (sizes, defaults), settings and output size, plus the PBR outputs, built-in link names and presets."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        func size(_ n: Int) -> String { n == 0 ? "any" : n == 1 ? "float" : "vec\(n)" }
        func numbers(_ values: [Float]) -> String { values.map { String(format: "%g", $0) }.joined(separator: ", ") }
        let nodes = MaterialGraphNodeType.all.map { type in
            NodeInfo(type: type.name, category: type.category, summary: type.summary,
                     inputs: type.inputs.map { "\($0.name) (\(size($0.size)), default \($0.defaultLink ?? numbers($0.defaultValue)))" },
                     settings: type.settings.map { setting in
                         let kind: String = switch setting.kind {
                         case .choice(let options): options.joined(separator: "|")
                         case .texture: "texture path"
                         case .integer(let range): "\(range.lowerBound)...\(range.upperBound)"
                         case .flag: "bool"
                         }
                         return "\(setting.name) (\(kind))"
                     },
                     output: size(type.outputSize))
        }
        return Result(nodes: nodes, outputs: MaterialGraph.outputs.map { "\($0.name) (\(size($0.size)), default \(numbers($0.defaultValue)))" },
                      builtins: ["uv", "position", "normal", "viewDir", "vertexColor", "time"], presets: MaterialGraph.presetNames)
    }
}

public enum MaterialGraphAssignCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MaterialGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The entity whose MeshRenderer (or Decal) gets the material (default: the selection's primary entity).
        public var entity: EntityID?
        /// Also every MeshRenderer and Decal below it (a placed model or prefab).
        public var children: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, entity: EntityID? = nil, children: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.entity = entity
            self.children = children
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var path: String
        /// The entities whose MeshRenderer.material or Decal.material was set.
        public var entities: [EntityID]
    }

    public static let id: CommandID = "materialGraph.assign"
    public static let title = "Assign Material Graph"
    public static let doc = "Sets the MeshRenderer.material of an entity (default: the selected one), and with `children: true` of every MeshRenderer below it (a placed model or prefab), to a .material file. A Decal gets it as its `material` (it paints the graph instead of its texture). Undoable, one step. Mesh build parts use a material through their `material` key instead."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, _) = try session.resolveMaterialFile(arguments, title)
        let world = session.world
        let root: Entity
        if let entityID = arguments.entity ?? session.selection.primary { root = try world.require(entityID) } else {
            throw CommandError.failed("\(title): select an entity or pass `entity`")
        }
        var targets: [(entity: Entity, component: String, old: FieldValue)] = []
        func visit(_ entity: Entity) {
            if let renderer = world.get(MeshRenderer.self, for: entity) {
                targets.append((entity, MeshRenderer.componentName, .string(renderer.material.key)))
            }
            if let decal = world.get(Decal.self, for: entity) {
                targets.append((entity, Decal.componentName, decal.material.map { .string($0.key) } ?? .null))
            }
            if arguments.children == true { for child in world.children(of: entity) { visit(child) } }
        }
        visit(root)
        guard !targets.isEmpty else {
            throw CommandError.failed("\(title): no MeshRenderer or Decal on the entity\(arguments.children == true ? " or below it" : "")")
        }
        let value = AssetReference(id, subAsset: "material").description
        var edits: [any UndoCommand] = []
        var ids: [EntityID] = []
        for (entity, component, old) in targets {
            guard let entityID = world.ensureID(of: entity) else { continue }
            edits.append(SetFieldCommand(id: entityID, component: component, path: "material", old: old, new: .string(value)))
            if ids.last != entityID { ids.append(entityID) }
        }
        guard session.perform(GroupCommand(title, edits)) else { throw CommandError.failed("\(title) failed") }
        return Result(path: session.assets?.path(of: id) ?? "", entities: ids)
    }
}
