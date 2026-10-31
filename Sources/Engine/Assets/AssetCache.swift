import Foundation

// The import cache in `Library/`:
//
// ```
// Library/
//   AssetDatabase.json            index: per asset id its path, importer + version, source hash,
//                                 size, mtime, settings and object list (decides what to reimport)
//   Artifacts/<id>/import.json    the imported objects: materials and prefabs inline, meshes and
//                                 textures in binary files next to it (mesh-N.bin, texture-N.bin)
//   Artifacts/<id>/files/         the importer's own artifacts (ImportContext.artifactsDirectory)
// ```
//
// Everything in `Library/` can be deleted; it is rebuilt by importing again. Binary files are
// raw little-endian memory (vertex stride recorded, checked on load), so a cache made on another
// architecture is simply rebuilt.

/// The Library index (`Library/AssetDatabase.json`).
struct LibraryIndex: Codable {
    static let currentVersion = 1
    var version = LibraryIndex.currentVersion
    var assets: [String: Entry] = [:]

    struct Entry: Codable, Equatable {
        var path: String
        var importer: String?
        var importerVersion: Int
        var sourceHash: String
        var size: Int64
        var modified: Double
        /// Canonical JSON of the effective settings.
        var settings: String
        var objects: [AssetObjectInfo]
        /// The last import failed with this message (and `objects` are from the import before).
        var error: String?
    }

    static func load(from url: URL) -> LibraryIndex {
        guard let data = FileManager.default.contents(atPath: url.path),
              let index = try? AssetJSON.decoder().decode(LibraryIndex.self, from: data),
              index.version == currentVersion else { return LibraryIndex() }
        return index
    }

    func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try AssetJSON.encode(self).write(to: url, options: .atomic)
    }
}

/// One imported object as the database lists it (without its data).
public struct AssetObjectInfo: Equatable, Sendable, Codable {
    public var id: SubAssetID
    public var name: String
    public var kind: AssetKind

    public init(id: SubAssetID, name: String, kind: AssetKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}

/// Reads and writes `Library/Artifacts/<id>/import.json` and its binary files.
enum AssetArtifacts {
    static let manifestName = "import.json"

    struct Manifest: Codable {
        static let currentVersion = 1
        var version = Manifest.currentVersion
        var vertexStride = MemoryLayout<MeshVertex>.stride
        var main: SubAssetID?
        var objects: [Object]
    }

    struct Object: Codable {
        var id: SubAssetID
        var name: String
        var kind: AssetKind
        var file: String?
        var vertexCount: Int?
        var indexCount: Int?
        var width: Int?
        var height: Int?
        var srgb: Bool?
        var mipmaps: Bool?
        var material: MaterialAsset?
        var prefab: PrefabAsset?
    }

    static func write(_ asset: ImportedAsset, to directory: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        var objects: [Object] = []
        for (n, object) in asset.objects.enumerated() {
            var entry = Object(id: object.id, name: object.name, kind: object.kind)
            switch object.value {
            case .mesh(let geometry):
                let file = "mesh-\(n).bin"
                var data = Data()
                geometry.vertices.withUnsafeBytes { data.append(contentsOf: $0) }
                geometry.indices.withUnsafeBytes { data.append(contentsOf: $0) }
                try data.write(to: directory.appendingPathComponent(file))
                entry.file = file
                entry.vertexCount = geometry.vertices.count
                entry.indexCount = geometry.indices.count
            case .texture(let texture):
                let file = "texture-\(n).bin"
                try Data(texture.image.pixels).write(to: directory.appendingPathComponent(file))
                entry.file = file
                entry.width = texture.image.width
                entry.height = texture.image.height
                entry.srgb = texture.isSRGB
                entry.mipmaps = texture.generatesMipmaps
            case .material(let material):
                entry.material = material
            case .prefab(let prefab):
                entry.prefab = prefab
            }
            objects.append(entry)
        }
        try AssetJSON.encode(Manifest(main: asset.main, objects: objects))
            .write(to: directory.appendingPathComponent(manifestName), options: .atomic)
    }

    /// The cached import, or nil if it is missing, from another format version or damaged.
    static func read(from directory: URL) -> ImportedAsset? {
        guard let data = FileManager.default.contents(atPath: directory.appendingPathComponent(manifestName).path),
              let manifest = try? AssetJSON.decoder().decode(Manifest.self, from: data),
              manifest.version == Manifest.currentVersion, manifest.vertexStride == MemoryLayout<MeshVertex>.stride else { return nil }
        var asset = ImportedAsset(main: manifest.main)
        for entry in manifest.objects {
            let value: AssetObject
            switch entry.kind {
            case .mesh:
                guard let file = entry.file, let vertexCount = entry.vertexCount, let indexCount = entry.indexCount,
                      let bytes = FileManager.default.contents(atPath: directory.appendingPathComponent(file).path) else { return nil }
                let vertexBytes = vertexCount * MemoryLayout<MeshVertex>.stride
                guard bytes.count == vertexBytes + indexCount * 4 else { return nil }
                var vertices = [MeshVertex](repeating: MeshVertex(position: .zero, normal: .zero), count: vertexCount)
                var indices = [UInt32](repeating: 0, count: indexCount)
                bytes.withUnsafeBytes { raw in
                    vertices.withUnsafeMutableBytes { $0.copyMemory(from: UnsafeRawBufferPointer(rebasing: raw[0..<vertexBytes])) }
                    indices.withUnsafeMutableBytes { $0.copyMemory(from: UnsafeRawBufferPointer(rebasing: raw[vertexBytes...])) }
                }
                value = .mesh(MeshGeometry(vertices: vertices, indices: indices))
            case .texture:
                guard let file = entry.file, let width = entry.width, let height = entry.height,
                      let bytes = FileManager.default.contents(atPath: directory.appendingPathComponent(file).path),
                      bytes.count == width * height * 4 else { return nil }
                value = .texture(TextureAsset(image: Image(width: width, height: height, pixels: [UInt8](bytes)),
                                              isSRGB: entry.srgb ?? true, generatesMipmaps: entry.mipmaps ?? true))
            case .material:
                guard let material = entry.material else { return nil }
                value = .material(material)
            case .prefab:
                guard let prefab = entry.prefab else { return nil }
                value = .prefab(prefab)
            }
            asset.objects.append(ImportedObject(id: entry.id, name: entry.name, value: value))
        }
        return asset
    }
}

/// A fast non-cryptographic 64-bit hash of file contents, as 16 hex digits (decides whether a
/// source changed; not for security).
enum ContentHash {
    static func hex(_ data: Data) -> String {
        var h: UInt64 = 0x9E37_79B9_7F4A_7C15 ^ UInt64(data.count)
        data.withUnsafeBytes { raw in
            let words = raw.count / 8
            for i in 0..<words {
                let w = UInt64(littleEndian: raw.loadUnaligned(fromByteOffset: i * 8, as: UInt64.self))
                h = mix(h ^ w)
            }
            var tail: UInt64 = 0
            for i in (words * 8)..<raw.count { tail = tail << 8 | UInt64(raw[i]) }
            h = mix(h ^ tail)
        }
        let s = String(h, radix: 16)
        return String(repeating: "0", count: 16 - s.count) + s
    }

    @inline(__always) private static func mix(_ x: UInt64) -> UInt64 {
        var z = x &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 31)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 29)
    }

    static func hex(contentsOf url: URL) throws -> String {
        try hex(Data(contentsOf: url, options: .mappedIfSafe))
    }
}
