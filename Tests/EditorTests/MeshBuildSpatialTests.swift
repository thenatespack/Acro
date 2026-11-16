import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// The mesh build spatial checks (bounds and warnings in every meshBuild.* result), the examples
// and the preview's headless parts (posing, framing, tiling).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSpatialTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

private func warnings(_ parts: [MeshBuildPart], animations: [MeshBuildAnimation] = []) -> [String] {
    MeshBuildCheck.spatial(MeshBuild(parts: parts, animations: animations)).warnings
}

private func box(_ name: String, _ position: Vec3, _ size: Vec3 = Vec3(1, 1, 1), parent: String = "", rotation: Vec3 = .zero,
                 opacity: Float = 1) -> MeshBuildPart {
    MeshBuildPart(name: name, shape: .box, parent: parent, position: position, rotation: rotation, size: size, opacity: opacity)
}

@MainActor
@Suite struct MeshBuildSpatialTests {
    // MARK: Bounds

    @Test func boundsComeFromGeometryThroughTheParentChain() throws {
        // A 2 x 0.2 x 0.2 bar turned upright by its parent's rotation, standing on a 1 m cube.
        let build = MeshBuild(parts: [
            box("Base", Vec3(0, 0.5, 0)),
            MeshBuildPart(name: "Hinge", shape: .group, parent: "Base", position: Vec3(0, 0.5, 0), rotation: Vec3(0, 0, 90)),
            box("Bar", Vec3(1, 0, 0), Vec3(2, 0.2, 0.2), parent: "Hinge"),
        ])
        let (bounds, warnings) = MeshBuildCheck.spatial(build, includeParts: true)
        let b = try #require(bounds)
        #expect(b.size == Vec3(1, 3, 1))
        #expect(b.min == Vec3(-0.5, 0, -0.5) && b.max == Vec3(0.5, 3, 0.5))
        #expect(b.base == 0)
        let bar = try #require(b.parts?.first { $0.part == "Bar" })
        #expect(bar.min == Vec3(-0.1, 1, -0.1) && bar.max == Vec3(0.1, 3, 0.1), "rotated by the group, rounded to mm")
        #expect(b.parts?.contains { $0.part == "Hinge" } == false, "groups have no box")
        #expect(warnings.isEmpty, "\(warnings)")
        #expect(MeshBuildCheck.spatial(build).bounds?.parts == nil, "per-part boxes only on request")
        #expect(MeshBuildCheck.spatial(MeshBuild(parts: [MeshBuildPart(name: "G", shape: .group)])).bounds == nil)
    }

    @Test func partsOfReturnsTheFileParts() {
        let build = MeshBuild(parts: [box("A", .zero), box("B", .zero)])
        #expect(MeshBuildCheck.parts(of: build) == build.parts)
    }

    // MARK: Each warning

    @Test func floatingPartsAreReported() {
        let w = warnings([box("Body", Vec3(0, 0.5, 0)), box("Hat", Vec3(0, 1.75, 0), Vec3(0.5, 0.5, 0.5))])
        #expect(w.count == 1)
        #expect(w.first?.contains("part 'Hat' floats") == true && w.first?.contains("nearest: 'Body', 0.5 m away") == true, "\(w)")
        // A floating group of two touching parts is reported once, naming both.
        let pair = warnings([box("Body", Vec3(0, 0.5, 0)), box("A", Vec3(0, 2, 0), Vec3(0.5, 0.5, 0.5)),
                             box("B", Vec3(0, 2.5, 0), Vec3(0.5, 0.5, 0.5))])
        #expect(pair.count == 1 && pair[0].contains("parts 'A', 'B' float"), "\(pair)")
        // Within the tolerance counts as touching.
        #expect(warnings([box("Body", Vec3(0, 0.5, 0)), box("Hat", Vec3(0, 1.255, 0), Vec3(0.5, 0.5, 0.5))]).isEmpty)
    }

    @Test func partsBelowTheGroundAreReported() {
        let w = warnings([box("Body", Vec3(0, 0.5, 0)), box("Root", Vec3(0, -0.6, 0), Vec3(0.2, 0.2, 0.2))])
        #expect(w.contains { $0.contains("part 'Root' is entirely below the ground") }, "\(w)")
        #expect(w.contains { $0.contains("lowest point is 0.7 m below the ground (part 'Root')") }, "\(w)")
    }

    @Test func aModelOffTheGroundIsReported() {
        let above = warnings([box("Body", Vec3(0, 0.9, 0))])
        #expect(above == ["the lowest point is 0.4 m above the ground; models stand on y=0: move the root parts down 0.4 m (positions are part centers)"])
        let below = warnings([box("Body", Vec3(0, 0, 0))])
        #expect(below.count == 1 && below[0].contains("0.5 m below the ground"), "\(below)")
        #expect(warnings([box("Body", Vec3(0, 0.505, 0))]).isEmpty, "within the tolerance")
    }

    @Test func partsHiddenInsideOpaquePartsAreReported() {
        let w = warnings([box("Body", Vec3(0, 0.5, 0)), box("Core", Vec3(0, 0.5, 0), Vec3(0.3, 0.3, 0.3))])
        #expect(w.count == 1 && w[0].contains("part 'Core' is hidden inside 'Body'"), "\(w)")
        // Inside a sphere's box but poking out of the sphere: not hidden.
        let corner = warnings([MeshBuildPart(name: "Ball", shape: .sphere, position: Vec3(0, 1, 0), size: Vec3(2, 2, 2)),
                               box("Peg", Vec3(0.75, 1.75, 0.75), Vec3(0.3, 0.3, 0.3))])
        #expect(!corner.contains { $0.contains("hidden") }, "\(corner)")
        // Inside a sphere: hidden.
        let inside = warnings([MeshBuildPart(name: "Ball", shape: .sphere, position: Vec3(0, 1, 0), size: Vec3(2, 2, 2)),
                               box("Seed", Vec3(0, 1, 0), Vec3(0.3, 0.3, 0.3))])
        #expect(inside.contains { $0.contains("'Seed' is hidden inside 'Ball'") }, "\(inside)")
    }

    @Test func zeroAndNegativeSizesAreReported() {
        let zero = warnings([box("Body", Vec3(0, 0.5, 0)), box("Sheet", Vec3(0, 1, 0), Vec3(1, 0, 1))])
        #expect(zero.contains { $0.contains("part 'Sheet' has size 0 on y") }, "\(zero)")
        let negative = warnings([box("Body", Vec3(0, 0.5, 0), Vec3(1, -1, 1))])
        #expect(negative.contains { $0.contains("part 'Body' has a negative size on y") }, "\(negative)")
        // A plane ignores size.y, so 0 there is fine.
        #expect(warnings([MeshBuildPart(name: "Rug", shape: .plane, size: Vec3(2, 0, 1))]).isEmpty)
    }

    @Test func partsOutOfScaleAreReported() {
        let big = warnings([box("Seat", Vec3(0, 0.5, 0)), box("Back", Vec3(0, 1.5, 0.4), Vec3(1, 1, 0.2)),
                            box("Leg", Vec3(0, 0.5, 0), Vec3(0.1, 1, 0.1)), box("Cushion", Vec3(0, 50, 0), Vec3(100, 100, 100))])
        #expect(big.contains { $0.contains("part 'Cushion' is 100 m across") }, "\(big)")
        let tiny = warnings([box("Body", Vec3(0, 0.5, 0)), box("Rivet", Vec3(0, 1.0005, 0), Vec3(0.001, 0.001, 0.001))])
        #expect(tiny.contains { $0.contains("part 'Rivet' is only 0.001 m across") }, "\(tiny)")
        let huge = warnings([box("Tower", Vec3(0, 250, 0), Vec3(10, 500, 10))])
        #expect(huge.contains { $0.contains("the model is 500 m across") }, "\(huge)")
    }

    // MARK: Good builds stay quiet

    @Test func aLampWithAPoleAndShadeHasNoWarnings() {
        #expect(warnings([
            MeshBuildPart(name: "Pole", shape: .cylinder, position: Vec3(0, 1, 0), size: Vec3(0.1, 2, 0.1)),
            MeshBuildPart(name: "Shade", shape: .cone, parent: "Pole", position: Vec3(0, 1, 0), opacity: 0.8),
        ]).isEmpty)
    }

    @Test func aCartWithWheelsTouchingTheBodyHasNoWarnings() {
        func wheel(_ x: Float, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: "Wheel \(x) \(z)", shape: .cylinder, parent: "Body", position: Vec3(x, -0.3, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.6, 0.1, 0.6))
        }
        let w = warnings([box("Body", Vec3(0, 0.6, 0), Vec3(1, 0.4, 2)), wheel(-0.55, -0.6), wheel(0.55, -0.6), wheel(-0.55, 0.6),
                          wheel(0.55, 0.6)])
        #expect(w.isEmpty, "\(w)")
    }

    @Test func aGroupPivotWithChildrenHasNoWarnings() {
        let w = warnings([
            box("Post", Vec3(0, 0.5, 0), Vec3(0.2, 1, 0.2)),
            MeshBuildPart(name: "Hinge", shape: .group, parent: "Post", position: Vec3(0, 0.5, 0), rotation: Vec3(0, 30, 0)),
            box("Door", Vec3(0.5, 0.25, 0), Vec3(1, 0.5, 0.05), parent: "Hinge"),
            box("Handle", Vec3(0.4, 0, -0.05), Vec3(0.1, 0.05, 0.05), parent: "Door"),
        ], animations: [MeshBuildAnimation(motions: [MeshBuildMotion(part: "Hinge", kind: .swing)])])
        #expect(w.isEmpty, "\(w)")
    }

    @Test func partsInsideATransparentPartHaveNoWarnings() {
        let w = warnings([
            MeshBuildPart(name: "Dome", shape: .sphere, position: Vec3(0, 0.5, 0), opacity: 0.3),
            box("Figure", Vec3(0, 0.5, 0), Vec3(0.2, 0.4, 0.2)),
            box("Stand", Vec3(0, 0.15, 0), Vec3(0.5, 0.3, 0.5)),
        ])
        #expect(w.isEmpty, "\(w)")
    }

    // MARK: Examples

    @Test func examplesImportWithoutWarnings() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let listed = try call(session, "meshBuild.examples")
        let examples = try #require(listed["examples"] as? [[String: Any]])
        #expect(examples.count == MeshBuildExamples.all.count && examples.count == 13)
        for example in examples {
            let name = try #require(example["name"] as? String)
            let build = try #require(MeshBuildExamples.all.first { $0.name == name }?.build)
            #expect(build.parts.count >= 5, "\(name) reads")
            #expect(MeshBuildCheck.spatial(build).warnings.isEmpty, "\(name): \(MeshBuildCheck.spatial(build).warnings)")
            #expect(build.parts.allSatisfy { $0.shapeWarnings.isEmpty }, "\(name): \(build.parts.flatMap(\.shapeWarnings))")
            let created = try call(session, "meshBuild.new", ["name": name, "build": try #require(example["build"])])
            #expect((created["warnings"] as? [String]) == [], "\(name): \(created["warnings"] ?? "")")
            let bounds = try #require(created["bounds"] as? [String: Any])
            #expect(bounds["base"] as? Double == 0, "\(name) stands on y=0")
            #expect(bounds["parts"] == nil, "meshBuild.new keeps its result short")
            let got = try call(session, "meshBuild.get", ["path": "\(name).meshbuild"])
            #expect(((got["bounds"] as? [String: Any])?["parts"] as? [Any])?.isEmpty == false)
        }
        // The listed builds leave defaults out and read back as the same builds.
        let firstPart = (((examples[0]["build"] as? [String: Any])?["parts"] as? [[String: Any]])?.first) ?? [:]
        #expect(firstPart["name"] != nil && firstPart["opacity"] == nil && firstPart["shape"] != nil)
        for example in MeshBuildExamples.all {
            let compact = try MeshBuildExamplesCommand.compact(example.build)
            #expect(try JSONDecoder().decode(MeshBuild.self, from: JSONEncoder().encode(compact)) == example.build, "\(example.name)")
        }
        #expect(throws: (any Error).self) { try call(session, "meshBuild.examples", ["name": "Spaceship"]) }
        #expect(try call(session, "meshBuild.examples", ["name": "turret"])["examples"].map { ($0 as? [Any])?.count } == 1)
    }

    // MARK: Preview (headless parts)

    @Test func previewSceneFramesPosesAndTiles() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let build = MeshBuildExamples.turret.build
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Turret", build: build))
        let assets = try #require(session.assets)
        let prefab = try #require(assets.prefab(AssetReference(id)))
        let meshes: (MeshHandle) -> MeshGeometry? = { handle in handle.assetReference.flatMap { assets.mesh($0) } }

        let rest = try MeshBuildPreviewScene(build: build, prefab: prefab, views: MeshBuildPreviewScene.defaultViews, tileSize: 200,
                                             labels: true, highlight: ["Barrel"], animation: nil, time: nil, meshes: meshes)
        #expect(rest.views.count == 4)
        #expect(rest.views.allSatisfy { $0.width == 200 && $0.height == 200 && $0.outline.count == 1 })
        #expect(rest.views[0].title.hasPrefix("Front (from -Z)") && rest.views[0].title.hasSuffix("grid 0.25 m"), "\(rest.views[0].title)")
        #expect(abs(rest.lo.y) < 1e-4 && rest.hi.z > 0.4 && rest.lo.z < -1.3, "the barrel points to -Z")
        // The front camera is on the -Z side looking toward +Z.
        let front = rest.views[0].view
        #expect(front.eye.z < rest.lo.z)
        #expect(!rest.views[0].draw.isEmpty, "a grid and labels")

        let posed = try MeshBuildPreviewScene(build: build, prefab: prefab, views: [.top], tileSize: 10, labels: false, highlight: [],
                                              animation: "Scan", time: 1, meshes: meshes)
        #expect(posed.views.count == 1 && posed.views[0].width == MeshBuildPreviewScene.tileSizes.lowerBound)
        let pivot = try #require(posed.parts["Pivot"])
        let turned = try #require(posed.world.get(Transform.self, for: pivot)?.rotation.eulerDegrees.y)
        #expect(abs(turned - 40) < 0.5, "a quarter of the 4 s swing is its 40 degree peak: \(turned)")
        #expect(posed.lo.x < rest.lo.x - 0.2, "the barrel swung toward -X")

        #expect(throws: (any Error).self) {
            try MeshBuildPreviewScene(build: build, prefab: prefab, views: [.front], tileSize: 100, labels: false, highlight: ["Nope"],
                                      animation: nil, time: nil, meshes: meshes)
        }
        #expect(throws: (any Error).self) {
            try MeshBuildPreviewScene(build: build, prefab: prefab, views: [.front], tileSize: 100, labels: false, highlight: [],
                                      animation: "Dance", time: nil, meshes: meshes)
        }

        let tile = Image(width: 4, height: 3, pixels: [UInt8](repeating: 200, count: 48))
        let grid = MeshBuildPreviewScene.compose([tile, tile, tile, tile])
        #expect(grid.width == 10 && grid.height == 8)
        #expect(MeshBuildPreviewScene.compose([tile, tile, tile]).height == 8)
        #expect(MeshBuildPreviewScene.compose([tile]).width == 4)
        #expect(MeshBuildPreviewScene.gridSpacing(for: 3.8) == 0.5 && MeshBuildPreviewScene.gridSpacing(for: 0.3) == 0.05)

        // Headless (no window): the tool says why it can't run.
        #expect(!MeshBuildPreviewCommand.isAvailable(in: session))
        #expect(throws: (any Error).self) { try call(session, "meshBuild.preview", ["asset": id.description]) }
    }
}
