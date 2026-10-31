import Foundation

// Prefab variants: a `.prefab` file that is another prefab plus its own overrides.
//
// ```swift
// let id = try database.createPrefabVariant(of: AssetReference(crate), at: "Crates/Heavy.prefab")
// // Heavy.prefab: {"format": "sge-prefab-variant", "base": "asset:<crate>", "overrides": [...]}
// ```
//
// The overrides are `PrefabOverride`s in the base template's prefab-local ids (the same kinds an
// instance has: fields, array elements, components, removed and added children), so a variant
// holds exactly what an instance of the base would override. `PrefabAsset.template` resolves the
// chain (a variant of a variant works; cycles throw `PrefabError.cycle`), see PrefabInstance.swift.

/// A prefab based on another: `base` plus `overrides`.
public struct PrefabVariant: Equatable, Sendable, Codable {
    public static let format = "sge-prefab-variant"
    public static let currentVersion = 1

    /// The prefab it is based on (a `.prefab` file, a model's prefab or another variant).
    public var base: AssetReference
    /// Its own changes to the base, by the base's prefab-local ids.
    public var overrides: [PrefabOverride]

    public init(base: AssetReference, overrides: [PrefabOverride] = []) {
        self.base = base
        self.overrides = overrides
    }

    private struct File: Codable {
        var format: String
        var version: Int
        var base: AssetReference
        var overrides: [PrefabOverride]
    }

    /// The file's contents.
    public func fileData() throws -> Data {
        try AssetJSON.encoder().encode(File(format: Self.format, version: Self.currentVersion, base: base, overrides: overrides))
    }

    /// Reads a variant file; nil when `data` isn't one (a scene file, say), an error when it is
    /// one that doesn't parse or is newer than this engine.
    public init?(fileData data: Data) throws {
        struct Header: Decodable { var format: String? }
        guard let header = try? AssetJSON.decoder().decode(Header.self, from: data), header.format == Self.format else { return nil }
        let file = try AssetJSON.decoder().decode(File.self, from: data)
        guard file.version <= Self.currentVersion else { throw AssetError.unreadable("written by a newer engine") }
        self.init(base: file.base, overrides: file.overrides)
    }
}

extension AssetDatabase {
    /// Writes a new variant file at `path` (relative to `Assets/`) based on `base`, with
    /// `overrides` (none: it starts as a copy of the base) and imports it.
    @discardableResult
    public func createPrefabVariant(of base: AssetReference, overrides: [PrefabOverride] = [], at path: String) throws -> AssetID {
        try createPrefab(PrefabVariant(base: base, overrides: overrides).fileData(), at: path)
    }
}

extension World {
    /// Applies a variant's overrides to a copy of its base (`root` and below, whose ids are the
    /// base's prefab-local ones).
    func applyVariantOverrides(_ overrides: [PrefabOverride], under root: Entity) {
        var byLocal: [String: Entity] = [:]
        for entity in subtreeOrder(root) { if let id = id(of: entity) { byLocal[id.description] = entity } }
        _ = applyOverrides(overrides, space: PrefabSpace(instance: self, entities: byLocal), entities: byLocal)
    }
}
