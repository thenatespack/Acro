import Foundation
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Imports `.path` files (a `PathBuild` as JSON): `mesh/<profile>` and `material/<profile>` per
/// cross-section profile, `mesh/<piece>` and `material/<piece>` per built-in piece, and the main
/// `prefab/<file name>`: a root named after the file with one node per profile (mesh, material
/// and, with `collider`, a triangle-mesh `Collider`) and one group node per piece rule holding
/// its placed copies (equal mesh and material, so they draw as one instanced batch).
///
/// With `terrain.asset` set, the `.terrain` file is read as a dependency: editing the terrain
/// reimports the path, so it keeps following the ground.
public struct PathBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "path" }
    public var fileExtensions: [String] { ["path"] }
    public var version: Int { 2 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: PathBuild
        do { build = try AssetJSON.decoder().decode(PathBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a path: \(error)")
        }
        for problem in build.problems { context.warn(problem) }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let ground = Self.terrain(build.terrain, &context)
        let samples = build.samples(on: ground)
        let junctions = build.junctionLayout(Self.junctionTargets(build, ground: ground, &context), samples: samples)
        for warning in junctions.warnings { context.warn(warning) }
        let runs = PathBuild.runs(samples, outside: junctions.cuts)
        let paving = build.pavingProfile?.name
        var asset = ImportedAsset()
        var meshNamer = SubAssetNamer(), materialNamer = SubAssetNamer()
        var children: [PrefabNode] = []

        for (i, profile) in build.profiles.enumerated() {
            var pieces = runs.compactMap { build.mesh(profile, samples: $0) }
            if profile.name == paving, let patch = junctions.patch { pieces.append(patch) }
            guard let geometry = MeshGeometry.joined(pieces) else {
                if samples.count >= 2 { context.warn("profile '\(profile.name)' makes no geometry") }
                continue
            }
            let meshID = meshNamer.id(kind: "mesh", name: profile.name, index: i)
            asset.add(meshID, name: profile.name, .mesh(geometry))
            var material = Self.materialReference(profile.material, owner: profile.name, &context)
            if material == nil {
                let materialID = materialNamer.id(kind: "material", name: profile.name, index: i)
                asset.add(materialID, name: profile.name, .material(Self.material(for: profile, texture: Self.texture(profile, &context))))
                material = context.reference(materialID)
            }
            let collider: ColliderShape? = profile.collider
                ? .triangleMesh(vertices: geometry.vertices.map(\.position), indices: geometry.indices) : nil
            children.append(PrefabNode(name: profile.name, mesh: context.reference(meshID), material: material, collider: collider))
        }

        var budget = PathBuild.maxPieces
        for (i, piece) in build.pieces.enumerated() {
            guard let parts = Self.parts(of: piece, index: i, meshNamer: &meshNamer, materialNamer: &materialNamer, asset: &asset, &context) else {
                continue
            }
            var instances = build.instances(of: piece, samples: samples, on: ground, limit: budget + 1, excluding: junctions.cuts)
            if instances.count > budget {
                context.warn("piece '\(piece.name)': more than \(PathBuild.maxPieces) pieces in total; the rest are dropped")
                instances = Array(instances.prefix(budget))
            }
            budget -= instances.count
            let single = parts.count == 1 && parts[0].transform == Transform()
            let builtIn = piece.asset.trimmingCharacters(in: .whitespaces).isEmpty
            let collider: ColliderShape? = builtIn && piece.collider ? .box(halfExtents: Vec3(abs(piece.size.x), abs(piece.size.y), abs(piece.size.z)) / 2) : nil
            let nodes = instances.enumerated().map { n, instance -> PrefabNode in
                let transform = Transform(position: instance.position, rotation: instance.rotation, scale: Vec3(repeating: instance.scale))
                if single {
                    return PrefabNode(name: "\(piece.name) \(n)", transform: transform, mesh: parts[0].mesh, material: parts[0].material,
                                      collider: collider)
                }
                return PrefabNode(name: "\(piece.name) \(n)", transform: transform, children: parts.map {
                    PrefabNode(name: $0.name, transform: $0.transform, mesh: $0.mesh, material: $0.material)
                })
            }
            children.append(PrefabNode(name: piece.name, children: nodes))
        }

        var prefabNamer = SubAssetNamer()
        let prefab = prefabNamer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: children)])))
        asset.main = prefab
        return asset
    }

    // MARK: Parts

    /// A piece's drawable parts: a built-in shape (added to `asset`), or the parts of the
    /// `.meshbuild` / mesh reference it names.
    private static func parts(of piece: PathPiece, index: Int, meshNamer: inout SubAssetNamer, materialNamer: inout SubAssetNamer,
                              asset: inout ImportedAsset, _ context: inout ImportContext) -> [TerrainImporter.PropPart]? {
        if !piece.asset.trimmingCharacters(in: .whitespaces).isEmpty {
            let before = context.warnings.count
            let parts = TerrainImporter.prop(TerrainScatter(name: piece.name, asset: piece.asset, material: piece.material), &context)
            // The shared loader speaks of scatter rules; here they're pieces.
            let scatter = "scatter '\(piece.name)'"
            for i in before..<context.warnings.count where context.warnings[i].hasPrefix(scatter) {
                context.warnings[i] = "piece '\(piece.name)'" + context.warnings[i].dropFirst(scatter.count)
            }
            return parts
        }
        let part = MeshBuildPart(name: piece.name, shape: piece.shape, size: piece.size, color: piece.color,
                                 metallic: piece.metallic, roughness: piece.roughness)
        guard let geometry = part.geometry(), !geometry.indices.isEmpty else {
            if piece.shape != .group { context.warn("piece '\(piece.name)' has no shape to draw") }
            return nil
        }
        let meshID = meshNamer.id(kind: "mesh", name: piece.name, index: index + 10_000)
        asset.add(meshID, name: piece.name, .mesh(geometry))
        let materialID = materialNamer.id(kind: "material", name: piece.name, index: index + 10_000)
        asset.add(materialID, name: piece.name, .material(MeshBuildImporter.material(for: part, texture: nil)))
        return [TerrainImporter.PropPart(name: piece.name, transform: Transform(), mesh: context.reference(meshID),
                                         material: context.reference(materialID))]
    }

    static func material(for profile: PathProfile, texture: AssetReference?) -> MaterialAsset {
        let opacity = min(max(profile.opacity, 0), 1)
        let color = MeshBuildColor.linear(fromSRGB: profile.color)
        return MaterialAsset(shading: .pbr, baseColor: Vec4(color.x, color.y, color.z, opacity), texture: texture,
                             metallic: min(max(profile.metallic, 0), 1), roughness: min(max(profile.roughness, 0), 1),
                             emissiveColor: MeshBuildColor.linear(fromSRGB: profile.glow), alphaMode: opacity < 1 ? .blend : .opaque,
                             doubleSided: profile.shape == .flat || (profile.shape == .custom && !profile.closedShape))
    }

    // MARK: References

    private static func normalized(_ value: String) -> String {
        let value = value.trimmingCharacters(in: .whitespaces)
        return value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
    }

    /// The path `path` (relative to `Assets/`) as seen from the importing file's folder.
    private static func relative(_ path: String, from assetPath: String) -> String {
        String(repeating: "../", count: assetPath.split(separator: "/").count - 1) + path
    }

    /// The terrain to follow (nil when off or unreadable, with a warning for the latter).
    static func terrain(_ settings: PathTerrain, _ context: inout ImportContext) -> Terrain? {
        guard settings.isOn else { return nil }
        let path = normalized(settings.asset)
        guard path.lowercased().hasSuffix(".terrain") else {
            context.warn("terrain: '\(settings.asset)' isn't a .terrain file")
            return nil
        }
        guard let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)) else {
            context.warn("terrain: no terrain file '\(settings.asset)'")
            return nil
        }
        guard let terrain = PathBuild.decodeTerrain(data) else {
            context.warn("terrain: '\(settings.asset)' isn't a readable terrain")
            return nil
        }
        return terrain
    }

    /// The other paths `build` meets, read as dependencies (so editing one reimports this path),
    /// with their curves on their terrains.
    static func junctionTargets(_ build: PathBuild, ground: Terrain?, _ context: inout ImportContext) -> [PathJunctionTarget] {
        build.junctions.compactMap { junction -> PathJunctionTarget? in
            var value = junction.path.trimmingCharacters(in: .whitespaces)
            if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
                guard let path = context.assetsByPath.first(where: { $0.value == reference.asset })?.key else {
                    context.warn("junction: no path asset '\(junction.path)'")
                    return nil
                }
                value = path
            }
            let path = normalized(value)
            guard path.lowercased().hasSuffix(".path") else {
                context.warn("junction: '\(junction.path)' isn't a .path file")
                return nil
            }
            guard path != context.assetPath else {
                context.warn("junction: a path can't join itself")
                return nil
            }
            guard let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)),
                  let other = try? AssetJSON.decoder().decode(PathBuild.self, from: data) else {
                context.warn("junction: no readable path '\(junction.path)'")
                return nil
            }
            let sameGround = other.terrain.isOn && normalized(other.terrain.asset) == normalized(build.terrain.asset)
            let otherGround = sameGround ? ground : terrain(other.terrain, &context)
            return PathJunctionTarget(junction, other: other, samples: other.samples(on: otherGround))
        }
    }

    private static func texture(_ profile: PathProfile, _ context: inout ImportContext) -> AssetReference? {
        let value = profile.texture.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "texture") : reference
        }
        if let id = context.assetsByPath[normalized(value)] { return AssetReference(id, subAsset: "texture") }
        context.warn("profile '\(profile.name)': no texture asset '\(value)'")
        return nil
    }

    private static func materialReference(_ value: String, owner: String, _ context: inout ImportContext) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "material") : reference
        }
        if let id = context.assetsByPath[normalized(value)] { return AssetReference(id, subAsset: "material") }
        context.warn("profile '\(owner)': no material asset '\(value)'")
        return nil
    }
}
