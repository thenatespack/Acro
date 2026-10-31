import Foundation
import Testing
@testable import Engine

// 3D audio on the offline device, so every sample is deterministic.

private let rate = 48000.0

private func makeSystem() throws -> AudioSystem {
    try AudioSystem(device: OfflineAudioDevice(sampleRate: rate), maxVoices: 16)
}

private func constant(_ value: Float, seconds: Double = 4) -> SoundBuffer {
    SoundBuffer(frameCount: Int(rate * seconds), channelCount: 1, sampleRate: rate) { _, _ in value }
}

private func sine(_ frequency: Double, seconds: Double = 4) -> SoundBuffer {
    SoundBuffer(frameCount: Int(rate * seconds), channelCount: 1, sampleRate: rate) { i, _ in
        Float(sin(2 * Double.pi * frequency * Double(i) / rate))
    }
}

/// Frequency of a signal from its upward zero crossings over frames `range` of channel `channel`.
private func frequency(_ output: [Float], channel: Int = 0, frames range: Range<Int>) -> Double {
    var crossings = 0
    var first = -1.0, last = -1.0
    for i in range.lowerBound + 1..<range.upperBound {
        let a = output[2 * (i - 1) + channel], b = output[2 * i + channel]
        if a < 0 && b >= 0 {
            let at = Double(i - 1) + Double(-a / (b - a))  // interpolated crossing
            if first < 0 { first = at }
            last = at
            crossings += 1
        }
    }
    return crossings > 1 ? Double(crossings - 1) * rate / (last - first) : 0
}

private func rms(_ output: [Float], channel: Int, frames range: Range<Int>) -> Float {
    var sum: Float = 0
    for i in range { sum += output[2 * i + channel] * output[2 * i + channel] }
    return (sum / Float(range.count)).squareRoot()
}

@Suite struct SpatialAudioTests {
    // MARK: - Attenuation

    @Test func inverseRolloff() {
        func g(_ d: Float, factor: Float = 1) -> Float {
            SpatialAudio.attenuation(distance: d, minDistance: 2, maxDistance: 100, rolloff: .inverse, factor: factor)
        }
        #expect(g(0.5) == 1)  // inside the minimum distance: full level
        #expect(g(2) == 1)
        #expect(abs(g(4) - 2.0 / (2 + 2)) < 1e-6)  // min / (min + (d - min))
        #expect(abs(g(4, factor: 2) - 2.0 / (2 + 4)) < 1e-6)
        #expect(g(100) == g(500))  // held beyond the maximum distance
        #expect(g(10) > g(20))
    }

    @Test func linearRolloffReachesSilenceAtMax() {
        func g(_ d: Float) -> Float {
            SpatialAudio.attenuation(distance: d, minDistance: 1, maxDistance: 11, rolloff: .linear, factor: 1)
        }
        #expect(g(1) == 1)
        #expect(abs(g(6) - 0.5) < 1e-6)
        #expect(g(11) == 0)
        #expect(g(50) == 0)
    }

    @Test func exponentialRolloff() {
        func g(_ d: Float, factor: Float) -> Float {
            SpatialAudio.attenuation(distance: d, minDistance: 1, maxDistance: 100, rolloff: .exponential, factor: factor)
        }
        #expect(abs(g(2, factor: 1) - 0.5) < 1e-6)
        #expect(abs(g(4, factor: 2) - 1.0 / 16) < 1e-6)
        #expect(g(1, factor: 3) == 1)
    }

    // MARK: - Pan law

    @Test func equalPowerPanKeepsPower() {
        for k in 0...20 {
            let pan = Float(k) / 10 - 1
            let (l, r) = SpatialAudio.equalPowerGains(pan: pan)
            #expect(abs(l * l + r * r - 1) < 1e-5, "pan \(pan)")
        }
        let center = SpatialAudio.equalPowerGains(pan: 0)
        #expect(abs(center.left - 0.70710678) < 1e-5 && abs(center.right - 0.70710678) < 1e-5)
        let left = SpatialAudio.equalPowerGains(pan: -1)
        #expect(abs(left.left - 1) < 1e-6 && abs(left.right) < 1e-6)
        let right = SpatialAudio.equalPowerGains(pan: 1)
        #expect(abs(right.left) < 1e-6 && abs(right.right - 1) < 1e-6)
        #expect(SpatialAudio.equalPowerGains(pan: 7).right == SpatialAudio.equalPowerGains(pan: 1).right)  // clamped
    }

    @Test func directionDecidesPanAndHeadShadow() {
        let listener = AudioListenerState()  // at the origin, looking down -Z, +X is to the right
        let s = SpatialSettings()
        func result(_ position: Vec3) -> SpatialResult {
            SpatialAudio.compute(listener: listener, listenerVelocity: .zero, position: position, velocity: .zero,
                                 direction: nil, settings: s, volume: 1)
        }
        let ahead = result(Vec3(0, 0, -5))
        #expect(abs(ahead.pan) < 1e-6)
        #expect(abs(ahead.gainL - ahead.gainR) < 1e-6)
        let right = result(Vec3(5, 0, 0))
        #expect(abs(right.pan - 1) < 1e-6)
        #expect(right.gainR > 10 * right.gainL)
        #expect(right.cutoffL < right.cutoffR)  // the head shadows the far (left) ear
        let left = result(Vec3(-5, 0, 0))
        #expect(left.cutoffR < left.cutoffL && left.gainL > left.gainR)
        // Behind is as centered as ahead.
        #expect(abs(result(Vec3(0, 0, 5)).pan) < 1e-6)
        // A listener turned to look along +X hears the same source ahead.
        var turned = listener
        turned.forward = Vec3(1, 0, 0)
        let ahead2 = SpatialAudio.compute(listener: turned, listenerVelocity: .zero, position: Vec3(5, 0, 0), velocity: .zero,
                                          direction: nil, settings: s, volume: 1)
        #expect(abs(ahead2.pan) < 1e-5)
    }

    @Test func panFadesToCenterInsideMinDistance() {
        var s = SpatialSettings()
        s.minDistance = 2
        let r = SpatialAudio.compute(listener: AudioListenerState(), listenerVelocity: .zero, position: Vec3(0.2, 0, 0), velocity: .zero,
                                     direction: nil, settings: s, volume: 1)
        #expect(abs(r.pan) < 0.15)
    }

    @Test func distanceLowPassGoesFromOpenToFarCutoff() {
        var s = SpatialSettings()
        s.minDistance = 1
        s.maxDistance = 101
        s.farCutoff = 2000
        func cutoff(_ d: Float) -> Float {
            SpatialAudio.compute(listener: AudioListenerState(), listenerVelocity: .zero, position: Vec3(0, 0, -d), velocity: .zero,
                                 direction: nil, settings: s, volume: 1).cutoffL
        }
        #expect(cutoff(1) == StereoFilter.openCutoff)
        #expect(abs(cutoff(101) - 2000) < 1)
        #expect(cutoff(30) > cutoff(60))
        s.distanceLowPass = false
        #expect(cutoff(101) == StereoFilter.openCutoff)
    }

    // MARK: - Cone

    @Test func coneGain() {
        // 90 degrees inner, 180 outer, quarter level outside.
        func g(_ degrees: Float) -> Float {
            SpatialAudio.coneGain(angle: degrees * .pi / 180, inner: 90, outer: 180, outerGain: 0.25)
        }
        #expect(g(0) == 1 && g(45) == 1)
        #expect(g(90) == 0.25 && g(170) == 0.25)
        #expect(abs(g(67.5) - 0.625) < 1e-5)  // halfway between the half angles 45 and 90
        #expect(SpatialAudio.coneGain(angle: 3, inner: 360, outer: 360, outerGain: 0) == 1)  // omnidirectional
    }

    @Test func coneUsesEmitterDirection() {
        var s = SpatialSettings()
        s.coneInnerAngle = 60
        s.coneOuterAngle = 120
        s.coneOuterGain = 0.1
        func gain(facing: Vec3) -> Float {
            SpatialAudio.compute(listener: AudioListenerState(), listenerVelocity: .zero, position: Vec3(0, 0, -1), velocity: .zero,
                                 direction: facing, settings: s, volume: 1).gain
        }
        #expect(gain(facing: Vec3(0, 0, 1)) == 1)  // pointing at the listener
        #expect(abs(gain(facing: Vec3(0, 0, -1)) - 0.1) < 1e-6)  // pointing away
    }

    // MARK: - Doppler

    @Test func dopplerPitch() {
        func pitch(listener: Vec3 = .zero, source: Vec3 = Vec3(0, 0, -100), sourceVelocity: Vec3 = .zero,
                   factor: Float = 1) -> Float {
            SpatialAudio.doppler(listenerPosition: .zero, listenerVelocity: listener, sourcePosition: source,
                                 sourceVelocity: sourceVelocity, speedOfSound: 343, factor: factor)
        }
        #expect(pitch() == 1)
        // The source approaches at a tenth of the speed of sound: 1 / (1 - 0.1).
        #expect(abs(pitch(sourceVelocity: Vec3(0, 0, 34.3)) - 1 / 0.9) < 1e-4)
        #expect(abs(pitch(sourceVelocity: Vec3(0, 0, -34.3)) - 1 / 1.1) < 1e-4)  // receding
        // The listener approaches: 1.1.
        #expect(abs(pitch(listener: Vec3(0, 0, -34.3)) - 1.1) < 1e-4)
        // Sideways motion doesn't shift the pitch.
        #expect(abs(pitch(sourceVelocity: Vec3(50, 0, 0)) - 1) < 1e-6)
        // The factor scales the effect, and 0 turns it off.
        #expect(abs(pitch(sourceVelocity: Vec3(0, 0, 34.3), factor: 0.5) - 1 / 0.95) < 1e-4)
        #expect(pitch(sourceVelocity: Vec3(0, 0, 34.3), factor: 0) == 1)
        // Supersonic speeds stay clamped to an octave, and finite.
        let fast = pitch(sourceVelocity: Vec3(0, 0, 5000))
        #expect(fast == SpatialAudio.dopplerRange.upperBound)
        #expect(pitch(sourceVelocity: Vec3(0, 0, -5000)) >= SpatialAudio.dopplerRange.lowerBound)
    }

    @Test func dopplerShiftsPlaybackFrequency() throws {
        let audio = try makeSystem()
        let voice = audio.play(sine(1000), at: Vec3(0, 0, -100))
        voice.worldVelocity = Vec3(0, 0, 34.3)
        let output = audio.render(frames: 48000)
        // After the 30 ms glide the tone is 1000 / 0.9 Hz.
        let measured = frequency(output, frames: 24000..<48000)
        #expect(abs(measured - 1111.1) < 4, "measured \(measured)")
        // Velocity derived from the listener's movement does the same: 34.3 m/s toward the source.
        let audio2 = try makeSystem()
        _ = audio2.play(sine(1000), at: Vec3(0, 0, -100))
        audio2.update(dt: 0.1)
        audio2.listener.position = Vec3(0, 0, -3.43)
        audio2.update(dt: 0.1)
        let output2 = audio2.render(frames: 48000)
        #expect(abs(frequency(output2, frames: 24000..<48000) - 1100) < 4)
    }

    // MARK: - Through the mixer

    @Test func attenuationAndPanReachTheOutput() throws {
        let audio = try makeSystem()
        var settings = SpatialSettings()
        settings.distanceLowPass = false
        audio.listener.headShadow = 0
        audio.play(constant(1), at: Vec3(0, 0, -4), settings: settings, loop: true)
        var output = audio.render(frames: 4800)
        let ahead = output[2 * 4799]
        let expected = 0.25 * Float(0.5).squareRoot()  // inverse rolloff at 4 m, centered equal power
        #expect(abs(ahead - expected) < 1e-4, "\(ahead) vs \(expected)")
        #expect(abs(output[2 * 4799 + 1] - expected) < 1e-4)

        audio.stopAll()
        _ = audio.render(frames: 4800)
        audio.play(constant(1), at: Vec3(4, 0, 0), settings: settings, loop: true)
        output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799 + 1] - 0.25) < 1e-4)  // hard right: all power on the right
        #expect(abs(output[2 * 4799]) < 1e-4)
    }

    @Test func volumeAndListenerGainApply() throws {
        let audio = try makeSystem()
        var settings = SpatialSettings()
        settings.distanceLowPass = false
        audio.listener.volume = 0.5
        let voice = audio.play(constant(1), at: Vec3(0, 0, -1), settings: settings, volume: 0.5, loop: true)
        var output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799] - 0.25 * Float(0.5).squareRoot()) < 1e-4)
        voice.volume = 1
        output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799] - 0.5 * Float(0.5).squareRoot()) < 1e-4)
    }

    @Test func movingASourceRampsWithoutSteps() throws {
        let audio = try makeSystem()
        var settings = SpatialSettings()
        settings.distanceLowPass = false
        let voice = audio.play(constant(1), at: Vec3(0, 0, -1), settings: settings, loop: true)
        _ = audio.render(frames: 4800)
        voice.worldPosition = Vec3(0, 0, -20)
        let output = audio.render(frames: 4800)
        var largestStep: Float = 0
        for i in 1..<4800 { largestStep = max(largestStep, abs(output[2 * i] - output[2 * (i - 1)])) }
        // The gain falls by 0.65 over about 20 ms (960 frames): no sample-to-sample jump beyond that slope.
        #expect(largestStep < 0.0012, "largest step \(largestStep)")
        #expect(abs(output[2 * 4799] - 0.05 * Float(0.5).squareRoot()) < 1e-3)
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func dopplerPitchGlidesInsteadOfJumping() throws {
        let audio = try makeSystem()
        let voice = audio.play(sine(1000), at: Vec3(0, 0, -100))
        _ = audio.render(frames: 4800)
        voice.worldVelocity = Vec3(0, 0, 100)  // a big, sudden velocity change
        let output = audio.render(frames: 9600)
        // Early on (within the first few ms) the frequency is still near 1000 Hz.
        let early = frequency(output, frames: 0..<400)
        #expect(early < 1150, "early \(early)")
        let late = frequency(output, frames: 6000..<9600)
        #expect(late > 1350)
    }

    @Test func listenerOrientationPans() throws {
        let audio = try makeSystem()
        var settings = SpatialSettings()
        settings.distanceLowPass = false
        audio.listener.headShadow = 0
        audio.play(constant(1), at: Vec3(0, 0, -4), settings: settings, loop: true)
        _ = audio.render(frames: 4800)
        // Turn the listener to face +X: the source (at -Z) is now on its left.
        audio.listener.forward = Vec3(1, 0, 0)
        let output = audio.render(frames: 9600)
        #expect(output[2 * 9599] > 10 * output[2 * 9599 + 1])
    }

    @Test func voiceCanLeaveSpatialMode() throws {
        let audio = try makeSystem()
        let voice = audio.play(constant(1), at: Vec3(0, 0, -50), loop: true)
        var output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799]) < 0.02)
        voice.worldPosition = nil
        #expect(voice.spatial == nil)
        output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799] - 1) < 1e-3)
    }

    @Test func spatialRenderIsDeterministicAndFinite() throws {
        func run() throws -> [Float] {
            let audio = try makeSystem()
            let voice = audio.play(sine(440), at: Vec3(3, 0, -2), loop: true)
            var all: [Float] = []
            for k in 0..<30 {
                voice.worldPosition = Vec3(3 * cosf(Float(k) * 0.3), 0, -2 * sinf(Float(k) * 0.3) - 3)
                audio.update(dt: 1.0 / 60)
                all += audio.render(frames: 800)
            }
            return all
        }
        let a = try run(), b = try run()
        #expect(a == b)
        #expect(a.allSatisfy { $0.isFinite && !$0.isSubnormal })
    }

    // MARK: - ECS

    @MainActor @Test func emitterComponentsDriveVoices() throws {
        let audio = try makeSystem()
        audio.register(constant(1), as: "hum")
        let world = World()
        world.addSpatialAudio(audio)
        _ = world.spawn(Transform(position: Vec3(0, 0, 0)), AudioListener(headShadow: 0))
        var emitter = AudioEmitter(sound: "hum")
        emitter.spatial.distanceLowPass = false
        let entity = world.spawn(Transform(position: Vec3(0, 0, -4)), emitter)
        world.update(dt: 1.0 / 60)
        #expect(audio.activeVoices.count == 1)
        var output = audio.render(frames: 4800)
        #expect(abs(output[2 * 4799] - 0.25 * Float(0.5).squareRoot()) < 1e-3)

        // Move it to the right: the transform drives the pan.
        world.modify(Transform.self, for: entity) { $0.position = Vec3(4, 0, 0) }
        world.update(dt: 1.0 / 60)
        output = audio.render(frames: 4800)
        #expect(output[2 * 4799 + 1] > 10 * output[2 * 4799])

        // Switching it off stops the voice; despawning does too.
        world.modify(AudioEmitter.self, for: entity) { $0.isPlaying = false }
        world.update(dt: 1.0 / 60)
        _ = audio.render(frames: 2400)
        #expect(audio.activeVoices.isEmpty)
        world.modify(AudioEmitter.self, for: entity) { $0.isPlaying = true }
        world.update(dt: 1.0 / 60)
        #expect(audio.activeVoices.count == 1)
        world.despawn(entity)
        world.update(dt: 1.0 / 60)
        _ = audio.render(frames: 2400)
        #expect(audio.activeVoices.isEmpty)
    }

    @MainActor @Test func oneShotEmitterClearsIsPlayingWhenItEnds() throws {
        let audio = try makeSystem()
        audio.register(constant(1, seconds: 0.05), as: "pop")
        let world = World()
        world.addSpatialAudio(audio)
        _ = world.spawn(Transform(), AudioListener())
        let entity = world.spawn(Transform(position: Vec3(0, 0, -2)), AudioEmitter(sound: "pop", loop: false))
        world.update(dt: 1.0 / 60)
        _ = audio.render(frames: 4800)
        audio.update(dt: 0)
        world.update(dt: 1.0 / 60)
        #expect(world.get(AudioEmitter.self, for: entity)?.isPlaying == false)
        world.update(dt: 1.0 / 60)
        #expect(audio.activeVoices.isEmpty)
    }

    @MainActor @Test func audioComponentsRoundTripThroughScenes() throws {
        AudioSystem.registerComponents()
        let world = World()
        var emitter = AudioEmitter(sound: "wind", reverbSend: 0.4, filter: AudioFilter(.lowPass, cutoff: 900, q: 1.2))
        emitter.spatial.rolloff = .exponential
        emitter.spatial.coneInnerAngle = 40
        emitter.velocity = Vec3(1, 2, 3)
        let e = world.spawn(Transform(), emitter, AudioListener(volume: 0.5))
        let data = try world.save()
        let other = World()
        let roots = try other.load(data)
        #expect(roots.count == 1)
        #expect(other.get(AudioEmitter.self, for: roots[0]) == emitter)
        #expect(other.get(AudioListener.self, for: roots[0])?.volume == 0.5)
        _ = e
    }
}
