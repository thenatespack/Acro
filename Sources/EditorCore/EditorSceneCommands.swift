import Engine
import EngineMCP
import Foundation

// Commands that read the scene (the hierarchy, finding entities, one entity's components, the
// component types and their fields, the selection) and that group edits into one undo step
// (`edit.batch`, `edit.beginBatch` / `edit.endBatch`). The reads return what the hierarchy and
// inspector panels show, as JSON, so a remote caller sees what the user sees; the edits they
// pair with are in EditorCommands.swift.

// MARK: Results

/// One entity in `scene.hierarchy`: id, name, component names and children.
public struct HierarchyNode: Codable, Equatable, Sendable, JSONSchemaProviding {
    public var id: EntityID
    public var name: String
    public var components: [String]
    /// Empty past `depth`, with `more` saying how many there are.
    public var children: [HierarchyNode]
    /// Children left out because of the depth limit.
    public var more: Int?

    // Recursive, so stated rather than probed.
    public static var jsonSchema: JSON {
        [
            "type": "object",
            "properties": [
                "id": ["type": "string", "pattern": "^[0-9a-f]{32}$", "description": "The entity id."],
                "name": ["type": "string"],
                "components": ["type": "array", "items": ["type": "string"]],
                "children": ["type": "array", "items": ["type": "object", "description": "A node like this one."]],
                "more": ["type": "integer", "description": "Children left out past the depth limit."],
            ],
            "required": ["id", "name", "components", "children"],
        ]
    }
}

/// An entity found by `entity.find`.
public struct EntityMatch: Codable, Equatable, Sendable {
    public var id: EntityID
    public var name: String
    /// Names from the root down, joined with "/".
    public var path: String
    public var parent: EntityID?
    public var components: [String]
}

/// One entity with every component (`entity.get`, `editor://entity/{id}`).
public struct EntityDetails: Codable, Equatable, Sendable {
    public var id: EntityID
    public var name: String
    public var parent: EntityID?
    public var children: [EntityID]
    /// Where it is in the world (its `Transform` combined with its parents').
    public var world: Transform
    /// Every saved component's fields by component name, as `component.setField` takes them.
    public var components: [String: JSON]
}

/// A registered component type (`component.types`).
public struct ComponentTypeInfo: Codable, Equatable, Sendable {
    public var name: String
    /// Whether `component.add` can add it (it has a default in `EditorComponentCatalog`).
    public var addable: Bool
    /// Its fields, nested ones by dotted path, as the inspector edits them. Empty when no
    /// value of it is around to reflect (not addable and on no entity).
    public var fields: [ComponentFieldInfo]
    /// The JSON Schema of the component as scene files store it.
    public var schema: JSON
}

/// One field of a component type, from reflection.
public struct ComponentFieldInfo: Codable, Equatable, Sendable {
    /// What `component.setField` takes as `path`.
    public var path: String
    /// "bool", "int", "float", "string", "vec2", "vec3", "vec4", "quat", "entity", "enum",
    /// "array", "unknown" or a structure's type name.
    public var kind: String
    /// An enum's cases.
    public var cases: [String]?
    /// Whether it can be null.
    public var optional: Bool
    /// The default value (nil for structures and arrays, whose children are listed after them).
    public var defaultValue: JSON?
    public var range: [Double]?
    public var readOnly: Bool?
    /// A `vec3` / `vec4` edited as a linear color.
    public var color: Bool?
    public var tooltip: String?
}

// MARK: Query commands

public enum SceneHierarchyCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only this entity's subtree (default: every root).
        public var root: EntityID?
        /// Levels below the roots to include (default: all; 0 lists only the roots).
        public var depth: Int?
        public init(root: EntityID? = nil, depth: Int? = nil) {
            self.root = root
            self.depth = depth
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entities: [HierarchyNode]
    }

    public static let id: CommandID = "scene.hierarchy"
    public static let title = "Hierarchy"
    public static let doc = "Returns the entity tree as the hierarchy panel shows it (roots in order, children in sibling order): each node's id, name, component names and children. `root` limits it to one subtree, `depth` to that many levels."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        let roots = try arguments.root.map { [try world.require($0)] } ?? world.roots
        return Result(entities: roots.compactMap { session.hierarchyNode($0, depth: arguments.depth ?? .max) })
    }
}

public enum EntityFindCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Part of the name, any case (with `exact`, the whole name).
        public var name: String?
        /// Only entities with this component ("Camera", "MeshRenderer"…).
        public var component: String?
        /// An entity id, or its first hex digits (as logs and the inspector abbreviate it).
        public var id: String?
        /// Match `name` exactly.
        public var exact: Bool?
        public init(name: String? = nil, component: String? = nil, id: String? = nil, exact: Bool? = nil) {
            self.name = name
            self.component = component
            self.id = id
            self.exact = exact
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entities: [EntityMatch]
    }

    public static let id: CommandID = "entity.find"
    public static let title = "Find Entities"
    public static let doc = "Finds entities by `name` (substring, any case; whole name with `exact`), by `component` they have, and/or by `id` (or its leading hex digits); all given criteria must match. Returns them in hierarchy order with id, name, path (\"Parent/Child\"), parent and component names."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        let name = arguments.name?.lowercased()
        let idPrefix = arguments.id?.lowercased().replacingOccurrences(of: "-", with: "")
        var found: [EntityMatch] = []
        func visit(_ entity: Entity, path: String) {
            let title = session.displayName(of: entity)
            let path = path.isEmpty ? title : "\(path)/\(title)"
            let components = world.componentTypes(of: entity).filter { $0.isSerialized }.map { $0.componentName }
            let id = world.id(of: entity)
            var matches = true
            if let name {
                let own = (world.get(Name.self, for: entity)?.value ?? title).lowercased()
                matches = arguments.exact == true ? own == name : own.contains(name)
            }
            if let component = arguments.component, !components.contains(component) { matches = false }
            if let idPrefix, !(id?.description.hasPrefix(idPrefix) ?? false) { matches = false }
            if matches, let id {
                found.append(EntityMatch(id: id, name: title, path: path, parent: world.parent(of: entity).flatMap { world.id(of: $0) },
                                         components: components))
            }
            for child in world.children(of: entity) { visit(child, path: path) }
        }
        for root in world.roots { visit(root, path: "") }
        return Result(entities: found)
    }
}

public enum EntityGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        public init(entity: EntityID) { self.entity = entity }
    }

    public static let id: CommandID = "entity.get"
    public static let title = "Get Entity"
    public static let doc = "Returns one entity as the inspector shows it: name, parent, children, its world transform and every component's fields (the values `component.setField` takes, by field name)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EntityDetails {
        _ = try session.world.require(arguments.entity)
        return try session.commands.require(session.entityDetails(arguments.entity), title)
    }
}

public enum ComponentTypesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only this component type.
        public var component: String?
        public init(component: String? = nil) { self.component = component }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var components: [ComponentTypeInfo]
    }

    public static let id: CommandID = "component.types"
    public static let title = "Component Types"
    public static let doc = "Lists the registered component types: whether component.add can add them, their fields (dotted paths for component.setField, kinds, enum cases, defaults, ranges) and the JSON Schema of their saved form."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let names = arguments.component.map { [$0] } ?? ComponentRegistry.names
        let generator = EditorMCP.makeSchemaGenerator()
        let addable = Set(EditorComponentCatalog.addableNames)
        var infos: [ComponentTypeInfo] = []
        for name in names {
            guard let type = ComponentRegistry.type(named: name) else { throw EditorError.unknownComponent(name) }
            guard type.isSerialized || arguments.component != nil else { continue }
            // A value to reflect: the catalog's default, else one in the scene.
            var sample = EditorComponentCatalog.makeDefault(named: name)
            if sample == nil {
                for entity in session.world.roots.flatMap({ session.world.descendants(of: $0, including: true) }) {
                    if let component = session.world.component(named: name, of: entity) {
                        sample = component
                        break
                    }
                }
            }
            infos.append(ComponentTypeInfo(name: name, addable: addable.contains(name),
                                           fields: sample.map { session.fieldInfos($0.fields()) } ?? [],
                                           schema: Self.schema(type, generator)))
        }
        return Result(components: infos)
    }

    private static func schema<C: Component>(_ type: C.Type, _ generator: JSONSchemaGenerator) -> JSON {
        generator.schema(for: type)
    }
}

public enum SelectionGetCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// In selection order (live entities only).
        public var entities: [EntityID]
        /// The one the inspector shows.
        public var primary: EntityID?
    }

    public static let id: CommandID = "selection.get"
    public static let title = "Get Selection"
    public static let doc = "Returns the selected entities and the primary one (shown in the inspector)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let world = session.world
        return Result(entities: session.selection.entities(in: world).compactMap { world.id(of: $0) },
                      primary: session.selection.primaryEntity(in: world).flatMap { world.id(of: $0) })
    }
}

// MARK: Batches

/// The batch `edit.beginBatch` opened.
public struct EditorBatch: Sendable {
    public var label: String
    /// `undo.groupDepth` with its group open.
    var depth: Int
    var selection: [EntityID]
    var primary: EntityID?
}

/// One command call in `edit.batch`.
public struct BatchCall: Codable, Equatable, Sendable {
    /// The command (tool) id, e.g. "entity.create".
    public var command: CommandID
    /// Its arguments. A string "$<n>.<path>" anywhere in them is replaced by that part of
    /// call n's result ("$0.entity", "$1.entities.0"), so later calls can use what earlier
    /// ones created, and "{$<n>.<path>}" inside a longer string is interpolated ("asset:{$2.asset}").
    public var arguments: JSON?
    public init(command: CommandID, arguments: JSON? = nil) {
        self.command = command
        self.arguments = arguments
    }
}

public enum EditBatchCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The undo step's name: what the batch is for ("Build a table").
        public var label: String
        public var calls: [BatchCall]
        public init(label: String, calls: [BatchCall]) {
            self.label = label
            self.calls = calls
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Each call's result, in order.
        public var results: [JSON]
    }

    public static let id: CommandID = "edit.batch"
    public static let title = "Batch"
    public static let doc = "Runs `calls` (each {command, arguments}) in order as ONE undo step named `label`. If a call fails, everything the batch did is undone, the selection is restored, and the error names the call. A string \"$<n>.<path>\" in arguments is replaced by part of call n's result (\"$0.entity\" is the entity call 0 created); \"{$<n>.<path>}\" inside a longer string interpolates it (\"asset:{$2.asset}\"). File operations and screenshots aren't rolled back or can't be batched."
    public static let isUndoable = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let undo = session.undo
        let before = (session.selection.ids, session.selection.primary)
        var results: [JSON] = []
        undo.beginGroup(arguments.label)
        for (index, call) in arguments.calls.enumerated() {
            do {
                if call.command == id { throw CommandError.failed("edit.batch can't contain edit.batch") }
                let json = try Self.substitute(call.arguments ?? [:], results: results)
                results.append(try JSON(data: session.commands.run(call.command, json: json.data())))
            } catch {
                var rollback = ""
                do { try undo.cancelGroup() } catch { rollback = " (undoing it failed: \(error))" }
                session.selection.set(before.0, primary: before.1)
                session.changed()
                throw CommandError.failed("\(arguments.label): call \(index) (\(call.command)) failed: \(error). "
                                          + "Nothing the batch did was kept\(rollback).")
            }
        }
        undo.endGroup()
        session.changed()
        return Result(results: results)
    }

    /// `json` with "$n.path" strings replaced from `results`, and "{$n.path}" inside longer
    /// strings interpolated ("asset:{$2.asset}").
    static func substitute(_ json: JSON, results: [JSON]) throws -> JSON {
        switch json {
        case .string(let text) where text.hasPrefix("$"):
            guard let value = try lookup(text, results: results) else { return json }
            return value
        case .string(var text) where text.contains("{$"):
            var from = text.startIndex
            while let open = text.range(of: "{$", range: from..<text.endIndex),
                  let close = text[open.upperBound...].firstIndex(of: "}") {
                let reference = String(text[text.index(after: open.lowerBound)..<close])
                guard let value = try lookup(reference, results: results) else { from = open.upperBound; continue }
                let inserted = value.stringValue ?? value.text
                text.replaceSubrange(open.lowerBound...close, with: inserted)
                from = text.index(open.lowerBound, offsetBy: inserted.count)
            }
            return .string(text)
        case .array(let items): return .array(try items.map { try substitute($0, results: results) })
        case .object(let members): return .object(try members.mapValues { try substitute($0, results: results) })
        default: return json
        }
    }

    /// The part of `results` that "$n.path" names; nil when it isn't a reference ("$5 off").
    private static func lookup(_ text: String, results: [JSON]) throws -> JSON? {
        var parts = text.dropFirst().split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard let index = Int(parts.removeFirst()) else { return nil }
        guard results.indices.contains(index) else {
            throw CommandError.failed("\(text) refers to call \(index), which hasn't run yet")
        }
        var value = results[index]
        for part in parts {
            if let i = Int(part), let items = value.arrayValue, items.indices.contains(i) {
                value = items[i]
            } else if let member = value[part] {
                value = member
            } else {
                throw CommandError.failed("\(text): call \(index)'s result has no '\(part)'")
            }
        }
        return value
    }
}

public enum EditBeginBatchCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The undo step's name.
        public var label: String
        public init(label: String) { self.label = label }
    }

    public static let id: CommandID = "edit.beginBatch"
    public static let title = "Begin Batch"
    public static let doc = "Starts recording every following edit (from any tool) as ONE undo step named `label`, until edit.endBatch. Undo is unavailable meanwhile. Use edit.batch when the calls are known up front."
    public static func isAvailable(in session: EditorSession) -> Bool { session.batch == nil && !session.undo.isGrouping }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.batch != nil ? "a batch is already open (edit.endBatch closes it)" : "an edit is in progress in the editor (a drag)"
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        session.undo.beginGroup(arguments.label)
        session.batch = EditorBatch(label: arguments.label, depth: session.undo.groupDepth, selection: session.selection.ids,
                                    primary: session.selection.primary)
        session.changed()
        return NoResult()
    }
}

public enum EditEndBatchCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Undo everything the batch did instead of keeping it (and restore the selection).
        public var cancel: Bool?
        public init(cancel: Bool? = nil) { self.cancel = cancel }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var label: String
        /// Whether an undo step was recorded (false when cancelled or nothing changed).
        public var recorded: Bool
    }

    public static let id: CommandID = "edit.endBatch"
    public static let title = "End Batch"
    public static let doc = "Ends the batch edit.beginBatch started: its edits become one undo step, or with `cancel` are undone."
    public static func isAvailable(in session: EditorSession) -> Bool { session.batch != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { "no batch is open (edit.beginBatch starts one)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let batch = session.batch else { throw CommandError.failed("No batch is open") }
        let undo = session.undo
        guard undo.groupDepth <= batch.depth else {
            throw CommandError.failed("An edit is in progress in the editor (a drag); end the batch when it is done")
        }
        session.batch = nil
        defer { session.changed() }
        guard undo.groupDepth == batch.depth else {
            throw CommandError.failed("The batch was dropped when the scene was replaced (scene.new / scene.open)")
        }
        if arguments.cancel == true {
            try undo.cancelGroup()
            session.selection.set(batch.selection, primary: batch.primary)
            return Result(label: batch.label, recorded: false)
        }
        let changes = undo.changeCount
        undo.endGroup()
        return Result(label: batch.label, recorded: undo.changeCount != changes)
    }
}

// MARK: Reading entities

extension EditorSession {
    /// `entity` and `depth` levels of descendants as a `HierarchyNode`.
    func hierarchyNode(_ entity: Entity, depth: Int) -> HierarchyNode? {
        guard let id = world.id(of: entity) else { return nil }
        let children = world.children(of: entity)
        return HierarchyNode(id: id, name: displayName(of: entity),
                             components: world.componentTypes(of: entity).filter { $0.isSerialized }.map { $0.componentName },
                             children: depth > 0 ? children.compactMap { hierarchyNode($0, depth: depth - 1) } : [],
                             more: depth > 0 || children.isEmpty ? nil : children.count)
    }

    /// The entity `id` with every saved component's fields, or nil if it doesn't exist.
    public func entityDetails(_ id: EntityID) -> EntityDetails? {
        guard let entity = world.entity(for: id) else { return nil }
        var components: [String: JSON] = [:]
        for component in world.components(of: entity) where type(of: component).isSerialized {
            components[type(of: component).componentName] = .object(Dictionary(
                component.fields().map { ($0.name, fieldJSON($0)) }, uniquingKeysWith: { first, _ in first }))
        }
        let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
        return EntityDetails(id: id, name: displayName(of: entity), parent: world.parent(of: entity).flatMap { world.id(of: $0) },
                             children: world.children(of: entity).compactMap { world.id(of: $0) },
                             world: Transform(matrix: matrix), components: components)
    }

    func fieldJSON(_ field: FieldDescriptor) -> JSON {
        if let value = field.value { return JSON(value.json(in: world), in: world) }
        switch field.kind {
        case .array: return .array(field.children.map(fieldJSON))
        case .structure:
            return .object(Dictionary(field.children.map { ($0.name, fieldJSON($0)) }, uniquingKeysWith: { first, _ in first }))
        default: return nil
        }
    }

    /// `fields` and their descendants, depth first, as `ComponentFieldInfo`s.
    func fieldInfos(_ fields: [FieldDescriptor]) -> [ComponentFieldInfo] {
        fields.flatMap { field -> [ComponentFieldInfo] in
            guard !field.hints.hidden else { return [] }
            var kind = field.kind.description, cases: [String]?
            if case .enumeration(let names) = field.kind {
                kind = "enum"
                cases = names
            }
            let hints = field.hints
            let info = ComponentFieldInfo(
                path: field.path, kind: kind, cases: cases, optional: field.isOptional,
                defaultValue: field.value.map { JSON($0.json(in: world), in: world) },
                range: hints.range.map { [$0.lowerBound, $0.upperBound] }, readOnly: hints.readOnly ? true : nil,
                color: hints.color ? true : nil, tooltip: hints.tooltip)
            return [info] + fieldInfos(field.children)
        }
    }
}

extension World {
    /// `entity`'s subtree, depth first (with `entity` itself first when `including`).
    @MainActor func descendants(of entity: Entity, including: Bool = false) -> [Entity] {
        var result = including ? [entity] : []
        for child in children(of: entity) { result += descendants(of: child, including: true) }
        return result
    }
}

// MARK: Picking meshes without a renderer

/// What `ScenePicker` tests against when no host renderer is there (headless, tests): the
/// built-in cube, plane and sphere, and the open project's meshes.
@MainActor
public final class EditorPickMeshes: PickMeshSource {
    private unowned let session: EditorSession
    private let builtins = PickMeshLibrary()

    init(session: EditorSession) {
        self.session = session
    }

    public func pickBounds(_ mesh: MeshHandle) -> Bounds? {
        if let reference = mesh.assetReference { return session.assets?.mesh(reference)?.bounds }
        return builtins.pickBounds(mesh)
    }

    public func pickGeometry(_ mesh: MeshHandle) -> MeshGeometry? {
        if let reference = mesh.assetReference { return session.assets?.mesh(reference) }
        return builtins.pickGeometry(mesh)
    }
}
