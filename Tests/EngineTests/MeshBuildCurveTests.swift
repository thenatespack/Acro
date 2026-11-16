import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Curved and deformed mesh build geometry: sweep, loft, the deformers and subdivision.

private func weldedIDs(_ g: MeshGeometry) -> [Int] {
    var ids: [SIMD3<Int>: Int] = [:]
    return g.vertices.map { v in
        let key = SIMD3<Int>(Int((v.position.x * 1e4).rounded()), Int((v.position.y * 1e4).rounded()), Int((v.position.z * 1e4).rounded()))
        if let id = ids[key] { return id }
        ids[key] = ids.count
        return ids.count - 1
    }
}

/// Closed and consistently wound once seams are welded: every directed edge once, its reverse once.
private func isClosedManifold(_ g: MeshGeometry) -> Bool {
    let ids = weldedIDs(g)
    var edges: [SIMD2<Int>: Int] = [:]
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = ids[Int(g.indices[t])], b = ids[Int(g.indices[t + 1])], c = ids[Int(g.indices[t + 2])]
        guard a != b, b != c, a != c else { continue }
        for (p, q) in [(a, b), (b, c), (c, a)] { edges[SIMD2(p, q), default: 0] += 1 }
    }
    return !edges.isEmpty && edges.allSatisfy { edge, count in count == 1 && edges[SIMD2(edge.y, edge.x)] == 1 }
}

private func signedVolume(_ g: MeshGeometry) -> Float {
    var v: Float = 0
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let a = g.vertices[Int(g.indices[t])].position, b = g.vertices[Int(g.indices[t + 1])].position
        let c = g.vertices[Int(g.indices[t + 2])].position
        v += dot(a, cross(b, c)) / 6
    }
    return v
}

/// No triangle's face normal points against its corners' normals; normals are unit length.
private func normalsMatchWinding(_ g: MeshGeometry) -> Bool {
    for t in stride(from: 0, to: g.indices.count, by: 3) {
        let v = (0..<3).map { g.vertices[Int(g.indices[t + $0])] }
        let n = cross(v[1].position - v[0].position, v[2].position - v[0].position)
        guard length(n) > 1e-9 else { continue }
        if v.contains(where: { dot($0.normal, normalize(n)) < -0.2 }) { return false }
    }
    return g.vertices.allSatisfy { abs(length($0.normal) - 1) < 1e-3 }
}

private func expectSolid(_ g: MeshGeometry?, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let g else { Issue.record("\(label): no mesh", sourceLocation: sourceLocation); return }
    #expect(!g.indices.isEmpty && g.indices.count % 3 == 0, "\(label): triangles", sourceLocation: sourceLocation)
    #expect(isClosedManifold(g), "\(label): closed", sourceLocation: sourceLocation)
    #expect(signedVolume(g) > 0, "\(label): faces point out", sourceLocation: sourceLocation)
    #expect(normalsMatchWinding(g), "\(label): normals follow the winding", sourceLocation: sourceLocation)
    #expect(g.vertices.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite && $0.position.z.isFinite },
            "\(label): finite", sourceLocation: sourceLocation)
}

private func build(_ part: MeshBuildPart) -> (MeshGeometry?, [String]) {
    var warnings: [String] = []
    let g = part.geometry(warnings: &warnings)
    return (g, warnings)
}

/// The frames along a sweep: each sample's tangent and up, as the generator makes them.
private func frames(_ path: [Vec3], closed: Bool = false) -> [MeshGeometry.PathSample] {
    var samples = path.indices.dropLast().map { i in
        MeshGeometry.PathSample(position: path[i], tangent: normalize(path[i + 1] - path[i]), scale: 1)
    }
    samples.append(MeshGeometry.PathSample(position: path[path.count - 1], tangent: normalize(path[path.count - 1] - path[path.count - 2]),
                                           scale: 1))
    MeshGeometry.frame(&samples, closed: closed)
    return samples
}

@Suite struct MeshBuildCurveTests {
    // MARK: Sweep

    @Test func straightSweepIsACylinder() throws {
        let part = MeshBuildPart(shape: .sweep, segments: 48, path: [Vec3(0, 0, 0), Vec3(0, 0, -2)], radius: 0.1)
        let (g0, w) = build(part)
        #expect(w.isEmpty, "\(w)")
        let g = try #require(g0)
        expectSolid(g, "straight sweep")
        #expect(abs(signedVolume(g) - .pi * 0.01 * 2) < 0.002)
        #expect(length(g.bounds.halfExtent - Vec3(0.1, 0.1, 1)) < 1e-3 && length(g.bounds.center - Vec3(0, 0, -1)) < 1e-3)
        #expect(length(part.localBounds.halfExtent - g.bounds.halfExtent) < 1e-6, "localBounds is the mesh's")
        // Sides point straight out from the axis; the 90° rims stay hard (caps point along it).
        for v in g.vertices where abs(v.position.z) > 0.01 && abs(v.position.z + 2) > 0.01 {
            #expect(abs(dot(v.normal, normalize(Vec3(v.position.x, v.position.y, 0))) - 1) < 1e-3)
        }
        #expect(g.vertices.contains { abs($0.position.z) < 1e-5 && abs($0.normal.z - 1) < 1e-4 })
    }

    @Test func curvedSweepIsSmoothAndFollowsThePath() throws {
        let path = [Vec3(0, 0, 0), Vec3(0, 0.5, 0), Vec3(0.3, 0.8, 0), Vec3(0.8, 0.8, 0.2)]
        let part = MeshBuildPart(shape: .sweep, segments: 16, path: path, radius: 0.04)
        let (g0, w) = build(part)
        #expect(w.isEmpty)
        let g = try #require(g0)
        expectSolid(g, "curved sweep")
        // The spline passes through every point: some ring's center is at each.
        for p in path {
            let near = g.vertices.filter { abs(length($0.position - p) - 0.04) < 2e-3 }
            #expect(near.count >= 8, "a ring around \(p)")
        }
        // More rings where it turns than one per span.
        #expect(g.vertices.count > 16 * 8)
        // Smooth along: no welded position carries two normals on the sides.
        let ids = weldedIDs(g)
        var normals: [Int: Vec3] = [:]
        var split = 0
        for (i, id) in ids.enumerated() where abs(g.vertices[i].normal.y) < 0.9 || g.vertices[i].position.y > 0.01 {
            if let n = normals[id], length(n - g.vertices[i].normal) > 0.05 { split += 1 } else { normals[id] = g.vertices[i].normal }
        }
        #expect(split <= 2 * 17, "only the caps' rims are split, \(split)")
    }

    @Test func framesNeverFlipOnAVerticalOrTwistyPath() throws {
        // Straight up, then over and down: the frame's up must turn continuously.
        var path: [Vec3] = []
        for k in 0...40 {
            let a = Float(k) / 40 * .pi
            path.append(Vec3(0, 0, 0) + (k < 1 ? .zero : Vec3(0.5 - 0.5 * cosf(a), 1 + 0.5 * sinf(a), 0)))
        }
        path.insert(Vec3(0, -1, 0), at: 0)
        for samples in [frames(path), frames([Vec3(0, 0, 0), Vec3(0, 1, 0), Vec3(0, 2, 0)])] {
            for i in 1..<samples.count {
                #expect(dot(samples[i].up, samples[i - 1].up) > 0.9, "frame \(i) jumps")
                #expect(abs(dot(samples[i].up, samples[i].tangent)) < 1e-4)
            }
        }
        // A helix: the frames turn smoothly all the way.
        let helix = (0...60).map { k -> Vec3 in
            let a = Float(k) / 60 * 4 * .pi
            return Vec3(cosf(a), Float(k) / 30, sinf(a))
        }
        let h = frames(helix)
        for i in 1..<h.count { #expect(dot(h[i].up, h[i - 1].up) > 0.95) }
        // The vertical sweep builds and its sides are continuous.
        let g = MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0), Vec3(0, 2, 0)], radius: 0.1).geometry()
        expectSolid(g, "vertical sweep")
        #expect(abs((g?.bounds.halfExtent.y ?? 0) - 1) < 1e-4)
    }

    @Test func closedSweepIsARing() throws {
        let path = (0..<8).map { k -> Vec3 in
            let a = Float(k) / 8 * 2 * .pi
            return Vec3(cosf(a), 0, sinf(a))
        }
        let (g0, w) = build(MeshBuildPart(shape: .sweep, segments: 16, path: path, radius: 0.1, closed: true))
        #expect(w.isEmpty)
        let g = try #require(g0)
        expectSolid(g, "ring")
        // A torus of R 1, r 0.1: volume 2π²Rr²; the spline through 8 points is nearly a circle.
        #expect(abs(signedVolume(g) - 2 * .pi * .pi * 0.01) < 0.01, "\(signedVolume(g))")
        #expect(abs(g.bounds.halfExtent.x - 1.1) < 0.02 && abs(g.bounds.halfExtent.y - 0.1) < 1e-3)
        // A square loop of straight segments (mitred corners) is closed too, with hard corners.
        let square = [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(1, 0, 1), Vec3(0, 0, 1)]
        let frame = MeshBuildPart(shape: .sweep, path: square, radius: 0.05, closed: true, smooth: false).geometry()
        expectSolid(frame, "square loop")
        #expect(abs(signedVolume(try #require(frame)) - 4 * 0.99 * .pi * 0.0025) < 0.002)
        // A closed path that repeats its first point at the end is the same loop.
        let repeated = MeshBuildPart(shape: .sweep, path: square + [square[0]], radius: 0.05, closed: true, smooth: false).geometry()
        #expect(repeated?.vertices.count == frame?.vertices.count)
    }

    @Test func straightSweepHasMitredCorners() throws {
        let path = [Vec3(0, 0, 0), Vec3(0, 1, 0), Vec3(1, 1, 0)]
        let g = try #require(MeshBuildPart(shape: .sweep, path: path, radius: 0.1, smooth: false).geometry())
        expectSolid(g, "elbow")
        // The corner's rings lie on the mitre plane x + y = 1.
        let corner = g.vertices.filter { abs($0.position.x + $0.position.y - 1) < 1e-4 && $0.position.y > 0.85 }
        #expect(corner.count >= 2 * 24)
        // Hard: the incoming side's normals are level (no y), the outgoing side's have no x.
        #expect(corner.contains { abs($0.normal.x) > 0.3 && abs($0.normal.y) < 1e-3 })
        #expect(corner.contains { abs($0.normal.y) > 0.3 && abs($0.normal.x) < 1e-3 })
        #expect(abs(g.bounds.center.y + g.bounds.halfExtent.y - 1.1) < 1e-3, "the outside of the corner reaches 1.1")
    }

    @Test func taperedSweepShrinksToAPoint() throws {
        let path = [Vec3(0, 0, 0), Vec3(0, 0.5, 0), Vec3(0.2, 0.9, 0)]
        let part = MeshBuildPart(shape: .sweep, segments: 16, path: path, radius: 0.1, radii: [1, 0.5, 0])
        let (g0, w) = build(part)
        #expect(w.isEmpty)
        let g = try #require(g0)
        expectSolid(g, "horn")
        // Full at the base, half at the middle point, a point at the tip.
        let base = g.vertices.filter { abs($0.position.y) < 1e-5 }.map { length(Vec3($0.position.x, 0, $0.position.z)) }.max() ?? 0
        #expect(abs(base - 0.1) < 1e-4)
        let middle = g.vertices.filter { abs(length($0.position - path[1]) - 0.05) < 2e-3 }
        #expect(middle.count >= 8)
        let tip = g.vertices.filter { length($0.position - path[2]) < 1e-5 }
        #expect(tip.count >= 16, "the ring at the tip collapses to the point")
        // radii with the wrong count warns and pads with 1.
        let (padded, w2) = build(MeshBuildPart(shape: .sweep, path: path, radius: 0.1, radii: [0.5]))
        #expect(padded != nil && w2.contains { $0.contains("radii has 1 values for 3") })
    }

    @Test func profileSweepKeepsCornersAndUp() throws {
        // A rail: a 0.1 x 0.04 rectangle along +X; its height (y) stays vertical.
        let rect = [Vec2(-0.05, -0.02), Vec2(0.05, -0.02), Vec2(0.05, 0.02), Vec2(-0.05, 0.02)]
        let g = try #require(MeshBuildPart(shape: .sweep, profile: rect, path: [Vec3(0, 0, 0), Vec3(2, 0, 0)]).geometry())
        expectSolid(g, "rail")
        #expect(abs(g.bounds.halfExtent.y - 0.02) < 1e-5 && abs(g.bounds.halfExtent.z - 0.05) < 1e-5, "profile y is up, x across")
        #expect(!g.vertices.contains { abs($0.normal.y) > 0.01 && abs($0.normal.z) > 0.01 }, "corners stay hard")
    }

    @Test func badSweepsWarnInsteadOfCrashing() {
        let cases: [(MeshBuildPart, String)] = [
            (MeshBuildPart(shape: .sweep), "at least 2"),
            (MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0)]), "at least 2"),
            (MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 0, 0)]), "at least 2"),
            (MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0)], radius: 0), "radius > 0"),
            (MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0)], radius: .nan), "radius > 0"),
            (MeshBuildPart(shape: .sweep, profile: [Vec2(0, 0), Vec2(1, 0)], path: [Vec3(0, 0, 0), Vec3(0, 1, 0)]), "at least 3"),
            (MeshBuildPart(shape: .sweep, profile: [Vec2(0, 0), Vec2(2, 2), Vec2(2, 0), Vec2(0, 1)], path: [Vec3(0, 0, 0), Vec3(0, 1, 0)]),
             "crosses itself"),
        ]
        for (part, phrase) in cases {
            let (g, w) = build(part)
            #expect(g == nil, "\(phrase): nothing built")
            #expect(w.contains { $0.contains(phrase) }, "\(phrase): \(w)")
            #expect(part.shapeWarnings == w)
        }
        // NaN points are dropped; a 2-point closed path stays open; self-overlap just renders.
        let (g1, w1) = build(MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(.nan, 0, 0), Vec3(0, 1, 0)]))
        #expect(g1 != nil && w1.count == 1 && w1[0].contains("aren't numbers"))
        let (g2, w2) = build(MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0)], closed: true))
        #expect(g2 != nil && w2.contains { $0.contains("left open") })
        let knot = (0..<12).map { k -> Vec3 in
            let a = Float(k) / 12 * 2 * .pi
            return Vec3(sinf(a) + 2 * sinf(2 * a), cosf(a) - 2 * cosf(2 * a), -sinf(3 * a)) * 0.2
        }
        let (g3, w3) = build(MeshBuildPart(shape: .sweep, path: knot + knot, radius: 0.3, radii: [-1] + Array(repeating: 1, count: 23), closed: true))
        #expect(g3 != nil && w3.count == 1 && w3[0].contains("≥ 0"))
        // A U-turn and a straight path doubling back don't blow up.
        let (g4, _) = build(MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 0, 0.001)], smooth: false))
        #expect(g4.map { $0.bounds.halfExtent.x < 2 } == true)
        // Fields a shape ignores are pointed out.
        #expect(MeshBuildPart(shape: .box, path: [Vec3(0, 0, 0)], radius: 1).shapeWarnings.first?.contains("path, radius only shape sweep") == true)
        #expect(MeshBuildPart(shape: .sweep, sections: []).shapeWarnings.contains { $0.contains("sections only shape loft") })
        #expect(MeshBuildPart(shape: .box, smooth: true).shapeWarnings.first?.contains("smooth") == true)
        #expect(MeshBuildPart(shape: .sweep, profile: [Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)]).fieldWarnings.isEmpty, "profile is a sweep's")
    }

    // MARK: Loft

    @Test func loftSuperellipseRoundness() throws {
        // At 1 the section is an ellipse: its points satisfy (x/a)² + (z/b)² = 1.
        let ellipse = MeshGeometry.superellipse(half: Vec2(0.5, 0.25), roundness: 1, count: 32)
        #expect(ellipse.allSatisfy { abs(powf($0.x / 0.5, 2) + powf($0.y / 0.25, 2) - 1) < 1e-4 })
        // At 0 it is a diamond: |x|/a + |y|/b = 1.
        let diamond = MeshGeometry.superellipse(half: Vec2(0.5, 0.25), roundness: 0, count: 32)
        #expect(diamond.allSatisfy { abs(abs($0.x) / 0.5 + abs($0.y) / 0.25 - 1) < 1e-4 })
        // Rounder → more area, approaching the box's.
        func area(_ r: Float) -> Float {
            abs(MeshGeometry.doubleSignedArea(MeshGeometry.superellipse(half: Vec2(0.5, 0.5), roundness: r, count: 256))) / 2
        }
        #expect(abs(area(0) - 0.5) < 0.01 && abs(area(1) - .pi / 4) < 0.01)
        #expect(area(0) < area(1) && area(1) < area(2) && area(2) < area(3) && area(3) < area(5) && area(5) > 0.97 && area(5) <= 1)
        // Every value builds a closed loft.
        for r: Float in [0, 0.5, 1, 2, 3, 4, 6] {
            let part = MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0, size: Vec2(1, 0.6), roundness: r),
                                                              MeshBuildSection(at: 1, size: Vec2(1, 0.6), roundness: r)])
            expectSolid(part.geometry(), "loft roundness \(r)")
        }
    }

    @Test func loftInterpolatesItsSections() throws {
        // A bottle: wide body, shoulder, narrow neck. Along Y, sections [x, z].
        let sections = [MeshBuildSection(at: 0, size: Vec2(0.4, 0.2)), MeshBuildSection(at: 0.3, size: Vec2(0.4, 0.2)),
                        MeshBuildSection(at: 0.4, size: Vec2(0.1, 0.1)), MeshBuildSection(at: 0.55, size: Vec2(0.1, 0.1))]
        let part = MeshBuildPart(shape: .loft, segments: 32, sections: sections)
        let (g0, w) = build(part)
        #expect(w.isEmpty, "\(w)")
        let g = try #require(g0)
        expectSolid(g, "bottle")
        #expect(abs(g.bounds.halfExtent.x - 0.2) < 1e-4 && abs(g.bounds.halfExtent.z - 0.1) < 1e-4)
        #expect(abs(g.bounds.center.y - g.bounds.halfExtent.y) < 1e-5 && abs(g.bounds.center.y + g.bounds.halfExtent.y - 0.55) < 1e-5)
        // Through every section, and monotone between them: never wider than the widest or past the neck.
        func width(at y: Float) -> Float {
            g.vertices.filter { abs($0.position.y - y) < 1e-4 }.map { abs($0.position.x) }.max() ?? -1
        }
        #expect(abs(width(at: 0.3) - 0.2) < 1e-4 && abs(width(at: 0.4) - 0.05) < 1e-4)
        #expect(g.vertices.allSatisfy { $0.position.y < 0.4 - 1e-4 || abs($0.position.x) <= 0.05 + 1e-4 }, "no bulge in the neck")
        #expect(g.vertices.allSatisfy { abs($0.position.x) <= 0.2 + 1e-4 }, "no overshoot past the body")
        // Between the body and the neck there are interpolated rings narrowing smoothly.
        let shoulder = Set(g.vertices.filter { $0.position.y > 0.301 && $0.position.y < 0.399 }.map { $0.position.y })
        #expect(shoulder.count >= 5)
        // Straight: rings only at the sections, with a crease kept at the 0.3 shoulder.
        let straight = try #require(MeshBuildPart(shape: .loft, segments: 32, smooth: false, sections: sections).geometry())
        expectSolid(straight, "straight bottle")
        #expect(Set(straight.vertices.map { $0.position.y }).count == 4)
        // Sections may come in any order and with centers; along z with [x, y] sizes.
        let hull = MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 2, size: Vec2(1, 0.5)),
                                                          MeshBuildSection(center: Vec3(0, 0.3, -2), size: Vec2(0, 0)),
                                                          MeshBuildSection(at: 0, size: Vec2(1.2, 0.6), roundness: 3)], axis: .z)
        let h = try #require(hull.geometry())
        expectSolid(h, "hull")
        #expect(abs(h.bounds.halfExtent.z - 2) < 1e-4 && abs(h.bounds.halfExtent.x - 0.6) < 1e-3 && abs(h.bounds.halfExtent.y - 0.3) < 0.02)
        #expect(h.vertices.contains { length($0.position - Vec3(0, 0.3, -2)) < 1e-5 }, "the bow is the point section")
        // Along x, size is [z, y].
        let xLoft = try #require(MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0, size: Vec2(0.4, 0.2)),
                                                                        MeshBuildSection(at: 1, size: Vec2(0.4, 0.2))], axis: .x).geometry())
        expectSolid(xLoft, "x loft")
        #expect(abs(xLoft.bounds.halfExtent.z - 0.2) < 1e-3 && abs(xLoft.bounds.halfExtent.y - 0.1) < 1e-3)
    }

    @Test func loftProfilesKeepCorners() throws {
        // Two squares of 4 points: used as written, so the corners stay exact and hard.
        let square = [Vec2(-0.5, -0.5), Vec2(0.5, -0.5), Vec2(0.5, 0.5), Vec2(-0.5, 0.5)]
        let part = MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0, profile: square),
                                                          MeshBuildSection(at: 1, size: Vec2(0.5, 0.5), profile: square)])
        let g = try #require(part.geometry())
        expectSolid(g, "frustum")
        #expect(abs(signedVolume(g) - (1 + 0.25 + 0.5) / 3) < 1e-4, "a square frustum's volume")
        #expect(!g.vertices.contains { abs($0.normal.x) > 0.01 && abs($0.normal.z) > 0.01 }, "the 90° corners stay hard")
        // Mixed with an ellipse: the profile is resampled to `segments`.
        let mixed = MeshBuildPart(shape: .loft, segments: 20, sections: [MeshBuildSection(at: 0, profile: square),
                                                                         MeshBuildSection(at: 1, size: Vec2(1, 1))])
        expectSolid(mixed.geometry(), "square to round")
    }

    @Test func badLoftsWarn() {
        let cases: [(MeshBuildPart, String)] = [
            (MeshBuildPart(shape: .loft), "at least 2 sections"),
            (MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0)]), "at least 2 sections"),
            (MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0), MeshBuildSection(at: 0)]), "same place"),
            (MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: .nan), MeshBuildSection(at: 1)]), "isn't a number"),
        ]
        for (part, phrase) in cases {
            let (g, w) = build(part)
            #expect(g == nil, "\(phrase)")
            #expect(w.contains { $0.contains(phrase) }, "\(phrase): \(w)")
        }
        let (g, w) = build(MeshBuildPart(shape: .loft, sections: [
            MeshBuildSection(at: 0, size: Vec2(.nan, 1), roundness: .infinity),
            MeshBuildSection(at: 1, profile: [Vec2(0, 0), Vec2(1, 0)])]))
        #expect(g != nil && w.count == 3, "\(w)")
    }

    // MARK: Deformers

    @Test func bendTurnsTheTopByItsAngle() throws {
        for degrees: Float in [30, 90, -45] {
            let part = MeshBuildPart(shape: .box, size: Vec3(0.2, 2, 0.2), deform: [.bend(.x, degrees)])
            let (g0, w) = build(part)
            #expect(w.isEmpty)
            let g = try #require(g0)
            expectSolid(g, "bent box \(degrees)")
            // The top face's normal leans `degrees` toward +x.
            let theta = degrees * .pi / 180
            let top = g.vertices.filter { dot($0.normal, Vec3(sinf(theta), cosf(theta), 0)) > 0.999 }
            #expect(top.count >= 4, "\(degrees)°: a face turned to the bend")
            // The length along the middle is kept: the top center is on the arc of radius h/θ.
            let r = 2 / theta
            let expected = Vec3(r - r * cosf(theta), -1 + r * sinf(theta), 0)
            #expect(g.vertices.contains { length($0.position - (expected + Vec3(0.1 * cosf(theta), -0.1 * sinf(theta), 0))) < 0.02 })
            #expect(abs(signedVolume(g) - 0.08) < 0.002, "volume kept \(signedVolume(g))")
        }
        // Toward z.
        let z = try #require(MeshBuildPart(shape: .cylinder, size: Vec3(0.2, 1, 0.2), deform: [.bend(.z, 60)]).geometry())
        #expect(z.bounds.center.z > 0.1 && abs(z.bounds.center.x) < 1e-3)
        expectSolid(z, "bent cylinder")
    }

    @Test func twistTaperAndHardEdges() throws {
        let twisted = try #require(MeshBuildPart(shape: .box, size: Vec3(1, 2, 1), deform: [.twist(90)]).geometry())
        expectSolid(twisted, "twisted box")
        // The top corners are turned 90° about Y; the bottom ones are not.
        let topCorner = twisted.vertices.filter { abs($0.position.y - 1) < 1e-5 }.map(\.position)
        #expect(topCorner.contains { length($0 - Vec3(0.5, 1, -0.5)) < 1e-4 } && topCorner.contains { length($0 - Vec3(-0.5, 1, 0.5)) < 1e-4 })
        #expect(twisted.vertices.contains { length($0.position - Vec3(0.5, -1, 0.5)) < 1e-4 })
        // Hard edges stay hard: the top face is flat-shaded straight up.
        #expect(twisted.vertices.filter { abs($0.position.y - 1) < 1e-5 && $0.normal.y > 0.5 }.allSatisfy { $0.normal.y > 0.999 })
        #expect(abs(signedVolume(twisted) - 2) < 0.05)

        let tapered = try #require(MeshBuildPart(shape: .cylinder, size: Vec3(1, 1, 1), deform: [.taper(0.5, 0.25)]).geometry())
        expectSolid(tapered, "tapered cylinder")
        let top = tapered.vertices.filter { abs($0.position.y - 0.5) < 1e-5 }
        #expect(abs((top.map { $0.position.x }.max() ?? 0) - 0.25) < 1e-3 && abs((top.map { $0.position.z }.max() ?? 0) - 0.125) < 1e-3)
        let bottom = tapered.vertices.filter { abs($0.position.y + 0.5) < 1e-5 }
        #expect(abs((bottom.map { $0.position.x }.max() ?? 0) - 0.5) < 1e-3)
        // The tapered side's normals lean up.
        #expect(tapered.vertices.filter { abs($0.position.y) < 0.4 && abs($0.normal.y) < 0.9 }.allSatisfy { $0.normal.y > 0.05 })
    }

    @Test func noiseIsDeterministicBySeedAndStaysClosed() throws {
        func rock(_ seed: Int) -> MeshGeometry? {
            MeshBuildPart(shape: .sphere, size: Vec3(1, 1, 1), segments: 16, deform: [.noise(0.08, scale: 0.3, seed: seed)]).geometry()
        }
        let a = try #require(rock(1)), b = try #require(rock(1)), c = try #require(rock(2))
        expectSolid(a, "rock")
        #expect(a.vertices == b.vertices, "same seed, same rock")
        #expect(a.vertices.map(\.position) != c.vertices.map(\.position), "another seed, another rock")
        let radii = a.vertices.map { length($0.position) }
        #expect((radii.max() ?? 0) - (radii.min() ?? 0) > 0.04 && (radii.max() ?? 1) < 0.5 + 0.081 && (radii.min() ?? 0) > 0.5 - 0.081)
        // A noisy box keeps its edges closed (corners move together).
        expectSolid(MeshBuildPart(shape: .box, deform: [.noise(0.05, scale: 0.2)]).geometry(), "dented box")
        // Noise is part-space: a mirror copy is the mirror image.
        let part = MeshBuildPart(shape: .box, position: Vec3(1, 0, 0), mirror: [.x],
                                 deform: [.noise(0.05, scale: 0.2, seed: 3), .bend(.x, 20)])
        let copies = MeshBuild(parts: [part]).expanded().parts
        let original = try #require(copies[0].geometry()), mirrored = try #require(copies[1].geometry())
        #expect(zip(original.vertices, mirrored.vertices).allSatisfy {
            length($0.position * Vec3(-1, 1, 1) - $1.position) < 1e-5
        })
        expectSolid(mirrored, "mirrored deformed box")
    }

    @Test func subdivisionSplitsEvenly() throws {
        var g = MeshGeometry.cube(size: 1)
        g.subdivide(maxEdge: 0.3, maxTriangles: 100_000)
        expectSolid(g, "subdivided cube")
        #expect(abs(signedVolume(g) - 1) < 1e-5, "flat subdivision keeps the shape")
        for t in stride(from: 0, to: g.indices.count, by: 3) {
            let p = (0..<3).map { g.vertices[Int(g.indices[t + $0])].position }
            #expect(length(p[1] - p[0]) <= 0.3 + 1e-5 && length(p[2] - p[1]) <= 0.3 + 1e-5 && length(p[0] - p[2]) <= 0.3 + 1e-5)
        }
        // The budget stops it early, still closed.
        var capped = MeshGeometry.cube(size: 1)
        capped.subdivide(maxEdge: 0.001, maxTriangles: 2000)
        #expect(capped.indices.count / 3 <= 2000 && capped.indices.count / 3 > 12)
        expectSolid(capped, "capped")
        // The part's level: 0 is off, higher is finer; the default is 3.
        func triangles(_ level: Int?) -> Int {
            (MeshBuildPart(shape: .box, deform: [.twist(10)], subdivide: level).geometry()?.indices.count ?? 0) / 3
        }
        #expect(triangles(0) == 12 && triangles(1) < triangles(2) && triangles(2) < triangles(nil) && triangles(nil) == triangles(3))
        #expect(triangles(6) <= MeshBuildPart.maxDeformTriangles)
    }

    @Test func deformWarnings() {
        let cases: [(MeshBuildPart, String)] = [
            (MeshBuildPart(shape: .group, deform: [.twist(10)]), "group has no mesh"),
            (MeshBuildPart(shape: .box, deform: [MeshBuildDeform()]), "none of taper"),
            (MeshBuildPart(shape: .box, deform: [.bend(.y, 10)]), "bend axis must be x or z"),
            (MeshBuildPart(shape: .box, deform: [.taper(-1, 1)]), "taper must be"),
            (MeshBuildPart(shape: .box, deform: [.noise(0.1, scale: 0)]), "scale > 0"),
            (MeshBuildPart(shape: .box, deform: [.twist(.nan)]), "twist must be"),
            (MeshBuildPart(shape: .box, subdivide: 2), "only matters with deform"),
            (MeshBuildPart(shape: .box, deform: [.twist(5)], subdivide: 9), "0...6"),
        ]
        for (part, phrase) in cases {
            #expect(part.shapeWarnings.contains { $0.contains(phrase) }, "\(phrase): \(part.shapeWarnings)")
            var w: [String] = []
            let g = part.geometry(warnings: &w)
            #expect(part.shape == .group ? g == nil : g != nil)
            #expect(g?.vertices.allSatisfy { $0.position.x.isFinite && $0.normal.x.isFinite } ?? true)
        }
        #expect(MeshBuildPart(shape: .box, deform: [.twist(5), .noise(0.01, scale: 0.1)]).shapeWarnings.isEmpty)
    }

    @Test func deformedBoundsAndCurves() throws {
        // localBounds follows the deformed mesh, so stacking and spatial checks see the bend.
        let part = MeshBuildPart(shape: .cylinder, size: Vec3(0.2, 2, 0.2), deform: [.bend(.x, 90)])
        let b = part.localBounds
        #expect(b.center.x + b.halfExtent.x > 1.2, "it reaches out sideways")
        // Deform works on sweeps and lofts too.
        expectSolid(MeshBuildPart(shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0)], radius: 0.1, deform: [.bend(.z, 45)]).geometry(),
                    "bent sweep")
        expectSolid(MeshBuildPart(shape: .loft, sections: [MeshBuildSection(at: 0), MeshBuildSection(at: 1)], deform: [.twist(45)]).geometry(),
                    "twisted loft")
        // Every primitive survives every deformer closed.
        for shape in [MeshBuildShape.sphere, .capsule, .torus, .tube, .wedge, .pyramid, .cone, .hemisphere] {
            let g = MeshBuildPart(shape: shape, segments: 12, deform: [.taper(0.7, 0.7), .twist(30), .bend(.x, 30), .noise(0.02, scale: 0.3)])
                .geometry()
            expectSolid(g, "deformed \(shape)")
        }
    }

    // MARK: File

    @Test func curveFieldsRoundTripAndStayOutOfOldFiles() throws {
        let plain = MeshBuild(parts: [MeshBuildPart(name: "Crate")])
        let plainJSON = String(decoding: try plain.fileData(), as: UTF8.self)
        for key in ["path", "radius", "radii", "closed", "smooth", "sections", "axis", "deform", "subdivide"] {
            #expect(!plainJSON.contains("\"\(key)\""), "\(key) isn't written by default")
        }
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Pipe", shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0)], radius: 0.1, radii: [1, 0.5], closed: false,
                          smooth: false),
            MeshBuildPart(name: "Hull", shape: .loft, sections: [MeshBuildSection(at: 0, size: Vec2(1, 2), roundness: 3),
                                                                 MeshBuildSection(center: Vec3(0, 1, 2), profile: [Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)])],
                          axis: .z),
            MeshBuildPart(name: "Rock", deform: [.taper(0.5, 1), .bend(.z, 20), .twist(45), .noise(0.1, scale: 0.3, seed: 7)], subdivide: 4),
        ])
        let data = try build.fileData()
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: data) == build)
        // Through the tools' JSON (meshBuild.edit re-encodes parts) too.
        #expect(try JSONDecoder().decode(MeshBuild.self, from: JSONEncoder().encode(build)) == build)

        let lenient = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(#"""
            {"parts": [
              {"shape": "loft", "sections": [{"at": 0.5}, {"at": [0, 1, 0.2], "size": [1, 1]}, {}]},
              {"shape": "box", "deform": {"twist": 30}},
              {"shape": "box", "deform": [{"taper": 0.5}, {"bend": 20}, {"noise": 0.05}, {"bend": {"axis": "z"}}, {"noise": {"seed": 2.0}}]},
              {"shape": "sweep", "radius": "big", "closed": 1}
            ]}
            """#.utf8))
        let s = try #require(lenient.parts[0].sections)
        #expect(s[0].at == .along(0.5) && s[1].at == .point(Vec3(0, 1, 0.2)) && s[2].at == .along(0) && s[2].size == nil)
        #expect(lenient.parts[1].deform == [.twist(30)])
        #expect(lenient.parts[2].deform == [.taper(0.5, 0.5), .bend(.x, 20), MeshBuildDeform(noise: .init(amount: 0.05)), .bend(.z, 30),
                                            MeshBuildDeform(noise: .init(seed: 2))])
        #expect(lenient.parts[3].radius == nil && lenient.parts[3].closed == nil)
    }

    @MainActor @Test func importerBuildsCurvesAndReportsTheirWarnings() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildCurveTests-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: url, name: "MeshBuildCurves")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let good = MeshBuild(parts: [
            MeshBuildPart(name: "Pipe", shape: .sweep, path: [Vec3(0, 0, 0), Vec3(0, 1, 0), Vec3(1, 1, 0)], radius: 0.05),
            MeshBuildPart(name: "Bottle", shape: .loft, sections: [MeshBuildSection(at: 0), MeshBuildSection(at: 1)]),
            MeshBuildPart(name: "Stump", shape: .cylinder, deform: [.noise(0.05, scale: 0.2)]),
        ])
        let id = try database.createMeshBuild(good, at: "Models/curves.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        #expect(database.record(id)?.objects.filter { $0.kind == .mesh }.count == 3)
        var bad = good
        bad.parts.append(MeshBuildPart(name: "Cable", shape: .sweep, path: [Vec3(0, 0, 0)]))
        let warnings = try database.writeMeshBuild(bad, to: id)
        #expect(warnings.contains { $0.contains("part 'Cable'") && $0.contains("at least 2") }, "\(warnings)")
        #expect(database.record(id)?.objects.filter { $0.kind == .mesh }.count == 3)
    }
}
