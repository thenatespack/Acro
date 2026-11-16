import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Edge wear on mesh build parts (MeshBuildEdgeWear.swift, `EdgeWear` in Material.swift).

@MainActor private func importEdgeBuild(_ build: MeshBuild, _ body: (AssetDatabase, AssetID) throws -> Void) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildEdgeWearTests-\(UUID().uuidString)", isDirectory: true)
    let project = try Project.create(at: url, name: "MeshBuildEdgeWear")
    defer { try? FileManager.default.removeItem(at: project.root) }
    let database = AssetDatabase(project: project)
    let id = try database.createMeshBuild(build, at: "Models/model.meshbuild")
    database.refreshAsync()
    database.waitForAll()
    try body(database, id)
}

private func findNode(_ name: String, in nodes: [PrefabNode]) -> PrefabNode? {
    for n in nodes {
        if n.name == name { return n }
        if let found = findNode(name, in: n.children) { return found }
    }
    return nil
}

/// The edge coordinate a vertex carries, as the shader decodes it.
private func edgeCoordinate(_ v: MeshVertex) -> Float {
    EdgeWear.coordinate(tangent: Vec3(v.tangent.x, v.tangent.y, v.tangent.z), normal: v.normal)
}

/// mesh_surface.glsl's decoding of `EdgeWear.packed`, in floats as the shader does it.
private func unpack(_ packed: (Float, Float)) -> (color: Vec3, roughness: Float, metallic: Float, frequency: Float, crisp: Float) {
    func bytes(_ w: Float) -> (Float, Float, Float) {
        let hi = (w / 65536).rounded(.down)
        let mid = ((w - hi * 65536) / 256).rounded(.down)
        return (w - hi * 65536 - mid * 256, mid, hi)
    }
    let a = bytes(packed.0), b = bytes(packed.1)
    let flags = b.2 - 128
    let code = flags.truncatingRemainder(dividingBy: 32)
    return (Vec3(a.0, a.1, a.2) / 255 * 2, b.0 / 255, b.1 / 255, 4 * exp2f(code / 3), (flags / 32).rounded(.down) / 3)
}

@Suite(.serialized) struct MeshBuildEdgeWearTests {
    @Test func edgeCoordinatesAndParametersRoundTrip() {
        // The coordinate through the tangent: whatever the tangent's length or angle to the normal,
        // and the occlusion in w stays.
        let normal = normalize(Vec3(0.3, 1, -0.2))
        for e: Float in [-24, -10, -1, 0, 0.37, 1, 1.5] {
            var g = MeshGeometry(vertices: [MeshVertex(position: .zero, normal: normal, tangent: Vec4(2, 0.4, 0, -0.62))], indices: [])
            MeshBuildEdgeWear.store([e], in: &g)
            let v = g.vertices[0]
            #expect(abs(edgeCoordinate(v) - e) < 1e-3, "\(e) -> \(edgeCoordinate(v))")
            #expect(v.tangent.w == -0.62, "handedness and baked occlusion are kept")
            // The shader's tangent: the in-plane part, still along the original tangent's projection.
            let t = Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
            let inPlane = normalize(t - normal * dot(normal, t))
            let original = normalize(Vec3(2, 0.4, 0) - normal * dot(normal, Vec3(2, 0.4, 0)))
            #expect(dot(inPlane, original) > 0.9999)
        }
        // Out of range clamps; a plain tangent reads as far from any edge.
        #expect(EdgeWear.decode(EdgeWear.encode(-100)) == EdgeWear.minimum && EdgeWear.decode(EdgeWear.encode(9)) == EdgeWear.maximum)
        #expect(EdgeWear.coordinate(tangent: Vec3(1, 0, 0), normal: Vec3(0, 1, 0)) == EdgeWear.minimum)

        let wear = EdgeWear(color: Vec3(0.62, 1.3, 0.05), roughness: 0.3, metallic: 1, noiseFrequency: 90, crisp: 1)
        let packed = wear.packed
        #expect(packed.0 < 16_777_216 && packed.1 < 16_777_216 && packed.1 > 0.5, "24-bit integers, exact in a float")
        #expect(packed.0 == packed.0.rounded() && packed.1 == packed.1.rounded())
        let back = unpack(packed)
        #expect(abs(back.color.x - 0.62) < 0.005 && abs(back.color.y - 1.3) < 0.005 && abs(back.color.z - 0.05) < 0.005)
        #expect(abs(back.roughness - 0.3) < 0.003 && back.metallic == 1 && back.crisp == 1)
        #expect(abs(back.frequency / 90 - 1) < 0.13, "frequency in steps of a third of an octave: \(back.frequency)")
        let soft = unpack(EdgeWear(color: .zero, roughness: 1, metallic: 0, noiseFrequency: 1, crisp: 0).packed)
        #expect(soft.crisp == 0 && soft.frequency == 4 && soft.metallic == 0 && soft.roughness == 1)
    }

    @Test func cubeEdgesAndCornersAreHighFaceCentersLow() {
        // An unbevelled 0.4 m box, split like the occlusion bake does (faces in a few big triangles).
        var box = MeshGeometry.cube(size: 1)
        box.scale(by: Vec3(repeating: 0.4))
        box = box.tessellated(maxEdge: 0.1, maxTriangles: 10_000)
        let width = MeshBuildEdgeWear.bandWidth(size: Vec3(repeating: 0.4), wear: 1, look: .paintedMetal)
        #expect(abs(width - 0.02) < 1e-4)
        let edges = MeshBuildEdgeWear.convexEdges(box, width: width)
        #expect(!edges.isEmpty && edges.allSatisfy { $0.strength > 0.99 }, "every edge of a box is a sharp convex edge")
        MeshBuildEdgeWear.store(MeshBuildEdgeWear.coordinates(box, edges: edges, width: width), in: &box)
        for v in box.vertices {
            let p = v.position
            let onEdges = [p.x, p.y, p.z].filter { abs(abs($0) - 0.2) < 1e-4 }.count  // 1 face, 2 edge, 3 corner
            let e = edgeCoordinate(v)
            switch onEdges {
            case 3: #expect(e > 1.3, "corner \(p): \(e)")
            case 2: #expect(e > 0.99, "edge \(p): \(e)")
            default:
                // On a face: one band width in from the nearest edge per meter.
                let inward = [p.x, p.y, p.z].filter { abs(abs($0) - 0.2) > 1e-4 }.map { 0.2 - abs($0) }.min() ?? 0
                #expect(abs(e - max(1 - inward / width, EdgeWear.minimum)) < 0.4, "face \(p): \(e)")
            }
        }
        let centers = box.vertices.filter { v in [v.position.x, v.position.y, v.position.z].filter { abs($0) < 1e-4 }.count == 2 }
        #expect(centers.count == 6 && centers.allSatisfy { edgeCoordinate($0) < -5 }, "face centers are far from the edges")

        // Halfway between an edge vertex and the next one in, the interpolated coordinate is the
        // distance's (what lets big triangles keep a narrow band).
        let a = box.vertices.first { abs($0.position.x - 0.2) < 1e-4 && abs($0.position.y - 0.2) < 1e-4 && abs($0.position.z) < 1e-4 && $0.normal.x > 0.9 }
        let b = box.vertices.first { abs($0.position.x - 0.2) < 1e-4 && abs($0.position.y - 0.1) < 1e-4 && abs($0.position.z) < 1e-4 && $0.normal.x > 0.9 }
        if let a, let b {
            let mid = (edgeCoordinate(a) + edgeCoordinate(b)) / 2
            #expect(abs(mid - (1 - 0.05 / width)) < 0.05, "\(mid)")
        } else {
            Issue.record("the split box has vertices on the edge and 0.1 m in")
        }
    }

    @Test func smoothRoundSidesAreNotEdgesButRimsAndBevelsAre() {
        let width: Float = 0.02
        // A sphere: no edges anywhere.
        var sphere = MeshGeometry.sphere(radius: 0.2, segments: 32, rings: 16)
        #expect(MeshBuildEdgeWear.convexEdges(sphere, width: width).isEmpty)
        MeshBuildEdgeWear.apply(to: &sphere, wear: 1, look: .paintedMetal)
        #expect(sphere.vertices.allSatisfy { edgeCoordinate($0) < -5 })
        // A cylinder: the rims, not the sides.
        let cylinder = MeshBuildPart(name: "C", shape: .cylinder, size: Vec3(0.35, 0.4, 0.35)).geometry()!
        let rims = MeshBuildEdgeWear.convexEdges(cylinder, width: width)
        #expect(!rims.isEmpty && rims.allSatisfy { abs(abs($0.a.y) - 0.2) < 1e-4 && abs(abs($0.b.y) - 0.2) < 1e-4 }, "only rim edges")
        // A bevelled box: the rounding's rows add up to a strong edge.
        let rounded = MeshBuildPart(name: "R", shape: .box, size: Vec3(0.4, 0.4, 0.4), bevel: 0.03).geometry()!
        let bevel = MeshBuildEdgeWear.convexEdges(rounded, width: width)
        #expect(bevel.contains { $0.strength > 0.9 }, "max \(bevel.map(\.strength).max() ?? 0)")
        var worn = rounded.tessellated(maxEdge: 0.1, maxTriangles: 20_000)
        MeshBuildEdgeWear.apply(to: &worn, wear: 1, look: .wood)
        let onBevel = worn.vertices.filter { abs($0.position.x) > 0.19 && abs($0.position.y) > 0.19 && abs($0.position.z) < 0.1 }
        let faceMiddle = worn.vertices.filter { abs($0.position.x) < 0.05 && abs($0.position.y) < 0.05 }
        #expect(!onBevel.isEmpty && onBevel.allSatisfy { edgeCoordinate($0) > 0.5 })
        #expect(!faceMiddle.isEmpty && faceMiddle.allSatisfy { edgeCoordinate($0) < -3 })
    }

    @MainActor @Test func importerWearsLookEdgesAndLeavesOtherPartsAlone() throws {
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Crate", position: Vec3(0, 0.2, 0), size: Vec3(0.4, 0.4, 0.4), look: "paintedMetal", wear: 1),
            MeshBuildPart(name: "Clean", position: Vec3(1, 0.2, 0), size: Vec3(0.4, 0.4, 0.4), look: "paintedMetal"),
            MeshBuildPart(name: "Plain", position: Vec3(-1, 0.2, 0), size: Vec3(0.4, 0.4, 0.4), wear: 1),
            MeshBuildPart(name: "Glass", position: Vec3(0, 0.2, 1), size: Vec3(0.4, 0.4, 0.4), look: "glass", wear: 1),
        ])
        try importEdgeBuild(build) { database, id in
            let prefab = try #require(database.prefab(AssetReference(id)))
            @MainActor func part(_ name: String) throws -> (MeshGeometry, MaterialAsset) {
                let node = try #require(findNode(name, in: prefab.roots))
                return (try #require(node.mesh.flatMap { database.mesh($0) }), try #require(node.material.flatMap { database.material($0) }))
            }
            let (crate, crateMaterial) = try part("Crate")
            let wear = try #require(crateMaterial.edgeWear)
            #expect(wear.metallic == 1 && wear.crisp == 1, "painted metal chips to bare metal")
            #expect(crate.vertices.contains { edgeCoordinate($0) > 1.3 } && crate.vertices.contains { edgeCoordinate($0) < -3 })
            #expect(crate.vertices.allSatisfy { abs($0.tangent.w) <= 1 && abs($0.tangent.w) > 0 }, "occlusion still in w")
            for name in ["Clean", "Plain", "Glass"] {
                let (mesh, material) = try part(name)
                #expect(material.edgeWear == nil, "\(name)")
                // Their tangents are as before: unit length, perpendicular to the normal.
                #expect(mesh.vertices.allSatisfy { v in
                    let t = Vec3(v.tangent.x, v.tangent.y, v.tangent.z)
                    return abs(dot(t, normalize(v.normal))) < 1e-4 && abs(length(t) - 1) < 1e-4
                }, "\(name)")
            }
        }
    }

    @Test func materialCarriesEdgeWearToTheUniformsAndFiles() throws {
        var asset = MaterialAsset()
        #expect(asset.material(textures: { _ in nil }).edgeWear == nil)
        let wear = EdgeWear(color: Vec3(0.5, 0.4, 0.3), roughness: 0.6, metallic: 0, noiseFrequency: 40, crisp: 0.33)
        asset.edgeWear = wear
        #expect(asset.material(textures: { _ in nil }).edgeWear == wear)
        let data = try JSONEncoder().encode(asset)
        #expect(try JSONDecoder().decode(MaterialAsset.self, from: data).edgeWear == wear)
        // Files without the key read as none, and materials without it don't write it.
        #expect(!String(decoding: try JSONEncoder().encode(MaterialAsset()), as: UTF8.self).contains("edgeWear"))
    }
}
