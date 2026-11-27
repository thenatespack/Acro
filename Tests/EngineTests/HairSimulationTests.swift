import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineRendering

// Hair dynamics (HairSimulation.swift, SceneRenderer+HairSim.swift) and the fur meshes built on
// background jobs (SceneRenderer+Fur.swift).

/// A head: a sphere with the hair cut away below the ears, colliders for the head, neck and shoulders.
private func hairOnHead() -> (base: MeshGeometry, fur: MaterialFur) {
    var hair = GroomBuild.preset("straightHair")!
    hair.length = 0.24
    hair.density = 0.8
    hair.cut = [GroomCut(center: Vec3(0, -0.13, 0.04), radius: 0.12, length: 0)]
    hair.colliders = [
        GroomCollider(center: .zero, radii: Vec3(0.1, 0.1, 0.1)),
        GroomCollider(center: Vec3(0, -0.1, 0), radius: 0.045, end: Vec3(0, -0.25, 0)),
        GroomCollider(center: Vec3(-0.18, -0.27, 0), radius: 0.07, end: Vec3(0.18, -0.27, 0)),
    ]
    return (MeshGeometry.sphere(radius: 0.1, segments: 32, rings: 16).withTangents(), MaterialFur(groom: hair))
}

/// A head turning sharply side to side and bobbing, `frame` frames at 60 per second in.
private func shakenModel(_ frame: Int) -> Mat4 {
    let t = Float(frame) / 60
    let turn = 1.4 * sinf(t * 9)  // ~13 rad/s at its fastest
    return Mat4(translation: Vec3(0.3 * sinf(t * 7), 1.5 + 0.08 * sinf(t * 13), 0), rotation: Quat(angle: turn, axis: Vec3(0, 1, 0)),
                scale: Vec3(repeating: 1))
}

@Suite struct HairSimulationTests {
    @Test func strandsKeepTheirLengthsAndStayOutOfTheColliders() throws {
        let (base, fur) = hairOnHead()
        let guides = GroomGeometry.guides(base, fur: fur).guides
        #expect(guides.count > 100)
        let rig = HairRig(guides: guides, fur: fur, base: base)
        #expect(!rig.simulated.isEmpty && rig.simulated.count < guides.count, "leaders simulated, followers interpolated")
        var sim = HairSimulation(rig: rig)
        let wind = HairSimulation.Wind(direction: Vec3(1, 0, 0), strength: 3, gustiness: 1)
        var worstStretch: Float = 0, worstDepth: Float = 0, moved: Float = 0, segments = 0, stretched = 0
        for frame in 0..<180 {
            let model = shakenModel(frame)
            sim.step(model: model, joints: nil, dt: 1.0 / 60, time: Float(frame) / 60, wind: wind)
            guard frame > 0 else { continue }
            let inverse = model.inverse
            for g in 0..<rig.guideCount {
                for p in rig.first[g]..<rig.first[g + 1] {
                    if p > rig.first[g] {
                        let d = length(sim.position[p] - sim.position[p - 1])
                        let stretch = abs(d - rig.segment[p]) / max(rig.segment[p], 1e-5)
                        segments += 1
                        if stretch > 0.01 { stretched += 1 }
                        worstStretch = max(worstStretch, stretch)
                    }
                    let local = HairSimulation.point(inverse, sim.position[p])
                    moved = max(moved, length(local - rig.rest[p]))
                    for (c, collider) in rig.colliders.enumerated() where rig.restInside[p] & (1 << UInt32(c)) == 0 {
                        var q = local
                        if collider.shape.pushOut(&q, offset: 0) != nil { worstDepth = max(worstDepth, length(q - local)) }
                    }
                }
            }
        }
        // Inextensible, except where a tip is wedged between two colliders (the neck and a
        // shoulder): there the colliders win.
        #expect(Double(stretched) < Double(segments) * 0.001, "segments keep their rest length: \(stretched) of \(segments) off by > 1%")
        #expect(worstStretch < 0.5, "worst \(worstStretch)")
        #expect(worstDepth < 0.003, "strands stay out of the head, neck and shoulders: deepest \(worstDepth) m")
        #expect(moved > 0.03, "the hair swings: \(moved) m off its rest shape")

        // Held still in calm air, it settles back to the style.
        let still = shakenModel(179)
        for frame in 180..<420 { sim.step(model: still, joints: nil, dt: 1.0 / 60, time: Float(frame) / 60, wind: .calm) }
        var offRest: Float = 0
        for p in rig.rest.indices { offRest = max(offRest, length(HairSimulation.point(still.inverse, sim.position[p]) - rig.rest[p])) }
        #expect(offRest < 0.02, "settled within 2 cm of the groomed shape: \(offRest) m")
    }

    @Test func skinnedRootsAndCollidersFollowTheirJoints() {
        var (base, fur) = hairOnHead()
        base.skin = Array(repeating: SkinInfluence(joint: 1), count: base.vertices.count)
        let guides = GroomGeometry.guides(base, fur: fur).guides
        let rig = HairRig(guides: guides, fur: fur, base: base)
        #expect(rig.colliders.allSatisfy { $0.joint == 1 })
        var sim = HairSimulation(rig: rig)
        let lift = Mat4.translation(Vec3(0, 2, 0))
        for frame in 0..<10 { sim.step(model: .identity, joints: [.identity, lift], dt: 1.0 / 60, time: Float(frame) / 60, wind: .calm) }
        let off = (0..<rig.guideCount).map { length(sim.position[rig.first[$0]] - rig.rest[rig.first[$0]] - Vec3(0, 2, 0)) }
        #expect(off.max()! < 1e-4, "roots ride joint 1")
    }

    @MainActor @Test func shellCountFollowsTheFursSizeOnScreen() {
        // 6 cm fur, 1500 px per meter at 1 m: 90 px at 1 m (all 32 at 3 px a shell), 18 px at 5 m.
        #expect(RenderPrep.furShellCount(full: 32, length: 0.06, distance: 1, pixelScale: 1500, pixelsPerShell: 3) == 30)
        #expect(RenderPrep.furShellCount(full: 32, length: 0.06, distance: 0.5, pixelScale: 1500, pixelsPerShell: 3) == 32)
        #expect(RenderPrep.furShellCount(full: 32, length: 0.06, distance: 5, pixelScale: 1500, pixelsPerShell: 3) == 6)
        #expect(RenderPrep.furShellCount(full: 4, length: 0.06, distance: 50, pixelScale: 1500, pixelsPerShell: 3) == 4)
        #expect(RenderPrep.furShellCount(full: 32, length: 0.06, distance: 5, pixelScale: 0, pixelsPerShell: 3) == 32, "unknown: all")
        // Drawn shells stand for the rest: the count, and the boost in the fraction.
        #expect(RenderPrep.furShellCode(drawn: 32, full: 32) == 32)
        let code = RenderPrep.furShellCode(drawn: 8, full: 32)
        #expect(code.rounded(.down) == 8 && abs(1 + (code - 8 - 0.01) / 0.98 * 8 - 4) < 1e-3)
    }

    @MainActor @Test func furMeshesBuildInTheBackgroundAndSwapIn() throws {
        try TestDevices.forEachBackend { device, frames in
            let renderer = try SceneRenderer(device: device, quality: .medium)
            renderer.blocksOnAssetLoading = false
            let (base, fur) = hairOnHead()
            try renderer.registerMesh(base, key: "HairSimulationTests.head")
            var material = Material(baseColor: Vec4(1, 1, 1, 1))
            material.fur = fur
            try renderer.registerMaterial(material, key: "HairSimulationTests.hair")
            let world = World()
            world.spawn(Transform(position: Vec3(0, 1.5, 0)), Name("HairSimulationTests head"),
                        MeshRenderer(mesh: MeshHandle("HairSimulationTests.head"), material: .default),
                        GroomRenderer(groom: MaterialHandle("HairSimulationTests.hair")))
            world.spawn(Transform.looking(from: Vec3(0, 1.5, 1.5), at: Vec3(0, 1.5, 0)), Camera())
            world.propagateTransforms()
            let start = Date()
            renderer.gather(world)
            #expect(renderer.prep.items.count == 1, "nothing but the head until the fur is built")
            var hair: RenderItem?
            while hair == nil, Date().timeIntervalSince(start) < 30 {
                Thread.sleep(forTimeInterval: 0.01)
                renderer.gather(world)
                hair = renderer.prep.items.first { $0.instance.color.w < -0.5 }
            }
            let item = try #require(hair, "the cards swapped in")
            #expect(renderer.furBuildSeconds > 0)
            let state = try #require(renderer.hairStates.values.first)
            #expect(item.mesh == state.mesh && item.skin == -1 && item.instance.model == .identity)
            #expect(renderer.prep.items.contains { $0.instance.params.y == 0 }, "the undercoat (scalp) too")
            try frames.run { frame in renderer.uploadHair(frame: frame) }
            #expect(!state.needsUpload)
        }
    }
}
