import Foundation
import Testing
@testable import Engine

@Test func decalRoundTripsThroughJSON() throws {
    let decal = Decal(texture: TextureHandle("graffiti"), tint: Vec3(1, 0.5, 0.25), opacity: 0.75, emissive: 2, roughness: 0.2,
                      angleFade: 0.3, sortOrder: -4, isVisible: false)
    #expect(try JSONDecoder().decode(Decal.self, from: JSONEncoder().encode(decal)) == decal)
}

@Test func decalDecodesMissingFieldsAsDefaults() throws {
    let decal = try JSONDecoder().decode(Decal.self, from: Data(#"{"opacity": 0.5}"#.utf8))
    var expected = Decal()
    expected.opacity = 0.5
    #expect(decal == expected)
}

@MainActor @Test func decalIsARegisteredComponent() throws {
    GamePlayer.registerEngineComponents()
    #expect(ComponentRegistry.type(named: "Decal") == Decal.self)
    let world = World()
    _ = world.spawn(Transform(), Decal(opacity: 0.4, sortOrder: 2))
    let loaded = World()
    _ = try loaded.load(try world.save())
    var found: [Decal] = []
    loaded.query(Decal.self) { _, decal in found.append(decal) }
    #expect(found == [Decal(opacity: 0.4, sortOrder: 2)])
}

@Test func decalBoundsEncloseTheRotatedAndScaledBox() {
    let (center, half) = Decal.bounds(of: Mat4.translation(Vec3(1, 2, 3)) * Mat4.scale(Vec3(2, 4, 6)))
    #expect(center == Vec3(1, 2, 3))
    #expect(half == Vec3(1, 2, 3))
}

@MainActor @Test func decalsGatherVisibleOnesInSortOrder() throws {
    try TestDevices.forEachBackend { device, _ in
        let renderer = try DecalRenderer(device: device)
        let world = World()
        let top = world.spawn(Transform(), Decal(sortOrder: 5))
        let bottom = world.spawn(Transform(), Decal(sortOrder: -1))
        _ = world.spawn(Transform(), Decal(isVisible: false))
        _ = world.spawn(Transform(), Decal(opacity: 0))
        _ = world.spawn(Transform(scale: Vec3(0, 1, 1)), Decal())
        _ = top; _ = bottom
        world.update(dt: 1.0 / 60)
        renderer.gather(world: world)
        #expect(renderer.items.map(\.decal.sortOrder) == [-1, 5], "\(device.backend)")
    }
}

@MainActor @Test func sceneRendererCreatesDecalsOnlyForWorldsWithThem() throws {
    try TestDevices.forEachBackend { device, _ in
        let renderer = try SceneRenderer(device: device, quality: .low)
        let world = World()
        _ = world.spawn(Transform())
        renderer.gatherDecals(world: world)
        #expect(renderer.decals == nil && !renderer.needsDecalDepth)
        _ = world.spawn(Transform(), Decal())
        world.update(dt: 1.0 / 60)
        renderer.gatherDecals(world: world)
        #expect(renderer.decals != nil && renderer.needsDecalDepth, "\(device.backend)")
    }
}
