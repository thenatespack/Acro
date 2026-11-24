#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

/// Imports `.gridmap` files (a `GridMap` as JSON) as the main `prefab/<file name>`: a root named
/// after the file, a "Floor <y>" node per floor and under it a "Chunk <x>_<z>" node per chunk
/// holding the chunk's pieces and, with `collider`, one triangle-mesh `Collider` merging their
/// collision. Each placed piece is a node named "<piece> <x>,<y>,<z>" that references the
/// piece's own meshes and materials, so equal pieces draw as one instanced batch.
///
/// Pieces come from `.meshbuild` files, models (`.gltf`, `.glb`, `.obj`), `.prefab` scene files
/// or mesh references. The importer runs the piece file's own importer to learn its node tree
/// and triangles (recording the file as a dependency, so the map reimports when a piece
/// changes). Mirrored pieces get mirrored copies of their meshes as sub-assets
/// ("mesh/<piece> mirrored"). Built-in primitives used by `.prefab` pieces ("cube"...) become
/// meshes of the map ("mesh/builtin <key>"); prefab variants are resolved by
/// GridMapPieceVariants.swift.
public struct GridMapImporter: AssetImporter {
    public init() {}

    public var name: String { BuiltInImporterName.gridMap }
    public var fileExtensions: [String] { ["gridmap"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let map: GridMap
        do { map = try AssetJSON.decoder().decode(GridMap.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a grid map: \(error)")
        }
        let stem = context.assetPath.pathLastComponent.pathDeletingExtension
        var asset = ImportedAsset()
        var warnings: [String] = []
        var placements = map.placements(warnings: &warnings)
        if placements.count > GridMap.maxCells {
            warnings.append("more than \(GridMap.maxCells) cells; the rest are dropped")
            placements = Array(placements.prefix(GridMap.maxCells))
        }

        let loader = PieceLoader(context)
        defer { loader.cleanUp() }
        var builder = Builder(asset: asset, loader: loader, assetID: context.assetID)
        var prototypes: [Int: Prototype?] = [:]
        struct ChunkKey: Hashable, Comparable {
            var y: Int, x: Int, z: Int
            static func < (a: ChunkKey, b: ChunkKey) -> Bool { (a.y, a.z, a.x) < (b.y, b.z, b.x) }
        }
        var nodes: [ChunkKey: [PrefabNode]] = [:]
        var triangles: [ChunkKey: (vertices: [Vec3], indices: [UInt32])] = [:]

        for placement in placements {
            let index = placement.piece
            if prototypes[index] == nil {
                prototypes[index] = .some(Self.prototype(map.pieces[index], loader: loader, warnings: &warnings))
            }
            guard let prototype = prototypes[index] ?? nil else { continue }
            let piece = map.pieces[index]
            let cell = placement.cell
            let name = "\(piece.name) \(cell.at.x),\(cell.at.y),\(cell.at.z)"
            let node = builder.node(name: name, transform: map.transform(of: placement), prototype: prototype, mirrored: placement.mirrored,
                                    pieceName: piece.name, uniformScale: piece.scale.x == piece.scale.y && piece.scale.y == piece.scale.z)
            let chunk = map.chunk(of: cell.at)
            let key = ChunkKey(y: cell.at.y, x: chunk.x, z: chunk.y)
            nodes[key, default: []].append(node)

            guard map.collider, piece.collider != .none else { continue }
            var mesh = triangles[key] ?? ([], [])
            var added = false
            if piece.collider != .box {
                added = builder.appendTriangles(of: node, parent: .identity, into: &mesh)
                if !added && piece.collider == .mesh, builder.warnedNoTriangles.insert(piece.name).inserted {
                    warnings.append("piece '\(piece.name)': its triangles can't be read for a mesh collider")
                }
            }
            if !added && piece.collider != .mesh {
                let box = map.box(of: placement)
                Self.appendBox(center: box.center, halfExtent: box.halfExtent, rotation: box.rotation, into: &mesh)
            }
            triangles[key] = mesh
        }
        warnings += builder.warnings
        asset = builder.asset
        for (id, name, geometry) in loader.builtinMeshes { asset.add(id, name: name, .mesh(geometry)) }

        var floors: [Int: [PrefabNode]] = [:]
        for key in nodes.keys.sorted() {
            var collider: ColliderShape?
            if let mesh = triangles[key], !mesh.indices.isEmpty { collider = .triangleMesh(vertices: mesh.vertices, indices: mesh.indices) }
            floors[key.y, default: []].append(PrefabNode(name: "Chunk \(key.x)_\(key.z)", children: nodes[key] ?? [], collider: collider))
        }
        let children = floors.keys.sorted().map { PrefabNode(name: "Floor \($0)", children: floors[$0] ?? []) }
        var namer = SubAssetNamer()
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: children)])))
        asset.main = prefab
        for warning in warnings { context.warn(warning) }
        return asset
    }

    // MARK: Pieces

    /// A piece's model: its node tree in model space (meshes and materials are references).
    struct Prototype {
        var roots: [PrefabNode]
        /// The one mesh when the whole model is a single mesh with no transform of its own.
        var single: (mesh: AssetReference, material: AssetReference?, transform: Transform)?
    }

    static func prototype(_ piece: GridPiece, loader: PieceLoader, warnings: inout [String]) -> Prototype? {
        let value = piece.asset.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else {
            warnings.append("piece '\(piece.name)' has no asset")
            return nil
        }
        var roots: [PrefabNode]
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            let mesh = reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "mesh") : reference
            roots = [PrefabNode(name: piece.name, mesh: mesh, material: loader.materialReference(piece.material, warnings: &warnings))]
        } else {
            let path = PieceLoader.normalized(value)
            guard let id = loader.id(forPath: path) else {
                warnings.append("piece '\(piece.name)': no asset '\(value)'")
                return nil
            }
            if path.lowercased().hasSuffix(".gridmap") {
                warnings.append("piece '\(piece.name)': a grid map can't be a piece")
                return nil
            }
            guard let imported = loader.imported(id) else {
                warnings.append("piece '\(piece.name)': '\(value)' can't be imported")
                return nil
            }
            if let prefab = imported.object(nil, kind: .prefab), case .prefab(let p) = prefab.value {
                if p.scene != nil || p.variant != nil {
                    // A scene file, or a variant resolved to one (its base plus its overrides).
                    guard let scene = loader.sceneData(of: p) else {
                        warnings.append("piece '\(piece.name)': the variant '\(value)' can't be resolved (its base prefab is missing or unreadable)")
                        return nil
                    }
                    roots = PieceLoader.sceneNodes(scene, builtin: loader.builtinMesh)
                } else {
                    roots = p.roots
                }
            } else if let mesh = imported.object(nil, kind: .mesh) {
                roots = [PrefabNode(name: piece.name, mesh: AssetReference(id, subAsset: mesh.id),
                                    material: imported.object(nil, kind: .material).map { AssetReference(id, subAsset: $0.id) })]
            } else {
                warnings.append("piece '\(piece.name)': '\(value)' isn't a model, mesh build or prefab")
                return nil
            }
        }
        if !hasMesh(roots) {
            warnings.append("piece '\(piece.name)': '\(value)' has nothing to draw")
            return nil
        }
        var prototype = Prototype(roots: roots)
        // A lone mesh (possibly under empty identity parents, as mesh builds make) draws on the cell node itself.
        var chain = roots
        var transform = Transform()
        while chain.count == 1, isPlain(chain[0]) {
            let node = chain[0]
            transform = Transform(matrix: transform.matrix * node.transform.matrix)
            if let mesh = node.mesh {
                if node.children.isEmpty { prototype.single = (mesh, node.material, transform) }
                break
            }
            chain = node.children
        }
        return prototype
    }

    private static func isPlain(_ node: PrefabNode) -> Bool {
        node.animator == nil && node.particles == nil && node.skin == nil && node.collider == nil && node.postFX == nil
    }

    private static func hasMesh(_ nodes: [PrefabNode]) -> Bool {
        nodes.contains { $0.mesh != nil || hasMesh($0.children) }
    }

    /// Builds the placed nodes, mirrored meshes and collision triangles.
    struct Builder {
        var asset: ImportedAsset
        let loader: PieceLoader
        let assetID: AssetID
        var namer = SubAssetNamer()
        var mirroredMeshes: [AssetReference: AssetReference] = [:]
        var localGeometry: [SubAssetID: MeshGeometry] = [:]
        var warnings: [String] = []
        var warnedNoMirror = Set<String>()
        var warnedNoTriangles = Set<String>()

        init(asset: ImportedAsset, loader: PieceLoader, assetID: AssetID) {
            self.asset = asset
            self.loader = loader
            self.assetID = assetID
        }

        mutating func node(name: String, transform: Transform, prototype: Prototype, mirrored: Bool, pieceName: String,
                           uniformScale: Bool) -> PrefabNode {
            if let single = prototype.single, uniformScale || single.transform.rotation == .identity {
                var local = single.transform
                var mesh = single.mesh
                if mirrored {
                    local = Self.mirror(local)
                    mesh = mirroredMesh(mesh, pieceName: pieceName)
                }
                let composed = Transform(matrix: transform.matrix * local.matrix)
                return PrefabNode(name: name, transform: composed, mesh: mesh, material: single.material)
            }
            let children = mirrored ? prototype.roots.map { mirror($0, pieceName: pieceName) } : prototype.roots
            return PrefabNode(name: name, transform: transform, children: children)
        }

        /// `node` mirrored across its parent's x axis (M·T·M for each transform, mirrored meshes).
        mutating func mirror(_ node: PrefabNode, pieceName: String) -> PrefabNode {
            var out = node
            out.transform = Self.mirror(node.transform)
            if let mesh = node.mesh { out.mesh = mirroredMesh(mesh, pieceName: pieceName) }
            if var animator = node.animator {
                animator.tracks = animator.tracks.map(GridMapImporter.mirrored)
                out.animator = animator
            }
            out.children = node.children.map { mirror($0, pieceName: pieceName) }
            return out
        }

        static func mirror(_ t: Transform) -> Transform {
            Transform(position: Vec3(-t.position.x, t.position.y, t.position.z),
                      rotation: Quat(t.rotation.x, -t.rotation.y, -t.rotation.z, t.rotation.w), scale: t.scale)
        }

        /// A mirrored copy of `mesh` in this asset (made once per mesh).
        mutating func mirroredMesh(_ mesh: AssetReference, pieceName: String) -> AssetReference {
            if let done = mirroredMeshes[mesh] { return done }
            guard let geometry = loader.geometry(mesh) else {
                if warnedNoMirror.insert(pieceName).inserted { warnings.append("piece '\(pieceName)': its meshes can't be read, so flips are ignored") }
                return mesh
            }
            let id = namer.id(kind: "mesh", name: "\(pieceName) mirrored", index: mirroredMeshes.count)
            let flipped = GridMapImporter.mirrored(geometry)
            asset.add(id, name: "\(pieceName) mirrored", .mesh(flipped))
            localGeometry[id] = flipped
            let reference = AssetReference(assetID, subAsset: id)
            mirroredMeshes[mesh] = reference
            return reference
        }

        func geometry(_ mesh: AssetReference) -> MeshGeometry? {
            if mesh.asset == assetID, let sub = mesh.subAsset, let local = localGeometry[sub] { return local }
            return loader.geometry(mesh)
        }

        /// Appends the triangles of `node`'s meshes (placed by `parent`); false if none could be read.
        func appendTriangles(of node: PrefabNode, parent: Mat4, into mesh: inout (vertices: [Vec3], indices: [UInt32])) -> Bool {
            let matrix = parent * node.transform.matrix
            var any = false
            if let reference = node.mesh, let geometry = geometry(reference), !geometry.indices.isEmpty {
                let base = UInt32(mesh.vertices.count)
                for v in geometry.vertices {
                    let p = matrix * Vec4(v.position, 1)
                    mesh.vertices.append(Vec3(p.x, p.y, p.z))
                }
                let c0 = Vec3(matrix.c0.x, matrix.c0.y, matrix.c0.z), c1 = Vec3(matrix.c1.x, matrix.c1.y, matrix.c1.z)
                let c2 = Vec3(matrix.c2.x, matrix.c2.y, matrix.c2.z)
                let flips = dot(cross(c0, c1), c2) < 0
                var i = 0
                while i + 2 < geometry.indices.count {
                    let a = geometry.indices[i], b = geometry.indices[i + 1], c = geometry.indices[i + 2]
                    mesh.indices += flips ? [base + a, base + c, base + b] : [base + a, base + b, base + c]
                    i += 3
                }
                any = true
            }
            for child in node.children where appendTriangles(of: child, parent: matrix, into: &mesh) { any = true }
            return any
        }
    }

    /// A transform animation track of a node mirrored across its parent's x axis: moving along x
    /// and turning about y or z go the other way (M·T·M again); other tracks are unchanged.
    static func mirrored(_ track: AnimationTrack) -> AnimationTrack {
        guard ["Transform.position.x", "Transform.rotation.y", "Transform.rotation.z"].contains(track.target) else { return track }
        var out = track
        out.from = -track.from
        out.to = -track.to
        out.amplitude = -track.amplitude
        out.offset = -track.offset
        out.curve = AnimationCurve(keys: track.curve.keys.map { key in
            var key = key
            key.value = -key.value
            key.inTangent = key.inTangent.map { -$0 }
            key.outTangent = key.outTangent.map { -$0 }
            return key
        }, wrap: track.curve.wrap)
        return out
    }

    /// `geometry` mirrored across x: positions, normals and tangents flipped, winding reversed.
    static func mirrored(_ geometry: MeshGeometry) -> MeshGeometry {
        var out = geometry
        out.vertices = geometry.vertices.map { v in
            MeshVertex(position: Vec3(-v.position.x, v.position.y, v.position.z), normal: Vec3(-v.normal.x, v.normal.y, v.normal.z), uv: v.uv,
                       tangent: Vec4(-v.tangent.x, v.tangent.y, v.tangent.z, -v.tangent.w))
        }
        var i = 0
        while i + 2 < out.indices.count {
            out.indices.swapAt(i + 1, i + 2)
            i += 3
        }
        return out
    }

    /// The 12 triangles of a box.
    static func appendBox(center: Vec3, halfExtent h: Vec3, rotation: Quat, into mesh: inout (vertices: [Vec3], indices: [UInt32])) {
        let base = UInt32(mesh.vertices.count)
        for i in 0..<8 {
            let corner = Vec3(i & 1 == 0 ? -h.x : h.x, i & 2 == 0 ? -h.y : h.y, i & 4 == 0 ? -h.z : h.z)
            mesh.vertices.append(center + rotation * corner)
        }
        let faces: [UInt32] = [0, 2, 3, 0, 3, 1, 4, 5, 7, 4, 7, 6, 0, 1, 5, 0, 5, 4, 2, 6, 7, 2, 7, 3, 0, 4, 6, 0, 6, 2, 1, 3, 7, 1, 7, 5]
        mesh.indices += faces.map { base + $0 }
    }
}

/// Reads the files pieces come from by running their own importers (cached per file, recorded
/// as dependencies of the map).
final class PieceLoader {
    private let context: ImportContext
    private var imports: [AssetID: ImportedAsset?] = [:]
    private let paths: [AssetID: String]
    private let assetsRoot: URL
    private let scratch: URL
    /// Piece imports kept across reimports (nil outside an asset database).
    let cache: GridMapPieceCache?
    /// Built-in primitives ("cube"...) used by prefab pieces, as meshes of the map itself.
    private(set) var builtinMeshes: [(id: SubAssetID, name: String, geometry: MeshGeometry)] = []

    init(_ context: ImportContext) {
        self.context = context
        var paths: [AssetID: String] = [:]
        for (path, id) in context.assetsByPath { paths[id] = path }
        self.paths = paths
        var root = context.sourceURL
        for _ in context.assetPath.split(separator: "/") { root = root.deletingLastPathComponent() }
        assetsRoot = root
        scratch = FileManager.default.temporaryDirectory.appendingPathComponent("gridmap-\(UUID().uuidString)", isDirectory: true)
        cache = GridMapPieceCache(context: context, assetsRoot: root)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: scratch)
        cache?.removeUnused()
    }

    func id(forPath path: String) -> AssetID? { context.assetsByPath[path] }

    static func normalized(_ value: String) -> String {
        let value = value.trimmingCharacters(in: .whitespaces)
        return value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
    }

    /// The path `path` (relative to `Assets/`) as seen from the importing file's folder.
    private func relative(_ path: String) -> String {
        let depth = context.assetPath.split(separator: "/").count - 1
        return String(repeating: "../", count: depth) + path
    }

    /// What `id`'s importer makes of it (nil if it can't be imported here).
    func imported(_ id: AssetID) -> ImportedAsset? {
        if let done = imports[id] { return done }
        imports[id] = .some(nil)
        guard let path = paths[id] else { return nil }
        let ext = path.pathFileExtension.lowercased()
        guard ext != "gridmap", let importer = AssetImporterRegistry.builtIn.importer(forExtension: ext) else { return nil }
        let url = assetsRoot.appendingPathComponent(path)
        var settings: JSONValue?
        if let data = try? Data(contentsOf: URL(fileURLWithPath: url.path + "." + AssetSidecar.fileExtension)),
           let sidecar = try? AssetJSON.decoder().decode(AssetSidecar.self, from: data) {
            settings = sidecar.settings
        }
        let canonical = AssetJSON.canonical(importer.effectiveSettings(settings))
        if let cached = cache?.read(id: id, path: path, importer: importer, settings: canonical, log: context.dependencyLog) {
            imports[id] = .some(cached)
            return cached
        }
        guard (try? context.readDependency(relativePath: relative(path))) != nil else { return nil }
        let directory = scratch.appendingPathComponent(id.description, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var inner = ImportContext(assetID: id, sourceURL: url, assetPath: path, artifactsDirectory: directory, cacheDirectory: nil,
                                  assetsByPath: context.assetsByPath)
        let result = try? importer.importAsset(&inner, settings: settings)
        if let result, let cache, let source = context.dependencyLog.all.first(where: { $0.path == path }) {
            cache.write(result, id: id, importer: importer, settings: canonical, source: source, dependencies: inner.dependencyLog.all)
        }
        // The map follows the files the piece's import read too (a model's buffers and textures).
        inner.dependencyLog.all.forEach(context.dependencyLog.record)
        imports[id] = .some(result)
        return result
    }

    /// The triangles a mesh reference names (nil if unreadable).
    func geometry(_ reference: AssetReference) -> MeshGeometry? {
        if reference.asset == context.assetID {
            return builtinMeshes.first { $0.id == reference.subAsset }?.geometry
        }
        guard let imported = imported(reference.asset), let object = imported.object(reference.subAsset, kind: .mesh),
              case .mesh(let geometry) = object.value else { return nil }
        return geometry
    }

    func materialReference(_ value: String, warnings: inout [String]) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "material") : reference
        }
        if let id = context.assetsByPath[Self.normalized(value)] { return AssetReference(id, subAsset: "material") }
        warnings.append("no material asset '\(value)'")
        return nil
    }

    /// A reference to the built-in primitive `key` ("cube", "sphere"...) as a mesh of the map
    /// (made once per key); nil for keys that aren't built-in primitives.
    func builtinMesh(_ key: String) -> AssetReference? {
        let id = "mesh/builtin \(key)"
        if !builtinMeshes.contains(where: { $0.id == id }) {
            guard let geometry = MeshGeometry.builtin(MeshHandle(key)) else { return nil }
            builtinMeshes.append((id, key, geometry))
        }
        return AssetReference(context.assetID, subAsset: id)
    }

    /// A `.prefab` scene file's entities as nodes: names, transforms and mesh renderers (other
    /// components are left out). Renderers name an asset's mesh, or a built-in primitive that
    /// `builtin` turns into a reference (dropped without it).
    static func sceneNodes(_ data: Data, builtin: (String) -> AssetReference? = { _ in nil }) -> [PrefabNode] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entities = root["entities"] as? [[String: Any]] else { return [] }
        func floats(_ value: Any?) -> [Float]? { (value as? [Any])?.compactMap { ($0 as? NSNumber)?.floatValue } }
        var byID: [Int: PrefabNode] = [:]
        var parents: [Int: Int] = [:]
        var order: [Int] = []
        for entity in entities {
            guard let id = (entity["id"] as? NSNumber)?.intValue else { continue }
            let components = entity["components"] as? [String: Any] ?? [:]
            let name = (components["Name"] as? [String: Any])?["value"] as? String ?? "Node"
            var transform = Transform()
            if let t = components["Transform"] as? [String: Any] {
                if let p = floats(t["position"]), p.count == 3 { transform.position = Vec3(p[0], p[1], p[2]) }
                if let r = floats(t["rotation"]), r.count == 4 { transform.rotation = Quat(r[0], r[1], r[2], r[3]) }
                if let s = floats(t["scale"]), s.count == 3 { transform.scale = Vec3(s[0], s[1], s[2]) }
            }
            var node = PrefabNode(name: name, transform: transform)
            if let renderer = components["MeshRenderer"] as? [String: Any], (renderer["isVisible"] as? Bool) != false,
               let key = renderer["mesh"] as? String, let mesh = AssetReference(key) ?? builtin(key) {
                node.mesh = mesh
                node.material = (renderer["material"] as? String).flatMap { AssetReference($0) }
            }
            byID[id] = node
            if let parent = (entity["parent"] as? NSNumber)?.intValue { parents[id] = parent }
            order.append(id)
        }
        func build(_ id: Int, depth: Int) -> PrefabNode {
            var node = byID[id]!
            if depth < 64 { node.children = order.filter { parents[$0] == id }.map { build($0, depth: depth + 1) } }
            return node
        }
        return order.filter { parents[$0] == nil || byID[parents[$0]!] == nil }.map { build($0, depth: 0) }
    }
}
