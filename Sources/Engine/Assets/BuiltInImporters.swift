import Foundation

/// Imports Wavefront OBJ files: one mesh per object (`o` / `g`), plus a prefab with one node
/// per mesh. Polygons are triangulated as fans; missing normals are computed per face
/// (flat), missing UVs are zero. Materials (`mtllib` / `usemtl`) are ignored: nodes get the
/// default material.
///
/// Sub-asset ids: `mesh/<object name>` (`mesh/<index>` for unnamed geometry before the first
/// `o`), and `prefab/<file name without extension>`.
public struct OBJImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        /// Multiplies positions.
        public var scale: Float = 1
        /// Flips texture coordinates vertically (OBJ's v grows upward, image rows go down).
        public var flipV: Bool = true

        public init(scale: Float = 1, flipV: Bool = true) {
            self.scale = scale
            self.flipV = flipV
        }
    }

    public init() {}

    public var name: String { "obj" }
    public var fileExtensions: [String] { ["obj"] }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        guard let text = String(data: try context.data(), encoding: .utf8) else { throw AssetError.unreadable("not UTF-8 text") }
        let parsed = try Self.parse(text, settings: settings, warn: { context.warn($0) })
        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        var nodes: [PrefabNode] = []
        for (index, object) in parsed.enumerated() {
            let id = namer.id(kind: "mesh", name: object.name, index: index)
            asset.add(id, name: object.name ?? "Mesh \(index)", .mesh(object.geometry))
            nodes.append(PrefabNode(name: object.name ?? "Mesh \(index)", mesh: context.reference(id)))
        }
        guard !nodes.isEmpty else { throw AssetError.unreadable("no faces") }
        let base = (context.assetPath as NSString).lastPathComponent
        let stem = (base as NSString).deletingPathExtension
        let root = nodes.count == 1 ? nodes[0] : PrefabNode(name: stem, children: nodes)
        asset.add(namer.id(kind: "prefab", name: stem, index: 0), name: stem, .prefab(PrefabAsset(roots: [root])))
        return asset
    }

    struct Object {
        var name: String?
        var geometry: MeshGeometry
    }

    /// Parses OBJ text into objects with geometry (empty objects are dropped).
    static func parse(_ text: String, settings: Settings, warn: (String) -> Void) throws -> [Object] {
        var positions: [Vec3] = [], uvs: [Vec2] = [], normals: [Vec3] = []
        var objects: [Object] = []
        var current = Object(name: nil, geometry: MeshGeometry(vertices: [], indices: []))
        var dedup: [SIMD3<Int32>: UInt32] = [:]
        var skippedFaces = 0

        func finish() {
            if !current.geometry.indices.isEmpty { objects.append(current) }
            dedup.removeAll(keepingCapacity: true)
        }
        func floats(_ parts: ArraySlice<Substring>, count: Int, line: Int) throws -> [Float] {
            let values = parts.prefix(count).compactMap { Float($0) }
            guard values.count == count else { throw AssetError.unreadable("bad numbers on line \(line)") }
            return values
        }
        /// 0-based index from a 1-based or negative OBJ index; -1 when absent.
        func resolve(_ field: Substring?, count: Int) -> Int32? {
            guard let field, !field.isEmpty else { return -1 }
            guard let i = Int(field) else { return nil }
            let index = i > 0 ? i - 1 : count + i
            return index >= 0 && index < count ? Int32(index) : nil
        }

        for (lineIndex, rawLine) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let line = lineIndex + 1
            let parts = rawLine.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard let keyword = parts.first, !keyword.hasPrefix("#") else { continue }
            switch keyword {
            case "v":
                let v = try floats(parts.dropFirst(), count: 3, line: line)
                positions.append(Vec3(v[0], v[1], v[2]) * settings.scale)
            case "vt":
                let v = try floats(parts.dropFirst(), count: 2, line: line)
                uvs.append(Vec2(v[0], settings.flipV ? 1 - v[1] : v[1]))
            case "vn":
                let v = try floats(parts.dropFirst(), count: 3, line: line)
                normals.append(normalize(Vec3(v[0], v[1], v[2])))
            case "o", "g":
                let name = parts.dropFirst().joined(separator: " ")
                if current.geometry.indices.isEmpty {
                    current.name = name.isEmpty ? current.name : name
                } else {
                    finish()
                    current = Object(name: name.isEmpty ? nil : name, geometry: MeshGeometry(vertices: [], indices: []))
                }
            case "f":
                var corners: [SIMD3<Int32>] = []
                for field in parts.dropFirst() {
                    let refs = field.split(separator: "/", omittingEmptySubsequences: false)
                    guard let p = resolve(refs.first, count: positions.count), p >= 0,
                          let t = resolve(refs.count > 1 ? refs[1] : nil, count: uvs.count),
                          let n = resolve(refs.count > 2 ? refs[2] : nil, count: normals.count) else {
                        throw AssetError.unreadable("bad face index on line \(line)")
                    }
                    corners.append(SIMD3(p, t, n))
                }
                guard corners.count >= 3 else { skippedFaces += 1; continue }
                // Flat normal for corners without one.
                let a = positions[Int(corners[0].x)], b = positions[Int(corners[1].x)], c = positions[Int(corners[2].x)]
                let faceNormal = cross(b - a, c - a)
                let flat = length(faceNormal) > 0 ? normalize(faceNormal) : Vec3(0, 1, 0)
                var indices: [UInt32] = []
                for corner in corners {
                    if corner.z >= 0, let existing = dedup[corner] {
                        indices.append(existing)
                        continue
                    }
                    let index = UInt32(current.geometry.vertices.count)
                    current.geometry.vertices.append(MeshVertex(
                        position: positions[Int(corner.x)],
                        normal: corner.z >= 0 ? normals[Int(corner.z)] : flat,
                        uv: corner.y >= 0 ? uvs[Int(corner.y)] : .zero))
                    // Corners with computed normals aren't shared: the normal is per face.
                    if corner.z >= 0 { dedup[corner] = index }
                    indices.append(index)
                }
                for k in 1..<(indices.count - 1) { current.geometry.indices += [indices[0], indices[k], indices[k + 1]] }
            default:
                continue  // mtllib, usemtl, s, l, p…: not used
            }
        }
        finish()
        if skippedFaces > 0 { warn("skipped \(skippedFaces) faces with fewer than 3 corners") }
        return objects
    }
}

/// Imports `.material` files: a `MaterialAsset` as JSON (every key optional), e.g.
///
/// ```json
/// { "baseColor" : [0.8, 0.3, 0.2, 1], "texture" : "asset:5f1c…#texture", "specular" : 0.5 }
/// ```
///
/// One sub-asset, `material`.
public struct MaterialFileImporter: AssetImporter {
    public typealias Settings = NoImportSettings

    public init() {}

    public var name: String { "material" }
    public var fileExtensions: [String] { ["material"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let material = try AssetJSON.decoder().decode(MaterialAsset.self, from: context.data())
        var asset = ImportedAsset()
        asset.add("material", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .material(material))
        return asset
    }
}

/// Imports `.prefab` files: one entity subtree saved as a scene file (`World.save([root])`, the
/// same JSON as scenes), written by the editor's Create Prefab and Apply to Prefab
/// (`AssetDatabase.createPrefab`). One sub-asset, `prefab`, holding the file's data
/// (`PrefabAsset(scene:)`); the entities are decoded when it is instantiated, on the main actor.
/// Nested prefab instances inside it are resolved then too (see PrefabInstance.swift).
public struct PrefabFileImporter: AssetImporter {
    public typealias Settings = NoImportSettings

    public init() {}

    public var name: String { "prefab" }
    public var fileExtensions: [String] { ["prefab"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let data = try context.data()
        if let variant = try PrefabVariant(fileData: data) {
            var asset = ImportedAsset()
            asset.add("prefab", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                      .prefab(PrefabAsset(variant: variant)))
            return asset
        }
        // Only the header is checked here: components need the registry (main actor).
        struct Header: Decodable {
            var format: String
            var version: Int
            var entities: [Entity]
            struct Entity: Decodable {}
        }
        guard let header = try? AssetJSON.decoder().decode(Header.self, from: data), FileFormat.matches(header.format, SceneFile.format) else {
            throw AssetError.unreadable("not a prefab (scene file)")
        }
        guard header.version <= SceneFile.currentVersion else { throw AssetError.unreadable("written by a newer engine") }
        guard !header.entities.isEmpty else { throw AssetError.unreadable("the prefab has no entities") }
        var asset = ImportedAsset()
        asset.add("prefab", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .prefab(PrefabAsset(scene: data)))
        return asset
    }
}
