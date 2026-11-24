#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EnginePhysics
import EngineScene

/// Runs a `.vscript` graph on its entity while the game plays (the editor's play mode, built
/// games), with no game module needed. `variables` overrides the graph's exposed variables
/// for this entity. Put one on an empty "Game Rules" entity for a scene-level graph.
public struct VisualScript: Component, Equatable, Sendable {
    public static let componentName = "VisualScript"
    public static var fieldHints: [String: FieldHints] {
        ["graph": FieldHints(tooltip: "The .vscript file: asset:<id> or a path under Assets/"),
         "variables": FieldHints(tooltip: "This entity's values of the graph's exposed variables"),
         "enabled": FieldHints(tooltip: "Off: the graph doesn't run")]
    }

    /// The graph: "asset:<id>" or a path under `Assets/`.
    public var graph: String
    public var enabled: Bool
    /// Per-entity values of the graph's variables, by name.
    public var variables: [String: JSONValue]

    public init(graph: String = "", enabled: Bool = true, variables: [String: JSONValue] = [:]) {
        self.graph = graph
        self.enabled = enabled
        self.variables = variables
    }

    private enum CodingKeys: String, CodingKey { case graph, enabled, variables }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        graph = try c.decodeIfPresent(String.self, forKey: .graph) ?? ""
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        variables = try c.decodeIfPresent([String: JSONValue].self, forKey: .variables) ?? [:]
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(graph, forKey: .graph)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(variables, forKey: .variables)
    }

    /// A component for `graph` with its exposed variables at their defaults (so the inspector lists them).
    public init(graph: String, defaults: VisualScriptGraph) {
        var values: [String: JSONValue] = [:]
        for variable in defaults.variables where variable.exposed {
            values[variable.name] = variable.defaultValue ?? VisualScriptValue.zero(variable.type).json
        }
        self.init(graph: graph, variables: values)
    }
}

/// Imports a `.vscript` file: checks that it decodes and reports the graph's problems as
/// warnings (unknown node types, bad wires, type mismatches, unconnected required inputs,
/// unreachable nodes). A graph has no objects: `VisualScriptRuntime` reads the file again
/// whenever it is reimported, so edits apply while a game runs. A cooked game keeps the file as it is.
///
/// Node types live on the main actor, so the import itself (any thread) checks the structure
/// and the database adds the checks that need node types on the main actor after the import
/// (`AssetImporterMainActorChecks`): background imports get the same warnings as others.
public struct VisualScriptImporter: AssetImporter, AssetImporterMainActorChecks {
    public init() {}

    public var name: String { "vscript" }
    public var fileExtensions: [String] { ["vscript"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let graph: VisualScriptGraph
        do { graph = try VisualScriptGraph.decode(context.data()) } catch {
            throw AssetError.unreadable("not a visual script: \(error)")
        }
        for issue in VisualScriptValidator.structuralIssues(graph) where issue.severity != .info { context.warn(issue.description) }
        return ImportedAsset()
    }

    /// The checks that need node types (`VisualScriptValidator.nodeIssues`), after the import.
    @MainActor
    public func mainActorWarnings(for id: AssetID, in database: AssetDatabase) -> [String] {
        guard let data = try? database.fileData(of: id), let graph = try? VisualScriptGraph.decode(data) else { return [] }
        return VisualScriptValidator.nodeIssues(graph).filter { $0.severity != .info }.map(\.description)
    }
}

extension AssetDatabase {
    /// The `.vscript` asset a component's `graph` names ("asset:<id>" or a path under `Assets/`).
    public func visualScriptID(for value: String) -> AssetID? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        let id: AssetID?
        if value.hasPrefix(AssetReference.scheme) {
            id = AssetReference(value).map(\.asset)
        } else {
            id = self.id(forPath: value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value)
        }
        guard let id, record(id)?.importer == VisualScriptImporter().name else { return nil }
        return id
    }

    /// The graph in the `.vscript` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func visualScript(of id: AssetID) -> VisualScriptGraph? {
        guard record(id)?.importer == VisualScriptImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? VisualScriptGraph.decode(data)
    }

    /// Writes `graph` to a new `.vscript` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createVisualScript(_ graph: VisualScriptGraph, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try graph.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// Overwrites the `.vscript` asset `id` and reimports it (running games pick it up next
    /// frame). Returns the import's warnings about it.
    @discardableResult
    public func writeVisualScript(_ graph: VisualScriptGraph, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try graph.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The asset a node input names (a path under `Assets/` or "asset:<id>"), if it exists.
    public func assetID(forScriptValue value: String) -> AssetID? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme) {
            guard let reference = AssetReference(value), record(reference.asset) != nil else { return nil }
            return reference.asset
        }
        return id(forPath: value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value)
    }
}

extension World {
    /// Runs this world's `VisualScript` components: adds systems "vscript.fixedUpdate",
    /// "vscript.update" and "vscript.lateUpdate" (each last in its stage, so after physics
    /// events) driving a new `VisualScriptRuntime`. Returns the runtime; remove it with
    /// `removeVisualScripts(_:)`. Hosts call this on play: the editor and `ScenePlayback`.
    @MainActor @discardableResult
    public func addVisualScripts(host: VisualScriptHost) -> VisualScriptRuntime {
        ComponentRegistry.register(VisualScript.self)
        removeVisualScripts()
        let runtime = VisualScriptRuntime(world: self, host: host)
        addSystem("vscript.fixedUpdate", stage: .fixedUpdate) { _ in runtime.fixedUpdate() }
        addSystem("vscript.update", stage: .update) { _ in runtime.update() }
        addSystem("vscript.lateUpdate", stage: .lateUpdate) { _ in runtime.lateUpdate() }
        return runtime
    }

    /// The systems `addVisualScripts` adds.
    public static let visualScriptSystemNames = ["vscript.fixedUpdate", "vscript.update", "vscript.lateUpdate"]

    /// Removes the visual script systems; the runtime (if given or found) ends its instances.
    @MainActor
    public func removeVisualScripts(_ runtime: VisualScriptRuntime? = nil) {
        let runtime = runtime ?? VisualScriptRuntime.runtime(for: self)
        for name in Self.visualScriptSystemNames { removeSystem(named: name) }
        runtime?.detach()
    }
}
