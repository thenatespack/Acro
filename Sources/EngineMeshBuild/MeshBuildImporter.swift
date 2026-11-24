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

// A part's geometry and the `.meshbuild` importer. The file format (`MeshBuild`, `MeshBuildPart`)
// is in EngineAssets/Assets/MeshBuild.swift.

// MARK: - Geometry

extension MeshBuildPart {
    /// The part's mesh in its own space (nil for a `group`): the shape fitted to `size`, with
    /// world-projected UVs under `worldUV`, reflected by `reflection` on mirror copies.
    public func geometry() -> MeshGeometry? {
        var warnings: [String] = []
        return geometry(warnings: &warnings)
    }

    /// The part's mesh, adding a sentence to `warnings` for each problem with its fields (a
    /// `lathe` or `extrude` whose profile can't be built is nil).
    public func geometry(warnings: inout [String]) -> MeshGeometry? {
        var shaped = shapeGeometry(warnings: &warnings)
        // Deformers bend the finished shape before the reflection, so mirror copies match (MeshBuildDeform.swift).
        if let g = shaped, !(deform ?? []).isEmpty { shaped = deformed(g, warnings: &warnings) }
        // A leaf look on a ribbon or plane shows one sprig (MeshBuildFoliage.swift).
        if let g = shaped, shape != .foliage, resolvedLeafLook != nil { shaped = leafSprigUVs(g) }
        guard reflection != Vec3(1, 1, 1), var g = shaped else { return shaped }
        g.scale(by: reflection)  // flips the normals, and the winding when it is a mirror image
        return g
    }

    private func shapeGeometry(warnings: inout [String]) -> MeshGeometry? {
        warnings += fieldWarnings
        let s = Vec3(abs(size.x), abs(size.y), abs(size.z))
        let segments = min(max(segments, 3), 128)
        let bevel = bevel.map { $0.isFinite ? max($0, 0) : 0 } ?? 0
        var g: MeshGeometry
        switch shape {
        case .group: return nil
        case .sculpt: return sculptGeometry(warnings: &warnings)
        case .foliage: return foliageGeometry(warnings: &warnings)  // MeshBuildFoliage.swift
        case .box:
            guard bevel > 0 else { g = .cube(size: 1); break }
            return finish(MeshGeometry.roundedBox(halfExtent: s / 2, radius: bevel, segments: segments))
        case .cylinder where bevel > 0:
            // Built at its real size so the rims stay round, then stretched to an oval like a capsule.
            let r = min(s.x, s.z) / 2
            g = MeshGeometry.roundedCylinder(radius: r, height: s.y, bevel: bevel, segments: segments)
            g.scale(by: Vec3(r > 0 ? s.x / 2 / r : 1, 1, r > 0 ? s.z / 2 / r : 1))
            return finish(g)
        case .lathe:
            guard var lathe = MeshGeometry.lathe(profile: profile ?? [], segments: segments, warnings: &warnings) else { return nil }
            lathe.scale(by: s)
            return finish(lathe)
        case .extrude:
            guard let extrude = MeshGeometry.extrude(profile: (profile ?? []).map { $0 * Vec2(s.x, s.y) }, depth: s.z,
                                                     warnings: &warnings) else { return nil }
            return finish(extrude)
        case .sweep, .loft:
            // Curves (MeshBuildCurves.swift): meters as written, `size` multiplies them like a profile's.
            guard var curve = curveGeometry(segments: segments, warnings: &warnings) else { return nil }
            curve.scale(by: s)
            return finish(curve)
        case .sphere: g = .sphere(radius: 0.5, segments: segments, rings: max(segments / 2, 2))
        case .hemisphere: g = MeshGeometry.hemisphere(segments: segments)
        case .cylinder: g = .cylinder(radius: 0.5, height: 1, segments: segments)
        case .cone: g = .cone(radius: 0.5, height: 1, segments: segments)
        case .capsule:
            // A capsule's caps must stay round, so it is built at its real size.
            let r = min(s.x, s.z) / 2
            g = .capsule(radius: min(r, s.y / 2), height: s.y, segments: segments, rings: max(segments / 4, 2))
            g.scale(by: Vec3(r > 0 ? s.x / 2 / r : 1, 1, r > 0 ? s.z / 2 / r : 1))
            return finish(g)
        case .torus:
            let minor = min(s.y, min(s.x, s.z) / 2) / 2
            let major = max(min(s.x, s.z) / 2 - minor, 0)
            g = .torus(majorRadius: major, minorRadius: minor, segments: segments, sides: max(segments / 2, 3))
            let ring = major + minor
            g.scale(by: Vec3(ring > 0 ? s.x / 2 / ring : 1, 1, ring > 0 ? s.z / 2 / ring : 1))
            return finish(g)
        case .tube:
            g = MeshGeometry.tube(outerRadius: 0.5, innerRadius: max(0.5 - thickness / max(min(s.x, s.z), 1e-4), 0),
                                  segments: segments)
        case .plane: g = .plane(size: 1)
        case .wedge:
            g = MeshGeometry.convexHullFaces([
                [Vec3(-0.5, -0.5, -0.5), Vec3(0.5, -0.5, -0.5), Vec3(0.5, -0.5, 0.5), Vec3(-0.5, -0.5, 0.5)],  // bottom
                [Vec3(-0.5, -0.5, -0.5), Vec3(-0.5, 0.5, -0.5), Vec3(0.5, 0.5, -0.5), Vec3(0.5, -0.5, -0.5)],  // back
                [Vec3(-0.5, 0.5, -0.5), Vec3(-0.5, -0.5, 0.5), Vec3(0.5, -0.5, 0.5), Vec3(0.5, 0.5, -0.5)],    // slope
                [Vec3(-0.5, -0.5, -0.5), Vec3(-0.5, -0.5, 0.5), Vec3(-0.5, 0.5, -0.5)],                        // left
                [Vec3(0.5, -0.5, -0.5), Vec3(0.5, 0.5, -0.5), Vec3(0.5, -0.5, 0.5)],                           // right
            ])
        case .pyramid:
            let apex = Vec3(0, 0.5, 0)
            let b = [Vec3(-0.5, -0.5, -0.5), Vec3(0.5, -0.5, -0.5), Vec3(0.5, -0.5, 0.5), Vec3(-0.5, -0.5, 0.5)]
            g = MeshGeometry.convexHullFaces([b] + (0..<4).map { [b[$0], b[($0 + 1) % 4], apex] })
        }
        g.scale(by: Vec3(s.x, shape == .plane ? 1 : s.y, s.z))
        return finish(g)
    }

    private func finish(_ geometry: MeshGeometry) -> MeshGeometry {
        var g = geometry
        if worldUV {
            // Planar projection along each vertex's dominant normal axis, in meters.
            for i in g.vertices.indices {
                let p = g.vertices[i].position, n = g.vertices[i].normal
                let a = Vec3(abs(n.x), abs(n.y), abs(n.z))
                if a.x >= a.y && a.x >= a.z {
                    g.vertices[i].uv = Vec2(n.x > 0 ? -p.z : p.z, -p.y)
                } else if a.y >= a.z {
                    g.vertices[i].uv = Vec2(p.x, n.y > 0 ? p.z : -p.z)
                } else {
                    g.vertices[i].uv = Vec2(n.z > 0 ? p.x : -p.x, -p.y)
                }
            }
        }
        return g
    }
}

extension MeshGeometry {
    /// Scales positions by `factor` per axis and corrects the normals (inverse-transpose).
    mutating func scale(by factor: Vec3) {
        guard factor != Vec3(1, 1, 1) else { return }
        let inverse = Vec3(factor.x != 0 ? 1 / factor.x : 0, factor.y != 0 ? 1 / factor.y : 0, factor.z != 0 ? 1 / factor.z : 0)
        for i in vertices.indices {
            vertices[i].position *= factor
            let n = vertices[i].normal * inverse
            let len = length(n)
            vertices[i].normal = len > 0 ? n / len : vertices[i].normal
        }
        // A negative scale mirrors the mesh: flip the winding to keep faces counter-clockwise.
        if factor.x * factor.y * factor.z < 0 {
            for t in stride(from: 0, to: indices.count - 2, by: 3) { indices.swapAt(t + 1, t + 2) }
        }
    }

    /// The top half of a sphere of radius 0.5 squashed to unit height: base at y = -0.5 (a flat
    /// disc), top at +0.5, diameter 1.
    static func hemisphere(segments: Int) -> MeshGeometry {
        let rings = max(segments / 4, 2)
        var profile: [LatheRing] = []
        for i in 0...rings {
            let a = Float(i) / Float(rings) * .pi / 2
            // A radius-0.5 dome of height 1: y = -0.5 + cos(a), normals of the stretched sphere.
            let n = normalize(Vec3(sinf(a), cosf(a) / 2, 0))
            profile.append((0.5 * sinf(a), -0.5 + cosf(a), n.x, n.y, Float(i) / Float(rings)))
        }
        var g = MeshGeometry(vertices: [], indices: [])
        g.appendLathe(profile, segments: segments)
        g.appendCap(radius: 0.5, y: -0.5, up: false, segments: segments)
        return g
    }

    /// A hollow cylinder along Y of height 1 between `innerRadius` and `outerRadius`, with flat rings at both ends.
    static func tube(outerRadius: Float, innerRadius: Float, segments: Int) -> MeshGeometry {
        let ro = outerRadius, ri = min(innerRadius, outerRadius * 0.999)
        var g = MeshGeometry(vertices: [], indices: [])
        // Each lathe piece runs in the direction that makes its normal (profile direction turned
        // +90 degrees in (r, y)) point outward: top inner→outer, outer wall down, bottom outer→inner, inner wall up.
        g.appendLathe([(ri, 0.5, 0, 1, 0), (ro, 0.5, 0, 1, 0.1)], segments: segments)
        g.appendLathe([(ro, 0.5, 1, 0, 0.1), (ro, -0.5, 1, 0, 0.5)], segments: segments)
        g.appendLathe([(ro, -0.5, 0, -1, 0.5), (ri, -0.5, 0, -1, 0.6)], segments: segments)
        if ri > 0 { g.appendLathe([(ri, -0.5, -1, 0, 0.6), (ri, 0.5, -1, 0, 1)], segments: segments) }
        return g
    }

    /// A flat-shaded convex solid from its faces (each a planar loop of corners in either
    /// order): every face is wound counter-clockwise seen from outside (judged against the
    /// solid's center), fan-triangulated, with planar 0–1 UVs.
    static func convexHullFaces(_ faces: [[Vec3]]) -> MeshGeometry {
        let all = faces.flatMap { $0 }
        let center = all.reduce(Vec3.zero, +) / Float(max(all.count, 1))
        var g = MeshGeometry(vertices: [], indices: [])
        for var face in faces where face.count >= 3 {
            var n = Vec3.zero  // Newell's method
            for i in face.indices {
                let a = face[i], b = face[(i + 1) % face.count]
                n += Vec3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
            }
            let faceCenter = face.reduce(Vec3.zero, +) / Float(face.count)
            if dot(n, faceCenter - center) < 0 { face.reverse(); n = -n }
            n = normalize(n)
            // UV axes in the face's plane: u along the first edge, v perpendicular.
            let u = normalize(face[1] - face[0]), v = cross(n, u)
            let coords = face.map { Vec2(dot($0 - face[0], u), dot($0 - face[0], v)) }
            let lo = coords.reduce(Vec2(repeating: .infinity)) { pointwiseMin($0, $1) }
            let hi = coords.reduce(Vec2(repeating: -.infinity)) { pointwiseMax($0, $1) }
            let extent = pointwiseMax(hi - lo, Vec2(1e-6, 1e-6))
            let base = UInt32(g.vertices.count)
            for (p, c) in zip(face, coords) {
                let t = (c - lo) / extent
                g.vertices.append(MeshVertex(position: p, normal: n, uv: Vec2(t.x, 1 - t.y)))
            }
            for i in 1..<UInt32(face.count - 1) { g.indices += [base, base + i, base + i + 1] }
        }
        return g
    }
}

// MARK: - Importer

/// Imports `.meshbuild` files (a `MeshBuild` as JSON): `mesh/<part>` and `material/<part>` per
/// part (no material for parts using a `material` asset, no mesh for groups) and the main
/// `prefab/<file name>`: a root node named after the file holding the part tree, with a
/// `FieldAnimator` on every part an autoplay animation moves. Editing the file (in the editor's
/// Mesh Builder, with the `meshBuild.*` tools or by hand) reimports it and updates placed copies.
public struct MeshBuildImporter: AssetImporter {
    public init() {}

    public var name: String { BuiltInImporterName.meshBuild }
    public var fileExtensions: [String] { ["meshbuild"] }
    public var version: Int { 13 }  // 2: mirror and repeat, 3: sculpt, 4: sweep, loft and deform, 5: looks and baked occlusion,
                                   // 6: sculpt children's looks, sweeps / lofts / deformers in sculpts, 7: edge wear,
                                   // 8: foliage, ribbons, leaf looks, noise budget, 9: edge wear noise in object space,
                                   // 10: sculpt look blending, leaf card variation,
                                   // 11: plant wind, detail levels, impostors, 12: baked occlusion off by default,
                                   // 13: physics materials

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let file: MeshBuild
        do { file = try AssetJSON.decoder().decode(MeshBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a mesh build: \(error)")
        }
        // Mirror and repeat copies become parts of their own (after the file's parts).
        let expansion = file.expansion()
        for warning in expansion.warnings { context.warn(warning) }
        // A sculpt's subtree is meshed into it (MeshBuildSculpt.swift): those parts stay nodes (pivots) without meshes.
        let sculpting = expansion.build.gatheringSculpts(sources: expansion.sources)
        for warning in sculpting.build.sculptContextWarnings(sculpting) { context.warn(warning) }
        // A sculpt with several looks draws a mesh per look on parts of their own, appended (MeshBuildSculptLooks.swift).
        // Their looks blend across the boundaries (MeshBuildSculptBlend.swift): blend layers are parts too.
        let pieces = sculpting.splittingLooks(blending: true)
        let build = pieces.build
        let stem = context.assetPath.pathLastComponent.pathDeletingExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()

        // Part names must be unique for parenting and tracks; later duplicates are only drawn.
        var firstIndex: [String: Int] = [:]
        for (i, part) in build.parts.enumerated() {
            if firstIndex[part.name] == nil {
                firstIndex[part.name] = i
            } else if i < file.parts.count {  // copies that clash were warned about by the expansion
                context.warn("two parts are named '\(part.name)'")
            }
        }
        let partNames = Set(firstIndex.keys)
        for animation in build.animations {
            for track in animation.allTracks where !partNames.contains(track.part) {
                context.warn("animation '\(animation.name)' moves a part that doesn't exist: '\(track.part)'")
            }
        }

        // Every part's mesh first: looks and baked occlusion (MeshBuildImporter+Looks.swift) need them all.
        var geometries: [MeshGeometry?] = build.parts.enumerated().map { i, part in
            var shapeWarnings: [String] = []
            let geometry = pieces.geometry(i, warnings: &shapeWarnings)
            if sculpting.sculpted.contains(i), i < file.parts.count { shapeWarnings += part.fieldWarnings }
            for warning in shapeWarnings { context.warn("part '\(part.name)': \(warning)") }
            return geometry
        }
        Self.finishSurfaces(build, &geometries, occlusion: file.ao ?? false, firstIndex: firstIndex, layers: pieces.layerSurfaces)
        Self.finishEdgeWear(build, &geometries, skipping: pieces.layers)
        for warning in file.plantFieldWarnings { context.warn(warning) }
        // Plants sway and get detail levels (MeshBuildLOD.swift).
        let plant = MeshBuildPlant(build: build, file: file, geometries: geometries, firstIndex: firstIndex)
        var lookTextures = LookTextureRefs()
        var leafTextures = LeafTextureRefs()  // MeshBuildImporter+Foliage.swift

        // Each drawn part's material (nil: a `material` asset), then the sculpts' blends (MeshBuildSculptBlend.swift).
        var materials: [MaterialAsset?] = build.parts.indices.map { _ in nil }
        var materialAssets: [AssetReference?] = build.parts.indices.map { _ in nil }
        for (i, part) in build.parts.enumerated() {
            guard let geometry = geometries[i], !geometry.indices.isEmpty else { continue }
            if let material = resolve(part.material, kind: "material", part: part.name, &context) {
                materialAssets[i] = material
                continue
            }
            let texture = resolve(part.texture, kind: "texture", part: part.name, &context)
            let look = part.resolvedLook.map { lookTextures.references($0, wear: part.wear, &asset, &namer, &context) }
            var material = Self.material(for: part, texture: texture, look: look, geometry: geometry)
            if let leaf = part.resolvedLeafLook {
                material = Self.leafMaterial(for: part, texture: texture, leaf: leafTextures.references(leaf, &asset, &namer, &context))
            }
            material.wind = plant.wind(forPart: i, part)
            materials[i] = material
        }
        Self.finishBlends(pieces, &geometries, &materials)

        var nodes: [PrefabNode] = []
        for (i, part) in build.parts.enumerated() {
            var node = PrefabNode(name: part.name, transform: part.transform)
            if let geometry = geometries[i], !geometry.indices.isEmpty {
                let meshID = namer.id(kind: "mesh", name: part.name, index: i)
                asset.add(meshID, name: part.name, .mesh(geometry))
                node.mesh = context.reference(meshID)
                if let material = materialAssets[i] {
                    node.material = material
                } else if let material = materials[i] {
                    let materialID = namer.id(kind: "material", name: part.name, index: i)
                    asset.add(materialID, name: part.name, .material(material))
                    node.material = context.reference(materialID)
                }
            }
            // Fur or hair on the part (GroomBuild.swift): its fur material, grown at run time.
            if let groom = part.groom?.trimmingCharacters(in: .whitespaces), !groom.isEmpty {
                if node.mesh == nil {
                    context.warn("part '\(part.name)': groom '\(groom)' needs a part with a mesh")
                } else if let fur = resolve(groom, kind: GroomRenderer.furSubAsset, part: part.name, &context) {
                    node.groom = GroomRenderer(groom: MaterialHandle(AssetReference(fur.asset, subAsset: GroomRenderer.furSubAsset)))
                }
            }
            if firstIndex[part.name] == i {
                let tracks = build.animatorTracks(for: part.name)
                if !tracks.isEmpty { node.animator = FieldAnimator(tracks: tracks) }
            }
            nodes.append(node)
        }

        Self.addDetailLevels(file: file, build: build, plant: plant, geometries: geometries, materials: materials, nodes: &nodes,
                             asset: &asset, namer: &namer, context: &context)

        // The tree: a part hangs from the first part with its `parent` name, unless that would
        // make a loop or the parent is missing (then from the root).
        func parentIndex(of i: Int) -> Int? {
            let parent = build.parts[i].parent
            guard !parent.isEmpty else { return nil }
            guard let p = firstIndex[parent], p != i else {
                context.warn("part '\(build.parts[i].name)' has a missing parent '\(parent)'")
                return nil
            }
            var seen: Set<Int> = [i], up: Int? = p
            while let u = up {
                if seen.contains(u) {
                    context.warn("part '\(build.parts[i].name)' is its own ancestor; attached to the root")
                    return nil
                }
                seen.insert(u)
                let name = build.parts[u].parent
                up = name.isEmpty ? nil : firstIndex[name]
            }
            return p
        }
        var children: [Int: [Int]] = [:]
        var roots: [Int] = []
        for i in build.parts.indices {
            if let p = parentIndex(of: i) { children[p, default: []].append(i) } else { roots.append(i) }
        }
        let rootSurface = Self.assignPhysicsSurfaces(build, to: &nodes, &context)
        func tree(_ i: Int) -> PrefabNode {
            var node = nodes[i]
            node.children = (children[i] ?? []).map(tree)
            return node
        }
        var root = PrefabNode(name: stem, children: roots.map(tree))
        root.physicsSurface = rootSurface
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [root])))
        asset.main = prefab
        return asset
    }

    /// The material of a part without a `material` asset.
    static func material(for part: MeshBuildPart, texture: AssetReference?) -> MaterialAsset {
        let opacity = min(max(part.opacity, 0), 1)
        let color = MeshBuildColor.linear(fromSRGB: part.color)
        return MaterialAsset(shading: .pbr, baseColor: Vec4(color.x, color.y, color.z, opacity), texture: texture,
                             uvScale: part.textureScale, metallic: min(max(part.metallic, 0), 1),
                             roughness: min(max(part.roughness, 0), 1), emissiveColor: MeshBuildColor.linear(fromSRGB: part.glow),
                             emissiveStrength: max(part.glowStrength, 0), alphaMode: opacity < 1 ? .blend : .opaque,
                             doubleSided: part.shape == .plane || part.isRibbon || part.shape == .foliage)
    }

    /// The asset `value` names ("" is none): a reference ("asset:<id>[#object]"), else a path
    /// relative to `Assets/`, else relative to the mesh build's folder. A file reference gets
    /// `kind` as its object ("texture", "material").
    private func resolve(_ value: String, kind: String, part: String, _ context: inout ImportContext) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: kind) : reference
        }
        let path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        if let id = context.assetsByPath[path] ?? context.asset(atRelativePath: path) {
            return AssetReference(id, subAsset: kind)
        }
        context.warn("part '\(part)': no \(kind) asset '\(value)'")
        return nil
    }
}
