import Foundation

// Asset identity.
//
// Every file under a project's `Assets/` folder has an `AssetID`, stored in the sidecar next
// to it (`rock.obj.meta`, see AssetSidecar.swift). The id, not the path, is what scenes and
// other assets store, so references survive renaming and moving the file as long as its
// sidecar moves with it.
//
// One file can import to several objects (a .glb holds meshes, materials, textures and a node
// hierarchy). Each is a *sub-asset* with an id chosen by the importer, unique within the file
// and stable across reimports (see `SubAssetID`). An `AssetReference` names a file and,
// optionally, one of its sub-assets.
//
// ## Text form
//
// References are written as `asset:<32 hex digits>` or `asset:<32 hex digits>#<sub-asset id>`,
// e.g. `asset:5f1c0e9a8b7d4c3e2f1a0b9c8d7e6f50#mesh/Rock`. This is the string a `MeshHandle`
// or `MaterialHandle` holds when it names an asset, so handles still encode as one string and
// scene files keep their format: older files (built-in or code-registered keys) load unchanged,
// and files that use assets store ids, never paths. The `asset:` prefix is reserved: don't
// register code keys that start with it.

/// The stable identity of a file in a project's `Assets/` folder: 128 random bits, kept in
/// the file's sidecar. Written as 32 lowercase hex digits (a UUID without dashes).
public struct AssetID: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let high: UInt64
    public let low: UInt64

    public init(high: UInt64, low: UInt64) {
        self.high = high
        self.low = low
    }

    /// A new random id.
    public static func random() -> AssetID {
        var generator = SystemRandomNumberGenerator()
        return AssetID(high: generator.next(), low: generator.next())
    }

    /// Parses 32 hex digits, with or without UUID dashes (either case).
    public init?(_ string: String) {
        let hex = string.filter { $0 != "-" }
        guard hex.utf8.count == 32, hex.allSatisfy(\.isHexDigit),
              let high = UInt64(hex.prefix(16), radix: 16),
              let low = UInt64(hex.suffix(16), radix: 16) else { return nil }
        self.init(high: high, low: low)
    }

    /// 32 lowercase hex digits.
    public var description: String {
        let h = String(high, radix: 16), l = String(low, radix: 16)
        return String(repeating: "0", count: 16 - h.count) + h + String(repeating: "0", count: 16 - l.count) + l
    }

    public static func < (a: AssetID, b: AssetID) -> Bool { (a.high, a.low) < (b.high, b.low) }

    public init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let id = AssetID(string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad asset id '\(string)'"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// Identifies one object inside an imported file, e.g. `"mesh/Rock"`. Chosen by the importer:
/// unique within the file and stable across reimports, so references to it survive the
/// source being edited. The convention is `<kind>/<name>` with the object's name from the
/// source file, falling back to its index (`"mesh/2"`) when it has none, and `<name>~2`,
/// `~3`… for repeated names (`SubAssetNamer` does exactly this). Names keep references
/// valid when objects are added or reordered; indices only for unnamed objects.
public typealias SubAssetID = String

/// Names an asset (a file in `Assets/`) and optionally one object imported from it.
///
/// Without a sub-asset, a reference means the file's main object of the kind asked for:
/// `ImportedAsset.main` when it has that kind, else its first object of that kind (so a
/// `MeshHandle` naming an .obj file draws its first mesh).
public struct AssetReference: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public var asset: AssetID
    public var subAsset: SubAssetID?

    public init(_ asset: AssetID, subAsset: SubAssetID? = nil) {
        self.asset = asset
        self.subAsset = subAsset
    }

    /// The prefix of the text form (`asset:<id>[#<sub-asset>]`).
    public static let scheme = "asset:"

    /// Parses `asset:<id>` or `asset:<id>#<sub-asset>`; nil for anything else (such as a
    /// plain mesh key like "cube").
    public init?(_ string: String) {
        guard string.hasPrefix(Self.scheme) else { return nil }
        let rest = string.dropFirst(Self.scheme.count)
        let parts = rest.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        guard let id = AssetID(String(parts[0])) else { return nil }
        asset = id
        subAsset = parts.count > 1 && !parts[1].isEmpty ? String(parts[1]) : nil
    }

    /// The text form: `asset:<id>` or `asset:<id>#<sub-asset>`.
    public var description: String {
        Self.scheme + asset.description + (subAsset.map { "#\($0)" } ?? "")
    }

    public static func < (a: AssetReference, b: AssetReference) -> Bool {
        (a.asset, a.subAsset ?? "") < (b.asset, b.subAsset ?? "")
    }

    public init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let reference = AssetReference(string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad asset reference '\(string)'"))
        }
        self = reference
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// Makes sub-asset ids by the `SubAssetID` convention: `<kind>/<name>`, `<kind>/<index>` for
/// unnamed objects, and `<kind>/<name>~2`, `~3`… when a name repeats within a kind.
public struct SubAssetNamer: Sendable {
    private var taken: Set<String> = []

    public init() {}

    /// A fresh id for the `index`th object of `kind` (e.g. "mesh"), named `name` in the source.
    public mutating func id(kind: String, name: String?, index: Int) -> SubAssetID {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let base = "\(kind)/" + (trimmed.isEmpty ? "\(index)" : trimmed)
        var id = base
        var n = 2
        while taken.contains(id) {
            id = "\(base)~\(n)"
            n += 1
        }
        taken.insert(id)
        return id
    }
}

extension MeshHandle {
    /// A handle naming a mesh imported from a project asset (resolved through
    /// `SceneRenderer.assets`). It encodes as `asset:<id>[#<sub-asset>]`.
    public init(_ reference: AssetReference) { self.init(reference.description) }

    /// The asset this handle names, or nil for a plain key ("cube", a code-registered mesh).
    public var assetReference: AssetReference? { AssetReference(key) }
}

extension MaterialHandle {
    /// A handle naming a material imported from a project asset (resolved through
    /// `SceneRenderer.assets`). It encodes as `asset:<id>[#<sub-asset>]`.
    public init(_ reference: AssetReference) { self.init(reference.description) }

    /// The asset this handle names, or nil for a plain key ("default", a code-registered material).
    public var assetReference: AssetReference? { AssetReference(key) }
}

extension TextureHandle {
    /// A handle naming a project texture asset (resolved through `SceneRenderer.assets`). It
    /// encodes as `asset:<id>[#<sub-asset>]`.
    public init(_ reference: AssetReference) { self.init(reference.description) }

    /// The asset this handle names, or nil for a plain key (a code-registered texture).
    public var assetReference: AssetReference? { AssetReference(key) }
}
