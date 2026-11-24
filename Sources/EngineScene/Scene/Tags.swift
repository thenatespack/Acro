#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// The Tag component (named `Tags` in Swift, as Swift Testing owns `Tag`): labels that group entities across the hierarchy ("enemy", "pickup", "checkpoint"), so game
/// code, visual scripts and tools can find them without knowing names or parents.
///
/// Scene files store the tags as one comma-separated string (`{"Tag": {"tags": "enemy, boss"}}`),
/// which the inspector edits as a text field; an array of strings also loads. Tags are trimmed,
/// non-empty, unique and can't contain commas.
///
/// ```swift
/// world.add(Tags("enemy", "boss"), to: ogre)
/// for enemy in world.entities(taggedWith: "enemy") { … }
/// world.addTag("stunned", to: ogre)
/// ```
public struct Tags: Component, Equatable, Sendable {
    public static let componentName = "Tag"
    public static var fieldHints: [String: FieldHints] {
        ["tags": FieldHints(tooltip: "Comma-separated, e.g. enemy, boss")]
    }

    /// The tags, in the order given, without duplicates.
    public private(set) var tags: [String]

    public init(_ tags: String...) { self.init(tags: tags) }

    public init(tags: [String]) {
        self.tags = []
        for tag in tags { insert(tag) }
    }

    /// Whether the entity has `tag`.
    public func contains(_ tag: String) -> Bool { tags.contains(Self.clean(tag)) }

    /// Adds `tag` (trimmed, commas removed) unless it is empty or already there.
    public mutating func insert(_ tag: String) {
        let clean = Self.clean(tag)
        if !clean.isEmpty, !tags.contains(clean) { tags.append(clean) }
    }

    public mutating func remove(_ tag: String) {
        let clean = Self.clean(tag)
        tags.removeAll { $0 == clean }
    }

    /// `tag` as stored: trimmed, without commas.
    public static func clean(_ tag: String) -> String {
        tag.replacingOccurrences(of: ",", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The tags in `text`, split at commas.
    public static func parse(_ text: String) -> [String] {
        text.split(separator: ",").map { clean(String($0)) }.filter { !$0.isEmpty }
    }

    private enum CodingKeys: String, CodingKey { case tags }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let list = try? c.decodeIfPresent([String].self, forKey: .tags) {
            self.init(tags: list)
        } else {
            self.init(tags: Self.parse(try c.decodeIfPresent(String.self, forKey: .tags) ?? ""))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tags.joined(separator: ", "), forKey: .tags)
    }
}

extension World {
    /// Whether `entity` has `tag` (its `Tag` component lists it).
    public func hasTag(_ tag: String, _ entity: Entity) -> Bool {
        get(Tags.self, for: entity)?.contains(tag) ?? false
    }

    /// Every entity tagged `tag`, in storage order.
    public func entities(taggedWith tag: String) -> [Entity] {
        let clean = Tags.clean(tag)
        var found: [Entity] = []
        query(Tags.self) { entity, tags in if tags.tags.contains(clean) { found.append(entity) } }
        return found
    }

    /// The first entity tagged `tag` (in storage order), or nil.
    public func firstEntity(taggedWith tag: String) -> Entity? {
        let clean = Tags.clean(tag)
        var found: Entity?
        query(Tags.self) { entity, tags in if found == nil, tags.tags.contains(clean) { found = entity } }
        return found
    }

    /// Tags `entity` with `tag`, adding a `Tag` component if it has none.
    public func addTag(_ tag: String, to entity: Entity) {
        guard isAlive(entity), !Tags.clean(tag).isEmpty else { return }
        if has(Tags.self, for: entity) {
            modify(Tags.self, for: entity) { $0.insert(tag) }
        } else {
            add(Tags(tags: [tag]), to: entity)
        }
    }

    /// Removes `tag` from `entity`, and the `Tag` component once it has no tags left.
    public func removeTag(_ tag: String, from entity: Entity) {
        guard var tags = get(Tags.self, for: entity) else { return }
        tags.remove(tag)
        if tags.tags.isEmpty { remove(Tags.self, from: entity) } else { add(tags, to: entity) }
    }
}
