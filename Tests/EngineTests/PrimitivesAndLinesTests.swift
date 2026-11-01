import Foundation
import Testing
@testable import Engine

/// Every triangle's face normal must agree with its vertices' normals (counter-clockwise from
/// outside), and every normal is unit length. Returns the fraction of agreeing triangles.
private func windingAgreement(_ g: MeshGeometry) -> Float {
    var good = 0, total = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let v = (0..<3).map { g.vertices[Int(g.indices[t + $0])] }
        let face = cross(v[1].position - v[0].position, v[2].position - v[0].position)
        guard length(face) > 1e-9 else { continue }
        total += 1
        if dot(face, v[0].normal + v[1].normal + v[2].normal) > 0 { good += 1 }
    }
    return Float(good) / Float(max(total, 1))
}

@Suite @MainActor struct PrimitiveGeometryTests {
    @Test func handlesBuildUnitSizedCenteredMeshes() throws {
        for (handle, half) in [(MeshHandle.cylinder, Vec3(0.5, 0.5, 0.5)), (.capsule, Vec3(0.25, 0.5, 0.25)),
                               (.cone, Vec3(0.5, 0.5, 0.5)), (.torus, Vec3(0.5, 0.15, 0.5))] {
            let g = try #require(MeshGeometry.builtin(handle))
            let b = g.bounds
            #expect(length(b.center) < 1e-5, "\(handle)")
            #expect(length(b.halfExtent - half) < 1e-4, "\(handle) \(b.halfExtent)")
            #expect(g.indices.allSatisfy { Int($0) < g.vertices.count })
            #expect(g.indices.count % 3 == 0)
            #expect(g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-4 }, "\(handle) normals")
            for v in g.vertices {
                #expect(v.uv.x >= -1e-5 && v.uv.x <= 1.00001 && v.uv.y >= -1e-5 && v.uv.y <= 1.00001)
            }
            #expect(windingAgreement(g) == 1, "\(handle) winding")
            #expect(g.withTangents().hasTangents)
        }
    }

    @Test func vertexCounts() {
        #expect(MeshGeometry.cylinder(segments: 8).vertices.count == (1 + 9) * 2 + 2 * 9)
        #expect(MeshGeometry.torus(segments: 8, sides: 6).vertices.count == 9 * 7)
        #expect(MeshGeometry.capsule(segments: 8, rings: 3).vertices.count == 8 * 9)
        #expect(MeshGeometry.cone(segments: 8).vertices.count == 2 * 9 + 10)
    }

    @Test func capsuleCapsRadiusAtHalfHeight() {
        let g = MeshGeometry.capsule(radius: 2, height: 1)
        #expect(abs(g.bounds.halfExtent.y - 0.5) < 1e-5)
        #expect(abs(g.bounds.halfExtent.x - 0.5) < 1e-5)
    }

    @Test func coneSideNormalsAreSlanted() {
        let g = MeshGeometry.cone(radius: 0.5, height: 1, segments: 4)
        let side = g.vertices.first { $0.position.y < 0 && $0.normal.y > 0 && $0.normal.y < 1 }!
        // The side's normal is (height, radius) in (r, y): y / r = 0.5.
        let horizontal = length(Vec3(side.normal.x, 0, side.normal.z))
        #expect(abs(side.normal.y / horizontal - 0.5) < 1e-4)
    }

    @Test func rendererRegistersTheBuiltins() throws {
        let library = PickMeshLibrary()
        for handle in MeshGeometry.builtinHandles {
            #expect(library.pickBounds(handle) != nil, "\(handle)")
        }
    }
}

@Suite @MainActor struct LineRendererTests {
    private func spec(_ points: [Vec3], sag: Float = 0, smooth: Bool = false, style: LineRenderer.Style = .tube,
                      curve: LineRenderer.Curve = .parabola, segments: Int = 8, sides: Int = 6) -> LineRenderer.Spec {
        LineRenderer.Spec(points: points, sag: sag, curve: curve, smooth: smooth, style: style, width: 0.1, segments: segments, sides: sides)
    }

    @Test func straightTubeCounts() throws {
        let g = try #require(LineRenderer.geometry(spec([Vec3(0, 0, 0), Vec3(4, 0, 0)], segments: 4, sides: 8)))
        #expect(g.vertices.count == 5 * 9)
        #expect(g.indices.count == 4 * 8 * 6)
        #expect(g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-4 })
        #expect(windingAgreement(g) == 1)
        let b = g.bounds
        #expect(abs(b.halfExtent.x - 2) < 1e-4 && abs(b.halfExtent.y - 0.05) < 1e-4)
    }

    @Test func sagDropsTheMiddleByExactlySagForBothCurves() throws {
        for curve in LineRenderer.Curve.allCases {
            let line = LineRenderer.centerline(spec([Vec3(0, 5, 0), Vec3(10, 5, 0)], sag: 1.5, curve: curve, segments: 10))
            #expect(abs(line[5].y - 3.5) < 1e-3, "\(curve)")
            #expect(abs(line[0].y - 5) < 1e-5 && abs(line[10].y - 5) < 1e-5)
            // Symmetric.
            #expect(abs(line[3].y - line[7].y) < 1e-3)
        }
    }

    @Test func catenaryHangsLowerNearTheMiddleThanAParabolaWouldAtTheEnds() {
        let c = LineRenderer.centerline(spec([Vec3(0, 0, 0), Vec3(10, 0, 0)], sag: 3, curve: .catenary, segments: 20))
        let p = LineRenderer.centerline(spec([Vec3(0, 0, 0), Vec3(10, 0, 0)], sag: 3, curve: .parabola, segments: 20))
        #expect(abs(c[10].y - p[10].y) < 1e-3)
        #expect(abs(c[5].y - p[5].y) > 1e-3)  // different shapes
    }

    @Test func smoothingPassesThroughThePoints() {
        let pts = [Vec3(0, 0, 0), Vec3(2, 3, 0), Vec3(5, 1, 1), Vec3(7, 4, 0)]
        let line = LineRenderer.centerline(spec(pts, smooth: true, segments: 6))
        #expect(line.count == 3 * 6 + 1)
        for (k, p) in pts.enumerated() { #expect(length(line[k * 6] - p) < 1e-4) }
    }

    @Test func degeneratePathsGiveNoMesh() {
        #expect(LineRenderer.geometry(spec([])) == nil)
        #expect(LineRenderer.geometry(spec([Vec3(1, 1, 1)])) == nil)
        #expect(LineRenderer.geometry(spec([Vec3(1, 1, 1), Vec3(1, 1, 1)])) == nil)
    }

    @Test func verticalAndSharpPathsStayFinite() throws {
        let g = try #require(LineRenderer.geometry(spec([Vec3(0, 0, 0), Vec3(0, 3, 0), Vec3(3, 3, 0), Vec3(3, 0, 0)], smooth: true)))
        #expect(g.vertices.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite && $0.normal.x.isFinite && abs(length($0.normal) - 1) < 1e-3 })
    }

    @Test func ribbonHasBothFaces() throws {
        let g = try #require(LineRenderer.geometry(spec([Vec3(0, 0, 0), Vec3(4, 0, 0)], style: .ribbon, segments: 2)))
        #expect(g.vertices.count == 2 * 3 * 2)
        #expect(windingAgreement(g) == 1)
    }

    @Test func specFollowsEndpointEntities() throws {
        let world = World()
        let a = world.spawn(Transform(position: Vec3(0, 4, 0)))
        let b = world.spawn(Transform(position: Vec3(6, 4, 0)))
        let cable = world.spawn(Transform(position: Vec3(0, 0, 0)),
                                LineRenderer(points: [], start: world.ref(to: a), end: world.ref(to: b), sag: 1))
        world.propagateTransforms()
        let line = world.get(LineRenderer.self, for: cable)!
        let s1 = line.spec(in: world, worldToLocal: .identity)
        #expect(s1.points == [Vec3(0, 4, 0), Vec3(6, 4, 0)])
        world.modify(Transform.self, for: b) { $0.position = Vec3(8, 4, 0) }
        world.propagateTransforms()
        let s2 = line.spec(in: world, worldToLocal: .identity)
        #expect(s1 != s2)
        #expect(s2 == line.spec(in: world, worldToLocal: .identity))
    }

    @Test func decodesWithDefaults() throws {
        let line = try JSONDecoder().decode(LineRenderer.self, from: Data("{}".utf8))
        #expect(line == LineRenderer())
        let round = LineRenderer(points: [Vec3(0, 0, 0), Vec3(1, 2, 3)], sag: 2, curve: .parabola, smooth: true, style: .ribbon)
        #expect(try JSONDecoder().decode(LineRenderer.self, from: JSONEncoder().encode(round)) == round)
    }

    @Test func reflectionExposesThePointsList() throws {
        ComponentRegistry.register(LineRenderer.self)
        let world = World()
        let e = world.spawn(LineRenderer(points: [Vec3(0, 0, 0), Vec3(1, 1, 1)]))
        let fields = try #require(world.fields(of: LineRenderer.componentName, for: e))
        let points = try #require(fields.first { $0.name == "points" })
        #expect(points.children.count == 2)
        #expect(fields.first { $0.name == "start" }?.isEntityReference == true)
        #expect(fields.first { $0.name == "curve" } != nil)
    }
}
