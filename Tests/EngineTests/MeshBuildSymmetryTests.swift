import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Mesh build `mirror` and `repeat`: the expansion into parts, mirrored geometry and animations,
// names, and the importers that read mesh builds (mesh build, character, grid map, terrain).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSymmetryTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "MeshBuildSymmetry")
}

private func approx(_ a: Vec3, _ b: Vec3, _ tolerance: Float = 1e-3) -> Bool { length(a - b) < tolerance }

/// `name`'s transform in the model's space (its parent chain multiplied out).
private func modelMatrix(_ build: MeshBuild, _ name: String) -> Mat4 {
    guard let part = build.parts.first(where: { $0.name == name }) else { return .identity }
    let local = part.transform.matrix
    return part.parent.isEmpty ? local : modelMatrix(build, part.parent) * local
}

/// The triangles of `name`'s mesh in the model's space.
private func triangles(_ build: MeshBuild, _ name: String) -> [(Vec3, Vec3, Vec3)] {
    guard let part = build.parts.first(where: { $0.name == name }), let g = part.geometry() else { return [] }
    let m = modelMatrix(build, name)
    func p(_ i: UInt32) -> Vec3 {
        let v = m * Vec4(g.vertices[Int(i)].position, 1)
        return Vec3(v.x, v.y, v.z)
    }
    return stride(from: 0, to: g.indices.count, by: 3).map { (p(g.indices[$0]), p(g.indices[$0 + 1]), p(g.indices[$0 + 2])) }
}

/// Whether `copy`'s triangles are `original`'s reflected by `d` (same faces, each still wound
/// counter-clockwise seen from outside: reflecting flips the winding back).
private func isReflection(_ build: MeshBuild, _ original: String, _ copy: String, _ d: Vec3) -> Bool {
    let a = triangles(build, original), b = triangles(build, copy)
    guard a.count == b.count, !a.isEmpty else { return false }
    let flips = d.x * d.y * d.z < 0
    return a.allSatisfy { t in
        let (p, q, r) = (t.0 * d, t.1 * d, t.2 * d)
        let wound = flips ? (p, r, q) : (p, q, r)
        return b.contains { u in
            // The same triangle, starting at any corner.
            [(u.0, u.1, u.2), (u.1, u.2, u.0), (u.2, u.0, u.1)].contains { approx($0.0, wound.0) && approx($0.1, wound.1) && approx($0.2, wound.2) }
        }
    }
}

@Suite struct MeshBuildSymmetryTests {
    @Test func mirrorOnEachAxisReflectsTheSubtree() throws {
        for (axis, d) in [(MeshBuildAxis.x, Vec3(-1, 1, 1)), (.y, Vec3(1, -1, 1)), (.z, Vec3(1, 1, -1))] {
            let build = MeshBuild(parts: [
                MeshBuildPart(name: "Body", position: Vec3(0, 1, 0), rotation: Vec3(0, 15, 0)),
                MeshBuildPart(name: "Arm", shape: .wedge, parent: "Body", position: Vec3(0.6, 0.3, 0.2), rotation: Vec3(10, 25, 40),
                              size: Vec3(0.3, 0.8, 0.5), mirror: [axis]),
                MeshBuildPart(name: "Hand", shape: .pyramid, parent: "Arm", position: Vec3(0.1, -0.5, 0.3), rotation: Vec3(-30, 5, 70),
                              size: Vec3(0.2, 0.3, 0.1)),
            ])
            let expansion = build.expansion()
            let names = expansion.build.parts.map(\.name)
            #expect(names == ["Body", "Arm", "Hand", "Arm (mirror \(axis.rawValue))", "Hand (mirror \(axis.rawValue))"])
            #expect(expansion.sources == ["Body", "Arm", "Hand", "Arm", "Hand"] && expansion.warnings.isEmpty)
            let arm = try #require(expansion.build.parts.first { $0.name == "Arm (mirror \(axis.rawValue))" })
            let hand = try #require(expansion.build.parts.first { $0.name == "Hand (mirror \(axis.rawValue))" })
            #expect(arm.parent == "Body" && hand.parent == arm.name, "the subtree hangs from the copy")
            #expect(arm.mirror == nil && arm.reflection == d, "copies don't mirror again")
            #expect(approx(arm.position, Vec3(0.6, 0.3, 0.2) * d), "position negated on the axis")
            // The copy is the original reflected in the parent's (Body's) space, faces still facing out.
            var reflected = expansion.build
            for i in reflected.parts.indices where reflected.parts[i].parent.isEmpty {
                reflected.parts[i].position = .zero
                reflected.parts[i].rotation = .zero
            }
            #expect(isReflection(reflected, "Arm", arm.name, d), "\(axis): the wedge's mirror image")
            #expect(isReflection(reflected, "Hand", hand.name, d), "\(axis): the child's mirror image")
        }
    }

    @Test func mirroredRotationIsAProperRotation() {
        // D·R·D for one axis keeps the angle about that axis and negates the other two.
        for (axis, d) in [(MeshBuildAxis.x, Vec3(-1, 1, 1)), (.y, Vec3(1, -1, 1)), (.z, Vec3(1, 1, -1))] {
            let rotation = Vec3(20, -35, 50)
            let copy = MeshBuild(parts: [MeshBuildPart(name: "P", rotation: rotation, mirror: [axis])]).expanded().parts[1]
            let r = Quat(eulerDegrees: rotation).matrix, c = Quat(eulerDegrees: copy.rotation).matrix
            let dm = Mat4(Vec4(d.x, 0, 0, 0), Vec4(0, d.y, 0, 0), Vec4(0, 0, d.z, 0), Vec4(0, 0, 0, 1))
            let expected = dm * r * dm
            for (a, b) in [(c.c0, expected.c0), (c.c1, expected.c1), (c.c2, expected.c2)] {
                #expect(((a - b) * (a - b)).sum() < 1e-8, "\(axis): \(copy.rotation)")
            }
        }
    }

    @Test func wedgeMirrorVerticesAreAReflection() throws {
        // A wedge's ramp faces +z; mirrored across z it must face -z (no rotation can do that
        // to a wedge turned about y, so the mesh itself is reflected).
        let build = MeshBuild(parts: [MeshBuildPart(name: "Ramp", shape: .wedge, position: Vec3(0, 0, 1), rotation: Vec3(0, 30, 0),
                                                    mirror: [.z])]).expanded()
        let copy = build.parts[1]
        #expect(copy.name == "Ramp (mirror z)" && approx(copy.position, Vec3(0, 0, -1)) && approx(copy.rotation, Vec3(0, -30, 0)))
        let original = try #require(build.parts[0].geometry()), mirrored = try #require(copy.geometry())
        for (v, w) in zip(original.vertices, mirrored.vertices) {
            #expect(approx(w.position, v.position * Vec3(1, 1, -1), 1e-5) && approx(w.normal, v.normal * Vec3(1, 1, -1), 1e-5))
        }
        #expect(isReflection(build, "Ramp", "Ramp (mirror z)", Vec3(1, 1, -1)))
        // Faces still wind outward.
        let center = mirrored.bounds.center
        for t in stride(from: 0, to: mirrored.indices.count, by: 3) {
            let a = mirrored.vertices[Int(mirrored.indices[t])].position, b = mirrored.vertices[Int(mirrored.indices[t + 1])].position
            let c = mirrored.vertices[Int(mirrored.indices[t + 2])].position
            #expect(dot(cross(b - a, c - a), (a + b + c) / 3 - center) >= -1e-6)
        }
    }

    @Test func linearAndRadialRepeat() throws {
        let row = MeshBuild(parts: [MeshBuildPart(name: "Post", position: Vec3(-2, 0.5, 0), repetition: MeshBuildRepeat(count: 4, offset: Vec3(1, 0, 0)))])
            .expanded()
        #expect(row.parts.map(\.name) == ["Post", "Post 2", "Post 3", "Post 4"])
        #expect(row.parts.map(\.position) == [Vec3(-2, 0.5, 0), Vec3(-1, 0.5, 0), Vec3(0, 0.5, 0), Vec3(1, 0.5, 0)])

        // Spokes about the hub's y axis, turning with the ring; each carries its child.
        let wheel = MeshBuild(parts: [
            MeshBuildPart(name: "Hub", shape: .cylinder),
            MeshBuildPart(name: "Spoke", parent: "Hub", position: Vec3(0.3, 0, 0), rotation: Vec3(0, 0, 90),
                          repetition: MeshBuildRepeat(count: 4, radial: .init(axis: .y))),
            MeshBuildPart(name: "Cap", parent: "Spoke", position: Vec3(0, 0.2, 0)),
        ]).expanded()
        #expect(wheel.parts.map(\.name) == ["Hub", "Spoke", "Cap", "Spoke 2", "Cap 2", "Spoke 3", "Cap 3", "Spoke 4", "Cap 4"])
        #expect(wheel.parts.filter { $0.name.hasPrefix("Cap ") }.allSatisfy { $0.position == Vec3(0, 0.2, 0) && $0.parent == "Spoke" + $0.name.dropFirst(3) })
        let spokes = wheel.parts.filter { $0.name.hasPrefix("Spoke") }
        let expected = [Vec3(0.3, 0, 0), Vec3(0, 0, -0.3), Vec3(-0.3, 0, 0), Vec3(0, 0, 0.3)]
        for (k, (spoke, position)) in zip(spokes, expected).enumerated() {
            #expect(approx(spoke.position, position, 1e-4), "\(spoke.name): \(spoke.position)")
            let turn = Quat(angle: Float(k) * .pi / 2, axis: Vec3(0, 1, 0)) * Quat(eulerDegrees: Vec3(0, 0, 90))
            let got = Quat(eulerDegrees: spoke.rotation)
            #expect(abs(abs((turn.vector * got.vector).sum()) - 1) < 1e-4, "\(spoke.name) turns with the ring: \(spoke.rotation)")
        }
        // The cap of each spoke ends up around the ring in model space.
        let cap = modelMatrix(wheel, "Cap 2").c3
        let quarter = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))
        #expect(approx(Vec3(cap.x, cap.y, cap.z), quarter * (Vec3(0.3, 0, 0) + Quat(eulerDegrees: Vec3(0, 0, 90)) * Vec3(0, 0.2, 0)), 1e-4))

        // A 90° arc of 3 bolts centered on the part (both ends included), radius 0.5.
        let arc = MeshBuild(parts: [MeshBuildPart(name: "Bolt", position: Vec3(0, 1, 0),
                                                  repetition: MeshBuildRepeat(count: 3, radial: .init(axis: .y, radius: 0.5, angle: 90)))])
            .expanded()
        let s = Float(0.5).squareRoot() * 0.5
        for (bolt, position) in zip(arc.parts, [Vec3(0.5, 1, 0), Vec3(s, 1, -s), Vec3(0, 1, -0.5)]) {
            #expect(approx(bolt.position, position, 1e-4), "\(bolt.name): \(bolt.position)")
        }
    }

    @Test func repeatThenMirror() {
        let fence = MeshBuild(parts: [
            MeshBuildPart(name: "Left Post", position: Vec3(-1, 0.5, 0), mirror: [.x], repetition: MeshBuildRepeat(count: 3, offset: Vec3(0, 0, 1))),
        ]).expansion()
        #expect(fence.build.parts.map(\.name) == ["Left Post", "Right Post", "Left Post 2", "Right Post 2", "Left Post 3", "Right Post 3"])
        #expect(fence.build.parts.map(\.position) == [Vec3(-1, 0.5, 0), Vec3(1, 0.5, 0), Vec3(-1, 0.5, 1), Vec3(1, 0.5, 1),
                                                       Vec3(-1, 0.5, 2), Vec3(1, 0.5, 2)])
        #expect(fence.copies == ["Right Post", "Left Post 2", "Right Post 2", "Left Post 3", "Right Post 3"])

        // Four legs from one: mirror on two axes makes every combination.
        let chair = MeshBuild(parts: [MeshBuildPart(name: "Front Left Leg", position: Vec3(-0.4, 0.25, 0.4), mirror: [.z, .x])]).expanded()
        #expect(chair.parts.map(\.name) == ["Front Left Leg", "Front Right Leg", "Back Left Leg", "Back Right Leg"])
        #expect(chair.parts.map(\.position) == [Vec3(-0.4, 0.25, 0.4), Vec3(0.4, 0.25, 0.4), Vec3(-0.4, 0.25, -0.4), Vec3(0.4, 0.25, -0.4)])
        #expect(chair.parts[3].reflection == Vec3(-1, 1, -1))
    }

    @Test func animationsFollowTheCopies() throws {
        var build = MeshBuild(parts: [
            MeshBuildPart(name: "Left Arm", position: Vec3(-0.5, 1, 0), mirror: [.x]),
            MeshBuildPart(name: "Blade", parent: "Hub", position: Vec3(1, 0, 0), repetition: MeshBuildRepeat(count: 4, radial: .init())),
            MeshBuildPart(name: "Hub", shape: .group),
        ])
        build.animations = [MeshBuildAnimation(name: "Wave", tracks: [
            MeshBuildTrack(part: "Left Arm", property: .position, keys: [MeshBuildKey(0, .zero), MeshBuildKey(1, Vec3(-0.2, 0.1, 0.3))]),
            MeshBuildTrack(part: "Blade", property: .position, keys: [MeshBuildKey(0, .zero), MeshBuildKey(1, Vec3(0.5, 0, 0))]),
        ], motions: [MeshBuildMotion(part: "Left Arm", kind: .swing, axis: .z, amount: 40)])]
        let expanded = build.expanded()
        func end(_ part: String, _ target: String) -> Float? {
            expanded.animatorTracks(for: part).first { $0.target == target }?.curve.keys.last?.value
        }
        func peak(_ part: String, _ target: String) -> Float? {
            expanded.animatorTracks(for: part).first { $0.target == target }?.curve.keys.map(\.value).max { abs($0) < abs($1) }
        }
        // Mirrored across x: sideways moves and turns about y / z go the other way.
        #expect(end("Left Arm", "Transform.position.x") == -0.2 && end("Right Arm", "Transform.position.x") == 0.2)
        #expect(end("Right Arm", "Transform.position.y") == 0.1 && end("Right Arm", "Transform.position.z") == 0.3)
        #expect(peak("Left Arm", "Transform.rotation.z") == 40 && peak("Right Arm", "Transform.rotation.z") == -40, "a symmetric swing")
        // Turned with the ring: the blade a quarter turn round slides along -z.
        #expect(end("Blade", "Transform.position.x") == 0.5)
        #expect(abs(try #require(end("Blade 2", "Transform.position.z")) + 0.5) < 1e-4)
        #expect(expanded.animatorTracks(for: "Blade 2").allSatisfy { $0.target != "Transform.position.x" || abs($0.curve.keys.last!.value) < 1e-4 })
        // The file's own tracks are untouched; the copies' are added after them.
        #expect(expanded.animations[0].tracks.prefix(2) == build.animations[0].tracks.prefix(2))
        #expect(expanded.animations[0].motions == build.animations[0].motions)
    }

    @Test func namesAreDeterministic() {
        func name(_ n: String, _ axes: [MeshBuildAxis]) -> String {
            MeshBuild(parts: [MeshBuildPart(name: n, mirror: MeshBuildMirror(axes))]).expanded().parts.dropFirst().map(\.name).joined(separator: "|")
        }
        #expect(name("Left Arm", [.x]) == "Right Arm")
        #expect(name("right_eye", [.x]) == "left_eye")
        #expect(name("Arm.L", [.x]) == "Arm.R")
        #expect(name("Leftover", [.x]) == "Leftover (mirror x)", "whole words only")
        #expect(name("Upper Lid", [.y]) == "Lower Lid")
        #expect(name("Front Bumper", [.z]) == "Back Bumper")
        #expect(name("Left Arm", [.z]) == "Left Arm (mirror z)", "Left/Right is the x axis's word")
        #expect(name("Wheel", [.x, .z]) == "Wheel (mirror x)|Wheel (mirror z)|Wheel (mirror xz)")
        #expect(name("Left Wheel", [.x, .z]) == "Right Wheel|Left Wheel (mirror z)|Right Wheel (mirror z)")
        let build = MeshBuild(parts: [MeshBuildPart(name: "Leg", mirror: [.x], repetition: MeshBuildRepeat(count: 3, offset: Vec3(1, 0, 0)))])
        #expect(build.expansion() == build.expansion())
        #expect(build.expanded().expanded() == build.expanded(), "expanding again changes nothing")
        #expect(build.uniquePartName("Leg 2") == "Leg 2 2", "copy names are taken")
        #expect(MeshBuild.starter.expanded() == MeshBuild.starter)
    }

    @Test func nameClashesWarn() {
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Left Arm", position: Vec3(-1, 0, 0), mirror: [.x]),
            MeshBuildPart(name: "Right Arm", position: Vec3(5, 0, 0)),
        ])
        let expansion = build.expansion()
        #expect(expansion.build.parts.map(\.name) == ["Left Arm", "Right Arm", "Right Arm"])
        #expect(expansion.build.parts[1].position == Vec3(5, 0, 0), "the file's part comes first, so it wins")
        #expect(expansion.warnings.count == 1 && expansion.warnings[0].contains("'Left Arm' makes a copy named 'Right Arm'"))

        let big = MeshBuild(parts: [MeshBuildPart(name: "A", repetition: MeshBuildRepeat(count: 1000))]).expansion()
        #expect(big.build.parts.count == MeshBuildRepeat.maxCount && big.warnings.contains { $0.contains("outside 1...256") })
    }

    @Test func fileFormatRoundTrips() throws {
        let json = #"""
        {"parts": [
          {"name": "A", "mirror": "x"},
          {"name": "B", "mirror": ["z", "x"], "repeat": {"count": 3, "offset": [1, 0, 0]}},
          {"name": "C", "repeat": {"count": 6, "radial": {"radius": 0.5}}}
        ]}
        """#
        let build = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(json.utf8))
        #expect(build.parts[0].mirror?.axes == [.x])
        #expect(build.parts[1].mirror?.axes == [.x, .z] && build.parts[1].repetition == MeshBuildRepeat(count: 3, offset: Vec3(1, 0, 0)))
        #expect(build.parts[2].repetition?.radial == MeshBuildRepeat.Radial(axis: .y, radius: 0.5, angle: 360))
        #expect(try AssetJSON.decoder().decode(MeshBuild.self, from: build.fileData()) == build)
        let text = String(decoding: try build.fileData(), as: UTF8.self)
        #expect(text.contains(#""mirror" : "x""#) && text.contains(#""repeat" : {"#) && !text.contains("reflection"))
        let plain = String(decoding: try MeshBuild.starter.fileData(), as: UTF8.self)
        #expect(!plain.contains("mirror") && !plain.contains("repeat"), "parts without copies keep their old form")
    }

    @MainActor @Test func importerMakesANodePerCopy() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let build = MeshBuild(parts: [
            MeshBuildPart(name: "Body", size: Vec3(1, 1, 0.5)),
            MeshBuildPart(name: "Left Arm", shape: .capsule, parent: "Body", position: Vec3(-0.6, 0, 0), mirror: [.x]),
            MeshBuildPart(name: "Left Hand", shape: .sphere, parent: "Left Arm", position: Vec3(0, -0.5, 0)),
            MeshBuildPart(name: "Leg", parent: "Body", position: Vec3(0.3, -0.7, 0), repetition: MeshBuildRepeat(count: 4, radial: .init())),
        ], animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "Left Arm", kind: .swing, axis: .z)])])
        let id = try database.createMeshBuild(build, at: "Models/robot.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        #expect(database.meshBuild(of: id) == build, "the file keeps the short form")
        #expect(record.objects.filter { $0.kind == .mesh }.count == 9, "Body, 2 arms, 2 hands, 4 legs")
        #expect(record.objects.contains { $0.id == "mesh/Right Hand" })

        let prefab = try #require(database.prefab(AssetReference(id)))
        func count(_ node: PrefabNode) -> Int { 1 + node.children.map(count).reduce(0, +) }
        let root = try #require(prefab.roots.first)
        #expect(count(root) == 10, "the root and 9 parts")
        let body = try #require(root.children.first)
        #expect(body.children.map(\.name) == ["Left Arm", "Leg", "Right Arm", "Leg 2", "Leg 3", "Leg 4"])
        let rightArm = try #require(body.children.first { $0.name == "Right Arm" })
        #expect(rightArm.children.map(\.name) == ["Right Hand"] && rightArm.animator?.tracks.count == 1)
        #expect(approx(rightArm.transform.position, Vec3(0.6, 0, 0)))
        let world = World()
        #expect(world.instantiate(prefab).count == 1)
        #expect(world.count(of: FieldAnimator.self) == 2)
    }

    @MainActor @Test func characterPartColorsNameCopies() throws {
        SkeletalAnimation.registerComponents()
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Band", shape: .torus, size: Vec3(0.3, 0.05, 0.3)),
            MeshBuildPart(name: "Left Horn", shape: .cone, parent: "Band", position: Vec3(-0.12, 0.1, 0), rotation: Vec3(0, 0, 20),
                          size: Vec3(0.05, 0.2, 0.05), color: Vec3(1, 1, 1), mirror: [.x]),
            MeshBuildPart(name: "Gem", parent: "Band", position: Vec3(0, 0, 0.15), size: Vec3(repeating: 0.03),
                          repetition: MeshBuildRepeat(count: 3, offset: Vec3(0, 0.04, 0))),
        ]), at: "crown.meshbuild")
        let crown = CharacterAttachment(name: "Crown", bone: "head", asset: "crown.meshbuild",
                                        partColors: ["Right Horn": Vec3(1, 0, 0), "Gem": Vec3(0, 0, 1)])
        let id = try database.createCharacter(CharacterBuild(), at: "hero.character")
        let warnings = try database.writeCharacter(CharacterBuild(attachments: [crown]), to: id)
        #expect(!warnings.contains { $0.contains("partColors") }, "copies are parts: \(warnings)")
        func baseColor(_ part: String) -> Vec4? {
            guard case .material(let m)? = database.object(AssetReference(id, subAsset: "material/Crown \(part)"), kind: .material)?.value else { return nil }
            return m.baseColor
        }
        let red = MeshBuildColor.linear(fromSRGB: Vec3(1, 0, 0))
        #expect(baseColor("Right Horn").map { abs($0.x - red.x) < 1e-5 && $0.y < 1e-5 } == true, "named by its copy name")
        #expect(baseColor("Left Horn").map { $0.y > 0.9 } == true, "the source keeps its own color")
        #expect(baseColor("Gem 3").map { $0.z > 0.9 && $0.x < 1e-5 } == true, "a copy takes its source's entry")
        #expect(database.object(AssetReference(id, subAsset: "mesh/Crown Right Horn"), kind: .mesh) != nil)
    }

    @MainActor @Test func gridMapPiecesAndTerrainScatterIncludeCopies() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createMeshBuild(MeshBuild(parts: [
            MeshBuildPart(name: "Left Post", position: Vec3(-0.8, 0.5, 0), size: Vec3(0.2, 1, 0.2), mirror: [.x]),
        ]), at: "Pieces/Gate.meshbuild")
        var map = GridMap(pieces: [GridPiece(name: "Gate", asset: "Pieces/Gate.meshbuild")])
        map.paint("Gate", at: [GridCoord(0, 0, 0)])
        map.paint("Gate", at: [GridCoord(1, 0, 0)], flipX: true)
        let mapID = try database.createGridMap(map, at: "Levels/gates.gridmap")
        let mapRecord = try #require(database.record(mapID))
        #expect(mapRecord.importError == nil)
        let chunk = try #require(database.prefab(AssetReference(mapID))?.roots.first?.children.first?.children.first)
        func names(_ node: PrefabNode) -> [String] { [node.name] + node.children.flatMap(names) }
        for cell in ["Gate 0,0,0", "Gate 1,0,0"] {
            let node = try #require(chunk.children.first { $0.name == cell })
            #expect(names(node).contains("Left Post") && names(node).contains("Right Post"), "\(cell): \(names(node))")
        }

        var terrain = Terrain.generated(size: Vec2(16, 16), resolution: 9, seed: 1)
        terrain.scatter = [TerrainScatter(name: "Gates", asset: "Pieces/Gate.meshbuild", density: 1, maxSlope: 90, maxCount: 2)]
        let terrainID = try database.createTerrain(terrain, at: "Maps/field.terrain")
        database.refreshAsync()
        database.waitForAll()
        let gate = try #require(database.prefab(AssetReference(terrainID))?.roots.first?.children.last?.children.first?.children.first)
        #expect(gate.children.map(\.name) == ["Left Post", "Right Post"])
        #expect(gate.children[1].mesh?.subAsset == "mesh/Right Post" && approx(gate.children[1].transform.position, Vec3(0.8, 0.5, 0)))
    }
}
