import Foundation
import Testing
@testable import Engine

@MainActor @Test func builtinAnimationComponentsRoundTripAndRegister() throws {
    GamePlayer.registerEngineComponents()
    for name in ["Spin", "FieldAnimator", "LightFlicker", "CameraPath"] {
        #expect(ComponentRegistry.type(named: name) != nil)
    }
    let animator = FieldAnimator(tracks: [.wave("Transform.position.y", amplitude: 0.5, frequency: 2)], speed: 2)
    #expect(try JSONDecoder().decode(FieldAnimator.self, from: JSONEncoder().encode(animator)) == animator)
    let flicker = LightFlicker(style: .neonBuzz, minIntensity: 0.1, speed: 3, seed: 4)
    #expect(try JSONDecoder().decode(LightFlicker.self, from: JSONEncoder().encode(flicker)) == flicker)
    let path = CameraPath(points: [Vec3(0, 0, 0), Vec3(1, 2, 3)], duration: 5, handheld: 0.1)
    #expect(try JSONDecoder().decode(CameraPath.self, from: JSONEncoder().encode(path)) == path)
    #expect(try JSONDecoder().decode(LightFlicker.self, from: Data("{}".utf8)) == LightFlicker())
}

@MainActor @Test func addBuiltinAnimationSystemsIsIdempotent() {
    let world = World()
    world.addBuiltinAnimationSystems()
    world.addBuiltinAnimationSystems()
    #expect(world.systemNames(in: .update).filter { $0 == "builtin.spin" }.count == 1)
}

@MainActor @Test func spinRotatesAndFieldAnimatorWavesAdditively() {
    let world = World()
    world.addBuiltinAnimationSystems()
    let e = world.spawn(Transform(position: Vec3(0, 1, 0)), Spin(axis: Vec3(0, 1, 0), speed: .pi),
                        FieldAnimator(tracks: [.wave("Transform.position.y", amplitude: 0.5, frequency: 1)]))
    var maxY: Float = 0
    for _ in 0..<60 {
        world.update(dt: 1.0 / 60)
        maxY = max(maxY, world.get(Transform.self, for: e)!.position.y)
    }
    let t = world.get(Transform.self, for: e)!
    #expect(maxY > 1.4 && maxY <= 1.51)
    #expect(abs(t.position.y - 1) < 0.02)   // a whole period later, back at the base value
    let forward = t.rotation * Vec3(0, 0, 1)
    #expect(abs(forward.z + 1) < 0.02)       // half a turn
}

@MainActor @Test func lightFlickerStaysWithinBoundsAndIsDeterministic() {
    func run() -> [Float] {
        let world = World()
        world.addBuiltinAnimationSystems()
        let e = world.spawn(Transform(), PointLight(intensity: 10),
                            LightFlicker(style: .smooth, minIntensity: 0.2, maxIntensity: 0.8, speed: 5, seed: 9))
        var values: [Float] = []
        for _ in 0..<120 {
            world.update(dt: 1.0 / 60)
            values.append(world.get(PointLight.self, for: e)!.intensity)
        }
        return values
    }
    let a = run()
    #expect(a == run())
    #expect(a.allSatisfy { $0 >= 2 - 1e-4 && $0 <= 8 + 1e-4 })
    #expect((a.max() ?? 0) - (a.min() ?? 0) > 0.1)
}

@MainActor @Test func cameraPathMovesAlongPoints() {
    let world = World()
    world.addBuiltinAnimationSystems()
    let e = world.spawn(Transform(), CameraPath(points: [Vec3(0, 0, 0), Vec3(10, 0, 0)], duration: 1, loop: .once, easing: .linear))
    for _ in 0..<30 { world.update(dt: 1.0 / 60) }
    let mid = world.get(Transform.self, for: e)!.position
    #expect(abs(mid.x - 5) < 0.3)
    for _ in 0..<60 { world.update(dt: 1.0 / 60) }
    #expect(abs(world.get(Transform.self, for: e)!.position.x - 10) < 0.05)
}
