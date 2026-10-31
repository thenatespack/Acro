import Foundation

// Taking component types out of a world and putting them back, for code that comes and goes
// at run time (game modules, hot reload; see GameModule.swift):
//
// - `detachComponents(named:)` moves every component of the named types into the entity's
//   `UnresolvedComponents` as JSON and drops the types' stores, so nothing in the world refers
//   to the types any more. Entity handles inside them are encoded as handles (not file ids),
//   so they come back as the same entities. Entities, hierarchy, ids and other components are
//   untouched, and handles stay valid.
// - `resolveUnresolvedComponents(defaults:)` turns them back into components once types with
//   those names are registered again, tolerating changed types: fields the data lacks take the
//   value of a default component, fields the type no longer has are ignored, and a field whose
//   data no longer decodes (its type changed) is reset to the default. What still fails stays
//   raw JSON, which saving writes back unchanged.

/// What `World.resolveUnresolvedComponents(defaults:)` did.
public struct ComponentResolveReport: Equatable, Sendable {
    /// Components turned back into typed ones.
    public var resolved = 0
    /// Per component name: fields that were reset to the default because their data didn't decode.
    public var resetFields: [String: Set<String>] = [:]
    /// Per component name: why it couldn't be decoded (it stays raw JSON).
    public var failures: [String: String] = [:]
    /// Names still unresolved afterwards: not registered, or failed.
    public var unresolvedNames: Set<String> = []

    public init() {}
}

extension World {
    /// Moves every component of the types named `names` into `UnresolvedComponents` (as JSON)
    /// and drops their stores (see the notes above). Returns how many components moved. Throws,
    /// changing nothing, if one fails to encode. Can't be called from inside a query.
    @discardableResult
    public func detachComponents(named names: Set<String>) throws -> Int {
        precondition(!isIterating, "detachComponents(named:) can't run inside a query")
        let detached = storeOrder.filter {
            names.contains($0.componentType.componentName) && ObjectIdentifier($0.componentType) != ObjectIdentifier(UnresolvedComponents.self)
        }
        guard !detached.isEmpty else { return 0 }
        var moved: [Entity: [String: JSONValue]] = [:]
        var count = 0
        for store in detached where store.count > 0 {
            for slot in alive.indices where alive[slot] {
                let entity = Entity(index: UInt32(slot), generation: generations[slot])
                guard let component = store.component(of: entity) else { continue }
                moved[entity, default: [:]][store.componentType.componentName] = try JSONValue.encoding(component)
                count += 1
            }
        }
        for (entity, values) in moved {
            var components = get(UnresolvedComponents.self, for: entity)?.components ?? [:]
            components.merge(values) { _, new in new }
            add(UnresolvedComponents(components: components), to: entity)
        }
        let ids = Set(detached.map { ObjectIdentifier($0.componentType) })
        storeOrder.removeAll { ids.contains(ObjectIdentifier($0.componentType)) }
        for id in ids { stores[id] = nil }
        return count
    }

    /// The names of the components held as raw JSON in `UnresolvedComponents`, with how many
    /// entities hold each.
    public func unresolvedComponentCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        query(UnresolvedComponents.self) { _, unresolved in
            for name in unresolved.components.keys { counts[name, default: 0] += 1 }
        }
        return counts
    }

    /// Like `resolveUnresolvedComponents()`, but tolerant of types that changed since the data
    /// was written (see the notes above): `defaults(name)` gives a default value of the
    /// registered type, whose fields fill in what the data lacks or can't provide; without one,
    /// the data must decode as it is.
    @discardableResult
    public func resolveUnresolvedComponents(defaults: (String) -> (any Component)?) -> ComponentResolveReport {
        precondition(!isIterating, "resolveUnresolvedComponents(defaults:) can't run inside a query")
        var report = ComponentResolveReport()
        var pending: [(Entity, UnresolvedComponents)] = []
        query(UnresolvedComponents.self) { pending.append(($0, $1)) }
        var baseJSON: [String: JSONValue?] = [:]
        for (entity, unresolved) in pending {
            var remaining = unresolved.components
            for (name, raw) in unresolved.components.sorted(by: { $0.key < $1.key }) {
                guard let type = ComponentRegistry.type(named: name) else { continue }
                if baseJSON[name] == nil { baseJSON[name] = .some(defaults(name).flatMap { try? JSONValue.encoding($0) }) }
                switch Self.decodeTolerantly(type, raw: raw, base: baseJSON[name] ?? nil) {
                case .success(let (component, reset)):
                    add(component, to: entity)
                    remaining[name] = nil
                    report.resolved += 1
                    if !reset.isEmpty { report.resetFields[name, default: []].formUnion(reset) }
                case .failure(let error):
                    if report.failures[name] == nil { report.failures[name] = Self.describe(error) }
                }
            }
            if remaining.isEmpty {
                remove(UnresolvedComponents.self, from: entity)
            } else if remaining.count != unresolved.components.count {
                add(UnresolvedComponents(components: remaining), to: entity)
            }
            report.unresolvedNames.formUnion(remaining.keys)
        }
        return report
    }

    /// Decodes `raw` as `type`, over `base` (the default's JSON): `raw`'s fields win, and a
    /// field that fails to decode falls back to `base`'s, a few times over. Returns the
    /// component and the dotted paths of the fields that fell back.
    private static func decodeTolerantly(_ type: any Component.Type, raw: JSONValue, base: JSONValue?)
        -> Result<(any Component, Set<String>), any Error> {
        guard let base else { return Result { (try decodeComponent(type, from: raw), []) } }
        var overlay = raw
        var reset: Set<String> = []
        var lastError: (any Error)?
        for _ in 0..<16 {
            do {
                return .success((try decodeComponent(type, from: base.merging(overlay)), reset))
            } catch {
                lastError = error
                let path = Self.codingPath(of: error)
                guard !path.isEmpty, let removed = overlay.removing(path) else { break }
                overlay = removed
                reset.insert(path.joined(separator: "."))
            }
        }
        return .failure(lastError ?? SceneError.notASceneFile)
    }

    private static func decodeComponent<C: Component>(_ type: C.Type, from raw: JSONValue) throws -> any Component {
        try raw.decode(C.self)
    }

    private static func codingPath(of error: any Error) -> [String] {
        guard let error = error as? DecodingError else { return [] }
        let context: DecodingError.Context
        switch error {
        case .typeMismatch(_, let c), .valueNotFound(_, let c), .dataCorrupted(let c): context = c
        case .keyNotFound(_, let c): context = c
        @unknown default: return []
        }
        // Array elements: reset the whole array.
        return Array(context.codingPath.prefix { $0.intValue == nil }.map(\.stringValue))
    }

    private static func describe(_ error: any Error) -> String {
        guard let error = error as? DecodingError else { return String(describing: error) }
        func path(_ c: DecodingError.Context) -> String {
            c.codingPath.isEmpty ? "" : " at '\(c.codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: "."))'"
        }
        switch error {
        case .typeMismatch(let type, let c): return "expected \(type)\(path(c))"
        case .valueNotFound(let type, let c): return "missing \(type) value\(path(c))"
        case .keyNotFound(let key, let c): return "missing field '\(key.stringValue)'\(path(c))"
        case .dataCorrupted(let c): return c.debugDescription + path(c)
        @unknown default: return String(describing: error)
        }
    }
}

extension JSONValue {
    /// This object with `overlay`'s keys put over it, recursively for nested objects; any
    /// other `overlay` replaces it.
    func merging(_ overlay: JSONValue) -> JSONValue {
        guard case .object(let base) = self, case .object(let top) = overlay else { return overlay }
        var merged = base
        for (key, value) in top { merged[key] = base[key].map { $0.merging(value) } ?? value }
        return .object(merged)
    }

    /// This value without the field at `path`, or nil if there is none.
    func removing(_ path: [String]) -> JSONValue? {
        guard let first = path.first, case .object(var object) = self, let child = object[first] else { return nil }
        if path.count == 1 {
            object[first] = nil
        } else {
            guard let removed = child.removing(Array(path.dropFirst())) else { return nil }
            object[first] = removed
        }
        return .object(object)
    }
}
