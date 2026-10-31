import Foundation
import Testing
@testable import Engine

private func close(_ a: Float, _ b: Float, _ eps: Float = 1e-5) -> Bool { abs(a - b) <= eps }

// MARK: Easing

@Test func everyEasingStartsAtZeroAndEndsAtOne() {
    for easing in Easing.allCases {
        #expect(easing(0) == 0 && easing(1) == 1, "\(easing)")
        #expect(easing(-3) == 0 && easing(7) == 1, "\(easing) clamps")
    }
}

@Test func nonOvershootingEasingsAreMonotonic() {
    let overshooting: Set<Easing> = [.backIn, .backOut, .backInOut, .elasticIn, .elasticOut, .elasticInOut,
                                     .bounceIn, .bounceOut, .bounceInOut]
    for easing in Easing.allCases where !overshooting.contains(easing) {
        var previous: Float = 0
        for i in 1...200 {
            let value = easing(Float(i) / 200)
            #expect(value >= previous - 1e-6, "\(easing) at \(i)")
            previous = value
        }
    }
}

@Test func easingShapesHaveTheirKnownMidpointsAndOvershoots() {
    #expect(close(Easing.quadIn(0.5), 0.25) && close(Easing.quadOut(0.5), 0.75) && close(Easing.quadInOut(0.5), 0.5))
    #expect(close(Easing.cubicIn(0.5), 0.125) && close(Easing.cubicInOut(0.5), 0.5))
    #expect(close(Easing.sineInOut(0.5), 0.5) && close(Easing.expoInOut(0.5), 0.5))
    #expect((1...99).contains { Easing.backOut(Float($0) / 100) > 1 })
    #expect((1...99).contains { Easing.backIn(Float($0) / 100) < 0 })
    #expect((1...99).contains { Easing.elasticOut(Float($0) / 100) > 1 })
    // Bounce stays inside 0...1 and touches the floor again before the end.
    #expect((1...99).allSatisfy { (0...1).contains(Easing.bounceOut(Float($0) / 100)) })
    // In is the mirror image of out.
    for easing in [Easing.quadIn, .cubicIn, .expoIn, .backIn, .elasticIn, .bounceIn] {
        let out = Easing(rawValue: easing.rawValue.replacingOccurrences(of: "In", with: "Out"))!
        #expect(close(easing(0.3), 1 - out(0.7), 1e-4), "\(easing)")
    }
}

@Test func easingNamesRoundTripThroughCodable() throws {
    let data = try JSONEncoder().encode([Easing.cubicInOut])
    #expect(String(decoding: data, as: UTF8.self) == #"["cubicInOut"]"#)
    #expect(try JSONDecoder().decode([Easing].self, from: data) == [.cubicInOut])
}

// MARK: Curves

@Test func linearAndStepCurvesInterpolateAndClamp() {
    let linear = AnimationCurve<Float>(keys: [Keyframe(0, 0), Keyframe(2, 10), Keyframe(4, 10)])
    #expect(linear.evaluate(at: -1) == 0 && linear.evaluate(at: 1) == 5 && linear.evaluate(at: 3) == 10 && linear.evaluate(at: 9) == 10)
    #expect(linear.duration == 4)
    let step = AnimationCurve<Float>(keys: [Keyframe(0, 1, interpolation: .step), Keyframe(1, 2, interpolation: .step), Keyframe(2, 3)])
    #expect(step.evaluate(at: 0.99) == 1 && step.evaluate(at: 1) == 2 && step.evaluate(at: 1.5) == 2 && step.evaluate(at: 2) == 3)
    #expect(AnimationCurve<Float>().evaluate(at: 1) == 0)
}

@Test func keysAreKeptSortedByTime() {
    var curve = AnimationCurve<Float>(keys: [Keyframe(2, 20), Keyframe(0, 0)])
    curve.add(Keyframe(1, 10))
    #expect(curve.keys.map(\.time) == [0, 1, 2])
    #expect(curve.evaluate(at: 1.5) == 15)
}

@Test func hermiteCurvesHitKeysAndHonorTangents() {
    // Flat tangents give smoothstep: the midpoint is halfway and the ends are slow.
    let flat = AnimationCurve<Float>(keys: [
        Keyframe(0, 0, interpolation: .hermite, outTangent: 0), Keyframe(1, 1, inTangent: 0)])
    #expect(close(flat.evaluate(at: 0.5), 0.5) && close(flat.evaluate(at: 0.1), 0.028))
    // Automatic (Catmull-Rom) tangents pass through every key, smoothly through a peak.
    let auto = AnimationCurve<Float>(keys: [
        Keyframe(0, 0, interpolation: .hermite), Keyframe(1, 1, interpolation: .hermite),
        Keyframe(2, 0, interpolation: .hermite), Keyframe(3, 1)])
    for k in auto.keys { #expect(close(auto.evaluate(at: k.time), k.value)) }
    #expect(auto.evaluate(at: 0.75) > 0.75)  // overshoots the straight line toward the peak
    // A straight line has constant slope, so automatic tangents reproduce it.
    let line = AnimationCurve<Float>(keys: (0...4).map { Keyframe(Float($0), Float($0) * 2, interpolation: .hermite) })
    #expect(close(line.evaluate(at: 2.3), 4.6))
}

@Test func curvesWrapByLoopingAndPingPong() {
    let keys = [Keyframe<Float>(0, 0), Keyframe(2, 2)]
    #expect(close(AnimationCurve(keys: keys, wrap: .loop).evaluate(at: 3), 1))
    #expect(close(AnimationCurve(keys: keys, wrap: .loop).evaluate(at: -0.5), 1.5))
    #expect(close(AnimationCurve(keys: keys, wrap: .pingPong).evaluate(at: 3), 1))
    #expect(close(AnimationCurve(keys: keys, wrap: .pingPong).evaluate(at: 5), 1))
    #expect(close(AnimationCurve(keys: keys, wrap: .pingPong).evaluate(at: 4), 0))
}

@Test func vectorAndQuaternionCurvesInterpolate() {
    let v = AnimationCurve<Vec3>(keys: [Keyframe(0, Vec3(0, 0, 0)), Keyframe(1, Vec3(2, 4, 6))])
    #expect(v.evaluate(at: 0.5) == Vec3(1, 2, 3))
    let v4 = AnimationCurve<Vec4>.linear(from: Vec4(0, 0, 0, 0), to: Vec4(1, 1, 1, 1), duration: 2)
    #expect(v4.evaluate(at: 1) == Vec4(repeating: 0.5))
    let qa = Quat.identity, qb = Quat(angle: .pi, axis: Vec3(0, 1, 0))
    let q = AnimationCurve<Quat>(keys: [Keyframe(0, qa), Keyframe(1, qb)])
    let mid = q.evaluate(at: 0.5)
    #expect(close(mid.vector.y, sinf(.pi / 4), 1e-4) && close(sqrtf((mid.vector * mid.vector).sum()), 1, 1e-5))
    let h = AnimationCurve<Quat>(keys: [Keyframe(0, qa, interpolation: .hermite), Keyframe(1, qb, interpolation: .hermite),
                                       Keyframe(2, qa)])
    #expect(close(sqrtf((h.evaluate(at: 0.4).vector * h.evaluate(at: 0.4).vector).sum()), 1, 1e-5))
    #expect(close((h.evaluate(at: 1).vector * qb.vector).sum(), 1, 1e-5))
}

@Test func curvesRoundTripThroughJSON() throws {
    let curve = AnimationCurve<Vec2>(keys: [Keyframe(0, Vec2(0, 1), interpolation: .hermite, outTangent: Vec2(1, 0)),
                                           Keyframe(1, Vec2(2, 3))], wrap: .pingPong)
    let decoded = try JSONDecoder().decode(AnimationCurve<Vec2>.self, from: JSONEncoder().encode(curve))
    #expect(decoded == curve)
}

// MARK: Tweens

private final class Box { var value: Float = 0 }

@MainActor @Test func tweenReachesTheEndExactlyAndCompletesOnce() {
    let system = TweenSystem()
    var value: Float = -1
    var completed = 0
    let tween = system.tween(from: 10, to: 20, duration: 1, ease: .quadOut) { value = $0 }
    tween.onComplete = { completed += 1 }
    system.update(dt: 0.5)
    #expect(close(value, 10 + 10 * Easing.quadOut(0.5)) && completed == 0 && system.count == 1)
    system.update(dt: 0.75)
    #expect(value == 20 && completed == 1 && tween.isFinished && system.count == 0)
    system.update(dt: 1)
    #expect(value == 20 && completed == 1)
}

@MainActor @Test func delayHoldsTheStartValueAndCapturesItLate() {
    let system = TweenSystem()
    let box = Box()
    system.tween(box, \.value, to: 100, duration: 1, delay: 2)
    box.value = 40
    system.update(dt: 1.5)
    #expect(box.value == 40)
    box.value = 50  // changed during the delay: the tween starts from here
    system.update(dt: 1)  // 0.5 s into the tween
    #expect(close(box.value, 75))
    system.update(dt: 10)
    #expect(box.value == 100)
}

@MainActor @Test func repeatsPlayExtraTimes() {
    let system = TweenSystem()
    var values: [Float] = []
    let tween = system.tween(from: 0, to: 1, duration: 1, repeatCount: 2) { values.append($0) }
    for _ in 0..<7 { system.update(dt: 0.5) }
    #expect(values.prefix(6).map { $0 } == [0.5, 0, 0.5, 0, 0.5, 1])  // 0.5 then wraps to the start each play
    #expect(tween.isFinished && values.last == 1)
}

@MainActor @Test func yoyoReturnsToTheStartWhenThePlayCountIsEven() {
    let system = TweenSystem()
    var value: Float = -1
    system.tween(from: 0, to: 10, duration: 1, repeatCount: 1, yoyo: true) { value = $0 }
    system.update(dt: 0.75)
    #expect(close(value, 7.5))
    system.update(dt: 0.5)  // 1.25 s: 25% into the backward play
    #expect(close(value, 7.5))
    system.update(dt: 0.75)
    #expect(value == 0 && system.count == 0)

    var odd: Float = -1
    system.tween(from: 0, to: 10, duration: 1, repeatCount: 2, yoyo: true) { odd = $0 }
    system.update(dt: 5)
    #expect(odd == 10)
}

@MainActor @Test func infiniteTweensKeepGoingUntilCancelled() {
    let system = TweenSystem()
    var value: Float = 0
    let tween = system.tween(from: 0, to: 1, duration: 1, repeatCount: -1, yoyo: true) { value = $0 }
    system.update(dt: 100.25)
    #expect(tween.totalDuration == nil && !tween.isFinished && close(value, 0.25, 1e-3))
    tween.cancel()
    system.update(dt: 1)
    #expect(system.count == 0 && close(value, 0.25, 1e-3))
}

@MainActor @Test func oneBigDtMatchesManySmallOnes() {
    func final(_ steps: Int, _ dt: Float) -> Float {
        let system = TweenSystem()
        var value: Float = -1
        system.tween(from: 0, to: 8, duration: 0.5, delay: 0.25, ease: .cubicInOut, repeatCount: 3, yoyo: true) { value = $0 }
        for _ in 0..<steps { system.update(dt: dt) }
        return value
    }
    #expect(final(1, 1.25) == final(5, 0.25))
    #expect(close(final(1, 1.0), final(8, 0.125), 1e-4))
}

@MainActor @Test func zeroDurationAppliesTheEndValueImmediately() {
    let system = TweenSystem()
    var value: Float = -1
    system.tween(from: 0, to: 3, duration: 0) { value = $0 }
    system.update(dt: 0)
    #expect(value == 3 && system.count == 0)
}

@MainActor @Test func timeScaleAndPauseControlProgress() {
    let system = TweenSystem()
    var value: Float = 0
    let tween = system.tween(from: 0, to: 1, duration: 1) { value = $0 }
    tween.timeScale = 2
    system.update(dt: 0.25)
    #expect(close(value, 0.5))
    tween.isPaused = true
    system.update(dt: 10)
    #expect(close(value, 0.5))
    tween.isPaused = false
    tween.complete()
    #expect(value == 1 && tween.isFinished)
}

private struct Health: Component, Equatable {
    var hp: Float
    var offset: Vec2
}

@MainActor @Test func componentKeyPathsTweenAndStopWhenTheEntityIsGone() {
    let world = World()
    let tweens = TweenSystem()
    world.addTweenSystem(tweens)
    let a = world.spawn(Transform(position: Vec3(0, 0, 0)), Health(hp: 100, offset: Vec2(1, 1)))
    let b = world.spawn(Health(hp: 5, offset: .zero))
    tweens.tween(\Transform.position, of: a, in: world, to: Vec3(4, 8, 0), duration: 2, ease: .linear)
    tweens.tween(\Health.hp, of: a, in: world, to: 0, duration: 1)
    tweens.tween(\Health.offset, of: b, in: world, to: Vec2(2, 2), duration: 1)
    world.update(dt: 0.5)
    #expect(world.get(Transform.self, for: a)?.position == Vec3(1, 2, 0))
    #expect(world.get(Health.self, for: a)?.hp == 50)
    world.despawn(b)
    world.update(dt: 0.5)
    #expect(world.get(Health.self, for: a)?.hp == 0)
    #expect(tweens.count == 1)  // the despawned entity's tween and the finished one are gone
    world.update(dt: 1)
    #expect(world.get(Transform.self, for: a)?.position == Vec3(4, 8, 0) && tweens.count == 0)
}

@MainActor @Test func curvesPlayThroughTweens() {
    let system = TweenSystem()
    var value: Float = 0
    let curve = AnimationCurve<Float>(keys: [Keyframe(1, 10), Keyframe(3, 30)])
    system.play(curve) { value = $0 }
    system.update(dt: 1)
    #expect(close(value, 20))
    system.update(dt: 1)
    #expect(value == 30 && system.count == 0)
}
