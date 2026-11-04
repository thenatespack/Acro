import Foundation

// Asset packs: what a shipping build loads instead of a project. `AssetCooker` writes one from
// a project (every asset reachable from the chosen scenes, imported with shipping settings);
// `AssetDatabase(mounting:)` resolves asset ids from it read-only, with no importers and no
// source files.
//
// One file, little-endian:
//
// ```
// 0    "SGEPACK\0"                       magic
// 8    UInt32 version (1)
// 12   UInt32 alignment (64)             every blob starts at a multiple of it
// 16   UInt64 table of contents offset
// 24   UInt64 table of contents size
// 32   16 ASCII hex digits               ContentHash of the table of contents
// 48   zeros up to 64
// 64   blobs, each aligned               mesh / texture bytes exactly as Library/Artifacts stores them,
//                                        scene files, raw files (audio)
// ...  table of contents (JSON, sorted keys): `AssetPackManifest`
// ```
//
// The table of contents is the manifest: per asset its id, path (informational), importer,
// objects (kinds, names, mesh / texture layout, materials and prefabs inline) and for each
// binary file its blob (offset, size, ContentHash); the scenes, the start scene first. Blobs
// with the same bytes are stored once. A pack is written in one go and only read afterwards;
// nothing in it depends on time or on the machine, so the same inputs give the same bytes.

/// Errors from reading packs.
public enum AssetPackError: Error, Equatable, CustomStringConvertible {
    /// The file isn't a pack (no magic).
    case notAPack(String)
    /// The pack was written by a newer engine.
    case unsupportedVersion(Int)
    /// A blob or the table of contents doesn't match its hash or lies outside the file.
    case damaged(String)
    /// The pack was cooked for another vertex layout (`MeshVertex`).
    case incompatible(String)
    /// The pack has no asset with this id (it wasn't reachable from the cooked scenes, or doesn't exist).
    case unknownAsset(AssetID, pack: String)
    /// The asset is in the pack, but holds no objects of its own (audio, other files): use `data(of:)`.
    case noObjects(AssetID, pack: String)
    /// No scene with this path in the pack.
    case unknownScene(String, pack: String, available: [String])

    public var description: String {
        switch self {
        case .notAPack(let path): "\(path) is not an asset pack"
        case .unsupportedVersion(let v): "Asset pack version \(v) is newer than this engine reads (\(AssetPackManifest.currentVersion))"
        case .damaged(let what): "Damaged asset pack: \(what)"
        case .incompatible(let what): "Incompatible asset pack: \(what)"
        case .unknownAsset(let id, let pack):
            "Asset \(id) is not in \(pack): it wasn't reachable from the cooked scenes (cook it with --include) or doesn't exist"
        case .noObjects(let id, let pack): "Asset \(id) in \(pack) has no imported objects (read its bytes with data(of:))"
        case .unknownScene(let path, let pack, let available):
            "No scene '\(path)' in \(pack) (it has: \(available.isEmpty ? "none" : available.joined(separator: ", ")))"
        }
    }
}

/// The platform a pack is cooked for.
public enum CookPlatform: String, Codable, Sendable, CaseIterable {
    case macos, linux, windows

    /// The platform this program runs on.
    public static var current: CookPlatform {
        #if os(macOS)
        .macos
        #elseif os(Windows)
        .windows
        #else
        .linux
        #endif
    }

    /// What menus show: "macOS", "Linux", "Windows".
    public var title: String {
        switch self {
        case .macos: "macOS"
        case .linux: "Linux"
        case .windows: "Windows"
        }
    }

    /// The texture family its GPUs are best served by: ASTC on macOS (Apple silicon), BC elsewhere.
    public var defaultTextureFamily: TextureFamily { self == .macos ? .astc : .bc }
}

/// Which block-compressed formats textures are cooked to.
public enum TextureFamily: String, Codable, Sendable, CaseIterable {
    /// BC7 (BC5 for normal maps): desktop GPUs (Windows, Linux, Intel and Apple silicon Macs).
    case bc
    /// ASTC 4x4 (two-channel ASTC for normal maps): Apple silicon, mobile.
    case astc

    /// What `TextureCompression.auto` resolves to on this machine.
    public static var machine: TextureFamily { TextureCodec.autoFormat(srgb: true) == .bc7Srgb ? .bc : .astc }
}

/// Where one blob lies in a pack.
public struct AssetPackBlob: Codable, Equatable, Hashable, Sendable {
    public var offset: UInt64
    public var size: UInt64
    /// `ContentHash` of the bytes (16 hex digits).
    public var hash: String
}

/// A pack's table of contents (see the notes at the top of this file).
public struct AssetPackManifest: Codable, Sendable {
    public static let format = "SwiftGameEngine.AssetPack"
    public static let currentVersion = 1

    public var format = AssetPackManifest.format
    public var version = AssetPackManifest.currentVersion
    /// The project's name.
    public var name: String
    public var platform: CookPlatform
    public var textureFamily: TextureFamily
    /// `MemoryLayout<MeshVertex>.stride` of the engine that cooked it.
    public var vertexStride: Int
    /// The scenes, the start scene first.
    public var scenes: [Scene]
    /// Every asset, sorted by id.
    public var assets: [Asset]
    /// The project's runtime settings (window, physics) when it has any; `GamePlayer` applies them.
    public var runtime: ProjectRuntimeSettings? = nil

    public struct Scene: Codable, Equatable, Sendable {
        /// The scene's path relative to `Assets/` (or its file name when it was outside).
        public var path: String
        public var blob: AssetPackBlob
    }

    public struct Asset: Codable, Sendable {
        public var id: AssetID
        /// Its path in the project, relative to `Assets/` (for messages; nothing reads the file).
        public var path: String
        /// The importer that made it; nil for files without one.
        public var importer: String?
        /// The import settings it was cooked with (the shipping settings), for code that reads
        /// them at run time (`AssetDatabase.settings(of:)`, e.g. audio's `stream`).
        public var settings: JSONValue?
        /// The object a reference without a sub-asset means (`ImportedAsset.main`).
        var main: SubAssetID?
        /// The objects, as `Library/Artifacts/<id>/import.json` lists them.
        var objects: [AssetArtifacts.Object]
        /// Their binary files ("mesh-0.bin", "texture-1.bin") by name.
        var files: [String: AssetPackBlob]
        /// The file's own bytes, for assets used as they are (audio, files without an importer).
        public var data: AssetPackBlob?

        /// The objects, as the database lists them.
        public var objectInfos: [AssetObjectInfo] { objects.map { AssetObjectInfo(id: $0.id, name: $0.name, kind: $0.kind) } }
        /// Bytes of its blobs.
        public var byteCount: UInt64 { files.values.reduce(data?.size ?? 0) { $0 + $1.size } }
    }

    /// The start scene's path.
    public var startScene: String? { scenes.first?.path }
}

/// Byte layout constants and the writer.
enum AssetPackFormat {
    static let magic = Array("SGEPACK\0".utf8)
    static let headerSize = 64
    static let alignment = 64

    /// Assembles a pack: blobs appended (deduplicated, aligned), then the table of contents.
    final class Writer {
        private(set) var body = Data()
        private var blobs: [String: AssetPackBlob] = [:]

        init() {
            body.append(Data(count: headerSize))
        }

        /// Appends `bytes` (or finds identical bytes already appended).
        func add(_ bytes: Data) -> AssetPackBlob {
            let hash = ContentHash.hex(bytes)
            let key = "\(hash):\(bytes.count)"
            if let blob = blobs[key] { return blob }
            pad()
            let blob = AssetPackBlob(offset: UInt64(body.count), size: UInt64(bytes.count), hash: hash)
            body.append(bytes)
            blobs[key] = blob
            return blob
        }

        private func pad() {
            let rest = body.count % alignment
            if rest != 0 { body.append(Data(count: alignment - rest)) }
        }

        /// The finished file: header, blobs, table of contents.
        func finish(_ manifest: AssetPackManifest) throws -> Data {
            pad()
            let toc = try AssetJSON.encode(manifest)
            let tocOffset = UInt64(body.count)
            body.append(toc)
            var header = Data(magic)
            withUnsafeBytes(of: UInt32(AssetPackManifest.currentVersion).littleEndian) { header.append(contentsOf: $0) }
            withUnsafeBytes(of: UInt32(alignment).littleEndian) { header.append(contentsOf: $0) }
            withUnsafeBytes(of: tocOffset.littleEndian) { header.append(contentsOf: $0) }
            withUnsafeBytes(of: UInt64(toc.count).littleEndian) { header.append(contentsOf: $0) }
            header.append(Data(ContentHash.hex(toc).utf8))
            header.append(Data(count: headerSize - header.count))
            body.replaceSubrange(0..<headerSize, with: header)
            return body
        }
    }
}

/// A pack opened for reading (memory-mapped). Thread-safe: it never changes after `open`.
public final class AssetPack: Sendable {
    public let url: URL
    public let manifest: AssetPackManifest
    /// Whether blob reads check their hash (default true: a damaged file fails clearly
    /// instead of drawing garbage; hashing runs at several GB/s).
    public let verifiesBlobs: Bool
    private let bytes: Data
    private let assetsByID: [AssetID: Int]

    /// Opens and checks the pack at `url`: magic, version, table of contents (hash and
    /// layout), the vertex layout it was cooked for.
    public init(url: URL, verifiesBlobs: Bool = true) throws {
        self.url = url
        self.verifiesBlobs = verifiesBlobs
        let data: Data
        do {
            data = try Data(contentsOf: url, options: .alwaysMapped)
        } catch {
            throw AssetPackError.notAPack("\(url.path) (\(error.localizedDescription))")
        }
        guard data.count >= AssetPackFormat.headerSize, Array(data.prefix(8)) == AssetPackFormat.magic else {
            throw AssetPackError.notAPack(url.path)
        }
        func integer<T: FixedWidthInteger>(_ offset: Int, _: T.Type) -> T {
            data.withUnsafeBytes { T(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: T.self)) }
        }
        let version = Int(integer(8, UInt32.self))
        guard version <= AssetPackManifest.currentVersion else { throw AssetPackError.unsupportedVersion(version) }
        let tocOffset = integer(16, UInt64.self), tocSize = integer(24, UInt64.self)
        guard tocOffset <= UInt64(data.count), tocSize <= UInt64(data.count) - tocOffset else {
            throw AssetPackError.damaged("the table of contents lies outside the file")
        }
        let toc = data.subdata(in: Int(tocOffset)..<Int(tocOffset + tocSize))
        guard String(decoding: data.subdata(in: 32..<48), as: UTF8.self) == ContentHash.hex(toc) else {
            throw AssetPackError.damaged("the table of contents doesn't match its hash")
        }
        let manifest: AssetPackManifest
        do {
            manifest = try AssetJSON.decoder().decode(AssetPackManifest.self, from: toc)
        } catch {
            throw AssetPackError.damaged("unreadable table of contents: \(error)")
        }
        guard manifest.format == AssetPackManifest.format else { throw AssetPackError.notAPack(url.path) }
        guard manifest.vertexStride == MemoryLayout<MeshVertex>.stride else {
            throw AssetPackError.incompatible("cooked for \(manifest.vertexStride)-byte vertices; this engine uses \(MemoryLayout<MeshVertex>.stride)")
        }
        self.manifest = manifest
        bytes = data
        assetsByID = Dictionary(manifest.assets.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The pack's file name, for messages.
    public var name: String { url.lastPathComponent }

    /// The entry for `id`, if the pack has it.
    public func entry(_ id: AssetID) -> AssetPackManifest.Asset? { assetsByID[id].map { manifest.assets[$0] } }

    /// Whether the pack has `id`.
    public func contains(_ id: AssetID) -> Bool { assetsByID[id] != nil }

    /// A blob's bytes (copied), checked against its hash when `verifiesBlobs`.
    public func bytes(of blob: AssetPackBlob) throws -> Data {
        guard blob.offset <= UInt64(bytes.count), blob.size <= UInt64(bytes.count) - blob.offset else {
            throw AssetPackError.damaged("a blob lies outside the file")
        }
        let data = bytes.subdata(in: Int(blob.offset)..<Int(blob.offset + blob.size))
        if verifiesBlobs, ContentHash.hex(data) != blob.hash {
            throw AssetPackError.damaged("a blob at offset \(blob.offset) doesn't match its hash")
        }
        return data
    }

    /// The imported objects of `id`, as the asset database would have them.
    public func asset(_ id: AssetID) throws -> ImportedAsset {
        guard let entry = entry(id) else { throw AssetPackError.unknownAsset(id, pack: name) }
        if entry.objects.isEmpty, entry.data != nil { throw AssetPackError.noObjects(id, pack: name) }
        var failure: (any Error)?
        let manifest = AssetArtifacts.Manifest(main: entry.main, objects: entry.objects)
        let asset = AssetArtifacts.decode(manifest) { file in
            guard let blob = entry.files[file] else { return nil }
            do { return try bytes(of: blob) } catch { failure = error; return nil }
        }
        if let failure { throw failure }
        guard let asset else { throw AssetPackError.damaged("asset \(id) (\(entry.path)) doesn't match its table of contents entry") }
        return asset
    }

    /// The file bytes stored for `id` (audio, files without an importer).
    public func data(of id: AssetID) throws -> Data {
        guard let entry = entry(id) else { throw AssetPackError.unknownAsset(id, pack: name) }
        guard let blob = entry.data else { throw AssetPackError.unknownAsset(id, pack: name) }
        return try bytes(of: blob)
    }

    /// The scene file at `path` (relative to `Assets/`; a leading `Assets/` is allowed), or the start scene.
    public func scene(_ path: String? = nil) throws -> Data {
        let scenes = manifest.scenes
        // `path` may also be project-root relative ("Assets/Scenes/X.scene").
        let relative = path.map { $0.hasPrefix("Assets/") ? String($0.dropFirst("Assets/".count)) : $0 }
        guard let scene = relative.map({ p in scenes.first { $0.path == p || ($0.path as NSString).lastPathComponent == p } }) ?? scenes.first else {
            throw AssetPackError.unknownScene(path ?? "(start scene)", pack: name, available: scenes.map(\.path))
        }
        return try bytes(of: scene.blob)
    }
}
