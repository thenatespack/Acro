import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

/// Prefab variants as grid map pieces. `PrefabAsset.template` resolves a variant in a `World`,
/// which imports (running on any thread) can't use, so the grid map importer applies the
/// variant's overrides to its base's entities as JSON instead. It keeps the same prefab-local
/// ids (a scene file's `uid`s, else a hash of the name path) and the override kinds a piece
/// can show: fields, added and removed components, removed entities and added children. Nested
/// prefab instances inside the base keep the data their scene file holds.
extension PieceLoader {
    /// One entity of a prefab as scene-file JSON, with its prefab-local id.
    struct SceneEntity {
        var uid: String
        var parent: String?
        var components: [String: JSONValue]
    }

    /// The scene data of a `.prefab` piece: a scene file's own, or for a variant its base's (a
    /// scene file, a model's prefab or another variant) with the variant's overrides applied.
    /// Nil when a base is missing, unreadable, has more than one root or the chain loops.
    func sceneData(of prefab: PrefabAsset) -> Data? {
        if prefab.variant == nil, let scene = prefab.scene { return scene }
        guard let entities = sceneEntities(of: prefab, depth: 0) else { return nil }
        return Self.sceneFile(entities)
    }

    private func sceneEntities(of prefab: PrefabAsset, depth: Int) -> [SceneEntity]? {
        guard let variant = prefab.variant else {
            if let scene = prefab.scene { return Self.entities(ofScene: scene) }
            return Self.entities(ofRoots: prefab.roots)
        }
        // `imported` returns nil for a file it is already importing, so a cycle ends here too.
        guard depth < 16, let base = imported(variant.base.asset),
              let object = base.object(variant.base.subAsset, kind: .prefab), case .prefab(let basePrefab) = object.value,
              var entities = sceneEntities(of: basePrefab, depth: depth + 1),
              entities.filter({ $0.parent == nil }).count == 1 else { return nil }
        Self.apply(variant.overrides, to: &entities)
        return entities
    }

    /// A scene file's entities, ids given as `PrefabAsset.template` does.
    static func entities(ofScene data: Data) -> [SceneEntity]? {
        struct Record: Decodable {
            var id: Int
            var parent: Int?
            var uid: String?
            var components: [String: PlainJSON]?
        }
        struct File: Decodable { var entities: [Record] }
        guard let file = try? JSONDecoder().decode(File.self, from: data) else { return nil }
        var parentOf: [Int: Int] = [:], uidOf: [Int: String] = [:], name: [Int: String] = [:]
        var order: [Int] = [], components: [Int: [String: JSONValue]] = [:]
        for record in file.entities {
            let id = record.id
            order.append(id)
            parentOf[id] = record.parent
            uidOf[id] = record.uid
            let values = (record.components ?? [:]).mapValues(\.value)
            components[id] = values
            if case .object(let n)? = values["Name"], case .string(let s)? = n["value"] { name[id] = s }
        }
        let known = Set(order)
        // Entities without a uid get the hash of their name path (siblings numbered "#2"...).
        func assign(_ id: Int, path: String) {
            if uidOf[id] == nil { uidOf[id] = World.stableID(path).description }
            var seen: [String: Int] = [:]
            for child in order where parentOf[child] == id {
                let n = name[child] ?? ""
                let count = seen[n, default: 0]
                seen[n] = count + 1
                assign(child, path: path + "/" + n + (count == 0 ? "" : "#\(count + 1)"))
            }
        }
        for id in order where parentOf[id].map({ !known.contains($0) }) ?? true { assign(id, path: name[id] ?? "") }
        return order.map { id in
            SceneEntity(uid: uidOf[id]!, parent: parentOf[id].flatMap { uidOf[$0] }, components: components[id] ?? [:])
        }
    }

    /// A model prefab's nodes as entities (name, transform and mesh renderer), ids from their
    /// name paths as `World.instantiate` plus `assignStableIDs` give them.
    static func entities(ofRoots roots: [PrefabNode]) -> [SceneEntity] {
        var out: [SceneEntity] = []
        func visit(_ node: PrefabNode, parent: String?, path: String) {
            let uid = World.stableID(path).description
            var components: [String: JSONValue] = ["Name": .object(["value": .string(node.name)])]
            if let transform = try? JSONValue.encoding(node.transform) { components["Transform"] = transform }
            if let mesh = node.mesh {
                var renderer: [String: JSONValue] = ["mesh": .string(mesh.description)]
                if let material = node.material { renderer["material"] = .string(material.description) }
                components["MeshRenderer"] = .object(renderer)
            }
            out.append(SceneEntity(uid: uid, parent: parent, components: components))
            var seen: [String: Int] = [:]
            for child in node.children {
                let count = seen[child.name, default: 0]
                seen[child.name] = count + 1
                visit(child, parent: uid, path: path + "/" + child.name + (count == 0 ? "" : "#\(count + 1)"))
            }
        }
        for root in roots { visit(root, parent: nil, path: root.name) }
        return out
    }

    /// Applies a variant's overrides (in `World.applyOverrides`' order); ones that don't fit are skipped.
    static func apply(_ overrides: [PrefabOverride], to entities: inout [SceneEntity]) {
        func rank(_ o: PrefabOverride) -> Int { o.kind == .addedEntity ? 1 : o.kind == .removedElement ? 2 : 0 }
        func lastIndex(_ o: PrefabOverride) -> Int { o.path?.split(separator: ".").last.flatMap { Int($0) } ?? -1 }
        let ordered = overrides.enumerated().sorted { a, b in
            let (x, y) = (rank(a.element), rank(b.element))
            if x != y { return x < y }
            if x == 2, lastIndex(a.element) != lastIndex(b.element) { return lastIndex(a.element) > lastIndex(b.element) }
            return a.offset < b.offset
        }.map(\.element)
        for override in ordered {
            guard let i = entities.firstIndex(where: { $0.uid == override.entity }) else { continue }
            switch override.kind {
            case .removedEntity:
                var gone: Set<String> = [override.entity]
                var grew = true
                while grew {
                    let before = gone.count
                    for e in entities where e.parent.map(gone.contains) == true { gone.insert(e.uid) }
                    grew = gone.count != before
                }
                entities.removeAll { gone.contains($0.uid) }
            case .removedComponent:
                if let name = override.component { entities[i].components[name] = nil }
            case .addedComponent:
                if let name = override.component, let value = override.value { entities[i].components[name] = value }
            case .field, .removedElement:
                // Every entity has a transform in a world, written or not.
                guard let name = override.component,
                      var value = entities[i].components[name] ?? (name == "Transform" ? try? JSONValue.encoding(Transform()) : nil)
                else { continue }
                let keys = override.path.map { $0.isEmpty ? [] : $0.split(separator: ".", omittingEmptySubsequences: false).map(String.init) } ?? []
                let applied = override.kind == .removedElement
                    ? !keys.isEmpty && value.prefabRemoveElement(at: keys[...])
                    : override.value.map { value.prefabSet(at: keys[...], to: $0) } ?? false
                if applied { entities[i].components[name] = value }
            case .addedEntity:
                guard let uid = override.path, !entities.contains(where: { $0.uid == uid }), let value = override.value,
                      let data = try? JSONEncoder().encode(value), var added = Self.entities(ofScene: data), !added.isEmpty else { continue }
                // The added subtree's top hangs under the overridden entity, with the id the variant gave it.
                let top = added[0].uid
                for j in added.indices {
                    if added[j].uid == top { added[j].uid = uid; added[j].parent = override.entity }
                    if added[j].parent == top { added[j].parent = uid }
                }
                entities += added
            }
        }
    }

    /// The entities as a scene file `sceneNodes` reads (parents before children).
    static func sceneFile(_ entities: [SceneEntity]) -> Data? {
        var index: [String: Int] = [:]
        for (i, e) in entities.enumerated() { index[e.uid] = i }
        let records: [JSONValue] = entities.enumerated().map { i, e in
            var record: [String: JSONValue] = ["id": .int(Int64(i)), "uid": .string(e.uid), "components": .object(e.components)]
            if let parent = e.parent.flatMap({ index[$0] }) { record["parent"] = .int(Int64(parent)) }
            return .object(record)
        }
        return try? JSONEncoder().encode(JSONValue.object(["format": .string(SceneFile.format), "version": .int(2), "entities": .array(records)]))
    }

}

/// JSON decoded as a `JSONValue` without reading `{"$entity": n}` as an entity handle (which
/// needs a scene being loaded): such objects stay plain objects.
private struct PlainJSON: Decodable {
    var value: JSONValue

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: any Decoder) throws {
        let single = try decoder.singleValueContainer()
        if single.decodeNil() { value = .null; return }
        if let v = try? single.decode(Bool.self) { value = .bool(v); return }
        if let v = try? single.decode(Int64.self) { value = .int(v); return }
        if let v = try? single.decode(Double.self) { value = .double(v); return }
        if let v = try? single.decode(String.self) { value = .string(v); return }
        if let v = try? single.decode([PlainJSON].self) { value = .array(v.map(\.value)); return }
        let keyed = try decoder.container(keyedBy: Key.self)
        var object: [String: JSONValue] = [:]
        for key in keyed.allKeys { object[key.stringValue] = try keyed.decode(PlainJSON.self, forKey: key).value }
        value = .object(object)
    }
}
